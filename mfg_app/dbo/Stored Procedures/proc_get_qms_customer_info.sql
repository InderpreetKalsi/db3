-- =============================================
-- Author:		Kamlesh Ganar
-- Create date: 16 Aug 2019
-- Description:	SP to get the QMS customer details
--	Exec proc_get_qms_customer_info 1347070
-- =============================================
CREATE PROCEDURE proc_get_qms_customer_info 
	-- Add the parameters for the stored procedure here
	@SupplierID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT [qms_contact_id] AS QmsContactId
		  ,[supplier_id] AS SupplierId
		  ,[company] AS Company
		  ,[first_name] AS FirstName
		  ,[last_name] AS LastName
		  ,[email] AS Email
		  ,[phone] AS Phone
		  ,[address] AS [Address]
		  ,[city] AS City
		  ,[state_id] AS StateId
		  ,[country_id] AS CountryId
		  ,[zip_code] AS ZipCode
		  ,[is_active] AS IsActive
		  ,[created_date] AS CreatedDate
	  FROM [dbo].[mp_qms_contacts](NOLOCK) WHERE
	  supplier_id = @SupplierID
END
