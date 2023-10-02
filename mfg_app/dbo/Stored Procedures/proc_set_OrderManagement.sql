
/*

select * delete from mpOrderManagement  where rfqid = 1190600

EXEC proc_set_OrderManagement
	@RfqId				= '1190600'
	,@RfqEncryptedId	= '6SUSoy6PBR4/D5A1UEccpg=='
	,@PONumber			= 'PO-1190600-1'
	,@PODate			= '2023-04-15 06:51:23.437'
	,@IsMfgStandardPO	= 0
	,@SupplierContactId	= 1413650
	,@FileName = 'test'

*/
CREATE PROCEDURE [dbo].[proc_set_OrderManagement] 
(
	@RfqId				INT
	,@RfqEncryptedId	NVARCHAR(250)
	,@PONumber			VARCHAR(250)
	,@PODate			DATETIME
	,@IsMfgStandardPO	BIT = 0
	,@FileName			VARCHAR(250)  = null
	,@SupplierContactId	INT

)
AS
BEGIN
	-- M2-4821  Buyer - Award modal Step 2 - DB
	
	DECLARE @FileId INT = NULL
	DECLARE @ContactId INT = NULL
	DECLARE @CompanyId INT = NULL
	DECLARE @AddressId INT = NULL
	DECLARE @PaymentTerm VARCHAR(250) = NULL
	DECLARE @TransactionStatus VARCHAR(50)= 'Failure'
	
	BEGIN TRY
	
		BEGIN TRAN

			
			SELECT @ContactId = contact_id FROM mp_rfq (NOLOCK) WHERE Rfq_Id = @RfqId 
			SELECT @CompanyId = company_id FROM	mp_contacts (NOLOCK) WHERE contact_id = @ContactId 
				

			IF @FileName <> '' AND @FileName IS NOT NULL
			BEGIN

				INSERT INTO mp_special_files
				(	FILE_NAME,CONT_ID,COMP_ID,IS_DELETED,FILETYPE_ID,CREATION_DATE,Imported_Location,parent_file_id
					,Legacy_file_id	,file_title	,file_caption,file_path	,s3_found_status,is_processed,sort_order
				)					 
				SELECT @FileName ,@ContactId ,NULL ,0 ,18 ,GETUTCDATE() ,NULL ,NULL ,NULL ,NULL ,NULL ,NULL
				,NULL ,0 ,NULL    
				SET @FileId = @@IDENTITY

			END
						
			-- if po exists
			IF ((SELECT COUNT(1) FROM mpOrderManagement (NOLOCK) WHERE RfqId = @RfqId )) > 0
			BEGIN
				-- updating existing record for supplier, if other than supplier no action taken
				IF @SupplierContactId NOT IN (16,17,18,20)
				BEGIN

					INSERT INTO [mpOrderManagementChangeLogs]
					([Type] ,OrderManagementId ,RfqId ,PONumber ,PODate ,IsMfgStandardPO ,OldPOStatus ,NewPOStatus ,FileId ,SupplierContactId)
					SELECT 'MFG - Update PO' ,Id ,RfqId ,PONumber ,PODate ,IsMfgStandardPO ,POStatus ,'pending'  ,FileId ,SupplierContactId
					FROM mpOrderManagement (NOLOCK) WHERE RfqId = @RfqId
					
					INSERT INTO mp_data_history
					(field,oldvalue,newvalue,creation_date,userid,tablename)
					SELECT 
						'{"RfqId":'+CONVERT(VARCHAR(50),@RfqId )+'}'
						,'{"POUpdated":""}'
						,'{"POUpdated":"Sent"}' 
						, GETUTCDATE() 
						, @ContactId 
						, 'mpOrderManagement'
					
					INSERT INTO mp_data_history
					(field,oldvalue,newvalue,creation_date,userid,tablename)
					SELECT 
						'{"RfqId":'+CONVERT(VARCHAR(50),@RfqId )+'}'
						,'{"POStatus":"'+POStatus+'"}'
						,'{"POStatus":"pending"}' 
						, GETUTCDATE() 
						, @ContactId 
						, 'mpOrderManagement'
					FROM mpOrderManagement (NOLOCK) WHERE RfqId = @RfqId
					
					UPDATE mpOrderManagement
					SET
						PONumber			= @PONumber 
						,PODate				= @PODate
						,IsMfgStandardPO	= @IsMfgStandardPO 
						,FileId				= @FileId
						,SupplierContactId	= @SupplierContactId
						,ModifiedDate		= GETUTCDATE()
						,IsDeleted = 0
						,POStatus ='pending' 
					WHERE RfqId = @RfqId
					
					SET @TransactionStatus = 'Success'
				END
			
				INSERT INTO tmpOrderManagementflowlogs (RfqId,FlowName,POJSON)
				SELECT @RfqId , 'Update PO data' , '' 
			
			
			END
			-- if po not exists
			ELSE
			BEGIN
			
				SELECT 
					@AddressId = a.address_id 
				FROM 
				mp_company_shipping_site	a (NOLOCK)
				LEFT JOIN mp_addresses		c (NOLOCK) ON a.address_id = c.address_id
				LEFT JOIN mp_mst_country	d (NOLOCK) ON c.country_id = d.country_id
				LEFT JOIN mp_mst_region		e (NOLOCK) ON c.region_id = e.region_id AND e.region_id <> 0
				WHERE a.default_site = 1
				AND a.comp_id IN (@CompanyId)

				SELECT 
					@PaymentTerm = b.description			
				FROM mp_rfq (NOLOCK) a
				LEFT JOIN mp_mst_paymentterm		(NOLOCK)  b ON a.payment_term_id = b.paymentterm_id
				WHERE rfq_id = @RfqId


				IF @SupplierContactId NOT IN (16,17,18,20)
				BEGIN
					INSERT INTO mpOrderManagement
					(RfqId ,RfqEncryptedId ,PONumber ,PODate ,IsMfgStandardPO  ,FileId ,SupplierContactId ,POStatus , ShippingAddressId , PaymentTerm)
					SELECT @RfqId ,@RfqEncryptedId ,@PONumber ,@PODate ,@IsMfgStandardPO ,@FileId ,@SupplierContactId ,'pending'  , @AddressId , @PaymentTerm
					
					INSERT INTO mp_data_history
					(field,oldvalue,newvalue,creation_date,userid,tablename)
					SELECT 
						'{"RfqId":'+CONVERT(VARCHAR(50),@RfqId )+'}'
						,'{"POCreated":""}'
						,'{"POCreated":"Yes"}' 
						, GETUTCDATE() 
						, @ContactId 
						, 'mpOrderManagement'
										
					INSERT INTO mp_data_history
					(field,oldvalue,newvalue,creation_date,userid,tablename)
					SELECT 
						'{"RfqId":'+CONVERT(VARCHAR(50),@RfqId )+'}'
						,'{"POStatus":""}'
						,'{"POStatus":"pending"}' 
						, GETUTCDATE() 
						, @ContactId 
						, 'mpOrderManagement'

					SET @TransactionStatus = 'Success'

					INSERT INTO tmpOrderManagementflowlogs (RfqId,FlowName,POJSON)
					SELECT @RfqId , 'Create PO data' , '' 
				END
			END

		COMMIT TRAN
		SELECT @TransactionStatus AS TransactionStatus 
				
	END TRY
	BEGIN CATCH
		
		ROLLBACK TRAN
		SET @TransactionStatus = 'Failure' + ' - ' + ERROR_MESSAGE()

		INSERT INTO tmpOrderManagementflowlogs (RfqId,FlowName,POJSON)
		SELECT @RfqId , 'Error - Create PO data' , CONVERT(VARCHAR(1000), @TransactionStatus)

		SELECT @TransactionStatus AS TransactionStatus 

	END CATCH
	
		

END
