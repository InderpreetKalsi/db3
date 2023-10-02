
CREATE PROCEDURE DBO.proc_set_RevisionData_CleanupRFQPartsNQuantity 
AS
-- =============================================
-- Author:		dp-sb
-- Create date:  21/12/2018
-- Description:	Stored procedure to set RFQ Part Quantity historical data for further processing.
-- Modification:
-- Example: proc_set_RevisionData_CleanupRFQCertificateData
-- =================================================================
--Version No – Change Date – Modified By      – CR No – Note
-- =================================================================
BEGIN
	---Get the RFQ special certificates json data for cleaning
	IF OBJECT_ID('tempdb..#tmpJsonDataRFQ') IS NOT NULL DROP TABLE #tmpJsonDataRFQ; 
	SELECT 
		tablename + '' +  COALESCE(
					(select top 1 [value] FROM OPENJSON(field) a where [key]='RfqPartId') 
					, (select top 1 [value] FROM OPENJSON(oldvalue) a where [key]='RfqPartId') 
					, (select top 1 [value] FROM OPENJSON(newvalue) a where [key]='RfqPartId') 
				) + convert(varchar(10), FORMAT(creation_date, 'HHmm')) as SearchVal
		, COALESCE(
					(select top 1 [value] FROM OPENJSON(field) a where [key]='RfqPartId') 
					, (select top 1 [value] FROM OPENJSON(oldvalue) a where [key]='RfqPartId') 
					, (select top 1 [value] FROM OPENJSON(newvalue) a where [key]='RfqPartId') 
				) as RFQ_ID
		--, FORMAT(creation_date, 'HH:mm') as TimeNumber
		, * 
		INTO #tmpJsonDataRFQ
	FROM 
		mp_data_history_working
	WHERE  tablename in ('mp_rfq_part_quantity')
	and is_processed = 0	
		
		 
	---Combining multiple rows for as newvalue and old value is getting inserted in 
	---individual rows wvery time when certificate information updated for RFQ
	IF OBJECT_ID('tempdb..#tmpMergedJsonDataRFQ') IS NOT NULL DROP TABLE #tmpMergedJsonDataRFQ; 
	SELECT t.SearchVal, t.RFQ_ID, max(data_history_id) as data_history_id
      ,'[' + STUFF(( SELECT ', ' + oldvalue
                FROM #tmpJsonDataRFQ 
                WHERE SearchVal  = t.SearchVal
                FOR XML PATH(''),TYPE)
                .value('.','NVARCHAR(MAX)'),1,2,'') + ']' AS OldValueJson
		,  '[' + STUFF(( SELECT ', ' + newvalue
                FROM #tmpJsonDataRFQ 
                WHERE SearchVal  = t.SearchVal
                FOR XML PATH(''),TYPE)
                .value('.','NVARCHAR(MAX)'),1,2,'') + ']' AS NewValueJson
	INTO #tmpMergedJsonDataRFQ
	FROM #tmpJsonDataRFQ t
	GROUP BY t.SearchVal, t.RFQ_ID
	order by t.SearchVal, t.RFQ_ID

	--select * from #tmpMergedJsonDataRFQ
	--Mark raw Certificate data as Processed
	UPDATE actualData
		SET actualdata.is_processed = 1 
			, actualdata.processed_date = getdate()
	FROM 
	#tmpJsonDataRFQ tmpData
	join mp_data_history_working actualData
	on tmpData.data_history_id = actualData.data_history_id
	

	--Make Certificate data changes available for processing 
	UPDATE actualData
	SET actualData.oldvalue = mrgdData.OldValueJson
	, actualData.newvalue  = mrgdData.NewValueJson
	, is_processed = 0
	, actualdata.processed_date =null
	FROM #tmpMergedJsonDataRFQ   mrgdData
	join mp_data_history_working actualData
	on mrgdData.data_history_id = actualData.data_history_id
	---Finding the changes between the old and new values
END
