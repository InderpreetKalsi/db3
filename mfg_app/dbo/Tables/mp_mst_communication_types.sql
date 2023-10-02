CREATE TABLE [dbo].[mp_mst_communication_types] (
    [communication_type_id] SMALLINT     IDENTITY (1, 1) NOT NULL,
    [order_number]          SMALLINT     NOT NULL,
    [contact_type]          VARCHAR (25) NOT NULL,
    CONSTRAINT [PK_mp_mst_communication_types] PRIMARY KEY CLUSTERED ([communication_type_id] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'defined communication types like, Email, FAx, mobile etc...', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mp_mst_communication_types';

