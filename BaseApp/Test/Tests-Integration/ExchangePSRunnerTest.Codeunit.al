codeunit 139057 "Exchange PS Runner Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [INT] [Exchange PowerShell Runner]
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        UseO365: Option Yes,No;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetSetCredentials()
    var
        TempOfficeAdminCredentials: Record "Office Admin. Credentials" temporary;
        ExchangePowerShellRunner: Codeunit "Exchange PowerShell Runner";
        Username: Text[80];
        Password: Text[30];
    begin
        // Setup: username and password
        GenerateRandomText(Username, 40);
        GenerateRandomText(Password, 20);

        // Exercise: setting credentials
        ExchangePowerShellRunner.SetCredentials(Username, Password);

        // Verify: we should get the same credentials back when we request them
        ExchangePowerShellRunner.GetCredentials(TempOfficeAdminCredentials);
        Assert.AreEqual(TempOfficeAdminCredentials.Email, Username, 'User/email mismatch.');
        Assert.AreEqual(TempOfficeAdminCredentials.GetPassword, Password, 'Password mismatch.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetEndpoint()
    var
        TempOfficeAdminCredentials: Record "Office Admin. Credentials" temporary;
        ExchangePowerShellRunner: Codeunit "Exchange PowerShell Runner";
        Endpoint: Text[250];
    begin
        // Setup: endpoint
        GenerateRandomText(Endpoint, 150);

        // Exercise: setting endpoint
        ExchangePowerShellRunner.SetEndpoint(Endpoint);

        // Verify: the endpoint was set properly
        ExchangePowerShellRunner.GetCredentials(TempOfficeAdminCredentials);
        Assert.AreEqual(TempOfficeAdminCredentials.Endpoint, Endpoint, 'Endpoint mismatch.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDefaultEndpoint()
    var
        TempOfficeAdminCredentials: Record "Office Admin. Credentials" temporary;
        ExchangePowerShellRunner: Codeunit "Exchange PowerShell Runner";
        Endpoint: Text[250];
    begin
        // Setup: an initial endpoint
        GenerateRandomText(Endpoint, 150);

        // Exercise: setting the endpoint to the generated value and then an empty string
        ExchangePowerShellRunner.SetEndpoint(Endpoint);
        ExchangePowerShellRunner.SetEndpoint('');

        // Verify: The endpoint is the default endpoint
        ExchangePowerShellRunner.GetCredentials(TempOfficeAdminCredentials);
        Assert.AreEqual(TempOfficeAdminCredentials.Endpoint, TempOfficeAdminCredentials.DefaultEndpoint, 'Endpoint mismatch.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestO365Endpoint()
    var
        TempOfficeAdminCredentials: Record "Office Admin. Credentials" temporary;
        ExchangePowerShellRunner: Codeunit "Exchange PowerShell Runner";
    begin
        // Setup

        // Exercise

        // Verify: the PS runner O365 endpoint is the default endpoint
        Assert.AreEqual(
          ExchangePowerShellRunner.O365PSEndpoint, TempOfficeAdminCredentials.DefaultEndpoint,
          'Endpoint did not match the expected default.');
    end;

    [Test]
    [HandlerFunctions('O365CredentialPromptHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestPromptO365Credentials()
    var
        TempOfficeAdminCredentials: Record "Office Admin. Credentials" temporary;
        ExchangePowerShellRunner: Codeunit "Exchange PowerShell Runner";
        Email: Text[80];
        Password: Text[30];
    begin
        // Setup: random credential values
        GenerateRandomText(Email, 40);
        GenerateRandomText(Password, 20);
        LibraryVariableStorage.Enqueue(Email);
        LibraryVariableStorage.Enqueue(Password);

        // Exercise: run the credential prompt, calling the handler to add the values to the dialog
        ExchangePowerShellRunner.PromptForCredentials;

        // Verify: credentials are set properly
        ExchangePowerShellRunner.GetCredentials(TempOfficeAdminCredentials);
        Assert.AreEqual(Email, TempOfficeAdminCredentials.Email, 'Email mismatch.');
        Assert.AreEqual(Password, TempOfficeAdminCredentials.GetPassword, 'Password mismatch.');
    end;

    [Test]
    [HandlerFunctions('ExchangeCredentialPromptHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestPromptExchangeCredentials()
    var
        TempOfficeAdminCredentials: Record "Office Admin. Credentials" temporary;
        ExchangePowerShellRunner: Codeunit "Exchange PowerShell Runner";
        Username: Text[80];
        Password: Text[30];
        Endpoint: Text[250];
    begin
        // Setup: random credential values
        GenerateRandomText(Username, 40);
        GenerateRandomText(Password, 20);
        GenerateRandomText(Endpoint, 150);

        LibraryVariableStorage.Enqueue(Username);
        LibraryVariableStorage.Enqueue(Password);
        LibraryVariableStorage.Enqueue(Endpoint);

        // Exercise: run the credential prompt, calling the handler to add the values to the dialog
        ExchangePowerShellRunner.PromptForCredentials;

        // Verify: credentials are set properly
        ExchangePowerShellRunner.GetCredentials(TempOfficeAdminCredentials);
        Assert.AreEqual(Username, TempOfficeAdminCredentials.Email, 'Username mismatch.');
        Assert.AreEqual(Password, TempOfficeAdminCredentials.GetPassword, 'Password mismatch.');
        Assert.AreEqual(Endpoint, TempOfficeAdminCredentials.Endpoint, 'Endpoint mismatch.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNoPromptIfCredentialsSet()
    var
        TempOfficeAdminCredentials: Record "Office Admin. Credentials" temporary;
        ExchangePowerShellRunner: Codeunit "Exchange PowerShell Runner";
        Username: Text[80];
        Password: Text[30];
        Endpoint: Text[250];
    begin
        // Setup: random credential values
        GenerateRandomText(Username, 40);
        GenerateRandomText(Password, 20);
        GenerateRandomText(Endpoint, 150);

        // Exercise: set credentials on the codeunit directly
        ExchangePowerShellRunner.SetCredentials(Username, Password);
        ExchangePowerShellRunner.SetEndpoint(Endpoint);

        // Verify: the credential prompt should not be run and it contains the correct credentials
        ExchangePowerShellRunner.PromptForCredentials;

        ExchangePowerShellRunner.GetCredentials(TempOfficeAdminCredentials);
        Assert.AreEqual(Username, TempOfficeAdminCredentials.Email, 'Username mismatch.');
        Assert.AreEqual(Password, TempOfficeAdminCredentials.GetPassword, 'Password mismatch.');
        Assert.AreEqual(Endpoint, TempOfficeAdminCredentials.Endpoint, 'Endpoint mismatch.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestResetInitialization()
    var
        TempOfficeAdminCredentials: Record "Office Admin. Credentials" temporary;
        ExchangePowerShellRunner: Codeunit "Exchange PowerShell Runner";
        Username: Text[80];
        Password: Text[30];
        Endpoint: Text[250];
    begin
        // Setup: random credential and endpoint values
        GenerateRandomText(Username, 40);
        GenerateRandomText(Password, 20);
        GenerateRandomText(Endpoint, 150);

        // Exercise: initialize and reset initialization
        ExchangePowerShellRunner.SetCredentials(Username, Password);
        ExchangePowerShellRunner.SetEndpoint(Endpoint);
        ExchangePowerShellRunner.ResetInitialization;

        // Verify: credential values should be empty
        ExchangePowerShellRunner.GetCredentials(TempOfficeAdminCredentials);
        Assert.AreEqual('', TempOfficeAdminCredentials.Email, 'Username mismatch.');
        Assert.AreEqual('', TempOfficeAdminCredentials.GetPassword, 'Password mismatch.');
        Assert.AreEqual('', TempOfficeAdminCredentials.Endpoint, 'Endpoint mismatch.');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure O365CredentialPromptHandler(var OfficeAdminCredentialsDlg: TestPage "Office Admin. Credentials")
    var
        UsernameOrEmail: Text[80];
        Password: Text[30];
    begin
        UsernameOrEmail := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(UsernameOrEmail));
        Password := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(Password));

        OfficeAdminCredentialsDlg.UseO365.SetValue(UseO365::No);
        OfficeAdminCredentialsDlg.ActionNext.Invoke;

        OfficeAdminCredentialsDlg.O365Email.SetValue(UsernameOrEmail);
        OfficeAdminCredentialsDlg.O365Password.SetValue(Format(Password));
        OfficeAdminCredentialsDlg.ActionFinish.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ExchangeCredentialPromptHandler(var OfficeAdminCredentialsDlg: TestPage "Office Admin. Credentials")
    var
        UsernameOrEmail: Text[80];
        Password: Text[30];
        Endpoint: Text[250];
    begin
        UsernameOrEmail := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(UsernameOrEmail));
        Password := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(Password));
        Endpoint := CopyStr(LibraryVariableStorage.DequeueText, 1, MaxStrLen(Endpoint));

        OfficeAdminCredentialsDlg.UseO365.SetValue(UseO365::Yes);
        OfficeAdminCredentialsDlg.ActionNext.Invoke;

        OfficeAdminCredentialsDlg.OnPremUsername.SetValue(UsernameOrEmail);
        OfficeAdminCredentialsDlg.OnPremPassword.SetValue(Password);
        OfficeAdminCredentialsDlg.Endpoint.SetValue(Endpoint);
        OfficeAdminCredentialsDlg.ActionFinish.Invoke;
    end;

    [Normal]
    [Scope('OnPrem')]
    procedure GenerateRandomText(var Text: Text; Length: Integer)
    var
        LibraryUtility: Codeunit "Library - Utility";
    begin
        Text := CopyStr(Format(LibraryUtility.GenerateRandomText(Length)), 1, MaxStrLen(Text));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}

