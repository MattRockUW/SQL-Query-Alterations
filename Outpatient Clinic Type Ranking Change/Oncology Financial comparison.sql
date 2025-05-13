

with original as (
select op_enc_type, op_enc_type_desc, gl_building_id, gl_building_name, 
count(distinct visit_id) as 'Original DistinctVisitIDCount', 
sum(chgs) as 'Original TotalChgs', 
sum(NetRev) as 'Original TotalNetRev', 
sum(vdcost) as 'Original TotalVDCost', 
sum(fdcost) as 'Original TotalFDCost',
sum(vicost) as 'Original TotalVIcost', 
sum(ficost) as 'Original TotalFICost'
from mart_uwhealth.[ONCOLOGY_FINANCIAL]
group by op_enc_type, op_enc_type_desc, gl_building_id, gl_building_name
),

corrected as (
select op_enc_type, op_enc_type_desc, gl_building_id, gl_building_name, 
count(distinct visit_id) as 'Corrected DistinctVisitIDCount', 
sum(chgs) as 'Corrected TotalChgs', 
sum(NetRev) as 'Corrected TotalNetRev', 
sum(vdcost) as 'Corrected TotalVDCost', 
sum(fdcost) as 'Corrected TotalFDCost',
sum(vicost) as 'Corrected TotalVIcost', 
sum(ficost) as 'Corrected TotalFICost'
from adhoc_uwhealth.[ONCOLOGY_FINANCIAL]
group by op_enc_type, op_enc_type_desc, gl_building_id, gl_building_name
)

select * from original o
full outer join corrected c on
o.op_enc_type = c.op_enc_type and
o.op_enc_type_desc = c.op_enc_type_desc and 
o.gl_building_id = c.gl_building_id and
o.gl_building_name = c.gl_building_name

