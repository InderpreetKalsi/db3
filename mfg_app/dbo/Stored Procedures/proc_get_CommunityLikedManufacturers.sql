/*
DECLARE @RC INT  
exec [proc_get_CommunityLikedManufacturers] 
	@ContactId=1337828
	,@PageNo	= 1
	,@PageSize  = 25
*/
    
CREATE PROCEDURE [dbo].[proc_get_CommunityLikedManufacturers]  
(
 @ContactId INT
 ,@PageNo	INT = 1
 ,@PageSize	INT = 25
)
AS  
BEGIN  
  
		SET NOCOUNT ON
		/* M2-4033 Buyer - New Liked Manufacturers list - DB */

		SELECT * , COUNT(*) OVER ( PARTITION BY Buyer )  TotalRec FROM 
		(
			SELECT   
				ROW_NUMBER() OVER(PARTITION BY b.company_id ORDER BY b.company_id, lead_date DESC) RN 
				, @ContactId		AS Buyer
				, 0 AS book_id
				, 0 AS bk_type  
				, b.company_id	AS CompanyId  
				, comp.name		AS CompanyName   
				, c.contact_id	AS FollowContactId  
				, starrating.no_of_stars AS NoOfStars  
				, addr.address1  
				, addr.address2  
				, addr.address3  
				, addr.address4  
				, addr.address5  
				, addr.country_id AS CountryId  
				, mstregion.REGION_NAME AS RegionName  
				, mstcountry.country_name AS CountryName  
				, IIF(filetype.filetype_id=6,spefile.FILE_NAME, NULL) AS CompanyLogo   
				, 0 AS BookId  
				, '' AS BookTypeName  
				, b.lead_id AS LeadId
				, email.Email 
				, lead_date AS LeadDate
		  FROM mp_mst_lead_source		a (NOLOCK)
		  INNER JOIN mp_lead			b (NOLOCK) 				ON b.lead_source_id = a.lead_source_id 
		  LEFT JOIN mp_companies		comp (NOLOCK)			ON b.company_id=comp.company_id  
		  LEFT JOIN 
		  (
				SELECT 
					company_id , contact_id , address_id , [user_id]
					, ROW_NUMBER() OVER(PARTITION BY company_id ORDER BY company_id , is_admin DESC, contact_id ) rn 
				FROM mp_contacts		(NOLOCK) 
				WHERE IsTestAccount = 0
		  ) c ON c.company_id = comp.company_id  and c.rn=1
		  LEFT JOIN mp_addresses		addr (NOLOCK)			ON c.address_id=addr.address_id  
		  LEFT JOIN mp_mst_country		mstcountry (NOLOCK)		ON addr.country_id=mstcountry.country_id  
		  LEFT JOIN mp_mst_region		mstregion (NOLOCK)		ON addr.region_id=mstregion.region_id  
		  LEFT JOIN mp_star_rating		starrating (NOLOCK)		ON starrating.company_id=comp.company_id  
		  LEFT JOIN mp_special_files	spefile (NOLOCK)		ON b.company_id=spefile.COMP_ID and c.contact_id=spefile.CONT_ID and FILETYPE_ID = 6  
		  LEFT JOIN mp_mst_filetype		filetype (NOLOCK)		ON(spefile.FILETYPE_ID = filetype.filetype_id)  
		  LEFT JOIN aspnetusers email (NOLOCK) ON  c.[user_id] = email.id
		  WHERE		b.lead_from_contact = @ContactId   
		  AND		a.lead_source_id = '17' AND b.status_id = 1
	  ) a
	  WHERE A.RN = 1
	  ORDER BY LeadDate DESC
	  OFFSET @PageSize * (@PageNo - 1) ROWS
	  FETCH NEXT @PageSize ROWS ONLY

END
