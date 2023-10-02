
CREATE FUNCTION [dbo].[fn_get_datesrange]
(
    @RFQId			INT,
	@StartDate		DATE,
    @EndDate		DATE
)
RETURNS TABLE AS RETURN
(
	SELECT  @RFQId RFQId, DATEADD(DAY, nbr - 1, @StartDate) AS RFQDateRange
	FROM    
	( 
		SELECT    ROW_NUMBER() OVER ( ORDER BY c.object_id ) AS Nbr
		FROM      sys.columns c
	) nbrs
	WHERE   nbr - 1 <= DATEDIFF(DAY, @StartDate, @EndDate)
)