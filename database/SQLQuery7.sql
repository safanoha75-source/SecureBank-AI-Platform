USE [SessionFinancialBankDB];
GO

SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    c.column_id AS ColumnOrder,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length AS MaxLength,
    c.precision AS PrecisionValue,
    c.scale AS ScaleValue,
    c.is_nullable AS IsNullable,
    c.is_identity AS IsIdentity,
    dc.definition AS DefaultValue
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
    ON t.schema_id = s.schema_id
INNER JOIN sys.columns AS c
    ON t.object_id = c.object_id
INNER JOIN sys.types AS ty
    ON c.user_type_id = ty.user_type_id
LEFT JOIN sys.default_constraints AS dc
    ON c.default_object_id = dc.object_id
WHERE t.name IN
(
    'BankTransactions',
    'SecurityEvents',
    'DetectionResults',
    'ModelEvaluations',
    'Alerts',
    'ResponseActions',
    'AgentAssessments',
    'NotificationOutbox',
    'Accounts',
    'Customers'
)
ORDER BY
    t.name,
    c.column_id;