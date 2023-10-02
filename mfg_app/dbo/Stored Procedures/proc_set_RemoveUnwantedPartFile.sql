
-- EXEC proc_set_RemoveUnwantedPartFile  @RfqPartId = '54183'
CREATE PROCEDURE [dbo].[proc_set_RemoveUnwantedPartFile]
(
	@RfqPartId INT
)
AS
BEGIN
	/*
		Date	: Apr 07 2022
		Reason  : Remove unwanted part file from Rfq for ticket M2-4352 Buyer - Modify Step 1 of the RFQ process - UI   
	*/
	
	SET NOCOUNT ON 

	DECLARE @FileId	INT
	DECLARE @TransactionStatus	VARCHAR(10) = 'Success'

	BEGIN TRY
		BEGIN TRAN
		
		DELETE a
		FROM mp_rfq_parts_file	(NOLOCK) a
		JOIN mp_special_files	(NOLOCK) b ON a.file_id = b.file_id
		WHERE rfq_part_id = @RfqPartId
		AND b.file_name = 'New Part'

		SET @FileId  = (SELECT MIN(file_id) FROM mp_rfq_parts_file	(NOLOCK) a WHERE rfq_part_id = @RfqPartId AND status_id = 2)

		UPDATE mp_rfq_parts_file SET is_primary_file = 1 WHERE rfq_part_id = @RfqPartId AND file_id = @FileId AND status_id = 2

		COMMIT
		SELECT @TransactionStatus AS TransactionStatus
	END TRY
	BEGIN CATCH
		ROLLBACK

		SELECT 'Fail' AS TransactionStatus
	END CATCH 
END