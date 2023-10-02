

/*
select top 10 * from mp_rfq_parts order by rfq_part_id desc

select top 10 * from mp_parts order by part_id desc

declare @Error_Message nvarchar(250)
declare @Clone_RfqPartId int
exec [proc_mp_set_CloneRFQPart] @OriginalRFQPartID = 81786  , @CloneRfqPartId = @Clone_RfqPartId output  , @ErrorMessage = @Error_Message output
select @Error_Message Error_Message , @Clone_RfqPartId  Clone_RfqPartId 
*/

CREATE PROCEDURE [dbo].[proc_mp_set_CloneRFQPart]
( 
  @OriginalRFQPartID int 
, @ErrorMessage nvarchar(250) OUTPUT
, @CloneRfqPartId int OUTPUT
)
AS
-- =============================================
-- Create date:  14 Jan, 2019
-- Description:	Procedure used for cloning the RFQ Part
-- Modification:
-- =================================================================
--Version No – Change Date – Modified By      – CR No – Note
-- =================================================================
-- 
-- =================================================================

BEGIN	
		
    DECLARE @RaisedErrorMsg nvarchar(200)	
	DECLARE @NewPartId int


	SET @RaisedErrorMsg = 'unable to clone RFQPart#' +  convert(varchar(10), @OriginalRFQPartID) 
	IF EXISTS(SELECT 1 FROM mp_rfq_parts WHERE rfq_part_id = @OriginalRFQPartID)
	BEGIN
	--print 'Start 1'
		
		BEGIN TRY
			BEGIN TRAN
				DECLARE @NewRFQPartID int				 
								
				insert into mp_parts
				(
					part_name, part_number, part_commodity_code ,part_description ,material_id,part_qty_unit_id
					,part_category_id,status_id,company_id,contact_id,currency_id,creation_date,modification_date
					,Post_Production_Process_id,part_size_unit_id,width,height,depth,length,diameter,surface,volume,tolerance_id,is_child_category_selected
					,IsLargePart,GeometryId
				)
				select 	part_name, part_number, part_commodity_code ,part_description ,material_id,part_qty_unit_id
					,part_category_id,status_id,company_id,contact_id,currency_id,GETUTCDATE() creation_date,GETUTCDATE() modification_date
					,Post_Production_Process_id,part_size_unit_id,width,height,depth,length,diameter,surface,volume,tolerance_id,is_child_category_selected
					,IsLargePart,GeometryId
				from mp_parts (nolock)
				where part_id in (select part_id from mp_rfq_parts where rfq_part_id = @OriginalRFQPartID)
				SET @NewPartId = @@IDENTITY
								
				INSERT INTO [dbo].mp_rfq_parts
				( 						        			 
					part_id
					,rfq_id
					,delivery_date
					,quantity_unit_id
					,status_id
					,part_category_id
					,created_date
					,modification_date
					,Post_Production_Process_id
					,Is_Rfq_Part_Default
					,ModifiedBy
					,min_part_quantity
					,min_part_quantity_unit
					,material_id
					,is_apply_process
					,is_apply_material
					,is_apply_post_process
					,is_apply_delivery_date
					, is_existing_part						 
					, is_child_category_selected		
					, is_apply_parent_process	
					, parent_rfq_part_id
				)
				SELECT 
					@NewPartId
					,rfq_id
					----,delivery_date       ---- commented with M2-3847
					, NULL as delivery_date  ---- added with M2-3847
					,quantity_unit_id
					,status_id
					,part_category_id
					, GETUTCDATE() created_date
					, GETUTCDATE() modification_date
					,Post_Production_Process_id
					,0
					,ModifiedBy
					,min_part_quantity
					,min_part_quantity_unit
					,material_id
					,is_apply_process
					,is_apply_material
					,is_apply_post_process
					,is_apply_delivery_date	
					, is_existing_part							 
					, is_child_category_selected		
					, is_apply_parent_process	
					, parent_rfq_part_id
				FROM 
					[dbo].mp_rfq_parts 
				WHERE rfq_part_id = @OriginalRFQPartID
				AND status_id = 2 --Valid parts
				SET @NewRFQPartID = @@IDENTITY
				
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
				JOIN [dbo].mp_rfq_parts as ClonedRFQParts  on OriginalRFQParts.rfq_id = ClonedRFQParts.rfq_id 
				JOIN [dbo].mp_rfq_parts_file as OriginalRFQPartsFile on OriginalRFQPartsFile.rfq_part_id = OriginalRFQParts.rfq_part_id
				and OriginalRFQParts.rfq_part_id = @OriginalRFQPartID 
				and ClonedRFQParts.rfq_part_id = @NewRFQPartID
				and OriginalRFQPartsFile.status_id = 2


				INSERT INTO [dbo].mp_parts_files(parts_id
					, file_id					
					, is_primary_file)
				SELECT 
					ClonedRFQParts.part_id
					, OriginalRFQPartsFile.file_id					
					, OriginalRFQPartsFile.is_primary_file  
				FROM [dbo].mp_rfq_parts as OriginalRFQParts 
				JOIN [dbo].mp_rfq_parts as ClonedRFQParts  on OriginalRFQParts.rfq_id = ClonedRFQParts.rfq_id 
				JOIN [dbo].mp_rfq_parts_file as OriginalRFQPartsFile on OriginalRFQPartsFile.rfq_part_id = OriginalRFQParts.rfq_part_id
				and OriginalRFQParts.rfq_part_id = @OriginalRFQPartID 
				and ClonedRFQParts.rfq_part_id = @NewRFQPartID
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
						@NewRFQPartID AS ClonedRFQPartId
						,OriginalRFQPartsQty.rfq_part_id
						, OriginalRFQPartsQty.part_qty
						, OriginalRFQPartsQty.quantity_level
						, OriginalRFQPartsQty.is_deleted
						, DENSE_RANK() OVER(ORDER BY OriginalRFQPartsQty.rfq_part_id) AS RN
					FROM [dbo].mp_rfq_parts as OriginalRFQParts 					
					JOIN [dbo].mp_rfq_part_quantity as OriginalRFQPartsQty on OriginalRFQPartsQty.rfq_part_id = OriginalRFQParts.rfq_part_id
					AND OriginalRFQParts.rfq_part_id = @OriginalRFQPartID 
				) A
				JOIN 
				(
					SELECT 
						@NewRFQPartID AS ClonedRFQPartId
						,ClonedRFQParts.rfq_part_id
						, ROW_NUMBER() OVER(ORDER BY rfq_part_id) AS RN
					FROM [dbo].mp_rfq_parts as ClonedRFQParts 			 		
					WHERE ClonedRFQParts.rfq_part_id = @NewRFQPartID 
				) B ON A.ClonedRFQPartId = B.ClonedRFQPartId  AND A.RN = B.RN

				/*M2-3419 : Buyer - Injection Molding Part drawer additions - DB*/
				IF ((SELECT COUNT(1) FROM mp_rfq_part_drawer_answers (NOLOCK) WHERE RfqPartId = @OriginalRFQPartID) > 0)
					BEGIN
					   INSERT INTO mp_rfq_part_drawer_answers
					   SELECT @NewRFQPartID,@NewPartId, QuestionId, Answer,GETUTCDATE() FROM mp_rfq_part_drawer_answers WHERE RfqPartId = @OriginalRFQPartID
					END
			  /**/
				
			 						COMMIT TRAN
				SET @ErrorMessage = ''
				SET @CloneRfqPartId = @NewRFQPartID
				
			END TRY
			BEGIN CATCH
				if @@ERROR <> 0 
				BEGIN
					SET @ErrorMessage = ''
					ROLLBACK TRAN
				END
				SET @ErrorMessage = 'RFQ Part Cloning failed! ' + char(13)  + ERROR_MESSAGE() 
			END CATCH
	END
	ELSE
	BEGIN
		SET @ErrorMessage =@RaisedErrorMsg
	END
END
