#HTS - Tested
#===========
select 'HTS_TESTED' as 'INDICATOR',count(distinct t.patient_id) AS INDICATOR_VALUE,date_format(last_day(date_sub(current_date(),interval 1 MONTH)),'%Y%b%d') as 'INDICATOR_DATE'
from kenyaemr_etl.etl_hts_test t
inner join kenyaemr_etl.etl_patient_demographics d on d.patient_id = t.patient_id where test_type =1 and t.voided = 0 and t.visit_date between DATE_ADD(DATE_SUB(current_date(),INTERVAL DAYOFMONTH(current_date())-1 DAY),INTERVAL -1 MONTH)
    and date(last_day(date_sub(current_date(),interval 1 MONTH)));

# Retention on ART on ART 12 months
#==================================
select  'RETENTION_ON_ART_12_MONTHS' as 'INDICATOR',count(net.patient_id) AS INDICATOR_VALUE,date_format(last_day(date_sub(current_date(),interval 1 MONTH)),'%Y%b%d') as 'INDICATOR_DATE'
from (
     select e.patient_id,e.date_started, d.visit_date as dis_date, if(d.visit_date is not null and d.discontinuation_reason=159492, 1, 0) as TOut, d.date_died,
            mid(max(concat(fup.visit_date,fup.next_appointment_date)),11) as latest_tca,
            if(enr.transfer_in_date is not null, 1, 0) as TIn, max(fup.visit_date) as latest_vis_date
     from (select e.patient_id,p.dob,p.Gender,min(e.date_started) as date_started
           from kenyaemr_etl.etl_drug_event e
                  join kenyaemr_etl.etl_patient_demographics p on p.patient_id=e.patient_id
           where e.program='HIV'
           group by e.patient_id) e
            left outer join kenyaemr_etl.etl_patient_program_discontinuation d on d.patient_id=e.patient_id and d.program_uuid='2bdada65-4c72-4a48-8730-859890e25cee'
            left outer join kenyaemr_etl.etl_hiv_enrollment enr on enr.patient_id=e.patient_id
            left outer join kenyaemr_etl.etl_patient_hiv_followup fup on fup.patient_id=e.patient_id
     where  date(e.date_started) between DATE_ADD(DATE_SUB(current_date(),INTERVAL DAYOFMONTH(current_date())-1 DAY),INTERVAL -1 YEAR) and date(last_day(date_sub(current_date(),interval 1 YEAR)))
     group by e.patient_id
     having   (dis_date>date(last_day(date_sub(current_date(),interval 1 MONTH))) or dis_date is null or TOut=0 ) and (
         (date(latest_tca) > date(last_day(date_sub(current_date(),interval 1 MONTH))) and (date(latest_tca) > date(dis_date) or dis_date is null ))  or
         (((date(latest_tca) between DATE_ADD(DATE_SUB(current_date(),INTERVAL DAYOFMONTH(current_date())-1 DAY),INTERVAL -1 MONTH) and date(last_day(date_sub(current_date(),interval 1 MONTH)))) and (date(latest_tca) >= date(latest_vis_date)) ) ) or
         (((date(latest_tca) between DATE_ADD(DATE_SUB(current_date(),INTERVAL DAYOFMONTH(current_date())-1 DAY),INTERVAL -1 MONTH) and date(last_day(date_sub(current_date(),interval 1 MONTH)))) and (date(latest_vis_date) >= date(latest_tca)) or date(latest_tca) > curdate()) ) and
         (date(latest_tca) > date(dis_date) or dis_date is null )
         )
     )net;

#Retention on ART Viral load <1000_12 months
#===========================================
select  'RETENTION_ON_ART_12_MONTHS' as 'INDICATOR',count(net.patient_id) AS INDICATOR_VALUE,date_format(last_day(date_sub(current_date(),interval 1 MONTH)),'%Y%b%d') as 'INDICATOR_DATE'
from (
     select e.patient_id,e.date_started, d.visit_date as dis_date, if(d.visit_date is not null and d.discontinuation_reason=159492, 1, 0) as TOut, d.date_died,
            mid(max(concat(fup.visit_date,fup.next_appointment_date)),11) as latest_tca,
            if(enr.transfer_in_date is not null, 1, 0) as TIn, max(fup.visit_date) as latest_vis_date
     from (select e.patient_id,p.dob,p.Gender,min(e.date_started) as date_started
           from kenyaemr_etl.etl_drug_event e
                  join kenyaemr_etl.etl_patient_demographics p on p.patient_id=e.patient_id
           where e.program='HIV'
           group by e.patient_id) e
            left outer join kenyaemr_etl.etl_patient_program_discontinuation d on d.patient_id=e.patient_id and d.program_uuid='2bdada65-4c72-4a48-8730-859890e25cee'
            left outer join kenyaemr_etl.etl_hiv_enrollment enr on enr.patient_id=e.patient_id
            left outer join kenyaemr_etl.etl_patient_hiv_followup fup on fup.patient_id=e.patient_id
     inner join(select
                      patient_id,
                      max(visit_date) as vl_date,
                      if(mid(max(concat(visit_date,lab_test)),11) = 856, mid(max(concat(visit_date,test_result)),11), if(mid(max(concat(visit_date,lab_test)),11)=1305 and mid(max(concat(visit_date,test_result)),11) = 1302, "LDL","")) as vl_result,
                      mid(max(concat(visit_date,urgency)),11) as urgency
                     from kenyaemr_etl.etl_laboratory_extract
               where lab_test in (1305, 856) and visit_date between DATE_ADD(DATE_SUB(current_date(),INTERVAL DAYOFMONTH(current_date())-1 DAY),INTERVAL -12 MONTH) and date(date(last_day(date_sub(current_date(),interval 1 MONTH))))
               group by patient_id
               having mid(max(concat(visit_date,test_result)),11) is not null or mid(max(concat(visit_date,test_result)),11) <> '') vl on e.patient_id = vl.patient_id
     where  date(e.date_started) between DATE_ADD(DATE_SUB(current_date(),INTERVAL DAYOFMONTH(current_date())-1 DAY),INTERVAL -1 YEAR) and date(last_day(date_sub(current_date(),interval 1 YEAR))) and (vl.vl_result < 1000 or vl.vl_result = 'LDL')
     group by e.patient_id
     having (dis_date>date(last_day(date_sub(current_date(),interval 1 MONTH))) or dis_date is null or TOut=0 ) and (
         (date(latest_tca) > date(last_day(date_sub(current_date(),interval 1 MONTH))) and (date(latest_tca) > date(dis_date) or dis_date is null ))  or
         (((date(latest_tca) between DATE_ADD(DATE_SUB(current_date(),INTERVAL DAYOFMONTH(current_date())-1 DAY),INTERVAL -1 MONTH) and date(last_day(date_sub(current_date(),interval 1 MONTH)))) and (date(latest_tca) >= date(latest_vis_date)) ) ) or
         (((date(latest_tca) between DATE_ADD(DATE_SUB(current_date(),INTERVAL DAYOFMONTH(current_date())-1 DAY),INTERVAL -1 MONTH) and date(last_day(date_sub(current_date(),interval 1 MONTH)))) and (date(latest_vis_date) >= date(latest_tca)) or date(latest_tca) > curdate()) ) and
         (date(latest_tca) > date(dis_date) or dis_date is null )
         )
     )net;

#MFLCode changes in EMR
#======================
--Test DWAPI queries fetch facility name and site code from kenyaemr_etl.etl_default_facility_info

#HTS_TESTED_POS
#===============
select 'HTS_TST_POS' AS 'INDICATOR', count(distinct t.patient_id) as 'INDICATOR_VALUE',date_format(last_day(date_sub(current_date(),interval 1 MONTH)),'%Y%b%d') as 'INDICATOR_DATE'
from  kenyaemr_etl.etl_hts_test t
inner join kenyaemr_etl.etl_patient_demographics d on d.patient_id=t.patient_id
where t.voided=0 and date(t.visit_date) between DATE_ADD(DATE_SUB(current_date(),INTERVAL DAYOFMONTH(current_date())-1 DAY),INTERVAL -1 MONTH) and date(last_day(date_sub(current_date(),interval 1 MONTH))) and t.test_type=2 and t.final_test_result='Positive';

#HTS-Linked
#==============
select 'HTS_LINKED' AS 'INDICATOR', count(distinct t.patient_id) as 'INDICATOR_VALUE',date_format(last_day(date_sub(current_date(),interval 1 MONTH)),'%Y%b%d') as 'INDICATOR_DATE'
from kenyaemr_etl.etl_hts_referral_and_linkage r
       inner join kenyaemr_etl.etl_hts_test t on r.patient_id = t.patient_id and t.final_test_result = 'Positive'
where (r.ccc_number !='' or r.ccc_number IS NOT NULL) and (r.facility_linked_to !='' or r.facility_linked_to IS NOT NULL)
  and t.visit_date between DATE_ADD(DATE_SUB(current_date(),INTERVAL DAYOFMONTH(current_date())-1 DAY),INTERVAL -1 MONTH) and  date(last_day(date_sub(current_date(),interval 1 MONTH)));
  
  #HTS_Index
#=============
select 'HTS_INDEX' AS 'INDICATOR', count(distinct c.patient_id) as 'INDICATOR_VALUE',date_format(last_day(date_sub(current_date(),interval 1 MONTH)),'%Y%b%d') as 'INDICATOR_DATE'
from openmrs.kenyaemr_hiv_testing_patient_contact c inner join kenyaemr_etl.etl_hts_test t
         on c.patient_id = t.patient_id where c.relationship_type in(971, 972, 1528, 162221, 163565, 970, 5617)
                                                  and t.voided=0 and c.voided = 0 and date(c.date_created)
                                                          between DATE_ADD(DATE_SUB(current_date(),INTERVAL DAYOFMONTH(current_date())-1 DAY),INTERVAL -3 MONTH) and date(last_day(date_sub(current_date(),interval 1 MONTH))) group by t.patient_id;

#TX_PVLS

select 'TX_PVLS' AS 'INDICATOR', count(distinct t.patient_id) as 'INDICATOR_VALUE',date_format(last_day(date_sub(current_date(),interval 1 MONTH)),'%Y%b%d') as 'INDICATOR_DATE'
from(
    select fup.visit_date,fup.patient_id, max(e.visit_date) as enroll_date,
           greatest(max(e.visit_date), ifnull(max(date(e.transfer_in_date)),'0000-00-00')) as latest_enrolment_date,
           greatest(max(fup.visit_date), ifnull(max(d.visit_date),'0000-00-00')) as latest_vis_date,
           greatest(mid(max(concat(fup.visit_date,fup.next_appointment_date)),11), ifnull(max(d.visit_date),'0000-00-00')) as latest_tca,
           d.patient_id as disc_patient,
           d.effective_disc_date as effective_disc_date,
           max(d.visit_date) as date_discontinued,
           de.patient_id as started_on_drugs,
           vl.vl_date as vl_date,
           vl.vl_result as vl_result
    from kenyaemr_etl.etl_patient_hiv_followup fup
           join kenyaemr_etl.etl_patient_demographics p on p.patient_id=fup.patient_id
           join kenyaemr_etl.etl_hiv_enrollment e on fup.patient_id=e.patient_id
           inner join kenyaemr_etl.etl_drug_event de on e.patient_id = de.patient_id and de.program='HIV' and date(date_started) <= date_sub( date(last_day(date_sub(current_date(),interval 1 MONTH))), INTERVAL  3 MONTH )
           left outer JOIN
             (select patient_id, coalesce(date(effective_discontinuation_date),visit_date) visit_date,max(date(effective_discontinuation_date)) as effective_disc_date from kenyaemr_etl.etl_patient_program_discontinuation
              where date(visit_date) <= date(last_day(date_sub(current_date(),interval 1 MONTH))) and program_name='HIV'
              group by patient_id
             ) d on d.patient_id = fup.patient_id
           inner join  (
                       select
                              patient_id,
                              max(visit_date) as vl_date,
                              if(mid(max(concat(visit_date,lab_test)),11) = 856, mid(max(concat(visit_date,test_result)),11), if(mid(max(concat(visit_date,lab_test)),11)=1305 and mid(max(concat(visit_date,test_result)),11) = 1302, "LDL","")) as vl_result,
                              mid(max(concat(visit_date,urgency)),11) as urgency
                       from kenyaemr_etl.etl_laboratory_extract
                       where lab_test in (1305, 856) and visit_date between DATE_ADD(DATE_SUB(current_date(),INTERVAL DAYOFMONTH(current_date())-1 DAY),INTERVAL -12 MONTH) and date(date(last_day(date_sub(current_date(),interval 1 MONTH))))
                       group by patient_id
                       having max(test_result) is not null or max(test_result) <> ''
                       ) vl on vl.patient_id = fup.patient_id
    where fup.visit_date <= date(last_day(date_sub(current_date(),interval 1 MONTH)))
    group by patient_id
    having (started_on_drugs is not null and started_on_drugs <> '' ) and (
        (
            ((timestampdiff(DAY,date(latest_tca),date(last_day(date_sub(current_date(),interval 1 MONTH)))) <= 30 or timestampdiff(DAY,date(latest_tca),date(curdate())) <= 30) and (date(d.effective_disc_date) > date(last_day(date_sub(current_date(),interval 1 MONTH))) or d.effective_disc_date is null))
              and (date(latest_vis_date) >= date(date_discontinued) or date(latest_tca) >= date(date_discontinued) or disc_patient is null)
            )
        )
    ) t;

#HTS_Index_Pos
#===============
select 'HTS_INDEX_POS' AS 'INDICATOR', count( distinct c.patient_id) as 'INDICATOR_VALUE',date_format(last_day(date_sub(current_date(),interval 1 MONTH)),'%Y%b%d') as 'INDICATOR_DATE'
from openmrs.kenyaemr_hiv_testing_patient_contact c inner join kenyaemr_etl.etl_hts_test t
         on c.patient_id = t.patient_id where c.relationship_type in(971, 972, 1528, 162221, 163565, 970, 5617)
                                          and t.final_test_result = "Positive" and t.voided=0 and c.voided = 0 and t.test_type = 2 and date(c.date_created)
                                                  between DATE_ADD(DATE_SUB(current_date(),INTERVAL DAYOFMONTH(current_date())-1 DAY),INTERVAL -3 MONTH) and date(last_day(date_sub(current_date(),interval 1 MONTH)));


#ETL Refresh
SELECT script_name as 'INDICATOR_NAME', stop_time as 'INDICATOR_VALUE',DATE_FORMAT(stop_time,'%Y%b%d') as 'INDICATOR_MONTH'
FROM kenyaemr_etl.etl_script_status s where s.error is null and script_name='scheduled_updates'
order by INDICATOR_VALUE desc
limit 1;