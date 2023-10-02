
/*

EXEC proc_get_supplier_parent_capabilities @supplier_company_id = 1799152 ,  @type = 'RFQSearch'
*/
CREATE PROCEDURE [dbo].[proc_get_supplier_parent_capabilities]
(
	@supplier_company_id	INT
	,@type					VARCHAR(50) = NULL
)
AS
BEGIN
	
	SET NOCOUNT ON
	/* M2-3209 Capabiities (Parent & Child) changes - DB */

	DECLARE @CapabilityCount INT
	
	SET @CapabilityCount = 
	(
		SELECT SUM(CapabilityCount) FROM
		(
			SELECT COUNT(1) CapabilityCount FROM mp_company_processes WHERE  company_id= @supplier_company_id  
			UNION
			SELECT COUNT(1) CapabilityCount FROM mp_gateway_subscription_company_processes WHERE  company_id= @supplier_company_id  
		) a
	)

	IF @CapabilityCount = 0
	BEGIN
		
		;WITH Capabilities_Parents AS
		(
			SELECT part_category_id ,discipline_name ,level , parent_part_category_id  FROM mp_mst_part_category  (NOLOCK) WHERE status_id =  2 AND level = 0
		) , 
		Capabilities_Childs AS
		(
			SELECT part_category_id ,discipline_name ,level , parent_part_category_id  FROM mp_mst_part_category  (NOLOCK) WHERE status_id =  2 AND level = 1
		)
		SELECT DISTINCT TOP 100
			@supplier_company_id AS CompanyId
			, (CASE WHEN p.discipline_name = c.discipline_name THEN  c.part_category_id ELSE p.part_category_id END) 		AS ParentCapabilityId	
			, (CASE WHEN p.discipline_name = c.discipline_name THEN  c.discipline_name ELSE p.discipline_name END) 		AS ParentCapability	
			, NULL  AS ChildCapabilityId 	
			, NULL	AS ChildCapability	
			, 1   AS [Level]
		FROM Capabilities_Parents p
		LEFT JOIN Capabilities_Childs c ON p.part_category_id = c.parent_part_category_id
		WHERE C.discipline_name <> 'Contact an Engineer'
		ORDER BY 
			ParentCapability


	END
	ELSE
	BEGIN

		SELECT 
			DISTINCT
			CompanyId
			, (CASE WHEN a.ParentCapability = a.ChildCapability THEN  ChildCapabilityId ELSE ParentCapabilityId END) 	AS ParentCapabilityId	
			, (CASE WHEN a.ParentCapability = a.ChildCapability THEN  ChildCapability ELSE ParentCapability END) 		AS ParentCapability	
			, NULL  AS ChildCapabilityId 	
			, NULL	AS ChildCapability	
			, 1   AS [Level]
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
END
