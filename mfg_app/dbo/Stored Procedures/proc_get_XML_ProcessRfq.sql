/*
UPDATE XML_MFGRfq SET IsIncludedInProcessXml = 0,IncludedInProcessXmlDate = null

DECLARE @XMLRfq XML;

EXEC proc_get_XML_ProcessRfq
    @PageNumber = 1,
	@PageSize = 5000,
	@ProcessId = 7455,
    @XMLOutRfq = @XMLRfq OUTPUT;

SELECT @XMLRfq AS 'RfqXML';
 
*/
CREATE PROCEDURE [dbo].[proc_get_XML_ProcessRfq]
(
	 @PageNumber					INT		= 1
    ,@PageSize					INT		= 1000
	,@ProcessId  INT
	,@XMLOutRfq		XML OUTPUT	
)
AS
BEGIN
	--M2-3747 Separate RFQ XML file for each process to push to the directory

	SET NOCOUNT ON

	DROP TABLE IF EXISTS #tmpXMLProcessRfq
	
	

	SELECT 
		*
	INTO #tmpXMLProcessRfq
	FROM XML_MFGRfq (NOLOCK)
	WHERE ProcessId = @ProcessId AND IsProcessed = 1 AND COALESCE(IsIncludedInProcessXml,0) =0
	ORDER BY [RecordDate] ASC
	OFFSET @PageSize * (@PageNumber - 1) ROWS
	FETCH NEXT @PageSize ROWS ONLY
	
	--SELECT * FROM #tmpXMLProcessRfq
	
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
		FROM  #tmpXMLProcessRfq
		FOR XML PATH('rfq'), ROOT('root'),ELEMENTS
	)


	UPDATE XML_MFGRfq SET IsIncludedInProcessXml = 1 , IncludedInProcessXmlDate = GETUTCDATE()  where ProcessId = @ProcessId AND IsProcessed = 1 AND COALESCE(IsIncludedInProcessXml,0) =0

END




