
CREATE PROCEDURE [dbo].[proc_set_RevisionData_Cleanup]
AS
-- =============================================
-- Author:		dp-sb
-- Create date:  18/12/2018
-- Description:	Stored procedure to cleanup and rearrange historical data for further processing.
-- Modification:
-- Example: proc_set_RevisionData_Cleanup
-- =================================================================
--Version No – Change Date – Modified By      – CR No – Note
-- =================================================================
BEGIN 

 
	DECLARE @RFQ_ID int, @rfq_revision_id int, @rfq_version_id int, @RFQSubmitted int, @DelNextRec int=0, @Prev_RFQ_ID int =0
	DECLARE c1 CURSOR FOR
		select
			rv.RFQ_ID
			, rv.rfq_version_id
			, rr.rfq_revision_id 
			, CASE WHEN rr.field ='RFQ Status' and oldvalue = 'In-Progress' and newvalue='Pending Approval'  then 1 ELSE 0 END as RFQSubmitted
		--DELETE rr
		from mp_rfq_versions rv 
		JOIN mp_rfq_revision rr on rv.rfq_version_id = rr.rfq_version_id and is_Cleaned_data = 0
		LEFT JOIN 
		(select distinct rfq_id from mp_rfq_revision where field = 'RFQ Status' and oldvalue = 'In-Progress' and newvalue='Pending Approval'  and   is_Cleaned_data =1) as pr on pr.rfq_id = rv.RFQ_ID
		Where pr.rfq_id is null
		order by rv.RFQ_ID, rv.major_number
	OPEN C1
	FETCH NEXT FROM C1 into @RFQ_ID, @rfq_version_id, @rfq_revision_id , @RFQSubmitted 
	WHILE @@FETCH_STATUS =0 
	BEGIN
		IF @Prev_RFQ_ID  <> @RFQ_ID
		BEGIN
			SET @DelNextRec =1
			print 'set for delete'
		END

		IF @RFQSubmitted = 0 and @DelNextRec =1 
			BEGIN
				print 'Removing records @rfq_revision_id = ' + convert(nvarchar(10), @rfq_revision_id)
				SET @Prev_RFQ_ID  = @RFQ_ID
			
				DELETE FROM mp_rfq_revision where rfq_revision_id = @rfq_revision_id 
				BEGIN try
					print 'deleting mp_rfq_versions where rfq_version_id = ' + convert(varchar(10), @rfq_version_id) + ' and major_number<> 1'
					DELETE FROM mp_rfq_versions where rfq_version_id = @rfq_version_id and major_number<> 1
				End try
				BEGIN Catch
					print error_message()
				ENd catch
			END
		ELSE
			BEGIN
				SET @Prev_RFQ_ID  = @RFQ_ID
				SET @DelNextRec =0
			END
		 
		PRINT 'Updating is_Cleaned_data status = 1'
		UPDATE mp_rfq_revision set is_Cleaned_data = 1 where rfq_revision_id = @rfq_revision_id 

		FETCH NEXT FROM C1 into @RFQ_ID, @rfq_version_id, @rfq_revision_id , @RFQSubmitted 
	END 
	CLOSE c1
	DEALLOCATE c1

	
	SELECT *, row_number() over (partition by rfq_id order by rfq_id, creation_date) as NewVersionNo 
	into #tmp_MP_rfq_version 
	FROM MP_rfq_versions

	UPDATE b set b.major_number = a.NewVersionNo
	 , b.version_number = convert(varchar(10), a.NewVersionNo) + '.0'
	 from #tmp_MP_rfq_version a join MP_rfq_versions b
	 on a.rfq_version_id = b.rfq_version_id
	 and a.NewVersionNo <> b.major_number
	
	drop table #tmp_MP_rfq_version


	---CLEANING mp_rfq_revision at 2nd level
	 
	BEGIN

		---Finding Bad/Duplicate data and seting sorting order
		IF OBJECT_ID('tempdb..#tmpLevel2Cleaning') IS NOT NULL DROP TABLE #tmpLevel2Cleaning; 	
		SELECT 
		 rank() over(partition by rfq_id ORDER BY  UniqNumber ) as NewVersion
		, CASE WHEN newvalue = NextUpcomingValue THEN 1 ELSE 0 END as BadData
		, row_number() over (partition by rfq_id, UniqNumber  order by rfq_id, UniqNumber) * 10 as TimeIncrementer
		, min(creation_date) over (partition by rfq_id, UniqNumber  order by rfq_id, UniqNumber) as minCreationDate
		, *
		 into #tmpLevel2Cleaning
		 FROM 
		(
			SELECT  
				 LEAD(newvalue) OVER (partition by rfq_id ORDER BY rfq_id, UniqNumber, intSortOrder, creation_date) as NextUpcomingValue 
				 , *
			FROM
			(
				SELECT 
					 convert(varchar(20), FORMAT(creation_date, 'yyyyMMddHHmm')) as UniqNumber
					--, isnull((select position from mp_mst_rfq_buyerStatus where description = oldvalue),999) as intSortOrder 
					, isnull((select CASE WHEN position =1 THEN position ELSE 999+position END as Position from mp_mst_rfq_buyerStatus where description = newvalue),999) as intSortOrder 
					, *
				FROM mp_rfq_revision
				WHERE need_Level2_Cleaning = 1
			) ft 
		) as checkNextVal 
		--where rfq_id = 1104004
		order by rfq_id, UniqNumber, intSortOrder, creation_date

		-- select * from #tmpLevel2Cleaning where rfq_id = 1104004

		---Removing Bad/Duplicate data and seating sorting order
		DELETE b
		FROM #tmpLevel2Cleaning a
		JOIN mp_rfq_revision b on a.rfq_revision_id = b.rfq_revision_id
		where BadData = 1

		--SELECT NewVersionId, toClean.* 
		---Adjusting version ids to reduce multiple versions
		UPDATE toClean set toclean.rfq_version_id  = validData.NewVersionId
			, toClean.creation_date = dateadd(millisecond, validData.TimeIncrementer, minCreationDate)
			--, toClean.creation_date = dateadd(millisecond, validdata.rfq_revision_id , minCreationDate)
			, toClean.need_Level2_Cleaning = 0
		--SELECT NewVersionId, toClean.creation_date, dateadd(millisecond, validData.TimeIncrementer, minCreationDate), toClean.*
		FROM 
		(SELECT min(rfq_version_id) over (partition by rfq_id, newVersion order by rfq_id, newVersion) as NewVersionId , * 
		FROM #tmpLevel2Cleaning where BadData = 0) validData
		Join mp_rfq_revision toClean on validdata.rfq_version_id = toclean.rfq_version_id  
		and validdata.rfq_revision_id = toclean.rfq_revision_id  
		--order by toClean.rfq_revision_id, toClean.creation_date

		 ---Start - Code to set the sequence for RFQ Part Quantity  to display in Revision history-----------
		IF OBJECT_ID('tempdb..#tmpSetRFQPartQtySortOrder') IS NOT NULL DROP TABLE #tmpSetRFQPartQtySortOrder; 
		select rfq_revision_id 
		--, row_number() over(partition by rfq_id, rfq_version_id order by field desc)
		--, min(creation_date) over(partition by rfq_id, rfq_version_id)
			--Adding millisecond to created date for setting the sort order
			, dateadd(millisecond 
						---Getting sequence as per field value to show Quantity 1 to 3 in sequence
						, 5*  row_number() over(partition by rfq_id, rfq_version_id order by field desc) 
						---Getting minimum data time and add 10 milisecond to set sort order
						, min(creation_date) over(partition by rfq_id, rfq_version_id)) as SortedDate
			into #tmpSetRFQPartQtySortOrder
	 
		FROM mp_rfq_revision
		where field like '% Part Quantity -%'
  
		Update mrr set mrr.creation_date = tmrr.SortedDate
		FROM mp_rfq_revision mrr JOIN #tmpSetRFQPartQtySortOrder tmrr
		on mrr.rfq_revision_id = tmrr.rfq_revision_id
		---END - Code to set the sequence for RFQ Part Quantity  to display in Revision history-----------


		--Removing unwanted versions which are not in used  
		DELETE rv 
		--SELECT *
		FROM mp_rfq_versions rv
		left  join mp_rfq_revision rr
		ON rv.rfq_version_id = rr.rfq_version_id
		WHERE rr.rfq_version_id  is null
		and major_number <>  1

		IF OBJECT_ID('tempdb..#tmp_MP_rfq_versions') IS NOT NULL DROP TABLE #tmp_MP_rfq_versions; 	
		SELECT *, row_number() over (partition by rfq_id order by rfq_id, creation_date) as NewVersionNo 
 		into #tmp_MP_rfq_versions 
		FROM MP_rfq_versions

		UPDATE b set b.major_number = a.NewVersionNo
		 , b.version_number = convert(varchar(10), a.NewVersionNo) + '.0'
		 --SELECT a.*
		 from #tmp_MP_rfq_versions a join MP_rfq_versions b
		 on a.rfq_version_id = b.rfq_version_id
		 and a.NewVersionNo <> b.major_number
	END 
END
