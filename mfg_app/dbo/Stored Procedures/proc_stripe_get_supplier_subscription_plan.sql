
/*


EXEC [proc_stripe_get_supplier_subscription_plan] @supplier_id = 1337827
EXEC [proc_stripe_get_supplier_payment_method] @supplier_id = 1337827
EXEC [proc_stripe_get_supplier_subscription_invoices] @supplier_id = 1337827

*/
CREATE  PROCEDURE [dbo].[proc_stripe_get_supplier_subscription_plan]
(
	@supplier_id		INT
)
AS
BEGIN

	/*
		CREATED	:	MAR 18, 2020	
		DESC	:	M2-2713 M - Billing History and Contract page - DB
	*/

	SET NOCOUNT ON

	DROP TABLE IF EXISTS #ListofContacts

	SELECT contact_id 
	INTO #ListofContacts
	FROM mp_contacts (NOLOCK) WHERE company_id IN
	(
		SELECT company_id FROM mp_contacts (NOLOCK) WHERE contact_id = @supplier_id
	)

	SELECT 
		a.stripe_customer_id AS StripeCustomerId
		,b.stripe_subscription_id  AS StripeSubscriptionId
		,d.name AS ActiveSubscriptionPlan
		,CASE WHEN  c.billing_interval = 'Quarterly' THEN ' Quarterly Rate: ' WHEN  c.billing_interval = 'Yearly' THEN ' Yearly Rate: ' END AS SubscriptionInterval
		,'$'+CONVERT(VARCHAR(250),c.price) AS SubscriptionPlanPrice
		,FORMAT(b.subscription_end,'dd/MM/yyyy ') AS NextBillingDate
	FROM  [dbo].[mp_stripe_customers] a (NOLOCK)
	JOIN
	(
		SELECT a.customer_id, a.plan_id ,a.subscription_end , a.stripe_subscription_id
		FROM  [dbo].[mp_stripe_customer_subscriptions] (NOLOCK) a
		JOIN
		(
			SELECT customer_id , MAX(id) subscription_id FROM  [dbo].[mp_stripe_customer_subscriptions] (NOLOCK)
			GROUP BY customer_id
		) b on a.id = b.subscription_id
	) b on a.id =  b.customer_id
	JOIN mp_stripe_pricing_plans		(NOLOCK) c ON c.id = b.plan_id
	JOIN mp_stripe_products				(NOLOCK) d ON d.id = c.product_id
	WHERE 
		a.supplier_id  IN (SELECT contact_id FROM #ListofContacts)


	DROP TABLE IF EXISTS #ListofContacts
END
