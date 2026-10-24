--CREATING VIEWS
CREATE VIEW vw_ChurnData AS
    SELECT * FROM new_Churn WHERE Customer_Status In ('Churned', 'Stayed');

CREATE VIEW vw_JoinData AS
    SELECT * FROM new_Churn WHERE Customer_Status = 'Joined';