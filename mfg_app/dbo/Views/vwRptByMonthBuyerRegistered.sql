
-- SELECT * FROM vwRptByMonthBuyerRegistered where buyerid  =1276499
CREATE VIEW [dbo].[vwRptByMonthBuyerRegistered]
AS
SELECT 
	a.contact_id AS BuyerId
	,CONVERT(DATE,a.created_on) [Buyer Registered]
	,YEAR(a.created_on) [Year Registered]
	,MONTH(a.created_on) [Month Registered]
	,SUBSTRING(CONVERT(VARCHAR(5),CONVERT(VARCHAR(5),DATENAME(m,a.created_on))), 1,3) +'-'+ SUBSTRING(CONVERT(VARCHAR(5),YEAR(a.created_on)),3,2)    
	AS [Buyer Registered On]
	,c.country_name AS Country
	,CASE 
		WHEN
			(
				SELECT COUNT(1) 
				FROM mp_rfq (NOLOCK) a1
				JOIN mp_rfq_release_history (NOLOCK) b1 ON a1.rfq_id = b1.rfq_id AND a1.contact_id = a.contact_id
			) > 0 THEN 'Yes' 
		ELSE 'No'
	END AS RFQReleased
	,LoginYear
	,LoginMonth
	,SUBSTRING(CONVERT(VARCHAR(5),CONVERT(VARCHAR(5),DATENAME(m,LoginMonth))), 1,3) +'-'+ SUBSTRING(CONVERT(VARCHAR(5),LoginYear),3,2)    
	AS [Login On]
	,LoginCount
FROM mp_contacts (NOLOCK)  a
JOIN mp_addresses (NOLOCK)  b ON a.address_id = b.address_id and isnull(a.IsTestAccount,0)= 0
JOIN mp_mst_country (NOLOCK)  c ON b.country_id = c.country_id
LEFT JOIN 
(
		SELECT contact_id ,YEAR(login_datetime) LoginYear, MONTH (login_datetime) LoginMonth , COUNT(1) LoginCount 
		FROM mp_user_logindetail (NOLOCK) a1
		GROUP BY contact_id ,YEAR(login_datetime), MONTH (login_datetime) 
) d ON a.contact_id = d.contact_id
WHERE YEAR(a.created_on) >= 2019 
AND a.is_buyer = 1
--ORDER BY [Year Registered] , [Month Registered]
