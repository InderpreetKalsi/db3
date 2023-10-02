
/*

declare @p13 dbo.tbltype_ListOfProcesses

declare @p14 dbo.tbltype_ListOfMaterials

declare @p15 dbo.tbltype_ListOfPostProcesses

declare @p16 dbo.tbltype_ListOfTerritories

declare @p17 dbo.tbltype_ListOfStates

declare @p18 dbo.tbltype_ListOfProximities

declare @p19 dbo.tbltype_ListOfTolerances

declare @p20 dbo.tbltype_ListOfBuyerIndustryId

declare @p21 dbo.tbltype_ListOfCertificateCodes

exec [proc_get_supplier_myrfqs_list]
	@RfqType=1
	,@SupplierID=1350506
	,@SupplierCompID=1769973
	,@PageNumber=1
	,@PageSize=10
	,@SearchText=N'',@Geometry=0,@IsLargePart=default,@SaveSearchID=0,@unit_of_measure_id=0,@orderby=default,@IsOrderByDesc=1,@ProcessIDs=@p13,@MaterialIDs=@p14,@PostProcessIDs=@p15,@BuyerTerritories=@p16,@BuyerStates=@p17,@Proximities=@p18,@Tolerances=@p19,@BuyerIndustryId=@p20,@CertificateId=@p21



*/

 

CREATE PROCEDURE [dbo].[proc_get_supplier_myrfqs_list]
(
	@RfqType			int,	 
	@SupplierID			int,
	@SupplierCompID		int,
	@SearchText			varchar(150)	= null,	
	@SaveSearchID		int				= null,
	@ProcessIDs			as tbltype_ListOfProcesses			readonly,
	@MaterialIDs		as tbltype_ListOfMaterials			readonly,
	@PostProcessIDs		as tbltype_ListOfPostProcesses		readonly,
	@BuyerTerritories	as tbltype_ListOfTerritories		readonly,
	@BuyerStates		as tbltype_ListOfStates				readonly,
	@Proximities		as tbltype_ListOfProximities		readonly,
	@Tolerances			as tbltype_ListOfTolerances			readonly,
	@BuyerIndustryId    as tbltype_ListOfBuyerIndustryId    readonly,
	@CertificateId		as tbltype_ListOfCertificateCodes	readonly,
	@Geometry			int		= null ,
	@unit_of_measure_id	int		= null,
	@width_min			float	= null ,
	@width_max			float	= null ,
	@height_min			float	= null ,
	@height_max			float	= null ,
	@depth_min			float	= null ,
	@depth_max			float	= null ,
	@length_min			float	= null ,
	@length_max			float	= null ,
	@diameter_min		float	= null ,
	@diameter_max		float	= null ,
	@PageNumber			int		= 1,
	@PageSize			int		= 24,
	@IsOrderByDesc		bit		='true',
	@OrderBy			varchar(100)	= null,
	@CurrentDate		datetime		= null,
	@IsLargePart		bit			    = null 

)
as
begin

/*
declare @ProcessIDs dbo.tbltype_ListOfProcesses
declare @MaterialIDs dbo.tbltype_ListOfMaterials
declare @PostProcessIDs dbo.tbltype_ListOfPostProcesses
declare @BuyerTerritories dbo.tbltype_ListOfTerritories
declare @BuyerStates dbo.tbltype_ListOfStates
declare @Proximities dbo.tbltype_ListOfProximities
declare @Tolerances dbo.tbltype_ListOfTolerances
declare @BuyerIndustryId dbo.tbltype_ListOfBuyerIndustryId
declare @CertificateId dbo.tbltype_ListOfCertificateCodes

-- 1350568	1770029
	declare @RfqType			int=6,	 
	@SupplierID			int=1350872,
	@SupplierCompID		int=1770306,
	@SearchText			varchar(150)	= N'',	
	@SaveSearchID		int				= null,
 	@Geometry			int		= 0 ,
	@unit_of_measure_id	int		= null,
	@width_min			float	= null ,
	@width_max			float	= null ,
	@height_min			float	= null ,
	@height_max			float	= null ,
	@depth_min			float	= null ,
	@depth_max			float	= null ,
	@length_min			float	= null ,
	@length_max			float	= null ,
	@diameter_min		float	= null ,
	@diameter_max		float	= null ,
	@PageNumber			int		= 1,
	@PageSize			int		= 24,
	@IsOrderByDesc		bit		='true',
	@OrderBy			varchar(100)	= null,
	@CurrentDate		datetime		= null,
	@IsLargePart		bit			= null 
 
 */

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
		/2	=> MyRFQ's => All Tab => Special Invite's
		/3	=> MyRFQ's => All Tab => Followed Buyer's
		/4	=> MyRFQ's => All Tab => Quoted RFQ's
		/5	=> MyRFQ's => All Tab => Recently Viewed RFQ's
		/6	=> MyRFQ's => All Tab => RFQ's with No Quotes
		/7	=> MyRFQ's => All Tab => RFQ's with Less than 3 Quotes 

		/51	=> MyRFQ's => Liked Tab => AllRFQ's
		/52	=> MyRFQ's => Liked Tab => Special Invite's
		/53	=> MyRFQ's => Liked Tab => Followed Buyer's
		/54	=> MyRFQ's => Liked Tab => Quoted RFQ's
		/55	=> MyRFQ's => Liked Tab => Recently Viewed RFQ's
		/56	=> MyRFQ's => Liked Tab => RFQ's with No Quotes
		/57	=> MyRFQ's => Liked Tab => RFQ's with Less than 3 Quotes 

		/101	=> MyRFQ's => DisLiked Tab => AllRFQ's
		/102	=> MyRFQ's => DisLiked Tab => Special Invite's
		/103	=> MyRFQ's => DisLiked Tab => Followed Buyer's
		/104	=> MyRFQ's => DisLiked Tab => Quoted RFQ's
		/105	=> MyRFQ's => DisLiked Tab => Recently Viewed RFQ's
		/106	=> MyRFQ's => DisLiked Tab => RFQ's with No Quotes
		/107	=> MyRFQ's => DisLiked Tab => RFQ's with Less than 3 Quotes 
	
	
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
	declare @processids2				as tbltype_ListOfProcesses
	declare @MaterialIDs1				as tbltype_ListOfMaterials		
	declare @PostProcessIDs1			as tbltype_ListOfPostProcesses	
	declare @BuyerTerritories1			as tbltype_ListOfTerritories
	declare @BuyerStates1				as tbltype_ListOfStates		
	declare @Proximities1				as tbltype_ListOfProximities	
	declare @Tolerances1				as tbltype_ListOfTolerances	
	declare @BuyerIndustryId1	        as tbltype_ListOfBuyerIndustryId /* M2-3384 : M & Vision - My RFQs - Search by Buyer's Industry -DB */
	/* M2-3810 M - Add search by Certification as a filter on the My RFQ's page-DB */
	declare @CerticateId1				as tbltype_ListOfCertificateCodes
	/**/
	declare @blacklisted_rfqs table (rfq_id int)
	declare @sql_query_rfq_list_based_on_processes nvarchar(max)
	/* May 4, 2020 As discussed with Eddie & Beau Martin , For supplier after taking RFQ capabilities, we need to hide buyer info & restrict supplier to download part files for profile capabilities RFQ’s as we do for basic supplier.*/
	declare @IsSubscriptionSupplier		bit = 0
	/**/
	/* M2-4653 -- based on current subscription */
	declare @UnlockedRfqsCount int=0
	declare @IsRfqUnlocked INT=0
	/**/
	DECLARE @SubscriptionStatus VARCHAR(25), @RunningSubscriptionId INT  /* M2-4686 */

	drop table if exists #rfq_list
	drop table if exists #rfq_list_for_parts_search
	drop table if exists #rfqlocation  -- /*  M2-2087 Clone up to 3 RFQ's for 3 regions - API */
	drop table if exists #rfq_likes
	drop table if exists #filtered_rfq_list
	drop table if exists #geocode
	/* M2-4653 -- based on current subscription */
	drop table if exists #tmpmpGrowthPackageUnlockRFQsInfo
	/**/
	

	create table #rfq_list (rfq_id int)
	create table #rfq_list_for_parts_search (rfq_id int)
	create table #rfqlocation (rfq_location int) -- /*  M2-2087 Clone up to 3 RFQ's for 3 regions - API */
	create table #filtered_rfq_list (rfq_id int) -- /*  Oct 14,2019 - M2-2196 M - My RFQ's page - Saved Search module - Initial State : DB */

	if @currentdate is null
	begin
		set @inputdate = convert(varchar(8),format(getutcdate(),'yyyyMMdd'))
		set @currentdate = getutcdate()
	end
	else
	begin
		set @inputdate = convert(varchar(8),format(@currentdate,'yyyyMMdd'))
	end

	--set @is_registered_supplier = (select  top 1 is_registered from mp_registered_supplier (nolock)  where company_id = @SupplierCompID order by account_type desc )
	set @is_premium_supplier = isnull((select top 1 account_type from mp_registered_supplier (nolock)  where company_id = @SupplierCompID order by account_type desc),83)
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

	--set @is_stripe_supplier =
	--						(case	when (select count(1) from mp_gateway_subscription_company_processes (nolock)  where  company_id =  @SupplierCompID and is_active = 1)> 0 then cast('true' as bit) else cast('false' as bit) end )

	/* M2-4653 -- based on current subscription  */             
	IF exists (SELECT  COUNT(1) from mp_registered_supplier (NOLOCK)  WHERE company_id = @SupplierCompID AND account_type = 84) --- this is silver supplier
	BEGIN
		 ---- below code commented with M2-5221
		 /* M2-4686 */
			 ---- Getting status and latest running id against company id
			 --SELECT  TOP 1  @SubscriptionStatus =   b.status , @RunningSubscriptionId = b.id 
				--FROM [dbo].[mp_gateway_subscription_customers] (NOLOCK) a
				--JOIN [dbo].[mp_gateway_subscriptions] (NOLOCK) b ON a.id= b.customer_id
				--WHERE a.gateway_id = 310 
				--AND a.company_id = @SupplierCompID
				--ORDER BY b.ID DESC
		 /* END : M2-4686 */

		   ------ Updated code with M2-5221
		;WITH cte AS 
		(
			SELECT   MAX(b.subscription_start)  subscription_start 
			, MAX(b.subscription_end) subscription_end
			FROM [dbo].[mp_gateway_subscription_customers] (NOLOCK) a
			JOIN [dbo].[mp_gateway_subscriptions] (NOLOCK) b ON a.id= b.customer_id
			WHERE a.gateway_id = 310 
			AND a.company_id = @SupplierCompID
		)  
			SELECT  TOP 1     @SubscriptionStatus =   b.status ,   @RunningSubscriptionId = b.id 
			FROM [dbo].[mp_gateway_subscription_customers] (NOLOCK) a
			JOIN [dbo].[mp_gateway_subscriptions] (NOLOCK) b ON a.id= b.customer_id
			JOIN cte on cte.subscription_start = b.subscription_start and cte.subscription_end = b.subscription_end
			WHERE a.gateway_id = 310 
			AND a.company_id = @SupplierCompID
			ORDER BY b.ID DESC


		---- getting RFQ count as per company level based on current subscription start and end date renge
		--SET @UnlockedRfqsCount =
		--(
		--	SELECT COUNT(DISTINCT c.rfq_id)
		--	FROM [dbo].[mp_gateway_subscription_customers] (NOLOCK) a
		--	JOIN [dbo].[mp_gateway_subscriptions] (NOLOCK) b ON 
		--		a.id = b.customer_id 
		--		AND CAST(b.subscription_end AS DATE) >= CAST(GETUTCDATE() AS DATE)
		--		AND a.company_id = @SupplierCompID
		--		AND [status] = 'active'
		--	JOIN  mpGrowthPackageUnlockRFQsInfo (NOLOCK) c on c.CompanyId = a.company_id
		--	WHERE 
		--		CAST(c.UnlockDate AS DATE) >= CAST(b.subscription_start AS DATE)
		--		AND CAST(c.UnlockDate AS DATE) <= CAST(b.subscription_end AS DATE)
		--)

		IF @SubscriptionStatus = 'active'
		BEGIN
			SET @UnlockedRfqsCount =
			(
				SELECT COUNT(DISTINCT c.rfq_id)
				FROM [dbo].[mp_gateway_subscription_customers] (NOLOCK) a
				JOIN [dbo].[mp_gateway_subscriptions] (NOLOCK) b ON 
					a.id = b.customer_id 
					--AND CAST(b.subscription_end AS DATE) >= CAST(GETUTCDATE() AS DATE)
					AND a.company_id = @SupplierCompID
				JOIN  mpGrowthPackageUnlockRFQsInfo (NOLOCK) c on c.CompanyId = a.company_id
				/* Slack issue : restored used RFQs -> IsDeleted = 1 */ 
					AND c.IsDeleted = 0
				WHERE 
					b.id = @RunningSubscriptionId
					AND c.UnlockDate  >= b.subscription_start
					AND c.UnlockDate <= b.subscription_end
			)

		END
		ELSE
		BEGIN
		SET @UnlockedRfqsCount =
			(
				SELECT COUNT(DISTINCT c.rfq_id)
				FROM [dbo].[mp_gateway_subscription_customers] (NOLOCK) a
				JOIN [dbo].[mp_gateway_subscriptions] (NOLOCK) b ON 
				a.id = b.customer_id 
				--AND CAST(b.subscription_end AS DATE) >= CAST(GETUTCDATE() AS DATE)
				AND a.company_id = @SupplierCompID
				JOIN  mpGrowthPackageUnlockRFQsInfo (NOLOCK) c on c.CompanyId = a.company_id
				/* Slack issue : restored used RFQs -> IsDeleted = 1 */ 
					AND c.IsDeleted = 0
				WHERE 
					b.id = @RunningSubscriptionId
					AND c.UnlockDate  >= b.subscription_start
					AND CAST(c.UnlockDate AS DATE) <=  CAST(DATEADD(dd,30, b.subscription_end) AS DATE)
		   )
		END


		SELECT Rfq_Id  INTO #tmpmpGrowthPackageUnlockRFQsInfo 
		FROM mpGrowthPackageUnlockRFQsInfo (NOLOCK) WHERE CompanyId = 		@SupplierCompID
		/* Slack issue : restored used RFQs -> IsDeleted = 1 */ 
					AND IsDeleted = 0
		

	END
	/**/
	  

	if (select count(1) from @Proximities) > 0
	begin
		
		select 
			@latitude= c.latitude
			, @longitude = c.longitude
		from mp_contacts			(nolock) a 
		join mp_addresses			(nolock) b on a.address_id = b.address_id 
			-- and b.is_geocode_data_added =1  
			and a.contact_id in (@SupplierID)
		join mp_mst_country			(nolock) d on b.country_id = d.country_id
		join mp_mst_geocode_data	(nolock) c on b.address3 = c.zipcode and d.country_name = c.country
		
		select @proximities_value = value from mp_system_parameters where id in  (select * from @Proximities)

		create table #geocode
		(
			zipcode  nvarchar(200) null ,
			distance float null
		)
	
		insert into #geocode
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


	


	/*  M2-2087 Clone up to 3 RFQ's for 3 regions - API */
	if @manufacturing_location_id = 4 
		
		insert into #rfqlocation values (7), (4)
	
	if @manufacturing_location_id = 5
		insert into #rfqlocation values (7), (5)

	if @manufacturing_location_id not in (4,5)
		insert into #rfqlocation values (@manufacturing_location_id)
	/**/
	
	/* M2-2863 Vision - RFQs - Filter by Process - DB */
	drop table if exists #tmpprocesses
	create table #tmpprocesses
	(
		parent_part_category_id int null
		, part_category_id int null
	)

	insert into #tmpprocesses (parent_part_category_id , part_category_id)
	select distinct parent_part_category_id , part_category_id 
	from mp_mst_part_category a where part_category_id in (select processId from @ProcessIDs ) and status_id = 2 and level =1 

	insert into #tmpprocesses (parent_part_category_id , part_category_id)
	select distinct parent_part_category_id , part_category_id 
	from mp_mst_part_category a where parent_part_category_id in 
	(
		select processId from @ProcessIDs where  processId not in (select parent_part_category_id from #tmpprocesses) 
	) and status_id = 2 and level =1 

	/**/
	
	/* M2-3209 Capabiities (Parent & Child) changes - DB */
	insert into @processids2
	--select part_category_id from mp_mst_part_category (nolock) where parent_part_category_id in (select * from @ProcessIDs) and level = 1 and status_id = 2
	--union 
	--select * from @ProcessIDs
	/* M2-2863 Vision - RFQs - Filter by Process - DB */
	select distinct part_category_id from #tmpprocesses
	/**/
	/**/
	
    insert into @blacklisted_rfqs (rfq_id)
    select distinct c.rfq_id 
	from mp_book_details					a (nolock)
    join mp_books							b (nolock) on a.book_id = b.book_id 
    join mp_rfq								c (nolock) on b.contact_id = c.contact_id
	left join mp_rfq_quote_supplierquote	f (nolock) on c.rfq_id = f.rfq_id and f.contact_id = @SupplierID
	left join mp_rfq_quote_items			e (nolock) on f.rfq_quote_SupplierQuote_id= e.rfq_quote_SupplierQuote_id
    where bk_type= 5 and a.company_id = @SupplierCompID and  ((f.is_quote_submitted = 0 or f.is_quote_submitted is null)and  isnull(e.is_awrded,0) = 0)
	union  -- exclude rfq's for black listed buyer which are awarded & quoted 
	select distinct c.rfq_id  
	from mp_book_details					a (nolock) 
    join mp_books							b (nolock) on a.book_id = b.book_id  and b.contact_id = @SupplierID
	join mp_contacts						d (nolock) on a.company_id =  d.company_id
	join mp_rfq								c (nolock) on d.contact_id = c.contact_id
	left join mp_rfq_quote_supplierquote	f (nolock) on c.rfq_id = f.rfq_id and f.contact_id = @SupplierID
	left join mp_rfq_quote_items			e (nolock) on f.rfq_quote_SupplierQuote_id= e.rfq_quote_SupplierQuote_id
    where bk_type= 5 and  ((f.is_quote_submitted = 0 or f.is_quote_submitted is null)and  isnull(e.is_awrded,0) = 0)
	/* M2-3251  Vision - Flag as a test account and hide the data from reporting - DB */
	union
	select distinct b.rfq_id
	from mp_contacts	(nolock) a
	join mp_rfq		(nolock) b on a.contact_id = b.contact_id 
	where is_buyer = 1 and isnull(a.istestaccount,0) = 1 
	/**/


	if (@RfqType in (1,14,18)) and (@OrderBy is null or @OrderBy = '' )
		set @OrderBy  = 'release_date'
	else if (@RfqType in (3)) and (@OrderBy is null or @OrderBy = '' )
		set @OrderBy  = ''
	else if (@OrderBy is null or @OrderBy = '' )
		set @OrderBy  = 'quoteby'

	select rfq_id ,is_rfq_like into #rfq_likes from  mp_rfq_supplier_likes a	(nolock) where contact_id = @SupplierID 

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
		when @RfqType in (1,51,101,5,55,105,6,56,106,7,57,107) then

			case	
				when @SupplierCompID in (1780723,991070,1465765,1537437) then 
					' and a.rfq_status_id in ( 3 ,5 ,6 ,16 ,17 ,18)   
					  and convert(date,a.rfq_created_on  ) >=  convert(date,dateadd(month,-2,getutcdate())) ' 
				else ' and a.rfq_status_id = 3 
					   and format(a.quotes_needed_by,''yyyyMMdd'') >= '''+@inputdate+'''  ' 
			end
			+ 
			'
		 	join mp_rfq_preferences		mrp (nolock) on a.rfq_id = mrp.rfq_id and mrp.rfq_pref_manufacturing_location_id in (select * from #rfqlocation)  
			'	
		when @RfqType in (2,52,102) then
			' and a.rfq_status_id = 3 
			join mp_rfq_supplier	mrs	(nolock) on mrs.rfq_id = a.rfq_id and mrs.company_id = ' + convert(varchar(100),@SupplierCompID) 
		when @RfqType in (4,54,104) then
			' and a.rfq_status_id in  (3 , 5, 6 ) 
			join mp_rfq_quote_SupplierQuote	mrqsq	(nolock) on mrqsq.rfq_id = a.rfq_id and mrqsq.contact_id =  '+convert(varchar(50),@SupplierID)
		when @RfqType in (3,53,103) then
			' and a.rfq_status_id not in (14) and a.rfq_status_id > 2 
			join mp_contacts	e (nolock) on a.contact_id = e.contact_id
			join 
				(
					select distinct mbd.company_id 
					from mp_book_details	mbd		(nolock)
					join mp_books			mb		(nolock)	on mbd.book_id =mb.book_id
					join mp_mst_book_type	mmbt	(nolock)	on mmbt.book_type_id = mb.bk_type
					and mmbt.book_type =''BOOK_BOOKTYPE_HOTLIST''
					and mb.contact_id = '+convert(varchar(50),@SupplierID)+'
				) followed_buyer on followed_buyer.company_id = e.company_id 
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

	exec sp_executesql  @sql_query_rfq_list_based_on_processes 
	,N'@processids1  tbltype_ListOfProcesses readonly'
	,@processids1  = @processids2	
	
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
	/* M2-3810 M - Add search by Certification as a filter on the My RFQs page-DB */
	left join mp_rfq_special_certificates (nolock)  mrsc on a.rfq_id = mrsc.rfq_id
	/**/	
	/* M2-3384 : M & Vision - My RFQs - Search by Buyers Industry -DB */
	left join mp_company_supplier_types mcst (nolock) on mcom.company_id = mcst.company_id and mcst.is_buyer = 1 


	'
	+
	case 
		when @RfqType in (1,51,101,5,55,105,6,56,106,7,57,107) then
			case	
				when @SupplierCompID in (1780723,991070,1465765,1537437) then 
					' and a.rfq_status_id in ( 3 ,5 ,6 ,16 ,17 ,18 )  
					  and convert(date,a.rfq_created_on  ) >=  convert(date,dateadd(month,-6,getutcdate())) ' 
				else ' and a.rfq_status_id = 3 
					   and format(a.quotes_needed_by,''yyyyMMdd'') >= '''+@inputdate+'''  ' 
			end
			+ 
			'
			join mp_rfq_preferences		mrp (nolock) on a.rfq_id = mrp.rfq_id and mrp.rfq_pref_manufacturing_location_id in (select * from #rfqlocation)  
			'	
		when @RfqType in (2,52,102) then
			' and a.rfq_status_id = 3 
			 join mp_rfq_preferences		mrp (nolock) on a.rfq_id = mrp.rfq_id 
			 join mp_rfq_supplier	mrs	(nolock) on mrs.rfq_id = a.rfq_id and mrs.company_id = ' + convert(varchar(100),@SupplierCompID) 
		when @RfqType in (3,53,103) then
			' and a.rfq_status_id not in (14) and a.rfq_status_id > 2 
			 join 
				(
					select distinct mbd.company_id 
					from mp_book_details	mbd		(nolock)
					join mp_books			mb		(nolock)	on mbd.book_id =mb.book_id
					join mp_mst_book_type	mmbt	(nolock)	on mmbt.book_type_id = mb.bk_type
					and mmbt.book_type =''BOOK_BOOKTYPE_HOTLIST''
					and mb.contact_id = '+convert(varchar(50),@SupplierID)+'
				) followed_buyer on followed_buyer.company_id = mc.company_id 
			'
		when @RfqType in (4,54,104) then
			' and a.rfq_status_id in  (3 , 5, 6 , 16,17 ) 
			join mp_rfq_quote_SupplierQuote	mrqsq	(nolock) on mrqsq.rfq_id = a.rfq_id and mrqsq.contact_id =  '+convert(varchar(50),@SupplierID)
		else ''
	end
	+
	'
	 left join vw_address		vwa (nolock) on mc.address_id = vwa.address_Id	
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

	--select @width_min ,@width_max ,@height_min ,@height_max ,@depth_min ,@depth_max ,@length_min ,@length_max ,@diameter_min ,@diameter_max
	
	/* M2-3417 M - Add Part size to the RFQ Search filter - DB*/
	set @extra_field =  
		case 
			when @Geometry = 0 then
				case
					when @IsLargePart is null then ''
					when @IsLargePart = 0 then ' and ( IsLargePart = 0) '
					when @IsLargePart = 1 then ' and ( IsLargePart = 1) '
				end
			when @Geometry = 58 then
				case 
					when @IsLargePart is null then ''
					when @IsLargePart = 0 then ' and ( GeometryId = 58 and isnull(IsLargePart,0) = 0) '
					when @IsLargePart = 1 then ' and ( GeometryId = 58 and IsLargePart = 1) '
				end 
			when @Geometry = 59 then	
				case 
					when @IsLargePart is null then ''
					when @IsLargePart = 0 then ' and ( GeometryId = 59 and isnull(IsLargePart,0) = 0) '
					when @IsLargePart = 1 then ' and ( GeometryId = 59 and IsLargePart = 1) '
				end 
			else ''
		end 
	/**/
	
	set @where_query = 
	case when ((select count(1) from @processids2) > 0 or @company_capabilities > 0)   then ' a.rfq_id in (select * from  #rfq_list ) ' else '' end
	+ case when (select count(1) from @MaterialIDs) > 0 then ' and c.material_id in (select * from  @MaterialIDs1 ) ' else '' end
	+ case when (select count(1) from @PostProcessIDs) > 0 then ' and b.post_production_process_id in (select * from  @PostProcessIDs1 ) ' else '' end
	/* M2-3810 M - Add search by Certification as a filter on the My RFQ's page-DB */
	+ case when (select count(1) from @CertificateId) > 0 then ' and mrsc.certificate_id in (select * from  @CerticateId1 ) ' else '' end 
	/**/
	+ case when (select count(1) from @BuyerTerritories) > 0 then ' and mcom.manufacturing_location_id in (select * from  @BuyerTerritories1 '+ case when (select count(1) from @BuyerTerritories where territoryId = 7) > 0 then ' union select 4 union select 5  ' when (select count(1) from @BuyerTerritories where territoryId in (4,5)) > 0 then ' union select 7 ' else '' end +' ) ' else '' end
	+ case when (select count(1) from @BuyerStates) > 0 then ' and vwa.regionId in (select * from  @BuyerStates1 ) ' else '' end
	+ case when @Geometry = 58 then @extra_field else '' 
	   end
	+ case when @Geometry = 59 then @extra_field else '' 
	  end
	+ case when @Geometry = 0 then @extra_field else '' 
	   end
	+ case when (select count(1) from @Tolerances) > 0 then ' and c.tolerance_id in (select * from  @Tolerances1 ) ' else '' end
	+ case when (select count(1) from @Proximities) > 0 then 
		' and a.rfq_id in (select distinct f.rfq_id
			from #geocode a
			join mp_addresses	(nolock) b on a.zipcode = b.address3
			join mp_mst_country (nolock) c on b.country_id = c.country_id 
			join mp_contacts	(nolock) d on b.address_id = d.address_id and d.is_buyer =1 
			join mp_companies	(nolock) e on d.company_id = e.company_id and e.manufacturing_location_id in  (select * from #rfqlocation)
			join mp_rfq			(nolock) f on d.contact_id = f.contact_id and f.rfq_status_id in  (3 , 5, 6 ) ) ' else '' end 
	/* M2-3384 : M & Vision - My RFQs - Search by Buyer's Industry -DB */
    + case when (select count(1) from @BuyerIndustryId) > 0 then ' and mcst.supplier_type_id in (select * from  @BuyerIndustryId1) ' else '' end
	
	--select @where_query as where_query

	if left(@where_query,5) = ' and '
		set @where_query = substring(@where_query , 6, len(@where_query))
		
	set  @sql_query_rfq_list_based_on_processes = @sql_query_rfq_list_based_on_processes + case when len(@where_query) > 0 then ' where ' else '' end + @where_query 
	
	--select @sql_query_rfq_list_based_on_processes, @extra_field , @where_query


	exec sp_executesql  @sql_query_rfq_list_based_on_processes 
	,N'@MaterialIDs1 tbltype_ListOfMaterials readonly , @PostProcessIDs1 as tbltype_ListOfPostProcesses	 readonly ,@CerticateId1 tbltype_ListOfCertificateCodes readonly , @BuyerTerritories1 as tbltype_ListOfTerritories readonly, @BuyerStates1 as tbltype_ListOfStates readonly,@Tolerances1 as tbltype_ListOfTolerances	readonly, @BuyerIndustryId1 as tbltype_ListOfBuyerIndustryId readonly'
	,@MaterialIDs1 = @MaterialIDs
	,@PostProcessIDs1 = @PostProcessIDs
	,@BuyerTerritories1 = @BuyerTerritories
	,@BuyerStates1 = @BuyerStates
	,@Tolerances1 = @Tolerances
	,@CerticateId1 = @CertificateId /* M2-3810 M - Add search by Certification as a filter on the My RFQ's page-DB */
	,@BuyerIndustryId1 = @BuyerIndustryId /* M2-3384 : M & Vision - My RFQs - Search by Buyer's Industry -DB */


	/* M2-1924 M - In the application the search needs to be inclusive - DB */
	if len(@SearchText) > 0
	begin
		insert into #rfq_list_for_parts_search (rfq_id)
		select distinct a.rfq_id 
		from mp_rfq	(nolock) a 
		/* M2-3075  M - Add keyword search to the RFQ search page - DB*/
		left join mp_rfq_parts (nolock) b on a.rfq_id = b.rfq_id
		left join mp_parts (nolock) c on c.part_id = b.part_id
		left join mp_mst_part_category (nolock) d on b.part_category_id = d.part_category_id
		left join mp_mst_part_category (nolock) e on d.parent_part_category_id = e.part_category_id
		/**/
		where 
			(a.rfq_name like '%'+@SearchText+'%')	
			OR	
			(a.rfq_id like '%'+@SearchText+'%')		
			OR
			/* M2-3075  M - Add keyword search to the RFQ search page - DB*/
			(isnull(c.part_name,'') like '%'+@SearchText+'%')		
			OR
			(isnull(a.rfq_description,'') like '%'+@SearchText+'%')		
			OR
			(isnull(d.discipline_name,'') like '%'+@SearchText+'%')
			OR
			(isnull(e.discipline_name,'') like '%'+@SearchText+'%')		
			/**/
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
					--, b.rfq_status_id as RFQStatus
					, convert(varchar(100),floor(c.min_part_quantity)) as PartQty 
					, c.min_part_quantity_unit as PartQtyUnit  
					, j.value as PostProductionProcessName 
					, k.material_name_en  as PartsMaterialName  
					, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as PartCategoryName
					, b.contact_id as BuyerContactId  
					, b.Quotes_needed_by as QuotesNeededBy
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
						when @is_premium_supplier in (83,84,85,313) then 0
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
				/**/
				/* M2-4653 */
				, t.Rfq_Id	  AS  IsRfqUnlocked  
				, b.pref_NDA_Type     AS  NDALevel
				, @UnlockedRfqsCount  AS  UnlockedRfqCount
				, 
				(
					CASE 
						WHEN @is_premium_supplier = 84 THEN
							CASE	
								WHEN t.Rfq_Id IS NOT NULL  THEN 'No Action'
								WHEN @UnlockedRfqsCount = 3 OR b.pref_NDA_Type = 2 THEN 'Upgrade to Quote'
								WHEN @UnlockedRfqsCount < 3 AND s.MatchedPartCount = 0  THEN 'Upgrade to Quote'
								ELSE 'Unlock Rfq Button'
							END
						WHEN @is_premium_supplier IN (83,313) THEN 'Upgrade to Quote' ---Added 313 with M2-5133 
						WHEN @is_premium_supplier IN (85,86) THEN 'No Action'
					END
				)
				AS ActionForGrowthPackage
				/**/
				/* M2-4754 */
				,b.IsRfqWithMissingInfo  
				/**/
				/* M2-4793 */
				,b.WithOrderManagement  
				/**/
				from
				mp_rfq_supplier		mrs				(nolock) 
				join mp_rfq b						(nolock) on mrs.rfq_id = b.rfq_id 
					--and rfq_status_id = 3 
					--and format(b.quotes_needed_by,'yyyyMMdd') >= format(@currentdate,'yyyyMMdd') 
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
				/* M2-4653 */
				left join #tmpmpGrowthPackageUnlockRFQsInfo t on b.rfq_id = t.Rfq_Id
				/**/
				where 
				( 
					 (
						mrs.company_id = -1 
						and mrp.rfq_pref_manufacturing_location_id in 
						/*  M2-2087 Clone up to 3 RFQ's for 3 regions - API */
						(select * from #rfqlocation)
						/**/
						--and rfq_status_id = 3  
						/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
						and b.rfq_id = case when (select count(1) from #rfq_list)  > 0 then  q.rfq_id  else b.rfq_id end
						/**/
						/* M2-1924 M - In the application the search needs to be inclusive - DB */
						and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
						/**/
					 )
			 
				)
				and b.rfq_id not in  (select distinct rfq_id from mp_rfq_quote_SupplierQuote (nolock) where contact_id = @SupplierID  )
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
		--=> MyRFQ's => All Tab => Special Invite's (2)
		--=> MyRFQ's => Liked Tab => Special Invite's  (52)
		--=> MyRFQ's => DisLiked Tab => Special Invite's  (102) 
		else if  (@RfqType in (2,52,102))
		begin

			SELECT SpecialInviteRFQ.* , rfq_release.release_date as ReleaseDate, 	count(1) over () RfqCount  FROM (
				select 
					distinct 
					b.rfq_id as RfqId  
					, b.rfq_name as RfqName 
					, convert(varchar(100),floor(c.min_part_quantity)) as PartQty 
					, c.min_part_quantity_unit as PartQtyUnit  
					, j.value as PostProductionProcessName 
					, k.material_name_en  as PartsMaterialName  
					,  case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as PartCategoryName
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
						when @is_premium_supplier in (83,84,85,313) then 0
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
				/* M2-4653 */
				, @IsRfqUnlocked	  AS  IsRfqUnlocked  
				, b.pref_NDA_Type     AS  NDALevel
				, @UnlockedRfqsCount  AS  UnlockedRfqCount
				/**/
				/* M2-4754 */
				,b.IsRfqWithMissingInfo  
			    /**/
				/* M2-4793 */
				,b.WithOrderManagement  
				/**/
				from
				mp_rfq_supplier		mrs				(nolock) 
				join mp_rfq b						(nolock) on mrs.rfq_id = b.rfq_id and rfq_status_id = 3 and mrs.company_id =@SupplierCompID
				join mp_rfq_preferences  mrp		(nolock) on b.rfq_id = mrp.rfq_id 
				join mp_rfq_parts c					(nolock) on b.rfq_id = c.rfq_id   --and c.is_rfq_part_default =  1
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
				where 
				 b.rfq_id not in  (select rfq_id from @blacklisted_rfqs) 
				 /* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
				 and b.rfq_id = case when (select count(processId) from @processids2) > 0 then  q.rfq_id  else b.rfq_id end
				 /**/
				/* M2-1924 M - In the application the search needs to be inclusive - DB */
				and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
				/**/
				and b.rfq_id not in (select distinct rfq_id from mp_rfq_quote_SupplierQuote (nolock) where contact_id = @SupplierID )
				/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
				and c.is_rfq_part_default =  1
				/**/
				and b.rfq_id in (select * from #filtered_rfq_list) -- Oct 14,2019 - M2-2196 M - My RFQ's page - Saved Search module - Initial State : DB
				and b.rfq_id = case when @RfqType in (52,102) then a.rfq_id else  b.rfq_id end 
				and 
				(
					a.is_rfq_like = case when @RfqType in (2,52) then 1 when @RfqType = 102 then 0  end 
					or
					isnull(a.is_rfq_like,1) = (case when @RfqType = 2 then 1 end)
					or
					isnull(a.is_rfq_like,1) = (case when @RfqType = 2 then 0 end)
				)
			) SpecialInviteRFQ
			left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on SpecialInviteRFQ.RFQId = rfq_release.rfq_id
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
		--=> MyRFQ's => All Tab => Followed Buyer's (3)
		--=> MyRFQ's => Liked Tab => Followed Buyer's  (53)
		--=> MyRFQ's => DisLiked Tab => Followed Buyer's  (103) 
		else if (@RfqType in (3,53,103))		 
		begin	
		
			select FollowedBuyersRFQ.* , rfq_release.release_date as ReleaseDate, 	count(1) over () RfqCount  from 
			(
				select 
					distinct 
					b.rfq_id as RfqId  
					, b.rfq_name as RfqName 
					, convert(varchar(100),floor(c.min_part_quantity)) as PartQty 
					, c.min_part_quantity_unit as PartQtyUnit  
					, j.value as PostProductionProcessName 
					, k.material_name_en  as PartsMaterialName  
					,  case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as PartCategoryName
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
						when @is_premium_supplier in (83,84,85,313) then 0
						/**/
						else
							(
								select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
							)
					  end as NoOfQuotes 
					/**/
					/* M2-2092 M - Add sort A-Z and Z-A to the followed Buyer RFQ's sort list -DB*/
					, followed_buyer.FollowedDate
					/**/
					/* May 4, 2020 As discussed with Eddie & Beau Martin , For supplier after taking RFQ capabilities, we need to hide buyer info & restrict supplier to download part files for profile capabilities RFQ’s as we do for basic supplier. */
					,@IsSubscriptionSupplier AS IsSubscriptionSupplier
					,(CASE WHEN s.MatchedPartCount > 0 THEN CAST('true' AS BIT)	ELSE CAST('false' AS BIT) END ) As IsAllowQuoting
					/**/
				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
				/* M2-4653 */
				, @IsRfqUnlocked	  AS	 IsRfqUnlocked  
				, b.pref_NDA_Type     AS  NDALevel
				, @UnlockedRfqsCount  AS  UnlockedRfqCount
				/**/
				/* M2-4754 */
				,b.IsRfqWithMissingInfo  
			    /**/
				/* M2-4793 */
				,b.WithOrderManagement  
				/**/
				from 
				mp_rfq b							(nolock) 
				/* DATA-70 Followed Buyers RFQs needs to only display past RFQs that match the suppliers manufacturing location	*/
				join mp_rfq_preferences  mrp		(nolock) on b.rfq_id = mrp.rfq_id and mrp.rfq_pref_manufacturing_location_id  in 
						/*  M2-2087 Clone up to 3 RFQ's for 3 regions - API */
						(select * from #rfqlocation)
						/**/
				/**/
				join mp_rfq_parts c					(nolock) on b.rfq_id = c.rfq_id  --and c.is_rfq_part_default =  1 
					and rfq_status_id > 2 
					and rfq_status_id not in (14)
				join mp_parts d						(nolock) on c.part_id = d.part_id
				left join mp_system_parameters j	(nolock) on c.post_production_process_id = j.id and j.sys_key = '@PostProdProcesses' 
				left join mp_mst_materials	k		(nolock) on c.material_id = k.material_id 
				left join mp_mst_part_category l	(nolock) on c.part_category_id = l.part_category_id
				/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
				left join mp_mst_part_category category (nolock) on l.parent_part_category_id=category.part_category_id
				/**/
				join mp_contacts m					(nolock) on b.contact_id = m.contact_id
				join mp_companies mcom				(nolock) on m.company_id = mcom.company_id			 
				left join mp_star_rating o			(nolock) on o.company_id = m.company_id
				join 
				(

					select distinct mbd.company_id,mbd.creation_date FollowedDate from 
					mp_book_details mbd			(nolock)
					JOIN mp_books  mb			(nolock)	on mbd.book_id =mb.book_id
					JOIN mp_mst_book_type mmbt	(nolock)	on mmbt.book_type_id = mb.bk_type
					and mmbt.book_type ='BOOK_BOOKTYPE_HOTLIST'
					and mb.contact_id = @SupplierID

				) followed_buyer on followed_buyer.company_id = mcom.company_id 
			 
				left join mp_special_files p		(nolock) on p.file_id = b.file_id
				left join vw_address				(nolock) on m.address_id = vw_address.address_id
				/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
				left join #rfq_list q on b.rfq_id =  q.rfq_id
				/**/
				left join #rfq_likes a	(nolock) on a.rfq_id = b.rfq_id  
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
				 and b.rfq_id = case when (select count(processId) from @processids2) > 0 then  q.rfq_id  else b.rfq_id end
				 /**/
				/* M2-1924 M - In the application the search needs to be inclusive - DB */
				and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
				/**/
				/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
				and c.is_rfq_part_default =  1
				/**/
				and b.rfq_id in (select * from #filtered_rfq_list) -- Oct 14,2019 - M2-2196 M - My RFQ's page - Saved Search module - Initial State : DB
				and 
				(
					a.is_rfq_like = case when @RfqType in (3,53) then 1 when @RfqType = 103 then 0  end 
					or
					isnull(a.is_rfq_like,1) = (case when @RfqType = 3 then 1 end)
					or
					isnull(a.is_rfq_like,1) = (case when @RfqType = 3 then 0 end)
				)
			) FollowedBuyersRFQ
			left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on FollowedBuyersRFQ.RFQId = rfq_release.rfq_id
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
				/* DATA-70 Followed Buyers RFQs needs to only display past RFQs that match the suppliers manufacturing location	*/
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'buyer'then   CompanyName end asc  
				,case  when @IsOrderByDesc =  0 and @OrderBy = '' then   FollowedDate end asc
				/**/
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
					,  case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as PartCategoryName
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
						when @is_premium_supplier in (83,84,85,313) then 0
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
				/* M2-4653 */
				, @IsRfqUnlocked	  AS	 IsRfqUnlocked  
				, b.pref_NDA_Type     AS  NDALevel
				, @UnlockedRfqsCount  AS  UnlockedRfqCount
				/**/
				/* M2-4754 */
					,b.IsRfqWithMissingInfo  
				/**/
				/* M2-4793 */
				,b.WithOrderManagement  
				/**/
			FROM 
				mp_rfq_quote_SupplierQuote	mrqsq	(nolock) 
				join mp_rfq b						(nolock) on mrqsq.rfq_id = b.rfq_id 
					and rfq_status_id in  (3 , 5, 6, 16,17 )
					and  is_rfq_resubmitted = 0
					and  mrqsq.is_quote_submitted = 1
					and mrqsq.contact_id = @SupplierID
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
				 and b.rfq_id = case when (select count(processId) from @processids2) > 0 then  q.rfq_id  else b.rfq_id end
				 /**/
				/* M2-1924 M - In the application the search needs to be inclusive - DB */
				and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
				/**/
				and b.rfq_id not in 
				(

					select distinct a.rfq_id  from mp_rfq_quote_SupplierQuote	a	(nolock) 
					join mp_rfq_quote_items (nolock)  b on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id and b.is_awrded = 1 and a.contact_id = @SupplierID
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
		--=> MyRFQ's => All Tab => Recently Viewed RFQ's (5)
		--=> MyRFQ's => Liked Tab => Recently Viewed RFQ's  (55)
		--=> MyRFQ's => DisLiked Tab => Recently Viewed RFQ's  (105) 
		else if (@RfqType  in (5,55,105))	
		begin	
			select myrfqsv.* , rfq_release.release_date as ReleaseDate, 	count(1) over () RfqCount  from 
			 (
				select 
					distinct 
					b.rfq_id as RfqId  
					, b.rfq_name as RfqName 
					, convert(varchar(100),floor(c.min_part_quantity)) as PartQty 
					, c.min_part_quantity_unit as PartQtyUnit  
					, j.value as PostProductionProcessName 
					, k.material_name_en  as PartsMaterialName  
					,  case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as PartCategoryName
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
						when @is_premium_supplier in (83,84,85,313) then 0
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
				/* M2-4653 */
				, @IsRfqUnlocked	  AS	 IsRfqUnlocked  
				, b.pref_NDA_Type     AS  NDALevel
				, @UnlockedRfqsCount  AS  UnlockedRfqCount
				/**/
				/* M2-4754 */
				,b.IsRfqWithMissingInfo  
			    /**/
				/* M2-4793 */
				,b.WithOrderManagement  
				/**/
				from
				mp_rfq_supplier		mrs				(nolock) 
				join mp_rfq b						(nolock) on mrs.rfq_id = b.rfq_id 
					and rfq_status_id = 3 
					and format(b.quotes_needed_by,'yyyyMMdd') >= format(@currentdate,'yyyyMMdd') 
				join mp_rfq_supplier_read rfq_view  (nolock) on 
					b.rfq_id = rfq_view.rfq_id 
					and rfq_view.supplier_id=@SupplierID 
					and datediff(day,rfq_view.read_date ,getutcdate()) < 31
				join mp_rfq_preferences  mrp		(nolock) on b.rfq_id = mrp.rfq_id 
				join mp_rfq_parts c					(nolock) on b.rfq_id = c.rfq_id 
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
				left join mp_company_processes	mcp	(nolock) on d.part_category_id = mcp.part_category_id and mcp.company_id = @SupplierCompID
				/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
				left join  #rfq_list q on b.rfq_id =  q.rfq_id
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
				b.rfq_id not in  (select distinct rfq_id from mp_rfq_quote_SupplierQuote (nolock) where contact_id = @SupplierID and is_rfq_resubmitted = 0 )
				and b.rfq_id not in  (select rfq_id from @blacklisted_rfqs) 
				and b.rfq_id = case when (select count(processId) from @processids2) > 0 then  q.rfq_id  else b.rfq_id end -- M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes
				and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end -- M2-1924 M - In the application the search needs to be inclusive - DB
				and c.is_rfq_part_default =  1 -- M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes
				and b.rfq_id in (select * from #filtered_rfq_list) -- Oct 14,2019 - M2-2196 M - My RFQ's page - Saved Search module - Initial State : DB
				and 
				(
					a.is_rfq_like = case when @RfqType in (5,55) then 1 when @RfqType = 105 then 0  end 
					or
					isnull(a.is_rfq_like,1) = (case when @RfqType = 5 then 1 end)
					or
					isnull(a.is_rfq_like,1) = (case when @RfqType = 5 then 0 end)
				)
			) myrfqsv
			left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on myrfqsv.RFQId = rfq_release.rfq_id
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
		--=> MyRFQ's => All Tab => RFQ's with No Quotes / Less than 3 Quotes (6,7)
		--=> MyRFQ's => Liked Tab => RFQ's with No Quotes / Less than 3 Quotes  (56,57)
		--=> MyRFQ's => DisLiked Tab => RFQ's with No Quotes / Less than 3 Quotes  (106,107) 
		else if (@RfqType in  (6,56,106,7,57,107))	
		begin	
			select 
				myrfqs.* 
				, rfq_release.release_date  as ReleaseDate
				, case 
						 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
							/* Eddie requested (Jan 21,2020), to remove territory condition and show no of quotes for all platinum users */
						--when rfq_pref_manufacturing_location_id  = 3 then 0
							/**/
						/**/
						/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
						when @is_premium_supplier in (83,84,85,313) then 0
						/**/
						else
							NoOfQuotes
				  end 
				  as NoOfQuotes
				, count(1) over () RfqCount  
			from 
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
					 -- case 
						-- /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
						--	/* Eddie requested (Jan 21,2020), to remove territory condition and show no of quotes for all platinum users */
						----when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
						--	/**/
						--/**/
						--/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
						--when @is_premium_supplier in (83,84,85) then 0
						--/**/
						--else
							(
								select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
							)
					  --end 
					  as NoOfQuotes 
					 -- ,(
						--		select count(1) from mp_rfq_quote_supplierquote (nolock) 
						--		where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
						--) as NoOfQuotes1
					/**/
					  , mrp.rfq_pref_manufacturing_location_id 
					/**/
					/* May 4, 2020 As discussed with Eddie & Beau Martin , For supplier after taking RFQ capabilities, we need to hide buyer info & restrict supplier to download part files for profile capabilities RFQ’s as we do for basic supplier. */
					,@IsSubscriptionSupplier AS IsSubscriptionSupplier
					,(CASE WHEN s.MatchedPartCount > 0 THEN CAST('true' AS BIT)	ELSE CAST('false' AS BIT) END ) As IsAllowQuoting
					/**/
				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
				/* M2-4653 */
				, @IsRfqUnlocked	  AS	 IsRfqUnlocked  
				, b.pref_NDA_Type     AS  NDALevel
				, @UnlockedRfqsCount  AS  UnlockedRfqCount
				/**/
				/* M2-4754 */
				,b.IsRfqWithMissingInfo  
				/**/
				/* M2-4793 */
				,b.WithOrderManagement  
				/**/
				from
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
				and b.rfq_id not in  (select distinct rfq_id from mp_rfq_quote_SupplierQuote (nolock) where contact_id = @SupplierID  )
				and b.rfq_id not in  (select rfq_id from @blacklisted_rfqs) 
				--and (a.is_rfq_like != 0 or a.is_rfq_like is null)
				and c.is_rfq_part_default =  1 -- M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes
				and b.rfq_id in (select * from #filtered_rfq_list) -- Oct 14,2019 - M2-2196 M - My RFQ's page - Saved Search module - Initial State : DB
				and 
				(
					a.is_rfq_like = case when @RfqType in (6,56,7,57) then 1 when @RfqType in (106,107) then 0  end 
					or
					isnull(a.is_rfq_like,1) = (case when @RfqType in (6,7) then 1 end)
					or
					isnull(a.is_rfq_like,1) = (case when @RfqType in (6,7) then 0 end)
				)
			) myrfqs
			 left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on myrfqs.RFQId = rfq_release.rfq_id
			/* M2-2044 M - My RFQs, My Liked RFQs, Followed Buyers RFQs - add filters for # of quotes - DB */
			where 
				NoOfQuotes < (case when @RfqType in (6,56,106) then 1 when @RfqType in (7,57,107) then 3 end )
				and NoOfQuotes > (case when @RfqType in (6,56,106) then -1 when @RfqType in (7,57,107) then -1 end )
			/**/
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
	/**/


	
	
	
	/* End - Oct 14,2019 - M2-2196 M - My RFQ's page - Saved Search module - Initial State : DB */
end
