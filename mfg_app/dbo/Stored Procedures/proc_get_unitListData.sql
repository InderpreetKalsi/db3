-- =============================================
-- Author:		dp-Sh. B.
-- Create date: 25/10/2018
-- Description:	Stored procedure to Get Unit List records.
-- Modification:
-- Example: [proc_get_unitListData] 
-- =================================================================
--Version No – Change Date – Modified By      – CR No – Note
-- =================================================================

CREATE PROCEDURE [dbo].[proc_get_unitListData](@Li_Abbr varchar(2) = 'EN')
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SELECT 
		id
		, dbo.[fn_getTranslatedValue]([description], @Li_Abbr) as [description]
	FROM 
		dbo.mp_system_parameters 
	WHERE 
		sys_key =  '@UNIT2_LIST' 
	ORDER BY sort_order, [value]

	

END
