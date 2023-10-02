

/*
TRUNCATE TABLE mpUserProfileVideoLinks

select * from mpUserProfileVideoLinks order by 1 desc

--SELECT * FROM mp_contacts where contact_id  = 1338129

exec proc_set_CompanyProfileVideos
	@ProfileVideoLinksId		=	4
	,@CompanyId					=   1768233
	,@ContactId					=   1338129
	,@Title						=   'T5'
	,@Description				=	'D5'
	,@VideoLink					=	'https://people.zoho.com/delaplex/zp#timetracker/timelogs/listview5'

select top 5 * from mpUserProfileVideoLinks order by 1 desc
select top 5 * from XML_SupplierProfileCaptureChanges order by 1 desc

*/
CREATE PROCEDURE proc_set_CompanyProfileVideos
(
	@ProfileVideoLinksId		INT
	,@CompanyId					INT
	,@ContactId					INT
	,@Title						VARCHAR(250)
	,@Description				VARCHAR(500)
	,@VideoLink					NVARCHAR(4000) 
)
AS
BEGIN

	-- M2-4549 M - Add the ability to add large videos to the profile - DB

	DECLARE @OldVideoLink	AS NVARCHAR(4000) = '' 

	SELECT @OldVideoLink = ISNULL(VideoLink,'') FROM mpUserProfileVideoLinks (NOLOCK) WHERE Id = @ProfileVideoLinksId

	BEGIN TRY
		IF ISNULL(@VideoLink,'') =  ISNULL(@OldVideoLink,'')
		BEGIN

			UPDATE  mpUserProfileVideoLinks 
			SET
				Title = @Title
				,[Description] = @Description
			WHERE Id = @ProfileVideoLinksId

		END
		ELSE
		BEGIN

			UPDATE  mpUserProfileVideoLinks 
			SET
				IsDeleted = 1
				,DeletedOn = GETUTCDATE()	
				,DeletedBy = @ContactId
			WHERE Id = @ProfileVideoLinksId

			INSERT INTO mpUserProfileVideoLinks (CompanyId ,	ContactId,	Title	,VideoLink	,Description,	IsDeleted , CreatedOn)
			SELECT @CompanyId ,  @ContactId , @Title , @VideoLink , @Description ,  0 , GETUTCDATE()

			INSERT INTO XML_SupplierProfileCaptureChanges (CompanyId , Event ,  CreatedOn , CreatedBy)
			SELECT @CompanyId , 'video_updated'  , GETUTCDATE() , @ContactId

		END

		SELECT TransactionStatus  = 'Success'
	END TRY
	BEGIN CATCH

		ROLLBACK
		SELECT TransactionStatus  = 'Failure'

	END CATCH


END
