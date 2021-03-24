select
       CASE WHEN prg.program='TB' THEN prg.status  ELSE null end  AS StatusAtTBClinic,
       CASE WHEN prg.program='MCH-Mother Services' THEN prg.status  ELSE null end  AS  StatusAtPMTCT,
       CASE WHEN prg.program='HIV' THEN prg.status  ELSE null end  AS   StatusATCCC,

       '' AS SatelliteName,
       0 AS FacilityId,d.unique_patient_no as PatientID,
       d.patient_id as PatientPK,
       pkv.PKV as Pkv,
       (select value_reference from location_attribute
        where location_id in (select property_value
                              from global_property
                              where property='kenyaemr.defaultLocation') and attribute_type_id=1) as SiteCode,
       (select name from location
        where location_id in (select property_value
                              from global_property
                              where property='kenyaemr.defaultLocation')) as FacilityName,
       case d.gender when 'M' then 'Male' when 'F' then 'Female' end  as Gender,
       d.dob as DOB,
       CAST(min(hiv.visit_date) as Date) as RegistrationDate,
       CAST(coalesce(date_first_enrolled_in_care,min(hiv.visit_date)) as Date) as RegistrationAtCCC,
       CAST(min(mch.visit_date)as Date) as RegistrationATPMTCT,
       CAST(min(tb.visit_date)as Date) as RegistrationAtTBClinic,
       case  max(hiv.entry_point)
         when 160542 then 'OPD'
         when 160563 then 'Other'
         when 160539 then 'VCT'
         when 160538 then 'PMTCT'
         when 160541 then 'TB'
         when 160536 then 'IPD - Adult'
           /*else cn.name*/
           end as PatientSource,

       (select state_province from location
        where location_id in (select property_value
                              from global_property
                              where property='kenyaemr.defaultLocation')) as Region,
       (select county_district from location
        where location_id in (select property_value
                              from global_property
                              where property='kenyaemr.defaultLocation'))as District,
       (select address6 from location
        where location_id in (select property_value
                              from global_property
                              where property='kenyaemr.defaultLocation')) as Village,
       UPPER(ts.name) as ContactRelation,
       CAST(GREATEST(coalesce(max(hiv.visit_date),date('1000-01-01')),coalesce(max(de.visit_date),date('1000-01-01')), coalesce(max(enr.visit_date),date('1000-01-01'))) as Date) as LastVisit,
       UPPER(d.marital_status) as MaritalStatus,
       UPPER(d.education_level) as EducationLevel,

       CAST(min(hiv.date_confirmed_hiv_positive) as Date) as DateConfirmedHIVPositive,
       max(hiv.arv_status) as PreviousARTExposure,
       NULL as PreviousARTStartDate,
       'KenyaEMR' as Emr,
       'Kenya HMIS II' as Project,
       CASE hiv.patient_type
         WHEN 160563 THEN 'Transfer in'
         WHEN 164144	THEN 'New client'
         WHEN 159833	THEN 'Re-enroll'
         ELSE hiv.patient_type
           END AS PatientType,
       if (c.client_id is not null,'Key population', (select CASE
                                                               WHEN mid(max(concat(f.visit_date,f.population_type)),11)=164929
                                                                       THEN 'Key population'
                                                               WHEN mid(max(concat(f.visit_date,f.population_type)),11)=164928 THEN 'General Population'
                                                                 END  from  kenyaemr_etl.etl_patient_hiv_followup f
                                                      WHERE f.encounter_id=max(enr.encounter_id) group by f.patient_id)) AS PopulationType,
       COALESCE(c.key_population_type,(select
                                              case mid(max(concat(f.visit_date,f.key_population_type)),11)
                                                WHEN 105 THEN 'PWID'
                                                WHEN 160578 THEN 'MSM'
                                                WHEN 160579  THEN 'FSW'
                                                WHEN 1175 THEN 'N/A'
                                                ELSE null END
                                       from  kenyaemr_etl.etl_patient_hiv_followup f
                                       WHERE f.encounter_id=max(enr.encounter_id) group by f.patient_id)) AS KeyPopulationType,
       case hiv.orphan when 1 THEN 'Yes' when 2 THEN 'No' ELSE null END as  'Orphan',
       case hiv.in_school when 1 THEN 'Yes' when 2 THEN 'No' ELSE null END as 'InSchool',
       patAd.county_district AS  PatientResidentCounty,
       patAd.state_province AS PatientResidentSubCounty,
       patAd.address6 AS PatientResidentLocation,
       patAd.address5 AS PatientResidentSubLocation,
       patAd.address4 AS PatientResidentWard,
       patAd.city_village AS PatientResidentVillage,
       cast(min(hiv.transfer_in_date) as Date) as TransferInDate,
       hiv.date_created as Date_Created,
       GREATEST(
         COALESCE(d.date_last_modified, hiv.date_last_modified, prg.date_last_modified),
         COALESCE(hiv.date_last_modified, prg.date_last_modified, d.date_last_modified),
         COALESCE(prg.date_last_modified, d.date_last_modified, hiv.date_last_modified)
           ) as Date_Last_Modified,d.occupation as Occupation
from kenyaemr_etl.etl_hiv_enrollment hiv
       inner join  kenyaemr_etl.etl_patient_demographics d on hiv.patient_id=d.patient_id
       left outer join kenyaemr_etl.etl_mch_enrollment mch on mch.patient_id=d.patient_id
       left outer join kenyaemr_etl.etl_patient_hiv_followup enr on enr.patient_id=d.patient_id
       left outer join kenyaemr_etl.etl_tb_enrollment tb on tb.patient_id=d.patient_id
       left outer join kenyaemr_etl.etl_drug_event de on de.patient_id = d.patient_id
       left join concept_name ts on ts.concept_id=hiv.relationship_of_treatment_supporter and ts.concept_name_type = 'FULLY_SPECIFIED' and ts.locale='en'
       left join person_address patAd ON patAd.person_id=d.patient_id and patAd.voided = 0
       inner join (    select
                              x.patient_id as patient_id,x.sxFirstName,x.sxLastname,x.sxMiddleName,x.dmFirstName,x.dmLastName,x.dmMiddleName,x.Gender,x.DOB,
                              CASE WHEN locate(';',dmLastName )>0 THEN
                                  CONCAT(
                                    CAST( LEFT(Gender ,1) AS CHAR CHARACTER SET utf8)
                                    ,CAST( sxFirstName AS CHAR CHARACTER SET utf8)
                                    , CAST( SUBSTRING(dmLastName ,locate(';',dmLastName )+1,LENGTH(dmLastName )) AS CHAR CHARACTER SET utf8)
                                    ,CAST( LTRIM(RTRIM(DATE_FORMAT(DOB, '%Y'))) AS CHAR CHARACTER SET utf8)
                                      )
                                   ELSE
                                  CONCAT(
                                    CAST( LEFT(Gender ,1)AS CHAR CHARACTER SET utf8)
                                    , CAST( sxFirstName AS CHAR CHARACTER SET utf8),
                                    CAST( dmLastName AS CHAR CHARACTER SET utf8),
                                    CAST( LTRIM(RTRIM(DATE_FORMAT(DOB, '%Y'))) AS CHAR CHARACTER SET utf8)
                                      )
                                  END AS PKV
                       from(
                           SELECT patient_id,
                                  SOUNDEX(UPPER(REPLACE(given_name ,'0','O'))) AS sxFirstName,
                                  SOUNDEX(UPPER(REPLACE(family_name ,'0','O'))) AS sxLastName,
                                  SOUNDEX(UPPER(REPLACE(middle_name ,'0','O'))) AS sxMiddleName,
                                  fn_getPatientNameDoubleMetaphone(UPPER(REPLACE(given_name ,'0','O'))) AS dmFirstName,
                                  fn_getPatientNameDoubleMetaphone(UPPER(REPLACE(family_name ,'0','O'))) AS dmLastName,
                                  fn_getPatientNameDoubleMetaphone(UPPER(REPLACE(middle_name ,'0','O'))) AS dmMiddleName,
                                  Gender,DOB
                           FROM kenyaemr_etl.etl_patient_demographics
                           )x)pkv on pkv.patient_id = d.patient_id
       left join
         (
         select Patient_Id,   program ,
                if(mid(max(concat(date_enrolled,date_completed)), 20) is null, 'Active', 'Inactive') as status,
                date_created,date_last_modified
         from kenyaemr_etl.etl_patient_program
         group by Patient_Id,program
         ) as prg on prg.patient_id = d.patient_id
       left join kenyaemr_etl.etl_contact c on c.client_id = d.patient_id and prg.status='Active' and prg.program='KP'
where unique_patient_no is not null
group by d.patient_id
order by d.patient_id;