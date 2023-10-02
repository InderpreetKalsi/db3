

/*

EXEC  [dbo].[proc_get_UserGetStartedInfo] 1350725 

*/

------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[proc_get_UserGetStartedInfo]
(
	@ContactId INT
	,@StepId INT = NULL
	,@SubStepId INT = NULL
)
AS
BEGIN
----  M2-4537 Lock Buyer Engagement step on refresh - DB

	SET NOCOUNT ON
	
	SELECT 
		Id,
		ContactId,
		StepId,
		SubStepId,
		IsPartFilesReady,
		IsHelpNeeded,
		PartFiles,
		IsStandardNDA,
		IsSingleConfirm,
		CustomNDAFile 
	FROM mpUserGetStartedInfo (NOLOCK) 
	WHERE contactid = @ContactId 
			
	     
END
