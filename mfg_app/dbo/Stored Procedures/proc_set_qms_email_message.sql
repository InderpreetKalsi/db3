/*

	exec proc_set_qms_email_message 
	@supplier_id			= 1337894
	,@supplier_company_id	= 1768056
	,@qms_quote_id			= 33
	,@email_subject			= 'test subject'
	,@email_body			= 'test body'
	,@qms_pdf_file_name		= 'testfile1'
	,@is_email_to_customer	= 1

*/

CREATE procedure [dbo].[proc_set_qms_email_message]
(
	@supplier_id			int
	,@supplier_company_id	int
	,@qms_quote_id			int
	,@email_subject			nvarchar(500)
	,@email_body			nvarchar(max)
	,@qms_pdf_file_name		nvarchar(500)
	,@is_email_to_customer	bit
)
as
begin
	/*
		Oct 17, 2019 - M2-2200 M - Quotes Details page - Messages tab : DB
	*/
	declare @transaction_status					varchar(500) = 'Failed'
	declare	@qms_customer_id					int
	declare	@qms_customer_email					varchar(250)
	declare @qms_email_message_id				int
	declare @qms_pdf_file_id					int
	declare @qms_terms_condition_file_id		int = 0
	declare @supplier_email_id					varchar(250)

	select 
		@qms_customer_id	= b.qms_contact_id
		,@qms_customer_email = b.email
	from
	mp_qms_quotes			(nolock) a
	join mp_qms_contacts	(nolock) b on a.qms_contact_id = b.qms_contact_id
	where qms_quote_id = @qms_quote_id	
	
	select 
		@qms_terms_condition_file_id = file_id 
	from mp_special_files 
	where cont_id = @supplier_id and comp_id = @supplier_company_id
	and filetype_id = 109 and is_deleted = 0
	
	if @is_email_to_customer = 0
		set @supplier_email_id = (select top 1  b.email 	from mp_contacts a (nolock) join aspnetusers b (nolock) on a.user_id = b.id	where a.contact_id = @supplier_id )

	begin tran
	begin try

		insert into mp_special_files
		(file_name ,cont_id ,comp_id ,is_deleted ,filetype_id, creation_date )
		select @qms_pdf_file_name , @supplier_id , @supplier_company_id , 0 , 110 , getutcdate()
		set @qms_pdf_file_id = @@identity

		insert into	mp_qms_email_messages
		(qms_quote_id,email_subject,email_body,email_date,from_cont,to_cont,to_email)
		select @qms_quote_id , @email_subject , @email_body , getutcdate() , @supplier_id , case when @is_email_to_customer = 0 then @supplier_id else @qms_customer_id end , case when @is_email_to_customer = 0 then @supplier_email_id else @qms_customer_email end  
		set @qms_email_message_id = @@identity

		insert into mp_qms_email_messages_files
		(qms_email_message_id,file_id)
		select * from
		(
		select @qms_email_message_id qms_email_message_id  , @qms_terms_condition_file_id qms_file_id
		union 
		select @qms_email_message_id qms_email_message_id  , @qms_pdf_file_id qms_pdf_file_id
		) a 
		where qms_file_id <> 0

		commit

		set @transaction_status = 'Success'
		select @transaction_status TransactionStatus , @qms_email_message_id as QMSEmailMessageId

	end try
	begin catch
		rollback

		set @transaction_status = 'Failed - ' + error_message()
		select @transaction_status TransactionStatus , 0 QMSEmailMessageId 

	end catch


end
