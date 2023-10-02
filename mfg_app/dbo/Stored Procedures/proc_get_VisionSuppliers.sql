
/*

exec proc_get_VisionSuppliers
@PageNumber=1
,@PageSize=200
,@SearchText=N'1800811'
,@IsOrderByDesc=1
,@IsBasic=0
,@IsSilver=0
,@IsGold=0
,@IsPlatinum=0
,@IsLoggedIn30Days=0
,@IsLoggedIn60Days=0
,@IsLoggedIn90Days=0
,@ManufacturingLocationId=0
,@OrderBy=N''


*/
CREATE PROCEDURE [dbo].[proc_get_VisionSuppliers]	   
 @PageNumber INT = 1,
 @PageSize   INT = 50,
 @SearchText VARCHAR(50) = Null,	 
 @IsOrderByDesc BIT= 'true',
 @IsBasic BIT = 'false',
 @IsSilver BIT = 'false',
 @IsGold BIT = 'false',
 @IsPlatinum BIT = 'false',
 @IsLoggedIn30Days BIT = 'false',
 @IsLoggedIn60Days BIT = 'false',
 @IsLoggedIn90Days BIT = 'false',
 @ManufacturingLocationId INT = 0,
 @OrderBy VARCHAR(50) = Null,
 @IsStarter BIT = 'false' -- M2-5133

AS

BEGIN  	 

	SET NOCOUNT ON
	
	DROP TABLE IF EXISTS #tmp_proc_get_VisionSuppliers_contacts
	DROP TABLE IF EXISTS #tmp_proc_get_VisionSuppliers_companies
	DROP TABLE IF EXISTS #tmp_proc_get_VisionSuppliers_mp_communication_details
	DROP TABLE IF EXISTS #supplierlist

	SELECT 
		a.contact_id   
		, a.company_id 
		, a.[user_id] 
		, a.last_login_on
		, a.total_login_count
		, a.created_on
		, a.first_name
		, a.last_name
		, b.email
		, ISNULL(DATEDIFF(day,a.last_login_on,GETUTCDATE()) ,0 ) AS days_last_login
		, a.address_id
		, a.is_admin
		, ROW_NUMBER() OVER(PARTITION BY a.company_id ,a.is_admin ORDER BY  a.company_id ,a.contact_id  ,a.is_admin DESC ) ContactRn
	INTO #tmp_proc_get_VisionSuppliers_contacts
	FROM mp_contacts (NOLOCK) a
	JOIN aspnetusers (NOLOCK) b ON a.[user_id] = b.id
	WHERE is_buyer = 0 AND a.company_id  <> 0

	SELECT 
		a.company_id
		,b.contact_id
		,COUNT(*) OVER()   TotalCount 
	INTO #tmp_proc_get_VisionSuppliers_companies
	FROM mp_companies (NOLOCK) a
	JOIN #tmp_proc_get_VisionSuppliers_contacts b ON a.company_id = b.company_id
	LEFT JOIN mp_registered_supplier (NOLOCK) c ON a.company_Id = c.company_Id
	WHERE
		ISNULL(c.account_type,83) = 
		(
			CASE	WHEN  @IsBasic =  1 THEN 83 
					WHEN  @IsSilver =  1 THEN 84
					WHEN  @IsGold =  1 THEN 85
					WHEN  @IsPlatinum =  1 THEN 86
					WHEN  @IsStarter = 1 THEN 313 -- M2-5133
					ELSE ISNULL(c.account_type,83)
			END
		)
		AND b.days_last_login >= 
			(
				CASE	WHEN  @IsLoggedIn30Days =  1 THEN 30 
						WHEN  @IsLoggedIn60Days =  1 THEN 60
						WHEN  @IsLoggedIn90Days =  1 THEN 90
						ELSE 0
				END
			)
		AND ISNULL(a.manufacturing_location_id,0)  = (CASE WHEN  @ManufacturingLocationId  =  0 THEN ISNULL(a.manufacturing_location_id,0)  ELSE @ManufacturingLocationId END)
		AND 
		(
			  (a.name Like '%'+@SearchText+'%')	
			  OR (b.first_name Like '%'+@SearchText+'%') 
			  OR (b.last_name Like '%'+@SearchText+'%')
			  OR (b.email Like '%'+@SearchText+'%') 
			  OR ((b.first_name + ' ' + b.last_name) Like '%'+@SearchText+'%') 
			  OR (b.contact_id LIKE '%'+@SearchText+'%')     /*M2-4062*/
			  OR (b.company_id LIKE '%'+@SearchText+'%')     /*M2-4062*/
		)
	ORDER BY 
		CASE  WHEN @IsOrderByDesc =  1 and @OrderBy = '' THEN   a.company_id END DESC   
		,CASE  WHEN @IsOrderByDesc =  0 and @OrderBy = '' THEN   a.company_id END ASC 
		,CASE  WHEN @IsOrderByDesc =  1 and @OrderBy = 'CompanyName' THEN   a.name END DESC 
		,CASE  WHEN @IsOrderByDesc =  0 and @OrderBy = 'CompanyName' THEN   a.name END ASC 

	OFFSET @PageSize   * ( @PageNumber - 1) ROWS
	FETCH NEXT @PageSize ROWS ONLY

	SELECT 
		a.contact_id , a.communication_type_id , a.communication_value 
	INTO #tmp_proc_get_VisionSuppliers_mp_communication_details 
	FROM mp_communication_details (NOLOCK) a
	WHERE 
		communication_type_id = 1 
		AND EXISTS (SELECT * FROM #tmp_proc_get_VisionSuppliers_companies WHERE contact_id = a.contact_id )

	
	SELECT 
	 UserId,	Minilogo,	CompanyName,	FirstName,	LastName,	EmailAddress,	PhoneNumber,	NoOfStars,	ContactId,	LastLogin,	TotalLoginCount,	
	 CreatedOn,	CompanyId,	manufacturingLocationId,	AccountTypeId,	IsSpotlightTurnOn,	IsMQSEnabled,	UserRole,	ContactRn,
	 IsProfileCompleted,TotalCount
	INTO #supplierlist
	FROM
	(
		SELECT 
			*
			, ROW_NUMBER() OVER (PARTITION BY a.CompanyId,  a.UserRole ORDER BY a.CompanyId, a.UserRole , a.ContactId   ) Rn1
		FROM 
		(
			SELECT DISTINCT
					b.[user_id]  AS UserId
					, COALESCE( mp_special_files.FILE_NAME , '') AS Minilogo
					, COALESCE( mp_companies.name,'') AS CompanyName
					, COALESCE( b.first_name,'' ) AS FirstName
					, COALESCE( b.last_name,'' ) AS LastName
					, COALESCE( b.Email,'''' ) AS EmailAddress
					, COALESCE( mcd.communication_value,'' ) AS PhoneNumber					  
					, mp_star_rating.no_of_stars AS NoOfStars				   
					, b.contact_Id	AS ContactId				 
					, b.last_login_on	AS LastLogin
					, b.total_login_count	AS TotalLoginCount
					, b.created_on AS CreatedOn  
					, b.company_id AS CompanyId  
					, mp_companies.Manufacturing_location_id AS manufacturingLocationId  					
					, mp_registered_supplier.account_type AS AccountTypeId
					, COALESCE( mp_spotlight_supplier.is_spotlight_turn_on , 'false' ) AS IsSpotlightTurnOn
					, mp_companies.is_mqs_enable AS IsMQSEnabled
					/* M2-4107 Vision - re-label the parent and child accounts*/
					--, CASE WHEN d.Name = 'Seller Admin' THEN 'Parent' ELSE 'Child' END UserRole1 
					--, ROW_NUMBER() OVER (PARTITION BY b.company_id, b.contact_Id  , d.Name ORDER BY b.company_id , d.Name , b.contact_Id ) Rn
					, (CASE WHEN is_admin = 1 AND ContactRn = 1 THEN 'Primary Admin' WHEN is_admin = 1  AND ContactRn > 1 THEN 'Secondary Admin' ELSE 'User' END) AS UserRole
					, b.ContactRn 
					/**/
					, 
						CASE 
							WHEN 
								(
									CASE WHEN LEN(COALESCE( f.address1 , '')) > 0 THEN 1 ELSE 0 END  
									+ CASE WHEN LEN(COALESCE( mp_companies.description,'')) > 0 THEN 1 ELSE 0 END
									+ CASE WHEN (COALESCE(c.company_id,'0')) > 0 THEN 1 ELSE 0 END  
								) = 3 THEN CAST(1 AS BIT)
							ELSE CAST(0 AS BIT)
						END AS	IsProfileCompleted
					, TotalCount
			FROM #tmp_proc_get_VisionSuppliers_contacts b  
			JOIN #tmp_proc_get_VisionSuppliers_companies a ON a.company_id = b.company_id 
				AND a.contact_id = b.contact_id
				--AND a.company_id = 1767999
				--AND b.[user_id] = '2465d1d8-4894-43ce-8737-44e140c873ea' 
			JOIN mp_companies (NOLOCK) ON  b.company_id = mp_companies.company_id
			LEFT JOIN 
			(
				SELECT comp_id , FILE_NAME  , ROW_NUMBER() OVER (PARTITION BY comp_id  ORDER BY comp_id , FILE_ID DESC) Rn
				FROM mp_special_files (NOLOCK)
				WHERE FILETYPE_ID = 6 AND IS_DELETED = 0
			) mp_special_files ON mp_special_files.comp_id = a.company_id and mp_special_files.Rn = 1
			LEFT JOIN #tmp_proc_get_VisionSuppliers_mp_communication_details mcd ON mcd.contact_id =  b.contact_id AND mcd.communication_type_id = 1
			LEFT JOIN 
			(
				SELECT company_id FROM mp_company_processes (NOLOCK) 
				UNION
				SELECT company_id FROM mp_gateway_subscription_company_processes (NOLOCK) 					 
			) c ON a.company_Id = c.company_id
			/* M2-4076 Vision - Add Spotlight to the supplier profile drawer - DB */
			LEFT JOIN mp_spotlight_supplier (NOLOCK) ON b.company_id = mp_spotlight_supplier.CompanyId
			/*  */
			LEFT JOIN mp_star_rating (NOLOCK) ON mp_star_rating.company_id = a.company_id
			LEFT JOIN mp_registered_supplier (NOLOCK)  ON a.company_id = mp_registered_supplier.company_id
			--JOIN 
			--(
			--	SELECT a.userid , b.Name , ROW_NUMBER() OVER (PARTITION BY a.userid ORDER BY a.userid , b.Name DESC ) RN
			--	FROM AspNetUserRoles a (NOLOCK)
			--	JOIN AspNetRoles b (NOLOCK) ON a.RoleId = b.Id
			--	WHERE 
			--	b.Name  IN  ('Seller','Seller Admin')
									
			--) d ON 	b.[user_id]  = d.UserId AND d.RN=1
			LEFT JOIN mp_addresses f  (NOLOCK) ON f.address_id = b.address_id
		) a
	) a

	----M2-4385 : if primary admin IsProfileCompleted = 1 then all users under this company id need to set IsProfileCompleted = 1
		update #supplierlist 
		set IsProfileCompleted = 1
		where companyid in 
		(
	  		select CompanyId  from #supplierlist where UserRole = 'Primary Admin' and IsProfileCompleted =1
		) and UserRole = 'User'  and IsProfileCompleted =0
	

		----M2-4385 : if primary admin IsProfileCompleted = 0 then all users under this company id need to set IsProfileCompleted = 0
		update #supplierlist 
		set IsProfileCompleted = 0
		where companyid in 
		(
	  		select CompanyId    from #supplierlist where UserRole = 'Primary Admin' and IsProfileCompleted =0
		)	and UserRole = 'User'  and IsProfileCompleted =1

		----Final Resultset
		SELECT 
		UserId,	Minilogo,	CompanyName,	FirstName,	LastName,	EmailAddress,	PhoneNumber,	NoOfStars,	ContactId,	LastLogin,	TotalLoginCount,	
		CreatedOn,	CompanyId,	manufacturingLocationId,	AccountTypeId,	IsSpotlightTurnOn,	IsMQSEnabled,	UserRole,	ContactRn
		,IsProfileCompleted ,TotalCount
		FROM #supplierlist a
		ORDER BY 
		CASE  WHEN @IsOrderByDesc =  1 and @OrderBy = '' THEN   a.CompanyId END DESC  
		,CASE  WHEN @IsOrderByDesc =  1 and @OrderBy = '' THEN  a.UserRole END DESC    
		,CASE  WHEN @IsOrderByDesc =  1 and @OrderBy = '' THEN  a.ContactRn END ASC   
		,CASE  WHEN @IsOrderByDesc =  0 and @OrderBy = '' THEN  a.CompanyId END ASC  
		,CASE  WHEN @IsOrderByDesc =  0 and @OrderBy = '' THEN  a.UserRole END DESC    
		,CASE  WHEN @IsOrderByDesc =  0 and @OrderBy = '' THEN  a.ContactRn END ASC  
		,CASE  WHEN @IsOrderByDesc =  1 and @OrderBy = 'CompanyName' THEN  a.CompanyName END DESC  
		,CASE  WHEN @IsOrderByDesc =  1 and @OrderBy = 'CompanyName' THEN  a.UserRole END DESC    
		,CASE  WHEN @IsOrderByDesc =  1 and @OrderBy = 'CompanyName' THEN  a.ContactRn END ASC   
		,CASE  WHEN @IsOrderByDesc =  0 and @OrderBy = 'CompanyName' THEN  a.CompanyName END ASC  
		,CASE  WHEN @IsOrderByDesc =  0 and @OrderBy = 'CompanyName' THEN  a.UserRole END DESC    
		,CASE  WHEN @IsOrderByDesc =  0 and @OrderBy = 'CompanyName' THEN  a.ContactRn END ASC  

	DROP TABLE IF EXISTS #tmp_proc_get_VisionSuppliers_contacts
	DROP TABLE IF EXISTS #tmp_proc_get_VisionSuppliers_companies
	DROP TABLE IF EXISTS #tmp_proc_get_VisionSuppliers_mp_communication_details

	--select * from #supplierlist order by CompanyId
	--select companyid from #supplierlist  group by companyid having count(companyid) > 1

END
