
CREATE FUNCTION [dbo].[fn_mp_GetHashedPasswordForContId]
(
	@ContID numeric(18, 0)
	, @CryptMethodId int
)
RETURNS varchar(40)
AS
BEGIN
	declare @returnValue varchar(40)
	
	select @returnValue = 
		sys.fn_varbintohexsubstring(0, (
			HASHBYTES(
			'SHA1'
			, cast(cont.contact_id as varchar(100))
				+ '_:_' + cont.UserName
				+ '_:_' + cont.PasswordOld
				+ '_:_' + cast(cast(getdate() as date) as varchar(200))
				+ '_:_' + crypt.CRYPT_METHODKEY_VALUE
			)	
		),1,0)
		
	from 
		aspnetusers cont
		inner join mp_crypt_methodkey crypt
			on crypt.CRYPT_METHOD_ID = @CryptMethodId
	where 
		cont.contact_id = @ContID
		
	return @returnValue
END
