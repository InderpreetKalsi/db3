

/*

M2-4945 HubSpot - Integrate Reshape User Registration API -DB
	With this SP will get data as per following condition
		1.Eddie updated delaPlex team regrading the ticket ‘M2-4862 HubSpot - Integrate Reshape User Registration API’, 
		that we need to call the Reshape's "supplier.create" API multiple times if a company has multiple contacts under it in the MFG DB.
		2. if from hubspot free/basic account change to Growth, Gold, Platinum then such information providing with this SP.
		3. this sp return always Top 1 record so once API record process record then API update IsProcessed = 1 and IsSynced = 1

EXEC proc_get_ReshapeUserRegistrationDetails

*/
CREATE PROCEDURE [dbo].[proc_get_ReshapeUserRegistrationDetails]
AS
BEGIN
 SET NOCOUNT ON

		DECLARE @CompanyId INT

		SELECT TOP 1  @CompanyId =  a.CompanyId
	 	FROM mpAccountPaidStatusDetails(NOLOCK) a 
		WHERE a.IsProcessed IS NULL AND a.IsSynced = 0 
		AND a.OldValue IS NOT NULL AND a.NewValue IS NOT NULL 
		 
		IF @CompanyId IS NOT NULL
		BEGIN 
				SELECT a.ID
				, a.CompanyId
				, a.OldValue
				, a.NewValue
				, a.CompanyId AS  [Domain] 
				, b.name AS [Business]
				, c.contact_id AS [ContactId] 
				, c.first_name + ' ' + c.last_name AS [ContactName]
				, d.Email
				FROM mpAccountPaidStatusDetails(NOLOCK) a 
				JOIN mp_companies(NOLOCK) b on a.CompanyId = b.company_id
				JOIN mp_contacts(NOLOCK) c ON c.company_id = b.company_id 
				JOIN AspNetUsers (NOLOCK) d on d.id = c.user_id
				WHERE a.CompanyId = @CompanyId
				AND a.IsProcessed IS NULL 
				AND a.IsSynced = 0 
				AND a.OldValue IS NOT NULL 
				AND a.NewValue IS NOT NULL 
				  
		END
		

 

END
