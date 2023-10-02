
/*

EXEC proc_set_buyer_dashboard_new_suppliers

*/
CREATE PROCEDURE [dbo].[proc_set_buyer_dashboard_new_suppliers]
AS
BEGIN

		/*
		-- Created	:	May 28, 2020
					:	M2-2904 Buyer - New Manufacturer module - DB
		*/


		INSERT INTO mp_buyer_dashboard_new_suppliers
		(BuyerId,SupplierId)
		SELECT a.buyer_id, a.supplier_id
		FROM
		(
			SELECT a.contact_id buyer_id, b.supplier_id 
			FROM mp_contacts a (NOLOCK)
			CROSS APPLY
			(
				SELECT DISTINCT supplier_id
				FROM mp_gateway_subscription_customers a (NOLOCK) 
				JOIN mp_gateway_subscriptions b (NOLOCK) ON a.id = b.customer_id AND b.status = 'Live'
					AND CONVERT(DATE,b.created+7) < CONVERT(DATE,GETUTCDATE()) 
			) b
			WHERE a.is_buyer = 1 AND a.is_active = 1 
		) a
		LEFT JOIN mp_buyer_dashboard_new_suppliers  b (NOLOCK) ON a.buyer_id = b.BuyerId and a.supplier_id = b.SupplierId
		WHERE b.SupplierId IS NULL
END
