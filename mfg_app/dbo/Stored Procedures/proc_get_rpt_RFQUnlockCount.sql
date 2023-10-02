/*
    By Eddie
  	Need a report, all the growth users and how many unlocks they had had.

*/
 
---- exec [dbo].[proc_get_rpt_RFQUnlockCount]  
CREATE PROCEDURE [dbo].[proc_get_rpt_RFQUnlockCount] 
AS
BEGIN

	SELECT  
			a.company_id [Company Id]
			, c.name     [Name]
			, b.subscription_start [Subscription Start]
			, b.subscription_end   [Subscription End]
				  --, datediff(dd,b.subscription_start ,b.subscription_end) noofdays
			, (SELECT count(1) FROM mpGrowthPackageUnlockRFQsInfo(NOLOCK) c WHERE c.CompanyId = a.company_id 
					AND UnlockDate BETWEEN b.subscription_start AND b.subscription_end AND c.IsDeleted = 0 ) UnlockRFQCount
			, b.status 
			, b.RequestType
		FROM [dbo].[mp_gateway_subscription_customers] (NOLOCK) a
		JOIN [dbo].[mp_gateway_subscriptions] (NOLOCK) b ON a.id= b.customer_id
		JOIN mp_companies ( nolock) c on c.company_id = a.company_id
		WHERE a.gateway_id = 310 and a.company_id !=0
	--	 and b.status = 'active'
		ORDER BY a.company_id , b.id 
END