codeunit 142080 "UT PAG Bank Rec II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Bank Reconciliation]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        ValueMustEqualErr: Label 'Value must be equal.';

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnNavigatePostedBankRecWorksheet()
    var
        PostedBankRecLine: Record "Posted Bank Rec. Line";
        PostedBankRecWorksheet: TestPage "Posted Bank Rec. Worksheet";
    begin
        // Purpose of the Page - 10125 Page Posted Bank Rec.Worksheet.

        // Setup: Create Posted Bank Rec. Document.
        Initialize;
        CreatePostedBankRec(PostedBankRecLine, PostedBankRecLine."Account Type"::"Bank Account", '');

        // Exercise.
        OpenPagePostedBankRecWorksheetToNavigate(PostedBankRecLine."Bank Account No.");

        // Verify.
        VerifyBankReconciliationWorksheet(PostedBankRecWorksheet, PostedBankRecLine."Bank Account No.", PostedBankRecLine."Statement No.");
    end;

    [Test]
    [HandlerFunctions('BankReconciliationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PrintRecordPostedBankRecWorksheet()
    var
        PostedBankRecLine: Record "Posted Bank Rec. Line";
        PostedBankRecWorksheet: TestPage "Posted Bank Rec. Worksheet";
    begin
        // Purpose of the test is to run PrintRecords function of Page - 10125 Posted Bank Rec.Worksheet.

        // Setup.
        Initialize;
        CreatePostedBankRec(PostedBankRecLine, PostedBankRecLine."Account Type"::"Bank Account", '');

        // Pre-Exercise
        SetBankReconciliationReports;

        // Exercise.
        OpenPagePostedBankRecWorksheetToPrint(PostedBankRecWorksheet, PostedBankRecLine."Bank Account No.");

        // Verify.
        VerifyBankReconciliationWorksheet(PostedBankRecWorksheet, PostedBankRecLine."Bank Account No.", PostedBankRecLine."Statement No.");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetTableIDPostedBankRecDepLinesSubform()
    var
        PostedBankRecDepLinesSub: Page "Posted Bank Rec. Dep Lines Sub";
    begin
        // Purpose of the test is to validate GetTableID function of Page - 10127 Posted Bank Rec. Dep Lines Sub.

        // Setup.
        Initialize;

        // Exercise & Verify: Verify Table ID after execution of function - GetTableID.
        Assert.AreEqual(DATABASE::"Posted Bank Rec. Line", PostedBankRecDepLinesSub.GetTableID, ValueMustEqualErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetTableIDPostedBankRecAdjLinesSubform()
    var
        PostedBankRecAdjLinesSub: Page "Posted Bank Rec. Adj Lines Sub";
    begin
        // Purpose of the test is to validate GetTableID function of Page - 10128 Bank Rec. Adj. Lines Subform.

        // Setup.
        Initialize;

        // Exercise & Verify: Verify Table ID after execution of function - GetTableID.
        Assert.AreEqual(DATABASE::"Posted Bank Rec. Line", PostedBankRecAdjLinesSub.GetTableID, ValueMustEqualErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetTableIDPostedBankRecCheckLinesSubform()
    var
        PostedBankRecChkLinesSub: Page "Posted Bank Rec. Chk Lines Sub";
    begin
        // Purpose of the test is to validate GetTableID function of Page - 10126 Posted Bank Rec. Chk Lines Sub.

        // Setup.
        Initialize;

        // Exercise & Verify: Verify Table ID after execution of function - GetTableID.
        Assert.AreEqual(DATABASE::"Posted Bank Rec. Line", PostedBankRecChkLinesSub.GetTableID, ValueMustEqualErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetAccountsGLAccountPostedBankRecAdjLinesSubform()
    var
        GLAccount: Record "G/L Account";
        PostedBankRecLine: Record "Posted Bank Rec. Line";
    begin
        // Purpose of the test is to validate  GetAccounts function of Page - 10128 Posted Bank Rec. Adj Lines Sub.

        // Setup: Create G/L Account.
        Initialize;
        CreateGLAccount(GLAccount);
        GetAccountsPostedBankRecAdjLinesSubform(PostedBankRecLine."Account Type"::"G/L Account", GLAccount."No.", GLAccount.Name);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetAccountsCustomerPostedBankRecAdjLinesSubform()
    var
        Customer: Record Customer;
        PostedBankRecLine: Record "Posted Bank Rec. Line";
    begin
        // Purpose of the test is to validate  GetAccounts function of Page - 10128 Posted Bank Rec. Adj Lines Sub.

        // Setup: Create Customer.
        Initialize;
        CreateCustomer(Customer);
        GetAccountsPostedBankRecAdjLinesSubform(PostedBankRecLine."Account Type"::Customer, Customer."No.", Customer.Name);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetAccountsVendorPostedBankRecAdjLinesSubform()
    var
        Vendor: Record Vendor;
        PostedBankRecLine: Record "Posted Bank Rec. Line";
    begin
        // Purpose of the test is to validate  GetAccounts function of Page - 10128 Posted Bank Rec. Adj Lines Sub.

        // Setup: Create Vendor.
        Initialize;
        CreateVendor(Vendor);
        GetAccountsPostedBankRecAdjLinesSubform(PostedBankRecLine."Account Type"::Vendor, Vendor."No.", Vendor.Name);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetAccountsBankAccountPostedBankRecAdjLinesSubform()
    var
        BankAccount: Record "Bank Account";
        PostedBankRecLine: Record "Posted Bank Rec. Line";
    begin
        // Purpose of the test is to validate  GetAccounts function of Page - 10128 Posted Bank Rec. Adj Lines Sub.

        // Setup: Create Bank Account.
        Initialize;
        CreateBankAccount(BankAccount);
        GetAccountsPostedBankRecAdjLinesSubform(PostedBankRecLine."Account Type"::"Bank Account", BankAccount."No.", BankAccount.Name);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetAccountsFixedAssetPostedBankRecAdjLinesSubform()
    var
        FixedAsset: Record "Fixed Asset";
        PostedBankRecLine: Record "Posted Bank Rec. Line";
    begin
        // Purpose of the test is to validate  GetAccounts function of Page - 10128 Posted Bank Rec. Adj Lines Sub.

        // Setup: Create Fixed Asset.
        Initialize;
        CreateFixedAsset(FixedAsset);
        GetAccountsPostedBankRecAdjLinesSubform(PostedBankRecLine."Account Type"::"Fixed Asset", FixedAsset."No.", FixedAsset.Description);
    end;

    local procedure GetAccountsPostedBankRecAdjLinesSubform(AccountType: Option; AccountNo: Code[20]; Name: Text)
    var
        PostedBankRecLine: Record "Posted Bank Rec. Line";
        PostedBankRecAdjLinesSub: Page "Posted Bank Rec. Adj Lines Sub";
        AccountName: Text[50];
        BalanceAccountName: Text[50];
    begin
        // Create Bank Reconciliation.
        CreatePostedBankRec(PostedBankRecLine, AccountType, AccountNo);

        // Exercise.
        PostedBankRecAdjLinesSub.GetAccounts(PostedBankRecLine, AccountName, BalanceAccountName);

        // Verify: Verify AccountName after execution of function - GetAccounts.
        Assert.AreEqual(Name, AccountName, ValueMustEqualErr);
    end;

    [Test]
    [HandlerFunctions('BankRecWorksheetDynRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionClearLinesBankRecWorksheetDynPage()
    var
        BankRecLine: Record "Bank Rec. Line";
        GLAccount: Record "G/L Account";
        BankRecWorksheetDyn: TestPage "Bank Rec. Worksheet Dyn";
    begin
        // Purpose of the test is to validate trigger OnAction - ClearLines of Page - 36720 Bank Rec.Worksheet Dyn.

        // Setup: Create G/L Account and Bank Reconciliation, Open Bank Rec.Worksheet Dyn Page.
        Initialize;
        UpdateBankRecAdjDocNoInGeneralLedgerSetup('');
        CreateGLAccount(GLAccount);
        CreateBankReconciliation(BankRecLine, BankRecLine."Account Type"::"G/L Account", GLAccount."No.");
        OpenBankRecWorksheetDyn(BankRecWorksheetDyn, BankRecLine);

        // Exercise.
        BankRecWorksheetDyn.ClearLines.Invoke;  // Opens BankRecWorksheetDynRequestPageHandler.

        // Verify: Verify Bank Rec. Line is deleted.
        Assert.IsFalse(BankRecLine.Get(BankRecLine."Bank Account No.", BankRecLine."Statement No.", BankRecLine."Record Type", BankRecLine."Line No."), 'Bank Reconciliation Line must not exist.');
        BankRecWorksheetDyn.Close;
    end;

    [Test]
    [HandlerFunctions('BankRecWorksheetDynRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionRecordAdjustmentsBankRecWorksheetDynPage()
    var
        BankRecLine: Record "Bank Rec. Line";
        GLAccount: Record "G/L Account";
        BankRecWorksheetDyn: TestPage "Bank Rec. Worksheet Dyn";
    begin
        // Purpose of the test is to validate trigger OnAction - RecordAdjustments of Page - 36720 Bank Rec.Worksheet Dyn.

        // Setup: Create G/L Account and Bank Reconciliation, Open Bank Rec.Worksheet Dyn Page.
        Initialize;
        UpdateBankRecAdjDocNoInGeneralLedgerSetup(CreateNoSeries);
        CreateGLAccount(GLAccount);
        CreateBankReconciliation(BankRecLine, BankRecLine."Account Type"::"G/L Account", GLAccount."No.");
        Commit;  // Commit is required On Run Bank Rec.-Post.
        OpenBankRecWorksheetDyn(BankRecWorksheetDyn, BankRecLine);

        // Exercise.
        BankRecWorksheetDyn.RecordAdjustments.Invoke;  // Opens BankRecWorksheetDynRequestPageHandler.
        BankRecWorksheetDyn.Close;

        // Verify: Verify Amount in new created Bank Rec Line for Record Type - Adjustment.
        VerifyAdjustmentBankReconciliation(BankRecLine);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetTableIDBankRecCheckLinesDyn()
    var
        BankRecCheckLinesDyn: Page "Bank Rec. Check Lines Dyn";
    begin
        // Purpose of the test is to validate GetTableID function of Page - 36721 Bank Rec. Check Lines Dyn.

        // Setup.
        Initialize;

        // Exercise & Verify: Verify Table ID after execution of function - GetTableID.
        Assert.AreEqual(DATABASE::"Bank Rec. Line", BankRecCheckLinesDyn.GetTableID, ValueMustEqualErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetTableIDBankRecAdjLinesDyn()
    var
        BankRecAdjLines: Page "Bank Rec. Adj. Lines";
    begin
        // Purpose of the test is to validate GetTableID function of Page - 36723 Bank Rec. Adj. Lines Subform.

        // Setup.
        Initialize;

        // Exercise & Verify: Verify Table ID after execution of function - GetTableID.
        Assert.AreEqual(DATABASE::"Bank Rec. Line", BankRecAdjLines.GetTableID, ValueMustEqualErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetTableIDBankRecDepLinesDyn()
    var
        BankRecDepLinesDyn: Page "Bank Rec. Dep. Lines - Dyn.";
    begin
        // Purpose of the test is to validate GetTableID function of Page - 36722 Bank Rec. Dep. Lines - Dyn.

        // Setup.
        Initialize;

        // Exercise & Verify: Verify Table ID after execution of function - GetTableID.
        Assert.AreEqual(DATABASE::"Bank Rec. Line", BankRecDepLinesDyn.GetTableID, ValueMustEqualErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetAccountsGLAccountBankRecAdjLines()
    var
        GLAccount: Record "G/L Account";
        BankRecLine: Record "Bank Rec. Line";
    begin
        // Purpose of the test is to validate  GetAccounts function of Page - 36723 Page Bank Rec. Adj. Lines.

        // Setup: Create G/L Account.
        Initialize;
        CreateGLAccount(GLAccount);
        GetAccountsBankRecAdjLines(BankRecLine."Account Type"::"G/L Account", GLAccount."No.", GLAccount.Name);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetAccountsCustomerBankRecAdjLines()
    var
        Customer: Record Customer;
        BankRecLine: Record "Bank Rec. Line";
    begin
        // Purpose of the test is to validate  GetAccounts function of Page - 36723 Page Bank Rec. Adj. Lines.

        // Setup: Create Customer.
        Initialize;
        CreateCustomer(Customer);
        GetAccountsBankRecAdjLines(BankRecLine."Account Type"::Customer, Customer."No.", Customer.Name);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetAccountsVendorBankRecAdjLines()
    var
        Vendor: Record Vendor;
        BankRecLine: Record "Bank Rec. Line";
    begin
        // Purpose of the test is to validate  GetAccounts function of Page - 36723 Page Bank Rec. Adj. Lines.

        // Setup: Create Vendor.
        Initialize;
        CreateVendor(Vendor);
        GetAccountsBankRecAdjLines(BankRecLine."Account Type"::Vendor, Vendor."No.", Vendor.Name);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetAccountsBankAccountBankRecAdjLines()
    var
        BankAccount: Record "Bank Account";
        BankRecLine: Record "Bank Rec. Line";
    begin
        // Purpose of the test is to validate  GetAccounts function of Page - 36723 Page Bank Rec. Adj. Lines.

        // Setup: Create Bank Account.
        Initialize;
        CreateBankAccount(BankAccount);
        GetAccountsBankRecAdjLines(BankRecLine."Account Type"::"Bank Account", BankAccount."No.", BankAccount.Name);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetAccountsFixedAssetBankRecAdjLines()
    var
        FixedAsset: Record "Fixed Asset";
        BankRecLine: Record "Bank Rec. Line";
    begin
        // Purpose of the test is to validate  GetAccounts function of Page - 36723 Page Bank Rec. Adj. Lines.

        // Setup: Create Fixed Asset.
        Initialize;
        CreateFixedAsset(FixedAsset);
        GetAccountsBankRecAdjLines(BankRecLine."Account Type"::"Fixed Asset", FixedAsset."No.", FixedAsset.Description);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetupNewLineBankCommentSheet()
    var
        BankAccount: Record "Bank Account";
        BankCommentLine: Record "Bank Comment Line";
        BankCommentSheet: TestPage "Bank Comment Sheet";
    begin
        // Purpose of the test is to validate SetupNew Line function for Page 10130 Bank Comment Sheet.

        // Setup.
        CreateBankAccount(BankAccount);

        // Exercise.
        OpenBankCommentSheetToEnterComment(BankCommentSheet, BankAccount."No.");

        // Verify:
        BankCommentLine.SetRange("Bank Account No.", BankAccount."No.");
        BankCommentLine.FindFirst;
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;
    end;

    local procedure CreateBankAccount(var BankAccount: Record "Bank Account")
    begin
        BankAccount."No." := LibraryUTUtility.GetNewCode;
        BankAccount.Name := LibraryUTUtility.GetNewCode;
        BankAccount.Insert;
    end;

    local procedure CreateBankReconciliation(var BankRecLine: Record "Bank Rec. Line"; AccountType: Option; AccountNo: Code[20])
    var
        BankRecHeader: Record "Bank Rec. Header";
        BankAccount: Record "Bank Account";
    begin
        CreateBankAccount(BankAccount);
        BankRecHeader."Bank Account No." := BankAccount."No.";
        BankRecHeader."Statement No." := LibraryUTUtility.GetNewCode;
        BankRecHeader."Statement Date" := WorkDate;
        BankRecHeader.Insert;

        // Create Bank Rec. Line.
        BankRecLine.Cleared := true;
        BankRecLine."Posting Date" := WorkDate;
        BankRecLine."Document No." := LibraryUTUtility.GetNewCode;
        BankRecLine."Cleared Amount" := LibraryRandom.RandDec(10, 2);
        BankRecLine."Statement No." := BankRecHeader."Statement No.";
        BankRecLine."Bank Account No." := BankRecHeader."Bank Account No.";
        BankRecLine.Amount := LibraryRandom.RandDec(10, 2);
        BankRecLine."Account Type" := AccountType;
        BankRecLine."Account No." := AccountNo;
        BankRecLine."Bal. Account Type" := AccountType;
        BankRecLine."Bal. Account No." := AccountNo;
        BankRecLine.Insert;
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        Customer."No." := LibraryUTUtility.GetNewCode;
        Customer.Name := LibraryUTUtility.GetNewCode;
        Customer.Insert;
    end;

    local procedure CreateFixedAsset(var FixedAsset: Record "Fixed Asset")
    begin
        FixedAsset."No." := LibraryUTUtility.GetNewCode;
        FixedAsset.Description := LibraryUTUtility.GetNewCode;
        FixedAsset.Insert;
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account")
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode;
        GLAccount.Name := LibraryUTUtility.GetNewCode;
        GLAccount.Insert;
    end;

    local procedure CreateNoSeries(): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeries.Code := LibraryUTUtility.GetNewCode10;
        NoSeries."Default Nos." := true;
        NoSeries.Insert;
        NoSeriesLine."Series Code" := NoSeries.Code;
        NoSeriesLine."Starting No." := LibraryUTUtility.GetNewCode10;
        NoSeriesLine.Insert;
        exit(NoSeries.Code);
    end;

    local procedure CreatePostedBankRec(var PostedBankRecLine: Record "Posted Bank Rec. Line"; AccountType: Option; AccountNo: Code[20])
    var
        BankAccount: Record "Bank Account";
        PostedBankRecHeader: Record "Posted Bank Rec. Header";
    begin
        CreateBankAccount(BankAccount);
        PostedBankRecHeader."Bank Account No." := BankAccount."No.";
        PostedBankRecHeader."Statement No." := LibraryUTUtility.GetNewCode;
        PostedBankRecHeader."Statement Date" := WorkDate;
        PostedBankRecHeader.Comment := true;
        PostedBankRecHeader.Insert;

        PostedBankRecLine."Posting Date" := WorkDate;
        PostedBankRecLine."Document No." := LibraryUTUtility.GetNewCode;
        PostedBankRecLine."Cleared Amount" := LibraryRandom.RandDec(10, 2);
        PostedBankRecLine."Bank Account No." := PostedBankRecHeader."Bank Account No.";
        PostedBankRecLine."Statement No." := PostedBankRecHeader."Statement No.";
        PostedBankRecLine."Record Type" := PostedBankRecLine."Record Type"::Adjustment;
        PostedBankRecLine."Account Type" := AccountType;
        PostedBankRecLine."Account No." := AccountNo;
        PostedBankRecLine.Amount := LibraryRandom.RandDec(10, 2);
        PostedBankRecLine.Positive := true;
        PostedBankRecLine.Insert;
    end;

    local procedure CreateVendor(var Vendor: Record Vendor)
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode;
        Vendor.Name := LibraryUTUtility.GetNewCode;
        Vendor.Insert;
    end;

    local procedure GetAccountsBankRecAdjLines(AccountType: Option; AccountNo: Code[20]; Name: Text)
    var
        BankRecLine: Record "Bank Rec. Line";
        BankRecAdjLines: Page "Bank Rec. Adj. Lines";
        AccountName: Text[50];
        BalanceAccountName: Text[50];
    begin
        // Create Bank Reconciliation.
        CreateBankReconciliation(BankRecLine, AccountType, AccountNo);

        // Exercise.
        BankRecAdjLines.GetAccounts(BankRecLine, AccountName, BalanceAccountName);

        // Verify: Verify AccountName after execution of function - GetAccounts.
        Assert.AreEqual(Name, AccountName, ValueMustEqualErr);
    end;

    local procedure OpenBankRecWorksheetDyn(var BankRecWorksheetDyn: TestPage "Bank Rec. Worksheet Dyn"; BankRecLine: Record "Bank Rec. Line")
    begin
        BankRecWorksheetDyn.OpenEdit;
        BankRecWorksheetDyn.FILTER.SetFilter("Bank Account No.", BankRecLine."Bank Account No.");
        BankRecWorksheetDyn.FILTER.SetFilter("Statement No.", BankRecLine."Statement No.");
    end;

    local procedure OpenBankCommentSheetToEnterComment(var BankCommentSheet: TestPage "Bank Comment Sheet"; BankAccountNo: Code[20])
    begin
        BankCommentSheet.OpenNew;
        BankCommentSheet.FILTER.SetFilter("Bank Account No.", BankAccountNo);
        BankCommentSheet.Comment.SetValue(LibraryUTUtility.GetNewCode);
        BankCommentSheet.Date.SetValue(WorkDate);
        BankCommentSheet.Close;
    end;

    local procedure OpenPagePostedBankRecWorksheetToNavigate(BankAccountNo: Code[20])
    var
        PostedBankRecWorksheet: TestPage "Posted Bank Rec. Worksheet";
        Navigate: TestPage Navigate;
    begin
        Navigate.Trap;
        OpenPagePostedBankRecWorksheet(PostedBankRecWorksheet, BankAccountNo);
        PostedBankRecWorksheet.Navigate.Invoke;
        PostedBankRecWorksheet.Close;
        Navigate.Close;
    end;

    local procedure OpenPagePostedBankRecWorksheetToPrint(var PostedBankRecWorksheet: TestPage "Posted Bank Rec. Worksheet"; BankAccountNo: Code[20])
    begin
        OpenPagePostedBankRecWorksheet(PostedBankRecWorksheet, BankAccountNo);
        PostedBankRecWorksheet.Print.Invoke;
        PostedBankRecWorksheet.Close;
    end;

    local procedure OpenPagePostedBankRecWorksheet(var PostedBankRecWorksheet: TestPage "Posted Bank Rec. Worksheet"; BankAccountNo: Code[20])
    begin
        PostedBankRecWorksheet.OpenEdit;
        PostedBankRecWorksheet.FILTER.SetFilter("Bank Account No.", BankAccountNo);
    end;

    local procedure UpdateBankRecAdjDocNoInGeneralLedgerSetup(BankRecAdjDocNos: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get;
        GeneralLedgerSetup."Bank Rec. Adj. Doc. Nos." := BankRecAdjDocNos;
        GeneralLedgerSetup.Modify;
    end;

    local procedure VerifyAdjustmentBankReconciliation(BankRecLine: Record "Bank Rec. Line")
    var
        BankRecLine2: Record "Bank Rec. Line";
    begin
        BankRecLine2.SetRange("Bank Account No.", BankRecLine."Bank Account No.");
        BankRecLine2.SetRange("Statement No.", BankRecLine."Statement No.");
        BankRecLine2.SetRange("Record Type", BankRecLine2."Record Type"::Adjustment);
        BankRecLine2.FindFirst;
        BankRecLine2.TestField(Amount, BankRecLine.Amount - BankRecLine."Cleared Amount");
    end;

    local procedure VerifyBankReconciliationWorksheet(PostedBankRecWorksheet: TestPage "Posted Bank Rec. Worksheet"; BankAccountNo: Code[20]; StatementNo: Code[20])
    begin
        PostedBankRecWorksheet.OpenEdit;
        PostedBankRecWorksheet.FILTER.SetFilter("Bank Account No.", BankAccountNo);
        PostedBankRecWorksheet."Statement No.".AssertEquals(StatementNo);
        PostedBankRecWorksheet.Close;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankRecWorksheetDynRequestPageHandler(var BankRecProcessLines: TestRequestPage "Bank Rec. Process Lines")
    begin
        BankRecProcessLines.MarkAsCleared.SetValue(true);
        BankRecProcessLines.OK.Invoke;
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure BankReconciliationHandler(var BankReconciliation: Report "Bank Reconciliation")
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;

    local procedure SetBankReconciliationReports()
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"B.Stmt", ReportSelections.Usage::"B.Recon.Test");
        ReportSelections.DeleteAll;

        AddReconciliationReport(ReportSelections.Usage::"B.Stmt", 1, REPORT::"Bank Reconciliation");
        AddReconciliationReport(ReportSelections.Usage::"B.Recon.Test", 1, REPORT::"Bank Rec. Test Report");
    end;

    local procedure AddReconciliationReport(Usage: Option; Sequence: Integer; ReportID: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.Usage := Usage;
        ReportSelections.Sequence := Format(Sequence);
        ReportSelections."Report ID" := ReportID;
        ReportSelections.Insert;
    end;
}

