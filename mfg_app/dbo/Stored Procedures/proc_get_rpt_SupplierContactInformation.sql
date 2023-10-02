
-- EXEC proc_get_rpt_SupplierContactInformation
CREATE PROCEDURE [dbo].[proc_get_rpt_SupplierContactInformation]
AS
BEGIN
	
	-- M2-3714 Report - Supplier Contact Information Report

	SET NOCOUNT ON

	DROP TABLE IF EXISTS #proc_get_rpt_SupplierContactInformation_CompanyData
	DROP TABLE IF EXISTS #proc_get_rpt_SupplierContactInformation_ContactData
	DROP TABLE IF EXISTS #proc_get_rpt_SupplierContactInformation_AddressData
	DROP TABLE IF EXISTS #proc_get_rpt_SupplierContactInformation_CommunicationData
	DROP TABLE IF EXISTS #proc_get_rpt_SupplierContactInformation_CapabilitiesData
	DROP TABLE IF EXISTS #proc_get_rpt_SupplierContactInformation_SolrData
	DROP TABLE IF EXISTS #proc_get_rpt_SupplierContactInformation_ExistingContract
	

	SELECT company_id , 'Yes'  AS [contract] INTO #proc_get_rpt_SupplierContactInformation_ExistingContract
	FROM zoho..zoho_sink_down_logs (NOLOCK) WHERE table_name = 'mp_registered_supplier' AND oldfieldvalue IN (85,84)
	UNION
	SELECT company_id , 'Yes'  AS [contract]  FROM zoho..zoho_sink_down_logs (NOLOCK) WHERE table_name = 'mp_registered_supplier' AND newfieldvalue IN (85,84)


	SELECT 
		a.company_id AS CompanyId
		,a.contact_id	AS ContactId				
		, first_name +' '+ last_name AS Contact
		, b.email AS ContactEmail
		, ROW_NUMBER() OVER (PARTITION BY a.company_id ORDER BY a.company_id,a.contact_id) Rn
		, a.address_id AS AddressID
		, CASE WHEN a.IsTestAccount = 0 THEN 'No' ELSE 'Yes' END IsTestAccount
	INTO #proc_get_rpt_SupplierContactInformation_ContactData
	FROM mp_contacts (NOLOCK) a
	JOIN aspnetusers (NOLOCK) b ON a.[user_id] = b.id
	WHERE a.is_buyer = 0 AND a.is_admin = 1 AND a.company_id <> 0
	
	DELETE FROM #proc_get_rpt_SupplierContactInformation_ContactData WHERE Rn > 1

	SELECT  
		a.address_id AS AddressId
		, a.address1 AS Address1
		, a.address2 AS Address2
		, a.address4 AS City
		, a.address3 AS Zipcode
		, b.region_name AS [State]
		, c.country_name AS Country
	INTO #proc_get_rpt_SupplierContactInformation_AddressData
	FROM mp_addresses (NOLOCK) a 
	LEFT JOIN mp_mst_region (NOLOCK) b ON a.region_id = b.region_id
	LEFT JOIN mp_mst_country (NOLOCK) c ON a.country_id = c.country_id
	WHERE EXISTS (SELECT AddressID FROM #proc_get_rpt_SupplierContactInformation_ContactData WHERE a.address_id = AddressID)

	SELECT 
		a.company_id AS CompanyId
		,a.name AS Company
		,a.description AS CompanyDescription
		, CASE WHEN k.PaidStatus IS NULL THEN '01 Basic' WHEN k.PaidStatus ='' THEN '01 Basic' ELSE  k.PaidStatus  END 		as PaidStatus
		, CASE WHEN d.territory_classification_name IS NULL THEN NULL WHEN d.territory_classification_name ='' THEN NULL ELSE d.territory_classification_name END as ManufacturingLocation
		, FORMAT (a.created_date, 'MM/dd/yyyy ')  CompanyRegistrationDate 
	INTO #proc_get_rpt_SupplierContactInformation_CompanyData
	FROM mp_companies a (NOLOCK)
	LEFT JOIN mp_mst_territory_classification	(NOLOCK) d ON a.manufacturing_location_id = d.territory_classification_id
	LEFT JOIN 
	(
		SELECT 
			VisionACCTID  AS CompanyId
			,(
				CASE	
					WHEN account_status in('active','gold') THEN '03 Gold' --1
					WHEN account_status = 'silver'          THEN '02 Silver'
					WHEN account_status = 'platinum'        THEN '04 Platinum'
					ELSE '01 Basic' 
				 END
			 ) AS PaidStatus
		FROM Zoho..Zoho_company_account (NOLOCK) WHERE synctype = 2 AND  account_type_id = 3
	) k ON a.company_id = k.CompanyId
	WHERE EXISTS (SELECT CompanyId FROM #proc_get_rpt_SupplierContactInformation_ContactData WHERE a.company_id = CompanyId)

	SELECT 
		a.contact_id AS ContactId
		, a.communication_value AS PhoneNo
	INTO #proc_get_rpt_SupplierContactInformation_CommunicationData
	FROM mp_communication_details (NOLOCK) a 
	WHERE communication_type_id = 1 
	AND EXISTS (SELECT CompanyId FROM #proc_get_rpt_SupplierContactInformation_ContactData WHERE a.contact_id = ContactId)


	SELECT CompanyId , STRING_AGG(Capabilities,';') Capabilities
	INTO #proc_get_rpt_SupplierContactInformation_CapabilitiesData
	FROM
	(	
		SELECT  a.company_id CompanyId, b.discipline_name AS Capabilities
		FROM mp_company_processes (NOLOCK) a
		JOIN mp_mst_part_category (NOLOCK) b ON a.part_category_id = b.part_category_id AND b.status_id = 2
		AND EXISTS (SELECT CompanyId FROM #proc_get_rpt_SupplierContactInformation_ContactData WHERE a.company_id = CompanyId)
		UNION
		SELECT  a.company_id CompanyId, b.discipline_name AS Capabilities
		FROM mp_gateway_subscription_company_processes (NOLOCK) a
		JOIN mp_mst_part_category (NOLOCK) b ON a.part_category_id = b.part_category_id AND b.status_id = 2
		AND EXISTS (SELECT CompanyId FROM #proc_get_rpt_SupplierContactInformation_ContactData WHERE a.company_id = CompanyId)
	) a 
	GROUP BY CompanyId

	--SELECT * FROM #proc_get_rpt_SupplierContactInformation_ContactData
	--SELECT * FROM #proc_get_rpt_SupplierContactInformation_AddressData
	--SELECT * FROM #proc_get_rpt_SupplierContactInformation_CompanyData
	--SELECT * FROM #proc_get_rpt_SupplierContactInformation_CommunicationData
	--SELECT * FROM #proc_get_rpt_SupplierContactInformation_CapabilitiesData

	SELECT  
		'Solr' AS Source
		, name	AS [Supplier Name]
		, Id	AS [Supplier VID] 
		, FORMAT (CONVERT(DATE,creation_date), 'MM/dd/yyyy ')  CompanyRegistrationDate 
		, 'No'  AS IsTestAccount
		, '01 Basic'	AS PaidStatus
		, 'No' AS [Existing Contract]
		, ''	AS ManufacturingLocation
		, description_3 AS [Supplier Description]
		, street_address AS [Address1]
		, '' AS Address2
		, city AS City
		, zip_code AS Zipcode
		, region AS State
		, country AS Country
		, email AS [Primary Supplier Email]
		, phone AS [Primary Supplier Phone]
		, primary_contact_name AS [Primary Supplier Full Name]
		, '' AS [Primary Supplier VID]
		, discipline_name_3 AS [Supplier Capabilities]
	INTO #proc_get_rpt_SupplierContactInformation_SolrData
	FROM mpSolrData (NOLOCK) 
	WHERE is_exists_in_mfg = 0  

	CREATE UNIQUE NONCLUSTERED INDEX IX_rpt_SupplierContactInformation_SolrData ON  #proc_get_rpt_SupplierContactInformation_SolrData ( [Supplier VID] );
	CREATE UNIQUE NONCLUSTERED INDEX IX_rpt_SupplierContactInformation_CompanyDat ON  #proc_get_rpt_SupplierContactInformation_CompanyData ( [CompanyId]);

	SELECT  
		'Vision' AS Source
		, a.Company AS [Supplier Name]
		, a.CompanyId AS [Supplier VID] 
		, a.CompanyRegistrationDate AS [Supplier Registered]
		, b.IsTestAccount
		, a.PaidStatus
		, (CASE WHEN a.PaidStatus = '01 Basic' THEN ISNULL(f.[contract],'No') ELSE '-' END) AS [Existing Contract]
		, a.ManufacturingLocation
		, a.CompanyDescription AS [Supplier Description]
		, c.Address1 
		, c.Address2
		, c.City
		, c.Zipcode
		, c.State
		, c.Country
		, b.ContactEmail AS [Primary Supplier Email]
		, d.PhoneNo AS [Primary Supplier Phone]
		, b.Contact AS [Primary Supplier Full Name]
		, b.ContactId AS [Primary Supplier VID]
		, e.Capabilities AS [Supplier Capabilities]
	FROM #proc_get_rpt_SupplierContactInformation_CompanyData a
	JOIN #proc_get_rpt_SupplierContactInformation_ContactData b ON a.CompanyId = b.CompanyId
	LEFT JOIN #proc_get_rpt_SupplierContactInformation_AddressData c ON b.AddressID = c.AddressId
	LEFT JOIN #proc_get_rpt_SupplierContactInformation_CommunicationData d ON b.ContactId = d.ContactId
	LEFT JOIN #proc_get_rpt_SupplierContactInformation_CapabilitiesData e  ON a.CompanyId = e.CompanyId
	LEFT JOIN #proc_get_rpt_SupplierContactInformation_ExistingContract f ON a.CompanyId = f.company_id
	UNION
	SELECT * FROM #proc_get_rpt_SupplierContactInformation_SolrData
	ORDER BY [Supplier VID] 

END