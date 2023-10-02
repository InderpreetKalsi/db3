

CREATE  procedure [dbo].[proc_get_subscriptions_report]
    @ContactId INT,
    @CompanyId INT
AS
begin

set nocount on
drop table if exists ##mfg_company_subscription_supplier_details

if (@ContactId is not null or @ContactId = '' ) and (@CompanyId is not null or @CompanyId = '')
begin

 /* fetching account users communication details above account users in tmp table  */
        select
             contact_id  , [Telephone]   , [Fax]
        into #tmp_communication_details
        from
        (
          select  contact_id ,
            case
                when communication_type_id = 1 then 'Telephone'
                when communication_type_id = 2 then 'Fax'

            end as communication_type
            , isnull(communication_clean_value, communication_value) communication_value
          from  mp_communication_details
          where contact_id = @ContactId 
        ) x
        pivot
        (
          max(communication_value)
          for communication_type in([Telephone], [Fax])
        )p 


    select company_id, contact_id, assigned_sourcingadvisor,[cust_representative],[company_name],title,[contact_name]
,city,[state],country_name,zip,[email],[phonenumber],[fax],[streetaddress],[subscription_start_date],[subscription_end_date]
,[customer_id],manufacturing_location,agrementnumber,membershiptotal,totalusd,NumberOfUsers
   into ##mfg_company_subscription_supplier_details
   from (
    select b.company_id, c.contact_id, b.Assigned_SourcingAdvisor, concat(xyz.first_name,' ' + xyz.last_name) [cust_representative], b.name [company_name],c.title [title] 
    , concat(c.first_name,' ', c.last_name) [contact_name]
    ,address4 AS city    , case when ( f.REGION_ID = 0 ) then 'N/A' else f.REGION_NAME  end AS [state]
    , case when (g.country_id = 0 ) then 'N/A' else g.country_name  end AS country_name
    ,d.address3 as zip,e.email [email],h.[Telephone] [phonenumber], h.[Fax] [fax]
    ,concat(d.address1, ' ' , d.address2) as[streetaddress]
    ,a.subscription_start_date [subscription_start_date]
    ,a. subscription_end_date [subscription_end_date]
    ,a.customer_id [customer_id]
	,territory_classification_name as [manufacturing_location]
	,a.zoho_subscription_id [agrementnumber]
	,a.membership_total_amount [membershiptotal]
	,a.invoice_total_amount [totalusd]
    ,row_number() over (partition by b.company_id, c.contact_id order by zoho_subscription_id desc, zoho_company_subscription_id desc) [RN]
	,null as NumberOfUsers
    from  [dbo].[mp_company_subscriptions](nolock) a
    join mp_companies (nolock) b on a.account_zoho_id = b.company_zoho_id
    --join mp_contacts (nolock) c on a.zoho_id = c.user_zoho_id
	 join mp_contacts (nolock) c on b.company_id = c.company_id 
	join aspnetusers (nolock) e on c.user_id = e.id
    left join mp_addresses(nolock) d on d.address_id = c.address_id
    left join mp_mst_region  (nolock) f ON d.region_id = f.REGION_ID
    left join mp_mst_country  (nolock) g ON f.country_Id = g.country_id
    left join #tmp_communication_details h on h.contact_id =  c.contact_id
   	left join mp_mst_territory_classification j on j.territory_classification_id = b.Manufacturing_location_id
    left join    ( select a1.company_id, b1.contact_id,b1.first_name,b1.last_name
             from mp_companies (nolock) a1
            join mp_contacts (nolock) b1 on a1.Assigned_SourcingAdvisor = b1.contact_id
        ) xyz on xyz.company_id = b.company_id
    ) abc
     where RN = 1 and  abc.company_id = @CompanyId
     and abc.contact_id = @ContactId

     /* --Getting result set 1 for header section */
     select company_id,contact_id,assigned_sourcingadvisor,[cust_representative],company_name,title,contact_name
     ,city,[state],country_name,zip,email,phonenumber,fax,streetaddress,subscription_start_date,subscription_end_date,customer_id
	 ,manufacturing_location,agrementnumber,membershiptotal,totalusd,NumberOfUsers
     from ##mfg_company_subscription_supplier_details
     /* */



  /* payment section  */----
  select  invoice_date,[invoice_number],b.reference_number [ref_number],b.amount [amount],[status] from
  (
  select a.invoice_id, a.invoice_date,a.number [invoice_number],a.[status]
    ,row_number() over (partition by a.customer_id  order by invoice_id desc) [RN]
  from mp_companies_invoice(nolock) a
   join ##mfg_company_subscription_supplier_details (nolock) c on a.customer_id = c.customer_id
  ) abc
  join mp_invoice_payments(nolock) b on abc.invoice_id = b.invoiceId
   where [RN] = 1
    /* */

    /* categories section  */----
    select c.discipline_name
    from ##mfg_company_subscription_supplier_details (nolock) a
    join mp_company_processes(nolock) b on a.company_id = b.company_id
    join mp_mst_part_category (nolock) c on c.part_category_id = b.part_category_id
    /* */


    end
 end
