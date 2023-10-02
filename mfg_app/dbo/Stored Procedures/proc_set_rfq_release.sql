
CREATE procedure [dbo].[proc_set_rfq_release]
(
	@rfq_id int
)
as
begin
	
	begin try

		declare @rows as int = 0
		declare @buyercontact_id as int =0
		drop table if exists #list_of_supplier_admin_contacts_for_rfq
		drop table if exists #companies_for_rfq


		-- individual or group of companies for rfq 
		select distinct b.company_id , 'group' as type 
		into #companies_for_rfq 
		from mp_rfq_supplier a
		join mp_book_details b on a.supplier_group_id = b.book_id
		where rfq_id = @rfq_id 
		union
		select distinct company_id , 'individual' as type from mp_rfq_supplier 
		where supplier_group_id is null and   rfq_id = @rfq_id
		
		if exists (select * from #companies_for_rfq)
		begin
			
			if 	(select top 1 company_id from #companies_for_rfq) = -1 
			begin
				update mp_rfq_quote_suplierstatuses  set rfq_userStatus_id = 2  where rfq_id = @rfq_id 
				
				set @rows =  @@rowcount;
			end
			else
			begin
				select @rfq_id rfq_id , a.company_id , a.contact_id 
				into #list_of_supplier_admin_contacts_for_rfq
				from mp_contacts a
				where a.company_id in (select company_id from #companies_for_rfq) and is_admin = 1 and is_buyer = 0 and is_active = 1

				merge mp_rfq_quote_suplierstatuses as target
				using #list_of_supplier_admin_contacts_for_rfq as source on (target.rfq_id = source.rfq_id and target.contact_id = source.contact_id) 
				when matched  then 
					update set target.rfq_userStatus_id = 2 , target.modification_date = getdate()
				when not matched by target then 
					insert (rfq_id,contact_id,rfq_userStatus_id,creation_date,is_legacy_data) 
					values (source.rfq_id, source.contact_id, 1, getdate(), 0)			; 
				set @rows =  @@rowcount;

				Select @buyercontact_id= contact_id from mp_rfq where rfq_id=@rfq_id;

				insert into mp_lead (company_id,lead_source_id,lead_from_contact,lead_date)
				select distinct company_id,7,@buyercontact_id,GETUTCDATE() from #list_of_supplier_admin_contacts_for_rfq 
								

			end
			UPDATE mp_messages SET trash = 1 where message_id  in (SELECT message_Id  from mp_messages where rfq_id  = @rfq_id and  message_type_id = 220)
			if @rows > 0
				begin
					
					select 'SUCCESS' as processStatus
				end		
			else 
				select 'FAILURE' as processStatus
			
		end
		else
			select 'FAILURE: Supplier not exist!' as processStatus
		
	end try
	begin catch

		select 'FAILURE: '+ error_message()  processStatus

	end catch

	
end
