
/*

TRUNCATE TABLE XML_SupplierProfile_Logs
TRUNCATE TABLE XML_SupplierProfile

EXEC [proc_set_XML_SupplierProfile]
SELECT * FROM XML_SupplierProfile_Logs
SELECT * FROM XML_SupplierProfile where company_id =  338576
SELECT * from XML_SupplierProfileCaptureChanges where companyid =  338576
select * from mp_companies where company_id = 1791918
*/
CREATE PROCEDURE [dbo].[proc_set_XML_SupplierProfile]

AS
BEGIN
	--M2-3466 Supplier profile XML file generation
	
	DECLARE @LastRecordDate	DATETIME2 
	DECLARE @CurrentDT		DATETIME2 =  GETUTCDATE()


	SET @LastRecordDate =  ISNULL((SELECT MAX ([createddate]) FROM XML_SupplierProfile (NOLOCK)) ,'2021-01-25 00:00:00.101') 
	SET @LastRecordDate =  DateAdd(millisecond,1,@LastRecordDate)

	--SELECT GETUTCDATE()
	
	EXEC [proc_set_XML_SupplierProfile_NewUsers] 
		@MaxDate			= @LastRecordDate ,
		@CurrentDateTime	= @CurrentDT

	--SELECT GETUTCDATE() CurrentTime
	WAITFOR DELAY '00:00:10' ---- 10 Second Delay
	SELECT GETUTCDATE() CurrentTime

	EXEC [proc_set_XML_SupplierProfile_NewProfileChanges]
	@MaxDate = @LastRecordDate ,
	@CurrentDateTime = @CurrentDT

	--SELECT GETUTCDATE()

END
