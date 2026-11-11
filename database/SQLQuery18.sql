USE SecureBank_DB;
GO

-- السماح بإدخال قيمة صريحة في عمود الـ ID
SET IDENTITY_INSERT Customers ON;

INSERT INTO Customers (CustomerID, FullName, Email, Phone, CreatedAt)
VALUES (1, 'نهى غريب', 'noha@securebank.com', '01000000000', GETDATE());

SET IDENTITY_INSERT Customers OFF;
GO