--USE [master]; DROP DATABASE [Claimsuite]; CREATE DATABASE [Claimsuite]
USE [Claimsuite]
GO

IF OBJECT_ID(N'UiRoute', N'U') IS NOT NULL DROP TABLE [UiRoute]
IF OBJECT_ID(N'UiRouteType', N'U') IS NOT NULL DROP TABLE [UiRouteType]
IF OBJECT_ID(N'UiFormListParameter', N'U') IS NOT NULL DROP TABLE [UiFormListParameter]
IF OBJECT_ID(N'UiParameterType', N'U') IS NOT NULL DROP TABLE [UiParameterType]
IF OBJECT_ID(N'UiFormList', N'U') IS NOT NULL DROP TABLE [UiFormList]
IF OBJECT_ID(N'UiFormField', N'U') IS NOT NULL DROP TABLE [UiFormField]
IF OBJECT_ID(N'UiFormFieldType', N'U') IS NOT NULL DROP TABLE [UiFormFieldType]
IF OBJECT_ID(N'UiFormTab', N'U') IS NOT NULL DROP TABLE [UiFormTab]
IF OBJECT_ID(N'UiForm', N'U') IS NOT NULL DROP TABLE [UiForm]
GO

-- ***** FORMS *****
GO

CREATE TABLE [UiForm] (
  [Id] NVARCHAR(25) NOT NULL,
		[Title] NVARCHAR(255) NOT NULL,
		[Source] SYSNAME NOT NULL,
		[InsertSP] SYSNAME NULL,
		[UpdateSP] SYSNAME NULL,
		[DeleteSP] SYSNAME NULL,
		CONSTRAINT [PK_UiForm] PRIMARY KEY CLUSTERED ([Id])
 )
GO

CREATE TABLE [UiFormTab] (
  [FormId] NVARCHAR(25) NOT NULL,
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
 (N'TXT', N'Text'),
	(N'DTE', N'Date'),
	(N'DDN', N'Dropdown'),
	(N'SUG', N'Suggest')
GO

CREATE TABLE [UiFormField] (
  [FormId] NVARCHAR(25) NOT NULL,
		[Id] SYSNAME NOT NULL,
		[TabIndex] TINYINT NOT NULL,
		[Index] TINYINT NOT NULL,
		[Title] NVARCHAR(255) NOT NULL,
		[Type] NCHAR(3) NOT NULL CONSTRAINT [DF_UiFormField_Type] DEFAULT (N'TXT'),
		[Required] BIT NOT NULL CONSTRAINT [DF_UiFormField_Required] DEFAULT (0),
		[ReadOnly] BIT NOT NULL CONSTRAINT [DF_UiFormField_ReadOnly] DEFAULT (1),
		CONSTRAINT [PK_UiFormField] PRIMARY KEY NONCLUSTERED ([FormId], [Id]),
		CONSTRAINT [UQ_UiFormField] UNIQUE CLUSTERED ([FormId], [TabIndex], [Index]),
		CONSTRAINT [FK_UiFormField_UiFormTab] FOREIGN KEY ([FormId], [TabIndex]) REFERENCES [UiFormTab] ([FormId], [Index]) ON UPDATE CASCADE ON DELETE CASCADE
	)
GO

CREATE TABLE [UiFormList] (
  [FormId] NVARCHAR(25) NOT NULL,
		[FieldId] SYSNAME NOT NULL,
		[Source] SYSNAME NOT NULL,
		[ValueField] SYSNAME NOT NULL,
		[TextField] SYSNAME NULL,
		CONSTRAINT [PK_UiFormList] PRIMARY KEY CLUSTERED ([FormId], [FieldId]),
		CONSTRAINT [FK_UiFormList_UiFormField] FOREIGN KEY ([FormId], [FieldId]) REFERENCES [UiFormField] ([FormId], [Id]) ON UPDATE CASCADE ON DELETE CASCADE
	)
GO

CREATE TABLE [UiParameterType] (
  [Type] NCHAR(1) NOT NULL,
		[Description] NVARCHAR(255) NOT NULL,
		CONSTRAINT [PK_UiParameterType] PRIMARY KEY NONCLUSTERED ([Type]),
		CONSTRAINT [UQ_UiParameterType_Description] UNIQUE CLUSTERED ([Description])
	)
GO

INSERT INTO [UiParameterType] ([Type], [Description])
VALUES
 (N'C', N'Constant'),
	(N'F', N'Field'),
	(N'R', N'Route Parameter')
GO

CREATE TABLE [UiFormListParameter] (
  [FormId] NVARCHAR(25) NOT NULL,
		[FieldId] SYSNAME NOT NULL,
  [Name] SYSNAME NOT NULL,
		[Type] NCHAR(1) NOT NULL,
		[Value] SQL_VARIANT NOT NULL,
		CONSTRAINT [PK_UiFormListParameter] PRIMARY KEY CLUSTERED ([FormId], [FieldId], [Name]),
  CONSTRAINT [FK_UiFormListParameter_UiParameterType] FOREIGN KEY ([Type]) REFERENCES [UiParameterType] ([Type])
 )
GO

-- ***** ROUTES *****
GO

CREATE TABLE [UiRouteType] (
  [Type] NCHAR(1) NOT NULL,
		[Description] NVARCHAR(255) NOT NULL,
		CONSTRAINT [PK_UiRouteType] PRIMARY KEY NONCLUSTERED ([Type]),
		CONSTRAINT [UQ_UiRouteType_Description] UNIQUE CLUSTERED ([Description])
	)
GO

INSERT INTO [UiRouteType] ([Type], [Description])
VALUES
 (N'F', N'Form')
GO

CREATE TABLE [UiRoute] (
  [Route] NVARCHAR(255) NOT NULL,
		[Type] NCHAR(1) NOT NULL CONSTRAINT [DF_UiRoute_Type] DEFAULT (N'F'),
		[New] BIT NOT NULL CONSTRAINT [DF_UiRoute_New] DEFAULT (0),
		[TemplateId] NVARCHAR(25) NOT NULL,
		[FormId] AS CASE WHEN [Type] = N'F' THEN [TemplateId] END PERSISTED,
	 CONSTRAINT [PK_UiRoute] PRIMARY KEY CLUSTERED ([Route]),
		CONSTRAINT [FK_UiRoute_UiRouteType] FOREIGN KEY ([Type]) REFERENCES [UiRouteType] ([Type]),
		CONSTRAINT [FK_UiRoute_UiForm] FOREIGN KEY ([FormId]) REFERENCES [UiForm] ([Id]),
		CONSTRAINT [CK_UiRoute_UiRouteType] CHECK ([Type] IN (N'F')),
		CONSTRAINT [CK_UiRoute_New] CHECK ([Type] = N'F' OR [New] = 0)
	)
GO
