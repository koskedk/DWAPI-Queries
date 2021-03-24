select a.patient_id as PatientPK,0 AS FacilityId,s.siteCode as SiteCode,de.unique_patient_no as PatientID,'KenyaEMR' as Emr,'Kenya HMIS II' as Project,s.FacilityName as FacilityName,
       a.visit_id as VisitID,a.visit_date as VisitDate,e.OTZEnrollmentDate,e.TransferInStatus, e.ModulesPreviouslyCovered
    ,concat_ws(',',NULLIF(if(a.orientation='Yes','OTZ Orientation',null),''),NULLIF(if(a.participation='Yes','OTZ Participation',''),''),NULLIF(if(a.making_decision_future='Yes','OTZ Making decisions for the future',''),'')
       ,NULLIF(if(a.transition_to_adult_care='Yes','OTZ Transition to Adult care',''),''),NULLIF(if(a.treatment_literacy='Yes','OTZ Treatment literacy',''),''),NULLIF(if(a.srh='Yes','OTZ SRH',''),''),
               NULLIF(if(a.beyond_third_ninety='Yes','OTZ Beyond the 3rd 90',null),'')) as ModulesCompletedToday,a.attended_support_group as SupportGroupInvolvement,
       a.remarks as Remarks,d.attrition_reason as TransitionAttritionReason, d.Outcome_date as OutcomeDate, a.date_created as Date_Created, greatest(NULLIF(a.date_last_modified,'0000-00-00'),NULLIF(a.date_last_modified,'0000-00-00')) as Date_Last_Modified
from kenyaemr_etl.etl_otz_activity a
       inner join kenyaemr_etl.etl_patient_demographics de on a.patient_id = de.patient_id
       inner join (select e.patient_id, greatest(max(e.visit_date),'0000-00-00') as OTZEnrollmentDate,mid(max(concat(e.visit_date,e.transfer_in)),11) as TransferInStatus,
                          concat_ws(',',NULLIF(if(e.orientation='Yes','OTZ Orientation',null),''),NULLIF(if(e.participation='Yes','OTZ Participation',''),''),NULLIF(if(e.making_decision_future='Yes','OTZ Making decisions for the future',''),''),
                                    NULLIF(if(e.transition_to_adult_care='Yes','OTZ Transition to Adult care',''),''),NULLIF(if(e.treatment_literacy='Yes','OTZ Treatment literacy',''),''),NULLIF(if(e.srh='Yes','OTZ SRH',''),''),
                                    NULLIF(if(e.beyond_third_ninety='Yes','OTZ Beyond the 3rd 90',null),'')) as ModulesPreviouslyCovered,e.date_created as date_created, e.date_last_modified as date_last_modified
                   from kenyaemr_etl.etl_otz_enrollment e group by e.patient_id)e on a.patient_id = e.patient_id
       left join (select d.patient_id,coalesce(max(date(d.effective_discontinuation_date)),date(d.visit_date)) Outcome_date,(case mid(max(concat(date(d.visit_date),d.discontinuation_reason)),11) when 5240 then 'LTFU' when 159492 then 'Transfer Out'
                                                                                                                                                                                                   when 160034 then 'Died' when 159836 then 'Opt out of OTZ' when 165363 then 'Transition to Adult Care' end ) as attrition_reason from kenyaemr_etl.etl_patient_program_discontinuation d
                  where program_name='OTZ' group by d.patient_id)d on d.patient_id = a.patient_id
       join kenyaemr_etl.etl_default_facility_info s;