USE SecureBank_DB;
GO

-- إنشاء جدول سجلات معاملات الاحتيال المالي المتقدمة
IF OBJECT_ID('Transaction_Fraud_Logs', 'U') IS NOT NULL
    DROP TABLE Transaction_Fraud_Logs;
GO

CREATE TABLE Transaction_Fraud_Logs (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT FOREIGN KEY REFERENCES Customers(CustomerID),
    Amount DECIMAL(18,2),
    Location NVARCHAR(100),
    IPAddress NVARCHAR(50),
    RiskScore FLOAT,
    IsFraud BIT,
    DetectedAt DATETIME DEFAULT GETDATE()
);
GO