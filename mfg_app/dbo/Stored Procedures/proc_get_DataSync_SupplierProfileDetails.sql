

/* 

EXEC [proc_get_DataSync_SupplierProfileDetails] @CompanyId = 909492 ,@NextPostId = '731524'

*/
CREATE PROCEDURE [dbo].[proc_get_DataSync_SupplierProfileDetails]
(
	@CompanyId INT
	,@NextPostId VARCHAR(50)
)
AS
BEGIN

 
	
	-- M2-3780  Data Sync for Supplier Directory from MS SQL Server to MySQL
	SET NOCOUNT ON

	DROP TABLE IF EXISTS #tmp_DataSync_SupplierProfileDetails_Capabilities
	DROP TABLE IF EXISTS #tmp_DataSync_SupplierProfileDetails_Adddress
	DROP TABLE IF EXISTS #tmp_DataSync_SupplierProfileDetails_Companies
	DROP TABLE IF EXISTS #tmp_DataSync_SupplierProfileDetails_Reviews
	DROP TABLE IF EXISTS #tmp_DataSync_SupplierProfileDetails_PaidStatus
	DROP TABLE IF EXISTS #tmp_DataSync_SupplierProfileDetails_MfgVerified
	DROP TABLE IF EXISTS #tmp_DataSync_SupplierProfileDetails_Certificates
	/* M2-4024 Data - Sync the directory order */
	DROP TABLE IF EXISTS #tmp_DataSync_SupplierProfileDetails
	/**/
	/* M2-4270 Data - Add Industry Focus and Materials from the M profile to the data sync */
	DROP TABLE IF EXISTS #tmp_DataSync_SupplierProfileDetails_Industries
	/**/

	DECLARE @CompanyLogo				VARCHAR(4000)
	DECLARE @ImageGalleryPath			VARCHAR(4000)
	DECLARE @CompanyBanner				VARCHAR(4000)
	DECLARE @EnvironmentURL				VARCHAR(4000) 
	DECLARE @IsHideProfile				BIT = 0
	/* M2-4059 Vision - Add Spotlight to the data sync - DB*/
	DECLARE @SpotLightRank				INT
	/**/
	DECLARE @CompanyPaidStatus			INT 
	
	IF DB_NAME() = 'mp2020_dev'
	BEGIN

		SET @CompanyLogo = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.public/logos/'
		SET @ImageGalleryPath = 'https://files.mfg.com/RFQFiles/'
		SET @CompanyBanner = 'https://files.mfg.com/RFQFiles/'
		SET @EnvironmentURL = 'https://dev.mfg.com/manufacturer/'
		
	END
	ELSE IF DB_NAME() = 'mp2020_uat'
	BEGIN

		SET @CompanyLogo = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020/logos/'
		SET @ImageGalleryPath = 'https://uatfiles.mfg.com/RFQFiles/'
		SET @CompanyBanner = 'https://uatfiles.mfg.com/RFQFiles/'
		SET @EnvironmentURL = 'https://staging.mfg.com/manufacturer/'	
	END
	ELSE IF DB_NAME() = 'mp2020_prod'
	BEGIN

		SET @CompanyLogo = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.public/logos/'
		SET @ImageGalleryPath = 'https://files.mfg.com/RFQFiles/'
		SET @CompanyBanner = 'https://files.mfg.com/RFQFiles/'
		SET @EnvironmentURL = 'https://mfg.com/manufacturer/'
	END

	/* M2-4412 Note	Following are client provided hard-coded values 
	*/
	begin
			DROP TABLE IF EXISTS  #tmp_materials
			CREATE TABLE #tmp_materials (term_id INT, materials VARCHAR(50))
			INSERT INTO #tmp_materials
			SELECT 25515 as term_id	,'ABS-Like'  as materials UNION 
			SELECT 25516	,'Acrylic'						  UNION 
			SELECT 25517	,'Alloy Steel'					  UNION 
			SELECT 25518	,'Aluminum'						  UNION 
			SELECT 25519	,'Beryllium Copper'				  UNION 
			SELECT 25520	,'Brass'						  UNION 
			SELECT 25521	,'Bronze'						  UNION 
			SELECT 25522	,'Carbon Steel'					  UNION 
			SELECT 25523	,'Ceramic'						  UNION 
			SELECT 25524	,'Cobalt'						  UNION 
			SELECT 25525	,'Copper'						  UNION 
			SELECT 25526	,'Elastomer'					  UNION 
			SELECT 25527	,'Foam'							  UNION 
			SELECT 25528	,'Glass'						  UNION 
			SELECT 25529	,'Graphite'						  UNION 
			SELECT 25530	,'Inconel'						  UNION 
			SELECT 25531	,'Iron'							  UNION 
			SELECT 25532	,'Lead'							  UNION 
			SELECT 25533	,'Magnesium'					  UNION 
			SELECT 25534	,'Metal'						  UNION 
			SELECT 25535	,'Multiple'						  UNION 
			SELECT 25536	,'Nickel'						  UNION 
			SELECT 25537	,'Nylon or Nylon-Like'			  UNION 
			SELECT 25538	,'Other Metal'					  UNION 
			SELECT 25539	,'Other/Misc'					  UNION 
			SELECT 25540	,'PC-Like'						  UNION 
			SELECT 25541	,'Polyurethane'					  UNION 
			SELECT 25542	,'Silicone'						  UNION 
			SELECT 25543	,'Stainless Steel'				  UNION 
			SELECT 25544	,'Thermoplastic'				  UNION 
			SELECT 25545	,'Thermoset'					  UNION 
			SELECT 25546	,'Tin'							  UNION 
			SELECT 25547	,'Titanium'						  UNION 
			SELECT 25548	,'Tool Steel'					  UNION 
			SELECT 25549	,'Tungsten Carbide'				  UNION 
			SELECT 25550	,'Wood'							  UNION 
			SELECT 25551	,'Zinc'							 
	END


	
	DECLARE  @ProfileManagementSettings VARCHAR(1000) = (SELECT ProfileSettings FROM mpCompanyProfileManagementSettings (NOLOCK) WHERE CompanyId = @CompanyId)

	/* M2-4059 Vision - Add Spotlight to the data sync - DB*/
	DECLARE  @Industries VARCHAR(1000) =
	(
		
		SELECT
			STRING_AGG(CONVERT(VARCHAR(50),IndustryBranches_id), ',')
		FROM 
		(
			SELECT DISTINCT
				a.IndustryBranches_id
			FROM mp_company_Industryfocus (NOLOCK)  a
			JOIN mp_mst_industrybranches (NOLOCK) b ON a.IndustryBranches_id = b.IndustryBranches_id AND b.publish = 1
			WHERE company_id = @CompanyId 
		) a
	)

	DECLARE  @Materials VARCHAR(1000) =
	(
		SELECT
			STRING_AGG(CONVERT(VARCHAR(50),Material_id), ',')
		FROM 
		(
			SELECT 
				DISTINCT a.Material_id
				--, ROW_NUMBER() OVER (PARTITION BY  a.Material_id  ORDER BY a.Material_id) -1 Rn
			FROM mp_company_MaterialSpecialties (NOLOCK)  a
			JOIN mp_mst_materials (NOLOCK) b ON a.Material_id = b.material_id
			WHERE company_id = @CompanyId
		) a
	)
	/**/

	SET @IsHideProfile = (SELECT CAST(ISNULL(is_hide_directory_profile,0) AS BIT ) FROM mp_companies (NOLOCK) WHERE company_id = @CompanyId)
	SET @SpotLightRank = ISNULL((SELECT RankPosition FROM mp_spotlight_supplier (NOLOCK) WHERE CompanyId = @CompanyId and is_spotlight_turn_on =1),0)
	
	-- fetching company details
	SELECT *
	INTO #tmp_DataSync_SupplierProfileDetails_Companies
	FROM mp_companies				(NOLOCK) a
	WHERE a.company_id = @CompanyId
	
	-- fetching company reviews
	/* M2-3925 Data Sync - Add ratings review responses to the data sync and push the existing */
	SELECT response_id ,a.created_date ,score , REPLACE(a.comment,'"','') comment  ,  a.created_date cd 
	/* M2-4288 Data Sync - Add Buyer Company Name, Buyer First Name, and Buyer Last Name Initial for ratings / reviews */
	/*M2-5049 : Below two columns are commented */
	--, ISNULL(b.first_name +' '+ LEFT(b.last_name,1) , '') as ratebycontact
	--, ISNULL(c.name, '') as ratebycompany
	/*M2-5049 : Below two columns are modified */
	,(COALESCE(b.[first_name],d.Firstname) + N' ') + COALESCE(b.[last_name], d.LastName) AS ratebycontact
	,COALESCE(c.name,d.SenderCompany,'') as ratebycompany
	/**/
	INTO #tmp_DataSync_SupplierProfileDetails_Reviews
	FROM mp_rating_responses a (NOLOCK)
	LEFT JOIN mp_contacts b (NOLOCK) ON a.from_id = b.contact_id
	LEFT JOIN mp_companies c (NOLOCK) ON b.company_id = c.company_id
	LEFT JOIN [mpcommunityratings] d ON d.id = a.CommunityRatingID  ---- Added with M2-5049
	WHERE to_company_id = @CompanyId  AND score IS NOT NULL
	UNION
	SELECT a.parent_id ,a.created_date ,a.score , REPLACE(a.comment,'"','') comment  , b.created_date cd , '' , ''
	FROM mp_rating_responses (NOLOCK) a
	JOIN (SELECT * FROM mp_rating_responses (NOLOCK) WHERE to_company_id = @CompanyId  AND score  IS NOT NULL) b ON a.parent_id = b.response_id
	ORDER BY  cd DESC , a.response_id DESC, created_date
	/**/

	-- fetching capabilities of supplier
	SELECT DISTINCT 
		b.company_id AS CompanyId , c.discipline_name AS ParentCapabilities 
		, CASE 
				WHEN  a.discipline_name = 'DMLS' THEN 'Direct Metal Laser Sintering (DMLS)' 
				WHEN  a.discipline_name = 'FDM' THEN 'Fused Deposition Modeling (FDM)' 
				WHEN  a.discipline_name = 'MJF' THEN 'Multi-Jet Fusion (MJF)' 
				WHEN  a.discipline_name = 'SLS' THEN 'Selective Laser Sintering (SLS)' 
				WHEN  a.discipline_name = 'SLA' THEN 'Stereolithography (SLA)' 
				WHEN  a.discipline_name = 'EDM' THEN 'Electrical Discharge Machining (EDM)' 
				ELSE  a.discipline_name
		  END AS ChildCapabilities
	INTO #tmp_DataSync_SupplierProfileDetails_Capabilities
	FROM mp_mst_part_category (NOLOCK) a
	JOIN
	(
		SELECT company_id , part_category_id FROM mp_company_processes (NOLOCK) WHERE company_id = @CompanyId
		/* Aug 24 2021 As discussed with Eddie - change in capabiliies logic for data sync process , it will only push profile capabilitie */
		--UNION
		--SELECT company_id , part_category_id FROM mp_gateway_subscription_company_processes  (NOLOCK) WHERE company_id = @CompanyId
		/**/
	) b ON a.part_category_id = b.part_category_id
	JOIN mp_mst_part_category (NOLOCK) c ON a.parent_part_category_id = c.part_category_id 


	-- fetching supplier address
	SELECT
		a.company_id AS CompanyId
		,c.country_id 
		,b.contact_id
		,b.first_name 
		,b.last_name
		,f.email
		----,CASE WHEN LEN(ISNULL(c.address1,'')) = 0 THEN '' ELSE REPLACE(c.address1,'?','')  END AS StreetAddress
		,CASE WHEN LEN(ISNULL(c.address1,'')) = 0 THEN '' ELSE REPLACE(c.address1,'?','') END   
		+CASE WHEN LEN(ISNULL(c.address2,'')) = 0 THEN '' ELSE CASE WHEN LEN(ISNULL(c.address1,'')) != 0 THEN ', ' ELSE '' END + REPLACE(c.address2,'?','') END AS StreetAddress  ---- Added Address2 field in address 
		,CASE WHEN LEN(ISNULL(c.address4,'')) = 0 THEN '' ELSE REPLACE(c.address4,'?','')  END AS City
		,CASE WHEN LEN(ISNULL(e.REGION_NAME,'')) = 0 THEN '' ELSE e.REGION_NAME  END AS State
		,CASE WHEN LEN(ISNULL(c.address3,'')) = 0 THEN '' ELSE c.address3  END AS ZipCode
		,CASE WHEN LEN(ISNULL(d.country_name,'')) = 0  THEN '' ELSE d.country_name END AS Country
	INTO #tmp_DataSync_SupplierProfileDetails_Adddress
	FROM #tmp_DataSync_SupplierProfileDetails_Companies				(NOLOCK) A
	JOIN 
	(
		SELECT 
			company_id , contact_id , first_name , last_name , is_buyer , address_id, IsTestAccount , [user_id] 
			, ROW_NUMBER() OVER(PARTITION BY company_id ORDER BY company_id , is_admin DESC, contact_id ) rn 
		FROM mp_contacts		(NOLOCK) 
		WHERE is_buyer = 0
	) b ON a.company_id = b.company_id and b.rn=1
	LEFT JOIN mp_addresses			c (NOLOCK) ON b.address_id = c.address_id
	LEFT JOIN mp_mst_country		d (NOLOCK) ON c.country_id = d.country_id
	LEFT JOIN mp_mst_region			e (NOLOCK) ON c.region_id = e.region_id AND e.region_id <> 0
	LEFT JOIN aspnetusers			f (NOLOCK) ON b.[user_id] = f.id
	WHERE a.company_id = @CompanyId 

	-- fetching supplier paid status
	SET @CompanyPaidStatus = (SELECT account_type FROM mp_registered_supplier (NOLOCK) WHERE company_id = @CompanyId )

	-- setting supplier verified status
	SELECT  
		@CompanyId AS CompanyId  
		, CASE WHEN @CompanyPaidStatus > 83 THEN 'MFG Verified? Yes' ELSE 'MFG Verified? No' END AS PaidStatus  INTO #tmp_DataSync_SupplierProfileDetails_MfgVerified

	-- setting supplier teir status
	SELECT  
		@CompanyId AS CompanyId  
		, CASE	
				WHEN @CompanyPaidStatus = 85 THEN '03 Gold' 
				WHEN @CompanyPaidStatus = 84 THEN '02 Growth Package'
				WHEN @CompanyPaidStatus = 86 THEN '04 Platinum'
				WHEN @CompanyPaidStatus = 313 THEN '05 Starter' ---- Added with M2-5133
				ELSE '01 Basic' 
		  END AS PaidStatus  INTO #tmp_DataSync_SupplierProfileDetails_PaidStatus

	

	-- fetching certificates for badging
	SELECT   
		TOP  1 LEFT(b.certificate_code,3) AS Certificate
	INTO #tmp_DataSync_SupplierProfileDetails_Certificates
	FROM mp_company_certificates	(NOLOCK) a
	JOIN mp_certificates			(NOLOCK) b ON a.certificates_id = b.certificate_id
	WHERE a.company_id IN
		(
			SELECT company_id 
			FROM #tmp_DataSync_SupplierProfileDetails_Companies		a
			LEFT JOIN #tmp_DataSync_SupplierProfileDetails_PaidStatus k ON a.company_id = k.CompanyId
			WHERE k.PaidStatus IN ('03 Gold' , '02 Growth Package' , '04 Platinum','05 Starter')
		)
		AND 
		(
			LEFT(b.certificate_code,3) = 'ISO'
		)
	UNION
	SELECT   
		TOP  1 LEFT(b.certificate_code,2)  AS Certificate
	FROM mp_company_certificates	(NOLOCK) a
	JOIN mp_certificates			(NOLOCK) b ON a.certificates_id = b.certificate_id
	WHERE a.company_id  IN
		(
			SELECT company_id 
			FROM #tmp_DataSync_SupplierProfileDetails_Companies		a
			LEFT JOIN #tmp_DataSync_SupplierProfileDetails_PaidStatus k ON a.company_id = k.CompanyId
			WHERE k.PaidStatus IN ('03 Gold' , '02 Growth Package' , '04 Platinum','05 Starter')
		)
		AND 
		(
			LEFT(b.certificate_code,2) = 'AS'
		)
	UNION
	SELECT   
		TOP  1 LEFT(b.certificate_code,2)  AS Certificate
	FROM mp_company_certificates	(NOLOCK) a
	JOIN mp_certificates			(NOLOCK) b ON a.certificates_id = b.certificate_id
	WHERE a.company_id  IN
		(
			SELECT company_id 
			FROM #tmp_DataSync_SupplierProfileDetails_Companies		a
			LEFT JOIN #tmp_DataSync_SupplierProfileDetails_PaidStatus k ON a.company_id = k.CompanyId
			WHERE k.PaidStatus IN ('03 Gold' , '02 Growth Package' , '04 Platinum','05 Starter')
		)
		AND 
		(
			LEFT(b.certificate_code,2) = 'QS'
		)

			   
	IF	(@ProfileManagementSettings IS NULL OR @ProfileManagementSettings = '' )
		AND ((SELECT COUNT(1) FROM #tmp_DataSync_SupplierProfileDetails_PaidStatus WHERE PaidStatus = '04 Platinum')>0)
	BEGIN
		SET @ProfileManagementSettings  = (SELECT STRING_AGG([value] , ',') FROM mp_system_parameters WHERE sys_key = '@CONFIGURE_PROFILE_PLATINUM')
	END
	ELSE IF (@ProfileManagementSettings IS NULL OR @ProfileManagementSettings = '' )
			AND ((SELECT COUNT(1) FROM #tmp_DataSync_SupplierProfileDetails_PaidStatus WHERE PaidStatus = '03 Gold')>0)
	BEGIN
		SET @ProfileManagementSettings  = (SELECT STRING_AGG([value] , ',') FROM mp_system_parameters WHERE sys_key = '@CONFIGURE_PROFILE_GOLD')
	END
	ELSE IF (@ProfileManagementSettings IS NULL OR @ProfileManagementSettings = '' ) 
			AND ((SELECT COUNT(1) FROM #tmp_DataSync_SupplierProfileDetails_PaidStatus WHERE PaidStatus = '02 Growth Package')>0)
	BEGIN
		SET @ProfileManagementSettings  = (SELECT STRING_AGG([value] , ',') FROM mp_system_parameters WHERE sys_key = '@CONFIGURE_PROFILE_SILVER')
	END
	----M2-5133
	ELSE IF (@ProfileManagementSettings IS NULL OR @ProfileManagementSettings = '' )
			AND ((SELECT COUNT(1) FROM #tmp_DataSync_SupplierProfileDetails_PaidStatus WHERE PaidStatus = '05 Starter')>0)
	BEGIN
			SET @ProfileManagementSettings  = (SELECT STRING_AGG([value] , ',') FROM mp_system_parameters WHERE sys_key = '@CONFIGURE_PROFILE_STARTER')
	END
	ELSE IF (@ProfileManagementSettings IS NULL OR @ProfileManagementSettings = '' )
			AND ((SELECT COUNT(1) FROM #tmp_DataSync_SupplierProfileDetails_PaidStatus WHERE PaidStatus = '01 Basic')>0)
	BEGIN
		SET @ProfileManagementSettings  = (SELECT STRING_AGG([value] , ',') FROM mp_system_parameters WHERE sys_key = '@CONFIGURE_PROFILE_BASIC')
	END
	ELSE IF (@ProfileManagementSettings IS NULL OR @ProfileManagementSettings = '' )			
	BEGIN
		SET @ProfileManagementSettings  = (SELECT STRING_AGG([value] , ',') FROM mp_system_parameters WHERE sys_key = '@CONFIGURE_PROFILE_BASIC')
	END


	DECLARE  @ProfileManagementSettingscount VARCHAR(1000) =  (SELECT COUNT(1) FROM STRING_SPLIT(@ProfileManagementSettings,',') WHERE [Value] NOT IN ('HideProfile',''))

	/* M2-4059 Vision - Add Spotlight to the data sync - DB*/
	DECLARE  @Industriescount VARCHAR(1000) =  (SELECT COUNT(1) FROM STRING_SPLIT(@Industries,',') )
	DECLARE  @Materialscount VARCHAR(1000) =  (SELECT COUNT(1) FROM STRING_SPLIT(@Materials,','))
	/**/

	/* wp_pmxi_posts */
	SELECT 
		@NextPostId	AS post_id
		, 1				AS import_id
		, @CompanyId	AS unique_key
		, ''			AS product_key
		, 47			AS iteration
		, 0				AS specified

	/* wp_posts */
	SELECT 
		@NextPostId	AS id
		,'7'			AS post_author
		,GETUTCDATE()	AS post_date
		,GETUTCDATE()	AS post_date_gmt
		,''				AS post_content
		,a.name			AS post_title
		,''				AS post_excerpt
		,CASE WHEN @IsHideProfile = 0 THEN 'publish' ELSE 'draft' END		AS post_status
		,'open'			AS comment_status
		,'open'			AS ping_status
		,''				AS post_password
			,CASE 
				WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(a.name),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
				ELSE ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(dbo.removespecialchars(a.name))),' ','-'),'__','-'),'___','-') ),'--','-'),'') + '-' 
			  END 
			+ CASE 
				WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(a.name),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
				WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(c.City),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
				ELSE ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(dbo.removespecialchars(c.City))),' ','-'),'__','-'),'___','-') ),'--','-'),'') +  '-'
				END 
			+ CASE 
				WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(a.name),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
				WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(c.State),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
				ELSE ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(dbo.removespecialchars(c.State))),' ','-'),'__','-'),'___','-') ),'--','-'),'')  +  '-'
				END
			+  CONVERT(VARCHAR(100),a.company_id) AS	post_name
		,''				AS to_ping
		,''				AS pinged
		,GETUTCDATE()	AS post_modified
		,GETUTCDATE()	AS post_modified_gmt
		,''				AS post_content_filtered
		,'0'			AS post_parent
		, @EnvironmentURL
			+ CASE 
				WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(a.name),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
				ELSE ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(dbo.removespecialchars(a.name))),' ','-'),'__','-'),'___','-') ),'--','-'),'') + '-' 
			  END 
			+ CASE 
				WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(a.name),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
				WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(c.City),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
				ELSE ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(dbo.removespecialchars(c.City))),' ','-'),'__','-'),'___','-') ),'--','-'),'') +  '-'
				END 
			+ CASE 
				WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(a.name),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
				WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(c.State),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
				ELSE ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(dbo.removespecialchars(c.State))),' ','-'),'__','-'),'___','-') ),'--','-'),'')  +  '-'
				END
			+  CONVERT(VARCHAR(100),a.company_id)
			+'/' AS guid
		,'0'			AS menu_order
		,'manufacturer' AS post_type
		,''				AS post_mime_type
		,'0'			AS comment_count
	FROM #tmp_DataSync_SupplierProfileDetails_Companies  a (NOLOCK)
	LEFT JOIN #tmp_DataSync_SupplierProfileDetails_Adddress	c (NOLOCK) ON a.company_id = c.CompanyId
	WHERE a.company_id = @CompanyId

	/* wp_yoast_indexable */
	SELECT 
		@EnvironmentURL
			+CASE 
				WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(a.name),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
				ELSE ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(dbo.removespecialchars(a.name))),' ','-'),'__','-'),'___','-') ),'--','-'),'') + '-' 
			  END 
			+ CASE 
				WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(a.name),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
				WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(b.City),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
				ELSE ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(dbo.removespecialchars(b.City))),' ','-'),'__','-'),'___','-') ),'--','-'),'') +  '-'
				END 
			+ CASE 
				WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(a.name),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
				WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(b.State),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
				ELSE ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(dbo.removespecialchars(b.State))),' ','-'),'__','-'),'___','-') ),'--','-'),'')  +  '-'
				END
			+  CONVERT(VARCHAR(100),a.company_id)
			+'/' AS permalink
		,'61:'+CONVERT(VARCHAR(150),REPLACE(NEWID(),'-',''))+'' AS permalink_hash
		,@NextPostId		AS object_id
		,'post'				AS object_type
		,'manufacturer'			AS object_sub_type
		,'7'				AS author_id
		,'0'				AS post_parent
		,a.name 
			+ ' %%sep%% '
			+ CASE 
				WHEN LEN(ISNULL(f.ParentCapabilities,'')) = 0 THEN ''
				WHEN LEN(ISNULL(f.ParentCapabilities,'')) > 0 AND  CHARINDEX(',',f.ParentCapabilities) = 0 THEN  f.ParentCapabilities
				WHEN LEN(ISNULL(f.ParentCapabilities,'')) > 0 AND  CHARINDEX(',',f.ParentCapabilities) > 0 THEN	
					SUBSTRING(f.ParentCapabilities,0,CHARINDEX(',',f.ParentCapabilities))
				ELSE ''
			 END
			+' %%sep%% '
			+ CASE WHEN LEN(ISNULL(b.StreetAddress,'')) = 0 THEN '' ELSE REPLACE(b.StreetAddress,'?','') + ', ' END
			+ CASE WHEN LEN(ISNULL(b.City,'')) = 0 THEN '' ELSE REPLACE(b.City,'?','') + ', ' END
			+ CASE WHEN LEN(ISNULL(b.State,'')) = 0 THEN '' ELSE b.State + ', ' END
			+ CASE WHEN LEN(ISNULL(b.ZipCode,'')) = 0 THEN '' ELSE b.ZipCode + ', ' END
			+ CASE WHEN LEN(ISNULL(b.Country,'')) = 0  THEN '' ELSE b.Country END	
			+' %%sep%% %%sitename%%' AS title
		,a.name+'''s custom manufacturing capabilities include: '
			+ CASE 
				WHEN LEN(ISNULL(f.ParentCapabilities,'')) = 0 THEN ''
				WHEN LEN(ISNULL(f.ParentCapabilities,'')) > 0 THEN  f.ParentCapabilities + space(1) 
				ELSE ''
			  END
			+ '- Find '+a.name+' and more suppliers on the MFG Community!' AS description
		,a.name			AS breadcrumb_title
		,'publish'		AS post_status
		,''				AS is_public
		,'0'			AS is_protected
		,''				AS has_public_posts
		,''				AS number_of_pages
		,''				AS canonical
		,''				AS primary_focus_keyword
		,''				AS primary_focus_keyword_score
		,'0'			AS readability_score
		,'0'			AS is_cornerstone
		,''				AS is_robots_noindex
		,'0'			AS is_robots_nofollow
		,''				AS is_robots_noarchive
		,''				AS is_robots_noimageindex
		,''				AS is_robots_nosnippet
		,a.name+' %%sep%% %%sitename%%'		AS twitter_title
		,''				AS twitter_image
		,'Find '+a.name+' and more suppliers on the MFG Community!' AS twitter_description
		,''				AS twitter_image_id
		,''				AS twitter_image_source
		,a.name+' %%sep%% %%sitename%%'		AS open_graph_title
		,'Find '+a.name+' and more suppliers on the MFG Community!'		AS open_graph_description
		,'/wp-content/uploads/sites/3/2021/01/Banner_Social.png'		AS open_graph_image
		,''				AS open_graph_image_id
		,'set-by-user'	AS open_graph_image_source
		,''				AS open_graph_image_meta
		,'0'			AS link_count
		,''				AS incoming_link_count
		,''				AS prominent_words_version
		,GETUTCDATE()	AS created_at
		,GETUTCDATE()	AS updated_at
		,'3'			AS blog_id
		,''				AS language
		,''				AS region
		,''				AS schema_page_type
		,''				AS schema_article_type
		,'0'			AS has_ancestors
		,''				AS estimated_reading_time_minutes
	FROM #tmp_DataSync_SupplierProfileDetails_Companies  a (NOLOCK)
	LEFT JOIN #tmp_DataSync_SupplierProfileDetails_Adddress b ON a.company_id = b.CompanyId
	LEFT JOIN 
	(
		SELECT CompanyId , STRING_AGG(REPLACE(ParentCapabilities,', ',''),', ') ParentCapabilities
		FROM
		(
			SELECT DISTINCT CompanyId ,  ParentCapabilities FROM #tmp_DataSync_SupplierProfileDetails_Capabilities 
		) a
		GROUP BY CompanyId
		
	) f ON a.company_id = f.CompanyId
	WHERE a.company_id = @CompanyId

	/* wp_term_relationships */
	SELECT
	* 
	FROM 
	(
		SELECT 
			@NextPostId				AS [object_id]
			, ISNULL(c.term_id , 316 )	AS term_taxonomy_id
			, 1							AS term_order
		FROM #tmp_DataSync_SupplierProfileDetails_Companies		a (NOLOCK) 
		LEFT JOIN #tmp_DataSync_SupplierProfileDetails_MfgVerified b ON a.company_id = b.CompanyId 
		LEFT JOIN wp_terms c (NOLOCK) ON ISNULL(b.PaidStatus,'MFG Verified? No') = c.name
		WHERE a.company_id = @CompanyId
		UNION
		SELECT
			@NextPostId	AS [object_id]
			, f.term_id		AS term_taxonomy_id
			, 1				AS term_order
		FROM #tmp_DataSync_SupplierProfileDetails_Companies  a (NOLOCK)
		JOIN 
			(
				SELECT 
					company_id , contact_id , first_name , last_name , is_buyer , address_id, IsTestAccount , [user_id] 
					, ROW_NUMBER() OVER(PARTITION BY company_id ORDER BY company_id , is_admin DESC, contact_id ) rn 
				FROM mp_contacts		(NOLOCK) 
				WHERE is_buyer = 0
			) b ON a.company_id = b.company_id and b.rn=1
		LEFT JOIN mp_addresses			c (NOLOCK) ON b.address_id = c.address_id
		LEFT JOIN mp_mst_country		d (NOLOCK) ON c.country_id = d.country_id
		LEFT JOIN mp_mst_region			e (NOLOCK) ON c.region_id = e.region_id AND e.region_id <> 0
		LEFT JOIN wp_terms				f (NOLOCK) ON d.country_name = f.name
		WHERE a.company_id = @CompanyId
		UNION
		SELECT
			@NextPostId	AS [object_id]
			, f.term_id		AS term_taxonomy_id
			, 1				AS term_order
		FROM #tmp_DataSync_SupplierProfileDetails_Companies  a (NOLOCK)
		JOIN 
			(
				SELECT 
					company_id , contact_id , first_name , last_name , is_buyer , address_id, IsTestAccount , [user_id] 
					, ROW_NUMBER() OVER(PARTITION BY company_id ORDER BY company_id , is_admin DESC, contact_id ) rn 
				FROM mp_contacts		(NOLOCK) 
				WHERE is_buyer = 0
			) b ON a.company_id = b.company_id and b.rn=1
		LEFT JOIN mp_addresses			c (NOLOCK) ON b.address_id = c.address_id
		LEFT JOIN mp_mst_region			e (NOLOCK) ON c.region_id = e.region_id AND e.region_id <> 0
		LEFT JOIN wp_terms				f (NOLOCK) ON e.REGION_NAME = f.name
		WHERE a.company_id = @CompanyId
		UNION
		----Beow code commented with M2-4410
		--SELECT
		--	@NextPostId	AS [object_id]
		--	, f.term_id		AS term_taxonomy_id
		--	, 1				AS term_order
		--FROM #tmp_DataSync_SupplierProfileDetails_Companies  a (NOLOCK)
		--JOIN 
		--	(
		--		SELECT 
		--			company_id , contact_id , first_name , last_name , is_buyer , address_id, IsTestAccount , [user_id] 
		--			, ROW_NUMBER() OVER(PARTITION BY company_id ORDER BY company_id , is_admin DESC, contact_id ) rn 
		--		FROM mp_contacts		(NOLOCK) 
		--		WHERE is_buyer = 0
		--	) b ON a.company_id = b.company_id and b.rn=1
		--LEFT JOIN mp_addresses			c (NOLOCK) ON b.address_id = c.address_id
		--LEFT JOIN wp_terms				f (NOLOCK) ON c.address4 = f.name
		--WHERE a.company_id = @CompanyId	

		---- M2-4410
		SELECT  
		@NextPostId	AS [object_id]
		, f.term_id		AS term_taxonomy_id
		, 1				AS term_order	 
		FROM 
		(
				SELECT  LOWER	(REPLACE(c1, ' ','-'))+'-'+	LOWER(REPLACE(s1, ' ','-'))	as mfg_slug
				from 
				(
					SELECT
						LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(2000),address4) COLLATE Cyrillic_General_CI_AI , ',',''), '.',''), '''',''), '/',''), '(',''), ')',''), '?','')))  c1
						,LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(2000),region_name) COLLATE Cyrillic_General_CI_AI , ',',''), '.',''), '''',''), '/',''), '(',''), ')',''), '?','')))   s1 
						FROM #tmp_DataSync_SupplierProfileDetails_Companies  a (NOLOCK)
						JOIN 
							(
								SELECT 
									company_id , contact_id , first_name , last_name , is_buyer , address_id, IsTestAccount , [user_id] 
									, ROW_NUMBER() OVER(PARTITION BY company_id ORDER BY company_id , is_admin DESC, contact_id ) rn 
								FROM mp_contacts		(NOLOCK) 
								WHERE is_buyer = 0
							) b ON a.company_id = b.company_id and b.rn=1
						LEFT JOIN mp_addresses			c (NOLOCK) ON b.address_id = c.address_id
						LEFT JOIN mp_mst_region (NOLOCK) g on g.region_id = c.region_id 
						WHERE a.company_id = @CompanyId	 
				) mfgcitystate
		) mfgslug
		LEFT JOIN wp_terms	f (NOLOCK) on mfgslug.mfg_slug = f.slug
		UNION
		SELECT
			@NextPostId	AS [object_id]
			, c.term_id		AS term_taxonomy_id
			, 1				AS term_order
		FROM #tmp_DataSync_SupplierProfileDetails_Companies  a (NOLOCK)
		JOIN mp_mst_territory_classification	b (NOLOCK) ON a.manufacturing_location_id = b.territory_classification_id
		JOIN wp_terms							c (NOLOCK) ON (b.territory_classification_name + '-Based Manufacturing') = c.name
		WHERE a.company_id = @CompanyId
		UNION
		SELECT
			@NextPostId	AS [object_id]
			, c.term_id		AS term_taxonomy_id
			, ROW_NUMBER() OVER( ORDER BY c.term_id)	AS term_order
		FROM #tmp_DataSync_SupplierProfileDetails_Companies  a (NOLOCK)
		JOIN (SELECT DISTINCT CompanyId , ParentCapabilities FROM #tmp_DataSync_SupplierProfileDetails_Capabilities)	b  ON a.company_id = b.CompanyId
		JOIN wp_terms							c (NOLOCK) ON REPLACE(REPLACE(b.ParentCapabilities,'&','&amp;'),',','') = c.name
		WHERE a.company_id = @CompanyId
		UNION
		SELECT
			@NextPostId	AS [object_id]
			, c.term_id		AS term_taxonomy_id
			, ROW_NUMBER() OVER( ORDER BY c.term_id)	AS term_order
		FROM #tmp_DataSync_SupplierProfileDetails_Companies  a (NOLOCK)
		JOIN (SELECT DISTINCT CompanyId , ChildCapabilities FROM #tmp_DataSync_SupplierProfileDetails_Capabilities WHERE ParentCapabilities <> ChildCapabilities)	b  ON a.company_id = b.CompanyId
		JOIN wp_terms							c (NOLOCK) ON REPLACE(REPLACE(b.ChildCapabilities,'&','&amp;'),',','') = c.name
		WHERE a.company_id = @CompanyId
		UNION
		SELECT
			@NextPostId	AS [object_id]
			, /* for qa
			  CASE 
				WHEN a.manufacturing_location_id = 2 THEN	16846
				WHEN a.manufacturing_location_id = 3 THEN	16845
				WHEN a.manufacturing_location_id = 4 THEN	16843
				WHEN a.manufacturing_location_id = 5 THEN	16844
				WHEN a.manufacturing_location_id = 6 THEN	16847
			  END
			  */ 
			  
			  CASE 
				WHEN a.manufacturing_location_id = 2 THEN	24986
				WHEN a.manufacturing_location_id = 3 THEN	24984
				WHEN a.manufacturing_location_id = 4 THEN	24988
				WHEN a.manufacturing_location_id = 5 THEN	24985
				WHEN a.manufacturing_location_id = 6 THEN	24987
			  END
			  
			  AS term_taxonomy_id
			, 1 	AS term_order
		FROM #tmp_DataSync_SupplierProfileDetails_Companies  a (NOLOCK) WHERE manufacturing_location_id IN  (2,3,4,5,6) --AND @SpotLightRank BETWEEN 1 AND 10
		UNION ---- New code added with M2-4412		
		SELECT  
			@NextPostId	AS [object_id]
			, d.term_id		AS term_taxonomy_id
			--, 1				AS term_order
			, ROW_NUMBER() OVER( ORDER BY d.term_id)	AS term_order
			FROM #tmp_DataSync_SupplierProfileDetails_Companies  (nolock) a
			join mp_company_MaterialSpecialties (NOLOCK) b on a.company_id = b.company_id
			JOIN mp_mst_materials (NOLOCK) c ON c.Material_id = b.material_id and c.is_active=1
			join wp_terms (nolock) d on d.name = c.material_name_en
			join #tmp_materials e on e.materials = c.material_name_en
			and d.term_id = e.term_id
			WHERE a.company_id = @CompanyId
	) a WHERE term_taxonomy_id IS NOT NULL



	/* wp_postmeta */
	SELECT 
		@NextPostId					AS post_id
		, '_3dshopview'					AS meta_key
		, 'field_6006fd3d981d0'			AS meta_value
	/* M2-4024 Data - Sync the directory order */
    INTO #tmp_DataSync_SupplierProfileDetails
    /**/
	UNION
		SELECT 
			@NextPostId								AS post_id
			, '3dshopview'								AS meta_key
			, ISNULL(REPLACE(m.[3dshopview],'&' ,'&amp;' ),'')		AS meta_value
		FROM #tmp_DataSync_SupplierProfileDetails_Companies  a (NOLOCK)
		LEFT JOIN 
		(
			SELECT company_id ,[3d_tour_url] [3dshopview] , ROW_NUMBER() OVER(PARTITION BY company_id ORDER BY company_id,company_3dtour_id DESC)  RN  
			FROM mp_company_3dtours (NOLOCK) WHERE is_deleted = 0 AND  [3d_tour_url] like '%matterport%'
		) m ON a.company_id = m.company_id AND m.RN = 1 
		WHERE a.company_id = @CompanyId 
	UNION
		SELECT @NextPostId , '_address','field_5fab5ace1f04a' 
	UNION
		SELECT @NextPostId, 'address', 
			CASE WHEN LEN(ISNULL(b.StreetAddress,'')) = 0 THEN '' ELSE REPLACE(b.StreetAddress,'?','') + ', ' END
			+ CASE WHEN LEN(ISNULL(b.City,'')) = 0 THEN '' ELSE REPLACE(b.City,'?','') + ', ' END
			+ CASE WHEN LEN(ISNULL(b.State,'')) = 0 THEN '' ELSE b.State + ', ' END
			+ CASE WHEN LEN(ISNULL(b.ZipCode,'')) = 0 THEN '' ELSE b.ZipCode + ', ' END
			+ CASE WHEN LEN(ISNULL(b.Country,'')) = 0  THEN '' ELSE b.Country END	
		FROM #tmp_DataSync_SupplierProfileDetails_Companies				(NOLOCK) a
		LEFT JOIN #tmp_DataSync_SupplierProfileDetails_Adddress b ON a.company_id = b.CompanyId
		WHERE a.company_id = @CompanyId 
	UNION
		SELECT @NextPostId,'_address_city','field_600c7aaa17d65' 
	UNION
		SELECT @NextPostId,'address_city',CASE WHEN LEN(ISNULL(b.City,'')) = 0 THEN '' ELSE REPLACE(b.City,'?','') END 
		FROM #tmp_DataSync_SupplierProfileDetails_Companies				(NOLOCK) a
		LEFT JOIN #tmp_DataSync_SupplierProfileDetails_Adddress b ON a.company_id = b.CompanyId
		WHERE a.company_id = @CompanyId 
	UNION
		SELECT @NextPostId,'_address_country','field_600c7ac217d66'
	UNION
		SELECT @NextPostId,'address_country',CASE WHEN LEN(ISNULL(b.Country,'')) = 0  THEN '' ELSE b.Country END	
		FROM #tmp_DataSync_SupplierProfileDetails_Companies				(NOLOCK) a
		LEFT JOIN #tmp_DataSync_SupplierProfileDetails_Adddress b ON a.company_id = b.CompanyId
		WHERE a.company_id = @CompanyId 
	UNION
		SELECT @NextPostId,'_address_gps','field_5fda31618b4d7'
	UNION
		SELECT @NextPostId,'address_gps',ISNULL((CONVERT(VARCHAR(100),latitude) +','+CONVERT(VARCHAR(100),longitude)) ,'') 
		FROM #tmp_DataSync_SupplierProfileDetails_Companies				(NOLOCK) a
		LEFT JOIN #tmp_DataSync_SupplierProfileDetails_Adddress b ON a.company_id = b.CompanyId
		LEFT JOIN mp_mst_geocode_data	(NOLOCK) c ON b.ZipCode = c.Zipcode AND b.country_id = c.country_Id
		WHERE a.company_id = @CompanyId
	UNION
		SELECT @NextPostId,'_address_gps_latitude','field_5fff2addb7408'
	UNION
		SELECT @NextPostId,'address_gps_latitude',ISNULL(CONVERT(VARCHAR(100),latitude),'') 
		FROM #tmp_DataSync_SupplierProfileDetails_Companies				(NOLOCK) a
		LEFT JOIN #tmp_DataSync_SupplierProfileDetails_Adddress b ON a.company_id = b.CompanyId
		LEFT JOIN mp_mst_geocode_data	(NOLOCK) c ON b.ZipCode = c.Zipcode AND b.country_id = c.country_Id
		WHERE a.company_id = @CompanyId
	UNION
		SELECT @NextPostId,'_address_gps_longitude','field_5fff2addb7408'
	UNION
		SELECT @NextPostId,'address_gps_longitude',ISNULL(CONVERT(VARCHAR(100),longitude),'') 
		FROM #tmp_DataSync_SupplierProfileDetails_Companies				(NOLOCK) a
		LEFT JOIN #tmp_DataSync_SupplierProfileDetails_Adddress b ON a.company_id = b.CompanyId
		LEFT JOIN mp_mst_geocode_data	(NOLOCK) c ON b.ZipCode = c.Zipcode AND b.country_id = c.country_Id
		WHERE a.company_id = @CompanyId
	UNION
		SELECT @NextPostId,'_address_state','field_600c7a9717d64'
	UNION
		SELECT @NextPostId,'address_state',
			CASE WHEN LEN(ISNULL(b.State,'')) = 0 THEN '' ELSE b.State  END
		FROM #tmp_DataSync_SupplierProfileDetails_Companies				(NOLOCK) a
		LEFT JOIN #tmp_DataSync_SupplierProfileDetails_Adddress b ON a.company_id = b.CompanyId
		WHERE a.company_id = @CompanyId
	UNION
		SELECT @NextPostId,'_avatar','field_5faeff8d6f42f'
	UNION
		SELECT @NextPostId,'avatar', 
			CASE 
				WHEN h.file_name IS NULL THEN '' 
				WHEN h.file_name ='' THEN '' 
				ELSE 
					ISNULL(@CompanyLogo + REPLACE(h.file_name,'&' ,'&amp;'),'')
			END as [avatar_image] 
		FROM #tmp_DataSync_SupplierProfileDetails_Companies				(NOLOCK) a
		LEFT JOIN 
		(
			SELECT COMP_ID ,file_name , ROW_NUMBER() OVER(PARTITION BY COMP_ID ORDER BY COMP_ID,FILE_ID DESC)  RN  FROM mp_special_files (NOLOCK) WHERE FILETYPE_ID = 6 AND IS_DELETED = 0
		) h ON a.company_id = h.COMP_ID AND h.RN = 1
		WHERE a.company_id = @CompanyId
	UNION
		SELECT @NextPostId,'_banner','field_6006fe63981d1'
	UNION
		SELECT @NextPostId,'banner',
			CASE 
				WHEN l.file_name IS NULL THEN '' 
				WHEN l.file_name ='' THEN '' 
				ELSE 
					ISNULL(@CompanyBanner + REPLACE(l.file_name,'&' ,'&amp;'),'')
			END
		FROM #tmp_DataSync_SupplierProfileDetails_Companies				(NOLOCK) a
		LEFT JOIN 
		(
			SELECT COMP_ID ,file_name , ROW_NUMBER() OVER(PARTITION BY COMP_ID ORDER BY COMP_ID,FILE_ID DESC)  RN  FROM mp_special_files (NOLOCK) WHERE FILETYPE_ID = 8 AND IS_DELETED = 0
		) l ON a.company_id = l.COMP_ID AND l.RN = 1
		WHERE a.company_id = @CompanyId
	UNION
		SELECT @NextPostId,'_cagecode','field_5faf0c2f28afe'
	UNION
		SELECT @NextPostId,'cagecode'
			,CASE WHEN a.cage_code IS NULL THEN '' WHEN a.cage_code ='' THEN '' ELSE REPLACE(REPLACE( REPLACE(a.cage_code,'<',''),'>',''),'&' ,'&amp;') END
		FROM #tmp_DataSync_SupplierProfileDetails_Companies				(NOLOCK) a
		WHERE a.company_id = @CompanyId
	UNION
		SELECT @NextPostId,'_date_established','field_5faf044b7bfeb'
	UNION
		SELECT @NextPostId,'date_established',REPLACE(CONVERT(VARCHAR(10),created_date,120),'-','') 
		FROM #tmp_DataSync_SupplierProfileDetails_Companies				(NOLOCK) a
		WHERE a.company_id = @CompanyId
	UNION
		SELECT @NextPostId,'_description','field_5fab5ba91f04e'
	UNION
		SELECT @NextPostId,'description',
			CASE 
				WHEN a.description IS NULL THEN '' 
				WHEN a.description ='' THEN '' 
				ELSE REPLACE(a.description , '<p><br></p>','') 
				--(SELECT [dbo].RemoveInvalidXMLCharacters (REPLACE( REPLACE( REPLACE( (SELECT [dbo].[udf_StripHTML](ISNULL(a.description,''))),'&' ,'&amp;'),'<',''),'>',''))) 
			END
		FROM #tmp_DataSync_SupplierProfileDetails_Companies				(NOLOCK) a
		WHERE a.company_id = @CompanyId
	UNION
		SELECT @NextPostId,'_duns','field_5faf01946f432'
	UNION
		SELECT @NextPostId,'duns' ,CASE WHEN LEN(ISNULL(a.duns_number,'')) = 0 THEN '' ELSE a.duns_number  END 
		FROM #tmp_DataSync_SupplierProfileDetails_Companies				(NOLOCK) a
		WHERE a.company_id = @CompanyId
	UNION
		SELECT @NextPostId,'_employees','field_5faf01c46f433'
	UNION
		SELECT @NextPostId,'employees' ,
			CASE WHEN c.range IS NULL THEN '' WHEN c.range ='' THEN '' WHEN c.range = '---' THEN ''  ELSE c.range END
		FROM #tmp_DataSync_SupplierProfileDetails_Companies				(NOLOCK) a
		LEFT JOIN mp_mst_employees_count_range		(NOLOCK) c ON a.employee_count_range_id = c.employee_count_range_id
		WHERE a.company_id = @CompanyId
	UNION
		SELECT @NextPostId,'_equipment','field_5faf047e7bfec'
	UNION
		SELECT @NextPostId ,'equipment' , 
		ISNULL((
			SELECT 
				STRING_AGG(a.equipment,'')
			FROM
			(
				SELECT 
					'<p class="equipment">' +
					(SELECT [dbo].RemoveInvalidXMLCharacters (REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(b.equipment_Text,''),'&' ,'&amp;'),'<',''),'>',''),'"','')))
					+ '</p>' AS equipment
				FROM mp_company_equipments	(NOLOCK) a
				JOIN mp_mst_equipment			(NOLOCK) b ON a.equipment_ID = b.equipment_Id
				WHERE a.company_id = @CompanyId
			) a
		) ,'')
	UNION
		SELECT @NextPostId,'_gallery','field_5fda32208b4d9'
	UNION
		--SELECT @NextPostId,'gallery' , 
		--CONVERT(VARCHAR(100),(SELECT COUNT(1) FROM mp_special_files (NOLOCK)	WHERE comp_id = @CompanyId and filetype_id = 4 and is_deleted = 0 AND ISNULL(s3_found_status,1) = 1))
	    
		---- Modified  with M2-4269
		SELECT  @NextPostId,'gallery' , 
		CAST(SUM(cnt)  AS Varchar(100)) 
		FROM 
		(
			SELECT COUNT(1) as cnt FROM mp_special_files (NOLOCK)	WHERE comp_id = @CompanyId and filetype_id = 4 and is_deleted = 0 AND ISNULL(s3_found_status,1) = 1
			UNION ALL
			SELECT COUNT(1)  FROM mpUserProfileVideoLinks (NOLOCK)  WHERE companyid = @CompanyId and isdeleted = 0  and  IsLinkVisionAccepted = 1
		) gallerycnt
	UNION
	(
		--SELECT  @NextPostId , '_gallery_'+CAST(ROW_NUMBER() OVER(ORDER BY FILE_ID)-1 AS VARCHAR)+'_image_url' , 'field_5ff6242cc3e71'
		--FROM mp_special_files (NOLOCK)	WHERE comp_id = @CompanyId and filetype_id = 4 and is_deleted = 0 AND ISNULL(s3_found_status,1) = 1
		--UNION
		--SELECT  @NextPostId , 'gallery_'+CAST(ROW_NUMBER() OVER(ORDER BY FILE_ID)-1 AS VARCHAR)+'_image_url' , @ImageGalleryPath  + REPLACE(file_name,'&' ,'&amp;')
		--FROM mp_special_files (NOLOCK)	WHERE comp_id = @CompanyId and filetype_id = 4 and is_deleted = 0 AND ISNULL(s3_found_status,1) = 1

		---- Modified  with M2-4269
		SELECT @NextPostId ,  
		'_gallery_' +  +CAST(ROW_NUMBER() OVER(ORDER BY rn)-1 AS VARCHAR)+'_image_url'
		,  'field_5ff6242cc3e71'
		FROM
		
		(
			SELECT  1 as rn  
			FROM mp_special_files (NOLOCK)	WHERE comp_id = @CompanyId and filetype_id = 4 and is_deleted = 0 AND ISNULL(s3_found_status,1) = 1
			UNION ALL  
			SELECT  1  
			FROM mpUserProfileVideoLinks (NOLOCK)
			WHERE companyid = @CompanyId 
			and isdeleted = 0  and  IsLinkVisionAccepted = 1
		) gallery 

		UNION	 

		SELECT post_id,'gallery_'+CAST(ROW_NUMBER() OVER(ORDER BY rn)-1 AS VARCHAR)+'_image_url' as meta_key,meta_value FROM
		(
			SELECT post_id,meta_key,meta_value 
			,ROW_NUMBER() OVER ( ORDER BY post_id) rn
			FROM
			(
					SELECT  @NextPostId as post_id 
					, 'gallery_'+CAST(ROW_NUMBER() OVER(ORDER BY FILE_ID)-1 AS VARCHAR)+'_image_url'  meta_key
					, @ImageGalleryPath + REPLACE(file_name,'&' ,'&amp;') meta_value
					FROM mp_special_files (NOLOCK)	WHERE comp_id = @CompanyId and filetype_id = 4 and is_deleted = 0 AND ISNULL(s3_found_status,1) = 1
					Union all  
					SELECT  @NextPostId , 'gallery_'+CAST(ROW_NUMBER() OVER(ORDER BY Id)-1 AS VARCHAR)+'_image_url' ,   VideoLink
					FROM mpUserProfileVideoLinks (NOLOCK) 
					WHERE companyid = @CompanyId  
					and isdeleted = 0  and  IsLinkVisionAccepted = 1
			) gallery
		) gallerylist
	)
	UNION
		SELECT @NextPostId,'_id','field_5fda31dc8b4d8'
	UNION
		SELECT @NextPostId,'id',	CONVERT(VARCHAR(100), a.company_id) 
		FROM #tmp_DataSync_SupplierProfileDetails_Companies				(NOLOCK) a
		WHERE a.company_id = @CompanyId
	UNION
		SELECT @NextPostId,'_languages','field_5faf04cf54551'
	UNION
		SELECT @NextPostId,'languages' ,
		ISNULL((
			SELECT 
				STRING_AGG(a.equipment,'')
			FROM
			(
				SELECT  DISTINCT 
					'<p class="language">' +
					REPLACE(ISNULL(b.language_name,''),'&' ,'&amp;')
					+'</p>' AS equipment
				FROM mp_company_contact_otherlanguages	(NOLOCK) a
				JOIN mp_mst_language			(NOLOCK) b ON a.language_id = b.language_id
				WHERE a.company_id = @CompanyId
			) a
		) ,'')
	UNION
		SELECT @NextPostId,'_location_manufacturing','field_5faf04f454553'
	UNION
		SELECT @NextPostId,'location_manufacturing'
			,CASE WHEN LEN(ISNULL(b.territory_classification_name,'')) = 0  THEN '' ELSE b.territory_classification_name END	
		FROM #tmp_DataSync_SupplierProfileDetails_Companies				(NOLOCK) a
		JOIN mp_mst_territory_classification (NOLOCK) b ON a.manufacturing_location_id = b.territory_classification_id
	UNION
		SELECT @NextPostId,'_mfgverified','field_600b47fdaab2e'
	UNION
		SELECT @NextPostId,'mfgverified', 
			CASE 
				WHEN k.PaidStatus IS NULL THEN 'No' 
				WHEN k.PaidStatus ='' THEN 'No' 
				WHEN k.PaidStatus ='MFG Verified? No' THEN 'No'
				ELSE  'Yes'  END
		FROM #tmp_DataSync_SupplierProfileDetails_Companies				(NOLOCK) a
		LEFT JOIN #tmp_DataSync_SupplierProfileDetails_MfgVerified k ON a.company_id = k.CompanyId
	UNION
		SELECT @NextPostId,'_name','field_5fab5aad1f049'
	UNION
		SELECT @NextPostId,'name', CASE WHEN LEN(ISNULL(a.name,'')) = 0 THEN '' ELSE a.name  END  
		FROM #tmp_DataSync_SupplierProfileDetails_Companies	(NOLOCK) a	
	UNION
		SELECT @NextPostId,'_old_slug','field_601059443520b'
	UNION
		SELECT @NextPostId,'old_slug', 
			CASE 
				WHEN LEN(ISNULL(a.name,'')) = 0 THEN '' 
				ELSE REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(a.name),' ','-'),'__','-'),'___','-') ),'--','-') 
					+'-'+CONVERT(VARCHAR(150),a.company_id)  
			END  
		FROM #tmp_DataSync_SupplierProfileDetails_Companies	(NOLOCK) a	
	UNION
		SELECT @NextPostId,'_phone','field_5ff4a5e756653'
	UNION
		SELECT @NextPostId,'phone',
		(	SELECT TOP 1	
				CASE	WHEN REPLACE(REPLACE(REPLACE(communication_value,'&' ,'&amp;'),'(',''),')','') = '' THEN NULL
						ELSE REPLACE(REPLACE(REPLACE(communication_value,'&' ,'&amp;'),'(',''),')','')
				END
			FROM mp_communication_details (NOLOCK) 
			WHERE communication_type_id = 1
			AND  contact_id IN (SELECT contact_id FROM #tmp_DataSync_SupplierProfileDetails_Adddress) 
		)
	UNION
		SELECT @NextPostId,'_profile_owner_email','field_6009cc0ab5f12'
	UNION
		SELECT @NextPostId,'profile_owner_email', email
		FROM #tmp_DataSync_SupplierProfileDetails_Adddress
	UNION
		SELECT @NextPostId,'_profile_owner_name_first','field_6009cba897698'
	UNION
		SELECT @NextPostId,'profile_owner_name_first', ISNULL(a.first_name,'')
		FROM #tmp_DataSync_SupplierProfileDetails_Adddress a
	UNION
		SELECT @NextPostId,'_profile_owner_name_last','field_6009cbee97699'
	UNION
		SELECT @NextPostId,'profile_owner_name_last', ISNULL(a.last_name,'')
		FROM #tmp_DataSync_SupplierProfileDetails_Adddress a
	UNION
		SELECT @NextPostId,'_reviews','field_5fd4113a066d1'
	UNION
		SELECT @NextPostId,'reviews' , 
		ISNULL(CONVERT(VARCHAR(100),( SELECT COUNT(1) FROM #tmp_DataSync_SupplierProfileDetails_Reviews )),'0')
	UNION
		SELECT @NextPostId,'_reviews_rating','field_5fab5b341f04c'
	UNION
		SELECT @NextPostId,'reviews_rating' , 
		ISNULL(CONVERT(VARCHAR(100),( SELECT no_of_stars FROM mp_star_rating (NOLOCK) WHERE company_id = @CompanyId)),'0')
	UNION
		SELECT @NextPostId,'_reviews_total','field_5fab5b541f04d'
	UNION
		SELECT @NextPostId,'reviews_total' , 
		ISNULL(CONVERT(VARCHAR(100),( SELECT total_responses FROM mp_star_rating (NOLOCK) WHERE company_id = @CompanyId )),'0')
	UNION
		(
			SELECT  @NextPostId , '_reviews_'+CAST(ROW_NUMBER() OVER(ORDER BY  response_id DESC , created_date)-1 AS VARCHAR)+'_review_date' , 'field_5fd41152066d2'
			FROM #tmp_DataSync_SupplierProfileDetails_Reviews 
			UNION
			SELECT  @NextPostId , '_reviews_'+CAST(ROW_NUMBER() OVER(ORDER BY  response_id DESC , created_date)-1 AS VARCHAR)+'_review_rating' , 'field_5fd41184066d3'
			FROM #tmp_DataSync_SupplierProfileDetails_Reviews 
			UNION
			SELECT  @NextPostId , '_reviews_'+CAST(ROW_NUMBER() OVER(ORDER BY  response_id DESC , created_date)-1 AS VARCHAR)+'_review_comment' , 'field_5fd411da066d4'
			FROM #tmp_DataSync_SupplierProfileDetails_Reviews 
			UNION
			SELECT  @NextPostId , '_reviews_'+CAST(ROW_NUMBER() OVER(ORDER BY  response_id DESC , created_date)-1 AS VARCHAR)+'_review_response' , 'field_60f1ccdbb2272'
			FROM #tmp_DataSync_SupplierProfileDetails_Reviews 
			/* M2-4288 Data Sync - Add Buyer Company Name, Buyer First Name, and Buyer Last Name Initial for ratings / reviews */
			UNION
			SELECT  @NextPostId , '_reviews_'+CAST(ROW_NUMBER() OVER(ORDER BY  response_id DESC , created_date)-1 AS VARCHAR)+'_review_reviewer_name' , 'field_61d6080299d68'
			FROM #tmp_DataSync_SupplierProfileDetails_Reviews 
			UNION
			SELECT  @NextPostId , '_reviews_'+CAST(ROW_NUMBER() OVER(ORDER BY  response_id DESC , created_date)-1 AS VARCHAR)+'_review_reviewer_company' , 'field_61d6081399d69'
			FROM #tmp_DataSync_SupplierProfileDetails_Reviews 
			/**/
			UNION
			SELECT  @NextPostId , 'reviews_'+CAST(ROW_NUMBER() OVER(ORDER BY  response_id DESC , created_date)-1 AS VARCHAR)+'_review_date' , REPLACE(CONVERT(VARCHAR(10),created_date,120),'-','') 
			FROM #tmp_DataSync_SupplierProfileDetails_Reviews  
			UNION
			SELECT  @NextPostId , 'reviews_'+CAST(ROW_NUMBER() OVER(ORDER BY  response_id DESC , created_date)-1 AS VARCHAR)+'_review_rating' , CONVERT(VARCHAR(10),score)
			FROM #tmp_DataSync_SupplierProfileDetails_Reviews 
			UNION
			SELECT  @NextPostId , 'reviews_'+CAST(ROW_NUMBER() OVER(ORDER BY  response_id DESC , created_date)-1 AS VARCHAR)+'_review_comment' , comment
			FROM #tmp_DataSync_SupplierProfileDetails_Reviews 
			UNION
			SELECT  @NextPostId , 'reviews_'+CAST(ROW_NUMBER() OVER(ORDER BY  response_id DESC , created_date)-1 AS VARCHAR)+'_review_response' , CASE WHEN score IS NULL THEN  'a:1:{i:0;s:3:"yes";}' ELSE '' END
			FROM #tmp_DataSync_SupplierProfileDetails_Reviews 
			/* M2-4288 Data Sync - Add Buyer Company Name, Buyer First Name, and Buyer Last Name Initial for ratings / reviews */
			UNION
			SELECT  @NextPostId , 'reviews_'+CAST(ROW_NUMBER() OVER(ORDER BY  response_id DESC , created_date)-1 AS VARCHAR)+'_review_reviewer_name' , ratebycontact
			FROM #tmp_DataSync_SupplierProfileDetails_Reviews 
			UNION
			SELECT  @NextPostId , 'reviews_'+CAST(ROW_NUMBER() OVER(ORDER BY  response_id DESC , created_date)-1 AS VARCHAR)+'_review_reviewer_company' , ratebycompany
			FROM #tmp_DataSync_SupplierProfileDetails_Reviews 
			/**/
		)
	UNION
		SELECT @NextPostId,'_source','field_6006fef4981d2'
	UNION
		SELECT @NextPostId,'source','Mfg'
	UNION
		SELECT @NextPostId,'_tier','field_5fda32728b4da'
	UNION
		SELECT @NextPostId,'tier',
			CASE 
				WHEN k.PaidStatus IS NULL THEN '01 Basic' 
				WHEN k.PaidStatus ='' THEN '01 Basic' 
				ELSE k.PaidStatus  
			END
		FROM #tmp_DataSync_SupplierProfileDetails_Companies				 a
		LEFT JOIN #tmp_DataSync_SupplierProfileDetails_PaidStatus k ON a.company_id = k.CompanyId
	UNION
		SELECT @NextPostId,'_type','field_5faf054c5e655'
	UNION
		SELECT @NextPostId,'type', 
			CASE WHEN supplier_type_name_en IS NULL THEN '' WHEN supplier_type_name_en ='' THEN '' ELSE (SELECT [dbo].RemoveInvalidXMLCharacters (REPLACE( (SELECT [dbo].[udf_StripHTML](ISNULL(supplier_type_name_en,''))),'&' ,'&amp;'))) END 

		FROM #tmp_DataSync_SupplierProfileDetails_Companies				(NOLOCK) a
		LEFT JOIN 
		(
			SELECT company_id ,supplier_type_id , ROW_NUMBER() OVER(PARTITION BY company_id ORDER BY company_id,company_supplier_types_id DESC)  RN  FROM mp_company_supplier_types (NOLOCK) WHERE ISNULL(IS_BUYER,0) = 0
		) i ON a.company_id = i.company_id  AND i.RN = 1
		LEFT JOIN mp_mst_supplier_type (NOLOCK) j ON i.supplier_type_id = j.supplier_type_id
	UNION
		SELECT @NextPostId,'_website','field_5ff4a5b456652'
	UNION
		SELECT @NextPostId,'website' ,
		ISNULL((	SELECT TOP 1	
					CASE	WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(communication_value,'&' ,'&amp;'),'https://',''),'https:/',''),'http://',''),'http:/','') = '' THEN NULL
							ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(communication_value,'&' ,'&amp;'),'https://',''),'https:/',''),'http://',''),'http:/','')
					END 
			FROM mp_communication_details (NOLOCK) 
			WHERE communication_type_id = 4 AND communication_value <> ''
			AND  company_id IN (SELECT CompanyId FROM #tmp_DataSync_SupplierProfileDetails_Adddress) 
		) ,'')
	UNION
		SELECT @NextPostId, '_certifications' ,'field_5faf015c6f431'
	UNION
		SELECT @NextPostId, 'certifications' ,
		ISNULL((
			SELECT 
				STRING_AGG(a.certificate,'')
			FROM
			(
				SELECT DISTINCT  
					'<p class="certification">' 
					+ REPLACE(ISNULL(b.certificate_code ,''),'&' ,'&amp;')
					+'</p>' AS certificate
				FROM mp_company_certificates	(NOLOCK) a
				JOIN mp_certificates			(NOLOCK) b ON a.certificates_id = b.certificate_id
				WHERE a.company_id = @CompanyId
			) a
		) ,'')
	UNION
		SELECT @NextPostId,'_capabilities','field_5faeffa36f430'
	UNION
		SELECT @NextPostId,'capabilities', CONVERT(VARCHAR(100),(SELECT COUNT(DISTINCT ParentCapabilities) FROM #tmp_DataSync_SupplierProfileDetails_Capabilities))
	UNION
		(
			SELECT  @NextPostId , '_capabilities_'+CAST(ROW_NUMBER() OVER(ORDER BY ParentCapabilities)-1 AS VARCHAR)+'_primary' , 'field_5ff79533e47ac'
			FROM (SELECT DISTINCT ParentCapabilities FROM #tmp_DataSync_SupplierProfileDetails_Capabilities ) a
			UNION
			SELECT  @NextPostId , '_capabilities_'+CAST(ROW_NUMBER() OVER(ORDER BY ParentCapabilities)-1 AS VARCHAR)+'_secondary' , 'field_5ff79549e47ad'
			FROM (SELECT DISTINCT ParentCapabilities FROM #tmp_DataSync_SupplierProfileDetails_Capabilities ) a 
			UNION
			SELECT  @NextPostId , 'capabilities_'+CAST(ROW_NUMBER() OVER(ORDER BY ParentCapabilities)-1 AS VARCHAR)+'_primary' , ParentCapabilities
			FROM (SELECT DISTINCT ParentCapabilities FROM #tmp_DataSync_SupplierProfileDetails_Capabilities  ) a
			UNION
			SELECT  @NextPostId , 'capabilities_'+CAST(ROW_NUMBER() OVER(ORDER BY ParentCapabilities)-1 AS VARCHAR)+'_secondary' , 
				ISNULL((SELECT STRING_AGG(ChildCapabilities,', ') FROM #tmp_DataSync_SupplierProfileDetails_Capabilities WHERE ParentCapabilities = a.ParentCapabilities AND ParentCapabilities<>ChildCapabilities) ,'')
			FROM (SELECT DISTINCT ParentCapabilities FROM #tmp_DataSync_SupplierProfileDetails_Capabilities  ) a
		)
	UNION
		SELECT @NextPostId, '_yoast_wpseo_title'
			,a.name 
				+ ' %%sep%% '
				+ CASE 
					WHEN LEN(ISNULL(f.ParentCapabilities,'')) = 0 THEN ''
					WHEN LEN(ISNULL(f.ParentCapabilities,'')) > 0 AND  CHARINDEX(',',f.ParentCapabilities) = 0 THEN  f.ParentCapabilities
					WHEN LEN(ISNULL(f.ParentCapabilities,'')) > 0 AND  CHARINDEX(',',f.ParentCapabilities) > 0 THEN	
						SUBSTRING(f.ParentCapabilities,0,CHARINDEX(',',f.ParentCapabilities))
					ELSE ''
				 END
				+' %%sep%% '
				+ CASE WHEN LEN(ISNULL(b.StreetAddress,'')) = 0 THEN '' ELSE REPLACE(b.StreetAddress,'?','') + ', ' END
				+ CASE WHEN LEN(ISNULL(b.City,'')) = 0 THEN '' ELSE REPLACE(b.City,'?','') + ', ' END
				+ CASE WHEN LEN(ISNULL(b.State,'')) = 0 THEN '' ELSE b.State + ', ' END
				+ CASE WHEN LEN(ISNULL(b.ZipCode,'')) = 0 THEN '' ELSE b.ZipCode + ', ' END
				+ CASE WHEN LEN(ISNULL(b.Country,'')) = 0  THEN '' ELSE b.Country END	
				+' %%sep%% %%sitename%%' AS title
		FROM #tmp_DataSync_SupplierProfileDetails_Companies  a (NOLOCK)
		LEFT JOIN #tmp_DataSync_SupplierProfileDetails_Adddress b ON a.company_id = b.CompanyId
		LEFT JOIN 
		(
			SELECT CompanyId , STRING_AGG(REPLACE(ParentCapabilities,', ',''),',') ParentCapabilities
			FROM
			(
				SELECT DISTINCT CompanyId ,  ParentCapabilities FROM #tmp_DataSync_SupplierProfileDetails_Capabilities 
			) a
			GROUP BY CompanyId
		
		) f ON a.company_id = f.CompanyId
		WHERE a.company_id = @CompanyId
	UNION
		SELECT @NextPostId, '_yoast_wpseo_metadesc'
			,a.name+'''s custom manufacturing capabilities include: '
			+ CASE 
				WHEN LEN(ISNULL(f.ParentCapabilities,'')) = 0 THEN ''
				WHEN LEN(ISNULL(f.ParentCapabilities,'')) > 0 THEN  f.ParentCapabilities + space(1)
				ELSE ''
			  END
			+ '- Find '+a.name+' and more suppliers on the MFG Community!'
		FROM #tmp_DataSync_SupplierProfileDetails_Companies  a (NOLOCK)
		LEFT JOIN #tmp_DataSync_SupplierProfileDetails_Adddress b ON a.company_id = b.CompanyId
		LEFT JOIN 
		(
			SELECT CompanyId , STRING_AGG(REPLACE(ParentCapabilities,', ',''),', ') ParentCapabilities
			FROM
			(
				SELECT DISTINCT CompanyId ,  ParentCapabilities FROM #tmp_DataSync_SupplierProfileDetails_Capabilities 
			) a
			GROUP BY CompanyId
		
		) f ON a.company_id = f.CompanyId
		WHERE a.company_id = @CompanyId

	UNION
		SELECT @NextPostId,'_yoast_wpseo_opengraph-title'
			,	A.name 
			+ ' %%sep%% %%sitename%%' 
		FROM #tmp_DataSync_SupplierProfileDetails_Companies a
	UNION
		SELECT @NextPostId,'_yoast_wpseo_opengraph-description'
			,	'Find ' + A.name 
			+ ' and more suppliers on the MFG Community!' 
		FROM #tmp_DataSync_SupplierProfileDetails_Companies a
	UNION
		SELECT @NextPostId,'_yoast_wpseo_twitter-title'
			, A.name 
			+ ' %%sep%% %%sitename%%' 
		FROM #tmp_DataSync_SupplierProfileDetails_Companies a
	UNION
		SELECT @NextPostId,'_yoast_wpseo_twitter-description'
			,'Find ' + A.name 
			+ ' and more suppliers on the MFG Community!' 
		FROM #tmp_DataSync_SupplierProfileDetails_Companies a
	UNION
		SELECT @NextPostId,'_yoast_wpseo_opengraph-image' ,'/wp-content/uploads/sites/3/2021/01/Banner_Social.png'
	UNION
		SELECT @NextPostId,'_badges','field_60623073de61b'
	UNION
		SELECT @NextPostId,'badges','1'
	UNION
		SELECT @NextPostId,'_badges_0_rfq_awarded','field_60623084de61c'
	UNION
		SELECT @NextPostId,'badges_0_rfq_awarded',
		(
			SELECT 
				CASE 
					WHEN RfqAwarded < 3 AND RfqAwarded > 0 THEN '1'
					WHEN RfqAwarded < 7 AND RfqAwarded > 0 THEN '3'
					WHEN RfqAwarded >= 7 THEN '7'
					ELSE ''
				END
			FROM
			(
				SELECT COUNT(DISTINCT a.rfq_id)  RfqAwarded
				FROM mp_rfq_quote_SupplierQuote a (NOLOCK)
				JOIN mp_rfq_quote_items			b (NOLOCK) ON a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id
				WHERE a.contact_id IN 
				(
					SELECT contact_id FROM mp_contacts (NOLOCK)
					WHERE company_id IN 
						( 
							SELECT company_id 
							FROM #tmp_DataSync_SupplierProfileDetails_Companies		a
							LEFT JOIN #tmp_DataSync_SupplierProfileDetails_PaidStatus k ON a.company_id = k.CompanyId
							WHERE k.PaidStatus IN ('03 Gold' , '02 Growth Package' , '04 Platinum','05 Starter')
						)
					AND is_buyer = 0
				)
				AND b.is_awrded = 1
				AND b.status_id = 6
				AND a.is_quote_submitted = 1
				AND a.is_rfq_resubmitted = 0
			) a
		)
	UNION
		SELECT @NextPostId,'_badges_0_rfq_awarded_amount','field_606235a8a7fc2'
	UNION
		SELECT @NextPostId,'badges_0_rfq_awarded_amount',
		(
			SELECT 
				CASE 
					WHEN RfqAwarded > 0 THEN CONVERT(VARCHAR(50),RfqAwarded)
					ELSE ''
				END
			FROM
			(
				SELECT CONVERT(VARCHAR(50),COUNT(DISTINCT a.rfq_id) ) RfqAwarded
				FROM mp_rfq_quote_SupplierQuote a (NOLOCK)
				JOIN mp_rfq_quote_items			b (NOLOCK) ON a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id
				WHERE a.contact_id IN 
				(
					SELECT contact_id FROM mp_contacts (NOLOCK)
					WHERE company_id IN 
						( 
							SELECT company_id 
							FROM #tmp_DataSync_SupplierProfileDetails_Companies		a
							LEFT JOIN #tmp_DataSync_SupplierProfileDetails_PaidStatus k ON a.company_id = k.CompanyId
							WHERE k.PaidStatus IN ('03 Gold' , '02 Growth Package' , '04 Platinum','05 Starter')
						)
					AND is_buyer = 0
				)
				AND b.is_awrded = 1
				AND b.status_id = 6
				AND a.is_quote_submitted = 1
				AND a.is_rfq_resubmitted = 0
			) a
		)
	UNION
		SELECT @NextPostId,'_badges_0_rfq_quoted','field_606232e3de61d'
	UNION
		SELECT @NextPostId,'badges_0_rfq_quoted',
		(
			SELECT 
				CASE 
					WHEN RfqQuoted <= 20 AND RfqQuoted > 10 THEN '1'
					WHEN RfqQuoted <= 50 AND RfqQuoted > 20 THEN '2'
					WHEN RfqQuoted > 50 THEN '3'
					ELSE ''
				END
			FROM
			(
				SELECT COUNT(DISTINCT a.rfq_id)  RfqQuoted
				FROM mp_rfq_quote_SupplierQuote a (NOLOCK)
				JOIN mp_rfq_quote_items			b (NOLOCK) ON a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id
				WHERE a.contact_id IN 
				(
					SELECT contact_id FROM mp_contacts (NOLOCK)
					WHERE company_id IN 
						( 
							SELECT company_id 
							FROM #tmp_DataSync_SupplierProfileDetails_Companies		a
							LEFT JOIN #tmp_DataSync_SupplierProfileDetails_PaidStatus k ON a.company_id = k.CompanyId
							WHERE k.PaidStatus IN ('03 Gold' , '02 Growth Package' , '04 Platinum','05 Starter')
						)
					AND is_buyer = 0
				)
				AND a.is_quote_submitted = 1
				AND a.is_rfq_resubmitted = 0
			) a
		)
	UNION
		SELECT @NextPostId,'_badges_0_certifications','field_60623331de61e'
	UNION
		SELECT @NextPostId,'badges_0_certifications' , 
		ISNULL((
			SELECT 
				'a:'+CONVERT(VARCHAR(50),RC)+':{' + STRING_AGG(C1,'') + '}'
			FROM
			(
				SELECT
					'i:' + CONVERT(VARCHAR(50),RN) 
					+ CASE 
						WHEN Certificate = 'ISO' THEN ';s:3:"' 
						ELSE ';s:2:"' 
					  END
					+ Certificate 
					+ '";' AS C1
					, RC

				FROM
				(
					SELECT 
						LOWER(Certificate)  Certificate
						,ROW_NUMBER() OVER ( ORDER BY Certificate)-1 RN
						,COUNT(*) OVER() RC
					FROM #tmp_DataSync_SupplierProfileDetails_Certificates 
				) a
			) a
			GROUP BY RC
		),'')
	UNION
		SELECT @NextPostId,'_badges_0_member_duration','field_6062338ede61f'
	UNION
		SELECT @NextPostId,'badges_0_member_duration' ,
		ISNULL(
		(
			SELECT 
				CASE 
					WHEN DATEDIFF(Year, created_date , GETUTCDATE()) BETWEEN 0 AND 1 THEN '1'
					WHEN DATEDIFF(Year, created_date , GETUTCDATE()) BETWEEN 1 AND 5 THEN '2'
					WHEN DATEDIFF(Year, created_date , GETUTCDATE()) > 5 THEN '3'
				END

			FROM #tmp_DataSync_SupplierProfileDetails_Companies 
			WHERE 
			company_id IN 
			( 
				SELECT company_id 
				FROM #tmp_DataSync_SupplierProfileDetails_Companies		a
				LEFT JOIN #tmp_DataSync_SupplierProfileDetails_PaidStatus k ON a.company_id = k.CompanyId
				WHERE k.PaidStatus IN ('03 Gold' , '02 Growth Package' , '04 Platinum','05 Starter')
			)
		) , '')
	UNION
		SELECT @NextPostId,'_badges_0_mfgverified','field_6070bd2fd6aa4'
	UNION
		SELECT @NextPostId,'badges_0_mfgverified' ,
		ISNULL(
		(
			SELECT 
				'a:1:{i:0;s:8:"verified";}'

			FROM #tmp_DataSync_SupplierProfileDetails_PaidStatus k
			WHERE k.PaidStatus IN ('03 Gold' , '02 Growth Package' , '04 Platinum','05 Starter')
			
		) , '')
	UNION
		SELECT @NextPostId,'_display','field_607f521e8ff98'
	UNION
		SELECT @NextPostId,'display' ,
		ISNULL(
		(
			SELECT  
				CASE WHEN @ProfileManagementSettingsCount > 0 THEN 'a:'+CONVERT(VARCHAR(50),@ProfileManagementSettingsCount) +':{'+STRING_AGG(ProfileManagementSettings, '') + '}' ELSE '' END
			FROM
			(
				SELECT
					CASE 
						WHEN [Value] = 'Ads' THEN   'i:'+CONVERT(VARCHAR(50),Rn)+';s:3:"Ads";'
						WHEN [Value] = 'Badges' THEN   'i:'+CONVERT(VARCHAR(50),Rn)+';s:6:"Badges";'
						WHEN [Value] = 'Capabilities' THEN   'i:'+CONVERT(VARCHAR(50),Rn)+';s:12:"Capabilities";'
						WHEN [Value] = 'Claim My Profile' THEN   'i:'+CONVERT(VARCHAR(50),Rn)+';s:16:"Claim My Profile";'
						WHEN [Value] = 'Contact' THEN   'i:'+CONVERT(VARCHAR(50),Rn)+';s:7:"Contact";'
						WHEN [Value] = 'Company Details' THEN   'i:'+CONVERT(VARCHAR(50),Rn)+';s:15:"Company Details";'
						WHEN [Value] = 'Description' THEN   'i:'+CONVERT(VARCHAR(50),Rn)+';s:11:"Description";'
						WHEN [Value] = 'Edit My Profile' THEN   'i:'+CONVERT(VARCHAR(50),Rn)+';s:15:"Edit My Profile";'
						WHEN [Value] = 'Equipment' THEN   'i:'+CONVERT(VARCHAR(50),Rn)+';s:9:"Equipment";'
						WHEN [Value] = 'Gallery' THEN   'i:'+CONVERT(VARCHAR(50),Rn)+';s:7:"Gallery";'
						WHEN [Value] = 'Message' THEN   'i:'+CONVERT(VARCHAR(50),Rn)+';s:7:"Message";'
						WHEN [Value] = 'Reviews' THEN   'i:'+CONVERT(VARCHAR(50),Rn)+';s:7:"Reviews";'
						WHEN [Value] = 'Simple RFQ' THEN   'i:'+CONVERT(VARCHAR(50),Rn)+';s:10:"Simple RFQ";'
						WHEN [Value] = 'Tags' THEN   'i:'+CONVERT(VARCHAR(50),Rn)+';s:4:"Tags";'
						WHEN [Value] = 'RFQ History' THEN   'i:'+CONVERT(VARCHAR(50),Rn)+';s:11:"RFQ History";'
						WHEN [Value] = 'Analytics' THEN   'i:'+CONVERT(VARCHAR(50),Rn)+';s:9:"Analytics";'
					END ProfileManagementSettings
				FROM
				(
					SELECT 
						[value] AS [Value]
						, ROW_NUMBER() OVER (ORDER BY [value] ) -1 Rn
					FROM STRING_SPLIT(@ProfileManagementSettings,',')
					WHERE [value] NOT IN ('HideProfile','')
				) a
			) a
		) , '')
	UNION
		SELECT @NextPostId,'_completion','field_60b8d233c84d4'
	UNION
		SELECT @NextPostId,'completion' ,
		ISNULL(
		(
			SELECT 
				CASE 
					WHEN 
						(
							CASE WHEN LEN(COALESCE( mp_special_files.FILE_NAME , '')) > 0 THEN 1 ELSE 0 END
							+ CASE WHEN LEN(COALESCE( mp_companies.description,'')) > 0 THEN 1 ELSE 0 END
							+ CASE WHEN (COALESCE(b.company_id,'0')) > 0 THEN 1 ELSE 0 END  
						) = 3 THEN '100'
					ELSE ''
				END AS	IsProfileCompleted

			FROM mp_companies (NOLOCK) 
			LEFT JOIN 
			(
				SELECT comp_id , FILE_NAME  , ROW_NUMBER() OVER (PARTITION BY comp_id  ORDER BY comp_id , FILE_ID DESC) Rn
				FROM mp_special_files (NOLOCK)
				WHERE FILETYPE_ID = 6 AND IS_DELETED = 0
			) mp_special_files ON mp_special_files.comp_id = mp_companies.company_id and mp_special_files.Rn = 1
			LEFT JOIN 
			(
				SELECT company_id FROM mp_company_processes (NOLOCK) 
				UNION
				SELECT company_id FROM mp_gateway_subscription_company_processes (NOLOCK) 					 
			) b ON mp_companies.company_Id = b.company_id
			WHERE mp_companies.company_Id = @CompanyId
		), '')
	UNION
		SELECT @NextPostId,'_spotlight','field_612025cd55a48'
	UNION
		SELECT @NextPostId,'spotlight' , (CASE WHEN @SpotLightRank = 0 THEN '0' ELSE '1' END)
	UNION
		SELECT @NextPostId,'_spotlight_sort_order','field_612568fd6ceff'
	UNION
		SELECT @NextPostId,'spotlight_sort_order' , (CASE WHEN @SpotLightRank = 0 THEN '' ELSE CONVERT(VARCHAR(10),@SpotLightRank) END)
	/* M2-4059 Vision - Add Spotlight to the data sync - DB*/
	UNION
		SELECT @NextPostId,CASE WHEN @Industriescount > 0 THEN '_industries' ELSE 'noindustries' END ,'field_61f232644ed93'
	UNION
		SELECT @NextPostId,CASE WHEN @Industriescount > 0 THEN 'industries' ELSE 'noindustries' END  ,
		ISNULL(
		(
			SELECT  
				CASE WHEN @Industriescount > 0 THEN 'a:'+CONVERT(VARCHAR(50),@Industriescount) +':{'+STRING_AGG(Industries, '') + '}' ELSE '' END
			FROM
			(
				SELECT
					CASE 
						WHEN [Value] = 43 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"43";'
						WHEN [Value] = 75 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"75";'
						WHEN [Value] = 69 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"69";'
						WHEN [Value] = 70 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"70";'
						WHEN [Value] = 76 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"76";'
						WHEN [Value] = 29 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"29";'
						WHEN [Value] = 8 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:1:"8";'
						WHEN [Value] = 39 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"39";'
						WHEN [Value] = 50 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"50";'
						WHEN [Value] = 71 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"71";'
						WHEN [Value] = 54 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"54";'
						WHEN [Value] = 63 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"63";'
						WHEN [Value] = 26 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"26";'
						WHEN [Value] = 27 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"27";'
						WHEN [Value] = 7 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:1:"7";'
						WHEN [Value] = 55 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"55";'
						WHEN [Value] = 28 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"28";'
						WHEN [Value] = 16 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"16";'
						WHEN [Value] = 77 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"77";'
						WHEN [Value] = 59 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"59";'
						WHEN [Value] = 46 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"46";'
						WHEN [Value] = 52 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"52";'
						WHEN [Value] = 60 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"60";'
						WHEN [Value] = 19 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"19";'
						WHEN [Value] = 72 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"72";'
						WHEN [Value] = 12 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"12";'
						WHEN [Value] = 78 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"78";'
						WHEN [Value] = 79 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"79";'
						WHEN [Value] = 37 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"37";'
						WHEN [Value] = 61 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"61";'
						WHEN [Value] = 53 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"53";'
						WHEN [Value] = 73 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"73";'
						WHEN [Value] = 4 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:1:"4";'
						WHEN [Value] = 67 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"67";'
						WHEN [Value] = 68 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"68";'
						WHEN [Value] = 21 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"21";'
						WHEN [Value] = 17 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"17";'
						WHEN [Value] = 56 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"56";'
						WHEN [Value] = 9 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:1:"9";'
						WHEN [Value] = 31 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"31";'
						WHEN [Value] = 30 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"30";'
						WHEN [Value] = 80 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"80";'
						WHEN [Value] = 32 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"32";'
						WHEN [Value] = 1 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:1:"1";'
						WHEN [Value] = 81 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"81";'
						WHEN [Value] = 64 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"64";'
						WHEN [Value] = 11 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"11";'
						WHEN [Value] = 18 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"18";'
						WHEN [Value] = 15 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"15";'
						WHEN [Value] = 41 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"41";'
						WHEN [Value] = 25 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"25";'
						WHEN [Value] = 62 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"62";'
						WHEN [Value] = 23 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"23";'
						WHEN [Value] = 57 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"57";'
						WHEN [Value] = 82 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"82";'
						WHEN [Value] = 66 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"66";'
						WHEN [Value] = 2 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:1:"2";'
						WHEN [Value] = 42 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"42";'
						WHEN [Value] = 20 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"20";'
						WHEN [Value] = 6 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:1:"6";'
						WHEN [Value] = 13 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"13";'
						WHEN [Value] = 10 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"10";'
						WHEN [Value] = 49 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"49";'
						WHEN [Value] = 48 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"48";'
						WHEN [Value] = 83 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"83";'
						WHEN [Value] = 65 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"65";'
						WHEN [Value] = 24 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"24";'
						WHEN [Value] = 44 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"44";'
						WHEN [Value] = 38 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"38";'
						WHEN [Value] = 22 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"22";'
						WHEN [Value] = 36 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"36";'
						WHEN [Value] = 35 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"35";'
						WHEN [Value] = 14 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"14";'
						WHEN [Value] = 5 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:1:"5";'
						WHEN [Value] = 34 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"34";'
						WHEN [Value] = 33 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"33";'
						WHEN [Value] = 45 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"45";'
						WHEN [Value] = 58 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"58";'
						WHEN [Value] = 74 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"74";'
						WHEN [Value] = 40 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"40";'
						WHEN [Value] = 51 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"51";'
						WHEN [Value] = 3 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:1:"3";'
						
					END Industries
				FROM
				(
					SELECT 
						[value] AS [Value]
						, ROW_NUMBER() OVER (ORDER BY [value] ) -1 Rn
					FROM STRING_SPLIT(@Industries,',')
					
				) a
			) a
		) , '')
	UNION
		SELECT @NextPostId,CASE WHEN @Materialscount > 0 THEN '_materials' ELSE 'nomaterials' END ,'field_61f2329c4ed94'
	UNION
		SELECT @NextPostId,CASE WHEN @Materialscount > 0 THEN 'materials' ELSE 'nomaterials' END , 
		ISNULL(
		(
			SELECT  
				CASE WHEN @Materialscount > 0 THEN 'a:'+CONVERT(VARCHAR(50),@Materialscount) +':{'+STRING_AGG(Materials, '') + '}' ELSE '' END
			FROM
			(
				SELECT
					CASE 
						WHEN [Value] = 600 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:3:"600";'
						WHEN [Value] = 607 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:3:"607";'
						WHEN [Value] = 553 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:3:"553";'
						WHEN [Value] = 12 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"12";'
						WHEN [Value] = 569 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:3:"569";'
						WHEN [Value] = 562 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:3:"562";'
						WHEN [Value] = 13 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"13";'
						WHEN [Value] = 123 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:3:"123";'
						WHEN [Value] = 570 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:3:"570";'
						WHEN [Value] = 563 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:3:"563";'
						WHEN [Value] = 564 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:3:"564";'
						WHEN [Value] = 129 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:3:"129";'
						WHEN [Value] = 552 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:3:"552";'
						WHEN [Value] = 52 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"52";'
						WHEN [Value] = 113 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:3:"113";'
						WHEN [Value] = 5 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:1:"5";'
						WHEN [Value] = 99 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"99";'
						WHEN [Value] = 565 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:3:"565";'
						WHEN [Value] = 33 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"33";'
						WHEN [Value] = 603 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:3:"603";'
						WHEN [Value] = 560 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:3:"560";'
						WHEN [Value] = 38 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"38";'
						WHEN [Value] = 602 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:3:"602";'
						WHEN [Value] = 605 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:3:"605";'
						WHEN [Value] = 561 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:3:"561";'
						WHEN [Value] = 601 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:3:"601";'
						WHEN [Value] = 606 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:3:"606";'
						WHEN [Value] = 604 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:3:"604";'
						WHEN [Value] = 4 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:1:"4";'
						WHEN [Value] = 130 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:3:"130";'
						WHEN [Value] = 131 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:3:"131";'
						WHEN [Value] = 566 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:3:"566";'
						WHEN [Value] = 567 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:3:"567";'
						WHEN [Value] = 124 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:3:"124";'
						WHEN [Value] = 568 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:3:"568";'
						WHEN [Value] = 60 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"60";'
						WHEN [Value] = 41 THEN 'i:'+CONVERT(VARCHAR(50),Rn)+';s:2:"41";'
					END Materials
				FROM
				(
					SELECT 
						[value] AS [Value]
						, ROW_NUMBER() OVER (ORDER BY [value] ) -1 Rn
					FROM STRING_SPLIT(@Materials,',')
					
				) a
			) a
		) , '')
		/* */




	/* M2-4024 Data - Sync the directory order */
	INSERT INTO #tmp_DataSync_SupplierProfileDetails
	SELECT 
		@NextPostId								AS post_id
		, 'sort_order_score'								AS meta_key
		,ISNULL(
				SUM(
						CASE	
							WHEN meta_key = '3dshopview'				AND LEN(ISNULL(meta_value,'')) > 0 THEN 8
							WHEN meta_key = 'cagecode'					AND LEN(ISNULL(meta_value,'')) > 0 THEN 3
							WHEN meta_key = 'certifications'			AND LEN(ISNULL(meta_value,'')) > 0 THEN 10
							WHEN meta_key = 'duns'						AND LEN(ISNULL(meta_value,'')) > 0 THEN 3
							WHEN meta_key = 'employees'					AND LEN(ISNULL(meta_value,'')) > 0 THEN 5
							WHEN meta_key = 'equipment'					AND LEN(ISNULL(meta_value,'')) > 0 THEN 10
							WHEN meta_key = 'gallery'					AND (ISNULL(meta_value,'') <> '0' AND ISNULL(meta_value,'') <> '') THEN 10
							WHEN meta_key = 'languages'					AND LEN(ISNULL(meta_value,'')) > 0 THEN 5
							WHEN meta_key = 'location_manufacturing'	AND LEN(ISNULL(meta_value,'')) > 0 THEN 5
							WHEN meta_key = 'mfgverified'				AND meta_value = 'Yes'				THEN 10
							WHEN meta_key = 'reviews_total'				AND (ISNULL(meta_value,'') <> '0' AND ISNULL(meta_value,'') <> '')  THEN 8
							WHEN meta_key = 'website'					AND LEN(ISNULL(meta_value,'')) > 0 THEN 5
						END
					),0
				) SortWeightage
	FROM #tmp_DataSync_SupplierProfileDetails

	
	SELECT * FROM #tmp_DataSync_SupplierProfileDetails 
	WHERE meta_key NOT IN  ('noindustries','nomaterials')
	ORDER BY meta_key
	/**/

	DROP TABLE IF EXISTS #tmp_DataSync_SupplierProfileDetails_Capabilities
	DROP TABLE IF EXISTS #tmp_DataSync_SupplierProfileDetails_Adddress
	DROP TABLE IF EXISTS #tmp_DataSync_SupplierProfileDetails_Companies
	DROP TABLE IF EXISTS #tmp_DataSync_SupplierProfileDetails_Reviews
	DROP TABLE IF EXISTS #tmp_DataSync_SupplierProfileDetails_PaidStatus
	DROP TABLE IF EXISTS #tmp_DataSync_SupplierProfileDetails_MfgVerified
	DROP TABLE IF EXISTS #tmp_DataSync_SupplierProfileDetails_Certificates
	/* M2-4024 Data - Sync the directory order */
	DROP TABLE IF EXISTS #tmp_DataSync_SupplierProfileDetails
	/**/

END
