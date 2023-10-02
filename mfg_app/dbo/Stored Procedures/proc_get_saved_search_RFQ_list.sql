-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[proc_get_saved_search_RFQ_list]
	@contact_id int
AS
BEGIN
	SELECT saved_search_id, search_filter_name FROM [dbo].[mp_saved_search] WHERE contact_id = @contact_id
END
