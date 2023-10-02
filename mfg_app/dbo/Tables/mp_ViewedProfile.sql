CREATE TABLE [dbo].[mp_ViewedProfile] (
    [ViewProfile_id]      INT      IDENTITY (1, 1) NOT NULL,
    [ContactId]           INT      NOT NULL,
    [CompanyID_Profile]   INT      NULL,
    [profile_viewed_date] DATETIME NULL,
    [contact_id_profile]  INT      NULL,
    CONSTRAINT [PK_mp_ViewedProfile] PRIMARY KEY CLUSTERED ([ViewProfile_id] ASC) WITH (FILLFACTOR = 90)
);

