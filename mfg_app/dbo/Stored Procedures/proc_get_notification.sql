CREATE procedure proc_get_notification
(
@processStatus				varchar(20)		= null,
@rfq_id						int				= null,
@message_type				varchar(50)		= null,
@message_type_id			int				= null,
@msg_date					datetime, 
@from_contact_id			int				= null,
@from_username				varchar(50)		= null,
@from_user_contactimage		varchar(200)	= null,
@PageSize					int				= 1,
@PageNumber					int				= 1000
)
as
begin
		
		drop table if exists tmp_get_message_notification
		drop table if exists #tmp_email_notification
		drop table if exists #tmp_messages_notification

		select 
			row_number() over (order by to_cont) as rn , to_cont ,to_email,email_message_subject,email_message_descr , email_message_id 
		into #tmp_email_notification
		from mp_email_messages (nolock) where rfq_id = @rfq_id and message_type_id = @message_type_id	and email_message_date = @msg_date 

		select 
			row_number() over (order by to_cont) as rn ,to_cont ,null to_email,message_subject,message_descr ,message_id
		into #tmp_messages_notification
		from mp_messages (nolock) where rfq_id = @rfq_id and message_type_id = @message_type_id	and message_date = @msg_date 
				
		select 
			@processStatus as processStatus
			, @rfq_id  as rfq_id
			, @message_type as message_type
			, @message_type_id as message_type_id
			, a.email_message_id as email_message_id
			, b.message_id as message_id 
			, a.email_message_subject as email_msg_subject
			, a.email_message_descr as email_msg_body
			, b.message_subject as message_subject
			, b.message_descr as message_body
			, @msg_date as email_message_date
			, @from_contact_id as from_contact_id
			, @from_username as from_username
			, @from_user_contactimage as from_user_contactimage
			, a.to_cont as to_contact_id
			, c.first_name +' '+ c.last_name to_username
			, a.to_email as to_email_id
			, 0 as message_sent
		from #tmp_email_notification a
		join #tmp_messages_notification b on a.rn = b.rn
		join mp_contacts (nolock) c on a.to_cont = c.contact_id
		order by a.to_cont
		OFFSET @PageSize * (@PageNumber - 1) ROWS
		FETCH NEXT @PageSize ROWS ONLY; 
end
