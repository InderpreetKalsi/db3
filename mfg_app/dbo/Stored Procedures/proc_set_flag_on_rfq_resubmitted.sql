
CREATE procedure [dbo].[proc_set_flag_on_rfq_resubmitted]
(@rfq_id int)
as
begin
	/* M2-928 RFQ has changed and your quotes are not valid */
	
	begin try
		update mp_rfq_quote_supplierquote set is_rfq_resubmitted = 1 where rfq_id = @rfq_id

		update mp_rfq_quote_suplierstatuses set rfq_userStatus_id =  1 , modification_date = getutcdate() where rfq_id = @rfq_id and rfq_userStatus_id <> 1

		delete from mp_rfq_supplier_read where rfq_id = @rfq_id

		select 'Success' status
	end try
	begin catch
		select 'Faliure: ' + error_message() as  status
	end catch
end
