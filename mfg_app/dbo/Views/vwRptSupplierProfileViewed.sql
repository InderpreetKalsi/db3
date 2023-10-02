



-- SELECT * FROM [vwRptSupplierProfileViewed] ORDER BY ProfileViewedDate DESC
CREATE VIEW [dbo].[vwRptSupplierProfileViewed]
AS
SELECT 
	d.name AS SupplierCompany
	,e.territory_classification_name AS [Manufacturing Location]
	,CONVERT (DATE,lead_date) AS ProfileViewedDate
	,DATEDIFF(DAY,lead_date,GETUTCDATE()) AS NoOfDaysLastViewed
	,(CASE WHEN b.contact_id = 0 THEN a.ip_address + ' (IP address)' ELSE (b.first_name +' '+b.last_name) + ' (' +c.name+')' END)  AS ProfileViewedBy
	--,a.lead_from_contact 
	, (CASE WHEN b.contact_id = 0 THEN a.ip_address  ELSE '' END)  AS IPAddress
	, (CASE WHEN b.contact_id = 0 THEN ''  ELSE (b.first_name +' '+b.last_name) + ' (' +c.name+')' END)  BuyerInfo
	,COUNT(a.company_id) AS NoOfTimesViewed
FROM mp_lead (NOLOCK) a
JOIN mp_contacts (NOLOCK) b ON a.lead_from_contact = b.contact_id  and IsTestAccount= 0
JOIN mp_companies (NOLOCK) c ON b.company_id = c.company_id
JOIN mp_companies (NOLOCK) d ON a.company_id = d.company_id
LEFT JOIN mp_mst_territory_classification (NOLOCK) e ON d.manufacturing_location_id  = e.territory_classification_id
WHERE lead_source_id in (1,11) AND a.lead_from_contact <> 1336138 and b.IsTestAccount = 0 
GROUP BY 
	d.name 
	,e.territory_classification_name 
	,CONVERT (DATE,lead_date) 
	,(CASE WHEN b.contact_id = 0  THEN a.ip_address + ' (IP address)' ELSE (b.first_name +' '+b.last_name) + ' (' +c.name+')' END) 
	,DATEDIFF(DAY,lead_date,GETUTCDATE()) 
	,(CASE WHEN b.contact_id = 0  THEN a.ip_address  ELSE '' END)
	,(CASE WHEN b.contact_id = 0  THEN ''  ELSE (b.first_name +' '+b.last_name) + ' (' +c.name+')' END)
