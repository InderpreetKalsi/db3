CREATE TABLE [dbo].[mp_qms_contacts] (
    [qms_contact_id] INT           IDENTITY (1, 1) NOT NULL,
    [supplier_id]    INT           NOT NULL,
    [company]        VARCHAR (250) NULL,
    [first_name]     VARCHAR (100) NULL,
    [last_name]      VARCHAR (100) NULL,
    [email]          VARCHAR (100) NULL,
    [phone]          VARCHAR (100) NULL,
    [address]        VARCHAR (250) NULL,
    [city]           VARCHAR (100) NULL,
    [state_id]       INT           NULL,
    [country_id]     INT           NULL,
    [zip_code]       VARCHAR (50)  NULL,
    [is_active]      BIT           DEFAULT ((1)) NOT NULL,
    [created_date]   DATETIME      DEFAULT (getutcdate()) NOT NULL,
    [state]          VARCHAR (250) NULL,
    [country]        VARCHAR (250) NULL,
    [is_import]      BIT           DEFAULT ((0)) NULL,
    CONSTRAINT [pk_mp_qms_contacts] PRIMARY KEY CLUSTERED ([qms_contact_id] ASC) WITH (FILLFACTOR = 90)
);

