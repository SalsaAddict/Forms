--USE [master]; DROP DATABASE [Claimsuite]; CREATE DATABASE [Claimsuite]
USE [Claimsuite]
GO

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
IF OBJECT_ID(N'apiUserVerify', N'P') IS NOT NULL DROP PROCEDURE [apiUserVerify]
IF OBJECT_ID(N'apiUserLogin', N'P') IS NOT NULL DROP PROCEDURE [apiUserLogin]
IF OBJECT_ID(N'fnUserName', N'FN') IS NOT NULL DROP FUNCTION [fnUserName]
IF OBJECT_ID(N'User', N'U') IS NOT NULL DROP TABLE [User]
GO

CREATE TABLE [User] (
  [Id] INT NOT NULL IDENTITY (1, 1),
  [Email] NVARCHAR(255) NOT NULL,
		[Name] AS [Forename] + N' ' + [Surname] PERSISTED,
		[Forename] NVARCHAR(127) NOT NULL,
		[Surname] NVARCHAR(127) NOT NULL,
		[Password] NVARCHAR(max) NOT NULL,
		[Reset] BIT NOT NULL CONSTRAINT [DF_User_Reset] DEFAULT (1),
		[ValidFromUTC] DATETIME NOT NULL CONSTRAINT [DF_User_ValidFromUTC] DEFAULT (GETUTCDATE()),
		[ValidUntilUTC] DATETIME NULL,
		[LastAccessedUTC] DATETIME NULL,
		CONSTRAINT [PK_User] PRIMARY KEY CLUSTERED ([Id]),
		CONSTRAINT [UQ_User_Email] UNIQUE ([Email]),
		CONSTRAINT [CK_User_ValidUntilUTC] CHECK ([ValidUntilUTC] >= [ValidFromUTC]),
		CONSTRAINT [CK_User_LastAccessedUTC] CHECK ([LastAccessedUTC] BETWEEN [ValidFromUTC] AND ISNULL([ValidUntilUTC], GETUTCDATE()))
 )
GO

CREATE FUNCTION [dbo].[fnUserName](@UserId INT)
RETURNS NVARCHAR(255)
AS
BEGIN
 RETURN (SELECT [Name] FROM [User] WHERE [Id] = @UserId)
END
GO

INSERT INTO [User] ([Email], [Password], [Reset], [Forename], [Surname])
VALUES
 (N'pierre@whitespace.co.uk', N'1000:hk+D8z0NIR1TXcZEoLWv1S/yn2y3L7nA:1NY7qD4GdoxieaaT3Mn64pcz75aq4GfZ', 0, N'Pierre', N'Henry')
GO

CREATE PROCEDURE [apiUserLogin](@Email NVARCHAR(255))
AS
BEGIN
 SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @Now DATETIME; SET @Now = GETUTCDATE()
	UPDATE [User]
	SET [LastAccessedUTC] = @Now
 OUTPUT
	 [inserted].[Id] AS [UserId],
  [inserted].[Name],
		[inserted].[Password],
		[inserted].[Reset]
	WHERE [Email] = @Email
	 AND [ValidFromUTC] <= @Now
		AND ISNULL([ValidUntilUTC], @Now) >= @Now
	RETURN
END
GO

EXEC [apiUserLogin] N'pierre@whitespace.co.uk'
GO

CREATE PROCEDURE [apiUserVerify](@UserId INT, @Timeout TINYINT = 15)
AS
BEGIN
 SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
 DECLARE @Now DATETIME, @Reset BIT, @ValidFromUTC DATETIME, @ValidUntilUTC DATETIME, @LastAccessedUTC DATETIME
	SELECT
	 @Now = GETUTCDATE(),
		@Reset = [Reset],
		@ValidFromUTC = [ValidFromUTC],
		@ValidUntilUTC = [ValidUntilUTC],
		@LastAccessedUTC = [LastAccessedUTC]
	FROM [User]
	WHERE [Id] = @UserId
	IF @@ROWCOUNT = 0 RAISERROR(N'Invalid user.', 16, 1)
	ELSE IF @ValidFromUTC > @Now RAISERROR(N'Your account is not yet active.', 16, 1)
	ELSE IF @Now > @ValidUntilUTC RAISERROR(N'Your account has expired.', 16, 1)
	ELSE IF @Now > DATEADD(minute, @Timeout, @LastAccessedUTC) RAISERROR(N'Your session has expired. Please login and try again.', 16, 1)
	ELSE IF @Reset = 1 RAISERROR(N'You must reset your password.', 16, 1)
	ELSE UPDATE [User] SET [LastAccessedUTC] = GETUTCDATE() WHERE [Id] = @UserId
	RETURN
END
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
		[CreatedUTC] DATETIMEOFFSET NOT NULL CONSTRAINT [DF_Entity_CreatedUTC] DEFAULT (GETUTCDATE()),
		[CreatedByUserId] INT NOT NULL,
		[UpdatedUTC] DATETIMEOFFSET NOT NULL CONSTRAINT [DF_Entity_UpdatedUTC] DEFAULT (GETUTCDATE()),
		[UpdatedByUserId] INT NOT NULL,
		[Active] BIT NOT NULL CONSTRAINT [DF_Entity_Active] DEFAULT (1),
		CONSTRAINT [PK_Entity] PRIMARY KEY NONCLUSTERED ([Id]),
		CONSTRAINT [UQ_Entity_Name] UNIQUE CLUSTERED ([CountryId], [Name]),
		CONSTRAINT [FK_Entity_Country] FOREIGN KEY ([CountryId]) REFERENCES [Country] ([Id]),
		CONSTRAINT [FK_Entity_User_CreatedByUserId] FOREIGN KEY ([CreatedByUserId]) REFERENCES [User] ([Id]),
		CONSTRAINT [FK_Entity_User_UpdatedByUserId] FOREIGN KEY ([UpdatedByUserId]) REFERENCES [User] ([Id]),
		CONSTRAINT [CK_Entity_UpdatedUTC] CHECK ([UpdatedUTC] >= [CreatedUTC])
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
	 [EntityId] = [Id],
	 [Name],
		[Address],
		[PostalCode],
		[CountryId],
		[LBR],
		[CAR],
		[COV],
		[MGA],
		[TPA],
		[CreatedUTC],
		[CreatedBy] = [dbo].[fnUserName]([CreatedByUserId]),
		[UpdatedUTC],
		[UpdatedBy] = [dbo].[fnUserName]([UpdatedByUserId]),
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
		@Active BIT = 1,
		@UserId INT
	)
AS
BEGIN
 DECLARE @Id INT
 INSERT INTO [Entity] ([Name], [Address], [PostalCode], [CountryId], [LBR], [CAR], [COV], [MGA], [TPA], [CreatedByUserId], [UpdatedByUserId], [Active])
	VALUES (@Name, @Address, @PostalCode, @CountryId, @LBR, @CAR, @COV, @MGA, @TPA, @UserId, @UserId, @Active)
	SELECT @Id = SCOPE_IDENTITY()
	EXEC [apiEntity] @Id
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
		@Active BIT = 1,
		@UserId INT
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
		[Active] = ISNULL(@Active, [Active]),
		[UpdatedUTC] = GETUTCDATE(),
		[UpdatedByUserId] = @UserId
	WHERE [Id] = @Id
	EXEC [apiEntity] @Id
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

EXEC [apiEntityInsert] @Name = N'Whitespace Software Limited', @UserId = 1
EXEC [apiEntityUpdate] 1, @LBR = 1, @UserId = 1
EXEC [apiEntityInsert] @Name = N'Datarise Limited', @CountryId = N'US', @UserId = 1
GO
