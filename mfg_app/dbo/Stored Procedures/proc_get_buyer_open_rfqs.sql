/*  
declare @totalrec int   
declare @p9 dbo.tbltype_ListOfProcesses  
--insert into @p9 values(100000)  
  
exec proc_get_buyer_open_rfqs   
 @buyer_contact_id  = 1337872  
 ,@supplier_contact_id  = 1337866  
 ,@pageno    = 1  
 ,@pagesize    = 25  
 ,@searchtext   = ''   
 ,@is_orderby_desc  = 'true'  
 ,@orderby    = 'material'  
 ,@processids   = @p9  
 ,@total_rec    = @totalrec output  
  
select @totalrec  
 
*/  
  
  
CREATE procedure [dbo].[proc_get_buyer_open_rfqs]  
(  
 @buyer_contact_id int  
 ,@supplier_contact_id int  
 ,@pageno   int = 1  
 ,@pagesize   int = 25  
 ,@searchtext  varchar(150) = null   
 ,@processids  as tbltype_ListOfProcesses readonly  
 ,@is_orderby_desc bit ='true'  
 ,@orderby   varchar(150) = null  
 ,@total_rec   int output  
)  
as  
begin  
 /* M2-2031 M - Buyer Profile - Add the number of RFQ's the buyer has open to the profile and make a clickable link - DBk */  
 /* Dec 10 2019 - M2-2429 M - Urgent Bug - M's should only be able to see RFQ's in their region */  
 set nocount on  
   
 declare @supplier_manufacturing_location int   
   
 drop table if exists #rfq_list_based_on_processlist  
 drop table if exists #rfq_list_based_on_searchtext  
 /* M2-2429 */  
 drop table if exists #supplier_manufacturing_location  
 /**/  
  
 create table #rfq_list_based_on_processlist (rfq_id int)  
 create table #rfq_list_based_on_searchtext (rfq_id int)  
   
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
   
   
  
 if (@orderby is null or @orderby = '' )  
  set @orderby  = 'release_date'  
  
  
 if ((select count(1) from @processids ) > 0)  
 begin  
  insert into #rfq_list_based_on_processlist (rfq_id)  
  select distinct a.rfq_id   
  from mp_rfq     (nolock) a   
  join mp_rfq_parts   (nolock) b  on a.rfq_id = b.rfq_id   
  join mp_parts     (nolock) c on b.part_id  = c.part_id  
  where   
   rfq_status_id = 3   
   and a.contact_id = @buyer_contact_id   
   and b.part_category_id in  (select * from @processids)  
 end  
   
 /* M2-1924 M - In the application the search needs to be inclusive - DB */  
 if len(@searchtext) > 0  
 begin  
  insert into #rfq_list_based_on_searchtext (rfq_id)  
  select distinct a.rfq_id   
  from mp_rfq     (nolock) a   
  join mp_rfq_parts   (nolock) b  on a.rfq_id = b.rfq_id   
  join mp_parts     (nolock) c on b.part_id  = c.part_id  
  where   
   rfq_status_id = 3   
   and a.contact_id = @buyer_contact_id   
   and  
   (  
    (a.rfq_name like '%'+@searchtext+'%')   
    or   
    (a.rfq_id like '%'+@searchtext+'%')    
    or   
    (c.part_name like '%'+@searchtext+'%')  
    or    
    (c.part_number like '%'+@searchtext+'%')  
    or  
    (@SearchText is null)   
   )  
 end  
 /**/  
  
 set @total_rec =   
 (  
  select   
   count(1) as rfq_id   
  from  
  mp_rfq b       (nolock)   
  join mp_rfq_parts c     (nolock) on   
   b.rfq_id = c.rfq_id   
   and c.is_rfq_part_default = 1  
   and b.quotes_needed_by is not null  
  join mp_parts d      (nolock) on c.part_id = d.part_id  
  join mp_rfq_supplier a     (nolock) on a.rfq_id = b.rfq_id and a.company_id = -1  
  left join mp_system_parameters j (nolock) on c.post_production_process_id = j.id and j.sys_key = '@PostProdProcesses'   
  left join mp_mst_materials k  (nolock) on d.material_id = k.material_id   
  left join mp_mst_part_category l (nolock) on c.part_category_id = l.part_category_id  
  left join   
  (  
   select   
    rfq_id   
    , max(status_date) release_date   
   from mp_rfq_release_history (nolock) group by rfq_id   
  ) rfq_release on b.rfq_id = rfq_release.rfq_id  
  left join #rfq_list_based_on_processlist  m on b.rfq_id = m.rfq_id  
  left join #rfq_list_based_on_searchtext   n on b.rfq_id = n.rfq_id  
  /* M2-2429 */  
  join mp_rfq_preferences o (nolock) on  b.rfq_id = o.rfq_id   
  /**/  
  where   
   rfq_status_id = 3   
   and b.contact_id = @buyer_contact_id  
   and b.rfq_id = (case when (select count(1) from @processids) >  0 then m.rfq_id else b.rfq_id end )  
   and b.rfq_id = (case when (len(@searchtext)) >  0 then n.rfq_id else b.rfq_id end )  
   /* M2-2429 */  
   and o.rfq_pref_manufacturing_location_id in  (select * from #supplier_manufacturing_location)  
   /**/  
 )  
  
  
 select   
   b.rfq_id as rfq_id   
 from  
 mp_rfq b       (nolock)   
 join mp_rfq_parts c     (nolock) on   
  b.rfq_id = c.rfq_id   
  and c.is_rfq_part_default = 1  
  and b.quotes_needed_by is not null  
 join mp_parts d      (nolock) on c.part_id = d.part_id  
 join mp_rfq_supplier a     (nolock) on a.rfq_id = b.rfq_id and a.company_id = -1  
 left join mp_system_parameters j (nolock) on c.post_production_process_id = j.id and j.sys_key = '@PostProdProcesses'   
 left join mp_mst_materials k  (nolock) on d.material_id = k.material_id   
 left join mp_mst_part_category l (nolock) on d.part_category_id = l.part_category_id  
 left join   
 (  
  select   
   rfq_id   
   , max(status_date) release_date   
  from mp_rfq_release_history (nolock) group by rfq_id   
 ) rfq_release on b.rfq_id = rfq_release.rfq_id  
 left join #rfq_list_based_on_processlist  m on b.rfq_id = m.rfq_id  
 left join #rfq_list_based_on_searchtext   n on b.rfq_id = n.rfq_id  
 /* M2-2429 */  
 join mp_rfq_preferences o (nolock) on  b.rfq_id = o.rfq_id   
 /**/  
 where   
  rfq_status_id = 3   
  and b.contact_id = @buyer_contact_id  
  and b.rfq_id = (case when (select count(1) from @processids) >  0 then m.rfq_id else b.rfq_id end )  
  and b.rfq_id = (case when (len(@searchtext)) >  0 then n.rfq_id else b.rfq_id end )  
  /* M2-2429 */  
  and o.rfq_pref_manufacturing_location_id in  (select * from #supplier_manufacturing_location)  
  /**/  
 order by   
  case  when @is_orderby_desc =  1 and @OrderBy = 'quantity' then   c.min_part_quantity end desc     
  ,case  when @is_orderby_desc =  1 and @OrderBy = 'material' then   k.material_name_en end desc     
  ,case  when @is_orderby_desc =  1 and @OrderBy = 'process' then   l.discipline_name end desc     
  ,case  when @is_orderby_desc =  1 and @OrderBy = 'postprocess' then   j.value end desc     
  ,case  when @is_orderby_desc =  1 and @OrderBy = 'quoteby'then   b.quotes_needed_by end desc     
  ,case  when @is_orderby_desc =  1 and @OrderBy = 'release_date' then   rfq_release.release_date end desc     
  ,case  when @is_orderby_desc =  0 and @OrderBy = 'quantity' then   c.min_part_quantity end asc     
  ,case  when @is_orderby_desc =  0 and @OrderBy = 'material' then   k.material_name_en end asc     
  ,case  when @is_orderby_desc =  0 and @OrderBy = 'process' then   l.discipline_name end asc     
  ,case  when @is_orderby_desc =  0 and @OrderBy = 'postprocess' then   j.value end asc     
  ,case  when @is_orderby_desc =  0 and @OrderBy = 'quoteby'then   b.quotes_needed_by end asc     
  ,case  when @is_orderby_desc =  0 and @OrderBy = 'release_date' then   rfq_release.release_date end asc     
     
 offset @pagesize * (@pageno - 1) rows  
 fetch next @pagesize rows only  
  
   
 drop table if exists #rfq_list_based_on_processlist  
 drop table if exists #rfq_list_based_on_searchtext  
 drop table if exists #supplier_manufacturing_location   
end
