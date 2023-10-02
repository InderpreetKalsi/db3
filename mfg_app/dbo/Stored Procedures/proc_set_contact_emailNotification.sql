
CREATE PROCEDURE [dbo].[proc_set_contact_emailNotification]
-- =============================================
-- Author:		dp-sb
-- Create date: 20 July, 2018
-- Description:	Ticket M2-29L Procedure is used to create or update the Contact's notification data. 
--				Developer need to call this procedure with below mentioned parameters.
--				Char(1) types of parameters accepts a charector as mentioned below
--					N - Notify me instantly , 
--					I - Include in my daily summary , 
--					D - Do not notify me
-- =============================================
(
@ContactId int,							--mp_contacts.contact_id
@IsNotifyByEmail bit,					--mp_contacts.is_notify_by_email
@AwardConfirmations char(1),			--mp_scheduled_job.scheduler_type_id, mp_scheduled_job.is_real_time OR is_scheduled OR is_deleted
@NewMessages char(1),					--mp_scheduled_job.scheduler_type_id, mp_scheduled_job.is_real_time OR is_scheduled OR is_deleted
@NewQuotes char(1),						--mp_scheduled_job.scheduler_type_id, mp_scheduled_job.is_real_time OR is_scheduled OR is_deleted		
@NDAsToApprove char(1),					--mp_scheduled_job.scheduler_type_id, mp_scheduled_job.is_real_time OR is_scheduled OR is_deleted		
@OrderStatusUpdates char(1),			--mp_scheduled_job.scheduler_type_id, mp_scheduled_job.is_real_time OR is_scheduled OR is_deleted		
@RatingsToPerformReceived char(1),		--mp_scheduled_job.scheduler_type_id, mp_scheduled_job.is_real_time OR is_scheduled OR is_deleted		
@IsSendDailySummary bit,				--mp_scheduled_job.scheduler_type_id, mp_scheduled_job.is_deleted		
@IsSystemMaintenanceAnnouncements bit,	--mp_scheduled_job.scheduler_type_id, mp_scheduled_job.is_deleted		
@IsNewsletter bit,						--mp_scheduled_job.scheduler_type_id, mp_scheduled_job.is_deleted		
@IsSpecialInvitations bit,				--mp_scheduled_job.scheduler_type_id, mp_scheduled_job.is_deleted		
@IsSendNotificationsAsHTML bit,			--mp_contacts.is_mail_in_HTML
@ErrorMessage nvarchar(250) OUTPUT
)
AS
BEGIN

BEGIN TRY
	DECLARE @tblmp_scheduled_job Table(
	scheduler_type_id	smallint
	, contact_id	int
	, is_real_time	bit
	, is_scheduled	bit
	, is_deleted	bit)

		--Prepare the data from parameter
		BEGIN
	
		
			INSERT INTO @tblmp_scheduled_job(scheduler_type_id, contact_id, is_real_time, is_scheduled, is_deleted )
			SELECT 
					scheduler_type_id
					, @ContactId
					, CASE WHEN upper(@AwardConfirmations) = 'N' THEN 1 ELSE 0 END as is_real_time
					, CASE WHEN upper(@AwardConfirmations) = 'I' THEN 1 ELSE 0 END as is_scheduled
					, CASE WHEN upper(@AwardConfirmations) = 'D' THEN 1 ELSE 0 END as is_deleted
			FROM 
				mp_mst_scheduler_type where scheduler_type_name = 'NEW_ACTIVITY_AWARD_ACCEPTANCE'
			UNION ALL
			SELECT 
					scheduler_type_id
					, @ContactId
					, CASE WHEN upper(@NewMessages) = 'N' THEN 1 ELSE 0 END as is_real_time
					, CASE WHEN upper(@NewMessages) = 'I' THEN 1 ELSE 0 END as is_scheduled
					, CASE WHEN upper(@NewMessages) = 'D' THEN 1 ELSE 0 END as is_deleted
			FROM 
				mp_mst_scheduler_type where scheduler_type_name = 'NEW_ACTIVITY_MESSAGES'
			UNION ALL
			SELECT 
					scheduler_type_id
					, @ContactId
					, CASE WHEN upper(@NewQuotes) = 'N' THEN 1 ELSE 0 END as is_real_time
					, CASE WHEN upper(@NewQuotes) = 'I' THEN 1 ELSE 0 END as is_scheduled
					, CASE WHEN upper(@NewQuotes) = 'D' THEN 1 ELSE 0 END as is_deleted
			FROM 
				mp_mst_scheduler_type where scheduler_type_name = 'NEW_ACTIVITY_QUOTES'
			UNION ALL
			SELECT 
					scheduler_type_id
					, @ContactId
					, CASE WHEN upper(@NDAsToApprove) = 'N' THEN 1 ELSE 0 END as is_real_time
					, CASE WHEN upper(@NDAsToApprove) = 'I' THEN 1 ELSE 0 END as is_scheduled
					, CASE WHEN upper(@NDAsToApprove) = 'D' THEN 1 ELSE 0 END as is_deleted
			FROM 
				mp_mst_scheduler_type where scheduler_type_name = 'NEW_ACTIVITY_2ND_LEVEL_NDA'
			UNION ALL			
			SELECT 
					scheduler_type_id
					, @ContactId
					, CASE WHEN upper(@OrderStatusUpdates) = 'N' THEN 1 ELSE 0 END as is_real_time
					, CASE WHEN upper(@OrderStatusUpdates) = 'I' THEN 1 ELSE 0 END as is_scheduled
					, CASE WHEN upper(@OrderStatusUpdates) = 'D' THEN 1 ELSE 0 END as is_deleted
			FROM 
				mp_mst_scheduler_type where scheduler_type_name = 'JOB_MAIL_PRODUCTION_UPDATE'
			UNION ALL
			SELECT 
					scheduler_type_id
					, @ContactId
					, CASE WHEN upper(@RatingsToPerformReceived) = 'N' THEN 1 ELSE 0 END as is_real_time
					, CASE WHEN upper(@RatingsToPerformReceived) = 'I' THEN 1 ELSE 0 END as is_scheduled
					, CASE WHEN upper(@RatingsToPerformReceived) = 'D' THEN 1 ELSE 0 END as is_deleted
			FROM 
				mp_mst_scheduler_type where scheduler_type_name = 'NEW_ACTIVITY_RATINGS_TO_PERFORM'
		    UNION ALL
			SELECT 
					scheduler_type_id
					, @ContactId
					,0  as is_real_time
					,  0  as is_scheduled
					, CASE WHEN @IsSendDailySummary = 1 THEN 0 ELSE 1 END as is_deleted
			FROM 
				mp_mst_scheduler_type where scheduler_type_name = 'ALERT_DAILY_DIGEST'
			UNION ALL
			SELECT 
					scheduler_type_id
					, @ContactId
					,0  as is_real_time
					,  0  as is_scheduled
					, CASE WHEN @IsSystemMaintenanceAnnouncements = 1 THEN 0 ELSE 1 END as is_deleted
			FROM 
				mp_mst_scheduler_type where scheduler_type_name = 'ALERT_SYSTEM_UPDATES'
			UNION ALL
			SELECT 
					scheduler_type_id
					, @ContactId
					,0  as is_real_time
					,  0  as is_scheduled
					, CASE WHEN @IsNewsletter=1 THEN 0 ELSE 1 END as is_deleted
			FROM 
				mp_mst_scheduler_type where scheduler_type_name = 'ALERT_NEWSLETTER'
			UNION ALL
			SELECT 
					scheduler_type_id
					, @ContactId
						,0  as is_real_time
					,  0  as is_scheduled
					, CASE WHEN @IsSpecialInvitations = 1 THEN 0 ELSE 1 END as is_deleted
			FROM 
				mp_mst_scheduler_type where scheduler_type_name = 'ALERT_SPECIAL_OFFERS'
		END

		 
		---Updating contact tables to set notification information.
		BEGIN TRAN
		--	print 'Updating mp_contacts'
			Update mp_contacts set is_notify_by_email = @IsNotifyByEmail, is_mail_in_HTML =@IsSendNotificationsAsHTML where contact_id = @ContactId
		
			IF EXISTS(select * from mp_scheduled_job where contact_id = @ContactId)
				BEGIN
				--	print 'Updating mp_scheduled_job'
					--Update the existing data
					 UPDATE msj SET
						msj.is_deleted = tmsj.is_deleted
						, msj.is_real_time = tmsj.is_real_time
						, msj.is_scheduled = tmsj.is_scheduled
					 FROM 
						mp_scheduled_job msj
						JOIN @tblmp_scheduled_job tmsj on msj.contact_id = tmsj.contact_id and msj.scheduler_type_id=tmsj.scheduler_type_id
				END
			ELSE
				BEGIN
					--print 'Inserting mp_scheduled_job'
					--Insert the existing data
					INSERT INTO  mp_scheduled_job(scheduler_type_id, contact_id, is_real_time, is_scheduled, is_deleted )
					SELECT scheduler_type_id, contact_id, is_real_time, is_scheduled, is_deleted FROM @tblmp_scheduled_job
				END
		COMMIT TRAN
		SET @ErrorMessage = 'Notification setting saved successfully.'
	END TRY
	BEGIN CATCH
		if @@ERROR <> 0 
		BEGIN
			SET @ErrorMessage = ''
			ROLLBACK TRAN
		END
		SET @ErrorMessage = 'Notification setting failed! ' + char(13)  + ERROR_MESSAGE() 
	END CATCH
		--SELECT @ErrorMessage
END
