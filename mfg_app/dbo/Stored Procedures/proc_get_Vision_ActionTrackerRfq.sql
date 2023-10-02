
/*

SELECT * FROM ActionTrackerRfq WHERE RfqId IN (1192860	,1192859 ,1192836)

DECLARE @p1 [tbltype_ListOfRfqStatuses]
DECLARE @p2 [tbltype_ListOfRfqLocation]
DECLARE @p3 [tbltype_ListOfProcesses]
INSERT INTO @p1 VALUES ('all')  -- Quoting ,  Closed ,Awarded ,Not Awarded
--INSERT INTO @p2 VALUES ('United States')
--INSERT INTO @p3 VALUES (100001)

--SELECT * FROM  @p1 
EXEC [proc_get_Vision_ActionTrackerRfq]
	@PageNumber = 1
	,@PageSize	= 20
	,@NoofQuotesLessThen3 = NULL
	,@RfqQuality = NULL  -- (0 to 5)
	,@RfqSearch =  NULL -- '1192859'
	,@RfqCloseStartDate =NULL --'01/01/2021'
	,@RfqCloseEndDate =  NULL --'01/01/2021'
	,@RfqReleaseStartDate =  NULL --'2020-12-30 00:00:00' -- '2020-12-01'
	,@RfqReleaseEndDate =  NULL --'2021-01-29 00:00:00' -- '2020-12-07'
	,@Status = @p1
	,@RfqLocation = @p2
	,@ProcessIDs = @p3
	,@SortBy = NULL --  Rating , Status ,Location
	,@IsSortByDesc = 1


*/
CREATE PROCEDURE [dbo].[proc_get_Vision_ActionTrackerRfq]
(
	@PageNumber				INT = 1
	,@PageSize				INT = 20
	,@NoofQuotesLessThen3	INT = NULL
	,@RfqQuality			INT = NULL 
	,@RfqCloseStartDate		AS	DATE = NULL
	,@RfqCloseEndDate		AS	DATE = NULL
	,@RfqReleaseStartDate	AS	DATE = NULL
	,@RfqReleaseEndDate		AS	DATE = NULL
	,@RfqSearch				AS	VARCHAR(250) = NULL
	,@SortBy				AS	VARCHAR(250) = 'RfqCloseDate'
	,@IsSortByDesc			AS  BIT = 1
	,@Status				AS [tbltype_ListOfRfqStatuses] READONLY
	,@RfqLocation			AS [tbltype_ListOfRfqLocation] READONLY
	,@ProcessIDs			AS [tbltype_ListOfProcesses]   READONLY
)
AS
BEGIN

	-- M2-3378 Vision - RFQ Tracker - page data -DB 
	SET NOCOUNT ON 

	DROP TABLE IF EXISTS #getActionTrackerRfq
	DROP TABLE IF EXISTS #getActionTrackerRfqFinal
	DROP TABLE IF EXISTS #getCapabilities

	DECLARE @ExecSQLQuery	NVARCHAR(MAX) = ''
	DECLARE @SQLQuery		VARCHAR(MAX) = ''
	DECLARE @DateQuery		VARCHAR(MAX) = ''
	DECLARE @WhereQuery		VARCHAR(MAX) = ''
	DECLARE @OrderQuery		VARCHAR(MAX) = ''
	DECLARE @RfqQuality1	INT


	DECLARE @Status1					AS [tbltype_ListOfRfqStatuses] 
	DECLARE @RfqLocation1				AS [tbltype_ListOfRfqLocation]
	DECLARE @ProcessIDs1				AS [tbltype_ListOfProcesses]

	CREATE TABLE #getActionTrackerRfq (RfqId INT)
	CREATE TABLE #getActionTrackerRfqFinal (RfqId INT)
	CREATE TABLE #getCapabilities (PartCategoryId INT)

	IF @SortBy = '' OR @SortBy IS NULL
		SET @SortBy = 'RfqCloseDate'

	-- SELECT DISTINCT [Status] FROM ActionTrackerRfq
	-- UPDATE RFQ Action Tracker data
	-- EXEC proc_set_ActionTrackerRfq


	SET @WhereQuery = ' WHERE '
		+	CASE	WHEN (SELECT COUNT(1) FROM @Status) = 0  THEN ' [Status] IN (''Quoting'',''Closed'',''Awarded'',''Not Awarded'' ,''Awarded to MFG Manufacturer Offline'',''Awarded in Another MFG Region'',''Awarded Non-MFG Manufacturer'') ' 
					WHEN (SELECT COUNT(1) FROM @Status WHERE Status = 'All') > 0  THEN ' [Status] IN (''Quoting'',''Closed'',''Awarded'',''Not Awarded'' ,''Awarded to MFG Manufacturer Offline'',''Awarded in Another MFG Region'',''Awarded Non-MFG Manufacturer'') ' 
					WHEN (SELECT COUNT(1) FROM @Status WHERE Status = 'Awarded') > 0  THEN ' [Status] IN (''Awarded'',''Awarded to MFG Manufacturer Offline'',''Awarded in Another MFG Region'',''Awarded Non-MFG Manufacturer'') '  
					WHEN (SELECT COUNT(1) FROM @Status) > 0 THEN ' [Status] IN (SELECT * FROM @Status1) '
			END
		+	CASE	WHEN @NoofQuotesLessThen3 IS NULL THEN '' 
					WHEN @NoofQuotesLessThen3 = 0 THEN 'AND Quotes = 0 '
					WHEN @NoofQuotesLessThen3 = 1 THEN 'AND Quotes BETWEEN 1 AND 3 '
					WHEN @NoofQuotesLessThen3 = 2 THEN 'AND Quotes > 3  '
			END
		+	CASE	WHEN @RfqQuality IS NULL THEN '' 
					WHEN @RfqQuality = 0 THEN 'AND Rating IS NULL ' 					
					WHEN @RfqQuality >0 THEN 'AND Rating =  @RfqQuality1 '
			END
		+	CASE	WHEN @RfqCloseStartDate IS NULL AND @RfqCloseEndDate IS NULL  THEN '' 
					WHEN @RfqCloseStartDate IS NOT NULL AND @RfqCloseEndDate IS NOT NULL  THEN 'AND CONVERT(DATE,RfqCloseDate) BETWEEN '''+CONVERT(VARCHAR(10) , @RfqCloseStartDate, 120)+''' AND '''+CONVERT(VARCHAR(10) ,@RfqCloseEndDate, 120)+''' '
			END
		+	CASE	WHEN @RfqReleaseStartDate IS NULL AND @RfqReleaseEndDate IS NULL  THEN '' 
					WHEN @RfqReleaseStartDate IS NOT NULL AND @RfqReleaseEndDate IS NOT NULL  THEN 'AND CONVERT(DATE,RfqReleaseDate) BETWEEN '''+CONVERT(VARCHAR(10) , @RfqReleaseStartDate, 120)+''' AND '''+CONVERT(VARCHAR(10) , @RfqReleaseEndDate, 120)+''' '
			END
		+	CASE	WHEN (SELECT COUNT(1) FROM @RfqLocation) = 0  THEN '' 
					WHEN (SELECT COUNT(1) FROM @RfqLocation) > 0 THEN 'AND [Location] IN (SELECT * FROM @RfqLocation1) '
			END
		+	CASE	WHEN @RfqSearch IS NULL THEN '' 
					WHEN @RfqSearch = '' THEN ''
					ELSE 
						'AND 
						(
							RfqId LIKE ''%'+@RfqSearch+'%''
							OR RfqName LIKE ''%'+@RfqSearch+'%''
							OR Buyer LIKE ''%'+@RfqSearch+'%''
							OR BuyerEmail LIKE ''%'+@RfqSearch+'%''
							OR BuyerCompany LIKE ''%'+@RfqSearch+'%''
						
						)'
			END
	
	/* M2-3532 Vision - RFQ Tracker Page - Selecting 'Manufacturing Process' filter should displayed the list of matching RFQ's */
	IF ((SELECT COUNT(1) FROM @ProcessIDs) > 0)
	BEGIN

		INSERT INTO #getCapabilities(PartCategoryId)
		SELECT part_category_id 
		FROM mp_mst_part_category (NOLOCK) 
		WHERE parent_part_category_id IN (SELECT * FROM @ProcessIDs) AND status_id = 2 AND level = 1
		UNION
		SELECT * FROM @ProcessIDs

	END
	/**/


	SET @SQLQuery = ''
		+	CASE	WHEN (SELECT COUNT(1) FROM @ProcessIDs) = 0  THEN '' 
					WHEN (SELECT COUNT(1) FROM @ProcessIDs) > 0 THEN 
						' 
							INSERT INTO #getActionTrackerRfq(RfqId)
							SELECT DISTINCT rfq_id AS RfqId FROM mp_rfq_parts (NOLOCK) 
							WHERE part_category_id IN (SELECT * FROM #getCapabilities)
						'
			END	


	IF LEN(@SQLQuery) > 0 
	BEGIN

		SET @ExecSQLQuery = @SQLQuery
	
		EXEC SP_EXECUTESQL @ExecSQLQuery 
		,N'@ProcessIDs1  [tbltype_ListOfProcesses] READONLY'
		,@ProcessIDs1  = @ProcessIDs	
		
	END
	
	SET @SQLQuery =''
	SET @ExecSQLQuery =''


	SET @SQLQuery = 
	'INSERT INTO #getActionTrackerRfqFinal (RfqId)
	 SELECT RfqId FROM ActionTrackerRFQ (NOLOCK) ' 
	+ @WhereQuery
	+ CASE WHEN ((SELECT COUNT(1) FROM #getActionTrackerRfq) > 0) THEN ' AND RfqId IN  (SELECT RfqId FROM #getActionTrackerRfq)' ELSE '' END
	
	
	SET @ExecSQLQuery = @SQLQuery

	EXEC SP_EXECUTESQL @ExecSQLQuery 
	,N'
		@RfqLocation1  [tbltype_ListOfRfqLocation] READONLY 
		, @Status1  [tbltype_ListOfRfqStatuses] READONLY 
		, @RfqQuality1	INT
	'
	,@RfqLocation1  = @RfqLocation	
	,@Status1  = @Status	
	,@RfqQuality1 = @RfqQuality

	--SELECT @ExecSQLQuery ,@WhereQuery  ,@RfqSearch
	--SELECT RfqId FROM #getActionTrackerRfqFinal

	SELECT *
	FROM
	(
		SELECT   
			RfqId
			,ParentRfqId
			,RfqName
			,RfqThumbnails
			,Rating
			,BuyerId
			,Buyer
			,BuyerEmail
			,BuyerCompany
			,RfqCloseDate -- UTCConvertedRfqCloseDate RfqCloseDate
			,RfqReleaseDate
			,Reviewed
			,Liked
			,Marked
			,Quotes
			,[Location]
			,[Status]
			,CASE WHEN a.ParentRfqId != 0 THEN (SELECT [RfqId] FROM ActionTrackerRFQ (NOLOCK) WHERE RfqId =  a.ParentRfqId  ) ELSE [RfqId] END AS RfqId1
			,CASE WHEN a.ParentRfqId != 0 THEN ISNULL((SELECT [Rating] FROM ActionTrackerRFQ (NOLOCK) WHERE RfqId =  a.ParentRfqId  ),[Rating])  ELSE [Rating] END AS Rating1
			,CASE WHEN a.ParentRfqId != 0 THEN (SELECT [Location] FROM ActionTrackerRFQ (NOLOCK) WHERE RfqId =  a.ParentRfqId  ) ELSE [Location] END AS Location1
			,CASE WHEN a.ParentRfqId != 0 THEN (SELECT [Status] FROM ActionTrackerRFQ (NOLOCK) WHERE RfqId =  a.ParentRfqId  ) ELSE [Status] END AS Status1
			,CASE WHEN a.ParentRfqId != 0 THEN (SELECT RfqCloseDate FROM ActionTrackerRFQ (NOLOCK) WHERE RfqId =  a.ParentRfqId  ) ELSE RfqCloseDate END AS RfqCloseDate1
			--,UTCConvertedRfqCloseDate
			,COUNT(1) OVER() AS RfqCount 
		FROM ActionTrackerRFQ			(NOLOCK) a 
		WHERE 
			RfqId IN 
			(
				SELECT RfqId FROM #getActionTrackerRfqFinal
				UNION
				SELECT cloned_rfq_id FROM mp_rfq_cloned_logs (NOLOCK) WHERE parent_rfq_id IN (SELECT RfqId FROM #getActionTrackerRfqFinal)
			)
	) a	
	ORDER BY 
		 CASE  WHEN @IsSortByDesc =  1 AND @SortBy = 'RfqCloseDate'		THEN   RfqCloseDate1 END DESC   
		,CASE  WHEN @IsSortByDesc =  1 AND @SortBy = 'Rating'			THEN   Rating1 END DESC			
		,CASE  WHEN @IsSortByDesc =  1 AND @SortBy = 'Status'			THEN   Status1 END DESC			
		,CASE  WHEN @IsSortByDesc =  1 AND @SortBy = 'Location'			THEN   Location1 END DESC		
		,CASE  WHEN @IsSortByDesc =  0 AND @SortBy = 'RfqCloseDate'		THEN   RfqCloseDate1 END ASC    
		,CASE  WHEN @IsSortByDesc =  0 AND @SortBy = 'Rating'			THEN   Rating1 END ASC			
		,CASE  WHEN @IsSortByDesc =  0 AND @SortBy = 'Status'			THEN   Status1 END ASC			
		,CASE  WHEN @IsSortByDesc =  0 AND @SortBy = 'Location'			THEN   Location1 END ASC		
		, RfqId1
	OFFSET @PageSize * (@PageNumber - 1) ROWS
	FETCH NEXT @PageSize ROWS ONLY


END
