CREATE PROCEDURE [dbo].[proc_set_RevisionData_v1](@TableName varchar(50))
AS
-- =============================================
-- Create date: 05 Oct, 2018
-- Description:	Set the data revision
-- Modification:
-- Example: [proc_set_RevisionData] 'mp_parts'
--			[proc_set_RevisionData] 'mp_rfq'
--			[proc_set_RevisionData] 'mp_rfq_special_certificates'
-- =================================================================
--Version No – Change Date – Modified By      – CR No – Note
-- =================================================================
BEGIN
	--DELETE FROM mp_data_history where oldvalue is null
	DECLARE @jsonOldVal NVARCHAR(MAX) 
			, @jsonNewVal NVARCHAR(MAX) 
			, @jsonIDVal NVARCHAR(400) 
			, @DataHistoryId bigint
			, @CreationDate datetime
			, @UserID int
			, @rfq_id int
			, @part_id int

			, @RFQVersion int =0
			, @newRFQVersionId INT
			, @PartVersion int =0
			, @newPartVersionId INT



		--	, @TableName varchar(50) ='mp_rfq_parts'

	DECLARE @OldValueTable as Table(OldKey nvarchar(100), OldValue nvarchar(max))
	DECLARE @NewValueTable as Table(NewKey nvarchar(100), NewValue nvarchar(max))
	DECLARE @IDTable as Table(IDKey nvarchar(100),IDValue nvarchar(400))

	--Get the un processed data from history table
	DECLARE C1 CURSOR FOR
		SELECT  
			data_history_id
		  , oldvalue
		  , newvalue
		  , field 
		  , creation_date
		  , userid
		FROM 
			mp_data_history
		WHERE  tablename =  @TableName 
		AND is_processed = 0
		and oldvalue is not null
	
	OPEN C1
	--Loop each record to update in revision table
	FETCH NEXT FROM C1 into @DataHistoryId, @jsonOldVal, @jsonNewVal , @jsonIDVal , @CreationDate, @UserID
	WHILE  @@FETCH_STATUS =0 
	BEGIN
		BEGIN TRY
			DELETE FROM @OldValueTable
			DELETE FROM @NewValueTable
			DELETE FROM @IDTable
		
			INSERT INTO @OldValueTable(OldKey,OldValue)
			SELECT [key],[value] FROM OPENJSON(@jsonOldVal)

			INSERT INTO @NewValueTable(NewKey,NewValue)
			SELECT [key],[value]  FROM OPENJSON(@jsonNewVal)

			INSERT INTO @IDTable(IDKey, IDValue)
			SELECT [key],[value]  FROM OPENJSON(@jsonIDVal)

			
			---Get the Version from version table
			IF lower(@TableName) = 'mp_rfq' -- or lower(@TableName) = 'mp_rfq_parts' OR lower(@TableName) = 'mp_rfq_part_quantity')
			BEGIN
				---Create version history for RFQ changes
				select @rfq_id = IDValue from @IDTable  --Get the RFQ_ID
				select @RFQVersion = count(1)+1 from mp_rfq_versions where RFQ_ID = @rfq_id 

				INSERT INTO mp_rfq_versions(contact_id
											, major_number
											, minor_number
											, version_number
											, creation_date
											, RFQ_ID)
				VALUES(@UserID, @RFQVersion,0,convert(varchar(5), @RFQVersion) + '.0', @CreationDate,@rfq_id)
				set @newRFQVersionId = @@IDENTITY 
				



				IF (@RFQVersion > 1)
					BEGIN
						print '---Inserting revision data for RFQ if version has changed from 1 as 1st version is creating the RFQ'
						---Inserting revision data for RFQ
						INSERT INTO mp_rfq_revision(rfq_id
													, field
													, oldvalue
													, newvalue
													, creation_date
													, rfq_version_id)
						SELECT @rfq_id
								, OldKey
								, isnull(OldValue,'')
								, isnull(NewValue,'')
								, @CreationDate
								, @newRFQVersionId 
							FROM 
						 (
							 SELECT 
	
								 *
								, CASE WHEN isnull(a.OldValue,'') <> isnull(b.NewValue,'') THEN 
										1 
									Else 
										0 
									END AS is_Modified 
							 FROM (@OldValueTable a 
							   JOIN @NewValueTable b
							 on a.OldKey = b.NewKey ) cross join @IDTable 
						) as AuditData where is_Modified = 1
					END

				Update mp_data_history set is_processed = 1, processed_date = getdate() where data_history_id = @DataHistoryId
			END

			IF lower(@TableName) = 'mp_rfq_special_certificates'
			BEGIN
				print 'mp_rfq_special_certificates'
				---Create version history for RFQ changes
				SELECT @rfq_id = NewValue  FROM @NewValueTable where NewKey = 'RfqId' 

				---Check/Set RFQ Versioning
				SELECT @RFQVersion = count(1)+1 FROM mp_rfq_versions WHERE RFQ_ID = @rfq_id 
				
			
			
				INSERT INTO mp_rfq_versions(contact_id
											, major_number
											, minor_number
											, version_number
											, creation_date
											, RFQ_ID)
				VALUES(@UserID, @RFQVersion,0,convert(varchar(5), @RFQVersion) + '.0', @CreationDate,@rfq_id)
				set @newRFQVersionId = @@IDENTITY 
				
				INSERT INTO mp_rfq_revision(rfq_id
											, field
											, oldvalue
											, newvalue
											, creation_date
											, rfq_version_id)
				SELECT @rfq_id, NewKey, isnull(OldValue,''), isnull(NewValue,''), @CreationDate, @newRFQVersionId FROM 
					(
						--Below sql looks like has bug and need to check on Join condition to get the all data, recommended join would be full join ...Commented By Suryakant 
						SELECT 
	
							*
						, CASE WHEN isnull(a.OldValue,'') <> isnull(b.NewValue,'') THEN 
								1 
							Else 
								0 
							END AS is_Modified 
						FROM @OldValueTable a 
						right JOIN @NewValueTable b
						on a.OldKey = b.NewKey 
						where b.NewKey <>'rfqid'
						--) cross join @IDTable 
				) as AuditData where is_Modified = 1
					

				Update mp_data_history set is_processed = 1, processed_date = getdate() where data_history_id = @DataHistoryId
			END

			
			IF lower(@TableName) = 'mp_rfq_parts' --OR lower(@TableName) = 'mp_rfq_part_quantity')
			BEGIN
				---Create version history for RFQ changes
				SELECT @rfq_id = NewValue  FROM @NewValueTable where NewKey = 'RfqId' 

				---Check/Set RFQ Versioning
				SELECT @RFQVersion = count(1)+1 FROM mp_rfq_versions WHERE RFQ_ID = @rfq_id 
				
			
			
				INSERT INTO mp_rfq_versions(contact_id
											, major_number
											, minor_number
											, version_number
											, creation_date
											, RFQ_ID)
				VALUES(@UserID, @RFQVersion,0,convert(varchar(5), @RFQVersion) + '.0', @CreationDate,@rfq_id)
				set @newRFQVersionId = @@IDENTITY 
				
				INSERT INTO mp_rfq_revision(rfq_id
											, field
											, oldvalue
											, newvalue
											, creation_date
											, rfq_version_id)
				SELECT @rfq_id, NewKey, isnull(OldValue,''), isnull(NewValue,''), @CreationDate, @newRFQVersionId FROM 
					(
						SELECT 
	
							*
						, CASE WHEN isnull(a.OldValue,'') <> isnull(b.NewValue,'') THEN 
								1 
							Else 
								0 
							END AS is_Modified 
						FROM @OldValueTable a 
						right JOIN @NewValueTable b
						on a.OldKey = b.NewKey 
						where b.NewKey <>'rfqid'
						--) cross join @IDTable 
				) as AuditData where is_Modified = 1
					

				Update mp_data_history set is_processed = 1, processed_date = getdate() where data_history_id = @DataHistoryId
			END

			/*
			IF lower(@TableName) = 'mp_rfq_part_quantity'
			BEGIN
				---Create version history for RFQ changes
				SELECT @rfq_id = NewValue  FROM @NewValueTable where NewKey = 'RfqId' 

				---Check/Set RFQ Versioning
				SELECT @RFQVersion = count(1)+1 FROM mp_rfq_versions WHERE RFQ_ID = @rfq_id 
				
			

				INSERT INTO mp_rfq_versions(contact_id
											, major_number
											, minor_number
											, version_number
											, creation_date
											, RFQ_ID)
				VALUES(@UserID, @RFQVersion,0,convert(varchar(5), @RFQVersion) + '.0', @CreationDate,@rfq_id)
				set @newRFQVersionId = @@IDENTITY 
				
				print '---Inserting revision data for RFQ'
				INSERT INTO mp_rfq_revision(rfq_id
											, field
											, oldvalue
											, newvalue
											, creation_date
											, rfq_version_id)
				SELECT @rfq_id, NewKey, isnull(OldValue,''), isnull(NewValue,''), @CreationDate, @@IDENTITY FROM 
				 (
					 SELECT 
	
						 *
						, CASE WHEN isnull(a.OldValue,'') <> isnull(b.NewValue,'') THEN 
								1 
							Else 
								0 
							END AS is_Modified 
					 FROM @OldValueTable a 
					  right JOIN @NewValueTable b
					 on a.OldKey = b.NewKey 
					 where b.NewKey <>'rfqid'
					 --) cross join @IDTable 
				) as AuditData where is_Modified = 1

				Update mp_data_history set is_processed = 1, processed_date = getdate() where data_history_id = @DataHistoryId

			END
			*/

			IF lower(@TableName) = 'mp_parts'
			BEGIN

			--select * from @OldValueTable
			--select * from @NewValueTable
			--select * from @IDTable

				--select * from mp_data_history where tablename ='mp_parts'
				---Create version history for RFQ changes

				SELECT @part_id = IDValue  FROM @IDTable  

				---Check/Set RFQ Versioning
				SELECT @PartVersion = count(1)+1 FROM mp_parts_versions WHERE part_ID = @part_id 
				
				INSERT INTO mp_parts_versions(contact_id
											, major_number
											, minor_number
											, version_number
											, creation_date
											, part_ID)
				VALUES(@UserID, @PartVersion,0,convert(varchar(5), @PartVersion) + '.0', @CreationDate,@part_id)
				set @newPartVersionId = @@IDENTITY 
				
				print '---Inserting revision data for RFQ'
				INSERT INTO mp_parts_revision(part_id
											, field
											, oldvalue
											, newvalue
											, creation_date
											, parts_version_id)
				SELECT @part_id, NewKey, isnull(OldValue,''), isnull(NewValue,''), @CreationDate, @newPartVersionId FROM 
				 (
					 SELECT 
	
						 *
						, CASE WHEN isnull(a.OldValue,'') <> isnull(b.NewValue,'') THEN 
								1 
							Else 
								0 
							END AS is_Modified 
					 FROM @OldValueTable a 
					  right JOIN @NewValueTable b
					 on a.OldKey = b.NewKey 
				) as AuditData where is_Modified = 1

				Update mp_data_history set is_processed = 1, processed_date = getdate() where data_history_id = @DataHistoryId

			END



			---Code to update Data in readable format
		BEGIN
			SELECT 
			rfq_revision_id
			, rfq_id
			, field
			
			--Setting the correct field name for revision history screen
			, CASE WHEN (field ='ImportancePrice') THEN 
				'Price'
			WHEN (field ='ImportanceQuality') THEN 
				'Quality'
			WHEN (field ='ImportanceSpeed' )  THEN 
				'Speed'
			WHEN (field ='RfqStatusId' )  THEN 
				'RFQ Status'
			WHEN (field ='ShipTo') THEN
				'Shipping Address'
			WHEN (field ='PrefNdaType') THEN
				'Preferred NDA Type'
			WHEN (field ='WhoPaysForShipping') THEN
				'Who pays for shipping'
			ELSE
				field
			END  as field_Updated

			--Setting the understandable Old value for revision history screen
			, CASE WHEN (field ='ImportancePrice' OR field ='ImportanceQuality'  OR field ='ImportanceSpeed' ) and ltrim(rtrim(oldvalue)) ='1' THEN 
				'High Importance'
			WHEN (field ='ImportancePrice' OR field ='ImportanceQuality'  OR field ='ImportanceSpeed' ) and ltrim(rtrim(oldvalue)) ='2' THEN 
				'Middle importance'
			WHEN (field ='ImportancePrice' OR field ='ImportanceQuality'  OR field ='ImportanceSpeed' ) and ltrim(rtrim(oldvalue)) ='3' THEN 
				'low importance'
			WHEN (field ='RfqStatusId' )  THEN 
				(SELECT [description] from mp_mst_rfq_buyerStatus where rfq_buyerstatus_id = CONVERT(int, isnull(oldvalue,0)))
			WHEN (field ='ShipTo') THEN
				(
					select isnull(css.site_label + ', ',' ') + isnull(ma.address1 +', ',' ') + isnull(ma.address2 +', ',' ') + isnull(ma.address3 +', ',' ') + isnull(ma.address4 +', ',' ') + isnull(ma.address5 + ', ',' ')+isnull(country_name,' ')  from mp_company_shipping_site css 
					join mp_addresses ma on css.address_id = ma.address_id
					Join mp_mst_country  mms on mms.country_id = ma.country_id
					where site_id= convert(int, ltrim(rtrim(oldvalue)))
					and site_id <>0
				)
			WHEN (field ='PrefNdaType') THEN
				(
					SELECT CASE WHEN ltrim(rtrim(oldvalue)) ='' THEN
						''
					WHEN ltrim(rtrim(oldvalue)) = '0' THEN
						'No NDA'
					WHEN ltrim(rtrim(oldvalue))= '1' THEN
						'1st-level NDA'
					WHEN ltrim(rtrim(oldvalue)) = '2' THEN
						'2nd-level NDA'
					END
				)
				WHEN (field ='WhoPaysForShipping') THEN
				(
					SELECT CASE WHEN ltrim(rtrim(oldvalue)) ='' THEN
							''
							WHEN ltrim(rtrim(oldvalue)) = '1' THEN
							'Buyer Pay'
							ELSE 
							'Supplier Pay'
					END
				)
			ELSE
				oldvalue
			END  as OldValue_Updated
			, oldvalue

			--Setting the understandable new value for revision history screen
			, CASE WHEN (field ='ImportancePrice' OR field ='ImportanceQuality'  OR field ='ImportanceSpeed' ) and ltrim(rtrim(newvalue)) ='1' THEN 
				'High Importance'
			WHEN (field ='ImportancePrice' OR field ='ImportanceQuality'  OR field ='ImportanceSpeed' ) and ltrim(rtrim(newvalue)) ='2' THEN 
				'Middle importance'
			WHEN (field ='ImportancePrice' OR field ='ImportanceQuality'  OR field ='ImportanceSpeed' ) and ltrim(rtrim(newvalue)) ='3' THEN 
				'low importance'
			WHEN (field ='RfqStatusId' )  THEN 
				(SELECT [description] from mp_mst_rfq_buyerStatus where rfq_buyerstatus_id = CONVERT(int, isnull(newvalue,0)))
			WHEN (field ='ShipTo') THEN
				(
					select isnull(css.site_label + ', ',' ') 
					+ isnull(ma.address1 +', ',' ') 
					+ isnull(ma.address2 +', ',' ') 
					+ isnull(ma.address3 +', ',' ') + isnull(ma.address4 +', ',' ') + isnull(ma.address5 + ', ',' ')+isnull(country_name,' ')  from mp_company_shipping_site css 
					join mp_addresses ma on css.address_id = ma.address_id
					Join mp_mst_country  mms on mms.country_id = ma.country_id
					where site_id= convert(int, ltrim(rtrim(newvalue)))
					and site_id <>0
				)
			WHEN (field ='PrefNdaType') THEN
				(
					select 
					CASE WHEN ltrim(rtrim(newvalue)) ='' THEN
							''
					WHEN ltrim(rtrim(newvalue)) = '0' THEN
						'No NDA'
					WHEN ltrim(rtrim(newvalue)) = '1' THEN
						'1st-level NDA'
					WHEN ltrim(rtrim(newvalue)) = '2' THEN
						'2nd-level NDA'
					END
				)
			WHEN (field ='WhoPaysForShipping') THEN
				(
					SELECT 
						CASE WHEN ltrim(rtrim(newvalue)) ='' THEN
							''
						WHEN ltrim(rtrim(newvalue)) = '1' THEN
							'Buyer Pay'
						ELSE 
							'Supplier Pay'
						END
				)
			ELSE
				newvalue
			END  as newvalue_Updated
			, newvalue
			, creation_date
			, rfq_version_id
			into #tmp_RevisionData
			FROM mp_rfq_revision
			WHERE field in ('ImportancePrice', 'ImportanceQuality', 'ImportanceSpeed', 'RfqStatusId', 'ShipTo', 'PrefNdaType','WhoPaysForShipping')
 
				--select 
			UPDATE mrr SET
				mrr.field = trd.field_Updated
				, mrr.oldvalue = ISNULL(trd.OldValue_Updated,'')
				, mrr.newvalue = ISNULL(trd.newvalue_Updated,'')
			FROM #tmp_RevisionData trd 
			JOIN mp_rfq_revision mrr ON trd.field = mrr.field 
			AND mrr.rfq_revision_id = trd.rfq_revision_id

			DROP TABLE #tmp_RevisionData
		END




		END TRY
		BEGIN CATCH
			print error_message()
		END CATCH

		FETCH NEXT FROM C1 into @DataHistoryId, @jsonOldVal, @jsonNewVal , @jsonIDVal , @CreationDate, @UserID
	END
	Close C1
	DEALLOCATE C1

	---Cleanup data for Revision history
	--EXEC proc_Cleanup_Revision_data
	--print '--Revision data cleaning ...'
	EXEC dbo.proc_set_RevisionData_Cleanup

END
