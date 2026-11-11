-- =========================================================
-- SecureBank Database Schema
-- تصميم قواعد البيانات العلائقية لنظام الحماية والاحتيال
-- =========================================================

-- التأكد من إنشاء قاعدة البيانات والانتقال إليها
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'SecureBank_DB')
BEGIN
    CREATE DATABASE SecureBank_DB;
END
GO

USE SecureBank_DB;
GO

-- 1. جدول العملاء (Customers)
-- يحتوي على البيانات الأساسية لكل عميل في البنك
CREATE TABLE Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    FullName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    Phone NVARCHAR(20),
    CreatedAt DATETIME DEFAULT GETDATE()
);
GO

-- 2. جدول الحسابات البنكية (Accounts)
-- يربط العميل بحساباته المالية وأنواعها والرصيد
CREATE TABLE Accounts (
    AccountID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT FOREIGN KEY REFERENCES Customers(CustomerID) ON DELETE CASCADE,
    AccountType NVARCHAR(50) NOT NULL, -- مثال: 'Savings' أو 'Current'
    Balance DECIMAL(18, 2) NOT NULL DEFAULT 0.00,
    Status NVARCHAR(20) DEFAULT 'Active'
);
GO

-- 3. جدول المعاملات المالية (Transactions)
-- مخصص لنموذج كشف الاحتيال المالي (Fraud Detection Dataset)
CREATE TABLE Transactions (
    TransactionID INT IDENTITY(1,1) PRIMARY KEY,
    AccountID INT FOREIGN KEY REFERENCES Accounts(AccountID) ON DELETE CASCADE,
    Amount DECIMAL(18, 2) NOT NULL,
    TransactionTime DATETIME DEFAULT GETDATE(),
    DeviceRiskScore FLOAT NOT NULL, -- مؤشر خطورة الجهاز المستخدم في المعاملة
    Location NVARCHAR(50),          -- مكان إجراء المعاملة
    IsFraud BIT DEFAULT 0           -- 0 = معاملة سليمة، 1 = معاملة احتيالية
);
GO

-- 4. جدول السجلات الأمنية وهجمات الشبكة وحقن البيانات (Security_Logs)
-- مخصص لنموذجي SQL Injection و Network Attacks
CREATE TABLE Security_Logs (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT NULL FOREIGN KEY REFERENCES Customers(CustomerID),
    AttackType NVARCHAR(50) NOT NULL, -- مثال: 'SQL_Injection' أو 'Network_Attack'
    PayloadDetails NVARCHAR(MAX) NOT NULL, -- النص الخبيث أو تفاصيل حزمة الشبكة
    RiskScore FLOAT NOT NULL,
    LoggedAt DATETIME DEFAULT GETDATE()
);
GO