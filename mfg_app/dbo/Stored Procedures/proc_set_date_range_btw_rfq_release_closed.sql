-- EXEC proc_set_date_range_btw_rfq_release_closed
CREATE PROCEDURE [dbo].[proc_set_date_range_btw_rfq_release_closed]
AS
BEGIN
	
	

	DROP TABLE IF EXISTS #tmp_mp_rfq_release_closed_date_range

	SELECT a.* , b.RFQDateRange INTO #tmp_mp_rfq_release_closed_date_range
	FROM
	(
		SELECT DISTINCT  a.rfq_id RFQId, FirstReleaseDate , CONVERT(DATE,Quotes_needed_by) ClosedDate
		FROM mp_rfq a (NOLOCK)
		JOIN 
		(	
			SELECT rfq_id , MIN(CONVERT(DATE,status_date)) FirstReleaseDate
			FROM mp_rfq_release_history  (NOLOCK)
			GROUP BY rfq_id
		) b ON a.rfq_id = b.rfq_id
		
		WHERE a.rfq_id NOT IN
		(
			SELECT b.rfq_id
			FROM mp_contacts a (NOLOCK) 
			join mp_rfq b (nolock) on a.contact_id = b.contact_id 
			WHERE user_id IN 
			(

				SELECT id FROM aspnetusers WHERE 
				email LIKE '%info@battleandbrew.com%'
				OR email LIKE '%rhollis@mfg.com%'
				OR email LIKE '%billtestermfg@gmail.com%'
				OR email LIKE '%adam@attractful.com%'
				OR email LIKE '%testsu%'
				OR email LIKE '%testbuyer@yopmail.com%'
			) 
		)
	) a
	CROSS APPLY (SELECT * FROM [dbo].[fn_get_datesrange](a.RFQId, a.FirstReleaseDate,a.ClosedDate) ) b


	INSERT INTO mp_rfq_release_closed_date_range (RFQId,FirstReleaseDate,ClosedDate,RFQDateRange)
	SELECT a.*
	FROM #tmp_mp_rfq_release_closed_date_range a 
	LEFT JOIN mp_rfq_release_closed_date_range b (NOLOCK) ON a.RFQId = b.RFQId
	WHERE b.RFQDateRange IS NULL


	UPDATE a SET a.UniqueSuppliers = b.UniqueSuppliers
	FROM mp_rfq_release_closed_date_range a (NOLOCK)
	LEFT JOIN 
	(
		SELECT rfq_id AS RFQId , COUNT(DISTINCT contact_id) AS UniqueSuppliers
		FROM mp_rfq_quote_supplierquote (NOLOCK)
		WHERE is_quote_submitted = 1 AND is_rfq_resubmitted = 0
		GROUP BY rfq_id
	) b ON a.RFQId = b.RFQId 
	WHERE a.UniqueSuppliers <> ISNULL(b.UniqueSuppliers,0)


END