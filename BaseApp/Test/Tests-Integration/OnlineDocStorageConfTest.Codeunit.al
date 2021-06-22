codeunit 139100 "Online Doc. Storage Conf Test"
{
    Permissions = TableData "Document Service" = imd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [INT] [Document Service] [UI]
    end;

    var
        Assert: Codeunit Assert;

    [Normal]
    local procedure InitializeConfig()
    var
        Config: Record "Document Service";
    begin
        Config.DeleteAll;

        Config.Init;
        Config."Service ID" := 'Service ID';
        Config.Description := 'Description';
        Config.Location := 'http://location';
        Config."User Name" := 'User Name';
        Config."Document Repository" := 'Document Repository';
        Config.Folder := 'Folder';
        Config.Insert;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestConfigSuccessful()
    var
        DocServPage: TestPage "Document Service Config";
    begin
        InitializeConfig;

        DocServPage.OpenEdit;

        DocServPage."Service ID".SetValue('Service ID');
        Assert.AreEqual(DocServPage."Service ID".Value, 'SERVICE ID', 'Setting Service ID value failed');

        DocServPage.Description.SetValue('Description');
        Assert.AreEqual(DocServPage.Description.Value, 'Description', 'Setting Description value failed');

        DocServPage.Location.SetValue('Location');
        Assert.AreEqual(DocServPage.Location.Value, 'Location', 'Setting Location value failed');

        DocServPage."Document Repository".SetValue('Document Repository');
        Assert.AreEqual(DocServPage."Document Repository".Value, 'Document Repository', 'Setting Doc. Repository value failed');

        DocServPage.Folder.SetValue('Folder');
        Assert.AreEqual(DocServPage.Folder.Value, 'Folder', 'Setting Folder value failed');

        DocServPage."User Name".SetValue('User Name');
        Assert.AreEqual(DocServPage."User Name".Value, 'User Name', 'Setting User Name value failed');

        Assert.IsTrue(DocServPage."Test Connection".Enabled, 'Validation of config data not enabled');
        DocServPage."Test Connection".Invoke;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestUnsuccessfulTestConnection()
    var
        DocumentService: Record "Document Service";
        DocServPage: TestPage "Document Service Config";
    begin
        // Expect Test Connection to fail fast due to table validation failing.
        // This test intentionally only tests CAL code without testing the full validation stack.

        DocumentService.DeleteAll;
        DocServPage.OpenEdit;

        // Description is not mandatory but we want to trigger validation on the record.
        DocServPage.Description.SetValue('Description');
        DocServPage."Test Connection".Invoke;
        Assert.IsTrue(DocServPage.ValidationErrorCount > 0, 'Validation errors did not occur');

        DocServPage.Location.SetValue('Location');
        DocServPage."Test Connection".Invoke;
        Assert.IsTrue(DocServPage.ValidationErrorCount > 0, 'Validation errors did not occur');

        DocServPage."User Name".SetValue('User Name');
        DocServPage."Test Connection".Invoke;
        Assert.IsTrue(DocServPage.ValidationErrorCount > 0, 'Validation errors did not occur');

        DocServPage.Folder.SetValue('Folder');
        DocServPage."Test Connection".Invoke;
        Assert.IsTrue(DocServPage.ValidationErrorCount > 0, 'Validation errors did not occur');

        // All fields except password filled in, but validation should fail due to invalid Location address format.
        DocServPage."Document Repository".SetValue('Document Repository');
        DocServPage."Test Connection".Invoke;
        Assert.IsTrue(DocServPage.ValidationErrorCount > 0, 'Validation errors did not occur');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestOnlyOneConfigExists()
    var
        DocServConf: Record "Document Service";
    begin
        InitializeConfig;

        Assert.AreEqual(DocServConf.Count, 1, 'No configuration or more than one entry detected');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRecordInitializedOnFirstOpenPage()
    var
        DocumentService: Record "Document Service";
        DocServPage: TestPage "Document Service Config";
    begin
        DocumentService.DeleteAll;
        DocServPage.OpenEdit;

        Assert.IsFalse(DocServPage."Service ID".Value = '', 'The Service ID field should have been automatically populated');
        Assert.IsTrue(DocServPage.Description.Value = '', 'The Description should have defaulted to empty.');
        Assert.IsTrue(DocServPage.Location.Value = '', 'The Location should have defaulted to empty.');
        Assert.IsTrue(DocServPage."User Name".Value = '', 'The User Name should have defaulted to empty.');
        Assert.IsTrue(DocServPage.Folder.Value = '', 'The Folder should have defaulted to empty.');
        Assert.IsTrue(DocServPage."Document Repository".Value = '', 'The Document Repository should have defaulted to empty.');
        Assert.IsTrue(DocumentService.FindFirst, 'The default record should have been initialized upon Open Page.');
        Assert.IsTrue(DocumentService.Password = '', 'The Password should have defaulted to empty.');
    end;

    [Test]
    [HandlerFunctions('PasswordPageHandler,PasswordPageConfirmationHandler')]
    [Scope('OnPrem')]
    procedure TestSetPassword()
    var
        DocumentService: Record "Document Service";
        DocServPage: TestPage "Document Service Config";
    begin
        InitializeConfig;
        DocServPage.OpenEdit;
        DocServPage."Set Password".Invoke;
        DocServPage.OK.Invoke;

        DocumentService.FindFirst;
        Assert.AreEqual('Password', DocumentService.Password, 'Password was not saved.');
    end;

    [Test]
    [HandlerFunctions('PasswordEmptyPageHandler,PasswordPageConfirmationHandler')]
    [Scope('OnPrem')]
    procedure TestClearPassword()
    var
        DocumentService: Record "Document Service";
        DocServPage: TestPage "Document Service Config";
    begin
        InitializeConfig;
        DocumentService.FindFirst;
        DocumentService.Validate(Password, 'Password');
        DocumentService.Modify;
        Commit;

        DocServPage.OpenEdit;
        DocServPage."Set Password".Invoke;
        DocServPage.OK.Invoke;

        DocumentService.FindFirst;
        Assert.AreEqual('', DocumentService.Password, 'Password was not cleared.');
    end;

    [Test]
    [HandlerFunctions('PasswordPageHandler,PasswordPageDeclineConfirmationHandler')]
    [Scope('OnPrem')]
    procedure TestDeclinePasswordChange()
    var
        DocumentService: Record "Document Service";
        DocServPage: TestPage "Document Service Config";
    begin
        InitializeConfig;
        DocumentService.FindFirst;
        DocumentService.Validate(Password, 'OldPwd');
        DocumentService.Modify;
        Commit;

        DocServPage.OpenEdit;
        DocServPage."Set Password".Invoke;
        DocServPage.OK.Invoke;

        DocumentService.FindFirst;
        Assert.AreEqual('OldPwd', DocumentService.Password, 'Password change should have been declined.');
    end;

    [Test]
    [HandlerFunctions('PasswordMismatchPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestMismatchingPassword()
    var
        DocServPage: TestPage "Document Service Config";
    begin
        InitializeConfig;

        // Test fails if the mismatch message does not appear.
        DocServPage.OpenEdit;
        DocServPage."Set Password".Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PasswordPageHandler(var PwdPage: TestPage "Document Service Acc. Pwd.")
    begin
        PwdPage.PasswordField.SetValue('Password');
        PwdPage.ConfirmPasswordField.SetValue('Password');
        PwdPage.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PasswordEmptyPageHandler(var PwdPage: TestPage "Document Service Acc. Pwd.")
    begin
        PwdPage.PasswordField.SetValue('');
        PwdPage.ConfirmPasswordField.SetValue('');
        PwdPage.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PasswordMismatchPageHandler(var PwdPage: TestPage "Document Service Acc. Pwd.")
    begin
        PwdPage.PasswordField.SetValue('Password1');
        PwdPage.ConfirmPasswordField.SetValue('Password2');

        // Brings up error message which we handle.
        PwdPage.OK.Invoke;
        PwdPage.Cancel.Invoke;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure PasswordPageConfirmationHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure PasswordPageDeclineConfirmationHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

