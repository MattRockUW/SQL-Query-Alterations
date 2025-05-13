
--drop table #temphspaccount
/*
create table #temphspaccount
(
	HSP_ACCOUNT_ID numeric(18,0) not null,
	ACADEMIC_CLINICAL_DEPT_ROLLUP varchar(40) not null,
	ACADEMIC_CLINICAL_SECTION_ROLLUP varchar(40) not null
)

insert into #temphspaccount
select HSP_ACCOUNT_ID,ACADEMIC_CLINICAL_DEPT_ROLLUP,ACADEMIC_CLINICAL_SECTION_ROLLUP
from [adhoc_UWHealth].[STRATA_BRIDGE_RANKED_PROCS_PROVS] brp --on brp.hsp_account_id = scah.[STRATA_ENCOUNTER_REC_NBR]
join MART_LOAD_UWHEALTH.STRATA_PHYSICIAN sp on brp.UDF_TECHCHG_BUS_SEG_ATTR_PROV_ID = sp.code
*/

select eaoe.op_enc_type,
scah.op_enc_type as 'original op_enc_type',
enc_fiscal_year,
t.ACADEMIC_CLINICAL_DEPT_ROLLUP,
tech_attr_prov_acad_dept_rollup,
t.ACADEMIC_CLINICAL_SECTION_ROLLUP,
tech_attr_prov_acad_sect_rollup, 
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
left join #temphspaccount t on t.hsp_account_id = scah.[STRATA_ENCOUNTER_REC_NBR] 
group by eaoe.op_enc_type,
enc_fiscal_year,
t.ACADEMIC_CLINICAL_DEPT_ROLLUP,
tech_attr_prov_acad_dept_rollup,
t.ACADEMIC_CLINICAL_SECTION_ROLLUP,
tech_attr_prov_acad_sect_rollup,
scah.op_enc_type
 

