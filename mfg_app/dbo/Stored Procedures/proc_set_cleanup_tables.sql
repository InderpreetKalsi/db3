CREATE PROCEDURE [dbo].[proc_set_cleanup_tables]
AS
BEGIN

	/* M2-2819 SQL Job for cleaning unwanted data from tables - DB */

	
	DECLARE @TableName NVARCHAR(500);
	DECLARE @SQLIndex NVARCHAR(MAX);
	DECLARE @SQLStatisticstaIndex NVARCHAR(MAX);
	DECLARE @RowCount INT;
	DECLARE @Counter INT;

	DECLARE @IndexAnalysis TABLE
	(
		AnalysisID INT IDENTITY(1, 1) NOT NULL    PRIMARY KEY ,
		TableName NVARCHAR(500) ,
		SQLText NVARCHAR(MAX) ,
		UpdateStatisticsText NVARCHAR(MAX) ,
		AvgFragmentationInPercent FLOAT 		
	)

	-- cleanup data history table 
	DELETE FROM mp_data_history WHERE CONVERT(DATE,creation_date) = CONVERT(DATE,GETUTCDATE()-1) AND is_processed = 0
	
	-- cleanup email table 
	UPDATE mp_email_messages SET email_message_descr = '' 
	WHERE CONVERT(DATE,email_message_date) = CONVERT(DATE,GETUTCDATE()-1) AND message_sent = 1

	-- weekly maintanance 
	IF FORMAT(GETUTCDATE(),'dddd') = 'Sunday'
	BEGIN

		INSERT  INTO @IndexAnalysis
		SELECT  
			T.name 
			, 'ALTER INDEX [' + I.name + '] ON ['+ S.name + '].[' + T.name + '] ' + 'REORGANIZE' AS  frag_script 
			, 'UPDATE STATISTICS ['+ S.name + '].[' + T.name + '] '  AS  statistics_script 
			, DDIPS.avg_fragmentation_in_percent		AS  fragmentation_in_percent
		FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS DDIPS
		INNER JOIN sys.tables T on T.object_id = DDIPS.object_id
		INNER JOIN sys.schemas S on T.schema_id = S.schema_id
		INNER JOIN sys.indexes I ON I.object_id = DDIPS.object_id
		AND DDIPS.index_id = I.index_id
		WHERE DDIPS.database_id = DB_ID()
		and I.name is not null
		AND DDIPS.avg_fragmentation_in_percent > 0
		ORDER BY fragmentation_in_percent DESC

		SELECT  @RowCount = COUNT(AnalysisID)
		FROM    @IndexAnalysis

		SET @Counter = 1
		WHILE @Counter <= @RowCount 
		BEGIN

			SELECT  
				@SQLIndex = SQLText 
				, @SQLStatisticstaIndex = UpdateStatisticsText
			FROM    @IndexAnalysis
			WHERE   AnalysisID = @Counter

			EXECUTE sp_executesql @SQLIndex

			SET @Counter = @Counter + 1

		END

	END


	

END
