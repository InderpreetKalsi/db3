

/*  
select * from mpUserGetStartedInfo(nolock) where contactid = 1350499  
select count(1) WillDoLaterCount from mp_rfq where    WillDoLater = 1  --23 records  
select WillDoLater, * from mp_rfq where    WillDoLater = 1  --23 records  
  
EXEC proc_get_UserRfqSubmittedWillDoLaterCount @ContactId = 1350499  
EXEC proc_get_UserRfqSubmittedWillDoLaterCount @ContactId = 1350702  
--------------------------------------------------------------------------------  
*/  
  
CREATE PROCEDURE [dbo].[proc_get_UserRfqSubmittedWillDoLaterCount]  
(  
 @ContactId INT  
)  
AS  
BEGIN  
  ----M2-4537 Lock Buyer Engagement step on refresh - DB  
  SET NOCOUNT ON  
  
  DECLARE @SubmittedRFqCount INT,@WillDoLaterCount INT,@ContactIdStepCount INT  
  
   IF(@ContactId > 0)  
   BEGIN  
   ----Below code commited with M2-4598
   --SELECT @SubmittedRFqCount = COUNT(1)  FROM mp_rfq (NOLOCK) WHERE contact_id = @ContactId AND rfq_status_id > 1 AND rfq_status_id <> 14  

   ----Below code added with M2-4598
  	SELECT @SubmittedRFqCount = COUNT(1) FROM mp_rfq (NOLOCK) a 
									JOIN mp_rfq_revision(NOLOCK) b ON a.rfq_id = b.rfq_id
									WHERE contact_id = @ContactId
									AND b.field = 'RFQ Status'
									AND b.newvalue IN ('Pending Approval','Quoting')

   SELECT @WillDoLaterCount = COUNT(1)   FROM mp_rfq (NOLOCK) WHERE contact_id = @ContactId AND WillDoLater = 1  
    
   SELECT DISTINCT @ContactIdStepCount =   COUNT(DISTINCT StepId) FROM mpUserGetStartedInfo(NOLOCK) WHERE contactid = @ContactId  AND StepId = 5
    
   IF @WillDoLaterCount = 0 AND @ContactIdStepCount  < 1  
    SELECT @SubmittedRFqCount AS SubmittedRFqCount, CAST('FALSE'  AS BIT) AS WillDoLaterCount  , 2 GetStartedStepId , 0 GetStartedSubStepId
   
   IF @WillDoLaterCount > 0   
    SELECT @SubmittedRFqCount AS SubmittedRFqCount,  CAST('TRUE'  AS BIT) AS WillDoLaterCount  , 2 GetStartedStepId , 0 GetStartedSubStepId

   IF @WillDoLaterCount = 0 AND @ContactIdStepCount  = 1  
	SELECT @SubmittedRFqCount AS SubmittedRFqCount,  CAST('TRUE'  AS BIT) AS WillDoLaterCount  , 2 GetStartedStepId , 0 GetStartedSubStepId
  
 END  
  
END
