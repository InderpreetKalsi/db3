
/*
exec proc_get_SupplierDetailList
 @ContactId  = 1345532
 ,@SearchText = 'test company'


*/
CREATE PROCEDURE [dbo].[proc_get_SupplierDetailList] 
	 @ContactId INT,
	 @PageNumber INT = 1,
	 @PageSize   INT = 25,
	 @SearchText VARCHAR(50) = Null,	
	 @CountryIds as tbltype_ListOfCountries readonly,
	 @ProcessIds as tbltype_ListOfProcesses readonly,
	 @CerificateCodes as tbltype_ListOfCertificateCodes readonly,
	 @IsFollowing BIT = 'false'	 
AS
-- =============================================
-- Create date: 03 Oct, 2018
-- Description:	Get the list of supplier details 
-- Modification: 

--DECLARE @Processids as tbltype_ListOfProcesses; 
--DECLARE @CountryIds as tbltype_ListOfCountries; 

--INSERT INTO @ProcessIds (Processid)Values(7448);
--INSERT INTO @ProcessIds (Processid)Values(7455) ; 
--SELECT * FROM @Processids

--EXEC [proc_get_SupplierDetailList] 1337733,1,20,'Supper, East 2nd Street, New York, NY, USA',@CountryIds,@ProcessIds 
-- Example: [proc_get_SupplierDetailList] 1335857,1,20,'delaplex11',NULL,@ProcessIds 
-- =================================================================
--Version No – Change Date – Modified By      – CR No – Note
-- =================================================================


BEGIN	
		
	set nocount on
		
	DECLARE @Company_Id INT ;
	SELECT  @Company_Id = company_id from mp_contacts where contact_id  = @ContactId

	DECLARE @ProcessIdCount INT;
	SELECT @ProcessIdCount = COUNT(*) FROM @ProcessIds; 				

	DECLARE @CertificateCodeCount INT;
	SELECT @CertificateCodeCount = COUNT(*) FROM @CerificateCodes; 	

	declare @sql_query nvarchar(max),
	@where_query nvarchar(max),
	@search_query nvarchar(max),
	@join_query nvarchar(max),
	@SQLString nvarchar(max)
  
 /* M2-2490 Supplier Profile - Automatically hide suppliers that don't meet minimum criteria - DB */
	drop table if exists #excludecompanies

	create table #excludecompanies
	(
	company_id		int ,
	islogo			int default 0,
	isheader		int default 0,
	isdescription	int default 0
	)

	insert into #excludecompanies (company_id, isdescription)
	select distinct a.company_id , (case when a.description = '' or a.description is null then 0 else 1 end) as isdescription
	from mp_companies (nolock) a
	join mp_contacts  (nolock) b on a.company_id = b.company_id 
		and is_buyer = 0 
		and isnull(b.istestaccount,0) = 0 
	where 
	not exists (select company_id from mp_registered_supplier where account_type in (84,85,86,313) and company_id = a.company_id) --M2-5133 added 313 account type
	and 
	a.company_id > 0
	/* M2-3251  Vision - Flag as a test account and hide the data from reporting - DB */
	union
	select distinct a.company_id , 0 as isdescription
	from mp_companies (nolock) a
	join mp_contacts  (nolock) b on a.company_id = b.company_id 
	where is_buyer = 0 and isnull(b.istestaccount,0) = 1 
	/**/
	
		
	-- logo update
	update a set a.islogo =1
	from #excludecompanies a
	join (select distinct comp_id from mp_special_files (nolock) where filetype_id = 6 and is_deleted = 0) b on a.company_id = b.comp_id 

	-- header update
	update a set a.isheader =1
	from #excludecompanies a
	join (select distinct comp_id from mp_special_files (nolock) where filetype_id = 8 and is_deleted = 0) b on a.company_id = b.comp_id 
	
/**/



	SET @SQLString = case when ( @ProcessIdCount = 1 ) then 'mp_spotlight_supplier.is_spotlight_turn_on' ELSE 'CAST(0 AS BIT)' END 
	

    set @join_query = 
	   case when ( @ProcessIdCount > 0) then ' join #ProcessId_Companies AS processCompanies on processCompanies.company_id = a.company_Id ' else '' end 	
	   + case when ( @CertificateCodeCount > 0) then ' join #CertificateCode_Companies AS CertificateCodeCompanies on CertificateCodeCompanies.company_id = a.company_Id' else '' end
	   + case when (@IsFollowing = 'true') then ' join #Followed_Companies AS FollowedCompanies on FollowedCompanies.company_id = a.company_Id ' else '' end 	

	set @search_query =  
		case when @SearchText IS Null then ' AND ((1 = 1)) ' else '' end 
		+ case when @SearchText Is NOT Null then ' AND (a.name Like ''%'+@SearchText+'%'')' else '' end	


	set @sql_query = 
		  ' 			     	    
	drop table if exists #tmp_supplier_company_contact

	declare @blacklisted_Companies table (company_id int)
    insert into @blacklisted_Companies (company_id)
    select distinct a.company_id from mp_book_details  a   (nolock)
    join mp_books b  (nolock) on a.book_id = b.book_id    
    where bk_type= 5 and b.Contact_Id = @ContactId1	  
	union  
	select distinct d.company_id from mp_book_details  a  (nolock)
    join mp_books b  (nolock) on a.book_id = b.book_id   
	join mp_contacts d  (nolock) on b.contact_Id = d.contact_Id 
    where bk_type= 5  AND a.company_Id = @Company_Id1

	 
    select distinct a.company_id 
	into #Followed_Companies
	from mp_book_details  a   (nolock)
    join mp_books b  (nolock) on a.book_id = b.book_id    
    where bk_type= 4 and b.Contact_Id = @ContactId1 
     

 
	SELECT Distinct company_id 
	into #ProcessId_Companies
	FROM mp_company_processes  (nolock) where Part_Category_id IN ( SELECT * FROM @ProcessIds1)  
	union 
	select  distinct b.company_id
	from mp_spotlight_supplier (nolock) a
	join mp_contacts b (nolock) on a.CompanyId = b.company_id
	where a.part_category_id in ( select * from @ProcessIds1)  

		 
	SELECT Distinct mp_company_certificates.company_id 
	into #CertificateCode_Companies
	FROM mp_company_certificates (nolock) 
	JOIN mp_certificates (nolock)  ON mp_company_certificates.certificates_id = mp_certificates.certificate_id
	where mp_certificates.certificate_id IN (SELECT * FROM @CerificateCodes1) 
	 


	--select a.company_id , a.name company_name , b.contact_id , b.address_id
	--into #tmp_supplier_company_contact
	--from
	--mp_companies (nolock) a
	--JOIN mp_contacts  (nolock) b ON b.company_Id = a.company_Id	
	--'+ @join_query +'	
	--where b.is_buyer = 0  AND b.company_id > 0  AND a.company_id > 0 

	select comp_Id ,cont_id , file_name , filetype_id  into #tmp_company_profile_logo
	from mp_special_files (nolock) where filetype_id in  (6,8) and is_deleted = 0
	
	create nonclustered index idx_tmp_company_profile_logo_comp_id_filetype_id
	on #tmp_company_profile_logo ([comp_Id],[filetype_id])



	select  * , COUNT(a.CompanyId) over() TotalCount
	from
	(
					 
					 
				select distinct
						a.company_id 
						, ltrim(rtrim( REPLACE(ltrim(rtrim( REPLACE(a.name,char(9),'''') )),char(9),'''') ))   as ManufactureName 
				 		, vw_address.City   AS City       
						, vw_address.[State]  AS [State]    
						, vw_address.CountryId  AS CountryId    
						, vw_address.country_name AS Country    
						, (select top 1 file_name from #tmp_company_profile_logo where  a.company_id = comp_id and filetype_id = 6 ) AS companyLogo     
						, (select top 1 file_name from #tmp_company_profile_logo where  a.company_id = comp_id and filetype_id =  8)  AS ProfilePicture  
						, a.company_id AS CompanyId        
						, mrs.is_registered  
						, '+ @SQLString +' AS IsSpotLightTurnOn 						 
				 from mp_companies (nolock) a   
				 --left join mp_company_shipping_site  (nolock) b ON a.company_id = b.comp_id and b.default_site = 1
				 --left join mp_contacts (nolock) b ON a.company_id = b.company_id and  is_buyer = 0 and is_admin= 1
				 left join 
				  (
					select company_id , contact_id , user_id ,address_id  , row_number() over(partition by company_id order by company_id ,contact_id ) rn
					from  mp_contacts (nolock) 
					where is_buyer =  0  and is_admin =1 
				  )  b on a.company_id = b.company_id and b.rn =1
				 left join vw_address  (nolock) ON b.address_id = vw_address.address_Id  
				 left join mp_registered_supplier mrs on mrs.company_id = a.company_id 		
				 left join mp_spotlight_supplier on a.company_Id = (select company_id  from mp_contacts where company_id  = mp_spotlight_supplier.CompanyId)
				 and ( mp_spotlight_supplier.part_category_id IN (SELECT * FROM @ProcessIds1) )		 
				 '+ @join_query +'	
				 where a.company_id > 0
				 and  a.company_id in  (select distinct company_id from mp_contacts (nolock) where is_buyer = 0 and company_id > 0 )
				 and  a.company_id NOT IN (SELECT company_id FROM @blacklisted_Companies)
				 and 
				 (
						(vw_address.CountryId in (select countryId from @CountryIds1 ))
						OR 
						((Select count(countryId) from @CountryIds1) = 0)
				 )	 
				 and a.company_id not in (select distinct company_id from #excludecompanies  where (islogo + isheader +	isdescription)<3 )
	 
				'+ @search_query +'
	) a
	order by a.IsSpotLightTurnOn desc, a.is_registered desc, a.ManufactureName
	OFFSET '+ convert(varchar(50),@PageSize) +'   * ( '+ convert(varchar(50),@PageNumber) + ' - 1) ROWS
	FETCH NEXT '+ convert(varchar(50),@PageSize) + ' ROWS ONLY'

	EXECUTE sp_executesql @sql_query,N'@ContactId1 INT,@Company_Id1 INT,@CountryIds1 tbltype_ListOfCountries readonly,@ProcessIds1 as tbltype_ListOfProcesses readonly,@CerificateCodes1 as tbltype_ListOfCertificateCodes readonly', @ContactId1 = @ContactId ,@Company_Id1 = @Company_Id, @CountryIds1 = @CountryIds,@ProcessIds1 = @ProcessIds,@CerificateCodes1 = @CerificateCodes
	
	

	drop table if exists #Followed_Companies
	drop table if exists #ProcessId_Companies
	drop table if exists #CertificateCode_Companies
	drop table if exists #tmp_supplier_company_contact
	drop table if exists #tmp_company_profile_logo
	drop table if exists #excludecompanies	
END
