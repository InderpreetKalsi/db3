------------------------------------------------------------------------------------------------------
CREATE procedure [dbo].[proc_del_qms_additional_lead_time]
(
	@supplier_company_id			int,
	@qms_additional_lead_time_id int
)
as
begin
	/*
		Oct 21, 2019 - M2-2184 M - Add Quote Details items to the site preferences : DB
	*/
	-- testing 1
	declare @transaction_status					varchar(500) = 'Failed'
	declare	@qms_lead_time_id		int

	begin tran
	begin try

		delete from mp_mst_qms_additional_lead_time where qms_additional_lead_time_id = @qms_additional_lead_time_id and supplier_company_id = @supplier_company_id
		
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
