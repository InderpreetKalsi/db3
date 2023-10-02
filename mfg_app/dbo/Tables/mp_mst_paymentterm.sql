CREATE TABLE [dbo].[mp_mst_paymentterm] (
    [paymentterm_id]  SMALLINT       IDENTITY (1, 1) NOT NULL,
    [paymentterm_key] NVARCHAR (100) NOT NULL,
    [description]     NVARCHAR (100) NOT NULL,
    [sort_number]     SMALLINT       NOT NULL,
    [days_count]      SMALLINT       DEFAULT ((-1)) NOT NULL,
    CONSTRAINT [PK_mp_mst_paymentterm] PRIMARY KEY CLUSTERED ([paymentterm_id] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'List of payment terms', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_mst_paymentterm';

