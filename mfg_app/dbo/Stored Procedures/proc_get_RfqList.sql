CREATE PROCEDURE [dbo].[proc_get_RfqList]
	 @ContactId INT,
	 @CompanyId INT,
	 @RfqType INT
AS
-- =============================================
-- Author:		dp-Am. N.
-- Create date:  31/10/2018
-- Description:	Stored procedure to Get the RFQ details based on RFQ Type
-- Modification:
-- Syntax: [proc_get_RfqList] <Contact_id>,<Company_id>,<RFQ_Type_id>
-- Example: [proc_get_RfqList] 216582,337455,3
--[proc_get_RfqList] 216582,337455,4
--[proc_get_RfqList] 216582,337455,5
--[proc_get_RfqList] 216582,337455,6
-- =================================================================
--Version No – Change Date – Modified By      – CR No – Note
-- =================================================================
BEGIN
	------------------------ All Rfq --------------------
	if (@RfqType = 3)	
	BEGIN	
		SELECT * FROM 
		(
			SELECT DISTINCT 
				--'SupplierAssignedRFQ' as RFQTypes,
				rfq_data.rfq_id AS RFQId 
				, rfq_data.rfq_name AS RFQName
				, rfq_data.part_file_name AS file_name	
			
				--, rfq_data.part_id
				--, rfq_data.rfq_part_id
								 			
				, rfq_data.part_qty AS Quantity 
				, rfq_data.quantity_unit_value AS UnitValue 
				, rfq_data.post_production_process_value AS PostProductionProcessValue
				, rfq_data.material_name AS Material 
				, rfq_data.Process  AS Process 
				, rfq_data.buyer_contact_name AS Buyer 
				, rfq_data.rfq_buyer_status AS RFQStatus			 
				, rfq_data.rfq_created_on AS RFQCreatedOn 
				, rfq_data.Quotes_needed_by AS QuotesNeededBy
				, rfq_data.award_date AS AwardDate
				, rfq_likes.is_rfq_like AS IsRfqLike 
				, mnr.nps_score AS NPSScore  
				, COALESCE(rfq_data.rfq_thumbnail_name,'') AS RfqThumbnail							 
			FROM vw_get_RFQ_Data as rfq_data
				LEFT JOIN mp_rfq_supplier_likes AS rfq_likes 
				ON rfq_data.rfq_id = rfq_likes.rfq_id
				and rfq_data.supplier_company_id = rfq_likes.company_id
				and rfq_data.supplier_contact_id = rfq_likes.contact_id
				LEFT JOIN mp_nps_rating mnr on mnr.company_id = rfq_data.buyer_company_id
			WHERE 
				 rfq_data.supplier_contact_id = @contactId 
				 AND rfq_data.supplier_company_id = @companyId 
				 --AND rfq_data.part_qty=(SELECT max(part_qty) FROM mp_rfq_part_quantity WHERE rfq_part_id = rfq_data.rfq_part_id) 
				 AND rfq_data.rfq_part_quantity_id=(SELECT max(a.rfq_part_quantity_id) FROM mp_rfq_part_quantity a join mp_rfq_parts b on a.rfq_part_id = b.rfq_part_id and b.rfq_id = rfq_data.rfq_id) 
				 and rfq_userStatus_id in (1,2)
				 and buyer_status_id >= 3
		Union
			--All RFQ Matching Supplier Capabilities and Territory
			SELECT distinct
				--'LocationCapabilityMatching', 
				rfq_data.rfq_id AS RFQId  
					, rfq_data.rfq_name AS RFQName 
					, rfq_data.part_file_name AS file_name	

					--, rfq_data.part_id
					--, rfq_data.rfq_part_id

					, rfq_data.part_qty AS Quantity 
					, rfq_data.quantity_unit_value AS UnitValue  
					, rfq_data.post_production_process_value AS PostProductionProcessValue
					, rfq_data.material_name AS Material 
					, rfq_data.Process AS Process 
					, rfq_data.buyer_contact_name AS Buyer 
					, rfq_data.rfq_buyer_status AS RFQStatus
					, rfq_data.rfq_created_on AS RFQCreatedOn  
					, rfq_data.Quotes_needed_by AS QuotesNeededBy
					, rfq_data.award_date  AS AwardDate
					, null AS IsRfqLike  
					, mnr.nps_score AS NPSScore
					, COALESCE(rfq_data.rfq_thumbnail_name,'') AS RfqThumbnail		
			FROM vw_get_RFQ_Data rfq_data
				JOIN (
						SELECT distinct territory_classification_id 
						FROM vw_get_company_territory_and_Capabilities 
						WHERE company_id = @CompanyId
					)  b ON rfq_data.rfq_pref_manufacturing_location_id = b.territory_classification_id
				JOIN (
						SELECT part_category_id 
						from vw_get_company_territory_and_Capabilities 
						where company_id = @CompanyId
					) c on rfq_data.part_category_id = c.part_category_id

				-- LEFT JOIN mp_nps_rating mnr on mnr.contact_id = rfq_data.buyer_contact_id -- jan 10, 2019 
				LEFT JOIN mp_nps_rating mnr on mnr.company_id = rfq_data.buyer_company_id
			WHERE
			   rfq_data.rfq_userStatus_id in (1,2)
			 and rfq_data.buyer_status_id = 3
			 --AND rfq_data.part_qty=(SELECT max(part_qty) FROM mp_rfq_part_quantity WHERE rfq_part_id = rfq_data.rfq_part_id) 	 
			AND rfq_data.rfq_part_quantity_id=(SELECT max(a.rfq_part_quantity_id) FROM mp_rfq_part_quantity a join mp_rfq_parts b on a.rfq_part_id = b.rfq_part_id and b.rfq_id = rfq_data.rfq_id) 
		 ) as AllRFQ ORDER BY  QuotesNeededBy DESC
		--SELECT 
	--		mp_rfq.rfq_id AS RFQId
	--		, mp_rfq.rfq_name AS RFQName			
	--		, mp_special_files.file_name AS file_name
	--		, mp_rfq_part_quantity.part_qty AS Quantity
	--		, Unit.value AS UnitValue
	--		, Processes.value AS PostProductionProcessValue
	--		, mp_mst_materials.material_name AS Material
	--		, mp_mst_part_category.discipline_name AS Process
	--		, mp_companies.name AS Buyer
	--		, mp_mst_rfq_buyerStatus.[description] AS RFQStatus
	--		, mp_rfq.rfq_created_on AS RFQCreatedOn
	--		, mp_rfq.Quotes_needed_by AS QuotesNeededBy
	--		, mp_rfq.award_date AS AwardDate
	--		, mp_rfq_supplier_likes.is_rfq_like AS IsRfqLike
	--		, mp_nps_rating.nps_score AS NPSScore
	--		, COALESCE(ThumbnailFile.File_Name,'') AS RfqThumbnail							 
	--	FROM mp_rfq_supplier_likes  
	--		 JOIN mp_rfq_quote_suplierStatuses ON mp_rfq_supplier_likes.rfq_id = mp_rfq_quote_suplierStatuses.rfq_Id
	--		 JOIN mp_rfq ON mp_rfq_supplier_likes.rfq_id = mp_rfq.rfq_id 
	--		 LEFT JOIN mp_special_files AS ThumbnailFile ON ThumbnailFile.file_id = mp_rfq.file_id
	--		 JOIN mp_contacts ON mp_rfq.contact_id=mp_contacts.contact_id
	--		 LEFT JOIN mp_nps_rating ON mp_nps_rating.contact_Id = mp_contacts.contact_Id
	--		 JOIN mp_companies ON mp_contacts.company_id=mp_companies.company_id
	--		 JOIN mp_mst_rfq_buyerStatus ON mp_rfq.rfq_status_id=mp_mst_rfq_buyerStatus.rfq_buyerstatus_id
			 
	--		 JOIN mp_rfq_parts ON mp_rfq.rfq_id = mp_rfq_parts.rfq_id
	--		 JOIN mp_rfq_parts_file ON mp_rfq_parts.rfq_part_id = mp_rfq_parts_file.rfq_part_id
	--		 JOIN mp_special_files ON mp_special_files.file_id = mp_rfq_parts_file.file_id
	--		 JOIN mp_rfq_part_quantity ON mp_rfq_part_quantity.rfq_part_id = mp_rfq_parts.rfq_part_id
	--		 LEFT JOIN mp_system_parameters AS Processes ON Processes.id = mp_rfq_parts.Post_Production_Process_id AND Processes.sys_key = '@PostProdProcesses' 

	--		 JOIN mp_parts ON mp_parts.part_id = mp_rfq_parts.part_id 
	--		 LEFT JOIN mp_mst_materials ON mp_mst_materials.material_id = mp_parts.material_id
			 
	--		 LEFT JOIN mp_system_parameters AS Unit ON Unit.id = mp_parts.part_qty_unit_id AND Unit.sys_key = '@UNIT2_LIST' AND Unit.sys_key = '@UNIT2_LIST' 
	--		 JOIN mp_mst_part_category ON mp_mst_part_category.part_category_id = mp_parts.part_category_id 
	--	WHERE 
	--		 mp_rfq_supplier_likes.contact_id = @contactId 
	--		 AND mp_rfq_supplier_likes.company_id = @companyId 
	--		 AND mp_rfq_supplier_likes.is_rfq_like = 1 
	--		 AND mp_rfq_parts.Is_Rfq_Part_Default = 1 
	--		 AND mp_rfq_parts_file.is_primary_file = 1 
	--		 AND mp_rfq_part_quantity.part_qty=(SELECT max(part_qty) FROM mp_rfq_part_quantity WHERE rfq_part_id = mp_rfq_parts.rfq_part_id) 
	--		 AND mp_rfq_quote_suplierStatuses.rfq_userStatus_id = 1
	--UNION  
	--	 SELECT 
	--		mp_rfq.rfq_id AS RFQId
	--		,mp_rfq.rfq_name AS RFQName
	--		,mp_special_files.file_name AS file_name
	--		,mp_rfq_part_quantity.part_qty AS Quantity
	--		,Unit.value AS UnitValue
	--		,Processes.value AS PostProductionProcessValue
	--		,mp_mst_materials.material_name AS Material
	--		,mp_mst_part_category.discipline_name AS Process
	--		,mp_companies.name AS Buyer
	--		,mp_mst_rfq_buyerStatus.[description] AS RFQStatus 
	--		,mp_rfq.rfq_created_on AS RFQCreatedOn
	--		,mp_rfq.Quotes_needed_by AS QuotesNeededBy
	--		,mp_rfq.award_date AS AwardDate
	--		,mp_rfq_supplier_likes.is_rfq_like AS IsRfqLike	
	--		,mp_nps_rating.nps_score AS NPSScore
	--		, COALESCE(ThumbnailFile.File_Name,'') AS RfqThumbnail								 
	--	FROM mp_rfq_supplier
	--		 JOIN mp_rfq_quote_suplierStatuses ON mp_rfq_supplier.rfq_id = mp_rfq_quote_suplierStatuses.rfq_Id
	--		 JOIN mp_rfq ON mp_rfq_supplier.rfq_id = mp_rfq.rfq_id	
	--		 LEFT JOIN mp_special_files AS ThumbnailFile ON ThumbnailFile.file_id = mp_rfq.file_id		  
	--		 LEFT JOIN mp_rfq_supplier_likes ON mp_rfq.rfq_id = mp_rfq_supplier_likes.rfq_id AND mp_rfq_supplier_likes.company_Id = @companyId
	--		 JOIN mp_contacts ON mp_rfq.contact_id=mp_contacts.contact_id
	--		 LEFT JOIN mp_nps_rating ON mp_nps_rating.contact_Id = mp_contacts.contact_Id
	--		 JOIN mp_companies ON mp_contacts.company_id=mp_companies.company_id
	--		 JOIN mp_mst_rfq_buyerStatus ON mp_rfq.rfq_status_id=mp_mst_rfq_buyerStatus.rfq_buyerstatus_id

	--		 JOIN mp_rfq_parts ON mp_rfq.rfq_id = mp_rfq_parts.rfq_id
	--		 JOIN mp_rfq_parts_file ON mp_rfq_parts.rfq_part_id = mp_rfq_parts_file.rfq_part_id
	--		 JOIN mp_special_files ON mp_rfq_parts_file.file_id = mp_special_files.file_id
	--		 JOIN mp_rfq_part_quantity ON mp_rfq_parts.rfq_part_id = mp_rfq_part_quantity.rfq_part_id
	--		 LEFT JOIN mp_system_parameters AS Processes on mp_rfq_parts.Post_Production_Process_id = Processes.id AND Processes.sys_key = '@PostProdProcesses' 

	--		 JOIN mp_parts ON mp_rfq_parts.part_id = mp_parts.part_id
	--		 LEFT JOIN mp_mst_materials ON mp_parts.material_id = mp_mst_materials.material_id			 			 			 
			 
	--		 LEFT JOIN mp_system_parameters AS Unit on mp_parts.part_qty_unit_id = Unit.id AND Unit.sys_key = '@UNIT2_LIST' AND Unit.sys_key = '@UNIT2_LIST'  			 
	--		 JOIN mp_mst_part_category ON mp_parts.part_category_id = mp_mst_part_category.part_category_id
	--	WHERE 
	--	    ( mp_rfq_supplier.company_Id = @CompanyId  OR mp_rfq_supplier.supplier_group_id 
	--		IN (SELECT book_id FROM mp_book_details WHERE mp_book_details.company_Id = @CompanyId) ) 
	--		AND mp_rfq_parts.Is_Rfq_Part_Default = 1 
	--		AND mp_rfq_parts_file.is_primary_file = 1 
	--		AND mp_rfq_part_quantity.part_qty=(SELECT max(part_qty) FROM mp_rfq_part_quantity WHERE rfq_part_id = mp_rfq_parts.rfq_part_id) 
	--		AND mp_rfq_quote_suplierStatuses.rfq_userStatus_id = 1
	--		--AND Processes.sys_key = '@PostProdProcesses' 
	--		--AND Unit.sys_key = '@UNIT2_LIST' 

	--UNION  
	--	SELECT 
	--		mp_rfq.rfq_id AS RFQId
	--		,mp_rfq.rfq_name AS RFQName
	--		,mp_special_files.[file_name] AS file_name			
	--		,mp_rfq_part_quantity.part_qty AS Quantity
	--		,Unit.value AS UnitValue
	--		,Processes.value AS PostProductionProcessValue 
	--		,mp_mst_materials.material_name AS Material
	--		,mp_mst_part_category.discipline_name AS Process
	--		,mp_companies.[name] AS Buyer
	--		,mp_mst_rfq_buyerStatus.[description] AS RFQStatus			
	--		,mp_rfq.rfq_created_on AS RFQCreatedOn
	--		,mp_rfq.Quotes_needed_by AS QuotesNeededBy
	--		,mp_rfq.award_date AS AwardDate
	--		,mp_rfq_supplier_likes.is_rfq_like AS IsRfqLike		
	--		,mp_nps_rating.nps_score AS NPSScore
	--		, COALESCE(ThumbnailFile.File_Name,'') AS RfqThumbnail										 
	--	FROM mp_rfq 
	--	    JOIN mp_rfq_quote_SupplierQuote ON mp_rfq.rfq_id = mp_rfq_quote_SupplierQuote.rfq_id
	--		JOIN mp_rfq_quote_suplierStatuses ON mp_rfq.rfq_id = mp_rfq_quote_suplierStatuses.rfq_Id 
	--		LEFT JOIN mp_special_files AS ThumbnailFile ON ThumbnailFile.file_id = mp_rfq.file_id
	--		LEFT JOIN mp_rfq_supplier_likes ON mp_rfq.rfq_id = mp_rfq_supplier_likes.rfq_id AND mp_rfq_supplier_likes.company_Id = @companyId
	--		JOIN mp_contacts ON mp_rfq.contact_id=mp_contacts.contact_id
	--		LEFT JOIN mp_nps_rating ON mp_nps_rating.contact_Id = mp_contacts.contact_Id
	--		JOIN mp_companies ON mp_contacts.company_id=mp_companies.company_id
	--		JOIN mp_mst_rfq_buyerStatus ON mp_rfq.rfq_status_id=mp_mst_rfq_buyerStatus.rfq_buyerstatus_id

	--		JOIN mp_rfq_parts ON mp_rfq.rfq_id = mp_rfq_parts.rfq_id
	--		JOIN mp_rfq_parts_file ON mp_rfq_parts.rfq_part_id = mp_rfq_parts_file.rfq_part_id
	--		JOIN mp_special_files ON mp_rfq_parts_file.[file_id] = mp_special_files.[file_id]
	--		JOIN mp_rfq_part_quantity ON mp_rfq_parts.rfq_part_id = mp_rfq_part_quantity.rfq_part_id
	--		LEFT JOIN mp_system_parameters AS Processes ON mp_rfq_parts.Post_Production_Process_id = Processes.id AND Processes.sys_key = '@PostProdProcesses' 

	--		JOIN mp_parts ON mp_rfq_parts.part_id = mp_parts.part_id			
	--		LEFT JOIN mp_mst_materials ON mp_parts.material_id = mp_mst_materials.material_id 
			
	--		LEFT JOIN mp_system_parameters AS Unit ON mp_parts.part_qty_unit_id = Unit.id AND Unit.sys_key = '@UNIT2_LIST' AND Unit.sys_key = '@UNIT2_LIST'  			
	--		JOIN mp_mst_part_category ON mp_parts.part_category_id = mp_mst_part_category.part_category_id
	--	WHERE 
	--		mp_rfq.rfq_status_id = 3 			 
	--		AND mp_rfq_parts.Is_Rfq_Part_Default = 1 
	--		AND mp_rfq_parts_file.is_primary_file = 1 
	--		AND mp_rfq_part_quantity.part_qty=(SELECT MAX(part_qty) FROM mp_rfq_part_quantity WHERE rfq_part_id = mp_rfq_parts.rfq_part_id) 
	--		AND mp_rfq_quote_suplierStatuses.rfq_userStatus_id = 1
	--		--AND Processes.sys_key = '@PostProdProcesses' 
	--		--AND Unit.sys_key = '@UNIT2_LIST' 
	--		AND mp_rfq_quote_SupplierQuote.contact_id = @contactId 	
			
	--UNION  
	--	SELECT 
	--		mp_rfq.rfq_id AS RFQId
	--		,mp_rfq.rfq_name AS RFQName
	--		,mp_special_files.[file_name] AS file_name			
	--		,mp_rfq_part_quantity.part_qty AS Quantity
	--		,Unit.value AS UnitValue
	--		,Processes.value AS PostProductionProcessValue 
	--		,mp_mst_materials.material_name AS Material
	--		,mp_mst_part_category.discipline_name AS Process
	--		,mp_companies.[name] AS Buyer
	--		,mp_mst_rfq_buyerStatus.[description] AS RFQStatus			
	--		,mp_rfq.rfq_created_on AS RFQCreatedOn
	--		,mp_rfq.Quotes_needed_by AS QuotesNeededBy
	--		,mp_rfq.award_date AS AwardDate
	--		,mp_rfq_supplier_likes.is_rfq_like AS IsRfqLike		
	--		,mp_nps_rating.nps_score AS NPSScore
	--		,COALESCE(ThumbnailFile.File_Name,'') AS RfqThumbnail							 
	--	 FROM mp_rfq 
	--		JOIN mp_rfq_quote_suplierStatuses ON mp_rfq.rfq_id = mp_rfq_quote_suplierStatuses.rfq_Id 
	--		LEFT JOIN mp_special_files AS ThumbnailFile ON ThumbnailFile.file_id = mp_rfq.file_id
	--		LEFT JOIN mp_rfq_supplier_likes ON mp_rfq.rfq_id = mp_rfq_supplier_likes.rfq_id AND mp_rfq_supplier_likes.company_Id = @companyId
	--		JOIN mp_contacts ON mp_rfq.contact_id=mp_contacts.contact_id
	--		LEFT JOIN mp_nps_rating ON mp_nps_rating.contact_Id = mp_contacts.contact_Id
	--		JOIN mp_companies ON mp_contacts.company_id=mp_companies.company_id
	--		JOIN mp_mst_rfq_buyerStatus ON mp_rfq.rfq_status_id=mp_mst_rfq_buyerStatus.rfq_buyerstatus_id

	--		JOIN mp_rfq_parts ON mp_rfq.rfq_id = mp_rfq_parts.rfq_id
	--		JOIN mp_rfq_parts_file ON mp_rfq_parts.rfq_part_id = mp_rfq_parts_file.rfq_part_id
	--		JOIN mp_special_files ON mp_rfq_parts_file.[file_id] = mp_special_files.[file_id]
	--		JOIN mp_rfq_part_quantity ON mp_rfq_parts.rfq_part_id = mp_rfq_part_quantity.rfq_part_id
	--		LEFT JOIN mp_system_parameters AS Processes ON mp_rfq_parts.Post_Production_Process_id = Processes.id AND Processes.sys_key = '@PostProdProcesses' 

	--		JOIN mp_parts ON mp_rfq_parts.part_id = mp_parts.part_id			
	--		LEFT JOIN mp_mst_materials ON mp_parts.material_id = mp_mst_materials.material_id 
			
	--		LEFT JOIN mp_system_parameters AS Unit ON mp_parts.part_qty_unit_id = Unit.id AND Unit.sys_key = '@UNIT2_LIST' 			
	--		JOIN mp_mst_part_category ON mp_parts.part_category_id = mp_mst_part_category.part_category_id
	--	WHERE 
	--		mp_rfq_parts.Is_Rfq_Part_Default = 1 
	--		AND mp_rfq_parts_file.is_primary_file = 1 
	--		AND mp_rfq_part_quantity.part_qty=(SELECT MAX(part_qty) FROM mp_rfq_part_quantity WHERE rfq_part_id = mp_rfq_parts.rfq_part_id) 
	--		--AND Processes.sys_key = '@PostProdProcesses' 
	--		--AND Unit.sys_key = '@UNIT2_LIST' 
	--		AND mp_mst_rfq_buyerStatus.rfq_buyerstatus_id = 6 	
	--		AND mp_rfq_quote_suplierStatuses.rfq_userStatus_id = 1		 			
		 
			
	--UNION  
	--	SELECT 
	--		0 AS RFQId
	--		,'FollowedBuyers_RFQ' AS RFQName
	--		,'FollowedBuyers_FileName' As File_Name
	--		,'10' AS Quantity
	--		,'FollowedBuyers_Unit' AS UnitValue
	--		,'FollowedBuyers_PostProductionProcess' AS PostProductionProcessValue
	--		,'FollowedBuyers_Material' AS Material
	--		,'FollowedBuyers_Process' AS Process
	--		,'FollowedBuyers_BuyerName' AS Buyer
	--		,'FollowedBuyers_RfqStatus' AS RFQStatus 
	--		,GETUTCDATE() AS RFQCreatedOn
	--		,GETUTCDATE() AS QuotesNeededBy
	--		,GETUTCDATE() AS AwardDate
	--		,'false' AS IsRfqLike  
	--		,'85' AS NPSScore
	--		, '' AS RfqThumbnail	

	END	  
	------------------------ Liked Rfq --------------------
	ELSE IF (@RfqType = 4)	
	BEGIN	
		SELECT DISTINCT 
			--'SupplierAssignedRFQ' as RFQTypes,
			rfq_data.rfq_id AS RFQId 
			, rfq_data.rfq_name AS RFQName
			, rfq_data.part_file_name AS file_name	
			
			--, rfq_data.part_id
			--, rfq_data.rfq_part_id
								 			
			, rfq_data.part_qty AS Quantity 
			, rfq_data.quantity_unit_value AS UnitValue 
			, rfq_data.post_production_process_value AS PostProductionProcessValue
			, rfq_data.material_name AS Material 
			, rfq_data.Process  AS Process 
			, rfq_data.buyer_contact_name AS Buyer 
			, rfq_data.rfq_buyer_status AS RFQStatus			 
			, rfq_data.rfq_created_on AS RFQCreatedOn 
			, rfq_data.Quotes_needed_by AS QuotesNeededBy
			, rfq_data.award_date AS AwardDate
			, rfq_likes.is_rfq_like AS IsRfqLike 
			, mnr.nps_score AS NPSScore  
			, COALESCE(rfq_data.rfq_thumbnail_name,'') AS RfqThumbnail							 
		FROM vw_get_RFQ_Data as rfq_data
			LEFT JOIN mp_rfq_supplier_likes AS rfq_likes 
			ON rfq_data.rfq_id = rfq_likes.rfq_id
			and rfq_data.supplier_company_id = rfq_likes.company_id
			and rfq_data.supplier_contact_id = rfq_likes.contact_id
			-- LEFT JOIN mp_nps_rating mnr on mnr.contact_id = rfq_data.buyer_contact_id -- jan 10, 2019 
			LEFT JOIN mp_nps_rating mnr on mnr.company_id = rfq_data.buyer_company_id
		WHERE 
			 rfq_data.supplier_contact_id = @contactId 
			 AND rfq_data.supplier_company_id = @companyId 
			 --AND rfq_data.part_qty=(SELECT max(part_qty) FROM mp_rfq_part_quantity WHERE rfq_part_id = rfq_data.rfq_part_id) 
			 AND rfq_data.rfq_part_quantity_id=(SELECT max(a.rfq_part_quantity_id) FROM mp_rfq_part_quantity a join mp_rfq_parts b on a.rfq_part_id = b.rfq_part_id and b.rfq_id = rfq_data.rfq_id) 
			 and rfq_userStatus_id in (1,2)
			 and buyer_status_id >= 3
			 and rfq_likes.is_rfq_like = 1
			 ORDER BY QuotesNeededBy DESC
	END	  
	
	----------------------- Special Invite Rfq --------------------
	ELSE IF (@RfqType = 5)	
	BEGIN	
		
	SELECT DISTINCT 
			--'SupplierAssignedRFQ' as RFQTypes,
			rfq_data.rfq_id AS RFQId 
			, rfq_data.rfq_name AS RFQName
			, rfq_data.part_file_name AS file_name	
			
			--, rfq_data.part_id
			--, rfq_data.rfq_part_id
								 			
			, rfq_data.part_qty AS Quantity 
			, rfq_data.quantity_unit_value AS UnitValue 
			, rfq_data.post_production_process_value AS PostProductionProcessValue
			, rfq_data.material_name AS Material 
			, rfq_data.Process  AS Process 
			, rfq_data.buyer_contact_name AS Buyer 
			, rfq_data.rfq_buyer_status AS RFQStatus			 
			, rfq_data.rfq_created_on AS RFQCreatedOn 
			, rfq_data.Quotes_needed_by AS QuotesNeededBy
			, rfq_data.award_date AS AwardDate
			, rfq_likes.is_rfq_like AS IsRfqLike 
			, mnr.nps_score AS NPSScore  
			, COALESCE(rfq_data.rfq_thumbnail_name,'') AS RfqThumbnail							 
		FROM vw_get_RFQ_Data as rfq_data
			LEFT JOIN mp_rfq_supplier_likes AS rfq_likes 
			ON rfq_data.rfq_id = rfq_likes.rfq_id
			and rfq_data.supplier_company_id = rfq_likes.company_id
			and rfq_data.supplier_contact_id = rfq_likes.contact_id
			-- LEFT JOIN mp_nps_rating mnr on mnr.contact_id = rfq_data.buyer_contact_id -- jan 10, 2019 
			LEFT JOIN mp_nps_rating mnr on mnr.company_id = rfq_data.buyer_company_id
		WHERE 
			 rfq_data.supplier_contact_id = @contactId 
			 AND rfq_data.supplier_company_id = @companyId 
			 --AND rfq_data.part_qty=(SELECT max(part_qty) FROM mp_rfq_part_quantity WHERE rfq_part_id = rfq_data.rfq_part_id) 
			 AND rfq_data.rfq_part_quantity_id=(SELECT max(a.rfq_part_quantity_id) FROM mp_rfq_part_quantity a join mp_rfq_parts b on a.rfq_part_id = b.rfq_part_id and b.rfq_id = rfq_data.rfq_id) 
			 and rfq_userStatus_id in (1,2)
			 and buyer_status_id >= 3
		ORDER BY  QuotesNeededBy DESC
	END	  
	------------------------ Quoted Rfq --------------------
	ELSE IF (@RfqType = 6)		 
	BEGIN					 
		--SELECT 
		--	mp_rfq.rfq_id AS RFQId
		--	,mp_rfq.rfq_name AS RFQName
		--	,mp_special_files.[file_name] AS file_name			
		--	,mp_rfq_part_quantity.part_qty AS Quantity
		--	,Unit.value AS UnitValue
		--	,Processes.value AS PostProductionProcessValue 
		--	,mp_mst_materials.material_name AS Material
		--	,mp_mst_part_category.discipline_name AS Process
		--	,mp_companies.[name] AS Buyer
		--	,mp_mst_rfq_buyerStatus.rfq_buyerstatus_li_key AS RFQStatus			
		--	,mp_rfq.rfq_created_on AS RFQCreatedOn
		--	,mp_rfq.Quotes_needed_by AS QuotesNeededBy
		--	,mp_rfq.award_date AS AwardDate
		--	,mp_rfq_supplier_likes.is_rfq_like AS IsRfqLike		
		--	,mp_nps_rating.nps_score AS NPSScore
		--	,COALESCE(ThumbnailFile.File_Name,'') AS RfqThumbnail								 
		--FROM mp_rfq 
		--    JOIN mp_rfq_quote_SupplierQuote ON mp_rfq.rfq_id = mp_rfq_quote_SupplierQuote.rfq_id
		--	JOIN mp_rfq_quote_suplierStatuses ON mp_rfq.rfq_id = mp_rfq_quote_suplierStatuses.rfq_Id 
		--	LEFT JOIN mp_special_files AS ThumbnailFile ON ThumbnailFile.file_id = mp_rfq.file_id
		--	LEFT JOIN mp_rfq_supplier_likes ON mp_rfq.rfq_id = mp_rfq_supplier_likes.rfq_id AND mp_rfq_supplier_likes.company_Id = @companyId
		--	JOIN mp_contacts ON mp_rfq.contact_id=mp_contacts.contact_id
		--	LEFT JOIN mp_nps_rating ON mp_nps_rating.contact_Id = mp_contacts.contact_Id
		--	JOIN mp_companies ON mp_contacts.company_id=mp_companies.company_id
		--	JOIN mp_mst_rfq_buyerStatus ON mp_rfq.rfq_status_id=mp_mst_rfq_buyerStatus.rfq_buyerstatus_id

		--	JOIN mp_rfq_parts ON mp_rfq.rfq_id = mp_rfq_parts.rfq_id
		--	JOIN mp_rfq_parts_file ON mp_rfq_parts.rfq_part_id = mp_rfq_parts_file.rfq_part_id
		--	JOIN mp_special_files ON mp_rfq_parts_file.[file_id] = mp_special_files.[file_id]
		--	JOIN mp_rfq_part_quantity ON mp_rfq_parts.rfq_part_id = mp_rfq_part_quantity.rfq_part_id
		--	LEFT JOIN mp_system_parameters AS Processes ON mp_rfq_parts.Post_Production_Process_id = Processes.id AND Processes.sys_key = '@PostProdProcesses' 

		--	JOIN mp_parts ON mp_rfq_parts.part_id = mp_parts.part_id			
		--	LEFT JOIN mp_mst_materials ON mp_parts.material_id = mp_mst_materials.material_id 
			
		--	LEFT JOIN mp_system_parameters AS Unit ON mp_parts.part_qty_unit_id = Unit.id AND Unit.sys_key = '@UNIT2_LIST' AND Unit.sys_key = '@UNIT2_LIST'  			
		--	JOIN mp_mst_part_category ON mp_parts.part_category_id = mp_mst_part_category.part_category_id
		--WHERE 
		--	mp_rfq.rfq_status_id = 3 			 
		--	AND mp_rfq_parts.Is_Rfq_Part_Default = 1 
		--	AND mp_rfq_parts_file.is_primary_file = 1 
		--	AND mp_rfq_part_quantity.part_qty=(SELECT MAX(part_qty) FROM mp_rfq_part_quantity WHERE rfq_part_id = mp_rfq_parts.rfq_part_id) 
		--	AND mp_rfq_quote_suplierStatuses.rfq_userStatus_id = 1
		--	--AND Processes.sys_key = '@PostProdProcesses' 
		--	--AND Unit.sys_key = '@UNIT2_LIST' 
		--	AND mp_rfq_quote_SupplierQuote.contact_id = @contactId
			 		 			
		--ORDER BY QuotesNeededBy DESC
		
		SELECT DISTINCT 
			--'SupplierAssignedRFQ' as RFQTypes,
			rfq_data.rfq_id AS RFQId 
			, rfq_data.rfq_name AS RFQName
			, rfq_data.part_file_name AS file_name	
			
			--, rfq_data.part_id
			--, rfq_data.rfq_part_id
								 			
			, rfq_data.part_qty AS Quantity 
			, rfq_data.quantity_unit_value AS UnitValue 
			, rfq_data.post_production_process_value AS PostProductionProcessValue
			, rfq_data.material_name AS Material 
			, rfq_data.Process  AS Process 
			, rfq_data.buyer_contact_name AS Buyer 
			, rfq_data.rfq_buyer_status AS RFQStatus			 
			, rfq_data.rfq_created_on AS RFQCreatedOn 
			, rfq_data.Quotes_needed_by AS QuotesNeededBy
			, rfq_data.award_date AS AwardDate
			, rfq_likes.is_rfq_like AS IsRfqLike 
			, mnr.nps_score AS NPSScore  
			, COALESCE(rfq_data.rfq_thumbnail_name,'') AS RfqThumbnail							 
		FROM vw_get_RFQ_Data as rfq_data
			JOIN mp_rfq_quote_SupplierQuote as rqsq on rfq_data.rfq_id = rqsq.rfq_id  and is_rfq_resubmitted = 0
			LEFT JOIN mp_rfq_supplier_likes AS rfq_likes 
			ON rfq_data.rfq_id = rfq_likes.rfq_id
			and rfq_data.supplier_company_id = rfq_likes.company_id
			and rfq_data.supplier_contact_id = rfq_likes.contact_id
			-- LEFT JOIN mp_nps_rating mnr on mnr.contact_id = rfq_data.buyer_contact_id -- jan 10, 2019 
			LEFT JOIN mp_nps_rating mnr on mnr.company_id = rfq_data.buyer_company_id
		WHERE 
			 rfq_data.supplier_contact_id = @contactId 
			 AND rfq_data.supplier_company_id = @companyId 
			 --AND rfq_data.part_qty=(SELECT max(part_qty) FROM mp_rfq_part_quantity WHERE rfq_part_id = rfq_data.rfq_part_id) 
			 AND rfq_data.rfq_part_quantity_id=(SELECT max(a.rfq_part_quantity_id) FROM mp_rfq_part_quantity a join mp_rfq_parts b on a.rfq_part_id = b.rfq_part_id and b.rfq_id = rfq_data.rfq_id) 
			 and rfq_userStatus_id in (1,2)
			 and buyer_status_id >= 3
		    ORDER BY QuotesNeededBy DESC
	END	
	 
 ------------------------ Awarded Rfq --------------------
	ELSE IF (@RfqType = 7)		 
	BEGIN			
		 --This below SQL is still in progress as RFQ award functionality is yet to implement 
		--Need to revisit this SQL once RFQ award functionality is ready
		 SELECT DISTINCT 
			--'SupplierAssignedRFQ' as RFQTypes,
			rfq_data.rfq_id AS RFQId 
			, rfq_data.rfq_name AS RFQName
			, rfq_data.part_file_name AS file_name	
			
			--, rfq_data.part_id
			--, rfq_data.rfq_part_id
								 			
			, rfq_data.part_qty AS Quantity 
			, rfq_data.quantity_unit_value AS UnitValue 
			, rfq_data.post_production_process_value AS PostProductionProcessValue
			, rfq_data.material_name AS Material 
			, rfq_data.Process  AS Process 
			, rfq_data.buyer_contact_name AS Buyer 
			, rfq_data.rfq_buyer_status AS RFQStatus			 
			, rfq_data.rfq_created_on AS RFQCreatedOn 
			, rfq_data.Quotes_needed_by AS QuotesNeededBy
			, rfq_data.award_date AS AwardDate
			, rfq_likes.is_rfq_like AS IsRfqLike 
			, mnr.nps_score AS NPSScore  
			, COALESCE(rfq_data.rfq_thumbnail_name,'') AS RfqThumbnail							 
		FROM vw_get_RFQ_Data as rfq_data
			JOIN mp_rfq_quote_SupplierQuote as rqsq on rfq_data.rfq_id = rqsq.rfq_id  and is_rfq_resubmitted = 0
			JOIN mp_rfq_quote_items as rqid on rqid.rfq_quote_SupplierQuote_id = rqsq.rfq_quote_SupplierQuote_id
			and rfq_data.rfq_part_id = rqid.rfq_part_id
			LEFT JOIN mp_rfq_supplier_likes AS rfq_likes 
			ON rfq_data.rfq_id = rfq_likes.rfq_id
			and rfq_data.supplier_company_id = rfq_likes.company_id
			and rfq_data.supplier_contact_id = rfq_likes.contact_id
			-- LEFT JOIN mp_nps_rating mnr on mnr.contact_id = rfq_data.buyer_contact_id -- jan 10, 2019 
			LEFT JOIN mp_nps_rating mnr on mnr.company_id = rfq_data.buyer_company_id
		WHERE 
			 rfq_data.supplier_contact_id = @contactId 
			 AND rfq_data.supplier_company_id = @companyId 
			 --AND rfq_data.part_qty=(SELECT max(part_qty) FROM mp_rfq_part_quantity WHERE rfq_part_id = rfq_data.rfq_part_id) 
			 AND rfq_data.rfq_part_quantity_id=(SELECT max(a.rfq_part_quantity_id) FROM mp_rfq_part_quantity a join mp_rfq_parts b on a.rfq_part_id = b.rfq_part_id and b.rfq_id = rfq_data.rfq_id) 
			 and rfq_userStatus_id in (1,2)
			 and buyer_status_id >= 3
			 and rqid.is_awrded=1	 			
		ORDER BY QuotesNeededBy DESC
	END 

--	 ------------------------ Followed Buyers Rfq --------------------
	ELSE IF (@RfqType = 8)		 
	BEGIN			
		 SELECT DISTINCT 
			--'SupplierAssignedRFQ' as RFQTypes,
			rfq_data.rfq_id AS RFQId 
			, rfq_data.rfq_name AS RFQName
			, rfq_data.part_file_name AS file_name	
			
			--, rfq_data.part_id
			--, rfq_data.rfq_part_id
								 			
			, rfq_data.part_qty AS Quantity 
			, rfq_data.quantity_unit_value AS UnitValue 
			, rfq_data.post_production_process_value AS PostProductionProcessValue
			, rfq_data.material_name AS Material 
			, rfq_data.Process  AS Process 
			, rfq_data.buyer_contact_name AS Buyer 
			, rfq_data.rfq_buyer_status AS RFQStatus			 
			, rfq_data.rfq_created_on AS RFQCreatedOn 
			, rfq_data.Quotes_needed_by AS QuotesNeededBy
			, rfq_data.award_date AS AwardDate
			, rfq_likes.is_rfq_like AS IsRfqLike 
			, mnr.nps_score AS NPSScore  
			, COALESCE(rfq_data.rfq_thumbnail_name,'') AS RfqThumbnail							 
		FROM vw_get_RFQ_Data as rfq_data
			JOIN 
			(mp_book_details mbd 
			JOIN mp_books  mb on mbd.book_id =mb.book_id
			JOIN mp_mst_book_type mmbt on mmbt.book_type_id = mb.bk_type
			and mmbt.book_type ='BOOK_BOOKTYPE_HOTLIST'
			) on mb.contact_id = rfq_data.supplier_contact_id
			and mbd.company_id  = rfq_data.buyer_company_id
			LEFT JOIN mp_rfq_supplier_likes AS rfq_likes 
			ON rfq_data.rfq_id = rfq_likes.rfq_id
			and rfq_data.supplier_company_id = rfq_likes.company_id
			and rfq_data.supplier_contact_id = rfq_likes.contact_id
			-- LEFT JOIN mp_nps_rating mnr on mnr.contact_id = rfq_data.buyer_contact_id -- jan 10, 2019 
			LEFT JOIN mp_nps_rating mnr on mnr.company_id = rfq_data.buyer_company_id
		WHERE 
			 rfq_data.supplier_contact_id = @contactId 
			 AND rfq_data.supplier_company_id = @companyId 
			 AND rfq_data.part_qty=(SELECT max(part_qty) FROM mp_rfq_part_quantity WHERE rfq_part_id = rfq_data.rfq_part_id) 
			 AND rfq_data.rfq_part_quantity_id=(SELECT max(a.rfq_part_quantity_id) FROM mp_rfq_part_quantity a join mp_rfq_parts b on a.rfq_part_id = b.rfq_part_id and b.rfq_id = rfq_data.rfq_id) 
			 and rfq_userStatus_id in (1,2)
			 and buyer_status_id >= 3
		    ORDER BY QuotesNeededBy DESC			
	END	  

	------------------------ DisLiked Rfq --------------------
	else if (@RfqType = 9)	
	BEGIN	
	--	 SELECT 
	--		mp_rfq.rfq_id AS RFQId
	--		, mp_rfq.rfq_name AS RFQName			
	--		, mp_special_files.file_name AS file_name
	--		, mp_rfq_part_quantity.part_qty AS Quantity
	--		, Unit.value AS UnitValue
	--		, Processes.value AS PostProductionProcessValue
	--		, mp_mst_materials.material_name AS Material
	--		, mp_mst_part_category.discipline_name AS Process
	--		, mp_companies.name AS Buyer
	--		, mp_mst_rfq_buyerStatus.rfq_buyerstatus_li_key AS RFQStatus
	--		, mp_rfq.rfq_created_on AS RFQCreatedOn
	--		, mp_rfq.Quotes_needed_by AS QuotesNeededBy
	--		, mp_rfq.award_date AS AwardDate
	--		, mp_rfq_supplier_likes.is_rfq_like AS IsRfqLike
	--		, mp_nps_rating.nps_score AS NPSScore
	--		, COALESCE(ThumbnailFile.File_Name,'') AS RfqThumbnail							 
	--	FROM mp_rfq_supplier_likes 
	--		 JOIN mp_rfq_quote_suplierStatuses ON mp_rfq_supplier_likes.rfq_id = mp_rfq_quote_suplierStatuses.rfq_Id  
	--		 JOIN mp_rfq ON mp_rfq_supplier_likes.rfq_id = mp_rfq.rfq_id
	--		 LEFT JOIN mp_special_files AS ThumbnailFile ON ThumbnailFile.file_id = mp_rfq.file_id
	--		 JOIN mp_contacts ON mp_rfq.contact_id=mp_contacts.contact_id
	--		 LEFT JOIN mp_nps_rating ON mp_nps_rating.contact_Id = mp_contacts.contact_Id
	--		 JOIN mp_companies ON mp_contacts.company_id=mp_companies.company_id
	--		 JOIN mp_mst_rfq_buyerStatus ON mp_rfq.rfq_status_id=mp_mst_rfq_buyerStatus.rfq_buyerstatus_id
			 
	--		 JOIN mp_rfq_parts ON mp_rfq.rfq_id = mp_rfq_parts.rfq_id
	--		 JOIN mp_rfq_parts_file ON mp_rfq_parts.rfq_part_id = mp_rfq_parts_file.rfq_part_id
	--		 JOIN mp_special_files ON mp_special_files.file_id = mp_rfq_parts_file.file_id
	--		 JOIN mp_rfq_part_quantity ON mp_rfq_part_quantity.rfq_part_id = mp_rfq_parts.rfq_part_id
	--		 LEFT JOIN mp_system_parameters AS Processes ON Processes.id = mp_rfq_parts.Post_Production_Process_id AND Processes.sys_key = '@PostProdProcesses' 

	--		 JOIN mp_parts ON mp_parts.part_id = mp_rfq_parts.part_id 
	--		 LEFT JOIN mp_mst_materials ON mp_mst_materials.material_id = mp_parts.material_id
			 
	--		 LEFT JOIN mp_system_parameters AS Unit ON Unit.id = mp_parts.part_qty_unit_id AND Unit.sys_key = '@UNIT2_LIST' AND Unit.sys_key = '@UNIT2_LIST' 
	--		 JOIN mp_mst_part_category ON mp_mst_part_category.part_category_id = mp_parts.part_category_id 
	--	WHERE 
	--		 mp_rfq_supplier_likes.contact_id = @contactId 
	--		 AND mp_rfq_supplier_likes.company_id = @companyId 
	--		 AND mp_rfq_supplier_likes.is_rfq_like = 0 
	--		 AND mp_rfq_parts.Is_Rfq_Part_Default = 1 
	--		 AND mp_rfq_parts_file.is_primary_file = 1 
	--		 AND mp_rfq_part_quantity.part_qty=(SELECT max(part_qty) FROM mp_rfq_part_quantity WHERE rfq_part_id = mp_rfq_parts.rfq_part_id) 
	--		 --AND Processes.sys_key = '@PostProdProcesses' 
	--		 --AND Unit.sys_key = '@UNIT2_LIST' 
	--		 AND mp_rfq_quote_suplierStatuses.rfq_userStatus_id = 1
		SELECT DISTINCT 
			--'SupplierAssignedRFQ' as RFQTypes,
			rfq_data.rfq_id AS RFQId 
			, rfq_data.rfq_name AS RFQName
			, rfq_data.part_file_name AS file_name	
			
			--, rfq_data.part_id
			--, rfq_data.rfq_part_id
								 			
			, rfq_data.part_qty AS Quantity 
			, rfq_data.quantity_unit_value AS UnitValue 
			, rfq_data.post_production_process_value AS PostProductionProcessValue
			, rfq_data.material_name AS Material 
			, rfq_data.Process  AS Process 
			, rfq_data.buyer_contact_name AS Buyer 
			, rfq_data.rfq_buyer_status AS RFQStatus			 
			, rfq_data.rfq_created_on AS RFQCreatedOn 
			, rfq_data.Quotes_needed_by AS QuotesNeededBy
			, rfq_data.award_date AS AwardDate
			, rfq_likes.is_rfq_like AS IsRfqLike 
			, mnr.nps_score AS NPSScore  
			, COALESCE(rfq_data.rfq_thumbnail_name,'') AS RfqThumbnail							 
		FROM vw_get_RFQ_Data as rfq_data
			LEFT JOIN mp_rfq_supplier_likes AS rfq_likes 
			ON rfq_data.rfq_id = rfq_likes.rfq_id
			and rfq_data.supplier_company_id = rfq_likes.company_id
			and rfq_data.supplier_contact_id = rfq_likes.contact_id
			-- LEFT JOIN mp_nps_rating mnr on mnr.contact_id = rfq_data.buyer_contact_id -- jan 10, 2019 
			LEFT JOIN mp_nps_rating mnr on mnr.company_id = rfq_data.buyer_company_id
		WHERE 
			 rfq_data.supplier_contact_id = @contactId 
			 AND rfq_data.supplier_company_id = @companyId 
			 --AND rfq_data.part_qty=(SELECT max(part_qty) FROM mp_rfq_part_quantity WHERE rfq_part_id = rfq_data.rfq_part_id) 
			 AND rfq_data.rfq_part_quantity_id=(SELECT max(a.rfq_part_quantity_id) FROM mp_rfq_part_quantity a join mp_rfq_parts b on a.rfq_part_id = b.rfq_part_id and b.rfq_id = rfq_data.rfq_id) 
			 and rfq_userStatus_id in (1,2)
			 and buyer_status_id >= 3
			 and rfq_likes.is_rfq_like = 0
			 ORDER BY QuotesNeededBy DESC
	END	 

	------------------------ All Vision Rfq --------------------
	else if (@RfqType = 10)	
	BEGIN	
		 SELECT TOP(100)
			mp_rfq.rfq_id AS RFQId
			, mp_rfq.rfq_name AS RFQName				 
			, mp_special_files.file_name AS file_name
			, mp_rfq_part_quantity.part_qty AS Quantity
			, Unit.value AS UnitValue
			, Processes.value AS PostProductionProcessValue
			, mp_mst_materials.material_name AS Material
			, mp_mst_part_category.discipline_name AS Process
			, mp_companies.name AS Buyer
			, mp_mst_rfq_buyerStatus.rfq_buyerstatus_li_key AS RFQStatus
			, mp_rfq.rfq_created_on AS RFQCreatedOn
			, mp_rfq.Quotes_needed_by AS QuotesNeededBy
			, mp_rfq.award_date AS AwardDate
			, mp_rfq_supplier_likes.is_rfq_like AS IsRfqLike
			, mp_nps_rating.nps_score AS NPSScore
			, COALESCE(ThumbnailFile.File_Name,'') AS RfqThumbnail							 
		FROM  mp_rfq
			 LEFT JOIN mp_rfq_supplier_likes  ON mp_rfq_supplier_likes.rfq_id = mp_rfq.rfq_id
			 LEFT JOIN mp_special_files AS ThumbnailFile ON ThumbnailFile.file_id = mp_rfq.file_id
			 JOIN mp_contacts ON mp_rfq.contact_id=mp_contacts.contact_id
			 -- LEFT JOIN mp_nps_rating mnr on mnr.contact_id = rfq_data.buyer_contact_id -- jan 10, 2019 
			 LEFT JOIN mp_nps_rating  on mp_nps_rating.company_id = mp_contacts.company_id
			 JOIN mp_companies ON mp_contacts.company_id=mp_companies.company_id
			 JOIN mp_mst_rfq_buyerStatus ON mp_rfq.rfq_status_id=mp_mst_rfq_buyerStatus.rfq_buyerstatus_id
			 
			 JOIN mp_rfq_parts ON mp_rfq.rfq_id = mp_rfq_parts.rfq_id
			 JOIN mp_rfq_parts_file ON mp_rfq_parts.rfq_part_id = mp_rfq_parts_file.rfq_part_id
			 JOIN mp_special_files ON mp_special_files.file_id = mp_rfq_parts_file.file_id
			 JOIN mp_rfq_part_quantity ON mp_rfq_part_quantity.rfq_part_id = mp_rfq_parts.rfq_part_id
			 LEFT JOIN mp_system_parameters AS Processes ON Processes.id = mp_rfq_parts.Post_Production_Process_id AND Processes.sys_key = '@PostProdProcesses' 

			 JOIN mp_parts ON mp_parts.part_id = mp_rfq_parts.part_id 
			 LEFT JOIN mp_mst_materials ON mp_mst_materials.material_id = mp_parts.material_id
			 
			 LEFT JOIN mp_system_parameters AS Unit ON Unit.id = mp_parts.part_qty_unit_id AND Unit.sys_key = '@UNIT2_LIST' AND Unit.sys_key = '@UNIT2_LIST' 
			 JOIN mp_mst_part_category ON mp_mst_part_category.part_category_id = mp_parts.part_category_id 
		WHERE 			 			 			 
			 mp_rfq_parts.Is_Rfq_Part_Default = 1 
			 AND mp_rfq_parts_file.is_primary_file = 1 
			 AND mp_rfq_part_quantity.part_qty=(SELECT max(part_qty) FROM mp_rfq_part_quantity WHERE rfq_part_id = mp_rfq_parts.rfq_part_id) 			 
			 
		ORDER BY RFQCreatedOn DESC
	END

	------------------------ All Active Rfq --------------------
	else if (@RfqType = 11)	
	BEGIN	
		 SELECT 
			mp_rfq.rfq_id AS RFQId
			, mp_rfq.rfq_name AS RFQName			
			, mp_special_files.file_name AS file_name
			, mp_rfq_part_quantity.part_qty AS Quantity
			, Unit.value AS UnitValue
			, Processes.value AS PostProductionProcessValue
			, mp_mst_materials.material_name AS Material
			, mp_mst_part_category.discipline_name AS Process
			, mp_companies.name AS Buyer
			, mp_mst_rfq_buyerStatus.rfq_buyerstatus_li_key AS RFQStatus
			, mp_rfq.rfq_created_on AS RFQCreatedOn
			, mp_rfq.Quotes_needed_by AS QuotesNeededBy
			, mp_rfq.award_date AS AwardDate
			, mp_rfq_supplier_likes.is_rfq_like AS IsRfqLike
			, mp_nps_rating.nps_score AS NPSScore
			, COALESCE(ThumbnailFile.File_Name,'') AS RfqThumbnail							 
		FROM  mp_rfq
			 LEFT JOIN mp_rfq_supplier_likes  ON mp_rfq_supplier_likes.rfq_id = mp_rfq.rfq_id
			 LEFT JOIN mp_special_files AS ThumbnailFile ON ThumbnailFile.file_id = mp_rfq.file_id
			 JOIN mp_contacts ON mp_rfq.contact_id=mp_contacts.contact_id
			 -- LEFT JOIN mp_nps_rating mnr on mnr.contact_id = rfq_data.buyer_contact_id -- jan 10, 2019 
			LEFT JOIN mp_nps_rating on mp_nps_rating.company_id = mp_contacts.company_id
			 JOIN mp_companies ON mp_contacts.company_id=mp_companies.company_id
			 JOIN mp_mst_rfq_buyerStatus ON mp_rfq.rfq_status_id=mp_mst_rfq_buyerStatus.rfq_buyerstatus_id
			 
			 JOIN mp_rfq_parts ON mp_rfq.rfq_id = mp_rfq_parts.rfq_id
			 JOIN mp_rfq_parts_file ON mp_rfq_parts.rfq_part_id = mp_rfq_parts_file.rfq_part_id
			 JOIN mp_special_files ON mp_special_files.file_id = mp_rfq_parts_file.file_id
			 JOIN mp_rfq_part_quantity ON mp_rfq_part_quantity.rfq_part_id = mp_rfq_parts.rfq_part_id
			 LEFT JOIN mp_system_parameters AS Processes ON Processes.id = mp_rfq_parts.Post_Production_Process_id AND Processes.sys_key = '@PostProdProcesses' 

			 JOIN mp_parts ON mp_parts.part_id = mp_rfq_parts.part_id 
			 LEFT JOIN mp_mst_materials ON mp_mst_materials.material_id = mp_parts.material_id
			 
			 LEFT JOIN mp_system_parameters AS Unit ON Unit.id = mp_parts.part_qty_unit_id AND Unit.sys_key = '@UNIT2_LIST' AND Unit.sys_key = '@UNIT2_LIST' 
			 JOIN mp_mst_part_category ON mp_mst_part_category.part_category_id = mp_parts.part_category_id 
		WHERE 			 			 			 
			 mp_rfq_parts.Is_Rfq_Part_Default = 1 
			 AND mp_rfq_parts_file.is_primary_file = 1 
			 AND mp_rfq_part_quantity.part_qty=(SELECT max(part_qty) FROM mp_rfq_part_quantity WHERE rfq_part_id = mp_rfq_parts.rfq_part_id) 			 
			 AND (GETUTCDATE() <= mp_rfq.Quotes_needed_by ) 
			 AND mp_rfq.rfq_status_id >= 3
			 AND mp_rfq.rfq_status_id NOT IN (5,13)
			 AND mp_rfq.contact_Id = @contactId
		ORDER BY RFQCreatedOn DESC
	END

	------------------------Rfq Marked for Quoting --------------------
	else if (@RfqType = 12)	
	BEGIN	
		 SELECT 
			mp_rfq.rfq_id AS RFQId
			, mp_rfq.rfq_name AS RFQName				 
			, mp_special_files.file_name AS file_name
			, mp_rfq_part_quantity.part_qty AS Quantity
			, Unit.value AS UnitValue
			, Processes.value AS PostProductionProcessValue
			, mp_mst_materials.material_name AS Material
			, mp_mst_part_category.discipline_name AS Process
			, mp_companies.name AS Buyer
			, mp_mst_rfq_buyerStatus.rfq_buyerstatus_li_key AS RFQStatus
			, mp_rfq.rfq_created_on AS RFQCreatedOn
			, mp_rfq.Quotes_needed_by AS QuotesNeededBy
			, mp_rfq.award_date AS AwardDate
			, mp_rfq_supplier_likes.is_rfq_like AS IsRfqLike
			, mp_nps_rating.nps_score AS NPSScore
			, COALESCE(ThumbnailFile.File_Name,'') AS RfqThumbnail							 
		FROM  mp_rfq
			 LEFT JOIN mp_rfq_supplier_likes  ON mp_rfq_supplier_likes.rfq_id = mp_rfq.rfq_id
			 LEFT JOIN mp_special_files AS ThumbnailFile ON ThumbnailFile.file_id = mp_rfq.file_id
			 JOIN mp_contacts ON mp_rfq.contact_id=mp_contacts.contact_id
			 -- LEFT JOIN mp_nps_rating mnr on mnr.contact_id = rfq_data.buyer_contact_id -- jan 10, 2019 
			LEFT JOIN mp_nps_rating  on mp_nps_rating.company_id = mp_contacts.company_id
			 JOIN mp_companies ON mp_contacts.company_id=mp_companies.company_id
			 JOIN mp_mst_rfq_buyerStatus ON mp_rfq.rfq_status_id=mp_mst_rfq_buyerStatus.rfq_buyerstatus_id
			 
			 JOIN mp_rfq_parts ON mp_rfq.rfq_id = mp_rfq_parts.rfq_id
			 JOIN mp_rfq_parts_file ON mp_rfq_parts.rfq_part_id = mp_rfq_parts_file.rfq_part_id
			 JOIN mp_special_files ON mp_special_files.file_id = mp_rfq_parts_file.file_id
			 JOIN mp_rfq_part_quantity ON mp_rfq_part_quantity.rfq_part_id = mp_rfq_parts.rfq_part_id
			 LEFT JOIN mp_system_parameters AS Processes ON Processes.id = mp_rfq_parts.Post_Production_Process_id AND Processes.sys_key = '@PostProdProcesses' 

			 JOIN mp_parts ON mp_parts.part_id = mp_rfq_parts.part_id 
			 LEFT JOIN mp_mst_materials ON mp_mst_materials.material_id = mp_parts.material_id
			 
			 LEFT JOIN mp_system_parameters AS Unit ON Unit.id = mp_parts.part_qty_unit_id AND Unit.sys_key = '@UNIT2_LIST' AND Unit.sys_key = '@UNIT2_LIST' 
			 JOIN mp_mst_part_category ON mp_mst_part_category.part_category_id = mp_parts.part_category_id 
			 JOIN mp_rfq_quote_suplierStatuses ON mp_rfq_parts.rfq_id=mp_rfq_quote_suplierStatuses.rfq_id
			 
		WHERE 			 			 			 
			 mp_rfq_parts.Is_Rfq_Part_Default = 1 
			 AND mp_rfq_parts_file.is_primary_file = 1 
			 AND mp_rfq_part_quantity.part_qty=(SELECT max(part_qty) FROM mp_rfq_part_quantity WHERE rfq_part_id = mp_rfq_parts.rfq_part_id) 			 
			 AND (GETUTCDATE() <= mp_rfq.Quotes_needed_by ) 
			 AND mp_rfq.rfq_status_id >= 3
			 AND mp_rfq.contact_Id = @contactId
			 AND mp_rfq_quote_suplierStatuses.rfq_userStatus_id=2
		ORDER BY RFQCreatedOn DESC
	END

	------------------------Supplier - Quots inprogress Rfq --------------------
	ELSE IF (@RfqType = 13)	
	BEGIN	
		SELECT DISTINCT 
			rfq_data.rfq_id AS RFQId 
			, rfq_data.rfq_name AS RFQName
			, rfq_data.part_file_name AS file_name	
			, rfq_data.part_qty AS Quantity 
			, rfq_data.quantity_unit_value AS UnitValue 
			, rfq_data.post_production_process_value AS PostProductionProcessValue
			, rfq_data.material_name AS Material 
			, rfq_data.Process  AS Process 
			, rfq_data.buyer_contact_name AS Buyer 
			, rfq_data.rfq_buyer_status AS RFQStatus			 
			, rfq_data.rfq_created_on AS RFQCreatedOn 
			, rfq_data.Quotes_needed_by AS QuotesNeededBy
			, rfq_data.award_date AS AwardDate
			, rfq_likes.is_rfq_like AS IsRfqLike 
			, mnr.nps_score AS NPSScore  
			, COALESCE(rfq_data.rfq_thumbnail_name,'') AS RfqThumbnail							 
		FROM vw_get_RFQ_Data as rfq_data
			LEFT JOIN mp_rfq_supplier_likes AS rfq_likes 
			ON rfq_data.rfq_id = rfq_likes.rfq_id
			and rfq_data.supplier_company_id = rfq_likes.company_id
			and rfq_data.supplier_contact_id = rfq_likes.contact_id
			-- LEFT JOIN mp_nps_rating mnr on mnr.contact_id = rfq_data.buyer_contact_id -- jan 10, 2019 
			LEFT JOIN mp_nps_rating mnr on mnr.company_id = rfq_data.buyer_company_id
		WHERE 
			 rfq_data.supplier_contact_id = @contactId 
			 AND rfq_data.supplier_company_id = @companyId 
			 AND rfq_data.rfq_part_quantity_id=(SELECT max(a.rfq_part_quantity_id) FROM mp_rfq_part_quantity a join mp_rfq_parts b on a.rfq_part_id = b.rfq_part_id and b.rfq_id = rfq_data.rfq_id) 
			 and rfq_userStatus_id in (2)
			 and buyer_status_id >= 3
			 and rfq_likes.is_rfq_like = 0
		ORDER BY QuotesNeededBy DESC
	END	 

END
