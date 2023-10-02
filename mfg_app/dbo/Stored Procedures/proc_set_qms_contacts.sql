/*

declare @p2 dbo.tbltype_ImportQMSContacts
insert into @p2 values(N'
tests',N'Last name',N'city',N'eee@hhh.co',N'455',N'fgfgf',N'fisrt name',N'ss',N'ccccc',N'22332')
insert into @p2 values(N'
tytyt',N'Last name',N'city',N'hggf@hhh.com',N'423',N'45',N'first name',N'fg',N'trrtr',N'654654')


exec proc_set_qms_contacts @SupplierId=1337894,@QMSContacts=@p2

*/

------------------------------------------------------------------------------------------------------
CREATE procedure [dbo].[proc_set_qms_contacts]
(
	@SupplierId		int
	,@QMSContacts	as tbltype_ImportQMSContacts			readonly
	
)
as
begin
	/*
		Jan 28, 2020 - M2-2587 M - My Customers - Upload CSV Step 2 - Mapping- DB
	*/
		
	declare @transaction_status		varchar(500) = 'Failed'
	declare @created_date			datetime = getutcdate()
	declare @ImportCount			int  = 0

	begin tran
	begin try

		insert into mp_qms_contacts
		(supplier_id,company,first_name,last_name,email,phone,address
		,city,state,country,zip_code,state_id,country_id,is_import,created_date)
		select 
			@SupplierId SupplierId , a.*  , c.region_id state_id , b.country_id 
			, 1 is_import ,@created_date 
		from @QMSContacts a
		left join mp_mst_country (nolock) b on ltrim(rtrim(a.country)) = b.country_name
		left join mp_mst_region (nolock) c on ltrim(rtrim(a.state)) = c.region_name
		set @ImportCount = @@ROWCOUNT

		commit

		set @transaction_status = 'Success' 
		select @transaction_status TransactionStatus , @ImportCount as ImportCount

	end try
	begin catch
		rollback
		
		set @transaction_status = 'Failed - ' + error_message()
		select @transaction_status TransactionStatus , 0 as ImportCount

	end catch


end
