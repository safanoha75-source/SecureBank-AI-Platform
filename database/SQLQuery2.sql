USE SessionFinancialBankDB;
GO

SELECT
    SourceSystem,
    DatasetSplit,
    IsDemo,
    COUNT_BIG(*) AS TransactionCount,
    SUM(CONVERT(BIGINT, ActualFraudLabel)) AS FraudCount
FROM dbo.BankTransactions
WHERE SourceSystem = 'PAYSIM'
GROUP BY
    SourceSystem,
    DatasetSplit,
    IsDemo
ORDER BY DatasetSplit;
GO

SELECT
    COUNT_BIG(*) AS TotalRows,
    COUNT(DISTINCT SourceRecordKey) AS UniqueSourceRecords
FROM dbo.BankTransactions
WHERE SourceSystem = 'PAYSIM';
GO