
-- SELECT TOP 100 * FROM vwRptBuyerActivity order by BUYER , ActivityDate DESC
CREATE VIEW [dbo].[vwRptBuyerActivity]
AS

WITH BuyerLoginActivity AS
(
	SELECT 
		a.contact_id , 'Login' Activity, CONVERT(DATETIME,a.login_datetime) ActivityDate
	FROM mp_user_logindetail (NOLOCK) a
	JOIN mp_contacts (NOLOCK) b ON a.contact_id = b.contact_id AND b.is_buyer = 1  and isnull(b.IsTestAccount,0)= 0
	WHERE YEAR(a.login_datetime) >=2019
	AND  a.contact_id NOT IN
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
		SELECT contact_id FROM mp_contacts (NOLOCK) WHERE isnull(IsTestAccount,0)= 1
	)
),
 BuyerOtherActivity AS
(
	SELECT 
		a.contact_id , c.activity Activity, CONVERT(DATE,a.activity_date) ActivityDate
	FROM mp_track_user_activities (NOLOCK) a
	JOIN mp_contacts (NOLOCK) b ON a.contact_id = b.contact_id AND b.is_buyer = 1 and isnull(b.IsTestAccount,0)= 0
	JOIN mp_mst_activities (NOLOCK) c ON a.activity_id = c.activity_id 
	WHERE YEAR(a.activity_date) >=2019
	AND  a.contact_id NOT IN
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
		SELECT contact_id FROM mp_contacts (NOLOCK) WHERE isnull(IsTestAccount,0)= 1
	)
)
SELECT 
	 b.first_name +' '+ b.last_name AS Buyer
	, c.name AS BuyerAccount
	, a.Activity AS Activity
	, a.ActivityDate 
FROM 
(
	SELECT * FROM BuyerLoginActivity 
	UNION ALL
	SELECT * FROM BuyerOtherActivity 
) a
JOIN mp_contacts	b (NOLOCK) on a.contact_id = b.contact_id  and isnull(b.IsTestAccount,0)= 0
JOIN mp_companies	c (NOLOCK) on b.company_id = c.company_id
WHERE 
(
	(b.first_name +' '+ b.last_name) <> '' 
	AND (b.first_name +' '+ b.last_name) <> ' '
	AND (b.first_name +' '+ b.last_name) IS NOT NULL
)
