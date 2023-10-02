CREATE procedure [dbo].[proc_set_qms_process_material_postproduction]
(
	@set_type smallint  -- 1 process -- 2 material -- 3 post production
	,@supplier_company_id int
	,@value varchar(500)
	
)
as
begin

	/*  M2-2138 M - Create QMS - In the part drawer, make the process list a manual entry - DB*/
	
	declare @identity_id int
	declare @transaction_status bit = 0
	
	begin tran
	begin try
		if 	@set_type = 1  -- process
		begin

			insert into mp_mst_qms_processes (qms_process) values (@value) ;
			set @identity_id =  scope_identity();
			
			if @identity_id > 0
			begin
			
				insert into mp_qms_company_processes(supplier_company_id,qms_process_id)
				select @supplier_company_id , @identity_id

				commit;
				set @transaction_status = 1

				select 
					case when @transaction_status = 1 then 'Success' else 'Failed' end as transaction_status
					,supplier_company_id , qms_process_id as id
				from mp_qms_company_processes (nolock)
				where 
				supplier_company_id  =  @supplier_company_id 
				and qms_process_id = @identity_id

			end
			else 
			begin

				rollback;
				select 
					case when @transaction_status = 1 then 'Success' else 'Failed' end as transaction_status
					,null as supplier_company_id , null as id

			end


		end
		else if 	@set_type = 2  -- material
		begin

			insert into mp_mst_qms_materials (qms_material) values (@value) ;
			set @identity_id =  scope_identity();

			if @identity_id > 0
			begin
				
				insert into mp_qms_company_materials(supplier_company_id,qms_material_id)
				select @supplier_company_id , @identity_id

				commit;
				set @transaction_status = 1

				select 
					case when @transaction_status = 1 then 'Success' else 'Failed' end as transaction_status
					,supplier_company_id , qms_material_id as id
				from mp_qms_company_materials (nolock)
				where 
				supplier_company_id  =  @supplier_company_id 
				and qms_material_id = @identity_id

			end
			else 
			begin

				rollback;
				select 
					case when @transaction_status = 1 then 'Success' else 'Failed' end as transaction_status
					,null as supplier_company_id , null as id

			end

		end
		else if 	@set_type = 3  -- post production
		begin

			insert into mp_mst_qms_post_productions (qms_post_production) values (@value) ;
			set @identity_id =  scope_identity();

			if @identity_id > 0
			begin
				
				insert into mp_qms_company_post_productions(supplier_company_id,qms_post_production_id)
				select @supplier_company_id , @identity_id
				
				commit;
				set @transaction_status = 1

				select 
					case when @transaction_status = 1 then 'Success' else 'Failed' end as transaction_status
					,supplier_company_id , qms_post_production_id as id
				from mp_qms_company_post_productions (nolock)
				where 
				supplier_company_id  =  @supplier_company_id 
				and qms_post_production_id = @identity_id

			end
			else 
			begin

				rollback;
				select 
					case when @transaction_status = 1 then 'Success' else 'Failed' end as transaction_status
					,null as supplier_company_id , null as id

			end
		end

	end try
	begin catch
		rollback;
		select 
			case when @transaction_status = 1 then 'Success' else 'Failed'+ ' ' + error_message() end  as transaction_status
			,null as supplier_company_id , null as id
	end catch

end
