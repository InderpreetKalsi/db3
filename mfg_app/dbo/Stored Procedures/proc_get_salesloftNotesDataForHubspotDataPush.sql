
-- =============================================  
-- Author:  dp-AN  
-- Create date: 03/01/2022  
-- Description: Stored procedure to Get salesloft notes data for hubspot data push
-- Modification:  
-- Example: [proc_get_salesloftNotesDataForHubspotDataPush]  
-- =================================================================  
--Version No – Change Date – Modified By      – CR No – Note  
-- =================================================================  
  
CREATE PROCEDURE [dbo].[proc_get_salesloftNotesDataForHubspotDataPush]  
   
AS  
BEGIN      
  
 SELECT  top(20) 
	a.associated_with_id AS AssociatedWithId,	  
	a.user_id AS UserId,	  
	a.content AS Content,
	b.email_address AS PeopleEmailAddress,
	c.email AS UsersEmailAddress,
	a.created_at AS CreatedAt,
	a.updated_at AS UpdatedAt,
	a.salesloft_notes_id AS SalesloftNotesId,
	d.[HubSpot ContactId] AS PeopleEmailAddressHubSpotId
 FROM SalesloftNotes (NOLOCK)  a 
 join salesloftpeople (NOLOCK)  b on a.associated_with_id = b.id
 join SalesloftUsers(NOLOCK)  c on a.user_id = c.id
 join HubSpotContactsOneTimePull (NOLOCK)  d on b.email_address = d.email
 where a.is_processed is null    
   
END
