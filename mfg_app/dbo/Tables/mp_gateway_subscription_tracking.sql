CREATE TABLE [dbo].[mp_gateway_subscription_tracking] (
    [id]                              INT            IDENTITY (1001, 1) NOT NULL,
    [gateway_id]                      INT            NULL,
    [contact_id]                      INT            NOT NULL,
    [company_id]                      INT            NULL,
    [subscriptions_customer_id]       VARCHAR (250)  NULL,
    [subscriptions_plan]              VARCHAR (250)  NULL,
    [hosted_page_link]                VARCHAR (1000) NULL,
    [created]                         DATETIME       DEFAULT (getutcdate()) NULL,
    [subscription_id]                 INT            NULL,
    [update_subscription_card]        BIT            DEFAULT ((0)) NULL,
    [is_successful_transaction]       BIT            NULL,
    [successful_transaction_datetime] DATETIME       NULL,
    [subscriptions_addon]             VARCHAR (250)  NULL,
    [subscriptions_addon_quantity]    INT            NULL,
    CONSTRAINT [PK_mp_gateway_subscription_tracking_id_contact_id] PRIMARY KEY CLUSTERED ([id] ASC, [contact_id] ASC) WITH (FILLFACTOR = 90)
);

