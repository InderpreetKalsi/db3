------------------------------------------------------------------------------------------------------
CREATE procedure proc_set_qms_dynamic_fee_types
(
	@supplier_company_id	int,
	@fee_types				varchar(150),
	@is_default				bit
)
as
begin
	/*
		Oct 21, 2019 - M2-2184 M - Add Quote Details items to the site preferences : DB
	*/
		
	declare @transaction_status			varchar(500) = 'Failed'
	declare	@qms_dynamic_fee_type_id	int

	begin tran
	begin try

		insert into mp_mst_qms_dynamic_fee_types
		(supplier_company_id ,fee_type ,is_default)
		select @supplier_company_id , @fee_types ,@is_default
		set @qms_dynamic_fee_type_id = @@identity

		commit

		set @transaction_status = 'Success'
		select @transaction_status TransactionStatus , @qms_dynamic_fee_type_id as QMSDynamicFeeTypeId

	end try
	begin catch
		rollback

		set @transaction_status = 'Failed - ' + error_message()
		select @transaction_status TransactionStatus , 0 QMSDynamicFeeTypeId 

	end catch


end
