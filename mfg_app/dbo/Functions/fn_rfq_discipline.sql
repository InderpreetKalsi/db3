CREATE function [dbo].[fn_rfq_discipline](@part_category_id int , @level int)
RETURNS TABLE
AS
RETURN  
(
	with cte1
	as
	(
		select part_category_id as childid, discipline_name as name,parent_part_category_id as parentid, 0 AS level , level as actuallevel from mp_mst_part_category where part_category_id =  @part_category_id
		union all 
		select mp_mst_part_category.part_category_id,mp_mst_part_category.discipline_name,mp_mst_part_category.parent_part_category_id, cte1.level +1, mp_mst_part_category.level as actuallevel from mp_mst_part_category inner join cte1 on mp_mst_part_category.part_category_id=cte1.parentid
		where cte1.level <= (select level from mp_mst_part_category where part_category_id =  @part_category_id) -1 
	)
	select top 1 * from cte1 D1  where D1.actuallevel =@level
)
