;
with cur as (
select scah.op_enc_type,
enc_fiscal_year,
scah.tech_attr_prov_acad_dept_rollup,
scah.tech_attr_prov_acad_sect_rollup, 
count(distinct strata_encounter_rec_nbr) as 'CurrentRecordCount', 
sum(ADJUSTMENT_AMOUNT) as 'CurrentTotalADJUSTMENT_AMOUNT',
sum(CHARGE_AMOUNT) as 'CurrentTotalCHARGE_AMOUNT', 
--sum(VAR_DIRECT_COST) as 'Current Total VAR_DIRECT_COST', 
--sum(FIXED_DIRECT_COST) as 'Current Total FIXED_DIRECT_COST', 
--sum(DIRECT_COST) as 'Current Total DIRECT_COST', 
--sum(VAR_INDIRECT_COST) as 'Current Total VAR_INDIRECT_COST', 
--sum(FIXED_INDIRECT_COST) as 'Current Total FIXED_INDIRECT_COST', 
--sum(INDIRECT_COST) as 'Current Total INDIRECT_COST', 
sum(TOTAL_COST) as 'CurrentTotalTOTAL_COST', 
sum(CONTRIBUTION_MARGIN) as 'CurrentTotalCONTRIBUTION_MARGIN', 
sum(OPERATING_MARGIN) as 'CurrentTotalOPERATING_MARGIN'
from [Mart_UWHealth].[STRATA_COST_ACCOUNT_HB_T] scah
join [mart_load_uwhealth].[EA_ACCOUNT_OP_ENC_TYPE] eaoe on scah.[STRATA_ENCOUNTER_REC_NBR] = eaoe.hsp_account_id
group by scah.op_enc_type,
enc_fiscal_year,
tech_attr_prov_acad_dept_rollup,
tech_attr_prov_acad_sect_rollup
),

adj as 
(
select eaoe.op_enc_type,
enc_fiscal_year,
sp.ACADEMIC_CLINICAL_DEPT_ROLLUP as tech_attr_prov_acad_dept_rollup,
sp.ACADEMIC_CLINICAL_SECTION_ROLLUP as tech_attr_prov_acad_sect_rollup, 
count(distinct strata_encounter_rec_nbr) as 'AdjRecordCount', 
sum(ADJUSTMENT_AMOUNT) as 'AdjTotalADJUSTMENT_AMOUNT',
sum(CHARGE_AMOUNT) as 'AdjTotalCHARGE_AMOUNT', 
--sum(VAR_DIRECT_COST) as 'Adj Total VAR_DIRECT_COST', 
--sum(FIXED_DIRECT_COST) as 'Adj Total FIXED_DIRECT_COST', 
--sum(DIRECT_COST) as 'Adj Total DIRECT_COST', 
--sum(VAR_INDIRECT_COST) as 'Adj Total VAR_INDIRECT_COST', 
--sum(FIXED_INDIRECT_COST) as 'Adj Total FIXED_INDIRECT_COST', 
--sum(INDIRECT_COST) as 'Adj Total INDIRECT_COST', 
sum(TOTAL_COST) as 'AdjTotalTOTAL_COST', 
sum(CONTRIBUTION_MARGIN) as 'AdjTotalCONTRIBUTION_MARGIN', 
sum(OPERATING_MARGIN) as 'AdjTotalOPERATING_MARGIN'
from [Mart_UWHealth].[STRATA_COST_ACCOUNT_HB_T] scah
join [Adhoc_UWHealth].[EA_ACCOUNT_OP_ENC_TYPE] eaoe on scah.[STRATA_ENCOUNTER_REC_NBR] = eaoe.hsp_account_id
join [adhoc_UWHealth].[STRATA_BRIDGE_RANKED_PROCS_PROVS] brp on brp.hsp_account_id = scah.[STRATA_ENCOUNTER_REC_NBR]
join MART_LOAD_UWHEALTH.STRATA_PHYSICIAN sp on brp.UDF_TECHCHG_BUS_SEG_ATTR_PROV_ID = sp.code
group by eaoe.op_enc_type,
enc_fiscal_year,
sp.ACADEMIC_CLINICAL_DEPT_ROLLUP,
sp.ACADEMIC_CLINICAL_SECTION_ROLLUP
)

select 
coalesce(c.op_enc_type, a.op_enc_type) as 'op_enc_type',
coalesce(c.enc_fiscal_year, a.enc_fiscal_year) as 'enc_fiscal_year',
coalesce(c.tech_attr_prov_acad_dept_rollup, a.tech_attr_prov_acad_dept_rollup) as 'tech_attr_prov_acad_dept_rollup',
coalesce(c.tech_attr_prov_acad_sect_rollup, a.tech_attr_prov_acad_sect_rollup) as 'tech_attr_prov_acad_sect_rollup',
coalesce(CurrentRecordCount, 0) as 'Current Record Count', 	
coalesce(CurrentTotalADJUSTMENT_AMOUNT, 0) as 'Current Total ADJUSTMENT_AMOUNT', 		
coalesce(CurrentTotalCHARGE_AMOUNT, 0) as 'Current Total CHARGE_AMOUNT', 		
coalesce(CurrentTotalTOTAL_COST, 0) as 'Current Total TOTAL_COST', 		
coalesce(CurrentTotalCONTRIBUTION_MARGIN, 0) as 'Current Total CONTRIBUTION_MARGIN', 		
coalesce(CurrentTotalOPERATING_MARGIN, 0) as 'Current Total OPERATING_MARGIN', 		
coalesce(AdjRecordCount, 0) as 'Adj Record Count', 		
coalesce(AdjTotalADJUSTMENT_AMOUNT, 0) as 'Adj Total ADJUSTMENT_AMOUNT', 		
coalesce(AdjTotalCHARGE_AMOUNT, 0) as 'Adj Total CHARGE_AMOUNT', 		
coalesce(AdjTotalTOTAL_COST, 0) as 'Adj Total TOTAL_COST', 		
coalesce(AdjTotalCONTRIBUTION_MARGIN, 0) as 'Adj Total CONTRIBUTION_MARGIN', 	
coalesce(AdjTotalOPERATING_MARGIN, 0) as 'Adj Total OPERATING_MARGIN'
from cur c
full outer join adj a on 
a.op_enc_type = c.op_enc_type and
a.enc_fiscal_year = c.enc_fiscal_year and
a.tech_attr_prov_acad_dept_rollup = c.tech_attr_prov_acad_dept_rollup and
a.tech_attr_prov_acad_sect_rollup = c.tech_attr_prov_acad_sect_rollup
