/*
	EXEC [proc_get_ManufacturerContacts]
	@ContactId=1337828
	,@IsBuyer =0 
	,@IsBlacklisted = 0
	,@PageNo	= 1
	,@PageSize  = 25
*/
    
CREATE PROCEDURE [dbo].[proc_get_ManufacturerContacts]  
 @ContactId INT,  
 @IsBuyer bit,  
 @IsBlacklisted bit null
 ,@PageNo	INT = 1
 ,@PageSize	INT = 25 
AS  
BEGIN  
  if @IsBlacklisted is null or @IsBlacklisted = ''  
   set @IsBlacklisted = 0  

  
  DROP TABLE IF EXISTS #ManufacturerContacts  
  
  SELECT   
    ROW_NUMBER() OVER(PARTITION BY bookdetails.company_id ORDER BY bookdetails.company_id) RN  
    ,book.contact_id As Buyer  
    ,book.book_id,book.bk_type  
    ,bookdetails.company_id AS CompanyId  
    ,comp.name AS CompanyName   
    ,cont.contact_id AS FollowContactId  
    , starrating.no_of_stars AS NoOfStars  
    , addr.address1  
    , addr.address2  
    , addr.address3  
    , addr.address4  
    , addr.address5  
    , addr.country_id AS CountryId  
    ,mstregion.REGION_NAME AS RegionName  
    ,mstcountry.country_name AS CountryName  
    ,IIF(filetype.filetype_id=6,spefile.FILE_NAME, NULL) AS CompanyLogo   
    ,book.book_id AS BookId  
    ,book.bk_name AS BookTypeName  
  INTO #ManufacturerContacts  
  FROM mp_books book  
  LEFT JOIN mp_book_details bookdetails ON book.book_id=bookdetails.book_id  
  LEFT JOIN mp_companies comp ON bookdetails.company_id=comp.company_id  
  LEFT JOIN -- for mailing address using supplier contact id   
  (  
   select a.* from mp_contacts a   
   join  
   (  
    select company_id , min(contact_id) contact_id from mp_contacts    
    where is_buyer = ( CASE WHEN @IsBuyer=1 THEN 0 ELSE 1 END )  and is_admin = 1   
      
    group by company_id  
   ) b on a.company_id = b.company_id and a.contact_id = b.contact_id  
     
  ) as cont ON bookdetails.company_id=cont.company_id   

  LEFT JOIN mp_addresses addr on cont.address_id=addr.address_id  
  LEFT JOIN mp_mst_country mstcountry ON addr.country_id=mstcountry.country_id  
  LEFT JOIN mp_mst_region mstregion ON addr.region_id=mstregion.region_id  
  LEFT JOIN mp_star_rating starrating ON starrating.company_id=comp.company_id  
  LEFT JOIN mp_special_files spefile ON bookdetails.company_id=spefile.COMP_ID and cont.contact_id=spefile.CONT_ID and FILETYPE_ID = 6  
  LEFT JOIN mp_mst_filetype filetype ON(spefile.FILETYPE_ID = filetype.filetype_id)  
  WHERE book.bk_name = case when @IsBlacklisted =  0 then 'Buyer Hotlist' else 'Buyer Blacklist' end   
  and book.contact_id=  @ContactId  
  AND cont.is_buyer=( CASE WHEN @IsBuyer=1 THEN 0 ELSE 1 END )  
        --and cont.company_id not in (select company_id from @blacklisted_contacts)  
  
  SELECT * , COUNT(*) OVER ( PARTITION BY Buyer )  TotalRec 
  FROM #ManufacturerContacts 
  WHERE RN = 1  
  ORDER BY BookId DESC 
  OFFSET @PageSize * (@PageNo - 1) ROWS
  FETCH NEXT @PageSize ROWS ONLY
 

  DROP TABLE IF EXISTS #ManufacturerContacts  
    
END
