CREATE VIEW [dbo].[vwRptRfqsByProcessAndPaidManufacturesLast90DaysLWithLocation]
	AS
	SELECT 
		CONVERT(VARCHAR(10),DATEADD(DAY,-90,CONVERT(DATE,GETUTCDATE())) ,101) +' - ' + CONVERT(VARCHAR(10),CONVERT(DATE,GETUTCDATE()),101) RfqReleasePeriod
		--, c.part_category_id 
		, c.discipline_name AS Process
		, f.territory_classification_name AS RfqLocation
		, COUNT(1) AS TotalRFQs
		, 
		(
			SELECT COUNT(DISTINCT g.company_id) 
			FROM mp_company_processes (NOLOCK) g
			JOIN mp_registered_supplier (NOLOCK) h ON g.company_id = h.company_id
			JOIN mp_companies (NOLOCK) i ON h.company_id = i.company_id AND f.territory_classification_id = i.manufacturing_location_id
			WHERE  g.part_category_id = c.part_category_id 
		) AS TotalManufactures
	FROM mp_rfq a (NOLOCK)
	JOIN mp_rfq_parts b (NOLOCK) ON a.rfq_id = b.rfq_id
	JOIN mp_mst_part_category c (NOLOCK) ON b.part_category_id = c.part_category_id
	JOIN mp_rfq_release_history d (NOLOCK) ON a.rfq_id = d.rfq_id
	JOIN mp_rfq_preferences e (NOLOCK) ON a.rfq_id = e.rfq_id
	JOIN mp_mst_territory_classification f (NOLOCK) ON e.rfq_pref_manufacturing_location_id = f.territory_classification_id
	JOIN mp_contacts						(NOLOCK) g ON a.contact_id = g.contact_id AND IsTestAccount = 0
	WHERE CONVERT(DATE,d.status_date) BETWEEN DATEADD(DAY,-90,CONVERT(DATE,GETUTCDATE())) AND CONVERT(DATE,GETUTCDATE())
	GROUP BY c.discipline_name , c.part_category_id , f.territory_classification_name ,f.territory_classification_id
	--ORDER BY 2
