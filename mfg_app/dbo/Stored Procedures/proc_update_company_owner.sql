
CREATE PROCEDURE [dbo].[proc_update_company_owner]	 
	 @CompanyId INT,
	 @RegionCode VARCHAR(50) = Null,
	 @IsBuyer BIT = Null
AS
BEGIN
	

	insert into tempGeocodeLog values (@CompanyId,@RegionCode,@IsBuyer,getdate())

	DECLARE @Location varchar(50),@SourcingAdvisor int = Null;	 	 
	SELECT @Location = location from mp_region_advisor_lookup where region_code = @RegionCode   	 
    IF (@Location != '')
		BEGIN		 
			IF(@IsBuyer = 1)
				BEGIN
				IF(@Location = 'West')
				BEGIN
					SET @SourcingAdvisor = 1345421;					 
				END
				ELSE IF (@Location = 'East')
				BEGIN
					SET @SourcingAdvisor = 1577;					 
				END
				ELSE
				BEGIN
					SET @SourcingAdvisor = 1571;					 
				END

			END
			ELSE IF(@IsBuyer = 0)
					BEGIN
					IF(@Location = 'West')
						BEGIN
							SET @SourcingAdvisor = 1339475;
						END
					ELSE IF (@Location = 'East')
						BEGIN
							SET @SourcingAdvisor = 1584;
						END
					ELSE
						BEGIN
							SET @SourcingAdvisor = 1571;
						END
			END
		END                                    
    ELSE
		BEGIN
			SET @SourcingAdvisor = 1571
		END

	Update mp_companies SET  Assigned_SourcingAdvisor = @SourcingAdvisor where company_id  = @CompanyId;                   	 
 
	
END
