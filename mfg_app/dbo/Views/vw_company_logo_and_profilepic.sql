
	CREATE view vw_company_logo_and_profilepic as
	select comp_Id ,cont_id , file_name , filetype_id  from mp_special_files (nolock) where filetype_id in  (6,8) and is_deleted = 0