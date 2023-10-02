CREATE TABLE [dbo].[hubspot_crm_exports] (
    [Record_ID_Contact]             INT           NOT NULL,
    [First_Name]                    NVARCHAR (50) NOT NULL,
    [Last_Name]                     NVARCHAR (50) NULL,
    [Email]                         NVARCHAR (50) NOT NULL,
    [Account_Paid_Status]           NVARCHAR (50) NOT NULL,
    [Primary_Associated_Company_ID] FLOAT (53)    NULL,
    [Vision_Supplier_ID]            INT           NULL,
    [Growth_Package_Eligible]       NVARCHAR (50) NOT NULL,
    [Associated_Company]            NVARCHAR (50) NULL
);

