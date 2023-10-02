
/*
SELECT getutcdate(), * FROM mpOrderManagement where RfqId = 1162088
EXEC [proc_get_RfqPODetails] @RfqId = 1162124

*/
CREATE PROCEDURE [dbo].[proc_get_RfqPODetails]
(
	@RfqId INT
)
AS
 
BEGIN
	-- M2-4849 Create new external facing API for Order Management - DB
		SET NOCOUNT ON

		BEGIN TRY

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
			DECLARE @LastRatingInDays			INT = 0
			DECLARE @RfqThumbnail				VARCHAR(4000)
	
	
			DECLARE @RfqPOInfo					VARCHAR(8000)
			DECLARE @RfqPartInfo				VARCHAR(8000)
			DECLARE @ReplacePartText			VARCHAR(8000)= '"parts":""'

			DECLARE @TransactionId				VARCHAR(255) = NEWID()

			IF DB_NAME() = 'mp2020_qa_app_2'
			BEGIN

				SET @CompanyLogo = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020/logos/'
				SET @RfqThumbnail = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020/thumbnails/'
				SET @POFileURL = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.uat.test/RFQFiles/'
				SET @RfqPartFileURL = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.uat.test/RFQFiles/' 
						
			END
			ELSE IF DB_NAME() = 'mp2020_dev'
			BEGIN

				SET @CompanyLogo = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.public/logos/'
				SET @RfqThumbnail = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020/thumbnails/'
				SET @POFileURL = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.uat.test/RFQFiles/'
				SET @RfqPartFileURL = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.uat.test/RFQFiles/' 
		

			END
			ELSE IF DB_NAME() = 'mp2020_uat'
			BEGIN

				SET @CompanyLogo = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020/logos/'
				SET @RfqThumbnail = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020/thumbnails/'
				SET @POFileURL = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.uat.test/RFQFiles/'
				SET @RfqPartFileURL = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.uat.test/RFQFiles/' 

			END
			ELSE IF DB_NAME() = 'mp2020_prod'
			BEGIN

				SET @CompanyLogo = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.public/logos/'
				SET @RfqThumbnail = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.public/thumbnails/' 
				----SET @POFileURL = 'https://files.mfg.com/RFQFiles/'
				SET @POFileURL = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020/RFQFiles/'
				SET @RfqPartFileURL = 'https://files.mfg.com/RFQFiles/' 
		

			END


			UPDATE mpOrderManagement  SET IsDeleted = 0 WHERE RfqId = @RfqId  
		
		

			-- po details
			SELECT 
				TOP 1 
				@RfqId AS rfq_id
				, a.Id							AS unique_id
				, TransactionId					AS transaction_id
				, PONumber						AS number
				, POStatus						AS status
				, CONVERT(VARCHAR,PODate,120)	AS date_utc
				, SupplierContactId				AS supplier_contact_id
				, CASE WHEN b.file_name IS NULL THEN '' WHEN b.file_name ='' THEN '' ELSE ISNULL(@POFileURL + REPLACE(b.file_name,'&' ,'&amp;'),'') END AS file_url
				, CASE WHEN b.file_name IS NULL THEN '' WHEN b.file_name ='' THEN '' ELSE ISNULL(REPLACE(b.file_name,'&' ,'&amp;'),'') END AS file_name						
				, ReshapeUniqueId				AS reshape_order_id
				, ISNULL(Reason , '')			AS reason
				, ModifiedDate					AS reason_date
				, CASE 
					WHEN POStatus = 'retracted' THEN
					'The award has been retracted and Order ['+ISNULL(PONumber,'')+'] is now closed. You can now award this RFQ to other manufacturers and start a new order.'
					ELSE  'The order and part tracking will begin once the manufacturer accepts the Purchase Order.'
				   END banner_message
				 , ShippingAddressId			AS buyer_shipping_address_id
				 , PaymentTerm					AS po_paymentterm
				 , c.id							AS po_paymentterm_id
				 , CASE WHEN a.IsPartCompleted = NULL OR a.IsPartCompleted = 0 THEN  CAST('false' AS BIT) ELSE CAST('true' AS BIT) END po_part_complete
				 , CASE WHEN a.IsOrderReceived = NULL OR a.IsOrderReceived = 0 THEN  CAST('false' AS BIT) ELSE CAST('true' AS BIT) END po_order_received 
				 , ISNULL(a.Notes , '') AS po_notes
			INTO #tmp_po_info
			FROM mpOrderManagement (NOLOCK) a
			LEFT JOIN mp_special_files (NOLOCK) b ON a.FileId = b.FILE_ID
			LEFT JOIN mp_system_parameters (NOLOCK) c ON a.PaymentTerm = c.value AND c.[sys_key] = N'@SUPPLIER_PAYMENTTERM'
			WHERE RfqId = @RfqId 
			ORDER BY a.Id DESC

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
				, b.paymentterm_id                      AS paymentterm_id
			INTO #tmp_rfq_info
			FROM mp_rfq (NOLOCK) a
			LEFT JOIN mp_mst_paymentterm		(NOLOCK)  b ON a.payment_term_id = b.paymentterm_id
			LEFT JOIN mp_mst_rfq_buyerstatus	(NOLOCK)  c ON a.rfq_status_id = c.rfq_buyerstatus_id
			WHERE rfq_id = @RfqId
	
			-- rfq part details
			SELECT 
				a.rfq_id
				,a.rfq_part_id		AS [rfq_part_id]
				,b.part_name		AS [rfq_part_name]
				,b.part_number		AS [rfq_part_no]
				,CASE WHEN LEN(b.part_description) = 0 THEN 'N/A' ELSE ISNULL(b.part_description,'N/A') END AS [rfq_part_information]
				, CASE 
					WHEN b.GeometryId IS NULL THEN 'N/A'
					ELSE 'Production of a ' +ISNULL(b.part_name,'')+ ' (' +  CASE WHEN d.discipline_name = c.discipline_name THEN d.discipline_name ELSE c.discipline_name END + '). The part is ' +  CASE WHEN b.GeometryId = 58 THEN 'prismatic' ELSE 'cylindrical' END + ' and ' +  CASE WHEN b.IsLargePart = 1 THEN 'large ( > 10 inches )' ELSE 'small ( < 10 inches )' END + '. Please see drawing for all specifications.'
					END
				AS [rfq_part_specification]
				,d.discipline_name	AS [rfq_part_manufacturing_process]
				,CASE WHEN d.discipline_name = c.discipline_name THEN '' ELSE c.discipline_name END	AS [rfq_part_manufacturing_technique]
				,f.material_name_en		AS [rfq_part_material]
				,e.value				AS [rfq_part_post_process]
				,g.value				AS [rfq_part_unit_of_measure]
				,h.value				AS [rfq_part_quantity_unit]
				,i.part_qty				AS [rfq_part_first_quantity]
				,CASE WHEN a.is_existing_part = 1 THEN 'Existing' ELSE 'New' END AS [rfq_part_existing]
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
			LEFT JOIN mp_rfq_part_quantity (NOLOCK) i ON a.rfq_part_id = i.rfq_part_id AND i.is_deleted = 0 AND i.quantity_level = 0
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
				, f.first_name  AS supplier_first_name
				, f.last_name AS supplier_last_name
				, i.communication_value AS supplier_phone
				,CASE WHEN LEN(ISNULL(c.address1,'')) = 0 THEN '' ELSE REPLACE(c.address1,'?','') END AS supplier_address1
				,CASE WHEN LEN(ISNULL(c.address2,'')) = 0 THEN '' ELSE REPLACE(c.address2,'?','') END AS supplier_address2  ---- Added Address2 field in address 
				,CASE WHEN LEN(ISNULL(c.address4,'')) = 0 THEN '' ELSE REPLACE(c.address4,'?','') END AS supplier_city
				,CASE WHEN LEN(ISNULL(e.REGION_NAME,'')) = 0 THEN '' ELSE e.REGION_NAME  END AS supplier_state
				,CASE WHEN LEN(ISNULL(c.address3,'')) = 0 THEN '' ELSE c.address3  END AS supplier_zip
				,CASE WHEN LEN(ISNULL(d.country_name,'')) = 0  THEN '' ELSE d.country_name END AS supplier_country
				,e.REGION_ID AS supplier_region_id
				,d.country_id AS supplier_country_id
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
				, a.first_name  AS buyer_first_name
				, a.last_name AS buyer_last_name
				, i.communication_value AS buyer_bill_phone
				,CASE WHEN LEN(ISNULL(c.address1,'')) = 0 THEN '' ELSE REPLACE(c.address1,'?','') END AS buyer_bill_address1
				,CASE WHEN LEN(ISNULL(c.address2,'')) = 0 THEN '' ELSE REPLACE(c.address2,'?','') END AS buyer_bill_address2  ---- Added Address2 field in address 
				,CASE WHEN LEN(ISNULL(c.address4,'')) = 0 THEN '' ELSE REPLACE(c.address4,'?','') END AS buyer_bill_city
				,CASE WHEN LEN(ISNULL(e.REGION_NAME,'')) = 0 THEN '' ELSE e.REGION_NAME  END AS buyer_bill_state
				,CASE WHEN LEN(ISNULL(c.address3,'')) = 0 THEN '' ELSE c.address3  END AS buyer_bill_zip
				,CASE WHEN LEN(ISNULL(d.country_name,'')) = 0  THEN '' ELSE d.country_name END AS buyer_bill_country
				,e.region_id AS buyer_bill_region_id
				,d.country_id AS buyer_bill_country_id
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
			LEFT JOIN mp_addresses		c (NOLOCK) ON a.buyer_shipping_address_id = c.address_id
			LEFT JOIN mp_mst_country	d (NOLOCK) ON c.country_id = d.country_id
			LEFT JOIN mp_mst_region		e (NOLOCK) ON c.region_id = e.region_id AND e.region_id <> 0
		


			-- supplier public profile url
			DECLARE @SupplierCompanyId INT = (SELECT supplier_company_id FROM #tmp_contacts_manufacturer_info)
			DROP TABLE IF EXISTS #tmp_supplier_public_profile
			CREATE TABLE #tmp_supplier_public_profile (CommunityCompanyProfile VARCHAR(4000) ,	ProfileDetailUrl  VARCHAR(4000))

			INSERT INTO #tmp_supplier_public_profile 
			EXEC proc_get_CommunityCompanyProfileURL @CompanyId = @SupplierCompanyId 

			SET @LastRatingInDays = 
			(
				SELECT  TOP 1  DATEDIFF(DAY, created_date , GETUTCDATE())  
				FROM mp_rating_responses NOLOCK
				WHERE from_id IN (SELECT buyer_contact_id FROM #tmp_rfq_info) and  to_company_id = @SupplierCompanyId and score IS NOT NULL 
				ORDER BY  created_date DESC
			)
		
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
						) AS 'rfq_quote_id'
						,unique_id 	AS 'po_mfg_unique_id' 	
						,number		AS 'po_number' 
						,ISNULL(purchase_order.status,'Pending')		AS 'po_status'
						,date_utc	AS 'po_date'	
						--,''							AS 'po_delivery_date'
						,rfq.delivery_date_utc		AS 'po_delivery_date' 
						,purchase_order.po_paymentterm					AS 'po_term'
						,purchase_order.po_paymentterm_id         AS 'po_term_id'
						,purchase_order.po_part_complete	 AS 'po_part_complete'
						,purchase_order.po_order_received	 AS 'po_order_received'
						,reshape_order_id			AS 'reshape_order_id'
						,file_url					AS 'po_file_url'	
						,[file_name]				AS 'po_file'	
						,[reason]					AS 'po_reason'
						, reason_date				AS  'po_reason_date'
						, banner_message			AS  'po_banner_message'
						, purchase_order.po_notes AS  'po_notes'
						,supplier.supplier_name					AS 'supplier_name'
						,supplier.supplier_first_name			AS 'supplier_first_name'
						,supplier.supplier_last_name			AS 'supplier_last_name'
						,supplier.supplier_company_name			AS 'supplier_company'
						,supplier.supplier_email				AS 'supplier_email'
						,supplier.supplier_company_id			AS 'supplier_company_id'
						,supplier.supplier_id					AS 'supplier_id'
						,''										AS 'supplier_encrypt_id'
						,supplier.supplier_company_logo			AS 'supplier_company_logo'
						,supplier.supplier_address1				AS 'supplier_address1'
						,supplier.supplier_address2				AS 'supplier_address2'
						,supplier.supplier_city					AS 'supplier_city'
						,supplier.supplier_state				AS 'supplier_state'
						,supplier.supplier_zip					AS 'supplier_zip'
						,supplier.supplier_country				AS 'supplier_country'
						,supplier.supplier_region_id            AS 'supplier_region_id'
						,supplier.supplier_country_id           AS 'supplier_country_id'
						,supplier.supplier_phone				AS 'supplier_phone'
						,buyer_billing.buyer_bill_name			AS 'buyer_bill_name'
						,buyer_billing.buyer_first_name			AS 'buyer_first_name'
						,buyer_billing.buyer_last_name			AS 'buyer_last_name'
						,buyer_billing.buyer_bill_company		AS 'buyer_bill_company'
						,buyer_billing.buyer_bill_address1		AS 'buyer_bill_address1'
						,buyer_billing.buyer_bill_address2		AS 'buyer_bill_address2'
						,buyer_billing.buyer_bill_city			AS 'buyer_bill_city'
						,buyer_billing.buyer_bill_state			AS 'buyer_bill_state'
						,buyer_billing.buyer_bill_zip			AS 'buyer_bill_zip'
						,buyer_billing.buyer_bill_country		AS 'buyer_bill_country'
						,buyer_billing.buyer_bill_region_id     AS 'buyer_bill_region_id'
						,buyer_billing.buyer_bill_country_id    AS 'buyer_bill_country_id'
						,buyer_billing.buyer_bill_phone			AS 'buyer_bill_phone'
						,buyer_billing.buyer_bill_email			AS 'buyer_bill_email'
						,buyer_billing.buyer_company_id			AS 'buyer_bill_company_id'
						,buyer_billing.buyer_id					AS 'buyer_bill_buyer_id'		
						,buyer_billing.buyer_bill_company_logo	AS 'buyer_bill_company_logo'
						,buyer_shipping.buyer_ship_address1		AS 'buyer_ship_address1'
						,buyer_shipping.buyer_ship_address2		AS 'buyer_ship_address2'
						,buyer_shipping.buyer_ship_city			AS 'buyer_ship_city'
						,buyer_shipping.buyer_ship_state		AS 'buyer_ship_state'
						,buyer_shipping.buyer_ship_zip			AS 'buyer_ship_zip'
						,buyer_shipping.buyer_ship_country		AS 'buyer_ship_country'
						,buyer_shipping.buyer_ship_region_id    AS 'buyer_ship_region_id'
						,buyer_shipping.buyer_ship_country_id   AS 'buyer_ship_country_id'
						,CASE WHEN @LastRatingInDays < 15 THEN CAST('false' AS BIT) ELSE CAST('true' AS BIT) END AS 'allow_rating' 
						,''							AS 'parts'
						, 
						(
							SELECT 
								
								SUM(CASE WHEN b.status_id = 6 AND ISNULL(b.unit,0) > 0 THEN CONVERT(DECIMAL(18,4),ISNULL(b.unit,0) * ISNULL(b.price,0))  ELSE 

								CONVERT(DECIMAL(18,4),(
									ISNULL(c.part_qty,0) * ISNULL(b.per_unit_price,0) 
									+ ISNULL(b.tooling_amount,0) 
									+ ISNULL(b.miscellaneous_amount,0)
									+ ISNULL(b.shipping_amount ,0)
								  )) END) AS 'quoted_quantity_total_price_all'
							
							FROM mp_rfq_quote_SupplierQuote (NOLOCK) a
							JOIN mp_rfq_quote_items (NOLOCK) b ON a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id
							JOIN mp_rfq_part_quantity (NOLOCK) c ON b.rfq_part_id = c.rfq_part_id AND b.rfq_part_quantity_id = c.rfq_part_quantity_id
							WHERE a.rfq_id =  @RfqId 
							AND a.contact_id IN  (SELECT supplier_contact_id FROM #tmp_po_info)
							AND a.is_quote_submitted =1
							AND a.is_rfq_resubmitted =0
							AND b.is_awrded = 1	
					
						) AS 'rfq_part_quoted_quantity_total_price_all'
					FROM #tmp_rfq_info rfq
					LEFT JOIN #tmp_contacts_manufacturer_info supplier ON rfq.rfq_id = supplier.rfq_id
					LEFT JOIN #tmp_po_info purchase_order ON rfq.rfq_id = rfq.rfq_id
					LEFT JOIN #tmp_contacts_buyer_info buyer_billing ON rfq.rfq_id = buyer_billing.rfq_id
					LEFT JOIN #tmp_contacts_buyer_shipping_info buyer_shipping  ON buyer_billing.rfq_id = buyer_shipping.rfq_id
					FOR JSON PATH  , INCLUDE_NULL_VALUES , WITHOUT_ARRAY_WRAPPER 
				) om
			)

			-- EXEC [proc_get_RfqPODetails] @RfqId = 1195442 	
	
	
			SET @RfqPartInfo = 
			(
				SELECT (
					SELECT 	
						rfq_parts.rfq_part_id							AS 'rfq_part_id'
						,rfq_parts.rfq_part_name						AS 'rfq_part_description'	
						,rfq_parts.rfq_part_no							AS 'rfq_part_no'	
						,ISNULL(quantities.rfq_part_status,'Pending')	AS 'rfq_part_status'
						--,rfq_parts.[rfq_part_first_quantity]			AS 'rfq_part_first_quantity'
						,quantities.quoted_quantity						AS 'rfq_part_first_quantity'
						,rfq_parts.[rfq_part_quantity_unit]				AS 'rfq_part_first_quantity_unit'
						,rfq_parts.rfq_part_manufacturing_process		AS 'rfq_part_manufacturing_process'	
						,rfq_parts.rfq_part_manufacturing_technique		AS 'rfq_part_manufacturing_technique'	
						,rfq_parts.rfq_part_material					AS 'rfq_part_material'	
						,rfq_parts.rfq_part_post_process				AS 'rfq_part_process'	
						,ISNULL(rfq_parts.rfq_part_information,'N/A')	AS 'rfq_part_information'	
						,ISNULL(rfq_parts.rfq_part_specification,'N/A')	AS 'rfq_part_specification'	
						,rfq_parts.rfq_part_existing					AS 'rfq_part_existing'	
						, quantities.quoted_quantity_item_id			AS 'rfq_part_quoted_quantity_item_id'
						, CONVERT(VARCHAR(100),quantities.quoted_quantity)  +' '+ rfq_parts .[rfq_part_quantity_unit] AS 'rfq_part_quoted_quantity'
						, quantities.quoted_price_per_unit				AS 'rfq_part_quoted_price_per_unit'
						, quantities.quoted_quantity_total_price		AS 'rfq_part_quoted_quantity_total_price'
					
					FROM #tmp_rfq_part_info rfq_parts
					JOIN	
					(
					
							SELECT 
								a.rfq_id
								,b.rfq_part_id
								,b.rfq_quote_items_id AS 'quoted_quantity_item_id'
								, CASE WHEN b.status_id = 6 AND ISNULL(b.unit,0) > 0 THEN b.unit ELSE c.part_qty END  AS 'quoted_quantity'
								--, c.quantity_level
								, CASE WHEN b.status_id = 6 AND ISNULL(b.unit,0) > 0 THEN b.price ELSE CONVERT(DECIMAL(18,4),b.per_unit_price) END   AS 'quoted_price_per_unit'
								, CASE WHEN b.status_id = 6 AND ISNULL(b.unit,0) > 0 THEN 0 ELSE CONVERT(DECIMAL(18,4),b.tooling_amount) END  AS 'quoted_tooling_price'
								, CASE WHEN b.status_id = 6 AND ISNULL(b.unit,0) > 0 THEN CONVERT(DECIMAL(18,4),ISNULL(b.unit,0) * ISNULL(b.price,0))  ELSE 
                                    CONVERT(DECIMAL(18,4),(
									ISNULL(c.part_qty,0) * ISNULL(b.per_unit_price,0) 
									+ ISNULL(b.tooling_amount,0) 
									+ ISNULL(b.miscellaneous_amount,0)
									+ ISNULL(b.shipping_amount ,0)
								  )) 
                                  END  AS 'quoted_quantity_total_price'
								, ISNULL(CONVERT(VARCHAR(100),b.est_lead_time_value),'') +' '+ ISNULL(b.est_lead_time_range,'') AS 'lead_time'
								, ISNULL(b.ReshapePartStatus,'Pending') AS rfq_part_status
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
					FOR JSON PATH  , ROOT ('parts') , INCLUDE_NULL_VALUES
				) parts
			)
		
			IF ((SELECT COUNT(1) FROM #tmp_po_info WHERE status IN ('cancelled' , 'retracted')) = 0)
			BEGIN
				SET @RfqPOInfo = REPLACE(@RfqPOInfo , @ReplacePartText , SUBSTRING(@RfqPartInfo,2,LEN(@RfqPartInfo)-2)  )
			END
		--END

			SELECT @RfqPOInfo OrderManagement , unique_id AS OrderManagementId  FROM  #tmp_po_info

			INSERT INTO tmpOrderManagementflowlogs (RfqId,FlowName,POJSON)
			SELECT @RfqId , 'PO Payload for marketplace'  , SUBSTRING(CONVERT(VARCHAR(8000),@RfqPOInfo),0,100)

	END TRY
	BEGIN CATCH

		INSERT INTO tmpOrderManagementflowlogs (RfqId,FlowName,POJSON)
		SELECT @RfqId , 'Error - PO Payload for marketplace' , CONVERT(VARCHAR(1000), 'Failure' + ' - ' + ERROR_MESSAGE())

	END CATCH
	
	DROP TABLE IF EXISTS #tmp_po_info
	DROP TABLE IF EXISTS #tmp_rfq_info
	DROP TABLE IF EXISTS #tmp_rfq_part_info
	DROP TABLE IF EXISTS #tmp_contacts_buyer_info
	DROP TABLE IF EXISTS #tmp_contacts_buyer_shipping_info
	DROP TABLE IF EXISTS #tmp_contacts_manufacturer_info

 
END
