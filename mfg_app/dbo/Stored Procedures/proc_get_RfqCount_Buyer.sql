

-- =============================================
-- Author:		dp-sb
-- Create date:  12/12/2018
-- Description:	Stored procedure to Get buyer side count 
-- Modification:
-- Example: [proc_get_RfqCount_Buyer] 1371102
-- =================================================================
--Version No – Change Date – Modified By      – CR No – Note
-- =================================================================
CREATE PROCEDURE [dbo].[proc_get_RfqCount_Buyer]
	@BuyerContactId INT
AS
BEGIN
 
------------------------ Awarded Rfqs by Buyers --------------------	 
	--This will gives count of awarder RFQ but Award is yet to accept
		SELECT 
			'AWARDED_RFQ' as RfqType
			, count(distinct mr.rfq_id) as TotalCount
		FROM mp_rfq_quote_items mrqi
			JOIN mp_rfq_quote_SupplierQuote mrqsq on mrqi.rfq_quote_SupplierQuote_id = mrqsq.rfq_quote_SupplierQuote_id  
			JOIN mp_rfq mr on mrqsq.rfq_id = mr.rfq_id
				AND mrqi.is_awrded = 1 and is_award_accepted = 0
				AND mr.contact_id = @BuyerContactId
				and is_rfq_resubmitted = 0

Union ALL

------------------------ Mark for Quoting RFQ Count --------------------
	 
	 SELECT  
	 'MARK_FOR_QUOTED_RFQ' AS RfqType,
	 COUNT(DISTINCT mp_rfq.rfq_id) AS TotalCount
		FROM  mp_rfq
			 JOIN mp_rfq_parts ON mp_rfq.rfq_id = mp_rfq_parts.rfq_id
			 JOIN mp_rfq_parts_file ON mp_rfq_parts.rfq_part_id = mp_rfq_parts_file.rfq_part_id
			 JOIN mp_rfq_part_quantity ON mp_rfq_part_quantity.rfq_part_id = mp_rfq_parts.rfq_part_id
			 JOIN mp_rfq_quote_suplierStatuses ON mp_rfq_parts.rfq_id=mp_rfq_quote_suplierStatuses.rfq_id
		WHERE 			 			 			 
			 mp_rfq.contact_Id = @BuyerContactId
			 AND mp_rfq_parts_file.is_primary_file = 1 
			 AND mp_rfq_part_quantity.rfq_part_quantity_id=(SELECT min(a.rfq_part_quantity_id) 
														FROM mp_rfq_part_quantity a 
														join mp_rfq_parts b on a.rfq_part_id = b.rfq_part_id 
														and b.rfq_id = mp_rfq.rfq_id and b.status_id != 12 
														and b.Is_Rfq_Part_Default =  1) 
			 AND mp_rfq.rfq_status_id= 3			
			 AND mp_rfq_quote_suplierStatuses.rfq_userStatus_id=2
			 


Union ALL
------------------------ New Quotes Count --------------------
	 
		SELECT 
		'NEW_QUOTES' AS RfqType
		,COUNT(DISTINCT supQuote.rfq_id) AS TotalCount
		FROM mp_rfq_quote_SupplierQuote supQuote
		JOIN mp_rfq on supQuote.rfq_id=mp_rfq.rfq_id
		JOIN mp_contacts on supQuote.contact_id =mp_contacts.contact_id		
		LEFT JOIN mp_rfq_quote_items MRQI ON MRQI.rfq_quote_SupplierQuote_id = supQuote.rfq_quote_SupplierQuote_id    /* M2-4265 */
		WHERE mp_rfq.contact_id=@BuyerContactId	 and is_rfq_resubmitted = 0 AND supQuote.is_quote_submitted = 1  and is_reviewed = 0
		--as compared with proc_get_BuyerQuotes and commented 
		--and is_reviewed = 0 
		--AND mp_rfq.rfq_status_id NOT IN (5,13)
		AND mp_rfq.rfq_status_id NOT IN (1,13)
		AND mp_rfq.IsArchived <> 1       /* M2-4265 Starts */
		AND ISNULL(MRQI.is_awrded,'') = 0	
		AND rfq_status_id <> 18				/* M2-4265 Ends   */

			
	Union ALL
------------------------ RFQ Quotes decline by Buyers --------------------
	--This will return the total new Quotes declined by Buyers
	--new mening RFQ for the same is not Closed or Retracted 
		SELECT 
			'DECLINE_QUOTES' AS RfqType
			, COUNT(DISTINCT mrqi.rfq_quote_SupplierQuote_id) AS TotalCount
		FROM mp_rfq_quote_items mrqi
			JOIN mp_rfq_quote_SupplierQuote mrqsq on mrqi.rfq_quote_SupplierQuote_id = mrqsq.rfq_quote_SupplierQuote_id  
			JOIN mp_rfq mr on mrqsq.rfq_id = mr.rfq_id
			JOIN mp_mst_rfq_buyerStatus mmrbs on mmrbs.rfq_buyerstatus_id = mr.rfq_status_id
			AND mmrbs.rfq_buyerstatus_li_key in ('RFX_BUYERSTATUS_CLOSED','RFX_BUYERSTATUS_RETRACTED')
			AND mrqi.is_awrded = 0
			AND mr.contact_id = @BuyerContactId and is_rfq_resubmitted = 0
		 

Union All
------------------------ Special Invite Rfq Count --------------------
		 SELECT 
			'SPECIAL_INVITE' As RfqType
			,  count(mm.message_id) As TotalCount						 
			--select *
		 FROM 
				mp_messages mm
		 JOIN mp_mst_message_types mt ON mm.message_type_id = mt.message_type_id
		 AND mt.message_type_name = 'RFQ_BUYER_INVITATION'
		 AND message_read = 0
		 AND mm.from_cont  = @BuyerContactId


Union All
------------------------Buyer's Profile View --------------------
		 SELECT 
			'PROFILE_VIEW' As RfqType
			,  count(viewProf.ContactId) As TotalCount	
			 
		FROM 
				mp_ViewedProfile viewProf
				join mp_contacts cont ON viewProf.CompanyID_Profile=cont.company_id
				WHERE cont.contact_id=@BuyerContactId and cont.is_buyer=1
		 
		 

Union All
-------------------------- M2-491 NDA's to Approve count --------------------

SELECT 
			'NDA_TO_APPROVE' As RfqType 
			,COUNT(r.rfq_id) As TotalCount
		FROM 
	mp_rfq r
	left join mp_rfq_supplier_nda_accepted NdaAccepted on r.rfq_id=NdaAccepted.rfq_id --And NdaAccepted.contact_id=@ContactId--
	left join 
	(
	select a.* from mp_messages a
		join 
		--(select RFQ_ID , to_cont, min(message_id)  message_id from mp_messages where MESSAGE_TYPE_ID in (2, 42, 148,154) group by RFQ_ID , to_cont ) b on a.message_id = b.message_id -- add to_contact in group by for proper message status
		(select RFQ_ID , to_cont, min(message_id)  message_id from mp_messages mess join mp_mst_message_types mmmt on  mess.MESSAGE_TYPE_ID = mmmt.MESSAGE_TYPE_ID where message_type_name in ('rfqPermissionRequest', 'MESSAGE_TYPE_CONFIDENTIALITY_AGREEMENT', 'RFQ_RELEASED_BY_ENGINEERING','RFQ_EDITED_RESUBMIT_QUOTE') group by RFQ_ID , to_cont  ) b on a.message_id = b.message_id -- add to_contact in group by for proper message status
	
	)
	 m  --inner
		on m.RFQ_ID = r.RFQ_ID    
		and NdaAccepted.contact_id = m.to_cont  -- add after adding to_contact in group by 
		--and m.mESSAGE_TYPE_ID in (2, 42) -- NDA
		--and m.mESSAGE_TYPE_ID in (2, 42, 148,154) -- NDA
		and m.mESSAGE_TYPE_ID in (2, 42,203,208,202) -- NDA

	left join mp_mst_message_types mt  --inner
		on mt.MESSAGE_TYPE_ID = m.MESSAGE_TYPE_ID

	----------------inner join mp_contacts authorCont
	----------------	on authorCont.contact_id = m.REAL_FROM_CONT_ID
	--------****Change in Join
		----inner join mp_contacts authorCont
		----on authorCont.contact_id = r.contact_id
		inner join mp_contacts authorCont
		on authorCont.contact_id = NdaAccepted.contact_id
	left join mp_nps_rating NpsRating on authorCont.company_id =NpsRating.company_id
	inner join mp_companies authorCompany
		on authorCompany.company_id = authorcont.company_id
	left join mp_mst_message_status authorStatus  --inner
		on authorStatus.MESSAGE_STATUS_ID = m.MESSAGE_STATUS_ID_AUTHOR
	----------------inner join mp_mst_message_status recipientStatus
	----------------	on recipientStatus.message_status_id = m.MESSAGE_STATUS_ID_RECIPIENT
	left join mp_messages ndaRevoked
		on ndaRevoked.MESSAGE_HIERARCHY = m.MESSAGE_ID
		and ndaRevoked.MESSAGE_TYPE_ID = 46 -- revoked
		and ndaRevoked.IS_LAST_MESSAGE = 1
	where
		
	r.contact_id = @BuyerContactId
	-- and award_date >= GETDATE()
	--AND rfq_status_id=5					--M2-4185
	AND Quotes_needed_by >= GETDATE()	--M2-4185
	and r.pref_NDA_Type=2--should show only level 2 RFQ
	--------------------and authorCompany.SALES_STATUS_ID <> 2 -- Remove X MFG
	and (authorStatus.MESSAGE_STATUS_TOKEN NOT IN('ACCEPTED','DECLINED')OR authorStatus.MESSAGE_STATUS_TOKEN IS NULL)--once accept/declined rfq should not be in the list. I it only for 'NDA to approve'
	and authorcont.is_active = 1 -- Contact still active.
	AND rfq_status_id != 5					--M2-5002
	--order by 1
			 
--Union All
-------------------------- Awarded Rfq Count --------------------
--		SELECT 'NDA_TO_SIGN_REQUIRED_RESIGN' As RfqType, 0 As TotalCount

  Union All 
  --------------------------Rfq To Award Count --------------------
  SELECT 'RFQ_TO_AWARD' as RfqType
			, count(distinct mrqsq.rfq_id) as TotalCount
		
		FROM mp_rfq_quote_items mrqi
		JOIN mp_rfq_quote_SupplierQuote mrqsq on mrqi.rfq_quote_SupplierQuote_id = mrqsq.rfq_quote_SupplierQuote_id  
		JOIN mp_rfq  mrfq on mrqsq.rfq_id = mrfq.rfq_id
		WHERE 
				ISNULL(mrqi.is_awrded,0) = 0
				AND 
				mrfq.contact_id = @BuyerContactId
				AND mrqsq.is_quote_submitted = 1
				and mrqsq.is_rfq_resubmitted = 0
				AND  mrfq.rfq_status_id IN (5) 
   Union All 
  --------------------------Rfq To Award Count --------------------
	SELECT 'MY_RFQ_COUNT' as RfqType
		, COUNT(DISTINCT a.rfq_id) as TotalCount 
	FROM mp_rfq  a 
	JOIN mp_rfq_parts b ON a.rfq_id = b.rfq_id
	WHERE a.contact_id = @BuyerContactId AND a.rfq_status_id IN(2,3,5,6,9,14,15,16,17,18,20)  and IsArchived = 0
	--ORDER BY 1

   ---- Added with M2-5218
   Union All 
  --------------------------Rfq To Draft Count --------------------
	SELECT 'DRAFT_RFQ_CREATED' as RfqType
		, COUNT(DISTINCT a.rfq_id) as TotalCount 
	FROM mp_rfq  a 
	JOIN mp_rfq_parts b ON a.rfq_id = b.rfq_id
	WHERE a.contact_id = @BuyerContactId AND a.rfq_status_id IN(1)   
	 Union All 
  --------------------------Released an RFQ to the MP Count --------------------
	SELECT 'RFQ_TO_RELEASED' as RfqType
		, COUNT(DISTINCT a.rfq_id) as TotalCount 
	FROM mp_rfq  a 
	JOIN mp_rfq_parts b ON a.rfq_id = b.rfq_id
	WHERE a.contact_id = @BuyerContactId AND a.rfq_status_id IN(2)   
	ORDER BY 1


END
