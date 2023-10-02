
CREATE VIEW [dbo].[vw_rfq_getRegisteredManufacturer]
AS 
SELECT 
	distinct mcp.company_id
	, mcp.Name as company
	, mmc.territory_classification_id
	, mrs.is_registered 
FROM dbo.mp_contacts mc 
JOIN dbo.mp_companies mcp on mc.company_id = mcp.company_id
JOIN dbo.mp_addresses ma on ma.address_id = mc.address_id
JOIN dbo.mp_mst_country mmc on ma.country_id = mmc.country_id
JOIN dbo.mp_registered_supplier mrs on mrs.company_id = mc.company_id
AND mc.is_buyer = 0
AND mc.is_active = 1
AND mmc.territory_classification_id is not null
