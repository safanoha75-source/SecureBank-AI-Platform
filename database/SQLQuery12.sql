
USE [SessionFinancialBankDB];
GO

/* =====================================================
   A. DETECTION RESULTS: WHAT MODELS ALREADY RAN?
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

    SUM(CASE
        WHEN TransactionID IS NOT NULL THEN 1 ELSE 0
    END) AS LinkedTransactions,

    SUM(CASE
        WHEN SecurityEventID IS NOT NULL THEN 1 ELSE 0
    END) AS LinkedSecurityEvents

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
   B. DETAILS OF EXISTING DETECTION RESULTS
   ===================================================== */

SELECT
    d.DetectionResultID,
    d.TransactionID,
    b.SourceSystem,
    b.DatasetSplit,
    b.ActualFraudLabel,
    d.DetectorType,
    d.PredictedLabel,
    d.ScoreValue,
    d.ScoreSemantics,
    d.ThresholdValue,
    d.RiskLevel,
    d.ModelName,
    d.ModelVersion,
    d.IsDemo,
    d.CreatedAt

FROM dbo.DetectionResults AS d

LEFT JOIN dbo.BankTransactions AS b
    ON d.TransactionID = b.TransactionID

ORDER BY d.DetectionResultID;


/* =====================================================
   C. SOURCE PAYLOAD COMPLETENESS
   ===================================================== */

SELECT
    SourceSystem,
    DatasetSplit,

    COUNT_BIG(*) AS TotalRows,

    SUM(CASE
        WHEN ISJSON(SourcePayloadJson) = 1
        THEN 1 ELSE 0
    END) AS ValidJsonRows,

    SUM(CASE
        WHEN ISJSON(SourcePayloadJson) = 1
         AND JSON_VALUE(
             SourcePayloadJson, '$.oldbalanceOrg'
         ) IS NOT NULL
        THEN 1 ELSE 0
    END) AS HasOldBalanceOrig,

    SUM(CASE
        WHEN ISJSON(SourcePayloadJson) = 1
         AND JSON_VALUE(
             SourcePayloadJson, '$.newbalanceOrig'
         ) IS NOT NULL
        THEN 1 ELSE 0
    END) AS HasNewBalanceOrig,

    SUM(CASE
        WHEN ISJSON(SourcePayloadJson) = 1
         AND JSON_VALUE(
             SourcePayloadJson, '$.oldbalanceDest'
         ) IS NOT NULL
        THEN 1 ELSE 0
    END) AS HasOldBalanceDest,

    SUM(CASE
        WHEN ISJSON(SourcePayloadJson) = 1
         AND JSON_VALUE(
             SourcePayloadJson, '$.newbalanceDest'
         ) IS NOT NULL
        THEN 1 ELSE 0
    END) AS HasNewBalanceDest,

    SUM(CASE
        WHEN ISJSON(SourcePayloadJson) = 1
         AND JSON_VALUE(
             SourcePayloadJson, '$.isFlaggedFraud'
         ) IS NOT NULL
        THEN 1 ELSE 0
    END) AS HasFlaggedFraud

FROM dbo.BankTransactions

WHERE SourceSystem = 'PAYSIM'

GROUP BY
    SourceSystem,
    DatasetSplit;


/* =====================================================
   D. SAMPLE ORIGINAL PAYLOADS
   ===================================================== */

SELECT TOP (3)
    TransactionID,
    SourceRecordKey,
    TransactionType,
    Amount,
    SourceStep,
    ActualFraudLabel,
    LEFT(SourcePayloadJson, 1500) AS PayloadSample

FROM dbo.BankTransactions

WHERE SourceSystem = 'PAYSIM'

ORDER BY TransactionID;


/* =====================================================
   E. HISTORICAL MODEL EVALUATIONS
   ===================================================== */

SELECT
    ModelEvaluationID,
    DetectorType,
    ModelName,
    ModelVersion,
    DatasetName,
    EvaluationSplit,
    PrecisionValue,
    RecallValue,
    F1Value,
    AveragePrecision,
    ThresholdValue,
    ScoreSemantics,
    IsHistoricalReference,
    EvaluatedAt

FROM dbo.ModelEvaluations

ORDER BY EvaluatedAt DESC;
GO
