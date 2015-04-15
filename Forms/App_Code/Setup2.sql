--USE [master]; DROP DATABASE [Claimsuite]; CREATE DATABASE [Claimsuite]
USE [Claimsuite]
GO

IF OBJECT_ID(N'pr_UiRead', N'P') IS NOT NULL DROP PROCEDURE [pr_UiRead]
IF OBJECT_ID(N'pr_UiForm', N'P') IS NOT NULL DROP PROCEDURE [pr_UiForm]
IF OBJECT_ID(N'pr_UiRoutes', N'P') IS NOT NULL DROP PROCEDURE [pr_UiRoutes]
IF OBJECT_ID(N'UiFormList', N'U') IS NOT NULL DROP TABLE [UiFormList]
IF OBJECT_ID(N'UiFormField', N'U') IS NOT NULL DROP TABLE [UiFormField]
IF OBJECT_ID(N'UiFormFieldType', N'U') IS NOT NULL DROP TABLE [UiFormFieldType]
IF OBJECT_ID(N'UiFormTab', N'U') IS NOT NULL DROP TABLE [UiFormTab]
IF OBJECT_ID(N'UiFormKey', N'U') IS NOT NULL DROP TABLE [UiFormKey]
IF OBJECT_ID(N'UiForm', N'U') IS NOT NULL DROP TABLE [UiForm]
IF OBJECT_ID(N'pr_UiSourceType', N'P') IS NOT NULL DROP PROCEDURE [pr_UiSourceType]
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
	(N'P', N'Stored Procedure')
GO

CREATE PROCEDURE [pr_UiSourceType]
AS
BEGIN
 SET NOCOUNT ON
	SET ANSI_WARNINGS OFF
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SELECT [Type], [Description] FROM [UiSourceType] ORDER BY [Description]
	RETURN
END
GO

CREATE TABLE [UiForm] (
  [Id] NVARCHAR(50) NOT NULL,
		[Route] AS CONVERT(NVARCHAR(255), N'/forms/' + [Id]) PERSISTED,
		[Title] NVARCHAR(255) NOT NULL,
		[SourceType] NCHAR(1) NOT NULL,
		[Source] SYSNAME NOT NULL,
		CONSTRAINT [PK_UiForm] PRIMARY KEY CLUSTERED ([Id]),
		CONSTRAINT [UQ_UiForm_Route] UNIQUE ([Route]),
		CONSTRAINT [FK_UiForm_UiSourceType] FOREIGN KEY ([SourceType]) REFERENCES [UiSourceType] ([Type])
	)
GO

CREATE TABLE [UiFormKey] (
  [FormId] NVARCHAR(50) NOT NULL,
		[Index] TINYINT NOT NULL,
		[Name] SYSNAME NOT NULL,
		CONSTRAINT [PK_UiFormKey] PRIMARY KEY CLUSTERED ([FormId], [Index]),
		CONSTRAINT [UQ_UiFormKey_Name] UNIQUE ([FormId], [Name]),
		CONSTRAINT [FK_UiFormKey_UiForm] FOREIGN KEY ([FormId]) REFERENCES [UiForm] ([Id]) ON UPDATE CASCADE ON DELETE CASCADE
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
		[Id] SYSNAME NOT NULL,
		[TabIndex] TINYINT NOT NULL,
		[Index] TINYINT NOT NULL,
		[Title] NVARCHAR(255) NOT NULL,
		[Type] NCHAR(3) NOT NULL CONSTRAINT [DF_UiFormField_Type] DEFAULT (N'txt'),
		[Required] BIT NOT NULL,
		CONSTRAINT [PK_UiFormField] PRIMARY KEY CLUSTERED ([FormId], [TabIndex], [Index]),
		CONSTRAINT [UQ_UiFormField_Id] UNIQUE ([FormId], [Id]),
		CONSTRAINT [FK_UiFormField_UiFormTab] FOREIGN KEY ([FormId], [TabIndex]) REFERENCES [UiFormTab] ([FormId], [Index]) ON UPDATE CASCADE ON DELETE CASCADE
	)
GO

CREATE TABLE [UiFormList] (
  [FormId] NVARCHAR(50) NOT NULL,
		[TabIndex] TINYINT NOT NULL,
		[FieldIndex] TINYINT NOT NULL,
		[Name] SYSNAME NOT NULL,
		[ValueField] SYSNAME NOT NULL,
		[TextField] SYSNAME NULL,
		CONSTRAINT [PK_UiFormList] PRIMARY KEY CLUSTERED ([FormId], [TabIndex], [FieldIndex]),
		CONSTRAINT [FK_UiFormList_UiFormField] FOREIGN KEY ([FormId], [TabIndex], [FieldIndex]) REFERENCES [UiFormField] ([FormId], [TabIndex], [Index]) ON UPDATE CASCADE ON DELETE CASCADE
	)
GO

CREATE TABLE [UiRouteType] (
  [Type] NVARCHAR(10) NOT NULL,
		CONSTRAINT [PK_UiRouteType] PRIMARY KEY CLUSTERED ([Type])
 )
GO

INSERT INTO [UiRouteType] ([Type])
VALUES
 (N'UiForm')
GO

CREATE TABLE [UiRoute] (
  [Route] NVARCHAR(255) NOT NULL,
		[Type] NVARCHAR(10) NOT NULL,
		[New] BIT NOT NULL
		

CREATE PROCEDURE [pr_UiRoutes]
AS
BEGIN
 SET NOCOUNT ON
	SELECT
		[Route] = frm.[Route],
		[Parameters] = CONVERT(NVARCHAR(max), (
				SELECT
					N'/:' + k.[Name]
				FROM [UiFormKey] k
				WHERE k.[FormId] = frm.[Id]
				ORDER BY k.[Index]
				FOR XML PATH (N'')
			))
	FROM [UiForm] frm
 RETURN
END
GO

CREATE PROCEDURE [pr_UiForm](@Route NVARCHAR(255))
AS
BEGIN
 SET NOCOUNT ON
	;WITH XMLNAMESPACES (N'http://james.newtonking.com/projects/json' AS [json])
	SELECT
		[Id] = frm.[Id],
		[Title] = frm.[Title],
		( -- Keys
		  SELECT
				 [@json:Array] = N'true',
					[Name] = k.[Name]
				FROM [UiFormKey] k
				WHERE k.[FormId] = frm.[Id]
				ORDER BY k.[Index]
				FOR XML PATH (N'Keys'), TYPE
		 ),
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
								[Id] = fld.[Id],
								[Index] = fld.[Index],
								[Title] = fld.[Title],
								[Type] = LOWER(fld.[Type]),
								[Required] = fld.[Required],
								( -- List
								  SELECT
										 [Name] = lst.[Name],
											[ValueField] = lst.[ValueField],
											[TextField] = ISNULL(lst.[TextField], lst.[ValueField])
										FROM [UiFormList] lst
										WHERE lst.[FormId] = fld.[FormId]
										 AND lst.[TabIndex] = fld.[TabIndex]
											AND lst.[FieldIndex] = fld.[Index]
										FOR XML PATH (N'List'), TYPE
								 )
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
	WHERE frm.[Route] = @Route
	FOR XML PATH (N'Form'), TYPE
	RETURN
END
GO

CREATE PROCEDURE [pr_UiRead](@Id NVARCHAR(50))
AS
BEGIN
 SET NOCOUNT ON
	SET ANSI_WARNINGS OFF
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SELECT [SourceType], [Source] FROM [UiForm] WHERE [Id] = @Id
	SELECT [Id] FROM [UiFormField] WHERE [FormId] = @Id
	RETURN
END
GO

EXEC [pr_UiForm] N'UiForm'