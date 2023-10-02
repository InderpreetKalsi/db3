
-- SELECT * , CASE WHEN  [TYPE] = '5. Sum of RFQ award price' AND RN = 1 THEN AwaredPrice ELSE 0 END [RFQ Awared Price]  FROM vwRptByMonthRFQMetrics  WHERE RFQId IN (1101464,1101469) ORDER BY [Year RFQ Date] ,[Month RFQ Date] ,RFQId
CREATE VIEW [dbo].[vwRptByMonthRFQMetrics]
AS

SELECT
	ROW_NUMBER() OVER (PARTITION BY RFQId, Type ORDER BY RFQId) RN
	,a.*
	,SUBSTRING(CONVERT(VARCHAR(5),CONVERT(VARCHAR(5),DATENAME(m,a.[RFQ Date]))), 1,3) +'-'+ SUBSTRING(CONVERT(VARCHAR(5),YEAR(a.[RFQ Date])),3,2)    AS [RFQ Released On]
	,c.territory_classification_name AS [RFQ Location]
	,f.discipline_name AS [RFQ Parent Capability]
	,e.discipline_name AS [RFQ Child Capability]
FROM 
(
		SELECT DISTINCT
			a.rfq_id AS RFQId
			,'1. No of RFQ released' AS Type
			,CONVERT(DATE,b.ReleaseDate) [RFQ Date]
			,YEAR(b.ReleaseDate) [Year RFQ Date]
			,MONTH(b.ReleaseDate) [Month RFQ Date]
			,0 AwaredPrice
		FROM mp_rfq		a	(NOLOCK)
		JOIN 
		(
			SELECT rfq_id , MAX(status_date)  ReleaseDate
			FROM mp_rfq_release_history	(NOLOCK)
			GROUP BY  rfq_id 
		) b ON a.rfq_id = b.rfq_id
		WHERE YEAR(b.ReleaseDate) >= 2019
		UNION
		SELECT 
			a.rfq_id AS RFQId
			,'2. No of RFQs with quotes' AS Type
			,CONVERT(DATE,b.ReleaseDate) [RFQ Date]
			,YEAR(b.ReleaseDate) [Year RFQ Date]
			,MONTH(b.ReleaseDate) [Month RFQ Date]
			,0 AwaredPrice
		FROM mp_rfq_quote_supplierquote (NOLOCK) a
		JOIN 
		(
			SELECT rfq_id , MAX(status_date)  ReleaseDate
			FROM mp_rfq_release_history	(NOLOCK)
			GROUP BY  rfq_id 
		) b ON a.rfq_id = b.rfq_id
		WHERE a.is_rfq_resubmitted = 0 AND a.is_quote_submitted = 1
		AND YEAR(b.ReleaseDate) >= 2019
		UNION
		SELECT DISTINCT
			a.rfq_id AS RFQId
			,'3. No of RFQs without quotes' AS Type
			,CONVERT(DATE,b.ReleaseDate) [RFQ Date]
			,YEAR(b.ReleaseDate) [Year RFQ Date]
			,MONTH(b.ReleaseDate) [Month RFQ Date]
			,0 AwaredPrice
		FROM mp_rfq		a	(NOLOCK)
		JOIN 
		(
			SELECT rfq_id , MAX(status_date)  ReleaseDate
			FROM mp_rfq_release_history	(NOLOCK)
			GROUP BY  rfq_id 
		) b ON a.rfq_id = b.rfq_id
		LEFT JOIN mp_rfq_quote_supplierquote c (NOLOCK) on a.rfq_id = c.rfq_id
		WHERE YEAR(b.ReleaseDate) >= 2019 AND c.rfq_id IS NULL
		UNION
		SELECT DISTINCT
			a.rfq_id AS RFQId
			,'4. No of RFQs Awarded' AS Type
			,CONVERT(DATE,b.ReleaseDate) [RFQ Date]
			,YEAR(b.ReleaseDate) [Year RFQ Date]
			,MONTH(b.ReleaseDate) [Month RFQ Date]
			,0 AwaredPrice
		FROM mp_rfq		a	(NOLOCK)
		JOIN 
		(
			SELECT rfq_id , MAX(status_date)  ReleaseDate
			FROM mp_rfq_release_history	(NOLOCK)
			GROUP BY  rfq_id 
		) b ON a.rfq_id = b.rfq_id
		JOIN mp_rfq_quote_supplierquote c (NOLOCK) on a.rfq_id = c.rfq_id
		JOIN mp_rfq_quote_items d (NOLOCK) on c.rfq_quote_SupplierQuote_id = d.rfq_quote_SupplierQuote_id
		WHERE YEAR(b.ReleaseDate) >= 2019
		AND c.is_rfq_resubmitted = 0 AND c.is_quote_submitted = 1
		AND d.is_awrded = 1
		UNION
		SELECT DISTINCT
			a.rfq_id AS RFQId
			,'5. Sum of RFQ award price' AS Type
			,CONVERT(DATE,b.ReleaseDate) [RFQ Date]
			,YEAR(b.ReleaseDate) [Year RFQ Date]
			,MONTH(b.ReleaseDate) [Month RFQ Date]
			,CONVERT(DECIMAL(15,4),SUM(d.per_unit_price * awarded_qty)) AwaredPrice
		FROM mp_rfq		a	(NOLOCK)
		JOIN 
		(
			SELECT rfq_id , MAX(status_date)  ReleaseDate
			FROM mp_rfq_release_history	(NOLOCK)
			GROUP BY  rfq_id 
		) b ON a.rfq_id = b.rfq_id
		JOIN mp_rfq_quote_supplierquote c (NOLOCK) on a.rfq_id = c.rfq_id
		JOIN mp_rfq_quote_items d (NOLOCK) on c.rfq_quote_SupplierQuote_id = d.rfq_quote_SupplierQuote_id
		WHERE YEAR(b.ReleaseDate) >= 2019
		AND c.is_rfq_resubmitted = 0 AND c.is_quote_submitted = 1
		AND d.is_awrded = 1
		GROUP BY 
			a.rfq_id 
			,CONVERT(DATE,b.ReleaseDate)
			,YEAR(b.ReleaseDate) 
			,MONTH(b.ReleaseDate) 
) a
JOIN mp_rfq_preferences		(NOLOCK) b ON a.RFQId = b.rfq_id
JOIN mp_mst_territory_classification (NOLOCK) c ON b.rfq_pref_manufacturing_location_id = c.territory_classification_id
JOIN mp_rfq_parts			(NOLOCK) d ON a.RFQId = d.rfq_id
JOIN mp_mst_part_category	(NOLOCK) e ON d.part_category_id = e.part_category_id
JOIN mp_mst_part_category	(NOLOCK) f ON f.part_category_id = e.parent_part_category_id
JOIN mp_rfq					(NOLOCK) g ON a.RFQId = g.rfq_id
WHERE 
g.contact_id NOT IN
(
	SELECT contact_id FROM mp_contacts (NOLOCK)
	WHERE user_id IN 
	(

	SELECT id FROM aspnetusers (NOLOCK) WHERE 
		email LIKE '%info@battleandbrew.com%'
		OR email LIKE '%rhollis@mfg.com%'
		OR email LIKE '%billtestermfg@gmail.com%'
		OR email LIKE '%adam@attractful.com%'
		OR email LIKE '%testsu%'
		OR email LIKE '%testbu%'
		OR email LIKE '%pmahant@delaplex.in%'
	) 
	UNION
	SELECT contact_id FROM mp_contacts (NOLOCK)
	WHERE  isnull(IsTestAccount,0)= 1
)
