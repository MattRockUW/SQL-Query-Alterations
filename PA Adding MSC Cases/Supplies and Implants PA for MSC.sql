/****** Object:  View [Mart_Load_UWHealth].[VIZIENT_PROC_ANALYTICS_SPL_UW]    Script Date: 5/13/2025 9:22:11 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--CREATE VIEW [Mart_Load_UWHealth].[VIZIENT_PROC_ANALYTICS_SPL_UW] AS 
SELECT
/*
11-25-24 Matt Rock - corrected supot and supot2 to find correct pricing, 
removed imp2 for wasted / implanted and removed implants as that table does not log unimplanted implants well
*/
'520098' AS "Medicare Provider ID"
, COALESCE(CAST(orlog.LOC_ID as varchar(18)), '') AS "Sub-Facility ID"
, '40357' AS "Member ID"
, COALESCE(CAST(coalesce(peh.HSP_ACCOUNT_ID, PAT_OR_ADM_LINK.or_link_csn)  as varchar(18)), '') as "Encounter ID" 
, COALESCE(CAST(id.IDENTITY_ID as varchar(25)), '') as "Patient ID"
, COALESCE(orlog.CASE_ID, '') AS "Procedural Case Number"
, COALESCE(CONVERT(nchar(8),orlog.SURGERY_DATE,112),'') AS "Date of Service"  /*The value of 112 is used to format the result as yyyymmdd. */
,CASE
	WHEN SUBSTRing(TRIM(zom_mfg.NAME),LEN(TRIM(zom_mfg.NAME)),1) BETWEEN '0' AND '9'
	THEN SUBSTRing(TRIM(zom_mfg.NAME),1,LEN(TRIM(zom_mfg.NAME))-7)
	WHEN SUBSTRing(TRIM(zom_mfg2.NAME),LEN(TRIM(zom_mfg2.NAME)),1) BETWEEN '0' AND '9'
	THEN SUBSTRing(TRIM(zom_mfg2.NAME),1,LEN(TRIM(zom_mfg2.NAME))-7)
	ELSE COALESCE(zom_mfg.NAME, zom_mfg2.NAME, '')
	END as "Manufacturer Name"
, CAST(COALESCE(imp.MANUF_NUM,imp.MODEL_NUMBER,eosm.MAN_CTLG_NUM,'') as varchar(192)) AS "Manufacturer Catalog Number"
, CASE WHEN  /* String ends with a contenated 6 digit number ID */
	substring(TRIM(COALESCE(zos_imp.NAME,zos_sply.NAME,zos_imp2.NAME,zos_sply2.NAME, '')),
	LEN(TRIM(COALESCE(zos_imp.NAME,zos_sply.NAME,zos_imp2.NAME,zos_sply2.NAME, ''))),
	1) BETWEEN '0' AND '9'  
	THEN /* exclude the 6 digit number string at end */
	substring(TRIM(COALESCE(zos_imp.NAME,zos_sply.NAME,zos_imp2.NAME,zos_sply2.NAME, '')),
	1,
	LEN(TRIM(COALESCE(zos_imp.NAME,zos_sply.NAME,zos_imp2.NAME,zos_sply2.NAME, '')))-7
	)
	ELSE TRIM(COALESCE(zos_imp.NAME,zos_sply.NAME,zos_imp2.NAME,zos_sply2.NAME, ''))  /* use coalesce */
	END as "Vendor Name"

, CAST(COALESCE(imp.SUP_CAT_NUM, ors2.LAST_SUPPLIER_NUM, /*orss.SUPPLIER_CTLG_NUM, orss2.SUPPLIER_CTLG_NUM,*/ '') as varchar(254)) AS "Vendor Catalog Number"  /*DD 8/18/2020 removed orss and orss2 tables from coalesce. Not adding value to coalesce and join is causing duplication and complexity with no additional value.*/
, COALESCE(CAST(imp.MODEL_NUMBER as varchar(30)),CAST(eosm.MAN_CTLG_NUM as varchar(30))) AS "Unique Device Identifier"
, CAST(COALESCE(imp.IMPLANT_NAME, ors2.SUPPLY_NAME, '') as varchar(254)) AS "Item Description"
, COALESCE(CAST(oli_tray.IMPLANT_NUM_USED as varchar(10)),'0') AS "Usage Quantity"
, '' AS "Usage UOM"
, '' AS "Quantity per Usage UOM"
, COALESCE(isd2.IDENTITY_ID,isd.IDENTITY_ID,isd4.IDENTITY_ID,isd3.IDENTITY_ID,ors.Primary_Ext_ID,ors2.Primary_Ext_ID,'') AS "HCO Item Number" /* BJ: 08/05/18 */
, CAST(COALESCE(eap_imp.PROC_CODE, imp.CHARGE_CODE, ors.CHARGE_CODE, ors2.CHARGE_CODE, '') as varchar(40)) AS "Charge Code"
/*, CAST(COALESCE(imp.COST_PER_UNIT,supot.COST_PER_UNIT_OT,imp.COST,imp2.COST_PER_UNIT,supot2.COST_PER_UNIT_OT,imp2.COST,0)as varchar(25)) AS "Supply Cost" See below
Below replaces Supply_Cost to account for Constructs (Set of implants at package cost) used in OR starting July 2019. Doug 1/29/2021  */
,CAST(
	(CASE WHEN Construct.Construct = 'Construct in Case' and (COALESCE(imp.COST_PER_UNIT,supot.COST_PER_UNIT_OT,imp.COST,eosm.MAN_PACK_PRICE,supot2.COST_PER_UNIT_OT, 0)) = '0'
	THEN '.01'	 
	ELSE (COALESCE(imp.COST_PER_UNIT,supot.COST_PER_UNIT_OT,imp.COST,eosm.MAN_PACK_PRICE,supot2.COST_PER_UNIT_OT ,0))
	END) as varchar(25)) AS "Supply Cost"   

, '' AS "Supply Cost UOM" /* DD 8/18/2020 As Implants are in EACH in the data, Supply Cost UOM need not be reported. Joins to OR_SPLY_SUPPLIER removed to avoid duplicates for Implant section. */

/*, COALESCE(CAST(orss.SUPPLIER_PACK_RAT as varchar(10)),CAST(orss2.SUPPLIER_PACK_RAT as varchar(10)), '') AS "Quantity per Supply Cost UOM"-- BJ: 08/02/18KCJ 10/16/19 - removed because the cost is being sent at the lowest quantity and this field was miscalculating cost per case */
, '' AS "Quantity per Supply Cost UOM" /* KCJ 10/16/19 see comment on row above */
, CAST(COALESCE(oli_tray2.IMPLANT_NUM_USED,0) as varchar(10)) AS "Wasted Quantity"
, '' AS "Wasted UOM"
, '' AS "Quantity per Wasted UOM"

FROM [source_uwhealth].epic_or_log_cur orlog
INNER JOIN [source_uwhealth].epic_PAT_OR_ADM_LINK_cur PAT_OR_ADM_LINK ON orlog.CASE_ID = PAT_OR_ADM_LINK.CASE_ID
INNER JOIN [source_uwhealth].epic_PAT_ENC_HSP_cur peh on PAT_OR_ADM_LINK.OR_LINK_CSN = peh.PAT_ENC_CSN_ID
INNER JOIN [source_uwhealth].epic_patient_cur patient ON orlog.PAT_ID = patient.PAT_ID
--INNER JOIN [source_uwhealth].epic_hsp_account_cur har ON peh.HSP_ACCOUNT_ID = har.HSP_ACCOUNT_ID
INNER JOIN [source_uwhealth].epic_identity_ID_cur id ON patient.PAT_ID = id.PAT_ID
LEFT OUTER JOIN [source_uwhealth].epic_or_log_LN_IMPLANT_cur olli ON orlog.LOG_ID = olli.LOG_ID

/* BEGIN "Client to Verify Selection" - compare values selected for IMPLANT_ACTION_C, update as needed to conform to your values */
LEFT OUTER JOIN [source_uwhealth].epic_OR_LNLG_IMPLANTS_cur oli_tray ON olli.IMPLANTS_ID = oli_tray.RECORD_ID and oli_tray.IMPLANT_ACTION_C IN ('1','2','4')  /* implanted, explanted, adjusted */
LEFT OUTER JOIN [source_uwhealth].epic_OR_LNLG_IMPLANTS_cur oli_tray2 ON olli.IMPLANTS_ID = oli_tray2.RECORD_ID and oli_tray2.IMPLANT_ACTION_C = '3'  /* wasted */
/*  END "Client to Verify Selection" */

LEFT OUTER JOIN [source_uwhealth].epic_OR_IMP_cur imp ON oli_tray.IMPLANT_ID = imp.IMPLANT_ID
/* LEFT OUTER JOIN [source_uwhealth].epic_OR_IMP_cur imp2 ON oli_tray2.IMPLANT_ID = imp2.IMPLANT_ID 
MAR 11-22-24: epic_OR_IMP_cur does not track wasted or used and removed implants */
LEFT OUTER JOIN [source_uwhealth].epic_OR_SPLY_cur ors ON imp.Inventory_Item_ID = ors.Supply_ID
LEFT OUTER JOIN [source_uwhealth].epic_OR_SPLY_cur ors2 ON oli_tray2.IMP_INV_TYPE_ID = ors2.Supply_ID
LEFT OUTER JOIN [Source_UWHealth].EPIC_OR_SPLY_MANFACTR_CUR eosm on eosm.item_id = oli_tray2.IMP_INV_TYPE_ID
/* LEFT OUTER JOIN OR_SPLY_SUPPLIER orss ON imp.Inventory_Item_Id = orss.Item_ID-- BJ: 08/02/18 -- DD 8/18/2020 Joins to OR_SPLY_SUPPLIER removed to avoid duplicates for Implant section.
 LEFT OUTER JOIN OR_SPLY_SUPPLIER orss2 ON imp2.Inventory_Item_Id = orss2.Item_ID  			-- DD 8/18/2020 Joins to OR_SPLY_SUPPLIER removed to avoid duplicates for Implant section.
 LEFT OUTER JOIN ZC_OR_UNIT_ISSUE zoui ON orss.SUPPLIER_PACK_T_C = zoui.Unit_Issue_C-- BJ: 08/02/18 -- DD 8/18/2020 Joins to OR_SPLY_SUPPLIER removed to avoid duplicates for Implant section.
 LEFT OUTER JOIN ZC_OR_UNIT_ISSUE zoui2 ON orss2.SUPPLIER_PACK_T_C = zoui2.Unit_Issue_C  		-- DD 8/18/2020 Joins to OR_SPLY_SUPPLIER removed to avoid duplicates for Implant section. */
LEFT OUTER JOIN [source_uwhealth].epic_ZC_OR_MANUFACTURER_cur zom_mfg ON imp.MANUFACTURER_C = zom_mfg.MANUFACTURER_C
LEFT OUTER JOIN [source_uwhealth].epic_ZC_OR_MANUFACTURER_cur zom_mfg2 ON eosm.MANUFACTURER_C = zom_mfg2.MANUFACTURER_C
LEFT OUTER JOIN [source_uwhealth].epic_ZC_OR_SUPPLIER_cur zos_sply ON imp.VENDOR_DISTRIB_C = zos_sply.SUPPLIER_C
LEFT OUTER JOIN [source_uwhealth].epic_ZC_OR_SUPPLIER_cur zos_sply2 ON ors2.LAST_SUPPLIER_C = zos_sply2.SUPPLIER_C

LEFT OUTER JOIN [source_uwhealth].epic_CLARITY_EAP_cur eap_imp ON imp.CHARGE_CODE_EAP_ID = eap_imp.PROC_ID
/*LEFT OUTER JOIN [source_uwhealth].epic_CLARITY_EAP_cur eap_imp2 ON imp2.CHARGE_CODE_EAP_ID = eap_imp2.PROC_ID 
MAR 11-22-24- epic_OR_IMP_cur was for wasted implants, but wasted or used and removed implants are not well logged in this table */
LEFT OUTER JOIN [source_uwhealth].epic_ZC_OR_MANUFACTURER_cur zos_imp ON imp.MANUFACTURER_C = zos_imp.MANUFACTURER_C
LEFT OUTER JOIN [source_uwhealth].epic_ZC_OR_MANUFACTURER_cur zos_imp2 ON eosm.MANUFACTURER_C = zos_imp2.MANUFACTURER_C
LEFT OUTER JOIN [source_uwhealth].epic_patient_3_cur pat3 ON patient.PAT_ID = pat3.PAT_ID

LEFT OUTER JOIN [source_uwhealth].epic_OR_SPLY_OVTM_cur supot ON oli_tray.IMP_INV_TYPE_ID = supot.ITEM_ID AND supot.EFFECTIVE_DATE =
(SELECT MAX(supot_sub1.EFFECTIVE_DATE)
 FROM [source_uwhealth].epic_OR_SPLY_OVTM_cur supot_sub1
 WHERE supot_sub1.EFFECTIVE_DATE <= orlog.SURGERY_DATE and oli_tray.IMP_INV_TYPE_ID = supot_sub1.item_id)

LEFT OUTER JOIN [source_uwhealth].epic_OR_SPLY_OVTM_cur supot2 ON oli_tray2.IMP_INV_TYPE_ID = supot2.ITEM_ID AND supot2.EFFECTIVE_DATE =
(SELECT MAX(supot_sub2.EFFECTIVE_DATE)
 FROM  [source_uwhealth].epic_OR_SPLY_OVTM_cur supot_sub2 
 WHERE supot_sub2.EFFECTIVE_DATE <= orlog.SURGERY_DATE  and oli_tray2.IMP_INV_TYPE_ID = supot_sub2.item_id)

LEFT OUTER JOIN (SELECT olat.LOG_ID, MAX(olat.AUDIT_DATE) OVER(PARTITION BY olat.LOG_ID ORDER BY olat.LOG_ID, olat.AUDIT_DATE desc) AS PostDate
 FROM [source_uwhealth].epic_or_log_AUDIT_TRAIL_cur olat 
 WHERE olat.AUDIT_ACTION_C = '7'
) olat2 ON orlog.LOG_ID = olat2.LOG_ID

LEFT OUTER JOIN [source_uwhealth].epic_identity_SUP_ID_cur isd ON imp.INVENTORY_ITEM_ID = isd.SUPPLY_ID
LEFT OUTER JOIN [source_uwhealth].epic_identity_SUP_ID_cur isd2 ON oli_tray.IMP_INV_TYPE_ID = isd2.SUPPLY_ID
LEFT OUTER JOIN [source_uwhealth].epic_identity_SUP_ID_cur isd3 ON oli_tray2.IMP_INV_TYPE_ID = isd3.SUPPLY_ID
LEFT OUTER JOIN [source_uwhealth].epic_identity_SUP_ID_cur isd4 ON oli_tray2.IMP_INV_TYPE_ID = isd4.SUPPLY_ID

/* Construct Subquery identifying Constructs for Supply_Cost case statement 1/29/2021 Doug 
MAR 11-22-24: Constructs are no longer used in Madison UW locations since July 2021 - left in for prior cases
*/
left outer join 
(select distinct vlog.CASE_ID, 'Construct in Case' as Construct
	from [source_uwhealth].epic_v_log_supplies_implants_cur vlog
  	where vlog.Implant_NM like 'CONSTRUCT %'       /* 'CONSTRUCT ' per UW OR Brenda Brookins 1/21/2021 */
	 or vlog.ITEM_NM like 'CONSTRUCT %'  			
) construct ON orlog.LOG_ID = construct.CASE_ID
---------

WHERE
/* Opt1 Historical and Monthly Logic
orlog.SURGERY_DATE >= '11/1/2022' AND orlog.SURGERY_DATE < '12/1/2022'  Commenting 06/04/2024
 Opt2 Daily Logic
 CONVERT(varchar,olat2.PostDate,112) = CONVERT(varchar,GETDATE()-1,112)
AND  */
(pat3.IS_TEST_PAT_YN IS NULL OR pat3.IS_TEST_PAT_YN = 'N')
AND patient.PAT_MRN_ID NOT LIKE 'ZZ%'
AND (oli_tray.IMPLANT_ID IS NOT NULL OR oli_tray2.IMPLANT_ID IS NOT NULL)
AND (oli_tray.IMPLANT_NUM_USED > 0 OR oli_tray2.IMPLANT_NUM_USED > 0)
AND (oli_tray.IMPLANT_ACTION_C <> '2' OR oli_tray2.IMPLANT_ACTION_C = '3') /*KCJ 11/13/18 excluding explants per Brenda Brookins */
/* BEGIN Facility Selection--default is all */
--AND har.SERV_AREA_ID IN ('10000')
AND orlog.LOC_ID NOT IN ('88600','99600')
AND orlog.ROOM_ID NOT IN ('692742','692743','692744','692745','692746','692747','692748','692749','692875','692876','692877','693301','693326','695241','695382','695383') --APC rooms to be excluded because many noninvasive procedures and others that are causing data quality concerns
AND orlog.ROOM_ID NOT IN ('693288','695076') /* RN Out rooms that are often non-invasive procedures */
/*AND har.LOC_ID IN ('37000')
AND orlog.LOC_ID = '91000'
 END Facility Selection */

/* 12/12/18 KCJ adding below filters in order to remove $0 items that should not be in submitted data, many of these are just placeholder items in Epic */
 
AND COALESCE(imp.IMPLANT_NAME, ors2.SUPPLY_NAME, '') NOT LIKE '%IV BIN%' /* "Item Description" as in SELECT not like 'IV BIN' */
AND COALESCE(isd2.IDENTITY_ID,isd.IDENTITY_ID,isd4.IDENTITY_ID,isd3.IDENTITY_ID,ors.Primary_Ext_ID,ors2.Primary_Ext_ID,'') NOT IN ('MIX','ANES LEVEL C TRIGGER','LAP SOAKING BIN','CHARTING CODE','HOMEMADE')  /* "HCO Item Number" as in SELECT is not in list */
/*AND zom_mfg.MANUFACTURER_C <> '144' --[Commented out May 2020 and SPL resubmitted - causing missing records where Manuf is null]
AND zom_mfg.TITLE NOT LIKE '%DO NOT%' --[Commented out May 2020 and SPL resubmitted - causing missing records where Manuf is null]
AND zom_mfg.NAME <> 'NONE NEEDED/KNOWN/WANTED'
AND zom_mfg2.NAME <> 'NONE NEEDED/KNOWN/WANTED'
AND zos_imp.NAME <> 'NONE NEEDED/KNOWN/WANTED'
AND zos_imp2.NAME <> 'NONE NEEDED/KNOWN/WANTED'
AND zos_sply.NAME <> 'NONE NEEDED/KNOWN/WANTED'
AND zos_sply2.NAME <> 'NONE NEEDED/KNOWN/WANTED'
AND ("HCO Item Number" <> '' AND "Supply Cost" <> '0') */

AND id.IDENTITY_TYPE_ID = 0

/*END Implant ******************************************************************************/
UNION all
/*Begin Supplies*************************/



SELECT DISTINCT
'520098' AS "Medicare Provider ID"
, COALESCE(CAST(orlog.LOC_ID as varchar(18)), '') AS "Sub-Facility ID"
, '40357' AS "Member ID"
,COALESCE(CAST(coalesce(peh.HSP_ACCOUNT_ID, PAT_OR_ADM_LINK.or_link_csn) as varchar(18)), '') as "Encounter ID"
,COALESCE(CAST(id.IDENTITY_ID as varchar(25)), '') as "Patient ID"
, COALESCE(orlog.CASE_ID, '') AS "Procedural Case Number"
, COALESCE(CONVERT(nchar(8),orlog.SURGERY_DATE,112),'') AS "Date of Service"  /*The value of 112 is used to format the result as yyyymmdd. */
/*,CASE
WHEN SUBSTR(TRIM(zom_mfg.NAME),LENGTH(TRIM(zom_mfg.NAME))) BETWEEN '0' AND '9'
THEN CAST(SUBSTR(TRIM(zom_mfg.NAME),1,INSTR(TRIM(zom_mfg.NAME),' ',-1,1)) as varchar(254))
ELSE COALESCE(CAST(zom_mfg.NAME as varchar(254)), '')
END as "Manufacturer Name" */
,CASE
	WHEN SUBSTRing(TRIM(zom_mfg.NAME),LEN(TRIM(zom_mfg.NAME)),1) BETWEEN '0' AND '9'
	THEN SUBSTRing(TRIM(zom_mfg.NAME),1,LEN(TRIM(zom_mfg.NAME))-7)  /* Using LEN(TRIM(zom_mfg.NAME))-7 as of MS SQL conversion. Original truncates to first space in THEN. */
	ELSE COALESCE(zom_mfg.NAME, '')
	END as "Manufacturer Name"
, CAST(COALESCE(osm.MAN_CTLG_NUM, '') as varchar(192)) AS "Manufacturer Catalog Number"
/*, CAST(COALESCE(zos.NAME,zom_sply.NAME, '') as varchar(254)) AS "Vendor Name" kcj 3/9/19 commented out in exchange for below case statement that eliminates concatentation issue with vendor name and id
,CAST(
(CASE
WHEN zos.NAME IS NOT NULL AND SUBSTR(TRIM(zos.NAME),LENGTH(TRIM(zos.NAME))) BETWEEN '0' AND '9'
THEN SUBSTR(TRIM(zos.NAME),1,INSTR(TRIM(zos.NAME),' ',-1,1))
WHEN zos.NAME IS NOT NULL AND SUBSTR(TRIM(zos.NAME),LENGTH(TRIM(zos.NAME))) BETWEEN 'A' AND 'Z'
THEN zos.NAME
WHEN zos.NAME IS NULL AND SUBSTR(TRIM(zom_sply.NAME),LENGTH(TRIM(zom_sply.NAME))) BETWEEN '0' AND '9'
THEN SUBSTR(TRIM(zom_sply.NAME),1,INSTR(TRIM(zom_sply.NAME),' ',-1,1))
WHEN zos.NAME IS NULL AND SUBSTR(TRIM(zom_sply.NAME),LENGTH(TRIM(zom_sply.NAME))) BETWEEN 'A' AND 'Z'
THEN zom_sply.NAME
ELSE ''
END) as varchar(254)) "Vendor Name" */

, CASE WHEN  /* String ends with a contenated 6 digit number ID */
		substring(TRIM(COALESCE(zos.NAME,zom_sply.NAME, '')),
		LEN(TRIM(COALESCE(zos.NAME,zom_sply.NAME, ''))),
		1) BETWEEN '0' AND '9'  
	THEN /* exclude the 6 digit number string at end */
		substring(TRIM(COALESCE(zos.NAME,zom_sply.NAME, '')),
		1,
		LEN(TRIM(COALESCE(zos.NAME,zom_sply.NAME, '')))-7
		)
	ELSE TRIM(COALESCE(zos.NAME,zom_sply.NAME, ''))  /* use coalesce */
	END as "Vendor Name"

/* ORIGINAL ORDER , CAST(COALESCE(oss.SUPPLIER_CTLG_NUM,ors.LAST_SUPPLIER_NUM, '') as varchar(254)) AS "Vendor Catalog Number" */
, CAST(COALESCE(ors.LAST_SUPPLIER_NUM, oss.SUPPLIER_CTLG_NUM, '') as varchar(254)) AS "Vendor Catalog Number" /* Doug edit 8/18/2020 Coalesce order changed to look at OR_SPLY first to avoid duplicates from OR_SPLY_SUPPLIER (oss) */
, CAST('' as varchar(30)) AS "Unique Device Identifier"
, CAST(COALESCE(ors.SUPPLY_NAME, '') as varchar(254)) AS "Item Description"
, COALESCE(CAST(vlsi.NUMBER_USED as varchar(10)),CAST(vlsi.NUMBER_WASTED as varchar(10)),'0') AS "Usage Quantity"
, '' AS "Usage UOM"
, '' AS "Quantity per Usage UOM"
, COALESCE(isd.IDENTITY_ID, ors.Primary_Ext_ID, '') AS "HCO Item Number"/* BJ: 08/05/18 */
, CAST(COALESCE(eap_sply.PROC_CODE, ors.CHARGE_CODE, '') as varchar(40)) AS "Charge Code"
, COALESCE(CAST(vlsi.COST_PER_UNIT as varchar(25)),CAST(supot.COST_PER_UNIT_OT as varchar(25)),'0') AS "Supply Cost"
, COALESCE(zoui.ABBR, '') AS "Supply Cost UOM"/* BJ: 08/02/18 */
/*, ISNULL(orss.SUPPLIER_PACK_RAT, '') AS 'Quantity per Supply Cost UOM'  BJ: 08/02/18
, COALESCE(CAST(orss.SUPPLIER_PACK_RAT as varchar(10)),CAST(orss2.SUPPLIER_PACK_RAT as varchar(10)), '') AS "Quantity per Supply Cost UOM"  BJ: 08/02/18KCJ 10/16/19 - removed because the cost is being sent at the lowest quantity and this field was miscalculating cost per case*/
,'' AS "Quantity per Supply Cost UOM" /* KCJ 10/16/19 see comment on row above */
, COALESCE(CAST(vlsi.NUMBER_WASTED as varchar(10)),'0') AS "Wasted Quantity"
, '' AS "Wasted UOM"
, '' AS "Quantity per Wasted UOM"


FROM [source_uwhealth].epic_or_log_cur orlog
INNER JOIN [source_uwhealth].epic_PAT_OR_ADM_LINK_cur PAT_OR_ADM_LINK ON orlog.CASE_ID = PAT_OR_ADM_LINK.CASE_ID
INNER JOIN [source_uwhealth].epic_PAT_ENC_HSP_cur peh on PAT_OR_ADM_LINK.OR_LINK_CSN = peh.PAT_ENC_CSN_ID
INNER JOIN [source_uwhealth].epic_patient_cur patient ON orlog.PAT_ID = patient.PAT_ID
--INNER JOIN [source_uwhealth].epic_hsp_account_cur har ON peh.HSP_ACCOUNT_ID = har.HSP_ACCOUNT_ID
INNER JOIN [source_uwhealth].epic_identity_id_cur id ON patient.PAT_ID = id.PAT_ID
INNER JOIN [source_uwhealth].epic_v_log_supplies_implants_cur vlsi on orlog.LOG_ID = vlsi.LOG_ID AND vlsi.IMPLANT_ID IS NULL
LEFT OUTER JOIN [source_uwhealth].epic_OR_SPLY_cur ors ON vlsi.ITEM_ID = ors.SUPPLY_ID

LEFT OUTER JOIN [source_uwhealth].epic_or_sply_supplier_cur oss ON ((vlsi.ITEM_ID = oss.ITEM_ID)
/* Doug edit 8/18/2020 New join to supplier below to above line where epic allows multiple ITEM_ID/LINE is the primary key */
and (oss.SUPPLIER_C = ors.LAST_SUPPLIER_C))

LEFT OUTER JOIN [source_uwhealth].epic_OR_SPLY_MANFACTR_CUR osm ON /*(*/(vlsi.ITEM_ID = osm.ITEM_ID)

LEFT OUTER JOIN [source_uwhealth].epic_or_sply_supplier_cur orss ON ((vlsi.Item_Id = orss.Item_ID)/* BJ: 08/02/18
 Doug edit 8/18/2020 New join to supplier below to above line where epic allows multiple ITEM_ID/LINE is the primary key */
and (orss.SUPPLIER_C = ors.LAST_SUPPLIER_C))

LEFT OUTER JOIN [source_uwhealth].epic_ZC_OR_UNIT_ISSUE_CUR zoui ON orss.SUPPLIER_PACK_T_C = zoui.Unit_Issue_C/* BJ: 08/02/18 */
LEFT OUTER JOIN [source_uwhealth].epic_ZC_OR_MANUFACTURER_cur zom_mfg ON osm.MANUFACTURER_C = zom_mfg.MANUFACTURER_C
LEFT OUTER JOIN [source_uwhealth].epic_ZC_OR_SUPPLIER_cur zos ON oss.SUPPLIER_C = zos.SUPPLIER_C
LEFT OUTER JOIN [source_uwhealth].epic_ZC_OR_MANUFACTURER_cur zom_sply on oss.SUPPLIER_C = zom_sply.MANUFACTURER_C
LEFT OUTER JOIN [source_uwhealth].epic_clarity_ucl_cur ucl ON orlog.LOG_ID = ucl.SURGICAL_LOG_ID AND vlsi.ITEM_ID = ucl.SUPPLY_ID
LEFT OUTER JOIN [source_uwhealth].epic_CLARITY_EAP_cur eap_sply ON ucl.PROCEDURE_ID = eap_sply.PROC_ID
LEFT OUTER JOIN [source_uwhealth].epic_patient_3_cur pat3 ON patient.PAT_ID = pat3.PAT_ID
LEFT OUTER JOIN [source_uwhealth].epic_or_log_LN_IMPLANT_cur olli ON orlog.LOG_ID = olli.LOG_ID
LEFT OUTER JOIN [source_uwhealth].epic_OR_LNLG_IMPLANTS_cur oli_tray ON olli.IMPLANTS_ID = oli_tray.RECORD_ID
LEFT OUTER JOIN [source_uwhealth].epic_OR_SPLY_OVTM_cur supot ON vlsi.ITEM_ID = supot.ITEM_ID AND supot.EFFECTIVE_DATE =
(SELECT MAX(OR_SPLY_OVTM_sub1.EFFECTIVE_DATE)
 FROM [source_uwhealth].epic_or_log_cur orlog_sub1
 INNER JOIN [source_uwhealth].epic_v_log_supplies_implants_cur vlsi_sub1 on orlog_sub1.LOG_ID = vlsi_sub1.LOG_ID AND vlsi_sub1.IMPLANT_ID IS NULL
  INNER JOIN [source_uwhealth].epic_OR_SPLY_OVTM_cur OR_SPLY_OVTM_sub1 ON vlsi_sub1.ITEM_ID = OR_SPLY_OVTM_sub1.ITEM_ID
 WHERE (OR_SPLY_OVTM_sub1.EFFECTIVE_DATE <= orlog_sub1.SURGERY_DATE))

LEFT OUTER JOIN (SELECT olat.LOG_ID, MAX(olat.AUDIT_DATE) OVER(PARTITION BY olat.LOG_ID ORDER BY olat.LOG_ID, olat.AUDIT_DATE desc) AS PostDate
 FROM [source_uwhealth].epic_or_log_AUDIT_TRAIL_cur olat 
 WHERE olat.AUDIT_ACTION_C = '7'
) olat2 ON orlog.LOG_ID = olat2.LOG_ID

LEFT OUTER JOIN [source_uwhealth].epic_identity_SUP_ID_cur isd ON vlsi.ITEM_ID = isd.SUPPLY_ID

WHERE
/* Opt1 Historical and Monthly Logic
orlog.SURGERY_DATE >= '11/1/2022' AND orlog.SURGERY_DATE < '12/1/2022'  Commenting 06/04/2024

 Opt2 Daily Logic
 CONVERT(varchar,olat2.PostDate,112) = CONVERT(varchar,GETDATE()-1,112)


AND */
(pat3.IS_TEST_PAT_YN IS NULL OR pat3.IS_TEST_PAT_YN = 'N')
AND patient.PAT_MRN_ID NOT LIKE 'ZZ%'
/* AND vlsi.ITEM_ID is not null -- BJ: attempt to filter out Equip, Instruments and RX items... not the right approach as these item types have MMIS Item #'s */

/* BEGIN Facility Selection--default is all */
--AND har.SERV_AREA_ID IN ('10000')
AND orlog.LOC_ID NOT IN ('88600','99600')
AND orlog.ROOM_ID NOT IN ('692742','692743','692744','692745','692746','692747','692748','692749','692875','692876','692877','693301','693326','695241','695382','695383') --APC rooms to be excluded because many noninvasive procedures and others that are causing data quality concerns */
AND orlog.ROOM_ID NOT IN ('693288','695076') -- RN Out rooms that are often non-invasive procedures */
/* AND har.LOC_ID IN ('37000')
AND orlog.LOC_ID = '91000'
 END Facility Selection */

/* 12/12/18 KCJ adding below filters in order to remove $0 items that should not be in submitted data, many of these are just placeholder items in Epic */

AND CAST(COALESCE(ors.SUPPLY_NAME, '') as varchar(254)) NOT LIKE '%IV BIN%' /* "Item Description" as in SELECT not like 'IV BIN' */
AND COALESCE(isd.IDENTITY_ID, ors.Primary_Ext_ID, '') NOT IN ('MIX','ANES LEVEL C TRIGGER','LAP SOAKING BIN','CHARTING CODE','HOMEMADE')  /* "HCO Item Number" as in SELECT is not in list */
/* AND zom_mfg.MANUFACTURER_C <> '144' --[Commented out May 2020 and SPL resubmitted - causing missing records where Manuf is null]
AND zom_mfg.TITLE NOT LIKE '%DO NOT%' --[Commented out May 2020 and SPL resubmitted - causing missing records where Manuf is null]
AND zom_mfg.NAME <> 'NONE NEEDED/KNOWN/WANTED'
AND zom_sply.NAME <> 'NONE NEEDED/KNOWN/WANTED'
AND zos.NAME <> 'NONE NEEDED/KNOWN/WANTED'
AND ("HCO Item Number" <> '' AND "Supply Cost" <> '0') */

AND id.IDENTITY_TYPE_ID = '0'

;
GO


