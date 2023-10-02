
-- exec [proc_get_IpAddressCount] @IpAddress = null
CREATE PROCEDURE [dbo].[proc_get_IpAddressCount] 
 (
 @IpAddress        VARCHAR(100) = NULL
 )
AS
 BEGIN
 
/* M2-4028    :    User registration - Block IP address & Implement Recaptcha */

	DECLARE @LoginDateCount INT
	DECLARE @Day INT

	SET NOCOUNT ON

	SELECT    
        @LoginDateCount = COUNT(DISTINCT LogDate)
        , @Day = COUNT(DISTINCT GETUTCDATE())
	FROM    mpUserRegistrationCaptureIpAddressLogs    (NOLOCK)
	WHERE    IpAddress = @IpAddress
	AND        CAST(LogDate AS DATE) = CAST(GETUTCDATE() as date)

	IF @Day = 1 AND @LoginDateCount<=10
		SELECT 'Registartion Succeded' As 'ResponseMsg'
	ELSE
		SELECT 'Registartion Failed' As 'ResponseMsg'
END
