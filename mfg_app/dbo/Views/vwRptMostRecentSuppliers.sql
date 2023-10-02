-- SELECT * FROM [vwRptMostRecentSuppliers]  WHERE [DaysCreated] < =90 ORDER BY [Company]
CREATE VIEW  [dbo].[vwRptMostRecentSuppliers]
AS

SELECT 
	a.name AS [Company]
	,FORMAT(a.created_date, 'd', 'en-US' )  AS [Company Created]
	,CONVERT(INT,DATEDIFF(DAY,a.created_date, GETUTCDATE()))  AS [DaysCreated]
	,(CASE WHEN f.account_status IS NULL THEN 'Free' WHEN  f.account_status  = 'Active' THEN 'Gold' ELSE f.account_status END) AS AccountType
	,g.territory_classification_name AS [MFG Location]
	,e.discipline_name [Discipline 0]
	,d.discipline_name [Discipline 1]
	,'' [Discipline 2]
FROM mp_companies	a (NOLOCK)
JOIN mp_contacts	b (NOLOCK) ON a.company_id = b.company_id AND  b.is_buyer= 0 AND a.company_id <> 0  and isnull(b.IsTestAccount,0)= 0
JOIN 
(
	SELECT DISTINCT company_id , part_category_id FROM mp_company_processes (NOLOCK)
	UNION
	SELECT DISTINCT company_id , part_category_id  FROM mp_gateway_subscription_company_processes (NOLOCK)
)	c  ON a.company_id = c.company_id
JOIN mp_mst_part_category d (NOLOCK) ON c.part_category_id = d.part_category_id
JOIN mp_mst_part_category e (NOLOCK) ON d.parent_part_category_id = e.part_category_id
JOIN zoho..zoho_company_account f (NOLOCK) ON a.company_id = f.visionacctid AND f.synctype = 2
JOIN mp_mst_territory_classification g (NOLOCK) ON a.manufacturing_location_id  = g.territory_classification_id
WHERE c.part_category_id IN (SELECT part_category_id FROM mp_active_capabilities)
