/*

declare @p25 dbo.tbltype_ListOfProcesses
insert into @p25 values (17819

declare @p26 dbo.tbltype_ListOfBuyerIndustryId

exec [proc_get_RfqList_Vision]
	@ContactId=848283
	,@CompanyId=1274154
	,@RfqType=10
	,@CountryId=0
	,@ManufacturingLocationId=0
	,@IsActive=1
	,@IsPending=0
	,@IsIncomplete=0
	,@IsClosingIn4Days=0
	,@IsClosingIn24Hours=0
	,@IsQuoting=0
	,@IsAwarded=0
	,@IsDraft=1
	,@IsDraftAfterClose=0
	,@DraftBeforeRelease=0
	,@IsClosed=0
	,@PageNumber=1
	,@PageSize=20
	,@IsValidated=0
	,@IsUnvalidated=0
	,@IsOrderByDesc=1
	,@OrderBy=default
	,@IsMfgCommunityRfq=0
	,@SearchText=N''
	,@ProcessIDs=@p25
	,@BuyerIndustryId=@p26

	GO

declare @p25 dbo.tbltype_ListOfProcesses

declare @p26 dbo.tbltype_ListOfBuyerIndustryId

exec [proc_get_RfqList_Vision_13042023]
	@ContactId=848283
	,@CompanyId=1274154
	,@RfqType=10
	,@CountryId=0
	,@ManufacturingLocationId=0
	,@IsActive=0
	,@IsPending=0
	,@IsIncomplete=0
	,@IsClosingIn4Days=0
	,@IsClosingIn24Hours=0
	,@IsQuoting=0
	,@IsAwarded=0
	,@IsDraft=1
	,@IsDraftAfterClose=0
	,@DraftBeforeRelease=0
	,@IsClosed=0
	,@PageNumber=1
	,@PageSize=20
	,@IsValidated=0
	,@IsUnvalidated=0
	,@IsOrderByDesc=1
	,@OrderBy=default
	,@IsMfgCommunityRfq=0
	,@SearchText=N''
	,@ProcessIDs=@p25
	,@BuyerIndustryId=@p26

*/

CREATE   PROCEDURE [dbo].[proc_get_RfqList_Vision]
	 @ContactId INT,
	 @CompanyId INT,
	 @RfqType INT,	
	 @ManufacturingLocationId INT = 0, 
	 @CountryId INT = 0, 
	 @IsActive BIT = 'false',
	 @IsPending BIT = 'false',
	 @IsIncomplete BIT = 'false',
	 @IsClosingIn4Days BIT = 'false',
	 @IsClosingIn24Hours BIT = 'false',
	 @IsClosed BIT = 'false',
	 @IsQuoting BIT = 'false',
	 @IsAwarded BIT = 'false',
	 @IsDraft BIT = 'false',
	 @DraftBeforeRelease BIT = 'false',
	 @IsDraftAfterClose BIT = 'false',
	 @PageNumber INT = 1,
	 @PageSize   INT = 24,
	 @IsValidated BIT = 'true',
	 @IsUnvalidated BIT = 'false',
	 @IsMfgCommunityRfq BIT = 'false',	 
	 @SearchText VARCHAR(50) = Null,
	 @IsOrderByDesc BIT = 1,
	 @OrderBy VARCHAR(50) = Null,
	 @ProcessIDs			as tbltype_ListOfProcesses			readonly,
	 @BuyerIndustryId    as tbltype_ListOfBuyerIndustryId    readonly
	  
	  
AS
-- =============================================
-- Author:		dp-Am. N.
-- Create date:  31/10/2018
-- Description:	Stored procedure to Get the RFQ details based on RFQ Type for Supplier
-- Modification:
-- Syntax: [proc_get_RfqList] <Contact_id>,<Company_id>,<RFQ_Type_id>
-- Example: [proc_get_RfqList] 216582,337455,3
--[proc_get_RfqList_Vision] 848283,1274154,10,92,NULL,NULL,NULL,NULL,NULL,Null,1,20,NULL,NULL,NULL,Null,'rfq_name'
--[proc_get_RfqList_Buyer] 216582,337455,12
--[proc_get_RfqList_Buyer] 216582,337455,6
-- =================================================================
--Version No – Change Date – Modified By      – CR No – Note
-- =================================================================
BEGIN

	set nocount on 

	--select '1' , getutcdate() dt

	/* M2-3384 : M & Vision - My RFQs - Search by Buyer's Industry -DB */
	drop table if exists #BuyerIndistry
	create table #BuyerIndistry (BuyerIndustryId int)

	drop table if exists #rfq_list
	create table #rfq_list (rfq_id int )

	drop table if exists #rfqs
	create table #rfqs (rfq_id int, rfq_created_on datetime , totalcount int, address_Id int null, city varchar(250) null, regionid int null, state varchar(250) null, countryid int null, country_name varchar(250) null)
	
	/* M2-2863 Vision - RFQs - Filter by Process - DB */
	drop table if exists #tmpprocesses
	create table #tmpprocesses
	(
		parent_part_category_id int null
		, part_category_id int null
	)
	/**/

	------------------------ All Vision Rfq --------------------
	--drop table if exists #tmpaddress
	--select * into #tmpaddress from useraddress



	drop table if exists #tmpmasterprocesses
	select distinct
		part_category_id
		, discipline_name
	into #tmpmasterprocesses
	from mp_mst_part_category	p		(nolock) 					
	where status_id = 2 and level = 0
	union
	select distinct
		p.part_category_id
		, case 
			when p.discipline_name = category.discipline_name then category.discipline_name 
			else category.discipline_name +' / '+ p.discipline_name
		  end discipline_name
	from mp_mst_part_category	p		(nolock) 	
	JOIN mp_mst_part_category category (nolock) on p.parent_part_category_id=category.part_category_id				
	where p.status_id = 2 and p.level = 1
	union
	select distinct 
		p.part_category_id
		, case 
			when p.discipline_name = category.discipline_name then category.discipline_name 
			else category.discipline_name +' / '+ p.discipline_name
		  end discipline_name
	from mp_rfq			a (nolock) 
	join mp_rfq_parts	b (nolock) on a.rfq_id = b.rfq_id and a.rfq_status_id = 2
	join mp_mst_part_category	p		(nolock)  on b.part_category_id = p.part_category_id
	join mp_mst_part_category category (nolock) on p.parent_part_category_id=category.part_category_id
	order by discipline_name


	/* M2-3837 Vision - RFQ Submitted to Pending Priority Time Stamp - DB */
	DROP TABLE IF EXISTS #tmp_proc_get_RfqList_Vision_RfqSubmitted
	
	IF @IsPending=1 AND @IsValidated = 1
	BEGIN
		SELECT rfq_id RfqId, MAX(creation_date) SubmittedDate INTO #tmp_proc_get_RfqList_Vision_RfqSubmitted
		FROM mp_rfq_revision (NOLOCK) where newvalue = 'Pending Approval'	
		GROUP BY rfq_id
	END
	/**/

	

	if (@RfqType = 10)	
	BEGIN	
			
			--select '2' , getutcdate() dt

			declare @sql_query nvarchar(max),
			@where_query nvarchar(max),
			@search_query nvarchar(max),
			@orderBy_query nvarchar(max),
			@sql_query1 nvarchar(max) 
	 
			/* M2-2863 Vision - RFQs - Filter by Process - DB */
			declare @processids1				as tbltype_ListOfProcesses
			
			/* M2-3384 : M & Vision - My RFQs - Search by Buyer's Industry -DB */
			insert into #BuyerIndistry SELECT * FROM @BuyerIndustryId
			
			/**/
	
			set @where_query =  
				
				case when @IsDraft = 0 AND @DraftBeforeRelease = 0 AND @IsDraftAfterClose = 0 then ' mp_rfq.rfq_status_id >=2 AND mp_rfq.rfq_status_id != 13	 ' else '' end
				+ case when @IsDraft = 1 then ' mp_rfq.rfq_status_id IN (1,14) 	 ' else '' end
				+ case when @IsDraft = 0 AND @DraftBeforeRelease = 1 AND @IsDraftAfterClose = 0 then ' mp_rfq.rfq_status_id IN (1,14) 	 ' else '' end
				+ case when @IsDraft = 0 AND @DraftBeforeRelease = 0 AND @IsDraftAfterClose = 1 then ' mp_rfq.rfq_status_id IN (1,14) 	 ' else '' end
				/* M2-3615 Vision - Add Directory RFQs under RFQs on the left menu - DB */
				+ CASE WHEN @IsMfgCommunityRfq =  0 THEN ' and IsMfgCommunityRfq = 0 ' ELSE ' and IsMfgCommunityRfq = 1 ' END
				/**/
				+ case when @IsPending = 'true' then 'AND ( mp_rfq.rfq_status_id = 2 )' else '' end 
				+ case when @IsActive  = 'true' then 'AND ( format(GETUTCDATE(),''yyyyMMdd'') <= format(mp_rfq.Quotes_needed_by,''yyyyMMdd'') )	' else '' end 
				+ case when @IsIncomplete  = 'true' then 'AND ( mp_rfq.rfq_status_id = 14 )' else '' end
				+ case when @IsClosingIn4Days  = 'true' then ' AND ( DATEDIFF(d, format(GETUTCDATE(),''yyyyMMdd''), format(mp_rfq.Quotes_needed_by,''yyyyMMdd'') ) <= 4 ) AND mp_rfq.rfq_id NOT IN (select rfq_id from mp_rfq_quote_SupplierQuote where rfq_id = mp_rfq.rfq_id  ) ' else '' end
				+ case when @IsClosingIn24Hours  = 'true' then 'AND ( DATEDIFF(hh, format(GETUTCDATE(),''yyyyMMdd''), format(mp_rfq.Quotes_needed_by,''yyyyMMdd'') ) <= 24 )' else '' end
				+ case when @IsClosed  = 'true' then 'AND ( format(GETUTCDATE(),''yyyyMMdd'') >  format(mp_rfq.Quotes_needed_by,''yyyyMMdd'') )' else '' end
				+ case when @IsValidated  = 'true' then 'AND ( mp_rfq.rfq_id IN ( SELECT rfq_id from mp_rfq join mp_contacts ON mp_rfq.contact_id = mp_contacts.contact_id where mp_contacts.Is_Validated_Buyer = 1) )' else '' end
				+ case when @IsUnvalidated  = 'true' then 'AND ( mp_rfq.rfq_id IN ( SELECT rfq_id from mp_rfq join mp_contacts ON mp_rfq.contact_id = mp_contacts.contact_id where mp_contacts.Is_Validated_Buyer = 0 or mp_contacts.Is_Validated_Buyer is null) )' else '' end
				+ case when (@CountryId > 0) then 'AND ( useraddress.CountryId = '+ CONVERT(VARCHAR(150),@CountryId)+')' else '' end
				+ case when (@ManufacturingLocationId in (4)) then 'AND ( mp_rfq_preferences.rfq_pref_manufacturing_location_id in (4,7))' when (@ManufacturingLocationId in (5)) then 'AND ( mp_rfq_preferences.rfq_pref_manufacturing_location_id in (5,7))' when (@ManufacturingLocationId > 0) then 'AND ( mp_rfq_preferences.rfq_pref_manufacturing_location_id = @ManufacturingLocationId1)' else '' end
				/* M2-2861 Vision - RFQs - Search Enhancements/filters - DB*/
				+ case when @IsQuoting  = 'true' then 'AND ( format(mp_rfq.Quotes_needed_by,''yyyyMMdd'') >= format(GETUTCDATE(),''yyyyMMdd'')  ) AND mp_rfq.rfq_status_id = 3	' else '' end 
				+ case when @IsAwarded  = 'true' then ' AND mp_rfq.rfq_status_id = 6	' else '' end 
				--+ case when @IsDraft  = 'true' then ' AND mp_rfq.rfq_status_id = 1	' else '' end 
				/**/
				/* M2-2863 Vision - RFQs - Filter by Process - DB */
				+ case when (select count(1) from @ProcessIDs) > 0 then 'AND  mp_rfq.rfq_id in (select * from  #rfq_list ) ' else ' ' end
				/**/
				/* M2-3384 : M & Vision - My RFQs - Search by Buyer's Industry -DB */
				+ case when (select count(1) from @BuyerIndustryId) > 0 then ' and mcst.supplier_type_id in (select * from  #BuyerIndistry) ' else '' end


		   set @orderBy_query = 
				
				+ case when (@OrderBy IS Null AND @IsOrderByDesc = 'true' AND @IsPending = 1 AND @IsValidated = 1 ) then 'ORDER BY Allrfqs.RfqSubmittedDate DESC' else '' end
				+ case when (@OrderBy IS Null AND @IsOrderByDesc = 'true' AND @IsPending = 1 AND @IsValidated = 1 ) then 'ORDER BY Allrfqs.RfqSubmittedDate DESC' else '' end
				+ case when (@OrderBy IS Null AND @IsOrderByDesc = 'false'  AND @IsPending = 1 AND @IsValidated = 1) then 'ORDER BY Allrfqs.RfqSubmittedDate' else '' end
				+ case when (@OrderBy IS Null AND @IsOrderByDesc = 'true' AND @IsPending = 1 AND @IsUnvalidated = 1 ) then 'ORDER BY Allrfqs.RFQCreatedOn DESC' else '' end
				+ case when (@OrderBy IS Null AND @IsOrderByDesc = 'false'  AND @IsPending = 1 AND @IsUnvalidated = 1) then 'ORDER BY Allrfqs.RFQCreatedOn' else '' end
				+ case when (@OrderBy IS Null AND @IsOrderByDesc = 'true'  AND @IsPending = 0) then 'ORDER BY Allrfqs.RFQCreatedOn DESC' else '' end
				+ case when (@OrderBy IS Null AND @IsOrderByDesc = 'false'  AND @IsPending = 0) then 'ORDER BY Allrfqs.RFQCreatedOn' else '' end
				+ case when (@OrderBy = 'rfq_name' AND @IsOrderByDesc = 'true') then 'ORDER BY Allrfqs.RFQName DESC ' else '' end
				+ case when (@OrderBy = 'rfq_name' AND @IsOrderByDesc = 'false') then 'ORDER BY Allrfqs.RFQName ' else '' end

	
			set @search_query =  
				  case when @SearchText Is NOT Null then 'AND ((mp_rfq.rfq_name Like ''%'+@SearchText+'%'')	OR (mp_rfq.rfq_id Like ''%'+@SearchText+'%'') OR (mp_companies.name Like ''%'+@SearchText+'%'') OR ((mp_contacts.first_name + '' '' +	mp_contacts.last_name) Like ''%'+@SearchText+'%'') OR (aspnetusers.Email Like ''%'+@SearchText+'%''))' else '' end 



			/* M2-2863 Vision - RFQs - Filter by Process - DB */
			insert into #tmpprocesses (parent_part_category_id , part_category_id)
			select distinct parent_part_category_id , part_category_id 
			from mp_mst_part_category a where part_category_id in (select processId from @ProcessIDs ) and status_id = 2 and level =1 

			insert into #tmpprocesses (parent_part_category_id , part_category_id)
			select distinct parent_part_category_id , part_category_id 
			from mp_mst_part_category a where parent_part_category_id in 
			(
				select processId from @ProcessIDs where  processId not in (select parent_part_category_id from #tmpprocesses) 
			) and status_id = 2 and level =1 
	
	        

			set @sql_query=			
			'
			insert into #rfq_list (rfq_id)
			select distinct a.rfq_id 
			from mp_rfq			a (nolock) 
			join mp_rfq_parts	b (nolock) on a.rfq_id = b.rfq_id 
			'
			+
			/* M2-3615 Vision - Add Directory RFQs under RFQs on the left menu - DB */
			CASE WHEN @IsMfgCommunityRfq =  0 THEN ' and a.IsMfgCommunityRfq = 0 ' ELSE ' and a.IsMfgCommunityRfq = 1 ' END
			/**/
			+
			'
			join mp_parts		c (nolock) on b.part_id  = c.part_id 
			where b.part_category_id in 
			(
				select part_category_id from  #tmpprocesses
			)
			'

			exec sp_executesql  @sql_query 
			,N'@processids1  tbltype_ListOfProcesses readonly'  --, @BuyerIndustryId1 tbltype_ListOfBuyerIndustryId readonly
			,@processids1  = @ProcessIDs
			--,@BuyerIndustryId1 = @BuyerIndustryId /* M2-3384 : M & Vision - My RFQs - Search by Buyer's Industry -DB */	
			/**/
			
			set @sql_query=			
			'
			WITH useraddress as
			(
				select 
					mp_addresses.address_Id
					, mp_addresses.address4 AS City		
					, mp_mst_region.REGION_ID AS RegionId 
					, case when ( mp_mst_region.REGION_ID = 0 ) then ''N/A'' else mp_mst_region.REGION_NAME  end AS [State]
					, mp_mst_country.country_id AS CountryId
					, case when (mp_mst_country.country_id = 0 ) then ''N/A'' else mp_mst_country.country_name  end AS country_name 
				from 
				mp_addresses (nolock)
				JOIN mp_mst_region  (nolock) ON mp_addresses.region_id = mp_mst_region.REGION_ID
				JOIN mp_mst_country  (nolock) ON mp_mst_region.country_Id = mp_mst_country.country_id
			)
			INSERT INTO #rfqs  (rfq_id  , rfq_created_on , totalcount , address_id , city , regionid , state , countryid , country_name )
			SELECT DISTINCT mp_rfq.rfq_id , mp_rfq.rfq_created_on , COUNT(mp_rfq.rfq_id) OVER() TotalCount , useraddress.address_Id	,useraddress.City	,useraddress.RegionId	,useraddress.State	,useraddress.CountryId	,useraddress.country_name
			FROM	mp_rfq			(NOLOCK) 
			JOIN	mp_contacts		(NOLOCK) ON		mp_rfq.contact_id = mp_contacts.contact_id
			JOIN	mp_companies	(NOLOCK) ON		mp_contacts.company_id = mp_companies.company_id
			JOIN	aspnetusers		(NOLOCK) ON		mp_contacts.user_id = aspnetusers.id
			LEFT JOIN useraddress			 ON mp_contacts.address_id = useraddress.address_id
			LEFT JOIN mp_rfq_preferences (nolock)  ON mp_rfq.rfq_id = mp_rfq_preferences.rfq_id
			/* M2-3384 : M & Vision - My RFQs - Search by Buyers Industry -DB */
			LEFT JOIN mp_company_supplier_types mcst (nolock) on mp_companies.company_id = mcst.company_id and mcst.is_buyer = 1
			WHERE '

			set @sql_query = @sql_query  + @where_query + @search_query 
			+  case when  (select count(1) from @ProcessIDs ) > 0 then ' and mp_rfq.rfq_id in (select * from #rfq_list)' else '' end
			+  case when @IsDraft = 0 AND @DraftBeforeRelease = 1 AND @IsDraftAfterClose = 0 then   ' AND EXISTS (SELECT rfq_id FROM mp_rfq_release_history (NOLOCK) WHERE  mp_rfq.rfq_id  = mp_rfq_release_history.rfq_id)  AND CONVERT(DATE,mp_rfq.Quotes_needed_by) > CONVERT(DATE,GETUTCDATE())  ' else '' end
			+  case when @IsDraft = 0 AND @DraftBeforeRelease = 0 AND @IsDraftAfterClose = 1 then   ' AND EXISTS (SELECT rfq_id FROM mp_rfq_release_history (NOLOCK) WHERE  mp_rfq.rfq_id  = mp_rfq_release_history.rfq_id) AND CONVERT(DATE,mp_rfq.Quotes_needed_by) < CONVERT(DATE,GETUTCDATE())  ' else '' end
			+  case when (@IsOrderByDesc = 'true' ) then 
						' ORDER BY  mp_rfq.rfq_created_on DESC ' + ' OFFSET '+ convert(varchar(50),@PageSize) +'   * ( '+ convert(varchar(50),@PageNumber) + ' - 1) ROWS FETCH NEXT '+ convert(varchar(50),@PageSize) + ' ROWS ONLY '
					else '' 
				end
			+  case when (@IsOrderByDesc = 'false' ) then 
						' ORDER BY  mp_rfq.rfq_created_on ASC ' + ' OFFSET '+ convert(varchar(50),@PageSize) +'   * ( '+ convert(varchar(50),@PageNumber) + ' - 1) ROWS FETCH NEXT '+ convert(varchar(50),@PageSize) + ' ROWS ONLY '
					else '' 
				end
			
			---exec sp_executesql  @sql_query ---- commented on 27-Sep-2023

			--- Reported slack issue and modified code on 27-Sep-2023
			EXECUTE sp_executesql  @sql_query
			,N'@ManufacturingLocationId1 INT', @ManufacturingLocationId1 = @ManufacturingLocationId 

			--select @sql_query
			--select * from #rfqs

			IF @IsDraft = 0 AND @DraftBeforeRelease = 0 AND @IsDraftAfterClose = 0
			BEGIN
					--select '3' , getutcdate() dt

					set @sql_query = 
					' 		  
					SELECT  * FROM(  
		  
					SELECT DISTINCT  
					mp_rfq.rfq_id AS RFQId
					, mp_rfq.rfq_name AS RFQName				 
					, mp_special_files.file_name AS file_name
					, floor(mp_rfq_parts.min_part_quantity)  AS Quantity			 
					, mp_rfq_parts.min_part_quantity_unit AS UnitValue
					, Processes.value AS PostProductionProcessValue
					, mp_mst_materials.material_name_en as  Material 
					, p.discipline_name  AS Process
					, mp_companies.name AS Buyer
					, mp_Companies.company_id as buyer_company_id
					, mp_mst_rfq_buyerStatus.rfq_buyerstatus_li_key AS RFQStatus
					, mp_rfq.rfq_created_on AS RFQCreatedOn
					, mp_rfq.Quotes_needed_by AS QuotesNeededBy
					, mp_rfq.award_date AS AwardDate
					, mp_rfq_supplier_likes.is_rfq_like AS IsRfqLike
					, mp_star_rating.no_of_stars AS NoOfStars
					, '+COALESCE('ThumbnailFile.File_Name','')+' AS RfqThumbnail
					, mp_contacts.contact_id AS BuyerContactId	
					, mp_rfq.payment_term_id AS payment_term_id	
					, rfq.totalcount AS TotalCount
					, rfq.City			AS City		 
					, rfq.[State]		AS [State]
					, rfq.CountryId		AS CountryId
					, rfq.country_name	AS Country	
					, mc.first_name + '' '' +	mc.last_name as BuyerOwner
					, mp_rfq.rfq_quality		AS RFQQuality
					, aspnetusers.Email			AS BuyerEmail
					, (mp_contacts.first_name + '' '' +	mp_contacts.last_name) AS BuyerName
					, mp_rfq_preferences.rfq_pref_manufacturing_location_id AS RFQLocationId
					/*M2-2458 : Buyers - Tile and Row - Add Dates and # of Quotes on to RFQ tiles in MY RFQs  -DB*/
					,(select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where mp_rfq.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0) as RFQQuoteCount
					,'
					+
					CASE WHEN @IsPending=1 AND @IsValidated = 1 THEN ' RfqSubmitted.SubmittedDate AS RfqSubmittedDate ' ELSE ' NULL AS RfqSubmittedDate ' END
					+
					'

					FROM #rfqs rfq
					JOIN mp_rfq							(nolock) ON rfq.rfq_id = mp_rfq.rfq_id
					JOIN mp_contacts					(nolock) ON mp_rfq.contact_id=mp_contacts.contact_id 	
					JOIN mp_rfq_parts					(nolock) ON mp_rfq.rfq_id = mp_rfq_parts.rfq_id and Is_Rfq_Part_Default =  1
					LEFT JOIN mp_rfq_parts_file			(nolock) ON mp_rfq_parts.rfq_part_id = mp_rfq_parts_file.rfq_part_id
					JOIN mp_special_files				(nolock) ON mp_special_files.file_id = mp_rfq_parts_file.file_id
					JOIN mp_parts						(nolock) ON mp_parts.part_id = mp_rfq_parts.part_id 
					JOIN mp_mst_rfq_buyerStatus		(nolock) ON mp_rfq.rfq_status_id=mp_mst_rfq_buyerStatus.rfq_buyerstatus_id
					JOIN mp_companies					(nolock) ON mp_contacts.company_id=mp_companies.company_id
					LEFT JOIN mp_contacts mc				(nolock) ON mp_companies.Assigned_SourcingAdvisor=mc.contact_id
					JOIN mp_rfq_part_quantity			(nolock) ON mp_rfq_part_quantity.rfq_part_id = mp_rfq_parts.rfq_part_id
					JOIN #tmpmasterprocesses	p		(nolock) ON p.part_category_id = mp_rfq_parts.part_category_id 
					LEFT JOIN mp_rfq_supplier_likes	(nolock) ON mp_rfq_supplier_likes.rfq_id = mp_rfq.rfq_id and mp_rfq.contact_id = mp_rfq_supplier_likes.contact_id
					LEFT JOIN mp_special_files			(nolock) AS ThumbnailFile ON ThumbnailFile.file_id = mp_rfq.file_id
					left join mp_star_rating			(nolock) on mp_star_rating.company_id = mp_contacts.company_id	
					LEFT JOIN mp_system_parameters AS Processes (nolock) ON Processes.id = mp_rfq_parts.Post_Production_Process_id AND Processes.sys_key = ''@PostProdProcesses''
					LEFT JOIN mp_mst_materials		(nolock) ON mp_mst_materials.material_id = mp_rfq_parts.material_id
					LEFT JOIN mp_system_parameters AS Unit (nolock) ON Unit.id = mp_parts.part_qty_unit_id AND Unit.sys_key = ''@UNIT2_LIST'' 
					JOIN aspnetusers					(nolock) ON  mp_contacts.user_id = aspnetusers.id
					JOIN mp_rfq_preferences (nolock)  ON mp_rfq.rfq_id = mp_rfq_preferences.rfq_id
					/* M2-3384 : M & Vision - My RFQs - Search by Buyers Industry -DB */
					LEFT JOIN mp_company_supplier_types mcst (nolock) on mp_companies.company_id = mcst.company_id and mcst.is_buyer = 1 
					'
					+
					CASE WHEN @IsPending=1 AND @IsValidated = 1 THEN ' LEFT JOIN #tmp_proc_get_RfqList_Vision_RfqSubmitted RfqSubmitted ON mp_rfq.rfq_id = RfqSubmitted.RfqId ' ELSE '' END
					+
					'
					WHERE mp_rfq_parts_file.is_primary_file = 1 '
						
				set @sql_query1 = @sql_query  
				+ ') AS AllRfqs
				left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history group by rfq_id ) rfq_release  on AllRfqs.RFQId = rfq_release.rfq_id	
				ORDER BY AllRfqs.RFQCreatedOn DESC '
					
			END
			/* M2-3520 Vision - Draft RFQ filter revisions - DB */
			ELSE IF @IsDraft = 1
			BEGIN
				--select '4' , getutcdate() dt
									
				set @sql_query = 
					' 		  
					SELECT  *  FROM(  
		  
					SELECT DISTINCT  
					mp_rfq.rfq_id AS RFQId
					, mp_rfq.rfq_name AS RFQName				 
					, mp_special_files.file_name AS file_name
					, floor(mp_rfq_parts.min_part_quantity)  AS Quantity			 
					, mp_rfq_parts.min_part_quantity_unit AS UnitValue
					, Processes.value AS PostProductionProcessValue
					, mp_mst_materials.material_name_en as  Material 
					, case when category.discipline_name is null then p.discipline_name  when category.discipline_name = p.discipline_name then p.discipline_name else category.discipline_name +'' / ''+ p.discipline_name end AS Process
					, mp_companies.name AS Buyer
					, mp_Companies.company_id as buyer_company_id
					, mp_mst_rfq_buyerStatus.rfq_buyerstatus_li_key AS RFQStatus
					, mp_rfq.rfq_created_on AS RFQCreatedOn
					, mp_rfq.Quotes_needed_by AS QuotesNeededBy
					, mp_rfq.award_date AS AwardDate
					, mp_rfq_supplier_likes.is_rfq_like AS IsRfqLike
					, mp_star_rating.no_of_stars AS NoOfStars
					, '+COALESCE('ThumbnailFile.File_Name','')+' AS RfqThumbnail
					--, MessagesMst.message_date AS message_date	
					, mp_contacts.contact_id AS BuyerContactId	
					, mp_rfq.payment_term_id AS payment_term_id		
					, rfq.totalcount AS TotalCount
					, rfq.City			AS City		 
					, rfq.[State]		AS [State]
					, rfq.CountryId		AS CountryId
					, rfq.country_name	AS Country	
					, mc.first_name + '' '' +	mc.last_name as BuyerOwner
					, mp_rfq.rfq_quality		AS RFQQuality
					, aspnetusers.Email			AS BuyerEmail
					, (mp_contacts.first_name + '' '' +	mp_contacts.last_name) AS BuyerName
					, mp_rfq_preferences.rfq_pref_manufacturing_location_id AS RFQLocationId
					/*M2-2458 : Buyers - Tile and Row - Add Dates and # of Quotes on to RFQ tiles in MY RFQs  -DB*/
					,(select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where mp_rfq.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0) as RFQQuoteCount
					,  NULL AS RfqSubmittedDate /* M2-3837 Vision - RFQ Submitted to Pending Priority Time Stamp - DB */
					FROM #rfqs rfq
					JOIN mp_rfq							(nolock) ON rfq.rfq_id = mp_rfq.rfq_id 
						JOIN mp_contacts					(nolock) ON mp_rfq.contact_id=mp_contacts.contact_id 
						LEFT JOIN mp_rfq_parts					(nolock) ON mp_rfq.rfq_id = mp_rfq_parts.rfq_id and Is_Rfq_Part_Default =  1
						LEFT JOIN mp_rfq_parts_file				(nolock) ON mp_rfq_parts.rfq_part_id = mp_rfq_parts_file.rfq_part_id AND mp_rfq_parts_file.is_primary_file = 1 	
						LEFT JOIN mp_special_files				(nolock) ON mp_special_files.file_id = mp_rfq_parts_file.file_id
						LEFT JOIN mp_parts						(nolock) ON mp_parts.part_id = mp_rfq_parts.part_id 
						LEFT JOIN mp_mst_rfq_buyerStatus		(nolock) ON mp_rfq.rfq_status_id=mp_mst_rfq_buyerStatus.rfq_buyerstatus_id
						LEFT JOIN mp_companies					(nolock) ON mp_contacts.company_id=mp_companies.company_id
						LEFT JOIN mp_contacts mc				(nolock) ON mp_companies.Assigned_SourcingAdvisor=mc.contact_id
						LEFT JOIN mp_rfq_part_quantity			(nolock) ON mp_rfq_part_quantity.rfq_part_id = mp_rfq_parts.rfq_part_id
						LEFT JOIN mp_mst_part_category	p		(nolock) ON p.part_category_id = mp_rfq_parts.part_category_id 
						/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
						LEFT JOIN mp_mst_part_category category (nolock) on p.parent_part_category_id=category.part_category_id
						/**/
						LEFT JOIN mp_rfq_supplier_likes	(nolock) ON mp_rfq_supplier_likes.rfq_id = mp_rfq.rfq_id and mp_rfq.contact_id = mp_rfq_supplier_likes.contact_id
						LEFT JOIN mp_special_files			(nolock) AS ThumbnailFile ON ThumbnailFile.file_id = mp_rfq.file_id
						left join mp_star_rating			(nolock) on mp_star_rating.company_id = mp_contacts.company_id	
						LEFT JOIN mp_system_parameters AS Processes (nolock) ON Processes.id = mp_rfq_parts.Post_Production_Process_id AND Processes.sys_key = ''@PostProdProcesses''
						LEFT JOIN mp_mst_materials		(nolock) ON mp_mst_materials.material_id = mp_rfq_parts.material_id
						LEFT JOIN mp_system_parameters AS Unit (nolock) ON Unit.id = mp_parts.part_qty_unit_id AND Unit.sys_key = ''@UNIT2_LIST'' 
						JOIN aspnetusers					(nolock) ON  mp_contacts.user_id = aspnetusers.id
						LEFT JOIN mp_rfq_preferences (nolock)  ON mp_rfq.rfq_id = mp_rfq_preferences.rfq_id
						/* M2-3384 : M & Vision - My RFQs - Search by Buyers Industry -DB */
						LEFT JOIN mp_company_supplier_types mcst (nolock) on mp_companies.company_id = mcst.company_id and mcst.is_buyer = 1  
				WHERE 	mp_rfq.rfq_status_id IN (1,14) 
				'
				
			   

				set @sql_query1 = @sql_query  + 
				') AS AllRfqs
				left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history group by rfq_id ) rfq_release  on Allrfqs.RFQId = rfq_release.rfq_id		 '
				+ @orderBy_query 

			END
			ELSE IF @IsDraft = 0 AND @DraftBeforeRelease = 1 AND @IsDraftAfterClose = 0
			BEGIN
				--select '5' , getutcdate() dt

				set @sql_query = 
					' 		  
					SELECT  * FROM(  
		  
					SELECT DISTINCT  
					mp_rfq.rfq_id AS RFQId
					, mp_rfq.rfq_name AS RFQName				 
					, mp_special_files.file_name AS file_name
					, floor(mp_rfq_parts.min_part_quantity)  AS Quantity			 
					, mp_rfq_parts.min_part_quantity_unit AS UnitValue
					, Processes.value AS PostProductionProcessValue
					, mp_mst_materials.material_name_en as  Material 
					, case when category.discipline_name is null then p.discipline_name  when category.discipline_name = p.discipline_name then p.discipline_name else category.discipline_name +'' / ''+ p.discipline_name end AS Process
					, mp_companies.name AS Buyer
					, mp_Companies.company_id as buyer_company_id
					, mp_mst_rfq_buyerStatus.rfq_buyerstatus_li_key AS RFQStatus
					, mp_rfq.rfq_created_on AS RFQCreatedOn
					, mp_rfq.Quotes_needed_by AS QuotesNeededBy
					, mp_rfq.award_date AS AwardDate
					, mp_rfq_supplier_likes.is_rfq_like AS IsRfqLike
					, mp_star_rating.no_of_stars AS NoOfStars
					, '+COALESCE('ThumbnailFile.File_Name','')+' AS RfqThumbnail
					--, MessagesMst.message_date AS message_date	
					, mp_contacts.contact_id AS BuyerContactId	
					, mp_rfq.payment_term_id AS payment_term_id	
					, rfq.totalcount AS TotalCount
					, rfq.City			AS City		 
					, rfq.[State]		AS [State]
					, rfq.CountryId		AS CountryId
					, rfq.country_name	AS Country	
					, mc.first_name + '' '' +	mc.last_name as BuyerOwner
					, mp_rfq.rfq_quality		AS RFQQuality
					, aspnetusers.Email			AS BuyerEmail
					, (mp_contacts.first_name + '' '' +	mp_contacts.last_name) AS BuyerName
					, mp_rfq_preferences.rfq_pref_manufacturing_location_id AS RFQLocationId
					/*M2-2458 : Buyers - Tile and Row - Add Dates and # of Quotes on to RFQ tiles in MY RFQs  -DB*/
					,(select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where mp_rfq.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0) as RFQQuoteCount
					,  NULL AS RfqSubmittedDate /* M2-3837 Vision - RFQ Submitted to Pending Priority Time Stamp - DB */
					FROM #rfqs rfq
					JOIN mp_rfq							(nolock) ON rfq.rfq_id = mp_rfq.rfq_id 
						JOIN mp_contacts					(nolock) ON mp_rfq.contact_id=mp_contacts.contact_id 
						LEFT JOIN mp_rfq_parts					(nolock) ON mp_rfq.rfq_id = mp_rfq_parts.rfq_id and Is_Rfq_Part_Default =  1
						LEFT JOIN mp_rfq_parts_file				(nolock) ON mp_rfq_parts.rfq_part_id = mp_rfq_parts_file.rfq_part_id AND mp_rfq_parts_file.is_primary_file = 1 	
						LEFT JOIN mp_special_files				(nolock) ON mp_special_files.file_id = mp_rfq_parts_file.file_id
						LEFT JOIN mp_parts						(nolock) ON mp_parts.part_id = mp_rfq_parts.part_id 
						LEFT JOIN mp_mst_rfq_buyerStatus		(nolock) ON mp_rfq.rfq_status_id=mp_mst_rfq_buyerStatus.rfq_buyerstatus_id
						LEFT JOIN mp_companies					(nolock) ON mp_contacts.company_id=mp_companies.company_id
						LEFT JOIN mp_contacts mc				(nolock) ON mp_companies.Assigned_SourcingAdvisor=mc.contact_id
						LEFT JOIN mp_rfq_part_quantity			(nolock) ON mp_rfq_part_quantity.rfq_part_id = mp_rfq_parts.rfq_part_id
						LEFT JOIN mp_mst_part_category	p		(nolock) ON p.part_category_id = mp_rfq_parts.part_category_id 
						/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
						LEFT JOIN mp_mst_part_category category (nolock) on p.parent_part_category_id=category.part_category_id
						/**/
						LEFT JOIN mp_rfq_supplier_likes	(nolock) ON mp_rfq_supplier_likes.rfq_id = mp_rfq.rfq_id and mp_rfq.contact_id = mp_rfq_supplier_likes.contact_id
						LEFT JOIN mp_special_files			(nolock) AS ThumbnailFile ON ThumbnailFile.file_id = mp_rfq.file_id
								 		 
						left join mp_star_rating			(nolock) on mp_star_rating.company_id = mp_contacts.company_id	
						LEFT JOIN mp_system_parameters AS Processes (nolock) ON Processes.id = mp_rfq_parts.Post_Production_Process_id AND Processes.sys_key = ''@PostProdProcesses''
						LEFT JOIN mp_mst_materials		(nolock) ON mp_mst_materials.material_id = mp_rfq_parts.material_id
						LEFT JOIN mp_system_parameters AS Unit (nolock) ON Unit.id = mp_parts.part_qty_unit_id AND Unit.sys_key = ''@UNIT2_LIST'' 
						JOIN aspnetusers					(nolock) ON  mp_contacts.user_id = aspnetusers.id
						LEFT JOIN mp_rfq_preferences (nolock)  ON mp_rfq.rfq_id = mp_rfq_preferences.rfq_id
						/* M2-3384 : M & Vision - My RFQs - Search by Buyers Industry -DB */
						LEFT JOIN mp_company_supplier_types mcst (nolock) on mp_companies.company_id = mcst.company_id and mcst.is_buyer = 1  
				WHERE 	mp_rfq.rfq_status_id IN (1,14) '
				
				set @sql_query1 = @sql_query +
				') AS AllRfqs
				left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history group by rfq_id ) rfq_release  on Allrfqs.RFQId = rfq_release.rfq_id		 '
				+ @orderBy_query 

			END
			ELSE IF @IsDraft = 0 AND @DraftBeforeRelease = 0 AND @IsDraftAfterClose = 1
			BEGIN
				--select '6' , getutcdate() dt


				set @sql_query = 
					' 		  
					SELECT  * FROM(  
		  
					SELECT DISTINCT  
					mp_rfq.rfq_id AS RFQId
					, mp_rfq.rfq_name AS RFQName				 
					, mp_special_files.file_name AS file_name
					, floor(mp_rfq_parts.min_part_quantity)  AS Quantity			 
					, mp_rfq_parts.min_part_quantity_unit AS UnitValue
					, Processes.value AS PostProductionProcessValue
					, mp_mst_materials.material_name_en as  Material 
					, case when category.discipline_name is null then p.discipline_name  when category.discipline_name = p.discipline_name then p.discipline_name else category.discipline_name +'' / ''+ p.discipline_name end AS Process
					, mp_companies.name AS Buyer
					, mp_Companies.company_id as buyer_company_id
					, mp_mst_rfq_buyerStatus.rfq_buyerstatus_li_key AS RFQStatus
					, mp_rfq.rfq_created_on AS RFQCreatedOn
					, mp_rfq.Quotes_needed_by AS QuotesNeededBy
					, mp_rfq.award_date AS AwardDate
					, mp_rfq_supplier_likes.is_rfq_like AS IsRfqLike
					, mp_star_rating.no_of_stars AS NoOfStars
					, '+COALESCE('ThumbnailFile.File_Name','')+' AS RfqThumbnail
					--, MessagesMst.message_date AS message_date	
					, mp_contacts.contact_id AS BuyerContactId	
					, mp_rfq.payment_term_id AS payment_term_id	
					, rfq.totalcount AS TotalCount
					, rfq.City			AS City		 
					, rfq.[State]		AS [State]
					, rfq.CountryId		AS CountryId
					, rfq.country_name	AS Country	
					, mc.first_name + '' '' +	mc.last_name as BuyerOwner
					, mp_rfq.rfq_quality		AS RFQQuality
					, aspnetusers.Email			AS BuyerEmail
					, (mp_contacts.first_name + '' '' +	mp_contacts.last_name) AS BuyerName
					, mp_rfq_preferences.rfq_pref_manufacturing_location_id AS RFQLocationId
					/*M2-2458 : Buyers - Tile and Row - Add Dates and # of Quotes on to RFQ tiles in MY RFQs  -DB*/
					,(select count(1) from mp_rfq_quote_supplierquote (nolock) 
								where mp_rfq.rfq_id = rfq_id and is_quote_submitted = 1 and is_rfq_resubmitted = 0) as RFQQuoteCount
					,  NULL AS RfqSubmittedDate  /* M2-3837 Vision - RFQ Submitted to Pending Priority Time Stamp - DB */
					FROM #rfqs rfq
					JOIN mp_rfq							(nolock) ON rfq.rfq_id = mp_rfq.rfq_id 
						JOIN mp_contacts					(nolock) ON mp_rfq.contact_id=mp_contacts.contact_id 
						LEFT JOIN mp_rfq_parts					(nolock) ON mp_rfq.rfq_id = mp_rfq_parts.rfq_id and Is_Rfq_Part_Default =  1
						LEFT JOIN mp_rfq_parts_file				(nolock) ON mp_rfq_parts.rfq_part_id = mp_rfq_parts_file.rfq_part_id AND mp_rfq_parts_file.is_primary_file = 1 	
						LEFT JOIN mp_special_files				(nolock) ON mp_special_files.file_id = mp_rfq_parts_file.file_id
						LEFT JOIN mp_parts						(nolock) ON mp_parts.part_id = mp_rfq_parts.part_id 
						LEFT JOIN mp_mst_rfq_buyerStatus		(nolock) ON mp_rfq.rfq_status_id=mp_mst_rfq_buyerStatus.rfq_buyerstatus_id
						LEFT JOIN mp_companies					(nolock) ON mp_contacts.company_id=mp_companies.company_id
						LEFT JOIN mp_contacts mc				(nolock) ON mp_companies.Assigned_SourcingAdvisor=mc.contact_id
						LEFT JOIN mp_rfq_part_quantity			(nolock) ON mp_rfq_part_quantity.rfq_part_id = mp_rfq_parts.rfq_part_id
						LEFT JOIN mp_mst_part_category	p		(nolock) ON p.part_category_id = mp_rfq_parts.part_category_id 
						/* M2-3202 Buyer and M - Change the tiles and rows to include parent category */
						LEFT JOIN mp_mst_part_category category (nolock) on p.parent_part_category_id=category.part_category_id
						/**/
						LEFT JOIN mp_rfq_supplier_likes	(nolock) ON mp_rfq_supplier_likes.rfq_id = mp_rfq.rfq_id and mp_rfq.contact_id = mp_rfq_supplier_likes.contact_id
						LEFT JOIN mp_special_files			(nolock) AS ThumbnailFile ON ThumbnailFile.file_id = mp_rfq.file_id								 		 
						left join mp_star_rating			(nolock) on mp_star_rating.company_id = mp_contacts.company_id	
						LEFT JOIN mp_system_parameters AS Processes (nolock) ON Processes.id = mp_rfq_parts.Post_Production_Process_id AND Processes.sys_key = ''@PostProdProcesses''
						LEFT JOIN mp_mst_materials		(nolock) ON mp_mst_materials.material_id = mp_rfq_parts.material_id
						LEFT JOIN mp_system_parameters AS Unit (nolock) ON Unit.id = mp_parts.part_qty_unit_id AND Unit.sys_key = ''@UNIT2_LIST'' 
						JOIN aspnetusers					(nolock) ON  mp_contacts.user_id = aspnetusers.id
						JOIN mp_rfq_preferences (nolock)  ON mp_rfq.rfq_id = mp_rfq_preferences.rfq_id
						/* M2-3384 : M & Vision - My RFQs - Search by Buyers Industry -DB */
						LEFT JOIN mp_company_supplier_types mcst (nolock) on mp_companies.company_id = mcst.company_id and mcst.is_buyer = 1  
				WHERE 	mp_rfq.rfq_status_id IN (1,14) 	'
				
				set @sql_query1 = @sql_query  +
				') AS AllRfqs
				left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history group by rfq_id ) rfq_release  on Allrfqs.RFQId = rfq_release.rfq_id		 '
				+ @orderBy_query 

			END
			/**/
			--select '7' , getutcdate() dt
			EXECUTE sp_executesql @sql_query1,N'@CountryId1 INT,@ManufacturingLocationId1 INT', @CountryId1 = @CountryId , @ManufacturingLocationId1 = @ManufacturingLocationId 
			--select '8' , getutcdate() dt
			--SELECT @sql_query1 , @CountryId , @ManufacturingLocationId
	END	

	 

END
