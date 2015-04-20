--USE [master]; DROP DATABASE [Claimsuite]; CREATE DATABASE [Claimsuite]
USE [Claimsuite]
GO

IF OBJECT_ID(N'apiUser', N'P') IS NOT NULL DROP PROCEDURE [apiUser]
IF OBJECT_ID(N'User', N'U') IS NOT NULL DROP TABLE [User]
IF OBJECT_ID(N'apiEntityDelete', N'P') IS NOT NULL DROP PROCEDURE [apiEntityDelete]
IF OBJECT_ID(N'apiEntityUpdate', N'P') IS NOT NULL DROP PROCEDURE [apiEntityUpdate]
IF OBJECT_ID(N'apiEntityInsert', N'P') IS NOT NULL DROP PROCEDURE [apiEntityInsert]
IF OBJECT_ID(N'apiEntityTypes', N'P') IS NOT NULL DROP PROCEDURE [apiEntityTypes]
IF OBJECT_ID(N'apiEntity', N'P') IS NOT NULL DROP PROCEDURE [apiEntity]
IF OBJECT_ID(N'apiEntities', N'P') IS NOT NULL DROP PROCEDURE [apiEntities]
IF OBJECT_ID(N'Entity', N'U') IS NOT NULL DROP TABLE [Entity]
IF OBJECT_ID(N'apiCurrencies', N'P') IS NOT NULL DROP PROCEDURE [apiCurrencies]
IF OBJECT_ID(N'Currency', N'U') IS NOT NULL DROP TABLE [Currency]
IF OBJECT_ID(N'apiCountries', N'P') IS NOT NULL DROP PROCEDURE [apiCountries]
IF OBJECT_ID(N'Country', N'U') IS NOT NULL DROP TABLE [Country]
GO

CREATE TABLE [Country] (
  [Id] NCHAR(2) NOT NULL,
		[Name] NVARCHAR(255) NOT NULL,
		CONSTRAINT [PK_Country] PRIMARY KEY NONCLUSTERED ([Id]),
		CONSTRAINT [UQ_Country_Name] UNIQUE ([Name])
	)
GO

INSERT INTO [Country] ([Id], [Name])
VALUES
 (N'UK', 'United Kingdom'),
	(N'US', 'United States')
GO

CREATE PROCEDURE [apiCountries]
AS
BEGIN
 SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SELECT [Id], [Name] FROM [Country] ORDER BY [Name]
	RETURN
END
GO

CREATE TABLE [Currency] (
  [Id] NCHAR(3) NOT NULL,
		[Name] NVARCHAR(255) NOT NULL,
		CONSTRAINT [PK_Currency] PRIMARY KEY NONCLUSTERED ([Id]),
		CONSTRAINT [UQ_Currency_Name] UNIQUE ([Name])
	)
GO

INSERT INTO [Currency] ([Id], [Name])
VALUES
 (N'GBP', N'British Pounds'),
	(N'EUR', N'Euros'),
	(N'USD', N'US Dollars')
GO

CREATE PROCEDURE [apiCurrencies]
AS
BEGIN
 SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SELECT [Id], [Name] FROM [Currency] ORDER BY [Name]
	RETURN
END
GO

CREATE TABLE [Entity] (
  [Id] INT NOT NULL IDENTITY (1, 1),
		[Name] NVARCHAR(255) NOT NULL,
		[Address] NVARCHAR(255) NULL,
		[PostalCode] NVARCHAR(25) NULL,
		[CountryId] NCHAR(2) NOT NULL,
		[LBR] BIT NOT NULL CONSTRAINT [DF_Entity_LBR] DEFAULT (0), -- Lloyd's Broker
		[CAR] BIT NOT NULL CONSTRAINT [DF_Entity_CAR] DEFAULT (0), -- Carrier
		[COV] BIT NOT NULL CONSTRAINT [DF_Entity_COV] DEFAULT (0), -- Coverholder
		[MGA] BIT NOT NULL CONSTRAINT [DF_Entity_MGA] DEFAULT (0), -- Managing General Agent
		[TPA] BIT NOT NULL CONSTRAINT [DF_Entity_TPA] DEFAULT (0), -- Third-Pary Adjuster
		[Active] BIT NOT NULL CONSTRAINT [DF_Entity_Active] DEFAULT (1),
		CONSTRAINT [PK_Entity] PRIMARY KEY NONCLUSTERED ([Id]),
		CONSTRAINT [UQ_Entity_Name] UNIQUE CLUSTERED ([CountryId], [Name]),
		CONSTRAINT [FK_Entity_Country] FOREIGN KEY ([CountryId]) REFERENCES [Country] ([Id])
	)
GO

CREATE PROCEDURE [apiEntities]
AS
BEGIN
 SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SELECT
	 [Id] = e.[Id],
		[Name] = e.[Name],
		[Country] = ec.[Name],
		[Active] = e.[Active]
	FROM [Entity] e
	 JOIN [Country] ec ON e.[CountryId] = ec.[Id]
	ORDER BY e.[Name], ec.[Name]
	RETURN
END
GO

CREATE PROCEDURE [apiEntity](@EntityId INT)
AS
BEGIN
 SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SELECT
	 [Name],
		[Address],
		[PostalCode],
		[CountryId],
		[LBR],
		[CAR],
		[COV],
		[MGA],
		[TPA],
		[Active]
	FROM [Entity]
	WHERE [Id] = @EntityId
	RETURN
END
GO

CREATE PROCEDURE [apiEntityTypes]
AS
BEGIN
 SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
 SELECT [Code], [Description]
	FROM (VALUES
	  (1, N'LBR', N'Lloyd''s Broker'),
			(2, N'CAR', N'Carrier'),
			(3, N'COV', N'Coverholder'),
			(4, N'MGA', N'MGA'),
			(5, N'TPA', N'TPA')
	 ) t ([Index], [Code], [Description])
	ORDER BY [Index]
 RETURN
END
GO

CREATE PROCEDURE [apiEntityInsert](
		@Name NVARCHAR(255),
		@Address NVARCHAR(255) = NULL,
		@PostalCode NVARCHAR(25) = NULL,
		@CountryId NCHAR(2) = N'UK',
		@LBR BIT = 0,
		@CAR BIT = 0,
		@COV BIT = 0,
		@MGA BIT = 0,
		@TPA BIT = 0,
		@Active BIT = 1
	)
AS
BEGIN
 INSERT INTO [Entity] ([Name], [Address], [PostalCode], [CountryId], [LBR], [CAR], [COV], [MGA], [TPA], [Active])
	VALUES (@Name, @Address, @PostalCode, @CountryId, @LBR, @CAR, @COV, @MGA, @TPA, @Active)
	SELECT [EntityId] = SCOPE_IDENTITY()
	RETURN
END
GO

CREATE PROCEDURE [apiEntityUpdate](
  @Id INT,
		@Name NVARCHAR(255) = NULL,
		@Address NVARCHAR(255) = NULL,
		@PostalCode NVARCHAR(25) = NULL,
		@CountryId NCHAR(2) = NULL,
		@LBR BIT = NULL,
		@CAR BIT = NULL,
		@COV BIT = NULL,
		@MGA BIT = NULL,
		@TPA BIT = NULL,
		@Active BIT = 1
	)
AS
BEGIN
 UPDATE [Entity]
	SET
	 [Name] = ISNULL(@Name, [Name]),
		[Address] = ISNULL(@Address, [Address]),
		[PostalCode] = ISNULL(@PostalCode, [PostalCode]),
		[CountryId] = ISNULL(@CountryId, [CountryId]),
		[LBR] = ISNULL(@LBR, [LBR]),
		[CAR] = ISNULL(@CAR, [CAR]),
		[COV] = ISNULL(@COV, [COV]),
		[MGA] = ISNULL(@MGA, [MGA]),
		[TPA] = ISNULL(@TPA, [TPA]),
		[Active] = ISNULL(@Active, [Active])
	WHERE [Id] = @Id
	SELECT [EntityId] = @Id
	RETURN
END
GO

CREATE PROCEDURE [apiEntityDelete](@Id INT)
AS
BEGIN
 SET NOCOUNT ON
	DELETE [Entity] WHERE [Id] = @Id
	RETURN
END
GO

EXEC [apiEntityInsert] @Name = N'Whitespace Software Limited'
EXEC [apiEntityUpdate] 1, @LBR = 1
EXEC [apiEntityInsert] @Name = N'Datarise Limited', @CountryId = N'US'
GO

CREATE TABLE [User] (
  [Id] INT NOT NULL IDENTITY (1, 1),
  [Email] NVARCHAR(255) NOT NULL,
		[Name] AS [Forename] + N' ' + [Surname] PERSISTED,
		[Forename] NVARCHAR(127) NOT NULL,
		[Surname] NVARCHAR(127) NOT NULL,
		[Password] NVARCHAR(max) NOT NULL,
		[Reset] BIT NOT NULL CONSTRAINT [DF_User_Reset] DEFAULT (1),
		CONSTRAINT [PK_User] PRIMARY KEY NONCLUSTERED ([Id]),
		CONSTRAINT [UQ_User_Email] UNIQUE CLUSTERED ([Email])
 )
GO

INSERT INTO [User] ([Email], [Password], [Reset], [Forename], [Surname])
OUTPUT [inserted].*
VALUES
 (N'pierre@whitespace.co.uk', N'1000:hk+D8z0NIR1TXcZEoLWv1S/yn2y3L7nA:1NY7qD4GdoxieaaT3Mn64pcz75aq4GfZ', 0, N'Pierre', N'Henry')
GO

CREATE PROCEDURE [apiUser](@Email NVARCHAR(255))
AS
BEGIN
 SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
 SELECT
	 [Name],
		[Forename],
		[Surname],
		[Password],
		[Reset]
	FROM [User]
	WHERE [Email] = @Email
	RETURN
END
GO

