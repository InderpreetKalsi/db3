
/*

declare @p22 dbo.tbltype_ListOfProcesses
--insert into @p22 values(2)


exec [proc_get_supplier_mycompanyrfqs_list] 
@RfqType=1
,@SupplierID=1337848
,@SupplierCompID=1768018
,@PageNumber=1
,@PageSize=300
,@SearchText=N''
,@orderby=N''
,@IsOrderByDesc=1
,@ProcessIDs=@p22
,@SelectedSupplierId = null

*/
Create procedure [dbo].[proc_get_supplier_mycompanyrfqs_list_bk_hotfix]
(
	@RfqType			int,	 
	@SupplierID			int,
	@SupplierCompID		int,
	@SearchText			varchar(150)	= null,	
	@ProcessIDs			as tbltype_ListOfProcesses			readonly,
	@PageNumber			int		= 1,
	@PageSize			int		= 24,
	@IsOrderByDesc		bit		='true',
	@OrderBy			varchar(100)	= null,
	@CurrentDate		datetime		= null ,
	@SelectedSupplierId   INT = NULL
)
as
begin

	set nocount on
	/*
		 =============================================
		 Create date:  Oct 14,2019
		 Description:  List of RFQ based on supplier location and capabilities
		 Modification:
		 Oct 14,2019 - M2-2196 M - My RFQ's page - Saved Search module - Initial State : DB
		 Apr 06,2020 - M2-2739 Stripe - Capabilities selection for gold & platinum subscription - DB
		 =================================================================
	
		/1	=> MyRFQ's => All Tab => AllRFQ's
		/4	=> MyRFQ's => All Tab => Quoted RFQ's
		/5	=> MyRFQ's => All Tab => Decline Quote's
		/6	=> MyRFQ's => All Tab => Awarded Quote's
		/7	=> MyRFQ's => All Tab => Mark for Quoting
		
		
		/51	=> MyRFQ's => Liked Tab => AllRFQ's
		/54	=> MyRFQ's => Liked Tab => Quoted RFQ's
		/55	=> MyRFQ's => Liked Tab => Decline Quote's
		/56	=> MyRFQ's => Liked Tab => Awarded Quote's
		/57	=> MyRFQ's => Liked Tab => Mark for Quoting 

		/101	=> MyRFQ's => DisLiked Tab => AllRFQ's
		/104	=> MyRFQ's => DisLiked Tab => Quoted RFQ's
		/105	=> MyRFQ's => DisLiked Tab => Decline Quote's
		/106	=> MyRFQ's => DisLiked Tab => Awarded Quote's
		/107	=> MyRFQ's => DisLiked Tab => Mark for Quoting
	
	
	*/
	
	declare @is_registered_supplier		bit = 0 
	declare @is_stripe_supplier			bit = 0 
	declare @manufacturing_location_id	smallint  
	declare @company_capabilities		int  = 0
	declare @sortorder					varchar(10) 
	declare @inputdate					varchar(8) 
	declare @rfqlocation				int
	declare @is_premium_supplier		int
	declare @where_query				nvarchar(max)
	declare @extra_field				nvarchar(max)
	declare @latitude					float=null
	declare @longitude					float=null
	declare @proximities_value			varchar(50)
	declare @processids1				as tbltype_ListOfProcesses 
		
	declare @blacklisted_rfqs table (rfq_id int)
	declare @sql_query_rfq_list_based_on_processes nvarchar(max)
	/* May 4, 2020 As discussed with Eddie & Beau Martin , For supplier after taking RFQ capabilities, we need to hide buyer info & restrict supplier to download part files for profile capabilities RFQ’s as we do for basic supplier.*/
	declare @IsSubscriptionSupplier		bit = 0
	/**/


	drop table if exists #rfq_list
	drop table if exists #rfq_list_for_parts_search
	drop table if exists #rfqlocation  -- /*  M2-2087 Clone up to 3 RFQ's for 3 regions - API */
	drop table if exists #rfq_likes
	drop table if exists #filtered_rfq_list
	drop table if exists #geocode

	create table #rfq_list (rfq_id int)
	create table #rfq_list_for_parts_search (rfq_id int)
	create table #rfqlocation (rfq_location int) -- /*  M2-2087 Clone up to 3 RFQ's for 3 regions - API */
	create table #filtered_rfq_list (rfq_id int) -- /*  Oct 14,2019 - M2-2196 M - My RFQ's page - Saved Search module - Initial State : DB */

	/* M2-2852 M - Add My Company RFQs to the left menu and new page - DB */
	CREATE TABLE #tmp_mycompany_suppliers (SupplierId INT)
	/**/

	/* M2-2852 M - Add My Company RFQs to the left menu and new page - DB */
	IF @SelectedSupplierId IS NULL
	BEGIN
		INSERT INTO #tmp_mycompany_suppliers (SupplierId)
		SELECT contact_id from mp_contacts where company_id = @SupplierCompID
	END
	ELSE
	BEGIN
		INSERT INTO #tmp_mycompany_suppliers (SupplierId) SELECT @SelectedSupplierId
	END
	/**/

	if @currentdate is null
	begin
		set @inputdate = convert(varchar(8),format(getutcdate(),'yyyyMMdd'))
		set @currentdate = getutcdate()
	end
	else
	begin
		set @inputdate = convert(varchar(8),format(@currentdate,'yyyyMMdd'))
	end

	set @is_registered_supplier = (select is_registered from mp_registered_supplier (nolock)  where company_id = @SupplierCompID)
	set @is_premium_supplier = isnull((select account_type from mp_registered_supplier (nolock)  where company_id = @SupplierCompID),83)
	set @manufacturing_location_id  = (select manufacturing_location_id from mp_companies (nolock) where company_id = @SupplierCompID)
	set @company_capabilities = 
	(
		select count(1) from
		(
			select part_category_id from mp_company_processes  (nolock) where  company_id = @SupplierCompID
			/* M2-2739 */
			union
			select part_category_id from  mp_gateway_subscription_company_processes (nolock)  where  company_id = @SupplierCompID
			/**/
		) a
	)

	SET @IsSubscriptionSupplier =
		(
			CASE	
				WHEN (SELECT COUNT(1) FROM mp_gateway_subscription_company_processes (NOLOCK)  WHERE  company_id =  @SupplierCompID AND is_active = 1)> 0 THEN CAST('true' AS BIT) 
				ELSE CAST('false' AS BIT) 
			END 
		)

	set @is_stripe_supplier =
							(case	when (select count(1) from mp_gateway_subscription_company_processes (nolock)  where  company_id =  @SupplierCompID and is_active = 1)> 0 then cast('true' as bit) else cast('false' as bit) end )

	

	/*  M2-2087 Clone up to 3 RFQ's for 3 regions - API */
	if @manufacturing_location_id = 4 
		insert into #rfqlocation values (7), (4)

	if @manufacturing_location_id = 5
		insert into #rfqlocation values (7), (5)

	if @manufacturing_location_id not in (4,5)
		insert into #rfqlocation values (@manufacturing_location_id)
	/**/
	

    insert into @blacklisted_rfqs (rfq_id)
    select distinct c.rfq_id 
	from mp_book_details					a (nolock)
    join mp_books							b (nolock) on a.book_id = b.book_id 
    join mp_rfq								c (nolock) on b.contact_id = c.contact_id
	left join mp_rfq_quote_supplierquote	f (nolock) on c.rfq_id = f.rfq_id and f.contact_id   in
				/* M2-2852 M - Add My Company RFQs to the left menu and new page - DB */
				(
					select supplierid from #tmp_mycompany_suppliers
				)
				/**/
	left join mp_rfq_quote_items			e (nolock) on f.rfq_quote_SupplierQuote_id= e.rfq_quote_SupplierQuote_id
    where bk_type= 5 and a.company_id = @SupplierCompID and  ((f.is_quote_submitted = 0 or f.is_quote_submitted is null)and  isnull(e.is_awrded,0) = 0)
	union  -- exclude rfq's for black listed buyer which are awarded & quoted 
	select distinct c.rfq_id  
	from mp_book_details					a (nolock) 
    join mp_books							b (nolock) on a.book_id = b.book_id  and b.contact_id   in
				/* M2-2852 M - Add My Company RFQs to the left menu and new page - DB */
				(
					select supplierid from #tmp_mycompany_suppliers
				)
				/**/
	join mp_contacts						d (nolock) on a.company_id =  d.company_id
	join mp_rfq								c (nolock) on d.contact_id = c.contact_id
	left join mp_rfq_quote_supplierquote	f (nolock) on c.rfq_id = f.rfq_id and f.contact_id   in
				/* M2-2852 M - Add My Company RFQs to the left menu and new page - DB */
				(
					select supplierid from #tmp_mycompany_suppliers
				)
				/**/
	left join mp_rfq_quote_items			e (nolock) on f.rfq_quote_SupplierQuote_id= e.rfq_quote_SupplierQuote_id
    where bk_type= 5 and  ((f.is_quote_submitted = 0 or f.is_quote_submitted is null)and  isnull(e.is_awrded,0) = 0)

	if (@RfqType in (1,14,18)) and (@OrderBy is null or @OrderBy = '' )
		set @OrderBy  = 'release_date'
	else if (@RfqType in (3)) and (@OrderBy is null or @OrderBy = '' )
		set @OrderBy  = ''
	else if (@OrderBy is null or @OrderBy = '' )
		set @OrderBy  = 'quoteby'

	select rfq_id ,is_rfq_like into #rfq_likes from  mp_rfq_supplier_likes a	(nolock) where contact_id  in
	/* M2-2852 M - Add My Company RFQs to the left menu and new page - DB */
	(
		select supplierid from #tmp_mycompany_suppliers
	)
	/**/

	/*  Oct 14,2019 - M2-2196 M - My RFQ's page - Saved Search module - Initial State : DB */
	set @sql_query_rfq_list_based_on_processes=			
	'
	insert into #rfq_list (rfq_id)
	select distinct a.rfq_id 
	from mp_rfq			a (nolock) 
	join mp_rfq_parts	b (nolock) on a.rfq_id = b.rfq_id 
	join mp_parts		c (nolock) on b.part_id  = c.part_id '
	+
	case 
		when @RfqType in (1,51,101) then
			' and a.rfq_status_id = 3
			and format(a.quotes_needed_by,''yyyyMMdd'') >= '''+@inputdate+''' 
			join mp_rfq_preferences		mrp (nolock) on a.rfq_id = mrp.rfq_id and mrp.rfq_pref_manufacturing_location_id in (select * from #rfqlocation)  
			'	
		when @RfqType in (4,54,104) then
			' and a.rfq_status_id in  (3 , 5, 6 ) 
			join mp_rfq_quote_SupplierQuote	mrqsq	(nolock) on mrqsq.rfq_id = a.rfq_id and mrqsq.contact_id   in
				/* M2-2852 M - Add My Company RFQs to the left menu and new page - DB */
				(
					select supplierid from #tmp_mycompany_suppliers
				)
				/**/  '
		when @RfqType in (5,55,105) then
			' and a.rfq_status_id in  (3 , 5, 6 ) 
			  join mp_rfq_quote_SupplierQuote	mrqsq	(nolock) on mrqsq.rfq_id = a.rfq_id and mrqsq.contact_id   in
				/* M2-2852 M - Add My Company RFQs to the left menu and new page - DB */
				(
					select supplierid from #tmp_mycompany_suppliers
				)
				/**/  '
		when @RfqType in (6,56,106) then
			'  
			  join mp_rfq_quote_SupplierQuote	mrqsq	(nolock) on mrqsq.rfq_id = a.rfq_id and mrqsq.contact_id   in
				/* M2-2852 M - Add My Company RFQs to the left menu and new page - DB */
				(
					select supplierid from #tmp_mycompany_suppliers
				)
				/**/  '
		when @RfqType in (7,57,107) then
			'  
			  join mp_rfq_quote_suplierstatuses	mrqss	(nolock) on a.rfq_id = mrqss.rfq_id and mrqss.contact_id  in
				/* M2-2852 M - Add My Company RFQs to the left menu and new page - DB */
				(
					select supplierid from #tmp_mycompany_suppliers
				)
				/**/   and rfq_userStatus_id in (1, 2)
			  '
		else ' '
	end
	+
	'
	join
	(
		select distinct c.part_category_id 
		from 
		mp_mst_part_category b  (nolock)
		join mp_mst_part_category c  (nolock) on b.parent_part_category_id = c.parent_part_category_id 
		'
		+
		case 
			when @company_capabilities > 0  and  @RfqType in ( 1,6,7,51,101) then 
				' join 
				  (
						select company_id,part_category_id from  mp_company_processes a	(nolock)   where company_id = '+ convert(varchar(50),@SupplierCompID)+'
						/* M2-2739 */
						union
						select company_id,part_category_id from  mp_gateway_subscription_company_processes a (nolock)   where company_id = '+ convert(varchar(50),@SupplierCompID)+'
						/**/
				  ) a on a.part_category_id = b.part_category_id '
			else ' '
		end
		+
		'
		where  c.status_id = 2
		and 
		(
			(
				c.part_category_id in (select processId from @processids1)
			)
			OR 
			(
				(select count(processId) from  @processids1 ) = 0)
			)				
	) d on b.part_category_id = d.part_category_id
	'

	--select @sql_query_rfq_list_based_on_processes
	--select * from #rfq_list

	exec sp_executesql  @sql_query_rfq_list_based_on_processes 
	,N'@processids1  tbltype_ListOfProcesses readonly'
	,@processids1  = @Processids	
	


	/* Oct 14,2019 - M2-2196 M - My RFQ's page - Saved Search module - Initial State : DB */
	set @sql_query_rfq_list_based_on_processes=			
	'
	insert into #filtered_rfq_list (rfq_id)
	select distinct a.rfq_id 
	from mp_rfq			a	(nolock) 
	join mp_rfq_parts	b	(nolock) on a.rfq_id = b.rfq_id 
	join mp_parts		c	(nolock) on b.part_id  = c.part_id 
	join mp_contacts	mc	(nolock) on a.contact_id = mc.contact_id 
	join mp_companies	mcom	(nolock) on mc.company_id = mcom.company_id 
	'
	+
	case 
		when @RfqType in (1,51,101) then
			' and a.rfq_status_id = 3
			 and format(a.quotes_needed_by,''yyyyMMdd'') >= '''+@inputdate+''' 
			 join mp_rfq_preferences		mrp (nolock) on a.rfq_id = mrp.rfq_id and mrp.rfq_pref_manufacturing_location_id in (select * from #rfqlocation)  
			'	
		when @RfqType in (4,54,104) then
			' and a.rfq_status_id in  (3 , 5, 6 ) 
			join mp_rfq_quote_SupplierQuote	mrqsq	(nolock) on mrqsq.rfq_id = a.rfq_id and mrqsq.contact_id   in
				/* M2-2852 M - Add My Company RFQs to the left menu and new page - DB */
				(
					select supplierid from #tmp_mycompany_suppliers
				)
				/**/ '
		when @RfqType in (5,54,104) then
			' and a.rfq_status_id in  (3 , 5, 6 ) 
			join mp_rfq_quote_SupplierQuote	mrqsq	(nolock) on mrqsq.rfq_id = a.rfq_id and mrqsq.contact_id   in
				/* M2-2852 M - Add My Company RFQs to the left menu and new page - DB */
				(
					select supplierid from #tmp_mycompany_suppliers
				)
				/**/ '
		when @RfqType in (6,56,106) then
			' 
			  join mp_rfq_quote_SupplierQuote	mrqsq	(nolock) on mrqsq.rfq_id = a.rfq_id and mrqsq.contact_id   in
				/* M2-2852 M - Add My Company RFQs to the left menu and new page - DB */
				(
					select supplierid from #tmp_mycompany_suppliers
				)
				/**/  '
		when @RfqType in (7,57,107) then
			'  
			  join mp_rfq_quote_suplierstatuses	mrqss	(nolock) on a.rfq_id = mrqss.rfq_id and mrqss.contact_id  in
				/* M2-2852 M - Add My Company RFQs to the left menu and new page - DB */
				(
					select supplierid from #tmp_mycompany_suppliers
				)
				/**/   and rfq_userStatus_id in (1, 2)
			  '
		else ''
	end
	+
	'
	 left join vw_address		vwa (nolock) on mc.address_id = vwa.address_Id	
	'
	

	--select count(1) from @ProcessIDs
	
	set @where_query = 
	case when (select count(1) from @ProcessIDs) > 0 then ' a.rfq_id in (select * from  #rfq_list ) ' else '' end
	
	--select @where_query as where_query

	if left(@where_query,5) = ' and '
		set @where_query = substring(@where_query , 6, len(@where_query))
		
	set  @sql_query_rfq_list_based_on_processes = @sql_query_rfq_list_based_on_processes + case when len(@where_query) > 0 then ' where ' else '' end + @where_query 
	
	--select @sql_query_rfq_list_based_on_processes, @extra_field , @where_query

	exec sp_executesql  @sql_query_rfq_list_based_on_processes 

	
	--select @sql_query_rfq_list_based_on_processes
	--select * from #filtered_rfq_list order by rfq_id desc
	--select supplierid from #tmp_mycompany_suppliers



	/* M2-1924 M - In the application the search needs to be inclusive - DB */
	if len(@SearchText) > 0
	begin
		insert into #rfq_list_for_parts_search (rfq_id)
		select distinct a.rfq_id 
		from mp_rfq	(nolock) a 
		where 
			(a.rfq_name like '%'+@SearchText+'%')	
			OR	
			(a.rfq_id like '%'+@SearchText+'%')		
			OR
			(@SearchText is null)	
	end
	/**/	



	/* Start - Oct 14,2019 - M2-2196 M - My RFQ's page - Saved Search module - Initial State : DB */
	/* MyRFQ's => All Tab */
		--=> MyRFQ's => All Tab => AllRFQ's  (1)
		--=> MyRFQ's => Liked Tab => AllRFQ's  (51)
		--=> MyRFQ's => DisLiked Tab => AllRFQ's  (101) 
		if (@RfqType in (1,51,101) )	
		begin


			select myrfqs.*  , rfq_release.release_date as ReleaseDate , 	count(1) over () RfqCount    from 
			 (
				select 
					distinct 
					b.rfq_id as RfqId  
					, b.rfq_name as RfqName 
					, convert(varchar(100),floor(c.min_part_quantity)) as PartQty 
					, c.min_part_quantity_unit as PartQtyUnit  
					, j.value as PostProductionProcessName 
					, k.material_name_en  as PartsMaterialName  
					, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as PartCategoryName
					, b.contact_id as BuyerContactId  
					, b.quotes_needed_by as QuotesNeededBy
					, a.is_rfq_like IsRfqLike  
					, o.no_of_stars AS NoOfStars 
					, coalesce(p.file_name,'') as RfqThumbnail 	 
					, b.special_instruction_to_manufacturer as SpecialInstructions 
					, m.company_id AS BuyerCompanyId	
					, vw_address.state			as State 
					, vw_address.country_name	as Country 	
					, mcom.name as CompanyName 
					, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS CompanyLogoPath 
					, c.rfq_part_id as RfqPartId 
					, c.is_rfq_part_default
					, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )	as	 RfqPartCount 
					/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
					, 
					  case 
						 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
							/* Eddie requested (Jan 21,2020), to remove territory condition and show no of quotes for all platinum users */
						--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
							/**/
						/**/
						/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
						when @is_premium_supplier in (83,84,85) then 0
						/**/
						else
							(
								select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
							)
					  end as NoOfQuotes 
					/**/
					,floor(c.min_part_quantity) as PartQty1
					/* May 4, 2020 As discussed with Eddie & Beau Martin , For supplier after taking RFQ capabilities, we need to hide buyer info & restrict supplier to download part files for profile capabilities RFQ’s as we do for basic supplier. */
					,@IsSubscriptionSupplier AS IsSubscriptionSupplier
					,(CASE WHEN s.MatchedPartCount > 0 THEN CAST('true' AS BIT)	ELSE CAST('false' AS BIT) END ) As IsAllowQuoting
					/**/

				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/				from
				mp_rfq_supplier		mrs				(nolock) 
				join mp_rfq b						(nolock) on mrs.rfq_id = b.rfq_id 
					and rfq_status_id = 3 
					and format(b.quotes_needed_by,'yyyyMMdd') >= format(@currentdate,'yyyyMMdd') 
				join mp_rfq_preferences  mrp		(nolock) on b.rfq_id = mrp.rfq_id 
				join mp_rfq_parts c					(nolock) on b.rfq_id = c.rfq_id -- and c.is_rfq_part_default =  1
				join mp_parts d						(nolock) on c.part_id = d.part_id
				left join mp_system_parameters j	(nolock) on c.post_production_process_id = j.id and j.sys_key = '@PostProdProcesses' 
				left join mp_mst_materials	k		(nolock) on c.material_id = k.material_id 
				left join mp_mst_part_category l	(nolock) on c.part_category_id = l.part_category_id
				/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
				left join mp_mst_part_category category (nolock) on l.parent_part_category_id=category.part_category_id
				/**/
				join mp_contacts m					(nolock) on b.contact_id = m.contact_id
				join mp_companies mcom				(nolock) on m.company_id = mcom.company_id
				left join 
				(
					select distinct m1.company_id, o1.no_of_stars 
					from
					mp_rfq b1 (nolock)
					join mp_contacts m1  (nolock) on b1.contact_id = m1.contact_id  
					join mp_star_rating o1  (nolock) on o1.company_id = m1.company_id
				) o	on o.company_id = m.company_id
				left join mp_special_files p		(nolock) on p.file_id = b.file_id
				left join vw_address				(nolock) on m.address_id = vw_address.address_id
				left join #rfq_likes			a	(nolock) on a.rfq_id = b.rfq_id  
				/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
				left join #rfq_list q on b.rfq_id =  q.rfq_id
				/**/
				/* M2-1924 M - In the application the search needs to be inclusive - DB */
				left join #rfq_list_for_parts_search r on  b.rfq_id =  r.rfq_id
				/**/
				left join 
				(
					SELECT 
						a.rfq_id,
						COUNT(c.part_category_id) MatchedPartCount
					FROM mp_rfq					(NOLOCK) a
					LEFT JOIN mp_rfq_parts		(NOLOCK) b ON a.rfq_id = b.rfq_id AND b.status_id  = 2
					LEFT JOIN mp_gateway_subscription_company_processes  (NOLOCK) c ON b.part_category_id = c.part_category_id AND c.company_id = @SupplierCompID  AND c.is_active = 1
 					WHERE  
						a.rfq_id IN (select * from #filtered_rfq_list)
					GROUP BY a.rfq_id
				) s on b.rfq_id = s.rfq_id
				where 
				( 
					 (
						mrs.company_id = -1 
						and mrp.rfq_pref_manufacturing_location_id in 
						/*  M2-2087 Clone up to 3 RFQ's for 3 regions - API */
						(select * from #rfqlocation)
						/**/
						and rfq_status_id = 3  
						/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
						and b.rfq_id = case when (select count(1) from #rfq_list)  > 0 then  q.rfq_id  else b.rfq_id end
						/**/
						/* M2-1924 M - In the application the search needs to be inclusive - DB */
						and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
						/**/
					 )
			 
				)
				and b.rfq_id not in  (select distinct rfq_id from mp_rfq_quote_SupplierQuote (nolock) where contact_id   in
				/* M2-2852 M - Add My Company RFQs to the left menu and new page - DB */
				(
					select supplierid from #tmp_mycompany_suppliers
				)
				/**/  )
				and b.rfq_id not in  (select rfq_id from @blacklisted_rfqs) 
				--and (a.is_rfq_like != 0 or a.is_rfq_like is null)
				and c.is_rfq_part_default =  1 -- M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes
				and b.rfq_id in (select * from #filtered_rfq_list) -- Oct 14,2019 - M2-2196 M - My RFQ's page - Saved Search module - Initial State : DB
				and b.rfq_id = case when @RfqType in (51,101) then a.rfq_id else  b.rfq_id end 
				and 
				(
					a.is_rfq_like = case when @RfqType in (1,51) then 1 when @RfqType = 101 then 0  end 
					or
					isnull(a.is_rfq_like,1) = (case when @RfqType = 1 then 1 end)
				)
			) myrfqs
			 left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on myrfqs.RFQId = rfq_release.rfq_id
			order by 
				case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   PartQty1 end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   partsMaterialName end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   partCategoryName end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   postProductionProcessName end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'release_date' then   release_date end desc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   PartQty1 end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   partsMaterialName end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   partCategoryName end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   postProductionProcessName end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'release_date' then   release_date end asc   
			
			offset @pagesize * (@pagenumber - 1) rows
			fetch next @pagesize rows only
		
		end	
		--=> MyRFQ's => All Tab => Quoted RFQ's (4)
		--=> MyRFQ's => Liked Tab => Quoted RFQ's  (54)
		--=> MyRFQ's => DisLiked Tab => Quoted RFQ's  (104) 
		else if (@RfqType  in (4,54,104))		 
		begin	
	
			SELECT QuotedRFQ.* , rfq_release.release_date as ReleaseDate, 	count(1) over () RfqCount  FROM 
			(		 
			SELECT
				distinct 
					b.rfq_id as RfqId  
					, b.rfq_name as RfqName 
					, convert(varchar(100),floor(c.min_part_quantity)) as PartQty 
					, c.min_part_quantity_unit as PartQtyUnit  
					, j.value as PostProductionProcessName 
					, k.material_name_en  as PartsMaterialName  
					, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as PartCategoryName
					, b.contact_id as BuyerContactId  
					, b.quotes_needed_by as QuotesNeededBy
					, a.is_rfq_like IsRfqLike  
					, o.no_of_stars AS NoOfStars 
					, coalesce(p.file_name,'') as RfqThumbnail 	 
					, b.special_instruction_to_manufacturer as SpecialInstructions 
					, m.company_id AS BuyerCompanyId	
					, vw_address.state			as State 
					, vw_address.country_name	as Country 	
					, mcom.name as CompanyName 
					, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS CompanyLogoPath 
					, c.rfq_part_id as RfqPartId 
					, c.is_rfq_part_default
					, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )	as	 RfqPartCount 
					/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
					, 
					  case 
						 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
							/* Eddie requested (Jan 21,2020), to remove territory condition and show no of quotes for all platinum users */
						--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
							/**/
						/**/
						/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
						when @is_premium_supplier in (83,84,85) then 0
						/**/
						else
							(
								select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
							)
					  end as NoOfQuotes 
					/**/
					/* May 4, 2020 As discussed with Eddie & Beau Martin , For supplier after taking RFQ capabilities, we need to hide buyer info & restrict supplier to download part files for profile capabilities RFQ’s as we do for basic supplier. */
					,@IsSubscriptionSupplier AS IsSubscriptionSupplier
					,(CASE WHEN s.MatchedPartCount > 0 THEN CAST('true' AS BIT)	ELSE CAST('false' AS BIT) END ) As IsAllowQuoting
					/**/

				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/			
				FROM 
				mp_rfq_quote_SupplierQuote	mrqsq	(nolock) 
				join mp_rfq b						(nolock) on mrqsq.rfq_id = b.rfq_id 
					and rfq_status_id in  (3 , 5, 6 )
					and  is_rfq_resubmitted = 0
					and  mrqsq.is_quote_submitted = 1
					and mrqsq.contact_id   in
					/* M2-2852 M - Add My Company RFQs to the left menu and new page - DB */
					(
						select supplierid from #tmp_mycompany_suppliers
					)
					/**/
				join mp_rfq_preferences  mrp		(nolock) on b.rfq_id = mrp.rfq_id 
				join mp_rfq_parts c					(nolock) on b.rfq_id = c.rfq_id --and c.is_rfq_part_default =  1
				join mp_parts d						(nolock) on c.part_id = d.part_id
				left join mp_system_parameters j	(nolock) on c.post_production_process_id = j.id and j.sys_key = '@PostProdProcesses' 
				left join mp_mst_materials	k		(nolock) on c.material_id = k.material_id 
				left join mp_mst_part_category l	(nolock) on c.part_category_id = l.part_category_id
				/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
				left join mp_mst_part_category category (nolock) on l.parent_part_category_id=category.part_category_id
				/**/
				join mp_contacts m					(nolock) on b.contact_id = m.contact_id
				join mp_companies mcom				(nolock) on m.company_id = mcom.company_id
				left join 
				(
					select distinct m1.company_id, o1.no_of_stars 
					from
					mp_rfq b1 (nolock)
					join mp_contacts m1  (nolock) on b1.contact_id = m1.contact_id  
					join mp_star_rating o1  (nolock) on o1.company_id = m1.company_id
				) o	on o.company_id = m.company_id
				left join mp_special_files p		(nolock) on p.file_id = b.file_id
				left join vw_address				(nolock) on m.address_id = vw_address.address_id
				left join #rfq_likes a	(nolock) on a.rfq_id = b.rfq_id 
				/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
				left join #rfq_list q on b.rfq_id =  q.rfq_id
				/**/
				/* M2-1924 M - In the application the search needs to be inclusive - DB */
				left join #rfq_list_for_parts_search r on  b.rfq_id =  r.rfq_id
				/**/
				left join 
				(
					SELECT 
						a.rfq_id,
						COUNT(c.part_category_id) MatchedPartCount
					FROM mp_rfq					(NOLOCK) a
					LEFT JOIN mp_rfq_parts		(NOLOCK) b ON a.rfq_id = b.rfq_id AND b.status_id  = 2
					LEFT JOIN mp_gateway_subscription_company_processes  (NOLOCK) c ON b.part_category_id = c.part_category_id AND c.company_id = @SupplierCompID  AND c.is_active = 1
 					WHERE  
						a.rfq_id IN (select * from #filtered_rfq_list)
					GROUP BY a.rfq_id
				) s on b.rfq_id = s.rfq_id			
			WHERE 

				b.rfq_id not in  (select rfq_id from @blacklisted_rfqs)
				 /* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
				 and b.rfq_id = case when (select count(processId) from @Processids) > 0 then  q.rfq_id  else b.rfq_id end
				 /**/
				/* M2-1924 M - In the application the search needs to be inclusive - DB */
				and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
				/**/
				and b.rfq_id not in 
				(

					select distinct a.rfq_id  from mp_rfq_quote_SupplierQuote	a	(nolock) 
					join mp_rfq_quote_items (nolock)  b on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id and b.is_awrded = 1 
					and a.contact_id   in
					/* M2-2852 M - Add My Company RFQs to the left menu and new page - DB */
					(
						select supplierid from #tmp_mycompany_suppliers
					)
					/**/
					and  is_rfq_resubmitted = 0

				)
				and c.is_rfq_part_default =  1
				and b.rfq_id in (select * from #filtered_rfq_list) -- Oct 14,2019 - M2-2196 M - My RFQ's page - Saved Search module - Initial State : DB
				and 
				(
					a.is_rfq_like = case when @RfqType in (4,54) then 1 when @RfqType = 104 then 0  end 
					or
					isnull(a.is_rfq_like,1) = (case when @RfqType = 4 then 1 end)
					or
					isnull(a.is_rfq_like,1) = (case when @RfqType = 4 then 0 end)
				)
			) AS QuotedRFQ
				left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on QuotedRFQ.RFQId = rfq_release.rfq_id
			order by 
				case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   partQty end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   partsMaterialName end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   partCategoryName end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   postProductionProcessName end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'release_date' then   release_date end desc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   partQty end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   partsMaterialName end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   partCategoryName end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   postProductionProcessName end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'release_date' then   release_date end asc  
			offset @pagesize * (@pagenumber - 1) rows
			fetch next @pagesize rows only
		end	 
		--=> MyRFQ's => All Tab => Declined Quotes  (5)
		--=> MyRFQ's => Liked Tab => Declined Quotes   (55)
		--=> MyRFQ's => DisLiked Tab => Declined Quotes   (105) 
		else if (@RfqType  in (5,55,105))	
		begin	
			SELECT QuotedRFQ.* , rfq_release.release_date as ReleaseDate, 	count(1) over () RfqCount  FROM 
			(		 
			SELECT
				distinct 
					b.rfq_id as RfqId  
					, b.rfq_name as RfqName 
					, convert(varchar(100),floor(c.min_part_quantity)) as PartQty 
					, c.min_part_quantity_unit as PartQtyUnit  
					, j.value as PostProductionProcessName 
					, k.material_name_en  as PartsMaterialName  
					, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as PartCategoryName
					, b.contact_id as BuyerContactId  
					, b.quotes_needed_by as QuotesNeededBy
					, a.is_rfq_like IsRfqLike  
					, o.no_of_stars AS NoOfStars 
					, coalesce(p.file_name,'') as RfqThumbnail 	 
					, b.special_instruction_to_manufacturer as SpecialInstructions 
					, m.company_id AS BuyerCompanyId	
					, vw_address.state			as State 
					, vw_address.country_name	as Country 	
					, mcom.name as CompanyName 
					, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS CompanyLogoPath 
					, c.rfq_part_id as RfqPartId 
					, c.is_rfq_part_default
					, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )	as	 RfqPartCount 
					/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
					, 
					  case 
						 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
							/* Eddie requested (Jan 21,2020), to remove territory condition and show no of quotes for all platinum users */
						--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
							/**/
						/**/
						/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
						when @is_premium_supplier in (83,84,85) then 0
						/**/
						else
							(
								select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
							)
					  end as NoOfQuotes 
					/**/
					/* May 4, 2020 As discussed with Eddie & Beau Martin , For supplier after taking RFQ capabilities, we need to hide buyer info & restrict supplier to download part files for profile capabilities RFQ’s as we do for basic supplier. */
					,@IsSubscriptionSupplier AS IsSubscriptionSupplier
					,(CASE WHEN s.MatchedPartCount > 0 THEN CAST('true' AS BIT)	ELSE CAST('false' AS BIT) END ) As IsAllowQuoting
					/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/			
			FROM 
				mp_rfq_quote_SupplierQuote	mrqsq	(nolock) 
				join mp_rfq b						(nolock) on mrqsq.rfq_id = b.rfq_id 
					and rfq_status_id in  (3 , 5, 6 )
					/* M2-2852 M - Add My Company RFQs to the left menu and new page - DB */
					and  (mrqsq.is_rfq_resubmitted = 0 OR mrqsq.is_quote_declined = 1 ) 
					and  mrqsq.is_quote_submitted = 1
					and mrqsq.contact_id   in
					
					(
						select supplierid from #tmp_mycompany_suppliers
					)
					/**/
				join mp_rfq_preferences  mrp		(nolock) on b.rfq_id = mrp.rfq_id 
				join mp_rfq_parts c					(nolock) on b.rfq_id = c.rfq_id --and c.is_rfq_part_default =  1
				join mp_parts d						(nolock) on c.part_id = d.part_id
				left join mp_system_parameters j	(nolock) on c.post_production_process_id = j.id and j.sys_key = '@PostProdProcesses' 
				left join mp_mst_materials	k		(nolock) on c.material_id = k.material_id 
				left join mp_mst_part_category l	(nolock) on c.part_category_id = l.part_category_id
				/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
				left join mp_mst_part_category category (nolock) on l.parent_part_category_id=category.part_category_id
				/**/
				join mp_contacts m					(nolock) on b.contact_id = m.contact_id
				join mp_companies mcom				(nolock) on m.company_id = mcom.company_id
				left join 
				(
					select distinct m1.company_id, o1.no_of_stars 
					from
					mp_rfq b1 (nolock)
					join mp_contacts m1  (nolock) on b1.contact_id = m1.contact_id  
					join mp_star_rating o1  (nolock) on o1.company_id = m1.company_id
				) o	on o.company_id = m.company_id
				left join mp_special_files p		(nolock) on p.file_id = b.file_id
				left join vw_address				(nolock) on m.address_id = vw_address.address_id
				left join #rfq_likes a	(nolock) on a.rfq_id = b.rfq_id 
				/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
				left join #rfq_list q on b.rfq_id =  q.rfq_id
				/**/
				/* M2-1924 M - In the application the search needs to be inclusive - DB */
				left join #rfq_list_for_parts_search r on  b.rfq_id =  r.rfq_id
				/**/
				left join 
				(
					SELECT 
						a.rfq_id,
						COUNT(c.part_category_id) MatchedPartCount
					FROM mp_rfq					(NOLOCK) a
					LEFT JOIN mp_rfq_parts		(NOLOCK) b ON a.rfq_id = b.rfq_id AND b.status_id  = 2
					LEFT JOIN mp_gateway_subscription_company_processes  (NOLOCK) c ON b.part_category_id = c.part_category_id AND c.company_id = @SupplierCompID  AND c.is_active = 1
 					WHERE  
						a.rfq_id IN (select * from #filtered_rfq_list)
					GROUP BY a.rfq_id
				) s on b.rfq_id = s.rfq_id			
			WHERE 

				b.rfq_id not in  (select rfq_id from @blacklisted_rfqs)
				 /* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
				 and b.rfq_id = case when (select count(processId) from @Processids) > 0 then  q.rfq_id  else b.rfq_id end
				 /**/
				/* M2-1924 M - In the application the search needs to be inclusive - DB */
				and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
				/**/
				and c.is_rfq_part_default =  1
				and b.rfq_id in (select * from #filtered_rfq_list) -- Oct 14,2019 - M2-2196 M - My RFQ's page - Saved Search module - Initial State : DB
				and 
				(
					a.is_rfq_like = case when @RfqType in (5,55) then 1 when @RfqType = 104 then 0  end 
					or
					isnull(a.is_rfq_like,1) = (case when @RfqType = 5 then 1 end)
					or
					isnull(a.is_rfq_like,1) = (case when @RfqType = 5 then 0 end)
				)
			) AS QuotedRFQ
				left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on QuotedRFQ.RFQId = rfq_release.rfq_id
			order by 
				case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   partQty end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   partsMaterialName end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   partCategoryName end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   postProductionProcessName end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'release_date' then   release_date end desc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   partQty end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   partsMaterialName end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   partCategoryName end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   postProductionProcessName end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'release_date' then   release_date end asc  
			offset @pagesize * (@pagenumber - 1) rows
			fetch next @pagesize rows only

		end
		--=> MyRFQ's => All Tab => Awarded Quotes (6)
		--=> MyRFQ's => Liked Tab => Awarded Quotes  (56)
		--=> MyRFQ's => DisLiked Tab => Awarded Quotes  (106) 
		else if (@RfqType  in (6,56,106))		 
		begin	
	
			SELECT QuotedRFQ.* , rfq_release.release_date as ReleaseDate, 	count(1) over () RfqCount  FROM 
			(		 
			SELECT
				distinct 
					b.rfq_id as RfqId  
					, b.rfq_name as RfqName 
					, convert(varchar(100),floor(c.min_part_quantity)) as PartQty 
					, c.min_part_quantity_unit as PartQtyUnit  
					, j.value as PostProductionProcessName 
					, k.material_name_en  as PartsMaterialName  
					, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as PartCategoryName
					, b.contact_id as BuyerContactId  
					, b.quotes_needed_by as QuotesNeededBy
					, a.is_rfq_like IsRfqLike  
					, o.no_of_stars AS NoOfStars 
					, coalesce(p.file_name,'') as RfqThumbnail 	 
					, b.special_instruction_to_manufacturer as SpecialInstructions 
					, m.company_id AS BuyerCompanyId	
					, vw_address.state			as State 
					, vw_address.country_name	as Country 	
					, mcom.name as CompanyName 
					, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS CompanyLogoPath 
					, c.rfq_part_id as RfqPartId 
					, c.is_rfq_part_default
					, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )	as	 RfqPartCount 
					/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
					, 
					  case 
						 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
							/* Eddie requested (Jan 21,2020), to remove territory condition and show no of quotes for all platinum users */
						--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
							/**/
						/**/
						/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
						when @is_premium_supplier in (83,84,85) then 0
						/**/
						else
							(
								select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
							)
					  end as NoOfQuotes 
					/**/
					/* May 4, 2020 As discussed with Eddie & Beau Martin , For supplier after taking RFQ capabilities, we need to hide buyer info & restrict supplier to download part files for profile capabilities RFQ’s as we do for basic supplier. */
					,@IsSubscriptionSupplier AS IsSubscriptionSupplier
					,(CASE WHEN s.MatchedPartCount > 0 THEN CAST('true' AS BIT)	ELSE CAST('false' AS BIT) END ) As IsAllowQuoting
					/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/			
			FROM 
				mp_rfq_quote_SupplierQuote	mrqsq	(nolock) 
				join mp_rfq b						(nolock) on mrqsq.rfq_id = b.rfq_id 
					--and rfq_status_id in  (3 , 5, 6 )
					--and  is_rfq_resubmitted = 0
					--and  mrqsq.is_quote_submitted = 1
					and mrqsq.contact_id   in
					/* M2-2852 M - Add My Company RFQs to the left menu and new page - DB */
					(
						select supplierid from #tmp_mycompany_suppliers
					)
					/**/
				join mp_rfq_preferences  mrp		(nolock) on b.rfq_id = mrp.rfq_id 
				join mp_rfq_parts c					(nolock) on b.rfq_id = c.rfq_id --and c.is_rfq_part_default =  1
				join mp_parts d						(nolock) on c.part_id = d.part_id
				left join mp_system_parameters j	(nolock) on c.post_production_process_id = j.id and j.sys_key = '@PostProdProcesses' 
				left join mp_mst_materials	k		(nolock) on c.material_id = k.material_id 
				left join mp_mst_part_category l	(nolock) on c.part_category_id = l.part_category_id
				/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
				left join mp_mst_part_category category (nolock) on l.parent_part_category_id=category.part_category_id
				/**/
				join mp_contacts m					(nolock) on b.contact_id = m.contact_id
				join mp_companies mcom				(nolock) on m.company_id = mcom.company_id
				left join 
				(
					select distinct m1.company_id, o1.no_of_stars 
					from
					mp_rfq b1 (nolock)
					join mp_contacts m1  (nolock) on b1.contact_id = m1.contact_id  
					join mp_star_rating o1  (nolock) on o1.company_id = m1.company_id
				) o	on o.company_id = m.company_id
				left join mp_special_files p		(nolock) on p.file_id = b.file_id
				left join vw_address				(nolock) on m.address_id = vw_address.address_id
				left join #rfq_likes a	(nolock) on a.rfq_id = b.rfq_id 
				/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
				left join #rfq_list q on b.rfq_id =  q.rfq_id
				/**/
				/* M2-1924 M - In the application the search needs to be inclusive - DB */
				left join #rfq_list_for_parts_search r on  b.rfq_id =  r.rfq_id
				/**/
				left join 
				(
					SELECT 
						a.rfq_id,
						COUNT(c.part_category_id) MatchedPartCount
					FROM mp_rfq					(NOLOCK) a
					LEFT JOIN mp_rfq_parts		(NOLOCK) b ON a.rfq_id = b.rfq_id AND b.status_id  = 2
					LEFT JOIN mp_gateway_subscription_company_processes  (NOLOCK) c ON b.part_category_id = c.part_category_id AND c.company_id = @SupplierCompID  AND c.is_active = 1
 					WHERE  
						a.rfq_id IN (select * from #filtered_rfq_list)
					GROUP BY a.rfq_id
				) s on b.rfq_id = s.rfq_id			
			WHERE 

				b.rfq_id not in  (select rfq_id from @blacklisted_rfqs)
				 /* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
				 and b.rfq_id = case when (select count(processId) from @Processids) > 0 then  q.rfq_id  else b.rfq_id end
				 /**/
				/* M2-1924 M - In the application the search needs to be inclusive - DB */
				and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
				/**/
				and b.rfq_id in 
				(

					select  distinct b.rfq_id from 
					mp_rfq_quote_items a		(nolock)  
					join mp_rfq_quote_SupplierQuote b  (nolock) on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id 
					and b.contact_id   in
					/* M2-2852 M - Add My Company RFQs to the left menu and new page - DB */
					(
						select supplierid from #tmp_mycompany_suppliers
					)
					/**/	and a.is_awrded=1	
					and is_rfq_resubmitted = 0	
				
				

				)
				and c.is_rfq_part_default =  1
				and b.rfq_id in (select * from #filtered_rfq_list) -- Oct 14,2019 - M2-2196 M - My RFQ's page - Saved Search module - Initial State : DB
				and 
				(
					a.is_rfq_like = case when @RfqType in (6,56) then 1 when @RfqType = 106 then 0  end 
					or
					isnull(a.is_rfq_like,1) = (case when @RfqType = 6 then 1 end)
					or
					isnull(a.is_rfq_like,1) = (case when @RfqType = 6 then 0 end)
				)
			) AS QuotedRFQ
				left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on QuotedRFQ.RFQId = rfq_release.rfq_id
			order by 
				case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   partQty end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   partsMaterialName end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   partCategoryName end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   postProductionProcessName end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'release_date' then   release_date end desc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   partQty end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   partsMaterialName end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   partCategoryName end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   postProductionProcessName end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'release_date' then   release_date end asc  
			offset @pagesize * (@pagenumber - 1) rows
			fetch next @pagesize rows only
		end	 
		--=> MyRFQ's => All Tab =>  Mark for Quoting  (7)
		--=> MyRFQ's => Liked Tab =>  Mark for Quoting  (57)
		--=> MyRFQ's => DisLiked Tab =>  Mark for Quoting  (107) 
		if (@RfqType in (7,57,107) )	
		begin
			select mymarkforquotingrfqs.*  , rfq_release.release_date as ReleaseDate , 	count(1) over () RfqCount    from 
			 (
				select 
					distinct 
					b.rfq_id as RfqId  
					, b.rfq_name as RfqName 
					, convert(varchar(100),floor(c.min_part_quantity)) as PartQty 
					, c.min_part_quantity_unit as PartQtyUnit  
					, j.value as PostProductionProcessName 
					, k.material_name_en  as PartsMaterialName  
					, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as PartCategoryName
					, b.contact_id as BuyerContactId  
					, b.quotes_needed_by as QuotesNeededBy
					, a.is_rfq_like IsRfqLike  
					, o.no_of_stars AS NoOfStars 
					, coalesce(p.file_name,'') as RfqThumbnail 	 
					, b.special_instruction_to_manufacturer as SpecialInstructions 
					, m.company_id AS BuyerCompanyId	
					, vw_address.state			as State 
					, vw_address.country_name	as Country 	
					, mcom.name as CompanyName 
					, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS CompanyLogoPath 
					, c.rfq_part_id as RfqPartId 
					, c.is_rfq_part_default
					, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )	as	 RfqPartCount 
					/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
					, 
					  case 
						 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
							/* Eddie requested (Jan 21,2020), to remove territory condition and show no of quotes for all platinum users */
						--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
							/**/
						/**/
						/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
						when @is_premium_supplier in (83,84,85) then 0
						/**/
						else
							(
								select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
							)
					  end as NoOfQuotes 
					/**/
					,floor(c.min_part_quantity) as PartQty1
					/* May 4, 2020 As discussed with Eddie & Beau Martin , For supplier after taking RFQ capabilities, we need to hide buyer info & restrict supplier to download part files for profile capabilities RFQ’s as we do for basic supplier. */
					,@IsSubscriptionSupplier AS IsSubscriptionSupplier
					,(CASE WHEN s.MatchedPartCount > 0 THEN CAST('true' AS BIT)	ELSE CAST('false' AS BIT) END ) As IsAllowQuoting
					/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/			
				from
				mp_rfq_supplier		mrs				(nolock) 
				join mp_rfq b						(nolock) on mrs.rfq_id = b.rfq_id 
					and rfq_status_id = 3 
				join mp_rfq_preferences  mrp		(nolock) on b.rfq_id = mrp.rfq_id 
				join mp_rfq_parts c					(nolock) on b.rfq_id = c.rfq_id -- and c.is_rfq_part_default =  1
				join mp_parts d						(nolock) on c.part_id = d.part_id
				left join mp_system_parameters j	(nolock) on c.post_production_process_id = j.id and j.sys_key = '@PostProdProcesses' 
				left join mp_mst_materials	k		(nolock) on c.material_id = k.material_id 
				left join mp_mst_part_category l	(nolock) on c.part_category_id = l.part_category_id
				/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
				left join mp_mst_part_category category (nolock) on l.parent_part_category_id=category.part_category_id
				/**/
				join mp_contacts m					(nolock) on b.contact_id = m.contact_id
				join mp_companies mcom				(nolock) on m.company_id = mcom.company_id
				left join 
				(
					select distinct m1.company_id, o1.no_of_stars 
					from
					mp_rfq b1 (nolock)
					join mp_contacts m1  (nolock) on b1.contact_id = m1.contact_id  
					join mp_star_rating o1  (nolock) on o1.company_id = m1.company_id
				) o	on o.company_id = m.company_id
				left join mp_special_files p		(nolock) on p.file_id = b.file_id
				left join vw_address				(nolock) on m.address_id = vw_address.address_id
				left join #rfq_likes			a	(nolock) on a.rfq_id = b.rfq_id  
				/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
				left join #rfq_list q on b.rfq_id =  q.rfq_id
				/**/
				/* M2-1924 M - In the application the search needs to be inclusive - DB */
				left join #rfq_list_for_parts_search r on  b.rfq_id =  r.rfq_id
				/**/
				left join 
				(
					SELECT 
						a.rfq_id,
						COUNT(c.part_category_id) MatchedPartCount
					FROM mp_rfq					(NOLOCK) a
					LEFT JOIN mp_rfq_parts		(NOLOCK) b ON a.rfq_id = b.rfq_id AND b.status_id  = 2
					LEFT JOIN mp_gateway_subscription_company_processes  (NOLOCK) c ON b.part_category_id = c.part_category_id AND c.company_id = @SupplierCompID  AND c.is_active = 1
 					WHERE  
						a.rfq_id IN (select * from #filtered_rfq_list)
					GROUP BY a.rfq_id
				) s on b.rfq_id = s.rfq_id
				where 
				b.rfq_id not in  (select rfq_id from @blacklisted_rfqs)
				 /* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
				 and b.rfq_id = case when (select count(processId) from @Processids) > 0 then  q.rfq_id  else b.rfq_id end
				 /**/
				/* M2-1924 M - In the application the search needs to be inclusive - DB */
				and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
				/**/
				and c.is_rfq_part_default =  1
				and b.rfq_id in (select * from #filtered_rfq_list) -- Oct 14,2019 - M2-2196 M - My RFQ's page - Saved Search module - Initial State : DB
				and 
				(
					a.is_rfq_like = case when @RfqType in (7,57) then 1 when @RfqType = 107 then 0  end 
					or
					isnull(a.is_rfq_like,1) = (case when @RfqType = 7 then 1 end)
					or
					isnull(a.is_rfq_like,1) = (case when @RfqType = 7 then 0 end)
				)
			) mymarkforquotingrfqs
			 left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on mymarkforquotingrfqs.RFQId = rfq_release.rfq_id
			order by 
				case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   PartQty1 end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   partsMaterialName end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   partCategoryName end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   postProductionProcessName end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'release_date' then   release_date end desc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   PartQty1 end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   partsMaterialName end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   partCategoryName end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   postProductionProcessName end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'release_date' then   release_date end asc   
			
			offset @pagesize * (@pagenumber - 1) rows
			fetch next @pagesize rows only
		
		end	
	/**/


	
	
	
	/* End - Oct 14,2019 - M2-2196 M - My RFQ's page - Saved Search module - Initial State : DB */
end
