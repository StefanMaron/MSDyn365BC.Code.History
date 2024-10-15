codeunit 141036 "UT PAG Bank Reconciliation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Bank Reconciliation] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";
        ValueMustEqualMsg: Label 'Value must be equal.';

    [Test]
    [HandlerFunctions('BankRecProcessLinesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionClearLinesBankRecWorksheetPage()
    var
        BankRecLine: Record "Bank Rec. Line";
        GLAccount: Record "G/L Account";
        BankRecWorksheet: TestPage "Bank Rec. Worksheet";
    begin
        // Purpose of the test is to validate trigger OnAction - ClearLines of Page - 10120 Bank Rec.Worksheet.

        // Setup: Create G/ L Account and Bank Reconciliation, Open Bank Reconciliation Worksheet Page.
        UpdateGeneralLedgerSetup('');  // Update Bank Rec. Adj. Doc. Nos. as Blank.
        CreateGLAccount(GLAccount);
        CreateBankReconciliation(BankRecLine, BankRecLine."Account Type"::"G/L Account", GLAccount."No.");
        OpenBankRecWorksheetPage(BankRecWorksheet, BankRecLine);

        // Exercise.
        BankRecWorksheet.ClearLines.Invoke;  // Opens MarkLinesBankRecProcessLinesPageHandler.

        // Verify: Verify Bank Rec. Line is deleted.
        Assert.IsFalse(BankRecLine.Get(BankRecLine."Bank Account No.", BankRecLine."Statement No.", BankRecLine."Record Type", BankRecLine."Line No."), 'Bank Reconciliation Line must not exist.');
        BankRecWorksheet.Close;
    end;

    [Test]
    [HandlerFunctions('BankRecProcessLinesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure OnActionRecordAdjustmentsBankRecWorksheetPage()
    var
        BankRecLine: Record "Bank Rec. Line";
        GLAccount: Record "G/L Account";
        GeneralLedgerSetup: Record "General Ledger Setup";
        BankRecWorksheet: TestPage "Bank Rec. Worksheet";
        BankRecAdjDocNos: Code[20];
    begin
        // Purpose of the test is to validate trigger OnAction - RecordAdjustments of Page - 10120 Bank Rec.Worksheet.

        // Setup: Create G/L Account and Bank Reconciliation, Open Bank Reconciliation Worksheet Page.
        GeneralLedgerSetup.Get;
        BankRecAdjDocNos := UpdateGeneralLedgerSetup(GeneralLedgerSetup."Bank Account Nos.");  // Update Bank Rec. Adj. Doc. Nos.
        CreateGLAccount(GLAccount);
        CreateBankReconciliation(BankRecLine, BankRecLine."Account Type"::"G/L Account", GLAccount."No.");
        Commit;  // Commit is required as Bank Rec. Process Lines Report creates new line of Bank Reconciliation Line for Record Type - Adjustment.
        OpenBankRecWorksheetPage(BankRecWorksheet, BankRecLine);

        // Exercise.
        BankRecWorksheet.RecordAdjustments.Invoke;  // Opens MarkLinesBankRecProcessLinesPageHandler.
        BankRecWorksheet.Close;

        // Verify: Verify Amount in new created Bank Rec Line for Record Type - Adjustment.
        VerifyAdjustmentBankReconciliation(BankRecLine);

        // TearDown.
        UpdateGeneralLedgerSetup(BankRecAdjDocNos);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetTableIDBankRecDepLinesSubform()
    var
        BankRecDepLinesSubform: Page "Bank Rec. Dep. Lines Subform";
    begin
        // Purpose of the test is to validate GetTableID function of Page - 10122 Bank Rec. Dep. Lines Subform.

        // Setup.
        // Exercise & Verify: Verify Table ID after execution of function - GetTableID.
        Assert.AreEqual(DATABASE::"Bank Rec. Line", BankRecDepLinesSubform.GetTableID, ValueMustEqualMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetTableIDBankRecAdjLinesSubform()
    var
        BankRecAdjLinesSubform: Page "Bank Rec. Adj. Lines Subform";
    begin
        // Purpose of the test is to validate GetTableID function of Page - 10123 Bank Rec. Adj. Lines Subform.

        // Exercise & Verify: Verify Table ID after execution of function - GetTableID.
        Assert.AreEqual(DATABASE::"Bank Rec. Line", BankRecAdjLinesSubform.GetTableID, ValueMustEqualMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetTableIDBankRecCheckLinesSubform()
    var
        BankRecCheckLinesSubform: Page "Bank Rec. Check Lines Subform";
    begin
        // Purpose of the test is to validate GetTableID function of Page - 10121 Bank Rec. Check Lines Subform.

        // Exercise & Verify: Verify Table ID after execution of function - GetTableID.
        Assert.AreEqual(DATABASE::"Bank Rec. Line", BankRecCheckLinesSubform.GetTableID, ValueMustEqualMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetAccountsGLAccountBankRecAdjLinesSubform()
    var
        GLAccount: Record "G/L Account";
        BankRecLine: Record "Bank Rec. Line";
    begin
        // Purpose of the test is to validate  GetAccounts function of Page - 10123 Bank Rec. Adj. Lines Subform.

        // Setup: Create G/L Account.
        CreateGLAccount(GLAccount);
        GetAccountsBankRecAdjLinesSubform(BankRecLine."Account Type"::"G/L Account", GLAccount."No.", GLAccount.Name);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetAccountsCustomerBankRecAdjLinesSubform()
    var
        Customer: Record Customer;
        BankRecLine: Record "Bank Rec. Line";
    begin
        // Purpose of the test is to validate  GetAccounts function of Page - 10123 Bank Rec. Adj. Lines Subform.

        // Setup: Create Customer.
        CreateCustomer(Customer);
        GetAccountsBankRecAdjLinesSubform(BankRecLine."Account Type"::Customer, Customer."No.", Customer.Name);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetAccountsVendorBankRecAdjLinesSubform()
    var
        Vendor: Record Vendor;
        BankRecLine: Record "Bank Rec. Line";
    begin
        // Purpose of the test is to validate  GetAccounts function of Page - 10123 Bank Rec. Adj. Lines Subform.

        // Setup: Create Vendor.
        CreateVendor(Vendor);
        GetAccountsBankRecAdjLinesSubform(BankRecLine."Account Type"::Vendor, Vendor."No.", Vendor.Name);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetAccountsBankAccountBankRecAdjLinesSubform()
    var
        BankAccount: Record "Bank Account";
        BankRecLine: Record "Bank Rec. Line";
    begin
        // Purpose of the test is to validate  GetAccounts function of Page - 10123 Bank Rec. Adj. Lines Subform.

        // Setup: Create Bank Account.
        CreateBankAccount(BankAccount);
        GetAccountsBankRecAdjLinesSubform(BankRecLine."Account Type"::"Bank Account", BankAccount."No.", BankAccount.Name);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetAccountsFixedAssetBankRecAdjLinesSubform()
    var
        FixedAsset: Record "Fixed Asset";
        BankRecLine: Record "Bank Rec. Line";
    begin
        // Purpose of the test is to validate  GetAccounts function of Page - 10123 Bank Rec. Adj. Lines Subform.

        // Setup: Create Fixed Asset.
        CreateFixedAsset(FixedAsset);
        GetAccountsBankRecAdjLinesSubform(BankRecLine."Account Type"::"Fixed Asset", FixedAsset."No.", FixedAsset.Description);
    end;

    local procedure GetAccountsBankRecAdjLinesSubform(AccountType: Option; AccountNo: Code[20]; Name: Text)
    var
        BankRecLine: Record "Bank Rec. Line";
        BankRecAdjLinesSubform: Page "Bank Rec. Adj. Lines Subform";
        AccountName: Text[50];
        BalanceAccountName: Text[50];
    begin
        // Create Bank Reconciliation.
        CreateBankReconciliation(BankRecLine, AccountType, AccountNo);

        // Exercise.
        BankRecAdjLinesSubform.GetAccounts(BankRecLine, AccountName, BalanceAccountName);

        // Verify: Verify AccountName after execution of function - GetAccounts.
        Assert.AreEqual(Name, AccountName, ValueMustEqualMsg);
    end;

    local procedure OpenBankRecWorksheetPage(var BankRecWorksheet: TestPage "Bank Rec. Worksheet"; BankRecLine: Record "Bank Rec. Line")
    begin
        BankRecWorksheet.OpenEdit;
        BankRecWorksheet.FILTER.SetFilter("Bank Account No.", BankRecLine."Bank Account No.");
        BankRecWorksheet.FILTER.SetFilter("Statement No.", BankRecLine."Statement No.");
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

    local procedure CreateVendor(var Vendor: Record Vendor)
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode;
        Vendor.Name := LibraryUTUtility.GetNewCode;
        Vendor.Insert;
    end;

    local procedure UpdateGeneralLedgerSetup(NewBankRecAdjDocNos: Code[20]) OldBankRecAdjDocNos: Code[20]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get;
        OldBankRecAdjDocNos := GeneralLedgerSetup."Bank Rec. Adj. Doc. Nos.";
        GeneralLedgerSetup."Bank Rec. Adj. Doc. Nos." := NewBankRecAdjDocNos;
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

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankRecProcessLinesRequestPageHandler(var BankRecProcessLines: TestRequestPage "Bank Rec. Process Lines")
    begin
        BankRecProcessLines.MarkAsCleared.SetValue(true);
        BankRecProcessLines.OK.Invoke;
    end;
}

