
/* 

EXEC proc_get_SupplierPublishProfileStatus  @CompanyId = 1800526
EXEC proc_set_SupplierPublishProfileStatus @CompanyId=1800535 ,@ContactId = 1372581

*/
CREATE PROCEDURE [dbo].[proc_set_SupplierPublishProfileStatus]
(
	@CompanyId	INT
	,@ContactId	INT
)
AS
BEGIN

	DECLARE @StatusId INT

	-- M2-3900 M - Publish my profile decision modal-DB 
	UPDATE a SET a.ProfileStatus = 
			
				CASE 
					WHEN a.ProfileStatus = 234 THEN 234 
					WHEN a.ProfileStatus = 232 THEN 232 
					WHEN b.NewIsProfileCompleted =  1 THEN 231 
					ELSE 230
				END 
			
	FROM mp_companies a (NOLOCK)
	JOIN
	(
		SELECT
			a.company_id
			,
			--CASE  
			--	WHEN e.PaidStatus IN ('03 Gold' , '02 Silver', '04 Platinum') THEN 1
			--	ELSE
					CASE 
						WHEN 
							(
								CASE WHEN LEN(COALESCE( a.description,'')) > 0 THEN 1 ELSE 0 END
								+ CASE WHEN (COALESCE(d.company_id,'0')) > 0 THEN 1 ELSE 0 END  
								+ CASE WHEN LEN(COALESCE( f.address1 , '')) > 0 THEN 1 ELSE 0 END  
							) = 3 THEN CAST(1 AS BIT)
						ELSE CAST(0 AS BIT)
					END 
			 --END 	
			 NewIsProfileCompleted
		FROM mp_companies a
		JOIN 
			(
				SELECT 
					company_id , contact_id , first_name , last_name , is_buyer , address_id, IsTestAccount , [user_id] 
					, ROW_NUMBER() OVER(PARTITION BY company_id ORDER BY company_id , is_admin DESC, contact_id ) rn 
				FROM mp_contacts		(NOLOCK) 
				WHERE is_buyer = 0
		) b ON a.company_id = b.company_id and b.rn=1  
		LEFT JOIN 
		(
			SELECT company_id FROM mp_company_processes (NOLOCK) 
			UNION
			SELECT company_id FROM mp_gateway_subscription_company_processes (NOLOCK) 					 
		) d ON d.company_id = a.company_id
		LEFT JOIN
		(
			SELECT 
				VisionACCTID  AS CompanyId
				,(
					CASE	
						WHEN account_status IN ('active','gold') THEN '03 Gold' --1
						WHEN account_status = 'silver'          THEN '02 Silver'
						WHEN account_status = 'platinum'        THEN '04 Platinum'
						ELSE '01 Basic' 
					END
				 ) AS PaidStatus			
			FROM Zoho..Zoho_company_account (NOLOCK) WHERE synctype = 2 AND  account_type_id = 3 
		) e ON e.CompanyId = a.company_id
		LEFT JOIN mp_addresses f  (NOLOCK) ON f.address_id = b.address_id
	) b ON a.company_id = b.company_id and a.company_id =  @CompanyId



	SET @StatusId = (SELECT ProfileStatus AS StatusId FROM mp_companies a (NOLOCK) WHERE company_id = @CompanyId)

	SELECT @StatusId AS StatusId 

END
