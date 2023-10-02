
-- =============================================
-- Author:		dp-AM. N.
-- Create date: 04/07/2019
-- Description:	Stored procedure to Get MQS Contact List
-- Modification:
-- Example: [proc_get_MQSContactList]  @SupplierCompanyId = 1768056
-- =================================================================
--Version No – Change Date – Modified By      – CR No – Note
-- =================================================================

CREATE PROCEDURE [dbo].[proc_get_MQSContactList]	 
	 @PageNumber INT = 1,
	 @PageSize INT = 10000,
	 @SupplierCompanyId INT,
	 @CountryId INT = 0,
	 @StateId INT = 0,
	 @SearchText VARCHAR(50) = Null,
	 @IsOrderByDesc BIT= 0 
	 
AS
BEGIN

	  SELECT  *,TotalCount = count(*) over() FROM(  		   
			SELECT mqc.mqs_contact_id AS mqs_contact_id,
			mqc.company AS Company, 
			mqc.first_name As FirstName, 
			mqc.last_name AS LastName, 
			mqc.email AS Email, 
			mqc.phone AS Phone, 
			mqc.address +','+ mqc.city + ','+ mp_mst_region.REGION_NAME + ',' + mp_mst_country.iso_code  + ',' + mqc.zip_code  AS Address,
			mqc.created_date						
			FROM mp_mqs_contacts mqc
			join mp_contacts ON mqc.supplier_id = mp_contacts.contact_id 
			join mp_companies ON mp_contacts.company_id = mp_companies.company_id 
			JOIN mp_mst_region  (nolock) ON mqc.state_id = mp_mst_region.REGION_ID
			JOIN mp_mst_country  (nolock) ON mqc.country_id  = mp_mst_country.country_id			
			where mp_companies.is_mqs_enable = 1
			AND mp_companies.company_id = @SupplierCompanyId 
			AND mqc.is_active = 1
			AND (mqc.country_id = @CountryId OR @CountryId = 0 )
			AND (mqc.state_id = @StateId OR @StateId = 0)  	
			AND (mqc.company Like '%'+ @SearchText +'%' OR 
				 mqc.first_name Like '%'+ @SearchText +'%' OR
				 mqc.last_name Like '%'+ @SearchText +'%' OR
				 mqc.email Like '%'+ @SearchText +'%' OR
				 mqc.phone Like '%'+ @SearchText +'%' OR
				 mqc.address Like '%'+ @SearchText +'%' OR 
				 @SearchText IS NULL )  				 
		) AS AllContacts	
		order by 
		case  when @IsOrderByDesc =  1 then created_date end desc   
		,case  when @IsOrderByDesc =  0 then created_date end     		
				 
		offset @PageSize * (@PageNumber - 1) rows
		fetch next @PageSize rows only	 
 
	
END
