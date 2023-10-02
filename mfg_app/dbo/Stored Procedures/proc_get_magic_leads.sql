
  
/*  
exec proc_get_magic_leads @supplier_company_id = 1693766  
*/  
  
CREATE procedure [dbo].[proc_get_magic_leads]  
(  
 @supplier_company_id int  
)  
as  
begin  
 set nocount on  
 /* M2-1913 M - Magic Lead List page - DB */  
  
 drop table if exists #tmp_magic_leads  
  
 select * into #tmp_magic_leads from mp_magic_leads where supplier_company_id = @supplier_company_id and is_expired = 0  
   
 select * from  
 (  
  select distinct  
   b.contact_id  as buyer_contact_id  
   , b.company_id  as buyer_company_id  
   , d.name   as buyer_company   
   , e.no_of_stars  as no_of_stars  
   , c.address1  
   , c.address2  
   , c.address3  
   , c.address4  
   , c.address5  
   , c.country_id  as country_id  
   , f.region_name   
   , g.country_name   
   , iif(i.filetype_id=6,h.file_name, null) as company_logo   
   , j.communication_value as company_phone  
   , k.communication_value as company_web  
   , row_number () over (partition by b.company_id order by d.name ) rn  
     
  from #tmp_magic_leads   (nolock) a  
  join mp_contacts   (nolock) b on a.buyer_company_id = b.company_id --and b.is_admin =1  
  join mp_addresses   (nolock) c on b.address_id = c.address_id  
  join mp_companies   (nolock) d on b.company_id = d.company_id  
  left join mp_star_rating (nolock) e on e.company_id = d.company_id  
  left join mp_mst_region  (nolock) f on c.region_id = f.region_id  
  left join mp_mst_country (nolock) g on c.country_id = g.country_id  
  left join mp_special_files (nolock) h on d.company_id = h.comp_id and b.contact_id = h.cont_id and filetype_id = 6  
  left join mp_mst_filetype (nolock) i on (h.filetype_id = i.filetype_id)  
  left join mp_communication_details (nolock) j on d.company_id = j.company_id and  j.communication_type_id = 1  
  left join mp_communication_details (nolock) k on d.company_id = k.company_id and  k.communication_type_id = 4  
 ) a   
 where rn =1   
   
 drop table if exists #tmp_magic_leads  
end  