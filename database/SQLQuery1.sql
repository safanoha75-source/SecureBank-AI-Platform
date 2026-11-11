
USE [SessionFinancialBankDB];
GO

SELECT d.*
FROM dbo.DetectionResults AS d
LEFT JOIN dbo.BankTransactions AS t
    ON t.TransactionID = d.TransactionID
LEFT JOIN dbo.SecurityEvents AS s
    ON s.SecurityEventID = d.SecurityEventID
WHERE
    (d.TransactionID IS NOT NULL AND t.TransactionID IS NULL)
    OR
    (d.SecurityEventID IS NOT NULL AND s.SecurityEventID IS NULL)
    OR
    (
        (d.TransactionID IS NULL AND d.SecurityEventID IS NULL)
        OR
        (d.TransactionID IS NOT NULL AND d.SecurityEventID IS NOT NULL)
    );
GO
