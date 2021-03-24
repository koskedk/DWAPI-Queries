select v.patient_id as PatientPK,
       s.siteCode as SiteCode,
       de.unique_patient_no as PatientID,
       0 AS FacilityId,
       'KenyaEMR' as Emr,'Kenya HMIS II' as Project,s.FacilityName as FacilityName,
       v.visit_id as VisitID,v.visit_date as VisitDate,
       '' as PHQ9_1,'' as PHQ9_2,'' as PHQ9_3,'' as PHQ9_4,'' as PHQ9_5,'' as PHQ9_6,'' as PHQ9_7,'' as PHQ9_8,'' as PHQ9_9,'' as DepressionAssesmentScore,
       (case v.PHQ_9_rating when 1115 then 'Depression unlikely' when 157790 then 'Mild depression'
                            when 134011 then 'Moderate depression' when 134017 then 'Moderate severe depression' when 126627 then 'Severe depression' end) as PHQ_9_rating,
       v.date_created as Date_Created, v.date_last_modified as Date_Last_Modified
from kenyaemr_etl.etl_depression_screening v
       inner join kenyaemr_etl.etl_patient_demographics de on v.patient_id = de.patient_id
       inner join (select e.patient_id, max(e.visit_date) as latest_enrolment_date from kenyaemr_etl.etl_hiv_enrollment e group by e.patient_id)e on v.patient_id = e.patient_id
       left join (select d.patient_id as disc_patient,coalesce(max(date(d.effective_discontinuation_date)),date(d.visit_date)) Outcome_date from kenyaemr_etl.etl_patient_program_discontinuation d
                  where program_name='HIV' group by d.patient_id)d on d.disc_patient = v.patient_id
       join kenyaemr_etl.etl_default_facility_info s
where d.disc_patient is null or d.Outcome_date < e.latest_enrolment_date;

Fixed issues on coded reason not on fp,adverse events and allergies and chronic illnesses fields not populating, coded reason for phq9 rating
