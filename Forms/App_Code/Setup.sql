--USE [master]; DROP DATABASE [Claimsuite]; CREATE DATABASE [Claimsuite]
USE [Claimsuite]
GO

IF OBJECT_ID(N'pr_UiForm_R', N'P') IS NOT NULL DROP PROCEDURE [pr_UiForm_R]
IF OBJECT_ID(N'UiForm', N'U') IS NOT NULL DROP TABLE [UiForm]
IF OBJECT_ID(N'fn_UiForm_ValidateArrays', N'FN') IS NOT NULL DROP FUNCTION [fn_UiForm_ValidateArrays]
IF OBJECT_ID(N'fn_UiForm_Id', N'FN') IS NOT NULL DROP FUNCTION [fn_UiForm_Id]
IF EXISTS (SELECT * FROM sys.xml_schema_collections WHERE [name] = N'UiFormXSD') DROP XML SCHEMA COLLECTION [UiFormXSD]
GO

CREATE XML SCHEMA COLLECTION [UiFormXSD] AS
N'<?xml version="1.0" encoding="utf-16"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">

  <xs:element name="Form">
    <xs:complexType>
      <xs:sequence>
        <xs:element name="Id" type="xs:token" />
        <xs:element name="Title" type="xs:token" />
        <xs:element name="Data" type="Data" />
        <xs:element name="Tabs" type="Tabs" maxOccurs="unbounded" />
      </xs:sequence>
    </xs:complexType>
  </xs:element>

  <xs:complexType name="Data">
    <xs:sequence>
      <xs:element name="Source" type="xs:token" />
      <xs:element name="SourceType">
        <xs:simpleType>
          <xs:restriction base="xs:token">
            <xs:enumeration value="Table or View" />
            <xs:enumeration value="Table-Valued Function" />
            <xs:enumeration value="Stored Procedure" />
          </xs:restriction>
        </xs:simpleType>
      </xs:element>
    </xs:sequence>
  </xs:complexType>

  <xs:complexType name="Tabs">
    <xs:sequence>
      <xs:element name="Title" type="xs:token" />
      <xs:element name="Fields" type="Fields" maxOccurs="unbounded" />
    </xs:sequence>
    <xs:anyAttribute processContents="skip" namespace="http://james.newtonking.com/projects/json" />
  </xs:complexType>

  <xs:complexType name="Fields">
    <xs:sequence>
      <xs:element name="Id" type="xs:token" />
      <xs:element name="Title" type="xs:token" />
      <xs:element name="Type" default="Text">
        <xs:simpleType>
          <xs:restriction base="xs:token">
            <xs:enumeration value="Text" />
            <xs:enumeration value="Date" />
            <xs:enumeration value="Dropdown" />
            <xs:enumeration value="Suggest" />
          </xs:restriction>
        </xs:simpleType>
      </xs:element>
      <xs:element name="Required" default="Never">
        <xs:simpleType>
          <xs:restriction base="xs:token">
            <xs:enumeration value="Always" />
            <xs:enumeration value="Update" />
            <xs:enumeration value="Never" />
          </xs:restriction>
        </xs:simpleType>
      </xs:element>
      <xs:element name="Editable" default="Always">
        <xs:simpleType>
          <xs:restriction base="xs:token">
            <xs:enumeration value="Always" />
            <xs:enumeration value="Insert" />
            <xs:enumeration value="Update" />
          </xs:restriction>
        </xs:simpleType>
      </xs:element>
      <xs:element name="Visible" default="Always">
        <xs:simpleType>
          <xs:restriction base="xs:token">
            <xs:enumeration value="Always" />
            <xs:enumeration value="Edit" />
            <xs:enumeration value="Insert" />
            <xs:enumeration value="Update" />
          </xs:restriction>
        </xs:simpleType>
      </xs:element>
      <xs:element name="List" type="List" minOccurs="0" />
    </xs:sequence>
    <xs:anyAttribute processContents="skip" namespace="http://james.newtonking.com/projects/json" />
  </xs:complexType>

  <xs:complexType name="List">
    <xs:sequence>
      <xs:element name="Name" type="xs:token" />
      <xs:element name="Parameters" minOccurs="0" maxOccurs="unbounded">
        <xs:complexType>
          <xs:sequence>
            <xs:element name="Name" type="xs:token" />
            <xs:element name="Type">
              <xs:simpleType>
                <xs:restriction base="xs:token">
                  <xs:enumeration value="Field" />
                  <xs:enumeration value="Constant" />
                  <xs:enumeration value="RouteParameter" />
                </xs:restriction>
              </xs:simpleType>
            </xs:element>
            <xs:element name="Value" type="xs:token" />
          </xs:sequence>
          <xs:anyAttribute processContents="skip" namespace="http://james.newtonking.com/projects/json" />
        </xs:complexType>
      </xs:element>
    </xs:sequence>
  </xs:complexType>

</xs:schema>'
GO

CREATE FUNCTION [dbo].[fn_UiForm_Id](@XML XML ([dbo].[UiFormXSD]))
RETURNS NVARCHAR(50)
WITH SCHEMABINDING
AS
BEGIN
 RETURN @XML.value(N'/Form[1]/Id[1]', N'NVARCHAR(50)')
END
GO

CREATE FUNCTION [dbo].[fn_UiForm_ValidateArrays](@XML XML ([dbo].[UiFormXSD]))
RETURNS BIT
WITH SCHEMABINDING
AS
BEGIN
 DECLARE @IsValid BIT
	;WITH XMLNAMESPACES ('http://james.newtonking.com/projects/json' AS json)
	SELECT @IsValid = CASE
		 WHEN @XML.exist(N'//Tabs[not(@json:Array = "true")]') = 1 THEN 0
			WHEN @XML.exist(N'//Fields[not(@json:Array = "true")]') = 1 THEN 0
			WHEN @XML.exist(N'//Parameters[not(@json:Array = "true")]') = 1 THEN 0
	  ELSE 1
		END
	RETURN @IsValid
END
GO

CREATE TABLE [UiForm] (
  [Id] AS [dbo].[fn_UiForm_Id]([XML]) PERSISTED,
  [XML] XML ([UiFormXSD]) NOT NULL,
		CONSTRAINT [PK_UiForm] PRIMARY KEY CLUSTERED ([Id]),
		CONSTRAINT [CK_UiForm_ValidateArrays] CHECK ([dbo].[fn_UiForm_ValidateArrays]([XML]) = 1)
	)
GO

CREATE PRIMARY XML INDEX [IX_UiForm_XML] ON [UiForm] ([XML])
GO

CREATE XML INDEX [IX_UiForm_XML_PATH] ON [UiForm] ([XML]) USING XML INDEX [IX_UiForm_XML] FOR PATH
GO

CREATE XML INDEX [IX_UiForm_XML_VALUE] ON [UiForm] ([XML]) USING XML INDEX [IX_UiForm_XML] FOR VALUE
GO

CREATE XML INDEX [IX_UiForm_XML_PROPERTY] ON [UiForm] ([XML]) USING XML INDEX [IX_UiForm_XML] FOR PROPERTY
GO

INSERT INTO [UiForm] ([XML])
VALUES (
N'<?xml version="1.0" encoding="utf-16" ?>
<Form xmlns:json="http://james.newtonking.com/projects/json">
  <Id>/home</Id>
  <Title>Incident</Title>
  <Data>
    <Source>vw_40Incident</Source>
    <SourceType>Table or View</SourceType>
  </Data>
  <Tabs json:Array="true">
    <Title>Incident Details</Title>
    <Fields json:Array="true">
      <Id>InsuredId</Id>
      <Title>Programme</Title>
      <Type>Dropdown</Type>
      <Required>Always</Required>
      <Editable>Insert</Editable>
      <Visible>Always</Visible>
      <List>
        <Name>pr_40GetInsured</Name>
        <Parameters json:Array="true">
          <Name>UserId</Name>
          <Type>Constant</Type>
          <Value>4835</Value>
        </Parameters>
      </List>
    </Fields>
  </Tabs>
</Form>')
GO

CREATE PROCEDURE [pr_UiForm_R](@Id NVARCHAR(50))
AS
BEGIN
 SET NOCOUNT ON
	SET ANSI_WARNINGS ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SELECT [XML].query(N'/Form[1]') FROM [UiForm] WHERE [Id] = @Id FOR XML PATH (N'')
	RETURN
END
GO

EXEC [pr_UiForm_R] N'/home'
GO
