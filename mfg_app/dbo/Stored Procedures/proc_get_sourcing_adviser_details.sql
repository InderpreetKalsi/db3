
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[proc_get_sourcing_adviser_details]
	@supplier_id	INT
AS
BEGIN
	SET NOCOUNT ON

	SELECT
         (d.first_name +' '+ d.last_name) as SourcingAdviserName
        ,  d.title as SourcingAdviserDesignation
        , communication_value as SourcingAdviserPhone
        ,c.email
    FROM mp_contacts    (NOLOCK) a
    JOIN mp_companies     (NOLOCK) b ON a.company_id = b.company_id
    LEFT JOIN mp_contacts    (NOLOCK) d ON b.Assigned_SourcingAdvisor = d.contact_id
	JOIN aspnetusers    (NOLOCK) c ON c.id = d.user_id
    LEFT JOIN mp_communication_details (NOLOCK) e ON d.contact_id = e.contact_id
    WHERE a.contact_id = @supplier_id
END
