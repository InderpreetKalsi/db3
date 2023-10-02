-- exec proc_set_qms_additional_lead_time 1768028
------------------------------------------------------------------------------------------------------
CREATE procedure [dbo].[proc_set_qms_additional_lead_time]
(
	@supplier_company_id	int,
	@lead_time			varchar(150)
)
as
begin
	/*
		Oct 21, 2019 - M2-2184 M - Add Quote Details items to the site preferences : DB
	*/
		
	declare @transaction_status					varchar(500) = 'Failed'
	declare	@qms_lead_time_id		int

	begin tran
	begin try

		insert into mp_mst_qms_additional_lead_time
		(supplier_company_id ,lead_time )
		select @supplier_company_id , @lead_time 
		set @qms_lead_time_id = @@identity

		commit

		set @transaction_status = 'Success'
		select @transaction_status TransactionStatus , @qms_lead_time_id as QMSLeadTimeId

	end try
	begin catch
		rollback

		set @transaction_status = 'Failed - ' + error_message()
		select @transaction_status TransactionStatus , 0 QMSLeadTimeId 

	end catch


end
