select
       '' AS SatelliteName,
       0 AS FacilityId,
       d.unique_patient_no as PatientID,
       d.patient_id as PatientPK,
       (select siteCode from kenyaemr_etl.etl_default_facility_info) as SiteCode,
       (select FacilityName from kenyaemr_etl.etl_default_facility_info) as FacilityName,
       '' as ExitDescription,
       'KenyaEMR' as Emr,
       'Kenya HMIS II' as Project,
       max(date(disc.visit_date)) AS ExitDate,
       mid(max(concat(visit_date,(case discontinuation_reason
                                    when 159492 then 'Transfer Out'
                                    when 160034 then 'Died'
                                    when 5240 then 'LTFU'
                                    when 819 then 'Stopped Treatment'
                                    else '' end), '' )),20) as ExitReason,
       if(e.latest_enrolment_date > greatest(coalesce(max(disc.effective_discontinuation_date),'0000-00-00'),coalesce(max(disc.visit_date),'0000-00-00')),e.latest_enrolment_date,null ) as ReEnrollmentDate,
       (case mid(max(concat(date(disc.visit_date),disc.trf_out_verified)),11) when 1065 then 'Yes' when 1066 then 'No' end) as TOVerified,
       mid(max(concat(date(disc.visit_date),disc.trf_out_verification_date)),11) as TOVerifiedDate,
       disc.date_created as Date_Created,
       disc.date_last_modified as Date_Last_Modified
from kenyaemr_etl.etl_patient_program_discontinuation disc
       left join (select e.patient_id as patient_id, max(e.visit_date) as latest_enrolment_date, mid(max(concat(e.visit_date,e.patient_type)),11) as patient_type from kenyaemr_etl.etl_hiv_enrollment e
                  group by e.patient_id) e on e.patient_id = disc.patient_id
       join kenyaemr_etl.etl_patient_demographics d on d.patient_id=disc.patient_id
where d.unique_patient_no is not null and disc.program_name='HIV'
group by PatientID
order by disc.visit_date ASC;