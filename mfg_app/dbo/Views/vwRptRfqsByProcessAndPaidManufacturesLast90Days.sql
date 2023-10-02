
CREATE VIEW [dbo].[vwRptRfqsByProcessAndPaidManufacturesLast90Days]
	AS
	SELECT 
		CONVERT(VARCHAR(10),DATEADD(DAY,-90,CONVERT(DATE,GETUTCDATE())) ,101) +' - ' + CONVERT(VARCHAR(10),CONVERT(DATE,GETUTCDATE()),101) RfqReleasePeriod
		--, c.part_category_id 
		, c.discipline_name AS Process
		, COUNT(1) AS TotalRFQs
		, 
		(
			SELECT COUNT(DISTINCT e.company_id) 
			FROM mp_company_processes (NOLOCK) e
			JOIN mp_registered_supplier (NOLOCK) f ON e.company_id = f.company_id
			WHERE  e.part_category_id = c.part_category_id 
		) AS TotalManufactures
	FROM mp_rfq a (NOLOCK)
	JOIN mp_rfq_parts b (NOLOCK) ON a.rfq_id = b.rfq_id
	JOIN mp_mst_part_category c (NOLOCK) ON b.part_category_id = c.part_category_id
	JOIN mp_rfq_release_history d (NOLOCK) ON a.rfq_id = d.rfq_id
	JOIN mp_contacts			(NOLOCK) g ON a.contact_id = g.contact_id AND IsTestAccount = 0
	WHERE CONVERT(DATE,d.status_date) BETWEEN DATEADD(DAY,-90,CONVERT(DATE,GETUTCDATE())) AND CONVERT(DATE,GETUTCDATE())
	GROUP BY c.discipline_name , c.part_category_id
