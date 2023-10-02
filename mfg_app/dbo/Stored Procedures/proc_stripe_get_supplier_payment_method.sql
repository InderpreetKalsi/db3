
/*
EXEC [proc_stripe_get_supplier_payment_method] @supplier_id = 1337827
*/
CREATE  PROCEDURE [dbo].[proc_stripe_get_supplier_payment_method]
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
		g.stripe_customer_id AS StripeCustomerId
		,b.name AS SupplierCompany
		, (
			isnull(c.address1,'') +',' 
			+ isnull(c.address2,'')  
			+char(13) + char(10)+ isnull(c.address4,'')+',' 
			+char(13) + char(10)+ isnull(e.region_name,'')+','
			+char(13) + char(10)+ isnull(d.iso_code,'')+','  
			+char(13) + char(10)+ isnull(c.address3,'')
		  )  AS SupplierAddress
		, f.communication_value AS SupplierContactNo
		, h.card_brand		AS SupplierCardBrand
		, 'xxxx xxxx xxxx ' + h.card_last4digit AS SupplierCardLast4Digit
		, h.stripe_card_id AS SupplierStripeCardId
	FROM mp_contacts					a (NOLOCK)
	JOIN mp_companies					b (NOLOCK) ON a.company_id = b.company_id
	JOIN mp_addresses					c (NOLOCK) ON a.address_id = c.address_id
	LEFT JOIN mp_mst_country			d (NOLOCK) ON c.country_id = d.country_id
	LEFT JOIN mp_mst_region				e (NOLOCK) ON c.region_id = e.region_id
	LEFT JOIN mp_communication_details	f (NOLOCK) ON a.contact_id = f.contact_id  and communication_type_id = 1
	JOIN mp_stripe_customers			g (NOLOCK) ON a.contact_id =  g.supplier_id
	JOIN 		
	(
		SELECT a.*
		FROM  [dbo].mp_stripe_customer_cards (NOLOCK) a
		JOIN
		(
			SELECT customer_id , MAX(id) card_id FROM  [dbo].mp_stripe_customer_cards (NOLOCK)
			GROUP BY customer_id
		) b on a.id = b.card_id
	) h  ON g.id = h.customer_id

	WHERE 
		a.contact_id  IN (SELECT contact_id FROM #ListofContacts)

	DROP TABLE IF EXISTS #ListofContacts
END
