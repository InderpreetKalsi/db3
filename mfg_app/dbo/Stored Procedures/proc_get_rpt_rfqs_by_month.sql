
/*

SELECT distinct rfqid
FROM mp_rfq_release_closed_date_range (NOLOCK)
WHERE RFQDateRange BETWEEN '2020-10-01' AND '2020-10-01'


EXEC [proc_get_rpt_rfqs_by_month]
@StartDate = '2020-10-01' 
,@EndDate = '2020-10-01' 


*/
CREATE PROCEDURE [dbo].[proc_get_rpt_rfqs_by_month]
(
	@StartDate	DATE NULL
	,@EndDate	DATE NULL
)
AS
BEGIN
	/* M2-3349 Report - RFQ's release by processes by month */
	SET NOCOUNT ON

	SELECT
		a.[RFQ Location]
		, a.[Discipline 0]
		, COUNT(DISTINCT a.[Buyers] )	AS [Unique Buyer Count]
		, COUNT(DISTINCT a.[RFQs] )		AS [Unique RFQ Count]
		, SUM(a.[Suppliers] )	AS [Unique Supplier Quoted]
	FROM
	(
		SELECT 
			DISTINCT
			f.territory_classification_name AS [RFQ Location]
			,g.discipline_name AS [Discipline 0]
			,a.contact_id AS [Buyers]
			,a.rfq_id AS [RFQs]
			,a1.UniqueSuppliers AS [Suppliers]
		
		FROM 
		(
			SELECT DISTINCT RFQId ,UniqueSuppliers
			FROM mp_rfq_release_closed_date_range (NOLOCK)
			WHERE RFQDateRange BETWEEN @StartDate AND @EndDate
		) a1
		JOIN mp_rfq								(NOLOCK) a ON a1.RFQId = a.rfq_id --AND a.rfq_status_id IN (3,5,6,16,17)
		JOIN mp_rfq_parts						(NOLOCK) b ON a.rfq_id = b.rfq_id
		JOIN mp_mst_part_category				(NOLOCK) c ON b.part_category_id = c.part_category_id
		JOIN mp_mst_part_category				(NOLOCK) g ON c.parent_part_category_id = g.part_category_id
		JOIN mp_rfq_preferences					(NOLOCK) e ON a.rfq_id = e.rfq_id
		JOIN mp_mst_territory_classification	(NOLOCK) f ON e.rfq_pref_manufacturing_location_id = f.territory_classification_id
		JOIN mp_contacts						(NOLOCK) h ON a.contact_id = h.contact_id   and isnull(h.IsTestAccount,0)= 0
	) a 
	GROUP BY --ROLLUP ( f.territory_classification_name , c.discipline_name )
		a.[RFQ Location]
		, a.[Discipline 0]
	ORDER BY a.[RFQ Location] , a.[Discipline 0] --, c.discipline_name 
	
END
