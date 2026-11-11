
USE [SessionFinancialBankDB];
GO

/* =====================================================
   01 - BANK TRANSACTIONS SOURCE SUMMARY
   ===================================================== */

SELECT
    SourceSystem,
    DatasetSplit,
    IsDemo,
    ProcessingStatus,
    COUNT_BIG(*) AS TotalRows,
    SUM(CASE WHEN ActualFraudLabel = 1 THEN 1 ELSE 0 END) AS FraudRows,
    SUM(CASE WHEN ActualFraudLabel = 0 THEN 1 ELSE 0 END) AS NormalRows,
    SUM(CASE WHEN ActualFraudLabel IS NULL THEN 1 ELSE 0 END) AS MissingLabels,
    MIN(OccurredAt) AS FirstTransaction,
    MAX(OccurredAt) AS LastTransaction
FROM dbo.BankTransactions
GROUP BY
    SourceSystem,
    DatasetSplit,
    IsDemo,
    ProcessingStatus
ORDER BY
    SourceSystem,
    DatasetSplit;


/* =====================================================
   02 - FRAUD / NORMAL DISTRIBUTION
   ===================================================== */

SELECT
    SourceSystem,
    DatasetSplit,
    ActualFraudLabel,
    IsDemo,
    COUNT_BIG(*) AS RecordCount
FROM dbo.BankTransactions
GROUP BY
    SourceSystem,
    DatasetSplit,
    ActualFraudLabel,
    IsDemo
ORDER BY
    SourceSystem,
    DatasetSplit,
    ActualFraudLabel;


/* =====================================================
   03 - DUPLICATE SOURCE RECORD KEYS
   ===================================================== */

WITH KeyCounts AS
(
    SELECT
        SourceSystem,
        SourceRecordKey,
        COUNT_BIG(*) AS DuplicateRows
    FROM dbo.BankTransactions
    WHERE SourceRecordKey IS NOT NULL
    GROUP BY
        SourceSystem,
        SourceRecordKey
)
SELECT TOP (100)
    SourceSystem,
    SourceRecordKey,
    DuplicateRows
FROM KeyCounts
WHERE DuplicateRows > 1
ORDER BY DuplicateRows DESC;


/* =====================================================
   06 - DETECTION RESULTS SUMMARY
   ===================================================== */

SELECT
    DetectorType,
    ModelName,
    ModelVersion,
    ScoreSemantics,
    RiskLevel,
    PredictedLabel,
    IsDemo,
    COUNT_BIG(*) AS ResultCount,
    SUM(CASE WHEN TransactionID IS NOT NULL THEN 1 ELSE 0 END) AS LinkedTransactions,
    SUM(CASE WHEN SecurityEventID IS NOT NULL THEN 1 ELSE 0 END) AS LinkedSecurityEvents,
    MIN(ScoreValue) AS MinimumScore,
    MAX(ScoreValue) AS MaximumScore,
    MIN(ThresholdValue) AS MinimumThreshold,
    MAX(ThresholdValue) AS MaximumThreshold
FROM dbo.DetectionResults
GROUP BY
    DetectorType,
    ModelName,
    ModelVersion,
    ScoreSemantics,
    RiskLevel,
    PredictedLabel,
    IsDemo
ORDER BY
    DetectorType,
    ModelName;


/* =====================================================
   08 - SECURITY EVENTS SOURCE SUMMARY
   ===================================================== */

SELECT
    SourceSystem,
    EventSource,
    EventFamily,
    SourceLabel,
    GroundTruthMalicious,
    IsDemo,
    COUNT_BIG(*) AS EventCount,
    MIN(CapturedAt) AS FirstEvent,
    MAX(CapturedAt) AS LastEvent
FROM dbo.SecurityEvents
GROUP BY
    SourceSystem,
    EventSource,
    EventFamily,
    SourceLabel,
    GroundTruthMalicious,
    IsDemo
ORDER BY
    SourceSystem,
    EventFamily;


/* =====================================================
   09 - ALERTS SUMMARY
   ===================================================== */

SELECT
    d.DetectorType,
    d.ModelName,
    d.RiskLevel,
    a.AlertType,
    a.Severity,
    a.AlertStatus,
    a.SimulatedHold,
    COUNT_BIG(*) AS AlertCount
FROM dbo.Alerts AS a
LEFT JOIN dbo.DetectionResults AS d
    ON a.DetectionResultID = d.DetectionResultID
GROUP BY
    d.DetectorType,
    d.ModelName,
    d.RiskLevel,
    a.AlertType,
    a.Severity,
    a.AlertStatus,
    a.SimulatedHold
ORDER BY
    d.DetectorType,
    d.ModelName,
    d.RiskLevel;
GO
