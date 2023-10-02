
create procedure proc_set_company_url
(
@company_id int
)
as
begin

	declare @company_count int
	declare @company_name nvarchar(500) = (select name from mp_companies where company_id = @company_id )
	declare @company_name_without_specialchars nvarchar(500) = replace(replace(replace(dbo.removespecialchars(@company_name),' ','_'),'__','_'),'___','_')
	
	select @company_count = count(1) from mp_companies (nolock) where name = @company_name

	update mp_companies
	set 
		companyurl  = @company_name_without_specialchars + '_' + convert(varchar(50), @company_count)
	where company_id = @company_id 

end
