-----------------------------------------------------------------------------------------------------
/*
EXEC proc_get_spotlight_processlist  @CompanyId =0
EXEC proc_get_spotlight_processlist  @CompanyId =1
*/
--exec [proc_get_spotlight_processlist] @Li_Abbr = 'EN' , @CompanyId =0
/*
EXEC proc_get_spotlight_processlist  @CompanyId =0
EXEC proc_get_spotlight_processlist  @CompanyId =1
*/
--exec [proc_get_spotlight_processlist] @Li_Abbr = 'EN' , @CompanyId =0
CREATE  procedure [dbo].[proc_get_spotlight_processlist] (@Li_Abbr varchar(2) = 'EN' , @CompanyId int)

/*
-- ===================================================================================================================
-- Create date: 09 Jul, 2019
-- Description:	M2-1777 Change the process selector in Discover M and Vision Spotlight to include top level process-DB
-- ===================================================================================================================
*/
AS
BEGIN

	SET NOCOUNT ON
	
	IF @CompanyId > 0 
	BEGIN

		;WITH Capabilities_Parents AS
		(
			SELECT part_category_id ,discipline_name ,level , parent_part_category_id  FROM mp_mst_part_category  (NOLOCK) WHERE status_id in (2) AND level = 0
		) , 
		Capabilities_Childs AS
		(
			SELECT part_category_id ,discipline_name ,level , parent_part_category_id  FROM mp_mst_part_category  (NOLOCK) WHERE status_id in (2) AND level = 1
		)
		SELECT DISTINCT
		a.Parent_discipline_id 	AS Parent_discipline_id	
			, a.Parent_discipline_name AS Parent_discipline_name	
			, NULL  AS Child_discipline_id 	
			, NULL	AS Child_discipline_name	
			, 0 AS [Level] 
		FROM
		(
		SELECT
			p.part_category_id		AS Parent_discipline_id	
			, p.discipline_name	AS Parent_discipline_name	
			, c.part_category_id	AS Child_discipline_id	
			, c.discipline_name		AS Child_discipline_name	
			, c.level  AS [Level]
			--, p.level AS plevel
			FROM Capabilities_Parents p
		LEFT JOIN Capabilities_Childs c					ON p.part_category_id = c.parent_part_category_id
		JOIN mp_company_processes	  MCP	(NOLOCK)	ON c.part_category_id=MCP.part_category_id
		AND MCP.company_id=  @CompanyId 
				AND p.discipline_name NOT IN ('Contact an Engineer')

		)a

	END
	ELSE
	BEGIN

		SELECT DISTINCT
			part_category_id AS Parent_discipline_id	
			, discipline_name  AS Parent_discipline_name	
			, NULL  AS Child_discipline_id 	
			, NULL	AS Child_discipline_name	
			, 0   AS [Level] 
			--, p.level AS pleve
			FROM mp_mst_part_category  (NOLOCK) 
			WHERE status_id =  2 AND level = 0
			AND discipline_name NOT IN ('Contact an Engineer')

--	DROP TABLE IF EXISTS #1

	END
END
