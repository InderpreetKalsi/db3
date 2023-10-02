-- EXEC proc_get_ActionTrackerManufacturerBadgeCount  @Assigned_SourcingAdvisor = 0
CREATE PROCEDURE [dbo].[proc_get_ActionTrackerManufacturerBadgeCount]
(@Assigned_SourcingAdvisor int = null )
AS
BEGIN
	SET NOCOUNT ON 
	DECLARE @NewProfilePendingCount INT ,@VideoPendingCount INT
	DROP TABLE IF EXISTS #tmpCount
	CREATE TABLE #tmpCount ( id INT IDENTITY(1,1), NewProfilePendingCount INT null , VideoPendingCount INT null )
	INSERT INTO #tmpCount VALUES (0,0)


	-- M2-3882 Vision - New Profile Review tab for action tracker - DB
	SELECT @NewProfilePendingCount = COUNT(1) -- NewProfilePendingCount 
	FROM mpCompanyPublishProfileLogs (NOLOCK) a
	INNER JOIN mp_companies (NOLOCK)m ON a.CompanyId = m.company_id
	INNER JOIN mp_contacts (NOLOCK)c ON c.contact_id = m.Assigned_SourcingAdvisor
	WHERE 
	a.PublishProfileStatusId = 232 AND a.IsApproved IS NULL
	/* M2-4193 Vision Action Tracker -Match new profile counter according to owner selection-DB*/
	AND c.contact_id = CASE WHEN @Assigned_SourcingAdvisor IS NULL OR  @Assigned_SourcingAdvisor = 0  THEN c.contact_id ELSE @Assigned_SourcingAdvisor END
	
	---M2-4577  Count Badge for videos in action Tracker - API
	SELECT @VideoPendingCount = COUNT(1) --VideoPendingCount 
	FROM mpUserProfileVideoLinks(nolock)
	WHERE isdeleted = 0
	AND IsLinkVisionAccepted IS NULL

	UPDATE #tmpCount
    SET NewProfilePendingCount   = @NewProfilePendingCount
    ,VideoPendingCount = @VideoPendingCount


    SELECT NewProfilePendingCount, VideoPendingCount FROM #tmpCount
	 	 
	
END
