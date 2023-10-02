/*
UPDATE XML_MFGRfq SET IsProcessed = 0

DECLARE @XMLRfq XML;

EXEC proc_get_XML_Rfq
    @PageNumber = 1,
	@PageSize = 5000,
    @XMLOutRfq = @XMLRfq OUTPUT;

SELECT @XMLRfq AS 'RfqXML';
 
*/
CREATE PROCEDURE [dbo].[proc_get_XML_Rfq]
(
	 @PageNumber					INT		= 1
    ,@PageSize					INT		= 1000
	,@XMLOutRfq		XML OUTPUT	
)
AS
BEGIN
	--M2-3722 API - New RFQ XML file to push to the Directory

	SET NOCOUNT ON

	DROP TABLE IF EXISTS #tmpXMLRfq
	
	

	SELECT 
		*
	INTO #tmpXMLRfq
	FROM XML_MFGRfq (NOLOCK)
	WHERE IsProcessed = 1 AND IsIncludedInXml =0
	ORDER BY [RecordDate] ASC
	OFFSET @PageSize * (@PageNumber - 1) ROWS
	FETCH NEXT @PageSize ROWS ONLY
	
	--SELECT * FROM #tmpXMLRfq
	
	SET @XMLOutRfq = 
	(
		SELECT  RfqId,
		RfqName,
		RfqThumbnail,
		RfqDesc,
		Process,
		Technique,
		Material,
		PostProcess,
		IsLargePart,
		MaxQuantity,
		RfqDeepLinkUrl,
		BuyerState,
		BuyerCountry,
		BuyerIndustry		 			
		FROM  #tmpXMLRfq
		FOR XML PATH('rfq'), ROOT('root'),ELEMENTS
	)


	UPDATE XML_MFGRfq SET IsIncludedInXml = 1 , IncludedDate = GETUTCDATE()  WHERE IsProcessed = 1 AND IsIncludedInXml =0

END




