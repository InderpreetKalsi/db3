
/*

select * from mpOrderManagement WHERE RFQID =1194223 
EXEC proc_set_EditPurchaseOrder
	@POUniqueId 		= 100020
   	,@IsFileExists		= 1
   	,@PONumber      	= 'PO-1194223'
   	,@PODate            = default
   	,@DeliveryDate   	= default
   	,@PaymentTerm       = default
   	,@ShipAddressId     = default
   	,@FileName 			= 'abc.pdf'
select * from mpOrderManagement WHERE RFQID =1194223 

select * from mpOrderManagement WHERE RFQID =1194223 
EXEC proc_set_EditPurchaseOrder
	@POUniqueId 		= 100091
   	,@IsFileExists		= 0
   	,@PONumber      	= 'PO-1162088'
   	,@PODate            = '2023-03-03 11:06:07.713'
   	,@DeliveryDate   	= '2023-03-09 11:06:07.713'
   	,@PaymentTerm       = '4'
   	,@ShipAddressId     = 6089731
   	,@FileName 			= default
select * from mpOrderManagement WHERE RFQID =1194223 

SELECT getutcdate(), * FROM mp_rfq where Rfq_Id = 1162088
SELECT getutcdate(), * FROM mpOrderManagement where RfqId = 1162088
exec proc_set_EditPurchaseOrder @DeliveryDate='2023-03-30 18:30:00',@PaymentTerm=N'4',@ShipAddressId=6089731,@POUniqueId=100091,@IsFileExists=0,@PONumber=N'PO-1162088123',@PODate='2023-03-03 15:00:00'
SELECT getutcdate(), * FROM mpOrderManagement where RfqId = 1162088

*/
CREATE PROCEDURE [dbo].[proc_set_EditPurchaseOrder]
(
    @POUniqueId 		INT                        
    ,@IsFileExists		BIT                        
    ,@PONumber        	VARCHAR(250)         
    ,@PODate            DATETIME = NULL            
    ,@DeliveryDate    	DATETIME = NULL            
    ,@PaymentTerm      	VARCHAR(150) = NULL        
    ,@ShipAddressId    	INT = NULL                
    ,@FileName 			VARCHAR(250)  = NULL    
    ,@Notes             NVARCHAR(4000) = NULL
)
AS
BEGIN

	-- M2-4825
	
	DECLARE @FileId INT = NULL
	DECLARE @ContactId INT = NULL
	DECLARE @TransactionStatus VARCHAR(50)= 'Failure'
	
	BEGIN TRY
		BEGIN TRAN

			SELECT @ContactId = b.contact_id
			FROM mpOrderManagement (NOLOCK) a
			JOIN mp_rfq (NOLOCK) b ON a.RfqId = b.rfq_id
			WHERE Id  = @POUniqueId

			IF  @IsFileExists = 1 
			BEGIN

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

					UPDATE mpOrderManagement
					SET
						PONumber			= @PONumber
						,PODate				= @PODate
						,IsMfgStandardPO	= 0 
						,POStatus			= 'pending'
						,FileId				= @FileId
						,ModifiedBy			= @ContactId
						,ModifiedDate		= GETUTCDATE()
						,Notes              = ISNULL(@Notes ,'')
					WHERE Id  = @POUniqueId	

					SET @TransactionStatus = 'Success'

			END
			ELSE
			BEGIN

					UPDATE mpOrderManagement
					SET
						PONumber				= @PONumber
						,PODate					= @PODate
						,PaymentTerm			= ISNULL(@PaymentTerm,PaymentTerm) 
						,POStatus				= 'pending'
						,ShippingAddressId		= ISNULL(@ShipAddressId,ShippingAddressId)
						,ModifiedBy				= @ContactId
						,ModifiedDate			= GETUTCDATE()
						,Notes                  = ISNULL(@Notes ,'')
					WHERE Id  = @POUniqueId	

					UPDATE b
					SET
						b.DeliveryDate			= @DeliveryDate
					FROM mpOrderManagement (NOLOCK) a
					JOIN mp_rfq (NOLOCK) b ON a.RfqId = b.rfq_id
					WHERE a.Id  = @POUniqueId	

					SET @TransactionStatus = 'Success'

			END

		COMMIT TRAN
		SELECT @TransactionStatus AS TransactionStatus , a.RfqId , a.RfqEncryptedId FROM mpOrderManagement (NOLOCK) a WHERE a.Id  = @POUniqueId

		
		INSERT INTO tmpOrderManagementflowlogs (RfqId,FlowName,POJSON)
		SELECT RfqId ,  'PO edit' , '' 
		FROM mpOrderManagement (NOLOCK) a WHERE a.Id  = @POUniqueId

	END TRY
	BEGIN CATCH
		
		ROLLBACK TRAN
		SET @TransactionStatus = 'Failure' + ' - ' + ERROR_MESSAGE()
		SELECT @TransactionStatus AS TransactionStatus , a.RfqId , a.RfqEncryptedId FROM mpOrderManagement (NOLOCK) a WHERE a.Id  = @POUniqueId

	END CATCH

END
