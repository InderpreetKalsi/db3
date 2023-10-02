
-- SELECT * FROM [vwRptSuppliersRFQsAndQuotesByProcesses] ORDER BY 	[Discipline Level 1] ,[Discipline Level 2] ,Type
CREATE VIEW [dbo].[vwRptSuppliersRFQsAndQuotesByProcesses] 
AS
WITH Processes AS
(
	SELECT 
			b.part_category_id
		,	c.discipline_name	AS	[Discipline Level 1]
		,	b.discipline_name	AS	[Discipline Level 2]
		
	FROM mp_active_capabilities		a	(NOLOCK)
	JOIN mp_mst_part_category		b	(NOLOCK) ON a.part_category_id = b.part_category_id
	JOIN mp_mst_part_category		c	(NOLOCK) ON b.parent_part_category_id = c.part_category_id AND c.part_category_id NOT IN (0,1)
) 
,ProcessesWithActiveSupplier AS 
(
	SELECT DISTINCT '4. Active Supplier' Type, d.company_id id, e.part_category_id , 1 DaysCreated  , f.manufacturing_location_id AS LocationId
	FROM mp_registered_supplier	d (NOLOCK)
	JOIN
	(
		SELECT company_id,part_category_id FROM mp_company_processes (NOLOCK)
		UNION
		SELECT company_id,part_category_id FROM mp_gateway_subscription_company_processes (NOLOCK)
	) e	 ON d.company_id = e.company_id 
	JOIN mp_companies (NOLOCK) f ON d.company_id = f.company_id
	--JOIN mp_mst_territory_classification (NOLOCK) g ON f.manufacturing_location_id = g.territory_classification_id
) 
,ProcessesWithBasicSupplier AS 
(
	SELECT DISTINCT '3. Basic Supplier' Type, f.company_id id, g.part_category_id , DATEDIFF(DAY,f.created_date,GETUTCDATE() ) DaysCreated  , f.manufacturing_location_id AS LocationId
	FROM mp_companies f (NOLOCK)
	JOIN
	(
	SELECT company_id,part_category_id FROM mp_company_processes (NOLOCK)
	UNION
	SELECT company_id,part_category_id FROM mp_gateway_subscription_company_processes (NOLOCK)
	) g	 ON f.company_id = g.company_id 
	--JOIN mp_mst_territory_classification (NOLOCK) h ON f.manufacturing_location_id = h.territory_classification_id
	WHERE NOT EXISTS (SELECT * FROM mp_registered_supplier (NOLOCK) WHERE f.company_id = company_id)  AND DATEDIFF(DAY,f.created_date,GETUTCDATE() ) <= 365
) 
,ProcessesWithRFQ AS 
(
	SELECT DISTINCT '2. RFQ' Type, h.rfq_id id, j.part_category_id , DATEDIFF(DAY,h.rfq_created_on,GETUTCDATE() ) DaysCreated , f.rfq_pref_manufacturing_location_id AS LocationId
	FROM mp_rfq h (NOLOCK)
	JOIN mp_rfq_release_history i (NOLOCK) ON h.rfq_id = i.rfq_id
	JOIN mp_rfq_parts j ON h.rfq_id = j.rfq_id   AND DATEDIFF(DAY,h.rfq_created_on,GETUTCDATE() )<= 365
	JOIN mp_rfq_preferences (NOLOCK) f ON h.rfq_id = f.rfq_id
	JOIN mp_contacts	b (NOLOCK) ON h.contact_id = b.contact_id  and IsTestAccount= 0
	--JOIN mp_mst_territory_classification (NOLOCK) g ON f.rfq_pref_manufacturing_location_id = g.territory_classification_id
) 
,ProcessesWithQuotes AS 
(
	SELECT DISTINCT '1. Quotes' Type, h.rfq_quote_supplierquote_id id, i.part_category_id , DATEDIFF(DAY,g.quote_date,GETUTCDATE() ) DaysCreated ,k.manufacturing_location_id AS LocationId
	FROM mp_rfq_quote_supplierquote	g	(NOLOCK) 
	JOIN mp_rfq_quote_items			h	(NOLOCK) ON g.rfq_quote_supplierquote_id = h.rfq_quote_supplierquote_id  AND g.is_quote_submitted = 1 AND g.is_rfq_resubmitted = 0
	JOIN mp_rfq_parts				i	(NOLOCK) ON	h.rfq_part_id = i.rfq_part_id  AND DATEDIFF(DAY,g.quote_date,GETUTCDATE() )<= 365
	JOIN mp_contacts (NOLOCK)  j ON g.contact_id = j.contact_id   and j.IsTestAccount= 0
	JOIN mp_companies (NOLOCK) k ON j.company_id = k.company_id
) 
SELECT 
	a.[Discipline Level 1] 
	,a.[Discipline Level 2]
	,b.Type
	,b.id AS Id
	,b.DaysCreated
	,c.territory_classification_name [MFG Location]
FROM Processes a
LEFT JOIN 
(
	SELECT * FROM ProcessesWithActiveSupplier
	UNION
	SELECT * FROM ProcessesWithBasicSupplier
	UNION
	SELECT * FROM ProcessesWithRFQ
	UNION
	SELECT * FROM ProcessesWithQuotes

)	b ON a.part_category_id = b.part_category_id
LEFT JOIN mp_mst_territory_classification (NOLOCK) c ON b.LocationId = c.territory_classification_id
