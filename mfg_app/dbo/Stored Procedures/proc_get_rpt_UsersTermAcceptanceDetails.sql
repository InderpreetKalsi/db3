/*
 This SP data used in xls document for user review who Who_Accepted_Or_Declined terms and condition
 */
 -- EXEC [proc_get_rpt_UsersTermAcceptanceDetails]
 CREATE PROCEDURE [dbo].[proc_get_rpt_UsersTermAcceptanceDetails]
 AS
 SET NOCOUNT ON
 BEGIN

	SET NOCOUNT ON

	SELECT DISTINCT
		   c.name[Company Name]
		 , b.Email [Email]
		 , FORMAT (b.Modify_On, 'd','us')  [Accepeted or Declined Date] 
		 , CASE WHEN Is_Acceptances = 1 THEN 'Accepted'
			   WHEN  Is_Acceptances = 0 THEN 'Declined'
			   ELSE 'No Response'
			   END AS [Terms Condition Status]
		 , CASE WHEN Who_Accepted_Or_Declined = 1 THEN 'Buyer'
			   WHEN  Who_Accepted_Or_Declined = 0 THEN 'Manufacturer'
			   END AS [Who_Accepted_Or_Declined]
	FROM mpNewTermAcceptances (NOLOCK)   b 
	JOIN AspNetUsers (NOLOCK) a  ON b.Email = a.Email
	JOIN mp_contacts (NOLOCK) d ON a.id = d.user_id and d.IsTestAccount= 0 
	JOIN mp_companies(NOLOCK) c on d.company_id = c.company_id
	WHERE Is_Acceptances IS NOT NULL
	ORDER BY [Email]

  END
