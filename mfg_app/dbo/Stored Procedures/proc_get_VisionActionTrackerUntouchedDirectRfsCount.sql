
/*
DECLARE @DirectUntouchedRfqsCount INT
EXEC proc_get_VisionActionTrackerUntouchedDirectRfsCount @DirectUntouchedRfqsCount = @DirectUntouchedRfqsCount OUTPUT
SELECT @DirectUntouchedRfqsCount
*/
CREATE PROCEDURE [dbo].[proc_get_VisionActionTrackerUntouchedDirectRfsCount]
(
	@DirectUntouchedRfqsCount INT OUTPUT
)
AS
BEGIN

	SET NOCOUNT ON
	-- Mar 03 2020 , M2-3670 Directory RFQ - New Simple RFQ Form data - DB


	SET @DirectUntouchedRfqsCount = 
	(
		SELECT COUNT(1) AS DirectUntouchedRfqsCount
		FROM [mpCommunityDirectRfqs]  (NOLOCK) a
		WHERE a.LeadId IS NULL
	)

END
