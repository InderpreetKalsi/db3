


/*
	
		EXEC proc_set_HubspotToMFGCompanyQuotingCapabilityInstantSync
		1772113,'34556','Blow Molding;Woodworking'
		

*/ 

CREATE PROCEDURE [dbo].[proc_set_HubspotToMFGCompanyQuotingCapabilityInstantSync]
 (
	@CompanyID INT  = NULL
	,@HubSpotAccountId VARCHAR(100) 
    ,@QuotingCapability NVARCHAR(MAX) = NULL  
 )
AS
BEGIN
 		DROP TABLE IF EXISTS #CompanyQuotingCapability 
		DECLARE @MaxQuotingCapabilitiesAllowed INT , @AccountType INT = 83 --- default set to basic
		
		----get company account type   
		SELECT @AccountType = account_type FROM mp_registered_supplier(NOLOCK) WHERE company_id = @CompanyID
		
		---- for webhook log  entry tracking 
		INSERT INTO HubSpotWebhookCompanyQuotingCapabilityExecutionLogs (CompanyID,HubSpotAccountId,HubSpotQuotingCapability,WebhookType,AccountType)
		VALUES (@CompanyID,@HubSpotAccountId,@QuotingCapability,'CompanyQuotingCapability',@AccountType)
		
		----- split Quoting Capability into table
		SELECT value AS QuotingCapability INTO #CompanyQuotingCapability FROM string_split(@QuotingCapability,';')
			
		--- As per discussion with client only gold and platinum company set QuotingCapability and exclude growth account type 
		IF (@AccountType IN (85,86))
		BEGIN
			IF  (@QuotingCapability IS NULL OR @QuotingCapability = '' )
			BEGIN
			 
				BEGIN TRY
					BEGIN TRANSACTION
						--- deleted existing quoting capability of this company 
						DELETE FROM mp_gateway_subscription_company_processes WHERE company_id = @CompanyID

						---- Set the QuotingCapabilities count into mp_companies 
						UPDATE [mp_companies] SET [max_quoting_capabilities_allowed] = NULL
						WHERE [company_id] = @CompanyID

						---- Update this field HubSpotCompanies -> [Supplier Purchased Processes]  
						UPDATE DataSync_MarketplaceHubSpot..HubSpotCompanies
						SET  [Supplier Purchased Processes]   = NULL
						WHERE  [vision account id] = @CompanyID
						AND Synctype is null

						COMMIT TRANSACTION
					END TRY
					BEGIN CATCH
						ROLLBACK TRANSACTION
					END CATCH

			END
			ELSE
			BEGIN
		 
				IF (SELECT COUNT(1) FROM #CompanyQuotingCapability) > 0
				BEGIN
					BEGIN TRY
						BEGIN TRANSACTION
			
						---- Get the count of quoting capability
						SELECT @MaxQuotingCapabilitiesAllowed = COUNT(1) FROM #CompanyQuotingCapability

						--- deleted existing quoting capability of this company and assigned latest capability from hubspot
						DELETE FROM mp_gateway_subscription_company_processes WHERE company_id = @CompanyID

						--- inserted existing quoting capability of this company and assigned latest capability from hubspot
						INSERT INTO [mp_gateway_subscription_company_processes] ([company_id], [part_category_id])
						SELECT  @CompanyID AS company_id,   b.part_category_id
						FROM mp_mst_part_category (NOLOCK) a
						JOIN mp_mst_part_category (NOLOCK) b on a.part_category_id = b.parent_part_category_id and b.level = 1
						AND a.parent_part_category_id is NULL
						JOIN #CompanyQuotingCapability d on d.QuotingCapability = a.discipline_name 

						---- Set the QuotingCapabilities count into mp_companies 
						UPDATE [mp_companies] SET [max_quoting_capabilities_allowed] = @MaxQuotingCapabilitiesAllowed
						WHERE [company_id] = @CompanyID;
				 
						 ---- Update this field HubSpotCompanies -> [Supplier Purchased Processes]  
						UPDATE DataSync_MarketplaceHubSpot..HubSpotCompanies
						SET  [Supplier Purchased Processes]   = @QuotingCapability
						WHERE  [vision account id] = @CompanyID
						AND Synctype is null

						COMMIT TRANSACTION
					END TRY
					BEGIN CATCH
						ROLLBACK TRANSACTION
					END CATCH
				END
			END
		END  ---- (@AccountType IN (85,86))

		IF (@AccountType = 83)
		BEGIN
			BEGIN TRY
				BEGIN TRANSACTION
					--- deleted existing quoting capability of this company 
					DELETE FROM mp_gateway_subscription_company_processes WHERE company_id = @CompanyID

					---- Set the QuotingCapabilities count into mp_companies 
					UPDATE [mp_companies] SET [max_quoting_capabilities_allowed] = NULL
					WHERE [company_id] = @CompanyID

					---- Update this field HubSpotCompanies -> [Supplier Purchased Processes]  
					UPDATE DataSync_MarketplaceHubSpot..HubSpotCompanies
					SET  [Supplier Purchased Processes]   = NULL
					WHERE  [vision account id] = @CompanyID
					AND Synctype is null

				COMMIT TRANSACTION
			END TRY
			BEGIN CATCH
				ROLLBACK TRANSACTION
			END CATCH
		END
	
		
END
