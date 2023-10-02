
CREATE VIEW [dbo].[vwRptSupplierSavedSearchFilters]
AS
SELECT
	b.first_name + ' '+ b.last_name AS Supplier
	,c.name AS Company
	,ISNULL(e.paid_status,'Free') AS [Paid Status]
	,total_filters AS [Total Filters]
	,(total_filters - ISNULL(totalfilters,0)) AS [Total Filters Excluding My Capabilities]
FROM
(
SELECT contact_id , COUNT(1) total_filters
FROM mp_saved_search (NOLOCK)
GROUP BY contact_id
) a
JOIN mp_contacts		b (NOLOCK) ON a.contact_id = b.contact_id  and b.IsTestAccount= 0
JOIN mp_companies		c (NOLOCK) ON b.company_id = c.company_id
LEFT JOIN
(
	SELECT contact_id , COUNT(1) totalfilters
	FROM mp_saved_search (NOLOCK) 
	WHERE search_filter_name = 'My Capabilities'
	GROUP BY contact_id
) d ON a.contact_id = d.contact_id
LEFT JOIN 
(
	SELECT 
		VisionACCTID  AS company_id
		,(
			CASE	
				WHEN account_status in('active','gold') THEN 'Gold' --1
				WHEN account_status = 'silver'          THEN 'Silver'
				WHEN account_status = 'platinum'        THEN 'Platinum'
				ELSE 'Free' 
			 END
		 ) AS paid_status

	FROM ZOHO..Zoho_company_account (NOLOCK) WHERE synctype = 2 AND  account_type_id = 3
) e ON c.company_id = e.company_id

WHERE  b.contact_id NOT IN
	(
		SELECT contact_id FROM mp_contacts (NOLOCK)
		WHERE user_id IN 
		(

		SELECT id FROM aspnetusers WHERE 
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
	)
