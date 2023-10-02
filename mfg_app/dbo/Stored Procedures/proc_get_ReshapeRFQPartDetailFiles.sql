

/*
	M2-5112 Data - Install Upload Care
	M2-5129 B - Clone Rfq - Add & remove files to Reshape - DB
		 
	EXEC  [dbo].[proc_get_ReshapeRFQPartDetailFiles]
	 @RfqId       = 1164143
	,@RfqPartId   =  62746

	EXEC  [dbo].[proc_get_ReshapeRFQPartDetailFiles]
	 @RfqId       = 1164143
	,@RfqPartId   =  NULL
	
 */
   
   CREATE PROCEDURE [dbo].[proc_get_ReshapeRFQPartDetailFiles]
   (
	  @RfqId        INT
	 ,@RfqPartId    INT = NULL
 
   )
   AS
   BEGIN
   
    --DECLARE @RfqId      INT = 1164143
   	--     ,@RfqPartId  INT = null --62746

    SET NOCOUNT ON
   	
	DECLARE @FileURL					VARCHAR(4000)
	DECLARE @PartFilesCnt INT = 0 , @GeneralAttachmentsCnt INT = 0

	IF DB_NAME() = 'mp2020_dev'
	BEGIN
		SET @FileURL = 'https://uatfiles.mfg.com/RFQFiles/'
	END
	ELSE IF DB_NAME() = 'mp2020_uat'
	BEGIN	
		SET @FileURL = 'https://uatfiles.mfg.com/RFQFiles/'		
	END
	ELSE IF DB_NAME() = 'mp2020_prod'
	BEGIN		
		SET @FileURL = 'https://files.mfg.com/RFQFiles/'
	END
	    
	IF @RfqPartId IS NULL OR @RfqPartId = '' ---- Added with M2-5129
	BEGIN
	
	  ---RfqId ,RfqPartId ,FileId ,Filename ,FileS3Url
		SELECT 
		  c.rfq_id		AS [RfqId]
		, c.rfq_part_id  AS [RfqPartId]
		, a.[file_id]    AS [FileId]
		, CASE WHEN a.file_name IS NULL THEN '' WHEN a.file_name ='' THEN '' ELSE ISNULL(@FileURL + REPLACE(a.file_name,'&' ,'&amp;'),'') END AS [Url]
		--, CASE WHEN a.file_name IS NULL THEN '' ELSE  REPLACE(a.file_name,'&' ,'&amp;') END AS [FileName]
		, RIGHT( a.[file_name], (LEN(a.[file_name]) - (CHARINDEX( '_S3_',a.[file_name]) + 3)))   AS [FileName]
		FROM mp_special_files	a	(NOLOCK) 
		JOIN mp_rfq_parts_file	b	(NOLOCK) on a.FILE_ID=b.file_id 
			--AND a.ReshapeProjectUid IS NULL 
			--AND a.ReshapeFileUid IS NULL
			AND a.IS_DELETED = 0
		JOIN mp_rfq_parts c	(NOLOCK) on b.rfq_part_id =c.rfq_part_id 
		WHERE c.rfq_id = @RfqId
		ORDER BY b.FILE_ID  
	END
	ELSE
	BEGIN
 	  ---RfqId ,RfqPartId ,FileId ,Filename ,FileS3Url
		SELECT 
		  c.rfq_id		AS [RfqId]
		, c.rfq_part_id  AS [RfqPartId]
		, a.[file_id]    AS [FileId]
		, CASE WHEN a.file_name IS NULL THEN '' WHEN a.file_name ='' THEN '' ELSE ISNULL(@FileURL + REPLACE(a.file_name,'&' ,'&amp;'),'') END AS [Url]
		--, CASE WHEN a.file_name IS NULL THEN '' ELSE  REPLACE(a.file_name,'&' ,'&amp;') END AS [FileName]
		, RIGHT( a.[file_name], (LEN(a.[file_name]) - (CHARINDEX( '_S3_',a.[file_name]) + 3)))   AS [FileName]
		FROM mp_special_files	a	(NOLOCK) 
		JOIN mp_rfq_parts_file	b	(NOLOCK) on a.FILE_ID=b.file_id 
			AND a.ReshapeProjectUid IS NULL 
			AND a.ReshapeFileUid IS NULL
			AND a.IS_DELETED = 0
		JOIN mp_rfq_parts c	(NOLOCK) on b.rfq_part_id =c.rfq_part_id 
		WHERE c.rfq_id = @RfqId
		AND c.rfq_part_id = @RfqPartId
		ORDER BY b.FILE_ID  
	 END


	 END
