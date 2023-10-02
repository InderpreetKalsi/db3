
CREATE PROCEDURE [dbo].[proc_get_VisionContacts]	 
 @ContactType INT
AS
BEGIN
 ----------- If Buyer ----------------------------------
	IF(@ContactType = 1)
	BEGIN

		 SELECT AspNetUsers.Id AS UserId
			   , COALESCE( mp_special_files.FILE_NAME , '') AS Minilogo
			   , COALESCE( mp_companies.name,'' ) AS CompanyName
			   , COALESCE( AspNetUsers.FirstName,'' ) AS FirstName
			   , COALESCE( AspNetUsers.LastName,'' ) AS LastName
			   , COALESCE( AspNetUsers.Email,'' ) AS EmailAddress
			   , COALESCE( mp_communication_details.communication_value,'' ) AS PhoneNumber		
			   , mp_contacts.Is_Validated_Buyer AS IsValidated		    
			   , mp_star_rating.no_of_stars AS NoOfStars				   
			   , mp_contacts.contact_Id	AS ContactId	
			   --, mp_contacts.company_Id	AS CompanyId	
			   --, AspNetUsers.last_ogin	AS LastLogin
			   , mp_contacts.created_on AS CreatedOn  				
		FROM AspNetUsers
			JOIN mp_contacts ON mp_contacts.User_Id = AspNetUsers.Id	
			--LEFT JOIN mp_nps_rating ON mp_nps_rating.contact_Id = mp_contacts.contact_Id  -- Jan 10 2019	
			LEFT JOIN mp_star_rating ON mp_star_rating.company_id = mp_contacts.company_id	 
			LEFT JOIN mp_companies ON mp_companies.company_Id = mp_contacts.company_id
			LEFT JOIN mp_special_files ON mp_special_files.cont_id = mp_contacts.contact_id AND mp_special_files.FILETYPE_ID = 6
			LEFT JOIN mp_communication_details ON mp_communication_details.contact_id =  mp_contacts.contact_id AND mp_communication_details.communication_type_id = 1
		WHERE 			 			  	 
			 mp_contacts.Is_Buyer = 1

	END
	----------- If Supplier ----------------------------------
	ELSE IF(@ContactType = 2)
	BEGIN
		
		SELECT TOP(50) AspNetUsers.Id AS UserId
			   ,COALESCE( mp_special_files.FILE_NAME , '') AS FileName
			   ,COALESCE( mp_companies.name,'' ) AS CompanyName
			   ,COALESCE( AspNetUsers.FirstName,'' ) AS FirstName
			   ,COALESCE( AspNetUsers.LastName,'' ) AS LastName
			   ,COALESCE( AspNetUsers.Email,'' ) AS Email
			   ,COALESCE( mp_communication_details.communication_value,'' ) AS PhoneNo			    
			   , mp_star_rating.no_of_stars AS NoOfStars		   
			   ,mp_contacts.contact_Id	AS ContactId	
			   ,mp_contacts.company_Id	AS CompanyId	
			   ,AspNetUsers.last_ogin	AS LastLogin
			   ,mp_contacts.created_on AS CreatedOn  				
		FROM AspNetUsers
			LEFT JOIN mp_contacts ON mp_contacts.User_Id = AspNetUsers.Id	
			--LEFT JOIN mp_nps_rating ON mp_nps_rating.contact_Id = mp_contacts.contact_Id  -- Jan 10 2019	
			LEFT JOIN mp_star_rating ON mp_star_rating.company_id = mp_contacts.company_id	
			LEFT JOIN mp_companies ON mp_companies.company_Id = mp_contacts.company_id
			LEFT JOIN mp_special_files  ON mp_special_files.cont_id = mp_contacts.contact_id AND mp_special_files.FILETYPE_ID = 6
			LEFT JOIN mp_communication_details ON mp_communication_details.contact_id =  mp_contacts.contact_id AND mp_communication_details.communication_type_id = 1
		WHERE 			 
			mp_communication_details.communication_type_id = 1 	 
			AND mp_contacts.Is_Buyer = 0

	END
	
     
END
