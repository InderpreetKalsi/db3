/*

declare @totalrec int

exec proc_get_qms_my_invoices
@SupplierId			= 1337793 
, @SearchText		= null   -- InvoiceNo -- QuoteReferenceNo
, @IsOrderByDesc	= 'false'
, @OrderBy			= 'total' -- null , 'Customer' , 'Status' 
, @Customer_id		= null
, @Status			= null
, @pageno			= 1
, @pagesize			= 20
, @total_rec		= @totalrec output

select @totalrec

*/
CREATE procedure [dbo].[proc_get_qms_my_invoices]
(
	@SupplierId			int	
	,@SearchText		varchar(150)	= null
	,@IsOrderByDesc		bit		='true'
	,@OrderBy			varchar(100)	= null -- 'Customer' , 'Status'
	,@Customer_id		int = null
	,@Status			varchar(100)	= null
	,@pageno			int = 1
	,@pagesize			int = 25
	,@total_rec			int output
)
as
begin
		/*
		 =============================================
		 Create date: Nov 22,2019
		 Description: M2-2307 M - QMS - My Invoices tab and page - DB
		 Modification:
		 =================================================================
		*/
		set nocount on

		drop table if exists #tmp_qms_my_invoices
		
		if (@OrderBy is null or @OrderBy = '' )
			set @OrderBy  = 'invoice_id'

		select	
			a.invoice_no as InvoiceNo
			, e.first_name + ' ' +last_name as Customer
			, a.reference_no as QuoteReferenceNo 
			, g.status as Status
			, sum(case when d.fee_type_id = 1 then (c.part_qty *  d.value) else  d.value end) as AmountDue
			, a.qms_quote_invoice_id as QMSQuoteInvoiceId
			, a.qms_quote_id as QMSQuoteId
			, a.invoice_id as InvoiceId
			, a.qms_customer_id as QMSCustomerId
			, f.quote_id as QuoteId
			into #tmp_qms_my_invoices
		from mp_qms_quote_invoices						(nolock) a
		join mp_qms_quote_invoice_parts					(nolock) b on a.qms_quote_invoice_id = b.qms_quote_invoice_id and a.is_deleted = 0
		join mp_qms_quote_invoice_part_quantities		(nolock) c on b.qms_quote_invoice_part_id = c.qms_quote_invoice_part_id and c.is_deleted = 0
		left join mp_qms_quote_invoice_part_qty_fee_types	(nolock) d on c.qms_quote_invoice_part_qty_id = d.qms_quote_invoice_part_qty_id
		join mp_qms_contacts							(nolock) e on a.qms_customer_id = e.qms_contact_id
		join mp_qms_quotes								(nolock) f on a.qms_quote_id = f.qms_quote_id
		join mp_mst_qms_status							(nolock) g on a.status_id = g.qms_status_id
		where 
			 a.created_by = @SupplierId
			 and 
			 (
				 (a.invoice_no like '%'+@SearchText+'%')	
				 or	
				 (a.reference_no like '%'+@SearchText+'%')		
				 or
				 (@SearchText is null)
			 )
			 and a.qms_customer_id = (case when @Customer_id is null or @Customer_id ='0'  then a.qms_customer_id else @Customer_id end )
			 and g.status = (case when @Status is null or @Status = '' then g.status else @Status end ) 
		group by a.invoice_no ,e.first_name + ' ' +last_name ,a.reference_no,g.status, a.qms_quote_invoice_id, a.qms_quote_id ,a.invoice_id ,a.qms_customer_id,f.quote_id
		
		select @total_rec = count(1)  from #tmp_qms_my_invoices

		select 
			InvoiceNo	
			,Customer	
			,QuoteReferenceNo	
			,Status	
			,AmountDue	+ isnull(SpecialFeeAmt,0) as AmountDue
			,a.QMSQuoteInvoiceId	
			,QMSQuoteId	
			,InvoiceId	
			,QMSCustomerId	
			,QuoteId	

		from #tmp_qms_my_invoices a
		left join
		(
			select a.qms_quote_invoice_id as QMSQuoteInvoiceId, sum(h.value) SpecialFeeAmt
			from mp_qms_quote_invoices							(nolock) a
			join mp_qms_quote_invoice_parts						(nolock) b on a.qms_quote_invoice_id = b.qms_quote_invoice_id and a.is_deleted = 0
			left join mp_qms_quote_invoice_part_special_fees	(nolock) h on b.qms_quote_invoice_part_id = h.qms_quote_invoice_part_id
			where 
			 a.created_by = @SupplierId
			group by a.qms_quote_invoice_id 
		)  b on a.QMSQuoteInvoiceId = b.QMSQuoteInvoiceId
		order by 
				case   when @IsOrderByDesc =  1 and @OrderBy = 'invoice_id' then   convert(bigint,InvoiceNo) end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'Customer' then   Customer end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'Status' then   Status end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'quote_id' then   QMSQuoteId end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'total' then   AmountDue end desc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'invoice_id' then   convert(bigint,InvoiceNo) end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'Customer' then   Customer end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'Status' then   Status end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'quote_id' then   QMSQuoteId end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'total' then   AmountDue end asc
		offset @pagesize * (@pageno - 1) rows
		fetch next @pagesize rows only

end
