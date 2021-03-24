select v.patient_id as PatientPK,0 AS FacilityId,s.siteCode as SiteCode,de.unique_patient_no as PatientID,'KenyaEMR' as Emr,'Kenya HMIS II' as Project,s.FacilityName as FacilityName,
       v.encounter_id as VisitID,v.visit_date as VisitDate,v.visit_date as OVCEnrollmentDate,coalesce(v.relationship_to_client,r.b_is_to_a) as RelationshipToClient,
       de.CPIMS_unique_identifier as CPIMSUniqueIdentifier,v.partner_offering_ovc as PartnerOfferingOVCServices,v.client_enrolled_cpims as EnrolledinCPIMS,
       concat_ws(',',NULLIF(if(v.ovc_comprehensive_program='Yes','OVC Comprehensive',''),''),
                 NULLIF(if(v.dreams_program='Yes','DREAMS',''),''),
                 NULLIF(if(v.ovc_preventive_program='Yes','OVC Preventive',''),'')) as ProgramModel,d.attrition_reason as OVCExitReason, d.Outcome_date as ExitDate, v.date_created as Date_Created, greatest(v.date_last_modified,v.date_last_modified) as Date_Last_Modified
from kenyaemr_etl.etl_ovc_enrolment v
       inner join kenyaemr_etl.etl_patient_demographics de on v.patient_id = de.patient_id
       left join (SELECT r.person_b,r.person_a,t.a_is_to_b,t.b_is_to_a FROM openmrs.relationship r inner join openmrs.relationship_type t on r.relationship = t.relationship_type_id where r.voided =0)r on v.patient_id = r.person_b
       left join (select d.patient_id,coalesce(max(date(d.effective_discontinuation_date)),date(d.visit_date)) Outcome_date,(case mid(max(concat(date(d.visit_date),d.discontinuation_reason)),11) when 160036 then 'Transfer out to a PEPFAR supported facility' when 159492 then 'Transfer out to a non PEPFAR supported facility'
                                                                                                                                                                                                   when 165219 then 'Exit without graduation' when 1267 then 'Graduated out of OVC' when 160034 then 'Died' end ) as attrition_reason from kenyaemr_etl.etl_patient_program_discontinuation d
                  where program_name='OVC' group by d.patient_id)d on d.patient_id = v.patient_id
       join kenyaemr_etl.etl_default_facility_info s;