
-- EXEC proc_get_CommunityCompanyProfileURL @CompanyId = 1582479

CREATE PROCEDURE [dbo].[proc_get_CommunityCompanyProfileURL]
(
	@CompanyId	INT
)
AS
BEGIN
	-- M2-3592 Redirect View Full Profile link to the directory profiles
	
	SET NOCOUNT ON


	DROP TABLE IF EXISTS #tmp_CommunityCompanyProfileURL_Adddress
	DROP TABLE IF EXISTS #tmp_CommunityCompanyProfileURL_Companies

	DECLARE @EnvironmentURL VARCHAR(500) 

	IF DB_NAME() = 'mp2020_dev'
	BEGIN
		SET @EnvironmentURL = 'https://dev.mfg.com/manufacturer/'
	END
	ELSE IF DB_NAME() = 'mp2020_uat'
	BEGIN
		SET @EnvironmentURL = 'https://staging.mfg.com/manufacturer/'		
	END
	ELSE IF DB_NAME() = 'mp2020_prod'
	BEGIN
		SET @EnvironmentURL = 'https://mfg.com/manufacturer/'
	END


	-- fetching company details
	SELECT a.company_id , a.name
	INTO #tmp_CommunityCompanyProfileURL_Companies
	FROM mp_companies				(NOLOCK) a
	WHERE a.company_id = @CompanyId


	-- fetching supplier address
	SELECT
		a.company_id AS CompanyId
		,CASE WHEN LEN(ISNULL(c.address4,'')) = 0 THEN '' ELSE REPLACE(c.address4,'?','')  END AS City
		,CASE WHEN LEN(ISNULL(e.REGION_NAME,'')) = 0 THEN '' ELSE e.REGION_NAME  END AS State
	INTO #tmp_CommunityCompanyProfileURL_Adddress
	FROM #tmp_CommunityCompanyProfileURL_Companies	 a
	JOIN 
	(
		SELECT 
			company_id , contact_id , first_name , last_name , is_buyer , address_id, IsTestAccount , [user_id] 
			, ROW_NUMBER() OVER(PARTITION BY company_id ORDER BY company_id , is_admin DESC, contact_id ) rn 
		FROM mp_contacts		(NOLOCK) 
		WHERE is_buyer =0 
	) b ON a.company_id = b.company_id and b.rn=1
	LEFT JOIN mp_addresses			c (NOLOCK) ON b.address_id = c.address_id
	LEFT JOIN mp_mst_country		d (NOLOCK) ON c.country_id = d.country_id
	LEFT JOIN mp_mst_region			e (NOLOCK) ON c.region_id = e.region_id AND e.region_id <> 0
			
	
	SELECT 	

		@EnvironmentURL
		+ CASE 
			WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(a.name),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
			ELSE ISNULL(REPLACE(REPLACE(REPLACE(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(dbo.removespecialchars(a.name))),' ','-'),'__','-'),'___','-') ),'--','-'),'---','-'),'----','-'),'-----','-'),'') + '-' 
		  END 
		+ CASE 
			WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(a.name),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
			WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(c.City),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
			ELSE ISNULL(REPLACE(REPLACE(REPLACE(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(dbo.removespecialchars(c.City))),' ','-'),'__','-'),'___','-') ),'--','-'),'---','-'),'----','-'),'-----','-'),'') +  '-'
			END 
		+ CASE 
			WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(a.name),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
			WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(c.State),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
			ELSE ISNULL(REPLACE(REPLACE(REPLACE(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(dbo.removespecialchars(c.State))),' ','-'),'__','-'),'___','-') ),'--','-'),'---','-'),'----','-'),'-----','-'),'')  +  '-'
			END
		+  CONVERT(VARCHAR(100),a.company_id)  AS CommunityCompanyProfile,
		CASE 
			WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(a.name),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
			ELSE ISNULL(REPLACE(REPLACE(REPLACE(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(dbo.removespecialchars(a.name))),' ','-'),'__','-'),'___','-') ),'--','-'),'---','-'),'----','-'),'-----','-'),'') + '-' 
		  END 
		+ CASE 
			WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(a.name),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
			WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(c.City),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
			ELSE ISNULL(REPLACE(REPLACE(REPLACE(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(dbo.removespecialchars(c.City))),' ','-'),'__','-'),'___','-') ),'--','-'),'---','-'),'----','-'),'-----','-'),'') +  '-'
			END 
		+ CASE 
			WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(a.name),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
			WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(c.State),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
			ELSE ISNULL(REPLACE(REPLACE(REPLACE(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(dbo.removespecialchars(c.State))),' ','-'),'__','-'),'___','-') ),'--','-'),'---','-'),'----','-'),'-----','-'),'')  +  '-'
			END
		+  CONVERT(VARCHAR(100),a.company_id)  AS ProfileDetailUrl
	FROM #tmp_CommunityCompanyProfileURL_Companies  a (NOLOCK)
	LEFT JOIN #tmp_CommunityCompanyProfileURL_Adddress	c (NOLOCK) ON a.company_id = c.CompanyId

END
