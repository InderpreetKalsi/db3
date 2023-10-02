CREATE TABLE [dbo].[mp_vision_action_tracker_tracking] (
    [id]              INT           IDENTITY (101, 1) NOT NULL,
    [action_taken_by] INT           NOT NULL,
    [action_source]   VARCHAR (150) NULL,
    [action_type]     VARCHAR (150) NULL,
    [contact_id]      INT           NOT NULL,
    [value]           INT           NULL,
    [is_marked]       BIT           DEFAULT ((0)) NULL,
    [action_taken_on] DATETIME      DEFAULT (getutcdate()) NULL,
    CONSTRAINT [pk_mp_vision_action_tracker_tracking_id_action_taken_by_contact_id] PRIMARY KEY CLUSTERED ([id] ASC, [action_taken_by] ASC, [contact_id] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [Idx_mp_vision_action_tracker_tracking_action_source_action_taken_on_action_type_value]
    ON [dbo].[mp_vision_action_tracker_tracking]([action_source] ASC, [action_taken_on] ASC)
    INCLUDE([action_type], [value]) WITH (FILLFACTOR = 90);

