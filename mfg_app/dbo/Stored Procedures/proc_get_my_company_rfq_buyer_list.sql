
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
--EXEC proc_get_my_company_rfq_buyer_list 1799026
CREATE PROCEDURE [dbo].[proc_get_my_company_rfq_buyer_list]
	@CompanyId int 
AS
BEGIN
	SET NOCOUNT ON;

   SELECT contact_id AS BuyerContactId,
		  company_id AS BuyerCompanyId,
		  first_name AS BuyerFirstName,
		  last_name AS BuyerLastName,
		  is_buyer AS IsBuyer,
		  is_admin AS IsAdmin
   FROM mp_contacts 
   WHERE company_id = @CompanyId 
		AND is_buyer = 1 
		AND is_active = 1
  ORDER BY contact_id

END
