
/*
 select * from mpOrderManagement where  rfqid = 1162128
 EXEC [proc_get_Reshape_RfqPODetails] @RfqId = 1192815 , @RfqEncryptedId = 'J7Ej7XYTOOf7cqRpvwhreQ=='
*/
CREATE PROCEDURE [dbo].[proc_get_Reshape_RfqPODetails]
(
	@RfqId INT
	,@RfqEncryptedId VARCHAR(100)
)
AS
 
BEGIN
 
	-- M2-4849 Create new external facing API for Order Management - DB
	SET NOCOUNT ON

	DROP TABLE IF EXISTS #tmp_po_info
	DROP TABLE IF EXISTS #tmp_rfq_info
	DROP TABLE IF EXISTS #tmp_rfq_part_info
	DROP TABLE IF EXISTS #tmp_contacts_buyer_info
	DROP TABLE IF EXISTS #tmp_contacts_buyer_shipping_info
	DROP TABLE IF EXISTS #tmp_contacts_manufacturer_info

	DECLARE @CompanyLogo				VARCHAR(4000)
	DECLARE @RfqDetailUrl_Supplier		VARCHAR(4000)
	DECLARE @SupplierPublicProfileUrl	VARCHAR(4000)
	DECLARE @POFileURL					VARCHAR(4000)
	DECLARE @RfqPartFileURL				VARCHAR(4000)
	DECLARE @RfqThumbnail				VARCHAR(4000)
	
	
	DECLARE @RfqPOInfo					VARCHAR(8000)
	DECLARE @RfqPartInfo				VARCHAR(8000)
	DECLARE @ReplacePartText			VARCHAR(8000)= '"order_line_items":{"parts":""}'

	DECLARE @TransactionId				VARCHAR(255) = NEWID()

	BEGIN TRY

		IF DB_NAME() = 'mp2020_qa_app_2'
		BEGIN

			SET @CompanyLogo = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020/logos/'
			SET @RfqThumbnail = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020/thumbnails/'
			SET @RfqDetailUrl_Supplier = 'https://qaapp2.mfg.com/#/supplier/supplerRfqDetails?rfqId='+@RfqEncryptedId
			SET @POFileURL = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.uat.test/RFQFiles/'
			SET @RfqPartFileURL = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.uat.test/RFQFiles/' 
						
		END
		ELSE IF DB_NAME() = 'mp2020_dev'
		BEGIN

			SET @CompanyLogo = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.public/logos/'
			SET @RfqThumbnail = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020/thumbnails/'
			SET @RfqDetailUrl_Supplier = 'https://qaapp.mfg.com/#/supplier/supplerRfqDetails?rfqId='+@RfqEncryptedId
			SET @POFileURL = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.uat.test/RFQFiles/'
			SET @RfqPartFileURL = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.uat.test/RFQFiles/' 
		

		END
		ELSE IF DB_NAME() = 'mp2020_uat'
		BEGIN

			SET @CompanyLogo = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020/logos/'
			SET @RfqThumbnail = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020/thumbnails/'
			SET @RfqDetailUrl_Supplier = 'https://uatapp.mfg.com/#/supplier/supplerRfqDetails?rfqId='+@RfqEncryptedId
			SET @POFileURL = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.uat.test/RFQFiles/'
			SET @RfqPartFileURL = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.uat.test/RFQFiles/' 

		END
		ELSE IF DB_NAME() = 'mp2020_prod'
		BEGIN

			SET @CompanyLogo = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.public/logos/'
			SET @RfqThumbnail = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.public/thumbnails/' 
			SET @RfqDetailUrl_Supplier = 'https://app.mfg.com/#/supplier/supplerRfqDetails?rfqId='+@RfqEncryptedId
			----SET @POFileURL = 'https://files.mfg.com/RFQFiles/'
			SET @POFileURL = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020/RFQFiles/'
			SET @RfqPartFileURL = 'https://files.mfg.com/RFQFiles/' 
		

		END
	
		UPDATE mpOrderManagement  SET IsDeleted = 0 WHERE RfqId = @RfqId  

		-- po details
		SELECT 
			TOP 1 
			@RfqId AS rfq_id
			, Id							AS unique_id
			, TransactionId					AS transaction_id
			, PONumber						AS number
			, POStatus						AS status
			, CONVERT(VARCHAR,PODate,120)	AS date_utc
			, SupplierContactId				AS supplier_contact_id
			, CASE WHEN b.file_name IS NULL THEN '' WHEN b.file_name ='' THEN '' ELSE ISNULL(@POFileURL + REPLACE(b.file_name,'&' ,'&amp;'),'') END AS file_url  
			, ShippingAddressId				AS po_shipping_address_id
			, PaymentTerm					AS po_paymentterm
			, ISNULL(Notes,'')              AS po_Notes
		INTO #tmp_po_info
		FROM mpOrderManagement (NOLOCK) a
		LEFT JOIN mp_special_files (NOLOCK) b ON a.FileId = b.FILE_ID
		WHERE RfqId = @RfqId 
		ORDER BY Id DESC
	
	
		-- rfq details
		SELECT 
			@RfqId AS rfq_id
			, contact_id			AS buyer_contact_id
			, a.rfq_name			AS rfq_name
			, b.description			AS term
			, special_instruction_to_manufacturer AS special_instruction
			, @RfqDetailUrl_Supplier AS rfq_detail_url_default
			, c.description			AS status
			, CONVERT(VARCHAR,DeliveryDate,120)		AS delivery_date_utc
			, CONVERT(VARCHAR,award_date,120)		AS award_date_utc
			, CONVERT(VARCHAR,rfq_created_on,120)	AS rfq_created_utc
			, COALESCE(@RfqThumbnail+rfqthumbnail.File_Name,'')  AS  rfq_thumbnail
		INTO #tmp_rfq_info
		FROM mp_rfq (NOLOCK) a
		LEFT JOIN mp_mst_paymentterm		(NOLOCK)  b ON a.payment_term_id = b.paymentterm_id
		LEFT JOIN mp_mst_rfq_buyerstatus	(NOLOCK)  c ON a.rfq_status_id = c.rfq_buyerstatus_id
		LEFT JOIN mp_special_files			(NOLOCK)  rfqthumbnail ON rfqthumbnail.file_id = a.file_id
		WHERE rfq_id = @RfqId
	
		-- rfq part details
		SELECT 
			a.rfq_id
			,a.rfq_part_id		AS [rfq_part_id]
			,b.part_name		AS [rfq_part_name]
			,b.part_number		AS [rfq_part_no]
			,d.discipline_name	AS [rfq_part_manufacturing_process]
			,CASE WHEN d.discipline_name = c.discipline_name THEN '' ELSE c.discipline_name END	AS [rfq_part_manufacturing_technique]
			,f.material_name_en		AS [rfq_part_material]
			,e.value				AS [rfq_part_post_process]
			,g.value				AS [rfq_part_unit_of_measure]
			,h.value				AS [rfq_part_quantity_unit]
			--,a.*
			--,b.*
			--,h.*
		INTO #tmp_rfq_part_info
		FROM mp_rfq_parts  (NOLOCK) a
		JOIN mp_parts (NOLOCK) b ON a.part_id = b.part_id
		LEFT JOIN mp_mst_part_category (NOLOCK) c ON a.part_category_id = c.part_category_id
		LEFT JOIN mp_mst_part_category (NOLOCK) d ON c.parent_part_category_id = d.part_category_id
		LEFT JOIN mp_system_parameters (NOLOCK) e ON a.Post_Production_Process_id = e.id
		LEFT JOIN mp_mst_materials (NOLOCK) f ON b.material_id = f.material_id
		LEFT JOIN mp_system_parameters (NOLOCK) g ON b.part_size_unit_id = g.id
		LEFT JOIN mp_system_parameters (NOLOCK) h ON b.part_qty_unit_id = h.id
		WHERE rfq_id = @RfqId AND b.status_id = 2
		ORDER BY [rfq_part_id]


		-- supplier details
		SELECT 
			@RfqId AS rfq_id
			, a.company_id AS supplier_company_id
			, g.name AS supplier_company_name
			, CASE WHEN h.file_name IS NULL THEN '' WHEN h.file_name ='' THEN '' ELSE ISNULL(@CompanyLogo + REPLACE(h.file_name,'&' ,'&amp;'),'') END as supplier_company_logo 
			, b.Email AS supplier_email
			, f.contact_id as supplier_id
			, f.first_name +' '+ f.last_name AS supplier_name
			--, f.first_name  AS supplier_first_name
			--, f.last_name AS supplier_last_name
			, i.communication_value AS supplier_phone
			,CASE WHEN LEN(ISNULL(c.address1,'')) = 0 THEN '' ELSE REPLACE(c.address1,'?','') END AS supplier_address1
			,CASE WHEN LEN(ISNULL(c.address2,'')) = 0 THEN '' ELSE REPLACE(c.address1,'?','') END AS supplier_address2  ---- Added Address2 field in address 
			,CASE WHEN LEN(ISNULL(c.address4,'')) = 0 THEN '' ELSE REPLACE(c.address4,'?','') END AS supplier_city
			,CASE WHEN LEN(ISNULL(e.REGION_NAME,'')) = 0 THEN '' ELSE e.REGION_NAME  END AS supplier_state
			,CASE WHEN LEN(ISNULL(c.address3,'')) = 0 THEN '' ELSE c.address3  END AS supplier_zip
			,CASE WHEN LEN(ISNULL(d.country_name,'')) = 0  THEN '' ELSE d.country_name END AS supplier_country
		INTO #tmp_contacts_manufacturer_info 
		FROM 
		(
			SELECT 
				company_id 
				, address_id
				, ROW_NUMBER() OVER(PARTITION BY company_id ORDER BY company_id , is_admin DESC, contact_id ) rn 
			FROM mp_contacts		(NOLOCK) 
			WHERE company_id  IN
			(
				SELECT company_id FROM mp_contacts		(NOLOCK)  
				WHERE
				contact_id  IN
				(
					SELECT supplier_contact_id FROM #tmp_po_info
				)
			)
		) a 
		JOIN mp_contacts			f (NOLOCK) ON a.company_id = f.company_id   AND a.rn=1
		JOIN AspNetUsers			b (NOLOCK) ON f.user_id = b.id 
		JOIN mp_companies			g (NOLOCK) ON a.company_id = g.company_id  
		LEFT JOIN mp_addresses		c (NOLOCK) ON a.address_id = c.address_id
		LEFT JOIN mp_mst_country	d (NOLOCK) ON c.country_id = d.country_id
		LEFT JOIN mp_mst_region		e (NOLOCK) ON c.region_id = e.region_id AND e.region_id <> 0
		LEFT JOIN 
		(
			SELECT COMP_ID ,file_name , ROW_NUMBER() OVER(PARTITION BY COMP_ID ORDER BY COMP_ID,FILE_ID DESC)  RN  FROM mp_special_files (NOLOCK) WHERE FILETYPE_ID = 6 AND IS_DELETED = 0
		) h ON a.company_id = h.COMP_ID AND h.RN = 1
		LEFT JOIN mp_communication_details (NOLOCK) i ON f.contact_id  = i.contact_id AND communication_type_id = 1
		WHERE f.contact_id IN 
		(
			SELECT supplier_contact_id FROM #tmp_po_info
		)
	
		-- buyer bill details
		SELECT 
			@RfqId AS rfq_id
			, a.company_id AS buyer_company_id
			, g.name AS buyer_bill_company
			, CASE WHEN h.file_name IS NULL THEN '' WHEN h.file_name ='' THEN '' ELSE ISNULL(@CompanyLogo + REPLACE(h.file_name,'&' ,'&amp;'),'') END as buyer_bill_company_logo 
			, b.Email AS buyer_bill_email
			, a.contact_id AS buyer_id
			, a.first_name +' '+ a.last_name AS buyer_bill_name
			--, a.first_name  AS buyer_first_name
			--, a.last_name AS buyer_last_name
			, i.communication_value AS buyer_bill_phone
			,CASE WHEN LEN(ISNULL(c.address1,'')) = 0 THEN '' ELSE REPLACE(c.address1,'?','') END AS buyer_bill_address1
			,CASE WHEN LEN(ISNULL(c.address2,'')) = 0 THEN '' ELSE REPLACE(c.address1,'?','') END AS buyer_bill_address2  ---- Added Address2 field in address 
			,CASE WHEN LEN(ISNULL(c.address4,'')) = 0 THEN '' ELSE REPLACE(c.address4,'?','') END AS buyer_bill_city
			,CASE WHEN LEN(ISNULL(e.REGION_NAME,'')) = 0 THEN '' ELSE e.REGION_NAME  END AS buyer_bill_state
			,CASE WHEN LEN(ISNULL(c.address3,'')) = 0 THEN '' ELSE c.address3  END AS buyer_bill_zip
			,CASE WHEN LEN(ISNULL(d.country_name,'')) = 0  THEN '' ELSE d.country_name END AS buyer_bill_country
		INTO #tmp_contacts_buyer_info
		FROM 
		(
			SELECT 
				company_id , contact_id , first_name , last_name , is_buyer , address_id, IsTestAccount , [user_id] 
				, ROW_NUMBER() OVER(PARTITION BY company_id ORDER BY company_id , is_admin DESC, contact_id ) rn 
			FROM mp_contacts		(NOLOCK) 
			WHERE 
			contact_id  IN
				(
					SELECT buyer_contact_id FROM #tmp_rfq_info
				)
		) a 
		JOIN AspNetUsers			b (NOLOCK) ON a.user_id = b.id AND a.rn=1
		JOIN mp_companies			g (NOLOCK) ON a.company_id = g.company_id
		LEFT JOIN mp_addresses		c (NOLOCK) ON a.address_id = c.address_id
		LEFT JOIN mp_mst_country	d (NOLOCK) ON c.country_id = d.country_id
		LEFT JOIN mp_mst_region		e (NOLOCK) ON c.region_id = e.region_id AND e.region_id <> 0
		LEFT JOIN 
		(
			SELECT COMP_ID ,file_name , ROW_NUMBER() OVER(PARTITION BY COMP_ID ORDER BY COMP_ID,FILE_ID DESC)  RN  FROM mp_special_files (NOLOCK) WHERE FILETYPE_ID = 6 AND IS_DELETED = 0
		) h ON a.company_id = h.COMP_ID AND h.RN = 1
		LEFT JOIN mp_communication_details (NOLOCK) i ON a.contact_id  = i.contact_id AND communication_type_id = 1

		-- buyer shipping details
		SELECT 
			@RfqId AS rfq_id
			, CASE WHEN LEN(ISNULL(c.address1,'')) = 0 THEN '' ELSE REPLACE(c.address1,'?','') END AS buyer_ship_address1
			,CASE WHEN LEN(ISNULL(c.address2,'')) = 0 THEN '' ELSE REPLACE(c.address2,'?','') END AS buyer_ship_address2  ---- Added Address2 field in address 
			,CASE WHEN LEN(ISNULL(c.address4,'')) = 0 THEN '' ELSE REPLACE(c.address4,'?','') END AS buyer_ship_city
			,CASE WHEN LEN(ISNULL(e.REGION_NAME,'')) = 0 THEN '' ELSE e.REGION_NAME  END AS buyer_ship_state
			,CASE WHEN LEN(ISNULL(c.address3,'')) = 0 THEN '' ELSE c.address3  END AS buyer_ship_zip
			,CASE WHEN LEN(ISNULL(d.country_name,'')) = 0  THEN '' ELSE d.country_name END AS buyer_ship_country
			,e.region_id AS buyer_ship_region_id
			,d.country_id AS buyer_ship_country_id
		INTO #tmp_contacts_buyer_shipping_info
		FROM 
		#tmp_po_info	a (NOLOCK)
		LEFT JOIN mp_addresses		c (NOLOCK) ON a.po_shipping_address_id = c.address_id
		LEFT JOIN mp_mst_country	d (NOLOCK) ON c.country_id = d.country_id
		LEFT JOIN mp_mst_region		e (NOLOCK) ON c.region_id = e.region_id AND e.region_id <> 0
	
	
		-- supplier public profile url
		DECLARE @SupplierCompanyId INT = (SELECT supplier_company_id FROM #tmp_contacts_manufacturer_info)
		DROP TABLE IF EXISTS #tmp_supplier_public_profile
		CREATE TABLE #tmp_supplier_public_profile (CommunityCompanyProfile VARCHAR(4000) ,	ProfileDetailUrl  VARCHAR(4000))

		INSERT INTO #tmp_supplier_public_profile 
		EXEC proc_get_CommunityCompanyProfileURL @CompanyId = @SupplierCompanyId 

		SET @RfqPOInfo = 
		(
			SELECT 
			(
				SELECT
					rfq.rfq_id					AS 'rfq_id'
					,
					(
						SELECT a.rfq_quote_SupplierQuote_id
						FROM mp_rfq_quote_SupplierQuote (NOLOCK) a
						WHERE a.rfq_id =  @RfqId 
						AND a.contact_id IN  (SELECT supplier_contact_id FROM #tmp_po_info)
						AND a.is_quote_submitted =1
						AND a.is_rfq_resubmitted =0
					) AS 'quote_id'
					,'kx5HSA2nXC8w5Ovbg0b6gn1V6Kq05Dgj' AS 'secret'
					,'Pending'					AS 'status'
					,ISNULL(purchase_order.po_Notes, 'N/A')	AS 'buyer_note'
					,rfq.delivery_date_utc		AS 'delivered_by'
					,rfq.rfq_created_utc		AS 'order_created_by'
					,buyer_billing.buyer_bill_name		AS 'buyer_name'
					--,buyer_billing.buyer_first_name		AS 'buyer_first_name'
					--,buyer_billing.buyer_last_name      AS 'buyer_last_name'
					,purchase_order.transaction_id		AS 'external_id'
					,rfq.term					AS 'term'
					,''							AS 'order_line_items.parts'
					,''							AS 'purchase_order.po_name'
					,purchase_order.unique_id 	AS 'purchase_order.po_mfg_unique_id' 	
					,purchase_order.number		AS 'purchase_order.po_number' 
					,purchase_order.date_utc	AS 'purchase_order.po_date'	
					,''							AS 'purchase_order.po_delivery_date'
					,purchase_order.po_paymentterm					AS 'purchase_order.po_term'
					,purchase_order.file_url	AS 'purchase_order.po_file_url'	
			
					,buyer_billing.buyer_bill_name			AS 'purchase_order.buyer.bill_name'
					--,buyer_billing.buyer_first_name         AS 'purchase_order.buyer.bill_first_name'
					--,buyer_billing.buyer_last_name          AS 'purchase_order.buyer.bill_last_name'
					,buyer_billing.buyer_bill_company		AS 'purchase_order.buyer.bill_company'
					,buyer_billing.buyer_bill_address1		AS 'purchase_order.buyer.bill_address1'
					,buyer_billing.buyer_bill_address2		AS 'purchase_order.buyer.bill_address2'
					,buyer_billing.buyer_bill_city			AS 'purchase_order.buyer.bill_city'
					,buyer_billing.buyer_bill_state			AS 'purchase_order.buyer.bill_state'
					,buyer_billing.buyer_bill_zip			AS 'purchase_order.buyer.bill_zip'
					,buyer_billing.buyer_bill_country		AS 'purchase_order.buyer.bill_country'
					,buyer_billing.buyer_bill_phone			AS 'purchase_order.buyer.bill_phone'
					,buyer_billing.buyer_bill_email			AS 'purchase_order.buyer.bill_email'
					,buyer_billing.buyer_company_id			AS 'purchase_order.buyer.bill_company_id'
					,buyer_billing.buyer_id					AS 'purchase_order.buyer.bill_buyer_id'		
					,buyer_billing.buyer_bill_company_logo	AS 'purchase_order.buyer.bill_company_logo'
					,buyer_shipping.buyer_ship_address1		AS 'purchase_order.buyer.ship_address1'
					,buyer_shipping.buyer_ship_address2		AS 'purchase_order.buyer.ship_address2'
					,buyer_shipping.buyer_ship_city			AS 'purchase_order.buyer.ship_city'
					,buyer_shipping.buyer_ship_state		AS 'purchase_order.buyer.ship_state'
					,buyer_shipping.buyer_ship_zip			AS 'purchase_order.buyer.ship_zip'
					,buyer_shipping.buyer_ship_country		AS 'purchase_order.buyer.ship_country'
					,supplier.supplier_name					AS 'purchase_order.supplier.ship_name'
					--,supplier.supplier_first_name			AS 'purchase_order.supplier.ship_first_name'
					--,supplier.supplier_last_name			AS 'purchase_order.supplier.ship_last_name'
					,supplier.supplier_company_name			AS 'purchase_order.supplier.ship_company'
					,supplier.supplier_address1				AS 'purchase_order.supplier.ship_address1'
					,supplier.supplier_address2				AS 'purchase_order.supplier.ship_address2'
					,supplier.supplier_city					AS 'purchase_order.supplier.ship_city'
					,supplier.supplier_state				AS 'purchase_order.supplier.ship_state'
					,supplier.supplier_zip					AS 'purchase_order.supplier.ship_zip'
					,supplier.supplier_country				AS 'purchase_order.supplier.ship_country'
					,supplier.supplier_phone				AS 'purchase_order.supplier.ship_phone'
					,supplier.supplier_email				AS 'purchase_order.supplier.ship_email'
					,''										AS 'purchase_order.supplier.special_instruction'
					,supplier.supplier_company_id			AS 'purchase_order.supplier.ship_company_id'
					,supplier.supplier_id					AS 'purchase_order.supplier.ship_supplier_id'
					,supplier.supplier_company_logo			AS 'purchase_order.supplier.ship_company_logo'
					,rfq.rfq_name							AS 'rfq.name'	
					,rfq.status								AS 'rfq.status'	
					,rfq.rfq_thumbnail						AS 'rfq.rfq_thumbnail'	
					,rfq.rfq_detail_url_default				AS 'rfq.url'
					,rfq.rfq_detail_url_default + '&quotes=Quotes'		AS 'rfq.url_quotes'
					,rfq.rfq_detail_url_default + '&message=Message'	AS 'rfq.url_message'
					,rfq.rfq_detail_url_default + '&history=History'	AS 'rfq.url_history'
					,rfq.rfq_detail_url_default + '&order=Order'		AS 'rfq.url_order'
					,rfq.award_date_utc						AS 'rfq.award_date_utc'	
             	
				FROM #tmp_rfq_info rfq
				LEFT JOIN #tmp_contacts_buyer_info buyer_billing ON rfq.rfq_id = buyer_billing.rfq_id
				LEFT JOIN #tmp_contacts_buyer_shipping_info buyer_shipping  ON buyer_billing.rfq_id = buyer_shipping.rfq_id
				LEFT JOIN #tmp_contacts_manufacturer_info supplier ON buyer_shipping.rfq_id = supplier.rfq_id
				LEFT JOIN #tmp_po_info purchase_order ON rfq.rfq_id = purchase_order.rfq_id
	
				FOR JSON PATH  , INCLUDE_NULL_VALUES , WITHOUT_ARRAY_WRAPPER 
			) om
		)

		-- EXEC proc_get_Reshape_RfqPODetails @RfqId = 1195364 , @RfqEncryptedId = '1ju2Ub6e2KJmynGojNsptA%3D%3D'
		
		SET @RfqPartInfo = 
		(
			SELECT (
				SELECT 	
					rfq_parts.rfq_part_name					AS 'description'
					,quantities.quoted_quantity				AS 'quantity'	
					,quantities.quoted_price_per_unit		AS 'price'	
					,quantities.quoted_quantity_total_price	AS 'total'	
					,rfq_parts.rfq_part_id					AS 'parts.external_id'
					,rfq_parts.rfq_part_id					AS 'parts.details.part_id'	
					,rfq_parts.rfq_part_name				AS 'parts.details.part_name'	
					,rfq_parts.rfq_part_no					AS 'parts.details.part_no'	
					,rfq_parts.rfq_part_manufacturing_process		AS 'parts.details.manufacturing_process'	
					,rfq_parts.rfq_part_manufacturing_technique		AS 'parts.details.manufacturing_technique'	
					,rfq_parts.rfq_part_material			AS 'parts.details.material'	
					,rfq_parts.rfq_part_post_process		AS 'parts.details.process'	
					, quantities.quoted_quantity_id			AS 'parts.details.quoted_quantity_id'
					, CONVERT(VARCHAR(100),quantities.quoted_quantity)  +' '+ rfq_parts .[rfq_part_quantity_unit] AS 'parts.details.quoted_quantity'
					, quantities.quoted_price_per_unit		AS 'parts.details.quoted_price_per_unit'
					, quantities.quoted_tooling_price			AS 'parts.details.quoted_tooling_price'
					, quantities.quoted_quantity_total_price	AS 'parts.details.quoted_quantity_total_price'
					,
					(
						SELECT @RfqPartFileURL + b.file_name AS 'part_file'
						FROM mp_rfq_parts_file (NOLOCK) a
						JOIN mp_special_files (NOLOCK) b ON a.file_id = b.FILE_ID
						WHERE 
						a.rfq_part_id = rfq_parts.rfq_part_id 
						AND status_id = 2
						AND b.file_name <> 'New Part'
						FOR JSON PATH  , INCLUDE_NULL_VALUES
					) AS   'parts.details.files'
				
				FROM #tmp_rfq_part_info rfq_parts
				JOIN	
				(
					
						SELECT 
							a.rfq_id
							,b.rfq_part_id
							,b.rfq_quote_items_id AS 'quoted_quantity_id'
							, CASE WHEN b.status_id = 6 AND ISNULL(b.unit,0) > 0 THEN b.unit ELSE c.part_qty END AS 'quoted_quantity'
							--, c.quantity_level
							, CASE WHEN b.status_id = 6 AND ISNULL(b.unit,0) > 0 THEN b.price ELSE CONVERT(DECIMAL(18,4),b.per_unit_price) END AS 'quoted_price_per_unit'
							, CASE WHEN b.status_id = 6 AND ISNULL(b.unit,0) > 0 THEN 0 ELSE CONVERT(DECIMAL(18,4),b.tooling_amount) END AS 'quoted_tooling_price'
							, CASE WHEN b.status_id = 6 AND ISNULL(b.unit,0) > 0 THEN CONVERT(DECIMAL(18,4),ISNULL(b.unit,0) * ISNULL(b.price,0))  ELSE 
                                    CONVERT(DECIMAL(18,4),(
									ISNULL(c.part_qty,0) * ISNULL(b.per_unit_price,0) 
									+ ISNULL(b.tooling_amount,0) 
									+ ISNULL(b.miscellaneous_amount,0)
									+ ISNULL(b.shipping_amount ,0)
								  )) 
                                  END AS 'quoted_quantity_total_price'
							, ISNULL(CONVERT(VARCHAR(100),b.est_lead_time_value),'') +' '+ ISNULL(b.est_lead_time_range,'') AS 'lead_time'
						FROM mp_rfq_quote_SupplierQuote (NOLOCK) a
						JOIN mp_rfq_quote_items (NOLOCK) b ON a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id
						JOIN mp_rfq_part_quantity (NOLOCK) c ON b.rfq_part_id = c.rfq_part_id AND b.rfq_part_quantity_id = c.rfq_part_quantity_id
						WHERE a.rfq_id =  @RfqId 
						AND a.contact_id IN  (SELECT supplier_contact_id FROM #tmp_po_info)
						AND a.is_quote_submitted =1
						AND a.is_rfq_resubmitted =0
						AND b.is_awrded = 1					
					) AS   quantities ON 
						quantities.rfq_id = rfq_parts.rfq_id
						AND quantities.rfq_part_id = rfq_parts.rfq_part_id
				FOR JSON PATH  , ROOT ('order_line_items') , INCLUDE_NULL_VALUES
			) parts
		)


		SET @RfqPOInfo = REPLACE(@RfqPOInfo , @ReplacePartText , SUBSTRING(@RfqPartInfo,2,LEN(@RfqPartInfo)-2)  )


		SELECT @RfqPOInfo OrderManagement , unique_id AS OrderManagementId FROM  #tmp_po_info

		INSERT INTO tmpOrderManagementflowlogs (RfqId,FlowName,POJSON)
		SELECT @RfqId , 'PO Payload for Reshape' , SUBSTRING(CONVERT(VARCHAR(8000),@RfqPOInfo),0,100)

		---- Update the RfqEncryptedId  
		IF @RfqId > 0
		BEGIN
		
			UPDATE a
				SET 
					RfqEncryptedId = @RfqEncryptedId				
			FROM mpOrderManagement a (NOLOCK)
			LEFT JOIN #tmp_rfq_info c ON a.RfqId = c.rfq_id	
			WHERE ID IN ( SELECT unique_id FROM #tmp_po_info)

		END
	
	END TRY
	BEGIN CATCH

		INSERT INTO tmpOrderManagementflowlogs (RfqId,FlowName,POJSON)
		SELECT @RfqId , 'Error - PO Payload for Reshape' , CONVERT(VARCHAR(1000), 'Failure' + ' - ' + ERROR_MESSAGE())

	END CATCH

	DROP TABLE IF EXISTS #tmp_po_info
	DROP TABLE IF EXISTS #tmp_rfq_info
	DROP TABLE IF EXISTS #tmp_rfq_part_info
	DROP TABLE IF EXISTS #tmp_contacts_buyer_info
	DROP TABLE IF EXISTS #tmp_contacts_buyer_shipping_info
	DROP TABLE IF EXISTS #tmp_contacts_manufacturer_info

 
END
