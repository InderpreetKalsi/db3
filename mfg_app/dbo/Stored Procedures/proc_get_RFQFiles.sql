CREATE proc proc_get_RFQFiles
(
@rfq_id int 
)
as 
begin

	set nocount on
	/* download all files related to rfq*/

	select a.FILE_NAME as filename 
	from mp_special_files	a	(nolock) 
	join mp_rfq_parts_file	b	(nolock) on a.FILE_ID=b.file_id
	inner join mp_rfq_parts c	(nolock) on b.rfq_part_id =c.rfq_part_id 
	where c.rfq_id=@rfq_id
	union all
	select a.FILE_NAME as filename 
	from mp_special_files	a	(nolock) 
	join mp_rfq_other_files	b	(nolock) on a.FILE_ID=b.file_id and b.status_id =2
	where b.rfq_id=@rfq_id

end