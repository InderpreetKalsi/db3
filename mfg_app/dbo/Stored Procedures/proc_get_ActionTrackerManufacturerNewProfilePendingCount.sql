-- EXEC proc_get_ActionTrackerManufacturerNewProfilePendingCount  @Assigned_SourcingAdvisor = 0
CREATE PROCEDURE [dbo].[proc_get_ActionTrackerManufacturerNewProfilePendingCount]
(@Assigned_SourcingAdvisor int = null )
AS
BEGIN

	-- M2-3882 Vision - New Profile Review tab for action tracker - DB
	SET NOCOUNT ON 

	SELECT COUNT(1) NewProfilePendingCount 
	FROM mpCompanyPublishProfileLogs (NOLOCK) a
	INNER JOIN mp_companies (NOLOCK)m ON a.CompanyId = m.company_id
	INNER JOIN mp_contacts (NOLOCK)c ON c.contact_id = m.Assigned_SourcingAdvisor
	WHERE 
	a.PublishProfileStatusId = 232 AND a.IsApproved IS NULL
	/* M2-4193 Vision Action Tracker -Match new profile counter according to owner selection-DB*/
	AND c.contact_id = CASE WHEN @Assigned_SourcingAdvisor IS NULL OR  @Assigned_SourcingAdvisor = 0  THEN c.contact_id ELSE @Assigned_SourcingAdvisor END
	/**/
	
END
