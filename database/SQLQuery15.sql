
USE [SessionFinancialBankDB];
GO

SELECT
    OBJECT_NAME(parent_object_id) AS TableName,
    name AS ConstraintName,
    definition AS ConstraintDefinition
FROM sys.check_constraints
WHERE parent_object_id IN
(
    OBJECT_ID('dbo.DetectionResults'),
    OBJECT_ID('dbo.Alerts'),
    OBJECT_ID('dbo.ResponseActions')
)
ORDER BY
    TableName,
    ConstraintName;
GO
