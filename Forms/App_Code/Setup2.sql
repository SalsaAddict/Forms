--USE [master]; DROP DATABASE [Claimsuite]; CREATE DATABASE [Claimsuite]
USE [Claimsuite]
GO

IF OBJECT_ID(N'pr_UiForm', N'P') IS NOT NULL DROP PROCEDURE [pr_UiForm]
IF OBJECT_ID(N'UiFormField', N'U') IS NOT NULL DROP TABLE [UiFormField]
IF OBJECT_ID(N'UiFormFieldType', N'U') IS NOT NULL DROP TABLE [UiFormFieldType]
IF OBJECT_ID(N'UiFormTab', N'U') IS NOT NULL DROP TABLE [UiFormTab]
IF OBJECT_ID(N'UiForm', N'U') IS NOT NULL DROP TABLE [UiForm]
IF OBJECT_ID(N'UiSourceType', N'U') IS NOT NULL DROP TABLE [UiSourceType]
GO

CREATE TABLE [UiSourceType] (
  [Type] NCHAR(1) NOT NULL,
		[Description] NVARCHAR(25) NOT NULL,
		CONSTRAINT [PK_UiSourceType] PRIMARY KEY NONCLUSTERED ([Type]),
		CONSTRAINT [UQ_UiSourceType] UNIQUE CLUSTERED ([Description])
	)
GO

INSERT INTO [UiSourceType] ([Type], [Description])
VALUES
 (N'T', N'Table or View'),
	(N'F', N'Table-Valued Function'),
	(N'P', N'Stored Procedure')
GO

CREATE TABLE [UiForm] (
  [Id] NVARCHAR(50) NOT NULL,
		[Title] NVARCHAR(255) NOT NULL,
		[SourceType] NCHAR(1) NOT NULL,
		[Source] SYSNAME NOT NULL,
		CONSTRAINT [PK_UiForm] PRIMARY KEY CLUSTERED ([Id]),
		CONSTRAINT [FK_UiForm_UiSourceType] FOREIGN KEY ([SourceType]) REFERENCES [UiSourceType] ([Type])
	)
GO

CREATE TABLE [UiFormTab] (
  [FormId] NVARCHAR(50) NOT NULL,
		[Index] TINYINT NOT NULL,
		[Title] NVARCHAR(255) NOT NULL,
		CONSTRAINT [PK_UiFormTab] PRIMARY KEY CLUSTERED ([FormId], [Index]),
		CONSTRAINT [FK_UiFormTab_UiForm] FOREIGN KEY ([FormId]) REFERENCES [UiForm] ([Id]) ON UPDATE CASCADE ON DELETE CASCADE
	)
GO

CREATE TABLE [UiFormFieldType] (
  [Type] NCHAR(3) NOT NULL,
		[Description] NVARCHAR(25) NOT NULL,
		CONSTRAINT [PK_UiFormFieldType] PRIMARY KEY CLUSTERED ([Type]),
		CONSTRAINT [UQ_UiFormFieldType_Description] UNIQUE ([Description])
	)
GO

INSERT INTO [UiFormFieldType] ([Type], [Description])
VALUES
 (N'txt', N'Text'),
	(N'dte', N'Date'),
	(N'ddn', N'Dropdown'),
	(N'sug', N'Suggest')
GO

CREATE TABLE [UiFormField] (
  [FormId] NVARCHAR(50) NOT NULL,
		[TabIndex] TINYINT NOT NULL,
		[Index] TINYINT NOT NULL,
		[Title] NVARCHAR(255) NOT NULL,
		[Type] NCHAR(3) NOT NULL CONSTRAINT [DF_UiFormField_Type] DEFAULT (N'txt'),
		[Required] BIT NOT NULL,
		[DataItem] SYSNAME NOT NULL,
		CONSTRAINT [PK_UiFormField] PRIMARY KEY CLUSTERED ([FormId], [TabIndex], [Index]),
		CONSTRAINT [FK_UiFormField_UiFormTab] FOREIGN KEY ([FormId], [TabIndex]) REFERENCES [UiFormTab] ([FormId], [Index])
	)
GO

CREATE PROCEDURE [pr_UiForm](@Id NVARCHAR(50))
AS
BEGIN
 SET NOCOUNT ON
	;WITH XMLNAMESPACES (N'http://james.newtonking.com/projects/json' AS [json])
	SELECT
		[Id] = frm.[Id],
		[Title] = frm.[Title],
		( -- Data
				SELECT
					[SourceType] = frm.[SourceType],
					[Source] = frm.[Source]
				FOR XML PATH (N'Data'), TYPE
			),
		( -- Tabs
				SELECT
					[@json:Array] = N'true',
					[Index] = tab.[Index],
					[Title] = tab.[Title],
					( -- Fields
							SELECT
								[@json:Array] = N'true',
								[Index] = fld.[Index],
								[Title] = fld.[Title],
								[Type] = LOWER(fld.[Type]),
								[Required] = fld.[Required],
								[DataItem] = fld.[DataItem]
							FROM [UiFormField] fld
							WHERE fld.[FormId] = tab.[FormId]
								AND fld.[TabIndex] = tab.[Index]
							ORDER BY fld.[Index]
							FOR XML PATH (N'Fields'), TYPE
						)
				FROM [UiFormTab] tab
				WHERE tab.[FormId] = frm.[Id]
				ORDER BY tab.[Index]
				FOR XML PATH (N'Tabs'), TYPE
			)
	FROM [UiForm] frm
	WHERE frm.[Id] = @Id
	FOR XML PATH (N'Form'), TYPE
	RETURN
END
GO

EXEC [pr_UiForm] N'UiForm'