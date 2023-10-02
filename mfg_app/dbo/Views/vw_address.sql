

CREATE view [dbo].[vw_address] as
	select 
		mp_addresses.address_Id
		, mp_addresses.address4 AS City		
		, mp_mst_region.REGION_ID AS RegionId 
		, case when ( mp_mst_region.REGION_ID = 0 ) then 'N/A' else mp_mst_region.REGION_NAME  end AS [State]
		, mp_mst_country.country_id AS CountryId
		, case when (mp_mst_country.country_id = 0 ) then 'N/A' else mp_mst_country.country_name  end AS country_name 
	from 
	mp_addresses (nolock)
	JOIN mp_mst_region  (nolock) ON mp_addresses.region_id = mp_mst_region.REGION_ID
	JOIN mp_mst_country  (nolock) ON mp_mst_region.country_Id = mp_mst_country.country_id



