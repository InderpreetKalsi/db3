
-- =============================================  
-- Author:  dp-AN  
-- Create date: 03/01/2022  
-- Description: Stored procedure to Get salesloft calls data for hubspot data push
-- Modification:  
-- Example: [proc_get_salesloftCallsDataForHubspotDataPush]  
-- =================================================================  
--Version No – Change Date – Modified By      – CR No – Note  
-- =================================================================  
  
CREATE PROCEDURE [dbo].[proc_get_salesloftCallsDataForHubspotDataPush]  
   
AS  
BEGIN      
  
 SELECT  top(10) 
	 a.[to] AS ToNumber,
	 'COMPLETED' AS Status,
	 a.duration AS Duration,
	 b.email_address AS PeopleEmailAddress,
	 c.email AS UsersEmailAddress,
	 a.created_at AS CreatedAt,
	 a.updated_at AS UpdatedAt,
	 a.salesloftcallsid as Salesloftcallsid,
	 a.disposition as Disposition,
	 d.[HubSpot ContactId] AS PeopleEmailAddressHubSpotId
 FROM SalesloftCalls (NOLOCK)  a 
 join salesloftpeople (NOLOCK)  b on a.called_person_id = b.id
 join SalesloftUsers(NOLOCK)  c on a.user_id = c.id
 join HubSpotContactsOneTimePull (NOLOCK)  d on b.email_address = d.email
 where a.is_processed is null
    
   
END
