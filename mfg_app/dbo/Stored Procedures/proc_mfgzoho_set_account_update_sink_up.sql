
/*
exec proc_mfgzoho_set_account_update_sink_up
*/
CREATE procedure [dbo].[proc_mfgzoho_set_account_update_sink_up]
as
begin
/*
    M2-1661 Accounts Module Update Sync - DB SQL Job/Development
    M2-1662 Buyer/Supplier Module Update Sync - DB SQL Job/Development
*/

set nocount on
declare @todaydate datetime = getutcdate()
declare @lastidentity int

declare @company_buyey_supplier_log_details table
    (
        company_id                      int,
        company_zoho_id                 varchar(200),
        oldfieldvalue                   nvarchar(max),
        newfieldvalue                   nvarchar(max),
        table_name                      varchar(100),
        fieldname                       varchar(100),
        tranmode                        varchar(15),
        user_contact_id                 int,
        user_zoho_id                    varchar(200),
        module_type                     tinyint
    )

    /* getting information on old and new values from both the databases (MFG and Zoho) */
    declare @company_updatesync_log table
    (
        company_id                      int,
        company_zoho_id                 varchar(200),
        mfg_name                        nvarchar(300),
        zoho_account_name               nvarchar(300),
        mfg_duns_number                 nvarchar(100),
        zoho_duns                       nvarchar(100),
        mfg_employee_count_range_id     nvarchar(50),
        zoho_Employee_Count_id          nvarchar(50),
        mfg_communication_value         nvarchar(300),
        zoho_Website1                   nvarchar(300),
        mfg_phone_communication_value   nvarchar(100),
        zoho_phone                      nvarchar(100),
        mfg_fax                         nvarchar(100),
        zoho_fax                        nvarchar(100),
        mfg_discipline_level0           nvarchar(max),
        zoho_discipline_level0          nvarchar(max),
        mfg_discipline_level1           nvarchar(max),
        zoho_discipline_level1          nvarchar(max),
        mfg_discipline_level2           nvarchar(max),
        zoho_discipline_level2          nvarchar(max),
        mfg_certificate_type1           nvarchar(max),
        zoho_certificate_type1          nvarchar(max),
        mfg_certificate_type2           nvarchar(max),
        zoho_certificate_type2          nvarchar(max),
        mfg_certificate_type3           nvarchar(max),
        zoho_certificate_type3          nvarchar(max),
        mfg_certificate_type4           nvarchar(max),
        zoho_certificate_type4          nvarchar(max),
        mfg_account_type_id             nvarchar(10),
        zoho_account_type_id            nvarchar(10),
        mfg_industry_id                 nvarchar(10),
        zoho_industry_id                nvarchar(10),
        mfg_linkedin_communication      nvarchar(500),
        zoho_linkedn_URL                nvarchar(500),
        mfg_skypeid_communication       nvarchar(500),
        zoho_Skype_ID                   nvarchar(500),
        table_name                      varchar(100)
    )

    declare @company_updatesync_address_log table
    (
        company_id                      int,
        company_zoho_id                 varchar(200),
        mfg_address1                    nvarchar(max),
        zoho_street_address_1           nvarchar(max),
        mfg_address2                    nvarchar(max),
        zoho_street_address_2           nvarchar(max),
        mfg_city                        nvarchar(max),
        zoho_city                       nvarchar(max),
        mfg_zipcode                     nvarchar(max),
        zoho_zip_code                   nvarchar(max),
        mfg_country_name                nvarchar(max),
        zoho_country                    nvarchar(max),
        mfg_state                       nvarchar(max),
        zoho_state                      nvarchar(max),
        contact_id                      int,
        contact_zoho_id                 varchar(200),
        table_name                      varchar(200)
    )

    declare @users_updatesync_details table
    (
        usercontact_id                  int,
        userzoho_id                     varchar(200),
        mfg_title                       nvarchar(150),
        zoho_title                      nvarchar(150),
        mfg_first_name                  nvarchar(500),
        zoho_first_name                 nvarchar(500),
        mfg_last_name                   nvarchar(500),
        zoho_last_name                  nvarchar(500),
        mfg_is_notify_by_email          varchar(10),
        zoho_email_opt_out              varchar(10),
        mfg_is_validated_buyer          varchar(10),
        zoho_is_validated_buyer         varchar(10),
		mfg_email						varchar(500),
        zoho_email						varchar(500),
        table_name                      varchar(200)
    )

begin try

    -- 1. company account
    drop table if exists #tmp_company_discipline
    drop table if exists #tmp_company_certificate
    drop table if exists #tmp_account_communication_details
    drop table if exists #tmp_mfg_company_details
    drop table if exists #tmp_mfg_source_details
    drop table if exists #tmp_zoho_users_details
    drop table if exists #update_company_list
    drop table if exists #tmp_communication_details
    drop table if exists #update_contact_list
    drop table if exists #tmp_zoho_company_address_details
    drop table if exists #tmp_zoho_users_addess_details
    drop table if exists #tmp_mfg_company_update_details
    drop table if exists #excludecompanyidlist
	drop table if exists #deleteaddress
	drop table if exists #buyerRFQinfo
	drop table if exists #supplierupgraderequest
	drop table if exists #supplieraccounttype


    /* Fetch those records which are available in both database MFG and Zoho */
        select a.company_id,name,duns_number,employee_count_range_id,company_zoho_id
        into #tmp_mfg_company_details
        from mp_companies (nolock) a
        where  exists
        (
            select distinct VisionACCTID from zoho..zoho_company_account(nolock) b
            where a.company_id = b.VisionACCTID and b.synctype = 1
            and VisionACCTID is not null
        ) and a.company_id != 0
		
    begin transaction

        /* load companies discipline_level*/
        select distinct a.company_id
            , (select childid from dbo.fn_rfq_discipline(a.part_category_id,0)) discipline_level0
            , (select childid from dbo.fn_rfq_discipline(a.part_category_id,1)) discipline_level1
            , (select childid from dbo.fn_rfq_discipline(a.part_category_id,2)) discipline_level2
        into #tmp_company_discipline
        from mp_company_processes(nolock) a
        join mp_mst_part_category(nolock) b on a.part_category_id = b.part_category_id
        where b.level in (0,1,2)  and b.status_id = 2
        /**/

        /* load company certificates */
        select  distinct  a1.company_id
            ,    STUFF((SELECT  ',' + convert(varchar,a.certificates_id )
                from mp_company_certificates(nolock) a
                join mp_certificates(nolock) b on a.certificates_id = b.certificate_id and b.certificate_type_id = 1
                where a.status_id = 2 and a.company_id = a1.company_id
                FOR XML PATH('')), 1, 1, '') AS certificate_type1
            ,    STUFF((SELECT  ',' + convert(varchar,a.certificates_id )
                from mp_company_certificates(nolock) a
                join mp_certificates(nolock) b on a.certificates_id = b.certificate_id and b.certificate_type_id = 2
                where a.status_id = 2 and a.company_id = a1.company_id
                FOR XML PATH('')), 1, 1, '') AS certificate_type2
            ,    STUFF((SELECT  ',' + convert(varchar,a.certificates_id )
                from mp_company_certificates(nolock) a
                join mp_certificates(nolock) b on a.certificates_id = b.certificate_id and b.certificate_type_id = 3
                where a.status_id = 2 and a.company_id = a1.company_id
                FOR XML PATH('')), 1, 1, '') AS certificate_type3
            ,    STUFF((SELECT  ',' + convert(varchar,a.certificates_id )
                from mp_company_certificates(nolock) a
                join mp_certificates(nolock) b on a.certificates_id = b.certificate_id and b.certificate_type_id = 4
                where a.status_id = 2 and a.company_id = a1.company_id
                FOR XML PATH('')), 1, 1, '') AS certificate_type4
        into #tmp_company_certificate
        from mp_company_certificates(nolock) a1

        /* fetching account communication details in tmp table  */
        select
            company_id   , [Telephone]   , [Fax]   , [Web] , [Skype Name] , [LinkedIn]
        into #tmp_account_communication_details
        from
        (
          select company_id,
            case
                when communication_type_id = 1 then  'Telephone'
                when communication_type_id = 2 then     'Fax'
                when communication_type_id = 4 then     'Web'
                when communication_type_id = 6 then     'Skype Name'
                when communication_type_id = 8 then     'LinkedIn'

            end as communication_type
            , isnull(communication_clean_value, communication_value) communication_value
          from  mp_communication_details(nolock)
          where company_id != 0 and company_id in  (select distinct company_id from #tmp_mfg_company_details(nolock)  where company_id != 0 )
        ) x
        pivot
        (
          max(communication_value)
          for communication_type in([Telephone], [Fax],  [Web] , [Skype Name] , [LinkedIn])
        )p

        /* fetching account users communication details above account users in tmp table  */
        select
             contact_id  , [Telephone]   , [Fax]
        into #tmp_communication_details
        from
        (
          select  contact_id ,
            case
                when communication_type_id = 1 then 'Telephone'
                when communication_type_id = 2 then     'Fax'

            end as communication_type
            , isnull(communication_clean_value, communication_value) communication_value
          from  mp_communication_details(nolock)
          where contact_id is not null and  contact_id != 0 and contact_id in
          (select distinct contact_id from #tmp_mfg_company_details(nolock)   a
                join mp_contacts(nolock) b on a.company_id = b.company_id where contact_id != 0)
        ) x
        pivot
        (
          max(communication_value)
          for communication_type in([Telephone], [Fax])
        )p1

          /* This is company level information*/
          select
            distinct
            a.company_id
            ,a.name as account_name
            ,case when (select count(*) from (select distinct company_id,is_buyer from mp_contacts (nolock) group by company_id , is_buyer ) a1  where company_id = a.company_id group by company_id having count(*) > 1   ) > 1 then 1 when b.is_buyer = 1 then 2 when b.is_buyer = 0 then 3 end account_type_id
            , a.employee_count_range_id
            , a.duns_number as duns
            , g.industry_type_id as industry_id
            , a.company_id as mfglegacyacctid
            , h.Telephone as telephone
            , h.fax
            , h.web
            , h.[Skype Name]
            , h.[LinkedIn]
            , i.discipline_level0
            , j.discipline_level1
            , k.discipline_level2
            , l.certificate_type1
            , l.certificate_type2
            , l.certificate_type3
            , l.certificate_type4
            , a.company_zoho_id
         into #tmp_mfg_company_update_details
        from #tmp_mfg_company_details (nolock) a
        left join mp_contacts (nolock) b on a.company_id = b.company_id
        left join
        (    select a.company_id ,    a.industry_type_id from mp_company_industries (nolock) a
            join (select company_id , max(company_industry_id) company_industry_id from mp_company_industries (nolock)  group by company_id) b
                on a.company_industry_id = b.company_industry_id
        )    g on a.company_id = g.company_id
        left join #tmp_account_communication_details h on a.company_id = h.company_id
        left join
        (
            select
                a.company_id
                ,STUFF((SELECT distinct ',' + convert(varchar,discipline_level0 )
            from #tmp_company_discipline(nolock)
            where company_id = a.company_id
            FOR XML PATH('')), 1, 1, '') AS discipline_level0
            from mp_companies(nolock) a
        ) i on a.company_id = i.company_id
        left join
        (
            select
                a.company_id
                ,STUFF((SELECT distinct ',' + convert(varchar,discipline_level1 )
            from #tmp_company_discipline(nolock)
            where company_id = a.company_id
            FOR XML PATH('')), 1, 1, '') AS discipline_level1
            from mp_companies(nolock) a
        ) j on a.company_id = j.company_id
        left join
        (
            select
                a.company_id
                ,STUFF((SELECT distinct ',' + convert(varchar,discipline_level2 )
            from #tmp_company_discipline(nolock)
            where company_id = a.company_id
            FOR XML PATH('')), 1, 1, '') AS discipline_level2
            from mp_companies(nolock) a
        ) k on a.company_id = k.company_id
        left join #tmp_company_certificate(nolock) l on  a.company_id = l.company_id
        /* */

        /* M2-3429 Zoho - On only Email Update/change the Zoho Db Flags not getting Resetted => code commented */
		/* here code for senario for one company assign multiple contact and these contacts are is_admin = 1 so exclude such type of companies*/
        --select company_id
        --into #excludecompanyidlist
        --from (
        --        select company_id , count(company_id) as cnt from mp_contacts(nolock)
        --        where is_admin = 1 and company_id !=0
        --        group by company_id
        --        having count(company_id) > 1
        --     ) abc
       /**/
	   /**/

         /* This is users level information*/
            select
            distinct
            a.company_id
            ,case when (select count(*) from (select distinct company_id,is_buyer from mp_contacts (nolock) group by company_id , is_buyer ) a1  where company_id = a.company_id group by company_id having count(*) > 1   ) > 1 then 1 when b.is_buyer = 1 then 2 when b.is_buyer = 0 then 3 end account_type_id
            ,ma.address_id
            , ma.address1
            , ma.address2
            , ma.address4 as city
            , ma.address5 ----state
            , ma.address3 as zipcode
            , mc.country_name
            , mc.country_id
            , mr.region_id
            , mr.region_name as [state]
            , a.company_zoho_id
            , b.contact_id
            , b.user_zoho_id
            , b.title
            , b.first_name
            , b.last_name
            , b.is_notify_by_email
            , b.is_validated_buyer
            , cd.Telephone [userphone]
            , cd.Fax [userfax]
            , b.is_admin
			, b1.email
        into #tmp_mfg_source_details
        from #tmp_mfg_company_details (nolock) a
        left join mp_contacts (nolock) b on a.company_id = b.company_id
		left join aspnetusers (nolock) b1 on b.user_id = b1.id
        left join mp_addresses ma (nolock) on b.address_id = ma.address_id -- need to check only update mailing address
        left join mp_mst_country mc (nolock) on ma.country_id = mc.country_id
        left join mp_mst_region mr (nolock) on ma.region_id = mr.region_id
        left join #tmp_communication_details(nolock) cd on cd.contact_id = b.contact_id
        /* M2-3429 Zoho - On only Email Update/change the Zoho Db Flags not getting Resetted => code commented */
		--where  a.company_id not in (select company_id from #excludecompanyidlist(nolock))
		/**/
        /* */

        /* Updating into zoho table zoho_company_account from MFG dB */
        merge zoho..zoho_company_account as target
        using #tmp_mfg_company_update_details as source on
         (target.visionacctid = source.company_id and target.synctype = 1)
        when matched
        and (
                isnull(target.account_name,'')            != source.account_name
                or isnull(target.duns,'')                 != source.duns
                or isnull(target.Employee_Count_id,'')    != source.employee_count_range_id
                or isnull(target.Website1,'')             != source.web
                or isnull(target.phone,'')                != source.telephone
                or isnull(target.fax,'')                  != source.fax
                or isnull(target.discipline_level0,'')    != source.discipline_level0
                or isnull(target.discipline_level1,'')    != source.discipline_level1
                or isnull(target.discipline_level2,'')    != source.discipline_level2
                or isnull(target.certificate_type1,'')    != source.certificate_type1
                or isnull(target.certificate_type2,'')    != source.certificate_type2
                or isnull(target.certificate_type3,'')    != source.certificate_type3
                or isnull(target.certificate_type4,'')    != source.certificate_type4
                or target.account_type_id                 != source.account_type_id
                or isnull(target.industry_id,'')          != source.industry_id
                or isnull(target.LinkedIn_URL,'')         != source.LinkedIn
                or isnull(target.Skype_ID,'')             != source.[Skype Name]
            ) then
            update set
                target.account_name                  = source.account_name
                ,target.duns                         = case when source.duns is null or source.duns = '' then target.duns else source.duns end
                ,target.employee_count_id            = source.employee_count_range_id
                ,target.Website1                     = case when source.web is null or source.web  = '' then target.Website1 else source.web end
                ,target.phone                        = source.telephone
                ,target.fax                          = source.fax
                ,target.discipline_level0            = source.discipline_level0
                ,target.discipline_level1            = source.discipline_level1
                ,target.discipline_level2            = source.discipline_level2
                ,target.certificate_type1            = source.certificate_type1
                ,target.certificate_type2            = source.certificate_type2
                ,target.certificate_type3            = source.certificate_type3
                ,target.certificate_type4            = source.certificate_type4
                ,target.account_type_id              = source.account_type_id
                ,target.industry_id                  = source.industry_id
                ,target.LinkedIn_URL                 = source.LinkedIn
                ,target.Skype_ID                     = source.[Skype Name]
                ,Modified_Time                       = @todaydate
				--,target.IsSync = 0
    --            ,target.IsProcessed = null
            output
             deleted.visionacctid
            ,deleted.zoho_id
            ,inserted.account_name               as mfg_name
            ,deleted.account_name                as zoho_account_name
            ,inserted.duns                       as mfg_duns_number
            ,deleted.duns                        as zoho_duns
            ,inserted.employee_count_id          as mfg_employee_count_range_id
            ,deleted.Employee_Count_id           as zoho_Employee_Count_id
            ,inserted.Website1                   as mfg_communication_value
            ,deleted.Website1                    as zoho_Website1
            ,inserted.phone                      as mfg_phone_communication_value
            ,deleted.phone                       as zoho_phone
            ,inserted.fax                        as mfg_fax
            ,deleted.fax                         as zoho_fax
            ,inserted.discipline_level0          as mfg_discipline_level0
            ,deleted.discipline_level0           as zoho_discipline_level0
            ,inserted.discipline_level1          as mfg_discipline_level1
            ,deleted.discipline_level1           as zoho_discipline_level1
            ,inserted.discipline_level2          as mfg_discipline_level2
            ,deleted.discipline_level2           as zoho_discipline_level2
            ,inserted.certificate_type1          as mfg_certificate_type1
            ,deleted.certificate_type1           as zoho_certificate_type1
            ,inserted.certificate_type2          as mfg_certificate_type2
            ,deleted.certificate_type2           as zoho_certificate_type2
            ,inserted.certificate_type3          as mfg_certificate_type3
            ,deleted.certificate_type3           as zoho_certificate_type3
            ,inserted.certificate_type4          as mfg_certificate_type4
            ,deleted.certificate_type4           as zoho_certificate_type4
            ,inserted.account_type_id            as mfg_account_type_id
            ,deleted.account_type_id             as zoho_account_type_id
            ,inserted.industry_id                as mfg_industry_id
            ,deleted.industry_id                 as zoho_industry_id
            ,inserted.LinkedIn_URL               as mfg_linkedin_communication
            ,deleted.LinkedIn_URL                as zoho_linkedn_URL
            ,inserted.Skype_ID                   as mfg_skypeid_communication
            ,deleted.Skype_ID                    as zoho_Skype_ID
            ,'zoho_company_account'              as table_name
        into @company_updatesync_log;

        insert  into @company_buyey_supplier_log_details
        select company_id,company_zoho_id,oldfieldid,newfieldid,table_name
,fieldname,transactionmode,user_contact_id,user_zoho_id,module_type
         from(
            select company_id,company_zoho_id, isnull(zoho_account_name,'') as oldfieldid , mfg_name as newfieldid
            , table_name, 'account_name' as fieldname,'update' transactionmode ,null user_contact_id,null user_zoho_id, 1 module_type from @company_updatesync_log
            union all
            select company_id,company_zoho_id, isnull(zoho_duns,''), mfg_duns_number,table_name,'duns','update',null,null ,1 from @company_updatesync_log
            union all
            select company_id,company_zoho_id, isnull(zoho_Employee_Count_id,''), mfg_employee_count_range_id,table_name,'employee_count_id','update',null,null,1 from @company_updatesync_log
            union all
            select company_id,company_zoho_id, isnull(zoho_Website1,''), mfg_communication_value,table_name,'Website1' ,'update' ,null ,null ,1 from @company_updatesync_log
            union all
            select company_id,company_zoho_id, isnull(zoho_phone,''), mfg_phone_communication_value,table_name,'phone' ,'update' ,null ,null ,1 from @company_updatesync_log
            union all
            select company_id,company_zoho_id, isnull(zoho_fax,''), mfg_fax,table_name,'fax' ,'update' ,null ,null ,1 from @company_updatesync_log
            union all
            select company_id,company_zoho_id, isnull(zoho_discipline_level0,''), mfg_discipline_level0,table_name,'discipline_level0' ,'update' ,null ,null ,1 from @company_updatesync_log
            union all
            select company_id,company_zoho_id, isnull(zoho_discipline_level1,''), mfg_discipline_level1,table_name,'discipline_level1' ,'update' ,null ,null ,1 from @company_updatesync_log
            union all
            select company_id,company_zoho_id, isnull(zoho_discipline_level2,''), mfg_discipline_level2,table_name,'discipline_level2' ,'update' ,null ,null ,1 from @company_updatesync_log
            union all
            select company_id,company_zoho_id, isnull(zoho_certificate_type1,''), mfg_certificate_type1,table_name,'certificate_type1' ,'update' ,null ,null ,1 from @company_updatesync_log
            union all
            select company_id,company_zoho_id, isnull(zoho_certificate_type2,''), mfg_certificate_type2,table_name,'certificate_type2' ,'update' ,null ,null ,1 from @company_updatesync_log
            union all
            select company_id,company_zoho_id, isnull(zoho_certificate_type3,''), mfg_certificate_type3,table_name,'certificate_type3' ,'update' ,null ,null ,1 from @company_updatesync_log
            union all
            select company_id,company_zoho_id, isnull(zoho_certificate_type4,''), mfg_certificate_type4,table_name,'certificate_type4' ,'update' ,null ,null ,1 from @company_updatesync_log
            union all
            select company_id,company_zoho_id, zoho_account_type_id, mfg_account_type_id,table_name,'account_type_id' ,'update' ,null ,null ,1 from @company_updatesync_log
            union all
            select company_id,company_zoho_id, isnull(zoho_industry_id,''), mfg_industry_id,table_name,'industry_id' ,'update' ,null ,null ,1     from @company_updatesync_log
              union all
             select  company_id, company_zoho_id, isnull(zoho_linkedn_URL,''), mfg_linkedin_communication, table_name, 'linkedn_URL', 'update', null, null, 1  from @company_updatesync_log
             union all
             select  company_id, company_zoho_id, isnull(zoho_Skype_ID,''), mfg_skypeid_communication, table_name, 'Skype_ID', 'update', null, null, 1  from @company_updatesync_log
        )  abc
        where oldfieldid != newfieldid

         /* getting users details into temp table */
        select a.company_id,a.contact_id,a.user_zoho_id,a.title,a.first_name,a.last_name,a.is_notify_by_email,a.is_validated_buyer
        ,c.User_account_id,c.Account_Name_id , a.email
         into #tmp_zoho_users_details
        from #tmp_mfg_source_details(nolock) a
        join  zoho..zoho_company_account (nolock) b on a.company_id = b.VisionACCTID
        join zoho..zoho_user_accounts (nolock) c on b.company_account_id = c.Account_Name_id and a.contact_id = c.VisionSUPID
        where b.SyncType = 1 AND c.SyncType = 1
        /*  */

		-- print  101
         /* Updating users records into zoho_user_accounts from MFG dB */
        merge zoho..zoho_user_accounts as target
        using #tmp_zoho_users_details as source on
         (target.User_account_id = source.User_account_id and target.synctype = 1)
        when matched
        and (
                 isnull(target.Title,'')                != isnull(source.title,'')
              or isnull(target.first_name,'')           != isnull(source.first_name,'')
              or isnull(target.last_name,'')            != isnull(source.last_name,'')
              or isnull(target.email_opt_out,'')        != case when isnull(target.email_opt_out,'') = source.is_notify_by_email then 1 else source.is_notify_by_email end
              or isnull(target.is_validated_buyer,0)    != isnull(source.is_validated_buyer,0)
			  or isnull(target.email,'')				!= isnull(source.email,'')
            ) then
            update set
                target.title                  = isnull(source.title,'')
                ,target.first_name            = isnull(source.first_name,'')
                ,target.last_name             = isnull(source.last_name,'')
                ,target.email_opt_out         = case when source.is_notify_by_email = 0 then 1 else 0 end
                ,target.is_validated_buyer    = isnull(source.is_validated_buyer,0)
                ,Modified_Time                = @todaydate
				,target.email				  = isnull(source.email,'')
				--,target.IsSync = 0
    --            ,target.IsProcessed = null

        output
             source.contact_id                as usercontact_id
             ,source.user_zoho_id             as userzoho_id
             ,inserted.title                  as mfg_title
             ,deleted.title                   as zoho_title
             ,inserted.first_name             as mfg_first_name
             ,deleted.first_name              as zoho_first_name
             ,inserted.last_name              as mfg_last_name
             ,deleted.last_name               as zoho_last_name
             ,inserted.email_opt_out          as mfg_is_notify_by_email
             ,deleted.email_opt_out           as zoho_email_opt_out
             ,inserted.is_validated_buyer     as mfg_is_validated_buyer
             ,deleted.is_validated_buyer      as zoho_is_validated_buyer
			 ,inserted.email				  as mfg_email
             ,deleted.email					  as zoho_email
             ,'zoho_user_accounts'            as table_name
         into @users_updatesync_details;

        insert  into @company_buyey_supplier_log_details
        select company_id,company_zoho_id,oldfieldid,newfieldid,table_name,fieldname,transactionmode,usercontact_id,userzoho_id,module_type
        from(
            select null company_id , null company_zoho_id, isnull(zoho_title,'') as oldfieldid , mfg_title as newfieldid
            , table_name, 'title' as fieldname,'update' transactionmode ,  usercontact_id, userzoho_id  , 1 module_type from @users_updatesync_details
            union all
            select  null, null, isnull(zoho_first_name,''), mfg_first_name, table_name, 'first_name' ,'update', usercontact_id, userzoho_id, 1    from @users_updatesync_details
            union all
             select  null, null, isnull(zoho_last_name,''), mfg_last_name, table_name, 'last_name', 'update', usercontact_id, userzoho_id, 1  from @users_updatesync_details
            union all
             select  null, null, isnull(zoho_email_opt_out,''), mfg_is_notify_by_email, table_name, 'email_opt_out', 'update', usercontact_id, userzoho_id, 1  from @users_updatesync_details
             union all
             select  null, null, isnull(zoho_is_validated_buyer,''), mfg_is_validated_buyer, table_name, 'is_validated_buyer', 'update', usercontact_id, userzoho_id, 1  from @users_updatesync_details
			union all
             select  null, null, isnull(zoho_email,''), mfg_email, table_name, 'email', 'update', usercontact_id, userzoho_id, 1  from @users_updatesync_details

         )  abc
        where oldfieldid != newfieldid
        /* */

		/* here deleted such company id records from zoho table which are is_admin = 0 and only one record into mp_contact table
		 against particular company_id*/
				
		select company_id ,address_id into #deleteaddress from (
		  select a.company_id, c.address_id ,  a.is_admin  ,is_admin_cnt
			   from  #tmp_mfg_source_details(nolock) a
			join zoho..zoho_company_account (nolock) b on a.company_id = b.VisionACCTID
			join zoho..zoho_User_Company_address(nolock) c on c.company_id =  b.company_account_id
			left join ( 
			  select company_id , count(company_id) is_admin_cnt  from #tmp_mfg_source_details  group by company_id
			   ) d on d.company_id = a.company_id
			 where c.address_type_id = 1 and b.SyncType = 1 and a.is_admin = 0
		 			 and c.address_id is not null
					 ) abc where is_admin_cnt = 1

			if (select count(1) from #deleteaddress ) > 0
			begin
				delete from zoho..zoho_User_Company_address where address_id in (select address_id from #deleteaddress) 
				delete from zoho..zoho_addresses where address_id in (select address_id from #deleteaddress) 
			end
		/* */

       /* code for update company address, where for particular company->for contacts->is_admin = 1 */
       select  a.company_id, a.address1,a.address2, a.city,a.address5,a.zipcode,a.country_id,a.country_name,
		a.REGION_ID,a.state,a.company_zoho_id,c.zoho_users_id,c.address_id,a.address_id [visionaddressid] 
		, row_number() over(partition by a.company_id order by a.company_id , c.address_id) rn
        into #tmp_zoho_company_address_details
        from  #tmp_mfg_source_details(nolock) a
        join zoho..zoho_company_account (nolock) b on a.company_id = b.VisionACCTID
        join zoho..zoho_User_Company_address(nolock) c on c.company_id =  b.company_account_id
         where c.address_type_id = 1 and b.SyncType = 1  and a.is_admin = 1
	-- print  103

		merge zoho..zoho_addresses as target
        using #tmp_zoho_company_address_details as source on
           ( target.address_id = source.address_id and source.rn=1 and target.address_type_id = 1 AND isnull(source.country_name,'') <> '')
        when matched and target.Address_type_id = 1
        and (
                isnull(target.street_address_1,'')    != isnull(source.address1,'')
                or isnull(target.street_address_2,'') != isnull(source.address2,'')
                or isnull(target.city,'')             != isnull(source.city,'')
                or isnull(target.zip_code,'')         != isnull(source.zipcode,'')
                or isnull(target.country,'')          != isnull(source.country_name,'')
                or isnull(target.[state],'')          != isnull(source.[state],'')
            )  then
        update set
            target.street_address_1        = source.address1
            ,target.street_address_2    = case when source.address2 is null or source.address2 = '' then target.street_address_2 else source.address2 end
            ,target.city                = source.city
            ,target.zip_code            = source.zipcode
            ,target.country                = source.country_name
            ,target.[state]                = source.[state]
            ,target.vision_address_id      = source.visionaddressid
         output
            source.company_id
            ,source.company_zoho_id                 as company_zoho_id
            ,inserted.street_address_1              as mfg_address1
            ,deleted.street_address_1               as zoho_street_address_1
            ,inserted.street_address_2              as mfg_address2
            ,deleted.street_address_2               as zoho_street_address_2
            ,inserted.city                          as mfg_city
            ,deleted.city                           as zoho_city
            ,inserted.zip_code                      as mfg_zipcode
            ,deleted.zip_code                       as zoho_zip_code
            ,inserted.country                       as mfg_country_name
            ,deleted.country                        as zoho_country
            ,inserted.[state]                       as mfg_state
            ,deleted.[state]                        as zoho_state
            ,null                                   as contact_id
            ,null                                   as contact_zoho_id
            ,'zoho_addresses'                       as table_name
        into @company_updatesync_address_log;
        /* */

        /* code for update user address, which are assigned for particular contacts */
        select  a.company_id, a.address1,a.address2, a.city,a.address5,a.zipcode,a.country_id,a.country_name,
a.REGION_ID,a.state,a.company_zoho_id,c.zoho_users_id,c.address_id,b.VisionSUPID,a.user_zoho_id,a.address_id [visionaddressid]
        into #tmp_zoho_users_addess_details
        from #tmp_mfg_source_details(nolock) a
        join zoho..zoho_user_accounts (nolock) b on a.contact_id = b.VisionSUPID
        join zoho..zoho_User_Company_address(nolock) c on b.User_account_id = c.zoho_users_id
        where c.address_type_id = 1 and b.SyncType = 1
-- print  104
		 merge zoho..zoho_addresses as target
        using #tmp_zoho_users_addess_details as source on
           ( target.address_id = source.address_id and target.address_type_id = 1)
        when matched and target.address_type_id = 1
        and (
                isnull(target.street_address_1,'')    != source.address1
                or isnull(target.street_address_2,'') != isnull(source.address2,'')
                or isnull(target.city,'')             != source.city
                or isnull(target.zip_code,'')         != source.zipcode
                or isnull(target.country,'')          != source.country_name
                or isnull(target.[state],'')          != source.[state]

            )  then
        update set
            target.street_address_1        = source.address1
            ,target.street_address_2    = case when source.address2 is null or source.address2 = '' then target.street_address_2 else source.address2 end
            ,target.city                = source.city
            ,target.zip_code            = source.zipcode
            ,target.country                = source.country_name
            ,target.[state]                = source.[state]
            ,target.vision_address_id      = source.visionaddressid
         output
            source.company_id
            ,source.company_zoho_id                 as company_zoho_id
            ,inserted.street_address_1              as mfg_address1
            ,deleted.street_address_1               as zoho_street_address_1
            ,inserted.street_address_2              as mfg_address2
            ,deleted.street_address_2               as zoho_street_address_2
            ,inserted.city                          as mfg_city
            ,deleted.city                           as zoho_city
            ,inserted.zip_code                      as mfg_zipcode
            ,deleted.zip_code                       as zoho_zip_code
            ,inserted.country                       as mfg_country_name
            ,deleted.country                        as zoho_country
            ,inserted.[state]                       as mfg_state
            ,deleted.[state]                        as zoho_state
            ,source.VisionSUPID                     as contact_id
            ,source.user_zoho_id                    as contact_zoho_id
            ,'zoho_addresses'                       as table_name
        into @company_updatesync_address_log;
        /* */

        insert  into @company_buyey_supplier_log_details
        select company_id,company_zoho_id,oldfieldid,newfieldid,table_name,fieldname,transactionmode,user_contact_id,user_zoho_id,module_type
         from(
            select company_id,company_zoho_id, isnull(zoho_street_address_1,'') as oldfieldid , mfg_address1 as newfieldid
            , table_name, 'street_address_1' as fieldname,'update' transactionmode ,contact_id user_contact_id,contact_zoho_id user_zoho_id, 1 module_type
            from @company_updatesync_address_log
            union all
             select company_id,company_zoho_id,isnull(zoho_street_address_2,''),mfg_address2,table_name,'street_address_2','update',contact_id,contact_zoho_id, 1
            from @company_updatesync_address_log
            union all
             select company_id,company_zoho_id,isnull(zoho_city,''),mfg_city,table_name,'city','update',contact_id,contact_zoho_id,1
            from @company_updatesync_address_log
            union all
             select company_id,company_zoho_id, isnull(zoho_zip_code,''),mfg_zipcode,table_name,'zip_code','update',contact_id,contact_zoho_id,1
            from @company_updatesync_address_log
            union all
             select company_id,company_zoho_id, isnull(zoho_country,''), mfg_country_name , table_name, 'country' ,'update' ,contact_id,contact_zoho_id, 1
            from @company_updatesync_address_log
            union all
             select company_id,company_zoho_id, isnull(zoho_state,'') , mfg_state , table_name, 'state' ,'update' ,contact_id ,contact_zoho_id , 1
            from @company_updatesync_address_log
        )  abc
        where oldfieldid != newfieldid

        /* creating log for updated records */
        insert into zoho..zoho_sink_down_logs
		(zoho_module_id,company_id,company_zoho_id,log_date,table_name,field_name,oldfieldvalue,newfieldvalue,transaction_mode,user_contact_id,user_zoho_id)
        select  distinct 20 as zoho_module_id,a.company_id,a.company_zoho_id,@todaydate,a.table_name,a.fieldname
		,a.oldfieldvalue,a.newfieldvalue,a.tranmode,a.user_contact_id,a.user_zoho_id
        from @company_buyey_supplier_log_details a
        where module_type = 1
        /* */

        /* update for account */
        select distinct company_id
        into #update_company_list
        from @company_buyey_supplier_log_details

        update a
        set  a.IsSync = 0
        ,a.IsProcessed = null
        ,a.Modified_Time = @todaydate
        from zoho..zoho_company_account a
        join #update_company_list b on a.VisionACCTID = b.company_id
        where a.synctype = 1;
        /* */

        /* update for zoho_user_accounts */
        select distinct b.User_account_id
        into #update_contact_list
        from @company_buyey_supplier_log_details a
        join zoho..zoho_user_accounts (nolock) b on a.user_contact_id = b.VisionSUPID
        where b.synctype = 1

        update a
        set  a.IsSync = 0
        ,a.IsProcessed = null
        ,a.Modified_Time = @todaydate
        from zoho..zoho_user_accounts a
        join #update_contact_list b on a.User_account_id = b.User_account_id
        where a.synctype = 1
        /* */

        insert into zoho..zoho_sink_down_job_running_logs (zoho_module_id,job_date,job_status)
        select 20 zoho_module_id , @todaydate , 'success : account/buyer/supplier update sync'

/* M2-2409 Zoho Field Updates - Contacts - RFQ - DB */

		
		select * 
		into #buyerRFQinfo 
		from 
		(
		select
			a.contact_id 
			,c.user_zoho_id
			,d.user_account_id
			,min(status_date) First_RFQ_Release_Date
			,max(status_date) Most_Recent_RFQ_Release_Date
			, count(distinct a.rfq_id) as Number_of_RFQs_Released
			, row_number () over (partition by a.contact_id order by a.contact_id) as rn
		
		from 
		mp_rfq a (nolock)
		join mp_rfq_release_history b (nolock) on a.rfq_id = b.rfq_id
		join mp_contacts			c (nolock) on a.contact_id = c.contact_id
		join zoho..zoho_user_accounts d (nolock)  on  c.user_zoho_id = d.zoho_id and d.SyncType = 1 
		where c.user_zoho_id <> '0'
		group by a.contact_id ,c.user_zoho_id ,d.User_account_id
		) a
		where rn = 1 
		
-- print  105
		merge zoho..zoho_user_accounts as target
        using #buyerRFQinfo as source on
         (target.zoho_id = source.user_zoho_id and target.synctype = 1)
        when matched
        and (
                 isnull(target.First_RFQ_Release_Date,'')           != source.First_RFQ_Release_Date
              or isnull(target.Most_Recent_RFQ_Release_Date,'')     != source.Most_Recent_RFQ_Release_Date
              or isnull(target.Number_of_RFQs_Released,0)          != source.Number_of_RFQs_Released
              
            ) then
            update set
                target.First_RFQ_Release_Date           = source.First_RFQ_Release_Date
                ,target.Most_Recent_RFQ_Release_Date    = source.Most_Recent_RFQ_Release_Date
                ,target.Number_of_RFQs_Released         = source.Number_of_RFQs_Released
                ,target.Modified_Time							= @todaydate
				,target.issync = 0
				,target.isprocessed = null
		;
/*  */


/* M2-2540 Zoho - Supplier Upgrade Request Data Update - DB */
	select distinct a.contact_id , 1 UpgradeRequest  
	/* M2-2638 Zoho - Supplier Upgrade Request Date - DB */
	--, max(activity_date) UpgradeDate
	, dateadd(hour, -5,max(activity_date)) UpgradeDate
	/**/
	into #supplierupgraderequest
	from mp_track_user_activities	(nolock) a
	join mp_contacts				(nolock) b on a.contact_id = b.contact_id
	where activity_id = 3
	group by a.contact_id 
-- print  106
	merge zoho..zoho_user_accounts as target
    using #supplierupgraderequest as source on
        (target.visionsupid = source.contact_id and target.synctype = 1)
    when matched
    and (
            isnull(target.UpgradeRequest,0)				!= source.UpgradeRequest  
			or isnull(target.UpgradeDate,'2000-01-01')	!= source.UpgradeDate            
        ) then
        update set
            target.UpgradeRequest           = source.UpgradeRequest 
			,target.UpgradeDate				= source.UpgradeDate 
            ,target.Modified_Time			= @todaydate
			,target.issync					= 0
			,target.isprocessed				= null
	;
/**/


--/* M2-2714 ZOHO - Strip mapping - DB */
--	SELECT 
--		company_id 
--		,CASE  WHEN account_type =  86 THEN 'Platinum' WHEN account_type =  85 THEN 'Gold' END account_status
--		,CASE  WHEN account_type_source =  133 THEN 'Zoho Subscriptions' WHEN (account_type_source =  132 or account_type_source IS NULL)  THEN 'Zoho CRM' WHEN (account_type_source =  131)  THEN 'MFG Vision'  END account_status_source
--	INTO #supplieraccounttype
--	FROM mp_registered_supplier (NOLOCK)
--	UNION
--	SELECT DISTINCT 
--		e.company_id AS CompanyId
--		,'Silver' account_status
--		,'Zoho Subscriptions' SubscriptionSource
--	FROM mp_gateway_subscription_customers a (NOLOCK)
--	JOIN  
--		(
--			SELECT a.id, a.customer_id, a.plan_id
--			FROM  [dbo].mp_gateway_subscriptions (NOLOCK) a
--			JOIN
--			(
--				SELECT customer_id , MAX(id) subscription_id FROM  [dbo].mp_gateway_subscriptions (NOLOCK)
--				GROUP BY customer_id
--			) b on a.id = b.subscription_id
--		) b on a.id =  b.customer_id
--	JOIN mp_gateway_subscription_pricing_plans	c (NOLOCK) ON  b.plan_id = c.id
--	JOIN mp_gateway_subscription_products		d (NOLOCK) ON  c.product_id = d.id
--	JOIN mp_contacts e (NOLOCK) ON a.supplier_id = e.contact_id 
--	WHERE d.name IN ('Silver')

--	merge zoho..zoho_company_account as target
--    using #supplieraccounttype as source on
--        (target.VisionACCTID= source.company_id and target.synctype = 1)
--    when matched then
--        update set
--            target.account_status           = source.account_status 
--			,target.account_status_source	= source.account_status_source 
--            ,target.Modified_Time			= @todaydate
--			,target.issync					= 0
--			,target.isprocessed				= null
--	;
--/**/


-- print  107
	/* M2-3265 ZOHO (Accounts and Contacts Create/Update Sync SQL Db Job changes for updating the [Customer Support Rep.] Field.) - DB */
	--SELECT a.company_id ,a.assigned_customer_rep , b.assigned_customer_rep ,isprocessed ,issync
	UPDATE b SET b.assigned_customer_rep = a.assigned_customer_rep , issync = 0 ,isprocessed	= NULL
	FROM mp_companies (NOLOCK) a
	JOIN zoho..zoho_company_account (NOLOCK) b ON a.company_id = b.VisionACCTID
	WHERE ISNULL(a.assigned_customer_rep,0) <> ISNULL(b.assigned_customer_rep,0) AND b.synctype = 1 
	--AND b.assigned_customer_rep IS NOT NULL
	/**/

-- print  108
	/* M2-3340 Zoho - RFQ Marketplace Access Sync - DB */
	--select b.VisionACCTID ,rfq_access_capabilities_level0 , rfq_access_capabilities_level1 , a.level0, a.level1 
	update b set b.rfq_access_capabilities_level0 = a.level0 , b.rfq_access_capabilities_level1 = a.level1  , issync = 0 ,isprocessed	= NULL
	from 
	(
		select distinct
			a.company_id
			,STUFF
			(
				(
					select distinct ',' + convert(varchar,b1.parent_part_category_id )
					from mp_gateway_subscription_company_processes (nolock) a1
					join mp_mst_part_category (nolock) b1 on a1.part_category_id = b1.part_category_id
					where a1.company_id = a.company_id
					for xml path('')
				), 1, 1, ''
			) AS level0
			,STUFF
			(
				(
					select distinct ',' + convert(varchar,part_category_id )
					from mp_gateway_subscription_company_processes (nolock)
					where company_id = a.company_id
					for xml path('')
				), 1, 1, ''
			) AS level1
		from mp_gateway_subscription_company_processes(nolock) a
	) a
	join zoho..zoho_company_account (NOLOCK) b on a.company_id = b.VisionACCTID AND b.synctype = 1 
	where 
	(	
		len(isnull(a.level0,0)) <> len(isnull(b.rfq_access_capabilities_level0,0))
		or
		len(isnull(a.level1,0)) <> len(isnull(b.rfq_access_capabilities_level1,0))
	)
	/**/
	

	/* M2-3605 Buyer - Add a question to the Industry modal and push data to ZOHO - ZOHO DB */
	UPDATE B SET 
		B.IndustryModalQuestions = A.Questions 
		, B.IndustryModalAnswers = A.Answers 
		, B.IsSync = 0 , B.ISPROCESSED = NULL
	FROM mpBuyerIndustryModalAnswers  A (nolock)
	JOIN ZOHO..ZOHO_USER_ACCOUNTS B  (nolock) ON A.BuyeId = B.VISIONSUPID 
	WHERE B.SYNCTYPE = 1 AND 
	(
		LEN(ISNULL(a.Questions,'')) <> LEN(ISNULL(b.IndustryModalQuestions,''))
		OR
		LEN(ISNULL(a.Answers,'')) <> LEN(ISNULL(b.IndustryModalAnswers,''))
	)
	/**/

	/* M2-3693 M - Need to change the 'Public Profile' URL while changing the Company Name from Manufacturer profile - ZOHO DB */
	UPDATE b SET 
		b.companyurl = a.companyurl 
		/* M2-3750 ZOHO - bi-directional full profile on / off */
		, b.Hide_Directory_Profile = a.is_hide_directory_profile
		/**/
		, b.IsSync = 0 
		, b.Isprocessed = NULL
	FROM mp_companies  a (NOLOCK)
	JOIN zoho..zoho_company_account b  (NOLOCK) ON a.company_id = b.visionacctid 
	WHERE 
	b.SYNCTYPE = 1 AND 
	(
		LEN(ISNULL(a.companyurl,'')) <> LEN(ISNULL(b.companyurl,''))
		/* M2-3750 ZOHO - bi-directional full profile on / off */
		OR ISNULL(a.is_hide_directory_profile,0) <> ISNULL(b.Hide_Directory_Profile,0)
		/**/
	)



	/**/


	-- print  109
	UPDATE B SET B.is_validated_buyer = A.Is_Validated_Buyer , B.IsSync = 0 , B.ISPROCESSED = NULL
	FROM MP_CONTACTS  A (nolock)
	JOIN ZOHO..ZOHO_USER_ACCOUNTS B  (nolock) ON A.CONTACT_ID = B.VISIONSUPID 
		AND ISNULL(a.Is_Validated_Buyer, 0)  <>  ISNULL(b.is_validated_buyer,0)
	WHERE IS_BUYER = 1  and B.SYNCTYPE = 1
	-- print  110
	
	commit

    end try

    begin catch
			-- print  111
           rollback

           insert into zoho..zoho_sink_down_job_running_logs
            (zoho_module_id,job_date,job_status)
            select 20 zoho_module_id , @todaydate , 'fail : account/buyer/supplier' + error_message()
            set @lastidentity = @@identity
			
           insert into zoho..zoho_sink_down_job_running_logs_detail (job_running_id , zoho_id)
           select @lastidentity , company_zoho_id     from #tmp_mfg_company_details  (nolock)

    end catch

end
