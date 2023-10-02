
/*
EXEC proc_get_DataSync_SupplierList

SELECT *  FROM  mpDataSyncSupplierProfileToCommunityLogs (nolock) WHERE [DBObject] = 'DataSync-Profile-OnDemand-2022Jul22-Manually'

SELECT *
	FROM mpDataSyncSupplierProfileToCommunityLogs  (NOLOCK)
	WHERE 
		[IsProcessed] = 0 
		/* M2-3845 Data Sync Marketplace to Community -DB*/
		AND CompanyProfileStatus = 234
		/**/
	ORDER BY [CompanyId]

UPDATE mpDataSyncSupplierProfileToCommunityLogs SET  [IsProcessed] = 0, IsSyncFailed = 1 WHERE Id = 850


*/
CREATE PROCEDURE [dbo].[proc_get_DataSync_SupplierList]
AS
BEGIN
	-- M2-3780  Data Sync for Supplier Directory from MS SQL Server to MySQL
	
	SET NOCOUNT ON

	DECLARE @LastRecordDate DATETIME2 = ISNULL((SELECT MAX(FetchDataToDateTime) FROM mpDataSyncSupplierProfileToCommunityLogs (NOLOCK)),DATEADD(MINUTE, -5 , GETUTCDATE()))
	DECLARE @CurrentDT		DATETIME2 = GETUTCDATE()
	
	/* M2-4157 Reinsert failed data-sync records logic implementation -DB */
	DROP TABLE IF EXISTS #tmp_DataSync_SupplierList_FailedToSyncSuppliers
	SELECT * INTO #tmp_DataSync_SupplierList_FailedToSyncSuppliers FROM mpDataSyncSupplierProfileToCommunityLogs WHERE [IsProcessed] = 0 AND IsSyncFailed = 1  
	/**/

	
	UPDATE mpDataSyncSupplierProfileToCommunityLogs SET [IsProcessed] = 1 WHERE [IsProcessed] = 0

	-- Fetch list of newly created supplier companies 
	INSERT INTO mpDataSyncSupplierProfileToCommunityLogs ([DBObject] , [CompanyId] , [FetchDataFromDateTime] , [FetchDataToDateTime] , CompanyProfileStatus)
	SELECT DISTINCT 'mp_companies-NewUserRegistered' ,  b.company_id AS CompanyId ,  @LastRecordDate  , @CurrentDT  ,ProfileStatus
	FROM mp_companies		(NOLOCK) b
	JOIN (SELECT company_id , is_buyer, IsTestAccount FROM mp_contacts		(NOLOCK) ) a ON a.company_id = b.company_id 
	WHERE 
		a.is_buyer = 0 
		AND IsTestAccount = 0 
		AND b.COMPANY_ID <> 0
		AND b.created_date BETWEEN @LastRecordDate AND @CurrentDT
	UNION
	-- Fetch list of supplier companies who update their profile 
	SELECT DISTINCT 'XML_SupplierProfileCaptureChanges' , CompanyId ,  @LastRecordDate  , @CurrentDT ,ProfileStatus
	FROM XML_SupplierProfileCaptureChanges (NOLOCK) A
	JOIN mp_companies		(NOLOCK) b ON a.CompanyId = b.company_id
	JOIN (SELECT company_id , is_buyer, IsTestAccount FROM mp_contacts		(NOLOCK) ) c ON b.company_id = c.company_id 
	WHERE 
		CreatedOn BETWEEN @LastRecordDate AND @CurrentDT
		AND c.is_buyer = 0 
		AND c.IsTestAccount = 0 
		AND b.company_id <> 0
	UNION
	-- Fetch list of supplier companies who update their paid status in Zoho 
	--SELECT 'mp_registered_supplier-PaidStatus' , a.company_id  AS CompanyId ,  @LastRecordDate  , @CurrentDT ,ProfileStatus
	--FROM zoho..zoho_sink_down_logs (NOLOCK) a
	--JOIN mp_companies		(NOLOCK) b ON a.company_id = b.company_id
	--WHERE 
	--	table_name = 'mp_registered_supplier' 
	--	AND log_date BETWEEN @LastRecordDate AND @CurrentDT
	SELECT 'mp_registered_supplier-PaidStatus' , a.company_id  AS CompanyId ,  @LastRecordDate  , @CurrentDT ,ProfileStatus
	FROM mp_registered_supplier (NOLOCK) a
	JOIN mp_companies		(NOLOCK) b ON a.company_id = b.company_id
	WHERE 
		(
			created_on BETWEEN @LastRecordDate AND @CurrentDT
			OR updated_on BETWEEN @LastRecordDate AND @CurrentDT
		)

	UNION
	-- Fetch list of supplier companies who update their paid status in Zoho 
	SELECT 'mp_companies-HideProfile' , a.company_id  AS CompanyId ,  @LastRecordDate  , @CurrentDT  ,ProfileStatus
	FROM zoho..zoho_sink_down_logs (NOLOCK)  a
	JOIN mp_companies		(NOLOCK) b ON a.company_id = b.company_id
	WHERE 
		table_name = 'mp_companies' 
		AND field_name = 'is_hide_directory_profile'
		AND log_date BETWEEN @LastRecordDate AND @CurrentDT

	
	-- Fetch list of newly created supplier companies 
	INSERT INTO mpDataSyncSupplierProfileToCommunityLogs ([DBObject] , [CompanyId] , [FetchDataFromDateTime] , [FetchDataToDateTime] , [IsProcessed] , CompanyProfileStatus)
	SELECT DISTINCT 'XML_SupplierProfileCaptureChanges-HideProfile' , CompanyId ,  @LastRecordDate  , @CurrentDT , 0  , 234
	FROM XML_SupplierProfileCaptureChanges (NOLOCK) A
	JOIN mp_companies		(NOLOCK) b ON a.CompanyId = b.company_id
	JOIN (SELECT company_id , is_buyer, IsTestAccount FROM mp_contacts		(NOLOCK) ) c ON b.company_id = c.company_id 
	WHERE 
		CreatedOn BETWEEN @LastRecordDate AND @CurrentDT
		AND c.is_buyer = 0 
		AND a.Event = 'hide_profile'
		AND b.company_id <> 0

	--INSERT INTO mpDataSyncSupplierProfileToCommunityLogs ([DBObject] , [CompanyId] , [FetchDataFromDateTime] , [FetchDataToDateTime] , [IsProcessed] , CompanyProfileStatus)
	--SELECT DISTINCT 'DataSync-PaidSupplier-MFGVerified-Manually' , company_id ,  @LastRecordDate  , @CurrentDT , 0  , 234
	--FROM    mp_companies (NOLOCK) b  
	--WHERE company_id in (  
	--322757,337412,337424,337635,347724,401413,468886,517099,627550,641211,672524,695606,697976,748447,838185,1031915,1050596,1172999,1196229,1213612,1232139,1252862,1270190,1391743,1401579,1449218,1491727,1511178,1524338,1530218,1535708,1546467,1550755,1566120,1566739,1646347,1646629,1646928,1647054,1647603,1648064,1684877,1685265,1688285,1692967,1698296,1700769,1700973,1702220,1719015,1721546,1767788,1767789,1767792,1767793,1768162,1768222,1768377,1768390,1768547,1768771,1769143,1770394,1770656,1771550,1773699,1773898,1774560,1774725,1775055,1775796,1775861,1776990,1777260,1777682,1778018,1778840,1778913,1779077,1780073,1780562,1780702,1780829,1780906,1781370,1782399,1782400,1783253,1783915,1784042,1784495,1784583,1785241,1785396,1786765,1786787,1787459,1787738,1788103,1788937,1790899,1791171,1791249,1791424,1791425,1791585,1791869,1792429,1792564,1792859,1792861,1792864,1792890,1792914,1792939,1793007,1793361,1793397,1793460,1793687,1793816,1793822,1794147,1794615,1795003,1795380,1795613,1795863,1796350,1796664,1797279,1797282,1797352,1797412,1798024,1798547,1798614,1798723,1798826,1798895,1799382,1799488,1799556,1834565,1834869,1835237,1835250,1835321,1835635,1836122,1836471,1836576,1836740,1836811,1837181,1837250,1837367,1837450,1837572,1837698,1837814,1837822,1838039,1838040,1838067,1838228,1838247,1838328,1838561,1838605,1838618,1838645,1838660,1838664,1838665,1838685,1838697,1838704,1838792,1838817,1838833,1838868,1838910,1838954,1838958,1839048,1839123,1839130,1839380,1839454
	--)

	--INSERT INTO mpDataSyncSupplierProfileToCommunityLogs ([DBObject] , [CompanyId] , [FetchDataFromDateTime] , [FetchDataToDateTime] , [IsProcessed] , CompanyProfileStatus)
	--SELECT DISTINCT 'DataSync-Profile-OnDemand-13Apr2023-Manually' , company_id ,  @LastRecordDate  , @CurrentDT , 0  , 234
	--FROM    mp_companies (NOLOCK) b  
	--WHERE company_id in ( 1844608,1845396,1845825,1846153,1846789,1846979,1846998,1847027,1847037,1847058,1847066,1847135,1847143,1847147,1847164,1847278,1847280,1847302)

	--INSERT INTO mpDataSyncSupplierProfileToCommunityLogs ([DBObject] , [CompanyId] , [FetchDataFromDateTime] , [FetchDataToDateTime] , [IsProcessed] , CompanyProfileStatus)
	--SELECT DISTINCT 'DataSync-Profile-OnDemand-11May2023-Manually' , company_id ,  @LastRecordDate  , @CurrentDT , 0  , 234
	--FROM    mp_companies (NOLOCK) b  
	--WHERE company_id in (select company_id from tmp_M2_4981_Paid_supplier_details(nolock) where company_id !=0)

	---M2-5013
	--INSERT INTO mpDataSyncSupplierProfileToCommunityLogs ([DBObject] , [CompanyId] , [FetchDataFromDateTime] , [FetchDataToDateTime] , [IsProcessed] , CompanyProfileStatus)
	--SELECT DISTINCT 'DataSync-Profile-OnDemand-06Sept2023-Manually' , company_id ,  @LastRecordDate  , @CurrentDT , 0  , 234
	--FROM    mp_companies (NOLOCK) b  
	--WHERE company_id in 
	--(
	--1839682 --,1838405,1797569,1791591,1788498,1540391
	------select company_id from tmp_M2_4981_Paid_supplier_details(nolock) where company_id !=0
	--)

	

	/* M2-4157 Reinsert failed data-sync records logic implementation -DB */
	INSERT INTO mpDataSyncSupplierProfileToCommunityLogs ([DBObject] , [CompanyId] , [FetchDataFromDateTime] , [FetchDataToDateTime] , [IsProcessed] , CompanyProfileStatus)
	SELECT [DBObject] , [CompanyId] ,  @LastRecordDate  , @CurrentDT , 0  , CompanyProfileStatus 
	FROM #tmp_DataSync_SupplierList_FailedToSyncSuppliers
	/**/

	--INSERT INTO mpDataSyncSupplierProfileToCommunityLogs ([DBObject] , [CompanyId] , [FetchDataFromDateTime] , [FetchDataToDateTime] , CompanyProfileStatus)
	--SELECT DISTINCT 'Industries-Materials-Ratings' , a.CompanyId ,   GETUTCDATE()  , GETUTCDATE() , 234 
	--FROM
	--(
	--	SELECT DISTINCT Company_id CompanyId FROM mp_company_MaterialSpecialties  a (NOLOCK)
	--	UNION
	--	SELECT DISTINCT company_id CompanyId from mp_company_Industryfocus a (NOLOCK)
	--	UNION
	--	SELECT DISTINCT to_company_id CompanyId FROM mp_rating_responses a (NOLOCK) WHERE  score IS NOT NULL
	--) a JOIN mp_contacts b on a.CompanyId = b.company_id AND b.is_buyer = 0


	SELECT 	DISTINCT CompanyId 	
	FROM mpDataSyncSupplierProfileToCommunityLogs  (NOLOCK)
	WHERE 
		[IsProcessed] = 0 
		/* M2-3845 Data Sync Marketplace to Community -DB*/
		AND CompanyProfileStatus = 234
		/**/
	ORDER BY [CompanyId]

 

END


 

