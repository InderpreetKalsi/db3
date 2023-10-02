

 

/*
 M2-4474 : Buyer and M - New T&C's acceptance modal - DB

 exec proc_get_users_TermAcceptances 'UATbuyer14@yopmail.com' ,1350682

*/
 
CREATE PROCEDURE [dbo].[proc_get_users_TermAcceptances]   
  (
	@Email nvarchar(255) 
	,@Contact_id int
  )
AS  
BEGIN  
   
  SET NOCOUNT ON

  -- M2-4474 Buyer and M - New T&C's acceptance modal - DB

  IF ((SELECT COUNT(1)  FROM mpNewTermAcceptances (NOLOCK)  WHERE email = @Email AND Contact_Id = @Contact_id ) > 0 )
  BEGIN
	  SELECT Is_Acceptances ,Contact_Id , Who_Accepted_Or_Declined,is_buyer
	  FROM mpNewTermAcceptances (NOLOCK)
	  WHERE email = @Email
	  and Contact_Id = @Contact_id
  END
  ELSE 
  BEGIN 
  
	SELECT CAST('true' AS BIT)  Is_Acceptances , 0 Contact_Id , CAST('true' AS BIT) Who_Accepted_Or_Declined, CAST('true' AS BIT) is_buyer
  
  END



END
