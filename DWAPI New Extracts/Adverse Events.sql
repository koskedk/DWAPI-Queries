select v.patient_id as PatientPK,
       s.siteCode as SiteCode,
       de.unique_patient_no as PatientID,
       0 AS FacilityId,'KenyaEMR' as Emr,'Kenya HMIS II' as Project,
       s.FacilityName as FacilityName,
       v.visit_date as VisitDate,
       group_concat(case a.cause when 70056 then 'Abicavir' when 162298 then 'ACE inhibitors' when 70878 then 'Allopurinol' when 155060 then 'Aminoglycosides' when 162299 then 'ARBs (angiotensin II receptor blockers)' when 103727 then 'Aspirin' when 71647 then 'Atazanavir' when 72822 then 'Carbamazepine' when 162301 then 'Cephalosporins' when 73300 then 'Chloroquine'  when 73667 then 'Codeine' when 74807 then 'Didanosine' when 75523 then 'Efavirenz' when 162302 then 'Erythromycins' when
                        75948 then 'Ethambutol' when 77164 then 'Griseofulvin' when 162305 then 'Heparins' when 77675 then 'Hydralazine' when 78280 then 'Isoniazid' when 794 then 'Lopinavir/ritonavir' when 80106 then 'Morphine' when 80586 then 'Nevirapine' when 80696 then 'Nitrofurans' when 162306 then 'Non-steroidal anti-inflammatory drugs' when 81723 then 'Penicillamine' when 81724 then 'Penicillin' when 81959 then 'Phenolphthaleins' when 82023 then 'Phenytoin' when
                        82559 then 'Procainamide' when 82900 then 'Pyrazinamide' when 83018 then 'Quinidine' when 767 then 'Rifampin' when 162307 then 'Statins' when 84309 then 'Stavudine'
                                 when 162170 then 'Sulfonamides' when 84795 then 'Tenofovir' when 84893 then 'Tetracycline' when 86663 then 'Zidovudine' when 5622 then 'Other' end SEPARATOR '|') as AdverseEventCause,
       group_concat(case a.adverse_event when 1067 then 'Unknown' when  121629  then 'Anaemia' when 148888 then 'Anaphylaxis' when 148787 then 'Angioedema' when 120148 then 'Arrhythmia' when 108 then 'Bronchospasm' when 143264 then 'Cough' when 142412 then 'Diarrhea' when 118773 then 'Dystonia' when 140238 then 'Fever'
                                         when 140039 then 'Flushing' when 139581 then 'GI upset' when 139084 then 'Headache' when 159098 then 'Hepatotoxicity' when 111061 then 'Hives' when 117399 then 'Hypertension' when 879 then 'Itching' when 121677 then 'Mental status change' when 159347 then 'Musculoskeletal pain'
                                         when 121 then 'Myalgia' when 512 then 'Rash' when 5622 then 'Other' end  SEPARATOR '|') as AdverseEvent,
       group_concat(case a.severity when 1498 then 'Mild' when 1499 then 'Moderate' when 1500 then 'Severe' when 162819 then 'Fatal' when 1067 then 'Unknown' end SEPARATOR '|') as Severity,
       group_concat(a.start_date SEPARATOR '|') as AdverseEventStartDate,'' as AdverseEventEndDate,
       group_concat(case a.action_taken when 1257 then 'CONTINUE REGIMEN' when 1259 then 'SWITCHED REGIMEN'  when 981 then 'CHANGED DOSE'  when 1258 then 'SUBSTITUTED DRUG' when 1107 then 'NONE' when 1260 then 'STOP' when 5622 then 'Other' end SEPARATOR '|') as AdverseEventActionTaken,
       '' as AdverseEventClinicalOutcome, '' as AdverseEventIsPregnant, '' as AdverseEventRegimen,
       a.date_created as Date_Created, a.date_last_modified as Date_Last_Modified
from kenyaemr_etl.etl_adverse_events a
       inner join  kenyaemr_etl.etl_patient_hiv_followup v on v.encounter_id = a.encounter_id
       inner join kenyaemr_etl.etl_patient_demographics de on v.patient_id = de.patient_id
       inner join (select e.patient_id, max(e.visit_date) as latest_enrolment_date from kenyaemr_etl.etl_hiv_enrollment e group by e.patient_id)e on v.patient_id = e.patient_id
       left join (select d.patient_id as disc_patient,coalesce(max(date(d.effective_discontinuation_date)),date(d.visit_date)) Outcome_date from kenyaemr_etl.etl_patient_program_discontinuation d
                  where program_name='HIV' group by d.patient_id)d on d.disc_patient = v.patient_id
       join kenyaemr_etl.etl_default_facility_info s
where d.disc_patient is null or d.Outcome_date < e.latest_enrolment_date group by a.patient_id,a.encounter_id;