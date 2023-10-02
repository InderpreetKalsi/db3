-- SELECT TOP 10 * FROM [vwRptActiveSuppliersWithAwardingDetails] ORDER BY [Company Id] , [Supplier Awarded]
CREATE VIEW  [dbo].[vwRptActiveSuppliersWithAwardingDetails]
AS

SELECT
	a.[Company Id]
	,a.Company 
	,a.CompanyURL 
	,a.[MFG Region]
	,a.[Paid Status]
	,CONVERT(VARCHAR(5),YEAR(h.award_date)) +'-'+ SUBSTRING(CONVERT(VARCHAR(5),CONVERT(VARCHAR(5),DATENAME(m,h.award_date))), 1,3)  AS [Supplier Awarded]

FROM 
(
	SELECT DISTINCT
		a.company_id AS [Company Id]
		,a.name AS [Company]
		,a.CompanyURL 
		,f.territory_classification_name AS [MFG Region]
		,ISNULL(g.paid_status,'Free')  AS [Paid Status]
	FROM mp_companies	a (NOLOCK)
	JOIN mp_contacts	b (NOLOCK) ON a.company_id = b.company_id AND  b.is_buyer= 0 AND a.company_id <> 0 and a.is_active = 1  and isnull(b.IsTestAccount,0)= 0
	JOIN mp_mst_territory_classification f (NOLOCK) ON a.manufacturing_location_id = f.territory_classification_id
	LEFT JOIN 
	(
		SELECT 
			VisionACCTID  AS company_id
			,(
				CASE	
					WHEN account_status in('active','gold') THEN 'Gold' --1
					WHEN account_status = 'silver'          THEN 'Silver'
					WHEN account_status = 'platinum'        THEN 'Platinum'
					ELSE 'Free' 
				 END
			 ) AS paid_status

		FROM ZOHO..Zoho_company_account (NOLOCK) WHERE synctype = 2 AND  account_type_id = 3
	) g ON a.company_id = g.company_id
) a
LEFT JOIN 
(
	SELECT DISTINCT c.company_id,  a.contact_id ,   CONVERT(DATE,b.awarded_date) award_date , a.rfq_id 
	FROM mp_rfq_quote_supplierquote a (NOLOCK)
	JOIN mp_rfq_quote_items b (NOLOCK) ON a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id
	JOIN mp_contacts c (NOLOCK) ON a.contact_id = c.contact_id  and isnull(c.IsTestAccount,0)= 0
	WHERE b.awarded_date IS NOT NULL AND b.is_awrded = 1
	
) h ON a.[Company Id] = h.company_id
WHERE a.[Company Id]  NOT IN
(
	SELECT ISNULL(company_id,0) FROM mp_contacts (NOLOCK)
	WHERE user_id IN 
	(
	SELECT id FROM aspnetusers WHERE 
	email LIKE '%info@battleandbrew.com%'
	OR email LIKE '%rhollis@mfg.com%'
	OR email LIKE '%billtestermfg@gmail.com%'
	OR email LIKE '%adam@attractful.com%'
	OR email LIKE '%testsu%'
	OR email LIKE '%testbu%'
	OR email LIKE '%pmahant@delaplex.in%'
	) 
	UNION
	SELECT company_id FROM mp_contacts (NOLOCK) WHERE isnull(IsTestAccount,0)= 1
)
