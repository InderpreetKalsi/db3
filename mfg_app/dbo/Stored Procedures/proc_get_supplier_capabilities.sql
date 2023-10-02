
/*

EXEC proc_get_supplier_capabilities @supplier_company_id = 1768939 ,  @type = 'Profile'
EXEC proc_get_supplier_capabilities @supplier_company_id = 1768939 ,  @type = 'RFQSearch'
*/
CREATE PROCEDURE [dbo].[proc_get_supplier_capabilities]
(
	@supplier_company_id	INT
	,@type					VARCHAR(50) = NULL
)
AS
BEGIN
	
	SET NOCOUNT ON
	/* M2-3209 Capabiities (Parent & Child) changes - DB */


	SELECT 
		CompanyId
		, (CASE WHEN a.ParentCapability = a.ChildCapability THEN  ChildCapabilityId ELSE ParentCapabilityId END) 	AS ParentCapabilityId	
		, (CASE WHEN a.ParentCapability = a.ChildCapability THEN  ChildCapability ELSE ParentCapability END) 		AS ParentCapability	
		, (CASE WHEN a.ParentCapability = a.ChildCapability THEN  NULL ELSE ChildCapabilityId END)  ChildCapabilityId 	
		, (CASE WHEN a.ParentCapability = a.ChildCapability THEN  NULL ELSE ChildCapability END) 	 		AS ChildCapability	
		, (CASE WHEN a.ParentCapability = a.ChildCapability THEN  0 ELSE [Level] END)   AS [Level]
	FROM
	(
		SELECT DISTINCT  
			MCP.company_id				AS CompanyId,  
			Parent_PC.part_category_id	AS ParentCapabilityId  
		  , Parent_PC.discipline_name	AS ParentCapability  
		  , Child_PC.Part_category_id	AS ChildCapabilityId  
		  , Child_PC.discipline_name	AS ChildCapability  
		  , Child_PC.level				AS [Level]
		 FROM   
		  mp_mst_part_category				Child_PC	(NOLOCK) 
		  LEFT JOIN mp_mst_part_category	Parent_PC	(NOLOCK)  ON Child_PC.parent_part_category_id = Parent_PC.part_category_id  
		  JOIN mp_company_processes			MCP			(NOLOCK)  ON Child_PC.part_category_id=MCP.part_category_id  
		 WHERE    
			 MCP.company_id= @supplier_company_id  
			 and Child_PC.status_id IN (2,4)   
			 and Parent_PC.status_id IN (2,4)  
		 UNION
		 SELECT DISTINCT  
			SCP.company_id				AS CompanyId,  
			Parent_PC.part_category_id	AS ParentCapabilityId  
		  , Parent_PC.discipline_name	AS ParentCapability  
		  , Child_PC.Part_category_id	AS ChildCapabilityId  
		  , Child_PC.discipline_name	AS ChildCapability  
		  , Child_PC.level				AS [Level]
		 FROM   
		  mp_mst_part_category				Child_PC	(NOLOCK) 
		  LEFT JOIN mp_mst_part_category	Parent_PC	(NOLOCK)  ON Child_PC.parent_part_category_id = Parent_PC.part_category_id  
		  JOIN mp_gateway_subscription_company_processes	SCP			(NOLOCK)  ON Child_PC.part_category_id=SCP.part_category_id  
		 WHERE    
			 SCP.company_id= (CASE WHEN @type = 'Profile' THEN -1 WHEN @type = 'RFQSearch' THEN @supplier_company_id END )  
			 and Child_PC.status_id IN(2,4)   
			 and Parent_PC.status_id IN(2,4)  
	) a
	ORDER BY ParentCapability, ChildCapability  

END
