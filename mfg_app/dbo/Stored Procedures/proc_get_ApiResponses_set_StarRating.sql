
CREATE procedure [dbo].[proc_get_ApiResponses_set_StarRating]	 

 @CompanyId int

as
begin
 
	declare @TotalResponsesCount int,@AvgScore decimal(18,2),@NoOfStars decimal(18,2);  	 

	select @TotalResponsesCount = 
		(select count(*) from mp_rating_responses with (nolock) where to_company_id = @CompanyId AND ( parent_id IS NULL  OR parent_id = 0 ))	  

	select @AvgScore = sum(coalesce(Score,0))/count(1) from  mp_rating_responses where to_company_id = @CompanyId AND ( parent_id IS NULL  OR parent_id = 0 )
		
	set @NoOfStars = @AvgScore;

	if exists (select * from mp_star_rating where company_id = @CompanyId)    		
	begin    
		update mp_star_rating
		set company_id = @CompanyId
			,no_of_stars = @NoOfStars
			,total_responses = @TotalResponsesCount			  
		where company_id= @CompanyId  
	end
	else
	begin
		insert into mp_star_rating
		(
			company_id,
			no_of_stars,
			total_responses
		)
		values
		(
			@CompanyId,
			@NoOfStars,					 
			@TotalResponsesCount
		)
	end

end
