

CREATE VIEW [dbo].[vw_get_RFQ_Data]	  
	AS
		SELECT   --distinct 
			  mp_rfq.rfq_id  
			, mp_rfq.rfq_name  
			
			, mp_rfq.rfq_created_on  
			, mp_rfq.Quotes_needed_by  
			, mp_rfq.award_date  
			, isnull(mp_rfq_quote_suplierStatuses.rfq_userStatus_id,1)  as rfq_userStatus_id
			, mp_rfq_preferences.rfq_pref_manufacturing_location_id

			, mp_rfq_parts.part_id
			, mp_rfq_parts.rfq_part_id
			, mp_parts.part_category_id
			, mp_rfq_parts.Is_Rfq_Part_Default 

			, ROW_NUMBER() over(order by mp_rfq_parts.rfq_part_id ASC) as rfq_part_Sequence

			, mp_rfq_part_quantity.rfq_part_quantity_id
			, FLOOR(mp_rfq_part_quantity.part_qty) AS part_qty
			, Unit.id as quantity_unit_id
			, Unit.value AS quantity_unit_value			 

			, mp_Companies.company_id as buyer_company_id
			, mp_rfq.contact_id as buyer_contact_id
			, mp_contacts.first_name + ' ' + mp_contacts.last_name as buyer_contact_name 
			, mp_contacts.address_Id as buyer_contact_address_id
			
			, mp_rfq.rfq_status_id as buyer_status_id
			, mp_mst_rfq_buyerStatus.[rfq_buyerstatus_li_key] AS rfq_buyer_status			

			, mp_mst_materials.material_id 
			, dbo.[fn_getTranslatedValue](mp_mst_materials.material_name, 'EN') material_name 

			, mp_mst_part_category.part_category_id as process_id
			, mp_mst_part_category.discipline_name AS Process
			
			, Processes.id as post_production_process_id
			, Processes.value AS post_production_process_value 

			, mp_special_files.[FILE_ID] as part_file_id
			, mp_special_files.[file_name] as part_file_name
			
			, ThumbnailFile.[FILE_ID]  as rfq_thumbnailFile_id
			, ThumbnailFile.[file_name]  as rfq_thumbnail_name
			 

			, SupplierComp.company_id as supplier_company_id
			, SupplierComp.contact_id as supplier_contact_id
			, is_register_supplier_quote_the_RFQ 	
			, mp_rfq.pref_NDA_Type
			, mp_rfq.special_instruction_to_manufacturer -- Added By Ashwin
			--, mp_rfq_supplier_likes.is_rfq_like AS IsRfqLike		
			--, mp_nps_rating.nps_score AS NPSScore
			, mp_rfq.payment_term_id AS payment_term_id	
			
			
			FROM mp_rfq  (nolock) 
			LEFT JOIN mp_rfq_preferences  (nolock) on mp_rfq.rfq_id = mp_rfq_preferences.rfq_id
			
				--and mp_rfq_quote_suplierStatuses.rfq_userStatus_id in (1,2)  --This condition release only those RFQ which is approved by Vision
			JOIN mp_rfq_parts  (nolock) ON mp_rfq.rfq_id = mp_rfq_parts.rfq_id
			JOIN mp_rfq_part_quantity  (nolock) ON mp_rfq_parts.rfq_part_id = mp_rfq_part_quantity.rfq_part_id
			JOIN mp_parts  (nolock) ON mp_rfq_parts.part_id = mp_parts.part_id			
			LEFT JOIN mp_mst_part_category  (nolock) ON mp_parts.part_category_id = mp_mst_part_category.part_category_id
			LEFT JOIN mp_mst_materials  (nolock) ON mp_parts.material_id = mp_mst_materials.material_id 
			JOIN mp_contacts  (nolock) ON mp_rfq.contact_id=mp_contacts.contact_id
			JOIN mp_companies  (nolock) ON mp_contacts.company_id=mp_companies.company_id
			JOIN mp_mst_rfq_buyerStatus (nolock) ON mp_rfq.rfq_status_id=mp_mst_rfq_buyerStatus.rfq_buyerstatus_id
			JOIN mp_system_parameters  (nolock) AS Unit ON mp_parts.part_qty_unit_id = Unit.id AND Unit.sys_key = '@UNIT2_LIST' 
			LEFT JOIN  -- Convert join to left join for all registered manufactured
				( 
					mp_rfq_quote_suplierStatuses  (nolock) 
					JOIN mp_contacts SupplierComp  (nolock) on mp_rfq_quote_suplierStatuses.contact_id = SupplierComp.contact_id
				)
				ON mp_rfq.rfq_id = mp_rfq_quote_suplierStatuses.rfq_Id

			LEFT JOIN (mp_rfq_parts_file  (nolock) 
						JOIN mp_special_files  (nolock) ON mp_rfq_parts_file.[file_id] = mp_special_files.[file_id])
			ON mp_rfq_parts.rfq_part_id = mp_rfq_parts_file.rfq_part_id AND mp_rfq_parts_file.is_primary_file = 1  

			LEFT JOIN mp_system_parameters  (nolock) AS Processes ON mp_rfq_parts.Post_Production_Process_id = Processes.id 
			AND Processes.sys_key = '@PostProdProcesses' 
			
			LEFT JOIN mp_special_files  (nolock) AS ThumbnailFile ON ThumbnailFile.file_id = mp_rfq.file_id
