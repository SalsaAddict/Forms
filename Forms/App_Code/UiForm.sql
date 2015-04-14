USE [Claimsuite]
GO

INSERT INTO [UiForm] ([Id], [Title], [SourceType], [Source])
VALUES
 (N'UiForm', N'Form', N'T', N'UiForm'),
	(N'UiFormTab', N'Tab', N'T', N'UiFormTab')
GO

INSERT INTO [UiFormKey] ([FormId], [Index], [Name])
VALUES
 (N'UiForm', 0, N'Id'),
	(N'UiFormTab', 0, N'FormId'),
	(N'UiFormTab', 1, N'Index')
GO

INSERT INTO [UiFormTab] ([FormId], [Index], [Title])
VALUES
 (N'UiForm', 0, N'Form Details'),
	(N'UiForm', 1, N'Data'),
	(N'UiFormTab', 0, N'Tab Details')
GO

INSERT INTO [UiFormField] ([FormId], [Id], [TabIndex], [Index], [Title], [Type], [Required])
VALUES
 (N'UiForm', N'Id', 0, 0, N'Form Id', N'txt', 1),
	(N'UiForm', N'Title', 0, 1, N'Form Title', N'txt', 1),
	(N'UiForm', N'SourceType', 1, 0, N'Source Type', N'ddn', 1),
	(N'UiForm', N'Source', 1, 1, N'Source', N'txt', 1)
GO

INSERT INTO [UiFormList] ([FormId], [TabIndex], [FieldIndex], [Name], [ValueField], [TextField])
VALUES
 (N'UiForm', 1, 0, N'pr_UiSourceType', N'Type', N'Description')
GO

EXEC [pr_UiForm] N'/forms/UiForm'
EXEC [pr_UiRoutes]
EXEC [pr_UiRead] N'UiForm'



