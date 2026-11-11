USE SessionFinancialBankDB;
GO
SELECT
    COUNT_BIG(*) AS TotalSecurityEvents
FROM dbo.SecurityEvents;

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'SecurityEvents'
ORDER BY ORDINAL_POSITION;

USE SessionFinancialBankDB;
GO

SELECT
    COUNT_BIG(*) AS TotalSecurityEvents
FROM dbo.SecurityEvents;

SELECT
    SourceSystem,
    EventSource,
    COUNT_BIG(*) AS TotalRecords
FROM dbo.SecurityEvents
GROUP BY
    SourceSystem,
    EventSource
ORDER BY TotalRecords DESC;
SELECT
    GroundTruthMalicious,
    EventFamily,
    SourceLabel,
    COUNT_BIG(*) AS TotalRecords
FROM dbo.SecurityEvents
WHERE SourceSystem = 'SQLI_DATASET'
  AND EventSource = 'SQLI'
GROUP BY
    GroundTruthMalicious,
    EventFamily,
    SourceLabel
ORDER BY TotalRecords DESC;

SELECT
    GroundTruthMalicious,
    EventFamily,
    SourceLabel,
    COUNT_BIG(*) AS TotalRecords
FROM dbo.SecurityEvents
WHERE SourceSystem = 'SQLI_DATASET'
  AND EventSource = 'SQLI'
GROUP BY
    GroundTruthMalicious,
    EventFamily,
    SourceLabel
ORDER BY TotalRecords DESC;

SELECT
    SourceRecordKey,
    COUNT_BIG(*) AS DuplicateCount
FROM dbo.SecurityEvents
WHERE SourceSystem = 'SQLI_DATASET'
  AND EventSource = 'SQLI'
GROUP BY SourceRecordKey
HAVING COUNT_BIG(*) > 1;