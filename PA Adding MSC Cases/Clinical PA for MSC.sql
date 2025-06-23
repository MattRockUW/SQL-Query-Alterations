/****** Object:  View [Mart_Load_UWHealth].[VIZIENT_PROC_ANALYTICS_CLN_UW]    Script Date: 5/13/2025 9:22:31 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [Mart_Load_UWHealth].[VIZIENT_PROC_ANALYTICS_CLN_UW] AS 
SELECT 
/*
5-13-25 Matt Rock - added another union to select MSC cases. Those cases did not have entries in [source_uwhealth].epic_hsp_account_cur, so 
they were almost entirely not included. The work around was to get to Strata data via 
[source_uwhealth].epic_pat_or_adm_link_cur.or_link_csn = [Mart_UWHealth].STRATA_COST_CHARGE_ACTIVITY_PB.pat_enc_csn_id
*/
DISTINCT
'520098' as "Medicare Provider ID"
,COALESCE(CAST(har.LOC_ID as varchar(18)), '') as "Sub-Facility ID"
,'40357' as "Member ID"
,COALESCE(CAST(har.HSP_ACCOUNT_ID as varchar(18)), '') as "Encounter ID"
,COALESCE(CAST(id.IDENTITY_ID as varchar(25)), '') as "Patient ID"
,COALESCE(orlog.CASE_ID, '') as "PROCEDURAL CASE NUMBER"
,COALESCE(CAST(CONVERT(nchar(8), orlog.SURGERY_DATE,112) as varchar(112)),'') AS "Date of Service"
,COALESCE(CAST(CONVERT(nchar(8), patient.BIRTH_DATE,112) as varchar(112)),'') AS "Date of Birth"
,flb.DEPARTMENT_ID as "HCO DEPARTMENT CODE"
,cd2.DEPARTMENT_NAME as "HCO DEPARTMENT DESCRIPTION" 
,CASE WHEN patient.SEX_C = '1' THEN '2'
 WHEN patient.SEX_C = '2' THEN '1'
 ELSE '3'
END as "SEX"
--,COALESCE(zoor.TITLE, '') as "PROCEDURE LOCATION"-- BJ: 08/10/18
,'' as "PROCEDURE LOCATION"
,COALESCE(zocc.TITLE, '') as "CASE STATUS"-- BJ: 08/10/18

-- BEGIN "Client to Verify" Selection - compare mapped values below in table ZC_ACCT_CLASS_HA to values below, update as needed!!!!!
-- Per Ashley Petit, only account classes used are 1,2,4,5,6,8,22 and 5/22 can be broken out by if the procedure is at TSC or MSC, so everything else is coded as miscellaneous. 1 is technically inpatient, but we decided to code it as emergency since there is a bucket for it.
,CASE WHEN har.ACCT_CLASS_HA_C  ='1' THEN 'E'-- Emergency - Emergency
WHEN har.ACCT_CLASS_HA_C ='2' THEN 'I'-- Inpatient - Inpatient
WHEN har.ACCT_CLASS_HA_C ='3' THEN 'O' -- Observation - Observation
WHEN har.ACCT_CLASS_HA_C ='4' THEN 'O' -- Outpatient Short Stay - Inpatient --recoded as OP as of 3/28/2019 due to 10% cases not coming through with ICDs, but having CPTs
WHEN har.ACCT_CLASS_HA_C ='5' AND har.LOC_ID IN ('34000','34100') THEN 'F' -- Outpatient - Freestanding Ambulatory Surgery
WHEN har.ACCT_CLASS_HA_C ='5' AND har.LOC_ID NOT IN ('34000','34100') THEN 'H' -- Outpatient - Hospital-Based Ambulatory Surgery
WHEN har.ACCT_CLASS_HA_C ='6' THEN 'I' -- First Day Surgery - Inpatient
WHEN har.ACCT_CLASS_HA_C ='8' THEN 'I' -- Surgical Admit - Inpatient
WHEN har.ACCT_CLASS_HA_C ='9' THEN 'M' -- Home Health - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='10' THEN 'M'-- Take Home Med - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='11' THEN 'M'-- Home Care Services - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='12' THEN 'M'-- Specimen - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='13' THEN 'M' -- Med Flight - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='14' THEN 'M' -- Rehab Maintenance - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='15' THEN 'M' -- Group - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='16' THEN 'M' -- Therapy - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='17' THEN 'M' -- Hospice Outpt - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='18' THEN 'M' -- Hospice Inpt - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='19' THEN 'M' -- Palliative Care - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='20' THEN 'M' -- Hospice Face to Face - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='21' THEN 'M' -- Hospice Related - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='22' AND har.LOC_ID IN ('34000','34100') THEN 'F' -- Expected Stroke - Freestanding Ambulatory Surgery
WHEN har.ACCT_CLASS_HA_C ='22' AND har.LOC_ID NOT IN ('34000','34100') THEN 'H' -- Expected Stroke - Hospital-Based Ambulatory Surgery
WHEN har.ACCT_CLASS_HA_C ='23' THEN 'M' -- Newborn - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='24' THEN 'M' -- Dialysis - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='24' THEN 'M' -- Complex Care - Miscellaneous
ELSE 'M'
END as "ENCOUNTER TYPE" 
-- END "Client to Verify Selection"

---- BEGIN "Client to Verify Selection" - Case Type (coding to be modified/replaced per client)
----UW Health is hardcoding this field because all of the data will be flowing through clarity for now and the operating room is the only procedural area using clarity
--,'OR' AS "CASE TYPE" --used to do this for UWH-madison until 6/14/19
,CASE WHEN ser_room.PROV_NAME like '%UWHC OSC%' THEN 'HA'-- Hospital based ambulatory surgery
WHEN orlog.ROOM_ID IN ('692083','692084','693343','695239') THEN 'HS'-- Hybrid Suite
Else 'OR'
END AS "CASE TYPE"
--WHEN ser_room.PROV_NAME like '%ENDO%'THEN 'EN'-- Endoscopy
--WHEN loc.LOC_NAME like '%ENDO%'THEN 'EN'-- Endoscopy
--WHEN ser_room.PROV_NAME like '%GI%'THEN 'EN'-- Endoscopy
--WHEN loc.LOC_NAME like '%GI%'THEN 'EN'-- Endoscopy
--WHEN ser_room.PROV_NAME like '%IR%' 
--AND (primphys.SPECIALTY_NAME like '%Radio%' OR primphys.SPECIALTY_NAME like '%Cardio%')
---- AND left(orproc.PROC_NAME,3) = 'IR '-- Univ of Colorado only
--THEN 'IR'-- Interventional Radiology
--WHEN loc.LOC_NAME like '%IR%'
--AND (primphys.SPECIALTY_NAME like '%Radio%' OR primphys.SPECIALTY_NAME like '%Cardio%')
---- AND left(orproc.PROC_NAME,3) = 'IR '-- Univ of Colorado only
--THEN 'IR'-- Interventional Radiology
--WHEN @MemberHCOID = 'TBD'
--AND loc.LOC_NAME like '%CARDIO%'THEN 'PV'-- Peripheral Vascular -- INTEGRIS ONLY
--
--
--WHEN ser_room.PROV_NAME like '%CV%' 
--OR ser_room.PROV_NAME like '%PV%'
--OR ser_room.PROV_NAME like '%PERIPH VASC%'THEN 'PV'-- Peripheral Vascular
--WHEN loc.LOC_NAME like '%CV%' 
--OR loc.LOC_NAME like '%PV%'
--OR loc.LOC_NAME like '%PERIPH VASC%'THEN 'PV'-- Peripheral Vascular
--
--
--WHEN @MemberHCOID = 'TBD'
--AND loc.LOC_NAME like '%Invasive%'
--AND primphys.SPECIALTY_NAME like '%Electro%'THEN 'EP'-- Electrophysiology  -- INTEGRIS ONLY
--
--
--WHEN ser_room.PROV_NAME like '%HCL%' 
--AND primphys.SPECIALTY_NAME like '%Electrophysiology%' THEN 'EP'-- Electrophysiology Laboratory
--WHEN loc.LOC_NAME like '%HCL%'
--AND primphys.SPECIALTY_NAME like '%Electrophysiology%'THEN 'EP'-- Electrophysiology Laboratory
--WHEN ser_room.PROV_NAME like '% CL%' 
--AND primphys.SPECIALTY_NAME like '%Electrophysiology%'THEN 'EP'-- Electrophysiology Laboratory
--WHEN loc.LOC_NAME like '% CL%'
--AND primphys.SPECIALTY_NAME like '%Electrophysiology%'THEN 'EP'-- Electrophysiology Laboratory
--
--WHEN @MemberHCOID = 'TBD'
--AND loc.LOC_NAME like '%Invasive%'
--AND primphys.SPECIALTY_NAME like '%Cardio%'THEN 'CC'-- Cardiology -- INTEGRIS ONLY
--
--
--WHEN ser_room.PROV_NAME like '%HCL%' 
--AND primphys.SPECIALTY_NAME like '%Cardiology%'THEN 'CC'-- Cardiac Catherization Laboratory
--WHEN loc.LOC_NAME like '%HCL%'
--AND primphys.SPECIALTY_NAME like '%Cardiology%'  THEN 'CC'-- Cardiac Catherization Laboratory
--WHEN ser_room.PROV_NAME like '% CL%' 
--AND primphys.SPECIALTY_NAME like '%Cardiology%'THEN 'CC'-- Cardiac Catherization Laboratory
--WHEN loc.LOC_NAME like '% CL%' 
--AND primphys.SPECIALTY_NAME like '%Cardiology%'  THEN 'CC'-- Cardiac Catherization Laboratory
--WHEN ser_room.PROV_NAME like '%ASC%' THEN 'FA' -- FreeStanding Ambulatory Surgery Center
--WHEN loc.LOC_NAME like '%ASC%' THEN 'FA'-- FreeStanding Ambulatory Surgery Center
--WHEN ser_room.PROV_NAME like '%SDS%' THEN 'FA' -- FreeStanding Ambulatory Surgery Center
--WHEN loc.LOC_NAME like '%SDS%' THEN 'FA'-- FreeStanding Ambulatory Surgery Center
--WHEN ser_room.PROV_NAME like '%SDC%' THEN 'FA' -- FreeStanding Ambulatory Surgery Center
--WHEN loc.LOC_NAME like '%SDC%' THEN 'FA'-- FreeStanding Ambulatory Surgery Center
--
--WHEN @MemberHCOID = 'TBD'
--AND ser_room.PROV_NAME like '%IH %' THEN 'HA'-- Hospital-Based Ambulatory Surgery Center -- INTEGRIS ONLY
--WHEN @MemberHCOID = 'TBD' 
--ANDloc.LOC_NAME like '%IH %' THEN 'HA'-- Hospital-Based Ambulatory Surgery Center -- INTEGRIS ONLY
--
--
--WHEN @MemberHCOID = 'TBD'
--AND loc.LOC_NAME like '%Main OR%'THEN 'OR'-- Operating Room -- INTEGRIS ONLY
--
--
--WHEN ser_room.PROV_NAME  like '%OR%' THEN 'OR'-- Operating Room
--WHEN loc.LOC_NAME like '%OR%' THEN 'OR'-- Operating Room
--ELSE 'OT'-- Other
--END as "CASE TYPE"
--
---- END "Client to Verify Selection" 

,'' as "ROBOTICS FLAG"  
,COALESCE(CAST(orlog.ASA_RATING_C as varchar(2)), '') as "ASA PHYSICAL STATUS CLASSIFICATION"
,'' AS "CPT Procedure Code"  
,'' as "CPT HOSPITAL-ASSIGNED PHYSICIAN ID" -- BJ: 08/07/18
,'' as "CPT CODE MODIFIER_1" 
,'' as "CPT CODE MODIFIER_2"         
,'' as "CPT CODE MODIFIER_3"         
,'' as "CPT CODE MODIFIER_4"        
,CAST(COALESCE(px1.REF_BILL_CODE, px2.REF_BILL_CODE, px3.REF_BILL_CODE, '') as varchar(7)) as "ICD-10 PROCEDURE CODE"    
,CASE WHEN px1.REF_BILL_CODE = '' AND px2.REF_BILL_CODE = '' AND px3.REF_BILL_CODE = ''  THEN ''
WHEN px1.REF_BILL_CODE != '' THEN CAST(hap1.LINE as varchar(10)) 
WHEN px2.REF_BILL_CODE != '' THEN CAST(hap2.LINE as varchar(10))
WHEN px3.REF_BILL_CODE != '' THEN CAST(hap3.LINE as varchar(10))
ELSE ''  -- Added ELSE to avoid NULL 6/20/2023 Doug
END as "ICD-10 PROCEDURE SEQUENCE" -- BJ: 09/04/18
,CASE WHEN px1.REF_BILL_CODE = '' AND px2.REF_BILL_CODE = '' AND px3.REF_BILL_CODE = ''  THEN ''
WHEN px1.REF_BILL_CODE != '' THEN CAST(serlog1.PROV_ID as varchar(10))
WHEN px2.REF_BILL_CODE != '' THEN CAST(serlog2.PROV_ID as varchar(10))
WHEN px3.REF_BILL_CODE != '' THEN CAST(serlog3.PROV_ID as varchar(10))
ELSE ''   -- Added ELSE to avoid NULL 6/20/2023 Doug
END as "ICD-10 HOSPITAL-ASSIGNED PHYSICIAN ID"
,'' as "HCO PROCEDURE CODE"
,'' as "HCO PROCEDURE DESCRIPTION"
,NULL as "HCO PROCEDURE SEQUENCE"
,'' as "HCO PROCEDURE HOSPITAL-ASSIGNED PHYSICIAN ID"
,'' as "SCHEDULED PROCEDURAL SUITE"
--,COALESCE(CAST(orlog.ROOM_ID as varchar(18)), '') as "ACTUAL PROCEDURAL SUITE"  -- BJ: 08/05/18
,COALESCE(CAST(ser_room.PROV_NAME as varchar(30)), '') as "ACTUAL PROCEDURAL SUITE" -- BJ: 08/05/15
,COALESCE(CAST(respanes.PROV_ID as varchar(18)), '') as "ANESTHESIOLOGIST PHYSICIAN ID - 1"
,'' as "ANESTHESIOLOGIST PHYSICIAN ID - 2"
,'' as "ANESTHESIOLOGIST PHYSICIAN ID - 3" 
,'' as "ANESTHESIOLOGIST PHYSICIAN ID - 4"
,COALESCE(CAST(primcirc.PROV_ID as varchar(18)), '') as "CIRCULATOR ID - 1"
,'' as "CIRCULATOR ID - 2"
,'' as "CIRCULATOR ID - 3"
,'' as "CIRCULATOR ID - 4" 
,COALESCE(primcirc.PROV_NM_CRED, '') as "CIRCULATOR NAME - 1"
,'' as "CIRCULATOR NAME - 2"
,'' as "CIRCULATOR NAME - 3"
,'' as "CIRCULATOR NAME - 4"
,COALESCE(CAST(primsurgtech.PROV_ID as varchar(18)), '') as "SCRUB TECH ID - 1"
,'' as "SCRUB TECH ID - 2"
,'' as "SCRUB TECH ID - 3"
,'' as "SCRUB TECH ID - 4"
,COALESCE(primsurgtech.PROV_NM_CRED, '') as "SCRUB TECH NAME - 1"
,'' as "SCRUB TECH NAME - 2"
,'' as "SCRUB TECH NAME - 3"
,'' as "SCRUB TECH NAME - 4"
,'' as "SURGICAL ASSISTANT ID - 1"
,'' as "SURGICAL ASSISTANT ID - 2"
,'' as "SURGICAL ASSISTANT ID - 3"
,'' as "SURGICAL ASSISTANT ID - 4" 
,'' as "SURGICAL ASSISTANT NAME - 1"
,'' as "SURGICAL ASSISTANT NAME - 2"
,'' as "SURGICAL ASSISTANT NAME - 3"
,'' as "SURGICAL ASSISTANT NAME - 4"
--,COALESCE(CAST(orlog.SCHED_START_TIME as varchar(101)), '') as 'DATE CASE SCHEDULED' - 7/24/18, updated logic (line below)...
----,COALESCE(CAST(CONVERT(nchar(8), orlog.SCHED_START_TIME,112)
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(hours from orlog.SCHED_START_TIME) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(hours from orlog.SCHED_START_TIME) as varchar(112))
----ELSE CAST(EXTRACT(hours from orlog.SCHED_START_TIME) as varchar(112))
----END
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(minutes from orlog.SCHED_START_TIME) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(minutes from orlog.SCHED_START_TIME) as varchar(112))
----ELSE CAST(EXTRACT(minutes from orlog.SCHED_START_TIME) as varchar(112))
----END 
----as varchar(112)),'') 



, FORMAT(orlog.SCHED_START_TIME,'yyyyMMddHHmm') as "DATE CASE SCHEDULED"
,CASE WHEN orc.CANCEL_REASON_C IS NOT NULL AND orc.CANCEL_COMMENTS IS NOT NULL AND ot.Incision_Start IS NULL AND ot.Incision_Close IS NULL
  THEN 'Y'
  WHEN orc.CANCEL_REASON_C IS NOT NULL AND orc.CANCEL_COMMENTS IS NULL AND ot.Incision_Start IS NULL AND ot.Incision_Close IS NULL
  THEN 'Y'
  WHEN orc.CANCEL_COMMENTS IS NOT NULL AND orc.CANCEL_REASON_C IS NULL AND ot.Incision_Start IS NULL AND ot.Incision_Close IS NULL
  THEN 'Y'
  ELSE 'N'
END as "CANCELLATION FLAG"
----,COALESCE(CAST(CONVERT(nchar(8), orlog.SCHED_START_TIME,112)
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(hours from orlog.SCHED_START_TIME) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(hours from orlog.SCHED_START_TIME) as varchar(112))
----ELSE CAST(EXTRACT(hours from orlog.SCHED_START_TIME) as varchar(112))
----END
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(minutes from orlog.SCHED_START_TIME) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(minutes from orlog.SCHED_START_TIME) as varchar(112))
----ELSE CAST(EXTRACT(minutes from orlog.SCHED_START_TIME) as varchar(112))
----END
----as varchar(112)),'') 
, FORMAT(orlog.SCHED_START_TIME,'yyyyMMddHHmm') as "SCHEDULED CASE START"
,'' as "SCHEDULED CASE END"
----,COALESCE(CAST(CONVERT(nchar(8), ot.In_Room,112)
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(hours from ot.In_Room) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(hours from ot.In_Room) as varchar(112))
----ELSE CAST(EXTRACT(hours from ot.In_Room) as varchar(112))
----END
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(minutes from ot.In_Room) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(minutes from ot.In_Room) as varchar(112))
----ELSE CAST(EXTRACT(minutes from ot.In_Room) as varchar(112))
----END
----as varchar(112)),'') 
, FORMAT(ot.In_Room,'yyyyMMddHHmm') AS "PATIENT IN ROOM"
----,COALESCE(CAST(CONVERT(nchar(8), ot.Anesthesia_Start,112)
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(hours from ot.Anesthesia_Start) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(hours from ot.Anesthesia_Start) as varchar(112))
----ELSE CAST(EXTRACT(hours from ot.Anesthesia_Start) as varchar(112))
----END
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(minutes from ot.Anesthesia_Start) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(minutes from ot.Anesthesia_Start) as varchar(112))
----ELSE CAST(EXTRACT(minutes from ot.Anesthesia_Start) as varchar(112))
----END
----as varchar(112)),'') 
, FORMAT(ot.Anesthesia_Start,'yyyyMMddHHmm') AS "ANESTHESIA START"
----,COALESCE(CAST(CONVERT(nchar(8), ot.Incision_Start,112)
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(hours from ot.Incision_Start) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(hours from ot.Incision_Start) as varchar(112))
----ELSE CAST(EXTRACT(hours from ot.Incision_Start) as varchar(112))
----END
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(minutes from ot.Incision_Start) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(minutes from ot.Incision_Start) as varchar(112))
----ELSE CAST(EXTRACT(minutes from ot.Incision_Start) as varchar(112))
----END
----as varchar(112)),'') 
, FORMAT(ot.Incision_Start,'yyyyMMddHHmm') AS "INCISION START"
----,COALESCE(CAST(CONVERT(nchar(8), ot.Incision_Close,112)
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(hours from ot.Incision_Close) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(hours from ot.Incision_Close) as varchar(112))
----ELSE CAST(EXTRACT(hours from ot.Incision_Close) as varchar(112))
----END
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(minutes from ot.Incision_Close) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(minutes from ot.Incision_Close) as varchar(112))
----ELSE CAST(EXTRACT(minutes from ot.Incision_Close) as varchar(112))
----END
----as varchar(112)),'') 
, FORMAT(ot.Incision_Close,'yyyyMMddHHmm') AS "INCISION CLOSE"
----,COALESCE(CAST(CONVERT(nchar(8), ot.Anesthesia_End,112)
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(hours from ot.Anesthesia_End) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(hours from ot.Anesthesia_End) as varchar(112))
----ELSE CAST(EXTRACT(hours from ot.Anesthesia_End) as varchar(112))
----END
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(minutes from ot.Anesthesia_End) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(minutes from ot.Anesthesia_End) as varchar(112))
----ELSE CAST(EXTRACT(minutes from ot.Anesthesia_End) as varchar(112))
----END
----as varchar(112)),'') 
, FORMAT(ot.Anesthesia_End,'yyyyMMddHHmm') AS "ANESTHESIA END"
----,COALESCE(CAST(CONVERT(nchar(8), ot.Out_of_Room,112)
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(hours from ot.Out_of_Room) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(hours from ot.Out_of_Room) as varchar(112))
----ELSE CAST(EXTRACT(hours from ot.Out_of_Room) as varchar(112))
----END
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(minutes from ot.Out_of_Room) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(minutes from ot.Out_of_Room) as varchar(112))
----ELSE CAST(EXTRACT(minutes from ot.Out_of_Room) as varchar(112))
----END
----as varchar(112)),'') 
, FORMAT(ot.Out_of_Room,'yyyyMMddHHmm') AS "PATIENT OUT OF ROOM"
----,COALESCE(CAST(CONVERT(nchar(8), ot.In_Recovery,112)
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(hours from ot.In_Recovery) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(hours from ot.In_Recovery) as varchar(112))
----ELSE CAST(EXTRACT(hours from ot.In_Recovery) as varchar(112))
----END
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(minutes from ot.In_Recovery) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(minutes from ot.In_Recovery) as varchar(112))
----ELSE CAST(EXTRACT(minutes from ot.In_Recovery) as varchar(112))
----END
----as varchar(112)),'') 
, FORMAT(ot.In_Recovery,'yyyyMMddHHmm') AS "RECOVERY START"
----,COALESCE(CAST(CONVERT(nchar(8), ot.Out_Recovery,112)
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(hours from ot.Out_Recovery) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(hours from ot.Out_Recovery) as varchar(112))
----ELSE CAST(EXTRACT(hours from ot.Out_Recovery) as varchar(112))
----END
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(minutes from ot.Out_Recovery) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(minutes from ot.Out_Recovery) as varchar(112))
----ELSE CAST(EXTRACT(minutes from ot.Out_Recovery) as varchar(112))
----END
----as varchar(112)),'') 
, FORMAT(ot.Out_Recovery,'yyyyMMddHHmm') AS "RECOVERY END"
----,COALESCE(CAST(CONVERT(nchar(8), olat2.PostDate,112)
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(hours from olat2.PostDate) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(hours from olat2.PostDate) as varchar(112))
----ELSE CAST(EXTRACT(hours from olat2.PostDate) as varchar(112))
----END
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(minutes from olat2.PostDate) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(minutes from olat2.PostDate) as varchar(112))
----ELSE CAST(EXTRACT(minutes from olat2.PostDate) as varchar(112))
----END
----as varchar(112)),'') 
, FORMAT(olat2.PostDate,'yyyyMMddHHmm') AS "POST DATE"

-- kcj 3/10: below datetimes replaced by above code

--,COALESCE(CAST(ot.IN_ROOM as varchar(112)) + SUBSTR(CAST(ot.IN_ROOM as varchar(108)),1,2) + SUBSTR(CAST(ot.IN_ROOM as varchar(108)),4,2), '') as "PATIENT IN ROOM"
--,COALESCE(CAST(ot.ANESTHESIA_START as varchar(112)) + SUBSTR(CAST(ot.ANESTHESIA_START as varchar(108)),1,2) + SUBSTR(CAST(ot.ANESTHESIA_START as varchar(108)),4,2), '') as "ANESTHESIA START"
--,COALESCE(CAST(ot.INCISION_START as varchar(112)) + SUBSTR(CAST(ot.INCISION_START as varchar(108)),1,2) + SUBSTR(CAST(ot.INCISION_START as varchar(108)),4,2), '') as "INCISION START"
--,COALESCE(CAST(ot.INCISION_CLOSE as varchar(112)) + SUBSTR(CAST(ot.INCISION_CLOSE as varchar(108)),1,2) + SUBSTR(CAST(ot.INCISION_CLOSE as varchar(108)),4,2), '') as "INCISION CLOSE"
--,COALESCE(CAST(ot.ANESTHESIA_END as varchar(112)) + SUBSTR(CAST(ot.ANESTHESIA_END as varchar(108)),1,2) + SUBSTR(CAST(ot.ANESTHESIA_END as varchar(108)),4,2), '') as "ANESTHESIA END"
--,COALESCE(CAST(ot.OUT_OF_ROOM as varchar(112)) + SUBSTR(CAST(ot.OUT_OF_ROOM as varchar(108)),1,2)+ SUBSTR(CAST(ot.OUT_OF_ROOM as varchar(108)),4,2), '') as "PATIENT OUT OF ROOM"
--,COALESCE(CAST(ot.IN_RECOVERY as varchar(112)) + SUBSTR(CAST(ot.IN_RECOVERY as varchar(108)),1,2) + SUBSTR(CAST(ot.IN_RECOVERY as varchar(108)),4,2), '') as "RECOVERY START"
--,COALESCE(CAST(ot.OUT_RECOVERY as varchar(112)) + SUBSTR(CAST(ot.OUT_RECOVERY as varchar(108)),1,2) + SUBSTR(CAST(ot.OUT_RECOVERY as varchar(108)),4,2), '') as "RECOVERY END"
--,COALESCE(CAST(olat2.PostDate as varchar(112)) + SUBSTR(CAST(olat2.PostDate as varchar(108)),1,2) + SUBSTR(CAST(olat2.PostDate as varchar(108)),4,2), '') as "POST DATE"

-- OR Mgmt System case/log records
FROM [source_uwhealth].epic_or_case_cur orc
LEFT OUTER JOIN [source_uwhealth].epic_or_log_cur orlog ON orc.LOG_ID = orlog.LOG_ID
LEFT OUTER JOIN [source_uwhealth].epic_f_log_based_cur flb ON orlog.LOG_ID = flb.LOG_ID-- available in Clarity 2015 forward
LEFT OUTER JOIN [source_uwhealth].epic_ZC_OR_CASE_CLASS_CUR zocc ON orc.CASE_CLASS_C = zocc.CASE_CLASS_C-- BJ: 08/10/18

-- Patient info
INNER JOIN [source_uwhealth].epic_pat_or_adm_link_cur PAT_OR_ADM_LINK ON orlog.CASE_ID = PAT_OR_ADM_LINK.CASE_ID
INNER JOIN [source_uwhealth].epic_pat_enc_hsp_cur peh ON PAT_OR_ADM_LINK.OR_LINK_CSN = peh.PAT_ENC_CSN_ID
INNER JOIN [source_uwhealth].epic_PATIENT_cur patient ON orlog.PAT_ID = patient.PAT_ID
INNER JOIN [source_uwhealth].epic_HSP_ACCOUNT_cur har ON peh.HSP_ACCOUNT_ID = har.HSP_ACCOUNT_ID
INNER JOIN [source_uwhealth].epic_IDENTITY_ID_cur id ON patient.PAT_ID = id.PAT_ID

-- Procedure Scheduled/Ordered Info
LEFT OUTER JOIN [source_uwhealth].epic_or_case_ALL_PROC_cur orcap ON orc.OR_CASE_ID = orcap.OR_CASE_ID AND orcap.LINE = 1-- BJ: 9/10/18
LEFT OUTER JOIN [source_uwhealth].epic_OR_PROC_cur orproc ON orcap.OR_PROC_ID = orproc.OR_PROC_ID
--LEFT OUTER JOIN ZC_OR_OP_REGION zoor ON orproc.OPERATING_REGION_C = zoor.OPERATING_REGION_C-- BJ: 08/10/18
-- Reflecting CASE Documentation: OR_PROC_CPT_ID varies by Member (1) not populated, (2) CPT mapped 1 PROC_ID to many CPTs to hopefully (3) CPT mapped to 1 PROC_ID
--LEFT OUTER JOIN OR_PROC_CPT_ID orproccpt ON orproc.OR_PROC_ID = orproccpt.OR_PROC_ID
LEFT OUTER JOIN [source_uwhealth].epic_ZC_OR_CANCEL_RSN_cur orcrsn ON orc.CANCEL_REASON_C = orcrsn.CANCEL_REASON_C
LEFT OUTER JOIN [source_uwhealth].epic_ZC_PROC_NOT_PERF_cur zcprocnotperf ON orlog.PROC_NOT_PERF_C = zcprocnotperf.PROC_NOT_PERF_C

-- Performing Physician Info (not captured in F_LOG_BASED table)
LEFT JOIN [source_uwhealth].epic_or_log_ALL_STAFF_cur orlas1 on orlas1.LOG_ID = orlog.LOG_ID and orlas1.STAFF_TYPE_MAP_C = 1 and orlas1.ROLE_C = 1 and orlas1.PANEL = 1 -- and orlas1.ACCOUNTBLE_STAFF_YN = 'Y'
LEFT JOIN [source_uwhealth].epic_CLARITY_SER_cur serlog1 on serlog1.PROV_ID = orlas1.STAFF_ID
-- Assisting Physician
LEFT JOIN [source_uwhealth].epic_or_log_ALL_STAFF_cur orlas2 on orlas2.LOG_ID = orlog.LOG_ID and orlas2.STAFF_TYPE_MAP_C = 1 and orlas2.ROLE_C = 2 and orlas2.PANEL = 1 -- and orlas2.ACCOUNTBLE_STAFF_YN = 'Y'
LEFT JOIN [source_uwhealth].epic_CLARITY_SER_cur serlog2 on serlog2.PROV_ID = orlas2.STAFF_ID
-- Resident Assisting Physician
LEFT JOIN [source_uwhealth].epic_or_log_ALL_STAFF_cur orlas3 on orlas3.LOG_ID = orlog.LOG_ID and orlas3.STAFF_TYPE_MAP_C = 1 and orlas3.ROLE_C = 3 and orlas3.PANEL = 1 -- and orlas3.ACCOUNTBLE_STAFF_YN = 'Y'
LEFT JOIN [source_uwhealth].epic_CLARITY_SER_cur serlog3 on serlog3.PROV_ID = orlas3.STAFF_ID

    
-- Staff Name and Credentials
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur performphys on serlog1.PROV_ID = performphys.PROV_ID--performing physician
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur assistingphys on serlog2.PROV_ID = performphys.PROV_ID--assisting physician
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur residentphys on serlog3.PROV_ID = performphys.PROV_ID--resident physician

LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur primphys on flb.PRIMARY_PHYSICIAN_ID = primphys.PROV_ID--primary physician
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur secondphys on flb.SECONDARY_PHYSICIAN_ID = secondphys.PROV_ID--secondary physician
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur primcirc on flb.PRIMARY_CIRCULATOR_ID = primcirc.PROV_ID--primary circulator
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur primsurgtech on flb.PRIMARY_SURG_TECH_ID = primsurgtech.PROV_ID--primary surgical technician
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur primprern on flb.PRIMARY_PREOP_NURSE_ID = primprern.PROV_ID--primary preop nurse
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur primrecrn on flb.PRIMARY_RECOVERY_NURSE_ID = primrecrn.PROV_ID--primary recovery nurse
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur primphaseiirn on flb.PRIMARY_PHASEII_NURSE_ID = primphaseiirn.PROV_ID--primary phase II nurse
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur respanes on flb.RESP_ANES_ID = respanes.PROV_ID--responsible anesthesia provider
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur firstanes on flb.FIRST_ANES_ID = firstanes.PROV_ID--first anesthesia provider

-- Exclude test paitients in WHERE clause
LEFT OUTER JOIN [source_uwhealth].epic_PATIENT_3_cur pat3 ON patient.PAT_ID = pat3.PAT_ID


/* BJ: replaced with D_PROV_PRIMARY_HIERARCHY, code to be removed shortly!!!
-- Anesthesiologist Info
LEFT OUTER JOIN (SELECT astf.LOG_ID, astaff.ANESTH_STAFF_ID AS ANESTHESIOLOGIST_PROV_ID, ser.PROV_NAME AS ANESTHESIOLOGIST
 FROM OR_LOG_LN_ANESSTAF astf
LEFT OUTER JOIN OR_LNLG_ANES_STAFF astaff ON astf.ANESTHESIA_STAFF_I = astaff.RECORD_ID
LEFT OUTER JOIN ZC_OR_ANSTAFF_TYPE atp ON astaff.ANESTH_STAFF_C = atp.ANEST_STAFF_REQ_C  
LEFT OUTER JOIN CLARITY_SER ser ON astaff.ANESTH_STAFF_ID = ser.PROV_ID
 WHERE atp.ANEST_STAFF_REQ_C = 10 AND astf.LINE = (SELECT MIN(a.LINE)
   FROM OR_LOG_LN_ANESSTAF a
   WHERE a.LOG_ID = astf.LOG_ID)
) an ON orlog.LOG_ID = an.LOG_ID
*/

-- OR Room Info
LEFT OUTER JOIN [source_uwhealth].epic_CLARITY_SER_cur ser_room ON orlog.ROOM_ID = ser_room.PROV_ID
LEFT OUTER JOIN [source_uwhealth].epic_CLARITY_LOC_cur loc on orlog.LOC_ID = loc.LOC_ID
 
--Department
LEFT OUTER JOIN [source_uwhealth].epic_CLARITY_DEP_cur cd2 ON flb.DEPARTMENT_ID = cd2.DEPARTMENT_ID



-- BEGIN "Client to Verify Selection" - OR Times (possibly custom built per client) in table ZC_OR_PAT_EVENTS
-- OR TIME parameters for TRACKING EVENTs & PANEL TIME EVENTs found in tables: [OR_LOG_CASE_TIMES and OR_LOG_PANEL_TIME1]

--LEFT OUTER JOIN (SELECT ct.LOG_ID
-- ,MAX(CASE WHEN ct.TRACKING_EVENT_C = '60' THEN ct.TRACKING_TIME_IN END) AS In_Room-- In Surgical Room
-- ,MAX(CASE WHEN ct.TRACKING_EVENT_C = '70' THEN ct.TRACKING_TIME_IN END) AS Anesthesia_Start-- Anesthesia Begins
-- ,MAX(CASE WHEN ptime.PANEL_TIME_EVENT_C = '10' THEN ptime.panel_start_time END) AS Incision_Start-- Incision Open
-- ,MAX(CASE WHEN ptime.PANEL_TIME_EVENT_C = '20' THEN ptime.panel_start_time END) AS Incision_Close-- Incision Closed
-- ,MAX(CASE WHEN ct.TRACKING_EVENT_C = '100' THEN ct.TRACKING_TIME_IN END) AS Anesthesia_End-- Anesthesia End
-- ,MAX(CASE WHEN ct.TRACKING_EVENT_C = '110' THEN ct.TRACKING_TIME_IN END) AS Out_of_Room-- Out of Surgical Room
-- ,MAX(CASE WHEN ct.TRACKING_EVENT_C IN ('120','500','580') THEN ct.TRACKING_TIME_IN END) AS In_Recovery-- In Recovery (PACU)
-- ,MAX(CASE WHEN ct.TRACKING_EVENT_C IN ('140','540','590') THEN ct.TRACKING_TIME_IN END) AS Out_Recovery-- Out Recovery (PACU)
-- FROM OR_LOG_CASE_TIMES ct 
--LEFT OUTER JOIN OR_LOG_PANEL_TIME1 ptime ON ct.log_id = ptime.log_id
-- WHERE ct.TRACKING_EVENT_C IN ('10','20','60','70','100','110','120','140','500','540','580','590')
-- GROUP BY ct.LOG_ID
--) ot ON orlog.LOG_ID = ot.LOG_ID
-- END "Client to Verify Selection"
--alternative to the above "client to verify selection section"
LEFT OUTER JOIN (SELECT ct.LOG_ID
,MAX(ct.PATIENT_IN_ROOM_DTTM) AS In_Room
,MAX(ct.ANESTHESIA_START_DTTM) AS Anesthesia_Start
,MAX(ct.PROCEDURE_START_DTTM) AS Incision_Start -- kcj added 5/22 per definition in clarity dictionary
,MAX(ct.PROCEDURE_COMP_DTTM) AS Incision_Close -- kcj added 5/22 per definition in clarity dictionary
--,MAX(CASE WHEN ptime.PANEL_TIME_EVENT_C = '144' THEN ptime.panel_start_time END) AS Incision_Start -- kcj removed 5/22 due to time field not being populated in clarity and alternative above meets definition criteria
--,MAX(CASE WHEN ptime.PANEL_TIME_EVENT_C = '288' THEN ptime.panel_start_time END) AS Incision_Close -- kcj removed 5/22 due to time field not being populated in clarity and alternative above meets definition criteria
,MAX(ct.ANESTHESIA_STOP_DTTM) AS Anesthesia_End
,MAX(ct.PATIENT_OUT_ROOM_DTTM) AS Out_of_Room
,MAX(ct.PATIENT_IN_RECOVERY_DTTM) AS In_Recovery
,MAX(ct.PATIENT_OUT_RECOVERY_DTTM) AS Out_Recovery
FROM [source_uwhealth].epic_V_LOG_TIMING_EVENTS_cur ct
LEFT OUTER JOIN [source_uwhealth].epic_OR_LOG_PANEL_TIME1_cur ptime ON ct.log_id = ptime.log_id
GROUP BY ct.LOG_ID
) ot ON orlog.LOG_ID = ot.LOG_ID
-- Determine Most Recent "PostDate" and use/share globally in script
LEFT OUTER JOIN (SELECT olat.LOG_ID, MAX(olat.AUDIT_DATE) OVER(PARTITION BY olat.LOG_ID ORDER BY olat.LOG_ID, olat.AUDIT_DATE desc) AS PostDate
 FROM [source_uwhealth].epic_or_log_AUDIT_TRAIL_cur olat 
 WHERE olat.AUDIT_ACTION_C = '7'
) olat2 ON orlog.LOG_ID = olat2.LOG_ID
-- Billing ICDs 
      -- Primary Physician 
      LEFT OUTER JOIN [source_uwhealth].epic_HSP_ACCT_PX_LIST_cur hap1 on har.HSP_ACCOUNT_ID = hap1.HSP_ACCOUNT_ID AND serlog1.PROV_ID = hap1.PROC_PERF_PROV_ID AND hap1.PROC_DATE BETWEEN DATEADD(DAY, -3, orlog.SURGERY_DATE) AND DATEADD(DAY, 3, orlog.SURGERY_DATE)
      LEFT OUTER JOIN [source_uwhealth].epic_CL_ICD_PX_cur px1 ON hap1.FINAL_ICD_PX_ID = px1.ICD_PX_ID     
      -- Assisting Physician 
LEFT OUTER JOIN [source_uwhealth].epic_HSP_ACCT_PX_LIST_cur hap2 on har.HSP_ACCOUNT_ID = hap2.HSP_ACCOUNT_ID AND serlog2.PROV_ID = hap2.PROC_PERF_PROV_ID AND hap2.PROC_DATE BETWEEN DATEADD(DAY, -3, orlog.SURGERY_DATE) AND DATEADD(DAY, 3, orlog.SURGERY_DATE)
      LEFT OUTER JOIN [source_uwhealth].epic_CL_ICD_PX_cur px2 ON hap2.FINAL_ICD_PX_ID = px2.ICD_PX_ID
      -- Resident Assisting Physician
LEFT OUTER JOIN [source_uwhealth].epic_HSP_ACCT_PX_LIST_cur hap3 on har.HSP_ACCOUNT_ID = hap3.HSP_ACCOUNT_ID AND serlog3.PROV_ID = hap3.PROC_PERF_PROV_ID AND hap3.PROC_DATE BETWEEN DATEADD(DAY, -3, orlog.SURGERY_DATE) AND DATEADD(DAY, 3, orlog.SURGERY_DATE)
      LEFT OUTER JOIN [source_uwhealth].epic_CL_ICD_PX_cur px3 ON hap3.FINAL_ICD_PX_ID = px3.ICD_PX_ID

WHERE
-- Dates passed from @Variables above set based upon request (On-Boarding, Baseline/Historical or Ongoing Refreshes)

-- Opt1 OnBoarding, Baseline/Historical or Ongoing Refresh (***** Monthly *****) Logic

--CONVERT(varchar,orlog.SURGERY_DATE,112) >= @StartDate AND CONVERT(varchar,orlog.SURGERY_DATE,112) < DATEADD(DAY, 1, @EndDate)
--orlog.SURGERY_DATE >= '7/1/2021' AND orlog.SURGERY_DATE <  '8/1/2021' Commenting 06/04/2024
-- Opt2 Ongoing Refresh (***** Daily *****) Logic

-- CONVERT(varchar,orlog.SURGERY_DATE,112) = CONVERT(varchar,GETDATE()-1,112)


-- Exclude 'test' patients in production database
--AND 
(pat3.IS_TEST_PAT_YN IS NULL OR pat3.IS_TEST_PAT_YN = 'N')
AND patient.PAT_MRN_ID NOT LIKE 'ZZ%'

-- Selection of Patient Types for "Inpatient"
AND har.ACCT_CLASS_HA_C IN ('2','6','8') 
AND id.IDENTITY_TYPE_ID = '0'

-- BEGIN Facility Selection--default is all
AND har.SERV_AREA_ID IN ('10000')
AND orlog.LOC_ID NOT IN ('88600','99600')
AND orlog.ROOM_ID NOT IN ('692742','692743','692744','692745','692746','692747','692748','692749','692875','692876','692877','693301','693326','695241','695382','695383') --APC rooms to be excluded because many noninvasive procedures and others that are causing data quality concerns
AND orlog.ROOM_ID NOT IN ('693288','695076') -- RN Out rooms that are often non-invasive procedures
--AND har.LOC_ID IN ('37000')
--AND (flb.DEPARTMENT_ID LIKE '3%' OR cd2.DEPARTMENT_NAME LIKE '%TAC%' OR ser_room.PROV_NAME LIKE '%TAC%')
--(SELECT LOC_ID FROM CLARITY_LOC
--WHERE LOCATION_ABBR like '%PVH%')
-- END Facility Selection   ********** PS, there is another "BEGIN Facility Selection--default is all" *************** SEE BELOW  **************** 

--AND orlog.CASE_ID = 672916
--
--
--***********************************************************************************************************************************************************************************************
--***********************************************************************************************************************************************************************************************
--
UNION
--
--***********************************************************************************************************************************************************************************************
--***********************************************************************************************************************************************************************************************
--
--Begin CPT


SELECT
'520098' as "Medicare Provider ID"
,COALESCE(CAST(har.LOC_ID as varchar(18)), '') as "Sub-Facility ID"
,'40357' as "Member ID"
,COALESCE(CAST(har.HSP_ACCOUNT_ID as varchar(18)), '') as "Encounter ID"
,COALESCE(CAST(id.IDENTITY_ID as varchar(25)), '') as "Patient ID"
,COALESCE(orlog.CASE_ID, '') as "PROCEDURAL CASE NUMBER"
,COALESCE(CAST(CONVERT(nchar(8), orlog.SURGERY_DATE,112) as varchar(112)),'') AS "Date of Service"
,COALESCE(CAST(CONVERT(nchar(8), patient.BIRTH_DATE,112) as varchar(112)),'') AS "Date of Birth"
,flb.DEPARTMENT_ID as "HCO DEPARTMENT CODE"
,cd2.DEPARTMENT_NAME as "HCO DEPARTMENT DESCRIPTION"
,CASE WHEN patient.SEX_C = '1' THEN '2'
 WHEN patient.SEX_C = '2' THEN '1'
 ELSE '3'
END as "SEX"
--,COALESCE(zoor.TITLE, '') as "PROCEDURE LOCATION"-- BJ: 08/10/18
,'' as "PROCEDURE LOCATION"
,COALESCE(zocc.TITLE, '') as "CASE STATUS"-- BJ: 08/10/18

-- BEGIN "Client to Verify" Selection - compare mapped values below in table ZC_ACCT_CLASS_HA to values below, update as needed!!!!!
-- Per Ashley Petit, only account classes used are 1,2,4,5,6,8,22 and 5/22 can be broken out by if the procedure is at TSC or MSC, so everything else is coded as miscellaneous. 1 is technically inpatient, but we decided to code it as emergency since there is a bucket for it.
,CASE WHEN har.ACCT_CLASS_HA_C  ='1' THEN 'E'-- Emergency - Emergency
WHEN har.ACCT_CLASS_HA_C ='2' THEN 'I'-- Inpatient - Inpatient
WHEN har.ACCT_CLASS_HA_C ='3' THEN 'O' -- Observation - Observation
WHEN har.ACCT_CLASS_HA_C ='4' THEN 'O' -- Outpatient Short Stay - Inpatient --recoded as OP as of 3/28/2019 due to 10% cases not coming through with ICDs, but having CPTs
WHEN har.ACCT_CLASS_HA_C ='5' AND har.LOC_ID IN ('34000','34100') THEN 'F' -- Outpatient - Freestanding Ambulatory Surgery
WHEN har.ACCT_CLASS_HA_C ='5' AND har.LOC_ID NOT IN ('34000','34100') THEN 'H' -- Outpatient - Hospital-Based Ambulatory Surgery
WHEN har.ACCT_CLASS_HA_C ='6' THEN 'I' -- First Day Surgery - Inpatient
WHEN har.ACCT_CLASS_HA_C ='8' THEN 'I' -- Surgical Admit - Inpatient
WHEN har.ACCT_CLASS_HA_C ='9' THEN 'M' -- Home Health - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='10' THEN 'M'-- Take Home Med - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='11' THEN 'M'-- Home Care Services - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='12' THEN 'M'-- Specimen - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='13' THEN 'M' -- Med Flight - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='14' THEN 'M' -- Rehab Maintenance - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='15' THEN 'M' -- Group - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='16' THEN 'M' -- Therapy - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='17' THEN 'M' -- Hospice Outpt - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='18' THEN 'M' -- Hospice Inpt - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='19' THEN 'M' -- Palliative Care - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='20' THEN 'M' -- Hospice Face to Face - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='21' THEN 'M' -- Hospice Related - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='22' AND har.LOC_ID IN ('34000','34100') THEN 'F' -- Expected Stroke - Freestanding Ambulatory Surgery
WHEN har.ACCT_CLASS_HA_C ='22' AND har.LOC_ID NOT IN ('34000','34100') THEN 'H' -- Expected Stroke - Hospital-Based Ambulatory Surgery
WHEN har.ACCT_CLASS_HA_C ='23' THEN 'M' -- Newborn - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='24' THEN 'M' -- Dialysis - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='24' THEN 'M' -- Complex Care - Miscellaneous
ELSE 'M'
END as "ENCOUNTER TYPE" 
-- END "Client to Verify Selection"

---- BEGIN "Client to Verify Selection" - Case Type (coding to be modified/replaced per client)
----UW Health is hardcoding this field because all of the data will be flowing through clarity for now and the operating room is the only procedural area using clarity
--,'OR' AS "CASE TYPE" --used to do until 6/14 for uwh-madison
,CASE WHEN ser_room.PROV_NAME like '%UWHC OSC%' THEN 'HA'-- Hospital based ambulatory surgery
WHEN orlog.ROOM_ID IN ('692083','692084','693343','695239') THEN 'HS'-- Hybrid Suite
Else 'OR'
END AS "CASE TYPE"
--,CASE WHEN ser_room.PROV_NAME like '%HYBRID%' THEN 'HS'-- Hybrid Suite
--WHEN loc.LOC_NAME like '%HYBRID%' THEN 'HS'-- Hybrid Suite
--WHEN ser_room.PROV_NAME like '%ENDO%'THEN 'EN'-- Endoscopy
--WHEN loc.LOC_NAME like '%ENDO%'THEN 'EN'-- Endoscopy
--WHEN ser_room.PROV_NAME like '%GI%'THEN 'EN'-- Endoscopy
--WHEN loc.LOC_NAME like '%GI%'THEN 'EN'-- Endoscopy
--WHEN ser_room.PROV_NAME like '%IR%' 
--AND (primphys.SPECIALTY_NAME like '%Radio%' OR primphys.SPECIALTY_NAME like '%Cardio%')
---- AND left(orproc.PROC_NAME,3) = 'IR '-- Univ of Colorado only
--THEN 'IR'-- Interventional Radiology
--WHEN loc.LOC_NAME like '%IR%'
--AND (primphys.SPECIALTY_NAME like '%Radio%' OR primphys.SPECIALTY_NAME like '%Cardio%')
---- AND left(orproc.PROC_NAME,3) = 'IR '-- Univ of Colorado only
--THEN 'IR'-- Interventional Radiology
--WHEN @MemberHCOID = 'TBD'
--AND loc.LOC_NAME like '%CARDIO%'THEN 'PV'-- Peripheral Vascular -- INTEGRIS ONLY
--
--
--WHEN ser_room.PROV_NAME like '%CV%' 
--OR ser_room.PROV_NAME like '%PV%'
--OR ser_room.PROV_NAME like '%PERIPH VASC%'THEN 'PV'-- Peripheral Vascular
--WHEN loc.LOC_NAME like '%CV%' 
--OR loc.LOC_NAME like '%PV%'
--OR loc.LOC_NAME like '%PERIPH VASC%'THEN 'PV'-- Peripheral Vascular
--
--
--WHEN @MemberHCOID = 'TBD'
--AND loc.LOC_NAME like '%Invasive%'
--AND primphys.SPECIALTY_NAME like '%Electro%'THEN 'EP'-- Electrophysiology  -- INTEGRIS ONLY
--
--
--WHEN ser_room.PROV_NAME like '%HCL%' 
--AND primphys.SPECIALTY_NAME like '%Electrophysiology%' THEN 'EP'-- Electrophysiology Laboratory
--WHEN loc.LOC_NAME like '%HCL%'
--AND primphys.SPECIALTY_NAME like '%Electrophysiology%'THEN 'EP'-- Electrophysiology Laboratory
--WHEN ser_room.PROV_NAME like '% CL%' 
--AND primphys.SPECIALTY_NAME like '%Electrophysiology%'THEN 'EP'-- Electrophysiology Laboratory
--WHEN loc.LOC_NAME like '% CL%'
--AND primphys.SPECIALTY_NAME like '%Electrophysiology%'THEN 'EP'-- Electrophysiology Laboratory
--
--WHEN @MemberHCOID = 'TBD'
--AND loc.LOC_NAME like '%Invasive%'
--AND primphys.SPECIALTY_NAME like '%Cardio%'THEN 'CC'-- Cardiology -- INTEGRIS ONLY
--
--
--WHEN ser_room.PROV_NAME like '%HCL%' 
--AND primphys.SPECIALTY_NAME like '%Cardiology%'THEN 'CC'-- Cardiac Catherization Laboratory
--WHEN loc.LOC_NAME like '%HCL%'
--AND primphys.SPECIALTY_NAME like '%Cardiology%'  THEN 'CC'-- Cardiac Catherization Laboratory
--WHEN ser_room.PROV_NAME like '% CL%' 
--AND primphys.SPECIALTY_NAME like '%Cardiology%'THEN 'CC'-- Cardiac Catherization Laboratory
--WHEN loc.LOC_NAME like '% CL%' 
--AND primphys.SPECIALTY_NAME like '%Cardiology%'  THEN 'CC'-- Cardiac Catherization Laboratory
--WHEN ser_room.PROV_NAME like '%ASC%' THEN 'FA' -- FreeStanding Ambulatory Surgery Center
--WHEN loc.LOC_NAME like '%ASC%' THEN 'FA'-- FreeStanding Ambulatory Surgery Center
--WHEN ser_room.PROV_NAME like '%SDS%' THEN 'FA' -- FreeStanding Ambulatory Surgery Center
--WHEN loc.LOC_NAME like '%SDS%' THEN 'FA'-- FreeStanding Ambulatory Surgery Center
--WHEN ser_room.PROV_NAME like '%SDC%' THEN 'FA' -- FreeStanding Ambulatory Surgery Center
--WHEN loc.LOC_NAME like '%SDC%' THEN 'FA'-- FreeStanding Ambulatory Surgery Center
--
--WHEN @MemberHCOID = 'TBD'
--AND ser_room.PROV_NAME like '%IH %' THEN 'HA'-- Hospital-Based Ambulatory Surgery Center -- INTEGRIS ONLY
--WHEN @MemberHCOID = 'TBD' 
--ANDloc.LOC_NAME like '%IH %' THEN 'HA'-- Hospital-Based Ambulatory Surgery Center -- INTEGRIS ONLY
--
--
--WHEN @MemberHCOID = 'TBD'
--AND loc.LOC_NAME like '%Main OR%'THEN 'OR'-- Operating Room -- INTEGRIS ONLY
--
--
--WHEN ser_room.PROV_NAME  like '%OR%' THEN 'OR'-- Operating Room
--WHEN loc.LOC_NAME like '%OR%' THEN 'OR'-- Operating Room
--ELSE 'OT'-- Other
--END as "CASE TYPE"
--
---- END "Client to Verify Selection" 

,'' as "ROBOTICS FLAG"  
,COALESCE(CAST(orlog.ASA_RATING_C as varchar(2)), '') as "ASA PHYSICAL STATUS CLASSIFICATION"
,COALESCE(hacc.CPT_CODE, '') as "CPT Procedure Code"-- BJ: 09/28/18 --KCJ 11/14/18 removed orproccpt.OR_PROC_ID from coalesce because UW Health does not populate that table
,COALESCE(hacc.CPT_PERF_PROV_ID, serlog.PROV_ID, '') as "CPT HOSPITAL-ASSIGNED PHYSICIAN ID" -- BJ: 08/07/18 & 09/28/18
,SUBSTRING(COALESCE(CAST(hacc.CPT_MODIFIERS as varchar(2)), ''),1,2) as "CPT CODE MODIFIER_1" 
,SUBSTRING(COALESCE(CAST(hacc.CPT_MODIFIERS as varchar(2)), ''),4,2) as "CPT CODE MODIFIER_2"         
,SUBSTRING(COALESCE(CAST(hacc.CPT_MODIFIERS as varchar(2)), ''),7,2) as "CPT CODE MODIFIER_3"         
,SUBSTRING(COALESCE(CAST(hacc.CPT_MODIFIERS as varchar(2)), ''),10,2) as "CPT CODE MODIFIER_4"        
,'' as "ICD-10 PROCEDURE CODE"
,'' as "ICD-10 PROCEDURE SEQUENCE"
,'' as "ICD-10 HOSPITAL-ASSIGNED PHYSICIAN ID"
,'' as "HCO PROCEDURE CODE"
,'' as "HCO PROCEDURE DESCRIPTION"
,NULL as "HCO PROCEDURE SEQUENCE"
,'' as "HCO PROCEDURE HOSPITAL-ASSIGNED PHYSICIAN ID"
,'' as "SCHEDULED PROCEDURAL SUITE"
--,COALESCE(CAST(orlog.ROOM_ID as varchar(18)), '') as "ACTUAL PROCEDURAL SUITE"  -- BJ: 08/05/18
,COALESCE(CAST(ser_room.PROV_NAME as varchar(30)), '') as "ACTUAL PROCEDURAL SUITE" -- BJ: 08/05/15
,COALESCE(CAST(respanes.PROV_ID as varchar(18)), '') as "ANESTHESIOLOGIST PHYSICIAN ID - 1"
,'' as "ANESTHESIOLOGIST PHYSICIAN ID - 2"
,'' as "ANESTHESIOLOGIST PHYSICIAN ID - 3" 
,'' as "ANESTHESIOLOGIST PHYSICIAN ID - 4"
,COALESCE(CAST(primcirc.PROV_ID as varchar(18)), '') as "CIRCULATOR ID - 1"
,'' as "CIRCULATOR ID - 2"
,'' as "CIRCULATOR ID - 3"
,'' as "CIRCULATOR ID - 4" 
,COALESCE(primcirc.PROV_NM_CRED, '') as "CIRCULATOR NAME - 1"
,'' as "CIRCULATOR NAME - 2"
,'' as "CIRCULATOR NAME - 3"
,'' as "CIRCULATOR NAME - 4"
,COALESCE(CAST(primsurgtech.PROV_ID as varchar(18)), '') as "SCRUB TECH ID - 1"
,'' as "SCRUB TECH ID - 2"
,'' as "SCRUB TECH ID - 3"
,'' as "SCRUB TECH ID - 4"
,COALESCE(primsurgtech.PROV_NM_CRED, '') as "SCRUB TECH NAME - 1"
,'' as "SCRUB TECH NAME - 2"
,'' as "SCRUB TECH NAME - 3"
,'' as "SCRUB TECH NAME - 4"
,'' as "SURGICAL ASSISTANT ID - 1"
,'' as "SURGICAL ASSISTANT ID - 2"
,'' as "SURGICAL ASSISTANT ID - 3"
,'' as "SURGICAL ASSISTANT ID - 4" 
,'' as "SURGICAL ASSISTANT NAME - 1"
,'' as "SURGICAL ASSISTANT NAME - 2"
,'' as "SURGICAL ASSISTANT NAME - 3"
,'' as "SURGICAL ASSISTANT NAME - 4"
--,COALESCE(CAST(orlog.SCHED_START_TIME as varchar(101)), '') as 'DATE CASE SCHEDULED' - 7/24/18, updated logic (line below)...
----,COALESCE(CAST(CONVERT(nchar(8), orlog.SCHED_START_TIME,112)
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(hours from orlog.SCHED_START_TIME) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(hours from orlog.SCHED_START_TIME) as varchar(112))
----ELSE CAST(EXTRACT(hours from orlog.SCHED_START_TIME) as varchar(112))
----END
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(minutes from orlog.SCHED_START_TIME) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(minutes from orlog.SCHED_START_TIME) as varchar(112))
----ELSE CAST(EXTRACT(minutes from orlog.SCHED_START_TIME) as varchar(112))
----END 
----as varchar(112)),'') 
, FORMAT(orlog.SCHED_START_TIME,'yyyyMMddHHmm') as "DATE CASE SCHEDULED"
,CASE WHEN orc.CANCEL_REASON_C IS NOT NULL AND orc.CANCEL_COMMENTS IS NOT NULL AND ot.Incision_Start IS NULL AND ot.Incision_Close IS NULL
  THEN 'Y'
  WHEN orc.CANCEL_REASON_C IS NOT NULL AND orc.CANCEL_COMMENTS IS NULL AND ot.Incision_Start IS NULL AND ot.Incision_Close IS NULL
  THEN 'Y'
  WHEN orc.CANCEL_COMMENTS IS NOT NULL AND orc.CANCEL_REASON_C IS NULL AND ot.Incision_Start IS NULL AND ot.Incision_Close IS NULL
  THEN 'Y'
  ELSE 'N'
END as "CANCELLATION FLAG"
----,COALESCE(CAST(CONVERT(nchar(8), orlog.SCHED_START_TIME,112)
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(hours from orlog.SCHED_START_TIME) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(hours from orlog.SCHED_START_TIME) as varchar(112))
----ELSE CAST(EXTRACT(hours from orlog.SCHED_START_TIME) as varchar(112))
----END
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(minutes from orlog.SCHED_START_TIME) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(minutes from orlog.SCHED_START_TIME) as varchar(112))
----ELSE CAST(EXTRACT(minutes from orlog.SCHED_START_TIME) as varchar(112))
----END
----as varchar(112)),'') 
, FORMAT(orlog.SCHED_START_TIME,'yyyyMMddHHmm') as "SCHEDULED CASE START"
,'' as "SCHEDULED CASE END"
--,COALESCE(CAST(CONVERT(nchar(8), ot.In_Room,112)
--+
--CASE
--WHEN LENGTH(CAST(EXTRACT(hours from ot.In_Room) as varchar(112))) = 1
--THEN '0'+CAST(EXTRACT(hours from ot.In_Room) as varchar(112))
--ELSE CAST(EXTRACT(hours from ot.In_Room) as varchar(112))
--END
--+
--CASE
--WHEN LENGTH(CAST(EXTRACT(minutes from ot.In_Room) as varchar(112))) = 1
--THEN '0'+CAST(EXTRACT(minutes from ot.In_Room) as varchar(112))
--ELSE CAST(EXTRACT(minutes from ot.In_Room) as varchar(112))
--END
--as varchar(112)),'') 
, FORMAT(ot.In_Room,'yyyyMMddHHmm') AS "PATIENT IN ROOM"
----,COALESCE(CAST(CONVERT(nchar(8), ot.Anesthesia_Start,112)
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(hours from ot.Anesthesia_Start) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(hours from ot.Anesthesia_Start) as varchar(112))
----ELSE CAST(EXTRACT(hours from ot.Anesthesia_Start) as varchar(112))
----END
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(minutes from ot.Anesthesia_Start) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(minutes from ot.Anesthesia_Start) as varchar(112))
----ELSE CAST(EXTRACT(minutes from ot.Anesthesia_Start) as varchar(112))
----END
----as varchar(112)),'') 
, FORMAT(ot.Anesthesia_Start,'yyyyMMddHHmm') AS "ANESTHESIA START"
----,COALESCE(CAST(CONVERT(nchar(8), ot.Incision_Start,112)
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(hours from ot.Incision_Start) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(hours from ot.Incision_Start) as varchar(112))
----ELSE CAST(EXTRACT(hours from ot.Incision_Start) as varchar(112))
----END
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(minutes from ot.Incision_Start) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(minutes from ot.Incision_Start) as varchar(112))
----ELSE CAST(EXTRACT(minutes from ot.Incision_Start) as varchar(112))
----END
----as varchar(112)),'') 
,FORMAT(ot.Incision_Start,'yyyyMMddHHmm') AS "INCISION START"
----,COALESCE(CAST(CONVERT(nchar(8), ot.Incision_Close,112)
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(hours from ot.Incision_Close) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(hours from ot.Incision_Close) as varchar(112))
----ELSE CAST(EXTRACT(hours from ot.Incision_Close) as varchar(112))
----END
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(minutes from ot.Incision_Close) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(minutes from ot.Incision_Close) as varchar(112))
----ELSE CAST(EXTRACT(minutes from ot.Incision_Close) as varchar(112))
----END
----as varchar(112)),'') 
, FORMAT(ot.Incision_Close,'yyyyMMddHHmm') AS "INCISION CLOSE"
----,COALESCE(CAST(CONVERT(nchar(8), ot.Anesthesia_End,112)
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(hours from ot.Anesthesia_End) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(hours from ot.Anesthesia_End) as varchar(112))
----ELSE CAST(EXTRACT(hours from ot.Anesthesia_End) as varchar(112))
----END
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(minutes from ot.Anesthesia_End) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(minutes from ot.Anesthesia_End) as varchar(112))
----ELSE CAST(EXTRACT(minutes from ot.Anesthesia_End) as varchar(112))
----END
----as varchar(112)),'') 
, FORMAT(ot.Anesthesia_End,'yyyyMMddHHmm') AS "ANESTHESIA END"
----,COALESCE(CAST(CONVERT(nchar(8), ot.Out_of_Room,112)
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(hours from ot.Out_of_Room) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(hours from ot.Out_of_Room) as varchar(112))
----ELSE CAST(EXTRACT(hours from ot.Out_of_Room) as varchar(112))
----END
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(minutes from ot.Out_of_Room) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(minutes from ot.Out_of_Room) as varchar(112))
----ELSE CAST(EXTRACT(minutes from ot.Out_of_Room) as varchar(112))
----END
----as varchar(112)),'') 
, FORMAT(ot.Out_of_Room,'yyyyMMddHHmm') AS "PATIENT OUT OF ROOM"
----,COALESCE(CAST(CONVERT(nchar(8), ot.In_Recovery,112)
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(hours from ot.In_Recovery) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(hours from ot.In_Recovery) as varchar(112))
----ELSE CAST(EXTRACT(hours from ot.In_Recovery) as varchar(112))
----END
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(minutes from ot.In_Recovery) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(minutes from ot.In_Recovery) as varchar(112))
----ELSE CAST(EXTRACT(minutes from ot.In_Recovery) as varchar(112))
----END
----as varchar(112)),'') 
, FORMAT(ot.In_Recovery,'yyyyMMddHHmm') AS "RECOVERY START"
----,COALESCE(CAST(CONVERT(nchar(8), ot.Out_Recovery,112)
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(hours from ot.Out_Recovery) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(hours from ot.Out_Recovery) as varchar(112))
----ELSE CAST(EXTRACT(hours from ot.Out_Recovery) as varchar(112))
----END
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(minutes from ot.Out_Recovery) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(minutes from ot.Out_Recovery) as varchar(112))
----ELSE CAST(EXTRACT(minutes from ot.Out_Recovery) as varchar(112))
----END
----as varchar(112)),'') 
, FORMAT(ot.Out_Recovery,'yyyyMMddHHmm') AS "RECOVERY END"
----,COALESCE(CAST(CONVERT(nchar(8), olat2.PostDate,112)
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(hours from olat2.PostDate) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(hours from olat2.PostDate) as varchar(112))
----ELSE CAST(EXTRACT(hours from olat2.PostDate) as varchar(112))
----END
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(minutes from olat2.PostDate) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(minutes from olat2.PostDate) as varchar(112))
----ELSE CAST(EXTRACT(minutes from olat2.PostDate) as varchar(112))
----END
----as varchar(112)),'') 
, FORMAT(olat2.PostDate,'yyyyMMddHHmm') AS "POST DATE"

-- kcj 3/10: below datetimes replaced by above code
--
--,COALESCE(CAST(ot.IN_ROOM as varchar(112)) + SUBSTR(CAST(ot.IN_ROOM as varchar(108)),1,2) + SUBSTR(CAST(ot.IN_ROOM as varchar(108)),4,2), '') as "PATIENT IN ROOM"
--,COALESCE(CAST(ot.ANESTHESIA_START as varchar(112)) + SUBSTR(CAST(ot.ANESTHESIA_START as varchar(108)),1,2) + SUBSTR(CAST(ot.ANESTHESIA_START as varchar(108)),4,2), '') as "ANESTHESIA START"
--,COALESCE(CAST(ot.INCISION_START as varchar(112)) + SUBSTR(CAST(ot.INCISION_START as varchar(108)),1,2) + SUBSTR(CAST(ot.INCISION_START as varchar(108)),4,2), '') as "INCISION START"
--,COALESCE(CAST(ot.INCISION_CLOSE as varchar(112)) + SUBSTR(CAST(ot.INCISION_CLOSE as varchar(108)),1,2) + SUBSTR(CAST(ot.INCISION_CLOSE as varchar(108)),4,2), '') as "INCISION CLOSE"
--,COALESCE(CAST(ot.ANESTHESIA_END as varchar(112)) + SUBSTR(CAST(ot.ANESTHESIA_END as varchar(108)),1,2) + SUBSTR(CAST(ot.ANESTHESIA_END as varchar(108)),4,2), '') as "ANESTHESIA END"
--,COALESCE(CAST(ot.OUT_OF_ROOM as varchar(112)) + SUBSTR(CAST(ot.OUT_OF_ROOM as varchar(108)),1,2)+ SUBSTR(CAST(ot.OUT_OF_ROOM as varchar(108)),4,2), '') as "PATIENT OUT OF ROOM"
--,COALESCE(CAST(ot.IN_RECOVERY as varchar(112)) + SUBSTR(CAST(ot.IN_RECOVERY as varchar(108)),1,2) + SUBSTR(CAST(ot.IN_RECOVERY as varchar(108)),4,2), '') as "RECOVERY START"
--,COALESCE(CAST(ot.OUT_RECOVERY as varchar(112)) + SUBSTR(CAST(ot.OUT_RECOVERY as varchar(108)),1,2) + SUBSTR(CAST(ot.OUT_RECOVERY as varchar(108)),4,2), '') as "RECOVERY END"
--,COALESCE(CAST(olat2.PostDate as varchar(112)) + SUBSTR(CAST(olat2.PostDate as varchar(108)),1,2) + SUBSTR(CAST(olat2.PostDate as varchar(108)),4,2), '') as "POST DATE"

-- OR Mgmt System case/log records
FROM [source_uwhealth].epic_or_case_cur orc
LEFT OUTER JOIN [source_uwhealth].epic_or_log_cur orlog ON orc.LOG_ID = orlog.LOG_ID 
LEFT OUTER JOIN [source_uwhealth].epic_f_log_based_cur flb ON orlog.LOG_ID = flb.LOG_ID-- available in Clarity 2015 forward
LEFT OUTER JOIN [source_uwhealth].epic_ZC_OR_CASE_CLASS_CUR zocc ON orc.CASE_CLASS_C = zocc.CASE_CLASS_C-- BJ: 08/10/18

-- Patient info
INNER JOIN [source_uwhealth].epic_pat_or_adm_link_cur PAT_OR_ADM_LINK ON orlog.CASE_ID = PAT_OR_ADM_LINK.CASE_ID
INNER JOIN [source_uwhealth].epic_pat_enc_hsp_cur peh ON PAT_OR_ADM_LINK.OR_LINK_CSN = peh.PAT_ENC_CSN_ID
INNER JOIN [source_uwhealth].epic_PATIENT_cur patient ON orlog.PAT_ID = patient.PAT_ID
INNER JOIN [source_uwhealth].epic_HSP_ACCOUNT_cur har ON peh.HSP_ACCOUNT_ID = har.HSP_ACCOUNT_ID
INNER JOIN [source_uwhealth].epic_IDENTITY_ID_cur id ON patient.PAT_ID = id.PAT_ID

-- Procedure Scheduled/Ordered Info
LEFT OUTER JOIN [source_uwhealth].epic_or_case_ALL_PROC_cur orcap ON orc.OR_CASE_ID = orcap.OR_CASE_ID -- BJ: 9/10/18
LEFT OUTER JOIN [source_uwhealth].epic_OR_PROC_cur orproc ON orcap.OR_PROC_ID = orproc.OR_PROC_ID
--LEFT OUTER JOIN ZC_OR_OP_REGION zoor ON orproc.OPERATING_REGION_C = zoor.OPERATING_REGION_C-- BJ: 08/10/18
-- Reflecting CASE Documentation: OR_PROC_CPT_ID varies by Member (1) not populated, (2) CPT mapped 1 PROC_ID to many CPTs to hopefully (3) CPT mapped to 1 PROC_ID
--LEFT OUTER JOIN OR_PROC_CPT_ID orproccpt ON orproc.OR_PROC_ID = orproccpt.OR_PROC_ID
LEFT OUTER JOIN [source_uwhealth].epic_ZC_OR_CANCEL_RSN_cur orcrsn ON orc.CANCEL_REASON_C = orcrsn.CANCEL_REASON_C
LEFT OUTER JOIN [source_uwhealth].epic_ZC_PROC_NOT_PERF_cur zcprocnotperf ON orlog.PROC_NOT_PERF_C = zcprocnotperf.PROC_NOT_PERF_C

-- Performing Physician Info (not captured in F_LOG_BASED table)
LEFT JOIN [source_uwhealth].epic_or_log_ALL_STAFF_cur orlas on orlas.LOG_ID = orlog.LOG_ID and orlas.STAFF_TYPE_MAP_C = 1 and orlas.ROLE_C = 1 and orlas.PANEL = 1 -- and orlas.ACCOUNTBLE_STAFF_YN = 'Y'
LEFT JOIN [source_uwhealth].epic_CLARITY_SER_cur serlog on serlog.PROV_ID = orlas.STAFF_ID
    
-- Staff Name and Credentials
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur performphys on serlog.PROV_ID = performphys.PROV_ID--performing physician
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur primphys on flb.PRIMARY_PHYSICIAN_ID = primphys.PROV_ID--primary physician
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur secondphys on flb.SECONDARY_PHYSICIAN_ID = secondphys.PROV_ID--secondary physician
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur primcirc on flb.PRIMARY_CIRCULATOR_ID = primcirc.PROV_ID--primary circulator
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur primsurgtech on flb.PRIMARY_SURG_TECH_ID = primsurgtech.PROV_ID--primary surgical technician
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur primprern on flb.PRIMARY_PREOP_NURSE_ID = primprern.PROV_ID--primary preop nurse
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur primrecrn on flb.PRIMARY_RECOVERY_NURSE_ID = primrecrn.PROV_ID--primary recovery nurse
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur primphaseiirn on flb.PRIMARY_PHASEII_NURSE_ID = primphaseiirn.PROV_ID--primary phase II nurse
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur respanes on flb.RESP_ANES_ID = respanes.PROV_ID--responsible anesthesia provider
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur firstanes on flb.FIRST_ANES_ID = firstanes.PROV_ID--first anesthesia provider


-- Exclude test paitients in WHERE clause
LEFT OUTER JOIN [source_uwhealth].epic_PATIENT_3_cur pat3 ON patient.PAT_ID = pat3.PAT_ID


/* BJ: replaced with D_PROV_PRIMARY_HIERARCHY, code to be removed shortly!!!
-- Anesthesiologist Info
LEFT OUTER JOIN (SELECT astf.LOG_ID, astaff.ANESTH_STAFF_ID AS ANESTHESIOLOGIST_PROV_ID, ser.PROV_NAME AS ANESTHESIOLOGIST
 FROM OR_LOG_LN_ANESSTAF astf
LEFT OUTER JOIN OR_LNLG_ANES_STAFF astaff ON astf.ANESTHESIA_STAFF_I = astaff.RECORD_ID
LEFT OUTER JOIN ZC_OR_ANSTAFF_TYPE atp ON astaff.ANESTH_STAFF_C = atp.ANEST_STAFF_REQ_C  
LEFT OUTER JOIN CLARITY_SER ser ON astaff.ANESTH_STAFF_ID = ser.PROV_ID
 WHERE atp.ANEST_STAFF_REQ_C = 10 AND astf.LINE = (SELECT MIN(a.LINE)
   FROM OR_LOG_LN_ANESSTAF a
   WHERE a.LOG_ID = astf.LOG_ID)
) an ON orlog.LOG_ID = an.LOG_ID
*/

-- OR Room Info
LEFT OUTER JOIN [source_uwhealth].epic_CLARITY_SER_cur ser_room ON orlog.ROOM_ID = ser_room.PROV_ID
LEFT OUTER JOIN [source_uwhealth].epic_CLARITY_LOC_cur loc on orlog.LOC_ID = loc.LOC_ID
 
--Department
LEFT OUTER JOIN [source_uwhealth].epic_CLARITY_DEP_cur cd2 ON flb.DEPARTMENT_ID = cd2.DEPARTMENT_ID



-- BEGIN "Client to Verify Selection" - OR Times (possibly custom built per client) in table ZC_OR_PAT_EVENTS
-- OR TIME parameters for TRACKING EVENTs & PANEL TIME EVENTs found in tables: [OR_LOG_CASE_TIMES and OR_LOG_PANEL_TIME1]

--LEFT OUTER JOIN (SELECT ct.LOG_ID
-- ,MAX(CASE WHEN ct.TRACKING_EVENT_C = '432' THEN ct.TRACKING_TIME_IN END) AS In_Room-- In Surgical Room
-- ,MAX(CASE WHEN ct.TRACKING_EVENT_C = '576' THEN ct.TRACKING_TIME_IN END) AS Anesthesia_Start-- Anesthesia Begins
-- ,MAX(CASE WHEN ptime.PANEL_TIME_EVENT_C = '144' THEN ptime.panel_start_time END) AS Incision_Start-- Incision Open
-- ,MAX(CASE WHEN ptime.PANEL_TIME_EVENT_C = '288' THEN ptime.panel_start_time END) AS Incision_Close-- Incision Closed
-- ,MAX(CASE WHEN ct.TRACKING_EVENT_C = '1008' THEN ct.TRACKING_TIME_IN END) AS Anesthesia_End-- Anesthesia End
-- ,MAX(CASE WHEN ct.TRACKING_EVENT_C = '1152' THEN ct.TRACKING_TIME_IN END) AS Out_of_Room-- Out of Surgical Room
-- ,MAX(CASE WHEN ct.TRACKING_EVENT_C IN ('1296') THEN ct.TRACKING_TIME_IN END) AS In_Recovery-- In Recovery (PACU)
-- ,MAX(CASE WHEN ct.TRACKING_EVENT_C IN ('1584') THEN ct.TRACKING_TIME_IN END) AS Out_Recovery-- Out Recovery (PACU)
-- FROM OR_LOG_CASE_TIMES ct 
--LEFT OUTER JOIN OR_LOG_PANEL_TIME1 ptime ON ct.log_id = ptime.log_id
-- WHERE ct.TRACKING_EVENT_C IN ('10','20','60','70','100','110','120','140','500','540','580','590')
-- GROUP BY ct.LOG_ID
--) ot ON orlog.LOG_ID = ot.LOG_ID
-- END "Client to Verify Selection"
--alternative to the above
LEFT OUTER JOIN (SELECT ct.LOG_ID
,MAX(ct.PATIENT_IN_ROOM_DTTM) AS In_Room
,MAX(ct.ANESTHESIA_START_DTTM) AS Anesthesia_Start
,MAX(ct.PROCEDURE_START_DTTM) AS Incision_Start -- kcj added 5/22 per definition in clarity dictionary
,MAX(ct.PROCEDURE_COMP_DTTM) AS Incision_Close -- kcj added 5/22 per definition in clarity dictionary
--,MAX(CASE WHEN ptime.PANEL_TIME_EVENT_C = '144' THEN ptime.panel_start_time END) AS Incision_Start -- kcj removed 5/22 due to time field not being populated in clarity and alternative above meets definition criteria
--,MAX(CASE WHEN ptime.PANEL_TIME_EVENT_C = '288' THEN ptime.panel_start_time END) AS Incision_Close -- kcj removed 5/22 due to time field not being populated in clarity and alternative above meets definition criteria
,MAX(ct.ANESTHESIA_STOP_DTTM) AS Anesthesia_End
,MAX(ct.PATIENT_OUT_ROOM_DTTM) AS Out_of_Room
,MAX(ct.PATIENT_IN_RECOVERY_DTTM) AS In_Recovery
,MAX(ct.PATIENT_OUT_RECOVERY_DTTM) AS Out_Recovery
FROM [source_uwhealth].epic_V_LOG_TIMING_EVENTS_cur ct
LEFT OUTER JOIN [source_uwhealth].epic_OR_LOG_PANEL_TIME1_cur ptime ON ct.log_id = ptime.log_id
GROUP BY ct.LOG_ID
) ot ON orlog.LOG_ID = ot.LOG_ID

-- Determine Most Recent "PostDate" and use/share globally in script
LEFT OUTER JOIN (SELECT olat.LOG_ID, MAX(olat.AUDIT_DATE) OVER(PARTITION BY olat.LOG_ID ORDER BY olat.LOG_ID, olat.AUDIT_DATE desc) AS PostDate
 FROM [source_uwhealth].epic_or_log_AUDIT_TRAIL_cur olat 
 WHERE olat.AUDIT_ACTION_C = '7'
) olat2 ON orlog.LOG_ID = olat2.LOG_ID
-- Billing CPTs
     LEFT OUTER JOIN [source_uwhealth].epic_HSP_ACCT_CPT_CODES_cur hacc ON ((har.HSP_ACCOUNT_ID = hacc.HSP_ACCOUNT_ID ) and (hacc.CPT_CODE_DATE between orlog.SURGERY_DATE and dateadd(day,1,hacc.CPT_CODE_DATE))) -- +1 day for cases running past midnight into next day.
     
WHERE
-- Dates passed from @Variables above set based upon request (On-Boarding, Baseline/Historical or Ongoing Refreshes)

-- Opt1 OnBoarding, Baseline/Historical or Ongoing Refresh (***** Monthly *****) Logic

--CONVERT(varchar,orlog.SURGERY_DATE,112) >= @StartDate AND CONVERT(varchar,orlog.SURGERY_DATE,112) < DATEADD(DAY, 1, @EndDate)
--orlog.SURGERY_DATE >= '7/1/2021' AND orlog.SURGERY_DATE < '8/1/2021' COmmenting 06/04/2024
-- Opt2 Ongoing Refresh (***** Daily *****) Logic

-- CONVERT(varchar,orlog.SURGERY_DATE,112) = CONVERT(varchar,GETDATE()-1,112)

-- Exclude 'test' patients in production database
--AND 
(pat3.IS_TEST_PAT_YN IS NULL OR pat3.IS_TEST_PAT_YN = 'N')
AND patient.PAT_MRN_ID NOT LIKE 'ZZ%'

-- Selection of Patient Types for "Non-Inpatient"
AND har.ACCT_CLASS_HA_C NOT IN ('2','6','8') 
AND id.IDENTITY_TYPE_ID = '0'

--AND orproc.OR_PROC_ID is not null

-- BEGIN Facility Selection--default is all
AND har.SERV_AREA_ID IN ('10000')
AND orlog.LOC_ID NOT IN ('88600','99600') --OOR cases at UWH-Madison
AND orlog.ROOM_ID NOT IN ('692742','692743','692744','692745','692746','692747','692748','692749','692875','692876','692877','693301','693326','695241','695382','695383') --APC rooms to be excluded because many noninvasive procedures and others that are causing data quality concerns
AND orlog.ROOM_ID NOT IN ('693288','695076') -- RN Out rooms that are often non-invasive procedures
--AND har.LOC_ID IN ('37000')
--AND (flb.DEPARTMENT_ID LIKE '3%' OR cd2.DEPARTMENT_NAME LIKE '%TAC%' OR ser_room.PROV_NAME LIKE '%TAC%')
--(SELECT LOC_ID FROM CLARITY_LOC
--WHERE LOCATION_ABBR like '%PVH%')
-- END Facility Selection
--
--
--***********************************************************************************************************************************************************************************************
--***********************************************************************************************************************************************************************************************
--
UNION
--
--***********************************************************************************************************************************************************************************************
--***********************************************************************************************************************************************************************************************
--
--


SELECT
'520098' as "Medicare Provider ID"
,COALESCE(CAST(har.LOC_ID as varchar(18)), '') as "Sub-Facility ID"
,'40357' as "Member ID"
,COALESCE(CAST(har.HSP_ACCOUNT_ID as varchar(18)), '') as "Encounter ID"
,COALESCE(CAST(id.IDENTITY_ID as varchar(25)), '') as "Patient ID"
,COALESCE(orlog.CASE_ID, '') as "PROCEDURAL CASE NUMBER"
,COALESCE(CAST(CONVERT(nchar(8), orlog.SURGERY_DATE,112) as varchar(112)),'') AS "Date of Service"
,COALESCE(CAST(CONVERT(nchar(8), patient.BIRTH_DATE,112) as varchar(112)),'') AS "Date of Birth"
,flb.DEPARTMENT_ID as "HCO DEPARTMENT CODE"
,cd2.DEPARTMENT_NAME as "HCO DEPARTMENT DESCRIPTION"
,CASE WHEN patient.SEX_C = '1' THEN '2'
 WHEN patient.SEX_C = '2' THEN '1'
 ELSE '3'
END as "SEX"
--,COALESCE(zoor.TITLE, '') as "PROCEDURE LOCATION"-- BJ: 08/10/18
,'' as "PROCEDURE LOCATION"
,COALESCE(zocc.TITLE, '') as "CASE STATUS"-- BJ: 08/10/18

-- BEGIN "Client to Verify" Selection - compare mapped values below in table ZC_ACCT_CLASS_HA to values below, update as needed!!!!!
-- Per Ashley Petit, only account classes used are 1,2,4,5,6,8,22 and 5/22 can be broken out by if the procedure is at TSC or MSC, so everything else is coded as miscellaneous. 1 is technically inpatient, but we decided to code it as emergency since there is a bucket for it.
,CASE WHEN har.ACCT_CLASS_HA_C  ='1' THEN 'E'-- Emergency - Emergency
WHEN har.ACCT_CLASS_HA_C ='2' THEN 'I'-- Inpatient - Inpatient
WHEN har.ACCT_CLASS_HA_C ='3' THEN 'O' -- Observation - Observation
WHEN har.ACCT_CLASS_HA_C ='4' THEN 'O' -- Outpatient Short Stay - Inpatient --recoded as OP as of 3/28/2019 due to 10% cases not coming through with ICDs, but having CPTs
WHEN har.ACCT_CLASS_HA_C ='5' AND har.LOC_ID IN ('34000','34100') THEN 'F' -- Outpatient - Freestanding Ambulatory Surgery
WHEN har.ACCT_CLASS_HA_C ='5' AND har.LOC_ID NOT IN ('34000','34100') THEN 'H' -- Outpatient - Hospital-Based Ambulatory Surgery
WHEN har.ACCT_CLASS_HA_C ='6' THEN 'I' -- First Day Surgery - Inpatient
WHEN har.ACCT_CLASS_HA_C ='8' THEN 'I' -- Surgical Admit - Inpatient
WHEN har.ACCT_CLASS_HA_C ='9' THEN 'M' -- Home Health - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='10' THEN 'M'-- Take Home Med - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='11' THEN 'M'-- Home Care Services - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='12' THEN 'M'-- Specimen - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='13' THEN 'M' -- Med Flight - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='14' THEN 'M' -- Rehab Maintenance - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='15' THEN 'M' -- Group - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='16' THEN 'M' -- Therapy - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='17' THEN 'M' -- Hospice Outpt - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='18' THEN 'M' -- Hospice Inpt - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='19' THEN 'M' -- Palliative Care - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='20' THEN 'M' -- Hospice Face to Face - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='21' THEN 'M' -- Hospice Related - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='22' AND har.LOC_ID IN ('34000','34100') THEN 'F' -- Expected Stroke - Freestanding Ambulatory Surgery
WHEN har.ACCT_CLASS_HA_C ='22' AND har.LOC_ID NOT IN ('34000','34100') THEN 'H' -- Expected Stroke - Hospital-Based Ambulatory Surgery
WHEN har.ACCT_CLASS_HA_C ='23' THEN 'M' -- Newborn - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='24' THEN 'M' -- Dialysis - Miscellaneous
WHEN har.ACCT_CLASS_HA_C ='24' THEN 'M' -- Complex Care - Miscellaneous
ELSE 'M'
END as "ENCOUNTER TYPE" 
-- END "Client to Verify Selection"

---- BEGIN "Client to Verify Selection" - Case Type (coding to be modified/replaced per client)
----UW Health is hardcoding this field because all of the data will be flowing through clarity for now and the operating room is the only procedural area using clarity
--,'OR' AS "CASE TYPE" --used to do for w-madison until 6/14
,CASE WHEN ser_room.PROV_NAME like '%UWHC OSC%' THEN 'HA'-- Hospital based ambulatory surgery
WHEN orlog.ROOM_ID IN ('692083','692084','693343','695239') THEN 'HS'-- Hybrid Suite
Else 'OR'
END AS "CASE TYPE"
--,CASE WHEN ser_room.PROV_NAME like '%HYBRID%' THEN 'HS'-- Hybrid Suite
--WHEN loc.LOC_NAME like '%HYBRID%' THEN 'HS'-- Hybrid Suite
--WHEN ser_room.PROV_NAME like '%ENDO%'THEN 'EN'-- Endoscopy
--WHEN loc.LOC_NAME like '%ENDO%'THEN 'EN'-- Endoscopy
--WHEN ser_room.PROV_NAME like '%GI%'THEN 'EN'-- Endoscopy
--WHEN loc.LOC_NAME like '%GI%'THEN 'EN'-- Endoscopy
--WHEN ser_room.PROV_NAME like '%IR%' 
--AND (primphys.SPECIALTY_NAME like '%Radio%' OR primphys.SPECIALTY_NAME like '%Cardio%')
---- AND left(orproc.PROC_NAME,3) = 'IR '-- Univ of Colorado only
--THEN 'IR'-- Interventional Radiology
--WHEN loc.LOC_NAME like '%IR%'
--AND (primphys.SPECIALTY_NAME like '%Radio%' OR primphys.SPECIALTY_NAME like '%Cardio%')
---- AND left(orproc.PROC_NAME,3) = 'IR '-- Univ of Colorado only
--THEN 'IR'-- Interventional Radiology
--WHEN @MemberHCOID = 'TBD'
--AND loc.LOC_NAME like '%CARDIO%'THEN 'PV'-- Peripheral Vascular -- INTEGRIS ONLY
--
--
--WHEN ser_room.PROV_NAME like '%CV%' 
--OR ser_room.PROV_NAME like '%PV%'
--OR ser_room.PROV_NAME like '%PERIPH VASC%'THEN 'PV'-- Peripheral Vascular
--WHEN loc.LOC_NAME like '%CV%' 
--OR loc.LOC_NAME like '%PV%'
--OR loc.LOC_NAME like '%PERIPH VASC%'THEN 'PV'-- Peripheral Vascular
--
--
--WHEN @MemberHCOID = 'TBD'
--AND loc.LOC_NAME like '%Invasive%'
--AND primphys.SPECIALTY_NAME like '%Electro%'THEN 'EP'-- Electrophysiology  -- INTEGRIS ONLY
--
--
--WHEN ser_room.PROV_NAME like '%HCL%' 
--AND primphys.SPECIALTY_NAME like '%Electrophysiology%' THEN 'EP'-- Electrophysiology Laboratory
--WHEN loc.LOC_NAME like '%HCL%'
--AND primphys.SPECIALTY_NAME like '%Electrophysiology%'THEN 'EP'-- Electrophysiology Laboratory
--WHEN ser_room.PROV_NAME like '% CL%' 
--AND primphys.SPECIALTY_NAME like '%Electrophysiology%'THEN 'EP'-- Electrophysiology Laboratory
--WHEN loc.LOC_NAME like '% CL%'
--AND primphys.SPECIALTY_NAME like '%Electrophysiology%'THEN 'EP'-- Electrophysiology Laboratory
--
--WHEN @MemberHCOID = 'TBD'
--AND loc.LOC_NAME like '%Invasive%'
--AND primphys.SPECIALTY_NAME like '%Cardio%'THEN 'CC'-- Cardiology -- INTEGRIS ONLY
--
--
--WHEN ser_room.PROV_NAME like '%HCL%' 
--AND primphys.SPECIALTY_NAME like '%Cardiology%'THEN 'CC'-- Cardiac Catherization Laboratory
--WHEN loc.LOC_NAME like '%HCL%'
--AND primphys.SPECIALTY_NAME like '%Cardiology%'  THEN 'CC'-- Cardiac Catherization Laboratory
--WHEN ser_room.PROV_NAME like '% CL%' 
--AND primphys.SPECIALTY_NAME like '%Cardiology%'THEN 'CC'-- Cardiac Catherization Laboratory
--WHEN loc.LOC_NAME like '% CL%' 
--AND primphys.SPECIALTY_NAME like '%Cardiology%'  THEN 'CC'-- Cardiac Catherization Laboratory
--WHEN ser_room.PROV_NAME like '%ASC%' THEN 'FA' -- FreeStanding Ambulatory Surgery Center
--WHEN loc.LOC_NAME like '%ASC%' THEN 'FA'-- FreeStanding Ambulatory Surgery Center
--WHEN ser_room.PROV_NAME like '%SDS%' THEN 'FA' -- FreeStanding Ambulatory Surgery Center
--WHEN loc.LOC_NAME like '%SDS%' THEN 'FA'-- FreeStanding Ambulatory Surgery Center
--WHEN ser_room.PROV_NAME like '%SDC%' THEN 'FA' -- FreeStanding Ambulatory Surgery Center
--WHEN loc.LOC_NAME like '%SDC%' THEN 'FA'-- FreeStanding Ambulatory Surgery Center
--
--WHEN @MemberHCOID = 'TBD'
--AND ser_room.PROV_NAME like '%IH %' THEN 'HA'-- Hospital-Based Ambulatory Surgery Center -- INTEGRIS ONLY
--WHEN @MemberHCOID = 'TBD' 
--ANDloc.LOC_NAME like '%IH %' THEN 'HA'-- Hospital-Based Ambulatory Surgery Center -- INTEGRIS ONLY
--
--
--WHEN @MemberHCOID = 'TBD'
--AND loc.LOC_NAME like '%Main OR%'THEN 'OR'-- Operating Room -- INTEGRIS ONLY
--
--
--WHEN ser_room.PROV_NAME  like '%OR%' THEN 'OR'-- Operating Room
--WHEN loc.LOC_NAME like '%OR%' THEN 'OR'-- Operating Room
--ELSE 'OT'-- Other
--END as "CASE TYPE"
--
---- END "Client to Verify Selection" 

,'' as "ROBOTICS FLAG"  
,COALESCE(CAST(orlog.ASA_RATING_C as varchar(2)), '') as "ASA PHYSICAL STATUS CLASSIFICATION"
,'' as "CPT Procedure Code"-- BJ: 09/28/18 --KCJ 11/14/18 removed orproccpt.OR_PROC_ID from coalesce because UW Health does not populate that table
,'' as "CPT HOSPITAL-ASSIGNED PHYSICIAN ID" -- BJ: 08/07/18 & 09/28/18
,'' as "CPT CODE MODIFIER_1" 
,'' as "CPT CODE MODIFIER_2"         
,'' as "CPT CODE MODIFIER_3"         
,'' as "CPT CODE MODIFIER_4"        
,'' as "ICD-10 PROCEDURE CODE"
,'' as "ICD-10 PROCEDURE SEQUENCE"
,'' as "ICD-10 HOSPITAL-ASSIGNED PHYSICIAN ID"
,COALESCE(orproc2.OR_PROC_ID, '') as "HCO PROCEDURE CODE"
,COALESCE(orproc2.PROC_NAME, '') as "HCO PROCEDURE DESCRIPTION"
,COALESCE(olaproc.LINE,NULL) as "HCO PROCEDURE SEQUENCE"
,COALESCE(CAST(performphys.PROV_ID as varchar(18)), '') as "HCO PROCEDURE HOSPITAL-ASSIGNED PHYSICIAN ID"
,'' as "SCHEDULED PROCEDURAL SUITE"
--,COALESCE(CAST(orlog.ROOM_ID as varchar(18)), '') as "ACTUAL PROCEDURAL SUITE"  -- BJ: 08/05/18
,COALESCE(CAST(ser_room.PROV_NAME as varchar(18)), '') as "ACTUAL PROCEDURAL SUITE" -- BJ: 08/05/15
,COALESCE(CAST(respanes.PROV_ID as varchar(18)), '') as "ANESTHESIOLOGIST PHYSICIAN ID - 1"
,'' as "ANESTHESIOLOGIST PHYSICIAN ID - 2"
,'' as "ANESTHESIOLOGIST PHYSICIAN ID - 3" 
,'' as "ANESTHESIOLOGIST PHYSICIAN ID - 4"
,COALESCE(CAST(primcirc.PROV_ID as varchar(18)), '') as "CIRCULATOR ID - 1"
,'' as "CIRCULATOR ID - 2"
,'' as "CIRCULATOR ID - 3"
,'' as "CIRCULATOR ID - 4" 
,COALESCE(primcirc.PROV_NM_CRED, '') as "CIRCULATOR NAME - 1"
,'' as "CIRCULATOR NAME - 2"
,'' as "CIRCULATOR NAME - 3"
,'' as "CIRCULATOR NAME - 4"
,COALESCE(CAST(primsurgtech.PROV_ID as varchar(18)), '') as "SCRUB TECH ID - 1"
,'' as "SCRUB TECH ID - 2"
,'' as "SCRUB TECH ID - 3"
,'' as "SCRUB TECH ID - 4"
,COALESCE(primsurgtech.PROV_NM_CRED, '') as "SCRUB TECH NAME - 1"
,'' as "SCRUB TECH NAME - 2"
,'' as "SCRUB TECH NAME - 3"
,'' as "SCRUB TECH NAME - 4"
,'' as "SURGICAL ASSISTANT ID - 1"
,'' as "SURGICAL ASSISTANT ID - 2"
,'' as "SURGICAL ASSISTANT ID - 3"
,'' as "SURGICAL ASSISTANT ID - 4" 
,'' as "SURGICAL ASSISTANT NAME - 1"
,'' as "SURGICAL ASSISTANT NAME - 2"
,'' as "SURGICAL ASSISTANT NAME - 3"
,'' as "SURGICAL ASSISTANT NAME - 4"
--,COALESCE(CAST(orlog.SCHED_START_TIME as varchar(101)), '') as 'DATE CASE SCHEDULED' - 7/24/18, updated logic (line below)...
----,COALESCE(CAST(CONVERT(nchar(8), orlog.SCHED_START_TIME,112)
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(hours from orlog.SCHED_START_TIME) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(hours from orlog.SCHED_START_TIME) as varchar(112))
----ELSE CAST(EXTRACT(hours from orlog.SCHED_START_TIME) as varchar(112))
----END
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(minutes from orlog.SCHED_START_TIME) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(minutes from orlog.SCHED_START_TIME) as varchar(112))
----ELSE CAST(EXTRACT(minutes from orlog.SCHED_START_TIME) as varchar(112))
----END 
----as varchar(112)),'') 
, FORMAT(orlog.SCHED_START_TIME,'yyyyMMddHHmm') as "DATE CASE SCHEDULED"
,CASE WHEN orc.CANCEL_REASON_C IS NOT NULL AND orc.CANCEL_COMMENTS IS NOT NULL AND ot.Incision_Start IS NULL AND ot.Incision_Close IS NULL
  THEN 'Y'
  WHEN orc.CANCEL_REASON_C IS NOT NULL AND orc.CANCEL_COMMENTS IS NULL AND ot.Incision_Start IS NULL AND ot.Incision_Close IS NULL
  THEN 'Y'
  WHEN orc.CANCEL_COMMENTS IS NOT NULL AND orc.CANCEL_REASON_C IS NULL AND ot.Incision_Start IS NULL AND ot.Incision_Close IS NULL
  THEN 'Y'
  ELSE 'N'
END as "CANCELLATION FLAG"
----,COALESCE(CAST(CONVERT(nchar(8), orlog.SCHED_START_TIME,112)
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(hours from orlog.SCHED_START_TIME) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(hours from orlog.SCHED_START_TIME) as varchar(112))
----ELSE CAST(EXTRACT(hours from orlog.SCHED_START_TIME) as varchar(112))
----END
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(minutes from orlog.SCHED_START_TIME) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(minutes from orlog.SCHED_START_TIME) as varchar(112))
----ELSE CAST(EXTRACT(minutes from orlog.SCHED_START_TIME) as varchar(112))
----END
----as varchar(112)),'') 
, FORMAT(orlog.SCHED_START_TIME,'yyyyMMddHHmm') as "SCHEDULED CASE START"
,'' as "SCHEDULED CASE END"
----,COALESCE(CAST(CONVERT(nchar(8), ot.In_Room,112)
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(hours from ot.In_Room) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(hours from ot.In_Room) as varchar(112))
----ELSE CAST(EXTRACT(hours from ot.In_Room) as varchar(112))
----END
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(minutes from ot.In_Room) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(minutes from ot.In_Room) as varchar(112))
----ELSE CAST(EXTRACT(minutes from ot.In_Room) as varchar(112))
----END
----as varchar(112)),'') 
, FORMAT(ot.In_Room,'yyyyMMddHHmm') AS "PATIENT IN ROOM"
----,COALESCE(CAST(CONVERT(nchar(8), ot.Anesthesia_Start,112)
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(hours from ot.Anesthesia_Start) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(hours from ot.Anesthesia_Start) as varchar(112))
----ELSE CAST(EXTRACT(hours from ot.Anesthesia_Start) as varchar(112))
----END
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(minutes from ot.Anesthesia_Start) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(minutes from ot.Anesthesia_Start) as varchar(112))
----ELSE CAST(EXTRACT(minutes from ot.Anesthesia_Start) as varchar(112))
----END
----as varchar(112)),'') 
, FORMAT(ot.Anesthesia_Start,'yyyyMMddHHmm') AS "ANESTHESIA START"
----,COALESCE(CAST(CONVERT(nchar(8), ot.Incision_Start,112)
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(hours from ot.Incision_Start) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(hours from ot.Incision_Start) as varchar(112))
----ELSE CAST(EXTRACT(hours from ot.Incision_Start) as varchar(112))
----END
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(minutes from ot.Incision_Start) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(minutes from ot.Incision_Start) as varchar(112))
----ELSE CAST(EXTRACT(minutes from ot.Incision_Start) as varchar(112))
----END
----as varchar(112)),'')
, FORMAT(ot.Incision_Start,'yyyyMMddHHmm') AS "INCISION START"
----,COALESCE(CAST(CONVERT(nchar(8), ot.Incision_Close,112)
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(hours from ot.Incision_Close) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(hours from ot.Incision_Close) as varchar(112))
----ELSE CAST(EXTRACT(hours from ot.Incision_Close) as varchar(112))
----END
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(minutes from ot.Incision_Close) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(minutes from ot.Incision_Close) as varchar(112))
----ELSE CAST(EXTRACT(minutes from ot.Incision_Close) as varchar(112))
----END
----as varchar(112)),'') 
, FORMAT(ot.Incision_Close,'yyyyMMddHHmm') AS "INCISION CLOSE"
----,COALESCE(CAST(CONVERT(nchar(8), ot.Anesthesia_End,112)
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(hours from ot.Anesthesia_End) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(hours from ot.Anesthesia_End) as varchar(112))
----ELSE CAST(EXTRACT(hours from ot.Anesthesia_End) as varchar(112))
----END
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(minutes from ot.Anesthesia_End) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(minutes from ot.Anesthesia_End) as varchar(112))
----ELSE CAST(EXTRACT(minutes from ot.Anesthesia_End) as varchar(112))
----END
----as varchar(112)),'') 
, FORMAT(ot.Anesthesia_End,'yyyyMMddHHmm') AS "ANESTHESIA END"
----,COALESCE(CAST(CONVERT(nchar(8), ot.Out_of_Room,112)
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(hours from ot.Out_of_Room) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(hours from ot.Out_of_Room) as varchar(112))
----ELSE CAST(EXTRACT(hours from ot.Out_of_Room) as varchar(112))
----END
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(minutes from ot.Out_of_Room) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(minutes from ot.Out_of_Room) as varchar(112))
----ELSE CAST(EXTRACT(minutes from ot.Out_of_Room) as varchar(112))
----END
----as varchar(112)),'') 
, FORMAT(ot.Out_of_Room,'yyyyMMddHHmm') AS "PATIENT OUT OF ROOM"
----,COALESCE(CAST(CONVERT(nchar(8), ot.In_Recovery,112)
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(hours from ot.In_Recovery) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(hours from ot.In_Recovery) as varchar(112))
----ELSE CAST(EXTRACT(hours from ot.In_Recovery) as varchar(112))
----END
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(minutes from ot.In_Recovery) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(minutes from ot.In_Recovery) as varchar(112))
----ELSE CAST(EXTRACT(minutes from ot.In_Recovery) as varchar(112))
----END
----as varchar(112)),'') 
, FORMAT(ot.In_Recovery,'yyyyMMddHHmm') AS "RECOVERY START"
----,COALESCE(CAST(CONVERT(nchar(8), ot.Out_Recovery,112)
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(hours from ot.Out_Recovery) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(hours from ot.Out_Recovery) as varchar(112))
----ELSE CAST(EXTRACT(hours from ot.Out_Recovery) as varchar(112))
----END
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(minutes from ot.Out_Recovery) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(minutes from ot.Out_Recovery) as varchar(112))
----ELSE CAST(EXTRACT(minutes from ot.Out_Recovery) as varchar(112))
----END
----as varchar(112)),'')
, FORMAT(ot.Out_Recovery,'yyyyMMddHHmm') AS "RECOVERY END"
----,COALESCE(CAST(CONVERT(nchar(8), olat2.PostDate,112)
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(hours from olat2.PostDate) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(hours from olat2.PostDate) as varchar(112))
----ELSE CAST(EXTRACT(hours from olat2.PostDate) as varchar(112))
----END
----+
----CASE
----WHEN LENGTH(CAST(EXTRACT(minutes from olat2.PostDate) as varchar(112))) = 1
----THEN '0'+CAST(EXTRACT(minutes from olat2.PostDate) as varchar(112))
----ELSE CAST(EXTRACT(minutes from olat2.PostDate) as varchar(112))
----END
----as varchar(112)),'') 
, FORMAT(olat2.PostDate,'yyyyMMddHHmm') AS "POST DATE"

-- kcj 3/10: below datetimes replaced by above code
--
--,COALESCE(CAST(ot.IN_ROOM as varchar(112)) + SUBSTR(CAST(ot.IN_ROOM as varchar(108)),1,2) + SUBSTR(CAST(ot.IN_ROOM as varchar(108)),4,2), '') as "PATIENT IN ROOM"
--,COALESCE(CAST(ot.ANESTHESIA_START as varchar(112)) + SUBSTR(CAST(ot.ANESTHESIA_START as varchar(108)),1,2) + SUBSTR(CAST(ot.ANESTHESIA_START as varchar(108)),4,2), '') as "ANESTHESIA START"
--,COALESCE(CAST(ot.INCISION_START as varchar(112)) + SUBSTR(CAST(ot.INCISION_START as varchar(108)),1,2) + SUBSTR(CAST(ot.INCISION_START as varchar(108)),4,2), '') as "INCISION START"
--,COALESCE(CAST(ot.INCISION_CLOSE as varchar(112)) + SUBSTR(CAST(ot.INCISION_CLOSE as varchar(108)),1,2) + SUBSTR(CAST(ot.INCISION_CLOSE as varchar(108)),4,2), '') as "INCISION CLOSE"
--,COALESCE(CAST(ot.ANESTHESIA_END as varchar(112)) + SUBSTR(CAST(ot.ANESTHESIA_END as varchar(108)),1,2) + SUBSTR(CAST(ot.ANESTHESIA_END as varchar(108)),4,2), '') as "ANESTHESIA END"
--,COALESCE(CAST(ot.OUT_OF_ROOM as varchar(112)) + SUBSTR(CAST(ot.OUT_OF_ROOM as varchar(108)),1,2)+ SUBSTR(CAST(ot.OUT_OF_ROOM as varchar(108)),4,2), '') as "PATIENT OUT OF ROOM"
--,COALESCE(CAST(ot.IN_RECOVERY as varchar(112)) + SUBSTR(CAST(ot.IN_RECOVERY as varchar(108)),1,2) + SUBSTR(CAST(ot.IN_RECOVERY as varchar(108)),4,2), '') as "RECOVERY START"
--,COALESCE(CAST(ot.OUT_RECOVERY as varchar(112)) + SUBSTR(CAST(ot.OUT_RECOVERY as varchar(108)),1,2) + SUBSTR(CAST(ot.OUT_RECOVERY as varchar(108)),4,2), '') as "RECOVERY END"
--,COALESCE(CAST(olat2.PostDate as varchar(112)) + SUBSTR(CAST(olat2.PostDate as varchar(108)),1,2) + SUBSTR(CAST(olat2.PostDate as varchar(108)),4,2), '') as "POST DATE"

-- OR Mgmt System case/log records
FROM [source_uwhealth].epic_or_case_cur orc
LEFT OUTER JOIN [source_uwhealth].epic_or_log_cur orlog ON orc.LOG_ID = orlog.LOG_ID 
LEFT OUTER JOIN [source_uwhealth].epic_f_log_based_cur flb ON orlog.LOG_ID = flb.LOG_ID-- available in Clarity 2015 forward
LEFT OUTER JOIN [source_uwhealth].epic_ZC_OR_CASE_CLASS_CUR zocc ON orc.CASE_CLASS_C = zocc.CASE_CLASS_C-- BJ: 08/10/18

-- Patient info
INNER JOIN [source_uwhealth].epic_pat_or_adm_link_cur PAT_OR_ADM_LINK ON orlog.CASE_ID = PAT_OR_ADM_LINK.CASE_ID
INNER JOIN [source_uwhealth].epic_pat_enc_hsp_cur peh ON PAT_OR_ADM_LINK.OR_LINK_CSN = peh.PAT_ENC_CSN_ID
INNER JOIN [source_uwhealth].epic_PATIENT_cur patient ON orlog.PAT_ID = patient.PAT_ID
INNER JOIN [source_uwhealth].epic_HSP_ACCOUNT_cur har ON peh.HSP_ACCOUNT_ID = har.HSP_ACCOUNT_ID
INNER JOIN [source_uwhealth].epic_IDENTITY_ID_cur id ON patient.PAT_ID = id.PAT_ID

-- Procedure Scheduled/Ordered Info
LEFT OUTER JOIN [source_uwhealth].epic_or_case_ALL_PROC_cur orcap ON orc.OR_CASE_ID = orcap.OR_CASE_ID -- BJ: 9/10/18
LEFT OUTER JOIN [source_uwhealth].epic_OR_PROC_cur orproc ON orcap.OR_PROC_ID = orproc.OR_PROC_ID
--LEFT OUTER JOIN ZC_OR_OP_REGION zoor ON orproc.OPERATING_REGION_C = zoor.OPERATING_REGION_C-- BJ: 08/10/18
-- Reflecting CASE Documentation: OR_PROC_CPT_ID varies by Member (1) not populated, (2) CPT mapped 1 PROC_ID to many CPTs to hopefully (3) CPT mapped to 1 PROC_ID
--LEFT OUTER JOIN OR_PROC_CPT_ID orproccpt ON orproc.OR_PROC_ID = orproccpt.OR_PROC_ID
LEFT OUTER JOIN [source_uwhealth].epic_ZC_OR_CANCEL_RSN_cur orcrsn ON orc.CANCEL_REASON_C = orcrsn.CANCEL_REASON_C
LEFT OUTER JOIN [source_uwhealth].epic_ZC_PROC_NOT_PERF_cur zcprocnotperf ON orlog.PROC_NOT_PERF_C = zcprocnotperf.PROC_NOT_PERF_C


-- Performed cases -- added per conversation with vizient and Deb Lemaster and Ashley Petit because case tables are scheduled cases and log tables are performed cases
LEFT OUTER JOIN [source_uwhealth].epic_or_log_ALL_PROC_cur olaproc ON orc.LOG_ID = olaproc.LOG_ID
LEFT OUTER JOIN [source_uwhealth].epic_OR_PROC_cur orproc2 ON olaproc.OR_PROC_ID = orproc2.OR_PROC_ID



-- Performing Physician Info (not captured in F_LOG_BASED table)
LEFT JOIN [source_uwhealth].epic_or_log_ALL_STAFF_cur orlas on orlas.LOG_ID = orlog.LOG_ID and orlas.STAFF_TYPE_MAP_C = 1 and orlas.ROLE_C = 1 and orlas.PANEL = 1 -- and orlas.ACCOUNTBLE_STAFF_YN = 'Y'
LEFT JOIN [source_uwhealth].epic_CLARITY_SER_cur serlog on serlog.PROV_ID = orlas.STAFF_ID
    
-- Staff Name and Credentials
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur performphys on serlog.PROV_ID = performphys.PROV_ID--performing physician
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur primphys on flb.PRIMARY_PHYSICIAN_ID = primphys.PROV_ID--primary physician
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur secondphys on flb.SECONDARY_PHYSICIAN_ID = secondphys.PROV_ID--secondary physician
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur primcirc on flb.PRIMARY_CIRCULATOR_ID = primcirc.PROV_ID--primary circulator
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur primsurgtech on flb.PRIMARY_SURG_TECH_ID = primsurgtech.PROV_ID--primary surgical technician
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur primprern on flb.PRIMARY_PREOP_NURSE_ID = primprern.PROV_ID--primary preop nurse
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur primrecrn on flb.PRIMARY_RECOVERY_NURSE_ID = primrecrn.PROV_ID--primary recovery nurse
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur primphaseiirn on flb.PRIMARY_PHASEII_NURSE_ID = primphaseiirn.PROV_ID--primary phase II nurse
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur respanes on flb.RESP_ANES_ID = respanes.PROV_ID--responsible anesthesia provider
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur firstanes on flb.FIRST_ANES_ID = firstanes.PROV_ID--first anesthesia provider


-- Exclude test patients in WHERE clause
LEFT OUTER JOIN [source_uwhealth].epic_PATIENT_3_cur pat3 ON patient.PAT_ID = pat3.PAT_ID


/* BJ: replaced with D_PROV_PRIMARY_HIERARCHY, code to be removed shortly!!!
-- Anesthesiologist Info
LEFT OUTER JOIN (SELECT astf.LOG_ID, astaff.ANESTH_STAFF_ID AS ANESTHESIOLOGIST_PROV_ID, ser.PROV_NAME AS ANESTHESIOLOGIST
 FROM OR_LOG_LN_ANESSTAF astf
LEFT OUTER JOIN OR_LNLG_ANES_STAFF astaff ON astf.ANESTHESIA_STAFF_I = astaff.RECORD_ID
LEFT OUTER JOIN ZC_OR_ANSTAFF_TYPE atp ON astaff.ANESTH_STAFF_C = atp.ANEST_STAFF_REQ_C  
LEFT OUTER JOIN CLARITY_SER ser ON astaff.ANESTH_STAFF_ID = ser.PROV_ID
 WHERE atp.ANEST_STAFF_REQ_C = 10 AND astf.LINE = (SELECT MIN(a.LINE)
   FROM OR_LOG_LN_ANESSTAF a
   WHERE a.LOG_ID = astf.LOG_ID)
) an ON orlog.LOG_ID = an.LOG_ID
*/

-- OR Room Info
LEFT OUTER JOIN [source_uwhealth].epic_CLARITY_SER_cur ser_room ON orlog.ROOM_ID = ser_room.PROV_ID
LEFT OUTER JOIN [source_uwhealth].epic_CLARITY_LOC_cur loc on orlog.LOC_ID = loc.LOC_ID
 
--Department
LEFT OUTER JOIN [source_uwhealth].epic_CLARITY_DEP_cur cd2 ON flb.DEPARTMENT_ID = cd2.DEPARTMENT_ID



-- BEGIN "Client to Verify Selection" - OR Times (possibly custom built per client) in table ZC_OR_PAT_EVENTS
-- OR TIME parameters for TRACKING EVENTs & PANEL TIME EVENTs found in tables: [OR_LOG_CASE_TIMES and OR_LOG_PANEL_TIME1]

--LEFT OUTER JOIN (SELECT ct.LOG_ID
-- ,MAX(CASE WHEN ct.TRACKING_EVENT_C = '432' THEN ct.TRACKING_TIME_IN END) AS In_Room-- In Surgical Room
-- ,MAX(CASE WHEN ct.TRACKING_EVENT_C = '576' THEN ct.TRACKING_TIME_IN END) AS Anesthesia_Start-- Anesthesia Begins
-- ,MAX(CASE WHEN ptime.PANEL_TIME_EVENT_C = '144' THEN ptime.panel_start_time END) AS Incision_Start-- Incision Open
-- ,MAX(CASE WHEN ptime.PANEL_TIME_EVENT_C = '288' THEN ptime.panel_start_time END) AS Incision_Close-- Incision Closed
-- ,MAX(CASE WHEN ct.TRACKING_EVENT_C = '1008' THEN ct.TRACKING_TIME_IN END) AS Anesthesia_End-- Anesthesia End
-- ,MAX(CASE WHEN ct.TRACKING_EVENT_C = '1152' THEN ct.TRACKING_TIME_IN END) AS Out_of_Room-- Out of Surgical Room
-- ,MAX(CASE WHEN ct.TRACKING_EVENT_C IN ('1296') THEN ct.TRACKING_TIME_IN END) AS In_Recovery-- In Recovery (PACU)
-- ,MAX(CASE WHEN ct.TRACKING_EVENT_C IN ('1584') THEN ct.TRACKING_TIME_IN END) AS Out_Recovery-- Out Recovery (PACU)
-- FROM OR_LOG_CASE_TIMES ct 
--LEFT OUTER JOIN OR_LOG_PANEL_TIME1 ptime ON ct.log_id = ptime.log_id
-- WHERE ct.TRACKING_EVENT_C IN ('10','20','60','70','100','110','120','140','500','540','580','590')
-- GROUP BY ct.LOG_ID
--) ot ON orlog.LOG_ID = ot.LOG_ID
-- END "Client to Verify Selection"
--alternative to the above
LEFT OUTER JOIN (SELECT ct.LOG_ID
,MAX(ct.PATIENT_IN_ROOM_DTTM) AS In_Room
,MAX(ct.ANESTHESIA_START_DTTM) AS Anesthesia_Start
,MAX(ct.PROCEDURE_START_DTTM) AS Incision_Start -- kcj added 5/22 per definition in clarity dictionary
,MAX(ct.PROCEDURE_COMP_DTTM) AS Incision_Close -- kcj added 5/22 per definition in clarity dictionary
--,MAX(CASE WHEN ptime.PANEL_TIME_EVENT_C = '144' THEN ptime.panel_start_time END) AS Incision_Start -- kcj removed 5/22 due to time field not being populated in clarity and alternative above meets definition criteria
--,MAX(CASE WHEN ptime.PANEL_TIME_EVENT_C = '288' THEN ptime.panel_start_time END) AS Incision_Close -- kcj removed 5/22 due to time field not being populated in clarity and alternative above meets definition criteria
,MAX(ct.ANESTHESIA_STOP_DTTM) AS Anesthesia_End
,MAX(ct.PATIENT_OUT_ROOM_DTTM) AS Out_of_Room
,MAX(ct.PATIENT_IN_RECOVERY_DTTM) AS In_Recovery
,MAX(ct.PATIENT_OUT_RECOVERY_DTTM) AS Out_Recovery
FROM [source_uwhealth].epic_V_LOG_TIMING_EVENTS_cur ct
LEFT OUTER JOIN [source_uwhealth].epic_OR_LOG_PANEL_TIME1_cur ptime ON ct.log_id = ptime.log_id
GROUP BY ct.LOG_ID
) ot ON orlog.LOG_ID = ot.LOG_ID

-- Determine Most Recent "PostDate" and use/share globally in script
LEFT OUTER JOIN (SELECT olat.LOG_ID, MAX(olat.AUDIT_DATE) OVER(PARTITION BY olat.LOG_ID ORDER BY olat.LOG_ID, olat.AUDIT_DATE desc) AS PostDate
 FROM [source_uwhealth].epic_or_log_AUDIT_TRAIL_cur olat 
 WHERE olat.AUDIT_ACTION_C = '7'
) olat2 ON orlog.LOG_ID = olat2.LOG_ID

WHERE
-- Dates passed from @Variables above set based upon request (On-Boarding, Baseline/Historical or Ongoing Refreshes)

-- Opt1 OnBoarding, Baseline/Historical or Ongoing Refresh (***** Monthly *****) Logic

--CONVERT(varchar,orlog.SURGERY_DATE,112) >= @StartDate AND CONVERT(varchar,orlog.SURGERY_DATE,112) < DATEADD(DAY, 1, @EndDate)
--orlog.SURGERY_DATE >= '7/1/2021' AND orlog.SURGERY_DATE < '8/1/2021' Commenting 06/04/2024
-- Opt2 Ongoing Refresh (***** Daily *****) Logic

-- CONVERT(varchar,orlog.SURGERY_DATE,112) = CONVERT(varchar,GETDATE()-1,112)

-- Exclude 'test' patients in production database
--AND
(pat3.IS_TEST_PAT_YN IS NULL OR pat3.IS_TEST_PAT_YN = 'N')
AND patient.PAT_MRN_ID NOT LIKE 'ZZ%'

-- Selection of Patient Types for "Non-Inpatient"
--AND har.ACCT_CLASS_HA_C NOT IN ('2','6','8') --kcj 5/3 remved per conversation with Vizient. This new/third union is for the HCO procedures and should not parse out inpatient and outpatient
AND id.IDENTITY_TYPE_ID = '0'

--AND orproc.OR_PROC_ID is not null

-- BEGIN Facility Selection--default is all
AND har.SERV_AREA_ID IN ('10000')
AND orlog.LOC_ID NOT IN ('88600','99600') --OOR cases at UWH-Madison
AND orlog.ROOM_ID NOT IN ('692742','692743','692744','692745','692746','692747','692748','692749','692875','692876','692877','693301','693326','695241','695382','695383') --APC rooms to be excluded because many noninvasive procedures and others that are causing data quality concerns
AND orlog.ROOM_ID NOT IN ('693288','695076')

UNION
/*This section is for MSC surgeries only. */

SELECT
'520098' as "Medicare Provider ID"
,COALESCE(CAST(stratacpts.place_of_service_id as varchar(18)), '') as "Sub-Facility ID"
,'40357' as "Member ID"
,COALESCE(CAST(coalesce(peh.HSP_ACCOUNT_ID, stratacpts.pat_enc_csn_id)  as varchar(18)), '') as "Encounter ID" --stratacpts.pat_enc_csn_id
,COALESCE(CAST(id.IDENTITY_ID as varchar(25)), '') as "Patient ID"
,COALESCE(orlog.CASE_ID, '') as "PROCEDURAL CASE NUMBER"
,COALESCE(CAST(CONVERT(nchar(8), orlog.SURGERY_DATE,112) as varchar(112)),'') AS "Date of Service"
,COALESCE(CAST(CONVERT(nchar(8), patient.BIRTH_DATE,112) as varchar(112)),'') AS "Date of Birth"
,flb.DEPARTMENT_ID as "HCO DEPARTMENT CODE"
,cd2.DEPARTMENT_NAME as "HCO DEPARTMENT DESCRIPTION"
,CASE WHEN patient.SEX_C = '1' THEN '2'
 WHEN patient.SEX_C = '2' THEN '1'
 ELSE '3'
END as "SEX"
/*,COALESCE(zoor.TITLE, '') as "PROCEDURE LOCATION"-- BJ: 08/10/18 */
,'' as "PROCEDURE LOCATION"
,COALESCE(zocc.TITLE, '') as "CASE STATUS"-- BJ: 08/10/18

/* BEGIN "Client to Verify" Selection - compare mapped values below in table ZC_ACCT_CLASS_HA to values below, update as needed!!!!!
 F is 'Freestanding Ambulatory Surgery' per Vizient mapping
 */
,'F' as "ENCOUNTER TYPE" 
/* END "Client to Verify Selection"

 BEGIN "Client to Verify Selection" - Case Type (coding to be modified/replaced per client)
UW Health is hardcoding this field because all of the data will be flowing through clarity for now and the operating room is the only procedural area using clarity
OR' AS "CASE TYPE" --used to do until 6/14 for uwh-madison */
,CASE WHEN ser_room.PROV_NAME like '%UWHC OSC%' THEN 'HA'-- Hospital based ambulatory surgery
WHEN orlog.ROOM_ID IN ('692083','692084','693343','695239') THEN 'HS'-- Hybrid Suite
Else 'OR'
END AS "CASE TYPE"
,'' as "ROBOTICS FLAG"  
,COALESCE(CAST(orlog.ASA_RATING_C as varchar(2)), '') as "ASA PHYSICAL STATUS CLASSIFICATION"
,COALESCE(stratacpts.BILLED_CPT_CODE, '') as "CPT Procedure Code"-- BJ: 09/28/18 --KCJ 11/14/18 removed orproccpt.OR_PROC_ID from coalesce because UW Health does not populate that table
,COALESCE(stratacpts.PROF_ATTR_PROVIDER_ID, serlog.PROV_ID, '') as "CPT HOSPITAL-ASSIGNED PHYSICIAN ID" -- BJ: 08/07/18 & 09/28/18
,COALESCE(CAST(stratacpts.CPT_MODIFIER_ONE as varchar(2)), '') as "CPT CODE MODIFIER_1" 
,COALESCE(CAST(stratacpts.CPT_MODIFIER_TWO as varchar(2)), '') as "CPT CODE MODIFIER_2"         
,COALESCE(CAST(stratacpts.CPT_MODIFIER_THREE as varchar(2)), '') as "CPT CODE MODIFIER_3"         
,COALESCE(CAST(stratacpts.CPT_MODIFIER_FOUR as varchar(2)), '') as "CPT CODE MODIFIER_4"        
,'' as "ICD-10 PROCEDURE CODE"
,'' as "ICD-10 PROCEDURE SEQUENCE"
,'' as "ICD-10 HOSPITAL-ASSIGNED PHYSICIAN ID"
,'' as "HCO PROCEDURE CODE"
,'' as "HCO PROCEDURE DESCRIPTION"
,NULL as "HCO PROCEDURE SEQUENCE"
,'' as "HCO PROCEDURE HOSPITAL-ASSIGNED PHYSICIAN ID"
,'' as "SCHEDULED PROCEDURAL SUITE"
--,COALESCE(CAST(orlog.ROOM_ID as varchar(18)), '') as "ACTUAL PROCEDURAL SUITE"  -- BJ: 08/05/18
,COALESCE(CAST(ser_room.PROV_NAME as varchar(30)), '') as "ACTUAL PROCEDURAL SUITE" -- BJ: 08/05/15
,COALESCE(CAST(respanes.PROV_ID as varchar(18)), '') as "ANESTHESIOLOGIST PHYSICIAN ID - 1"
,'' as "ANESTHESIOLOGIST PHYSICIAN ID - 2"
,'' as "ANESTHESIOLOGIST PHYSICIAN ID - 3" 
,'' as "ANESTHESIOLOGIST PHYSICIAN ID - 4"
,COALESCE(CAST(primcirc.PROV_ID as varchar(18)), '') as "CIRCULATOR ID - 1"
,'' as "CIRCULATOR ID - 2"
,'' as "CIRCULATOR ID - 3"
,'' as "CIRCULATOR ID - 4" 
,COALESCE(primcirc.PROV_NM_CRED, '') as "CIRCULATOR NAME - 1"
,'' as "CIRCULATOR NAME - 2"
,'' as "CIRCULATOR NAME - 3"
,'' as "CIRCULATOR NAME - 4"
,COALESCE(CAST(primsurgtech.PROV_ID as varchar(18)), '') as "SCRUB TECH ID - 1"
,'' as "SCRUB TECH ID - 2"
,'' as "SCRUB TECH ID - 3"
,'' as "SCRUB TECH ID - 4"
,COALESCE(primsurgtech.PROV_NM_CRED, '') as "SCRUB TECH NAME - 1"
,'' as "SCRUB TECH NAME - 2"
,'' as "SCRUB TECH NAME - 3"
,'' as "SCRUB TECH NAME - 4"
,'' as "SURGICAL ASSISTANT ID - 1"
,'' as "SURGICAL ASSISTANT ID - 2"
,'' as "SURGICAL ASSISTANT ID - 3"
,'' as "SURGICAL ASSISTANT ID - 4" 
,'' as "SURGICAL ASSISTANT NAME - 1"
,'' as "SURGICAL ASSISTANT NAME - 2"
,'' as "SURGICAL ASSISTANT NAME - 3"
,'' as "SURGICAL ASSISTANT NAME - 4"

, FORMAT(orlog.SCHED_START_TIME,'yyyyMMddHHmm') as "DATE CASE SCHEDULED"
,CASE WHEN orc.CANCEL_REASON_C IS NOT NULL AND orc.CANCEL_COMMENTS IS NOT NULL AND ot.Incision_Start IS NULL AND ot.Incision_Close IS NULL
  THEN 'Y'
  WHEN orc.CANCEL_REASON_C IS NOT NULL AND orc.CANCEL_COMMENTS IS NULL AND ot.Incision_Start IS NULL AND ot.Incision_Close IS NULL
  THEN 'Y'
  WHEN orc.CANCEL_COMMENTS IS NOT NULL AND orc.CANCEL_REASON_C IS NULL AND ot.Incision_Start IS NULL AND ot.Incision_Close IS NULL
  THEN 'Y'
  ELSE 'N'
END as "CANCELLATION FLAG"
, FORMAT(orlog.SCHED_START_TIME,'yyyyMMddHHmm') as "SCHEDULED CASE START"
,'' as "SCHEDULED CASE END"
, FORMAT(ot.In_Room,'yyyyMMddHHmm') AS "PATIENT IN ROOM"
, FORMAT(ot.Anesthesia_Start,'yyyyMMddHHmm') AS "ANESTHESIA START"
,FORMAT(ot.Incision_Start,'yyyyMMddHHmm') AS "INCISION START"
, FORMAT(ot.Incision_Close,'yyyyMMddHHmm') AS "INCISION CLOSE"
, FORMAT(ot.Anesthesia_End,'yyyyMMddHHmm') AS "ANESTHESIA END"
, FORMAT(ot.Out_of_Room,'yyyyMMddHHmm') AS "PATIENT OUT OF ROOM"
, FORMAT(ot.In_Recovery,'yyyyMMddHHmm') AS "RECOVERY START"
, FORMAT(ot.Out_Recovery,'yyyyMMddHHmm') AS "RECOVERY END"
, FORMAT(olat2.PostDate,'yyyyMMddHHmm') AS "POST DATE"
FROM [source_uwhealth].epic_or_case_cur orc
LEFT OUTER JOIN [source_uwhealth].epic_or_log_cur orlog ON orc.LOG_ID = orlog.LOG_ID 
LEFT OUTER JOIN [source_uwhealth].epic_f_log_based_cur flb ON orlog.LOG_ID = flb.LOG_ID-- available in Clarity 2015 forward
LEFT OUTER JOIN [source_uwhealth].epic_ZC_OR_CASE_CLASS_CUR zocc ON orc.CASE_CLASS_C = zocc.CASE_CLASS_C-- BJ: 08/10/18

-- Patient info
INNER JOIN [source_uwhealth].epic_pat_or_adm_link_cur PAT_OR_ADM_LINK ON orlog.CASE_ID = PAT_OR_ADM_LINK.CASE_ID
INNER JOIN [source_uwhealth].epic_pat_enc_hsp_cur peh ON PAT_OR_ADM_LINK.OR_LINK_CSN = peh.PAT_ENC_CSN_ID
INNER JOIN [source_uwhealth].epic_PATIENT_cur patient ON orlog.PAT_ID = patient.PAT_ID

INNER JOIN [source_uwhealth].epic_IDENTITY_ID_cur id ON patient.PAT_ID = id.PAT_ID

-- Procedure Scheduled/Ordered Info
LEFT OUTER JOIN [source_uwhealth].epic_or_case_ALL_PROC_cur orcap ON orc.OR_CASE_ID = orcap.OR_CASE_ID -- BJ: 9/10/18
LEFT OUTER JOIN [source_uwhealth].epic_OR_PROC_cur orproc ON orcap.OR_PROC_ID = orproc.OR_PROC_ID
--LEFT OUTER JOIN ZC_OR_OP_REGION zoor ON orproc.OPERATING_REGION_C = zoor.OPERATING_REGION_C-- BJ: 08/10/18
-- Reflecting CASE Documentation: OR_PROC_CPT_ID varies by Member (1) not populated, (2) CPT mapped 1 PROC_ID to many CPTs to hopefully (3) CPT mapped to 1 PROC_ID
--LEFT OUTER JOIN OR_PROC_CPT_ID orproccpt ON orproc.OR_PROC_ID = orproccpt.OR_PROC_ID
LEFT OUTER JOIN [source_uwhealth].epic_ZC_OR_CANCEL_RSN_cur orcrsn ON orc.CANCEL_REASON_C = orcrsn.CANCEL_REASON_C
LEFT OUTER JOIN [source_uwhealth].epic_ZC_PROC_NOT_PERF_cur zcprocnotperf ON orlog.PROC_NOT_PERF_C = zcprocnotperf.PROC_NOT_PERF_C

-- Performing Physician Info (not captured in F_LOG_BASED table)
LEFT JOIN [source_uwhealth].epic_or_log_ALL_STAFF_cur orlas on orlas.LOG_ID = orlog.LOG_ID and orlas.STAFF_TYPE_MAP_C = 1 and orlas.ROLE_C = 1 and orlas.PANEL = 1 -- and orlas.ACCOUNTBLE_STAFF_YN = 'Y'
LEFT JOIN [source_uwhealth].epic_CLARITY_SER_cur serlog on serlog.PROV_ID = orlas.STAFF_ID
    
-- Staff Name and Credentials
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur performphys on serlog.PROV_ID = performphys.PROV_ID--performing physician
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur primphys on flb.PRIMARY_PHYSICIAN_ID = primphys.PROV_ID--primary physician
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur secondphys on flb.SECONDARY_PHYSICIAN_ID = secondphys.PROV_ID--secondary physician
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur primcirc on flb.PRIMARY_CIRCULATOR_ID = primcirc.PROV_ID--primary circulator
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur primsurgtech on flb.PRIMARY_SURG_TECH_ID = primsurgtech.PROV_ID--primary surgical technician
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur primprern on flb.PRIMARY_PREOP_NURSE_ID = primprern.PROV_ID--primary preop nurse
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur primrecrn on flb.PRIMARY_RECOVERY_NURSE_ID = primrecrn.PROV_ID--primary recovery nurse
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur primphaseiirn on flb.PRIMARY_PHASEII_NURSE_ID = primphaseiirn.PROV_ID--primary phase II nurse
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur respanes on flb.RESP_ANES_ID = respanes.PROV_ID--responsible anesthesia provider
LEFT OUTER JOIN [source_uwhealth].epic_D_PROV_PRIMARY_HIERARCHY_cur firstanes on flb.FIRST_ANES_ID = firstanes.PROV_ID--first anesthesia provider


-- Exclude test paitients in WHERE clause
LEFT OUTER JOIN [source_uwhealth].epic_PATIENT_3_cur pat3 ON patient.PAT_ID = pat3.PAT_ID

-- OR Room Info
LEFT OUTER JOIN [source_uwhealth].epic_CLARITY_SER_cur ser_room ON orlog.ROOM_ID = ser_room.PROV_ID
LEFT OUTER JOIN [source_uwhealth].epic_CLARITY_LOC_cur loc on orlog.LOC_ID = loc.LOC_ID and loc.loc_id = '34100' --MSC
 
--Department
LEFT OUTER JOIN [source_uwhealth].epic_CLARITY_DEP_cur cd2 ON flb.DEPARTMENT_ID = cd2.DEPARTMENT_ID


LEFT OUTER JOIN (SELECT ct.LOG_ID
,MAX(ct.PATIENT_IN_ROOM_DTTM) AS In_Room
,MAX(ct.ANESTHESIA_START_DTTM) AS Anesthesia_Start
,MAX(ct.PROCEDURE_START_DTTM) AS Incision_Start -- kcj added 5/22 per definition in clarity dictionary
,MAX(ct.PROCEDURE_COMP_DTTM) AS Incision_Close -- kcj added 5/22 per definition in clarity dictionary
--,MAX(CASE WHEN ptime.PANEL_TIME_EVENT_C = '144' THEN ptime.panel_start_time END) AS Incision_Start -- kcj removed 5/22 due to time field not being populated in clarity and alternative above meets definition criteria
--,MAX(CASE WHEN ptime.PANEL_TIME_EVENT_C = '288' THEN ptime.panel_start_time END) AS Incision_Close -- kcj removed 5/22 due to time field not being populated in clarity and alternative above meets definition criteria
,MAX(ct.ANESTHESIA_STOP_DTTM) AS Anesthesia_End
,MAX(ct.PATIENT_OUT_ROOM_DTTM) AS Out_of_Room
,MAX(ct.PATIENT_IN_RECOVERY_DTTM) AS In_Recovery
,MAX(ct.PATIENT_OUT_RECOVERY_DTTM) AS Out_Recovery
FROM [source_uwhealth].epic_V_LOG_TIMING_EVENTS_cur ct
LEFT OUTER JOIN [source_uwhealth].epic_OR_LOG_PANEL_TIME1_cur ptime ON ct.log_id = ptime.log_id
GROUP BY ct.LOG_ID
) ot ON orlog.LOG_ID = ot.LOG_ID

-- Determine Most Recent "PostDate" and use/share globally in script
LEFT OUTER JOIN (SELECT olat.LOG_ID, MAX(olat.AUDIT_DATE) OVER(PARTITION BY olat.LOG_ID ORDER BY olat.LOG_ID, olat.AUDIT_DATE desc) AS PostDate
 FROM [source_uwhealth].epic_or_log_AUDIT_TRAIL_cur olat 
 WHERE olat.AUDIT_ACTION_C = '7'
) olat2 ON orlog.LOG_ID = olat2.LOG_ID
-- Billing CPTs
join [Mart_UWHealth].STRATA_COST_CHARGE_ACTIVITY_PB stratacpts on PAT_OR_ADM_LINK.or_link_csn = stratacpts.pat_enc_csn_id
	and stratacpts.entity_cd = '413' /* entity for MSC only */ 

WHERE
-- Dates passed from @Variables above set based upon request (On-Boarding, Baseline/Historical or Ongoing Refreshes)

-- Opt1 OnBoarding, Baseline/Historical or Ongoing Refresh (***** Monthly *****) Logic

--CONVERT(varchar,orlog.SURGERY_DATE,112) >= @StartDate AND CONVERT(varchar,orlog.SURGERY_DATE,112) < DATEADD(DAY, 1, @EndDate)
--orlog.SURGERY_DATE >= '7/1/2021' AND orlog.SURGERY_DATE < '8/1/2021' COmmenting 06/04/2024
-- Opt2 Ongoing Refresh (***** Daily *****) Logic

-- CONVERT(varchar,orlog.SURGERY_DATE,112) = CONVERT(varchar,GETDATE()-1,112)

-- Exclude 'test' patients in production database
--AND 
(pat3.IS_TEST_PAT_YN IS NULL OR pat3.IS_TEST_PAT_YN = 'N')
AND patient.PAT_MRN_ID NOT LIKE 'ZZ%'

-- Selection of Patient Types for "Non-Inpatient"
--AND har.ACCT_CLASS_HA_C NOT IN ('2','6','8') 
AND id.IDENTITY_TYPE_ID = '0'

--AND orproc.OR_PROC_ID is not null

-- BEGIN Facility Selection--default is all
--AND har.SERV_AREA_ID IN ('10000')
AND orlog.LOC_ID NOT IN ('88600','99600') --OOR cases at UWH-Madison
AND orlog.ROOM_ID NOT IN ('692742','692743','692744','692745','692746','692747','692748','692749','692875','692876','692877','693301','693326','695241','695382','695383') --APC rooms to be excluded because many noninvasive procedures and others that are causing data quality concerns
AND orlog.ROOM_ID NOT IN ('693288','695076') -- RN Out rooms that are often non-invasive procedures
--AND har.LOC_ID IN ('37000')
--AND (flb.DEPARTMENT_ID LIKE '3%' OR cd2.DEPARTMENT_NAME LIKE '%TAC%' OR ser_room.PROV_NAME LIKE '%TAC%')
--(SELECT LOC_ID FROM CLARITY_LOC
--WHERE LOCATION_ABBR like '%PVH%')
-- END Facility Selection

