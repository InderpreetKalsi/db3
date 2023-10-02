
--exec proc_mfgzoho_set_account_update_sink_up
CREATE procedure [dbo].[proc_mfgzoho_identified_duplicate_address]
as
begin

set nocount on

   

begin try

    -- 1. company account
   

    drop table if exists #tmp_mfg_company_details
    drop table if exists #tmp_mfg_source_details
	drop table if exists #mfg_addr
   
    /* Fetch those records which are available in both database MFG and Zoho */
	  select a.company_id
        into #tmp_mfg_company_details
        from mp_companies (nolock) a
        where  a.company_id in 
        ( select  VisionACCTID 
				 from  zoho..zoho_company_account(nolock) where SyncType = 1
				 and  company_account_id in ( select company_id
				 from  zoho..zoho_user_company_address  (nolock) 
				 where address_type_id = 1 and company_id is not null 
				 group by company_id 
				 having count(address_type_id) > 1
		 )
	    )
        and a.company_id in(5175)


		--drop table #tmp_mfg_company_details
    begin transaction

          
           /* This is users level information*/
            select
            distinct
            a.company_id
            , ma.address1
            , ma.address2
            , ma.address4 as city
            , ma.address5 ----state
            , ma.address3 as zipcode
            , mc.country_name
            , mr.region_name as [state]
            , b.contact_id
            , b.is_admin
        into #tmp_mfg_source_details
        from #tmp_mfg_company_details (nolock) a
        left join mp_contacts (nolock) b on a.company_id = b.company_id
        left join mp_addresses ma (nolock) on b.address_id = ma.address_id -- need to check only update mailing address
        left join mp_mst_country mc (nolock) on ma.country_id = mc.country_id
        left join mp_mst_region mr (nolock) on ma.region_id = mr.region_id
        left join #tmp_communication_details(nolock) cd on cd.contact_id = b.contact_id
		where  b.is_admin = 1  
        /* */

	
		--select * from  #tmp_mfg_source_details 

			
		select distinct a.address1,a.address2, a.city,a.zipcode,a.country_name,a.state,c.company_id ,c.address_id
		into #mfg_addr
		from #tmp_mfg_source_details a
		join zoho..zoho_user_accounts (nolock) b on a.contact_id = b.VisionSUPID
        join zoho..zoho_User_Company_address(nolock) c on c.company_id =  b.Account_Name_id
         where c.address_type_id = 1 and b.SyncType = 1  and a.is_admin = 1 
	   	 
		 --drop table #mfg_addr
	--drop table #deletedfromzohoaddress
	select address1,address2, city,zipcode,country_name,state from #mfg_addr
	except
       	select c.street_address_1,c.street_address_2,c.city,c.postal_code,c.country,c.state --,c.address_id, b.company_id
		--into #deletedfromzohoaddress
		from   zoho..zoho_user_accounts (nolock) a
        join zoho..zoho_User_Company_address(nolock) b on b.company_id =  a.Account_Name_id
		join zoho..zoho_addresses(nolock) c on c.address_id = b.address_id and c.address_type_id =1
		join #mfg_addr d on b.company_id = d.company_id
        where b.address_type_id = 1 and a.SyncType = 1 
		and  c.street_address_1 !=  d.address1
		and c.city != d.city
		and c.country != d.country_name
		and c.state !=d.state
		and c.postal_code != d.zipcode 
		and ( c.street_address_2 != d.address2) or (isnull(c.street_address_2,'') = isnull(d.address2,'') )
		
	
       	select c.street_address_1,c.street_address_2,c.city,c.postal_code,c.country,c.state , c.address_id
		--into #deletedfromzohoaddress
		from   zoho..zoho_user_accounts (nolock) a
        join zoho..zoho_User_Company_address(nolock) b on b.company_id =  a.Account_Name_id
		join zoho..zoho_addresses(nolock) c on c.address_id = b.address_id and c.address_type_id =1
		join #mfg_addr d on b.company_id = d.company_id
		except
			select address1,address2, city,zipcode,country_name,state,address_id  from #mfg_addr

	except

		select * from #deletedfromzohoaddress

		begin transaction
		delete b 
		from   #deletedfromzohoaddress (nolock) a
        join zoho..zoho_User_Company_address(nolock) b on b.address_id =  a.address_id

		 

		delete b
		from   #deletedfromzohoaddress (nolock) a
        join zoho..zoho_addresses(nolock) b on b.address_id =  a.address_id


		select b.*
		from   #deletedfromzohoaddress (nolock) a
        join zoho..zoho_User_Company_address(nolock) b on b.address_id =  a.address_id


				select b.*
		from   #deletedfromzohoaddress (nolock) a
        join zoho..zoho_addresses(nolock) b on b.address_id =  a.address_id
		
		commit
		rollback


		




    commit

    end try

    begin catch

           rollback

         
            print  error_message()
            

    end catch

end
