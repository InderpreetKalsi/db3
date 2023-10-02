
create procedure [dbo].[proc_update_QMS_quote_parts_status]
  @partIds as tbltype_ListOfQMSQuotePartsId readonly,
  @isAccepted as bit
as
begin	 
	
	begin try	    

		UPDATE mp_qms_quote_parts SET is_accepted =  ISNULL(@isAccepted,0)
		where qms_quote_part_id IN (SELECT PartId  FROM @partIds)

		select 'Success' status
	end try
	begin catch
		select 'Faliure: ' + error_message() as  status
	end catch
end
