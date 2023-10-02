CREATE PROCEDURE [dbo].[proc_set_RevisionData]
AS
-- =============================================
-- Create date: 05 Oct, 2018
-- Description:	Set the data revision
-- Modification:
-- Example: [proc_set_RevisionData]   

			--SELECT * FROM mp_rfq_revision (NOLOCK) WHERE rfq_id IN (1162244,1162245)
			--SELECT * FROM mp_rfq_versions (NOLOCK) WHERE rfq_id IN (1162244,1162245)
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
			, @TableName varchar(50)
			, @sqlStr nvarchar(500)=''

	DECLARE @OldValueTable as Table(OldKey nvarchar(100), OldValue nvarchar(max))
	DECLARE @NewValueTable as Table(NewKey nvarchar(100), NewValue nvarchar(max))
	DECLARE @IDTable as Table(IDKey nvarchar(100),IDValue nvarchar(400))

	DECLARE @jsonOldTable table([OldPartQty] numeric(18,2),  [OldQuantityLevel] int, [OldRfqPartId] int)
	DECLARE @jsonNewTable table([NewPartQty] numeric(18,2),  [NewQuantityLevel] int, [NewRfqPartId] int)


	--Removing unwanted records
	DELETE FROM mp_data_history where  tablename in ('mp_data_history','mp_messages')
	
	
	---Getting History data to working table for processing 
	BEGIN
		IF OBJECT_ID('dbo.mp_data_history_working') IS NOT NULL DROP TABLE mp_data_history_working; 
	
		---Adding unprocessed data to working table
		SELECT * INTO mp_data_history_working 
		FROM mp_data_history 
		WHERE  tablename in ('mp_rfq', 'mp_rfq_special_certificates','mp_rfq_preferences','mp_rfq_parts', 'mp_rfq_part_quantity')
		AND is_processed = 0
		ORDER BY data_history_id

				
		---Updating unprocessed data flag in original table to Processed.
		UPDATE mp_data_history SET is_processed=1 , processed_date = GETUTCDATE() 
		WHERE  tablename in ('mp_rfq', 'mp_rfq_special_certificates','mp_rfq_preferences','mp_rfq_parts','mp_rfq_part_quantity')
		AND is_processed = 0 
	END

	print '--Cleanup RFQ Certificate data '
	EXEC proc_set_RevisionData_CleanupRFQCertificateData
	
	print '--Cleanup RFQ Part''s Quantity data '
	EXEC proc_set_RevisionData_CleanupRFQPartsNQuantity
	
	--Get the un processed data from history table
	DECLARE C1 CURSOR FOR
		SELECT  
			data_history_id
		  , oldvalue
		  , newvalue
		  , field 
		  , creation_date
		  , userid
		  , tablename
		FROM 
			mp_data_history_working
		--WHERE  tablename =  @TableName 
		WHERE  tablename in ('mp_rfq', 'mp_rfq_special_certificates','mp_rfq_preferences','mp_rfq_parts','mp_rfq_part_quantity')
		AND is_processed = 0
		--and oldvalue is not null
		ORDER BY data_history_id
	
	OPEN C1
	--Loop each record to update in revision table
	FETCH NEXT FROM C1 into @DataHistoryId, @jsonOldVal, @jsonNewVal , @jsonIDVal , @CreationDate, @UserID, @TableName 
	WHILE  @@FETCH_STATUS =0 
	BEGIN
		print '@DataHistoryId = ' + convert(varchar(10), @DataHistoryId)
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
						SELECT distinct @rfq_id
								, OldKey
								, isnull(OldValue,'')
								, isnull(NewValue,'')
								, @CreationDate
								, @newRFQVersionId 
							FROM 
						 (
							 SELECT distinct
	
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
						--and OldKey <>'CertificateId'
						--and OldKey <>'CreationDate'
					END

				Update mp_data_history_working set is_processed = 1, processed_date = getdate() where data_history_id = @DataHistoryId
			END

			IF (lower(@TableName) = 'mp_rfq_special_certificates')
			BEGIN
				print 'Started processing - mp_rfq_special_certificates'
			 	---Create version history for RFQ changes
				SET @rfq_id = 0
				SELECT @rfq_id = max(RFQID) FROM 
				(
					SELECT TOP 1 [value] as RFQID FROM OPENJSON(@jsonNewVal) a where [key]='RfqId'
					union
					SELECT TOP 1 [value] as RFQID FROM OPENJSON(@jsonoldVal) a where [key]='RfqId'
				) a
			
				---Check/Set RFQ Versioning
				SELECT @RFQVersion = count(1)+1 FROM mp_rfq_versions WHERE RFQ_ID = @rfq_id 
				IF isnull(@UserID,0) =0
				BEGIN
					SELECT @UserID = contact_id from mp_rfq where rfq_id = @rfq_id
				END
				print 'Started creating - version'
				INSERT INTO mp_rfq_versions(contact_id
											, major_number
											, minor_number
											, version_number
											, creation_date
											, RFQ_ID)
				VALUES(@UserID, @RFQVersion,0,convert(varchar(5), @RFQVersion) + '.0', @CreationDate,@rfq_id)
				SET @newRFQVersionId = @@IDENTITY 

				print 'Started reading - old log'
				IF OBJECT_ID('tempdb..#tmpRFQOldCertificate') IS NOT NULL DROP TABLE #tmpRFQOldCertificate; 
				SELECT DISTINCT 
						[key] as oldKey
						,[value] oldValue 
					INTO #tmpRFQOldCertificate
				FROM OPENJSON(@jsonOldVal) 
				--WHERE [key]= 'CertificateId'
				WHERE [key] in ('CertificateId','RfqId')

				print 'Started reading - New log'
				IF OBJECT_ID('tempdb..#tmpRFQNewCertificate') IS NOT NULL DROP TABLE #tmpRFQNewCertificate; 		
				SELECT DISTINCT 
						[key] as NewKey 
						,[value] NewValue 
					INTO #tmpRFQNewCertificate
				FROM OPENJSON(@jsonNewVal)
				--WHERE [key]= 'CertificateId'
				WHERE [key] in ('CertificateId','RfqId')
			
			 	print 'Started inserting - revision  for RFQ' + convert(varchar(10), @rfq_id)
				
				---Inserting Certificate values
				INSERT INTO mp_rfq_revision(rfq_id
											, field
											, oldvalue
											, newvalue
											, creation_date
											, rfq_version_id)
				SELECT distinct @rfq_id, 'RFQ Certificate', isnull(OldValue,''), isnull(NewValue,''), @CreationDate, @newRFQVersionId FROM 
					(
						
						SELECT  STUFF(( SELECT ', ' + certificate_code
									FROM (select b.certificate_code from #tmpRFQOldCertificate a join mp_certificates b on a.oldValue = b.certificate_id) a 
									FOR XML PATH(''),TYPE)
									.value('.','NVARCHAR(MAX)'),1,2,'') AS oldValue
								,  STUFF(( SELECT ', ' + certificate_code
									FROM (select b.certificate_code from #tmpRFQNewCertificate  a join mp_certificates b on a.NewValue = b.certificate_id)b 
									FOR XML PATH(''),TYPE)
									.value('.','NVARCHAR(MAX)'),1,2,'') AS newValue
					) a where isnull(oldValue,'') <> isnull(newValue,'')
				
				Update mp_data_history_working set is_processed = 1, processed_date = getdate() where data_history_id = @DataHistoryId
				  print 'END processing - mp_rfq_special_certificates'
			END

			IF (lower(@TableName) = 'mp_rfq_preferences')
			BEGIN
				print 'Started processing - mp_rfq_preferences'
			 	---Create version history for RFQ changes
				SET @rfq_id = 0
				SELECT @rfq_id = max(RFQID) FROM 
				(
					SELECT TOP 1 [value] as RFQID FROM OPENJSON(@jsonNewVal) a where [key]='RfqId'
					union
					SELECT TOP 1 [value] as RFQID FROM OPENJSON(@jsonoldVal) a where [key]='RfqId'
				) a
			
				---Check/Set RFQ Versioning
				SELECT @RFQVersion = count(1)+1 FROM mp_rfq_versions WHERE RFQ_ID = @rfq_id 
				IF isnull(@UserID,0) =0
				BEGIN
					SELECT @UserID = contact_id from mp_rfq where rfq_id = @rfq_id
				END
				print 'Started creating - version'
				INSERT INTO mp_rfq_versions(contact_id
											, major_number
											, minor_number
											, version_number
											, creation_date
											, RFQ_ID)
				VALUES(@UserID, @RFQVersion,0,convert(varchar(5), @RFQVersion) + '.0', @CreationDate,@rfq_id)
				SET @newRFQVersionId = @@IDENTITY 

				print 'Started reading - old log'
				IF OBJECT_ID('tempdb..#tmpRFQOldPreferences') IS NOT NULL DROP TABLE #tmpRFQOldPreferences; 
				SELECT DISTINCT 
						[key] as oldKey
						,[value] oldValue 
					INTO #tmpRFQOldPreferences
				FROM OPENJSON(@jsonOldVal) 
				--WHERE [key]= 'CertificateId'
				WHERE [key] in ('RfqId','RfqPrefManufacturingLocationId')

				print 'Started reading - New log'
				IF OBJECT_ID('tempdb..#tmpRFQNewPreferences') IS NOT NULL DROP TABLE #tmpRFQNewPreferences; 		
				SELECT DISTINCT 
						[key] as NewKey 
						,[value] NewValue 
					INTO #tmpRFQNewPreferences
				FROM OPENJSON(@jsonNewVal)
				--WHERE [key]= 'CertificateId'
				WHERE [key] in ('RfqId','RfqPrefManufacturingLocationId')
			
			 	PRINT 'Started inserting - revision  for RFQ' + convert(varchar(10), @rfq_id)
				---Inserting Rfq Manufacturing Location preferences
				INSERT INTO mp_rfq_revision(rfq_id
											, field
											, oldvalue
											, newvalue
											, creation_date
											, rfq_version_id)
				SELECT DISTINCT @rfq_id, 'Preferred Manufacturing Location', isnull(OldValue,''), isnull(NewValue,''), @CreationDate, @newRFQVersionId FROM 
					(
						
						SELECT  STUFF(( SELECT ', ' + territory_classification_DispName
									FROM (select b.territory_classification_DispName from #tmpRFQOldPreferences a join mp_mst_territory_classification b on a.oldValue = b.territory_classification_id and oldKey = 'RfqPrefManufacturingLocationId') a 
									FOR XML PATH(''),TYPE)
									.value('.','NVARCHAR(MAX)'),1,2,'') AS oldValue
								,  STUFF(( SELECT ', ' + territory_classification_DispName
									FROM (select b.territory_classification_DispName from #tmpRFQNewPreferences  a join mp_mst_territory_classification b on a.NewValue = b.territory_classification_id and NewKey = 'RfqPrefManufacturingLocationId')b 
									FOR XML PATH(''),TYPE)
									.value('.','NVARCHAR(MAX)'),1,2,'') AS newValue
					) a where isnull(oldValue,'') <> isnull(newValue,'')
					
				UPDATE mp_data_history_working set is_processed = 1, processed_date = getdate() where data_history_id = @DataHistoryId
				PRINT 'END processing - mp_rfq_preferences'
			END

			IF lower(@TableName) = 'mp_rfq_parts' --OR lower(@TableName) = 'mp_rfq_part_quantity')
			BEGIN
				---Find the RFQ id for processing
				BEGIN
					SET @rfq_id = 0
					SELECT @rfq_id = max(RFQID) FROM 
					(
						SELECT TOP 1 [value] as RFQID FROM OPENJSON(@jsonNewVal) a where [key]='RfqId'
						union
						SELECT TOP 1 [value] as RFQID FROM OPENJSON(@jsonoldVal) a where [key]='RfqId'
					) a
				END
				 
				IF isnull(@UserID,0) =0
				BEGIN
					SELECT @UserID = contact_id from mp_rfq where rfq_id = @rfq_id
				END
				---Get the Existing and Create new version for RFQ changes
				BEGIN
					SELECT @RFQVersion = count(1)+1 FROM mp_rfq_versions WHERE RFQ_ID = @rfq_id 

					---Create new version entry for RFQ changes
					INSERT INTO mp_rfq_versions(contact_id
												, major_number
												, minor_number
												, version_number
												, creation_date
												, RFQ_ID)
					VALUES(@UserID, @RFQVersion,0,convert(varchar(5), @RFQVersion) + '.0', @CreationDate,@rfq_id)
					set @newRFQVersionId = @@IDENTITY 
				END
				 
				--Create the revision history data 
				BEGIN
					IF OBJECT_ID('tempdb..#tmpRFQParts') IS NOT NULL DROP TABLE #tmpRFQParts; 		
					--Creatind 
					SELECT distinct @rfq_id as rfq_id
							, coalesce(OldKey, newKey) as field
							, isnull(OldValue,'') as OldValue
							, isnull(NewValue,'') as NewValue
							, @CreationDate as CreationDate
							, @newRFQVersionId as newRFQVrsionID
							into #tmpRFQParts
						FROM 
						(
							SELECT distinct
	
								*
							, CASE WHEN isnull(a.OldValue,'') <> isnull(b.NewValue,'') THEN 
									1 
								Else 
									0 
								END AS is_Modified 
							FROM (@OldValueTable a 
							full  JOIN @NewValueTable b
							on a.OldKey = b.NewKey 
							 
							) cross join @IDTable 
						) as AuditData where is_Modified = 1
						AND coalesce(OldKey, newKey) in ('PartId', 'IsRfqPartDefault' )
					 
					--Inserting revision data for RFQ
					INSERT INTO mp_rfq_revision(rfq_id
												, field
												, oldvalue
												, newvalue
												, creation_date
												, rfq_version_id)
					SELECT 
						rfq_id
					, CASE WHEN field ='PartId' and oldvalue ='' THEN
							'Part Newly added'
						WHEN field ='IsRfqPartDefault' THEN
							'Is Default RFQ Part?'
						ELSE	
							field
						END as field
					, CASE WHEN field ='PartId' THEN
							isnull((SELECT top 1 part_name from mp_parts where part_id = trp.oldValue),'')
						WHEN field ='IsRfqPartDefault' THEN
							(
								SELECT CASE WHEN ltrim(rtrim(oldvalue)) ='' THEN
									''
								WHEN ltrim(rtrim(oldvalue)) = 'false' THEN
									'No'
								ELSE 
								'	Yes'
								END
							)
						ELSE	
							isnull(oldvalue,'')
						END as oldvalue
					, CASE WHEN field ='PartId' THEN
							isnull((SELECT top 1 part_name from mp_parts where part_id = trp.newValue),'')
						WHEN field ='IsRfqPartDefault' THEN
							(
								SELECT CASE WHEN ltrim(rtrim(newValue)) ='' THEN
									''
								WHEN ltrim(rtrim(newValue)) = 'false' THEN
									'No'
								ELSE 
								'	Yes'
								END
							)
						ELSE	
							isnull(newValue,'')
						END as newValue
					, CreationDate
					, newRFQVrsionID
					from #tmpRFQParts trp
				END
				Update mp_data_history_working set is_processed = 1, processed_date = getdate() where data_history_id = @DataHistoryId
			END
			
			--print lower(@TableName)
			IF lower(@TableName) = 'mp_rfq_part_quantity'
			BEGIN
				BEGIN TRY
					DELETE FROM @jsonOldTable
					DELETE FROM @jsonNewTable
					--select * from mp_data_history_working
					--Getting Old and New temporaray tables for Quantity data processing.

					SET @sqlStr = '
					SELECT 
						[PartQty],  [QuantityLevel], [RfqPartId]
			
					FROM OPENJSON
					(
						''' + @jsonOldVal +'''
					)
					WITH ([PartQty] numeric(18,2) ''$.PartQty'',  [QuantityLevel] int ''$.QuantityLevel'',  [RfqPartId] int ''$.RfqPartId'')
					'
					insert into @jsonOldTable([OldPartQty], [OldQuantityLevel], [OldRfqPartId])
					EXEC sp_executesql @sqlStr 

					SET @sqlStr = ''
					SET @sqlStr = '
					SELECT 
						[PartQty],  [QuantityLevel], [RfqPartId]
			
					FROM OPENJSON
					(
						''' + @jsonNewVal +'''
					)
					WITH ([PartQty] numeric(18,2) ''$.PartQty'',  [QuantityLevel] int ''$.QuantityLevel'',  [RfqPartId] int ''$.RfqPartId'')
					'

					insert into @jsonNewTable([NewPartQty], [NewQuantityLevel], [NewRfqPartId])
					EXEC sp_executesql @sqlStr 
			
			
					IF OBJECT_ID('tempdb..#tmpRFQPartQtyData') IS NOT NULL DROP TABLE #tmpRFQPartQtyData; 
					SELECT * into #tmpRFQPartQtyData FROM 
					@jsonOldTable ot
					Full Join @jsonNewTable nt
					ON ot.OldRfqPartId = nt.NewRfqPartId
					and ot.OldQuantityLevel=nt.NewQuantityLevel
			

					IF OBJECT_ID('tempdb..#tmpRFQPartQtyProcessedData') IS NOT NULL DROP TABLE #tmpRFQPartQtyProcessedData; 
					 SELECT  
						 mrf.rfq_id
						 ,  convert(nvarchar(3), coalesce(rpqd.OldQuantityLevel, newQuantityLevel)+1) +
							CASE WHEN coalesce(rpqd.OldQuantityLevel, newQuantityLevel) +1 = 1 THEN 
								'st'
								 WHEN coalesce(rpqd.OldQuantityLevel, newQuantityLevel)+1 = 2 THEN 
								 'nd'
								 WHEN coalesce(rpqd.OldQuantityLevel, newQuantityLevel)+1 = 3 THEN 
								 'rd'
								 Else
								'th'
								End +	  ' Part Quantity - "' 
								+  isnull(mp.part_name,'') + '"' as field
						 , convert(nvarchar(10), rpqd.OldPartQty) as OldValue 
						 , convert(nvarchar(10), rpqd.NewPartQty) as NewValue
						, @CreationDate as CreationDate
						into #tmpRFQPartQtyProcessedData 
					 FROM #tmpRFQPartQtyData rpqd
					 JOIN mp_rfq_parts mrf on mrf.rfq_part_id = coalesce(rpqd.OldRfqPartId, NewRfqPartId)
					 JOIN mp_parts mp on mrf.part_id = mp.part_id
					 
					 
			  
					---Find the RFQ id for processing
					BEGIN
						SET @rfq_id = 0
						SELECT @rfq_id = max(RFQID) FROM 
						(
							select distinct  rfq_id as RFQID from #tmpRFQPartQtyProcessedData
						) a
					END
				 
					IF isnull(@UserID,0) =0
					BEGIN
						SELECT @UserID = contact_id from mp_rfq where rfq_id = @rfq_id
					END

					---Get the Existing and Create new version for RFQ changes
					BEGIN
						SELECT @RFQVersion = count(1)+1 FROM mp_rfq_versions WHERE RFQ_ID = @rfq_id 

						---Create new version entry for RFQ changes
						INSERT INTO mp_rfq_versions(contact_id
													, major_number
													, minor_number
													, version_number
													, creation_date
													, RFQ_ID)
						VALUES(@UserID, @RFQVersion,0,convert(varchar(5), @RFQVersion) + '.0', @CreationDate,@rfq_id)
						set @newRFQVersionId = @@IDENTITY 
					END

					---Setting up revision data
					INSERT INTO mp_rfq_revision
					(rfq_id
						, field
						, oldvalue
						, newvalue
						, creation_date
						, rfq_version_id)
					SELECT rfq_id
						, field
						, isnull(oldvalue,'')
						, isnull(newvalue,'')
						, CreationDate
						, @newRFQVersionId
					FROM 
						#tmpRFQPartQtyProcessedData 
					WHERE isnull(oldvalue,'')<>isnull(newvalue,'')
				END TRY
				BEGIN CATCH
					print error_message()
				END CATCH

				Update mp_data_history_working set is_processed = 1, processed_date = getdate() where data_history_id = @DataHistoryId
			END

			IF lower(@TableName) = 'mp_parts'
			BEGIN
				---Create version history for RFQ changes
				SELECT @part_id = IDValue  FROM @IDTable  
				/*
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
				SELECT distinct @part_id, NewKey, isnull(OldValue,''), isnull(NewValue,''), @CreationDate, @newPartVersionId FROM 
				 (
					 SELECT distinct 
	
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

				Update mp_data_history_working set is_processed = 1, processed_date = getdate() where data_history_id = @DataHistoryId
				*/
			END

		

		---Code to update Data in readable format
		print 'Started Data Cleaning..'
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
			WHEN (field ='IsSpecialCertificationsByManufacturer') THEN
				'Is special certifications by Manufacturer?'	
			WHEN (field ='IsSpecialInstructionToManufacturer') THEN
				'Is special instruction to Manufacturer?'
			WHEN (field ='SpecialInstructionToManufacturer') THEN
				'Special instruction to Manufacturer'
			WHEN (field ='QuotesNeededBy') THEN
				'Quotes needed by'
			WHEN (field ='AwardDate') THEN
				'Award date'

			WHEN (field ='IsRegisterSupplierQuoteTheRfq') THEN
				'Is registered Supplier quote the RFQ'
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
				WHEN (field ='IsSpecialCertificationsByManufacturer') THEN
				(
					SELECT CASE WHEN ltrim(rtrim(oldvalue)) ='' THEN
								''
							WHEN ltrim(rtrim(oldvalue)) = 'false' THEN
							'No'
							ELSE 
							'Yes'
						END
				)
				WHEN (field ='IsSpecialInstructionToManufacturer') THEN
				(
					SELECT CASE WHEN ltrim(rtrim(oldvalue)) ='' THEN
								''
							WHEN ltrim(rtrim(oldvalue)) = 'false' THEN
							'No'
							ELSE 
							'Yes'
						END
				)
				WHEN (field ='QuotesNeededBy') THEN
				(
					format(convert(datetime, oldvalue),'yyyy-MM-dd')
				)
				WHEN (field ='AwardDate') THEN
				(
					format(convert(datetime, oldvalue),'yyyy-MM-dd')
				)
				WHEN (field ='IsRegisterSupplierQuoteTheRfq') THEN
				(
					SELECT CASE WHEN ltrim(rtrim(oldvalue)) ='' THEN
								''
							WHEN ltrim(rtrim(oldvalue)) = 'false' THEN
							'No'
							ELSE 
							'Yes'
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
			WHEN (field ='IsSpecialCertificationsByManufacturer') THEN
				(
					SELECT CASE WHEN ltrim(rtrim(newvalue)) ='' THEN
								''
							WHEN ltrim(rtrim(newvalue)) = 'false' THEN
							'No'
							ELSE 
							'Yes'
						END
				)
			WHEN (field ='IsSpecialInstructionToManufacturer') THEN
				(
					SELECT CASE WHEN ltrim(rtrim(newvalue)) ='' THEN
								''
							WHEN ltrim(rtrim(newvalue)) = 'false' THEN
							'No'
							ELSE 
							'Yes'
						END
				)
			WHEN (field ='QuotesNeededBy') THEN
				(
					format(convert(datetime, newvalue),'yyyy-MM-dd')
				)
			WHEN (field ='AwardDate') THEN
				(
					format(convert(datetime, newvalue),'yyyy-MM-dd')
				)
			WHEN (field ='IsRegisterSupplierQuoteTheRfq') THEN
				(
					SELECT CASE WHEN ltrim(rtrim(newvalue)) ='' THEN
								''
							WHEN ltrim(rtrim(newvalue)) = 'false' THEN
							'No'
							ELSE 
							'Yes'
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
			WHERE field in ('IsRegisterSupplierQuoteTheRfq','AwardDate', 'QuotesNeededBy', 'SpecialInstructionToManufacturer','IsSpecialInstructionToManufacturer'
			,'IsSpecialCertificationsByManufacturer', 'ImportancePrice', 'ImportanceQuality', 'ImportanceSpeed'
			, 'RfqStatusId', 'ShipTo', 'PrefNdaType','WhoPaysForShipping')
 
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
		print 'END Data Cleaning..'



		END TRY
		BEGIN CATCH
			print error_message()
		END CATCH

		FETCH NEXT FROM C1 into @DataHistoryId, @jsonOldVal, @jsonNewVal , @jsonIDVal , @CreationDate, @UserID, @TableName 
	END
	Close C1
	DEALLOCATE C1

	--Code to cleanup unwanted fields from mp_rfq_revision 
	Print '-Cleanup unwanted fields from mp_rfq_revision'
	BEGIN
		DELETE FROM mp_rfq_revision where field in ('ModifiedBy')
	END

	---Cleanup data for Revision history
	print '--Revision data cleaning ...'
	EXEC dbo.proc_set_RevisionData_Cleanup

END
