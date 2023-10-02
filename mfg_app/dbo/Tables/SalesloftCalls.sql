CREATE TABLE [dbo].[SalesloftCalls] (
    [salesloftcallsid] INT            IDENTITY (1, 1) NOT NULL,
    [id]               INT            NOT NULL,
    [to]               VARCHAR (500)  NULL,
    [duration]         INT            NULL,
    [sentiment]        VARCHAR (500)  NULL,
    [disposition]      VARCHAR (500)  NULL,
    [created_at]       DATETIME       NULL,
    [updated_at]       DATETIME       NULL,
    [recordings]       VARCHAR (1000) NULL,
    [user_id]          INT            NULL,
    [action_id]        INT            NULL,
    [called_person_id] INT            NULL,
    [crm_activity_id]  INT            NULL,
    [note_id]          INT            NULL,
    [cadence_id]       INT            NULL,
    [step_id]          INT            NULL,
    [is_processed]     BIT            NULL,
    CONSTRAINT [PK_SalesloftCalls_salesloftcallsid] PRIMARY KEY CLUSTERED ([salesloftcallsid] ASC)
);

