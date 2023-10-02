/*
declare @p28 dbo.tbltype_ListOfTerritories

insert into @p28 values (2) ,(4) 

exec proc_get_states_by_territory @territories=@p28

*/

CREATE procedure proc_get_states_by_territory 
(
	@territories	as tbltype_ListOfTerritories		readonly
)
as
begin
	/*
	===============================================================================================
	Create date:	Nov 18,2019
	Description:	M2-2298 My RFQs filter/search bugs, selecting existing filter does not update, 
					clearing all filters shows limited results, initial results appear limited-DB
	Modification:		 
	===============================================================================================
	*/
	
	set nocount on

	declare @territorylist table (territotyid int);

	-- if input territory contains usa & canada (7), then adding usa (4) and canada (5) in the list of territories
	if ((select count(1) from @territories where territoryid = 7 ) > 0 )
	begin
		insert into @territorylist (territotyid)
		select * from @territories
		union
		select 4 as usa_territory
		union
		select 5 as canada_territory
	end
	else
	begin
		insert into @territorylist (territotyid)
		select * from @territories
	end
	
	select distinct
		b.region_id as RegionId
		,b.region_name as RegionName
		,a.country_id as CountryId
		,a.territory_classification_id as TerritoryId 	
	from
	mp_mst_country		(nolock) a
	join mp_mst_region	(nolock) b 	on a.country_id = b.country_id
	where a.territory_classification_id in  (select * from @territorylist)
	order by  TerritoryId, CountryId ,  RegionName
	

end
