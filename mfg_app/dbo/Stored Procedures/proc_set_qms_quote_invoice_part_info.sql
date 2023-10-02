/*

declare @p27 dbo.tbltype_QMSQuoteInvoicePartQTYWithFeeTypeValues

insert into  @p27 values(101,100.5864),(102,29.5864),(103,39.5864),(104,44044488.5864),(105,59.5864)
--select * from @p27
exec proc_set_qms_quote_invoice_part_info
	@QMSQuoteInvoiceId		=1
	,@QMSQuotePartId		=1
	,@QTYLevel				=0
	,@PartQTY				= 11
	,@UnitId				= 14
	,@FeeTypeValues			= @p27
*/

CREATE proc [dbo].[proc_set_qms_quote_invoice_part_info]
(
	@QMSQuoteInvoiceId		int
	,@QMSQuotePartId		int
	,@QTYLevel				smallint
	,@PartQTY				numeric(18, 0) =  null
	,@UnitId				int =  null
	,@IsPartOfInvoice		bit
	,@FeeTypeValues			as tbltype_QMSQuoteInvoicePartQTYWithFeeTypeValues			readonly
)
as
begin

	/* Dec 12 M2-2421 M - Invoice tab - Update Other Quantity selection -DB */

	declare @TransactionStatus				varchar(500) = 'Failed'
	declare @qms_quote_invoice_part_id		int
	declare @qms_quote_invoice_part_qty_id	int
	
	drop table if exists #qms_quote_invoice

	begin tran
	begin try
	
		--select  * from mp_qms_quote_invoices 
		--delete from mp_qms_quote_invoice_part_qty_fee_types where qms_quote_invoice_part_qty_id in 
		--(
		--	select qms_quote_invoice_part_qty_id from 
		--	mp_qms_quote_invoice_part_quantities (nolock) a
		--	join mp_qms_quote_invoice_parts (nolock) b on a.qms_quote_invoice_part_id = b.qms_quote_invoice_part_id
		--	--join mp_qms_quote_invoices		(nolock) c on b.qms_quote_invoice_id = c.qms_quote_invoice_id
		--	where b.qms_quote_invoice_id  =  @QMSQuoteInvoiceId
		--)
		--delete from mp_qms_quote_invoice_part_quantities where qms_quote_invoice_part_qty_id in 
		--(
		--	select a.qms_quote_invoice_part_qty_id from 
		--	mp_qms_quote_invoice_part_quantities (nolock) a
		--	join mp_qms_quote_invoice_parts (nolock) b on a.qms_quote_invoice_part_id = b.qms_quote_invoice_part_id
		--	--join mp_qms_quote_invoices		(nolock) c on b.qms_quote_invoice_id = c.qms_quote_invoice_id
		--	where b.qms_quote_invoice_id  =  @QMSQuoteInvoiceId
		--)

		--delete from mp_qms_quote_invoice_parts where qms_quote_invoice_id  =  @QMSQuoteInvoiceId
		
		
		
		select 
			@QMSQuoteInvoiceId	QMSQuoteInvoiceId 
			,@QMSQuotePartId	QMSQuotePartId
			,@QTYLevel			QTYLevel
			,@PartQTY			PartQTY
			,@UnitId			UnitId
			,@IsPartOfInvoice	IsPartOfInvoice
			, * 
			into #qms_quote_invoice
		from @FeeTypeValues



		merge mp_qms_quote_invoice_parts as target  
		 using (select distinct QMSQuoteInvoiceId ,QMSQuotePartId , IsPartOfInvoice  from #qms_quote_invoice) as source on  
		  (target.qms_quote_invoice_id = source.QMSQuoteInvoiceId and target.qms_quote_part_id = source.QMSQuotePartId  )  
		 when not matched by target then  
		  insert (qms_quote_invoice_id,qms_quote_part_id,IsPartOfInvoice)   
		  values (source.QMSQuoteInvoiceId,source.QMSQuotePartId, source.IsPartOfInvoice)
		 --when not matched by source then  
		 --delete
		 ;
		 set @qms_quote_invoice_part_id = SCOPE_IDENTITY()
	 
		 if (@qms_quote_invoice_part_id is null)
		 begin
			set @qms_quote_invoice_part_id =
			(
				select qms_quote_invoice_part_id
				from mp_qms_quote_invoice_parts
				where 
				qms_quote_invoice_id = @QMSQuoteInvoiceId
				and qms_quote_part_id = @QMSQuotePartId
			)
		 end
	 
		 if (@qms_quote_invoice_part_id>0)
		 begin

			--select distinct @qms_quote_invoice_part_id qms_quote_invoice_part_id ,	QTYLevel ,PartQTY,UnitId  from #qms_quote_invoice
		
			merge mp_qms_quote_invoice_part_quantities as target  
			using (select distinct @qms_quote_invoice_part_id qms_quote_invoice_part_id ,	QTYLevel ,PartQTY,UnitId  from #qms_quote_invoice)  as source on  
			(target.qms_quote_invoice_part_id = source.qms_quote_invoice_part_id and target.part_qty = source.PartQTY  and target.part_qty_unit_id = source.UnitId  and target.qty_level = source.QTYLevel )  
			when not matched by target then  
				insert (qms_quote_invoice_part_id ,part_qty ,part_qty_unit_id ,qty_level)  
				values (source.qms_quote_invoice_part_id ,source.PartQTY ,source.UnitId ,source.QTYLevel)
			--when not matched by source then  
			-- delete
			;
			set @qms_quote_invoice_part_qty_id = SCOPE_IDENTITY()
		
			if (@qms_quote_invoice_part_qty_id is null)
			begin
				set @qms_quote_invoice_part_qty_id =
				(
					select qms_quote_invoice_part_id
					from mp_qms_quote_invoice_part_quantities
					where 
					qms_quote_invoice_part_id = @qms_quote_invoice_part_id
					and qty_level = @QTYLevel
				)
			end
		

			if (@qms_quote_invoice_part_qty_id>0)
			begin
	
				merge mp_qms_quote_invoice_part_qty_fee_types as target  
				using (select distinct @qms_quote_invoice_part_qty_id qms_quote_invoice_part_qty_id ,*  from #qms_quote_invoice)  as source on  
				(target.qms_quote_invoice_part_qty_id = source.qms_quote_invoice_part_qty_id and target.fee_type_id = source.FeeTypeId  )  
				when matched and (target.value  <> source.value) then  
					update set target.value  = source.value
				when not matched then  
					insert (qms_quote_invoice_part_qty_id ,fee_type_id ,value)  
					values (source.qms_quote_invoice_part_qty_id ,source.FeeTypeId ,source.value )
				;

			end


		 end 


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
