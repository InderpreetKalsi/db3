

/*
exec proc_set_magic_leads
*/

CREATE procedure [dbo].[proc_set_magic_leads]
as
begin
	-- M2-1913 M - Magic Lead List page 
	-- Apr 06,2020 - M2-2739 Stripe - Capabilities selection for gold & platinum subscription - DB

	drop table if exists #tmp_company_processes
	drop table if exists #tmp_validated_buyer_rfqs_last_60_days
	drop table if exists #tmp_magic_list
	drop table if exists #tmp_followed_and_viewed_buyer_companies

	-- update existing leads and set expired flag to true
	update mp_magic_leads  set is_expired =  1 where is_expired = 0

	-- fetch gold and premium suppliers processess 
	select distinct a.company_id supplier_company_id, b.part_category_id , account_type
	into #tmp_company_processes
	from mp_registered_supplier (nolock) a
	join 
	(
		select company_id,part_category_id from  mp_company_processes a	(nolock)
		/* M2-2739 */
		union
		select company_id,part_category_id from  mp_gateway_subscription_company_processes a (nolock) 
		/**/
	) b on a.company_id = b.company_id
	join mp_companies (nolock) c on a.company_id = c.company_id and c.manufacturing_location_id in (4,5,7)
	where account_type in (84,85,86) -- M2-4619
	and b.part_category_id in (select part_category_id from mp_active_capabilities (nolock)  )
	--and a.company_id = 1769973

	-- fetch list of validated buyer who posted rfq's in last 60 days
	/* M2-2692 M - Adjust Magic Lead List rules - DB */
		/* Mar 02, 2020 Ewesterfield-MFG : if it was possible to expand the Magic lead list for wood working category to 1 year? */
		select distinct a.rfq_id,  d.company_id buyer_company_id, c.part_category_id , 1 is_wood_work
		into  #tmp_validated_buyer_rfqs_last_60_days
		from mp_rfq			(nolock) a
		join mp_rfq_parts	(nolock) b on a.rfq_id =b.rfq_id
		join mp_parts		(nolock) c on b.part_id = c.part_id
		join mp_contacts	(nolock) d on a.contact_id = d.contact_id and d.is_validated_buyer = 1
		join mp_companies	(nolock) e on d.company_id = e.company_id and e.manufacturing_location_id in (4,5,7)
		where b.part_category_id in 
		(
			select distinct part_category_id 
			from #tmp_company_processes 
			where part_category_id in (7469 ,7761,7759,7760,7763,7764,7765)
		)
		
		and convert(date,a.rfq_created_on) >= convert(date,getutcdate()-365)
		
		and a.rfq_status_id in  (3,5,6)
		/*M2-2250 Vision - Magic Lead List On/Off button in buyer info drawer - DB */
			and e.is_magic_lead_enable = 1
		/**/
		union
		/**/
		select distinct a.rfq_id,  d.company_id buyer_company_id, c.part_category_id , 0 is_wood_work
		from mp_rfq			(nolock) a
		join mp_rfq_parts	(nolock) b on a.rfq_id =b.rfq_id
		join mp_parts		(nolock) c on b.part_id = c.part_id
		join mp_contacts	(nolock) d on a.contact_id = d.contact_id and d.is_validated_buyer = 1
		join mp_companies	(nolock) e on d.company_id = e.company_id and e.manufacturing_location_id in (4,5,7)
		where b.part_category_id in 
		(
			select distinct part_category_id 
			from #tmp_company_processes 
			where part_category_id not in (7469 ,7761,7759,7760,7763,7764,7765)
		)
		/* M2-3071 M - Change Magic Lead List time to 12 months - DB*/
		and convert(date,a.rfq_created_on) >= convert(date,getutcdate()-365)
		/**/
		and a.rfq_status_id in  (3,5,6)
		/*M2-2250 Vision - Magic Lead List On/Off button in buyer info drawer - DB */
			and e.is_magic_lead_enable = 1
		/**/
	/**/

	-- fetch list of buyer which were followed and viewed  by supplier 
	select distinct mc.company_id supplier_company_id , mbd.company_id as followed_and_viewed_buyer_company_id
	into #tmp_followed_and_viewed_buyer_companies
	from mp_book_details	mbd		(nolock)
	join mp_books			mb		(nolock)	on mbd.book_id =mb.book_id
	join mp_mst_book_type	mmbt	(nolock)	on mmbt.book_type_id = mb.bk_type
	and mmbt.book_type ='BOOK_BOOKTYPE_HOTLIST'
	join mp_contacts		mc		(nolock)	on mb.contact_id = mc.contact_id and mc.is_buyer = 0
	union 
	select distinct  mc.company_id supplier_company_id  , a.CompanyID_Profile as viewed_buyer_company_id
	from mp_viewedprofile	(nolock) a
	join mp_contacts		(nolock) mc	on a.contactid = mc.contact_id and mc.is_buyer = 0
	
	-- fetch list of magic lead for supplier by excluding followed & viewed buyers and the buyers already included in the magic leads
	/* M2-2692 M - Adjust Magic Lead List rules - DB */
	select account_type , supplier_company_id , buyer_company_id , row_number() over (partition by a.supplier_company_id ,is_wood_work order by a.supplier_company_id ,is_wood_work , a.buyer_company_id ) rn ,is_wood_work
	into #tmp_magic_list
	from
	(
	select distinct 
		a.account_type
		, a.supplier_company_id 
		, b.buyer_company_id 
		, c.buyer_company_id as magic_list_buyer_company_id
		, d.followed_and_viewed_buyer_company_id
		, is_wood_work
	from #tmp_company_processes a
	join #tmp_validated_buyer_rfqs_last_60_days b on a.part_category_id = b.part_category_id
	left join mp_magic_leads (nolock) c on a.supplier_company_id = c.supplier_company_id and b.buyer_company_id = c.buyer_company_id and is_expired = 1
	left join #tmp_followed_and_viewed_buyer_companies d on a.supplier_company_id = d.supplier_company_id and b.buyer_company_id = d.followed_and_viewed_buyer_company_id
	where b.buyer_company_id is not null 
	and c.buyer_company_id is null
	and d.followed_and_viewed_buyer_company_id is null
	and b.buyer_company_id not in (569469 ,1732008)
	) a 
	where account_type = 85
	union
	select account_type , supplier_company_id , buyer_company_id , row_number() over (partition by a.supplier_company_id ,is_wood_work order by a.supplier_company_id ,is_wood_work , a.buyer_company_id ) rn ,is_wood_work
	from
	(
	select distinct 
		a.account_type
		, a.supplier_company_id 
		, b.buyer_company_id 
		, c.buyer_company_id as magic_list_buyer_company_id
		, d.followed_and_viewed_buyer_company_id
		, is_wood_work
	from #tmp_company_processes a
	join #tmp_validated_buyer_rfqs_last_60_days b on a.part_category_id = b.part_category_id
	left join mp_magic_leads (nolock) c on a.supplier_company_id = c.supplier_company_id and b.buyer_company_id = c.buyer_company_id and is_expired = 1
	left join #tmp_followed_and_viewed_buyer_companies d on a.supplier_company_id = d.supplier_company_id and b.buyer_company_id = d.followed_and_viewed_buyer_company_id
	where b.buyer_company_id is not null 
	and c.buyer_company_id is null
	and d.followed_and_viewed_buyer_company_id is null
	and b.buyer_company_id not in (569469 ,1732008)
	) a 
	where account_type = 86
	/* M2-4619 */
	union
	select account_type , supplier_company_id , buyer_company_id , row_number() over (partition by a.supplier_company_id ,is_wood_work order by a.supplier_company_id ,is_wood_work , a.buyer_company_id ) rn ,is_wood_work
	from
	(
	select distinct 
		a.account_type
		, a.supplier_company_id 
		, b.buyer_company_id 
		, c.buyer_company_id as magic_list_buyer_company_id
		, d.followed_and_viewed_buyer_company_id
		, is_wood_work
	from #tmp_company_processes a
	join #tmp_validated_buyer_rfqs_last_60_days b on a.part_category_id = b.part_category_id
	left join mp_magic_leads (nolock) c on a.supplier_company_id = c.supplier_company_id and b.buyer_company_id = c.buyer_company_id and is_expired = 1
	left join #tmp_followed_and_viewed_buyer_companies d on a.supplier_company_id = d.supplier_company_id and b.buyer_company_id = d.followed_and_viewed_buyer_company_id
	where b.buyer_company_id is not null 
	and c.buyer_company_id is null
	and d.followed_and_viewed_buyer_company_id is null
	and b.buyer_company_id not in (569469 ,1732008)
	) a 
	where account_type = 84
	/**/
	/**/

	
	/* M2-2692 M - Adjust Magic Lead List rules - DB */
	insert into mp_magic_leads
	(supplier_company_id,buyer_company_id , account_type )
	select supplier_company_id, buyer_company_id , account_type from #tmp_magic_list where account_type = 85 and is_wood_work = 0 and rn <= 5
	union 
	select supplier_company_id, buyer_company_id, account_type  from #tmp_magic_list where account_type = 85 and is_wood_work = 1 and rn <= 5
	union 
	select supplier_company_id, buyer_company_id, account_type  from #tmp_magic_list where account_type = 86 and is_wood_work = 0 and rn <= 7
	union 
	select supplier_company_id, buyer_company_id, account_type  from #tmp_magic_list where account_type = 86 and is_wood_work = 1 and rn <= 7 
	union 
	select supplier_company_id, buyer_company_id, account_type  from #tmp_magic_list where account_type = 84 and is_wood_work = 0 and rn <= 2
	

		/* M2-3071 M - Change Magic Lead List time to 12 months - DB*/	
		--insert into mp_messages
		--( message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
		--select distinct
		--	221  message_type_id 
		--	, 'Congrats! You have '+case when account_type =  85 then '5' when account_type =  86 then '7' end + ' new Magic Leads waiting for you. Click here to view them.'  as message_subject 
		--	, 'Congrats! You have '+case when account_type =  85 then '5' when account_type =  86 then '7' end + ' new Magic Leads waiting for you. Click here to view them.'  as message_descr
		--	, getutcdate() as message_date
		--	/* M2-2264 M - Messages Tab : Magic lead list messages should be listed only under 'All' tab -API */
		--	, 1348071 from_contact_id  -- Bill Artley as suggested by Soel (Aug 06 2020)
		--	/**/
		--	, b.contact_id as to_contact_id 
		--	, 0 as message_sent
		--	, 0 as message_read
		--	, 0 as trash
		--	, 0 as from_trash
		--	, 0 as real_from_cont_id
		--	, 0 as is_last_message
		--	, 0 as message_status_id_recipient
		--	, 0 as message_status_id_author
		--from mp_magic_leads (nolock) a
		--join mp_contacts	(nolock) b on a.supplier_company_id = b.company_id and is_buyer = 0 
		--where is_expired = 0 and  convert(date,lead_date)  = convert(date,getutcdate())
		/**/
	/**/
end
