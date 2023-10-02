/*
DECLARE @DirectoryUntouchedMessages INT
EXEC proc_get_vision_action_tracker_untouched_directory_messages_count @DirectoryUntouchedMessagesCount = @DirectoryUntouchedMessages OUTPUT
SELECT @DirectoryUntouchedMessages
*/
CREATE PROCEDURE [dbo].[proc_get_vision_action_tracker_untouched_directory_messages_count]
(
	@DirectoryUntouchedMessagesCount INT OUTPUT
)
AS
BEGIN

	SET NOCOUNT ON
	-- Jul 08 2020 , M2-3028 Email - Send and email to buyside support when a message with attachment has not been touched for 24 hours - DB


	SET @DirectoryUntouchedMessagesCount = 
	(
		SELECT COUNT(1) AS DirectoryUntouchedMessagesCount
		FROM mp_lead  (NOLOCK) a
		JOIN mp_lead_email_mappings (NOLOCK) b ON a.lead_id = b.lead_id
		WHERE a.lead_source_id in  (6,13) AND  a.status_id IS NULL
		AND a.lead_from_contact NOT IN 
		(	
			1336138,
			1343670,
			1343671,
			1343672,
			1343673
		)
		AND a.company_id NOT IN  (1767788,1775055)
	)

END


