

/*
EXEC proc_get_MessageThreads
@MessageId = 19194225
,@ContactId = 1349558

exec proc_get_MessageThreads @MessageId=19194247,@ContactId=1349558
					
*/
CREATE PROCEDURE [dbo].[proc_get_MessageThreads]
(
	@MessageId INT
	,@ContactId INT = NULL
)
AS
BEGIN
	-- M2-3430 Global Message optimization - Convert into the SP - DB
	SET NOCOUNT ON
	
		DECLARE @RfqId	INT = 0

		DROP TABLE IF EXISTS #tmp_proc_get_MessageThreads_Message
		DROP TABLE IF EXISTS #tmp_proc_get_MessageThreads_MessageThreads
		DROP TABLE IF EXISTS #tmp_proc_get_MessageThreads_ContactCompanyInfo
		DROP TABLE IF EXISTS #tmp_proc_get_MessageThreads_ContactCompanyInfo_1
		DROP TABLE IF EXISTS #tmp_proc_get_MessagesIds_ArchivedMessageIds

		DECLARE @ArchivedMessages BIT = 0 


		-- fetch message details
		SELECT * 
		INTO #tmp_proc_get_MessageThreads_Message
		FROM mp_messages (NOLOCK) a 
		WHERE  a.message_id = @MessageId

		SET @RfqId = ISNULL((SELECT CASE WHEN message_type_id IN (210,211) THEN 0 ELSE rfq_id END FROM #tmp_proc_get_MessageThreads_Message),0)

		/* M2-4218 DB - Buyer and M - Add Archived messages tab under messages Tab*/
		CREATE TABLE #tmp_proc_get_MessagesIds_ArchivedMessageIds
		(
			MessageIds INT
		)

			   
		SET @ArchivedMessages = 
		(CASE WHEN (SELECT COUNT(1) FROM mpArchivedMessages (NOLOCK) WHERE ArchievedBy = @ContactId  AND MessageId = @MessageId) > 0 THEN 1 ELSE 0 END )



		/**/

		SELECT * 
		INTO #tmp_proc_get_MessageThreads_MessageThreads
		FROM mp_messages (NOLOCK) a 
		WHERE  
			(
				--EXISTS (SELECT * FROM @MessageIds WHERE MessageId = a.message_id)
				--AND 
				ISNULL(a.rfq_id,0) = (CASE WHEN @RfqId = 0 THEN ISNULL(a.rfq_id,0) ELSE @RfqId END)
				AND 
				(
					ISNULL(a.from_cont,0) IN 
							(
								SELECT ISNULL(from_cont,0) FROM #tmp_proc_get_MessageThreads_Message 
								UNION
								SELECT ISNULL(to_cont,0) FROM #tmp_proc_get_MessageThreads_Message
							)
					AND ISNULL(a.to_cont,0) IN 
						(
							SELECT ISNULL(from_cont,0) FROM #tmp_proc_get_MessageThreads_Message
							UNION
							SELECT ISNULL(to_cont,0) FROM #tmp_proc_get_MessageThreads_Message
						)			
				)
				AND a.message_subject IN  (SELECT message_subject FROM #tmp_proc_get_MessageThreads_Message )
			)
			AND trash = 0

		--SELECT * FROM #tmp_proc_get_MessageThreads_MessageThreads

		IF @ArchivedMessages = 0
			INSERT INTO #tmp_proc_get_MessagesIds_ArchivedMessageIds (MessageIds)
			SELECT MessageId FROM mpArchivedMessages (NOLOCK) WHERE ArchievedBy = @ContactId 
		ELSE IF @ArchivedMessages =1
			INSERT INTO #tmp_proc_get_MessagesIds_ArchivedMessageIds (MessageIds)
			SELECT message_id FROM #tmp_proc_get_MessageThreads_MessageThreads 


		-- fetching contact & company details
		SELECT 
			c.company_id	AS CompanyId
			, CASE WHEN c.company_id = 0  THEN 'MFG' ELSE c.name END		AS Company
			, b.contact_id	AS ContactId
			, CASE WHEN c.company_id = 0   THEN 'MFG' ELSE b.first_name +' '+ b.last_name END  AS Contact
			, c.companyurl	AS CompanyURL
			, CASE WHEN  c.company_id = 0  THEN 'Logo_MFG.jpg' ELSE d.file_name END AS CompanyLogo
		INTO #tmp_proc_get_MessageThreads_ContactCompanyInfo
		FROM
		(
			SELECT from_cont Id FROM #tmp_proc_get_MessageThreads_Message
			UNION
			SELECT to_cont FROM #tmp_proc_get_MessageThreads_Message
		) a
		JOIN mp_contacts	b (NOLOCK) ON a.Id = b.contact_id
		JOIN mp_companies	c (NOLOCK) ON b.company_id = c.company_id
		LEFT JOIN mp_special_files d (NOLOCK) ON c.company_id = d.comp_id AND d.is_deleted = 0 AND d.filetype_id = 6
	

		SELECT
			 a.message_id	AS MessageId
			, a.rfq_id		AS RfqId
			, CAST('false' AS BIT) HaveThread
			, CASE WHEN (a.message_type_id IN (230) AND b.ContactId > 0 )  THEN b.CompanyId WHEN (a.message_type_id IN (221,230) OR b.ContactId = 0 ) THEN 0 ELSE b.CompanyId	END AS FromCompanyId
			, CASE WHEN (a.message_type_id IN (230) AND b.ContactId > 0 )  THEN b.Company WHEN (a.message_type_id IN (221,230) OR b.ContactId = 0 ) THEN g.company  WHEN a.message_type_id = 232 THEN 'MFG' ELSE b.Company END		AS FromCompany
			, CASE WHEN b.ContactId = 0  THEN NULL ELSE  b.CompanyLogo	END	AS FromCompanyLogo
			, CASE WHEN b.ContactId = 0  THEN NULL ELSE  b.CompanyURL END	AS FromCompanyURL
			, CASE WHEN (a.message_type_id IN (230) AND b.ContactId > 0 )  THEN b.ContactId WHEN (a.message_type_id IN (221,230) OR b.ContactId = 0 ) THEN 0 ELSE b.ContactId	END  	AS FromContactId
			, CASE WHEN (a.message_type_id IN (230) AND b.ContactId > 0 )  THEN b.Contact WHEN (a.message_type_id IN (221,230) OR b.ContactId = 0 ) THEN ISNULL(g.first_name,'') +' '+ ISNULL(g.last_name,'') WHEN a.message_type_id = 232 THEN 'MFG'  ELSE b.Contact	 END  	AS FromContact
			, c.CompanyId 	AS ToCompanyId
			, c.Company		AS ToCompany
			, CASE WHEN c.CompanyId = 0 THEN 'Logo_MFG.jpg' ELSE c.CompanyLogo	END	AS ToCompanyLogo
			, c.CompanyURL	AS ToCompanyURL
			, c.ContactId	AS ToContactId
			, c.Contact	 	AS ToContact
			, d.lead_id		AS LeadId
			, a.message_subject	AS MessageSubject
			, a.message_descr	AS MessageDescription
			, a.message_type_id AS MessageTypeId
			, e.message_type_name AS MessageType
			, a.message_date	AS MessageDate
			, CASE WHEN a.message_read = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END MessageRead
			, CASE WHEN a.message_sent = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END MessageSent
			, a.read_date AS MessageReadDate 
			, (
				SELECT STRING_AGG(i.file_name,',') 
				FROM mp_special_files i (NOLOCK) 
				JOIN mp_message_file (NOLOCK) h ON i.file_id = h.file_id
				WHERE h.message_id = 
				( 
					CASE 
						WHEN a.message_type_id = 225  THEN  d.message_id
						ELSE a.message_id 
					END
				)  
			)	AS MessageFile
			, CASE WHEN a.is_external_nda_accepted = 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END IsNdaAccepted
			, (	
				SELECT quote_reference_number
				FROM mp_rfq_quote_supplierquote (NOLOCK) j 
				WHERE j.rfq_id = a.rfq_id
					AND j.contact_id = a.from_cont
					AND j.is_rfq_resubmitted = 0
			  ) AS QuoteReferenceNo
		FROM #tmp_proc_get_MessageThreads_MessageThreads a 
		LEFT JOIN #tmp_proc_get_MessageThreads_ContactCompanyInfo b ON a.from_cont = b.ContactId
		LEFT JOIN #tmp_proc_get_MessageThreads_ContactCompanyInfo c ON a.to_cont = c.ContactId
		LEFT JOIN mp_lead_message_mapping	(NOLOCK) d ON a.message_id = d.message_id
		LEFT JOIN mp_mst_message_types		(NOLOCK) e ON a.message_type_id = e.message_type_id 	
		LEFT JOIN mp_lead_email_mappings	(NOLOCK) f ON d.lead_id = f.lead_id
		LEFT JOIN mp_lead_emails			(NOLOCK) g ON f.lead_email_message_id = g.lead_email_message_id
		/* M2-4218 DB - Buyer and M - Add Archived messages tab under messages Tab*/
		LEFT JOIN #tmp_proc_get_MessagesIds_ArchivedMessageIds (NOLOCK) c1 ON a.message_id = c1.MessageIds
		/**/
		WHERE 
		ISNULL(c1.MessageIds,0)  = 
			(
				CASE 
					WHEN @ArchivedMessages = 1 THEN c1.MessageIds
					ELSE 0
				END
			)
			
		ORDER BY MessageDate DESC

		DROP TABLE IF EXISTS #tmp_proc_get_MessageThreads_Message
		DROP TABLE IF EXISTS #tmp_proc_get_MessageThreads_MessageThreads
		DROP TABLE IF EXISTS #tmp_proc_get_MessageThreads_ContactCompanyInfo
		DROP TABLE IF EXISTS #tmp_proc_get_MessageThreads_ContactCompanyInfo_1
		DROP TABLE IF EXISTS #tmp_proc_get_MessagesIds_ArchivedMessageIds


END
