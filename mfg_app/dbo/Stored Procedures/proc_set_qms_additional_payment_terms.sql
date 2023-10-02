
-- exec proc_get_qms_additional_payment_terms 1768028
------------------------------------------------------------------------------------------------------
CREATE procedure proc_set_qms_additional_payment_terms
(
	@supplier_company_id	int,
	@payment_terms			varchar(150)
)
as
begin
	/*
		Oct 21, 2019 - M2-2184 M - Add Quote Details items to the site preferences : DB
	*/
		
	declare @transaction_status					varchar(500) = 'Failed'
	declare	@qms_payment_term_id		int

	begin tran
	begin try

		insert into mp_mst_qms_additional_payment_terms
		(supplier_company_id ,payment_terms)
		select @supplier_company_id , @payment_terms 
		set @qms_payment_term_id = @@identity

		commit

		set @transaction_status = 'Success'
		select @transaction_status TransactionStatus , @qms_payment_term_id as QMSPaymentTermId

	end try
	begin catch
		rollback

		set @transaction_status = 'Failed - ' + error_message()
		select @transaction_status TransactionStatus , 0 QMSPaymentTermId 

	end catch


end
