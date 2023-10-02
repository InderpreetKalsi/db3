
-- EXEC proc_mfgzoho_set_account_sink_down
CREATE  procedure [dbo].[proc_mfgzoho_set_account_sink_down]
as
begin
	/* M2-1533 DownSync(AppSync) Get Modified existing records from Zoho CRM to MFG Db. (Accounts module)
	   M2-1535 DownSync(AppSync) - records from Zoho CRM to MFG Db. (Buyer module)- DB and
       M2-1534 DownSync(AppSync) - records from Zoho CRM to MFG Db. (Supplier module)- DB
	   M2-1847 Application - Zoho - Ability to mark Account as hidden - DB
	   -- Notes
	   -- module_type = 1    (account)
	   -- module_type = 2    (buyer/supplier)
	   -- To findind not sync records due to some error while execution used condition issync = 0 and syncdatetime = null and isprocessed = 1
	*/

	set nocount on
	declare @todaydate datetime = getutcdate()
	declare @lastidentity int

	drop table if exists ##zoho_company_account_sync_down
	drop table if exists ##zoho_buyer_supplier_users_sync_down

	declare @company_sink_down_log_new table
	(
		company_id						int,
		company_zoho_id					varchar(200),
	    oldfieldvalue                   varchar(100),
		newfieldvalue                   varchar(100),
		table_name                      varchar(100),
	    fieldname			            varchar(100),
		tranmode                        varchar(15),
		user_contact_id                 int,
		user_zoho_id                    varchar(200),
		module_type                     tinyint               
	)

/* 
  Account section
*/


if (select count(1) from zoho..zoho_company_account  (nolock) where synctype = 2 and isnull(issync,0) = 0 and isnull(isprocessed,0) = 0 ) > 0
begin
	
	begin try
	begin tran
/* update company zoho id in mfg db*/
	update b  set b.company_zoho_id = a.zoho_id
	from zoho..zoho_company_account a (nolock) 
	join mp_companies b (nolock) on a.visionacctid = b.company_id 
	where a.SyncType = 1 and a.zoho_id is not null  and b.company_zoho_id is null
/* */

/* reteriving data for sink down process */
	select company_account_id ,  visionacctid , zoho_id 
	, convert(int,(case when account_status in('active','gold') then 85 --1
	                    when account_status in('free','Basic')  then 83 --0
						when account_status = 'silver'          then 84
						when account_status = 'platinum'        then 86
						else account_status end )
				   ) account_status  
	, locationid as manufacturing_location  , manager_id as sourcing_advisor , issync , isprocessed , syncdatetime
	,Account_type_id,MFGLegacyACCTID,Account_name,hide_directory_profile
	into ##zoho_company_account_sync_down
	from zoho..zoho_company_account  (nolock)
	where synctype =2 and isnull(issync,0) = 0 and isnull(isprocessed,0) = 0
/* */


/* update isprocessed status for above records */
	update b
	set b.isprocessed = 1 , b.processeddatetime = @todaydate 
	from ##zoho_company_account_sync_down a
	join zoho..zoho_company_account b (nolock) on a.company_account_id = b.company_account_id
/* */

/* updating manufacturing location and sourcing advisor */
	declare @company_sink_down_log table
	(
		company_id							int,
		company_zoho_id						varchar(200),
		manufacturing_location_id_old		int,
		manufacturing_location_id_new		int,
		assigned_sourcingadvisor_old		int,
		assigned_sourcingadvisor_new		int,
		zoho_hide_directory_profile_new     bit,
		mfg_is_hide_directory_profile_old   bit, 
		table_name							varchar(100)
	)
	
	merge mp_companies as target
	using ##zoho_company_account_sync_down as source on (target.company_zoho_id = source.zoho_id 
	                                                     and convert(varchar(100),target.company_id) = source.visionacctid) 
	when matched  
			and  (  isnull(target.manufacturing_location_id,9999) <> isnull(source.manufacturing_location ,9999)
					or isnull(target.assigned_sourcingadvisor,9999) <> isnull(source.sourcing_advisor ,9999) 
					or isnull(target.is_hide_directory_profile,0) <>  isnull(source.hide_directory_profile,0) 
				  ) then 
		update set 
			target.manufacturing_location_id = source.manufacturing_location  
			,target.assigned_sourcingadvisor = isnull(source.sourcing_advisor ,target.assigned_sourcingadvisor) 
			,target.is_hide_directory_profile = source.hide_directory_profile 
	output 
		 deleted.company_id 
		,deleted.company_zoho_id 
		,deleted.manufacturing_location_id  as manufacturing_location_id_old
		,inserted.manufacturing_location_id as manufacturing_location_id_new
		,deleted.assigned_sourcingadvisor   as assigned_sourcingadvisor_old
		,inserted.assigned_sourcingadvisor  as assigned_sourcingadvisor_new
		,inserted.is_hide_directory_profile as zoho_hide_directory_profile_new
		,deleted.is_hide_directory_profile  as mfg_is_hide_directory_profile_old
		,'mp_companies'                     as table_name
	into @company_sink_down_log; 


	/* M2-3981 Vision - Map hidden configured check box to Zoho hide profile - DB */

	insert into XML_SupplierProfileCaptureChanges (CompanyId ,Event ,CreatedOn)
	select distinct b.company_id ,  'hide_profile' , getutcdate()
	from ##zoho_company_account_sync_down a
	join mp_companies b (nolock) on a.VisionACCTID = b.company_id
	where isnull(a.hide_directory_profile,0) <>  isnull(b.is_hide_directory_profile,0) 
	
	/**/



	insert  into @company_sink_down_log_new  
	select * from(
	select company_id,company_zoho_id, assigned_sourcingadvisor_old as oldfieldid , assigned_sourcingadvisor_new as newfieldid
	, table_name, 'assigned_sourcingadvisor' as fieldname,'update' transactionmode ,null user_contact_id,null user_zoho_id, 1 module_type
	from @company_sink_down_log
	union all
	select company_id,company_zoho_id, manufacturing_location_id_old, manufacturing_location_id_new
	,table_name,'manufacturing_location_id' ,'update' ,null [user_id],null user_zoho_id,1 module_type
	from @company_sink_down_log
	union all
	select company_id,company_zoho_id, isnull(mfg_is_hide_directory_profile_old,0), zoho_hide_directory_profile_new
	,table_name,'is_hide_directory_profile' ,'update' ,null [user_id],null user_zoho_id,1 module_type
	from @company_sink_down_log
	)  abc
	where (oldfieldid != newfieldid) 
/*  */

/* updating account status */
	declare @company_sink_down_log_1 table
	(
		company_id				int,
		register_supplier_old	bit,
		register_supplier_new	bit,
		account_type_old        int,
		account_type_new        int,
		tranmode                varchar(15)
	)

	merge mp_registered_supplier as target
	using ##zoho_company_account_sync_down as source on (target.company_id = source.visionacctid) 
	when matched  
		and
		( 
			target.account_type != source.account_status 
			/* M2-2714 ZOHO - Strip mapping - DB */
			OR isnull(target.account_type_source,0) != 132
			/**/
		)
		and  source.account_type_id not in (1,2) 
	    and source.account_status in(85,84,86)  then
		update set 
			target.account_type =  source.account_status
			,target.updated_on = @todaydate
			,target.is_registered =  case when source.account_status = 84 then 0 else 1 end
			/* M2-2714 ZOHO - Strip mapping - DB */
			,target.account_type_source = 132
			/**/
	when not matched and  source.account_type_id not in (1,2) and source.account_status in(85,84,86) then
	 insert (company_id,is_registered,created_on,account_type,account_type_source)
				 values (source.visionacctid,case when source.account_status = 84 then 0 else 1 end ,@todaydate,source.account_status,132)
	output 
		isnull(deleted.company_id,inserted.company_id)
		,deleted.is_registered as is_registered_old
		,inserted.is_registered as is_registered_new
		,deleted.account_type as is_account_type_old
		,inserted.account_type as is_account_type_new
		,case when deleted.company_id is not null then 'update' else 'insert' end
	into @company_sink_down_log_1; 

	insert  into @company_sink_down_log_new  
	select * from(
	select company_id, b.Zoho_id , account_type_old oldfieldid , account_type_new newfieldid
	,'mp_registered_supplier' as tablename,'account_type'  as fieldname ,tranmode , null user_contact_id, null user_zoho_id, 1 module_type
	from @company_sink_down_log_1 a
	join ##zoho_company_account_sync_down b on a.company_id = b.visionacctid
	)  abc
	where isnull(oldfieldid,0) != newfieldid 

	---- if any  company_id,account_status : basic (83) and this company_id exists in "mp_registered_supplier" 
	---- then such records will deleted from "mp_registered_supplier" table  
	if ( select count(1) from mp_registered_supplier(nolock) a 
	        join ##zoho_company_account_sync_down(nolock) b on  a.company_id = b.visionacctid
			and  b.account_type_id not in (1,2) and b.account_status = 83 ) > 0 
	begin
	
			insert  into @company_sink_down_log_new  
			select company_id, b.Zoho_id , a.account_type oldfieldid , '83' newfieldid
			,'mp_registered_supplier' as tablename,'account_type'  as fieldname ,'delete',null user_contact_id, null user_zoho_id,1 module_type
			from mp_registered_supplier(nolock) a
			join ##zoho_company_account_sync_down(nolock) b on  a.company_id = b.visionacctid
			and  b.account_type_id not in (1,2) and b.account_status = 83
		
			delete a 
			output 
				 deleted.company_id 
				,deleted.is_registered as is_registered_old
				,null
				,deleted.account_type as is_account_type_old
				,83 as is_account_type_new
				,'delete'  
			into @company_sink_down_log_1
			from mp_registered_supplier(nolock) a
			join ##zoho_company_account_sync_down(nolock) b on  a.company_id = b.visionacctid
			and  b.account_type_id not in (1,2) and b.account_status = 83;
	end
/* */

/* creating log for updated records */
	insert into zoho..zoho_sink_down_logs
	(zoho_module_id,company_id,company_zoho_id,log_date,table_name,field_name,oldfieldvalue,newfieldvalue,transaction_mode,user_contact_id,user_zoho_id)
	select 
	distinct 20 as zoho_module_id, 
	a.company_id,a.company_zoho_id,@todaydate,a.table_name,a.fieldname,a.oldfieldvalue,a.newfieldvalue,a.tranmode,null,null
	from @company_sink_down_log_new a
	where module_type = 1 
/* */

	update b set b.issync = 1 , b.syncdatetime = @todaydate
	from ##zoho_company_account_sync_down a
	join zoho..zoho_company_account b (nolock) on a.company_account_id = b.company_account_id

	insert into zoho..zoho_sink_down_job_running_logs	(zoho_module_id,job_date,job_status)
	select 20 zoho_module_id , @todaydate , 'success : Account sync'
	set @lastidentity = @@identity

	/* creating log for affected records */
	-- 	below records will goes into log table those records are "account_type" = 1,2 and account_status = 85 ("Active")
	insert into zoho..zoho_premium_buyer_log (Company_Account_Id,VisionACCTID,Zoho_id,Account_Status,Account_Type_Id,Created_On,MFGLegacyACCTID,Account_name)
	select company_account_id,VisionACCTID,Zoho_id,account_status,Account_type_id,@todaydate,MFGLegacyACCTID,Account_name
	 from ##zoho_company_account_sync_down where Account_type_id in(1,2) and account_status = 85
	/* */

	/* M2-3547 Supplier profile XML file generation (New Elements) - DB*/
	if ((select count(1)  from @company_sink_down_log_new where table_name = 'mp_registered_supplier') > 0)
	begin

		insert into XML_SupplierProfileCaptureChanges (CompanyId ,[Event])
		select company_id , 'tier' from @company_sink_down_log_new where table_name = 'mp_registered_supplier'

	end 
	/**/
	
	
	commit

end try
begin catch
	
	rollback
	
	insert into zoho..zoho_sink_down_job_running_logs
	(zoho_module_id,job_date,job_status)
	select 20 zoho_module_id , @todaydate , 'fail : Account sync ' + error_message() 
	set @lastidentity = @@identity
	
	insert into zoho..zoho_sink_down_job_running_logs_detail (job_running_id , zoho_id)
	select @lastidentity , zoho_id 	from zoho..zoho_company_account  (nolock)
	where synctype =2 and isnull(issync,0) = 0 and isnull(isprocessed,0) = 0
		
	update c set c.isprocessed = 1 , c.syncdatetime = null
	from zoho.dbo.zoho_sink_down_job_running_logs(nolock) a
	join zoho.dbo.zoho_sink_down_job_running_logs_detail(nolock) b on a.job_running_id = b.job_running_id
	join zoho..zoho_company_account  (nolock) c on b.zoho_id = c.Zoho_id
	where a.job_running_id = @lastidentity
	and synctype =2 and isnull(issync,0) = 0 and isnull(isprocessed,0) = 0

end catch
end 
else
begin
		insert into zoho..zoho_sink_down_job_running_logs	(zoho_module_id,job_date,job_status)
		select 20 zoho_module_id , @todaydate , 'No records found - Account sync'
end

/* 
  Buyer/Supplier section
*/

if (select count(1) from zoho..zoho_user_accounts  (nolock) where synctype = 2 and isnull(issync,0) = 0 and isnull(isprocessed,0) = 0 and Email_Opt_Out is not null ) > 0
begin

	begin try
		begin tran 
			/* update company zoho id in mfg db*/
			update b  set b.user_zoho_id = a.zoho_id
			from zoho..zoho_user_accounts(nolock) a
			join mp_contacts(nolock)  b on a.VisionSUPID = b.contact_id 
			where a.SyncType = 1 and a.Zoho_id is not null  
			and (b.user_zoho_id is null or b.user_zoho_id = '0')
			and a.Zoho_id <> '0'
			/* */

			/* reteriving data for sink down process */
			select User_account_id ,  VisionSUPID , zoho_id ,Email_Opt_Out,
			 issync , isprocessed , syncdatetime ,Account_type_id
			into ##zoho_buyer_supplier_users_sync_down
			from zoho..zoho_user_accounts  (nolock)
			where synctype =2 and isnull(issync,0) = 0 and isnull(isprocessed,0) = 0
			and Email_Opt_Out is not null
			/* */
		
			/* update isprocessed status for above records */
			update b
			set b.isprocessed = 1 , b.processeddatetime = @todaydate 
			from ##zoho_buyer_supplier_users_sync_down(nolock) a
			join zoho..zoho_user_accounts b (nolock) on  a.user_account_id = b.user_account_id 
			/* */
		  		   
			/* updating manufacturing location and sourcing advisor */
			declare @user_sink_down_log table
			(
				User_contact_id				int,
				user_zoho_id				varchar(200),
				Email_Opt_Out_old	        bit,
				Email_Opt_Out_new	        bit,
				table_name                  varchar(100),
				tranmode                    varchar(15)
			)
           /* */
		   
		   /* updating records in mp_contacts */
		   merge mp_contacts as target
			using ##zoho_buyer_supplier_users_sync_down as source on (target.contact_id = source.VisionSUPID and
			                                                           target.user_zoho_id = source.zoho_id) 
			when matched  and is_notify_by_email != (case when source.Email_Opt_Out = 0 then 1 else 0 end)  then    
				update set 
					target.is_notify_by_email = (case when source.Email_Opt_Out = 0 then 1 else 0 end)
					,target.modified_on = @todaydate
			output 
				deleted.contact_id
				,deleted.user_zoho_id
				,deleted.is_notify_by_email  as is_notify_by_email_old
				,inserted.is_notify_by_email as is_notify_by_email_new
				,'mp_contacts' as table_name
				,'update'
			into @user_sink_down_log; 
			/* */
			
			insert  into @company_sink_down_log_new  
			select * from(
			select null company_id, null company_zoho_id , Email_Opt_Out_old oldfieldid , Email_Opt_Out_new newfieldid
			, 'mp_contacts' as tablename ,'is_notify_by_email'  as fieldname , tranmode , a.User_contact_id ,a.user_zoho_id, 2 module_type
			from @user_sink_down_log  a
			join ##zoho_buyer_supplier_users_sync_down b on a.User_contact_id = b.VisionSUPID
			)  abc
			where oldfieldid != newfieldid 

			update b
			set  b.issync = 1 , b.syncdatetime = @todaydate
			from ##zoho_buyer_supplier_users_sync_down a
			join zoho..zoho_user_accounts b (nolock) on  a.user_account_id = b.user_account_id 
			
			insert into zoho..zoho_sink_down_job_running_logs	(zoho_module_id,job_date,job_status)
			select 20 zoho_module_id , @todaydate , 'success - Buyer/Supplier down sync'
			
			/* creating log for updated records */
			insert into zoho..zoho_sink_down_logs
			(zoho_module_id,company_id,company_zoho_id,log_date,table_name,field_name,oldfieldvalue,newfieldvalue,transaction_mode,user_contact_id,user_zoho_id)
			select 20 as zoho_module_id, 
			a.company_id,a.company_zoho_id,@todaydate,a.table_name,a.fieldname,a.oldfieldvalue,a.newfieldvalue,a.tranmode,a.user_contact_id ,a.user_zoho_id
			from @company_sink_down_log_new a
			where module_type = 2


			/* Jun 12, 2020 (Slack) - Ewesterfield-MFG  2:56 AM Please check the subscription config. Any new Silver, Gold, or Platinum should have LiveQuote on. They are coming in as off right now at least for Gold ones. */
			--SELECT DISTINCT  visionacctid, account_status , is_mqs_enable
			UPDATE b SET b.is_mqs_enable = 1
			FROM zoho..zoho_company_account a (NOLOCK)
			JOIN	mp_companies b (NOLOCK) ON a.visionacctid = b.company_id
			WHERE SyncType = 2
				AND account_status IN  ('Active','Gold','Platinum',',Silver')
				AND visionacctid IS NOT NULL
				AND is_mqs_enable = 0
			/**/


						
		commit

	end try

	begin catch
	
		rollback
	
		insert into zoho..zoho_sink_down_job_running_logs
		(zoho_module_id,job_date,job_status)
		select 20 zoho_module_id , @todaydate , 'fail : Buyer/Supplier sync : ' + error_message() 
		set @lastidentity = @@identity
			
		insert into zoho..zoho_sink_down_job_running_logs_detail (job_running_id , zoho_id)
		select @lastidentity , zoho_id 	from zoho..zoho_user_accounts  (nolock)
		where synctype =2 and isnull(issync,0) = 0 and isnull(isprocessed,0) = 0
	
		update c set c.isprocessed = 1 , c.syncdatetime = null
		from zoho.dbo.zoho_sink_down_job_running_logs(nolock) a
		join zoho.dbo.zoho_sink_down_job_running_logs_detail(nolock) b on a.job_running_id = b.job_running_id
		join zoho..zoho_user_accounts  (nolock) c on b.zoho_id = c.Zoho_id
		where a.job_running_id = @lastidentity
		and synctype =2 and isnull(issync,0) = 0 and isnull(isprocessed,0) = 0

end catch
end
else
begin
		insert into zoho..zoho_sink_down_job_running_logs	(zoho_module_id,job_date,job_status)
		select 20 zoho_module_id , @todaydate , 'No records found - Buyer/Supplier sync'
		
end


end --Begin
