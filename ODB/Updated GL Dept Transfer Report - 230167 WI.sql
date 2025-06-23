declare @StartDate datetime = '2024-07-01'
declare @EndDate   datetime = '2025-06-01'
;
/***********************************************************************************************************************
 1. 
***********************************************************************************************************************/
WITH all_xfer AS
(
SELECT
ha.hsp_account_id
, p.pat_name
, peh.pat_enc_csn_id
, p.pat_mrn_id
, dep_from.department_id as from_dept_id
, dep_from.RPT_GRP_TWENTYTHREE as from_dept_acc
, dep_from.department_name as from_dept
, dep_from.is_periop_dep_yn AS from_dept_is_periop
, adt_to.department_id as to_dept_id
, dep_to.RPT_GRP_TWENTYTHREE as to_dept_acc
, dep_to.department_name as to_dept
, dep_to.is_periop_dep_yn AS to_dept_is_periop
, adt_to.effective_time
, zpc_to.abbr as to_pat_class
, za.name AS accommodation
, (select max(adt_last.SEQ_NUM_IN_ENC) AS last_seq_in_enc /* Previous event */
	from Source_UWHealth.EPIC_CLARITY_ADT_CUR adt_last
		 inner join[Source_UWHealth].EPIC_CLARITY_DEP_CUR dep on adt_last.department_id = dep.department_id
   where adt_last.pat_enc_csn_id = adt_to.pat_enc_csn_id
		  and adt_last.event_type_c in (1,3,5,7) -- Admission [1], Transfer In [3], [Source_UWHealth].EPIC_PATIENT_CUR Update [5], Hospital Outpatient [7]
		  and adt_last.event_subtype_c <> 2 -- Canceled [2]
		  and (dep.is_periop_dep_yn IS NULL or dep.is_periop_dep_yn <> 'Y')
          and adt_last.effective_time < adt_to.effective_time) as last_seq_in_enc
   , (select min(adt_next.SEQ_NUM_IN_ENC) AS next_seq_in_enc /* Next event */
   	    from Source_UWHealth.EPIC_CLARITY_ADT_CUR adt_next
		     inner join[Source_UWHealth].EPIC_CLARITY_DEP_CUR dep on adt_next.department_id = dep.department_id
	    where adt_next.pat_enc_csn_id = adt_to.pat_enc_csn_id
			  and adt_next.event_type_c in (1,3,5,7) -- Admission [1], Transfer In [3], [Source_UWHealth].EPIC_PATIENT_CUR Update [5], Hospital Outpatient [7]
			  and adt_next.event_subtype_c <> 2 -- Canceled [2]
			  and (dep.is_periop_dep_yn IS NULL or dep.is_periop_dep_yn <> 'Y')
			  and adt_next.effective_time > adt_to.effective_time) as next_seq_in_enc
from
	Source_UWHealth.EPIC_CLARITY_ADT_CUR adt_to
	inner join Source_UWHealth.EPIC_CLARITY_ADT_CUR adt_from on adt_to.xfer_event_id = adt_from.event_id
	inner join [Source_UWHealth].EPIC_PATIENT_CUR p on adt_to.pat_id = p.pat_id
	inner join [Source_UWHealth].EPIC_PAT_ENC_HSP_CUR peh on adt_to.pat_enc_csn_id = peh.pat_enc_csn_id
	left outer join [Source_UWHealth].EPIC_ZC_PAT_CLASS_CUR zpc_to on adt_to.pat_class_c = zpc_to.adt_pat_class_c
	left outer join[Source_UWHealth].EPIC_CLARITY_DEP_CUR dep_to on adt_to.department_id = dep_to.department_id
	left outer join[Source_UWHealth].EPIC_CLARITY_DEP_CUR dep_from on adt_from.department_id = dep_from.department_id
	INNER join [Source_UWHealth].EPIC_HSP_ACCOUNT_CUR ha on peh.hsp_account_id = ha.hsp_account_id
	left outer join [Source_UWHealth].EPIC_ZC_ACCOMMODATION_CUR za on adt_to.accommodation_c = za.accommodation_c
WHERE
	peh.adt_pat_class_c = 2 -- most recent encounter [Source_UWHealth].EPIC_PATIENT_CUR class is inpatient
	AND ha.acct_class_ha_c = 2 -- most recent account class is inpatient
	AND adt_to.effective_time > peh.inp_adm_date -- transfer occurred after inpatient admission
	and adt_to.effective_time >= @StartDate
	and adt_to.effective_time < @EndDate
	and adt_to.event_type_c in (3,5) --  Transfer In [3], [Source_UWHealth].EPIC_PATIENT_CUR Update [5]
	and adt_to.event_subtype_c <> 2 -- Canceled [2]
	and adt_from.department_id<>adt_to.department_id
	--AND peh.ADT_SERV_AREA_ID IN {?Service Area}

)
/***********************************************************************************************************************
 2. 
***********************************************************************************************************************/
, add_dept AS (
					SELECT x.*,
					       a1.department_id AS last_inp_dept_in,
						   a2.department_id AS next_inp_dept_in
					  FROM all_xfer x
					       LEFT JOIN Source_UWHealth.EPIC_CLARITY_ADT_CUR a1 ON a1.pat_enc_csn_id=x.pat_enc_csn_id
						                               AND a1.SEQ_NUM_IN_ENC = x.last_seq_in_enc
						   LEFT JOIN Source_UWHealth.EPIC_CLARITY_ADT_CUR a2 ON a2.pat_enc_csn_id=x.pat_enc_csn_id
	                                                   AND a2.SEQ_NUM_IN_ENC=x.next_seq_in_enc
													   

              )
--SELECT * FROM add_dept;
/***********************************************************************************************************************
 3. 
***********************************************************************************************************************/
select 
  from_dept_id
  ,from_dept_acc
, from_dept
, to_dept_id
,to_dept_acc
, to_dept
, CAST(EOMONTH(EFFECTIVE_TIME) AS DATE) as mon_yr
, count(*) as 'count'
--, to_pat_class
--, accommodation
--, @StartDate AS StartDate
--, @EndDate AS EndDate
from add_dept x
where
-- not a transfer into an OR and not being transferred back into the same unit
((to_dept_is_periop IS NULL or to_dept_is_periop <> 'Y') and (last_inp_dept_in is null or to_dept_id <> last_inp_dept_in))
-- transfer into OR, but not the same pre-OR and post-OR unit
OR
(to_dept_is_periop = 'Y' and (last_inp_dept_in is null or x.next_inp_dept_in IS NULL OR last_inp_dept_in <> x.next_inp_dept_in))
group by from_dept_id
, from_dept
,from_dept_acc
,to_dept_acc
, to_dept_id
, to_dept
, CAST(EOMONTH(EFFECTIVE_TIME) AS DATE)
