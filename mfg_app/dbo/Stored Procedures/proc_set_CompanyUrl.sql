
/*

EXEC proc_set_CompanyUrl @NewCompanyName = 'EASYTURN' , @CompanyId =1800437 

SELECT company_id , name , companyurl FROM mp_companies WHERE company_id  = 1800437
SELECT visionacctid, account_name, companyurl , issync , isprocessed FROM zoho..zoho_company_account WHERE visionacctid = 1800437

*/
CREATE PROCEDURE proc_set_CompanyUrl
(
	@NewCompanyName	NVARCHAR(500)
	,@CompanyId	INT
)
AS
BEGIN
	-- M2-3693 M - Need to change the 'Public Profile' URL while changing the Company Name from Manufacturer profile - ZOHO DB


	DECLARE @CompanyNewURL NVARCHAR(500) = ''


	SET @CompanyNewURL = 
	LOWER
	(
		REPLACE
		(
			REPLACE
			(
				REPLACE
				(
					dbo.removespecialchars(@NewCompanyName)
					,' ','_'
				)
				,'__','_'
			)
			,'___','_'
		)
	) +'_'+CONVERT(VARCHAR(100),@CompanyId)


	
	UPDATE mp_companies SET companyurl = @CompanyNewURL WHERE company_id = @CompanyId

END
