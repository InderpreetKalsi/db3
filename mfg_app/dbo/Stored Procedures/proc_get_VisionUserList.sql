
/*

EXEC [proc_get_VisionUserList] 
@PageNumber=1
,@PageSize=200
,@sortby=N'email'
,@isorderbydesc=0
,@searchtext=N''
,@filterby=N''



*/
CREATE  PROCEDURE [dbo].[proc_get_VisionUserList]      
  @PageNumber INT=1,  
  @PageSize INT=20,  
  @sortby varchar(100) = null ,  
  @isorderbydesc int = 1,  
  @searchtext nvarchar(200) = null,  
  @filterby varchar(200) = null  
AS  
BEGIN    

 set nocount on     	 
 	 
    
	 if @sortby is null or @sortby= ''  
		set @sortby = 'CreatedOn'  
  
	 if (@PageSize is null or @PageSize = 0) and (@PageNumber is null or @PageNumber = 0)  
	 begin  
		set @PageSize = 20  
		set @PageNumber = 1  
	 end  
  
	 if @filterby is null  
		set @filterby = ''  
    
	 
	select *,  count(1) over () TotalCount 
	from 
	(
	   select distinct d.first_name as FirstName,
	   d.last_name as LastName,
	   a.Email as Email,
	   a.Id as UserId,
	   c.Name as Role,
	   d.is_active as IsActive,
	   d.contact_id as ContactId,
	   d.created_on as CreatedOn
	   from AspNetUsers a
	   join mp_contacts d on a.Id = d.User_Id  
	   join  AspNetUserRoles b on a.Id = b.UserId
	   join AspNetRoles c on b.RoleId = c.Id
	   where b.RoleId in ('667763D5-9440-4766-81D4-FBA5AB85FC1C','720DE5EB-25B1-49BE-8FA2-6423524C4693','7711E6AA-FF40-45F6-AA3E-BB2B741EFA49','AF74F5D7-9DD6-4D54-9725-4943679690B2') 
	   and d.is_active = 1
	   
	) a	 
	order by   
	case   when @isorderbydesc =  1 and @sortby = 'FirstName'	then   a.FirstName end desc  
	,case  when @isorderbydesc =  1 and @sortby = 'LastName'		then   a.LastName end desc  
	,case  when @isorderbydesc =  1 and @sortby = 'Email'			then   a.Email end desc  
	,case  when @isorderbydesc =  1 and @sortby = 'Role'			then   a.Role end desc  
	,case  when @isorderbydesc =  1 and @sortby = 'CreatedOn'			then   a.CreatedOn end desc  
	,case  when @isorderbydesc =  0 and @sortby = 'FirstName'	then   a.FirstName end asc    
	,case  when @isorderbydesc =  0 and @sortby = 'LastName'		then   a.LastName end asc  
	,case  when @isorderbydesc =  0 and @sortby = 'Email'			then   a.Email end asc  
	,case  when @isorderbydesc =  0 and @sortby = 'Role'			then   a.Role end asc  
	,case  when @isorderbydesc =  0 and @sortby = 'CreatedOn'			then   a.CreatedOn end asc  
	offset @pagesize * (@pagenumber - 1) rows  
	fetch next @pagesize rows only  	  	
	
    
END
