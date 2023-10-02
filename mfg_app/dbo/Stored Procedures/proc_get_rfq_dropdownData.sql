
/*


 exec [proc_get_rfq_dropdownData] @Li_Abbr = 'EN'

*/
CREATE  PROCEDURE [dbo].[proc_get_rfq_dropdownData]( @Li_Abbr varchar(2) = 'EN')

AS
BEGIN
	SET NOCOUNT ON

	/*-- =============================================
	-- Create date: 05 Sep, 2018
	-- Description:	This Procedure will be used in rfq part creation and will return the list of data like
	-- Modified:  12 Aug, 2020
	-- Description: M2-3177 Parent and Children changes - DB
	*/
	

	;WITH Capabilities_Parents AS
	(
		SELECT part_category_id ,discipline_name ,level , parent_part_category_id  , ShowPartSizingComponent , ShowQuestionsOnPartDrawer , SortOrder FROM mp_mst_part_category  (NOLOCK) WHERE status_id =  2 AND level = 0
	) , 
	Capabilities_Childs AS
	(
		SELECT part_category_id ,discipline_name ,level , parent_part_category_id  FROM mp_mst_part_category  (NOLOCK) WHERE status_id =  2 AND level = 1
	)
	SELECT 
		--(CASE WHEN p.discipline_name = c.discipline_name THEN  c.part_category_id ELSE p.part_category_id END) 		AS Parent_discipline_id	
		--, (CASE WHEN p.discipline_name = c.discipline_name THEN  c.discipline_name ELSE p.discipline_name END) 		AS Parent_discipline_name	
		--, (CASE WHEN p.discipline_name = c.discipline_name THEN  c.part_category_id ELSE c.part_category_id END)  	AS Child_discipline_id	
		--, (CASE WHEN p.discipline_name = c.discipline_name THEN  NULL ELSE c.discipline_name END) 	 		AS Child_discipline_name	
		--, (CASE WHEN p.discipline_name = c.discipline_name THEN  0 ELSE c.level END)   AS level
		--, p.level AS plevel
		p.part_category_id		AS Parent_discipline_id	
		, p.discipline_name		AS Parent_discipline_name	
		, c.part_category_id	AS Child_discipline_id	
		, c.discipline_name		AS Child_discipline_name	
		, c.level 
		, p.level AS plevel
		, p.ShowPartSizingComponent 
		, p.ShowQuestionsOnPartDrawer
		, p.SortOrder
	FROM Capabilities_Parents p
	LEFT JOIN Capabilities_Childs c ON p.part_category_id = c.parent_part_category_id
	ORDER BY 
		--(CASE WHEN p.discipline_name = 'Contact an Engineer' THEN 'Z'+p.discipline_name ELSE p.discipline_name END)
		--,c.discipline_name
		 p.SortOrder 

END
