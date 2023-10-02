
-- select * from vwRptMessageTrailBuyerToSupplier order by  Buyer
CREATE VIEW [dbo].[vwRptMessageTrailBuyerToSupplier_AllMessages]
AS

WITH AllMessagesBuyerToSupplier AS
(
	SELECT 
		from_cont , to_cont ,CONVERT(DATE,message_date) message_date , message_type_id , message_id
	FROM mp_messages (NOLOCK)
	WHERE 
	CONVERT(DATE,message_date) >='2019-02-17'
	AND  from_cont NOT IN
	(
		SELECT contact_id FROM mp_contacts (NOLOCK)
		WHERE 
		(
			user_id IN 
			(

			SELECT id FROM aspnetusers WHERE 
			email LIKE '%info@battleandbrew.com%'
			OR email LIKE '%rhollis@mfg.com%'
			OR email LIKE '%billtestermfg@gmail.com%'
			OR email LIKE '%adam@attractful.com%'
			OR email LIKE '%testsu%'
			OR email LIKE '%testbu%'
			) 
			OR company_id = 0 
			OR is_buyer = 0
		)
		UNION
		SELECT contact_id FROM mp_contacts (NOLOCK)
		WHERE  isnull(IsTestAccount,0)= 1
	)
	--and from_cont = 1359059
	
)
SELECT 
	b.first_name +' '+ b.last_name AS Buyer
	, c.name AS BuyerAccount
	, CASE WHEN b.Is_Validated_Buyer = 1 THEN 'Yes' ELSE 'No' END AS IsValidated  
	, f.message_type_name AS MessageType
	, a.message_date AS MessageDate
	, d.first_name +' '+ d.last_name AS Supplier
	, e.name AS SupplierAccount


FROM AllMessagesBuyerToSupplier a
JOIN mp_contacts	b (NOLOCK) on a.from_cont = b.contact_id and b.is_buyer = 1  and isnull(b.IsTestAccount,0)= 0
JOIN mp_companies	c (NOLOCK) on b.company_id = c.company_id
JOIN mp_contacts	d (NOLOCK) on a.to_cont = d.contact_id  and d.is_buyer = 0  and isnull(d.IsTestAccount,0)= 0
JOIN mp_companies	e (NOLOCK) on d.company_id = e.company_id
JOIN mp_mst_message_types f (NOLOCK) on a.message_type_id = f.message_type_id
