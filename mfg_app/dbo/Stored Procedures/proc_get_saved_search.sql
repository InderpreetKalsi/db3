

/*
exec proc_get_saved_search @save_search_id=1967422,@contact_id=1337848,@part_category_id=N'',@post_process_id=N'',@material_id=N'',@buyer_location_id=N'',@country_id=N'',@region_id=N'',@proximity_id=N'',@geometry_id=0,@unit_of_measure_id=0,@tolerance_id=N'',@width_min=0,@width_max=0,@height_min=0,@height_max=0,@depth_min=0,@depth_max=0,@length_min=0,@length_max=0,@diameter_min=0,@diameter_max=0,@par_pagination=1,@par_per_page_records=24,@sortorder=N'desc',@SearchText=N'',@IsOrderByDesc=1
*/
CREATE    procedure [dbo].[proc_get_saved_search]
(
	@save_search_id int,
	@contact_id int ,
	@part_category_id		nvarchar(max) = null,
	@post_process_id		varchar(max) = null,
	@material_id			varchar(max) = null ,
	@buyer_location_id		varchar(100) = null ,
	@country_id				varchar(250) = null ,
	@region_id				varchar(250) = null ,
	@proximity_id			varchar(100) = null ,
	@geometry_id			int = 0,
	@unit_of_measure_id		int = 0,
	@tolerance_id			varchar(100) = 0 ,
	@width_min				float = null ,
	@width_max				float = null ,
	@height_min				float = null ,
	@height_max				float = null ,
	@depth_min				float = null ,
	@depth_max				float = null ,
	@length_min				float = null ,
	@length_max				float = null ,
	@diameter_min			float = null ,
	@diameter_max			float = null ,
	@par_pagination			int	  = 1 ,
 	@par_per_page_records   int	  = 1000 ,
 	@sortorder				varchar(10)   = 'asc',
	@SearchText VARCHAR(50) = Null,
	@IsOrderByDesc BIT='true',
	@OrderBy VARCHAR(100) = Null	,
	@volume			float = null 
	 

)
as
begin
	/*
		created on :	dec 08,2018
		M2-686 Analyze the legacy db structure & Create the table structure in MP2020 to maintain the saved search feature
		
	*/

	--select * from mp_system_parameters

	--select * from mp_saved_search where geometry_id in  (1,2,3) order by saved_search_id desc 

	set nocount on
	 

	DECLARE @latitude float = NULL,
	@longitude float = NULL
	 
	 
	if(@contact_id > 0)
	BEGIN
		SELECT  @latitude = mp_mst_geocode_data.latitude , @longitude = mp_mst_geocode_data.longitude  
		from mp_contacts 
		join mp_addresses ON mp_contacts.address_id = mp_addresses.address_Id
		join mp_mst_geocode_data ON mp_addresses.address3 = mp_mst_geocode_data.zipcode
		where contact_id = @contact_id		 
	END

	if( (@latitude IS NOT NULL AND @latitude != 0  ) AND  (@longitude IS NOT NULL AND @longitude != 0) )
	BEGIN
		 SELECT
			zipcode, (
			  3959 * acos 
			( convert(decimal(15,8) , 
			  cos ( radians(@latitude) )
			  * cos( radians( latitude ) )
			  * cos( radians( longitude ) - radians(@longitude) )
			  + sin ( radians(@latitude) )
			  * sin( radians( latitude ) )
			))
		) AS distance
		into #geocode_tmp_table
		FROM mp_mst_geocode_data
	END


	if ( @OrderBy is null or @OrderBy = '' )
		set @OrderBy  = 'release_date'
	 
	
	set nocount on

	declare @part_category_id1 nvarchar(max) 
	declare @post_process_id1 nvarchar(max)
	declare @material_id1 nvarchar(max)
	declare @buyer_territory_id1 varchar(100)
	declare @rfq_country_id1 varchar(max)
	declare @rfq_region_id1 varchar(max)
	declare @unit_of_measure_id1 varchar(250)
	declare @tolerance_id1 varchar(100)
	declare @where_query nvarchar(max)
	declare @search_query nvarchar(max)	
	declare @sql_query nvarchar(max)
	--declare @sortorder1 varchar(10)
	declare @CompanyId INT
	declare @join_query nvarchar(max)
	declare @width_min1 varchar(100)
	declare @width_max1 varchar(100)
	declare @height_min1 varchar(100)
	declare @height_max1 varchar(100)
	declare @depth_min1 varchar(100)
	declare @depth_max1 varchar(100)
	declare @length_min1 varchar(100)
	declare @length_max1 varchar(100)
	declare @diameter_min1 varchar(100)
	declare @diameter_max1 varchar(100)
	declare @extra_field nvarchar(max)	
	declare @proximity_id1 varchar(100)
	/*M2-1521 Discover RFQs Supply Side - Need a search for Volume - Database*/
	declare @volume1 varchar(100)
	/**/

	/*  M2-2087 Clone up to 3 RFQ's for 3 regions - API */
	drop table if exists #rfqlocation
	/**/

	/*  M2-2087 Clone up to 3 RFQ's for 3 regions - API */
	create table #rfqlocation (rfq_location int)
	/**/


	SELECT @CompanyId = company_id FROM mp_contacts where contact_Id  = @contact_id;


	/*  M2-2087 Clone up to 3 RFQ's for 3 regions - API */
	if (select Manufacturing_location_id from mp_companies where company_id = @CompanyId) = 4 
		insert into #rfqlocation values (7), (4)

	if (select Manufacturing_location_id from mp_companies where company_id = @CompanyId) = 5
		insert into #rfqlocation values (7), (5)

	if (select Manufacturing_location_id from mp_companies where company_id = @CompanyId) not in (4,5)
			insert into #rfqlocation values ((select Manufacturing_location_id from mp_companies where company_id = @CompanyId))
	/**/
	
	declare @blacklisted_rfqs table (rfq_id int)

    insert into @blacklisted_rfqs (rfq_id)
    select distinct c.rfq_id from mp_book_details  a 
    join mp_books b on a.book_id = b.book_id 
    join mp_rfq c on b.contact_id = c.contact_id
    where bk_type= 5 and a.company_id = @CompanyId
	union  -- exclude rfq's for black listed buyer which are awarded & quoted 
	select distinct c.rfq_id  from mp_book_details  a 
    join mp_books b on a.book_id = b.book_id  and b.contact_id = @contact_id
	join mp_contacts d on a.company_id =  d.company_id
	join mp_rfq c on d.contact_id = c.contact_id
	left join mp_rfq_quote_supplierquote f on c.rfq_id = f.rfq_id and f.contact_id = @contact_id
	left join mp_rfq_quote_items e on f.rfq_quote_SupplierQuote_id= e.rfq_quote_SupplierQuote_id
    where bk_type= 5 and  ((f.is_quote_submitted = 0 or f.is_quote_submitted is null)and  isnull(e.is_awrded,0) = 0)
	

	if @save_search_id = 0
	begin
		 
		set	@part_category_id1 = case when @part_category_id = null then null else @part_category_id end
		set	@post_process_id1 = case when @post_process_id = null then null else @post_process_id end
		set	@material_id1 = case when @material_id = null then null else @material_id end 
		set	@buyer_territory_id1 = case when @buyer_location_id = null then null else @buyer_location_id end
		set	@rfq_country_id1 = case when @country_id = null then null else @country_id end
		set	@rfq_region_id1 = case when @region_id = null then null else @region_id end
		set	@unit_of_measure_id1 = case when @unit_of_measure_id =0 then 0 else @unit_of_measure_id end
		set	@tolerance_id1 = case when @tolerance_id = 0 then 0 else @tolerance_id end
		set @proximity_id1 = case when @proximity_id = null then null else @proximity_id end
		set @width_min1 =  case when @width_min = -1 then '' else convert(varchar(50),@width_min) end
		set @width_max1 =   case when @width_max = -1 then '' else convert(varchar(50),@width_max) end
		set @height_min1 =  case when @height_min = -1 then '' else convert(varchar(50),@height_min) end
		set @height_max1 =  case when @height_max = -1 then '' else convert(varchar(50),@height_max) end
		set @depth_min1 =  case when @depth_min = -1 then '' else convert(varchar(50),@depth_min) end
		set @depth_max1 =  case when @depth_min = -1 then '' else convert(varchar(50),@depth_max) end
		set @length_min1 =  case when @length_min = -1 then '' else convert(varchar(50),@length_min) end
		set @length_max1 =  case when @length_max = -1 then '' else convert(varchar(50),@length_max) end
		set @diameter_min1 =  case when @diameter_min = -1 then '' else convert(varchar(50),@diameter_min) end
		set @diameter_max1 =  case when @diameter_max = -1 then '' else convert(varchar(50),@diameter_max) end
		/*M2-1521 Discover RFQs Supply Side - Need a search for Volume - Database*/
		set @volume1 = case when @volume = null or @volume = '' then '' else convert(varchar(100),@volume) end
		/**/
		
	end
	else
	begin

		select 
			@part_category_id1 = isnull(part_category_id ,'')
			, @post_process_id1 =  isnull(post_process_id,'')
			, @material_id1 =  isnull(material_id ,'')
			, @buyer_territory_id1 =  isnull(buyer_location_id,'')
			, @rfq_country_id1 =  isnull(country_id,'')
			, @rfq_region_id1 =  isnull(region_id,'')
			, @unit_of_measure_id1 =  isnull(unit_of_measure_id,'')
			, @proximity_id1 =   isnull(proximity_id,'') 
			, @tolerance_id1 =  isnull(tolerance_id,'')
			, @width_min1 =  case when convert(varchar(50),width_min) = '-1' then '' else convert(varchar(50),width_min) end
			, @width_max1 =   case when convert(varchar(50),width_min) = '-1' then '' else convert(varchar(50),width_max) end
			, @height_min1 =  case when convert(varchar(50),height_min) = '-1' then '' else convert(varchar(50),height_min) end
			, @height_max1 =  case when convert(varchar(50),height_max) = '-1' then '' else convert(varchar(50),height_max) end
			, @depth_min1 =  case when convert(varchar(50),depth_min) = '-1' then '' else convert(varchar(50),depth_min) end
			, @depth_max1 =  case when convert(varchar(50),depth_min) = '-1' then '' else convert(varchar(50),depth_max) end
			, @length_min1 =  case when convert(varchar(50),length_min) = '-1'  or convert(varchar(50),length_min) = '0'then '' else convert(varchar(50),length_min) end
			, @length_max1 =  case when convert(varchar(50),length_max) = '-1' or convert(varchar(50),length_max) = '0' then '' else convert(varchar(50),length_max) end
			, @diameter_min1 =  case when convert(varchar(50),diameter_min) = '-1' or convert(varchar(50),diameter_min) = '0' then '' else convert(varchar(50),diameter_min) end
			, @diameter_max1 =  case when convert(varchar(50),diameter_max) = '-1' or convert(varchar(50),diameter_max) = '0' then '' else convert(varchar(50),diameter_max) end
			/*M2-1521 Discover RFQs Supply Side - Need a search for Volume - Database*/
			, @volume1 = case when volume is null or volume = '' then '' else convert(varchar(100),volume) end
			/**/
		from mp_saved_search (nolock) where contact_id = @contact_id and saved_search_id = @save_search_id
	end
			
	if @width_min1 = '' and @width_max1 = '' and @height_min1 = ''and @height_min1 = '' and @height_max1 = ''and @depth_min1 = ''and @depth_max1 = ''and @length_min1 = ''and @length_max1 = '' and @diameter_min1 = '' and @diameter_max1 = ''
	begin
		set @unit_of_measure_id1  = null
	end
	  

	set @where_query =  
		--case when @part_category_id1 = '' or  @part_category_id1 is null then '' else ' convert(nvarchar(max),a.part_category_id) in  (' +@part_category_id1+ ') ' end 
		--+ 
		case when @post_process_id1 = '' or  @post_process_id1 is null then '' else ' and convert(nvarchar(max),a.post_production_process_id) in  (' +@post_process_id1+ ') ' end 
		+ case when @material_id1 = '' or  @material_id1 is null then '' else ' and convert(nvarchar(max),a.material_id) in  (' +@material_id1+ ') ' end 
		+ case when @buyer_territory_id1 = ''or  @buyer_territory_id1 is null  then '' else ' and convert(nvarchar(max),a.buyer_territory_id) in  (' +@buyer_territory_id1+ ') ' end 
		+ case when @rfq_country_id1 = '' or  @rfq_country_id1 is null then '' else ' and convert(nvarchar(max),a.rfq_country_id) in  (' +@rfq_country_id1+ ') ' end 
		+ case when @rfq_region_id1 = '' or  @rfq_region_id1 is null then '' else ' and convert(nvarchar(max),a.rfq_region_id) in  (' +@rfq_region_id1+ ') ' end 
		+ case when @unit_of_measure_id1 = 0 or  @unit_of_measure_id1 is null  then '' else ' and convert(nvarchar(max),a.quantity_unit_id) in  (' +@unit_of_measure_id1+ ') ' end 
		--+ case when @tolerance_id1 = '0' or @tolerance_id1 = '' or  @tolerance_id1 is null then '' else ' and convert(nvarchar(max),a.part_tolerance_id) in  (' +@tolerance_id1+ ')' end 
		+ case when @proximity_id1 = '' or  @proximity_id1 is null then '' else '' end
		+ case when @proximity_id1 = '54' AND  (@latitude IS NOT NULL  AND @latitude != 0 AND @longitude IS NOT NULL AND @longitude != 0   )   then 
		' and ship_to IN (SELECT site_id FROM  mp_company_shipping_site
		  join mp_addresses on  mp_company_shipping_site.address_id = mp_addresses.address_Id 
		  join #geocode_tmp_table AS   geocodetmpTable ON mp_addresses.address3 = geocodetmpTable.zipcode
		  AND  geocodetmpTable.distance  <= 50)' else '' end		 
		+ case when @proximity_id1 = '55' AND  (@latitude IS NOT NULL  AND @latitude != 0 AND @longitude IS NOT NULL AND @longitude != 0   )   then 
		' and ship_to IN (SELECT site_id FROM  mp_company_shipping_site
		  join mp_addresses on  mp_company_shipping_site.address_id = mp_addresses.address_Id 
		  join #geocode_tmp_table AS   geocodetmpTable ON mp_addresses.address3 = geocodetmpTable.zipcode
		  AND  geocodetmpTable.distance <= 100)' else '' end	
		+ case when @proximity_id1 = '56' AND  (@latitude IS NOT NULL  AND @latitude != 0 AND @longitude IS NOT NULL AND @longitude != 0   )   then 
		' and ship_to IN (SELECT site_id FROM  mp_company_shipping_site
		  join mp_addresses on  mp_company_shipping_site.address_id = mp_addresses.address_Id 
		  join #geocode_tmp_table AS   geocodetmpTable ON mp_addresses.address3 = geocodetmpTable.zipcode
		  AND  geocodetmpTable.distance  <= 250)' else '' end
		+ case when @proximity_id1 = '57' AND  (@latitude IS NOT NULL  AND @latitude != 0 AND @longitude IS NOT NULL AND @longitude != 0   )   then 
		' and ship_to IN (SELECT site_id FROM  mp_company_shipping_site
		  join mp_addresses on  mp_company_shipping_site.address_id = mp_addresses.address_Id 
		  join #geocode_tmp_table AS   geocodetmpTable ON mp_addresses.address3 = geocodetmpTable.zipcode
		  AND  geocodetmpTable.distance  <= 500)' else '' end			
		/*M2-1521 Discover RFQs Supply Side - Need a search for Volume - Database*/
		+ case when @volume1 = '' or  @volume1 is null then '' else ' and convert(varchar(100),a.volume) in  (' +@volume1+ ') ' end
		/**/ 
 

	set @join_query = case when @tolerance_id1 = '0' or @tolerance_id1 = '' or  @tolerance_id1 is null then '' else ' join (select distinct rfq_id from mp_rfq_parts a join mp_parts b  on a.part_id = b.part_id where b.tolerance_id in (' +@tolerance_id1+ ')  )  b on a.rfq_id = b.rfq_id ' end
	
	
	set @extra_field =  
		case 
			when @width_min1 = '' and @width_max1 = ''  then '' 
			when @width_min1 != '' and @width_max1 = ''  then ' b.width in  (' +@width_min1+ ')'
			when @width_min1 != '' and @width_max1 != ''  then ' b.width in  (' +@width_min1+ ' , ' ++@width_max1++ ' )'
			when @width_min1 = '' and @width_max1 != ''  then ' b.width in  (' +@width_max1+ ')'
		end 
		+ case 
			when @height_min1 = '' and @height_max1 = ''  then '' 
			when @height_min1 != '' and @height_max1 = ''  then ' and b.height in  (' +@height_min1+ ')'
			when @height_min1 != '' and @height_max1 != ''  then ' and b.height in  (' +@height_min1+ ' , ' ++@height_max1++ ' )'
			when @height_min1 = '' and @height_max1 != ''  then ' and b.height in  (' +@height_max1+ ')'
		end 
		+ case 
			when @depth_min1 = '' and @depth_max1 = ''  then '' 
			when @depth_min1 != '' and @depth_max1 = ''  then ' and b.depth in  (' +@depth_min1+ ')'
			when @depth_min1 != '' and @depth_max1 != ''  then ' and b.depth in  (' +@depth_min1+ ' , ' ++@depth_max1++ ' )'
			when @depth_min1 = '' and @depth_max1 != ''  then ' and b.depth in  (' +@depth_max1+ ')'
		end 
		+ case 
			when @length_min1 = '' and @length_max1 = ''  then '' 
			when @length_min1 != '' and @length_max1 = ''  then ' and b.length in  (' +@length_min1+ ')'
			when @length_min1 != '' and @length_max1 != ''  then ' and b.length in  (' +@length_min1+ ' , ' ++@length_max1++ ' )'
			when @length_min1 = '' and @length_max1 != ''  then ' and b.length in  (' +@length_max1+ ')'
		end 
		+ case 
			when @diameter_min1 = '' and @diameter_max1 = ''  then '' 
			when @diameter_min1 != '' and @diameter_max1 = ''  then ' and b.diameter in  (' +@diameter_min1+ ')'
			when @diameter_min1 != '' and @diameter_max1 != ''  then ' and b.diameter in  (' +@diameter_min1+ ' , ' ++@diameter_max1++ ' )'
			when @diameter_min1 = '' and @diameter_max1 != ''  then ' and b.diameter in  (' +@diameter_max1+ ')'
		end 


	if left(@extra_field,4)= ' and'
	begin
		set @extra_field =  substring(@extra_field,5,len(@extra_field))		
	end


	set @join_query = @join_query +  case when len(@extra_field)> 0 then ' join (select distinct rfq_id from mp_rfq_parts a join mp_parts b  on a.part_id = b.part_id where '+@extra_field+' )  c on a.rfq_id = c.rfq_id ' else '' end
						 
	--select @where_query
   if len(@where_query) > 0 and left(@where_query,4) = ' and'
		set @where_query = ' where  Quotes_needed_by is not null  and ' + substring(@where_query , 5 ,  len(@where_query)) 
   else if len(@where_query) > 0 
		set @where_query = ' where   Quotes_needed_by is not null and ' + @where_query
   else if len(@where_query) =  0
		set @where_query = ' where  Quotes_needed_by is not null '


   set @where_query = @where_query + case when @geometry_id > 0 and @extra_field = '' then ' and  convert(nvarchar(max),a.part_category_id) in  (0)' else '' end

   set @search_query =  
		  case when @SearchText Is NOT Null then 'AND ((a.rfq_name Like ''%'+@SearchText+'%'')	OR (a.rfq_id Like ''%'+@SearchText+'%''))' else '' end 

	drop table if exists #tmp_company_process
	drop table if exists #all_valid_rfqs	

	create table #tmp_company_process
	(
		part_category_id int
	)

		insert   into #tmp_company_process
		(part_category_id)
		select value from string_split(@part_category_id1,',')

   	select 
	distinct 
				  a.rfq_id  
				, a.rfq_name  
				, a.Quotes_needed_by 
				, a.ship_to 
				, d.part_id
				, d.rfq_part_id
				, f.part_category_id
				, e.rfq_part_quantity_id
				, e.part_qty  
				, unit.id as quantity_unit_id
				, unit.value AS quantity_unit_value
				, j.company_id as buyer_company_id
				, f.tolerance_id as part_tolerance_id
				, tolerance.value tolerance
				, a.contact_id as buyer_contact_id
				, i.first_name + ' ' + i.last_name as buyer_contact_name 
				, a.rfq_status_id as buyer_status_id
				, k.[description] AS rfq_buyer_status			
				, h.material_id 
				, dbo.[fn_getTranslatedValue](h.material_name, 'EN') material_name 
				, g.part_category_id as process_id
				, case when category.discipline_name = g.discipline_name then g.discipline_name else category.discipline_name +' / '+ g.discipline_name end AS Process
				, Processes.id as post_production_process_id
				, Processes.value AS post_production_process_value 
				, mp_special_files.[FILE_ID] as part_file_id
				, mp_special_files.[file_name] as part_file_name
				, ThumbnailFile.FILE_ID  as rfq_thumbnailFile_id
				, COALESCE(ThumbnailFile.File_Name,'') AS rfq_thumbnail_name
				, vw_address.CountryId		AS rfq_country_id
				, vw_address.RegionId		AS rfq_region_id
				, mp_rfq_preferences.rfq_pref_manufacturing_location_id as buyer_territory_id
				,  likes.is_rfq_like AS is_rfq_like
				, rfq_release.release_date
				,a.payment_term_id AS payment_term_id
				, vw_address.City			AS City		 
				, vw_address.[State]		AS [State]				 
				, vw_address.country_name	AS Country		
				, msr.no_of_stars AS NoOfStars 
				, a.special_instruction_to_manufacturer as SpecialInstructions
				, f.volume
				, d.is_rfq_part_default
				, (select count(1) from mp_rfq_parts c11 (nolock) where a.rfq_id = c11.rfq_id )		 rfq_parts_count
				--, m.company_id
	into #all_valid_rfqs
	from mp_rfq a (nolock)	
	join mp_rfq_parts d (nolock)on a.rfq_id = d.rfq_id --and Is_Rfq_Part_Default = 1  
		and format(a.quotes_needed_by,'yyyyMMdd') >= format(getutcdate(),'yyyyMMdd') 
	join mp_rfq_part_quantity e (nolock)on d.rfq_part_id = e.rfq_part_id
	join mp_parts f (nolock) on d.part_id = f.part_id			
	join mp_mst_part_category g (nolock) on f.part_category_id = g.part_category_id
	/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
	left join mp_mst_part_category category (nolock) on g.parent_part_category_id=category.part_category_id
	/**/
	join mp_mst_materials h (nolock) on f.material_id = h.material_id 
	join mp_contacts i (nolock) on a.contact_id=i.contact_id
	join mp_companies j (nolock) on i.company_id=j.company_id
	--left join mp_addresses n (nolock) on i.address_id = n.address_id
	left join vw_address  (nolock) ON i.address_id = vw_address.address_Id
	left join mp_system_parameters tolerance (nolock) on tolerance.id = f.tolerance_id
	left join mp_mst_country o (nolock) on vw_address.CountryId = o.country_id
	LEFT JOIN mp_rfq_preferences on a.rfq_id = mp_rfq_preferences.rfq_id
	join mp_mst_rfq_buyerStatus k (nolock) on a.rfq_status_id=k.rfq_buyerstatus_id and a.rfq_status_id = 3
	join mp_system_parameters as unit (nolock) ON f.part_qty_unit_id = unit.id AND unit.sys_key = '@UNIT2_LIST' 
	left join 
	(
		mp_rfq_parts_file l
		join mp_special_files on l.[file_id] = mp_special_files.[file_id]
	)
	on  d.rfq_part_id = l.rfq_part_id AND l.is_primary_file = 1  
	left join mp_system_parameters as processes on d.Post_Production_Process_id = processes.id 
	and Processes.sys_key = '@PostProdProcesses' 
	left join mp_special_files as ThumbnailFile on ThumbnailFile.file_id = a.file_id
	left join mp_rfq_supplier_likes likes on   a.rfq_id = likes.rfq_id and likes.contact_id =  @contact_id and likes.is_rfq_like = 1
	left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history group by rfq_id ) rfq_release on a.rfq_id = rfq_release.rfq_id
	LEFT JOIN mp_star_rating msr on msr.company_id = j.company_id
	left join (select distinct rfq_id from mp_rfq_quote_SupplierQuote (nolock) where mp_rfq_quote_SupplierQuote.is_rfq_resubmitted = 0 and is_quote_submitted = 1 and mp_rfq_quote_SupplierQuote.contact_id =  @contact_id ) mrqsq on mrqsq.rfq_id = a.rfq_id
	/* M2-2060 let me choose"/special invite RFQ found in a different supplier's saved search */
	left join mp_rfq_supplier (nolock)  m on a.rfq_id = m.rfq_id
	/**/
	where 
	mrqsq.rfq_id  is null
	and  a.rfq_id  not in  (select distinct rfq_id from mp_rfq_supplier_likes where contact_id = @contact_id and is_rfq_like = 0 )
	and  a.rfq_id  not in  (select rfq_id from @blacklisted_rfqs)
	and mp_rfq_preferences.rfq_pref_manufacturing_location_id  in 
					/*  M2-2087 Clone up to 3 RFQ's for 3 regions - API */
					(select * from #rfqlocation)
					/**/
	/* M2-2060 let me choose"/special invite RFQ found in a different supplier's saved search */
	and (m.company_id = -1 or m.company_id = @CompanyId)
	/**/
   
   --select * from #tmp_company_process
   --select * from #all_valid_rfqs where rfq_id =  1169290

   set @sql_query = 
	'
	select 
		rfq_id	,rfq_name	,part_qty	,quantity_unit_value	,material_name	,process	,post_process	,closes	,rfq_status	
		,rfq_thumbnail_name	,is_rfq_like, count(rfq_id) over(partition by ss) AS total_count  , buyer_contact_name,buyer_company_id,buyer_contact_id ,release_date,payment_term_id,City,State,Country,NoOfStars,SpecialInstructions,ship_to,rfq_part_id,rfq_parts_count
	from 
	(	select  	''savedsearch'' as ss , 	
			a.rfq_id,		rfq_name , buyer_contact_name ,buyer_company_id,buyer_contact_id,		FLOOR(min(part_qty )) part_qty,		quantity_unit_value,		material_name,		process,
			post_production_process_value as post_process 		,Quotes_needed_by as closes		,rfq_buyer_status as rfq_status		,rfq_thumbnail_name		,is_rfq_like , release_date,payment_term_id,City,State,Country,NoOfStars,SpecialInstructions,ship_to,buyer_territory_id,rfq_part_id,rfq_parts_count
		from #all_valid_rfqs a '+@join_query + ' 
		/* M2-1666 Supplier - Process filters need to search through all the RFQ Parts processes */	
		left join 
		(
					select distinct a.rfq_id 
					from mp_rfq a 
					join mp_rfq_parts b (nolock)   on a.rfq_id = b.rfq_id 
						and a.rfq_status_id = 3
						and format(a.quotes_needed_by,''yyyyMMdd'') >= format(getutcdate(),''yyyyMMdd'') 
					join mp_parts c (nolock) on b.part_id  = c.part_id and c.part_category_id in (select * from #tmp_company_process)
					--join
					--(
					--	select distinct c.part_category_id 
					--	from mp_company_processes a	 (nolock)
					--	join mp_mst_part_category b  (nolock) on a.part_category_id = b.part_category_id
					--	join mp_mst_part_category c  (nolock) on b.parent_part_category_id = c.parent_part_category_id 
					--	where c.status_id = 2
					--	and b.part_category_id in (select * from #tmp_company_process)
				
					--) d on c.part_category_id = d.part_category_id
		) q on a.rfq_id =  q.rfq_id
		/**/
		' + @where_query + '  '+@search_query+ ' '+ case when @par_per_page_records = 3 then ' and convert(varchar,release_date, 120) > '''+ convert(varchar,getutcdate() -1 , 120)+''' ' else '' end +' 
		/* M2-1666 Supplier - Process filters need to search through all the RFQ Parts processes */
		and a.is_rfq_part_default = 1 
		and a.rfq_id = case when (select count(1) from #tmp_company_process where part_category_id <> 0) > 0 then  q.rfq_id  else a.rfq_id end      
		/**/
		group by a.rfq_id	,rfq_name , buyer_contact_name 	,material_name	,process	,post_production_process_value 	,Quotes_needed_by,rfq_buyer_status ,quantity_unit_value,rfq_thumbnail_name,is_rfq_like ,buyer_company_id,buyer_contact_id ,release_date,payment_term_id,City,State,Country,NoOfStars,SpecialInstructions,ship_to,buyer_territory_id,rfq_part_id,rfq_parts_count
	) a

	order by 
			case  when @IsOrderByDesc1 =  1 and @OrderBy1 = ''quantity'' then   part_qty end desc   
			,case  when @IsOrderByDesc1 =  1 and @OrderBy1 = ''material'' then   material_name end desc   
			,case  when @IsOrderByDesc1 =  1 and @OrderBy1 = ''process'' then   process end desc   
			,case  when @IsOrderByDesc1 =  1 and @OrderBy1 = ''postprocess'' then   post_process end desc   
			,case  when @IsOrderByDesc1 =  1 and @OrderBy1 = ''quoteby'' then   closes end desc   
			,case  when @IsOrderByDesc1 =  1 and @OrderBy1 = ''release_date'' then   release_date end desc   
			,case  when @IsOrderByDesc1 =  0 and @OrderBy1 = ''quantity'' then   part_qty end asc   
			,case  when @IsOrderByDesc1 =  0 and @OrderBy1 = ''material'' then   material_name end asc   
			,case  when @IsOrderByDesc1 =  0 and @OrderBy1 = ''process'' then   process end asc   
			,case  when @IsOrderByDesc1 =  0 and @OrderBy1 = ''postprocess'' then   post_process end asc   
			,case  when @IsOrderByDesc1 =  0 and @OrderBy1 = ''quoteby'' then   closes end asc   
			,case  when @IsOrderByDesc1 =  0 and @OrderBy1 = ''release_date'' then   release_date end asc

	offset ' + convert(varchar(50),@par_per_page_records) + '  * (  ' + convert(varchar(50),@par_pagination) + '  - 1) rows
	fetch next ' + convert(varchar(50),@par_per_page_records) + ' rows only;
	' 

	
	--select @sql_query
	EXECUTE sp_executesql @sql_query, N'@IsOrderByDesc1  BIT,@OrderBy1 varchar(100)', @IsOrderByDesc1  = @IsOrderByDesc ,@OrderBy1 = @OrderBy
	drop table if exists #geocode_tmp_table	 



end
