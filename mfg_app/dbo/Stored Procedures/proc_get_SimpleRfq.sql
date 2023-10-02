
-- =============================================
-- Author:		Mahendra Kadam
-- Create date: 30/03/2021
-- Description:	M2-3719 M - Add Simple RFQs under RFQs- DB
-- =============================================


-- EXEC  [proc_get_SimpleRfq] @ContactId = 1337812, @PageNumber = 1, @PageSize = 20

CREATE PROCEDURE [dbo].[proc_get_SimpleRfq]
  @ContactId INT,
  @PageNumber INT,
  @PageSize   INT
AS
BEGIN
  SET NOCOUNT ON;
  SELECT *,  COUNT(1) OVER () TotalCount
  FROM 
  (
		SELECT 
			m.message_id
			--, COALESCE((con.first_name + ' ' + con.last_name) , (le.first_name + ' ' + le.last_name) ,'') AS Name
			,IIF(ISNULL((con.first_name + ' ' + con.last_name),'') <> '' , con.first_name + ' ' + con.last_name, IIF(ISNULL((le.first_name + ' ' + le.last_name),'')<>'',(le.first_name + ' ' + le.last_name),(RFQ.firstname + ' ' + RFQ.lastname))) AS Name
			, comp.company_id As CompanyId
			, COALESCE(comp.name , le.company , '') AS CompanyName
			, m.message_subject
			, m.message_descr
			, m.message_date
			, lm.lead_id
			, m.from_cont
			, m.message_read  
		FROM mp_messages m
		LEFT JOIN  mp_contacts con (nolock) ON con.contact_id = m.from_cont
		LEFT JOIN  mp_companies comp (nolock) ON con.company_id = comp.company_id
		LEFT JOIN  mp_lead_message_mapping lm (nolock) ON lm.message_id = m.message_id
		LEFT JOIN  mp_lead_email_mappings lem (nolock) ON lm.lead_id = lem.lead_id
		LEFT JOIN mpCommunityDirectRfqs RFQ(NOLOCK) ON RFQ.leadid = lem.lead_id

		LEFT JOIN  mp_lead_emails le (nolock) ON lem.lead_email_message_id = le.lead_email_message_id
		WHERE to_cont= @ContactId AND trash = 0 AND message_type_id = 230
    ) a
	ORDER BY a.message_date DESC
	OFFSET      @PageSize * (@PageNumber - 1) ROWS
    FETCH NEXT  @PageSize ROWS ONLY;
END
