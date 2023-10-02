CREATE  procedure [dbo].[proc_mfgzoho_set_subscription_sink_down]
as
begin
	
	/* M2-1541 Zoho Subscription and Invoice AppSync process - DB */
set nocount on	
	declare @todaydate datetime = getutcdate()
	declare @lastidentity int

	drop table if exists ##zoho_companies_subscription
	drop table if exists ##zoho_Invoice
	drop table if exists ##zoho_Invoice_Payments

----**************************************************************************************************************
---- Step 1 : pull records from table "zoho_companies_subscription" into mp_company_subscriptions 
----**************************************************************************************************************
/* reteriving data for sink down process for zoho_companies_subscription */
	select company_subscription_id,payment_duration,subscription_start_date,subscription_end_date
	,zoho_subscription_id,cc_gateway,is_autorenewal,zoho_id,customer_id,account_zoho_id,currency_symbol
	,total_invoice_amount,invoice_amount
	into ##zoho_companies_subscription
	from zoho..zoho_companies_subscription(nolock) 
	where synctype = 2 and isnull(isprocessed,0) = 0 and  isnull(issync,0) = 0
/* */

--**********************************************************************************************************
-- Step 2 :pull records from table "zoho_Invoice" into "mp_companies_invoice "
--**********************************************************************************************************

/* reteriving data for sink down process form zoho_Invoice */
	select seqid,invoice_id,number,status,invoice_date,due_date,a.customer_id
	,total,payment_made,balance,credits_applied,write_off_amount 
	into ##zoho_Invoice
	from zoho..zoho_Invoice(nolock) a 
	where synctype =2 and isnull(isprocessed,0) = 0	and   isnull(issync,0) = 0
/* */


if ((select count(1) from ##zoho_companies_subscription ) > 0 or (select count(1) from ##zoho_Invoice ) > 0 )
begin

	begin try
		begin tran
	
	/* inserting company_zoho_id for log the records for sink down*/
		declare @company_sink_down_log table (company_zoho_id varchar(200))

	/* update isprocessed,issync status for above records */
		update b
		set b.isprocessed = 1,b.issync = 1,b.processeddatetime = @todaydate ,b.SyncDatetime = @todaydate
		from ##zoho_companies_subscription (nolock)a
		join zoho..zoho_companies_subscription(nolock)  b 
		on a.company_subscription_id = b.company_subscription_id
	/* */

	

	/* Merger revords into table mp_company_subscriptions  */
		 merge dbo.mp_company_subscriptions as target
				 using  ##zoho_companies_subscription as source 
				 ON (target.zoho_company_subscription_id = source.company_subscription_id)
				 when  NOT MATCHED then 
				 insert (zoho_company_subscription_id,payment_duration,subscription_start_date,subscription_end_date
					,zoho_subscription_id,cc_gateway,is_autorenewal,zoho_id,customer_id,account_zoho_id,created_on
					,currency_symbol,membership_total_amount,invoice_total_amount)
				 values (source.company_subscription_id,source.payment_duration,source.subscription_start_date,
				 source.subscription_end_date,source.zoho_subscription_id,source.cc_gateway,is_autorenewal
				 ,source.zoho_id,source.customer_id,source.account_zoho_id,@todaydate
				 ,source.currency_symbol,source.total_invoice_amount,source.invoice_amount)
			output 
			inserted.zoho_id 
			into @company_sink_down_log;
	/* */
	----********************************************End Step 1 ***************************************************
	

	/* Merger revords into table mp_companies_invoice  */
		 merge dbo.mp_companies_invoice as target
				 using  ##zoho_Invoice as source 
				 ON (target.zoho_seqid  = source.seqid )
				 when  NOT MATCHED then 
				 insert (zoho_seqid,invoice_id,number,[status],invoice_date,customer_id
					,total,payment_made,balance,credits_applied,write_off_amount,created_on,due_date)
				 values (source.seqid ,source.invoice_id,source.number,source.[status],source.invoice_date
				 ,source.customer_id,source.total,source.payment_made,source.balance
				 ,source.credits_applied,source.write_off_amount,@todaydate , source.due_date);
	/* */
	----********************************************End Step 2 ***************************************************

	----**********************************************************************************************************
	---- Step 3 :  pull records from table "zoho_Invoice_Payments" into mp_Invoice_Payments 
	----**********************************************************************************************************
	/* reteriving data for sink down process for zoho_companies_subscription */
		select b.invoiceseqid,b.seqid,b.invoiceId,b.payment_id,b.payment_mode,b.invoice_payment_id
		,b.gateway_transaction_id,b.[description],b.[date],b.reference_number,b.amount,IsActive 
		into ##zoho_Invoice_Payments
		from ##zoho_Invoice (nolock) a 
		join  zoho..zoho_Invoice_Payments (nolock) b on a.invoice_id = b.invoiceid
	/* */

	/* update isprocessed ,issync, status for above records */
		update b
		set b.isprocessed = 1 , b.issync = 1,b.processeddatetime = @todaydate ,b.SyncDatetime = @todaydate
		from ##zoho_Invoice (nolock) a
		join zoho..zoho_Invoice(nolock)  b 
		on a.seqid = b.seqid
	/* */

	/* Merger revords into table mp_invoice_payments  */
		 merge dbo.mp_invoice_payments as target
				 using  ##zoho_Invoice_Payments as source 
				 ON (target.zoho_invoiceseqid  = source.invoiceseqid)
				 when  NOT MATCHED then 
				 insert (zoho_invoiceseqid,seqid,invoiceId,payment_id,payment_mode,invoice_payment_id
				 ,gateway_transaction_id,[description],[date],reference_number,amount)
				 values (source.invoiceseqid,source.seqid,source.invoiceId,source.payment_id,source.payment_mode,source.invoice_payment_id
				 ,source.gateway_transaction_id,source.[description],source.[date],source.reference_number,source.amount 
				 );
	/* */

		insert into zoho..zoho_sink_down_job_running_logs	(zoho_module_id,job_date,job_status)
		select 29 zoho_module_id , @todaydate , 'success'
		set @lastidentity = @@identity

	----********************************************End Step 3 ***************************************************

	commit
	
	end try

	begin catch
		rollback
		
		insert into zoho..zoho_sink_down_job_running_logs
		(zoho_module_id,job_date,job_status)
		select 29 zoho_module_id , @todaydate , 'fail : ' + error_message() 
		set @lastidentity = @@identity
	
		insert into zoho..zoho_sink_down_job_running_logs_detail (job_running_id , zoho_id)
		select @lastidentity , a.zoho_id 	from zoho..zoho_companies_subscription  (nolock) a
		join ##zoho_companies_subscription (nolock) b on a.Zoho_id = b.Zoho_id
		where synctype = 2 and isnull(issync,0) = 0 and isnull(isprocessed,0) = 0 
		
		update c set c.isprocessed = 1 , c.syncdatetime = null
		from zoho.dbo.zoho_sink_down_job_running_logs(nolock) a
		join zoho.dbo.zoho_sink_down_job_running_logs_detail(nolock) b on a.job_running_id = b.job_running_id
		join zoho..zoho_companies_subscription (nolock) c on b.zoho_id = c.Zoho_id
		join ##zoho_companies_subscription (nolock) d on  c.Zoho_id = d.Zoho_id
		where a.job_running_id = @lastidentity
		and synctype =2 and  isnull(issync,0) = 0 and isnull(isprocessed,0) = 0 

	end catch
end
else
begin
		insert into zoho..zoho_sink_down_job_running_logs	(zoho_module_id,job_date,job_status)
		select 29 zoho_module_id , @todaydate , 'No records found'
		set @lastidentity = @@identity
end

end
