/*
declare @QMSQuoteInvoiceId1 int

exec proc_set_qms_quote_invoice_basic_info
	@QMSQuoteId				=3176
	,@SupplierId			=3176
	,@CustomerId			=1064
	,@ReferenceNo			='1064'
	,@InvoiceName			='1064'
	,@InvoiceNo				='1064'
	,@InvoiceDate			= getdateutc()
	,@CurrencyId			= 2
	,@PurchaseOrderNo		=1064
	,@PaymentTermId			=20
	,@StatusID				=21
	,@Notes					='1064'
	,@QMSQuoteInvoiceId		=@QMSQuoteInvoiceId1  output

select @QMSQuoteInvoiceId1

*/

create proc proc_set_qms_quote_invoice_basic_info
(
	@QMSQuoteId				int
	,@SupplierId			int
	,@CustomerId			int
	,@ReferenceNo			nvarchar(300)
	,@InvoiceName			nvarchar(500)
	,@InvoiceNo				varchar(150)
	,@InvoiceDate			datetime
	,@CurrencyId			int
	,@PurchaseOrderNo		int
	,@PaymentTermId			int = null
	,@StatusID				int
	,@Notes					nvarchar(4000)
	,@QMSQuoteInvoiceId		int output
)
as
begin

	/* Dec 12 M2-2421 M - Invoice tab - Update Other Quantity selection -DB */

	declare @TransactionStatus		varchar(500) = 'Failed'
	
	begin tran
	begin try

		
		insert into mp_qms_quote_invoices
		(qms_quote_id, qms_customer_id, invoice_no, invoice_name, purchase_order_number, reference_no
		,currency_id ,invoice_date ,payment_term_id ,status_id ,notes ,created_by ,created_date)
		values 
		(@QMSQuoteId ,@CustomerId ,@InvoiceNo ,@InvoiceName ,@PurchaseOrderNo ,@ReferenceNo
		,@CurrencyId ,@InvoiceDate ,@PaymentTermId ,@StatusID ,@Notes ,@SupplierId ,GETUTCDATE()
		)
		set @QMSQuoteInvoiceId = @@IDENTITY


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
