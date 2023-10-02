-- SELECT TOP 10 * FROM vwRptByMonthSupplierNewRegistrants
CREATE VIEW [dbo].[vwRptByMonthSupplierNewRegistrants]
AS
WITH NewRegisteredSuppliers AS
(
	SELECT DISTINCT
		'New Registrants' AS Type
		,YEAR(a.created_date) YearCreated
		,MONTH(a.created_date) MonthCreated
		,CONVERT(DATE,a.created_date) AS CreatedDate 
		,a.company_id AS SupplierCompany
		,d.CapabilityType
		,f.discipline_name AS [Level 0]
		,e.discipline_name AS [Level 1]
		,ISNULL(g.account_status,'Free') AS [Paid Status]
		,h.territory_classification_name AS [Location]
		,SUBSTRING(CONVERT(VARCHAR(5),CONVERT(VARCHAR(5),DATENAME(m,a.created_date))), 1,3) +'-'+ SUBSTRING(CONVERT(VARCHAR(5),YEAR(a.created_date)),3,2)    AS CreatedMonthYear 
	FROM mp_companies		a	(NOLOCK)
	JOIN mp_contacts		b	(NOLOCK) ON a.company_id = b.company_id AND b.is_buyer = 0  and isnull(b.IsTestAccount,0)= 0
	LEFT JOIN
	(
		SELECT company_id, part_category_id , 'Profile Capability' AS CapabilityType from mp_company_processes  (NOLOCK) a  
		/* M2-2739 */
		union
		select company_id,part_category_id, 'Quoting Capability' AS CapabilityType from  mp_gateway_subscription_company_processes (nolock) 
		/**/
	) d ON a.company_id = d.company_id
	JOIN mp_mst_part_category e (NOLOCK) ON d.part_category_id = e.part_category_id
	JOIN mp_mst_part_category f (NOLOCK) ON f.part_category_id = e.parent_part_category_id
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
	LEFT JOIN mp_mst_territory_classification (NOLOCK) h ON a.manufacturing_location_id = h.territory_classification_id
	WHERE 
	b.contact_id NOT IN
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
	) 

	AND YEAR(a.created_date) >= 2019
) 
SELECT * FROM NewRegisteredSuppliers
