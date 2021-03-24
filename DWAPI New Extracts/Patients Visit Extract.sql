select distinct
                '' AS SatelliteName, 0 AS FacilityId, d.unique_patient_no as PatientID,
                d.patient_id as PatientPK,
                (select name from location
                 where location_id in (select property_value
                                       from global_property
                                       where property='kenyaemr.defaultLocation')) as FacilityName,
                (select value_reference from location_attribute
                 where location_id in (select property_value
                                       from global_property
                                       where property='kenyaemr.defaultLocation') and attribute_type_id=1) as SiteCode,
                fup.visit_id as VisitId,
                case when fup.visit_date < '1990-01-01' then null else CAST(fup.visit_date AS DATE) end  AS VisitDate,
                'Out Patient' as Service,
                (case fup.visit_scheduled when 1 then "Scheduled" when 2 then 'Unscheduled' else "" end ) as VisitType,
                (case fup.person_present when 978 then 'Self' when 161642 then 'Treatment supporter' when 159802 then 'Refill visit documentation' when 5622 then 'Other' end) as VisitBy,
                case fup.who_stage
                  when 1220 then 'WHO I'
                  when 1221 then 'WHO II'
                  when 1222 then 'WHO III'
                  when 1223 then 'WHO IV'
                  when 1204 then 'WHO I'
                  when 1205 then 'WHO II'
                  when 1206 then 'WHO III'
                  when 1207 then 'WHO IV'
                  else ''
                    end as WHOStage,
                null as WABStage,
                case fup.pregnancy_status
                  when 1065 then 'Yes'
                  when 1066 then 'No'
                    end as Pregnant,
                CAST(fup.last_menstrual_period AS DATE) as LMP,
                CAST(fup.expected_delivery_date AS DATE) as EDD,
                fup.height as Height,
                fup.weight as Weight,
                concat(fup.systolic_pressure,'/',fup.diastolic_pressure) as BP,
                fup.temperature as Temp,
                fup.pulse_rate as PulseRate,
                fup.respiratory_rate as RespiratoryRate,
                fup.oxygen_saturation as OxygenSaturation,
                fup.muac as Muac,
                (case fup.nutritional_status when 1115 then "Normal" when 163302 then "Severe acute malnutrition" when 163303 then "Moderate acute malnutrition" when 114413 then "Overweight/Obese" else "" end) as nutritional_status,
                (case fup.ever_had_menses when 1065 then 'Yes' when 1066 then 'No' when 1175 then 'N/A' end) as EverHadMenses,
                null as Breastfeeding,
                (case menopausal when 113928 then 'Yes' end) as Menopausal,
                (case prophylaxis_given when 105281 then 'Cotrimoxazole' when 74250 then 'Dapsone' when 1107 then 'None'  end) as ProphylaxisUsed,
                (case fup.ctx_adherence when 159405 then 'Good' when 163794 then 'Fair' when 159407 then 'Bad' else '' end) as CTXAdherence,
                de.regimen as CurrentRegimen,
                (case fup.reason_not_using_family_planning
                   when 160572 then "Thinks can't get pregnant" when 160573 then "Not sexually active now" when 5622 then "Other" else "" end) as NoFPReason,
                'ART|CTX' as AdherenceCategory,
                concat(
                  IF(fup.arv_adherence=159405, 'Good', IF(fup.arv_adherence=159406, 'Fair', IF(fup.arv_adherence=159407, 'Poor', ''))), IF(fup.arv_adherence in (159405,159406,159407), '|','') ,
                  IF(fup.ctx_adherence=159405, 'Good', IF(fup.ctx_adherence=159406, 'Fair', IF(fup.ctx_adherence=159407, 'Poor', '')))
                    ) AS Adherence,
                (case next_appointment_reason when 160523 then 'Follow up' when 1283 then 'Lab tests' when 159382 then 'Counseling' when 160521 then 'Pharmacy Refill' when 5622 then 'Other'  else '' end) as TCAReason,
                fup.clinical_notes as ClinicalNotes,
                '' as OI,
                NULL as OIDate,
                case ifnull(fup.family_planning_status,'')
                  when 695 then 'Currently using FP'
                  when 160652 then 'Not using FP'
                  when 1360 then 'Wants FP'
                  else ''
                    end as FamilyPlanningMethod,
                concat_ws('|',
                          nullif(case fup.condom_provided
                                   when 1065 then 'Condoms'
                                   else ''
                                     end,''),
                          nullif(case fup.pwp_disclosure
                                   when 1065 then 'Disclosure'
                                   else ''
                                     end,''),
                          nullif(case fup.pwp_partner_tested
                                   when 1065 then 'Partner Testing'
                                   else ''
                                     end,''),
                          nullif(case fup.screened_for_sti
                                   when 1065 then 'Screened for STI'
                                   else ''
                                     end,''))as PwP,
                if(fup.last_menstrual_period is not null, timestampdiff(week,fup.last_menstrual_period,fup.visit_date),'') as GestationAge,
                case when fup.next_appointment_date < '1990-01-01' then null else CAST(fup.next_appointment_date AS DATE) end  AS NextAppointmentDate,
                'KenyaEMR' as Emr,
                'Kenya HMIS II' as Project,
                CAST(fup.substitution_first_line_regimen_date AS DATE)  AS SubstitutionFirstlineRegimenDate,
                fup.substitution_first_line_regimen_reason AS SubstitutionFirstlineRegimenReason,
                CAST(fup.substitution_second_line_regimen_date AS DATE) AS SubstitutionSecondlineRegimenDate,
                fup.substitution_second_line_regimen_reason AS SubstitutionSecondlineRegimenReason,
                CAST(fup.second_line_regimen_change_date AS DATE) AS SecondlineRegimenChangeDate,
                fup.second_line_regimen_change_reason AS SecondlineRegimenChangeReason,
                CASE fup.stability
                  WHEN 1 THEN 'Stable'
                  WHEN 2 THEN 'Not Stable' END as StabilityAssessment,
                dc.name as DifferentiatedCare,
                CASE
                  WHEN fup.key_population_type  IS NOT NULL AND fup.key_population_type  !=1175
                          THEN 'Key population'
                  ELSE pt.name  END as PopulationType,
                case fup.key_population_type
                  WHEN 105 THEN 'PWID'
                  WHEN 160578 THEN 'MSM'
                  WHEN 160579  THEN 'FSW'
                  when 165084 then 'MSW'
                  when 165085 then  'PWUD'
                  when 165100 then 'Transgender'
                  WHEN 1175 THEN 'N/A'
                  ELSE null  END as KeyPopulationType,
                '' as HCWConcern,
                fup.date_created as Date_Created,
                GREATEST(COALESCE(d.date_last_modified, fup.date_last_modified), COALESCE(fup.date_last_modified, d.date_last_modified)) as Date_Last_Modified
from kenyaemr_etl.etl_patient_demographics d
       join kenyaemr_etl.etl_patient_hiv_followup fup on fup.patient_id=d.patient_id
       left join concept_name dc on dc.concept_id =  fup.differentiated_care and dc.concept_name_type='FULLY_SPECIFIED'
       left join concept_name pt on fup.population_type = pt.concept_id AND pt.concept_name_type='FULLY_SPECIFIED'
       left join (select de.patient_id,mid(max(concat(de.visit_date,de.regimen)),11) as regimen from kenyaemr_etl.etl_drug_event de
                  where de.discontinued is null group by de.patient_id)de on fup.patient_id = de.patient_id
where d.unique_patient_no is not null and fup.visit_date > '1990-01-01' and fup.visit_id is not null;