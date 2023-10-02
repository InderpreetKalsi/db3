/*

select * from mpOrderManagement (nolock) where rfqid = 1195364 order by id desc 

exec proc_set_Reshape_UpdatePOPartStatus @json=N'{
  "rfq_id": 1162200,
  "quote_id": 155313,
  "po_mfg_unique_id": 100187,
  "is_part_completed": 0,
  "parts": [
    {
      "external_id": "60418",
      "quoted_quantity_id": 350610,
      "status": "In Production"
    },
    {
      "external_id": "60419",
      "quoted_quantity_id": 350614,
      "status": "Quality Inspection"
    }
  ]
}'

*/


CREATE PROCEDURE [dbo].[proc_set_Reshape_UpdatePOPartStatus]
(
	@json NVARCHAR(MAX)
)
AS
BEGIN

	-- M2-4849 Create new external facing API for Order Management - DB
	SET NOCOUNT ON

	--- remove/replace the no-break space 
	DECLARE @POPartJSON VARCHAR(MAX) 
	DECLARE @quoted_quantity_id VARCHAR(MAX) --(select value from string_split(@to_contacts, ',')) 
 	DECLARE @rfq_id INT
	DECLARE @to_contacts INT
	DECLARE @from_contact INT
	DECLARE @processStatus AS VARCHAR(MAX) = 'SUCCESS'
	DECLARE @ReshapeUniqueId UNIQUEIDENTIFIER

	SET @POPartJSON =  REPLACE(@json,CHAR(160),'')

	DROP TABLE IF EXISTS #tmp_proc_set_Reshape_UpdatePOPartStatus
	
	BEGIN TRY
		SELECT * INTO #tmp_proc_set_Reshape_UpdatePOPartStatus FROM
		(
			SELECT 
				i.rfq_id, i.[quote_id], i.[po_mfg_unique_id], a.[external_id], a.[quoted_quantity_id],a.[status], i.[is_part_completed]
			FROM OPENJSON(@POPartJSON) 
			WITH 
			(
			   rfq_id INT '$.rfq_id',
			   quote_id INT '$.quote_id',
			   po_mfg_unique_id INT '$.po_mfg_unique_id',
			   is_part_completed BIT '$.is_part_completed',
			   parts NVARCHAR(MAX) '$.parts' AS JSON
			) AS i
			CROSS APPLY OPENJSON(i.parts) 
			WITH 
			(
			   [external_id] INT '$.external_id',
			   [quoted_quantity_id] INT '$.quoted_quantity_id',
			   [status] NVARCHAR(MAX) '$.status' 
			) a
		) a

		BEGIN TRAN

		/* Getting ReshapeUniqueId */
		SELECT DISTINCT @ReshapeUniqueId = ReshapeUniqueId
		FROM mpordermanagement(NOLOCK) a
		JOIN #tmp_proc_set_Reshape_UpdatePOPartStatus b ON a.id = b.po_mfg_unique_id


		/* Getting Supplier information */  
		SELECT DISTINCT @from_contact =  a.contact_id
				FROM mp_rfq_quote_SupplierQuote(NOLOCK) a
				JOIN mp_rfq_quote_items(NOLOCK) b on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id AND b.is_awrded = 1
				JOIN #tmp_proc_set_Reshape_UpdatePOPartStatus h on h.quoted_quantity_id = b.rfq_quote_items_id


		/* Insert data into log table */
		INSERT INTO mpOrderManagementPartStatusChangeLogs
		(RfqId,RfqQuoteItemsId,OldStatus,NewStatus,RfqPartId,SupplierContactId,ReshapeUniqueId)
		SELECT b.rfq_id, rfq_quote_items_id, ISNULL(a.ReshapePartStatus,'') AS [OldStatus] , ISNULL(b.[status],'')  AS [NewStatus]
		,b.external_id ,@from_contact AS SupplierContactId, @ReshapeUniqueId as ReshapeUniqueId
		FROM  mp_rfq_quote_items(NOLOCK) a
		JOIN #tmp_proc_set_Reshape_UpdatePOPartStatus b on a.rfq_quote_items_id = b.quoted_quantity_id
		/* */
		
		INSERT INTO mp_data_history
		(field,oldvalue,newvalue,creation_date,userid,tablename)
		SELECT 
			'{"RfqPartId":'+CONVERT(VARCHAR(150),a.rfq_part_id )+'}'
			,'{"POPartStatus":"'+ISNULL(a.ReshapePartStatus,'')+'"}'
			,'{"POPartStatus":"'+ISNULL(b.[status],'')+'","ContactId":'+CONVERT(VARCHAR(150),c.contact_id )+'}'
			, GETUTCDATE() 
			, c.contact_id 
			, 'mp_rfq_parts'

		FROM  mp_rfq_quote_items (NOLOCK) a
		JOIN #tmp_proc_set_Reshape_UpdatePOPartStatus b on a.rfq_quote_items_id = b.quoted_quantity_id
		JOIN mp_rfq_quote_SupplierQuote (NOLOCK) c ON a.rfq_quote_SupplierQuote_id = c.rfq_quote_SupplierQuote_id
		JOIN mp_rfq_parts (NOLOCK) d ON a.rfq_part_id = d.rfq_part_id

		
		UPDATE a
			SET a.ReshapePartStatus = ISNULL(b.[status],'')
		FROM mp_rfq_quote_items  (NOLOCK) a
		JOIN #tmp_proc_set_Reshape_UpdatePOPartStatus b ON a.rfq_quote_items_id = b.[quoted_quantity_id]

		UPDATE a
		SET a.IsPartCompleted = b.is_part_completed
		FROM mpOrderManagement (NOLOCK) a
		JOIN #tmp_proc_set_Reshape_UpdatePOPartStatus b on a.id = b.po_mfg_unique_id




		COMMIT

		--select * from #tmp_proc_set_Reshape_UpdatePOPartStatus
		
		/* Getting RFQ ID */
		SELECT DISTINCT @rfq_id = rfq_id FROM #tmp_proc_set_Reshape_UpdatePOPartStatus

		/* Getting Buyer information */ 
		SELECT @to_contacts = contact_id
		FROM mp_rfq(NOLOCK) 
		WHERE  rfq_id in ( SELECT distinct rfq_id from #tmp_proc_set_Reshape_UpdatePOPartStatus)

		/* Getting Supplier information */  
		SELECT DISTINCT @from_contact =  a.contact_id
				FROM mp_rfq_quote_SupplierQuote(NOLOCK) a
				JOIN mp_rfq_quote_items(NOLOCK) b on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id AND b.is_awrded = 1
				JOIN #tmp_proc_set_Reshape_UpdatePOPartStatus h on h.quoted_quantity_id = b.rfq_quote_items_id
      
	  /* Getting quoted_quantity_id information into commma separated */  
	   SELECT @quoted_quantity_id = STRING_AGG(quoted_quantity_id, ', ') FROM #tmp_proc_set_Reshape_UpdatePOPartStatus

	  /* Output */
		SELECT TransactionStatus  = 'Success' , @rfq_id AS rfq_id, @from_contact  AS from_contact 
		, @to_contacts AS to_contacts , @quoted_quantity_id AS quoted_quantity_id

		INSERT INTO tmpOrderManagementflowlogs (RfqId,FlowName,POJSON)
		SELECT @rfq_id ,  'PO part status update from Reshape' , '' 

	END TRY
	BEGIN CATCH
		
		ROLLBACK

		SELECT TransactionStatus  = 'Fail - ' + ERROR_MESSAGE()

		INSERT INTO tmpOrderManagementflowlogs (RfqId,FlowName,POJSON)
		SELECT @rfq_id , 'Error - PO part status update from Reshape' , CONVERT(VARCHAR(1000), 'Failure' + ' - ' + ERROR_MESSAGE())
		
		
	END CATCH

	


END
