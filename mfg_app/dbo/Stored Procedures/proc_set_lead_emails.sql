
/*
declare @p3 dbo.tbltype_lead_emails
insert into @p3 values(N'Inder',N'Kalsi',N'Kalsi',N'ikalsi@delaplex.com',N'99626197776',N'Testing Directory Messages',N'Testing....',NULL,0)

select * from @p3
exec proc_set_lead_emails @lead_id=485743,@supplier_id=1369657,@lead_emails=@p3

*/

CREATE PROCEDURE [dbo].[proc_set_lead_emails]
(
	 @lead_id		INT
	,@supplier_id	INT
	,@lead_emails	AS tbltype_lead_emails	READONLY

)
AS
BEGIN

	/*
		CREATE	:	MAR 11, 2020
		DESC	:	M2-2722 M - Make Read my message clickable on Leadstream - DB
					MAY 12 2020 , M2-2649 Supplier Profile (Non-Registered Users) - Ability to add part files and request NDA - DB
	*/

	DECLARE @transaction_status		VARCHAR(500) = 'Failed'
	DECLARE @lead_email_message_id	INT
	DECLARE @identity_msg INT;
	DECLARE @RowNo INT = 1
	DECLARE @IndividualFileName VARCHAR(MAX)
	DECLARE @FileId INT
	DECLARE @FilesForSplit VARCHAR(MAX)
	/* M2-4010 M - for directory messages, simple, direct RFQ's CC children and add it to their messages -API */
	DECLARE @notification_message_running_id  TABLE (id int IDENTITY(1,1) ,  message_id INT null)
	DECLARE @CompanyId INT = (SELECT DISTINCT company_id FROM mp_contacts (NOLOCK) WHERE contact_id = @supplier_id)
	/**/

	/* M2-4094 Buyer - Add Directory message to the buyer's global messages */
	--DECLARE @plead_from_contact INT;
	--WAITFOR DELAY '00:00:02'
	--SELECT @plead_from_contact = IIF(lead_from_contact = 0, 0, lead_from_contact) FROM mp_lead WHERE lead_id = @lead_id
	/* */


	DROP TABLE IF EXISTS #FileTable

	BEGIN TRAN
	BEGIN TRY

			IF ((SELECT COUNT(1) FROM @lead_emails) > 0)
			BEGIN

				INSERT INTO mp_lead_emails
				(first_name, last_name, company, email, phoneno, email_subject, email_message)
				SELECT first_name, last_name, company, email, phoneno, email_subject, email_message FROM @lead_emails
				SET @lead_email_message_id = @@IDENTITY

				IF @lead_email_message_id  > 0
				BEGIN
				
					INSERT INTO mp_lead_email_mappings (lead_id,lead_email_message_id)
					SELECT @lead_id , @lead_email_message_id

					SET @transaction_status = 'Success' 

				END

				SET @FilesForSplit = (SELECT Files FROM @lead_emails)

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
					, 225						as message_type_id 
					, email_subject				as message_subject 
					, email_message				as message_descr
					, GETUTCDATE()				as message_date
					, (SELECT ISNULL(lead_from_contact,0) FROM mp_lead WHERE lead_id = @lead_id)		as from_contact_id 
					, b.contact_id				as to_contact_id 
					, 0							as message_sent
					, 0							as message_read
					, 1							as trash
					, 0							as from_trash
					, 0							as real_from_cont_id
					, 0							as is_last_message
					, 0							as message_status_id_recipient
					, 0							as message_status_id_author
					, [is_nda_required]
				FROM @lead_emails a
				CROSS APPLY (SELECT contact_id FROM mp_contacts (NOLOCK) WHERE company_id = @CompanyId ) b
				--SET @identity_msg = @@identity
		 
				
				/* M2-4010 M - for directory messages, simple, direct RFQ's CC children and add it to their messages -API */
				IF (SELECT COUNT(1) FROM @notification_message_running_id) > 0 -- @identity_msg > 0
				/*  */
				BEGIN
									
					/* M2-3928 M - Remove attachment requirement for a directory message to show under global "messages". - DB */
					IF LEN(@FilesForSplit) > 0
					BEGIN			 
						SELECT ROW_NUMBER() OVER(ORDER BY value ASC) AS RowNo , value 
						INTO #FileTable 
						FROM 
						(
							SELECT value FROM STRING_SPLIT(@FilesForSplit, ',')

						) AS MessageFileDetailList  				 


						WHILE (@RowNo <= (SELECT COUNT(*) FROM #FileTable))
						BEGIN 
							SET  @IndividualFileName = (SELECT value FROM #FileTable WHERE RowNo = @RowNo);
	 
							INSERT INTO mp_special_files
							(	FILE_NAME,CONT_ID,COMP_ID,IS_DELETED,FILETYPE_ID,CREATION_DATE,Imported_Location,parent_file_id
								,Legacy_file_id	,file_title	,file_caption,file_path	,s3_found_status,is_processed,sort_order
							)					 
							SELECT @IndividualFileName ,NULL ,NULL ,0 ,57 ,GETUTCDATE() ,NULL ,NULL ,NULL ,NULL ,NULL ,NULL
							,NULL ,0 ,NULL    
							SET @FileId = @@IDENTITY
					
							INSERT INTO mp_message_file ( MESSAGE_ID, [FILE_ID])
							/* M2-4010 M - for directory messages, simple, direct RFQ's CC children and add it to their messages -API */
							--SELECT @identity_msg , @FileId 
							SELECT message_id , @FileId FROM @notification_message_running_id
							/**/

						SET @RowNo = @RowNo + 1;
						END	
					END
					/**/
				
					INSERT INTO mp_lead_message_mapping (lead_id, message_id)
					/* M2-4010 M - for directory messages, simple, direct RFQ's CC children and add it to their messages -API */
					--SELECT @lead_id ,@identity_msg 
					SELECT @lead_id , message_id FROM @notification_message_running_id
					/**/
				
				END
			END


	SET @transaction_status = 'Success'
	
	COMMIT
			
	SELECT @transaction_status TransactionStatus


	END TRY
	BEGIN CATCH
		ROLLBACK
		
		SET @transaction_status = 'Failed - ' + error_message()
		SELECT @transaction_status TransactionStatus
	END CATCH

END
