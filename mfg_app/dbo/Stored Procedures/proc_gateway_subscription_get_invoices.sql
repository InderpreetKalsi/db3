
/*
	EXEC [proc_gateway_subscription_get_invoices] @supplier_id = 1349270
*/

CREATE  PROCEDURE [dbo].[proc_gateway_subscription_get_invoices]
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

	SELECT DISTINCT
		a.subscription_customer_id AS SubscriptioneCustomerId
		,e.subscription_id  AS SubscriptionSubscriptionId
		,invoice_date AS InvoiceDate
		,CONVERT(DECIMAL(18,2),invoice_amount) AS InvoiceAmount
		,subscription_invoice_id AS SubscriptionInvoiceId
		,invoice_id AS InvoiceId
		, InvoicehostedPDF AS InvoicePDF
	FROM  [dbo].[mp_gateway_subscription_customers] a (NOLOCK)
	JOIN  
	(
		SELECT a.id, a.customer_id, a.subscription_end ,a.subscription_id
		FROM  [dbo].[mp_gateway_subscriptions] (NOLOCK) a
	) e on a.id =  e.customer_id
	JOIN
	(
		SELECT 
			a.subscription_invoice_id , a.id invoice_id , a.subscription_id , a.invoice_no 
			, FORMAT(a.invoice_date,'MM/dd/yyyy ') AS invoice_date , a.amount_due AS invoice_amount
			, a.invoice_pdf AS InvoicePDF
			, a.invoice_hosted_url AS InvoicehostedPDF
		FROM  [dbo].mp_gateway_subscription_invoices (NOLOCK) a
		JOIN
		(
			SELECT subscription_id, subscription_invoice_id , MAX(id) invoice_id 
			FROM  [dbo].mp_gateway_subscription_invoices (NOLOCK)
			GROUP BY subscription_id, subscription_invoice_id 
		) b on a.id = b.invoice_id
	) b on e.subscription_id =  b.subscription_id
	WHERE 
		a.supplier_id = @supplier_id
	ORDER BY InvoiceDate DESC , InvoiceId DESC


END
