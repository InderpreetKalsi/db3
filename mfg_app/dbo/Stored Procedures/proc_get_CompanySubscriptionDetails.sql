


/*
--select id as customerId, *  from Mp_Gateway_Subscription_Customers(nolock) where company_id = 1770029
--select plan_id, * from Mp_Gateway_Subscriptions(nolock) where customer_id = 1013 and status = 'active'
--select  * from Mp_Gateway_Subscription_Products where id = 1003

exec proc_get_CompanySubscriptionDetails 1769973

M2-4659 Implementation of showing Stripe Customer Portal on button click
*/

CREATE PROCEDURE [dbo].[proc_get_CompanySubscriptionDetails]
(
	@CompanyId INT
)
AS
BEGIN
	-- M2-4659 Implementation of showing Stripe Customer Portal on button click

	SET NOCOUNT ON
	--DECLARE @CompanyId INT = 	1770029
	DECLARE @IsCustomerSubscribed 		BIT = 0
	DECLARE @IsCapabilitySet 			BIT = 0
	DECLARE @SubscriptionPlan  			VARCHAR(250)=''
	DECLARE @CustomerId INT = 	0
	DECLARE @PlanId INT = 	0
	DECLARE @ProductId INT = 	0

 
	SET @CustomerId = (SELECT [id]  FROM mp_gateway_subscription_customers(NOLOCK) WHERE company_id = @CompanyId)
	SET @PlanId = (SELECT [plan_id]  FROM mp_gateway_subscriptions(NOLOCK) WHERE customer_id = @CustomerId)

	--- IsCustomerSubscribed
	IF (SELECT COUNT(1) FROM mp_gateway_subscription_pricing_plans (NOLOCK) WHERE id = @PlanId)  > 0
			SET @IsCustomerSubscribed = 1
	
	SET  @ProductId = (SELECT product_id  FROM mp_gateway_subscription_pricing_plans(NOLOCK) WHERE id = @PlanId)
	
	-- SubscriptionPlan  
	SET  @SubscriptionPlan = (SELECT [NAME] FROM mp_gateway_subscription_products (NOLOCK) WHERE id = @ProductId)
	
	-- IsCapabilitySet 
	IF (SELECT COUNT(1) FROM mp_gateway_subscription_company_processes (NOLOCK) WHERE company_id = @CompanyId)  > 0
		   SET @IsCapabilitySet = 1

	SELECT  @IsCustomerSubscribed AS IsCustomerSubscribed ,@SubscriptionPlan AS SubscriptionPlan , @IsCapabilitySet AS IsCapabilitySet
 
 END
