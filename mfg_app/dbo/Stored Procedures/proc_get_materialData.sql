
/*

DECLARE @p22 dbo.tbltype_ListOfProcesses
--INSERT INTO @p22 VALUES(17819)

EXEC [proc_get_materialData]
@Li_Abbr = 'EN'
,@CompanyId  = 0
,@ProcessIDs = @p22

*/
CREATE  PROCEDURE [dbo].[proc_get_materialData]--(@Li_Abbr varchar(2) = 'EN')
  @Li_Abbr varchar(2) = 'EN',
  @CompanyId INT ,
  @ProcessIDs			AS tbltype_ListOfProcesses			READONLY

AS
BEGIN
	
	SET NOCOUNT ON 

	IF	@CompanyId>0

	BEGIN
		SELECT 
			ParentMaterial.material_id as Parent_Material_Id
			,ParentMaterial.material_name as Parent_Material_Name 
			,ChildMaterial.material_id as Child_Material_Id
			,ChildMaterial.material_name_en  as Child_Material_Name 
		FROM mp_mst_materials				as ChildMaterial (NOLOCK)
		Join mp_mst_materials				as ParentMaterial (NOLOCK) ON ChildMaterial.material_parent_id = ParentMaterial.material_id 
	    join mp_company_MaterialSpecialties as MCM (NOLOCK) ON ChildMaterial.material_id=MCM.material_id
		WHERE
		MCM.Company_id=@CompanyId
		AND ChildMaterial.is_active=1
		ORDER BY Parent_Material_Name,Child_Material_Name

	END
	/* M2-3399 Buyer - Map Materials and Post process to Parent Processes in the part drawer- DB */
	ELSE IF (SELECT COUNT(1) FROM  @ProcessIDs) > 0
	BEGIN
		
		SELECT DISTINCT 
			ParentMaterial.material_id as Parent_Material_Id
			,ParentMaterial.material_name as Parent_Material_Name 
			,ChildMaterial.material_id as Child_Material_Id 
			,ChildMaterial.material_name_en  as Child_Material_Name 
		FROM mp_mst_process_material_mapping	a (NOLOCK)
		JOIN mp_mst_materials					ChildMaterial (NOLOCK) ON a.material_id = ChildMaterial.material_id
		JOIN mp_mst_materials					ParentMaterial (NOLOCK) ON ChildMaterial.material_parent_id = ParentMaterial.material_id 
		LEFT JOIN @ProcessIDs					b ON a.part_category_id = b.processId
		WHERE 
		ChildMaterial.is_active=1
		AND a.part_category_id = (CASE WHEN (SELECT COUNT(1) FROM  @ProcessIDs) > 0 THEN b.processId ELSE a.part_category_id END)
		ORDER BY Parent_Material_Name,Child_Material_Name

	END
	/**/
	ELSE IF (SELECT COUNT(1) FROM  @ProcessIDs) = 0
	BEGIN
		
		SELECT DISTINCT 
			ParentMaterial.material_id as Parent_Material_Id
			,ParentMaterial.material_name as Parent_Material_Name 
			,ChildMaterial.material_id as Child_Material_Id 
			,ChildMaterial.material_name_en  as Child_Material_Name 
		FROM mp_mst_materials					ChildMaterial (NOLOCK) 
		JOIN mp_mst_materials					ParentMaterial (NOLOCK) ON ChildMaterial.material_parent_id = ParentMaterial.material_id 
		WHERE 
		ChildMaterial.is_active=1
		ORDER BY Parent_Material_Name,Child_Material_Name

	END

END
