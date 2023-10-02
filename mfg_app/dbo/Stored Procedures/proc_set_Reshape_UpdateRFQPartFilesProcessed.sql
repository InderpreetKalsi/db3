
/*
exec proc_set_Reshape_UpdateRFQPartFilesProcessed @json=N'{
    "reshape_project_uid": "99822d70-3077-4ecc-820b-0c9cb029af90",
    "reshape_file_uid": "fOolwbEosnFhCq0FtWzeo3HOxh4V4o90",
    "mfg_rfq_id": 1194661,
    "mfg_file_id": 440945,
    "is_processed": true,
    "scs_url": "s3://path/to/file90"
}'

*/

CREATE PROCEDURE [dbo].[proc_set_Reshape_UpdateRFQPartFilesProcessed]
(
	@json NVARCHAR(MAX)
)
AS

--DECLARE @json VARCHAR(MAX) =N'{
--    "reshape_project_uid": "99822d70-3077-4ecc-820b-0c9cb029af10",
--    "reshape_file_uid": "fOolwbEosnFhCq0FtWzeo3HOxh4V4o10",
--    "mfg_rfq_id": 1194661,
--    "mfg_file_id": 440944,
--    "is_processed": true,
--    "scs_url": "s3://path/to/file10"
--}'


BEGIN

BEGIN TRY
	SET NOCOUNT ON
	DECLARE @POPartJSON VARCHAR(MAX) 
	DECLARE @RfqId INT

	SET @POPartJSON =  REPLACE(@json,CHAR(160),'')

	DROP TABLE IF EXISTS #tmp_Reshape_UpdateFiles
	
	BEGIN TRAN

	---Convert JSON into tablular format
	SELECT * INTO #tmp_Reshape_UpdateFiles FROM
		(
			SELECT 
				i.[mfg_rfq_id], i.mfg_file_id AS [FileId], i.[is_processed], i.[reshape_project_uid], i.[reshape_file_uid], i.[scs_url]
			FROM OPENJSON(@POPartJSON) 
			WITH 
			(
			   mfg_rfq_id INT '$.mfg_rfq_id',
			   mfg_file_id INT '$.mfg_file_id',
			   is_processed BIT '$.is_processed',
			   reshape_project_uid VARCHAR(1000) '$.reshape_project_uid',
			   reshape_file_uid  VARCHAR(1000) '$.reshape_file_uid',
			   scs_url  VARCHAR(2000) '$.scs_url'
			) AS i
		) UpdateFiles
 
		---- getting RFQ ID from JSON
		SELECT DISTINCT @RfqId =  mfg_rfq_id FROM #tmp_Reshape_UpdateFiles
		 
 		---- Here update mp_rfq_parts_file -> IsFileProcessedByReshape based on FileId and mfg_part_id
		--UPDATE a
		--SET IsFileProcessedByReshape  =  b.is_processed
		--,ReshapeProjectUid = b.reshape_project_uid
		--,ReshapeFileUid = b.reshape_file_uid
		--FROM mp_rfq_parts_file(NOLOCK) a
		--JOIN #tmp_Reshape_UpdateFiles b on a.file_id = b.FileId
		--AND a.rfq_part_id = b.mfg_part_id
 
		---- Here update mp_special_files -> ReshapeFileProcessedURL based on FileId  
		UPDATE a
	    SET  a.ReshapeFileProcessedURL = b.scs_url 
		, a.IsFileProcessedByReshape =  b.is_processed
		, a.ReshapeProjectUid =  b.reshape_project_uid
		, a.ReshapeFileUid =  b.reshape_file_uid
		FROM  mp_special_files(NOLOCK) a
		JOIN #tmp_Reshape_UpdateFiles b on a.file_id = b.FileId
				
		---- Here update mp_rfq -> IsReshapeFileProcessed if against rfq any IsFileProcessedByReshape value 1 then update 1 else 0
		IF (	SELECT COUNT(1)
					FROM mp_special_files	a	(NOLOCK) 
					JOIN mp_rfq_parts_file	b	(NOLOCK) on a.FILE_ID=b.file_id
					JOIN mp_rfq_parts c	(NOLOCK) on b.rfq_part_id =c.rfq_part_id 
					WHERE c.rfq_id =  @RfqId   
					AND a.IsFileProcessedByReshape = 1
			)  > 0 
		BEGIN
			---- Here update mp_rfq -> IsReshapeFileProcessed based on rfq_id  
			UPDATE mp_rfq 
			SET IsReshapeFileProcessed = 1 
			WHERE rfq_id = @RfqId
		END
		ELSE
		BEGIN
		---- Here update mp_rfq -> IsReshapeFileProcessed based on rfq_id  if none of files are processed
			UPDATE mp_rfq 
			SET IsReshapeFileProcessed = 0 
			WHERE rfq_id = @RfqId
		END
			
		 /* Output */
		SELECT TransactionStatus  = 'Success'  

		INSERT INTO tmpOrderManagementflowlogs (RfqId,FlowName,POJSON)
		SELECT @RfqId
		,  'file process JSON by Reshape' 
		, @POPartJSON

		COMMIT
		 
END TRY
	BEGIN CATCH
		
		ROLLBACK

		SELECT TransactionStatus  = 'Fail - ' + ERROR_MESSAGE()

		INSERT INTO tmpOrderManagementflowlogs (RfqId,FlowName,POJSON)
		SELECT @RfqId
		, 'Error - file process JSON by Reshape' 
		, CONVERT(NVARCHAR(MAX), 'Failure' + ' - ' + ERROR_MESSAGE()  + ' - ' + @POPartJSON )
		
		
END CATCH

END
