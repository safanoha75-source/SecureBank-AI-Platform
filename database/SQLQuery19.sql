USE SecureBank_DB;
GO

-- حذف الجدول القديم إن وجد لإنشائه بالهيكلة الصحيحة المتكاملة
IF OBJECT_ID('Security_Logs', 'U') IS NOT NULL
    DROP TABLE Security_Logs;
GO

-- إنشاء جدول سجلات الأمان والهجمات بالهيكلة الجديدة
CREATE TABLE Security_Logs (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT FOREIGN KEY REFERENCES Customers(CustomerID),
    ThreatType NVARCHAR(50),
    QueryText NVARCHAR(MAX),
    RiskScore FLOAT,
    IsAttack BIT,
    DetectedAt DATETIME DEFAULT GETDATE()
);
GO