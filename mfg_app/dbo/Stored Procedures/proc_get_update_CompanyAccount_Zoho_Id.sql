
-- =============================================
-- Author:		<Allwin Lewis>
-- Create date: <16 Apr 2020>
-- Description:	<Stored Procedure for Fetching the Company/Account Zoho ID from first in MFG Db then in the Zoho DB.>
-- =============================================
CREATE PROCEDURE [dbo].[proc_get_update_CompanyAccount_Zoho_Id]
	-- Add the parameters for the stored procedure here
	@CompanyId INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @Company_Zoho_Id varchar(200)

	----Extract Company Zoho ID from the MFG DB
	SELECT @Company_Zoho_Id = [company_zoho_id] from [dbo].[mp_companies] comp where comp.company_id = @CompanyId

	IF (LTRIM(RTRIM(ISNULL(@Company_Zoho_Id,''))) = '' or LTRIM(RTRIM(@Company_Zoho_Id)) = '0')
		BEGIN	

		----Extract Company Zoho ID from the Zoho DB
		SELECT @Company_Zoho_Id = zca.Zoho_id from [dbo].[mp_companies] comp 
		LEFT JOIN Zoho..[zoho_company_account] zca
		on comp.[company_id] = zca.VisionACCTID
		
		where comp.company_id = @CompanyId and zca.SyncType = 1

		----Update the Extracted Company Zoho ID from the Zoho DB into the MFG DB.
		Update mp_companies SET  [company_zoho_id] = @Company_Zoho_Id where company_id  = @CompanyId;

		END



	Select @Company_Zoho_Id -- return back the Extracted Company/Account Zoho ID.


	
END
