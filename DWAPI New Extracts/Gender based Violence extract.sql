select v.patient_id as PatientPK,s.siteCode as SiteCode,0 AS FacilityId,de.unique_patient_no as PatientID,'KenyaEMR' as Emr,'Kenya HMIS II' as Project,s.FacilityName as FacilityName,
       v.visit_id as VisitID,v.visit_date as VisitDate,
       (case v.ipv when 1065 then 'Yes' when 1066 then 'No' end) as IPV,
       (case v.physical_ipv when 158358 then 'Yes' when 1066 then 'No' end) as PhysicalIPV,
       (case v.emotional_ipv when 118688 then 'Yes' when 1066 then 'No' end) as EmotionalIPV,
       (case v.sexual_ipv when 152370 then 'Yes' when 1066 then 'No' end) as SexualIPV,
       (case v.ipv_relationship when 1582 then 'Yes' when 1066 then 'No' end) as IPVRelationship,
       v.date_created as Date_Created, v.date_last_modified as Date_Last_Modified
from kenyaemr_etl.etl_gbv_screening v
       inner join kenyaemr_etl.etl_patient_demographics de on v.patient_id = de.patient_id
       inner join (select e.patient_id, max(e.visit_date) as latest_enrolment_date from kenyaemr_etl.etl_hiv_enrollment e group by e.patient_id)e on v.patient_id = e.patient_id
       left join (select d.patient_id as disc_patient,coalesce(max(date(d.effective_discontinuation_date)),date(d.visit_date)) Outcome_date from kenyaemr_etl.etl_patient_program_discontinuation d
                  where program_name='HIV' group by d.patient_id)d on d.disc_patient = v.patient_id
       join kenyaemr_etl.etl_default_facility_info s
where d.disc_patient is null or d.Outcome_date < e.latest_enrolment_date;