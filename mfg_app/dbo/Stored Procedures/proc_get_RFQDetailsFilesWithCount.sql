

/*
	M2-4974 M - Add Files tab to the RFQ details page

	 
	EXEC [proc_get_RFQDetailsFilesWithCount]
	 @RfqId       = 1162529
	,@FileType    = 1 --   1 : Part Files , 2 : General Attachments
	,@SearchText  = null
	,@PageNumber  = 1
	,@PageSize    = 24

   */
   
   CREATE PROCEDURE [dbo].[proc_get_RFQDetailsFilesWithCount]
   (
	  @RfqId        INT
	 ,@FileType     INT
	 ,@SearchText   VARCHAR(100) = NULL
	 ,@PageNumber   INT = 1
	 ,@PageSize     INT = 24
   )
   AS

    SET NOCOUNT ON
   	
	DECLARE @FileURL					VARCHAR(4000)
	DECLARE @PartFilesCnt INT = 0 , @GeneralAttachmentsCnt INT = 0

	IF DB_NAME() = 'mp2020_dev'
	BEGIN
		SET @FileURL = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.uat.test/RFQFiles/'
	END
	ELSE IF DB_NAME() = 'mp2020_uat'
	BEGIN	
		SET @FileURL = 'https://s3.us-east-2.amazonaws.com/mfg.mp2020.uat.test/RFQFiles/'		
	END
	ELSE IF DB_NAME() = 'mp2020_prod'
	BEGIN		
		SET @FileURL = 'https://files.mfg.com/RFQFiles/'
	END
	   

	---- First getting both the file count
	SELECT @PartFilesCnt = COUNT(1) 
	FROM mp_special_files	a	(NOLOCK) 
	JOIN mp_rfq_parts_file	b	(NOLOCK) on a.FILE_ID=b.file_id
	JOIN mp_rfq_parts c	(NOLOCK) on b.rfq_part_id =c.rfq_part_id 
	WHERE c.rfq_id = @RfqId
	--AND ( a.file_name LIKE '%' + @SearchText + '%' OR @SearchText IS NULL)


	SELECT  @GeneralAttachmentsCnt = COUNT(1) 
	FROM mp_special_files	a	(nolock) 
	JOIN mp_rfq_other_files	b	(nolock) on a.FILE_ID=b.file_id and b.status_id =2
	WHERE b.rfq_id = @RfqId
	--AND ( a.file_name LIKE '%' + @SearchText + '%' OR @SearchText IS NULL)

	--SELECT @PartFilesCnt AS PartFilesCnt, @GeneralAttachmentsCnt AS GeneralAttachmentsCnt
	 
	IF @FileType = 1 
	BEGIN
	
		SELECT 
		  CASE WHEN a.file_name IS NULL THEN '' ELSE  REPLACE(a.file_name,'&' ,'&amp;') END as [FileName]
		, CASE WHEN a.file_name IS NULL THEN '' WHEN a.file_name ='' THEN '' ELSE ISNULL(@FileURL + REPLACE(a.file_name,'&' ,'&amp;'),'') END AS FileURL
		, @PartFilesCnt AS PartFilesCnt 
		, @GeneralAttachmentsCnt AS GeneralAttachmentsCnt
		FROM mp_special_files	a	(NOLOCK) 
		JOIN mp_rfq_parts_file	b	(NOLOCK) on a.FILE_ID=b.file_id
		JOIN mp_rfq_parts c	(NOLOCK) on b.rfq_part_id =c.rfq_part_id 
		WHERE c.rfq_id = @RfqId
		AND ( a.file_name LIKE '%' + @SearchText + '%' OR @SearchText IS NULL)
		ORDER BY b.FILE_ID  
		OFFSET @pagesize * (@pagenumber - 1) ROWS
		FETCH NEXT @pagesize ROWS only	

	END
	ELSE 
	BEGIN
		 
		SELECT 
		 CASE WHEN a.file_name IS NULL THEN '' ELSE  REPLACE(a.file_name,'&' ,'&amp;') END as [FileName]
		, CASE WHEN a.file_name IS NULL THEN '' WHEN a.file_name ='' THEN '' ELSE ISNULL(@FileURL + REPLACE(a.file_name,'&' ,'&amp;'),'') END AS FileURL
		, @PartFilesCnt AS PartFilesCnt 
		, @GeneralAttachmentsCnt AS GeneralAttachmentsCnt
		FROM mp_special_files	a	(NOLOCK) 
		JOIN mp_rfq_other_files	b	(NOLOCK) on a.FILE_ID=b.file_id and b.status_id =2
		WHERE b.rfq_id = @RfqId
		AND ( a.file_name LIKE '%' + @SearchText + '%' OR @SearchText IS NULL)
		ORDER BY b.FILE_ID  
		OFFSET @pagesize * (@pagenumber - 1) ROWS
		FETCH NEXT @pagesize ROWS only	

	END
