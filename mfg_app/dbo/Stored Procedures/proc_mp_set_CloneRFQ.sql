

/*

declare @p10 nvarchar(250)
set @p10=N''
declare @p11 int
set @p11=1190604
exec sp_executesql N'exec proc_mp_set_CloneRFQ @NewRFQName,@OriginalRFQID,@Contact_id,@DeliveryDate,@IsEdit,@ManufacturingLocationId,@IsClonedWhileRfqCreation,@ErrorMessage OUT,@CloneRfqId OUT',N'@Contact_id int,@OriginalRFQID int,@NewRFQName nvarchar(200),@DeliveryDate datetime,@IsEdit bit,@ManufacturingLocationId int,@IsClonedWhileRfqCreation bit,@ErrorMessage nvarchar(250) output,@CloneRfqId int output',@Contact_id=1337828,@OriginalRFQID=1190602,@NewRFQName=N'1190602',@DeliveryDate='2020-04-27 10:50:10.790',@IsEdit=0,@ManufacturingLocationId=3,@IsClonedWhileRfqCreation=1,@ErrorMessage=@p10 output,@CloneRfqId=@p11 output
select @p10, @p11

*/
CREATE  PROCEDURE [dbo].[proc_mp_set_CloneRFQ]
(
@NewRFQName varchar(200)
, @OriginalRFQID int
, @Contact_id int
, @DeliveryDate DATETIME
, @QuotesNeededBy DATETIME
, @AwardDate DATETIME
, @IsEdit bit = 0
, @ManufacturingLocationId int = 0
, @IsClonedWhileRfqCreation bit = 0
, @QuantityUnitId int = 0
, @ErrorMessage nvarchar(250) OUTPUT
, @CloneRfqId int OUTPUT
)
AS
-- =============================================
-- Create date:  19 Sep, 2018
-- Description:	Procedure used for cloning the RFQ 
-- Modification:
-- =================================================================
--Version No – Change Date – Modified By      – CR No – Note
-- =================================================================
-- 
-- =================================================================

BEGIN
	--print 'Start'
	DECLARE @RaisedErrorMsg nvarchar(200)
	SET @RaisedErrorMsg = 'Contact id ' + convert(varchar(10), @Contact_id) + ' is not authorised to clone RFQ#' +  convert(varchar(10), @OriginalRFQID) 
			
	IF EXISTS(SELECT 1 FROM mp_rfq WHERE rfq_id = @OriginalRFQID and contact_id = @Contact_id)
	BEGIN
	--print 'Start 1'
		
		BEGIN TRY
			BEGIN TRAN
				DECLARE @NewRFQID int, @ClonedRFQ_accepted_nda_id  int

								
				INSERT INTO [dbo].mp_rfq( rfq_name
					, rfq_description
					, contact_id
					, rfq_created_on
					, rfq_status_id
					, is_special_certifications_by_manufacturer
					, is_special_instruction_to_manufacturer
					, special_instruction_to_manufacturer
					, importance_price
					, importance_speed
					, importance_quality
					, Quotes_needed_by
					, award_date
					, is_partial_quoting_allowed
					, Who_Pays_for_Shipping
					, ship_to
					, is_register_supplier_quote_the_RFQ
					, pref_NDA_Type
					, Post_Production_Process_id
					, Imported_Data
					, payment_term_id
					, pref_rfq_communication_method
					, rfq_purpose_id
					, DeliveryDate  ---- added M2-3847
					)
				SELECT 
					 @NewRFQName as rfq_name
					, rfq_description
					, contact_id
					, getdate() rfq_created_on
					, case when @IsEdit = 1 then 1 else 2 end as rfq_status_id					 
					, is_special_certifications_by_manufacturer
					, is_special_instruction_to_manufacturer
					, special_instruction_to_manufacturer
					, importance_price
					, importance_speed
					, importance_quality
					, @QuotesNeededBy
					, @AwardDate
					, is_partial_quoting_allowed
					, Who_Pays_for_Shipping
					, ship_to
					, is_register_supplier_quote_the_RFQ
					, pref_NDA_Type
					, Post_Production_Process_id
					, Imported_Data
					, payment_term_id
					, pref_rfq_communication_method
					, rfq_purpose_id
					, @DeliveryDate as DeliveryDate  ---- added M2-3847
				FROM 
					[dbo].mp_rfq 
				WHERE rfq_id = @OriginalRFQID

				SET @NewRFQID = @@IDENTITY
				
				INSERT INTO mp_rfq_cloned_logs (parent_rfq_id,cloned_rfq_id)
				SELECT @OriginalRFQID , @NewRFQID

				/* Ewesterfield-MFG  11:20 PM Here is a bug for cloned RFQ's. Currently if the buyer does not assign a name to the RFQ the system assigns the RFQ number as the name BUT it assigns the same number to all regions. In the screenshot below you can see how the RFQ for Asia and Latin America have been assigned the RFQ number if the USA RFQ as its RFQ Name. (edited) */
				IF @NewRFQName = CONVERT(VARCHAR(150),@OriginalRFQID)
					UPDATE mp_rfq SET rfq_name = @NewRFQID WHERE rfq_id = @NewRFQID

				INSERT INTO [dbo].mp_rfq_parts
					( part_id
					, rfq_id
					, delivery_date
					, quantity_unit_id
					, status_id
					, part_category_id
					, created_date
					, modification_date
					, Post_Production_Process_id
					, Is_Rfq_Part_Default
					, min_part_quantity
					, min_part_quantity_unit
					, material_id
					, is_existing_part									 
					, is_child_category_selected
					, is_apply_parent_process	
					, parent_rfq_part_id
					, is_apply_process
					, is_apply_material
					, is_apply_post_process
					, is_apply_delivery_date
					)
				SELECT   part_id
					, @NewRFQID as rfq_id
					----, case when @IsClonedWhileRfqCreation = 1 then delivery_date else @DeliveryDate end as delivery_date	-- commented with M2-3847
					, NULL as delivery_date  ---- Added with M2-3847
					, quantity_unit_id
					, status_id
					, part_category_id
					, GETDATE() created_date
					, GETDATE() modification_date
					, Post_Production_Process_id
					, Is_Rfq_Part_Default
					, min_part_quantity
					, min_part_quantity_unit
					, material_id
					, is_existing_part					 
					, is_child_category_selected
					, is_apply_parent_process
					, parent_rfq_part_id
					, is_apply_process
					, is_apply_material
					, is_apply_post_process
					, is_apply_delivery_date
				FROM [dbo].mp_rfq_parts where rfq_id = @OriginalRFQID
				AND status_id = 2 --Valid parts

				INSERT INTO [dbo].mp_rfq_parts_file(rfq_part_id
					, file_id
					, creation_date
					, status_id
					, is_primary_file)
				SELECT 
					ClonedRFQParts.rfq_part_id
					, OriginalRFQPartsFile.file_id
					, getdate()
					, OriginalRFQPartsFile.status_id
					, OriginalRFQPartsFile.is_primary_file  
				FROM [dbo].mp_rfq_parts as OriginalRFQParts 
				JOIN [dbo].mp_rfq_parts as ClonedRFQParts  on OriginalRFQParts.part_id = ClonedRFQParts.part_id 
				JOIN [dbo].mp_rfq_parts_file as OriginalRFQPartsFile on OriginalRFQPartsFile.rfq_part_id = OriginalRFQParts.rfq_part_id
				and OriginalRFQParts.rfq_id = @OriginalRFQID 
				and ClonedRFQParts.rfq_id = @NewRFQID
				and OriginalRFQPartsFile.status_id = 2
	
				INSERT INTO [dbo].mp_rfq_part_quantity
				(
					rfq_part_id
					, part_qty
					, quantity_level
					, is_deleted
				)
				/* M2-2087 Clone up to 3 RFQ's for 3 regions - API */
				SELECT
					B.rfq_part_id
					,A.part_qty
					,A.quantity_level
					,A.is_deleted
				FROM
				(
					SELECT 
						@NewRFQID AS ClonedRFQId
						,OriginalRFQPartsQty.rfq_part_id
						, OriginalRFQPartsQty.part_qty
						, OriginalRFQPartsQty.quantity_level
						, OriginalRFQPartsQty.is_deleted
						, DENSE_RANK() OVER(ORDER BY OriginalRFQPartsQty.rfq_part_id) AS RN
					FROM [dbo].mp_rfq_parts as OriginalRFQParts 					
					JOIN [dbo].mp_rfq_part_quantity as OriginalRFQPartsQty on OriginalRFQPartsQty.rfq_part_id = OriginalRFQParts.rfq_part_id
					AND OriginalRFQParts.rfq_id = @OriginalRFQID 
				) A
				JOIN 
				(
					SELECT 
						@NewRFQID AS ClonedRFQId
						,ClonedRFQParts.rfq_part_id
						, ROW_NUMBER() OVER(ORDER BY rfq_part_id) AS RN
					FROM [dbo].mp_rfq_parts as ClonedRFQParts 					
					WHERE ClonedRFQParts.rfq_id = @NewRFQID 
				) B ON A.ClonedRFQId = B.ClonedRFQId  AND A.RN = B.RN
				
					--SELECT DISTINCT
					--	ClonedRFQParts.rfq_part_id
					--	, OriginalRFQPartsQty.part_qty
					--	, OriginalRFQPartsQty.quantity_level
					--	, OriginalRFQPartsQty.is_deleted
					--FROM 
					--	[dbo].mp_rfq_parts as OriginalRFQParts 
					--	JOIN [dbo].mp_rfq_parts as ClonedRFQParts  on OriginalRFQParts.part_id = ClonedRFQParts.part_id 
					--	JOIN [dbo].mp_rfq_part_quantity as OriginalRFQPartsQty on OriginalRFQPartsQty.rfq_part_id = OriginalRFQParts.rfq_part_id
					--	and OriginalRFQParts.rfq_id = @OriginalRFQID 
					--	and ClonedRFQParts.rfq_id = @NewRFQID
				/**/

				INSERT INTO [dbo].mp_rfq_accepted_nda 
				(
					rfq_id	
					, nda_content	
					, creation_date	
					, status_id
				)
				SELECT TOP 1
					@NewRFQID
					, nda_content
					, getdate()
					, status_id  
				FROM 
					[dbo].mp_rfq_accepted_nda 
				WHERE 
					rfq_id = @OriginalRFQID and status_id = 2

				SET @ClonedRFQ_accepted_nda_id = @@IDENTITY

				INSERT INTO [dbo].mp_rfq_nda_files
				(
					rfq_accepted_nda_id
					,[file_id]
				)
				SELECT TOP 1 
					@ClonedRFQ_accepted_nda_id
					, [FILE_ID]  
				FROM [dbo].mp_rfq_accepted_nda mran
				JOIN [dbo].mp_rfq_nda_files mrnf on mran.rfq_accepted_nda_id = mrnf.rfq_accepted_nda_id
				and mran.rfq_id = @OriginalRFQID

				INSERT INTO [dbo].mp_rfq_other_files
				(
				 rfq_id
				, file_id
				, creation_date
				, status_id
				)
				SELECT @NewRFQID
					, file_id	
					, getdate() creation_date	
					, status_id
				FROM 
					[dbo].mp_rfq_other_files 
				WHERE rfq_id = @OriginalRFQID

				INSERT INTO [dbo].mp_rfq_supplier
				(
					rfq_id	
					, company_id	
					, supplier_group_id
				)
				SELECT 
					@NewRFQID
					, company_id
					, supplier_group_id 
				FROM 
					[dbo].mp_rfq_supplier  
				WHERE 
					rfq_id = @OriginalRFQID

		----Inserting RFQ certificates-----
				INSERT INTO [dbo].mp_rfq_special_certificates
				(
					rfq_id	
					, certificate_id	
					, creation_date
				)
				SELECT 
					@NewRFQID
					, certificate_id
					, getdate() creation_date 
				FROM 
					[dbo].mp_rfq_special_certificates  
				WHERE 
					rfq_id = @OriginalRFQID

				INSERT INTO mp_rfq_preferences 
				SELECT @NewRFQID,@ManufacturingLocationId,@Contact_id																		

				/* M2-2772 RFQ revision history not showing changes - DB*/
				IF ((SELECT COUNT(1) FROM mp_data_history (NOLOCK) WHERE field = '{"RfqId":'+CONVERT(VARCHAR(50),@NewRFQID)+'}')= 0)
				BEGIN

					 INSERT INTO mp_data_history (field,oldvalue,newvalue,creation_date,userid,tablename)
					 -- mp_rfq
					 SELECT 
						'{"RfqId":'+CONVERT(VARCHAR(50),a.rfq_id)+'}' field, 
						'{"RfqStatusId":3}' oldvalue,
						'{"RfqName":"'+rfq_name+'","RfqStatusId":'+CONVERT(VARCHAR(10),rfq_status_id)+',"AwardDate":"'+CONVERT(VARCHAR(10),award_date,120)+'","ImportancePrice":'+CONVERT(VARCHAR(10),importance_price)+',"ImportanceQuality":'+CONVERT(VARCHAR(10),importance_quality)+',"ImportanceSpeed":'+CONVERT(VARCHAR(10),importance_speed)+',"PrefRfqCommunicationMethod":'+CONVERT(VARCHAR(10),pref_rfq_communication_method)+',"QuotesNeededBy":"'+CONVERT(VARCHAR(10),Quotes_needed_by,120)+'","ShipTo":'+CONVERT(VARCHAR(10),ship_to)+',"WhoPaysForShipping":'+CONVERT(VARCHAR(10),Who_Pays_for_Shipping)+',"PrefNdaType":'+CONVERT(VARCHAR(10),pref_NDA_Type)+',"IsRegisterSupplierQuoteTheRfq":'+CASE WHEN is_register_supplier_quote_the_RFQ = 1 THEN 'true' ELSE 'false' END+',"IsSpecialCertificationsByManufacturer":'+CASE WHEN is_special_certifications_by_manufacturer = 1 THEN 'true' ELSE 'false' END+',"IsSpecialInstructionToManufacturer":'+CASE WHEN is_special_instruction_to_manufacturer = 1 THEN 'true' ELSE 'false' END+',"SpecialInstructionToManufacturer":'+CASE WHEN is_special_instruction_to_manufacturer = 1 THEN '"'+CONVERT(NVARCHAR(MAX),ISNULL(special_instruction_to_manufacturer,''))+'"' ELSE '""' END +',"CertificateId":'+CASE WHEN is_special_certifications_by_manufacturer = 1 THEN CONVERT(VARCHAR(10),b.certificate_id) ELSE '""' END+'}' newvalue , GETUTCDATE() creation_date
						, contact_id userid
						,'mp_rfq' tablename
					 FROM mp_rfq (NOLOCK) a
					 LEFT JOIN mp_rfq_special_certificates (NOLOCK) b ON a.rfq_id = b.rfq_id
					 WHERE a.rfq_id = @NewRFQID


					 INSERT INTO mp_data_history (field,oldvalue,newvalue,creation_date,userid,tablename)
					 -- mp_rfq_parts
					  SELECT 
						'{"RfqPartId":'+CONVERT(VARCHAR(50),b.rfq_part_id)+'}' field, NULL oldvalue,'{"PartId":'+CONVERT(VARCHAR(50),b.part_id)+',"IsRfqPartDefault":'+CASE WHEN Is_Rfq_Part_Default = 1 THEN 'true' ELSE 'false' END+'}' newvalue , GETUTCDATE() creation_date
						, contact_id userid
						,'mp_rfq_parts' tablename
					 FROM mp_rfq (NOLOCK) a
					 JOIN mp_rfq_parts (NOLOCK) b ON a.rfq_id = b.rfq_id
					 WHERE a.rfq_id = @NewRFQID
 



					 INSERT INTO mp_data_history (field,oldvalue,newvalue,creation_date,userid,tablename)
					 -- mp_rfq_preferences
					 SELECT 
						'{"RfqId":'+CONVERT(VARCHAR(50),a.rfq_id)+'}' field 
						, NULL oldvalue
						, '{"RfqPrefManufacturingLocationId":'+CONVERT(VARCHAR(50),b.rfq_pref_manufacturing_location_id) +'}' newvalue  
						, GETUTCDATE() creation_date
						, contact_id userid
						,'mp_rfq_preferences' tablename
					 FROM mp_rfq (NOLOCK) a
					 LEFT JOIN mp_rfq_preferences (NOLOCK) b ON a.rfq_id = b.rfq_id
					 WHERE a.rfq_id = @NewRFQID
				END

				/*M2-3421  Buyer - Modify the Units list - DB*/
				IF(@QuantityUnitId > 0)
				BEGIN
				    UPDATE mp_rfq_parts SET quantity_unit_id = @QuantityUnitId 
					WHERE rfq_id = @NewRFQID 
						 AND quantity_unit_id NOT IN(14,23,24)
				END
				/**/

				/*M2-3419 : Buyer - Injection Molding Part drawer additions - DB*/
				IF ((SELECT COUNT(1) FROM mp_rfq_part_drawer_answers (NOLOCK) WHERE RfqPartId IN (SELECT rfq_part_id FROM mp_rfq_parts WHERE rfq_id = @OriginalRFQID)) > 0)
				BEGIN
				  CREATE TABLE #CloneRFQParts (id int, rfq_part_id int)
				  CREATE TABLE #OriginalRFQParts (id int, rfq_part_id int)

				  insert into #CloneRFQParts    SELECT ROW_NUMBER() OVER(ORDER BY rfq_part_id),rfq_part_id FROM mp_rfq_parts WHERE rfq_id = @NewRFQID
				  insert into #OriginalRFQParts SELECT ROW_NUMBER() OVER(ORDER BY rfq_part_id) as id,rfq_part_id FROM mp_rfq_parts WHERE rfq_id = @OriginalRFQID

				  INSERT INTO mp_rfq_part_drawer_answers 
				  SELECT a.rfq_part_id,c.PartId,c.QuestionId,c.Answer,GETUTCDATE() 
				  FROM #CloneRFQParts a 
						join #OriginalRFQParts b ON(a.id = b.id) 
						join mp_rfq_part_drawer_answers c on(b.rfq_part_id = c.RfqPartId)
				END
				/**/

				COMMIT TRAN
				SET @ErrorMessage = ''
				SET @CloneRfqId = @NewRFQID
				--print @NewRFQID
			END TRY
			BEGIN CATCH
				if @@ERROR <> 0 
				BEGIN
					SET @ErrorMessage = ''
					ROLLBACK TRAN
				END
				SET @ErrorMessage = 'RFQ Cloning failed! ' + char(13)  + ERROR_MESSAGE() 
			END CATCH
	END
	ELSE
	BEGIN
		SET @ErrorMessage =@RaisedErrorMsg
	END
END
