USE SessionFinancialBankDB;
GO

-- SQLI Dataset Quality Check
WITH SQLI AS
(
    SELECT *
    FROM dbo.SecurityEvents
    WHERE SourceSystem = 'SQLI_DATASET'
      AND EventSource = 'SQLI'
),
Duplicates AS
(
    SELECT
        SourceRecordKey,
        COUNT_BIG(*) AS DuplicateCount
    FROM SQLI
    GROUP BY SourceRecordKey
    HAVING COUNT_BIG(*) > 1
)
SELECT
    (SELECT COUNT_BIG(*) FROM SQLI) AS TotalRecords,

    (SELECT COUNT_BIG(*) FROM Duplicates)
        AS DuplicateGroups,

    (SELECT COALESCE(
        SUM(DuplicateCount - 1), 0
    ) FROM Duplicates) AS ExtraDuplicateRows,

    (SELECT COUNT_BIG(*) FROM SQLI
     WHERE SourceRecordKey IS NULL)
        AS MissingRecordKey,

    (SELECT COUNT_BIG(*) FROM SQLI
     WHERE GroundTruthMalicious IS NULL)
        AS MissingLabels,

    (SELECT COUNT_BIG(*) FROM SQLI
     WHERE FeatureJson IS NULL)
        AS MissingFeatureJson,

    (SELECT COUNT_BIG(*) FROM SQLI
     WHERE FeatureJson IS NOT NULL
       AND ISJSON(FeatureJson) = 0)
        AS InvalidJson;