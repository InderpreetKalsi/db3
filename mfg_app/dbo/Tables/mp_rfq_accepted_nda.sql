CREATE TABLE [dbo].[mp_rfq_accepted_nda] (
    [rfq_accepted_nda_id] INT            IDENTITY (1, 1) NOT NULL,
    [rfq_id]              INT            NULL,
    [nda_content]         NVARCHAR (MAX) NULL,
    [creation_date]       DATETIME       NULL,
    [status_id]           INT            NULL,
    CONSTRAINT [PK_mp_rfq_accepted_nda] PRIMARY KEY CLUSTERED ([rfq_accepted_nda_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_rfq_accepted_nda_mp_rfq] FOREIGN KEY ([rfq_id]) REFERENCES [dbo].[mp_rfq] ([rfq_id])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'This table will fill when user select the "NDA Verbage"', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_rfq_accepted_nda';

