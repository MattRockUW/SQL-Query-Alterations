/****** Object:  View [Mart_UWHealth].[ONCOLOGY_FINANCIAL]    Script Date: 2/4/2025 10:36:21 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [Adhoc_UWHealth].[ONCOLOGY_FINANCIAL]
AS WITH HBTABLE1 AS (
SELECT A.STRATA_ENCOUNTER_REC_NBR
, A.PATIENT_ID
, POP.CANCER_SITE_GRP_1
, POP.CANCER_SITE_GRP_2 
, A.INOUT_IND
, A.ENC_FISCAL_YEAR
, A.INS_PLAN_1_GL_PAYOR_GROUP_3
, A.PAT_GEO_MARKET_2000A
, A.PAT_GEO_REGION_2000
, A.PRIN_GL_BUILDING_ID
, BLDG.PRIN_GL_BUILDING_NAME
, BLDG.PRIN_GL_BUILDING_ADDRESS
, BLDG.BUILDING_CATEGORY
, A.MEDICAL_HOME_FLG
, A.OP_ENC_TYPE
, A.OR_CASES
, A.QUARTZ_RISK_FLG
, A.ACO_FLG
, A.LOS_NET_DAYS
, CASE WHEN A.OR_CASES > 0 THEN 'Y' ELSE 'N' END AS ORFLAG
, CASE WHEN A.OBS_OSS_FLG IS NULL THEN 'NA' ELSE A.OBS_OSS_FLG END AS OBS_OSS_FLG
, CASE WHEN A.TECH_ATTR_PROV_ACAD_DEPT_ROLLUP = ' ' THEN 'Unknown' WHEN A.TECH_ATTR_PROV_ACAD_DEPT_ROLLUP IS NULL THEN 'Unknown' ELSE A.TECH_ATTR_PROV_ACAD_DEPT_ROLLUP END AS TECH_ATTR_PROV_ACAD_DEPT_ROLLUP
, CASE WHEN A.TECH_ATTR_PROV_ACAD_SECT_ROLLUP = ' ' THEN 'Unknown' WHEN A.TECH_ATTR_PROV_ACAD_SECT_ROLLUP IS NULL THEN 'Unknown' ELSE A.TECH_ATTR_PROV_ACAD_SECT_ROLLUP END AS TECH_ATTR_PROV_ACAD_SECT_ROLLUP
, isnull(A.CHARGE_AMOUNT,0) as CHARGE_AMOUNT
, isnull(A.ESTIMATED_REIMBURSEMENT,0) as ESTIMATED_REIMBURSEMENT
, isnull(A.VAR_DIRECT_COST,0) as VAR_DIRECT_COST
, isnull(A.FIXED_DIRECT_COST,0) as FIXED_DIRECT_COST
, isnull(A.VAR_INDIRECT_COST,0) as VAR_INDIRECT_COST
, isnull(A.FIXED_INDIRECT_COST,0) as FIXED_INDIRECT_COST
, isnull(SUM(C.CHARGE_AMOUNT),0) AS PBCHGS
, isnull(SUM(C.ESTIMATED_REIMBURSEMENT),0) AS PBNETREV
, isnull(SUM(C.VAR_DIRECT_COST),0) AS PBVDCOST
, isnull(SUM(C.FIXED_DIRECT_COST),0) AS PBFDCOST
, isnull(SUM(C.VAR_INDIRECT_COST),0) AS PBVICOST
, isnull(SUM(C.FIXED_INDIRECT_COST),0) AS PBFICOST
FROM [Mart_UWHealth].[STRATA_COST_ACCOUNT_HB] A
JOIN [Mart_UWHealth].[POPULATION_ONCOLOGY_HB] POP ON A.STRATA_ENCOUNTER_REC_NBR = POP.HOSPITAL_ACCOUNT_ID
LEFT JOIN [Mart_UWHealth].[STRATA_COST_ACCOUNT_PB] B ON A.STRATA_ENCOUNTER_REC_NBR = B.MATCHED_HB_STRATA_ENCOUNTER /* hb/pb match */
LEFT JOIN [Mart_UWHealth].[STRATA_COST_CHARGE_ACTIVITY_PB] C ON B.STRATA_ENCOUNTER_REC_NBR = C.STRATA_ENCOUNTER_REC_NBR
LEFT JOIN [Source_UWHealth].[UDD_EA_GL_BLDG_CAT_MAP] BLDG
on A.PRIN_GL_BUILDING_ID = BLDG.PRIN_GL_BUILDING_ID
WHERE A.ENC_FISCAL_YEAR > 2020 AND A.CHARGE_AMOUNT > 0 
AND A.DISCHARGE_DT <= 
(
select [COSTED_THRU_DT]
from [Mart_UWHealth].[EA_EPPFM_COSTED_THRU_DT]
)


GROUP BY A.STRATA_ENCOUNTER_REC_NBR
, A.INOUT_IND
, A.CHARGE_AMOUNT
, A.ESTIMATED_REIMBURSEMENT
, A.VAR_DIRECT_COST
, A.FIXED_DIRECT_COST
, A.VAR_INDIRECT_COST
, A.FIXED_INDIRECT_COST
, A.INS_PLAN_1_GL_PAYOR_GROUP_3
, POP.CANCER_SITE_GRP_1
, POP.CANCER_SITE_GRP_2 
, A.PAT_GEO_MARKET_2000A
, A.PAT_GEO_REGION_2000 
, A.ENC_FISCAL_YEAR
, A.MEDICAL_HOME_FLG
, A.OP_ENC_TYPE
, A.OR_CASES
, A.LOS_NET_DAYS
, CASE WHEN A.OR_CASES > 0 THEN 'Y' ELSE 'N' END 
, CASE WHEN A.OBS_OSS_FLG IS NULL THEN 'NA' ELSE A.OBS_OSS_FLG END 
, CASE WHEN A.TECH_ATTR_PROV_ACAD_DEPT_ROLLUP = ' ' THEN 'Unknown' WHEN A.TECH_ATTR_PROV_ACAD_DEPT_ROLLUP IS NULL THEN 'Unknown' ELSE A.TECH_ATTR_PROV_ACAD_DEPT_ROLLUP END 
, CASE WHEN A.TECH_ATTR_PROV_ACAD_SECT_ROLLUP = ' ' THEN 'Unknown' WHEN A.TECH_ATTR_PROV_ACAD_SECT_ROLLUP IS NULL THEN 'Unknown' ELSE A.TECH_ATTR_PROV_ACAD_SECT_ROLLUP END
, A.PATIENT_ID
, A.INS_PLAN_1_GL_PAYOR_GROUP_1
, A.INS_PLAN_1_GL_PAYOR_GROUP_2
, A.QUARTZ_RISK_FLG
, A.ACO_FLG
, A.PRIN_GL_BUILDING_ID
, BLDG.PRIN_GL_BUILDING_NAME
, BLDG.PRIN_GL_BUILDING_ADDRESS
, BLDG.BUILDING_CATEGORY
)

 , PBTABLE1 AS (
SELECT 
  concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY) AS VISIT_ID
, A.PATIENT_ID
, inout.INOUT_IND
, A.SERVICE_DT_FISCAL_YEAR
, SITEGRP.CANCER_SITE_GRP_1
, SITEGRP.CANCER_SITE_GRP_2
, INS.INS_PLAN_1_GL_PAYOR_GROUP_3
, geo.PAT_GEO_MARKET_2000A
, geo.PAT_GEO_REGION_2000
, TECH.TECH_ATTR_PROV_ACAD_DEPT_ROLLUP
, TECH.TECH_ATTR_PROV_ACAD_SECT_ROLLUP
, QRISK.QUARTZ_RISK_FLG
, ACO.ACO_FLG
, CASE WHEN C.OBS_OSS_FLG IS NULL THEN 'NA' ELSE C.OBS_OSS_FLG END AS OBS_OSS_FLG
, LOC.PLACE_OF_SERVICE_ID
, LOC.GL_BUILDING_ID
, LOC.GL_BUILDING_NAME
, LOC.GL_BUILDING_ADDRESS
, LOC.BUILDING_CATEGORY
, MEDHOME.MEDICAL_HOME_FLG
, COST.PBCHGS2
, COST.PBNETREV2
, COST.PBVDCOST2
, COST.PBFDCOST2
, COST.PBVICOST2
, COST.PBFICOST2
FROM [Mart_UWHealth].[STRATA_COST_CHARGE_ACTIVITY_PB] A
JOIN [Modeled_UWHealth].[DIM_DATE] DT ON A.SERVICE_DT = DT.ACTUAL_DT
JOIN [Mart_UWHealth].[STRATA_COST_ACCOUNT_PB] C ON A.STRATA_ENCOUNTER_REC_NBR = C.STRATA_ENCOUNTER_REC_NBR 
JOIN [Mart_UWHealth].[POPULATION_ONCOLOGY_PROFB] POP ON A.PB_TX_ID = POP.TX_ID
LEFT JOIN [Source_UWHealth].[UDD_EA_PB_POS_BLDG_MAP] BLDG
ON A.PLACE_OF_SERVICE_ID = BLDG.POS_ID
left JOIN
	(SELECT 
	  concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY) AS VISIT_ID
	, CANCER_SITE_GRP_1
	, CANCER_SITE_GRP_2
	, RANK() OVER (partition by concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY) ORDER BY isnull(SUM(A.CHARGE_AMOUNT),0) DESC, case when CANCER_SITE_GRP_1 like 'Miscellaneous%' then 2 else 1 end, case when CANCER_SITE_GRP_1 like 'Other%' then 2 else 1 end, case when CANCER_SITE_GRP_2 like 'Other%' then 2 else 1 end, isnull(SUM(A.CHARGE_AMOUNT),0) + isnull(SUM(A.VAR_DIRECT_COST),0) + isnull(SUM(A.FIXED_DIRECT_COST),0) + isnull(SUM(A.VAR_INDIRECT_COST),0) + isnull(SUM(A.FIXED_INDIRECT_COST),0) DESC, max(CANCER_SITE_GRP_1), max(CANCER_SITE_GRP_2)) AS RNK
	FROM [Mart_UWHealth].[STRATA_COST_CHARGE_ACTIVITY_PB] A
	JOIN [Modeled_UWHealth].[DIM_DATE] DT ON A.SERVICE_DT = DT.ACTUAL_DT
	JOIN [Mart_UWHealth].[STRATA_COST_ACCOUNT_PB] C ON A.STRATA_ENCOUNTER_REC_NBR = C.STRATA_ENCOUNTER_REC_NBR 
	JOIN [Mart_UWHealth].[POPULATION_ONCOLOGY_PROFB] POP ON A.PB_TX_ID = POP.TX_ID
	WHERE 
	A.SERVICE_DT >= '7/1/2020' and (C.MATCHED_HB_STRATA_ENCOUNTER IS NULL OR C.MATCHED_HB_STRATA_ENCOUNTER = '')AND ENC_FISCAL_YEAR > '2020'
	and A.SERVICE_DT <= 
	(
	select [COSTED_THRU_DT]
	from [Mart_UWHealth].[EA_EPPFM_COSTED_THRU_DT]
	)
	GROUP BY  concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY)
	, CANCER_SITE_GRP_1
	, CANCER_SITE_GRP_2
	)SITEGRP ON concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY) = SITEGRP.VISIT_ID AND SITEGRP.RNK = 1
left JOIN
	(SELECT 
	  concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY) AS VISIT_ID
	, A.TECH_ATTR_PROV_ACAD_DEPT_ROLLUP
	, A.TECH_ATTR_PROV_ACAD_SECT_ROLLUP
	, RANK() OVER (partition by concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY) ORDER BY isnull(SUM(A.CHARGE_AMOUNT),0) DESC, isnull(SUM(A.CHARGE_AMOUNT),0) + isnull(SUM(A.VAR_DIRECT_COST),0) + isnull(SUM(A.FIXED_DIRECT_COST),0) + isnull(SUM(A.VAR_INDIRECT_COST),0) + isnull(SUM(A.FIXED_INDIRECT_COST),0) DESC, max(A.TECH_ATTR_PROV_ACAD_DEPT_ROLLUP),max(TECH_ATTR_PROV_ACAD_sect_ROLLUP)) AS RNK
	FROM [Mart_UWHealth].[STRATA_COST_CHARGE_ACTIVITY_PB] A
	JOIN [Modeled_UWHealth].[DIM_DATE] DT ON A.SERVICE_DT = DT.ACTUAL_DT
	JOIN [Mart_UWHealth].[STRATA_COST_ACCOUNT_PB] C ON A.STRATA_ENCOUNTER_REC_NBR = C.STRATA_ENCOUNTER_REC_NBR
	JOIN [Mart_UWHealth].[POPULATION_ONCOLOGY_PROFB] pop  on A.PB_TX_ID = pop.TX_ID
	WHERE 
	A.SERVICE_DT >= '7/1/2020' and (C.MATCHED_HB_STRATA_ENCOUNTER IS NULL OR C.MATCHED_HB_STRATA_ENCOUNTER = '')AND ENC_FISCAL_YEAR > '2020'
	and A.SERVICE_DT <= 
	(
	select [COSTED_THRU_DT]
	from [Mart_UWHealth].[EA_EPPFM_COSTED_THRU_DT]
	)
	GROUP BY  concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY)
	, A.TECH_ATTR_PROV_ACAD_DEPT_ROLLUP
	, A.TECH_ATTR_PROV_ACAD_SECT_ROLLUP
	)TECH ON concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY) = TECH.VISIT_ID AND TECH.RNK = 1
left JOIN
	(SELECT 
	  concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY) AS VISIT_ID
	, A.PLACE_OF_SERVICE_ID
	, BLDG.GL_BUILDING_ID
	, BLDG.GL_BUILDING_NAME
	, BLDG.GL_BUILDING_ADDRESS
	, BLDG.BUILDING_CATEGORY
	, RANK() OVER (partition by concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY) ORDER BY isnull(SUM(A.CHARGE_AMOUNT),0) DESC,isnull(SUM(A.CHARGE_AMOUNT),0) + isnull(SUM(A.VAR_DIRECT_COST),0) + isnull(SUM(A.FIXED_DIRECT_COST),0) + isnull(SUM(A.VAR_INDIRECT_COST),0) + isnull(SUM(A.FIXED_INDIRECT_COST),0) DESC, max(BLDG.GL_BUILDING_ID)) AS RNK
	FROM [Mart_UWHealth].[STRATA_COST_CHARGE_ACTIVITY_PB] A
	JOIN [Modeled_UWHealth].[DIM_DATE] DT ON A.SERVICE_DT = DT.ACTUAL_DT
	JOIN [Mart_UWHealth].[STRATA_COST_ACCOUNT_PB] C ON A.STRATA_ENCOUNTER_REC_NBR = C.STRATA_ENCOUNTER_REC_NBR 
	LEFT JOIN [Source_UWHealth].[UDD_EA_PB_POS_BLDG_MAP] BLDG	ON A.PLACE_OF_SERVICE_ID = BLDG.POS_ID
	JOIN [Mart_UWHealth].[POPULATION_ONCOLOGY_PROFB] pop  on A.PB_TX_ID = pop.TX_ID
	WHERE 
	A.SERVICE_DT >= '7/1/2020' and (C.MATCHED_HB_STRATA_ENCOUNTER IS NULL OR C.MATCHED_HB_STRATA_ENCOUNTER = '')AND ENC_FISCAL_YEAR > '2020'
	and A.SERVICE_DT <= 
	(
	select [COSTED_THRU_DT]
	from [Mart_UWHealth].[EA_EPPFM_COSTED_THRU_DT]
	)
	GROUP BY  concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY)
	, A.PLACE_OF_SERVICE_ID
	, BLDG.GL_BUILDING_ID
	, BLDG.GL_BUILDING_NAME
	, BLDG.GL_BUILDING_ADDRESS
	, BLDG.BUILDING_CATEGORY
	) LOC ON concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY) = LOC.VISIT_ID AND LOC.RNK = 1
LEFT JOIN
	(SELECT 
	  concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY) AS VISIT_ID
	, isnull(SUM(A.CHARGE_AMOUNT),0) AS PBCHGS2
	, isnull(SUM(A.ESTIMATED_REIMBURSEMENT),0) AS PBNETREV2
	, isnull(SUM(A.VAR_DIRECT_COST),0) AS PBVDCOST2
	, isnull(SUM(A.FIXED_DIRECT_COST),0) AS PBFDCOST2
	, isnull(SUM(A.VAR_INDIRECT_COST),0) AS PBVICOST2
	, isnull(SUM(A.FIXED_INDIRECT_COST),0) AS PBFICOST2
	FROM [Mart_UWHealth].[STRATA_COST_CHARGE_ACTIVITY_PB] A
	JOIN [Modeled_UWHealth].[DIM_DATE] DT ON A.SERVICE_DT = DT.ACTUAL_DT
	JOIN [Mart_UWHealth].[STRATA_COST_ACCOUNT_PB] C ON A.STRATA_ENCOUNTER_REC_NBR = C.STRATA_ENCOUNTER_REC_NBR 
	JOIN [Mart_UWHealth].[POPULATION_ONCOLOGY_PROFB] pop  on A.PB_TX_ID = pop.TX_ID
	WHERE 
	A.SERVICE_DT >= '7/1/2020' and (C.MATCHED_HB_STRATA_ENCOUNTER IS NULL OR C.MATCHED_HB_STRATA_ENCOUNTER = '')AND ENC_FISCAL_YEAR > '2020'
	and A.SERVICE_DT <= 
	(
	select [COSTED_THRU_DT]
	from [Mart_UWHealth].[EA_EPPFM_COSTED_THRU_DT]
	)
	GROUP BY  concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY)
	)COST ON concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY) = COST.VISIT_ID 
LEFT JOIN
	(SELECT 
	  concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY) AS VISIT_ID
	, c.INS_PLAN_1_GL_PAYOR_GROUP_3
	, RANK() OVER (partition by concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY) ORDER BY isnull(SUM(A.CHARGE_AMOUNT),0) DESC, isnull(SUM(A.CHARGE_AMOUNT),0) + isnull(SUM(A.VAR_DIRECT_COST),0) + isnull(SUM(A.FIXED_DIRECT_COST),0) + isnull(SUM(A.VAR_INDIRECT_COST),0) + isnull(SUM(A.FIXED_INDIRECT_COST),0) DESC) AS RNK
	FROM [Mart_UWHealth].[STRATA_COST_CHARGE_ACTIVITY_PB] A
	JOIN [Modeled_UWHealth].[DIM_DATE] DT ON A.SERVICE_DT = DT.ACTUAL_DT
	JOIN [Mart_UWHealth].[STRATA_COST_ACCOUNT_PB] C ON A.STRATA_ENCOUNTER_REC_NBR = C.STRATA_ENCOUNTER_REC_NBR
	JOIN [Mart_UWHealth].[POPULATION_ONCOLOGY_PROFB] pop  on A.PB_TX_ID = pop.TX_ID
	WHERE 
	A.SERVICE_DT >= '7/1/2020' and (C.MATCHED_HB_STRATA_ENCOUNTER IS NULL OR C.MATCHED_HB_STRATA_ENCOUNTER = '')AND ENC_FISCAL_YEAR > '2020'
	and A.SERVICE_DT <= 
	(
	select [COSTED_THRU_DT]
	from [Mart_UWHealth].[EA_EPPFM_COSTED_THRU_DT]
	)
	GROUP BY  concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY)
	, c.INS_PLAN_1_GL_PAYOR_GROUP_3
	)INS ON concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY) = INS.VISIT_ID AND INS.RNK = 1
LEFT JOIN
	(SELECT 
	  concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY) AS VISIT_ID
	, C.QUARTZ_RISK_FLG
	, RANK() OVER (partition by concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY) ORDER BY isnull(SUM(A.CHARGE_AMOUNT),0) DESC, isnull(SUM(A.CHARGE_AMOUNT),0) + isnull(SUM(A.VAR_DIRECT_COST),0) + isnull(SUM(A.FIXED_DIRECT_COST),0) + isnull(SUM(A.VAR_INDIRECT_COST),0) + isnull(SUM(A.FIXED_INDIRECT_COST),0) DESC) AS RNK
	FROM [Mart_UWHealth].[STRATA_COST_CHARGE_ACTIVITY_PB] A
	JOIN [Modeled_UWHealth].[DIM_DATE] DT ON A.SERVICE_DT = DT.ACTUAL_DT
	JOIN [Mart_UWHealth].[STRATA_COST_ACCOUNT_PB] C ON A.STRATA_ENCOUNTER_REC_NBR = C.STRATA_ENCOUNTER_REC_NBR
	JOIN [Mart_UWHealth].[POPULATION_ONCOLOGY_PROFB] pop  on A.PB_TX_ID = pop.TX_ID
	WHERE 
	A.SERVICE_DT >= '7/1/2020' and (C.MATCHED_HB_STRATA_ENCOUNTER IS NULL OR C.MATCHED_HB_STRATA_ENCOUNTER = '')AND ENC_FISCAL_YEAR > '2020'
	and A.SERVICE_DT <= 
	(
	select [COSTED_THRU_DT]
	from [Mart_UWHealth].[EA_EPPFM_COSTED_THRU_DT]
	)
	GROUP BY  concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY)
	, C.QUARTZ_RISK_FLG
	)QRISK ON concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY) = QRISK.VISIT_ID AND QRISK.RNK = 1
LEFT JOIN
	(SELECT 
	  concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY) AS VISIT_ID
	, C.MEDICAL_HOME_FLG
	, RANK() OVER (partition by concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY) ORDER BY isnull(SUM(A.CHARGE_AMOUNT),0) DESC, isnull(SUM(A.CHARGE_AMOUNT),0) + isnull(SUM(A.VAR_DIRECT_COST),0) + isnull(SUM(A.FIXED_DIRECT_COST),0) + isnull(SUM(A.VAR_INDIRECT_COST),0) + isnull(SUM(A.FIXED_INDIRECT_COST),0) DESC) AS RNK
	FROM [Mart_UWHealth].[STRATA_COST_CHARGE_ACTIVITY_PB] A
	JOIN [Modeled_UWHealth].[DIM_DATE] DT ON A.SERVICE_DT = DT.ACTUAL_DT
	JOIN [Mart_UWHealth].[STRATA_COST_ACCOUNT_PB] C ON A.STRATA_ENCOUNTER_REC_NBR = C.STRATA_ENCOUNTER_REC_NBR
	JOIN [Mart_UWHealth].[POPULATION_ONCOLOGY_PROFB] pop  on A.PB_TX_ID = pop.TX_ID
	WHERE 
	A.SERVICE_DT >= '7/1/2020' and (C.MATCHED_HB_STRATA_ENCOUNTER IS NULL OR C.MATCHED_HB_STRATA_ENCOUNTER = '')AND ENC_FISCAL_YEAR > '2020'
	and A.SERVICE_DT <= 
	(
	select [COSTED_THRU_DT]
	from [Mart_UWHealth].[EA_EPPFM_COSTED_THRU_DT]
	)
	GROUP BY  concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY)
	, C.MEDICAL_HOME_FLG
	)MEDHOME ON concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY) = MEDHOME.VISIT_ID AND MEDHOME.RNK = 1
LEFT JOIN
	(SELECT 
	  concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY) AS VISIT_ID
	, C.INOUT_IND
	, RANK() OVER (partition by concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY) ORDER BY isnull(SUM(A.CHARGE_AMOUNT),0) DESC, isnull(SUM(A.CHARGE_AMOUNT),0) + isnull(SUM(A.VAR_DIRECT_COST),0) + isnull(SUM(A.FIXED_DIRECT_COST),0) + isnull(SUM(A.VAR_INDIRECT_COST),0) + isnull(SUM(A.FIXED_INDIRECT_COST),0) DESC) AS RNK
	FROM [Mart_UWHealth].[STRATA_COST_CHARGE_ACTIVITY_PB] A
	JOIN [Modeled_UWHealth].[DIM_DATE] DT ON A.SERVICE_DT = DT.ACTUAL_DT
	JOIN [Mart_UWHealth].[STRATA_COST_ACCOUNT_PB] C ON A.STRATA_ENCOUNTER_REC_NBR = C.STRATA_ENCOUNTER_REC_NBR
	JOIN [Mart_UWHealth].[POPULATION_ONCOLOGY_PROFB] pop  on A.PB_TX_ID = pop.TX_ID
	WHERE 
	A.SERVICE_DT >= '7/1/2020' and (C.MATCHED_HB_STRATA_ENCOUNTER IS NULL OR C.MATCHED_HB_STRATA_ENCOUNTER = '')AND ENC_FISCAL_YEAR > '2020'
	and A.SERVICE_DT <= 
	(
	select [COSTED_THRU_DT]
	from [Mart_UWHealth].[EA_EPPFM_COSTED_THRU_DT]
	)
	GROUP BY  concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY)
	, C.INOUT_IND
	)inout ON concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY) = inout.VISIT_ID AND inout.RNK = 1
LEFT JOIN
	(SELECT 
	  concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY) AS VISIT_ID
	, PAT_GEO_MARKET_2000A
	, PAT_GEO_REGION_2000
	, RANK() OVER (partition by concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY) ORDER BY case when PAT_GEO_MARKET_2000A is null then 2 else 1 end, case when PAT_GEO_REGION_2000 is null then 2 else 1 end,isnull(SUM(A.CHARGE_AMOUNT),0) DESC) AS RNK
	FROM [Mart_UWHealth].[STRATA_COST_CHARGE_ACTIVITY_PB] A
	JOIN [Modeled_UWHealth].[DIM_DATE] DT ON A.SERVICE_DT = DT.ACTUAL_DT
	JOIN [Mart_UWHealth].[STRATA_COST_ACCOUNT_PB] C ON A.STRATA_ENCOUNTER_REC_NBR = C.STRATA_ENCOUNTER_REC_NBR
	JOIN [Mart_UWHealth].[POPULATION_ONCOLOGY_PROFB] pop  on A.PB_TX_ID = pop.TX_ID
	WHERE 
	A.SERVICE_DT >= '7/1/2020' and (C.MATCHED_HB_STRATA_ENCOUNTER IS NULL OR C.MATCHED_HB_STRATA_ENCOUNTER = '')AND ENC_FISCAL_YEAR > '2020'
	and A.SERVICE_DT <= 
	(
	select [COSTED_THRU_DT]
	from [Mart_UWHealth].[EA_EPPFM_COSTED_THRU_DT]
	)
	GROUP BY  concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY)
	, PAT_GEO_MARKET_2000A
	, PAT_GEO_REGION_2000
	)geo ON concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY) = geo.VISIT_ID AND geo.RNK = 1
LEFT JOIN
	(SELECT 
	  concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY) AS VISIT_ID
	, ACO_FLG
	, RANK() OVER (partition by concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY) ORDER BY isnull(SUM(A.CHARGE_AMOUNT),0) DESC) AS RNK
	FROM [Mart_UWHealth].[STRATA_COST_CHARGE_ACTIVITY_PB] A
	JOIN [Modeled_UWHealth].[DIM_DATE] DT ON A.SERVICE_DT = DT.ACTUAL_DT
	JOIN [Mart_UWHealth].[STRATA_COST_ACCOUNT_PB] C ON A.STRATA_ENCOUNTER_REC_NBR = C.STRATA_ENCOUNTER_REC_NBR
	JOIN [Mart_UWHealth].[POPULATION_ONCOLOGY_PROFB] pop  on A.PB_TX_ID = pop.TX_ID
	WHERE 
	A.SERVICE_DT >= '7/1/2020' and (C.MATCHED_HB_STRATA_ENCOUNTER IS NULL OR C.MATCHED_HB_STRATA_ENCOUNTER = '')AND ENC_FISCAL_YEAR > '2020'
	and A.SERVICE_DT <= 
	(
	select [COSTED_THRU_DT]
	from [Mart_UWHealth].[EA_EPPFM_COSTED_THRU_DT]
	)
	GROUP BY  concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY)
	, ACO_FLG
	)ACO ON concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY) = aco.VISIT_ID AND aco.RNK = 1
WHERE 
A.SERVICE_DT >= '7/1/2020' and (C.MATCHED_HB_STRATA_ENCOUNTER IS NULL OR C.MATCHED_HB_STRATA_ENCOUNTER = '')AND ENC_FISCAL_YEAR > '2020'
and A.SERVICE_DT <= 
(
select [COSTED_THRU_DT]
from [Mart_UWHealth].[EA_EPPFM_COSTED_THRU_DT]
)
and (A.CHARGE_AMOUNT != 0 or A.TOTAL_COST != 0 or A.TOTAL_COST IS NOT NULL or A.TOTAL_COST not like '')
GROUP BY inout.INOUT_IND
, concat(A.PATIENT_ID,DT.YEAR_MONTH_DAY)
, A.SERVICE_DT_FISCAL_YEAR
, SITEGRP.CANCER_SITE_GRP_1
, SITEGRP.CANCER_SITE_GRP_2
, INS.INS_PLAN_1_GL_PAYOR_GROUP_3
, geo.PAT_GEO_MARKET_2000A
, geo.PAT_GEO_REGION_2000
, MEDHOME.MEDICAL_HOME_FLG
, CASE WHEN C.OBS_OSS_FLG IS NULL THEN 'NA' ELSE C.OBS_OSS_FLG END
, A.PATIENT_ID
, TECH.TECH_ATTR_PROV_ACAD_DEPT_ROLLUP
, TECH.TECH_ATTR_PROV_ACAD_SECT_ROLLUP
, QRISK.QUARTZ_RISK_FLG
, aco.ACO_FLG
, LOC.PLACE_OF_SERVICE_ID
, LOC.GL_BUILDING_ID
, LOC.GL_BUILDING_NAME
, LOC.GL_BUILDING_ADDRESS
, LOC.BUILDING_CATEGORY
, COST.PBCHGS2
, COST.PBNETREV2
, COST.PBVDCOST2
, COST.PBFDCOST2
, COST.PBVICOST2
, COST.PBFICOST2
)

, SAGETABLE1 AS (
SELECT 
A.STRATA_ENCOUNTER_REC_NBR
, A.PATIENT_ID
, A.SRC_SYSTM
, SITEGRP.CANCER_SITE_GRP_1
, SITEGRP.CANCER_SITE_GRP_2 
, A.INOUT_IND
, A.ENC_FISCAL_YEAR
, A.INS_PLAN_1_GL_PAYOR_GROUP_3
, A.PAT_GEO_MARKET_2000A
, A.PAT_GEO_REGION_2000
, A.PRIN_GL_BUILDING_ID
, BLDG.PRIN_GL_BUILDING_NAME
, BLDG.PRIN_GL_BUILDING_ADDRESS
, BLDG.BUILDING_CATEGORY
, A.MEDICAL_HOME_FLG
, A.OP_ENC_TYPE
, A.OR_CASES
, A.QUARTZ_RISK_FLG
, A.ACO_FLG
, A.LOS_NET_DAYS
, CASE WHEN A.OR_CASES > 0 THEN 'Y' ELSE 'N' END AS ORFLAG
, CASE WHEN A.OBS_OSS_FLG IS NULL THEN 'NA' ELSE A.OBS_OSS_FLG END AS OBS_OSS_FLG
, CASE WHEN A.TECH_ATTR_PROV_ACAD_DEPT_ROLLUP = ' ' THEN 'Unknown' WHEN A.TECH_ATTR_PROV_ACAD_DEPT_ROLLUP IS NULL THEN 'Unknown' ELSE A.TECH_ATTR_PROV_ACAD_DEPT_ROLLUP END AS TECH_ATTR_PROV_ACAD_DEPT_ROLLUP
, CASE WHEN A.TECH_ATTR_PROV_ACAD_SECT_ROLLUP = ' ' THEN 'Unknown' WHEN A.TECH_ATTR_PROV_ACAD_SECT_ROLLUP IS NULL THEN 'Unknown' ELSE A.TECH_ATTR_PROV_ACAD_SECT_ROLLUP END AS TECH_ATTR_PROV_ACAD_SECT_ROLLUP
, isnull(A.CHARGE_AMOUNT,0) as CHARGE_AMOUNT
, isnull(A.ESTIMATED_REIMBURSEMENT,0) as ESTIMATED_REIMBURSEMENT
, isnull(A.VAR_DIRECT_COST,0) as VAR_DIRECT_COST
, isnull(A.FIXED_DIRECT_COST,0) as FIXED_DIRECT_COST
, isnull(A.VAR_INDIRECT_COST,0) as VAR_INDIRECT_COST
, isnull(A.FIXED_INDIRECT_COST,0) as FIXED_INDIRECT_COST
FROM [Mart_UWHealth].[STRATA_COST_ACCOUNT_HB] A
JOIN [Mart_UWHealth].[POPULATION_ONCOLOGY_ENC] POP ON A.PAT_ENC_CSN_ID = POP.CSN_ID
LEFT JOIN [Source_UWHealth].[UDD_EA_GL_BLDG_CAT_MAP] BLDG
on A.PRIN_GL_BUILDING_ID = BLDG.PRIN_GL_BUILDING_ID
left JOIN
	(SELECT 
	  A.STRATA_ENCOUNTER_REC_NBR
	, CANCER_SITE_GRP_1
	, CANCER_SITE_GRP_2
	, RANK() OVER (partition by A.STRATA_ENCOUNTER_REC_NBR ORDER BY isnull(SUM(A.CHARGE_AMOUNT),0) DESC, case when CANCER_SITE_GRP_1 like 'Miscellaneous%' then 2 else 1 end, case when CANCER_SITE_GRP_1 like 'Other%' then 2 else 1 end, case when CANCER_SITE_GRP_2 like 'Other%' then 2 else 1 end, isnull(SUM(A.CHARGE_AMOUNT),0) + isnull(SUM(A.VAR_DIRECT_COST),0) + isnull(SUM(A.FIXED_DIRECT_COST),0) + isnull(SUM(A.VAR_INDIRECT_COST),0) + isnull(SUM(A.FIXED_INDIRECT_COST),0) DESC, max(CANCER_SITE_GRP_1), max(CANCER_SITE_GRP_2)) AS RNK
	FROM [Mart_UWHealth].[STRATA_COST_ACCOUNT_HB] A
	JOIN [Mart_UWHealth].[POPULATION_ONCOLOGY_ENC] POP ON A.PAT_ENC_CSN_ID = POP.CSN_ID
	WHERE A.SRC_SYSTM = 'SAGE'
	AND A.ENC_FISCAL_YEAR > 2020 --AND A.CHARGE_AMOUNT > 0 
	AND A.DISCHARGE_DT <= 
	(
	select [COSTED_THRU_DT]
	from [Mart_UWHealth].[EA_EPPFM_COSTED_THRU_DT]
	)
	GROUP BY  STRATA_ENCOUNTER_REC_NBR
	, CANCER_SITE_GRP_1
	, CANCER_SITE_GRP_2
	)SITEGRP ON A.STRATA_ENCOUNTER_REC_NBR = SITEGRP.STRATA_ENCOUNTER_REC_NBR AND SITEGRP.RNK = 1
WHERE A.SRC_SYSTM = 'SAGE'
AND A.ENC_FISCAL_YEAR > 2020 --AND A.CHARGE_AMOUNT > 0 
AND A.DISCHARGE_DT <= 
(
select [COSTED_THRU_DT]
from [Mart_UWHealth].[EA_EPPFM_COSTED_THRU_DT]
)

GROUP BY A.STRATA_ENCOUNTER_REC_NBR
, A.INOUT_IND
, A.CHARGE_AMOUNT
, A.ESTIMATED_REIMBURSEMENT
, A.VAR_DIRECT_COST
, A.FIXED_DIRECT_COST
, A.VAR_INDIRECT_COST
, A.FIXED_INDIRECT_COST
, A.INS_PLAN_1_GL_PAYOR_GROUP_3
, SITEGRP.CANCER_SITE_GRP_1
, SITEGRP.CANCER_SITE_GRP_2 
, A.PAT_GEO_MARKET_2000A
, A.PAT_GEO_REGION_2000 
, A.ENC_FISCAL_YEAR
, A.MEDICAL_HOME_FLG
, A.OP_ENC_TYPE
, A.OR_CASES
, A.LOS_NET_DAYS
, CASE WHEN A.OR_CASES > 0 THEN 'Y' ELSE 'N' END 
, CASE WHEN A.OBS_OSS_FLG IS NULL THEN 'NA' ELSE A.OBS_OSS_FLG END 
, CASE WHEN A.TECH_ATTR_PROV_ACAD_DEPT_ROLLUP = ' ' THEN 'Unknown' WHEN A.TECH_ATTR_PROV_ACAD_DEPT_ROLLUP IS NULL THEN 'Unknown' ELSE A.TECH_ATTR_PROV_ACAD_DEPT_ROLLUP END 
, CASE WHEN A.TECH_ATTR_PROV_ACAD_SECT_ROLLUP = ' ' THEN 'Unknown' WHEN A.TECH_ATTR_PROV_ACAD_SECT_ROLLUP IS NULL THEN 'Unknown' ELSE A.TECH_ATTR_PROV_ACAD_SECT_ROLLUP END
, A.PATIENT_ID
, A.INS_PLAN_1_GL_PAYOR_GROUP_1
, A.INS_PLAN_1_GL_PAYOR_GROUP_2
, A.QUARTZ_RISK_FLG
, A.ACO_FLG
, A.PRIN_GL_BUILDING_ID
, BLDG.PRIN_GL_BUILDING_NAME
, BLDG.PRIN_GL_BUILDING_ADDRESS
, BLDG.BUILDING_CATEGORY
, A.SRC_SYSTM
)

SELECT
  VISIT_ID
, NULL AS STRATA_ENCOUNTER_REC_NBR
, NULL AS SAGE_ENCOUNTER_REC_NUMBER
, PATIENT_ID
, CANCER_SITE_GRP_1
, CANCER_SITE_GRP_2 
, INOUT_IND
, 'PB Only'		AS OP_ENC_TYPE
, case when INOUT_IND = 'IP' then 'PB Only IP' 
  when INOUT_IND = 'OP' then 'PB Only OP'
  else null end				as  OP_ENC_TYPE_DESC
, 'PB Only'	AS ORFLAG
, OBS_OSS_FLG
, QUARTZ_RISK_FLG
, ACO_FLG
, case when TECH_ATTR_PROV_ACAD_DEPT_ROLLUP is null then 'Unknown'
else TECH_ATTR_PROV_ACAD_DEPT_ROLLUP end as TECH_ATTR_PROV_ACAD_DEPT_ROLLUP
, case when TECH_ATTR_PROV_ACAD_SECT_ROLLUP is null then 'Unknown'
else TECH_ATTR_PROV_ACAD_SECT_ROLLUP end as TECH_ATTR_PROV_ACAD_SECT_ROLLUP
, NULL		AS OR_CASES
, NULL		AS LOS_NET_DAYS
, SERVICE_DT_FISCAL_YEAR as ENC_FISCAL_YEAR
, INS_PLAN_1_GL_PAYOR_GROUP_3
, case when PAT_GEO_MARKET_2000A is null then 'Unknown'
else PAT_GEO_MARKET_2000A end as PAT_GEO_MARKET_2000A
, case when PAT_GEO_REGION_2000 is null then 'Unknown'
else PAT_GEO_REGION_2000 end as PAT_GEO_REGION_2000
, GL_BUILDING_ID
, GL_BUILDING_NAME
, GL_BUILDING_ADDRESS
, BUILDING_CATEGORY
, MEDICAL_HOME_FLG
, PBCHGS2 AS CHGS
, PBNETREV2 AS NETREV
, PBVDCOST2 AS VDCOST
, PBFDCOST2 AS FDCOST
, PBVICOST2 AS VICOST
, PBFICOST2 AS FICOST
, 'PB Only' AS HBPB_IND
FROM PBTABLE1 A


UNION ALL


SELECT
 NULL AS VISIT_ID
, STRATA_ENCOUNTER_REC_NBR
, NULL   AS SAGE_ENCOUNTER_REC_NUMBER
, PATIENT_ID
, CANCER_SITE_GRP_1
, CANCER_SITE_GRP_2 
, INOUT_IND
, Case
	When A.OP_ENC_TYPE is not null then A.OP_ENC_TYPE
	When INOUT_IND = 'IP' then 'INPT'
	When INOUT_IND = 'OP' and (OBS_OSS_FLG = 'OBS' or OBS_OSS_FLG = 'OSS') then 'OBSOTHER'
	else 'OTHER' END	as OP_ENC_TYPE
, Case
	When B.OP_ENC_TYPE_DESC is not null then B.OP_ENC_TYPE_DESC
	When INOUT_IND = 'IP' then 'Inpatient'
	When INOUT_IND = 'OP' and (OBS_OSS_FLG = 'OBS' or OBS_OSS_FLG = 'OSS') then 'Other Temp Patient'
	else 'Other Outpatient Encounter' END	as OP_ENC_TYPE_DESC
, ORFLAG
, OBS_OSS_FLG
, QUARTZ_RISK_FLG
, ACO_FLG
, TECH_ATTR_PROV_ACAD_DEPT_ROLLUP
, TECH_ATTR_PROV_ACAD_SECT_ROLLUP
, OR_CASES
, LOS_NET_DAYS
, ENC_FISCAL_YEAR
, INS_PLAN_1_GL_PAYOR_GROUP_3
, case when PAT_GEO_MARKET_2000A is null then 'Unknown'
else PAT_GEO_MARKET_2000A end as PAT_GEO_MARKET_2000A
, case when PAT_GEO_REGION_2000 is null then 'Unknown'
else PAT_GEO_REGION_2000 end as PAT_GEO_REGION_2000
, case when PRIN_GL_BUILDING_ID is null then 'Unknown'
else PRIN_GL_BUILDING_ID end	AS GL_BUILDING_ID
, case when PRIN_GL_BUILDING_NAME is null then 'Unknown'
else PRIN_GL_BUILDING_NAME end	AS GL_BUILDING_NAME
, case when PRIN_GL_BUILDING_ADDRESS is null then 'Unknown'
else PRIN_GL_BUILDING_ADDRESS end	AS GL_BUILDING_ADDRESS
, case when BUILDING_CATEGORY is null then 'Unknown'
else BUILDING_CATEGORY end	AS BUILDING_CATEGORY
, MEDICAL_HOME_FLG
, CHARGE_AMOUNT + PBCHGS AS CHGS
, ESTIMATED_REIMBURSEMENT + PBNETREV AS NETREV
, VAR_DIRECT_COST + PBVDCOST AS VDCOST
, FIXED_DIRECT_COST + PBFDCOST AS FDCOST
, VAR_INDIRECT_COST + PBVICOST AS VICOST
, FIXED_INDIRECT_COST + PBFICOST AS FICOST
, 'HBPB' AS HBPB_IND
FROM HBTABLE1 A
LEFT JOIN 
	(SELECT DISTINCT 
	OP_ENC_TYPE, OP_ENC_TYPE_DESC, OP_ENC_HIERARCHY 
	FROM [Adhoc_UWHealth].[EA_OP_CCN_TYPE]
	) B 
	ON A.OP_ENC_TYPE = B.OP_ENC_TYPE


UNION ALL


SELECT
 NULL AS VISIT_ID
, NULL AS STRATA_ENCOUNTER_REC_NBR
, STRATA_ENCOUNTER_REC_NBR   AS SAGE_ENCOUNTER_REC_NUMBER
, PATIENT_ID
, CANCER_SITE_GRP_1
, CANCER_SITE_GRP_2 
, INOUT_IND
, Case
	When A.OP_ENC_TYPE is not null then A.OP_ENC_TYPE
	When INOUT_IND = 'IP' then 'INPT'
	When INOUT_IND = 'OP' and (OBS_OSS_FLG = 'OBS' or OBS_OSS_FLG = 'OSS') then 'OBSOTHER'
	else 'OTHER' END	as OP_ENC_TYPE
, Case
	when A.OP_ENC_TYPE = 'SAGE' then 'Non-billable Enctr (Phone, MyChart)'
	When B.OP_ENC_TYPE_DESC is not null then B.OP_ENC_TYPE_DESC
	When INOUT_IND = 'IP' then 'Inpatient'
	When INOUT_IND = 'OP' and (OBS_OSS_FLG = 'OBS' or OBS_OSS_FLG = 'OSS') then 'Other Temp Patient'
	else 'Other Outpatient Encounter' END	as OP_ENC_TYPE_DESC
, ORFLAG
, OBS_OSS_FLG
, QUARTZ_RISK_FLG
, ACO_FLG
, TECH_ATTR_PROV_ACAD_DEPT_ROLLUP
, TECH_ATTR_PROV_ACAD_SECT_ROLLUP
, OR_CASES
, LOS_NET_DAYS
, ENC_FISCAL_YEAR
, INS_PLAN_1_GL_PAYOR_GROUP_3
, case when PAT_GEO_MARKET_2000A is null then 'Unknown'
else PAT_GEO_MARKET_2000A end as PAT_GEO_MARKET_2000A
, case when PAT_GEO_REGION_2000 is null then 'Unknown'
else PAT_GEO_REGION_2000 end as PAT_GEO_REGION_2000
, case when PRIN_GL_BUILDING_ID is null then 'Unknown'
else PRIN_GL_BUILDING_ID end	AS GL_BUILDING_ID
, case when PRIN_GL_BUILDING_NAME is null then 'Unknown'
else PRIN_GL_BUILDING_NAME end	AS GL_BUILDING_NAME
, case when PRIN_GL_BUILDING_ADDRESS is null then 'Unknown'
else PRIN_GL_BUILDING_ADDRESS end	AS GL_BUILDING_ADDRESS
, case when BUILDING_CATEGORY is null then 'Unknown'
else BUILDING_CATEGORY end	AS BUILDING_CATEGORY
, MEDICAL_HOME_FLG
, CHARGE_AMOUNT AS CHGS
, ESTIMATED_REIMBURSEMENT AS NETREV
, VAR_DIRECT_COST AS VDCOST
, FIXED_DIRECT_COST AS FDCOST
, VAR_INDIRECT_COST AS VICOST
, FIXED_INDIRECT_COST AS FICOST
, 'HB SAGE' AS HBPB_IND
FROM SAGETABLE1 A
LEFT JOIN 
	(SELECT DISTINCT 
	OP_ENC_TYPE, OP_ENC_TYPE_DESC, OP_ENC_HIERARCHY 
	FROM [Adhoc_UWHealth].[EA_OP_CCN_TYPE]
	) B 
	ON A.OP_ENC_TYPE = B.OP_ENC_TYPE;
GO


