

/*  


EXEC [proc_set_DataSync_Update_MarketplaceToHubSpot_CompanyContact]

*/
CREATE PROCEDURE [dbo].[proc_set_DataSync_Update_MarketplaceToHubSpot_CompanyContact]
AS
BEGIN
	/* 
		M2-4233 DB - HubSpot - Create Sync Contacts module API Scheduler & Immediate Syncs.
		M2-4235 DB - HubSpot - Create Sync Buyer Companies (Custom) module API Scheduler & Immediate Syncs.
		M2-4234 DB - HubSpot - Create Sync Companies (Default) module API Scheduler & Immediate Syncs.
	
	*/

	--SET NOCOUNT ON 

	DECLARE @SyncedDate AS DATETIME =  GETUTCDATE()
	DECLARE @SyncedDateIST AS DATETIME =  CONVERT(DATETIME,SWITCHOFFSET(@SyncedDate, '+05:30'))
	DECLARE @IsVisionAccountBuyer AS BIT
	DECLARE @PublicProfileURL VARCHAR(1000) 

	IF DB_NAME() = 'mp2020_dev'
	BEGIN
		SET @PublicProfileURL = 'https://dev.mfg.com/manufacturer/'
	END
	ELSE IF DB_NAME() = 'mp2020_uat'
	BEGIN
		SET @PublicProfileURL = 'https://staging.mfg.com/manufacturer/'		
	END
	ELSE IF DB_NAME() = 'mp2020_prod'
	BEGIN
		SET @PublicProfileURL = 'https://mfg.com/manufacturer/'
	END


	DROP TABLE IF EXISTS #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ListofCompanies
	DROP TABLE IF EXISTS #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ListofContacts
	DROP TABLE IF EXISTS #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesType
	DROP TABLE IF EXISTS #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesAddress
	DROP TABLE IF EXISTS #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesInfo
	DROP TABLE IF EXISTS #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesDiscipline0
	DROP TABLE IF EXISTS #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesDiscipline0
	DROP TABLE IF EXISTS #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesQuotingDiscipline0
	DROP TABLE IF EXISTS #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesQuotingDiscipline1
	DROP TABLE IF EXISTS #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesIndustries
	DROP TABLE IF EXISTS #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo
	DROP TABLE IF EXISTS #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo1
	DROP TABLE IF EXISTS #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo2
	DROP TABLE IF EXISTS #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsAddress
	DROP TABLE IF EXISTS #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactCommunications
	DROP TABLE IF EXISTS #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompanyCommunications
	

	CREATE TABLE #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ListofCompanies (company_id INT NULL)
	CREATE TABLE #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ListofContacts (contact_id INT NULL)

	BEGIN TRANSACTION
	BEGIN TRY
		
		
		-- companies & contacts data already generated marked as processed
		UPDATE ds SET ds.IsProcessed = 1 , ds.ProcessedDate = @SyncedDate , ds.ProcessedDateIST = @SyncedDateIST
		FROM DataSync_MarketplaceHubSpot.dbo.MarketplaceToHubSpotContactCompaniesCreateLogs ds (NOLOCK) 
		WHERE [SyncType] = 'Scheduler - Update - 30 Minutes' AND ds.IsProcessed IS NULL
		
		-- Scheduler sync : checking companies and contact in every 30 minutes which are not sync from Marketplace to HubSpot
		-- List of companies which are not sync from Marketplace to HubSpot
		INSERT INTO #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ListofCompanies (company_id)
		SELECT DISTINCT a.CompanyId AS company_id 
		FROM XML_SupplierProfileCaptureChanges (NOLOCK) a
		WHERE a.CompanyId <> 0 AND CreatedOn BETWEEN DATEADD(MINUTE , -30 ,@SyncedDate) AND @SyncedDate
		AND [Event] IN 
		(
			'address','cagecode','capabilities','certifications','company_name','dunsnumber','employees_countrange'
			,'hide_profile','industry','name','phone','website','tier'
		)

		-- List of contacts which are not sync from Marketplace to HubSpot
		INSERT INTO #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ListofContacts (contact_id)
		SELECT DISTINCT a.CreatedBy AS contact_id 
		FROM XML_SupplierProfileCaptureChanges (NOLOCK) a
		WHERE a.CompanyId <> 0 AND CreatedOn BETWEEN DATEADD(MINUTE , -30 ,@SyncedDate) AND @SyncedDate
		AND [Event] IN 
		(
			'address','cagecode','capabilities','certifications','company_name','dunsnumber','employees_countrange'
			,'hide_profile','industry','name','phone','website','tier'
		)
		
		/* M2-4938  */
		-- List of companies which are not sync from Marketplace to HubSpot due to email update/change
		INSERT INTO #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ListofCompanies (company_id)
		SELECT DISTINCT  c.company_id
		FROM mp_email_change_logs (NOLOCK) a
		JOIN aspnetusers (NOLOCK) b on a.newemail = b.email
		JOIN mp_contacts(NOLOCK) c on c.user_id = b.id
		WHERE   a.ModifiedOn BETWEEN DATEADD(MINUTE , -30 ,GETDATE()) AND GETDATE()
		AND c.company_id NOT IN (SELECT company_id FROM #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ListofCompanies)

		-- List of contact which are not sync from Marketplace to HubSpot due to email update/change
		INSERT INTO #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ListofContacts (contact_id)
		SELECT DISTINCT  c.contact_id
		FROM mp_email_change_logs (NOLOCK) a
		JOIN aspnetusers (NOLOCK) b on a.newemail = b.email
		JOIN mp_contacts(NOLOCK) c on c.user_id = b.id
		WHERE   a.ModifiedOn BETWEEN DATEADD(MINUTE , -30 ,GETDATE()) AND GETDATE()
		AND c.contact_id NOT IN (SELECT contact_id FROM #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ListofContacts)
		/*  */

		INSERT INTO DataSync_MarketplaceHubSpot.dbo.MarketplaceToHubSpotContactCompaniesCreateLogs 
		([Vision Account Id], [Vision Contact Id], [SyncType], [IsSynced], [SyncedDate], [SyncedDateIST])
		SELECT company_id, NULL, 'Scheduler - Update - 30 Minutes', 1, @SyncedDate, @SyncedDateIST FROM #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ListofCompanies
		UNION
		SELECT NULL, contact_id, 'Scheduler - Update - 30 Minutes', 1, @SyncedDate, @SyncedDateIST FROM #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ListofContacts

		-- companies details
		SELECT 
			a.company_id, a.name , a.cage_code , a.duns_number , a.assigned_customer_rep , a.assigned_sourcingadvisor , a.manufacturing_location_id
			, a.is_hide_directory_profile , a.employee_count_range_id , a.created_date 
			, a.profilestatus ----Added with 5083
		INTO #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesInfo
		FROM mp_companies  a (NOLOCK)
		WHERE EXISTS 
		(
			SELECT *
			FROM DataSync_MarketplaceHubSpot.dbo.MarketplaceToHubSpotContactCompaniesCreateLogs (NOLOCK)
			WHERE 
				[IsProcessed] IS NULL 
				AND [Vision Contact Id] IS NULL
				--AND a.company_id = [Vision Account Id] 
				AND [SyncType] = 'Scheduler - Update - 30 Minutes'
		)

		-- companies status buyer or supplier company
		SELECT DISTINCT a.company_id , a.is_buyer INTO #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesType
		FROM mp_contacts a (NOLOCK)
		WHERE EXISTS 
		(
			SELECT *
			FROM DataSync_MarketplaceHubSpot.dbo.MarketplaceToHubSpotContactCompaniesCreateLogs (NOLOCK)
			WHERE 
				[IsProcessed] IS NULL 
				AND [Vision Contact Id] IS NULL
				AND [Vision Account Id] = a.company_id
				AND [SyncType] = 'Scheduler - Update - 30 Minutes'
		)

		-- companies address details 
		SELECT 
			a.company_id 
			,b.address1 AS [Company Street Address]
			,b.address2 AS [Company Street Address 2]
			,b.address4 AS [Company City] 
			,c.region_name AS [Company State]
			,b.address3 AS [Company Postal Code]
			,d.country_name AS [Company Country]
			,d.iso_code AS [Company Country Code]
		INTO #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesAddress
		FROM  
		(
				SELECT 
					company_id , contact_id ,address_id
					, ROW_NUMBER() OVER(PARTITION BY company_id ORDER BY company_id , is_admin DESC, contact_id ) rn 
				FROM [mp_contacts] (NOLOCK)
			
		) a
		JOIN mp_addresses			b (NOLOCK) ON a.address_id = b.address_id AND a.rn = 1 
		LEFT JOIN mp_mst_region		c (NOLOCK) ON b.region_id = c.region_id AND b.region_id <> 0
		LEFT JOIN mp_mst_country	d (NOLOCK) ON b.country_id = d.country_id AND b.country_id <> 0
		WHERE EXISTS 
		(
			SELECT *
			FROM DataSync_MarketplaceHubSpot.dbo.MarketplaceToHubSpotContactCompaniesCreateLogs (NOLOCK)
			WHERE 
				[IsProcessed] IS NULL 
				AND [Vision Contact Id] IS NULL
				AND [Vision Account Id] = a.company_id
				AND [SyncType] = 'Scheduler - Update - 30 Minutes'
		) 

		-- companies phone numbers
		SELECT company_id , communication_value , ROW_NUMBER() OVER (PARTITION BY company_id ORDER BY company_id , contact_id ) Rn 
		INTO #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompanyCommunications
		FROM mp_communication_details a (NOLOCK) 
		WHERE communication_type_id = 1 AND company_id IS NOT NULL AND company_id > 0 
		AND EXISTS 
		(
			SELECT *
			FROM DataSync_MarketplaceHubSpot.dbo.MarketplaceToHubSpotContactCompaniesCreateLogs (NOLOCK)
			WHERE 
				[IsProcessed] IS NULL 
				AND [Vision Contact Id] IS NULL
				AND [Vision Account Id] = a.company_id
				AND [SyncType] = 'Scheduler - Update - 30 Minutes'
		)

		-- companies disciplines 0
		SELECT DISTINCT a.company_id, b.discipline_name  AS part_category_id INTO #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesDiscipline0
		FROM 
		mp_company_processes(NOLOCK) a
		JOIN mp_mst_part_category(NOLOCK) b ON a.part_category_id = b.part_category_id AND b.LEVEL = 0
		WHERE EXISTS 
		(
			SELECT *
			FROM DataSync_MarketplaceHubSpot.dbo.MarketplaceToHubSpotContactCompaniesCreateLogs (NOLOCK) 
			WHERE 
				[IsProcessed] IS NULL 
				AND [Vision Contact Id] IS NULL
				AND [Vision Account Id] = a.company_id
				AND [SyncType] = 'Scheduler - Update - 30 Minutes'
		)
		UNION
		SELECT DISTINCT a.company_id, c.discipline_name  AS part_category_id
		FROM 
		mp_company_processes(NOLOCK) a
		JOIN mp_mst_part_category(NOLOCK) b ON a.part_category_id = b.part_category_id AND b.LEVEL = 1
		JOIN mp_mst_part_category(NOLOCK) c ON b.parent_part_category_id = c.part_category_id 
		WHERE EXISTS 
		(
			SELECT *
			FROM DataSync_MarketplaceHubSpot.dbo.MarketplaceToHubSpotContactCompaniesCreateLogs (NOLOCK) 
			WHERE 
				[IsProcessed] IS NULL 
				AND [Vision Contact Id] IS NULL
				AND [Vision Account Id] = a.company_id
				AND [SyncType] = 'Scheduler - Update - 30 Minutes'
		)

		-- companies disciplines 1
		SELECT DISTINCT a.company_id, b.discipline_name  AS part_category_id 
		INTO #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesDiscipline1
		FROM 
		mp_company_processes(NOLOCK) a
		JOIN mp_mst_part_category(NOLOCK) b ON a.part_category_id = b.part_category_id AND b.LEVEL = 1
		WHERE EXISTS 
		(
			SELECT *
			FROM DataSync_MarketplaceHubSpot.dbo.MarketplaceToHubSpotContactCompaniesCreateLogs (NOLOCK) 
			WHERE 
				[IsProcessed] IS NULL 
				AND [Vision Contact Id] IS NULL
				AND [Vision Account Id] = a.company_id
				AND [SyncType] = 'Scheduler - Update - 30 Minutes'
		)
	
		-- companies quoting disciplines 0
		SELECT DISTINCT a.company_id, b.discipline_name  AS part_category_id INTO #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesQuotingDiscipline0
		FROM 
		mp_gateway_subscription_company_processes(NOLOCK) a
		JOIN mp_mst_part_category(NOLOCK) b ON a.part_category_id = b.part_category_id AND b.LEVEL = 0
		WHERE EXISTS 
		(
			SELECT *
			FROM DataSync_MarketplaceHubSpot.dbo.MarketplaceToHubSpotContactCompaniesCreateLogs (NOLOCK) 
			WHERE 
				[IsProcessed] IS NULL 
				AND [Vision Contact Id] IS NULL
				AND [Vision Account Id] = a.company_id
				AND [SyncType] = 'Scheduler - Update - 30 Minutes'
		)
		UNION
		SELECT DISTINCT a.company_id, c.discipline_name  AS part_category_id
		FROM 
		mp_gateway_subscription_company_processes(NOLOCK) a
		JOIN mp_mst_part_category(NOLOCK) b ON a.part_category_id = b.part_category_id AND b.LEVEL = 1
		JOIN mp_mst_part_category(NOLOCK) c ON b.parent_part_category_id = c.part_category_id 
		WHERE EXISTS 
		(
			SELECT *
			FROM DataSync_MarketplaceHubSpot.dbo.MarketplaceToHubSpotContactCompaniesCreateLogs (NOLOCK) 
			WHERE 
				[IsProcessed] IS NULL 
				AND [Vision Contact Id] IS NULL
				AND [Vision Account Id] = a.company_id
				AND [SyncType] = 'Scheduler - Update - 30 Minutes'
		)

		-- companies quoting disciplines 1
		SELECT DISTINCT a.company_id, b.discipline_name  AS part_category_id 	INTO #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesQuotingDiscipline1
		FROM 
		mp_gateway_subscription_company_processes(NOLOCK) a
		JOIN mp_mst_part_category(NOLOCK) b ON a.part_category_id = b.part_category_id AND b.LEVEL = 1
		WHERE EXISTS 
		(
			SELECT *
			FROM DataSync_MarketplaceHubSpot.dbo.MarketplaceToHubSpotContactCompaniesCreateLogs (NOLOCK) 
			WHERE 
				[IsProcessed] IS NULL 
				AND [Vision Contact Id] IS NULL
				AND [Vision Account Id] = a.company_id
				AND [SyncType] = 'Scheduler - Update - 30 Minutes'
		)
	
		-- companies industries
		SELECT company_id, CASE WHEN a.is_buyer = 0 THEN supplier_type_name_en WHEN a.is_buyer = 1 THEN IndustryBranches_name_EN  ELSE NULL END industries
		INTO #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesIndustries
		FROM mp_company_supplier_types (NOLOCK)  a
		LEFT JOIN mp_mst_supplier_type (NOLOCK) b ON a.supplier_type_id = b.supplier_type_id AND a.is_buyer = 0
		LEFT JOIN mp_mst_industrybranches (NOLOCK) c ON a.supplier_type_id = c.IndustryBranches_id AND a.is_buyer = 1
		WHERE EXISTS 
		(
			SELECT *
			FROM DataSync_MarketplaceHubSpot.dbo.MarketplaceToHubSpotContactCompaniesCreateLogs (NOLOCK) 
			WHERE 
				[IsProcessed] IS NULL 
				AND [Vision Contact Id] IS NULL
				AND [Vision Account Id] = a.company_id
				AND [SyncType] = 'Scheduler - Update - 30 Minutes'
		)

		--- below code commented on 27-Feb-2023 for created duplicate companies records
		-- insert company new record 
		/*
		INSERT INTO DataSync_MarketplaceHubSpot.dbo.HubSpotCompanies
		(
		[Vision Account Id], [HubSpot Account Id], [IsBuyerAccount], [Account Paid Status], [Buyer Company City], [Buyer Company Country],  
		[Buyer Company Phone], [Buyer Company Postal Code], [Buyer Company State], [Buyer Company Street Address], [Buyer Company Street Address 2], [Cage Code], [City], 
		[Company Name], [Company Owner Id], [Country/Region], [Create Date], [Customer Service Rep Id], [Discipline Level 0], [Discipline Level 1], [Duns Number], 
		[Facebook Company Page], [Google Plus Page], [Hide Directory Profile], [Industry], [LinkedIn Company Page] ,[Number of Employees], [Phone Number], 
		[Postal Code], [Public Profile URL], 
		[RFQ Access Capabilities 0], [RFQ Access Capabilities 1], [State/Region], [Street Address], [Street Address 2], [Manufacturing Location], [Twitter Handle], 
		[IsSynced], [SyncedDate], [SyncedDateIST]
		,[RecordType] ---- temp added 
		)
		SELECT 
			[Vision Account Id]
			,	NULL AS [HubSpot Account Id]
			,   b.is_buyer AS  [IsBuyerAccount]
			,	CASE 
					WHEN b.is_buyer = 1 THEN ''
					WHEN (SELECT TOP 1 account_type FROM mp_registered_supplier (NOLOCK) a1 WHERE a.[Vision Account Id] = a1.company_id) = 84 THEN 'Growth'
					WHEN (SELECT TOP 1 account_type FROM mp_registered_supplier (NOLOCK) a1 WHERE a.[Vision Account Id] = a1.company_id) = 85 THEN 'Gold'
					WHEN (SELECT TOP 1 account_type FROM mp_registered_supplier (NOLOCK) a1 WHERE a.[Vision Account Id] = a1.company_id) = 86 THEN 'Platinum'
					ELSE 'Basic'
				END [Account Paid Status]
			, CASE WHEN b.is_buyer = 1 THEN c.[Company City] ELSE '' END [Buyer Company City]
			, CASE WHEN b.is_buyer = 1 THEN c.[Company Country] ELSE '' END [Buyer Company Country]
			, CASE WHEN b.is_buyer = 1 THEN k.communication_value ELSE '' END AS [Buyer Company Phone]
			, CASE WHEN b.is_buyer = 1 THEN c.[Company Postal Code] ELSE '' END [Buyer Company Postal Code]
			, CASE WHEN b.is_buyer = 1 THEN c.[Company State] ELSE '' END [Buyer Company State]
			, CASE WHEN b.is_buyer = 1 THEN c.[Company Street Address] ELSE '' END [Buyer Company Street Address]
			, CASE WHEN b.is_buyer = 1 THEN c.[Company Street Address 2] ELSE '' END [Buyer Company Address 2]
			, d.cage_code AS [Cage Code]
			, CASE WHEN b.is_buyer = 0 THEN c.[Company City] ELSE '' END [City]
			, d.name AS [Company Name]
			, d.assigned_sourcingadvisor AS [Company Owner Id]
			, CASE WHEN b.is_buyer = 0 THEN c.[Company Country] ELSE '' END [Country]
			, d.created_date AS [Create Date]
			, d.assigned_customer_rep AS  [Customer Service Rep Id]
			, CASE WHEN b.is_buyer = 0 THEN e.disciplines0  END   AS [Discipline Level 0]
			, CASE WHEN b.is_buyer = 0 THEN f.disciplines1  END   AS [Discipline Level 1]
			, d.duns_number AS [Duns Number] 
			, NULL AS [Facebook Company Page]
			, NULL AS [Google Plus Page]
			, CASE WHEN b.is_buyer = 0 THEN ISNULL(d.is_hide_directory_profile, CAST('false' AS BIT))  END AS [Hide Directory Profile]
			, g.industries AS [Industry]
			, NULL AS [LinkedIn Company Page]
			, d.employee_count_range_id AS [Number of Employees]
			, CASE WHEN b.is_buyer = 0 THEN k.communication_value ELSE '' END  AS [Phone Number]
			, CASE WHEN b.is_buyer = 0 THEN c.[Company Postal Code]  END AS [Postal Code]
			, CASE WHEN b.is_buyer = 0 THEN h.PublicProfileUrl  END  AS [Public Profile URL]
			, CASE WHEN b.is_buyer = 0 THEN i.disciplines0  END  AS [RFQ Access Capabilities 0]
			, CASE WHEN b.is_buyer = 0 THEN j.disciplines1  END  AS [RFQ Access Capabilities 1]
			, CASE WHEN b.is_buyer = 0 THEN c.[Company State]  END AS [State/Region]
			, CASE WHEN b.is_buyer = 0 THEN c.[Company Street Address]  END AS [Street Address]
			, CASE WHEN b.is_buyer = 0 THEN c.[Company Street Address 2]  END AS [Street Address 2]
			, d.manufacturing_location_id AS [Manufacturing Location]
			, NULL AS [Twitter Handle]
			, CAST('false' AS BIT) AS [IsSynced]
			, @SyncedDate		AS [SyncedDate]
			, @SyncedDateIST	AS [SyncedDateIST]
			, 'RecordUpdate'  AS [RecordType] ---- temp added 
		FROM DataSync_MarketplaceHubSpot.dbo.MarketplaceToHubSpotContactCompaniesCreateLogs  a (NOLOCK) 
		JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesType b ON a.[Vision Account Id] = b.company_id
		LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesAddress c ON  a.[Vision Account Id] = c.company_id
		LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesInfo d ON  a.[Vision Account Id] = d.company_id
		LEFT JOIN 
		(
			SELECT
			company_id, 
			STRING_AGG(part_category_id,';') disciplines0
			FROM
				#tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesDiscipline0
			GROUP BY
				company_id
		) e ON  a.[Vision Account Id] = e.company_id
		LEFT JOIN 
		(
			SELECT
			company_id, 
			STRING_AGG(part_category_id,';') disciplines1
			FROM
				#tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesDiscipline1
			GROUP BY
				company_id
		) f ON  a.[Vision Account Id] = f.company_id
		LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesIndustries    g on a.[Vision Account Id] = g.company_id  
		LEFT JOIN 
		(
			SELECT 	
				a.company_id , 
				@PublicProfileURL
				+ CASE 
					WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(a.name),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
					ELSE ISNULL(REPLACE(REPLACE(REPLACE(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(dbo.removespecialchars(a.name))),' ','-'),'__','-'),'___','-') ),'--','-'),'---','-'),'----','-'),'-----','-'),'') + '-' 
				  END 
				+ CASE 
					WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(a.name),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
					WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(c.[Company City]),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
					ELSE ISNULL(REPLACE(REPLACE(REPLACE(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(dbo.removespecialchars(c.[Company City]))),' ','-'),'__','-'),'___','-') ),'--','-'),'---','-'),'----','-'),'-----','-'),'') +  '-'
					END 
				+ CASE 
					WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(a.name),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
					WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(c.[Company State]),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
					ELSE ISNULL(REPLACE(REPLACE(REPLACE(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(dbo.removespecialchars(c.[Company State]))),' ','-'),'__','-'),'___','-') ),'--','-'),'---','-'),'----','-'),'-----','-'),'')  +  '-'
					END
				+  CONVERT(VARCHAR(100),a.company_id)  AS  PublicProfileUrl
			FROM #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesInfo  a (NOLOCK)
			LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesAddress	c (NOLOCK) ON a.company_id = c.company_id
		
		) h ON a.[Vision Account Id] = h.company_id 
		LEFT JOIN 
		(
			SELECT
			company_id, 
			STRING_AGG(part_category_id,';') disciplines0
			FROM
				#tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesQuotingDiscipline0
			GROUP BY
				company_id
		) i ON  a.[Vision Account Id] = i.company_id
		LEFT JOIN 
		(
			SELECT
			company_id, 
			STRING_AGG(part_category_id,';') disciplines1
			FROM
				#tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesQuotingDiscipline1
			GROUP BY
				company_id
		) j ON  a.[Vision Account Id] = j.company_id
		LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompanyCommunications k (NOLOCK) ON a.[Vision Account Id] = k.company_id AND k.Rn = 1
		WHERE a.[IsProcessed] IS NULL AND a.[Vision Contact Id] IS NULL AND a.[SyncType] = 'Scheduler - Update - 30 Minutes'
		AND NOT EXISTS (SELECT 1 FROM DataSync_MarketplaceHubSpot.dbo.HubSpotCompanies b (NOLOCK) WHERE a.[Vision Account Id] = b.[Vision Account Id] )
		*/

		-- insert company update record 
		INSERT INTO DataSync_MarketplaceHubSpot.dbo.HubSpotCompaniesUpdateLogs
		(
		[Vision Account Id], [IsBuyerAccount], [Account Paid Status], [Buyer Company City], [Buyer Company Country],  
		[Buyer Company Phone], [Buyer Company Postal Code], [Buyer Company State], [Buyer Company Street Address], [Buyer Company Street Address 2], [Cage Code], [City], 
		[Company Name], [Company Owner Id], [Country/Region], [Create Date], [Customer Service Rep Id], [Discipline Level 0], [Discipline Level 1], [Duns Number], 
		[Facebook Company Page], [Google Plus Page], [Hide Directory Profile], [Industry], [LinkedIn Company Page] ,[Number of Employees], [Phone Number], 
		[Postal Code], [Public Profile URL], 
		[RFQ Access Capabilities 0], [RFQ Access Capabilities 1], [State/Region], [Street Address], [Street Address 2], [Manufacturing Location], [Twitter Handle] 
		, [SyncedDate], [SyncedDateIST]
		)
		SELECT 
			[Vision Account Id]
			,   b.is_buyer AS  [IsBuyerAccount]
			,	CASE 
					WHEN b.is_buyer = 1 THEN ''
					WHEN (SELECT TOP 1 account_type FROM mp_registered_supplier (NOLOCK) a1 WHERE a.[Vision Account Id] = a1.company_id) = 84 THEN 'Growth'
					WHEN (SELECT TOP 1 account_type FROM mp_registered_supplier (NOLOCK) a1 WHERE a.[Vision Account Id] = a1.company_id) = 85 THEN 'Gold'
					WHEN (SELECT TOP 1 account_type FROM mp_registered_supplier (NOLOCK) a1 WHERE a.[Vision Account Id] = a1.company_id) = 86 THEN 'Platinum'
					WHEN (SELECT TOP 1 account_type FROM mp_registered_supplier (NOLOCK) a1 WHERE a.[Vision Account Id] = a1.company_id) = 313 THEN 'Starter'
					ELSE 'Basic'
				END [Account Paid Status]
			, CASE WHEN b.is_buyer = 1 THEN c.[Company City] ELSE '' END [Buyer Company City]
			, CASE WHEN b.is_buyer = 1 THEN c.[Company Country] ELSE '' END [Buyer Company Country]
			, CASE WHEN b.is_buyer = 1 THEN k.communication_value ELSE '' END AS [Buyer Company Phone]
			, CASE WHEN b.is_buyer = 1 THEN c.[Company Postal Code] ELSE '' END [Buyer Company Postal Code]
			, CASE WHEN b.is_buyer = 1 THEN c.[Company State] ELSE '' END [Buyer Company State]
			, CASE WHEN b.is_buyer = 1 THEN c.[Company Street Address] ELSE '' END [Buyer Company Street Address]
			, CASE WHEN b.is_buyer = 1 THEN c.[Company Street Address 2] ELSE '' END [Buyer Company Address 2]
			, d.cage_code AS [Cage Code]
			, CASE WHEN b.is_buyer = 0 THEN c.[Company City] ELSE '' END [City]
			, d.name AS [Company Name]
			, d.assigned_sourcingadvisor AS [Company Owner Id]
			, CASE WHEN b.is_buyer = 0 THEN c.[Company Country] ELSE '' END [Country]
			, d.created_date AS [Create Date]
			--, d.assigned_customer_rep AS  [Customer Service Rep Id] ----commented with M2-5176 
			, NULL AS  [Customer Service Rep Id] ---- updated with M2-5176 
			, CASE WHEN b.is_buyer = 0 THEN e.disciplines0  END   AS [Discipline Level 0]
			, CASE WHEN b.is_buyer = 0 THEN f.disciplines1  END   AS [Discipline Level 1]
			, d.duns_number AS [Duns Number] 
			, NULL AS [Facebook Company Page]
			, NULL AS [Google Plus Page]
			, CASE WHEN b.is_buyer = 0 THEN ISNULL(d.is_hide_directory_profile, CAST('false' AS BIT))  END AS [Hide Directory Profile]
			, g.industries AS [Industry]
			, NULL AS [LinkedIn Company Page]
			, d.employee_count_range_id AS [Number of Employees]
			, CASE WHEN b.is_buyer = 0 THEN k.communication_value ELSE '' END  AS [Phone Number]
			, CASE WHEN b.is_buyer = 0 THEN c.[Company Postal Code]  END AS [Postal Code]
			, CASE WHEN b.is_buyer = 0 THEN h.PublicProfileUrl  END  AS [Public Profile URL]
			---- following fields commented with M2-5177
			----, CASE WHEN b.is_buyer = 0 THEN i.disciplines0  END  AS [RFQ Access Capabilities 0]
			----, CASE WHEN b.is_buyer = 0 THEN j.disciplines1  END  AS [RFQ Access Capabilities 1]
			---- modified with M2-5177
			, NULL  AS [RFQ Access Capabilities 0]
			, NULL  AS [RFQ Access Capabilities 1]
			, CASE WHEN b.is_buyer = 0 THEN c.[Company State]  END AS [State/Region]
			, CASE WHEN b.is_buyer = 0 THEN c.[Company Street Address]  END AS [Street Address]
			, CASE WHEN b.is_buyer = 0 THEN c.[Company Street Address 2]  END AS [Street Address 2]
			, d.manufacturing_location_id AS [Manufacturing Location]
			, NULL AS [Twitter Handle]
			, @SyncedDate		AS [SyncedDate]
			, @SyncedDateIST	AS [SyncedDateIST]
		FROM DataSync_MarketplaceHubSpot.dbo.MarketplaceToHubSpotContactCompaniesCreateLogs a (NOLOCK) 
		JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesType b ON a.[Vision Account Id] = b.company_id
		LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesAddress c ON  a.[Vision Account Id] = c.company_id
		LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesInfo d ON  a.[Vision Account Id] = d.company_id
		LEFT JOIN 
		(
			SELECT
			company_id, 
			STRING_AGG(part_category_id,';') disciplines0
			FROM
				#tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesDiscipline0
			GROUP BY
				company_id
		) e ON  a.[Vision Account Id] = e.company_id
		LEFT JOIN 
		(
			SELECT
			company_id, 
			STRING_AGG(part_category_id,';') disciplines1
			FROM
				#tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesDiscipline1
			GROUP BY
				company_id
		) f ON  a.[Vision Account Id] = f.company_id
		LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesIndustries    g on a.[Vision Account Id] = g.company_id  
		LEFT JOIN 
		(
			SELECT 	
				a.company_id , 
				@PublicProfileURL
				+ CASE 
					WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(a.name),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
					ELSE ISNULL(REPLACE(REPLACE(REPLACE(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(dbo.removespecialchars(a.name))),' ','-'),'__','-'),'___','-') ),'--','-'),'---','-'),'----','-'),'-----','-'),'') + '-' 
				  END 
				+ CASE 
					WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(a.name),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
					WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(c.[Company City]),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
					ELSE ISNULL(REPLACE(REPLACE(REPLACE(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(dbo.removespecialchars(c.[Company City]))),' ','-'),'__','-'),'___','-') ),'--','-'),'---','-'),'----','-'),'-----','-'),'') +  '-'
					END 
				+ CASE 
					WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(a.name),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
					WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(c.[Company State]),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
					ELSE ISNULL(REPLACE(REPLACE(REPLACE(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(dbo.removespecialchars(c.[Company State]))),' ','-'),'__','-'),'___','-') ),'--','-'),'---','-'),'----','-'),'-----','-'),'')  +  '-'
					END
				+  CONVERT(VARCHAR(100),a.company_id)  AS  PublicProfileUrl
			FROM #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesInfo  a (NOLOCK)
			LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesAddress	c (NOLOCK) ON a.company_id = c.company_id
		
		) h ON a.[Vision Account Id] = h.company_id 
		LEFT JOIN 
		(
			SELECT
			company_id, 
			STRING_AGG(part_category_id,';') disciplines0
			FROM
				#tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesQuotingDiscipline0
			GROUP BY
				company_id
		) i ON  a.[Vision Account Id] = i.company_id
		LEFT JOIN 
		(
			SELECT
			company_id, 
			STRING_AGG(part_category_id,';') disciplines1
			FROM
				#tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesQuotingDiscipline1
			GROUP BY
				company_id
		) j ON  a.[Vision Account Id] = j.company_id
		LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompanyCommunications k (NOLOCK) ON a.[Vision Account Id] = k.company_id AND k.Rn = 1
		WHERE a.[IsProcessed] IS NULL AND a.[Vision Contact Id] IS NULL AND a.[SyncType] = 'Scheduler - Update - 30 Minutes'
		AND EXISTS (SELECT 1 FROM DataSync_MarketplaceHubSpot.dbo.HubSpotCompanies b (NOLOCK) WHERE a.[Vision Account Id] = b.[Vision Account Id] )

		-- update company records
		UPDATE a SET
			a.[Vision Account Id] = 	b.[Vision Account Id]  
			,a.[IsBuyerAccount] = 	b.[IsBuyerAccount]  
			,a.[Account Paid Status] = 	b.[Account Paid Status]  
			,a.[Buyer Company City] = 	b.[Buyer Company City]  
			,a.[Buyer Company Country] = 	b.[Buyer Company Country]  
			,a.[Buyer Company Phone] = 	b.[Buyer Company Phone]  
			,a.[Buyer Company Postal Code] = 	b.[Buyer Company Postal Code]  
			,a.[Buyer Company State] = 	b.[Buyer Company State]  
			,a.[Buyer Company Street Address] = 	b.[Buyer Company Street Address]  
			,a.[Buyer Company Street Address 2] = 	b.[Buyer Company Address 2] 
			,a.[Cage Code] = 	b.[Cage Code]  
			,a.[City] = 	b.[City]  
			,a.[Company Name] = 	b.[Company Name]  
			,a.[Company Owner Id] = 	b.[Company Owner Id]  
			,a.[Country/Region] = 	b.[Country] 
			,a.[Create Date] = 	b.[Create Date]  
			--,a.[Customer Service Rep Id] = 	b.[Customer Service Rep Id]  --- commented with M2-5176 
			,a.[Discipline Level 0] = 	b.[Discipline Level 0]  
			,a.[Discipline Level 1] = 	b.[Discipline Level 1]  
			,a.[Duns Number] = 	b.[Duns Number]  
			,a.[Facebook Company Page] = 	b.[Facebook Company Page]  
			,a.[Google Plus Page] = 	b.[Google Plus Page]  
			,a.[Hide Directory Profile] = 	b.[Hide Directory Profile]  
			,a.[Industry] = 	b.[Industry]  
			,a.[LinkedIn Company Page] = 	b.[LinkedIn Company Page]  
			,a.[Number of Employees] = 	b.[Number of Employees]  
			,a.[Phone Number] = 	b.[Phone Number]  
			,a.[Postal Code] = 	b.[Postal Code]  
			,a.[Public Profile URL] = 	b.[Public Profile URL]  
			---- following fields commented with M2-5177
			----,a.[RFQ Access Capabilities 0] = 	b.[RFQ Access Capabilities 0]  
			----,a.[RFQ Access Capabilities 1] = 	b.[RFQ Access Capabilities 1]  
			,a.[State/Region] = 	b.[State/Region]  
			,a.[Street Address] = 	b.[Street Address]  
			,a.[Street Address 2] = 	b.[Street Address 2]  
			,a.[Manufacturing Location] = 	b.[Manufacturing Location]  
			,a.[Twitter Handle] = 	b.[Twitter Handle]  
			,a.[IsSynced] = 	0  
			,a.[SyncedDate] = 	@SyncedDate 
			,a.[SyncedDateIST] = 	@SyncedDateIST  
			,a.[IsProcessed] = 	NULL  
			,a.[Number of Employees Text] = [NumberofEmployeesText]
			,a.[IsProfilePublished] = b.[IsProfilePublished] 
		FROM DataSync_MarketplaceHubSpot.dbo.HubSpotCompanies a
		JOIN 
		(
			SELECT 
				[Vision Account Id]
				,   b.is_buyer AS  [IsBuyerAccount]
				,	CASE 
						WHEN b.is_buyer = 1 THEN ''
						WHEN (SELECT TOP 1 account_type FROM mp_registered_supplier (NOLOCK) a1 WHERE a.[Vision Account Id] = a1.company_id) = 84 THEN 'Growth'
						WHEN (SELECT TOP 1 account_type FROM mp_registered_supplier (NOLOCK) a1 WHERE a.[Vision Account Id] = a1.company_id) = 85 THEN 'Gold'
						WHEN (SELECT TOP 1 account_type FROM mp_registered_supplier (NOLOCK) a1 WHERE a.[Vision Account Id] = a1.company_id) = 86 THEN 'Platinum'
						WHEN (SELECT TOP 1 account_type FROM mp_registered_supplier (NOLOCK) a1 WHERE a.[Vision Account Id] = a1.company_id) = 313 THEN 'Starter'
						ELSE 'Basic'
					END [Account Paid Status]
				, CASE WHEN b.is_buyer = 1 THEN c.[Company City] ELSE '' END [Buyer Company City]
				, CASE WHEN b.is_buyer = 1 THEN c.[Company Country] ELSE '' END [Buyer Company Country]
				, CASE WHEN b.is_buyer = 1 THEN k.communication_value ELSE '' END AS [Buyer Company Phone]
				, CASE WHEN b.is_buyer = 1 THEN c.[Company Postal Code] ELSE '' END [Buyer Company Postal Code]
				, CASE WHEN b.is_buyer = 1 THEN c.[Company State] ELSE '' END [Buyer Company State]
				, CASE WHEN b.is_buyer = 1 THEN c.[Company Street Address] ELSE '' END [Buyer Company Street Address]
				, CASE WHEN b.is_buyer = 1 THEN c.[Company Street Address 2] ELSE '' END [Buyer Company Address 2]
				, d.cage_code AS [Cage Code]
				, CASE WHEN b.is_buyer = 0 THEN c.[Company City] ELSE '' END [City]
				, d.name AS [Company Name]
				, d.assigned_sourcingadvisor AS [Company Owner Id]
				, CASE WHEN b.is_buyer = 0 THEN c.[Company Country] ELSE '' END [Country]
				, d.created_date AS [Create Date]
				--, d.assigned_customer_rep AS  [Customer Service Rep Id] --- Commented with M2-5176 
				, NULL AS  [Customer Service Rep Id] -- updated with M2-5176 
				, CASE WHEN b.is_buyer = 0 THEN e.disciplines0  END   AS [Discipline Level 0]
				, CASE WHEN b.is_buyer = 0 THEN f.disciplines1  END   AS [Discipline Level 1]
				, d.duns_number AS [Duns Number] 
				, NULL AS [Facebook Company Page]
				, NULL AS [Google Plus Page]
				, CASE WHEN b.is_buyer = 0 THEN ISNULL(d.is_hide_directory_profile, CAST('false' AS BIT))  END AS [Hide Directory Profile]
				, g.industries AS [Industry]
				, NULL AS [LinkedIn Company Page]
				, d.employee_count_range_id AS [Number of Employees]
				, CASE WHEN b.is_buyer = 0 THEN k.communication_value ELSE '' END  AS [Phone Number]
				, CASE WHEN b.is_buyer = 0 THEN c.[Company Postal Code]  END AS [Postal Code]
				, CASE WHEN b.is_buyer = 0 THEN h.PublicProfileUrl  END  AS [Public Profile URL]
				---- following fields commented with M2-5177
				----, CASE WHEN b.is_buyer = 0 THEN i.disciplines0  END  AS [RFQ Access Capabilities 0]
				----, CASE WHEN b.is_buyer = 0 THEN j.disciplines1  END  AS [RFQ Access Capabilities 1]
				---- modified with M2-5177
				, NULL AS [RFQ Access Capabilities 0]
				, NULL AS [RFQ Access Capabilities 1]
				, CASE WHEN b.is_buyer = 0 THEN c.[Company State]  END AS [State/Region]
				, CASE WHEN b.is_buyer = 0 THEN c.[Company Street Address]  END AS [Street Address]
				, CASE WHEN b.is_buyer = 0 THEN c.[Company Street Address 2]  END AS [Street Address 2]
				, d.manufacturing_location_id AS [Manufacturing Location]
				, NULL AS [Twitter Handle]
				, @SyncedDate		AS [SyncedDate]
				, @SyncedDateIST	AS [SyncedDateIST]
				, CASE WHEN d.employee_count_range_id = 1 THEN '1-2'
			       WHEN d.employee_count_range_id = 2 THEN '3-9'
				   WHEN d.employee_count_range_id = 3 THEN '10-49'
				   WHEN d.employee_count_range_id = 4 THEN '50-99'
				   WHEN d.employee_count_range_id = 5 THEN '100-249'
				   WHEN d.employee_count_range_id = 6 THEN '250+'
				   ELSE ''
			  END AS [NumberofEmployeesText]
			, CASE WHEN d.[ProfileStatus] = 234 THEN 1 ELSE 0 END AS [IsProfilePublished] ---- Added with M2-5083
			FROM DataSync_MarketplaceHubSpot.dbo.MarketplaceToHubSpotContactCompaniesCreateLogs a (NOLOCK) 
			JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesType b ON a.[Vision Account Id] = b.company_id
			LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesAddress c ON  a.[Vision Account Id] = c.company_id
			LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesInfo d ON  a.[Vision Account Id] = d.company_id
			LEFT JOIN 
			(
				SELECT
				company_id, 
				STRING_AGG(part_category_id,';') disciplines0
				FROM
					#tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesDiscipline0
				GROUP BY
					company_id
			) e ON  a.[Vision Account Id] = e.company_id
			LEFT JOIN 
			(
				SELECT
				company_id, 
				STRING_AGG(part_category_id,';') disciplines1
				FROM
					#tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesDiscipline1
				GROUP BY
					company_id
			) f ON  a.[Vision Account Id] = f.company_id
			LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesIndustries    g on a.[Vision Account Id] = g.company_id  
			LEFT JOIN 
			(
				SELECT 	
					a.company_id , 
					@PublicProfileURL
					+ CASE 
						WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(a.name),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
						ELSE ISNULL(REPLACE(REPLACE(REPLACE(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(dbo.removespecialchars(a.name))),' ','-'),'__','-'),'___','-') ),'--','-'),'---','-'),'----','-'),'-----','-'),'') + '-' 
					  END 
					+ CASE 
						WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(a.name),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
						WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(c.[Company City]),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
						ELSE ISNULL(REPLACE(REPLACE(REPLACE(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(dbo.removespecialchars(c.[Company City]))),' ','-'),'__','-'),'___','-') ),'--','-'),'---','-'),'----','-'),'-----','-'),'') +  '-'
						END 
					+ CASE 
						WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(a.name),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
						WHEN LEN(ISNULL(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(dbo.removespecialchars(c.[Company State]),' ','-'),'__','-'),'___','-') ),'--','-'),'')) = 0 THEN '' 
						ELSE ISNULL(REPLACE(REPLACE(REPLACE(REPLACE(LOWER(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(dbo.removespecialchars(c.[Company State]))),' ','-'),'__','-'),'___','-') ),'--','-'),'---','-'),'----','-'),'-----','-'),'')  +  '-'
						END
					+  CONVERT(VARCHAR(100),a.company_id)  AS  PublicProfileUrl
				FROM #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesInfo  a (NOLOCK)
				LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesAddress	c (NOLOCK) ON a.company_id = c.company_id
		
			) h ON a.[Vision Account Id] = h.company_id 
			LEFT JOIN 
			(
				SELECT
				company_id, 
				STRING_AGG(part_category_id,';') disciplines0
				FROM
					#tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesQuotingDiscipline0
				GROUP BY
					company_id
			) i ON  a.[Vision Account Id] = i.company_id
			LEFT JOIN 
			(
				SELECT
				company_id, 
				STRING_AGG(part_category_id,';') disciplines1
				FROM
					#tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesQuotingDiscipline1
				GROUP BY
					company_id
			) j ON  a.[Vision Account Id] = j.company_id
			LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompanyCommunications k (NOLOCK) ON a.[Vision Account Id] = k.company_id AND k.Rn = 1
			WHERE a.[IsProcessed] IS NULL AND a.[Vision Contact Id] IS NULL AND a.[SyncType] = 'Scheduler - Update - 30 Minutes'
			AND EXISTS (SELECT 1 FROM DataSync_MarketplaceHubSpot.dbo.HubSpotCompanies b (NOLOCK) WHERE a.[Vision Account Id] = b.[Vision Account Id] )
		
		) b ON a.[Vision Account Id] = b.[Vision Account Id] AND a.SyncType IS NULL
		
		-- contact details
		SELECT 
			b.contact_id ,b.company_id , b.is_buyer ,b.first_name ,b.last_name ,b.address_id ,b.[user_id] ,c.email ,d.seller_cont_id ,e.buyer_cont_id , b.is_validated_buyer
			,(
				CASE 
					WHEN  d.seller_cont_id IS NULL AND  e.buyer_cont_id IS NOT NULL THEN h.company_id 
					WHEN  d.seller_cont_id IS NOT NULL AND  e.buyer_cont_id IS NULL THEN f.company_id
				END
			) dualaccount_company_id
			,(
				CASE 
					WHEN  d.seller_cont_id IS NULL AND  e.buyer_cont_id IS NOT NULL THEN h.first_name
					WHEN  d.seller_cont_id IS NOT NULL AND  e.buyer_cont_id IS NULL THEN f.first_name
				END
			) dualaccount_first_name
			,(
				CASE 
					WHEN  d.seller_cont_id IS NULL AND  e.buyer_cont_id IS NOT NULL THEN h.last_name
					WHEN  d.seller_cont_id IS NOT NULL AND  e.buyer_cont_id IS NULL THEN f.last_name
				END
			) dualaccount_last_name
			,(
				CASE 
					WHEN  d.seller_cont_id IS NULL AND  e.buyer_cont_id IS NOT NULL THEN h.address_id
					WHEN  d.seller_cont_id IS NOT NULL AND  e.buyer_cont_id IS NULL THEN f.address_id
				END
			) dualaccount_address_id
			, j.manufacturing_location_id AS territory
			,(
				CASE 
					WHEN  d.seller_cont_id IS NULL AND  e.buyer_cont_id IS NOT NULL THEN l.manufacturing_location_id 
					WHEN  d.seller_cont_id IS NOT NULL AND  e.buyer_cont_id IS NULL THEN k.manufacturing_location_id
				END
			) AS dualaccount_territory
			,(
				CASE 
					WHEN  d.seller_cont_id IS NULL AND  e.buyer_cont_id IS NOT NULL THEN h.is_validated_buyer
					WHEN  d.seller_cont_id IS NOT NULL AND  e.buyer_cont_id IS NULL THEN f.is_validated_buyer
				END
			) AS dualaccount_is_validated_buyer

		INTO #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo
		FROM DataSync_MarketplaceHubSpot.dbo.MarketplaceToHubSpotContactCompaniesCreateLogs  a (NOLOCK) 
		JOIN mp_contacts  b (NOLOCK) ON  a.[Vision Contact Id] = b.contact_id AND a.[IsProcessed] IS NULL  AND a.[Vision Account Id] IS NULL
		JOIN AspNetUsers  c (NOLOCK) ON b.user_id = c.id
		LEFT JOIN  
		(
			SELECT buyer_cont_id , seller_cont_id FROM mp_contacts_buyersellerassociation (NOLOCK)
		
		) d ON b.contact_id = d.buyer_cont_id
		LEFT JOIN  
		(
			SELECT seller_cont_id , buyer_cont_id FROM mp_contacts_buyersellerassociation (NOLOCK)
		
		) e ON b.contact_id = e.seller_cont_id
		LEFT JOIN mp_contacts  f (NOLOCK) ON d.seller_cont_id = f.contact_id
		LEFT JOIN AspNetUsers  g (NOLOCK) ON f.user_id = g.id
		LEFT JOIN mp_contacts  h (NOLOCK) ON e.buyer_cont_id = h.contact_id
		LEFT JOIN AspNetUsers  i (NOLOCK) ON h.user_id = i.id
		JOIN mp_companies	   j (NOLOCK) ON b.company_id = j.company_id
		LEFT JOIN mp_companies	   k (NOLOCK) ON f.company_id = k.company_id
		LEFT JOIN mp_companies	   l (NOLOCK) ON h.company_id = l.company_id
		WHERE a.[SyncType] = 'Scheduler - Update - 30 Minutes'
	
		-- contact address
		SELECT 
			a.address_id 
			,b.address1 AS [Contact Street Address]
			,b.address2 AS [Contact Street Address 2]
			,b.address4 AS [Contact City] 
			,c.region_name AS [Contact State]
			,b.address3 AS [Contact Postal Code]
			,d.country_name AS [Contact Country]
			,d.iso_code AS [Contact Country Code]
		INTO #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsAddress
		FROM 
		(
			SELECT address_id FROM #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo
			UNION
			SELECT dualaccount_address_id FROM #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo WHERE dualaccount_address_id IS NOT NULL
		) a
		JOIN mp_addresses			b (NOLOCK) ON a.address_id = b.address_id  AND a.address_id IS NOT NULL
		LEFT JOIN mp_mst_region		c (NOLOCK) ON b.region_id = c.region_id AND b.region_id <> 0
		LEFT JOIN mp_mst_country	d (NOLOCK) ON b.country_id = d.country_id AND b.country_id <> 0

		-- contact communication details
		SELECT 
			communication_id , contact_id , communication_type_id , communication_value  
			, ROW_NUMBER() OVER (PARTITION BY contact_id , communication_type_id ORDER BY contact_id , communication_type_id , communication_id DESC) Rn 
		INTO #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactCommunications
		FROM mp_communication_details (NOLOCK)
		WHERE communication_type_id IN  (1,2,4,5) AND contact_id <> 0
		AND contact_id IN 
		(
			SELECT contact_id FROM #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo
			UNION
			SELECT seller_cont_id FROM #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo WHERE seller_cont_id IS NOT NULL
			UNION
			SELECT buyer_cont_id FROM #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo WHERE buyer_cont_id IS NOT NULL
		)
	
		SELECT DISTINCT
			b.email				AS [Email]
			, NULL					AS [HubSpot Contact Id]
			, b.user_id				AS [Contact Id]
			, (CASE WHEN b.is_buyer = 1 THEN b.contact_id ELSE b.buyer_cont_id END) AS [Vision Buyer Id]
			, (CASE WHEN b.is_buyer = 1 THEN b.company_id ELSE b.dualaccount_company_id END) AS [Vision Buyer Account Id]
			, NULL					AS [HubSpot Buyer Account Id]
			, (CASE WHEN b.is_buyer = 0 THEN b.contact_id ELSE b.seller_cont_id END) AS [Vision Supplier Id]
			, (CASE WHEN b.is_buyer = 0 THEN b.company_id ELSE b.dualaccount_company_id END) AS [Vision Supplier Account Id]
			, NULL					AS [HubSpot Supplier Account Id]
			, (CASE WHEN b.is_buyer = 1 THEN c.[Contact City] ELSE d.[Contact City] END) AS [Buyer City]
			, (CASE WHEN b.is_buyer = 1 THEN c.[Contact Country] ELSE d.[Contact Country] END) AS [Buyer Country]
			, (CASE WHEN b.is_buyer = 1 THEN b.first_name ELSE b.dualaccount_first_name END) AS [Buyer First Name]				
			, (CASE WHEN b.is_buyer = 1 THEN b.last_name ELSE b.dualaccount_last_name END) AS [Buyer Last Name]				
			, NULL AS [Buyer Phone]
			, (CASE WHEN b.is_buyer = 1 THEN c.[Contact Postal Code] ELSE d.[Contact Postal Code] END) AS [Buyer Postal Code]
			, (CASE WHEN b.is_buyer = 1 THEN c.[Contact State] ELSE d.[Contact State] END) AS [Buyer State]
			, (CASE WHEN b.is_buyer = 1 THEN c.[Contact Street Address] ELSE d.[Contact Street Address] END) AS [Buyer Street Address]
			, (CASE WHEN b.is_buyer = 1 THEN c.[Contact Street Address 2] ELSE d.[Contact Street Address 2] END) AS [Buyer Street Address 2]
			, (CASE WHEN b.is_buyer = 1 THEN b.territory ELSE b.dualaccount_territory END)  AS [Buyer Territory]
			, (CASE WHEN b.is_buyer = 0 THEN c.[Contact City] ELSE d.[Contact City] END) AS [City]
			, (CASE WHEN b.is_buyer = 0 THEN c.[Contact Country] ELSE d.[Contact Country] END) AS [Country]
			, (CASE WHEN b.is_buyer = 0 THEN c.[Contact State] ELSE d.[Contact State] END) AS [Country/Region]
			, NULL AS [Fax]
			, (CASE WHEN b.is_buyer = 0 THEN b.first_name ELSE b.dualaccount_first_name END) AS [First Name]
			, NULL AS [First RFQ Release Date]
			, NULL AS [Industry]
			, (CASE WHEN b.is_buyer = 0 THEN b.last_name ELSE b.dualaccount_last_name END) AS [Last Name]
			, NULL AS [Last Upgrade Request Date]
			, CASE 
				WHEN b.is_buyer = 1 AND ISNULL(b.seller_cont_id,0)> 0 THEN 'Both' 
				WHEN b.is_buyer = 1 AND ISNULL(b.seller_cont_id,0)= 0 THEN 'Buyer' 
				WHEN b.is_buyer = 0 AND ISNULL(b.buyer_cont_id,0)> 0 THEN 'Both'
				WHEN b.is_buyer = 0 AND ISNULL(b.buyer_cont_id,0)= 0 THEN 'Supplier'
			  END AS [MFG Contact Type]
			, NULL  AS [Mobile Phone]
			, NULL AS [Most Recent RFQ Release Date]
			, NULL AS [Number of RFQs]
			, NULL AS [Phone]
			, (CASE WHEN b.is_buyer = 0 THEN c.[Contact Postal Code] ELSE d.[Contact Postal Code] END) AS [Postal Code]
			, (CASE WHEN b.is_buyer = 0 THEN c.[Contact State] ELSE d.[Contact State] END) AS [State/Region]
			, (CASE WHEN b.is_buyer = 0 THEN c.[Contact Street Address] ELSE d.[Contact Street Address] END) AS [Street Address]
			, (CASE WHEN b.is_buyer = 0 THEN b.territory ELSE b.dualaccount_territory END) AS [Territory]
			, NULL AS [Unsubscribed from all email]
			, NULL AS [Upgrade Request]
			, NULL AS [Vision RFQ Validated]
			, NULL AS [Website URL]
			, CAST('false' AS BIT)	AS [IsSynced]
			, @SyncedDate			AS [SyncedDate]
			, @SyncedDateIST		AS [SyncedDateIST]
		INTO #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo1
		FROM DataSync_MarketplaceHubSpot.dbo.MarketplaceToHubSpotContactCompaniesCreateLogs a (NOLOCK) 
		JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo b ON a.[Vision Contact Id] = b.contact_id
		LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsAddress c ON b.address_id = c.address_id
		LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsAddress d ON b.dualaccount_address_id = d.address_id
		WHERE a.[IsProcessed] IS NULL AND a.[Vision Account Id] IS NULL AND a.[SyncType] = 'Scheduler - Update - 30 Minutes'

		
		--- below code commented on 27-Feb-2023 for created duplicate companies records
		-- inserting new records
		/*
		INSERT INTO  DataSync_MarketplaceHubSpot.dbo.HubSpotContacts
		(
			[Email], [HubSpot Contact Id], [Contact Id], [Vision Buyer Id], [Vision Buyer Account Id], [HubSpot Buyer Account Id], [Vision Supplier Id]
		, [Vision Supplier Account Id], [HubSpot Supplier Account Id], [Buyer City], [Buyer Country] 	,[Buyer First Name]	,[Buyer Last Name]	 , [Buyer Phone], [Buyer Postal Code], [Buyer State], [Buyer Street Address], [Buyer Street Address 2]
			, [Buyer Territory], [City], [Country], [Country/Region], [Fax], [First Name], [First RFQ Release Date], [Industry], [Last Name], [Last Upgrade Request Date]
			, [MFG Contact Type], [Mobile Phone], [Most Recent RFQ Release Date], [Number of RFQs], [Phone], [Postal Code], [State/Region], [Street Address], [Territory]
			, [Unsubscribed from all email], [Upgrade Request], [Vision RFQ Validated], [Website URL], [IsSynced], [SyncedDate], [SyncedDateIST]
		)
		SELECT 
			a.[Email], a.[HubSpot Contact Id], a.[Contact Id], a.[Vision Buyer Id], a.[Vision Buyer Account Id], a.[HubSpot Buyer Account Id], a.[Vision Supplier Id]
			, a.[Vision Supplier Account Id], a.[HubSpot Supplier Account Id], a.[Buyer City], a.[Buyer Country] 	,[Buyer First Name]	,[Buyer Last Name]	 
			, b.[communication_value] [Buyer Phone], a.[Buyer Postal Code], a.[Buyer State], a.[Buyer Street Address], a.[Buyer Street Address 2]
			, a.[Buyer Territory], a.[City], a.[Country], a.[Country], a.[Fax], a.[First Name]
			, e.[First RFQ Release Date] [First RFQ Release Date], a.[Industry], a.[Last Name]
			, f.[Last Upgrade Request Date] [Last Upgrade Request Date]
			, a.[MFG Contact Type], a.[Mobile Phone], e.[Most Recent RFQ Release Date] [Most Recent RFQ Release Date]
			, e.[Number of RFQs Released] [Number of RFQs]
			, c.communication_value AS [Phone], a.[Postal Code], a.[State/Region], a.[Street Address], a.[Territory]
			, a.[Unsubscribed from all email]
			, (CASE WHEN f.[Last Upgrade Request Date] IS NULL THEN 0 ELSE 1 END) [Upgrade Request]
			, d.Is_Validated_Buyer AS [Vision RFQ Validated]
			, CASE 
				WHEN a.[Vision Buyer Id] IS NOT NULL AND  a.[Vision Supplier Id] IS NULL THEN g.communication_value
				WHEN a.[Vision Buyer Id] IS NULL AND  a.[Vision Supplier Id] IS NOT NULL THEN h.communication_value
				ELSE h.communication_value
			  END [Website URL]
			, a.[IsSynced], a.[SyncedDate], a.[SyncedDateIST]
		FROM #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo1 a
		LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactCommunications b ON a.[Vision Buyer Id] = b.contact_id AND b.Rn =1 AND b.communication_type_id = 1
		LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactCommunications c ON a.[Vision Supplier Id] = c.contact_id AND c.Rn =1 AND c.communication_type_id = 1
		--LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo d ON a.[Vision Buyer Id] = d.contact_id
		LEFT JOIN 
		(
			SELECT contact_id , is_validated_buyer FROM #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo WHERE is_buyer = 1
			UNION
			SELECT buyer_cont_id , dualaccount_is_validated_buyer FROM #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo WHERE is_buyer = 0 AND buyer_cont_id IS NOT NULL
		) d ON a.[Vision Buyer Id] = d.contact_id
		LEFT JOIN 
		(
			SELECT 
				b.contact_id  , MIN(a.status_date) [First RFQ Release Date] 
				, MAX(a.status_date) [Most Recent RFQ Release Date]
				, COUNT(DISTINCT a.rfq_id) as [Number of RFQs Released]
			FROM mp_rfq_release_history (NOLOCK) a
			JOIN mp_rfq					(NOLOCK) b ON a.rfq_id = b.rfq_id
			GROUP BY b.contact_id
		) e ON a.[Vision Buyer Id] = e.contact_id
		LEFT JOIN
		(
			SELECT 
				contact_id , MAX(activity_date) [Last Upgrade Request Date]
			FROM mp_track_user_activities (NOLOCK) WHERE activity_id IN (3,14)
			GROUP BY contact_id
		) f ON a.[Vision Supplier Id] = f.contact_id
		LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactCommunications g ON a.[Vision Buyer Id] = g.contact_id AND g.Rn =1 AND g.communication_type_id = 4
		LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactCommunications h ON a.[Vision Supplier Id] = h.contact_id AND h.Rn =1 AND h.communication_type_id = 4
		WHERE NOT EXISTS (SELECT 1 FROM DataSync_MarketplaceHubSpot.dbo.HubSpotContacts b (NOLOCK) WHERE a.Email = b.Email )
		*/

		-- inserting contact update log
		INSERT INTO  DataSync_MarketplaceHubSpot.dbo.HubSpotContactsUpdateLogs
		(
			[Email], [Contact Id], [Vision Buyer Id], [Vision Buyer Account Id], [Vision Supplier Id]
			, [Vision Supplier Account Id], [Buyer City], [Buyer Country] 	,[Buyer First Name]	,[Buyer Last Name]	 , [Buyer Phone], [Buyer Postal Code], [Buyer State]
			, [Buyer Street Address], [Buyer Street Address 2]
			, [Buyer Territory], [City], [Country], [Country/Region], [Fax], [First Name], [First RFQ Release Date], [Industry], [Last Name], [Last Upgrade Request Date]
			, [MFG Contact Type], [Mobile Phone], [Most Recent RFQ Release Date], [Number of RFQs], [Phone], [Postal Code], [State/Region], [Street Address], [Territory]
			, [Unsubscribed from all email], [Upgrade Request], [Vision RFQ Validated], [Website URL], [SyncedDate], [SyncedDateIST]
		)
		SELECT 
			b.[Email], b.[Contact Id], b.[Vision Buyer Id], b.[Vision Buyer Account Id], b.[Vision Supplier Id]
			, b.[Vision Supplier Account Id], b.[Buyer City], b.[Buyer Country] 	,b.[Buyer First Name]	,b.[Buyer Last Name]	 
			, b.[Buyer Phone], b.[Buyer Postal Code], b.[Buyer State], b.[Buyer Street Address], b.[Buyer Street Address 2]
			, b.[Buyer Territory], b.[City], b.[Country], b.[Country], b.[Fax], b.[First Name]
			, b.[First RFQ Release Date], b.[Industry], b.[Last Name]
			, b.[Last Upgrade Request Date]
			, b.[MFG Contact Type], b.[Mobile Phone], b.[Most Recent RFQ Release Date]
			, b.[Number of RFQs]
			, b.[Phone], b.[Postal Code], b.[State/Region], b.[Street Address], b.[Territory]
			, b.[Unsubscribed from all email]
			, b.[Upgrade Request]
			, b.[Vision RFQ Validated]
			, b.[Website URL]
			, b.[SyncedDate], b.[SyncedDateIST] 
		FROM DataSync_MarketplaceHubSpot.dbo.HubSpotContacts (NOLOCK) a
		JOIN
		(
			SELECT 
			a.[Email], a.[Contact Id], a.[Vision Buyer Id], a.[Vision Buyer Account Id], a.[Vision Supplier Id]
			, a.[Vision Supplier Account Id], a.[Buyer City], a.[Buyer Country] 	,[Buyer First Name]	,[Buyer Last Name]	 
			, b.[communication_value] [Buyer Phone], a.[Buyer Postal Code], a.[Buyer State], a.[Buyer Street Address], a.[Buyer Street Address 2]
			, a.[Buyer Territory], a.[City], a.[Country], a.[Country/Region], a.[Fax], a.[First Name]
			, e.[First RFQ Release Date] [First RFQ Release Date], a.[Industry], a.[Last Name]
			, f.[Last Upgrade Request Date] [Last Upgrade Request Date]
			, a.[MFG Contact Type], a.[Mobile Phone], e.[Most Recent RFQ Release Date] [Most Recent RFQ Release Date]
			, e.[Number of RFQs Released] [Number of RFQs]
			, c.communication_value AS [Phone], a.[Postal Code], a.[State/Region], a.[Street Address], a.[Territory]
			, a.[Unsubscribed from all email]
			, (CASE WHEN f.[Last Upgrade Request Date] IS NULL THEN 0 ELSE 1 END) [Upgrade Request]
			, d.Is_Validated_Buyer AS [Vision RFQ Validated]
			, CASE 
				WHEN a.[Vision Buyer Id] IS NOT NULL AND  a.[Vision Supplier Id] IS NULL THEN g.communication_value
				WHEN a.[Vision Buyer Id] IS NULL AND  a.[Vision Supplier Id] IS NOT NULL THEN h.communication_value
				ELSE h.communication_value
			  END [Website URL]
			, a.[IsSynced], a.[SyncedDate], a.[SyncedDateIST]
			FROM #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo1 a
			LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactCommunications b ON a.[Vision Buyer Id] = b.contact_id AND b.Rn =1 AND b.communication_type_id = 1
			LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactCommunications c ON a.[Vision Supplier Id] = c.contact_id AND c.Rn =1 AND c.communication_type_id = 1
			--LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo d ON a.[Vision Buyer Id] = d.contact_id
			LEFT JOIN 
			(
				SELECT contact_id , is_validated_buyer FROM #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo WHERE is_buyer = 1
				UNION
				SELECT buyer_cont_id , dualaccount_is_validated_buyer FROM #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo WHERE is_buyer = 0 AND buyer_cont_id IS NOT NULL
			) d ON a.[Vision Buyer Id] = d.contact_id
			LEFT JOIN 
			(
				SELECT 
					b.contact_id  , MIN(a.status_date) [First RFQ Release Date] 
					, MAX(a.status_date) [Most Recent RFQ Release Date]
					, COUNT(DISTINCT a.rfq_id) as [Number of RFQs Released]
				FROM mp_rfq_release_history (NOLOCK) a
				JOIN mp_rfq					(NOLOCK) b ON a.rfq_id = b.rfq_id
				GROUP BY b.contact_id
			) e ON a.[Vision Buyer Id] = e.contact_id
			LEFT JOIN
			(
				SELECT 
					contact_id , MAX(activity_date) [Last Upgrade Request Date]
				FROM mp_track_user_activities (NOLOCK) WHERE activity_id IN (3,14)
				GROUP BY contact_id
			) f ON a.[Vision Supplier Id] = f.contact_id
			LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactCommunications g ON a.[Vision Buyer Id] = g.contact_id AND g.Rn =1 AND g.communication_type_id = 4
			LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactCommunications h ON a.[Vision Supplier Id] = h.contact_id AND h.Rn =1 AND h.communication_type_id = 4
		) b ON a.Email = b.Email

		
		/*  M2-4938 Added below code */
		-- inserting contact update log
		INSERT INTO  DataSync_MarketplaceHubSpot.dbo.HubSpotContactsUpdateLogs
		(
			[Email], [Contact Id], [Vision Buyer Id], [Vision Buyer Account Id], [Vision Supplier Id]
			, [Vision Supplier Account Id], [Buyer City], [Buyer Country] 	,[Buyer First Name]	,[Buyer Last Name]	 , [Buyer Phone], [Buyer Postal Code], [Buyer State]
			, [Buyer Street Address], [Buyer Street Address 2]
			, [Buyer Territory], [City], [Country], [Country/Region], [Fax], [First Name], [First RFQ Release Date], [Industry], [Last Name], [Last Upgrade Request Date]
			, [MFG Contact Type], [Mobile Phone], [Most Recent RFQ Release Date], [Number of RFQs], [Phone], [Postal Code], [State/Region], [Street Address], [Territory]
			, [Unsubscribed from all email], [Upgrade Request], [Vision RFQ Validated], [Website URL], [SyncedDate], [SyncedDateIST]
		)
		SELECT 
			b.[Email], b.[Contact Id], b.[Vision Buyer Id], b.[Vision Buyer Account Id], b.[Vision Supplier Id]
			, b.[Vision Supplier Account Id], b.[Buyer City], b.[Buyer Country] 	,b.[Buyer First Name]	,b.[Buyer Last Name]	 
			, b.[Buyer Phone], b.[Buyer Postal Code], b.[Buyer State], b.[Buyer Street Address], b.[Buyer Street Address 2]
			, b.[Buyer Territory], b.[City], b.[Country], b.[Country], b.[Fax], b.[First Name]
			, b.[First RFQ Release Date], b.[Industry], b.[Last Name]
			, b.[Last Upgrade Request Date]
			, b.[MFG Contact Type], b.[Mobile Phone], b.[Most Recent RFQ Release Date]
			, b.[Number of RFQs]
			, b.[Phone], b.[Postal Code], b.[State/Region], b.[Street Address], b.[Territory]
			, b.[Unsubscribed from all email]
			, b.[Upgrade Request]
			, b.[Vision RFQ Validated]
			, b.[Website URL]
			, b.[SyncedDate], b.[SyncedDateIST] 
		FROM DataSync_MarketplaceHubSpot.dbo.HubSpotContacts (NOLOCK) a
		JOIN
		(
			SELECT 
			a.[Email], a.[Contact Id], a.[Vision Buyer Id], a.[Vision Buyer Account Id], a.[Vision Supplier Id]
			, a.[Vision Supplier Account Id], a.[Buyer City], a.[Buyer Country] 	,[Buyer First Name]	,[Buyer Last Name]	 
			, b.[communication_value] [Buyer Phone], a.[Buyer Postal Code], a.[Buyer State], a.[Buyer Street Address], a.[Buyer Street Address 2]
			, a.[Buyer Territory], a.[City], a.[Country], a.[Country/Region], a.[Fax], a.[First Name]
			, e.[First RFQ Release Date] [First RFQ Release Date], a.[Industry], a.[Last Name]
			, f.[Last Upgrade Request Date] [Last Upgrade Request Date]
			, a.[MFG Contact Type], a.[Mobile Phone], e.[Most Recent RFQ Release Date] [Most Recent RFQ Release Date]
			, e.[Number of RFQs Released] [Number of RFQs]
			, c.communication_value AS [Phone], a.[Postal Code], a.[State/Region], a.[Street Address], a.[Territory]
			, a.[Unsubscribed from all email]
			, (CASE WHEN f.[Last Upgrade Request Date] IS NULL THEN 0 ELSE 1 END) [Upgrade Request]
			, d.Is_Validated_Buyer AS [Vision RFQ Validated]
			, CASE 
				WHEN a.[Vision Buyer Id] IS NOT NULL AND  a.[Vision Supplier Id] IS NULL THEN g.communication_value
				WHEN a.[Vision Buyer Id] IS NULL AND  a.[Vision Supplier Id] IS NOT NULL THEN h.communication_value
				ELSE h.communication_value
			  END [Website URL]
			, a.[IsSynced], a.[SyncedDate], a.[SyncedDateIST]
			FROM #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo1 a
			LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactCommunications b ON a.[Vision Buyer Id] = b.contact_id AND b.Rn =1 AND b.communication_type_id = 1
			LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactCommunications c ON a.[Vision Supplier Id] = c.contact_id AND c.Rn =1 AND c.communication_type_id = 1
			--LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo d ON a.[Vision Buyer Id] = d.contact_id
			LEFT JOIN 
			(
				SELECT contact_id , is_validated_buyer FROM #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo WHERE is_buyer = 1
				UNION
				SELECT buyer_cont_id , dualaccount_is_validated_buyer FROM #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo WHERE is_buyer = 0 AND buyer_cont_id IS NOT NULL
			) d ON a.[Vision Buyer Id] = d.contact_id
			LEFT JOIN 
			(
				SELECT 
					b.contact_id  , MIN(a.status_date) [First RFQ Release Date] 
					, MAX(a.status_date) [Most Recent RFQ Release Date]
					, COUNT(DISTINCT a.rfq_id) as [Number of RFQs Released]
				FROM mp_rfq_release_history (NOLOCK) a
				JOIN mp_rfq					(NOLOCK) b ON a.rfq_id = b.rfq_id
				GROUP BY b.contact_id
			) e ON a.[Vision Buyer Id] = e.contact_id
			LEFT JOIN
			(
				SELECT 
					contact_id , MAX(activity_date) [Last Upgrade Request Date]
				FROM mp_track_user_activities (NOLOCK) WHERE activity_id IN (3,14)
				GROUP BY contact_id
			) f ON a.[Vision Supplier Id] = f.contact_id
			LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactCommunications g ON a.[Vision Buyer Id] = g.contact_id AND g.Rn =1 AND g.communication_type_id = 4
			LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactCommunications h ON a.[Vision Supplier Id] = h.contact_id AND h.Rn =1 AND h.communication_type_id = 4
		) b ON  
		a.[Contact Id] = b.[Contact Id] ---- this is unique identifier value of contact id 

		/*  */
		
		-- updating existing records
		UPDATE a SET 
			a.[Email] = b.[Email]
			/* ---- Below code commented on 14-Aug-2023 because ids fields can't updated */
			--,a.[HubSpot Contact Id] = b.[HubSpot Contact Id]
			--,a.[Contact Id] = b.[Contact Id]
			--,a.[Vision Buyer Id] = b.[Vision Buyer Id]
			--,a.[Vision Buyer Account Id] = b.[Vision Buyer Account Id]
			--,a.[HubSpot Buyer Account Id] = b.[HubSpot Buyer Account Id]
			--,a.[Vision Supplier Id] = b.[Vision Supplier Id]
			--,a.[Vision Supplier Account Id] = b.[Vision Supplier Account Id]
			--,a.[HubSpot Supplier Account Id] = b.[HubSpot Supplier Account Id]
			,a.[Buyer City] = b.[Buyer City]
			,a.[Buyer Country] = b.[Buyer Country]
			,a.[Buyer First Name] = b.[Buyer First Name]
			,a.[Buyer Last Name] = b.[Buyer Last Name]
			,a.[Buyer Phone] = b.[Buyer Phone]
			,a.[Buyer Postal Code] = b.[Buyer Postal Code]
			,a.[Buyer State] = b.[Buyer State]
			,a.[Buyer Street Address] = b.[Buyer Street Address]
			,a.[Buyer Street Address 2] = b.[Buyer Street Address 2]
			,a.[Buyer Territory] = b.[Buyer Territory]
			,a.[City] = b.[City]
			,a.[Country] = b.[Country]
			,a.[Country/Region] = b.[Country]
			,a.[Fax] = b.[Fax]
			,a.[First Name] = b.[First Name]
			,a.[First RFQ Release Date] = b.[First RFQ Release Date]
			,a.[Industry] = b.[Industry]
			,a.[Last Name] = b.[Last Name]
			,a.[Last Upgrade Request Date] = b.[Last Upgrade Request Date]
			,a.[MFG Contact Type] = b.[MFG Contact Type]
			,a.[Mobile Phone] = b.[Mobile Phone]
			,a.[Most Recent RFQ Release Date] = b.[Most Recent RFQ Release Date]
			,a.[Number of RFQs] = b.[Number of RFQs]
			,a.[Phone] = b.[Phone]
			,a.[Postal Code] = b.[Postal Code]
			,a.[State/Region] = b.[State/Region]
			,a.[Street Address] = b.[Street Address]
			,a.[Territory] = b.[Territory]
			,a.[Unsubscribed from all email] = b.[Unsubscribed from all email]
			,a.[Upgrade Request] = b.[Upgrade Request]
			,a.[Vision RFQ Validated] = b.[Vision RFQ Validated]
			,a.[Website URL] = b.[Website URL]
			,a.[IsSynced] = 0
			,a.[SyncedDate] = b.[SyncedDate]
			,a.[SyncedDateIST] = b.[SyncedDateIST]
			,a.[IsProcessed] = NULL
		FROM DataSync_MarketplaceHubSpot.dbo.HubSpotContacts (NOLOCK) a
		JOIN
		(
			SELECT 
			a.[Email], a.[HubSpot Contact Id], a.[Contact Id], a.[Vision Buyer Id], a.[Vision Buyer Account Id], a.[HubSpot Buyer Account Id], a.[Vision Supplier Id]
			, a.[Vision Supplier Account Id], a.[HubSpot Supplier Account Id], a.[Buyer City], a.[Buyer Country] 	,[Buyer First Name]	,[Buyer Last Name]	 
			, b.[communication_value] [Buyer Phone], a.[Buyer Postal Code], a.[Buyer State], a.[Buyer Street Address], a.[Buyer Street Address 2]
			, a.[Buyer Territory], a.[City], a.[Country], a.[Country/Region], a.[Fax], a.[First Name]
			, e.[First RFQ Release Date] [First RFQ Release Date], a.[Industry], a.[Last Name]
			, f.[Last Upgrade Request Date] [Last Upgrade Request Date]
			, a.[MFG Contact Type], a.[Mobile Phone], e.[Most Recent RFQ Release Date] [Most Recent RFQ Release Date]
			, e.[Number of RFQs Released] [Number of RFQs]
			, c.communication_value AS [Phone], a.[Postal Code], a.[State/Region], a.[Street Address], a.[Territory]
			, a.[Unsubscribed from all email]
			, (CASE WHEN f.[Last Upgrade Request Date] IS NULL THEN 0 ELSE 1 END) [Upgrade Request]
			, d.Is_Validated_Buyer AS [Vision RFQ Validated]
			, CASE 
				WHEN a.[Vision Buyer Id] IS NOT NULL AND  a.[Vision Supplier Id] IS NULL THEN g.communication_value
				WHEN a.[Vision Buyer Id] IS NULL AND  a.[Vision Supplier Id] IS NOT NULL THEN h.communication_value
				ELSE h.communication_value
			  END [Website URL]
			, a.[IsSynced], a.[SyncedDate], a.[SyncedDateIST]
			FROM #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo1 a
			LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactCommunications b ON a.[Vision Buyer Id] = b.contact_id AND b.Rn =1 AND b.communication_type_id = 1
			LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactCommunications c ON a.[Vision Supplier Id] = c.contact_id AND c.Rn =1 AND c.communication_type_id = 1
			--LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo d ON a.[Vision Buyer Id] = d.contact_id
			LEFT JOIN 
			(
				SELECT contact_id , is_validated_buyer FROM #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo WHERE is_buyer = 1
				UNION
				SELECT buyer_cont_id , dualaccount_is_validated_buyer FROM #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo WHERE is_buyer = 0 AND buyer_cont_id IS NOT NULL
			) d ON a.[Vision Buyer Id] = d.contact_id
			LEFT JOIN 
			(
				SELECT 
					b.contact_id  , MIN(a.status_date) [First RFQ Release Date] 
					, MAX(a.status_date) [Most Recent RFQ Release Date]
					, COUNT(DISTINCT a.rfq_id) as [Number of RFQs Released]
				FROM mp_rfq_release_history (NOLOCK) a
				JOIN mp_rfq					(NOLOCK) b ON a.rfq_id = b.rfq_id
				GROUP BY b.contact_id
			) e ON a.[Vision Buyer Id] = e.contact_id
			LEFT JOIN
			(
				SELECT 
					contact_id , MAX(activity_date) [Last Upgrade Request Date]
				FROM mp_track_user_activities (NOLOCK) WHERE activity_id IN (3,14)
				GROUP BY contact_id
			) f ON a.[Vision Supplier Id] = f.contact_id
			LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactCommunications g ON a.[Vision Buyer Id] = g.contact_id AND g.Rn =1 AND g.communication_type_id = 4
			LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactCommunications h ON a.[Vision Supplier Id] = h.contact_id AND h.Rn =1 AND h.communication_type_id = 4
		) b ON a.Email = b.Email


		/*  M2-4938 Added below code */
		-- updating existing records
		UPDATE a SET 
			a.[Email] = b.[Email]
			/* ---- Below code commented on 14-Aug-2023 because ids fields can't updated */
			--,a.[HubSpot Contact Id] = b.[HubSpot Contact Id]
			--,a.[Contact Id] = b.[Contact Id]
			--,a.[Vision Buyer Id] = b.[Vision Buyer Id]
			--,a.[Vision Buyer Account Id] = b.[Vision Buyer Account Id]
			--,a.[HubSpot Buyer Account Id] = b.[HubSpot Buyer Account Id]
			--,a.[Vision Supplier Id] = b.[Vision Supplier Id]
			--,a.[Vision Supplier Account Id] = b.[Vision Supplier Account Id]
			--,a.[HubSpot Supplier Account Id] = b.[HubSpot Supplier Account Id]
			,a.[Buyer City] = b.[Buyer City]
			,a.[Buyer Country] = b.[Buyer Country]
			,a.[Buyer First Name] = b.[Buyer First Name]
			,a.[Buyer Last Name] = b.[Buyer Last Name]
			,a.[Buyer Phone] = b.[Buyer Phone]
			,a.[Buyer Postal Code] = b.[Buyer Postal Code]
			,a.[Buyer State] = b.[Buyer State]
			,a.[Buyer Street Address] = b.[Buyer Street Address]
			,a.[Buyer Street Address 2] = b.[Buyer Street Address 2]
			,a.[Buyer Territory] = b.[Buyer Territory]
			,a.[City] = b.[City]
			,a.[Country] = b.[Country]
			,a.[Country/Region] = b.[Country]
			,a.[Fax] = b.[Fax]
			,a.[First Name] = b.[First Name]
			,a.[First RFQ Release Date] = b.[First RFQ Release Date]
			,a.[Industry] = b.[Industry]
			,a.[Last Name] = b.[Last Name]
			,a.[Last Upgrade Request Date] = b.[Last Upgrade Request Date]
			,a.[MFG Contact Type] = b.[MFG Contact Type]
			,a.[Mobile Phone] = b.[Mobile Phone]
			,a.[Most Recent RFQ Release Date] = b.[Most Recent RFQ Release Date]
			,a.[Number of RFQs] = b.[Number of RFQs]
			,a.[Phone] = b.[Phone]
			,a.[Postal Code] = b.[Postal Code]
			,a.[State/Region] = b.[State/Region]
			,a.[Street Address] = b.[Street Address]
			,a.[Territory] = b.[Territory]
			,a.[Unsubscribed from all email] = b.[Unsubscribed from all email]
			,a.[Upgrade Request] = b.[Upgrade Request]
			,a.[Vision RFQ Validated] = b.[Vision RFQ Validated]
			,a.[Website URL] = b.[Website URL]
			,a.[IsSynced] = 0
			,a.[SyncedDate] = b.[SyncedDate]
			,a.[SyncedDateIST] = b.[SyncedDateIST]
			,a.[IsProcessed] = NULL
		FROM DataSync_MarketplaceHubSpot.dbo.HubSpotContacts (NOLOCK) a
		JOIN
		(
			SELECT 
			a.[Email], a.[HubSpot Contact Id], a.[Contact Id], a.[Vision Buyer Id], a.[Vision Buyer Account Id], a.[HubSpot Buyer Account Id], a.[Vision Supplier Id]
			, a.[Vision Supplier Account Id], a.[HubSpot Supplier Account Id], a.[Buyer City], a.[Buyer Country] 	,[Buyer First Name]	,[Buyer Last Name]	 
			, b.[communication_value] [Buyer Phone], a.[Buyer Postal Code], a.[Buyer State], a.[Buyer Street Address], a.[Buyer Street Address 2]
			, a.[Buyer Territory], a.[City], a.[Country], a.[Country/Region], a.[Fax], a.[First Name]
			, e.[First RFQ Release Date] [First RFQ Release Date], a.[Industry], a.[Last Name]
			, f.[Last Upgrade Request Date] [Last Upgrade Request Date]
			, a.[MFG Contact Type], a.[Mobile Phone], e.[Most Recent RFQ Release Date] [Most Recent RFQ Release Date]
			, e.[Number of RFQs Released] [Number of RFQs]
			, c.communication_value AS [Phone], a.[Postal Code], a.[State/Region], a.[Street Address], a.[Territory]
			, a.[Unsubscribed from all email]
			, (CASE WHEN f.[Last Upgrade Request Date] IS NULL THEN 0 ELSE 1 END) [Upgrade Request]
			, d.Is_Validated_Buyer AS [Vision RFQ Validated]
			, CASE 
				WHEN a.[Vision Buyer Id] IS NOT NULL AND  a.[Vision Supplier Id] IS NULL THEN g.communication_value
				WHEN a.[Vision Buyer Id] IS NULL AND  a.[Vision Supplier Id] IS NOT NULL THEN h.communication_value
				ELSE h.communication_value
			  END [Website URL]
			, a.[IsSynced], a.[SyncedDate], a.[SyncedDateIST]
			FROM #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo1 a
			LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactCommunications b ON a.[Vision Buyer Id] = b.contact_id AND b.Rn =1 AND b.communication_type_id = 1
			LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactCommunications c ON a.[Vision Supplier Id] = c.contact_id AND c.Rn =1 AND c.communication_type_id = 1
			LEFT JOIN 
			(
				SELECT contact_id , is_validated_buyer FROM #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo WHERE is_buyer = 1
				UNION
				SELECT buyer_cont_id , dualaccount_is_validated_buyer FROM #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo WHERE is_buyer = 0 AND buyer_cont_id IS NOT NULL
			) d ON a.[Vision Buyer Id] = d.contact_id
			LEFT JOIN 
			(
				SELECT 
					b.contact_id  , MIN(a.status_date) [First RFQ Release Date] 
					, MAX(a.status_date) [Most Recent RFQ Release Date]
					, COUNT(DISTINCT a.rfq_id) as [Number of RFQs Released]
				FROM mp_rfq_release_history (NOLOCK) a
				JOIN mp_rfq					(NOLOCK) b ON a.rfq_id = b.rfq_id
				GROUP BY b.contact_id
			) e ON a.[Vision Buyer Id] = e.contact_id
			LEFT JOIN
			(
				SELECT 
					contact_id , MAX(activity_date) [Last Upgrade Request Date]
				FROM mp_track_user_activities (NOLOCK) WHERE activity_id IN (3,14)
				GROUP BY contact_id
			) f ON a.[Vision Supplier Id] = f.contact_id
			LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactCommunications g ON a.[Vision Buyer Id] = g.contact_id AND g.Rn =1 AND g.communication_type_id = 4
			LEFT JOIN #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactCommunications h ON a.[Vision Supplier Id] = h.contact_id AND h.Rn =1 AND h.communication_type_id = 4
		) b ON 
		a.[Contact Id] = b.[Contact Id] ---- this is unique identifier value of contact id 
	
		/*  */
		COMMIT
	END TRY
	BEGIN CATCH
		ROLLBACK
	END CATCH

	/*
	M2-4474
	Terms & Conditions acceptance field in HubSpot will be updated based on these three values "Accepted", "Declined", "No Response"
	*/
	BEGIN
	   /*  M2-4474 : Buyer and M - New T&C's acceptance modal - DB */
		UPDATE b
		SET 
			b.[Terms and Conditions Status]	 =
			CASE WHEN a.Is_Acceptances = 1 THEN 'Accepted'
				 WHEN a.Is_Acceptances = 0 THEN 'Declined'
				ELSE NULL
			END
			,b.[Terms and Conditions Contact Type] = 
			CASE WHEN a.Who_Accepted_Or_Declined = 1 THEN 'Buyer'
				 WHEN a.Who_Accepted_Or_Declined = 0 THEN 'Manufacturer'
				ELSE NULL
			END
			,b.[Terms and Conditions Action Date] = a.Modify_On
			,b.[IsSynced] = 0
			,b.[IsProcessed] = NULL
		FROM 
		(
			SELECT DISTINCT email ,  Is_Acceptances  , Who_Accepted_Or_Declined  , Modify_On 
			FROM mpNewTermAcceptances (NOLOCK) 
			WHERE  Is_Acceptances IS NOT NULL AND Modify_On BETWEEN DATEADD(MINUTE , -30 ,@SyncedDate) AND @SyncedDate
		) a
		JOIN DataSync_MarketplaceHubSpot.dbo.hubspotcontacts(nolock) b on a.email = b.email
	 /**/
	END

	/* update [Registration Date] for suplier and [Buyer Registration Date] for Buyer  */
	---Supplier
	UPDATE b
	SET 
		b.[Registration Date] = a.created_on
		,b.[IsSynced] = 0
		,b.[IsProcessed] = NULL
	FROM mp_contacts (NOLOCK) a
	JOIN AspNetUsers (NOLOCK) c ON a.user_id = c.id 		
	JOIN DataSync_MarketplaceHubSpot.dbo.hubspotcontacts(nolock) b on  c.Email = b.Email
			AND b.[Vision Supplier Id] = a.contact_id
	WHERE  b.[Registration Date] IS NULL AND YEAR(a.created_on) > 2020
	AND a.is_buyer = 0

	------Buyer
	UPDATE d
	SET 
		d.[Buyer Registration Date] = b.created_on
		,d.[IsSynced] = 0
		,d.[IsProcessed] = NULL
	FROM  aspnetusers (NOLOCK) a  
	JOIN mp_contacts (NOLOCK) b on a.id = b.user_id  
	JOIN mp_companies (NOLOCK) c on c.company_id = b.company_id   
	JOIN DataSync_MarketplaceHubSpot.dbo.hubspotcontacts(NOLOCK) d on d.email = a.email
			AND d.[Vision Buyer Id] = b.contact_id
	WHERE b.is_buyer = 1
	and d.[Buyer Registration Date] IS NULL
	/**/

	/* 	M2-5178 Hubspot - UpSync - Push the test account check box from Vision to Hubspot - DB */ 
	BEGIN
	PRINT GETUTCDATE()
	PRINT 'IS Test Company'	 
	--- This update code for hubspotcompanies -> [Is Test Company]
	;WITH CTE AS 
		(
			SELECT  
				 a.email, b.IsTestAccount 
				 , b.is_admin,b.contact_id 
				 , c.company_id 
				 , CASE WHEN tblIsTestAccountInfo.cnt > 0 THEN 1 ELSE ISNULL(tblIsTestAccountInfo.cnt,0) END IsTestAccountInfoUpdate
				 , tblIsTestAccountInfo.cnt 
				 , ROW_NUMBER() OVER (PARTITION BY c.company_id ORDER BY b.contact_id ) as rn 
			 FROM aspnetusers (NOLOCK) a  
			 join mp_contacts (NOLOCK) b on a.id = b.user_id  
			 join mp_companies (NOLOCK) c on c.company_id = b.company_id  
			 LEFT JOIN
			 ( 
			   SELECT  
					aspnetusers.email 
					, COUNT(1) AS cnt
			   FROM  mp_contacts (NOLOCK)
			   JOIN aspnetusers (NOLOCK) on aspnetusers.id = mp_contacts.user_id
			   WHERE mp_contacts.IsTestAccount = 1 
			   GROUP BY aspnetusers.email
			 ) AS tblIsTestAccountInfo on tblIsTestAccountInfo.email = a.email
			 WHERE   b.company_id IN 
				( 
						 
					SELECT DISTINCT [Vision Supplier Account Id]  FROM DataSync_MarketplaceHubSpot..hubspotcontacts(NOLOCK)  
					WHERE [Vision Supplier Account Id] IS NOT NULL 
					UNION
					SELECT DISTINCT [Vision Buyer Account Id]  FROM DataSync_MarketplaceHubSpot..hubspotcontacts(NOLOCK) 
					WHERE [Vision Buyer Account Id] IS NOT NULL 
					
				)
		)	
		UPDATE b   
		SET [Is Test Company] = a.IsTestAccountInfoUpdate
		,b.[IsSynced] = 0
		,b.[IsProcessed] = NULL
		----SELECT [Is Test Company] , a.IsTestAccountInfoUpdate, a.* 
		FROM CTE a
		JOIN DataSync_MarketplaceHubSpot..hubspotcompanies (NOLOCK) b on a.company_id = b.[vision account id]
		JOIN 
			(
				SELECT DISTINCT [Vision Supplier Account Id]  as company_id FROM DataSync_MarketplaceHubSpot..hubspotcontacts(NOLOCK)  
					WHERE [Vision Supplier Account Id] IS NOT NULL 
					UNION
					SELECT DISTINCT [Vision Buyer Account Id]  from DataSync_MarketplaceHubSpot..hubspotcontacts(NOLOCK) 
					WHERE [Vision Buyer Account Id] IS NOT NULL 
			) AS company_association_company_id on company_association_company_id.company_id = a.company_id
			WHERE   b.SyncType IS NULL 
			AND a.rn =1 
			AND [Is Test Company] != a.IsTestAccountInfoUpdate
		 
			 
     PRINT 'IS Test Contact'
	 ---- This update code for hubspotcontacts -> [Is Test Company]
	 ;WITH CTE AS 
		(
			SELECT  
				a.email
				, b.IsTestAccount 
				, b.is_admin
				, b.contact_id 
				, c.company_id 
				, CASE WHEN tblIsTestAccountInfo.cnt > 0 THEN 1 ELSE ISNULL(tblIsTestAccountInfo.cnt,0) END IsTestAccountInfoUpdate
				, tblIsTestAccountInfo.cnt 
				, ROW_NUMBER() OVER (PARTITION BY c.company_id ORDER BY b.contact_id ) as rn 
			 FROM aspnetusers (NOLOCK) a  
			 JOIN mp_contacts (NOLOCK) b on a.id = b.user_id  
			 JOIN mp_companies (NOLOCK) c on c.company_id = b.company_id  
			 LEFT JOIN
			 ( 
			   SELECT  
					aspnetusers.email 
					, COUNT(1) AS cnt
				FROM  mp_contacts (NOLOCK)
				JOIN  aspnetusers (NOLOCK) on aspnetusers.id = mp_contacts.user_id
				WHERE mp_contacts.IsTestAccount = 1 
				GROUP BY aspnetusers.email
			 ) AS tblIsTestAccountInfo on tblIsTestAccountInfo.email = a.email
			 WHERE   b.company_id IN 
				( 
					SELECT DISTINCT [Vision Supplier Account Id]  AS company_id FROM DataSync_MarketplaceHubSpot..hubspotcontacts(NOLOCK)  
					WHERE [Vision Supplier Account Id] IS NOT NULL 
					UNION
					SELECT DISTINCT [Vision Buyer Account Id]  FROM DataSync_MarketplaceHubSpot..hubspotcontacts(NOLOCK) 
					WHERE [Vision Buyer Account Id] IS NOT NULL 
					
				)
		)	
		UPDATE d   
		SET d.[Is Test Contact] = a.IsTestAccountInfoUpdate
		,d.[IsSynced] = 0
		,d.[IsProcessed] = NULL
		  ---SELECT [Is Test Company] , a.IsTestAccountInfoUpdate, a.* 
			FROM CTE a
			JOIN DataSync_MarketplaceHubSpot..hubspotcompanies (NOLOCK) b on a.company_id = b.[vision account id]
			JOIN DataSync_MarketplaceHubSpot..hubspotcontacts (NOLOCK) d on d.email = a.email
			JOIN 
			(
					SELECT DISTINCT [Vision Supplier Account Id]  AS company_id FROM DataSync_MarketplaceHubSpot..hubspotcontacts(NOLOCK)  
					WHERE [Vision Supplier Account Id] IS NOT NULL 
					UNION
					SELECT DISTINCT [Vision Buyer Account Id]  FROM DataSync_MarketplaceHubSpot..hubspotcontacts(NOLOCK) 
					WHERE [Vision Buyer Account Id] IS NOT NULL 
			) AS company_association_company_id on company_association_company_id.company_id = a.company_id
			WHERE     [Is Test Contact] != a.IsTestAccountInfoUpdate
			and b.SyncType IS NULL 
			
 
	 PRINT GETUTCDATE()

	END

	DROP TABLE IF EXISTS #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ListofCompanies
	DROP TABLE IF EXISTS #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ListofContacts
	DROP TABLE IF EXISTS #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesType
	DROP TABLE IF EXISTS #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesAddress
	DROP TABLE IF EXISTS #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesInfo
	DROP TABLE IF EXISTS #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesDiscipline0
	DROP TABLE IF EXISTS #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesDiscipline0
	DROP TABLE IF EXISTS #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesQuotingDiscipline0
	DROP TABLE IF EXISTS #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesQuotingDiscipline1
	DROP TABLE IF EXISTS #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompaniesIndustries
	DROP TABLE IF EXISTS #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo
	DROP TABLE IF EXISTS #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo1
	DROP TABLE IF EXISTS #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsInfo2
	DROP TABLE IF EXISTS #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactsAddress
	DROP TABLE IF EXISTS #tmp_MarketplaceToHubSpot_Sync_CompanyContact_ContactCommunications
	DROP TABLE IF EXISTS #tmp_MarketplaceToHubSpot_Sync_CompanyContact_CompanyCommunications


END
