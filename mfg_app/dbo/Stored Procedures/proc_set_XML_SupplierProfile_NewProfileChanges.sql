
/*

EXEC [proc_set_XML_SupplierProfile_NewProfileChanges]
@MaxDate = '2020-12-01 09:32:08.590' ,
@CurrentDateTime = '2020-12-02 11:11:20.590'

*/



CREATE PROCEDURE [dbo].[proc_set_XML_SupplierProfile_NewProfileChanges]
(
	@MaxDate		DATETIME2,
	@CurrentDateTime DATETIME2
)
AS
BEGIN
	--M2-3466 Supplier profile XML file generation
	--SELECT GETUTCDATE()

	SET NOCOUNT ON


	DECLARE @PublicProfileLink			VARCHAR(4000)
	DECLARE @CompanyLogo				VARCHAR(4000)
	DECLARE @ImageGalleryPath			VARCHAR(4000)
	DECLARE @CompanyBanner				VARCHAR(4000)
	DECLARE @TotalRecords				INT

	BEGIN TRY


		IF DB_NAME() = 'mp2020_dev'
		BEGIN
			SET @PublicProfileLink = 'http://qa.mfg2020.com/#/Public/profile/'
			SET @CompanyLogo = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020/logos/'
			SET @ImageGalleryPath = 'https://uatfiles.mfg.com/RFQFiles/'
			SET @CompanyBanner = 'https://uatfiles.mfg.com/RFQFiles/'
		
		END
		ELSE IF DB_NAME() = 'mp2020_uat'
		BEGIN
			SET @PublicProfileLink = 'https://uatapp.mfg.com/#/Public/profile/'
			SET @CompanyLogo = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020/logos/'
			SET @ImageGalleryPath = 'https://uatfiles.mfg.com/RFQFiles/'
			SET @CompanyBanner = 'https://uatfiles.mfg.com/RFQFiles/'
		END
		ELSE IF DB_NAME() = 'mp2020_prod'
		BEGIN
			SET @PublicProfileLink = 'https://app.mfg.com/#/Public/profile/'
			SET @CompanyLogo = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.public/logos/'
			SET @ImageGalleryPath = 'https://files.mfg.com/RFQFiles/'
			SET @CompanyBanner = 'https://files.mfg.com/RFQFiles/'
		END

		DROP TABLE IF EXISTS #TMP_XML_SupplierProfileCaptureChanges
			
		SELECT DISTINCT CompanyId 
		INTO #TMP_XML_SupplierProfileCaptureChanges 
		FROM XML_SupplierProfileCaptureChanges (NOLOCK) A
		JOIN mp_companies		(NOLOCK) b ON a.CompanyId = b.company_id
		JOIN (SELECT company_id , is_buyer, IsTestAccount FROM mp_contacts		(NOLOCK) ) c ON b.company_id = c.company_id 
		WHERE CreatedOn BETWEEN @MaxDate AND @CurrentDateTime
			AND c.is_buyer = 0 
			AND c.IsTestAccount = 0 AND b.company_id <> 0
		UNION
		SELECT company_id FROM zoho..zoho_sink_down_logs (NOLOCK) WHERE table_name = 'mp_registered_supplier' 
		AND log_date BETWEEN @MaxDate AND @CurrentDateTime
		

		--SELECT * FROM #TMP_XML_SupplierProfileCaptureChanges


		IF ((SELECT COUNT(1) FROM #TMP_XML_SupplierProfileCaptureChanges ) > 0 )
		BEGIN

			--SELECT DISTINCT company_id FROM XML_SupplierProfile (NOLOCK) WHERE createddate BETWEEN @MaxDate AND @CurrentDateTime AND [action] = 'New'

			DELETE FROM #TMP_XML_SupplierProfileCaptureChanges  
			WHERE CompanyId IN (SELECT DISTINCT company_id FROM XML_SupplierProfile (NOLOCK) WHERE createddate BETWEEN @MaxDate AND @CurrentDateTime AND [action] = 'New')
		
			--SELECT DISTINCT b.company_id as CompanyId INTO #XMLSupplierProfileListofCompanyIds
			--FROM mp_companies		(NOLOCK) b
			--JOIN (SELECT company_id , is_buyer, IsTestAccount FROM mp_contacts		(NOLOCK) ) a ON a.company_id = b.company_id 
			--WHERE a.is_buyer = 0 
			--	AND IsTestAccount = 0 AND b.COMPANY_ID <> 0
			--	AND b.created_date BETWEEN @MaxDate AND @CurrentDateTime
			--ORDER BY b.company_id ASC


			INSERT INTO XML_SupplierProfile
			(rn ,company_id ,contact_id ,address_id ,publicprofile ,[avatar] ,banner ,cagecode ,description ,duns ,employees ,date_established ,location_manufacturing ,name ,type ,[tier] ,[action],createddate 
			,phone ,website ,[source] 
			, [3dshopview]  , first_name 
			, last_name, email , mfgverified 
			, [owner]
			)
			SELECT 
				ROW_NUMBER() OVER(ORDER BY b.company_id)  RN
				,b.company_id		as id
				,a.contact_id		as contact_id
				,a.address_id		as address_id
				, CompanyURL		as publicprofile -- @PublicProfileLink + 
				, CASE 
					WHEN h.file_name IS NULL THEN NULL 
					WHEN h.file_name ='' THEN NULL 
					ELSE 
						'<image url="'+ISNULL(@CompanyLogo +  REPLACE(h.file_name,'&' ,'&amp;'),'')+'">'+ISNULL(@CompanyLogo + REPLACE(h.file_name,'&' ,'&amp;'),'') + '</image>'
					END as [avatar_image] 
				, CASE 
					WHEN l.file_name IS NULL THEN NULL 
					WHEN l.file_name ='' THEN NULL 
					ELSE 
						'<image url="'+ISNULL(@CompanyBanner +  REPLACE(l.file_name,'&' ,'&amp;'),'')+'">'+ISNULL(@CompanyBanner + REPLACE(l.file_name,'&' ,'&amp;'),'') + '</image>'
					END as banner 
				, CASE WHEN b.cage_code IS NULL THEN NULL WHEN b.cage_code ='' THEN NULL ELSE REPLACE(REPLACE( REPLACE(b.cage_code,'<',''),'>',''),'&' ,'&amp;') END	as cagecode
				, CASE WHEN b.description IS NULL THEN NULL WHEN b.description ='' THEN NULL 
						ELSE (SELECT [dbo].RemoveInvalidXMLCharacters (REPLACE( REPLACE( REPLACE( (SELECT [dbo].[udf_StripHTML](ISNULL(b.description,''))),'&' ,'&amp;'),'<',''),'>',''))) END
					as description
				, CASE WHEN b.duns_number IS NULL THEN NULL WHEN b.duns_number ='' THEN NULL ELSE REPLACE(REPLACE( REPLACE(b.duns_number,'<',''),'>',''),'&' ,'&amp;') END 	as dunsnumber
				, CASE WHEN c.range IS NULL THEN NULL WHEN c.range ='' THEN NULL WHEN c.range = '---' THEN NULL  ELSE c.range END 			as employees_countrange
				, b.created_date	as established_date
				, CASE WHEN d.territory_classification_name IS NULL THEN NULL WHEN d.territory_classification_name ='' THEN NULL ELSE d.territory_classification_name END as location_manufacturing
				, CASE WHEN b.name IS NULL THEN NULL WHEN b.name ='' THEN NULL ELSE (SELECT [dbo].RemoveInvalidXMLCharacters (REPLACE( (SELECT [dbo].[udf_StripHTML](ISNULL(b.name ,''))),'&' ,'&amp;')))  END 		as name
				, CASE WHEN supplier_type_name_en IS NULL THEN NULL WHEN supplier_type_name_en ='' THEN NULL ELSE (SELECT [dbo].RemoveInvalidXMLCharacters (REPLACE( (SELECT [dbo].[udf_StripHTML](ISNULL(supplier_type_name_en,''))),'&' ,'&amp;'))) END   as [type]
				, CASE WHEN k.PaidStatus IS NULL THEN '01 Basic' WHEN k.PaidStatus ='' THEN '01 Basic' ELSE  k.PaidStatus  END 		as PaidStatus
				, 'Update' as [action]
				, @CurrentDateTime as createddate
				, (SELECT TOP 1	
					CASE	WHEN REPLACE(REPLACE(REPLACE(communication_value,'&' ,'&amp;'),'(',''),')','') = '' THEN NULL
							ELSE REPLACE(REPLACE(REPLACE(communication_value,'&' ,'&amp;'),'(',''),')','')
					END
					FROM mp_communication_details (NOLOCK) WHERE contact_id = a.contact_id AND communication_type_id = 1) as Phone
				, (SELECT TOP 1	
					CASE	WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(communication_value,'&' ,'&amp;'),'https://',''),'https:/',''),'http://',''),'http:/','') = '' THEN NULL
							ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(communication_value,'&' ,'&amp;'),'https://',''),'https:/',''),'http://',''),'http:/','')
					END 
							FROM mp_communication_details (NOLOCK) WHERE company_id = b.company_id AND communication_type_id = 4 AND communication_value <> '') as Website
				, 'Mfg' as Source
				, REPLACE(m.[3dshopview],'&' ,'&amp;' )[3dshopview]
				, REPLACE(REPLACE(a.first_name,'&' ,'&amp;'),'"','') first_name
				, REPLACE(REPLACE(a.last_name,'&' ,'&amp;'),'"','') last_name
				, REPLACE(n.email,'&' ,'&amp;') email
				, CASE WHEN k.PaidStatus IS NULL THEN 'No' WHEN k.PaidStatus ='' THEN 'No' WHEN k.PaidStatus ='01 Basic' THEN 'No'  ELSE  'Yes'  END 		as mfgverified
				, CASE	
						WHEN a.first_name = '' THEN  '<profile_owner name_first="" name_last="" email="'+REPLACE(n.email,'&' ,'&amp;')+'">'+REPLACE(n.email,'&' ,'&amp;')+'</profile_owner>'
						WHEN a.last_name = '' THEN  '<profile_owner name_first="" name_last="" email="'+REPLACE(n.email,'&' ,'&amp;')+'">'+REPLACE(n.email,'&' ,'&amp;')+'</profile_owner>'
						WHEN a.first_name <> ''  AND a.last_name <> '' THEN  '<profile_owner name_first="'+REPLACE(REPLACE(a.first_name,'&' ,'&amp;'),'"','')+'" name_last="'+REPLACE(REPLACE(a.last_name,'&' ,'&amp;'),'"','')+'" email="'+REPLACE(n.email,'&' ,'&amp;')+'">' + REPLACE(REPLACE(a.first_name,'&' ,'&amp;'),'"','')+' ' + REPLACE(REPLACE(a.last_name,'&' ,'&amp;'),'"','') +' '+ REPLACE(n.email,'&' ,'&amp;') +'</profile_owner>'
						ELSE NULL
					END
				as profile_owner 
			--INTO #XML5000
			FROM 
			#TMP_XML_SupplierProfileCaptureChanges b1
			JOIN mp_companies		(NOLOCK) b ON  b1.CompanyId = b.company_id
			JOIN (SELECT company_id , contact_id , first_name , last_name , is_buyer , address_id, IsTestAccount , [user_id] , row_number() over(partition by company_id order by company_id , is_admin desc, contact_id ) rn FROM mp_contacts		(NOLOCK) ) a ON a.company_id = b.company_id and a.rn=1
			LEFT JOIN mp_mst_employees_count_range		(NOLOCK) c ON b.employee_count_range_id = c.employee_count_range_id
			LEFT JOIN mp_mst_territory_classification	(NOLOCK) d ON b.manufacturing_location_id = d.territory_classification_id
			LEFT JOIN 
			(
				SELECT COMP_ID ,file_name , ROW_NUMBER() OVER(PARTITION BY COMP_ID ORDER BY COMP_ID,FILE_ID DESC)  RN  FROM mp_special_files (NOLOCK) WHERE FILETYPE_ID = 6 AND IS_DELETED = 0
			) h ON b.company_id = h.COMP_ID AND h.RN = 1
			LEFT JOIN 
			(
				SELECT company_id ,supplier_type_id , ROW_NUMBER() OVER(PARTITION BY company_id ORDER BY company_id,company_supplier_types_id DESC)  RN  FROM mp_company_supplier_types (NOLOCK) WHERE ISNULL(IS_BUYER,0) = 0
			) i ON b.company_id = i.company_id  AND i.RN = 1
			LEFT JOIN mp_mst_supplier_type (NOLOCK) j ON i.supplier_type_id = j.supplier_type_id
			LEFT JOIN 
			(
				SELECT 
					VisionACCTID  AS CompanyId
					,(
						CASE	
							WHEN account_status in('active','gold') THEN '03 Gold' --1
							WHEN account_status = 'silver'          THEN '02 Silver'
							WHEN account_status = 'platinum'        THEN '04 Platinum'
							ELSE '01 Basic' 
							END
						) AS PaidStatus
				FROM Zoho..Zoho_company_account (NOLOCK) WHERE synctype = 2 AND  account_type_id = 3
			) k ON b.company_id = k.CompanyId
			LEFT JOIN 
			(
				SELECT COMP_ID ,file_name , ROW_NUMBER() OVER(PARTITION BY COMP_ID ORDER BY COMP_ID,FILE_ID DESC)  RN  FROM mp_special_files (NOLOCK) WHERE FILETYPE_ID = 8 AND IS_DELETED = 0
			) l ON b.company_id = l.COMP_ID AND l.RN = 1
			LEFT JOIN 
			(
				SELECT company_id ,[3d_tour_url] [3dshopview] , ROW_NUMBER() OVER(PARTITION BY company_id ORDER BY company_id,company_3dtour_id DESC)  RN  FROM mp_company_3dtours (NOLOCK) 
			) m ON b.company_id = m.company_id AND m.RN = 1
			JOIN aspnetusers n (NOLOCK)  ON  a.user_id = n.id

			SET @TotalRecords = (SELECT COUNT(DISTINCT company_id ) FROM XML_SupplierProfile WHERE isprocessed = 0  AND [action] = 'Update')

			DECLARE @CompanyId			INT
			DECLARE @AddressId			INT
			DECLARE @PublicProfile		VARCHAR(1000)
			DECLARE @RN					INT

			PRINT '-- Cursor : Start '

			DECLARE cr_Company CURSOR FOR SELECT RN ,company_id as id , address_id , publicprofile FROM XML_SupplierProfile (NOLOCK) WHERE isprocessed = 0 ORDER BY RN
			OPEN cr_Company;
			FETCH NEXT FROM cr_Company INTO @RN  , @CompanyId  , @AddressId ,@PublicProfile;

			WHILE @@FETCH_STATUS = 0
			BEGIN
			
						PRINT '-> CompanyId:' + CONVERT(VARCHAR(100),@CompanyId) + ':' + CONVERT(VARCHAR(100),@RN)

						PRINT '  --> Fetching Address ' + CONVERT(VARCHAR(100),@CompanyId)

						DECLARE 
							@Address						NVARCHAR(MAX) = '',
							@AddressWithoutHTMLTags			NVARCHAR(MAX) = '',
							@PublicProfileURL				VARCHAR(1000) = '',
							@FinalAddressXML				XML = '',
							@GPS							VARCHAR(150) = '&#160;'  ,
							@LatLong						VARCHAR(500) = '',
							@Lat							VARCHAR(500) = '',
							@Long							VARCHAR(500) = '',
							@ZipCode						VARCHAR(1000) = '',
							@Street							VARCHAR(500) = '',
							@City							VARCHAR(500) = '',
							@State							VARCHAR(500) = '',
							@Country							VARCHAR(500) = '';

						SELECT 
							@Address =
								(
									CASE WHEN LEN(ISNULL(e.address1,'')) = 0 THEN '' ELSE REPLACE(address1,'?','') + ', ' END
									+ CASE WHEN LEN(ISNULL(e.address4,'')) = 0 THEN '' ELSE REPLACE(address4,'?','') + ', ' END
									+ CASE WHEN LEN(ISNULL(g.REGION_NAME,'')) = 0 THEN '' ELSE g.REGION_NAME + ', ' END
									+ CASE WHEN LEN(ISNULL(e.address3,'')) = 0 THEN '' ELSE address3 + ', ' END
									+ CASE WHEN LEN(ISNULL(f.country_name,'')) = 0  THEN '' ELSE f.country_name END	
								)
							,@LatLong = (CONVERT(VARCHAR(100),latitude) +','+CONVERT(VARCHAR(100),longitude)) 
							,@Lat = (CONVERT(VARCHAR(100),latitude))
							,@Long = (CONVERT(VARCHAR(100),longitude))
							,@ZipCode = CASE WHEN LEN(ISNULL(e.address3,'')) = 0 THEN '' ELSE address3 END
							,@Street = CASE WHEN LEN(ISNULL(e.address1,'')) = 0 THEN '' ELSE REPLACE(REPLACE(REPLACE(REPLACE(address1,'?',''),'"',''),'<',''),'>','') END
							,@City = CASE WHEN LEN(ISNULL(e.address4,'')) = 0 THEN '' ELSE REPLACE(REPLACE(REPLACE(REPLACE(address4,'?',''),'"',''),'<',''),'>','')  END
							,@State = CASE WHEN LEN(ISNULL(g.REGION_NAME,'')) = 0 THEN '' ELSE REPLACE(REPLACE(REPLACE(REPLACE(g.REGION_NAME,'?',''),'"',''),'<',''),'>','')  END
							,@Country = CASE WHEN LEN(ISNULL(f.country_name,'')) = 0  THEN '' ELSE f.country_name END	
						FROM mp_addresses				(NOLOCK) e
						LEFT JOIN mp_mst_country		(NOLOCK) f ON e.country_id = f.country_id
						LEFT JOIN mp_mst_region			(NOLOCK) g ON e.region_id = g.region_id AND g.region_id <> 0
						LEFT JOIN mp_mst_geocode_data (NOLOCK) h ON LTRIM(RTRIM(e.address3)) = LTRIM(RTRIM(h.zipcode)) AND e.country_id  = h.country_Id
						WHERE E.address_id = @AddressId

						SET @AddressWithoutHTMLTags = 
								(
									CASE 
										WHEN @Address IS NULL THEN NULL 
										WHEN @Address = '' THEN NULL 
										ELSE   
										'<text street="'+REPLACE(@Street,'&' ,'&amp;')+ '" city="'+ REPLACE(@City,'&' ,'&amp;')+ '" state="'+REPLACE(@State,'&' ,'&amp;')+ '" zipcode="'+ REPLACE(@ZipCode,'&' ,'&amp;')+ '" country="' + REPLACE(@Country,'&' ,'&amp;') +'">' 
										+(SELECT [dbo].RemoveInvalidXMLCharacters (REPLACE( (SELECT [dbo].[udf_StripHTML](ISNULL(@Address,''))),'&' ,'&amp;'))) 
										+'</text>'
										--+CASE WHEN @ZipCode IS NULL THEN NULL WHEN @ZipCode ='' THEN NULL ELSE '<zipcode>'+@ZipCode+'</zipcode>' END
										+CASE WHEN @LatLong IS NULL THEN NULL WHEN @LatLong ='' THEN NULL ELSE '<gps latitude="'+@Lat+'" longitude="'+@Long+'">'+@LatLong +'</gps>'END
								
										--+'<url_googlemaps>&#160;</url_googlemaps>'
									END
								)

						SET @FinalAddressXML = @AddressWithoutHTMLTags

						UPDATE XML_SupplierProfile SET [address] = @FinalAddressXML 	WHERE company_id = @CompanyId
						SET @FinalAddressXML = ''
				
						PRINT '  -- Fetching Capabilities : ' + CONVERT(VARCHAR(100),@CompanyId)

						DROP TABLE IF EXISTS #TMP
						-- Fetching Supplier Capabilities & generating capabiities XML
						SELECT ROW_NUMBER() OVER(ORDER BY c.discipline_name , a.discipline_name ) rn , c.discipline_name as parent , a.discipline_name as child INTO #TMP
						FROM mp_mst_part_category (NOLOCK) a
						JOIN
						(
							SELECT company_id , part_category_id FROM mp_company_processes (NOLOCK) WHERE company_id = @CompanyId
							UNION
							SELECT company_id , part_category_id FROM mp_gateway_subscription_company_processes  (NOLOCK) WHERE company_id = @CompanyId
						) b ON a.part_category_id = b.part_category_id --AND a.level = 1 
						JOIN mp_mst_part_category (NOLOCK) c ON a.parent_part_category_id = c.part_category_id


						DECLARE 
							@Capabilities						NVARCHAR(MAX) = '',
							@ParentCapabilities					NVARCHAR(MAX) = '',
							@ParentWithoutXMLTags				NVARCHAR(MAX) = '',
							@ChildCapabilities					NVARCHAR(MAX) = '',
							@ChildCapabilitiesWithoutXMLTags	NVARCHAR(MAX) = '',
							@FinalCapabilitiesXML				XML = '',
							@Marketplaces						NVARCHAR(MAX) = '',
							@FinalMarketplacesXML				XML = '';

						DECLARE cr_ParentCapabilities CURSOR FOR SELECT DISTINCT parent FROM #TMP 
						OPEN cr_ParentCapabilities;
						FETCH NEXT FROM cr_ParentCapabilities INTO @ParentCapabilities;
			
				
			
						SET @Capabilities = ''
						SET @Marketplaces = ''
						WHILE @@FETCH_STATUS = 0
							BEGIN

						
								SET @ParentWithoutXMLTags = REPLACE(@ParentCapabilities,'&' ,'&amp;')
								SET @Capabilities = @Capabilities + '<capability>'+ '<primary txt="'+@ParentWithoutXMLTags+'">'+@ParentWithoutXMLTags+'</primary>'
								--SET @Marketplaces = @Marketplaces + '<marketplace  txt="'+@ParentWithoutXMLTags+'">'+@ParentWithoutXMLTags+'</marketplace>'
						
								DECLARE cr_ChildCapabilities CURSOR FOR SELECT DISTINCT Child FROM #TMP WHERE Parent =   @ParentCapabilities AND Parent<> Child
								OPEN cr_ChildCapabilities;
								FETCH NEXT FROM cr_ChildCapabilities INTO @ChildCapabilities;

								WHILE @@FETCH_STATUS = 0
								BEGIN
							
									SET @ChildCapabilitiesWithoutXMLTags = REPLACE(@ChildCapabilities,'&' ,'&amp;')
									SET @Capabilities = @Capabilities+'<secondary txt="'+@ChildCapabilitiesWithoutXMLTags+'">'+@ChildCapabilitiesWithoutXMLTags+'</secondary>'
			
								FETCH NEXT FROM cr_ChildCapabilities INTO @ChildCapabilities;
								END;
								CLOSE cr_ChildCapabilities;
								DEALLOCATE cr_ChildCapabilities;
	
								SET @Capabilities = @Capabilities + '</capability>'

							FETCH NEXT FROM cr_ParentCapabilities INTO @ParentCapabilities;
							END;

						CLOSE cr_ParentCapabilities;
						DEALLOCATE cr_ParentCapabilities;

						SET @Capabilities = CASE WHEN LEN(@Capabilities)> 0 THEN @Capabilities ELSE NULL END  
						SET @FinalCapabilitiesXML = @Capabilities
						SET @FinalMarketplacesXML = CASE WHEN LEN(@Marketplaces)> 0 THEN @Marketplaces ELSE NULL END  
				

						UPDATE XML_SupplierProfile 
						SET 
							capabilities = @FinalCapabilitiesXML   
							, marketplaces = @FinalMarketplacesXML
						WHERE company_id = @CompanyId

						SET @FinalCapabilitiesXML = ''
						SET @FinalMarketplacesXML = ''

						-- Fetching Supplier Ceritificates
						DECLARE 
							@Certificates			NVARCHAR(MAX) = '',
							@FinalCertificatesList	NVARCHAR(MAX) = '',
							@FinalCertificatesXML	XML ='',
							@CertificatesWithoutXMLTags	NVARCHAR(MAX) = '';

						DECLARE cr_Ceritificates CURSOR FOR 
							SELECT DISTINCT b.certificate_code 
							FROM mp_company_certificates	(NOLOCK) a
							JOIN mp_certificates			(NOLOCK) b ON a.certificates_id = b.certificate_id
							WHERE a.company_id = @CompanyId

						OPEN cr_Ceritificates;
						FETCH NEXT FROM cr_Ceritificates INTO @Certificates;

						PRINT '  -- Fetching Ceritificates : ' + CONVERT(VARCHAR(100),@CompanyId)

						SET @FinalCertificatesList = ''
						WHILE @@FETCH_STATUS = 0
							BEGIN
								SET @CertificatesWithoutXMLTags = REPLACE(@Certificates,'&' ,'&amp;')
								SET @FinalCertificatesList = @FinalCertificatesList + '<name txt="'+@CertificatesWithoutXMLTags+'">'+@CertificatesWithoutXMLTags+ '</name>'

						FETCH NEXT FROM cr_Ceritificates INTO @Certificates;
						END;

						CLOSE cr_Ceritificates;
						DEALLOCATE cr_Ceritificates;   

				
						SET @FinalCertificatesList = CASE WHEN LEN(@FinalCertificatesList)> 0 THEN @FinalCertificatesList ELSE NULL END
						SET @FinalCertificatesXML = @FinalCertificatesList

						UPDATE XML_SupplierProfile SET certifications =  @FinalCertificatesXML   WHERE company_id = @CompanyId
						SET @FinalCertificatesXML = ''


						PRINT '  -- Fetching Equipments : ' + CONVERT(VARCHAR(100),@CompanyId)
						-- Fetch & set Supplier equipments
						DECLARE 
							@Equipments			NVARCHAR(MAX) = '',
							@FinalEquipmentList	NVARCHAR(MAX) = '',
							@FinalEquipmentXML	XML ='',
							@EquipmentsWithoutXMLTags	NVARCHAR(MAX) = '';

						DECLARE cr_Equipments CURSOR FOR 
							SELECT DISTINCT b.equipment_Text
							FROM mp_company_equipments	(NOLOCK) a
							JOIN mp_mst_equipment			(NOLOCK) b ON a.equipment_ID = b.equipment_Id
							WHERE a.company_id = @CompanyId

						OPEN cr_Equipments;
						FETCH NEXT FROM cr_Equipments INTO @Equipments;

						SET @FinalEquipmentList = ''
						WHILE @@FETCH_STATUS = 0
							BEGIN

								SET @EquipmentsWithoutXMLTags = (SELECT [dbo].RemoveInvalidXMLCharacters (REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@Equipments,''),'&' ,'&amp;'),'<',''),'>',''),'"','')))
								SET @FinalEquipmentList = @FinalEquipmentList + '<name txt="'+@EquipmentsWithoutXMLTags+'">'+@EquipmentsWithoutXMLTags+'</name>'

						FETCH NEXT FROM cr_Equipments INTO @Equipments;
						END;

						CLOSE cr_Equipments;
						DEALLOCATE cr_Equipments;   

						SET @FinalEquipmentList = CASE WHEN LEN(@FinalEquipmentList)> 0 THEN @FinalEquipmentList ELSE NULL END 
						SET @FinalEquipmentXML = @FinalEquipmentList

						UPDATE XML_SupplierProfile SET equipment =  @FinalEquipmentXML WHERE company_id = @CompanyId
						SET @FinalEquipmentXML = ''


						PRINT '  -- Fetching Industries : ' + CONVERT(VARCHAR(100),@CompanyId)
						-- Fetch & set Supplier equipments
						DECLARE 
							@Industries			NVARCHAR(MAX) = '',
							@FinalIndustriesList	NVARCHAR(MAX) = '',
							@FinalIndustriesXML	XML ='',
							@IndustriesWithoutXMLTags	NVARCHAR(MAX) = '';

						DECLARE cr_Industries CURSOR FOR 
							SELECT DISTINCT [IndBranch].[IndustryBranches_name_EN] AS [IndustryBranchesNameEn]
							FROM [mp_mst_IndustryBranches] AS [IndBranch]
							INNER JOIN [mp_company_Industryfocus] AS [CompIndFoc] ON [IndBranch].[IndustryBranches_id] = [CompIndFoc].[IndustryBranches_id]
							WHERE [CompIndFoc].[company_id] = @CompanyId

						OPEN cr_Industries;
						FETCH NEXT FROM cr_Industries INTO @Industries;

						SET @FinalIndustriesList = ''
						WHILE @@FETCH_STATUS = 0
							BEGIN

								SET @IndustriesWithoutXMLTags = (SELECT [dbo].RemoveInvalidXMLCharacters (REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@Industries,''),'&' ,'&amp;'),'<',''),'>',''),'"','')))
								SET @FinalIndustriesList = @FinalIndustriesList + '<industry  txt="'+@IndustriesWithoutXMLTags+'">'+@IndustriesWithoutXMLTags+'</industry >'

						FETCH NEXT FROM cr_Industries INTO @Industries;
						END;

						CLOSE cr_Industries;
						DEALLOCATE cr_Industries;   

						SET @FinalIndustriesList = CASE WHEN LEN(@FinalIndustriesList)> 0 THEN @FinalIndustriesList ELSE NULL END 
						SET @FinalIndustriesXML = @FinalIndustriesList

						UPDATE XML_SupplierProfile SET industries = @FinalIndustriesXML  WHERE company_id = @CompanyId
						SET @FinalIndustriesXML = ''

						PRINT '  -- Fetching ImageGallery : ' + CONVERT(VARCHAR(100),@CompanyId)
						-- Fetch & set Supplier image gallery
						DECLARE 
							@ImageGallery			NVARCHAR(MAX) = '',
							@FinalImageGalleryList	NVARCHAR(MAX) = '',
							@FinalImageGalleryXML	XML ='',
							@ImageGalleryWithoutXMLTags			NVARCHAR(MAX) = '';

						DECLARE cr_ImageGallery CURSOR FOR 
							SELECT file_name  FROM mp_special_files 
							WHERE comp_id = @CompanyId and filetype_id = 4 and is_deleted = 0 AND ISNULL(s3_found_status,1) = 1

						OPEN cr_ImageGallery;
						FETCH NEXT FROM cr_ImageGallery INTO @ImageGallery;

				
						SET @FinalImageGalleryList = ''
						WHILE @@FETCH_STATUS = 0
							BEGIN
								SET @ImageGalleryWithoutXMLTags = @ImageGalleryPath + REPLACE(@ImageGallery,'&' ,'&amp;')
								SET @FinalImageGalleryList = @FinalImageGalleryList + '<image url="'+@ImageGalleryWithoutXMLTags+'">'+@ImageGalleryWithoutXMLTags+ '</image>'

						FETCH NEXT FROM cr_ImageGallery INTO @ImageGallery;
						END;

						CLOSE cr_ImageGallery;
						DEALLOCATE cr_ImageGallery;   

				
						SET @FinalImageGalleryList = CASE WHEN LEN(@FinalImageGalleryList)> 0 THEN @FinalImageGalleryList ELSE NULL END 
						SET @FinalImageGalleryXML = @FinalImageGalleryList

						UPDATE XML_SupplierProfile SET gallery = (CASE WHEN LEN(@FinalImageGalleryList)=0 THEN NULL ELSE @FinalImageGalleryXML END)   WHERE company_id = @CompanyId
						SET @FinalImageGalleryXML = ''

				
						PRINT '  -- Fetching Languages : ' + CONVERT(VARCHAR(100),@CompanyId)
						-- Fetch & set Supplier languages
						DECLARE 
							@Languages			NVARCHAR(MAX) = '',
							@FinalLanguagesList	NVARCHAR(MAX) = '',
							@FinalLanguagesXML	XML ='',
							@LanguagesWithoutXMLTags	NVARCHAR(MAX) = '';

						DECLARE cr_Languages CURSOR FOR 
							SELECT DISTINCT b.language_name
							FROM mp_company_contact_otherlanguages	(NOLOCK) a
							JOIN mp_mst_language			(NOLOCK) b ON a.language_id = b.language_id
							WHERE a.company_id = @CompanyId

						OPEN cr_Languages;
						FETCH NEXT FROM cr_Languages INTO @Languages;
				
						SET @FinalLanguagesList = ''
						WHILE @@FETCH_STATUS = 0
							BEGIN
						
								SET @LanguagesWithoutXMLTags = REPLACE(@Languages,'&' ,'&amp;')
								SET @FinalLanguagesList = @FinalLanguagesList + '<language txt="'+@LanguagesWithoutXMLTags+'">'+@LanguagesWithoutXMLTags+'</language>'

						FETCH NEXT FROM cr_Languages INTO @Languages;
						END;

						CLOSE cr_Languages;
						DEALLOCATE cr_Languages;   

						SET @FinalLanguagesList = CASE WHEN LEN(@FinalLanguagesList)> 0 THEN @FinalLanguagesList ELSE NULL END 
						SET @FinalLanguagesXML = @FinalLanguagesList
						--SELECT @FinalLanguagesXML

				
						UPDATE XML_SupplierProfile SET languages = @FinalLanguagesXML   WHERE company_id = @CompanyId
						SET @FinalLanguagesXML = ''

						PRINT '  -- Fetching Ratings : ' + CONVERT(VARCHAR(100),@CompanyId)
						-- Fetch & set Supplier ratings
						DECLARE 
							@RatingId			INT , 	
							@RatingDate			NVARCHAR(MAX) = '',
							@Rating				NVARCHAR(MAX) = '',
							@RatingComment		NVARCHAR(MAX) = '',
							@RatingCommentWithoutXMLTags		NVARCHAR(MAX) = '',
							@FinalRatingList	NVARCHAR(MAX) = '',
							@FinalRatingXML		XML ='',
							@OverallRating		VARCHAR(50) = '',
							@TotalRating		VARCHAR(50) = '';
					

						SET @OverallRating = (SELECT CONVERT(INT,ROUND(ROUND(no_of_stars, 1,0),0))  FROM mp_star_rating (NOLOCK) WHERE company_id = @CompanyId)
						SET @TotalRating = (SELECT no_of_stars  FROM mp_star_rating (NOLOCK) WHERE company_id = @CompanyId)

						DECLARE cr_Ratings CURSOR FOR 
							SELECT response_id, created_date ,score , REPLACE(comment,'"','') comment FROM mp_rating_responses (NOLOCK) WHERE to_company_id = @CompanyId ORDER BY created_date DESC

						OPEN cr_Ratings;
						FETCH NEXT FROM cr_Ratings INTO @RatingId, @RatingDate, @Rating ,@RatingComment;

						SET @FinalRatingList = ''
						WHILE @@FETCH_STATUS = 0
						BEGIN
						
								--PRINT '--------> RatingId  : ' + CONVERT(VARCHAR,@RatingId )

								SET @RatingCommentWithoutXMLTags = (SELECT [dbo].RemoveInvalidXMLCharacters (REPLACE(REPLACE(REPLACE(ISNULL(@RatingComment,''),'&' ,'&amp;'),'<',''),'>','')))
								SET @FinalRatingList = @FinalRatingList+'<review>'
								SET @FinalRatingList =	@FinalRatingList 
														+ '<date txt="'+@RatingDate+'">'+@RatingDate+'</date>'
														+ '<rating txt="'+@Rating+'">'+@Rating+'</rating>'
														+ '<comment txt="'+@RatingCommentWithoutXMLTags+'">'+@RatingCommentWithoutXMLTags+'</comment>'
								SET @FinalRatingList =	@FinalRatingList + '</review>'

						FETCH NEXT FROM cr_Ratings INTO @RatingId, @RatingDate, @Rating ,@RatingComment;
						END;

						CLOSE cr_Ratings;


						SET @FinalRatingList = 
							CASE	WHEN ((SELECT COUNT(1) FROM mp_star_rating (NOLOCK) WHERE company_id = @CompanyId) > 0) THEN
										'<rating star="'+@OverallRating+'-star">'+@TotalRating +'</rating>'
										+'<total>'+CONVERT(VARCHAR(50),(SELECT total_responses FROM mp_star_rating (NOLOCK) WHERE company_id = @CompanyId)) +'</total>'
										+@FinalRatingList
									WHEN LEN(@FinalRatingList)>0  THEN @FinalRatingList
							ELSE NULL
							END
				
						SET @FinalRatingXML = @FinalRatingList
			
						DEALLOCATE cr_Ratings;   

						UPDATE XML_SupplierProfile SET reviews = (CASE WHEN LEN(@FinalRatingList)=0 THEN NULL ELSE @FinalRatingXML END)    WHERE company_id = @CompanyId

						UPDATE XML_SupplierProfile SET isprocessed = 1 , processeddate =  GETUTCDATE() WHERE company_id = @CompanyId

			FETCH NEXT FROM cr_Company INTO @RN  , @CompanyId ,  @AddressId ,@PublicProfile;
			END;

			CLOSE cr_Company;
			DEALLOCATE cr_Company; 

			PRINT '-- Cursor : End '


		END

		INSERT INTO XML_SupplierProfile_Logs 
		([Action],[DBObject],[Status],[Error],[ErrorDateTime],[SuccessDateTime],[RecordProcessed],FetchDataFromDateTime,FetchDataToDateTime)
		VALUES ('Update','proc_set_XML_SupplierProfile_NewProfileChanges','Success',NULL,NULL, @CurrentDateTime,ISNULL(@TotalRecords,0),@MaxDate,@CurrentDateTime)
		
	END TRY
	BEGIN CATCH

		INSERT INTO XML_SupplierProfile_Logs 
		([Action],[DBObject],[Status],[Error],[ErrorDateTime],[SuccessDateTime],[RecordProcessed],FetchDataFromDateTime,FetchDataToDateTime)
		VALUES ('Update','proc_set_XML_SupplierProfile_NewProfileChanges','Fail',ERROR_MESSAGE(),@CurrentDateTime,NULL,@TotalRecords,@MaxDate,@CurrentDateTime)


	END CATCH

END
