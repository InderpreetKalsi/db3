--exec proc_get_Buyer_ActionTracker_Untouched_Directory_Messages_Count
CREATE PROCEDURE [dbo].[proc_get_Buyer_ActionTracker_Untouched_Directory_Messages_Count]
AS
BEGIN
	SET NOCOUNT ON 

	-- M2-2990 Vision - Add a counter on the Directory messages tab that shows how many messages have been untouched
	
	SELECT 'Directory Message' AS Type ,COUNT(1) AS DirectoryUntouchedMessagesCount
    FROM mp_lead  (NOLOCK) a
	JOIN mp_lead_email_mappings (NOLOCK) b ON a.lead_id = b.lead_id
	WHERE lead_source_id in  (6,13)  AND  status_id IS NULL
	AND a.lead_from_contact NOT IN 
		(	
			1336138,
			1343670,
			1343671,
			1343672,
			1343673
		)
	AND a.company_id NOT IN  (1767788,1775055)
END
