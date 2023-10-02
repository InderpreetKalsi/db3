

/*


exec proc_get_Buyer_MyCompanyRFQs
	 @ContactId = 1352301,
	 @CompanyId = 1782686,
	 @RfqType = 7,
	 @OrderBy = 'rfq_closed_date',
	 @IsOrderByDesc ='false',
	 @currentdate = '2020-07-10 02:00:42'

*/

CREATE PROCEDURE [dbo].[proc_get_Buyer_MyCompanyRFQs]
(
	 @ContactId INT,
	 @CompanyId INT,
	 @RfqType INT,
	 @OrderBy VARCHAR(100) = null,
	 @IsOrderByDesc BIT='true',
	 @currentdate datetime = null ,
	 @PageNumber INT = 1,
	 @PageSize   INT = 25,
	 @searchText VARCHAR(100) = null,
	 @SelectedBuyerId   INT = NULL
) 
AS
-- ====================================================
-- Description:	M2-2846 Buyer - Add My Company RFQs below RFQs - DB
-- ====================================================
BEGIN

	set nocount on

	drop table if exists #tmp_mycompany_buyers
	
	CREATE TABLE #tmp_mycompany_buyers (BuyerId INT)


	if (@OrderBy is null or @OrderBy = '')
		set @OrderBy = 'rfq_id'

	if (@IsOrderByDesc is null )
		set @IsOrderByDesc = 1
	
	if @currentdate is null
		set @currentdate = getutcdate()

	if @searchText is null
		set @searchText = ''
	



	IF @SelectedBuyerId IS NULL
	BEGIN
		INSERT INTO #tmp_mycompany_buyers (BuyerId)
		SELECT contact_id from mp_contacts where company_id = @CompanyId
	END
	ELSE
	BEGIN
			INSERT INTO #tmp_mycompany_buyers (BuyerId) SELECT @SelectedBuyerId
	END
	
			 
	------------------------ My Company RFQ's --------------------
	/*M2-1596 Performance optimization for Buyer list - Database side*/
	if (@rfqtype =1)
	begin
		select 
			
			a.rfq_id as RFQId
			, a.rfq_name as RFQName
			, a.rfq_status_id as RFQStatusId
			, k.description as RFQStatus
			, case when category.discipline_name is null then pcategory.discipline_name  when category.discipline_name = pcategory.discipline_name then pcategory.discipline_name else category.discipline_name +' / '+ pcategory.discipline_name end as Process
			, a.rfq_created_on as RFQCreatedOn
			, a.Quotes_needed_by as QuotesNeededBy
			, a.award_date as AwardDate
			, coalesce(n.File_Name,'') as RfqThumbnail
			, count(1) over () RfqCount 
			, rfq_pref_manufacturing_location_id	AS RfqPrefLocationId
			, mmtc.territory_classification_name AS 	RfqPrefLocation		
			, b1.contact_id as BuyerId 
			, b1.first_name +' '+ b1.last_name as Buyer
			/*  M2-3601 Create special invite RFQ from the community - API*/
			,case when IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
			/**/
			/* M2-4793 */
			,a.WithOrderManagement  
			/**/
		from  
			mp_rfq								 a		(nolock)
			join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id	
				and a.contact_id in (select * from #tmp_mycompany_buyers)
				and a.rfq_status_id in  (2,3,5,6,9,14,15)		
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
			join mp_contacts b1 (nolock) on a.contact_id = b1.contact_id
		where (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.rfq_id end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.rfq_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then  pcategory.discipline_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'location' then  mmtc.territory_classification_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'buyer' then  (b1.first_name +' '+ b1.last_name) end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_created' then  a.rfq_created_on end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_closed_date' then  a.Quotes_needed_by end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'status' then  k.description end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.rfq_id  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.rfq_name  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then  pcategory.discipline_name end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'location' then  mmtc.territory_classification_name end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'buyer' then  (b1.first_name +' '+ b1.last_name) end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_created' then  a.rfq_created_on end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_closed_date' then  a.Quotes_needed_by end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'status' then  k.description end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only	
	end
	/**/
	------------------------ My Company RFQ's (Quoting) --------------------
	/*M2-1596 Performance optimization for Buyer list - Database side*/
	else if (@rfqtype =2)
	begin

			select 
			a.rfq_id as RFQId
			, a.rfq_name as RFQName
			, a.rfq_status_id as RFQStatusId
			, k.description as RFQStatus
			, case when category.discipline_name is null then pcategory.discipline_name  when category.discipline_name = pcategory.discipline_name then pcategory.discipline_name else category.discipline_name +' / '+ pcategory.discipline_name end  as Process
			, a.rfq_created_on as RFQCreatedOn
			, a.Quotes_needed_by as QuotesNeededBy
			, a.award_date as AwardDate
			, coalesce(n.File_Name,'') as RfqThumbnail
			, count(1) over () RfqCount 			
			, rfq_pref_manufacturing_location_id	AS RfqPrefLocationId
			, mmtc.territory_classification_name AS 	RfqPrefLocation				 
			, b1.contact_id as BuyerId 
			, b1.first_name +' '+ b1.last_name as Buyer
			/*  M2-3601 Create special invite RFQ from the community - API*/
			,case when IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
			/**/
			/* M2-4793 */
			,a.WithOrderManagement  
			/**/
		from  
			mp_rfq								 a		(nolock)
			join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id	
				and a.contact_id  in (select * from #tmp_mycompany_buyers)
				and a.rfq_status_id in  (3)		
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
			join mp_contacts b1 (nolock) on a.contact_id = b1.contact_id
			where (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.rfq_id end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.rfq_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then  pcategory.discipline_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'location' then  mmtc.territory_classification_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'buyer' then  (b1.first_name +' '+ b1.last_name) end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_created' then  a.rfq_created_on end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_closed_date' then  a.Quotes_needed_by end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'status' then  k.description end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.rfq_id  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.rfq_name  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then  pcategory.discipline_name end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'location' then  mmtc.territory_classification_name end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'buyer' then  (b1.first_name +' '+ b1.last_name) end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_created' then  a.rfq_created_on end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_closed_date' then  a.Quotes_needed_by end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'status' then  k.description end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only	
	end
	/**/
	------------------------ My Company RFQ's (Awarded) --------------------
	/*M2-1596 Performance optimization for Buyer list - Database side*/
	else if (@rfqtype =4)
	begin

			select 
			a.rfq_id as RFQId
			, a.rfq_name as RFQName
			, a.rfq_status_id as RFQStatusId
			, k.description as RFQStatus
			, case when category.discipline_name is null then pcategory.discipline_name  when category.discipline_name = pcategory.discipline_name then pcategory.discipline_name else category.discipline_name +' / '+ pcategory.discipline_name end  as Process
			, a.rfq_created_on as RFQCreatedOn
			, a.Quotes_needed_by as QuotesNeededBy
			, a.award_date as AwardDate
			, coalesce(n.File_Name,'') as RfqThumbnail
			, count(1) over () RfqCount 	
			, rfq_pref_manufacturing_location_id	AS RfqPrefLocationId
			, mmtc.territory_classification_name AS 	RfqPrefLocation					 	
			, b1.contact_id as BuyerId 
			, b1.first_name +' '+ b1.last_name as Buyer
			/*  M2-3601 Create special invite RFQ from the community - API*/
			,case when IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
			/**/
			/* M2-4793 */
			,a.WithOrderManagement  
			/**/
		from  
			mp_rfq								 a		(nolock)
			join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id	
				and a.contact_id  in (select * from #tmp_mycompany_buyers)
				and a.rfq_status_id in  (6)		
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
			join mp_contacts b1 (nolock) on a.contact_id = b1.contact_id
		where (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.rfq_id end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.rfq_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then  pcategory.discipline_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'location' then  mmtc.territory_classification_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'buyer' then  (b1.first_name +' '+ b1.last_name) end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_created' then  a.rfq_created_on end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_closed_date' then  a.Quotes_needed_by end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'status' then  k.description end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.rfq_id  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.rfq_name  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then  pcategory.discipline_name end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'location' then  mmtc.territory_classification_name end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'buyer' then  (b1.first_name +' '+ b1.last_name) end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_created' then  a.rfq_created_on end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_closed_date' then  a.Quotes_needed_by end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'status' then  k.description end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only	
	end
	/**/
	------------------------ My Company RFQ's (Pending Approval) --------------------
	/*M2-1596 Performance optimization for Buyer list - Database side*/
	else if (@rfqtype =5)
	begin

			select 
			a.rfq_id as RFQId
			, a.rfq_name as RFQName
			, a.rfq_status_id as RFQStatusId
			, k.description as RFQStatus
			, case when category.discipline_name is null then pcategory.discipline_name  when category.discipline_name = pcategory.discipline_name then pcategory.discipline_name else category.discipline_name +' / '+ pcategory.discipline_name end  as Process
			, a.rfq_created_on as RFQCreatedOn
			, a.Quotes_needed_by as QuotesNeededBy
			, a.award_date as AwardDate
			, coalesce(n.File_Name,'') as RfqThumbnail
			, count(1) over () RfqCount 
			, rfq_pref_manufacturing_location_id	AS RfqPrefLocationId
			, mmtc.territory_classification_name AS 	RfqPrefLocation			 							
			, b1.contact_id as BuyerId 
			, b1.first_name +' '+ b1.last_name as Buyer
			/*  M2-3601 Create special invite RFQ from the community - API*/
			,case when IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
			/**/
			/* M2-4793 */
			,a.WithOrderManagement  
			/**/
		from  
			mp_rfq								 a		(nolock)
			join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id	
				and a.contact_id  in (select * from #tmp_mycompany_buyers)
				and a.rfq_status_id in  (2)		
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
			join mp_contacts b1 (nolock) on a.contact_id = b1.contact_id
		where (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.rfq_id end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.rfq_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then  pcategory.discipline_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'location' then  mmtc.territory_classification_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'buyer' then  (b1.first_name +' '+ b1.last_name) end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_created' then  a.rfq_created_on end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_closed_date' then  a.Quotes_needed_by end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'status' then  k.description end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.rfq_id  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.rfq_name  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then  pcategory.discipline_name end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'location' then  mmtc.territory_classification_name end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'buyer' then  (b1.first_name +' '+ b1.last_name) end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_created' then  a.rfq_created_on end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_closed_date' then  a.Quotes_needed_by end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'status' then  k.description end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only	
	end
	/**/
------------------------ My Company RFQ's (Closed) --------------------
	/*M2-1596 Performance optimization for Buyer list - Database side*/
	else if (@rfqtype =6)
	begin

			select 
			a.rfq_id as RFQId
			, a.rfq_name as RFQName
			, a.rfq_status_id as RFQStatusId
			, k.description as RFQStatus
			, case when category.discipline_name is null then pcategory.discipline_name  when category.discipline_name = pcategory.discipline_name then pcategory.discipline_name else category.discipline_name +' / '+ pcategory.discipline_name end  as Process
			, a.rfq_created_on as RFQCreatedOn
			, a.Quotes_needed_by as QuotesNeededBy
			, a.award_date as AwardDate
			, coalesce(n.File_Name,'') as RfqThumbnail
			, count(1) over () RfqCount
			, rfq_pref_manufacturing_location_id	AS RfqPrefLocationId
			, mmtc.territory_classification_name AS 	RfqPrefLocation			 		 			
			, b1.contact_id as BuyerId 
			, b1.first_name +' '+ b1.last_name as Buyer
			/*  M2-3601 Create special invite RFQ from the community - API*/
			,case when IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
			/**/
			/* M2-4793 */
			,a.WithOrderManagement  
			/**/
		from  
			mp_rfq								 a		(nolock)
			join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id	
				and a.contact_id  in (select * from #tmp_mycompany_buyers)
				and a.rfq_status_id in  (5)		
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
			join mp_contacts b1 (nolock) on a.contact_id = b1.contact_id
		where (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.rfq_id end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.rfq_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then  pcategory.discipline_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'location' then  mmtc.territory_classification_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'buyer' then  (b1.first_name +' '+ b1.last_name) end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_created' then  a.rfq_created_on end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_closed_date' then  a.Quotes_needed_by end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'status' then  k.description end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.rfq_id  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.rfq_name  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then  pcategory.discipline_name end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'location' then  mmtc.territory_classification_name end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'buyer' then  (b1.first_name +' '+ b1.last_name) end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_created' then  a.rfq_created_on end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_closed_date' then  a.Quotes_needed_by end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'status' then  k.description end asc    
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only	
	end
	/**/
	------------------------ My Company RFQ's (with no Quotes) --------------------
	/*M2-1596 Performance optimization for Buyer list - Database side*/
	else if (@RfqType = 13)	
	begin

		 select 
			a.rfq_id as RFQId
			, a.rfq_name as RFQName
			, a.rfq_status_id as RFQStatusId
			, k.description as RFQStatus
			, case when category.discipline_name is null then pcategory.discipline_name  when category.discipline_name = pcategory.discipline_name then pcategory.discipline_name else category.discipline_name +' / '+ pcategory.discipline_name end  as Process
			, a.rfq_created_on as RFQCreatedOn
			, a.Quotes_needed_by as QuotesNeededBy
			, a.award_date as AwardDate
			, coalesce(n.File_Name,'') as RfqThumbnail			
			, count(1) over () RfqCount 
			, rfq_pref_manufacturing_location_id	AS RfqPrefLocationId
			, mmtc.territory_classification_name AS 	RfqPrefLocation				 	
			, b1.contact_id as BuyerId 
			, b1.first_name +' '+ b1.last_name as Buyer
			/*  M2-3601 Create special invite RFQ from the community - API*/
			,case when IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
			/**/
			/* M2-4793 */
			,a.WithOrderManagement  
			/**/
		from  mp_rfq							 a		(nolock)
		join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id			
			and a.contact_id   in (select * from #tmp_mycompany_buyers)
			and a.rfq_status_id in  (3,5)	
		left join mp_special_files			 n		(nolock) on n.file_id = a.file_id
		join mp_rfq_parts rparts (nolock) on rparts.rfq_id=a.rfq_id and rparts.Is_Rfq_Part_Default=1
		join mp_parts mparts  (nolock) on mparts.part_id=rparts.part_id
		left join mp_mst_part_category pcategory (nolock) on pcategory.part_category_id=rparts.part_category_id
		/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
		left join mp_mst_part_category category (nolock) on pcategory.parent_part_category_id=category.part_category_id
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
		join mp_contacts b1 (nolock) on a.contact_id = b1.contact_id
		where   
		(d.quote_received is null or quote_received = 0 )
		and (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.rfq_id end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.rfq_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then  pcategory.discipline_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'location' then  mmtc.territory_classification_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'buyer' then  (b1.first_name +' '+ b1.last_name) end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_created' then  a.rfq_created_on end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_closed_date' then  a.Quotes_needed_by end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'status' then  k.description end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.rfq_id  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.rfq_name  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then  pcategory.discipline_name end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'location' then  mmtc.territory_classification_name end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'buyer' then  (b1.first_name +' '+ b1.last_name) end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_created' then  a.rfq_created_on end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_closed_date' then  a.Quotes_needed_by end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'status' then  k.description end asc    
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only

	end
	/**/
	------------------------ My Company RFQ's (with Quotes) --------------------
	/*M2-1596 Performance optimization for Buyer list - Database side*/
	else if (@RfqType = 14)	
	begin

		 select 
			a.rfq_id as RFQId
			, a.rfq_name as RFQName
			, a.rfq_status_id as RFQStatusId
			, k.description as RFQStatus
			, case when category.discipline_name is null then pcategory.discipline_name  when category.discipline_name = pcategory.discipline_name then pcategory.discipline_name else category.discipline_name +' / '+ pcategory.discipline_name end  as Process
			, a.rfq_created_on as RFQCreatedOn
			, a.Quotes_needed_by as QuotesNeededBy
			, a.award_date as AwardDate
			, coalesce(n.File_Name,'') as RfqThumbnail			
			, count(1) over () RfqCount 
			, rfq_pref_manufacturing_location_id	AS RfqPrefLocationId
			, mmtc.territory_classification_name AS 	RfqPrefLocation			 
			, b1.contact_id as BuyerId 
			, b1.first_name +' '+ b1.last_name as Buyer
			/*  M2-3601 Create special invite RFQ from the community - API*/
			,case when IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
			/**/
			/* M2-4793 */
			,a.WithOrderManagement  
			/**/
		from  mp_rfq							 a		(nolock)
		join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id			
			and a.contact_id   in (select * from #tmp_mycompany_buyers)
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
		join mp_contacts b1 (nolock) on a.contact_id = b1.contact_id
		where   
		(d.quote_received > 0 )
		and (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.rfq_id end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.rfq_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then  pcategory.discipline_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'location' then  mmtc.territory_classification_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'buyer' then  (b1.first_name +' '+ b1.last_name) end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_created' then  a.rfq_created_on end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_closed_date' then  a.Quotes_needed_by end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'status' then  k.description end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.rfq_id  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.rfq_name  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then  pcategory.discipline_name end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'location' then  mmtc.territory_classification_name end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'buyer' then  (b1.first_name +' '+ b1.last_name) end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_created' then  a.rfq_created_on end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_closed_date' then  a.Quotes_needed_by end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'status' then  k.description end asc   	  
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only
	end
	/**/
	------------------------ My Company RFQ's (Archived)--------------------
	/*M2-1596 Performance optimization for Buyer list - Database side*/
	else if (@rfqtype =8)
	begin

		select 
			a.rfq_id as RFQId
			, a.rfq_name as RFQName
			, a.rfq_status_id as RFQStatusId
			, k.description as RFQStatus
			, case when category.discipline_name is null then pcategory.discipline_name  when category.discipline_name = pcategory.discipline_name then pcategory.discipline_name else category.discipline_name +' / '+ pcategory.discipline_name end  as Process
			, a.rfq_created_on as RFQCreatedOn
			, a.Quotes_needed_by as QuotesNeededBy
			, a.award_date as AwardDate
			, coalesce(n.File_Name,'') as RfqThumbnail
			, count(1) over () RfqCount
			, rfq_pref_manufacturing_location_id	AS RfqPrefLocationId
			, mmtc.territory_classification_name AS 	RfqPrefLocation				 		 
			, b1.contact_id as BuyerId 
			, b1.first_name +' '+ b1.last_name as Buyer
			/*  M2-3601 Create special invite RFQ from the community - API*/
			,case when IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
			/**/
			/* M2-4793 */
			,a.WithOrderManagement  
			/**/
		from  
			mp_rfq								 a		(nolock)
			join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id	
				and a.contact_id in (select * from #tmp_mycompany_buyers)
				and a.rfq_status_id  in (13)	
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
			join mp_contacts b1 (nolock) on a.contact_id = b1.contact_id
		where (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.rfq_id end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.rfq_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then  pcategory.discipline_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'location' then  mmtc.territory_classification_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'buyer' then  (b1.first_name +' '+ b1.last_name) end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_created' then  a.rfq_created_on end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_closed_date' then  a.Quotes_needed_by end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'status' then  k.description end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.rfq_id  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.rfq_name  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then  pcategory.discipline_name end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'location' then  mmtc.territory_classification_name end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'buyer' then  (b1.first_name +' '+ b1.last_name) end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_created' then  a.rfq_created_on end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_closed_date' then  a.Quotes_needed_by end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'status' then  k.description end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only	
	end
	/**/
	

	------------------------ My Company RFQ's (Active)--------------------
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
			, mp_companies.name AS BuyerCompany
			, a.rfq_status_id as RFQStatusId
			, k.description as RFQStatus
			, rfq_likes.is_rfq_like AS IsRfqLike
			, mp_star_rating.no_of_stars AS NoOfStars
			, a.payment_term_id AS payment_term_id				
			, a.rfq_created_on as RFQCreatedOn
			, a.Quotes_needed_by as QuotesNeededBy
			, a.award_date as AwardDate
			, coalesce(n.File_Name,'') as RfqThumbnail
			, count(1) over () RfqCount 
			, rfq_pref_manufacturing_location_id	AS RfqPrefLocationId
			, mmtc.territory_classification_name AS 	RfqPrefLocation			 	
			, mp_contacts.contact_id as BuyerId 
			, mp_contacts.first_name +' '+ mp_contacts.last_name as Buyer
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
				and a.contact_id   in (select * from #tmp_mycompany_buyers)
				and a.rfq_status_id > 2
				and a.rfq_status_id not in(5,13,14)	
				and format(a.quotes_needed_by,'yyyyMMdd') >= format(@currentdate,'yyyyMMdd') 
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
			left join (select * from mp_rfq_supplier_likes (nolock)  where contact_id   in (select * from #tmp_mycompany_buyers) ) as rfq_likes on a.rfq_id = rfq_likes.rfq_id
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
		) a
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.RFQId end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.RFQName end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then  a.Process end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'location' then  a.RfqPrefLocation end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'buyer' then  a.Buyer end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_created' then  a.RFQCreatedOn end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_closed_date' then  a.QuotesNeededBy end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'status' then  a.RFQStatus end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.RFQId  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.RFQName  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then  a.Process end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'location' then  a.RfqPrefLocation end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'buyer' then  a.Buyer end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_created' then  a.RFQCreatedOn end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_closed_date' then  a.QuotesNeededBy end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'status' then  a.RFQStatus end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only	
	end
	/**/
	------------------------ My Company RFQ's (Active with qouting)--------------------
	/*M2-1596 Performance optimization for Buyer list - Database side*/
	else if (@rfqtype =15)
	begin

		select 
			a.rfq_id as RFQId
			, a.rfq_name as RFQName
			, a.rfq_status_id as RFQStatusId
			, k.description as RFQStatus
			, case when category.discipline_name is null then pcategory.discipline_name  when category.discipline_name = pcategory.discipline_name then pcategory.discipline_name else category.discipline_name +' / '+ pcategory.discipline_name end  as Process
			, a.rfq_created_on as RFQCreatedOn
			, a.Quotes_needed_by as QuotesNeededBy
			, a.award_date as AwardDate
			, coalesce(n.File_Name,'') as RfqThumbnail
			, count(1) over () RfqCount 			
			, rfq_pref_manufacturing_location_id	AS RfqPrefLocationId
			, mmtc.territory_classification_name AS 	RfqPrefLocation			 
			, b1.contact_id as BuyerId 
			, b1.first_name +' '+ b1.last_name as Buyer
			/*  M2-3601 Create special invite RFQ from the community - API*/
			,case when IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
			/**/
			/* M2-4793 */
			,a.WithOrderManagement  
			/**/
		from  
			mp_rfq								 a		(nolock)
			join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id	
				and a.contact_id  in (select * from #tmp_mycompany_buyers)
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
			join mp_contacts b1 (nolock) on a.contact_id = b1.contact_id
		where (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.rfq_id end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.rfq_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then  pcategory.discipline_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'location' then  mmtc.territory_classification_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'buyer' then  (b1.first_name +' '+ b1.last_name) end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_created' then  a.rfq_created_on end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_closed_date' then  a.Quotes_needed_by end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'status' then  k.description end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.rfq_id  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.rfq_name  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then  pcategory.discipline_name end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'location' then  mmtc.territory_classification_name end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'buyer' then  (b1.first_name +' '+ b1.last_name) end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_created' then  a.rfq_created_on end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_closed_date' then  a.Quotes_needed_by end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'status' then  k.description end asc    
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only	
	end
	/**/
	------------------------ My Company RFQ's (Active with awarded)--------------------
	/*M2-1596 Performance optimization for Buyer list - Database side*/
	else if (@rfqtype =16)
	begin

		select 
			a.rfq_id as RFQId
			, a.rfq_name as RFQName
			, a.rfq_status_id as RFQStatusId
			, k.description as RFQStatus
			, case when category.discipline_name is null then pcategory.discipline_name  when category.discipline_name = pcategory.discipline_name then pcategory.discipline_name else category.discipline_name +' / '+ pcategory.discipline_name end  as Process 
			, a.rfq_created_on as RFQCreatedOn
			, a.Quotes_needed_by as QuotesNeededBy
			, a.award_date as AwardDate
			, coalesce(n.File_Name,'') as RfqThumbnail
			, count(1) over () RfqCount 			
			, rfq_pref_manufacturing_location_id	AS RfqPrefLocationId
			, mmtc.territory_classification_name AS 	RfqPrefLocation		 
			, b1.contact_id as BuyerId 
			, b1.first_name +' '+ b1.last_name as Buyer
			/*  M2-3601 Create special invite RFQ from the community - API*/
			,case when IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
			/**/
			/* M2-4793 */
			,a.WithOrderManagement  
			/**/
		from  
			mp_rfq								 a		(nolock)
			join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id	
				and a.contact_id  in (select * from #tmp_mycompany_buyers) 
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
			left join mp_mst_part_category pcategory (nolock) on pcategory.part_category_id=rparts.part_category_id
			/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
			left join mp_mst_part_category category (nolock) on pcategory.parent_part_category_id=category.part_category_id
			/**/
			/* Ewesterfield-MFG Sep 22, 2019, Is it possible to add the Region selected when creating an RFQ using cloning below the Process on the Tiles and Rows*/
			join mp_mst_territory_classification (nolock) mmtc on  mrp.rfq_pref_manufacturing_location_id = mmtc.territory_classification_id
			/**/
			join mp_contacts b1 (nolock) on a.contact_id = b1.contact_id
		where (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.rfq_id end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.rfq_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then  pcategory.discipline_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'location' then  mmtc.territory_classification_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'buyer' then  (b1.first_name +' '+ b1.last_name) end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_created' then  a.rfq_created_on end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_closed_date' then  a.Quotes_needed_by end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'status' then  k.description end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.rfq_id  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.rfq_name  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then  pcategory.discipline_name end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'location' then  mmtc.territory_classification_name end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'buyer' then  (b1.first_name +' '+ b1.last_name) end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_created' then  a.rfq_created_on end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_closed_date' then  a.Quotes_needed_by end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'status' then  k.description end asc   
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only	
	end
	/**/
	------------------------ My Company RFQ's (Active with quotes)--------------------
	/*M2-1596 Performance optimization for Buyer list - Database side*/
	else if (@rfqtype =18)
	begin

		select 
			a.rfq_id as RFQId
			, a.rfq_name as RFQName
			, a.rfq_status_id as RFQStatusId
			, k.description as RFQStatus
			, case when category.discipline_name is null then pcategory.discipline_name  when category.discipline_name = pcategory.discipline_name then pcategory.discipline_name else category.discipline_name +' / '+ pcategory.discipline_name end  as Process
			, a.rfq_created_on as RFQCreatedOn
			, a.Quotes_needed_by as QuotesNeededBy
			, a.award_date as AwardDate
			, coalesce(n.File_Name,'') as RfqThumbnail
			, count(1) over () RfqCount 			
			, rfq_pref_manufacturing_location_id	AS RfqPrefLocationId
			, mmtc.territory_classification_name AS 	RfqPrefLocation			 
			, b1.contact_id as BuyerId 
			, b1.first_name +' '+ b1.last_name as Buyer
			/*  M2-3601 Create special invite RFQ from the community - API*/
			,case when IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
			/**/
			/* M2-4793 */
			,a.WithOrderManagement  
			/**/
		from  
		mp_rfq								 a		(nolock)
		join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id	
				and a.contact_id  in (select * from #tmp_mycompany_buyers) 
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
			join mp_contacts b1 (nolock) on a.contact_id = b1.contact_id
		where (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
		and d.quote_received > 0
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.rfq_id end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.rfq_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then  pcategory.discipline_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'location' then  mmtc.territory_classification_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'buyer' then  (b1.first_name +' '+ b1.last_name) end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_created' then  a.rfq_created_on end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_closed_date' then  a.Quotes_needed_by end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'status' then  k.description end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.rfq_id  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.rfq_name  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then  pcategory.discipline_name end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'location' then  mmtc.territory_classification_name end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'buyer' then  (b1.first_name +' '+ b1.last_name) end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_created' then  a.rfq_created_on end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_closed_date' then  a.Quotes_needed_by end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'status' then  k.description end asc    
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only	
	end
	/**/
	------------------------ My Company RFQ's (Active with no quotes)--------------------
	/*M2-1596 Performance optimization for Buyer list - Database side*/
	else if (@rfqtype =17)
	begin

		select 
			a.rfq_id as RFQId
			, a.rfq_name as RFQName
			, a.rfq_status_id as RFQStatusId
			, k.description as RFQStatus
            , case when category.discipline_name is null then pcategory.discipline_name  when category.discipline_name = pcategory.discipline_name then pcategory.discipline_name else category.discipline_name +' / '+ pcategory.discipline_name end  as Process
			, a.rfq_created_on as RFQCreatedOn
			, a.Quotes_needed_by as QuotesNeededBy
			, a.award_date as AwardDate
			, coalesce(n.File_Name,'') as RfqThumbnail
			, count(1) over () RfqCount 			
			, rfq_pref_manufacturing_location_id	AS RfqPrefLocationId
			, mmtc.territory_classification_name AS 	RfqPrefLocation			 	
			, b1.contact_id as BuyerId 
			, b1.first_name +' '+ b1.last_name as Buyer
			/*  M2-3601 Create special invite RFQ from the community - API*/
			,case when IsMfgCommunityRfq = 1 then cast ('true' as bit) else cast ('false' as bit) end as IsCommunityRfq
			/**/
			/* M2-4793 */
			,a.WithOrderManagement  
			/**/
		from  
		mp_rfq								 a		(nolock)
		join mp_mst_rfq_buyerstatus			 k 		(nolock) on a.rfq_status_id=k.rfq_buyerstatus_id	
				and a.contact_id  in (select * from #tmp_mycompany_buyers)
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
			join mp_contacts b1 (nolock) on a.contact_id = b1.contact_id
		where (convert(varchar(100),a.rfq_id) like '%'+@searchText+'%' or a.rfq_name like '%'+@searchText+'%')
		and (d.quote_received is null or quote_received = 0 )
		order by 
			case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_id' then   a.rfq_id end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_name' then  a.rfq_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'process' then  pcategory.discipline_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'location' then  mmtc.territory_classification_name end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'buyer' then  (b1.first_name +' '+ b1.last_name) end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_created' then  a.rfq_created_on end desc  
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'rfq_closed_date' then  a.Quotes_needed_by end desc   
			,case  when @IsOrderByDesc =  1 and @OrderBy = 'status' then  k.description end desc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_id' then   a.rfq_id  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_name' then   a.rfq_name  end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'process' then  pcategory.discipline_name end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'location' then  mmtc.territory_classification_name end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'buyer' then  (b1.first_name +' '+ b1.last_name) end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_created' then  a.rfq_created_on end asc  
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'rfq_closed_date' then  a.Quotes_needed_by end asc   
			,case  when @IsOrderByDesc =  0 and @OrderBy = 'status' then  k.description end asc    
		offset @pagesize * (@pagenumber - 1) rows
		fetch next @pagesize rows only	
	end
	/**/


end
