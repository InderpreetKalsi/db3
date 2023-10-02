
-- =============================================	
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
--EXEC proc_get_my_company_rfq_supplier_list 1799026
CREATE PROCEDURE [dbo].[proc_get_my_company_rfq_supplier_list]
	@CompanyId int 
AS
BEGIN
	SET NOCOUNT ON;

   SELECT contact_id AS SupplierContactId,
		  company_id AS SupplierCompanyId,
		  first_name AS SupplierFirstName,
		  last_name AS SupplierLastName,
		  is_buyer AS IsBuyer,
		  is_admin AS IsAdmin
   FROM mp_contacts 
   WHERE company_id = @CompanyId 
		AND is_buyer = 0 
		AND is_active = 1
  ORDER BY contact_id

END
