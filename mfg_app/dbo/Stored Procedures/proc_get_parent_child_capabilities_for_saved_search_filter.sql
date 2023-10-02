
	
/*

EXEC proc_get_parent_child_capabilities_for_saved_search_filter @capabilities_list = '542,17677,17801,7656,100001,7479,17770,7670,17783,7450,7467,7593,7469,101036,7499,101042,17675,101057,101052,7576,101034,7491,17767,101025,7586,17792,17785,7464,7468,17800,7493'

*/
CREATE PROCEDURE proc_get_parent_child_capabilities_for_saved_search_filter
(
	@capabilities_list			NVARCHAR(MAX)
)
AS
BEGIN

	SET NOCOUNT ON
	/* M2-3209 Capabiities (Parent & Child) changes - DB */
	DROP TABLE IF EXISTS  #TMP_Capabilities_List
	DROP TABLE IF EXISTS  #TMP_Child_Capabilities_List

	CREATE TABLE #TMP_Capabilities_List
	(
	
		ParentCapabilityId		INT
		,ParentCapability		VARCHAR(150)	
		,ChildCapabilityId		INT
		,ChildCapability		VARCHAR(150)
		,CLevel					INT
		,PLevel					INT
	)
	
	INSERT INTO #TMP_Capabilities_List
	EXEC [proc_get_capabilities_list]

	SELECT DISTINCT ParentCapabilityId , ChildCapabilityId ,  ChildCapability INTO #TMP_Child_Capabilities_List  
	FROM #TMP_Capabilities_List 
	WHERE ChildCapabilityId IN 
	(
		SELECT value AS CapabilityId
		FROM STRING_SPLIT(@capabilities_list, ',')  
		WHERE RTRIM(value) <> ''
	) AND ChildCapability IS NOT NULL 

	SELECT DISTINCT ParentCapabilityId ,  ParentCapability  FROM #TMP_Capabilities_List 
	WHERE ParentCapabilityId IN 
	(
		SELECT Value AS  CapabilityId
		FROM STRING_SPLIT(@capabilities_list, ',')  
		WHERE RTRIM(value) <> ''
		UNION
		SELECT ParentCapabilityId FROM #TMP_Child_Capabilities_List
	) 
	ORDER BY ParentCapabilityId

	SELECT DISTINCT  ParentCapabilityId , ChildCapabilityId ,  ChildCapability FROM #TMP_Child_Capabilities_List  ORDER BY ParentCapabilityId

END
