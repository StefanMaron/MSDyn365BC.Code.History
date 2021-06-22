codeunit 135207 "Image Analysis Setup Test"
{
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
        MockSecretTxt: Label '[{"key":"%1","endpoint":"%2","limittype":"%3","limitvalue":"%4"}]', Locked = true;
        AzureKeyVault: Codeunit "Azure Key Vault";
        AzureKeyVaultTestLibrary: Codeunit "Azure Key Vault Test Library";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";

    [Test]
    [Scope('OnPrem')]
    procedure TestValidateApiUri()
    var
        ImageAnalysisSetup: Record "Image Analysis Setup";
    begin
        // [SCENARIO] Only URIs for Cognitive Services are allowed

        // [GIVEN] An empty Image Analysis Setup
        LibraryLowerPermissions.SetO365Basic;
        ImageAnalysisSetup.DeleteAll();
        ImageAnalysisSetup.Init();
        ImageAnalysisSetup.Insert();
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
        ImageAnalysisSetup.DeleteAll();
        ImageAnalysisSetup.Init();
        ImageAnalysisSetup.Insert();

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

