-- select * from vwRptMessageTrailBuyerToSupplier order by  Buyer
CREATE VIEW [dbo].[vwRptMessageTrailBuyerToSupplier]
AS

WITH BuyerToSupplierOneToOneMessages AS
(
	SELECT 
		message_id, from_cont , to_cont ,CONVERT(DATE,message_date) message_date 
		, CASE WHEN message_type_id = 5	THEN 'Internal Messages' ELSE 'External Messages' END messagetype 
	FROM mp_messages (NOLOCK) m
	WHERE message_type_id IN (5,225) --AND rfq_id IS NULL
	AND YEAR(message_date) >=2019
	AND  NOT EXISTS
	(
		SELECT a.contact_id
		FROM
		(
			SELECT contact_id FROM mp_contacts (NOLOCK)
			WHERE user_id IN 
			(

				SELECT id FROM aspnetusers  (NOLOCK) WHERE 
				email LIKE '%info@battleandbrew.com%'
				OR email LIKE '%rhollis@mfg.com%'
				OR email LIKE '%billtestermfg@gmail.com%'
				OR email LIKE '%adam@attractful.com%'
				OR email LIKE '%testsu%'
				OR email LIKE '%testbu%'
				OR email LIKE '%pmahant@delaplex.in%'
			) 
			UNION
			SELECT contact_id FROM mp_contacts (NOLOCK)
			WHERE  isnull(IsTestAccount,0)= 1
		) a 
		WHERE m.from_cont = a.contact_id
	)
)
SELECT 
	DISTINCT
	b.first_name +' '+ b.last_name AS Buyer
	, c.name AS BuyerAccount
	, CASE WHEN b.Is_Validated_Buyer = 1 THEN 'Yes' ELSE 'No' END AS IsValidated  
	, a.messagetype AS MessageType
	, a.message_date AS MessageDate
	, d.first_name +' '+ d.last_name AS Supplier
	, e.name AS SupplierAccount
FROM BuyerToSupplierOneToOneMessages a
LEFT JOIN mp_contacts	b (NOLOCK) on a.from_cont = b.contact_id and b.is_buyer = 1
LEFT JOIN mp_companies	c (NOLOCK) on b.company_id = c.company_id
JOIN mp_contacts	d (NOLOCK) on a.to_cont = d.contact_id  and isnull(d.IsTestAccount,0)= 0
JOIN mp_companies	e (NOLOCK) on d.company_id = e.company_id
