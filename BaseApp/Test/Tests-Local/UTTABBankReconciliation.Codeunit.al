codeunit 141035 "UT TAB Bank Reconciliation"
{
    Permissions = TableData "Bank Account Ledger Entry" = imd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [UT] [Bank Reconciliation]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";
        ValueMustNotExistMsg: Label '%1 must not exist.';
        ValueMustExistMsg: Label '%1 must exist.';
        DialogErr: Label 'Dialog';
        UnsupportedTypeNotificationMsg: Label '%1 is not supported account type. You can enter and post the adjustment entry in a General Journal instead.', Comment = '%1=account type';
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CurrencyFactorOnValidateBankRecHeaderError()
    var
        BankRecHeader: Record "Bank Rec. Header";
    begin
        // Purpose of the test is to validate Currency Factor - OnValidate Trigger of Table ID - 10120 Bank Rec. Header.

        // Setup: Create Bank Reconciliation Header.
        CreateBankReconciliationHeader(BankRecHeader);

        // Exercise.
        asserterror BankRecHeader.Validate("Currency Factor");

        // Verify: Verify Error Code, Actual error - Currency Factor cannot be specified without Currency Code in Bank Rec. Header.
        Assert.ExpectedErrorCode('NCLCSRTS:TableErrorStr');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteBankRecHeader()
    var
        BankCommentLine: Record "Bank Comment Line";
        BankRecHeader: Record "Bank Rec. Header";
        BankRecLine: Record "Bank Rec. Line";
        BankRecSubLine: Record "Bank Rec. Sub-line";
    begin
        // Purpose of the test is to validate OnDelete Trigger of Table ID - 10120 Bank Rec. Header.

        // Setup: Create Bank Reconciliation Header and Bank Comment Line.
        CreateBankReconciliationHeader(BankRecHeader);
        CreateBankCommentLine(BankCommentLine, BankRecHeader."Bank Account No.", BankRecHeader."Statement No.");
        MockBankRecLine(
          BankRecLine, BankRecHeader."Bank Account No.", BankRecHeader."Statement No.", BankRecLine."Collapse Status"::" ");
        MockBankRecSubLine(BankRecSubLine, BankRecLine);

        // Exercise.
        BankRecHeader.Delete(true);

        // Verify: Verify Bank Reconciliation Header and Bank Comment Line is deleted.
        BankRecHeader.SetRecFilter;
        Assert.RecordIsEmpty(BankRecHeader);
        BankCommentLine.SetRecFilter;
        Assert.RecordIsEmpty(BankCommentLine);
        // Bank Rec. Line and Bank Rec. Sub-line deleted
        BankRecLine.SetRecFilter;
        Assert.RecordIsEmpty(BankRecLine);
        BankRecSubLine.SetRecFilter;
        Assert.RecordIsEmpty(BankRecSubLine);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RenameBankRecHeaderError()
    var
        BankRecHeader: Record "Bank Rec. Header";
    begin
        // Purpose of the test is to validate OnRename Trigger of Table ID - 10120 Bank Rec. Header.

        // Setup: Create Bank Reconciliation Header.
        CreateBankReconciliationHeader(BankRecHeader);

        // Exercise.
        asserterror BankRecHeader.Rename(BankRecHeader."Bank Account No.", LibraryUTUtility.GetNewCode);

        // Verify: Verify Error Code, Actual error - You cannot rename a Bank Rec. Header.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BankRecLineExistBankRecHeader()
    var
        BankRecHeader: Record "Bank Rec. Header";
        BankRecLine: Record "Bank Rec. Line";
    begin
        // Purpose of the test is to validate BankRecLineExist function of Table ID - 10120 Bank Rec. Header.

        // Setup: Create Bank Reconciliation Header and Bank Reconciliation Line.
        CreateBankReconciliationHeader(BankRecHeader);
        MockCollapsedDepositBankRecLine(BankRecLine, BankRecHeader."Bank Account No.", BankRecHeader."Statement No.");

        // Exercise & Verify: Verify Bank Reconciliation Line Exists.
        Assert.IsTrue(BankRecHeader.BankRecLineExist, StrSubstNo(ValueMustExistMsg, BankRecLine.TableCaption));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AccountNoOnValidateGLAccountBankRecLine()
    var
        BankRecLine: Record "Bank Rec. Line";
        GLAccount: Record "G/L Account";
    begin
        // Purpose of the test is to validate Account No. - OnValidate Trigger of Table ID - 10121 Bank Rec. Line.

        // Setup: Create G/L Account and Bank Reconciliation with Account Type - G/L Account.
        CreateGLAccount(GLAccount);
        MockBankRecLineWithRandomCollapseStatus(BankRecLine, LibraryUTUtility.GetNewCode, LibraryUTUtility.GetNewCode);  // Default Collapse - Option Range 0 to 2.
        UpdateAccountOnBankReconciliationLine(BankRecLine, BankRecLine."Account Type"::"G/L Account", GLAccount."No.");

        // Exercise.
        BankRecLine.Validate("Account No.");

        // Verify: Verify Description and Currency Code as blank on Bank Reconciliation Line.
        VerifyBankRecLineDescriptionAndCurrency(BankRecLine, GLAccount.Name, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AccountNoOnValidateCustomerBankRecLine()
    var
        BankRecHeader: Record "Bank Rec. Header";
        BankRecLine: Record "Bank Rec. Line";
        Customer: Record Customer;
    begin
        // Purpose of the test is to validate Account No. - OnValidate Trigger of Table ID - 10121 Bank Rec. Line.

        // Setup: Create Customer and Bank Reconciliation with Account Type - Customer.
        CreateCustomer(Customer);
        CreateBankReconciliationHeader(BankRecHeader);
        MockBankRecLineWithRandomCollapseStatus(BankRecLine, BankRecHeader."Bank Account No.", BankRecHeader."Statement No.");  // Default Collapse - Option Range 0 to 2.
        UpdateAccountOnBankReconciliationLine(BankRecLine, BankRecLine."Account Type"::Customer, Customer."No.");

        // Exercise.
        BankRecLine.Validate("Account No.");

        // Verify: Verify Description and Currency Code on Bank Reconciliation Line.
        VerifyBankRecLineDescriptionAndCurrency(BankRecLine, Customer.Name, Customer."Currency Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AccountNoOnValidateVendorBankRecLine()
    var
        BankRecHeader: Record "Bank Rec. Header";
        BankRecLine: Record "Bank Rec. Line";
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to validate Account No. - OnValidate Trigger of Table ID - 10121 Bank Rec. Line.

        // Setup: Create Vendor and Bank Reconciliation with Account Type - Vendor.
        CreateVendor(Vendor);
        CreateBankReconciliationHeader(BankRecHeader);
        MockBankRecLineWithRandomCollapseStatus(BankRecLine, BankRecHeader."Bank Account No.", BankRecHeader."Statement No.");  // Default Collapse - Option Range 0 to 2.
        UpdateAccountOnBankReconciliationLine(BankRecLine, BankRecLine."Account Type"::Vendor, Vendor."No.");

        // Exercise.
        BankRecLine.Validate("Account No.");

        // Verify: Verify Description and Currency Code on Bank Reconciliation Line.
        VerifyBankRecLineDescriptionAndCurrency(BankRecLine, Vendor.Name, Vendor."Currency Code");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AccountNoOnValidateBankAccountBankRecLine()
    var
        BankRecHeader: Record "Bank Rec. Header";
        BankRecLine: Record "Bank Rec. Line";
        BankAccount: Record "Bank Account";
    begin
        // Purpose of the test is to validate Account No. - OnValidate Trigger of Table ID - 10121 Bank Rec. Line.

        // Setup: Create Bank Account and Bank Reconciliation with Account Type - Bank Account.
        CreateBankAccount(BankAccount);
        CreateBankReconciliationHeader(BankRecHeader);
        MockBankRecLineWithRandomCollapseStatus(BankRecLine, BankRecHeader."Bank Account No.", BankRecHeader."Statement No.");  // Default Collapse - Option Range 0 to 2.
        UpdateAccountOnBankReconciliationLine(BankRecLine, BankRecLine."Account Type"::"Bank Account", BankAccount."No.");

        // Exercise.
        BankRecLine.Validate("Account No.");

        // Verify: Verify Description and Currency Code as blank on Bank Reconciliation Line.
        VerifyBankRecLineDescriptionAndCurrency(BankRecLine, BankAccount.Name, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AccountNoOnValidateFixedAssetBankRecLine()
    var
        BankRecHeader: Record "Bank Rec. Header";
        BankRecLine: Record "Bank Rec. Line";
        FixedAsset: Record "Fixed Asset";
    begin
        // Purpose of the test is to validate Account No. - OnValidate Trigger of Table ID - 10121 Bank Rec. Line.
        LibraryLowerPermissions.SetOutsideO365Scope();

        // Setup: Create Fixed Asset and Bank Reconciliation with Account Type - Fixed Asset.
        CreateFixedAsset(FixedAsset);
        CreateBankReconciliationHeader(BankRecHeader);
        MockBankRecLineWithRandomCollapseStatus(BankRecLine, BankRecHeader."Bank Account No.", BankRecHeader."Statement No.");  // Default Collapse - Option Range 0 to 2.
        UpdateAccountOnBankReconciliationLine(BankRecLine, BankRecLine."Account Type"::"Fixed Asset", FixedAsset."No.");

        // Exercise.
        BankRecLine.Validate("Account No.");

        // Verify: Verify Description and Currency Code as blank on Bank Reconciliation Line.
        VerifyBankRecLineDescriptionAndCurrency(BankRecLine, FixedAsset.Description, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BalAccountNoOnValidateGLAccountBankRecLine()
    var
        BankRecLine: Record "Bank Rec. Line";
        GLAccount: Record "G/L Account";
    begin
        // Purpose of the test is to validate Bal. Account No. - OnValidate Trigger of Table ID - 10121 Bank Rec. Line.

        // Setup: Create G/L Account and Bank Reconciliation with Bal. Account Type - G/L Account.
        CreateGLAccount(GLAccount);
        MockBankRecLineWithRandomCollapseStatus(BankRecLine, LibraryUTUtility.GetNewCode, LibraryUTUtility.GetNewCode);  // Default Collapse - Option Range 0 to 2.
        UpdateBalAccountOnBankReconciliationLine(BankRecLine, BankRecLine."Bal. Account Type"::"G/L Account", GLAccount."No.");

        // Exercise.
        BankRecLine.Validate("Bal. Account No.");

        // Verify: Verify Description and Currency Code as blank on Bank Reconciliation Line.
        VerifyBankRecLineDescriptionAndCurrency(BankRecLine, GLAccount.Name, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BalAccountNoOnValidateCustomerBankRecLine()
    var
        BankRecHeader: Record "Bank Rec. Header";
        BankRecLine: Record "Bank Rec. Line";
        Customer: Record Customer;
    begin
        // Purpose of the test is to validate Bal. Account No. - OnValidate Trigger of Table ID - 10121 Bank Rec. Line.

        // Setup: Create Customer and Bank Reconciliation with Bal. Account Type - Customer.
        CreateCustomer(Customer);
        CreateBankReconciliationHeader(BankRecHeader);
        MockBankRecLineWithRandomCollapseStatus(BankRecLine, BankRecHeader."Bank Account No.", BankRecHeader."Statement No.");  // Default Collapse - Option Range 0 to 2.
        UpdateBalAccountOnBankReconciliationLine(BankRecLine, BankRecLine."Bal. Account Type"::Customer, Customer."No.");

        // Exercise.
        BankRecLine.Validate("Bal. Account No.");

        // Verify: Verify Description and Currency Code on Bank Reconciliation Line.
        VerifyBankRecLineDescriptionAndCurrency(BankRecLine, Customer.Name, Customer."Currency Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BalAccountNoOnValidateVendorBankRecLine()
    var
        BankRecHeader: Record "Bank Rec. Header";
        BankRecLine: Record "Bank Rec. Line";
        Vendor: Record Vendor;
    begin
        // Purpose of the test is to validate Bal. Account No. - OnValidate Trigger of Table ID - 10121 Bank Rec. Line.

        // Setup: Create Vendor and Bank Reconciliation with Bal. Account Type - Vendor.
        CreateVendor(Vendor);
        CreateBankReconciliationHeader(BankRecHeader);
        MockBankRecLineWithRandomCollapseStatus(BankRecLine, BankRecHeader."Bank Account No.", BankRecHeader."Statement No.");  // Default Collapse - Option Range 0 to 2.
        UpdateBalAccountOnBankReconciliationLine(BankRecLine, BankRecLine."Bal. Account Type"::Vendor, Vendor."No.");

        // Exercise.
        BankRecLine.Validate("Bal. Account No.");

        // Verify: Verify Description and Currency Code on Bank Reconciliation Line.
        VerifyBankRecLineDescriptionAndCurrency(BankRecLine, Vendor.Name, Vendor."Currency Code");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BalAccountNoOnValidateBankAccountBankRecLine()
    var
        BankRecHeader: Record "Bank Rec. Header";
        BankRecLine: Record "Bank Rec. Line";
        BankAccount: Record "Bank Account";
    begin
        // Purpose of the test is to validate Bal. Account No. - OnValidate Trigger of Table ID - 10121 Bank Rec. Line.

        // Setup: Create Bank Account and Bank Reconciliation with Bal. Account Type - Bank Account.
        CreateBankAccount(BankAccount);
        CreateBankReconciliationHeader(BankRecHeader);
        MockBankRecLineWithRandomCollapseStatus(BankRecLine, BankRecHeader."Bank Account No.", BankRecHeader."Statement No.");  // Default Collapse - Option Range 0 to 2.
        UpdateBalAccountOnBankReconciliationLine(BankRecLine, BankRecLine."Bal. Account Type"::"Bank Account", BankAccount."No.");

        // Exercise.
        BankRecLine.Validate("Bal. Account No.");

        // Verify: Verify Description and Currency Code as blank on Bank Reconciliation Line.
        VerifyBankRecLineDescriptionAndCurrency(BankRecLine, BankAccount.Name, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BalAccountNoOnValidateFixedAssetBankRecLine()
    var
        BankRecHeader: Record "Bank Rec. Header";
        BankRecLine: Record "Bank Rec. Line";
        FixedAsset: Record "Fixed Asset";
    begin
        // Purpose of the test is to validate Bal. Account No. - OnValidate Trigger of Table ID - 10121 Bank Rec. Line.
        LibraryLowerPermissions.SetOutsideO365Scope();

        // Setup: Create Fixed Asset and Bank Reconciliation with Bal. Account Type - Fixed Asset.
        CreateFixedAsset(FixedAsset);
        CreateBankReconciliationHeader(BankRecHeader);
        MockBankRecLineWithRandomCollapseStatus(BankRecLine, BankRecHeader."Bank Account No.", BankRecHeader."Statement No.");  // Default Collapse - Option Range 0 to 2.
        UpdateBalAccountOnBankReconciliationLine(BankRecLine, BankRecLine."Bal. Account Type"::"Fixed Asset", FixedAsset."No.");

        // Exercise.
        BankRecLine.Validate("Bal. Account No.");

        // Verify: Verify Description and Currency Code as blank on Bank Reconciliation Line.
        VerifyBankRecLineDescriptionAndCurrency(BankRecLine, FixedAsset.Description, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteBankRecLine()
    var
        BankRecLine: Record "Bank Rec. Line";
    begin
        // Purpose of the test is to validate OnDelete Trigger of Table ID - 10121 Bank Rec. Line.

        // Setup: Create Bank Reconciliation Line.
        MockBankRecLineWithRandomCollapseStatus(BankRecLine, LibraryUTUtility.GetNewCode, LibraryUTUtility.GetNewCode);  // Collapse Status - option Range 0 to 2

        // Exercise.
        BankRecLine.Delete(true);

        // Verify: Verify Bank Reconciliation Line is deleted.
        Assert.IsFalse(
          BankRecLine.Get(BankRecLine."Bank Account No.", BankRecLine."Statement No.", BankRecLine."Record Type", BankRecLine."Line No."),
          StrSubstNo(ValueMustNotExistMsg, BankRecLine.TableCaption));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RenameBankRecLineError()
    var
        BankRecLine: Record "Bank Rec. Line";
    begin
        // Purpose of the test is to validate OnRename Trigger of Table ID - 10121 Bank Rec. Line.

        // Setup: Create Bank Reconciliation Line.
        MockBankRecLineWithRandomCollapseStatus(BankRecLine, LibraryUTUtility.GetNewCode, LibraryUTUtility.GetNewCode);  // Collapse Status - option Range 0 to 2

        // Exercise.
        asserterror BankRecLine.Rename(
            BankRecLine."Bank Account No.", LibraryUTUtility.GetNewCode, BankRecLine."Record Type", BankRecLine."Line No.");

        // Verify: Verify Error Code, Actual error - You cannot rename a Bank Rec. Line.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ExpandLineBankRecLine()
    var
        BankRecHeader: Record "Bank Rec. Header";
        BankRecLine: Record "Bank Rec. Line";
        BankRecSubLine: array[3] of Record "Bank Rec. Sub-line";
    begin
        // [SCENARIO 371566] Expand of Collapsed Bank Rec. Line (with two Bank Rec. Sub-lines) produces two new Expanded Bank Rec. lines

        // [GIVEN] Bank Reconciliation. Collapsed Deposit Bank Rec. Line with two Bank Rec. Sub-lines setup:
        // [GIVEN] "Document Type" = "A1"/"A2", "Document No." = "B1"/"B2", "External Document No." = "C"/"C"
        CreateBankReconciliationHeader(BankRecHeader);
        MockCollapsedDepositBankRecLine(BankRecLine, BankRecHeader."Bank Account No.", BankRecHeader."Statement No.");
        MockBankRecSubLine(BankRecSubLine[1], BankRecLine);
        MockBankRecSubLine(BankRecSubLine[2], BankRecLine);
        BankRecSubLine[2]."External Document No." := BankRecSubLine[1]."External Document No.";
        BankRecSubLine[2].Modify();

        // [WHEN] Expand line
        BankRecLine.ExpandLine(BankRecLine);

        // [THEN] Bank Rec. Sub-lines are deleted
        BankRecSubLine[3].SetRange("Bank Account No.", BankRecLine."Bank Account No.");
        BankRecSubLine[3].SetRange("Statement No.", BankRecLine."Statement No.");
        BankRecSubLine[3].SetRange("Bank Rec. Line No.", BankRecLine."Line No.");
        Assert.RecordIsEmpty(BankRecSubLine[3]);

        // [THEN] Two new Bank Rec. Lines are created with following details:
        // [THEN] "Document Type" = "A1"/"A2", "Document No." = "B1"/"B2", "External Document No." = "C", "Collapse Status" = "Expanded Deposit Line"
        FindBankRecLine(
          BankRecLine, BankRecLine."Bank Account No.", BankRecLine."Statement No.", BankRecLine."Record Type"::Deposit);
        VerifyBankRecLineValues(
          BankRecLine, 10000, BankRecSubLine[1]."Document Type", BankRecSubLine[1]."Document No.",
          BankRecSubLine[1]."External Document No.", BankRecLine."Collapse Status"::"Expanded Deposit Line", false, 0);

        BankRecLine.Next;
        VerifyBankRecLineValues(
          BankRecLine, 20000, BankRecSubLine[2]."Document Type", BankRecSubLine[2]."Document No.",
          BankRecSubLine[2]."External Document No.", BankRecLine."Collapse Status"::"Expanded Deposit Line", false, 0);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CollapseLinesBankRecLine()
    var
        BankRecHeader: Record "Bank Rec. Header";
        BankRecLine: array[3] of Record "Bank Rec. Line";
        BankRecSubLine: Record "Bank Rec. Sub-line";
    begin
        // [SCENARIO 371566] Collapse of two Expanded Bank Rec. Lines produces new Collapsed Bank Rec. Line with two new Bank Rec. Sub-lines

        // [GIVEN] Bank Reconciliation. Two Expanded Deposit Bank Rec. Lines with following setup:
        // [GIVEN] "Document Type" = "A1"/"A2" "Document No." = "B1"/"B2", "External Document No." = "C"
        CreateBankReconciliationHeader(BankRecHeader);
        MockExpandedDepositBankRecLine(BankRecLine[1], BankRecHeader."Bank Account No.", BankRecHeader."Statement No.");
        MockExpandedDepositBankRecLine(BankRecLine[2], BankRecHeader."Bank Account No.", BankRecHeader."Statement No.");
        BankRecLine[2]."External Document No." := BankRecLine[1]."External Document No.";
        BankRecLine[2].Modify();

        // [WHEN] Collapse line
        BankRecLine[3] := BankRecLine[1];
        BankRecLine[3].CollapseLines(BankRecLine[3]);

        // [THEN] Two new Bank Rec. Sub-lines are created with following details:
        // [THEN] "Document Type" = "A1"/"A2" "Document No." = "B1"/"B2", "External Document No." = "C"
        FindBankRecSubLine(
          BankRecSubLine, BankRecHeader."Bank Account No.", BankRecHeader."Statement No.", BankRecLine[1]."Line No.");
        VerifyBankRecSubLineValues(
          BankRecSubLine, 1, BankRecLine[1]."Document Type", BankRecLine[1]."Document No.",
          BankRecLine[1]."External Document No.");

        BankRecSubLine.Next;
        VerifyBankRecSubLineValues(
          BankRecSubLine, 2, BankRecLine[2]."Document Type", BankRecLine[2]."Document No.",
          BankRecLine[2]."External Document No.");

        // [THEN] New Bank Rec. Line is created with following details:
        // [THEN] "Document Type" = "", "Document No." = "", "External Document No." = "C", "Collapse Status" = "Collapsed Deposit"
        BankRecLine[1].Find;
        FindBankRecLine(
          BankRecLine[1], BankRecHeader."Bank Account No.", BankRecHeader."Statement No.", BankRecLine[1]."Record Type"::Deposit);
        VerifyBankRecLineValues(
          BankRecLine[1], 10000, BankRecLine[1]."Document Type"::" ", '',
          BankRecLine[2]."External Document No.", BankRecLine[1]."Collapse Status"::"Collapsed Deposit", false, 0);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ExpandLineBankRecLineWithClearedTrue()
    var
        BankRecLine: Record "Bank Rec. Line";
        BankRecSubLine: array[3] of Record "Bank Rec. Sub-line";
    begin
        // [SCENARIO 376610] Expand of Collapsed Bank Rec. Line with Cleared enabled produces two new Expanded Bank Rec. lines with Cleared = TRUE

        // [GIVEN] Bank Reconciliation. Collapsed Deposit Bank Rec. Line with Cleared = TRUE and two Bank Rec. Sub-lines
        CreateBankReconciliationHeaderWithCollapsedLine(BankRecSubLine, BankRecLine, true);

        // [WHEN] Expand line
        BankRecLine.ExpandLine(BankRecLine);

        // [THEN] Two new Bank Rec. Lines are created with Cleared = TRUE and Cleared Amount = Amount of each line
        FindBankRecLine(
          BankRecLine, BankRecLine."Bank Account No.", BankRecLine."Statement No.", BankRecLine."Record Type"::Deposit);
        VerifyBankRecLineValues(
          BankRecLine, 10000, BankRecSubLine[1]."Document Type", BankRecSubLine[1]."Document No.",
          BankRecSubLine[1]."External Document No.", BankRecLine."Collapse Status"::"Expanded Deposit Line",
          true, BankRecSubLine[1].Amount);
        BankRecLine.Next;
        VerifyBankRecLineValues(
          BankRecLine, 20000, BankRecSubLine[2]."Document Type", BankRecSubLine[2]."Document No.",
          BankRecSubLine[2]."External Document No.", BankRecLine."Collapse Status"::"Expanded Deposit Line",
          true, BankRecSubLine[2].Amount);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ExpandLineBankRecLineWithClearedFalse()
    var
        BankRecLine: Record "Bank Rec. Line";
        BankRecSubLine: array[3] of Record "Bank Rec. Sub-line";
    begin
        // [SCENARIO 376610] Expand of Collapsed Bank Rec. Line with Cleared disabled produces two new Expanded Bank Rec. lines with Cleared = FALSE;

        // [GIVEN] Bank Reconciliation. Collapsed Deposit Bank Rec. Line with Cleared = FALSE and two Bank Rec. Sub-lines
        CreateBankReconciliationHeaderWithCollapsedLine(BankRecSubLine, BankRecLine, false);

        // [WHEN] Expand line
        BankRecLine.ExpandLine(BankRecLine);

        // [THEN] Two new Bank Rec. Lines are created with Cleared = FALSE and Cleared Amount = 0
        FindBankRecLine(
          BankRecLine, BankRecLine."Bank Account No.", BankRecLine."Statement No.", BankRecLine."Record Type"::Deposit);
        VerifyBankRecLineValues(
          BankRecLine, 10000, BankRecSubLine[1]."Document Type", BankRecSubLine[1]."Document No.",
          BankRecSubLine[1]."External Document No.", BankRecLine."Collapse Status"::"Expanded Deposit Line",
          false, 0);
        BankRecLine.Next;
        VerifyBankRecLineValues(
          BankRecLine, 20000, BankRecSubLine[2]."Document Type", BankRecSubLine[2]."Document No.",
          BankRecSubLine[2]."External Document No.", BankRecLine."Collapse Status"::"Expanded Deposit Line",
          false, 0);
    end;

    [Test]
    [HandlerFunctions('BankRecProcessLinesReqHandler')]
    [Scope('OnPrem')]
    procedure SuggestTwiceBankRecLines()
    var
        BankAccount: Record "Bank Account";
        BankRecHeader: Record "Bank Rec. Header";
        BankRecLine: Record "Bank Rec. Line";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankRecProcessLines: Report "Bank Rec. Process Lines";
        ExtDocNo: Code[20];
        Amount1: Decimal;
        Amount2: Decimal;
        EntryNo1: Integer;
        EntryNo2: Integer;
    begin
        // [SCENARIO 376524] Expand Lines after Suggest Deposit Lines twice in a Bank Rec. Worksheet

        // [GIVEN] Bank Reconciliation Header "S" for Bank Account = "X"
        CreateBankAccount(BankAccount);
        CreateBankReconciliationHeaderWithBankAcc(BankRecHeader, BankAccount."No.");

        // [GIVEN] Two Bank Account Ledger Entries with Amount1 = 10, Amount2 = 20 for Bank Account = "X"
        ExtDocNo := LibraryUTUtility.GetNewCode;
        MockBankAccountLedgerEntry(EntryNo1, Amount1, BankAccount."No.", ExtDocNo, WorkDate);
        MockBankAccountLedgerEntry(EntryNo2, Amount2, BankAccount."No.", ExtDocNo, WorkDate);

        // [GIVEN] Suggest Lines called twice
        Commit();
        BankRecProcessLines.SetDoSuggestLines(
          true, BankRecHeader."Bank Account No.", BankRecHeader."Statement No.");
        LibraryVariableStorage.Enqueue(WorkDate);
        BankRecProcessLines.Run();
        LibraryVariableStorage.Enqueue(WorkDate);
        BankRecProcessLines.Run();

        // [WHEN] Expand Deposit Line
        FindBankRecLine(BankRecLine, BankAccount."No.", BankRecHeader."Statement No.", BankRecLine."Record Type"::Deposit);
        BankRecLine.ExpandLine(BankRecLine);

        // [THEN] Lines has "Collapse Status" = Expanded, Amount respectively 10 and 20
        BankRecLine.SetRange("Bank Ledger Entry No.", EntryNo1);
        FindBankRecLine(BankRecLine, BankAccount."No.", BankRecHeader."Statement No.", BankRecLine."Record Type"::Deposit);
        VerifyExpandedDepositLine(BankRecLine, ExtDocNo, Amount1, WorkDate);
        BankRecLine.SetRange("Bank Ledger Entry No.", EntryNo2);
        FindBankRecLine(BankRecLine, BankAccount."No.", BankRecHeader."Statement No.", BankRecLine."Record Type"::Deposit);
        VerifyExpandedDepositLine(BankRecLine, ExtDocNo, Amount2, WorkDate);

        // [THEN] Bank Account Ledger Entries has "Statement Status" = "Bank Acc. Entry Applied" and "Statement No." = "S"
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccount."No.");
        BankAccountLedgerEntry.FindSet();
        VerifyBankAccLedgerEntry(BankAccountLedgerEntry, BankRecHeader."Statement No.");
        BankAccountLedgerEntry.Next;
        VerifyBankAccLedgerEntry(BankAccountLedgerEntry, BankRecHeader."Statement No.");
    end;

    [Test]
    [HandlerFunctions('BankRecProcessLinesReqHandler')]
    [Scope('OnPrem')]
    procedure SuggestTwiceBankRecLinesAddNewLine()
    var
        BankAccount: Record "Bank Account";
        BankRecHeader: Record "Bank Rec. Header";
        BankRecLine: Record "Bank Rec. Line";
        BankRecProcessLines: Report "Bank Rec. Process Lines";
        ExtDocNo: Code[20];
        Amount: array[3] of Decimal;
        PostingDate: array[3] of Date;
        EntryNo: array[3] of Integer;
        i: Integer;
    begin
        // [SCENARIO 379501] Expand Lines after Suggest Deposit Lines twice with collapsed line when new line is added on suggestment

        // [GIVEN] Bank Reconciliation Header "S" for Bank Account = "X"
        CreateBankAccount(BankAccount);
        CreateBankReconciliationHeaderWithBankAcc(BankRecHeader, BankAccount."No.");

        // [GIVEN] Bank Account Ledger Entry with Amount = 10 on Date 10-01-15 for Bank Account = "X"
        // [GIVEN] Two Bank Account Ledger Entries with Amounts = 20 and 30 on Date 20-01-15 for Bank Account = "X"
        ExtDocNo := LibraryUTUtility.GetNewCode;
        PostingDate[1] := LibraryRandom.RandDate(5);
        PostingDate[2] := WorkDate;
        PostingDate[3] := WorkDate;
        for i := 1 to ArrayLen(PostingDate) do
            MockBankAccountLedgerEntry(EntryNo[i], Amount[i], BankAccount."No.", ExtDocNo, PostingDate[i]);

        // [GIVEN] Suggest Lines called twice on 20-01-15, then on 10-01-15
        Commit();
        BankRecProcessLines.SetDoSuggestLines(
          true, BankRecHeader."Bank Account No.", BankRecHeader."Statement No.");
        LibraryVariableStorage.Enqueue(PostingDate[2]);
        BankRecProcessLines.Run();
        Clear(BankRecProcessLines);
        BankRecProcessLines.SetDoSuggestLines(
          true, BankRecHeader."Bank Account No.", BankRecHeader."Statement No.");
        LibraryVariableStorage.Enqueue(PostingDate[1]);
        BankRecProcessLines.Run();

        // [WHEN] Expand Deposit Line
        BankRecLine.Reset();
        FindBankRecLine(BankRecLine, BankAccount."No.", BankRecHeader."Statement No.", BankRecLine."Record Type"::Deposit);
        BankRecLine.ExpandLine(BankRecLine);

        // [THEN] All 3 lines has "Collapse Status" = Expanded, with Amounts 10, 20 and 30 respectively and proper Posting Dates
        for i := 1 to ArrayLen(PostingDate) do begin
            BankRecLine.SetRange("Bank Ledger Entry No.", EntryNo[i]);
            FindBankRecLine(BankRecLine, BankAccount."No.", BankRecHeader."Statement No.", BankRecLine."Record Type"::Deposit);
            VerifyExpandedDepositLine(BankRecLine, ExtDocNo, Amount[i], PostingDate[i]);
        end;
    end;

    [Test]
    [HandlerFunctions('BankRecProcessLinesReqHandler')]
    [Scope('OnPrem')]
    procedure CollapseBankRecLinesAgainAfterCollapseAndExpandActions()
    var
        BankAccount: Record "Bank Account";
        BankRecHeader: Record "Bank Rec. Header";
        BankRecLine: Record "Bank Rec. Line";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankRecProcessLines: Report "Bank Rec. Process Lines";
        ExtDocNo: Code[20];
        Amount: array[2] of Decimal;
        EntryNo: array[2] of Integer;
        i: Integer;
    begin
        // [SCENARIO 380069] Collapse last Bank Rec. Lines after lines were collapsed and expanded

        // [GIVEN] Bank Statement "S" for Bank Account = "X"
        CreateBankAccount(BankAccount);
        CreateBankReconciliationHeaderWithBankAcc(BankRecHeader, BankAccount."No.");

        // [GIVEN] Two Bank Account Ledger Entries with Amount = 10 and Amount = 20 for Bank Account = "X"
        ExtDocNo := LibraryUTUtility.GetNewCode;
        for i := 1 to ArrayLen(EntryNo) do
            MockBankAccountLedgerEntry(EntryNo[i], Amount[i], BankAccount."No.", ExtDocNo, WorkDate);

        // [GIVEN] Suggest Lines, Expand, Collapse and Expand.
        Commit();
        BankRecProcessLines.SetDoSuggestLines(
          true, BankRecHeader."Bank Account No.", BankRecHeader."Statement No.");
        LibraryVariableStorage.Enqueue(WorkDate);
        BankRecProcessLines.Run();

        FindBankRecLine(BankRecLine, BankAccount."No.", BankRecHeader."Statement No.", BankRecLine."Record Type"::Deposit);
        BankRecLine.ExpandLine(BankRecLine);
        BankRecLine.FindLast();
        BankRecLine.CollapseLines(BankRecLine);
        BankRecLine.FindFirst();
        BankRecLine.ExpandLine(BankRecLine);

        // [WHEN] Collapse last Deposit Line second time
        BankRecLine.FindLast();
        BankRecLine.CollapseLines(BankRecLine);

        // [THEN] Collapsed Deposit Line has amount = 30
        BankRecLine.FindFirst();
        BankRecLine.TestField(Amount, Amount[1] + Amount[2]);
        // [THEN] Bank Account Ledger Entries are applied to Bank Statement "S"
        for i := 1 to ArrayLen(EntryNo) do begin
            BankAccountLedgerEntry.Get(EntryNo[i]);
            VerifyBankAccLedgerEntry(BankAccountLedgerEntry, BankRecHeader."Statement No.");
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankRecSublineIsNotDeletedOnDeleteBankRecLineTypeCheckOrAdjustment()
    var
        BankRecHeader: Record "Bank Rec. Header";
        BankRecLine: array[3] of Record "Bank Rec. Line";
        BankRecSubLine: Record "Bank Rec. Sub-line";
        LineNo: Integer;
    begin
        // [SCENARIO 271092] When a user deletes a bank reconciliation line with "Record Type" = "Check" or "Adjustment", this does not delete bank reconciliation sublines for a deposit bank rec. line with the same "Line No.".

        // [GIVEN] Bank account reconciliation with lines of all record types - Check, Adjustment, Deposit and the same "Line No.".
        CreateBankReconciliationHeader(BankRecHeader);

        LineNo := LibraryRandom.RandInt(100);
        MockBankRecLineForRecordType(BankRecLine[1], BankRecHeader, BankRecLine[1]."Record Type"::Check, LineNo);
        MockBankRecLineForRecordType(BankRecLine[2], BankRecHeader, BankRecLine[2]."Record Type"::Adjustment, LineNo);
        MockBankRecLineForRecordType(BankRecLine[3], BankRecHeader, BankRecLine[3]."Record Type"::Deposit, LineNo);

        // [GIVEN] Bank reconciliation subline, that is related to the deposit line.
        MockBankRecSubLine(BankRecSubLine, BankRecLine[3]);

        // [WHEN] Delete both "Check"- and "Adjustment"-typed lines.
        BankRecLine[1].Delete(true);
        BankRecLine[2].Delete(true);

        // [THEN] The subline is not deleted.
        BankRecSubLine.Find;
        BankRecSubLine.TestField("Statement No.", BankRecHeader."Statement No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankRecSublineDeletedOnDeleteBankRecLineTypeDeposit()
    var
        BankRecHeader: Record "Bank Rec. Header";
        BankRecLine: Record "Bank Rec. Line";
        BankRecSubLine: Record "Bank Rec. Sub-line";
    begin
        // [SCENARIO 271092] When a user deletes a bank reconciliation line with "Record Type" = "Deposit", this deletes all related bank reconciliation sublines.

        // [GIVEN] Bank account reconciliation with deposit line.
        CreateBankReconciliationHeader(BankRecHeader);
        MockBankRecLineForRecordType(BankRecLine, BankRecHeader, BankRecLine."Record Type"::Deposit, LibraryRandom.RandInt(100));

        // [GIVEN] Bank reconciliation subline, that is related to the deposit line.
        MockBankRecSubLine(BankRecSubLine, BankRecLine);

        // [WHEN] Delete the deposit line.
        BankRecLine.Delete(true);

        // [THEN] The subline is deleted.
        BankRecSubLine.SetRange("Statement No.", BankRecHeader."Statement No.");
        Assert.RecordIsEmpty(BankRecSubLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CollapseLinesBankRecLineWithClearedTrue()
    var
        BankRecHeader: Record "Bank Rec. Header";
        BankRecLine: array[2] of Record "Bank Rec. Line";
        TotalAmount: Integer;
    begin
        // [SCENARIO ] Collapse of two Expanded Bank Rec. Lines with "Cleared" = "TRUE" produces new Collapsed Bank Rec. Line with "Cleared" = "TRUE"

        // [GIVEN] Bank Reconciliation. Two Expanded Deposit Bank Rec. Lines with following setup:
        // [GIVEN] "Document Type" = "A1"/"A2" "Document No." = "B1"/"B2", "External Document No." = "C", "Cleared" = "TRUE", "Amount" = "D1"/"D2"
        CreateBankReconciliationHeader(BankRecHeader);
        MockExpandedDepositBankRecLineWithClearedAndAmount(
          BankRecLine[1], BankRecHeader."Bank Account No.", BankRecHeader."Statement No.", LibraryRandom.RandInt(100), true);
        MockExpandedDepositBankRecLineWithClearedAndAmount(
          BankRecLine[2], BankRecHeader."Bank Account No.", BankRecHeader."Statement No.", LibraryRandom.RandInt(100), true);
        BankRecLine[2]."External Document No." := BankRecLine[1]."External Document No.";
        BankRecLine[2].Modify(true);
        TotalAmount := BankRecLine[1].Amount + BankRecLine[2].Amount;

        // [WHEN] Collapse line
        BankRecLine[1].CollapseLines(BankRecLine[1]);

        // [THEN] New Bank Rec. Line is created with following details:
        // [THEN] "Document Type" = "", "Document No." = "", "External Document No." = "C", "Collapse Status" = "Collapsed Deposit", "Cleared" = "TRUE", "Cleared Amount" = "D1 + D2"
        VerifyBankRecLineValues(
          BankRecLine[1], 10000, BankRecLine[1]."Document Type"::" ", '',
          BankRecLine[1]."External Document No.", BankRecLine[1]."Collapse Status"::"Collapsed Deposit", true, TotalAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CollapseLinesBankRecLineWithClearedTrueAndFalse()
    var
        BankRecHeader: Record "Bank Rec. Header";
        BankRecLine: array[2] of Record "Bank Rec. Line";
    begin
        // [SCENARIO ] Collapse of two Expanded Bank Rec. Lines with "Cleared" = "TRUE"/"FALSE" produces new Collapsed Bank Rec. Line with "Cleared" = "FALSE"

        // [GIVEN] Bank Reconciliation. Two Expanded Deposit Bank Rec. Lines with following setup:
        // [GIVEN] "Document Type" = "A1"/"A2" "Document No." = "B1"/"B2", "External Document No." = "C", "Cleared" = "TRUE"/"FALSE", "Amount" = "D1"/"D2"
        CreateBankReconciliationHeader(BankRecHeader);
        MockExpandedDepositBankRecLineWithClearedAndAmount(
          BankRecLine[1], BankRecHeader."Bank Account No.", BankRecHeader."Statement No.", LibraryRandom.RandInt(100), true);
        MockExpandedDepositBankRecLineWithClearedAndAmount(
          BankRecLine[2], BankRecHeader."Bank Account No.", BankRecHeader."Statement No.", LibraryRandom.RandInt(100), false);
        BankRecLine[2]."External Document No." := BankRecLine[1]."External Document No.";
        BankRecLine[2].Modify(true);

        // [WHEN] Collapse line
        BankRecLine[1].CollapseLines(BankRecLine[1]);

        // [THEN] New Bank Rec. Line is created with following details:
        // [THEN] "Document Type" = "", "Document No." = "", "External Document No." = "C", "Collapse Status" = "Collapsed Deposit", "Cleared" = "TRUE", "Cleared Amount" = "0"
        VerifyBankRecLineValues(
          BankRecLine[1], 10000, BankRecLine[1]."Document Type"::" ", '',
          BankRecLine[1]."External Document No.", BankRecLine[1]."Collapse Status"::"Collapsed Deposit", false, 0);
    end;

    [Test]
    [HandlerFunctions('UnsupportedTypeSendNotificationHandler')]
    [Scope('OnPrem')]
    procedure AccountTypeICPartner()
    var
        BankRecLine: Record "Bank Rec. Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // [SCENARIO 381948] User gets notification when use account type "IC Partner"

        // [WHEN] Account Type changed to "IC Partner"
        BankRecLine.Validate("Account Type", BankRecLine."Account Type"::"IC Partner");

        // [THEN] Notification "IC Partner is not supported account type..."
        Assert.ExpectedMessage(StrSubstNo(UnsupportedTypeNotificationMsg, BankRecLine."Account Type"), LibraryVariableStorage.DequeueText);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('UnsupportedTypeSendNotificationHandler')]
    [Scope('OnPrem')]
    procedure AccountTypeEmployee()
    var
        BankRecLine: Record "Bank Rec. Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // [SCENARIO 381948] User gets notification when use account type Employee

        // [WHEN] Account Type changed to Employee
        BankRecLine.Validate("Account Type", BankRecLine."Account Type"::Employee);

        // [THEN] Notification "Employee is not supported account type..."
        Assert.ExpectedMessage(StrSubstNo(UnsupportedTypeNotificationMsg, BankRecLine."Account Type"), LibraryVariableStorage.DequeueText);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('UnsupportedTypeSendNotificationHandler')]
    [Scope('OnPrem')]
    procedure BalAccountTypeICPartner()
    var
        BankRecLine: Record "Bank Rec. Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // [SCENARIO 381948] User gets notification when use bal. account type "IC Partner"

        // [WHEN] Bal. Account Type changed to "IC Partner"
        BankRecLine.Validate("Bal. Account Type", BankRecLine."Bal. Account Type"::"IC Partner");

        // [THEN] Notification "IC Partner is not supported account type..."
        Assert.ExpectedMessage(StrSubstNo(UnsupportedTypeNotificationMsg, BankRecLine."Bal. Account Type"), LibraryVariableStorage.DequeueText);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('UnsupportedTypeSendNotificationHandler')]
    [Scope('OnPrem')]
    procedure BalAccountTypeEmployee()
    var
        BankRecLine: Record "Bank Rec. Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // [SCENARIO 381948] User gets notification when use bal. account type Employee

        // [WHEN] Bal. Account Type changed to Employee
        BankRecLine.Validate("Bal. Account Type", BankRecLine."Bal. Account Type"::Employee);

        // [THEN] Notification "Employee is not supported account type..."
        Assert.ExpectedMessage(StrSubstNo(UnsupportedTypeNotificationMsg, BankRecLine."Bal. Account Type"), LibraryVariableStorage.DequeueText);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;


    local procedure MockExpandedDepositBankRecLine(var BankRecLine: Record "Bank Rec. Line"; BankAccountNo: Code[20]; StatementNo: Code[20])
    begin
        MockBankRecLine(BankRecLine, BankAccountNo, StatementNo, BankRecLine."Collapse Status"::"Expanded Deposit Line");
    end;

    local procedure MockExpandedDepositBankRecLineWithClearedAndAmount(var BankRecLine: Record "Bank Rec. Line"; BankAccountNo: Code[20]; StatementNo: Code[20]; Amount: Integer; Cleared: Boolean)
    begin
        MockBankRecLine(BankRecLine, BankAccountNo, StatementNo, BankRecLine."Collapse Status"::"Expanded Deposit Line");
        BankRecLine.Validate(Amount, Amount);
        BankRecLine.Validate(Cleared, Cleared);
        BankRecLine.Modify(true);
    end;

    local procedure MockCollapsedDepositBankRecLine(var BankRecLine: Record "Bank Rec. Line"; BankAccountNo: Code[20]; StatementNo: Code[20])
    begin
        MockBankRecLine(BankRecLine, BankAccountNo, StatementNo, BankRecLine."Collapse Status"::"Collapsed Deposit");
    end;

    local procedure MockBankRecLineWithRandomCollapseStatus(var BankRecLine: Record "Bank Rec. Line"; BankAccountNo: Code[20]; StatementNo: Code[20])
    begin
        MockBankRecLine(BankRecLine, BankAccountNo, StatementNo, LibraryRandom.RandIntInRange(0, 2));
    end;

    local procedure MockBankRecLine(var BankRecLine: Record "Bank Rec. Line"; BankAccountNo: Code[20]; StatementNo: Code[20]; CollapseStatus: Option)
    begin
        with BankRecLine do begin
            Init;
            "Bank Account No." := BankAccountNo;
            "Statement No." := StatementNo;
            "Record Type" := "Record Type"::Deposit;
            "Line No." := LibraryUtility.GetNewRecNo(BankRecLine, FieldNo("Line No."));

            "Collapse Status" := CollapseStatus;
            "Document Type" := LibraryRandom.RandIntInRange("Document Type"::Payment, "Document Type"::Refund);
            "Document No." := LibraryUTUtility.GetNewCode;
            "External Document No." :=
              CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen("External Document No.")), 1, MaxStrLen("External Document No."));
            Insert;
        end;
    end;

    local procedure MockBankRecLineForRecordType(var BankRecLine: Record "Bank Rec. Line"; BankRecHeader: Record "Bank Rec. Header"; RecordType: Option; LineNo: Integer)
    begin
        with BankRecLine do begin
            Init;
            "Bank Account No." := BankRecHeader."Bank Account No.";
            "Statement No." := BankRecHeader."Statement No.";
            "Record Type" := RecordType;
            "Line No." := LineNo;
            Insert;
        end;
    end;

    local procedure MockBankAccountLedgerEntry(var EntryNo: Integer; var BankAmount: Decimal; BankAccNo: Code[20]; ExtDocNo: Code[20]; PostingDate: Date)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        with BankAccountLedgerEntry do begin
            Init;
            "Entry No." := LibraryUtility.GetNewRecNo(BankAccountLedgerEntry, FieldNo("Entry No."));
            "Posting Date" := PostingDate;
            "Document Type" := "Document Type"::Payment;
            "Document No." := LibraryUTUtility.GetNewCode;
            "External Document No." := ExtDocNo;
            "Bank Account No." := BankAccNo;
            Amount := LibraryRandom.RandDec(100, 2);
            Open := true;
            Insert;
            EntryNo := "Entry No.";
            BankAmount := Amount;
        end;
    end;

    local procedure CreateBankAccount(var BankAccount: Record "Bank Account")
    begin
        BankAccount."No." := LibraryUTUtility.GetNewCode;
        BankAccount.Name := LibraryUTUtility.GetNewCode;
        BankAccount.Insert();
    end;

    local procedure CreateBankAccountLedgerEntry(): Integer
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry."Entry No." := SelectBankAccountLedgerEntryNo;
        BankAccountLedgerEntry.Insert();
        exit(BankAccountLedgerEntry."Entry No.");
    end;

    local procedure CreateBankReconciliationHeader(var BankRecHeader: Record "Bank Rec. Header")
    begin
        CreateBankReconciliationHeaderWithBankAcc(BankRecHeader, LibraryUTUtility.GetNewCode);
    end;

    local procedure CreateBankReconciliationHeaderWithCollapsedLine(var BankRecSubLine: array[2] of Record "Bank Rec. Sub-line"; var BankRecLine: Record "Bank Rec. Line"; Cleared: Boolean)
    var
        BankRecHeader: Record "Bank Rec. Header";
    begin
        CreateBankReconciliationHeader(BankRecHeader);
        MockCollapsedDepositBankRecLine(BankRecLine, BankRecHeader."Bank Account No.", BankRecHeader."Statement No.");
        MockBankRecSubLine(BankRecSubLine[1], BankRecLine);
        MockBankRecSubLine(BankRecSubLine[2], BankRecLine);
        BankRecLine.Validate(Cleared, Cleared);
        BankRecLine.Modify(true);
    end;

    local procedure CreateBankReconciliationHeaderWithBankAcc(var BankRecHeader: Record "Bank Rec. Header"; BankAccountNo: Code[20])
    begin
        BankRecHeader."Bank Account No." := BankAccountNo;
        BankRecHeader."Statement No." := LibraryUTUtility.GetNewCode;
        BankRecHeader."Currency Factor" := LibraryRandom.RandDec(10, 2);
        BankRecHeader."Statement Date" := WorkDate;
        BankRecHeader.Insert();
    end;

    local procedure MockBankRecSubLine(var BankRecSubLine: Record "Bank Rec. Sub-line"; BankRecLine: Record "Bank Rec. Line")
    var
        RecRef: RecordRef;
    begin
        with BankRecSubLine do begin
            Init;
            "Bank Account No." := BankRecLine."Bank Account No.";
            "Statement No." := BankRecLine."Statement No.";
            "Bank Rec. Line No." := BankRecLine."Line No.";
            RecRef.GetTable(BankRecSubLine);
            "Line No." := LibraryUtility.GetNewLineNo(RecRef, FieldNo("Line No."));

            "Bank Ledger Entry No." := CreateBankAccountLedgerEntry;
            "Document Type" := LibraryRandom.RandIntInRange("Document Type"::Payment, "Document Type"::Refund);
            "Document No." := LibraryUTUtility.GetNewCode;
            "External Document No." :=
              CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen("External Document No.")), 1, MaxStrLen("External Document No."));
            Amount := LibraryRandom.RandDec(100, 2);
            Insert;
        end;
    end;

    local procedure CreateBankCommentLine(var BankCommentLine: Record "Bank Comment Line"; BankAccountNo: Code[20]; No: Code[20])
    begin
        BankCommentLine."Table Name" := BankCommentLine."Table Name"::"Bank Rec.";
        BankCommentLine."Bank Account No." := BankAccountNo;
        BankCommentLine."No." := No;
        BankCommentLine.Insert();
    end;

    local procedure CreateCurrencyWithExchangeRate(): Code[10]
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        Currency.Code := LibraryUTUtility.GetNewCode10;
        Currency.Insert();
        CurrencyExchangeRate."Currency Code" := Currency.Code;
        CurrencyExchangeRate."Exchange Rate Amount" := LibraryRandom.RandDec(10, 2);
        CurrencyExchangeRate."Relational Exch. Rate Amount" := CurrencyExchangeRate."Exchange Rate Amount";
        CurrencyExchangeRate."Starting Date" := WorkDate;
        CurrencyExchangeRate.Insert();
        exit(Currency.Code);
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    begin
        Customer."No." := LibraryUTUtility.GetNewCode;
        Customer.Name := LibraryUTUtility.GetNewCode;
        Customer."Bill-to Customer No." := Customer."No.";
        Customer."Currency Code" := CreateCurrencyWithExchangeRate;
        Customer.Insert();
    end;

    local procedure CreateFixedAsset(var FixedAsset: Record "Fixed Asset")
    begin
        FixedAsset."No." := LibraryUTUtility.GetNewCode;
        FixedAsset.Description := LibraryUTUtility.GetNewCode;
        FixedAsset.Insert();
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account")
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode;
        GLAccount.Name := LibraryUTUtility.GetNewCode;
        GLAccount.Insert();
    end;

    local procedure CreateVendor(var Vendor: Record Vendor)
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode;
        Vendor."Pay-to Vendor No." := Vendor."No.";
        Vendor."Currency Code" := CreateCurrencyWithExchangeRate;
        Vendor.Name := LibraryUTUtility.GetNewCode;
        Vendor.Insert();
    end;

    local procedure FindBankRecLine(var BankRecLine: Record "Bank Rec. Line"; BankAccountNo: Code[20]; StatementNo: Code[20]; RecordType: Option)
    begin
        with BankRecLine do begin
            SetRange("Bank Account No.", BankAccountNo);
            SetRange("Statement No.", StatementNo);
            SetRange("Record Type", RecordType);
            FindFirst();
        end;
    end;

    local procedure FindBankRecSubLine(var BankRecSubLine: Record "Bank Rec. Sub-line"; BankAccountNo: Code[20]; StatementNo: Code[20]; BankRecLineNo: Integer)
    begin
        with BankRecSubLine do begin
            SetRange("Bank Account No.", BankAccountNo);
            SetRange("Statement No.", StatementNo);
            SetRange("Bank Rec. Line No.", BankRecLineNo);
            FindFirst();
        end;
    end;

    local procedure SelectBankAccountLedgerEntryNo(): Integer
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        if BankAccountLedgerEntry.FindLast() then
            exit(BankAccountLedgerEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure UpdateBalAccountOnBankReconciliationLine(var BankRecLine: Record "Bank Rec. Line"; BalAccountType: Option; BalAccountNo: Code[20])
    begin
        BankRecLine."Bal. Account Type" := BalAccountType;
        BankRecLine."Bal. Account No." := BalAccountNo;
        BankRecLine.Modify();
    end;

    local procedure UpdateAccountOnBankReconciliationLine(var BankRecLine: Record "Bank Rec. Line"; AccountType: Option; AccountNo: Code[20])
    begin
        BankRecLine."Account Type" := AccountType;
        BankRecLine."Account No." := AccountNo;
        BankRecLine.Modify();
    end;

    local procedure VerifyBankRecLineDescriptionAndCurrency(BankRecLine: Record "Bank Rec. Line"; Description: Text[100]; CurrencyCode: Code[10])
    begin
        BankRecLine.TestField(Description, Description);
        BankRecLine.TestField("Currency Code", CurrencyCode);
    end;

    local procedure VerifyBankRecLineValues(BankRecLine: Record "Bank Rec. Line"; ExpectedLineNo: Integer; ExpectedDocType: Option; ExpectedDocNo: Code[20]; ExpectedExternalDocNo: Code[35]; ExpectedCollapseStatus: Option; ExpectedCleared: Boolean; ExpectedClearedAmount: Decimal)
    begin
        with BankRecLine do begin
            Assert.AreEqual(ExpectedLineNo, "Line No.", FieldCaption("Line No."));
            Assert.AreEqual(ExpectedDocType, "Document Type", FieldCaption("Document Type"));
            Assert.AreEqual(ExpectedDocNo, "Document No.", FieldCaption("Document No."));
            Assert.AreEqual(ExpectedExternalDocNo, "External Document No.", FieldCaption("External Document No."));
            Assert.AreEqual(ExpectedCollapseStatus, "Collapse Status", FieldCaption("Collapse Status"));
            Assert.AreEqual(ExpectedCleared, Cleared, FieldCaption(Cleared));
            Assert.AreEqual(ExpectedClearedAmount, "Cleared Amount", FieldCaption("Cleared Amount"));
        end;
    end;

    local procedure VerifyBankRecSubLineValues(BankRecSubLine: Record "Bank Rec. Sub-line"; ExpectedLineNo: Integer; ExpectedDocType: Option; ExpectedDocNo: Code[20]; ExpectedExternalDocNo: Code[35])
    begin
        with BankRecSubLine do begin
            Assert.AreEqual(ExpectedLineNo, "Line No.", FieldCaption("Line No."));
            Assert.AreEqual(ExpectedDocType, "Document Type", FieldCaption("Document Type"));
            Assert.AreEqual(ExpectedDocNo, "Document No.", FieldCaption("Document No."));
            Assert.AreEqual(ExpectedExternalDocNo, "External Document No.", FieldCaption("External Document No."));
        end;
    end;

    local procedure VerifyExpandedDepositLine(BankRecLine: Record "Bank Rec. Line"; ExtDocNo: Code[20]; Amount: Decimal; PostingDate: Date)
    begin
        BankRecLine.TestField(Amount, Amount);
        BankRecLine.TestField("Collapse Status", BankRecLine."Collapse Status"::"Expanded Deposit Line");
        BankRecLine.TestField("External Document No.", ExtDocNo);
        BankRecLine.TestField("Posting Date", PostingDate);
    end;

    local procedure VerifyBankAccLedgerEntry(BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; StatementNo: Code[20])
    begin
        BankAccountLedgerEntry.TestField("Statement Status", BankAccountLedgerEntry."Statement Status"::"Bank Acc. Entry Applied");
        BankAccountLedgerEntry.TestField("Statement No.", StatementNo);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankRecProcessLinesReqHandler(var BankRecProcessLines: TestRequestPage "Bank Rec. Process Lines")
    var
        RecordTypeToProcess: Option Checks,Deposits,Both;
    begin
        BankRecProcessLines.RecordTypeToProcess.SetValue(RecordTypeToProcess::Both);
        BankRecProcessLines."Bank Rec. Line".SetFilter("Posting Date", Format(LibraryVariableStorage.DequeueDate));
        BankRecProcessLines.OK.Invoke;
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure UnsupportedTypeSendNotificationHandler(var Notification: Notification): Boolean
    begin
        LibraryVariableStorage.Enqueue(Notification.Message);
    end;
}

