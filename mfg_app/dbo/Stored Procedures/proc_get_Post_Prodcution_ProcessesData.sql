
/*


DECLARE @p22 dbo.tbltype_ListOfProcesses
INSERT INTO @p22 VALUES(7469)

EXEC [proc_get_Post_Prodcution_ProcessesData]
@Li_Abbr  = 'EN'
,@ProcessIDs = @p22

*/
CREATE  PROCEDURE [dbo].[proc_get_Post_Prodcution_ProcessesData]
( 
	@Li_Abbr varchar(2) = 'EN'
	,@ProcessIDs	AS tbltype_ListOfProcesses	READONLY
)

AS
BEGIN
	
	SET NOCOUNT ON 

	IF (SELECT COUNT(1) FROM @ProcessIDs) = 0 
	BEGIN
		SELECT DISTINCT
			ParentPostProductionProcess.id as ParentPostProductionProcess_id
			, ParentPostProductionProcess.value  as ParentPostProductionProcess_name 
			, ChildPostProductionProcess.id as ChildPostProductionProcess_Id
			, ChildPostProductionProcess.value  as ChildPostProductionProcess_name 
		FROM mp_system_parameters as ChildPostProductionProcess (NOLOCK)
		JOIN mp_system_parameters as ParentPostProductionProcess (NOLOCK)
			ON ChildPostProductionProcess.parent= ParentPostProductionProcess.id 
		WHERE 
			ChildPostProductionProcess.id NOT IN 
			(
				SELECT parent FROM mp_system_parameters where parent IS NOT NULL AND sys_key = '@PostProdProcesses'
			)
		AND ChildPostProductionProcess.parent>0
		AND ChildPostProductionProcess.sys_key = '@PostProdProcesses'
		AND ParentPostProductionProcess.sys_key = '@PostProdProcesses'
		ORDER BY ParentPostProductionProcess_name,ChildPostProductionProcess_name
	END
	/* M2-3353  Data - Map the Post Processes to the Parent Process and Material - DB */
	ELSE IF (SELECT COUNT(1) FROM @ProcessIDs) > 0 
	BEGIN
		SELECT DISTINCT
			ParentPostProductionProcess.id as ParentPostProductionProcess_id
			, ParentPostProductionProcess.value  as ParentPostProductionProcess_name 
			, ChildPostProductionProcess.id as ChildPostProductionProcess_Id
			, ChildPostProductionProcess.value as ChildPostProductionProcess_name 
		FROM mp_mst_process_postprocess_mapping	a (NOLOCK)
		JOIN mp_system_parameters as ChildPostProductionProcess (NOLOCK)
			ON a.postprocess_id = ChildPostProductionProcess.id 
		JOIN mp_system_parameters as ParentPostProductionProcess (NOLOCK)
			ON ChildPostProductionProcess.parent= ParentPostProductionProcess.id 
		LEFT JOIN @ProcessIDs					b ON a.part_category_id = b.processId
		WHERE 
			ChildPostProductionProcess.id NOT IN 
			(
				SELECT parent FROM mp_system_parameters where parent IS NOT NULL AND sys_key = '@PostProdProcesses'
			)
		AND ChildPostProductionProcess.parent>0
		AND ChildPostProductionProcess.sys_key = '@PostProdProcesses'
		AND ParentPostProductionProcess.sys_key = '@PostProdProcesses'
		AND a.part_category_id = (CASE WHEN (SELECT COUNT(1) FROM  @ProcessIDs) > 0 THEN b.processId ELSE a.part_category_id END)
		ORDER BY ParentPostProductionProcess_name,ChildPostProductionProcess_name
	END
	/**/
END
