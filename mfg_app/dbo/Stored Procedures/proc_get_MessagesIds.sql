

/*


DECLARE @RC INT  
DECLARE @UnRC INT  
DECLARE @UnRCBuyer INT  
DECLARE @UnRCRfq INT  

EXEC [proc_get_MessagesIds]
	@ContactId	= 1368471
	,@RfqId		= 1162279
	,@TypeId	= 0  -- 0: All , 1:Read , 2:UnRead , 3:Sent 
	,@PageNo	= 1
	,@PageSize	= 25
	,@TotalRec	= @RC OUTPUT
	,@TotalUnRec	= @UnRC OUTPUT
	,@TotalUnReadBuyerSupplier	= @UnRCBuyer OUTPUT
	,@TotalUnReadRfq	= @UnRCRfq OUTPUT
	,@IsNotificationOrMessage = 2	-- 0: All , 1: Notification , 2: Message
	,@IsBuyerSupplierOrRfq	 = 0	-- 0: All , 1: Buyer , 2: Rfq , 3: Supplier 
	,@ArchivedMessages = 0
	,@SentMessages = 0
	,@Search = ''
SELECT  @RC AS TotalRecords , @UnRC AS TotalUnreadRecords , @UnRCBuyer TotalUnreadBuyerSupplierRecords , @UnRCRfq TotalUnreadRfqRecords

*/
CREATE PROCEDURE [dbo].[proc_get_MessagesIds]
(
	@ContactId	INT 
	,@RfqId		INT = 0
	,@TypeId	INT  -- 0: All , 1:Read , 2:UnRead , 3:Sent 
	,@PageNo	INT = 1
	,@PageSize	INT = 25
	,@TotalRec  INT =0 OUTPUT  
	,@TotalUnRec  INT =0 OUTPUT 
	,@TotalUnReadBuyerSupplier  INT =0 OUTPUT  
	,@TotalUnReadRfq  INT =0 OUTPUT 
	,@IsNotificationOrMessage	INT =0	-- 1: Notification , 2: Message
	,@IsBuyerSupplierOrRfq		INT	 =0		-- 1: Buyer , 2: Rfq , 3: Supplier
	,@Search					VARCHAR(500) = ''
	,@ArchivedMessages BIT = 0
	,@SentMessages BIT = 0
)
AS
BEGIN

	-- M2-3430 Global Message optimization - Convert into the SP - DB
	SET NOCOUNT ON

	DROP TABLE IF EXISTS #tmp_proc_get_MessagesIds_MessagesAllData
	DROP TABLE IF EXISTS #tmp_proc_get_MessagesIds_Messages
	DROP TABLE IF EXISTS #tmp_proc_get_MessagesIds_MessageThreads
	DROP TABLE IF EXISTS #tmp_proc_get_MessagesIds_MessageTypeIds
	DROP TABLE IF EXISTS #tmp_proc_get_MessagesIds_IsBuyerSupplier
	DROP TABLE IF EXISTS #tmp_proc_get_MessagesIds_ArchivedMessageIds
	DROP TABLE IF EXISTS #tmp_proc_get_MessagesIds_SentMessageIds

	CREATE TABLE #tmp_proc_get_MessagesIds_MessagesAllData 
	(
		MessageId		INT
		,MessageDate	DATETIME
		,MessageRead	BIT
		,MessageSent	BIT
		/* M2-4088 Buyer and Supplier - Split Messages and Notifications - DB */
		,MessageSubject VARCHAR(1000) NULL
		,RfqId			INT NULL
		,FromContactId	INT NULL
		,ToContactId	INT NULL
		/**/
		/* M2-4218 DB - Buyer and M - Add Archived messages tab under messages Tab*/
		,IsArchived		BIT
		/**/
	)
	
	CREATE TABLE #tmp_proc_get_MessagesIds_Messages 
	(
		MessageId		INT
		,MessageDate	DATETIME
		,MessageRead	BIT
		,MessageSent	BIT
		/* M2-4088 Buyer and Supplier - Split Messages and Notifications - DB */
		,MessageSubject VARCHAR(1000) NULL
		,RfqId			INT NULL
		,FromContactId	INT NULL
		,ToContactId	INT NULL  --M2-4902
		/**/

	)

	CREATE TABLE #tmp_proc_get_MessagesIds_MessageThreads
	(
		MessageId		INT
		,Rn				INT
	)

	SET @TotalRec =0
	SET @TotalUnRec  =0
	SET @TotalUnReadBuyerSupplier  =0
	SET @TotalUnReadRfq  =0

	/* M2-4218 DB - Buyer and M - Add Archived messages tab under messages Tab*/
	CREATE TABLE #tmp_proc_get_MessagesIds_ArchivedMessageIds
	(
		MessageIds INT
	)

	INSERT INTO #tmp_proc_get_MessagesIds_ArchivedMessageIds (MessageIds)
	SELECT MessageId FROM mpArchivedMessages (NOLOCK) WHERE ArchievedBy = @ContactId 

	/**/

	/* M2-4220 DB - Add sent tab in the users messages list b*/
	CREATE TABLE #tmp_proc_get_MessagesIds_SentMessageIds
	(
		MessageIds INT
	)

	INSERT INTO #tmp_proc_get_MessagesIds_SentMessageIds (MessageIds)
	SELECT message_id FROM mp_messages (NOLOCK) a WHERE from_cont = @ContactId

	/**/

	--SELECT * FROM #tmp_proc_get_MessagesIds_SentMessageIds ORDER BY MessageIds DESC
		
   	/* M2-4088 Buyer and Supplier - Split Messages and Notifications - DB */
	IF ISNULL(@IsNotificationOrMessage,0) > 0 AND ISNULL(@RfqId ,0) = 0
	BEGIN
	 
		CREATE TABLE #tmp_proc_get_MessagesIds_MessageTypeIds
		(
			Ids INT
		)
		CREATE TABLE #tmp_proc_get_MessagesIds_IsBuyerSupplier
		(
			Ids INT
		)


		IF @IsNotificationOrMessage = 1
		BEGIN
			INSERT INTO #tmp_proc_get_MessagesIds_MessageTypeIds (Ids)
			VALUES (1),(7),(8),(31),(42),(202),(203),(204),(205),(206),(208),(209),(210),(211),(212),(213),(214),(218),(221),(222),(223),(224),(226),(227),(228),(231),(232),(235),(237),(238),(243),(244),(245),(247),(248),(249),(250),(251) 
		END
		ELSE IF @IsNotificationOrMessage = 2
		BEGIN
			INSERT INTO #tmp_proc_get_MessagesIds_MessageTypeIds (Ids)
			VALUES (5),(40),(220),(225),(230),(217),(242),(233) 
		END

		IF @IsBuyerSupplierOrRfq IN (0,2)
		BEGIN
			INSERT INTO #tmp_proc_get_MessagesIds_IsBuyerSupplier (Ids)
			VALUES (0),(1)
			
		END
		ELSE IF @IsBuyerSupplierOrRfq IN (1)
		BEGIN
			INSERT INTO #tmp_proc_get_MessagesIds_IsBuyerSupplier (Ids)
			VALUES (1)

		END
		ELSE IF @IsBuyerSupplierOrRfq  IN (3)
		BEGIN
			INSERT INTO #tmp_proc_get_MessagesIds_IsBuyerSupplier (Ids)
			VALUES (0)
		END


		INSERT INTO #tmp_proc_get_MessagesIds_MessagesAllData (MessageId,MessageDate,MessageRead,MessageSent,MessageSubject,RfqId,FromContactId,ToContactId,IsArchived)
		SELECT 
			a.message_id AS MessageId 
			,a.message_date AS MessageDate
			,a.message_read AS MessageRead
			,a.message_sent AS MessageSent
			,a.message_subject  AS MessageSubject
			,a.rfq_id AS RfqId
			,a.from_cont AS FromContactId
			,a.to_cont AS ToContactId
			,a.trash AS IsArchived
		FROM mp_messages (NOLOCK) a
		JOIN mp_mst_message_types (NOLOCK) b ON a.message_type_id = b.message_type_id 
		WHERE
			ISNULL(IsNotification,0) = (CASE WHEN @IsNotificationOrMessage = 1 THEN 1 ELSE 0 END)	
			AND (a.to_cont = @ContactId OR a.from_cont = @ContactId )
			AND a.trash = 0
			AND a.message_type_id IS NOT NULL
			AND a.message_subject IS NOT NULL
			AND a.message_type_id  IN (SELECT * FROM #tmp_proc_get_MessagesIds_MessageTypeIds)

		--SELECT * FROM #tmp_proc_get_MessagesIds_MessagesAllData  order by MessageSubject ,MessageId
		--SELECT * FROM #tmp_proc_get_MessagesIds_ArchivedMessageIds


		/* Nov 22, 2021 : Beau Martin  - M user jeremy@sumrallmanufacturing.com sees 2 new messages on dashboard tile, yet no unread messages were found on messages page.*/
		IF @IsNotificationOrMessage = 1 
			DELETE FROM #tmp_proc_get_MessagesIds_MessagesAllData WHERE FromContactId = @ContactId
		/**/

		--SELECT * FROM #tmp_proc_get_MessagesIds_MessagesAllData

		INSERT INTO #tmp_proc_get_MessagesIds_Messages (MessageId,MessageDate,MessageRead,MessageSent,MessageSubject,RfqId,FromContactId,ToContactId)
		SELECT MessageId,MessageDate,MessageRead,MessageSent,MessageSubject,RfqId,FromContactId,ToContactId
		FROM #tmp_proc_get_MessagesIds_MessagesAllData a
		LEFT JOIN (SELECT contact_id , is_buyer FROM mp_contacts (NOLOCK)) c ON a.FromContactId = c.contact_id
		LEFT JOIN #tmp_proc_get_MessagesIds_ArchivedMessageIds (NOLOCK) c1 ON a.MessageId = c1.MessageIds
		LEFT JOIN #tmp_proc_get_MessagesIds_SentMessageIds (NOLOCK) d1 ON a.MessageId = d1.MessageIds
		WHERE
			ISNULL(c.is_buyer,0) IN (SELECT * FROM #tmp_proc_get_MessagesIds_IsBuyerSupplier)
			AND ISNULL(a.RfqId,0) >= 
				(
					CASE 
						WHEN ISNULL(@IsBuyerSupplierOrRfq,0) = 0 THEN 0 
						WHEN ISNULL(@IsBuyerSupplierOrRfq,0) = 1 THEN 0 
						WHEN ISNULL(@IsBuyerSupplierOrRfq,0) = 2 THEN 1 
						WHEN ISNULL(@IsBuyerSupplierOrRfq,0) = 3 THEN 0 
					END
				) 
			/* M2-4218 DB - Buyer and M - Add Archived messages tab under messages Tab*/
			AND ISNULL(c1.MessageIds,0)  = 
			(
				CASE 
					WHEN @ArchivedMessages = 1 THEN c1.MessageIds
					ELSE 0
				END
			)
			/**/
			/* M2-4220 DB - Add sent tab in the users messages list  */
			AND a.MessageId  = 
			(
				CASE 
					WHEN @SentMessages = 1 THEN d1.MessageIds
					ELSE a.MessageId
				END
			)
			/**/
		
		--SELECT * FROM #tmp_proc_get_MessagesIds_Messages order by MessageSubject ,MessageId 
		
		IF @IsNotificationOrMessage = 1
			INSERT INTO #tmp_proc_get_MessagesIds_MessageThreads
			SELECT MessageId , ROW_NUMBER() OVER (PARTITION BY MessageSubject, FromContactId ORDER BY MessageSubject  , MessageId DESC)  Rn
			FROM #tmp_proc_get_MessagesIds_Messages (NOLOCK) a 
		ELSE 
			INSERT INTO #tmp_proc_get_MessagesIds_MessageThreads
			SELECT MessageId , ROW_NUMBER() OVER (PARTITION BY MessageSubject,ToContactId ORDER BY MessageSubject  , MessageId DESC)  Rn
			FROM #tmp_proc_get_MessagesIds_Messages (NOLOCK) a 

		--SELECT *  FROM #tmp_proc_get_MessagesIds_Messages a
		--SELECT * FROM #tmp_proc_get_MessagesIds_MessageThreads

		SELECT a.MessageId 
		FROM
		(
			SELECT 
				a.MessageId 
				,a.MessageDate
				,a.MessageRead
				,a.MessageSent
				, (SELECT MAX(MessageDate) FROM #tmp_proc_get_MessagesIds_Messages a1 WHERE a1.MessageSubject = a.MessageSubject ) LastMessageDate
			FROM #tmp_proc_get_MessagesIds_Messages a
			LEFT JOIN (SELECT  * FROM #tmp_proc_get_MessagesIds_MessageThreads ) b ON a.MessageId = b.MessageId 
			WHERE 
				(b.Rn = 1 OR b.Rn  IS NULL )
				AND 
				(
					a.MessageSubject LIKE '%'+ISNULL(@Search,'')+'%'					
				) 
				
		) a
		--ORDER BY LastMessageDate DESC ---- M2-4522 code commited 
		ORDER BY MessageDate DESC       ---- M2-4522 code modified 
		OFFSET @PageSize * (@PageNo - 1) ROWS
		FETCH NEXT @PageSize ROWS ONLY
	
		SET @TotalRec = 
			(
				SELECT COUNT(1) FROM #tmp_proc_get_MessagesIds_MessagesAllData a
				LEFT JOIN (SELECT  * FROM #tmp_proc_get_MessagesIds_MessageThreads ) b ON a.MessageId = b.MessageId 
				WHERE 
					(b.Rn = 1 OR b.Rn  IS NULL )
					AND 
					(
						a.MessageSubject LIKE '%'+ISNULL(@Search,'')+'%'					
					) 
			)
		
		--SELECT * FROM #tmp_proc_get_MessagesIds_MessagesAllData 

		SET @TotalUnRec = (SELECT COUNT(1) FROM #tmp_proc_get_MessagesIds_MessagesAllData WHERE MessageRead = 0 AND FromContactId <> @ContactId)

		SET @TotalUnReadBuyerSupplier = (SELECT COUNT(1) FROM #tmp_proc_get_MessagesIds_MessagesAllData WHERE MessageRead = 0 AND FromContactId <> @ContactId)

		SET @TotalUnReadRfq = (SELECT COUNT(1) FROM #tmp_proc_get_MessagesIds_MessagesAllData WHERE MessageRead = 0 AND ISNULL(RfqId,0) > 0 AND FromContactId <> @ContactId)


	END
	/**/
	ELSE
	BEGIN
	
		-- Fetching all received & sent messages
		IF @TypeId IN (0,1,2)
		BEGIN

		
			INSERT INTO #tmp_proc_get_MessagesIds_Messages (MessageId,MessageDate,MessageRead,MessageSent,MessageSubject)
			SELECT 
				a.message_id AS MessageId 
				,a.message_date AS MessageDate
				,a.message_read AS MessageRead
				,a.message_sent AS MessageSent
				,a.message_subject  AS MessageSubject
			FROM mp_messages (NOLOCK) a
			LEFT JOIN #tmp_proc_get_MessagesIds_ArchivedMessageIds (NOLOCK) c ON a.message_id = c.MessageIds
			WHERE (a.to_cont = @ContactId)
			AND a.trash = 0
			AND a.message_subject IS NOT NULL
			AND ISNULL(a.rfq_id,0) = CASE WHEN @RfqId = 0 THEN ISNULL(a.rfq_id,0) ELSE @RfqId END 
			/* Dec 01, 2021, As discussed with Eddie, need to show only messages in rfq detail message tab */
			AND a.message_type_id IN (5,40,220,225,230,217,242) ----242 added with M2-5010
			--AND a.message_type_id NOT IN (211, 210)
			--AND a.message_type_id IS NOT NULL
			/**/
			/* M2-4218 DB - Buyer and M - Add Archived messages tab under messages Tab*/
			AND ISNULL(c.MessageIds,0)  = 
			(
				CASE 
					WHEN @ArchivedMessages = 1 THEN c.MessageIds
					ELSE 0
				END
			)
			/**/
		END
		ELSE IF @TypeId IN (3)
		BEGIN
		
			INSERT INTO #tmp_proc_get_MessagesIds_Messages (MessageId,MessageDate,MessageRead,MessageSent,MessageSubject)
			SELECT 
				a.message_id AS MessageId 
				,a.message_date AS MessageDate
				,a.message_read AS MessageRead
				,a.message_sent AS MessageSent
				,a.message_subject  AS MessageSubject
			FROM mp_messages (NOLOCK) a
			LEFT JOIN #tmp_proc_get_MessagesIds_ArchivedMessageIds (NOLOCK) c ON a.message_id = c.MessageIds
			WHERE ( a.from_cont = @ContactId OR a.from_cont = @ContactId)
			AND a.trash = 0
			AND a.message_subject IS NOT NULL
			AND ISNULL(a.rfq_id,0) = CASE WHEN @RfqId = 0 THEN ISNULL(a.rfq_id,0) ELSE @RfqId END 
			/* Dec 01, 2021, As discussed with Eddie, need to show only messages in rfq detail message tab */
			AND a.message_type_id IN (5,40,220,225,230,217,242) ----242 added with M2-5010
			--AND a.message_type_id NOT IN (211, 210)
			--AND a.message_type_id IS NOT NULL
			/**/
			/* M2-4218 DB - Buyer and M - Add Archived messages tab under messages Tab*/
			AND ISNULL(c.MessageIds,0)  = 
			(
				CASE 
					WHEN @ArchivedMessages = 1 THEN c.MessageIds
					ELSE 0
				END
			)
			/**/

			----SET @TotalUnRec = (SELECT COUNT(1) FROM #tmp_proc_get_MessagesIds_Messages WHERE MessageRead = 0)
			
		END	

		INSERT INTO #tmp_proc_get_MessagesIds_MessageThreads
		SELECT MessageId , ROW_NUMBER() OVER (PARTITION BY MessageSubject ORDER BY MessageSubject  , MessageId DESC)  Rn
		FROM #tmp_proc_get_MessagesIds_Messages (NOLOCK) a 

				
		-- Global messages All tab data
		IF @TypeId = 0
		BEGIN
		
			--SELECT 
			--	a.MessageId 
			--FROM #tmp_proc_get_MessagesIds_Messages a
			--ORDER BY a.MessageDate DESC
			--OFFSET @PageSize * (@PageNo - 1) ROWS
			--FETCH NEXT @PageSize ROWS ONLY

			SELECT a.MessageId 
			FROM
			(
				SELECT 
					a.MessageId 
					,a.MessageDate
					,a.MessageRead
					,a.MessageSent
					, (SELECT MAX(MessageDate) FROM #tmp_proc_get_MessagesIds_Messages a1 WHERE a1.MessageSubject = a.MessageSubject ) LastMessageDate
				FROM #tmp_proc_get_MessagesIds_Messages a
				LEFT JOIN (SELECT  * FROM #tmp_proc_get_MessagesIds_MessageThreads ) b ON a.MessageId = b.MessageId 
				WHERE 
					(b.Rn = 1 OR b.Rn  IS NULL )
					AND 
					(
						a.MessageSubject LIKE '%'+ISNULL(@Search,'')+'%'					
					) 
				
			) a
			ORDER BY MessageDate DESC  
			OFFSET @PageSize * (@PageNo - 1) ROWS
			FETCH NEXT @PageSize ROWS ONLY


			SET @TotalRec = 
			(
				SELECT COUNT(1) FROM #tmp_proc_get_MessagesIds_Messages a
				LEFT JOIN (SELECT  * FROM #tmp_proc_get_MessagesIds_MessageThreads ) b ON a.MessageId = b.MessageId 
				WHERE 
					(b.Rn = 1 OR b.Rn  IS NULL )
					AND 
					(
						a.MessageSubject LIKE '%'+ISNULL(@Search,'')+'%'					
					) 
			)

			SET @TotalUnRec = (SELECT COUNT(1) FROM #tmp_proc_get_MessagesIds_Messages WHERE MessageRead = 0 AND FromContactId <> @ContactId)
			
		END
		-- Global messages Read tab data
		ELSE IF @TypeId = 1
		BEGIN
		
			/*
			SELECT 
				a.MessageId 
			FROM #tmp_proc_get_MessagesIds_Messages a
			WHERE MessageRead = 1
			ORDER BY a.MessageDate DESC
			OFFSET @PageSize * (@PageNo - 1) ROWS
			FETCH NEXT @PageSize ROWS ONLY
			*/

			 
			SELECT a.MessageId 
			FROM
			(
				SELECT 
					a.MessageId 
					,a.MessageDate
					,a.MessageRead
					,a.MessageSent
					, (SELECT MAX(MessageDate) FROM #tmp_proc_get_MessagesIds_Messages a1 WHERE a1.MessageSubject = a.MessageSubject ) LastMessageDate
				FROM #tmp_proc_get_MessagesIds_Messages a
				LEFT JOIN (SELECT  * FROM #tmp_proc_get_MessagesIds_MessageThreads ) b ON a.MessageId = b.MessageId 
				WHERE  a.MessageRead = 1 AND
					(b.Rn = 1 OR b.Rn  IS NULL )
					AND 
					(
						a.MessageSubject LIKE '%'+ISNULL(@Search,'')+'%'					
					) 
				
			) a
			ORDER BY MessageDate DESC     
			OFFSET @PageSize * (@PageNo - 1) ROWS
			FETCH NEXT @PageSize ROWS ONLY

			----SET @TotalRec = (SELECT COUNT(1) FROM #tmp_proc_get_MessagesIds_Messages WHERE MessageRead = 1)

			SET @TotalRec = 
			(
				SELECT COUNT(1) FROM #tmp_proc_get_MessagesIds_Messages a
				LEFT JOIN (SELECT  * FROM #tmp_proc_get_MessagesIds_MessageThreads ) b ON a.MessageId = b.MessageId 
				WHERE a.MessageRead = 1 AND 
					(b.Rn = 1 OR b.Rn  IS NULL )
					AND 
					(
						a.MessageSubject LIKE '%'+ISNULL(@Search,'')+'%'					
					) 
			)

			----SET @TotalUnRec = (SELECT COUNT(1) FROM #tmp_proc_get_MessagesIds_Messages WHERE MessageRead = 0)
			SET @TotalUnRec = (SELECT COUNT(1) FROM #tmp_proc_get_MessagesIds_Messages WHERE MessageRead = 0 AND FromContactId <> @ContactId)

		END
		-- Global messages UnRead tab data
		ELSE IF @TypeId = 2
		BEGIN
	
		   /*
			SELECT 
				a.MessageId 
			FROM #tmp_proc_get_MessagesIds_Messages a
			WHERE MessageRead = 0
			ORDER BY a.MessageDate DESC
			OFFSET @PageSize * (@PageNo - 1) ROWS
			FETCH NEXT @PageSize ROWS ONLY
		   */

		   SELECT a.MessageId 
			FROM
			(
				SELECT 
					a.MessageId 
					,a.MessageDate
					,a.MessageRead
					,a.MessageSent
					, (SELECT MAX(MessageDate) FROM #tmp_proc_get_MessagesIds_Messages a1 WHERE a1.MessageSubject = a.MessageSubject ) LastMessageDate
				FROM #tmp_proc_get_MessagesIds_Messages a
				LEFT JOIN (SELECT  * FROM #tmp_proc_get_MessagesIds_MessageThreads ) b ON a.MessageId = b.MessageId 
				WHERE  a.MessageRead = 0 AND
					(b.Rn = 1 OR b.Rn  IS NULL )
					AND 
					(
						a.MessageSubject LIKE '%'+ISNULL(@Search,'')+'%'					
					) 
				
			) a
			ORDER BY MessageDate DESC   
			OFFSET @PageSize * (@PageNo - 1) ROWS
			FETCH NEXT @PageSize ROWS ONLY

			----SET @TotalRec = (SELECT COUNT(1) FROM #tmp_proc_get_MessagesIds_Messages WHERE MessageRead = 0)
			SET @TotalRec = 
			(
				SELECT COUNT(1) FROM #tmp_proc_get_MessagesIds_Messages a
				LEFT JOIN (SELECT  * FROM #tmp_proc_get_MessagesIds_MessageThreads ) b ON a.MessageId = b.MessageId 
				WHERE a.MessageRead = 0 AND 
					(b.Rn = 1 OR b.Rn  IS NULL )
					AND 
					(
						a.MessageSubject LIKE '%'+ISNULL(@Search,'')+'%'					
					) 
			)

			----SET @TotalUnRec = (SELECT COUNT(1) FROM #tmp_proc_get_MessagesIds_Messages WHERE MessageRead = 0)
			SET @TotalUnRec = (SELECT COUNT(1) FROM #tmp_proc_get_MessagesIds_Messages WHERE MessageRead = 0 AND FromContactId <> @ContactId)

		END
		-- Global messages Sent tab data
		ELSE IF @TypeId = 3
		BEGIN
		
		    /*
			SELECT 
				a.MessageId 
			FROM #tmp_proc_get_MessagesIds_Messages a
			ORDER BY a.MessageDate DESC
			OFFSET @PageSize * (@PageNo - 1) ROWS
			FETCH NEXT @PageSize ROWS ONLY
            */ 
           
		   SELECT a.MessageId 
			FROM
			(
				SELECT 
					a.MessageId 
					,a.MessageDate
					,a.MessageRead
					,a.MessageSent
					, (SELECT MAX(MessageDate) FROM #tmp_proc_get_MessagesIds_Messages a1 WHERE a1.MessageSubject = a.MessageSubject ) LastMessageDate
				FROM #tmp_proc_get_MessagesIds_Messages a
				LEFT JOIN (SELECT  * FROM #tmp_proc_get_MessagesIds_MessageThreads ) b ON a.MessageId = b.MessageId 
				WHERE 
					(b.Rn = 1 OR b.Rn  IS NULL )
					AND 
					(
						a.MessageSubject LIKE '%'+ISNULL(@Search,'')+'%'					
					) 
				
			) a
			ORDER BY MessageDate DESC  
			OFFSET @PageSize * (@PageNo - 1) ROWS
			FETCH NEXT @PageSize ROWS ONLY


			----SET @TotalRec = (SELECT COUNT(1) FROM #tmp_proc_get_MessagesIds_Messages)

			SET @TotalRec = 
			(
				SELECT COUNT(1) FROM #tmp_proc_get_MessagesIds_Messages a
				LEFT JOIN (SELECT  * FROM #tmp_proc_get_MessagesIds_MessageThreads ) b ON a.MessageId = b.MessageId 
				WHERE 
					(b.Rn = 1 OR b.Rn  IS NULL )
					AND 
					(
						a.MessageSubject LIKE '%'+ISNULL(@Search,'')+'%'					
					) 
			)
		
			SET @TotalUnRec = (SELECT COUNT(1) FROM #tmp_proc_get_MessagesIds_Messages WHERE MessageRead = 0 AND FromContactId <> @ContactId)

		END
	END

	DROP TABLE IF EXISTS #tmp_proc_get_MessagesIds_MessagesAllData
	DROP TABLE IF EXISTS #tmp_proc_get_MessagesIds_Messages
	DROP TABLE IF EXISTS #tmp_proc_get_MessagesIds_MessageThreads
	DROP TABLE IF EXISTS #tmp_proc_get_MessagesIds_MessageTypeIds
	DROP TABLE IF EXISTS #tmp_proc_get_MessagesIds_IsBuyerSupplier
	DROP TABLE IF EXISTS #tmp_proc_get_MessagesIds_ArchivedMessageIds
	DROP TABLE IF EXISTS #tmp_proc_get_MessagesIds_SentMessageIds

END
