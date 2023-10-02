
-- EXEC  [proc_get_lead_stream] @company_id = 1769227 ,@uptodays = NULL
--
CREATE PROCEDURE [dbo].[proc_get_lead_stream]
(
	@company_id		int
	, @uptodays		int 
	, @pagenumber	int = 1
	, @pagesize		int = 25
	, @datefrom     date = null 
	, @dateto       date = null 
	, @InteractionType INT = 0	 
)
as

begin
	/* M2-1526 Add Lead Stream page - DB */
	set nocount on

	DECLARE @AccountType INT = 313 ---If user comapny has Starter package then exclude such records from list

	if @uptodays is null 
		set @uptodays = 30

	if @datefrom is not null
		set @uptodays = datediff(day, @datefrom , getutcdate())

	if @uptodays is not null and @datefrom is null 
	begin
		set @datefrom = '2000-01-01'
		set @dateto = getutcdate()
				
	end
	
	
	--if @datefrom is not null
	--	set @uptodays = datediff(day, @datefrom , getutcdate())

	select 
	*,  count(1) over () totalcount 
	from
	(
	select  
		a.lead_id
		,a.lead_date
		, c.contact_id
		, case when a.lead_from_contact is null then 'Internet User' else  c.first_name +' ' +c.last_name end as contact_name
		, case when a.lead_from_contact is null OR a.lead_from_contact=0 then 'IP: ' +isnull(ip_address,'')  else  d.name end as company
		, a.ip_address
		, b.lead_source_desc as interaction
		, a.status_id
		, a.lead_source_id
		, a.value
		/* M2-3194 Leadstream - Limit the number of times an IP shows up in leadstream in 24 hour period - DB*/
		--, row_number() over(partition by convert(date,a.lead_date) , case when a.lead_from_contact=0 then ip_address else convert(varchar(50),c.contact_id) end,b.lead_source_desc , a.value order by convert(date,a.lead_date) asc)  rn
		/* M2 - 4395 Add Gallery clicks to the Leadstream - DB */
		,row_number() over(partition by convert(date,a.lead_date) , c.contact_id ,b.lead_source_desc , a.value order by convert(date,a.lead_date) asc)  rn

		/**/
		 
	from mp_lead			a (nolock)
	join mp_mst_lead_source b (nolock)	on a.lead_source_id = b.lead_source_id
	left join mp_contacts	c (nolock)	on a.lead_from_contact = c.contact_id and c.is_active=1
	left join mp_companies	d (nolock)	on c.company_id = d.company_id
	where 
        a.company_id = @company_id	
		/* M2-3251	Vision - Flag as a test account and hide the data from reporting - DB */
		and isnull(c.istestaccount,0)= 0
		/**/
		and convert(date,lead_date)> = dateadd(day, - @uptodays, convert(date,getutcdate()))
		and convert(date,lead_date) between @datefrom and @dateto
		and  
		((@InteractionType  > 0 AND a.lead_source_id = @InteractionType
		  OR
		 (@InteractionType = 0 )))	
		and (CASE WHEN a.lead_source_id in (6,13) AND (a.status_id IS NULL OR a.status_id = 2 OR a.status_id = 0) THEN 0 
		          WHEN a. lead_source_id = 10 AND a.status_id = 2 THEN 0   --change for ticket M2-3172 Leadstream Report Buyer Awards
				  ELSE 1 END) = 1	
		AND @AccountType ! = (SELECT account_type FROM mp_registered_supplier(NOLOCK) WHERE company_id = @company_id) --- M2-5133 
	) a
	/* M2-3194 Leadstream - Limit the number of times an IP shows up in leadstream in 24 hour period - DB*/
	where rn =1 
	/**/
	order by --	a.lead_date desc
	CASE WHEN @datefrom<>'2000-01-01' THEN a.lead_date END asc,
	CASE WHEN @datefrom='2000-01-01' THEN a.lead_date  END desc 
	offset @pagesize * (@pagenumber - 1) rows
	fetch next @pagesize rows only
		
end
