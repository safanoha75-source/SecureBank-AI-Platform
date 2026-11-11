
USE [SessionFinancialBankDB];
GO

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
ORDER BY d.CreatedAt DESC;
GO
