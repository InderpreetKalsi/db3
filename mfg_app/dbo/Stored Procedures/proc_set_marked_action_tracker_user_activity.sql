
/*

	TRUNCATE TABLE mp_vision_action_tracker_tracking

	EXEC proc_set_marked_action_tracker_user_activity
	@ActionTakenBy	= 477
	,@IsBuyer = 0
	,@ContactId	= 1371018
	,@ActivityDate	= '2020-12-18 07:12:50.033'

	EXEC proc_set_marked_action_tracker_user_activity
	@ActionTakenBy	= 1074
	,@IsBuyer = 1
	,@ContactId	= 1350016
	,@ActivityDate	= GETUTCDATE()

SELECT * FROM mp_track_user_activities  (NOLOCK) a WHERE activity_id = 12 AND contact_id = 1350016
SELECT * FROM MP_RFQ WHERE contact_id = 1350016	

	SELECT * FROM MP_MST_ACTIVITIES WHERE  contact_id = 1350016

*/
CREATE PROCEDURE [dbo].[proc_set_marked_action_tracker_user_activity]
(
	@ActionTakenBy	INT
	,@IsBuyer		INT
	,@ContactId		INT
	,@ActivityDate	DATETIME
)
AS
BEGIN

	/* M2-3524  Vision - Action Tracker - Modify the rows to aggregate the check marks under the latest action for 24 hours - DB*/
	DECLARE @StartDate	DATETIME	= DATEADD(HOUR,-24,@ActivityDate)
	DECLARE @EndDate	DATETIME	= GETUTCDATE()
	DECLARE @TransactionStatus VARCHAR(MAX)		= 'Fail'
	--SELECT * FROM mp_vision_action_tracker_tracking

	BEGIN TRY
		IF @IsBuyer = 0
		BEGIN
				
			INSERT INTO mp_vision_action_tracker_tracking 
			(action_taken_by ,action_source ,action_type ,contact_id ,value ,is_marked ,action_taken_on)
			SELECT @ActionTakenBy action_taken_by ,'SupplierActionTracker' action_source, 'New Reg' action_type , contact_id , 0 value , 1 is_marked , GETUTCDATE() action_taken_on
			FROM mp_contacts (NOLOCK)
			WHERE 
			/* M2-3322 Action Tracker - Search By Date not giving accurate result */
			CONVERT(DATE,created_on)>= '2020-09-25'
			AND contact_id = @ContactId
			AND created_on BETWEEN @StartDate AND @EndDate
			/**/
			and is_buyer = 0 

			UNION
			SELECT @ActionTakenBy action_taken_by ,'SupplierActionTracker' action_source, 'Logged In' action_type , contact_id , 0 value , 1 is_marked , GETUTCDATE() action_taken_on
			FROM mp_user_logindetail (NOLOCK)
			WHERE contact_id = @ContactId 
			AND login_datetime BETWEEN @StartDate AND @EndDate

			UNION
			SELECT @ActionTakenBy action_taken_by ,'SupplierActionTracker' action_source, 'Pressed Upgrade' action_type , contact_id , 0 value , 1 is_marked , GETUTCDATE() action_taken_on
			FROM mp_track_user_activities (NOLOCK)
			WHERE activity_id = 3
			AND contact_id = @ContactId
			AND activity_date BETWEEN @StartDate AND @EndDate

			UNION
			SELECT @ActionTakenBy action_taken_by ,'SupplierActionTracker' action_source, 'Landed On Plans' action_type , contact_id , 0 value , 1 is_marked , GETUTCDATE() action_taken_on
			FROM mp_gateway_subscription_tracking (NOLOCK)
			WHERE subscriptions_plan IS NOT NULL
			AND contact_id = @ContactId
			AND created BETWEEN @StartDate AND @EndDate

			UNION
			SELECT @ActionTakenBy action_taken_by ,'SupplierActionTracker' action_source, 'Basic Opened RFQ' action_type , contact_id , Value value , 1 is_marked , GETUTCDATE() action_taken_on
			FROM mp_track_user_activities (NOLOCK)
			WHERE activity_id = 13  AND value <> '0' 
			AND contact_id = @ContactId
			AND activity_date BETWEEN @StartDate AND @EndDate
		END
		ELSE IF @IsBuyer = 1
		BEGIN

			INSERT INTO mp_vision_action_tracker_tracking 
			(action_taken_by ,action_source ,action_type ,contact_id ,value ,is_marked ,action_taken_on)
			SELECT @ActionTakenBy action_taken_by ,'BuyerActionTracker' action_source, 'New Reg' action_type , contact_id , 0 value , 1 is_marked , GETUTCDATE() action_taken_on
			FROM mp_contacts (NOLOCK)
			WHERE 
			/* -- M2-3322 Action Tracker - Search By Date not giving accurate result */
			CONVERT(DATE,created_on)>= '2020-09-25'
			/**/
			AND is_buyer = 1
			AND contact_id = @ContactId
			AND created_on BETWEEN @StartDate AND @EndDate
			UNION
			SELECT @ActionTakenBy action_taken_by ,'BuyerActionTracker' action_source, 'Unval' action_type , a.contact_id , i.rfq_id value , 1 is_marked , GETUTCDATE() action_taken_on
			FROM mp_track_user_activities  (NOLOCK) a 
			JOIN mp_contacts (NOLOCK) b ON a.contact_id = b.contact_id AND b.is_validated_buyer = 0	
			LEFT JOIN mp_rfq i (NOLOCK) ON b.contact_id = i.contact_id AND i.rfq_status_id IN  (1,2)
			WHERE activity_id = 12
			AND a.contact_id = @ContactId
			AND activity_date BETWEEN @StartDate AND @EndDate

			UNION
			SELECT @ActionTakenBy action_taken_by ,'BuyerActionTracker' action_source, 'Logged In' action_type , a.contact_id , 0 value , 1 is_marked , GETUTCDATE() action_taken_on
			FROM mp_user_logindetail	a (NOLOCK)
			JOIN mp_contacts			b (NOLOCK) ON a.contact_id = b.contact_id 
				AND b.contact_id <>0 AND b.is_buyer =1 
			WHERE a.contact_id = @ContactId
			AND login_datetime BETWEEN @StartDate AND @EndDate

		

		END
		
		SET @TransactionStatus = 'Success'

		SELECT @TransactionStatus TransactionStatus
	
	END TRY
	BEGIN CATCH
		
		SET @TransactionStatus = @TransactionStatus + ' :' + Error_Message()

		SELECT @TransactionStatus 

	END CATCH

END
