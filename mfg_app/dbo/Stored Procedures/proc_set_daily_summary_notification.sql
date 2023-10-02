
CREATE   procedure [dbo].[proc_set_daily_summary_notification]  
as  
begin  
  
 /* M2-770 Daily Summary Email for buyers- API*/  
  
  
 declare @message_type_id int = (select  message_type_id from mp_mst_message_types where message_type_name = 'BUYER_DAILY_SUMMARY')  
   
 declare @processStatus as varchar(max) = 'SUCCESS'  
 declare @from_username as nvarchar(100) = ''  
 declare @from_user_contactimage as nvarchar(500) = ''  
 declare @from_user_email varchar(200) = ''  
 declare @pending_awards varchar(50) = '0'  
 declare @new_qoutes_received varchar(50) = '0'  
 declare @nda_to_approve varchar(50) = '0'  
 declare @rating_received varchar(50) = '0'  
 declare @rating_to_performed varchar(50) = '0'  
 declare @likes varchar(50) = '0'  
 declare @follows varchar(50) = '0'  
 declare @email_msg_subject as nvarchar(250) = ''  
 declare @email_msg_body as nvarchar(max) = ''  
 declare @notification_email_running_id  table (id int identity(1,1) ,  email_message_id int null)  
 declare @today_date  as datetime =  getutcdate()  
  
 /* getting email subject & body */  
  select   
   @email_msg_body = email_body_template, @email_msg_subject = email_subject_template  
  from mp_mst_email_template where message_type_id = @message_type_id and is_active = 1   
    
 /**/  
   
 drop table if exists #all_buyers  
  
 create table #all_buyers  
 (  
  contact_id   int,  
  summary_date  date default convert(date,getutcdate()) ,  
  pending_awards  varchar(50) default 0,  
  new_qoutes_received varchar(50) default 0,  
  nda_to_approve  varchar(50) default 0,  
  rating_received  varchar(50) default 0,  
  rating_to_performed varchar(50) default 0,  
  likes    varchar(50) default 0,  
  follows    varchar(50) default 0  
 )  
   
 insert into #all_buyers  (contact_id)  
 select a.contact_id   
 from mp_contacts a (nolock)   
 inner join mp_scheduled_job b  (nolock) on a.contact_id=b.contact_id and b.scheduler_type_id = 9   
 where a.is_buyer =  1  and is_notify_by_email = 1 and b.is_deleted=0  
 --and a.contact_id  in  (1338075)
 --(  
 -- select distinct c.contact_id  
 -- from mp_exclude_contacts_from_daily_notification a (nolock)  
 -- join aspnetusers b (nolock) on a.email = b.email  
 -- join mp_contacts c (nolock) on b.contact_id = c.contact_id  and is_buyer = 1  
 --)  
  
 --and b.is_scheduled=1  this condition removed from above query

 -- pending_awards  
 update a set a.pending_awards = b.pending_awards  
 --select *  
 from #all_buyers a  
 join   
 (  
 select   
  b.contact_id as buyer_id , count(*) as  pending_awards  
 from  mp_rfq_quote_items a (nolock)   
 join  mp_rfq_quote_SupplierQuote b  (nolock) on b.rfq_quote_SupplierQuote_id = a.rfq_quote_SupplierQuote_id  
 join  mp_rfq_parts c  (nolock) on a.rfq_part_id = c.rfq_part_id  
 join  mp_rfq d  (nolock) on b.rfq_id = d.rfq_id  
 where (is_awrded is null or is_awrded = 0) and d.rfq_status_id not in (4, 5)  
 and convert(date,b.quote_date) = convert(date,  getutcdate()) and  is_quote_submitted =1  
 group by b.contact_id  
 ) b on a.contact_id= b.buyer_id  
  
  
 -- new_qoutes_received  
 update a set a.new_qoutes_received = b.new_qoutes_received  
 --select *  
 from #all_buyers a  
 join   
 (  
 select    
  b.contact_id as buyer_id , count(*) as  new_qoutes_received  
 from  
  mp_rfq_quote_SupplierQuote a  (nolock)   
 join  mp_rfq b  (nolock) on a.rfq_id = b.rfq_id  
 where   
  convert(date,a.quote_date) = convert(date,  getutcdate()) and    
  is_quote_submitted =1  
 and b.rfq_status_id not in (4, 5)  
 group by b.contact_id  
 ) b on a.contact_id= b.buyer_id  
  
  
 -- nda_to_approve  
 update a set a.nda_to_approve = b.nda_to_approve  
 from #all_buyers a  
 join   
 (  
  
 select b.contact_id  as buyer_id  ,  count(distinct b.rfq_id) nda_to_approve   
 from  mp_rfq_supplier_nda_accepted a (nolock)   
 join  mp_rfq b  (nolock) on a.rfq_id = b.rfq_id  
 where   
  convert(date,prefered_nda_type_accepted_date) = convert(date,  getutcdate()) and   
  (isapprove_by_buyer is null)  
  and b.rfq_status_id not in (4, 5)  
 group by b.contact_id  
 ) b on a.contact_id= b.buyer_id  
  
  
 -- rating received  
 update a set a.rating_received = b.rating_received  
 from #all_buyers a  
 join   
 (  
 select to_id as buyer_id , count(*) as rating_received from mp_rating_responses a (nolock)   
 where   
  convert(date,created_date) = convert(date,  getutcdate())   
 group by to_id  
 ) b on a.contact_id= b.buyer_id  
  
 -- rating to perform  
 update a set a.rating_to_performed = b.rating_to_performed  
 from #all_buyers a  
 join   
 (  
 select from_cont as buyer_id , count(*) rating_to_performed from  mp_messages  (nolock) where message_type_id in (select message_type_id from mp_mst_message_types (nolock)  where message_type_name = 'SUPPLIER_NPS_RATING')  
 --and  convert(date,message_date) = convert(date,  getutcdate())   
 and (message_read = null or message_read = 0 )  
 group by from_cont  
 ) b on a.contact_id= b.buyer_id  
   
 -- likes  
 update a set a.likes = b.likes  
 from #all_buyers a   
 join   
 ( 
  	select  b.contact_id as buyer_id , count(is_rfq_like) likes from
    mp_rfq_supplier_likes   (nolock)   a
	join mp_rfq(nolock)  b on a.rfq_id = b.rfq_id
	and convert(date,a.like_date) = convert(date,  getutcdate())  
	 group by b.contact_id
  ) b on a.contact_id= b.buyer_id
  
  
 -- follows  
update a set a.follows = b.follows  
 from #all_buyers a  
 join   
 (  
  select contact_id as buyer_id, count(*) follows  from   
  (  
    select distinct mpc.contact_id , mbd.company_id from   
    mp_book_details mbd   (nolock)  
    JOIN mp_books  mb   (nolock) on mbd.book_id =mb.book_id  
    JOIN mp_mst_book_type mmbt (nolock) on mmbt.book_type_id = mb.bk_type  
	JOIN mp_contacts mpc (nolock) on mpc.company_id = mbd.company_id
     and mmbt.book_type ='BOOK_BOOKTYPE_HOTLIST'  
     and convert(date,mbd.creation_date) = convert(date,  getutcdate())   
  ) a  
  group by  contact_id  
 ) b on a.contact_id= b.buyer_id   
  
  
 insert into mp_email_messages  
 ( message_type_id, email_message_subject, email_message_descr, email_message_date,from_cont ,to_cont, to_email, message_sent,message_read )  
 --output inserted.email_message_id into @notification_email_running_id  
 select    
  @message_type_id    
  , @email_msg_subject email_msg_subject   
  , replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(@email_msg_body, '#Buyer_Name#', b.first_name + ' ' + b.last_name),'#Summary_Date_Time#',  convert(varchar(5),@today_date, 108) +', ' +convert(varchar(18),
@today_date, 103) ), '#pending_awards#', pending_awards),'#new_qoutes_received#', new_qoutes_received), '#nda_to_approve#' , nda_to_approve),'#rating_received#', rating_received), '#rating_to_performed#', rating_to_performed), '#likes#', likes), '#follows#' , follows),'Email Me', isnull(n.email,'')) ,'+678-981-4023' ,    isnull(m.communication_value,'') ) , 'Kevin Witherspoon' , isnull(l.first_name,'') + ' ' + isnull(l.last_name,'')) as email_msg_body  
  , @today_date email_message_date  
  , a.contact_id from_cont  
  , a.contact_id to_cont  
  , c.email  
  , 0 message_sent  
  , 0 message_read  
  --, isnull(l.title,'')  
  --, isnull(l.first_name,'') + ' ' + isnull(l.last_name,'')  
  --, isnull(m.communication_value,'')  
  --, isnull(n.email,'')  
 from #all_buyers  a  
 join  mp_contacts b  (nolock) on a.contact_id = b.contact_id  
	AND b.is_notify_by_email = 1  /* M2-4789*/
 join  aspnetusers c  (nolock) on b.user_id = c.id  
 --left join   mp_special_files d on a.contact_id = d.cont_id and filetype_id = 17  
 join mp_companies k   (nolock) on b.company_id = k.company_id   
 left join mp_contacts l     (nolock) on k.Assigned_SourcingAdvisor = l.contact_id     
 left join mp_communication_details m     (nolock) on l.contact_id   = m.contact_id and m.communication_type_id = 1  
 left join aspnetusers n on l.user_id = n.id  
 where  (pending_awards + new_qoutes_received  + nda_to_approve + rating_received + likes + follows) >0   
  
end

