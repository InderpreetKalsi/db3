

/*

declare @p8 dbo.tbltype_ListOfProcesses

exec proc_get_RfqList_Supplier 
@ContactId=1350506
,@CompanyId=1769973
,@RfqType=3
,@PageNumber=1
,@PageSize=50
,@currentdate='2021-05-14 07:16:47'
,@IsOrderByDesc=1
,@Processids=@p8


*/
CREATE PROCEDURE [dbo].[proc_get_RfqList_Supplier]
	 @ContactId INT,
	 @CompanyId INT,
	 @RfqType INT,	 
	 @PageNumber INT = 1,
	 @PageSize   INT = 10,
	 @SearchText VARCHAR(50) = Null,	
	 @Processids as tbltype_ListOfProcesses readonly,
	 @IsOrderByDesc BIT='true',
	 @OrderBy VARCHAR(100) = Null,
	 @currentdate datetime = null,
	 @SelectedSupplierId   INT = NULL 
	
AS
	/*
	 =============================================
	 Author:		dp-Am. N.
	 Create date:  31/10/2018
	 Description:	Stored procedure to Get the RFQ details based on RFQ Type for Supplier
	 Modification:
	 Syntax: [proc_get_RfqList_Supplier] <Contact_id>,<Company_id>,<RFQ_Type_id>
	 =================================================================
	 */
BEGIN
	------------------------ All Rfq --------------------
	set nocount on
	
	--DECLARE @TotalRecords INT;
	
	--declare @is_registered_supplier bit = 0 
	declare @manufacturing_location_id smallint  
	declare @company_capabilities int  = 0
	declare @sortorder varchar(10) 
	declare @blacklisted_rfqs table (rfq_id int)
	declare @sql_query_rfq_list_based_on_processes nvarchar(max)
	
	declare @processids1 as tbltype_ListOfProcesses 
	
	declare @inputdate varchar(8) 
	declare @rfqlocation int
	declare @is_premium_supplier int
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
	/*  M2-2087 Clone up to 3 RFQ's for 3 regions - API */
	drop table if exists #rfqlocation
	/**/
	/* M2-4653 -- based on current subscription */
	drop table if exists #tmpmpGrowthPackageUnlockRFQsInfo
	/**/
	
	
	create table #rfq_list (rfq_id int)
	create table #rfq_list_for_parts_search (rfq_id int)
	/*  M2-2087 Clone up to 3 RFQ's for 3 regions - API */
	create table #rfqlocation (rfq_location int)
	/**/

	/* M2-2854 M - My Company Quotes page for RFQ's - DB*/
	CREATE TABLE #tmp_mycompany_suppliers (SupplierId INT)
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

	/* M2-2854 M - My Company Quotes page for RFQ's - DB*/
	IF @SelectedSupplierId IS NULL
	BEGIN
		INSERT INTO #tmp_mycompany_suppliers (SupplierId)
		SELECT contact_id from mp_contacts where company_id = @CompanyId
	END
	ELSE
	BEGIN
		INSERT INTO #tmp_mycompany_suppliers (SupplierId) SELECT @SelectedSupplierId
	END
	/**/

	--set @is_registered_supplier = (select is_registered from mp_registered_supplier (nolock)  where company_id = @CompanyId)
	set @is_premium_supplier = isnull((select account_type from mp_registered_supplier (nolock)  where company_id = @CompanyId),83)
	set @manufacturing_location_id  = (select manufacturing_location_id from mp_companies (nolock) where company_id = @CompanyId)
	set @company_capabilities = (select count(1) from mp_company_processes  (nolock) where  company_id = @CompanyId)
	SET @IsSubscriptionSupplier =
		(
			CASE	
				WHEN (SELECT COUNT(1) FROM mp_gateway_subscription_company_processes (NOLOCK)  WHERE  company_id =  @CompanyId AND is_active = 1)> 0 THEN CAST('true' AS BIT) 
				ELSE CAST('false' AS BIT) 
			END 
		)
	

	/* M2-4653 -- based on current subscription  */             
	IF exists (SELECT  COUNT(1) from mp_registered_supplier (NOLOCK)  WHERE company_id = @CompanyId AND account_type = 84) --- this is silver supplier
	BEGIN
	     ---- below code commented with M2-5221
	     /* M2-4686 */
			 ---- Getting status and latest running id against company id
			 --SELECT  TOP 1  @SubscriptionStatus =   b.status , @RunningSubscriptionId = b.id 
				--FROM [dbo].[mp_gateway_subscription_customers] (NOLOCK) a
				--JOIN [dbo].[mp_gateway_subscriptions] (NOLOCK) b ON a.id= b.customer_id
				--WHERE a.gateway_id = 310 
				--AND a.company_id = @CompanyId
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
			AND a.company_id = @CompanyId
		)  
			SELECT  TOP 1     @SubscriptionStatus =   b.status ,   @RunningSubscriptionId = b.id 
			FROM [dbo].[mp_gateway_subscription_customers] (NOLOCK) a
			JOIN [dbo].[mp_gateway_subscriptions] (NOLOCK) b ON a.id= b.customer_id
			JOIN cte on cte.subscription_start = b.subscription_start and cte.subscription_end = b.subscription_end
			WHERE a.gateway_id = 310 
			AND a.company_id = @CompanyId
			ORDER BY b.ID DESC

		---- getting RFQ count as per company level based on current subscription start and end date renge
		--SET @UnlockedRfqsCount =
		--(
		--	SELECT COUNT(DISTINCT c.rfq_id)
		--	FROM [dbo].[mp_gateway_subscription_customers] (NOLOCK) a
		--	JOIN [dbo].[mp_gateway_subscriptions] (NOLOCK) b ON 
		--		a.id = b.customer_id 
		--		AND CAST(b.subscription_end AS DATE) >= CAST(GETUTCDATE() AS DATE)
		--		AND a.company_id = @CompanyId
		--		AND [status] = 'active'
		--	JOIN  mpGrowthPackageUnlockRFQsInfo (NOLOCK) c on c.CompanyId = a.company_id
		--	WHERE 
		--		CAST(c.UnlockDate AS DATE) >= CAST(b.subscription_start AS DATE)
		--		AND CAST(c.UnlockDate AS DATE) <= CAST(b.subscription_end AS DATE)
		--)

		IF @SubscriptionStatus = 'active'
		BEGIN
		    ---- getting RFQ count as per company level based on current subscription start and end date renge
			SET @UnlockedRfqsCount =
			(
				SELECT COUNT(DISTINCT c.rfq_id)
				FROM [dbo].[mp_gateway_subscription_customers] (NOLOCK) a
				JOIN [dbo].[mp_gateway_subscriptions] (NOLOCK) b ON 
					a.id = b.customer_id 
					--AND CAST(b.subscription_end AS DATE) >= CAST(GETUTCDATE() AS DATE)
					AND a.company_id = @CompanyId
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
		---- getting RFQ count as per company level based on current subscription start and end date renge
		SET @UnlockedRfqsCount =
			(
				SELECT COUNT(DISTINCT c.rfq_id)
				FROM [dbo].[mp_gateway_subscription_customers] (NOLOCK) a
				JOIN [dbo].[mp_gateway_subscriptions] (NOLOCK) b ON 
				a.id = b.customer_id 
				--AND CAST(b.subscription_end AS DATE) >= CAST(GETUTCDATE() AS DATE)
				AND a.company_id = @CompanyId
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
		FROM mpGrowthPackageUnlockRFQsInfo (NOLOCK) WHERE CompanyId = 		@CompanyId
		/* Slack issue : restored used RFQs -> IsDeleted = 1 */ 
					AND IsDeleted = 0
		

	END
	/**/


	/*  M2-2087 Clone up to 3 RFQ's for 3 regions - API */
	if @manufacturing_location_id = 4 
	insert into #rfqlocation values (7), (4)

	if @manufacturing_location_id = 5
		insert into #rfqlocation values (7), (5)

	if @manufacturing_location_id not in (4,5)
			insert into #rfqlocation values (@manufacturing_location_id)
	/**/
	

    insert into @blacklisted_rfqs (rfq_id)
    select distinct c.rfq_id from mp_book_details  a 
    join mp_books b on a.book_id = b.book_id 
    join mp_rfq c on b.contact_id = c.contact_id
	left join mp_rfq_quote_supplierquote f on c.rfq_id = f.rfq_id and f.contact_id = @ContactId
	left join mp_rfq_quote_items e on f.rfq_quote_SupplierQuote_id= e.rfq_quote_SupplierQuote_id
    where bk_type= 5 and a.company_id = @CompanyId and  ((f.is_quote_submitted = 0 or f.is_quote_submitted is null)and  isnull(e.is_awrded,0) = 0)
	union  -- exclude rfq's for black listed buyer which are awarded & quoted 
	select distinct c.rfq_id  from mp_book_details  a 
    join mp_books b on a.book_id = b.book_id  and b.contact_id = @ContactId
	join mp_contacts d on a.company_id =  d.company_id
	join mp_rfq c on d.contact_id = c.contact_id
	left join mp_rfq_quote_supplierquote f on c.rfq_id = f.rfq_id and f.contact_id = @ContactId
	left join mp_rfq_quote_items e on f.rfq_quote_SupplierQuote_id= e.rfq_quote_SupplierQuote_id
    where bk_type= 5 and  ((f.is_quote_submitted = 0 or f.is_quote_submitted is null)and  isnull(e.is_awrded,0) = 0)
	/* M2-3251  Vision - Flag as a test account and hide the data from reporting - DB */
	union
	select distinct b.rfq_id
	from mp_contacts	(nolock) a
	join mp_rfq		(nolock) b on a.contact_id = b.contact_id 
	where is_buyer = 1 and isnull(a.istestaccount,0) = 1 
	/**/


	if (@RfqType in (3,14,18)) and (@OrderBy is null or @OrderBy = '' )
		set @OrderBy  = 'release_date'
	else if (@RfqType in (8)) and (@OrderBy is null or @OrderBy = '' )
		set @OrderBy  = ''
	else if (@OrderBy is null or @OrderBy = '' )
		set @OrderBy  = 'quoteby'

	drop table if exists #rfq_likes

	select rfq_id ,is_rfq_like into #rfq_likes from  mp_rfq_supplier_likes a	(nolock) where contact_id = @ContactId 


	set @sql_query_rfq_list_based_on_processes=			
	'

	insert into #rfq_list (rfq_id)
	select distinct a.rfq_id 
	from mp_rfq			a (nolock) 
	join mp_rfq_parts	b (nolock)   on a.rfq_id = b.rfq_id 
	join mp_parts c (nolock) on b.part_id  = c.part_id '
	+
	case 
		when @RfqType in (3, 14,18,22) then
			'and a.rfq_status_id = 3
			and format(a.quotes_needed_by,''yyyyMMdd'') >= '''+@inputdate+''' 
			join mp_rfq_preferences  mrp (nolock) on a.rfq_id = mrp.rfq_id and mrp.rfq_pref_manufacturing_location_id in (select * from #rfqlocation)  '	
		when @RfqType in ( 5 , 15) then
			' and a.rfq_status_id = 3 '
		when @RfqType in (6,17,21) then
			' and a.rfq_status_id in  (3 , 5, 6 ) 
			join mp_rfq_quote_SupplierQuote	mrqsq	(nolock) on mrqsq.rfq_id = a.rfq_id and mrqsq.contact_id =  '+convert(varchar(50),@ContactId)
		when @RfqType in (8,16,20) then
			' and a.rfq_status_id not in (14) and a.rfq_status_id > 2 
			join mp_contacts	e (nolock) on a.contact_id = e.contact_id
			join 
				(
					select distinct mbd.company_id 
					from mp_book_details	mbd		(nolock)
					join mp_books			mb		(nolock)	on mbd.book_id =mb.book_id
					join mp_mst_book_type	mmbt	(nolock)	on mmbt.book_type_id = mb.bk_type
					and mmbt.book_type =''BOOK_BOOKTYPE_HOTLIST''
					and mb.contact_id = '+convert(varchar(50),@ContactId)+'
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
			when @company_capabilities > 0  and  @RfqType in ( 3 , 14) then 
				' join mp_company_processes a	 (nolock)  on a.part_category_id = b.part_category_id and  a.company_id = '+ convert(varchar(50),@CompanyId)
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
	) d on c.part_category_id = d.part_category_id
	'
	--select @sql_query_rfq_list_based_on_processes
	exec sp_executesql  @sql_query_rfq_list_based_on_processes ,N'@processids1  as tbltype_ListOfProcesses readonly',@processids1  = @Processids
	
	/* M2-1924 M - In the application the search needs to be inclusive - DB */
	if len(@SearchText) > 0
	begin
		insert into #rfq_list_for_parts_search (rfq_id)
		select distinct a.rfq_id 
		from mp_rfq					(nolock) a 
		join mp_rfq_parts			(nolock) b  on a.rfq_id = b.rfq_id 
		join mp_parts 				(nolock) c on b.part_id  = c.part_id
		join mp_contacts 			(nolock) m on a.contact_id = m.contact_id
		join mp_companies 			(nolock) mcom on m.company_id = mcom.company_id
		where 
			(a.rfq_name like '%'+@SearchText+'%')	
			OR	
			(a.rfq_id like '%'+@SearchText+'%')		
			OR	
			(mcom.name like '%'+@SearchText+'%')
			OR	
			((m.first_name +' '+ m.last_name) like '%'+@SearchText+'%')
			OR	
			(c.part_name like '%'+@SearchText+'%')
			OR	
			(c.part_number like '%'+@SearchText+'%')
			OR
			(@SearchText is null)	
	end
	/**/
	
	
	------------------------ My RFQ's --------------------
	if (@RfqType = 3)	
	BEGIN	
		select myrfqs.* , rfq_release.release_date, 	count(1) over () RfqCount  from 
		 (
			select 
				distinct 
				b.rfq_id as RFQId 
				, b.rfq_name as RFQName
				, floor(c.min_part_quantity) as Quantity
				, c.min_part_quantity_unit as UnitValue 
				, j.value as PostProductionProcessValue
				, k.material_name_en  as Material 
				, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as Process
				, b.contact_id as BuyerContactId 
				, b.quotes_needed_by as QuotesNeededBy
				, a.is_rfq_like IsRfqLike 
				, o.no_of_stars AS NoOfStars 
				, coalesce(p.file_name,'') as RfqThumbnail	 
				, b.special_instruction_to_manufacturer as SpecialInstructions
				, m.company_id AS BuyerCompanyId	
				, vw_address.state			AS [State]
				, vw_address.country_name	AS Country	
				,mcom.name as buyer_company_name
				, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS buyer_company_logo
				, c.rfq_part_id
				, c.is_rfq_part_default
				, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )		 rfq_parts_count
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				, 
				  case 
					 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
					--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
					/**/
					/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
					when @is_premium_supplier in (83,84,85,'',313) then 0
					/**/
					else
						(
							select count(1) from mp_rfq_quote_supplierquote (nolock) 
							where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
						)
				  end as no_of_quotes 
				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
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
			left join mp_rfq_supplier_likes a	(nolock) on a.rfq_id = b.rfq_id  and a.contact_id = @ContactId
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
					LEFT JOIN mp_gateway_subscription_company_processes  (NOLOCK) c ON b.part_category_id = c.part_category_id AND c.company_id = @CompanyId  AND c.is_active = 1
 					WHERE  
						a.rfq_id IN (select * from #rfq_list)
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
					and rfq_status_id = 3  
					/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
					and b.rfq_id = case when @company_capabilities > 0 then  q.rfq_id  else b.rfq_id end
					/**/
					/* M2-1924 M - In the application the search needs to be inclusive - DB */
					and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
					/**/
				 )
			 
			)
			and b.rfq_id not in  (select distinct rfq_id from mp_rfq_quote_SupplierQuote (nolock) where contact_id = @ContactId  )
			and b.rfq_id not in  (select rfq_id from @blacklisted_rfqs) 
			and (a.is_rfq_like != 0 or a.is_rfq_like is null)
			/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			and c.is_rfq_part_default =  1
			/**/
		) myrfqs
		 left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on myrfqs.RFQId = rfq_release.rfq_id
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   Quantity end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   Material end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   Process end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   PostProductionProcessValue end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'release_date' then   release_date end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   Quantity end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   Material end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   Process end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   PostProductionProcessValue end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'release_date' then   release_date end asc   
			
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only
		
	END	  
	------------------------ Liked Rfq --------------------
	ELSE IF (@RfqType = 4)	
	BEGIN	

		select rfqlikes.* , rfq_release.release_date, 	count(1) over () RfqCount  from 
		(
			select 
				distinct 
				b.rfq_id as RFQId 
				, b.rfq_name as RFQName
				, floor(c.min_part_quantity) as Quantity
				, c.min_part_quantity_unit as UnitValue 
				, j.value as PostProductionProcessValue
				, k.material_name_en as Material 
				, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as Process
				, b.contact_id as BuyerContactId 
				, b.quotes_needed_by as QuotesNeededBy
				, a.is_rfq_like IsRfqLike 
				, o.no_of_stars AS NoOfStars  
				, coalesce(p.file_name,'') as RfqThumbnail	 
				, b.special_instruction_to_manufacturer as SpecialInstructions
				, m.company_id AS BuyerCompanyId	
				, vw_address.state			AS [State]
				, vw_address.country_name	AS Country	
				, mcom.name as buyer_company_name
				, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS buyer_company_logo	
				, c.rfq_part_id
				, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )	as	 rfq_parts_count
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				, 
				  case 
					 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
					----when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
					/**/
					/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
					when @is_premium_supplier in (83,84,85,313) then 0
					/**/
					else
						(
							select count(1) from mp_rfq_quote_supplierquote (nolock) 
							where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
						)
				  end as no_of_quotes 
				/**/
				/* May 4, 2020 As discussed with Eddie & Beau Martin , For supplier after taking RFQ capabilities, we need to hide buyer info & restrict supplier to download part files for profile capabilities RFQ’s as we do for basic supplier. */
				,@IsSubscriptionSupplier AS IsSubscriptionSupplier
				,(CASE WHEN s.MatchedPartCount > 0 THEN CAST('true' AS BIT)	ELSE CAST('false' AS BIT) END ) As IsAllowQuoting
				/**/	
				,c.is_rfq_part_default			
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
				/* M2-4653 */
				, 
				(
					CASE 
						WHEN @is_premium_supplier = 84 THEN
							CASE	
								WHEN t1.Rfq_Id IS NOT NULL  THEN 'No Action'
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
			from mp_rfq_supplier_likes a		(nolock)
			join mp_rfq b						(nolock) on a.rfq_id = b.rfq_id and is_rfq_like = 1 and a.contact_id = @ContactId 
				--and b.rfq_id = 1153425
			join mp_rfq_preferences  mrp		(nolock) on b.rfq_id = mrp.rfq_id 
			join mp_rfq_parts c					(nolock) on a.rfq_id = c.rfq_id  
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
			left join mp_company_processes	mcp	(nolock) on d.part_category_id = mcp.part_category_id and mcp.company_id = @CompanyId
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
					LEFT JOIN mp_gateway_subscription_company_processes  (NOLOCK) c ON b.part_category_id = c.part_category_id AND c.company_id = @CompanyId  AND c.is_active = 1
 					GROUP BY a.rfq_id
				) s on a.rfq_id = s.rfq_id
			/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			left join #rfq_list t on b.rfq_id =  t.rfq_id
			/**/
			/* M2-4653 */
			left join #tmpmpGrowthPackageUnlockRFQsInfo t1 on b.rfq_id = t1.Rfq_Id
			/**/
			where 
			 /* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			 b.rfq_id = case when ((select count(processId) from @Processids))  > 0 then  t.rfq_id  else b.rfq_id end
			/**/
			 and a.rfq_id not in  (select rfq_id from @blacklisted_rfqs) 
			 --and (
				--	(c.part_category_id in (select processId from @Processids ))
				--	OR 
				--	((select count(processId) from @Processids) = 0)
				-- )
			--/* M2-1924 M - In the application the search needs to be inclusive - DB */
			and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
			and c.is_rfq_part_default =  1
			/**/
		) rfqlikes
		left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on rfqlikes.RFQId = rfq_release.rfq_id 
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   Quantity end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   Material end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   Process end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   PostProductionProcessValue end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   Quantity end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   Material end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   Process end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   PostProductionProcessValue end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only

	END	  
	----------------------- Special Invite Rfq --------------------
	ELSE IF (@RfqType = 5)	
	BEGIN

	SELECT SpecialInviteRFQ.* , rfq_release.release_date, 	count(1) over () RfqCount  FROM (
			select 
				distinct 
				b.rfq_id as RFQId 
				, b.rfq_name as RFQName
				, floor(c.min_part_quantity) as Quantity
				, c.min_part_quantity_unit as UnitValue 
				, j.value as PostProductionProcessValue
				, k.material_name_en as Material 
				, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as Process
				, b.contact_id as BuyerContactId 
				, b.quotes_needed_by as QuotesNeededBy
				, a.is_rfq_like IsRfqLike 
				, o.no_of_stars AS NoOfStars 
				, coalesce(p.file_name,'') as RfqThumbnail	 
				, b.special_instruction_to_manufacturer as SpecialInstructions
				, m.company_id AS BuyerCompanyId	
				, vw_address.state			AS [State]
				, vw_address.country_name	AS Country	
				,mcom.name as buyer_company_name
				, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS buyer_company_logo	
				, c.rfq_part_id
				, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )		 rfq_parts_count
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				, 
				  case 
					 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
					--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
					/**/
					/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
					when @is_premium_supplier in (83,84,85,313) then 0
					/**/
					else
						(
							select count(1) from mp_rfq_quote_supplierquote (nolock) 
							where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
						)
				  end as no_of_quotes 
				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
				/* M2-4653 */
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
			join mp_rfq b						(nolock) on mrs.rfq_id = b.rfq_id and rfq_status_id = 3 and mrs.company_id =@CompanyId
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
			left join mp_rfq_supplier_likes a	(nolock) on a.rfq_id = b.rfq_id  and a.contact_id = @ContactId
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
				LEFT JOIN mp_gateway_subscription_company_processes  (NOLOCK) c ON b.part_category_id = c.part_category_id AND c.company_id = @CompanyId  AND c.is_active = 1
 				WHERE  
					a.rfq_id IN (select * from #rfq_list)
				GROUP BY a.rfq_id
			) s on b.rfq_id = s.rfq_id
			/* M2-4653 */
			left join #tmpmpGrowthPackageUnlockRFQsInfo t on b.rfq_id = t.Rfq_Id
			/**/
			where 
			 b.rfq_id not in  (select rfq_id from @blacklisted_rfqs) 
			 /* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			 and b.rfq_id = case when (select count(processId) from @Processids) > 0 then  q.rfq_id  else b.rfq_id end
			 /**/
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
			/**/
			and b.rfq_id not in (select distinct rfq_id from mp_rfq_quote_SupplierQuote (nolock) where contact_id = @ContactId )
			/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			and c.is_rfq_part_default =  1
			/**/
		
		) SpecialInviteRFQ
		left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on SpecialInviteRFQ.RFQId = rfq_release.rfq_id
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   Quantity end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   Material end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   Process end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   PostProductionProcessValue end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   Quantity end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   Material end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   Process end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   PostProductionProcessValue end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc  
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only
	END	  
	------------------------ Quoted Rfq --------------------
	ELSE IF (@RfqType = 6)		 
	BEGIN	
	
		SELECT QuotedRFQ.* , rfq_release.release_date, 	count(1) over () RfqCount  FROM 
		(		 
		SELECT
			distinct 
				b.rfq_id as RFQId 
				, b.rfq_name as RFQName
				, floor(c.min_part_quantity) as Quantity
				, c.min_part_quantity_unit as UnitValue 
				, j.value as PostProductionProcessValue
				, dbo.[fn_getTranslatedValue](k.material_name, 'EN') as Material 
				, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as Process
				, b.contact_id as BuyerContactId 
				, b.quotes_needed_by as QuotesNeededBy
				, a.is_rfq_like IsRfqLike 
				, o.no_of_stars AS NoOfStars 
				, coalesce(p.file_name,'') as RfqThumbnail	 
				, b.special_instruction_to_manufacturer as SpecialInstructions
				, m.company_id AS BuyerCompanyId	
				, vw_address.state			AS [State]
				, vw_address.country_name	AS Country	
				,mcom.name as buyer_company_name
				, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS buyer_company_logo
				, c.rfq_part_id
				, mrqsq.is_reviewed AS IsReviewed
				/* M2-3318 Buyer - Change the My Quotes page to reflect Viewed and Reviewed - DB */
				, mrqsq.IsViewed	AS IsViewed
				/**/
				, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )		 rfq_parts_count
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				, 
				  case 
					 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
					--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
					/**/
					/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
					when @is_premium_supplier in (83,84,85,313) then 0
					/**/
					else
						(
							select count(1) from mp_rfq_quote_supplierquote (nolock) 
							where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
						)
				  end as no_of_quotes 
				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
				/* M2-4653 */
				,'No Action' AS ActionForGrowthPackage
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
				and rfq_status_id in  (3 , 5, 6 ,16, 17 ,18 ,20) 
				and  is_rfq_resubmitted = 0
				and  mrqsq.is_quote_submitted = 1
				and mrqsq.contact_id = @ContactId
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
			left join mp_rfq_supplier_likes a	(nolock) on a.rfq_id = b.rfq_id  and a.contact_id = @ContactId
			/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			left join #rfq_list q on b.rfq_id =  q.rfq_id
			/**/
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			left join #rfq_list_for_parts_search r on  b.rfq_id =  r.rfq_id
			/**/
			
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

				select distinct a.rfq_id  
				from mp_rfq_quote_SupplierQuote	a	(nolock) 
				join mp_rfq_quote_items (nolock)  b on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id and b.is_awrded = 1 and a.contact_id = @ContactId
				and  is_rfq_resubmitted = 0
				and b.status_id = 6
			)
			and c.is_rfq_part_default =  1
		) AS QuotedRFQ
			left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on QuotedRFQ.RFQId = rfq_release.rfq_id
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   Quantity end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   Material end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   Process end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   PostProductionProcessValue end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   Quantity end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   Material end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   Process end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   PostProductionProcessValue end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc  
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only
	END	
	------------------------ Awarded Rfq --------------------
	ELSE IF (@RfqType = 7)		 
	BEGIN
		
		select rfqawarded.* , rfq_release.release_date, 	count(1) over () RfqCount  from 
		(
			select 
				distinct 
				b.rfq_id as RFQId 
				, b.rfq_name as RFQName
				, floor(c.min_part_quantity) as Quantity
				, c.min_part_quantity_unit as UnitValue 
				, j.value as PostProductionProcessValue
				, dbo.[fn_getTranslatedValue](k.material_name, 'EN') as Material 
				, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as Process
				, b.contact_id as BuyerContactId 
				, b.quotes_needed_by as QuotesNeededBy
				, a.is_rfq_like IsRfqLike 
				, o.no_of_stars AS NoOfStars 
				, coalesce(p.file_name,'') as RfqThumbnail	 
				, b.special_instruction_to_manufacturer as SpecialInstructions
				, m.company_id AS BuyerCompanyId	
				, vw_address.state			AS [State]
				, vw_address.country_name	AS Country	
				, mcom.name as buyer_company_name
				, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS buyer_company_logo
				, c.rfq_part_id
				, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )		 rfq_parts_count
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				, 
				  case 
					 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
					--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
					/**/
					/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
					when @is_premium_supplier in (83,84,85,313) then 0
					/**/
					else
						(
							select count(1) from mp_rfq_quote_supplierquote (nolock) 
							where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
						)
				  end as no_of_quotes 
				/**/
				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
				/* M2-4653 */
				,'No Action' AS ActionForGrowthPackage
				/**/
			/* M2-4754 */
				,b.IsRfqWithMissingInfo  
			/**/
			/* M2-4793 */
				,b.WithOrderManagement  
			/**/
			from   
			mp_rfq b						
			join mp_rfq_parts c					(nolock) on b.rfq_id = c.rfq_id  and c.is_rfq_part_default =  1
			join mp_rfq_preferences  mrp		(nolock) on b.rfq_id = mrp.rfq_id 
			join mp_rfq_quote_SupplierQuote	a1	(nolock) on b.rfq_id = a1.rfq_id  and  is_rfq_resubmitted = 0
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
			left join mp_rfq_supplier_likes a	(nolock) on a.rfq_id = b.rfq_id  and a.contact_id = @ContactId
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			left join #rfq_list_for_parts_search r on  b.rfq_id =  r.rfq_id
			/**/
			where 
			b.rfq_id in 
			(
		
				select  distinct b.rfq_id from 
				mp_rfq_quote_items a		(nolock)  
				join mp_rfq_quote_SupplierQuote b  (nolock) on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id 
				and b.contact_id = @ContactId	and a.is_awrded=1	 
				/* M2-3271 Buyer - Dashboard award module changes - DB*/
				and status_id = 6
				/**/
				and is_rfq_resubmitted = 0			
			)
			 and  
			 b.rfq_id not in  (select rfq_id from @blacklisted_rfqs) 
			 and (
					(d.part_category_id in (select processId from @Processids ))
					OR 
					((select count(processId) from @Processids) = 0)
				)
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
			/**/
		
		) rfqawarded
		left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on rfqawarded.RFQId = rfq_release.rfq_id
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   Quantity end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   Material end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   Process end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   PostProductionProcessValue end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   Quantity end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   Material end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   Process end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   PostProductionProcessValue end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc  
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only
		
	END 
	------------------------ Followed Buyers Rfq --------------------
	ELSE IF (@RfqType = 8)		 
	BEGIN	
		

		select FollowedBuyersRFQ.* , rfq_release.release_date, 	count(1) over () RfqCount  from 
		(
			select 
				distinct 
				b.rfq_id as RFQId 
				, b.rfq_name as RFQName
				, floor(c.min_part_quantity) as Quantity
				, c.min_part_quantity_unit as UnitValue 
				, j.value as PostProductionProcessValue
				, k.material_name_en as Material 
				, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as Process
				, b.contact_id as BuyerContactId 
				, b.quotes_needed_by as QuotesNeededBy
				, a.is_rfq_like IsRfqLike 
				, o.no_of_stars AS NoOfStars 
				, coalesce(p.file_name,'') as RfqThumbnail	 
				, b.special_instruction_to_manufacturer as SpecialInstructions
				, m.company_id AS BuyerCompanyId	
				, vw_address.state			AS [State]
				, vw_address.country_name	AS Country	
				, mcom.name as buyer_company_name
				, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS buyer_company_logo	
				, c.rfq_part_id
				, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )		 rfq_parts_count
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				, 
				  case 
					 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
					--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
					/**/
					/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
					when @is_premium_supplier in (83,84,85,313) then 0
					/**/
					else
						(
							select count(1) from mp_rfq_quote_supplierquote (nolock) 
							where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
						)
				  end as no_of_quotes 
				/**/
				/* M2-2092 M - Add sort A-Z and Z-A to the followed Buyer RFQ's sort list -DB*/
				, followed_buyer.FollowedDate
				/**/
				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
				/* M2-4653 */
				,b.rfq_status_id , 
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
						WHEN @is_premium_supplier IN (85,86) THEN 
							CASE 
								WHEN b.rfq_status_id  =  4 AND @IsSubscriptionSupplier = 1 AND s.MatchedPartCount = 0   THEN 'Upgrade to Quote' 
								WHEN @IsSubscriptionSupplier = 1 AND s.MatchedPartCount = 0   THEN 'Upgrade to Quote' 
								ELSE 'No Action'
							END
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
				and mb.contact_id = @ContactId

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
					LEFT JOIN mp_gateway_subscription_company_processes  (NOLOCK) c ON b.part_category_id = c.part_category_id AND c.company_id = @CompanyId  AND c.is_active = 1
 					WHERE  
						a.rfq_id IN (select * from #rfq_list)
					GROUP BY a.rfq_id
				) s on b.rfq_id = s.rfq_id
				/* M2-4653 */
				left join #tmpmpGrowthPackageUnlockRFQsInfo t on b.rfq_id = t.Rfq_Id
				/**/
			where 
			 b.rfq_id not in  (select rfq_id from @blacklisted_rfqs) 
			 /* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			 and b.rfq_id = case when (select count(processId) from @Processids) > 0 then  q.rfq_id  else b.rfq_id end
			 /**/
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
			/**/
			/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			and c.is_rfq_part_default =  1
			/**/
		) FollowedBuyersRFQ
		left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on FollowedBuyersRFQ.RFQId = rfq_release.rfq_id
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   Quantity end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   Material end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   Process end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   PostProductionProcessValue end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
			/* DATA-70 Followed Buyers RFQs needs to only display past RFQs that match the suppliers manufacturing location	*/
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'buyer'then   buyer_company_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = '' then   FollowedDate  end desc 
			/**/
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   Quantity end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   Material end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   Process end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   PostProductionProcessValue end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc  
			/* DATA-70 Followed Buyers RFQs needs to only display past RFQs that match the suppliers manufacturing location	*/
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'buyer'then   buyer_company_name end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = '' then   FollowedDate end asc
			/**/
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only

	
	END	  
	------------------------ DisLiked Rfq --------------------
	else if (@RfqType = 9)	
	BEGIN	
		select rfqlikes.* 				, rfq_release.release_date, 	count(1) over () RfqCount  from 
		(
			select 
				distinct 
				b.rfq_id as RFQId 
				, b.rfq_name as RFQName
				, floor(c.min_part_quantity) as Quantity
				, c.min_part_quantity_unit as UnitValue 
				, j.value as PostProductionProcessValue
				, k.material_name_en as Material 
				, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as Process
				, b.contact_id as BuyerContactId 
				, b.quotes_needed_by as QuotesNeededBy
				, a.is_rfq_like IsRfqLike 
				, o.no_of_stars AS NoOfStars 
				, coalesce(p.file_name,'') as RfqThumbnail	 
				, b.special_instruction_to_manufacturer as SpecialInstructions
				, m.company_id AS BuyerCompanyId	
				, vw_address.state			AS [State]
				, vw_address.country_name	AS Country	
				, mcom.name as buyer_company_name
				, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS buyer_company_logo	
				, c.rfq_part_id
				, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )		 rfq_parts_count
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				, 
				  case 
					 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
					--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
					/**/
					/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
					when @is_premium_supplier in (83,84,85,313) then 0
					/**/
					else
						(
							select count(1) from mp_rfq_quote_supplierquote (nolock) 
							where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
						)
				  end as no_of_quotes 
				/**/
				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
				/* M2-4653 */
				,'No Action' AS ActionForGrowthPackage
				/**/
			/* M2-4754 */
				,b.IsRfqWithMissingInfo  
			/**/
			/* M2-4793 */
				,b.WithOrderManagement  
			/**/
			from mp_rfq_supplier_likes a		(nolock)
			join mp_rfq b						(nolock) on a.rfq_id = b.rfq_id and is_rfq_like = 0 and a.contact_id = @ContactId and rfq_status_id = 3 
			join mp_rfq_preferences  mrp		(nolock) on b.rfq_id = mrp.rfq_id 
			join mp_rfq_parts c					(nolock) on a.rfq_id = c.rfq_id  and c.is_rfq_part_default =  1
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
			left join mp_company_processes	mcp	(nolock) on d.part_category_id = mcp.part_category_id and mcp.company_id = @CompanyId
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			left join #rfq_list_for_parts_search r on  b.rfq_id =  r.rfq_id
			/**/
			
			where 
			
			 a.rfq_id not in  (select rfq_id from @blacklisted_rfqs) 
			 and (
					(d.part_category_id in (select processId from @Processids ))
					OR 
					((select count(processId) from @Processids) = 0)
				 )
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
			/**/
		) rfqlikes
		left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on rfqlikes.RFQId = rfq_release.rfq_id
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   Quantity end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   Material end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   Process end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   PostProductionProcessValue end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   Quantity end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   Material end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   Process end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   PostProductionProcessValue end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc  
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only
	END	 
	------------------------Supplier - Quots inprogress Rfq --------------------
	ELSE IF (@RfqType = 13)	--initially using id 13 and need to change in UI
	BEGIN
		
		SELECT QuotesInProgressRFQ.* 				, rfq_release.release_date, 	count(1) over () RfqCount  FROM
		(	
			select 
				distinct 
				b.rfq_id as RFQId 
				, b.rfq_name as RFQName
				, floor(c.min_part_quantity) as Quantity
				, c.min_part_quantity_unit as UnitValue 
				, j.value as PostProductionProcessValue
				, dbo.[fn_getTranslatedValue](k.material_name, 'EN') as Material 
				, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as Process
				, b.contact_id as BuyerContactId 
				, b.quotes_needed_by as QuotesNeededBy
				, a.is_rfq_like IsRfqLike 
				, o.no_of_stars AS NoOfStars  
				, coalesce(p.file_name,'') as RfqThumbnail	 
				, b.special_instruction_to_manufacturer as SpecialInstructions
				, m.company_id AS BuyerCompanyId	
				, vw_address.state			AS [State]
				, vw_address.country_name	AS Country	
				, mcom.name as buyer_company_name
				, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS buyer_company_logo
				, c.rfq_part_id
				, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )		 rfq_parts_count
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				, 
				  case 
					 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
					--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
					/**/
					/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
					when @is_premium_supplier in (83,84,85,313) then 0
					/**/
					else
						(
							select count(1) from mp_rfq_quote_supplierquote (nolock) 
							where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
						)
				  end as no_of_quotes 
				/**/
				, b.rfq_status_id AS RfqStatusId
				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
				/* M2-4653 */
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
						WHEN @is_premium_supplier IN (85,86)  THEN 'No Action'
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
			mp_rfq b						
			join mp_rfq_parts c					(nolock) on b.rfq_id = c.rfq_id   and  c.is_rfq_part_default =  1 
			/* M2-3479	RFQ is getting visible in both 'My Quotes' & 'Quote in Progress' tab on Manufacturer side, when user retracted any part of the RFQ */
			--and b.rfq_status_id in (1, 3)
			--join mp_rfq_quote_suplierstatuses		c1	(nolock) on b.rfq_id = c1.rfq_id and c1.contact_id = @ContactId and rfq_userStatus_id in (1, 2)
			--left join mp_rfq_quote_SupplierQuote	a1	(nolock) on b.rfq_id = a1.rfq_id  
			--	and  is_rfq_resubmitted = 0 
			--	and a1.contact_id = @ContactId and a1.is_quote_submitted in ( 0,1)
			join
			(
				select a.rfq_id, b.rfq_status_id , a.rfq_userStatus_id , a.IsTrash --, c.rfq_id , c.is_quote_submitted, c.is_rfq_resubmitted
				from mp_rfq_quote_suplierstatuses (nolock) a
				join mp_rfq (nolock) b on a.rfq_id = b.rfq_id 
				where a.contact_id =  @ContactId  and rfq_userStatus_id in (2) and b.rfq_status_id in (1,3,5)
				union
				select a.rfq_id, b.rfq_status_id , a.rfq_userStatus_id , a.IsTrash --, c.rfq_id , c.is_quote_submitted, c.is_rfq_resubmitted
				from mp_rfq_quote_suplierstatuses (nolock) a
				join mp_rfq (nolock) b on a.rfq_id = b.rfq_id
				join mp_rfq_quote_SupplierQuote (nolock) c on a.rfq_id = c.rfq_id and a.contact_id = c.contact_id and c.is_quote_submitted in (0) and c.is_rfq_resubmitted = 0
				where a.contact_id =  @ContactId  and rfq_userStatus_id in (1) and b.rfq_status_id in (1,3,5)
				union
				select a.rfq_id, b.rfq_status_id , a.rfq_userStatus_id , a.IsTrash --, c.rfq_id , c.is_quote_submitted, c.is_rfq_resubmitted
				from mp_rfq_quote_suplierstatuses (nolock) a
				join mp_rfq (nolock) b on a.rfq_id = b.rfq_id
				join mp_rfq_quote_SupplierQuote (nolock) c on a.rfq_id = c.rfq_id and a.contact_id = c.contact_id and c.is_quote_submitted in (1) and c.is_rfq_resubmitted = 0
				where a.contact_id =  @ContactId  and rfq_userStatus_id in (1) and b.rfq_status_id in (1)
				union
				select a.rfq_id, b.rfq_status_id , a.rfq_userStatus_id , a.IsTrash --, c.rfq_id , c.is_quote_submitted, c.is_rfq_resubmitted
				from mp_rfq_quote_suplierstatuses (nolock) a
				join mp_rfq (nolock) b on a.rfq_id = b.rfq_id
				join mp_rfq_quote_SupplierQuote (nolock) c on a.rfq_id = c.rfq_id and a.contact_id = c.contact_id and c.is_quote_submitted in (1) and c.is_rfq_resubmitted = 1
				where a.contact_id =  @ContactId  and rfq_userStatus_id in (1) and b.rfq_status_id in (1)
			) c1 on b.rfq_id = c1.rfq_id and ISNULL(c1.IsTrash,0) = 0
			/**/
			join mp_rfq_preferences  mrp		(nolock) on b.rfq_id = mrp.rfq_id 	
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
			left join mp_rfq_supplier_likes a	(nolock) on a.rfq_id = b.rfq_id  and a.contact_id = @ContactId
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			left join #rfq_list_for_parts_search r on  b.rfq_id =  r.rfq_id
			/**/
			/* M2-4653 */
			left join 
				(
					SELECT 
						a.rfq_id,
						COUNT(c.part_category_id) MatchedPartCount
					FROM mp_rfq					(NOLOCK) a
					LEFT JOIN mp_rfq_parts		(NOLOCK) b ON a.rfq_id = b.rfq_id AND b.status_id  = 2
					LEFT JOIN mp_gateway_subscription_company_processes  (NOLOCK) c ON b.part_category_id = c.part_category_id AND c.company_id = @CompanyId  AND c.is_active = 1
 					WHERE  
						a.rfq_id IN (select * from #rfq_list)
					GROUP BY a.rfq_id
				) s on b.rfq_id = s.rfq_id
				
				left join #tmpmpGrowthPackageUnlockRFQsInfo t on b.rfq_id = t.Rfq_Id
				/**/
			where 
			/* M2-3479	RFQ is getting visible in both 'My Quotes' & 'Quote in Progress' tab on Manufacturer side, when user retracted any part of the RFQ */
			--(a1.rfq_id is not null or c1.rfq_userStatus_id in ( 2))  
			-- and
			/**/
			  b.rfq_id not in  (select rfq_id from @blacklisted_rfqs) 
			 and (
					(d.part_category_id in (select processId from @Processids ))
					OR 
					((select count(processId) from @Processids) = 0)
				)
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
			/**/
		
		) AS QuotesInProgressRFQ
		left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on QuotesInProgressRFQ.RFQId = rfq_release.rfq_id
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   Quantity end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   Material end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   Process end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   PostProductionProcessValue end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   Quantity end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   Material end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   Process end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   PostProductionProcessValue end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc  
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only
	END	 
	------------------------All Liked Rfq --------------------
    else if (@RfqType = 14)	
    BEGIN	
		select myrfqs.* , rfq_release.release_date, 	count(1) over () RfqCount  from 
		 (
			select 
				distinct 
				b.rfq_id as RFQId 
				, b.rfq_name as RFQName
				, floor(c.min_part_quantity) as Quantity
				, c.min_part_quantity_unit as UnitValue 
				, j.value as PostProductionProcessValue
				, k.material_name_en  as Material 
				, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as Process
				, b.contact_id as BuyerContactId 
				, b.quotes_needed_by as QuotesNeededBy
				, a.is_rfq_like IsRfqLike 
				, o.no_of_stars AS NoOfStars  
				, coalesce(p.file_name,'') as RfqThumbnail	 
				, b.special_instruction_to_manufacturer as SpecialInstructions
				, m.company_id AS BuyerCompanyId	
				, vw_address.state			AS [State]
				, vw_address.country_name	AS Country	
				,mcom.name as buyer_company_name
				, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS buyer_company_logo
				, c.rfq_part_id
				, c.is_rfq_part_default
				, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )		 rfq_parts_count
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				, 
				  case 
					 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
					--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
					/**/
					/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
					when @is_premium_supplier in (83,84,85,313) then 0
					/**/
					else
						(
							select count(1) from mp_rfq_quote_supplierquote (nolock) 
							where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
						)
				  end as no_of_quotes 
				/**/
				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
				/* M2-4653 */
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
			left join mp_rfq_supplier_likes a	(nolock) on a.rfq_id = b.rfq_id  and a.contact_id = @ContactId
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
					LEFT JOIN mp_gateway_subscription_company_processes  (NOLOCK) c ON b.part_category_id = c.part_category_id AND c.company_id = @CompanyId  AND c.is_active = 1
 					WHERE  
						a.rfq_id IN (select * from #rfq_list)
					GROUP BY a.rfq_id
				) s on b.rfq_id = s.rfq_id
				/* M2-4653 */
				left join #tmpmpGrowthPackageUnlockRFQsInfo t on b.rfq_id = t.Rfq_Id
				/**/
			where 
			 ( 
				 (
					mrs.company_id = -1 
					and mrp.rfq_pref_manufacturing_location_id  in 
					/*  M2-2087 Clone up to 3 RFQ's for 3 regions - API */
					(select * from #rfqlocation)
					/**/
					and rfq_status_id = 3  
					/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
					and b.rfq_id = case when @company_capabilities > 0 then  q.rfq_id  else b.rfq_id end
					/**/
				 )
			 
			 )
			 and b.rfq_id not in  (select distinct rfq_id from mp_rfq_quote_SupplierQuote (nolock) where contact_id = @ContactId  )
			 and b.rfq_id not in  (select rfq_id from @blacklisted_rfqs) 

			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
			/**/
			and (a.is_rfq_like != 0 or a.is_rfq_like is null)
			/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			and c.is_rfq_part_default =  1
			/**/
		)  myrfqs
		left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on myrfqs.RFQId = rfq_release.rfq_id
		where myrfqs.RFQId in  (select distinct rfq_id from  mp_rfq_supplier_likes a	(nolock) where a.contact_id = @ContactId  and is_rfq_like = 1 )
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   Quantity end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   Material end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   Process end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   PostProductionProcessValue end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'release_date' then   release_date end desc    
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   Quantity end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   Material end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   Process end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   PostProductionProcessValue end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'release_date' then   release_date end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only
	
	END	  
	------------------------Special Invite Liked Rfq --------------------
	else if (@RfqType = 15)	
	BEGIN

	SELECT SpecialInviteRFQ.* , rfq_release.release_date , 	count(1) over () RfqCount  FROM (
			select 
				distinct 
				b.rfq_id as RFQId 
				, b.rfq_name as RFQName
				, floor(c.min_part_quantity) as Quantity
				, c.min_part_quantity_unit as UnitValue 
				, j.value as PostProductionProcessValue
				, k.material_name_en as Material 
				, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as Process
				, b.contact_id as BuyerContactId 
				, b.quotes_needed_by as QuotesNeededBy
				, a.is_rfq_like IsRfqLike 
				, o.no_of_stars AS NoOfStars 
				, coalesce(p.file_name,'') as RfqThumbnail	 
				, b.special_instruction_to_manufacturer as SpecialInstructions
				, m.company_id AS BuyerCompanyId	
				, vw_address.state			AS [State]
				, vw_address.country_name	AS Country	
				,mcom.name as buyer_company_name
				, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS buyer_company_logo	
				, c.rfq_part_id
				, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )		 rfq_parts_count
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				, 
				  case 
					 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
					--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
					/**/
					/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
					when @is_premium_supplier in (83,84,85,313) then 0
					/**/
					else
						(
							select count(1) from mp_rfq_quote_supplierquote (nolock) 
							where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
						)
				  end as no_of_quotes 
				/**/
				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
				/* M2-4653 */
				,'No Action' AS ActionForGrowthPackage
				/**/
			/* M2-4754 */
				,b.IsRfqWithMissingInfo  
			/**/
			/* M2-4793 */
				,b.WithOrderManagement  
			/**/
			from
			mp_rfq_supplier		mrs				(nolock) 
			join mp_rfq b						(nolock) on mrs.rfq_id = b.rfq_id and rfq_status_id = 3 and mrs.company_id =@CompanyId
			join mp_rfq_preferences  mrp		(nolock) on b.rfq_id = mrp.rfq_id 
			join mp_rfq_parts c					(nolock) on b.rfq_id = c.rfq_id   -- and c.is_rfq_part_default =  1
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
			left join mp_rfq_supplier_likes a	(nolock) on a.rfq_id = b.rfq_id  and a.contact_id = @ContactId
			/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			left join #rfq_list q on b.rfq_id =  q.rfq_id
			/**/
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			left join #rfq_list_for_parts_search r on  b.rfq_id =  r.rfq_id
			/**/
			where 
			 b.rfq_id not in  (select rfq_id from @blacklisted_rfqs) 
			 /* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			 and b.rfq_id = case when (select count(processId) from @Processids) > 0 then  q.rfq_id  else b.rfq_id end
			 /**/
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
			/**/
			 /* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			 and c.is_rfq_part_default =  1
			 /**/
		
		) SpecialInviteRFQ
		left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on SpecialInviteRFQ.RFQId = rfq_release.rfq_id
		where SpecialInviteRFQ.RFQId in  (select distinct rfq_id from  mp_rfq_supplier_likes a	(nolock) where a.contact_id = @ContactId  and is_rfq_like = 1 )
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   Quantity end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   Material end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   Process end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   PostProductionProcessValue end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   Quantity end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   Material end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   Process end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   PostProductionProcessValue end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc  
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only
	END	 
	------------------------Followed Buyers Liked Rfq --------------------
	else if (@RfqType = 16)	
	BEGIN	


	SELECT * FROM MP_MST_RFQ_BUYERSTATUS
		select FollowedBuyersRFQ.* , rfq_release.release_date, 	count(1) over () RfqCount  from 
		(
			select 
				distinct 
				b.rfq_id as RFQId 
				, b.rfq_name as RFQName
				, floor(c.min_part_quantity) as Quantity
				, c.min_part_quantity_unit as UnitValue 
				, j.value as PostProductionProcessValue
				, k.material_name_en as Material 
				, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as Process
				, b.contact_id as BuyerContactId 
				, b.quotes_needed_by as QuotesNeededBy
				, a.is_rfq_like IsRfqLike 
				, o.no_of_stars AS NoOfStars 
				, coalesce(p.file_name,'') as RfqThumbnail	 
				, b.special_instruction_to_manufacturer as SpecialInstructions
				, m.company_id AS BuyerCompanyId	
				, vw_address.state			AS [State]
				, vw_address.country_name	AS Country	
				,mcom.name as buyer_company_name
				, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS buyer_company_logo	
				, c.rfq_part_id
				, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )		 rfq_parts_count
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				, 
				  case 
					 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
					--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
					/**/
					/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
					when @is_premium_supplier in (83,84,85,313) then 0
					/**/
					else
						(
							select count(1) from mp_rfq_quote_supplierquote (nolock) 
							where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
						)
				  end as no_of_quotes 
				/**/
				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
				/* M2-4653 */
				,'No Action' AS ActionForGrowthPackage
				/**/
				/* M2-4754 */
					,b.IsRfqWithMissingInfo  
				/**/
				/* M2-4793 */
				,b.WithOrderManagement  
			/**/
			from 
			mp_rfq b							(nolock) 
			join mp_rfq_parts c					(nolock) on b.rfq_id = c.rfq_id  
				and rfq_status_id > 2 
				and rfq_status_id not in (14)
			join mp_rfq_preferences  mrp		(nolock) on b.rfq_id = mrp.rfq_id 
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
			join 
			(
				select distinct mbd.company_id from 
				mp_book_details mbd			(nolock)
				JOIN mp_books  mb			(nolock)	on mbd.book_id =mb.book_id
				JOIN mp_mst_book_type mmbt	(nolock)	on mmbt.book_type_id = mb.bk_type
				and mmbt.book_type ='BOOK_BOOKTYPE_HOTLIST'
				and mb.contact_id = @ContactId

			) followed_buyer on followed_buyer.company_id = mcom.company_id 
			 
			left join mp_special_files p		(nolock) on p.file_id = b.file_id
			left join vw_address				(nolock) on m.address_id = vw_address.address_id
			left join mp_company_processes	mcp	(nolock) on d.part_category_id = mcp.part_category_id and mcp.company_id = @CompanyId
			left join mp_rfq_supplier_likes a	(nolock) on a.rfq_id = b.rfq_id  and a.contact_id = @ContactId
			/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			left join #rfq_list q on b.rfq_id =  q.rfq_id
			/**/
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			left join #rfq_list_for_parts_search r on  b.rfq_id =  r.rfq_id
			/**/
			where 
			
			 b.rfq_id not in  (select rfq_id from @blacklisted_rfqs) 
			 /* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			 and b.rfq_id = case when (select count(processId) from @Processids) > 0 then  q.rfq_id  else b.rfq_id end
			 /**/
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
			/**/
			 /* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			 and c.is_rfq_part_default =  1 
			 /**/
		) FollowedBuyersRFQ
		left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on FollowedBuyersRFQ.RFQId = rfq_release.rfq_id
		where FollowedBuyersRFQ.RFQId in  (select distinct rfq_id from  mp_rfq_supplier_likes a	(nolock) where a.contact_id = @ContactId  and is_rfq_like = 1 )
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   Quantity end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   Material end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   Process end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   PostProductionProcessValue end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   Quantity end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   Material end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   Process end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   PostProductionProcessValue end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc  
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only
		
	END	  
	------------------------Quoted Liked Rfq --------------------
	else if (@RfqType = 17)	
	BEGIN	
		SELECT QuotedRFQ.* , rfq_release.release_date, 	count(1) over () RfqCount  FROM (		 
		SELECT
			distinct 
				b.rfq_id as RFQId 
				, b.rfq_name as RFQName
				, floor(c.min_part_quantity) as Quantity
				, c.min_part_quantity_unit as UnitValue 
				, j.value as PostProductionProcessValue
				, dbo.[fn_getTranslatedValue](k.material_name, 'EN') as Material 
				, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as Process
				, b.contact_id as BuyerContactId 
				, b.quotes_needed_by as QuotesNeededBy
				, a.is_rfq_like IsRfqLike 
				, o.no_of_stars AS NoOfStars 
				, coalesce(p.file_name,'') as RfqThumbnail	 
				, b.special_instruction_to_manufacturer as SpecialInstructions
				, m.company_id AS BuyerCompanyId	
				, vw_address.state			AS [State]
				, vw_address.country_name	AS Country	
				,mcom.name as buyer_company_name
				, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS buyer_company_logo
				, c.rfq_part_id
				, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )		 rfq_parts_count
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				, 
				  case 
					 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
					--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
					/**/
					/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
					when @is_premium_supplier in (83,84,85,313) then 0
					/**/
					else
						(
							select count(1) from mp_rfq_quote_supplierquote (nolock) 
							where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
						)
				  end as no_of_quotes 
				/**/
				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
				/* M2-4653 */
				,'No Action' AS ActionForGrowthPackage
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
				and rfq_status_id in  (3 , 5, 6 )
				and  is_rfq_resubmitted = 0
				and  mrqsq.is_quote_submitted = 1
				and mrqsq.contact_id = @ContactId
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
			left join mp_rfq_supplier_likes a	(nolock) on a.rfq_id = b.rfq_id  and a.contact_id = @ContactId
			left join mp_company_processes	mcp	(nolock) on d.part_category_id = mcp.part_category_id and mcp.company_id = @CompanyId
			/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			left join #rfq_list q on b.rfq_id =  q.rfq_id
			/**/
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			left join #rfq_list_for_parts_search r on  b.rfq_id =  r.rfq_id
			/**/
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
				join mp_rfq_quote_items (nolock)  b on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id and b.is_awrded = 1 and a.contact_id = @ContactId
				and  is_rfq_resubmitted = 0

			)
			/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			and c.is_rfq_part_default =  1
			/**/
		) AS QuotedRFQ
			left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on QuotedRFQ.RFQId = rfq_release.rfq_id
		where QuotedRFQ.RFQId in  (select distinct rfq_id from  mp_rfq_supplier_likes a	(nolock) where a.contact_id = @ContactId  and is_rfq_like = 1 )
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   Quantity end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   Material end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   Process end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   PostProductionProcessValue end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   Quantity end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   Material end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   Process end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   PostProductionProcessValue end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc  
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only
	END	
	------------------------All DisLiked Rfq --------------------
    else if (@RfqType = 18)	
    BEGIN	
		select myrfqs.* , rfq_release.release_date, 	count(1) over () RfqCount  from 
		 (
			select 
				distinct 
				b.rfq_id as RFQId 
				, b.rfq_name as RFQName
				, floor(c.min_part_quantity) as Quantity
				, c.min_part_quantity_unit as UnitValue 
				, j.value as PostProductionProcessValue
				, k.material_name_en  as Material 
				, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as Process
				, b.contact_id as BuyerContactId 
				, b.quotes_needed_by as QuotesNeededBy
				, a.is_rfq_like IsRfqLike 
				, o.no_of_stars AS NoOfStars 
				, coalesce(p.file_name,'') as RfqThumbnail	 
				, b.special_instruction_to_manufacturer as SpecialInstructions
				, m.company_id AS BuyerCompanyId	
				, vw_address.state			AS [State]
				, vw_address.country_name	AS Country	
				,mcom.name as buyer_company_name
				, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS buyer_company_logo
				, c.rfq_part_id
				, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )		 rfq_parts_count
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				, 
				  case 
					 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
					--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
					/**/
					/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
					when @is_premium_supplier in (83,84,85,313) then 0
					/**/
					else
						(
							select count(1) from mp_rfq_quote_supplierquote (nolock) 
							where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
						)
				  end as no_of_quotes 
				/**/
				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
				/* M2-4653 */
				,'No Action' AS ActionForGrowthPackage
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
			left join mp_rfq_supplier_likes a	(nolock) on a.rfq_id = b.rfq_id  and a.contact_id = @ContactId
			left join mp_company_processes	mcp	(nolock) on d.part_category_id = mcp.part_category_id and mcp.company_id = @CompanyId
			/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			left join #rfq_list q on b.rfq_id =  q.rfq_id
			/**/
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			left join #rfq_list_for_parts_search r on  b.rfq_id =  r.rfq_id
			/**/
			where 
			 ( 
				 (
					mrs.company_id =  -1  
					and mrp.rfq_pref_manufacturing_location_id  in 
					/*  M2-2087 Clone up to 3 RFQ's for 3 regions - API */
					(select * from #rfqlocation)
					/**/
					and rfq_status_id = 3  
					--and d.part_category_id = case when @company_capabilities > 0 then  mcp.part_category_id  else d.part_category_id end
				 )
 
			 )
			 and b.rfq_id not in  (select distinct rfq_id from mp_rfq_quote_SupplierQuote (nolock) where contact_id = @ContactId and is_rfq_resubmitted = 0 )
			 and b.rfq_id not in  (select rfq_id from @blacklisted_rfqs) 
			 /* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			 and b.rfq_id = case when (select count(processId) from @Processids) > 0 then  q.rfq_id  else b.rfq_id end
			 /**/
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
			/**/
 			 /* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			 and c.is_rfq_part_default =  1
			 /**/		
		) myrfqs
		left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on myrfqs.RFQId = rfq_release.rfq_id
		where myrfqs.RFQId in  (select distinct rfq_id from  mp_rfq_supplier_likes a	(nolock) where a.contact_id = @ContactId and is_rfq_like = 0 )
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   Quantity end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   Material end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   Process end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   PostProductionProcessValue end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'release_date' then   release_date end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   Quantity end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   Material end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   Process end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   PostProductionProcessValue end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'release_date' then   release_date end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only
		
	END	  
	------------------------Special Invite DisLiked Rfq --------------------
	else if (@RfqType = 19)	
	BEGIN

	SELECT SpecialInviteRFQ.* , rfq_release.release_date, 	count(1) over () RfqCount  FROM (
			select 
				distinct 
				b.rfq_id as RFQId 
				, b.rfq_name as RFQName
				, floor(c.min_part_quantity) as Quantity
				, c.min_part_quantity_unit as UnitValue 
				, j.value as PostProductionProcessValue
				, k.material_name_en as Material 
				, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as Process
				, b.contact_id as BuyerContactId 
				, b.quotes_needed_by as QuotesNeededBy
				, a.is_rfq_like IsRfqLike 
				, o.no_of_stars AS NoOfStars 
				, coalesce(p.file_name,'') as RfqThumbnail	 
				, b.special_instruction_to_manufacturer as SpecialInstructions
				, m.company_id AS BuyerCompanyId	
				, vw_address.state			AS [State]
				, vw_address.country_name	AS Country	
				,mcom.name as buyer_company_name
				, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS buyer_company_logo	
				, c.rfq_part_id
				, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )		 rfq_parts_count
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				, 
				  case 
					 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
					--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
					/**/
					/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
					when @is_premium_supplier in (83,84,85,313) then 0
					/**/
					else
						(
							select count(1) from mp_rfq_quote_supplierquote (nolock) 
							where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
						)
				  end as no_of_quotes 
				/**/
				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
				/* M2-4653 */
				,'No Action' AS ActionForGrowthPackage
				/**/
				/* M2-4754 */
				,b.IsRfqWithMissingInfo  
			    /**/
				/* M2-4793 */
				,b.WithOrderManagement  
			/**/
			from
			mp_rfq_supplier		mrs				(nolock) 
			join mp_rfq b						(nolock) on mrs.rfq_id = b.rfq_id and rfq_status_id = 3 and mrs.company_id =@CompanyId
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
			left join mp_rfq_supplier_likes a	(nolock) on a.rfq_id = b.rfq_id  and a.contact_id = @ContactId
			/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			left join #rfq_list q on b.rfq_id =  q.rfq_id
			/**/
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			left join #rfq_list_for_parts_search r on  b.rfq_id =  r.rfq_id
			/**/
			where 
			 b.rfq_id not in  (select rfq_id from @blacklisted_rfqs) 
			 /* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			 and b.rfq_id = case when (select count(processId) from @Processids) > 0 then  q.rfq_id  else b.rfq_id end
			 /**/
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
			/**/
 			 /* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			 and c.is_rfq_part_default =  1
			 /**/
		) SpecialInviteRFQ
		left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on SpecialInviteRFQ.RFQId = rfq_release.rfq_id
		where SpecialInviteRFQ.RFQId in  (select distinct rfq_id from  mp_rfq_supplier_likes a	(nolock) where a.contact_id = @ContactId  and is_rfq_like = 0 )
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   Quantity end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   Material end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   Process end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   PostProductionProcessValue end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   Quantity end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   Material end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   Process end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   PostProductionProcessValue end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc  
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only
	END	 
	------------------------Followed Buyers DisLiked Rfq --------------------
	else if (@RfqType = 20)	
	BEGIN	
		select FollowedBuyersRFQ.* , rfq_release.release_date, 	count(1) over () RfqCount  from 
		(
			select 
				distinct 
				b.rfq_id as RFQId 
				, b.rfq_name as RFQName
				, floor(c.min_part_quantity) as Quantity
				, c.min_part_quantity_unit as UnitValue 
				, j.value as PostProductionProcessValue
				, k.material_name_en as Material 
				, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as Process
				, b.contact_id as BuyerContactId 
				, b.quotes_needed_by as QuotesNeededBy
				, a.is_rfq_like IsRfqLike 
				, o.no_of_stars AS NoOfStars 
				, coalesce(p.file_name,'') as RfqThumbnail	 
				, b.special_instruction_to_manufacturer as SpecialInstructions
				, m.company_id AS BuyerCompanyId	
				, vw_address.state			AS [State]
				, vw_address.country_name	AS Country	
				,mcom.name as buyer_company_name
				, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS buyer_company_logo	
				, c.rfq_part_id
				, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )		 rfq_parts_count
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				, 
				  case 
					 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
					--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
					/**/
					/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
					when @is_premium_supplier in (83,84,85,313) then 0
					/**/
					else
						(
							select count(1) from mp_rfq_quote_supplierquote (nolock) 
							where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
						)
				  end as no_of_quotes 
				/**/
				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
				/* M2-4653 */
				,'No Action' AS ActionForGrowthPackage
				/**/
			   /* M2-4754 */
				,b.IsRfqWithMissingInfo  
			   /**/
			   /* M2-4793 */
				,b.WithOrderManagement  
			/**/
			from 
			mp_rfq b							(nolock) 
			join mp_rfq_parts c					(nolock) on b.rfq_id = c.rfq_id  and rfq_status_id > 2 and rfq_status_id not in (14)
			join mp_parts d						(nolock) on c.part_id = d.part_id
			join mp_rfq_preferences  mrp		(nolock) on b.rfq_id = mrp.rfq_id 
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
			join 
			(
				select distinct mbd.company_id from 
				mp_book_details mbd			(nolock)
				JOIN mp_books  mb			(nolock)	on mbd.book_id =mb.book_id
				JOIN mp_mst_book_type mmbt	(nolock)	on mmbt.book_type_id = mb.bk_type
				and mmbt.book_type ='BOOK_BOOKTYPE_HOTLIST'
				and mb.contact_id = @ContactId

			) followed_buyer on followed_buyer.company_id = mcom.company_id 
			 
			left join mp_special_files p		(nolock) on p.file_id = b.file_id
			left join vw_address				(nolock) on m.address_id = vw_address.address_id
			left join mp_company_processes	mcp	(nolock) on d.part_category_id = mcp.part_category_id and mcp.company_id = @CompanyId
			left join mp_rfq_supplier_likes a	(nolock) on a.rfq_id = b.rfq_id  and a.contact_id = @ContactId
			/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			left join #rfq_list q on b.rfq_id =  q.rfq_id
			/**/
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			left join #rfq_list_for_parts_search r on  b.rfq_id =  r.rfq_id
			/**/
			where 
			 b.rfq_id not in  (select rfq_id from @blacklisted_rfqs) 
			 /* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			 and b.rfq_id = case when (select count(processId) from @Processids) > 0 then  q.rfq_id  else b.rfq_id end
			 /**/
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
			/**/
			 /* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			 and c.is_rfq_part_default =  1 
			 /**/
		) FollowedBuyersRFQ
		left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on FollowedBuyersRFQ.RFQId = rfq_release.rfq_id
		where FollowedBuyersRFQ.RFQId in  (select distinct rfq_id from  mp_rfq_supplier_likes a	(nolock) where a.contact_id = @ContactId  and is_rfq_like = 0 )
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   Quantity end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   Material end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   Process end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   PostProductionProcessValue end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   Quantity end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   Material end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   Process end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   PostProductionProcessValue end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc  
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only		
	END	  
	------------------------Quoted DisLiked Rfq --------------------
	else if (@RfqType = 21)	
	BEGIN	
		SELECT QuotedRFQ.* , rfq_release.release_date, 	count(1) over () RfqCount  FROM (		 
		SELECT
			distinct 
				b.rfq_id as RFQId 
				, b.rfq_name as RFQName
				, floor(c.min_part_quantity) as Quantity
				, c.min_part_quantity_unit as UnitValue 
				, j.value as PostProductionProcessValue
				, dbo.[fn_getTranslatedValue](k.material_name, 'EN') as Material 
				, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as Process
				, b.contact_id as BuyerContactId 
				, b.quotes_needed_by as QuotesNeededBy
				, a.is_rfq_like IsRfqLike 
				, o.no_of_stars AS NoOfStars 
				, coalesce(p.file_name,'') as RfqThumbnail	 
				, b.special_instruction_to_manufacturer as SpecialInstructions
				, m.company_id AS BuyerCompanyId	
				, vw_address.state			AS [State]
				, vw_address.country_name	AS Country	
				,mcom.name as buyer_company_name
				, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS buyer_company_logo
				, c.rfq_part_id
				, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )		 rfq_parts_count
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				, 
				  case 
					 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
					--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
					/**/
					/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
					when @is_premium_supplier in (83,84,85,313) then 0
					/**/
					else
						(
							select count(1) from mp_rfq_quote_supplierquote (nolock) 
							where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
						)
				  end as no_of_quotes 
				/**/
				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
				/* M2-4653 */
				,'No Action' AS ActionForGrowthPackage
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
				and rfq_status_id in  (3 , 5, 6 )
				and  is_rfq_resubmitted = 0
				and  mrqsq.is_quote_submitted = 1
				and mrqsq.contact_id = @ContactId
			join mp_rfq_parts c					(nolock) on b.rfq_id = c.rfq_id and c.is_rfq_part_default =  1
			join mp_rfq_preferences  mrp		(nolock) on b.rfq_id = mrp.rfq_id 
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
			left join mp_rfq_supplier_likes a	(nolock) on a.rfq_id = b.rfq_id  and a.contact_id = @ContactId
			left join mp_company_processes	mcp	(nolock) on d.part_category_id = mcp.part_category_id and mcp.company_id = @CompanyId
			/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			left join #rfq_list q on b.rfq_id =  q.rfq_id
			/**/
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			left join #rfq_list_for_parts_search r on  b.rfq_id =  r.rfq_id
			/**/
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
				join mp_rfq_quote_items (nolock)  b on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id and b.is_awrded = 1 and a.contact_id = @ContactId
				and  is_rfq_resubmitted = 0

			)
			 /* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			 and c.is_rfq_part_default =  1 
			 /**/
		) AS QuotedRFQ
			left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on QuotedRFQ.RFQId = rfq_release.rfq_id
		where QuotedRFQ.RFQId in  (select distinct rfq_id from  mp_rfq_supplier_likes a	(nolock) where a.contact_id = @ContactId  and is_rfq_like = 0 )
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   Quantity end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   Material end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   Process end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   PostProductionProcessValue end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   Quantity end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   Material end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   Process end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   PostProductionProcessValue end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc   
			
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only
	END	
	------------------------My RFQ's recently viewed --------------------
	else if (@RfqType = 22)	
	BEGIN	
		select myrfqsv.* , rfq_release.release_date, 	count(1) over () RfqCount  from 
		 (
			select 
				distinct 
				b.rfq_id as RFQId 
				, b.rfq_name as RFQName
				, floor(c.min_part_quantity) as Quantity
				, c.min_part_quantity_unit as UnitValue 
				, j.value as PostProductionProcessValue
				, k.material_name_en  as Material 
				, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as Process
				, b.contact_id as BuyerContactId 
				, b.quotes_needed_by as QuotesNeededBy
				, a.is_rfq_like IsRfqLike 
				, o.no_of_stars AS NoOfStars 
				, coalesce(p.file_name,'') as RfqThumbnail	 
				, b.special_instruction_to_manufacturer as SpecialInstructions
				, m.company_id AS BuyerCompanyId	
				, vw_address.state			AS [State]
				, vw_address.country_name	AS Country	
				,mcom.name as buyer_company_name
				, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS buyer_company_logo
				, c.rfq_part_id
				, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )		 rfq_parts_count
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				, 
				  case 
					 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
					--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
					/**/
					/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
					when @is_premium_supplier in (83,84,85,313) then 0
					/**/
					else
						(
							select count(1) from mp_rfq_quote_supplierquote (nolock) 
							where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
						)
				  end as no_of_quotes 
				/**/
				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
				/* M2-4653 */
				,'No Action' AS ActionForGrowthPackage
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
			join mp_rfq_supplier_read rfq_view  (nolock) on  b.rfq_id = rfq_view.rfq_id and rfq_view.supplier_id=@ContactId
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
			left join mp_rfq_supplier_likes a	(nolock) on a.rfq_id = b.rfq_id  and a.contact_id = @ContactId
			left join mp_company_processes	mcp	(nolock) on d.part_category_id = mcp.part_category_id and mcp.company_id = @CompanyId
			/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			left join  #rfq_list q on b.rfq_id =  q.rfq_id
			/**/
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			left join #rfq_list_for_parts_search r on  b.rfq_id =  r.rfq_id
			/**/
			where 
			 b.rfq_id not in  (select distinct rfq_id from mp_rfq_quote_SupplierQuote (nolock) where contact_id = @ContactId and is_rfq_resubmitted = 0 )
			 and b.rfq_id not in  (select rfq_id from @blacklisted_rfqs) 
			 /* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			 and b.rfq_id = case when (select count(processId) from @Processids) > 0 then  q.rfq_id  else b.rfq_id end
			 /**/
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
			/**/
			/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			and c.is_rfq_part_default =  1
			/**/
		
		) myrfqsv
		left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on myrfqsv.RFQId = rfq_release.rfq_id
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   Quantity end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   Material end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   Process end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   PostProductionProcessValue end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   Quantity end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   Material end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   Process end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   PostProductionProcessValue end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc   
			
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only


	END
	------------------------Quoted Shop IQ NEED to Change Logic--------------------
	else if (@RfqType = 23)	
	BEGIN	
		
		SELECT QuotedShopIQRFQ.* , rfq_release.release_date, 	count(1) over () RfqCount  FROM (		 
		SELECT
			distinct 
				b.rfq_id as RFQId 
				, b.rfq_name as RFQName
				, floor(c.min_part_quantity) as Quantity
				, c.min_part_quantity_unit as UnitValue 
				, j.value as PostProductionProcessValue
				, dbo.[fn_getTranslatedValue](k.material_name, 'EN') as Material 
				, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as Process
				, b.contact_id as BuyerContactId 
				, b.quotes_needed_by as QuotesNeededBy
				, a.is_rfq_like IsRfqLike 
				, o.no_of_stars AS NoOfStars 
				, coalesce(p.file_name,'') as RfqThumbnail	 
				, b.special_instruction_to_manufacturer as SpecialInstructions
				, m.company_id AS BuyerCompanyId	
				, vw_address.state			AS [State]
				, vw_address.country_name	AS Country	
				,mcom.name as buyer_company_name
				, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS buyer_company_logo
				, c.rfq_part_id
				, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )		 rfq_parts_count
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				, 
				  case 
					 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
					--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
					/**/
					/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
					when @is_premium_supplier in (83,84,85,313) then 0
					/**/
					else
						(
							select count(1) from mp_rfq_quote_supplierquote (nolock) 
							where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
						)
				  end as no_of_quotes 
				/**/
				, mrqsq.is_reviewed AS IsReviewed
				/* M2-3318 Buyer - Change the My Quotes page to reflect Viewed and Reviewed - DB */
				, mrqsq.IsViewed	AS IsViewed
				/**/
				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
				/* M2-4653 */
				,'No Action' AS ActionForGrowthPackage
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
				and rfq_status_id in  (3 , 5, 6 ,16,17,20 ) ---- added 16,17,20 in in clause with M2-5047
				and  is_rfq_resubmitted = 0
				and  mrqsq.is_quote_submitted = 1
				and mrqsq.contact_id = @ContactId
			join mp_rfq_parts c					(nolock) on b.rfq_id = c.rfq_id and c.is_rfq_part_default =  1
			join mp_rfq_preferences  mrp		(nolock) on b.rfq_id = mrp.rfq_id 
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
				join mp_contacts m1  (nolock) on b1.contact_id = m1.contact_id -- and rfq_status_id = 3 
				join mp_star_rating o1  (nolock) on o1.company_id = m1.company_id
			) o	on o.company_id = m.company_id
			left join mp_special_files p		(nolock) on p.file_id = b.file_id
			left join vw_address				(nolock) on m.address_id = vw_address.address_id
			left join mp_rfq_supplier_likes a	(nolock) on a.rfq_id = b.rfq_id  and a.contact_id = @ContactId
			left join mp_company_processes	mcp	(nolock) on d.part_category_id = mcp.part_category_id and mcp.company_id = @CompanyId
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			left join #rfq_list_for_parts_search r on  b.rfq_id =  r.rfq_id
			/**/
		WHERE 

            b.rfq_id not in  (select rfq_id from @blacklisted_rfqs)
			and (
					(d.part_category_id in (select processId from @Processids ))
					OR 
					((Select count(processId) from @Processids) = 0)
				)
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
			/**/
			and b.rfq_id not in 
			(

				select distinct a.rfq_id  from mp_rfq_quote_SupplierQuote	a	(nolock) 
				join mp_rfq_quote_items (nolock)  b on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id and b.is_awrded = 1 and a.contact_id = @ContactId
				and  is_rfq_resubmitted = 0

			)
			and b.rfq_id in (select distinct rfq_id from mp_rfq_shopiq_metrics (nolock))

		) AS QuotedShopIQRFQ
		left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on QuotedShopIQRFQ.RFQId = rfq_release.rfq_id
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   Quantity end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   Material end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   Process end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   PostProductionProcessValue end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   Quantity end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   Material end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   Process end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   PostProductionProcessValue end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc   
			
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only
	end	
	------------------------ Quoted Rfq (Declined quotes)--------------------
	ELSE IF (@RfqType = 24)		 
	BEGIN	
		
		SELECT QuotedRFQ.* , rfq_release.release_date, 	count(1) over () RfqCount  FROM (		 
		SELECT
			distinct 
				b.rfq_id as RFQId 
				, b.rfq_name as RFQName
				, floor(c.min_part_quantity) as Quantity
				, c.min_part_quantity_unit as UnitValue 
				, j.value as PostProductionProcessValue
				, dbo.[fn_getTranslatedValue](k.material_name, 'EN') as Material 
				, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as Process
				, b.contact_id as BuyerContactId 
				, b.quotes_needed_by as QuotesNeededBy
				, a.is_rfq_like IsRfqLike 
				, o.no_of_stars AS NoOfStars 
				, coalesce(p.file_name,'') as RfqThumbnail	 
				, b.special_instruction_to_manufacturer as SpecialInstructions
				, m.company_id AS BuyerCompanyId	
				, vw_address.state			AS [State]
				, vw_address.country_name	AS Country	
				,mcom.name as buyer_company_name
				, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS buyer_company_logo
				, c.rfq_part_id
				, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )		 rfq_parts_count
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				, 
				  case 
					 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
					--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
					/**/
					/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
					when @is_premium_supplier in (83,84,85,313) then 0
					/**/
					else
						(
							select count(1) from mp_rfq_quote_supplierquote (nolock) 
							where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
						)
				  end as no_of_quotes 
				/**/
				, mrqsq.is_reviewed AS IsReviewed
				/* M2-3318 Buyer - Change the My Quotes page to reflect Viewed and Reviewed - DB */
				, mrqsq.IsViewed	AS IsViewed
				/**/
				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
				/* M2-4653 */
				,'No Action' AS ActionForGrowthPackage
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
				and rfq_status_id in  (3 , 5, 6 )
				and  ( is_rfq_resubmitted = 0 OR is_quote_declined = 1 ) 
				and  mrqsq.is_quote_submitted = 1
				and  mrqsq.contact_id = @ContactId
			join mp_rfq_preferences  mrp		(nolock) on b.rfq_id = mrp.rfq_id 
			/* M2-1617 M - Add a Declined Quote page and add it to the left menu */
			join 
			(
				select a.rfq_quote_SupplierQuote_id 
				from mp_rfq_quote_items			a	(nolock)
				join mp_rfq_quote_SupplierQuote b 	(nolock) on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id
				where a.is_awrded = 0 and b.contact_id = @ContactId
			) mrqi on mrqsq.rfq_quote_SupplierQuote_id = mrqi.rfq_quote_SupplierQuote_id
			/**/
			join mp_rfq_parts c					(nolock) on b.rfq_id = c.rfq_id and c.is_rfq_part_default =  1
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
				join mp_contacts m1  (nolock) on b1.contact_id = m1.contact_id -- and rfq_status_id = 3 
				join mp_star_rating o1  (nolock) on o1.company_id = m1.company_id
			) o	on o.company_id = m.company_id
			left join mp_special_files p		(nolock) on p.file_id = b.file_id
			left join vw_address				(nolock) on m.address_id = vw_address.address_id
			left join mp_rfq_supplier_likes a	(nolock) on a.rfq_id = b.rfq_id  and a.contact_id = @ContactId
			left join mp_company_processes	mcp	(nolock) on d.part_category_id = mcp.part_category_id and mcp.company_id = @CompanyId
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			left join #rfq_list_for_parts_search r on  b.rfq_id =  r.rfq_id
			/**/
		WHERE 

            b.rfq_id not in  (select rfq_id from @blacklisted_rfqs)
			and (
					(d.part_category_id in (select processId from @Processids ))
					OR 
					((Select count(processId) from @Processids) = 0)
				)
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
			/**/

			) AS QuotedRFQ
			left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on QuotedRFQ.RFQId = rfq_release.rfq_id
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   Quantity end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   Material end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   Process end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   PostProductionProcessValue end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   Quantity end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   Material end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   Process end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   PostProductionProcessValue end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc  
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only
	END	
	------------------------ Liked Rfq (Open)--------------------
	ELSE IF (@RfqType = 25)	
	BEGIN	

		select rfqlikes.* , rfq_release.release_date, 	count(1) over () RfqCount  from 
		(
			select 
				distinct 
				b.rfq_id as RFQId 
				, b.rfq_name as RFQName
				, floor(c.min_part_quantity) as Quantity
				, c.min_part_quantity_unit as UnitValue 
				, j.value as PostProductionProcessValue
				, k.material_name_en as Material 
				, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as Process
				, b.contact_id as BuyerContactId 
				, b.quotes_needed_by as QuotesNeededBy
				, a.is_rfq_like IsRfqLike 
				, o.no_of_stars AS NoOfStars 
				, coalesce(p.file_name,'') as RfqThumbnail	 
				, b.special_instruction_to_manufacturer as SpecialInstructions
				, m.company_id AS BuyerCompanyId	
				, vw_address.state			AS [State]
				, vw_address.country_name	AS Country	
				, mcom.name as buyer_company_name
				, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS buyer_company_logo	
				, c.rfq_part_id
				, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )		 rfq_parts_count
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				, 
				  case 
					 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
					--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
					/**/
					/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
					when @is_premium_supplier in (83,84,85,313) then 0
					/**/
					else
						(
							select count(1) from mp_rfq_quote_supplierquote (nolock) 
							where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
						)
				  end as no_of_quotes 
				/**/
				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
				/* M2-4653 */
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
			from mp_rfq_supplier_likes a		(nolock)
			join mp_rfq b						(nolock) on a.rfq_id = b.rfq_id and is_rfq_like = 1 and a.contact_id = @ContactId 
				and rfq_status_id = 3 
			join mp_rfq_parts c					(nolock) on a.rfq_id = c.rfq_id  and c.is_rfq_part_default =  1
			join mp_rfq_preferences  mrp		(nolock) on b.rfq_id = mrp.rfq_id 
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
			left join mp_company_processes	mcp	(nolock) on d.part_category_id = mcp.part_category_id and mcp.company_id = @CompanyId
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
				LEFT JOIN mp_gateway_subscription_company_processes  (NOLOCK) c ON b.part_category_id = c.part_category_id AND c.company_id = @CompanyId  AND c.is_active = 1
 				WHERE  
					a.rfq_id IN (select * from #rfq_list)
				GROUP BY a.rfq_id
			) s on b.rfq_id = s.rfq_id
			/* M2-4653 */
			left join #tmpmpGrowthPackageUnlockRFQsInfo t on b.rfq_id = t.Rfq_Id
			/**/
			where 
			
			 a.rfq_id not in  (select rfq_id from @blacklisted_rfqs) 
			 and (
					(d.part_category_id in (select processId from @Processids ))
					OR 
					((select count(processId) from @Processids) = 0)
				 )
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
			/**/
		) rfqlikes
		left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on rfqlikes.RFQId = rfq_release.rfq_id
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   Quantity end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   Material end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   Process end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   PostProductionProcessValue end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   Quantity end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   Material end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   Process end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   PostProductionProcessValue end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only

	END	  	
	------------------------ Liked Rfq (Closed)--------------------
	ELSE IF (@RfqType = 26)	
	BEGIN	

		select rfqlikes.* , rfq_release.release_date, 	count(1) over () RfqCount  from 
		(
			select 
				distinct 
				b.rfq_id as RFQId 
				, b.rfq_name as RFQName
				, floor(c.min_part_quantity) as Quantity
				, c.min_part_quantity_unit as UnitValue 
				, j.value as PostProductionProcessValue
				, k.material_name_en as Material 
				, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as Process
				, b.contact_id as BuyerContactId 
				, b.quotes_needed_by as QuotesNeededBy
				, a.is_rfq_like IsRfqLike 
				, o.no_of_stars AS NoOfStars 
				, coalesce(p.file_name,'') as RfqThumbnail	 
				, b.special_instruction_to_manufacturer as SpecialInstructions
				, m.company_id AS BuyerCompanyId	
				, vw_address.state			AS [State]
				, vw_address.country_name	AS Country	
				, mcom.name as buyer_company_name
				, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS buyer_company_logo	
				, c.rfq_part_id
				, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )		 rfq_parts_count
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				, 
				  case 
					 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
					--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
					/**/
					/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
					when @is_premium_supplier in (83,84,85,313) then 0
					/**/
					else
						(
							select count(1) from mp_rfq_quote_supplierquote (nolock) 
							where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
						)
				  end as no_of_quotes 
				/**/
				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
				/* M2-4653 */
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
				) AS ActionForGrowthPackage
				/**/
				/* M2-4754 */
				,b.IsRfqWithMissingInfo  
			    /**/
				/* M2-4793 */
				,b.WithOrderManagement  
			/**/
			from mp_rfq_supplier_likes a		(nolock)
			join mp_rfq b						(nolock) on a.rfq_id = b.rfq_id and is_rfq_like = 1 and a.contact_id = @ContactId 
				and rfq_status_id = 5
			join mp_rfq_parts c					(nolock) on a.rfq_id = c.rfq_id  and c.is_rfq_part_default =  1
			join mp_rfq_preferences  mrp		(nolock) on b.rfq_id = mrp.rfq_id 
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
			left join mp_company_processes	mcp	(nolock) on d.part_category_id = mcp.part_category_id and mcp.company_id = @CompanyId
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			left join #rfq_list_for_parts_search r on  b.rfq_id =  r.rfq_id
			/**/
			/**/
			left join 
			(
				SELECT 
					a.rfq_id,
					COUNT(c.part_category_id) MatchedPartCount
				FROM mp_rfq					(NOLOCK) a
				LEFT JOIN mp_rfq_parts		(NOLOCK) b ON a.rfq_id = b.rfq_id AND b.status_id  = 2
				LEFT JOIN mp_gateway_subscription_company_processes  (NOLOCK) c ON b.part_category_id = c.part_category_id AND c.company_id = @CompanyId  AND c.is_active = 1
 				WHERE  
					a.rfq_id IN (select * from #rfq_list)
				GROUP BY a.rfq_id
			) s on b.rfq_id = s.rfq_id
			/* M2-4653 */
			left join #tmpmpGrowthPackageUnlockRFQsInfo t on b.rfq_id = t.Rfq_Id
			/**/
			where 
			
			 a.rfq_id not in  (select rfq_id from @blacklisted_rfqs) 
			 and (
					(d.part_category_id in (select processId from @Processids ))
					OR 
					((select count(processId) from @Processids) = 0)
				 )
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
			/**/
		) rfqlikes
		left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on rfqlikes.RFQId = rfq_release.rfq_id
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   Quantity end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   Material end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   Process end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   PostProductionProcessValue end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   Quantity end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   Material end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   Process end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   PostProductionProcessValue end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only

	END	  	
	------------------------ Liked Rfq (Shop IQ)--------------------
	ELSE IF (@RfqType = 27)	
	BEGIN	

		select rfqlikes.* , rfq_release.release_date, 	count(1) over () RfqCount  from 
		(
			select 
				distinct 
				b.rfq_id as RFQId 
				, b.rfq_name as RFQName
				, floor(c.min_part_quantity) as Quantity
				, c.min_part_quantity_unit as UnitValue 
				, j.value as PostProductionProcessValue
				, k.material_name_en as Material 
				, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as Process
				, b.contact_id as BuyerContactId 
				, b.quotes_needed_by as QuotesNeededBy
				, a.is_rfq_like IsRfqLike 
				, o.no_of_stars AS NoOfStars 
				, coalesce(p.file_name,'') as RfqThumbnail	 
				, b.special_instruction_to_manufacturer as SpecialInstructions
				, m.company_id AS BuyerCompanyId	
				, vw_address.state			AS [State]
				, vw_address.country_name	AS Country	
				, mcom.name as buyer_company_name
				, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS buyer_company_logo	
				, c.rfq_part_id
				, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )		 rfq_parts_count
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				, 
				  case 
					 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
					--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
					/**/
					/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
					when @is_premium_supplier in (83,84,85,313) then 0
					/**/
					else
						(
							select count(1) from mp_rfq_quote_supplierquote (nolock) 
							where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
						)
				  end as no_of_quotes 
				/**/
				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
				/* M2-4653 */
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
				) AS ActionForGrowthPackage
				/**/
				/* M2-4754 */
				,b.IsRfqWithMissingInfo  
			    /**/
				/* M2-4793 */
				,b.WithOrderManagement  
			/**/
			from mp_rfq_supplier_likes a		(nolock)
			join mp_rfq b						(nolock) on a.rfq_id = b.rfq_id and is_rfq_like = 1 and a.contact_id = @ContactId 
				--and rfq_status_id = 5
			join mp_rfq_parts c					(nolock) on a.rfq_id = c.rfq_id  and c.is_rfq_part_default =  1
			join mp_rfq_preferences  mrp		(nolock) on b.rfq_id = mrp.rfq_id 
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
			left join mp_company_processes	mcp	(nolock) on d.part_category_id = mcp.part_category_id and mcp.company_id = @CompanyId
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			left join #rfq_list_for_parts_search r on  b.rfq_id =  r.rfq_id
			/**/
			/**/
			left join 
			(
				SELECT 
					a.rfq_id,
					COUNT(c.part_category_id) MatchedPartCount
				FROM mp_rfq					(NOLOCK) a
				LEFT JOIN mp_rfq_parts		(NOLOCK) b ON a.rfq_id = b.rfq_id AND b.status_id  = 2
				LEFT JOIN mp_gateway_subscription_company_processes  (NOLOCK) c ON b.part_category_id = c.part_category_id AND c.company_id = @CompanyId  AND c.is_active = 1
 				WHERE  
					a.rfq_id IN (select * from #rfq_list)
				GROUP BY a.rfq_id
			) s on b.rfq_id = s.rfq_id
			/* M2-4653 */
			left join #tmpmpGrowthPackageUnlockRFQsInfo t on b.rfq_id = t.Rfq_Id
			/**/
			where 
			
			 a.rfq_id not in  (select rfq_id from @blacklisted_rfqs) 
			 and (
					(d.part_category_id in (select processId from @Processids ))
					OR 
					((select count(processId) from @Processids) = 0)
				 )
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
			/**/
			 and b.rfq_id in (select distinct rfq_id from mp_rfq_shopiq_metrics (nolock))
		) rfqlikes
		left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on rfqlikes.RFQId = rfq_release.rfq_id
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   Quantity end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   Material end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   Process end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   PostProductionProcessValue end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   Quantity end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   Material end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   Process end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   PostProductionProcessValue end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only

	END	  
	------------------------ My RFQ's (no of quotes = 0 and no of quotes < 3) --------------------
	ELSE IF (@RfqType in  (28,29))	
	BEGIN	


		select myrfqs.* , rfq_release.release_date, 	count(1) over () RfqCount  from 
		 (
			select 
				distinct 
				b.rfq_id as RFQId 
				, b.rfq_name as RFQName
				, floor(c.min_part_quantity) as Quantity
				, c.min_part_quantity_unit as UnitValue 
				, j.value as PostProductionProcessValue
				, k.material_name_en  as Material 
				, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as Process
				, b.contact_id as BuyerContactId 
				, b.quotes_needed_by as QuotesNeededBy
				, a.is_rfq_like IsRfqLike 
				, o.no_of_stars AS NoOfStars 
				, coalesce(p.file_name,'') as RfqThumbnail	 
				, b.special_instruction_to_manufacturer as SpecialInstructions
				, m.company_id AS BuyerCompanyId	
				, vw_address.state			AS [State]
				, vw_address.country_name	AS Country	
				,mcom.name as buyer_company_name
				, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS buyer_company_logo
				, c.rfq_part_id
				, c.is_rfq_part_default
				, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )		 rfq_parts_count
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				, 
				  case 
					 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
					--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
					/**/
					/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
					when @is_premium_supplier in (83,84,85,313) then 0
					/**/
					else
						(
							select count(1) from mp_rfq_quote_supplierquote (nolock) 
							where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
						)
				  end as no_of_quotes 
				/**/
				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
				/* M2-4653 */
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
				) AS ActionForGrowthPackage
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
			left join mp_rfq_supplier_likes a	(nolock) on a.rfq_id = b.rfq_id  and a.contact_id = @ContactId
			/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			left join #rfq_list q on b.rfq_id =  q.rfq_id
			/**/
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			left join #rfq_list_for_parts_search r on  b.rfq_id =  r.rfq_id
			/**/
			/**/
			left join 
			(
				SELECT 
					a.rfq_id,
					COUNT(c.part_category_id) MatchedPartCount
				FROM mp_rfq					(NOLOCK) a
				LEFT JOIN mp_rfq_parts		(NOLOCK) b ON a.rfq_id = b.rfq_id AND b.status_id  = 2
				LEFT JOIN mp_gateway_subscription_company_processes  (NOLOCK) c ON b.part_category_id = c.part_category_id AND c.company_id = @CompanyId  AND c.is_active = 1
 				WHERE  
					a.rfq_id IN (select * from #rfq_list)
				GROUP BY a.rfq_id
			) s on b.rfq_id = s.rfq_id
			/* M2-4653 */
			left join #tmpmpGrowthPackageUnlockRFQsInfo t on b.rfq_id = t.Rfq_Id
			/**/
			where 
			( 
				 (
					mrs.company_id = -1 
					and mrp.rfq_pref_manufacturing_location_id  in 
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
			and b.rfq_id not in  (select distinct rfq_id from mp_rfq_quote_SupplierQuote (nolock) where contact_id = @ContactId  )
			and b.rfq_id not in  (select rfq_id from @blacklisted_rfqs) 
			and (a.is_rfq_like != 0 or a.is_rfq_like is null)
			/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			and c.is_rfq_part_default =  1
			/**/
		) myrfqs
		 left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on myrfqs.RFQId = rfq_release.rfq_id
		/* M2-2044 M - My RFQs, My Liked RFQs, Followed Buyers RFQs - add filters for # of quotes - DB */
		where 
			no_of_quotes < (case when @RfqType = 28 then 1 when @RfqType = 29 then 3 end )
			and no_of_quotes > (case when @RfqType = 28 then -1 when @RfqType = 29 then 0 end )
		/**/
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   Quantity end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   Material end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   Process end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   PostProductionProcessValue end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'release_date' then   release_date end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   Quantity end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   Material end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   Process end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   PostProductionProcessValue end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'release_date' then   release_date end asc   
			
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only
		
	END	
	------------------------ My Liked (no of quotes = 0 and no of quotes < 3) --------------------
	ELSE IF (@RfqType in  (30,31))	
	BEGIN	

		select 
			rfqlikes.* 
			, rfq_release.release_date
			, case 
				/* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
				--when rfq_pref_manufacturing_location_id  = 3 then 0
				/**/
				/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
				when @is_premium_supplier in (83,84,85,313) then 0
				/**/
				else
				no_of_quotes
			  end as no_of_quotes
			, 	count(1) over () RfqCount  from 
		(
			select 
				distinct 
				b.rfq_id as RFQId 
				, b.rfq_name as RFQName
				, floor(c.min_part_quantity) as Quantity
				, c.min_part_quantity_unit as UnitValue 
				, j.value as PostProductionProcessValue
				, k.material_name_en as Material 
				, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as Process
				, b.contact_id as BuyerContactId 
				, b.quotes_needed_by as QuotesNeededBy
				, a.is_rfq_like IsRfqLike 
				, o.no_of_stars AS NoOfStars  
				, coalesce(p.file_name,'') as RfqThumbnail	 
				, b.special_instruction_to_manufacturer as SpecialInstructions
				, m.company_id AS BuyerCompanyId	
				, vw_address.state			AS [State]
				, vw_address.country_name	AS Country	
				, mcom.name as buyer_company_name
				, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS buyer_company_logo	
				, c.rfq_part_id
				, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )		 rfq_parts_count
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				, (
						select count(1) from mp_rfq_quote_supplierquote (nolock) 
						where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
					  ) as no_of_quotes 
				, mrp.rfq_pref_manufacturing_location_id 
				/**/
					
				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
				/* M2-4653 */
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
				) AS ActionForGrowthPackage
				/**/
			    /* M2-4754 */
				,b.IsRfqWithMissingInfo  
			    /**/
				/* M2-4793 */
				,b.WithOrderManagement  
			/**/
			from mp_rfq_supplier_likes a		(nolock)
			join mp_rfq b						(nolock) on a.rfq_id = b.rfq_id and is_rfq_like = 1 and a.contact_id = @ContactId 
				--and rfq_status_id = 3 
			join mp_rfq_parts c					(nolock) on a.rfq_id = c.rfq_id  and c.is_rfq_part_default =  1
			join mp_rfq_preferences  mrp		(nolock) on b.rfq_id = mrp.rfq_id 
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
			left join mp_company_processes	mcp	(nolock) on d.part_category_id = mcp.part_category_id and mcp.company_id = @CompanyId
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			left join #rfq_list_for_parts_search r on  b.rfq_id =  r.rfq_id
			/**/
			/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			left join #rfq_list q on b.rfq_id =  q.rfq_id
			/**/			
			left join 
			(
				SELECT 
					a.rfq_id,
					COUNT(c.part_category_id) MatchedPartCount
				FROM mp_rfq					(NOLOCK) a
				LEFT JOIN mp_rfq_parts		(NOLOCK) b ON a.rfq_id = b.rfq_id AND b.status_id  = 2
				LEFT JOIN mp_gateway_subscription_company_processes  (NOLOCK) c ON b.part_category_id = c.part_category_id AND c.company_id = @CompanyId  AND c.is_active = 1
 				WHERE  
					a.rfq_id IN (select * from #rfq_list)
				GROUP BY a.rfq_id
			) s on b.rfq_id = s.rfq_id
			/* M2-4653 */
			left join #tmpmpGrowthPackageUnlockRFQsInfo t on b.rfq_id = t.Rfq_Id
			/**/
			where 
			
			 a.rfq_id not in  (select rfq_id from @blacklisted_rfqs) 
			 and (
					(d.part_category_id in (select processId from @Processids ))
					OR 
					((select count(processId) from @Processids) = 0)
				 )
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
			/**/
			/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			and b.rfq_id = case when (select count(1) from #rfq_list)  > 0 then  q.rfq_id  else b.rfq_id end
			/**/
		) rfqlikes
		left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on rfqlikes.RFQId = rfq_release.rfq_id
		where 
			no_of_quotes < (case when @RfqType = 30 then 1 when @RfqType = 31 then 3 end )
			and no_of_quotes > (case when @RfqType = 30 then -1 when @RfqType = 31 then -1 end )
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   Quantity end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   Material end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   Process end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   PostProductionProcessValue end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   Quantity end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   Material end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   Process end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   PostProductionProcessValue end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only

	END	  
	------------------------ Followed Buyer (no of quotes = 0 and no of quotes < 3) --------------------
	ELSE IF (@RfqType in  (32,33))	
	BEGIN	
		

		select 
			FollowedBuyersRFQ.* 
			, rfq_release.release_date
			, case 
				/* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
				--when rfq_pref_manufacturing_location_id  = 3 then 0
				/**/
				/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
				when @is_premium_supplier in (83,84,85,313) then 0
				/**/
				else
				no_of_quotes
			  end as no_of_quotes
			, count(1) over () RfqCount  from 
		(
			select 
				distinct 
				b.rfq_id as RFQId 
				, b.rfq_name as RFQName
				, floor(c.min_part_quantity) as Quantity
				, c.min_part_quantity_unit as UnitValue 
				, j.value as PostProductionProcessValue
				, k.material_name_en as Material 
				, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as Process
				, b.contact_id as BuyerContactId 
				, b.quotes_needed_by as QuotesNeededBy
				, a.is_rfq_like IsRfqLike 
				, o.no_of_stars AS NoOfStars 
				, coalesce(p.file_name,'') as RfqThumbnail	 
				, b.special_instruction_to_manufacturer as SpecialInstructions
				, m.company_id AS BuyerCompanyId	
				, vw_address.state			AS [State]
				, vw_address.country_name	AS Country	
				, mcom.name as buyer_company_name
				, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS buyer_company_logo	
				, c.rfq_part_id
				, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )		 rfq_parts_count
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				, (
						select count(1) from mp_rfq_quote_supplierquote (nolock) 
						where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
					  ) as no_of_quotes 
				, mrp.rfq_pref_manufacturing_location_id 
				/**/
				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
				/* M2-4653 */
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
				) AS ActionForGrowthPackage
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
				select distinct mbd.company_id from 
				mp_book_details mbd			(nolock)
				JOIN mp_books  mb			(nolock)	on mbd.book_id =mb.book_id
				JOIN mp_mst_book_type mmbt	(nolock)	on mmbt.book_type_id = mb.bk_type
				and mmbt.book_type ='BOOK_BOOKTYPE_HOTLIST'
				and mb.contact_id = @ContactId

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
				LEFT JOIN mp_gateway_subscription_company_processes  (NOLOCK) c ON b.part_category_id = c.part_category_id AND c.company_id = @CompanyId  AND c.is_active = 1
 				WHERE  
					a.rfq_id IN (select * from #rfq_list)
				GROUP BY a.rfq_id
			) s on b.rfq_id = s.rfq_id
			/* M2-4653 */
			left join #tmpmpGrowthPackageUnlockRFQsInfo t on b.rfq_id = t.Rfq_Id
			/**/
			where 
			 b.rfq_id not in  (select rfq_id from @blacklisted_rfqs) 
			 /* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			 and b.rfq_id = case when (select count(1) from #rfq_list) > 0 then  q.rfq_id  else b.rfq_id end
			 /**/
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
			/**/
			/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			and c.is_rfq_part_default =  1
			/**/
		) FollowedBuyersRFQ
		left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on FollowedBuyersRFQ.RFQId = rfq_release.rfq_id
		where 
			no_of_quotes < (case when @RfqType = 32 then 1 when @RfqType = 33 then 3 end )
			and no_of_quotes > (case when @RfqType = 32 then -1 when @RfqType = 33 then -1 end )
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   Quantity end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   Material end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   Process end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   PostProductionProcessValue end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   Quantity end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   Material end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   Process end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   PostProductionProcessValue end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc  
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only

	
	END	  
	------------------------ Liked Rfq Tab in My RFQ's (no of quotes = 0 and no of quotes < 3)  --------------------
    ELSE IF (@RfqType  in  (34,35))	
    BEGIN	
		select myrfqs.* , rfq_release.release_date, 	count(1) over () RfqCount  from 
		 (
			select 
				distinct 
				b.rfq_id as RFQId 
				, b.rfq_name as RFQName
				, floor(c.min_part_quantity) as Quantity
				, c.min_part_quantity_unit as UnitValue 
				, j.value as PostProductionProcessValue
				, k.material_name_en  as Material 
				, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as Process
				, b.contact_id as BuyerContactId 
				, b.quotes_needed_by as QuotesNeededBy
				, a.is_rfq_like IsRfqLike 
				, o.no_of_stars AS NoOfStars  
				, coalesce(p.file_name,'') as RfqThumbnail	 
				, b.special_instruction_to_manufacturer as SpecialInstructions
				, m.company_id AS BuyerCompanyId	
				, vw_address.state			AS [State]
				, vw_address.country_name	AS Country	
				,mcom.name as buyer_company_name
				, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS buyer_company_logo
				, c.rfq_part_id
				, c.is_rfq_part_default
				, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )		 rfq_parts_count
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				, 
				  case 
					 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
					--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
					/**/
					/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
					when @is_premium_supplier in (83,84,85,313) then 0
					/**/
					else
						(
							select count(1) from mp_rfq_quote_supplierquote (nolock) 
							where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
						)
				  end as no_of_quotes 
				/**/
				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
				/* M2-4653 */
				,'No Action' AS ActionForGrowthPackage
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
			left join mp_rfq_supplier_likes a	(nolock) on a.rfq_id = b.rfq_id  and a.contact_id = @ContactId
			/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			left join #rfq_list q on b.rfq_id =  q.rfq_id
			/**/
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			left join #rfq_list_for_parts_search r on  b.rfq_id =  r.rfq_id
			/**/
			
			where 
			 ( 
				 (
					mrs.company_id = -1 
					and mrp.rfq_pref_manufacturing_location_id  in 
					/*  M2-2087 Clone up to 3 RFQ's for 3 regions - API */
					(select * from #rfqlocation)
					/**/
					and rfq_status_id = 3  
					/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
					and b.rfq_id = case when (select count(1) from #rfq_list) > 0 then  q.rfq_id  else b.rfq_id end
					/**/
				 )
			 
			 )
			 and b.rfq_id not in  (select distinct rfq_id from mp_rfq_quote_SupplierQuote (nolock) where contact_id = @ContactId  )
			 and b.rfq_id not in  (select rfq_id from @blacklisted_rfqs) 

			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
			/**/
			and (a.is_rfq_like != 0 or a.is_rfq_like is null)
			/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			and c.is_rfq_part_default =  1
			/**/
		)  myrfqs
		left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on myrfqs.RFQId = rfq_release.rfq_id
		where 
		myrfqs.RFQId in  (select distinct rfq_id from  mp_rfq_supplier_likes a	(nolock) where a.contact_id = @ContactId  and is_rfq_like = 1 )
		and
		no_of_quotes < (case when @RfqType = 34 then 1 when @RfqType = 35 then 3 end )
		and no_of_quotes > (case when @RfqType = 34 then -1 when @RfqType = 35 then 0 end )
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   Quantity end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   Material end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   Process end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   PostProductionProcessValue end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'release_date' then   release_date end desc    
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   Quantity end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   Material end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   Process end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   PostProductionProcessValue end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'release_date' then   release_date end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only
	
	END	 
	------------------------ DisLiked Rfq Tab in My RFQ's (no of quotes = 0 and no of quotes < 3)   --------------------
    ELSE IF  (@RfqType  in  (36,37))	
    BEGIN	
		select myrfqs.* , rfq_release.release_date, 	count(1) over () RfqCount  from 
		 (
			select 
				distinct 
				b.rfq_id as RFQId 
				, b.rfq_name as RFQName
				, floor(c.min_part_quantity) as Quantity
				, c.min_part_quantity_unit as UnitValue 
				, j.value as PostProductionProcessValue
				, k.material_name_en  as Material 
				, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as Process
				, b.contact_id as BuyerContactId 
				, b.quotes_needed_by as QuotesNeededBy
				, a.is_rfq_like IsRfqLike 
				, o.no_of_stars AS NoOfStars 
				, coalesce(p.file_name,'') as RfqThumbnail	 
				, b.special_instruction_to_manufacturer as SpecialInstructions
				, m.company_id AS BuyerCompanyId	
				, vw_address.state			AS [State]
				, vw_address.country_name	AS Country	
				,mcom.name as buyer_company_name
				, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS buyer_company_logo
				, c.rfq_part_id
				, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )		 rfq_parts_count
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				, 
				  case 
					 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
					--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
					/**/
					/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
					when @is_premium_supplier in (83,84,85,313) then 0
					/**/
					else
						(
							select count(1) from mp_rfq_quote_supplierquote (nolock) 
							where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
						)
				  end as no_of_quotes 
				/**/
				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
				/* M2-4653 */
				,'No Action' AS ActionForGrowthPackage
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
			left join mp_rfq_supplier_likes a	(nolock) on a.rfq_id = b.rfq_id  and a.contact_id = @ContactId
			left join mp_company_processes	mcp	(nolock) on d.part_category_id = mcp.part_category_id and mcp.company_id = @CompanyId
			/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			left join #rfq_list q on b.rfq_id =  q.rfq_id
			/**/
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			left join #rfq_list_for_parts_search r on  b.rfq_id =  r.rfq_id
			/**/
			where 
			 ( 
				 (
					mrs.company_id =  -1  
					and mrp.rfq_pref_manufacturing_location_id  in 
					/*  M2-2087 Clone up to 3 RFQ's for 3 regions - API */
					(select * from #rfqlocation)
					/**/
					and rfq_status_id = 3  
					--and d.part_category_id = case when @company_capabilities > 0 then  mcp.part_category_id  else d.part_category_id end
				 )
 
			 )
			 and b.rfq_id not in  (select distinct rfq_id from mp_rfq_quote_SupplierQuote (nolock) where contact_id = @ContactId and is_rfq_resubmitted = 0 )
			 and b.rfq_id not in  (select rfq_id from @blacklisted_rfqs) 
			 /* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			 and b.rfq_id = case when (select count(1) from #rfq_list) > 0 then  q.rfq_id  else b.rfq_id end
			 /**/
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
			/**/
 			 /* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			 and c.is_rfq_part_default =  1
			 /**/		
		) myrfqs
		left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on myrfqs.RFQId = rfq_release.rfq_id
		where myrfqs.RFQId in  (select distinct rfq_id from  mp_rfq_supplier_likes a	(nolock) where a.contact_id = @ContactId and is_rfq_like = 0 )
		and
		no_of_quotes < (case when @RfqType = 36 then 1 when @RfqType = 37 then 3 end )
		and no_of_quotes > (case when @RfqType = 36 then -1 when @RfqType = 37 then 0 end )
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   Quantity end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   Material end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   Process end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   PostProductionProcessValue end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'release_date' then   release_date end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   Quantity end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   Material end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   Process end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   PostProductionProcessValue end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'release_date' then   release_date end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only
		
	END	
	------------------------ My Company Quoted Rfq --------------------
	ELSE IF (@RfqType = 38)		 
	BEGIN	
	
		SELECT QuotedRFQ.* , rfq_release.release_date, 	count(1) over () RfqCount  FROM 
		(		 
		SELECT
			distinct 
				b.rfq_id as RFQId 
				, b.rfq_name as RFQName
				, floor(c.min_part_quantity) as Quantity
				, c.min_part_quantity_unit as UnitValue 
				, j.value as PostProductionProcessValue
				, dbo.[fn_getTranslatedValue](k.material_name, 'EN') as Material 
				, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as Process
				, b.contact_id as BuyerContactId 
				, b.quotes_needed_by as QuotesNeededBy
				, a.is_rfq_like IsRfqLike 
				, o.no_of_stars AS NoOfStars 
				, coalesce(p.file_name,'') as RfqThumbnail	 
				, b.special_instruction_to_manufacturer as SpecialInstructions
				, m.company_id AS BuyerCompanyId	
				, vw_address.state			AS [State]
				, vw_address.country_name	AS Country	
				,mcom.name as buyer_company_name
				, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS buyer_company_logo
				, c.rfq_part_id
				, mrqsq.is_reviewed AS IsReviewed
				/* M2-3318 Buyer - Change the My Quotes page to reflect Viewed and Reviewed - DB */
				, mrqsq.IsViewed	AS IsViewed
				/**/
				, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )		 rfq_parts_count
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				, 
				  case 
					 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
					--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
					/**/
					/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
					when @is_premium_supplier in (83,84,85,313) then 0
					/**/
					else
						(
							select count(1) from mp_rfq_quote_supplierquote (nolock) 
							where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
						)
				  end as no_of_quotes 
				/**/
				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
				/* M2-4653 */
				,'No Action' AS ActionForGrowthPackage
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
				and rfq_status_id in   (3 , 5, 6 ,16, 17 ,18 ,20) 
				and  is_rfq_resubmitted = 0
				and  mrqsq.is_quote_submitted = 1
				and mrqsq.contact_id in 
				/* M2-2854 M - My Company Quotes page for RFQ's - DB*/
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
			left join mp_rfq_supplier_likes a	(nolock) on a.rfq_id = b.rfq_id  and a.contact_id in
			/* M2-2854 M - My Company Quotes page for RFQ's - DB*/
				(
					select supplierid from #tmp_mycompany_suppliers
				)
				/**/
			/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			left join #rfq_list q on b.rfq_id =  q.rfq_id
			/**/
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			left join #rfq_list_for_parts_search r on  b.rfq_id =  r.rfq_id
			/**/
			
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

				select distinct a.rfq_id  
				from mp_rfq_quote_SupplierQuote	a	(nolock) 
				join mp_rfq_quote_items (nolock)  b on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id and b.is_awrded = 1 
				and a.contact_id in (select supplierid from #tmp_mycompany_suppliers)
				and  is_rfq_resubmitted = 0
				and b.status_id = 6

			)
			and c.is_rfq_part_default =  1
		) AS QuotedRFQ
			left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on QuotedRFQ.RFQId = rfq_release.rfq_id
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   Quantity end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   Material end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   Process end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   PostProductionProcessValue end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   Quantity end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   Material end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   Process end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   PostProductionProcessValue end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc  
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only
	END	
	------------------------My Company Quotes -> ShopIQ--------------------
	else if (@RfqType = 39)	
	BEGIN	
		
		SELECT QuotedShopIQRFQ.* , rfq_release.release_date, 	count(1) over () RfqCount  FROM (		 
		SELECT
			distinct 
				b.rfq_id as RFQId 
				, b.rfq_name as RFQName
				, floor(c.min_part_quantity) as Quantity
				, c.min_part_quantity_unit as UnitValue 
				, j.value as PostProductionProcessValue
				, dbo.[fn_getTranslatedValue](k.material_name, 'EN') as Material 
				, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as Process
				, b.contact_id as BuyerContactId 
				, b.quotes_needed_by as QuotesNeededBy
				, a.is_rfq_like IsRfqLike 
				, o.no_of_stars AS NoOfStars 
				, coalesce(p.file_name,'') as RfqThumbnail	 
				, b.special_instruction_to_manufacturer as SpecialInstructions
				, m.company_id AS BuyerCompanyId	
				, vw_address.state			AS [State]
				, vw_address.country_name	AS Country	
				,mcom.name as buyer_company_name
				, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS buyer_company_logo
				, c.rfq_part_id
				, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )		 rfq_parts_count
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				, 
				  case 
					 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
					--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
					/**/
					/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
					when @is_premium_supplier in (83,84,85,313) then 0
					/**/
					else
						(
							select count(1) from mp_rfq_quote_supplierquote (nolock) 
							where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
						)
				  end as no_of_quotes 
				/**/
				, mrqsq.is_reviewed AS IsReviewed
				/* M2-3318 Buyer - Change the My Quotes page to reflect Viewed and Reviewed - DB */
				, mrqsq.IsViewed	AS IsViewed
				/**/
				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
				/* M2-4653 */
				,'No Action' AS ActionForGrowthPackage
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
				and rfq_status_id in  (3 , 5, 6 )
				and  is_rfq_resubmitted = 0
				and  mrqsq.is_quote_submitted = 1
				and mrqsq.contact_id  in
				/* M2-2854 M - My Company Quotes page for RFQ's - DB*/
				(
					select supplierid from #tmp_mycompany_suppliers
				)
				/**/
			join mp_rfq_parts c					(nolock) on b.rfq_id = c.rfq_id and c.is_rfq_part_default =  1
			join mp_rfq_preferences  mrp		(nolock) on b.rfq_id = mrp.rfq_id 
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
				join mp_contacts m1  (nolock) on b1.contact_id = m1.contact_id -- and rfq_status_id = 3 
				join mp_star_rating o1  (nolock) on o1.company_id = m1.company_id
			) o	on o.company_id = m.company_id
			left join mp_special_files p		(nolock) on p.file_id = b.file_id
			left join vw_address				(nolock) on m.address_id = vw_address.address_id
			left join mp_rfq_supplier_likes a	(nolock) on a.rfq_id = b.rfq_id  and a.contact_id  in
				/* M2-2854 M - My Company Quotes page for RFQ's - DB*/
				(
					select supplierid from #tmp_mycompany_suppliers
				)
				/**/
			left join mp_company_processes	mcp	(nolock) on d.part_category_id = mcp.part_category_id and mcp.company_id = @CompanyId
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			left join #rfq_list_for_parts_search r on  b.rfq_id =  r.rfq_id
			/**/
		WHERE 

            b.rfq_id not in  (select rfq_id from @blacklisted_rfqs)
			and (
					(d.part_category_id in (select processId from @Processids ))
					OR 
					((Select count(processId) from @Processids) = 0)
				)
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
			/**/
			and b.rfq_id not in 
			(

				select distinct a.rfq_id  from mp_rfq_quote_SupplierQuote	a	(nolock) 
				join mp_rfq_quote_items (nolock)  b on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id and b.is_awrded = 1 and a.contact_id  in
				/* M2-2854 M - My Company Quotes page for RFQ's - DB*/
				(
					select supplierid from #tmp_mycompany_suppliers
				)
				/**/
				and  is_rfq_resubmitted = 0

			)
			and b.rfq_id in (select distinct rfq_id from mp_rfq_shopiq_metrics (nolock))

		) AS QuotedShopIQRFQ
		left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on QuotedShopIQRFQ.RFQId = rfq_release.rfq_id
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   Quantity end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   Material end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   Process end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   PostProductionProcessValue end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   Quantity end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   Material end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   Process end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   PostProductionProcessValue end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc   
			
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only
	end	
	------------------------ My Company Quoted Rfq (Declined)--------------------
	ELSE IF (@RfqType = 40)		 
	BEGIN	
		
		SELECT QuotedRFQ.* , rfq_release.release_date, 	count(1) over () RfqCount  FROM (		 
		SELECT
			distinct 
				b.rfq_id as RFQId 
				, b.rfq_name as RFQName
				, floor(c.min_part_quantity) as Quantity
				, c.min_part_quantity_unit as UnitValue 
				, j.value as PostProductionProcessValue
				, dbo.[fn_getTranslatedValue](k.material_name, 'EN') as Material 
				, case when category.discipline_name = l.discipline_name then l.discipline_name else category.discipline_name +' / '+ l.discipline_name end as Process
				, b.contact_id as BuyerContactId 
				, b.quotes_needed_by as QuotesNeededBy
				, a.is_rfq_like IsRfqLike 
				, o.no_of_stars AS NoOfStars 
				, coalesce(p.file_name,'') as RfqThumbnail	 
				, b.special_instruction_to_manufacturer as SpecialInstructions
				, m.company_id AS BuyerCompanyId	
				, vw_address.state			AS [State]
				, vw_address.country_name	AS Country	
				,mcom.name as buyer_company_name
				, (select top 1 file_name from mp_special_files (nolock) where  mcom.company_id = comp_id and filetype_id = 6 ) AS buyer_company_logo
				, c.rfq_part_id
				, (select count(1) from mp_rfq_parts c11 (nolock) where b.rfq_id = c11.rfq_id )		 rfq_parts_count
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				, 
				  case 
					 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
					--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
					/**/
					/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
					when @is_premium_supplier in (83,84,85,313) then 0
					/**/
					else
						(
							select count(1) from mp_rfq_quote_supplierquote (nolock) 
							where b.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0
						)
				  end as no_of_quotes 
				/**/
				, mrqsq.is_reviewed AS IsReviewed
				/* M2-3318 Buyer - Change the My Quotes page to reflect Viewed and Reviewed - DB */
				, mrqsq.IsViewed	AS IsViewed
				/**/
				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
				/* M2-4653 */
				,'No Action' AS ActionForGrowthPackage
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
				and rfq_status_id in  (3 , 5, 6 )
				and  ( is_rfq_resubmitted = 0 OR is_quote_declined = 1 ) 
				and  mrqsq.is_quote_submitted = 1
				and  mrqsq.contact_id  in
				/* M2-2854 M - My Company Quotes page for RFQ's - DB*/
				(
					select supplierid from #tmp_mycompany_suppliers
				)
				/**/
			join mp_rfq_preferences  mrp		(nolock) on b.rfq_id = mrp.rfq_id 
			/* M2-1617 M - Add a Declined Quote page and add it to the left menu */
			join 
			(
				select a.rfq_quote_SupplierQuote_id 
				from mp_rfq_quote_items			a	(nolock)
				join mp_rfq_quote_SupplierQuote b 	(nolock) on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id
				where a.is_awrded = 0 and b.contact_id  in
				/* M2-2854 M - My Company Quotes page for RFQ's - DB*/
				(
					select supplierid from #tmp_mycompany_suppliers
				)
				/**/
			) mrqi on mrqsq.rfq_quote_SupplierQuote_id = mrqi.rfq_quote_SupplierQuote_id
			/**/
			join mp_rfq_parts c					(nolock) on b.rfq_id = c.rfq_id and c.is_rfq_part_default =  1
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
				join mp_contacts m1  (nolock) on b1.contact_id = m1.contact_id -- and rfq_status_id = 3 
				join mp_star_rating o1  (nolock) on o1.company_id = m1.company_id
			) o	on o.company_id = m.company_id
			left join mp_special_files p		(nolock) on p.file_id = b.file_id
			left join vw_address				(nolock) on m.address_id = vw_address.address_id
			left join mp_rfq_supplier_likes a	(nolock) on a.rfq_id = b.rfq_id  and a.contact_id  in
				/* M2-2854 M - My Company Quotes page for RFQ's - DB*/
				(
					select supplierid from #tmp_mycompany_suppliers
				)
				/**/
			left join mp_company_processes	mcp	(nolock) on d.part_category_id = mcp.part_category_id and mcp.company_id = @CompanyId
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			left join #rfq_list_for_parts_search r on  b.rfq_id =  r.rfq_id
			/**/
		WHERE 

            b.rfq_id not in  (select rfq_id from @blacklisted_rfqs)
			and (
					(d.part_category_id in (select processId from @Processids ))
					OR 
					((Select count(processId) from @Processids) = 0)
				)
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			and b.rfq_id = case when len(@SearchText) > 0 then  r.rfq_id  else b.rfq_id end
			/**/

			) AS QuotedRFQ
			left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock) group by rfq_id ) rfq_release on QuotedRFQ.RFQId = rfq_release.rfq_id
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'quantity' then   Quantity end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'material' then   Material end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then   Process end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'postprocess' then   PostProductionProcessValue end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'quoteby'then   QuotesNeededBy end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quantity' then   Quantity end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'material' then   Material end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then   Process end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'postprocess' then   PostProductionProcessValue end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'quoteby'then   QuotesNeededBy end asc  
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only
	END		
	------------------------ My Company Unlocked RFQs--------------------
	ELSE IF (@RfqType = 41)	--- Added code with M2-5020
	BEGIN	
		SELECT myrfqs.* , rfq_release.release_date, 	count(1) OVER () RfqCount  FROM 
		 (
			SELECT 
				DISTINCT 
				b.rfq_id AS RFQId 
				, b.rfq_name AS RFQName
				, floor(c.min_part_quantity) AS Quantity
				, c.min_part_quantity_unit AS UnitValue 
				, j.value AS PostProductionProcessValue
				, k.material_name_en  AS Material 
				, CASE WHEN category.discipline_name = l.discipline_name THEN l.discipline_name ELSE category.discipline_name +' / '+ l.discipline_name END AS Process
				, b.contact_id AS BuyerContactId 
				, b.quotes_needed_by AS QuotesNeededBy
				, a.is_rfq_like AS IsRfqLike 
				, o.no_of_stars AS NoOfStars 
				, coalesce(p.file_name,'') AS RfqThumbnail	 
				, b.special_instruction_to_manufacturer AS SpecialInstructions
				, m.company_id AS BuyerCompanyId	
				, vw_address.state			AS [State]
				, vw_address.country_name	AS Country	
				,mcom.name AS buyer_company_name
				, (SELECT TOP 1 file_name from mp_special_files (NOLOCK) WHERE  mcom.company_id = comp_id and filetype_id = 6 ) AS buyer_company_logo
				, c.rfq_part_id
				, c.is_rfq_part_default
				, (SELECT COUNT(1) from mp_rfq_parts c11 (NOLOCK) WHERE b.rfq_id = c11.rfq_id )		 rfq_parts_count
				/* M2-2042 M - My RFQs - add # of Quotes to the tiles - DB */
				, 
				  CASE 
					 /* M2-2096 M - Do not display number of quotes for Asia manufacturers- DB */
					--when mrp.rfq_pref_manufacturing_location_id  = 3 then 0
					/**/
					/*  M2-2142 Vision - Add the number of quotes to the Platinum package - DB */
					WHEN @is_premium_supplier in (83,84,85,'',313) THEN 0
					/**/
					ELSE
						(
							SELECT COUNT(1) FROM mp_rfq_quote_supplierquote (NOLOCK) 
							WHERE b.rfq_id = rfq_id and is_quote_submitted = 1 AND is_rfq_resubmitted = 0
						)
				  END AS no_of_quotes 
				/**/
				/* M2-3613 Vision - Action Tracker - Add Directory RFQs -DB */
				, CASE WHEN b.IsMfgCommunityRfq = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsMfgCommunityRfq
				/**/
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
			/* M2-4754 */
				,b.IsRfqWithMissingInfo  
			/**/
			/* M2-4793 */
				,b.WithOrderManagement  
			/**/
			from
			mp_rfq_supplier		mrs				(NOLOCK) 
			JOIN mp_rfq b						(NOLOCK) ON mrs.rfq_id = b.rfq_id 
			JOIN mp_rfq_preferences  mrp		(NOLOCK) ON b.rfq_id = mrp.rfq_id 
			JOIN mp_rfq_parts c					(NOLOCK) ON b.rfq_id = c.rfq_id -- and c.is_rfq_part_default =  1
			JOIN mp_parts d						(NOLOCK) ON c.part_id = d.part_id
			LEFT JOIN mp_system_parameters j	(NOLOCK) ON c.post_production_process_id = j.id and j.sys_key = '@PostProdProcesses' 
			LEFT JOIN mp_mst_materials	k		(NOLOCK) ON c.material_id = k.material_id 
			LEFT JOIN mp_mst_part_category l	(NOLOCK) ON c.part_category_id = l.part_category_id
			/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
			LEFT JOIN mp_mst_part_category category (nolock) on l.parent_part_category_id=category.part_category_id
			/**/
			JOIN mp_contacts m					(nolock) on b.contact_id = m.contact_id
			JOIN mp_companies mcom				(nolock) on m.company_id = mcom.company_id
			LEFT JOIN 
			(
				SELECT DISTINCT m1.company_id, o1.no_of_stars 
				FROM
				mp_rfq b1 (NOLOCK)
				join mp_contacts m1  (NOLOCK) on b1.contact_id = m1.contact_id  
				join mp_star_rating o1  (NOLOCK) on o1.company_id = m1.company_id
			) o	on o.company_id = m.company_id
			LEFT JOIN mp_special_files p		(NOLOCK) ON p.file_id = b.file_id
			LEFT JOIN vw_address				(NOLOCK) ON m.address_id = vw_address.address_id
			LEFT JOIN mp_rfq_supplier_likes a	(NOLOCK) ON a.rfq_id = b.rfq_id  and a.contact_id = @ContactId
			/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			LEFT JOIN #rfq_list q on b.rfq_id =  q.rfq_id
			/**/
			/* M2-1924 M - In the application the search needs to be inclusive - DB */
			LEFT JOIN #rfq_list_for_parts_search r ON  b.rfq_id =  r.rfq_id
			/**/
			LEFT JOIN 
				(
					SELECT 
						a.rfq_id,
						COUNT(c.part_category_id) MatchedPartCount
					FROM mp_rfq					(NOLOCK) a
					LEFT JOIN mp_rfq_parts		(NOLOCK) b ON a.rfq_id = b.rfq_id AND b.status_id  = 2
					LEFT JOIN mp_gateway_subscription_company_processes  (NOLOCK) c ON b.part_category_id = c.part_category_id AND c.company_id = @CompanyId  AND c.is_active = 1
 					WHERE  
						a.rfq_id IN (SELECT * FROM #rfq_list)
					GROUP BY a.rfq_id
				) s on b.rfq_id = s.rfq_id
			JOIN mpGrowthPackageUnlockRFQsInfo t on b.rfq_id = t.Rfq_Id AND t.CompanyId = @CompanyId 
			-- AND t.IsDeleted IN ( 0,1)
			AND t.IsDeleted IN ( 0,1) -- to show unlock tab in left menu
			WHERE 
			  ( 
				 (
					mrp.rfq_pref_manufacturing_location_id in 	(SELECT * FROM #rfqlocation)
					/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
					and  b.rfq_id = CASE WHEN @company_capabilities > 0 THEN  q.rfq_id  ELSE b.rfq_id END
					/**/
					/* M2-1924 M - In the application the search needs to be inclusive - DB */
					and b.rfq_id = CASE WHEN LEN(@SearchText) > 0 THEN  r.rfq_id  ELSE b.rfq_id END
					/**/
				 )
			)

			AND  b.rfq_id NOT IN  (SELECT rfq_id FROM @blacklisted_rfqs) 
			/* M2-1666 Supplier - Process filters need to search through all the RFQ Part's processes */
			AND c.is_rfq_part_default =  1
			/**/
		) myrfqs
		 LEFT JOIN (SELECT rfq_id , MAX(status_date) release_date FROM mp_rfq_release_history (NOLOCK) GROUP BY rfq_id ) rfq_release ON myrfqs.RFQId = rfq_release.rfq_id
		order by 
			 CASE  WHEN @IsOrderByDesc =  1 and @OrderBy = 'quantity' THEN   Quantity END DESC   
			,CASE  WHEN @IsOrderByDesc =  1 and @OrderBy = 'material' THEN   Material END DESC   
			,CASE  WHEN @IsOrderByDesc =  1 and @OrderBy = 'process' THEN   Process END DESC   
			,CASE  WHEN @IsOrderByDesc =  1 and @OrderBy = 'postprocess' THEN   PostProductionProcessValue END DESC   
			,CASE  WHEN @IsOrderByDesc =  1 and @OrderBy = 'quoteby' THEN   QuotesNeededBy END DESC   
			,CASE  WHEN @IsOrderByDesc =  1 and @OrderBy = 'release_date' THEN   release_date end DESC   
			,CASE  WHEN @IsOrderByDesc =  0 and @OrderBy = 'quantity' THEN   Quantity END ASC   
			,CASE  WHEN @IsOrderByDesc =  0 and @OrderBy = 'material' THEN   Material END ASC   
			,CASE  WHEN @IsOrderByDesc =  0 and @OrderBy = 'process' THEN   Process END ASC   
			,CASE  WHEN @IsOrderByDesc =  0 and @OrderBy = 'postprocess' THEN   PostProductionProcessValue END ASC   
			,CASE  WHEN @IsOrderByDesc =  0 and @OrderBy = 'quoteby' THEN   QuotesNeededBy END ASC   
			,CASE  WHEN @IsOrderByDesc =  0 and @OrderBy = 'release_date' THEN   release_date END ASC   
			
		offset @pagesize * (@pagenumber - 1) ROWS
		FETCH NEXT @pagesize ROWS only
		  
	END	 
		  
	drop table if exists #rfq_list
	drop table if exists #rfq_list_for_parts_search
	drop table if exists #rfqlocation
	
end
