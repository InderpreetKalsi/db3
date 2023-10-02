
CREATE PROCEDURE [dbo].[proc_set_TransferRFQ]
	-- Add the parameters for the stored procedure here
	@rfq_id INT,
	@from_contactid INT,
	@to_contactid INT

	
AS
BEGIN

	declare @rc_count int
	declare @status varchar(250) = ''
	declare @identity_msg int  = 0 
	declare @mdate datetime = getdate()

	set @from_contactid =  (select contact_id from mp_rfq  where  rfq_id = @rfq_id)

	update mp_rfq set  contact_id = @to_contactid   where  rfq_id = @rfq_id

	insert into mp_messages
	(
		rfq_id,message_type_id,message_subject,message_descr,message_date,message_read,message_sent
		,message_status_id_recipient,message_status_id_author,from_trash,real_from_cont_id,is_last_message 
		, from_cont ,to_cont ,trash
	)
	select @rfq_id , 31 , 'RFQ Transfer'  ,  'RFQ #' +convert(varchar(50),@rfq_id) + ' has been transferred to you!'  , @mdate , 0 , 0  ,0,0,0,0,0,@from_contactid , @to_contactid , 0
	set @identity_msg = @@identity

	if @identity_msg > 0 
	begin

		select 
			'Success' processStatus, a.rfq_id rfq_id, '31'  message_type_id, '' email_msg_subject, '' email_msg_body 
			, a.message_date as email_message_date, a.from_cont as from_contact_id, b.first_name +' ' + b.last_name as from_username
			, c.file_name as from_user_contactimage, to_cont as to_contact_id, d.first_name +' ' + d.last_name as to_username
			, e.email as to_email_id, 0 as message_sent
			, message_subject as message_subject , message_descr as message_body
			, '' email_message_id , a.message_id message_id
			, 'RFQ_TRANSFERT'  message_type 
		
		from mp_messages (nolock) a 
		join mp_contacts b (nolock) on a.from_cont = b.contact_id
		left join mp_special_files c (nolock)  on b.contact_id = c.cont_id and filetype_id = 17
		join mp_contacts d (nolock) on a.to_cont = d.contact_id
		join aspnetusers (nolock)  e on d.user_id = e.id
		where a.rfq_id = @rfq_id and a.message_type_id = 31 and message_date = @mdate
		
		
	end
	else
	begin

			select 
			'Failure : user already marked it for quoting or quoted it!'  processStatus, '' rfq_id, ''  message_type_id, '' email_msg_subject, '' email_msg_body 
			, '' as email_message_date, '' as from_contact_id, '' as from_username
			, '' as from_user_contactimage, '' as to_contact_id, '' as to_username
			, '' as to_email_id, 0 as message_sent
			, '' as message_subject , '' as message_body
			, '' email_message_id , '' message_id
			, ''  message_type


	end

	---Create entry to Revision history table
	BEGIN
		DECLARE @newRFQVersionId int=0
				, @RFQVersion int=0
				, @FromBuyerName nvarchar(100)=''
				, @ToBuyerName nvarchar(100)=''
			
				---Create version history for RFQ changes
				select @RFQVersion = count(1)+1 from mp_rfq_versions where RFQ_ID = @rfq_id 

				INSERT INTO mp_rfq_versions(contact_id, major_number, minor_number, version_number, creation_date, RFQ_ID)
				VALUES(@from_contactid, @RFQVersion,0,convert(varchar(5), @RFQVersion) + '.0', getdate(),@rfq_id)
				set @newRFQVersionId = @@IDENTITY 
				
				---Creating revision history

				select @FromBuyerName = concat(first_name, ' ',last_name) 
				from mp_contacts where contact_id = @from_contactid

				select @ToBuyerName = concat(first_name, ' ',last_name) 
				from mp_contacts where contact_id = @to_contactid

				INSERT INTO mp_rfq_revision(rfq_id, field, oldvalue, newvalue, creation_date, rfq_version_id)
				SELECT distinct @rfq_id, 'RFQ Transfer', isnull(@FromBuyerName,''), isnull(@ToBuyerName,''), getdate(), @newRFQVersionId 
	END
	
END
