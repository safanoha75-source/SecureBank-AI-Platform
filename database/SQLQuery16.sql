
USE [SessionFinancialBankDB];
GO

SELECT
    TransactionID,
    SourceSystem,
    IsDemo,
    TransactionType,
    Amount,
    ProcessingStatus,
    CASE
        WHEN SourcePayloadJson IS NULL THEN 'MISSING'
        WHEN ISJSON(SourcePayloadJson) = 1 THEN 'VALID_JSON'
        ELSE 'INVALID_JSON'
    END AS PayloadStatus,
    LEFT(SourcePayloadJson, 1200) AS PayloadSample
FROM dbo.BankTransactions
WHERE IsDemo = 1
ORDER BY TransactionID;
GO
