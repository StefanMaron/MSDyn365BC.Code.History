codeunit 138002 "O365 Email as PDF UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Report Distribution] [PDF]
    end;

    var
        ReportDistributionManagement: Codeunit "Report Distribution Management";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        ActiveDirectoryMockEvents: Codeunit "Active Directory Mock Events";
        TmpResult: Text;
        InvalidWindowsChrStringTxt: Label '"#%&*:<>?\/{|}~';

    [Test]
    [Scope('OnPrem')]
    procedure DownloadPdfOnClient()
    var
        FileManagement: Codeunit "File Management";
    begin
        Initialize;

        // Empty server file name
        TmpResult := '';
        asserterror ReportDistributionManagement.DownloadPdfOnClient(TmpResult);
        Assert.IsTrue(StrPos(GetLastErrorText, 'File name was not specified') <> 0, 'Expected error not thrown');

        // Correct file names
        TmpResult := FileManagement.ServerTempFileName('pdf');
        CreateFileOnServer(TmpResult);
        ReportDistributionManagement.DownloadPdfOnClient(TmpResult);
        Assert.IsFalse(FILE.Exists(TmpResult), 'Server file was not deleted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDeletionOfinvalidChr()
    var
        FileManagement: Codeunit "File Management";
    begin
        Initialize;

        Assert.AreEqual(
          '', FileManagement.StripNotsupportChrInFileName(InvalidWindowsChrStringTxt),
          'All invalid charaters needs to be deleted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyO365FromAddressUsed()
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        LibraryEmailFeature: Codeunit "Library - Email Feature";
        SMTPMail: Codeunit "SMTP Mail";
        Mail: Codeunit Mail;
        ExpectedMail: Text[250];
    begin
        LibraryEmailFeature.SetEmailFeatureEnabled(false);
        Initialize;
        if SMTPMailSetup.Get then
            SMTPMailSetup.Delete();

        SMTPMail.ApplyOffice365Smtp(SMTPMailSetup);

        // specify o365 account
        ExpectedMail := 'correct@mail.com';
        SMTPMailSetup."User ID" := ExpectedMail;
        SMTPMailSetup."Password Key" := CreateGuid;
        SMTPMailSetup.Insert();

        Assert.IsTrue(SMTPMail.IsOffice365Setup(SMTPMailSetup), 'Setup should match o365 setup');

        Mail.CollectCurrentUserEmailAddresses(TempNameValueBuffer);
        TempNameValueBuffer.SetRange(Name, 'SMTPSetup');
        Assert.IsTrue(TempNameValueBuffer.FindFirst, 'No emails were found');

        Assert.AreEqual(ExpectedMail, TempNameValueBuffer.Value, 'The wrong email was selected');
        LibraryEmailFeature.SetEmailFeatureEnabled(true);
    end;

    [Normal]
    local procedure CreateFileOnServer(Path: Text)
    var
        File: File;
    begin
        Assert.IsTrue(File.Create(Path), 'Unable to create a file: ' + Path);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Email as PDF UT");
        BindActiveDirectoryMockEvents;
        LibraryApplicationArea.EnableFoundationSetup;
    end;

    local procedure BindActiveDirectoryMockEvents()
    begin
        if ActiveDirectoryMockEvents.Enabled then
            exit;
        BindSubscription(ActiveDirectoryMockEvents);
        ActiveDirectoryMockEvents.Enable;
    end;
}

