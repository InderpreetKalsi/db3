
CREATE PROCEDURE [dbo].[proc_get_individual]	 
	 @ContactId INT,
	 @SearchText VARCHAR(50) = Null
AS
BEGIN
	
	DECLARE @Company_Id INT ;
	SELECT  @Company_Id = company_id from mp_contacts where contact_id  = @ContactId

	declare @blacklisted_Companies table (company_id int)	

    insert into @blacklisted_Companies (company_id)
    select distinct a.company_id from mp_book_details  a 
    join mp_books b on a.book_id = b.book_id      
    where bk_type= 5 and b.contact_id = @ContactId
	union  
	select distinct d.company_id from mp_book_details  a 
    join mp_books b on a.book_id = b.book_id   
	join mp_contacts d on b.contact_Id = d.contact_Id AND  a.company_id = @Company_Id
    where bk_type= 5  
	 

	--SELECT * FROm @blacklisted_Companies	 
	
	SELECT DISTINCT TOP(30)
	mp_companies.company_id AS CompanyId, 
	mp_companies.name AS Name
	FROM mp_contacts 
	JOIN mp_companies ON mp_contacts.company_id = mp_companies.company_id
	JOIN mp_registered_supplier ON  mp_companies.company_id = mp_registered_supplier.company_id AND mp_registered_supplier.is_registered = 1
	WHERE  mp_contacts.Is_Buyer = 0 
	AND  mp_contacts.Is_Active = 1
	AND (						 
			(mp_companies.name Like '%'+@SearchText+'%')		
			OR
			(@SearchText IS NULL)					 				
		)
	AND mp_companies.company_id not in  (select company_id from @blacklisted_Companies)
 
	
END
