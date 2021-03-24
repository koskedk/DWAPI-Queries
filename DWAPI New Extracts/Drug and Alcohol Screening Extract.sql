select v.patient_id as PatientPK,
       s.siteCode as SiteCode,
       de.unique_patient_no as PatientID,
       'KenyaEMR' as Emr,'Kenya HMIS II' as Project,
       s.FacilityName as FacilityName,
       0 AS FacilityId,
       v.visit_id as VisitID,v.visit_date as VisitDate,
       (case v.alcohol_drinking_frequency when 1090 then 'Never' when 1091 then 'Monthly or less' when 1092 then '2 to 4 times a month' when 1093 then '2 to 3 times a week' when 1094 then '4 or More Times a Week' end) as DrinkingAlcohol,
       (case v.smoking_frequency when 1090 then 'Never smoked' when 156358 then 'Former cigarette smoker' when 163197 then 'Current some day smoker' when 163196 then 'Current light tobacco smoker'
                                 when 163195 then 'Current heavy tobacco smoker' when 163200 then 'Unknown if ever smoked' end) as Smoking,
       (case v.drugs_use_frequency when 1090 then 'Never' when 1091 then 'Monthly or less' when 1092 then '2 to 4 times a month' when 1093 then '2 to 3 times a week' when 1094 then '4 or More Times a Week' end) as DrugUse,
       v.date_created as Date_Created, v.date_last_modified as Date_Last_Modified
from kenyaemr_etl.etl_alcohol_drug_abuse_screening v
       inner join kenyaemr_etl.etl_patient_demographics de on v.patient_id = de.patient_id
       inner join (select e.patient_id, max(e.visit_date) as latest_enrolment_date from kenyaemr_etl.etl_hiv_enrollment e group by e.patient_id)e on v.patient_id = e.patient_id
       left join (select d.patient_id as disc_patient,coalesce(max(date(d.effective_discontinuation_date)),date(d.visit_date)) Outcome_date from kenyaemr_etl.etl_patient_program_discontinuation d
                  where program_name='HIV' group by d.patient_id)d on d.disc_patient = v.patient_id
       join kenyaemr_etl.etl_default_facility_info s
where d.disc_patient is null or d.Outcome_date < e.latest_enrolment_date;