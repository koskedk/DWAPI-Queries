select v.patient_id as PatientPK,
       s.siteCode as SiteCode,
       de.unique_patient_no as PatientID,
       'KenyaEMR' as Emr,
       'Kenya HMIS II' as Project,
       0 AS FacilityId,
       s.FacilityName as FacilityName,
       v.visit_id as VisitID,v.visit_date as VisitDate,v.session_number as SessionNumber,v.first_session_date as DateOfFirstSession,v.pill_count as PillCountAdherence,
       '' as MMAS4_1,'' as MMAS4_2,'' as MMAS4_3,'' as MMAS4_4,'' as MMSA8_1,'' as MMSA8_2,'' as MMSA8_3,'' as MMSA8_4,
       v.arv_adherence as MMSAScore ,v.has_vl_results as EACRecievedVL, v.vl_results_suppressed as EACVL,v.vl_results_feeling as EACVLConcerns,
       v.cause_of_high_vl as EACVLThoughts,v.way_forward as EACWayForward,v.patient_hiv_knowledge as EACCognitiveBarrier,v.patient_drugs_uptake as EACBehaviouralBarrier_1,
       v.patient_drugs_reminder_tools as EACBehaviouralBarrier_2,v.patient_drugs_uptake_during_travels as EACBehaviouralBarrier_3,v.patient_drugs_side_effects_response as EACBehaviouralBarrier_4,
       v.patient_drugs_uptake_most_difficult_times as EACBehaviouralBarrier_5,v.patient_drugs_daily_uptake_feeling as EACEmotionalBarriers_1,v.patient_ambitions as EACEmotionalBarriers_2,
       v.patient_has_people_to_talk as EACEconBarrier_1,v.patient_enlisting_social_support as EACEconBarrier_2,v.patient_income_sources as EACEconBarrier_3,v.patient_challenges_reaching_clinic as EACEconBarrier_4,
       v.patient_worried_of_accidental_disclosure as EACEconBarrier_5, v.patient_treated_differently as EACEconBarrier_6,v.stigma_hinders_adherence as EACEconBarrier_7,v.patient_tried_faith_healing as EACEconBarrier_8,
       v.patient_adherence_improved as EACReviewImprovement,v.patient_doses_missed as EACReviewMissedDoses,v.review_and_barriers_to_adherence as EACReviewStrategy,v.other_referrals as EACReferral,
       v.appointments_honoured as EACReferralApp,v.referral_experience as EACReferralExperience,v.home_visit_benefit as EACHomevisit,v.adherence_plan as EACAdherencePlan,v.next_appointment_date as EACFollowupDate,
       v.date_created as Date_Created, v.date_last_modified as Date_Last_Modified
from kenyaemr_etl.etl_enhanced_adherence v
       inner join kenyaemr_etl.etl_patient_demographics de on v.patient_id = de.patient_id
       inner join (select e.patient_id, max(e.visit_date) as latest_enrolment_date from kenyaemr_etl.etl_hiv_enrollment e group by e.patient_id)e on v.patient_id = e.patient_id
       left join (select d.patient_id as disc_patient,coalesce(max(date(d.effective_discontinuation_date)),date(d.visit_date)) Outcome_date from kenyaemr_etl.etl_patient_program_discontinuation d
                  where program_name='HIV' group by d.patient_id)d on d.disc_patient = v.patient_id
       join kenyaemr_etl.etl_default_facility_info s
where d.disc_patient is null or d.Outcome_date < e.latest_enrolment_date;