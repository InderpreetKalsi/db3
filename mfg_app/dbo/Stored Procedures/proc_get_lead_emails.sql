
/*
	EXEC proc_get_lead_emails @lead_id = 43464
	EXEC proc_get_lead_emails @lead_id = 6
*/
CREATE PROCEDURE [dbo].[proc_get_lead_emails]
(
	@lead_id		INT
)
AS
BEGIN

	/*
		CREATE	:	MAR 11, 2020
		DESC	:	M2-2722 M - Make Read my message clickable on Leadstream - DB

	*/

	SET NOCOUNT ON

	SELECT 
		first_name  AS FirstName, last_name  AS LastName, company  AS Company,company_id  AS CompanyId, email  AS Email
		, phoneno  AS PhoneNo, email_subject  AS EmailSubject, email_message AS EmailMessage
	FROM 
	mp_lead								c (NOLOCK)
	LEFT JOIN mp_lead_email_mappings	b (NOLOCK) ON b.lead_id = c.lead_id
	LEFT JOIN mp_lead_emails			a (NOLOCK) ON a.lead_email_message_id = b.lead_email_message_id 
	WHERE c.lead_id =  @lead_id

END
