/****** Object:  View [Mart_Load_UWHealth].[EA_ACCOUNT_PRIN_GL_BUILDING]    Script Date: 12/16/2024 2:11:01 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--CREATE VIEW [Mart_Load_UWHealth].[EA_ACCOUNT_PRIN_GL_BUILDING] AS 
SELECT
/**********************************************************************************************************************
Title/Object: EA_ACCOUNT_PRIN_GL_BUILDING_LOAD
Purpose: Contain the complex logic for principal GL building ID assignments separately from the Strata HB Encounter
extract to support ease of maintenance and efficient extracts.
Business Rules Summary:
An account's principal building is:

Outpatient: The building ID from charges in the highest priority cost center per the BPAD outpatient encounter hierarchy (EA_ACCOUNT_OP_ENC_TYPE)
			If multiple building IDs are in the highest priority cost center, use the building ID with the most charges.
			If still returning multiple building IDs, use most recent charge and then highest building ID.

Inpatient:	Use the building ID with the most charges on the account.
			If multiple building IDs have an identical sum of charges, use most recent charge and then highest building ID.

OBS-OSS:	Use the building ID from the OBS-OSS hourly charge on the account.
			If no OBS-OSS hourly charge is present, use the building ID with the most charges.
			If multiple building IDs have an identical sum of charges, use most recent charge and then highest building ID.

History:
This extract query was ported from the Strata Sample extract and updated for UWHealth.

DATE		Developer				Action
10/25/2022	Sean Meirose			Added history documentation and business rules.
									Updated OBS-OSS logic to prioritize OBS-OSS hourly charges but consider others if they are not present.
01/31/2024	Sean Meirose			Updated join in outpatient logic to bring in OP Encounter Hiearchy value for the charge instead of the account.
									Converted to MS SQL.
10/24/2024	Swati Gupta				Removed Service Area filters to include NI
**********************************************************************************************************************/


HSP_ACCOUNT_ID,
PRIN_GL_BUILDING_ID AS Prin_GL_Building_ID
FROM
(
SELECT
HSP.HSP_ACCOUNT_ID,
CASE 
	WHEN har.ACCT_BASECLS_HA_C = '1' THEN 'I' ELSE 'O'
	END 
AS INOUT_IND,
CASE 
	WHEN har.acct_class_ha_c IN ('3', '4') THEN 'Y' ELSE 'N'
	END 
AS OBSOSS_FLG,
COALESCE(
	CASE 
		WHEN HSP.TX_POST_DATE < '2019-07-01' THEN COA.BUILDING_ID
		WHEN CHARINDEX(HSP.GL_CREDIT_NUM, '.') = 0 THEN SUBSTRING(HSP.GL_CREDIT_NUM, 4, 4)
		ELSE NULL
		END
	, 'Missing ID'
) AS PRIN_GL_BUILDING_ID,
b.OP_ENC_HIERARCHY,
SUM(HSP.tx_amount) AS sum_charges,
COUNT(*) OVER (PARTITION BY HSP.HSP_ACCOUNT_ID) AS Building_count,
NULL AS OBSOSS_COUNT, 
RANK() OVER (
PARTITION BY HSP.HSP_ACCOUNT_ID
ORDER BY B.OP_ENC_HIERARCHY, SUM(HSP.tx_amount) DESC, MAX(HSP.SERVICE_DATE) DESC, COALESCE(
CASE 
	WHEN HSP.TX_POST_DATE < '2019-07-01' THEN COA.BUILDING_ID
	WHEN CHARINDEX(HSP.GL_CREDIT_NUM, '.') = 0 THEN SUBSTRING(HSP.GL_CREDIT_NUM, 4, 4)
	ELSE NULL
	END
, 'Missing ID'
) DESC
) AS GL_BUILDING_RANK
FROM SOURCE_UWHEALTH.EPIC_HSP_TRANSACTIONS_CUR HSP
INNER JOIN MART_LOAD_UWHEALTH.STRATA_GLOBAL_INCLUSIONS_HX INC ON HSP.HSP_ACCOUNT_ID = INC.ENCOUNTERRECORDNUMBER
LEFT JOIN SOURCE_UWHEALTH.EPIC_CL_COST_CNTR_CUR CCN ON HSP.COST_CNTR_ID = CCN.COST_CNTR_ID
LEFT JOIN SOURCE_UWHEALTH.EA_UWH_LEGACY_COA_MAP_CUR COA ON CCN.COST_CENTER_CODE = COA.COST_CENTER AND COA.ORG = 'UWHC'
LEFT JOIN SOURCE_UWHEALTH.EPIC_HSP_ACCOUNT_CUR HAR ON HSP.hsp_account_id = HAR.hsp_account_id
LEFT JOIN MART_UWHEALTH.EA_OP_CCN_TYPE B ON COALESCE(
            CCN.RPT_GRP_FOUR,
            CASE
                WHEN HSP.TX_POST_DATE < '2019-07-01' THEN COA.NEW_CCN
                ELSE
                    CASE
                        WHEN CHARINDEX(HSP.GL_CREDIT_NUM, '.') = 0 THEN SUBSTRING(HSP.GL_CREDIT_NUM, 14, 7)
                        ELSE NULL
                    END
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
    GROUP BY
        HSP.HSP_ACCOUNT_ID, har.ACCT_BASECLS_HA_C, har.acct_class_ha_c, COA.BUILDING_ID, HSP.GL_CREDIT_NUM, b.OP_ENC_HIERARCHY, HSP.TX_POST_DATE

UNION ALL

    SELECT
        HSP.HSP_ACCOUNT_ID,
        CASE
            WHEN har.ACCT_BASECLS_HA_C = '1' THEN 'I'
            ELSE 'O'
        END AS INOUT_IND,
        CASE
            WHEN har.acct_class_ha_c IN ('3', '4') THEN 'Y'
            ELSE 'N'
        END AS OBSOSS_FLG,
        COALESCE(
            CASE
                WHEN HSP.TX_POST_DATE < '2019-07-01' THEN COA.BUILDING_ID
                ELSE
                    CASE
                        WHEN CHARINDEX(HSP.GL_CREDIT_NUM, '.') = 0 THEN SUBSTRING(HSP.GL_CREDIT_NUM, 4, 4)
                        ELSE NULL
                    END
            END,
            'Missing ID'
        ) AS PRIN_GL_BUILDING_ID,
        NULL AS OP_ENC_HIERARCHY,
        SUM(HSP.tx_amount) AS sum_charges,
        COUNT(*) OVER (PARTITION BY HSP.HSP_ACCOUNT_ID) AS Building_count,
        NULL AS OBSOSS_COUNT,
        RANK() OVER (
            PARTITION BY HSP.HSP_ACCOUNT_ID
            ORDER BY SUM(HSP.tx_amount) DESC, MAX(HSP.service_date) DESC, COALESCE(
            CASE
                WHEN HSP.TX_POST_DATE < '2019-07-01' THEN COA.BUILDING_ID
                ELSE
                    CASE
                        WHEN CHARINDEX(HSP.GL_CREDIT_NUM, '.') = 0 THEN SUBSTRING(HSP.GL_CREDIT_NUM, 4, 4)
                        ELSE NULL
                    END
            END,
            'Missing ID'
        ) DESC
        ) AS GL_BUILDING_RANK
    FROM
        SOURCE_UWHEALTH.EPIC_HSP_TRANSACTIONS_CUR HSP
	INNER JOIN 
		MART_LOAD_UWHEALTH.STRATA_GLOBAL_INCLUSIONS_HX INC ON HSP.HSP_ACCOUNT_ID = INC.ENCOUNTERRECORDNUMBER
    LEFT JOIN
        SOURCE_UWHEALTH.EPIC_HSP_ACCOUNT_CUR HAR ON HSP.hsp_account_id = HAR.hsp_account_id
    LEFT JOIN
        SOURCE_UWHEALTH.EPIC_CL_COST_CNTR_CUR CCN ON HSP.COST_CNTR_ID = CCN.COST_CNTR_ID
    LEFT JOIN
        SOURCE_UWHEALTH.EA_UWH_LEGACY_COA_MAP_CUR COA ON CCN.COST_CENTER_CODE = COA.COST_CENTER AND COA.ORG = 'UWHC'
    WHERE
        har.ACCT_BASECLS_HA_C = 1
        AND SUBSTRING(HSP.GL_CREDIT_NUM, 8, 6) = 400200
        AND COALESCE(
            CASE
                WHEN HSP.TX_POST_DATE < '2019-07-01' THEN COA.BUILDING_ID
                ELSE
                    CASE
                        WHEN CHARINDEX(HSP.GL_CREDIT_NUM, '.') = 0 THEN SUBSTRING(HSP.GL_CREDIT_NUM, 4, 4)
                        ELSE NULL
                    END
            END,
            'Missing ID'
        ) IN ('1060', '1065', '1081', '1080')
        AND HSP.TX_TYPE_HA_C = '1'
        AND HSP.SERV_AREA_ID = '10000'
    GROUP BY
        HSP.HSP_ACCOUNT_ID, har.ACCT_BASECLS_HA_C, har.acct_class_ha_c, COA.BUILDING_ID, HSP.GL_CREDIT_NUM, HSP.TX_POST_DATE
	UNION ALL
	 SELECT 
        HSP.HSP_ACCOUNT_ID, -- gl_credit_num, map.[MEDITECH_GL_STRING],SUBSTRING(HSP.GL_CREDIT_NUM, 9, 2),
        CASE
            WHEN har.ACCT_BASECLS_HA_C = '1' THEN 'I'
            ELSE 'O'
        END AS INOUT_IND,
        CASE
            WHEN har.acct_class_ha_c IN ('3', '4') THEN 'Y'
            ELSE 'N'
        END AS OBSOSS_FLG,
map.[GL_BUILDING_ID] AS PRIN_GL_BUILDING_ID,
        NULL AS OP_ENC_HIERARCHY,
        SUM(HSP.tx_amount) AS sum_charges,
        COUNT(*) OVER (PARTITION BY HSP.HSP_ACCOUNT_ID) AS Building_count,
        NULL AS OBSOSS_COUNT,
        RANK() OVER (
            PARTITION BY HSP.HSP_ACCOUNT_ID
            ORDER BY SUM(HSP.tx_amount) DESC, MAX(HSP.service_date) DESC, COALESCE(
            CASE
                WHEN HSP.TX_POST_DATE < '2021-07-01' THEN 'Missing ID'
                ELSE
                    map.[GL_BUILDING_ID]
            END,
            'Missing ID'
        ) DESC
        ) AS GL_BUILDING_RANK
    FROM
        SOURCE_UWHEALTH.EPIC_HSP_TRANSACTIONS_CUR HSP
		left join [Source_UWHealth].[UDD_EA_EPPFM_OCS_NIL_GL_STRING_MAP] map
		on hsp.gl_credit_num = map.[MEDITECH_GL_STRING]
	INNER JOIN 
		MART_LOAD_UWHEALTH.STRATA_GLOBAL_INCLUSIONS_HX INC ON HSP.HSP_ACCOUNT_ID = INC.ENCOUNTERRECORDNUMBER
    LEFT JOIN
        SOURCE_UWHEALTH.EPIC_HSP_ACCOUNT_CUR HAR ON HSP.hsp_account_id = HAR.hsp_account_id
    LEFT JOIN
        SOURCE_UWHEALTH.EPIC_CL_COST_CNTR_CUR CCN ON HSP.COST_CNTR_ID = CCN.COST_CNTR_ID
    LEFT JOIN
        SOURCE_UWHEALTH.EA_UWH_LEGACY_COA_MAP_CUR COA ON CCN.COST_CENTER_CODE = COA.COST_CENTER AND COA.ORG = 'UWHC'
   WHERE
    har.ACCT_BASECLS_HA_C = 1
  
		And  SUBSTRING(HSP.GL_CREDIT_NUM, 9, 2)= '10' and SUBSTRING(HSP.GL_CREDIT_NUM, 13, 1)= '1'
        AND 
		HSP.TX_TYPE_HA_C = '1'
        AND HSP.SERV_AREA_ID = '110000000'

   GROUP BY
        HSP.HSP_ACCOUNT_ID, har.ACCT_BASECLS_HA_C, har.acct_class_ha_c, map.[GL_BUILDING_ID],COA.BUILDING_ID, HSP.GL_CREDIT_NUM, HSP.TX_POST_DATE
		UNION ALL

    SELECT
        HSP.HSP_ACCOUNT_ID,
        CASE
            WHEN har.ACCT_BASECLS_HA_C = '1' THEN 'I'
            ELSE 'O'
        END AS INOUT_IND,
        CASE
            WHEN har.acct_class_ha_c IN ('3', '4') THEN 'Y'
            ELSE 'N'
        END AS OBSOSS_FLG,
        COALESCE(
            CASE
                WHEN HSP.TX_POST_DATE < '2019-07-01' THEN COA.BUILDING_ID
                ELSE
                    CASE
                        WHEN CHARINDEX(HSP.GL_CREDIT_NUM, '.') = 0 THEN SUBSTRING(HSP.GL_CREDIT_NUM, 4, 4)
                        ELSE NULL
                    END
            END,
            'Missing ID'
        ) AS PRIN_GL_BUILDING_ID,
        NULL AS OP_ENC_HIERARCHY,
        SUM(HSP.tx_amount) AS sum_charges,
        COUNT(*) OVER (PARTITION BY HSP.HSP_ACCOUNT_ID) AS Building_count,
        SUM(CASE WHEN EAP.PROC_CODE IN ('HBX0018', 'HBX0019', 'HBX0020', 'HBX0021') THEN 1 ELSE 0 END) AS OBSOSS_COUNT,
        RANK() OVER (
            PARTITION BY HSP.HSP_ACCOUNT_ID
            ORDER BY SUM(CASE WHEN EAP.PROC_CODE IN ('HBX0018', 'HBX0019', 'HBX0020', 'HBX0021') THEN 1 ELSE 0 END) DESC, SUM(HSP.tx_amount) DESC, MAX(HSP.service_date) DESC, COALESCE(
            CASE
                WHEN HSP.TX_POST_DATE < '2019-07-01' THEN COA.BUILDING_ID
                ELSE
                    CASE
                        WHEN CHARINDEX(HSP.GL_CREDIT_NUM, '.') = 0 THEN SUBSTRING(HSP.GL_CREDIT_NUM, 4, 4)
                        ELSE NULL
                    END
            END,
            'Missing ID'
        ) DESC
        ) AS GL_BUILDING_RANK
    FROM
        SOURCE_UWHEALTH.EPIC_HSP_TRANSACTIONS_CUR HSP
	INNER JOIN 
		MART_LOAD_UWHEALTH.STRATA_GLOBAL_INCLUSIONS_HX INC ON hsp.HSP_ACCOUNT_ID = INC.ENCOUNTERRECORDNUMBER
    LEFT JOIN
        SOURCE_UWHEALTH.EPIC_HSP_ACCOUNT_CUR HAR ON HSP.hsp_account_id = HAR.hsp_account_id
    LEFT JOIN
        SOURCE_UWHEALTH.EPIC_CL_COST_CNTR_CUR CCN ON HSP.COST_CNTR_ID = CCN.COST_CNTR_ID
    LEFT JOIN
        SOURCE_UWHEALTH.EA_UWH_LEGACY_COA_MAP_CUR COA ON CCN.COST_CENTER_CODE = COA.COST_CENTER AND COA.ORG = 'UWHC'
    LEFT JOIN
        SOURCE_UWHEALTH.EPIC_CLARITY_EAP_CUR EAP ON HSP.proc_id = EAP.proc_id
    WHERE
        HAR.ACCT_BASECLS_HA_C <> '1'
        AND HAR.acct_class_ha_c IN ('3', '4')
        AND COALESCE(
            CASE
                WHEN HSP.TX_POST_DATE < '2019-07-01' THEN COA.BUILDING_ID
                ELSE
                    CASE
                        WHEN CHARINDEX(HSP.GL_CREDIT_NUM, '.') = 0 THEN SUBSTRING(HSP.GL_CREDIT_NUM, 4, 4)
                        ELSE NULL
                    END
            END,
            'Missing ID'
        ) IN ('1060', '1065', '1081', '1080')
        AND HSP.TX_TYPE_HA_C = '1'
      --  AND HSP.SERV_AREA_ID = '10000'
    GROUP BY
        HSP.HSP_ACCOUNT_ID, har.ACCT_BASECLS_HA_C, har.acct_class_ha_c, COA.BUILDING_ID, HSP.GL_CREDIT_NUM, HSP.TX_POST_DATE
) AS foo
WHERE GL_BUILDING_RANK = 1
GROUP BY
    HSP_ACCOUNT_ID, PRIN_GL_BUILDING_ID;
GO


