/*

declare @default_value int 
exec proc_get_qms_process_material_postproduction 
@get_type = 1 
, @supplier_company_id = 1768056  
,@supplier_id =  1337894 
, @defaultValue = @default_value output
select @default_value

*/
CREATE procedure [dbo].[proc_get_qms_process_material_postproduction]
(
	@get_type				smallint  -- 1 process -- 2 material -- 3 post production
	,@supplier_company_id	int
	,@supplier_id			int
	,@defaultValue			int output
	
)
as
begin

	/*  M2-2138 M - Create QMS - In the part drawer, make the process list a manual entry - DB*/

	set nocount on

	if @get_type = 1
	begin
	
		select b.qms_process_id as id , b.qms_process as value 
		,  case 
				when ((select count(1) from mp_qms_quote_parts (nolock) where  part_category_id = a.qms_process_id) = 0) then cast('true' as bit) 
				else cast('false' as bit) 
			end as IsRemovable
		from mp_qms_company_processes (nolock) a
		join mp_mst_qms_processes (nolock) b on a.qms_process_id = b.qms_process_id
		where 
			b.is_active  = 1 
			and a.supplier_company_id = @supplier_company_id
		union 
		select qms_process_id ,qms_process , cast('false' as bit) as IsRemovable from mp_mst_qms_processes where parent_id is not null
		order by value

	end
	else 	if @get_type = 2
	begin

		select b.qms_material_id as id , b.qms_material as value
			,  case 
				when ((select count(1) from mp_qms_quote_parts (nolock) where  material_id = a.qms_material_id) = 0) then cast('true' as bit) 
				else cast('false' as bit) 
			end as IsRemovable
		from mp_qms_company_materials (nolock) a
		join mp_mst_qms_materials (nolock) b on a.qms_material_id = b.qms_material_id
		where 
			b.is_active  = 1
			and a.supplier_company_id = @supplier_company_id
		union 
		select qms_material_id ,qms_material , cast('false' as bit) as IsRemovable from mp_mst_qms_materials where parent_id is not null
		order by value

	end
	else 	if @get_type = 3
	begin

		select b.qms_post_production_id as id , b.qms_post_production as value
		,  case 
				when ((select count(1) from mp_qms_quote_parts (nolock) where  post_production_id = a.qms_post_production_id) = 0) then cast('true' as bit) 
				else cast('false' as bit) 
			end as IsRemovable 
		from mp_qms_company_post_productions (nolock) a
		join mp_mst_qms_post_productions (nolock) b on a.qms_post_production_id = b.qms_post_production_id
		where 
			b.is_active  = 1 
			and a.supplier_company_id = @supplier_company_id
		union 
		select qms_post_production_id ,qms_post_production , cast('false' as bit) as IsRemovable from mp_mst_qms_post_productions where parent_id is not null
		order by value
	end

	set @defaultValue =  
	(		
			select default_value 
			from mp_qms_user_quote_settings (nolock)
			where contact_id = @supplier_id and qms_quote_setting_id = (case when @get_type = 1 then 1 when @get_type = 2 then 2  when @get_type = 3 then 3 end)
	)


end
