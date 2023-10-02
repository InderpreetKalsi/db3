
/*
exec proc_get_Reshape_POPartStatusList 
@ReshapeUniqueId = '98932956-50C9-464B-8635-8273CFDE7CD0'
,@RfqPartId = 92421
,@SupplierContactId = 1371103
,@json=N'{
     "data":  [
            {
                 "id":1,
                 "created_at":  "2023-02-28T08:57:37.000000Z",
                 "updated_at":  "2023-02-28T08:57:37.000000Z",
                 "provider_id":  5420,
                 "name":  "Request Received",
                 "ordinal":  1,
                 "order_id":  923        
    },
	{
                 "id":2,
                 "created_at":  "2023-02-28T08:57:37.000000Z",
                 "updated_at":  "2023-02-28T08:57:37.000000Z",
                 "provider_id":  5420,
                 "name":  "In Production",
                 "ordinal":  1,
                 "order_id":  923        
    },
	{
                 "id":3,
                 "created_at":  "2023-02-28T08:57:37.000000Z",
                 "updated_at":  "2023-02-28T08:57:37.000000Z",
                 "provider_id":  5420,
                 "name":  "Production Completed",
                 "ordinal":  1,
                 "order_id":  923        
    },
	{
                 "id":4,
                 "created_at":  "2023-02-28T08:57:37.000000Z",
                 "updated_at":  "2023-02-28T08:57:37.000000Z",
                 "provider_id":  5420,
                 "name":  "Dispatched",
                 "ordinal":  1,
                 "order_id":  923        
    },
	{
                 "id":5,
                 "created_at":  "2023-02-28T08:57:37.000000Z",
                 "updated_at":  "2023-02-28T08:57:37.000000Z",
                 "provider_id":  5420,
                 "name":  "Delivered",
                 "ordinal":  1,
                 "order_id":  923        
    }
  ],
     "message":  "Get records successfully",
     "status":  "success"
}
'

*/

CREATE PROCEDURE [dbo].[proc_get_Reshape_POPartStatusList]
(
	  @ReshapeUniqueId UNIQUEIDENTIFIER 
	, @RfqPartId INT  
	, @SupplierContactId INT
	, @json NVARCHAR(MAX)
)
AS
 
BEGIN

	SET NOCOUNT ON
	DROP TABLE IF EXISTS #tmp_proc_POPartStatusList

	--- remove/replace the no-break space 
	DECLARE @POPartJSON VARCHAR(MAX) 
	DECLARE @processStatus AS VARCHAR(MAX) = 'SUCCESS'
	DECLARE @RfqPOStatusList    VARCHAR(MAX)  

	BEGIN TRY 
		
		SET @POPartJSON =  REPLACE(@json,CHAR(160),'')
			 
		SELECT * INTO #tmp_proc_POPartStatusList FROM
		(
			SELECT 
				a.id, a.name
			FROM OPENJSON(@POPartJSON) 
			WITH 
			(
				data NVARCHAR(MAX) '$.data' AS JSON
			) AS i
			CROSS APPLY OPENJSON(i.data) 
			WITH 
			(
				[id] INT '$.id',
				[name] VARCHAR(100) '$.name' 
			) a
		) a

		IF ((SELECT COUNT(1) FROM #tmp_proc_POPartStatusList) >  0 )
		BEGIN
		
			SET @RfqPOStatusList =   
			( 
				SELECT 
					a.id	AS [id]
					,a.name AS [status]
					,b.PartStatusDate AS [status_date]
					,CASE WHEN b.rn = 1 THEN 'current' WHEN b.rn > 1 THEN 'completed' ELSE 'pending' END AS [type]
				FROM #tmp_proc_POPartStatusList a 
				LEFT JOIN 
				(
					SELECT 
							a.NewStatus  AS PartStatus
							,CONVERT(DATE,a.CreatedOn) AS PartStatusDate
							,ROW_NUMBER() OVER (ORDER BY a.Id DESC) rn 
					FROM mpOrderManagementPartStatusChangeLogs(NOLOCK) a
					LEFT JOIN mpOrderManagement(NOLOCK) b on a.ReshapeUniqueId  = b.ReshapeUniqueId 
					WHERE a.ReshapeUniqueId = @ReshapeUniqueId 
					AND a.SupplierContactId = @SupplierContactId
					AND a.RfqPartId = @RfqPartId
					AND a.IsDeleted = 0
				) b ON a.name = b.PartStatus
				ORDER BY a.id
						
				FOR JSON PATH  , ROOT ('details') , INCLUDE_NULL_VALUES   
			)

		END
		ELSE
		BEGIN
			SET @RfqPOStatusList = '{"details":[{"id":1,"status":"Pending","status_date":"","type":"current"}]}'
		END
				 
		SELECT  TransactionStatus  = 'Success', @RfqPOStatusList AS POStatusList
		 
	END TRY
	BEGIN CATCH
			SELECT TransactionStatus  = 'Failure ' + ERROR_MESSAGE()
	END CATCH 
 
END
