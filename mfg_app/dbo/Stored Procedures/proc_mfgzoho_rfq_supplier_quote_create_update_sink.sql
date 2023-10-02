
CREATE procedure [dbo].[proc_mfgzoho_rfq_supplier_quote_create_update_sink]
as
begin
/*
    M2-1681 Zoho Supplier Quote module Create Sync (records from MFG Db to Zoho CRM.) - DB  -- insert and update
	M2-1842 Supplier Quote job update for "Quote created date"- DB
*/

set nocount on
declare @todaydate datetime = getutcdate()
declare @lastidentity int

 drop table if exists #tmp_mfg_rfq_supplier_quote_not_exists -- this is for newly created rfq id
 drop table if exists #tmp_mfg_rfq_supplier_quote_exists     -- this is for rfq details are available in both database MFG and zoho
 drop table if exists #tmp_rfq_discipline
 drop table if exists #tmp_inserted_quote_id
 drop table if exists #tmp_msg_update

declare @rfq_log_details table
    (
        oldfieldvalue                   nvarchar(max),
        newfieldvalue                   nvarchar(max),
        table_name                      varchar(100),
        fieldname                       varchar(100),
        tranmode                        varchar(15),
        rfq_id                          varchar(100),
        quote_id                        varchar(100)
    )

  /* getting information on old and new values from both the databases (MFG and Zoho) */
    declare @rfq_quote_updatesync_log table
    (
        mfg_zoho_rfq_id                 nvarchar(100),
        mfg_zoho_quote_id               nvarchar(100),
        mfg_total_parts                 nvarchar(100),
        zoho_total_parts                nvarchar(100),
        mfg_discipline_level0           nvarchar(max),
        zoho_discipline_level0          nvarchar(max),
        mfg_discipline_level1           nvarchar(max),
        zoho_discipline_level1          nvarchar(max),
        mfg_discipline_level2           nvarchar(max),
        zoho_discipline_level2          nvarchar(max),
        mfg_total_price                 nvarchar(100),
		zoho_total_price                nvarchar(100),
		mfg_is_parts_made_in_us         varchar(10),
		zoho_parts_made_in_USA          varchar(10),
		mfg_comment                     nvarchar(max),
		zoho_comment                    nvarchar(max),
		mfg_quote_reference_number      nvarchar(max),
		zoho_name						nvarchar(max),
		mfg_quote_date					varchar(50),    
		zoho_quote_created_date			varchar(50),
        table_name                      varchar(100)
		 
    )

   /* load companies discipline_level*/
   select
       mr.rfq_id as rfq_num
       , (select childid from dbo.fn_rfq_discipline (mp.part_category_id, 0))  as discipline_level0
       , (select childid from dbo.fn_rfq_discipline (mp.part_category_id, 1))  as discipline_level1
       , (select childid from dbo.fn_rfq_discipline (mp.part_category_id, 2))  as discipline_level2
   into #tmp_rfq_discipline
   from
   mp_companies mcom (nolock)
   join mp_contacts mcon (nolock) on mcom.company_id = mcon.company_id
   join mp_rfq mr (nolock) on mcon.contact_id = mr.contact_id
   left join mp_rfq_parts mrp (nolock) on mr.rfq_id = mrp.rfq_id
   left join mp_parts mp  (nolock) on mrp.part_id = mp.part_id
   /* */
   
   /* getting not exist quote id */
   select  rfq_quote_SupplierQuote_id  , c.rfq_id, c.rfq_guid
   into #tmp_inserted_quote_id
   from  mp_rfq_quote_SupplierQuote(nolock) a
   join mp_rfq(nolock) c on a.rfq_id = c.rfq_id
   where not exists (select quote_id from zoho..zoho_supplierquotes(nolock) b  where b.quote_id = a.rfq_quote_SupplierQuote_id and b.synctype = 1)
   /* */

   /* Here need to update mp_messages, those records where trash = 0 and message_type_id = 220 getting multiple time for rfq_id */
   select message_id
   into #tmp_msg_update from
   (
    select message_id
    ,ROW_NUMBER() over(partition by rfq_id,from_cont,trash order by message_id desc) rn
    from mp_messages m (nolock)  where message_type_id = 220 and  trash = 0
   ) abc where rn = 2
   
   if (select count(1) from #tmp_msg_update(nolock)) > 0
   begin
    update mp_messages
    set trash = 1
    ,from_trash_date = @todaydate
    from mp_messages a (nolock) 
    join #tmp_msg_update b on a.message_id = b.message_id
   end
   /* */

   /* fetching mfg rfq details which are not in zoho table zoho_rfq*/
   select distinct a.rfq_id,a.rfq_quote_SupplierQuote_id,is_parts_made_in_us,quote_reference_number
  ,message_descr as mfg_comment ,a.contact_id ,totalprice,rfq_part_count
  , g.discipline_level0
  ,h.discipline_level1
  ,i.discipline_level2
  ,j.rfq_guid
  ,a.quote_date
  into #tmp_mfg_rfq_supplier_quote_not_exists
  from  mp_rfq_quote_SupplierQuote(nolock) a
  left join mp_rfq_quote_items(nolock) b on b.rfq_quote_SupplierQuote_id = a.rfq_quote_SupplierQuote_id
  left join
  (
   select p.message_descr, p.rfq_id, p.from_cont,p.message_type_id
   from mp_messages(nolock) p
   left join mp_mst_message_types(nolock) q on q.message_type_id =  p.message_type_id
   left join mp_rfq_quote_SupplierQuote (nolock)  r on r.contact_id = p.from_cont
   where q.message_type_id = 220 and p.trash = 0
  ) c on c.rfq_id = a.rfq_id and c.from_cont = a.contact_id
  left join
  (
   select rfq_id ,contact_id, sum (isnull(per_unit_price,0) +isnull(tooling_amount,0)+ isnull(miscellaneous_amount,0)+ isnull(shipping_amount,0)) as [totalprice]
   from mp_rfq_quote_SupplierQuote(nolock)  a
   join mp_rfq_quote_items b (nolock) on  a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id
   group by rfq_id ,contact_id
  ) e on e.rfq_id = a.rfq_id and  e.contact_id = a.contact_id
  left join
  (
    select rfq_id , count(rfq_part_id) rfq_part_count from mp_rfq_parts(nolock) group by rfq_id
  ) f on f.rfq_id = a.rfq_id
   left join
    (
     select
      mr.rfq_id
      ,STUFF((SELECT distinct ',' + convert(varchar,discipline_level0 )
     from #tmp_rfq_discipline
     where rfq_num = mr.rfq_id
     FOR XML PATH('')), 1, 1, '') AS discipline_level0
     from mp_rfq mr
    ) g on g.rfq_id = a.rfq_id
    left join
    (
     select
      mr1.rfq_id
      ,STUFF((SELECT distinct ',' + convert(varchar,discipline_level1 )
     from #tmp_rfq_discipline
     where rfq_num = mr1.rfq_id
     FOR XML PATH('')), 1, 1, '') AS discipline_level1
     from mp_rfq mr1
    ) h on h.rfq_id = a.rfq_id
    left join
    (
     select
      mr2.rfq_id
      ,STUFF((SELECT distinct ',' + convert(varchar,discipline_level2 )
     from #tmp_rfq_discipline
     where rfq_num = mr2.rfq_id
     FOR XML PATH('')), 1, 1, '') AS discipline_level2
     from mp_rfq mr2
    ) i on i.rfq_id = a.rfq_id
  join #tmp_inserted_quote_id(nolock) j on j.rfq_id = a.rfq_id
  where  a.rfq_quote_SupplierQuote_id in
     (
      select rfq_quote_SupplierQuote_id from #tmp_inserted_quote_id(nolock)
      )
	
     if (select count(1) from #tmp_mfg_rfq_supplier_quote_not_exists(nolock) ) > 0
          begin
            begin try
               begin transaction
                       /* inserting into zoho table zoho_supplierquotes from MFG dB */
                    merge zoho..zoho_supplierquotes as target
                    using #tmp_mfg_rfq_supplier_quote_not_exists as source on
                     (target.Quote_ID = source.rfq_quote_SupplierQuote_id)
                    when not matched then
                        insert (rfq_id,Quote_ID,supplier_id,total_parts,mfg_discipline,mfg_1st_discipline
						,mfg_2nd_discipline,total_price,parts_made_in_USA,comments,[name] ,supplier_quote_url,quote_created_date
						,created_time,  synctype, issync)
                        values (source.rfq_id,source.rfq_quote_SupplierQuote_id,source.contact_id,source.rfq_part_count
						,source.discipline_level0,source.discipline_level1,source.discipline_level2
						,source.totalprice,source.is_parts_made_in_us,source.mfg_comment,source.quote_reference_number,source.rfq_guid,source.quote_date
                        ,@todaydate,1,0);

                         insert into zoho..zoho_sink_down_job_running_logs (zoho_module_id,job_date,job_status)
                         select 11 zoho_module_id , @todaydate , 'success : Supplier quotes RFQ create sync'

                commit
            end try

            begin catch
			rollback
					insert into zoho..zoho_sink_down_job_running_logs
					 (zoho_module_id,job_date,job_status)
					 select 11 zoho_module_id , @todaydate , 'fail : Supplier quotes RFQ create sync' + error_message()
					 set @lastidentity = @@identity

					 insert into zoho..zoho_sink_down_job_running_logs_detail (job_running_id , zoho_id)
					 select @lastidentity , rfq_id as company_zoho_id  from #tmp_mfg_rfq_supplier_quote_not_exists (nolock)
            end catch
          end
          else
          begin
                     insert into zoho..zoho_sink_down_job_running_logs (zoho_module_id,job_date,job_status)
                     select 11 zoho_module_id , @todaydate , 'No records found for supplier quotes RFQ create sync'
          end

   /* fetching mfg rfq supplier quote details which are exist in MFG and zoho databse table*/
   select distinct a.rfq_id,a.rfq_quote_SupplierQuote_id,is_parts_made_in_us,quote_reference_number
  ,message_descr as mfg_comment ,a.contact_id ,totalprice,rfq_part_count
  ,g.discipline_level0
  ,h.discipline_level1
  ,i.discipline_level2
  ,a.quote_date
  into #tmp_mfg_rfq_supplier_quote_exists
  from  mp_rfq_quote_SupplierQuote(nolock) a
  left join mp_rfq_quote_items(nolock) b on b.rfq_quote_SupplierQuote_id = a.rfq_quote_SupplierQuote_id
  left join
  (
   select p.message_descr, p.rfq_id, p.from_cont,p.message_type_id
   from mp_messages(nolock) p
   left join mp_mst_message_types(nolock) q on q.message_type_id =  p.message_type_id
   left join mp_rfq_quote_SupplierQuote (nolock) r on r.contact_id = p.from_cont
   where q.message_type_id = 220 and p.trash = 0
  ) c on c.rfq_id = a.rfq_id and c.from_cont = a.contact_id
  left join
  (
   select rfq_id ,contact_id, sum (isnull(per_unit_price,0) +isnull(tooling_amount,0)+ isnull(miscellaneous_amount,0)+ isnull(shipping_amount,0)) as [totalprice]
   from mp_rfq_quote_SupplierQuote(nolock)  a
   join mp_rfq_quote_items (nolock) b on  a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id
   group by rfq_id ,contact_id
  ) e on e.rfq_id = a.rfq_id and  e.contact_id = a.contact_id
  left join
  (
    select rfq_id , count(rfq_part_id) rfq_part_count from mp_rfq_parts(nolock) group by rfq_id
  ) f on f.rfq_id = a.rfq_id
   left join
    (
     select
      mr.rfq_id
      ,STUFF((SELECT distinct ',' + convert(varchar,discipline_level0 )
     from #tmp_rfq_discipline
     where rfq_num = mr.rfq_id
     FOR XML PATH('')), 1, 1, '') AS discipline_level0
     from mp_rfq mr
    ) g on g.rfq_id = a.rfq_id
    left join
    (
     select
      mr1.rfq_id
      ,STUFF((SELECT distinct ',' + convert(varchar,discipline_level1 )
     from #tmp_rfq_discipline
     where rfq_num = mr1.rfq_id
     FOR XML PATH('')), 1, 1, '') AS discipline_level1
     from mp_rfq mr1
    ) h on h.rfq_id = a.rfq_id
    left join
    (
     select
      mr2.rfq_id
      ,STUFF((SELECT distinct ',' + convert(varchar,discipline_level2 )
     from #tmp_rfq_discipline
     where rfq_num = mr2.rfq_id
     FOR XML PATH('')), 1, 1, '') AS discipline_level2
     from mp_rfq mr2
    ) i on i.rfq_id = a.rfq_id
    where  a.rfq_quote_SupplierQuote_id in
      (
       select Quote_ID from zoho.dbo.zoho_supplierquotes (nolock) where synctype = 1 and isnull(zoho_id,0) != 0 --isnull(isprocessed,0) = 0
      )
	
   if (select count(1) from #tmp_mfg_rfq_supplier_quote_exists(nolock) ) > 0
   begin
      begin try
         begin transaction

    /* Updating users records into zoho_user_accounts from MFG dB */
    merge zoho..zoho_supplierquotes as target
       using #tmp_mfg_rfq_supplier_quote_exists as source on
       (target.quote_id = source.rfq_quote_SupplierQuote_id and target.supplier_id = source.contact_id
	   and source.rfq_id = source.rfq_id and target.synctype = 1)
       when matched
       and (
       isnull(target.total_parts,'')			   != source.rfq_part_count
       or isnull(target.mfg_discipline,'')         != source.discipline_level0
       or isnull(target.mfg_1st_discipline,'')     != source.discipline_level1
       or isnull(target.mfg_2nd_discipline,'')     != source.discipline_level2
       or isnull(target.total_price,'')            != cast(source.totalprice as varchar(100))
       or isnull(target.parts_made_in_USA,'')      != source.is_parts_made_in_us
       or isnull(target.comments,'')               != source.mfg_comment
       or isnull(target.name,'')                   != source.quote_reference_number
	   or isnull(target.quote_created_date,'')     != source.quote_date  
            ) then
       update set
       target.total_parts					= source.rfq_part_count
       ,target.mfg_discipline				= source.discipline_level0
       ,target.mfg_1st_discipline			= source.discipline_level1
       ,target.mfg_2nd_discipline			= source.discipline_level2
       ,target.total_price					= source.totalprice
       ,target.parts_made_in_USA			= source.is_parts_made_in_us
       ,target.comments						= source.mfg_comment
       ,target.name							= source.quote_reference_number
	   ,target.quote_created_date			= source.quote_date  
       ,target.Modified_Time				= @todaydate
       output
       source.rfq_id                        as mfg_rfq_id,
	   source.rfq_quote_SupplierQuote_id    as mfg_zoho_quote_id,
       inserted.total_parts                 as mfg_total_parts,
       deleted.total_parts					as zoho_total_parts,
       inserted.mfg_discipline				as mfg_discipline_level0,
       deleted.mfg_discipline				as zoho_discipline_level0,
       inserted.mfg_1st_discipline			as mfg_discipline_level1,
       deleted.mfg_1st_discipline			as zoho_discipline_level1,
       inserted.mfg_2nd_discipline			as mfg_discipline_level2,
       deleted.mfg_2nd_discipline			as zoho_discipline_level2,
       inserted.total_price					as mfg_total_price,
       deleted.total_price                  as zoho_total_price,
       inserted.parts_made_in_USA           as mfg_is_parts_made_in_us,
       deleted.parts_made_in_USA            as zoho_parts_made_in_USA,
       inserted.comments                    as mfg_comment,
       deleted.comments                     as zoho_comment,
       inserted.name                        as mfg_quote_reference_number,
       deleted.name                         as zoho_name,
	   inserted.quote_created_date			as mfg_quote_date,       
       deleted.quote_created_date			as zoho_quote_created_date,
       'zoho_supplierquotes'                as table_name
       into @rfq_quote_updatesync_log;

                if (select count(1) from @rfq_quote_updatesync_log ) > 0
                Begin
                    insert  into @rfq_log_details (oldfieldvalue,newfieldvalue,table_name,fieldname,tranmode,rfq_id,quote_id)
                    select oldfieldid,newfieldid,table_name,fieldname,transactionmode,mfg_zoho_rfq_id,mfg_zoho_quote_id
                    from(
                        select isnull(zoho_total_parts,'') as oldfieldid , mfg_total_parts as newfieldid , table_name, 'total_parts' as fieldname,'update' transactionmode , mfg_zoho_rfq_id, mfg_zoho_quote_id  from @rfq_quote_updatesync_log
                       union all
                        select isnull(zoho_discipline_level0,'') as oldfieldid , mfg_discipline_level0 as newfieldid , table_name, 'mfg_discipline' as fieldname,'update' transactionmode , mfg_zoho_rfq_id , mfg_zoho_quote_id  from @rfq_quote_updatesync_log
                       union all
                        select isnull(zoho_discipline_level1,'') as oldfieldid , mfg_discipline_level1 as newfieldid , table_name, 'mfg_1st_discipline' as fieldname,'update' transactionmode , mfg_zoho_rfq_id , mfg_zoho_quote_id  from @rfq_quote_updatesync_log
                       union all
                        select isnull(zoho_discipline_level2,'') as oldfieldid , mfg_discipline_level2 as newfieldid , table_name, 'mfg_2nd_discipline' as fieldname,'update' transactionmode , mfg_zoho_rfq_id, mfg_zoho_quote_id  from @rfq_quote_updatesync_log
                       union all
                        select isnull(zoho_total_price ,'') as oldfieldid , mfg_total_price as newfieldid , table_name, 'total_price' as fieldname,'update' transactionmode , mfg_zoho_rfq_id  , mfg_zoho_quote_id from @rfq_quote_updatesync_log
                       union all
                        select isnull(zoho_parts_made_in_USA,'') as oldfieldid , mfg_is_parts_made_in_us as newfieldid , table_name, 'parts_made_in_USA' as fieldname,'update' transactionmode , mfg_zoho_rfq_id , mfg_zoho_quote_id from @rfq_quote_updatesync_log
                       union all
                        select isnull(zoho_comment,'') as oldfieldid , mfg_comment as newfieldid , table_name, 'comments' as fieldname,'update' transactionmode , mfg_zoho_rfq_id ,mfg_zoho_quote_id from @rfq_quote_updatesync_log
                       union all
                        select isnull(zoho_name,'') as oldfieldid , mfg_quote_reference_number as newfieldid , table_name, 'name' as fieldname,'update' transactionmode , mfg_zoho_rfq_id ,mfg_zoho_quote_id from @rfq_quote_updatesync_log
					   union all  
						select isnull(zoho_quote_created_date,'') as oldfieldid , mfg_quote_date as newfieldid , table_name, 'quote_created_date' as fieldname,'update' transactionmode , mfg_zoho_rfq_id ,mfg_zoho_quote_id from @rfq_quote_updatesync_log
                       )  abc
                    where oldfieldid != newfieldid
					
     /* creating log for updated records */
     insert into zoho..zoho_sink_down_logs
	 (zoho_module_id,company_id,company_zoho_id,log_date,table_name,field_name,oldfieldvalue,newfieldvalue,transaction_mode,user_contact_id,user_zoho_id,rfq_id)
     select  11 as zoho_module_id, null ,null , @todaydate,a.table_name,a.fieldname
     ,a.oldfieldvalue,a.newfieldvalue,a.tranmode,null,null,rfq_id from @rfq_log_details a
     /* */

    /* update for account */
    select distinct quote_id
    into #update_zoho_supplierquotes_list
    from @rfq_log_details

    update a
    set  a.IsSync = 0
    ,a.IsProcessed = null
    ,a.SyncDatetime = null
    ,a.ProcessedDatetime = null
    ,a.Modified_Time = @todaydate
    from zoho..zoho_supplierquotes a
    join #update_zoho_supplierquotes_list b on a.quote_id = b.quote_id
    where a.synctype = 1;
    /* */

    insert into zoho..zoho_sink_down_job_running_logs (zoho_module_id,job_date,job_status)
    select 11 zoho_module_id , @todaydate , 'success : Supplier quotes RFQ update sync'

    end
    else
    begin
         insert into zoho..zoho_sink_down_job_running_logs (zoho_module_id,job_date,job_status)
       select 11 zoho_module_id , @todaydate , 'No records found for supplier quote RFQ update sync'
    end

    commit
    end try
	begin catch
            rollback
	insert into zoho..zoho_sink_down_job_running_logs
    (zoho_module_id,job_date,job_status)
    select 11 zoho_module_id , @todaydate , 'fail : RFQ update sync ' + error_message()
	set @lastidentity = @@identity

     select distinct rfq_id
     into #update_error_rfq_list
     from #tmp_mfg_rfq_supplier_quote_exists

     insert into zoho..zoho_sink_down_job_running_logs_detail (job_running_id , zoho_id)
     select @lastidentity , rfq_id as company_zoho_id     from #update_error_rfq_list(nolock)

     ----here updated those records having some data issue to update the records
     update c set c.isprocessed = 1 , c.syncdatetime = null
     from zoho.dbo.zoho_sink_down_job_running_logs(nolock) a
     join zoho.dbo.zoho_sink_down_job_running_logs_detail(nolock) b on a.job_running_id = b.job_running_id
     join zoho..zoho_supplierquotes(nolock) c on b.zoho_id = c.rfq_id
     join #update_error_rfq_list d on d.rfq_id = c.rfq_id
     where a.job_running_id = @lastidentity
     and synctype = 1 and isnull(issync,0) = 0 and isnull(isprocessed,0) = 0

   end catch
   end
   else
   begin
     insert into zoho..zoho_sink_down_job_running_logs (zoho_module_id,job_date,job_status)
     select 11 zoho_module_id , @todaydate , 'No records found for supplier quote RFQ update sync.'

   end
   
end
