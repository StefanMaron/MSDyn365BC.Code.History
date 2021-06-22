codeunit 135209 "Azure Key Vault Module Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Azure] [Key Vault]
    end;

    var
        Assert: Codeunit Assert;
        MLForecastTok: Label 'ml-forecast';
        MachineLearningTok: Label 'machinelearning';
        QBOConsumerKeyTok: Label 'qbo-consumerkey';
        QBOConsumerSecretTok: Label 'qbo-consumersecret';
        AmcNameTok: Label 'amcname';
        AmcPasswordTok: Label 'amcpassword';
        YodleeCobrandNameTok: Label 'YodleeCobrandName';
        YodleeCobrandPasswordTok: Label 'YodleeCobrandPassword';
        YodleeServiceUriTok: Label 'YodleeServiceUri';
        SecretNotFoundErr: Label '%1 is not an application secret.', Comment = '%1 = Secret Name. %2 = Available secrets.';
        LibraryUtility: Codeunit "Library - Utility";
        AllowedApplicationSecretsSecretNameTxt: Label 'AllowedApplicationSecrets', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestKeyVault()
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        AzureKeyVaultTestLibrary: Codeunit "Azure Key Vault Test Library";
        MockAzureKeyvaultSecretProvider: DotNet MockAzureKeyVaultSecretProvider;
        Secret: Text;
    begin
        // [SCENARIO] When the key vault is called, the correct value is retrieved

        // [GIVEN] A configured Azure Key Vault
        MockAzureKeyvaultSecretProvider := MockAzureKeyvaultSecretProvider.MockAzureKeyVaultSecretProvider;
        MockAzureKeyvaultSecretProvider.AddSecretMapping(AllowedApplicationSecretsSecretNameTxt, 'ml-forecast,');
        MockAzureKeyvaultSecretProvider.AddSecretMappingFromFile('ml-forecast', LibraryUtility.GetInetRoot + GetFakeSecret);
        AzureKeyVaultTestLibrary.SetAzureKeyVaultSecretProvider(MockAzureKeyvaultSecretProvider);

        // [WHEN] The key vault is called
        AzureKeyVault.GetAzureKeyVaultSecret('ml-forecast', Secret);

        // [THEN] The value is retrieved
        Assert.AreEqual('SecretFromKeyVault', Secret, 'The returned secret was incorrect');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestKeyVaultCache()
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        AzureKeyVaultTestLibrary: Codeunit "Azure Key Vault Test Library";
        MockAzureKeyvaultSecretProvider: DotNet MockAzureKeyVaultSecretProvider;
        Secret: Text;
    begin
        // [SCENARIO] When the key vault secret provider is changed, the cache is cleared and the new value is retrieved

        // [GIVEN] A configured Azure Key Vault
        MockAzureKeyvaultSecretProvider := MockAzureKeyvaultSecretProvider.MockAzureKeyVaultSecretProvider;
        MockAzureKeyvaultSecretProvider.AddSecretMapping(AllowedApplicationSecretsSecretNameTxt, ',ml-forecast');
        MockAzureKeyvaultSecretProvider.AddSecretMappingFromFile('ml-forecast', LibraryUtility.GetInetRoot + GetAnotherFakeSecret);
        AzureKeyVaultTestLibrary.SetAzureKeyVaultSecretProvider(MockAzureKeyvaultSecretProvider);

        // [WHEN] The key vault is called
        AzureKeyVault.GetAzureKeyVaultSecret('ml-forecast', Secret);

        // [THEN] The value is retrieved
        Assert.AreEqual('AnotherSecretFromTheKeyVault', Secret, 'The returned secret was incorrect');

        // [WHEN] The Key Vault Secret Provider is changed
        MockAzureKeyvaultSecretProvider := MockAzureKeyvaultSecretProvider.MockAzureKeyVaultSecretProvider;
        MockAzureKeyvaultSecretProvider.AddSecretMapping(AllowedApplicationSecretsSecretNameTxt, 'ml-forecast');
        MockAzureKeyvaultSecretProvider.AddSecretMappingFromFile('ml-forecast', LibraryUtility.GetInetRoot + GetFakeSecret);
        AzureKeyVaultTestLibrary.SetAzureKeyVaultSecretProvider(MockAzureKeyvaultSecretProvider);
        AzureKeyVault.GetAzureKeyVaultSecret('ml-forecast', Secret);

        // [THEN] The cache is cleared and the value is retrieved
        Assert.AreEqual('SecretFromKeyVault', Secret, 'The returned secret was incorrect');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRetrievalOfSecrets()
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        AzureKeyVaultTestLibrary: Codeunit "Azure Key Vault Test Library";
        TimeSeriesManagement: Codeunit "Time Series Management";
        MockAzureKeyvaultSecretProvider: DotNet MockAzureKeyVaultSecretProvider;
        MLForecast: Text;
        MachineLearning: Text;
        QBOConsumerKey: Text;
        QBOConsumerSecret: Text;
        AmcName: Text;
        Amcpassword: Text;
        YodleeCobrandPassword: Text;
        YodleeCobranName: Text;
        YodleeServiceUri: Text;
        APIURI: Text[250];
        APIKey: Text[200];
        Limit: Decimal;
        LimitType: Option;
    begin
        // [SCENARIO] Azure Key vault is present and stores the following keys

        // [GIVEN] A key vault
        MockAzureKeyvaultSecretProvider := MockAzureKeyvaultSecretProvider.MockAzureKeyVaultSecretProvider;
        MockAzureKeyvaultSecretProvider.AddSecretMappingFromFile(
          StrSubstNo('ml-forecast-%1', TenantId), LibraryUtility.GetInetRoot + GetMachineLearningCredentialsSecret);
        MockAzureKeyvaultSecretProvider.AddSecretMappingFromFile(
          MLForecastTok, LibraryUtility.GetInetRoot + GetMachineLearningCredentialsSecret);
        MockAzureKeyvaultSecretProvider.AddSecretMappingFromFile(
          MachineLearningTok, LibraryUtility.GetInetRoot + GetMachineLearningCredentialsSecret);
        MockAzureKeyvaultSecretProvider.AddSecretMappingFromFile(
          StrSubstNo('machinelearning-%1', TenantId), LibraryUtility.GetInetRoot + GetMachineLearningCredentialsSecret);
        MockAzureKeyvaultSecretProvider.AddSecretMappingFromFile(
          QBOConsumerKeyTok, LibraryUtility.GetInetRoot + GetMachineLearningCredentialsSecret);
        MockAzureKeyvaultSecretProvider.AddSecretMappingFromFile(
          QBOConsumerSecretTok, LibraryUtility.GetInetRoot + GetMachineLearningCredentialsSecret);
        MockAzureKeyvaultSecretProvider.AddSecretMappingFromFile(
          AmcNameTok, LibraryUtility.GetInetRoot + GetMachineLearningCredentialsSecret);
        MockAzureKeyvaultSecretProvider.AddSecretMappingFromFile(
          AmcPasswordTok, LibraryUtility.GetInetRoot + GetMachineLearningCredentialsSecret);
        MockAzureKeyvaultSecretProvider.AddSecretMappingFromFile(
          YodleeCobrandNameTok, LibraryUtility.GetInetRoot + GetMachineLearningCredentialsSecret);
        MockAzureKeyvaultSecretProvider.AddSecretMappingFromFile(
          YodleeCobrandPasswordTok, LibraryUtility.GetInetRoot + GetMachineLearningCredentialsSecret);
        MockAzureKeyvaultSecretProvider.AddSecretMappingFromFile(
          YodleeServiceUriTok, LibraryUtility.GetInetRoot + GetMachineLearningCredentialsSecret);

        AzureKeyVaultTestLibrary.SetAzureKeyVaultSecretProvider(MockAzureKeyvaultSecretProvider);

        // [WHEN] The secret names have been allowed in the list
        MockAzureKeyvaultSecretProvider.AddSecretMapping(AllowedApplicationSecretsSecretNameTxt,
          StrSubstNo('%1,%2,%3,%4,%5,%6,%7,%8,%9', MLForecastTok, MachineLearningTok, QBOConsumerKeyTok,
            QBOConsumerSecretTok, AmcNameTok, AmcPasswordTok, YodleeCobrandNameTok, YodleeCobrandPasswordTok,
            YodleeServiceUriTok));

        // [WHEN] The secrets are retrieved
        TimeSeriesManagement.GetMLForecastCredentials(APIURI, APIKey, LimitType, Limit);
        AzureKeyVault.GetAzureKeyVaultSecret(MLForecastTok, MLForecast);
        AzureKeyVault.GetAzureKeyVaultSecret(MachineLearningTok, MachineLearning);
        AzureKeyVault.GetAzureKeyVaultSecret(QBOConsumerKeyTok, QBOConsumerKey);
        AzureKeyVault.GetAzureKeyVaultSecret(QBOConsumerSecretTok, QBOConsumerSecret);
        AzureKeyVault.GetAzureKeyVaultSecret(AmcNameTok, AmcName);
        AzureKeyVault.GetAzureKeyVaultSecret(AmcPasswordTok, Amcpassword);
        AzureKeyVault.GetAzureKeyVaultSecret(YodleeCobrandNameTok, YodleeCobranName);
        AzureKeyVault.GetAzureKeyVaultSecret(YodleeCobrandPasswordTok, YodleeCobrandPassword);
        AzureKeyVault.GetAzureKeyVaultSecret(YodleeServiceUriTok, YodleeServiceUri);

        // [THEN] The values returned are not empty
        Assert.AreNotEqual(APIURI, '', 'API URI was empty');
        Assert.AreNotEqual(APIKey, '', 'API Key was empty');
        Assert.AreNotEqual(LimitType, '', 'Limit type was empty');
        Assert.AreNotNearlyEqual(Limit, 0, 0.01, 'Timeout was 0');
        Assert.AreNotEqual(MLForecast, '', 'MLForecast was empty');
        Assert.AreNotEqual(MachineLearning, '', 'Machine learning was empty');
        Assert.AreNotEqual(QBOConsumerKey, '', 'QBOConsumerKey was empty');
        Assert.AreNotEqual(QBOConsumerSecret, '', 'QBOConsumerSecret was empty');
        Assert.AreNotEqual(AmcName, '', 'AmcName was empty');
        Assert.AreNotEqual(Amcpassword, '', 'Amcpassword was empty');
        Assert.AreNotEqual(YodleeCobranName, '', 'YodleeCobranName was empty');
        Assert.AreNotEqual(YodleeCobrandPassword, '', 'YodleeCobrandPassword was empty');
        Assert.AreNotEqual(YodleeServiceUri, '', 'YodleeServiceUri was empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRetrievalOfUnkownSecretFails()
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        AzureKeyVaultTestLibrary: Codeunit "Azure Key Vault Test Library";
        MockAzureKeyvaultSecretProvider: DotNet MockAzureKeyVaultSecretProvider;
        Secret: Text;
    begin
        // [SCENARIO] When an unknown key is provided, then retrieval of the secret fails

        // [GIVEN] A configured Azure Key Vault
        MockAzureKeyvaultSecretProvider := MockAzureKeyvaultSecretProvider.MockAzureKeyVaultSecretProvider;
        MockAzureKeyvaultSecretProvider.AddSecretMapping(AllowedApplicationSecretsSecretNameTxt, 'somesecret');
        MockAzureKeyvaultSecretProvider.AddSecretMappingFromFile('somesecret', LibraryUtility.GetInetRoot + GetAnotherFakeSecret);
        AzureKeyVaultTestLibrary.SetAzureKeyVaultSecretProvider(MockAzureKeyvaultSecretProvider);

        // [WHEN] The key vault is called with an unknown key
        asserterror AzureKeyVault.GetAzureKeyVaultSecret('somekeythatdoesnotexist', Secret);

        // [THEN] An error is thrown
        Assert.ExpectedError(StrSubstNo(SecretNotFoundErr, 'somekeythatdoesnotexist'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRetrievalOfImageAnalysisSecrets()
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        AzureKeyVaultTestLibrary: Codeunit "Azure Key Vault Test Library";
        ImageAnalysisManagement: Codeunit "Image Analysis Management";
        MockAzureKeyvaultSecretProvider: DotNet MockAzureKeyVaultSecretProvider;
        ApiUri: Text[250];
        ApiKey: Text[200];
        LimitType: Option Year,Month,Day,Hour;
        LimitValue: Integer;
    begin
        // [SCENARIO] Retrival of image analysis secrets from Azure Key Vault

        // [GIVEN] A key vault
        MockAzureKeyvaultSecretProvider := MockAzureKeyvaultSecretProvider.MockAzureKeyVaultSecretProvider;
        MockAzureKeyvaultSecretProvider.AddSecretMapping(AllowedApplicationSecretsSecretNameTxt, 'cognitive-vision-params');
        MockAzureKeyvaultSecretProvider.AddSecretMappingFromFile(
          'cognitive-vision-params', LibraryUtility.GetInetRoot + GetImageAnalysisSecret);
        AzureKeyVaultTestLibrary.SetAzureKeyVaultSecretProvider(MockAzureKeyvaultSecretProvider);

        // [WHEN] The secrets are retrieved
        ImageAnalysisManagement.GetImageAnalysisCredentials(ApiKey, ApiUri, LimitType, LimitValue);

        // [THEN] The values returned are correct
        Assert.AreEqual(ApiUri, 'endpoint1', 'Retrieved Api Uri was wrong.');
        Assert.AreEqual(ApiKey, 'key1', 'Retrieved Api Key was wrong.');
        Assert.AreEqual(LimitType, LimitType::Month, 'Retrieved Limit type was wrong.');
        Assert.AreEqual(LimitValue, 200, 'Retrieved Limit type was wrong.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRetrievalOfSMTPSecrets()
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
        AzureKeyVault: Codeunit "Azure Key Vault";
        AzureKeyVaultTestLibrary: Codeunit "Azure Key Vault Test Library";
        MailManagement: Codeunit "Mail Management";
        MockAzureKeyvaultSecretProvider: DotNet MockAzureKeyVaultSecretProvider;
    begin
        // [SCENARIO] Retrival of SMTP secrets from Azure Key Vault

        // [GIVEN] A key vault
        MockAzureKeyvaultSecretProvider := MockAzureKeyvaultSecretProvider.MockAzureKeyVaultSecretProvider;
        MockAzureKeyvaultSecretProvider.AddSecretMapping(AllowedApplicationSecretsSecretNameTxt, 'SmtpSetup');
        MockAzureKeyvaultSecretProvider.AddSecretMappingFromFile(
          'SmtpSetup', LibraryUtility.GetInetRoot + GetSMTPSecret);
        AzureKeyVaultTestLibrary.SetAzureKeyVaultSecretProvider(MockAzureKeyvaultSecretProvider);

        // [WHEN] The secrets are retrieved
        MailManagement.GetSMTPCredentials(SMTPMailSetup);

        // [THEN] The values returned are correct
        Assert.AreEqual('smtp.test.com', SMTPMailSetup."SMTP Server", 'Retrieved SMTP Server was wrong.');
        Assert.AreEqual(25, SMTPMailSetup."SMTP Server Port", 'Retrieved SMTP Server Port was wrong.');
        Assert.AreEqual(SMTPMailSetup.Authentication::Basic, SMTPMailSetup.Authentication, 'Retrieved Authentication was wrong.');
        Assert.AreEqual('TestUser', SMTPMailSetup."User ID", 'Retrieved User ID was wrong.');
        Assert.AreEqual('Pass123!', SMTPMailSetup.GetPassword, 'Retrieved Password was wrong.');
        Assert.AreEqual(true, SMTPMailSetup."Secure Connection", 'Retrieved Secure Connection was wrong.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRetrievalOfIsvSecret()
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        AzureKeyVaultTestLibrary: Codeunit "Azure Key Vault Test Library";
        MockAzureKeyvaultSecretProvider: DotNet MockAzureKeyVaultSecretProvider;
        Secret: Text;
    begin
        // [SCENARIO] When an ISV key is provided, then retrieval of the secret succeeds

        // [GIVEN] A configured Azure Key Vault
        MockAzureKeyvaultSecretProvider := MockAzureKeyvaultSecretProvider.MockAzureKeyVaultSecretProvider;
        MockAzureKeyvaultSecretProvider.AddSecretMapping(AllowedApplicationSecretsSecretNameTxt, 'isv-anykey');
        MockAzureKeyvaultSecretProvider.AddSecretMappingFromFile('isv-anykey', LibraryUtility.GetInetRoot + GetFakeSecret);
        AzureKeyVaultTestLibrary.SetAzureKeyVaultSecretProvider(MockAzureKeyvaultSecretProvider);

        // [WHEN] The key vault is called with an ISV key
        AzureKeyVault.GetAzureKeyVaultSecret('isv-anykey', Secret);

        // [THEN] A secret is returned
        Assert.AreEqual('SecretFromKeyVault', Secret, 'The returned secret was incorrect');
    end;

    [Normal]
    local procedure GetFakeSecret(): Text
    begin
        exit('\App\Test\Files\AzureKeyVaultSecret\FakeSecret.txt');
    end;

    [Normal]
    local procedure GetAnotherFakeSecret(): Text
    begin
        exit('\App\Test\Files\AzureKeyVaultSecret\AnotherFakeSecret.txt');
    end;

    local procedure GetMachineLearningCredentialsSecret(): Text
    begin
        exit('\App\Test\Files\AzureKeyVaultSecret\TimeSeriesForecastSecret.txt');
    end;

    [Normal]
    local procedure GetImageAnalysisSecret(): Text
    begin
        exit('\App\Test\Files\AzureKeyVaultSecret\ImageAnalysisSecret.txt');
    end;

    [Normal]
    local procedure GetSMTPSecret(): Text
    begin
        exit('\App\Test\Files\AzureKeyVaultSecret\SMTPSetupSecret.txt');
    end;
}

