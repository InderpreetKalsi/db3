-- SELECT * FROM vwRptQuotesBySupplier WHERE [Account Type] = 'Platinum' ORDER BY  Company ,  [User] ,[Discipline Level 1] ,[Discipline Level 2]
CREATE VIEW [dbo].[vwRptQuotesBySupplier] 
AS

WITH Supplier AS
(
	SELECT 
		a.company_id AS CompanyId
		,a.contact_id AS ContactId
		,b.name AS Company
		,a.first_name +' '+a.last_name AS [User]
		,CASE WHEN j.account_type = 85 THEN 'Gold' ELSE 'Platinum' END	AS [Account Type]
		,f.discipline_name	AS [Discipline Level 1] 
		,e.discipline_name	AS [Discipline Level 2]
		,e.part_category_id AS DisciplineId
		,b.Manufacturing_location_id [ManufacturingLocationId]
	FROM mp_contacts	a	(NOLOCK)
	JOIN mp_companies	b	(NOLOCK) ON a.company_id = b.company_id AND a.is_buyer = 0 AND a.company_id <> 0  and isnull(a.IsTestAccount,0)= 0
	JOIN 
	(
		SELECT company_id,part_category_id FROM mp_company_processes (NOLOCK)
		UNION
		SELECT company_id,part_category_id FROM mp_gateway_subscription_company_processes (NOLOCK)
	) c	 ON b.company_id = c.company_id
	JOIN mp_active_capabilities		d	(NOLOCK) ON c.part_category_id = d.part_category_id
	JOIN mp_mst_part_category		e	(NOLOCK) ON c.part_category_id = e.part_category_id
	JOIN mp_mst_part_category		f	(NOLOCK) ON e.parent_part_category_id = f.part_category_id
	JOIN mp_registered_supplier		j	(NOLOCK) ON b.company_id = j.company_id AND j.account_type in (85,86)
	JOIN 
	(
		SELECT DISTINCT contact_id 
		FROM mp_rfq_quote_supplierquote	(NOLOCK)
		WHERE is_quote_submitted = 1 AND is_rfq_resubmitted = 0 
	) g	 ON a.contact_id = g.contact_id  

) , 
 SupplierQuotes AS
(
	SELECT
		a.contact_id  AS ContactId
		,CONVERT(DATE,g.quote_date) [Quote Date]
		,i.part_category_id AS DisciplineId
	FROM mp_contacts	a	(NOLOCK)
	JOIN mp_rfq_quote_supplierquote	g	(NOLOCK) ON a.contact_id = g.contact_id and g.is_quote_submitted = 1 AND g.is_rfq_resubmitted = 0  and isnull(a.IsTestAccount,0)= 0
	JOIN mp_rfq_quote_items			h	(NOLOCK) ON g.rfq_quote_supplierquote_id = h.rfq_quote_supplierquote_id
	JOIN mp_rfq_parts				i	(NOLOCK) ON	h.rfq_part_id = i.rfq_part_id 
	JOIN mp_registered_supplier		j	(NOLOCK) ON a.company_id = j.company_id AND j.account_type in (85,86)
) 
SELECT 
	a.Company
	,a.[User]
	,c.territory_classification_name [ManufacturingLocation]
	,a.[Account Type]
	,a.[Discipline Level 1]
	,a.[Discipline Level 2]
	,b.[Quote Date]
	,SUM(CASE WHEN b.DisciplineId IS NULL THEN 0 ELSE 1 END)  [Quotes Submitted]
FROM Supplier a
LEFT JOIN SupplierQuotes b  ON a.ContactId = b.ContactId AND a.DisciplineId = b.DisciplineId
JOIN mp_mst_territory_classification (NOLOCK) c ON a.[ManufacturingLocationId] = c.territory_classification_id
GROUP BY 
	a.Company
	,a.[User]
	,c.territory_classification_name
	,a.[Account Type]
	,a.[Discipline Level 1]
	,a.[Discipline Level 2]
	,b.[Quote Date]
