INSERT INTO [UiForm] ([Id], [Title], [SourceType], [Source])
VALUES (N'UiForm', N'Form', N'T', N'UiForm')
GO

INSERT INTO [UiFormTab] ([FormId], [Index], [Title])
VALUES
 (N'UiForm', 0, N'General'),
	(N'UiForm', 1, N'Data')
GO

INSERT INTO [UiFormField] ([FormId], [TabIndex], [Index], [Title], [Type], [Required], [DataItem])
VALUES
 (N'UiForm', 0, 0, N'Form Id', N'txt', 1, N'Id'),
	(N'UiForm', 0, 1, N'Form Title', N'txt', 1, N'Title'),
	(N'UiForm', 1, 0, N'Source Type', N'ddn', 1, N'SourceType'),
	(N'UiForm', 1, 1, N'Source', N'txt', 1, N'Source')
GO
	