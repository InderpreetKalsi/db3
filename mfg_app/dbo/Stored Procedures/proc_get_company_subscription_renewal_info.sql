
/*


select * from mp_company_subscription_renewal_statuses (nolock)  where is_closed = 0 and status is null
select * from mp_company_subscription_renewal_statuses (nolock)  where  company_id = 1470046
select * from mp_companies where company_id = 1470046
  
  select distinct c.company_id, c.name , c.company_zoho_id , b.invoice_id  , b.* 
  from mp_company_subscriptions (nolock) a   
  join mp_companies_invoice  (nolock) b on a.customer_id = b.customer_id   
  join mp_companies  (nolock) c on account_zoho_id = c.company_zoho_id and c.company_id  = 1470046
  where b.status ='Overdue' 
  and not exists  (select invoice_id from mp_companies_invoice (nolock) where customer_id = a.customer_id and invoice_id = b.invoice_id  and status = 'paid') 
  1767549

  select * from mp_company_subscription_renewal_statuses where company_id = 337826
  
  
  select a.*
  from mp_company_subscriptions (nolock) a   
  join mp_companies_invoice  (nolock) b on a.customer_id = b.customer_id   
  where account_zoho_id =  '3341780000002249131'
  and b.status ='Overdue'  


  select   
   status, due_date ,zoho_seqid   ,invoice_id
   , rank() over (order by invoice_id) invoice_rn   
   , row_number() over (partition by customer_id,invoice_id order by zoho_seqid desc) same_invoice_rn   
   from mp_companies_invoice    
   where invoice_id in 
	(
		'1623878000007130256' , '1623878000007934517'
	)  
	and invoice_id not in (select invoice_id from mp_companies_invoice where customer_id = '1623878000000308391' and status = 'paid')



select * from mp_company_subscription_renewal_statuses (nolock) where is_closed = 0 and due_date is not null

select * from mp_company_subscription_renewal_statuses (nolock) where company_id = 1470046
exec proc_get_company_subscription_renewal_info @supplier_company_id = 1470046
select * from mp_company_subscription_renewal_statuses (nolock) where company_id = 1470046
*/

CREATE procedure [dbo].[proc_get_company_subscription_renewal_info]  
(  
 @supplier_company_id int  
)  
as  
begin  
   
 /* M2-2053 M - Past due bill banner - DB */   
 set nocount on  
  
 declare @company_zoho_id varchar(250)  
 declare @subscription_renewal_msg varchar(250) = ''  
  
 select @company_zoho_id = company_zoho_id   from mp_companies (nolock) where company_id =  @supplier_company_id  
   
 if @company_zoho_id is null or @company_zoho_id  = ''  
 begin  
  /* M2-2098 M - Implement Close 'X' button on top right side of 'Past bill due date banner' - DB */  
  if ((select count(1) from mp_company_subscription_renewal_statuses (nolock)  where company_id =  @supplier_company_id ) = 0 )  
   insert into mp_company_subscription_renewal_statuses (company_id,status) select @supplier_company_id , ''  
    
  /**/  
 end  
 else  
 begin  
   
  drop table if exists #tmp_company_overdue_invoices  
  /* M2-2098 M - Implement Close 'X' button on top right side of 'Past bill due date banner' - DB */  
  drop table if exists #tmp_company_overdue_invoices_final_status  
  /**/  
  
  select distinct b.invoice_id  
  into #tmp_company_overdue_invoices  
  from mp_company_subscriptions (nolock) a   
  join mp_companies_invoice  (nolock) b on a.customer_id = b.customer_id   
  where account_zoho_id =  @company_zoho_id   
  and b.status ='Overdue'  
  /*Dec 29 2020 Soel  3:13 AM @Inderpreet Singh Kalsi @Allwin Lewis can you look at the past due notice in the application based on invoice data from Zoho. it appears to not be working correctly .  I am not seeing the notice when I log in with customers with past due invoices. */
  and not exists  (select invoice_id from mp_companies_invoice (nolock) where customer_id = a.customer_id and invoice_id = b.invoice_id  and status = 'paid')
  /**/
  
   
  select   
   /* M2-2098 M - Implement Close 'X' button on top right side of 'Past bill due date banner' - DB */  
   @supplier_company_id as supplier_company_id , due_date   
   /**/  
   ,   
   case   
    when datediff(day,due_date,getutcdate()) between 6 and 10 then   
     'Your account is 5 days past due. Please call us at 770-444-9686 to update your payment information or email us at <a href="mailto:accounting@mfg.com"> accounting@mfg.com </a> to contact you.'  
    when datediff(day,due_date,getutcdate()) between 11 and 20 then   
     'Your account is 10 days past due. Please call us at 770-444-9686 to update your payment information or email us at <a href="mailto:accounting@mfg.com"> accounting@mfg.com </a> to contact you.'  
    when datediff(day,due_date,getutcdate()) between 21 and 29 then   
     'Your account is 20 days past due. Please call us at 770-444-9686 to update your payment information or email us at <a href="mailto:accounting@mfg.com"> accounting@mfg.com </a> to contact you.'  
    when datediff(day,due_date,getutcdate()) = 30  then   
     'Your account is 29 days past due. Please call us at 770-444-9686 to update your payment information or email us at <a href="mailto:accounting@mfg.com"> accounting@mfg.com </a> to contact you.'  
    when datediff(day,due_date,getutcdate()) > 30  then   
     'Your account is expired. Please call us at 770-444-9686 to update your payment information or email us at <a href="mailto:accounting@mfg.com"> accounting@mfg.com </a> to contact you.'  
                  
   end as subscription_renewal_msg   
  /* M2-2098 M - Implement Close 'X' button on top right side of 'Past bill due date banner' - DB */  
  into #tmp_company_overdue_invoices_final_status   
  /**/  
  from  
  (  
   select   
   status, due_date ,zoho_seqid   
   , rank() over (order by invoice_id) invoice_rn   
   , row_number() over (partition by customer_id,invoice_id order by zoho_seqid desc) same_invoice_rn   
   from mp_companies_invoice    
   where invoice_id in (select * from #tmp_company_overdue_invoices)  
   
  ) a   
  where   
  invoice_rn = 1    
  and same_invoice_rn = 1  
  and status in ( 'Overdue'  ) --'void' , 
  
  --select * from #tmp_company_overdue_invoices_final_status

  /* Soel 3:28 AM Jan 10, 2020 @Allwin Lewis @Inderpreet Singh Kalsi can you look at account rpm@rpm-engineering.com - VISION ID 363393, they are still getting the past due alert even though they don't have any past due invoices */  
  if ((select count(1) from #tmp_company_overdue_invoices_final_status) = 0)  
  begin  
   update mp_company_subscription_renewal_statuses set is_closed = 1 , closed_date =  convert(date,getutcdate()) where  company_id =  @supplier_company_id  
  end  
  /**/  
  else  
  begin  
   /* M2-2098 M - Implement Close 'X' button on top right side of 'Past bill due date banner' - DB */  
   merge mp_company_subscription_renewal_statuses  as target    
   using #tmp_company_overdue_invoices_final_status as source on    
    (target.company_id = source.supplier_company_id)    
   when matched  and (isnull(target.status,'') != source.subscription_renewal_msg or target.due_date != source.due_date) then    
     update set    
      target.status       = source.subscription_renewal_msg   
     ,target.due_date      = source.due_date  
     ,target.is_closed      = 0  
   when not matched then  
    insert (company_id,status,due_date) values (source.supplier_company_id,source.subscription_renewal_msg,source.due_date)  
   ;    
   /**/  
  end  
    
 end  
  
 /* M2-2098 M - Implement Close 'X' button on top right side of 'Past bill due date banner' - DB */  
 select   
  /* Soel - Dec 14, 2022 is it possible to deactivate the past due banner that is being linked to Zoho data?
  status as subscription_renewal_msg   
  */
  '' as subscription_renewal_msg
 from mp_company_subscription_renewal_statuses  
 where company_id =  @supplier_company_id and is_closed = 0  
 /**/  
  
  drop table if exists #tmp_company_overdue_invoices  
  drop table if exists #tmp_company_overdue_invoices_final_status  
   
end  