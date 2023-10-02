
/*
M2-4823 Buyer - Non-purchase order update award status modal - DB

EXEC  proc_get_NonPurchaseOrderAwardModalSupplierList  1164368,1368471,4
*/

CREATE PROCEDURE [dbo].[proc_get_NonPurchaseOrderAwardModalSupplierList]
(
	 @RfqId INT
	,@RfqBuyerContactId INT
	,@AwardedRegionId INT
)
AS
BEGIN
	--DECLARE @RfqId INT = 1164368 --1164371
	--,@BuyerRfqContactid INT = 1368471

	SELECT 
	a.rfq_id
	, b.rfq_pref_manufacturing_location_id AS [AwardedRegionId]
	--, c.contact_id [SupplierContactId] 
	, e.name AS AwardedCompanyName 
	, e.company_id AS [AwardedCompanyId]
	FROM mp_rfq(NOLOCK) a
	JOIN mp_rfq_preferences(NOLOCK) b ON a.rfq_id = b.rfq_id
	JOIN mp_rfq_quote_SupplierQuote (NOLOCK) c ON a.rfq_id = c.rfq_id
	JOIN mp_contacts (NOLOCK) d ON d.contact_id =c.contact_id
	JOIN mp_companies(NOLOCK) e ON e.company_id = d.company_id
	WHERE a.rfq_id  = @RfqId
	AND a.contact_id = @RfqBuyerContactId
	--AND a.rfq_status_id = 3
	AND b.rfq_pref_manufacturing_location_id = @AwardedRegionId

	UNION

	SELECT 
	a.rfq_id
	, b.rfq_pref_manufacturing_location_id AS [AwardedRegionId]
	--, c.contact_id [SupplierContactId] 
	, e.name AS AwardedCompanyName 
	, e.company_id AS [AwardedCompanyId]
	from mp_rfq(NOLOCK) a
	JOIN mp_rfq_preferences(NOLOCK) b ON a.rfq_id = b.rfq_id
	JOIN mp_rfq_quote_SupplierQuote (NOLOCK) c ON a.rfq_id = c.rfq_id
	JOIN mp_contacts (NOLOCK) d ON d.contact_id =c.contact_id
	JOIN mp_companies(NOLOCK) e ON e.company_id = d.company_id
	where  a.rfq_id in
	(
	SELECT cloned_rfq_id FROM mp_rfq_cloned_logs(NOLOCK) WHERE parent_rfq_id =  @RfqId
	UNION
	SELECT parent_rfq_id FROM mp_rfq_cloned_logs(NOLOCK) WHERE cloned_rfq_id = @RfqId  
	)
	AND a.contact_id = @RfqBuyerContactId
	--AND a.rfq_status_id = 3
	AND b.rfq_pref_manufacturing_location_id = @AwardedRegionId

END
