CREATE  VIEW [dbo].[vw_get_company_territory_and_Capabilities]
AS
	SELECT mp_companies.company_id
		, mp_contacts.contact_id
		, mp_mst_territory_classification.territory_classification_id 
		, mp_company_processes.part_category_id
	FROM 
		mp_companies (nolock) 
		JOIN mp_contacts  (nolock)ON mp_companies.company_id = mp_contacts.company_id
		LEFT JOIN mp_addresses  (nolock)ON mp_addresses.address_id = mp_contacts.address_id
		LEFT JOIN mp_mst_country  (nolock)ON mp_mst_country.country_id = mp_addresses.country_id
		LEFT JOIN mp_mst_territory_classification  (nolock)ON mp_mst_territory_classification.territory_classification_id = mp_mst_country.territory_classification_id
		LEFT JOIN mp_company_processes  (nolock)ON mp_companies.company_id = mp_company_processes.company_id
