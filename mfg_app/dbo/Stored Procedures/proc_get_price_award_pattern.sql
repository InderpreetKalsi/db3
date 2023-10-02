
CREATE  PROCEDURE [dbo].[proc_get_price_award_pattern]
	@companyid int,
	@fromdate  datetime,
	@todate    datetime,
	@days      int
AS
BEGIN
IF(@days>0)
	BEGIN
		SELECT I.rfq_quote_SupplierQuote_id AS QuoteSupplierQuoteId,CONVERT(DATE,I.awarded_date,103)Awarded_date
			,SUM((ISNULL(per_unit_price,0)*ISNULL(I.awarded_qty,0)) 
				+ISNULL(tooling_amount,0)
				+ISNULL(miscellaneous_amount,0)
				+ISNULL(shipping_amount,0)) AS Price
		FROM mp_contacts C 
		INNER JOIN mp_rfq R on(C.contact_id = R.contact_id)
		INNER JOIN mp_rfq_quote_SupplierQuote S ON(R.rfq_id = S.rfq_id)
		INNER JOIN mp_rfq_quote_items I ON (S.rfq_quote_SupplierQuote_id =  I.rfq_quote_SupplierQuote_id)
		WHERE C.company_id = @companyid AND I.is_awrded = 1 AND CONVERT(DATE,I.awarded_date,103) BETWEEN @fromdate AND @todate
		GROUP BY I.rfq_quote_SupplierQuote_id,Awarded_date
	END
ELSE
	BEGIN
	SELECT I.rfq_quote_SupplierQuote_id AS QuoteSupplierQuoteId,CONVERT(DATE,I.awarded_date,103)Awarded_date
			,SUM((ISNULL(per_unit_price,0)*ISNULL(I.awarded_qty,0)) 
				+ISNULL(tooling_amount,0)
				+ISNULL(miscellaneous_amount,0)
				+ISNULL(shipping_amount,0)) AS Price
		FROM mp_contacts C 
		INNER JOIN mp_rfq R on(C.contact_id = R.contact_id)
		INNER JOIN mp_rfq_quote_SupplierQuote S ON(R.rfq_id = S.rfq_id)
		INNER JOIN mp_rfq_quote_items I ON (S.rfq_quote_SupplierQuote_id =  I.rfq_quote_SupplierQuote_id)
		WHERE C.company_id = @companyid AND I.is_awrded = 1 AND CONVERT(DATE,I.awarded_date,103) IS NOT NULL
		GROUP BY I.rfq_quote_SupplierQuote_id,Awarded_date
	END
END
