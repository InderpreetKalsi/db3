CREATE    FUNCTION [dbo].[fn_getTranslatedValue]
(     @VALUE_KEY varchar(200), 
     @LANGUAGE_ABR varchar(5) = 'EN')
returns nvarchar(1000)
as
 
/*-- =============================================
-- Create date: 05 Sep, 2018
-- Description:	Function to get the translated value from dictionary table.
		
-- =================================================================
Version No – Change Date – Modified By      – CR No – Note
-- =================================================================
1.0       -- XXXX		 – XXXXXX			– XXXX	– XXXXXX
-- =================================================================
*/
begin

declare @RET nvarchar(1000);

select @RET = case UPPER(@LANGUAGE_ABR)
                       when 'FR' then LI_FR
                       when 'DE' then LI_DE
                       when 'EN' then LI_EN
                       when 'IT' then LI_IT 
                       when 'SP' then LI_SP 
                       when 'PT' then LI_PT 
                       when 'CZ' then LI_CZ 
                       when 'HG' then LI_HG
                       when 'US' then LI_US 
                       when 'CN' then LI_CN
                       when 'TR' then LI_TR
                       when 'KO' then LI_KO
                       when 'VI' then LI_VI
                       when 'JP' then LI_JP
                       when 'XX' then @VALUE_KEY
                       else LI_EN
                       end   
     from dbo.mp_mst_dictionary(nolock) d
     where LI_KEY = @VALUE_KEY;

return isnull(@RET, @VALUE_KEY);

end
