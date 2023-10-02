
/*

EXEC proc_get_sale_question_answers @QId = NULL
EXEC proc_get_sale_question_answers @QId = 101
EXEC proc_get_sale_question_answers @QId = 102

*/

CREATE PROCEDURE proc_get_sale_question_answers
(
	@QId	INT = NULL
)
AS
BEGIN
	SET NOCOUNT ON
	/* M2-2726 M - Contact sales modal*/


	IF @QId IS NULL OR @QId = 0
	BEGIN

		SELECT 
			id				AS [Id]
			,description	AS [Desc]
		FROM  mp_mst_sale_question_answers
		WHERE  parent_id IS NULL
		ORDER BY id

	END
	ELSE IF @QId = 102
	BEGIN

		SELECT 
			activity_id		AS [Id]
			,activity	AS [Desc]
		FROM  mp_mst_activities
		WHERE  activity_id IN (6,7,8)
		ORDER BY id

	END
	ELSE 
	BEGIN

		SELECT 
			id				AS [Id]
			,description	AS [Desc]
		FROM  mp_mst_sale_question_answers
		WHERE  parent_id = @QId
		ORDER BY id

	END

END
