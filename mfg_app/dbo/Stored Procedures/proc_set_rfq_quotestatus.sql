
/*
select row_number() over (partition by a.rfq_quote_SupplierQuote_id, rfq_part_id order by a.rfq_quote_SupplierQuote_id, rfq_part_id , rfq_part_quantity_id) rn ,  a.* , b.contact_id 
                from mp_rfq_quote_items a		(nolock)  
                join mp_rfq_quote_SupplierQuote b  (nolock) on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id 
                where b.rfq_id = 1192815


-- Award with other option
declare @p1 dbo.tbltype_ListOfRfqQuoteItemsIds
insert into @p1 values(0,60914,1,1368345,21,31,23)
insert into @p1 values(0,60915,1,1368345,31,31,23)
select * from @p1


exec proc_set_rfq_quotestatus @RfqQuoteItemsIds=@p1,@IsAwrded=1,@RfqId=1162528,@RfqQuoteSupplierQuoteId=0,@IsDeclineAll=0

*/

CREATE PROCEDURE [dbo].[proc_set_rfq_quotestatus]
	 @RfqQuoteItemsIds as tbltype_ListOfRfqQuoteItemsIds readonly,
	 @IsAwrded bit,
	 @RfqId int,
	 @RfqQuoteSupplierQuoteId int,
	 @IsDeclineAll bit
	 ---- added with M2-4823 
	 ,@AwardedRegionId INT = NULL
	 ,@AwardedCompanyId INT = NULL
	 ,@AwardedCompanyName NVARCHAR(300) = NULL
	 ,@AwardedWhyOfflineReason NVARCHAR (MAX) = NULL
	 ,@NotAwardedReason NVARCHAR (MAX) = NULL
AS
begin
	/*
		Create date: 23/04/2019
		Description:	Stored procedure to set part award status
	*/

	
	begin try

	declare @updatecount int = 0
	declare @quoteneededbydate datetime
	declare @status varchar(500) 
	declare @awardcount int = 0
	declare @awardcount1 int = 0
	declare @currentstatus int = 0
	declare @modifiedstatus int = 0
	declare @userid int = 0
	declare @buyercontactid int = 0
	declare @awardpartsstatus int = 0
	declare @multiplepartstatus int = 0
	--declare @rfqstatus int = 0
	declare @todaydate datetime = getutcdate() 
	declare @isclonedrfq bit = 0
	declare @haveclonerfqs bit = 0
	declare @RfqQuoteCount int = 0
	declare @anypartawarded int = 0

	select @quoteneededbydate = convert(datetime,quotes_needed_by) , @currentstatus = rfq_status_id , @userid = contact_id from mp_rfq (nolock) where rfq_id = @RfqId

	select @RfqQuoteCount = count(1) from mp_rfq_quote_SupplierQuote (nolock) where rfq_id = @RfqId and is_quote_submitted = 1 and is_rfq_resubmitted = 0

	drop table if exists #RfqPartQuotesInfo
	drop table if exists #IsRfqAnyPartAwarded

	/* M2-3172 Leadstream - Report Buyer Awards - DB */
	SELECT @buyercontactid = contact_id FROM mp_rfq (nolock) WHERE rfq_id = @RfqId

	-- if quote item id exists then follow normal process or if buyer select other quantity while awarding
	if 
	(
		(
			select sum(rowsum) from
			(
				select isnull(RfqQuoteItemsId,0) rowsum from  @RfqQuoteItemsIds
				union 
				select isnull(PartStatusId,0) rowsum from  @RfqQuoteItemsIds where ISNULL(PartStatusId,0)	not in (0,16,17,18,20)
			) a
		) > 0 
	)
	begin
		select @awardcount1 = count(1) 
		from mp_rfq_quote_items a		(nolock)  
		where rfq_quote_items_id in (select RfqQuoteItemsId from  @RfqQuoteItemsIds) and is_awrded = 1


		-- set is awarded flag based on quote items id's
		if @IsAwrded = 1
		begin
			update a 
			set 
				a.is_awrded = @IsAwrded
				,a.awarded_date = getutcdate() 
				,a.status_id = 6
			from mp_rfq_quote_items a		(nolock)  
			join mp_rfq_quote_SupplierQuote b  (nolock) on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id 
			where	a.rfq_quote_items_id in 
			(
				select RfqQuoteItemsId from  @RfqQuoteItemsIds
			)
		     and b.rfq_id = @RfqId
				
			
			set @updatecount = @@rowcount

			/* M2-4921 Buyer - Award modal step 1 - Other selection - DB */
			update a 
			set 
				a.is_awrded = @IsAwrded
				,a.awarded_date = getutcdate() 
				,a.status_id = 6
				,a.unit = c.Unit 
				,a.unit_type_id = c.UnitTypeId
				,a.price  = c.Price
			from 
            mp_rfq_quote_items   a		(nolock)  
            join 
            (
                select row_number() over (partition by a.rfq_quote_SupplierQuote_id, rfq_part_id order by a.rfq_quote_SupplierQuote_id, rfq_part_id , rfq_part_quantity_id) rn ,  a.* , b.contact_id 
                from mp_rfq_quote_items a		(nolock)  
                join mp_rfq_quote_SupplierQuote b  (nolock) on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id 
                where b.rfq_id = @RfqId
            ) a1 on  a.rfq_quote_items_id = a1.rfq_quote_items_id	 and a1.rn = 1
			join @RfqQuoteItemsIds			c			on a1.contact_id = c.PartStatusId and a1.rfq_part_id = c.RfqPartId 
			set @updatecount = @updatecount + @@rowcount
			/**/

			/* M2-3172 Leadstream - Report Buyer Awards - DB */
			INSERT INTO mp_lead
			SELECT DISTINCT c.company_id, 10 ,@buyercontactid,'',getutcdate(),NULL,	NULL,NULL,b.rfq_id 
			FROM mp_rfq_quote_items  a		(nolock)  
			join mp_rfq_quote_SupplierQuote b  (nolock) on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id 
			join mp_contacts c (nolock) on b.contact_id = c.contact_id
			join mp_companies d (nolock) on(c.company_id = d.company_id)
			WHERE	a.rfq_quote_items_id IN(select RfqQuoteItemsId from  @RfqQuoteItemsIds) 
					AND c.is_buyer = 0 AND c.company_id NOT IN
			(SELECT company_id FROM mp_lead WHERE lead_from_contact = @buyercontactid AND lead_source_id = 10 AND value = b.rfq_id 
			AND (status_id IS NULL OR status_id <> 2))
						 --ORDER BY rfq_quote_items_id DESC


		end
		/* M2-2552 Buyer - Awarding bugs */
		else if @IsAwrded = 0 and @awardcount1 = 0
		begin

			update a 
			set 
				a.is_awrded = @IsAwrded
				,a.awarded_date = getutcdate() 
				,a.status_id = NULL
				,a.unit = NULL
				,a.price = NULL
				,a.unit_type_id = NULL
				---- added with M2-4823 
				,a.AwardedRegionId = NULL
				,a.AwardedCompanyId =NULL
				,a.AwardedCompanyName= NULL
				,a.AwardedWhyOfflineReason = NULL
				,a.NotAwardedReason = NULL
			from mp_rfq_quote_items a		(nolock)  
			join mp_rfq_quote_SupplierQuote b  (nolock) on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id 
			where	a.rfq_quote_items_id in (select RfqQuoteItemsId from  @RfqQuoteItemsIds)
					and b.rfq_id = @RfqId
			set @updatecount = @@rowcount


		end
		else if @IsAwrded = 0 and @awardcount1 > 0
		begin

			update a 
			set 
				a.is_awrded = @IsAwrded
				,a.awarded_date = getutcdate() 
				,a.status_id = NULL
				,a.unit = NULL
				,a.price = NULL
				,a.unit_type_id = NULL
			from mp_rfq_quote_items a		(nolock)  
			join mp_rfq_quote_SupplierQuote b  (nolock) on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id 
			where	a.rfq_quote_items_id in (select RfqQuoteItemsId from  @RfqQuoteItemsIds)
					and b.rfq_id = @RfqId
					and a.is_awrded = 1
			set @updatecount = @@rowcount

			/* M2-3172 Leadstream - Report Buyer Awards - DB */
			select @awardpartsstatus = count(1) 
			from mp_rfq_quote_items a		(nolock)  
			where rfq_quote_SupplierQuote_id = @RfqQuoteSupplierQuoteId and is_awrded = 1

			if @awardpartsstatus = 0
			begin
				UPDATE mp_lead SET status_id = 2
				FROM mp_rfq_quote_SupplierQuote a  (nolock) 
				join  mp_contacts b (nolock)  on(a.contact_id = b.contact_id)
				join mp_lead c (nolock)  on(b.company_id = c.company_id)
				WHERE 
					rfq_quote_SupplierQuote_id = @RfqQuoteSupplierQuoteId AND b.is_buyer = 0
					AND c.lead_source_id = 10 AND c.lead_from_contact = @buyercontactid AND c.value = @RfqId
			end

		end
		/**/

		select @awardcount = count(1) 
		from mp_rfq_quote_items a		(nolock)  
		join mp_rfq_quote_SupplierQuote b  (nolock) on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id 
		and a.is_awrded=1 
		and b.rfq_id = @RfqId
		and is_rfq_resubmitted = 0

		select @RfqId RfqId , a.status_id status_id into #IsRfqAnyPartAwarded
		from mp_rfq_quote_items			a	(nolock)  
		join mp_rfq_quote_SupplierQuote b	(nolock)	on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id 
		where 
		b.is_quote_submitted = 1 
		and b.is_rfq_resubmitted = 0 
		and b.rfq_id = @RfqId
		and a.status_id is not null
		union
		select @RfqId RfqId ,AwardedStatusId from mp_rfq_parts where rfq_id = @RfqId and AwardedStatusId is not null
		order by status_id



		if @updatecount > 0
		begin
			-- if is awarded flag =1  then fq status = awarded
			if @IsAwrded =1  
			begin
				update mp_rfq set rfq_status_id = 6  
				,RegenerateShopIQOn = getutcdate() ---- M2-4272 M - Update Shop IQ data if the award price is updated - DB
				where rfq_id = @RfqId
				set @updatecount = @@rowcount
				
			end
			else if  @IsAwrded =0 and ((select count(1) from #IsRfqAnyPartAwarded) >  0)
			begin

				update a set a.rfq_status_id = b.status_id
				,a.RegenerateShopIQOn = getutcdate() ---- M2-4272 M - Update Shop IQ data if the award price is updated - DB
				from mp_rfq a
				join (select top 1 * from #IsRfqAnyPartAwarded ) b on a.rfq_id = b.RfqId 
				where a.rfq_id = @RfqId

			end
			-- if quotes_needed_by date less then getdate then fq status = quoting
			else if @IsAwrded =0 and (@quoteneededbydate < convert(datetime,getutcdate())) 
			begin
				if @awardcount = 0
				begin
					update mp_rfq set rfq_status_id = 5  
					,RegenerateShopIQOn = getutcdate() ---- M2-4272 M - Update Shop IQ data if the award price is updated - DB
					where rfq_id = @RfqId
					set @updatecount = @@rowcount
				end
				else
				begin
					/* M2-3271 Buyer - Dashboard award module changes - DB*/
					update a set a.rfq_status_id = b.status_id
					,a.RegenerateShopIQOn = getutcdate() ---- M2-4272 M - Update Shop IQ data if the award price is updated - DB
					from mp_rfq	a	(nolock) 
					join 
					(
						select distinct b.rfq_id 
						, isnull(a.status_id,999) status_id 
						, row_number() over 
							(
								order by  
									case 
										when a.status_id is null then 999  
										when a.status_id = 18 then 998  
										else a.status_id
									end
							) rn
						from mp_rfq_quote_items			a	(nolock)  
						join mp_rfq_quote_SupplierQuote b	(nolock)	on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id 
						--join @RfqQuoteItemsIds			c				on a.rfq_part_id = c.RfqPartId
						where 
							b.is_quote_submitted = 1 
							and b.is_rfq_resubmitted = 0 
							and b.rfq_id = @RfqId
					) b  on a.rfq_id = b.rfq_id and b.rn=1
					/**/
					set @updatecount = @@rowcount
				end
			end
			-- if quotes_needed_by date greater then getdate then rfq status = closed
			else if @IsAwrded =0 and (@quoteneededbydate > convert(datetime,getutcdate())) 
			begin
				if @awardcount = 0
				begin
					update mp_rfq set rfq_status_id = 3  
					,RegenerateShopIQOn = getutcdate() ---- M2-4272 M - Update Shop IQ data if the award price is updated - DB
					where rfq_id = @RfqId
					set @updatecount = @@rowcount
				end
				else
				begin
					/* M2-3271 Buyer - Dashboard award module changes - DB*/
					update a set a.rfq_status_id = b.status_id
					,a.RegenerateShopIQOn = getutcdate() ---- M2-4272 M - Update Shop IQ data if the award price is updated - DB
					from mp_rfq	a	(nolock) 
					join 
					(
						select distinct b.rfq_id , isnull(a.status_id,999) status_id , row_number() over 
							(
								order by  
									case 
										when a.status_id is null then 999  
										when a.status_id = 18 then 998  
										else a.status_id
									end
							) rn
						from mp_rfq_quote_items			a	(nolock)  
						join mp_rfq_quote_SupplierQuote b	(nolock)	on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id 
						--join @RfqQuoteItemsIds			c				on a.rfq_part_id = c.RfqPartId
						where 
							b.is_quote_submitted = 1 
							and b.is_rfq_resubmitted = 0 
							and b.rfq_id = @RfqId
					) b  on a.rfq_id = b.rfq_id and b.rn=1
					/**/
					set @updatecount = @@rowcount
				end
			end

			/* M2-3271 Buyer - Dashboard award module changes - DB*/
			-- changing status of parent & cloned rfq in case of decline & retract
			if ( @IsAwrded =0 )
			begin
				-- checking cloned rfqs with 16,17,18 status if exists then change the status
				-- select b.rfq_id , convert(datetime,b.quotes_needed_by)  quotes_needed_by ,b.rfq_status_id
				update b 
				set b.rfq_status_id = 
				(
					case 
						when convert(datetime,b.quotes_needed_by)  < convert(datetime,getutcdate()) then 5
						when convert(datetime,b.quotes_needed_by)  >= convert(datetime,getutcdate()) then 3
					end
				)
				,b.RegenerateShopIQOn = getutcdate() ---- M2-4272 M - Update Shop IQ data if the award price is updated - DB
				from mp_rfq_cloned_logs (nolock) a
				join mp_rfq (nolock) b on a.cloned_rfq_id = b.rfq_id
				where a.parent_rfq_id = @RfqId and b.rfq_status_id in (16,17,18,20)

				-- checking parent rfq with 16,17,18 status if exists then change the status
				--select b.rfq_id , convert(datetime,b.quotes_needed_by)  quotes_needed_by ,b.rfq_status_id
				update b 
				set b.rfq_status_id = 
				(
					case 
						when convert(datetime,b.quotes_needed_by)  < convert(datetime,getutcdate()) then 5
						when convert(datetime,b.quotes_needed_by)  >= convert(datetime,getutcdate()) then 3
					end
				)
				,b.RegenerateShopIQOn = getutcdate() ---- M2-4272 M - Update Shop IQ data if the award price is updated - DB
				from mp_rfq_cloned_logs (nolock) a
				join mp_rfq (nolock) b on a.parent_rfq_id = b.rfq_id
				where a.cloned_rfq_id = @RfqId and b.rfq_status_id in (16,17,18,20)
				

				insert into mp_data_history
				(field,oldvalue,newvalue,creation_date,userid,tablename)
				select 
					'{"RfqId":'+convert(varchar(50),a.cloned_rfq_id )+'}'
					,'{"RfqStatusId":'+convert(varchar(50), b.rfq_status_id)+'}'
					,'{"RfqStatusId":'+convert(varchar(50),(
					case 
						when convert(datetime,b.quotes_needed_by)  < convert(datetime,getutcdate()) then 5
						when convert(datetime,b.quotes_needed_by)  >= convert(datetime,getutcdate()) then 3
					end
				))+'}' 
					, getutcdate() 
					, @userid 
					, 'mp_rfq'
				
				from mp_rfq_cloned_logs (nolock) a
				join mp_rfq (nolock) b on a.cloned_rfq_id = b.rfq_id
				where a.parent_rfq_id = @RfqId and b.rfq_status_id in (16,17,18,20)
				union
				select 
					'{"RfqId":'+convert(varchar(50),a.parent_rfq_id )+'}'
					,'{"RfqStatusId":'+convert(varchar(50), b.rfq_status_id)+'}'
					,'{"RfqStatusId":'+convert(varchar(50),(
					case 
						when convert(datetime,b.quotes_needed_by)  < convert(datetime,getutcdate()) then 5
						when convert(datetime,b.quotes_needed_by)  >= convert(datetime,getutcdate()) then 3
					end
				))+'}' 
					, getutcdate() 
					, @userid 
					, 'mp_rfq'
				
				from mp_rfq_cloned_logs (nolock) a
				join mp_rfq (nolock) b on a.parent_rfq_id = b.rfq_id
				where a.cloned_rfq_id = @RfqId and b.rfq_status_id in (16,17,18,20)

			end
			/**/

			set @status = 'Success'
		
			select @modifiedstatus = rfq_status_id  from mp_rfq (nolock) where rfq_id = @RfqId

			if @currentstatus <> @modifiedstatus 
			begin
				insert into mp_data_history
				(field,oldvalue,newvalue,creation_date,userid,tablename)
				select '{"RfqId":'+convert(varchar(50),@RfqId)+'}',	'{"RfqStatusId":'+convert(varchar(50),@currentstatus)+'}',	'{"RfqStatusId":'+convert(varchar(50),@modifiedstatus)+'}' , getdate() , @userid , 'mp_rfq'
			end

			if ( @IsAwrded =0  AND @IsDeclineAll = 1 )
			begin
				update mp_rfq_quote_SupplierQuote set is_rfq_resubmitted = 1 ,rfq_resubmitted_date = getutcdate(),is_quote_declined = 1 where rfq_quote_SupplierQuote_id = @RfqQuoteSupplierQuoteId 
			end

		end
		else 
			set @status = 'Failure'


		/* M2-2552 Buyer - Awarding bugs */
		if @status = 'Success'
		begin
	
			update a  set a.is_continue_awarding = 0
			from mp_rfq_quote_items  (nolock) a
			join
			(
				select rfq_quote_items_id
				from mp_rfq_quote_items  (nolock)
				where rfq_part_id in 
				(		
					select distinct rfq_part_id
					from mp_rfq_quote_items (nolock)
					where rfq_quote_items_id in (select RfqQuoteItemsId from  @RfqQuoteItemsIds) and is_awrded = 1 
				)
			) b on a.rfq_quote_items_id = b.rfq_quote_items_id
		end
		/**/
	end
	
	/* M2-3271 Buyer - Dashboard award module changes - DB*/
	if ((select sum(isnull(RfqPartId,0)) from  @RfqQuoteItemsIds where RfqQuoteItemsId = 0 and ISNULL(PartStatusId,0)	in (16,17,18,20)) > 0 )
	begin
		
		select 
			RfqPartId 
			, (
				select count(1) from mp_rfq_quote_SupplierQuote a (nolock)
				join mp_rfq_quote_items b (nolock) on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id
				where rfq_id = @RfqId 
				and b.rfq_part_id = a1.RfqPartId
				and a.is_quote_submitted = 1 and a.is_rfq_resubmitted = 0
			 ) havequotes
		into #RfqPartQuotesInfo
		from  @RfqQuoteItemsIds a1
			
		if ((select sum(havequotes) from #RfqPartQuotesInfo)	=  0)
		begin
			update a set 
				a.AwardedUnit = c.Unit 
				,a.AwardedUnitTypeId = c.UnitTypeId
				,a.AwardedPrice  = c.Price 
				,a.AwardedStatusId = c.PartStatusId
				--,a.is_awrded = (case when c.PartStatusId in  (16,17,20) then 1  else 0 end )
				--,a.awarded_date = @todaydate
				--,a.is_continue_awarding = 0
			from mp_rfq_parts			a	(nolock)  
			join @RfqQuoteItemsIds		c		on a.rfq_part_id = c.RfqPartId 
			where a.rfq_id = @RfqId
			and  a.rfq_part_id in (select RfqPartId from #RfqPartQuotesInfo where havequotes = 0)
			set @updatecount = @@rowcount
		end
		else
		begin
			update a set 
				a.AwardedUnit = c.Unit 
				,a.AwardedUnitTypeId = c.UnitTypeId
				,a.AwardedPrice  = c.Price 
				,a.AwardedStatusId = c.PartStatusId
			from mp_rfq_parts			a	(nolock)  
			join @RfqQuoteItemsIds		c		on a.rfq_part_id = c.RfqPartId 
			where a.rfq_id = @RfqId
			and  a.rfq_part_id in (select RfqPartId from #RfqPartQuotesInfo where havequotes = 0)
			set @updatecount = @@rowcount

			-- fetching award count based on is awarded flag 
			select @awardcount1 = count(1) 
			from mp_rfq_quote_items			a	(nolock)  
			join mp_rfq_quote_SupplierQuote b	(nolock) on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id 
			where a.rfq_quote_items_id in (select RfqPartId from  @RfqQuoteItemsIds) and is_awrded = 1 and b.is_quote_submitted = 1 and b.is_rfq_resubmitted = 0
		
			set @multiplepartstatus = (select count(distinct PartStatusId) from  @RfqQuoteItemsIds )

			-- update data based on rfq part id for all supplier who quoted that rfq
				-- select a.rfq_quote_SupplierQuote_id , a.rfq_quote_items_id  ,a.rfq_part_id , is_awrded ,status_id ,a.unit ,a.price , c.*
				update a set 
					a.unit = c.Unit 
					,a.unit_type_id = c.UnitTypeId
					,a.price  = c.Price 
					,a.status_id = c.PartStatusId
					----- below line commented with M2-4901 
					,a.is_awrded = (case when c.PartStatusId in  (16,17,20) then 1  else 0 end )
					----- Modified with M2-4901 
					--,a.is_awrded = 0 ---- make other supplier quote is_awrded set to 0 
					,a.awarded_date = @todaydate
					,a.is_continue_awarding = 0
					---- added with M2-4823
					,a.AwardedRegionId = @AwardedRegionId
					,a.AwardedCompanyId = @AwardedCompanyId
					,a.AwardedCompanyName = @AwardedCompanyName
					,a.AwardedWhyOfflineReason = @AwardedWhyOfflineReason 
					,a.NotAwardedReason = @NotAwardedReason
				from mp_rfq_quote_items			a	(nolock)  
				join mp_rfq_quote_SupplierQuote b	(nolock)	on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id 
				join @RfqQuoteItemsIds			c				on a.rfq_part_id = c.RfqPartId and c.RfqQuoteItemsId = 0
				where b.is_quote_submitted = 1 and b.is_rfq_resubmitted = 0 and b.rfq_id = @RfqId
				and  a.rfq_part_id in (select RfqPartId from #RfqPartQuotesInfo where havequotes > 0)
				set @updatecount = @@rowcount
			
		end	

		-- checking & setting awardcount based on table type values 
		select @awardcount = count(1) 
		from mp_rfq_quote_items			a	(nolock)  
		join mp_rfq_quote_SupplierQuote b	(nolock) on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id 
		and a.is_awrded=1 
		and b.rfq_id = @RfqId
		and is_rfq_resubmitted = 0 
		and a.awarded_date = @todaydate
		
	--end



		if @updatecount > 0 and @awardcount > 0 
		begin

			-- update rfq status
			--select *
			update a set a.rfq_status_id = b.status_id
			,a.RegenerateShopIQOn = getutcdate() ---- M2-4272 M - Update Shop IQ data if the award price is updated - DB
			from mp_rfq	a	(nolock) 
			join 
			(
				select distinct b.rfq_id , isnull(a.status_id,999) status_id 
				, row_number() over 
							(
								order by  
									case 
										when a.status_id is null then 999  
										when a.status_id = 18 then 998  
										else a.status_id
									end
							) rn
				from mp_rfq_quote_items			a	(nolock)  
				join mp_rfq_quote_SupplierQuote b	(nolock)	on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id 
				--join @RfqQuoteItemsIds			c				on a.rfq_part_id = c.RfqPartId
				where 
					b.is_quote_submitted = 1 
					and b.is_rfq_resubmitted = 0 
					and b.rfq_id = @RfqId
			) b  on a.rfq_id = b.rfq_id and b.rn=1
			set @updatecount = @@rowcount

			set @modifiedstatus = (select rfq_status_id from mp_rfq (nolock)  where rfq_id = @RfqId)
			
			--select @modifiedstatus

			set @status = 'Success'
		
			if @currentstatus <> @modifiedstatus 
			begin
				insert into mp_data_history
				(field,oldvalue,newvalue,creation_date,userid,tablename)
				select '{"RfqId":'+convert(varchar(50),@RfqId)+'}',	'{"RfqStatusId":'+convert(varchar(50),@currentstatus)+'}',	'{"RfqStatusId":'+convert(varchar(50),@modifiedstatus)+'}' , getdate() , @userid , 'mp_rfq'
			end
		end
		else if @updatecount > 0 and @awardcount = 0 
		begin

			if @RfqQuoteCount = 0
			begin
				update a set a.rfq_status_id = b.status_id
				,a.RegenerateShopIQOn = getutcdate() ---- M2-4272 M - Update Shop IQ data if the award price is updated - DB
				from mp_rfq	a	(nolock) 
				join 
				(
					select distinct 
						a.rfq_id 
						, isnull(a.AwardedStatusId,999) status_id 
						, row_number() over 
							(
								order by  
									case 
										when a.AwardedStatusId is null then 999  
										when a.AwardedStatusId = 18 then 998  
										else a.AwardedStatusId
									end
							) rn
					from mp_rfq_parts			a	(nolock)  
					where 
						a.rfq_id = @RfqId
				) b  on a.rfq_id = b.rfq_id and b.rn=1
				set @updatecount = @@rowcount
			end
			else
			begin
			
				update a set a.rfq_status_id = b.status_id
				,a.RegenerateShopIQOn = getutcdate() ---- M2-4272 M - Update Shop IQ data if the award price is updated - DB
				from mp_rfq	a	(nolock) 
				join 
				(
					select distinct b.rfq_id , isnull(a.status_id,999) status_id 
					, row_number() over 
							(
								order by  
									case 
										when a.status_id is null then 999  
										when a.status_id = 18 then 998  
										else a.status_id
									end
							) rn
					from mp_rfq_quote_items			a	(nolock)  
					join mp_rfq_quote_SupplierQuote b	(nolock)	on a.rfq_quote_SupplierQuote_id = b.rfq_quote_SupplierQuote_id 
					--join @RfqQuoteItemsIds			c				on a.rfq_part_id = c.RfqPartId
					where 
						b.is_quote_submitted = 1 
						and b.is_rfq_resubmitted = 0 
						and b.rfq_id = @RfqId
				) b  on a.rfq_id = b.rfq_id and b.rn=1
				set @updatecount = @@rowcount

			end
			
			set @modifiedstatus = (select rfq_status_id from mp_rfq (nolock)  where rfq_id = @RfqId)
			
			--select @modifiedstatus

			set @status = 'Success'
		
			if @currentstatus <> @modifiedstatus 
			begin
				insert into mp_data_history
				(field,oldvalue,newvalue,creation_date,userid,tablename)
				select '{"RfqId":'+convert(varchar(50),@RfqId)+'}',	'{"RfqStatusId":'+convert(varchar(50),@currentstatus)+'}',	'{"RfqStatusId":'+convert(varchar(50),@modifiedstatus)+'}' , getdate() , @userid , 'mp_rfq'
			end

		end
		else 
		begin
			set @status = 'Failure'
		end
	end
	/**/
	
	/* M2-3281 Buyer - Change Awarding Modal - DB */
	
	--  checking rfq is cloned or not
	set @isclonedrfq = (case when (select count(1) from mp_rfq_cloned_logs (nolock) where cloned_rfq_id = @RfqId) > 0 then 1 else 0 end)
	
	-- checking rfq have cloned rfq's or not with quoting and closed status
	set @haveclonerfqs = 
	(
		case 
			when 
			(
				select count(1) 
				from mp_rfq_cloned_logs a (nolock)
				join mp_rfq b (nolock) on a.cloned_rfq_id = b.rfq_id and b.rfq_status_id in (3,5,17,18,20)
				where a.parent_rfq_id = @RfqId
			) > 0 then 1 
			else 0 
		end
	)
	
	-- if rfq is parent and having cloned rfq's then update the status of cloned rfq's with quoting & closed rfq status
	if @haveclonerfqs = 1 and @isclonedrfq = 0
	begin
		-- if rfq is parent and having cloned rfq's then if parent rfq status is awarded then for cloned rfq's status will be Awarded in other region 
		if @modifiedstatus =  6 
		begin
				update b set b.rfq_status_id = 16
				,b.RegenerateShopIQOn = getutcdate() ---- M2-4272 M - Update Shop IQ data if the award price is updated - DB
				from mp_rfq_cloned_logs a (nolock)
				join mp_rfq b (nolock) on a.cloned_rfq_id = b.rfq_id and b.rfq_status_id in (3,5,16,17,18,20)
				where a.parent_rfq_id = @RfqId
		end
		-- if rfq is parent and having cloned rfq's then if parent rfq status is in (16,17,18,20) then for cloned rfq's status will be same as parent
		else if @modifiedstatus in (16,17,18,20)
		begin
				update b set b.rfq_status_id = @modifiedstatus
				,b.RegenerateShopIQOn = getutcdate() ---- M2-4272 M - Update Shop IQ data if the award price is updated - DB
				from mp_rfq_cloned_logs a (nolock)
				join mp_rfq b (nolock) on a.cloned_rfq_id = b.rfq_id and b.rfq_status_id in (3,5,16,17,18,20)
				where a.parent_rfq_id = @RfqId
		end
	end

	-- if rfq is cloned and having parent rfq's then update the status of parent rfq's with quoting & closed rfq status
	else if @isclonedrfq = 1
	begin
		-- if rfq is cloned and having parent rfq's then if cloned rfq status is awarded then for parent rfq's status will be Awarded in other region 
		if @modifiedstatus =  6 
		begin
				/* M2-3513 Data - Add another award status - DB*/				
				--update b set b.rfq_status_id = 16
				--from mp_rfq_cloned_logs a (nolock)
				--join mp_rfq b (nolock) on a.parent_rfq_id = b.rfq_id and b.rfq_status_id in (3,5,16,17,18,20)
				--where a.cloned_rfq_id = @RfqId

				update a set a.rfq_status_id = 16
				,a.RegenerateShopIQOn = getutcdate() ---- M2-4272 M - Update Shop IQ data if the award price is updated - DB
				from mp_rfq (nolock) a
				join 
				(
					select (case when c.cloned_rfq_id = @RfqId then a.parent_rfq_id  else c.cloned_rfq_id end) rfq_id
					from mp_rfq_cloned_logs a (nolock)
					join mp_rfq b (nolock) on a.parent_rfq_id = b.rfq_id and b.rfq_status_id in (3,5,16,17,18,20) and a.cloned_rfq_id = @RfqId
					join mp_rfq_cloned_logs c on b.rfq_id = c.parent_rfq_id
				) b on a.rfq_id = b.rfq_id 

				/**/
		end
		-- if rfq is cloned and having parent rfq's then if cloned rfq status is  in (16,17,18,20)  then for parent rfq's status will be same as cloned rfq
		else
		begin

				/* M2-3513 Data - Add another award status - DB*/				
				--update b set b.rfq_status_id = @modifiedstatus
				--from mp_rfq_cloned_logs a (nolock)
				--join mp_rfq b (nolock) on a.parent_rfq_id = b.rfq_id and b.rfq_status_id in (3,5,16,17,18,20)
				--where a.cloned_rfq_id = @RfqId

				update a set a.rfq_status_id = @modifiedstatus
				,a.RegenerateShopIQOn = getutcdate() ---- M2-4272 M - Update Shop IQ data if the award price is updated - DB
				from mp_rfq (nolock) a
				join 
				(
					select (case when c.cloned_rfq_id = @RfqId then a.parent_rfq_id  else c.cloned_rfq_id end) rfq_id
					from mp_rfq_cloned_logs a (nolock)
					join mp_rfq b (nolock) on a.parent_rfq_id = b.rfq_id and b.rfq_status_id in (3,5,16,17,18,20) and a.cloned_rfq_id = @RfqId
					join mp_rfq_cloned_logs c on b.rfq_id = c.parent_rfq_id
				) b on a.rfq_id = b.rfq_id 

				/**/
		end

	end
	
	/**/
	
	
	
	
	select @status AS status

	INSERT INTO tmpOrderManagementflowlogs (RfqId,FlowName,POJSON)
	SELECT @RfqId , 'Update Rfq Status' , @modifiedstatus

	end try
	begin catch

		set @status = 'Failure'
		select @status AS status

	end catch

	 
	
end
