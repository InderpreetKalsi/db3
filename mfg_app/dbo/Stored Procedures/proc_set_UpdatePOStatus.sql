﻿
/*

select * from mpOrderManagement (nolock) where rfqid = 1195364 order by id desc 
select * from mpOrderManagementStatusChangeLogs(nolock)

EXEC proc_set_Reshape_UpdatePOStatus @poMfgUniqueId = 100005 , @poStatus = 'Approved'  , @poTransactionId =  'E6241F8E-ADB8-40EF-9809-7F4900B378C8'
 
*/
CREATE PROCEDURE [dbo].[proc_set_UpdatePOStatus]
(
	 @poMfgUniqueId      INT
	,@poStatus           VARCHAR(100) 
	,@poTransactionId    VARCHAR(255)
	
)
AS
BEGIN
	-- M2-4849 Create new external facing API for Order Management - DB
	SET NOCOUNT ON

	BEGIN TRY
		BEGIN TRAN
			-- if po exists then update the po status from reshape 
			IF ( SELECT COUNT(1) FROM mpOrderManagement(NOLOCK) WHERE Id = @poMfgUniqueId AND TransactionId = @poTransactionId ) > 0
			BEGIN
	
				INSERT INTO [mpOrderManagementChangeLogs]
				([Type] ,OrderManagementId ,RfqId ,PONumber ,PODate ,IsMfgStandardPO ,OldPOStatus ,NewPOStatus ,FileId ,SupplierContactId)
				SELECT 'MFG - update PO status' ,Id ,RfqId ,PONumber ,PODate ,IsMfgStandardPO ,POStatus ,@poStatus ,FileId ,SupplierContactId
				FROM mpOrderManagement (NOLOCK) WHERE Id = @poMfgUniqueId
											   
				Update mpOrderManagement
				SET 
					POStatus = @poStatus
					,ModifiedDate = GETUTCDATE()
				WHERE Id = @poMfgUniqueId AND TransactionId = @poTransactionId 

			END
		
		COMMIT TRAN
		SELECT TransactionStatus  = 'Success'

	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
		SELECT TransactionStatus  = 'Failure ' + ERROR_MESSAGE()
	END CATCH

END
