
/*
EXEC [proc_set_message_threads_to_unread] @MessageId =19193161
*/
CREATE PROCEDURE [dbo].[proc_set_message_threads_to_unread]
(
	@MessageId INT
)
AS
BEGIN

	SET NOCOUNT ON 
	
	
	DECLARE @FromCont			INT
	DECLARE @ToCont				INT
	DECLARE @MessageTypeId		INT
	DECLARE @MessageSubject		NVARCHAR(2000)
	DECLARE @MessageMinId		INT
	DECLARE @MessageMaxId		INT


	DROP TABLE IF EXISTS #tmp_messages 

	/* Nov 16 2021 - We are comment below code as there is no need of this sp. We will check the functionality after Sprint 6.4 release and if all seems look good then we will remove it from application  */
	--SELECT 
	--	@FromCont			= from_cont
	--	,@ToCont			= to_cont
	--	,@MessageTypeId		= message_type_id
	--	,@MessageSubject	= message_subject
	--FROM mp_messages (NOLOCK)
	--WHERE message_id = @MessageId


	----SELECT *
	----FROM mp_messages  (NOLOCK)
	----WHERE message_subject = @MessageSubject
	------AND message_type_id = @MessageTypeId
	----AND to_cont = @ToCont
	----AND from_cont = @FromCont
	----UNION
	----SELECT *
	----FROM mp_messages  (NOLOCK)
	----WHERE message_subject = @MessageSubject
	------AND message_type_id = @MessageTypeId
	----AND to_cont = @FromCont 
	----AND from_cont = @ToCont


	--SELECT message_id INTO #tmp_messages
	--FROM mp_messages  (NOLOCK)
	--WHERE message_subject = @MessageSubject
	----AND message_type_id = @MessageTypeId
	--AND to_cont = @ToCont
	--AND from_cont = @FromCont
	--UNION
	--SELECT message_id
	--FROM mp_messages  (NOLOCK)
	--WHERE message_subject = @MessageSubject
	----AND message_type_id = @MessageTypeId
	--AND to_cont = @FromCont 
	--AND from_cont = @ToCont
	
	--SELECT 
	--	@MessageMinId = MIN(message_id)
	--	,@MessageMaxId = MAX(message_id)
	--FROM #tmp_messages

	--UPDATE mp_messages SET message_read = 0 WHERE message_id in (@MessageMinId,@MessageMaxId)

	--DROP TABLE IF EXISTS #tmp_messages 

END
