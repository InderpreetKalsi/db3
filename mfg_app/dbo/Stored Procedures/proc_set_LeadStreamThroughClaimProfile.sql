
/*

EXEC proc_set_LeadStreamThroughClaimProfile
@ContactId = 1372454
,@CompanyId = 1800414
,@EmailId = 'schoudhari123@yopmail.com'

EXEC proc_set_LeadStreamThroughClaimProfile
@ContactId = 1372454
,@CompanyId = 1800414
,@EmailId = 'DEBORAHF@TETRADELEC.COM'


EXEC proc_set_LeadStreamThroughClaimProfile
@ContactId = 1372454
,@CompanyId = 1800414
,@EmailId = 'john876@yopmail.com'
*/
CREATE  PROCEDURE [dbo].[proc_set_LeadStreamThroughClaimProfile]
(
	@ContactId	INT
	,@CompanyId	INT
	,@EmailId	VARCHAR(250)
)
AS
BEGIN

	-- M2-3569  M - Claim my profile

	DECLARE @IsCommunityExternalDirectoryMessagesExists INT = 0
	DECLARE @IsCommunityLeadStreamExists	INT = 0
	DECLARE @TransactionStatus				VARCHAR(MAX) = 'Failed'

	BEGIN TRAN
	BEGIN TRY
		-- Checking Community External messages exists or not
		SET @IsCommunityExternalDirectoryMessagesExists = (SELECT COUNT(1) FROM mpCommunityExternalDirectoryMessages WHERE SupplierEmail = @EmailId AND IsClaimed = 0)
		-- Checking Community Leadstream exists or not
		SET @IsCommunityLeadStreamExists = (SELECT COUNT(1) FROM mpCommunityLeadStream WHERE SupplierEmail = @EmailId AND IsClaimed = 0)

		-- Reteriving & Inserting Community External messages if exists in relevant tables
		IF @IsCommunityExternalDirectoryMessagesExists > 0
		BEGIN

		
			DECLARE @LeadId				INT
			DECLARE @LeadEmailMessageId	INT
			DECLARE @MessageId			INT
			DECLARE @Id					INT
			DECLARE @BuyerId			INT
			DECLARE @BuyerEmail			VARCHAR(150)
			DECLARE @BuyerFirstName		VARCHAR(150)
			DECLARE @BuyerLastName		VARCHAR(150)
			DECLARE @BuyerCompanyName	VARCHAR(250)
			DECLARE @BuyerPhone			VARCHAR(50)
			DECLARE @MessageFileId		INT
			DECLARE @EmailSubject		VARCHAR(250)
			DECLARE @EmailBody			VARCHAR(MAX)
			DECLARE @IpAddress			VARCHAR(150)
			DECLARE @EmailMessageDate	DATETIME
			DECLARE @IsNdaRequired		BIT

		
			DECLARE crCommunityExternalDirectoryMessages CURSOR FOR 
			SELECT 
				Id
				,BuyerEmail
				,BuyerFirstName
				,BuyerLastName
				,BuyerCompanyName
				,BuyerPhone
				,MessageFileId
				,EmailSubject
				,EmailBody
				,IpAddress
				,EmailMessageDate
				,IsNdaRequired 
			FROM mpCommunityExternalDirectoryMessages WHERE SupplierEmail = @EmailId AND IsClaimed = 0
		
		
			OPEN crCommunityExternalDirectoryMessages;
			FETCH NEXT FROM crCommunityExternalDirectoryMessages INTO @Id,@BuyerEmail,@BuyerFirstName,@BuyerLastName,@BuyerCompanyName,@BuyerPhone,@MessageFileId,@EmailSubject,@EmailBody,@IpAddress,@EmailMessageDate,@IsNdaRequired ;

			WHILE @@FETCH_STATUS = 0
			BEGIN

				SET @BuyerId = 
				(
					SELECT b.contact_id
					FROM aspnetusers (NOLOCK) a
					JOIN mp_contacts (NOLOCK) b ON a.id = b.[user_id]
					WHERE email = @BuyerEmail
				)

				INSERT INTO mp_lead
				(company_id , lead_source_id , lead_from_contact , ip_address , lead_date)
				SELECT @CompanyId , 13 , ISNULL(@BuyerId,0) , CASE WHEN @BuyerId IS NULL THEN @IpAddress ELSE '' END , @EmailMessageDate
				SET @LeadId = @@IDENTITY
		
				IF @LeadId > 0 
				BEGIN
				
					INSERT INTO mp_lead_emails
					(first_name , last_name , company , email , phoneno , email_subject , email_message)
					SELECT @BuyerFirstName , @BuyerLastName , @BuyerCompanyName , @BuyerEmail , @BuyerPhone ,@EmailSubject ,@EmailBody
					SET @LeadEmailMessageId = @@IDENTITY

					INSERT INTO mp_lead_email_mappings (lead_id,lead_email_message_id)
					SELECT @LeadId , @LeadEmailMessageId
				END
				
				
				IF @MessageFileId > 0
				BEGIN

					INSERT INTO mp_messages
					( 
						rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read 
						,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author 
						,is_nda_required
					)
					SELECT
						NULL as rfq_id
						, 225				as message_type_id 
						, @EmailSubject		as  message_subject 
						, @EmailBody		as message_descr
						, GETUTCDATE()		as message_date
						, NULL				as from_contact_id 
						, @ContactId		as to_contact_id 
						, 0					as message_sent
						, 0					as message_read
						, 1					as trash
						, 0					as from_trash
						, 0					as real_from_cont_id
						, 0					as is_last_message
						, 0					as message_status_id_recipient
						, 0					as message_status_id_author
						, @IsNdaRequired
					SET @MessageId = @@identity

					INSERT INTO mp_message_file (MESSAGE_ID, [FILE_ID])
					SELECT @MessageId , @MessageFileId 

					INSERT INTO mp_lead_message_mapping (lead_id, message_id)
					SELECT @LeadId ,@MessageId 
					
				END

				UPDATE mpCommunityExternalDirectoryMessages SET IsClaimed = 1 WHERE Id = @Id

			FETCH NEXT FROM crCommunityExternalDirectoryMessages INTO @Id,@BuyerEmail,@BuyerFirstName,@BuyerLastName,@BuyerCompanyName,@BuyerPhone,@MessageFileId,@EmailSubject,@EmailBody,@IpAddress,@EmailMessageDate,@IsNdaRequired ;
			END;

			CLOSE crCommunityExternalDirectoryMessages;
			DEALLOCATE crCommunityExternalDirectoryMessages;
		
		END
		
		-- Reteriving & Inserting Community LeadStream data if exists in relevant tables
		IF @IsCommunityLeadStreamExists > 0
		BEGIN

			INSERT INTO mp_lead
			(company_id , lead_source_id , lead_from_contact , ip_address , lead_date)
			
			SELECT @CompanyId , a.LeadSourceId , CASE WHEN c.contact_id IS NULL THEN 0 ELSE c.contact_id END  ,CASE WHEN c.contact_id IS NULL THEN a.IpAddress ELSE '' END , LeadDate
			FROM mpCommunityLeadStream (NOLOCK) a
			LEFT JOIN AspNetUsers (NOLOCK) b ON a.BuyerEmail = b.Email
			LEFT JOIN mp_contacts (NOLOCK) c ON b.id = c.[user_id]
			WHERE a.SupplierEmail = @EmailId AND a.IsClaimed = 0

			UPDATE mpCommunityLeadStream SET IsClaimed = 1 WHERE SupplierEmail = @EmailId AND IsClaimed = 0
		END

	SET @TransactionStatus = 'Success'
	SELECT @TransactionStatus TransactionStatus

	COMMIT
	END TRY
	BEGIN CATCH
	
		
		ROLLBACK
		
		SET @TransactionStatus = 'Failed - ' + ERROR_MESSAGE()
		SELECT @TransactionStatus TransactionStatus
		

	END CATCH
END
