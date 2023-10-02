/*
exec proc_get_qms_quotes 
@qms_supplier_id = 1337894
,@qms_type = 8
,@pageno   = 1
,@pagesize = 100
,@search = ''
,@isorderbydesc = 1
,@orderby = ''
,@filter_company		 = null
,@filter_status			 = null
,@filter_probability	 = null
,@filter_supplier		= 1337894

*/


CREATE procedure [dbo].[proc_get_qms_quotes]
(
@qms_supplier_id		int
,@qms_type				smallint
,@pageno				int = 1
,@pagesize				int = 25
,@search				varchar(500) = null
,@isorderbydesc			bit ='true'
,@orderby				varchar(100) = null
,@filter_company		int = null
,@filter_probability	int = null
,@filter_status			int = null
,@filter_supplier		int = null
)
as
begin
	set nocount on
	/*
	M2-1901 M - My Quotes List View - DB
	M2-1988 M - QMS - Change the My Quotes Columns on the list -DB
	*/

	/* M2-2313 M - My Company Quotes page - DB */
	declare @supplier_company_id int
	/**/
	
	if @orderby is null or  @orderby = ''
		set @orderby = 'quote_id'
				
	drop table if exists #tmp_quote_feetypes
	drop table if exists ##tmp_quote_feetypes1

	/* M2-2313 M - My Company Quotes page - DB */
		set @supplier_company_id  = (select company_id from mp_contacts (nolock) where contact_id = @qms_supplier_id )
	/**/


	-- my QMS quotes excluding draft
	if @qms_type = 1 
	begin
		select 
			a.qms_quote_id as qms_quote_id
			, a.quote_id as quote_id
			, a.qms_quote_name as quote_name
			, a.quote_valid_until as quotes_expired
			, b.qms_contact_id as qms_company_id
			, b.company
			, b.first_name +' ' + b.last_name as contact
			, h.qms_process as process
			, f.status as quote_status
			, g.status as probalility
			, count(1) over () total_row_count
			, case 
				when (select count(1) from  mp_qms_quote_activities (nolock) where a.qms_quote_id = qms_quote_id and qms_quote_activity_id = 101) > 0 then cast('true' as bit) 
				else cast('false' as bit) 
			  end as QuoteDowloaded
			, case 
				when (select count(1) from  mp_qms_quote_activities (nolock) where a.qms_quote_id = qms_quote_id and qms_quote_activity_id = 102) > 0 then cast('true' as bit) 
				else cast('false' as bit) 
			  end as QuoteSentToSelf
			, case 
				when (select count(1) from  mp_qms_quote_activities (nolock) where a.qms_quote_id = qms_quote_id and qms_quote_activity_id = 103) > 0 then cast('true' as bit) 
				else cast('false' as bit) 
			  end as QuoteSentToCustomer
			, b.email as CustomerEmail
		from mp_qms_quotes					(nolock) a
		join mp_qms_contacts				(nolock) b on a.qms_contact_id = b.qms_contact_id
		join 
		(
			select a1.* from mp_qms_quote_parts (nolock)  a1
			join 
			(
				select qms_quote_id , min(qms_quote_part_id) qms_quote_part_id from mp_qms_quote_parts (nolock) group by qms_quote_id
			) b1 on a1.qms_quote_part_id = b1.qms_quote_part_id
		) c on a.qms_quote_id = c.qms_quote_id --and c.status_id = 2
		-- left join mp_mst_part_category		(nolock) e on c.part_category_id = e.part_category_id
		left join 
		(
			select qms_status_id  , description status 
			from mp_mst_qms_status (nolock) where  is_active = 1 and sys_key in ( 'EMAIL_STATUS')
			union 
			select mp_mst_qms_additional_email_status_id , email_status 
			from mp_mst_qms_additional_email_statuses a  (nolock) 
			where a.is_active = 1 and a.supplier_company_id = @supplier_company_id		
		) f	on a.email_status_id = f.qms_status_id 
		left join 
		(
			select qms_status_id qms_status_id , description status
			from mp_mst_qms_status (nolock)  where  is_active = 1 and sys_key in ( 'PROBABILITY')
			union 
			select mp_mst_qms_additional_probability_id , probability 
			from mp_mst_qms_additional_probabilities a  (nolock) 
			where a.is_active = 1 and a.supplier_company_id = @supplier_company_id
		) g on a.probability = g.qms_status_id 
		left join mp_mst_qms_processes		(nolock) h on c.part_category_id = h.qms_process_id
		where 
			a.status_id > 1
			and a.status_id != 19
			and 
			a.created_by = @qms_supplier_id
			and 
			(						 
					(b.company like '%'+@search+'%')	
					OR	
					(b.company like '%'+@search+'%')		
					OR
					(@search is null)					 				
			)
			and 
			(
				b.qms_contact_id = @filter_company 
				or @filter_company is null
			)
			and 
			(
				f.qms_status_id = @filter_status 
				or @filter_status is null
			)
			and 
			(
				g.qms_status_id = @filter_probability 
				or @filter_probability is null
			)
		order by 
			case   when @isorderbydesc =  1 and @orderby = 'quote_id'		then   a.qms_quote_id    end desc  
			,case  when @isorderbydesc =  1 and @orderby = 'qms_quote_name'	then   a.qms_quote_name    end desc  
			,case  when @isorderbydesc =  1 and @orderby = 'company'		then   company   end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'contact'		then   (b.first_name +' ' + b.last_name) end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'process'		then   h.qms_process   end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'quote_status'	then   f.status  end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'probalility'	then   g.status end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'quotes_expired'	then   a.quote_valid_until end desc  			
			,case  when @isorderbydesc =  0 and @orderby = 'quote_id'		then   a.qms_quote_id    end asc  
			,case  when @isorderbydesc =  0 and @orderby = 'qms_quote_name'	then   a.qms_quote_name    end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'company'		then   company   end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'contact'		then   (b.first_name +' ' + b.last_name) end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'process'		then   h.qms_process   end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'quote_status'	then   f.status  end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'probalility'	then   g.status end asc 
			,case  when @isorderbydesc =  0 and @orderby = 'quotes_expired'	then   a.quote_valid_until end asc  
						
		offset @pagesize * (@pageno - 1) rows
		fetch next @pagesize rows only
	end
	-- my drafts
	else if @qms_type = 2
	begin
		select 
			a.qms_quote_id as qms_quote_id
			, a.quote_id as quote_id
			, a.qms_quote_name as quote_name
			, a.quote_valid_until as quotes_expired
			, b.qms_contact_id as qms_company_id
			, b.company
			, b.first_name +' ' + b.last_name as contact
			, h.qms_process as process
			, f.status as quote_status
			, f.qms_status_id
			, g.status as probalility
			, count(1) over () total_row_count
			, case 
				when (select count(1) from  mp_qms_quote_activities (nolock) where a.qms_quote_id = qms_quote_id and qms_quote_activity_id = 101) > 0 then cast('true' as bit) 
				else cast('false' as bit) 
			  end as QuoteDowloaded
			, case 
				when (select count(1) from  mp_qms_quote_activities (nolock) where a.qms_quote_id = qms_quote_id and qms_quote_activity_id = 102) > 0 then cast('true' as bit) 
				else cast('false' as bit) 
			  end as QuoteSentToSelf
			, case 
				when (select count(1) from  mp_qms_quote_activities (nolock) where a.qms_quote_id = qms_quote_id and qms_quote_activity_id = 103) > 0 then cast('true' as bit) 
				else cast('false' as bit) 
			  end as QuoteSentToCustomer
			, b.email as CustomerEmail
		from mp_qms_quotes					(nolock) a
		join mp_qms_contacts				(nolock) b on a.qms_contact_id = b.qms_contact_id
		left join 
		(
			select a1.* from mp_qms_quote_parts (nolock)  a1
			join 
			(
				select qms_quote_id , min(qms_quote_part_id) qms_quote_part_id from mp_qms_quote_parts (nolock) group by qms_quote_id
			) b1 on a1.qms_quote_part_id = b1.qms_quote_part_id
		) c on a.qms_quote_id = c.qms_quote_id --and c.status_id = 2
		left join mp_mst_qms_processes		(nolock) h on c.part_category_id = h.qms_process_id
		left join 
		(
			select qms_status_id  , description status 
			from mp_mst_qms_status (nolock) where  is_active = 1 and sys_key in ( 'EMAIL_STATUS')
			union 
			select mp_mst_qms_additional_email_status_id , email_status 
			from mp_mst_qms_additional_email_statuses a  (nolock) 
			where a.is_active = 1 and a.supplier_company_id = @supplier_company_id		
		) f	on a.email_status_id = f.qms_status_id 
		left join 
		(
			select qms_status_id qms_status_id , description status
			from mp_mst_qms_status (nolock)  where  is_active = 1 and sys_key in ( 'PROBABILITY')
			union 
			select mp_mst_qms_additional_probability_id , probability 
			from mp_mst_qms_additional_probabilities a  (nolock) 
			where a.is_active = 1 and a.supplier_company_id = @supplier_company_id
		) g on a.probability = g.qms_status_id 
		where 
			a.status_id = 1
			and a.status_id != 19
			and a.created_by = @qms_supplier_id
			and 
			(						 
					(b.company like '%'+@search+'%')	
					OR	
					(b.company like '%'+@search+'%')		
					OR
					(@search is null)					 				
			)
			and 
			(
				b.qms_contact_id = @filter_company 
				or @filter_company is null
			)
			and 
			(
				f.qms_status_id = @filter_status 
				or @filter_status is null
			)
			and 
			(
				g.qms_status_id = @filter_probability 
				or @filter_probability is null
			)
		order by 
			case   when @isorderbydesc =  1 and @orderby = 'quote_id'		then   a.qms_quote_id    end desc  
			,case  when @isorderbydesc =  1 and @orderby = 'qms_quote_name'	then   a.qms_quote_name    end desc  
			,case  when @isorderbydesc =  1 and @orderby = 'company'		then   company   end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'contact'		then   (b.first_name +' ' + b.last_name) end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'process'		then   h.qms_process   end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'quote_status'	then   f.status  end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'probalility'	then   g.status end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'quotes_expired'	then   a.quote_valid_until end desc  			
			,case  when @isorderbydesc =  0 and @orderby = 'quote_id'		then   a.qms_quote_id    end asc  
			,case  when @isorderbydesc =  0 and @orderby = 'qms_quote_name'	then   a.qms_quote_name    end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'company'		then   company   end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'contact'		then   (b.first_name +' ' + b.last_name) end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'process'		then   h.qms_process   end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'quote_status'	then   f.status  end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'probalility'	then   g.status end asc 
			,case  when @isorderbydesc =  0 and @orderby = 'quotes_expired'	then   a.quote_valid_until end asc  		
		offset @pagesize * (@pageno - 1) rows
		fetch next @pagesize rows only
	end
	-- out for quoting
	else if @qms_type = 3
	begin
		select 
			a.qms_quote_id as qms_quote_id
			, a.quote_id as quote_id
			, a.qms_quote_name as quote_name
			, a.quote_valid_until as quotes_expired
			, b.qms_contact_id as qms_company_id
			, b.company
			, b.first_name +' ' + b.last_name as contact
			, h.qms_process as process
			, f.status as quote_status
			, g.status as probalility
			, count(1) over () total_row_count
			, case 
				when (select count(1) from  mp_qms_quote_activities (nolock) where a.qms_quote_id = qms_quote_id and qms_quote_activity_id = 101) > 0 then cast('true' as bit) 
				else cast('false' as bit) 
			  end as QuoteDowloaded
			, case 
				when (select count(1) from  mp_qms_quote_activities (nolock) where a.qms_quote_id = qms_quote_id and qms_quote_activity_id = 102) > 0 then cast('true' as bit) 
				else cast('false' as bit) 
			  end as QuoteSentToSelf
			, case 
				when (select count(1) from  mp_qms_quote_activities (nolock) where a.qms_quote_id = qms_quote_id and qms_quote_activity_id = 103) > 0 then cast('true' as bit) 
				else cast('false' as bit) 
			  end as QuoteSentToCustomer
			, b.email as CustomerEmail
		from mp_qms_quotes					(nolock) a
		join mp_qms_contacts				(nolock) b on a.qms_contact_id = b.qms_contact_id
		join 
		(
			select a1.* from mp_qms_quote_parts (nolock)  a1
			join 
			(
				select qms_quote_id , min(qms_quote_part_id) qms_quote_part_id from mp_qms_quote_parts (nolock) group by qms_quote_id
			) b1 on a1.qms_quote_part_id = b1.qms_quote_part_id
		) c on a.qms_quote_id = c.qms_quote_id --and c.status_id = 2
		left join mp_mst_qms_processes		(nolock) h on c.part_category_id = h.qms_process_id
		left join 
		(
			select qms_status_id  , description status 
			from mp_mst_qms_status (nolock) where  is_active = 1 and sys_key in ( 'EMAIL_STATUS')
			union 
			select mp_mst_qms_additional_email_status_id , email_status 
			from mp_mst_qms_additional_email_statuses a  (nolock) 
			where a.is_active = 1 and a.supplier_company_id = @supplier_company_id		
		) f	on a.email_status_id = f.qms_status_id 
		left join 
		(
			select qms_status_id qms_status_id , description status
			from mp_mst_qms_status (nolock)  where  is_active = 1 and sys_key in ( 'PROBABILITY')
			union 
			select mp_mst_qms_additional_probability_id , probability 
			from mp_mst_qms_additional_probabilities a  (nolock) 
			where a.is_active = 1 and a.supplier_company_id = @supplier_company_id
		) g on a.probability = g.qms_status_id 
		where 
			a.status_id = 2
			and a.status_id != 19
			and a.created_by = @qms_supplier_id
			and 
			(						 
					(b.company like '%'+@search+'%')	
					OR	
					(b.company like '%'+@search+'%')		
					OR
					(@search is null)					 				
			)
			and 
			(
				b.qms_contact_id = @filter_company 
				or @filter_company is null
			)
			and 
			(
				f.qms_status_id = @filter_status 
				or @filter_status is null
			)
			and 
			(
				g.qms_status_id = @filter_probability 
				or @filter_probability is null
			)
		order by 
			case   when @isorderbydesc =  1 and @orderby = 'quote_id'		then   a.qms_quote_id    end desc  
			,case  when @isorderbydesc =  1 and @orderby = 'qms_quote_name'	then   a.qms_quote_name    end desc  
			,case  when @isorderbydesc =  1 and @orderby = 'company'		then   company   end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'contact'		then   (b.first_name +' ' + b.last_name) end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'process'		then   h.qms_process   end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'quote_status'	then   f.status  end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'probalility'	then   g.status end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'quotes_expired'	then   a.quote_valid_until end desc  			
			,case  when @isorderbydesc =  0 and @orderby = 'quote_id'		then   a.qms_quote_id    end asc  
			,case  when @isorderbydesc =  0 and @orderby = 'qms_quote_name'	then   a.qms_quote_name    end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'company'		then   company   end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'contact'		then   (b.first_name +' ' + b.last_name) end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'process'		then   h.qms_process   end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'quote_status'	then   f.status  end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'probalility'	then   g.status end asc 
			,case  when @isorderbydesc =  0 and @orderby = 'quotes_expired'	then   a.quote_valid_until end asc    			
		offset @pagesize * (@pageno - 1) rows
		fetch next @pagesize rows only
	end
	-- my expired
	else if @qms_type = 4
	begin
		select 
			a.qms_quote_id as qms_quote_id
			, a.quote_id as quote_id
			, a.qms_quote_name as quote_name
			, a.quote_valid_until as quotes_expired
			, b.qms_contact_id as qms_company_id
			, b.company
			, b.first_name +' ' + b.last_name as contact
			, h.qms_process as process
			, f.status as quote_status
			, g.status as probalility
			, count(1) over () total_row_count
			, case 
				when (select count(1) from  mp_qms_quote_activities (nolock) where a.qms_quote_id = qms_quote_id and qms_quote_activity_id = 101) > 0 then cast('true' as bit) 
				else cast('false' as bit) 
			  end as QuoteDowloaded
			, case 
				when (select count(1) from  mp_qms_quote_activities (nolock) where a.qms_quote_id = qms_quote_id and qms_quote_activity_id = 102) > 0 then cast('true' as bit) 
				else cast('false' as bit) 
			  end as QuoteSentToSelf
			, case 
				when (select count(1) from  mp_qms_quote_activities (nolock) where a.qms_quote_id = qms_quote_id and qms_quote_activity_id = 103) > 0 then cast('true' as bit) 
				else cast('false' as bit) 
			  end as QuoteSentToCustomer
			, b.email as CustomerEmail
		from mp_qms_quotes					(nolock) a
		join mp_qms_contacts				(nolock) b on a.qms_contact_id = b.qms_contact_id
		join 
		(
			select a1.* from mp_qms_quote_parts (nolock)  a1
			join 
			(
				select qms_quote_id , min(qms_quote_part_id) qms_quote_part_id from mp_qms_quote_parts (nolock) group by qms_quote_id
			) b1 on a1.qms_quote_part_id = b1.qms_quote_part_id
		) c on a.qms_quote_id = c.qms_quote_id --and c.status_id = 2
		left join mp_mst_qms_processes		(nolock) h on c.part_category_id = h.qms_process_id
		left join 
		(
			select qms_status_id  , description status 
			from mp_mst_qms_status (nolock) where  is_active = 1 and sys_key in ( 'EMAIL_STATUS')
			union 
			select mp_mst_qms_additional_email_status_id , email_status 
			from mp_mst_qms_additional_email_statuses a  (nolock) 
			where a.is_active = 1 and a.supplier_company_id = @supplier_company_id		
		) f	on a.email_status_id = f.qms_status_id 
		left join 
		(
			select qms_status_id qms_status_id , description status
			from mp_mst_qms_status (nolock)  where  is_active = 1 and sys_key in ( 'PROBABILITY')
			union 
			select mp_mst_qms_additional_probability_id , probability 
			from mp_mst_qms_additional_probabilities a  (nolock) 
			where a.is_active = 1 and a.supplier_company_id = @supplier_company_id
		) g on a.probability = g.qms_status_id 
		where 
			a.status_id = 3
			and a.status_id != 19
			and a.created_by = @qms_supplier_id
			and 
			(						 
					(b.company like '%'+@search+'%')	
					OR	
					(b.company like '%'+@search+'%')		
					OR
					(@search is null)					 				
			)
			and 
			(
				b.qms_contact_id = @filter_company 
				or @filter_company is null
			)
			and 
			(
				f.qms_status_id = @filter_status 
				or @filter_status is null
			)
			and 
			(
				g.qms_status_id = @filter_probability 
				or @filter_probability is null
			)
		order by 
			case   when @isorderbydesc =  1 and @orderby = 'quote_id'		then   a.qms_quote_id    end desc  
			,case  when @isorderbydesc =  1 and @orderby = 'qms_quote_name'	then   a.qms_quote_name    end desc  
			,case  when @isorderbydesc =  1 and @orderby = 'company'		then   company   end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'contact'		then   (b.first_name +' ' + b.last_name) end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'process'		then   h.qms_process   end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'quote_status'	then   f.status  end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'probalility'	then   g.status end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'quotes_expired'	then   a.quote_valid_until end desc  			
			,case  when @isorderbydesc =  0 and @orderby = 'quote_id'		then   a.qms_quote_id    end asc  
			,case  when @isorderbydesc =  0 and @orderby = 'qms_quote_name'	then   a.qms_quote_name    end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'company'		then   company   end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'contact'		then   (b.first_name +' ' + b.last_name) end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'process'		then   h.qms_process   end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'quote_status'	then   f.status  end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'probalility'	then   g.status end asc 
			,case  when @isorderbydesc =  0 and @orderby = 'quotes_expired'	then   a.quote_valid_until end asc    		
		offset @pagesize * (@pageno - 1) rows
		fetch next @pagesize rows only
	end
	-- my accepted
	else if @qms_type = 5
	begin
		select 
			a.qms_quote_id as qms_quote_id
			, a.quote_id as quote_id
			, a.qms_quote_name as quote_name
			, a.quote_valid_until as quotes_expired
			, b.qms_contact_id as qms_company_id
			, b.company
			, b.first_name +' ' + b.last_name as contact
			, h.qms_process as process
			, f.status as quote_status
			, g.status as probalility
			, count(1) over () total_row_count
			, case 
				when (select count(1) from  mp_qms_quote_activities (nolock) where a.qms_quote_id = qms_quote_id and qms_quote_activity_id = 101) > 0 then cast('true' as bit) 
				else cast('false' as bit) 
			  end as QuoteDowloaded
			, case 
				when (select count(1) from  mp_qms_quote_activities (nolock) where a.qms_quote_id = qms_quote_id and qms_quote_activity_id = 102) > 0 then cast('true' as bit) 
				else cast('false' as bit) 
			  end as QuoteSentToSelf
			, case 
				when (select count(1) from  mp_qms_quote_activities (nolock) where a.qms_quote_id = qms_quote_id and qms_quote_activity_id = 103) > 0 then cast('true' as bit) 
				else cast('false' as bit) 
			  end as QuoteSentToCustomer
			, b.email as CustomerEmail
		from mp_qms_quotes					(nolock) a
		join mp_qms_contacts				(nolock) b on a.qms_contact_id = b.qms_contact_id
		join 
		(
			select a1.* from mp_qms_quote_parts (nolock)  a1
			join 
			(
				select qms_quote_id , min(qms_quote_part_id) qms_quote_part_id from mp_qms_quote_parts (nolock) group by qms_quote_id
			) b1 on a1.qms_quote_part_id = b1.qms_quote_part_id
		) c on a.qms_quote_id = c.qms_quote_id --and c.status_id = 2
		left join mp_mst_qms_processes		(nolock) h on c.part_category_id = h.qms_process_id
		left join 
		(
			select qms_status_id  , description status 
			from mp_mst_qms_status (nolock) where  is_active = 1 and sys_key in ( 'EMAIL_STATUS')
			union 
			select mp_mst_qms_additional_email_status_id , email_status 
			from mp_mst_qms_additional_email_statuses a  (nolock) 
			where a.is_active = 1 and a.supplier_company_id = @supplier_company_id		
		) f	on a.email_status_id = f.qms_status_id 
		left join 
		(
			select qms_status_id qms_status_id , description status
			from mp_mst_qms_status (nolock)  where  is_active = 1 and sys_key in ( 'PROBABILITY')
			union 
			select mp_mst_qms_additional_probability_id , probability 
			from mp_mst_qms_additional_probabilities a  (nolock) 
			where a.is_active = 1 and a.supplier_company_id = @supplier_company_id
		) g on a.probability = g.qms_status_id 
		where 
			a.status_id = 4
			and a.status_id != 19
			and a.created_by = @qms_supplier_id
			and 
			(						 
					(b.company like '%'+@search+'%')	
					OR	
					(b.company like '%'+@search+'%')		
					OR
					(@search is null)					 				
			)
			and 
			(
				b.qms_contact_id = @filter_company 
				or @filter_company is null
			)
			and 
			(
				f.qms_status_id = @filter_status 
				or @filter_status is null
			)
			and 
			(
				g.qms_status_id = @filter_probability 
				or @filter_probability is null
			)
		order by 
			case   when @isorderbydesc =  1 and @orderby = 'quote_id'		then   a.qms_quote_id    end desc  
			,case  when @isorderbydesc =  1 and @orderby = 'qms_quote_name'	then   a.qms_quote_name    end desc  
			,case  when @isorderbydesc =  1 and @orderby = 'company'		then   company   end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'contact'		then   (b.first_name +' ' + b.last_name) end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'process'		then   h.qms_process   end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'quote_status'	then   f.status  end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'probalility'	then   g.status end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'quotes_expired'	then   a.quote_valid_until end desc  			
			,case  when @isorderbydesc =  0 and @orderby = 'quote_id'		then   a.qms_quote_id    end asc  
			,case  when @isorderbydesc =  0 and @orderby = 'qms_quote_name'	then   a.qms_quote_name    end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'company'		then   company   end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'contact'		then   (b.first_name +' ' + b.last_name) end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'process'		then   h.qms_process   end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'quote_status'	then   f.status  end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'probalility'	then   g.status end asc 
			,case  when @isorderbydesc =  0 and @orderby = 'quotes_expired'	then   a.quote_valid_until end asc   		
		offset @pagesize * (@pageno - 1) rows
		fetch next @pagesize rows only
	end
	-- my declined
	else if @qms_type = 6
	begin
		select 
			a.qms_quote_id as qms_quote_id
			, a.quote_id as quote_id
			, a.qms_quote_name as quote_name
			, a.quote_valid_until as quotes_expired
			, b.qms_contact_id as qms_company_id
			, b.company
			, b.first_name +' ' + b.last_name as contact
			, h.qms_process as process
			, f.status as quote_status
			, g.status as probalility
			, count(1) over () total_row_count
			, case 
				when (select count(1) from  mp_qms_quote_activities (nolock) where a.qms_quote_id = qms_quote_id and qms_quote_activity_id = 101) > 0 then cast('true' as bit) 
				else cast('false' as bit) 
			  end as QuoteDowloaded
			, case 
				when (select count(1) from  mp_qms_quote_activities (nolock) where a.qms_quote_id = qms_quote_id and qms_quote_activity_id = 102) > 0 then cast('true' as bit) 
				else cast('false' as bit) 
			  end as QuoteSentToSelf
			, case 
				when (select count(1) from  mp_qms_quote_activities (nolock) where a.qms_quote_id = qms_quote_id and qms_quote_activity_id = 103) > 0 then cast('true' as bit) 
				else cast('false' as bit) 
			  end as QuoteSentToCustomer
			, b.email as CustomerEmail
		from mp_qms_quotes					(nolock) a
		join mp_qms_contacts				(nolock) b on a.qms_contact_id = b.qms_contact_id
		join 
		(
			select a1.* from mp_qms_quote_parts (nolock)  a1
			join 
			(
				select qms_quote_id , min(qms_quote_part_id) qms_quote_part_id from mp_qms_quote_parts (nolock) group by qms_quote_id
			) b1 on a1.qms_quote_part_id = b1.qms_quote_part_id
		) c on a.qms_quote_id = c.qms_quote_id --and c.status_id = 2
		left join mp_mst_qms_processes		(nolock) h on c.part_category_id = h.qms_process_id
		left join 
		(
			select qms_status_id  , description status 
			from mp_mst_qms_status (nolock) where  is_active = 1 and sys_key in ( 'EMAIL_STATUS')
			union 
			select mp_mst_qms_additional_email_status_id , email_status 
			from mp_mst_qms_additional_email_statuses a  (nolock) 
			where a.is_active = 1 and a.supplier_company_id = @supplier_company_id		
		) f	on a.email_status_id = f.qms_status_id 
		left join 
		(
			select qms_status_id qms_status_id , description status
			from mp_mst_qms_status (nolock)  where  is_active = 1 and sys_key in ( 'PROBABILITY')
			union 
			select mp_mst_qms_additional_probability_id , probability 
			from mp_mst_qms_additional_probabilities a  (nolock) 
			where a.is_active = 1 and a.supplier_company_id = @supplier_company_id
		) g on a.probability = g.qms_status_id 
		where 
			a.status_id = 5
			and a.status_id != 19
			and a.created_by = @qms_supplier_id
			and 
			(						 
					(b.company like '%'+@search+'%')	
					OR	
					(b.company like '%'+@search+'%')		
					OR
					(@search is null)					 				
			)
			and 
			(
				b.qms_contact_id = @filter_company 
				or @filter_company is null
			)
			and 
			(
				f.qms_status_id = @filter_status 
				or @filter_status is null
			)
			and 
			(
				g.qms_status_id = @filter_probability 
				or @filter_probability is null
			)
		order by 
			case   when @isorderbydesc =  1 and @orderby = 'quote_id'		then   a.qms_quote_id    end desc  
			,case  when @isorderbydesc =  1 and @orderby = 'qms_quote_name'	then   a.qms_quote_name    end desc  
			,case  when @isorderbydesc =  1 and @orderby = 'company'		then   company   end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'contact'		then   (b.first_name +' ' + b.last_name) end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'process'		then   h.qms_process   end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'quote_status'	then   f.status  end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'probalility'	then   g.status end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'quotes_expired'	then   a.quote_valid_until end desc  			
			,case  when @isorderbydesc =  0 and @orderby = 'quote_id'		then   a.qms_quote_id    end asc  
			,case  when @isorderbydesc =  0 and @orderby = 'qms_quote_name'	then   a.qms_quote_name    end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'company'		then   company   end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'contact'		then   (b.first_name +' ' + b.last_name) end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'process'		then   h.qms_process   end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'quote_status'	then   f.status  end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'probalility'	then   g.status end asc 
			,case  when @isorderbydesc =  0 and @orderby = 'quotes_expired'	then   a.quote_valid_until end asc     		
		offset @pagesize * (@pageno - 1) rows
		fetch next @pagesize rows only
	end
	--my deleted quotes
	else if @qms_type = 7
	begin
		select 
			a.qms_quote_id as qms_quote_id
			, a.quote_id as quote_id
			, a.qms_quote_name as quote_name
			, a.quote_valid_until as quotes_expired
			, b.qms_contact_id as qms_company_id
			, b.company
			, b.first_name +' ' + b.last_name as contact
			, h.qms_process as process
			, f.status as quote_status
			, g.status as probalility
			, count(1) over () total_row_count
			, case 
				when (select count(1) from  mp_qms_quote_activities (nolock) where a.qms_quote_id = qms_quote_id and qms_quote_activity_id = 101) > 0 then cast('true' as bit) 
				else cast('false' as bit) 
			  end as QuoteDowloaded
			, case 
				when (select count(1) from  mp_qms_quote_activities (nolock) where a.qms_quote_id = qms_quote_id and qms_quote_activity_id = 102) > 0 then cast('true' as bit) 
				else cast('false' as bit) 
			  end as QuoteSentToSelf
			, case 
				when (select count(1) from  mp_qms_quote_activities (nolock) where a.qms_quote_id = qms_quote_id and qms_quote_activity_id = 103) > 0 then cast('true' as bit) 
				else cast('false' as bit) 
			  end as QuoteSentToCustomer
			, b.email as CustomerEmail
		from mp_qms_quotes					(nolock) a
		join mp_qms_contacts				(nolock) b on a.qms_contact_id = b.qms_contact_id
		join 
		(
			select a1.* from mp_qms_quote_parts (nolock)  a1
			join 
			(
				select qms_quote_id , min(qms_quote_part_id) qms_quote_part_id from mp_qms_quote_parts (nolock) group by qms_quote_id
			) b1 on a1.qms_quote_part_id = b1.qms_quote_part_id
		) c on a.qms_quote_id = c.qms_quote_id --and c.status_id = 2
		left join mp_mst_qms_processes		(nolock) h on c.part_category_id = h.qms_process_id
		left join 
		(
			select qms_status_id  , description status 
			from mp_mst_qms_status (nolock) where  is_active = 1 and sys_key in ( 'EMAIL_STATUS')
			union 
			select mp_mst_qms_additional_email_status_id , email_status 
			from mp_mst_qms_additional_email_statuses a  (nolock) 
			where a.is_active = 1 and a.supplier_company_id = @supplier_company_id		
		) f	on a.email_status_id = f.qms_status_id 
		left join 
		(
			select qms_status_id qms_status_id , description status
			from mp_mst_qms_status (nolock)  where  is_active = 1 and sys_key in ( 'PROBABILITY')
			union 
			select mp_mst_qms_additional_probability_id , probability 
			from mp_mst_qms_additional_probabilities a  (nolock) 
			where a.is_active = 1 and a.supplier_company_id = @supplier_company_id
		) g on a.probability = g.qms_status_id 
		where 
			--a.status_id = 5
			 a.status_id = 19
			and a.created_by = @qms_supplier_id
			and 
			(						 
					(b.company like '%'+@search+'%')	
					OR	
					(b.company like '%'+@search+'%')		
					OR
					(@search is null)					 				
			)
			and 
			(
				b.qms_contact_id = @filter_company 
				or @filter_company is null
			)
			and 
			(
				f.qms_status_id = @filter_status 
				or @filter_status is null
			)
			and 
			(
				g.qms_status_id = @filter_probability 
				or @filter_probability is null
			)
		order by 
			case   when @isorderbydesc =  1 and @orderby = 'quote_id'		then   a.qms_quote_id    end desc  
			,case  when @isorderbydesc =  1 and @orderby = 'qms_quote_name'	then   a.qms_quote_name    end desc  
			,case  when @isorderbydesc =  1 and @orderby = 'company'		then   company   end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'contact'		then   (b.first_name +' ' + b.last_name) end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'process'		then   h.qms_process   end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'quote_status'	then   f.status  end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'probalility'	then   g.status end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'quotes_expired'	then   a.quote_valid_until end desc  			
			,case  when @isorderbydesc =  0 and @orderby = 'quote_id'		then   a.qms_quote_id    end asc  
			,case  when @isorderbydesc =  0 and @orderby = 'qms_quote_name'	then   a.qms_quote_name    end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'company'		then   company   end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'contact'		then   (b.first_name +' ' + b.last_name) end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'process'		then   h.qms_process   end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'quote_status'	then   f.status  end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'probalility'	then   g.status end asc 
			,case  when @isorderbydesc =  0 and @orderby = 'quotes_expired'	then   a.quote_valid_until end asc     		
		offset @pagesize * (@pageno - 1) rows
		fetch next @pagesize rows only
	end
	--my company quotes excluding draft
	/* M2-2313 M - My Company Quotes page - DB */
	else if @qms_type = 8
	begin
		select 
			a.qms_quote_id as qms_quote_id
			, a.quote_id as quote_id
			, a.qms_quote_name as quote_name
			, a.quote_valid_until as quotes_expired
			, b.qms_contact_id as qms_company_id
			, b.company
			, b.first_name +' ' + b.last_name as contact
			, h.qms_process as process
			, f.status as quote_status
			, g.status as probalility
			, i.*
			, count(1) over () total_row_count
			, case 
				when (select count(1) from  mp_qms_quote_activities (nolock) where a.qms_quote_id = qms_quote_id and qms_quote_activity_id = 101) > 0 then cast('true' as bit) 
				else cast('false' as bit) 
			  end as QuoteDowloaded
			, case 
				when (select count(1) from  mp_qms_quote_activities (nolock) where a.qms_quote_id = qms_quote_id and qms_quote_activity_id = 102) > 0 then cast('true' as bit) 
				else cast('false' as bit) 
			  end as QuoteSentToSelf
			, case 
				when (select count(1) from  mp_qms_quote_activities (nolock) where a.qms_quote_id = qms_quote_id and qms_quote_activity_id = 103) > 0 then cast('true' as bit) 
				else cast('false' as bit) 
			  end as QuoteSentToCustomer
			, b.email as CustomerEmail
		from mp_qms_quotes					(nolock) a
		join mp_qms_contacts				(nolock) b on a.qms_contact_id = b.qms_contact_id
		join 
		(
			select a1.* from mp_qms_quote_parts (nolock)  a1
			join 
			(
				select qms_quote_id , min(qms_quote_part_id) qms_quote_part_id from mp_qms_quote_parts (nolock) group by qms_quote_id
			) b1 on a1.qms_quote_part_id = b1.qms_quote_part_id
		) c on a.qms_quote_id = c.qms_quote_id --and c.status_id = 2
		-- left join mp_mst_part_category		(nolock) e on c.part_category_id = e.part_category_id
		left join 
		(
			select qms_status_id  , description status 
			from mp_mst_qms_status (nolock) where  is_active = 1 and sys_key in ( 'EMAIL_STATUS')
			union 
			select mp_mst_qms_additional_email_status_id , email_status 
			from mp_mst_qms_additional_email_statuses a  (nolock) 
			where a.is_active = 1 and a.supplier_company_id = @supplier_company_id		
		) f	on a.email_status_id = f.qms_status_id 
		left join 
		(
			select qms_status_id qms_status_id , description status
			from mp_mst_qms_status (nolock)  where  is_active = 1 and sys_key in ( 'PROBABILITY')
			union 
			select mp_mst_qms_additional_probability_id , probability 
			from mp_mst_qms_additional_probabilities a  (nolock) 
			where a.is_active = 1 and a.supplier_company_id = @supplier_company_id
		) g on a.probability = g.qms_status_id 
		left join mp_mst_qms_processes		(nolock) h on c.part_category_id = h.qms_process_id
		join 
		(
				select contact_id supplierid , first_name + ' ' + last_name  supplier 
				from mp_contacts (nolock)
				where company_id = @supplier_company_id and is_buyer= 0
		) i on a.created_by = i.supplierid
		where 
			a.status_id > 1
			and a.status_id != 19
			and 
			a.created_by in
			(
				select contact_id from mp_contacts where company_id = @supplier_company_id and is_buyer= 0
			) 
			and 
			(						 
					(b.company like '%'+@search+'%')	
					OR	
					(b.company like '%'+@search+'%')		
					OR
					(@search is null)		
					OR
					(i.supplier like '%'+@search+'%')			 				
			)
			and 
			(
				b.qms_contact_id = @filter_company 
				or @filter_company is null
			)
			and 
			(
				f.qms_status_id = @filter_status 
				or @filter_status is null
			)
			and 
			(
				g.qms_status_id = @filter_probability 
				or @filter_probability is null
			)
			and 
			(
				i.supplierid = @filter_supplier 
				or @filter_supplier is null
			)
		order by 
			case   when @isorderbydesc =  1 and @orderby = 'quote_id'		then   a.qms_quote_id    end desc  
			,case  when @isorderbydesc =  1 and @orderby = 'qms_quote_name'	then   a.qms_quote_name    end desc  
			,case  when @isorderbydesc =  1 and @orderby = 'company'		then   company   end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'contact'		then   (b.first_name +' ' + b.last_name) end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'process'		then   h.qms_process   end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'quote_status'	then   f.status  end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'probalility'	then   g.status end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'quotes_expired'	then   a.quote_valid_until end desc  
			,case  when @isorderbydesc =  1 and @orderby = 'quoter'			then   i.supplier end desc  
			,case  when @isorderbydesc =  0 and @orderby = 'quote_id'		then   a.qms_quote_id    end asc  
			,case  when @isorderbydesc =  0 and @orderby = 'qms_quote_name'	then   a.qms_quote_name    end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'company'		then   company   end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'contact'		then   (b.first_name +' ' + b.last_name) end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'process'		then   h.qms_process   end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'quote_status'	then   f.status  end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'probalility'	then   g.status end asc 
			,case  when @isorderbydesc =  0 and @orderby = 'quotes_expired'	then   a.quote_valid_until end asc  
			,case  when @isorderbydesc =  0 and @orderby = 'quoter'			then   i.supplier end asc  
						
		offset @pagesize * (@pageno - 1) rows
		fetch next @pagesize rows only
	end
	/* */
	/* M2-2313 M - My Company Quotes page - DB */
	--my company archived quotes 
	else if @qms_type = 9
	begin
		select 
			a.qms_quote_id as qms_quote_id
			, a.quote_id as quote_id
			, a.qms_quote_name as quote_name
			, a.quote_valid_until as quotes_expired
			, b.qms_contact_id as qms_company_id
			, b.company
			, b.first_name +' ' + b.last_name as contact
			, h.qms_process as process
			, f.status as quote_status
			, g.status as probalility
			, i.*
			, count(1) over () total_row_count
			, case 
				when (select count(1) from  mp_qms_quote_activities (nolock) where a.qms_quote_id = qms_quote_id and qms_quote_activity_id = 101) > 0 then cast('true' as bit) 
				else cast('false' as bit) 
			  end as QuoteDowloaded
			, case 
				when (select count(1) from  mp_qms_quote_activities (nolock) where a.qms_quote_id = qms_quote_id and qms_quote_activity_id = 102) > 0 then cast('true' as bit) 
				else cast('false' as bit) 
			  end as QuoteSentToSelf
			, case 
				when (select count(1) from  mp_qms_quote_activities (nolock) where a.qms_quote_id = qms_quote_id and qms_quote_activity_id = 103) > 0 then cast('true' as bit) 
				else cast('false' as bit) 
			  end as QuoteSentToCustomer
			, b.email as CustomerEmail
		from mp_qms_quotes					(nolock) a
		join mp_qms_contacts				(nolock) b on a.qms_contact_id = b.qms_contact_id
		join 
		(
			select a1.* from mp_qms_quote_parts (nolock)  a1
			join 
			(
				select qms_quote_id , min(qms_quote_part_id) qms_quote_part_id from mp_qms_quote_parts (nolock) group by qms_quote_id
			) b1 on a1.qms_quote_part_id = b1.qms_quote_part_id
		) c on a.qms_quote_id = c.qms_quote_id --and c.status_id = 2
		-- left join mp_mst_part_category		(nolock) e on c.part_category_id = e.part_category_id
		left join 
		(
			select qms_status_id  , description status 
			from mp_mst_qms_status (nolock) where  is_active = 1 and sys_key in ( 'EMAIL_STATUS')
			union 
			select mp_mst_qms_additional_email_status_id , email_status 
			from mp_mst_qms_additional_email_statuses a  (nolock) 
			where a.is_active = 1 and a.supplier_company_id = @supplier_company_id		
		) f	on a.email_status_id = f.qms_status_id 
		left join 
		(
			select qms_status_id qms_status_id , description status
			from mp_mst_qms_status (nolock)  where  is_active = 1 and sys_key in ( 'PROBABILITY')
			union 
			select mp_mst_qms_additional_probability_id , probability 
			from mp_mst_qms_additional_probabilities a  (nolock) 
			where a.is_active = 1 and a.supplier_company_id = @supplier_company_id
		) g on a.probability = g.qms_status_id 
		left join mp_mst_qms_processes		(nolock) h on c.part_category_id = h.qms_process_id
		join 
		(
				select contact_id supplierid , first_name + ' ' + last_name  supplier 
				from mp_contacts (nolock)
				where company_id = @supplier_company_id and is_buyer= 0
		) i on a.created_by = i.supplierid
		where 
			a.status_id = 19
			and 
			a.created_by in
			(
				select contact_id from mp_contacts where company_id = @supplier_company_id and is_buyer= 0
			) 
			and 
			(						 
					(b.company like '%'+@search+'%')	
					OR	
					(b.company like '%'+@search+'%')		
					OR
					(@search is null)		
					OR
					(i.supplier like '%'+@search+'%')			 				
			)
			and 
			(
				b.qms_contact_id = @filter_company 
				or @filter_company is null
			)
			and 
			(
				f.qms_status_id = @filter_status 
				or @filter_status is null
			)
			and 
			(
				g.qms_status_id = @filter_probability 
				or @filter_probability is null
			)
			and 
			(
				i.supplierid = @filter_supplier 
				or @filter_supplier is null
			)
		order by 
			case   when @isorderbydesc =  1 and @orderby = 'quote_id'		then   a.qms_quote_id    end desc  
			,case  when @isorderbydesc =  1 and @orderby = 'qms_quote_name'	then   a.qms_quote_name    end desc  
			,case  when @isorderbydesc =  1 and @orderby = 'company'		then   company   end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'contact'		then   (b.first_name +' ' + b.last_name) end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'process'		then   h.qms_process   end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'quote_status'	then   f.status  end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'probalility'	then   g.status end desc   
			,case  when @isorderbydesc =  1 and @orderby = 'quotes_expired'	then   a.quote_valid_until end desc  
			,case  when @isorderbydesc =  1 and @orderby = 'quoter'			then   i.supplier end desc  
			,case  when @isorderbydesc =  0 and @orderby = 'quote_id'		then   a.qms_quote_id    end asc  
			,case  when @isorderbydesc =  0 and @orderby = 'qms_quote_name'	then   a.qms_quote_name    end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'company'		then   company   end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'contact'		then   (b.first_name +' ' + b.last_name) end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'process'		then   h.qms_process   end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'quote_status'	then   f.status  end asc   
			,case  when @isorderbydesc =  0 and @orderby = 'probalility'	then   g.status end asc 
			,case  when @isorderbydesc =  0 and @orderby = 'quotes_expired'	then   a.quote_valid_until end asc  
			,case  when @isorderbydesc =  0 and @orderby = 'quoter'			then   i.supplier end asc  
						
		offset @pagesize * (@pageno - 1) rows
		fetch next @pagesize rows only
	end
	/* */
end
