select '' AS SatelliteName, 0 AS FacilityId, d.DOB,
       d.Gender, 'Government' AS Provider,
       d.unique_patient_no as PatientID,
       d.patient_id as PatientPK,
       timestampdiff(year,d.DOB, hiv.visit_date) as AgeEnrollment,
       timestampdiff(year,d.DOB, reg.art_start_date) as AgeARTStart,
       timestampdiff(year,d.DOB, reg.latest_vis_date) as AgeLastVisit,
       (select value_reference from location_attribute
        where location_id in (select property_value
                              from global_property
                              where property='kenyaemr.defaultLocation') and attribute_type_id=1) as SiteCode,
       (select name from location
        where location_id in (select property_value
                              from global_property
                              where property='kenyaemr.defaultLocation')) as FacilityName,
       CAST(coalesce(date_first_enrolled_in_care,min(hiv.visit_date)) as Date) as RegistrationDate,
       case  max(hiv.entry_point)
         when 160542 then 'OPD'
         when 160563 then 'Other'
         when 160539 then 'VCT'
         when 160538 then 'PMTCT'
         when 160541 then 'TB'
         when 160536 then 'IPD - Adult'
         else cn.name
           end as PatientSource,
       reg.art_start_date as StartARTDate,
       hiv.date_started_art_at_transferring_facility as PreviousARTStartDate,
       (case (if(o1.obs_group =1085 and o1.concept_id = 1088,o1.value_coded,null))
          when 164968 then 'AZT/3TC/DTG'
          when 164969 then 'TDF/3TC/DTG'
          when 164970 then 'ABC/3TC/DTG'
          when 164505 then 'TDF-3TC-EFV'
          when 792 then 'D4T/3TC/NVP'
          when 160124 then 'AZT/3TC/EFV'
          when 160104 then 'D4T/3TC/EFV'
          when 1652 then '3TC/NVP/AZT'
          when 161361 then 'EDF/3TC/EFV'
          when 104565 then 'EFV/FTC/TDF'
          when 162201 then '3TC/LPV/TDF/r'
          when 817 then 'ABC/3TC/AZT'
          when 162199 then 'ABC/NVP/3TC'
          when 162200 then '3TC/ABC/LPV/r'
          when 162565 then '3TC/NVP/TDF'
          when 164511 then '3TC/NVP/AZT'
          when 162561 then '3TC/AZT/LPV/r'
          when 162561 then 'AZT-3TC-ATV/r'
          when 164512 then 'TDF-3TC-ATV/r'
          when 162560 then '3TC/D4T/LPV/r'
          when 162563 then '3TC/ABC/EFV'
          when 162562 then 'ABC/LPV/R/TDF'
          when 162559 then 'ABC/DDI/LPV/r' END) as PreviousARTRegimen,
       reg.art_start_date as StartARTAtThisFacility,
       reg.regimen as StartRegimen,
       reg.regimen_line as StartRegimenLine,
       case
         when reg.latest_vis_date is not null then reg.latest_vis_date else  reg.last_art_date end as LastARTDate,
       reg.last_regimen as LastRegimen,
       reg.last_regimen_line as LastRegimenLine,
       reg.latest_tca as ExpectedReturn,
       reg.latest_vis_date as LastVisit ,
       timestampdiff(month,reg.art_start_date, reg.latest_vis_date) as Duration,
       disc.ExitDate as ExitDate,
       disc.ExitReason as ExitReason,
       'KenyaEMR' as Emr,
       'Kenya HMIS II' as Project,
       hiv.date_created as Date_Created,
       GREATEST(
         COALESCE(hiv.date_last_modified, disc.date_last_modified, reg.date_last_modified),
         COALESCE(disc.date_last_modified, reg.date_last_modified, hiv.date_last_modified),
         COALESCE(reg.date_last_modified, hiv.date_last_modified, disc.date_last_modified)
           ) as Date_Last_Modified
from kenyaemr_etl.etl_hiv_enrollment hiv
       join kenyaemr_etl.etl_patient_demographics d on d.patient_id=hiv.patient_id
       left outer join(
                      select d.patient_id, coalesce(max(date(d.effective_discontinuation_date)),max(date(d.visit_date)))as ExitDate,(case d.discontinuation_reason when 159492 then 'Transfer Out'
                                                                                                                                                                   when 160034 then 'Died'
                                                                                                                                                                   when 5240 then 'LTFU'
                                                                                                                                                                   when 819 then 'Stopped Treatment'
                                                                                                                                                                   else'' end) as ExitReason, max(d.date_last_modified) as date_last_modified from kenyaemr_etl.etl_patient_program_discontinuation d
                      where d.program_name='HIV' group by d.patient_id) disc on disc.patient_id = hiv.patient_id
       left outer join (select e.patient_id,
                               if(enr.date_started_art_at_transferring_facility is not null,enr.date_started_art_at_transferring_facility,
                                  e.date_started)as art_start_date, e.date_started, e.gender,e.dob,d.ExitDate as dis_date, if(d.ExitDate is not null, 1, 0) as TOut,
                               e.regimen, e.regimen_line, e.alternative_regimen, max(fup.next_appointment_date) as latest_tca,
                               last_art_date,last_regimen,last_regimen_line,
                               if(enr.transfer_in_date is not null, 1, 0) as TIn, max(fup.visit_date) as  latest_vis_date,
                               e.date_created,e.date_last_modified
                        from (select e.patient_id,p.dob,p.Gender,min(e.date_started) as date_started,
                                     max(e.date_started) as last_art_date,
                                     mid(min(concat(e.date_started,e.regimen_name)),11) as regimen,
                                     mid(min(concat(e.date_started,e.regimen_line)),11) as regimen_line,
                                     mid(max(concat(e.date_started,e.regimen_name)),11) as last_regimen,
                                     mid(max(concat(e.date_started,e.regimen_line)),11) as last_regimen_line,
                                     max(if(discontinued,1,0))as alternative_regimen,
                                     GREATEST(COALESCE(p.date_created, ph.date_created), COALESCE(ph.date_created, p.date_created)) as date_created,
                                     GREATEST(COALESCE(p.date_last_modified, ph.date_last_modified), COALESCE(ph.date_last_modified, p.date_last_modified)) as date_last_modified,e.provider as provider
                              from kenyaemr_etl.etl_drug_event e
                                     join kenyaemr_etl.etl_patient_demographics p on p.patient_id=e.patient_id
                                     left join  kenyaemr_etl.etl_pharmacy_extract ph on ph.patient_id = e.patient_id and is_arv=1
                              where e.program = 'HIV'
                              group by e.patient_id) e
                               left outer join (select d.patient_id, coalesce(max(date(d.effective_discontinuation_date)),max(date(d.visit_date))) ExitDate from kenyaemr_etl.etl_patient_program_discontinuation d
                                                where d.program_name='HIV' group by d.patient_id)d on d.patient_id=e.patient_id
                               left outer join kenyaemr_etl.etl_hiv_enrollment enr on enr.patient_id=e.patient_id
                               left outer join kenyaemr_etl.etl_patient_hiv_followup fup on fup.patient_id=e.patient_id
                        group by e.patient_id)reg on reg.patient_id=hiv.patient_id
       left outer join concept_name cn on cn.concept_id=hiv.entry_point  and cn.concept_name_type='FULLY_SPECIFIED'
                                            and cn.locale='en'
       left join (select o.person_id,o1.encounter_id, o.obs_id,o.concept_id as obs_group,o1.concept_id as concept_id,o1.value_coded
                  from obs o join obs o1 on o.obs_id = o1.obs_group_id) o1 on o1.encounter_id = hiv.encounter_id
where d.unique_patient_no is not null
group by d.patient_id
having min(hiv.visit_date) is not null and reg.art_start_date is not null;