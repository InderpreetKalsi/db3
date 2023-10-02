CREATE TABLE [dbo].[mp_company_subscription_renewal_statuses] (
    [company_subscription_renewal] INT           IDENTITY (1, 1) NOT NULL,
    [company_id]                   INT           NOT NULL,
    [due_date]                     DATE          NULL,
    [status]                       VARCHAR (500) NULL,
    [is_closed]                    BIT           DEFAULT ((0)) NULL,
    [closed_date]                  DATE          NULL,
    PRIMARY KEY CLUSTERED ([company_subscription_renewal] ASC) WITH (FILLFACTOR = 90)
);

