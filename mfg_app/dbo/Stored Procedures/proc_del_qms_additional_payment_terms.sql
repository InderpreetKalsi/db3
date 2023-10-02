------------------------------------------------------------------------------------------------------
CREATE procedure proc_del_qms_additional_payment_terms
(
	@supplier_company_id			int,
	@qms_additional_payment_term_id int
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

		delete from mp_mst_qms_additional_payment_terms where qms_additional_payment_term_id = @qms_additional_payment_term_id and supplier_company_id = @supplier_company_id
		
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
