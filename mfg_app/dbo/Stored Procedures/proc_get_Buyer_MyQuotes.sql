
/*

	DECLARE @Total_Count INT

	exec proc_get_Buyer_MyQuotes 
		@BuyerContactId=1335874
		,@TabId=5
		,@StatusId=0
		,@TerritoryId=0
		,@PageNumber=1
		,@PageSize=24
		,@IsOrderByDesc=1
		,@OrderBy=N'QuoteDate'
		,@Search=N''
		,@TotalCount=@Total_Count output


	SELECT @Total_Count

*/


CREATE PROCEDURE [dbo].[proc_get_Buyer_MyQuotes]
(
	@BuyerContactId		INT
	,@PageNumber		INT				=1
	,@PageSize			INT				=20
	,@IsOrderByDesc		BIT				='TRUE'
	,@OrderBy			VARCHAR(100)	= NULL
	,@TabId				SMALLINT		= 1		-- 1(All) ,2(Not Reviewed) ,3(Reviewed) ,4(Declined) , 5(Archived)
	,@StatusId			SMALLINT		= 0		-- 0(All) ,3(Quoting) ,5(Closed) ,6(Awarded)
	,@TerritoryId		SMALLINT		= 0		-- 0(All) ,2(Europe) ,3(Asia) ,4(United States) ,5(Canada) ,6(Mexico / South America) ,7(USA & Canada)
	,@Search			VARCHAR(300)	= NULL
	,@TotalCount		INT OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON

	/*
	Feb 07,2020 - M2-2624 Buyer - Change New Quotes page to My Quotes ON the LEFT menu, add filters AND enhancements - DB
	*/
	

	DECLARE @CompanyId INT ;
	DECLARE @BlacklistedCompanies TABLE (CompanyId INT)	
	DECLARE @SearchLength	INT = 0
	DECLARE @SQLQuery NVARCHAR(MAX) = ''

	DROP TABLE IF EXISTS #tmpBuyerMyQuotes
	DROP TABLE IF EXISTS #tmpBuyerMyQuotesExcludeRfq

	DECLARE @BuyerMyQuotes TABLE 
	(
		RfqId					INT				NULL,
		RfqName					VARCHAR(200)	NULL,
		RfqStatusId				SMALLINT		NULL,
		SupplierId				INT				NULL,
		Supplier				VARCHAR(200)	NULL,
		SupplierCompanyId		INT				NULL,
		SupplierCompany			VARCHAR(300)	NULL,
		SupplierTerritoryId		SMALLINT		NULL,
		SupplierTerritory		VARCHAR(200)	NULL,
		IsReviewedByBuyer		BIT				NULL,
		RfqResubmittedByBuyer	BIT				NULL,
		SupplierQuoteId			INT				NULL,
		QuoteDate				DATETIME		NULL,
		QuoteStatusId			SMALLINT		NULL,
		QuoteDeclined			BIT				NULL,
		PartId					INT				NULL,
		PartQtyId				INT				NULL,
		PartQtyLevel			SMALLINT		NULL,
		PerUnitPrice			NUMERIC(18,4)	NULL,
		ToolingAmount			NUMERIC(18,4)	NULL,
		MiscAmount				NUMERIC(18,4)	NULL,
		ShippingAmount			NUMERIC(18,4)	NULL,
		QtyAwarded				NUMERIC(18,4)	NULL,
		BuyerFeedbackId			INT				NULL,
		NoOfStars				NUMERIC(18,2)	NULL,
		/* M2-3318 Buyer - Change the My Quotes page to reflect Viewed and Reviewed - DB */
		IsViewedByBuyer				BIT				NULL,
		/**/	
		/* M2-4793 */
		WithOrderManagement				BIT				NULL
		/**/
	)

	CREATE TABLE #tmpBuyerMyQuotes 
	(
		RfqId					INT				NULL,
		RfqName					VARCHAR(200)	NULL,
		RfqStatusId				SMALLINT		NULL,
		SupplierId				INT				NULL,
		Supplier				VARCHAR(200)	NULL,
		SupplierCompanyId		INT				NULL,
		SupplierCompany			VARCHAR(300)	NULL,
		SupplierTerritoryId		SMALLINT		NULL,
		SupplierTerritory		VARCHAR(200)	NULL,
		IsReviewedByBuyer		BIT				NULL,
		RfqResubmittedByBuyer	BIT				NULL,
		SupplierQuoteId			INT				NULL,
		QuoteDate				DATETIME		NULL,
		QuoteStatusId			SMALLINT		NULL,
		QuoteDeclined			BIT				NULL,
		Qty1					NUMERIC(18,4)	NULL,
		Qty2					NUMERIC(18,4)	NULL,
		Qty3					NUMERIC(18,4)	NULL,
		BuyerFeedbackId			INT				NULL,
		NoOfStars				NUMERIC(18,2)	NULL,
		/* M2-3318 Buyer - Change the My Quotes page to reflect Viewed and Reviewed - DB */
		IsViewedByBuyer			BIT				NULL,
		/**/	
		/* M2-4793 */
		WithOrderManagement				BIT				NULL
		/**/
	)

	CREATE TABLE #tmpBuyerMyQuotesExcludeRfq
	(
		RfqStatusId				SMALLINT		NULL
	)

	/* M2-3775 Buyer - Add Archive functions to My Quotes - DB */
	INSERT INTO #tmpBuyerMyQuotesExcludeRfq VALUES (1),(13)
	/**/


	DECLARE @SupplierCompanies TABLE 
	(
		SupplierCompanyId				INT				NULL,
		SupplierCompany					VARCHAR(300)	NULL,
		SupplierTerritoryId				SMALLINT		NULL	
	)	

	INSERT INTO @SupplierCompanies (SupplierCompanyId ,SupplierCompany ,SupplierTerritoryId)
	SELECT company_id , name , Manufacturing_location_id FROM mp_companies (NOLOCK)	WHERE company_id <> 0

	SET @Search = ISNULL(@Search,'')
	
	IF @PageNumber = 0 AND @PageSize =0 
	BEGIN
		SET @PageNumber = 1
		SET @PageSize	= 20
	END

	SET @OrderBy = ISNULL(@OrderBy,'QuoteDate')
	
	SET @CompanyId = (SELECT  company_id FROM mp_contacts (NOLOCK) WHERE contact_id  = @BuyerContactId)



	
	INSERT INTO @BlacklistedCompanies (CompanyId)
    SELECT DISTINCT a.company_id FROM mp_book_details  a 
    JOIN mp_books b ON a.book_id = b.book_id      
    WHERE bk_type= 5 AND b.contact_id = @BuyerContactId
	UNION  
	SELECT DISTINCT d.company_id FROM mp_book_details  a 
    JOIN mp_books b ON a.book_id = b.book_id   
	JOIN mp_contacts d ON b.contact_Id = d.contact_Id AND  a.company_id = @CompanyId
    WHERE bk_type= 5 

	INSERT INTO @BuyerMyQuotes
	(
		RfqId ,RfqName	,RfqStatusId	,SupplierId	,Supplier	,SupplierCompanyId ,SupplierCompany ,SupplierTerritoryId ,SupplierTerritory	
		,IsReviewedByBuyer	,RfqResubmittedByBuyer	,SupplierQuoteId	,QuoteDate	,QuoteStatusId ,QuoteDeclined	
		,PartId	,PartQtyId	,PartQtyLevel	,PerUnitPrice	,ToolingAmount	,MiscAmount	,ShippingAmount	,QtyAwarded,BuyerFeedbackId , NoOfStars, IsViewedByBuyer,WithOrderManagement
	)
	SELECT 
		DISTINCT 
			a.rfq_id				AS RfqId
			,a.rfq_name				AS RfqName
			,a.rfq_status_id		AS RfqStatusId
			,b.contact_id			AS SupplierId
			,(c.first_name + ' ' + c.last_name ) AS Supplier
			,c.company_id			AS SupplierCompanyId
			,g.SupplierCompany		AS SupplierCompany
			,g.SupplierTerritoryId	AS SupplierTerritoryId
			,h.territory_classification_name AS SupplierTerritory
			,b.is_reviewed			AS IsReviewedByBuyer
			,is_rfq_resubmitted		AS RfqResubmittedByBuyer
			,b.rfq_quote_SupplierQuote_id	AS SupplierQuoteId
			,b.quote_date			AS QuoteDate
			,d.rfq_userStatus_id	AS QuoteStatusId
			,b.is_quote_declined	AS QuoteDeclined
			,e.rfq_part_id			AS PartId
			,e.rfq_part_quantity_id	AS PartQtyId
			,f.quantity_level		AS PartQtyLevel
			,e.per_unit_price		AS PerUnitPrice
			,e.tooling_amount		AS ToolingAmount 
			,e.miscellaneous_amount AS MiscAmount
			,e.shipping_amount		AS ShippingAmount
			,e.awarded_qty			AS QtyAwarded
			,b.buyer_feedback_id	AS BuyerFeedbackId
			,i.no_of_stars			AS NoOfStars 
			,b.IsViewed				AS IsViewedByBuyer
			/* M2-4793 */
			,a.WithOrderManagement  
			/**/
		FROM 
		mp_rfq									a	(NOLOCK) 
		JOIN mp_rfq_quote_supplierquote			b	(NOLOCK)	ON a.rfq_id = b.rfq_id 
			AND a.contact_id =@BuyerContactId 
			AND is_rfq_resubmitted = (CASE WHEN @TabId = 4 THEN 1  ELSE 0 END) 
			AND is_quote_submitted = 1
			/* Jan 21, 2021 - Email RE: Buyer mnunuparov@gmail.com  - Exclude draft Rfq from My Quotes page*/
			AND a.rfq_status_id not in (SELECT * FROM #tmpBuyerMyQuotesExcludeRfq)
			/**/
			/* M2-3775 Buyer - Add Archive functions to My Quotes - DB */
			AND ISNULL(a.IsArchived,0) = (CASE WHEN @TabId = 5 THEN 1  ELSE 0 END) 
			/**/
		JOIN mp_contacts						c	(NOLOCK)	ON b.contact_id = c.contact_id		
		LEFT JOIN mp_rfq_quote_suplierstatuses	d	(NOLOCK)	ON b.rfq_id = d.rfq_id AND d.contact_id = b.contact_id
		JOIN mp_rfq_quote_items					e	(NOLOCK)	ON b.rfq_quote_SupplierQuote_id = e.rfq_quote_SupplierQuote_id 
		JOIN mp_rfq_part_quantity				f	(NOLOCK)	ON e.rfq_part_id = f.rfq_part_id AND e.rfq_part_quantity_id = f.rfq_part_quantity_id
		JOIN @SupplierCompanies					g		ON c.company_id = g.SupplierCompanyId
		JOIN mp_mst_territory_classification	h	(NOLOCK)	ON g.SupplierTerritoryId = h.territory_classification_id
		LEFT JOIN mp_star_rating				i   (NOLOCK)	ON c.company_id = i.company_id
		WHERE c.company_id NOT IN (SELECT CompanyId FROM @BlacklistedCompanies)
		AND ISNULL(b.is_reviewed,1) = (CASE WHEN @TabId = 2 THEN 0  WHEN @TabId = 3 THEN 1 ELSE ISNULL(b.is_reviewed,1) END)
		AND ISNULL(b.is_quote_declined,0) = (CASE WHEN @TabId = 4 THEN 1  ELSE ISNULL(b.is_quote_declined,0) END)
		AND a.rfq_status_id = (CASE WHEN @StatusId = 0 THEN a.rfq_status_id ELSE @StatusId END)
		AND g.SupplierTerritoryId = (CASE WHEN @TerritoryId = 0 THEN g.SupplierTerritoryId ELSE @TerritoryId END) 
		AND			
		(
			(a.rfq_name LIKE '%'+@Search+'%')	
			OR	
			(a.rfq_id LIKE '%'+@Search+'%')		
			OR
			(g.SupplierCompany	LIKE '%'+@Search+'%')
			OR
			(@Search = '')	
		)

		INSERT INTO #tmpBuyerMyQuotes
		(
			RFQId	, RFQName	,RfqStatusId	, SupplierId	, Supplier	,SupplierCompanyId ,SupplierCompany ,SupplierTerritoryId ,SupplierTerritory	, QuoteDate	
			,IsReviewedByBuyer	,QuoteStatusId, SupplierQuoteId ,  Qty1 ,  Qty2 ,  Qty3	,RfqResubmittedByBuyer,QuoteDeclined ,BuyerFeedbackId ,NoOfStars,IsViewedByBuyer,WithOrderManagement
		)
		SELECT 
		RFQId	, RFQName	,RfqStatusId	, SupplierId	, Supplier	,SupplierCompanyId ,SupplierCompany ,SupplierTerritoryId ,SupplierTerritory	, QuoteDate	,IsReviewedByBuyer	
		,QuoteStatusId, SupplierQuoteId , [0] AS Qty1 , [1]  AS Qty2 , [2]    AS Qty3	,RfqResubmittedByBuyer,QuoteDeclined ,BuyerFeedbackId ,NoOfStars,IsViewedByBuyer,WithOrderManagement
		--INTO #tmpBuyerMyQuotes
		FROM  
		(
			SELECT *
			FROM
			(			
				SELECT 
					RFQId	, RFQName	,RfqStatusId	, SupplierId	, Supplier	,SupplierCompanyId	,SupplierCompany ,SupplierTerritoryId ,SupplierTerritory
					,QuoteDate	,IsReviewedByBuyer	,QuoteStatusId, SupplierQuoteId ,  PartQtyLevel ,BuyerFeedbackId ,NoOfStars,IsViewedByBuyer,WithOrderManagement
					,CONVERT
					(	DECIMAL(18,4),
						SUM
						(
							(
								(COALESCE(PerUnitPrice,0) * COALESCE(QtyAwarded,0)) 
								+ COALESCE(ToolingAmount,0)  
								+  COALESCE(MiscAmount,0)  
								+  COALESCE(ShippingAmount,0)
							)
						)
					) AS QtyTotal, RfqResubmittedByBuyer,QuoteDeclined  

				FROM @BuyerMyQuotes
				GROUP BY
					RFQId	, RFQName	,RfqStatusId	, SupplierId	, Supplier	,SupplierCompanyId	, SupplierCompany ,SupplierTerritoryId ,SupplierTerritory , QuoteDate	
					,QuoteDate	,IsReviewedByBuyer	,QuoteStatusId, SupplierQuoteId ,  PartQtyLevel , RfqResubmittedByBuyer,QuoteDeclined ,BuyerFeedbackId,NoOfStars,IsViewedByBuyer,WithOrderManagement
			) a

		) AS BuyerNewQuotes  
		PIVOT  
		(  
			MAX(QtyTotal)  
			FOR PartQtyLevel IN ([0], [1], [2])  
		) AS PivotTable
		ORDER BY 
				CASE WHEN @IsOrderByDesc =  1 AND @OrderBy IN ('QuoteDate', 'Date') THEN   QuoteDate END DESC   
				,CASE WHEN @IsOrderByDesc =  1 AND @OrderBy = 'Location' THEN   SupplierTerritory END DESC
				,CASE WHEN @IsOrderByDesc =  1 AND @OrderBy = 'Manufacturer' THEN   SupplierCompany END DESC
				,CASE WHEN @IsOrderByDesc =  1 AND @OrderBy = 'Qty1' THEN   [0] END DESC
				,CASE WHEN @IsOrderByDesc =  1 AND @OrderBy = 'Qty2' THEN   [1] END DESC
				,CASE WHEN @IsOrderByDesc =  1 AND @OrderBy = 'Qty3' THEN   [2] END DESC
				,CASE WHEN @IsOrderByDesc =  1 AND @OrderBy = 'Status' THEN   IsReviewedByBuyer END DESC
				,CASE WHEN @IsOrderByDesc =  0 AND @OrderBy IN ('QuoteDate', 'Date') THEN   QuoteDate END ASC  
				,CASE WHEN @IsOrderByDesc =  0 AND @OrderBy = 'Location' THEN   SupplierTerritory END ASC
				,CASE WHEN @IsOrderByDesc =  0 AND @OrderBy = 'Manufacturer' THEN   SupplierCompany END ASC
				,CASE WHEN @IsOrderByDesc =  0 AND @OrderBy = 'Qty1' THEN   [0] END ASC
				,CASE WHEN @IsOrderByDesc =  0 AND @OrderBy = 'Qty2' THEN   [1] END ASC
				,CASE WHEN @IsOrderByDesc =  0 AND @OrderBy = 'Qty3' THEN   [2] END ASC
				,CASE WHEN @IsOrderByDesc =  0 AND @OrderBy = 'Status' THEN   IsReviewedByBuyer END ASC 

		OFFSET @PageSize * (@PageNumber - 1) ROWS
		FETCH NEXT @PageSize ROWS ONLY
		;  

		
		SELECT 
			a.RFQId	, RFQName	,RfqStatusId	, a.SupplierId	, Supplier	,SupplierCompanyId ,SupplierCompany ,SupplierTerritoryId ,SupplierTerritory	
			, QuoteDate		,QuoteStatusId, SupplierQuoteId ,ISNULL(Qty1,0) Qty1 ,ISNULL(Qty2,0) Qty2 ,  ISNULL(Qty3,0) Qty3	,RfqResubmittedByBuyer,QuoteDeclined ,BuyerFeedbackId ,NoOfStars ,b.RFQSupplierStatusId,IsReviewedByBuyer ,CAST('true' AS BIT) as IsViewedByBuyer,WithOrderManagement
		FROM #tmpBuyerMyQuotes  a
		/* M2-3281 Buyer - Change Awarding Modal - DB */
		left join 
		(
			select   
				a.rfq_id AS RfqId
				,a.contact_id as SupplierId
				,min(isnull(b.status_id,999)) RFQSupplierStatusId
			from mp_rfq_quote_supplierquote a (nolock)  
			join mp_rfq_quote_items b (nolock) on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id   
			join mp_rfq				c (nolock) on a.rfq_id = c.rfq_id
			where  
				c.contact_id =@BuyerContactId   
				and is_rfq_resubmitted = 0   
				and is_quote_submitted = 1  
				and c.rfq_status_id not in (1,13)  
				and a.is_reviewed = 0  
			group by a.rfq_id  ,a.contact_id 
		  
		) as b on a.SupplierId = b.SupplierId and a.RFQId = b.RFQId
		/**/
		SET @TotalCount =  
		(
			SELECT COUNT(1) TotalCount FROM
			(
				SELECT DISTINCT RFQId, SupplierId FROM @BuyerMyQuotes 			
			) A 
		)

		/* 
			M2-2966 
			M2-3318 Buyer - Change the My Quotes page to reflect Viewed and Reviewed - DB
		*/
		IF ((SELECT COUNT(1) FROM #tmpBuyerMyQuotes WHERE IsViewedByBuyer = 0) > 0 )
		BEGIN

			SELECT  @SQLQuery = COALESCE(@SQLQuery + '', '') + 
				'EXEC proc_set_emailMessages @rfq_id =  '''+CONVERT(VARCHAR(100), RFQId)+''' , @message_type = ''BUYER_VIEWED_AN_RFQ9999'' ,@message_status_id = '''' ,@from_contact = '''' , @to_contacts = '''+CONVERT(VARCHAR(100), SupplierId)+''' ,@message = '''' ,@message_link = '''',@MessageFileNames = ''''  '
			FROM ( SELECT DISTINCT RFQId ,SupplierId FROM #tmpBuyerMyQuotes WHERE IsViewedByBuyer = 0 ) a

			--SELECT @SQLQuery
			EXEC (@SQLQuery)
		
			UPDATE a SET a.IsViewed = 1
			FROM mp_rfq_quote_supplierquote (NOLOCK) a
			JOIN #tmpBuyerMyQuotes b ON a.rfq_id = b.RFQId AND a.contact_id = b.SupplierId
			WHERE b.IsViewedByBuyer = 0 AND a.is_rfq_resubmitted = 0
		END
		/**/
END
