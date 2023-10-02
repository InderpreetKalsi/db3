CREATE PROCEDURE [dbo].[proc_get_SupplierDetailListNew] 
  @PageSize INT,
  @PageNumber INT   
AS


-- =============================================
-- Create date: 03 Oct, 2018
-- Description:	Get the list of supplier details 
-- Modification:
-- Example: [proc_get_SupplierDetailListNew] 1,2 
-- =================================================================
--Version No – Change Date – Modified By      – CR No – Note
-- =================================================================

BEGIN	 
	DECLARE @totalrow INT;
	SET @totalrow = (SELECT COUNT(*) FROM mp_contacts where mp_contacts.Is_Buyer = 0 ) 	 
	SELECT @totalrow AS totalrow;
	Select  mp_companies.name AS ManufactureName
			, COALESCE(mp_nps_rating.nps_score,0) AS NetPramoterScore
			, mp_addresses.address4 AS City
			, mp_mst_region.REGION_NAME AS [State]
			, mp_mst_country.country_name AS Country
			, companyLogoFile.FILE_NAME AS companyLogo 
			, ProfilePictureFile.FILE_NAME AS ProfilePicture 
			, mp_companies.company_Id AS CompanyId
			, mp_contacts.Contact_Id AS ContactId
			--, (SELECT COUNT(*) FROM mp_contacts where mp_contacts.Is_Buyer = 0 ) AS totalrow						 	 	 
	FROM 
			mp_contacts 
			JOIN mp_companies ON mp_contacts.company_Id = mp_companies.company_Id
			--LEFT JOIN mp_nps_rating ON mp_contacts.contact_Id = mp_nps_rating.contact_id -- jan 10, 2019
			LEFT JOIN mp_nps_rating  on mp_nps_rating.company_id = mp_contacts.company_Id 
			LEFT JOIN mp_addresses ON mp_contacts.Address_Id = mp_addresses.address_Id
			LEFT JOIN mp_mst_region ON mp_addresses.region_id = mp_mst_region.REGION_ID
			LEFT JOIN mp_mst_country ON mp_mst_region.country_Id = mp_mst_country.country_id
			LEFT JOIN mp_special_files AS companyLogoFile ON mp_contacts.contact_Id =  companyLogoFile.CONT_ID AND companyLogoFile.FILETYPE_ID = 6
			LEFT JOIN mp_special_files AS ProfilePictureFile ON mp_contacts.contact_Id =  ProfilePictureFile.CONT_ID AND ProfilePictureFile.FILETYPE_ID = 17		 
	where mp_contacts.Is_Buyer = 0 
	ORDER BY mp_companies.name  
	OFFSET @PageSize * (@PageNumber - 1) ROWS
    FETCH NEXT @PageSize ROWS ONLY	 

	
END
