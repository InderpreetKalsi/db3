

/*

select * from mp_rfq_preferences where rfq_id = 1176606
select * from mp_rfq_quote_suplierstatuses where rfq_id = 1176606
select * from mp_contacts where contact_id in (1022367,1358792)
select * from mp_companies where company_id in (1477588,1790236)
select * from mp_registered_supplier where company_id in (1477588,1790236)

    insert into #listofcompanies (company_id , contact_id)    select      a.company_id      , a.contact_id     from    (     select       a.company_id , c.contact_id , c.is_admin       , row_number() over(partition by  a.company_id order by a.company_id, c.is_admin desc, c.contact_id) rn     from mp_companies    (nolock) a     left join      (      select company_id , part_category_id from  mp_company_processes (nolock)      union       select company_id , part_category_id from mp_gateway_subscription_company_processes   (nolock)          ) b on a.company_id = b.company_id     join mp_contacts    (nolock) c on a.company_id = c.company_id and c.is_admin = 1     join mp_registered_supplier     (nolock) d on a.company_id = d.company_id and is_registered = 1       where       (        (          b.part_category_id in  (select * from #capabiities_parent_child)          and a.manufacturing_location_id in (select rfq_pref_manufacturing_location_id from #rfq_location_preferences )         )        or         (          a.manufacturing_location_id in (select rfq_pref_manufacturing_location_id from #rfq_location_preferences )           and b.part_category_id is null        )        )       and a.company_Id not in  (select company_id from #blacklistedcompanies)                ) a     where a.rn =1      



EXEC [proc_get_DistributionDetailList] 
@RfqId=1176606
,@PageNumber=1
,@PageSize=200
,@sortby=N''
,@isorderbydesc=0
,@searchtext=N''
,@filterby=N'Marked for Quoting'



*/
CREATE  PROCEDURE [dbo].[proc_get_DistributionDetailList]  
  @RfqId INT,     
  @PageNumber INT=1,  
  @PageSize INT=20,  
  @sortby varchar(100) = null ,  
  @isorderbydesc int = 0,  
  @searchtext nvarchar(200) = null,  
  @filterby varchar(200) = null  
AS  
BEGIN   
 /* M2-1185 Buyers - Add a Distribution tab to the RFQ details page */  
 /* M2-3320 Buyer - Hide the children contacts under the parent on the Insight tab - DB */

 set nocount on   
  
	 drop table if exists #rfq_capabiities  
	 drop table if exists #capabiities_parent_child  
	 drop table if exists #rfq_location_preferences  
	 drop table if exists #listofcompanies
	 drop table if exists #blacklistedcompanies
	 drop table if exists #Capability_Company_Id
  
	 declare @rfq_location_preferences int = 0  
	 declare @max_rfq_preferences_id int = 0  
	 declare @rfq_preferred_location int = 0  
  
	 declare @Company_Id		int
	 declare @ContactId			int   
	 declare @sqlquery			varchar(max)
	 declare @executesqlquery	nvarchar(max)

	 declare @is_rfq_for_all_registered_supplier int = (select top 1 company_id from mp_rfq_supplier  (nolock) where rfq_id = @RfqId)  
	 declare @rfq_status int = (select rfq_status_id from mp_rfq (nolock) where  rfq_id = @RfqId)  

	 declare @blacklisted_Companies table (company_id int)   
	   
	 create table #rfq_location_preferences  
	 (
		rfq_preferences_id int null
		, rfq_pref_manufacturing_location_id int null
	 )  
   
	 create table #listofcompanies  
	 (
		company_id int null
		, contact_id int null
	 )  

	 create table #blacklistedcompanies  
	 (
		company_id int null
	 )  

 	 select 
		@ContactId = mp_contacts.contact_Id
		,@Company_Id = mp_contacts.company_id  
	 from mp_rfq  (nolock)
	 join mp_contacts (nolock) on mp_rfq.contact_Id  = mp_contacts.contact_Id  
	 where mp_rfq.rfq_id  = @RfqId  
    
	 if @sortby is null or @sortby= ''  
		set @sortby = 'manufacturer'  
  
	 if (@PageSize is null or @PageSize = 0) and (@PageNumber is null or @PageNumber = 0)  
	 begin  
		set @PageSize = 20  
		set @PageNumber = 1  
	 end  
  
	 if @filterby is null  
		set @filterby = ''  
    
	insert into #blacklistedcompanies (company_id)  
	select distinct a.company_id 
	from mp_book_details	a (nolock)   
	join mp_books			b (nolock) on a.book_id = b.book_id        
	where bk_type= 5 and b.contact_id = @ContactId  
	union    
	select distinct d.company_id 
	from mp_book_details	a (nolock)  
	join mp_books			b (nolock)   on a.book_id = b.book_id     
	join mp_contacts		d (nolock) on b.contact_Id = d.contact_Id AND  a.company_id = @Company_Id  
	where bk_type= 5    
  
	insert into #rfq_location_preferences (rfq_preferences_id, rfq_pref_manufacturing_location_id)  
	select top 2 rfq_preferences_id, rfq_pref_manufacturing_location_id  
	from mp_rfq_preferences (nolock) 
	where rfq_id =@RfqId 
	order by rfq_preferences_id desc  
  
	/*  M2-2087 Clone up to 3 RFQ's for 3 regions - API */  
	if (select count(1) from #rfq_location_preferences where rfq_pref_manufacturing_location_id = 7) > 0  
	begin  
  
		insert into #rfq_location_preferences (rfq_preferences_id, rfq_pref_manufacturing_location_id)  
		select 1 , 4  
		union  
		select 2 , 5  
  
		delete from  #rfq_location_preferences where rfq_pref_manufacturing_location_id = 7  
	end  
	/**/  
  
	set @rfq_location_preferences = (select count(1) from #rfq_location_preferences where rfq_pref_manufacturing_location_id in (4,5) )  
  
	if ((select count(1) from #rfq_location_preferences) = 2) and @rfq_location_preferences < 2  
	begin   
		set @max_rfq_preferences_id  = (select max(rfq_preferences_id) from #rfq_location_preferences  )  
		delete from #rfq_location_preferences where rfq_preferences_id != @max_rfq_preferences_id   
	end   
   
	select distinct c.part_category_id 
	into #rfq_capabiities  
	from mp_rfq a    (nolock)  
	join mp_rfq_parts  b (nolock) on a.rfq_id = b.rfq_id  
	join mp_parts   c (nolock) on b.part_id = c.part_id  
	where a.rfq_id = @RfqId  
  
	select distinct b.part_category_id 
	into #capabiities_parent_child  
	from mp_mst_part_category a  (nolock)  
	join mp_mst_part_category b (nolock) on  a.parent_part_category_id= b.parent_part_category_id and b.status_id = 2  
	where a.part_category_id in (select * from #rfq_capabiities )  

	set @sqlquery =
	'
		insert into #listofcompanies (company_id , contact_id)
		select 
			a.company_id 
			, a.contact_id 
		from
		(
			select 
				a.company_id , c.contact_id , c.is_admin 
				, row_number() over(partition by  a.company_id order by a.company_id, c.is_admin desc, c.contact_id) rn
			from mp_companies				(nolock) a
			left join 
			(
				select company_id , part_category_id from  mp_company_processes	(nolock)
				union 
				select company_id , part_category_id from mp_gateway_subscription_company_processes  	(nolock)
			
			) b on a.company_id = b.company_id
			join mp_contacts				(nolock) c on a.company_id = c.company_id and c.is_admin = 1
			join mp_registered_supplier     (nolock) d on a.company_id = d.company_id and is_registered = 1  
			where  
			(  
			 (  
				  b.part_category_id in  (select * from #capabiities_parent_child)  
				  and a.manufacturing_location_id in (select rfq_pref_manufacturing_location_id from #rfq_location_preferences )   
			 )  
			 or   
			 (  
				  a.manufacturing_location_id in (select rfq_pref_manufacturing_location_id from #rfq_location_preferences )   
				  and b.part_category_id is null  
			 )   
			)  
			and a.company_Id not in  (select company_id from #blacklistedcompanies)  
			'
			+
			case 
				when @is_rfq_for_all_registered_supplier != -1 then
					' and a.company_id  in  (select company_id from mp_rfq_supplier  (nolock) where rfq_id = '+convert(varchar(100),@RfqId) +' )  '
				else ''
			end
			+
			'
			'
			+
			case when @searchtext = '' then '' else ' and a.name like ''%'+@searchtext+'%''' end
			+
			'
		) a 
		where a.rn =1 

	'
	-- select @sqlquery
	exec (@sqlquery)

	/* 
	M2-4507 
	here adding those company which are having quotating capabilities from vision side
	*/
	SELECT DISTINCT  
	  CompanyId  
	 INTO #Capability_Company_Id
	 FROM  
	 (  
	   SELECT DISTINCT    
	   SCP.company_id    AS CompanyId,   
	   Parent_PC.part_category_id AS ParentCapabilityId    
		, Parent_PC.discipline_name AS ParentCapability    
		, Child_PC.Part_category_id AS ChildCapabilityId    
		, Child_PC.discipline_name AS ChildCapability    
		, Child_PC.level    AS [Level]  
	   FROM     
		mp_mst_part_category    Child_PC (NOLOCK)   
		LEFT JOIN mp_mst_part_category Parent_PC (NOLOCK)  ON Child_PC.parent_part_category_id = Parent_PC.part_category_id    
		JOIN mp_gateway_subscription_company_processes SCP   (NOLOCK)  ON Child_PC.part_category_id= SCP.part_category_id    
	   WHERE      
		SCP.company_id in (select company_id  from #listofcompanies) 
		and Child_PC.status_id IN(2,4)     
		and Parent_PC.status_id IN(2,4)    
		and Child_PC.Part_category_id  in (select part_category_id  from #capabiities_parent_child)
	 ) a  
  
	  -- deleted those records of company ids, which are not having quotating capabilities from vision side 
	  DELETE FROM    #listofcompanies
	  WHERE company_id NOT IN 
	  (
		SELECT CompanyId FROM  #Capability_Company_Id
	  )
	  /* End of M2-4507 code */

	select * ,  count(1) over () TotalCount 
	from 
	(
		select 
			distinct
			b.name				as CompanyName
			,b.company_id		as CompanyId
			,b.CompanyURL		as CompanyUrl
			,d.territory_classification_name as ManufacturingLocation 
			,e.communication_value    as PhoneNo
			,f.no_of_stars      as NoOfStars 
			,
			case    
				when awarded.company_id is not null then 'Awarded'        
				when g.is_quote_submitted = 1		then 'Quoted'   
				when h.rfq_userStatus_id = 2		then 'Marked for Quoting'  
				when i.supplier_id is not null		then 'Reviewed'  
				else 'Not reviewed'      
			end as Status  
			,c.contact_id		as ContactId
			,(select count(1) from mp_contacts (nolock) where company_id = a.company_id and contact_id <> a.contact_id) NoOfChildContacts
			,isqmsenable	as IsQMSEnable
			,contact		as Contact
			,j.email		as Email

		from #listofcompanies a
		join 
		(
			select 
				company_id , name , manufacturing_location_id ,CompanyURL , is_mqs_enable as isqmsenable
			from mp_companies	(nolock) 
		) b on a.company_id = b.company_id
		join (select contact_id , company_id , first_name +' '+last_name as contact , user_id from mp_contacts	(nolock) )	c on b.company_id = c.company_id and a.contact_id = c.contact_id
		left join mp_mst_territory_classification				(nolock)	d on b.manufacturing_location_id =  d.territory_classification_id  
		left join mp_communication_details						(nolock)	e on c.contact_id  = e.contact_id and e.communication_type_id = 1 
		left join mp_star_rating								(nolock)	f on b.company_id = f.company_id      
		left join 
		(
			select distinct b.company_id , a.is_quote_submitted
			from mp_rfq_quote_supplierquote (nolock) a  
			join mp_contacts				(nolock) b on a.contact_id = b.contact_id  and a.rfq_id = @RfqId 
			and a.is_rfq_resubmitted = 0   
			and a.is_quote_submitted = 1 
		) g on b.company_id = g.company_id
		left join 
		(
			select distinct b.company_id , a.rfq_userStatus_id
			from mp_rfq_quote_suplierstatuses	(nolock) a
			join mp_contacts					(nolock) b  on a.contact_id = b.contact_id  and a.rfq_id= @RfqId
		) h on b.company_id = h.company_id
		left join 
		(
			select distinct b.company_id , a.supplier_id
			from mp_rfq_supplier_read			(nolock) a
			join mp_contacts					(nolock) b  on a.supplier_id = b.contact_id  and a.rfq_id= @RfqId
		) i on b.company_id = i.company_id
		left join   
		(  
			select distinct  c.company_id   
			from mp_rfq_quote_supplierquote a (nolock)  
			join mp_rfq_quote_items			b (nolock)  on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id 
				and a.rfq_id = @RfqId 
				and a.is_rfq_resubmitted = 0  
				and is_awrded = 1  
			join mp_contacts				c (nolock) on a.contact_id = c.contact_id   
		) awarded on b.company_id = awarded.company_id  
		join aspnetusers			j (nolock) on 	c.user_id = j.id	

	) a
	where 
	a.Status = (case when @filterby = ''  then a.Status else @filterby end )

	order by   
	case   when @isorderbydesc =  1 and @sortby = 'manufacturer'	then   a.CompanyName end desc  
	,case  when @isorderbydesc =  1 and @sortby = 'territory'		then   a.ManufacturingLocation end desc  
	,case  when @isorderbydesc =  1 and @sortby = 'status'			then   a.Status end desc  
	,case  when @isorderbydesc =  0 and @sortby = 'manufacturer'	then   a.CompanyName end asc    
	,case  when @isorderbydesc =  0 and @sortby = 'territory'		then   a.ManufacturingLocation end asc  
	,case  when @isorderbydesc =  0 and @sortby = 'status'			then   a.Status end asc  
	offset @pagesize * (@pagenumber - 1) rows  
	fetch next @pagesize rows only  	
	


	 drop table if exists #rfq_capabiities  
	 drop table if exists #capabiities_parent_child  
	 drop table if exists #rfq_location_preferences  
	 drop table if exists #listofcompanies
	 drop table if exists #blacklistedcompanies
    
END
