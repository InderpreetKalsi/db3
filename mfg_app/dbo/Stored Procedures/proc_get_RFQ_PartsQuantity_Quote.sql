
/*
EXEC proc_get_RFQ_PartsQuantity_Quote 1178811,1337827,1,0
*/
CREATE PROCEDURE [dbo].[proc_get_RFQ_PartsQuantity_Quote](@RFQ_ID int ,@contactId INT, @PartQtyLevel smallint=0,@IsRfqResubmitted BIT = 0 )
AS
-- =============================================
-- Create by: db-sb
-- Create date: 22 Nov, 2018
-- Description:	Procedure to return the RFQ Parts Quote data. @PartQtyLevel is optional and if passed 
--				it will return the RFQ Part's quantity for specified level(currently we are handling 
--				3 levels for same part quantity, like Quantity 1, Quantity 2, Quantity 3)
-- Example: [proc_get_RFQ_PartsQuantity_Quote] 1151419,1338135,0
-- =================================================================
--Version No – Change Date – Modified By      – CR No – Note
-- =================================================================
BEGIN

	--Veriable is to define the quantity level, in case in future we need to handle more that 3 levels 
	--then need to change @QuantityLevel value to new value.
	set nocount on
	
	/* Dec 13 2019 M2-2468 Buyer - Add Estimated Lead time to the buyer part - DB */
	
	DECLARE @QuantityLevel smallint = 3
	
	
	---Below SQL to return the raw RFQ parts quot data at available quantity level
	SELECT 
		 RfqParts.rfq_part_id		 
		, RfqQuoteItems.rfq_quote_items_id
		, RfqQuoteItems.is_awrded
		, RfqQuoteItems.rfq_part_quantity_id 
		, RfqQuoteItems.awarded_qty
		, mp_rfq_part_quantity.quantity_level +1 as quantity_level 	
		, Parts.part_name
		, Parts.part_number
		, RfqQuoteItems.rfq_quote_SupplierQuote_id
		, RfqQuoteItems.per_unit_price
		, RfqQuoteItems.tooling_amount
		, RfqQuoteItems.miscellaneous_amount
		, isnull(RfqQuoteItems.shipping_amount,0) as shipping_amount
		, RfqQuoteItems.est_lead_time_value as EstLeadTimeValue
		, RfqQuoteItems.est_lead_time_range as EstLeadTimeRange
		, mp_rfq_quote_SupplierQuote.buyer_feedback_id as buyerFeedbackId
		, mp_rfq_quote_SupplierQuote.quote_reference_number 
		, ROW_NUMBER() over (partition by RfqQuoteItems.rfq_part_id ,  mp_rfq_part_quantity.quantity_level  order by RfqQuoteItems.rfq_part_id ,  mp_rfq_part_quantity.quantity_level , RfqQuoteItems.rfq_quote_items_id desc) as PartQtySequence
		/* M2-3271 Buyer - Dashboard award module changes - DB */
		,RfqQuoteItems.status_id AS RfqPartStatusId
		,RfqQuoteItems.unit AS AwardedUnit
		,RfqQuoteItems.unit_type_id AS AwardedUnitTypeId
		,RfqQuoteItems.price AS AwardedPrice
		,RfqQuoteItems.is_continue_awarding As IsContinueAwarding
		/* M2-3599 M - Add Payment Terms to the Quote -DB*/
		,mp_rfq_quote_SupplierQuote.payment_terms AS SupplierPaymentTerms
		/**/
		into #tmpssbRFQQuotData
	FROM Mp_Parts Parts 
	JOIN mp_Rfq_Parts RfqParts ON Parts.part_id=RfqParts.part_id
	JOIN mp_rfq_part_quantity on mp_rfq_part_quantity.rfq_part_id = RfqParts.rfq_part_id
	LEFT JOIN Mp_Rfq_Quote_Items RfqQuoteItems ON RfqParts.Rfq_Part_Id=RfqQuoteItems.Rfq_Part_Id
	JOIN mp_rfq_quote_SupplierQuote ON mp_rfq_quote_SupplierQuote.rfq_quote_SupplierQuote_id = RfqQuoteItems.rfq_quote_SupplierQuote_id 
	and RfqQuoteItems.rfq_part_quantity_id = mp_rfq_part_quantity.rfq_part_quantity_id
	WHERE RfqParts.rfq_id=@RFQ_ID AND mp_rfq_quote_SupplierQuote.contact_id = @contactId AND mp_rfq_quote_SupplierQuote.is_rfq_resubmitted = @IsRfqResubmitted
	ORDER BY mp_rfq_part_quantity.rfq_part_quantity_id

	--select * from #tmpssbRFQQuotData

	--Below CTE to get each part for 3 times as we need to return dummy rows in case 
	--all parts quantity not quotated.
	;WITH partQtyLevel AS
	(
		select 
			RfqParts.rfq_part_id
			,  Parts.part_name
			, Parts.part_number 
			, 1 as VirtualQtyLevel 
		FROM Mp_Parts Parts  
		JOIN mp_Rfq_Parts RfqParts ON Parts.part_id = RfqParts.part_id
		WHERE RfqParts.rfq_id=@RFQ_ID AND RfqParts.status_id = 2

		UNION ALL

		select 
			RfqParts.rfq_part_id
			,  Parts.part_name
			, Parts.part_number 
			, VirtualQtyLevel+ 1 as VirtualQtyLevel  
		FROM Mp_Parts Parts  
		JOIN mp_Rfq_Parts RfqParts ON Parts.part_id = RfqParts.part_id
		JOIN partQtyLevel ctetbl on ctetbl.rfq_part_id = RfqParts.rfq_part_id
		WHERE RfqParts.rfq_id=@RFQ_ID AND RfqParts.status_id = 2
		and VirtualQtyLevel<@QuantityLevel 

	) 

	SELECT * into #tmpRFQPartsData from partQtyLevel order by rfq_part_id
 
	--select * from #tmpRFQPartsData

	--Final SQL to return the required data
	 SELECT 
		  partQuotData.rfq_quote_items_id AS RfqQuoteItemsId
		, partQuotData.is_awrded AS IsAwarded		  
		, PartQtyLevel.rfq_part_id	
		, PartQtyLevel.part_name	
		, PartQtyLevel.part_number	 
		, PartQtyLevel.VirtualQtyLevel  as VirtualQtyLevel
		, partQuotData.rfq_quote_items_id	
		, partQuotData.rfq_part_quantity_id	
		, partQuotData.quantity_level	 as quantity_level
		, partQuotData.awarded_qty	
		, partQuotData.rfq_quote_SupplierQuote_id	
		, partQuotData.per_unit_price	
		, COALESCE(partQuotData.tooling_amount,0) AS tooling_amount
		, COALESCE(partQuotData.miscellaneous_amount,0) AS miscellaneous_amount
		, COALESCE(partQuotData.shipping_amount,0) AS shipping_amount	
		, EstLeadTimeValue
		, EstLeadTimeRange
		, partQuotData.buyerFeedbackId
		, partQuotData.quote_reference_number
		/* M2-3271 Buyer - Dashboard award module changes - DB */
		, RfqPartStatusId
		, AwardedUnit
		, AwardedUnitTypeId
		, AwardedPrice
		, IsContinueAwarding
		/**/
		/* M2-3599 M - Add Payment Terms to the Quote -DB*/
		, SupplierPaymentTerms
		/**/
	 FROM #tmpRFQPartsData AS PartQtyLevel
		LEFT JOIN #tmpssbRFQQuotData AS partQuotData on PartQtyLevel.rfq_part_id = partQuotData.rfq_part_id 
		AND  PartQtyLevel.VirtualQtyLevel = partQuotData.quantity_level
	 WHERE 
	 PartQtySequence = 1 and 
	 (
		(PartQtyLevel.VirtualQtyLevel  = @PartQtyLevel
		OR @PartQtyLevel =0)
	 )
	 Order by PartQtyLevel.rfq_part_id	, PartQtyLevel.VirtualQtyLevel

 DROP TABLE #tmpRFQPartsData
 DROP TABLE #tmpssbRFQQuotData

 END
