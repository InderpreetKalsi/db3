
/*

EXEC proc_get_buyer_parent_capabilities 
*/
CREATE PROCEDURE [dbo].[proc_get_buyer_parent_capabilities]
AS
BEGIN
	
	SET NOCOUNT ON
	/* M2-3209 Capabiities (Parent & Child) changes - DB */

	    SELECT 
			DISTINCT
			(CASE WHEN a.ParentCapability = a.ChildCapability THEN  ChildCapabilityId ELSE ParentCapabilityId END) 	AS ParentCapabilityId	
			, (CASE WHEN a.ParentCapability = a.ChildCapability THEN  ChildCapability ELSE ParentCapability END) 		AS ParentCapability	
			, NULL  AS ChildCapabilityId 	
			, NULL	AS ChildCapability	
			, 0   AS [Level]
			, ShowPartSizingComponent 
		    , ShowQuestionsOnPartDrawer 
		FROM
		(
			SELECT DISTINCT  
				
				Parent_PC.part_category_id	AS ParentCapabilityId  
			  , Parent_PC.discipline_name	AS ParentCapability  
			  , Child_PC.Part_category_id	AS ChildCapabilityId  
			  , Child_PC.discipline_name	AS ChildCapability  
			  , Child_PC.level				AS [Level]
			  , Parent_PC.ShowPartSizingComponent 
			  , Parent_PC.ShowQuestionsOnPartDrawer 
			 FROM   
			  mp_mst_part_category				Child_PC	(NOLOCK) 
			  LEFT JOIN mp_mst_part_category	Parent_PC	(NOLOCK)  ON Child_PC.parent_part_category_id = Parent_PC.part_category_id  
			    
			 WHERE    
				 Child_PC.status_id IN (2)   
				 and Parent_PC.status_id IN (2)  
			
		) a
		ORDER BY ParentCapability, ChildCapability  

END
