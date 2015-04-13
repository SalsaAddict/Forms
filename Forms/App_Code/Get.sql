DECLARE @FormId NVARCHAR(50); SET @FormId = N'UiForm'

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
							[Required] = fld.[Required]
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
WHERE frm.[Id] = @FormId
FOR XML PATH (N'UiForm'), TYPE