
USE [SessionFinancialBankDB];
GO

SELECT
    SourceSystem,
    SourceRecordKey,
    COUNT_BIG(*) AS DuplicateCount
FROM dbo.BankTransactions
WHERE SourceSystem = 'PAYSIM'
  AND SourceRecordKey IS NOT NULL
GROUP BY
    SourceSystem,
    SourceRecordKey
HAVING COUNT_BIG(*) > 1
ORDER BY DuplicateCount DESC;
GO
