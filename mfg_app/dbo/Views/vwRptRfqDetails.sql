

--SELECT * FROM MP_RFQ WHERE RFQ_ID = 1164981
-- SELECT top 100 * FROM vwRptRfqDetails ORDER BY [Rfq Id] DESC
CREATE VIEW [dbo].[vwRptRfqDetails]
AS

SELECT DISTINCT
	c.name			AS [Buyer Company]
	,e.part_name	AS [Part Name]
	,a.rfq_id		AS [Rfq Id]
	,a.rfq_name		AS [Rfq #]
	,FORMAT(a.rfq_created_on, 'd', 'en-US' )	AS [Rfq Created]
	,l.description	AS [Rfq Status]
	,g.discipline_name	AS	[Process]
	,f.discipline_name	AS	[Sub-Process]
	,h.material_name_en	AS	[Material]
	,i.part_qty		AS [Qty]
	,k.Region AS	[Region]
	,(CASE WHEN m.is_awrded = 1 THEN 'Yes' ELSE 'No' END) AS [Awarded?]
	,FORMAT(m.awarded_date, 'd', 'en-US' ) AS [Awarded Date]
	,p.name			AS [Supplier]
	,m.QtyTotal		AS [Price]
	
FROM	mp_rfq			a	(NOLOCK)
JOIN	mp_rfq_release_history a1	(NOLOCK) on a.rfq_id =  a1.rfq_id AND a.rfq_status_id IN (3,5,6) AND a.contact_id <> 1336138
JOIN	mp_contacts		b	(NOLOCK) ON a.contact_id = b.contact_id   and isnull(b.IsTestAccount,0)= 0 --and  a.rfq_id = 1163701
JOIN	mp_companies	c	(NOLOCK) ON b.company_id = c.company_id
LEFT JOIN	mp_rfq_parts d	(NOLOCK) ON a.rfq_id = d.rfq_id
LEFT JOIN	mp_parts	e	(NOLOCK) ON d.part_id = e.part_id
LEFT JOIN	mp_mst_part_category	f	(NOLOCK) ON d.part_category_id = f.part_category_id
LEFT JOIN	mp_mst_part_category	g	(NOLOCK) ON f.parent_part_category_id = g.part_category_id
LEFT JOIN	mp_mst_materials		h	(nolock) ON d.material_id = h.material_id	
LEFT JOIN	mp_rfq_part_quantity	i	(NOLOCK) ON	d.rfq_part_id = i.rfq_part_id AND i.is_deleted = 0
--LEFT JOIN	mp_rfq_preferences		j	(NOLOCK) ON a.rfq_id = j.rfq_id
--LEFT JOIN	mp_mst_territory_classification		k	(NOLOCK) ON j.rfq_pref_manufacturing_location_id = k.territory_classification_id
LEFT JOIN 
(
	SELECT DISTINCT j.rfq_id ,  STUFF  
	(  
		(  
			SELECT DISTINCT ', '+ CAST( k1.territory_classification_name AS VARCHAR(MAX))  
			FROM mp_rfq_preferences	j1 (NOLOCK) 
			JOIN	mp_mst_territory_classification		k1	(NOLOCK) ON j1.rfq_pref_manufacturing_location_id = k1.territory_classification_id
			WHERE j.rfq_id  = j1.rfq_id 
			FOR XMl PATH('')  
		),1,1,''  
	) Region
	FROM mp_rfq_preferences	j (NOLOCK) 
	JOIN mp_mst_territory_classification		k	(NOLOCK) ON j.rfq_pref_manufacturing_location_id = k.territory_classification_id 
) k ON a.rfq_id = k.rfq_id 
LEFT JOIN	mp_mst_rfq_buyerStatus	l	(NOLOCK) ON	a.rfq_status_id = l.rfq_buyerstatus_id
LEFT JOIN	
(
	SELECT 
		m.rfq_id 
		,m.contact_id 
		,n.rfq_part_id
		,n.rfq_part_quantity_id
		,n.is_awrded 
		,n.awarded_date
		,CONVERT
		(	DECIMAL(18,4),
			SUM
			(
				(
					(COALESCE(per_unit_price,0) * COALESCE(awarded_qty,0)) 
					+ COALESCE(tooling_amount,0)  
					+  COALESCE(miscellaneous_amount,0)  
					+  COALESCE(shipping_amount,0)
				)
			)
		) AS QtyTotal
	FROM
	mp_rfq_quote_SupplierQuote	m	(NOLOCK) 
	JOIN mp_rfq_quote_items		n	(NOLOCK) ON m.rfq_quote_SupplierQuote_id = n.rfq_quote_SupplierQuote_id 
		AND m.is_rfq_resubmitted = 0
		AND m.is_quote_submitted = 1
		AND n.is_awrded = 1
	GROUP BY 
		m.rfq_id 
		,m.contact_id 
		,n.rfq_part_id
		,n.rfq_part_quantity_id
		,n.awarded_date
		,n.is_awrded 
) m	ON a.rfq_id  = m.rfq_id 
	AND d.rfq_part_id = m.rfq_part_id 
	AND i.rfq_part_quantity_id = m.rfq_part_quantity_id

LEFT JOIN	mp_contacts				o	(NOLOCK) ON m.contact_id = o.contact_id 
LEFT JOIN	mp_companies			p	(NOLOCK) ON o.company_id = p.company_id
