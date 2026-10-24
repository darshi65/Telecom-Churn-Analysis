-- CREATING ETL LOG
CREATE TABLE etl_log (
    Log_ID       INT IDENTITY(1,1) PRIMARY KEY,
    Load_Date    DATETIME2 DEFAULT GETDATE(),
    Rows_Loaded  INT,
    Notes        VARCHAR(200)
);

INSERT INTO etl_log (Rows_Loaded, Notes)
VALUES (@@ROWCOUNT, 'Manual load from Customer_Data');

SELECT * FROM Customer_Data;