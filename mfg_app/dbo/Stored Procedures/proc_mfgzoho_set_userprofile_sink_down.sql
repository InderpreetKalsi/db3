CREATE procedure [dbo].[proc_mfgzoho_set_userprofile_sink_down]
as
begin
/*
	created on	: nov 15, 2018
	m2-451 create sql jobs to import and export data for user profile module
*/

	-- 1. company account
	drop table if exists #tmp_zoho_user_company_address_details

		select 
			a.account_name_id, a.user_account_id , a.title, a.first_name ,a.last_name, a.email user_email, a.phone user_phone, a.mobile user_mobile
			, a.fax user_fax, a.skype_id, a.linkedin_url, a.twitter, a.zoho_id user_zoho_id
			,b.account_name,  a.account_type_id, b.phone company_phone , b.fax company_fax, b.employee_count_id, b.duns, b.website1 , b.zoho_id company_zoho_id
			,c.address_type_id
			,d.street_address_1, d.street_address_2, d.city, d.state, d.country, d.postal_code, d.zip_code ,  b.MFGLegacyACCTID legacy_company_id, MFGLegacySupID legacy_contact_id
		into #tmp_zoho_user_company_address_details 
		from zoho.dbo.zoho_user_accounts  a
		join zoho.dbo.zoho_company_account b on a.account_name_id = b.company_account_id
		left join zoho.dbo.zoho_user_company_address c on a.User_account_id = c.zoho_users_id
		left join zoho.dbo.zoho_addresses d on c.address_id = d.address_id
		where  a.synctype = 2 and a.issync = 0
			
		declare @account_name_id	bigint
		declare @user_account_id	bigint
		declare @title				varchar(500)
		declare @first_name			varchar(500)
		declare @last_name			varchar(500)
		declare @user_email			varchar(500)
		declare @user_phone			varchar(500)
		declare @user_mobile		varchar(500)
		declare @user_fax			varchar(500)
		declare @skype_id			varchar(500)
		declare @linkedin_url		varchar(500)
		declare @twitter			varchar(500)
		declare @user_zoho_id		varchar(500)
		declare @account_name		varchar(500)
		declare @account_type_id	int
		declare @company_phone		varchar(500)
		declare @company_fax		varchar(500)
		declare @employee_count_id	int
		declare @duns				varchar(500)
		declare @website1			varchar(500)
		declare @company_zoho_id	varchar(500)
		declare @address_type_id	bigint
		declare @street_address_1	varchar(500)
		declare @street_address_2	varchar(500)
		declare @city				varchar(500)
		declare @state				varchar(500)
		declare @country			varchar(500)
		declare @postal_code		varchar(500)
		declare @zip_code			varchar(500)

		declare @company_count		int
		declare @company_id			bigint
		declare @user_id			bigint
		declare @address_id			bigint
		declare @legacy_company_id	int
		declare @legacy_contact_id  int

		declare db_zoho_user_company_address cursor for select * from #tmp_zoho_user_company_address_details

		open db_zoho_user_company_address  

		fetch next from db_zoho_user_company_address into @account_name_id, @user_account_id, @title, @first_name, @last_name, @user_email, @user_phone, @user_mobile, @user_fax, @skype_id, @linkedin_url, @twitter, @user_zoho_id, @account_name, @account_type_id, @company_phone, @company_fax, @employee_count_id, @duns, @website1, @company_zoho_id, @address_type_id, @street_address_1, @street_address_2, @city, @state, @country, @postal_code, @zip_code  , @legacy_company_id , @legacy_contact_id
	
	
		while @@fetch_status = 0  
		begin  
			
				-- company
				if exists (select * from mp_companies where company_id  =  @legacy_company_id)
				begin
				
					set @company_id = (select company_id from mp_companies where  company_id  =  @legacy_company_id)

					update mp_companies set company_zoho_id = @company_zoho_id	where company_id = @company_id

				end
				else 
				begin
				
					insert into mp_companies
					(name, description, duns_number, employee_count_range_id, is_active, company_zoho_id)
					select @account_name, @account_name , @duns , @employee_count_id , 1 , @company_zoho_id
					set @company_id = @@identity

				end

				-- company communication
				if not exists (select * from mp_communication_details where company_id = @company_id and communication_type_id=1 )
				begin
					insert into mp_communication_details (communication_type_id, company_id ,  communication_value, is_valid)
					select distinct 1 , @company_id ,  company_phone, 1  from #tmp_zoho_user_company_address_details a
					where account_name_id = @account_name_id and company_phone is not null
				end

				if not exists (select * from mp_communication_details where company_id = @company_id and communication_type_id=2 )
				begin
					insert into mp_communication_details (communication_type_id, company_id ,  communication_value, is_valid)
					select distinct 2 , @company_id ,  company_fax, 1  from #tmp_zoho_user_company_address_details a
					where account_name_id = @account_name_id and company_fax is not null
				end
			
				if not exists (select * from mp_communication_details where company_id = @company_id and communication_type_id=4 )
				begin
					insert into mp_communication_details (communication_type_id, company_id ,  communication_value, is_valid)
					select distinct 4 , @company_id ,  website1, 1  from #tmp_zoho_user_company_address_details a
					where account_name_id = @account_name_id and website1 is not null
				end


				-- users
				if exists (select * from mp_contacts where contact_id = @legacy_contact_id and is_buyer = case when @account_type_id = 2 then 1 else 0 end and company_id = @company_id)
				begin
					set @user_id = (select contact_id from mp_contacts where contact_id = @legacy_contact_id  and is_buyer = case when @account_type_id = 2 then 1 else 0 end  and company_id = @company_id)

					update mp_contacts set user_zoho_id= @user_zoho_id	where contact_id = @user_id
				
				end
				else 
				begin
					insert into mp_contacts
					(company_id,title,first_name,last_name,is_buyer,is_admin,created_on,user_zoho_id,is_active)
					select @company_id, @title , @first_name , @last_name , case when @account_type_id = 2 then 1 else 0 end , 0
					, getdate() , @user_zoho_id , 1
					set @user_id = @@identity
				end
			
				-- user communication
				if not exists (select * from mp_communication_details where contact_id = @user_id and communication_type_id=1 )
				begin
					insert into mp_communication_details (communication_type_id,  contact_id, communication_value, is_valid)
					select  distinct  1 ,  @user_id , user_phone, 1  from #tmp_zoho_user_company_address_details a
					where account_name_id = @account_name_id and user_phone is not null  and user_account_id = @user_account_id 

				end

				if not exists (select * from mp_communication_details where contact_id = @user_id and communication_type_id=2 )
				begin
					insert into mp_communication_details (communication_type_id,  contact_id, communication_value, is_valid)
					select  distinct  2 ,  @user_id , user_fax, 1  from #tmp_zoho_user_company_address_details a
					where account_name_id = @account_name_id and user_fax is not null and user_account_id = @user_account_id 
				end
			
				if not exists (select * from mp_communication_details where contact_id = @user_id and communication_type_id=3 )
				begin
					insert into mp_communication_details (communication_type_id,  contact_id, communication_value, is_valid)
					select distinct  3 ,  @user_id , user_email, 1  from #tmp_zoho_user_company_address_details a
					where account_name_id = @account_name_id and user_email is not null and user_account_id = @user_account_id 
				end

				if not exists (select * from mp_communication_details where contact_id = @user_id and communication_type_id=5 )
				begin
					insert into mp_communication_details (communication_type_id,  contact_id, communication_value, is_valid)
					select distinct  5 ,  @user_id , user_email, 1  from #tmp_zoho_user_company_address_details a
					where account_name_id = @account_name_id and user_email is not null and user_account_id = @user_account_id 
				end

				if not exists (select * from mp_communication_details where contact_id = @user_id and communication_type_id=6 )
				begin
					insert into mp_communication_details (communication_type_id,  contact_id, communication_value, is_valid)
					select distinct  6 ,  @user_id , skype_id, 1  from #tmp_zoho_user_company_address_details a
					where account_name_id = @account_name_id and skype_id is not null and user_account_id = @user_account_id 
				end

				if not exists (select * from mp_communication_details where contact_id = @user_id and communication_type_id=8 )
				begin
					insert into mp_communication_details (communication_type_id,  contact_id, communication_value, is_valid)
					select distinct  8 ,  @user_id , linkedin_url, 1  from #tmp_zoho_user_company_address_details a
					where account_name_id = @account_name_id and linkedin_url is not null and user_account_id = @user_account_id 
				end

				if not exists (select * from mp_communication_details where contact_id = @user_id and communication_type_id=10 )
				begin
					insert into mp_communication_details (communication_type_id,  contact_id, communication_value, is_valid)
					select distinct  10 ,  @user_id , twitter, 1  from #tmp_zoho_user_company_address_details a
					where account_name_id = @account_name_id and twitter is not null and user_account_id = @user_account_id 
				end
					
				-- user address
				if @address_type_id = 1
				begin
				
					if exists (select * from #tmp_zoho_user_company_address_details a where  account_name_id = @account_name_id and user_account_id = @user_account_id and address_type_id = 1 and len(isnull(street_address_1,'') + isnull(street_address_2,'')+isnull(city,'')+isnull(state,'')+isnull(country,'')+isnull(postal_code,'')+isnull(zip_code,'')) > 0)	
					begin			
						insert into mp_addresses
						(country_id,	region_id	,address1	,address2	,address3	,address4	,address5	,show_in_profile	,show_only_state_city	,is_active)
						select 
							isnull(b.country_id,0) country_id, isnull(c.region_id,0)  as region_id, street_address_1, street_address_2 
							, postal_code, city, zip_code, 0 show_in_profile, 0 show_only_state_city, 1 is_active
						from #tmp_zoho_user_company_address_details a
						left join mp_mst_country b on a.country = b.country_name
						left join mp_mst_region c on a.state = c.region_name
						where account_name_id = @account_name_id and user_account_id = @user_account_id and address_type_id = 1
						and len(isnull(street_address_1,'') + isnull(street_address_2,'')+isnull(city,'')+isnull(state,'')+isnull(country,'')+isnull(postal_code,'')+isnull(zip_code,'')) > 0
						set @address_id = @@identity

						update mp_contacts set 	address_id = @address_id where contact_id = @user_id
					end
				
						
				end
				else if @account_type_id = 2
				begin 

					if exists (select * from #tmp_zoho_user_company_address_details a where  account_name_id = @account_name_id and user_account_id = @user_account_id and address_type_id = 2 and len(isnull(street_address_1,'') + isnull(street_address_2,'')+isnull(city,'')+isnull(state,'')+isnull(country,'')+isnull(postal_code,'')+isnull(zip_code,'')) > 0)
					begin			
						insert into mp_addresses
						(country_id,	region_id	,address1	,address2	,address3	,address4	,address5	,show_in_profile	,show_only_state_city	,is_active)
						select 
							isnull(b.country_id,0) country_id, isnull(c.region_id,0)  as region_id, street_address_1, street_address_2 
							, postal_code, city, zip_code, 0 show_in_profile, 0 show_only_state_city, 1 is_active
						from #tmp_zoho_user_company_address_details a
						left join mp_mst_country b on a.country = b.country_name
						left join mp_mst_region c on a.state = c.region_name
						where account_name_id = @account_name_id and user_account_id = @user_account_id and address_type_id = 2
						and len(isnull(street_address_1,'') + isnull(street_address_2,'')+isnull(city,'')+isnull(state,'')+isnull(country,'')+isnull(postal_code,'')+isnull(zip_code,'')) > 0
						set @address_id = @@identity

						insert into mp_company_shipping_site(comp_id,cont_id,address_id,default_site,site_creation_date)
						select @company_id , @user_id , @address_id , 0 , getdate()
					end
				
				end

				fetch next from db_zoho_user_company_address 
				into @account_name_id, @user_account_id, @title, @first_name, @last_name, @user_email, @user_phone, @user_mobile, @user_fax, @skype_id, @linkedin_url, @twitter, @user_zoho_id, @account_name, @account_type_id, @company_phone, @company_fax, @employee_count_id, @duns, @website1, @company_zoho_id, @address_type_id, @street_address_1, @street_address_2, @city, @state, @country, @postal_code, @zip_code   , @legacy_company_id , @legacy_contact_id
		end
		close db_zoho_user_company_address  
		deallocate db_zoho_user_company_address

		update zoho.dbo.zoho_company_account set issync = 1 , modified_time = getdate() where synctype = 2 and company_account_id in  (select distinct account_name_id from #tmp_zoho_user_company_address_details)
		update zoho.dbo.zoho_user_accounts set issync = 1 , modified_time = getdate() where synctype = 2 and user_account_id in  (select distinct user_account_id from #tmp_zoho_user_company_address_details)


end