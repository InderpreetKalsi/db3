
CREATE PROCEDURE proc_get_basic_manufacturer_dashboard

	@CompanyId INT

AS
BEGIN
	
	select top 10* from mp_companies 

END
