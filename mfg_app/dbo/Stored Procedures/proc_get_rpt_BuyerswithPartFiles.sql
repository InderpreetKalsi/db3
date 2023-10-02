-- EXEC proc_get_rpt_BuyerswithPartFiles @parStartDate = '2020-01-01', @parEndDate = '2020-12-31'
CREATE PROCEDURE proc_get_rpt_BuyerswithPartFiles
(
	@parStartDate	DATETIME = NULL
	,@parEndDate	DATETIME = NULL
)
AS
BEGIN

	SET NOCOUNT ON

	DROP TABLE IF EXISTS #tmpRptBuyerWithPartFiles_RfqParts

	SET @parEndDate =  DATEDIFF(dd, 0,@parEndDate) + CONVERT(DATETIME,'23:59:59.900')

	SELECT DISTINCT
		a.rfq_part_id		AS RfqPartId
		, a.rfq_id			AS RfqId
		, a.Created_Date	AS PartCreationDate
		, e.first_name		AS [Buyer First Name]
		, e.last_name		AS [Buyer Last Name]
		, f.email			AS [Buyer Email]
		, CONVERT(VARCHAR(50),REVERSE(LEFT(REVERSE(g.file_name),CHARINDEX('.',REVERSE(g.file_name))-1))) AS PartFileExtension
	INTO #tmpRptBuyerWithPartFiles_RfqParts
	FROM mp_rfq_parts		(NOLOCK)	a
	JOIN mp_rfq_parts_file	(NOLOCK)	b ON a.rfq_part_id = b.rfq_part_id
	JOIN mp_rfq_release_history	(NOLOCK) c ON a.rfq_id = c.rfq_id
	JOIN mp_rfq				(NOLOCK) d ON a.rfq_id = d.rfq_id
	JOIN mp_contacts		(NOLOCK) e ON d.contact_id = e.contact_id
	JOIN aspnetusers		(NOLOCK) f ON e.[user_id] = f.id
	JOIN mp_special_files	(NOLOCK) g ON b.[file_id] = g.[file_id]
 	WHERE 
		a.Created_Date BETWEEN @parStartDate AND @parEndDate
		AND e.is_validated_buyer = 1
		

	SELECT DISTINCT [Buyer First Name] , [Buyer Last Name] , [Buyer Email]
	FROM #tmpRptBuyerWithPartFiles_RfqParts 
	WHERE PartFileExtension IN ('STEP', 'SLDPRT', 'PRT', 'x_t', 'STL', 'IGS', 'IGES', 'STP') 
	ORDER BY [Buyer Email]

	DROP TABLE IF EXISTS #tmpRptBuyerWithPartFiles_RfqParts

END

