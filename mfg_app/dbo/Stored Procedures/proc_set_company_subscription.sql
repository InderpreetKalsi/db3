

/*
SELECT * FROM  mp_gateway_subscription_customers (NOLOCK) WHERE gateway_id  =310
SELECT * FROM  mp_gateway_subscription_customers (NOLOCK) WHERE subscription_customer_id = 'cus_Mfmjp4NA5U47kH' 
SELECT * FROM mp_gateway_subscriptions (NOLOCK) WHERE  customer_id =3565
SELECT * FROM mp_companies (NOLOCK) WHERE company_id = 1768083
SELECT * FROM mp_gateway_subscription_products (NOLOCK) WHERE ProductPriceAPIId = 'price_1LfoppGWEpBLxDePfFENpgUq'

update mp_gateway_subscriptions set 
	next_billing_at	= '2022-11-25 13:58:07.000'
	,subscription_start	= '2022-11-24 13:58:07.000'
	,subscription_end = '2022-12-24 13:58:07.000'
WHERE  customer_id =3565 and id = 1048

EXEC proc_set_company_subscription
	@StripeCustomerId			=  'cus_Mfmjp4NA5U47kH'	   
	,@Email						=  ''
	,@SubscriptionId    		=  'sub_1LwRAKGWEpBLxDePrabjMz6K'		            
	,@TotalAmout				=  '7900'		
	,@SubscriptionStart  		=  '2022-11-24'		      
	,@SubscriptionEnd       	=  '2022-12-24'		
	,@ProductPriceAPIId			=  'price_1LfoppGWEpBLxDePfFENpgUq'		
	,@SubscriptionInterval    	=  'month'		                
	,@SubscriptionIntervalCount	=  '1'		            
	,@InvoiceId            		=  'in_1M7fxTGWEpBLxDePBkUKAUEn'
	,@SubscriptionStatus		=  'active'   
	,@RequestType				=  'Recurring Success'

*/
CREATE PROCEDURE [dbo].[proc_set_company_subscription]
(
	@ContactId						INT          = NULL   
	,@StripeCustomerId				VARCHAR(250)                 
	,@Email    						VARCHAR(250) =  NULL 
	,@PaymentStatus					VARCHAR(50)  =  NULL	           
	,@SessionStatus     			VARCHAR(50)  =  NULL	           
	,@SubscriptionId    			VARCHAR(250)            
	,@TotalAmout					BIGINT       =  NULL	
	,@SubscriptionStart  			DATETIME      
	,@SubscriptionEnd       		DATETIME
	,@ProductPriceAPIId				VARCHAR(250)
	,@SubscriptionInterval    		VARCHAR(50)                
	,@SubscriptionIntervalCount		INT            
	,@InvoiceId            			VARCHAR(250)
	,@SubscriptionStatus          	VARCHAR(50)  
	,@RequestType                   VARCHAR(50) = NULL 
)
AS
BEGIN

	-- M2-4663 Webhooks or API call after Successful Payment from the Stripe Hosted Payment Page -DB
	DECLARE @TransactionStatus VARCHAR(50) = ''
	DECLARE @ErrorMessage VARCHAR(MAX) = ''
	DECLARE @CompanyId INT = 0 
	DECLARE @IsCompanyHasPreviousSubscription	INT = 0 
	DECLARE @SubscriptionCustomersRunningId		BIGINT = 0
	DECLARE @SubscriptionProductRunningId		BIGINT = 0
	--M2-5133
	DECLARE @SourceType  VARCHAR(20)
	DECLARE @AccountTypeId INT
	DECLARE @Event VARCHAR(50)

	----below key is different on production (price_1NYtDIGWEpBLxDePwFIo5PPc) and QA and UAT key is same i.e price_1NRG8mGWEpBLxDePxKvHhGnO
	IF @ProductPriceAPIId = 'price_1NYtDIGWEpBLxDePwFIo5PPc' -- Starter package APIId
	BEGIN
		SET @AccountTypeId = 313
		SET @SourceType = 'SP-Purchased'
		SET @Event = 'paid_status_starter'
	END
	ELSE
	BEGIN
		SET @AccountTypeId = 84
		SET @SourceType = 'GP-Purchased'
		SET @Event = 'paid_status_growth'
	END
	--  log subscription webhook into the db 
	DECLARE @WebhookData			VARCHAR(MAX) = ''
	SET @WebhookData = 
	'@ContactId					=  '''+CONVERT(VARCHAR(500),ISNULL(@ContactId,'0'))+'''	 
	,@StripeCustomerId			=  '''+CONVERT(VARCHAR(500),ISNULL(@StripeCustomerId,''))+'	''                 
	,@Email    					=  '''+CONVERT(VARCHAR(500),ISNULL(@Email,''))+'''	 	
	,@PaymentStatus				=  '''+CONVERT(VARCHAR(500),ISNULL(@PaymentStatus,''))+'''	 	        
	,@SessionStatus     		=  '''+CONVERT(VARCHAR(500),ISNULL(@SessionStatus,''))+'''	 	               
	,@SubscriptionId    		=  '''+CONVERT(VARCHAR(500),ISNULL(@SubscriptionId,''))+'''	 		            
	,@TotalAmout				=  '''+CONVERT(VARCHAR(500),ISNULL(@TotalAmout,'0'))+'''	 
	,@SubscriptionStart  		=  '''+CONVERT(VARCHAR,ISNULL(@SubscriptionStart,''), 21)+'''	 	      
	,@SubscriptionEnd       	=  '''+CONVERT(VARCHAR,ISNULL(@SubscriptionEnd,''), 21)+'''	 		
	,@ProductPriceAPIId			=  '''+CONVERT(VARCHAR(500),ISNULL(@ProductPriceAPIId,'')	)+'''	 	
	,@SubscriptionInterval    	=  '''+CONVERT(VARCHAR(500),ISNULL(@SubscriptionInterval,''))+'''	 		                
	,@SubscriptionIntervalCount	=  '''+CONVERT(VARCHAR(500),ISNULL(@SubscriptionIntervalCount,'0'))+'''	 	            
	,@InvoiceId            		=  '''+CONVERT(VARCHAR(500),ISNULL(@InvoiceId,'') )+'''	 
	,@SubscriptionStatus		=  '''+CONVERT(VARCHAR(500),ISNULL(@SubscriptionStatus,''))+'''	   
	'

	INSERT INTO mpGatewayWebhookLogs (ContactId ,Email,WebhookResponse)
	SELECT @ContactId ,  @Email , @WebhookData
	-- M2-4686
	-- Get the contact id using @StripeCustomerId -> subscription_customer_id 
	IF ( SELECT  COUNT(1) FROM  mp_gateway_subscription_customers (NOLOCK) WHERE subscription_customer_id = @StripeCustomerId ) = 1 
	BEGIN
	   	SELECT @ContactId = supplier_id FROM mp_gateway_subscription_customers (NOLOCK) WHERE subscription_customer_id = @StripeCustomerId
	END

	-- M2-4701 
	-- Get the contact id using @Email if @ContactId IS NULL 
	IF @ContactId IS NULL 
	BEGIN
		SELECT @ContactId = b.contact_id 
		FROM  aspnetusers (NOLOCK) a  
		JOIN mp_contacts (NOLOCK) b ON a.id = b.user_id  WHERE   a.email = @Email  
	END
	
	-- fetching company id based on contact 
	SELECT @CompanyId = company_id FROM mp_contacts (NOLOCK) WHERE contact_id = @ContactId
	SELECT @SubscriptionProductRunningId = id FROM mp_gateway_subscription_products (NOLOCK) WHERE ProductPriceAPIId = @ProductPriceAPIId
		
	-- fetching stripe customer id based on contact and company
	SELECT @IsCompanyHasPreviousSubscription = COUNT(1)
	FROM  mp_gateway_subscription_customers (NOLOCK) 
	WHERE supplier_id = @ContactId AND company_id = @CompanyId AND  gateway_id = 310
		
	
		BEGIN TRY
			BEGIN TRAN

			--  new subscription
			IF @IsCompanyHasPreviousSubscription = 0 AND @SubscriptionProductRunningId > 0
			BEGIN
					--  adding manufacturer info related to subscription
					INSERT INTO [mp_gateway_subscription_customers] (gateway_id ,company_id ,supplier_id ,subscription_customer_id)
					SELECT 310 , @CompanyId ,  @ContactId , @StripeCustomerId
					SET @SubscriptionCustomersRunningId = @@IDENTITY

					IF @SubscriptionCustomersRunningId > 0 
					BEGIN
						--  adding subscription info
						INSERT INTO mp_gateway_subscriptions
						(
							subscription_id ,customer_id ,plan_id ,next_billing_at 
							,subscription_start ,subscription_end
							,status ,created  ,PaymentStatus ,SessionStatus ,TotalAmout 
							,SubscriptionInterval ,SubscriptionIntervalCount ,InvoiceId,RequestType
						)
						SELECT @SubscriptionId ,@SubscriptionCustomersRunningId ,@SubscriptionProductRunningId 
						,DATEADD(day , @SubscriptionIntervalCount ,@SubscriptionStart) , @SubscriptionStart ,@SubscriptionEnd
						,@SubscriptionStatus ,GETUTCDATE() ,@PaymentStatus ,@SessionStatus ,@TotalAmout     	                
						,@SubscriptionInterval ,@SubscriptionIntervalCount ,@InvoiceId,@RequestType

						/* M2-4945 HubSpot - Integrate Reshape User Registration API -DB */
							---- adding company details in below table
							IF @CompanyId > 0 
							BEGIN
								IF NOT EXISTS (SELECT CompanyId FROM mpAccountPaidStatusDetails(NOLOCK) WHERE CompanyId = @CompanyId )
								BEGIN
									 INSERT INTO mpAccountPaidStatusDetails (CompanyId,OldValue,NewValue,IsProcessed,IsSynced,SourceType)
									 SELECT @CompanyId, 83 AS OldValue, @AccountTypeId AS NewValue, NULL AS IsProcessed,0 AS IsSynced, @SourceType AS SourceType
								END
							END
						/* */
								
						-- adding in paid manufacturer master list
						IF (SELECT COUNT(1) FROM mp_registered_supplier  (NOLOCK)  WHERE company_id  = @CompanyId) = 0 
						BEGIN 
							IF @SubscriptionStatus = 'canceled'
							BEGIN
								UPDATE mp_companies
									SET IsEligibleForGrowthPackage = 1
									,IsGrowthPackageTaken = 0 
									,IsStarterPackageTaken = 0
									--,IsStarterFreeTrialTaken = 0 --- commented on 25 - jul 
								WHERE company_id = @CompanyId
								
							END
							ELSE
							BEGIN
								INSERT INTO mp_registered_supplier (company_id ,is_registered ,created_on ,account_type ,account_type_source )
								SELECT @CompanyId ,1 ,GETUTCDATE() , @AccountTypeId , 310
							END 					
						END
						ELSE
						BEGIN

							IF @SubscriptionStatus = 'canceled'
							BEGIN
							--- convert this user to Basic so deleted from below table
									DELETE FROM mp_registered_supplier WHERE company_id = @CompanyId

							--- reset the fields
									UPDATE mp_companies
									SET IsEligibleForGrowthPackage = 1
									,IsGrowthPackageTaken = 0 
									,IsStarterPackageTaken = 0
									--,IsStarterFreeTrialTaken = 0  --- commented on 25 - jul 
									WHERE company_id = @CompanyId
									
						END
						ELSE
						BEGIN

								UPDATE mp_registered_supplier
								SET
									updated_on = GETUTCDATE()
									,account_type = @AccountTypeId 
									,account_type_source = 310
								WHERE company_id = @CompanyId
							END

						END

						-- adding manufacturer in directory datasync
						INSERT INTO XML_SupplierProfileCaptureChanges (CompanyId ,Event ,CreatedOn)
						SELECT @CompanyId ,@Event ,GETUTCDATE() 

						-- updating manufacturer growth package taken flag
						IF @AccountTypeId = 84
						BEGIN
							IF @SubscriptionStatus != 'canceled'
						UPDATE mp_companies SET IsEligibleForGrowthPackage =1 , IsGrowthPackageTaken = 1 WHERE company_id = @CompanyId
													
							IF @SubscriptionStatus = 'canceled'
							UPDATE mp_companies SET IsEligibleForGrowthPackage =1 , IsGrowthPackageTaken = 0 WHERE company_id = @CompanyId

						END
						IF @AccountTypeId = 313
						BEGIN
							--- Only 1st time user go for starter package then  IsStarterFreeTrialTaken = 1 and this field never update 
							IF @SubscriptionStatus = 'trialing'
							UPDATE mp_companies SET IsStarterFreeTrialTaken =1 WHERE company_id = @CompanyId

							IF @SubscriptionStatus != 'canceled'
							UPDATE mp_companies SET IsStarterPackageTaken =1 WHERE company_id = @CompanyId
								
							IF @SubscriptionStatus = 'canceled'
							UPDATE mp_companies SET IsStarterPackageTaken =0 WHERE company_id = @CompanyId
						END
						-- adding rfq qouting capatities as per plan for manufacturer
						IF @AccountTypeId = 84
						BEGIN
						
							INSERT INTO mp_gateway_subscription_company_processes (company_id ,part_category_id ,is_active)
							SELECT @CompanyId , part_category_id , 1 FROM [mp_gateway_subscription_products] (NOLOCK) a
							JOIN [mp_gateway_subscription_product_process_mappings] (NOLOCK) b
								ON a.id = b.ProductId
							JOIN [mp_mst_part_category] (NOLOCK) c
								ON b.PartCategoryId = c.parent_part_category_id
							WHERE a.id  = @SubscriptionProductRunningId 
								AND status_id = 2
								AND level = 1
						END

						
						SET @TransactionStatus =  'Success'
						SET @ErrorMessage = ''
						
					END
					ELSE
					BEGIN

						SET @TransactionStatus =  'Fail'
						SET @ErrorMessage = ERROR_MESSAGE()
		
					END

			END
			--  existing subscription
			ELSE IF @IsCompanyHasPreviousSubscription > 0  AND @SubscriptionProductRunningId > 0
			BEGIN
					--  adding manufacturer info related to subscription
					SET @SubscriptionCustomersRunningId = 
					(
						
						SELECT id
						FROM  mp_gateway_subscription_customers (NOLOCK) 
						WHERE supplier_id = @ContactId AND company_id = @CompanyId AND  gateway_id = 310
					
					)

					IF @SubscriptionCustomersRunningId > 0 
					BEGIN
						--  adding subscription info
						IF 
						((  
							SELECT COUNT(1) 
							FROM mp_gateway_subscriptions (NOLOCK) 
							WHERE 
								subscription_id =@SubscriptionId AND  customer_id = @SubscriptionCustomersRunningId 
								AND plan_id =@SubscriptionProductRunningId AND subscription_start = @SubscriptionStart AND subscription_end = @SubscriptionEnd 
								AND status = @SubscriptionStatus 
						)=0)
						BEGIN
							INSERT INTO mp_gateway_subscriptions
							(
								subscription_id ,customer_id ,plan_id ,next_billing_at 
								,subscription_start ,subscription_end
								,status ,created  ,PaymentStatus ,SessionStatus ,TotalAmout 
								,SubscriptionInterval ,SubscriptionIntervalCount ,InvoiceId,RequestType
							)
							SELECT @SubscriptionId ,@SubscriptionCustomersRunningId ,@SubscriptionProductRunningId 
							,DATEADD(day , @SubscriptionIntervalCount ,@SubscriptionStart) , @SubscriptionStart ,@SubscriptionEnd
							,@SubscriptionStatus ,GETUTCDATE() ,@PaymentStatus ,@SessionStatus ,@TotalAmout     	                
							,@SubscriptionInterval ,@SubscriptionIntervalCount ,@InvoiceId,@RequestType
						END
						
						-- adding in paid manufacturer master list
						IF (SELECT COUNT(1) FROM mp_registered_supplier  (NOLOCK)  WHERE company_id  = @CompanyId) = 0 
						BEGIN 
							IF @SubscriptionStatus = 'canceled'
							BEGIN
							--- reset the fields
								UPDATE mp_companies
									SET IsEligibleForGrowthPackage = 1
									,IsGrowthPackageTaken = 0 
									,IsStarterPackageTaken = 0
									---,IsStarterFreeTrialTaken = 0  --- commented on 25 - jul 
								WHERE company_id = @CompanyId
							END
							ELSE
							BEGIN
								INSERT INTO mp_registered_supplier (company_id ,is_registered ,created_on ,account_type ,account_type_source )
								SELECT @CompanyId ,1 ,GETUTCDATE() , @AccountTypeId , 310
							END 					
						END
						ELSE
						BEGIN
							 -- here need to check that if active subscription exists for that company 
							 -- then 
							IF @SubscriptionStatus = 'canceled'
							BEGIN
								 
									IF EXISTS 
									 (
										 SELECT TOP 1 b.id
										 FROM mp_gateway_subscription_customers (NOLOCK) a 
										 JOIN mp_gateway_subscriptions (NOLOCK) b on b.customer_id = a.id
										 where a.company_id = @CompanyID --17700231
										 AND CAST( GETUTCDATE()  AS DATE) BETWEEN CAST ( b.subscription_start AS DATE) AND CAST ( b.subscription_end AS DATE) 
										 AND b.[status] IN ( 'active','trialing')
										 ORDER BY b.id DESC
									 )
									 BEGIN
										
										IF @AccountTypeId = 313
										BEGIN
											UPDATE mp_companies	set IsEligibleForGrowthPackage = 1,IsStarterPackageTaken = 0 WHERE company_id = @CompanyId
											DELETE FROM mp_registered_supplier WHERE company_id = @CompanyId AND account_type = @AccountTypeId 
										END
										ELSE 
											DELETE FROM mp_registered_supplier WHERE company_id = @CompanyId
									 END
									 ELSE
									 BEGIN
									 
										--- convert this user to Basic so deleted from below table
										DELETE FROM mp_registered_supplier WHERE company_id = @CompanyId

										--- reset the fields
										UPDATE mp_companies
										set IsEligibleForGrowthPackage = 1
										,IsGrowthPackageTaken = 0 
										,IsStarterPackageTaken = 0
										---,IsStarterFreeTrialTaken = 0 --- commented on 25 - jul 
										where company_id = @CompanyId
									END
								END 
							ELSE
							BEGIN
							
								UPDATE mp_registered_supplier
								SET
									updated_on = GETUTCDATE()
									----,account_type = 84 
									,account_type = @AccountTypeId
									,account_type_source = 310
								WHERE company_id = @CompanyId
							END 
						 END 

						-- adding manufacturer in directory datasync
						IF @AccountTypeId = 84
						BEGIN
							INSERT INTO XML_SupplierProfileCaptureChanges (CompanyId ,Event ,CreatedOn)
							SELECT @CompanyId ,'paid_status_growth' ,GETUTCDATE() 
						END

						IF @AccountTypeId = 313
						BEGIN
							IF @SubscriptionStatus = 'canceled'
							BEGIN
								INSERT INTO XML_SupplierProfileCaptureChanges (CompanyId ,Event ,CreatedOn)
								SELECT @CompanyId ,'starter_package_canceled' ,GETUTCDATE() 
							END
							ELSE 
							BEGIN
								INSERT INTO XML_SupplierProfileCaptureChanges (CompanyId ,Event ,CreatedOn)
								SELECT @CompanyId ,'paid_status_starter' ,GETUTCDATE() 
							END 
						END
						-- updating manufacturer growth package taken flag
						IF @AccountTypeId = 84
						BEGIN
							IF @SubscriptionStatus != 'canceled'
							UPDATE mp_companies SET IsEligibleForGrowthPackage =1 , IsGrowthPackageTaken = 1 WHERE company_id = @CompanyId

							IF @SubscriptionStatus = 'canceled'
							UPDATE mp_companies SET IsEligibleForGrowthPackage =1 , IsGrowthPackageTaken = 0 WHERE company_id = @CompanyId

						END
						IF @AccountTypeId = 313
						BEGIN
							
							IF @SubscriptionStatus != 'canceled'
							UPDATE mp_companies SET IsStarterPackageTaken =1 WHERE company_id = @CompanyId
													
							IF @SubscriptionStatus = 'canceled'
							UPDATE mp_companies SET IsStarterPackageTaken =0 WHERE company_id = @CompanyId
						END
						/* M2 4888 / 4685 if recurring subscription then don't need to create data for rfq quoting capability
							---- adding rfq qouting capatities as per plan for manufacturer
							--INSERT INTO mp_gateway_subscription_company_processes (company_id ,part_category_id ,is_active)
							--SELECT @CompanyId , part_category_id , 1 FROM [mp_gateway_subscription_products] (NOLOCK) a
							--JOIN [mp_gateway_subscription_product_process_mappings] (NOLOCK) b
							--	ON a.id = b.ProductId
							--JOIN [mp_mst_part_category] (NOLOCK) c
							--	ON b.PartCategoryId = c.parent_part_category_id
							--WHERE a.id  = @SubscriptionProductRunningId 
							--	AND status_id = 2
							--	AND level = 1
						*/
							/* below code added if later growth package taken from any users with M2-5133 */
							IF NOT EXISTS 
							(
								SELECT company_id FROM mp_gateway_subscription_company_processes  WHERE company_id = @CompanyId
							)
							BEGIN
								INSERT INTO mp_gateway_subscription_company_processes (company_id ,part_category_id ,is_active)
								SELECT @CompanyId , part_category_id , 1 FROM [mp_gateway_subscription_products] (NOLOCK) a
								JOIN [mp_gateway_subscription_product_process_mappings] (NOLOCK) b
									ON a.id = b.ProductId
								JOIN [mp_mst_part_category] (NOLOCK) c
									ON b.PartCategoryId = c.parent_part_category_id
								WHERE a.id  = @SubscriptionProductRunningId 
									AND status_id = 2
									AND level = 1
							END

						SET @TransactionStatus =  'Success'
						SET @ErrorMessage = ''
					END
					ELSE
					BEGIN
						SET @TransactionStatus =  'Fail'
						SET @ErrorMessage = ERROR_MESSAGE()
					END

			END
			ELSE 
			BEGIN
				SET @TransactionStatus =  'Success'
			END

			IF @TransactionStatus = 'Success' OR  @TransactionStatus = '' 
			BEGIN				
				COMMIT
			END
			ELSE IF @TransactionStatus = 'Fail' 
			BEGIN				
				ROLLBACK
			END

		
			SELECT @TransactionStatus AS TransactionStatus , @ErrorMessage  ErrorMessage
		
		END TRY
		BEGIN CATCH
			
			SET @TransactionStatus =  'Fail'
			SET @ErrorMessage = ERROR_MESSAGE()

			ROLLBACK
			SELECT @TransactionStatus AS TransactionStatus , @ErrorMessage  ErrorMessage

		END CATCH
	
END
