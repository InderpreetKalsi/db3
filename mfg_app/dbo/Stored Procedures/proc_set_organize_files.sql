
/*

declare @p28 dbo.tbltype_ListOfFileIds
insert into @p28 values (363856) ,(363854) ,(363855)

exec proc_set_organize_files @FileIds =@p28 
*/
CREATE procedure proc_set_organize_files
(
	@FileIds	as tbltype_ListOfFileIds	readonly
)
as
begin

	/*
	===============================================================================================
	Create date:	Nov 19,2019
	Description:	M2-2294 Supplier Profile - Add ability to organize and set photo order & show 
					labels in gallery (if label exists) - DB 					
	Modification:		 
	===============================================================================================
	*/

	declare @transaction_status			varchar(500) = 'Failed'

	begin tran
	begin try
			
		update a set a.sort_order = b.row_no
		from mp_special_files a  (nolock) 
		join
		(
			select FileId as file_id , row_number() over(order by (select 0)) as row_no from @FileIds
		) b on a.file_id = b.file_id
	
		commit

		set @transaction_status = 'Success'
		select @transaction_status TransactionStatus
	
	end try
	begin catch

		rollback

		set @transaction_status = 'Failed - ' + error_message()
		select @transaction_status TransactionStatus 

	end catch
	
end
