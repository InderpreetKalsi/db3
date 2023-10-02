
/*
EXEC [proc_get_rpt_SupplierLeadStreamActivity] 
	
	@parStartDate	 = '2021-01-13'
	,@parEndDate	 = '2021-01-13'


*/

CREATE PROCEDURE [dbo].[proc_get_rpt_SupplierLeadStreamActivity]
(
	@parStartDate	DATE = '2021-01-01'
	,@parEndDate	DATE = '2021-01-01'
)
AS
BEGIN
	-- M2-3627 Report - Leadstream Report
	SET NOCOUNT ON

	DECLARE @StartDate	DATETIME	
	DECLARE @EndDate	DATETIME	

	DROP TABLE IF EXISTS #tmpRptSupplierLeadStreamActivity
	DROP TABLE IF EXISTS #tmpRptSupplierLeadStreamActivityCompanies
	DROP TABLE IF EXISTS #tmpRptSupplierLeadStreamActivityTestCompanies
	
	

	SELECT	
		company_id
		, name
		, b. territory_classification_name AS [Manufacturing Location]
		, ISNULL(c.PaidStatus ,'Basic') AS [Paid Status]
		, CASE WHEN a.ProfileStatus = 234 THEN 'Complete' ELSE 'In-Complete' END [Profile Status]
	INTO #tmpRptSupplierLeadStreamActivityCompanies
	FROM mp_companies (NOLOCK) a
	JOIN mp_mst_territory_classification (NOLOCK) b ON a.Manufacturing_location_id = b.territory_classification_id
	LEFT JOIN 
	(
		SELECT 
			VisionACCTID  AS CompanyId
			,(
				CASE	
					WHEN account_status in('active','gold') THEN 'Gold' --1
					WHEN account_status = 'silver'          THEN 'Silver'
					WHEN account_status = 'platinum'        THEN 'Platinum'
					ELSE 'Basic' 
				 END
			 ) AS PaidStatus
		FROM Zoho..Zoho_company_account (NOLOCK) WHERE synctype = 2 AND  account_type_id = 3
	) c ON a.company_id = c.CompanyId

	
	SELECT DISTINCT company_id INTO #tmpRptSupplierLeadStreamActivityTestCompanies FROM mp_contacts (NOLOCK) WHERE IsTestAccount = 1 

	SELECT 
		a.company_id		AS CompanyId
		,a.lead_source_id	AS SourceId
		,b.lead_source		AS Source
		,ISNULL(CONVERT(INT,a.lead_from_contact),0) AS LeadFrom
		,CONVERT(DATE,a.lead_date) AS LeadDate 
	INTO #tmpRptSupplierLeadStreamActivity
	FROM mp_lead (NOLOCK) a
	JOIN mp_mst_lead_source (NOLOCK) b ON a.lead_source_id = b.lead_source_id
	WHERE CONVERT(DATE,a.lead_date) BETWEEN @parStartDate AND @parEndDate
	
	SELECT *
	FROM 
	(
	  SELECT 
		CompanyId 
		, b.name AS Company
		, [Manufacturing Location]
		, [Paid Status]
		, [Profile Status]
		, LeadFrom  
		, Source
	  FROM #tmpRptSupplierLeadStreamActivity a
	  JOIN #tmpRptSupplierLeadStreamActivityCompanies b on a.CompanyId = b.company_id
	  WHERE NOT EXISTS (SELECT company_id  FROM #tmpRptSupplierLeadStreamActivityTestCompanies WHERE company_id = b.company_id)
	  
	) src
	PIVOT
	(
	  COUNT(LeadFrom)
	  FOR Source in ([Profile],[Message],[Internet],[Website],[Phone],[Email],[Special Invite],[Viewed Quote],[Read Message],[RFQ Awarded],[Community Profile],[Community Phone],[Community Email],[Community Direct RFQ],[Community Website],[In App Profile View])
	) piv
	ORDER BY Company
END
