
CREATE PROCEDURE dbo.REvieionData_backup_v1_proc_set_RevisionData_Cleanup
AS
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
		JOIN mp_rfq_revision rr on rv.rfq_version_id = rr.rfq_version_id
		and is_Cleaned_data = 0
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
				--Remove 
					--DELETE @rfq_revision_id
			
				DELETE FROM mp_rfq_revision where rfq_revision_id = @rfq_revision_id 
				BEGIN try
					DELETE FROM mp_rfq_versions where rfq_version_id = @rfq_version_id and major_number<> 1
				End try
				BEGIN Catch
					print error_message()
				ENd catch

			 
				SET @Prev_RFQ_ID  = @RFQ_ID
			
			END
		ELSE
			BEGIN
				SET @Prev_RFQ_ID  = @RFQ_ID
				SET @DelNextRec =0
			END

		UPDATE mp_rfq_revision set is_Cleaned_data = 1 where rfq_revision_id = @rfq_revision_id 

		FETCH NEXT FROM C1 into @RFQ_ID, @rfq_version_id, @rfq_revision_id , @RFQSubmitted 
	END 
	CLOSE c1
	DEALLOCATE c1

	
	SELECT *, row_number() over (partition by rfq_id order by rfq_id, creation_date) as NewVersionNo 
	into #tmp_MP_rfq_versions 
	FROM MP_rfq_versions

	UPDATE b set b.major_number = a.NewVersionNo
	 , b.version_number = convert(varchar(10), a.NewVersionNo) + '.0'
	 from #tmp_MP_rfq_versions a join MP_rfq_versions b
	 on a.rfq_version_id = b.rfq_version_id
	 and a.NewVersionNo <> b.major_number
	
	drop table #tmp_MP_rfq_versions

END
