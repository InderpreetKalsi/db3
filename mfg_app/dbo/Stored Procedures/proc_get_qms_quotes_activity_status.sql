CREATE PROCEDURE proc_get_qms_quotes_activity_status
@qms_quote_id int
AS
BEGIN
	set nocount on

	SELECT 
	case 
	when (select count(1) from  mp_qms_quote_activities (nolock) where qms_quote_id = @qms_quote_id and qms_quote_activity_id = 101) > 0 then cast('true' as bit) 
	else cast('false' as bit) 
	end as QuoteDowloaded
	, case 
	when (select count(1) from  mp_qms_quote_activities (nolock) where qms_quote_id = @qms_quote_id and qms_quote_activity_id = 102) > 0 then cast('true' as bit) 
	else cast('false' as bit) 
	end as QuoteSentToSelf
	, case 
	when (select count(1) from  mp_qms_quote_activities (nolock) where qms_quote_id = @qms_quote_id and qms_quote_activity_id = 103) > 0 then cast('true' as bit) 
	else cast('false' as bit) 
	end as QuoteSentToCustomer
END
