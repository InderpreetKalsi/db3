
--SELECT * FROM vwRptRFQsCreatedPast90Days  WHERE [DaysRFQCreated] < =90 ORDER BY [Buyer]

CREATE VIEW  [dbo].[vwRptRFQsCreatedPast90Days]
AS

SELECT 
	a.contact_id AS [BuyerId]
	,b.first_name +' '+b.last_name AS [Buyer]
	,f.email AS [Email]
	,FORMAT(a.rfq_created_on, 'd', 'en-US' )  AS [RFQ Created]
	,d.discipline_name AS [Process]
	,CONVERT(INT,COUNT(DISTINCT a.rfq_id)) AS NoOfRFQs
	,CONVERT(INT,DATEDIFF(DAY,a.rfq_created_on, GETUTCDATE()))  AS [DaysRFQCreated]
	,a.rfq_id RFQId
	,CASE WHEN (SELECT COUNT(DISTINCT part_category_id) FROM mp_rfq_parts WHERE  a.rfq_id = rfq_id) = 1 THEN 'Yes' ELSE 'No' END  RFQWithSingleCapability
FROM mp_rfq			a (NOLOCK)
JOIN mp_contacts	b (NOLOCK) ON a.contact_id = b.contact_id AND a.rfq_status_id IN (3,5,6)   and IsTestAccount= 0
JOIN mp_rfq_parts	c (NOLOCK) ON a.rfq_id = c.rfq_id
JOIN mp_mst_part_category d (NOLOCK) ON c.part_category_id = d.part_category_id
JOIN mp_rfq_release_history e (NOLOCK) ON a.rfq_id = e.rfq_id
JOIN aspnetusers	f (NOLOCK) ON b.user_id = f.id
GROUP BY 
	a.contact_id
	,b.first_name +' '+b.last_name 
	,f.email
	,FORMAT(a.rfq_created_on, 'd', 'en-US' )  
	,CONVERT(INT,DATEDIFF(DAY,a.rfq_created_on, GETUTCDATE()))
	,d.discipline_name
	,a.rfq_id
