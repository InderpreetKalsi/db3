CREATE TABLE [dbo].[mp_subscr_account] (
    [subscr_account_id] INT             IDENTITY (1, 1) NOT NULL,
    [company_id]        INT             NOT NULL,
    [status_id]         SMALLINT        NOT NULL,
    [start_date]        SMALLDATETIME   NULL,
    [active]            SMALLINT        NOT NULL,
    [total_price]       NUMERIC (18, 3) NOT NULL,
    [extended_end_date] DATETIME        NULL,
    CONSTRAINT [PK_mp_subscr_account] PRIMARY KEY CLUSTERED ([subscr_account_id] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Account Identifier', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_subscr_account', @level2type = N'COLUMN', @level2name = N'subscr_account_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifier', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_subscr_account', @level2type = N'COLUMN', @level2name = N'company_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Status Identifier :
  1 draft
  2 - valid - contract proposal succeed (sold)
  8 - end - contract proposal closed manually.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_subscr_account', @level2type = N'COLUMN', @level2name = N'status_id';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Effective start date of the contract', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_subscr_account', @level2type = N'COLUMN', @level2name = N'start_date';

