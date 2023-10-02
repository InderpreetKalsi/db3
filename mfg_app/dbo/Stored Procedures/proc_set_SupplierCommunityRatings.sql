
/*
EXEC [proc_set_SupplierCommunityRatings] 
@ReceiverCompanyId = 777705 
, @CommunityRatingsId =  2

*/

CREATE PROCEDURE [dbo].[proc_set_SupplierCommunityRatings]
(
	@ReceiverCompanyId		INT
	,@CommunityRatingsId	INT
)
AS
BEGIN

	/* M2-3995 Vision - Action Tracker - Add Ratings and Reviews tab to Community Users - DB*/

	BEGIN TRY
		
		DECLARE @Rating DECIMAL(18,2)
		DECLARE @TotalResponses INT
		
		INSERT INTO mp_rating_responses(from_id,to_id,score,created_date, ContactName, to_company_id , comment  , is_legacy_rating , parent_id,CommunityRatingID)
		SELECT  DISTINCT
				d.contact_id		AS from_id
				,e.contact_id		AS to_id
				,a.rating			AS score
				,a.ratingdate		AS created_date
				,a.FirstName+ ' '+a.LastName AS ContactName
				,e.company_id		AS to_company_id
				,a.Comment
				,0
				,0
				,@CommunityRatingsId
		FROM mpCommunityRatings			(NOLOCK) a
		LEFT JOIN [dbo].[AspNetUsers]	(NOLOCK) b ON a.SenderEmail = b.Email
		JOIN [AspNetUsers]				(NOLOCK) c ON a.ReceiverEmail = c.Email 
		JOIN mp_contacts				(NOLOCK) d ON b.Id = d.user_id
		JOIN mp_contacts 				(NOLOCK) e ON c.Id = e.user_id
		WHERE a.Id = @CommunityRatingsId 

		/*
		M2-5049 Directory - Ratings and Reviews updates - DB
		---- IF reveived rating from "Non-Loged user"  CommunityRatingsId -> SenderEmail belongs to "Non-Loged user"
		*/
		IF @@ROWCOUNT = 0
		BEGIN
			INSERT INTO mp_rating_responses(from_id,to_id,score,created_date, ContactName, to_company_id , comment  , is_legacy_rating , parent_id,CommunityRatingID)
			SELECT  DISTINCT
					NULL					AS from_id
					,c.contact_id			AS to_id
					,a.rating				AS score
					,a.ratingdate			AS created_date
					,a.FirstName + ' '+ a.LastName AS ContactName
					,@ReceiverCompanyId	    AS to_company_id
					,a.Comment
					,0
					,0
					,@CommunityRatingsId
				FROM mpCommunityRatings		(NOLOCK) a
				JOIN [dbo].[AspNetUsers]	(NOLOCK) b ON a.ReceiverEmail = b.Email
				JOIN mp_contacts			(NOLOCK) c ON c.user_id = b.id  
				Where  a.Id =   @CommunityRatingsId
		END
		/* */

		IF ((SELECT COUNT(1) FROM mp_star_rating (NOLOCK) WHERE company_id = @ReceiverCompanyId) > 0)
		BEGIN

			SELECT 
				@Rating = CONVERT(DECIMAL(18,2),(SUM(score) / COUNT(1)))  
				, @TotalResponses =  COUNT(1)
			FROM mp_rating_responses	(NOLOCK)
			WHERE to_company_id = @ReceiverCompanyId AND SCORE IS NOT NULL
			
			UPDATE mp_star_rating SET no_of_stars = @Rating , total_responses = @TotalResponses WHERE company_id = @ReceiverCompanyId

		END
		ELSE
		BEGIN

			INSERT INTO mp_star_rating (company_id ,no_of_stars ,total_responses)
			SELECT b.to_company_id , CONVERT(DECIMAL(18,2),(SUM(b.score) / COUNT(1))) ratings , COUNT(1) tota_responses
			FROM mp_rating_responses	(NOLOCK) b
			WHERE to_company_id = @ReceiverCompanyId AND SCORE IS NOT NULL
			GROUP BY b.to_company_id

		END

		INSERT INTO XML_SupplierProfileCaptureChanges (CompanyId ,Event ,CreatedOn)
		SELECT @ReceiverCompanyId , 'community_ratings' ,  GETUTCDATE()

		SELECT 'Success'  AS TransactionStatus

	END TRY
	BEGIN CATCH

		SELECT 'Failure - '+ ERROR_MESSAGE()  AS TransactionStatus

	END CATCH

END
