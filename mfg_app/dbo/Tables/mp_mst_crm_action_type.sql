CREATE TABLE [dbo].[mp_mst_crm_action_type] (
    [crm_action_type_id] INT           IDENTITY (1, 1) NOT NULL,
    [crm_action_type]    VARCHAR (100) NULL,
    [crm_action_type_en] VARCHAR (100) NULL,
    PRIMARY KEY CLUSTERED ([crm_action_type_id] ASC) WITH (FILLFACTOR = 90)
);

