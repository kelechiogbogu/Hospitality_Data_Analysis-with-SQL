--Data Quality Check Before Exploration
--To view data
SELECT * FROM Hospitality

-- To check for duplicate rows
SELECT *, 
	ROW_NUMBER() OVER(PARTITION BY reservation_id
	ORDER BY reservation_id) AS Duplicate_row
FROM Hospitality;
-- To delete all duplicates
WITH HospitalityDataset AS
 (SELECT *, 
	ROW_NUMBER() OVER(PARTITION BY reservation_id
	ORDER BY reservation_id) AS Duplicate_row
FROM Hospitality)
DELETE FROM HospitalityDataset WHERE Duplicate_row >1

-- To convert Avg_Room_Rate data type to money
ALTER TABLE Hospitality
ALTER COLUMN Avg_Room_Rate money

-- To delete unwanted Column
ALTER TABLE Hospitality
DROP COLUMN Date

--To inspect some colums
SELECT DISTINCT room_type
FROM Hospitality

SELECT DISTINCT booking_channel
FROM Hospitality

SELECT DISTINCT special_requests_flag
FROM Hospitality

SELECT DISTINCT advanced_booking
FROM Hospitality

SELECT DISTINCT  Rate_Type
FROM Hospitality

SELECT DISTINCT  Property
FROM Hospitality

-- To change 1 to Yes and 0 to No in the special_requests_flag and advanced_booking columns
ALTER TABLE Hospitality
ALTER COLUMN special_requests_flag char(3) 

ALTER TABLE Hospitality
ALTER COLUMN advanced_booking char(3)

SELECT special_requests_flag,
	CASE WHEN special_requests_flag = 1 THEN 'Yes'
	      WHEN special_requests_flag = 0 THEN 'No'
		  END
FROM Hospitality 

UPDATE Hospitality
	SET special_requests_flag = CASE WHEN special_requests_flag = 1 THEN 'Yes'
	      WHEN special_requests_flag = 0 THEN 'No'
		  END

		 
SELECT advanced_booking,
	CASE WHEN advanced_booking = 1 THEN 'Yes'
		WHEN advanced_booking = 0 THEN 'No' 
		END
FROM Hospitality

UPDATE Hospitality
SET advanced_booking = CASE WHEN advanced_booking = 1 THEN 'Yes'
		WHEN advanced_booking = 0 THEN 'No' 
		END
SELECT * FROM Hospitality

-- To change the check_in_date data type
ALTER TABLE Hospitality
ALTER COLUMN check_in_date datetime

-- To extract date name from date
SELECT DATENAME (WEEKDAY,check_in_date)
FROM Hospitality

-- To create a new column which will be populated with date name
ALTER TABLE Hospitality ADD check_in_day char(9)

--To populate the check_in_day column
UPDATE Hospitality
	SET check_in_day = DATENAME (WEEKDAY,check_in_date)
	
-- To ensure the Rate_Type values are correct
SELECT DISTINCT check_in_day
FROM Hospitality
WHERE Rate_Type = 'Weekend'

SELECT DISTINCT check_in_day
FROM Hospitality
WHERE Rate_Type = 'Weekday'

-- I have noticed an error in the Rate_Type column, Mondays check ins are recorded as Weekend rate type while Saturday checkins are recorded as Weekday rate type
-- To fix this error
UPDATE Hospitality
	SET Rate_Type = 'Weekday'
	WHERE check_in_day = 'Monday'

UPDATE Hospitality
	SET Rate_Type = 'Weekend'
	WHERE check_in_day = 'Saturday'

-- DATA EXPLORATION PROPER
-- To find number of check-in by days of the week
SELECT DATENAME(DW,check_in_date) AS Check_in_Day, DATEPART(DW,check_in_date -1) AS DayNo, COUNT(reservation_id) AS ReservationsCount 
FROM Hospitality
GROUP BY DATEPART(DW,check_in_date -1), DATENAME(DW,check_in_date)
ORDER BY 2

-- To find the number of checkins by month
SELECT DATENAME(MONTH,check_in_date) AS Check_in_Month, DATEPART(MONTH, check_in_date) AS MonthNo, COUNT(reservation_id) AS MonthlyReservations
FROM Hospitality
GROUP BY DATEPART(MONTH, check_in_date), DATENAME(MONTH,check_in_date)
ORDER BY 2


-- To show how each room type in different properties were checked into by weekdays 
--For The Chord
SELECT Property, check_in_day, room_type,
 COUNT(reservation_id)
 OVER(PARTITION BY check_in_day, room_type) ReservationCount
FROM Hospitality
WHERE Property = 'The Chord'

WITH TheChord AS (SELECT Property, check_in_day, room_type,
 COUNT(reservation_id)
 OVER(PARTITION BY check_in_day, room_type) ReservationCount
FROM Hospitality
WHERE Property = 'The Chord')
SELECT DISTINCT check_in_day, room_type, ReservationCount FROM TheChord
ORDER BY 1,2,3

--For The Sankey
SELECT Property, check_in_day, room_type,
 COUNT(reservation_id) 
 OVER(PARTITION BY check_in_day, room_type) ReservationCount
FROM Hospitality
WHERE Property = 'The Sankey'

WITH TheSankey AS (SELECT Property, check_in_day, room_type,
 COUNT(reservation_id)
 OVER(PARTITION BY check_in_day, room_type) ReservationCount
FROM Hospitality
WHERE Property = 'The Sankey')
SELECT DISTINCT check_in_day, room_type, ReservationCount FROM TheSankey
ORDER BY 1,2,3

--For The Marimekko
SELECT Property, check_in_day, room_type,
 COUNT(reservation_id) 
 OVER(PARTITION BY check_in_day, room_type) ReservationCount
FROM Hospitality
WHERE Property = 'The Marimekko'

WITH TheMarimekko AS (SELECT Property, check_in_day, room_type,
 COUNT(reservation_id)
 OVER(PARTITION BY check_in_day, room_type) ReservationCount
FROM Hospitality
WHERE Property = 'The Marimekko')
SELECT DISTINCT check_in_day, room_type, ReservationCount FROM TheMarimekko
ORDER BY 1,2,3


--Which booking channel do customers use more?
SELECT booking_channel, COUNT(*) * 100.0/SUM(COUNT(*)) OVER() As booking_channel_percentage
FROM Hospitality
GROUP BY booking_channel
ORDER BY booking_channel_percentage DESC

-- Is there a correlation between the price and the room type?
SELECT room_type, AVG(Avg_Room_Rate) Avg_price, COUNT(*) * 100.0/SUM(COUNT(*)) OVER() As check_in_percentage_room_type
FROM Hospitality
GROUP BY room_type
ORDER BY check_in_percentage_room_type ASC

--To check if there is correlation between the price and the room type in the different properties
SELECT room_type, AVG(Avg_Room_Rate) Avg_price, COUNT(*) * 100.0/SUM(COUNT(*)) OVER() As check_in_percentage_room_type
FROM Hospitality
WHERE Property = 'The Chord'
GROUP BY room_type
ORDER BY check_in_percentage_room_type ASC

SELECT room_type, AVG(Avg_Room_Rate) Avg_price, COUNT(*) * 100.0/SUM(COUNT(*)) OVER() As check_in_percentage_room_type
FROM Hospitality
WHERE Property = 'The Marimekko'
GROUP BY room_type
ORDER BY check_in_percentage_room_type ASC

SELECT room_type, AVG(Avg_Room_Rate) Avg_price, COUNT(*) * 100.0/SUM(COUNT(*)) OVER() As check_in_percentage_room_type
FROM Hospitality
WHERE Property = 'The Sankey'
GROUP BY room_type
ORDER BY check_in_percentage_room_type ASC

-- To find the property with the least Check in and the Average price
SELECT Property, COUNT(*) * 100.0/SUM(COUNT(*)) OVER() As Property_Percentage
FROM Hospitality
GROUP BY Property
ORDER BY Property_Percentage ASC

-- To find the percentage of advanced booking
SELECT advanced_booking, COUNT(*) * 100.0/SUM(COUNT(*)) OVER() As booking_type_pecentage
FROM Hospitality
GROUP BY advanced_booking

-- To find the average stay duration in different properties
SELECT Property, AVG(stay_duration) Average_stay
FROM Hospitality
GROUP BY Property

--To find the minimum and maximum stay duration
SELECT MAX(stay_duration) as Maximun, MIN(stay_duration) as Minimum
FROM Hospitality

-- To check if there is a correlation between room price and stay duration
SELECT stay_duration, AVG(Avg_Room_Rate) as Average_Price
FROM Hospitality
GROUP BY stay_duration

-- To find the average stay duration in different room types
SELECT room_type, AVG(stay_duration) Average_stay_By_RoomType
FROM Hospitality
GROUP BY room_type

--To find the percentage of customers according to stay duration
SELECT stay_duration, COUNT(reservation_id) num_ofcheck_ins, COUNT(reservation_id) * 100.0/ SUM(COUNT(reservation_id)) OVER() percentage_of_checkin
FROM Hospitality
GROUP BY stay_duration
ORDER BY percentage_of_checkin DESC

-- To find the maximum and minimum muber of occupants 
SELECT MAX(adults + children) as Maximun, MIN(adults + children)
FROM Hospitality

-- To find if there is a correlation between number of occupants and room type
SELECT room_type, AVG(adults + children) Occupants
FROM Hospitality
GROUP BY room_type

--What is the Total Revenue generated by the business?
SELECT SUM(Avg_Room_Rate * stay_duration) TotalRevenue
FROM Hospitality

-- Which room type brought in the highest revenue?
SELECT TOP 1 room_type, MAX(SUM(Avg_Room_Rate * stay_duration)) OVER() Total_Revenue
FROM Hospitality
GROUP BY room_type

-- Which Property brought in the highest revenue?
SELECT TOP 1 Property, MAX(SUM(Avg_Room_Rate * stay_duration)) OVER() TotalRvenueByPropety
FROM Hospitality
GROUP BY Property 

-- Which room type brought in the highest revenue for the different properties?
-- The Chord
SELECT room_type, SUM(Avg_Room_Rate * stay_duration) TheChord_Total_Revenue
FROM Hospitality
WHERE Property = 'The Chord'
GROUP BY room_type
ORDER BY TheChord_Total_Revenue DESC

-- The Marimekko
SELECT room_type, SUM(Avg_Room_Rate * stay_duration) TheMarimekko_Total_Revenue
FROM Hospitality
WHERE Property = 'The Marimekko'
GROUP BY room_type
ORDER BY TheMarimekko_Total_Revenue DESC

-- The Sankey
SELECT room_type, SUM(Avg_Room_Rate * stay_duration) TheSankey_Total_Revenue
FROM Hospitality
WHERE Property = 'The Sankey'
GROUP BY room_type
ORDER BY TheSankey_Total_Revenue DESC

--To show daily check in trends in the different properties
SELECT check_in_day, COUNT(Property)
FROM Hospitality
WHERE Property = 'The Sankey'
GROUP BY check_in_day
ORDER BY COUNT(Property) DESC

SELECT check_in_day, COUNT(Property)
FROM Hospitality
WHERE Property = 'The Chord'
GROUP BY check_in_day
ORDER BY COUNT(Property) DESC

SELECT check_in_day, COUNT(Property)
FROM Hospitality
WHERE Property = 'The Marimekko'
GROUP BY check_in_day
ORDER BY COUNT(Property) DESC

-- Showing what percentage of the customers made special requests
SELECT special_requests_flag, COUNT(special_requests_flag)*100.0 / SUM(COUNT(special_requests_flag)) OVER() SpecialRequestsPercent
FROM Hospitality
GROUP BY special_requests_flag

-- To Find checkins without children
SELECT children, COUNT(reservation_id) reservations
FROM Hospitality
WHERE children = 0
GROUP BY children
