CREATE TABLE [dbo].[tmp_SQLJob_Quote_RFQData] (
    [rfq_id]                 INT             NOT NULL,
    [rfq_name]               NVARCHAR (100)  NULL,
    [quote_expiry_date]      DATETIME        NULL,
    [company_id]             INT             NOT NULL,
    [CompanyName]            NVARCHAR (150)  NULL,
    [Grand_Total]            NUMERIC (38, 2) NULL,
    [quote_reference_number] VARCHAR (100)   NULL,
    [Billing_Street]         NVARCHAR (1532) NOT NULL,
    [Billing_City]           NVARCHAR (510)  NULL,
    [Billing_State]          NVARCHAR (200)  NOT NULL,
    [Billing_Country]        NVARCHAR (50)   NOT NULL,
    [Billing_Code]           VARCHAR (1)     NOT NULL
);

