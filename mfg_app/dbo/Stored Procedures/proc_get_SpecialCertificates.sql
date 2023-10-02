
CREATE PROCEDURE [dbo].[proc_get_SpecialCertificates]
	 @CompanyId INT
AS
BEGIN
	set nocount on
	

--If Company Id is there ,it will provide records for specific Company Id, otherwise it will get all the records.
    IF (@CompanyId>0)
		SELECT TOP(10) compCert.company_certificates_id, mpCertificate.certificate_type_id, COALESCE( mpCertificate.certificate_description,'') AS description, 
		mpCertificate.certificate_id, mpCertificate.certificate_code,SpecialFiles.FILE_NAME,compCert.creation_date
		FROM mp_certificates as mpCertificate
		JOIN Mp_Company_Certificates compCert on mpCertificate.certificate_id=compCert.certificates_id		 		
		LEFT JOIN Mp_Special_Files SpecialFiles ON  SpecialFiles.FILE_ID=compCert.file_id
		WHERE compCert.company_id=@CompanyId
		ORDER BY compCert.company_certificates_id DESC

	ELSE		
		SELECT CertificateType.certificate_type_id, CertificateType.description, mpCertificate.certificate_id, mpCertificate.certificate_code,creation_date 
		FROM mp_certificates as mpCertificate
		JOIN mp_mst_certificate_types as CertificateType on mpCertificate.certificate_type_id = CertificateType.certificate_type_id
		ORDER BY CertificateType.certificate_type_id
END


