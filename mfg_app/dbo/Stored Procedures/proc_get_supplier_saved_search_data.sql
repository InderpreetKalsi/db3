

/*

exec proc_get_supplier_saved_search_filters
-- truncate table mp_saved_search_exclude_rfqs

select * from mp_saved_search_exclude_rfqs
select top 100 * from mp_email_messages order by 1 desc 
exec proc_get_supplier_saved_search_data @contact_id = 1365839 ,@save_search_id = 1972218

SELECT * FROM mpSavedSearchEmailLogs

select * from mp_contacts where contact_id = '1365839'
select * from mp_companies where company_id = 1795393
*/
CREATE PROCEDURE [dbo].[proc_get_supplier_saved_search_data]
(
	@save_search_id int,
	@contact_id		int  

)
as
begin
	/*	Dec 26, 2019 M2-2496 RFQ Email Template Change - DB	*/
	/*  Feb 19, 2020 M2-2598 Update RFQ saved search email logic to prioritize higher rated RFQs - DB */
	/*  Feb 26, 2020 M2-2639 Saved Search Unique RFQ Filter */
	/*
		Mar 27, 2020
		1. Remove un-validated buyer RFQ's from saved search emails
		2. Remove specially invited RFQ's from saved search emails
		3. Exclude RFQ's with Do Not Include quality
		4. Exclude RFQ's created using test buyer account 
	*/
	
	set nocount on

	truncate table mp_saved_search_exclude_rfqs

	-- declare required varible to generate data
	declare @manufacturing_location_id	smallint  
	declare @inputdate					varchar(8) 
	declare @where_query				nvarchar(max)
	declare @extra_field				nvarchar(max)
	declare @latitude					float=null
	declare @longitude					float=null
	declare @proximities_value			varchar(50)
	declare @blacklisted_rfqs table (rfq_id int)
	declare @sql_query_rfq_list_based_on_processes nvarchar(max)
	declare @suppliercompid				int 
	declare @ProcessIDs					as tbltype_ListOfProcesses			
	declare @MaterialIDs				as tbltype_ListOfMaterials			
	declare @PostProcessIDs				as tbltype_ListOfPostProcesses		
	declare @BuyerTerritories			as tbltype_ListOfTerritories		
	declare @BuyerStates				as tbltype_ListOfStates				
	declare @Proximities				as tbltype_ListOfProximities		
	declare @Tolerances					as tbltype_ListOfTolerances
	declare @BuyerIndustryId			as tbltype_ListOfBuyerIndustryId	
	/* M2-3810 M - Add search by Certification as a filter on the My RFQ's page-DB */
	declare @CerticateId				as tbltype_ListOfCertificateCodes
	/**/		
	declare @Geometry					int		
	declare @unit_of_measure_id			int		
	declare @width_min					float	
	declare @width_max					float	
	declare @height_min					float	
	declare @height_max					float	
	declare @depth_min					float	
	declare @depth_max					float	
	declare @length_min					float	
	declare @length_max					float	
	declare @diameter_min				float	
	declare @diameter_max				float	
	declare @volume						float	
	declare @filter						varchar(500) 
	declare @username					varchar(250)
	declare @useremail					varchar(500) 
	declare @sourcingadvisor			varchar(250) 
	declare @sourcingadvisorno			varchar(150) 
	declare @sourcingadvisordesignation	varchar(150) 
	declare @sourcingadvisoremail		varchar(150) 
	declare @rfq_deeplink				nvarchar(1000) 
	declare @filter_deeplink			nvarchar(1000) 
	declare @rfq_thumbnails				nvarchar(1000) 
	declare @rfq_default_thumbnails		nvarchar(1000) 
	declare @IsLargePart				bit
		
	-- dropping temp table 
	drop table if exists #tmp_finaloutput

	/* M2-2818 Saved Search optimization - DB */
	TRUNCATE TABLE [tmp_trans].[saved_search_rfqlocation]
	TRUNCATE TABLE [tmp_trans].[saved_search_rfq_list]
	TRUNCATE TABLE [tmp_trans].[saved_search_rfq_list_for_parts_search]
	TRUNCATE TABLE [tmp_trans].[saved_search_filtered_rfq_list]
	TRUNCATE TABLE [tmp_trans].[saved_search_rfq_likes]
	TRUNCATE TABLE [tmp_trans].[saved_search_geocode]
	/**/


	if db_name() = 'mp2020_dev'
	begin
		set @rfq_deeplink = 'http://qa.mfg2020.com/#/supplier/supplerRfqDetails?id='
		set @filter_deeplink = 'http://qa.mfg2020.com/#/supplier/supplermyrfq?savedSearchId=' + convert(varchar(150),@save_search_id)
		set @rfq_thumbnails = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.public/thumbnails/'
	end
	else if db_name() = 'mp2020_uat'
	begin
		set @rfq_deeplink = 'https://uatapp.mfg.com/#/supplier/supplerRfqDetails?id='
		set @filter_deeplink = 'https://uatapp.mfg.com/#/supplier/supplermyrfq?savedSearchId='+ convert(varchar(150),@save_search_id)
		set @rfq_thumbnails = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.public/thumbnails/'
	end
	else if db_name() = 'mp2020_prod'
	begin
		set @rfq_deeplink = 'https://app.mfg.com/#/supplier/supplerRfqDetails?id='
		set @filter_deeplink = 'https://app.mfg.com/#/supplier/supplermyrfq?savedSearchId='+ convert(varchar(150),@save_search_id)
		set @rfq_thumbnails = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.public/thumbnails/'
	end
	
	set @rfq_default_thumbnails = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020/thumbnails/3-d-big.png'

	-- fetching supplier info
	select 
		@username = isnull(a.first_name,'') + ' ' + isnull(a.last_name,'')
		,@useremail = b.email
		,@sourcingadvisor = isnull(d.first_name,'') + ' ' + isnull(d.last_name,'')
		,@sourcingadvisordesignation = d.title
		,@sourcingadvisorno = communication_value
		,@sourcingadvisoremail = f.email
	from mp_contacts		(nolock) a
	join aspnetusers		(nolock) b on a.user_id = b.id
	left join mp_companies	(nolock) c on a.company_id = c.company_id
	left join mp_contacts	(nolock) d on c.assigned_sourcingadvisor = d.contact_id
	left join aspnetusers	(nolock) f on d.user_id = f.id
	left join mp_communication_details	(nolock) e on d.contact_id = e.contact_id and communication_type_id =1
	where a.contact_id = @contact_id
				
	-- fetching search filter name
	select @filter = search_filter_name from mp_saved_search (nolock) where contact_id = @contact_id and saved_search_id = @save_search_id

	-- fetching current date
	set @inputdate = convert(varchar(8),format(getutcdate(),'yyyyMMdd'))
	
	-- fetching info like supplier company , territory & processes
	set @suppliercompid	= (select company_id from mp_contacts (nolock) where contact_id = @contact_id)
	set @manufacturing_location_id  = (select manufacturing_location_id from mp_companies (nolock) where company_id = @suppliercompid)
	
	-- if territory is US or Canada , then adding additional territory which is USA & Canada to the supplier territory
	if @manufacturing_location_id = 4 
		insert into [tmp_trans].[saved_search_rfqlocation] values (7), (4)
	else if @manufacturing_location_id = 5
		insert into [tmp_trans].[saved_search_rfqlocation] values (7), (5)
	else if @manufacturing_location_id not in (4,5)
		insert into [tmp_trans].[saved_search_rfqlocation] values (@manufacturing_location_id)
	

	-- excluding RFQ's related to blacklisted supplier or buyer
	insert into @blacklisted_rfqs (rfq_id)
	select distinct c.rfq_id 
	from mp_book_details					a (nolock)
	   join mp_books							b (nolock) on a.book_id = b.book_id 
	   join mp_rfq								c (nolock) on b.contact_id = c.contact_id
	left join mp_rfq_quote_supplierquote	f (nolock) on c.rfq_id = f.rfq_id and f.contact_id = @contact_id
	left join mp_rfq_quote_items			e (nolock) on f.rfq_quote_SupplierQuote_id= e.rfq_quote_SupplierQuote_id
	   where bk_type= 5 and a.company_id = @suppliercompid and  ((f.is_quote_submitted = 0 or f.is_quote_submitted is null)and  isnull(e.is_awrded,0) = 0)
	union  -- exclude rfq's for black listed buyer which are awarded & quoted 
	select distinct c.rfq_id  
	from mp_book_details					a (nolock) 
	   join mp_books							b (nolock) on a.book_id = b.book_id  and b.contact_id = @contact_id
	join mp_contacts						d (nolock) on a.company_id =  d.company_id
	join mp_rfq								c (nolock) on d.contact_id = c.contact_id
	left join mp_rfq_quote_supplierquote	f (nolock) on c.rfq_id = f.rfq_id and f.contact_id = @contact_id
	left join mp_rfq_quote_items			e (nolock) on f.rfq_quote_SupplierQuote_id= e.rfq_quote_SupplierQuote_id
	   where bk_type= 5 and  ((f.is_quote_submitted = 0 or f.is_quote_submitted is null)and  isnull(e.is_awrded,0) = 0)
	/* M2-3251  Vision - Flag as a test account and hide the data from reporting - DB */
	union
	select distinct b.rfq_id
	from mp_contacts	(nolock) a
	join mp_rfq		(nolock) b on a.contact_id = b.contact_id 
	where is_buyer = 1 and isnull(a.istestaccount,0) = 1 
	/**/
	
			
	-- fetching filter values and assign it to varibles declared
	select 
		@geometry		=  isnull(geometry_id,-1)
		, @width_min	=  isnull(width_min,-1)
		, @width_max	=  isnull(width_max,-1)
		, @height_min	=  isnull(height_min,-1)
		, @height_max	=  isnull(height_max,-1)
		, @depth_min	=  isnull(depth_min,-1)
		, @depth_max	=  isnull(depth_max,-1)
		, @length_min	=  isnull(length_min,-1)
		, @length_max	=  isnull(length_max,-1)
		, @diameter_min =  isnull(diameter_min,-1)
		, @diameter_max =  isnull(diameter_max,-1)
		, @volume		=  isnull(volume,-1)
		, @IsLargePart  = IsLargePart 
		, @unit_of_measure_id = unit_of_measure_id
	from mp_saved_search (nolock) where contact_id = @contact_id and saved_search_id = @save_search_id


	-- fetching filter values and assign it to varibles declared
	insert into @ProcessIDs 
	select distinct part_category_id from mp_saved_search_processes (nolock) where saved_search_id = @save_search_id
	union
	select part_category_id from mp_mst_part_category (nolock) where  parent_part_category_id in (select distinct part_category_id from mp_saved_search_processes (nolock) where saved_search_id = @save_search_id) and status_id = 2



	insert into @MaterialIDs 
	select distinct value from string_split((select material_id from mp_saved_search (nolock) where contact_id = @contact_id and saved_search_id = @save_search_id),',') where value <> ''
	insert into @PostProcessIDs 
	select distinct value from string_split((select post_process_id from mp_saved_search (nolock) where contact_id = @contact_id and saved_search_id = @save_search_id),',') where value <> ''
	insert into @BuyerTerritories 
	select distinct value from string_split((select buyer_location_id from mp_saved_search (nolock) where contact_id = @contact_id and saved_search_id = @save_search_id),',') where value <> ''
	insert into @BuyerStates 
	select distinct value from string_split((select region_id from mp_saved_search (nolock) where contact_id = @contact_id and saved_search_id = @save_search_id),',') where value <> ''
	insert into @Proximities 
	select distinct value from string_split((select proximity_id from mp_saved_search (nolock) where contact_id = @contact_id and saved_search_id = @save_search_id),',') where value <> ''
	insert into @Tolerances 
	select distinct value from string_split((select tolerance_id from mp_saved_search (nolock) where contact_id = @contact_id and saved_search_id = @save_search_id),',') where value <> ''
	insert into @BuyerIndustryId 
	select distinct value from string_split((select BuyerIndustryId from mp_saved_search (nolock) where contact_id = @contact_id and saved_search_id = @save_search_id),',') where value <> ''
	/* M2-3810 M - Add search by Certification as a filter on the My RFQ's page-DB */
	insert into @CerticateId
	select distinct value from string_split((select certificate_ids from mp_saved_search (nolock) where contact_id = @contact_id and saved_search_id = @save_search_id),',') where value <> ''
	/**/

	-- jan 28 2020 : if in filter capabilities is blank then it will look for capabilities defined under company profile 
	if ((select count(1) from @ProcessIDs ) =0 )
	begin

		insert into @ProcessIDs 
		select distinct part_category_id from mp_company_processes (nolock) 
		where company_id = @suppliercompid and part_category_id in (select part_category_id from mp_active_capabilities (nolock)  )
		/* M2-2739 */
		union
		select distinct part_category_id from  mp_gateway_subscription_company_processes a (nolock)  where company_id = @suppliercompid
		/**/
	end
	
	-- if proximity value exists then fetching nearby buyer's based on range defined
	if (select count(1) from @Proximities) > 0
	begin
	
		select 
			@latitude= c.latitude
			, @longitude = c.longitude
		from mp_contacts			(nolock) a 
		join mp_addresses			(nolock) b on a.address_id = b.address_id 
			-- and b.is_geocode_data_added =1  
			and a.contact_id in (@contact_id)
		join mp_mst_country			(nolock) d on b.country_id = d.country_id
		join mp_mst_geocode_data	(nolock) c on b.address3 = c.zipcode and d.country_name = c.country
		
		select @proximities_value = value from mp_system_parameters where id in  (select * from @Proximities)

	
		insert into [tmp_trans].[saved_search_geocode]
		(zipcode, distance)
		select * from 
		(
			select
				zipcode, 
				(
					3959 * acos 
					(
						cos (radians(@latitude) )
						* cos( radians( mp_mst_geocode_data.latitude ) )
						* cos( radians( mp_mst_geocode_data.longitude ) - radians(@longitude) 
					)
					+ sin ( radians(@latitude) )* sin( radians( mp_mst_geocode_data.latitude ) )	)
				) as distance
			from mp_mst_geocode_data
			where  latitude <> 0 and longitude <>0
		) a
		where a.distance < @proximities_value

		
	end

	-- fetching disliked RFQ's by supplier and will exclude from the list
	INSERT INTO [tmp_trans].[saved_search_rfq_likes](rfq_id ,is_rfq_like)
	select rfq_id ,is_rfq_like  from  mp_rfq_supplier_likes a	(nolock) where contact_id = @contact_id 

	-- fetching RFQ's based on supplier processes where RFQ status = Quoting and Quote needed by date should be greater than & equal to today's date
	set @sql_query_rfq_list_based_on_processes=			
	'
	insert into [tmp_trans].[saved_search_rfq_list] (rfq_id)
	select distinct a.rfq_id 
	from mp_rfq			a (nolock) 
	join mp_rfq_parts	b (nolock) on a.rfq_id = b.rfq_id 
	join mp_parts		c (nolock) on b.part_id  = c.part_id 
		and a.rfq_status_id = 3
		and format(a.quotes_needed_by,''yyyyMMdd'') >= '''+@inputdate+''' 
	join mp_rfq_preferences		mrp (nolock) on a.rfq_id = mrp.rfq_id and mrp.rfq_pref_manufacturing_location_id in (select * from [tmp_trans].[saved_search_rfqlocation] (nolock)) 
	left join  @processids1 d on  b.part_category_id = d.processId
	where b.part_category_id  =  ' + case when ((select count(1) from @ProcessIDs) > 0) then ' d.processId '  else ' b.part_category_id 'end 
	
	exec sp_executesql  @sql_query_rfq_list_based_on_processes 
	,N'@processids1  tbltype_ListOfProcesses readonly'
	,@processids1  = @Processids	


	-- generating dynamic sql based on filter values
	set @sql_query_rfq_list_based_on_processes=			
	'
	insert into [tmp_trans].[saved_search_filtered_rfq_list] (rfq_id)
	select distinct a.rfq_id 
	from mp_rfq			a	(nolock) 
	join mp_rfq_parts	b	(nolock) on a.rfq_id = b.rfq_id 
	join mp_parts		c	(nolock) on b.part_id  = c.part_id 
	join mp_contacts	mc	(nolock) on a.contact_id = mc.contact_id 
	/* 	Mar 27, 2020 */
		and mc.is_validated_buyer = 1
		and isnull(a.rfq_quality,0) > -1
		and a.contact_id <> 1336138

	join mp_rfq_supplier mrs (nolock) on a.rfq_id = mrs.rfq_id and mrs.company_id = -1
	/* 	 */
	join mp_companies	mcom	(nolock) on mc.company_id = mcom.company_id 
		and a.rfq_status_id = 3
		and format(a.quotes_needed_by,''yyyyMMdd'') >= '''+@inputdate+''' 
	join mp_rfq_preferences		mrp (nolock) on a.rfq_id = mrp.rfq_id and mrp.rfq_pref_manufacturing_location_id in (select * from [tmp_trans].[saved_search_rfqlocation] (nolock))  
	left join vw_address		vwa (nolock) on mc.address_id = vwa.address_Id	
	/* M2-3384 : M & Vision - My RFQs - Search by Buyers Industry -DB */
	left join mp_company_supplier_types mcst (nolock) on mcom.company_id = mcst.company_id and mcst.is_buyer = 1
	/**/
	/* M2-3810 M - Add search by Certification as a filter on the My RFQs page-DB */
	left join mp_rfq_special_certificates (nolock)  mrsc on a.rfq_id = mrsc.rfq_id
	/**/ 
	'

	if @unit_of_measure_id = 5
	begin
		if @width_min	<> -1 
			set @width_min = @width_min * 0.0393701
		
		if @width_max	<> -1 
			set @width_max = @width_max * 0.0393701
		
		if @height_min	<> -1 
			set @height_min = @height_min * 0.0393701
			
		if @height_max	<> -1 
			set @height_max = @height_max * 0.0393701
			
		if @depth_min	<> -1 
			set @depth_min = @depth_min * 0.0393701
			
		if @depth_max	<> -1 
			set @depth_max = @depth_max * 0.0393701
			
		if @length_min	<> -1 
			set @length_min = @length_min * 0.0393701
			
		if @length_max	<> -1 
			set @length_max = @length_max * 0.0393701
			
		if @diameter_min <> -1 
			set @diameter_min = @diameter_min * 0.0393701
			
		if @diameter_max <> -1 
			set @diameter_max = @diameter_max * 0.0393701
			
	end

	set @extra_field =  
		case 
			when @Geometry in  (-1,0) AND @unit_of_measure_id = 0 then
				case
					when @IsLargePart is null then ''
					when @IsLargePart = 0 then ' and ( IsLargePart = 0) '
					when @IsLargePart = 1 then ' and ( IsLargePart = 1) '
				end
			when @Geometry in  (-1,0) AND @unit_of_measure_id IN (5) then
				case
					when @IsLargePart is null then ''
					when @IsLargePart = 0 then ' and ( part_qty_unit_id = 5 AND IsLargePart = 0) '
					when @IsLargePart = 1 then ' and ( part_qty_unit_id = 5 AND IsLargePart = 1) '
				end			
			when @Geometry in  (-1,0) AND @unit_of_measure_id IN (9) then
				case
					when @IsLargePart is null then ''
					when @IsLargePart = 0 then ' and ( part_qty_unit_id = 9 AND IsLargePart = 0) '
					when @IsLargePart = 1 then ' and ( part_qty_unit_id = 9 AND IsLargePart = 1) '
				end	
			when @Geometry = 58  AND @unit_of_measure_id =0 then
				case 
					when @IsLargePart is null then ''
					when @IsLargePart = 0 then ' and ( GeometryId = 58 and IsLargePart = 0) '
					when @IsLargePart = 1 then ' and ( GeometryId = 58 and  IsLargePart = 1) '
				
				end 
			when @Geometry = 58  AND @unit_of_measure_id IN (5) then
				case 
					when @IsLargePart is null then ''
					when @IsLargePart = 0 then ' and ( GeometryId = 58 and part_qty_unit_id = 5 AND IsLargePart = 0) '
					when @IsLargePart = 1 then ' and ( GeometryId = 58 and  part_qty_unit_id = 5 AND IsLargePart = 1) '
				
				end 
			when @Geometry = 58  AND @unit_of_measure_id IN (9) then
				case 
					when @IsLargePart is null then ''
					when @IsLargePart = 0 then ' and ( GeometryId = 58 and part_qty_unit_id = 9 AND IsLargePart = 0) '
					when @IsLargePart = 1 then ' and ( GeometryId = 58 and  part_qty_unit_id = 9 AND IsLargePart = 1) '
				
				end 
			when @Geometry = 59  AND @unit_of_measure_id =0 then
				case 
					when @IsLargePart is null then ''
					when @IsLargePart = 0 then ' and ( GeometryId = 59 and IsLargePart = 0) '
					when @IsLargePart = 1 then ' and ( GeometryId = 59 and  IsLargePart = 1) '
				
				end 
			when @Geometry = 59  AND @unit_of_measure_id IN (5) then
				case 
					when @IsLargePart is null then ''
					when @IsLargePart = 0 then ' and ( GeometryId = 59 and part_qty_unit_id = 5 AND IsLargePart = 0) '
					when @IsLargePart = 1 then ' and ( GeometryId = 59 and  part_qty_unit_id = 5 AND IsLargePart = 1) '
				
				end 
			when @Geometry = 59  AND @unit_of_measure_id IN (9) then
				case 
					when @IsLargePart is null then ''
					when @IsLargePart = 0 then ' and ( GeometryId = 59 and part_qty_unit_id = 9 AND IsLargePart = 0) '
					when @IsLargePart = 1 then ' and ( GeometryId = 59 and  part_qty_unit_id = 9 AND IsLargePart = 1) '
				
				end 
				
						
			else ''
		end 
	
	set @where_query = 
	case when (select count(1) from @ProcessIDs) > 0 then ' a.rfq_id in (select * from  [tmp_trans].[saved_search_rfq_list] (nolock)) ' else '' end
	+ case when (select count(1) from @MaterialIDs) > 0 then ' and b.material_id in (select * from  @MaterialIDs1 ) ' else '' end
	+ case when (select count(1) from @PostProcessIDs) > 0 then ' and b.post_production_process_id in (select * from  @PostProcessIDs1 ) ' else '' end
	/* M2-3810 M - Add search by Certification as a filter on the My RFQ's page-DB */
	+ case when (select count(1) from @CerticateId) > 0 then ' and mrsc.certificate_id in (select * from  @CerticateId1 ) ' else '' end 
	/**/
	+ case when (select count(1) from @BuyerTerritories) > 0 then ' and mcom.manufacturing_location_id in (select * from  @BuyerTerritories1 '+ case when (select count(1) from @BuyerTerritories where territoryId = 7) > 0 then ' union select 4 union select 5  ' when (select count(1) from @BuyerTerritories where territoryId in (4,5)) > 0 then ' union select 7 ' else '' end +' ) ' else '' end
	+ case when (select count(1) from @BuyerStates) > 0 then ' and vwa.regionId in (select * from  @BuyerStates1 ) ' else '' end
	+ case when @Geometry = 58 then @extra_field else '' 
	   end
	+ case when @Geometry = 59 then @extra_field else '' 
	  end
	+ case when @Geometry in (0,-1) then @extra_field else '' 
	  end
	+ case when (select count(1) from @Tolerances) > 0 then ' and c.tolerance_id in (select * from  @Tolerances1 ) ' else '' end
	+ case when (select count(1) from @Proximities) > 0 then 
		' and a.rfq_id in (select distinct f.rfq_id
			from [tmp_trans].[saved_search_geocode] a (nolock)
			join mp_addresses	(nolock) b on a.zipcode = b.address3
			join mp_mst_country (nolock) c on b.country_id = c.country_id 
			join mp_contacts	(nolock) d on b.address_id = d.address_id and d.is_buyer =1 
			join mp_companies	(nolock) e on d.company_id = e.company_id and e.manufacturing_location_id in  (select * from [tmp_trans].[saved_search_rfqlocation] (nolock))
			join mp_rfq			(nolock) f on d.contact_id = f.contact_id and f.rfq_status_id in  (3 , 5, 6 ) ) ' else '' end
	/* M2-3384 : M & Vision - My RFQs - Search by Buyer's Industry -DB */
    + case when (select count(1) from @BuyerIndustryId) > 0 then ' and mcst.supplier_type_id in (select * from  @BuyerIndustryId1) ' else '' end

	if left(@where_query,5) = ' and '
		set @where_query = substring(@where_query , 6, len(@where_query))
		
	set  @sql_query_rfq_list_based_on_processes = @sql_query_rfq_list_based_on_processes + case when len(@where_query) > 0 then ' where ' else '' end + @where_query 
	
	
	exec sp_executesql  @sql_query_rfq_list_based_on_processes 
	,N'@MaterialIDs1 tbltype_ListOfMaterials readonly , @PostProcessIDs1 as tbltype_ListOfPostProcesses	 readonly ,@CerticateId1 tbltype_ListOfCertificateCodes readonly ,@BuyerTerritories1 as tbltype_ListOfTerritories readonly, @BuyerStates1 as tbltype_ListOfStates readonly,@Tolerances1 as tbltype_ListOfTolerances	readonly,@BuyerIndustryId1 as tbltype_ListOfBuyerIndustryId	readonly'
	,@MaterialIDs1 = @MaterialIDs
	,@PostProcessIDs1 = @PostProcessIDs
	,@BuyerTerritories1 = @BuyerTerritories
	,@BuyerStates1 = @BuyerStates
	,@Tolerances1 = @Tolerances
	,@BuyerIndustryId1 = @BuyerIndustryId
	,@CerticateId1 = @CerticateId /* M2-3810 M - Add search by Certification as a filter on the My RFQ's page-DB */



	-- return top 3 recently released RFQ's (released yesterday)
	select top 3 
		@save_search_id										as SearchFilterId
		, @filter											as SearchFilter 
		, a.rfq_id											as RfqId 
		, (convert(varchar(150),(select max(convert(bigint,part_qty)) from mp_rfq_part_quantity b1 (nolock) where b.rfq_part_id = b1.rfq_part_id and is_deleted = 0))  + ' ' + m.value )					as Quantity
		, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end			as PartCategoryName
		, k.material_name_en								as PartsMaterialName  
		, convert(varchar(150),(datediff(day,getutcdate(),quotes_needed_by )))+ ' days'		as RfqCloses
		, convert(date,rfq_release.release_date)			as RFQRelease
		, @contact_id										as ContactId
		, @username											as Contact
		, @useremail										as ContactEmail
		, @sourcingadvisor									as SourcingAdvisor
		, @sourcingadvisordesignation						as SourcingAdvisorDesignation
		, @sourcingadvisorno								as SourcingAdvisorNo
		, @sourcingadvisoremail								as SourcingAdvisorEmail
		, @rfq_deeplink	+ convert(varchar(500),rfq_guid)	as RFQDeepLink						
		, @filter_deeplink									as FilterDeepLink
		, isnull(@rfq_thumbnails+j.file_name,@rfq_default_thumbnails) as RFQImage
		, a.rfq_quality
	/* M2 - 4222 Saved Search Email- Template version - DB */
		,IIF(Len(a.rfq_name)>50,LEFT(a.rfq_name,50)+'...', a.rfq_name) AS RFQName
	/* M2-2639 Saved Search Unique RFQ Filter */
	into #tmp_finaloutput
	/**/
	from mp_rfq							(nolock) a
	join mp_rfq_parts b					(nolock) on a.rfq_id = b.rfq_id and b.is_rfq_part_default =  1 and a.rfq_id in  (select * from [tmp_trans].[saved_search_filtered_rfq_list] (nolock))
	join mp_parts d						(nolock) on b.part_id = d.part_id
	left join mp_mst_materials	k		(nolock) on d.material_id = k.material_id 
	left join mp_mst_part_category l	(nolock) on d.part_category_id = l.part_category_id
	/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
	left join mp_mst_part_category category (nolock) on l.parent_part_category_id=category.part_category_id
	/**/
	left join mp_system_parameters m	(nolock) on b.quantity_unit_id = m.id 
	left join 
	(
		select rfq_id , max(status_date) release_date 
		from mp_rfq_release_history (nolock) 
		where rfq_id in  (select * from [tmp_trans].[saved_search_filtered_rfq_list] (nolock) ) group by rfq_id 
	) rfq_release on a.rfq_id = rfq_release.rfq_id
	left join mp_special_files		j	(nolock)  on a.file_id = j.file_id
	where 
		a.rfq_id in  (select * from [tmp_trans].[saved_search_filtered_rfq_list] (nolock))
		and convert(date,rfq_release.release_date) >=  (case when format(getutcdate(),'dddd') = 'Monday' then   convert(date,getutcdate() -3) else  convert(date,getutcdate()  -1) end )
	/* M2-2639 Saved Search Unique RFQ Filter */	
		and a.rfq_id not in (select rfq_id from mp_saved_search_exclude_rfqs (nolock) where contact_id = @contact_id)
	/**/
	order by isnull(a.rfq_quality,1000) , RFQRelease desc 

	/* M2-2639 Saved Search Unique RFQ Filter */
	select a.*, b.NoofParts from #tmp_finaloutput a
	JOIN 
	(
		SELECT Parts.rfq_id,COUNT(rfq_part_id) NoofParts 
		FROM mp_rfq_parts Parts 
		join #tmp_finaloutput   b on Parts.rfq_id = b.RfqId 
		GROUP BY Parts.rfq_id
	)  b on a.RfqId = b.rfq_id


	if ((select distinct contact_id from mp_saved_search_exclude_rfqs ) != @contact_id)
	begin
		truncate table mp_saved_search_exclude_rfqs
	end

	insert into mp_saved_search_exclude_rfqs
	select ContactId, RfqId from #tmp_finaloutput

	-- Saved Search Log 
	INSERT INTO mpSavedSearchEmailLogs (ContactId , RfqId , SavedSearchId ,LogDate )
	SELECT ContactId, RfqId , @save_search_id , GETUTCDATE() from #tmp_finaloutput

	
	/**/

	-- dropping temp table 
	drop table if exists #tmp_finaloutput

	/* M2-2818 Saved Search optimization - DB */
	TRUNCATE TABLE [tmp_trans].[saved_search_rfqlocation]
	TRUNCATE TABLE [tmp_trans].[saved_search_rfq_list]
	TRUNCATE TABLE [tmp_trans].[saved_search_rfq_list_for_parts_search]
	TRUNCATE TABLE [tmp_trans].[saved_search_filtered_rfq_list]
	TRUNCATE TABLE [tmp_trans].[saved_search_rfq_likes]
	TRUNCATE TABLE [tmp_trans].[saved_search_geocode]
	/**/
end
