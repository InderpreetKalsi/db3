
/*
EXEC proc_get_company_account_type @companyid = 1768050

select * from aspnetusers where email  like '%livequote%'
select * from mp_contacts where user_id = '0cf490d2-47d2-43f8-90e0-e17dff649885' or company_id = 1768843
SELECT TOP 50  * FROM mp_contacts WHERE contact_id = 1337916 or company_id = 1768050 ORDER BY company_id DESC

EXEC [proc_stripe_get_supplier_subscription_invoices] @supplier_id = 1349076

*/
CREATE  PROCEDURE [dbo].[proc_stripe_get_supplier_subscription_invoices]
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

	SELECT DISTINCT
		a.stripe_customer_id AS StripeCustomerId
		,e.stripe_subscription_id  AS StripeSubscriptionId
		,invoice_date AS InvoiceDate
		,CONVERT(DECIMAL(18,2),invoice_amount/100 ) AS InvoiceAmount
		,stripe_invoice_id AS StripeInvoiceId
		,invoice_id AS InvoiceId
		, InvoicehostedPDF AS InvoicePDF
	FROM  [dbo].[mp_stripe_customers] a (NOLOCK)
	JOIN  
	(
		SELECT a.id, a.customer_id, a.subscription_end ,a.stripe_subscription_id
		FROM  [dbo].[mp_stripe_customer_subscriptions] (NOLOCK) a
		--JOIN
		--(
		--	SELECT customer_id , MAX(id) subscription_id FROM  [dbo].[mp_stripe_customer_subscriptions] (NOLOCK)
		--	GROUP BY customer_id
		--) b on a.id = b.subscription_id
	) e on a.id =  e.customer_id
	JOIN
	(
		SELECT 
			a.stripe_invoice_id , a.id invoice_id , a.subscription_id , a.invoice_no 
			, FORMAT(a.created,'MM/dd/yyyy ') AS invoice_date , a.amount_due AS invoice_amount
			, a.invoice_pdf AS InvoicePDF
			, a.invoice_hosted_url AS InvoicehostedPDF
		FROM  [dbo].[mp_stripe_customer_subscription_invoices] (NOLOCK) a
		JOIN
		(
			SELECT subscription_id, stripe_invoice_id , MAX(id) invoice_id 
			FROM  [dbo].[mp_stripe_customer_subscription_invoices] (NOLOCK)
			GROUP BY subscription_id, stripe_invoice_id 
		) b on a.id = b.invoice_id
	) b on e.id =  b.subscription_id
	WHERE 
		a.supplier_id IN (SELECT contact_id FROM #ListofContacts)
	ORDER BY InvoiceDate DESC , InvoiceId DESC


	DROP TABLE IF EXISTS #ListofContacts
END
