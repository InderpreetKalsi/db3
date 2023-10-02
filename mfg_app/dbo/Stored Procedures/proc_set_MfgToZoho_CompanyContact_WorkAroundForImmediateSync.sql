
-- EXEC proc_set_MfgToZoho_CompanyContact_WorkAroundForImmediateSync
CREATE PROCEDURE [dbo].[proc_set_MfgToZoho_CompanyContact_WorkAroundForImmediateSync]
AS
BEGIN
	
	DECLARE @ContId INT
	DECLARE @CompId INT

	DROP TABLE IF EXISTS #tmpproc_set_MfgToZoho_CompanyContact_WorkAroundForImmediateSync
	DROP TABLE IF EXISTS #tmpproc_set_MfgToZoho_CompanyContact_WorkAroundForImmediateSync1

	SELECT VisionSUPID INTO #tmpproc_set_MfgToZoho_CompanyContact_WorkAroundForImmediateSync 
	FROM zoho..zoho_user_accounts (NOLOCK)

	SELECT a.company_id , a.contact_id , ROW_NUMBER() OVER(ORDER BY a.contact_id) AS Rn   
	INTO #tmpproc_set_MfgToZoho_CompanyContact_WorkAroundForImmediateSync1
	FROM mp_contacts (NOLOCK) a 
	LEFT JOIN #tmpproc_set_MfgToZoho_CompanyContact_WorkAroundForImmediateSync b ON CONVERT(VARCHAR(100),a.contact_id) = b.VisionSUPID
	WHERE b.VisionSUPID IS NULL
	AND a.company_id IS NOT NULL
	AND CONVERT(DATE,a.created_on) > CONVERT(DATE,DATEADD(DAY,-30,GETUTCDATE()))  
	
	DECLARE	@Counter INT = 1
	DECLARE	@Counter1 INT = (SELECT COUNT(1)FROM #tmpproc_set_MfgToZoho_CompanyContact_WorkAroundForImmediateSync1)
	WHILE @Counter <=@Counter1
	BEGIN
		
		SELECT 
			@CompId = company_id 
			,@ContId = contact_id 
		FROM #tmpproc_set_MfgToZoho_CompanyContact_WorkAroundForImmediateSync1 WHERE Rn = @Counter

		PRINT  'Company Id: ' + CAST(@CompId AS VARCHAR(100)) +'           Contact Id: '+    CAST(@ContId AS VARCHAR(100))

		EXEC [proc_mfgzoho_set_userprofile_sync_up] @CompanyID=@CompId , @ContactID =@ContId

		SET @Counter= @Counter+ 1
	END


END

