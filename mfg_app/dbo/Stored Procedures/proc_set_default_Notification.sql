

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[proc_set_default_Notification] 
	@ContactId INT
AS
BEGIN
	
	insert into mp_scheduled_job(scheduler_type_id,contact_id,is_real_time,is_scheduled,is_deleted)
	values
	(4,@ContactId,1,0,0), 
	(2,@ContactId,1,0,0),
	(1,@ContactId,1,0,0),
	(3,@ContactId,1,0,0),
	(12,@ContactId,1,0,0),
	(5,@ContactId,1,0,0),
	(9,@ContactId,0,0,0),
	(6,@ContactId,0,0,0),
	(7,@ContactId,0,0,0),
	(8,@ContactId,0,0,0)
	 
END
