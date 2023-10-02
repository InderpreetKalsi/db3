-- =============================================
-- Author:		dp-Am. N.
-- Create date:  01/11/2018
-- Description:	Stored procedure to Get supplier side Rfq count for contact and company 
-- Modification:
-- Example: [proc_get_SupplierRfqCount] 216582,337455
-- =================================================================
--Version No – Change Date – Modified By      – CR No – Note
-- =================================================================

CREATE PROCEDURE [dbo].[proc_get_SupplierRfqCount]
	@ContactId INT,
	@CompanyId INT
AS
BEGIN
 

  --DECLARE  @ContactId INT = 216582,
	 --@CompanyId INT = 337455

------------------------ ALL Rfq Count --------------------	 Added by dp-sb 
	  SELECT 'MyAllRFQ' as RfqType, sum(RFQCount) as RfqCount
	  FROM
		(
		SELECT DISTINCT 
			'SupplierAssignedRFQ' as RFQTypes,
			count(distinct rfq_data.rfq_id) AS RFQCount, 'All RFQ' as RFQCountType
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
			 and rfq_userStatus_id in (1,2)
			 and buyer_status_id >= 3
	Union
		--All RFQ Matching Supplier Capabilities and Territory
		SELECT distinct
			'LocationCapabilityMatching', 
			count(distinct rfq_data.rfq_id) AS RFQCount, 'All RFQ' as RFQCountType
			
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
		AND rfq_data.rfq_part_quantity_id=(SELECT max(a.rfq_part_quantity_id) FROM mp_rfq_part_quantity a join mp_rfq_parts b on a.rfq_part_id = b.rfq_part_id and b.rfq_id = rfq_data.rfq_id) 
		) as AllRFQCount
	Union ALL

------------------------ Liked Rfq Count --------------------
		SELECT 'MyLikedRfq' As RfqType, Count(distinct rfq_data.rfq_id) As RfqCount
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
		

Union All
------------------------ Special Invite Rfq Count --------------------
		SELECT 'SpecialInviteRfq' As RfqType,Count(distinct rfq_data.rfq_id) As RfqCount						 
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

Union All
------------------------ Quotes Rfq Count --------------------
		select 'MyQuotedRfq' As RfqType,Count(distinct rfq_data.rfq_id) As RfqCount 		 				 
		FROM vw_get_RFQ_Data as rfq_data
			JOIN mp_rfq_quote_SupplierQuote as rqsq on rfq_data.rfq_id = rqsq.rfq_id
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
			 
Union All
------------------------ Awarded Rfq Count --------------------

		select 'MyAwardedRfq' As RfqType,Count(distinct rfq_data.rfq_id) As RfqCount 		 			 
		FROM vw_get_RFQ_Data as rfq_data
			JOIN mp_rfq_quote_SupplierQuote as rqsq on rfq_data.rfq_id = rqsq.rfq_id
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
	UNION ALL	
------------------------Supplier - Quots inprogress Rfq --------------------
		SELECT 'MyRFQQuotesInProgress' As RfqType,Count(distinct rfq_data.rfq_id) As RfqCount 	
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
			
Union All
------------------------ Award Declined RFQ Count --------------------

		select 'AwardDeclinedRfq' As RfqType,Count(distinct mp_rfq.rfq_id) As RfqCount 
		  FROM mp_rfq 
			JOIN mp_rfq_quote_suplierStatuses ON mp_rfq.rfq_id = mp_rfq_quote_suplierStatuses.rfq_Id 
			LEFT JOIN mp_special_files AS ThumbnailFile ON ThumbnailFile.file_id = mp_rfq.file_id
			LEFT JOIN mp_rfq_supplier_likes ON mp_rfq.rfq_id = mp_rfq_supplier_likes.rfq_id AND mp_rfq_supplier_likes.company_Id = @companyId
			JOIN mp_contacts ON mp_rfq.contact_id=mp_contacts.contact_id
			LEFT JOIN mp_nps_rating mnr on mnr.company_id = mp_contacts.company_id  -- jan 10, 2019 change cintact id to company
			JOIN mp_companies ON mp_contacts.company_id=mp_companies.company_id
			JOIN mp_mst_rfq_buyerStatus ON mp_rfq.rfq_status_id=mp_mst_rfq_buyerStatus.rfq_buyerstatus_id

			JOIN mp_rfq_parts ON mp_rfq.rfq_id = mp_rfq_parts.rfq_id
			JOIN mp_rfq_parts_file ON mp_rfq_parts.rfq_part_id = mp_rfq_parts_file.rfq_part_id
			JOIN mp_special_files ON mp_rfq_parts_file.[file_id] = mp_special_files.[file_id]
			JOIN mp_rfq_part_quantity ON mp_rfq_parts.rfq_part_id = mp_rfq_part_quantity.rfq_part_id
			LEFT JOIN mp_system_parameters AS Processes ON mp_rfq_parts.Post_Production_Process_id = Processes.id AND Processes.sys_key = '@PostProdProcesses' 

			JOIN mp_parts ON mp_rfq_parts.part_id = mp_parts.part_id			
			LEFT JOIN mp_mst_materials ON mp_parts.material_id = mp_mst_materials.material_id 
			
			LEFT JOIN mp_system_parameters AS Unit ON mp_parts.part_qty_unit_id = Unit.id AND Unit.sys_key = '@UNIT2_LIST' 			
			JOIN mp_mst_part_category ON mp_parts.part_category_id = mp_mst_part_category.part_category_id
		WHERE 
			mp_rfq_parts.Is_Rfq_Part_Default = 1 
			AND mp_rfq_parts_file.is_primary_file = 1 
			AND mp_rfq_part_quantity.part_qty=(SELECT MAX(part_qty) FROM mp_rfq_part_quantity WHERE rfq_part_id = mp_rfq_parts.rfq_part_id) 
			--AND Processes.sys_key = '@PostProdProcesses' 
			--AND Unit.sys_key = '@UNIT2_LIST' 
			AND mp_mst_rfq_buyerStatus.rfq_buyerstatus_id = 9 	
			AND mp_rfq_quote_suplierStatuses.rfq_userStatus_id = 1			


Union All
------------------------ Followed Buyers Rfq Count --------------------

SELECT 'NDABuyerDeclinedRfq' As RfqType, 0 As RfqCount 	
		
Union All
------------------------ Followed Buyers Rfq Count --------------------

SELECT 'NDARequireResignRfq' As RfqType, 2 As RfqCount 



Union All
------------------------ Followed Buyers Rfq Count --------------------

		SELECT 'FollowedBuyersRfq' As RfqType, count(rfq_data.rfq_id) As RfqCount 		 
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
			-- LEFT JOIN mp_nps_rating mnr on mnr.contact_id = rfq_data.buyer_contact_id  -- jan 10, 2019
			LEFT JOIN mp_nps_rating mnr on mnr.company_id = rfq_data.buyer_company_id
		WHERE 
			 rfq_data.supplier_contact_id = @contactId 
			 AND rfq_data.supplier_company_id = @companyId 
			 AND rfq_data.part_qty=(SELECT max(part_qty) FROM mp_rfq_part_quantity WHERE rfq_part_id = rfq_data.rfq_part_id) 
			 AND rfq_data.rfq_part_quantity_id=(SELECT max(a.rfq_part_quantity_id) FROM mp_rfq_part_quantity a join mp_rfq_parts b on a.rfq_part_id = b.rfq_part_id and b.rfq_id = rfq_data.rfq_id) 
			 and rfq_userStatus_id in (1,2)
			 and buyer_status_id >= 3

 
END
