-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
--exec proc_get_upgrade_email_details 1337820
CREATE PROCEDURE [dbo].[proc_get_upgrade_email_details]
@contact_id int
AS
BEGIN
	set nocount on
	/*
		M2-2280 Upgrade Email - Update information - API 
	*/
	
	SELECT  isnull(mct.country_name, '') as Country,
			isnull(mr.REGION_NAME, '') as State,
			isnull(cm.name, '') as AccountName,
			isnull(u.Email, '') as Email, 
			isnull(cd.communication_value,'') as PhoneNumber	 
	FROM mp_contacts(nolock) c
			left join mp_companies(nolock) cm on(c.company_id = cm.company_id)
			left join AspNetUsers(nolock) u on(c.user_id = u.id)
			left join mp_addresses(nolock) a on(c.address_id = a.address_id)
			left join mp_mst_country(nolock) mct on(a.country_id = mct.country_id) 
			left join mp_mst_region(nolock) mr on(a.region_id = mr.region_id)
			left join mp_communication_details(nolock) cd on(c.contact_id = cd.contact_id and cd.communication_type_id = 1)
	WHERE c.contact_id = @contact_id
END
