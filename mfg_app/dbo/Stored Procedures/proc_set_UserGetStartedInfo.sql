

/*
SELECT * FROM mpUserGetStartedInfo (NOLOCK)


*/

------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[proc_set_UserGetStartedInfo]
(
	@ContactId INT
	,@StepId INT
	,@SubStepId INT = NULL
	,@IsPartFilesReady BIT = NULL
	,@IsHelpNeeded BIT = NULL
	,@PartFiles NVARCHAR(MAX) = NULL ---(comma seperated part files name)
	,@IsStandardNDA BIT = NULL
	,@IsSingleConfirm BIT = NULL
	,@CustomNDAFile NVARCHAR(MAX) = NULL ---(Custom NDA file name)
	
)
AS
BEGIN

    ----  M2-4537 Lock Buyer Engagement step on refresh - DB
	
	BEGIN TRY

	IF(@ContactId > 0 AND @StepId IS NOT NULL)
	BEGIN
		
		------ here need to check if contact id and stepid already existed then update that records
		IF ((SELECT COUNT(1)  FROM mpUserGetStartedInfo (NOLOCK)  WHERE ContactId = @ContactId AND StepId = @StepId AND SubStepId = @SubStepId ) > 0 )
		BEGIN

				IF @StepId = 2
				BEGIN

				        IF @SubStepId = 0
						BEGIN
							UPDATE mpUserGetStartedInfo
							SET  IsPartFilesReady = @IsPartFilesReady
							WHERE       ContactId = @ContactId 
									   AND StepId = @StepId
									AND SubStepId = @SubStepId
						END
						ELSE IF @SubStepId = 1 
						BEGIN
							UPDATE mpUserGetStartedInfo
							SET  PartFiles	  = @PartFiles
							,IsStandardNDA	  = @IsStandardNDA
							,IsSingleConfirm  = @IsSingleConfirm
							,CustomNDAFile	  = @CustomNDAFile
							WHERE   ContactId = @ContactId 
							AND        StepId = @StepId
							AND     SubStepId = @SubStepId
						END
						ELSE IF @SubStepId = 2
						BEGIN
							UPDATE mpUserGetStartedInfo
							SET   IsPartFilesReady = @IsPartFilesReady
						 		 ,IsHelpNeeded     = @IsHelpNeeded
							WHERE   ContactId = @ContactId 
							AND        StepId = @StepId
							AND     SubStepId = @SubStepId
						END

				END
				ELSE IF @StepId = 3
				BEGIN
				
					IF (@SubStepId = 0 OR @SubStepId = 1)
						BEGIN
							UPDATE mpUserGetStartedInfo
							SET   IsPartFilesReady = @IsPartFilesReady
						 		  ,IsHelpNeeded     = @IsHelpNeeded
								  , CustomNDAFile = @CustomNDAFile
								  , IsStandardNDA = @IsStandardNDA
								  , IsSingleConfirm = @IsSingleConfirm
							WHERE   ContactId = @ContactId 
							AND        StepId = @StepId
							AND     SubStepId = @SubStepId
						END

				END
				ELSE IF @StepId = 4 
				BEGIN
					 
					IF @SubStepId = 0
						BEGIN
							UPDATE mpUserGetStartedInfo
							SET   IsPartFilesReady = @IsPartFilesReady 
							,IsHelpNeeded     = @IsHelpNeeded
							WHERE   ContactId = @ContactId 
							AND        StepId = @StepId
							AND     SubStepId = @SubStepId
						END
				END
				

		END
		ELSE
		BEGIN
		
				INSERT INTO mpUserGetStartedInfo
					(
					 ContactId,
					 StepId,
					 SubStepId,
					 IsPartFilesReady,
					 IsHelpNeeded,
					 PartFiles,
					 IsStandardNDA,
					 IsSingleConfirm,
					 CustomNDAFile 
					 )
				VALUES      
					( @ContactId,
					  @StepId,
					  @SubStepId,
					  @IsPartFilesReady,
					  @IsHelpNeeded,
					  @PartFiles,
					  @IsStandardNDA,
					  @IsSingleConfirm,
					  @CustomNDAFile 
					  )
				END

		
	 END
	    
	SELECT 'Success' AS TransactionStatus 
		
	END TRY
	BEGIN CATCH
		SELECT 'Failed: '+ ERROR_MESSAGE()  TransactionStatus
	END CATCH

	   
END
