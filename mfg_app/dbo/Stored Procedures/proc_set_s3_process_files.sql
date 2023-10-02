CREATE PROCEDURE dbo.proc_set_s3_process_files 
AS
-- =============================================
-- Author:		dp-sb
-- Create date:  1 Feb, 2019
-- Description:	Stored procedure to set the s3_process_files,
--				This is used only during processing of legacy data 
--				and can be no use once we done with legacy data import and up with actual production
-- Modification:
-- =================================================================
--Version No – Change Date – Modified By      – CR No – Note
-- =================================================================
BEGIN
	-- #1. Update not required records
	--update a set a.is_legacy_exist=0 --where is_legacy_exist is null
	--SELECT a.*, b.Legacy_file_id
	DELETE a
	from s3_process_files a left join mp_special_files b
	on a.legacy_file_id = b.Legacy_file_id 
	where b.Legacy_file_id is  null 
 

	-- #2. Update required records
	update s3_process_files set is_legacy_exist=1 where is_legacy_exist is null
	-------
	-- Delete 
	--select * from mp_special_files where FILETYPE_ID=67 and Legacy_file_id not in(
	--select a.Legacy_file_id from mp_special_files a 
	--inner join s3_process_files b on a.FILETYPE_ID=b.filetype_id and a.Legacy_file_id=b.legacy_file_id and b.FILETYPE_ID=67)
	--order by CREATION_DATE
	-----
	--#3. Update File Type 67 - SP_RFQ_FILE
	update s3_process_files set filetype_id=67 where substring(src_folder,1,14)='docroot/rfqfil'
	update b set b.special_file_id= a.file_id from mp_special_files a 
	inner join s3_process_files b on a.FILETYPE_ID=b.filetype_id and a.Legacy_file_id=b.legacy_file_id and b.FILETYPE_ID=67 
	and substring(b.src_folder,1,14) not in('docroot/partit','docroot/thumbd')

	-----#4. Update File Type 76 - SP_PMS_ITEM_FILE 
	update s3_process_files set filetype_id=76 where substring(src_folder,1,14)='docroot/partit'
	update b set b.special_file_id= a.file_id from mp_special_files a 
	inner join s3_process_files b on a.FILETYPE_ID=b.filetype_id and a.Legacy_file_id=b.legacy_file_id and b.FILETYPE_ID=76 

	-----#5. Update File Type 106 - Thumbnails 
	update s3_process_files set filetype_id=106 where substring(src_folder,1,14)='docroot/thumbd'
	update b set b.special_file_id= a.file_id 
	from mp_special_files a 
	inner join s3_process_files b on a.FILETYPE_ID=b.filetype_id and a.Legacy_file_id=b.legacy_file_id and b.FILETYPE_ID=106

	-----#6. Update File Type 6 - LogoOfCompany = 6,
	update s3_process_files set filetype_id=106 where substring(src_folder,1,14)='docroot/logos/'
	update b set b.special_file_id= a.file_id from mp_special_files a 
	inner join s3_process_files b on a.FILETYPE_ID=b.filetype_id and a.Legacy_file_id=b.legacy_file_id and b.FILETYPE_ID=6

	-----#7. Update - BuildingPictureOfCompany = 4,
	update b set b.special_file_id= a.file_id ,filetype_id=a.filetype_id
	--select * 
	from mp_special_files a 
	inner join s3_process_files b on a.Legacy_file_id=b.legacy_file_id and isnull(b.Special_file_id,0)=0
	where a.FILETYPE_ID=4 and substring(b.src_folder,1,14) not in('docroot/partit','docroot/thumbd')

	-----#8. Update - BuildingPictureOfCompany = 14 MultimediaFileOfCompany = 14 Convert into 4,
	update b set b.special_file_id= a.file_id ,filetype_id=4 --select * 
	from mp_special_files a 
	inner join s3_process_files b on a.Legacy_file_id=b.legacy_file_id and isnull(b.Special_file_id,0)=0
	where a.FILETYPE_ID=14 and substring(b.src_folder,1,14) not in('docroot/partit','docroot/thumbd')
	-----#9. Update - BannerOfCompanyDisplayOnW = 8,
	update b set b.special_file_id= a.file_id ,filetype_id=8 from mp_special_files a 
	inner join s3_process_files b on a.Legacy_file_id=b.legacy_file_id and isnull(b.Special_file_id,0)=0
	where a.FILETYPE_ID=8 and substring(b.src_folder,1,14) not in('docroot/partit','docroot/thumbd')
	-----#10. Update - ContactPictureFile = 17,
	update b set b.special_file_id= a.file_id ,filetype_id=17 from mp_special_files a 
	inner join s3_process_files b on a.Legacy_file_id=b.legacy_file_id and isnull(b.Special_file_id,0)=0
	where a.FILETYPE_ID=17 and substring(b.src_folder,1,14) not in('docroot/partit','docroot/thumbd')
	-----#11. Update - UnknownDontRemove = 53,
	update b set b.special_file_id= a.file_id ,filetype_id=53 from mp_special_files a 
	inner join s3_process_files b on a.Legacy_file_id=b.legacy_file_id and isnull(b.Special_file_id,0)=0
	where a.FILETYPE_ID=53 and substring(b.src_folder,1,14) not in('docroot/partit','docroot/thumbd')
	-----#12. Update - MESSAGE = 57
	update b set b.special_file_id= a.file_id ,filetype_id=57
	from mp_special_files a 
	inner join s3_process_files b on a.Legacy_file_id=b.legacy_file_id and isnull(b.Special_file_id,0)=0
	where a.FILETYPE_ID=57 and substring(b.src_folder,1,14) not in('docroot/partit','docroot/thumbd')
	-----#13. Update - SP_COMP_NDA = 97
	update b set b.special_file_id= a.file_id ,filetype_id=97
	from mp_special_files a 
	inner join s3_process_files b on a.Legacy_file_id=b.legacy_file_id and isnull(b.Special_file_id,0)=0
	where a.FILETYPE_ID=97 and substring(b.src_folder,1,14) not in('docroot/partit','docroot/thumbd')
	-----#14. Update - SP_FOLLOWUP_CARD = 100
	update b set b.special_file_id= a.file_id ,filetype_id=100
	from mp_special_files a 
	inner join s3_process_files b on a.Legacy_file_id=b.legacy_file_id and isnull(b.Special_file_id,0)=0
	where a.FILETYPE_ID=100 and substring(b.src_folder,1,14) not in('docroot/partit','docroot/thumbd')
	-----#15. Update - GeneralFileOfCompany = 1
	update b set b.special_file_id= a.file_id ,filetype_id=1
	from mp_special_files a 
	inner join s3_process_files b on a.Legacy_file_id=b.legacy_file_id and isnull(b.Special_file_id,0)=0
	where a.FILETYPE_ID=1 and substring(b.src_folder,1,14) not in('docroot/partit','docroot/thumbd')
	-----#16. Update - InfoFileOfcompany = 2
	update b set b.special_file_id= a.file_id ,filetype_id=2
	--select * 
	from mp_special_files a 
	inner join s3_process_files b on a.Legacy_file_id=b.legacy_file_id and isnull(b.Special_file_id,0)=0
	where a.FILETYPE_ID=2 and substring(b.src_folder,1,14) not in('docroot/partit','docroot/thumbd')
	-----#17. Update - CertificateFilesofCompany = 15
	update b set b.special_file_id= a.file_id ,filetype_id=15 --select * 
	from mp_special_files a 
	inner join s3_process_files b on a.Legacy_file_id=b.legacy_file_id and isnull(b.Special_file_id,0)=0
	where a.FILETYPE_ID=15 and substring(b.src_folder,1,14) not in('docroot/partit','docroot/thumbd')
END
