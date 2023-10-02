
/*

exec proc_get_RfqList_Buyer 
	@ContactId=1335874
	,@CompanyId=1767570
	,@TerritoryId=0
	,@RfqType=1
	,@OrderBy=N'rfq_id'
	,@IsOrderByDesc=1
	,@currentdate='2021-04-23 04:47:50'
	,@PageNumber=1
	,@PageSize=24
	,@searchText=N''
	,@IsArchived= 0

exec proc_get_RfqList_Buyer 
	@ContactId=1335874
	,@CompanyId=1767570
	,@TerritoryId=0
	,@RfqType=1
	,@OrderBy=N'rfq_id'
	,@IsOrderByDesc=1
	,@currentdate='2021-04-23 04:47:50'
	,@PageNumber=1
	,@PageSize=24
	,@searchText=N''
	,@IsArchived= 1

*/

CREATE PROCEDURE [dbo].[proc_get_RfqList_Buyer]
	 @ContactId INT,
	 @CompanyId INT,
	 @RfqType INT,
	 @TerritoryId		SMALLINT		= 0,-- 0(All) ,2(Europe) ,3(Asia) ,4(United States) ,5(Canada) ,6(Mexico / South America) ,7(USA & Canada)
	 @OrderBy VARCHAR(100) = null,
	 @IsOrderByDesc BIT='true',
	 @currentdate datetime = null ,
	 @PageNumber INT = 1,
	 @PageSize   INT = 25,
	 @searchText VARCHAR(100) = null,
	 @IsArchived BIT = 0

AS
-- ====================================================
-- Author:		dp-Am. N.
-- Create date:  31/10/2018
-- Description:	Stored procedure to Get the RFQ 
--				details based on RFQ Type for Supplier
-- ====================================================
BEGIN

	set nocount on

	if (@OrderBy is null or @OrderBy = '')
		set @OrderBy = 'rfq_id'

	if (@IsOrderByDesc is null )
		set @IsOrderByDesc = 1
	
	if @currentdate is null
		set @currentdate = getutcdate()

	if @searchText is null
		set @searchText = ''
			 
	/* M2-3767 Buyer - Add Archive functions to My RFQ's- DB */
	if @IsArchived IS NULL
	begin
		set @IsArchived = 0
	end
	/**/

	------------------------ My RFQ's --------------------
	/*M2-1596 Performance optimization for Buyer list - Database side*/
	if (@rfqtype =1)
	begin

			select 
			
				a.rfq_id as RFQId
				, a.rfq_name as RFQName
				, a.rfq_status_id as RFQStatusId
				, k.rfq_buyerstatus_li_key as RFQStatus
				, case when category.discipline_name is null then pcategory.discipline_name when category.discipline_name = pcategory.discipline_name then pcategory.discipline_name else category.discipline_name +' / '+ pcategory.discipline_name end as Process
				,  a.rfq_created_on as RFQCreatedOn
				, a.Quotes_needed_by as QuotesNeededBy
				, a.award_date as AwardDate
				, coalesce(n.File_Name,'') as RfqThumbnail
				, count(1) over () RfqCount 
				, rfq_pref_manufacturing_location_id	
				, mmtc.territory_classification_name as 	rfq_pref_manufacturing_location
				/* M2-2458 : Buyers - Tile and Row - Add Dates and # of Quotes on to RFQ tiles in MY RFQs  -DB */
				,(select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where a.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0) as RFQQuoteCount		 
				,(select TOP 1 status_date from mp_rfq_release_history (nolock) 
								where a.rfq_id = rfq_id and status_id = 3 and a.rfq_status_id NOT IN(1,2) 
								ORDER BY rfq_release_history_id DESC) as RFQReleaseDate
			    /**/
				/*  M2-3601 Create special invite RFQ from the community - API*/
				,case when a.IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
				/**/
				/* M2-4793 */
				,a.WithOrderManagement  
				/**/
			from  
				mp_rfq								 a		(nolock)			 
				join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id	
					and a.contact_id =  @contactId 
					and a.rfq_status_id in  (2,3,5,6,9,14,15,16,17,18,20)	
					/* M2-3767 Buyer - Add Archive functions to My RFQ's- DB */
					and ISNULL(a.IsArchived,0) = @IsArchived	
					/**/
				left join mp_special_files			 n		(nolock) on n.file_id = a.file_id
				/* Beau Martin   01/24/2023 RFQs 1189067, 1189068, 1189069 were found in HubSpot as "pending approval" status. */
				left join mp_rfq_parts rparts (nolock) on rparts.rfq_id=a.rfq_id and rparts.Is_Rfq_Part_Default=1
				left join mp_parts mparts  (nolock) on mparts.part_id=rparts.part_id
				/**/
				join 
				(
					select 
						distinct
						rfq_id 
						, case
							when (select count(1) from mp_rfq_preferences (nolock) where rfq_id = a.rfq_id) > 1 then 7
							else rfq_pref_manufacturing_location_id
						end rfq_pref_manufacturing_location_id
					 from 
					 mp_rfq_preferences a (nolock)
				) mrp  on a.rfq_id = mrp.rfq_id
				/* Ewesterfield-MFG Sep 22, 2019, Is it possible to add the Region selected when creating an RFQ using cloning below the Process on the Tiles and Rows*/
				join mp_mst_territory_classification (nolock) mmtc on  mrp.rfq_pref_manufacturing_location_id = mmtc.territory_classification_id
				/**/
				left join mp_mst_part_category pcategory (nolock) on pcategory.part_category_id=rparts.part_category_id
				/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
				left join mp_mst_part_category category (nolock) on pcategory.parent_part_category_id=category.part_category_id
				/**/
			where (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
			AND mrp.rfq_pref_manufacturing_location_id = (CASE WHEN @TerritoryId = 0 THEN mrp.rfq_pref_manufacturing_location_id  ELSE @TerritoryId END) 
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.rfq_id end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.rfq_name end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.rfq_id  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.rfq_name  end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only	
	end
	/**/
	------------------------ My RFQ's (Quoting) --------------------
	/*M2-1596 Performance optimization for Buyer list - Database side*/
	else if (@rfqtype =2)
	begin

			select 
			a.rfq_id as RFQId
			, a.rfq_name as RFQName
			, a.rfq_status_id as RFQStatusId
			, k.rfq_buyerstatus_li_key as RFQStatus
			,case when category.discipline_name is null then pcategory.discipline_name when category.discipline_name = pcategory.discipline_name then pcategory.discipline_name else category.discipline_name +' / '+ pcategory.discipline_name end as Process
			, a.rfq_created_on as RFQCreatedOn
			, a.Quotes_needed_by as QuotesNeededBy
			, a.award_date as AwardDate
			, coalesce(n.File_Name,'') as RfqThumbnail
			, count(1) over () RfqCount 			
			, rfq_pref_manufacturing_location_id	
			, mmtc.territory_classification_name as 	rfq_pref_manufacturing_location
			/* M2-2458 : Buyers - Tile and Row - Add Dates and # of Quotes on to RFQ tiles in MY RFQs  -DB */
			,(select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where a.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0) as RFQQuoteCount
		    ,(select TOP 1 status_date from mp_rfq_release_history (nolock) 
								where a.rfq_id = rfq_id and status_id = 3 and a.rfq_status_id NOT IN(1,2) 
								ORDER BY rfq_release_history_id DESC) as RFQReleaseDate
			    /**/			 				 
				/*  M2-3601 Create special invite RFQ from the community - API*/
				,case when a.IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
				/**/
			/* M2-4793 */
			,a.WithOrderManagement  
				/**/
			from  
			mp_rfq								 a		(nolock)			 
			join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id	
				and a.contact_id =  @contactId 
				and a.rfq_status_id in  (3)	
				/* M2-3767 Buyer - Add Archive functions to My RFQ's- DB */
				and ISNULL(a.IsArchived,0) = @IsArchived	
				/**/	
			left join mp_special_files			 n		(nolock) on n.file_id = a.file_id
			join mp_rfq_parts rparts (nolock) on rparts.rfq_id=a.rfq_id and rparts.Is_Rfq_Part_Default=1
			join mp_parts mparts  (nolock) on mparts.part_id=rparts.part_id
			left join mp_mst_part_category pcategory (nolock) on pcategory.part_category_id=rparts.part_category_id
			/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
			left join mp_mst_part_category category (nolock) on pcategory.parent_part_category_id=category.part_category_id
			/**/
			join 
			(
				select 
					distinct
					rfq_id 
					, case
						when (select count(1) from mp_rfq_preferences (nolock) where rfq_id = a.rfq_id) > 1 then 7
						else rfq_pref_manufacturing_location_id
					end rfq_pref_manufacturing_location_id
				 from 
				 mp_rfq_preferences a (nolock)
			) mrp  on a.rfq_id = mrp.rfq_id
			/* Ewesterfield-MFG Sep 22, 2019, Is it possible to add the Region selected when creating an RFQ using cloning below the Process on the Tiles and Rows*/
			join mp_mst_territory_classification (nolock) mmtc on  mrp.rfq_pref_manufacturing_location_id = mmtc.territory_classification_id
			/**/		
			where (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
			AND mrp.rfq_pref_manufacturing_location_id = (CASE WHEN @TerritoryId = 0 THEN mrp.rfq_pref_manufacturing_location_id  ELSE @TerritoryId END) 
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.rfq_id end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.rfq_name end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.rfq_id  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.rfq_name  end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only	
	end
	/**/
	------------------------ My RFQ's (Awarded) --------------------
	/*M2-1596 Performance optimization for Buyer list - Database side*/
	else if (@rfqtype =4)
	begin

			select 
			a.rfq_id as RFQId
			, a.rfq_name as RFQName
			, a.rfq_status_id as RFQStatusId
			, k.rfq_buyerstatus_li_key as RFQStatus
			,case when category.discipline_name is null then pcategory.discipline_name when category.discipline_name = pcategory.discipline_name then pcategory.discipline_name else category.discipline_name +' / '+ pcategory.discipline_name end as Process
			, a.rfq_created_on as RFQCreatedOn
			, a.Quotes_needed_by as QuotesNeededBy
			, a.award_date as AwardDate
			, coalesce(n.File_Name,'') as RfqThumbnail
			, count(1) over () RfqCount 	
			, rfq_pref_manufacturing_location_id	
			, mmtc.territory_classification_name as 	rfq_pref_manufacturing_location
			/* M2-2458 : Buyers - Tile and Row - Add Dates and # of Quotes on to RFQ tiles in MY RFQs  -DB */
			,(select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where a.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0) as RFQQuoteCount
		    ,(select TOP 1 status_date from mp_rfq_release_history (nolock) 
								where a.rfq_id = rfq_id and status_id = 3 and a.rfq_status_id NOT IN(1,2) 
								ORDER BY rfq_release_history_id DESC) as RFQReleaseDate
			    /**/			 				 	
				/*  M2-3601 Create special invite RFQ from the community - API*/
				,case when a.IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
				/**/
			/* M2-4793 */
			,a.WithOrderManagement  
			/**/
			from  
			mp_rfq								 a		(nolock)			 
			join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id	
				and a.contact_id =  @contactId 
				and a.rfq_status_id in  (6)
				/* M2-3767 Buyer - Add Archive functions to My RFQ's- DB */
				and ISNULL(a.IsArchived,0) = @IsArchived	
				/**/		
			left join mp_special_files			 n		(nolock) on n.file_id = a.file_id
			join mp_rfq_parts rparts (nolock) on rparts.rfq_id=a.rfq_id and rparts.Is_Rfq_Part_Default=1
			join mp_parts mparts  (nolock) on mparts.part_id=rparts.part_id
			left join mp_mst_part_category pcategory (nolock) on pcategory.part_category_id=rparts.part_category_id
			/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
			left join mp_mst_part_category category (nolock) on pcategory.parent_part_category_id=category.part_category_id
			/**/
			join 
			(
				select 
					distinct
					rfq_id 
					, case
						when (select count(1) from mp_rfq_preferences (nolock) where rfq_id = a.rfq_id) > 1 then 7
						else rfq_pref_manufacturing_location_id
					end rfq_pref_manufacturing_location_id
				 from 
				 mp_rfq_preferences a (nolock)
			) mrp  on a.rfq_id = mrp.rfq_id
			/* Ewesterfield-MFG Sep 22, 2019, Is it possible to add the Region selected when creating an RFQ using cloning below the Process on the Tiles and Rows*/
			join mp_mst_territory_classification (nolock) mmtc on  mrp.rfq_pref_manufacturing_location_id = mmtc.territory_classification_id
			/**/
		where (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
		AND mrp.rfq_pref_manufacturing_location_id = (CASE WHEN @TerritoryId = 0 THEN mrp.rfq_pref_manufacturing_location_id  ELSE @TerritoryId END) 
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.rfq_id end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.rfq_name end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.rfq_id  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.rfq_name  end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only	
	end
	/**/
	------------------------ My RFQ's (Pending Approval) --------------------
	/*M2-1596 Performance optimization for Buyer list - Database side*/
	else if (@rfqtype =5)
	begin

			select 
			a.rfq_id as RFQId
			, a.rfq_name as RFQName
			, a.rfq_status_id as RFQStatusId
			, k.rfq_buyerstatus_li_key as RFQStatus
			,case when category.discipline_name is null then pcategory.discipline_name when category.discipline_name = pcategory.discipline_name then pcategory.discipline_name else category.discipline_name +' / '+ pcategory.discipline_name end as Process
			, a.rfq_created_on as RFQCreatedOn
			, a.Quotes_needed_by as QuotesNeededBy
			, a.award_date as AwardDate
			, coalesce(n.File_Name,'') as RfqThumbnail
			, count(1) over () RfqCount 
			, rfq_pref_manufacturing_location_id	
			, mmtc.territory_classification_name as 	rfq_pref_manufacturing_location
			/* M2-2458 : Buyers - Tile and Row - Add Dates and # of Quotes on to RFQ tiles in MY RFQs  -DB */
			,(select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where a.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0) as RFQQuoteCount
		    ,(select TOP 1 status_date from mp_rfq_release_history (nolock) 
								where a.rfq_id = rfq_id and status_id = 3 and a.rfq_status_id NOT IN(1,2) 
								ORDER BY rfq_release_history_id DESC) as RFQReleaseDate
			    /**/			 			 							
			/*  M2-3601 Create special invite RFQ from the community - API*/
			,case when a.IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
			/**/
			/* M2-4793 */
			,a.WithOrderManagement  
			/**/
			from  
			mp_rfq								 a		(nolock)			 
			join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id	
				and a.contact_id =  @contactId 
				and a.rfq_status_id in  (2)		
				/* M2-3767 Buyer - Add Archive functions to My RFQ's- DB */
				and ISNULL(a.IsArchived,0) = @IsArchived	
				/**/
			left join mp_special_files			 n		(nolock) on n.file_id = a.file_id
			/* Beau Martin   01/24/2023 RFQs 1189067, 1189068, 1189069 were found in HubSpot as "pending approval" status. */
			left join mp_rfq_parts rparts (nolock) on rparts.rfq_id=a.rfq_id and rparts.Is_Rfq_Part_Default=1
			left join mp_parts mparts  (nolock) on mparts.part_id=rparts.part_id
			/**/
			left join mp_mst_part_category pcategory (nolock) on pcategory.part_category_id=rparts.part_category_id
			/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
			left join mp_mst_part_category category (nolock) on pcategory.parent_part_category_id=category.part_category_id
			/**/
			join 
			(
				select 
					distinct
					rfq_id 
					, case
						when (select count(1) from mp_rfq_preferences (nolock) where rfq_id = a.rfq_id) > 1 then 7
						else rfq_pref_manufacturing_location_id
					end rfq_pref_manufacturing_location_id
				 from 
				 mp_rfq_preferences a (nolock)
			) mrp  on a.rfq_id = mrp.rfq_id
			/* Ewesterfield-MFG Sep 22, 2019, Is it possible to add the Region selected when creating an RFQ using cloning below the Process on the Tiles and Rows*/
			join mp_mst_territory_classification (nolock) mmtc on  mrp.rfq_pref_manufacturing_location_id = mmtc.territory_classification_id
			/**/
		
		where (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
		AND mrp.rfq_pref_manufacturing_location_id = (CASE WHEN @TerritoryId = 0 THEN mrp.rfq_pref_manufacturing_location_id  ELSE @TerritoryId END) 
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.rfq_id end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.rfq_name end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.rfq_id  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.rfq_name  end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only	
	end
	/**/
------------------------ My RFQ's (Closed) --------------------
	/*M2-1596 Performance optimization for Buyer list - Database side*/
	else if (@rfqtype =6)
	begin

			select 
			a.rfq_id as RFQId
			, a.rfq_name as RFQName
			, a.rfq_status_id as RFQStatusId
			, k.rfq_buyerstatus_li_key as RFQStatus
			,case when category.discipline_name is null then pcategory.discipline_name when category.discipline_name = pcategory.discipline_name then pcategory.discipline_name else category.discipline_name +' / '+ pcategory.discipline_name end as Process
			, a.rfq_created_on as RFQCreatedOn
			, a.Quotes_needed_by as QuotesNeededBy
			, a.award_date as AwardDate
			, coalesce(n.File_Name,'') as RfqThumbnail
			, count(1) over () RfqCount
			, rfq_pref_manufacturing_location_id	
			, mmtc.territory_classification_name as 	rfq_pref_manufacturing_location
			/* M2-2458 : Buyers - Tile and Row - Add Dates and # of Quotes on to RFQ tiles in MY RFQs  -DB */
			,(select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where a.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0) as RFQQuoteCount
		    ,(select TOP 1 status_date from mp_rfq_release_history (nolock) 
								where a.rfq_id = rfq_id and status_id = 3 and a.rfq_status_id NOT IN(1,2) 
								ORDER BY rfq_release_history_id DESC) as RFQReleaseDate
			    /**/			 				 		 			
			/*  M2-3601 Create special invite RFQ from the community - API*/
			,case when a.IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
			/**/
			/* M2-4793 */
			,a.WithOrderManagement  
			/**/
		from  
			mp_rfq								 a		(nolock)			 
			join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id	
				and a.contact_id =  @contactId 
				and a.rfq_status_id in  (5)
				/* M2-3767 Buyer - Add Archive functions to My RFQ's- DB */
				and ISNULL(a.IsArchived,0) = @IsArchived	
				/**/		
			left join mp_special_files			 n		(nolock) on n.file_id = a.file_id
			join mp_rfq_parts rparts (nolock) on rparts.rfq_id=a.rfq_id and rparts.Is_Rfq_Part_Default=1
			join mp_parts mparts  (nolock) on mparts.part_id=rparts.part_id
			left join mp_mst_part_category pcategory (nolock) on pcategory.part_category_id=rparts.part_category_id
			/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
			left join mp_mst_part_category category (nolock) on pcategory.parent_part_category_id=category.part_category_id
			/**/
			join 
			(
				select 
					distinct
					rfq_id 
					, case
						when (select count(1) from mp_rfq_preferences (nolock) where rfq_id = a.rfq_id) > 1 then 7
						else rfq_pref_manufacturing_location_id
					end rfq_pref_manufacturing_location_id
				 from 
				 mp_rfq_preferences a (nolock)
			) mrp  on a.rfq_id = mrp.rfq_id
			/* Ewesterfield-MFG Sep 22, 2019, Is it possible to add the Region selected when creating an RFQ using cloning below the Process on the Tiles and Rows*/
			join mp_mst_territory_classification (nolock) mmtc on  mrp.rfq_pref_manufacturing_location_id = mmtc.territory_classification_id
			/**/
		
		where (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
		AND mrp.rfq_pref_manufacturing_location_id = (CASE WHEN @TerritoryId = 0 THEN mrp.rfq_pref_manufacturing_location_id  ELSE @TerritoryId END) 
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.rfq_id end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.rfq_name end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.rfq_id  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.rfq_name  end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only	
	end
	/**/

	------------------------ My RFQ's (Deleted)--------------------
	/*M2-1596 Performance optimization for Buyer list - Database side*/
	else if (@rfqtype =8)
	begin

		select 
			a.rfq_id as RFQId
			, a.rfq_name as RFQName
			, a.rfq_status_id as RFQStatusId
			, k.rfq_buyerstatus_li_key as RFQStatus
			,case when category.discipline_name is null then pcategory.discipline_name when category.discipline_name = pcategory.discipline_name then pcategory.discipline_name else category.discipline_name +' / '+ pcategory.discipline_name end as Process
			, a.rfq_created_on as RFQCreatedOn
			, a.Quotes_needed_by as QuotesNeededBy
			, a.award_date as AwardDate
			, coalesce(n.File_Name,'') as RfqThumbnail
			, count(1) over () RfqCount
			, rfq_pref_manufacturing_location_id	
			, mmtc.territory_classification_name as 	rfq_pref_manufacturing_location
			/* M2-2458 : Buyers - Tile and Row - Add Dates and # of Quotes on to RFQ tiles in MY RFQs  -DB */
			,(select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where a.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0) as RFQQuoteCount
			,(select TOP 1 status_date from mp_rfq_release_history (nolock) 
								where a.rfq_id = rfq_id and status_id = 3 and a.rfq_status_id NOT IN(1,2)  
								ORDER BY rfq_release_history_id DESC) as RFQReleaseDate
			    /**/				 		 
			/*  M2-3601 Create special invite RFQ from the community - API*/
			,case when a.IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
			/**/
			/* M2-4793 */
			,a.WithOrderManagement  
			/**/
		from  
			mp_rfq								 a		(nolock)			 
			join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id	
				and a.contact_id =  @contactId 
				and a.rfq_status_id  in (13)	
			left join mp_special_files			 n		(nolock) on n.file_id = a.file_id
			left join mp_rfq_parts rparts (nolock) on rparts.rfq_id=a.rfq_id and rparts.Is_Rfq_Part_Default=1
			left join mp_parts mparts  (nolock) on mparts.part_id=rparts.part_id
			left join mp_mst_part_category pcategory (nolock) on pcategory.part_category_id=rparts.part_category_id
			/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
			left join mp_mst_part_category category (nolock) on pcategory.parent_part_category_id=category.part_category_id
			/**/
			left join 
			(
				select 
					distinct
					rfq_id 
					, case
						when (select count(1) from mp_rfq_preferences (nolock) where rfq_id = a.rfq_id) > 1 then 7
						else rfq_pref_manufacturing_location_id
					end rfq_pref_manufacturing_location_id
				 from 
				 mp_rfq_preferences a (nolock)
			) mrp  on a.rfq_id = mrp.rfq_id
			/* Ewesterfield-MFG Sep 22, 2019, Is it possible to add the Region selected when creating an RFQ using cloning below the Process on the Tiles and Rows*/
			left join mp_mst_territory_classification (nolock) mmtc on  mrp.rfq_pref_manufacturing_location_id = mmtc.territory_classification_id
			/**/
		
		where (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
		AND mrp.rfq_pref_manufacturing_location_id = (CASE WHEN @TerritoryId = 0 THEN mrp.rfq_pref_manufacturing_location_id  ELSE @TerritoryId END) 
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.rfq_id end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.rfq_name end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.rfq_id  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.rfq_name  end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only	
	end
	/**/
	------------------------ Draft RFQ's --------------------
	/*M2-1596 Performance optimization for Buyer list - Database side*/
	else if (@rfqtype =9)
	begin

		select 
			a.rfq_id as RFQId
			, a.rfq_name as RFQName
			, a.rfq_status_id as RFQStatusId
			, k.rfq_buyerstatus_li_key as RFQStatus
			, '' as Process     --for other RFQ Type we have process field in output
			, a.rfq_created_on as RFQCreatedOn
			, a.Quotes_needed_by as QuotesNeededBy
			, a.award_date as AwardDate
			, coalesce(n.File_Name,'') as RfqThumbnail
			, (select count(1) from mp_rfq_parts (nolock) where rfq_id = a.rfq_id and status_id = 2) as PartCount
			, count(1) over () RfqCount 
			, rfq_pref_manufacturing_location_id	
			, mmtc.territory_classification_name as 	rfq_pref_manufacturing_location
			/* M2-2458 : Buyers - Tile and Row - Add Dates and # of Quotes on to RFQ tiles in MY RFQs  -DB */
			,(select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where a.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0) as RFQQuoteCount
		    ,(select TOP 1 status_date from mp_rfq_release_history (nolock) 
								where a.rfq_id = rfq_id and status_id = 3 and a.rfq_status_id NOT IN(1,2) 
								ORDER BY rfq_release_history_id DESC) as RFQReleaseDate
			    /**/			 				 	
			/*  M2-3601 Create special invite RFQ from the community - API*/
			,case when a.IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
			/**/
			/* M2-4793 */
			,a.WithOrderManagement  
			/**/
		from  
			mp_rfq								 a		(nolock)
			join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id	
				and a.contact_id =  @contactId 
				and a.rfq_status_id in (1,14)				
			left join mp_special_files			 n		(nolock) on n.file_id = a.file_id
			left join 
			(
				select 
					distinct
					rfq_id 
					, case
						when (select count(1) from mp_rfq_preferences (nolock) where rfq_id = a.rfq_id) > 1 then 7
						else rfq_pref_manufacturing_location_id
					end rfq_pref_manufacturing_location_id
				 from 
				 mp_rfq_preferences a (nolock)
			) mrp  on a.rfq_id = mrp.rfq_id
			/* Ewesterfield-MFG Sep 22, 2019, Is it possible to add the Region selected when creating an RFQ using cloning below the Process on the Tiles and Rows*/
			left join mp_mst_territory_classification (nolock) mmtc on  mrp.rfq_pref_manufacturing_location_id = mmtc.territory_classification_id
			/**/
		
		where (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.rfq_id end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.rfq_name end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.rfq_id  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.rfq_name  end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only	
	end
	/**/
	------------------------ Draft RFQ's (only Draft RFQ's) --------------------
	/*M2-1596 Performance optimization for Buyer list - Database side*/
	else if (@rfqtype =10)
	begin

		select 
			a.rfq_id as RFQId
			, a.rfq_name as RFQName
			, a.rfq_status_id as RFQStatusId
			, k.rfq_buyerstatus_li_key as RFQStatus
			,'' as Process     --for other RFQ Type we have process field in output
			, a.rfq_created_on as RFQCreatedOn
			, a.Quotes_needed_by as QuotesNeededBy
			, a.award_date as AwardDate
			, coalesce(n.File_Name,'') as RfqThumbnail
			, (select count(1) from mp_rfq_parts (nolock) where rfq_id = a.rfq_id and status_id = 2) as PartCount
			, count(1) over () RfqCount 
			, rfq_pref_manufacturing_location_id	
			, mmtc.territory_classification_name as 	rfq_pref_manufacturing_location
			/* M2-2458 : Buyers - Tile and Row - Add Dates and # of Quotes on to RFQ tiles in MY RFQs  -DB */
			,(select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where a.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0) as RFQQuoteCount
		    ,(select TOP 1 status_date from mp_rfq_release_history (nolock) 
								where a.rfq_id = rfq_id and status_id = 3 and a.rfq_status_id NOT IN(1,2) 
								ORDER BY rfq_release_history_id DESC) as RFQReleaseDate
			    /**/			 				 		
			/*  M2-3601 Create special invite RFQ from the community - API*/
			,case when a.IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
			/**/
			/* M2-4793 */
			,a.WithOrderManagement  
			/**/
		from  
			mp_rfq								 a		(nolock)
			join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id	
				and a.contact_id =  @contactId 
				and a.rfq_status_id in (1)				
			left join mp_special_files			 n		(nolock) on n.file_id = a.file_id
			left join 
			(
				select 
					distinct
					rfq_id 
					, case
						when (select count(1) from mp_rfq_preferences (nolock) where rfq_id = a.rfq_id) > 1 then 7
						else rfq_pref_manufacturing_location_id
					end rfq_pref_manufacturing_location_id
				 from 
				 mp_rfq_preferences a (nolock)
			) mrp  on a.rfq_id = mrp.rfq_id
			/* Ewesterfield-MFG Sep 22, 2019, Is it possible to add the Region selected when creating an RFQ using cloning below the Process on the Tiles and Rows*/
			left join mp_mst_territory_classification (nolock) mmtc on  mrp.rfq_pref_manufacturing_location_id = mmtc.territory_classification_id
			/**/
		
		where (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.rfq_id end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.rfq_name end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.rfq_id  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.rfq_name  end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only	
	end
	/**/
	------------------------ Draft RFQ's (In-complete) --------------------
	/*M2-1596 Performance optimization for Buyer list - Database side*/
	else if (@rfqtype =11)
	begin

		select 
			a.rfq_id as RFQId
			, a.rfq_name as RFQName
			, a.rfq_status_id as RFQStatusId
			, k.rfq_buyerstatus_li_key as RFQStatus
			,'' as Process     --for other RFQ Type we have process field in output
			, a.rfq_created_on as RFQCreatedOn
			, a.Quotes_needed_by as QuotesNeededBy
			, a.award_date as AwardDate
			, coalesce(n.File_Name,'') as RfqThumbnail
			, (select count(1) from mp_rfq_parts (nolock) where rfq_id = a.rfq_id and status_id = 2) as PartCount
			, 	count(1) over () RfqCount 
			, rfq_pref_manufacturing_location_id	
			, mmtc.territory_classification_name as 	rfq_pref_manufacturing_location
			/* M2-2458 : Buyers - Tile and Row - Add Dates and # of Quotes on to RFQ tiles in MY RFQs  -DB */
			,(select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where a.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0) as RFQQuoteCount
		    ,(select TOP 1 status_date from mp_rfq_release_history (nolock) 
								where a.rfq_id = rfq_id and status_id = 3 and a.rfq_status_id NOT IN(1,2) 
								ORDER BY rfq_release_history_id DESC) as RFQReleaseDate
			    /**/			 				 		
			/*  M2-3601 Create special invite RFQ from the community - API*/
			,case when a.IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
			/**/
			/* M2-4793 */
			,a.WithOrderManagement  
			/**/
		from  
			mp_rfq								 a		(nolock)
			join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id	
				and a.contact_id =  @contactId 
				and a.rfq_status_id in (14)				
			left join mp_special_files			 n		(nolock) on n.file_id = a.file_id
			left join 
			(
				select 
					distinct
					rfq_id 
					, case
						when (select count(1) from mp_rfq_preferences (nolock) where rfq_id = a.rfq_id) > 1 then 7
						else rfq_pref_manufacturing_location_id
					end rfq_pref_manufacturing_location_id
				 from 
				 mp_rfq_preferences a (nolock)
			) mrp  on a.rfq_id = mrp.rfq_id
			/* Ewesterfield-MFG Sep 22, 2019, Is it possible to add the Region selected when creating an RFQ using cloning below the Process on the Tiles and Rows*/
			left join mp_mst_territory_classification (nolock) mmtc on  mrp.rfq_pref_manufacturing_location_id = mmtc.territory_classification_id
			/**/
		
		where (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.rfq_id end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.rfq_name end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.rfq_id  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.rfq_name  end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only	
	end
	/**/
	------------------------ Active Rfq --------------------
	else if (@RfqType = 3)	
	begin	
		 SELECT distinct
			mp_rfq.rfq_id AS RFQId
			, mp_rfq.rfq_name AS RFQName			
			, mp_rfq.rfq_status_id as RFQStatusId
			, mp_special_files.file_name AS file_name
			, floor(mp_rfq_parts.min_part_quantity)  AS Quantity			 
			, mp_rfq_parts.min_part_quantity_unit AS UnitValue
			, Processes.value AS PostProductionProcessValue
			, mp_mst_materials.material_name_en  AS Material
			, case when category.discipline_name is null then mp_mst_part_category.discipline_name  when category.discipline_name = mp_mst_part_category.discipline_name then mp_mst_part_category.discipline_name else category.discipline_name +' / '+ mp_mst_part_category.discipline_name end  AS Process
			, mp_companies.name AS Buyer
			, mp_mst_rfq_buyerStatus.rfq_buyerstatus_li_key AS RFQStatus
			, mp_rfq.rfq_created_on AS RFQCreatedOn
			, mp_rfq.Quotes_needed_by AS QuotesNeededBy
			, mp_rfq.award_date AS AwardDate
			, rfq_likes.is_rfq_like AS IsRfqLike
			, mp_star_rating.no_of_stars AS NoOfStars
			, COALESCE(ThumbnailFile.File_Name,'') AS RfqThumbnail	
			, mp_rfq.payment_term_id AS payment_term_id	
			, rfq_pref_manufacturing_location_id	
			, mmtc.territory_classification_name as 	rfq_pref_manufacturing_location
			/* M2-2458 : Buyers - Tile and Row - Add Dates and # of Quotes on to RFQ tiles in MY RFQs  -DB */
			,(select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where mp_rfq.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0) as RFQQuoteCount
		    ,(select TOP 1 status_date from mp_rfq_release_history (nolock) 
								where mp_rfq.rfq_id = rfq_id and status_id = 3 and mp_rfq.rfq_status_id NOT IN(1,2) 
								ORDER BY rfq_release_history_id DESC) as RFQReleaseDate
			    /**/			 
							 				 
			/*  M2-3601 Create special invite RFQ from the community - API*/
			,case when IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
			/**/
			/* M2-4793 */
			,mp_rfq.WithOrderManagement  
			/**/
		FROM  mp_rfq (NOLOCK)
			 LEFT JOIN (select * from mp_rfq_supplier_likes where contact_id = @ContactId ) AS rfq_likes 				ON mp_rfq.rfq_id = rfq_likes.rfq_id
			 LEFT JOIN mp_special_files AS ThumbnailFile ON ThumbnailFile.file_id = mp_rfq.file_id
			 JOIN mp_contacts ON mp_rfq.contact_id=mp_contacts.contact_id
			 LEFT JOIN mp_star_rating ON mp_star_rating.company_id = mp_contacts.company_id
			 JOIN mp_companies ON mp_contacts.company_id=mp_companies.company_id
			 JOIN mp_mst_rfq_buyerStatus ON mp_rfq.rfq_status_id=mp_mst_rfq_buyerStatus.rfq_buyerstatus_id
			 
			 JOIN mp_rfq_parts ON mp_rfq.rfq_id = mp_rfq_parts.rfq_id and Is_Rfq_Part_Default =  1
			 JOIN mp_rfq_parts_file ON mp_rfq_parts.rfq_part_id = mp_rfq_parts_file.rfq_part_id
			 JOIN mp_special_files ON mp_special_files.file_id = mp_rfq_parts_file.file_id
			 JOIN mp_rfq_part_quantity ON mp_rfq_part_quantity.rfq_part_id = mp_rfq_parts.rfq_part_id
			 LEFT JOIN mp_system_parameters AS Processes ON Processes.id = mp_rfq_parts.Post_Production_Process_id AND Processes.sys_key = '@PostProdProcesses' 

			 JOIN mp_parts ON mp_parts.part_id = mp_rfq_parts.part_id 
			 LEFT JOIN mp_mst_materials ON mp_mst_materials.material_id = mp_rfq_parts.material_id
			 
			 LEFT JOIN mp_system_parameters AS Unit ON Unit.id = mp_parts.part_qty_unit_id AND Unit.sys_key = '@UNIT2_LIST' AND Unit.sys_key = '@UNIT2_LIST' 
			 JOIN mp_mst_part_category ON mp_mst_part_category.part_category_id = mp_rfq_parts.part_category_id 
			/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
			left join mp_mst_part_category category (nolock) on mp_mst_part_category.parent_part_category_id=category.part_category_id
			/**/
			
			
			join 
			(
				select 
					distinct
					rfq_id 
					, case
						when (select count(1) from mp_rfq_preferences (nolock) where rfq_id = a.rfq_id) > 1 then 7
						else rfq_pref_manufacturing_location_id
					end rfq_pref_manufacturing_location_id
				 from 
				 mp_rfq_preferences a (nolock)
			) mrp  on mp_rfq.rfq_id = mrp.rfq_id
			/* Ewesterfield-MFG Sep 22, 2019, Is it possible to add the Region selected when creating an RFQ using cloning below the Process on the Tiles and Rows*/
			join mp_mst_territory_classification (nolock) mmtc on  mrp.rfq_pref_manufacturing_location_id = mmtc.territory_classification_id
			/**/
		
		WHERE 			 			 			 
			 mp_rfq_parts_file.is_primary_file = 1 
			 AND mp_rfq.rfq_status_id >= 2
			 AND mp_rfq.rfq_status_id NOT IN (13)
			 AND mp_rfq.contact_Id = @contactId
		ORDER BY RFQCreatedOn DESC

	end
	------------------------Rfq Marked for Quoting --------------------
	else if (@RfqType = 12)	
	begin	
		 SELECT DISTINCT 
			mp_rfq.rfq_id AS RFQId
			, mp_rfq.rfq_name AS RFQName				 
			, mp_rfq.rfq_status_id as RFQStatusId
			, mp_special_files.file_name AS file_name
			, floor(mp_rfq_parts.min_part_quantity)  AS Quantity			 
			, mp_rfq_parts.min_part_quantity_unit AS UnitValue
			, Processes.value AS PostProductionProcessValue
			, mp_mst_materials.material_name_en AS Material
			, case  when category.discipline_name is null then mp_mst_part_category.discipline_name when category.discipline_name = mp_mst_part_category.discipline_name then mp_mst_part_category.discipline_name else category.discipline_name +' / '+ mp_mst_part_category.discipline_name end  AS Process
			, mp_companies.name AS Buyer
			, mp_mst_rfq_buyerStatus.rfq_buyerstatus_li_key AS RFQStatus
			, mp_rfq.rfq_created_on AS RFQCreatedOn
			, mp_rfq.Quotes_needed_by AS QuotesNeededBy
			, mp_rfq.award_date AS AwardDate
			, rfq_likes.is_rfq_like AS IsRfqLike
			, mp_star_rating.no_of_stars AS NoOfStars
			, COALESCE(ThumbnailFile.File_Name,'') AS RfqThumbnail	
			, mp_rfq.payment_term_id AS payment_term_id	
			, rfq_pref_manufacturing_location_id
			, mmtc.territory_classification_name as 	rfq_pref_manufacturing_location
			/* M2-2458 : Buyers - Tile and Row - Add Dates and # of Quotes on to RFQ tiles in MY RFQs  -DB */
			,(select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where mp_rfq.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0) as RFQQuoteCount
		    ,(select TOP 1 status_date from mp_rfq_release_history (nolock) 
								where mp_rfq.rfq_id = rfq_id and status_id = 3 and mp_rfq.rfq_status_id NOT IN(1,2) 
								ORDER BY rfq_release_history_id DESC) as RFQReleaseDate
			    /**/						 			 
			/*  M2-3601 Create special invite RFQ from the community - API*/
			,case when IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
			/**/
			/* M2-4793 */
			,mp_rfq.WithOrderManagement  
			/**/
		FROM  mp_rfq (NOLOCK)
			 LEFT JOIN (select * from mp_rfq_supplier_likes where contact_id = @ContactId ) AS rfq_likes 				ON mp_rfq.rfq_id = rfq_likes.rfq_id
			 LEFT JOIN mp_special_files AS ThumbnailFile ON ThumbnailFile.file_id = mp_rfq.file_id
			 JOIN mp_contacts ON mp_rfq.contact_id=mp_contacts.contact_id
			 LEFT JOIN mp_star_rating ON mp_star_rating.company_id = mp_contacts.company_id
			 JOIN mp_companies ON mp_contacts.company_id=mp_companies.company_id
			 JOIN mp_mst_rfq_buyerStatus ON mp_rfq.rfq_status_id=mp_mst_rfq_buyerStatus.rfq_buyerstatus_id
			 JOIN mp_rfq_parts ON mp_rfq.rfq_id = mp_rfq_parts.rfq_id  and Is_Rfq_Part_Default =  1
			 JOIN mp_rfq_parts_file ON mp_rfq_parts.rfq_part_id = mp_rfq_parts_file.rfq_part_id
			 LEFT JOIN mp_special_files ON mp_special_files.file_id = mp_rfq_parts_file.file_id
			 JOIN mp_rfq_part_quantity ON mp_rfq_part_quantity.rfq_part_id = mp_rfq_parts.rfq_part_id
			 LEFT JOIN mp_system_parameters AS Processes ON Processes.id = mp_rfq_parts.Post_Production_Process_id AND Processes.sys_key = '@PostProdProcesses' 

			 JOIN mp_parts ON mp_parts.part_id = mp_rfq_parts.part_id 
			 LEFT JOIN mp_mst_materials ON mp_mst_materials.material_id = mp_rfq_parts.material_id
			 
			 LEFT JOIN mp_system_parameters AS Unit ON Unit.id = mp_parts.part_qty_unit_id AND Unit.sys_key = '@UNIT2_LIST' AND Unit.sys_key = '@UNIT2_LIST' 
			 JOIN mp_mst_part_category ON mp_mst_part_category.part_category_id = mp_rfq_parts.part_category_id 
			 /* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
			left join mp_mst_part_category category (nolock) on mp_mst_part_category.parent_part_category_id=category.part_category_id
			/**/
			JOIN mp_rfq_quote_suplierStatuses ON mp_rfq_parts.rfq_id=mp_rfq_quote_suplierStatuses.rfq_id
			join 
			(
				select 
					distinct
					rfq_id 
					, case
						when (select count(1) from mp_rfq_preferences (nolock) where rfq_id = a.rfq_id) > 1 then 7
						else rfq_pref_manufacturing_location_id
					end rfq_pref_manufacturing_location_id
				 from 
				 mp_rfq_preferences a (nolock)
			) mrp  on mp_rfq.rfq_id = mrp.rfq_id	
			/* Ewesterfield-MFG Sep 22, 2019, Is it possible to add the Region selected when creating an RFQ using cloning below the Process on the Tiles and Rows*/
			join mp_mst_territory_classification (nolock) mmtc on  mrp.rfq_pref_manufacturing_location_id = mmtc.territory_classification_id
			/**/
				 
		WHERE 			 			 			 
			 mp_rfq.contact_Id = @contactId
			 AND mp_rfq_parts_file.is_primary_file = 1 
			 AND mp_rfq.rfq_status_id = 3			
			 AND mp_rfq_quote_suplierStatuses.rfq_userStatus_id=2
		ORDER BY RFQCreatedOn DESC

	end
	------------------------ My RFQ's (with no Quotes) --------------------
	/*M2-1596 Performance optimization for Buyer list - Database side*/
	else if (@RfqType = 13)	
	begin

		 select 
			a.rfq_id as RFQId
			, a.rfq_name as RFQName
			, a.rfq_status_id as RFQStatusId
			, k.rfq_buyerstatus_li_key as RFQStatus
			, case  when category.discipline_name is null then pcategory.discipline_name  when category.discipline_name = pcategory.discipline_name then pcategory.discipline_name else category.discipline_name +' / '+ pcategory.discipline_name end  as Process
			, a.rfq_created_on as RFQCreatedOn
			, a.Quotes_needed_by as QuotesNeededBy
			, a.award_date as AwardDate
			, coalesce(n.File_Name,'') as RfqThumbnail			
			, count(1) over () RfqCount 
			, rfq_pref_manufacturing_location_id
			, mmtc.territory_classification_name as 	rfq_pref_manufacturing_location
			/* M2-2458 : Buyers - Tile and Row - Add Dates and # of Quotes on to RFQ tiles in MY RFQs  -DB */
			,(select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where a.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0) as RFQQuoteCount
		    ,(select TOP 1 status_date from mp_rfq_release_history (nolock) 
								where a.rfq_id = rfq_id and status_id = 3 and a.rfq_status_id NOT IN(1,2) 
								ORDER BY rfq_release_history_id DESC) as RFQReleaseDate
			    /**/			 				 	
			/*  M2-3601 Create special invite RFQ from the community - API*/
			,case when IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
			/**/
			/* M2-4793 */
			,a.WithOrderManagement  
			/**/
		from  mp_rfq							 a		(nolock)
		join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id			
			and a.contact_id =  @contactId 
			and a.rfq_status_id in  (3,5)	
			/* M2-3767 Buyer - Add Archive functions to My RFQ's- DB */
			and ISNULL(a.IsArchived,0) = @IsArchived	
			/**/
		left join mp_special_files			 n		(nolock) on n.file_id = a.file_id
		join mp_rfq_parts rparts (nolock) on rparts.rfq_id=a.rfq_id and rparts.Is_Rfq_Part_Default=1
		join mp_parts mparts  (nolock) on mparts.part_id=rparts.part_id
		left join mp_mst_part_category pcategory (nolock) on pcategory.part_category_id=rparts.part_category_id
		/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
		left join mp_mst_part_category category (nolock) on pcategory.parent_part_category_id=category.part_category_id
		/**/
		JOIN mp_rfq_quote_suplierStatuses ON rparts.rfq_id=mp_rfq_quote_suplierStatuses.rfq_id
		/**/
		left join 
			(
				select rfq_id , sum(convert(int,is_quote_submitted))  quote_received
				from mp_rfq_quote_SupplierQuote (nolock) 
				where is_rfq_resubmitted = 0
				group by rfq_id
			) d		 on a.rfq_id = d.rfq_id 		
		join 
		(
				select 
					distinct
					rfq_id 
					, case
						when (select count(1) from mp_rfq_preferences (nolock) where rfq_id = a.rfq_id) > 1 then 7
						else rfq_pref_manufacturing_location_id
					end rfq_pref_manufacturing_location_id
				 from 
				 mp_rfq_preferences a (nolock)
		) mrp  on a.rfq_id = mrp.rfq_id		
		/* Ewesterfield-MFG Sep 22, 2019, Is it possible to add the Region selected when creating an RFQ using cloning below the Process on the Tiles and Rows*/
		join mp_mst_territory_classification (nolock) mmtc on  mrp.rfq_pref_manufacturing_location_id = mmtc.territory_classification_id
		/**/
		
		where   
		(d.quote_received is null or quote_received = 0 )
		and (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.rfq_id end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.rfq_name end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.rfq_id  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.rfq_name  end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only

	end
	/**/
	------------------------ My RFQ's (with Quotes) --------------------
	/*M2-1596 Performance optimization for Buyer list - Database side*/
	else if (@RfqType = 14)	
	begin

		 select 
			a.rfq_id as RFQId
			, a.rfq_name as RFQName
			, a.rfq_status_id as RFQStatusId
			, k.rfq_buyerstatus_li_key as RFQStatus
			, case  when category.discipline_name is null then pcategory.discipline_name when category.discipline_name = pcategory.discipline_name then pcategory.discipline_name else category.discipline_name +' / '+ pcategory.discipline_name end  as Process
			, a.rfq_created_on as RFQCreatedOn
			, a.Quotes_needed_by as QuotesNeededBy
			, a.award_date as AwardDate
			, coalesce(n.File_Name,'') as RfqThumbnail			
			, count(1) over () RfqCount 
			, rfq_pref_manufacturing_location_id	
			, mmtc.territory_classification_name as 	rfq_pref_manufacturing_location
			/* M2-2458 : Buyers - Tile and Row - Add Dates and # of Quotes on to RFQ tiles in MY RFQs  -DB */
			,(select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where a.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0) as RFQQuoteCount
		    ,(select TOP 1 status_date from mp_rfq_release_history (nolock) 
								where a.rfq_id = rfq_id and status_id = 3 and a.rfq_status_id NOT IN(1,2) 
								ORDER BY rfq_release_history_id DESC) as RFQReleaseDate
			    /**/			 			 
			/*  M2-3601 Create special invite RFQ from the community - API*/
			,case when IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
			/**/
			/* M2-4793 */
			,a.WithOrderManagement  
			/**/
		from  mp_rfq							 a		(nolock)
		join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id			
			and a.contact_id =  @contactId
			/* M2-3767 Buyer - Add Archive functions to My RFQ's- DB */
			and ISNULL(a.IsArchived,0) = @IsArchived	
			/**/ 
		--	and a.rfq_status_id in  (3,5)	
		left join mp_special_files			 n		(nolock) on n.file_id = a.file_id
		join mp_rfq_parts rparts (nolock) on rparts.rfq_id=a.rfq_id and rparts.Is_Rfq_Part_Default=1
		join mp_parts mparts  (nolock) on mparts.part_id=rparts.part_id
		left join mp_mst_part_category pcategory (nolock) on pcategory.part_category_id=rparts.part_category_id
		/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
		left join mp_mst_part_category category (nolock) on pcategory.parent_part_category_id=category.part_category_id
		/**/
		join 
			(
				select rfq_id , sum(convert(int,is_quote_submitted))  quote_received
				from mp_rfq_quote_SupplierQuote (nolock) 
				where is_rfq_resubmitted = 0
				group by rfq_id
			) d		 on a.rfq_id = d.rfq_id 		
		join 
		(
			select 
				distinct
				rfq_id 
				, case
					when (select count(1) from mp_rfq_preferences (nolock) where rfq_id = a.rfq_id) > 1 then 7
					else rfq_pref_manufacturing_location_id
				end rfq_pref_manufacturing_location_id
				from 
				mp_rfq_preferences a (nolock)
		) mrp  on a.rfq_id = mrp.rfq_id
		/* Ewesterfield-MFG Sep 22, 2019, Is it possible to add the Region selected when creating an RFQ using cloning below the Process on the Tiles and Rows*/
		join mp_mst_territory_classification (nolock) mmtc on  mrp.rfq_pref_manufacturing_location_id = mmtc.territory_classification_id
		/**/
		
		where   
		(d.quote_received > 0 )
		and (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.rfq_id end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.rfq_name end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.rfq_id  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.rfq_name  end asc   	  
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only
	end
	/**/
	------------------------ My RFQ's (Active)--------------------
	/*M2-1596 Performance optimization for Buyer list - Database side*/
	else if (@rfqtype =7)
	begin

		select * from
		(
		select distinct 
			a.rfq_id as RFQId
			, a.rfq_name as RFQName
			, '' AS file_name
			, floor(rparts.min_part_quantity)  AS Quantity			 
			, rparts.min_part_quantity_unit AS UnitValue
			, Processes.value AS PostProductionProcessValue
			, mp_mst_materials.material_name_en  AS Material
			, case when category.discipline_name is null then pcategory.discipline_name  when category.discipline_name = pcategory.discipline_name then pcategory.discipline_name else category.discipline_name +' / '+ pcategory.discipline_name end  as Process
			, mp_companies.name AS Buyer
			, a.rfq_status_id as RFQStatusId
			, k.rfq_buyerstatus_li_key as RFQStatus
			, rfq_likes.is_rfq_like AS IsRfqLike
			, mp_star_rating.no_of_stars AS NoOfStars
			, a.payment_term_id AS payment_term_id				
			, a.rfq_created_on as RFQCreatedOn
			, a.Quotes_needed_by as QuotesNeededBy
			, a.award_date as AwardDate
			, coalesce(n.File_Name,'') as RfqThumbnail
			, count(1) over () RfqCount 
			, rfq_pref_manufacturing_location_id	
			, mmtc.territory_classification_name as 	rfq_pref_manufacturing_location
			/* M2-2458 : Buyers - Tile and Row - Add Dates and # of Quotes on to RFQ tiles in MY RFQs  -DB */
			,(select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where a.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0) as RFQQuoteCount
		    ,(select TOP 1 status_date from mp_rfq_release_history (nolock) 
								where a.rfq_id = rfq_id and status_id = 3 and a.rfq_status_id NOT IN(1,2) 
								ORDER BY rfq_release_history_id DESC) as RFQReleaseDate
			    /**/			 	
			/*  M2-3601 Create special invite RFQ from the community - API*/
			,case when IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
			/**/
			/* M2-4793 */
			,a.WithOrderManagement  
			/**/
		from  
			mp_rfq								 a		(nolock)
			join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id	
				--and a.rfq_id = 1152672
				and a.contact_id =  @contactId 
				and a.rfq_status_id > 2
				and a.rfq_status_id not in(5,13,14)	
				and format(a.quotes_needed_by,'yyyyMMdd') >= format(@currentdate,'yyyyMMdd')
				/* M2-3767 Buyer - Add Archive functions to My RFQ's- DB */
				and ISNULL(a.IsArchived,0) = @IsArchived	
				/**/ 
			left join mp_special_files			 n		(nolock) on n.file_id = a.file_id
			join mp_rfq_parts rparts (nolock) on rparts.rfq_id=a.rfq_id and rparts.Is_Rfq_Part_Default=1
			join mp_parts mparts  (nolock) on mparts.part_id=rparts.part_id
			join mp_rfq_parts_file (nolock) on rparts.rfq_part_id = mp_rfq_parts_file.rfq_part_id
			left join mp_mst_part_category pcategory (nolock) on pcategory.part_category_id=rparts.part_category_id
			/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
			left join mp_mst_part_category category (nolock) on pcategory.parent_part_category_id=category.part_category_id
			/**/
			--join mp_special_files (nolock)  on mp_special_files.file_id = mp_rfq_parts_file.file_id
			left join mp_system_parameters (nolock)  as Processes on Processes.id = rparts.Post_Production_Process_id AND Processes.sys_key = '@PostProdProcesses'
			left join mp_mst_materials (nolock)  on mp_mst_materials.material_id = mparts.material_id 
			join mp_contacts (nolock)   on a.contact_id=mp_contacts.contact_id
			join mp_companies (nolock)   on mp_contacts.company_id=mp_companies.company_id
			left join (select * from mp_rfq_supplier_likes (nolock)  where contact_id = @contactId ) as rfq_likes on a.rfq_id = rfq_likes.rfq_id
			left join mp_star_rating (nolock)  on mp_star_rating.company_id = mp_contacts.company_id
			join 
			(
				select 
					distinct
					rfq_id 
					, case
						when (select count(1) from mp_rfq_preferences (nolock) where rfq_id = a.rfq_id) > 1 then 7
						else rfq_pref_manufacturing_location_id
					end rfq_pref_manufacturing_location_id
				 from 
				 mp_rfq_preferences a (nolock)
			) mrp  on a.rfq_id = mrp.rfq_id
			/* Ewesterfield-MFG Sep 22, 2019, Is it possible to add the Region selected when creating an RFQ using cloning below the Process on the Tiles and Rows*/
			join mp_mst_territory_classification (nolock) mmtc on  mrp.rfq_pref_manufacturing_location_id = mmtc.territory_classification_id
			/**/
		
		where (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
		AND mrp.rfq_pref_manufacturing_location_id = (CASE WHEN @TerritoryId = 0 THEN mrp.rfq_pref_manufacturing_location_id  ELSE @TerritoryId END) 
		) a
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.RFQId end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.RFQName end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.RFQId  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.RFQName  end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only	
	end
	/**/
	------------------------ My RFQ's (Active with qouting)--------------------
	/*M2-1596 Performance optimization for Buyer list - Database side*/
	else if (@rfqtype =15)
	begin

		select 
			a.rfq_id as RFQId
			, a.rfq_name as RFQName
			, a.rfq_status_id as RFQStatusId
			, k.rfq_buyerstatus_li_key as RFQStatus
			, case when category.discipline_name is null then pcategory.discipline_name  when category.discipline_name = pcategory.discipline_name then pcategory.discipline_name else category.discipline_name +' / '+ pcategory.discipline_name end  as Process
			, a.rfq_created_on as RFQCreatedOn
			, a.Quotes_needed_by as QuotesNeededBy
			, a.award_date as AwardDate
			, coalesce(n.File_Name,'') as RfqThumbnail
			, count(1) over () RfqCount 			
			, rfq_pref_manufacturing_location_id	
			, mmtc.territory_classification_name as 	rfq_pref_manufacturing_location
			/* M2-2458 : Buyers - Tile and Row - Add Dates and # of Quotes on to RFQ tiles in MY RFQs  -DB */
			,(select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where a.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0) as RFQQuoteCount
		    ,(select TOP 1 status_date from mp_rfq_release_history (nolock) 
								where a.rfq_id = rfq_id and status_id = 3 and a.rfq_status_id NOT IN(1,2) 
								ORDER BY rfq_release_history_id DESC) as RFQReleaseDate
			    /**/			 			 
			/*  M2-3601 Create special invite RFQ from the community - API*/
			,case when IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
			/**/
			/* M2-4793 */
			,a.WithOrderManagement  
			/**/
		from  
			mp_rfq								 a		(nolock)
			join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id	
				and a.contact_id =  @contactId 
				and a.rfq_status_id >2 
				and a.rfq_status_id not in(5,13)	
				and format(a.quotes_needed_by,'yyyyMMdd') >= format(@currentdate,'yyyyMMdd') 
				and a.rfq_status_id  = 3
			left join mp_special_files			 n		(nolock) on n.file_id = a.file_id
			join mp_rfq_parts rparts (nolock) on rparts.rfq_id=a.rfq_id and rparts.Is_Rfq_Part_Default=1
			join mp_parts mparts  (nolock) on mparts.part_id=rparts.part_id
			left join mp_mst_part_category pcategory (nolock) on pcategory.part_category_id=rparts.part_category_id
			/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
			left join mp_mst_part_category category (nolock) on pcategory.parent_part_category_id=category.part_category_id
			/**/
			join 
			(
				select 
					distinct
					rfq_id 
					, case
						when (select count(1) from mp_rfq_preferences (nolock) where rfq_id = a.rfq_id) > 1 then 7
						else rfq_pref_manufacturing_location_id
					end rfq_pref_manufacturing_location_id
				 from 
				 mp_rfq_preferences a (nolock)
			) mrp  on a.rfq_id = mrp.rfq_id
			/* Ewesterfield-MFG Sep 22, 2019, Is it possible to add the Region selected when creating an RFQ using cloning below the Process on the Tiles and Rows*/
			join mp_mst_territory_classification (nolock) mmtc on  mrp.rfq_pref_manufacturing_location_id = mmtc.territory_classification_id
			/**/
		
		where (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
		AND mrp.rfq_pref_manufacturing_location_id = (CASE WHEN @TerritoryId = 0 THEN mrp.rfq_pref_manufacturing_location_id  ELSE @TerritoryId END) 
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.rfq_id end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.rfq_name end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.rfq_id  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.rfq_name  end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only	
	end
	/**/
	------------------------ My RFQ's (Active with awarded)--------------------
	/*M2-1596 Performance optimization for Buyer list - Database side*/
	else if (@rfqtype =16)
	begin

		select 
			a.rfq_id as RFQId
			, a.rfq_name as RFQName
			, a.rfq_status_id as RFQStatusId
			, k.rfq_buyerstatus_li_key as RFQStatus
			,'' as Process --other RFQ type has Process field in the output 
			, a.rfq_created_on as RFQCreatedOn
			, a.Quotes_needed_by as QuotesNeededBy
			, a.award_date as AwardDate
			, coalesce(n.File_Name,'') as RfqThumbnail
			, count(1) over () RfqCount 			
			, rfq_pref_manufacturing_location_id	
			, mmtc.territory_classification_name as 	rfq_pref_manufacturing_location
			/* M2-2458 : Buyers - Tile and Row - Add Dates and # of Quotes on to RFQ tiles in MY RFQs  -DB */
			,(select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where a.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0) as RFQQuoteCount
		    ,(select TOP 1 status_date from mp_rfq_release_history (nolock) 
								where a.rfq_id = rfq_id and status_id = 3 and a.rfq_status_id NOT IN(1,2) 
								ORDER BY rfq_release_history_id DESC) as RFQReleaseDate
			    /**/			 			 
			/*  M2-3601 Create special invite RFQ from the community - API*/
			,case when IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
			/**/
			/* M2-4793 */
			,a.WithOrderManagement  
			/**/
		from  
			mp_rfq								 a		(nolock)
			join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id	
				and a.contact_id =  @contactId 
				and a.rfq_status_id >2 
				and a.rfq_status_id not in(5,13)	
				and format(a.quotes_needed_by,'yyyyMMdd') >= format(@currentdate,'yyyyMMdd') 
				and a.rfq_status_id  = 6
			left join mp_special_files			 n		(nolock) on n.file_id = a.file_id
			join 
			(
				select 
					distinct
					rfq_id 
					, case
						when (select count(1) from mp_rfq_preferences (nolock) where rfq_id = a.rfq_id) > 1 then 7
						else rfq_pref_manufacturing_location_id
					end rfq_pref_manufacturing_location_id
				 from 
				 mp_rfq_preferences a (nolock)
			) mrp  on a.rfq_id = mrp.rfq_id
			/* Ewesterfield-MFG Sep 22, 2019, Is it possible to add the Region selected when creating an RFQ using cloning below the Process on the Tiles and Rows*/
			join mp_mst_territory_classification (nolock) mmtc on  mrp.rfq_pref_manufacturing_location_id = mmtc.territory_classification_id
			/**/
		
		where (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
		AND mrp.rfq_pref_manufacturing_location_id = (CASE WHEN @TerritoryId = 0 THEN mrp.rfq_pref_manufacturing_location_id  ELSE @TerritoryId END) 
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.rfq_id end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.rfq_name end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.rfq_id  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.rfq_name  end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only	
	end
	/**/
	------------------------ My RFQ's (Active with quotes)--------------------
	/*M2-1596 Performance optimization for Buyer list - Database side*/
	else if (@rfqtype =18)
	begin

		select 
			a.rfq_id as RFQId
			, a.rfq_name as RFQName
			, a.rfq_status_id as RFQStatusId
			, k.rfq_buyerstatus_li_key as RFQStatus
			, case when category.discipline_name is null then pcategory.discipline_name  when category.discipline_name = pcategory.discipline_name then pcategory.discipline_name else category.discipline_name +' / '+ pcategory.discipline_name end  as Process
			, a.rfq_created_on as RFQCreatedOn
			, a.Quotes_needed_by as QuotesNeededBy
			, a.award_date as AwardDate
			, coalesce(n.File_Name,'') as RfqThumbnail
			, count(1) over () RfqCount 			
			, rfq_pref_manufacturing_location_id	
			, mmtc.territory_classification_name as 	rfq_pref_manufacturing_location
			/* M2-2458 : Buyers - Tile and Row - Add Dates and # of Quotes on to RFQ tiles in MY RFQs  -DB */
			,(select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where a.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0) as RFQQuoteCount
		    ,(select TOP 1 status_date from mp_rfq_release_history (nolock) 
								where a.rfq_id = rfq_id and status_id = 3 and a.rfq_status_id NOT IN(1,2) 
								ORDER BY rfq_release_history_id DESC) as RFQReleaseDate
			    /**/			 			 
			/*  M2-3601 Create special invite RFQ from the community - API*/
			,case when IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
			/**/
			/* M2-4793 */
			,a.WithOrderManagement  
			/**/
		from  
		mp_rfq								 a		(nolock)
		join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id	
				and a.contact_id =  @contactId 
				and a.rfq_status_id >2 
				and a.rfq_status_id not in(5,13)	
				and format(a.quotes_needed_by,'yyyyMMdd') >= format(@currentdate,'yyyyMMdd') 

		left join mp_special_files			 n		(nolock) on n.file_id = a.file_id
		join 
			(
				select rfq_id , sum(convert(int,is_quote_submitted))  quote_received
				from mp_rfq_quote_SupplierQuote (nolock) 
				where is_rfq_resubmitted = 0
				group by rfq_id
			) d		 on a.rfq_id = d.rfq_id 
				
            join mp_rfq_parts rparts (nolock) on rparts.rfq_id=a.rfq_id and rparts.Is_Rfq_Part_Default=1
			join mp_parts mparts  (nolock) on mparts.part_id=rparts.part_id
			left join mp_mst_part_category pcategory (nolock) on pcategory.part_category_id=rparts.part_category_id
			/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
			left join mp_mst_part_category category (nolock) on pcategory.parent_part_category_id=category.part_category_id
			/**/
			join 
			(
				select 
					distinct
					rfq_id 
					, case
						when (select count(1) from mp_rfq_preferences (nolock) where rfq_id = a.rfq_id) > 1 then 7
						else rfq_pref_manufacturing_location_id
					end rfq_pref_manufacturing_location_id
				 from 
				 mp_rfq_preferences a (nolock)
			) mrp  on a.rfq_id = mrp.rfq_id
			/* Ewesterfield-MFG Sep 22, 2019, Is it possible to add the Region selected when creating an RFQ using cloning below the Process on the Tiles and Rows*/
			join mp_mst_territory_classification (nolock) mmtc on  mrp.rfq_pref_manufacturing_location_id = mmtc.territory_classification_id
			/**/
		
		where (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
		and d.quote_received > 0
		AND mrp.rfq_pref_manufacturing_location_id = (CASE WHEN @TerritoryId = 0 THEN mrp.rfq_pref_manufacturing_location_id  ELSE @TerritoryId END) 
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.rfq_id end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.rfq_name end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.rfq_id  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.rfq_name  end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only	
	end
	/**/
	------------------------ My RFQ's (Active with no quotes)--------------------
	/*M2-1596 Performance optimization for Buyer list - Database side*/
	else if (@rfqtype =17)
	begin

		select 
			a.rfq_id as RFQId
			, a.rfq_name as RFQName
			, a.rfq_status_id as RFQStatusId
			, k.rfq_buyerstatus_li_key as RFQStatus
            , case when category.discipline_name is null then pcategory.discipline_name  when category.discipline_name = pcategory.discipline_name then pcategory.discipline_name else category.discipline_name +' / '+ pcategory.discipline_name end  as Process
			, a.rfq_created_on as RFQCreatedOn
			, a.Quotes_needed_by as QuotesNeededBy
			, a.award_date as AwardDate
			, coalesce(n.File_Name,'') as RfqThumbnail
			, count(1) over () RfqCount 			
			, rfq_pref_manufacturing_location_id	
			, mmtc.territory_classification_name as 	rfq_pref_manufacturing_location
			/* M2-2458 : Buyers - Tile and Row - Add Dates and # of Quotes on to RFQ tiles in MY RFQs  -DB */
			,(select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where a.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0) as RFQQuoteCount
		    ,(select TOP 1 status_date from mp_rfq_release_history (nolock) 
								where a.rfq_id = rfq_id and status_id = 3 and a.rfq_status_id NOT IN(1,2) 
								ORDER BY rfq_release_history_id DESC) as RFQReleaseDate
			    /**/			 			 	
			/*  M2-3601 Create special invite RFQ from the community - API*/
			,case when IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
			/**/
			/* M2-4793 */
			,a.WithOrderManagement  
			/**/
		from  
		mp_rfq								 a		(nolock)
		join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id	
				and a.contact_id =  @contactId 
				and a.rfq_status_id >2 
				and a.rfq_status_id not in(5,13)	
				and format(a.quotes_needed_by,'yyyyMMdd') >= format(@currentdate,'yyyyMMdd') 
		left join mp_special_files			 n		(nolock) on n.file_id = a.file_id
		left join 
			(
				select rfq_id , sum(convert(int,is_quote_submitted))  quote_received
				from mp_rfq_quote_SupplierQuote (nolock) 
				where is_rfq_resubmitted = 0
				group by rfq_id
			) d		 on a.rfq_id = d.rfq_id 
			
           join mp_rfq_parts rparts (nolock) on rparts.rfq_id=a.rfq_id and rparts.Is_Rfq_Part_Default=1
			join mp_parts mparts  (nolock) on mparts.part_id=rparts.part_id
			left join mp_mst_part_category pcategory (nolock) on pcategory.part_category_id=rparts.part_category_id
			/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
			left join mp_mst_part_category category (nolock) on pcategory.parent_part_category_id=category.part_category_id
			/**/
			join 
			(
				select 
					distinct
					rfq_id 
					, case
						when (select count(1) from mp_rfq_preferences (nolock) where rfq_id = a.rfq_id) > 1 then 7
						else rfq_pref_manufacturing_location_id
					end rfq_pref_manufacturing_location_id
				 from 
				 mp_rfq_preferences a (nolock)
			) mrp  on a.rfq_id = mrp.rfq_id
			/* Ewesterfield-MFG Sep 22, 2019, Is it possible to add the Region selected when creating an RFQ using cloning below the Process on the Tiles and Rows*/
			join mp_mst_territory_classification (nolock) mmtc on  mrp.rfq_pref_manufacturing_location_id = mmtc.territory_classification_id
			/**/
		
		where (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
		and (d.quote_received is null or quote_received = 0 )
		AND mrp.rfq_pref_manufacturing_location_id = (CASE WHEN @TerritoryId = 0 THEN mrp.rfq_pref_manufacturing_location_id  ELSE @TerritoryId END) 
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.rfq_id end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.rfq_name end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.rfq_id  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.rfq_name  end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only	
	end
	/**/
	------------------------ My RFQ's (All Tab => RFQs to be Awarded) --------------------
	/* M2-3328 Buyer - Add RFQs to be awarded to status filter -DB */
	else if (@rfqtype =19)
	begin

		select * , count(1) over () RfqCount 
		from
		(
			select 
				distinct
				a.rfq_id as RFQId
				, a.rfq_name as RFQName
				, a.rfq_status_id as RFQStatusId
				, case 
					when rfqstobeawarded.rfq_id is null then k.rfq_buyerstatus_li_key 
					when (rfqstobeawarded.rfq_id is not null and ToBeAwardedRfqCount >= 5) then  'RFX_BUYERSTATUS_TO_BE_AWARDED' 
					else k.rfq_buyerstatus_li_key 
				  end as RFQStatus
				, case when category.discipline_name is null then pcategory.discipline_name when category.discipline_name = pcategory.discipline_name then pcategory.discipline_name else category.discipline_name +' / '+ pcategory.discipline_name end as Process
				,  a.rfq_created_on as RFQCreatedOn
				, a.Quotes_needed_by as QuotesNeededBy
				, a.award_date as AwardDate
				, coalesce(n.File_Name,'') as RfqThumbnail
				
				, rfq_pref_manufacturing_location_id	
				, mmtc.territory_classification_name as 	rfq_pref_manufacturing_location
				/* M2-2458 : Buyers - Tile and Row - Add Dates and # of Quotes on to RFQ tiles in MY RFQs  -DB */
			,(select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where a.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0) as RFQQuoteCount
		    ,(select TOP 1 status_date from mp_rfq_release_history (nolock) 
								where a.rfq_id = rfq_id and status_id = 3 and a.rfq_status_id NOT IN(1,2) 
								ORDER BY rfq_release_history_id DESC) as RFQReleaseDate
			    /**/			 		
	
			/*  M2-3601 Create special invite RFQ from the community - API*/
			,case when IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
			/**/
			/* M2-4793 */
			,a.WithOrderManagement  
			/**/
			from  
				mp_rfq								 a		(nolock)			 
				join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id	
					and a.contact_id =  @contactId 
					and a.rfq_status_id in  (5)
					and convert(date,a.award_date) <=  convert(date,getutcdate())
					/* M2-3767 Buyer - Add Archive functions to My RFQ's- DB */
					and ISNULL(a.IsArchived,0) = @IsArchived	
					/**/
				left join mp_special_files			 n		(nolock) on n.file_id = a.file_id
				join mp_rfq_parts rparts (nolock) on rparts.rfq_id=a.rfq_id and rparts.Is_Rfq_Part_Default=1
				join mp_parts mparts  (nolock) on mparts.part_id=rparts.part_id
				join mp_rfq_quote_SupplierQuote (nolock) mrqsq on a.rfq_id = mrqsq.rfq_id and  mrqsq.is_quote_submitted = 1 and mrqsq.is_rfq_resubmitted = 0
				join 
				(
					select 
						distinct
						rfq_id 
						, case
							when (select count(1) from mp_rfq_preferences (nolock) where rfq_id = a.rfq_id) > 1 then 7
							else rfq_pref_manufacturing_location_id
						end rfq_pref_manufacturing_location_id
					 from 
					 mp_rfq_preferences a (nolock)
				) mrp  on a.rfq_id = mrp.rfq_id
				/* Ewesterfield-MFG Sep 22, 2019, Is it possible to add the Region selected when creating an RFQ using cloning below the Process on the Tiles and Rows*/
				join mp_mst_territory_classification (nolock) mmtc on  mrp.rfq_pref_manufacturing_location_id = mmtc.territory_classification_id
				/**/
				left join mp_mst_part_category pcategory (nolock) on pcategory.part_category_id=rparts.part_category_id
				/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
				left join mp_mst_part_category category (nolock) on pcategory.parent_part_category_id=category.part_category_id
				/**/
				left join
				(
					SELECT 
						* 
						, count(1) over () ToBeAwardedRfqCount 
					FROM
					(
						SELECT 
							DISTINCT
							a.contact_id 
							,a.rfq_id
						
						FROM mp_rfq (NOLOCK) a
						JOIN mp_rfq_quote_SupplierQuote (NOLOCK) b ON a.rfq_id = b.rfq_id AND b.is_quote_submitted = 1 AND b.is_rfq_resubmitted = 0
						WHERE
							a.contact_id = @contactId
							AND a.rfq_status_id = 5
							AND DATEDIFF(DAY, CONVERT(DATE,a.award_date),CONVERT(DATE,GETUTCDATE())) >= 7
							AND CONVERT(DATE,a.rfq_created_on) >= '2020-08-01'
					) a 
				
				) rfqstobeawarded on a.rfq_id = rfqstobeawarded.rfq_id

			where (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
			AND mrp.rfq_pref_manufacturing_location_id = (CASE WHEN @TerritoryId = 0 THEN mrp.rfq_pref_manufacturing_location_id  ELSE @TerritoryId END) 
		) a
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.RFQId end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.RFQName end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.RFQId  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.RFQName  end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only	
	end
	/**/
	------------------------ My RFQ's (Directory Rfq => All Statues) --------------------
	/* M2-3657 Buyer - Remove Active tab and add Direct RFQs tab to My RFQs page - DB */
	else if (@rfqtype =20)
	begin

			select 
			
				a.rfq_id as RFQId
				, a.rfq_name as RFQName
				, a.rfq_status_id as RFQStatusId
				, k.rfq_buyerstatus_li_key as RFQStatus
				, case when category.discipline_name is null then pcategory.discipline_name when category.discipline_name = pcategory.discipline_name then pcategory.discipline_name else category.discipline_name +' / '+ pcategory.discipline_name end as Process
				,  a.rfq_created_on as RFQCreatedOn
				, a.Quotes_needed_by as QuotesNeededBy
				, a.award_date as AwardDate
				, coalesce(n.File_Name,'') as RfqThumbnail
				, count(1) over () RfqCount 
				, rfq_pref_manufacturing_location_id	
				, mmtc.territory_classification_name as 	rfq_pref_manufacturing_location
				/* M2-2458 : Buyers - Tile and Row - Add Dates and # of Quotes on to RFQ tiles in MY RFQs  -DB */
				,(select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where a.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0) as RFQQuoteCount		 
				,(select TOP 1 status_date from mp_rfq_release_history (nolock) 
								where a.rfq_id = rfq_id and status_id = 3 and a.rfq_status_id NOT IN(1,2) 
								ORDER BY rfq_release_history_id DESC) as RFQReleaseDate
			    /**/
				/*  M2-3601 Create special invite RFQ from the community - API*/
				,case when a.IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
				/**/
				/* M2-4793 */
				,a.WithOrderManagement  
				/**/
			from  
				mp_rfq								 a		(nolock)			 
				join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id	
					and a.contact_id =  @contactId 
					and a.rfq_status_id in  (2,3,5,6,9,14,15,16,17,18,20)		
					and IsMfgCommunityRfq = 1
				left join mp_special_files			 n		(nolock) on n.file_id = a.file_id
				join mp_rfq_parts rparts (nolock) on rparts.rfq_id=a.rfq_id and rparts.Is_Rfq_Part_Default=1
				join mp_parts mparts  (nolock) on mparts.part_id=rparts.part_id
				join 
				(
					select 
						distinct
						rfq_id 
						, case
							when (select count(1) from mp_rfq_preferences (nolock) where rfq_id = a.rfq_id) > 1 then 7
							else rfq_pref_manufacturing_location_id
						end rfq_pref_manufacturing_location_id
					 from 
					 mp_rfq_preferences a (nolock)
				) mrp  on a.rfq_id = mrp.rfq_id
				/* Ewesterfield-MFG Sep 22, 2019, Is it possible to add the Region selected when creating an RFQ using cloning below the Process on the Tiles and Rows*/
				join mp_mst_territory_classification (nolock) mmtc on  mrp.rfq_pref_manufacturing_location_id = mmtc.territory_classification_id
				/**/
				left join mp_mst_part_category pcategory (nolock) on pcategory.part_category_id=rparts.part_category_id
				/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
				left join mp_mst_part_category category (nolock) on pcategory.parent_part_category_id=category.part_category_id
				/**/
			where (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
			AND mrp.rfq_pref_manufacturing_location_id = (CASE WHEN @TerritoryId = 0 THEN mrp.rfq_pref_manufacturing_location_id  ELSE @TerritoryId END) 
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.rfq_id end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.rfq_name end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.rfq_id  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.rfq_name  end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only	
	end
	/* */
	------------------------ My RFQ's (Directory Rfq => Quoting Statues) --------------------
	/* M2-3657 Buyer - Remove Active tab and add Direct RFQs tab to My RFQs page - DB */
	else if (@rfqtype =21)
	begin

			select 
			a.rfq_id as RFQId
			, a.rfq_name as RFQName
			, a.rfq_status_id as RFQStatusId
			, k.rfq_buyerstatus_li_key as RFQStatus
			,case when category.discipline_name is null then pcategory.discipline_name when category.discipline_name = pcategory.discipline_name then pcategory.discipline_name else category.discipline_name +' / '+ pcategory.discipline_name end as Process
			, a.rfq_created_on as RFQCreatedOn
			, a.Quotes_needed_by as QuotesNeededBy
			, a.award_date as AwardDate
			, coalesce(n.File_Name,'') as RfqThumbnail
			, count(1) over () RfqCount 			
			, rfq_pref_manufacturing_location_id	
			, mmtc.territory_classification_name as 	rfq_pref_manufacturing_location
			/* M2-2458 : Buyers - Tile and Row - Add Dates and # of Quotes on to RFQ tiles in MY RFQs  -DB */
			,(select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where a.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0) as RFQQuoteCount
		    ,(select TOP 1 status_date from mp_rfq_release_history (nolock) 
								where a.rfq_id = rfq_id and status_id = 3 and a.rfq_status_id NOT IN(1,2) 
								ORDER BY rfq_release_history_id DESC) as RFQReleaseDate
			    /**/			 				 
				/*  M2-3601 Create special invite RFQ from the community - API*/
				,case when a.IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
				/**/
			/* M2-4793 */
			,a.WithOrderManagement  
				/**/
			from  
			mp_rfq								 a		(nolock)			 
			join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id	
				and a.contact_id =  @contactId 
				and a.rfq_status_id in  (3)	
				and IsMfgCommunityRfq = 1	
			left join mp_special_files			 n		(nolock) on n.file_id = a.file_id
			join mp_rfq_parts rparts (nolock) on rparts.rfq_id=a.rfq_id and rparts.Is_Rfq_Part_Default=1
			join mp_parts mparts  (nolock) on mparts.part_id=rparts.part_id
			left join mp_mst_part_category pcategory (nolock) on pcategory.part_category_id=rparts.part_category_id
			/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
			left join mp_mst_part_category category (nolock) on pcategory.parent_part_category_id=category.part_category_id
			/**/
			join 
			(
				select 
					distinct
					rfq_id 
					, case
						when (select count(1) from mp_rfq_preferences (nolock) where rfq_id = a.rfq_id) > 1 then 7
						else rfq_pref_manufacturing_location_id
					end rfq_pref_manufacturing_location_id
				 from 
				 mp_rfq_preferences a (nolock)
			) mrp  on a.rfq_id = mrp.rfq_id
			/* Ewesterfield-MFG Sep 22, 2019, Is it possible to add the Region selected when creating an RFQ using cloning below the Process on the Tiles and Rows*/
			join mp_mst_territory_classification (nolock) mmtc on  mrp.rfq_pref_manufacturing_location_id = mmtc.territory_classification_id
			/**/		
			where (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
			AND mrp.rfq_pref_manufacturing_location_id = (CASE WHEN @TerritoryId = 0 THEN mrp.rfq_pref_manufacturing_location_id  ELSE @TerritoryId END) 
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.rfq_id end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.rfq_name end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.rfq_id  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.rfq_name  end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only	
	end	
	/**/
	------------------------ My RFQ's (Directory Rfq => Awarded Statues) --------------------
	/* M2-3657 Buyer - Remove Active tab and add Direct RFQs tab to My RFQs page - DB */
	else if (@rfqtype =22)
	begin

			select 
			a.rfq_id as RFQId
			, a.rfq_name as RFQName
			, a.rfq_status_id as RFQStatusId
			, k.rfq_buyerstatus_li_key as RFQStatus
			,case when category.discipline_name is null then pcategory.discipline_name when category.discipline_name = pcategory.discipline_name then pcategory.discipline_name else category.discipline_name +' / '+ pcategory.discipline_name end as Process
			, a.rfq_created_on as RFQCreatedOn
			, a.Quotes_needed_by as QuotesNeededBy
			, a.award_date as AwardDate
			, coalesce(n.File_Name,'') as RfqThumbnail
			, count(1) over () RfqCount 	
			, rfq_pref_manufacturing_location_id	
			, mmtc.territory_classification_name as 	rfq_pref_manufacturing_location
			/* M2-2458 : Buyers - Tile and Row - Add Dates and # of Quotes on to RFQ tiles in MY RFQs  -DB */
			,(select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where a.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0) as RFQQuoteCount
		    ,(select TOP 1 status_date from mp_rfq_release_history (nolock) 
								where a.rfq_id = rfq_id and status_id = 3 and a.rfq_status_id NOT IN(1,2) 
								ORDER BY rfq_release_history_id DESC) as RFQReleaseDate
			    /**/			 				 	
				/*  M2-3601 Create special invite RFQ from the community - API*/
				,case when a.IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
				/**/
				/* M2-4793 */
				,a.WithOrderManagement  
				/**/
			from  
			mp_rfq								 a		(nolock)			 
			join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id	
				and a.contact_id =  @contactId 
				and a.rfq_status_id in  (6)	
				and IsMfgCommunityRfq = 1	
			left join mp_special_files			 n		(nolock) on n.file_id = a.file_id
			join mp_rfq_parts rparts (nolock) on rparts.rfq_id=a.rfq_id and rparts.Is_Rfq_Part_Default=1
			join mp_parts mparts  (nolock) on mparts.part_id=rparts.part_id
			left join mp_mst_part_category pcategory (nolock) on pcategory.part_category_id=rparts.part_category_id
			/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
			left join mp_mst_part_category category (nolock) on pcategory.parent_part_category_id=category.part_category_id
			/**/
			join 
			(
				select 
					distinct
					rfq_id 
					, case
						when (select count(1) from mp_rfq_preferences (nolock) where rfq_id = a.rfq_id) > 1 then 7
						else rfq_pref_manufacturing_location_id
					end rfq_pref_manufacturing_location_id
				 from 
				 mp_rfq_preferences a (nolock)
			) mrp  on a.rfq_id = mrp.rfq_id
			/* Ewesterfield-MFG Sep 22, 2019, Is it possible to add the Region selected when creating an RFQ using cloning below the Process on the Tiles and Rows*/
			join mp_mst_territory_classification (nolock) mmtc on  mrp.rfq_pref_manufacturing_location_id = mmtc.territory_classification_id
			/**/
		where (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
		AND mrp.rfq_pref_manufacturing_location_id = (CASE WHEN @TerritoryId = 0 THEN mrp.rfq_pref_manufacturing_location_id  ELSE @TerritoryId END) 
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.rfq_id end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.rfq_name end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.rfq_id  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.rfq_name  end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only	
	end
	/**/
	------------------------ My RFQ's (Directory Rfq => No Quotes) --------------------
	/* M2-3657 Buyer - Remove Active tab and add Direct RFQs tab to My RFQs page - DB */
	else if (@RfqType = 23)	
	begin

		 select 
			a.rfq_id as RFQId
			, a.rfq_name as RFQName
			, a.rfq_status_id as RFQStatusId
			, k.rfq_buyerstatus_li_key as RFQStatus
			, case  when category.discipline_name is null then pcategory.discipline_name  when category.discipline_name = pcategory.discipline_name then pcategory.discipline_name else category.discipline_name +' / '+ pcategory.discipline_name end  as Process
			, a.rfq_created_on as RFQCreatedOn
			, a.Quotes_needed_by as QuotesNeededBy
			, a.award_date as AwardDate
			, coalesce(n.File_Name,'') as RfqThumbnail			
			, count(1) over () RfqCount 
			, rfq_pref_manufacturing_location_id
			, mmtc.territory_classification_name as 	rfq_pref_manufacturing_location
			/* M2-2458 : Buyers - Tile and Row - Add Dates and # of Quotes on to RFQ tiles in MY RFQs  -DB */
			,(select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where a.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0) as RFQQuoteCount
		    ,(select TOP 1 status_date from mp_rfq_release_history (nolock) 
								where a.rfq_id = rfq_id and status_id = 3 and a.rfq_status_id NOT IN(1,2) 
								ORDER BY rfq_release_history_id DESC) as RFQReleaseDate
			    /**/			 				 	
			/*  M2-3601 Create special invite RFQ from the community - API*/
			,case when IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
			/**/
			/* M2-4793 */
			,a.WithOrderManagement  
			/**/
		from  mp_rfq							 a		(nolock)
		join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id			
			and a.contact_id =  @contactId 
			and a.rfq_status_id in  (3,5)	
			and IsMfgCommunityRfq = 1
		left join mp_special_files			 n		(nolock) on n.file_id = a.file_id
		join mp_rfq_parts rparts (nolock) on rparts.rfq_id=a.rfq_id and rparts.Is_Rfq_Part_Default=1
		join mp_parts mparts  (nolock) on mparts.part_id=rparts.part_id
		left join mp_mst_part_category pcategory (nolock) on pcategory.part_category_id=rparts.part_category_id
		/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
		left join mp_mst_part_category category (nolock) on pcategory.parent_part_category_id=category.part_category_id
		/**/
		JOIN mp_rfq_quote_suplierStatuses ON rparts.rfq_id=mp_rfq_quote_suplierStatuses.rfq_id
		/**/
		left join 
			(
				select rfq_id , sum(convert(int,is_quote_submitted))  quote_received
				from mp_rfq_quote_SupplierQuote (nolock) 
				where is_rfq_resubmitted = 0
				group by rfq_id
			) d		 on a.rfq_id = d.rfq_id 		
		join 
		(
				select 
					distinct
					rfq_id 
					, case
						when (select count(1) from mp_rfq_preferences (nolock) where rfq_id = a.rfq_id) > 1 then 7
						else rfq_pref_manufacturing_location_id
					end rfq_pref_manufacturing_location_id
				 from 
				 mp_rfq_preferences a (nolock)
		) mrp  on a.rfq_id = mrp.rfq_id		
		/* Ewesterfield-MFG Sep 22, 2019, Is it possible to add the Region selected when creating an RFQ using cloning below the Process on the Tiles and Rows*/
		join mp_mst_territory_classification (nolock) mmtc on  mrp.rfq_pref_manufacturing_location_id = mmtc.territory_classification_id
		/**/
		
		where   
		(d.quote_received is null or quote_received = 0 )
		and (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.rfq_id end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.rfq_name end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.rfq_id  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.rfq_name  end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only

	end
	/**/
	------------------------ My RFQ's (Directory Rfq => With Quotes) --------------------
	/* M2-3657 Buyer - Remove Active tab and add Direct RFQs tab to My RFQs page - DB */
	else if (@RfqType = 24)	
	begin

		 select 
			a.rfq_id as RFQId
			, a.rfq_name as RFQName
			, a.rfq_status_id as RFQStatusId
			, k.rfq_buyerstatus_li_key as RFQStatus
			, case  when category.discipline_name is null then pcategory.discipline_name when category.discipline_name = pcategory.discipline_name then pcategory.discipline_name else category.discipline_name +' / '+ pcategory.discipline_name end  as Process
			, a.rfq_created_on as RFQCreatedOn
			, a.Quotes_needed_by as QuotesNeededBy
			, a.award_date as AwardDate
			, coalesce(n.File_Name,'') as RfqThumbnail			
			, count(1) over () RfqCount 
			, rfq_pref_manufacturing_location_id	
			, mmtc.territory_classification_name as 	rfq_pref_manufacturing_location
			/* M2-2458 : Buyers - Tile and Row - Add Dates and # of Quotes on to RFQ tiles in MY RFQs  -DB */
			,(select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where a.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0) as RFQQuoteCount
		    ,(select TOP 1 status_date from mp_rfq_release_history (nolock) 
								where a.rfq_id = rfq_id and status_id = 3 and a.rfq_status_id NOT IN(1,2) 
								ORDER BY rfq_release_history_id DESC) as RFQReleaseDate
			    /**/			 			 
			/*  M2-3601 Create special invite RFQ from the community - API*/
			,case when IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
			/**/
			/* M2-4793 */
			,a.WithOrderManagement  
			/**/
		from  mp_rfq							 a		(nolock)
		join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id			
			and a.contact_id =  @contactId 
			and IsMfgCommunityRfq = 1
		--	and a.rfq_status_id in  (3,5)	
		left join mp_special_files			 n		(nolock) on n.file_id = a.file_id
		join mp_rfq_parts rparts (nolock) on rparts.rfq_id=a.rfq_id and rparts.Is_Rfq_Part_Default=1
		join mp_parts mparts  (nolock) on mparts.part_id=rparts.part_id
		left join mp_mst_part_category pcategory (nolock) on pcategory.part_category_id=rparts.part_category_id
		/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
		left join mp_mst_part_category category (nolock) on pcategory.parent_part_category_id=category.part_category_id
		/**/
		join 
			(
				select rfq_id , sum(convert(int,is_quote_submitted))  quote_received
				from mp_rfq_quote_SupplierQuote (nolock) 
				where is_rfq_resubmitted = 0
				group by rfq_id
			) d		 on a.rfq_id = d.rfq_id 		
		join 
		(
			select 
				distinct
				rfq_id 
				, case
					when (select count(1) from mp_rfq_preferences (nolock) where rfq_id = a.rfq_id) > 1 then 7
					else rfq_pref_manufacturing_location_id
				end rfq_pref_manufacturing_location_id
				from 
				mp_rfq_preferences a (nolock)
		) mrp  on a.rfq_id = mrp.rfq_id
		/* Ewesterfield-MFG Sep 22, 2019, Is it possible to add the Region selected when creating an RFQ using cloning below the Process on the Tiles and Rows*/
		join mp_mst_territory_classification (nolock) mmtc on  mrp.rfq_pref_manufacturing_location_id = mmtc.territory_classification_id
		/**/
		
		where   
		(d.quote_received > 0 )
		and (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.rfq_id end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.rfq_name end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.rfq_id  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.rfq_name  end asc   	  
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only
	end
	/**/
	


end
