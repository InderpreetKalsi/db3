/*
exec [proc_set_qms_user_quote_settings-NEW]
	@supplier_id			= 1338073
	,@quote_setting_type_id	= 4
	,@default_value			= NULL
*/
CREATE procedure [dbo].[proc_set_qms_user_quote_settings]
(
	@supplier_id			int
	,@quote_setting_type_id	int
	,@default_value			int= null

)
as
begin

	/*
		Oct 21, 2019 - M2-2184 M - Add Quote Details items to the site preferences : DB
		1	Process
		2	Material
		3	Post_Process
		4	Payment_Term
		5	Custom_Cost
		6	Shipping_Method
	*/
		
	declare @transaction_status			varchar(500) = 'Failed'

	begin tran
	begin try

		
		if (@default_value is null or @default_value = 0 )
		begin

				 delete from mp_qms_user_quote_settings 
				 where contact_id = @supplier_id and qms_quote_setting_id = @quote_setting_type_id 

		end
		else if ((select count(1) from mp_qms_user_quote_settings (nolock) where contact_id = @supplier_id and qms_quote_setting_id = @quote_setting_type_id) > 0 )
		begin
				update mp_qms_user_quote_settings 
					set qms_quote_setting_id = @quote_setting_type_id , default_value = @default_value
				where contact_id = @supplier_id AND qms_quote_setting_id = @quote_setting_type_id
		end
		else 
		begin
				insert into mp_qms_user_quote_settings
				(contact_id ,qms_quote_setting_id ,default_value)
				select @supplier_id , @quote_setting_type_id , @default_value

		end

		commit

		set @transaction_status = 'Success'
		
		if (@default_value is null or @default_value = 0 )
			select @transaction_status TransactionStatus , NULL AS ContactId , NULL AS SettingId , NULL Defaultvalue
		else 
			select @transaction_status TransactionStatus , contact_id AS ContactId 
				  ,qms_quote_setting_id AS SettingId 
				  ,default_value AS DefaultValue
			from mp_qms_user_quote_settings (nolock)
			where contact_id = @supplier_id and qms_quote_setting_id = @quote_setting_type_id 


	end try
	begin catch
		rollback

		set @transaction_status = 'Failed - ' + error_message()
		select @transaction_status TransactionStatus , NULL AS ContactID , NULL AS SettingId , NULL Defaultvalue

	end catch
	
end
