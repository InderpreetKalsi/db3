


/*

select * from mpCommunityDirectRfqs order by id desc 

exec proc_set_CommunityDirectRfqs 
@SupplierEmail = '1@yopmail.com'
,@BuyerEmail = '2@yopmail.com'
,@CommunityDirectRfqsJSON=
N'{"supplierEmail":"ZGVsYXBsZXhtYWtzdXBwbGllckB5b3BtYWlsLmNvbQ==","supplierCompanyId":"1769227","buyerIpAddress":"106.197.223.78, 64.252.99.17","FirstName":"tanay","LastName":"choudhary","buyerEmail":"dGFuYXlwcmVzZW50aW5naGltc2VsZkBnbWFpbC5jb20=","buyerPhone":"09740278817","partDesc":"","partFile":["638149829033600034_S3_DSC01901_1.jpg","638149829039093517_S3_DSC02487.jpg"],"capability":"Extrusions","material":"Alloy Steel","leadTime":"1","leadTimeDuration":"days","isNdaRequired":false,"WantsMP":false}'

select top 5 * from mp_special_files order by 1 desc 
select top 5 * from mpCommunityDirectRfqs order by 1 desc 
select top 5 * from mpCommunityDirectRfqsFiles order by 1 desc 
*/
CREATE PROCEDURE [dbo].[proc_set_CommunityDirectRfqs]
(
	@SupplierEmail VARCHAR(250)
	,@BuyerEmail VARCHAR(250)
	,@CommunityDirectRfqsJSON NVARCHAR(MAX)
)
AS
BEGIN

	-- M2-4782 Directory - Change the Simple RFQ uploader module to accept up to 10 files
	DECLARE @DirectRfqsJSON VARCHAR(MAX) 
	DECLARE @CommunityDirectRfqsRunningId  TABLE (Id INT NULL)
	DECLARE @DirectRfqsRunningId BIGINT
	DECLARE @TransactionStatus VARCHAR(50)= 'Failure'

	SET @DirectRfqsJSON =  REPLACE(@CommunityDirectRfqsJSON,CHAR(160),'')

	BEGIN TRY
	
		BEGIN TRAN
				INSERT INTO mp_special_files
				(	file_name,cont_id,comp_id,is_deleted,filetype_id,creation_date,imported_location,parent_file_id
					,legacy_file_id	,file_title	,file_caption,file_path	,s3_found_status,is_processed,sort_order
				)	
				OUTPUT INSERTED.FILE_ID INTO @CommunityDirectRfqsRunningId
				SELECT 
					partFileName ,NULL ,NULL ,0 ,76 ,GETUTCDATE() ,NULL ,NULL ,NULL ,NULL ,NULL ,NULL
					,NULL ,0 ,NULL  
				FROM OPENJSON(@DirectRfqsJSON)
				WITH( 
				partFileJson nvarchar(MAX)  '$.PartFile' AS JSON)
				CROSS APPLY OPENJSON(partFileJson) WITH (
				partFileName VARCHAR(250) '$')


				INSERT INTO  mpCommunityDirectRfqs
				(
				SupplierEmail,SupplierCompanyId,BuyerIpAddress,BuyerEmail,BuyerPhone,PartDesc
				,PartFileId,Capability,Material,Quantity,LeadTime,LeadTimeDuration,NdaFileId
				,IsNdaRequired,IsNdaAcceptedBySupplier,NdaAcceptedDate,WantsMP,CreatedOn
				,CommunitySupplierProfileURL,FirstName,LastName
				)
				SELECT 
					@SupplierEmail ,supplierCompanyId ,buyerIpAddress ,@BuyerEmail ,buyerPhone ,partDesc 
					,NULL ,capability ,material ,NULL,leadTime ,leadTimeDuration ,NULL
					,isNdaRequired ,0 ,NULL ,WantsMP ,GETUTCDATE() 
					,NULL ,FirstName ,LastName 
				FROM OPENJSON(@DirectRfqsJSON) 
				WITH 
				(
					supplierEmail		NVARCHAR(2000) '$.supplierEmail',
					supplierCompanyId	INT '$.SupplierCompanyId',
					buyerIpAddress		NVARCHAR(2000) '$.BuyerIpAddress',
					FirstName			NVARCHAR(500) '$.FirstName',
					LastName			NVARCHAR(500) '$.LastName',
					buyerEmail			NVARCHAR(500) '$.buyerEmail',
					buyerPhone			NVARCHAR(500) '$.BuyerPhone',
					partDesc			NVARCHAR(2000) '$.PartDesc',
					capability			NVARCHAR(500) '$.Capability',
					material 			NVARCHAR(500) '$.Material',
					--leadTime			INT '$.LeadTime',
					leadTime			DECIMAL(5,4) '$.LeadTime',
					leadTimeDuration	NVARCHAR(500) '$.LeadTimeDuration',
					isNdaRequired		BIT '$.IsNdaRequired',
					WantsMP				BIT '$.WantsMP'
				) AS i
				SET @DirectRfqsRunningId = @@IDENTITY

				INSERT INTO mpCommunityDirectRfqsFiles (CommunityDirectRfqId ,FileId)
				SELECT @DirectRfqsRunningId , * FROM @CommunityDirectRfqsRunningId
	 
		SET @TransactionStatus = 'Success'
		COMMIT TRAN
		SELECT @TransactionStatus AS TransactionStatus , @DirectRfqsRunningId AS DirectRfqsRunningId

	END TRY
	BEGIN CATCH
		
		ROLLBACK TRAN
		SET @TransactionStatus = 'Failure' + ' - ' + ERROR_MESSAGE()
		SELECT @TransactionStatus AS TransactionStatus , NULL AS DirectRfqsRunningId

	END CATCH
END
