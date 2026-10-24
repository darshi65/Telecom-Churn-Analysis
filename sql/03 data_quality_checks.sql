-- QUALITY CHECKS
-- Find duplicate Customer_IDs in the raw staging data (should ideally be 0 rows)
SELECT Customer_ID, COUNT(*) AS Times_Seen
FROM Customer_Data
GROUP BY Customer_ID
HAVING COUNT(*) > 1;
-- Result : None

-- Find "Stayed" customers with 0 months tenure (usually a data entry oddity worth flagging)
SELECT Customer_ID, Tenure_in_Months, Customer_Status
FROM Customer_Data
WHERE Tenure_in_Months = 0 AND Customer_Status = 'Stayed';
-- Result : None

-- DATA EXPLORATION
-- Find Gender-wise percentage split
SELECT Gender, Count(Gender) as TotalCount,
Count(Gender) * 100.0 / (Select Count(*) from Customer_Data)  AS Percentage
from Customer_Data
Group by Gender;

-- Find percentage split of the different Contract types
SELECT Contract, Count(Contract) as TotalCount,
Count(Contract) * 100.0 / (Select Count(*) from Customer_Data)  as Percentage
from Customer_Data
Group by Contract;

-- Find split of different Customer statuses and the percentage of revenue incurred by each
SELECT Customer_Status, Count(Customer_Status) as TotalCount, Sum(Total_Revenue) as TotalRev,
Sum(Total_Revenue) / (Select sum(Total_Revenue) from Customer_Data) * 100  as RevPercentage
from Customer_Data
Group by Customer_Status;

-- Find Total Customer Count and Percentage split by State
SELECT State, Count(State) as TotalCount,
Count(State) * 100.0 / (Select Count(*) from Customer_Data)  as Percentage
from Customer_Data
Group by State
Order by Percentage desc;