 
CREATE  PROCEDURE [dbo].[proc_get-supplier-awarded-parts]
	 @RfqId INT,
	 @SupplierContactId INT	 
AS
-- =============================================
-- Author:		dp-Am. N.
-- Create date:  18/04/2019
-- Description:	Stored procedure to Get supplier side awarded parts
-- Modification:
-- Syntax: [proc_get-supplier-awarded-parts] <RfqId>,<SupplierContactId> 
-- Example: [proc_get-supplier-awarded-parts] 1148797,1337817 
 
-- =================================================================
--Version No – Change Date – Modified By      – CR No – Note
-- =================================================================

BEGIN		
	 
	DECLARE @message_descr varchar(max)
	, @MessageFileId INT 
	, @MessageId INT;
	SELECT @message_descr = mp_messages.message_descr FROM mp_messages where message_type_id = 220 AND rfq_id = @RfqId AND from_cont = @SupplierContactId AND trash = 0  		 
	SELECT @MessageFileId =  id  FROM mp_message_file where MESSAGE_ID = @MessageId		 
	 
	SELECT  d.part_name AS PartName
	 , d.part_number AS PartNumber
	 , b.awarded_date AS AwardedDate	   
	 , b.awarded_qty AS AwardedQty	   
	 , e.value AS awardedQtyUnit	  
	 , ((b.awarded_qty * b.per_unit_price) + COALESCE( b.tooling_amount,0 ) + COALESCE( b.miscellaneous_amount ,0 ) + COALESCE ( b.shipping_amount,0 )) AS TotalPrice		  
	 , case when (@message_descr IS NOT NULL OR @MessageFileId > 0 ) then  CAST('true' AS bit) else CAST('false' AS bit) end AS IsMessageAdded
	 , f.contact_id AS BuyerContactId
	 , (g.first_name + ' ' + g.last_name ) AS BuyerContactName
	 , @message_descr AS MessageDesc
	 FROM mp_rfq_quote_SupplierQuote a 	
	 join mp_rfq_quote_items b ON a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id AND b.is_awrded = 1
	 AND  a.contact_id = @SupplierContactId	AND a.is_rfq_resubmitted = 0
	 join mp_rfq_parts c ON b.rfq_part_id = c.rfq_part_id
	 join mp_parts d ON c.part_id = d.part_id
	 join mp_system_parameters e ON c.quantity_unit_id = e.Id
	 join mp_rfq f ON a.rfq_id = f.rfq_id
	 join mp_contacts g ON f.contact_id = g.contact_id
	 WHERE a.rfq_id = @RfqId 
	 	 
END
