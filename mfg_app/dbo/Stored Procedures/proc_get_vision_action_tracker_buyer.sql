

-------------------------------------------------------------------------------------------------------------------

/*

select * from mp_lead order by 1 desc

update mp_lead set status_id = null where lead_source_id = 13

exec proc_get_vision_action_tracker_buyer 
@TrackerType=N'DirectoryMessage' -- All ,NewReg , LoggedIn , DirectoryMessage , Unval 
,@ByDate=default
,@TimeRange=default
,@SourcingAdvisorId=0
,@Search=default
,@PageNumber=1
,@PageSize=24
,@IsOrderByDesc=1
,@OrderBy=default
,@IsMarked=default
,@IsCommunityAllRfqsReleased=0
,@IsCommunityAllRfqsNotReleased=0
,@IsCommunityAllRfqsClosed=0


*/
CREATE PROCEDURE [dbo].[proc_get_vision_action_tracker_buyer]
(
	@TrackerType				VARCHAR(100)
	,@ByDate					DATE	=NULL
	,@TimeRange					INT		=NULL
	,@SourcingAdvisorId			INT		=NULL
	,@Search					VARCHAR(1000)		=NULL
	,@PageNumber				INT		= 1
	,@PageSize					INT		= 24
	,@IsOrderByDesc				BIT		='FALSE'
	,@OrderBy					VARCHAR(100)	= NULL
	,@IsMarked					BIT = NULL
	,@IsCommunityAllRfqsReleased	BIT = NULL
	,@IsCommunityAllRfqsNotReleased	BIT = NULL
	,@IsCommunityAllRfqsClosed		BIT = NULL	
)
AS
BEGIN

	SET NOCOUNT ON

	/*
		-- Created	:	May 29, 2020
		--			:	M2-2906 Vision - Action Tracker Page - DB
	*/

	DECLARE @ExecSQLQuery	NVARCHAR(MAX) = ''
	DECLARE @SQLQuery0		VARCHAR(MAX) = ''
	DECLARE @SQLQuery		VARCHAR(MAX) = ''
	DECLARE @DateQuery		VARCHAR(MAX) = ''
	DECLARE @WhereQuery		VARCHAR(MAX) = ''
	DECLARE @OrderQuery		VARCHAR(MAX) = ''
	

	IF (@OrderBy IS NULL OR  @OrderBy = '' )
		SET @OrderBy  = 'LeadDateTime'

	SET @WhereQuery = ''
		+	CASE WHEN @ByDate IS NULL			THEN '' ELSE  ' AND CONVERT(DATE,a.LeadDateTime) = '''+CONVERT(VARCHAR(10),@ByDate)+ '''' END
		+	CASE WHEN @SourcingAdvisorId = 0	THEN '' ELSE  ' AND a.SourcingAdvisorId = '''+CONVERT(VARCHAR(50),@SourcingAdvisorId)+ '''' END
		+	CASE WHEN @TimeRange IS NULL		THEN '' ELSE  ' AND DATEDIFF(HOUR,a.LeadDateTime,GETUTCDATE()) <= '+CONVERT(VARCHAR(20),@TimeRange)+ '' END
		+	CASE WHEN @Search = '' OR @Search  IS NULL THEN '' ELSE  
			' AND 
				(
					(a.BuyerCompany LIKE ''%'+ISNULL(@Search,'')+'%'')
					OR
					(a.Buyer) LIKE  ''%'+ISNULL(@Search,'''')+'%''
					OR
					(a.BuyerEmail LIKE  ''%'+ISNULL(@Search,'')+'%'')
				)
		
			 ' END 
		/* M2-3329 Vision - Add a filter for the checked and unchecked items in action tracker - DB*/
		+	CASE WHEN @IsMarked IS NULL		THEN '' 
				 WHEN @IsMarked = 1			THEN ' AND A.IsMarked = 1 '
				 WHEN @IsMarked = 0			THEN ' AND A.IsMarked = 0 '
			END
		/**/



		 SET @OrderQuery = 
		 ' ORDER BY ' 
		 + CASE 
				WHEN @OrderBy = 'LeadDateTime' THEN ' a.LeadDateTime ' + CASE WHEN @IsOrderByDesc = 1 THEN ' DESC ' ELSE ' ASC ' END 
				WHEN @OrderBy = 'Buyer' THEN ' a.Buyer ' + CASE WHEN @IsOrderByDesc = 1 THEN ' DESC ' ELSE ' ASC ' END 
		   END
	     +'OFFSET '+CONVERT(VARCHAR(100),@PageSize)+' * ('+CONVERT(VARCHAR(100),@PageNumber)+' - 1) ROWS
			FETCH NEXT '+CONVERT(VARCHAR(100),@PageSize)+' ROWS ONLY'
	
	
	SET @SQLQuery0 = 
	
	'
		SELECT * ,COUNT(1) OVER () AS TotalRecordCount
		FROM
		(
			SELECT 
				
				DISTINCT
				a.Type
				,a.IsBuyer
				,a.UnVal
				,CASE 
					WHEN DATEDIFF(MINUTE,ISNULL(i.rfq_created_on,a.RecentDate) ,GETUTCDATE()) < 60		THEN CONVERT(VARCHAR(100),DATEDIFF(MINUTE,ISNULL(i.rfq_created_on,a.RecentDate) ,GETUTCDATE())) + '' mins ago''
					WHEN DATEDIFF(HOUR,ISNULL(i.rfq_created_on,a.RecentDate) ,GETUTCDATE()) < 24	THEN CONVERT(VARCHAR(100),DATEDIFF(HOUR,ISNULL(i.rfq_created_on,a.RecentDate) ,GETUTCDATE())) + '' hrs ago''
					ELSE  CONVERT(VARCHAR(10),FORMAT(ISNULL(i.rfq_created_on,a.RecentDate) , ''d'', ''en-US'' )) + '' '' + REVERSE(SUBSTRING(REVERSE(CONVERT(VARCHAR(20),ISNULL(i.rfq_created_on,a.RecentDate) )), 0 , CHARINDEX('' '',REVERSE(CONVERT(VARCHAR(20),ISNULL(i.rfq_created_on,a.RecentDate) )))))
				 END						AS LeadDate 
				,ISNULL(i.rfq_created_on,a.RecentDate) 				AS LeadDateTime
				,COALESCE(b.contact_id,r.contact_id,0)		AS BuyerId
				,COALESCE((b.first_name +'' ''+ b.last_name), (g.first_name +'' ''+ g.last_name) ,'''')  AS Buyer
				,COALESCE(b.company_id,s.company_id,NULL)				AS BuyerCompanyId
				,COALESCE(d.name,g.company,'''')	AS BuyerCompany
				,COALESCE(c.email,g.email,'''')	AS BuyerEmail
				,COALESCE(h.communication_value,g.phoneno,'''') AS BuyerPhoneNo
				,(CASE 
					WHEN i.rfq_id  IS NOT NULL THEN ''RFQ #''+ CONVERT(VARCHAR(150), i.rfq_id) 
					ELSE COALESCE(g.email_subject,'''')  
				  END ) AS EmailSubject
				,(CASE 
					WHEN i.rfq_id  IS NOT NULL THEN p.description 
					ELSE COALESCE(g.email_message,'''')  
				 END ) AS EmailBody
				,(
					CASE 
						WHEN j.rfq_id IS NOT NULL THEN CAST(''true'' AS BIT)  
						WHEN l1.file_id IS NOT NULL THEN CAST(''true'' AS BIT)  
						ELSE CAST(''false'' AS BIT) 
					END  
				)    AS EmailAttachment
				,e.lead_id					AS LeadId
				,g.lead_email_message_id	AS LeadEmailId
				,l.message_id				AS MessageId
				,(SELECT TOP 1 contact_id FROM mp_contacts (NOLOCK) WHERE company_id = e.company_id  AND is_admin = 1)	AS SupplierId
				,e.status_id				AS StatusId
				,e.company_id				AS SupplierCompanyId
				,m.name						AS SupplierCompany
				,COALESCE(b.first_name , g.first_name  , '''')	AS BuyerFirstName
				,COALESCE(b.last_name , g.last_name, '''')		AS BuyerLastName
				,b.SalesloftPeopleId		AS SalesloftPeopleId	
				,i.rfq_id				AS RfqId
				,p.description			AS RfqStatus
				,o.no_of_stars				AS BuyerNpsScoreCode
    	 		,COALESCE(n.contact_id,t.contact_id)				AS SourcingAdvisorId
				,COALESCE(n.last_name,t.last_name)				AS SourcingAdvisor
				,(q.first_name +'' ''+ q.last_name)  AS ActionTakenBy
				,e.ModifiedOn				AS ActionTakenDate
				,u.MarkedById 
				,u.MarkedBy 
				,u.MarkedOn
				,ISNULL(u.IsMarked,0)  AS  IsMarked
				,i.rfq_created_on  rfq_created_on 
				,NULL IsCommunityRfqReleased
				,NULL IsCommunityRfqClosed
				,NULL IsMfgCommunityRfq
				,NULL as   IsQMSEnabled
				,NULL CommunityRfqReleaseDate
				,NULL AS CommunityRfqReleaseById
				,NULL AS CommunityRfqReleaseBy
				,NULL CommunityRfqClosedDate  
				,NULL AS CommunityRfqClosedById
				,NULL AS CommunityRfqClosedBy
				,CAST(COALESCE(b.Is_Validated_Buyer, 0) AS bit) AS IsValidated
			FROM
	'
	/** M2-3803 Vision - Action Tracker - Add Validated icon for buyers-DB 
	added last line - ,CAST(COALESCE(b.Is_Validated_Buyer, 0) AS bit) AS IsValidated
	**/
	
	
	SET @SQLQuery = 
	'
			(
			' +
					CASE  
						WHEN @TrackerType = 'NewReg' THEN 
							'
							SELECT ''New Reg'' Type ,contact_id AS Id ,MAX(created_on) AS RecentDate  ,1 AS IsBuyer , 0 AS UnVal
							FROM mp_contacts (NOLOCK)
							WHERE 
							/* M2-3322 Action Tracker - Search By Date not giving accurate result */
							convert(date,created_on)>= ''2020-09-25''
							/**/
							and is_buyer = 1
							GROUP BY contact_id 
							'
						WHEN @TrackerType = 'LoggedIn' THEN 
							'
							SELECT ''Logged In'' AS Type ,a.contact_id AS Id ,MAX(login_datetime) AS RecentDate  ,1 AS IsBuyer  , 0 AS UnVal
							FROM mp_user_logindetail	a (NOLOCK)
							JOIN mp_contacts			b (NOLOCK) ON a.contact_id = b.contact_id 
								AND b.contact_id <>0 AND b.is_buyer =1 
							GROUP BY a.contact_id
							'
						WHEN @TrackerType = 'DirectoryMessage' THEN 
							'
							SELECT ''Directory Message'' AS Type ,a.lead_id Id ,a.lead_date RecentDate ,0 AS IsBuyer  , 0 AS UnVal
							FROM mp_lead  (NOLOCK) a
							JOIN mp_lead_email_mappings (NOLOCK) b ON a.lead_id = b.lead_id
							WHERE a.lead_source_id in (6,13) AND  ISNULL(a.status_id , 10)  IN (0,1,3,10) AND a.company_id NOT IN  (1767788,1775055)
							'
						WHEN @TrackerType = 'Unval' THEN 
							'
							SELECT ''Unval'' AS Type ,a.contact_id Id ,MAX(activity_date) AS RecentDate  ,1 AS IsBuyer  , 1 AS UnVal
							FROM mp_track_user_activities  (NOLOCK) a 
							JOIN mp_contacts (NOLOCK) b ON a.contact_id = b.contact_id AND b.is_validated_buyer = 0	
							WHERE activity_id = 12
							GROUP BY a.contact_id
							'
						WHEN  @TrackerType = 'All' THEN 
							'
							SELECT ''New Reg'' Type ,contact_id AS Id ,MAX(created_on) AS RecentDate  ,1 AS IsBuyer , 0 AS UnVal
							FROM mp_contacts (NOLOCK)
							WHERE 
							/* M2-3322 Action Tracker - Search By Date not giving accurate result */
							convert(date,created_on)>= ''2020-09-25''
							/**/
							and is_buyer = 1
							GROUP BY contact_id 
							UNION
							SELECT ''Unval'' AS Type ,a.contact_id Id ,MAX(activity_date) AS RecentDate  ,1 AS IsBuyer  , 1 AS UnVal
							FROM mp_track_user_activities  (NOLOCK) a 
							JOIN mp_contacts (NOLOCK) b ON a.contact_id = b.contact_id AND b.is_validated_buyer = 0	
							WHERE activity_id = 12
							GROUP BY a.contact_id
							UNION
							SELECT ''Logged In'' AS Type ,a.contact_id AS Id ,MAX(login_datetime) AS RecentDate  ,1 AS IsBuyer  , 0 AS UnVal
							FROM mp_user_logindetail	a (NOLOCK)
							JOIN mp_contacts			b (NOLOCK) ON a.contact_id = b.contact_id 
								AND b.contact_id <>0 AND b.is_buyer =1 
							GROUP BY a.contact_id
							UNION
							SELECT ''Directory Message'' AS Type  ,a.lead_id Id ,a.lead_date RecentDate ,0 AS IsBuyer  , 0 AS UnVal
							FROM mp_lead  (NOLOCK) a
							JOIN mp_lead_email_mappings (NOLOCK) b ON a.lead_id = b.lead_id
							WHERE a.lead_source_id  in (6,13) AND  ISNULL(a.status_id , 10)  IN  (0,1,3,10) AND a.company_id NOT IN  (1767788,1775055)
							'
						ELSE ''
					END

				+'	
				
			) a
			LEFT JOIN mp_contacts				b (NOLOCK) ON a.Id = b.contact_id AND  a.IsBuyer = 1
			LEFT JOIN aspnetusers				c (NOLOCK) ON b.user_id = c.id
			LEFT JOIN mp_companies				d (NOLOCK) ON b.company_id = d.company_id  AND b.contact_id <>0 
			LEFT JOIN mp_lead					e (NOLOCK) ON a.Id = e.lead_id AND a.IsBuyer = 0  AND A.Type = ''Directory Message''
			LEFT JOIN mp_lead_email_mappings	f (NOLOCK) ON e.lead_id = f.lead_id AND  ISNULL(e.status_id , 10)  IN (0,1,3,10)
			LEFT JOIN mp_lead_emails			g (NOLOCK) ON f.lead_email_message_id = g.lead_email_message_id
			LEFT JOIN mp_communication_details  h (NOLOCK) ON b.contact_id = h.contact_id AND h.communication_type_id = 1 
			LEFT JOIN mp_rfq					i (NOLOCK) ON b.contact_id = i.contact_id AND a.UnVal = 1 AND i.rfq_status_id IN  (1,2)
			LEFT JOIN 
			(
				SELECT DISTINCT a.rfq_id 
				FROM mp_rfq_parts	a (NOLOCK)
				JOIN mp_rfq			b (NOLOCK) ON a.rfq_id = b.rfq_id AND b.rfq_status_id IN  (1,2)
			) j ON i.rfq_id = j.rfq_id 
			LEFT JOIN 
			( 
				SELECT id, lead_id , message_id , ROW_NUMBER() OVER(PARTITION BY lead_id ORDER BY lead_id , message_id) Rn 
				FROM mp_lead_message_mapping (NOLOCK)	
			) k  ON e.lead_id = k.lead_id AND (k.Rn = 1 OR k.Rn IS NULL)
			LEFT JOIN mp_messages				l  (NOLOCK)	ON k.message_id = l.message_id
			LEFT JOIN mp_message_file			l1  (NOLOCK)	ON k.message_id = l1.message_id
			LEFT JOIN mp_companies				m  (NOLOCK)	ON e.company_id = m.company_id
			LEFT JOIN mp_contacts				n  (NOLOCK)	ON d.assigned_sourcingadvisor = n.contact_id 
			LEFT JOIN mp_star_rating			o  (NOLOCK)	ON d.company_id = o.company_id 
			LEFT JOIN mp_mst_rfq_buyerstatus	p  (NOLOCK)	ON i.rfq_status_id = p.rfq_buyerstatus_id 
			LEFT JOIN mp_contacts				q  (NOLOCK)	ON e.ModifiedBy = q.contact_id 
			LEFT JOIN mp_contacts				r (NOLOCK) ON  e.lead_from_contact = r.contact_id  AND e.lead_from_contact <> 0 
			LEFT JOIN mp_companies				s (NOLOCK) ON  r.company_id = s.company_id  
			LEFT JOIN mp_contacts				t (NOLOCK) ON  s.assigned_sourcingadvisor = t.contact_id 
			LEFT JOIN 
			(
				SELECT 
					c.contact_id AS MarkedById 
					,(c.first_name +'' ''+ c.last_name) AS MarkedBy
					,a.contact_id AS BuyerId
					,a.action_type AS ActionType
					,CONVERT(VARCHAR(20),a.action_taken_on, 120) AS MarkedOn
					,a.is_marked AS IsMarked
					,a.value AS Value 					
				FROM mp_vision_action_tracker_tracking a (NOLOCK)
				JOIN
				(
					SELECT contact_id , action_type , value , MAX(Id) AS Id
					FROM mp_vision_action_tracker_tracking (NOLOCK)
					WHERE action_source = ''BuyerActionTracker''
					AND action_taken_on BETWEEN DATEADD(d, -7, GETUTCDATE()) AND  GETUTCDATE()
					GROUP BY contact_id , action_type , value
				) b ON a.Id = b.Id
				JOIN mp_contacts c (NOLOCK) ON a.action_taken_by = c.contact_id
			) u ON ISNULL(b.contact_id,ISNULL(r.contact_id,0)) = u.BuyerId AND u.ActionType = a.Type AND ISNULL(i.rfq_id,0) = ISNULL(u.Value,0)
		) a
		WHERE a.IsBuyer IN ( 0 ,1) 
	'
	+ @WhereQuery
	+ @OrderQuery


	
	SET @ExecSQLQuery = @SQLQuery0 + @SQLQuery
	--SELECT LEN(@SQLQuery) ,  LEN(@ExecSQLQuery) , @WhereQuery  ,@OrderQuery ,@ExecSQLQuery ,@SQLQuery
	--PRINT @ExecSQLQuery
	EXECUTE SP_EXECUTESQL  @ExecSQLQuery 


	--SELECT @ExecSQLQuery


END
