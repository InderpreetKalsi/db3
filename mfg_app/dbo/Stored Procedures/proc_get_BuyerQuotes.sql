




/*

EXEC [proc_get_BuyerQuotes] 
	@RfqId = 0 
	,@ContactId = 1337830
	,@PageNumber =1 
	,@PageSize =10 

EXEC [proc_get_BuyerQuotes] 
	@RfqId = 1154451 
	,@ContactId = 0
	,@PageNumber =1 
	,@PageSize =20 
*/
CREATE PROCEDURE [dbo].[proc_get_BuyerQuotes]  
  @RfqId INT,  
  @ContactId INT,  
  @PageNumber INT=1,  
  @PageSize INT=20  
AS  
BEGIN   
   
 DECLARE @Company_Id INT ;  
 SELECT  @Company_Id = company_id from mp_contacts (nolock) where contact_id  = @ContactId  
 DECLARE @SQLQuery NVARCHAR(MAX) = ''

 if @PageNumber = 0 and @PageSize =0   
 begin  
  set @PageNumber = 1  
  set @PageSize = 20  
 end  
  
 declare @blacklisted_Companies table (company_id int)   
  
    insert into @blacklisted_Companies (company_id)  
    select distinct a.company_id from mp_book_details  a   
    join mp_books b on a.book_id = b.book_id        
    where bk_type= 5 and b.contact_id = @ContactId  
 union    
 select distinct d.company_id from mp_book_details  a   
    join mp_books b on a.book_id = b.book_id     
 join mp_contacts d on b.contact_Id = d.contact_Id AND  a.company_id = @Company_Id  
    where bk_type= 5    
  
 set nocount on  
  
 drop table if exists #tmp_buyer_new_quotes  
 drop table if exists #tmp_buyer_new_quotes_rfq_id  
 drop table if exists #tmpEarlierQuoteTable  
    
  
 IF (@RfqId>0)   
 BEGIN    
  
	  SELECT *  
	  into #tmpEarlierQuoteTable  
	  FROM (   
     
	   select   
	   distinct   
		b.rfq_id AS RFQId  
		,a.rfq_name AS RFQName  
		,g.no_of_stars as NoOfStars  
		,b.contact_id AS contactId  
		,(c.first_name + ' ' + c.last_name ) AS contactName  
		,c.company_id AS CompanyId  
		,b.quote_date AS QuoteDate  
		,b.is_reviewed AS IsReviewed  
		,d.rfq_userStatus_id AS RfqQuoteStatus  
		,b.rfq_quote_SupplierQuote_id   
		,e.rfq_part_id  
		,e.per_unit_price  
		,e.tooling_amount  
		,e.miscellaneous_amount  
		,e.shipping_amount  
		,e.rfq_part_quantity_id  
		,e.awarded_qty  
		,f.quantity_level   
		,b.is_quote_submitted  
		,b.is_rfq_resubmitted  
		,b.is_quote_declined  
		,b.buyer_feedback_id AS 		BuyerFeedbackId	
		,ROW_NUMBER() OVER (PARTITION BY b.contact_id, e.rfq_part_id   ORDER BY b.quote_date DESC, b.contact_id, e.rfq_part_id , f.quantity_level ) AS rn  
		/* M2-3318 Buyer - Change the My Quotes page to reflect Viewed and Reviewed - DB */
		,b.IsViewed				AS IsViewedByBuyer   
		/**/
		/* M2-4793 */
		,a.WithOrderManagement  
		/**/
	   from   
		mp_rfq        a (nolock)   
	   join mp_rfq_quote_supplierquote   b (nolock) on a.rfq_id = b.rfq_id   
		--and a.contact_id =@ContactId   
		and is_rfq_resubmitted = 1   
		and is_quote_submitted = 1  
		and a.rfq_status_id not in (13)  
		and a.rfq_id = @RfqId   
		and b.contact_id NOT IN   
		(select mp_rfq_quote_supplierquote.contact_id from  mp_rfq_quote_supplierquote   
		join mp_rfq on mp_rfq_quote_supplierquote.rfq_id = mp_rfq.rfq_id  
		where mp_rfq.rfq_id = @RfqId  
		and mp_rfq.rfq_status_id not in (13)  
		and is_quote_submitted = 1  
		and  is_rfq_resubmitted = 0)       
	   join mp_contacts      c (nolock) on b.contact_id = c.contact_id    
	   left join mp_rfq_quote_suplierstatuses d (nolock) on b.rfq_id = d.rfq_id and d.contact_id = b.contact_id  
	   join mp_rfq_quote_items     e (nolock) on b.rfq_quote_SupplierQuote_id = e.rfq_quote_SupplierQuote_id   
	   join mp_rfq_part_quantity    f (nolock) on e.rfq_part_id = f.rfq_part_id and e.rfq_part_quantity_id = f.rfq_part_quantity_id  
	   left join mp_star_rating     g (nolock) on c.company_id=g.company_id   
  
	   join   
	   (  
		select   
		 a.rfq_quote_SupplierQuote_id , rfq_part_id   
		 , b.rfq_part_quantity_id , max(rfq_quote_items_id) rfq_quote_items_id  
		from   
		(  
		 select distinct contact_id ,  max(rfq_quote_SupplierQuote_id)  rfq_quote_SupplierQuote_id   
		 from mp_rfq_quote_supplierquote (nolock)  
		 where rfq_id = @RfqId   
		 and is_rfq_resubmitted = 1  
		 and is_quote_submitted = 1  
		 group by contact_id   
		) a  
		join mp_rfq_quote_items b (nolock) on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id   
		group by a.rfq_quote_SupplierQuote_id , rfq_part_id , b.rfq_part_quantity_id   
    
     
  
	   ) h on  e.rfq_quote_items_id = h.rfq_quote_items_id  
	   where c.company_id not in  (select company_id from @blacklisted_Companies)  
      
	  ) AS Earlier_Quote         
  
   
	  SELECT *   
	  into #tmp_buyer_new_quotes_rfq_id    
	  FROM   
	  (  
   
	   select   
	   distinct   
		b.rfq_id AS RFQId  
		,a.rfq_name AS RFQName  
		,g.no_of_stars as NoOfStars  
		,b.contact_id AS contactId  
		,(c.first_name + ' ' + c.last_name ) AS contactName  
		,c.company_id AS CompanyId  
		,b.quote_date AS QuoteDate  
		,b.is_reviewed AS IsReviewed  
		,d.rfq_userStatus_id AS RfqQuoteStatus  
		,b.rfq_quote_SupplierQuote_id   
		,e.rfq_part_id  
		,e.per_unit_price  
		,e.tooling_amount  
		,e.miscellaneous_amount  
		,e.shipping_amount  
		,e.rfq_part_quantity_id  
		,e.awarded_qty  
		,f.quantity_level   
		,b.is_quote_submitted  
		,b.is_rfq_resubmitted   
		,b.is_quote_declined      
		,b.buyer_feedback_id AS BuyerFeedbackId
		/* M2-3318 Buyer - Change the My Quotes page to reflect Viewed and Reviewed - DB */
		,b.IsViewed				AS IsViewedByBuyer   
		/**/
		/* M2-4793 */
		,a.WithOrderManagement  
		/**/
	  from   
	   mp_rfq        a (nolock)   
	  join mp_rfq_quote_supplierquote   b (nolock) on a.rfq_id = b.rfq_id   
	   --and a.contact_id =@ContactId   
		  and is_rfq_resubmitted = 0   
	   and is_quote_submitted = 1  
	   and a.rfq_status_id not in (13)  
	   and a.rfq_id = @RfqId  
	  join mp_contacts      c (nolock) on b.contact_id = c.contact_id    
	  left join mp_rfq_quote_suplierstatuses d (nolock) on b.rfq_id = d.rfq_id and d.contact_id = b.contact_id  
	  join mp_rfq_quote_items     e (nolock) on b.rfq_quote_SupplierQuote_id = e.rfq_quote_SupplierQuote_id   
	  join mp_rfq_part_quantity    f (nolock) on e.rfq_part_id = f.rfq_part_id and e.rfq_part_quantity_id = f.rfq_part_quantity_id  
	  left join mp_star_rating    g (nolock) on c.company_id=g.company_id   
	  join   
	  (  
	   select a.rfq_quote_SupplierQuote_id , rfq_part_id   
	   , b.rfq_part_quantity_id , max(rfq_quote_items_id) rfq_quote_items_id  
	   from mp_rfq_quote_supplierquote a (nolock)  
	   join mp_rfq_quote_items b (nolock) on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id   
	   where  a.rfq_id = @RfqId  
	   and is_rfq_resubmitted = 0   
	   and is_quote_submitted = 1  
	   group by a.rfq_quote_SupplierQuote_id , rfq_part_id , b.rfq_part_quantity_id   
    
	  ) h on  e.rfq_quote_items_id = h.rfq_quote_items_id  
	  where c.company_id not in  (select company_id from @blacklisted_Companies)  
  
	  Union    
    
	  SELECT RFQId,RFQName,NoOfStars,contactId,contactName,CompanyId,QuoteDate,IsReviewed,  
	  RfqQuoteStatus,rfq_quote_SupplierQuote_id,rfq_part_id,per_unit_price,tooling_amount,miscellaneous_amount,shipping_amount,  
	  rfq_part_quantity_id,awarded_qty,quantity_level,is_quote_submitted,is_rfq_resubmitted,is_quote_declined  ,BuyerFeedbackId , IsViewedByBuyer,WithOrderManagement
	  FROM #tmpEarlierQuoteTable   
	  --WHERE rn = 1  
  
	  ) AS All_Quote_List   
    
	  select 
			RFQId , RFQName , NoOfStars , contactId , contactName ,CompanyId , QuoteDate 
			, IsReviewed ,RfqQuoteStatus,  QuoteSubmitted, rfq_quote_SupplierQuote_id 
			, Qty1 , Qty2 ,Qty3,is_rfq_resubmitted,is_quote_declined ,BuyerFeedbackId
			, isnull(b.RFQSupplierStatusId,999) RFQSupplierStatusId ,IsViewedByBuyer,WithOrderManagement
	   
	  from 
	  (
		  select   
	  			RFQId , RFQName , NoOfStars , contactId , contactName ,CompanyId , QuoteDate 
				, IsReviewed ,RfqQuoteStatus, is_quote_submitted as QuoteSubmitted, rfq_quote_SupplierQuote_id 
				, [0] as Qty1 , [1]  as Qty2 , [2]    as Qty3,is_rfq_resubmitted,is_quote_declined ,BuyerFeedbackId , CAST('true' AS BIT) IsViewedByBuyer,WithOrderManagement
		  from    
		  (  
			   select *  
			   from  
			   (     
				select   
				RFQId , RFQName, NoOfStars , contactId , contactName ,CompanyId , QuoteDate ,IsReviewed ,RfqQuoteStatus, is_quote_submitted, rfq_quote_SupplierQuote_id ,  quantity_level ,  
				sum(((coalesce(per_unit_price,0) * coalesce(awarded_qty,0)) + coalesce(tooling_amount,0)  +  coalesce(miscellaneous_amount,0)  +  coalesce(shipping_amount,0))) as qty_total ,   
				is_rfq_resubmitted,is_quote_declined  ,BuyerFeedbackId ,IsViewedByBuyer,WithOrderManagement
				from #tmp_buyer_new_quotes_rfq_id  
				group by RFQId , RFQName, NoOfStars , contactId , contactName ,CompanyId , QuoteDate ,IsReviewed ,is_quote_submitted ,RfqQuoteStatus,rfq_quote_SupplierQuote_id , quantity_level,is_rfq_resubmitted,is_quote_declined  ,BuyerFeedbackId ,IsViewedByBuyer,WithOrderManagement
			   ) a   
  
		  ) as buyer_new_quotes    
		  pivot    
		  (    
		  max(qty_total)    
		  for quantity_level IN ([0], [1], [2])    
		  ) as PivotTable  
	  ) a
	  /* M2-3281 Buyer - Change Awarding Modal - DB */
	  left join 
	  (
			select   
				a.contact_id as SupplierId
				,min(isnull(b.status_id,999)) RFQSupplierStatusId
			from mp_rfq_quote_supplierquote a (nolock)  
			join mp_rfq_quote_items b (nolock) on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id   
			where  a.rfq_id = @RfqId  
				and is_rfq_resubmitted = 0   
				and is_quote_submitted = 1  
				and (b.is_continue_awarding is null or b.is_continue_awarding = 0)
			group by a.contact_id 
		  
	  ) as b on a.contactId = b.SupplierId
	  /**/
	  order by  QuoteDate,is_rfq_resubmitted desc  

	/* 
		M2-2966 
		M2-3388 Buyer - Change the RFQ details 'Quotes' page to reflect Viewed and Reviewed - DB
	*/
	

	IF ((SELECT COUNT(1) FROM #tmp_buyer_new_quotes_rfq_id WHERE IsViewedByBuyer = 0) > 0 )
	BEGIN

		SELECT  @SQLQuery = COALESCE(@SQLQuery + '', '') + 
			'EXEC proc_set_emailMessages @rfq_id =  '''+CONVERT(VARCHAR(100), RFQId)+''' , @message_type = ''BUYER_VIEWED_AN_RFQ9999'' ,@message_status_id = '''' ,@from_contact = '''' , @to_contacts = '''+CONVERT(VARCHAR(100), contactId)+''' ,@message = '''' ,@message_link = '''',@MessageFileNames = ''''  '
		FROM 
		( SELECT DISTINCT RFQId ,contactId FROM #tmp_buyer_new_quotes_rfq_id WHERE IsViewedByBuyer = 0 ) a

		--SELECT @SQLQuery
		EXEC (@SQLQuery)
		
		UPDATE a SET a.IsViewed = 1
		FROM mp_rfq_quote_supplierquote (NOLOCK) a
		JOIN #tmp_buyer_new_quotes_rfq_id b ON a.rfq_id = b.RFQId AND a.contact_id = b.contactId
		WHERE b.IsViewedByBuyer = 0 AND a.is_rfq_resubmitted = 0
	END
		/**/

 END      
 ELSE IF(@ContactId>0)   
 BEGIN   
    
   select   
   distinct   
    b.rfq_id AS RFQId  
    ,a.rfq_name AS RFQName  
    ,b.contact_id AS contactId  
    ,(c.first_name + ' ' + c.last_name ) AS contactName  
    ,c.company_id AS CompanyId  
    ,b.quote_date AS QuoteDate  
    ,b.is_reviewed AS IsReviewed  
    ,d.rfq_userStatus_id AS RfqQuoteStatus  
    ,b.rfq_quote_SupplierQuote_id   
    ,e.rfq_part_id  
    ,e.per_unit_price  
    ,e.tooling_amount  
    ,e.miscellaneous_amount  
    ,e.shipping_amount  
    ,e.rfq_part_quantity_id  
    ,e.awarded_qty  
    ,f.quantity_level   
    , is_rfq_resubmitted  
    , b.is_quote_declined  
	, b.buyer_feedback_id AS BuyerFeedbackId
	, b.IsViewed				AS IsViewedByBuyer   
	/* M2-4793 */
	,a.WithOrderManagement  
	/**/
  into #tmp_buyer_new_quotes           
  from   
   mp_rfq        a (nolock)   
  join mp_rfq_quote_supplierquote   b (nolock) on a.rfq_id = b.rfq_id   
   and a.contact_id =@ContactId   
   and is_rfq_resubmitted = 0   
   and is_quote_submitted = 1  
   and a.rfq_status_id not in (1,13)  
   and b.is_reviewed = 0  
   --and a.rfq_id = 1149002  
  join mp_contacts      c (nolock) on b.contact_id = c.contact_id    
  left join mp_rfq_quote_suplierstatuses d (nolock) on b.rfq_id = d.rfq_id and d.contact_id = b.contact_id  
  join mp_rfq_quote_items     e (nolock) on b.rfq_quote_SupplierQuote_id = e.rfq_quote_SupplierQuote_id   
  join mp_rfq_part_quantity    f (nolock) on e.rfq_part_id = f.rfq_part_id and e.rfq_part_quantity_id = f.rfq_part_quantity_id  
  where c.company_id not in  (select company_id from @blacklisted_Companies)  
  
	select

		a.RFQId , RFQName , contactId , contactName ,CompanyId , QuoteDate ,IsReviewed ,RfqQuoteStatus
		, rfq_quote_SupplierQuote_id , Qty1 , Qty2 , Qty3 , TotalCount,is_rfq_resubmitted,is_quote_declined  
		,BuyerFeedbackId, isnull(b.RFQSupplierStatusId ,999) as RFQSupplierStatusId ,IsViewedByBuyer,WithOrderManagement

	from
	(
		  select   
		  RFQId , RFQName , contactId , contactName ,CompanyId , QuoteDate ,IsReviewed ,RfqQuoteStatus, rfq_quote_SupplierQuote_id , [0] as Qty1 , [1]  as Qty2 , [2]    as Qty3  
		  ,count(RFQId) over() TotalCount,is_rfq_resubmitted,is_quote_declined  ,BuyerFeedbackId ,IsViewedByBuyer,WithOrderManagement
		  from    
		  (  
		   select *  
		   from  
		   (     
			select   
			RFQId , RFQName , contactId , contactName ,CompanyId , QuoteDate ,IsReviewed ,RfqQuoteStatus, rfq_quote_SupplierQuote_id ,  quantity_level ,  
			convert(decimal(18,4),sum(((coalesce(per_unit_price,0) * coalesce(awarded_qty,0)) + coalesce(tooling_amount,0)  +  coalesce(miscellaneous_amount,0)  +  coalesce(shipping_amount,0)))) as qty_total, is_rfq_resubmitted,is_quote_declined    ,BuyerFeedbackId ,IsViewedByBuyer ,WithOrderManagement
  
			from #tmp_buyer_new_quotes  
			group by RFQId , RFQName , contactId , contactName ,CompanyId , QuoteDate ,IsReviewed ,RfqQuoteStatus,rfq_quote_SupplierQuote_id , quantity_level, is_rfq_resubmitted,is_quote_declined  ,BuyerFeedbackId ,IsViewedByBuyer,WithOrderManagement
		   ) a   
  
		  ) as buyer_new_quotes    
		  pivot    
		  (    
		  max(qty_total)    
		  for quantity_level IN ([0], [1], [2])    
		  ) as PivotTable  
	  ) a
	  /* M2-3281 Buyer - Change Awarding Modal - DB */
	  left join 
	  (
			select   
				a.rfq_id AS RfqId
				,a.contact_id as SupplierId
				,min(isnull(b.status_id,999)) RFQSupplierStatusId
			from mp_rfq_quote_supplierquote a (nolock)  
			join mp_rfq_quote_items b (nolock) on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id   
			join mp_rfq				c (nolock) on a.rfq_id = c.rfq_id
			where  
				c.contact_id =@ContactId   
				and is_rfq_resubmitted = 0   
				and is_quote_submitted = 1  
				and c.rfq_status_id not in (1,13)  
				and a.is_reviewed = 0  
				and (b.is_continue_awarding is null or b.is_continue_awarding = 0)
			group by a.rfq_id  ,a.contact_id 
		  
	  ) as b on a.contactId = b.SupplierId and a.RFQId = b.RfqId
	  /**/
  order by QuoteDate desc  
  offset @PageSize * (@PageNumber - 1) rows  
  fetch next @PageSize rows only  
  ;    
  
  
 END    
  
  
 drop table if exists #tmp_buyer_new_quotes  
 drop table if exists #tmp_buyer_new_quotes_rfq_id  
 drop table if exists #tmpEarlierQuoteTable       
  
END
