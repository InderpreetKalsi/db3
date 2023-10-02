


/*
	SELECT * FROM mp_gateway_subscription_company_processes WHERE 
	EXEC proc_gateway_subscription_get_supplier_capabilities @supplier_company_id = 1769180 
*/
CREATE PROCEDURE [dbo].[proc_gateway_subscription_get_supplier_capabilities]
(
	@supplier_company_id	INT
)
AS
BEGIN

	 
	SET NOCOUNT ON
	DECLARE @AccountType INT = 313 ---If user comapny has Starter package then exclude capabilities from list

	/* M2-2739 Stripe - Capabilities selection for gold & platinum subscription - DB*/

	 --SELECT DISTINCT  
		--SCP.company_id				AS CompanyId,  
		--Parent_PC.part_category_id	AS ParentCapabilityId  
	 -- , Parent_PC.discipline_name	AS ParentCapability  
	 -- --, Child_PC.Part_category_id	AS ChildCapabilityId  
	 -- --, Child_PC.discipline_name	AS ChildCapability  
	 -- , Child_PC.level				AS [Level]
	 --FROM   
	 -- mp_mst_part_category				Child_PC	(NOLOCK) 
	 -- LEFT JOIN mp_mst_part_category	Parent_PC	(NOLOCK)  ON Child_PC.parent_part_category_id = Parent_PC.part_category_id  
	 -- JOIN mp_gateway_subscription_company_processes	SCP			(NOLOCK)  ON Child_PC.part_category_id=SCP.part_category_id  
	 --WHERE    
		-- SCP.company_id=  @supplier_company_id  
		-- and Child_PC.status_id IN(2,4)   
		-- and Parent_PC.status_id IN(2,4)  
	 --ORDER BY Child_PC.[Level],ParentCapability--, ChildCapability  


	 SELECT DISTINCT
		CompanyId
		, (CASE WHEN a.ParentCapability = a.ChildCapability THEN  ChildCapabilityId ELSE ParentCapabilityId END) 	AS ParentCapabilityId	
		, (CASE WHEN a.ParentCapability = a.ChildCapability THEN  ChildCapability ELSE ParentCapability END) 		AS ParentCapability	
		--, (CASE WHEN a.ParentCapability = a.ChildCapability THEN  NULL ELSE ChildCapabilityId END)  ChildCapabilityId 	
		--, (CASE WHEN a.ParentCapability = a.ChildCapability THEN  NULL ELSE ChildCapability END) 	 		AS ChildCapability	
		, [Level]  AS [Level]
	FROM
	(
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
		  JOIN mp_gateway_subscription_company_processes	SCP			(NOLOCK)  ON Child_PC.part_category_id= SCP.part_category_id  
		 WHERE    
			 SCP.company_id= @supplier_company_id
			 AND @AccountType ! = (SELECT account_type FROM mp_registered_supplier(NOLOCK) WHERE company_id = @supplier_company_id) --- M2-5133 
			 and Child_PC.status_id IN(2,4)   
			 and Parent_PC.status_id IN(2,4)  
	) a
	ORDER BY [Level],ParentCapability  


END
