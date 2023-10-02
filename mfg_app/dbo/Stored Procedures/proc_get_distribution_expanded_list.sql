/*
M2-3320 Buyer - Hide the children contacts under the parent on the Insight tab - DB

EXEC [proc_get_DistributionDetailList] 
@RfqId=1191464
,@PageNumber=1
,@PageSize=200
,@sortby=N''
,@isorderbydesc=0
,@searchtext=N''
,@filterby=N''

EXEC [proc_get_distribution_expanded_list] 
@RfqId=1191464
,@CompanyId=1768018
,@ContactId=1337848


*/
CREATE procedure [dbo].[proc_get_distribution_expanded_list]  
  @RfqId INT,
  @CompanyId INT,     
  @ContactId INT  
AS  
BEGIN   

	/* M2-3320 Buyer - Hide the children contacts under the parent on the Insight tab - DB */

	set nocount on   
  

	select * ,  count(1) over () TotalCount 
	from 
	(
		select 
			distinct
			b.name				as CompanyName
			,b.company_id		as CompanyId
			,b.CompanyURL		as CompanyUrl
			,d.territory_classification_name as ManufacturingLocation 
			,e.communication_value    as PhoneNo
			,f.no_of_stars			as NoOfStars 
			,
			case    
				when awarded.company_id is not null then 'Awarded'        
				when g.is_quote_submitted = 1		then 'Quoted'   
				when h.rfq_userStatus_id = 2		then 'Mark for Quoting'  
				when i.supplier_id is not null		then 'Reviewed'  
				else 'Not reviewed'      
			end as Status  
			,c.contact_id		as ContactId
			,isqmsenable		as IsQMSEnable
			,contact			as Contact
			,j.email			as Email
		from 
		(
			select 
				company_id , name , manufacturing_location_id ,CompanyURL , is_mqs_enable as isqmsenable
			from mp_companies	(nolock) 
			where company_id = @CompanyId
		) b 
		join 
		(
			select contact_id , company_id   , first_name +' '+last_name as contact , user_id from mp_contacts	(nolock) 
		)	c on b.company_id = c.company_id and c.contact_id  <>  @ContactId
		left join mp_mst_territory_classification				(nolock)	d on b.manufacturing_location_id =  d.territory_classification_id  
		left join mp_communication_details						(nolock)	e on c.contact_id  = e.contact_id and e.communication_type_id = 1 
		left join mp_star_rating								(nolock)	f on b.company_id = f.company_id      
		left join 
		(
			select distinct b.company_id , a.is_quote_submitted
			from mp_rfq_quote_supplierquote (nolock) a  
			join mp_contacts				(nolock) b on a.contact_id = b.contact_id  and a.rfq_id = @RfqId 
			and a.is_rfq_resubmitted = 0   
			and a.is_quote_submitted = 1 
		) g on b.company_id = g.company_id
		left join 
		(
			select distinct b.company_id , a.rfq_userStatus_id
			from mp_rfq_quote_suplierstatuses	(nolock) a
			join mp_contacts					(nolock) b  on a.contact_id = b.contact_id  and a.rfq_id= @RfqId
		) h on b.company_id = h.company_id
		left join 
		(
			select distinct b.company_id , a.supplier_id
			from mp_rfq_supplier_read			(nolock) a
			join mp_contacts					(nolock) b  on a.supplier_id = b.contact_id  and a.rfq_id= @RfqId
		) i on b.company_id = i.company_id
		left join   
		(  
			select distinct  c.company_id   
			from mp_rfq_quote_supplierquote a (nolock)  
			join mp_rfq_quote_items			b (nolock)  on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id 
				and a.rfq_id = @RfqId 
				and a.is_rfq_resubmitted = 0  
				and is_awrded = 1  
			join mp_contacts				c (nolock) on a.contact_id = c.contact_id   
		) awarded on b.company_id = awarded.company_id 
		join aspnetusers			j (nolock) on 	c.user_id = j.id	 		
	) a
	order by   a.CompanyName , a.ContactId
	
    
END
