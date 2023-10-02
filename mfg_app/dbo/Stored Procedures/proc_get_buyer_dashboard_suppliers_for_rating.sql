
/*

	EXEC [proc_get_buyer_dashboard_suppliers_for_rating] @BuyerId = 1349461

*/
CREATE PROCEDURE [dbo].[proc_get_buyer_dashboard_suppliers_for_rating]
(
	@BuyerId INT
)
AS
BEGIN
	
	SET NOCOUNT ON

	/*
		-- Created	:	May 28, 2020
					:	M2-2902 Buyer - Dashboard - New Ratings Module - DB
	*/
	

	UPDATE a SET a.IsAlreadyRated = 1 , a.LastRatedOn = CONVERT(DATE,b.created_date) ,a.RatedRfq = 1
	FROM mp_buyer_dashboard_supplier_for_ratings (NOLOCK) a
	JOIN mp_rating_responses (NOLOCK) b 
	ON	a.BuyerId = b.from_id 
			AND a.SupplierId = b.to_id 
			AND a.RfqId = b.rfq_id
			AND a.IsAlreadyRated = 0
			AND a.BuyerId = @BuyerId


	UPDATE a SET a.IsAlreadyRated = 1 , a.LastRatedOn = CONVERT(DATE,b.created_date)
	FROM mp_buyer_dashboard_supplier_for_ratings (NOLOCK) a
	JOIN mp_rating_responses (NOLOCK) b 
		ON	a.BuyerId = b.from_id 
			AND a.SupplierId = b.to_id 
			AND (b.rfq_id IS NULL OR b.rfq_id = 0)
			AND a.IsAlreadyRated = 0
			AND CONVERT(DATE,a.RfqClosedDate) <= CONVERT(DATE,b.created_date)
			AND a.BuyerId = @BuyerId


	SELECT DISTINCT TOP 2
		a.BuyerId
		,a.SupplierId
		,c.first_name +' '+c.last_name AS Supplier
		,c.company_id SupplierCompanyId
		,a.RfqId
		,a.RfqClosedDate
		,IIF(filetype.filetype_id=6,spefile.FILE_NAME, NULL) AS SupplierCompanyLogo 
		,d.name AS SupplierCompany
		,e.territory_classification_name AS SupplierLocation
		,
		CASE 
			WHEN a.AwardedDate IS NULL THEN
		'This manufacturer quoted RFQ #'+CONVERT(VARCHAR(100),a.RfqId)+' on '+FORMAT(a.QuoteDate, 'd', 'en-US' )+', and you communicated '+CONVERT(VARCHAR(100),ISNULL(f.CommunicateCount,0))+' times with them.'
			WHEN a.AwardedDate IS NOT NULL THEN
			'You awarded part(s) to this manufacturer from RFQ #'+CONVERT(VARCHAR(100),a.RfqId)+' on '+FORMAT(a.AwardedDate, 'd', 'en-US' )+'. Rate your experience to help others.'
		END RatingMessage
	FROM
	(
		SELECT		
			SupplierId
			,BuyerId
			,RfqId
			,RfqClosedDate
			,QuoteDate
			,AwardedDate
			,Id
			,IsAlreadyRated
			,IsExclude
			,ROW_NUMBER() OVER (PARTITION BY SupplierId  ORDER BY SupplierId , Id  DESC) RN
		FROM mp_buyer_dashboard_supplier_for_ratings (NOLOCK) a
		WHERE 
			BuyerId = @BuyerId
			AND a.IsAlreadyRated = 0
			AND a.IsExclude = 0
			AND NOT EXISTS 
			(SELECT * FROM mp_buyer_dashboard_supplier_for_ratings (NOLOCK) b WHERE b.BuyerId = @BuyerId AND b.SupplierId = a.SupplierId AND DATEDIFF(DAY,LastRatedOn,GETUTCDATE())  <16 )
	) a
	JOIN mp_contacts c (NOLOCK) ON a.SupplierId = c.contact_id 
	JOIN mp_companies d (NOLOCK) ON c.company_id = d.company_id 
	LEFT JOIN mp_mst_territory_classification e (NOLOCK) ON d.manufacturing_location_id = e.territory_classification_id
	LEFT JOIN mp_special_files spefile (NOLOCK)
		ON c.company_id=spefile.COMP_ID and c.contact_id=spefile.CONT_ID and filetype_id = 6  
	LEFT JOIN mp_mst_filetype filetype  (NOLOCK) ON(spefile.FILETYPE_ID = filetype.filetype_id) 
	LEFT JOIN 
	(
		SELECT rfq_id RfqId, to_cont SupplierId , COUNT(1) CommunicateCount  FROM mp_messages (NOLOCK) WHERE rfq_id IS NOT NULL AND from_cont =  @BuyerId
		GROUP BY rfq_id ,to_cont
	) f ON a.SupplierId = f.SupplierId	AND a.RfqId = f.RfqId
	WHERE RN  =1
	ORDER BY RfqClosedDate


	


END
