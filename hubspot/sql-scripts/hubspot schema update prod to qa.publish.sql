﻿/*
Deployment script for DataSync_MarketplaceHubSpot

This code was generated by a tool.
Changes to this file may cause incorrect behavior and will be lost if
the code is regenerated.
*/

GO
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, CONCAT_NULL_YIELDS_NULL, QUOTED_IDENTIFIER ON;

SET NUMERIC_ROUNDABORT OFF;


GO
:setvar DatabaseName "DataSync_MarketplaceHubSpot"
:setvar DefaultFilePrefix "DataSync_MarketplaceHubSpot"
:setvar DefaultDataPath "C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\"
:setvar DefaultLogPath "C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\"

GO
:on error exit
GO
/*
Detect SQLCMD mode and disable script execution if SQLCMD mode is not supported.
To re-enable the script after enabling SQLCMD mode, execute the following:
SET NOEXEC OFF; 
*/
:setvar __IsSqlCmdEnabled "True"
GO
IF N'$(__IsSqlCmdEnabled)' NOT LIKE N'True'
    BEGIN
        PRINT N'SQLCMD mode must be enabled to successfully execute this script.';
        SET NOEXEC ON;
    END


GO
USE [$(DatabaseName)];


GO
IF EXISTS (SELECT 1
           FROM   [master].[dbo].[sysdatabases]
           WHERE  [name] = N'$(DatabaseName)')
    BEGIN
        ALTER DATABASE [$(DatabaseName)]
            SET ANSI_NULLS ON,
                ANSI_PADDING ON,
                ANSI_WARNINGS ON,
                ARITHABORT ON,
                CONCAT_NULL_YIELDS_NULL ON,
                QUOTED_IDENTIFIER ON,
                ANSI_NULL_DEFAULT ON,
                CURSOR_DEFAULT LOCAL,
                RECOVERY FULL 
            WITH ROLLBACK IMMEDIATE;
    END


GO
IF EXISTS (SELECT 1
           FROM   [master].[dbo].[sysdatabases]
           WHERE  [name] = N'$(DatabaseName)')
    BEGIN
        ALTER DATABASE [$(DatabaseName)]
            SET PAGE_VERIFY NONE 
            WITH ROLLBACK IMMEDIATE;
    END


GO
ALTER DATABASE [$(DatabaseName)]
    SET TARGET_RECOVERY_TIME = 0 SECONDS 
    WITH ROLLBACK IMMEDIATE;


GO
IF EXISTS (SELECT 1
           FROM   [master].[dbo].[sysdatabases]
           WHERE  [name] = N'$(DatabaseName)')
    BEGIN
        ALTER DATABASE [$(DatabaseName)]
            SET QUERY_STORE (CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 367)) 
            WITH ROLLBACK IMMEDIATE;
    END


GO
/*
The type for column Number of Employees Text in table [dbo].[HubSpotCompanies] is currently  NVARCHAR (200) NULL but is being changed to  NVARCHAR (100) NULL. Data loss could occur and deployment may fail if the column contains data that is incompatible with type  NVARCHAR (100) NULL.
*/

IF EXISTS (select top 1 1 from [dbo].[HubSpotCompanies])
    RAISERROR (N'Rows were detected. The schema update is terminating because data loss might occur.', 16, 127) WITH NOWAIT

GO
/*
The column [dbo].[HubSpotContacts].[Stripe Customer ID] is being dropped, data loss could occur.
*/

IF EXISTS (select top 1 1 from [dbo].[HubSpotContacts])
    RAISERROR (N'Rows were detected. The schema update is terminating because data loss might occur.', 16, 127) WITH NOWAIT

GO
PRINT N'Dropping Index [dbo].[HubSpotCompanies].[IX_HubSpotCompanies_Email]...';


GO
DROP INDEX [IX_HubSpotCompanies_Email]
    ON [dbo].[HubSpotCompanies];


GO
PRINT N'Dropping Default Constraint unnamed constraint on [dbo].[HubSpotCompanies]...';


GO
ALTER TABLE [dbo].[HubSpotCompanies] DROP CONSTRAINT [DF__HubSpotCo__IsSyn__4E5E8EA2];


GO
PRINT N'Dropping Default Constraint unnamed constraint on [dbo].[HubSpotCompanies]...';


GO
ALTER TABLE [dbo].[HubSpotCompanies] DROP CONSTRAINT [DF__HubSpotCo__IsPro__4F52B2DB];


GO
PRINT N'Creating User [mfg_prod]...';


GO
CREATE USER [mfg_prod] FOR LOGIN [mfg_prod];


GO
REVOKE CONNECT TO [mfg_prod];


GO
PRINT N'Creating User [mfg_rpt_user]...';


GO
CREATE USER [mfg_rpt_user] FOR LOGIN [mfg_rpt_user];


GO
REVOKE CONNECT TO [mfg_rpt_user];


GO
PRINT N'Creating Role Membership <unnamed>...';


GO
EXECUTE sp_addrolemember @rolename = N'db_datareader', @membername = N'mfg_rpt_user';


GO
PRINT N'Creating Role Membership <unnamed>...';


GO
EXECUTE sp_addrolemember @rolename = N'db_owner', @membername = N'mfg_prod';


GO
PRINT N'Starting rebuilding table [dbo].[HubSpotCompanies]...';


GO
BEGIN TRANSACTION;

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SET XACT_ABORT ON;

CREATE TABLE [dbo].[tmp_ms_xx_HubSpotCompanies] (
    [Id]                             INT            IDENTITY (1000, 1) NOT NULL,
    [Vision Account Id]              INT            NULL,
    [HubSpot Account Id]             VARCHAR (255)  NULL,
    [IsBuyerAccount]                 BIT            NULL,
    [Account Paid Status]            VARCHAR (255)  NULL,
    [Buyer Company City]             VARCHAR (255)  NULL,
    [Buyer Company Country]          VARCHAR (255)  NULL,
    [Buyer Company Phone]            VARCHAR (255)  NULL,
    [Buyer Company Postal Code]      VARCHAR (255)  NULL,
    [Buyer Company State]            VARCHAR (255)  NULL,
    [Buyer Company Street Address]   VARCHAR (255)  NULL,
    [Buyer Company Street Address 2] VARCHAR (255)  NULL,
    [Cage Code]                      VARCHAR (255)  NULL,
    [City]                           VARCHAR (255)  NULL,
    [Company Name]                   VARCHAR (255)  NULL,
    [Company Owner Id]               INT            NULL,
    [Country/Region]                 VARCHAR (255)  NULL,
    [Create Date]                    DATETIME       NULL,
    [Customer Service Rep Id]        INT            NULL,
    [Discipline Level 0]             VARCHAR (2000) NULL,
    [Discipline Level 1]             VARCHAR (2000) NULL,
    [Duns Number]                    VARCHAR (255)  NULL,
    [Facebook Company Page]          VARCHAR (255)  NULL,
    [Google Plus Page]               VARCHAR (255)  NULL,
    [Hide Directory Profile]         BIT            NULL,
    [Industry]                       VARCHAR (1000) NULL,
    [LinkedIn Company Page]          VARCHAR (255)  NULL,
    [Number of Employees]            INT            NULL,
    [Phone Number]                   VARCHAR (255)  NULL,
    [Postal Code]                    VARCHAR (255)  NULL,
    [Public Profile URL]             VARCHAR (1000) NULL,
    [RFQ Access Capabilities 0]      VARCHAR (2000) NULL,
    [RFQ Access Capabilities 1]      VARCHAR (2000) NULL,
    [State/Region]                   VARCHAR (255)  NULL,
    [Street Address]                 VARCHAR (255)  NULL,
    [Street Address 2]               VARCHAR (255)  NULL,
    [Manufacturing Location]         VARCHAR (100)  NULL,
    [Twitter Handle]                 VARCHAR (255)  NULL,
    [IsSynced]                       BIT            DEFAULT ((0)) NULL,
    [SyncedDate]                     DATETIME       NULL,
    [SyncedDateIST]                  DATETIME       NULL,
    [IsProcessed]                    BIT            DEFAULT (NULL) NULL,
    [ProcessedDate]                  DATETIME       NULL,
    [ProcessedDateIST]               DATETIME       NULL,
    [SyncType]                       TINYINT        NULL,
    [IsEligibleForGrowthPackage]     BIT            NULL,
    [RecordType]                     VARCHAR (100)  NULL,
    [Number of Employees Text]       NVARCHAR (100) NULL,
    [IsProfilePublished]             BIT            NULL,
    [Supplier Purchased Processes]   VARCHAR (MAX)  NULL,
    [tmpIsSynced]                    BIT            NULL,
    [tmpIsProcessed]                 BIT            NULL,
    [Is Test Company]                BIT            NULL,
    CONSTRAINT [tmp_ms_xx_constraint_Pk_HubSpotCompanies_Id1] PRIMARY KEY CLUSTERED ([Id] ASC)
);

IF EXISTS (SELECT TOP 1 1 
           FROM   [dbo].[HubSpotCompanies])
    BEGIN
        SET IDENTITY_INSERT [dbo].[tmp_ms_xx_HubSpotCompanies] ON;
        INSERT INTO [dbo].[tmp_ms_xx_HubSpotCompanies] ([Id], [Vision Account Id], [HubSpot Account Id], [IsBuyerAccount], [Account Paid Status], [Buyer Company City], [Buyer Company Country], [Buyer Company Phone], [Buyer Company Postal Code], [Buyer Company State], [Buyer Company Street Address], [Buyer Company Street Address 2], [Cage Code], [City], [Company Name], [Company Owner Id], [Country/Region], [Create Date], [Customer Service Rep Id], [Discipline Level 0], [Discipline Level 1], [Duns Number], [Facebook Company Page], [Google Plus Page], [Hide Directory Profile], [Industry], [LinkedIn Company Page], [Phone Number], [Postal Code], [Public Profile URL], [RFQ Access Capabilities 0], [RFQ Access Capabilities 1], [State/Region], [Street Address], [Street Address 2], [Manufacturing Location], [Twitter Handle], [IsSynced], [SyncedDate], [SyncedDateIST], [IsProcessed], [ProcessedDate], [ProcessedDateIST], [SyncType], [IsEligibleForGrowthPackage], [RecordType], [Number of Employees Text], [Number of Employees], [IsProfilePublished])
        SELECT   [Id],
                 [Vision Account Id],
                 [HubSpot Account Id],
                 [IsBuyerAccount],
                 [Account Paid Status],
                 [Buyer Company City],
                 [Buyer Company Country],
                 [Buyer Company Phone],
                 [Buyer Company Postal Code],
                 [Buyer Company State],
                 [Buyer Company Street Address],
                 [Buyer Company Street Address 2],
                 [Cage Code],
                 [City],
                 [Company Name],
                 [Company Owner Id],
                 [Country/Region],
                 [Create Date],
                 [Customer Service Rep Id],
                 [Discipline Level 0],
                 [Discipline Level 1],
                 [Duns Number],
                 [Facebook Company Page],
                 [Google Plus Page],
                 [Hide Directory Profile],
                 [Industry],
                 [LinkedIn Company Page],
                 [Phone Number],
                 [Postal Code],
                 [Public Profile URL],
                 [RFQ Access Capabilities 0],
                 [RFQ Access Capabilities 1],
                 [State/Region],
                 [Street Address],
                 [Street Address 2],
                 [Manufacturing Location],
                 [Twitter Handle],
                 [IsSynced],
                 [SyncedDate],
                 [SyncedDateIST],
                 [IsProcessed],
                 [ProcessedDate],
                 [ProcessedDateIST],
                 [SyncType],
                 [IsEligibleForGrowthPackage],
                 [RecordType],
                 [Number of Employees Text],
                 [Number of Employees],
                 [IsProfilePublished]
        FROM     [dbo].[HubSpotCompanies]
        ORDER BY [Id] ASC;
        SET IDENTITY_INSERT [dbo].[tmp_ms_xx_HubSpotCompanies] OFF;
    END

DROP TABLE [dbo].[HubSpotCompanies];

EXECUTE sp_rename N'[dbo].[tmp_ms_xx_HubSpotCompanies]', N'HubSpotCompanies';

EXECUTE sp_rename N'[dbo].[tmp_ms_xx_constraint_Pk_HubSpotCompanies_Id1]', N'Pk_HubSpotCompanies_Id', N'OBJECT';

COMMIT TRANSACTION;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;


GO
PRINT N'Altering Table [dbo].[HubSpotContacts]...';


GO
ALTER TABLE [dbo].[HubSpotContacts] DROP COLUMN [Stripe Customer ID];


GO
ALTER TABLE [dbo].[HubSpotContacts]
    ADD [Is Test Contact] BIT NULL;


GO
PRINT N'Altering Table [dbo].[HubSpotRFQs]...';


GO
ALTER TABLE [dbo].[HubSpotRFQs] ALTER COLUMN [Rfq Name] NVARCHAR (MAX) NULL;

ALTER TABLE [dbo].[HubSpotRFQs] ALTER COLUMN [Rfq Quote Link] VARCHAR (2000) NULL;


GO
PRINT N'Creating Table [dbo].[b2]...';


GO
CREATE TABLE [dbo].[b2] (
    [column1] NVARCHAR (50)   NULL,
    [column2] NVARCHAR (1000) NULL
);


GO
PRINT N'Creating Table [dbo].[bk_hubspotcompanies_16_may_2023]...';


GO
CREATE TABLE [dbo].[bk_hubspotcompanies_16_may_2023] (
    [Id]                             INT            IDENTITY (1000, 1) NOT NULL,
    [Vision Account Id]              INT            NULL,
    [HubSpot Account Id]             VARCHAR (255)  NULL,
    [IsBuyerAccount]                 BIT            NULL,
    [Account Paid Status]            VARCHAR (255)  NULL,
    [Buyer Company City]             VARCHAR (255)  NULL,
    [Buyer Company Country]          VARCHAR (255)  NULL,
    [Buyer Company Phone]            VARCHAR (255)  NULL,
    [Buyer Company Postal Code]      VARCHAR (255)  NULL,
    [Buyer Company State]            VARCHAR (255)  NULL,
    [Buyer Company Street Address]   VARCHAR (255)  NULL,
    [Buyer Company Street Address 2] VARCHAR (255)  NULL,
    [Cage Code]                      VARCHAR (255)  NULL,
    [City]                           VARCHAR (255)  NULL,
    [Company Name]                   VARCHAR (255)  NULL,
    [Company Owner Id]               INT            NULL,
    [Country/Region]                 VARCHAR (255)  NULL,
    [Create Date]                    DATETIME       NULL,
    [Customer Service Rep Id]        INT            NULL,
    [Discipline Level 0]             VARCHAR (2000) NULL,
    [Discipline Level 1]             VARCHAR (2000) NULL,
    [Duns Number]                    VARCHAR (255)  NULL,
    [Facebook Company Page]          VARCHAR (255)  NULL,
    [Google Plus Page]               VARCHAR (255)  NULL,
    [Hide Directory Profile]         BIT            NULL,
    [Industry]                       VARCHAR (1000) NULL,
    [LinkedIn Company Page]          VARCHAR (255)  NULL,
    [Number of Employees]            INT            NULL,
    [Phone Number]                   VARCHAR (255)  NULL,
    [Postal Code]                    VARCHAR (255)  NULL,
    [Public Profile URL]             VARCHAR (1000) NULL,
    [RFQ Access Capabilities 0]      VARCHAR (2000) NULL,
    [RFQ Access Capabilities 1]      VARCHAR (2000) NULL,
    [State/Region]                   VARCHAR (255)  NULL,
    [Street Address]                 VARCHAR (255)  NULL,
    [Street Address 2]               VARCHAR (255)  NULL,
    [Manufacturing Location]         VARCHAR (100)  NULL,
    [Twitter Handle]                 VARCHAR (255)  NULL,
    [IsSynced]                       BIT            NULL,
    [SyncedDate]                     DATETIME       NULL,
    [SyncedDateIST]                  DATETIME       NULL,
    [IsProcessed]                    BIT            NULL,
    [ProcessedDate]                  DATETIME       NULL,
    [ProcessedDateIST]               DATETIME       NULL,
    [SyncType]                       TINYINT        NULL,
    [IsEligibleForGrowthPackage]     BIT            NULL,
    [RecordType]                     VARCHAR (100)  NULL
);


GO
PRINT N'Creating Table [dbo].[hubspot_sync_logs]...';


GO
CREATE TABLE [dbo].[hubspot_sync_logs] (
    [sync_log_id]                      INT      IDENTITY (1, 1) NOT NULL,
    [hubspot_module_id]                INT      NOT NULL,
    [sync_date_time]                   DATETIME NULL,
    [SyncType]                         INT      NULL,
    [OperationType]                    INT      NULL,
    [sync_date_time_IST]               DATETIME NULL,
    [sync_unix_timestamp_milliseconds] BIGINT   NULL,
    CONSTRAINT [PK_hubspot_sync_logs] PRIMARY KEY CLUSTERED ([sync_log_id] ASC) WITH (FILLFACTOR = 80)
);


GO
PRINT N'Creating Table [dbo].[HubSpotAllEmails_20220225]...';


GO
CREATE TABLE [dbo].[HubSpotAllEmails_20220225] (
    [Email] NVARCHAR (255) NULL
);


GO
PRINT N'Creating Table [dbo].[HubSpotContactsCreatedOrUpdatedLogs]...';


GO
CREATE TABLE [dbo].[HubSpotContactsCreatedOrUpdatedLogs] (
    [ID]                           INT           IDENTITY (1, 1) NOT NULL,
    [HubSpotContactsIdentityKeyId] INT           NULL,
    [HubSpotContactId]             VARCHAR (255) NULL,
    [IsProcessed]                  BIT           NULL,
    [IsSynced]                     BIT           NULL,
    [ProcessedDate]                DATETIME      NULL,
    [SyncedDate]                   DATETIME      NULL,
    [CreatedDate]                  DATETIME      NULL,
    [TransactionStatus]            INT           NULL,
    [ErrorMessages]                VARCHAR (MAX) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
PRINT N'Creating Table [dbo].[HubSpotContactsOneTimePull_Dec232021]...';


GO
CREATE TABLE [dbo].[HubSpotContactsOneTimePull_Dec232021] (
    [Id]                INT           IDENTITY (100, 1) NOT NULL,
    [Email]             VARCHAR (500) NULL,
    [HubSpot ContactId] VARCHAR (255) NULL
);


GO
PRINT N'Creating Table [dbo].[HubSpotErrorLogPushCompanies]...';


GO
CREATE TABLE [dbo].[HubSpotErrorLogPushCompanies] (
    [Id]                INT            IDENTITY (100, 1) NOT NULL,
    [PushType]          VARCHAR (50)   NULL,
    [Vision Company Id] INT            NULL,
    [Error]             VARCHAR (2000) NULL,
    [ErrorDate]         DATETIME       NULL,
    CONSTRAINT [Pk_HubSpotErrorLogPushCompanies_Id] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
PRINT N'Creating Index [dbo].[HubSpotErrorLogPushCompanies].[IX_HubSpotErrorLogPushCompanies_Vision_Company_Id]...';


GO
CREATE NONCLUSTERED INDEX [IX_HubSpotErrorLogPushCompanies_Vision_Company_Id]
    ON [dbo].[HubSpotErrorLogPushCompanies]([Vision Company Id] ASC, [PushType] ASC);


GO
PRINT N'Creating Table [dbo].[HubSpotErrorLogPushContacts]...';


GO
CREATE TABLE [dbo].[HubSpotErrorLogPushContacts] (
    [Id]                INT            IDENTITY (100, 1) NOT NULL,
    [PushType]          VARCHAR (50)   NULL,
    [Vision Contact Id] INT            NULL,
    [Error]             VARCHAR (2000) NULL,
    [ErrorDate]         DATETIME       NULL,
    CONSTRAINT [Pk_HubSpotErrorLogPushContacts_Id] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
PRINT N'Creating Index [dbo].[HubSpotErrorLogPushContacts].[IX_HubSpotErrorLogPushContacts_Vision_Contact_Id]...';


GO
CREATE NONCLUSTERED INDEX [IX_HubSpotErrorLogPushContacts_Vision_Contact_Id]
    ON [dbo].[HubSpotErrorLogPushContacts]([Vision Contact Id] ASC, [PushType] ASC);


GO
PRINT N'Creating Table [dbo].[HubSpotRFQs_rk]...';


GO
CREATE TABLE [dbo].[HubSpotRFQs_rk] (
    [Id]                   INT            IDENTITY (1, 1) NOT NULL,
    [Rfq Number]           VARCHAR (255)  NULL,
    [Rfq Name]             VARCHAR (255)  NULL,
    [Rfq Description]      NVARCHAR (MAX) NULL,
    [Vision Link]          VARCHAR (100)  NULL,
    [MFG Legacy Rfq Id]    INT            NULL,
    [Modified Date]        DATETIME       NULL,
    [Created Date]         DATETIME       NULL,
    [SyncType]             TINYINT        NULL,
    [IsSynced]             BIT            NULL,
    [Buyer Id]             BIGINT         NULL,
    [Buyer Name]           NVARCHAR (MAX) NULL,
    [Rfq Close Date]       DATETIME       NULL,
    [MFG Discipline]       NVARCHAR (MAX) NULL,
    [MFG 2nd Discipline]   NVARCHAR (MAX) NULL,
    [Assigned Engineer]    NVARCHAR (MAX) NULL,
    [RFQ Status]           INT            NULL,
    [Rfq Release Date]     DATETIME       NULL,
    [Part Count]           INT            NULL,
    [Region]               INT            NULL,
    [Number Of Quotes]     INT            NULL,
    [Quote Summary Link]   NVARCHAR (MAX) NULL,
    [IsDeleted]            BIT            NULL,
    [MFG 1st Discipline]   NVARCHAR (MAX) NULL,
    [Rfq Buyer Status Id]  INT            NULL,
    [Rfq User Status Id]   INT            NULL,
    [IsProcessed]          BIT            NULL,
    [SyncedDate]           DATETIME       NULL,
    [ProcessedDate]        DATETIME       NULL,
    [Rfq Materials]        VARCHAR (2000) NULL,
    [Is Mfg Community Rfq] BIT            NULL,
    [HubSpot Rfq Id]       VARCHAR (255)  NULL,
    CONSTRAINT [PK_HubSpotRFQs_rk] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (FILLFACTOR = 80)
);


GO
PRINT N'Creating Table [dbo].[HubSpotUpSyncAPIRequestResponseLogs]...';


GO
CREATE TABLE [dbo].[HubSpotUpSyncAPIRequestResponseLogs] (
    [Id]                           INT            IDENTITY (1, 1) NOT NULL,
    [HubSpotModuleType]            VARCHAR (100)  NULL,
    [OperationType]                VARCHAR (100)  NULL,
    [Email]                        NVARCHAR (500) NULL,
    [VisionAccountId]              INT            NULL,
    [RfqId]                        INT            NULL,
    [HubSpotAPIRequestURL]         NVARCHAR (MAX) NULL,
    [HubSpotAPIRequestJSON]        NVARCHAR (MAX) NULL,
    [HubSpotAPIResponseJSON]       NVARCHAR (MAX) NULL,
    [HubSpotAPIResponseStatusCode] VARCHAR (100)  NULL,
    [CreateDate]                   DATETIME       NULL,
    [IsSuccess]                    BIT            NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO
PRINT N'Creating Table [dbo].[mst_discipline_level0]...';


GO
CREATE TABLE [dbo].[mst_discipline_level0] (
    [disciplineId]    INT            IDENTITY (1, 1) NOT NULL,
    [discipline_name] NVARCHAR (500) NULL,
    [discipline_code] NVARCHAR (500) NULL,
    [discipline_desc] NVARCHAR (500) NULL
);


GO
PRINT N'Creating Table [dbo].[mst_discipline_level1]...';


GO
CREATE TABLE [dbo].[mst_discipline_level1] (
    [disciplineId]    INT            IDENTITY (1, 1) NOT NULL,
    [discipline_name] NVARCHAR (500) NULL
);


GO
PRINT N'Creating Table [dbo].[mst_manager_bk_duplicate_records]...';


GO
CREATE TABLE [dbo].[mst_manager_bk_duplicate_records] (
    [manager_id]      INT           NOT NULL,
    [manager_name]    VARCHAR (100) NULL,
    [is_active]       BIT           NULL,
    [zoho_id]         BIGINT        NULL,
    [hubspot_user_id] BIGINT        NULL
);


GO
PRINT N'Creating Table [dbo].[mst_manufacturing_location]...';


GO
CREATE TABLE [dbo].[mst_manufacturing_location] (
    [locationId]             INT            IDENTITY (1, 1) NOT NULL,
    [manufacturing_location] NVARCHAR (500) NULL
);


GO
PRINT N'Creating Table [dbo].[''portal 7872785$'']...';


GO
CREATE TABLE [dbo].['portal 7872785$'] (
    [User ID]     FLOAT (53)     NULL,
    [First Name]  NVARCHAR (255) NULL,
    [Last Name]   NVARCHAR (255) NULL,
    [Email]       NVARCHAR (255) NULL,
    [Last Login]  NVARCHAR (255) NULL,
    [Teams]       NVARCHAR (255) NULL,
    [Role]        NVARCHAR (255) NULL,
    [Permissions] NVARCHAR (MAX) NULL
);


GO
PRINT N'Creating Table [dbo].[t1]...';


GO
CREATE TABLE [dbo].[t1] (
    [Contact ID] NVARCHAR (255) NULL,
    [Email]      NVARCHAR (255) NULL
);


GO
PRINT N'Creating Default Constraint unnamed constraint on [dbo].[HubSpotContactsCreatedOrUpdatedLogs]...';


GO
ALTER TABLE [dbo].[HubSpotContactsCreatedOrUpdatedLogs]
    ADD DEFAULT (getutcdate()) FOR [CreatedDate];


GO
PRINT N'Creating Default Constraint unnamed constraint on [dbo].[HubSpotContactsCreatedOrUpdatedLogs]...';


GO
ALTER TABLE [dbo].[HubSpotContactsCreatedOrUpdatedLogs]
    ADD DEFAULT ((0)) FOR [TransactionStatus];


GO
PRINT N'Creating Default Constraint unnamed constraint on [dbo].[HubSpotErrorLogPushCompanies]...';


GO
ALTER TABLE [dbo].[HubSpotErrorLogPushCompanies]
    ADD DEFAULT (getutcdate()) FOR [ErrorDate];


GO
PRINT N'Creating Default Constraint unnamed constraint on [dbo].[HubSpotErrorLogPushContacts]...';


GO
ALTER TABLE [dbo].[HubSpotErrorLogPushContacts]
    ADD DEFAULT (getutcdate()) FOR [ErrorDate];


GO
PRINT N'Creating Default Constraint unnamed constraint on [dbo].[HubSpotUpSyncAPIRequestResponseLogs]...';


GO
ALTER TABLE [dbo].[HubSpotUpSyncAPIRequestResponseLogs]
    ADD DEFAULT (getutcdate()) FOR [CreateDate];


GO
PRINT N'Creating Procedure [dbo].[proc_set_HubSpotContactsCreatedOrUpdatedLogs]...';


GO
/*

EXEC proc_set_HubSpotContactsCreatedOrUpdatedLogs
    @HubSpotContactsIdentityKeyId = 2030
	,@HubSpotContactId = '16940694668'
	,@IsProcessed = 1
	,@IsSynced = 1
	,@ProcessedDate = '2023-08-17 08:13:34.487'
	,@SyncedDate = '2023-08-17 08:13:34.487'

hubspotcontactscreatedorupdatedlogs -> TransactionStatus -> 0 - Insert
															1 - Update


*/
  
 
CREATE PROCEDURE [dbo].[proc_set_HubSpotContactsCreatedOrUpdatedLogs]
(
	@HubSpotContactsIdentityKeyId	INT 
	,@HubSpotContactId VARCHAR(255) = NULL
	,@IsProcessed	  BIT 			
	,@IsSynced		  BIT 			
	,@ProcessedDate   DATETIME  
	,@SyncedDate      DATETIME = NULL
)
AS
BEGIN

DECLARE @identity bigint = 0

BEGIN TRY
----- insert record into log table
		INSERT INTO hubspotcontactscreatedorupdatedlogs
					(
					 hubspotcontactsidentitykeyid,
					 hubspotcontactid,
					 isprocessed,
					 issynced,
					 processeddate,
					 synceddate
					 )
		VALUES      (
		             @HubSpotContactsIdentityKeyId,
					 @HubSpotContactId,
					 @IsProcessed,
					 @IsSynced,
					 @ProcessedDate,
					 @SyncedDate
					 ) 

		SET @identity = @@identity

	BEGIN TRANSACTION
	
		IF @identity > 0
		BEGIN
			----update HubSpotContacts 
			UPDATE HubSpotContacts
			SET [HubSpot Contact Id] = @HubSpotContactId
			,IsSynced                = @IsSynced
			,IsProcessed             = @IsProcessed
			,SyncedDate				 = @SyncedDate
			,ProcessedDate			 = @ProcessedDate
			WHERE Id                 = @HubSpotContactsIdentityKeyId

			IF (SELECT COUNT(1) FROM hubspotcontacts(NOLOCK) WHERE id  = @HubSpotContactsIdentityKeyId AND IsSynced = 1 AND IsProcessed = 1) > 0
			BEGIN
				---update hubspotcontactscreatedorupdatedlogs
				UPDATE hubspotcontactscreatedorupdatedlogs
				SET TransactionStatus = 1
				WHERE ID = @identity
			END

		END

	COMMIT TRANSACTION
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION
	THROW;
	----for tracking the which error getting
	UPDATE hubspotcontactscreatedorupdatedlogs
	SET ErrorMessages =  error_message()
	WHERE ID = @identity
	
	
END CATCH
END
GO
PRINT N'Creating Procedure [dbo].[proc_set_HubSpotContactsCreatedOrUpdatedLogs_bk_18_Aug_2023]...';


GO
/*

EXEC proc_set_HubSpotContactsCreatedOrUpdatedLogs
    @HubSpotContactsIdentityKeyId = 2030
	,@HubSpotContactId = '16940694668'
	,@IsProcessed = 1
	,@IsSynced = 1
	,@ProcessedDate = '2023-08-17 08:13:34.487'
	,@SyncedDate = '2023-08-17 08:13:34.487'

*/
 
 
 
CREATE PROCEDURE [dbo].[proc_set_HubSpotContactsCreatedOrUpdatedLogs_bk_18_Aug_2023]
(
	@HubSpotContactsIdentityKeyId	INT 
	,@HubSpotContactId VARCHAR(255) = NULL
	,@IsProcessed	  BIT 			
	,@IsSynced		  BIT 			
	,@ProcessedDate   DATETIME  
	,@SyncedDate      DATETIME = NULL
)
AS
BEGIN

	BEGIN TRANSACTION

		----- insert record into log table
		INSERT INTO hubspotcontactscreatedorupdatedlogs
					(
					 hubspotcontactsidentitykeyid,
					 hubspotcontactid,
					 isprocessed,
					 issynced,
					 processeddate,
					 synceddate
					 )
		VALUES      (
		             @HubSpotContactsIdentityKeyId,
					 @HubSpotContactId,
					 @IsProcessed,
					 @IsSynced,
					 @ProcessedDate,
					 @SyncedDate
					 ) 

		----update HubSpotContacts 
		UPDATE HubSpotContacts
		SET [HubSpot Contact Id] = @HubSpotContactId
		,IsSynced                = @IsSynced
		,IsProcessed             = @IsProcessed
		,SyncedDate				 = @SyncedDate
		,ProcessedDate			 = @ProcessedDate
		WHERE Id                 = @HubSpotContactsIdentityKeyId

	COMMIT TRANSACTION
	   	  
END
GO
PRINT N'Update complete.';


GO
