﻿Create FUNCTION [dbo].[fn_split_string]
(
    @string    nvarchar(max),
    @delimiter nvarchar(max)
)
/*
    The same as STRING_SPLIT for compatibility level < 130
    https://docs.microsoft.com/en-us/sql/t-sql/functions/string-split-transact-sql?view=sql-server-ver15
*/
RETURNS TABLE AS RETURN
(
    SELECT 
           ROW_NUMBER ( ) over(order by (select 0))  id     --  Not sure if it works correct
         , Split.a.value('.', 'NVARCHAR(MAX)')       value
    FROM
    (
        SELECT CAST('<X>'+REPLACE(@string, @delimiter, '</X><X>')+'</X>' AS XML) AS String
    ) AS a
    CROSS APPLY String.nodes('/X') AS Split(a)
)