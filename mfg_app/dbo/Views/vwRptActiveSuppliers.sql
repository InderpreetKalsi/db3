
/*

SELECT TOP 100 * FROM [vwRptActiveSuppliers] (NOLOCK) WHERE [Company] = 'Whitworth Tool'  ORDER BY Company
SELECT TOP 100 * FROM [vwRptActiveSuppliers] (NOLOCK) WHERE [Company] = 'DNA Precision Machine & Design, LLC' ORDER BY Company
*/
CREATE VIEW  [dbo].[vwRptActiveSuppliers]
AS

SELECT 
	a.name AS [Company]
	--,capabilitytype
	,a.CompanyURL 
	,CASE 
		WHEN g.paid_status IN ('Gold','Platinum') AND CapabilityType = 'Quoting Capability' THEN e.discipline_name
		WHEN g.paid_status NOT IN ('Gold','Platinum') THEN e.discipline_name
		ELSE '' 
	 END AS [Primary Category]
	,CASE 
		WHEN g.paid_status IN ('Gold','Platinum') AND CapabilityType = 'Quoting Capability' THEN d.discipline_name
		WHEN g.paid_status NOT IN ('Gold','Platinum') THEN d.discipline_name
		ELSE '' 
	 END AS [Secondary Category]
	--,e.discipline_name AS [Primary Category]
	--,d.discipline_name AS [Secondary Category]
	,f.territory_classification_name AS [MFG Region]
	,g.paid_status AS [Paid Status]
FROM mp_companies	a (NOLOCK)
JOIN mp_contacts	b (NOLOCK) ON a.company_id = b.company_id AND  b.is_buyer= 0 AND a.company_id <> 0 and a.is_active = 1 and isnull(b.IsTestAccount,0)= 0
JOIN 
(
	SELECT DISTINCT 'Profile Capability' as capabilitytype   ,company_id , part_category_id FROM mp_company_processes (NOLOCK)
	UNION
	SELECT DISTINCT 'Quoting Capability' as capabilitytype , company_id , part_category_id  FROM mp_gateway_subscription_company_processes (NOLOCK)
)	c  ON a.company_id = c.company_id
JOIN mp_mst_part_category d (NOLOCK) ON c.part_category_id = d.part_category_id
JOIN mp_mst_part_category e (NOLOCK) ON d.parent_part_category_id = e.part_category_id
JOIN mp_mst_territory_classification f (NOLOCK) ON a.manufacturing_location_id = f.territory_classification_id
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
) g ON a.company_id = g.company_id

WHERE c.part_category_id IN (SELECT part_category_id FROM mp_active_capabilities)
AND 
(
	CASE 
		WHEN g.paid_status IN ('Gold','Platinum') AND CapabilityType = 'Quoting Capability' THEN e.discipline_name
		WHEN g.paid_status NOT IN ('Gold','Platinum') THEN e.discipline_name
		ELSE '' 
	 END
) <> ''
