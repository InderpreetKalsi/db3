CREATE TABLE [dbo].[mp_crm_notes] (
    [crm_notes_id]       INT            IDENTITY (1, 1) NOT NULL,
    [company_id]         INT            NULL,
    [contact_id]         INT            NULL,
    [crm_action_type_id] INT            NULL,
    [crm_notes_descr]    VARCHAR (150)  NULL,
    [crm_notes]          NVARCHAR (MAX) NULL,
    [crm_notes_date]     DATETIME       NULL,
    [is_hidden]          BIT            DEFAULT ((0)) NULL,
    PRIMARY KEY CLUSTERED ([crm_notes_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_mp_crm_notes_mp_mst_crm_action_type_crm_action_type_id] FOREIGN KEY ([crm_action_type_id]) REFERENCES [dbo].[mp_mst_crm_action_type] ([crm_action_type_id])
);

