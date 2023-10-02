-- =============================================
-- Author:		dp-Ash.
-- Create date:  25/10/2018
-- Description:	Stored procedure to Get Capabilities[categories] details for company
-- Modification:
-- Example: [proc_get_Capabilities] '',1701838
-- =================================================================
--Version No – Change Date – Modified By      – CR No – Note
-- =================================================================

CREATE PROCEDURE [dbo].[proc_get_Parent_Capabilities]
	 @Li_Abbr VARCHAR(2)='EN',
	 @CompanyId INT
AS
BEGIN
	
SELECT 
   distinct MCP.company_id,
		Parent_PC.part_category_id as Parent_discipline_id
		, dbo.[fn_getTranslatedValue](Parent_PC.discipline_name, 'EN') as Parent_discipline_name
	FROM 
		mp_mst_part_category Child_PC
		LEFT JOIN mp_mst_part_category Parent_PC on Child_PC.parent_part_category_id = Parent_PC.part_category_id
		 JOIN mp_company_processes MCP on Child_PC.part_category_id=MCP.part_category_id
	WHERE 	
	MCP.company_id=@CompanyId
	and Child_PC.status_id IN(2,4) 
	and Parent_PC.status_id IN(2,4)
	order by Parent_discipline_name

END
