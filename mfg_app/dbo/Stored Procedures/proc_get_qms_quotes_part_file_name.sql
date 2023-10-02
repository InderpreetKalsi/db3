CREATE PROCEDURE proc_get_qms_quotes_part_file_name 
@qms_quote_id int
AS
BEGIN
	SELECT 
		QmsQuoteId	,CONVERT(VARCHAR(150),rn) +'. ' + PartName 	AS PartName	,FileId	,FileName	,ActualFileName ,PartId
	FROM
	(
		SELECT DISTINCT a.qms_quote_id as QmsQuoteId ,b.part_name as PartName, d.FILE_ID as FileId,d.FILE_NAME as FileName,
		ROW_NUMBER() OVER (ORDER BY a.qms_quote_id,B.qms_quote_part_id,d.FILE_ID)  rn, SUBSTRING(FILE_NAME,CHARINDEX('S3_',FILE_NAME)+3,LEN(FILE_NAME)) as ActualFileName ,b.qms_quote_part_id as PartId 
		FROM mp_qms_quotes a			(NOLOCK)  
		JOIN mp_qms_quote_parts b		(NOLOCK) on(a.qms_quote_id = b.qms_quote_id and b.is_active = 1)
		JOIN mp_qms_quote_part_files c  (NOLOCK) on(b.qms_quote_part_id = c.qms_quote_part_id  and c.status_id = 2)
		JOIN mp_special_files d			(NOLOCK) on(c.file_id = d.FILE_ID) 
		WHERE a.qms_quote_id = @qms_quote_id AND a.is_active = 1
	) a 
	ORDER BY a.QmsQuoteId,a.PartId  , a.FileId
END
