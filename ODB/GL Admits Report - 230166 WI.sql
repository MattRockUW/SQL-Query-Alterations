/***********************************************************************************************************************
Report Title:    GL Admits Report - 230166 WI
REPORT PURPOSE:  To provide a list of ADT events in Clinical Research departments with unlimited lookback

Summary: 
 - Report includes Admission [1], Transfer In [3], Patient Update [5] ADT Events 
 - Includes Inpatient only - defined by the hospital account
 - Excludes ADT events that take place in the Hospice unit [6000039]
***********************************************************************************************************************
DATE              DEVELOPER          TICKET              ACTION
2018-06           DDL049             PRJ0176308          Updated for SAHS go-live 2018-07; limit to UW Health service area
2019-05           D0T0                                   Upgrade: Removed all fields which is not required or used in this report.
11/20/2023        Amber Glynn        PRJTASK5422515      Clarity migration. Added service area and date parameters.
***********************************************************************************************************************/
declare @StartDate datetime = '2024-07-01'
declare @EndDate   datetime = '2025-06-30';

WITH grab_ADT AS (
					select 
						  p.pat_name
						, ha.hsp_account_id
						, p.pat_mrn_id
						, adt.pat_enc_csn_id
						, adt.event_id
						, za.name as Accommodation
						, adt.effective_time
						, dep.department_name
						, dep.department_id
						, dep.rpt_grp_twentythree
						, adt.event_type_c
						, zps.abbr as hsp_svs_abbr
						, ha.acct_class_ha_c 
					from [Source_UWHealth].EPIC_clarity_adt_CUR adt 
						left outer join [Source_UWHealth].EPIC_PAT_ENC_HSP_CUR peh on adt.event_id = coalesce(peh.inp_adm_event_id, peh.OP_ADM_EVENT_ID)
						left outer join [Source_UWHealth].EPIC_HSP_ACCOUNT_CUR ha on peh.hsp_account_id = ha.hsp_account_id
						left outer join [Source_UWHealth].EPIC_patient_CUR p on adt.pat_id = p.pat_id
						left outer join [Source_UWHealth].EPIC_zc_event_type_CUR zet on adt.event_type_c = zet.event_type_c
						left outer join [Source_UWHealth].EPIC_zc_pat_class_CUR zpc on adt.pat_class_c = zpc.adt_pat_class_c
						left outer join [Source_UWHealth].EPIC_clarity_dep_CUR dep on adt.department_id = dep.department_id
						left outer join [Source_UWHealth].EPIC_zc_accommodation_CUR za on adt.accommodation_c = za.accommodation_c
						left outer join [Source_UWHealth].EPIC_zc_pat_service_CUR zps on adt.pat_service_c = zps.hosp_serv_c
					where adt.department_id <> 6000039 -- Exclude ADT events that take place in HOSPICE UNIT
							--and adt.event_type_c in (1,3,5, 7) -- Admission [1], Transfer In [3], Patient Update [5] ADT Events
							--and ha.acct_class_ha_c = 2 -- Include Inpatient [2] hospital accounts only
							AND adt.EFFECTIVE_TIME >= @StartDate
							AND adt.EFFECTIVE_TIME < @EndDate

)
select department_id, department_name, rpt_grp_twentythree as 'ACC', CAST(EOMONTH(EFFECTIVE_TIME) AS DATE) as mon_yr, event_type_c, acct_class_ha_c,  count(*) as 'AdmissionCount' from grab_ADT
group by department_id, department_name, rpt_grp_twentythree, CAST(EOMONTH(EFFECTIVE_TIME) AS DATE), event_type_c, acct_class_ha_c

