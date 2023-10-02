
/*
 M2-4474 : Buyer and M - New T&C's acceptance modal - DB

 EXEC [dbo].[proc_set_users_TermAcceptances_flag]
  @Email = 'nsupplieruat1@yopmail.com'
  , @Is_Acceptances = 1
  , @Contact_Id = 1350506
  go

   EXEC [dbo].[proc_set_users_TermAcceptances_flag]
   @Email = 'tracyromo@rocketmail.com'
  , @Is_Acceptances = 1
  , @Contact_Id = 1042369
  go

*/
 

CREATE PROCEDURE [dbo].[proc_set_users_TermAcceptances_flag]
(
	@Email NVARCHAR(255)
	,@Contact_Id INT 
	,@Is_Acceptances BIT  ---- 1 for Accepted 0 for Declined
)
AS
BEGIN

	BEGIN TRY

	IF(@Email IS NOT NULL AND @Email !='')
	BEGIN
		DECLARE @transaction_status BIT = 0

	    DECLARE @Who_Accepted_Or_Declined BIT
	    SELECT @Who_Accepted_Or_Declined = is_buyer  FROM mp_contacts (NOLOCK) WHERE contact_id = @Contact_Id
	 
		
		UPDATE A 
		SET a.Is_Acceptances = @Is_Acceptances
		,Who_Accepted_Or_Declined  = @Who_Accepted_Or_Declined 
		,Modify_On = GETUTCDATE()
		FROM mpNewTermAcceptances a
		WHERE email = TRIM(@Email)

		----- Deactivate that user if Terms and Condition selected to Declined
		IF @Is_Acceptances = 0
		BEGIN
			UPDATE b
			SET b.is_active = 0 ---> for deactivate user login
			FROM aspnetusers(NOLOCK) a
            JOIN mp_contacts(NOLOCK) b on a.id = b.[user_id]
            WHERE a.email= TRIM(@Email)
		END

		SET @transaction_status = 1
	 END
	    SELECT case when @transaction_status = 1 then 'Success' else 'Failed'+ ' ' + error_message() end AS TransactionStatus 
		
	END TRY
	BEGIN CATCH
		SELECT 'FAILURE: '+ error_message()  TransactionStatus
	END CATCH


END
