
CREATE VIEW [dbo].[vwRptSurveys] AS
SELECT 
	DISTINCT
	d.contact_id	AS Id
	,e.name		AS Company
	,d.first_name +' '+ d.last_name AS [User]
	,c.[key]	AS SurveyType
	,CONVERT(DATE,a.StartedDate) AS SurveyDate
	,CONVERT(VARCHAR,b.SurveyQuestionID -1) +'. '+ b.Title	AS Question
	,(CASE WHEN a.answerid LIKE '%OTHER%' THEN a.answer +' (Other)' ELSE a.answer END)	AS Answer
	--,f.territory_classification_name AS CompanyLocation
	--,a.answerid AS AId
	--,b.id		AS QId
FROM mp_survey_user_answerinfo	(NOLOCK) a
JOIN mp_mst_survey_questioninfo (NOLOCK) b ON a.surveyquestioninfoid = b.id AND a.answerid IS NOT NULL
JOIN mp_mst_surveyinfo			(NOLOCK) c ON b.surveyinfoid = c.id
JOIN mp_contacts				(NOLOCK) d ON a.userid = d.[user_id]  and d.IsTestAccount= 0
	AND d.is_buyer = (CASE WHEN c.[key] = 'BUYER-DASHBOARD' THEN 1 ELSE 0 END)
JOIN mp_companies				(NOLOCK) e ON d.company_id = e.company_id
JOIN mp_mst_territory_classification (NOLOCK) f ON e.manufacturing_location_id = f.territory_classification_id
