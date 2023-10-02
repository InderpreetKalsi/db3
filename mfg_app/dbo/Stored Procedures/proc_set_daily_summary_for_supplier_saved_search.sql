
-- exec proc_set_daily_summary_for_supplier_saved_search @is_registered_supplier =1 ,@pagenumber  = 1, 	 @pagesize    = 100
CREATE procedure [dbo].[proc_set_daily_summary_for_supplier_saved_search]
( @is_registered_supplier bit, @pagenumber int = 1, 	 @pagesize   int = 100)
as
begin
	/* M2-771 Daily RFQ filter emails for manufacturers with Active Contracts- API */
	
	declare @supplier_contact_id as int 
	declare @saved_search_id as int
	declare @last_saved_search_id as int
	declare @rfq_id as int
	declare @today_date  as datetime = getutcdate()
	
	declare @search_filter_name as varchar(500)
	declare @email as nvarchar(max) = ''
	declare @email_msg_subject as nvarchar(250) = ''
	declare @email_msg_body as nvarchar(max) = ''
	declare @email_header as nvarchar(max) = ''
	declare @email_footer as nvarchar(max) = ''
	declare @email_body_rfq_header as nvarchar(max) = ''
	declare @email_body_rfq_footer as nvarchar(max) = ''
	declare @email_body_rfq_parts as nvarchar(max) = ''
	declare @email_body_rfq_header_1 as nvarchar(max) = ''
	declare @email_body_rfq_footer_1 as nvarchar(max) = ''
	declare @email_body_rfq_parts_1 as nvarchar(max) = ''
	declare @rc_count as int
	declare @saved_search_rc_count as int
	


	declare @message_type_id bigint = (select  message_type_id from mp_mst_message_types where message_type_name = 'SUPPLIER_FILTERED_RFQ')
	declare @rc as int = 0
	/* getting email/message subject & body */
		select 
			@email_msg_body = email_body_template, @email_msg_subject = email_subject_template			
		from mp_mst_email_template (nolock) where message_type_id = @message_type_id and is_active = 1 
		
	/**/

	
	set @email_header = substring(@email_msg_body,0, charindex('<!--RFQ Starts', @email_msg_body))
	set @email_body_rfq_header = substring(@email_msg_body,charindex('<!--RFQ Starts', @email_msg_body) , charindex('<!--Part Starts', @email_msg_body)- charindex('<!--RFQ Starts', @email_msg_body))
	set @email_body_rfq_parts = substring(@email_msg_body,charindex('<!--Part Starts', @email_msg_body) , charindex('<!--Part Ends', @email_msg_body) - charindex('<!--Part Starts', @email_msg_body))
	set @email_body_rfq_footer = substring(@email_msg_body,charindex('<!--Part Ends', @email_msg_body), charindex('<!--RFQ Ends', @email_msg_body) - charindex('<!--Part Ends', @email_msg_body))
	set @email_footer = substring(@email_msg_body,charindex('<!--RFQ Ends', @email_msg_body), len(@email_msg_body) -1 )
	
	--select @email_header
	--select @email_body_rfq_header , charindex('<!--RFQ Starts', @email_msg_body) , charindex('<!--Part Starts', @email_msg_body)  , substring( @email_msg_body , 7235, 8962)
	--select @email_body_rfq_parts ,charindex('<!--Part Starts', @email_msg_body)  , charindex('<!--Part Ends', @email_msg_body)

	drop table if exists #supplier_data_based_on_saved_search
	drop table if exists #supplier_data_based_on_saved_search_final_resultset
	drop table if exists #supplier_data_based_on_saved_search_final_resultset_1
	drop table if exists #supplier_saved_search_email

	create table #supplier_data_based_on_saved_search
	(
		supplier_contact_id			int null ,
		saved_search_id				int null ,
		search_filter_name			varchar(500) null ,
		rfq_id						int null ,
		rfq_name					varchar(500) null ,
		part_qty					decimal(10,2) null ,
		quantity_unit_value			varchar(500) null ,
		material_name				varchar(500) null ,
		process						varchar(500) null ,
		post_process				varchar(500) null ,
		closes						datetime null ,
		rfq_status					varchar(500) null ,
		rfq_thumbnail_name			varchar(500) null ,
		is_rfq_like					bit null ,
		total_count					int null ,
		buyer_contact_name			varchar(500) null ,
		buyer_company_id			int null ,
		buyer_contact_id			int null ,
		release_date				datetime null , 
		payment_term_id				int null ,
		city						varchar(500) null ,
		state						varchar(500) null ,
		country						varchar(500) null ,
		NPSScore					int null,
		SpecialInstructions			nvarchar(max) null,
		ship_to						int null,
		rfq_part_id					int null,
		rfq_parts_count             int null
	)


	create table #supplier_saved_search_email
	(
		saved_search_id				int null ,
		email_subject				nvarchar(1000) null ,
		email						nvarchar(max) null
	)


	create nonclustered index nc_supplier_data_based_on_saved_search_rfq_id on #supplier_data_based_on_saved_search(rfq_id)

	
	
	if @is_registered_supplier = 1 
	begin

		declare db_cursor cursor for 
		select  a.contact_id , saved_search_id , search_filter_name 
		from mp_saved_search	(nolock) a 
		join mp_contacts 		(nolock) b on a.contact_id = b.contact_id
		left join mp_scheduled_job	(nolock) c on b.contact_id = c.contact_id and c.scheduler_type_id = 9 
		join mp_registered_supplier (nolock) d on b.company_id = d.company_id and is_registered =1
		where 
			b.is_buyer =  0  
			and is_notify_by_email = 1 
			and c.is_deleted=0
			and is_daily_notification = 1 
			and b.is_active = 1
			and (a.status_id = 2 or a.status_id is null)
			--and  a.contact_id  =1338073 
		order by  a.contact_id , saved_search_id  
		offset @pagesize * (@pagenumber - 1) rows	fetch next @pagesize rows only

		-- c.is_scheduled=1 and this condition removed from above query

	end
	--else
	--	declare db_cursor cursor for select contact_id , saved_search_id , search_filter_name from mp_saved_search where is_daily_notification = 1 	and contact_id not in (select distinct b.contact_id from mp_registered_supplier a join mp_contacts b on a.company_id = b.company_id)
	--	and contact_id not in 
	--	(
	--		select distinct c.contact_id
	--		from mp_exclude_contacts_from_daily_notification a
	--		join aspnetusers b on a.email = b.email
	--		join mp_contacts c on b.contact_id = c.contact_id  and is_buyer = 0
	--	)


	open db_cursor  
	fetch next from db_cursor into @supplier_contact_id   , @saved_search_id , @search_filter_name

	while @@fetch_status = 0  
	begin  

		insert into #supplier_data_based_on_saved_search
		(rfq_id	,rfq_name	,part_qty	,quantity_unit_value	,material_name	,process	,post_process	,closes	,rfq_status	,rfq_thumbnail_name	,is_rfq_like, total_count,	buyer_contact_name	,buyer_company_id	,buyer_contact_id,	release_date	,payment_term_id, city , state ,country ,NPSScore,SpecialInstructions , ship_to  , rfq_part_id,rfq_parts_count)
		exec proc_get_saved_search  
			@save_search_id = @saved_search_id, @contact_id = @supplier_contact_id ,@part_category_id = null 
			, @post_process_id = null ,@material_id = null ,@buyer_location_id= null 
			,@country_id = null, @region_id= null , @proximity_id = null 
			, @geometry_id = 0 , @unit_of_measure_id = 0 , @tolerance_id = null 
			, @par_pagination	=1 , 	@par_per_page_records  =3 , 	@sortorder = 'desc'
	
		update #supplier_data_based_on_saved_search set 
			supplier_contact_id		= @supplier_contact_id ,
			saved_search_id			= @saved_search_id,
			search_filter_name		= @search_filter_name
		where supplier_contact_id is null 

		fetch next from db_cursor into  @supplier_contact_id   , @saved_search_id , @search_filter_name 
	end 

	close db_cursor  
	deallocate db_cursor 
	
	select
		row_number () over (partition by a.supplier_contact_id , a.saved_search_id, a.rfq_id order by a.supplier_contact_id, a.saved_search_id ,Quotes_needed_by desc) rn
		, a.supplier_contact_id	,a.saved_search_id	,a.search_filter_name	,a.rfq_id	,a.rfq_name , j.file_name as rfq_thumbnail
		, b.first_name +' ' +b.last_name as username , k.name as company_name, c.email  , d.Quotes_needed_by , e.part_id , g.part_name 
		, g.part_description 
		, h.discipline_name AS Process
		, dbo.[fn_getTranslatedValue](i.material_name, 'EN') as material_name 
		, convert(int,f.part_qty ) part_qty
		, unit.value AS quantity_unit_value
		, replace(replace(@email_msg_subject,'#Supplier_Company_Name#' ,k.name ),'#Search_Name#' , a.search_filter_name) as email_subject
		, replace(replace(@email_header,'#Supplier_Name#' , b.first_name +' ' +b.last_name),'#Date#' , convert(varchar(10),@today_date, 101)) as email_header
		, replace(replace(replace(replace(replace(replace(@email_body_rfq_header,'#RFQ_Name#' , a.rfq_name),'=#RFQNo#' , '='+convert(varchar(150),d.rfq_guid)) ,'#Quote_End_Date#',
		convert(varchar(20),isnull(d.Quotes_needed_by,''), 101) ),'#Search_Name#', a.search_filter_name),'#RFQ_Thumbnail#' , isnull('https://s3.us-east-2.amazonaws.com/mfg.mp2020.public/thumbnails/'+j.file_name,'https://s3.us-east-2.amazonaws.com/mfg.mp2020.public/thumbnails/636904977928570732_S3_3dbig.png')),'#RFQNo#' ,convert(varchar(150),d.rfq_id)) as email_body_rfq_header
		, replace(replace(replace(replace(replace(@email_body_rfq_parts,'#Part_Name#' , g.part_name),'#Part_Id#' , convert(varchar(50),e.part_id)),'#Part_Desc#',g.part_description),'#Process#', h.discipline_name),'#Material#',dbo.[fn_getTranslatedValue](i.material_name, 'EN')) as email_body_rfq_parts
		, replace( @email_body_rfq_footer,'#RFQNo#' , convert(varchar(150),d.rfq_guid)) email_body_rfq_footer 
		, replace(replace(replace(replace(@email_footer , 'Christopher Jones', isnull(l.first_name,'') + ' ' + isnull(l.last_name,'')),'Title Goes Here',isnull(l.title,'')),'+678-981-4023',isnull(m.communication_value,'')),'Email Me' , isnull(n.email,'')) email_footer , k.company_id,k.Assigned_SourcingAdvisor

	into #supplier_data_based_on_saved_search_final_resultset
	from #supplier_data_based_on_saved_search a
	join mp_contacts b			(nolock) on a.supplier_contact_id = b.contact_id
		AND b.is_notify_by_email = 1  /* M2-4789*/
	join aspnetusers c			(nolock) on b.user_id = c.id
	join mp_rfq d				(nolock) on a.rfq_id = d.rfq_id
	join mp_rfq_parts e			(nolock) on d.rfq_id = e.rfq_id
	join mp_rfq_part_quantity f (nolock) on e.rfq_part_id = f.rfq_part_id
	join mp_parts g				(nolock) on e.part_id = g.part_id
	join mp_mst_part_category h (nolock) on g.part_category_id = h.part_category_id
	join mp_mst_materials i		(nolock) on g.material_id = i.material_id 
	join mp_system_parameters as unit (nolock) ON g.part_qty_unit_id = unit.id AND unit.sys_key = '@UNIT2_LIST' 
	left join mp_special_files j (nolock)  on d.file_id = j.file_id
	join mp_companies k			(nolock) on b.company_id = k.company_id 
	left join mp_contacts l     (nolock) on k.Assigned_SourcingAdvisor = l.contact_id   
	left join mp_communication_details m     (nolock) on l.contact_id   = m.contact_id and m.communication_type_id = 1
	left join aspnetusers n on l.user_id = n.id

	--order by a.supplier_contact_id, a.saved_search_id ,Quotes_needed_by desc
	
	--select * from #supplier_data_based_on_saved_search_final_resultset

	select 
		distinct supplier_contact_id	,saved_search_id	,search_filter_name	,rfq_id	,rfq_name	,rfq_thumbnail,username	,company_name	,email	,Quotes_needed_by	,part_id	,part_name
		,part_description	,Process	,material_name	,email_subject ,email_header ,email_body_rfq_header  
		,email_body_rfq_parts , email_body_rfq_footer , email_footer 
		,stuff((select ' <br />' + cast(convert(varchar,part_qty) + ' '+  quantity_unit_value as varchar(100)) [text()]
         from #supplier_data_based_on_saved_search_final_resultset 
         where saved_search_id = a.saved_search_id and rfq_id = a.rfq_id and part_id = a.part_id
         for xml path(''), type)
        .value('.','nvarchar(max)'),1,7,'') list_of_part_quantity
		
	into #supplier_data_based_on_saved_search_final_resultset_1
	from #supplier_data_based_on_saved_search_final_resultset a 


	update #supplier_data_based_on_saved_search_final_resultset_1 set email_body_rfq_parts = replace(email_body_rfq_parts , '#Quantity#' , list_of_part_quantity)
	
	declare @count as int = 0
	declare @count1 as int = 0
	declare @saved_search_id1 as int = 0
	
	--select * from #supplier_data_based_on_saved_search_final_resultset order by supplier_contact_id , saved_search_id  , rfq_id
	

	

	declare supplier_filtered_rfq_cursor cursor for   
	select distinct supplier_contact_id , saved_search_id , rfq_id from #supplier_data_based_on_saved_search_final_resultset_1 order by supplier_contact_id , saved_search_id , rfq_id

	open supplier_filtered_rfq_cursor  

	
	fetch next from supplier_filtered_rfq_cursor   
	into  @supplier_contact_id   , @saved_search_id , @rfq_id 

	set @email_body_rfq_parts = '' 
	set @email_body_rfq_header = '' 
	set @email_body_rfq_footer = '' 
	set @last_saved_search_id = @saved_search_id
	set @rc_count = 1
	while @@fetch_status = 0  
	begin   
			--select * from #supplier_data_based_on_saved_search_final_resultset_1 where saved_search_id = @saved_search_id

			if @saved_search_id1 = @saved_search_id
			begin
				set @saved_search_id1 = @saved_search_id
				set @count= (select count(distinct rfq_id) from #supplier_data_based_on_saved_search_final_resultset_1 where saved_search_id = @saved_search_id)
				set @count1 =  @count1 + 1
			end
			else 
			begin
				set @saved_search_id1 = @saved_search_id
				set @count= (select count(distinct rfq_id) from #supplier_data_based_on_saved_search_final_resultset_1 where saved_search_id = @saved_search_id)
				set @count1 =  1
			end
			
				
			set @email_msg_subject = ''

			if exists (select * from #supplier_saved_search_email where saved_search_id =@saved_search_id )
			begin

				set @email_body_rfq_parts = ''
				
				select 
					 @email_body_rfq_header = email_body_rfq_header
					, @email_body_rfq_footer = email_body_rfq_footer
				from #supplier_data_based_on_saved_search_final_resultset_1 
				where supplier_contact_id = @supplier_contact_id and saved_search_id =@saved_search_id and rfq_id  =@rfq_id
		
				select @email_body_rfq_parts = COALESCE(@email_body_rfq_parts + ' ', '') + email_body_rfq_parts 
				from #supplier_data_based_on_saved_search_final_resultset_1 
				where supplier_contact_id = @supplier_contact_id and saved_search_id =@saved_search_id and rfq_id  =@rfq_id

				set @email_body_rfq_header_1 = ''
				set @email_body_rfq_header_1 = (@email_body_rfq_header + @email_body_rfq_parts + @email_body_rfq_footer)

				update #supplier_saved_search_email set email = email + @email_body_rfq_header_1 where  saved_search_id =@saved_search_id 

			end
			else
			begin
				set @email_body_rfq_parts = ''
				set @email_body_rfq_header_1 = ''

				select 
					@email_header = email_header 
					, @email_body_rfq_header = email_body_rfq_header
					, @email_body_rfq_footer = email_body_rfq_footer
					, @email_footer = email_footer 
					, @email_msg_subject = email_subject
				from #supplier_data_based_on_saved_search_final_resultset_1 
				where supplier_contact_id = @supplier_contact_id and saved_search_id =@saved_search_id and rfq_id  =@rfq_id
		
				select @email_body_rfq_parts = COALESCE(@email_body_rfq_parts + ' ', '') + email_body_rfq_parts 
				from #supplier_data_based_on_saved_search_final_resultset_1 
				where supplier_contact_id = @supplier_contact_id and saved_search_id =@saved_search_id and rfq_id  =@rfq_id
		
				set @email_body_rfq_header_1 = @email_header + @email_body_rfq_header_1 + (@email_body_rfq_header + @email_body_rfq_parts + @email_body_rfq_footer)

				insert into #supplier_saved_search_email (saved_search_id , email , email_subject )
				select @saved_search_id , @email_body_rfq_header_1 , @email_msg_subject

			end
			
			
			--select @count count  ,@count1 count1
			if @count1 = @count
				update #supplier_saved_search_email set  email = email + @email_footer   where saved_search_id = @saved_search_id 
		

		--select * from #supplier_saved_search_email  where saved_search_id = @saved_search_id 

		fetch next from supplier_filtered_rfq_cursor   
		into  @supplier_contact_id   , @saved_search_id , @rfq_id 
		
	end   
	close supplier_filtered_rfq_cursor;  
	deallocate supplier_filtered_rfq_cursor; 

	--update #supplier_saved_search_email set  email = email + @email_footer  

	--select * from #supplier_saved_search_email

	insert into mp_email_messages
	( message_type_id, email_message_subject, email_message_descr, email_message_date,from_cont ,to_cont, to_email, message_sent,message_read )
	select distinct @message_type_id ,  a.email_subject , a.email , @today_date , supplier_contact_id , supplier_contact_id ,b.Email , 0, 0 
	from #supplier_saved_search_email a 
	join #supplier_data_based_on_saved_search_final_resultset_1 b on a.saved_search_id = b.saved_search_id

	

end

