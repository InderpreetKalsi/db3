  
    
  
   
-- exec proc_get_buyer_open_rfqs_count @buyer_contact_id  = 1337872  ,@supplier_contact_id  = 1337866  
CREATE procedure [dbo].[proc_get_buyer_open_rfqs_count]  
(  
 @buyer_contact_id int  
 ,@supplier_contact_id int  
)  
as  
begin  
  
 /* M2-1861  M - Buyer Profile - Add the number of RFQ's the buyer has open to the profile and make a clickable link */  
  
 set nocount on  
  
 declare @company_name varchar(250)  
 declare @supplier_company_id int   
 declare @supplier_manufacturing_location int   
  
 /* M2-2429 */  
 drop table if exists #supplier_manufacturing_location  
 /**/  
 /* M2-2429 */  
 create table #supplier_manufacturing_location  (territory_id int)  
  
 set @supplier_manufacturing_location =   
 (  
  select top 1 manufacturing_location_id from mp_companies a (nolock) join mp_contacts b (nolock) on a.company_id = b.company_id where b.contact_id = @supplier_contact_id  
 )  
  
 if @supplier_manufacturing_location in  (4)  
 begin  
  insert into #supplier_manufacturing_location (territory_id) values (4),(7)  
 end  
 else if @supplier_manufacturing_location in  (5)  
 begin  
  insert into #supplier_manufacturing_location (territory_id) values (5),(7)  
 end  
 else if @supplier_manufacturing_location in  (7)  
 begin  
  insert into #supplier_manufacturing_location (territory_id) values (4),(5),(7)  
 end  
 else  
 begin  
  insert into #supplier_manufacturing_location (territory_id) values (@supplier_manufacturing_location)  
 end  
 /**/  
   
   
 select @company_name = name    
 from mp_companies (nolock) a   
 join mp_contacts (nolock) b on a.company_id = b.company_id and b.contact_id = @buyer_contact_id  
  
 select count(1) open_rfqs , @company_name as company_name   
 from mp_rfq (nolock)  a  
 join mp_rfq_supplier (nolock) b on a.rfq_id = b.rfq_id and b.company_id = -1  
 /* M2-2429 */  
 join mp_rfq_preferences o (nolock) on  b.rfq_id = o.rfq_id   
 /**/  
 where   
 rfq_status_id = 3 and contact_id = @buyer_contact_id  
 and quotes_needed_by is not null  
 /* M2-2429 */  
 and o.rfq_pref_manufacturing_location_id in  (select * from #supplier_manufacturing_location)  
 /**/  

 drop table if exists #supplier_manufacturing_location   
end  