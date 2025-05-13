/****** Object:  View [Mart_Load_UWHealth].[STRATA_BRIDGE_RANKED_PROCS_PROVS]    Script Date: 2/7/2025 4:38:13 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [Adhoc_UWHealth].[STRATA_BRIDGE_RANKED_PROCS_PROVS]
AS select
HSP.HSP_ACCOUNT_ID

 --added 9/8/21 SM
,case
	WHEN OPENC.OP_ENC_TYPE IN ('GENRAD','ADVRAD','LABS','OTHDIA','CHEMOI','RTX','CRDRHB','HOMEH','RX','REGSVC') and HSP.ACCT_BASECLS_HA_C <> 1 and Substring(oproc.AUTHRZING_PROV_ID,1,1) in ('1','3') THEN oproc.AUTHRZING_PROV_ID

	--principal surgeon for inpatient accounts, exclude NI/Agrace via PROC_SER SAM 10/25/2022
	when HSP.ACCT_BASECLS_HA_C = 1 and DRG.MEDSURG_CD = 'SURG' and Substring(HSP_ACCT_PX_LIST.PROC_PERF_PROV_ID,1,1) in ('1','3') and PROC_SER.prov_id is null then HSP_ACCT_PX_LIST.PROC_PERF_PROV_ID 
	
	--principal surgeon for inpatient accounts SAM 10/25/2022
	when HSP.ACCT_BASECLS_HA_C = 1 and DRG.MEDSURG_CD = 'SURG' and OPENC.OR_CASES <> 0 and Substring(COALESCE(CODED_CPT.CPT_PERF_PROV_ID, perf_prov.PERFORMING_PROV_ID),1,1) in ('1','3') then COALESCE(CODED_CPT.CPT_PERF_PROV_ID, perf_prov.PERFORMING_PROV_ID)
	
	--attending provider if the inpatient account is not surgical, exclude NI/AGRACE via ATTEND_SER SAM 10/25/2022
	when HSP.ACCT_BASECLS_HA_C = 1 and DRG.MEDSURG_CD <> 'SURG' and Substring(HSP.ATTENDING_PROV_ID,1,1) in ('1','3') and ATTEND_SER.prov_id is null then HSP.ATTENDING_PROV_ID 
	
	
	--use CPT performing provider as principal surgeon for outpatient accounts with surgical charges UPDATED 5/25/22 and 8/23/2022 to reference new subquery for CPT performing provider
	when HSP.ACCT_BASECLS_HA_C <> 1 and OPENC.OR_CASES <> 0 and OPENC.OR_CASES is not null and HSP.DISCH_DATE_TIME >='10/1/2015' and Substring(COALESCE(CODED_CPT.CPT_PERF_PROV_ID, perf_prov.PERFORMING_PROV_ID),1,1) in ('1','3') then COALESCE(CODED_CPT.CPT_PERF_PROV_ID, perf_prov.PERFORMING_PROV_ID)
	
	
	--use procedure performing provider as principal surgeon for OP accounts with surgical charges discharged prior to 10/1/2015, exclude NI/Agrace via PROC_SER SAM 10/25/2022
	when HSP.ACCT_BASECLS_HA_C <> 1 and OPENC.OR_CASES <> 0 and OPENC.OR_CASES is not null and HSP.DISCH_DATE_TIME <'10/1/2015' 
	and Substring(HSP_ACCT_PX_LIST.PROC_PERF_PROV_ID,1,1) in ('1','3') and PROC_SER.prov_id is null then HSP_ACCT_PX_LIST.PROC_PERF_PROV_ID 
	
	
	else case when Substring(HSP.ATTENDING_PROV_ID,1,1) in ('1','3') and ATTEND_SER.prov_id is null then HSP.ATTENDING_PROV_ID else null end --exclude NI/AGRACE via ATTEND_SER SAM 10/25/2022
	end 																						AS UDF_TECHCHG_BUS_SEG_ATTR_PROV_ID																					

,coalesce(CODED_CPT.CPT_PERF_PROV_ID,perf_prov.PERFORMING_PROV_ID)								AS UDF_CPT_PRIM_PERF_PHYSICIAN --added 1/14/2022 SM


,case when substring(COALESCE(CODED_CPT.cpt_code,CPT_RANK.cpt_code),1,2) = 'HB' THEN HCPCS_RANK.HCPCS_CODE
else coalesce(CODED_CPT.cpt_code,CPT_RANK.cpt_code,hcpcs_rank.hcpcs_code)	end					AS UDF_PRIMARY_CPT_CODE --added 1/14/2022, updated 5/25/2022 SM


,case
	when HSP.ACCT_BASECLS_HA_C = 1 and HSP_ACCT_PX_LIST.PROC_PERF_PROV_ID is null and OPENC.OR_CASES <> 0 and OPENC.OR_CASES is not null then COALESCE(CODED_CPT.CPT_PERF_PROV_ID,perf_prov.PERFORMING_PROV_ID) --added CPT as backup for IP surgeries 10/26/2022 SM
	when HSP.ACCT_BASECLS_HA_C = 1 then HSP_ACCT_PX_LIST.PROC_PERF_PROV_ID --principal surgeon for inpatient accounts, removed DRG requirement 10/25/2022 SM
	when OPENC.OR_CASES <> 0 and OPENC.OR_CASES is not null and HSP.DISCH_DATE_TIME >='10/1/2015' then COALESCE(CODED_CPT.CPT_PERF_PROV_ID,perf_prov.PERFORMING_PROV_ID) --assign CPT perf prov for outpatient as well SAM 10/25/2022
	else null
	end																							AS UDF_PRINCIPAL_SURGEON --added 1/14/2022 SM

,HCPCS_RANK.HCPCS_CODE																			AS UDF_PRIMARY_HCPCS_CODE --added 1/14/2022 SM, updated 5/25/2022 SM

,case 
	when HSP.ACCT_BASECLS_HA_C = 1 then CASE WHEN CL_ICD_PX.REF_BILL_CODE_SET_C = 2 THEN CL_ICD_PX.REF_BILL_CODE END
	when substring(COALESCE(CODED_CPT.cpt_code,CPT_RANK.cpt_code),1,2) = 'HB' and HCPCS_RANK.HCPCS_CODE is not null THEN HCPCS_RANK.HCPCS_CODE
	when substring(COALESCE(CODED_CPT.cpt_code,CPT_RANK.cpt_code),1,2) <> 'HB' then COALESCE(CODED_CPT.cpt_code,CPT_RANK.cpt_code)
	else null end																					AS UDF_PRIN_PROCEDURE		
	
,case
	when HSP.ACCT_BASECLS_HA_C = 1 and CL_ICD_PX.REF_BILL_CODE_SET_C = 2 then 'ICD10'
	when substring(COALESCE(CODED_CPT.cpt_code,CPT_RANK.cpt_code),1,2) = 'HB' and HCPCS_RANK.HCPCS_CODE is not null then 'HCPCS'
	when substring(COALESCE(CODED_CPT.cpt_code,CPT_RANK.cpt_code),1,2) <> 'HB' and CPT_RANK.cpt_code is not null then 'CPT(R)'
	else null end																					AS UDF_PRIN_PROCEDURE_TYPE

,[Public_UWHealth].[GetCurrentLocalDatetime]() as TABLE_RELOAD_DATETIME


FROM	  MART_LOAD_UWHEALTH.STRATA_ELEMENTS_HSP_ACCOUNT_T HSP  
LEFT JOIN MART_LOAD_UWHEALTH.STRATA_BRIDGE_HBDRG_T DRG 								ON HSP.HSP_ACCOUNT_ID = DRG.HOSPITAL_ACCOUNT_ID
LEFT JOIN SOURCE_UWHEALTH.EPIC_HSP_ACCT_DX_LIST_CUR HSP_ACCT_DX_LIST		    ON HSP.HSP_ACCOUNT_ID = HSP_ACCT_DX_LIST.HSP_ACCOUNT_ID AND (HSP_ACCT_DX_LIST.LINE IS NULL OR HSP_ACCT_DX_LIST.LINE = 1) --limit to primary coded diagnosis
LEFT JOIN SOURCE_UWHEALTH.EPIC_HSP_ACCT_PX_LIST_CUR HSP_ACCT_PX_LIST		    ON HSP.HSP_ACCOUNT_ID = HSP_ACCT_PX_LIST.HSP_ACCOUNT_ID AND (HSP_ACCT_PX_LIST.LINE IS NULL OR HSP_ACCT_PX_LIST.LINE = 1) --limit to primary coded procedure
--following two joins are used to filter Northern Illinois and Agrace from attribution logic SAM 10/25/2022
LEFT JOIN SOURCE_UWHEALTH.EPIC_CLARITY_SER_CUR PROC_SER							ON HSP_ACCT_PX_LIST.PROC_PERF_PROV_ID = PROC_SER.prov_id and (PROC_SER.RPT_GRP_SIX = '77' or PROC_SER.PRACTICE_NAME_C = '2307')
LEFT JOIN SOURCE_UWHEALTH.EPIC_CLARITY_SER_CUR ATTEND_SER						ON HSP.ATTENDING_PROV_ID = ATTEND_SER.PROV_ID and (ATTEND_SER.RPT_GRP_SIX = '77' or ATTEND_SER.PRACTICE_NAME_C = '2307')
LEFT JOIN adhoc_UWHEALTH.EA_ACCOUNT_OP_ENC_TYPE OPENC 				        ON HSP.HSP_ACCOUNT_ID = OPENC.HSP_ACCOUNT_ID --OP enc type and OR case count SM 8/3/2022
LEFT JOIN SOURCE_UWHEALTH.EPIC_CL_ICD_PX_CUR CL_ICD_PX						    ON HSP_ACCT_PX_LIST.FINAL_ICD_PX_ID = CL_ICD_PX.ICD_PX_ID

--additional logic to bring in CPT and performing provider for coded procedures. Prioritizes procedural CPT codes with APC values assigned.
--If multiple procedures with identical APC payment amounts are found, use the one with the lowest line value

LEFT JOIN    --CODED_CPTs

 (  SELECT cpt.hsp_account_id, cpt.CPT_PERF_PROV_ID, cpt.CPT_CODE,
        RANK() OVER (PARTITION BY cpt.HSP_ACCOUNT_ID ORDER BY ISNULL(cpt.PX_APC_FAC_RMB_AMT, 0) DESC, cpt.line) AS rank
    FROM
        source_uwhealth.EPIC_HSP_ACCT_CPT_CODES_CUR AS cpt
		left join SOURCE_UWHEALTH.epic_clarity_ser_CUR ser on cpt.cpt_perf_prov_id = ser.prov_id --exclude Northern Illinois and Agrace SAM 10/25/2022
	WHERE
        (cpt.CPT_CODE < '70000' OR (cpt.CPT_CODE >= '90000' AND cpt.PX_APC_FAC_RMB_AMT IS NOT NULL))
		and ser.RPT_GRP_SIX <> '77' and ser.PRACTICE_NAME_C <> '2307' --exclude Northern Illinois and Agrace SAM 10/25/2022

) AS CODED_CPT																	ON  CODED_CPT.hsp_account_id = hsp.HSP_ACCOUNT_ID  AND CODED_CPT.rank = 1


--CPT performing provider; new approach added 5/25/2022
LEFT JOIN 
(SELECT foo.hsp_account_id, foo.performing_prov_id, RANK() OVER (PARTITION BY foo.hsp_account_id ORDER BY foo.charges DESC, foo.performing_prov_id) AS rank
    FROM
    (   SELECT a.hsp_account_id, a.PERFORMING_PROV_ID, SUM(a.tx_amount) AS charges
        FROM  [Mart_Load_UWHealth].[STRATA_ELEMENTS_HSP_TRANSACTIONS_T] a
               LEFT JOIN SOURCE_UWHEALTH.EPIC_CLARITY_SER_CUR AS SER ON A.PERFORMING_PROV_ID = SER.PROV_ID
        WHERE
            A.TX_TYPE_HA_C = '1'
            AND a.performing_prov_id IS NOT NULL
            AND ser.prov_type <> 'Resource'
            AND ser.RPT_GRP_SIX <> '77' -- exclude Northern Illinois SAM 10/25/2022
            AND ser.PRACTICE_NAME_C <> '2307' -- exclude Agrace SAM 10/25/2022
        GROUP BY
            a.hsp_account_id, a.performing_prov_id
        HAVING
            SUM(A.QUANTITY) > 0
    ) AS foo
) AS perf_prov																	ON  perf_prov.hsp_account_id = hsp.hsp_account_id  AND perf_prov.rank = 1


--primary CPT logic 5/25/22
LEFT JOIN 
(SELECT  foo.hsp_account_id, foo.cpt_code, RANK() OVER (PARTITION BY foo.hsp_account_id ORDER BY foo.charges DESC, foo.cpt_code) AS rank
    FROM
    ( SELECT a.hsp_account_id, a.cpt_code, SUM(a.tx_amount) AS charges
        FROM  [Mart_Load_UWHealth].[STRATA_ELEMENTS_HSP_TRANSACTIONS_T] a
        WHERE
            A.TX_TYPE_HA_C = '1' AND a.cpt_code IS NOT NULL
        GROUP BY
            a.hsp_account_id, a.cpt_code
        HAVING
            SUM(A.QUANTITY) > 0
    ) AS foo
) AS CPT_RANK																	ON  HSP.HSP_ACCOUNT_ID = CPT_RANK.hsp_account_id   AND CPT_RANK.rank = 1


--primary HCPCS logic 5/22/2022
LEFT JOIN 
(SELECT foo.hsp_account_id, foo.hcpcs_code, RANK() OVER (PARTITION BY foo.hsp_account_id ORDER BY foo.charges DESC, foo.hcpcs_code) AS rank
    FROM
    ( SELECT a.hsp_account_id, a.hcpcs_code, SUM(a.tx_amount) AS charges
        FROM  [Mart_Load_UWHealth].[STRATA_ELEMENTS_HSP_TRANSACTIONS_T] a
        WHERE
            A.TX_TYPE_HA_C = '1' AND a.hcpcs_code IS NOT NULL
        GROUP BY
            a.hsp_account_id, a.hcpcs_code
        HAVING
            SUM(A.QUANTITY) > 0
    ) AS foo
) AS HCPCS_RANK																	ON   HSP.HSP_ACCOUNT_ID = HCPCS_RANK.hsp_account_id  AND HCPCS_RANK.rank = 1


--Authorizing Provider and Order Type SAM 9/8/21 
LEFT JOIN 
(SELECT foo2.hsp_account_id, foo2.AUTHRZING_PROV_ID
  FROM 
    (SELECT foo.hsp_account_id, foo.AUTHRZING_PROV_ID, ROW_NUMBER() OVER (PARTITION BY foo.hsp_account_id ORDER BY foo.charges DESC, foo.qty DESC, foo.order_inst DESC, foo.order_id) AS prov_rank
       FROM 
	     (SELECT hsp.hsp_account_id,
            SUM(hsp.tx_amount) AS charges,
            COUNT(hsp.tx_id) AS qty,
            opproc.AUTHRZING_PROV_ID,
            opproc.order_inst,
            opproc.ORDER_TYPE_C,
            hsp.order_id
        FROM
            [Mart_Load_UWHealth].[STRATA_ELEMENTS_HSP_TRANSACTIONS_T] HSP
        LEFT JOIN
            [Mart_Load_UWHealth].[STRATA_ELEMENTS_HSP_ACCOUNT_T] HAR				ON hsp.hsp_account_id = har.hsp_account_id
        LEFT JOIN
            SOURCE_UWHEALTH.EPIC_ORDER_PROC_CUR AS opproc						ON opproc.order_proc_id = hsp.order_id AND har.PRIM_ENC_CSN_ID = opproc.pat_enc_csn_id
        LEFT JOIN
            SOURCE_UWHEALTH.EPIC_CLARITY_SER_CUR AS ser							ON opproc.AUTHRZING_PROV_ID = ser.prov_id
        WHERE
            hsp.TX_TYPE_HA_C = '1' -- charges
            AND hsp.order_id IS NOT NULL -- Transaction must have an order associated with it
            AND opproc.AUTHRZING_PROV_ID NOT LIKE '7%' -- Filters out outside providers
            AND ser.RPT_GRP_SIX <> '77' -- Exclude Northern Illinois
            AND ser.PRACTICE_NAME_C <> '2307' -- Exclude Agrace
        GROUP BY
            hsp.hsp_account_id, opproc.AUTHRZING_PROV_ID, opproc.ORDER_TYPE_C, opproc.order_inst, hsp.order_id
    ) AS foo
) AS foo2
WHERE foo2.prov_rank = 1
GROUP BY foo2.hsp_account_id, foo2.AUTHRZING_PROV_ID ) oproc								ON oproc.hsp_account_id = hsp.hsp_account_id;
GO


