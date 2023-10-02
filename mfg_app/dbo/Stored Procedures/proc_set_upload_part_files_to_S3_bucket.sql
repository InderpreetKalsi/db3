-- exec proc_set_upload_part_files_to_S3_bucket @supplier_id = null
CREATE proc proc_set_upload_part_files_to_S3_bucket (@supplier_id int null)
as
begin

	set nocount on

	--select 
	--distinct 
	----top 3
	--a.part_id
	--,a.part_name
	--,a.part_number 
	--,c.file_name
	--,c.FILE_ID
	--,c.FILETYPE_ID
	--,c.Imported_Location
	--,c.Legacy_file_id
	--,c.CREATION_DATE
	--, '/partitemfiles/'+CAST(YEAR(a.creation_date) AS NVARCHAR(5))+ '/' + CAST(DATEPART(month,a.creation_date) AS NVARCHAR(5))+ '/' + CAST(1+DATEPART(DAY,a.creation_date) AS NVARCHAR(5))+'/'+CAST(a.part_id AS NVARCHAR(10)) legacy_file_path 
	--,c.file_title
	--,c.file_caption
	--,c.file_path
	--,c.s3_found_status
	--,c.is_processed

	----into tmp_upload_part_files_dec_05_2019
	--from mp_parts a
	--join mp_parts_files b on a.part_id  = b.parts_id
	--join mp_special_files c on b.file_id = c.file_id and c.filetype_id= 76  and c.Imported_Location = '@PartsFile' --and c.file_path is null
	--where (c.s3_found_status is null and c.is_processed is null )

	
select 
distinct 
--a.rfq_id
--,a.rfq_part_id
--,
a.part_id
,d.part_name
,d.part_number
,c.file_name
,c.FILE_ID  as file_id
,c.FILETYPE_ID
,c.Imported_Location
,c.Legacy_file_id
,c.CREATION_DATE
, '/partitemfiles/'+CAST(YEAR(d.creation_date) AS NVARCHAR(5))+ '/' + CAST(DATEPART(month,d.creation_date) AS NVARCHAR(5))+ '/' + CAST(1+DATEPART(DAY,d.creation_date) AS NVARCHAR(5))+'/'+CAST(a.part_id AS NVARCHAR(10)) legacy_file_path 
	,c.file_title
	,c.file_caption
	,c.file_path
	,c.s3_found_status
	,c.is_processed
--into tmp_upload_part_files_dec_05_2019_2
from mp_rfq_parts a
join mp_rfq_parts_file b on a.rfq_part_id  = b.rfq_part_id
join mp_special_files c on b.file_id = c.file_id and c.filetype_id= 76  and c.Imported_Location = '@PartsFile' --and c.file_path is null
join mp_parts d on a.part_id = d.part_id
join mp_parts_files e on d.part_id  = e.parts_id
where 
--c.file_id = 365978
(c.s3_found_status is null and c.is_processed is null ) 
--and a.part_id not in (select part_id from tmp_upload_part_files_dec_05_2019 )



end