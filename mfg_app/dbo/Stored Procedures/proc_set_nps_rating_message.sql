

CREATE procedure [dbo].[proc_set_nps_rating_message]
(
	@rfq_id int 
)
as
begin

	declare @processStatus as varchar(max) = 'SUCCESS'
	declare @rfq_contact_id as bigint = 0
	declare @rfq_name as nvarchar(500) = ''
	declare @email_msg_subject as nvarchar(250) = ''
	declare @email_msg_body as nvarchar(max) = ''
	declare @msg_subject as nvarchar(250) = ''
	declare @msg_body as nvarchar(max) = ''
	declare @todays_date as datetime = getdate() 
	declare @from_username as nvarchar(100) = ''
	declare @from_user_contactimage as nvarchar(500) = ''
	declare @from_user_email varchar(200) = ''
	declare @company_id as bigint
	declare @company as nvarchar(200) = ''
	declare @supplier_company as nvarchar(200) = ''
	declare @identity bigint = 0
	declare @identity_msg bigint = 0
	declare @message_link varchar(10) = ''
	declare @notification_email_running_id  table (id int identity(1,1) ,  email_message_id int null)
	declare @notification_message_running_id  table (id int identity(1,1) ,  message_id int null)
	
	drop table if exists #list_of_to_contacts_for_messages_notification
	drop table if exists #tmp_notification
	drop table if exists #to_contacts
	
	create table #tmp_notification (id int null , email_message_id varchar(50), message_id  varchar(50))
	
	-- rfq info
	select @rfq_name = rfq_name , @rfq_contact_id = contact_id from mp_rfq a (nolock)	where rfq_id =  @rfq_id 

	-- awarded supplier info
	select distinct 
		b.contact_id
	into #to_contacts
	from mp_rfq a (nolock)
	join mp_rfq_quote_SupplierQuote b (nolock) on a.rfq_id = b.rfq_id  and  is_rfq_resubmitted = 0
	join mp_rfq_quote_items c(nolock) on b.rfq_quote_SupplierQuote_id = c.rfq_quote_SupplierQuote_id
	where is_awrded =1 and a.rfq_id = @rfq_id
	
	-- rfq contact info
	select 
		@from_username = b.first_name + ' ' + b.last_name
		, @from_user_contactimage = c.file_name
		, @from_user_email = d.email
		, @company_id = b.company_id
	from mp_contacts b  (nolock) 
	left join mp_special_files c  (nolock) on b.contact_id = c.cont_id and filetype_id = 17
	left join aspnetusers d  (nolock) on b.user_id = d.id
	where b.contact_id =  @rfq_contact_id

	-- to contact info
	select a.company_id, a.contact_id ,   b.email as  email_id, a.first_name + ' ' + a.last_name as username
	,a.is_notify_by_email  /* M2-4789*/
	into #list_of_to_contacts_for_messages_notification
	from mp_contacts a (nolock) 
	left join aspnetusers b  (nolock) on a.user_id = b.id
	where a.contact_id in (select * from #to_contacts)
	
	-- getting company name
	select @company = name from mp_companies  (nolock) where company_id = @company_id
	select @supplier_company = name from mp_companies 	 (nolock) where company_id in  (select distinct company_id from #list_of_to_contacts_for_messages_notification)


	insert into mp_messages
	( rfq_id, message_type_id, message_subject, message_descr, message_date,from_cont ,to_cont, message_sent,message_read ,trash, from_trash, real_from_cont_id, is_last_message , message_status_id_recipient , message_status_id_author)
	output inserted.message_id into @notification_message_running_id
	select 
			@rfq_id rfq_id
			, case 
				when  message_type_name = 'BUYER_NPS_RATING' then b.message_type_id						
				when  message_type_name = 'SUPPLIER_NPS_RATING' then b.message_type_id						
				end  as  message_type_id 
			, message_subject_template  message_subject 
					
			, case 
				when  message_type_name = 'SUPPLIER_NPS_RATING' then
					replace(replace(message_body_template, '#Buyer_Name#', @from_username) , '#Manufacturer_company_name#' ,@supplier_company) 
				when  message_type_name = 'BUYER_NPS_RATING' then
				replace(replace(message_body_template, '#Manufacturer_Contact_name#', username)  , '#Company_Name#',@company)
				end  as message_descr
			, @todays_date as message_date
			, case 
				when  message_type_name = 'SUPPLIER_NPS_RATING' then 		a.contact_id				
				when  message_type_name = 'BUYER_NPS_RATING' then @rfq_contact_id   					
				end as from_contact_id 
			, case 
				when  message_type_name = 'SUPPLIER_NPS_RATING' then 	 @rfq_contact_id			
				when  message_type_name = 'BUYER_NPS_RATING' then  		 a.contact_id	
				end as to_contact_id 
			, 0 as message_sent
			, 0 as message_read
			, 0 as trash
			, 0 as from_trash
			, 0 as real_from_cont_id
			, 0 as is_last_message
			, 0 as message_status_id_recipient
			, 0 as message_status_id_author
	from #list_of_to_contacts_for_messages_notification			a
	cross apply
	(
		select 
			a.message_type_id
			,a.message_type_name 
			,message_subject_template
			,message_body_template
			,email_body_template
			,email_subject_template 
		from 
		mp_mst_message_types  a
		join mp_mst_email_template b on a.message_type_id = b.message_type_id
		where a.message_type_name in ('SUPPLIER_NPS_RATING', 'BUYER_NPS_RATING')
	) b 
	set @identity_msg = @@identity

	insert into mp_email_messages
	( rfq_id, message_type_id, email_message_subject, email_message_descr, email_message_date
	,from_cont ,to_cont, to_email, message_sent,message_read )
	output inserted.email_message_id into @notification_email_running_id
	select 
		@rfq_id rfq_id
		,  case 
				when  message_type_name = 'BUYER_NPS_RATING' then b.message_type_id						
				when  message_type_name = 'SUPPLIER_NPS_RATING' then b.message_type_id						
				end  message_type_id 
		, email_subject_template  email_msg_subject
		, case 
				when  message_type_name = 'SUPPLIER_NPS_RATING' then
					replace(replace(replace(email_body_template, '#Buyer_Name#', @from_username) , '#Manufacturer_company_name#' ,@supplier_company) ,'#Message_Link#',@message_link)
				when  message_type_name = 'BUYER_NPS_RATING' then
				replace(replace(replace(email_body_template, '#Manufacturer_Contact_name#', username)  , '#Company_Name#',@company),'#Message_Link#',@message_link)
				end   email_msg_body 
		, @todays_date as email_message_date
		, case 
				when  message_type_name = 'SUPPLIER_NPS_RATING' then 		a.contact_id				
				when  message_type_name = 'BUYER_NPS_RATING' then @rfq_contact_id   					
				end as from_contact_id 
		,  case 
				when  message_type_name = 'SUPPLIER_NPS_RATING' then 	 		@rfq_contact_id			
				when  message_type_name = 'BUYER_NPS_RATING' then  		 a.contact_id	
				end as to_contact_id 
		, case when  message_type_name = 'SUPPLIER_NPS_RATING' then  @from_user_email else email_id end as to_email_id
		, 0 as message_sent
		, 0 as message_read
	from #list_of_to_contacts_for_messages_notification			a
	cross apply
	(
		select 
			a.message_type_id
			,a.message_type_name 
			,message_subject_template
			,message_body_template
			,email_body_template
			,email_subject_template 
		from 
		mp_mst_message_types  a
		join mp_mst_email_template b on a.message_type_id = b.message_type_id
		where a.message_type_name in ('SUPPLIER_NPS_RATING', 'BUYER_NPS_RATING')
	) b
	WHERE a.is_notify_by_email = 1  /* M2-4789*/ 

	set @identity = @@identity
				
	if @identity> 0 
	begin
		set @processStatus = 'SUCCESS'

		insert into #tmp_notification (id, message_id)
		select * from @notification_message_running_id

		update a set a.email_message_id = b.email_message_id
		from #tmp_notification a
		join @notification_email_running_id b on a.id = b.id
						

		select a.processStatus	,b.email_message_id ,b.message_id	,rfq_id	,message_type_id, message_subject	,message_body	,email_message_subject
				,email_msg_body		,email_message_date	,rfq_contact_id	,from_username ,from_user_contactimage	,to_contact_id	,to_username
				,to_email_id		,message_sent 		,message_type
		from 
		(
			select
				row_number() over (order by b.contact_id )  id
				, @processStatus processStatus 
				, @identity email_message_id , @identity_msg message_id
				, @rfq_id rfq_id
				, case 
					when  message_type_name = 'BUYER_NPS_RATING' then b1.message_type_id						
					when  message_type_name = 'SUPPLIER_NPS_RATING' then b1.message_type_id						
					end message_type_id
				, message_subject_template as message_subject
				, case 
					when  message_type_name = 'SUPPLIER_NPS_RATING' then
						replace(replace(message_body_template, '#Buyer_Name#', @from_username) , '#Manufacturer_company_name#' ,@supplier_company) 
					when  message_type_name = 'BUYER_NPS_RATING' then
					replace(replace(message_body_template, '#Manufacturer_Contact_name#', username)  , '#Company_Name#',@company)
					end as message_body
				, email_subject_template  email_message_subject
				, case 
					when  message_type_name = 'SUPPLIER_NPS_RATING' then
						replace(replace(replace(email_body_template, '#Buyer_Name#', @from_username) , '#Manufacturer_company_name#' ,@supplier_company) ,'#Message_Link#',@message_link)
					when  message_type_name = 'BUYER_NPS_RATING' then
						replace(replace(replace(email_body_template, '#Manufacturer_Contact_name#', username)  , '#Company_Name#',@company),'#Message_Link#',@message_link)
					end email_msg_body
				, @todays_date email_message_date
				, case 
					when  message_type_name = 'SUPPLIER_NPS_RATING' then 		b.contact_id				
					when  message_type_name = 'BUYER_NPS_RATING' then @rfq_contact_id   					
					end  rfq_contact_id
				, case 
					when  message_type_name = 'SUPPLIER_NPS_RATING' then 		b.username				
					when  message_type_name = 'BUYER_NPS_RATING' then @from_username   					
					end  as from_username
				,  case 
					when  message_type_name = 'SUPPLIER_NPS_RATING' then 		''				
					when  message_type_name = 'BUYER_NPS_RATING' then @from_user_contactimage   					
					end   from_user_contactimage
				, case 
					when  message_type_name = 'SUPPLIER_NPS_RATING' then 		@rfq_contact_id				
					when  message_type_name = 'BUYER_NPS_RATING' then b.contact_id  					
					end  as to_contact_id
				, case 
					when  message_type_name = 'SUPPLIER_NPS_RATING' then 		@from_username				
					when  message_type_name = 'BUYER_NPS_RATING' then b.username					
					end	 as to_username
				,  case 
					when  message_type_name = 'SUPPLIER_NPS_RATING' then 		@from_user_email			
					when  message_type_name = 'BUYER_NPS_RATING' then b.email_id					
					end	   as to_email_id
				, 0 as message_sent
				, case 
					when  message_type_name = 'BUYER_NPS_RATING' then 'BUYER_NPS_RATING'						
					when  message_type_name = 'SUPPLIER_NPS_RATING' then 'SUPPLIER_NPS_RATING'					
					end message_type
			from #list_of_to_contacts_for_messages_notification			b
			cross apply
			(
				select 
					a.message_type_id
					,a.message_type_name 
					,message_subject_template
					,message_body_template
					,email_body_template
					,email_subject_template 
				from 
				mp_mst_message_types  a
				join mp_mst_email_template b on a.message_type_id = b.message_type_id
				where a.message_type_name in ('SUPPLIER_NPS_RATING', 'BUYER_NPS_RATING')
			) b1 
		) a
		join #tmp_notification b on a.id = b.id
			
	end
	else
	begin
		set @processStatus = 'FAILUER'

		select 
			'FAILUER: No data for email notification!'  processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
			, '' as email_message_date, '' as rfq_contact_id, '' as from_username
			, '' as from_user_contactimage, '' as to_contact_id, '' as to_username
			, '' as to_email_id, 0 as message_sent
			, '' as message_subject , '' as message_body
			, '' email_message_id , '' message_id
			, ''  message_type
	end


end

