


/*

EXEC [proc_set_LeadStreamForDirectRfqs] 
@DirectRfqId	= 245
,@StatusId		= 1
,@ModifiedBy	= 1074


select * FROM [mpCommunityDirectRfqs] WHERE Id = 245
update  [mpCommunityDirectRfqs]  set leadid =  null wHERE Id = 245 
SELECT TOP 10 * FROM mp_lead WHERE LEAD_ID = 9609;

*/
CREATE  PROCEDURE [dbo].[proc_set_LeadStreamForDirectRfqs]
(
	@DirectRfqId	INT
	,@StatusId		INT
	,@ModifiedBy	INT
)
AS
BEGIN

	-- M2-3569  M - Claim my profile

	DECLARE @LeadId INT = 0
	DECLARE @TransactionStatus				VARCHAR(MAX) = 'Failed'

	DECLARE @SupplierCompanyId	INT	
	DECLARE @BuyerIpAddress		VARCHAR	(150)
	DECLARE @BuyerEmail			VARCHAR	(150)
	DECLARE @BuyerPhone			VARCHAR	(50)
	DECLARE @PartDesc			VARCHAR	(50)
	DECLARE @PartFileId			INT	
	DECLARE @Capability			VARCHAR	(150)
	DECLARE @Material			VARCHAR	(150)
	DECLARE @Quantity			INT	
	DECLARE @BuyerId			INT
	DECLARE @LeadEmailMessageId	INT
	DECLARE @IsNdaRequired		BIT
	DECLARE @MessageId			INT
	DECLARE @SupplierId			INT
	DECLARE @FirstName			VARCHAR	(150)
	DECLARE @LastName			VARCHAR	(150)
	/* M2-4010 M - for directory messages, simple, direct RFQ's CC children and add it to their messages -API */
	DECLARE @notification_message_running_id  TABLE (id int IDENTITY(1,1) ,  message_id INT null)
	/**/

	BEGIN TRAN
	BEGIN TRY
		


		SELECT  
			@LeadId				= ISNULL(LeadId	,0) ,
			@SupplierCompanyId	 = 	SupplierCompanyId	,
			@BuyerIpAddress	 = 	BuyerIpAddress	,
			@BuyerEmail	 = 	BuyerEmail	,
			@BuyerPhone	 = 	BuyerPhone	,
			@PartDesc	 = 	PartDesc	,
			@PartFileId	 = 	PartFileId	,
			@Capability	 = 	Capability	,
			@Material	 = 	Material	,
			@Quantity	 = 	Quantity	,
			@IsNdaRequired = IsNdaRequired ,
			@FirstName =  FirstName,
			@LastName = LastName
		FROM [mpCommunityDirectRfqs] WHERE Id = @DirectRfqId


		IF @LeadId > 0 
		BEGIN
			UPDATE mp_lead SET 
				status_id =@StatusId 
				,ModifiedBy =@ModifiedBy
				,ModifiedOn = GETUTCDATE()	
			WHERE lead_id = @LeadId
		END
		ELSE
		BEGIN

			SET @BuyerId = 
			ISNULL
			(
				(
					SELECT a.contact_id 
					FROM mp_contacts (NOLOCK) a
					JOIN aspnetusers (NOLOCK) b ON a.[user_id] = b.Id AND a.is_buyer = 1
					WHERE b.email = @BuyerEmail
				)
			,0)

			SET @SupplierId = 
			(
				SELECT TOP 1 a.contact_id 
				FROM mp_contacts (NOLOCK) a
				WHERE company_id = @SupplierCompanyId
				AND a.is_buyer =  0 AND  is_admin = 1
			)

			INSERT INTO mp_lead
			(company_id , lead_source_id , lead_from_contact , ip_address , lead_date , status_id , ModifiedBy  , ModifiedOn )
			SELECT @SupplierCompanyId , 14 , CASE WHEN @BuyerId = 0 THEN 0 ELSE @BuyerId END ,  CASE WHEN @BuyerId = 0 THEN @BuyerIpAddress ELSE '' END , GETUTCDATE() , @StatusId , @ModifiedBy , GETUTCDATE()
			SET @LeadId = @@IDENTITY


			IF @LeadId > 0 
			BEGIN
				
				INSERT INTO mp_lead_emails
				(first_name , last_name , company , email , phoneno , email_subject , email_message)
				SELECT @FirstName , @LastName , '' , @BuyerEmail , @BuyerPhone ,
					'Simple RFQ: ' 
					+ CASE WHEN LEN(@Capability) > 0 THEN @Capability + ' - ' ELSE '' END 
					+ CASE WHEN LEN(@Material) > 0 THEN @Material + ' - 'ELSE '' END
					--+ CASE WHEN LEN(@Quantity) > 0 THEN CONVERT(VARCHAR(50),@Quantity) ELSE '' END 
				, LEFT(@PartDesc, 20)
				SET @LeadEmailMessageId = @@IDENTITY

				INSERT INTO mp_lead_email_mappings (lead_id,lead_email_message_id)
				SELECT @LeadId , @LeadEmailMessageId


				IF @PartFileId > 0
				BEGIN

					INSERT INTO mp_messages
					( 
						rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read 
						,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author 
						,is_nda_required
					)
					/* M2-4010 M - for directory messages, simple, direct RFQ's CC children and add it to their messages -API */
					OUTPUT inserted.message_id INTO @notification_message_running_id
					/*  */
					SELECT
						NULL as rfq_id
						, 230				as message_type_id 
						, 'Simple RFQ: ' 
							+ CASE WHEN LEN(@Capability) > 0 THEN @Capability + ' - ' ELSE '' END 
							+ CASE WHEN LEN(@Material) > 0 THEN @Material + ' - 'ELSE '' END
							--+ CASE WHEN LEN(@Quantity) > 0 THEN CONVERT(VARCHAR(50),@Quantity) ELSE '' END 		
							as  message_subject 
						, @PartDesc			as message_descr
						, GETUTCDATE()		as message_date
						, CASE WHEN @BuyerId = 0 THEN NULL ELSE @BuyerId END				as from_contact_id 
						, contact_id		as to_contact_id 
						, 0					as message_sent
						, 0					as message_read
						, 0					as trash
						, 0					as from_trash
						, 0					as real_from_cont_id
						, 0					as is_last_message
						, 0					as message_status_id_recipient
						, 0					as message_status_id_author
						, @IsNdaRequired
					 FROM mp_contacts (NOLOCK) WHERE company_id = @SupplierCompanyId 

					--SET @MessageId = @@identity

					INSERT INTO mp_message_file (MESSAGE_ID, [FILE_ID])
					/* M2-4010 M - for directory messages, simple, direct RFQ's CC children and add it to their messages -API */
					--SELECT @MessageId , @PartFileId 
					SELECT message_id , @PartFileId  FROM @notification_message_running_id
					/**/
					

					INSERT INTO mp_lead_message_mapping (lead_id, message_id)
					/* M2-4010 M - for directory messages, simple, direct RFQ's CC children and add it to their messages -API */
					--SELECT @LeadId ,@MessageId 
					SELECT @LeadId ,message_id  FROM @notification_message_running_id
					/**/


				END

				UPDATE [mpCommunityDirectRfqs] SET LeadId = @LeadId WHERE Id = @DirectRfqId 



			END
		END

	

	SET @TransactionStatus = 'Success'
	--SELECT @TransactionStatus TransactionStatus
	SELECT 
			@TransactionStatus processStatus 
			, NULL email_message_id 
			, message_id message_id
			, NULL rfq_id
			, message_type_id message_type_id
			, message_subject  as message_subject
			, message_descr as message_body
			, NULL  email_message_subject
			, NULL email_msg_body
			, message_date email_message_date
			, d.contact_id rfq_contact_id
			, d.first_name +' '+d.last_name as from_username
			, e.file_name from_user_contactimage
			, to_cont as to_contact_id
			, NULL as to_username
			, c.email as to_email_id
			, 0 as message_sent
			, 'Community Direct Rfq' message_type
	FROM mp_messages (NOLOCK) a
	JOIN mp_contacts (NOLOCK) b ON a.to_cont = b.contact_id
	JOIN aspnetusers (NOLOCK) c ON b.user_id = c.id
	LEFT JOIN mp_contacts (NOLOCK) d ON a.from_cont = d.contact_id
	left join mp_special_files e  (nolock) on d.contact_id = e.cont_id and e.filetype_id = 17
	WHERE message_id in  (SELECT message_id FROM @notification_message_running_id)

	

	COMMIT
	END TRY
	BEGIN CATCH
	
		
		ROLLBACK
		
		SET @TransactionStatus = 'Failed - ' + ERROR_MESSAGE()
		SELECT @TransactionStatus processStatus
		

	END CATCH
END
