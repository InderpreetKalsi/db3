
/*

exec proc_get_buyer_open_rfq_details  @rfq_id = 1179886       ,@supplier_id =1337894


*/
CREATE procedure [dbo].[proc_get_buyer_open_rfq_details]
(
	@rfq_id int
	,@supplier_id int
)
as
begin
	/* M2-2031 M - Buyer Profile - Add the number of RFQ's the buyer has open to the profile and make a clickable link - DBk */

	set nocount on

	declare @company_capabilities int  = 0
	declare @manufacturing_location_id smallint  
	declare @sql_query_rfq_list_based_on_processes nvarchar(max)
	declare @supplier_company_id int
	declare @inputdate varchar(8) 
	declare @rfq_with_capabilities_matched int 
	
	drop table if exists #rfq_list
	/*  M2-2087 Clone up to 3 RFQ's for 3 regions - API */
	drop table if exists #rfqlocation
	/**/

	create table #rfq_list (rfq_id int)
	/*  M2-2087 Clone up to 3 RFQ's for 3 regions - API */
	create table #rfqlocation (rfq_location int)
	/**/

	
	set @supplier_company_id = (select company_id from mp_contacts (nolock) where contact_id = @supplier_id)
	set @company_capabilities = (select count(1) from mp_company_processes  (nolock) where  company_id = @supplier_company_id)
	set @manufacturing_location_id  = (select manufacturing_location_id from mp_companies (nolock) where company_id = @supplier_company_id)
	set @inputdate = convert(varchar(8),format(getutcdate(),'yyyyMMdd'))
	
	/*  M2-2087 Clone up to 3 RFQ's for 3 regions - API */
	if @manufacturing_location_id = 4 
		insert into #rfqlocation values (7), (4)

	if @manufacturing_location_id = 5
		insert into #rfqlocation values (7), (5)

	if @manufacturing_location_id not in (4,5)
			insert into #rfqlocation values (@manufacturing_location_id)
	/**/
		
	
	set @sql_query_rfq_list_based_on_processes=			
	'
		insert into #rfq_list (rfq_id)
		select distinct a.rfq_id 
		from mp_rfq			a (nolock) 
		join mp_rfq_parts	b (nolock)  on a.rfq_id = b.rfq_id 
		join mp_parts		c (nolock)	on b.part_id  = c.part_id 
			and a.rfq_status_id = 3
			and a.rfq_id = '+convert(varchar(50),@rfq_id)+'
		join mp_rfq_preferences  mrp (nolock) on a.rfq_id = mrp.rfq_id 
			and mrp.rfq_pref_manufacturing_location_id in (select * from #rfqlocation)
		' +case when @company_capabilities = 0 then '' else ' 
		join
		(
			select distinct c.part_category_id 
			from 
			mp_mst_part_category b  (nolock)
			join mp_mst_part_category c  (nolock) on b.parent_part_category_id = c.parent_part_category_id 
			join mp_company_processes a	 (nolock)  on a.part_category_id = b.part_category_id 
				and  a.company_id = '+ convert(varchar(50),@supplier_company_id) +
	'		where  c.status_id = 2 
		) d on c.part_category_id = d.part_category_id
	' 
	end
	
	exec sp_executesql  @sql_query_rfq_list_based_on_processes
	

	select 
		
		b.rfq_id as RFQId 
		, b.rfq_name as RFQName
		, coalesce(p.file_name,'') as ImageUrl	 
		, (select count(1) from mp_rfq_parts (nolock)  where b.rfq_id = rfq_id) as NoOfParts 
		, convert(varchar(50),c.min_part_quantity) +' '+ c.min_part_quantity_unit as Unit  
		, k.material_name_en as Material  
		, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as Process
		, j.value as PostProcess  
		, (select top 1  part_qty from mp_rfq_part_quantity (nolock) where c.rfq_part_id = rfq_part_id and quantity_level = 0 and is_deleted = 0 ) as Qty001 
		, (select top 1 part_qty from mp_rfq_part_quantity (nolock) where c.rfq_part_id = rfq_part_id and quantity_level = 1 and is_deleted = 0 ) as Qty002 
		, (select top 1 part_qty from mp_rfq_part_quantity (nolock) where c.rfq_part_id = rfq_part_id and quantity_level = 2 and is_deleted = 0 ) as Qty003 
		, b.special_instruction_to_manufacturer as Brief 
		, b.quotes_needed_by as CloseOn
		, q.release_date as ReleaseOn
		, m.is_rfq_like IsLike 
		, case when (select count(1) from #rfq_list where b.rfq_id = rfq_id) = 0 then cast('false' as bit) else cast('true' as bit)  end as IsCapabilitiesMatched
		, case when (select count(1) from #rfqlocation where mrp.rfq_pref_manufacturing_location_id = rfq_location) = 0 then 
				cast('false' as bit) else cast('true' as bit)  end as IsRegionMatched
	from
	mp_rfq b							(nolock) 
	join mp_rfq_parts c					(nolock) on 
		b.rfq_id = c.rfq_id 
		and c.is_rfq_part_default =  1
		and b.rfq_id = @rfq_id
	join mp_parts d						(nolock) on c.part_id = d.part_id
	left join mp_system_parameters j	(nolock) on c.post_production_process_id = j.id and j.sys_key = '@PostProdProcesses' 
	left join mp_mst_materials	k		(nolock) on d.material_id = k.material_id 
	left join mp_mst_part_category l	(nolock) on d.part_category_id = l.part_category_id
	/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
	left join mp_mst_part_category category (nolock) on l.parent_part_category_id=category.part_category_id
	/**/
	left join mp_special_files p		(nolock) on p.file_id = b.file_id
	left join 
	(
		select 
			rfq_id 
			, max(status_date) release_date 
		from mp_rfq_release_history (nolock) group by rfq_id 
	) q on b.rfq_id = q.rfq_id
	left join mp_rfq_supplier_likes m	(nolock) on m.rfq_id = b.rfq_id  and m.contact_id = @supplier_id
	join mp_rfq_preferences  mrp		(nolock) on b.rfq_id = mrp.rfq_id 
	
	
end
