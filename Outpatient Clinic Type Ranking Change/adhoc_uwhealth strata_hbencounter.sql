/****** Object:  View [Mart_Load_UWHealth].[STRATA_HBEncounter]    Script Date: 2/4/2025 3:57:35 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [adhoc_UWHealth].[STRATA_HBEncounter] AS SELECT * from ( select
/**********************************************************************************************************************
Title/Object: STRATA_HBEncounter - Strata_HBEncounterExtract- Port from Strata Sample extract
Purpose: 
Business Rules Summary:
History: This extract query was ported from the Strata Sample extract and updated for UWHealth.
DATE		Developer				Action
4/22/2020	Michael Connell			Version 1 - Port to Netezza and update with UWH specific logic
5/12/2020	Michael Connell			Updates based on strata feedback and new requirements
5/22/2020	Michael Connell			Minor update based on Strata feedback
7/28/2020	Sean Meirose			Added alt payor logic to current insurance plan field.
8/10/2020	Sean Meirose			Added 4 fields for provider attributed academic clinical dep/section and two for region/market.
9/3/2020	Sean Meirose			Removed unnecessary join to HSP_ACCT_SBO and populated zip code market/region fields.
9/8/2020	Sean Meirose			Unioned in SAGE extracts.
9/15/2020	Lorie Quickel			Commented off the SAGE unions until resources are developed
									Commented off the Conversion of the EncounterRecordNumber to ::VARCHAR(25) until the inclusion of the SAGE records is ironed out.
9/18/2020   Lorie Quickel			Commented off the UDFProvAttr* fields as they will be added in a fture Sprint with added features
10/7/2020	Mark Renshaw			Modified join for ZC_SEX to link to PATIENT.SEX_C instead of HSP_ACCOUNT.PAT_SEX_C, as PAT_SEX_C in HSP_ACCOUNT is often (erroneously) null.
10/19/2020	Sean Meirose			Unioned in SAGE extracts with updated primary keys and tested for duplicates. 
									NOTE: We do not have a SAGE subquery for non-chargeable supplies in HB Encounter, since they are dropped on real HARs.
11/5/2020	Lorie Quickel			Created as STRATA_HBEncounter_Temp_V to accommodate the MergeJoin setting requirement via Informatica
11/19/2020	Sean Meirose			Added logic for Sprint 5 fields (populations, medically homed).
1/20/2021	Sean Meirose			Added logic for Sprint 7 fields (MSDRG Cost Weight and Medsurg Code)
1/29/2021	Sean Meirose			Added atomic logic for MSDRG and updated join to Sprint 7 fields described above.
2/05/2021   Lorie Quickel			Collapsed all of the DRG related joins down to a single atomic subquery for efficiency
2/17/2021	Sean Meirose			Added MRN join using new Clarity object from February 2021 HealthLink upgrade.
									Updated retail pharmacy filter to use like criteria instead of equals.
									Updated UDF_PAYOR_RISK_ARRANGEMENT to use RISK_REV_UWH in alignment with STRATA_PBENCOUNTER.
3/18/2021	Sean Meirose			Replaced retail pharmacy SAGE section with version based on SOURCE_UWHEALTH...EA_STcptRATA_RETAILRX_SUMMARY.
3/22/2021	Sean Meirose			Updated estimated reimbursement filter to include FY21 values from new modeler.
5/13/2021	Sean Meirose			Updated SAGE to include estimated reimbursement.
									Added principal surgeon logic for academic clinical department and section.
									Added dummy insurance plan values for SAGE retail pharmacy.
									Populated Neuro and Ortho population fields for SAGE.
5/20/2021	Sean Meirose			Updated Quartz risk flag logic and join for SAGE and HB to join using coverage.
									Updated Insurance Plan 1, RiskRev and GL Payor ID assignments for SAGE.
6/28/2021	Sean Meirose			Added logic for UDF_GL_BUILDING_ID and UDF_OP_ENC_TYPE.
									Exposed OR_CASES, PATIENT_ID, and ZIPCODE_MARKET_2000B.
									Added CY21 NGACO population.
9/8/2021	Sean Meirose			Added attribution provider logic.
									Corrected OP Encounter Type to assign INPT to inpatient encounters.
									Added patient payment and MSDRG clinical group.
									Added Quartz Region, Line of Business, Line of Business Breakdown, Risk Panel,
									and Cap Breakdown.
									Updated retail pharmacy source system from SAGE to RetailRx.
									Updated Quartz Risk flag to assign Yes if a coverage was present (no filter on RISK)
									Corrected NGACO flag to include values from the CY21 population.
									Updated estimated reimbursement date range to send updated FY19 reimbursement.
9/14/2021	Sean Meirose			Updated SAGE service area filter per fall upgrade notes.
9/27/2021	Sean Meirose			Added HVT columns.
									Removed legacy attribution provider logic.
									Corrected neuro population COALESCEs.
									Updated join for legacy revenue modeler.
1/14/2022	Sean Meirose			Updated Quartz Risk flag to align with FY21 business rule.
									Hard coded SAGE/RetailRx in UDF_OP_ENC_TYPE for SAGE and RetailRx respectively.
									Added provider fields used in attribution provider: CPT Performing Provider and Principal Surgeon.
									Added principal procedure input columns and logic: Primary CPT/HCPCS code and Procedure Type.
									Nulled market/region fields due to new separate extract.
2/18/2022	Sean Meirose			Added AODA Flag.
5/25/2022	Sean Meirose			Updated primary CPT/HCPCS and CPT Performing Provider logic by adding new subqueries.
									NOTE: By extension, this updates Principal Surgeon and Attribution Provider
6/9/2022	Sean Meirose			Updated principal procedure and procedure type to reference the logic from 5/25/22.
6/24/2022	Swati Gupta				Updated to include DC population
7/25/2022	Sarah Orandi/Swati Gupta
									Added type 4 dummy record for Optical revenue from GL
8/3/2022	Sean Meirose			Replaced subqueries for insurance, principal GL building ID, OP Enc Type, and OR cases with
									references to new QA_DATAMART materialized views.
									Hardcoded '2' for RetailRx MRNs
									Further updated principal procedure and procedure type to reference both 3M coded CPT codes
									for procedures and highest charge transaction when a viable coded CPT is not present.
									Updated CY21 ACO population to use same format as other closed calendar years.
9/14/2022	Sean Meirose			Added hard coded patient types for Retail Pharmacy and Optical revenue.
10/25/2022	Sean Meirose			Added joins and filters to CLARITY_SER to eliminate Northern Illinois & Agrace
									providers from tech charge attribution logic.
									Drop surgical DRG requirement for Inpatient Principal Surgeon logic. Still required for Tech Attribution.
									Allow CPT performing provider for Inpatient Principal Surgeon and Tech Attribution Provider
									if OR Case Count exceeds 0.
11/08/2023	Sean Meirose			Converted to MS SQL.
12/05/2023	Sean Meirose			Finished initial conversion to MS SQL. Need to address RetailRx and Optical when source objects are available.
03/15/2024  Lorie Quickel			Streamlined the logic with Bridge tables for performance in MSSQL
06/12/2024  Sean Meirose			Added in Populations references as found in MDW
07/10/2024	Elizabeth Bohuski		Commenting out oncenc (oncology) and orthhb temporarily due to replicates in populations source objects
07/18/2024	Elizabeth Bohuski		Zipcode logic: Substring(HSP.PAT_ZIP,1,5); UDFNGACOIndicator: ISNULL(NGACO.NGACOIndicator,'N')
09/20/2024	Swati Gupta				Add UDF_SERVICE_AREA_ID
10/24/2024	Swati Gupta				Fixed EntityCode for NI
**********************************************************************************************************************/

cast(HSP.HSP_ACCOUNT_ID as numeric(36,0))														AS EncounterRecordNumber
,MRN.PAT_MRN																					AS MedicalRecordNumber
,LOC.LOC_ID				  																		AS LocationCode
, case when hsp.serv_area_id = '10000' then '211'  	
	   when hsp.serv_area_id = '110000000' then [GL_COMPANY_ID]
	   else 0 END																				AS EntityCode
,HSP.ACCT_CLASS_HA_C  																			AS PatientTypeCode
,P.PAT_FIRST_NAME				 																AS FirstName
,P.PAT_LAST_NAME			 																	AS LastName
,P.PAT_MIDDLE_NAME				  																AS MiddleName
,case when ZC_SEX.ABBR in ('F','M','U') then ZC_SEX.ABBR else 'U' end				  			AS GenderCode
,convert(varchar(8),cast(P.BIRTH_DATE as date),112)												AS DateOfBirth
,RACE.PATIENT_RACE_C																			AS RaceCode
,P.MARITAL_STATUS_C				  																AS MaritalStatusCode 
/* MC: assume that Numeric Zips are US Post Codes and just send the first 5. */
,Substring(HSP.PAT_ZIP,1,5)														AS ZipCode
,TRIM(CONCAT(COALESCE(replace(HSP.PAT_ADDR_1,'|',''),''),' ',COALESCE(replace(HSP.PAT_ADDR_2,'|',''),''),'')) AS StreetAddress /*combineline1and2ofaddress and removing pipes */
,HSP.pat_CITY				  																	AS City
,ZC_STATE.ABBR  																				AS State
,ZC_COUNTY.NAME				  																	AS County
/* MC:  Not populating.  Paul indicated Future use. */
,NULL																							AS EmployerCode /* PAT_OCCUPN_HX, not yet in SOURCE_UWHEALTH. */
,HSP.GUARANTOR_ID			  																	AS GuarantorCode
/* MC:  Not populating.  Paul indicated Future use. */
,NULL																							AS GuarantorEmployerCode /* SOURCE_UWHEALTH.EPIC_ACCOUNT.EMPLOYER_ID */
/*MC:  Valuing Quartz tapestry plans to '99999' to cut down on noise.  INS 1 is set to -100 for self pay.  This is not applied to the secondary and beyond plans, they are null. */
,Case when CAST(UWH_INS.INS_PLAN_1 AS integer) > 9000000  then 99999 
	else  COALESCE(UWH_INS.INS_PLAN_1,-100) END													AS InsurancePlan1Code
,Case when CAST(UWH_INS.INS_PLAN_2 AS integer)> 9000000  then 99999 
	else UWH_INS.INS_PLAN_2 END 																AS InsurancePlan2Code
,Case when CAST(UWH_INS.INS_PLAN_3 AS integer) > 9000000  then 99999 
	else UWH_INS.INS_PLAN_3 END 																AS InsurancePlan3Code
,Case when CAST(UWH_INS.INS_PLAN_4 AS integer) > 9000000  then 99999 
	else UWH_INS.INS_PLAN_4 END 																AS InsurancePlan4Code
,Case when CAST(UWH_INS.INS_PLAN_5 AS integer) > 9000000  then 99999 
	else UWH_INS.INS_PLAN_5 END 																AS InsurancePlan5Code
/* MC:  Not populating.  Paul indicated Future use. */
,NULL 																							AS PatientMotherERN /*HSP_LD_MOM_CHILD, needs to be in Aginity */
/* MC:  Not populating.  Paul indicated Future use. */
,NULL																							AS NewbornFlag /* CASE WHEN HSP.ADMISSION_TYPE_C = 4 THEN 'Y' ELSE 'N' END AS 'Newborn Flag' */
,convert(varchar(8),cast(HSP.ADM_DATE_TIME as date),112)										AS AdmitDate
,convert(varchar(5),cast(HSP.ADM_DATE_TIME as datetime),108)									AS AdmitTime
 /* For inpatients use the IP admit date which may be different from the account admit date. */
 ,CASE WHEN HSP.ACCT_BASECLS_HA_C = 1
 THEN convert(varchar(8),cast(HSP.IP_ADMIT_DATE_TIME as date),112)
 WHEN HSP.IP_ADMIT_DATE_TIME IS NULL THEN NULL ELSE NULL END  									AS IPAdmitDate
,HSP.ADMISSION_TYPE_C  																			AS AdmitTypeCode
,HSP.ADMISSION_SOURCE_C				  															AS AdmitSourceCode
,CLARITY_ADT.DEPARTMENT_ID				  														AS AdmitDepartmentCode
,NULL																							AS AdmitNurseStationCode /*MC:  Not populating.  Paul indicated Future use.  This is ADT data, there is code in BPADDEV to pull this value */
,HSP.MEANS_OF_ARRV_C			  																AS MethodofArrivalCode
,CASE WHEN CLARITY_EDG.REF_BILL_CODE_SET_C = 2 THEN CLARITY_EDG.REF_BILL_CODE END				AS AdmitICD10DXCode
,CASE WHEN EDG.REF_BILL_CODE_SET_C = 2 THEN EDG.REF_BILL_CODE END  								AS PrimaryICD10DXCode
,CASE WHEN CL_ICD_PX.REF_BILL_CODE_SET_C = 2 THEN CL_ICD_PX.REF_BILL_CODE END  					AS PrimaryICD10PXCode
,DRG.MSDRG				  																		AS MSDRGCode
,NULL																							AS APRDRGSchema /* MC:  Not populating.  Paul indicated Future use.  I think this is only used when we have a state specific DRGs */
,DRG.APRDRG 																					AS APRDRGCode
,DRG.APRDRG_ROM  																				AS APRROM
,DRG.SEVERITY_OF_ILLNESS 																		AS APRSOI
,HSP.PRIM_SVC_HA_C  																			AS ClinicalServiceCode
,HSP.CASE_MIX_GRP_CODE 																			AS CMGCode
,HSP.ADM_PROV_ID 																				AS AdmitPhysicianCode
,HSP.ATTENDING_PROV_ID 																			AS AttendPhysicianCode
 /* MC ConsultPhysician for Future use - HSP_ABS_CNSLT_INFO (not extracted to Clarity at all) or OR_CONSULTED_PROV (also not extracted to clarity, surg only) */
,NULL																							AS ConsultPhysician1Code 
,NULL																							AS ConsultPhysician2Code 
,NULL																							AS ConsultPhysician3Code 
,NULL 																							AS ConsultPhysician4Code 
,NULL																							AS ConsultPhysician5Code 

,HSP_ACCT_PX_LIST.PROC_PERF_PROV_ID  															AS PrimaryPerformingPhysicianCode
,HSP.REFERRING_PROV_ID  																		AS ReferPhysicianCode
,PAT_ENC.PCP_PROV_ID			  																AS PrimaryCarePhysicianCode
,CASE WHEN HSP.ACCT_BASECLS_HA_C = 2 
				THEN COALESCE(convert(varchar(8),cast(HSP.DISCH_DATE_TIME as date),112), 
				convert(varchar(8),cast(HSP.ADM_DATE_TIME as date),112)) /* discharge date time isn't always stamped on outpatient accounts */
 				ELSE convert(varchar(8),cast(HSP.DISCH_DATE_TIME as date),112) END  			AS DischargeDate
,CASE WHEN HSP.ACCT_BASECLS_HA_C = 2 
				THEN COALESCE(convert(varchar(5),cast(HSP.DISCH_DATE_TIME as datetime),108) ,
				convert(varchar(5),cast(HSP.ADM_DATE_TIME as datetime),108) ) /* discharge date time isn't always stamped on outpatient accounts */
 				ELSE convert(varchar(5),cast(HSP.DISCH_DATE_TIME as datetime),108) END  		AS DischargeTime
,HSP.DISCH_DEPT_ID				 																AS DischargeDepartmentCode
,NULL																							AS DischargeNurseStationCode /* MC:  Not populating.  Paul indicated Future use.*/
,CASE WHEN HSP.ACCT_BASECLS_HA_C = 2 AND HSP.PATIENT_STATUS_C IS NULL THEN '01' /* routine discharge */
 		ELSE HSP.PATIENT_STATUS_C END  															AS DischargeStatusCode
,HSP.ACCT_BILLSTS_HA_C				  															AS BillStatusCode
,convert(varchar(8),cast(HSP.LAST_STMT_DATE as date),112)										AS FinalBillDate
,COALESCE(HSP.TOT_ACCT_BAL,0)  																	AS AccountBalance								
,null																							AS HistoricalExpectedPayment
,ACNT.ACCOUNT_TYPE_C																			AS AccountType
,convert(varchar(8),cast(BKT_HX.AGNCY_HST_DT_OF_CH as date),112)  								AS BadDebtDate
/* MC:  For some reason these are preprended with a '0' in Clarity. */
,substring(HSP.BILL_DRG_MDC_VAL,2,2)  															AS BilledMDC
,HSP.CODING_STATUS_C 																			AS CodingStatus
,Case when cast(HSP.PRIMARY_PLAN_ID as integer) > 9000000  then 99999 
	else  COALESCE(HSP.PRIMARY_PLAN_ID,-100) END												AS CurrentInsurancePlan
/* MC:  Not populating.  Paul indicated Future use. */
,NULL											 												AS FacilityTransferredFrom /* SOURCE_UWHEALTH.EPIC_HSP_ACCOUNT_3, JOIN TO ZC_FAC_TRANS_FROM (no data for this table in Clarity) */
/* MC:  Not populating.  Paul indicated Future use. */
,NULL									  														AS FacilityTransferredTo /* SOURCE_UWHEALTH.EPIC_HSP_ACCOUNT_3, JOIN TO ZC_FAC_TRANS_FROM (no data for this table in Clarity) */

/* MC:  Not populating.  Paul indicated Future use. */
,NULL										  													AS GuarantorRelationship /* SOURCE_UWHEALTH.EPIC_ACCOUNT.RQC_RELATIONSHIP_C; ZC_GUAR_REL_TO_PAT (not in Aginity) */
,DRG.MDC_CD										  												AS MSMDC
/* MC:  Not populating.  Paul indicated Future use. */
,NULL																							AS EMPI /* HSP_ACCT_MPI(?), needs to go to SOURCE_UWHEALTH.*/
/* MC:  Not populating.  Paul indicated Future use. */
,NULL																							AS SubscriberNumber /* SOURCE_UWHEALTH.EPIC_COVERAGE */
/* MC:  Not populating.  Paul indicated Future use. */
,NULL																							AS SubscriberEmployer /* SOURCE_UWHEALTH.EPIC_COVERAGE */
/* MC:  Not populating.  Paul indicated Future use. */
,NULL																							AS SubscriberRelationship /* SOURCE_UWHEALTH.EPIC_COVERAGE.RQG_REL_TO_SUB_C; ZC_MEM_REL_TO_SUB (not in SOURCE_UWHEALTH.) */
/* MC:  Not populating Insurance PLan Group Name and number.  Paul indicated Future use.  Setting max datatypes in the 2 month test version.  Change to Null in the final extract. */
,NULL																							AS InsurancePlan1GroupName /*SOURCE_UWHEALTH.EPIC_PLAN_GRP */
,NULL																							AS InsurancePlan1GroupNumber /*SOURCE_UWHEALTH.EPIC_COVERAGE */
,NULL 																							AS InsurancePlan2GroupName /*SOURCE_UWHEALTH.EPIC_PLAN_GRP */
,NULL																							AS InsurancePlan2GroupNumber /*SOURCE_UWHEALTH.EPIC_COVERAGE */
,NULL																							AS InsurancePlan3GroupName /*SOURCE_UWHEALTH.EPIC_PLAN_GRP */
,NULL																							AS InsurancePlan3GroupNumber /*SOURCE_UWHEALTH.EPIC_COVERAGE */
,NULL																							AS InsurancePlan4GroupName /*SOURCE_UWHEALTH.EPIC_PLAN_GRP */
,NULL 																							AS InsurancePlan4GroupNumber /*SOURCE_UWHEALTH.EPIC_COVERAGE */
,NULL																							AS InsurancePlan5GroupName /*SOURCE_UWHEALTH.EPIC_PLAN_GRP */
,NULL																							AS InsurancePlan5GroupNumber /*SOURCE_UWHEALTH.EPIC_COVERAGE */
,NULL																							AS AgeCohorts /*MC Needs source */
,'EPIC Hospital Billing'  																		AS SourceSystem
,null																							AS UDFAdvBoardServiceLine
,null																							AS UDFAdvBoardSubServiceLine
,null																							AS UDFAdBoardOPProcServiceShort
,null																							AS UDFUWHCLegacyServiceLine
,coalesce(CASE WHEN (POP_QTZMEM.QMM_COVERAGE_ID is not null 
                     and Payormap.contract in ('Quartz','Unity'))
	                 or Payormap.GL_PAYOR_ID_UWHC = '30' then 'Y' else 'N' END,null)        	AS UDFQuartzUWHealthRisk /* updated 9/8/21, updated to new business rule 1/14/2022 SM	AS UDF_Quartz_Region updated 9/8/21 SM */
,coalesce(CASE WHEN MED_HOME.MED_HOME_PATIENT_ID is not null then 'Y' else 'N' END,null) 		AS UDFUWHealthMedicalHome
,ISNULL(NGACO.NGACOIndicator,'N')																AS UDFNGACOIndicator /*MC:  Maintenance point as new years are added. SM added 2021 population 9/8/2021 */
,cast(Payormap.GL_PAYOR_ID_UWHC as VARCHAR(66)) 												AS UDF_GL_PAYOR_ID
,CASE WHEN HSP.ACCT_BASECLS_HA_C = 2 
	then Payormap.RISK_REV_HB_IP 
	else Payormap.RISK_REV_HB_OP END 															AS UDF_UW_PAYOR_RISK_SPECIFIC
,Payormap.RISK_REV_UWH  																		AS UDF_PAYOR_RISK_ARRANGEMENT
,null																							AS UDF_ACADEMIC_CLINICAL_DEPT
,null																							AS UDF_ACADEMIC_CLINICAL_SECTION
,null																							AS UDF_ACADEMIC_CLINICAL_SECTION_ID
,HSP.PRIM_ENC_CSN_ID																			AS UDF_PAT_ENC_CSN_ID
,null																							AS UDFSyntheticHARRule  
,null             						                                                    	AS UDF_ZIPCODE_MARKET_2000A /* *YW+1 8/26 set value; blanked for separate extract 1/14/22 SM */
,null   						                                                             	AS UDF_ZIPCODE_MARKET_2000B /* Added 6/28/21 SM; blanked for separate extract 1/14/22 SM */
,null   						                                                                AS UDF_ZIPCODE_REGION_2000 /* blanked for separate extract 1/14/22 SM */
,onchb.cancer_site_grp_1																		AS UDF_CANCER_SITE_GRP_1
,onchb.cancer_site_grp_2 																		AS UDF_CANCER_SITE_GRP_2
,txphb.EPISODE_NAME																				AS UDF_TRANSPLANT_EPISODE_NAME
,txphb.RECIPIENT_DONOR																			AS UDF_TRANSPLANT_RECIPIENT_DONOR
,txphb.ADULT_PEDS																				AS UDF_TRANSPLANT_ADULT_PEDS
,txphb.VA_PATIENT																				AS UDF_TRANSPLANT_VA_PATIENT
,txphb.ORGAN_TX_PROC_GROUP 																		AS UDF_TRANSPLANT_ORGAN_PROC_GROUP
,txphb.EPISODE_PHASE																			AS UDF_TRANSPLANT_EPISODE_PHASE
,pedshb.PEDS_CARE_TYPE																			AS UDF_PEDS_CARE_TYPE																
,null																							AS UDF_DHC_CATEGORY																	
,null																							AS UDF_WPW_DXGRP_DESC																
,null																							AS UDF_WPW_DXGRP_CODES																		
,null																							AS UDF_WPW_PROVGRP																	
,null																							AS UDF_WPW_UPM_FLG
,neurhb.NEURO_DX_GRP																			AS UDF_NEURO_DX /* completed COALESCE 9/27/21 */
,neurhb.NEURO_DX_SUBGRP																			AS UDF_NEURO_DX_SUBGRP
,neurhb.NEURO_PROC_GRP																			AS UDF_NEURO_PROC
,neurhb.NEURO_SPECIALTY_GRP																		AS UDF_NEURO_SPECIALTY /* completed COALESCE 9/27/21 SM */
,neurhb.NEURO_ADULT_PEDS																		AS UDF_NEURO_ADULT_PEDS /* completed COALESCE 9/27/21 SM */
,null																							AS UDF_ORTHO_SPECIALTY
/*
,ORTHHB.ORTHO_SPECIALTY_GRP																		AS UDF_ORTHO_SPECIALTY
*/
,null																							AS UDF_HBENC_MODELED_TYPE_CD
,DRG.MEDSURG_CD																					AS UDF_MEDSURG_CD
,cast(round(DRG.WGT_NBR,4) as NUMERIC(9,4))														AS UDF_UWH_MSDRG_WGT_NBR
,HSP.PAT_ID																						AS UDF_PATIENT_ID /*  Added 6/28/21 SM */
,GL.PRIN_GL_BUILDING_ID																			AS UDF_PRIN_GL_BLD_ID /*  Added 6/28/21 SM */
,OPENC.OP_ENC_TYPE																				AS UDF_OP_ENC_TYPE /*  Added 6/28/21 SM */
,OPENC.OR_CASES																					AS UDF_OR_CASES /* Added 6/28/21 Will not send to Strata SM */
,DRG.DRG_CLINICAL_GRP_NM																		AS UDF_MSDRG_CLIN_GRP/* added 9/8/21 SM */
,RANKED.UDF_TECHCHG_BUS_SEG_ATTR_PROV_ID /* added 9/8/21 SM		 */							
,null																							AS UDF_PATIENT_PAYMENTS /* added 9/8/21, negated 1/14/2022 SM */
,pop_qtzmem.QMM_CAP_BREAKDOWN																	AS UDF_Quartz_Cap_Breakdown /* updated 9/8/21 SM */
,pop_qtzmem.QMM_LOB_NAME																		AS UDF_Quartz_Line_Of_Business /* updated 9/8/21 SM */
,pop_qtzmem.QMM_LOB_BREAKDOWN																	AS UDF_Quartz_LOB_Breakdown /* updated 9/8/21 SM */
,pop_qtzmem.QMM_RISK_PANEL_NAME																	AS UDF_Quartz_Risk_Panel /* updated 9/8/21 SM */
,pop_qtzmem.QMM_REGION																			AS UDF_Quartz_Region /* updated 9/8/21 SM			 */																						
,null																							as UDF_HVT_DX_GRP_1 /* added 9/27/21 SM			 */											
,null																							as UDF_HVT_DX_GRP_2 /* added 9/27/21 SM		 */													
,null																							as UDF_HVT_PX_GRP_1 /* added 9/27/21 SM		 */														
,null																							as UDF_HVT_PX_GRP_2 /* added 9/27/21 SM */
,RANKED.UDF_CPT_PRIM_PERF_PHYSICIAN /* added 1/14/2022 SM */
,RANKED.UDF_PRIMARY_CPT_CODE /* added 1/14/2022, updated 5/25/2022 SM */
,RANKED.UDF_PRINCIPAL_SURGEON /* added 1/14/2022 SM */
,RANKED.UDF_PRIMARY_HCPCS_CODE /* added 1/14/2022 SM, updated 5/25/2022 SM */
,RANKED.UDF_PRIN_PROCEDURE																						
,RANKED.UDF_PRIN_PROCEDURE_TYPE
,hsp.serv_area_id																	AS udf_service_area_id
,HSP.AODA_FLG 	/* SM 2/16/2022 added to exclude AODA  */


FROM MART_LOAD_UWHEALTH.STRATA_ELEMENTS_HSP_ACCOUNT_T HSP  
LEFT JOIN MART_LOAD_UWHEALTH.STRATA_ELEMENTS_PAT_ENC_T PAT_ENC					ON HSP.PRIM_ENC_CSN_ID = PAT_ENC.PAT_ENC_CSN_ID
LEFT JOIN SOURCE_UWHEALTH.EPIC_HSP_ACCT_PAT_MRN_CUR MRN						    ON HSP.HSP_ACCOUNT_ID = MRN.HSP_ACCOUNT_ID
LEFT JOIN SOURCE_UWHEALTH.EPIC_PAT_ENC_HSP_CUR peh 							    ON peh.HSP_ACCOUNT_ID = HSP.HSP_ACCOUNT_ID
LEFT JOIN SOURCE_UWHEALTH.EPIC_HSP_ACCT_DX_LIST_CUR HSP_ACCT_DX_LIST		    ON HSP.HSP_ACCOUNT_ID = HSP_ACCT_DX_LIST.HSP_ACCOUNT_ID AND (HSP_ACCT_DX_LIST.LINE IS NULL OR HSP_ACCT_DX_LIST.LINE = 1) /* limit to primary coded diagnosis */
LEFT JOIN SOURCE_UWHEALTH.EPIC_HSP_ACCT_PX_LIST_CUR HSP_ACCT_PX_LIST		    ON HSP.HSP_ACCOUNT_ID = HSP_ACCT_PX_LIST.HSP_ACCOUNT_ID AND (HSP_ACCT_PX_LIST.LINE IS NULL OR HSP_ACCT_PX_LIST.LINE = 1) /* limit to primary coded procedure */
LEFT JOIN SOURCE_UWHEALTH.EPIC_ACCOUNT_CUR ACNT 								ON HSP.GUARANTOR_ID = ACNT.ACCOUNT_ID
LEFT JOIN SOURCE_UWHEALTH.EPIC_ZC_ACCOUNT_TYPE_CUR ACNTTYPE 					ON ACNTTYPE.ACCOUNT_TYPE_C = ACNT.ACCOUNT_TYPE_C
LEFT JOIN SOURCE_UWHEALTH.EPIC_CLARITY_LOC_CUR LOC   							ON HSP.LOC_ID = LOC.LOC_ID
LEFT JOIN SOURCE_UWHEALTH.EPIC_CLARITY_DEP_CUR DEP   							ON HSP.DISCH_DEPT_ID = DEP.DEPARTMENT_ID
left join [Source_UWHealth].[UDD_EA_EPPFM_OCS_NIL_HL_DEPT_MAP] map				ON map.[HL_PRIM_DEPARTMENT_ID] = HSP.DISCH_DEPT_ID
LEFT JOIN SOURCE_UWHEALTH.EPIC_PATIENT_CUR P   								    ON HSP.PAT_ID = P.PAT_ID
LEFT JOIN SOURCE_UWHEALTH.EPIC_HSP_ACCT_ADMIT_DX_CUR HSP_ACCT_ADMIT_DX		    ON HSP.HSP_ACCOUNT_ID = HSP_ACCT_ADMIT_DX.HSP_ACCOUNT_ID and (HSP_ACCT_ADMIT_DX.LINE IS NULL OR HSP_ACCT_ADMIT_DX.LINE = 1)
LEFT JOIN SOURCE_UWHEALTH.EPIC_ACCT_GUAR_PAT_INFO_CUR ACCT_PAT_INFO 			ON HSP.GUARANTOR_ID = ACCT_PAT_INFO.ACCOUNT_ID AND HSP.PAT_ID = ACCT_PAT_INFO.PAT_ID /* and ACCT_PAT_INFO.Active_flg='Y' */
LEFT JOIN SOURCE_UWHEALTH.EPIC_CLARITY_EDG_CUR CLARITY_EDG					    ON HSP_ACCT_ADMIT_DX.ADMIT_DX_ID = CLARITY_EDG.DX_ID
LEFT JOIN SOURCE_UWHEALTH.EPIC_PAT_ENC_HSP_CUR PAT_ENC_HSP					    ON HSP.PRIM_ENC_CSN_ID = PAT_ENC_HSP.PAT_ENC_CSN_ID 
LEFT JOIN SOURCE_UWHEALTH.EPIC_CLARITY_ADT_CUR CLARITY_ADT					    ON hsp.PRIM_ENC_CSN_ID = CLARITY_ADT.PAT_ENC_CSN_ID and EVENT_TYPE_C = 1 AND CLARITY_ADT.EVENT_SUBTYPE_C <> 2 /* CANCELED */
LEFT JOIN SOURCE_UWHEALTH.EPIC_CLARITY_EDG_CUR EDG 							    ON HSP_ACCT_DX_LIST.DX_ID = EDG.DX_ID
LEFT JOIN SOURCE_UWHEALTH.EPIC_CL_ICD_PX_CUR CL_ICD_PX						    ON HSP_ACCT_PX_LIST.FINAL_ICD_PX_ID = CL_ICD_PX.ICD_PX_ID
LEFT JOIN MART_LOAD_UWHEALTH.EA_ACCOUNT_SBO_COVERAGE_T UWH_INS 			        ON HSP.HSP_ACCOUNT_ID = UWH_INS.HSP_ACCOUNT_ID /*   UW Bucket based plan assignment; updating to new datamart object 6/28 SM */
LEFT JOIN MART_UWHEALTH.GROUPER_BENEFIT_PLAN PAYORMAP 				            ON UWH_INS.INS_PLAN_1= PAYORMAP.BENEFIT_PLAN_ID
LEFT JOIN SOURCE_UWHEALTH.EPIC_PATIENT_RACE_CUR RACE 							ON P.PAT_ID = RACE.PAT_ID AND RACE.LINE = 1
left join SOURCE_UWHEALTH.EPIC_PATIENT_CUR P_ADMIT_DT 						    ON HSP.PAT_ID = P_ADMIT_DT.PAT_ID
LEFT JOIN SOURCE_UWHEALTH.EPIC_ZC_STATE_CUR  ZC_STATE							ON HSP.PAT_STATE_C = ZC_STATE.STATE_C
LEFT JOIN SOURCE_UWHEALTH.EPIC_ZC_COUNTY_CUR ZC_COUNTY						    ON HSP.PAT_COUNTY_C = ZC_COUNTY.INTERNAL_ID
LEFT JOIN SOURCE_UWHEALTH.EPIC_ZC_ACCT_BILLSTS_HA_CUR ZC_BILLSTS 				ON HSP.ACCT_BILLSTS_HA_C = ZC_BILLSTS.ACCT_BILLSTS_HA_C
LEFT JOIN SOURCE_UWHEALTH.EPIC_ZC_SEX_CUR ZC_SEX								ON P.SEX_C = ZC_SEX.RCPT_MEM_SEX_C
LEFT JOIN adhoc_uwhealth.EA_ACCOUNT_OP_ENC_TYPE OPENC 				        ON HSP.HSP_ACCOUNT_ID = OPENC.HSP_ACCOUNT_ID /* OP enc type and OR case count SM 8/3/2022 */
LEFT JOIN adhoc_uwhealth.EA_ACCOUNT_PRIN_GL_BUILDING GL					    ON GL.HSP_ACCOUNT_ID = HSP.HSP_ACCOUNT_ID  /* principal GL building ID SAM 8/3/2022 */
LEFT JOIN MART_LOAD_UWHEALTH.STRATA_BRIDGE_NGACO_INDICATOR_T NGACO				ON HSP.HSP_ACCOUNT_ID = NGACO.ENCOUNTERRECORDNUMBER   /* NGACO populations */
/* MSDRG, MDC, APRDRG, SOI, ROM,  MEDSURG_CD and MSDRG Cost Weight for MCC Dashboard (1/20/21) */
LEFT JOIN MART_LOAD_UWHEALTH.STRATA_BRIDGE_HBDRG_T DRG 							ON HSP.HSP_ACCOUNT_ID = DRG.HOSPITAL_ACCOUNT_ID
LEFT JOIN MART_LOAD_UWHEALTH.STRATA_BRIDGE_QUARTZ_MEMBER_MONTH_T POP_QTZMEM		ON HSP.HSP_ACCOUNT_ID = POP_QTZMEM.ENCOUNTERRECORDNUMBER
LEFT JOIN MART_LOAD_UWHEALTH.STRATA_BRIDGE_MEDHOMED_PATIENTS_T MED_HOME			ON HSP.HSP_ACCOUNT_ID = MED_HOME.ENCOUNTERRECORDNUMBER
LEFT JOIN MART_LOAD_UWHEALTH.STRATA_BRIDGE_BADDEBT_T BKT_HX						ON HSP.HSP_ACCOUNT_ID = BKT_HX.HSP_ACCOUNT_ID
LEFT JOIN MART_LOAD_UWHEALTH.STRATA_BRIDGE_RANKED_PROCS_PROVS_T RANKED			ON HSP.HSP_ACCOUNT_ID = RANKED.HSP_ACCOUNT_ID

/* Joins to population engine populations */
left join MART_UWHEALTH.population_oncology_hb onchb							on HSP.HSP_ACCOUNT_ID = onchb.HOSPITAL_ACCOUNT_ID
left join MART_UWHEALTH.population_transplant_hb txphb							on HSP.HSP_ACCOUNT_ID = txphb.HOSPITAL_ACCOUNT_ID
left join MART_UWHEALTH.population_peds_hb pedshb								on HSP.HSP_ACCOUNT_ID = pedshb.HOSPITAL_ACCOUNT_ID
left join MART_UWHEALTH.POPULATION_NEUROSCIENCES_HB neurhb						on HSP.HSP_ACCOUNT_ID = neurhb.HSP_ACCOUNT_ID
/*
left join MART_UWHEALTH.population_ortho_hb orthhb								on HSP.HSP_ACCOUNT_ID = orthhb.HOSPITAL_ACCOUNT_ID
*/



WHERE  hsp.ACCT_CLASS_HA_C <> '24' /* Account class 24 identifes WDI accounts */
   and (HSP.X_SBO_HAR_TYPE_C is null or HSP.X_SBO_HAR_TYPE_C =0) /* This filter elimiates PB HARs from the extract. */

   
UNION ALL

/* SAGE: Non-Chargeable Ambulatory Activity Psuedo-HARs based on encounters */

SELECT
cast(concat(33333,patenc.PAT_ENC_CSN_ID) as numeric(36,0))										AS EncounterRecordNumber /* required: SAGE + CSN */
,pat.PAT_MRN_ID																					AS MedicalRecordNumber /* required */
,LOC.LOC_ID			 																			AS LocationCode /* required: grab from pat_enc CSN */
,COALESCE(qcm.COMPANY,'211')					 												AS EntityCode /* required: either hard code as 211/310 if only UWHC/MF or grab from source table */
,'5'																							AS PatientTypeCode /* required */
,pat.PAT_FIRST_NAME				  																AS FirstName /* required */
,pat.PAT_LAST_NAME																				AS LastName /* required */
,pat.PAT_MIDDLE_NAME																			AS MiddleName /* required */
,pat.SEX																						AS GenderCode /* required */
,convert(varchar(8),cast(pat.BIRTH_DATE as date),112)											AS DateOfBirth /* required */
,patrace.PATIENT_RACE_C																			AS RaceCode /* required */
,pat.MARITAL_STATUS_C																			AS MaritalStatusCode /* required */
,Substring(p_addr.ZIP_HX,1,5) 																	AS ZipCode
,TRIM(CONCAT(COALESCE(replace(p_addr.ADDR_HX_LINE1,'|',''),''),' ',COALESCE(replace(p_addr.ADDR_HX_LINE2,'|',''),''),'')) AS StreetAddress/* combineline1and2ofaddress and removing pipes */
,p_addr.CITY_HX 																				AS City /* required */
,zc_state_hx.ABBR	 																			AS State /* required */
,zc_county_hx.[NAME]																			AS County /* required */
,NULL																							AS EmployerCode
,NULL																							AS GuarantorCode
,NULL																							AS GuarantorEmployerCode
,SAGEINS.SAGE_INSURANCEPLAN1CODE																AS InsurancePlan1Code
,NULL																							AS InsurancePlan2Code /* recommended. see if yuhong has logic to create this. */
,NULL																							AS InsurancePlan3Code /* recommended. see if yuhong has logic to create this. */
,NULL																							AS InsurancePlan4Code /* recommended. see if yuhong has logic to create this. */
,NULL																							AS InsurancePlan5Code /* recommended. see if yuhong has logic to create this. */
,NULL																							AS PatientMotherERN
,NULL																							AS NewbornFlag
,convert(varchar(8),cast(patenc.EFFECTIVE_DATE_DT as date),112)									AS AdmitDate /* required as the date of the costed event. encounter data for non-charge amb. */
,NULL																							AS AdmitTime /* time of costed event. not required for non-charge amb. */
,NULL																							AS IPAdmitDate
,NULL  																							AS AdmitTypeCode
,NULL																							AS AdmitSourceCode
,NULL																							AS AdmitDepartmentCode
,NULL																							AS AdmitNurseStationCode
,NULL																							AS MethodofArrivalCode
,NULL																							AS AdmitICD10DXCode
,icd10.CODE																  						AS PrimaryICD10DXCode /* required if feasible CAN THIS BE DONE? */
,NULL																							AS PrimaryICD10PXCode /* required if feasible. won't apply to non-charge amb encounters */
,NULL						 																	AS MSDRGCode
,NULL																							AS APRDRGSchema
,NULL								 															AS APRDRGCode
,NULL							 																AS APRROM
,NULL							 																AS APRSOI
,NULL								 															AS ClinicalServiceCode /* recommended */
,NULL									  														AS CMGCode
,NULL						  																	AS AdmitPhysicianCode
,patenc.ATTND_PROV_ID		  																	AS AttendPhysicianCode /* required */
,NULL																							AS ConsultPhysician1Code
,NULL																							AS ConsultPhysician2Code
,NULL																							AS ConsultPhysician3Code
,NULL																							AS ConsultPhysician4Code
,NULL																							AS ConsultPhysician5Code
,patenc.VISIT_PROV_ID																			AS PrimaryPerformingPhysicianCode /* required but evaluate for feasibility. won't apply for non-charge amb encounters */
,NULL  																							AS ReferPhysicianCode
,patenc.PCP_PROV_ID																				AS PrimaryCarePhysicianCode /* recommended, grab at time of encounter */
,convert(varchar(8),cast(patenc.EFFECTIVE_DATE_DT as date),112)									AS DischargeDate
,NULL  																							AS DischargeTime
,cast(patenc.DEPARTMENT_ID as numeric(18,0))													AS DischargeDepartmentCode
,NULL																							AS DischargeNurseStationCode
,NULL																							AS DischargeStatusCode
,NULL																							AS BillStatusCode
,NULL																							AS FinalBillDate
,0																								AS AccountBalance
,NULL																							AS HistoricalExpectedPayment /* added SAGE est reimb 5/13/2021  ,hbrevmod.EST_REIMB	  */
,NULL																							AS AccountType
,NULL																							AS BadDebtDate
,NULL 																							AS BilledMDC
,NULL 																							AS CodingStatus
,NULL																							AS CurrentInsurancePlan
,NULL										 													AS FacilityTransferredFrom
,NULL									  														AS FacilityTransferredTo
,NULL										  													AS GuarantorRelationship
,NULL  																							AS MSMDC
,NULL																							AS EMPI
,NULL																							AS SubscriberNumber
,NULL																							AS SubscriberEmployer
,NULL																							AS SubscriberRelationship
,NULL																							AS InsurancePlan1GroupName
,NULL																							AS InsurancePlan1GroupNumber
,NULL																							AS InsurancePlan2GroupName
,NULL																							AS InsurancePlan2GroupNumber
,NULL																							AS InsurancePlan3GroupName
,NULL																							AS InsurancePlan3GroupNumber
,NULL																							AS InsurancePlan4GroupName
,NULL																							AS InsurancePlan4GroupNumber
,NULL																							AS InsurancePlan5GroupName
,NULL																							AS InsurancePlan5GroupNumber
,NULL																							AS AgeCohorts /* recommended */
,'SAGE'				 																			AS SourceSystem /* hard code as SAGE */
,NULL																							AS UDFAdvBoardServiceLine
,NULL																							AS UDFAdvBoardSubServiceLine
,NULL																							AS UDFAdBoardOutpatientProcServiceShort
,NULL																							AS UDFUWHCLegacyServiceLine


/*   is this ok to not join to payormap twice    */
,COALESCE(CASE WHEN (POP_QTZMEM.QMM_COVERAGE_ID is not null and payormap.CONTRACT in ('Quartz','Unity'))
	  or (Payormap.GL_PAYOR_ID_UWHC = '30' or Payormap.GL_PAYOR_ID_UWMF = '30')
	      then 'Y' else 'N' END, null)      													AS UDFQuartzUWHealthRisk /* updated 9/8/21, updated to new business rule 1/14/2022 SM	 */
	



,coalesce(CASE WHEN MED_HOME.MED_HOME_PATIENT_ID is not null then 'Y' else 'N' END, null)		AS UDFUWHealthMedicalHome /* required, join population table to patient */
,ISNULL(NGACO.NGACOIndicator,'N')																AS UDFNGACOIndicator /* required, join population table to patient */
,SAGEINS.SAGE_GL_PAYOR_ID																		AS UDF_GL_PAYOR_ID
,SAGEINS.SAGE_UW_PAYOR_RISK_SPECIFIC															AS UDF_UW_PAYOR_RISK_SPECIFIC /* updated 5/20/21 */
,SAGEINS.SAGE_PAYOR_RISK_ARRANGEMENT			  												AS UDF_PAYOR_RISK_ARRANGEMENT /* updated 5/20/21 */
,ZC6.[NAME]																						AS UDF_ACADEMIC_CLINICAL_DEPT
,zc8.[NAME]																						AS UDF_ACADEMIC_CLINICAL_SECTION
,zc8.rpt_grp_eight																				AS UDF_ACADEMIC_CLINICAL_SECTION_ID
,patenc.PAT_ENC_CSN_ID																			AS UDF_PAT_ENC_CSN_ID /* required */
,'3'																							AS UDFSyntheticHARRule /* required */
,null              						                                                    	AS UDF_ZIPCODE_MARKET_2000A /* *YW+1 8/26 set value; blanked for separate extract 1/14/22 SM */
,null     						                                                             	AS UDF_ZIPCODE_MARKET_2000B /* Added 6/28/21 SM; blanked for separate extract 1/14/22 SM */
,null    						                                                                AS UDF_ZIPCODE_REGION_2000 /* blanked for separate extract 1/14/22 SM */
/*
,oncenc.cancer_site_grp_1 																		AS UDF_CANCER_SITE_GRP_1
,oncenc.cancer_site_grp_2																		AS UDF_CANCER_SITE_GRP_2
*/
,null                                                                                           AS UDF_CANCER_SITE_GRP_1
,null                                                                                           AS UDF_CANCER_SITE_GRP_2
,txpenc.EPISODE_NAME																			AS UDF_TRANSPLANT_EPISODE_NAME
,txpenc.RECIPIENT_DONOR 																		AS UDF_TRANSPLANT_RECIPIENT_DONOR
,txpenc.ADULT_PEDS																				AS UDF_TRANSPLANT_ADULT_PEDS
,txpenc.VA_PATIENT																				AS UDF_TRANSPLANT_VA_PATIENT
,txpenc.ORGAN_TX_PROC_GROUP																		AS UDF_TRANSPLANT_ORGAN_PROC_GROUP
,txpenc.EPISODE_PHASE																			AS UDF_TRANSPLANT_EPISODE_PHASE
,pedsenc.PEDS_CARE_TYPE																			AS UDF_PEDS_CARE_TYPE																
,null																							AS UDF_DHC_CATEGORY																
,null																							AS UDF_WPW_DXGRP_DESC																	
,null																							AS UDF_WPW_DXGRP_CODES																	
,null																							AS UDF_WPW_PROVGRP																
,null																							AS UDF_WPW_UPM_FLG
,neurenc.NEURO_DX_GRP																			AS UDF_NEURO_DX /* added neuro fields 5/13/2021; completed COALESCE 9/27/21 */
,neurenc.NEURO_DX_SUBGRP																		AS UDF_NEURO_DX_SUBGRP /* added neuro fields 5/13/2021; completed COALESCE 9/27/21 */
,neurenc.NEURO_PROC_GRP																			AS UDF_NEURO_PROC /* added neuro fields 5/13/2021; completed COALESCE 9/27/21 */
,neurenc.NEURO_SPECIALTY_GRP																	AS UDF_NEURO_SPECIALTY /* added neuro fields 5/13/2021; completed COALESCE 9/27/21 */
,neurenc.NEURO_ADULT_PEDS																		AS UDF_NEURO_ADULT_PEDS /* added neuro fields 5/13/2021; completed COALESCE 9/27/21 */
,ORTHENC.ORTHO_SPECIALTY_GRP 																	AS UDF_ORTHO_SPECIALTY /* added ortho field 5/13/2021, */
,null																							AS UDF_HBENC_MODELED_TYPE_CD /* added SAGE est reimb info 5/13/2021 */
,null																							AS UDF_MEDSURG_CD
,null																							AS UDF_UWH_MSDRG_WGT_NBR
,PATENC.PAT_ID																					AS UDF_PATIENT_ID /*  Added 6/28/21 SM */
,DEP.RPT_GRP_TWENTYFOUR																			AS UDF_PRIN_GL_BLD_ID /*  Added 6/28/21 SM */
,'SAGE'																							AS UDF_OP_ENC_TYPE /*  Added 6/28/21, hard coded to SAGE 1/14/2022 SM */
,0																								AS UDF_OR_CASES /* Added 6/28/21 Will not send to Strata SM */
,null																							AS UDF_MSDRG_CLIN_GRP /* added 9/8/21 SM */
,case 
	when Substring(patenc.visit_prov_id,1,1) in ('1','3')
		and ser.RPT_GRP_SIX <> '77' and ser.PRACTICE_NAME_C <> '2307'							/* exclude Northern Illinois and Agrace SAM 10/25/2022 */
		then patenc.visit_prov_id 																
	else null end 																				AS UDF_TECHCHG_BUS_SEG_ATTR_PROV_ID /* added 9/8/21 SM */
,0																								AS UDF_PATIENT_PAYMENTS /* added 9/8/21 SM */
,pop_qtzmem.QMM_CAP_BREAKDOWN																	AS UDF_Quartz_Cap_Breakdown /* updated 9/8/21 SM */
,pop_qtzmem.QMM_LOB_NAME																		AS UDF_Quartz_Line_Of_Business /* updated 9/8/21 SM */
,pop_qtzmem.QMM_LOB_BREAKDOWN																	AS UDF_Quartz_LOB_Breakdown /* updated 9/8/21 SM */
,pop_qtzmem.QMM_RISK_PANEL_NAME																	AS UDF_Quartz_Risk_Panel /* updated 9/8/21 SM */
,pop_qtzmem.QMM_REGION																			AS UDF_Quartz_Region /* updated 9/8/21 SM				 */			
,null																							as UDF_HVT_DX_GRP_1 /* added 9/27/21 SM ,hvtenc.DIAGNOSIS_GROUP_1		 */				
,null																							as UDF_HVT_DX_GRP_2 /* added 9/27/21 SM ,hvtenc.DIAGNOSIS_GROUP_2		 */			
,null																							as UDF_HVT_PX_GRP_1 /* added 9/27/21 SM ,hvtenc.PROCEDURE_GROUP_1		 */					
,null																							as UDF_HVT_PX_GRP_2 /* added 9/27/21 SM ,hvtenc.PROCEDURE_GROUP_2 	 */
,null																							AS UDF_CPT_PRIM_PERF_PHYSICIAN /* added 1/14/2022 SM */
,null																							AS UDF_PRIMARY_CPT_CODE /* added 1/14/2022 SM */
,null																							AS UDF_PRINCIPAL_SURGEON /* added 1/14/2022 SM */
,null																							AS UDF_PRIMARY_HCPCS_CODE /* added 1/14/2022 SM */
,null																							AS UDF_PRIN_PROCEDURE /* added 1/14/2022 SM			 */															
,null																							AS UDF_PRIN_PROCEDURE_TYPE /* added 1/14/2022 SM */ 
,incl.udf_service_area_id																	AS udf_service_area_id
,patenc.AODA_FLG														 						AS AODA_FLG 	/* SM 2/16/2022 added to exclude AODA  */


from   MART_LOAD_UWHEALTH.STRATA_ELEMENTS_PAT_ENC_T patenc
JOIN MART_LOAD_UWHEALTH.STRATA_GLOBAL_INCLUSIONS_HX incl on cast(concat(33333,patenc.PAT_ENC_CSN_ID) as numeric(36,0)) = incl.ENCOUNTERRECORDNUMBER and incl.ACTIVE_FLG = 'Y'
LEFT JOIN SOURCE_UWHEALTH.EPIC_PATIENT_CUR pat									ON patenc.PAT_ID = pat.PAT_ID
LEFT JOIN SOURCE_UWHEALTH.EPIC_CLARITY_DEP_CUR dep								ON patenc.DEPARTMENT_ID = dep.DEPARTMENT_ID
LEFT JOIN SOURCE_UWHEALTH.EPIC_CLARITY_LOC_CUR LOC   							ON PATENC.PRIMARY_LOC_ID = LOC.LOC_ID
LEFT JOIN SOURCE_UWHEALTH.EPIC_PATIENT_RACE_CUR patrace							ON patenc.PAT_ID = patrace.PAT_ID and (patrace.LINE is null or patrace.LINE=1)
LEFT JOIN SOURCE_UWHEALTH.EPIC_CLARITY_SER_CUR SER								ON patenc.VISIT_PROV_ID = SER.PROV_ID and Substring(patenc.visit_prov_id,1,1) in ('1','3')
LEFT JOIN SOURCE_UWHEALTH.EPIC_ZC_SER_RPT_GRP_6_CUR ZC6							ON SER.RPT_GRP_SIX = ZC6.RPT_GRP_SIX
LEFT JOIN SOURCE_UWHEALTH.EPIC_ZC_SER_RPT_GRP_8_CUR ZC8							ON SER.RPT_GRP_EIGHT = ZC8.RPT_GRP_EIGHT
LEFT JOIN SOURCE_UWHEALTH.EA_V_UWH_AMB_CLINIC_MAPPING_CUR qcm					ON patenc.DEPARTMENT_ID = qcm.DEPARTMENT_ID
LEFT JOIN SOURCE_UWHEALTH.EPIC_PAT_ADDR_CHNG_HX_CUR p_addr						ON pat.PAT_ID=p_addr.PAT_ID and patenc.EFFECTIVE_DATE_DT >= p_addr.EFF_Start_DATE and patenc.EFFECTIVE_DATE_DT < COALESCE(p_addr.EFF_END_DATE,'12/31/2200')  /*  cannot use BETWEEN because of overlapping datetimes in PAT_ADDR_CHNG_HX */
LEFT JOIN SOURCE_UWHEALTH.EPIC_ZC_STATE_CUR zc_state_hx							ON p_addr.STATE_HX_C = zc_state_hx.STATE_C
LEFT JOIN SOURCE_UWHEALTH.EPIC_ZC_COUNTY_CUR zc_county_hx						ON p_addr.COUNTY_HX_C = zc_county_hx.INTERNAL_ID
LEFT JOIN SOURCE_UWHEALTH.EPIC_PAT_ENC_DX_CUR encdx								ON patenc.PAT_ENC_CSN_ID = encdx.PAT_ENC_CSN_ID and encdx.PRIMARY_DX_YN='Y'
LEFT JOIN SOURCE_UWHEALTH.EPIC_EDG_CURRENT_ICD10_CUR icd10						ON encdx.DX_ID = icd10.DX_ID and icd10.LINE=1 /*  unsure if line 1 is most appropriate...some DX_IDs have multiple ICD10 codes associated. */
LEFT JOIN MART_LOAD_UWHEALTH.STRATA_BRIDGE_NGACO_INDICATOR_T NGACO				ON cast(concat(33333,patenc.PAT_ENC_CSN_ID) as numeric(36,0)) = NGACO.ENCOUNTERRECORDNUMBER   /* NGACO populations */
LEFT JOIN MART_LOAD_UWHEALTH.STRATA_BRIDGE_QUARTZ_MEMBER_MONTH_T POP_QTZMEM		ON cast(concat(33333,patenc.PAT_ENC_CSN_ID) as numeric(36,0)) = POP_QTZMEM.ENCOUNTERRECORDNUMBER
LEFT JOIN MART_LOAD_UWHEALTH.STRATA_BRIDGE_MEDHOMED_PATIENTS_T MED_HOME			ON cast(concat(33333,patenc.PAT_ENC_CSN_ID) as numeric(36,0)) = MED_HOME.ENCOUNTERRECORDNUMBER
LEFT JOIN MART_LOAD_UWHEALTH.STRATA_BRIDGE_SAGE_INSPLAN_T SAGEINS				ON cast(concat(33333,patenc.PAT_ENC_CSN_ID) as numeric(36,0)) = SAGEINS.ENCOUNTERRECORDNUMBER
left join MART_UWHEALTH.GROUPER_BENEFIT_PLAN Payormap 							ON SAGEINS.SAGE_INSURANCEPLAN1CODE = payormap.benefit_plan_id

/*left join MART_UWHEALTH.population_oncology_enc oncenc on patenc.PAT_ENC_CSN_ID = oncenc.CSN_ID*/
left join MART_UWHEALTH.population_transplant_enc txpenc on patenc.PAT_ENC_CSN_ID = txpenc.CSN_ID
left join MART_UWHEALTH.population_peds_enc pedsenc on patenc.PAT_ENC_CSN_ID = pedsenc.CSN_ID
left join MART_UWHEALTH.population_neurosciences_enc neurenc on patenc.PAT_ENC_CSN_ID = neurenc.PAT_ENC_CSN_ID /* added neuro fields 5/13/2021 */
left join MART_UWHEALTH.population_ortho_enc ORTHENC on patenc.PAT_ENC_CSN_ID = ORTHENC.CSN_ID /* added ortho field 5/13/2021	 */


where qcm.BUDGET_FLAG = 'Yes'



union all



/* SAGE Type 2's: Retail Pharmacy Dummy Records for FY20-21. FY18-19 to be backloaded manually. Eventually this will phase out in favor of patient-level dummy HARs per Julie Byrnes. */

select 
cast(a.EncounterRecordNumber as numeric(36,0))													AS EncounterRecordNumber/* required */
,'2'																							AS MedicalRecordNumber /* required, adding to comply with Strata CSF requirements 6/28 SAM */
,null																							AS LocationCode /* required: grab from pat_enc CSN */
,cast(EntityCode as VARCHAR(3))																	AS EntityCode
,'RTLRX'																						AS PatientTypeCode /* required, hard coded 9/14/2022 */
,'RETAIL'								  														AS FirstName /* required */
,'PHARMACY'																						AS LastName /* required */
,null																							AS MiddleName /* required */
,null																							AS GenderCode /* required */
,null																							AS DateOfBirth /* required */
,null																							AS RaceCode /* required */
,null																							AS MaritalStatusCode /* required */
,null																							AS ZipCode /* required. MC: assume that Numeric Zips are US Post Codes and just send the first 5.  */
,null																							AS StreetAddress /* recommended. combine line 1 and 2 of address. */
,null																							AS City /* required */
,null																							AS State /* required */
,null																							AS County /* required */
,null																							AS EmployerCode
,null																							AS GuarantorCode
,null																							AS GuarantorEmployerCode
,99																								AS InsurancePlan1Code /* required */
,null																							AS InsurancePlan2Code /* recommended. see if yuhong has logic to create this. */
,null																							AS InsurancePlan3Code /* recommended. see if yuhong has logic to create this. */
,null																							AS InsurancePlan4Code /* recommended. see if yuhong has logic to create this. */
,null																							AS InsurancePlan5Code /* recommended. see if yuhong has logic to create this. */
,null																							AS PatientMotherERN
,null																							AS NewbornFlag
,date																							AS AdmitDate /* required as the date of the costed event. encounter data for non-charge amb. */
,null																							AS AdmitTime /* time of costed event. not required for non-charge amb. */
,null																							AS IPAdmitDate
,null  																							AS AdmitTypeCode
,null																							AS AdmitSourceCode
,null																							AS AdmitDepartmentCode
,null																							AS AdmitNurseStationCode
,null																							AS MethodofArrivalCode
,null																							AS AdmitICD10DXCode
,null																				  			AS PrimaryICD10DXCode /* required if feasible CAN THIS BE DONE? */
,null																							AS PrimaryICD10PXCode /* required if feasible. won't apply to non-charge amb encounters */
,null						 																	AS MSDRGCode
,null																							AS APRDRGSchema
,null								 															AS APRDRGCode
,null												 											AS APRROM
,null												 											AS APRSOI
,null								 															AS ClinicalServiceCode /* recommended */
,null									  														AS CMGCode
,null							  																AS AdmitPhysicianCode
,null									  														AS AttendPhysicianCode /* required */
,null																							AS ConsultPhysician1Code
,null																							AS ConsultPhysician2Code
,null																							AS ConsultPhysician3Code
,null																							AS ConsultPhysician4Code
,null																							AS ConsultPhysician5Code
,null																							AS PrimaryPerformingPhysicianCode /* required but evaluate for feasibility. won't apply for non-charge amb encounters */
,null 																							AS ReferPhysicianCode
,null																							AS PrimaryCarePhysicianCode /* recommended, grab at time of encounter */
,date																							AS DischargeDate
,null  																							AS DischargeTime
,null																							AS DischargeDepartmentCode
,null																							AS DischargeNurseStationCode
,null																							AS DischargeStatusCode
,null																							AS BillStatusCode
,null																							AS FinalBillDate
,0																								AS AccountBalance
,HistoricalExpectedPayment
,null																							AS AccountType
,null																							AS BadDebtDate
,null																							AS BilledMDC
,null					 																		AS CodingStatus
,null																							AS CurrentInsurancePlan
,null											 												AS FacilityTransferredFrom
,null									  														AS FacilityTransferredTo
,null										  													AS GuarantorRelationship
,null 																							AS MSMDC
,null																							AS EMPI
,null																							AS SubscriberNumber
,null																							AS SubscriberEmployer
,null																							AS SubscriberRelationship
,null																							AS InsurancePlan1GroupName
,null																							AS InsurancePlan1GroupNumber
,null																							AS InsurancePlan2GroupName
,null																							AS InsurancePlan2GroupNumber
,null																							AS InsurancePlan3GroupName
,null																							AS InsurancePlan3GroupNumber
,null																							AS InsurancePlan4GroupName
,null																							AS InsurancePlan4GroupNumber
,null																							AS InsurancePlan5GroupName
,null																							AS InsurancePlan5GroupNumber
,null																							AS AgeCohorts /* recommended */
,'RetailRx'				 																		AS SourceSystem /* updated 9/8/2021 Sean Meirose */
,null																							AS UDFAdvBoardServiceLine
,null																							AS UDFAdvBoardSubServiceLine
,null																							AS UDFAdBoardOutpatientProcServiceShort
,null																							AS UDFUWHCLegacyServiceLine
,null    																						AS UDFQuartzUWHealthRisk /* required, join population table to patient */
,null																							AS UDFUWHealthMedicalHome /* required, join population table to patient */
,null																							AS UDFNGACOIndicator /* required, join population table to patient */
,99 																							AS UDF_GL_PAYOR_ID /* required - derive from insuranceplan1code */
,null																							AS UDF_UW_PAYOR_RISK_SPECIFIC /* required - derive from insuranceplan1code. only using OP for amb encounters. */
,null																							AS UDF_PAYOR_RISK_ARRANGEMENT /* required - derive from insuranceplan1code */
,null																							AS UDF_ACADEMIC_CLINICAL_DEPT
,null																							AS UDF_ACADEMIC_CLINICAL_SECTION
,null																							AS UDF_ACADEMIC_CLINICAL_SECTION_ID
,null																							AS UDF_PAT_ENC_CSN_ID
,'2'																							AS UDFSyntheticHARRule
,null    							                                                            AS UDF_ZIPCODE_MARKET_2000A
,null   							                                                            AS UDF_ZIPCODE_MARKET_2000B
,null                                   								                        AS UDF_ZIPCODE_REGION_2000
,null																							AS UDF_CANCER_SITE_GRP_1
,null 																							AS UDF_CANCER_SITE_GRP_2
,null																							AS UDF_TRANSPLANT_EPISODE_NAME
,null																							AS UDF_TRANSPLANT_RECIPIENT_DONOR
,null																							AS UDF_TRANSPLANT_ADULT_PEDS
,null																							AS UDF_TRANSPLANT_VA_PATIENT
,null																							AS UDF_TRANSPLANT_ORGAN_PROC_GROUP
,null																							AS UDF_TRANSPLANT_EPISODE_PHASE
,null																							AS UDF_PEDS_CARE_TYPE
,null																							AS UDF_DHC_CATEGORY
,null																							AS UDF_WPW_DXGRP_DESC
,null																							AS UDF_WPW_DXGRP_CODES
,null																							AS UDF_WPW_PROVGRP
,null																							AS UDF_WPW_UPM_FLG
,null																							AS UDF_NEURO_DX
,null																							AS UDF_NEURO_DX_SUBGRP
,null																							AS UDF_NEURO_PROC
,null																							AS UDF_NEURO_SPECIALTY
,null																							AS UDF_NEURO_ADULT_PEDS
,null																							AS UDF_ORTHO_SPECIALTY
,null																							AS UDF_HBENC_MODELED_TYPE_CD
,null																							AS UDF_MEDSURG_CD
,null																							AS UDF_UWH_MSDRG_WGT_NBR
,null																							AS UDF_PATIENT_ID /*  Added 6/28/21 SM */
,BuildingCode																					AS UDF_PRIN_GL_BLD_ID /*  Added 6/28/21 SM */
,'RetailRx'																						AS UDF_OP_ENC_TYPE /*  Added 6/28/21, hard coded to RetailRx 1/14/2022 SM */
,0																								AS UDF_OR_CASES /* Added 6/28/21 Will not send to Strata SM */
,null																							AS UDF_MSDRG_CLIN_GRP /* added 9/8/21 SM */
,null																							AS UDF_TECHCHG_BUS_SEG_ATTR_PROV_ID /* added 9/8/21 SM */
,0																								AS UDF_PATIENT_PAYMENTS /* added 9/8/21 SM */
,null																							AS UDF_Quartz_Cap_Breakdown /* updated 9/8/21 SM */
,null																							AS UDF_Quartz_Line_Of_Business /* updated 9/8/21 SM */
,null																							AS UDF_Quartz_LOB_Breakdown /* updated 9/8/21 SM */
,null																							AS UDF_Quartz_Risk_Panel /* updated 9/8/21 SM */
,null																							AS UDF_Quartz_Region /* updated 9/8/21 SM */
,null																							as UDF_HVT_DX_GRP_1 /* added 9/27/21 SM */
,null																							as UDF_HVT_DX_GRP_2 /* added 9/27/21 SM */
,null 																							as UDF_HVT_PX_GRP_1 /* added 9/27/21 SM */
,null																							as UDF_HVT_PX_GRP_2 /* added 9/27/21 SM */
,null																							AS UDF_CPT_PRIM_PERF_PHYSICIAN /* added 1/14/2022 SM */
,null																							AS UDF_PRIMARY_CPT_CODE /* added 1/14/2022 SM */
,null																							AS UDF_PRINCIPAL_SURGEON /* added 1/14/2022 SM */
,null																							AS UDF_PRIMARY_HCPCS_CODE /* added 1/14/2022 SM */
,null																							AS UDF_PRIN_PROCEDURE /* added 1/14/2022 SM		 */																			
,null																							AS UDF_PRIN_PROCEDURE_TYPE /* added 1/14/2022 SM */
,incl.UDF_SERVICE_AREA_ID																			AS UDF_SERVICE_AREA_ID
,'N'																							AS AODA_FLG 	/* SM 2/16/2022 added to exclude AODA  */

from SOURCE_UWHEALTH.UDD_EA_STRATA_RETAILRX_SUMMARY a
JOIN MART_LOAD_UWHEALTH.STRATA_GLOBAL_INCLUSIONS_HX incl on cast(a.EncounterRecordNumber as numeric(36,0)) = incl.ENCOUNTERRECORDNUMBER and incl.ACTIVE_FLG = 'Y' and incl.SOURCESYSTEM = 'RetailRx'



union all
/* SAGE Type 4's: Optical Dummy Records loaded from journal ledger.  */
/* Changed by SLO, SG 7/25/2022 */
select 
cast(concat(44444,GL_COMPANY_ID,GL_BUILDING_ID,GL_COST_CENTER_ID,FY,FP) as numeric(36,0))			AS EncounterRecordNumber/* required */
,'4'																								AS MedicalRecordNumber /* required */
,null																								AS LocationCode /* required */
,cast(GL_COMPANY_ID as VARCHAR(3))																	AS EntityCode
,'OPTCL'																							AS PatientTypeCode /* required, hard coded 9/14/2022 */
,'Optical'								  															AS FirstName /* required */
,'Revenue'																							AS LastName /* required */
,null																								AS MiddleName /* required */
,null																								AS GenderCode /* required */
,null																								AS DateOfBirth /* required */
,null																								AS RaceCode /* required */
,null																								AS MaritalStatusCode /* required */
,null																								AS ZipCode /* required  */
,null																								AS StreetAddress /* recommended. combine line 1 and 2 of address. */
,null																								AS City /* required */
,null																								AS State /* required */
,null																								AS County /* required */
,null																								AS EmployerCode
,null																								AS GuarantorCode
,null																								AS GuarantorEmployerCode
,null																								AS InsurancePlan1Code /* required */
,null																								AS InsurancePlan2Code /* recommended */
,null																								AS InsurancePlan3Code /* recommended  */
,null																								AS InsurancePlan4Code /* recommended */
,null																								AS InsurancePlan5Code /* recommended */
,null																								AS PatientMotherERN
,null																								AS NewbornFlag
,convert(varchar(8),cast(EOMONTH(MIN(GL_POST_DT)) as date),112)										AS AdmitDate /* required as the date of the costed event. encounter data for non-charge amb. , last of month */
,null																								AS AdmitTime /* time of costed event. not required for non-charge amb. */
,null																								AS IPAdmitDate
,null 																								AS AdmitTypeCode
,null																								AS AdmitSourceCode
,null																								AS AdmitDepartmentCode
,null																								AS AdmitNurseStationCode
,null																								AS MethodofArrivalCode
,null																								AS AdmitICD10DXCode
,null																				  				AS PrimaryICD10DXCode /* required if feasible CAN THIS BE DONE? */
,null																							  	AS PrimaryICD10PXCode /* required if feasible. won't apply to non-charge amb encounters */
,null						 																		AS MSDRGCode
,null																								AS APRDRGSchema
,null								 																AS APRDRGCode
,null												 												AS APRROM
,null												 												AS APRSOI
,null								 																AS ClinicalServiceCode /* recommended */
,null									  															AS CMGCode
,null							  																	AS AdmitPhysicianCode
,null									  															AS AttendPhysicianCode /* required */
,null																								AS ConsultPhysician1Code
,null																								AS ConsultPhysician2Code
,null																								AS ConsultPhysician3Code
,null																								AS ConsultPhysician4Code
,null																								AS ConsultPhysician5Code
,null																								AS PrimaryPerformingPhysicianCode /* required but evaluate for feasibility. won't apply for non-charge amb encounters */
,null  																								AS ReferPhysicianCode
,null																								AS PrimaryCarePhysicianCode /* recommended, grab at time of encounter */
,convert(varchar(8),cast(EOMONTH(MIN(GL_POST_DT)) as date),112)										AS DischargeDate /* last day of the month */
,null  																								AS DischargeTime
,null																								AS DischargeDepartmentCode
,null																								AS DischargeNurseStationCode
,null																								AS DischargeStatusCode
,null																								AS BillStatusCode
,null																								AS FinalBillDate
,0																									AS AccountBalance
,sum(posted_amt)																					AS HistoricalExpectedPayment 
,null																								AS AccountType
,null																								AS BadDebtDate
,null 																								AS BilledMDC
,null					 																			AS CodingStatus
,null																								AS CurrentInsurancePlan
,null											 													AS FacilityTransferredFrom
,null									  															AS FacilityTransferredTo
,null										  														AS GuarantorRelationship
,null  																								AS MSMDC
,null																								AS EMPI
,null																								AS SubscriberNumber
,null																								AS SubscriberEmployer
,null																								AS SubscriberRelationship
,null																								AS InsurancePlan1GroupName
,null																								AS InsurancePlan1GroupNumber
,null																								AS InsurancePlan2GroupName
,null																								AS InsurancePlan2GroupNumber
,null																								AS InsurancePlan3GroupName
,null																								AS InsurancePlan3GroupNumber
,null																								AS InsurancePlan4GroupName
,null																								AS InsurancePlan4GroupNumber
,null																								AS InsurancePlan5GroupName
,null																								AS InsurancePlan5GroupNumber
,null																								AS AgeCohorts /* recommended */
,'Optical'				 																			AS SourceSystem 
,null																								AS UDFAdvBoardServiceLine
,null																								AS UDFAdvBoardSubServiceLine
,null																								AS UDFAdBoardOutpatientProcServiceShort
,null																								AS UDFUWHCLegacyServiceLine
,null   																							AS UDFQuartzUWHealthRisk /* required */
,null																								AS UDFUWHealthMedicalHome /* required */
,null																								AS UDFNGACOIndicator /* required */
,null 																								AS UDF_GL_PAYOR_ID /* required  */
,null																								AS UDF_UW_PAYOR_RISK_SPECIFIC /* required  */
,null																								AS UDF_PAYOR_RISK_ARRANGEMENT /* required */
,null																								AS UDF_ACADEMIC_CLINICAL_DEPT
,null																								AS UDF_ACADEMIC_CLINICAL_SECTION
,null																								AS UDF_ACADEMIC_CLINICAL_SECTION_ID
,null																								AS UDF_PAT_ENC_CSN_ID
,'4'																								AS UDFSyntheticHARRule
,null    							                                                              	AS UDF_ZIPCODE_MARKET_2000A
,null    							                                                              	AS UDF_ZIPCODE_MARKET_2000B
,null                                   								                            AS UDF_ZIPCODE_REGION_2000
,null																								AS UDF_CANCER_SITE_GRP_1
,null 																								AS UDF_CANCER_SITE_GRP_2
,null																								AS UDF_TRANSPLANT_EPISODE_NAME
,null																								AS UDF_TRANSPLANT_RECIPIENT_DONOR
,null																								AS UDF_TRANSPLANT_ADULT_PEDS
,null																								AS UDF_TRANSPLANT_VA_PATIENT
,null																								AS UDF_TRANSPLANT_ORGAN_PROC_GROUP
,null																								AS UDF_TRANSPLANT_EPISODE_PHASE
,null																								AS UDF_PEDS_CARE_TYPE
,null																								AS UDF_DHC_CATEGORY
,null																								AS UDF_WPW_DXGRP_DESC
,null																								AS UDF_WPW_DXGRP_CODES
,null																								AS UDF_WPW_PROVGRP
,null																								AS UDF_WPW_UPM_FLG
,null																								AS UDF_NEURO_DX
,null																								AS UDF_NEURO_DX_SUBGRP
,null																								AS UDF_NEURO_PROC
,null																								AS UDF_NEURO_SPECIALTY
,null																								AS UDF_NEURO_ADULT_PEDS
,null																								AS UDF_ORTHO_SPECIALTY
,null																								AS UDF_HBENC_MODELED_TYPE_CD
,null																								AS UDF_MEDSURG_CD
,null																								AS UDF_UWH_MSDRG_WGT_NBR
,null																								AS UDF_PATIENT_ID 
,GL_BUILDING_ID																						AS UDF_PRIN_GL_BLD_ID 
,'OPTICAL'																							AS UDF_OP_ENC_TYPE 
,0																									AS UDF_OR_CASES 
,null																								AS UDF_MSDRG_CLIN_GRP 
,null																								AS UDF_TECHCHG_BUS_SEG_ATTR_PROV_ID 
,0																									AS UDF_PATIENT_PAYMENTS 
,null																								AS UDF_Quartz_Cap_Breakdown 
,null																								AS UDF_Quartz_Line_Of_Business 
,null																								AS UDF_Quartz_LOB_Breakdown 
,null																								AS UDF_Quartz_Risk_Panel 
,null																								AS UDF_Quartz_Region 
,null																								as UDF_HVT_DX_GRP_1 
,null																								as UDF_HVT_DX_GRP_2 
,null																								as UDF_HVT_PX_GRP_1 
,null																								as UDF_HVT_PX_GRP_2 
,null																								AS UDF_CPT_PRIM_PERF_PHYSICIAN 
,null																								AS UDF_PRIMARY_CPT_CODE 
,null																								AS UDF_PRINCIPAL_SURGEON 
,null																								AS UDF_PRIMARY_HCPCS_CODE 
,null																								AS UDF_PRIN_PROCEDURE 																				
,null																								AS UDF_PRIN_PROCEDURE_TYPE 
,incl.UDF_SERVICE_AREA_ID																			AS UDF_SERVICE_AREA_ID
,'N'																								AS AODA_FLG 	
from MART_UWHEALTH.UWH_GL_DETAIL_DAILY a
JOIN MART_LOAD_UWHEALTH.STRATA_GLOBAL_INCLUSIONS_HX incl on cast(concat(44444,GL_COMPANY_ID,GL_BUILDING_ID,GL_COST_CENTER_ID,FY,FP) as numeric(36,0)) = incl.ENCOUNTERRECORDNUMBER and incl.ACTIVE_FLG = 'Y' and incl.SOURCESYSTEM = 'Optical'

where 
GL_COST_CENTER_ID = '3030277' and GL_COMPANY_ID = '310' and GL_ACCOUNT_ID like '4%' and fy> 2017

GROUP BY GL_COMPANY_ID, GL_BUILDING_ID, GL_COST_CENTER_ID, FY, FP,incl.UDF_SERVICE_AREA_ID	
) ALLCOLS
group by 
       [EncounterRecordNumber]
      ,[MedicalRecordNumber]
      ,[LocationCode]
      ,[EntityCode]
      ,[PatientTypeCode]
      ,[FirstName]
      ,[LastName]
      ,[MiddleName]
      ,[GenderCode]
      ,[DateOfBirth]
      ,[RaceCode]
      ,[MaritalStatusCode]
      ,[ZipCode]
      ,[StreetAddress]
      ,[City]
      ,[State]
      ,[County]
      ,[EmployerCode]
      ,[GuarantorCode]
      ,[GuarantorEmployerCode]
      ,[InsurancePlan1Code]
      ,[InsurancePlan2Code]
      ,[InsurancePlan3Code]
      ,[InsurancePlan4Code]
      ,[InsurancePlan5Code]
      ,[PatientMotherERN]
      ,[NewbornFlag]
      ,[AdmitDate]
      ,[AdmitTime]
      ,[IPAdmitDate]
      ,[AdmitTypeCode]
      ,[AdmitSourceCode]
      ,[AdmitDepartmentCode]
      ,[AdmitNurseStationCode]
      ,[MethodofArrivalCode]
      ,[AdmitICD10DXCode]
      ,[PrimaryICD10DXCode]
      ,[PrimaryICD10PXCode]
      ,[MSDRGCode]
      ,[APRDRGSchema]
      ,[APRDRGCode]
      ,[APRROM]
      ,[APRSOI]
      ,[ClinicalServiceCode]
      ,[CMGCode]
      ,[AdmitPhysicianCode]
      ,[AttendPhysicianCode]
      ,[ConsultPhysician1Code]
      ,[ConsultPhysician2Code]
      ,[ConsultPhysician3Code]
      ,[ConsultPhysician4Code]
      ,[ConsultPhysician5Code]
      ,[PrimaryPerformingPhysicianCode]
      ,[ReferPhysicianCode]
      ,[PrimaryCarePhysicianCode]
      ,[DischargeDate]
      ,[DischargeTime]
      ,[DischargeDepartmentCode]
      ,[DischargeNurseStationCode]
      ,[DischargeStatusCode]
      ,[BillStatusCode]
      ,[FinalBillDate]
      ,[AccountBalance]
      ,[HistoricalExpectedPayment]
      ,[AccountType]
      ,[BadDebtDate]
      ,[BilledMDC]
      ,[CodingStatus]
      ,[CurrentInsurancePlan]
      ,[FacilityTransferredFrom]
      ,[FacilityTransferredTo]
      ,[GuarantorRelationship]
      ,[MSMDC]
      ,[EMPI]
      ,[SubscriberNumber]
      ,[SubscriberEmployer]
      ,[SubscriberRelationship]
      ,[InsurancePlan1GroupName]
      ,[InsurancePlan1GroupNumber]
      ,[InsurancePlan2GroupName]
      ,[InsurancePlan2GroupNumber]
      ,[InsurancePlan3GroupName]
      ,[InsurancePlan3GroupNumber]
      ,[InsurancePlan4GroupName]
      ,[InsurancePlan4GroupNumber]
      ,[InsurancePlan5GroupName]
      ,[InsurancePlan5GroupNumber]
      ,[AgeCohorts]
      ,[SourceSystem]
      ,[UDFAdvBoardServiceLine]
      ,[UDFAdvBoardSubServiceLine]
      ,[UDFAdBoardOPProcServiceShort]
      ,[UDFUWHCLegacyServiceLine]
      ,[UDFQuartzUWHealthRisk]
      ,[UDFUWHealthMedicalHome]
      ,[UDFNGACOIndicator]
      ,[UDF_GL_PAYOR_ID]
      ,[UDF_UW_PAYOR_RISK_SPECIFIC]
      ,[UDF_PAYOR_RISK_ARRANGEMENT]
      ,[UDF_ACADEMIC_CLINICAL_DEPT]
      ,[UDF_ACADEMIC_CLINICAL_SECTION]
      ,[UDF_ACADEMIC_CLINICAL_SECTION_ID]
      ,[UDF_PAT_ENC_CSN_ID]
      ,[UDFSyntheticHARRule]
      ,[UDF_ZIPCODE_MARKET_2000A]
      ,[UDF_ZIPCODE_MARKET_2000B]
      ,[UDF_ZIPCODE_REGION_2000]
      ,[UDF_CANCER_SITE_GRP_1]
      ,[UDF_CANCER_SITE_GRP_2]
      ,[UDF_TRANSPLANT_EPISODE_NAME]
      ,[UDF_TRANSPLANT_RECIPIENT_DONOR]
      ,[UDF_TRANSPLANT_ADULT_PEDS]
      ,[UDF_TRANSPLANT_VA_PATIENT]
      ,[UDF_TRANSPLANT_ORGAN_PROC_GROUP]
      ,[UDF_TRANSPLANT_EPISODE_PHASE]
      ,[UDF_PEDS_CARE_TYPE]
      ,[UDF_DHC_CATEGORY]
      ,[UDF_WPW_DXGRP_DESC]
      ,[UDF_WPW_DXGRP_CODES]
      ,[UDF_WPW_PROVGRP]
      ,[UDF_WPW_UPM_FLG]
      ,[UDF_NEURO_DX]
      ,[UDF_NEURO_DX_SUBGRP]
      ,[UDF_NEURO_PROC]
      ,[UDF_NEURO_SPECIALTY]
      ,[UDF_NEURO_ADULT_PEDS]
      ,[UDF_ORTHO_SPECIALTY]
      ,[UDF_HBENC_MODELED_TYPE_CD]
      ,[UDF_MEDSURG_CD]
      ,[UDF_UWH_MSDRG_WGT_NBR]
      ,[UDF_PATIENT_ID]
      ,[UDF_PRIN_GL_BLD_ID]
      ,[UDF_OP_ENC_TYPE]
      ,[UDF_OR_CASES]
      ,[UDF_MSDRG_CLIN_GRP]
      ,[UDF_TECHCHG_BUS_SEG_ATTR_PROV_ID]
      ,[UDF_PATIENT_PAYMENTS]
      ,[UDF_Quartz_Cap_Breakdown]
      ,[UDF_Quartz_Line_Of_Business]
      ,[UDF_Quartz_LOB_Breakdown]
      ,[UDF_Quartz_Risk_Panel]
      ,[UDF_Quartz_Region]
      ,[UDF_HVT_DX_GRP_1]
      ,[UDF_HVT_DX_GRP_2]
      ,[UDF_HVT_PX_GRP_1]
      ,[UDF_HVT_PX_GRP_2]
      ,[UDF_CPT_PRIM_PERF_PHYSICIAN]
      ,[UDF_PRIMARY_CPT_CODE]
      ,[UDF_PRINCIPAL_SURGEON]
      ,[UDF_PRIMARY_HCPCS_CODE]
      ,[UDF_PRIN_PROCEDURE]
      ,[UDF_PRIN_PROCEDURE_TYPE]
	  , udf_service_area_id
      ,[AODA_FLG];
GO


