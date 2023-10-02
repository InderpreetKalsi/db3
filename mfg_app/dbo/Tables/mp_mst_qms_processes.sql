CREATE TABLE [dbo].[mp_mst_qms_processes] (
    [qms_process_id] INT           IDENTITY (101, 1) NOT NULL,
    [qms_process]    VARCHAR (500) NULL,
    [is_active]      BIT           DEFAULT ((1)) NULL,
    [created_on]     DATETIME      DEFAULT (getutcdate()) NULL,
    [modified_on]    DATETIME      NULL,
    [parent_id]      INT           NULL,
    PRIMARY KEY CLUSTERED ([qms_process_id] ASC) WITH (FILLFACTOR = 90)
);

