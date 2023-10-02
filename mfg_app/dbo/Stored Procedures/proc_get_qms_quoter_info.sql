-- =============================================
-- Author:		Suraj Choudhari
-- Create date: 28 Jan 2020
-- Description:	SP to get the QMS quoter list
--	Exec proc_get_qms_quoter_info 1347070
-- =============================================
CREATE PROCEDURE [dbo].[proc_get_qms_quoter_info] 
	-- Add the parameters for the stored procedure here
	@SupplierCompanyID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET NOCOUNT ON;

    -- Select statements for procedure here
	SELECT [contact_id] AS QuoterContactId
		  ,[company_id] AS QuoterCompanyId
		  ,[first_name]+' '+last_name AS QuoterName
	 
	  FROM [dbo].[mp_contacts](NOLOCK) WHERE
	  [company_id] = @SupplierCompanyID
	  AND is_active = 1
END
