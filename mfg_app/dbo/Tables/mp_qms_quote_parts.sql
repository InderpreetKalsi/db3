CREATE TABLE [dbo].[mp_qms_quote_parts] (
    [qms_quote_part_id]     INT            IDENTITY (1, 1) NOT NULL,
    [qms_quote_id]          INT            NOT NULL,
    [part_name]             VARCHAR (500)  NULL,
    [part_no]               VARCHAR (250)  NULL,
    [part_category_id]      INT            NULL,
    [post_production_id]    INT            NULL,
    [material_id]           INT            NULL,
    [description]           VARCHAR (1000) NULL,
    [status_id]             INT            NULL,
    [is_active]             BIT            DEFAULT ((1)) NOT NULL,
    [created_date]          DATETIME       DEFAULT (getutcdate()) NOT NULL,
    [modified_date]         DATETIME       NULL,
    [is_accepted]           BIT            NULL,
    [qms_part_status_id]    INT            DEFAULT ((13)) NULL,
    [is_apply_process]      BIT            NULL,
    [is_apply_material]     BIT            NULL,
    [is_apply_post_process] BIT            NULL,
    CONSTRAINT [pk_mp_qms_quote_parts_qms_quote_part_id] PRIMARY KEY CLUSTERED ([qms_quote_part_id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK__mp_qms_qu__qms_q__45832891] FOREIGN KEY ([qms_quote_id]) REFERENCES [dbo].[mp_qms_quotes] ([qms_quote_id])
);


GO
ALTER TABLE [dbo].[mp_qms_quote_parts] NOCHECK CONSTRAINT [FK__mp_qms_qu__qms_q__45832891];

