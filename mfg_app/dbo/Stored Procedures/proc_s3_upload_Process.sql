

--drop procedure [proc_s3_upload_Process]
--go


/*
declare @tbl_email_notification_sentflag tbl_email_notification_sentflag
insert into @tbl_email_notification_sentflag values(1)

exec proc_set_email_notification_sent_flag @tbl_email_notification_sentflag 


select * from mp_email_messages a
*/

CREATE procedure [dbo].[proc_s3_upload_Process]
(
	@tbl_s3_upload_Process tbl_s3_upload_Process READONLY
)
as
begin
	declare @record_count int = 0

	begin try
		
	INSERT INTO s3_process_files (file_name, legacy_file_id, src_folder, dest_folder, importedDate) 
		SELECT [file_name], [legacy_file_id],[src_folder],[dest_folder], GETDATE() FROM @tbl_s3_upload_Process	

		--SELECT files.FILE_ID, files.FILE_NAME, files.FILETYPE_ID, files.Legacy_file_id  FROM mp_special_files AS files
		--JOIN @tbl_fileCheck_flags AS filechk 
		--on files.Legacy_file_id = filechk.Id 
		--and files.FILETYPE_ID = filechk.fileType
		
	end try
	begin catch
		--select 'FAILURE: '+ error_message()  processStatus
	end catch


end
