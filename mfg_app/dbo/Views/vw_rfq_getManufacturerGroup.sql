

CREATE VIEW [dbo].[vw_rfq_getManufacturerGroup]
AS 
SELECT 
	distinct 
	--mcp.company_id, mcp.Name as company, mmc.territory_classification_id, 1 as is_registered 
	mb.book_id
	, mb.bk_name
	--, mmc.territory_classification_id
	, mc.contact_id as BuyerContact_id
FROM mp_contacts mc
JOIN mp_books mb on mc.contact_id = mb.contact_id 
--JOIN mp_addresses ma on ma.address_id = mc.address_id
--JOIN mp_mst_country mmc on ma.country_id = mmc.country_id
JOIN mp_book_details mbd on mbd.book_id  = mb.book_id
JOIN dbo.mp_registered_supplier mrs on mrs.company_id = mbd.company_id
AND mc.is_buyer = 1
AND mc.is_active = 1
AND mb.status_id = 2
--AND mmc.territory_classification_id is not null
