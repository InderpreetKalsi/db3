
/*

Order Management : If supplier cancelled PO then this SP data used in API call 

EXEC  proc_get_RfqPartQuoteDetails 1195739 --1195740 
*/
CREATE PROCEDURE [dbo].[proc_get_RfqPartQuoteDetails]
( @RfqId INT )
AS

BEGIN
	SET NOCOUNT ON

	--DECLARE @rfqid INT= 1195740 --1195739 --  --

	DECLARE @RfqQuoteInfo					VARCHAR(MAX)
	DECLARE @RfqQuotePartInfo				VARCHAR(MAX)
	 
	
	SET @RfqQuoteInfo = 
	(
  
 			SELECT DISTINCT 
				  NULL					AS awardAcceptedOrDeclineDate
				, NULL					AS awardedDate
				, 0						AS awardedQty
				, ''					AS awardedQtyUnit
				, ''					AS buyerFeedbackId
				, f.[SupplierContactId] AS contactId --- Supplier id
				, NULL					AS contactIdList  
				, ''					AS errorMessage
				, NULL					AS estLeadTimeRange
				, NULL					AS estLeadTimeValue
				, NULL					AS estLeadTimeValueRange
				, 0						AS isAlreadyAwrded
				, 0						AS isAwardAccepted
				, 0						AS IsAwrded
				, 0						AS IsDeclineAll
				, 0						AS isRfqResubmitted
				, 0						AS miscellaneousAmount
				, 0						AS partId
				, ''					AS	partName 
				, ''					AS 		partNumber
				, 0						AS perUnitPrice
				, 0						AS quantityLevel
				, 0						AS  result
				, a.rfq_id				AS rfqId
				, 0						AS rfqPartId
				, ''					AS rfqPartIdString
				, 0						AS rfqPartQuantityId
				, 0						AS rfqQuoteItemsId
				, a.rfq_quote_SupplierQuote_id AS rfqQuoteSupplierQuoteId
				, 0						AS shippingAmount
				, 0						AS toolingAmount
			FROM mp_rfq_quote_SupplierQuote(NOLOCK) a
				JOIN mp_rfq_quote_items( NOLOCK) b on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id
				JOIN mp_rfq_part_quantity (NOLOCK) c on c.rfq_part_quantity_id = b.rfq_part_quantity_id
				JOIN mp_rfq_parts(NOLOCK) d on d.rfq_part_id = c.rfq_part_id
				JOIN mp_parts(NOLOCK) e on e.part_id = d.part_id
				JOIN  mpOrderManagement (NOLOCK) f on f.rfqid = a.rfq_id  and f.SupplierContactId = a.contact_id  
				AND IsDeleted = 0
				JOIN mp_rfq(NOLOCK) g on g.rfq_id = f.rfqid
				LEFT JOIN mp_system_parameters (NOLOCK) h ON e.part_qty_unit_id = h.id
			WHERE    a.rfq_id = @rfqid
			FOR JSON PATH  , INCLUDE_NULL_VALUES , WITHOUT_ARRAY_WRAPPER 
		)


		SET @RfqQuotePartInfo = 
		(
			SELECT
			  NULL					AS awardedUnitTypeId
			, NULL					AS isAwarded
			, NULL					AS isRfqStatus
			, NULL					AS price
			, b.rfq_part_id			AS rfqPartId
			, 0						AS rfqPartStatusId
			, b.rfq_quote_items_id  AS rfqQuoteItemsId
			, NULL					AS unit
			FROM mp_rfq_quote_SupplierQuote(NOLOCK) a
				JOIN mp_rfq_quote_items( NOLOCK) b on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id
				JOIN mp_rfq_part_quantity (NOLOCK) c on c.rfq_part_quantity_id = b.rfq_part_quantity_id
				JOIN mp_rfq_parts(NOLOCK) d on d.rfq_part_id = c.rfq_part_id
				JOIN mp_parts(NOLOCK) e on e.part_id = d.part_id
				JOIN  mpOrderManagement (NOLOCK) f on f.rfqid = a.rfq_id  and f.SupplierContactId = a.contact_id  
				AND IsDeleted = 0
				JOIN mp_rfq(NOLOCK) g on g.rfq_id = f.rfqid
				LEFT JOIN mp_system_parameters (NOLOCK) h ON e.part_qty_unit_id = h.id
			WHERE    a.rfq_id = @rfqid
			FOR JSON PATH  , ROOT ('rfqQuoteItemList') , INCLUDE_NULL_VALUES 
		)
		 
		SET @RfqQuoteInfo = CONCAT( REPLACE(@RfqQuoteInfo,'}',',') , LEFT(RIGHT(@RfqQuotePartInfo,len(@RfqQuotePartInfo)-1),len(@RfqQuotePartInfo)-1)  ) -- REPLACE(REPLACE(@RfqQuotePartInfo,'{',''),'}','')
		SELECT @RfqQuoteInfo AS RfqQuoteInfo
	
	END
