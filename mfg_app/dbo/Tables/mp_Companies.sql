CREATE TABLE [dbo].[mp_Companies] (
    [company_id]                        INT            IDENTITY (1, 1) NOT NULL,
    [name]                              NVARCHAR (150) NULL,
    [description]                       NVARCHAR (MAX) NULL,
    [duns_number]                       NVARCHAR (50)  NULL,
    [employee_count_range_id]           SMALLINT       CONSTRAINT [DF__mp_Compan__emplo__3A4CA8FD] DEFAULT ((0)) NOT NULL,
    [is_active]                         BIT            CONSTRAINT [DF__mp_Compan__is_ac__498EEC8D] DEFAULT ((1)) NOT NULL,
    [SALES_STATUS_ID]                   SMALLINT       NULL,
    [company_tolerance_id]              SMALLINT       NULL,
    [cage_code]                         NVARCHAR (200) NULL,
    [created_date]                      DATETIME       NULL,
    [Assigned_SourcingAdvisor]          INT            NULL,
    [company_zoho_id]                   VARCHAR (200)  NULL,
    [CompanyURL]                        NVARCHAR (150) NULL,
    [Manufacturing_location_id]         INT            NULL,
    [is_mqs_enable]                     BIT            DEFAULT ((0)) NULL,
    [is_hide_directory_profile]         BIT            NULL,
    [is_magic_lead_enable]              BIT            DEFAULT ((1)) NULL,
    [max_quoting_capabilities_allowed]  SMALLINT       NULL,
    [max_quoting_capabilities_added_by] INT            NULL,
    [assigned_customer_rep]             INT            NULL,
    [ProfileStatus]                     SMALLINT       CONSTRAINT [DF_mp_companies_ProfileStatus] DEFAULT ((230)) NULL,
    [IsCreatedFromVision]               BIT            DEFAULT ((0)) NULL,
    [IsEligibleForGrowthPackage]        BIT            DEFAULT ((0)) NULL,
    [IsGrowthPackageTaken]              BIT            DEFAULT ((0)) NULL,
    [HubSpotCompanyId]                  VARCHAR (200)  NULL,
    [IsStarterPackageTaken]             BIT            NULL,
    [IsStarterFreeTrialTaken]           BIT            NULL,
    CONSTRAINT [PK_mp_Companies] PRIMARY KEY CLUSTERED ([company_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_Companies_To_mp_employees_count_range] FOREIGN KEY ([employee_count_range_id]) REFERENCES [dbo].[mp_mst_employees_count_range] ([employee_count_range_id])
);


GO
CREATE NONCLUSTERED INDEX [IX_mp_Companies_is_active_company_id]
    ON [dbo].[mp_Companies]([is_active] ASC, [company_id] ASC)
    INCLUDE([name]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [idx_mp_companies_Assigned_SourcingAdvisor]
    ON [dbo].[mp_Companies]([Assigned_SourcingAdvisor] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [Idx_mp_Companies_Manufacturing_location_id_company_id]
    ON [dbo].[mp_Companies]([Manufacturing_location_id] ASC, [company_id] ASC)
    INCLUDE([name], [created_date]) WITH (FILLFACTOR = 90);


GO

CREATE TRIGGER [dbo].[tr_update_compan_url]  ON  [dbo].[mp_companies]
AFTER INSERT
AS 
BEGIN
	
   	UPDATE a SET companyurl = 
	(
		REPLACE(REPLACE(REPLACE(dbo.removespecialchars(a.name),' ','_'),'__','_'),'___','_') 
		+'_'
		+(
			SELECT CONVERT(VARCHAR(100),COUNT(1)+1) 
			FROM mp_companies (NOLOCK) 
			WHERE companyurl LIKE  '' + REPLACE(REPLACE(REPLACE(dbo.removespecialchars(a.name),' ','_'),'__','_'),'___','_')  + '%')
	)
	FROM mp_companies a (NOLOCK)
	WHERE a.company_id  IN (SELECT company_id FROM Inserted)

END
GO

CREATE TRIGGER [dbo].[tr_update_IsEligibleForGrowthPackage]  ON  [dbo].[mp_Companies]
AFTER INSERT
AS 
BEGIN
	
	UPDATE mp_companies 
	SET IsEligibleForGrowthPackage = 1
	,IsGrowthPackageTaken = 0
	,IsStarterPackageTaken = 0
	,IsStarterFreeTrialTaken = 0
	WHERE company_id  IN (SELECT company_id FROM Inserted)
	AND employee_count_range_id = 1
	AND Manufacturing_location_id <> 3


END
