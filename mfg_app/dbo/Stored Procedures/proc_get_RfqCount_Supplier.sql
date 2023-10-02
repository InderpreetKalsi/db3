

/*
exec [proc_get_RfqCount_Supplier]
@CompanyId =1702566
,@ContactId = 186212
,@RfqType = 0 
*/
CREATE  PROCEDURE [dbo].[proc_get_RfqCount_Supplier]
	@ContactId INT,
	@CompanyId INT,
	@RfqType INT = 0,
	@SearchText VARCHAR(50) = Null,	
	@Processids as tbltype_ListOfProcesses readonly	
AS
BEGIN
 
	
	declare @is_registered_supplier bit = 0 
	declare @manufacturing_location_id smallint  
	declare @company_capabilities int  = 0

	set @is_registered_supplier = (select is_registered from mp_registered_supplier (nolock)  where company_id = @CompanyId)
	set @manufacturing_location_id  = (select manufacturing_location_id from mp_companies (nolock) where company_id = @CompanyId)
	set @company_capabilities = (select count(1) from mp_company_processes  (nolock) where  company_id = @CompanyId)


    declare @blacklisted_rfqs table (rfq_id int)

    insert into @blacklisted_rfqs (rfq_id)
    select distinct c.rfq_id 
	from mp_book_details  a  (nolock)  
    join mp_books	b  (nolock)  on a.book_id = b.book_id 
    join mp_rfq		c  (nolock)  on b.contact_id = c.contact_id
    where bk_type= 5 and a.company_id = @CompanyId 
	union  -- exclude rfq's for black listed buyer which are awarded & quoted 
	select distinct c.rfq_id  
	from mp_book_details  a  (nolock)  
    join mp_books b  (nolock)  on a.book_id = b.book_id  and b.contact_id = @ContactId
	join mp_contacts d  (nolock)  on a.company_id =  d.company_id
	join mp_rfq c  (nolock)  on d.contact_id = c.contact_id
	left join mp_rfq_quote_supplierquote f  (nolock)  on c.rfq_id = f.rfq_id
	left join mp_rfq_quote_items e  (nolock)  on f.rfq_quote_SupplierQuote_id= e.rfq_quote_SupplierQuote_id
    where bk_type= 5 and  ((f.is_quote_submitted = 0 or f.is_quote_submitted is null)and  isnull(e.is_awrded,0) = 0)


------------------------ Award Declined RFQ Count --------------------
	IF (@RfqType = 0)
	BEGIN

		select 'AWARDED_RFQ' As RfqType,  			 
			 count(distinct rqsq.rfq_id) AS RFQCount		 			 
		from mp_rfq_quote_SupplierQuote as rqsq  (nolock) 
		join mp_rfq_quote_items			as rqid (nolock)
			on rqid.rfq_quote_SupplierQuote_id = rqsq.rfq_quote_SupplierQuote_id  
				and rqsq.contact_id = @ContactId and is_awrded = 1 
				and rqid.status_id = 6
				and convert(date, rqid.awarded_date) = convert(date, getutcdate())
				and rqsq.is_rfq_resubmitted =0
		where rqsq.rfq_id not in  (select rfq_id from @blacklisted_rfqs)		 
		
		Union All
		-------------------------- Special Invite Rfq Count --------------------
		--Code modified with ticket DATA-66
		select 'SPECIAL_INVITED_RFQ_UNREAD' As RfqType
		,  count(distinct  b.rfq_id) As RFQCount	
		from
		mp_rfq_supplier		mrs				(nolock) 
		join mp_rfq b						(nolock) on mrs.rfq_id = b.rfq_id and rfq_status_id = 3 
			and mrs.company_id = @CompanyId
		join mp_messages mm					(nolock) on mm.rfq_id = mrs.rfq_id 
		JOIN mp_mst_message_types mt		(nolock) ON mm.message_type_id = mt.message_type_id
			AND mt.message_type_name = 'RFQ_RELEASED_BY_ENGINEERING'
			AND message_read = 0 
			AND message_subject like '%special%'
			AND mm.to_cont  = @contactId 
		Where  mm.rfq_id not in  (select rfq_id from @blacklisted_rfqs)
		and b.rfq_id not in  (select distinct rfq_id from mp_rfq_quote_SupplierQuote (nolock) where contact_id = @ContactId  )
		and convert(date,mm.message_date) = convert(date,getutcdate()) 
		Union All
		------------------------ NDA_TO_SIGN_SUPPLIER_DECLINED --------------------
		select distinct	'NDA_TO_SIGN_SUPPLIER_DECLINED' as RFQTypes, 0 AS RFQCount
		Union All
		------------------------ NDA_TO_SIGN --------------------
		select 'NDA_TO_SIGN_REQUIRED_RESIGN' as RFQTypes , 0 as RFQCount 
		
		Union All
		------------------------ NEW MESSAGES ---------------------------
		--M2-1536 Change and Activate the M Dashboard tile buttons - DB--
		select 'NEW_MESSAGES' as RFQTypes , count(1)  as RFQCount 
		from mp_messages (nolock) 
		where to_cont = @ContactId and convert(date,message_date) = convert(date,getutcdate()) and message_read = 0
		and message_subject is not null and message_descr is not null
		/* Nov 22, 2021 : Beau Martin  - M user jeremy@sumrallmanufacturing.com sees 2 new messages on dashboard tile, yet no unread messages were found on messages page.*/
		and message_type_id in (select message_type_id from mp_mst_message_types (NOLOCK) where IsNotification = 0)
		/* */
		Union All

		------------------------ NEW NOTIFICATIONS ---------------------------
		--M2-4401 New bubble for notification when user login in application - DB--
		select 'NEW_NOTIFICATIONS' as RFQTypes , count(1)  as RFQCount 
		from mp_messages (nolock) 
		where to_cont = @ContactId and convert(date,message_date) = convert(date,getutcdate()) and message_read = 0
		and message_subject is not null and message_descr is not null
		/* Mar 16, 2022 : New bubble for notification when user login in application - DB*/
		and message_type_id in (select message_type_id from mp_mst_message_types (NOLOCK) where IsNotification = 1)
		/* */
		Union All
		------------------------ RE QUOTE RFQ ---------------------------
		--M2-1536 Change and Activate the M Dashboard tile buttons - DB--
		select 'RE_QUOTE_RFQ' as RFQTypes , count(distinct a.rfq_id)  as RFQCount 
		from mp_messages (nolock) a
		join 
		(
			select a.rfq_id , a.is_rfq_resubmitted  
			from mp_rfq_quote_supplierquote (nolock) a
			join
			(
				select rfq_id , max(rfq_quote_SupplierQuote_id) rfq_quote_SupplierQuote_id 
				from mp_rfq_quote_supplierquote (nolock) a
				where contact_id = @ContactId
				group by rfq_id
			) b on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id

		) b on a.rfq_id = b.rfq_id and b.is_rfq_resubmitted = 1
		where a.to_cont = @ContactId and convert(date,message_date) = convert(date,getutcdate()) 
		and  message_type_id =208 

		Union All
		-----------------------Un-viewed Magic Leads--------------------------------------
		--M2-1919: M - Dashboard - Modify the Orange Special Invites tile for Magic Leads List
		select 
			distinct 'UN_VIEWED_MAGIC_LEADS' as RFQTypes, count(1) AS RFQCount
		from mp_magic_leads (nolock) a
		left join
		( 
			select distinct a.company_id as supplier_company_id , b.companyid_profile as buyer_company_id 
			from mp_contacts		(nolock) a 
			join mp_viewedprofile	(nolock) b on a.contact_id = b.contactid
			where b.contactid = @ContactId
		) b  on a.supplier_company_id = b.supplier_company_id and a.buyer_company_id = b.buyer_company_id
		where a.supplier_company_id = @CompanyId and is_expired= 0 and b.buyer_company_id is null
	
				
	END
	


		
 
END
