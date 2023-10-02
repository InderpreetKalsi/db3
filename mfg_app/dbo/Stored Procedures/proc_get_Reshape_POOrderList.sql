 	
		
		
/*

SELECT a.* , b.contact_id , c.*
		FROM mpOrderManagement (NOLOCK) a
		JOIN mp_rfq (NOLOCK) b ON a.rfqid = b.rfq_id
		JOIN mp_contacts (NOLOCK) c ON b.contact_id = c.contact_id
		where b.contact_id = 1372750

   
   exec proc_get_Reshape_POOrderList @Contact_Id=1372884,@Status=default,@CompanyId=default,@ContactId=default,@SearchText=default,@PageNumber=N'1',@PageSize=N'24',@CompanyContactId = NULL
   exec proc_get_Reshape_POOrderList @Contact_Id=1371103,@Status=N'Pending',@CompanyId=default,@ContactId=default,@SearchText=default,@PageNumber=N'1',@PageSize=N'24',@CompanyContactId = NULL
   exec proc_get_Reshape_POOrderList @Contact_Id=1371103,@Status=N'Pending',@CompanyId=N'null',@ContactId='null',@SearchText=default,@PageNumber=N'1',@PageSize=N'24',@CompanyContactId = NULL
   exec proc_get_Reshape_POOrderList @Contact_Id=1371103,@Status=N'pending',@CompanyId='1799168',@ContactId='1371141',@SearchText=default,@PageNumber=N'1',@PageSize=N'24',@CompanyContactId = NULL

   exec proc_get_Reshape_POOrderList @Contact_Id=1372912 ,@Status=default,@CompanyId=default,@ContactId=default,@SearchText=default,@PageNumber=N'1',@PageSize=N'24',@CompanyContactId = 1372757  
  
*/  

CREATE PROCEDURE [dbo].[proc_get_Reshape_POOrderList]
(
	 @Contact_Id INT
	,@Status  VARCHAR(100)   =  NULL
	,@CompanyId	VARCHAR(MAX) =  NULL
	,@ContactId	VARCHAR(MAX) =  Null
	,@SearchText VARCHAR(50) =  Null
	,@PageNumber INT = 1
	,@PageSize   INT = 24
	,@CompanyContactId INT = NULL
)
AS
BEGIN

	SET NOCOUNT ON
 
	DECLARE @is_buyer BIT
	DECLARE @POFileURL					VARCHAR(4000)
	DECLARE @SupplierCompanyId INT     --M2-4979

	DROP TABLE IF EXISTS #Status
	DROP TABLE IF EXISTS #CompanyIds
	DROP TABLE IF EXISTS #ContactIds
	DROP TABLE IF EXISTS #tmp_proc_get_Reshape_POOrder_List_of_CompanyContactIds
	DROP TABLE IF EXISTS #tmp_CompanyContactIds

	CREATE TABLE #Status ([Status] VARCHAR(50))
	CREATE TABLE #CompanyIds (CompanyId VARCHAR(50))
	CREATE TABLE #ContactIds (ContactId VARCHAR(50))
	CREATE TABLE #tmp_proc_get_Reshape_POOrder_List_of_CompanyContactIds( CompanyId INT , ContactId INT )
	CREATE TABLE #tmp_CompanyContactIds (ContactId INT)  --M2-4979

	IF DB_NAME() = 'mp2020_dev'
	BEGIN
		SET @POFileURL = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.uat.test/RFQFiles/'
	END
	ELSE IF DB_NAME() = 'mp2020_uat'
	BEGIN	
		SET @POFileURL = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.uat.test/RFQFiles/'		
	END
	ELSE IF DB_NAME() = 'mp2020_prod'
	BEGIN		
		SET @POFileURL = 'https://files.mfg.com/RFQFiles/'
	END
	
	-- Getting is_buyer information
	SELECT @is_buyer = is_buyer FROM mp_contacts(NOLOCK) WHERE contact_id = @Contact_Id
		
	IF @is_buyer = 0 
	BEGIN
			
		/* M2-4979 : Added below code */
		IF @CompanyContactId IS NOT NULL 
		BEGIN 
		
				IF @CompanyContactId = 0 --All supplier contact ids data as per companyid
				BEGIN
					-- Getting log-in supplier company id  
					SELECT DISTINCT @SupplierCompanyId = company_id FROM mp_contacts(NOLOCK) WHERE contact_id = @Contact_Id
						
					---- Get the list of contacts ids
					INSERT INTO #tmp_CompanyContactIds
					SELECT contact_id FROM mp_contacts(NOLOCK) WHERE company_id = @SupplierCompanyId AND is_buyer = 0
				END
				ELSE
				BEGIN
				
					---- @CompanyContactId is NOT NULL then assigned parameter value of @CompanyContactId inserted 
					INSERT INTO #tmp_CompanyContactIds
					SELECT @CompanyContactId as Contact_Id
					
				END

				INSERT INTO #tmp_proc_get_Reshape_POOrder_List_of_CompanyContactIds
				SELECT DISTINCT c.company_id , c.contact_id 
				FROM mpOrderManagement (NOLOCK) a
				JOIN mp_rfq (NOLOCK) b ON a.rfqid = b.rfq_id
				JOIN mp_contacts (NOLOCK) c ON b.contact_id = c.contact_id
				WHERE a.SupplierContactId IN (SELECT ContactId FROM #tmp_CompanyContactIds)
		END
		ELSE IF @CompanyContactId IS NULL 
		BEGIN		
					---- @CompanyContactId is NULL then assigned parameter value of @Contact_Id inserted 
					INSERT INTO #tmp_CompanyContactIds
					SELECT @Contact_Id as Contact_Id

					INSERT INTO #tmp_proc_get_Reshape_POOrder_List_of_CompanyContactIds
					SELECT DISTINCT c.company_id , c.contact_id 
					FROM mpOrderManagement (NOLOCK) a
					JOIN mp_rfq (NOLOCK) b ON a.rfqid = b.rfq_id
					JOIN mp_contacts (NOLOCK) c ON b.contact_id = c.contact_id
					WHERE a.SupplierContactId = @Contact_Id

		END
		/* */

	END
	ELSE
	BEGIN
		INSERT INTO #tmp_proc_get_Reshape_POOrder_List_of_CompanyContactIds
		SELECT DISTINCT c.company_id , c.contact_id 
		FROM mpOrderManagement (NOLOCK) a
		JOIN mp_rfq (NOLOCK) b ON a.rfqid = b.rfq_id
		JOIN mp_contacts (NOLOCK) c ON  a.SupplierContactId = c.contact_id
		WHERE b.contact_id = @Contact_Id
	END
	
	---- Checking Status values
	IF @Status IS NULL OR @Status = 'NULL'
	BEGIN 
		INSERT INTO #Status VALUES ('Pending'), ('Accepted'), ('Cancelled'), ('Retracted')
	END
	ELSE
	BEGIN
		INSERT INTO #Status
		SELECT VALUE FROM string_split(@Status, ',') 
	END

	
	---- Checking Company id values
	IF @CompanyId IS NOT NULL AND @CompanyId <> 'null'
	BEGIN 
	 	INSERT INTO #CompanyIds
		SELECT VALUE FROM string_split(@CompanyId, ',') 
	END
	ELSE IF @CompanyId IS NULL OR @CompanyId = 'null'
	BEGIN
		INSERT INTO #CompanyIds
		SELECT DISTINCT CompanyId FROM #tmp_proc_get_Reshape_POOrder_List_of_CompanyContactIds
	END

	---- Checking Contact id values
	IF @ContactId IS NOT NULL AND @ContactId <> 'null'
	BEGIN 
	 	INSERT INTO #ContactIds
		SELECT VALUE FROM string_split(@ContactId, ',') 
	END
	ELSE IF @ContactId IS NULL OR @ContactId = 'null'
	BEGIN
		INSERT INTO #ContactIds
		SELECT DISTINCT ContactId FROM #tmp_proc_get_Reshape_POOrder_List_of_CompanyContactIds
	END

	
	 
	IF  @is_buyer = 1 
	BEGIN
			-- po details
			SELECT 
			Unique_id AS [MfgUniqueId] 
			,[rfqid]  AS [RfqId]
			,CASE WHEN RfqId IS NOT NULL THEN 
				REPLACE ( RfqId
					   , RfqId 
					   , 				  
					   case when IsPOExists = 1 THEN  
					   '<a style=''color: blue'' href=''/#/'+ RFQPageName + '?rfqId='+ concat(REPLACE(REPLACE(RfqGuid,'+','%2B'),'=','%3D'),PageLink) + ''' >' + convert(varchar(50),RfqId) + '</a>' 
					   ELSE
						'<a style=''color: blue'' href=''/#/'+ RFQPageName + '?id='+ RfqGuid + ''' >' + convert(varchar(50),RfqId) + '</a>' 
					   END 
					   )
				END AS [AssociatedRFQ] 
			,[PONumber]
			,CASE WHEN PONumber IS NOT NULL THEN 
						REPLACE ( PONumber
					   , PONumber 
					   , 
					   case when IsPOExists = 1 THEN  
					   '<a style=''color: blue'' href=''/#/'+ RFQPageName + '?rfqId='+ concat(REPLACE(REPLACE(RfqGuid,'+','%2B'),'=','%3D'),PageLink) + ''' >' + convert(varchar(50),PONumber) + '</a>' 
					   ELSE
						'<a style=''color: blue'' href=''/#/'+ RFQPageName + '?id='+ RfqGuid + ''' >' + convert(varchar(50),PONumber) + '</a>' 
					   END 
					   )END AS [OrderNumber] 
			,[Status]
			,[CompanyName]
			,[CompanyId]
			,[ContactId]
			,[ContactName]
			,POFileUrl
			FROM 
			(
				SELECT 
					 b.RfqId							AS [rfqid]                 
					, b.Id								AS unique_id
					, b.PONumber						AS [PONumber]
					, b.POStatus						AS [Status]
					, d.[name]							AS [CompanyName]
					, b.SupplierContactId				AS [ContactId]
					, c.first_name + ' ' + c.last_name  AS [ContactName]
					, a.contact_id						AS [BuyerContactId]
					, 'rfq/rfqdetail'					AS [RFQPageName]
					, CASE WHEN b.RfqId IS NOT NULL THEN 1 ELSE 0 END AS IsPOExists
		            , CASE WHEN b.RfqId IS NOT NULL THEN  b.RfqEncryptedId 
		              ELSE ( SELECT   CONVERT(VARCHAR(50), rfq_guid ) FROM mp_rfq(NOLOCK) WHERE mp_rfq.rfq_id = a.rfq_id) END  AS RFQGuid 
					,'&order=Order'						AS PageLink
					, d.company_id						AS [CompanyId]
					--, CASE WHEN b1.file_name IS NULL THEN '' WHEN b1.file_name ='' THEN '' ELSE ISNULL(@POFileURL + REPLACE(b1.file_name,'&' ,'&amp;'),'') END AS POFileUrl 
				    , CASE WHEN b1.file_name IS NULL THEN '' ELSE  REPLACE(b1.file_name,'&' ,'&amp;') END  AS POFileUrl 
				FROM mp_rfq  (NOLOCK) a
				JOIN mpOrderManagement (NOLOCK) b ON b.rfqid = a.rfq_id AND  b.IsDeleted = 0  
					AND a.rfq_status_id NOT IN (16,17,18,20)
				JOIN mp_contacts (NOLOCK) c ON c.contact_id = b.SupplierContactId 
				JOIN mp_companies (NOLOCK) d ON  d.company_id = c.company_id
				LEFT JOIN mp_special_files (NOLOCK) b1 ON b.FileId = b1.FILE_ID
				WHERE a.contact_id = @Contact_Id 
				AND POStatus IN ( SELECT [Status] FROM #Status)
				AND ( d.company_id IN ( SELECT CompanyId FROM #CompanyIds) )
				AND ( b.SupplierContactId IN ( SELECT ContactId FROM #ContactIds) )
				AND ( 
						( 
							b.rfqid like '%' + @SearchText + '%' 
							OR
							b.PONumber like '%' + @SearchText + '%' 
							OR
							d.[name] like '%' + @SearchText + '%' 
						) 
						OR @SearchText IS NULL
					)
			) PO 
			ORDER BY  unique_id DESC
			OFFSET @pagesize * (@pagenumber - 1) ROWS
			FETCH NEXT @pagesize ROWS only	
			
	END
	ELSE
	BEGIN 
		
		-- po details
		SELECT 
		unique_id AS [MfgUniqueId] 
		,[rfqid]  AS [RfqId]
		,CASE WHEN RfqId IS NOT NULL THEN 
				REPLACE ( RfqId
					   , RfqId 
					   , 				  
					   case when IsPOExists = 1 THEN  
					   '<a style=''color: blue'' href=''/#/'+ RFQPageName + '?rfqId='+ concat(REPLACE(REPLACE(RfqGuid,'+','%2B'),'=','%3D'),PageLink) + ''' >' + convert(varchar(50),RfqId) + '</a>' 
					   ELSE
						'<a style=''color: blue'' href=''/#/'+ RFQPageName + '?id='+ RfqGuid + ''' >' + convert(varchar(50),RfqId) + '</a>' 
					   END 
					   )
				END AS [AssociatedRFQ] 
		,[PONumber]
		,CASE WHEN PONumber IS NOT NULL THEN 
	  				   REPLACE ( PONumber
					   , PONumber 
					   , 
					   case when IsPOExists = 1 THEN  
					   '<a style=''color: blue'' href=''/#/'+ RFQPageName + '?rfqId='+ concat(REPLACE(REPLACE(RfqGuid,'+','%2B'),'=','%3D'),PageLink) + ''' >' + convert(varchar(50),PONumber) + '</a>' 
					   ELSE
						'<a style=''color: blue'' href=''/#/'+ RFQPageName + '?id='+ RfqGuid + ''' >' + convert(varchar(50),PONumber) + '</a>' 
					   END 
					   ) END AS [OrderNumber] 
		,[Status]
		,[CompanyName]
		,[CompanyId]
		,[ContactId]
		,[ContactName]
		,POFileUrl
		FROM 
		(
			SELECT 
				  b.RfqId                           AS [rfqid]                 
				, b.Id							    AS unique_id
				, b.PONumber						AS [PONumber]
				, b.POStatus						AS [Status]
				, d.[name]							AS [CompanyName]
				, SupplierContactId					AS [SupplierContactId]
				, a.contact_id						AS [ContactId]
				, c.first_name + ' ' + c.last_name  AS [ContactName]
				, 'supplier/supplerRfqDetails'      AS [RFQPageName]
				, CASE WHEN b.RfqId IS NOT NULL THEN 1 ELSE 0 END AS IsPOExists
		        , CASE WHEN b.RfqId IS NOT NULL THEN  b.RfqEncryptedId 
		          ELSE ( SELECT   convert(varchar(50), rfq_guid ) from mp_rfq(nolock) where mp_rfq.rfq_id = a.rfq_id) END  AS RFQGuid
				, '&quotes=Quotes'					AS PageLink
				, d.company_id						AS [CompanyId]
				--, CASE WHEN b1.file_name IS NULL THEN '' WHEN b1.file_name ='' THEN '' ELSE ISNULL(@POFileURL + REPLACE(b1.file_name,'&' ,'&amp;'),'') END AS POFileUrl 
			    , CASE WHEN b1.file_name IS NULL THEN '' ELSE  REPLACE(b1.file_name,'&' ,'&amp;') END  AS POFileUrl 
			FROM mp_rfq (NOLOCK) a
			LEFT JOIN mpOrderManagement  (NOLOCK) b ON b.rfqid = a.rfq_id AND b.IsDeleted = 0 
				AND a.rfq_status_id NOT IN (16,17,18,20)
			JOIN mp_contacts (NOLOCK) c on c.contact_id = a.contact_id
			JOIN mp_companies (NOLOCK) d ON  d.company_id = c.company_id
			LEFT JOIN mp_special_files (NOLOCK) b1 ON b.FileId = b1.FILE_ID
			WHERE  
			----b.SupplierContactId = @Contact_Id  ---- commented with M2-4979
			b.SupplierContactId IN (SELECT  ContactId FROM #tmp_CompanyContactIds ) ---- condition modified with M2-4979
			AND POStatus IN ( SELECT [Status] FROM #Status)
			AND ( d.company_id IN ( SELECT CompanyId FROM #CompanyIds) )
			AND ( a.contact_id IN ( SELECT ContactId FROM #ContactIds) )
			AND ( 
						( 
							b.rfqid like '%' + @SearchText + '%' 
							OR
							b.PONumber like '%' + @SearchText + '%' 
							OR
							d.[name] like '%' + @SearchText + '%' 
						) 
				
						OR @SearchText IS NULL
					)
		) PO 
		ORDER BY unique_id DESC
		OFFSET @pagesize * (@pagenumber - 1) ROWS
		FETCH NEXT @pagesize ROWS only	

	END


	DROP TABLE IF EXISTS #Status
	DROP TABLE IF EXISTS #CompanyIds
	DROP TABLE IF EXISTS #ContactIds
	DROP TABLE IF EXISTS #tmp_proc_get_Reshape_POOrder_List_of_CompanyContactIds

	END
