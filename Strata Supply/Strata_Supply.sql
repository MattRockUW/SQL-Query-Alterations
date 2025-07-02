/****** Object:  View [Mart_Load_UWHealth].[STRATA_Supply]    Script Date: 7/2/2025 11:54:51 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [Mart_Load_UWHealth].[STRATA_Supply] AS select
/**********************************************************************************************************************
Title/Object: STRATA_Supply
Purpose: This view feeds the Strata outbound file submission process. 
Business Rules Summary:
History:
DATE			Developer				Action
4/22/2020		Allen Quetone		    Version 1
5/12/2020		Sean Meirose			Added SupplyRollUp and Manufacturer values
6/11/2020		Sean Meirose			Added Implant data
6/17/2020		Sean Meirose			Replaced inner join with outer join to include missing values.
12/18/2023		Sean Meirose			Converted to MS SQL.
4/29/2025		Sean Meirose			Added Matt Rock's filter for hexadecimal null and registered trademark symbol
**********************************************************************************************************************/

 cast(Code as VARCHAR(254)) as Code,
REPLACE((REPLACE(Description,0x1A,'')),' ','') as Description, 
SupplyRollUp,
Vendor,
Manufacturer 
from (
select
ors.SUPPLY_ID 									as Code
,ors.SUPPLY_NAME 								as Description
,coalesce(itp.NAME,'') 								as SupplyRollUp
,coalesce(zcs.NAME,'')								as Vendor
,coalesce(zcm.NAME,'') 								as Manufacturer
from 	   SOURCE_UWHEALTH.EPIC_OR_SPLY_CUR ors 
  left join SOURCE_UWHEALTH.EPIC_ZC_OR_SUPPLIER_CUR zcs on ors.LAST_SUPPLIER_C = zcs.SUPPLIER_C
  left join SOURCE_UWHEALTH.EPIC_ZC_OR_TYPE_OF_ITEM_CUR itp on ors.TYPE_OF_ITEM_C = itp.TYPE_OF_ITEM_C                   
  left join SOURCE_UWHEALTH.EPIC_OR_SPLY_MANFACTR_CUR orm on ors.supply_id = orm.ITEM_ID and orm.LINE = 1
  left join SOURCE_UWHEALTH.EPIC_ZC_OR_MANUFACTURER_CUR zcm on orm.MANUFACTURER_C = zcm.MANUFACTURER_C

union all

select imp.implant_id + 100000000				as Code
,imp.implant_name								as Description
,coalesce(ipt.name,'')								as SupplyRollUp
,coalesce(zcs.name,'')								as Vendor
,coalesce(zcm.name,'')								as Manufacturer

from 	   SOURCE_UWHEALTH.EPIC_OR_IMP_CUR imp
 left join SOURCE_UWHEALTH.EPIC_ZC_OR_SUPPLIER_CUR zcs on imp.vendor_distrib_c = zcs.SUPPLIER_C
 left join SOURCE_UWHEALTH.EPIC_ZC_OR_IMPLANT_TYPE_CUR ipt on imp.implant_type_c = ipt.IMPLANT_TYPE_C                
 left join SOURCE_UWHEALTH.EPIC_ZC_OR_MANUFACTURER_CUR zcm on IMP.MANUFACTURER_C = zcm.MANUFACTURER_C
) foo;
GO


