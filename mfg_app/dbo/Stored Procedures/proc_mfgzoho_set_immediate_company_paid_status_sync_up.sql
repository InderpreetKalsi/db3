-- EXEC [proc_mfgzoho_set_immediate_company_paid_status_sync_up] @CompanyID = 1798857
CREATE PROCEDURE [dbo].[proc_mfgzoho_set_immediate_company_paid_status_sync_up]
(
	@CompanyID int
)
AS
BEGIN

SET NOCOUNT ON

/* 
	--M2-2800 Zoho -- Instant|Immediate Update Sync process to the Accounts Modules [AccountPaidStatus] field in the Zoho CRM. -- DB
	
*/

DECLARE @TransactionStatus BIT = CAST('false' AS BIT)

IF (isnull(@CompanyID ,0) > 0 ) 
BEGIN

	BEGIN TRY

	BEGIN TRANSACTION
	
		UPDATE a SET
			a.account_status = b.AccountStatus
			,a.issync = 0
			,isprocessed = NULL
		FROM  zoho..zoho_company_account a (NOLOCK)
		JOIN
		(
			SELECT DISTINCT e.company_id AS CompanyId, d.name AS AccountStatus
			FROM mp_gateway_subscription_customers a (NOLOCK)
			JOIN  
				(
					SELECT a.id, a.customer_id, a.plan_id
					FROM  [dbo].mp_gateway_subscriptions (NOLOCK) a
					JOIN
					(
						SELECT customer_id , MAX(id) subscription_id FROM  [dbo].mp_gateway_subscriptions (NOLOCK)
						GROUP BY customer_id
					) b on a.id = b.subscription_id
				) b on a.id =  b.customer_id AND a.company_id = @CompanyID
			JOIN mp_gateway_subscription_pricing_plans	c (NOLOCK) ON  b.plan_id = c.id
			JOIN mp_gateway_subscription_products		d (NOLOCK) ON  c.product_id = d.id
			JOIN mp_contacts e (NOLOCK) ON a.supplier_id = e.contact_id 
		) b ON a.VisionACCTID = b.CompanyId AND a.synctype = 1

		SET @TransactionStatus = CAST('true' AS BIT) 

		SELECT @CompanyID AS CompanyId, @TransactionStatus AS TransactionStatus

	COMMIT 
	END TRY

	BEGIN CATCH
			ROLLBACK
			SELECT @CompanyID AS CompanyId, @TransactionStatus AS TransactionStatus
	END CATCH
END
END
