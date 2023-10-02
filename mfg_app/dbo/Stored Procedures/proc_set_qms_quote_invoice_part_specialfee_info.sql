/*
declare @p271 dbo.tbltype_QMSQuoteInvoicePartQTYWithFeeTypeValues

insert into  @p271 values(101,200.5864),(102,39.5864),(103,49.5864),(104,588.5864),(105,69.5864)
--select * from @p27
exec proc_set_qms_quote_invoice_part_info
	@QMSQuoteInvoiceId		=1
	,@QMSQuotePartId		=1
	,@QTYLevel				=1
	,@PartQTY				= 11
	,@UnitId				= 14
	,@FeeTypeValues			= @p271


*/

CREATE proc [dbo].[proc_set_qms_quote_invoice_part_specialfee_info]
(
	@QMSQuoteInvoiceId		int
	,@QMSQuotePartId		int
	,@FeeTypeValues			as tbltype_QMSQuoteInvoicePartQTYWithFeeTypeValues			readonly
)
as
begin

	/* Dec 12 M2-2421 M - Invoice tab - Update Other Quantity selection -DB */

	declare @TransactionStatus				varchar(500) = 'Failed'
	declare @qms_quote_invoice_part_id		int
	
	drop table if exists #qms_quote_invoice

	begin tran
	begin try
	
		
		select 
			@QMSQuoteInvoiceId	QMSQuoteInvoiceId 
			,@QMSQuotePartId	QMSQuotePartId
			, * 
			into #qms_quote_invoice
		from @FeeTypeValues

		set @qms_quote_invoice_part_id = (select qms_quote_invoice_part_id from mp_qms_quote_invoice_parts where  qms_quote_invoice_id =  @QMSQuoteInvoiceId and qms_quote_part_id = @QMSQuotePartId)

		merge mp_qms_quote_invoice_part_special_fees as target  
		using (select distinct @qms_quote_invoice_part_id qms_quote_invoice_part_id ,*  from #qms_quote_invoice)  as source on  
		(target.qms_quote_invoice_part_id = source.qms_quote_invoice_part_id and target.fee_type_id = source.FeeTypeId  )  
		when matched and (target.value  <> source.value) then  
			update set target.value  = source.value
		when not matched then  
			insert (qms_quote_invoice_part_id ,fee_type_id ,value)  
			values (source.qms_quote_invoice_part_id ,source.FeeTypeId ,source.value )
		;

		 

		commit

		set @TransactionStatus = 'Success'
		select @TransactionStatus TransactionStatus 

	end try
	begin catch
		rollback

		set @TransactionStatus = 'Failed - ' + error_message()
		select @TransactionStatus TransactionStatus 

	end catch


end
