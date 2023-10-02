
/*
declare @tbl_email_notification_sentflag tbl_email_notification_sentflag
insert into @tbl_email_notification_sentflag values(1)

exec proc_set_email_notification_sent_flag @tbl_email_notification_sentflag 


select * from mp_email_messages a
*/

CREATE procedure [dbo].[proc_set_email_notification_sent_flag]
(
@tbl_email_notification_sentflag tbl_email_notification_sentflag READONLY
)
as
begin
	declare @record_count int = 0

	begin try
		
		update a set a.message_sent = 1 , email_message_descr = null
		from mp_email_messages a
		join @tbl_email_notification_sentflag b on a.email_message_id = b.email_message_id
		set @record_count = @@rowcount

		if @record_count = (select count(*) from @tbl_email_notification_sentflag )
			select 'SUCCESS' processStatus
		else
			select 'FAILURE'  processStatus
	end try
	begin catch
		select 'FAILURE: '+ error_message()  processStatus
	end catch


end