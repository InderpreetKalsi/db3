
/*

exec proc_get_qms_quote_invoices
@supplier_id = 1337916 
,@qms_quote_id = 57

*/
CREATE procedure [dbo].[proc_get_qms_quote_invoices]
(
	@supplier_id int
	,@qms_quote_id int
)
as
begin
		/*
		 =============================================
		 Create date: Nov 22,2019
		 Description: M2-2304 M - Invoice tab - Invoices added to the list - DB
		 Modification:
		 =================================================================
		*/

		set nocount on

		select	
			a.qms_quote_invoice_id as QMSQuoteInvoiceId
			, a.qms_quote_id as QMSQuoteId
			, a.invoice_no as InvoiceNo
			, a.invoice_name as InvoiceName
			, convert(varchar(10) ,a.created_date,101) as InvoiceCreated
			, a.reference_no as QuoteReferenceNo
			, e.company as Customer
			, sum(case when d.fee_type_id = 1 then (c.part_qty *  d.value) else  d.value end) as AmountDue
			, a.status_id as StatusId
			, e.qms_contact_id as QmsContactId
		from mp_qms_quote_invoices						(nolock) a
		join mp_qms_quote_invoice_parts					(nolock) b on a.qms_quote_invoice_id = b.qms_quote_invoice_id
		join mp_qms_quote_invoice_part_quantities		(nolock) c on b.qms_quote_invoice_part_id = c.qms_quote_invoice_part_id and c.is_deleted = 0
		join mp_qms_quote_invoice_part_qty_fee_types	(nolock) d on c.qms_quote_invoice_part_qty_id = d.qms_quote_invoice_part_qty_id
		join mp_qms_contacts							(nolock) e on a.qms_customer_id = e.qms_contact_id
		where 
			a.qms_quote_id = @qms_quote_id
			and a.created_by = @supplier_id
			and a.is_deleted != 1 
		group by a.qms_quote_invoice_id,a.qms_quote_id, a.invoice_no, a.invoice_name  ,convert(varchar(10) ,a.created_date,101) , a.reference_no , a.status_id, e.company,e.qms_contact_id
		order by QMSQuoteInvoiceId , QMSQuoteId 
end
