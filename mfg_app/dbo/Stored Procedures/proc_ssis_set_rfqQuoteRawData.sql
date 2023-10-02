
CREATE PROCEDURE [dbo].[proc_ssis_set_rfqQuoteRawData](
@tblRFQQuoteDataType tblRFQQuoteDataType READONLY
)
-- =============================================
-- Author:		dp-sb
-- Create date:  30/11/2018
-- Description:	Stored procedure to set the legacy RFQ Quote data. This procedure in call in SSIS package.
-- Modification:
-- Example: [proc_ssis_set_rfqQuoteData]  
-- =================================================================
--Version No – Change Date – Modified By      – CR No – Note
-- =================================================================
AS
BEGIN

	truncate table tmp_SSIS_RFQ_Quote_data
	

	INSERT INTO tmp_SSIS_RFQ_Quote_data
	(
	 RFQID							
	, Supplier_Contact_id			  
	, Supplier_company_id			  
	, is_prefered_nda_type_accepted	  
	, prefered_nda_type_accepted_date 
	, payment_terms					  
	, is_payterm_accepted			  
	, QuoteReferenceNumber			  
	, IsSubmittedQuote				  
	, QuoteCreationDate				  
	, QuoteExpirationDate			  
	, PMS_ITEM_ID					  
	, grid_article					  
	, per_unit_price				  
	, tooling_amount				  
	, miscellaneous_amount			  
	, shipping_amount				  
	, is_awarded					  
	, QUANTITY_REF					  
	, is_award_accepted				  
	, AwardAcceptanceStatusDate		  )
	SELECT 
	 RFQID							
	, Supplier_Contact_id			  
	, Supplier_company_id			  
	, is_prefered_nda_type_accepted	  
	, prefered_nda_type_accepted_date 
	, payment_terms					  
	, is_payterm_accepted			  
	, QuoteReferenceNumber			  
	, IsSubmittedQuote				  
	, QuoteCreationDate				  
	, QuoteExpirationDate			  
	, PMS_ITEM_ID					  
	, grid_article					  
	, per_unit_price				  
	, tooling_amount				  
	, miscellaneous_amount			  
	, shipping_amount				  
	, is_awarded					  
	, QUANTITY_REF					  
	, is_award_accepted				  
	, AwardAcceptanceStatusDate	
	 FROM @tblRFQQuoteDataType
END
