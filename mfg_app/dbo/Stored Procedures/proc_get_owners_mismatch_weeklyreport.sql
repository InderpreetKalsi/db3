-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE proc_get_owners_mismatch_weeklyreport 

AS
BEGIN
	SELECT * FROM [dbo].[zoho_owners_mismatch_logs]
END
