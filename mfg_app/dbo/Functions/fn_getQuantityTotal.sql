

CREATE FUNCTION [dbo].[fn_getQuantityTotal]
(
       @contactId int,
       @rfqId int,
	   @level int
)
RETURNS DECIMAL(18,4)
AS
BEGIN
       DECLARE @Result DECIMAL(18,4)
       SELECT @Result =(
	   
			SELECT SUM( ( (COALESCE(per_unit_price,0) * COALESCE(awarded_qty,0)) + COALESCE(tooling_amount,0)  +  COALESCE(miscellaneous_amount,0)  +  COALESCE(shipping_amount,0)   ) )  
			FROM mp_rfq_quote_SupplierQuote 
			JOIN mp_rfq ON mp_rfq_quote_SupplierQuote.rfq_id = mp_rfq.rfq_id			
			JOIN mp_rfq_quote_items ON  mp_rfq_quote_SupplierQuote.rfq_quote_SupplierQuote_id = mp_rfq_quote_items.rfq_quote_SupplierQuote_id
			JOIN mp_rfq_part_quantity ON mp_rfq_quote_items.rfq_part_quantity_id  = mp_rfq_part_quantity.rfq_part_quantity_id 
			AND mp_rfq_part_quantity.quantity_level = @level
			where mp_rfq_quote_SupplierQuote.contact_Id = @contactId AND mp_rfq_quote_SupplierQuote.is_quote_submitted = 1
			AND mp_rfq.rfq_id = @rfqId
			AND mp_rfq_quote_SupplierQuote.is_rfq_resubmitted = 0
			group by mp_rfq_quote_SupplierQuote.contact_Id ,mp_rfq_quote_SupplierQuote.rfq_Id  
	   )
       RETURN @Result
END
