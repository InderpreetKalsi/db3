
-- EXEC proc_stripe_get_email_subscription_info @supplier_id =  1349106,  @stripe_pricing_plan_id = 'plan_H0gRTDU3XAz6sb'
CREATE PROCEDURE [dbo].[proc_stripe_get_email_subscription_info]
(
	@supplier_id	INT
	,@stripe_pricing_plan_id VARCHAR(250)
)
AS
BEGIN
	
	SET NOCOUNT ON
	/* M2-2671  M - Confirmation overview email of purchase and subscription / contract details */

	DECLARE @company			VARCHAR(250)
	DECLARE @supplier			VARCHAR(250)
	DECLARE @supplier_email_id	VARCHAR(250)
	DECLARE @sourcing_advisor	VARCHAR(250)
	DECLARE @sourcing_advisor_designation	VARCHAR(250)
	DECLARE @sourcing_advisor_phoneno		VARCHAR(250)

	SELECT 
		@supplier = (a.first_name +' '+ a.last_name)
		,@company  = b.name
		,@supplier_email_id = c.email
		,@sourcing_advisor = (d.first_name +' '+ d.last_name)
		,@sourcing_advisor_designation =  d.title
		,@sourcing_advisor_phoneno = communication_value
	FROM mp_contacts	(NOLOCK) a
	JOIN mp_companies 	(NOLOCK) b ON a.company_id = b.company_id
	JOIN aspnetusers	(NOLOCK) c ON a.user_id = c.id
	LEFT JOIN mp_contacts	(NOLOCK) d ON b.Assigned_SourcingAdvisor = d.contact_id
	LEFT JOIN mp_communication_details (NOLOCK) e ON d.contact_id = e.contact_id
	WHERE a.contact_id = @supplier_id

	SELECT 
		TOP 1 
			@supplier			AS Supplier
			,@company			AS Company
			,@supplier_email_id AS Email
			,a.billing_interval	AS BillingInterval
			,a.price			AS PlanPrice
			,b.name				AS [Plan]
			,d.upgrade_title	AS UpgragePlan	 
			,@sourcing_advisor				AS SourcingAdvisor
			,@sourcing_advisor_designation	AS SourcingAdvisorDesignation
			,@sourcing_advisor_phoneno		AS SourcingAdvisorPhoneNo
	FROM mp_stripe_pricing_plans						a (NOLOCK) 
	JOIN [mp_stripe_products]							b (NOLOCK) ON (a.product_id = b.id)
	JOIN [mp_stripe_account_upgrade_product_mappings]	c (NOLOCK) ON (b.id = c.product_id)
	JOIN [mp_stripe_account_upgrades]					d (NOLOCK) ON(c.upgrade_id = d.id)
	WHERE a.stripe_pricing_plan_id = @stripe_pricing_plan_id

END
