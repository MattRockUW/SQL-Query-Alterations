select 
orc.LOG_ID ,
orc.surgery_date, 
orc.CASE_CLASS_C , 
PAT_OR_ADM_LINK.CASE_ID,
orlog.PAT_ID,
peh.HSP_ACCOUNT_ID , 
har.HSP_ACCOUNT_ID,
patient.PAT_ID,
orcap.OR_PROC_ID , 
orcrsn.CANCEL_REASON_C, 
zcprocnotperf.PROC_NOT_PERF_C,
'joinleft',
orlog.CASE_ID,  PAT_OR_ADM_LINK.CASE_ID,
PAT_OR_ADM_LINK.OR_LINK_CSN,  peh.PAT_ENC_CSN_ID, 
orlog.PAT_ID,  patient.PAT_ID, 
peh.HSP_ACCOUNT_ID,  har.HSP_ACCOUNT_ID, 
patient.PAT_ID, id.PAT_ID,
--hb.pat_enc_csn_id, pb.pat_enc_csn_id,
'joinright', 
flb.*--, flb.*, peh.*
--, hb.*, pb.*
from [source_uwhealth].epic_or_case_cur orc
join [Source_UWHealth].EPIC_PAT_OR_ADM_LINK_CUR epoalc on orc.log_id = epoalc.case_id
JOIN [source_uwhealth].epic_or_log_cur orlog ON orc.LOG_ID = orlog.LOG_ID-- and orc.surgery_date between '2025-03-01' and '2025-04-01'
JOIN [source_uwhealth].epic_f_log_based_cur flb ON orlog.LOG_ID = flb.LOG_ID AND flb.DEPARTMENT_ID  = 34101 
--LEFT OUTER JOIN [source_uwhealth].epic_ZC_OR_CASE_CLASS_CUR zocc ON orc.CASE_CLASS_C = zocc.CASE_CLASS_C

JOIN  [source_uwhealth].epic_pat_or_adm_link_cur PAT_OR_ADM_LINK ON orlog.CASE_ID = PAT_OR_ADM_LINK.CASE_ID
JOIN [source_uwhealth].epic_pat_enc_hsp_cur peh ON PAT_OR_ADM_LINK.OR_LINK_CSN = peh.PAT_ENC_CSN_ID and peh.pat_enc_csn_id in 

LEFT OUTER JOIN [source_uwhealth].epic_PATIENT_cur patient ON orlog.PAT_ID = patient.PAT_ID
JOIN [source_uwhealth].epic_HSP_ACCOUNT_cur har ON peh.HSP_ACCOUNT_ID = har.HSP_ACCOUNT_ID
LEFT OUTER JOIN [source_uwhealth].epic_IDENTITY_ID_cur id ON patient.PAT_ID = id.PAT_ID AND id.IDENTITY_TYPE_ID = '0'
 

LEFT OUTER JOIN [source_uwhealth].epic_or_case_ALL_PROC_cur orcap ON orc.OR_CASE_ID = orcap.OR_CASE_ID -- BJ: 9/10/18
LEFT OUTER JOIN [source_uwhealth].epic_OR_PROC_cur orproc ON orcap.OR_PROC_ID = orproc.OR_PROC_ID
--LEFT OUTER JOIN ZC_OR_OP_REGION zoor ON orproc.OPERATING_REGION_C = zoor.OPERATING_REGION_C-- BJ: 08/10/18
-- Reflecting CASE Documentation: OR_PROC_CPT_ID varies by Member (1) not populated, (2) CPT mapped 1 PROC_ID to many CPTs to hopefully (3) CPT mapped to 1 PROC_ID
--LEFT OUTER JOIN OR_PROC_CPT_ID orproccpt ON orproc.OR_PROC_ID = orproccpt.OR_PROC_ID
LEFT OUTER JOIN [source_uwhealth].epic_ZC_OR_CANCEL_RSN_cur orcrsn ON orc.CANCEL_REASON_C = orcrsn.CANCEL_REASON_C
LEFT OUTER JOIN [source_uwhealth].epic_ZC_PROC_NOT_PERF_cur zcprocnotperf ON orlog.PROC_NOT_PERF_C = zcprocnotperf.PROC_NOT_PERF_C
LEFT OUTER JOIN [source_uwhealth].epic_HSP_ACCT_CPT_CODES_cur hacc ON ((har.HSP_ACCOUNT_ID = hacc.HSP_ACCOUNT_ID ) and (hacc.CPT_CODE_DATE between orlog.SURGERY_DATE and dateadd(day,1,hacc.CPT_CODE_DATE))) -- +1 day for cases running past midnight into next day.
     
--join [Mart_UWHealth].[STRATA_COST_ACCOUNT_HB] hb on epoalc.or_link_inp_id = hb.strata_encounter_rec_nbr
--join [Mart_UWHealth].[STRATA_COST_ACCOUNT_pB] pb on epoalc.or_link_inp_id = pb.strata_encounter_rec_nbr
--where orc.LOG_ID in ('1267482', '1513036')

--order by orc.LOG_ID 

/*

select * from [Source_UWHealth].EPIC_PAT_OR_ADM_LINK_CUR epoalc
--join [Mart_UWHealth].[STRATA_COST_ACCOUNT_HB] A on a.pat_enc_csn_id=epoalc.or_link_csn --and a.pat_enc_csn_id is not null
where LOG_ID = '1513036'

/*
select * from [Mart_UWHealth].[STRATA_COST_ACCOUNT_HB]
where patient_id = 'Z124982'
order by admit_dt desc

select * from [Mart_UWHealth].[STRATA_COST_ACCOUNT_PB]
where patient_id = 'Z124982'
order by admit_dt desc
*/

select * from [Mart_UWHealth].[STRATA_COST_ACCOUNT_HB]
where strata_encounter_rec_nbr in (491074434, 163856096, 492247683, 492246062)
or pat_enc_csn_id in (491074434, 163856096, 492247683, 492246062)

select * from [Mart_UWHealth].[STRATA_COST_ACCOUNT_PB]
where strata_encounter_rec_nbr in (491074434, 163856096, 492247683, 492246062)
or pat_enc_csn_id in (491074434, 163856096, 492247683, 492246062)

 */

select * from [Mart_UWHealth].[STRATA_COST_ACCOUNT_HB]
where admit_dt >= '2025-03-01'
and hl_location_id = '34100'

select * from [Mart_UWHealth].[STRATA_COST_ACCOUNT_PB]
where admit_dt between '2025-03-01' and '2025-03-31'
and place_of_service_id = '34100'
order by patient_epic_mrn



select  * From [source_uwhealth].epic_pat_or_adm_link_cur PAT_OR_ADM_LINK
--or_link_csn, pat_enc_csn_id
where or_link_csn in (select pat_enc_csn_id from [Mart_UWHealth].[STRATA_COST_ACCOUNT_PB]
	where admit_dt between '2025-03-01' and '2025-03-31'
and place_of_service_id = '34100')


select  * From [source_uwhealth].epic_pat_or_adm_link_cur PAT_OR_ADM_LINK where or_link_csn = '476221250' and pat_id = 'Z906941'

select * from [Mart_UWHealth].[STRATA_COST_ACCOUNT_PB]
where pat_enc_csn_id = '476221250'

select * from [Mart_UWHealth].STRATA_COST_CHARGE_ACTIVITY_PB
where pat_enc_csn_id = '476221250'

