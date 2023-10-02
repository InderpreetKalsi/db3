

--  EXEC proc_get_company_account_type @companyid = 1769973
CREATE PROCEDURE  [dbo].[proc_get_company_account_type]
(
	@companyid INT =  NULL 
)
AS
BEGIN
	SET NOCOUNT ON
	
	/* List of companies with there account type */
		
	DECLARE @AccountType VARCHAR(50) = 'Basic'
	
	SET @AccountType = 
	(
		SELECT b.value  
		FROM mp_registered_supplier  a (NOLOCK)
		JOIN mp_system_parameters	b (NOLOCK) ON a.account_type = b.id
		WHERE a.company_id = @companyid
	)

	SELECT @companyid AS CompanyId  ,  ISNULL(@AccountType,'Basic') AS AccountType

END
