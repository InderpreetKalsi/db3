CREATE PROCEDURE [dbo].[proc_get_qms_invoice_no]
(
	@supplier_company_id	INT,
	@is_creating_invoice	BIT = 0,
	@defaultValue			INT OUTPUT
)
AS
BEGIN
	/*
		M2-2410 M - Add starting invoice number to settings - DB
	*/
		
	SET NOCOUNT ON 

	DECLARE @CurrentInvoiceNo INT
	
	SET @defaultValue =  
	(		
		SELECT invoice_starting_seq_no 
		FROM mp_mst_qms_quote_invoice_seq_no (NOLOCK)
		WHERE company_id = @supplier_company_id 
	)


	IF @is_creating_invoice = 1
	BEGIN
	
		SET @CurrentInvoiceNo = 

			(
			SELECT MAX(CONVERT(INT,	invoice_no)) InvoiceNo FROM mp_qms_quote_invoices 
			WHERE 
				created_by IN
				(
					SELECT contact_id FROM mp_contacts WHERE company_id = @supplier_company_id AND is_buyer = 0
				)
			)


		SELECT 
			CASE 
				WHEN  @CurrentInvoiceNo IS NULL THEN @defaultValue
				WHEN  @CurrentInvoiceNo < @defaultValue THEN @defaultValue 
				WHEN  @CurrentInvoiceNo > @defaultValue THEN @CurrentInvoiceNo+1 
				WHEN  @CurrentInvoiceNo = @defaultValue THEN @CurrentInvoiceNo+1 
			ELSE @defaultValue 
		END  InvoiceNo

	END
	ELSE
		SELECT @defaultValue InvoiceNo


END
