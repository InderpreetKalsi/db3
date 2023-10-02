

--drop procedure [proc_s3_upload_Process]
--go


/*
declare @tbl_s3_upload_Process_NewFileNames tbl_s3_upload_Process_NewFileNames
insert into @tbl_s3_upload_Process_NewFileNames values(1580861, 'dfsdfdfdf')

exec proc_set_email_notification_sent_flag @tbl_email_notification_sentflag 

select top 500 * from s3_process_files where Is_legacy_exist = 1
select * from mp_email_messages a

drop proc proc_s3_upload_Process_newFileName

*/



CREATE procedure [dbo].[proc_s3_upload_Process_newFileName]
(
	@tbl_s3_upload_Process_NewFileNames tbl_s3_upload_Process_NewFileNames READONLY
)
as
begin
	declare @record_count int = 0

	begin try
	
	update specialfile set specialfile.is_processed = 1, 
	specialfile.s3_found_status = tbl.found
	from mp_special_files_public specialfile 
	join @tbl_s3_upload_Process_NewFileNames tbl 
	on specialfile.FILE_ID = tbl.FileId


	--update s3files set  s3files.Process_filename = tbl.file_name
	--from s3_process_files s3files 
	--join @tbl_s3_upload_Process_NewFileNames tbl 
	--on s3files.s3_process_file_id = tbl.FileId

	--INSERT INTO s3_process_files (file_name, legacy_file_id, src_folder, dest_folder, importedDate) 
	--	SELECT [file_name], [legacy_file_id],[src_folder],[dest_folder], GETDATE() FROM @tbl_s3_upload_Process	

		--SELECT files.FILE_ID, files.FILE_NAME, files.FILETYPE_ID, files.Legacy_file_id  FROM mp_special_files AS files
		--JOIN @tbl_fileCheck_flags AS filechk 
		--on files.Legacy_file_id = filechk.Id 
		--and files.FILETYPE_ID = filechk.fileType
		
	end try
	begin catch
		--select 'FAILURE: '+ error_message()  processStatus
	end catch


end
