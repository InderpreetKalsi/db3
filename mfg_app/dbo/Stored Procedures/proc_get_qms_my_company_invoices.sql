CREATE procedure [dbo].[proc_get_qms_my_company_invoices]
(
	@SupplierId				int	
	,@SupplierCompanyId		int	
	,@SearchText			varchar(150)	= null
	,@IsOrderByDesc			bit		='true'
	,@OrderBy				varchar(100)	= null -- 'Customer' , 'Status'
	,@Customer_id			int = null
	,@Status				varchar(100)	= null
	,@PageNo				int = 1
	,@PageSize				int = 25
	,@FilterBySupplierId	int
	,@TotalRec				int output
)
as
begin
		/*
		 =============================================
		 Create date: Feb 24,2020
		 Description: M2-2311 M - My Company Invoices - DB
		 Modification:
		 =================================================================
		*/
		set nocount on

		drop table if exists #tmp_qms_my_invoices
		drop table if exists #tmp_qms_my_company_users

		if (@OrderBy is null or @OrderBy = '' )
			set @OrderBy  = 'invoice_id'

		
		select contact_id into #tmp_qms_my_company_users 
		from mp_contacts (nolock) where company_id = @SupplierCompanyId

		select	
			a.invoice_no as InvoiceNo
			, e.first_name + ' ' +e.last_name as Customer
			, a.reference_no as QuoteReferenceNo 
			, g.qms_status_id as StatusId
			, g.status as Status
			, sum(case when d.fee_type_id = 1 then (c.part_qty *  d.value) else  d.value end) as AmountDue
			, a.qms_quote_invoice_id as QMSQuoteInvoiceId
			, a.qms_quote_id as QMSQuoteId
			, a.invoice_id as InvoiceId
			, a.qms_customer_id as QMSCustomerId
			, f.quote_id as QuoteId
			, h.first_name + ' ' + h.last_name as Supplier
			, h.contact_id as SupplierId
			into #tmp_qms_my_invoices
		from mp_qms_quote_invoices						(nolock) a
		join mp_qms_quote_invoice_parts					(nolock) b on a.qms_quote_invoice_id = b.qms_quote_invoice_id and a.is_deleted = 0
		join mp_qms_quote_invoice_part_quantities		(nolock) c on b.qms_quote_invoice_part_id = c.qms_quote_invoice_part_id and c.is_deleted = 0
		join mp_qms_quote_invoice_part_qty_fee_types	(nolock) d on c.qms_quote_invoice_part_qty_id = d.qms_quote_invoice_part_qty_id
		join mp_qms_contacts							(nolock) e on a.qms_customer_id = e.qms_contact_id
		join mp_qms_quotes								(nolock) f on a.qms_quote_id = f.qms_quote_id
		join mp_mst_qms_status							(nolock) g on a.status_id = g.qms_status_id
		join mp_contacts								(nolock) h on a.created_by = h.contact_id
		where 

			 (
				 (a.invoice_no like '%'+@SearchText+'%')	
				 or	
				 (a.reference_no like '%'+@SearchText+'%')		
				 or
				 (@SearchText is null)
			 )
			 and a.qms_customer_id = (case when @Customer_id is null or @Customer_id ='0'  then a.qms_customer_id else @Customer_id end )
			 and g.status = (case when @Status is null or @Status = '' then g.status else @Status end ) 
			 and a.created_by in  (select contact_id from #tmp_qms_my_company_users)
			 and h.contact_id = (case when @FilterBySupplierId is null or @FilterBySupplierId ='0'  then h.contact_id else @FilterBySupplierId end ) 
		group by a.invoice_no ,e.first_name + ' ' +e.last_name ,a.reference_no,g.qms_status_id,g.status, a.qms_quote_invoice_id, a.qms_quote_id ,a.invoice_id ,a.qms_customer_id,f.quote_id ,h.first_name + ' ' + h.last_name ,h.contact_id 
		
		select @totalrec = count(1)  from #tmp_qms_my_invoices

		select 
			InvoiceNo	
			,Customer	
			,QuoteReferenceNo	
			,StatusId
			,Status	
			,AmountDue	+ isnull(SpecialFeeAmt,0) as AmountDue
			,a.QMSQuoteInvoiceId	
			,QMSQuoteId	
			,InvoiceId	
			,QMSCustomerId	
			,QuoteId
			,Supplier	
			,SupplierId
		from #tmp_qms_my_invoices  a
		left join
		(
			select a.qms_quote_invoice_id as QMSQuoteInvoiceId, sum(h.value) SpecialFeeAmt
			from mp_qms_quote_invoices							(nolock) a
			join mp_qms_quote_invoice_parts						(nolock) b on a.qms_quote_invoice_id = b.qms_quote_invoice_id and a.is_deleted = 0
			left join mp_qms_quote_invoice_part_special_fees	(nolock) h on b.qms_quote_invoice_part_id = h.qms_quote_invoice_part_id
			where 
			  a.created_by in  (select contact_id from #tmp_qms_my_company_users)
			group by a.qms_quote_invoice_id 
		)  b on a.QMSQuoteInvoiceId = b.QMSQuoteInvoiceId
		order by 
				case   when @IsOrderByDesc =  1 and @OrderBy = 'invoice_id' then   convert(bigint,InvoiceNo) end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'Customer' then   Customer end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'Status' then   Status end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'quote_id' then   QMSQuoteId end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'total' then   AmountDue end desc   
				,case  when @IsOrderByDesc =  1 and @OrderBy = 'Supplier' then   Supplier end desc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'invoice_id' then    convert(bigint,InvoiceNo) end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'Customer' then   Customer end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'Status' then   Status end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'quote_id' then   QMSQuoteId end asc   
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'total' then   AmountDue end asc
				,case  when @IsOrderByDesc =  0 and @OrderBy = 'Supplier' then   Supplier end asc   
		offset @pagesize * (@pageno - 1) rows
		fetch next @pagesize rows only


		drop table if exists #tmp_qms_my_invoices
		drop table if exists #tmp_qms_my_company_users
end
