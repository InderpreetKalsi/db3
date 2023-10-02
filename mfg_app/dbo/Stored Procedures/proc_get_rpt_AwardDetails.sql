

-- EXEC proc_get_rpt_AwardDetails
CREATE PROCEDURE proc_get_rpt_AwardDetails
AS
BEGIN
	SET NOCOUNT ON
	   
	SELECT DISTINCT 
		c.company_id					AS BuyerCompanyId
		, c.name						AS BuyerCompany
		, b.first_name + b.last_name	AS Buyer
		, b.contact_id					AS BuyerId
		, a.rfq_id						AS [Rfq #]
		, a.rfq_name					AS Rfq
		, CONVERT(DATE,a.rfq_created_on)				AS [Rfq Created]
		, A.rfq_status_id
		, d.description					AS [Rfq Status]
		, [Rfq Location]  
		, f.part_name					AS [Part Name]
		, g.discipline_name				AS [Process]
		, CASE WHEN rfq_status_id IN (17,20) THEN NULL ELSE  i.awarded_qty END  [Awarded Qty]
		, CASE WHEN rfq_status_id IN (17,20) THEN NULL ELSE  i.per_unit_price END [Awarded Price]
		, CASE WHEN rfq_status_id IN (17,20) THEN NULL ELSE  i.AwardDate END [Award Date]
		, CASE WHEN rfq_status_id IN (17,20) THEN NULL ELSE  [Supplier Location] END   [Supplier Location] 
		, CASE WHEN rfq_status_id IN (17,20) THEN NULL ELSE  i.SupplierCompanyId END SupplierCompanyId
		, CASE WHEN rfq_status_id IN (17,20) THEN NULL ELSE  i.SupplierCompany END SupplierCompany
		, CASE WHEN rfq_status_id IN (17,20) THEN NULL ELSE  i.SupplierId END SupplierId
		, CASE WHEN rfq_status_id IN (17,20) THEN NULL ELSE  i.Supplier END Supplier
	FROM mp_rfq			(NOLOCK) a
	JOIN mp_contacts	(NOLOCK) b ON a.contact_id = b.contact_id AND b.IsTestAccount = 0
	JOIN mp_companies	(NOLOCK) c ON b.company_id = c.company_id
	JOIN mp_mst_rfq_buyerStatus (NOLOCK) d ON a.rfq_status_id = d.rfq_buyerstatus_id
	JOIN mp_rfq_parts	(NOLOCK) e ON a.rfq_id = e.rfq_id
	JOIN mp_parts		(NOLOCK) f ON e.part_id = f.part_id
	JOIN mp_mst_part_category	(NOLOCK) g ON e.part_category_id = g.part_category_id
	LEFT JOIN 
	(
		SELECT a.rfq_id , STRING_AGG(territory_classification_name,',') [Rfq Location]  
		FROM mp_rfq_preferences		(NOLOCK) a 
		JOIN mp_mst_territory_classification		(NOLOCK) b ON a.rfq_pref_manufacturing_location_id = b.territory_classification_id
		GROUP BY a.rfq_id
	) h ON a.rfq_id = h.rfq_id
	LEFT JOIN 
	(
		SELECT  DISTINCT 
			i.rfq_id
			, k.company_id					AS SupplierCompanyId
			, k.name						AS SupplierCompany
			, j.first_name + ' ' + j.last_name	AS Supplier
			, j.contact_id					AS SupplierId
			, l.rfq_part_id
			, l.rfq_part_quantity_id 
			, l.awarded_qty
			, l.per_unit_price
			, CONVERT(DATE,l.awarded_date) AS AwardDate
			, m.territory_classification_name AS [Supplier Location]
		FROM mp_rfq_quote_supplierquote (NOLOCK) i 
		JOIN mp_contacts	(NOLOCK) j ON i.contact_id = j.contact_id AND i.is_rfq_resubmitted = 0 AND i.is_quote_submitted = 1
		JOIN mp_companies	(NOLOCK) k ON j.company_id = k.company_id
		JOIN mp_rfq_quote_items (NOLOCK) l ON i.rfq_quote_SupplierQuote_id = l.rfq_quote_SupplierQuote_id AND l.is_awrded = 1
		JOIN mp_mst_territory_classification (NOLOCK) m ON k.Manufacturing_location_id = m.territory_classification_id
		--WHERE i.rfq_id = 1179980
	) i ON a.rfq_id = i.rfq_id AND e.rfq_part_id = i.rfq_part_id
	WHERE rfq_status_id IN (6,16,17,20,18) 
	--AND A.rfq_id = 1179980
	ORDER BY [RFQ #] DESC

	--select * from mp_rfq_parts where rfq_id = 1180124
	--select * FROM mp_rfq_quote_supplierquote where rfq_id = 1180124
	--select * FROM mp_rfq_quote_items WHERE rfq_quote_SupplierQuote_id IN (select rfq_quote_SupplierQuote_id FROM mp_rfq_quote_supplierquote where rfq_id = 1180124 AND is_rfq_resubmitted = 0)


END