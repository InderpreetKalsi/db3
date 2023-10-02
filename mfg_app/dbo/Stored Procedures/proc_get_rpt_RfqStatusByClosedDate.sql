
--  EXEC proc_get_rpt_RfqStatusByClosedDate  @FromClosedDate =  '01/01/22' , @ToClosedDate = '01/31/22'
CREATE PROCEDURE [dbo].[proc_get_rpt_RfqStatusByClosedDate]
(
	@FromClosedDate DATE =  NULL
	,@ToClosedDate DATE = NULL
)
AS
BEGIN

	-- M2-4576  Buyer - RFQ Status Reports - DB 
	SET NOCOUNT ON
	
	IF @FromClosedDate IS NULL 
		SET @FromClosedDate = '2022-01-01'

	IF @ToClosedDate IS NULL 
		SET @ToClosedDate = '2022-01-31'

	SELECT 
		ISNULL(d.territory_classification_name, 'No Rfq Location')  AS [Rfq Location]
		, ISNULL(b.description, 'No Rfq Status')  AS [Rfq Status]
		, COUNT(DISTINCT a.rfq_id) AS [No of Rfq's]
	FROM mp_rfq (NOLOCK) a
	JOIN (SELECT DISTINCT rfq_id FROM mp_rfq_release_history (NOLOCK)) a1 ON a.rfq_id = a1.rfq_id
	LEFT JOIN mp_mst_rfq_buyerstatus (NOLOCK) b ON a.rfq_status_id = b.rfq_buyerstatus_id
	LEFT JOIN dbo.mp_rfq_preferences (NOLOCK) c ON a.rfq_id = c.rfq_id
	LEFT JOIN dbo.mp_mst_territory_classification (NOLOCK) d ON c.rfq_pref_manufacturing_location_id = d.territory_classification_id
	WHERE CAST(a.Quotes_needed_by AS DATE)  BETWEEN @FromClosedDate AND @ToClosedDate
	GROUP BY 
		ISNULL(d.territory_classification_name, 'No Rfq Location')
		,ISNULL(b.description, 'No Rfq Status')
	ORDER BY [Rfq Location] , [Rfq Status]

END