
CREATE procedure [dbo].[proc_mfgzoho_set_userprofile_sink_up]
as
begin
/*
	created on	: nov 15, 2018
	m2-451 create sql jobs to import and export data for user profile module
*/

set nocount on
begin try

	declare @todays_date as datetime = getdate()

	-- 1. company account
	drop table if exists #tmp_mfg_company_details
	drop table if exists #tmp_account_communication_details
	drop table if exists #tmp_company_certificate
	drop table if exists #tmp_company_discipline
	drop table if exists #tmp_company_certificate_mapping

	begin transaction

		/* load companies discipline_level*/
		select distinct a.company_id 
			, (select childid from dbo.fn_rfq_discipline(a.part_category_id,0)) discipline_level0
			, (select childid from dbo.fn_rfq_discipline(a.part_category_id,1)) discipline_level1
			, (select childid from dbo.fn_rfq_discipline(a.part_category_id,2)) discipline_level2
		into #tmp_company_discipline
		from mp_company_processes a 
		join mp_mst_part_category b on a.part_category_id = b.part_category_id
		where b.level in (0,1,2)  and b.status_id = 2 
		/**/


		/* load company certificates */
		select  distinct  a1.company_id 
			,	STUFF((SELECT  ',' +  convert(varchar,a.certificates_id )
				from mp_company_certificates a
				join mp_certificates b on a.certificates_id = b.certificate_id and b.certificate_type_id = 1
				where a.status_id = 2 and a.company_id = a1.company_id
				FOR XML PATH('')), 1, 1, '') AS certificate_type1
			,	STUFF((SELECT  ',' +  convert(varchar,a.certificates_id )
				from mp_company_certificates a
				join mp_certificates b on a.certificates_id = b.certificate_id and b.certificate_type_id = 2
				where a.status_id = 2 and a.company_id = a1.company_id
				FOR XML PATH('')), 1, 1, '') AS certificate_type2
			,	STUFF((SELECT  ',' +  convert(varchar,a.certificates_id )
				from mp_company_certificates a
				join mp_certificates b on a.certificates_id = b.certificate_id and b.certificate_type_id = 3
				where a.status_id = 2 and a.company_id = a1.company_id
				FOR XML PATH('')), 1, 1, '') AS certificate_type3
			,	STUFF((SELECT  ',' +  convert(varchar,a.certificates_id )
				from mp_company_certificates a
				join mp_certificates b on a.certificates_id = b.certificate_id and b.certificate_type_id = 4
				where a.status_id = 2 and a.company_id = a1.company_id
				FOR XML PATH('')), 1, 1, '') AS certificate_type4
		into #tmp_company_certificate
		from mp_company_certificates a1	


		/* company account enteries which are not in zoho account table , fetching & inserting into temp table */
		select * into #tmp_mfg_company_details
		from mp_companies (nolock) a
		where a.company_id not in 
		(
			select distinct isnull(VisionACCTID,'') from zoho.dbo.zoho_company_account where synctype = 1
		)
		and company_zoho_id is null

		/* fetching account communication details in tmp table  */
		select  
			company_id   , [Telephone]   , [Fax]   , [Web]   
		into #tmp_account_communication_details 
		from
		(
		  select company_id, 
			case 
				when communication_type_id = 1 then		'Telephone'
				when communication_type_id = 2 then 	'Fax'
				when communication_type_id = 4 then 	'Web'
			end as communication_type
			, isnull(communication_clean_value, communication_value) communication_value 
		  from  mp_communication_details
		  where company_id != 0 and company_id in  (select distinct company_id from #tmp_mfg_company_details  where company_id != 0 )
		) x
		pivot
		(
		  max(communication_value)
		  for communication_type in([Telephone], [Fax],  [Web] )
		)p

		

		/* inserting into zoho table using above temp table */
		insert into zoho.dbo.zoho_company_account
		(
			account_name, account_type_id, record_image, employee_count_id, duns, industry_id ,VisionACCTID
			, synctype, issync, created_time , phone, fax,  website1 ,discipline_level0 ,discipline_level1,discipline_level2 ,certificate_type1
			, certificate_type2 ,certificate_type3,certificate_type4, locationId ,manager_id
		)
		select 
			distinct 
			a.name as account_name
			,case when (select count(*) from (select distinct company_id,is_buyer from mp_contacts (nolock) group by company_id , is_buyer ) a1  where company_id = a.company_id group by company_id having count(*) > 1   ) > 1 then 1 when b.is_buyer = 1 then 2 when b.is_buyer = 0 then 3 end account_type_id
			, c.file_name as record_image
			, a.employee_count_range_id as employee_count_id
			, a.duns_number as duns
			, g.industry_type_id as industry_id
			, a.company_id as mfglegacyacctid
			, 1 as synctype
			, 0 as issync
			, @todays_date created_time
			, h.Telephone as telephone
			, h.fax
			, h.web
			, i.discipline_level0
			, j.discipline_level1
			, k.discipline_level2
			, l.certificate_type1
			, l.certificate_type2
			, l.certificate_type3
			, l.certificate_type4
			, a.Manufacturing_location_id
			--, case when mmtc.territory_classification_id = 2 then 1 
			--		when mmtc.territory_classification_id = 3 then 2  
			--		when mmtc.territory_classification_id = 4 then 3 
			--		when mmtc.territory_classification_id = 5 then 4
			--		when mmtc.territory_classification_id = 6 then 5 end 
					as territory
			, Assigned_SourcingAdvisor
		from #tmp_mfg_company_details (nolock) a
		left join mp_contacts (nolock) b on a.company_id = b.company_id
		left join mp_special_files (nolock) c on a.company_id =  c.comp_id and c.filetype_id = 6 and is_deleted = 0
		left join 
		(	select a.company_id ,	a.industry_type_id from mp_company_industries (nolock) a
			join (select company_id , max(company_industry_id)  company_industry_id from mp_company_industries (nolock)  group by company_id) b
				on a.company_industry_id = b.company_industry_id
		)	g on a.company_id = g.company_id
		left join #tmp_account_communication_details h on a.company_id = h.company_id
		left join 
		(
			select 
				a.company_id 
				,STUFF((SELECT distinct ',' +  convert(varchar,discipline_level0 )
			from #tmp_company_discipline
			where company_id = a.company_id
			FOR XML PATH('')), 1, 1, '') AS discipline_level0
			from mp_companies a
		) i on a.company_id = i.company_id
		left join 
		(
			select 
				a.company_id 
				,STUFF((SELECT distinct ',' +  convert(varchar,discipline_level1 )
			from #tmp_company_discipline
			where company_id = a.company_id
			FOR XML PATH('')), 1, 1, '') AS discipline_level1
			from mp_companies a
		) j on a.company_id = j.company_id
		left join 
		(
			select 
				a.company_id 
				,STUFF((SELECT distinct ',' +  convert(varchar,discipline_level2 )
			from #tmp_company_discipline
			where company_id = a.company_id
			FOR XML PATH('')), 1, 1, '') AS discipline_level2
			from mp_companies a
		) k on a.company_id = k.company_id
		left join #tmp_company_certificate l on  a.company_id = l.company_id
		left join mp_addresses ma (nolock) on b.address_id = ma.address_id 
		left join mp_mst_country mc (nolock) on ma.country_id = mc.country_id 
		left join mp_mst_region mr (nolock) on ma.region_id = mr.region_id 
		--left join mp_mst_territory_classification mmtc (nolock) on mc.territory_classification_id = mmtc.territory_classification_id
		order by a.company_id

	-- 2. company users
	drop table if exists #tmp_mfg_contact_details
	drop table if exists #tmp_communication_details

		/* account users which are not in zoho user table, fetching & inserting into tmp table */
		select 
			a.company_account_id as company_id , b.contact_id, b.title as title
			, case when b.first_name = '' then 'UnknownFirst' else b.first_name  end  as first_name
			, case when b.last_name = '' then 'UnknownLast' else b.last_name  end  as last_name
			, is_buyer , b.contact_type_id
			, c.email
		into #tmp_mfg_contact_details
		from zoho.dbo.zoho_company_account a (nolock)
		join mp_contacts (nolock) b on a.VisionACCTID = b.company_id
		join aspnetusers (nolock) c on b.user_id = c.id
		where a.synctype = 1 --and a.issync = 0 and account_type_id is  not null  -- and a.created_time =  @todays_date  
		and b.company_id <> 0
		and b.contact_id not in ( select distinct isnull(VisionSUPID,'') from zoho.dbo.zoho_user_accounts (nolock) where synctype = 1)
		and user_zoho_id is null 
		order by a.mfglegacyacctid 

		
		/* fetching account users communication details above account users in tmp table  */
		select  
			 contact_id  , [Telephone]   , [Fax]   , [E-Mail]   , [Web]   , [Mobile]   , [Skype Name]   , [LinkedIn]  , [Facebook]   , [Tweeter]
		into #tmp_communication_details 
		from
		(
		  select  contact_id , 
			case 
				when communication_type_id = 1 then		'Telephone'
				when communication_type_id = 2 then 	'Fax'
				when communication_type_id = 3 then 	'E-Mail'
				when communication_type_id = 4 then 	'Web'
				when communication_type_id = 5 then 	'Mobile'
				when communication_type_id = 6 then 	'Skype Name'
				when communication_type_id = 8 then 	'LinkedIn'
				when communication_type_id = 9 then 	'Facebook'
				when communication_type_id = 10	 then	'Tweeter'
			end as communication_type
			, isnull(communication_clean_value, communication_value) communication_value 
		  from  mp_communication_details
		  where contact_id is not null and  contact_id != 0 and contact_id in  (select distinct contact_id from #tmp_mfg_contact_details  where contact_id != 0 )
		) x
		pivot
		(
		  max(communication_value)
		  for communication_type in([Telephone], [Fax], [E-Mail] , [Web] , [Mobile] ,[Skype Name] , [LinkedIn] , [Facebook] , [Tweeter])
		)p

		
		/* inserting account users into zoho user table  */
		insert into zoho.dbo.zoho_user_accounts
		(
			account_name_id ,title, first_name ,last_name, email, phone, mobile, fax, skype_id, linkedin_url, twitter, VisionSUPID,
			synctype, issync ,created_time , status , account_type_id , contact_type_id
		)
		select 
			a.company_id as account_name_id
			, title	
			, first_name	
			, last_name	
			, isnull(a.email,b.[e-mail]) as email
			, telephone as phone
			, mobile as mobile
			, fax as fax
			, [skype name] as skype_id
			, linkedin as linkedin_url
			, tweeter as twitter
			, a.contact_id as mfglegacysupid
			, 1 as synctype
			, 0 as issync
			, @todays_date created_time
			, 0 as status
			, case when is_buyer = 1 then 2 when is_buyer = 0 then 3 end as account_type_id
			, contact_type_id
		from #tmp_mfg_contact_details a
		left join #tmp_communication_details b on a.contact_id = b.contact_id
		where a.contact_id not in ( select distinct isnull(VisionSUPID,'') from zoho.dbo.zoho_user_accounts (nolock))

	-- 3. User Address
	drop table if exists #tmp_mfg_user_address

		declare @running_id		as bigint
		declare @company_id		as bigint
		declare @contact_id		as bigint
		declare @address_id		as bigint
		declare @address1		as nvarchar(max)
		declare @address2		as nvarchar(max)	
		declare @address3		as nvarchar(max)
		declare @address4		as nvarchar(max)
		declare @address5		as nvarchar(max)
		declare @region_name	as nvarchar(max)
		declare @country_name	as nvarchar(max)
		declare @address_type	as int
		declare @next_user_address_id as bigint = 0

		/* fetching address details (mailing & shipping) for newly created user in zoho and inserting into tmp table */
		select 
			row_number() over (order by contact_id , address_type) as running_id, *
		into #tmp_mfg_user_address	
		from 
		(
			select 
				distinct null company_id ,  e.user_account_id contact_id, a.address_id , b.address1 , b.address2, b.address3 , b.address4 , b.address5 , d.region_name ,c.country_name
				, 1 as address_type 

			from mp_contacts a
			join zoho.dbo.zoho_user_accounts  e on a.contact_id = e.VisionSUPID and  e.synctype = 1 and e.issync = 0  and e.created_time = @todays_date  and e.VisionSUPID > 0
			join mp_addresses b on a.address_id = b.address_id
			join mp_mst_country c on b.country_id = c.country_id
			join mp_mst_region d on b.region_id = d.region_id
			union
			select 
				distinct a.comp_id company_id ,  null contact_id , a.address_id , b.address1 , b.address2, b.address3 , b.address4 , b.address5 , d.region_name ,c.country_name
				, 2 as address_type
			from mp_company_shipping_site a
			join zoho.dbo.zoho_company_account  e on a.comp_id = e.VisionACCTID and  e.synctype = 1 and e.issync = 0  and e.created_time = @todays_date  and e.VisionACCTID > 0
			join mp_addresses b on a.address_id = b.address_id
			join mp_mst_country c on b.country_id = c.country_id
			join mp_mst_region d on b.region_id = d.region_id
			where a.comp_id > 0 
			and a.default_site = 1
			union 
			select 
				distinct a.company_id company_id ,  null contact_id, a.address_id , b.address1 , b.address2, b.address3 , b.address4 , b.address5 , d.region_name ,c.country_name
				, 1 as address_type 

			from mp_contacts a
			join zoho.dbo.zoho_user_accounts  e on a.contact_id = e.VisionSUPID 
				and  e.synctype = 1 and e.issync = 0  
				and e.created_time = @todays_date  
				and e.VisionSUPID > 0 and is_admin = 1 
			join mp_addresses b on a.address_id = b.address_id
			join mp_mst_country c on b.country_id = c.country_id
			join mp_mst_region d on b.region_id = d.region_id
		) a


		/* declare cursur for inserting user address into zoho address table */
		declare db_mfg_user_address cursor for select  * from #tmp_mfg_user_address 

		open db_mfg_user_address  

		fetch next from db_mfg_user_address into @running_id, @company_id	,@contact_id	,@address_id	,@address1	,@address2	,@address3	,@address4	,@address5	,@region_name	,@country_name	,@address_type  

		

		while @@fetch_status = 0  
		begin  
				insert into zoho.dbo.zoho_addresses
				(address_type_id, street_address_1, street_address_2, city, state, country, postal_code, zip_code)
				select  @address_type, @address1, @address2, @address4, @region_name, @country_name, @address3, @address5

				set @next_user_address_id = @@identity
		
				insert into zoho.dbo.zoho_user_company_address
				(zoho_users_id, company_id, address_id, address_type_id)
				select contact_id ,company_id , @next_user_address_id , @address_type  from #tmp_mfg_user_address where running_id = @running_id

			  fetch next from db_mfg_user_address 
			  into @running_id, @company_id	,@contact_id	,@address_id	,@address1	,@address2	,@address3	,@address4	,@address5	,@region_name	,@country_name	,@address_type  
		end
		close db_mfg_user_address  
		deallocate db_mfg_user_address 

		/* inserting into zoho table zoho_mst_manager */
		insert into zoho.dbo.zoho_mst_manager (manager_id,manager_name,is_active,zoho_id)
		select  b.contact_id as manager_id , b.first_name + ' ' + b.last_name as manager_name , 1 as is_active , b.user_zoho_id  as zoho_id 
		 from AspNetUsers(nolock) a 
		join mp_contacts(nolock) b on a.id = b.user_id
		where is_pulse_user = 1 
		and b.contact_id not in (select manager_id from zoho.dbo.zoho_mst_manager(nolock))
		/* */


		/* update zoho_user_company_address table for updating company_id with company_account_id */
		update a set  a.company_id = b.company_account_id
		from zoho.dbo.zoho_user_company_address a
		join zoho.dbo.zoho_company_account b on a.company_id = b.VisionACCTID

		commit 
	end try

	begin catch
			rollback
	end catch

end
