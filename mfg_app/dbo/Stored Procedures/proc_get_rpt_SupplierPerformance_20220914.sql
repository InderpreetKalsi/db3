
/*
EXEC [proc_get_rpt_SupplierPerformance_20220914] 

	@parRange	= 'Last 7 Days'
	,@parStartDate	 = '2022-01-01'
	,@parEndDate	 = '2022-02-01'


*/

CREATE PROCEDURE [dbo].proc_get_rpt_SupplierPerformance_20220914
(
	@parRange	VARCHAR(100) = NULL
	,@parStartDate	DATE = NULL
	,@parEndDate	DATE = NULL
)
AS
BEGIN
	-- M2-3411 Report - Supplier Performance Report
	SET NOCOUNT ON

	DECLARE @StartDate	DATETIME	
	DECLARE @EndDate	DATETIME	
	DECLARE @Duration	INT

	DROP TABLE IF EXISTS #tmpRptSupplierPerformanceActiveSupplier
	DROP TABLE IF EXISTS #tmpRptSupplierPerformanceActiveSupplier_UserLogin
	DROP TABLE IF EXISTS #tmpRptSupplierPerformanceActiveSupplier_MostRecentQuoteDate
	DROP TABLE IF EXISTS #tmpRptSupplierPerformanceActiveSupplier_MostRecentAwardDate
	DROP TABLE IF EXISTS #tmpRptSupplierPerformanceActiveSupplier_Quotesgenerated
	DROP TABLE IF EXISTS #tmpRptSupplierPerformanceActiveSupplier_TotalAwards
	DROP TABLE IF EXISTS #tmpRptSupplierPerformanceActiveSupplier_RFQsViewed
	DROP TABLE IF EXISTS #tmpRptSupplierPerformanceActiveSupplier_RFQsliked
	DROP TABLE IF EXISTS #tmpRptSupplierPerformanceActiveSupplier_RFQsdisliked
	DROP TABLE IF EXISTS #tmpRptSupplierPerformanceActiveSupplier_RFQsmarkedforquoting
	DROP TABLE IF EXISTS #tmpRptSupplierPerformanceActiveSupplier_buyerssavedtocontacts
	

	IF (@parRange = 'No Selection') AND  (@parStartDate != '1900-01-01' ) AND  (@parEndDate != '1900-01-01' )
	BEGIN
		
		SET @StartDate = @parStartDate
		SET @EndDate =  @parEndDate

	END 
	ELSE IF (@parRange != '' )
	BEGIN

		IF @parRange = 'Last 7 Days'
		BEGIN
			SET @Duration =  7
		END

		IF @parRange = 'Last 15 Days'
		BEGIN
			SET @Duration =  15
		END

		IF @parRange = 'Last 1 Month'
		BEGIN
			SET @Duration =  30
		END

		IF @parRange = 'Last 3 Months'
		BEGIN
			SET @Duration =  90
		END

		IF @parRange = 'Last 6 Months'
		BEGIN
			SET @Duration =  180
		END

		IF @parRange = 'Last 9 Months'
		BEGIN
			SET @Duration =  270
		END

		IF @parRange = 'Last 1 Year'
		BEGIN
			SET @Duration =  365
		END


		SET @StartDate = DATEADD(DAY,-@Duration,GETUTCDATE())
		SET @EndDate =  GETUTCDATE()

	END

	--SELECT @parRange , @parStartDate ,@parEndDate ,@StartDate ,@EndDate

	-- list of paid manufacturers
	SELECT company_id  AS CompanyId	,b.value AS PaidStatus INTO #tmpRptSupplierPerformanceActiveSupplier
	FROM mp_registered_supplier (NOLOCK)  a 
	JOIN mp_system_parameters (NOLOCK) b ON a.account_type = b.id AND sys_key = '@ACCOUNT_TYPE'
	--WHERE company_id = 494545

	
	-- list of paid manufacturers	
	SELECT c.company_id , COUNT(1) AS login_count INTO #tmpRptSupplierPerformanceActiveSupplier_UserLogin
	FROM mp_user_logindetail (NOLOCK) f 
	JOIN mp_contacts	(NOLOCK) c ON c.contact_id = f.contact_id
	WHERE CONVERT(DATE,login_datetime) BETWEEN @StartDate AND @EndDate
	GROUP BY c.company_id

	SELECT contact_id , MAX(CONVERT(DATE,quote_date)) quote_date INTO #tmpRptSupplierPerformanceActiveSupplier_MostRecentQuoteDate
	FROM mp_rfq_quote_supplierquote (NOLOCK) 
	WHERE is_quote_submitted = 1
	GROUP BY contact_id

	SELECT c1.contact_id , MAX(CONVERT(DATE,awarded_date)) awarded_date INTO #tmpRptSupplierPerformanceActiveSupplier_MostRecentAwardDate
	FROM mp_rfq_quote_supplierquote (NOLOCK) c1 
	JOIN mp_rfq_quote_items (NOLOCK) d1 ON c1.rfq_quote_SupplierQuote_id = d1.rfq_quote_SupplierQuote_id 
	WHERE d1.status_id= 6 AND is_awrded = 1
	GROUP BY c1.contact_id

	SELECT b.company_id , COUNT(DISTINCT c1.rfq_id) quoted_rfq_count INTO #tmpRptSupplierPerformanceActiveSupplier_Quotesgenerated
	FROM mp_rfq_quote_supplierquote (NOLOCK) c1 
	JOIN mp_contacts (NOLOCK)   b ON c1.contact_id = b.contact_id
	WHERE is_quote_submitted = 1 AND c1.quote_date BETWEEN @StartDate AND @EndDate
	GROUP BY b.company_id

	SELECT b.company_id , COUNT(DISTINCT c1.rfq_id) awarded_rfq_count INTO #tmpRptSupplierPerformanceActiveSupplier_TotalAwards
	FROM mp_rfq_quote_supplierquote (NOLOCK) c1 
	JOIN mp_rfq_quote_items (NOLOCK) d1 ON c1.rfq_quote_SupplierQuote_id = d1.rfq_quote_SupplierQuote_id 
	JOIN mp_contacts (NOLOCK)   b ON c1.contact_id = b.contact_id
	WHERE d1.status_id= 6 AND is_awrded = 1 AND c1.quote_date BETWEEN @StartDate AND @EndDate
	GROUP BY b.company_id

	SELECT b.company_id , COUNT(DISTINCT rfq_id ) viewed_rfq_count INTO #tmpRptSupplierPerformanceActiveSupplier_RFQsViewed
	FROM mp_rfq_supplier_read (NOLOCK) a
	JOIN mp_contacts  (NOLOCK) b ON a.supplier_id = b.contact_id
	WHERE read_date BETWEEN @StartDate AND @EndDate
	GROUP BY b.company_id

	SELECT b.company_id , COUNT(DISTINCT rfq_id ) liked_rfq_count INTO #tmpRptSupplierPerformanceActiveSupplier_RFQsliked
	FROM mp_rfq_supplier_likes (NOLOCK) a
	JOIN mp_contacts  (NOLOCK) b ON a.contact_id = b.contact_id
	WHERE like_date BETWEEN @StartDate AND @EndDate
	AND is_rfq_like = 1
	GROUP BY b.company_id

	SELECT b.company_id , COUNT(DISTINCT rfq_id ) disliked_rfq_count INTO #tmpRptSupplierPerformanceActiveSupplier_RFQsdisliked
	FROM mp_rfq_supplier_likes (NOLOCK) a
	JOIN mp_contacts  (NOLOCK) b ON a.contact_id = b.contact_id
	WHERE like_date BETWEEN @StartDate AND @EndDate
	AND is_rfq_like = 0
	GROUP BY b.company_id

	SELECT b.company_id , COUNT(DISTINCT rfq_id )  marked_for_quoting_rfq_count  INTO #tmpRptSupplierPerformanceActiveSupplier_RFQsmarkedforquoting
	FROM mp_rfq_quote_suplierstatuses (NOLOCK) a
	JOIN mp_contacts (NOLOCK)   b ON a.contact_id = b.contact_id
	WHERE creation_date BETWEEN @StartDate AND @EndDate
	AND rfq_userStatus_id = 2 
	GROUP BY b.company_id

	SELECT b.company_id  , COUNT(DISTINCT bookdetails.company_id) buyers_saved_to_contacts_count INTO #tmpRptSupplierPerformanceActiveSupplier_buyerssavedtocontacts
	FROM mp_books book  
	JOIN mp_book_details bookdetails ON book.book_id=bookdetails.book_id
	JOIN mp_contacts (NOLOCK)   b ON book.contact_id = b.contact_id
	WHERE creation_date BETWEEN @StartDate AND @EndDate
	GROUP BY b.company_id

		
	--SELECT @StartDate , @EndDate 
	SELECT  
		ISNULL(e.PaidStatus,'Basic') AS [PaidStatus]
		,b.company_id									AS	[CompanyId]
		,(CASE WHEN LEN(b.name) > 30  THEN LEFT(b.name, 30) + '...' ELSE b.name END)		AS	[Company]
		,g.territory_classification_name AS [MFG Location]
		,(CASE WHEN LEN(d.first_name +' '+ d.last_name) > 20  THEN LEFT(d.first_name +' '+ d.last_name, 20) + '...' ELSE d.first_name +' '+ d.last_name END) 					AS	[Account Owner]
		,(CASE WHEN LEN(c.first_name +' '+ c.last_name) > 20  THEN LEFT(c.first_name +' '+ c.last_name, 20) + '...' ELSE c.first_name +' '+ c.last_name END) 					AS	[Customer Rep]
		,COUNT(DISTINCT a.contact_id)				AS  [No of Users]
		,MAX(CONVERT(DATE,a.last_login_on))			AS	[Most Recent Login]
		,MAX(quote_date)							AS	[Most Recent Quote Date]
		,MAX(awarded_date)							AS  [Most Recent Award Date]
		,ISNULL(login_count,0)						AS	[# of Logins]
		,ISNULL(quoted_rfq_count,0)					AS	[# of Quotes Generated]
		,ISNULL(awarded_rfq_count,0)				AS	[# of Total Awards]
		,ISNULL(viewed_rfq_count,0)					AS	[# of RFQs Viewed]
		,ISNULL(liked_rfq_count,0)					AS	[# of RFQs Liked]
		,ISNULL(disliked_rfq_count,0)				AS	[# of RFQs Disliked]
		,ISNULL(marked_for_quoting_rfq_count,0)		AS	[# of RFQs marked for quoting]
		,ISNULL(buyers_saved_to_contacts_count,0)	AS	[# of buyers saved to contacts]
		
		
	FROM 
	(
	
		SELECT company_id FROM  #tmpRptSupplierPerformanceActiveSupplier_Quotesgenerated
		UNION
		SELECT company_id FROM  #tmpRptSupplierPerformanceActiveSupplier_TotalAwards
		UNION
		SELECT company_id FROM  #tmpRptSupplierPerformanceActiveSupplier_RFQsViewed
		UNION
		SELECT company_id FROM  #tmpRptSupplierPerformanceActiveSupplier_RFQsliked
		UNION
		SELECT company_id FROM  #tmpRptSupplierPerformanceActiveSupplier_RFQsdisliked
		UNION
		SELECT company_id FROM  #tmpRptSupplierPerformanceActiveSupplier_RFQsmarkedforquoting
		UNION
		SELECT CompanyId FROM  #tmpRptSupplierPerformanceActiveSupplier
	
	) e1
	JOIN mp_companies		(NOLOCK) b ON b.company_id = e1.company_id
	JOIN mp_contacts		(NOLOCK) a ON a.company_id = b.company_id AND a.is_buyer = 0 AND a.IsTestAccount = 0
	LEFT JOIN #tmpRptSupplierPerformanceActiveSupplier e ON b.company_id = e.CompanyId
	LEFT JOIN mp_contacts	(NOLOCK) c ON b.assigned_customer_rep = c.contact_id
	LEFT JOIN mp_contacts	(NOLOCK) d ON b.assigned_sourcingadvisor = d.contact_id
	LEFT JOIN mp_mst_territory_classification (NOLOCK) g ON b.manufacturing_location_id	= g.territory_classification_id
	LEFT JOIN 
	(
		SELECT * FROM #tmpRptSupplierPerformanceActiveSupplier_UserLogin
	) UserLogin ON e1.company_id = UserLogin.company_id 
	LEFT JOIN
	(
		SELECT * FROM #tmpRptSupplierPerformanceActiveSupplier_MostRecentQuoteDate
	) [MostRecentQuoteDate] ON a.contact_id = [MostRecentQuoteDate].contact_id 
	LEFT JOIN 
	(
			SELECT * FROM #tmpRptSupplierPerformanceActiveSupplier_MostRecentAwardDate
	) [MostRecentAwardDate]  ON a.contact_id = [MostRecentAwardDate].contact_id 
	LEFT JOIN 
	(

		SELECT * FROM #tmpRptSupplierPerformanceActiveSupplier_Quotesgenerated
	)	[#ofQuotesgenerated]  ON e1.company_id = [#ofQuotesgenerated].company_id 
	LEFT JOIN
	(
		SELECT * FROM #tmpRptSupplierPerformanceActiveSupplier_TotalAwards
	) [#ofTotalAwards] ON e1.company_id = [#ofTotalAwards].company_id 
	LEFT JOIN
	(
		SELECT * FROM #tmpRptSupplierPerformanceActiveSupplier_RFQsViewed
	) [#ofRFQsViewed] ON e1.company_id = [#ofRFQsViewed].company_id
	LEFT JOIN
	(
		SELECT * FROM #tmpRptSupplierPerformanceActiveSupplier_RFQsliked
	) [#ofRFQsliked] ON e1.company_id = [#ofRFQsliked].company_id
	LEFT JOIN
	(
		SELECT * FROM #tmpRptSupplierPerformanceActiveSupplier_RFQsdisliked
	) [#ofRFQsdisliked] ON e1.company_id = [#ofRFQsdisliked].company_id
	LEFT JOIN
	(
		SELECT * FROM #tmpRptSupplierPerformanceActiveSupplier_RFQsmarkedforquoting
	) [#ofRFQsmarkedforquoting] ON e1.company_id = [#ofRFQsmarkedforquoting].company_id
	LEFT JOIN
	(
		SELECT * FROM #tmpRptSupplierPerformanceActiveSupplier_buyerssavedtocontacts
	) [#ofbuyerssavedtocontacts]  ON e1.company_id = [#ofbuyerssavedtocontacts].company_id
	WHERE  
	b.company_id <> 0
	AND a.IsTestAccount = 0
	GROUP BY 
		b.company_id
		,b.name			
		,c.first_name +' '+ c.last_name
		,d.first_name +' '+ d.last_name 
		,g.territory_classification_name
		,e.PaidStatus
		,ISNULL(login_count,0)
		,ISNULL(quoted_rfq_count,0)					
		,ISNULL(awarded_rfq_count,0)				
		,ISNULL(viewed_rfq_count,0)					
		,ISNULL(liked_rfq_count,0)					
		,ISNULL(disliked_rfq_count,0)				
		,ISNULL(marked_for_quoting_rfq_count,0)		
		,ISNULL(buyers_saved_to_contacts_count,0)	
	ORDER BY Company



	DROP TABLE IF EXISTS #tmpRptSupplierPerformanceActiveSupplier
	DROP TABLE IF EXISTS #tmpRptSupplierPerformanceActiveSupplier_UserLogin
	DROP TABLE IF EXISTS #tmpRptSupplierPerformanceActiveSupplier_MostRecentQuoteDate
	DROP TABLE IF EXISTS #tmpRptSupplierPerformanceActiveSupplier_MostRecentAwardDate
	DROP TABLE IF EXISTS #tmpRptSupplierPerformanceActiveSupplier_Quotesgenerated
	DROP TABLE IF EXISTS #tmpRptSupplierPerformanceActiveSupplier_TotalAwards
	DROP TABLE IF EXISTS #tmpRptSupplierPerformanceActiveSupplier_RFQsViewed
	DROP TABLE IF EXISTS #tmpRptSupplierPerformanceActiveSupplier_RFQsliked
	DROP TABLE IF EXISTS #tmpRptSupplierPerformanceActiveSupplier_RFQsdisliked
	DROP TABLE IF EXISTS #tmpRptSupplierPerformanceActiveSupplier_RFQsmarkedforquoting
	DROP TABLE IF EXISTS #tmpRptSupplierPerformanceActiveSupplier_buyerssavedtocontacts
		 
END
