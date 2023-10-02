------------------------------------------------------------------------------------------------------
CREATE procedure proc_set_qms_additional_shipping_methods
(
	@supplier_company_id	int,
	@shipping_methods		varchar(150)
)
as
begin
	/*
		Oct 21, 2019 - M2-2184 M - Add Quote Details items to the site preferences : DB
	*/
		
	declare @transaction_status			varchar(500) = 'Failed'
	declare	@qms_shipping_method_id		int

	begin tran
	begin try

		insert into mp_mst_qms_additional_shipping_methods
		(supplier_company_id ,shipping_methods)
		select @supplier_company_id , @shipping_methods 
		set @qms_shipping_method_id = @@identity

		commit

		set @transaction_status = 'Success'
		select @transaction_status TransactionStatus , @qms_shipping_method_id as QMSShippingMethodId

	end try
	begin catch
		rollback

		set @transaction_status = 'Failed - ' + error_message()
		select @transaction_status TransactionStatus , 0 QMSShippingMethodId 

	end catch


end
