
------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

/*

select * from aspnetusers where email = 'testsupplieremail@yopmail.com'

truncate table mpcommunityratings

INSERT INTO mpCommunityRatings
(IpAddress ,SenderCompany ,SenderEmail ,FirstName ,LastName ,IsBuyer ,ReceiverCompany ,ReceiverEmail ,Rating
,Comment ,RatingDate)
SELECT '152.57.105.80' , 'Kalsi Pvt Ltd.' , 'ikalsi@delaplex.com' , 'Inderpreet Singh' , 'Kalsi' ,1 , 'SupplierQA' , 'supplierqa@yopmail.com' , 5 , 'Satisfied customer' , GETUTCDATE()


select * from mpcommunityratings

EXEC [proc_get_vision_action_tracker_community]
	@TrackerType = 'All'   -- All ,CatchAll , DirectoryRfqs , SimpleRFQs , Ratings
	,@ByDate	= NULL
	,@TimeRange	= NULL
	,@Search		=NULL
	,@PageNumber	= 1
	,@PageSize		= 20
	,@IsOrderByDesc = 'True'
	,@OrderBy = NULL
	,@IsCommunityAllRfqsReleased	 = 0
	,@IsCommunityAllRfqsNotReleased	 = 0
	,@IsCommunityAllRfqsClosed		 = 0
	,@StatusId						 = -1  -- Values -1, 0 ,1 ,2

exec proc_get_vision_action_tracker_community 
@TrackerType=N'Ratings'
,@ByDate=default
,@TimeRange=default
,@Search=N''
,@PageNumber=1
,@PageSize=24
,@IsOrderByDesc=1
,@OrderBy=default
,@IsCommunityAllRfqsReleased=0
,@IsCommunityAllRfqsNotReleased=0
,@IsCommunityAllRfqsClosed=0
,@StatusId=-1

*/
CREATE PROCEDURE [dbo].[proc_get_vision_action_tracker_community]
(
	@TrackerType					VARCHAR(100)
	,@ByDate						DATE	=NULL
	,@TimeRange						INT		=NULL
	,@Search						VARCHAR(1000)		=NULL
	,@PageNumber					INT		= 1
	,@PageSize						INT		= 24
	,@IsOrderByDesc					BIT		='FALSE'
	,@OrderBy						VARCHAR(100)	= NULL
	,@IsCommunityAllRfqsReleased	BIT = NULL
	,@IsCommunityAllRfqsNotReleased	BIT = NULL
	,@IsCommunityAllRfqsClosed		BIT = NULL	
	,@StatusId						INT = NULL	
)
AS
BEGIN

	SET NOCOUNT ON

	/* Feb 23, 2021:	M2-3670 Directory RFQ - New Simple RFQ Form data */

	DROP TABLE IF EXISTS #tmp_vision_action_tracker_community
	DROP TABLE IF EXISTS #tmp_vision_action_tracker_community_CatchAll
	DROP TABLE IF EXISTS #tmp_vision_action_tracker_community_DirectoryRfqs
	DROP TABLE IF EXISTS #tmp_vision_action_tracker_community_DirectRfqs
	/* M2-3994 Vision - Action Tracker - Add Ratings and Reviews tab to Community Users - API */
	DROP TABLE IF EXISTS #tmp_vision_action_tracker_community_Ratings
	/**/
	DROP TABLE IF EXISTS #tmp_vision_action_tracker_community_CommunityFilter_IsCommunityRfqReleased	
	DROP TABLE IF EXISTS #tmp_vision_action_tracker_community_CommunityFilter_IsCommunityRfqClosed
	
	 
	CREATE TABLE #tmp_vision_action_tracker_community_CommunityFilter_IsCommunityRfqReleased ([Value] INT)
	CREATE TABLE #tmp_vision_action_tracker_community_CommunityFilter_IsCommunityRfqClosed ([Value] INT)
	CREATE TABLE #tmp_vision_action_tracker_community
	(
		Type						VARCHAR(50) NULL
		,Id							INT NULL
		,LeadDate					VARCHAR(50) NULL
		,LeadDateTime				DATETIME NULL
		,BuyerId					INT NULL
		,Buyer						VARCHAR(150) NULL
		,BuyerCompany				VARCHAR(150) NULL
		,BuyerEmail					VARCHAR(150) NULL
		,BuyerPhoneNo				VARCHAR(150) NULL
		,EmailSubject				VARCHAR(500) NULL
		,EmailBody					VARCHAR(MAX) NULL
		,EmailAttachment			BIT NULL
		,LeadId						INT NULL
		,SupplierId					INT NULL
		,StatusId					INT NULL
		,SupplierCompanyId			INT NULL
		,SupplierCompany			VARCHAR(150) NULL
		,SalesloftPeopleId			INT NULL
		,RfqId						INT NULL
		,RfqStatus					VARCHAR(150) NULL
		,BuyerNpsScoreCode			DECIMAL(18,2) NULL
		,ActionTakenBy				VARCHAR(150) NULL
		,ActionTakenDate			DATETIME NULL
		,rfq_created_on				DATETIME NULL
		,IsCommunityRfqReleased		BIT NULL
		,IsCommunityRfqClosed		BIT NULL
		,IsMfgCommunityRfq			BIT NULL
		,IsQMSEnabled				BIT NULL
		,CommunityRfqReleaseDate	DATETIME NULL
		,CommunityRfqReleaseById	INT NULL
		,CommunityRfqReleaseBy		VARCHAR(150) NULL	
		,CommunityRfqClosedDate		DATETIME NULL
		,CommunityRfqClosedById		INT NULL
		,CommunityRfqClosedBy		VARCHAR(150) NULL
		,WantsMp					BIT NULL
		,IsCommunityRatingApproved	BIT NULL
		,CommunityRatingApprovedDeclineBy	VARCHAR(150) NULL
		,CommunityRatingApprovedDeclineDate	DATETIME NULL
		,TotalRecordCount			INT NULL
                ,MessageID INT NULL  --- Added with M2-4525
	)


	IF (@OrderBy IS NULL OR  @OrderBy = '' )
		SET @OrderBy  = 'LeadDateTime'

		
	IF @IsCommunityAllRfqsNotReleased = 0 AND @IsCommunityAllRfqsReleased = 0 AND @IsCommunityAllRfqsClosed = 0
	BEGIN

		INSERT INTO #tmp_vision_action_tracker_community_CommunityFilter_IsCommunityRfqReleased
		SELECT 0 [Value] 
		UNION
		SELECT 1 [Value]	

		INSERT INTO #tmp_vision_action_tracker_community_CommunityFilter_IsCommunityRfqClosed
		SELECT 0 [Value] 
		UNION
		SELECT 1 [Value]	

	END
	ELSE IF @IsCommunityAllRfqsNotReleased = 1 AND @IsCommunityAllRfqsReleased = 0 AND @IsCommunityAllRfqsClosed = 0
	BEGIN

		INSERT INTO #tmp_vision_action_tracker_community_CommunityFilter_IsCommunityRfqReleased
		SELECT 0 [Value]

		INSERT INTO #tmp_vision_action_tracker_community_CommunityFilter_IsCommunityRfqClosed
		SELECT 0 [Value] 
		UNION
		SELECT 1 [Value]	

	END					
	ELSE IF @IsCommunityAllRfqsNotReleased = 0 AND @IsCommunityAllRfqsReleased = 1 AND @IsCommunityAllRfqsClosed = 0
	BEGIN

		INSERT INTO #tmp_vision_action_tracker_community_CommunityFilter_IsCommunityRfqReleased
		SELECT 1 [Value] 

		INSERT INTO #tmp_vision_action_tracker_community_CommunityFilter_IsCommunityRfqClosed
		SELECT 0 [Value] 
		UNION
		SELECT 1 [Value]	

	END	
	ELSE IF @IsCommunityAllRfqsNotReleased = 0 AND @IsCommunityAllRfqsReleased = 0 AND @IsCommunityAllRfqsClosed = 1
	BEGIN

		INSERT INTO #tmp_vision_action_tracker_community_CommunityFilter_IsCommunityRfqReleased
		SELECT 0 [Value]
		UNION
		SELECT 1 [Value]

		INSERT INTO #tmp_vision_action_tracker_community_CommunityFilter_IsCommunityRfqClosed
		SELECT 1 [Value] 

	END		
	

	
	IF @TrackerType = 'CatchAll'
	BEGIN

		INSERT INTO #tmp_vision_action_tracker_community
		SELECT 
			'Catch All'			AS [Type]
			,Id				AS Id
			--,CAST('false' AS BIT)				AS IsBuyer
			--,CAST('false' AS BIT)				AS UnVal
			,
			(	CASE 
					WHEN DATEDIFF(MINUTE,a.EmailMessageDate ,GETUTCDATE()) < 60		THEN CONVERT(VARCHAR(100),DATEDIFF(MINUTE,a.EmailMessageDate ,GETUTCDATE())) + ' mins ago'
					WHEN DATEDIFF(HOUR,a.EmailMessageDate ,GETUTCDATE()) < 24	THEN CONVERT(VARCHAR(100),DATEDIFF(HOUR,a.EmailMessageDate ,GETUTCDATE())) + ' hrs ago'
					ELSE  CONVERT(VARCHAR(10),FORMAT(a.EmailMessageDate , 'd', 'en-US' )) + ' ' + REVERSE(SUBSTRING(REVERSE(CONVERT(VARCHAR(20),a.EmailMessageDate )), 0 , CHARINDEX(' ',REVERSE(CONVERT(VARCHAR(20),a.EmailMessageDate )))))
				END
			)	AS LeadDate
			,EmailMessageDate	AS LeadDateTime
			,0					AS BuyerId
			,(BuyerFirstName+' '+ BuyerLastName) AS Buyer
			--,NULL				AS BuyerCompanyId
			,BuyerCompanyName	AS BuyerCompany
			,BuyerEmail			AS BuyerEmail
			,BuyerPhone			AS BuyerPhoneNo
   --,NULL    AS EmailSubject  
   --,NULL    AS EmailBody  
   , EmailSubject  --- modified with M2-4525
   , EmailBody     --- modified with M2-4525
			,(CASE WHEN  MessageFileId > 0 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END  )    AS EmailAttachment
			,Id					AS LeadId
			--,NULL				AS LeadEmailId
			--,NULL				AS MessageId
			,NULL				AS SupplierId
			,NULL				AS StatusId
			,NULL				AS SupplierCompanyId 
			,SupplierCompanyName	AS SupplierCompany
			--,BuyerFirstName			AS BuyerFirstName 
			--,BuyerLastName			AS BuyerLastName
			,NULL					AS SalesloftPeopleId
			,NULL					AS RfqId
			,NULL				AS RfqStatus
			,NULL				AS BuyerNpsScoreCode
			--,NULL				AS SourcingAdvisorId
			--,NULL				AS SourcingAdvisor
			,NULL				AS ActionTakenBy
			,NULL				AS ActionTakenDate
			--,NULL				AS MarkedById
			--,NULL				AS MarkedBy
			--,NULL				AS MarkedOn
			--,CAST('false' AS BIT)					AS IsMarked
			,NULL				AS rfq_created_on
			,CAST('false' AS BIT)					AS IsCommunityRfqReleased
			,CAST('false' AS BIT)					AS IsCommunityRfqClosed
			,CAST('false' AS BIT)					AS IsMfgCommunityRfq
			,CAST('false' AS BIT)					AS IsQMSEnabled
			,NULL				AS CommunityRfqReleaseDate
			,NULL				AS CommunityRfqReleaseById
			,NULL				AS CommunityRfqReleaseBy
			,NULL				AS CommunityRfqClosedDate
			,NULL				AS CommunityRfqClosedById
			,NULL				AS CommunityRfqClosedBy
			,CAST('false' AS BIT)					AS WantsMp
			, NULL		AS IsCommunityRatingApproved
			, NULL		AS CommunityRatingApprovedDeclineBy
			, NULL		AS CommunityRatingApprovedDeclineDate
			,COUNT(1) OVER () AS TotalRecordCount
   ,MessageFileId AS MessageId --- Added with M2-4525
		FROM mpCommunityExternalDirectoryMessages  (NOLOCK) a
		WHERE 	
            BuyerEmail <> 'zimneth05@gmail.com'	
            AND 
			(
				(BuyerCompanyName	 LIKE '%'+ISNULL(@Search,'')+'%')
				OR
				(BuyerFirstName+' '+ BuyerLastName)  LIKE  '%'+ISNULL(@Search,'')+'%'
				OR
				(BuyerEmail LIKE  '%'+ISNULL(@Search,'')+'%')
			)
			AND (CONVERT(DATE,EmailMessageDate) =  CASE WHEN @ByDate IS NULL THEN		CONVERT(DATE,EmailMessageDate) ELSE @ByDate END 	)
			AND (DATEDIFF(HOUR,EmailMessageDate ,GETUTCDATE()) <=  CASE WHEN @TimeRange IS NULL THEN	DATEDIFF(HOUR,EmailMessageDate ,GETUTCDATE()) ELSE @TimeRange END 	)
		ORDER BY 
				CASE  WHEN @IsOrderByDesc =  1 AND @OrderBy = 'LeadDateTime' THEN   EmailMessageDate END DESC
				,CASE  WHEN @IsOrderByDesc =  0 AND @OrderBy = 'LeadDateTime' THEN   EmailMessageDate END ASC 
				,CASE  WHEN @IsOrderByDesc =  1 AND @OrderBy = 'Buyer' THEN   (BuyerFirstName+' '+ BuyerLastName) END DESC 
				,CASE  WHEN @IsOrderByDesc =  0 AND @OrderBy = 'Buyer' THEN   (BuyerFirstName+' '+ BuyerLastName) END ASC 
		OFFSET @PageSize * (@PageNumber- 1) ROWS
		FETCH NEXT @PageSize ROWS ONLY

		SELECT * FROM #tmp_vision_action_tracker_community

	END

	IF @TrackerType = 'DirectoryRfqs'
	BEGIN
		
		INSERT INTO #tmp_vision_action_tracker_community
		SELECT * FROM 
		(
			SELECT DISTINCT 
				'Directory RFQs'			AS [Type]
				,a.rfq_id		AS Id
				--,CAST('false' AS BIT)				AS IsBuyer
				--,CAST('false' AS BIT)				AS UnVal
				,
				(	CASE 
						WHEN DATEDIFF(MINUTE,a.rfq_created_on ,GETUTCDATE()) < 60		THEN CONVERT(VARCHAR(100),DATEDIFF(MINUTE,a.rfq_created_on ,GETUTCDATE())) + ' mins ago'
						WHEN DATEDIFF(HOUR,a.rfq_created_on ,GETUTCDATE()) < 24	THEN CONVERT(VARCHAR(100),DATEDIFF(HOUR,a.rfq_created_on ,GETUTCDATE())) + ' hrs ago'
						ELSE  CONVERT(VARCHAR(10),FORMAT(a.rfq_created_on , 'd', 'en-US' )) + ' ' + REVERSE(SUBSTRING(REVERSE(CONVERT(VARCHAR(20),a.rfq_created_on )), 0 , CHARINDEX(' ',REVERSE(CONVERT(VARCHAR(20),a.rfq_created_on )))))
					END
				)	AS LeadDate
				,rfq_created_on	AS LeadDateTime
				,a.contact_id		AS BuyerId
				,(x.first_name +' '+ x.last_name) AS Buyer
				--,x.company_id		AS BuyerCompanyId
				,z.name				AS BuyerCompany
				,y.email			AS BuyerEmail
				,a1.communication_value						AS BuyerPhoneNo
				,'RFQ #'+ CONVERT(VARCHAR(150), a.rfq_id) 	AS EmailSubject
				,b1.description				AS EmailBody
				,CAST('true' AS BIT)    AS EmailAttachment
				,NULL					AS LeadId
				--,NULL				AS LeadEmailId
				--,NULL				AS MessageId
				,(SELECT TOP 1 contact_id FROM mp_contacts  (NOLOCK)  WHERE company_id = e1.company_id  AND is_admin = 1)				AS SupplierId
				,NULL				AS StatusId
				,e1.company_id			AS SupplierCompanyId
				,(SELECT TOP 1 name FROM mp_companies  (NOLOCK)  WHERE company_id = e1.company_id  )	AS SupplierCompany
				--,x.first_name			AS BuyerFirstName
				--,x.last_name			AS BuyerLastName
				,NULL					AS SalesloftPeopleId
				,a.rfq_id				AS RfqId
				,b1.description			AS RfqStatus
				,c1.no_of_stars			AS BuyerNpsScoreCode
				--,d1.contact_id			AS SourcingAdvisorId
				--,d1.last_name			AS SourcingAdvisor
				,NULL				AS ActionTakenBy
				,NULL				AS ActionTakenDate
				--,NULL				AS MarkedById
				--,NULL				AS MarkedBy
				--,NULL				AS MarkedOn
				--,CAST('false' AS BIT)					AS IsMarked
				,a.rfq_created_on	AS rfq_created_on
				,CASE WHEN IsCommunityRfqReleased = 0 THEN CAST('false' AS BIT)	ELSE CAST('true' AS BIT) END IsCommunityRfqReleased
				,CASE WHEN IsCommunityRfqClosed = 0 THEN CAST('false' AS BIT)	ELSE CAST('true' AS BIT) END	IsCommunityRfqClosed
				,CASE WHEN IsMfgCommunityRfq = 0 THEN CAST('false' AS BIT)	ELSE CAST('true' AS BIT) END IsMfgCommunityRfq
				,(SELECT CASE WHEN is_mqs_enable = 1 THEN CAST('true' AS bit) ELSE CAST('false' AS bit) END  FROM mp_companies  (NOLOCK)  WHERE company_id = e1.company_id ) AS IsQMSEnabled
				,CommunityRfqReleaseDate
				,CommunityRfqReleaseBy AS CommunityRfqReleaseById
				,(f1.first_name +' '+f1.last_name )				AS CommunityRfqReleaseBy
				,CommunityRfqClosedDate
				,CommunityRfqClosedBy AS CommunityRfqClosedById
				,(g1.first_name +' '+g1.last_name )					AS CommunityRfqClosedBy
				,CAST('false' AS BIT)					AS WantsMp
				, NULL		AS IsCommunityRatingApproved
				, NULL		AS CommunityRatingApprovedDeclineBy
				, NULL		AS CommunityRatingApprovedDeclineDate
				,COUNT(1) OVER () AS TotalRecordCount
	,NULL AS MessageId --- Added with M2-4525
			FROM mp_rfq  (NOLOCK) a
			LEFT JOIN mp_contacts	x	(NOLOCK) ON a.contact_id = x.contact_id AND  x.is_buyer = 1
			LEFT JOIN aspnetusers	y	(NOLOCK) ON x.user_id = y.id
			LEFT JOIN mp_companies	z	(NOLOCK) ON x.company_id = z.company_id  AND x.contact_id <>0 
			LEFT JOIN mp_communication_details  a1 (NOLOCK) ON x.contact_id = a1.contact_id AND a1.communication_type_id = 1
			LEFT JOIN mp_mst_rfq_buyerstatus	b1 (NOLOCK) ON a.rfq_status_id = b1.rfq_buyerstatus_id 
			LEFT JOIN mp_star_rating			c1 (NOLOCK) ON z.company_id = c1.company_id 
			LEFT JOIN mp_contacts				d1 (NOLOCK)	ON z.assigned_sourcingadvisor = d1.contact_id 
			LEFT JOIN mp_rfq_supplier			e1 (NOLOCK)	ON a.rfq_id = e1.rfq_id 
			LEFT JOIN mp_contacts				f1 (NOLOCK) ON a.CommunityRfqReleaseBy = f1.contact_id
			LEFT JOIN mp_contacts				g1 (NOLOCK) ON a.CommunityRfqClosedBy = g1.contact_id
			WHERE IsMfgCommunityRfq = 1
			AND a.rfq_status_id >=2  AND a.rfq_status_id != 13
			AND a.IsCommunityRfqReleased IN (SELECT * FROM #tmp_vision_action_tracker_community_CommunityFilter_IsCommunityRfqReleased)
			AND a.IsCommunityRfqClosed IN (SELECT * FROM #tmp_vision_action_tracker_community_CommunityFilter_IsCommunityRfqClosed)
			AND 
			(
				(z.name	 LIKE '%'+ISNULL(@Search,'')+'%')
				OR
				(x.first_name +' '+ x.last_name)  LIKE  '%'+ISNULL(@Search,'')+'%'
				OR
				(y.email LIKE  '%'+ISNULL(@Search,'')+'%')
			)
			AND (CONVERT(DATE,rfq_created_on) =  CASE WHEN @ByDate IS NULL THEN		CONVERT(DATE,rfq_created_on) ELSE @ByDate END 	)
			AND (DATEDIFF(HOUR,rfq_created_on ,GETUTCDATE()) <=  CASE WHEN @TimeRange IS NULL THEN	DATEDIFF(HOUR,rfq_created_on ,GETUTCDATE()) ELSE @TimeRange END 	)
		) a
		ORDER BY 
				CASE  WHEN @IsOrderByDesc =  1 AND @OrderBy = 'LeadDateTime' THEN   a.LeadDateTime END DESC
				,CASE  WHEN @IsOrderByDesc =  0 AND @OrderBy = 'LeadDateTime' THEN   a.LeadDateTime END ASC 
				,CASE  WHEN @IsOrderByDesc =  1 AND @OrderBy = 'Buyer' THEN   Buyer END DESC 
				,CASE  WHEN @IsOrderByDesc =  0 AND @OrderBy = 'Buyer' THEN   Buyer END ASC 
		OFFSET @PageSize * (@PageNumber- 1) ROWS
		FETCH NEXT @PageSize ROWS ONLY

		SELECT * FROM #tmp_vision_action_tracker_community

	END

	IF @TrackerType = 'SimpleRFQs'
	BEGIN
		
		INSERT INTO #tmp_vision_action_tracker_community
		SELECT 
			'Simple RFQs'	AS [Type]
			,a.Id		AS Id
			--,CAST('false' AS BIT)				AS IsBuyer
			--,CAST('false' AS BIT)				AS UnVal
			,
			(	CASE 
					WHEN DATEDIFF(MINUTE,a.CreatedOn ,GETUTCDATE()) < 60		THEN CONVERT(VARCHAR(100),DATEDIFF(MINUTE,a.CreatedOn ,GETUTCDATE())) + ' mins ago'
					WHEN DATEDIFF(HOUR,a.CreatedOn ,GETUTCDATE()) < 24	THEN CONVERT(VARCHAR(100),DATEDIFF(HOUR,a.CreatedOn ,GETUTCDATE())) + ' hrs ago'
					ELSE  CONVERT(VARCHAR(10),FORMAT(a.CreatedOn , 'd', 'en-US' )) + ' ' + REVERSE(SUBSTRING(REVERSE(CONVERT(VARCHAR(20),a.CreatedOn )), 0 , CHARINDEX(' ',REVERSE(CONVERT(VARCHAR(20),a.CreatedOn )))))
				END
			)	AS LeadDate
			,CreatedOn			AS LeadDateTime
			,ISNULL(x.contact_id,0)		AS BuyerId
			--,(x.first_name +' '+ x.last_name) AS Buyer
			/* M2-4336 Adding Fname and Lname from community portal simple RFQ table */
			,IIF(ISNULL(X.first_name,'')= '' AND ISNULL(X.last_name,'') ='',ISNULL(a.firstname,'') +' '+ ISNULL(a.lastname,''),ISNULL(x.first_name,'') +' '+ ISNULL(x.last_name,'')) AS Buyer
			--,x.company_id		AS BuyerCompanyId
			,z.name				AS BuyerCompany
			,COALESCE(y.email,a.BuyerEmail)						AS BuyerEmail
			,COALESCE(a1.communication_value,a.BuyerPhone)		AS BuyerPhoneNo
			,'Simple RFQ: ' + Capability +' - '+ Material 		AS EmailSubject
			,PartDesc				AS EmailBody
			----below code commented with M2-4873
			--,CASE WHEN PartFileId > 0 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END     AS EmailAttachment
			---- added below code with M2-4873
			, (SELECT TOP 1 CASE WHEN g1.CommunityDirectRfqId IS NOT NULL THEN  CAST('true' AS BIT) ELSE CAST('false' AS BIT) END 
			   FROM mpCommunityDirectRfqsFiles g1(NOLOCK)  WHERE g1.CommunityDirectRfqId = a.id )    AS EmailAttachment 
			,e1.lead_id			AS LeadId
			--,NULL				AS LeadEmailId
			--,NULL				AS MessageId
			,(SELECT TOP 1 contact_id FROM mp_contacts  (NOLOCK)  WHERE company_id = a.SupplierCompanyId  AND is_admin = 1)				AS SupplierId
			,CASE WHEN e1.status_id IN (0,1,2) THEN CONVERT(INT,e1.status_id) ELSE NULL END AS StatusId
			,a.SupplierCompanyId	AS SupplierCompanyId
			,(SELECT TOP 1 name FROM mp_companies  (NOLOCK)  WHERE company_id = a.SupplierCompanyId  )	AS SupplierCompany
			--,x.first_name			AS BuyerFirstName
			--,x.last_name			AS BuyerLastName
			,NULL					AS SalesloftPeopleId
			,NULL					AS RfqId
			,NULL					AS RfqStatus
			,c1.no_of_stars			AS BuyerNpsScoreCode
			--,d1.contact_id			AS SourcingAdvisorId
			--,d1.last_name			AS SourcingAdvisor
			,(f1.first_name +' '+ f1.last_name)	AS ActionTakenBy
			,e1.ModifiedOn						AS ActionTakenDate
			--,NULL				AS MarkedById
			--,NULL				AS MarkedBy
			--,NULL				AS MarkedOn
			--,CAST('false' AS BIT)					AS IsMarked
			,NULL				AS rfq_created_on
			,CAST('false' AS BIT)					AS IsCommunityRfqReleased
			,CAST('false' AS BIT)					AS IsCommunityRfqClosed
			,CAST('false' AS BIT)					AS IsMfgCommunityRfq
			,(SELECT CASE WHEN is_mqs_enable = 1 THEN CAST('true' AS bit) ELSE CAST('false' AS bit) END  FROM mp_companies  (NOLOCK)  WHERE company_id = a.SupplierCompanyId ) AS IsQMSEnabled
			,NULL				AS CommunityRfqReleaseDate
			,NULL				AS CommunityRfqReleaseBy
			,NULL				AS CommunityRfqReleaseBy
			,NULL				AS CommunityRfqClosedDate
			,NULL				AS CommunityRfqClosedBy
			,NULL				AS CommunityRfqClosedBy
			,CASE WHEN WantsMP = 0 THEN CAST('false' AS BIT) WHEN WantsMP = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END				AS WantsMp
			, NULL		AS IsCommunityRatingApproved
			, NULL		AS CommunityRatingApprovedDeclineBy
			, NULL		AS CommunityRatingApprovedDeclineDate
			,COUNT(1) OVER () AS TotalRecordCount
   ,NULL AS MessageId --- Added with M2-4525
		FROM [mpCommunityDirectRfqs]  (NOLOCK) a
		LEFT JOIN aspnetusers	y	(NOLOCK) ON a.BuyerEmail = y.Email
		LEFT JOIN mp_contacts	x	(NOLOCK) ON x.user_id = y.id AND  x.is_buyer = 1
		LEFT JOIN mp_companies	z	(NOLOCK) ON x.company_id = z.company_id  AND x.contact_id <>0 
		LEFT JOIN mp_communication_details  a1 (NOLOCK) ON x.contact_id = a1.contact_id AND a1.communication_type_id = 1
		LEFT JOIN mp_star_rating			c1 (NOLOCK) ON z.company_id = c1.company_id 
		LEFT JOIN mp_contacts				d1 (NOLOCK)	ON z.assigned_sourcingadvisor = d1.contact_id 
		LEFT JOIN mp_lead					e1 (NOLOCK) ON a.LeadId = e1.lead_id
		LEFT JOIN mp_contacts				f1 (NOLOCK) ON e1.ModifiedBy = f1.contact_id 
		WHERE  
			(
				COALESCE(y.email,a.BuyerEmail)  LIKE  '%'+ISNULL(@Search,'')+'%'
			)
		AND ISNULL(e1.status_id,-1) = CASE WHEN @StatusId = -1 THEN ISNULL(e1.status_id,-1) ELSE @StatusId END
		AND ISNULL(e1.status_id,-1) <> 2
		AND (CONVERT(DATE,CreatedOn) =  CASE WHEN @ByDate IS NULL THEN		CONVERT(DATE,CreatedOn) ELSE @ByDate END 	)
		AND (DATEDIFF(HOUR,CreatedOn ,GETUTCDATE()) <=  CASE WHEN @TimeRange IS NULL THEN	DATEDIFF(HOUR,CreatedOn ,GETUTCDATE()) ELSE @TimeRange END 	)

		ORDER BY 
				CASE  WHEN @IsOrderByDesc =  1 AND @OrderBy = 'LeadDateTime' THEN   CreatedOn END DESC
				,CASE  WHEN @IsOrderByDesc =  0 AND @OrderBy = 'LeadDateTime' THEN   CreatedOn END ASC 
				,CASE  WHEN @IsOrderByDesc =  1 AND @OrderBy = 'Buyer' THEN   (x.first_name +' '+ x.last_name) END DESC 
				,CASE  WHEN @IsOrderByDesc =  0 AND @OrderBy = 'Buyer' THEN   (x.first_name +' '+ x.last_name) END ASC 
		OFFSET @PageSize * (@PageNumber- 1) ROWS
		FETCH NEXT @PageSize ROWS ONLY

		SELECT * FROM #tmp_vision_action_tracker_community

	END

	/* M2-3994 Vision - Action Tracker - Add Ratings and Reviews tab to Community Users - API */
	IF @TrackerType = 'Ratings'
	BEGIN
		
		INSERT INTO #tmp_vision_action_tracker_community
		SELECT 
			'Ratings'			AS [Type]
			,a.Id				AS Id
			--,CAST('false' AS BIT)				AS IsBuyer
			--,CAST('false' AS BIT)				AS UnVal
			,
			(	CASE 
					WHEN DATEDIFF(MINUTE,a.RatingDate ,GETUTCDATE()) < 60		THEN CONVERT(VARCHAR(100),DATEDIFF(MINUTE,a.RatingDate ,GETUTCDATE())) + ' mins ago'
					WHEN DATEDIFF(HOUR,a.RatingDate ,GETUTCDATE()) < 24	THEN CONVERT(VARCHAR(100),DATEDIFF(HOUR,a.RatingDate ,GETUTCDATE())) + ' hrs ago'
					ELSE  CONVERT(VARCHAR(10),FORMAT(a.RatingDate , 'd', 'en-US' )) + ' ' + REVERSE(SUBSTRING(REVERSE(CONVERT(VARCHAR(20),a.RatingDate )), 0 , CHARINDEX(' ',REVERSE(CONVERT(VARCHAR(20),a.RatingDate )))))
				END
			)	AS LeadDate
			,RatingDate	AS LeadDateTime
			,0					AS BuyerId
			,(a.FirstName+' '+ a.LastName) AS Buyer
			--,NULL				AS BuyerCompanyId
			,SenderCompany		AS BuyerCompany
			,SenderEmail		AS BuyerEmail
			,''				AS BuyerPhoneNo
			,CONVERT(VARCHAR(100),Rating) 	AS EmailSubject
			,CONVERT(VARCHAR(MAX),Comment)	AS EmailBody
			,CAST('false' AS BIT)			AS EmailAttachment
			,NULL				AS LeadId
			--,NULL				AS LeadEmailId
			--,NULL				AS MessageId
			,NULL				AS SupplierId
			,NULL				AS StatusId
			,c.company_id		AS SupplierCompanyId 
			,ReceiverCompany	AS SupplierCompany
			--,BuyerFirstName			AS BuyerFirstName
			--,BuyerLastName			AS BuyerLastName
			,NULL					AS SalesloftPeopleId
			,NULL					AS RfqId
			,''					AS RfqStatus
			,NULL				AS BuyerNpsScoreCode
			--,NULL				AS SourcingAdvisorId
			--,''					AS SourcingAdvisor
			,''				AS ActionTakenBy
			,NULL				AS ActionTakenDate
			--,NULL				AS MarkedById
			--,NULL				AS MarkedBy
			--,NULL				AS MarkedOn
			--,CAST('false' AS BIT)					AS IsMarked
			,NULL				AS rfq_created_on
			,CAST('false' AS BIT)					AS IsCommunityRfqReleased
			,CAST('false' AS BIT)					AS IsCommunityRfqClosed
			,CAST('false' AS BIT)					AS IsMfgCommunityRfq
			,CAST('false' AS BIT)					AS IsQMSEnabled
			,NULL				AS CommunityRfqReleaseDate
			,NULL				AS CommunityRfqReleaseById
			,''					AS CommunityRfqReleaseBy
			,NULL				AS CommunityRfqClosedDate
			,NULL				AS CommunityRfqClosedById
			,''					AS CommunityRfqClosedBy
			,CAST('false' AS BIT)					AS WantsMp
			, IsApproved							AS IsCommunityRatingApproved
			, (f1.first_name +' '+ f1.last_name)	AS CommunityRatingApprovedDeclineBy
			, ApprovedDeclineDate					AS CommunityRatingApprovedDeclineDate
			,COUNT(1) OVER () AS TotalRecordCount
   ,NULL    AS MessageId  ---- Added with M2-4525
		FROM mpCommunityRatings  (NOLOCK) a
		----- Slack issue : include MFG suppliers only in the list so left join are removed from join tables
		LEFT JOIN mp_contacts	 (NOLOCK) f1  ON a.ApprovedDeclineBy = f1.contact_id
		/* M2-5049 LEFT JOIN added in below tables */
		LEFT JOIN aspnetusers	 (NOLOCK) b ON a.ReceiverEmail = b.email
		LEFT JOIN mp_contacts	 (NOLOCK) c ON b.id = c.user_id
		WHERE 		 
			(
				(SenderCompany	 LIKE '%'+ISNULL(@Search,'')+'%')
				OR
				(a.FirstName+' '+ a.LastName)  LIKE  '%'+ISNULL(@Search,'')+'%'
				OR
				(SenderEmail LIKE  '%'+ISNULL(@Search,'')+'%')
			)
			AND (CONVERT(DATE,RatingDate) =  CASE WHEN @ByDate IS NULL THEN		CONVERT(DATE,RatingDate) ELSE @ByDate END 	)
			AND (DATEDIFF(HOUR,RatingDate ,GETUTCDATE()) <=  CASE WHEN @TimeRange IS NULL THEN	DATEDIFF(HOUR,RatingDate ,GETUTCDATE()) ELSE @TimeRange END 	)
		ORDER BY 
				CASE  WHEN @IsOrderByDesc =  1 AND @OrderBy = 'LeadDateTime' THEN   RatingDate END DESC
				,CASE  WHEN @IsOrderByDesc =  0 AND @OrderBy = 'LeadDateTime' THEN   RatingDate END ASC 
				,CASE  WHEN @IsOrderByDesc =  1 AND @OrderBy = 'Buyer' THEN   (a.FirstName+' '+ a.LastName) END DESC 
				,CASE  WHEN @IsOrderByDesc =  0 AND @OrderBy = 'Buyer' THEN   (a.FirstName+' '+ a.LastName) END ASC 
		OFFSET @PageSize * (@PageNumber- 1) ROWS
		FETCH NEXT @PageSize ROWS ONLY


		SELECT * FROM #tmp_vision_action_tracker_community

	END
	/**/


	IF @TrackerType = 'All' 
	BEGIN 
			
		INSERT INTO #tmp_vision_action_tracker_community
			(Type,Id,LeadDate,LeadDateTime,BuyerId,Buyer,BuyerCompany,BuyerEmail,BuyerPhoneNo,EmailSubject,EmailBody
			,EmailAttachment,LeadId , SupplierId,StatusId,SupplierCompanyId,SupplierCompany,SalesloftPeopleId,RfqId,RfqStatus ,BuyerNpsScoreCode
			,ActionTakenBy,ActionTakenDate,rfq_created_on,IsCommunityRfqReleased,	IsCommunityRfqClosed,IsMfgCommunityRfq,IsQMSEnabled
			,CommunityRfqReleaseDate,CommunityRfqReleaseById,CommunityRfqReleaseBy,CommunityRfqClosedDate,	CommunityRfqClosedById,CommunityRfqClosedBy,WantsMp,IsCommunityRatingApproved
   ,CommunityRatingApprovedDeclineBy,CommunityRatingApprovedDeclineDate,MessageID)  
		SELECT DISTINCT 
			'Directory RFQs'AS [Type]
			,a.rfq_id		AS Id
			--,CAST('false' AS BIT)				AS IsBuyer
			--,CAST('false' AS BIT)				AS UnVal
			,
			(	CASE 
					WHEN DATEDIFF(MINUTE,a.rfq_created_on ,GETUTCDATE()) < 60		THEN CONVERT(VARCHAR(100),DATEDIFF(MINUTE,a.rfq_created_on ,GETUTCDATE())) + ' mins ago'
					WHEN DATEDIFF(HOUR,a.rfq_created_on ,GETUTCDATE()) < 24	THEN CONVERT(VARCHAR(100),DATEDIFF(HOUR,a.rfq_created_on ,GETUTCDATE())) + ' hrs ago'
					ELSE  CONVERT(VARCHAR(10),FORMAT(a.rfq_created_on , 'd', 'en-US' )) + ' ' + REVERSE(SUBSTRING(REVERSE(CONVERT(VARCHAR(20),a.rfq_created_on )), 0 , CHARINDEX(' ',REVERSE(CONVERT(VARCHAR(20),a.rfq_created_on )))))
				END
			)	AS LeadDate
			,rfq_created_on	AS LeadDateTime
			,ISNULL(a.contact_id,0)		AS BuyerId
			,(x.first_name +' '+ x.last_name) AS Buyer
			--,x.company_id		AS BuyerCompanyId
			,z.name				AS BuyerCompany
			,y.email			AS BuyerEmail
			,a1.communication_value						AS BuyerPhoneNo
			,'RFQ #'+ CONVERT(VARCHAR(150), a.rfq_id) 	AS EmailSubject
			,b1.description				AS EmailBody
			,CAST('true' AS BIT)    AS EmailAttachment
			,NULL					AS LeadId
			--,NULL				AS LeadEmailId
			--,NULL				AS MessageId
			,(SELECT TOP 1 contact_id FROM mp_contacts  (NOLOCK)  WHERE company_id = e1.company_id  AND is_admin = 1)				AS SupplierId
			,NULL				AS StatusId
			,e1.company_id			AS SupplierCompanyId
			,(SELECT TOP 1 name FROM mp_companies  (NOLOCK)  WHERE company_id = e1.company_id  )	AS SupplierCompany
			--,x.first_name			AS BuyerFirstName
			--,x.last_name			AS BuyerLastName
			,NULL					AS SalesloftPeopleId
			,a.rfq_id				AS RfqId
			,b1.description			AS RfqStatus
			,c1.no_of_stars			AS BuyerNpsScoreCode
			--,d1.contact_id			AS SourcingAdvisorId
			--,d1.last_name			AS SourcingAdvisor
			,''			AS ActionTakenBy
			,NULL			AS ActionTakenDate
			--,NULL				AS MarkedById
			--,NULL				AS MarkedBy
			--,NULL				AS MarkedOn
			--,CAST('false' AS BIT)					AS IsMarked
			,a.rfq_created_on	AS rfq_created_on
			,CASE WHEN IsCommunityRfqReleased = 0 THEN CAST('false' AS BIT)	ELSE CAST('true' AS BIT) END IsCommunityRfqReleased
			,CASE WHEN IsCommunityRfqClosed = 0 THEN CAST('false' AS BIT)	ELSE CAST('true' AS BIT) END	IsCommunityRfqClosed
			,CASE WHEN IsMfgCommunityRfq = 0 THEN CAST('false' AS BIT)	ELSE CAST('true' AS BIT) END IsMfgCommunityRfq
			,(SELECT CASE WHEN is_mqs_enable = 1 THEN CAST('true' AS bit) ELSE CAST('false' AS bit) END  FROM mp_companies  (NOLOCK)  WHERE company_id = e1.company_id ) AS IsQMSEnabled
			,CommunityRfqReleaseDate
			,CommunityRfqReleaseBy AS CommunityRfqReleaseById
			,(f1.first_name +' '+f1.last_name )				AS CommunityRfqReleaseBy
			,CommunityRfqClosedDate
			,CommunityRfqClosedBy AS CommunityRfqClosedById
			,(g1.first_name +' '+g1.last_name )					AS CommunityRfqClosedBy
			,CAST('false' AS BIT)					AS WantsMp
			, NULL		AS IsCommunityRatingApproved
			, ''		AS CommunityRatingApprovedDeclineBy
			, NULL		AS CommunityRatingApprovedDeclineDate
   , NULL AS MessageId ---- Added with M2-4525
		FROM mp_rfq  (NOLOCK) a
		LEFT JOIN mp_contacts	x	(NOLOCK) ON a.contact_id = x.contact_id AND  x.is_buyer = 1
		LEFT JOIN aspnetusers	y	(NOLOCK) ON x.user_id = y.id
		LEFT JOIN mp_companies	z	(NOLOCK) ON x.company_id = z.company_id  AND x.contact_id <>0 
		LEFT JOIN mp_communication_details  a1 (NOLOCK) ON x.contact_id = a1.contact_id AND a1.communication_type_id = 1
		LEFT JOIN mp_mst_rfq_buyerstatus	b1 (NOLOCK) ON a.rfq_status_id = b1.rfq_buyerstatus_id 
		LEFT JOIN mp_star_rating			c1 (NOLOCK) ON z.company_id = c1.company_id 
		LEFT JOIN mp_contacts				d1 (NOLOCK)	ON z.assigned_sourcingadvisor = d1.contact_id 
		LEFT JOIN mp_rfq_supplier			e1 (NOLOCK)	ON a.rfq_id = e1.rfq_id 
		LEFT JOIN mp_contacts				f1 (NOLOCK) ON a.CommunityRfqReleaseBy = f1.contact_id
		LEFT JOIN mp_contacts				g1 (NOLOCK) ON a.CommunityRfqClosedBy = g1.contact_id
		WHERE IsMfgCommunityRfq = 1
		AND a.rfq_status_id >=2  AND a.rfq_status_id != 13
		AND a.IsCommunityRfqReleased IN (SELECT * FROM #tmp_vision_action_tracker_community_CommunityFilter_IsCommunityRfqReleased)
		AND a.IsCommunityRfqClosed IN (SELECT * FROM #tmp_vision_action_tracker_community_CommunityFilter_IsCommunityRfqClosed)
		AND 
			(
				(z.name	 LIKE '%'+ISNULL(@Search,'')+'%')
				OR
				(x.first_name +' '+ x.last_name)  LIKE  '%'+ISNULL(@Search,'')+'%'
				OR
				(y.email LIKE  '%'+ISNULL(@Search,'')+'%')
				
			)
		AND (CONVERT(DATE,rfq_created_on) =  CASE WHEN @ByDate IS NULL THEN		CONVERT(DATE,rfq_created_on) ELSE @ByDate END 	)
		AND (DATEDIFF(HOUR,rfq_created_on ,GETUTCDATE()) <=  CASE WHEN @TimeRange IS NULL THEN	DATEDIFF(HOUR,rfq_created_on ,GETUTCDATE()) ELSE @TimeRange END 	)

		INSERT INTO #tmp_vision_action_tracker_community
			(Type,Id,LeadDate,LeadDateTime,BuyerId,Buyer,BuyerCompany,BuyerEmail,BuyerPhoneNo,EmailSubject,EmailBody
			,EmailAttachment,LeadId , SupplierId,StatusId,SupplierCompanyId,SupplierCompany,SalesloftPeopleId,RfqId,RfqStatus ,BuyerNpsScoreCode
			,ActionTakenBy,ActionTakenDate,rfq_created_on,IsCommunityRfqReleased,	IsCommunityRfqClosed,IsMfgCommunityRfq,IsQMSEnabled
			,CommunityRfqReleaseDate,CommunityRfqReleaseById,CommunityRfqReleaseBy,CommunityRfqClosedDate,	CommunityRfqClosedById,CommunityRfqClosedBy,WantsMp,IsCommunityRatingApproved
   ,CommunityRatingApprovedDeclineBy,CommunityRatingApprovedDeclineDate,MessageId)  
		SELECT 
			'Catch All'			AS [Type]
			,a.Id		AS Id
			--,CAST('false' AS BIT)				AS IsBuyer
			--,CAST('false' AS BIT)				AS UnVal
			,
			(	CASE 
					WHEN DATEDIFF(MINUTE,a.EmailMessageDate ,GETUTCDATE()) < 60		THEN CONVERT(VARCHAR(100),DATEDIFF(MINUTE,a.EmailMessageDate ,GETUTCDATE())) + ' mins ago'
					WHEN DATEDIFF(HOUR,a.EmailMessageDate ,GETUTCDATE()) < 24	THEN CONVERT(VARCHAR(100),DATEDIFF(HOUR,a.EmailMessageDate ,GETUTCDATE())) + ' hrs ago'
					ELSE  CONVERT(VARCHAR(10),FORMAT(a.EmailMessageDate , 'd', 'en-US' )) + ' ' + REVERSE(SUBSTRING(REVERSE(CONVERT(VARCHAR(20),a.EmailMessageDate )), 0 , CHARINDEX(' ',REVERSE(CONVERT(VARCHAR(20),a.EmailMessageDate )))))
				END
			)	AS LeadDate
			,EmailMessageDate	AS LeadDateTime
			,0					AS BuyerId
			,(BuyerFirstName+' '+ BuyerLastName) AS Buyer
			--,NULL				AS BuyerCompanyId
			,BuyerCompanyName	AS BuyerCompany
			,BuyerEmail			AS BuyerEmail
			,BuyerPhone			AS BuyerPhoneNo
   --,''     AS EmailSubject  
   --,''    AS EmailBody 
   , EmailSubject  --- modified with M2-4525
   , EmailBody     --- modified with M2-4525
			,(CASE WHEN  MessageFileId > 0 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END  )    AS EmailAttachment
			,Id					AS LeadId
			--,NULL				AS LeadEmailId
			--,NULL				AS MessageId
			,NULL				AS SupplierId
			,NULL				AS StatusId
			,NULL				AS SupplierCompanyId
			,SupplierCompanyName	AS SupplierCompany
			--,BuyerFirstName			AS BuyerFirstName
			--,BuyerLastName			AS BuyerLastName
			,NULL					AS SalesloftPeopleId
			,NULL					AS RfqId
			,''					AS RfqStatus
			,NULL				AS BuyerNpsScoreCode
			--,NULL				AS SourcingAdvisorId
			--,''					AS SourcingAdvisor
			,''				AS ActionTakenBy
			,NULL				AS ActionTakenDate
			--,NULL				AS MarkedById
			--,NULL				AS MarkedBy
			--,NULL				AS MarkedOn
			--,CAST('false' AS BIT)					AS IsMarked
			,NULL				AS rfq_created_on
			,CAST('false' AS BIT)					AS IsCommunityRfqReleased
			,CAST('false' AS BIT)					AS IsCommunityRfqClosed
			,CAST('false' AS BIT)					AS IsMfgCommunityRfq
			,CAST('false' AS BIT)					AS IsQMSEnabled
			,NULL				AS CommunityRfqReleaseDate
			,NULL				AS CommunityRfqReleaseById
			,''					AS CommunityRfqReleaseBy
			,NULL				AS CommunityRfqClosedDate
			,NULL				AS CommunityRfqClosedById
			,''					AS CommunityRfqClosedBy
			,CAST('false' AS BIT)					AS WantsMp
			, NULL		AS IsCommunityRatingApproved
			, ''		AS CommunityRatingApprovedDeclineBy
			, NULL		AS CommunityRatingApprovedDeclineDate
   , MessageFileId    AS MessageId  ---- Added with M2-4525 
		FROM mpCommunityExternalDirectoryMessages  (NOLOCK) a
		WHERE 	
            BuyerEmail <> 'zimneth05@gmail.com'
            AND 	 
			(
				(BuyerCompanyName	 LIKE '%'+ISNULL(@Search,'')+'%')
				OR
				(BuyerFirstName+' '+ BuyerLastName)  LIKE  '%'+ISNULL(@Search,'')+'%'
				OR
				(BuyerEmail LIKE  '%'+ISNULL(@Search,'')+'%')
				
			)
			AND (CONVERT(DATE,EmailMessageDate) =  CASE WHEN @ByDate IS NULL THEN		CONVERT(DATE,EmailMessageDate) ELSE @ByDate END 	)
			AND (DATEDIFF(HOUR,EmailMessageDate ,GETUTCDATE()) <=  CASE WHEN @TimeRange IS NULL THEN	DATEDIFF(HOUR,EmailMessageDate ,GETUTCDATE()) ELSE @TimeRange END 	)

		INSERT INTO #tmp_vision_action_tracker_community
			(Type,Id,LeadDate,LeadDateTime,BuyerId,Buyer,BuyerCompany,BuyerEmail,BuyerPhoneNo,EmailSubject,EmailBody
			,EmailAttachment,LeadId , SupplierId,StatusId,SupplierCompanyId,SupplierCompany,SalesloftPeopleId,RfqId,RfqStatus ,BuyerNpsScoreCode
			,ActionTakenBy,ActionTakenDate,rfq_created_on,IsCommunityRfqReleased,	IsCommunityRfqClosed,IsMfgCommunityRfq,IsQMSEnabled
			,CommunityRfqReleaseDate,CommunityRfqReleaseById,CommunityRfqReleaseBy,CommunityRfqClosedDate,	CommunityRfqClosedById,CommunityRfqClosedBy,WantsMp,IsCommunityRatingApproved
   ,CommunityRatingApprovedDeclineBy,CommunityRatingApprovedDeclineDate,MessageId)  
		SELECT 
			'Simple RFQs'	AS [Type]
			,a.Id		AS Id
			--,CAST('false' AS BIT)				AS IsBuyer
			--,CAST('false' AS BIT)				AS UnVal
			,
			(	CASE 
					WHEN DATEDIFF(MINUTE,a.CreatedOn ,GETUTCDATE()) < 60		THEN CONVERT(VARCHAR(100),DATEDIFF(MINUTE,a.CreatedOn ,GETUTCDATE())) + ' mins ago'
					WHEN DATEDIFF(HOUR,a.CreatedOn ,GETUTCDATE()) < 24	THEN CONVERT(VARCHAR(100),DATEDIFF(HOUR,a.CreatedOn ,GETUTCDATE())) + ' hrs ago'
					ELSE  CONVERT(VARCHAR(10),FORMAT(a.CreatedOn , 'd', 'en-US' )) + ' ' + REVERSE(SUBSTRING(REVERSE(CONVERT(VARCHAR(20),a.CreatedOn )), 0 , CHARINDEX(' ',REVERSE(CONVERT(VARCHAR(20),a.CreatedOn )))))
				END
			)	AS LeadDate
			,CreatedOn			AS LeadDateTime
			,ISNULL(x.contact_id,0)			AS BuyerId
			,(x.first_name +' '+ x.last_name) AS Buyer
			--,x.company_id		AS BuyerCompanyId
			,z.name				AS BuyerCompany
			,COALESCE(y.email,a.BuyerEmail)						AS BuyerEmail
			,COALESCE(a1.communication_value,a.BuyerPhone)		AS BuyerPhoneNo
			,'Simple RFQ: ' + Capability +' - '+ Material 			AS EmailSubject
			,PartDesc				AS EmailBody
			----below code commented with M2-4873
			--,CASE WHEN PartFileId > 0 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END     AS EmailAttachment
			---- added below code with M2-4873
			, (SELECT TOP 1 CASE WHEN g1.CommunityDirectRfqId IS NOT NULL THEN  CAST('true' AS BIT) ELSE CAST('false' AS BIT) END 
			   FROM mpCommunityDirectRfqsFiles g1(NOLOCK)  WHERE g1.CommunityDirectRfqId = a.id )    AS EmailAttachment 
			,e1.lead_id			AS LeadId
			--,NULL				AS LeadEmailId
			--,NULL				AS MessageId
			,(SELECT TOP 1 contact_id FROM mp_contacts  (NOLOCK)  WHERE company_id = a.SupplierCompanyId  AND is_admin = 1)				AS SupplierId
			,CASE WHEN e1.status_id IN (0,1,2) THEN CONVERT(INT,e1.status_id) ELSE NULL END 			AS StatusId
			,a.SupplierCompanyId	AS SupplierCompanyId
			,(SELECT TOP 1 name FROM mp_companies  (NOLOCK)  WHERE company_id = a.SupplierCompanyId  )	AS SupplierCompany
			--,x.first_name			AS BuyerFirstName
			--,x.last_name			AS BuyerLastName
			,NULL					AS SalesloftPeopleId
			,NULL					AS RfqId
			,''						AS RfqStatus
			,c1.no_of_stars			AS BuyerNpsScoreCode
			--,d1.contact_id			AS SourcingAdvisorId
			--,d1.last_name			AS SourcingAdvisor
			,(f1.first_name +' '+ f1.last_name)	AS ActionTakenBy
			,e1.ModifiedOn						AS ActionTakenDate
			--,NULL				AS MarkedById
			--,NULL				AS MarkedBy
			--,NULL				AS MarkedOn
			--,CAST('false' AS BIT)					AS IsMarked
			,NULL				AS rfq_created_on
			,CAST('false' AS BIT)					AS IsCommunityRfqReleased
			,CAST('false' AS BIT)					AS IsCommunityRfqClosed
			,CAST('false' AS BIT)					AS IsMfgCommunityRfq
			,(SELECT CASE WHEN is_mqs_enable = 1 THEN CAST('true' AS bit) ELSE CAST('false' AS bit) END  FROM mp_companies  (NOLOCK)  WHERE company_id = a.SupplierCompanyId ) AS IsQMSEnabled
			,NULL				AS CommunityRfqReleaseDate
			,NULL				AS CommunityRfqReleaseById
			,''					AS CommunityRfqReleaseBy
			,NULL				AS CommunityRfqClosedDate
			,NULL				AS CommunityRfqClosedById
			,''					AS CommunityRfqClosedBy
			,CASE WHEN WantsMP = 0 THEN CAST('false' AS BIT) WHEN WantsMP = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END				AS WantsMp
			, NULL		AS IsCommunityRatingApproved
			, ''		AS CommunityRatingApprovedDeclineBy
			, NULL		AS CommunityRatingApprovedDeclineDate
   ,NULL    AS MessageId  ---- Added with M2-4525 
		FROM [mpCommunityDirectRfqs]  (NOLOCK) a
		LEFT JOIN aspnetusers	y	(NOLOCK) ON a.BuyerEmail = y.Email
		LEFT JOIN mp_contacts	x	(NOLOCK) ON x.user_id = y.id AND  x.is_buyer = 1
		LEFT JOIN mp_companies	z	(NOLOCK) ON x.company_id = z.company_id  AND x.contact_id <>0 
		LEFT JOIN mp_communication_details  a1 (NOLOCK) ON x.contact_id = a1.contact_id AND a1.communication_type_id = 1
		LEFT JOIN mp_star_rating			c1 (NOLOCK) ON z.company_id = c1.company_id 
		LEFT JOIN mp_contacts				d1 (NOLOCK)	ON z.assigned_sourcingadvisor = d1.contact_id 
		LEFT JOIN mp_lead					e1 (NOLOCK) ON a.LeadId = e1.lead_id
		LEFT JOIN mp_contacts				f1 (NOLOCK) ON e1.ModifiedBy = f1.contact_id 
		WHERE  
			(
				COALESCE(y.email,a.BuyerEmail)  LIKE  '%'+ISNULL(@Search,'')+'%'
				
			)
		AND (CONVERT(DATE,CreatedOn) =  CASE WHEN @ByDate IS NULL THEN		CONVERT(DATE,CreatedOn) ELSE @ByDate END 	)
		AND (DATEDIFF(HOUR,CreatedOn ,GETUTCDATE()) <=  CASE WHEN @TimeRange IS NULL THEN	DATEDIFF(HOUR,CreatedOn ,GETUTCDATE()) ELSE @TimeRange END 	)
		AND ISNULL(e1.status_id,-1) = CASE WHEN @StatusId = -1 THEN ISNULL(e1.status_id,-1) ELSE @StatusId END
		AND ISNULL(e1.status_id,-1) <> 2

		/* M2-3994 Vision - Action Tracker - Add Ratings and Reviews tab to Community Users - API */
		INSERT INTO #tmp_vision_action_tracker_community
			(Type,Id,LeadDate,LeadDateTime,BuyerId,Buyer,BuyerCompany,BuyerEmail,BuyerPhoneNo,EmailSubject,EmailBody
			,EmailAttachment,LeadId , SupplierId,StatusId,SupplierCompanyId,SupplierCompany,SalesloftPeopleId,RfqId,RfqStatus ,BuyerNpsScoreCode
			,ActionTakenBy,ActionTakenDate,rfq_created_on,IsCommunityRfqReleased,	IsCommunityRfqClosed,IsMfgCommunityRfq,IsQMSEnabled
			,CommunityRfqReleaseDate,CommunityRfqReleaseById,CommunityRfqReleaseBy,CommunityRfqClosedDate,	CommunityRfqClosedById,CommunityRfqClosedBy,WantsMp,IsCommunityRatingApproved
   ,CommunityRatingApprovedDeclineBy,CommunityRatingApprovedDeclineDate,MessageId)  
		SELECT 
			'Ratings'			AS [Type]
			,a.Id				AS Id
			--,CAST('false' AS BIT)				AS IsBuyer
			--,CAST('false' AS BIT)				AS UnVal
			,
			(	CASE 
					WHEN DATEDIFF(MINUTE,a.RatingDate ,GETUTCDATE()) < 60		THEN CONVERT(VARCHAR(100),DATEDIFF(MINUTE,a.RatingDate ,GETUTCDATE())) + ' mins ago'
					WHEN DATEDIFF(HOUR,a.RatingDate ,GETUTCDATE()) < 24	THEN CONVERT(VARCHAR(100),DATEDIFF(HOUR,a.RatingDate ,GETUTCDATE())) + ' hrs ago'
					ELSE  CONVERT(VARCHAR(10),FORMAT(a.RatingDate , 'd', 'en-US' )) + ' ' + REVERSE(SUBSTRING(REVERSE(CONVERT(VARCHAR(20),a.RatingDate )), 0 , CHARINDEX(' ',REVERSE(CONVERT(VARCHAR(20),a.RatingDate )))))
				END
			)	AS LeadDate
			,RatingDate	AS LeadDateTime
			,0					AS BuyerId
			,(a.FirstName+' '+ a.LastName) AS Buyer
			--,NULL				AS BuyerCompanyId
			,SenderCompany		AS BuyerCompany
			,SenderEmail		AS BuyerEmail
			,''				AS BuyerPhoneNo
			,CONVERT(VARCHAR(100),Rating) 	AS EmailSubject
			,CONVERT(VARCHAR(MAX),Comment)	AS EmailBody
			,CAST('false' AS BIT)			AS EmailAttachment
			,NULL				AS LeadId
			--,NULL				AS LeadEmailId
			--,NULL				AS MessageId
			,NULL				AS SupplierId
			,NULL				AS StatusId
			,c.company_id			AS SupplierCompanyId 
			,ReceiverCompany	AS SupplierCompany
			--,BuyerFirstName			AS BuyerFirstName
			--,BuyerLastName			AS BuyerLastName
			,NULL					AS SalesloftPeopleId
			,NULL					AS RfqId
			,''					AS RfqStatus
			,NULL				AS BuyerNpsScoreCode
			--,NULL				AS SourcingAdvisorId
			--,''					AS SourcingAdvisor
			,''				AS ActionTakenBy
			,NULL				AS ActionTakenDate
			--,NULL				AS MarkedById
			--,NULL				AS MarkedBy
			--,NULL				AS MarkedOn
			--,CAST('false' AS BIT)					AS IsMarked
			,NULL				AS rfq_created_on
			,CAST('false' AS BIT)					AS IsCommunityRfqReleased
			,CAST('false' AS BIT)					AS IsCommunityRfqClosed
			,CAST('false' AS BIT)					AS IsMfgCommunityRfq
			,CAST('false' AS BIT)					AS IsQMSEnabled
			,NULL				AS CommunityRfqReleaseDate
			,NULL				AS CommunityRfqReleaseById
			,''					AS CommunityRfqReleaseBy
			,NULL				AS CommunityRfqClosedDate
			,NULL				AS CommunityRfqClosedById
			,''					AS CommunityRfqClosedBy
			,CAST('false' AS BIT)					AS WantsMp
			, IsApproved		AS IsCommunityRatingApproved
			, (f1.first_name +' '+ f1.last_name) AS CommunityRatingApprovedDeclineBy
			, ApprovedDeclineDate AS CommunityRatingApprovedDeclineDate
   ,NULL    AS MessageId  ---- Added with M2-4525 
		FROM mpCommunityRatings  (NOLOCK) a
		----- Slack issue : include MFG suppliers only in the list so left join are removed from join tables
		LEFT JOIN mp_contacts	 (NOLOCK) f1  ON a.ApprovedDeclineBy = f1.contact_id 
		/* M2-5049 LEFT JOIN added in below tables */
		LEFT JOIN aspnetusers	 (NOLOCK) b ON a.ReceiverEmail = b.email
		LEFT JOIN mp_contacts	 (NOLOCK) c ON b.id = c.user_id
		WHERE 		 
			(
				(SenderCompany	 LIKE '%'+ISNULL(@Search,'')+'%')
				OR
				(a.FirstName+' '+ a.LastName)  LIKE  '%'+ISNULL(@Search,'')+'%'
				OR
				(SenderEmail LIKE  '%'+ISNULL(@Search,'')+'%')
			)
			AND (CONVERT(DATE,RatingDate) =  CASE WHEN @ByDate IS NULL THEN		CONVERT(DATE,RatingDate) ELSE @ByDate END 	)
			AND (DATEDIFF(HOUR,RatingDate ,GETUTCDATE()) <=  CASE WHEN @TimeRange IS NULL THEN	DATEDIFF(HOUR,RatingDate ,GETUTCDATE()) ELSE @TimeRange END 	)
		ORDER BY 
				CASE  WHEN @IsOrderByDesc =  1 AND @OrderBy = 'LeadDateTime' THEN   RatingDate END DESC
				,CASE  WHEN @IsOrderByDesc =  0 AND @OrderBy = 'LeadDateTime' THEN   RatingDate END ASC 
				,CASE  WHEN @IsOrderByDesc =  1 AND @OrderBy = 'Buyer' THEN   (a.FirstName+' '+ a.LastName) END DESC 
				,CASE  WHEN @IsOrderByDesc =  0 AND @OrderBy = 'Buyer' THEN   (a.FirstName+' '+ a.LastName) END ASC 
		OFFSET @PageSize * (@PageNumber- 1) ROWS
		FETCH NEXT @PageSize ROWS ONLY
		/**/

		SELECT * ,COUNT(1) OVER () AS TotalRecordCount FROM 
		(
			SELECT 
				Type	,
				Id	,
				LeadDate	,
				LeadDateTime	,
				BuyerId	,
				Buyer	,
				BuyerCompany	,
				BuyerEmail	,
				BuyerPhoneNo	,
				EmailSubject	,
				EmailBody	,
				EmailAttachment	,
				LeadId	,
				SupplierId	,
				StatusId	,
				SupplierCompanyId ,
				SupplierCompany	,
				SalesloftPeopleId	,
				RfqId	,
				RfqStatus	,
				BuyerNpsScoreCode	,
				ActionTakenBy	,
				ActionTakenDate	,
				rfq_created_on	,
				IsCommunityRfqReleased	,
				IsCommunityRfqClosed	,
				IsMfgCommunityRfq	,
				IsQMSEnabled	,
				CommunityRfqReleaseDate	,
				CommunityRfqReleaseById	,
				CommunityRfqReleaseBy	,
				CommunityRfqClosedDate	,
				CommunityRfqClosedById	,
				CommunityRfqClosedBy	,
				WantsMp	,
				IsCommunityRatingApproved	,
				CommunityRatingApprovedDeclineBy	,
    CommunityRatingApprovedDeclineDate,
	MessageId  ---- Added with M2-4525
			FROM #tmp_vision_action_tracker_community
		) a
		ORDER BY 
				CASE  WHEN @IsOrderByDesc =  1 AND @OrderBy = 'LeadDateTime' THEN   LeadDateTime END DESC
				,CASE  WHEN @IsOrderByDesc =  0 AND @OrderBy = 'LeadDateTime' THEN   LeadDateTime END ASC 
				,CASE  WHEN @IsOrderByDesc =  1 AND @OrderBy = 'Buyer' THEN   Buyer END DESC 
				,CASE  WHEN @IsOrderByDesc =  0 AND @OrderBy = 'Buyer' THEN   Buyer END ASC 
		OFFSET @PageSize * (@PageNumber- 1) ROWS
		FETCH NEXT @PageSize ROWS ONLY

	END

END
