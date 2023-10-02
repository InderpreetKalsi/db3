
/*
exec proc_get_CompanyProfileManagementSettings  @CompanyId = 1767999 , @PaidStatus = 'Basic'
exec proc_get_CompanyProfileManagementSettings  @CompanyId = 1767999 , @PaidStatus = 'Silver'
exec proc_get_CompanyProfileManagementSettings  @CompanyId = 1767999 , @PaidStatus = 'Gold'
exec proc_get_CompanyProfileManagementSettings  @CompanyId = 1767999 , @PaidStatus = 'Platinum'
*/

CREATE PROCEDURE [dbo].[proc_get_CompanyProfileManagementSettings]
(
	@CompanyId	INT
	,@PaidStatus	VARCHAR(50)
)
AS
BEGIN

	-- M2-3764 Vision - Profile management drawer to turn sections on and off-DB

	SET NOCOUNT ON

	DECLARE  @ProfileManagementSettings VARCHAR(1000) = (SELECT ProfileSettings FROM mpCompanyProfileManagementSettings (NOLOCK) WHERE CompanyId = @CompanyId)
	DECLARE  @IsHideDirectoryProfile BIT = (SELECT CAST (ISNULL(is_hide_directory_profile,0) AS BIT)  FROM mp_companies (NOLOCK) WHERE company_id = @CompanyId)


	CREATE TABLE #tmpProfileManagementSettings 
	(
		Event	VARCHAR(250)
	)

	IF @PaidStatus = 'Basic'
	BEGIN
		 
		INSERT INTO #tmpProfileManagementSettings 
		SELECT value FROM mp_system_parameters WHERE sys_key  = '@CONFIGURE_PROFILE_BASIC'

	END
	ELSE IF @PaidStatus = 'Silver'
	BEGIN
		
		INSERT INTO #tmpProfileManagementSettings 
		SELECT value FROM mp_system_parameters WHERE sys_key  = '@CONFIGURE_PROFILE_SILVER'

	END
	ELSE IF @PaidStatus = 'Gold'
	BEGIN
		
		INSERT INTO #tmpProfileManagementSettings 
		SELECT value FROM mp_system_parameters WHERE sys_key  = '@CONFIGURE_PROFILE_GOLD'

	END
	ELSE IF @PaidStatus = 'Platinum'
	BEGIN

				
		INSERT INTO #tmpProfileManagementSettings 
		SELECT value FROM mp_system_parameters WHERE sys_key  = '@CONFIGURE_PROFILE_PLATINUM'
	
	END

	--INSERT INTO #tmpProfileManagementSettings VALUES ('HideProfile'), ('Ads'),('Badges'),('Capabilities'),('Claim My Profile'),('Company Details'),('Contact'),('Description'),('Edit My Profile'),('Equipment'),('Gallery'),('Message'),
	--('Reviews'),('RFQ History'),('Simple RFQ'),('Tags')

	SELECT 
		a.Event
		, CASE 
			WHEN @ProfileManagementSettings IS NULL THEN 
				CASE WHEN a.Event = 'HideProfile' THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END
			WHEN @ProfileManagementSettings IS NOT NULL THEN 
				CASE WHEN a.Event = b.Value THEN CAST (1 AS BIT) ELSE CAST(0 AS BIT) END
		  END AS ProfileSetting
	FROM #tmpProfileManagementSettings a
	LEFT JOIN (SELECT Value FROM STRING_SPLIT(@ProfileManagementSettings , ','))   b ON a.Event = b.value
	--ORDER BY a.Event
	

END
