
/*
	EXEC proc_get_SupplierPublishProfileStatus  @CompanyId = 1720706
*/

CREATE PROCEDURE [dbo].[proc_get_SupplierPublishProfileStatus]
(
	@CompanyId	INT
)
AS
BEGIN

	-- M2-3900 M - Publish my profile decision modal-DB 
	SET NOCOUNT ON

	DECLARE @ProfileStatusId AS INT = (SELECT ProfileStatus FROM mp_companies (NOLOCK) WHERE company_id = @CompanyId)
	DECLARE @IsTestAccount AS BIT = 
		CASE WHEN (SELECT SUM(ISNULL(CONVERT(SMALLINT,IsTestAccount),0)) FROM mp_contacts (NOLOCK) WHERE company_id = @CompanyId) > 0 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END
	
	
	-- when account is test then show public view button = disable
	IF @IsTestAccount = 1
	BEGIN

		SELECT 
			CAST(1 AS BIT) AS IsProfileComplete 
			, CAST(1 AS BIT) AS IsSubmittedForPublish 
			, CAST(1 AS BIT) AS IsAbleToViewPublicProfile 
			, CAST(0 AS BIT) AS IsProfileApprovedByVision

	END
	ELSE 
	BEGIN

		-- when account is not test and profile is incomplete then show publish button = disable
		IF @ProfileStatusId IN (230)
		BEGIN

			SELECT 
				CAST(0 AS BIT) AS IsProfileComplete 
				, CAST(0 AS BIT) AS IsSubmittedForPublish 
				, CAST(0 AS BIT) AS IsAbleToViewPublicProfile 
				, CAST(0 AS BIT) AS IsProfileApprovedByVision

		END
		-- when account is not test and profile is complete then show publish button = enable (yet to send for approval or rejected by vision)
		ELSE IF @ProfileStatusId IN (231,233)
		BEGIN

			SELECT 
				CAST(1 AS BIT) AS IsProfileComplete 
				, CAST(0 AS BIT) AS IsSubmittedForPublish 
				, CAST(0 AS BIT) AS IsAbleToViewPublicProfile 
				, CAST(0 AS BIT) AS IsProfileApprovedByVision

		END
		-- when account is not test and profile is complete when send for approval then show public profile button = disable
		ELSE IF @ProfileStatusId IN (232)
		BEGIN

			SELECT 
				CAST(1 AS BIT) AS IsProfileComplete 
				, CAST(1 AS BIT) AS IsSubmittedForPublish 
				, CAST(1 AS BIT) AS IsAbleToViewPublicProfile 
				, CAST(0 AS BIT) AS IsProfileApprovedByVision

		END
		-- when account is not test and profile is complete and approved by vision then show public profile button = enable
		ELSE IF @ProfileStatusId IN (234)
		BEGIN

			SELECT 
				CAST(1 AS BIT) AS IsProfileComplete 
				, CAST(1 AS BIT) AS IsSubmittedForPublish 
				, CAST(1 AS BIT) AS IsAbleToViewPublicProfile 
				, CAST(1 AS BIT) AS IsProfileApprovedByVision

		END

	END


END
