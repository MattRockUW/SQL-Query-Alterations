/****** Object:  View [Mart_Load_UWHealth].[EA_ACCOUNT_OP_ENC_TYPE]    Script Date: 2/4/2025 9:51:12 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [Adhoc_UWHealth].[EA_ACCOUNT_OP_ENC_TYPE]
AS SELECT
/**********************************************************************************************************************
Title/Object: EA_ACCOUNT_OP_ENC_TYPE
Purpose: Assigns the primary outpatient encounter type to a hospital billing account based on cost center hierarchy.
		 Also calculates OR Case totals.

Business Rules Summary:

The outpatient encounter type assigned to the cost center with the lowest hierarchy value of all charge cost centers
on an outpatient account will be used as the outpatient encounter type for that account.

An account's OR case count is the sum of the charged quantity for OR Prep charges (identified by 'HBZ0244', 'HBZ0243')
dropped in operating room cost centers (identified by '3040280','3040290').

History:
DATE		Developer				Action
01/31/2024	Sean Meirose			Added history documentation and business rules.
									Converted to MS SQL.
**********************************************************************************************************************/

 
    CCN_RANK.hsp_account_id, 
    CASE 
        WHEN HSP.ACCT_BASECLS_HA_C = 1 THEN 'INPT' 
        ELSE CCN_RANK.op_enc_type 
    END AS op_enc_type, 
    CCN_RANK.op_enc_hierarchy, 
    ORPREP.or_cases
FROM (
	SELECT 
    a.HSP_ACCOUNT_ID,
    B.OP_ENC_TYPE,
    B.OP_ENC_HIERARCHY,
    RANK() OVER (PARTITION BY a.HSP_ACCOUNT_ID ORDER BY B.OP_ENC_HIERARCHY) AS Rank_OP_ENC
FROM 
    SOURCE_UWHEALTH.EPIC_HSP_TRANSACTIONS_CUR A
LEFT JOIN 
    SOURCE_UWHEALTH.EPIC_CL_COST_CNTR_CUR CCN ON A.COST_CNTR_ID = CCN.COST_CNTR_ID
INNER JOIN 
    MART_LOAD_UWHEALTH.STRATA_GLOBAL_INCLUSIONS_HX INC ON A.HSP_ACCOUNT_ID = INC.ENCOUNTERRECORDNUMBER
LEFT JOIN 
    SOURCE_UWHEALTH.EA_UWH_LEGACY_COA_MAP_CUR COA ON CCN.COST_CENTER_CODE = COA.COST_CENTER AND COA.ORG = 'UWHC'
INNER JOIN 
    adhoc_UWHEALTH.EA_OP_CCN_TYPE B ON COALESCE( 
        CCN.RPT_GRP_FOUR,
        CASE
            WHEN A.TX_POST_DATE < '07/01/2019' THEN COA.NEW_CCN
            ELSE 
                CASE CHARINDEX(a.GL_CREDIT_NUM, '.')
                    WHEN 0 THEN SUBSTRING(a.GL_CREDIT_NUM, 14, 7)
                    ELSE NULL
                END
        END
    ) = B.GL_COST_CENTER_ID 
WHERE 
    A.TX_TYPE_HA_C = '1'
    AND A.SERV_AREA_ID = '10000'
    AND A.ACCT_CLASS_HA_C <> '24'
GROUP BY 
    a.HSP_ACCOUNT_ID, B.OP_ENC_TYPE, B.OP_ENC_HIERARCHY
HAVING 
    SUM(A.QUANTITY) > 0
) CCN_RANK

left join (
	select hsp.hsp_account_id,
	sum(case when 
			(CASE when hsp.TX_POST_DATE < '07/01/2019' then COA.NEW_CCN
			else CASE CHARINDEX(HSP.GL_CREDIT_NUM,'.')
     		WHEN 0 THEN SUBSTRING(HSP.GL_CREDIT_NUM,14,7)
     		ELSE NULL END
			END	) in ('3040280','3040290') 
		and eap.PROC_CODE in('HBZ0244', 'HBZ0243') then hsp.quantity 
		else 0 end) as OR_CASES

	FROM SOURCE_UWHEALTH.EPIC_HSP_TRANSACTIONS_CUR hsp
	left join SOURCE_UWHEALTH.EPIC_HSP_ACCOUNT_CUR HAR on HSP.hsp_account_id = HAR.hsp_account_id
	left join SOURCE_UWHEALTH.EPIC_CL_COST_CNTR_CUR CCN ON hsp.COST_CNTR_ID = CCN.COST_CNTR_ID
	left join SOURCE_UWHEALTH.EA_UWH_LEGACY_COA_MAP_CUR COA on CCN.COST_CENTER_CODE = COA.COST_CENTER and COA.ORG = 'UWHC'
	left join SOURCE_UWHEALTH.EPIC_CLARITY_EAP_CUR EAP on hsp.proc_id = eap.proc_id
	where hsp.TX_ID is not null 
		and HSP.TX_TYPE_HA_C = '1'
		and HSP.SERV_AREA_ID = '10000'
		and HAR.ACCT_CLASS_HA_C <> '24'
		and HSP.TX_POST_DATE >= '07/01/2017'
	group by hsp.hsp_account_id
) ORPREP ON ORPREP.hsp_account_id = CCN_RANK.hsp_account_id
LEFT JOIN SOURCE_UWHEALTH.EPIC_HSP_ACCOUNT_CUR HSP ON HSP.hsp_account_id = CCN_RANK.hsp_account_id
WHERE 
    CCN_RANK.Rank_OP_ENC = 
        CASE 
            WHEN (ORPREP.or_cases = 0 OR ORPREP.or_cases IS NULL) 
                AND CCN_RANK.op_enc_type = 'AMBSRG' THEN 2
            ELSE 1 
        END;
GO


