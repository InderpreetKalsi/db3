/*

SELECT * FROM mp_Companies WHERE COMPANY_ID in ( 1720471 , 836295 )
SELECT TOP 100 * FROM vwRptByMonthSupplier (NOLOCK) WHERE TYPE = '2. Free Manufacturers'  AND SUPPLIERID = 836295  ORDER BY SupplierId
SELECT TOP 100 * FROM vwRptByMonthSupplier (NOLOCK) WHERE TYPE = '3. Paid Manufacturers' AND SUPPLIERID = 1718708 ORDER BY SupplierId
*/
CREATE VIEW [dbo].[vwRptByMonthSupplier]
AS
WITH Suppliers AS
(
	SELECT 
		a.company_id AS SupplierId
		,CreatedDate
		,e.YearCreated
		,e.MonthCreated
		,e.Type
		--,COUNT(a.company_id) OVER (PARTITION BY YearCreated , MonthCreated ,e.Type ORDER BY  YearCreated , MonthCreated ,e.Type ) AS TotalCount
		,a.Manufacturing_location_id [LocationId]
	FROM mp_companies a (NOLOCK)
	JOIN
	(
		SELECT DISTINCT
			a.company_id AS SupplierCompanyId
			,'1. New Registrants' AS Type
			,CONVERT(DATE,a.created_date) CreatedDate
			,YEAR(a.created_date) YearCreated
			,MONTH(a.created_date) MonthCreated
		FROM mp_companies		a	(NOLOCK)
		JOIN mp_contacts		b	(NOLOCK) ON a.company_id = b.company_id AND b.is_buyer = 0  AND a.company_id <> 0 and isnull(b.IsTestAccount,0)= 0
		WHERE YEAR(a.created_date) >= 2019 --AND MONTH(a.created_date) IN (1,2)
		UNION
		SELECT DISTINCT
			a.company_id AS SupplierCompanyId
			,'2. Free Manufacturers' AS Type
			,CONVERT(DATE,a.created_date) CreatedDate
			,YEAR(a.created_date) YearCreated
			,MONTH(a.created_date) MonthCreated
		FROM mp_companies		a	(NOLOCK)
		JOIN mp_contacts		b	(NOLOCK) ON a.company_id = b.company_id AND b.is_buyer = 0  AND a.company_id <> 0 and isnull(b.IsTestAccount,0)= 0
		LEFT JOIN   
		(
			SELECT visionacctid  
			,(CASE 
					WHEN account_status IN ('Active','Gold')	THEN 'Gold' --1
					WHEN account_status in('Free','Basic')		THEN 'Free' --0
					WHEN account_status = 'Silver'				THEN 'Silver'
					WHEN account_status = 'Platinum'			THEN 'Platinum'
					ELSE  'Free' 
			  END) account_status 
			FROM zoho..zoho_company_account WHERE synctype = 2  and account_status IN ('Basic','Free','Gold','Platinum','Silver') AND Account_type_id = 3
			UNION 
			SELECT company_id , CASE WHEN account_type = 84 THEN 'Silver' WHEN account_type = 85 THEN 'Gold'  WHEN account_type = 86 THEN 'Platinum' END FROM mp_registered_supplier
		) g ON  a.company_id = g.visionacctid
		WHERE YEAR(a.created_date) >= 2019
		AND ISNULL(g.account_status,'Free') = 'Free'
		UNION
		SELECT DISTINCT
			a.company_id AS SupplierCompanyId
			,'3. Paid Manufacturers' AS Type
			,CONVERT(DATE,a.created_date) CreatedDate
			,YEAR(a.created_date) YearCreated
			,MONTH(a.created_date) MonthCreated
		FROM mp_companies		a	(NOLOCK)
		JOIN mp_contacts		b	(NOLOCK) ON a.company_id = b.company_id AND b.is_buyer = 0  AND a.company_id <> 0 and isnull(b.IsTestAccount,0)= 0
		LEFT JOIN   
		(
			SELECT visionacctid  
			,(CASE 
					WHEN account_status IN ('Active','Gold')	THEN 'Gold' --1
					WHEN account_status in('Free','Basic')		THEN 'Free' --0
					WHEN account_status = 'Silver'				THEN 'Silver'
					WHEN account_status = 'Platinum'			THEN 'Platinum'
					ELSE  'Free' 
			  END) account_status 
			FROM zoho..zoho_company_account WHERE synctype = 2  and account_status IN ('Basic','Free','Gold','Platinum','Silver') AND Account_type_id = 3
			UNION 
			SELECT company_id , CASE WHEN account_type = 84 THEN 'Silver' WHEN account_type = 85 THEN 'Gold'  WHEN account_type = 86 THEN 'Platinum' END FROM mp_registered_supplier
		) g ON  a.company_id = g.visionacctid
		WHERE YEAR(a.created_date) >= 2019
		AND ISNULL(g.account_status,'Free') <> 'Free'
	) e ON a.company_id = e.SupplierCompanyId
) 
SELECT 
	SupplierId
	,CASE 
		WHEN TYPE = '3. Paid Manufacturers' AND CapabilityType = 'Quoting Capability' THEN ISNULL(d.discipline_name,'- No Capabiities') 
		WHEN TYPE <> '3. Paid Manufacturers' THEN ISNULL(d.discipline_name,'- No Capabiities') 
		ELSE '' 
	 END AS [Level 0]
	,CASE 
		WHEN TYPE = '3. Paid Manufacturers' AND CapabilityType = 'Quoting Capability' THEN ISNULL(c.discipline_name,'- No Capabiities') 
		WHEN TYPE <> '3. Paid Manufacturers' THEN ISNULL(c.discipline_name,'- No Capabiities') 
		ELSE '' 
	 END AS [Level 1]
	,CreatedDate
	,YearCreated
	,MonthCreated
	,Type
	,ISNULL(e.territory_classification_name,'No Location') AS [Location]
	,SUBSTRING(CONVERT(VARCHAR(5),CONVERT(VARCHAR(5),DATENAME(m,a.CreatedDate))), 1,3) +'-'+ SUBSTRING(CONVERT(VARCHAR(5),YEAR(a.CreatedDate)),3,2)    AS CreatedMonthYear 
	--,TotalCount
FROM Suppliers a
LEFT JOIN
(
	SELECT company_id, part_category_id , 'Profile Capability' AS CapabilityType FROM mp_company_processes  (NOLOCK) a  
	/* M2-2739 */
	UNION
	SELECT company_id,part_category_id, 'Quoting Capability' AS CapabilityType FROM  mp_gateway_subscription_company_processes (nolock) 
	/**/
) b ON a.SupplierId = b.company_id 
LEFT JOIN mp_mst_part_category c (NOLOCK) ON b.part_category_id = c.part_category_id
LEFT JOIN mp_mst_part_category d (NOLOCK) ON d.part_category_id = c.parent_part_category_id
LEFT JOIN mp_mst_territory_classification (NOLOCK) e ON a.[LocationId] = e.territory_classification_id
WHERE a.SupplierId NOT IN
(
	SELECT ISNULL(company_id,0) FROM mp_contacts (NOLOCK)
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
	SELECT company_id FROM mp_contacts (NOLOCK)
	WHERE  isnull(IsTestAccount,0)= 1
)
AND 
(
CASE 
		WHEN TYPE = '3. Paid Manufacturers' AND CapabilityType = 'Quoting Capability' THEN ISNULL(d.discipline_name,'- No Capabiities') 
		WHEN TYPE <> '3. Paid Manufacturers' THEN ISNULL(d.discipline_name,'- No Capabiities') 
		ELSE '' 
END
) <> ''
