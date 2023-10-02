    
    
    
-- =============================================  
-- Author:  dp-Sh. B.  
-- Create date:  25/10/2018  
-- Description: Stored procedure to Get Capabilities[categories] details for company  
-- Modification:  
-- Example: [proc_get_Capabilities] '',1701481  
-- =================================================================  
--Version No – Change Date – Modified By      – CR No – Note  
-- =================================================================  
  
CREATE PROCEDURE [dbo].[proc_get_Capabilities]  
  @Li_Abbr VARCHAR(2)='EN',  
  @CompanyId INT  
AS  
BEGIN  
   
  
SELECT distinct  
    MCP.company_id,  
  Parent_PC.part_category_id as Parent_discipline_id  
  , Parent_PC.discipline_name as Parent_discipline_name  
  --, dbo.[fn_getTranslatedValue](Parent_PC.discipline_name, @Li_Abbr) as Parent_discipline_name  
  , Child_PC.Part_category_id as Child_discipline_id  
  , Child_PC.discipline_name as Child_discipline_name  
  --, dbo.[fn_getTranslatedValue](Child_PC.discipline_name, @Li_Abbr) as Child_discipline_name  
  , Child_PC.level  
 FROM   
  mp_mst_part_category Child_PC  (NOLOCK) 
  LEFT JOIN mp_mst_part_category Parent_PC  (NOLOCK)  on Child_PC.parent_part_category_id = Parent_PC.part_category_id  
  JOIN mp_company_processes MCP  (NOLOCK)  on Child_PC.part_category_id=MCP.part_category_id  
 WHERE    
 MCP.company_id= @CompanyId  
 and Child_PC.status_id IN(2,4)   
 and Parent_PC.status_id IN(2,4)   
 and Parent_PC.part_category_id in (7455,7646,7650,17767,7651,7653,17770,7609,7656,7658,17677,7442,7655,7448,7575,27677,7579,27678,7585,7589,7593,7576,7586,7437,7472,7473,7474,7475,7478,7464,17842,7732,7733,7734,7740,7538,7442,7536,17680,17783,17785,17792
,17794,17797,17800,17801,7670,7442,17795,7467,7746,7747,7748,7751,7745,7749,7439,7489,7490,7491,17691,7493,7497,7499,7501,7496,17819,17682,7445,7444,7549,8158,7807,7769,7479,7437,17724,7547,7769,7450,7614,7617,7622,7619,17675,27982,27697,27683,30005,17735
,7468,17847,17836,17837,17838,7755,17841,7757,7469,7763,7764,7761,7759,7760,7765,100003,100004,17819,7445,99998,7769,7769,101006,101007,101008,101009,101010)      
 --or Parent_PC.part_category_id in (17819,7445,99998,7769,7769)   
 order by Child_PC.level,Parent_discipline_name, Child_discipline_name  
END
