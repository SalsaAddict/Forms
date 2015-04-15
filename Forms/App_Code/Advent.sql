--USE [master]; DROP DATABASE [Claimsuite]; CREATE DATABASE [Claimsuite]
USE [Claimsuite]
GO

IF OBJECT_ID(N'Binder', N'U') IS NOT NULL DROP TABLE [Binder]
IF OBJECT_ID(N'pr_Entity_Save', N'P') IS NOT NULL DROP PROCEDURE [pr_Entity_Save]
IF OBJECT_ID(N'pr_Entity', N'P') IS NOT NULL DROP PROCEDURE [pr_Entity]
IF OBJECT_ID(N'pr_Entities', N'P') IS NOT NULL DROP PROCEDURE [pr_Entities]
IF OBJECT_ID(N'EntityType', N'U') IS NOT NULL DROP TABLE [EntityType]
IF OBJECT_ID(N'EntityTypeEnum', N'U') IS NOT NULL DROP TABLE [EntityTypeEnum]
IF OBJECT_ID(N'Entity', N'U') IS NOT NULL DROP TABLE [Entity]
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

CREATE TABLE [Entity] (
  [Id] INT NOT NULL IDENTITY (1, 1),
		[Name] NVARCHAR(255) NOT NULL,
		[Active] BIT NOT NULL CONSTRAINT [DF_Entity_Active] DEFAULT (1),
		CONSTRAINT [PK_Entity] PRIMARY KEY NONCLUSTERED ([Id]),
		CONSTRAINT [UQ_Entity_Name] UNIQUE CLUSTERED ([Name])
	)
GO

CREATE TABLE [EntityTypeEnum] (
  [Type] NCHAR(3) NOT NULL,
		[Description] NVARCHAR(255) NOT NULL,
		CONSTRAINT [PK_EntityTypeEnum] PRIMARY KEY NONCLUSTERED ([Type]),
		CONSTRAINT [UQ_EntityTypeEnum_Description] UNIQUE CLUSTERED ([Description])
	)
GO

INSERT INTO [EntityTypeEnum] ([Type], [Description])
VALUES
 (N'COV', N'Coverholder'),
	(N'LBR', N'LLoyd''s Broker'),
	(N'CAR', N'Carrier'),
	(N'MGA', N'MGA'),
	(N'TPA', N'TPA'),
	(N'RBR', N'Retail Broker')
GO

CREATE TABLE [EntityType] (
  [EntityId] INT NOT NULL,
		[Type] NCHAR(3) NOT NULL,
		[Active] BIT NOT NULL CONSTRAINT [DF_EntityType_Active] DEFAULT (1),
		CONSTRAINT [PK_EntityType] PRIMARY KEY CLUSTERED ([EntityId], [Type]),
		CONSTRAINT [FK_EntityType_Entity] FOREIGN KEY ([EntityId]) REFERENCES [Entity] ([Id]) ON DELETE CASCADE,
		CONSTRAINT [FK_EntityType_EntityTypeEnum] FOREIGN KEY ([Type]) REFERENCES [EntityTypeEnum] ([Type])
	)
GO

CREATE PROCEDURE [pr_Entities]
AS
BEGIN
 SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	;WITH XMLNAMESPACES (N'http://james.newtonking.com/projects/json' AS [json])
	SELECT
	 [@json:Array] = N'true',
	 [Id] = e.[Id],
		[Name] = e.[Name],
		( -- Types
		  SELECT
				 [@json:Array] = N'true',
					[Type] = ete.[Type],
					[Description] = ete.[Description],
					[Active] = ISNULL(et.[Active], 0)
				FROM [EntityTypeEnum] ete
				 LEFT JOIN [EntityType] et ON e.[Id] = et.[EntityId] AND ete.[Type] = et.[Type]
				ORDER BY ete.[Description]
				FOR XML PATH (N'Types'), TYPE
		 )
	FROM [Entity] e
	ORDER BY e.[Name]
	FOR XML PATH (N'Entities'), ROOT (N'Root')
	RETURN
END
GO

CREATE PROCEDURE [pr_Entity](@Id INT)
AS
BEGIN
 SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	;WITH XMLNAMESPACES (N'http://james.newtonking.com/projects/json' AS [json])
	SELECT
	 [Id] = e.[Id],
		[Name] = e.[Name],
		( -- Types
		  SELECT
				 [@json:Array] = N'true',
					[Type] = ete.[Type],
					[Description] = ete.[Description],
					[Active] = ISNULL(et.[Active], 0)
				FROM [EntityTypeEnum] ete
				 LEFT JOIN [EntityType] et ON e.[Id] = et.[EntityId] AND ete.[Type] = et.[Type]
				ORDER BY ete.[Description]
				FOR XML PATH (N'Types'), TYPE
		 )
	FROM [Entity] e
	WHERE e.[Id] = @Id
	FOR XML PATH (N'Entity')
	RETURN
END
GO

CREATE PROCEDURE [pr_Entity_Save](@XML XML)
AS
BEGIN
 SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @Id INT, @Name NVARCHAR(255), @Active BIT
	
	SELECT
		@Id = e.value(N'Id[1]', N'INT'),
		@Name = e.value(N'Name[1]', N'NVARCHAR(255)'),
		@Active = e.value(N'Active[1]', N'BIT')
	FROM @XML.nodes(N'/Entity[1]') ent (e)

	IF @Id IS NULL BEGIN
	 INSERT INTO [Entity] ([Name], [Active]) VALUES (@Name, ISNULL(@Active, 1))
		SET @Id = SCOPE_IDENTITY()
	END ELSE BEGIN
	 UPDATE [Entity] SET [Name] = @Name, [Active] = ISNULL(@Active, 1) WHERE [Id] = @Id
	END

	INSERT INTO [EntityType] ([EntityId], [Type], [Active])
	SELECT @Id, enm.[Type], 0
	FROM [EntityTypeEnum] enm
	 LEFT JOIN [EntityType] et ON @Id = et.[EntityId] AND enm.[Type] = et.[Type]
	WHERE et.[Active] IS NULL

	;WITH [Types] AS (
	  SELECT
			 [Type] = t.value(N'Type[1]', N'NCHAR(3)'),
				[Active] = t.value(N'Active[1]', N'BIT')
			FROM @XML.nodes(N'/Entity[1]/Types') et (t)
	 )
	UPDATE et
	SET [Active] = ISNULL(t.[Active], 0)
	FROM [EntityType] et
	 JOIN [EntityTypeEnum] enm ON et.[Type] = enm.[Type]
		JOIN [Types] t ON enm.[Type] = t.[Type]
 WHERE et.[EntityId] = @Id

	EXEC [pr_Entity] @Id

	RETURN
END
GO

CREATE TABLE [Binder] (
  [Id] INT NOT NULL IDENTITY (1, 1),
		[Reference] NVARCHAR(50) NOT NULL,
		[UMR] NVARCHAR(50) NOT NULL,
		[CoverholderId] INT NOT NULL,
		[CoverholderTypeEnum] AS CONVERT(NCHAR(3), N'COV') PERSISTED,
		[BrokerId] INT NOT NULL,
		[BrokerTypeEnum] AS CONVERT(NCHAR(3), N'LBR') PERSISTED,
		[InceptionDate] DATE NOT NULL,
		[ExpiryDate] DATE NOT NULL,
		CONSTRAINT [PK_Binder] PRIMARY KEY CLUSTERED ([Id]),
		CONSTRAINT [UQ_Binder_Reference] UNIQUE ([Reference]),
		CONSTRAINT [UQ_Binder_UMR] UNIQUE ([UMR]),
		CONSTRAINT [FK_Binder_Entity_CoverholderId] FOREIGN KEY ([CoverholderId], [CoverholderTypeEnum]) REFERENCES [EntityType] ([EntityId], [Type]),
		CONSTRAINT [FK_Binder_Entity_BrokerId] FOREIGN KEY ([BrokerId], [BrokerTypeEnum]) REFERENCES [EntityType] ([EntityId], [Type]),
		CONSTRAINT [CK_Binder_ExpiryDate] CHECK ([ExpiryDate] >= [InceptionDate])
	)
GO

