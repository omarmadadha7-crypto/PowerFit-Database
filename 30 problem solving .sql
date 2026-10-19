
-- 2 Get all vehicles made between 1950 and 2000

select *from VehicleMasterDetails where Year between 1990 and 2022;



-- 3 Get number vehicles made between 1950 and 2000

select count(*) from VehicleMasterDetails where Year between 1990 and 2022;


-- 4 Get number vehicles made between 1950 and 2000 per make and order them by Number Of Vehicles Descending

SELECT Makes.Make  ,NumberOfVehicles=COUNT(*) FROM VehicleDetails 
inner join Makes on VehicleDetails.MakeID = Makes.MakeID
WHERE Year BETWEEN 1950 AND 2000
Group by Makes.Make
ORDER BY NumberOfVehicles DESC


-- 5 Get All Makes that have manufactured more than 12000 Vehicles in years 1950 to 2000

SELECT Makes.Make  ,NumberOfVehicles=COUNT(*) FROM VehicleDetails 
inner join Makes on VehicleDetails.MakeID = Makes.MakeID
WHERE Year BETWEEN 1950 AND 2000
Group by Makes.Make
having count (*)>12000
ORDER BY NumberOfVehicles DESC





-- 6 Get number of vehicles made between 1950 and 2000 per make and add total vehicles column beside


Select Makes.Make,NumberOfVehicles = Count(*),
TotalVehicles = 
(
	Select Count(*) as NumberOfVehicles from VehicleDetails
)
from VehicleDetails inner join Makes
On VehicleDetails.MakeID = Makes.MakeID
where VehicleDetails.Year between 1950 and 2000

group by Makes.Make
order by NumberOfVehicles desc


-- 7 Get number of vehicles made between 1950 and 2000 per make and add total vehicles column beside it, then calculate it's percentage


select Makes.Make, NumberOfVehicles = count(*),
TotalVehicles = (Select Count(*) as NumberOfVehicles from VehicleDetails ),
 
Percentage = Cast (Count(*)as float /*NumberOfVehicles*/ ) / (	Select Count(*) from VehicleDetails	/*TotalVehicles*/ ) 

from VehicleDetails inner join Makes
On VehicleDetails.MakeID = Makes.MakeID
where VehicleDetails.Year between 1950 and 2000

group by Makes.Make
order by NumberOfVehicles desc



--- 8 Get Make, FuelTypeName and Number of Vehicles per FuelType per Make



select Makes.Make , FuelTypes.FuelTypeName,NumberofVehicles = count(*) from VehicleDetails

inner join Makes On VehicleDetails.MakeID = Makes.MakeID

inner join FuelTypes on VehicleDetails.FuelTypeID = FuelTypes.FuelTypeID
where VehicleDetails.Year between 1950 and 2000
group by Makes.Make, FuelTypes.FuelTypeName
order by Makes.Make




-- 9 Get all vehicles that runs with GAS



select  VehicleDetails.*, FuelTypes.FuelTypeName  from VehicleDetails
inner join FuelTypes on VehicleDetails.FuelTypeID = FuelTypes.FuelTypeID
where FuelTypes.FuelTypeName = N'GAS'


-- 10 Get Total Makes that runs with GAS

SELECT  Makes.Make , FuelTypes.FuelTypeName 
FROM VehicleDetails 
INNER JOIN Makes
ON VehicleDetails.MakeID=Makes.MakeID
INNER JOIN FuelTypes
ON VehicleDetails.FuelTypeID=FuelTypes.FuelTypeID
WHERE FuelTypes.FuelTypeName =N'GAS'
GROUP BY Makes.Make,FuelTypes.FuelTypeName ;  


-- 11 Get Total Makes that runs with GAS


SELECT COUNT(*) AS TotalRunsOnGas
FROM (
    SELECT Makes.Make, FuelTypes.FuelTypeName
    FROM VehicleDetails
    INNER JOIN Makes
        ON VehicleDetails.MakeID = Makes.MakeID
    INNER JOIN FuelTypes
        ON VehicleDetails.FuelTypeID = FuelTypes.FuelTypeID
    WHERE FuelTypes.FuelTypeName = N'GAS'
) R1;


-- 12 Count Vehicles by make and order them by NumberOfVehicles from high to low.


select Makes.Make , NumberOfVehicles= count (*) from VehicleDetails 
INNER JOIN Makes
     ON VehicleDetails.MakeID = Makes.MakeID
     group by Makes.Make
     order by NumberOfVehicles desc

  

  

  -- 13 Get all Makes/Count Of Vehicles that manufactures more than 20K Vehicles


  select Makes.Make,NumberOfVehicles=count(*) from VehicleDetails
INNER JOIN Makes
     ON VehicleDetails.MakeID = Makes.MakeID
     group by Makes.Make
     having count (*) > 20000
     order by NumberOfVehicles desc



     -- 14 Write a query to get all Makes with make starts with 'B'.


 select Makes.Make from Makes
 where Makes.Make like 'B%';










