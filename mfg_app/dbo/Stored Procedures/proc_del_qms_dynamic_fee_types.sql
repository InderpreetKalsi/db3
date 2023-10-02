
------------------------------------------------------------------------------------------------------
CREATE procedure proc_del_qms_dynamic_fee_types
(
	@supplier_company_id		int,
	@qms_dynamic_fee_type_id	int
)
as
begin
	/*
		Oct 21, 2019 - M2-2184 M - Add Quote Details items to the site preferences : DB
	*/
		
	declare @transaction_status		varchar(500) = 'Failed'

	begin tran
	begin try

		delete from mp_mst_qms_dynamic_fee_types where qms_dynamic_fee_type_id = @qms_dynamic_fee_type_id and supplier_company_id = @supplier_company_id
		
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
