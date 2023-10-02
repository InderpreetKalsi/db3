
/*
DECLARE @p25 dbo.tbltype_sale_activities
insert into @p25 values
(NULL, NULL, 'I’m interested in purchasing one of your products', NULL)
,(6, '1234567890',  NULL, NULL)

EXEC proc_set_sale_activities @SupplierId = 1369666 , @SaleActivitiess=@p25 

GO

DECLARE @p25 dbo.tbltype_sale_activities
insert into @p25 values
(NULL, NULL, 'I want to learn more about a product feature', NULL)
,(7, 'ikalsi@yopmail.com',  'Contact ASAP', NULL)

EXEC proc_set_sale_activities @SupplierId = 1369666 , @SaleActivitiess=@p25 

GO

DECLARE @p25 dbo.tbltype_sale_activities
insert into @p25 values
(NULL, NULL, 'I have a question about product pricing')
,(8, NULL, NULL, '2020-04-02 07:57:59.973')

EXEC proc_set_sale_activities @SupplierId = 1369666 , @SaleActivitiess=@p25 

GO
SELECT TOP 20 * FROM mp_track_user_activities ORDER BY user_activity_id DESC
*/

CREATE PROCEDURE [dbo].[proc_set_sale_activities]
(
	@SupplierId			INT 
	,@SaleActivitiess	AS tbltype_sale_activities	READONLY
)
AS
BEGIN

	-- M2-2741 M - Contact sales modal - Call me -DB
	-- M2-2744 M - Contact Sales modal - Schedule an appointment - DB
	
	DECLARE @TransactionStatus		VARCHAR(500) = 'Failed'

	BEGIN TRAN
	BEGIN TRY

			IF ((SELECT COUNT(1) FROM @SaleActivitiess) > 0)
			BEGIN

				INSERT INTO mp_track_user_activities
				([contact_id],  [activity_id], [Value], [Comment] , [ScheduledDate])
				SELECT @SupplierId, ISNULL([Id],9) , [Value], [Comment] , [ScheduledDate]  FROM @SaleActivitiess

				SET @TransactionStatus = 'Success' 		
			END

			IF @TransactionStatus = 'Success'
				COMMIT
			ELSE
				ROLLBACK

			SELECT @TransactionStatus TransactionStatus

	END TRY
	BEGIN CATCH
		ROLLBACK
		
		SET @TransactionStatus = 'Failed - ' + Error_Message()
		SELECT @TransactionStatus TransactionStatus

	END CATCH

END
