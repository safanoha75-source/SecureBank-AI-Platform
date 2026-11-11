
USE [SessionFinancialBankDB];
GO

WITH RawData AS
(
    SELECT
        TransactionID,
        DatasetSplit,
        TransactionType,
        Amount,
        SourceStep,
        ActualFraudLabel,
        CASE
            WHEN ISJSON(SourcePayloadJson) = 1
            THEN SourcePayloadJson
            ELSE N'{}'
        END AS Payload
    FROM dbo.BankTransactions
    WHERE SourceSystem = 'PAYSIM'
),
Extracted AS
(
    SELECT
        *,
        JSON_VALUE(Payload, '$.amount') AS JAmount,
        JSON_VALUE(Payload, '$.type') AS JType,
        JSON_VALUE(Payload, '$.oldbalanceorg') AS JOldOrig,
        JSON_VALUE(Payload, '$.newbalanceorig') AS JNewOrig,
        JSON_VALUE(Payload, '$.oldbalancedest') AS JOldDest,
        JSON_VALUE(Payload, '$.newbalancedest') AS JNewDest,
        JSON_VALUE(Payload, '$.step') AS JStep
    FROM RawData
),
Parsed AS
(
    SELECT
        *,
        TRY_CONVERT(DECIMAL(38,10), JAmount) AS AmountValue,
        TRY_CONVERT(DECIMAL(38,10), JOldOrig) AS OldOrigValue,
        TRY_CONVERT(DECIMAL(38,10), JNewOrig) AS NewOrigValue,
        TRY_CONVERT(DECIMAL(38,10), JOldDest) AS OldDestValue,
        TRY_CONVERT(DECIMAL(38,10), JNewDest) AS NewDestValue,
        TRY_CONVERT(BIGINT, JStep) AS StepValue
    FROM Extracted
)
SELECT
    DatasetSplit,
    COUNT_BIG(*) AS TotalRows,

    SUM(CASE WHEN JAmount IS NOT NULL
        THEN 1 ELSE 0 END) AS HasAmount,

    SUM(CASE WHEN JType IS NOT NULL
        THEN 1 ELSE 0 END) AS HasType,

    SUM(CASE WHEN JOldOrig IS NOT NULL
        THEN 1 ELSE 0 END) AS HasOldOrig,

    SUM(CASE WHEN JNewOrig IS NOT NULL
        THEN 1 ELSE 0 END) AS HasNewOrig,

    SUM(CASE WHEN JOldDest IS NOT NULL
        THEN 1 ELSE 0 END) AS HasOldDest,

    SUM(CASE WHEN JNewDest IS NOT NULL
        THEN 1 ELSE 0 END) AS HasNewDest,

    SUM(CASE WHEN JStep IS NOT NULL
        THEN 1 ELSE 0 END) AS HasStep,

    SUM(CASE
        WHEN AmountValue IS NULL
          OR OldOrigValue IS NULL
          OR NewOrigValue IS NULL
          OR OldDestValue IS NULL
          OR NewDestValue IS NULL
          OR StepValue IS NULL
        THEN 1 ELSE 0
    END) AS InvalidNumericRows,

    SUM(CASE
        WHEN ABS(Amount - AmountValue) > 0.0001
        THEN 1 ELSE 0
    END) AS AmountMismatches,

    SUM(CASE
        WHEN TransactionType <> JType
          OR TransactionType IS NULL
        THEN 1 ELSE 0
    END) AS TypeMismatches,

    SUM(CASE
        WHEN SourceStep <> StepValue
          OR SourceStep IS NULL
        THEN 1 ELSE 0
    END) AS StepMismatches

FROM Parsed
GROUP BY DatasetSplit
ORDER BY DatasetSplit;
GO

-- Verify the five supported transaction categories.
SELECT
    TransactionType,
    COUNT_BIG(*) AS TransactionCount
FROM dbo.BankTransactions
WHERE SourceSystem = 'PAYSIM'
GROUP BY TransactionType
ORDER BY TransactionType;
GO
