

-- EXEC [proc_mfgzoho_rfq_create_update_sink]
CREATE procedure [dbo].[proc_mfgzoho_rfq_create_update_sink]  
as  
begin  
/*  
    M2-1679 Zoho RFQ module Create Sync (records from MFG Db to Zoho CRM.) - DB          -- insert  
    M2-1680 Zoho RFQ module Update Sync (modified records from MFG Db to Zoho CRM.) - DB -- update  
	M2-1841 RFQ job update for field "Buyer RFQ status field" - DB

*/  
  
set nocount on  
declare @todaydate datetime = getutcdate()  
declare @lastidentity int  
DECLARE @HoursDifferenceBetweenUTCandEST  INT


  
declare @rfq_log_details table  
    (  
        oldfieldvalue      nvarchar(max),  
        newfieldvalue      nvarchar(max),  
        table_name         varchar(100),  
        fieldname          varchar(100),  
        tranmode           varchar(15),  
        rfq_id             int  
    )  
   
  /* getting information on old and new values from both the databases (MFG and Zoho) */  
    declare @rfq_updatesync_log table  
    (  
		mfg_zoho_rfq_id						int,  
		mfg_rfq_name						nvarchar(100),  
		zoho_rfq_name						nvarchar(100),  
		mfg_rfq_description					nvarchar(max),  
		zoho_rfq_description				nvarchar(max),  
		mfg_rfq_part_count					nvarchar(max),    
		zoho_part_count						nvarchar(max),  
		mfg_rfq_pref_location_id			nvarchar(max),      
		zoho_region							nvarchar(max),  
		mfg_release_date					varchar(50),    
		zoho_release_date					varchar(50),  
		mfg_closedate						varchar(50),    
		zoho_close_date						varchar(50),  
		mfg_buyer_name						nvarchar(max),   
		zoho_buyer_name						nvarchar(max),  
		mfg_assigned_sourcingadvisor		varchar(50),  
		zoho_assigned_sourcingadvisor		varchar(50),  
		mfg_rfqstatus						nvarchar(max),   
		zoho_rfq_buyerstatus_id             nvarchar(max),
		mfg_rfq_number_of_quotes			nvarchar(max),      
		zoho_number_of_quotes				nvarchar(max),  
		mfg_discipline_level0				nvarchar(max),  
		zoho_discipline_level0				nvarchar(max),  
		mfg_discipline_level1				nvarchar(max),  
		zoho_discipline_level1				nvarchar(max),  
		mfg_discipline_level2				nvarchar(max),  
		zoho_discipline_level2				nvarchar(max),  
		mfg_rfq_guid						nvarchar(200),  
		zoho_visionlink						nvarchar(200),  
		mfg_mfglegacyrfqid					nvarchar(200),  
		zoho_mfglegacyrfqid					nvarchar(200),  
		mfg_buyer_id						varchar(200),  
		zoho_buyer_id						varchar(200),  
		table_name							varchar(100)  
    )  
   

 drop table if exists #tmp_mfg_rfq_not_exists -- this is for newly created rfq id  
 drop table if exists #tmp_mfg_rfq_exists     -- this is for rfq details are available in both database MFG and zoho  
 drop table if exists #tmp_rfq_discipline  
 drop table if exists #tmp_inserted_rfq_id  
 drop table if exists #tmp_rfq_materials
 
SET @HoursDifferenceBetweenUTCandEST  = 
(
	CASE	
		WHEN (SELECT current_utc_offset FROM sys.time_zone_info WHERE name = 'Eastern Standard Time') = N'-05:00' THEN -5
		WHEN (SELECT current_utc_offset FROM sys.time_zone_info WHERE name = 'Eastern Standard Time') = N'-04:00' THEN -4
	END
)
 
 
   
   /* load companies discipline_level*/  
   select    
    mr.rfq_id as rfq_num  
    , (select childid from dbo.fn_rfq_discipline (mrp.part_category_id, 0))  as discipline_level0  
    , (select childid from dbo.fn_rfq_discipline (mrp.part_category_id, 1))  as discipline_level1  
    , (select childid from dbo.fn_rfq_discipline (mrp.part_category_id, 2))  as discipline_level2 
   into #tmp_rfq_discipline   
   from   
   mp_companies mcom (nolock)  
   join mp_contacts mcon (nolock) on mcom.company_id = mcon.company_id  
   join mp_rfq mr (nolock) on mcon.contact_id = mr.contact_id  
   left join mp_rfq_parts mrp (nolock) on mr.rfq_id = mrp.rfq_id  
   left join mp_parts mp  (nolock) on mrp.part_id = mp.part_id  
   /* */  

    /* getting not exist quote id */
		 select rfq_id
		 into #tmp_inserted_rfq_id
		 from  mp_rfq(nolock) a
		 where not exists (select rfq_number from zoho..zoho_rfq(nolock) b  where b.rfq_number = a.rfq_id and b.synctype = 1)

 	/* */
		
    /* fetching mfg rfq details which are not in zoho table zoho_rfq*/    
    select    
		a.rfq_id, isnull(a.rfq_name,convert(varchar(500),a.rfq_id)) rfq_name 
		,a.rfq_description ,  a.contact_id ,j.assigned_sourcingadvisor  
		,rfq_status_id [rfqstatus]
		--,Quotes_needed_by [CloseDate]
		,
		(
		case 			
			when rfq_pref_manufacturing_location_id = 4 then 	convert(datetime,dateadd(minute,-00,dateadd(hour,@HoursDifferenceBetweenUTCandEST,quotes_needed_by )))  
			when rfq_pref_manufacturing_location_id = 5 then  convert(datetime,dateadd(minute,-00,dateadd(hour,@HoursDifferenceBetweenUTCandEST,quotes_needed_by )))  
			when rfq_pref_manufacturing_location_id = 6 then  convert(datetime,dateadd(minute,-00,dateadd(hour,@HoursDifferenceBetweenUTCandEST,quotes_needed_by )))  
			when rfq_pref_manufacturing_location_id = 7 then 	convert(datetime,dateadd(minute,-00,dateadd(hour,@HoursDifferenceBetweenUTCandEST,quotes_needed_by ))) 
			when rfq_pref_manufacturing_location_id = 2 then 	convert(datetime,dateadd(hour,+2,quotes_needed_by )) 	
			when rfq_pref_manufacturing_location_id = 3 then 	convert(datetime,dateadd(minute,+30,dateadd(hour,+5,quotes_needed_by )))  
			else quotes_needed_by
		end
		) [CloseDate] 		
		,rfq_guid,release_date,rfq_part_count,rfq_number_of_quotes,e.first_name + ' ' + e.last_name as buyer_name  
		,rfq_pref_manufacturing_location_id  
		,g.discipline_level0  
		,h.discipline_level1  
		,i.discipline_level2  
		,e.company_id  
    into #tmp_mfg_rfq_not_exists    
    from mp_rfq (nolock) a    
    left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history(nolock) group by rfq_id ) b  on b.rfq_id = a.rfq_id     
    left join (select rfq_id , count(rfq_part_id) rfq_part_count from mp_rfq_parts(nolock) group by rfq_id ) c  on c.rfq_id = a.rfq_id  
    left join (select rfq_id , count(contact_id) rfq_number_of_quotes from  mp_rfq_quote_supplierquote(nolock) where is_quote_submitted = 1 group by rfq_id ) d on d.rfq_id = a.rfq_id    
    left join mp_contacts(nolock) e on e.contact_id =  a.contact_id  
    left join  
   (      
    select distinct  abc.rfq_id as rfq_id   
    ,case when cnt = 1 then b.rfq_pref_manufacturing_location_id else 7 end as rfq_pref_manufacturing_location_id  
     from (  
      select  rfq_id    
      ,count(rfq_pref_manufacturing_location_id) cnt  
      from mp_rfq_preferences   (nolock) 
      group by rfq_id    
    ) abc  join mp_rfq_preferences b on abc.rfq_id = b.rfq_id  
   ) f on f.rfq_id = a.rfq_id  
     left join   
   (  
    select   
     mr.rfq_id   
     ,STUFF((SELECT distinct ',' +  convert(varchar,discipline_level0 )  
    from #tmp_rfq_discipline  
    where rfq_num = mr.rfq_id  
    FOR XML PATH('')), 1, 1, '') AS discipline_level0  
    from mp_rfq mr  
   ) g on g.rfq_id = a.rfq_id  
   left join   
   (  
    select   
     mr1.rfq_id   
     ,STUFF((SELECT distinct ',' +  convert(varchar,discipline_level1 )  
    from #tmp_rfq_discipline  
    where rfq_num = mr1.rfq_id  
    FOR XML PATH('')), 1, 1, '') AS discipline_level1  
    from mp_rfq mr1  
   ) h on h.rfq_id = a.rfq_id  
   left join   
   (  
    select   
     mr2.rfq_id   
     ,STUFF((SELECT distinct ',' +  convert(varchar,discipline_level2 )  
    from #tmp_rfq_discipline  
    where rfq_num = mr2.rfq_id  
    FOR XML PATH('')), 1, 1, '') AS discipline_level2  
    from mp_rfq mr2  
   ) i on i.rfq_id = a.rfq_id  
   left join  
    (   
    select a1.company_id,a1.assigned_sourcingadvisor  
    from mp_companies (nolock) a1  
    join mp_contacts (nolock) b1 on a1.Assigned_SourcingAdvisor = b1.contact_id  
    ) j on  j.company_id = e.company_id  
    where    a.rfq_id in     
    (    
     select rfq_id from #tmp_inserted_rfq_id (nolock)
    )    
	and a.contact_id is not null   
		    
	if (select count(1) from #tmp_mfg_rfq_not_exists(nolock) ) > 0   
    begin  
   begin try   
      begin transaction  
        /* inserting into zoho table zoho_rfq from MFG dB */  
     merge zoho..zoho_rfq as target  
     using #tmp_mfg_rfq_not_exists as source on  
      (target.RFQ_Number = source.rfq_id)  
     when not matched then  
      insert (rfq_number,rfq_name,buyer_id,rfq_description,close_date,assigned_engineer,rfq_buyerstatus_id,visionlink,release_date  
      ,part_count,number_of_quotes,buyer_name,mfg_discipline,mfg_1st_discipline,mfg_2nd_discipline,region,mfglegacyrfqid  
      ,created_time,  synctype, issync)   
      values (source.rfq_id,source.rfq_name,source.contact_id, source.rfq_description  
      ,source.CloseDate,source.assigned_sourcingadvisor,source.rfqstatus,source.rfq_guid,source.release_date  
      ,source.rfq_part_count,source.rfq_number_of_quotes,source.buyer_name  
      ,source.discipline_level0,source.discipline_level1,source.discipline_level2,source.rfq_pref_manufacturing_location_id,source.rfq_id  
      ,@todaydate,1,0);  
      
       insert into zoho..zoho_sink_down_job_running_logs (zoho_module_id,job_date,job_status)  
       select 11 zoho_module_id , @todaydate , 'success : RFQ create sync'  
        
    commit  
   end try  
  
   begin catch  
    rollback  
      insert into zoho..zoho_sink_down_job_running_logs  
     (zoho_module_id,job_date,job_status)  
     select 11 zoho_module_id , @todaydate , 'fail : RFQ create sync' + error_message()  
     set @lastidentity = @@identity  
       
     insert into zoho..zoho_sink_down_job_running_logs_detail (job_running_id , zoho_id)  
     select @lastidentity , rfq_id as company_zoho_id  from #tmp_mfg_rfq_not_exists (nolock)  
  
  
   end catch  
    end  
    else  
    begin  
	 insert into zoho..zoho_sink_down_job_running_logs (zoho_module_id,job_date,job_status)  
	 select 11 zoho_module_id , @todaydate , 'No records found for RFQ create sync'  
    end  
      
    /* fetching mfg rfq details which are exist in MFG and zoho databse table*/    
    select    
		a.rfq_id, isnull(a.rfq_name,convert(varchar(500),a.rfq_id)) rfq_name 
		, a.rfq_description ,  a.contact_id ,j.assigned_sourcingadvisor  
		,rfq_status_id [rfqstatus]
		--,Quotes_needed_by [CloseDate]
		,
		(
		case 			
			when rfq_pref_manufacturing_location_id = 4 then 	convert(datetime,dateadd(minute,-00,dateadd(hour,@HoursDifferenceBetweenUTCandEST,quotes_needed_by )))  
			when rfq_pref_manufacturing_location_id = 5 then  convert(datetime,dateadd(minute,-00,dateadd(hour,@HoursDifferenceBetweenUTCandEST,quotes_needed_by )))  
			when rfq_pref_manufacturing_location_id = 6 then  convert(datetime,dateadd(minute,-00,dateadd(hour,@HoursDifferenceBetweenUTCandEST,quotes_needed_by )))  
			when rfq_pref_manufacturing_location_id = 7 then 	convert(datetime,dateadd(minute,-00,dateadd(hour,@HoursDifferenceBetweenUTCandEST,quotes_needed_by ))) 
			when rfq_pref_manufacturing_location_id = 2 then 	convert(datetime,dateadd(hour,+2,quotes_needed_by )) 	
			when rfq_pref_manufacturing_location_id = 3 then 	convert(datetime,dateadd(minute,+30,dateadd(hour,+5,quotes_needed_by )))  
			else quotes_needed_by
		end
		) [CloseDate] 
		,rfq_guid,release_date,rfq_part_count  
		,rfq_number_of_quotes,e.first_name + ' ' + e.last_name as buyer_name  
		,rfq_pref_manufacturing_location_id  
		,g.discipline_level0  
		,h.discipline_level1  
		,i.discipline_level2  
		,e.company_id  
    into #tmp_mfg_rfq_exists    
    from mp_rfq (nolock) a   
    left join (select rfq_id , max(status_date) release_date from mp_rfq_release_history (nolock)  group by rfq_id ) b  on b.rfq_id = a.rfq_id   
    left join (select rfq_id , count(rfq_part_id) rfq_part_count from mp_rfq_parts (nolock) group by rfq_id ) c  on c.rfq_id = a.rfq_id  
    left join (select rfq_id , count(contact_id) rfq_number_of_quotes from  mp_rfq_quote_SupplierQuote(nolock) where is_quote_submitted = 1 group by rfq_id ) d on d.rfq_id = a.rfq_id     
    left join mp_contacts(nolock) e on e.contact_id =  a.contact_id  
     left join  
   (      
    select distinct  abc.rfq_id as rfq_id   
    ,case when cnt = 1 then b.rfq_pref_manufacturing_location_id else 7 end as rfq_pref_manufacturing_location_id  
     from (  
      select  rfq_id    
      ,count(rfq_pref_manufacturing_location_id) cnt  
      from mp_rfq_preferences   (nolock) 
      group by rfq_id    
    ) abc  join mp_rfq_preferences b on abc.rfq_id = b.rfq_id  
   ) f on f.rfq_id = a.rfq_id  
   left join   
   (  
    select   
     mr.rfq_id   
     ,STUFF((SELECT distinct ',' +  convert(varchar,discipline_level0 )  
    from #tmp_rfq_discipline  
    where rfq_num = mr.rfq_id  
    FOR XML PATH('')), 1, 1, '') AS discipline_level0  
    from mp_rfq mr  
   ) g on g.rfq_id = a.rfq_id  
   left join   
   (  
    select   
     mr1.rfq_id   
     ,STUFF((SELECT distinct ',' +  convert(varchar,discipline_level1 )  
    from #tmp_rfq_discipline  
    where rfq_num = mr1.rfq_id  
    FOR XML PATH('')), 1, 1, '') AS discipline_level1  
    from mp_rfq mr1  
   ) h on h.rfq_id = a.rfq_id  
   left join   
   (  
    select   
     mr2.rfq_id   
     ,STUFF((SELECT distinct ',' +  convert(varchar,discipline_level2 )  
    from #tmp_rfq_discipline  
    where rfq_num = mr2.rfq_id  
    FOR XML PATH('')), 1, 1, '') AS discipline_level2  
    from mp_rfq mr2  
   ) i on i.rfq_id = a.rfq_id  
   left join  
    (   
    select a1.company_id,a1.assigned_sourcingadvisor  
    from mp_companies (nolock) a1  
    join mp_contacts (nolock) b1 on a1.Assigned_SourcingAdvisor = b1.contact_id  
    ) j on  j.company_id = e.company_id  
    where a.contact_id is not null   
    and a.rfq_id in     
    (    
     select RFQ_Number from zoho.dbo.zoho_rfq (nolock)  where synctype = 1  
	 /* Dec 03 , 2020*/
	 --and isnull(id,0) != 0 
	 ----isnull(isprocessed,0) = 0  
	/**/
    )    
		
	if (select count(1) from #tmp_mfg_rfq_exists(nolock) ) > 0  
    begin  
   begin try  
    begin transaction  
      /* Updating users records into zoho_user_accounts from MFG dB */  
    merge zoho..zoho_rfq as target  
    using #tmp_mfg_rfq_exists as source on  
     (target.RFQ_Number = source.rfq_id and target.synctype = 1)  
    when matched  
    and (  
      isnull(target.rfq_name,'')				!= source.rfq_name  
      or isnull(target.rfq_description,'')		!= source.rfq_description  
      or isnull(target.buyer_name,'')			!= source.buyer_name  
      or isnull(target.rfq_buyerstatus_id,'')   != source.rfqstatus  
      or isnull(target.region,'')				!= source.rfq_pref_manufacturing_location_id  
      or isnull(target.part_count,'')			!= source.rfq_part_count  
      or isnull(target.number_of_quotes,'')		!= source.rfq_number_of_quotes  
      or isnull(target.close_date,'')			!= source.closedate  
      or isnull(target.release_date,''  )		!= source.release_date  
      or isnull(target.Assigned_Engineer,'')	!= source.assigned_sourcingadvisor  
      or isnull(target.mfg_discipline,'')		!= source.discipline_level0  
      or isnull(target.mfg_1st_discipline,'')   != source.discipline_level1  
      or isnull(target.mfg_2nd_discipline,'')   != source.discipline_level2  
      or isnull(target.visionlink,'')			!= cast(source.rfq_guid as nvarchar(200))  
      or isnull(target.mfglegacyrfqid,'')		!= source.rfq_id  
      or isnull(target.Buyer_id,'')				!= source.contact_id  
     ) then  
     update set  
      target.rfq_name			            = source.rfq_name  
     ,target.rfq_description				= source.rfq_description  
     ,target.buyer_name						= source.buyer_name  
     ,target.rfq_buyerstatus_id				= source.rfqstatus  
     ,target.region							= source.rfq_pref_manufacturing_location_id  
     ,target.part_count						= source.rfq_part_count  
     ,target.number_of_quotes				= source.rfq_number_of_quotes  
     ,target.close_date						= source.closedate  
     ,target.release_date					= source.release_date  
     ,target.Assigned_Engineer				= source.assigned_sourcingadvisor  
     ,target.mfg_discipline					= source.discipline_level0  
     ,target.mfg_1st_discipline				= source.discipline_level1  
     ,target.mfg_2nd_discipline				= source.discipline_level2  
     ,target.visionlink						= cast(source.rfq_guid as nvarchar(200))  
     ,target.mfglegacyrfqid					= source.rfq_id  
     ,target.buyer_id						= source.contact_id  
     ,Modified_Time							= @todaydate  
    output  
     source.rfq_id					as mfg_rfq_id,  
     inserted.rfq_name				as mfg_rfq_name,  
     deleted.rfq_name				as zoho_rfq_name,  
     inserted.rfq_description		as mfg_rfq_description,  
     deleted.rfq_description		as zoho_rfq_description,  
     inserted.part_count			as mfg_rfq_part_count,   
     deleted.part_count				as zoho_part_count,  
     inserted.region				as mfg_rfq_pref_location_id,        
     deleted.region					as zoho_region,   
     inserted.release_date			as mfg_release_date,       
     deleted.release_date			as zoho_release_date,    
     inserted.close_date			as mfg_closedate,        
     deleted.close_date				as zoho_close_date,  
     inserted.buyer_name			as mfg_buyer_name,   
     deleted.buyer_name				as zoho_buyer_name,  
     inserted.Assigned_Engineer		as mfg_assigned_sourcingadvisor,   
     deleted.Assigned_Engineer		as zoho_assigned_sourcingadvisor,  
     inserted.rfq_buyerstatus_id    as mfg_rfqstatus,   
     deleted.rfq_buyerstatus_id     as zoho_rfq_buyerstatus_id,  
     inserted.number_of_quotes		as mfg_rfq_number_of_quotes,  
     deleted.number_of_quotes		as zoho_number_of_quotes,  
     inserted.mfg_discipline		as mfg_discipline_level0,   
     deleted.mfg_discipline			as zoho_discipline_level0,   
     inserted.mfg_1st_discipline	as mfg_discipline_level1,   
     deleted.mfg_1st_discipline		as zoho_discipline_level1,   
     inserted.mfg_2nd_discipline	as mfg_discipline_level2,   
     deleted.mfg_2nd_discipline		as zoho_discipline_level2,    
     inserted.visionlink			as mfg_rfq_guid,    
     deleted.visionlink				as zoho_visionlink,    
     inserted.mfglegacyrfqid		as mfg_mfglegacyrfqid,   
     deleted.mfglegacyrfqid			as zoho_mfglegacyrfqid,   
     inserted.buyer_id				as mfg_buyer_id,    
     deleted.buyer_id				as zoho_buyer_id,      
     'zoho_rfq'						as table_name          
    into @rfq_updatesync_log;  
  
      
    if (select count(1) from @rfq_updatesync_log ) > 0   
    Begin  
     insert  into @rfq_log_details (oldfieldvalue,newfieldvalue,table_name,fieldname,tranmode,rfq_id)  
     select oldfieldid,newfieldid,table_name,fieldname,transactionmode,mfg_zoho_rfq_id  
     from(  
      select isnull(zoho_rfq_name,'') as oldfieldid , mfg_rfq_name as newfieldid , table_name, 'rfq_name' as fieldname,'update' transactionmode , mfg_zoho_rfq_id  from @rfq_updatesync_log  
      union all  
      select isnull(zoho_rfq_description,'') as oldfieldid , mfg_rfq_description as newfieldid , table_name, 'rfq_description' as fieldname,'update' transactionmode , mfg_zoho_rfq_id  from @rfq_updatesync_log  
      union all  
      select isnull(zoho_part_count,'') as oldfieldid , mfg_rfq_part_count as newfieldid , table_name, 'part_count' as fieldname,'update' transactionmode , mfg_zoho_rfq_id  from @rfq_updatesync_log  
      union all  
      select isnull(zoho_region,'') as oldfieldid , mfg_rfq_pref_location_id as newfieldid , table_name, 'region' as fieldname,'update' transactionmode , mfg_zoho_rfq_id  from @rfq_updatesync_log  
      union all  
      select isnull(zoho_release_date,'') as oldfieldid , mfg_release_date as newfieldid , table_name, 'release_date' as fieldname,'update' transactionmode , mfg_zoho_rfq_id  from @rfq_updatesync_log  
      union all  
      select isnull(zoho_close_date,'') as oldfieldid , mfg_closedate as newfieldid , table_name, 'close_date' as fieldname,'update' transactionmode , mfg_zoho_rfq_id  from @rfq_updatesync_log  
      union all  
      select isnull(zoho_buyer_name,'') as oldfieldid , mfg_buyer_name as newfieldid , table_name, 'buyer_name' as fieldname,'update' transactionmode , mfg_zoho_rfq_id  from @rfq_updatesync_log  
      union all  
      select isnull(zoho_assigned_sourcingadvisor,'') as oldfieldid , mfg_assigned_sourcingadvisor as newfieldid , table_name, 'assigned_engineer' as fieldname,'update' transactionmode , mfg_zoho_rfq_id  from @rfq_updatesync_log  
      union all  
      select isnull(zoho_rfq_buyerstatus_id,'') as oldfieldid , mfg_rfqstatus as newfieldid , table_name, 'rfq_buyerstatus_id' as fieldname,'update' transactionmode , mfg_zoho_rfq_id  from @rfq_updatesync_log  
      union all  
      select isnull(zoho_number_of_quotes,'') as oldfieldid , mfg_rfq_number_of_quotes as newfieldid , table_name, 'number_of_quotes' as fieldname,'update' transactionmode , mfg_zoho_rfq_id  from @rfq_updatesync_log  
      union all  
      select isnull(zoho_discipline_level0,'') as oldfieldid , mfg_discipline_level0 as newfieldid , table_name, 'mfg_discipline' as fieldname,'update' transactionmode , mfg_zoho_rfq_id  from @rfq_updatesync_log  
        union all  
      select isnull(zoho_discipline_level1,'') as oldfieldid , mfg_discipline_level1 as newfieldid , table_name, 'mfg_1st_discipline' as fieldname,'update' transactionmode , mfg_zoho_rfq_id  from @rfq_updatesync_log  
        union all  
      select isnull(zoho_discipline_level2,'') as oldfieldid , mfg_discipline_level2 as newfieldid , table_name, 'mfg_2nd_discipline' as fieldname,'update' transactionmode , mfg_zoho_rfq_id  from @rfq_updatesync_log  
        union all  
      select isnull(zoho_visionlink,'') as oldfieldid , mfg_rfq_guid as newfieldid , table_name, 'visionlink' as fieldname,'update' transactionmode , mfg_zoho_rfq_id  from @rfq_updatesync_log  
        union all  
      select isnull(zoho_mfglegacyrfqid,'') as oldfieldid , mfg_mfglegacyrfqid as newfieldid , table_name, 'mfglegacyrfqid' as fieldname,'update' transactionmode , mfg_zoho_rfq_id  from @rfq_updatesync_log  
        union all  
      select isnull(zoho_buyer_id,'') as oldfieldid , mfg_buyer_id as newfieldid , table_name, 'buyer_id' as fieldname,'update' transactionmode , mfg_zoho_rfq_id  from @rfq_updatesync_log  
      )  abc  
     where oldfieldid != newfieldid  
  
     /* creating log for updated records */  
     insert into zoho..zoho_sink_down_logs  
     (zoho_module_id,company_id,company_zoho_id,log_date,table_name,field_name,oldfieldvalue,newfieldvalue,transaction_mode,user_contact_id,user_zoho_id,rfq_id)  
     select  11 as zoho_module_id, null ,null , @todaydate,a.table_name,a.fieldname  
     ,a.oldfieldvalue,a.newfieldvalue,a.tranmode,null,null,rfq_id  
     from @rfq_log_details a   
     /* */  
      
      /* update for zoho_rfq */  
     update a  
     set  a.IsSync = 0  
     ,a.IsProcessed = null  
     ,a.Modified_Time = @todaydate  
     ,a.SyncDatetime = null  
     ,a.ProcessedDatetime = null  
     from zoho..zoho_rfq a  
     join @rfq_updatesync_log b on a.rfq_number = b.mfg_zoho_rfq_id  
     where a.synctype = 1;  
     --/* */  
      
       insert into zoho..zoho_sink_down_job_running_logs (zoho_module_id,job_date,job_status)  
       select 11 zoho_module_id , @todaydate , 'success : RFQ update sync'  
  
       
    end  
    else  
    begin  
      insert into zoho..zoho_sink_down_job_running_logs (zoho_module_id,job_date,job_status)  
       select 11 zoho_module_id , @todaydate , 'No records found for RFQ update sync'  
    end  
  
	/* M2-2837 Zoho - RFQ - Part Materials Sync up - DB */
		SELECT DISTINCT 
			A.RFQ_ID 
			,D.MATERIAL_NAME_EN AS MATERIAL  
		INTO #tmp_rfq_materials
		FROM MP_RFQ				A (NOLOCK) 
		JOIN MP_RFQ_PARTS		B (NOLOCK) ON A.RFQ_ID = B.RFQ_ID
		JOIN MP_MST_MATERIALS	D (NOLOCK) ON B.MATERIAL_ID = D.MATERIAL_ID

		
		 
		UPDATE A	
			SET 
				a.rfq_materials = B.MATERIALS
				,a.IsSync = 0  
				,a.IsProcessed = null  
				,a.Modified_Time = @todaydate
		FROM ZOHO..ZOHO_RFQ A  (nolock) 
		JOIN
		(
			SELECT DISTINCT
			A.RFQ_ID 
			,STUFF((SELECT ', ' + CAST(MATERIAL AS VARCHAR(500)) [text()]
					 FROM #tmp_rfq_materials 
					 WHERE RFQ_ID = A.RFQ_ID
					 FOR XML PATH(''), TYPE)
					.value('.','NVARCHAR(MAX)'),1,2,' ') MATERIALS
 
			FROM #tmp_rfq_materials A
		) B ON A.RFQ_NUMBER = B.RFQ_ID
		WHERE  LEN(ISNULL(A.rfq_materials,''))  != LEN(B.MATERIALS)

	/**/

	/* M2-3616 ZOHO - Push new Directory RFQ flag to ZOHO - DB */
	
		UPDATE A	
			SET 
				a.IsMfgCommunityRfq = B.IsMfgCommunityRfq
				,a.IsSync = 0  
				,a.IsProcessed = null  
				,a.Modified_Time = @todaydate
		FROM ZOHO..ZOHO_RFQ A (nolock) 
		JOIN
		mp_rfq  B (nolock)  ON A.RFQ_NUMBER = B.RFQ_ID
		WHERE B.IsMfgCommunityRfq = 1 

    commit  

	 drop table if exists #tmp_mfg_rfq_not_exists -- this is for newly created rfq id  
	 drop table if exists #tmp_mfg_rfq_exists     -- this is for rfq details are available in both database MFG and zoho  
	 drop table if exists #tmp_rfq_discipline  
	 drop table if exists #tmp_inserted_rfq_id  
	 drop table if exists #tmp_rfq_materials

   end try  
  
   begin catch  
    rollback   
  
     insert into zoho..zoho_sink_down_job_running_logs  
     (zoho_module_id,job_date,job_status)  
     select 11 zoho_module_id , @todaydate , 'fail : RFQ update sync ' + error_message()  
     set @lastidentity = @@identity  
       
     insert into zoho..zoho_sink_down_job_running_logs_detail (job_running_id , zoho_id)  
     select @lastidentity , rfq_id as company_zoho_id     from #tmp_mfg_rfq_exists  (nolock)  
  
     --here updated those records having some data issue to update the records  
     update c set c.isprocessed = 1 , c.syncdatetime = null  
     from zoho.dbo.zoho_sink_down_job_running_logs(nolock) a  
     join zoho.dbo.zoho_sink_down_job_running_logs_detail(nolock) b on a.job_running_id = b.job_running_id  
     join zoho..zoho_rfq  (nolock) c on b.zoho_id   = c.rfq_number  
     join #tmp_mfg_rfq_exists d on d.rfq_id =  c.rfq_number  
     where a.job_running_id = @lastidentity  
     and synctype = 1 and isnull(issync,0) = 0 and isnull(isprocessed,0) = 0  
  
      
   end catch  
    end  
end
