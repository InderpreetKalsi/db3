
/*


DECLARE @XMLSupplierProfile XML;

EXEC proc_get_XML_SupplierProfile
    @PageNumber = 1,
	@PageSize = 5000,
    @XMLOutSupplierProfile = @XMLSupplierProfile OUTPUT;

SELECT @XMLSupplierProfile AS 'SupplierProfileXML';
UPDATE XML_SupplierProfile SET isincludedinxml = 0

SELECT * FROM MP_MST_GEOCODE_DATA WHERE ZIPCODE= '45345'
*/
CREATE PROCEDURE [dbo].[proc_get_XML_SupplierProfile]
(
@PageNumber					INT		= 1
,@PageSize					INT		= 1000
,@XMLOutSupplierProfile		XML OUTPUT	
)
AS
BEGIN
	--M2-3466 Supplier profile XML file generation

	SET NOCOUNT ON

	DROP TABLE IF EXISTS #tmpXMLSupplierProfile
	
	

	SELECT 
		[3dshopview]
		,address
		,avatar
		,banner
		,cagecode
		,capabilities
		,certifications
		,date_established
		,description
		,duns
		--,email
		,employees
		,equipment
		--,first_name
		--,last_name
		,company_id as id
		,gallery
		,industries
		,languages
		,location_manufacturing
		--,marketplaces
		,mfgverified
		,name
		,tier
		,phone
		,owner
		,reviews
		,publicprofile as slug
		,[source]
		,type
		,website
	INTO #tmpXMLSupplierProfile
	FROM XML_SupplierProfile (NOLOCK)
	WHERE isprocessed = 1 AND isincludedinxml =0
	ORDER BY [date_established] DESC
	OFFSET @PageSize * (@PageNumber - 1) ROWS
	FETCH NEXT @PageSize ROWS ONLY
	
	--SELECT * FROM #tmpXMLSupplierProfile
	
	SET @XMLOutSupplierProfile = 
	(
		SELECT 
			[3dshopview] shopview3d
			,address
			,avatar
			,banner
			,cagecode
			,capabilities
			,certifications
			,date_established
			,description
			,duns
			--,email
			,employees
			,equipment
			--,first_name
			--,last_name
			,id
			,gallery
			,industries
			,languages
			,location_manufacturing
			--,marketplaces
			,mfgverified
			,name
			,tier
			,phone
			,owner
			,reviews
			,slug
			,[source]
			,type
			,website
		FROM  #tmpXMLSupplierProfile
		FOR XML PATH('manufacturer'), ROOT('root'),ELEMENTS
	)


	UPDATE XML_SupplierProfile SET isincludedinxml = 1 , includeddate = GETUTCDATE() WHERE company_id IN (SELECT id FROM #tmpXMLSupplierProfile)

END


