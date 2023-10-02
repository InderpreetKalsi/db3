
/*
EXEC proc_get_public_profile_url_list 'free'
EXEC proc_get_public_profile_url_list 'Paid'
*/
CREATE proc [dbo].[proc_get_public_profile_url_list]
(
	@supplier_type		varchar(100)

)
AS
BEGIN
    set nocount on

	if(@supplier_type = 'Paid')
		begin
			SELECT b.company_id AS CompanyId, b.name AS CompanyName,
			CASE 
				WHEN DB_NAME() = 'MP2020_DEV' THEN 'http://qa.mfg2020.com/#/Public/profile/'
				WHEN DB_NAME() = 'MP2020_UAT' THEN 'https://uatapp.mfg.com/#/Public/profile/'
				WHEN DB_NAME() = 'MP2020_PROD' THEN 'https://app.mfg.com/#/Public/profile/'
			END	+b.CompanyURL AS CompanyURL
			,d.territory_classification_name AS ManufacturingLocation
			FROM mp_contacts a (nolock)
			INNER JOIN mp_Companies b (nolock) on a.company_id=b.company_id
			INNER JOIN mp_registered_supplier c (nolock) ON(a.company_id = c.company_id)
			INNER JOIN mp_mst_territory_classification d (nolock) ON(b.manufacturing_location_id = d.territory_classification_id)
			WHERE a.is_admin = 1
				  AND a.is_buyer = 0
				  AND a.is_active = 1
				  AND c.is_registered = 1
				  AND b.company_id <> 0
			GROUP BY b.company_id, b.name,b.CompanyURL,d.territory_classification_name
			ORDER BY b.company_id
		end
	else
	    begin
			SELECT b.company_id AS CompanyId, b.name AS CompanyName,
			CASE 
				WHEN DB_NAME() = 'MP2020_DEV' THEN 'http://qa.mfg2020.com/#/Public/profile/'
				WHEN DB_NAME() = 'MP2020_UAT' THEN 'https://uatapp.mfg.com/#/Public/profile/'
				WHEN DB_NAME() = 'MP2020_PROD' THEN 'https://app.mfg.com/#/Public/profile/'
			END+b.CompanyURL AS CompanyURL
			,d.territory_classification_name AS ManufacturingLocation
			FROM mp_contacts a (nolock)
			INNER JOIN mp_Companies b (nolock) on a.company_id=b.company_id
			--INNER JOIN mp_registered_supplier c (nolock) ON(a.company_id <> c.company_id)
			INNER JOIN mp_mst_territory_classification d (nolock) ON(b.manufacturing_location_id = d.territory_classification_id)
			WHERE a.is_admin = 1
				  AND a.is_buyer = 0
				  AND a.is_active = 1
				  AND b.company_id NOT IN(SELECT company_id FROM mp_registered_supplier WHERE is_registered = 1)
				  AND b.company_id <> 0
			GROUP BY b.company_id, b.name,b.CompanyURL,d.territory_classification_name
			ORDER BY b.company_id
		end
END
