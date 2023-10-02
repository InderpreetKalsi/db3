CREATE TABLE [dbo].[mp_rfq_cloned_logs] (
    [rfq_clone_history_id] INT IDENTITY (1, 1) NOT NULL,
    [parent_rfq_id]        INT NOT NULL,
    [cloned_rfq_id]        INT NOT NULL,
    PRIMARY KEY CLUSTERED ([rfq_clone_history_id] ASC, [parent_rfq_id] ASC, [cloned_rfq_id] ASC) WITH (FILLFACTOR = 90)
);

