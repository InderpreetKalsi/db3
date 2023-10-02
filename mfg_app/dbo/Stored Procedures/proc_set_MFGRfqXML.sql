/*

TRUNCATE TABLE [XML_MFGRfq]
GO
EXEC proc_set_MFGRfqXML
GO
SELECT * FROM [XML_MFGRfq] ORDER BY [RecordDate] DESC

*/

	CREATE PROCEDURE [dbo].[proc_set_MFGRfqXML]
	AS
	BEGIN
		
		/* M2-3726 New RFQ XML file to push to the Directory - DB */
		
		SET NOCOUNT ON
		
		DECLARE @MaxDate				DATETIME2	 		 		 
		DECLARE @TodaysDate				DATETIME2 =  GETUTCDATE()
		DECLARE @RfqDeepLink			VARCHAR(1000) 
		DECLARE @RfqThumbnails			VARCHAR(1000) 
		DECLARE @RfqDefaultThumbnails			VARCHAR(1000) 

		--TRUNCATE TABLE [XML_MFGRfq]		

		IF DB_NAME() = 'mp2020_dev'
		BEGIN
			SET @RfqDeepLink = 'http://qa.mfg2020.com/#/supplier/supplerRfqDetails?id='
			SET @RfqThumbnails = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.public/thumbnails/'
			
		END
		ELSE IF DB_NAME() = 'mp2020_uat'
		BEGIN
			SET @RfqDeepLink = 'https://uatapp.mfg.com/#/supplier/supplerRfqDetails?id='
			SET @RfqThumbnails = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020/thumbnails/'
			
		END
		ELSE IF DB_NAME() = 'mp2020_prod'
		BEGIN
			SET @RfqDeepLink = 'https://app.mfg.com/#/supplier/supplerRfqDetails?id='
			SET @RfqThumbnails = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.public/thumbnails/'
			
		END

	
		SET @RfqDefaultThumbnails = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020/thumbnails/3-d-big.png'
		SET @MaxDate =  ISNULL((SELECT MAX ([CreatedDate]) FROM [XML_MFGRfq] (NOLOCK)) , '2020-12-01 00:00:00.101' )
		SET @MaxDate =  DateAdd(millisecond,1,@MaxDate)



		DECLARE @TransactionStatus		VARCHAR(500) = 'Failed'

		BEGIN TRAN
		BEGIN TRY

			INSERT INTO [XML_MFGRfq] 
			(
				[RfqId],[RfqName],[RfqThumbnail],[RfqDesc],[ProcessId],[Process],[Technique],[Material],[PostProcess],[IsLargePart],
				[MaxQuantity],[RfqDeepLinkUrl],[BuyerState],[BuyerCountry],[BuyerIndustry],[RecordDate],[CreatedDate]
			)	 		 
		-- 'New RFQ Available in [Marketplace]' 
			SELECT
				e.rfq_id AS RfqId
				,e.rfq_name AS RfqName
				,ISNULL(@RfqThumbnails+j.file_name,@RfqDefaultThumbnails) AS RfqThumbnail
				,e.rfq_description AS RfqDesc
				,m.part_category_id AS ProcessId
				,m.discipline_name AS Process
				,l.discipline_name AS Technique
				,n.material_name AS Material			
				,o.value AS PostProcess
				,p.IsLargePart AS IsLargePart
				,r.MaxPartQty AS MaxQuantity
				, @RfqDeepLink + CONVERT(VARCHAR(500),e.rfq_guid) AS RfqDeepLinkUrl
				, d.REGION_NAME AS BuyerState
				, c.country_name AS BuyerCountry
				, s.listIndustries AS BuyerIndustry
				,f.status_date  AS RecordDate
				,@TodaysDate AS [CreatedDate]
			FROM
			mp_rfq                        (NOLOCK) e
			JOIN 
			(
				SELECT rfq_id ,status_date , ROW_NUMBER() OVER (PARTITION BY rfq_id ORDER BY rfq_id , status_date DESC) RN 
				FROM mp_rfq_release_history    (NOLOCK)
		
			) f ON e.rfq_id = f.rfq_id AND f.RN = 1
			JOIN mp_contacts            (NOLOCK) a ON e.contact_id = a.contact_id
			LEFT JOIN mp_addresses        (NOLOCK) b ON a.address_id = b.address_id
			LEFT JOIN mp_mst_country    (NOLOCK) c ON b.country_id = c.country_id
			LEFT JOIN mp_mst_region        (NOLOCK) d ON b.region_id = d.region_id AND d.region_id <> 0
			LEFT JOIN mp_special_files    (NOLOCK) j ON e.file_id = j.file_id
			JOIN mp_rfq_parts            (NOLOCK) k ON e.rfq_id = k.rfq_id and k.is_rfq_part_default = 1
			JOIN mp_mst_part_category    (NOLOCK) l ON k.part_category_id = l.part_category_id
			JOIN mp_mst_part_category    (NOLOCK) m ON l.parent_part_category_id = m.part_category_id
			JOIN mp_mst_materials    (NOLOCK) n ON k.material_id = n.material_id
			LEFT JOIN mp_system_parameters (NOLOCK) o ON k.Post_Production_Process_id = o.id AND o.sys_key = '@PostProdProcesses'
			JOIN mp_parts (NOLOCK) p on k.part_id = p.part_id
			LEFT JOIN
			(       
				SELECT rfq_part_id, Max(part_qty) AS MaxPartQty from mp_rfq_part_quantity group by rfq_part_id       
			) AS r on k.rfq_part_id = r.rfq_part_id
			Left JOIN
			(
				SELECT company_id, STRING_AGG(b.industry_key,',') listIndustries
				FROM mp_company_industries a
				join mp_mst_industries b on a.industry_type_id = b.industry_id            
				GROUP BY company_id                  
  
			) AS s on a.company_id  = s.company_id
			WHERE 
			e.rfq_id  not in (SELECT cloned_rfq_id FROM mp_rfq_cloned_logs (nolock)) 
			AND f.status_date  BETWEEN  @MaxDate AND @TodaysDate
						AND a.IsTestAccount = 0
						AND e.rfq_status_id in  (3 , 5, 6 ,16, 17 ,18 ,20) 
							
			ORDER BY RecordDate DESC			 		 

			Update XML_MFGRfq SET IsProcessed = 1 where IsProcessed = 0

			SET @TransactionStatus = 'Success' 	


			IF @TransactionStatus = 'Success'
				COMMIT
			ELSE
				ROLLBACK

			SELECT @TransactionStatus TransactionStatus

		END TRY
		BEGIN CATCH
			ROLLBACK
		
			SET @TransactionStatus = 'Failed - ' + Error_Message()
			SELECT @TransactionStatus TransactionStatus

		END CATCH

	END
