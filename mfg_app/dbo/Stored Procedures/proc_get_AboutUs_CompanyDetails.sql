  
    
  
  
  
  
CREATE PROCEDURE [dbo].[proc_get_AboutUs_CompanyDetails]   
  
  @CompanyId INT,  
  @IsBuyer bit  
AS  
BEGIN  
   
 IF (@IsBuyer=0)  
 SELECT comp.company_id,name as CompanyName,description,duns_number,employee_count_range_id,  
comp.created_date as CreatedDate,CompSuppl.supplier_type_id as SupplierTypeId,  
SuppType.supplier_type_name_en as CompanyType,  
cage_code as CageCode,comp.CompanyURL,  
comp.Manufacturing_location_id--,comp.[3d_tour_url]  
FROM mp_companies comp   (NOLOCK) 
LEFT JOIN mp_company_supplier_types CompSuppl  (NOLOCK) on Comp.company_id=CompSuppl.company_id   
LEFT JOIN mp_mst_supplier_type SuppType  (NOLOCK) on CompSuppl.supplier_type_id=SuppType.supplier_type_id  
WHERE comp.company_id=@CompanyId --and CompSuppl.is_buyer=0  
  
ELSE IF(@IsBuyer=1)  
SELECT comp.company_id,name as CompanyName,description,duns_number,employee_count_range_id,  
comp.created_date as CreatedDate,SuppType.IndustryBranches_id as SupplierTypeId,  
SuppType.IndustryBranches_name_EN as CompanyType,  
cage_code as CageCode,comp.CompanyURL,  
comp.Manufacturing_location_id--,comp.[3d_tour_url]  
FROM mp_companies comp    (NOLOCK) 
LEFT JOIN mp_company_supplier_types CompSuppl  (NOLOCK) on Comp.company_id=CompSuppl.company_id   
LEFT JOIN mp_mst_IndustryBranches SuppType  (NOLOCK) on CompSuppl.supplier_type_id=SuppType.IndustryBranches_id  
WHERE comp.company_id=@CompanyId --and CompSuppl.is_buyer=1   
  
END  
  