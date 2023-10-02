
CREATE procedure [dbo].[proc_set_saved_search_default_filter]
(
@contact_id int
)
as
begin
   
    declare @transaction_status bit = 0

	if(@contact_id>0)
	begin
		update Mp_Saved_Search
		set 
			is_default  = 0
		where contact_id = @contact_id 

		set @transaction_status = 1
	end

	SELECT case when @transaction_status = 1 then 'Success' else 'Failed'+ ' ' + error_message() end AS TransactionStatus 

end
