

/*
	DECLARE @p21 dbo.tbltype_vision_actiontracker_ListOfSourcingAdvisor
	DECLARE @p22 dbo.tbltype_vision_actiontracker_ListOfStates
	DECLARE @p23 dbo.tbltype_vision_actiontracker_ListOfPlanType

	--INSERT INTO @p21 values(1483)

	EXEC [proc_get_vision_action_tracker]
	@TrackerType = 'Videos'   -- All , NewReg , LoggedIn, PressedUpgrade , LandedOnPlans , BasicOpenedRFQ ,  NewProfiles , Videos
	,@ByDate	= NULL
	,@TimeRange	= NULL
	,@Search	=''
	,@ListOfSourcingAdvisor = @p21
	,@ListOfStates = @p22
	,@ListOfPlanType = @p23
	,@PageNumber	= 1
	,@PageSize		= 25
	,@IsOrderByDesc = 'TRUE'
	,@IsMarked =  null
	,@ProfileStatus	= null --Published 1, Unpublished 2, Rejected 0, All Null


*/
CREATE PROCEDURE [dbo].[proc_get_vision_action_tracker]
(
	@TrackerType				VARCHAR(100)
	,@ByDate					DATE	=NULL
	,@TimeRange					INT		=NULL
	,@Search					VARCHAR(1000)		=NULL
	,@ListOfSourcingAdvisor		AS tbltype_vision_actiontracker_ListOfSourcingAdvisor	READONLY 
	,@ListOfStates				AS tbltype_vision_actiontracker_ListOfStates			READONLY
	,@ListOfPlanType			AS tbltype_vision_actiontracker_ListOfPlanType			READONLY
	,@PageNumber				INT		= 1
	,@PageSize					INT		= 24
	,@IsOrderByDesc				BIT		='FALSE'
	,@IsMarked					BIT = NULL
	,@ProfileStatus				INT = NULL
)
AS
BEGIN

	DROP TABLE IF EXISTS #ListOfStates
	DROP TABLE IF EXISTS #IsMarked
	DROP TABLE IF EXISTS #tmp_vision_action_tracker_supplier_communication_details
	DROP TABLE IF EXISTS #tmp_vision_action_tracker_supplier_list
	DROP TABLE IF EXISTS #tmp_vision_action_tracker_supplier_list_1
	DROP TABLE IF EXISTS #tmp_vision_action_tracker_supplier_marked
	DROP TABLE IF EXISTS #IsNewProfileApproved

	DECLARE @SourcingAdvisor INT = (SELECT * FROM @ListOfSourcingAdvisor)
	DECLARE @PlanType INT = (SELECT * FROM @ListOfPlanType)
	DECLARE @MaxMinutes INT = 0

	SELECT DISTINCT contact_id , communication_value 
	INTO #tmp_vision_action_tracker_supplier_communication_details 
	FROM mp_communication_details  (NOLOCK) WHERE communication_type_id = 1 

	CREATE TABLE #ListOfStates ( state_id INT  NULL )
	CREATE TABLE #IsMarked ( marked BIT  NULL )
	CREATE TABLE #IsNewProfileApproved (IsNewProfileApproved INT  NULL )

	CREATE TABLE #tmp_vision_action_tracker_supplier_list 
	(
		  [type]				VARCHAR(150)  NULL
		, contact_id			INT   NULL
		, recent_date			DATETIME   NULL
		, [value]				INT  NULL
		, company_id			INT  NULL
		, sourcing_advisor		INT  NULL
		, recent_date_minutes	INT   NULL
		, paid_status			INT  NULL
		, state_id				INT  NULL
		, company				VARCHAR(150)  NULL
		, contact				VARCHAR(150)  NULL
		, email					VARCHAR(150)  NULL
		, marked				BIT	NULL
		, IsNewProfileApproved 	INT NULL
		, UpgradeType			VARCHAR(150)  NULL
		, VideoLink             NVARCHAR(2000)  NULL   ---- Added with M2-4551
		, VideoLinkIdentityId       INT             NULL   ---- Added with M2-4551 mpUserProfileVideoLinks - > Id
 	)

	IF @TrackerType = 'All'
	BEGIN
		INSERT INTO #tmp_vision_action_tracker_supplier_list ([type] ,contact_id , recent_date ,[value],IsNewProfileApproved  ,UpgradeType ,  VideoLink ,VideoLinkIdentityId )
		SELECT 'New Reg' Type , contact_id , MAX(created_on) RecentDate , NULL AS Value, 3 , NULL , NULL VideoLink , NULL VideoLinkIdentityId
		FROM mp_contacts (NOLOCK)
		WHERE 
		/* M2-3322 Action Tracker - Search By Date not giving accurate result */
		CONVERT(DATE,created_on)>= '2020-09-25'
		/**/
		and is_buyer = 0 
		GROUP BY contact_id
		UNION
		SELECT 'Logged In' Type , a.contact_id , MAX(login_datetime) RecentDate , NULL AS Value, 3 , NULL , NULL VideoLink , NULL VideoLinkIdentityId
		FROM mp_user_logindetail (NOLOCK) a
		JOIN mp_contacts (NOLOCK) b ON a.contact_id = b.contact_id
		WHERE b.is_buyer = 0 
		GROUP BY a.contact_id
		UNION
		SELECT 
			'Pressed Upgrade' Type ,contact_id , MAX(activity_date) RecentDate , NULL AS Value, 3 
			, CASE WHEN activity_id = 3 THEN 'Gold' WHEN activity_id = 14 THEN 'Growth Package' ELSE NULL END , NULL VideoLink , NULL VideoLinkIdentityId
		FROM mp_track_user_activities (NOLOCK)
		/* M2-4102 Vision - Add Silver Upgrade request to Action Tracker - DB*/
		WHERE activity_id in (3,14)
		/**/
		GROUP BY contact_id ,activity_id
		UNION
		SELECT 'Landed On Plans' Type ,contact_id , MAX(created) RecentDate , NULL AS Value, 3 ,NULL , NULL VideoLink , NULL VideoLinkIdentityId
		FROM mp_gateway_subscription_tracking (NOLOCK)
		WHERE subscriptions_plan IS NOT NULL
		GROUP BY contact_id
		UNION
		SELECT 'Basic Opened RFQ' Type ,contact_id , activity_date RecentDate , CONVERT(INT,Value) AS Value, 3 ,NULL , NULL VideoLink , NULL VideoLinkIdentityId
		FROM mp_track_user_activities (NOLOCK)
		WHERE activity_id = 13  AND value <> '0'
		UNION
		SELECT 'New Profiles' Type ,CreatedBy contact_id , CreatedOn RecentDate , NULL AS Value, IsApproved ,NULL , NULL VideoLink , NULL VideoLinkIdentityId
		FROM mpCompanyPublishProfileLogs (NOLOCK) a
		WHERE PublishProfileStatusId = 232
		--UNION   ---- Added with M2-4551
		--SELECT 'Videos' Type ,  contactid contact_id, CreatedOn RecentDate , NULL AS Value, 3 ,NULL,VideoLink ,Id AS VideoLinkIdentityId
		--FROM mpUserProfileVideoLinks (NOLOCK) a
		--WHERE  a.IsDeleted = 0 ---- 0 means -> video link is not deleted from user and 1 means -> video link is not deleted from user
	    --AND ISNULL(a.IsLinkVisionAccepted,1) = 1 --- 1-> means video link approved by vision and 0 -> means video link is not approved from vision
		----TBD where clause based on timestamp
	 

	END
	ELSE IF @TrackerType = 'NewReg'
	BEGIN
		INSERT INTO #tmp_vision_action_tracker_supplier_list ([type] ,contact_id , recent_date ,[value]   , IsNewProfileApproved ,UpgradeType  )
		SELECT 'New Reg' Type , contact_id , MAX(created_on) RecentDate , NULL AS Value ,3 ,NULL
		FROM mp_contacts (NOLOCK)
		WHERE 
		/* M2-3322 Action Tracker - Search By Date not giving accurate result */
		CONVERT(DATE,created_on)>= '2020-09-25'
		/**/
		and is_buyer = 0 
		GROUP BY contact_id
	END
	ELSE IF @TrackerType = 'LoggedIn'
	BEGIN
		INSERT INTO #tmp_vision_action_tracker_supplier_list ([type] ,contact_id , recent_date ,[value]   , IsNewProfileApproved ,UpgradeType  )
		SELECT 'Logged In' Type , a.contact_id , MAX(login_datetime) RecentDate , NULL AS Value,3,NULL
		FROM mp_user_logindetail (NOLOCK) a
		JOIN mp_contacts (NOLOCK) b ON a.contact_id = b.contact_id
		WHERE b.is_buyer = 0 
		GROUP BY a.contact_id
	END
	ELSE IF @TrackerType = 'PressedUpgrade'
	BEGIN
		INSERT INTO #tmp_vision_action_tracker_supplier_list ([type] ,contact_id , recent_date ,[value]   , IsNewProfileApproved ,UpgradeType  )
		SELECT 
			'Pressed Upgrade' Type ,contact_id , MAX(activity_date) RecentDate , NULL AS Value,3
			, CASE WHEN activity_id = 3 THEN 'Gold' WHEN activity_id = 14 THEN 'Growth Package' ELSE NULL END
		FROM mp_track_user_activities (NOLOCK)
		/* M2-4102 Vision - Add Silver Upgrade request to Action Tracker - DB*/
		WHERE activity_id in (3,14)
		/**/
		GROUP BY contact_id ,activity_id
	END
	ELSE IF @TrackerType = 'LandedOnPlans'
	BEGIN
		INSERT INTO #tmp_vision_action_tracker_supplier_list ([type] ,contact_id , recent_date ,[value]   , IsNewProfileApproved ,UpgradeType  )
		SELECT 'Landed On Plans' Type ,contact_id , MAX(created) RecentDate , NULL AS Value,3,NULL
		FROM mp_gateway_subscription_tracking (NOLOCK)
		WHERE subscriptions_plan IS NOT NULL
		GROUP BY contact_id
	END
	ELSE IF @TrackerType = 'BasicOpenedRFQ'
	BEGIN
		INSERT INTO #tmp_vision_action_tracker_supplier_list ([type] ,contact_id , recent_date ,[value] , IsNewProfileApproved ,UpgradeType  )
		SELECT 'Basic Opened RFQ' Type ,contact_id , activity_date RecentDate , CONVERT(INT,Value) AS Value ,3,NULL
		FROM mp_track_user_activities (NOLOCK)
		WHERE activity_id = 13  AND value <> '0'
	END
	ELSE IF @TrackerType = 'NewProfiles'
	BEGIN
		INSERT INTO #tmp_vision_action_tracker_supplier_list ([type] ,contact_id , recent_date ,[value], IsNewProfileApproved ,UpgradeType  )
		SELECT 'New Profiles' Type ,CreatedBy contact_id , CreatedOn RecentDate , NULL AS Value, IsApproved,NULL
		FROM mpCompanyPublishProfileLogs (NOLOCK) a
		WHERE PublishProfileStatusId = 232
	END
	ELSE IF @TrackerType = 'Videos' ---- Added with M2-4551
	BEGIN

		INSERT INTO #tmp_vision_action_tracker_supplier_list ([type] ,contact_id , recent_date ,[value], IsNewProfileApproved ,UpgradeType ,VideoLink,VideoLinkIdentityId )
		SELECT 'Videos' Type ,  contactid contact_id, CreatedOn RecentDate , NULL AS Value, 3 ,NULL,VideoLink ,Id AS VideoLinkIdentityId
		FROM mpUserProfileVideoLinks (NOLOCK) a
		WHERE  a.IsDeleted = 0 ---- 0 means -> video link is not deleted from user and 1 means -> video link is not deleted from user
	    --AND ISNULL(a.IsLinkVisionAccepted,1) = 1 --- 1-> means video link approved by vision and 0 -> means video link is not approved from vision
		----TBD where clause based on timestamp
	END

	SELECT      
		c.contact_id AS MarkedById      
		,(c.first_name +' '+ c.last_name) AS MarkedBy     
		,a.contact_id AS SupplierId     
		,a.action_type AS ActionType     
		,CONVERT(VARCHAR(20),a.action_taken_on, 120)  AS MarkedOn     
		,a.is_marked AS IsMarked     
		,a.value AS Value     
	INTO #tmp_vision_action_tracker_supplier_marked
	FROM mp_vision_action_tracker_tracking a (NOLOCK)    
	JOIN    
	(     
		SELECT 
			contact_id 
			, action_type 
			, value 
			, MAX(Id) AS Id     
		FROM mp_vision_action_tracker_tracking (NOLOCK)     
		WHERE action_source = 'SupplierActionTracker'     
			AND action_taken_on BETWEEN DATEADD(d, -7, GETUTCDATE()) AND  GETUTCDATE()
		GROUP BY contact_id , action_type , value    
	) b ON a.Id = b.Id    
	JOIN mp_contacts c (NOLOCK) ON a.action_taken_by = c.contact_id

	UPDATE a SET 
		a.company_id  = b.company_id
		, a.sourcing_advisor = b.assigned_SourcingAdvisor
		, a.recent_date_minutes = DATEDIFF(MINUTE, a.recent_date ,GETUTCDATE())
		, a.state_id = b.region_id
		, a.paid_status = b.paid_status
		, a.company = b.name
		, a.contact = b.contact
		, a.email = b.email
	FROM #tmp_vision_action_tracker_supplier_list a 
	LEFT JOIN 
	(
		SELECT 
			a.contact_id 
			, a.company_id
			, b.assigned_SourcingAdvisor
			, c.region_id
			, ISNULL(account_type,83) paid_status
			, b.name
			, a.first_name +' '+a.last_name contact
			, f.email
		FROM mp_contacts  a (NOLOCK) 
		JOIN mp_companies b (NOLOCK) ON a.company_id = b.company_id
		LEFT JOIN mp_addresses c (NOLOCK) ON a.address_id = c.address_id
		LEFT JOIN mp_registered_supplier e ON e.company_id = a.company_id 
		JOIN aspnetusers f (NOLOCK) ON a.[user_id] = f.id

		WHERE a.is_buyer = 0
	) b on a.contact_id = b.contact_id

	UPDATE a
		SET a.marked = b.IsMarked
	FROM #tmp_vision_action_tracker_supplier_list a
	JOIN #tmp_vision_action_tracker_supplier_marked  b ON a.contact_id = b.SupplierId 
	AND b.ActionType = a.Type  AND ISNULL(a.value,0) = ISNULL(b.Value,0)

	SET @MaxMinutes = (SELECT MAX(recent_date_minutes) FROM #tmp_vision_action_tracker_supplier_list)

	SET @TimeRange = 
		CASE 
			WHEN @TimeRange IS NULL THEN 
				CASE 
					WHEN @MaxMinutes < 61 THEN  @MaxMinutes 
					ELSE (@MaxMinutes / 60 ) 
				END
			ELSE @TimeRange 
		END
	

	IF (SELECT COUNT(1) FROM @ListOfStates) >  0
	BEGIN
		INSERT INTO #ListOfStates
		SELECT * FROM @ListOfStates
	END
	ELSE
	BEGIN
		INSERT INTO #ListOfStates
		SELECT DISTINCT state_id FROM #tmp_vision_action_tracker_supplier_list
	END


	--SELECT * FROM #tmp_vision_action_tracker_supplier_list
	--SELECt * from #tmp_vision_action_tracker_supplier_marked
	--SELECT @TimeRange
	--SELECT * FROM #ListOfStates


	IF @ProfileStatus IS NULL
	BEGIN
		INSERT INTO #IsNewProfileApproved VALUES (0),(1),(2),(3)	
		END
	ELSE IF @ProfileStatus =0 
	BEGIN
		INSERT INTO #IsNewProfileApproved VALUES (0)
	END
		ELSE 
	IF @ProfileStatus =1 
	BEGIN
		INSERT INTO #IsNewProfileApproved VALUES (1)
	END
	ELSE IF @ProfileStatus =2
	BEGIN
		INSERT INTO #IsNewProfileApproved VALUES (2)
		--select 'JDCWF'
	END

	IF @IsMarked IS NULL
	BEGIN
		INSERT INTO #IsMarked VALUES (0),(1)
	END
	ELSE IF @IsMarked =1 
	BEGIN
		INSERT INTO #IsMarked VALUES (1)
		DELETE FROM #IsNewProfileApproved WHERE IsNewProfileApproved IN (0,1,2)
	END
	ELSE IF @IsMarked =0 
	BEGIN
		INSERT INTO #IsMarked VALUES (0)
		DELETE FROM #IsNewProfileApproved WHERE IsNewProfileApproved IN (0,1,2)
	END
	
	--SELECT @ProfileStatus '@ProfileStatus'
	--SELECT '#IsNewProfileApproved', * FROM #IsNewProfileApproved
		
	--SELECT @IsMarked, '@IsMarked'
	--SELECT '#IsMarked', * FROM #IsMarked

		
		
	SELECT  * , COUNT(1) OVER () AS TotalRecordCount 
	INTO #tmp_vision_action_tracker_supplier_list_1
	FROM #tmp_vision_action_tracker_supplier_list a
	WHERE 
	(
		CONVERT(DATE,a.recent_date) = CASE WHEN @ByDate IS NULL THEN CONVERT(DATE,a.recent_date) ELSE @ByDate END
		AND a.recent_date_minutes <= (@TimeRange * 61 )
		AND 
		(
			a.company LIKE '%'+ISNULL(@Search,'')+'%'
			OR 
			a.contact LIKE '%'+ISNULL(@Search,'')+'%'
			OR
			a.email LIKE '%'+ISNULL(@Search,'')+'%'
		)
		AND ISNULL(a.sourcing_advisor,0)  = (CASE WHEN LEN(@SourcingAdvisor) > 0 THEN @SourcingAdvisor ELSE ISNULL(a.sourcing_advisor,0) END)
		AND a.paid_status  = (CASE WHEN LEN(@PlanType) > 0 THEN @PlanType ELSE a.paid_status END)
		AND a.state_id IN (SELECT * FROM #ListOfStates)
		AND ISNULL(a.marked,0) IN (SELECT * FROM #IsMarked)
		AND 
		ISNULL(a.IsNewProfileApproved,2) IN (SELECT * FROM #IsNewProfileApproved)
	)
	ORDER BY a.recent_date_minutes  ASC  
	OFFSET @PageSize	 * (@PageNumber - 1) ROWS
	FETCH NEXT @PageSize	ROWS ONLY

	--SELECT * FROM #tmp_vision_action_tracker_supplier_list_1

	SELECT     
			CASE      
				WHEN tmp.recent_date_minutes <= 60  THEN CONVERT(VARCHAR(100),
				DATEDIFF(MINUTE, tmp.recent_date ,GETUTCDATE())) + ' mins ago'     
				WHEN tmp.recent_date_minutes <= 1440  THEN CONVERT(VARCHAR(100),
				( tmp.recent_date_minutes / 60 )) + ' hrs ago'     
				ELSE  
				CONVERT(VARCHAR(10),FORMAT( tmp.recent_date , 'd', 'en-US' )) + ' ' + 
				REVERSE(SUBSTRING(REVERSE(CONVERT(VARCHAR(20), tmp.recent_date )), 0 , 
				CHARINDEX(' ',REVERSE(CONVERT(VARCHAR(20), tmp.recent_date )))))     END  CompanyRegisteredOn    
				,tmp.type AS Type     
				,b.contact_id AS SupplierId    
				,b.first_name +' '+b.last_name AS Supplier    
				,a.company_id AS SupplierCompanyId    
				,a.name AS SupplierCompany    
				,c.email AS SupplierEmail    
				,d.communication_value AS SupplierContactNo    
				,CASE 
					WHEN tmp.Value IS NOT NULL THEN 'RFQ #'+ CONVERT(VARCHAR(50),tmp.Value) 
					WHEN tmp.paid_status = 84 THEN 'Growth Package' --'Silver' 
					WHEN tmp.paid_status = 85 THEN 'Gold' 
					WHEN tmp.paid_status = 86 THEN 'Platinum' 
					WHEN tmp.paid_status = 313 THEN 'Starter' 
					ELSE 'Basic' 
				END  AS AccountType     
				, tmp.recent_date  AS CompanyRegistered    
				,g.region_id AS StateId    
				,b.total_login_count AS SupplierLoginCount    
				,a.is_mqs_enable AS IsQMSEnabled    
				,c.id AS UserId    
				,b.SalesloftPeopleId     
				,a.assigned_sourcingadvisor AS SourcingAdvisorId    
				,b1.last_name AS SourcingAdvisor    
				,tmp.value AS RfqId    
				,u.MarkedById     
				,u.MarkedBy     
				,u.MarkedOn    
				,ISNULL(u.IsMarked,0)  AS  IsMarked    
				,CASE 
				WHEN tmp.paid_status = 84 THEN 'Silver' 
				WHEN tmp.paid_status = 85 THEN 'Gold' 
				WHEN tmp.paid_status = 86 THEN 'Platinum' 
				WHEN tmp.paid_status = 313 THEN 'Starter' 
				ELSE 'Basic' 
				END SupplierType    
				,CASE       
				WHEN        
					(        
						CASE 
							WHEN LEN(COALESCE( g.address1 , '')) > 0 THEN 1 ELSE 0 END        
							+ CASE WHEN LEN(COALESCE( a.description,'')) > 0 THEN 1 ELSE 0 END        
							+ CASE WHEN (COALESCE(r.company_id,'0')) > 0 THEN 1 ELSE 0 
						END         
					) = 3 THEN CAST(1 AS BIT)      
				ELSE CAST(0 AS BIT)     
				END AS IsProfileCompleted    
				, s.IsApproved AS  NewProfilesIsApproved    
				,(CASE WHEN s.IsApproved = 1 THEN s.ApprovedBy ELSE NULL END) AS  NewProfilesApprovedById    
				,(CASE WHEN s.IsApproved = 1 THEN t.first_name +' '+ t.last_name ELSE NULL END) AS  NewProfilesApprovedBy    
				,(CASE WHEN s.IsApproved = 1 THEN s.ApprovedDate  ELSE NULL END) AS  NewProfilesApprovedDate    
				,(CASE WHEN s.IsApproved = 0 THEN s.ApprovedBy ELSE NULL END) AS  NewProfilesRejectedById    
				,(CASE WHEN s.IsApproved = 0 THEN t.first_name +' '+ t.last_name ELSE NULL END) AS  NewProfilesRejectedBy    
				,(CASE WHEN s.IsApproved = 0 THEN s.ApprovedDate  ELSE NULL END) AS  NewProfilesRejectedDate    
				,tmp.TotalRecordCount 
				,tmp.UpgradeType
					--,mpCompanyPublishProfileLogs.isapproved
				,tmp.VideoLink
				,tmp.VideoLinkIdentityId
				,(CASE WHEN vl.IsLinkVisionAccepted = 1 THEN vl.ModifiedBy ELSE NULL END) AS  VideosApprovedById    
				,(CASE WHEN vl.IsLinkVisionAccepted = 1 THEN t1.first_name +' '+ t1.last_name ELSE NULL END) AS  VideosApprovedBy    
				,(CASE WHEN vl.IsLinkVisionAccepted = 1 THEN vl.ModifiedOn  ELSE NULL END) AS  VideosApprovedDate    
				,(CASE WHEN vl.IsLinkVisionAccepted = 0 THEN vl.ModifiedBy ELSE NULL END) AS  VideosRejectedById    
				,(CASE WHEN vl.IsLinkVisionAccepted = 0 THEN t1.first_name +' '+ t1.last_name ELSE NULL END) AS  VideosRejectedBy    
				,(CASE WHEN vl.IsLinkVisionAccepted = 0 THEN vl.ModifiedOn  ELSE NULL END) AS  VideosRejectedDate
				,vl.IsLinkVisionAccepted
				,CASE WHEN vl.IsDeleted IS NULL THEN CAST('false' AS BIT) WHEN vl.IsDeleted  = 0 THEN CAST('false' AS BIT) WHEN vl.IsDeleted  = 1 THEN CAST('true' AS BIT)   end  IsVideoLinkDeleted
		FROM 
		#tmp_vision_action_tracker_supplier_list_1 tmp
		JOIN mp_companies a (NOLOCK) ON tmp.company_id = a.company_id   
		JOIN mp_contacts b (NOLOCK) ON 
			tmp.company_id = b.company_id 
			AND tmp.contact_id = b.contact_id 
			AND tmp.company_id <> 0 
			AND tmp.contact_id <> 0   
		LEFT JOIN mp_contacts b1 (NOLOCK) ON a.assigned_sourcingadvisor = b1.contact_id    
		JOIN aspnetusers c (NOLOCK) ON c.id = b.user_id  
		LEFT JOIN #tmp_vision_action_tracker_supplier_communication_details d (NOLOCK) ON b.contact_id = d.contact_id    
		LEFT JOIN mp_addresses    g (NOLOCK) ON b.address_id = g.address_id    
		LEFT JOIN    
		(    
			SELECT      
				c.contact_id AS MarkedById      
				,(c.first_name +' '+ c.last_name) AS MarkedBy     
				,a.contact_id AS SupplierId     
				,a.action_type AS ActionType     
				,CONVERT(VARCHAR(20),a.action_taken_on, 120)  AS MarkedOn     
				,a.is_marked AS IsMarked     
				,a.value AS Value     
			FROM mp_vision_action_tracker_tracking a (NOLOCK)    
			JOIN    
			(     
				SELECT 
					contact_id 
					, action_type 
					, value 
					, MAX(Id) AS Id     
				FROM mp_vision_action_tracker_tracking (NOLOCK)     
				WHERE action_source = 'SupplierActionTracker'     
					AND action_taken_on BETWEEN DATEADD(d, -7, GETUTCDATE()) AND  GETUTCDATE()
				GROUP BY contact_id , action_type , value    
			) b ON a.Id = b.Id    
			JOIN mp_contacts c (NOLOCK) ON a.action_taken_by = c.contact_id   
		) u ON b.contact_id = u.SupplierId AND u.ActionType = tmp.type  AND ISNULL(tmp.value,0) = ISNULL(u.Value,0)   
		LEFT JOIN mp_special_files (NOLOCK) ON mp_special_files.cont_id = b.contact_id AND mp_special_files.FILETYPE_ID = 6   
		LEFT JOIN       
		(       
			SELECT company_id FROM mp_company_processes (NOLOCK)        
			UNION       
			SELECT company_id FROM mp_gateway_subscription_company_processes (NOLOCK)             
		) r ON a.company_Id = r.company_id   
		LEFT JOIN mpCompanyPublishProfileLogs (NOLOCK) s ON tmp.contact_id = s.CreatedBy AND tmp.recent_date = s.CreatedOn   
		LEFT JOIN mp_contacts t (NOLOCK) ON s.ApprovedBy  = t.contact_id   
		LEFT JOIN mpUserProfileVideoLinks (NOLOCK) vl ON  vl.id = tmp.VideoLinkIdentityId
	    LEFT JOIN mp_contacts t1 (NOLOCK) ON  t1.contact_id = vl.ModifiedBy  
		WHERE     
		a.is_active = 1    AND b.is_active = 1
		ORDER BY tmp.recent_date  DESC   

		DROP TABLE IF EXISTS #ListOfStates
		DROP TABLE IF EXISTS #IsMarked
		DROP TABLE IF EXISTS #tmp_vision_action_tracker_supplier_communication_details
		DROP TABLE IF EXISTS #tmp_vision_action_tracker_supplier_list
		DROP TABLE IF EXISTS #tmp_vision_action_tracker_supplier_list_1
		DROP TABLE IF EXISTS #tmp_vision_action_tracker_supplier_marked
		DROP TABLE IF EXISTS #IsNewProfileApproved
	END
