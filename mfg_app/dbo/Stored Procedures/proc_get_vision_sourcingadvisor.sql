-- EXEC proc_get_vision_sourcingadvisor @ForBuyer = 1
CREATE PROCEDURE [dbo].[proc_get_vision_sourcingadvisor]
(
	@ForBuyer BIT
)
AS
BEGIN
	SET NOCOUNT ON
	/*
		-- Created	:	May 29, 2020
		--			:	M2-2906 Vision - Action Tracker Page - DB

		---Modified on 03-Jul-2023
		1. Removed these 2 ids from below list 1571 , 1349037 , As per request from Soel
		2. Contact id : 1421952 added in code on 14-jul-2023

		--Modified on 13-Sep-2023
		can you add Shonta Lockett as Account Owner for Buyers - she is already created in vision and her phone number should be - 678-981-4040
	*/

	IF @ForBuyer = 1
	BEGIN

		SELECT 
			b.contact_id SourcingAdvisorId 
			,b.first_name +' '+b.last_name AS SourcingAdvisor 
		FROM mp_contacts	b (NOLOCK)
		WHERE b.contact_id in 
		(1560,1247,1577,1585,1345421,1367274,1415016,1415017,1419517,1421952,1423839)
		ORDER BY SourcingAdvisor

	END
	ELSE IF @ForBuyer = 0
	BEGIN

		SELECT 
			b.contact_id SourcingAdvisorId 
			,b.first_name +' '+b.last_name AS SourcingAdvisor 
		FROM mp_contacts	b (NOLOCK)
		WHERE b.contact_id in 
		(1483,1247,1585,1339475,1367274,1415016,1415017,1419517,1421952
		---- below are customer support rep
		,1349037,1548,1579,1419075,1421106
		)
		ORDER BY SourcingAdvisor
	
	END

END
