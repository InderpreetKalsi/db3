

-- SELECT * FROM vwRptRFQsByMonth
CREATE VIEW [dbo].[vwRptRFQsByMonth]
AS
	SELECT 
		CONVERT(DATE, d.status_date) AS [RFQ Release Date]
		,f.territory_classification_name AS [RFQ Location]
		,c.discipline_name AS Capabilities
		,COUNT(DISTINCT a.contact_id) AS [Unique Buyer Count]
		,COUNT(DISTINCT a.rfq_id) AS [Unique RFQ Count]
	FROM mp_rfq								(NOLOCK) a
	JOIN mp_rfq_parts						(NOLOCK) b ON a.rfq_id = b.rfq_id
	JOIN mp_mst_part_category				(NOLOCK) c ON b.part_category_id = c.part_category_id
	JOIN mp_rfq_release_history				(NOLOCK) d ON a.rfq_id = d.rfq_id
	JOIN mp_rfq_preferences					(NOLOCK) e ON a.rfq_id = e.rfq_id
	JOIN mp_mst_territory_classification	(NOLOCK) f ON e.rfq_pref_manufacturing_location_id = f.territory_classification_id
	JOIN mp_contacts						(NOLOCK) g ON a.contact_id = g.contact_id AND IsTestAccount = 0
	GROUP BY 
		CONVERT(DATE, d.status_date)
		, f.territory_classification_name
		, c.discipline_name
