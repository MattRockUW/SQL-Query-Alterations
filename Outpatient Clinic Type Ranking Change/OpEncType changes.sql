
;
with corrected as (
select op_enc_type, op_enc_hierarchy, count(distinct hsp_account_id) as 'CorrectedCountofHSPAccounts' from adhoc_uwhealth.EA_ACCOUNT_OP_ENC_TYPE
group by op_enc_type, op_enc_hierarchy
),
original as (
select op_enc_type, op_enc_hierarchy, count(distinct hsp_account_id) as 'OriginalCountofHSPAccounts' from [Mart_Load_UWHealth].EA_ACCOUNT_OP_ENC_TYPE
group by op_enc_type, op_enc_hierarchy
)

select * from original o
full outer join corrected c on o.op_enc_type = c.op_enc_type 
and o.op_enc_hierarchy = c.op_enc_hierarchy

;

with original as (
select op_enc_type,  count(distinct hsp_account_id) as 'OriginalCountofHSPAccounts' from [Mart_Load_UWHealth].EA_ACCOUNT_OP_ENC_TYPE
group by op_enc_type
),
corrected as (
select op_enc_type,  count(distinct hsp_account_id) as 'CorrectedCountofHSPAccounts' from adhoc_uwhealth.EA_ACCOUNT_OP_ENC_TYPE
group by op_enc_type
)
select * from original o
full outer join corrected c on o.op_enc_type = c.op_enc_type 

;
with diffs as (
select og.*, cor.prin_gl_building_id as 'CorrectedGLBuilding' from [Mart_Load_UWHealth].EA_ACCOUNT_PRIN_GL_BUILDING og
full outer join [adhoc_UWHealth].EA_ACCOUNT_PRIN_GL_BUILDING cor
on og.hsp_account_id = cor.hsp_Account_id
)

select Prin_GL_Building_ID, CorrectedGLBuilding, count(distinct hsp_account_id) from diffs
group by Prin_GL_Building_ID, CorrectedGLBuilding

;

with original as (
select op_enc_type,  count(distinct hsp_account_id) as 'OriginalCountofHSPAccounts' from [Mart_Load_UWHealth].EA_ACCOUNT_OP_ENC_TYPE
group by op_enc_type
),
corrected as (
select op_enc_type,  count(distinct hsp_account_id) as 'CorrectedCountofHSPAccounts' from adhoc_uwhealth.EA_ACCOUNT_OP_ENC_TYPE
group by op_enc_type
),
t as 
(select op_enc_type,  count(distinct hsp_account_id) as 'mart_T CountofHSPAccounts' from [Mart_load_UWHealth].[EA_ACCOUNT_OP_ENC_TYPE_T]
group by op_enc_type
)
select * from original o
full outer join corrected c on o.op_enc_type = c.op_enc_type 
full outer join t on t.op_enc_type = o.op_enc_type

;