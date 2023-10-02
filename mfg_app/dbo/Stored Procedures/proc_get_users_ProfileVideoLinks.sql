
 
CREATE PROCEDURE [dbo].[proc_get_users_ProfileVideoLinks]   
  (
	@Company_id int
  )
AS  
BEGIN  
   
  SET NOCOUNT ON

  -- M2-4549 M - Add the ability to add large videos to the profile - DB

  IF (
       (SELECT COUNT(1)  FROM mpUserProfileVideoLinks (NOLOCK)  WHERE CompanyId = @Company_id 
		   AND IsDeleted = 0 
            AND ISNULL(IsLinkVisionAccepted,1) = 1  
		) > 0 
	  )
  BEGIN
	  SELECT 
		Id
		,ContactId
		,Title
		,VideoLink
		,[Description]
		,IsDeleted
		,IsLinkVisionAccepted
		,CreatedOn
		,ModifiedOn
		,ModifiedBy
	  FROM mpUserProfileVideoLinks (NOLOCK)
	  WHERE CompanyId = @Company_id
	  AND IsDeleted = 0
	  AND ISNULL(IsLinkVisionAccepted,1) = 1
	  
  END
 

END
