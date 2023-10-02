
/*

EXEC proc_get_role_entitlements @Role = 'Super Admin'
EXEC proc_get_role_entitlements @Role = 'Admin'
EXEC proc_get_role_entitlements @Role = 'Engineer'
EXEC proc_get_role_entitlements @Role = 'User'
*/
CREATE PROCEDURE [dbo].[proc_get_role_entitlements]
(
	@Role VARCHAR(150)
)
AS
BEGIN

	SET NOCOUNT ON 
	/*  M2-2859 Vision - Add User Management to the profile drop down menu and a new page - DB */

	SELECT 
		a.Id			AS	EntitlementId
		,c.Id			AS	ElementId
		,c.Element		AS	Element
		,c.[Key]		AS	ElementKey
		,b.Id			AS	PrivilageId
		,b.PrivilegeTo	AS	Privilage
		,b.[Key]			AS	PrivilageKey
		,(CASE WHEN a.DefaultValue	= 1 THEN CAST('true' AS BIT) ELSE CAST('false' AS BIT) END) AS EntitlementValue
	FROM mp_Entitlements		a (NOLOCK)
	JOIN mp_mst_Privilages		b (NOLOCK) ON a.PrivilegeID = b.Id
	JOIN mp_mst_PermissionFor	c (NOLOCK) ON b.ElementID = c.Id
	JOIN aspnetroles			d (NOLOCK) ON a.RoleID = d.Id
	WHERE d.Name = @Role
	ORDER BY c.Id , b.Id

END
