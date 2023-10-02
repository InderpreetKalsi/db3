
--ALTER TABLE [mp_spotlight_supplier] ADD [location_id]          INT      NULL	;
--GO



CREATE PROCEDURE [dbo].[proc_get_SpotLightManufacturersList]	 
	 @PageNumber INT = 1,
	 @PageSize INT = 1000,
	 @ProcessId INT = NULL,
	 @LocationId INT = 0,
	 @SearchText VARCHAR(50) = Null
AS
BEGIN

	SET NOCOUNT ON
	-- =============================================
	-- Author:		dp-AM. N.
	-- Create date: 21/06/2019
	-- Description:	Stored procedure to Get spotlight manufacturers
	-- Modification:
	-- Example: [proc_get_SpotLightManufacturersList] @ProcessId = 101044
	-- =================================================================
	--Version No – Change Date – Modified By      – CR No – Note
	-- =================================================================



	  SELECT  *,TotalCount = count(*) over() FROM(  
		  
		  SELECT DISTINCT mp_companies.company_id AS CompanyId
			, (select top 1 file_name from mp_special_files where  mp_companies.company_id = mp_special_files.comp_id and filetype_id = 6 ) AS CompanyLogo
			, COALESCE( mp_companies.name,'') AS CompanyName
			, COALESCE( mp_contacts.first_name,'' ) AS FirstName
			, COALESCE( mp_contacts.last_name,'' ) AS LastName			
			, mp_mst_territory_classification.territory_classification_name AS ManufacturingLocation  					
			, COALESCE( mp_system_parameters.value , 'Basic' ) AS ContractType
			, mp_spotlight_supplier.turnon_date AS TurnonDate
			, mp_mst_part_category.discipline_name AS PartCategory
			, mp_star_rating.no_of_stars AS NoOfStars
			, mp_contacts.User_Id AS UserId
			, mp_contacts.contact_id AS ContactId
			, mp_spotlight_supplier.expiry_date as ExpiryDate
			, mp_spotlight_supplier.spotlight_id as SpotlightId
			/* M2-4076 Vision - Add Spotlight to the supplier profile drawer - DB */
			, mp_spotlight_supplier.RankPosition AS RankPosition
			/* As per requirement from client discussed in 8 Sept's 2021 client call*/
			, AspNetUsers.Email AS Email
			/*  */
			/* M2-4115 Spotlight - Add region selection - DB */
			, mp_spotlight_supplier.location_id RegionId
			/*  */
			FROM (
					SELECT a.first_name, a.last_name,a.contact_id,a.company_id , a.[user_id] , ROW_NUMBER () OVER (PARTITION BY a.company_id ORDER BY a.company_id , contact_id ASC ) Rn
					FROM mp_contacts (NOLOCK) a
					JOIN mp_companies (NOLOCK) b ON a.company_id = b.company_id
					WHERE a.is_buyer = 0 AND a.is_admin = 1 AND b.company_id <> 0
				) mp_contacts --ON AspNetUsers.id = mp_contacts.user_id 				  				
				JOIN mp_companies ON  mp_contacts.company_id = mp_companies.company_Id 	AND mp_contacts.Rn = 1  			
				LEFT JOIN mp_mst_territory_classification ON mp_companies.Manufacturing_location_id = mp_mst_territory_classification.territory_classification_id
				/* M2-4076 Vision - Add Spotlight to the supplier profile drawer - DB */
				JOIN mp_Spotlight_Supplier ON mp_contacts.company_id = mp_Spotlight_Supplier.CompanyId
				/*  */
				/* As per requirement from client discussed in 8 Sept's 2021 client call*/
				JOIN AspNetUsers ON AspNetUsers.id = mp_contacts.user_id 
				/* */
				LEFT JOIN mp_mst_part_category ON mp_spotlight_supplier.part_category_id = mp_mst_part_category.part_category_id	
				LEFT JOIN mp_registered_supplier ON mp_companies.company_Id = mp_registered_supplier.company_Id		
				LEFT JOIN mp_star_rating ON mp_companies.company_Id = mp_star_rating.company_Id						
				LEFT JOIN  mp_system_parameters ON mp_registered_supplier.account_type = mp_system_parameters.Id	
				WHERE  mp_companies.name IS NOT NULL  	
				/* M2-4115 Spotlight - Add region selection - DB */
				AND (mp_spotlight_supplier.location_id =  @LocationId OR @LocationId = 0)
				/*  */
				AND (mp_companies.name Like '%'+@SearchText+'%' OR @SearchText IS NULL )
				AND  (mp_spotlight_supplier.part_category_id = @ProcessId  OR @ProcessId IS NULL)
				AND mp_spotlight_supplier.is_spotlight_turn_on = 1

		) AS AllContacts	
		order by RankPosition
		
		offset @PageSize * (@PageNumber - 1) rows
		fetch next @PageSize rows only	
END
