  
    
  
  
  
    
-- =============================================  
  
-- Author:  dp-Al. L.  
  
-- Create date:  20/11/2018  
  
-- Description: Stored procedure to Get list of API responses from [mp_nps_api_responses] table based on [contact_id],   
    -- calculate Promoters, Passives, Detractors and NPS score for a particular survey,  
    -- and insert/update it back into [mp_nps_rating] table.  
  
-- Modification: - Shifting NPS calculation from Contact IDs to Company IDs (03 Jan 2018)..  
  
-- Syntax: [proc_get_ApiResponses_set_NpsRating] <CompanyId>  
  
-- Example: [proc_get_ApiResponses_set_NpsRating] 1   
  
-- =================================================================  
  
--Version No – Change Date – Modified By      – CR No – Note  
-- 2     03 Jan 2018 - dp-Al. L.      - Shifting NPS calculation from Contact IDs to Company IDs..  
  
-- =================================================================  
  
  
CREATE PROCEDURE [dbo].[proc_get_ApiResponses_set_NpsRating]    
  
 @CompanyId bigint  
  
AS  
  
BEGIN  
  
   
 declare @TotalResponsesCount int;  
    declare @TotalPromotersCount int;  
 declare @TotalPassivesCount int;  
 declare @TotalDetractorsCount int;  
 
 --Along with Child Responses... (Changed from using ContactID to CompanyID)  
 select @TotalResponsesCount = (select count(*) from mp_rating_responses WITH (NOLOCK) WHERE ((to_company_id = @CompanyId) or (parent_id in (select response_id from [mp_rating_responses] WITH (NOLOCK) where to_company_id = @CompanyId))))  
  
 select @TotalPromotersCount = (select count(*) from mp_rating_responses WITH (NOLOCK) WHERE ((to_company_id = @CompanyId) or (parent_id in (select response_id from [mp_rating_responses] WITH (NOLOCK) where to_company_id = @CompanyId))) and (score <= 10 and score >= 9))  
 select @TotalPassivesCount = (select count(*) from mp_rating_responses WITH (NOLOCK) WHERE ((to_company_id = @CompanyId) or (parent_id in (select response_id from [mp_rating_responses] WITH (NOLOCK) where to_company_id = @CompanyId))) and (score <= 8 and
 score >= 7))  
 select @TotalDetractorsCount = (select count(*) from mp_rating_responses WITH (NOLOCK) WHERE ((to_company_id = @CompanyId) or (parent_id in (select response_id from [mp_rating_responses] WITH (NOLOCK) where to_company_id = @CompanyId))) and (score >= 0 and score <= 6))  
  
    
 declare @PromotersPercentage decimal;  
 declare @PassivesPercentage decimal;  
 declare @DetractorsPercentage decimal;  
  
  
 select @PromotersPercentage =  (select((CONVERT(decimal, @TotalPromotersCount) / (CONVERT(decimal,@TotalResponsesCount))) * 100))  
 select @PassivesPercentage =  (select((CONVERT(decimal, @TotalPassivesCount) / (CONVERT(decimal,@TotalResponsesCount))) * 100))  
 select @DetractorsPercentage =  (select((CONVERT(decimal, @TotalDetractorsCount) / (CONVERT(decimal,@TotalResponsesCount))) * 100))  
  
 declare @NpsScore decimal;  
 set @NpsScore = @PromotersPercentage - @DetractorsPercentage;  
 
  
 --IF EXISTS (SELECT * FROM mp_nps_rating WHERE contact_id=@ContactId) --removed  
 IF EXISTS (SELECT * FROM mp_nps_rating WHERE company_id=@CompanyId)   --added  
    
  BEGIN  
      
   UPDATE [dbo].[mp_nps_rating]  
   SET [nps_score] = @NpsScore  
     ,[promoter_score] = @PromotersPercentage  
     ,[promoter_count] = @TotalPromotersCount  
     ,[passive_score] = @PassivesPercentage  
     ,[passive_count] = @TotalPassivesCount  
     ,[detractor_score] = @DetractorsPercentage  
     ,[detractor_count] = @TotalDetractorsCount  
     ,[total_responses] = @TotalResponsesCount  
   --WHERE contact_id=@ContactId  
     WHERE company_id=@CompanyId --modified  
  
  END  
  
 ELSE  
  
  BEGIN  
  
   INSERT INTO [dbo].[mp_nps_rating]  
       (  
       --[contact_id] --removed  
        [company_id]  --added  
       ,[nps_score]  
       ,[promoter_score]  
       ,[promoter_count]  
       ,[passive_score]  
       ,[passive_count]  
       ,[detractor_score]  
       ,[detractor_count]  
       ,[total_responses])  
    VALUES  
       (  
       --@ContactId --removed  
     @CompanyId  --added  
       ,@NpsScore  
       ,@PromotersPercentage  
       ,@TotalPromotersCount  
       ,@PassivesPercentage  
       ,@TotalPassivesCount  
       ,@DetractorsPercentage  
       ,@TotalDetractorsCount  
       ,@TotalResponsesCount)  
  
  END  
  
  
  
END  
  