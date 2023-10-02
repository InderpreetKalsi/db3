
/*



declare @p27 dbo.tbltype_ListOfRFQ
declare @p28 dbo.tbltype_ListOfContact

insert into @p27 values (1193838)
insert into @p28 values (NULL,1372776)

exec proc_set_rfq_message_association 
@message_id			= null
,@msg_subject		= 'Dec 15 2021 Subject 1001'
,@msg_description	= 'Message 1001'
,@from_contact		= 1372777
,@rfqids			= @p27	
,@contactids        = @p28	
,@MessageFileNames	= 'T1,T2'

select top 50 * from mp_messages (nolock) order by 1 desc


*/
CREATE procedure [dbo].[proc_set_rfq_message_association]
(
	@message_id				int = null
	,@msg_subject			nvarchar(2000) = null
	,@msg_description		nvarchar(max) = null
	,@from_contact			int	= null
	,@rfqids				as tbltype_ListOfRFQ			readonly
	,@contactids			as [tbltype_ListOfContact]			readonly
	,@MessageFileNames		varchar(max) = null

)
as
begin

	/*
		 =================================================================
		 Create date:  Nov 04,2019
		 Description: M2-2259 Buyer and M - Add a Move To button on the 
		 Messages action button to associate a message with an RFQ - DB
		 Modification:
		 =================================================================
	*/

	declare @transaction_status		varchar(500) = 'Failed'
	declare @to_contacts			as tbltype_ListOfContact
	
	declare @is_buyer				bit
	/* M2-3687 M - Need 'Attachment' functionality when Manufacturer creates a new message from the 'Global Message' tab - API */
	declare @notification_message_running_id  table (id int identity(1,1) ,  message_id int null)


	drop table if exists #proc_set_rfq_message_associationMessageFileTable
	/**/

	begin tran
	begin try
	
		-- if message id is not null then create copy of that message and associate with list of rfq passed
		if (@message_id is not null or @message_id <>0 ) and ((select count(1) from @rfqids ) > 0)
		begin
			
			insert into mp_messages 
			(rfq_id,message_type_id,message_hierarchy,message_subject,message_descr,message_date,from_cont,to_cont,message_sent,message_read,trash,from_trash
			,real_from_cont_id,is_last_message,message_status_id_recipient,message_status_id_author
			)
			select 
				RFQId
				, message_type_id
				, message_hierarchy
				, 'RFQ # ' + convert(varchar(150),RFQId) + ' - '+ message_subject   as message_subject
				, message_descr
				, getutcdate() message_date
				, from_cont
				, to_cont
				, 0 as message_sent
				, 0 as message_read
				, 0 as trash
				, 0 as from_trash
				, 0 as real_from_cont_id
				, 0 as is_last_message
				, 0 as message_status_id_recipient
				, 0 as message_status_id_author
			from mp_messages (nolock)
			cross join @rfqids
			where message_id = @message_id

		end
		-- if message id is null (create a new rfq - message association) then based on is_buyer flag , generating list of to_contacts 
		else if (@message_id is null or @message_id  =0 )
		begin
			
			set @is_buyer =  (select is_buyer from mp_contacts (nolock) where contact_id = @from_contact)

			-- if is_buyer =0 it means supplier sending message to buyer 
			if @is_buyer =0
			begin
				
				/* M2-4263 Associate to RFQ to be an optional field in message drawer for both Buyer and M - API */
				if ((select count(1) from @rfqids)>0)
					insert into @to_contacts(rfqid, contactid)
					select rfq_id, contact_id from mp_rfq (nolock) where rfq_id in (select rfqid from @rfqids)
				else
					insert into @to_contacts(rfqid, contactid)
					select NULL , contactid from @contactids
				/**/
			end
			-- if is_buyer =1 it means buyer sending message to suppliers , including RFQ's which are marked for quoting and quoted by supplier
			else if @is_buyer =1
			begin
				/* M2-4263 Associate to RFQ to be an optional field in message drawer for both Buyer and M - API */
					
					--insert into @to_contacts(rfqid, contactid)
					--select distinct rfq_id, contact_id from mp_rfq_quote_suplierStatuses (nolock) where rfq_id in (select rfqid from @rfqids) and  rfq_userStatus_id in (1, 2)
					--union
					--select rfq_id, contact_id from mp_rfq_quote_SupplierQuote (nolock) where rfq_id in (select rfqid from @rfqids) and is_quote_submitted = 1

					if ((select count(1) from @rfqids)>0)
						/* 
						M2-4213 API - Buyer - Add select an M to send a message to in the drawer
						M2-4216 DB - M - Add a drop down for Followed Buyer selection in the New message drawer	
						*/
						insert into @to_contacts(rfqid, contactid)
						select a.rfqid, b.contactid from @rfqids a cross join  @contactids b
						/**/
					else
						insert into @to_contacts(rfqid, contactid)
						select NULL , contactid from @contactids

					/**/
				/**/

			end


			insert into mp_messages 
			(
			rfq_id ,message_type_id ,message_hierarchy ,message_subject ,message_descr ,message_date ,from_cont 
			,to_cont ,message_sent ,message_read ,trash ,from_trash ,real_from_cont_id ,is_last_message ,message_status_id_recipient 
			,message_status_id_author
			)
			/* M2-3687 M - Need 'Attachment' functionality when Manufacturer creates a new message from the 'Global Message' tab - API */
			output inserted.message_id into @notification_message_running_id
			/**/
			select 
				a.rfqid as rfq_id
				, 5 as message_type_id
				, null as message_hierarchy
				/* M2-4263 Associate to RFQ to be an optional field in message drawer for both Buyer and M - API */
				, CASE WHEN a.rfqid IS NULL THEN @msg_subject ELSE 'RFQ # ' + convert(varchar(150),a.rfqid) + ' - '+ @msg_subject END as message_subject
				/**/
				, @msg_description as message_descr
				, getutcdate() as message_date
				, @from_contact from_cont
				, b.contactid
				, 0 as message_sent
				, 0 as message_read
				, 0 as trash
				, 0 as from_trash
				, 0 as real_from_cont_id
				, 0 as is_last_message
				, 0 as message_status_id_recipient
				, 0 as message_status_id_author
			from	@to_contacts b 
			left join	@rfqids a on a.rfqid = b.rfqid
			


			/* M2-3687 M - Need 'Attachment' functionality when Manufacturer creates a new message from the 'Global Message' tab - API */
			DECLARE @RowNo INT = 1 ,@IndivisualFileName varchar(max) ,@FileId int ; 
			SELECT ROW_NUMBER() OVER(ORDER BY value ASC) AS RowNo , value into #proc_set_rfq_message_associationMessageFileTable FROM 
			(
				select value from string_split(@MessageFileNames, ',')

			) AS MessageFileDetailList  				 


			While (@RowNo <= (SELECT COUNT(*) from #proc_set_rfq_message_associationMessageFileTable))
			BEGIN 
				SET  @IndivisualFileName = (SELECT value from #proc_set_rfq_message_associationMessageFileTable where RowNo = @RowNo);
	 
				INSERT INTO mp_special_files(FILE_NAME,CONT_ID,COMP_ID,IS_DELETED,FILETYPE_ID,CREATION_DATE,Imported_Location,parent_file_id
					,Legacy_file_id	,file_title	,file_caption,file_path	,s3_found_status,is_processed,sort_order)					 
				SELECT @IndivisualFileName,@from_contact,null,0,57,getdate(),null,null,null,null,null,null,null,0,null  
				set @FileId = @@identity
					
				INSERT INTO mp_message_file ( MESSAGE_ID, [FILE_ID])
				select message_id , @FileId from @notification_message_running_id

			SET @RowNo = @RowNo + 1;
			END		
			/**/



		end


		commit

		set @transaction_status = 'Success'
		select @transaction_status TransactionStatus 

	end try
	begin catch
		rollback

		set @transaction_status = 'Failed - ' + error_message()
		select @transaction_status TransactionStatus 

	end catch

end
