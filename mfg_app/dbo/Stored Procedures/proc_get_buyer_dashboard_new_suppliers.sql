
/*
EXEC proc_get_buyer_dashboard_new_suppliers @BuyerId =1349461 
*/
CREATE PROCEDURE [dbo].[proc_get_buyer_dashboard_new_suppliers]
(
	@BuyerId INT
)

AS
BEGIN
		SET NOCOUNT ON
		/*
		-- Created	:	May 29, 2020
					:	M2-2904 Buyer - New Manufacturer module - DB
		*/

		
		DECLARE @SupplierCount INT

		DROP TABLE IF EXISTS #buyer_dashboard_new_suppliers
		DROP TABLE IF EXISTS #suppliers_capabilities

		SELECT @SupplierCount= COUNT(1)
		FROM mp_buyer_dashboard_new_suppliers  (NOLOCK) 
		WHERE 
			BuyerId = @BuyerId
			AND IsMessageSent = 0
			AND IsProfileViewed = 0
			AND ValidUntil >=  GETUTCDATE()


		IF @SupplierCount = 0
		BEGIN
			UPDATE a SET a.ValidUntil = DATEADD(DAY,7,GETUTCDATE())
			FROM mp_buyer_dashboard_new_suppliers a (NOLOCK) 
			JOIN
			(			
				SELECT 
					TOP 2 
					Id
				FROM mp_buyer_dashboard_new_suppliers  (NOLOCK) 
				WHERE 
					BuyerId = @BuyerId
					AND IsMessageSent = 0
					AND IsProfileViewed = 0
					AND ValidUntil IS NULL
			
			) b ON a.Id = b.Id
		END
		ELSE IF @SupplierCount = 1
		BEGIN
			UPDATE a SET a.ValidUntil = DATEADD(DAY,7,GETUTCDATE())
			FROM mp_buyer_dashboard_new_suppliers a (NOLOCK) 
			JOIN
			(			
				SELECT 
					TOP 1
					Id
				FROM mp_buyer_dashboard_new_suppliers  (NOLOCK) 
				WHERE 
					BuyerId = @BuyerId
					AND IsMessageSent = 0
					AND IsProfileViewed = 0
					AND ValidUntil IS NULL
			
			) b ON a.Id = b.Id
		END

		SELECT 
			a.BuyerId
			,a.SupplierId
			,c.first_name +' '+c.last_name AS Supplier
			,c.company_id SupplierCompanyId
			,IIF(filetype.filetype_id=6,spefile.FILE_NAME, NULL) AS SupplierCompanyLogo 
			,d.name AS SupplierCompany 
			,e.territory_classification_name AS SupplierLocation
			INTO #buyer_dashboard_new_suppliers
		FROM mp_buyer_dashboard_new_suppliers a (NOLOCK)
		JOIN mp_contacts c (NOLOCK) ON a.SupplierId = c.contact_id 
		JOIN mp_companies d (NOLOCK) ON c.company_id = d.company_id 
		LEFT JOIN mp_mst_territory_classification e (NOLOCK) ON d.manufacturing_location_id = e.territory_classification_id
		LEFT JOIN mp_special_files spefile (NOLOCK)
			ON c.company_id=spefile.COMP_ID and c.contact_id=spefile.CONT_ID and filetype_id = 6  
		LEFT JOIN mp_mst_filetype filetype  (NOLOCK) ON(spefile.FILETYPE_ID = filetype.filetype_id) 
		WHERE 
			a.BuyerId = @BuyerId
			AND a.IsMessageSent = 0
			AND a.IsProfileViewed = 0
			AND a.ValidUntil >=  GETUTCDATE()

		SELECT SupplierCompanyId ,Capabiities
		INTO #suppliers_capabilities
		FROM 
		(
			SELECT DISTINCT a.company_id SupplierCompanyId, c.discipline_name Capabiities , ROW_NUMBER() OVER(PARTITION BY a.company_id  ORDER BY a.company_id , c.discipline_name)  RN
			FROM mp_company_processes a (NOLOCK)
			JOIN mp_mst_part_category b (NOLOCK) ON a.part_category_id = b.part_category_id
			JOIN mp_mst_part_category c (NOLOCK) ON c.part_category_id = b.parent_part_category_id
			WHERE EXISTS 
			(SELECT * FROM #buyer_dashboard_new_suppliers WHERE a.company_id = SupplierCompanyId)
			UNION
			SELECT a.company_id SupplierCompanyId, c.discipline_name Capabiities , ROW_NUMBER() OVER(PARTITION BY a.company_id  ORDER BY a.company_id , c.discipline_name)  RN
			FROM mp_gateway_subscription_company_processes a (NOLOCK)
			JOIN mp_mst_part_category b (NOLOCK) ON a.part_category_id = b.part_category_id
			JOIN mp_mst_part_category c (NOLOCK) ON c.part_category_id = b.parent_part_category_id
			WHERE EXISTS 
			(SELECT * FROM #buyer_dashboard_new_suppliers WHERE a.company_id = SupplierCompanyId)
		) A
		WHERE RN <=3

		SELECT 
			a.BuyerId	
			,a.SupplierId
			,a.Supplier	
			,a.SupplierCompanyId	
			,a.SupplierCompanyLogo	
			,a.SupplierCompany	
			,a.SupplierLocation	
			,b.CapabiitiesList
		FROM #buyer_dashboard_new_suppliers a
		LEFT JOIN
		(
			SELECT  SupplierCompanyId
			   ,STUFF((SELECT DISTINCT ', ' + CAST(Capabiities AS VARCHAR(500)) [text()]
				 FROM #suppliers_capabilities 
				 WHERE SupplierCompanyId = t.SupplierCompanyId
				 FOR XML PATH(''), TYPE)
				.value('.','NVARCHAR(MAX)'),1,2,' ') CapabiitiesList
			FROM #suppliers_capabilities t
			GROUP BY SupplierCompanyId
		) b ON a.SupplierCompanyId = b.SupplierCompanyId


		DROP TABLE IF EXISTS #buyer_dashboard_new_suppliers
		DROP TABLE IF EXISTS #suppliers_capabilities

END
