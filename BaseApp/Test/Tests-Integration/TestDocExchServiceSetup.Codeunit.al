codeunit 134413 "Test Doc. Exch. Service Setup"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Document Exchange Service]
    end;

    var
        Assert: Codeunit Assert;
        InvalidUriErr: Label 'The URI is not valid.';

    [Test]
    [Scope('OnPrem')]
    procedure TestDocExchServiceSetupUrlBlank()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        // Init
        DocExchServiceSetup.Init;

        // Execute
        DocExchServiceSetup.Validate("Service URL", '');

        // Validate
        Assert.AreEqual('', DocExchServiceSetup."Service URL", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDocExchServiceSetupUrlInvalidUrl()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        // Init
        DocExchServiceSetup.Init;

        // Execute
        asserterror DocExchServiceSetup.Validate("Service URL", 'http://this is an invalid url');

        // Validate
        Assert.ExpectedError(InvalidUriErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDocExchServiceSetupUrlPositive()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        // Init
        DocExchServiceSetup.Init;

        // Execute
        DocExchServiceSetup.Validate("Service URL", 'https://microsoft.com');

        // Validate
        Assert.AreEqual('https://microsoft.com', DocExchServiceSetup."Service URL", '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure TestDocExchServiceSetupInsertDefault()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        DocExchServiceSetupCard: TestPage "Doc. Exch. Service Setup";
    begin
        // Init
        if DocExchServiceSetup.Get then
            DocExchServiceSetup.Delete(true);

        // Exectute
        DocExchServiceSetupCard.OpenEdit;
        Assert.AreEqual('', DocExchServiceSetupCard."Service URL".Value, '');
        DocExchServiceSetupCard.SetURLsToDefault.Invoke;
        DocExchServiceSetupCard.Close;

        // Validate
        DocExchServiceSetup.Get;
        Assert.AreNotEqual('', DocExchServiceSetup."Service URL", '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure TestDocExchServiceSetupPagePassword()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        DocExchServiceSetupCard: TestPage "Doc. Exch. Service Setup";
        TokenTxt: Text;
        TokenSecretTxt: Text;
        ConsumerKeyTxt: Text;
        ConsumerSecretTxt: Text;
        DocExchServiceIDTxt: Text;
    begin
        // Init
        if DocExchServiceSetup.Get then
            DocExchServiceSetup.Delete(true);
        Assert.IsTrue(DocExchServiceSetup.IsEmpty, '');

        TokenTxt := Format(CreateGuid);
        TokenSecretTxt := Format(CreateGuid);
        ConsumerKeyTxt := Format(CreateGuid);
        ConsumerSecretTxt := Format(CreateGuid);
        DocExchServiceIDTxt := Format(CreateGuid);

        // Execute
        DocExchServiceSetupCard.OpenEdit;
        DocExchServiceSetupCard.TokenValue.Value := TokenTxt;
        DocExchServiceSetupCard.TokenSecret.Value := TokenSecretTxt;
        DocExchServiceSetupCard.ConsumerKey.Value := ConsumerKeyTxt;
        DocExchServiceSetupCard.ConsumerSecret.Value := ConsumerSecretTxt;
        DocExchServiceSetupCard.DocExchTenantID.Value := DocExchServiceIDTxt;
        DocExchServiceSetupCard.Close;

        // Verify
        DocExchServiceSetup.Get;
        Assert.IsTrue(DocExchServiceSetup.HasPassword(DocExchServiceSetup.Token), '');
        Assert.IsTrue(DocExchServiceSetup.HasPassword(DocExchServiceSetup."Token Secret"), '');
        Assert.IsTrue(DocExchServiceSetup.HasPassword(DocExchServiceSetup."Consumer Key"), '');
        Assert.IsTrue(DocExchServiceSetup.HasPassword(DocExchServiceSetup."Consumer Secret"), '');
        Assert.IsTrue(DocExchServiceSetup.HasPassword(DocExchServiceSetup."Doc. Exch. Tenant ID"), '');
        Assert.AreEqual(TokenTxt, DocExchServiceSetup.GetPassword(DocExchServiceSetup.Token), '');
        Assert.AreEqual(TokenSecretTxt, DocExchServiceSetup.GetPassword(DocExchServiceSetup."Token Secret"), '');
        Assert.AreEqual(ConsumerKeyTxt, DocExchServiceSetup.GetPassword(DocExchServiceSetup."Consumer Key"), '');
        Assert.AreEqual(ConsumerSecretTxt, DocExchServiceSetup.GetPassword(DocExchServiceSetup."Consumer Secret"), '');
        Assert.AreEqual(DocExchServiceIDTxt, DocExchServiceSetup.GetPassword(DocExchServiceSetup."Doc. Exch. Tenant ID"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDocExchServiceMgtCheckCredentials()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        DocExchServiceMgt: Codeunit "Doc. Exch. Service Mgt.";
    begin
        // Init
        if DocExchServiceSetup.Delete(true) then;
        DocExchServiceSetup.Init;
        DocExchServiceSetup.Insert(true);

        // Execute
        asserterror DocExchServiceMgt.CheckConnection; // triggers a confirm and page.runmodal

        // Verify
        Assert.ExpectedError('The tokens and secret keys must be filled in the Doc. Exch. Service Setup window.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDocExchServiceMgtCheckCredentialsMissing()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        DocExchServiceMgt: Codeunit "Doc. Exch. Service Mgt.";
    begin
        // Init
        if DocExchServiceSetup.Get then
            DocExchServiceSetup.Delete(true);

        // Execute
        asserterror DocExchServiceMgt.CheckConnection;  // triggers a confirm

        // Verify
        Assert.ExpectedError('The tokens and secret keys must be filled in the Doc. Exch. Service Setup window.');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(Question: Text[1024]; var Answer: Boolean)
    begin
        Answer := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Answer: Boolean)
    begin
        Answer := true;
    end;
}

