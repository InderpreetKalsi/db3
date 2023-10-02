

/*

exec proc_get_supplier_saved_search_filters

*/

CREATE procedure [dbo].[proc_get_supplier_saved_search_filters]
as
begin

	/* Dec 26,2019 M2-2496 RFQ Email Template Change - DB */

	
	set nocount on
	
	
	/* M2-2818 Saved Search optimization - DB */
	TRUNCATE TABLE [tmp_trans].[saved_search_supplier_with_filters]
	TRUNCATE TABLE [tmp_trans].[saved_search_exclude_suppliers_to_whom_email_already_sent]
	/**/

	truncate table mp_saved_search_exclude_rfqs

	/* M2-2598  Update RFQ saved search email logic to prioritize higher rated RFQs - DB */

	INSERT INTO [tmp_trans].[saved_search_exclude_suppliers_to_whom_email_already_sent] (contact_id)
	select distinct from_cont as contact_id 
	from mp_email_messages (nolock) 
	where message_type_id = 216 and convert(date,email_message_date) = convert(date,getutcdate())

	insert into [tmp_trans].[saved_search_supplier_with_filters] (contact_id,saved_search_id)
	select 
		distinct  a.contact_id , saved_search_id 
	from 		
	mp_saved_search			(nolock) a 
	join mp_contacts 		(nolock) b on a.contact_id = b.contact_id 
		/* M2-3251  Vision - Flag as a test account and hide the data from reporting - DB*/
		and isnull(b.IsTestAccount,0) = 0
		/**/
	left join mp_scheduled_job	(nolock) c on b.contact_id = c.contact_id and c.scheduler_type_id = 9 
	where 
		c.is_deleted=0
		and is_daily_notification = 1 
		and not exists (select contact_id from [tmp_trans].[saved_search_exclude_suppliers_to_whom_email_already_sent] where a.contact_id = contact_id)
		and 
		a.search_filter_name = 'My Capabilities' 
		and not exists   (select distinct company_id from  mp_registered_supplier (nolock)  where b.company_id = company_id)
		and 
		exists  		
		(
			select distinct a1.contact_id
			from mp_contacts				(nolock) a1
			left join mp_company_processes	(nolock) b1 on a1.company_id = b1.company_id
			where 
				year(a1.created_on) >2015
				and a1.is_buyer = 0
				and b1.company_id is null
				and a1.is_notify_by_email = 1
				and a.contact_id = a1.contact_id
		)

				
	insert into [tmp_trans].[saved_search_supplier_with_filters] (contact_id,saved_search_id)
	select 
		distinct a.contact_id , a.saved_search_id 
	from 		
	mp_saved_search					(nolock) a 
	join mp_contacts 				(nolock) b on a.contact_id = b.contact_id
		/* M2-3251  Vision - Flag as a test account and hide the data from reporting - DB*/
		and isnull(b.IsTestAccount,0) = 0
		/**/
	left join mp_scheduled_job		(nolock) c on b.contact_id = c.contact_id and c.scheduler_type_id = 9 
	left join mp_saved_search_processes	(nolock) d on a.saved_search_id = d.saved_search_id 
	where 
		not exists  (select distinct contact_id from [tmp_trans].[saved_search_supplier_with_filters] (nolock) where a.contact_id = contact_id)
		and not exists (select contact_id from [tmp_trans].[saved_search_exclude_suppliers_to_whom_email_already_sent] (nolock)  where a.contact_id = contact_id)
		and year(b.created_on) >2015 
		and is_notify_by_email = 1 
		and c.is_deleted=0
		and is_daily_notification = 1 
		and b.is_active = 1
		and (a.status_id = 2 or a.status_id is null)
		and not exists   (select distinct company_id from  mp_registered_supplier (nolock) where b.company_id = company_id)
		and 
		(
			d.part_category_id in 
			(
				select distinct  part_category_id from mp_saved_search_comp_processes (nolock)  a
				where 
				company_id = b.company_id
			)
			or a.part_category_id = ''
		)

		
	insert into [tmp_trans].[saved_search_supplier_with_filters] (contact_id,saved_search_id)
	select 
		distinct  a.contact_id , saved_search_id  
	from 		
	mp_saved_search	(nolock) a 
	join mp_contacts 		(nolock) b on a.contact_id = b.contact_id
		/* M2-3251  Vision - Flag as a test account and hide the data from reporting - DB*/
		and isnull(b.IsTestAccount,0) = 0
		/**/
	left join mp_scheduled_job	(nolock) c on b.contact_id = c.contact_id and c.scheduler_type_id = 9 
	join mp_registered_supplier (nolock) d on b.company_id = d.company_id and is_registered =1
	where 
		is_notify_by_email = 1 
		and c.is_deleted=0
		and is_daily_notification = 1 
		and (a.status_id = 2 or a.status_id is null)
		and not exists (select contact_id from [tmp_trans].[saved_search_exclude_suppliers_to_whom_email_already_sent] where a.contact_id = contact_id)

	select distinct * from [tmp_trans].[saved_search_supplier_with_filters] (nolock)
	order by  contact_id desc, saved_search_id  desc


	TRUNCATE TABLE [tmp_trans].[saved_search_supplier_with_filters]
	TRUNCATE TABLE [tmp_trans].[saved_search_exclude_suppliers_to_whom_email_already_sent]

end
