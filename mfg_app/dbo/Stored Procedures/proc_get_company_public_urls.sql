  
    
 -- =============================================  
-- Author:  <Author,,Name>  
-- Create date: <Create Date,,>  
-- Description: <Description,,>  
-- =============================================  
-- exec proc_get_company_public_urls  
CREATE procedure [dbo].[proc_get_company_public_urls]  
as  
begin  
 set nocount on  
  
 select   
  Company_id as CompanyID  
  --, name as Company  
  , CompanyURL from mp_companies   (NOLOCK)
 where   
 is_hide_directory_profile is  null  
 and CompanyURL is not null  
 order by company_id desc  
  
end  
  
  