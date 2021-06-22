codeunit 135501 "AccountEntity E2E Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Account]
    end;

    var
        ServiceNameTxt: Label 'accounts';
        LibraryERM: Codeunit "Library - ERM";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
        Commit;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVerifyIDandLastDateModified()
    var
        GLAccount: Record "G/L Account";
        IntegrationRecord: Record "Integration Record";
        AccountNo: Text;
        AccountGUID: Text;
        BlankGuid: Guid;
        BlankDateTime: DateTime;
    begin
        // [SCENARIO] Create an account and verify it has Id and LastDateTimeModified
        // [GIVEN] a modified G/L Account
        Initialize;
        AccountNo := CreateAccount;
        Commit;

        // [WHEN] we retrieve the account from the database
        GLAccount.Reset;
        GLAccount.SetFilter("No.", AccountNo);
        Assert.IsTrue(GLAccount.FindFirst, 'The G/L Account should exist in the table.');
        AccountGUID := GLAccount.Id;

        // [THEN] the account should have an integration id and last date time modified
        Assert.IsTrue(IntegrationRecord.Get(AccountGUID), 'Could not find the integration record with Id ' + AccountNo);
        Assert.AreNotEqual(IntegrationRecord."Integration ID", BlankGuid,
          'Integration record should not get the blank guid with Id ' + AccountNo);
        Assert.AreNotEqual(GLAccount."Last Modified Date Time", BlankDateTime, 'Last Modified Date Time should be initialized');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetAccounts()
    var
        AccountNo: array[2] of Text;
        AccountJSON: array[2] of Text;
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] Create accounts and use a GET method to retrieve them
        // [GIVEN] 2 accounts in the G/L Account Table with positive balance
        Initialize;
        AccountNo[1] := CreateAccount;
        AccountNo[2] := CreateAccount;
        Commit;

        // [WHEN] we GET all the accounts from the web service
        ClearLastError;
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Account Entity", ServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] the 2 accounts should exist in the response
        if GetLastErrorText <> '' then
            Assert.ExpectedError('Request failed with error: ' + GetLastErrorText);

        GetAndVerifyIDFromJSON(ResponseText, AccountNo[1], AccountJSON[1]);
        GetAndVerifyIDFromJSON(ResponseText, AccountNo[2], AccountJSON[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDemoDataIntegrationRecordIdsForGLAccounts()
    var
        GLAccount: Record "G/L Account";
        IntegrationRecord: Record "Integration Record";
        BlankGuid: Guid;
    begin
        // [SCENARIO 184722] Integration record ids should be set correctly.
        // [GIVEN] We have demo data applied correctly
        GLAccount.SetRange(Id, BlankGuid);
        Assert.IsFalse(GLAccount.FindFirst, 'No G/L Accounts should have null id');

        // [WHEN] We look through all G/L Accounts.
        // [THEN] The integration record for the G/L Account should have the same record id.
        GLAccount.Reset;
        if GLAccount.Find('-') then begin
            repeat
                Assert.IsTrue(IntegrationRecord.Get(GLAccount.SystemId), 'The GLAccount id should exist in the integration record table');
                Assert.AreEqual(
                  IntegrationRecord."Record ID", GLAccount.RecordId,
                  'The integration record for the GLAccount should have the same record id as the GLAccount.');
            until GLAccount.Next <= 0
        end;
    end;

    [Normal]
    local procedure CreateAccount(): Text
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.Validate("Direct Posting", true);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    [Normal]
    local procedure GetAndVerifyIDFromJSON(ResponseText: Text; AccountNo: Text; var AccountJSON: Text)
    begin
        Assert.IsTrue(
          LibraryGraphMgt.GetObjectsFromJSONResponse(ResponseText, 'number', AccountNo, AccountNo, AccountJSON, AccountJSON),
          'Could not find the account in JSON');
        LibraryGraphMgt.VerifyIDInJson(AccountJSON);
    end;
}

