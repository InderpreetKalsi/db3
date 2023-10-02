
/*
select * from mp_mst_part_category where part_category_id =  7455

declare @p3 dbo.tbltype_listofprocesses
insert into @p3 values(7455)

exec proc_get_supplierpublicprofile
  @MFGLocation  = 0,
  @latitude  = 47.2392665,
  @longitude = -122.3570664,
  @distance= 100,
  @pagenumber = 1,
  @pagesize =25,
  @searchtext =  '',
  @isduns = '0',
  @processids=@p3

declare @p3 dbo.tbltype_listofprocesses
insert into @p3 values(7455)

exec proc_get_supplierpublicprofile
  @MFGLocation  = 0,
  @latitude  = NULL,
  @longitude = NULL,
  @distance= 100,
  @pagenumber = 1,
  @pagesize =25,
  @searchtext =  '',
  @isduns = '0',
  @processids=@p3
*/
CREATE PROCEDURE [dbo].[proc_get_supplierpublicprofile]
  @pagenumber  int = 1,
  @pagesize   int = 25,
  @searchtext  nvarchar(max) = null,
  @MFGLocation  int =null,
  @latitude   float=null,
  @longitude  float=null,
  @distance   int=null,
  @isduns	bit = null,
  @processids  as tbltype_listofprocesses readonly
as

begin
  set nocount on

  -- M2-2490 Supplier Profile - Automatically hide suppliers that don't meet minimum criteria - DB
  -- M2-2652 Supplier Profile API - Allow Search filter by CAGE Code or DUNS - DB


  if (@pagesize <= 0 OR @pagenumber<=0)
  begin
     set @pagenumber=1;
     set @pagesize=25;
  end
    
  declare @processidcount int=0;    
  declare @strsql   nvarchar(max)  
  declare @strwhere   nvarchar(max)  
  declare @strorder   nvarchar(500)  
  
  drop table if exists #processid_companies    
  drop table if exists #companies_processlist    
  drop table if exists #tmp_company_profile_logo     
  drop table if exists #tmp_finaloutput    
  drop table if exists #company_processes    
  drop table if exists #geocode    
  drop table if exists #companies_child_processlist
  drop table if exists #mp_mst_geocode_data
  drop table if exists #tmp_company_profile_logo_url
  /* M2-2490 Supplier Profile - Automatically hide suppliers that don't meet minimum criteria - DB */
  drop table if exists #excludecompanies
  /* */
    
  --here cheking if any processid exists  
  select @processidcount = count(*) from @processids;     
        
  create table #tmp_finaloutput    
  (    
   Logo    varchar(MAX) null ,    
   CompanyName  varchar(500) null ,     
   EmailAddress  varchar(500) null ,     
   PhoneNumber  varchar(500) null ,     
   CompanyId   int,    
   PublicURL   varchar(500) null ,     
   StreetAddress  varchar(500) null ,     
   City    varchar(500) null ,     
   State    varchar(500) null ,    
   Country   varchar(500) null ,    
   PostalCode  varchar(500) null ,     
   Latitude   varchar(500) null ,     
   Longitude   varchar(500) null ,     
   AccountTypeId     int,    
   AccountTypeValue  varchar(500) null ,     
   MFGLocation varchar(500) null ,
   totalcount  int  ,
   /* M2-1848 Supplier API - DB*/
   Is3DFloorPlan bit   ,
   IsHDProfilePhoto int ,
   /**/
   /* M2-2652 */
   Duns		varchar(500) null ,
   Cage		varchar(500) null 
   /**/
  )

  create table #geocode
  (
   zipcode  nvarchar(200) null ,
   distance float null,
   country_id int null
  )
/* M2-2490 Supplier Profile - Automatically hide suppliers that don't meet minimum criteria - DB */
	create table #excludecompanies
	(
		company_id		int ,
		islogo			int default 0,
		isheader		int default 0,
		isdescription	int default 0
	)
/**/

  create table #company_processes (company_id int)

  ----Records inserted into company profile logo temp table
  select comp_id ,cont_id , file_name , filetype_id
  into #tmp_company_profile_logo
  from mp_special_files (nolock) where filetype_id in  (4) and is_deleted = 0

  create nonclustered index idx_tmp_company_profile_logo_comp_id_filetype_id
  on #tmp_company_profile_logo ([comp_id],[filetype_id])

  select comp_id ,cont_id , file_name , filetype_id
  into #tmp_company_profile_logo_url
  from mp_special_files (nolock) where filetype_id in  (6) and is_deleted = 0

  create nonclustered index idx_tmp_company_profile_logo_comp_id_filetype_id_url
  on #tmp_company_profile_logo_url ([comp_id],[filetype_id])

 if (@latitude IS NOT NULL or @latitude != 0) AND  (@longitude IS NOT NULL or @longitude != 0)
 begin
    insert into #geocode
    (zipcode, distance,country_id)
    SELECT
     zipcode, (
    3959 * acos (
    cos (radians(@latitude) )
    * cos( radians( mp_mst_geocode_data.latitude ) )
    * cos( radians( mp_mst_geocode_data.longitude ) - radians(@longitude) )
    + sin ( radians(@latitude) )
    * sin( radians( mp_mst_geocode_data.latitude ) )
     )
    ) as distance
	,country_id
    from mp_mst_geocode_data
    where  latitude <> 0 and longitude <>0

 end

 if (@processidcount != 0)
 begin
   insert into  #company_processes (company_id )
    select distinct a.company_id
    from 
	(
		select company_id,part_category_id from  mp_company_processes a	(nolock) 
		/* M2-2739 */
		union
		select company_id,part_category_id from  mp_gateway_subscription_company_processes a (nolock) 
		/**/
	) a 
    join mp_mst_part_category b (nolock) on  a.part_category_id= b.part_category_id and b.status_id = 2
    join mp_mst_part_category c (nolock) on b.parent_part_category_id= c.part_category_id  and c.status_id = 2
    and b.level in (2,1,0)
    where c.part_category_id in (select processId from @processids)
    /* M2-1848 Supplier API - DB*/
    union
    select distinct a.company_id
    from 
	(
		select company_id,part_category_id from  mp_company_processes a	(nolock) 
		/* M2-2739 */
		union
		select company_id,part_category_id from  mp_gateway_subscription_company_processes a (nolock) 
		/**/
	) a 
    join mp_mst_part_category b (nolock) on  a.part_category_id= b.part_category_id and b.status_id = 2
    and b.level in (2,1)
    where b.part_category_id in (select processId from @processids)
    /**/
 end

 --select * from #company_processes where company_id =1718943

 
/* M2-2490 Supplier Profile - Automatically hide suppliers that don't meet minimum criteria - DB */

insert into #excludecompanies (company_id, isdescription)
select distinct a.company_id , (case when a.description = '' or a.description is null then 0 else 1 end) as isdescription
from mp_companies (nolock) a
join mp_contacts  (nolock) b on a.company_id = b.company_id and is_buyer = 0
where 
not exists (select company_id from mp_registered_supplier where account_type in  (84,85,86,313) and company_id = a.company_id) --M2-5133 added 313 account type
and 
a.company_id > 0

-- logo update
update a set a.islogo =1
from #excludecompanies a
join (select distinct comp_id from mp_special_files (nolock) where filetype_id = 6 and is_deleted = 0) b on a.company_id = b.comp_id 

-- header update
update a set a.isheader =1
from #excludecompanies a
join (select distinct comp_id from mp_special_files (nolock) where filetype_id = 8 and is_deleted = 0) b on a.company_id = b.comp_id 

/**/



set @strsql = ' select Logo,CompanyName,EmailAddress,PhoneNumber,CompanyId,PublicURL,StreetAddress,City,State,Country,PostalCode
,Latitude,Longitude,AccountTypeId,AccountTypeValue,MFGLocation,totalcount, Is3DFloorPlan ,IsHDProfilePhoto , Duns , Cage
     from
     (
      select distinct
       (select top 1 file_name from #tmp_company_profile_logo_url where  a.company_id = comp_id and filetype_id = 6 ) as Logo
       , ltrim(rtrim( replace(ltrim(rtrim( replace(a.name,char(9),'''') )),char(9),'''') ))   as CompanyName
       , f.email    as EmailAddress
       , d.communication_value as PhoneNumber
       , a.company_id   as CompanyId
       , a.companyurl   as PublicURL
       , e.address1 + '' ''+ e.address2 as  StreetAddress
       , e.address4   as   City
       , case when h.region_name = ''Unknown - Do not delete'' then '''' else  h.region_name end as   State
       , i.country_name  as  Country
       , e.Address3   as  PostalCode
       , g.latitude   as   Latitude
       , g.longitude   as   Longitude
       , isnull(sp.id,83)                 as   AccountTypeId
       , isnull(sp.value,''Basic'')         as   AccountTypeValue
       , tc.territory_classification_name  as MFGLocation
       ,  count(1) over ()  as totalcount
       /* M2-1848 Supplier API - DB*/
       , null as Is3DFloorPlan
       , (select count(1) from #tmp_company_profile_logo where a.company_id = comp_id ) as IsHDProfilePhoto
       /**/
	   '
	   +
	   case 
		when (@latitude IS NOT NULL AND  @latitude != 0) AND  (@longitude IS NOT NULL AND @longitude != 0) and  @distance > 0 then ', gtemp.distance '
		else ' , null as distance '
	   end
	   +
	   '
	   , a.duns_number as Duns
	   , a.cage_code as Cage
      from mp_companies     a   (nolock)
	  join 
	  (
		select company_id , contact_id , user_id ,address_id  , row_number() over(partition by company_id order by company_id ,contact_id ) rn
		from  mp_contacts (nolock) where is_buyer =  0  and is_admin =1 
	  )  c on a.company_id = c.company_id and c.rn = 1
     
      left join mp_registered_supplier    rs (nolock) on a.company_id = rs.company_id
      left join mp_system_parameters           sp (nolock) on rs.account_type=sp.id
      left join aspnetusers    f (nolock) on c.user_id = f.id
      left join mp_communication_details d (nolock) on c.contact_id = d.contact_id and d.communication_type_id = 1
      
      left join mp_addresses    e (nolock) on c.address_id = e.address_id --and region_id <> 0
      left join mp_mst_region    h  (nolock) on e.region_id = h.region_id
      left join mp_mst_country   i  (nolock) on e.country_id = i.country_id
      left join mp_mst_geocode_data  g  (nolock) on e.address3 = g.zipcode  and g.country_Id = e.country_id
      left join mp_mst_territory_classification tc(nolock) on a.Manufacturing_location_id=tc.territory_classification_id
     '

  /* Set #company_processes table */
  if (isnull(@processidcount,0) != 0)
  begin
      set @strsql = @strsql  + ' join #company_processes  j (nolock) on a.company_id = j.company_id '
  end
  /*  */

  /*Set #geocode table join condition*/
  if (@latitude IS NOT NULL AND  @latitude != 0) AND  (@longitude IS NOT NULL AND @longitude != 0) and  @distance > 0
  begin

   set @strsql = @strsql +  char(10) + ' join #geocode  gtemp (nolock) on e.address3 = gtemp.zipcode and gtemp.distance < @distance  and e.country_id = gtemp.country_id'
  end
  /*  */

  /*Set where default condition */
  set @strwhere = + char(10) + ' where a.company_id >0 and isnull(is_hide_directory_profile,0) = 0 
								 and a.company_id not in (select distinct company_id from #excludecompanies  where (islogo + isheader +	isdescription)<3 )'
  set @strwhere =  @strwhere
          + case when (@searchtext is not null and @searchtext !='') then ' and  (a.name like ''%'' + @searchtext + ''%'' or ' + case when @isduns = 1 then '( a.duns_number like ''%'' + @searchtext + ''%'' ) ) ' when @isduns = 0 then ' ( a.cage_code like ''%'' + @searchtext + ''%'' ) ) ' else '' end   else '' end
          + case when (@MFGLocation > 0) then ' and a.Manufacturing_location_id =  @MFGLocation ' else '' end
        /*  */

  /*Set order and page size*/
  set  @strorder = '
   ) a
    order by a.AccountTypeId desc , distance
    offset ' + cast(@pagesize as varchar(100)) +  ' * ( ' + cast(@pagenumber as varchar(100)) + ' - 1) rows
    fetch next ' + cast(@pagesize as varchar(100)) + ' rows only '
  /*  */

     /*Inserted data into #tmp_finaloutput */
     set  @strsql = @strsql + @strwhere + @strorder
     set @strsql = ' insert into #tmp_finaloutput
     (
     Logo ,CompanyName ,EmailAddress ,PhoneNumber ,CompanyId ,PublicURL ,StreetAddress ,City
     ,State ,Country ,PostalCode ,Latitude ,Longitude,AccountTypeId,AccountTypeValue,MFGLocation,totalcount ,Is3DFloorPlan  ,IsHDProfilePhoto, Duns , Cage
   ) ' + @strsql
   /*  */

	/*Execute dynamic sql*/
    EXECUTE sp_executesql @strsql ,N'@distance INT,@searchtext nvarchar(max),@MFGLocation int', @distance = @distance,@searchtext = @searchtext ,@MFGLocation = @MFGLocation
    /*  */

	/*here update Is3DFloorPlan column value based on condition*/  
	update  a
	set Is3DFloorPlan = case when len(isnull([3d_tour_url],'')) > 0 then 1 else 0 end 
	from #tmp_finaloutput (nolock)a
	--join mp_companies  b (nolock) on  a.CompanyId = b.company_id
	join mp_company_3dtours  b (nolock) on  a.CompanyId = b.company_id
	/* */  
	
	/*getting parent discipline_name */ 
    select distinct mcp.company_id,parent_pc.discipline_name 
    into #companies_processlist 
    from mp_mst_part_category child_pc
    left join mp_mst_part_category parent_pc on child_pc.parent_part_category_id = parent_pc.part_category_id
    join 
	(
		select company_id,part_category_id from  mp_company_processes a	(nolock) 
		/* M2-2739 */
		union
		select company_id,part_category_id from  mp_gateway_subscription_company_processes a (nolock) 
		/**/
	)  mcp on child_pc.part_category_id=mcp.part_category_id
    where parent_pc.status_id = 2
    and   mcp.company_id   in (select distinct companyid from #tmp_finaloutput)    
    /* */

	/*getting parent-child discipline_name */ 
    select distinct   mcp.company_id ,child_pc.discipline_name 
    into #companies_child_processlist 
    from mp_mst_part_category child_pc
    left join mp_mst_part_category parent_pc on child_pc.parent_part_category_id = parent_pc.part_category_id
    join 
	(
		select company_id,part_category_id from  mp_company_processes a	(nolock) 
		/* M2-2739 */
		union
		select company_id,part_category_id from  mp_gateway_subscription_company_processes a (nolock) 
		/**/
	) mcp on child_pc.part_category_id=mcp.part_category_id
    where  parent_pc.status_id = 2
    and   mcp.company_id   in (select distinct companyid from #tmp_finaloutput)   
    and child_pc.part_category_id in (7442,7472,7473,7474,7475,7478,7479,7489,7490,7491,7493,7496,7497,7499,7501,7538,7542,7547,7575,7576,7579,7585,7586,7589,7593,7609,7614,7617,7619,7622,7646,7650,7651,7653,7655,7656,7658,7670,7732,7733,7734,7740,7745,7746,7747,7748,7749,7751,7755,7757,7759,7760,7761,7763,7764,7765,8158,17677,17691,17724,17735,17767,17770,17783,17785,17792,17794,17795,17797,17800,17801,17836,17837,17838,17841,17842,17847,27677,27678,27982,30005,99999,100000,100001,100002,100003,100004)
	/* */
	  
   SELECT    
    zipcode, country, (    
     3959 * acos (    
     cos ( radians(isnull(@latitude,'')) )    
     * cos( radians( mp_mst_geocode_data.latitude ) )    
     * cos( radians( mp_mst_geocode_data.longitude ) - radians(isnull(@longitude,'')) )    
     + sin ( radians(isnull(@latitude,'')) )    
     * sin( radians( mp_mst_geocode_data.latitude ) )    
    )    
   ) AS distance    
   into #mp_mst_geocode_data    
   FROM mp_mst_geocode_data (nolock)    
   where zipcode in (select distinct postalcode from #tmp_finaloutput)    
   and latitude <> 0 and longitude <>0 
    

   select distinct a.Logo,a.CompanyName,a.EmailAddress,a.PhoneNumber,a.CompanyId,a.PublicURL,a.StreetAddress,a.City  
   ,a.State,a.Country,a.PostalCode,a.Latitude,a.Longitude,a.AccountTypeId,a.AccountTypeValue,a.MFGLocation,a.totalcount   
   ,b.PrimaryProcessesList
   ,c.distance     
   /* M2-1848 Supplier API - DB*/
   ,isnull(Is3DFloorPlan,0) Is3DFloorPlan
   ,IsHDProfilePhoto
   /**/
   ,d.SecondaryProcessesList 
   /* M2-2652 */
   ,a.Duns
   ,a.Cage
   /**/
   from #tmp_finaloutput a    
   left join     
    (    
    select      
     company_id    
     ,stuff((select ', ' + discipline_name  [text()]    
      from #companies_processlist    
      where company_id = t.company_id    
      for xml path(''), type)    
     .value('.','nvarchar(max)'),1,2,'') PrimaryProcessesList    
    from #companies_processlist t    
    group by company_id    
   ) b on a.CompanyId = b.company_id    
   left join     
    (    
    select      
     company_id    
     ,stuff((select ', ' + discipline_name  [text()]    
      from #companies_child_processlist    
      where company_id = t1.company_id    
      for xml path(''), type)    
     .value('.','nvarchar(max)'),1,2,'') SecondaryProcessesList    
    from #companies_child_processlist t1    
	group by company_id    
   ) d on a.CompanyId = d.company_id 
   left join #mp_mst_geocode_data c on a.postalcode = c.zipcode  and a.country = c.country
   
   order by a.AccountTypeId desc , c.distance asc    
   
 
end
