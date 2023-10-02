CREATE PROCEDURE dbo.proc_set_RegisteredSuppliers
AS
BEGIN
	
	TRUNCATE TABLE dbo.mp_registered_supplier

	INSERT INTO DBO.mp_registered_supplier(company_id,is_registered, created_on, updated_on)
	SELECT distinct 
		--a.SUBSCR_ACCOUNT_ID
		--, A.company_id, A.START_DATE,A.EXTENDED_END_DATE
		--, A.STATUS_ID, A.ACTIVE, A.TOTAL_PRICE
		A.company_id
		, 1 as is_registered
		, getdate() as created_on
		, getdate() as updated_on
	FROM  
		dbo.mp_subscr_account A
		INNER JOIN dbo.mp_companies C 
			ON C.company_id = A.company_id
	WHERE 
		DATEDIFF(day,A.START_DATE,A.EXTENDED_END_DATE)>15 
		AND A.STATUS_ID>1 
		AND A.ACTIVE>0
		AND DATEADD(HOUR,12,A.EXTENDED_END_DATE) > GETDATE()
		AND A.TOTAL_PRICE>1 
		and c.is_active = 1
END
