CREATE TABLE [dbo].[mp_sendgrid_blocked_email_ids] (
    [blocked_email_id]      INT           IDENTITY (1, 1) NOT NULL,
    [email_id]              VARCHAR (500) NULL,
    [sendgrid_blocked_date] DATETIME      NULL,
    [is_blocked]            BIT           DEFAULT ((0)) NULL,
    [list_type]             VARCHAR (250) NULL,
    [contact_id]            INT           NULL
);

