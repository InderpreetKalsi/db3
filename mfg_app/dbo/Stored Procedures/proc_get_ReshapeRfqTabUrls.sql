
CREATE PROCEDURE proc_get_ReshapeRfqTabUrls
(
	@RfqId INT 
)
AS
--DECLARE @RfqId INT = 1164021 --1164022

BEGIN

	DECLARE @RfqEncryptedId			VARCHAR(100)
	DECLARE @SupplierUrl 	        VARCHAR(4000)
	DECLARE @SupplierUrl_History	VARCHAR(4000)
	DECLARE @SupplierUrl_Message	VARCHAR(4000)
	DECLARE @SupplierUrl_Quotes		VARCHAR(4000)
	DECLARE @SupplierUrl_Rfq		VARCHAR(4000)

	SELECT @RfqEncryptedId = RfqEncryptedId from mp_rfq (NOLOCK) where rfq_id = @RfqId
	  
	DROP TABLE IF EXISTS #tmpTabs
	CREATE TABLE #tmpTabs ( Id INT,TabName VARCHAR(25),[TabUrl] VARCHAR(4000))

	INSERT INTO #tmpTabs VALUES (1,'RFQ',NULL)
	INSERT INTO #tmpTabs VALUES (2,'QUOTES',NULL)
	INSERT INTO #tmpTabs VALUES (3,'MESSAGES',NULL)
	INSERT INTO #tmpTabs VALUES (4,'HISTORY',NULL)
	

	IF DB_NAME() = 'mp2020_uat'
	BEGIN
		SET @SupplierUrl = 'https://uatapp.mfg.com/#/supplier/supplerRfqDetails?rfqId='
		SET @SupplierUrl_History = @SupplierUrl + REPLACE(REPLACE(@RfqEncryptedId,'+','%2B'),'=','%3D')  + '&history=History'
		SET @SupplierUrl_Message = @SupplierUrl + REPLACE(REPLACE(@RfqEncryptedId,'+','%2B'),'=','%3D')  + '&message=Message'
		SET @SupplierUrl_Quotes  = @SupplierUrl + REPLACE(REPLACE(@RfqEncryptedId,'+','%2B'),'=','%3D')  + '&quotes=Quotes'
		SET @SupplierUrl_Rfq     = @SupplierUrl + REPLACE(REPLACE(@RfqEncryptedId,'+','%2B'),'=','%3D')  
 	END
	ELSE IF DB_NAME() = 'mp2020_prod'
	BEGIN
		SET @SupplierUrl = 'https://app.mfg.com/#/supplier/supplerRfqDetails?rfqId='
		SET @SupplierUrl_History = @SupplierUrl + REPLACE(REPLACE(@RfqEncryptedId,'+','%2B'),'=','%3D')  + '&history=History'
		SET @SupplierUrl_Message = @SupplierUrl + REPLACE(REPLACE(@RfqEncryptedId,'+','%2B'),'=','%3D')  + '&message=Message'
		SET @SupplierUrl_Quotes  = @SupplierUrl + REPLACE(REPLACE(@RfqEncryptedId,'+','%2B'),'=','%3D')  + '&quotes=Quotes'
		SET @SupplierUrl_Rfq     = @SupplierUrl + REPLACE(REPLACE(@RfqEncryptedId,'+','%2B'),'=','%3D')  
 	END
	ELSE IF DB_NAME() = 'mp2020_dev'
	BEGIN
		SET @SupplierUrl = 'https://qaapp.mfg.com/#/supplier/supplerRfqDetails?rfqId='
		SET @SupplierUrl_History = @SupplierUrl + REPLACE(REPLACE(@RfqEncryptedId,'+','%2B'),'=','%3D')  + '&history=History'
		SET @SupplierUrl_Message = @SupplierUrl + REPLACE(REPLACE(@RfqEncryptedId,'+','%2B'),'=','%3D')  + '&message=Message'
		SET @SupplierUrl_Quotes  = @SupplierUrl + REPLACE(REPLACE(@RfqEncryptedId,'+','%2B'),'=','%3D')  + '&quotes=Quotes'
		SET @SupplierUrl_Rfq     = @SupplierUrl + REPLACE(REPLACE(@RfqEncryptedId,'+','%2B'),'=','%3D')  
 	END

	--select @SupplierUrl_History AS [HistoryTab] ,@SupplierUrl_Message [MessageTab] ,@SupplierUrl_Quotes [QuotesTab],@SupplierUrl_Rfq [RfqTab]
	
	UPDATE #tmpTabs SET [TabUrl] = @SupplierUrl_Rfq WHERE id = 1
	UPDATE #tmpTabs SET [TabUrl] = @SupplierUrl_Quotes WHERE id = 2
	UPDATE #tmpTabs SET [TabUrl] = @SupplierUrl_Message WHERE id = 3
	UPDATE #tmpTabs SET [TabUrl] = @SupplierUrl_History WHERE id = 4

	SELECT TabName   ,TabUrl    FROM #tmpTabs


END
