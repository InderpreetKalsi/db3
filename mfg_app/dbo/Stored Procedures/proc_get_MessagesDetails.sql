
/*

select * from mp_messages where to_cont = 0 and message_type_id = 5

declare @messageIds1 as [tbltype_ListOfMessageId]
insert into  @messageIds1 values (19194247) 

exec [proc_get_MessagesDetails] 
@MessageIds = @messageIds1
,@ContactId = 1349558 
*/
CREATE PROCEDURE [dbo].[proc_get_MessagesDetails]
(
	@MessageIds AS tbltype_ListOfMessageId READONLY	
	,@ContactId INT = NULL
)
AS
BEGIN
	 -- M2-3430 Global Message optimization - Convert into the SP - DB
	SET NOCOUNT ON

	DROP TABLE IF EXISTS #tmp_proc_get_MessagesAdditionalInfo_Messages
	DROP TABLE IF EXISTS #tmp_proc_get_MessagesAdditionalInfo_CheckingMessagesThreads
	DROP TABLE IF EXISTS #tmp_proc_get_MessagesAdditionalInfo_GettingAllMessagesOfFromToContacts
	DROP TABLE IF EXISTS #tmp_proc_get_MessagesAdditionalInfo_ContactCompanyInfo
	DROP TABLE IF EXISTS #tmp_proc_get_MessagesAdditionalInfo_MessagesIds
	DECLARE @PageName VARCHAR(100) 
	DECLARE @IsBuyer INT

	SELECT @IsBuyer = is_buyer FROM mp_contacts(nolock) WHERE contact_id = @ContactId

	CREATE TABLE #tmp_proc_get_MessagesAdditionalInfo_MessagesIds (Id INT IDENTITY(1,1) , MessageId INT)

	INSERT INTO #tmp_proc_get_MessagesAdditionalInfo_MessagesIds (MessageId)
	SELECT * FROM @MessageIds

	-- Fetching messages data for shared message id's
	SELECT * 
	INTO #tmp_proc_get_MessagesAdditionalInfo_Messages
	FROM mp_messages (NOLOCK) a 
	WHERE  EXISTS (SELECT * FROM @MessageIds WHERE MessageId = a.message_id)

	-- Fetching contact and company info 
	SELECT DISTINCT
			c.company_id	AS CompanyId
			, CASE WHEN c.company_id IS NULL THEN 'MFG' WHEN c.company_id = 0  THEN 'MFG' ELSE c.name END		AS Company
			, b.contact_id	AS ContactId
			, CASE WHEN c.company_id = 0  THEN 'MFG' ELSE b.first_name +' '+ b.last_name END  AS Contact
			, c.companyurl	AS CompanyURL
			, CASE WHEN c.company_id IS NULL THEN 'MFG_Logo_Color_No_R.jpg' WHEN  c.company_id = 0  THEN 'MFG_Logo_Color_No_R.jpg' ELSE d.file_name END	AS CompanyLogo
	        , b.is_buyer
	INTO #tmp_proc_get_MessagesAdditionalInfo_ContactCompanyInfo
	FROM
	(
		SELECT from_cont Id FROM #tmp_proc_get_MessagesAdditionalInfo_Messages
		UNION
		SELECT to_cont FROM #tmp_proc_get_MessagesAdditionalInfo_Messages
	) a
	JOIN mp_contacts	b (NOLOCK) ON a.Id = b.contact_id
	JOIN mp_companies	c (NOLOCK) ON b.company_id = c.company_id
	LEFT JOIN mp_special_files d (NOLOCK) ON c.company_id = d.comp_id AND d.is_deleted = 0 AND d.filetype_id = 6

	-- fetching all communication messages for 25 messsages based on from and to contact
	SELECT 
		a1.message_id , a1.from_cont , a1.to_cont , a1.message_subject , a1.message_type_id 
		, a1.trash , a1.message_descr 	, a1.message_date , a1.message_read
	INTO #tmp_proc_get_MessagesAdditionalInfo_GettingAllMessagesOfFromToContacts
	FROM mp_messages a1 (NOLOCK)
	WHERE 
		a1.from_cont IN 
			(
				SELECT from_cont FROM #tmp_proc_get_MessagesAdditionalInfo_Messages 
				UNION
				SELECT to_cont FROM #tmp_proc_get_MessagesAdditionalInfo_Messages
			)
		AND a1.to_cont IN 
			(
				SELECT from_cont FROM #tmp_proc_get_MessagesAdditionalInfo_Messages 
				UNION
				SELECT to_cont FROM #tmp_proc_get_MessagesAdditionalInfo_Messages 
			)
		--AND a1.trash = 0
		--AND message_type_id NOT IN (211, 210)

	
	--  fetching latest message description if have thread messages
	/* M2-4088 Buyer and Supplier - Split Messages and Notifications - DB */
	SELECT *
	INTO #tmp_proc_get_MessagesAdditionalInfo_CheckingMessagesThreads
	FROM
	(
	SELECT 
		a.message_id , a1.message_descr , a1.message_date
		, ROW_NUMBER() OVER (PARTITION BY a.message_subject ORDER BY a.message_subject , a1.message_read ASC , a1.message_date DESC)  Rn
		, a1.message_read
		, a1.from_cont
	FROM #tmp_proc_get_MessagesAdditionalInfo_Messages a (NOLOCK)
	JOIN #tmp_proc_get_MessagesAdditionalInfo_GettingAllMessagesOfFromToContacts a1 (NOLOCK)
		ON a1.message_subject = a.message_subject
	WHERE 
		a1.from_cont IN 
			(
				SELECT from_cont FROM #tmp_proc_get_MessagesAdditionalInfo_Messages WHERE message_id = a.message_id
				UNION
				SELECT to_cont FROM #tmp_proc_get_MessagesAdditionalInfo_Messages WHERE message_id = a.message_id
			)
		AND a1.to_cont IN 
			(
				SELECT from_cont FROM #tmp_proc_get_MessagesAdditionalInfo_Messages WHERE message_id = a.message_id
				UNION
				SELECT to_cont FROM #tmp_proc_get_MessagesAdditionalInfo_Messages WHERE message_id = a.message_id
			)
		--AND a1.trash = 0
		--AND a1.message_type_id NOT IN (211, 210)
	) a
	WHERE a.Rn = 1
	/**/

	--select * from #tmp_proc_get_MessagesAdditionalInfo_CheckingMessagesThreads

	-- generating messages info
	SELECT	MessageId,	RfqId,	HaveThread,	FromCompanyId,	FromCompany	,FromCompanyLogo,	FromCompanyURL,	FromContactId,	FromContact,	ToCompanyId,	ToCompany,
			ToCompanyLogo,	ToCompanyURL,	ToContactId,	ToContact,	LeadId	 
			/* Message and notification : page name take dynamic*/
			,CASE WHEN RfqId IS NOT NULL THEN 
			 CASE WHEN MessageSubject LIKE '%' + CAST(RfqId AS VARCHAR(50)) + '%' THEN 
					REPLACE ( MessageSubject
					   , RfqId 
					   , 
					   --case when messagetypeid IN (244,245,247) THEN 
					   case when IsPOExists = 1 THEN  
					   '<a style=''color: blue'' href=''/#/'+ PageName + '?rfqId='+ concat(REPLACE(REPLACE(RfqGuid,'+','%2B'),'=','%3D'),PageLink) + ''' >' + convert(varchar(50),RfqId) + '</a>' 
					   ELSE
						'<a style=''color: blue'' href=''/#/'+ PageName + '?id='+ RfqGuid + ''' >' + convert(varchar(50),RfqId) + '</a>' 
					   END 
					   )
					ELSE 
						REPLACE ( MessageSubject
					   , PONumber 
					   , 
					   --case when messagetypeid IN (244,245,247) THEN 
					   case when IsPOExists = 1 THEN  
					   '<a style=''color: blue'' href=''/#/'+ PageName + '?rfqId='+ concat(REPLACE(REPLACE(RfqGuid,'+','%2B'),'=','%3D'),PageLink) + ''' >' + convert(varchar(50),PONumber) + '</a>' 
					   ELSE
						'<a style=''color: blue'' href=''/#/'+ PageName + '?id='+ RfqGuid + ''' >' + convert(varchar(50),PONumber) + '</a>' 
					   END 
					   )
					END 
				ELSE
					MessageSubject
				END AS MessageSubject 
			, MessageDescription
			/* END : Message and notification : page name take dynamic*/
			, MessageTypeId,	MessageType	,IsNotification	
			, MessageDate,	MessageRead	,MessageSent,	MessageReadDate	--,RFQGuid,	PageName
			, MessageSubject as OriginalMessageSubject
			, MessageDescription AS OriginalMessageDescription
			, IsPOExists
		    , @IsBuyer is_buyer
			
	FROM (
	SELECT
		a.message_id	AS MessageId
		, a.rfq_id		AS RfqId
		, CAST('false' AS BIT) HaveThread
		, CASE 
			WHEN (a.message_type_id IN (230) AND b.ContactId > 0 )  THEN b.CompanyId
			WHEN (a.message_type_id IN (221,230) OR b.ContactId = 0 ) THEN 0 
			ELSE b.CompanyId	
		  END AS FromCompanyId
		, CASE 
			WHEN (a.message_type_id IN (230) AND b.ContactId > 0 )  THEN b.Company
			WHEN (a.message_type_id IN (221,230) OR b.ContactId = 0 ) THEN g.company 
			WHEN a.message_type_id IN (217,232,242,5) THEN 'MFG'  ELSE b.Company END		AS FromCompany
		, CASE WHEN b.ContactId IS NULL  THEN 'MFG_Logo_Color_No_R.png' WHEN b.ContactId = 0  THEN NULL ELSE  b.CompanyLogo	END AS FromCompanyLogo
		, CASE WHEN b.ContactId = 0  THEN NULL ELSE  b.CompanyURL END	AS FromCompanyURL
		, CASE 
			WHEN (a.message_type_id IN (230) AND b.ContactId > 0 )  THEN b.ContactId
			WHEN (a.message_type_id IN (221,230) OR b.ContactId = 0 )  THEN 0 ELSE b.ContactId	END  	AS FromContactId
		, CASE 
			WHEN (a.message_type_id IN (230) AND b.ContactId > 0 )  THEN b.Contact
			WHEN (a.message_type_id IN (221,230) OR b.ContactId = 0 ) THEN ISNULL(g.first_name,'') +' '+ ISNULL(g.last_name,'') WHEN a.message_type_id = 232 THEN 'MFG'  ELSE b.Contact	 END  	AS FromContact
		, c.CompanyId 	AS ToCompanyId
		, c.Company		AS ToCompany
		, CASE WHEN ISNULL(c.CompanyId,0) = 0 THEN 'MFG_Logo_Color_No_R.jpg' ELSE c.CompanyLogo	END AS ToCompanyLogo
		, c.CompanyURL	AS ToCompanyURL
		, c.ContactId	AS ToContactId
		, c.Contact	 	AS ToContact
		, d.lead_id		AS LeadId
		, a.message_subject	AS MessageSubject
		/* M2-4088 Buyer and Supplier - Split Messages and Notifications - DB */
		, ISNULL(h.message_descr , a.message_descr)	AS MessageDescription
		/**/
		, a.message_type_id AS MessageTypeId
		, e.message_type_name AS MessageType
		, ISNULL(e.IsNotification,0) As IsNotification
		, ISNULL(h.message_date , a.message_date)	AS MessageDate
		--, CASE WHEN a.message_read = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END MessageRead
		, 
		  CASE 
			WHEN h.from_cont  = @ContactId THEN CAST('true' AS BIT)
			ELSE
				CASE 
					WHEN h.message_read = 1 THEN CAST('true' AS BIT) 
					WHEN h.message_read = 0 THEN CAST('false' AS BIT) 
					WHEN a.message_read = 1 THEN CAST('true' AS BIT) 
					WHEN a.message_read = 0 THEN CAST('false' AS BIT) 
					ELSE CAST('false' AS BIT) 
				END 
		  END 
		  MessageRead 
		, CASE WHEN a.message_sent = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END MessageSent
		, a.read_date AS MessageReadDate 
		/* Message and notification : page name take dynamic*/
		----, CASE WHEN j.RfqId IS NOT NULL  AND a.message_type_id IN (244,245,247)THEN  j.RfqEncryptedId 
		, CASE WHEN j.RfqId IS NOT NULL THEN  j.RfqEncryptedId 
		       ELSE ( SELECT   convert(varchar(50), rfq_guid ) from mp_rfq(nolock) where mp_rfq.rfq_id = a.rfq_id) END 
			   AS RFQGuid
		, CASE WHEN @IsBuyer = 1 THEN 'rfq/rfqdetail' ELSE 'supplier/supplerRfqDetails' END PageName
		, CASE WHEN @IsBuyer = 1 THEN
			 --CASE WHEN j.POStatus in ('accepted','pending') THEN '&order=Order' ELSE '&quotes=Quotes' END 
			 '&order=Order'
			 ELSE 
				CASE WHEN a.message_type_id = 243 THEN 
				'&quotes=Quotes'
				ELSE
				NULL
				END 
			 END  AS PageLink
		, CASE WHEN j.RfqId IS NOT NULL THEN 1 ELSE 0 END IsPOExists
		, j.PONumber
	FROM #tmp_proc_get_MessagesAdditionalInfo_Messages a 
	LEFT JOIN #tmp_proc_get_MessagesAdditionalInfo_ContactCompanyInfo b ON a.from_cont = b.ContactId
	LEFT JOIN #tmp_proc_get_MessagesAdditionalInfo_ContactCompanyInfo c ON a.to_cont = c.ContactId
	LEFT JOIN mp_lead_message_mapping	(NOLOCK) d ON a.message_id = d.message_id
	LEFT JOIN mp_mst_message_types		(NOLOCK) e ON a.message_type_id = e.message_type_id 	
	LEFT JOIN mp_lead_email_mappings	(NOLOCK) f ON d.lead_id = f.lead_id
	LEFT JOIN mp_lead_emails			(NOLOCK) g ON f.lead_email_message_id = g.lead_email_message_id
	/* M2-4088 Buyer and Supplier - Split Messages and Notifications - DB */
	LEFT JOIN #tmp_proc_get_MessagesAdditionalInfo_CheckingMessagesThreads  (NOLOCK) h ON a.message_id = h.message_id
	/**/
	JOIN #tmp_proc_get_MessagesAdditionalInfo_MessagesIds  (NOLOCK) i ON a.message_id = i.MessageId
	--WHERE a.message_id NOT IN (SELECT M.MessageId From mpArchivedMessages m WHERE a.message_id = m.MessageId )
	LEFT JOIN mpOrderManagement(NOLOCK) j on j.RfqId = a.rfq_id AND j.IsDeleted = 0

	--ORDER BY  
 
	--a.message_id desc ----M2-4522

	) 
	messagesList  
	ORDER BY
	messagesList.MessageId desc

	

	--SELECT * FROM #tmp_proc_get_MessagesAdditionalInfo_GettingAllMessagesOfFromToContacts
	--SELECT * FROM #tmp_proc_get_MessagesAdditionalInfo_CheckingMessagesThreads

	DROP TABLE IF EXISTS #tmp_proc_get_MessagesAdditionalInfo_Messages
	DROP TABLE IF EXISTS #tmp_proc_get_MessagesAdditionalInfo_CheckingMessagesThreads
	DROP TABLE IF EXISTS #tmp_proc_get_MessagesAdditionalInfo_GettingAllMessagesOfFromToContacts
	DROP TABLE IF EXISTS #tmp_proc_get_MessagesAdditionalInfo_ContactCompanyInfo
	DROP TABLE IF EXISTS #tmp_proc_get_MessagesAdditionalInfo_MessagesIds
END
