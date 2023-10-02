CREATE TABLE [dbo].[mp_registered_supplier] (
    [Company_registory_id] INT      IDENTITY (1, 1) NOT NULL,
    [company_id]           INT      NULL,
    [is_registered]        BIT      NULL,
    [created_on]           DATETIME NULL,
    [updated_on]           DATETIME NULL,
    [account_type]         INT      NULL,
    [account_type_source]  INT      NULL,
    [created_by]           INT      NULL,
    [updated_by]           INT      NULL,
    CONSTRAINT [PK_mp_registered_supplier] PRIMARY KEY CLUSTERED ([Company_registory_id] ASC) WITH (FILLFACTOR = 90),
    FOREIGN KEY ([account_type]) REFERENCES [dbo].[mp_system_parameters] ([id])
);


GO
CREATE NONCLUSTERED INDEX [mp_registered_supplier_account_type]
    ON [dbo].[mp_registered_supplier]([account_type] ASC)
    INCLUDE([company_id]) WITH (FILLFACTOR = 90);


GO

CREATE TRIGGER [dbo].[tr_update_isregistered_flag_for_growth_package]  ON  [dbo].[mp_registered_supplier]
AFTER INSERT
AS 
BEGIN
	
	UPDATE mp_registered_supplier SET is_registered = 1 WHERE company_id IN (SELECT company_id FROM Inserted) 

END

GO
CREATE TRIGGER [dbo].[tr_update_isregistered_flag_for_growth_package_1]  ON  [dbo].[mp_registered_supplier]
AFTER UPDATE
AS 
BEGIN
	
	UPDATE mp_registered_supplier SET is_registered = 1 WHERE company_id IN (SELECT company_id FROM Inserted) 

END
