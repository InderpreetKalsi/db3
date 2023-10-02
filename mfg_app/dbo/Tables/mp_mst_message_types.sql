CREATE TABLE [dbo].[mp_mst_message_types] (
    [message_type_id]      SMALLINT       IDENTITY (1, 1) NOT NULL,
    [message_type_name]    VARCHAR (100)  NULL,
    [message_order]        INT            NULL,
    [message_hide]         BIT            NOT NULL,
    [buyer_use]            BIT            NOT NULL,
    [supplier_use]         BIT            NOT NULL,
    [message_type_name_en] NVARCHAR (150) NULL,
    [IsNotification]       BIT            DEFAULT ((1)) NULL,
    CONSTRAINT [PK_mp_mst_message_types] PRIMARY KEY CLUSTERED ([message_type_id] ASC) WITH (FILLFACTOR = 90)
);

