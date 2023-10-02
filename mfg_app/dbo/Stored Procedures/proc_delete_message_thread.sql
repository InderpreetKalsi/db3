



/*
DROP PROCEDURE [proc_delete_message_thread]

EXEC [proc_delete_message_thread]
*/
CREATE procedure [dbo].[proc_delete_message_thread]
(
  @ContactId INT
  ,@messageIds as [tbltype_ListOfArchievedMessageIds] readonly
)
AS 
BEGIN

	/* M2-4238 DB - If we delete the message or notification on buyer's page, same message gets deleted from supplier's page as well and Vice versa.*/
	
	SET NOCOUNT ON
	
	BEGIN TRY   

		/* M2-4238 DB - If we delete the message or notification on buyer's page, same message gets deleted from supplier's page as well and Vice versa.*/
		
		--UPDATE mp_messages SET Trash = 1 ,trash_date = GETUTCDATE(),from_trash = 1,from_trash_date = GETUTCDATE() 
		--where message_id IN (SELECT MessageId  FROM @messageIds)

		INSERT INTO mpArchivedMessages (ParentMessageId ,MessageId ,ArchieveDate ,ArchievedBy)
		SELECT [ParentMessageId] ,[MessageId] ,GETUTCDATE() , @ContactId  FROM @messageIds 
		

		/**/
		SELECT 'Success' AS status
	
	
	END TRY
	BEGIN CATCH
		SELECT 'Faliure: ' + ERROR_MESSAGE() AS  status
	END CATCH
END
