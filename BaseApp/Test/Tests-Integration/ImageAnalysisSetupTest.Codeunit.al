codeunit 135207 "Image Analysis Setup Test"
{
    Permissions = TableData "Azure AI Usage" = rimd;
    Subtype = Test;
    TestPermissions = Restrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Image Analysis]
    end;

    var
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        InvalidApiUriErr: Label 'The Api Uri must be a valid Uri for Cognitive Services.';
        MockSecretTxt: Label '[{"key":"%1","endpoint":"%2","limittype":"%3","limitvalue":"%4"}]', Comment = 'Locked';
        AzureKeyVault: Codeunit "Azure Key Vault";
        AzureKeyVaultTestLibrary: Codeunit "Azure Key Vault Test Library";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";

    [Test]
    [Scope('OnPrem')]
    procedure TestDateYear()
    var
        AzureAIUsage: Record "Azure AI Usage";
        DateToUse: Date;
        TimeToUse: Time;
    begin
        // [SCENARIO] Set a date, and check change of year is detected correctly

        // [GIVEN] a test date is set
        LibraryLowerPermissions.SetO365Basic;
        TimeToUse := 113001.123T;
        DateToUse := DMY2Date(20, 4, 2017);
        AzureAIUsage.SetTestMode(DateToUse, TimeToUse);

        // [THEN] it is detected correctly when we change year
        Assert.IsFalse(
          AzureAIUsage.HasChangedYear(CreateDateTime(CalcDate('<+1M>', DateToUse), TimeToUse)),
          'Expected not to have changed year');
        Assert.IsFalse(
          AzureAIUsage.HasChangedYear(CreateDateTime(CalcDate('<-1M>', DateToUse), TimeToUse)),
          'Expected not to have changed year');
        Assert.IsFalse(
          AzureAIUsage.HasChangedYear(CreateDateTime(CalcDate('<+1D>', DateToUse), TimeToUse)),
          'Expected not to have changed year');
        Assert.IsFalse(
          AzureAIUsage.HasChangedYear(CreateDateTime(CalcDate('<-1D>', DateToUse), TimeToUse)),
          'Expected not to have changed year');
        Assert.IsFalse(
          AzureAIUsage.HasChangedYear(CreateDateTime(DateToUse, 123001.123T)), 'Expected not to have changed year');
        Assert.IsFalse(
          AzureAIUsage.HasChangedYear(CreateDateTime(DateToUse, 103001.123T)), 'Expected not to have changed year');
        Assert.IsFalse(
          AzureAIUsage.HasChangedYear(CreateDateTime(DateToUse, 113101.123T)), 'Expected not to have changed year');
        Assert.IsFalse(
          AzureAIUsage.HasChangedYear(CreateDateTime(DateToUse, 112901.123T)), 'Expected not to have changed year');
        Assert.IsFalse(
          AzureAIUsage.HasChangedYear(CreateDateTime(DateToUse, 113002.123T)), 'Expected not to have changed year');
        Assert.IsFalse(
          AzureAIUsage.HasChangedYear(CreateDateTime(DateToUse, 113000.123T)), 'Expected not to have changed year');

        Assert.IsTrue(
          AzureAIUsage.HasChangedYear(CreateDateTime(CalcDate('<+9M>', DateToUse), TimeToUse)),
          'Expected to have changed year');
        Assert.IsTrue(
          AzureAIUsage.HasChangedYear(CreateDateTime(CalcDate('<-5M>', DateToUse), TimeToUse)),
          'Expected to have changed year');
        Assert.IsTrue(
          AzureAIUsage.HasChangedYear(CreateDateTime(CalcDate('<+1Y>', DateToUse), TimeToUse)),
          'Expected to have changed year');
        Assert.IsTrue(
          AzureAIUsage.HasChangedYear(CreateDateTime(CalcDate('<-1Y>', DateToUse), TimeToUse)),
          'Expected to have changed year');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDateMonth()
    var
        AzureAIUsage: Record "Azure AI Usage";
        DateToUse: Date;
        TimeToUse: Time;
    begin
        // [SCENARIO] Set a date, and check change of month is detected correctly

        // [GIVEN] a test date is set
        LibraryLowerPermissions.SetO365Basic;
        TimeToUse := 113001.123T;
        DateToUse := DMY2Date(20, 4, 2017);
        AzureAIUsage.SetTestMode(DateToUse, TimeToUse);

        // [THEN] it is detected correctly when we change month
        Assert.IsFalse(
          AzureAIUsage.HasChangedMonth(CreateDateTime(CalcDate('<+1D>', DateToUse), TimeToUse)),
          'Expected not to have changed month');
        Assert.IsFalse(
          AzureAIUsage.HasChangedMonth(CreateDateTime(CalcDate('<-1D>', DateToUse), TimeToUse)),
          'Expected not to have changed month');
        Assert.IsFalse(
          AzureAIUsage.HasChangedMonth(CreateDateTime(DateToUse, 123001.123T)), 'Expected not to have changed month');
        Assert.IsFalse(
          AzureAIUsage.HasChangedMonth(CreateDateTime(DateToUse, 103001.123T)), 'Expected not to have changed month');
        Assert.IsFalse(
          AzureAIUsage.HasChangedMonth(CreateDateTime(DateToUse, 113101.123T)), 'Expected not to have changed month');
        Assert.IsFalse(
          AzureAIUsage.HasChangedMonth(CreateDateTime(DateToUse, 112901.123T)), 'Expected not to have changed month');
        Assert.IsFalse(
          AzureAIUsage.HasChangedMonth(CreateDateTime(DateToUse, 113002.123T)), 'Expected not to have changed month');
        Assert.IsFalse(
          AzureAIUsage.HasChangedMonth(CreateDateTime(DateToUse, 113000.123T)), 'Expected not to have changed month');

        Assert.IsTrue(
          AzureAIUsage.HasChangedMonth(CreateDateTime(CalcDate('<+1M>', DateToUse), TimeToUse)),
          'Expected to have changed month');
        Assert.IsTrue(
          AzureAIUsage.HasChangedMonth(CreateDateTime(CalcDate('<-1M>', DateToUse), TimeToUse)),
          'Expected to have changed month');
        Assert.IsTrue(
          AzureAIUsage.HasChangedMonth(CreateDateTime(CalcDate('<+9M>', DateToUse), TimeToUse)),
          'Expected to have changed month');
        Assert.IsTrue(
          AzureAIUsage.HasChangedMonth(CreateDateTime(CalcDate('<-5M>', DateToUse), TimeToUse)),
          'Expected to have changed month');
        Assert.IsTrue(
          AzureAIUsage.HasChangedMonth(CreateDateTime(CalcDate('<+1Y>', DateToUse), TimeToUse)),
          'Expected to have changed month');
        Assert.IsTrue(
          AzureAIUsage.HasChangedMonth(CreateDateTime(CalcDate('<-1Y>', DateToUse), TimeToUse)),
          'Expected to have changed month');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDateDay()
    var
        AzureAIUsage: Record "Azure AI Usage";
        DateToUse: Date;
        TimeToUse: Time;
    begin
        // [SCENARIO] Set a date, and check change of day is detected correctly

        // [GIVEN] a test date is set
        LibraryLowerPermissions.SetO365Basic;
        TimeToUse := 113001.123T;
        DateToUse := DMY2Date(20, 4, 2017);
        AzureAIUsage.SetTestMode(DateToUse, TimeToUse);

        // [THEN] it is detected correctly when we change day
        Assert.IsFalse(AzureAIUsage.HasChangedDay(CreateDateTime(DateToUse, 123001.123T)), 'Expected not to have changed day');
        Assert.IsFalse(AzureAIUsage.HasChangedDay(CreateDateTime(DateToUse, 103001.123T)), 'Expected not to have changed day');
        Assert.IsFalse(AzureAIUsage.HasChangedDay(CreateDateTime(DateToUse, 113101.123T)), 'Expected not to have changed day');
        Assert.IsFalse(AzureAIUsage.HasChangedDay(CreateDateTime(DateToUse, 112901.123T)), 'Expected not to have changed day');
        Assert.IsFalse(AzureAIUsage.HasChangedDay(CreateDateTime(DateToUse, 113002.123T)), 'Expected not to have changed day');
        Assert.IsFalse(AzureAIUsage.HasChangedDay(CreateDateTime(DateToUse, 113000.123T)), 'Expected not to have changed day');

        Assert.IsTrue(
          AzureAIUsage.HasChangedDay(CreateDateTime(CalcDate('<+1D>', DateToUse), TimeToUse)), 'Expected to have changed day');
        Assert.IsTrue(
          AzureAIUsage.HasChangedDay(CreateDateTime(CalcDate('<-1D>', DateToUse), TimeToUse)), 'Expected to have changed day');
        Assert.IsTrue(
          AzureAIUsage.HasChangedDay(CreateDateTime(CalcDate('<+5D>', DateToUse), TimeToUse)), 'Expected to have changed day');
        Assert.IsTrue(
          AzureAIUsage.HasChangedDay(CreateDateTime(CalcDate('<-5D>', DateToUse), TimeToUse)), 'Expected to have changed day');
        Assert.IsTrue(
          AzureAIUsage.HasChangedDay(CreateDateTime(CalcDate('<+1Y>', DateToUse), TimeToUse)), 'Expected to have changed day');
        Assert.IsTrue(
          AzureAIUsage.HasChangedDay(CreateDateTime(CalcDate('<-1Y>', DateToUse), TimeToUse)), 'Expected to have changed day');
        Assert.IsTrue(
          AzureAIUsage.HasChangedDay(CreateDateTime(CalcDate('<+1M>', DateToUse), TimeToUse)), 'Expected to have changed day');
        Assert.IsTrue(
          AzureAIUsage.HasChangedDay(CreateDateTime(CalcDate('<-1M>', DateToUse), TimeToUse)), 'Expected to have changed day');
        Assert.IsTrue(
          AzureAIUsage.HasChangedDay(CreateDateTime(CalcDate('<+9M>', DateToUse), TimeToUse)), 'Expected to have changed day');
        Assert.IsTrue(
          AzureAIUsage.HasChangedDay(CreateDateTime(CalcDate('<-5M>', DateToUse), TimeToUse)), 'Expected to have changed day');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDateHour()
    var
        AzureAIUsage: Record "Azure AI Usage";
        DateToUse: Date;
        TimeToUse: Time;
    begin
        // [SCENARIO] Set a date, and check change of hour is detected correctly

        // [GIVEN] a test date is set
        LibraryLowerPermissions.SetO365Basic;
        TimeToUse := 113001.123T;
        DateToUse := DMY2Date(20, 4, 2017);
        AzureAIUsage.SetTestMode(DateToUse, TimeToUse);

        // [THEN] it is detected correctly when we change hour

        Assert.IsFalse(
          AzureAIUsage.HasChangedHour(CreateDateTime(DateToUse, 113101.123T)), 'Expected not to have changed hour');
        Assert.IsFalse(
          AzureAIUsage.HasChangedHour(CreateDateTime(DateToUse, 112901.123T)), 'Expected not to have changed hour');
        Assert.IsFalse(
          AzureAIUsage.HasChangedHour(CreateDateTime(DateToUse, 113002.123T)), 'Expected not to have changed hour');
        Assert.IsFalse(
          AzureAIUsage.HasChangedHour(CreateDateTime(DateToUse, 113000.123T)), 'Expected not to have changed hour');

        Assert.IsTrue(AzureAIUsage.HasChangedHour(CreateDateTime(DateToUse, 123001.123T)), 'Expected to have changed hour');
        Assert.IsTrue(AzureAIUsage.HasChangedHour(CreateDateTime(DateToUse, 103001.123T)), 'Expected to have changed hour');
        Assert.IsTrue(AzureAIUsage.HasChangedHour(CreateDateTime(DateToUse, 163001.123T)), 'Expected to have changed hour');
        Assert.IsTrue(AzureAIUsage.HasChangedHour(CreateDateTime(DateToUse, 013001.123T)), 'Expected to have changed hour');
        Assert.IsTrue(
          AzureAIUsage.HasChangedHour(CreateDateTime(CalcDate('<+1D>', DateToUse), TimeToUse)),
          'Expected to have changed hour');
        Assert.IsTrue(
          AzureAIUsage.HasChangedHour(CreateDateTime(CalcDate('<-1D>', DateToUse), TimeToUse)),
          'Expected to have changed hour');
        Assert.IsTrue(
          AzureAIUsage.HasChangedHour(CreateDateTime(CalcDate('<+1M>', DateToUse), TimeToUse)),
          'Expected to have changed hour');
        Assert.IsTrue(
          AzureAIUsage.HasChangedHour(CreateDateTime(CalcDate('<-1M>', DateToUse), TimeToUse)),
          'Expected to have changed hour');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIncrement()
    var
        AzureAIUsage: Record "Azure AI Usage";
        ImageAnalysisSetup: Record "Image Analysis Setup";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        MockAzureKeyVaultSecretProvider: DotNet MockAzureKeyVaultSecretProvider;
        DateToUse: Date;
        TimeToUse: Time;
    begin
        // [SCENARIO] Set a date, and check the increment function behaves as expected
        // [GIVEN] The period is set to hour, and the image analysis setup table is cleared
        LibraryLowerPermissions.SetO365Basic;
        ImageAnalysisSetup.DeleteAll;
        AzureAIUsage.DeleteAll;
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        TimeToUse := 113001.123T;
        DateToUse := DMY2Date(20, 4, 2010);
        AzureAIUsage.SetTestMode(DateToUse, TimeToUse);
        MockAzureKeyVaultSecretProvider := MockAzureKeyVaultSecretProvider.MockAzureKeyVaultSecretProvider;
        MockAzureKeyVaultSecretProvider.AddSecretMapping('AllowedApplicationSecrets', 'cognitive-vision-params');
        MockAzureKeyVaultSecretProvider.AddSecretMapping('cognitive-vision-params', StrSubstNo(MockSecretTxt, 'key==',
            'https://ussouthcentral.services.azureml.net/workspaces/something/services/blah/execute?api-version=2.0', 'Hour', 1800));
        // MockAzureKeyVaultSecretProvider.AddSecretMapping('machinelearning-default',MockSecretMLTxt);
        AzureKeyVaultTestLibrary.SetAzureKeyVaultSecretProvider(MockAzureKeyVaultSecretProvider);

        // [WHEN] we get the current status
        // [THEN] The setup record is initialized with 0
        Assert.AreEqual(
          0, AzureAIUsage.GetTotalProcessingTime(AzureAIUsage.Service::"Computer Vision"),
          'Expected the number of calls to be 0 (just created).');

        // [WHEN] We increment 3 times and get the status
        AzureAIUsage.IncrementTotalProcessingTime(AzureAIUsage.Service::"Computer Vision", 1);
        AzureAIUsage.IncrementTotalProcessingTime(AzureAIUsage.Service::"Computer Vision", 1);
        AzureAIUsage.IncrementTotalProcessingTime(AzureAIUsage.Service::"Computer Vision", 1);

        // [THEN] the call count is set to 3.
        Assert.AreEqual(
          3, AzureAIUsage.GetTotalProcessingTime(AzureAIUsage.Service::"Computer Vision"),
          'Expected increment to increment the number of calls.');

        // [GIVEN] the time is set to another hour
        TimeToUse := 123500T;
        DateToUse := DMY2Date(20, 4, 2010);
        AzureAIUsage.SetTestMode(DateToUse, TimeToUse);

        // [WHEN] we increment once and get the status
        AzureAIUsage.IncrementTotalProcessingTime(AzureAIUsage.Service::"Computer Vision", 1);

        // [THEN] a new setup record is initialized and incremented to 1, with the correct date and time, and there are 2 records in total
        Assert.AreEqual(
          1, AzureAIUsage.GetTotalProcessingTime(AzureAIUsage.Service::"Computer Vision"),
          'Expected increment to increment the number of calls.');
        Assert.AreEqual(1, AzureAIUsage.Count, 'Expected to have only 1 setup record');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidateApiUri()
    var
        ImageAnalysisSetup: Record "Image Analysis Setup";
    begin
        // [SCENARIO] Only URIs for Cognitive Services are allowed

        // [GIVEN] An empty Image Analysis Setup
        LibraryLowerPermissions.SetO365Basic;
        ImageAnalysisSetup.DeleteAll;
        ImageAnalysisSetup.Init;
        ImageAnalysisSetup.Insert;
        // [WHEN]

        // [THEN] Validating problematic URIs lead to errors
        asserterror ImageAnalysisSetup.Validate("Api Uri", 'http://westus.api.cognitive.microsoft.com/vision');
        Assert.ExpectedError(InvalidApiUriErr);

        asserterror ImageAnalysisSetup.Validate("Api Uri", 'https://westus.api.cognitive.microsoft2.com/vision');
        Assert.ExpectedError(InvalidApiUriErr);

        asserterror ImageAnalysisSetup.Validate("Api Uri",
            StrSubstNo('https://westus.api.cognitive.microsoft.com%1.evil.com/vision', '%2f'));

        // [GIVEN]

        // [WHEN]

        // [THEN] Validating correct URIs do not lead to errors
        ImageAnalysisSetup.Validate("Api Uri", '');

        ImageAnalysisSetup.Validate("Api Uri", 'https://westus.api.cognitive.microsoft.com/vision');

        ImageAnalysisSetup.Validate("Api Uri", 'https://somename.cognitiveservices.azure.com/');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApiKey()
    var
        ImageAnalysisSetup: Record "Image Analysis Setup";
    begin
        // [SCENARIO]

        // [GIVEN] An empty Image Analysis Setup
        LibraryLowerPermissions.SetO365Basic;
        ImageAnalysisSetup.DeleteAll;
        ImageAnalysisSetup.Init;
        ImageAnalysisSetup.Insert;

        // [WHEN]

        // [THEN] The API key is empty
        Assert.AreEqual('', ImageAnalysisSetup.GetApiKey, 'Api Key should be empty.');

        // [WHEN] An API key is set
        ImageAnalysisSetup.SetApiKey('123');

        // [THEN] The correct API key is retrieved
        Assert.AreEqual('123', ImageAnalysisSetup.GetApiKey, 'Api Key was not retrieved correctly.');

        // [WHEN] The Isolated Storage entry is deleted
        IsolatedStorageManagement.Delete(ImageAnalysisSetup."Api Key Key", DATASCOPE::Company);

        // [THEN] The API key is empty
        Assert.AreEqual('', ImageAnalysisSetup.GetApiKey, 'Api Key should be empty when value is deleted from Isolated Storage.');

        // [WHEN] An API key is set after that
        ImageAnalysisSetup.SetApiKey('1234');

        // [THEN] The correct API key is retrieved again
        Assert.AreEqual('1234', ImageAnalysisSetup.GetApiKey,
          'Api Key was not retrieved correctly after the value was deleted from isolated storage.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetupURIEndsInAnalyze()
    var
        ImageAnalysisSetup: TestPage "Image Analysis Setup";
    begin
        // [Feature] [Image Analysis]
        // [Scenario] Setup feature

        // [Given] The setup page opens and the user sets the correct URI
        LibraryLowerPermissions.SetO365Basic;
        ImageAnalysisSetup.OpenEdit;
        ImageAnalysisSetup."Api Uri".SetValue('https://cronus.api.cognitive.microsoft.com/vision/v1.0/analyze');

        // [When]

        // [Then]  Setup URI remains the same
        Assert.AreEqual('https://cronus.api.cognitive.microsoft.com/vision/v1.0/analyze',
          ImageAnalysisSetup."Api Uri".Value,
          'URI was modified');

        ImageAnalysisSetup."Api Uri".SetValue('https://cronus.api.cognitive.microsoft.com/vision/v1.0/analyze/');

        // [Then]  Setup URI remains the same
        Assert.AreEqual('https://cronus.api.cognitive.microsoft.com/vision/v1.0/analyze',
          ImageAnalysisSetup."Api Uri".Value,
          'URI was modified');

        ImageAnalysisSetup."Api Uri".SetValue('https://cronus.api.cognitive.microsoft.com/vision/v1.0/analyze/ ');

        // [Then]  Setup URI remains the same
        Assert.AreEqual('https://cronus.api.cognitive.microsoft.com/vision/v1.0/analyze',
          ImageAnalysisSetup."Api Uri".Value,
          'URI was modified');

        ImageAnalysisSetup.Close;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestSetupURIDoesNotEndInAnalyze()
    var
        ImageAnalysisSetup: TestPage "Image Analysis Setup";
    begin
        // [Feature] [Image Analysis]
        // [Scenario] Setup feature
        // [Given] The setup page opens and the user sets the correct URI but forgets to add /analyze in the end
        LibraryLowerPermissions.SetO365Basic;
        ImageAnalysisSetup.OpenEdit;

        // [When] User clicks yes in the correction confirm handler
        LibraryVariableStorage.Enqueue(true);
        ImageAnalysisSetup."Api Uri".SetValue('https://cronus.api.cognitive.microsoft.com/vision/v1.0');

        // [Then] Setup URI is corrected
        Assert.AreEqual('https://cronus.api.cognitive.microsoft.com/vision/v1.0/analyze',
          ImageAnalysisSetup."Api Uri".Value,
          'URI does not end in /analyze');

        LibraryVariableStorage.Enqueue(true);
        ImageAnalysisSetup."Api Uri".SetValue('https://cronus.api.cognitive.microsoft.com/vision/v1.0/');
        // [When] User clicks yes in the correction confirm handler
        // [Then] Setup URI is corrected
        Assert.AreEqual('https://cronus.api.cognitive.microsoft.com/vision/v1.0/analyze',
          ImageAnalysisSetup."Api Uri".Value,
          'URI does not end in /analyze');

        LibraryVariableStorage.Enqueue(true);
        ImageAnalysisSetup."Api Uri".SetValue('https://cronus.api.cognitive.microsoft.com/vision/v1.0/  ');
        // [When] User clicks yes in the correction confirm handler
        // [Then] Setup URI is corrected
        Assert.AreEqual('https://cronus.api.cognitive.microsoft.com/vision/v1.0/analyze',
          ImageAnalysisSetup."Api Uri".Value,
          'URI does not end in /analyze');

        LibraryVariableStorage.Enqueue(true);
        ImageAnalysisSetup."Api Uri".SetValue('https://cronus.api.cognitive.microsoft.com/vision/v1.0/  ');
        // [When] User clicks yes in the correction confirm handler
        // [Then] Setup URI is corrected
        Assert.AreEqual('https://cronus.api.cognitive.microsoft.com/vision/v1.0/analyze',
          ImageAnalysisSetup."Api Uri".Value,
          'URI does not end in /analyze');

        LibraryVariableStorage.Enqueue(false);
        ImageAnalysisSetup."Api Uri".SetValue('https://cronus.api.cognitive.microsoft.com/vision/v1.0/');
        // [Given] User clicks no in the correction confirm handler
        // [Then] URI stays the same
        Assert.AreEqual('https://cronus.api.cognitive.microsoft.com/vision/v1.0',
          ImageAnalysisSetup."Api Uri".Value,
          'URI does not end in /analyze');

        ImageAnalysisSetup.Close;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetupURICustomVision()
    var
        ImageAnalysisSetup: TestPage "Image Analysis Setup";
        CustomVisionURI: Text;
    begin
        // [Feature] [Image Analysis]
        // [Scenario] Setup feature

        // [Given] The setup page opens and the user sets custom vision URI
        LibraryLowerPermissions.SetO365Basic;
        ImageAnalysisSetup.OpenEdit;
        CustomVisionURI := 'https://southcentralus.api.cognitive.microsoft.com/customvision/v1.0/Prediction';
        ImageAnalysisSetup."Api Uri".SetValue(CustomVisionURI);

        // [When]

        // [Then] Setup URI remains the same
        Assert.AreEqual(CustomVisionURI,
          ImageAnalysisSetup."Api Uri".Value,
          'URI was modified');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean;
    end;
}

