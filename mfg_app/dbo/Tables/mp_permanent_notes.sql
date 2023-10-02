CREATE TABLE [dbo].[mp_permanent_notes] (
    [note_id]    INT            IDENTITY (1, 1) NOT NULL,
    [company_id] INT            NULL,
    [contact_id] INT            NULL,
    [notes]      NVARCHAR (MAX) NULL,
    [note_date]  DATETIME       DEFAULT (getdate()) NULL,
    [is_hidden]  BIT            DEFAULT ((0)) NULL,
    [is_latest]  BIT            DEFAULT ((1)) NULL,
    PRIMARY KEY CLUSTERED ([note_id] ASC) WITH (FILLFACTOR = 90)
);

