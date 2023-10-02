
-- =============================================  
-- Author:  dp-AM. N.  
-- Create date: 27/11/2018  
-- Description: Stored procedure to Get buyer side Rfq list    
-- Modification:  
-- Example: [proc_get_BuyerRfqList] 1160917,1  
-- =================================================================  
--Version No – Change Date – Modified By      – CR No – Note  
-- =================================================================  
  
CREATE PROCEDURE [dbo].[proc_get_BuyerRfqList]  
  @RfqId INT,  
  @ContactId INT  
AS  
BEGIN  
  
IF (@RfqId>0)  
  
 SELECT   
 mp_rfq_quote_SupplierQuote.rfq_id AS RFQId  
 , mp_rfq.rfq_name AS RFQName,mp_rfq_quote_SupplierQuote.contact_id AS contactId  
 , (mp_contacts.first_name + ' ' + mp_contacts.last_name ) AS contactName  
 , mp_contacts.company_id AS CompanyId  
 , mp_rfq_quote_SupplierQuote.quote_date AS QuoteDate  
 , mp_rfq_quote_SupplierQuote.is_reviewed AS IsReviewed  
 /* M2-3318 Buyer - Change the My Quotes page to reflect Viewed and Reviewed - DB */
 , mp_rfq_quote_SupplierQuote.IsViewed AS IsViewed  
 /**/
, (  
  SELECT SUM(part_qty)   
  FROM mp_rfq_part_quantity (NOLOCK) WHERE rfq_part_id in (SELECT rfq_part_id FROM mp_rfq_parts WHERE rfq_id = @RfqId ) and   
  quantity_level = 1   
  
 ) AS Qty1  
 , (  
  SELECT SUM(part_qty)   
  FROM mp_rfq_part_quantity (NOLOCK)  WHERE rfq_part_id in (SELECT rfq_part_id FROM mp_rfq_parts WHERE rfq_id = @RfqId ) and   
  quantity_level = 2   
  
   ) AS Qty2  
 , (  
  SELECT SUM(part_qty)   
  FROM mp_rfq_part_quantity (NOLOCK)  WHERE rfq_part_id in (SELECT rfq_part_id FROM mp_rfq_parts WHERE rfq_id = @RfqId ) and   
  quantity_level = 3   
  
   ) AS Qty3  
  
 FROM mp_rfq_quote_SupplierQuote    (NOLOCK) 
 JOIN mp_rfq  (NOLOCK) on mp_rfq_quote_SupplierQuote.rfq_id=mp_rfq.rfq_id  
 JOIN mp_contacts  (NOLOCK) on mp_rfq_quote_SupplierQuote.contact_id =mp_contacts. contact_id  
 WHERE mp_rfq_quote_SupplierQuote.rfq_id=@RfqId  and is_rfq_resubmitted = 0  
  
 ELSE IF(@ContactId>0)   
   
 SELECT mp_rfq_quote_SupplierQuote.rfq_id AS RFQId,mp_rfq.rfq_name AS RFQName,mp_rfq_quote_SupplierQuote.contact_id AS contactId  
 ,(mp_contacts.first_name + ' ' + mp_contacts.last_name ) AS contactName  
 ,mp_contacts.company_id AS CompanyId  
 ,mp_rfq_quote_SupplierQuote.quote_date AS QuoteDate  
 ,mp_rfq_quote_SupplierQuote.is_reviewed AS IsReviewed    
 /* M2-3318 Buyer - Change the My Quotes page to reflect Viewed and Reviewed - DB */
 , mp_rfq_quote_SupplierQuote.IsViewed AS IsViewed
 /**/
 ,(  
  SELECT SUM(part_qty)   
  FROM mp_rfq_part_quantity  (NOLOCK) WHERE rfq_part_id in (SELECT rfq_part_id FROM mp_rfq_parts WHERE rfq_id = @RfqId ) and   
  quantity_level = 1   
  
 ) AS Qty1  
 ,(  
  SELECT SUM(part_qty)   
  FROM mp_rfq_part_quantity  (NOLOCK) WHERE rfq_part_id in (SELECT rfq_part_id FROM mp_rfq_parts WHERE rfq_id = @RfqId ) and   
  quantity_level = 2   
  
 ) AS Qty2  
 ,(  
  SELECT SUM(part_qty)   
  FROM mp_rfq_part_quantity  (NOLOCK) WHERE rfq_part_id in (SELECT rfq_part_id FROM mp_rfq_parts WHERE rfq_id = @RfqId ) and   
  quantity_level = 3   
  
 ) AS Qty3  
  
 FROM mp_rfq_quote_SupplierQuote    (NOLOCK) 
 JOIN mp_rfq  (NOLOCK) on mp_rfq_quote_SupplierQuote.rfq_id=mp_rfq.rfq_id  
 JOIN mp_contacts  (NOLOCK) on mp_rfq_quote_SupplierQuote.contact_id =mp_contacts. contact_id  
 WHERE mp_rfq.contact_id=@ContactId   and is_rfq_resubmitted = 0  
   
END
