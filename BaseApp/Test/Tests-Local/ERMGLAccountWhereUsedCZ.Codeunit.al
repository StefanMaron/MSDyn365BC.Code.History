codeunit 144544 "ERM G/L Account Where-Used CZ"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [G/L Account Where-Used]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryFixedAssetCZ: Codeunit "Library - Fixed Asset CZ";
        Assert: Codeunit Assert;
        CalcGLAccWhereUsed: Codeunit "Calc. G/L Acc. Where-Used";
        isInitialized: Boolean;
        InvalidTableCaptionErr: Label 'Invalid table caption.';
        InvalidFieldCaptionErr: Label 'Invalid field caption.';
        InvalidLineValueErr: Label 'Invalid Line value.';

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckFAExtendedPostingGroup()
    var
        FAExtendedPostingGroup: Record "FA Extended Posting Group";
    begin
        // [SCENARIO 263861] FA Extended Posting Group should be shown on Where-Used page
        Initialize;

        // [GIVEN] FA Extended Posting Group with "Maintenance Expense Account" = "G"
        CreateFAExtendedPostingGroup(FAExtendedPostingGroup);

        // [WHEN] Run Where-Used function for G/L Accoun "G"
        CalcGLAccWhereUsed.CheckGLAcc(FAExtendedPostingGroup."Maintenance Expense Account");

        // [THEN] G/L Account "G" is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          FAExtendedPostingGroup.TableCaption,
          FAExtendedPostingGroup.FieldCaption("Maintenance Expense Account"),
          StrSubstNo(
            '%1=%2, %3=%4, %5=%6',
            FAExtendedPostingGroup.FieldCaption("FA Posting Group Code"),
            FAExtendedPostingGroup."FA Posting Group Code",
            FAExtendedPostingGroup.FieldCaption("FA Posting Type"),
            FAExtendedPostingGroup."FA Posting Type",
            FAExtendedPostingGroup.FieldCaption(Code),
            FAExtendedPostingGroup.Code));
    end;

    [Test]
    [HandlerFunctions('WhereUsedShowDetailsHandler')]
    [Scope('OnPrem')]
    procedure ShowDetailsWhereUsedFAExtendedPostingGroup()
    var
        FAExtendedPostingGroup: Record "FA Extended Posting Group";
        FAExtendedPostingGroups: TestPage "FA Extended Posting Groups";
    begin
        // [SCENARIO 263861] FA Extended Posting Groups page should be open on Show Details action from Where-Used page
        Initialize;

        // [GIVEN] FA Extended Posting Group "FA Posting Group Code" = "FPGC", "FA Posting Type" = "Disposal", Code = "C" with "Maintenance Expense Account" = "G"
        CreateFAExtendedPostingGroup(FAExtendedPostingGroup);

        // [WHEN] Run Where-Used function for G/L Accoun "G" and choose Show Details action
        FAExtendedPostingGroups.Trap;
        CalcGLAccWhereUsed.CheckGLAcc(FAExtendedPostingGroup."Maintenance Expense Account");

        // [THEN] FA Extended Posting Groups page opened with "FA Posting Type" = "Disposal", Code = "C"
        FAExtendedPostingGroups."FA Posting Type".AssertEquals(FAExtendedPostingGroup."FA Posting Type");
        FAExtendedPostingGroups.Code.AssertEquals(FAExtendedPostingGroup.Code);
    end;

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckBankAccount()
    var
        BankAccount: Record "Bank Account";
    begin
        // [SCENARIO 263861] Bank Account should be shown on Where-Used page
        Initialize;

        // [GIVEN] Bank Account with "Non Associated Payment Account" = "G"
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Non Associated Payment Account", LibraryERM.CreateGLAccountNo);
        BankAccount.Modify;

        // [WHEN] Run Where-Used function for G/L Accoun "G"
        CalcGLAccWhereUsed.CheckGLAcc(BankAccount."Non Associated Payment Account");

        // [THEN] G/L Account "G" is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          BankAccount.TableCaption,
          BankAccount.FieldCaption("Non Associated Payment Account"),
          StrSubstNo('%1=%2', BankAccount.FieldCaption("No."), BankAccount."No."));
    end;

    [Test]
    [HandlerFunctions('WhereUsedShowDetailsHandler')]
    [Scope('OnPrem')]
    procedure ShowDetailsWhereUsedBankAccount()
    var
        BankAccount: Record "Bank Account";
        BankAccountList: TestPage "Bank Account List";
    begin
        // [SCENARIO 263861] Bank Accounts page should be open on Show Details action from Where-Used page
        Initialize;

        // [GIVEN] Bank Account "B" with "Non Associated Payment Account" = "G"
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Non Associated Payment Account", LibraryERM.CreateGLAccountNo);
        BankAccount.Modify;

        // [WHEN] Run Where-Used function for G/L Accoun "G" and choose Show Details action
        BankAccountList.Trap;
        CalcGLAccWhereUsed.CheckGLAcc(BankAccount."Non Associated Payment Account");

        // [THEN] Bank Accounts page opened with "No." = "B"
        BankAccountList."No.".AssertEquals(BankAccount."No.");
    end;

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure CheckCreditsSetup()
    var
        CreditsSetup: Record "Credits Setup";
    begin
        // [SCENARIO 263861] Credits Setup should be shown on Where-Used page
        Initialize;

        // [GIVEN] Credits Setup with "Non Associated Payment Account" = "G"
        CreditsSetup.Get;
        CreditsSetup.Validate("Credit Bal. Account No.", LibraryERM.CreateGLAccountNo);
        CreditsSetup.Modify;

        // [WHEN] Run Where-Used function for G/L Accoun "G"
        CalcGLAccWhereUsed.CheckGLAcc(CreditsSetup."Credit Bal. Account No.");

        // [THEN] G/L Account "G" is shown on "G/L Account Where-Used List"
        ValidateWhereUsedRecord(
          CreditsSetup.TableCaption,
          CreditsSetup.FieldCaption("Credit Bal. Account No."),
          StrSubstNo('%1=%2', CreditsSetup.FieldCaption("Primary Key"), CreditsSetup."Primary Key"));
    end;

    [Test]
    [HandlerFunctions('WhereUsedShowDetailsHandler')]
    [Scope('OnPrem')]
    procedure ShowDetailsWhereUsedCreditsSetup()
    var
        CreditsSetup: Record "Credits Setup";
        CreditsSetupPage: TestPage "Credits Setup";
    begin
        // [SCENARIO 263861] Credits Setups page should be open on Show Details action from Where-Used page
        Initialize;

        // [GIVEN] Credits Setup with "Non Associated Payment Account" = "G"
        CreditsSetup.Get;
        CreditsSetup.Validate("Credit Bal. Account No.", LibraryERM.CreateGLAccountNo);
        CreditsSetup.Modify;

        // [WHEN] Run Where-Used function for G/L Accoun "G" and choose Show Details action
        CreditsSetupPage.Trap;
        CalcGLAccWhereUsed.CheckGLAcc(CreditsSetup."Credit Bal. Account No.");

        // [THEN] Credits Setups page opened
        CreditsSetupPage.OK.Invoke;
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore;
        LibraryVariableStorage.Clear;
        if isInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"Credits Setup");
        isInitialized := true;
    end;

    local procedure CreateFAExtendedPostingGroup(var FAExtendedPostingGroup: Record "FA Extended Posting Group")
    var
        ReasonCode: Record "Reason Code";
        FAPostingGroup: Record "FA Posting Group";
    begin
        LibraryERM.CreateReasonCode(ReasonCode);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAssetCZ.CreateFAExtendedPostingGroup(
          FAExtendedPostingGroup, FAPostingGroup.Code, FAExtendedPostingGroup."FA Posting Type"::Disposal, ReasonCode.Code);
        FAExtendedPostingGroup.Validate("Maintenance Expense Account", LibraryERM.CreateGLAccountNo);
        FAExtendedPostingGroup.Modify;
    end;

    local procedure ValidateWhereUsedRecord(ExpectedTableCaption: Text; ExpectedFieldCaption: Text; ExpectedLineValue: Text)
    begin
        Assert.AreEqual(ExpectedTableCaption, LibraryVariableStorage.DequeueText, InvalidTableCaptionErr);
        Assert.AreEqual(ExpectedFieldCaption, LibraryVariableStorage.DequeueText, InvalidFieldCaptionErr);
        Assert.AreEqual(ExpectedLineValue, LibraryVariableStorage.DequeueText, InvalidLineValueErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhereUsedHandler(var GLAccountWhereUsedList: TestPage "G/L Account Where-Used List")
    begin
        GLAccountWhereUsedList.First;
        LibraryVariableStorage.Enqueue(GLAccountWhereUsedList."Table Name".Value);
        LibraryVariableStorage.Enqueue(GLAccountWhereUsedList."Field Name".Value);
        LibraryVariableStorage.Enqueue(GLAccountWhereUsedList.Line.Value);
        GLAccountWhereUsedList.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhereUsedShowDetailsHandler(var GLAccountWhereUsedList: TestPage "G/L Account Where-Used List")
    begin
        GLAccountWhereUsedList.First;
        GLAccountWhereUsedList.ShowDetails.Invoke;
    end;
}

