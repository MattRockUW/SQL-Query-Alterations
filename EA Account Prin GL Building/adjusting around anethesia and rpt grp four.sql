
SELECT b.*, cost_center_code, HSP.COST_CNTR_ID, CCN.COST_CNTR_ID, CCN.RPT_GRP_FOUR, COALESCE(
            CCN.RPT_GRP_FOUR, 
            CASE
				WHEN LEN(COST_CENTER_CODE) = 7 THEN COST_CENTER_CODE
                WHEN HSP.TX_POST_DATE < '2019-07-01' THEN COA.NEW_CCN
                WHEN CHARINDEX(HSP.GL_CREDIT_NUM, '.') = 0 THEN SUBSTRING(HSP.GL_CREDIT_NUM, 14, 7)
                ELSE NULL

            END
        ) as 'jointoeaop',CCN.RPT_GRP_FOUR, HSP.TX_POST_DATE,  hsp.gl_credit_num,  COA.NEW_CCN , *

FROM SOURCE_UWHEALTH.EPIC_HSP_TRANSACTIONS_CUR HSP
INNER JOIN MART_LOAD_UWHEALTH.STRATA_GLOBAL_INCLUSIONS_HX INC ON HSP.HSP_ACCOUNT_ID = INC.ENCOUNTERRECORDNUMBER
LEFT JOIN SOURCE_UWHEALTH.EPIC_CL_COST_CNTR_CUR CCN ON HSP.COST_CNTR_ID = CCN.COST_CNTR_ID
LEFT JOIN SOURCE_UWHEALTH.EA_UWH_LEGACY_COA_MAP_CUR COA ON CCN.COST_CENTER_CODE = COA.COST_CENTER AND COA.ORG = 'UWHC'
LEFT JOIN SOURCE_UWHEALTH.EPIC_HSP_ACCOUNT_CUR HAR ON HSP.hsp_account_id = HAR.hsp_account_id
LEFT JOIN MART_UWHEALTH.EA_OP_CCN_TYPE B ON COALESCE(
            CCN.RPT_GRP_FOUR, 
            CASE
				WHEN LEN(COST_CENTER_CODE) = 7 THEN COST_CENTER_CODE
                WHEN HSP.TX_POST_DATE < '2019-07-01' THEN COA.NEW_CCN
                WHEN CHARINDEX(HSP.GL_CREDIT_NUM, '.') = 0 THEN SUBSTRING(HSP.GL_CREDIT_NUM, 14, 7)
                ELSE NULL

            END
        ) = B.GL_COST_CENTER_ID
    WHERE
        har.ACCT_BASECLS_HA_C <> '1'
        AND COALESCE(
            CASE
                WHEN har.acct_class_ha_c IN ('3', '4') THEN 'Y'
                ELSE 'N'
            END, 'N'
        ) = 'N'
        AND HSP.TX_TYPE_HA_C = '1'
      --  AND HSP.SERV_AREA_ID = '10000'
	  and ccn.RPT_GRP_FOUR in ('1004484', '1098147', '3035532', '9999999')

order by b.OP_ENC_HIERARCHY


/*

select RPT_GRP_FOUR,  case when cost_center_code like '3032%' then 'Like3032' else 'NotLike' end as 'testing', * From  SOURCE_UWHEALTH.EPIC_CL_COST_CNTR_CUR 
where   cost_center_code like '3032%'
and cost_center_code not IN ('3032186','3032045','3032112', '3032366' ) 

select * from MART_UWHEALTH.EA_OP_CCN_TYPE
where GL_COST_CENTER_ID = '3032021'

--select * From SOURCE_UWHEALTH.EPIC_CL_COST_CNTR_CUR
--WHERE CCN.RPT_GRP_FOUR IS NOT NULL;

select len(COST_CENTER_CODE), * From  SOURCE_UWHEALTH.EPIC_CL_COST_CNTR_CUR 
where rpt_grp_four = '3032420' or cost_center_code = '3032420'
order by 1

;

with rgf as (
select cost_cntr_id, cost_center_name, cost_center_code, rpt_grp_four
from SOURCE_UWHEALTH.EPIC_CL_COST_CNTR_CUR 
where rpt_grp_four is not null
),

ccc as (select cost_cntr_id, cost_center_name, cost_center_code, coalesce(rpt_grp_four, 'RptGrpFourIsNull') as rpt_grp_four
from SOURCE_UWHEALTH.EPIC_CL_COST_CNTR_CUR 
where rpt_grp_four is null-- and len(cost_center_code) = 7
)

select ccc.cost_cntr_id, ccc.cost_center_name, ccc.cost_center_code, ccc.rpt_grp_four, 'break', 
rgf.* from ccc
full outer join rgf on ccc.cost_center_code = rgf.rpt_grp_four



*/