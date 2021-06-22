codeunit 134141 "ERM Bank Reconciliation"
{
    Permissions = TableData "Bank Account Ledger Entry" = ri,
                  TableData "Bank Account Statement" = rimd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Bank Reconciliation]
        isInitialized := false;
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryRandom: Codeunit "Library - Random";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        WrongAmountErr: Label '%1 must be %2.', Locked = true;
        HasBankEntriesMsg: Label 'One or more bank account ledger entries in bank account';
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryDimension: Codeunit "Library - Dimension";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        isInitialized: Boolean;
        StatementNoEditableErr: Label '%1 should not be editable.', Comment = '%1 - "Statement No." field caption';
        TransactionAmountReducedMsg: Label 'The value in the Transaction Amount field has been reduced';

    [Test]
    [HandlerFunctions('GenJnlPageHandler')]
    [Scope('OnPrem')]
    procedure TransferToGenJnlLineWithBalAcc()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Initialize;

        // Setup: Create a bank rec. and add a line to it
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        SetupBankAccReconciliation(BankAccReconciliation, BankAccReconciliationLine);

        // Exercise: Execute Batch Job Transfer to GL Journal
        LibraryLowerPermissions.AddAccountReceivables;
        TransferToGenJnlReport(BankAccReconciliation, GenJournalBatch);

        // Verify: Check that the line was transfered to the GL Journal
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        Assert.IsTrue(GenJournalLine.FindFirst, 'Failed to find transfered journal line');
        Assert.AreEqual(BankAccReconciliationLine."Statement Amount", GenJournalLine.Amount,
          'Amount on transfered journal line is not correct');
        GenJournalLine.TestField("Bal. Account Type", GenJournalBatch."Bal. Account Type");
        GenJournalLine.TestField("Bal. Account No.", GenJournalBatch."Bal. Account No.");
    end;

    [Test]
    [HandlerFunctions('GenJnlPageHandler')]
    [Scope('OnPrem')]
    procedure TransferToGenJnlLineWithoutBalAcc()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        Initialize;

        // Setup: Create a bank rec. and add a line to it
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, LibraryERM.SelectGenJnlTemplate);
        SetupBankAccReconciliation(BankAccReconciliation, BankAccReconciliationLine);

        // Exercise: Execute Batch Job Transfer to GL Journal
        LibraryLowerPermissions.AddAccountReceivables;
        TransferToGenJnlReport(BankAccReconciliation, GenJournalBatch);
        // Verify: Check that the line was transfered to the GL Journal
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        Assert.IsTrue(GenJournalLine.FindFirst, 'Failed to find transfered journal line');
        Assert.AreEqual(-BankAccReconciliationLine."Statement Amount", GenJournalLine.Amount,
          'Amount on transfered journal line is not correct');
        GenJournalLine.TestField("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.TestField("Bal. Account No.", BankAccReconciliation."Bank Account No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DateCompressCheckLedgerEntries()
    var
        BankAccount: Record "Bank Account";
        CheckLedgerEntry: Record "Check Ledger Entry";
        DeleteCheckLedgerEntries: Report "Delete Check Ledger Entries";
        CurrentYear: Integer;
    begin
        Initialize;

        // Create check ledger entries
        PostCheck(BankAccount, CreateBankAccount, LibraryRandom.RandInt(1000));

        // Date compress check ledger entries
        // Close fiscal year
        LibraryFiscalYear.CloseFiscalYear;
        CurrentYear := Date2DMY(WorkDate, 3);

        // Run delete check batch job
        CheckLedgerEntry.SetRange("Bank Account No.", BankAccount."No.");
        DeleteCheckLedgerEntries.InitializeRequest(DMY2Date(1, 1, CurrentYear), DMY2Date(31, 12, CurrentYear));
        DeleteCheckLedgerEntries.UseRequestPage := false;
        DeleteCheckLedgerEntries.SetTableView(CheckLedgerEntry);
        DeleteCheckLedgerEntries.Run;

        // Verify check ledger entries are deleted
        CheckLedgerEntry.Reset;
        CheckLedgerEntry.SetRange("Bank Account No.", BankAccount."No.");
        CheckLedgerEntry.SetRange("Entry Status", CheckLedgerEntry."Entry Status"::Posted);
        Assert.AreEqual(CheckLedgerEntry.Count, 0, 'Expected no posted check ledger entries to exist');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckBankAccReconsiliation()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccount: Record "Bank Account";
        DocumentNo: Code[20];
    begin
        Initialize;

        // Setup
        DocumentNo := PostCheck(BankAccount, CreateBankAccount, LibraryRandom.RandInt(1000));

        // Exercise: Bank Account Reconciliation.
        LibraryLowerPermissions.AddAccountReceivables;
        CreateSuggestedBankReconc(BankAccReconciliation, BankAccount."No.", false);  // FALSE for 'Include Checks'.

        // Post the Bank Account Reconciliation
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // Verify: Verify Bank Ledger Entries closed
        VerifyBankRecLedgerEntry(BankAccount."No.", DocumentNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReversalBankAccReconciliation()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        GenJournalLine: Record "Gen. Journal Line";
        GLRegister: Record "G/L Register";
        ReversalEntry: Record "Reversal Entry";
    begin
        // Create and post General Journal Line using Random Values and Reversal of Bank Ledger Entries for Bank Reconciliation.

        // Setup: Create General Journal Line and Reverse Bank Ledger Entries for Bank Reconciliation.
        Initialize;
        CreateAndPostGenJournalLine(GenJournalLine, CreateBankAccount);
        GLRegister.FindLast;
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseRegister(GLRegister."No.");

        // Exercise: Bank Account Reconciliation.
        LibraryLowerPermissions.AddAccountReceivables;
        CreateSuggestedBankReconc(BankAccReconciliation, GenJournalLine."Bal. Account No.", false);  // FALSE for 'Include Checks'.

        // Post the Bank Account Reconciliation
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // Verify: Verify Bank Ledger Entry.
        VerifyReversedBankLedgerEntry(GenJournalLine."Bal. Account No.", GenJournalLine."Document No.", GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestBankReconcIncludeCheckTrue()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccount: Record "Bank Account";
    begin
        // Verify Bank Reconciliation Lines for Check Ledger entries ,when Include Check is True on Suggest Bank Account Reconciliation Lines.

        // Setup: Create Bank Account, create Check Ledger Entries.
        Initialize;
        PostCheck(BankAccount, CreateBankAccount, LibraryRandom.RandInt(1000));  // Take random Amount.

        // Exercise and Verification.
        LibraryLowerPermissions.AddAccountReceivables;
        SuggestAndVerifyBankReconcLine(BankAccount, '', BankAccReconciliationLine.Type::"Check Ledger Entry", true);  // '' for DocumentNo, TRUE for 'Include Checks'.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestBankReconcIncludeCheckFalse()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        DocumentNo: Code[20];
    begin
        // Verify Bank Reconciliation Lines for Bank Account ledger entries ,when Include Check is False on Suggest Bank Account Reconciliation Lines.

        // Setup: Create Bank Account, create Check Ledger Entries.
        Initialize;
        DocumentNo := PostCheck(BankAccount, CreateBankAccount, LibraryRandom.RandInt(1000));  // Take random Amount.

        // Exercise and Verification.
        LibraryLowerPermissions.AddAccountReceivables;
        SuggestAndVerifyBankReconcLine(BankAccount, DocumentNo, BankAccReconciliationLine.Type::"Bank Account Ledger Entry", false);  // '' for CheckNo, FALSE for 'Include Checks'.
    end;

    [Test]
    [HandlerFunctions('DeleteStatementConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeleteBankStatementConfirmed()
    var
        BankAccountStatement: Record "Bank Account Statement";
    begin
        // Setup.
        Initialize;
        CreateBankReconciliationWithLedgerEntries(BankAccountStatement);

        // Exercise.
        LibraryLowerPermissions.AddAccountReceivables;
        LibraryVariableStorage.Enqueue(true);
        BankAccountStatement.Delete(true);

        // Verify.
        asserterror
          BankAccountStatement.Get(BankAccountStatement."Bank Account No.",
            BankAccountStatement."Statement No.");
        Assert.AssertRecordNotFound;
    end;

    [Test]
    [HandlerFunctions('DeleteStatementConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeleteBankStatementNotConfirmed()
    var
        BankAccountStatement: Record "Bank Account Statement";
    begin
        // Setup.
        Initialize;
        CreateBankReconciliationWithLedgerEntries(BankAccountStatement);

        // Exercise.
        LibraryLowerPermissions.AddAccountReceivables;
        LibraryVariableStorage.Enqueue(false);
        asserterror BankAccountStatement.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyTotalOutstandingChecks()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccount: Record "Bank Account";
        OutstandingAmt: Decimal;
    begin
        Initialize;

        // Setup.
        PostCheck(BankAccount, CreateBankAccount, LibraryRandom.RandDec(1000, 2));
        CreateSuggestedBankReconc(BankAccReconciliation, BankAccount."No.", true);
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        OutstandingAmt := LibraryRandom.RandDec(1000, 2);
        PostCheck(BankAccount, BankAccount."No.", OutstandingAmt);
        CreateSuggestedBankReconc(BankAccReconciliation, BankAccount."No.", true);

        // Exercise.
        BankAccount.CalcFields("Total on Checks");

        // Verify.
        BankAccount.TestField("Total on Checks", OutstandingAmt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetStatementNoFromBankAccount()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccount: Record "Bank Account";
    begin
        Initialize;

        // Setup.
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."Last Statement No." := '';
        BankAccount.Modify;

        // Exercise.
        LibraryLowerPermissions.AddAccountReceivables;
        BankAccReconciliation.Init;
        BankAccReconciliation.Validate("Statement Type", BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation.Validate("Bank Account No.", BankAccount."No.");
        BankAccReconciliation.Insert(true);

        // Verify.
        BankAccReconciliation.TestField("Statement No.", Format(1));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccReconciliationBalanceToReconcile()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        BalanceToReconcile: Decimal;
        i: Integer;
    begin
        // [SCENARIO 363054] "Balance to Reconcile" does not include amounts from Posted Bank Reconciliations
        Initialize;

        // [GIVEN] Posted Bank Reconciliation A with Amount X
        CreateAndPostGenJournalLine(GenJournalLine, CreateBankAccount);
        CreateSuggestedBankReconc(BankAccReconciliation, GenJournalLine."Bal. Account No.", false);
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [GIVEN] Bank Reconciliation B with Amount Y
        for i := 1 to LibraryRandom.RandInt(5) do begin
            CreateAndPostGenJournalLine(GenJournalLine, GenJournalLine."Bal. Account No.");
            BalanceToReconcile += GenJournalLine.Amount;
        end;
        Clear(BankAccReconciliation);
        CreateSuggestedBankReconc(BankAccReconciliation, GenJournalLine."Bal. Account No.", false);

        // [WHEN] Bank Reconciliation B page is opened
        LibraryLowerPermissions.AddAccountReceivables;
        BankAccReconciliationPage.OpenView;
        BankAccReconciliationPage.GotoRecord(BankAccReconciliation);

        // [THEN] "Balance To Reconcile" = Y.
        Assert.AreEqual(
          -BalanceToReconcile,
          BankAccReconciliationPage.ApplyBankLedgerEntries.BalanceToReconcile.AsDEcimal,
          StrSubstNo(
            WrongAmountErr, BankAccReconciliationPage.ApplyBankLedgerEntries.BalanceToReconcile.Caption,
            -BalanceToReconcile));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccountTypeChangeClearsAccountNo()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Customer: Record Customer;
    begin
        SetupBankAccReconciliation(BankAccReconciliation, BankAccReconciliationLine);
        Customer.FindFirst;
        with BankAccReconciliationLine do begin
            Validate("Account Type", "Account Type"::Customer);
            Validate("Account No.", Customer."No.");
            Validate("Account Type", "Account Type"::"G/L Account");
            Assert.AreEqual('', "Account No.", '');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShortcutDimsOnPaymentReconJournalLine()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        DimensionValue: array[8] of Record "Dimension Value";
        i: Integer;
    begin
        // [FEATURE] [Dimension] [UT]
        // [SCENARIO 379516] Payment Reconciliation Journal correctly updates shortcut dimensions
        Initialize;
        UpdateGeneralShortcutDimensionSetup;

        // [GIVEN] Dimension 'D' with value 'V'. GLSetup."Shortcut Dimension 1 Code" = 'D'.
        // [GIVEN] Payment Reconciliation Journal Line.
        // [WHEN] Update journal line "Shortcut Dimension 1 Code" = 'V'
        BankAccReconciliationLine.Init;
        for i := 1 to ArrayLen(DimensionValue) do begin
            LibraryDimension.FindDimensionValue(DimensionValue[i], LibraryERM.GetShortcutDimensionCode(i));
            BankAccReconciliationLine.ValidateShortcutDimCode(i, DimensionValue[i].Code);
        end;

        // [THEN] Journal line Dimension Set Entry ("Dimension Set ID") contains Dimension 'D' with value 'V' record.
        for i := 1 to ArrayLen(DimensionValue) do
            Assert.AreEqual(
              DimensionValue[i].Code,
              GetDimensionValueCodeFromSetEntry(BankAccReconciliationLine."Dimension Set ID", DimensionValue[i]."Dimension Code"),
              DimensionValue[i].FieldCaption(Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SourceCodeSetupForReconPmtJnl()
    var
        SourceCode: Record "Source Code";
        SourceCodeSetup: Record "Source Code Setup";
        SourceCodeSetupPage: TestPage "Source Code Setup";
    begin
        // [FEATURE] [Source Code] [UT] [UI]
        // [SCENARIO 379544] Page field "Payment Reconciliation Journal" is available from "Source Code Setup"
        Initialize;

        // [GIVEN] Open Source Code Setup page
        LibraryERM.CreateSourceCode(SourceCode);
        SourceCodeSetupPage.OpenEdit;

        // [WHEN] Validate "Payment Reconciliation Journal" = "X"
        SourceCodeSetupPage."Payment Reconciliation Journal".SetValue(SourceCode.Code);
        SourceCodeSetupPage.Close;

        // [THEN] Record SourceCodeSetup."Payment Reconciliation Journal" = "X"
        SourceCodeSetup.Get;
        Assert.AreEqual(
          SourceCode.Code,
          SourceCodeSetup."Payment Reconciliation Journal",
          SourceCodeSetup.FieldCaption("Payment Reconciliation Journal"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDimSetIDOfCustLedgerEntryAfterPostingBankAccReconLine()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        StatementAmount: Decimal;
        CustomerNo: Code[20];
        CustLedgerEntryNo: Integer;
        DimSetID: Integer;
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 169462] "Dimension set ID" of Cust. Ledger Entry should be equal "Dimension Set ID" of Bank Acc. Reconcilation Line after posting
        Initialize;

        // [GIVEN] Posted sales invoice for a customer
        CreateAndPostSalesInvoice(CustomerNo, CustLedgerEntryNo, StatementAmount);

        // [GIVEN] Default dimension for the customer
        CreateDefaultDimension(CustomerNo, DATABASE::Customer);

        // [GIVEN] Bank Acc. Reconcilation Line with "Dimension Set ID" = "X" and "Account No." = the customer
        CreateApplyBankAccReconcilationLine(
          BankAccReconciliation, BankAccReconciliationLine,
          BankAccReconciliationLine."Account Type"::Customer,
          CustomerNo, StatementAmount, LibraryERM.CreateBankAccountNo);
        DimSetID := ApplyBankAccReconcilationLine(
            BankAccReconciliationLine, CustLedgerEntryNo, BankAccReconciliationLine."Account Type"::Customer, '');

        // [WHEN] Post Bank Acc. Reconcilation Line
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] "Cust. Ledger Entry"."Dimension Set ID" = "X"
        VerifyCustLedgerEntry(CustomerNo, BankAccReconciliation."Statement No.", DimSetID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDimSetIDOfVendLedgerEntryAfterPostingBankAccReconLine()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        StatementAmount: Decimal;
        VendorNo: Code[20];
        VendLedgerEntryNo: Integer;
        DimSetID: Integer;
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 169462] "Dimension set ID" of Vendor Ledger Entry should be equal "Dimension Set ID" of Bank Acc. Reconcilation Line after posting
        Initialize;

        // [GIVEN] Posted purchase invoice for a vendor
        CreateAndPostPurchaseInvoice(VendorNo, VendLedgerEntryNo, StatementAmount);

        // [GIVEN] Default dimension for the vendor
        CreateDefaultDimension(VendorNo, DATABASE::Vendor);

        // [GIVEN] Bank Acc. Reconcilation Line with "Dimension Set ID" = "X" and "Account No." = the vendor
        CreateApplyBankAccReconcilationLine(
          BankAccReconciliation, BankAccReconciliationLine,
          BankAccReconciliationLine."Account Type"::Vendor,
          VendorNo, StatementAmount, LibraryERM.CreateBankAccountNo);
        DimSetID := ApplyBankAccReconcilationLine(
            BankAccReconciliationLine, VendLedgerEntryNo, BankAccReconciliationLine."Account Type"::Vendor, '');

        // [WHEN] Post Bank Acc. Reconcilation Line
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] "Vendor Ledger Entry"."Dimension Set ID" = "X"
        VerifyVendLedgerEntry(VendorNo, BankAccReconciliation."Statement No.", DimSetID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyVATEntryAfterPostingBankAccReconLineForGLAccount()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        VATEntry: Record "VAT Entry";
        GLAccountNo: Code[20];
        BankAccountNo: Code[20];
        VATRate: Decimal;
    begin
        // [FEATURE] [G/L Account]
        // [SCENARIO 380298] VAT Entry shoud be created after posting Bank Acc. Reconcilation Line with G/L Account with VAT
        Initialize;

        // [GIVEN] G/L Account with VAT = 10%
        GLAccountNo := CreateGLAccountWithVATPostingSetup(VATRate);
        BankAccountNo := LibraryERM.CreateBankAccountNo;

        // [GIVEN] Bank Account Reconciliation for G/L Account with Amount = 100 (including VAT)
        CreateApplyBankAccReconcilationLine(BankAccReconciliation, BankAccReconciliationLine,
          BankAccReconciliationLine."Account Type"::"G/L Account",
          GLAccountNo, LibraryRandom.RandIntInRange(50, 100), BankAccountNo);
        BankAccReconciliationLine.TransferRemainingAmountToAccount;

        // [WHEN] Post Bank Acc. Reconcilation Line
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] VAT Entry created with "Amount" = 9,09
        VATEntry.SetRange("Document No.", BankAccReconciliation."Statement No.");
        VATEntry.FindFirst;
        VATEntry.TestField(Amount, -Round(((BankAccReconciliationLine."Statement Amount" / (1 + (VATRate / 100))) * (VATRate / 100))));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifySalespersonInDimSetOfBankAccReconLine()
    var
        Customer: Record Customer;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        // [FEATURE] [UT] [Customer]
        // [SCENARIO 175792] Salesperson code as default dimension should be in dimension set of Bank Account Reconcilation Line after validation of Customer
        Initialize;

        // [GIVEN] Customer with Salesperson Code as default dimension = "X"
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        Customer."Salesperson Code" := SalespersonPurchaser.Code;
        Customer.Modify;
        CreateDefaultDimensionWithSpecCode(SalespersonPurchaser.Code, DATABASE::"Salesperson/Purchaser");

        // [GIVEN] Record of Bank Account Reconcilation Line
        MockBankAccReconLine(BankAccReconciliationLine, BankAccReconciliationLine."Account Type"::Customer);

        // [WHEN] Validate Customer to "Account No." of Bank Account Reconcilation Line
        BankAccReconciliationLine.Validate("Account No.", Customer."No.");

        // [THEN] Dimension set of Bank Account Reconcilation Line contains Salesperson Code = "X"
        VerifyDimSetEntryValue(BankAccReconciliationLine."Dimension Set ID", Customer."Salesperson Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPurchaserInDimSetOfBankAccReconLine()
    var
        Vendor: Record Vendor;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        // [FEATURE] [UT] [Vendor]
        // [SCENARIO 175792] Purchaser code as default dimension should be in dimension set of Bank Account Reconcilation Line after validation of Vendor
        Initialize;

        // [GIVEN] Vendor with Purhaser Code as default dimension = "X"
        LibraryPurchase.CreateVendor(Vendor);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        Vendor."Purchaser Code" := SalespersonPurchaser.Code;
        Vendor.Modify;
        CreateDefaultDimensionWithSpecCode(SalespersonPurchaser.Code, DATABASE::"Salesperson/Purchaser");

        // [GIVEN] Record of Bank Account Reconcilation Line
        MockBankAccReconLine(BankAccReconciliationLine, BankAccReconciliationLine."Account Type"::Vendor);

        // [WHEN] Validate Vendor to "Vendor No." of Bank Account Reconcilation Line
        BankAccReconciliationLine.Validate("Account No.", Vendor."No.");

        // [THEN] Dimension set of Bank Account Reconcilation Line contains Purchaser Code = "X"
        VerifyDimSetEntryValue(BankAccReconciliationLine."Dimension Set ID", Vendor."Purchaser Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccReconciliationStatementNoIsNotEditable()
    var
        BankAccReconciliation: TestPage "Bank Acc. Reconciliation";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 381659] "Statement No." should not be editable in Bank Account Reconciliation
        BankAccReconciliation.OpenEdit;
        Assert.IsFalse(
          BankAccReconciliation.StatementNo.Editable, StrSubstNo(StatementNoEditableErr, BankAccReconciliation.StatementNo.Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastStatementOfReconciliationIsUpdatedOnlyOnInsertion()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccount: array[2] of Record "Bank Account";
    begin
        // [SCENARIO 381659] "Last Statement No." should be updated in Bank Account only on Bank Account Reconciliation insertion

        // [GIVEN] Bank Account Reconciliation "BA"
        BankAccReconciliation.Init;
        BankAccReconciliation."Statement Type" := BankAccReconciliation."Statement Type"::"Bank Reconciliation";

        // [GIVEN] Bank Account "Bank1" is set for "BA" having "Last Statement No." = "X01"
        LibraryERM.CreateBankAccount(BankAccount[1]);
        BankAccount[1]."Last Statement No." := 'X01';
        BankAccount[1].Modify;
        BankAccReconciliation.Validate("Bank Account No.", BankAccount[1]."No.");

        // [GIVEN] Bank Account "Bank2" is set for "BA" (instead of "Bank1") having "Last Statement No." = "Y01"
        LibraryERM.CreateBankAccount(BankAccount[2]);
        BankAccount[2]."Last Statement No." := 'Y01';
        BankAccount[2].Modify;
        BankAccReconciliation.Validate("Bank Account No.", BankAccount[2]."No.");
        BankAccount[2].TestField("Last Statement No.", 'Y01');

        // [WHEN] Bank Account Reconciliation "BA" is inserted with "Statement No." "1"
        BankAccReconciliation.Insert(true);

        // [THEN] Bank Account "Bank1" has "Last Statement No." = "X01"
        BankAccount[1].Find;
        BankAccount[1].TestField("Last Statement No.", 'X01');

        // [THEN] Bank Account "Bank2" has "Last Statement No." = "Y02"
        BankAccount[2].Find;
        BankAccount[2].TestField("Last Statement No.", BankAccReconciliation."Statement No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastStatementOfPaymentApplicationIsUpdatedOnlyOnInsertion()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccount: array[2] of Record "Bank Account";
    begin
        // [SCENARIO 381659] "Last Payment Statement No." should be updated in Bank Account only on Bank Account Reconciliation insertion

        // [GIVEN] Bank Account Reconciliation "BA"
        BankAccReconciliation.Init;
        BankAccReconciliation."Statement Type" := BankAccReconciliation."Statement Type"::"Payment Application";

        // [GIVEN] Bank Account "Bank1" is set for "BA" having "Last Payment Statement No." = "X01"
        LibraryERM.CreateBankAccount(BankAccount[1]);
        BankAccount[1]."Last Payment Statement No." := 'X01';
        BankAccount[1].Modify;
        BankAccReconciliation.Validate("Bank Account No.", BankAccount[1]."No.");

        // [GIVEN] Bank Account "Bank2" is set for "BA" (instead of "Bank1") having "Last Payment Statement No." = "Y01"
        LibraryERM.CreateBankAccount(BankAccount[2]);
        BankAccount[2]."Last Payment Statement No." := 'Y01';
        BankAccount[2].Modify;
        BankAccReconciliation.Validate("Bank Account No.", BankAccount[2]."No.");
        BankAccount[2].TestField("Last Payment Statement No.", 'Y01');

        // [WHEN] Bank Account Reconciliation "BA" is inserted with "Statement No." "1"
        BankAccReconciliation.Insert(true);

        // [THEN] Bank Account "Bank1" has "Last Payment Statement No." = "X01"
        BankAccount[1].Find;
        BankAccount[1].TestField("Last Payment Statement No.", 'X01');

        // [THEN] Bank Account "Bank2" has "Last Payment Statement No." = "Y02"
        BankAccount[2].Find;
        BankAccount[2].TestField("Last Payment Statement No.", BankAccReconciliation."Statement No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GlobalDimensionInheritsFromDimensionSetIDOfBankAccReconLineOnPosting()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        GLAccount: Record "G/L Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 202526] Global Dimension codes inherites from "Dimension Set ID" specified in Bank Acc. Reconciliation Line on posting

        Initialize;

        // [GIVEN] G/L Account "X" with Default dimension "DEPARTMENT - ADM"
        GeneralLedgerSetup.Get;
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"G/L Account", GLAccount."No.", GeneralLedgerSetup."Global Dimension 1 Code", DimensionValue.Code);

        // [GIVEN] Bank Acc. Reconcilation Line with G/L Account "X"
        CreateBankReconciliationWithGLAccount(BankAccReconciliation, BankAccReconciliationLine, GLAccount."No.");

        // [GIVEN] Set "Dimension Set ID" = 'Y' with dimension "DEPARTMENT - VW" for Bank Acc. Reconcilation Line
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        BankAccReconciliationLine.Validate(
          "Dimension Set ID", LibraryDimension.CreateDimSet(0, GeneralLedgerSetup."Global Dimension 1 Code", DimensionValue.Code));
        BankAccReconciliationLine.Modify(true);

        // [WHEN] Post Bank Acc. Reconcilation Line
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] G/L Entry with G/L Account "X" is posted. "Dimension Set ID" is 'Y', "Global Dimension 1 Code" is "DEPARTMENT - VW"
        VerifyGlobalDimensionCodeAndSetInGLEntry(GLAccount."No.", DimensionValue.Code, BankAccReconciliationLine."Dimension Set ID");
    end;

    [Test]
    [HandlerFunctions('GenJnlPageHandler')]
    [Scope('OnPrem')]
    procedure TransferToGenJnlLineWithReconcilBankAsBatchBalAcc()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 201538] The gen. journal line for reconciliation Bank Account is created with a correct sign when transferred from Bank Acc. Reconclication.
        Initialize;

        // [GIVEN] Bank Acc. Reconclication "BR" with Difference "D"
        SetupBankAccReconciliation(BankAccReconciliation, BankAccReconciliationLine);

        // [GIVEN] Gen Journal Batch "JB" for "BR"."Bank Account No." as Bal. Account
        SetupGenJournalBatch(
          GenJournalBatch, GenJournalBatch."Bal. Account Type"::"Bank Account", BankAccReconciliation."Bank Account No.");

        // [WHEN] Transfer to Gen. Journal is invoked from "BR"
        TransferToGenJnlReport(BankAccReconciliation, GenJournalBatch);

        // [THEN] Created Gen. Journal Line with Bal. Account = "BR"."Bal. Account"; Amount = -"D"
        VerifyGenJournalLine(
          GenJournalBatch."Journal Template Name", GenJournalBatch.Name, -BankAccReconciliationLine.Difference,
          GenJournalLine."Bal. Account Type"::"Bank Account", BankAccReconciliation."Bank Account No.");
    end;

    [Test]
    [HandlerFunctions('GenJnlPageHandler')]
    [Scope('OnPrem')]
    procedure TransferToGenJnlLineWithNotReconcilBankAsBatchBalAcc()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GenJournalLine: Record "Gen. Journal Line";
        BalAccountNo: Code[20];
    begin
        // [SCENARIO 201538] The gen. journal line for not reconciliation Bank Account is created with a correct sign when transferred from Bank Acc. Reconclication.
        Initialize;

        // [GIVEN] Bank Acc. Reconclication "BR" with Difference "D"
        SetupBankAccReconciliation(BankAccReconciliation, BankAccReconciliationLine);

        // [GIVEN] Bank Account "BA"
        BalAccountNo := LibraryERM.CreateBankAccountNo;
        // [GIVEN] Gen Journal Batch "JB" with Bal. type Bank Account and "JB"."Bal. Account No." = "BA"
        SetupGenJournalBatch(
          GenJournalBatch, GenJournalBatch."Bal. Account Type"::"Bank Account", BalAccountNo);

        // [WHEN] Transfer to Gen. Journal is invoked from "BR"
        TransferToGenJnlReport(BankAccReconciliation, GenJournalBatch);

        // [THEN] Created Gen. Journal Line with Bal. Account = "BA"; Amount = "D"
        VerifyGenJournalLine(
          GenJournalBatch."Journal Template Name", GenJournalBatch.Name, BankAccReconciliationLine.Difference,
          GenJournalLine."Bal. Account Type"::"Bank Account", BalAccountNo);
    end;

    [Test]
    [HandlerFunctions('GenJnlPageHandler')]
    [Scope('OnPrem')]
    procedure TransferToGenJnlLineWithGLAsBatchBalAcc()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GenJournalLine: Record "Gen. Journal Line";
        BalAccountNo: Code[20];
    begin
        // [SCENARIO 201538] The gen. journal line for G/L Account is created with a correct sign when transferred from Bank Acc. Reconclication.
        Initialize;

        // [GIVEN] Bank Acc. Reconclication "BR" with Difference "D"
        SetupBankAccReconciliation(BankAccReconciliation, BankAccReconciliationLine);

        // [GIVEN] G/L Account "GLAcc"
        BalAccountNo := LibraryERM.CreateGLAccountNo;
        // [GIVEN] Gen Journal Batch "JB" for "GLAcc" as Bal. Account
        SetupGenJournalBatch(
          GenJournalBatch, GenJournalBatch."Bal. Account Type"::"G/L Account", BalAccountNo);

        // [WHEN] Transfer to Gen. Journal is invoked from "BR"
        TransferToGenJnlReport(BankAccReconciliation, GenJournalBatch);

        // [THEN] Created Gen. Journal Line with Bal. Account = "GLAcc"; Amount = "D"
        VerifyGenJournalLine(
          GenJournalBatch."Journal Template Name", GenJournalBatch.Name, BankAccReconciliationLine.Difference,
          GenJournalLine."Bal. Account Type"::"G/L Account", BalAccountNo);
    end;

    [Test]
    [HandlerFunctions('GenJnlPageHandler')]
    [Scope('OnPrem')]
    procedure TransferToGenJnlLineWithEmptyBankAsBatchBalAcc()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 201538] The gen. journal line for empty Bank Account is created with a correct sign when transferred from Bank Acc. Reconclication.
        Initialize;

        // [GIVEN] Bank Acc. Reconclication "BR" with Difference "D"
        SetupBankAccReconciliation(BankAccReconciliation, BankAccReconciliationLine);

        // [GIVEN] Gen Journal Batch "JB" for empty Bank Account as Bal. Account
        SetupGenJournalBatch(
          GenJournalBatch, GenJournalBatch."Bal. Account Type"::"Bank Account", '');

        // [WHEN] Transfer to Gen. Journal is invoked from "BR"
        TransferToGenJnlReport(BankAccReconciliation, GenJournalBatch);

        // [THEN] Created Gen. Journal Line with Bal. Account = "BR"."Bal. Account"; Amount = -"D"
        VerifyGenJournalLine(
          GenJournalBatch."Journal Template Name", GenJournalBatch.Name, -BankAccReconciliationLine.Difference,
          GenJournalLine."Bal. Account Type"::"Bank Account", BankAccReconciliation."Bank Account No.");
    end;

    [Test]
    [HandlerFunctions('GenJnlPageHandler')]
    [Scope('OnPrem')]
    procedure TransferToGenJnlLineWithEmptyGLAsBatchBalAcc()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 201538] The gen. journal line for empty G/L Account is created with a correct sign when transferred from Bank Acc. Reconclication.
        Initialize;

        // [GIVEN] Bank Acc. Reconclication "BR" with Difference "D"
        SetupBankAccReconciliation(BankAccReconciliation, BankAccReconciliationLine);

        // [GIVEN] Gen Journal Batch "JB" for empty G/L Account as Bal. Account
        SetupGenJournalBatch(
          GenJournalBatch, GenJournalBatch."Bal. Account Type"::"G/L Account", '');

        // [WHEN] Transfer to Gen. Journal is invoked from "BR"
        TransferToGenJnlReport(BankAccReconciliation, GenJournalBatch);

        // [THEN] Created Gen. Journal Line Bal. with Account = "BR"."Bal. Account"; Amount = -"D"
        VerifyGenJournalLine(
          GenJournalBatch."Journal Template Name", GenJournalBatch.Name, -BankAccReconciliationLine.Difference,
          GenJournalLine."Bal. Account Type"::"Bank Account", BankAccReconciliation."Bank Account No.");
    end;

    [Test]
    [HandlerFunctions('TransToDiffAccModalPageHandler')]
    [Scope('OnPrem')]
    procedure PmtReconLineForCurrencyBankAccount()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GenJournalLine: Record "Gen. Journal Line";
        MatchBankPayments: Codeunit "Match Bank Payments";
        CurrencyCode: Code[10];
        GLAccNo: Code[20];
        ExchRateAmount: Decimal;
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 211312] G/L Entry with LCY creates when post Bank Acc. Reconciliation Line with FCY Bank Account

        // [GIVEN] Currency "X" with "Exchange Rate" = 1:5
        ExchRateAmount := LibraryRandom.RandIntInRange(5, 10);
        CurrencyCode :=
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate, ExchRateAmount, LibraryRandom.RandIntInRange(5, 10));

        // [GIVEN] Bank Account Reconciliation Line with Bank Account with Currency "X" and FCY Amount = 100
        CreateBankReconciliation(
          BankAccReconciliation, CreateBankAccountWithCurrencyCode(CurrencyCode),
          BankAccReconciliation."Statement Type"::"Payment Application");
        CreateBankAccReconLine(BankAccReconciliationLine, BankAccReconciliation);
        GLAccNo := LibraryERM.CreateGLAccountNo;
        LibraryVariableStorage.Enqueue(GLAccNo); // for TransToDiffAccModalPageHandler
        MatchBankPayments.TransferDiffToAccount(BankAccReconciliationLine, GenJournalLine);
        LibraryLowerPermissions.SetAccountReceivables;

        // [WHEN] Post Bank Acc. Reconciliation
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] G/L Entry created with Amount = 20
        VerifyGLEntryAmount(
          BankAccReconciliation."Statement No.", GLAccNo, -Round(BankAccReconciliationLine."Statement Amount" / ExchRateAmount));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,BankAccReconTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReversedEntriesAreNotShownInBankAccReconTest()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        ExpectedDocumentNo: array[2] of Code[20];
        BankAccountNo: Code[20];
        RequestPageXML: Text;
    begin
        // [FEATURE] [Reverse] [Payment] [Report] [Bank Acc. Recon. - Test]
        // [SCENARIO 231426] Reversed Bank Account Ledger Entries are not shown when report "Bank Acc. Recon. - Test" is printed
        Initialize;

        // [GIVEN] Bank Account = "B"
        BankAccountNo := LibraryERM.CreateBankAccountNo;

        // [GIVEN] Two posted vendor payments "P1" and "P2" with balancing bank account "B"
        PostTwoPaymentJournalLinesWithDocNoAndBalAccount(ExpectedDocumentNo, BankAccountNo);

        // [GIVEN] Payment "P2" is reversed
        ReverseTransactionGenJournalLine(ExpectedDocumentNo[2], BankAccountNo);

        // [GIVEN] Bank Account Reconciliation for "B"
        LibraryERM.CreateBankAccReconciliation(
          BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation.SetRecFilter;

        Commit;

        // [WHEN] Run report "Bank Acc. Recon. - Test" with enabled "Print outstanding transactions" for "B".
        RequestPageXML := REPORT.RunRequestPage(REPORT::"Bank Acc. Recon. - Test", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(REPORT::"Bank Acc. Recon. - Test", BankAccReconciliation, RequestPageXML);

        // [THEN] Payment "P1" exists in export XML.
        LibraryReportDataset.AssertElementWithValueExists('Outstd_Bank_Transac_Doc_No_', ExpectedDocumentNo[1]);

        // [THEN] Payment "P2" doesn't exist in export XML.
        LibraryReportDataset.AssertElementWithValueNotExist('Outstd_Bank_Transac_Doc_No_', ExpectedDocumentNo[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccReconciliationLine_GetDescription()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Description: Text[50];
    begin
        // [FEATURE] [Bank Acc. Reconciliation Line] [UT] [Description]
        // [SCENARIO 233511] TAB 274 "Bank Acc. Reconciliation Line".GetDescription() returns "Description" field value if not blanked
        // [SCENARIO 233511] and applied description info in case of blanked "Description" field
        Initialize;
        SetupBankAccReconciliation(BankAccReconciliation, BankAccReconciliationLine);

        // Blanked "Description", no applied entry
        UpdateBankAccReconciliationLineDescription(BankAccReconciliationLine, '');
        Assert.AreEqual('', BankAccReconciliationLine.GetDescription, '');

        // Typed "Description", no applied entry
        Description := LibraryUtility.GenerateGUID;
        UpdateBankAccReconciliationLineDescription(BankAccReconciliationLine, Description);
        Assert.AreEqual(Description, BankAccReconciliationLine.GetDescription, '');

        // Blanked "Description", single applied entry
        Description := LibraryUtility.GenerateGUID;
        MockAppliedPmtEntry(BankAccReconciliationLine, 1, Description);
        UpdateBankAccReconciliationLineDescription(BankAccReconciliationLine, '');
        Assert.AreEqual(Description, BankAccReconciliationLine.GetDescription, '');

        // Typed "Description", single applied entry
        Description := LibraryUtility.GenerateGUID;
        UpdateBankAccReconciliationLineDescription(BankAccReconciliationLine, Description);
        Assert.AreEqual(Description, BankAccReconciliationLine.GetDescription, '');

        // Blanked "Description", multiple applied entries
        MockAppliedPmtEntry(BankAccReconciliationLine, 2, LibraryUtility.GenerateGUID);
        UpdateBankAccReconciliationLineDescription(BankAccReconciliationLine, '');
        Assert.AreEqual('', BankAccReconciliationLine.GetDescription, '');

        // Typed "Description", multiple applied entries
        Description := LibraryUtility.GenerateGUID;
        UpdateBankAccReconciliationLineDescription(BankAccReconciliationLine, Description);
        Assert.AreEqual(Description, BankAccReconciliationLine.GetDescription, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostBankAccRecon_Description_OnlyInLine()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        GLEntry: Record "G/L Entry";
        Description: Text[50];
    begin
        // [FEATURE] [Description]
        // [SCENARIO 233511] Post bank account reconciliation in case of typed line's "Description" and blanked applied description
        Initialize;

        // [GIVEN]
        Description := LibraryUtility.GenerateGUID;
        CreateApplyBankReconWithDescription(BankAccReconciliation, '', Description);

        // [WHEN]
        GLEntry.FindLast;
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN]
        VerifyGLEntryWithDescriptionExists(GLEntry."Entry No.", Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostBankAccRecon_Description_OnlyInAppliesEntry()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        GLEntry: Record "G/L Entry";
        Description: Text[50];
    begin
        // [FEATURE] [Description]
        // [SCENARIO 233511] Post bank account reconciliation in case of blanked line's "Description" and typed applied description
        Initialize;

        // [GIVEN]
        Description := LibraryUtility.GenerateGUID;
        CreateApplyBankReconWithDescription(BankAccReconciliation, Description, '');

        // [WHEN]
        GLEntry.FindLast;
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN]
        VerifyGLEntryWithDescriptionExists(GLEntry."Entry No.", Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostBankAccRecon_Description_Both()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        GLEntry: Record "G/L Entry";
        Description: Text[50];
    begin
        // [FEATURE] [Description]
        // [SCENARIO 233511] Post bank account reconciliation in case of typed line's "Description" and typed applied description
        Initialize;

        // [GIVEN]
        Description := LibraryUtility.GenerateGUID;
        CreateApplyBankReconWithDescription(BankAccReconciliation, LibraryUtility.GenerateGUID, Description);

        // [WHEN]
        GLEntry.FindLast;
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN]
        VerifyGLEntryWithDescriptionExists(GLEntry."Entry No.", Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPmtOnlyBankAccReconLastStatementFields()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountNo: Code[20];
    begin
        // [SCENARIO 265955] When Payment Application Bank Acc. Reconciliation is posted without reconciliation, then Bank Account "Last Statement No." and "Balance Last Statement" are not changed,
        // [SCENARIO 265955] whereas field "Last Payment Statement No." equals to Bank Acc. Reconciliation "Statement No."
        Initialize;

        // [GIVEN] Bank Account with "Last Statement No." = <blank>, "Last Payment Statement No." = <blank> and "Balance Last Statement" = 0
        BankAccountNo := LibraryERM.CreateBankAccountNo;

        // [GIVEN] Create Bank Acc. Reconciliation with Statement Type = "Payment Application" and "Post Payments Only" = TRUE, Reconciliation Line has Statement Amount <> 0
        PrepareBankAccReconciliationWithPostPaymentsOnly(BankAccReconciliation, BankAccountNo, true);

        // [WHEN] Post Bank Acc. Reconciliation
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] Bank Account "Last Statement No." = <blank> and "Balance Last Statement" = 0
        // [THEN] Bank Account "Last Payment Statement No." equals to "Statement No." from Bank Acc. Reconciliation
        VerifyBankAccountLastStatementFields(BankAccountNo, BankAccReconciliation."Statement No.", '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostBankAccReconLastStatementFields()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountNo: Code[20];
    begin
        // [SCENARIO 265955] When Payment Application Bank Acc. Reconciliation is posted with reconciliation, then Bank Account "Last Statement No." and "Last Payment Statement No." are both equal to "Statement No." from Bank Acc. Reconciliation
        // [SCENARIO 265955] "Balance Last Statement" is increased by Posted Payment Recon. Line "Statement Amount" value
        Initialize;

        // [GIVEN] Bank Account with "Last Statement No." = <blank>, "Last Payment Statement No." = <blank> and "Balance Last Statement" = 0
        BankAccountNo := LibraryERM.CreateBankAccountNo;

        // [GIVEN] Create Bank Acc. Reconciliation with Statement Type = "Payment Application" and "Post Payments Only" = FALSE, Reconciliation line has Statement Amount = 1000.0
        PrepareBankAccReconciliationWithPostPaymentsOnly(BankAccReconciliation, BankAccountNo, false);

        // [WHEN] Post Bank Acc. Reconciliation
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] Bank Account "Last Statement No." and "Last Payment Statement No." are both equal to Bank Acc. Reconciliation "Statement No."
        // [THEN] Bank Account "Balance Last Statement" = 1000.0
        VerifyBankAccountLastStatementFields(
          BankAccountNo, BankAccReconciliation."Statement No.", BankAccReconciliation."Statement No.",
          GetStatementAmountFromBankAccRecon(BankAccountNo));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPmtReconciliationJournalWhenPostingDateOf2ndLineIsBefore1st()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconPostYesNo: Codeunit "Bank Acc. Recon. Post (Yes/No)";
        Amount: Decimal;
        BankAccountNo: Code[20];
        PostingDate: Date;
        VendorLedgerEntryNo: Integer;
        VendorNo: Code[20];
    begin
        // [SCENARIO 268197] When Posting Date of the 2nd Payment Line is before the 1st line, Payment Reconciliation must be able to post
        Initialize;

        // [GIVEN] Payment Reconciliation line for 01.04.18
        BankAccountNo := CreateBankAccount;
        CreateAndPostPurchaseInvoice(VendorNo, VendorLedgerEntryNo, Amount);

        LibraryERM.CreateBankAccReconciliation(
          BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Payment Application");
        CreateBankAccReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, VendorNo, Amount, WorkDate);

        BankAccReconciliation.Validate("Post Payments Only", true);
        BankAccReconciliationLine.Modify(true);

        // [GIVEN] Payment Reconciliation line for 01.03.18
        PostingDate := CalcDate('<-1M>', WorkDate);
        CreatePurchaseInvoice(PostingDate);
        CreateBankAccReconciliationLine(BankAccReconciliation, BankAccReconciliationLine, VendorNo, 0, PostingDate);

        CODEUNIT.Run(CODEUNIT::"Match Bank Pmt. Appl.", BankAccReconciliation);

        // [WHEN] Post payments
        Assert.IsTrue(BankAccReconPostYesNo.BankAccReconPostYesNo(BankAccReconciliation), 'Not all payments posted.');

        // [THEN] Bank Acc. Reconciliation Lines are posted
        VerifyBankAccountLastStatementFields(
          BankAccountNo, BankAccReconciliation."Statement No.", BankAccReconciliation."Statement No.", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccountStatementLinesDrillDown()
    var
        BankAccountStatement: Record "Bank Account Statement";
        BankAccountStatementLine: Record "Bank Account Statement Line";
        BankAccountStatementPage: TestPage "Bank Account Statement";
        BankAccountLedgerEntries: TestPage "Bank Account Ledger Entries";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 274506] Drill Down on "Appled Amount" in Bank Statement Lines opens relevant Bank Account Ledger Entries
        Initialize;
        LibraryApplicationArea.EnableBasicSetup;
        CreateBankReconciliationWithLedgerEntries(BankAccountStatement);
        BankAccountStatementLine.SetRange("Bank Account No.", BankAccountStatement."Bank Account No.");
        BankAccountStatementLine.SetRange("Statement No.", BankAccountStatement."Statement No.");
        BankAccountStatementLine.FindFirst;

        BankAccountStatementPage.OpenView;
        BankAccountStatementPage.GotoRecord(BankAccountStatement);
        BankAccountLedgerEntries.Trap;
        BankAccountStatementPage.Control11."Applied Amount".DrillDown;
        BankAccountLedgerEntries.Amount.AssertEquals(BankAccountStatementLine."Applied Amount");

        LibraryApplicationArea.DisableApplicationAreaSetup;
    end;

    [Test]
    [HandlerFunctions('PaymentApplicationModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostBankAccRecononciliationVendCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        DocumentNo: Code[20];
        BankAccountNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Purchase] [Refund] [Credit Memo]
        // [SCENARIO 287960] Refund bank account ledger entry is closed after posting of bank reconciliation matched with credit memo
        Initialize;

        // [GIVEN] Create and post purchase credit memo
        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);
        PurchaseHeader.CalcFields("Amount Including VAT");
        Amount := PurchaseHeader."Amount Including VAT";
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Create bank reconciliation
        LibraryLowerPermissions.AddAccountReceivables;
        BankAccountNo := CreateBankAccount;
        CreateBankReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Payment Application");

        // [GIVEN] Create bank reconciliation line and make manual match with posted credit memo
        CreateBankAccReconciliationLine(
          BankAccReconciliation, BankAccReconciliationLine, PurchaseHeader."Buy-from Vendor No.", Amount, WorkDate);
        LibraryVariableStorage.Enqueue(PurchaseHeader."Buy-from Vendor No.");
        LibraryVariableStorage.Enqueue(DocumentNo);
        MatchBankReconLineManually(BankAccReconciliationLine);

        // [WHEN] Reconciliation is being posted
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] Bank Ledger Entry closed
        VerifyBankRecLedgerEntry(BankAccountNo, BankAccReconciliation."Statement No.");
    end;

    [Test]
    [HandlerFunctions('PaymentApplicationWithReducedAmtModalPageHandler,TransToDiffAccModalPageHandler,MessageWithVerificationHandler')]
    [Scope('OnPrem')]
    procedure TransferDifferenceAppliedToVendorToGLAccount()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GenJournalLine: Record "Gen. Journal Line";
        MatchBankPayments: Codeunit "Match Bank Payments";
        GLAccNo: Code[20];
        LoweredAppliedAmount: Decimal;
        DiffAmount: Decimal;
    begin
        // [FEATURE] [Application] [UI]
        // [SCENARIO 290815] Stan can transfer difference previously applied to vendor account to G/L Account

        Initialize;

        LibraryLowerPermissions.AddAccountReceivables;

        // [GIVEN] Create Payment Reconciliation Line and transfer amount of 100 to vendor account
        CreateBankAccReconLineWithAmountTransferredToAcc(BankAccReconciliationLine);
        LibraryVariableStorage.Enqueue(BankAccReconciliationLine."Account No.");
        LoweredAppliedAmount := Round(BankAccReconciliationLine."Statement Amount" / 3);
        LibraryVariableStorage.Enqueue(LoweredAppliedAmount);
        DiffAmount := BankAccReconciliationLine."Statement Amount" - LoweredAppliedAmount;

        // [GIVEN] Applied amount changed to 75 so now there is difference of 25
        MatchBankReconLineManually(BankAccReconciliationLine);
        BankAccReconciliationLine.Find;

        // [WHEN] Transfer difference of 25 to account
        GLAccNo := LibraryERM.CreateGLAccountNo;
        LibraryVariableStorage.Enqueue(GLAccNo);
        BankAccReconciliationLine.Find;
        LibraryVariableStorage.Enqueue(TransactionAmountReducedMsg);
        MatchBankPayments.TransferDiffToAccount(BankAccReconciliationLine, GenJournalLine);

        // [THEN] New Payment Reconciliation Line created with amount of 25
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliationLine."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliationLine."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliationLine."Statement No.");
        BankAccReconciliationLine.SetFilter("Statement Line No.", '<>%1', BankAccReconciliationLine."Statement Line No.");
        Assert.RecordCount(BankAccReconciliationLine, 1);
        BankAccReconciliationLine.FindFirst;
        BankAccReconciliationLine.TestField("Statement Amount", DiffAmount);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('PaymentApplicationWithReducedAmtModalPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeAppliedAmountTransferredToVendor()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        AppliedPaymentEntry: Record "Applied Payment Entry";
        LoweredAppliedAmount: Decimal;
    begin
        // [FEATURE] [Application] [UI]
        // [SCENARIO 290815] Stan can change "Applied Amount" on "Payment Application" page if remaining amount already transferred to vendor account

        Initialize;

        // [GIVEN] Create Payment Reconciliation
        LibraryLowerPermissions.AddAccountReceivables;

        // [GIVEN] Create Payment Reconciliation Line and transfer amount of 100 to vendor account
        CreateBankAccReconLineWithAmountTransferredToAcc(BankAccReconciliationLine);
        LibraryVariableStorage.Enqueue(BankAccReconciliationLine."Account No.");
        LoweredAppliedAmount := Round(BankAccReconciliationLine."Statement Amount" / 3);
        LibraryVariableStorage.Enqueue(LoweredAppliedAmount);

        // [GIVEN] Opened "Payment Application" page

        // [WHEN] Change "Applied Amount" to 75 on "Payment Application" page
        MatchBankReconLineManually(BankAccReconciliationLine);

        // [THEN] One Applied Payment Entry exists for Bank Reconciliation Line
        BankAccReconciliationLine.Find;
        AppliedPaymentEntry.FilterAppliedPmtEntry(BankAccReconciliationLine);
        Assert.RecordCount(AppliedPaymentEntry, 1);

        // [THEN] "Applied Amount" is 75 in Applied Payment Entry
        AppliedPaymentEntry.FindFirst;
        AppliedPaymentEntry.TestField("Applied Amount", LoweredAppliedAmount);

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccReconciliationCanBePostedWhenStatementWithStatementNoAlreadyExists()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccountStatement: Record "Bank Account Statement";
    begin
        // [SCENARIO 302967] Bank Acc. Reconciliation can be posted when Bank Account Statement with the same Statement No. already exists
        Initialize;

        // [GIVEN] A Bank Account with Last Statement No. = '1'
        LibraryERM.CreateBankAccount(BankAccount);
        InitLastStatementNo(BankAccount, '1');

        // [GIVEN] A Bank Account Statement was created for this Bank Account with Statement No. = '1'
        CreateBankAccountStatement(BankAccount);

        // [GIVEN] A Bank Acc. Reconciliation with type = Payment was created with Statement No. = '1' and valid Line setup to be posted
        CreateApplyBankAccReconcilationLine(BankAccReconciliation, BankAccReconciliationLine,
          BankAccReconciliationLine."Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo, LibraryRandom.RandIntInRange(50, 100), BankAccount."No.");
        BankAccReconciliationLine.TransferRemainingAmountToAccount;

        // [WHEN] Posting Bank Acc. Reconciliation
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] Bank Account Statement for this Reconciliation was created with Statement No. = '2'
        BankAccountStatement.Get(BankAccount."No.", '2');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccReconciliationStatementNoTransfersToStatementWhenPostedAndNoStatementWithThisNoExists()
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccountStatement: Record "Bank Account Statement";
    begin
        // [SCENARIO 302967] When Bank Acc. Reconciliation is posted and there is no Bank Account Statement with same Statement No. exists the resulting Statement has that Statement No.
        Initialize;

        // [GIVEN] A Bank Account
        LibraryERM.CreateBankAccount(BankAccount);

        // [GIVEN] A Bank Acc. Reconciliation with type = Payment was created with Statement No. = '1' and valid Line setup to be posted
        CreateApplyBankAccReconcilationLine(BankAccReconciliation, BankAccReconciliationLine,
          BankAccReconciliationLine."Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo, LibraryRandom.RandIntInRange(50, 100), BankAccount."No.");
        BankAccReconciliationLine.TransferRemainingAmountToAccount;

        // [WHEN] Posting Bank Acc. Reconciliation
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);

        // [THEN] Bank Account Statement for this Reconciliation was created with Statement No. = '1'
        BankAccountStatement.Get(BankAccount."No.", '1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccountReconciliationLinesDrillDown()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliationPage: TestPage "Bank Acc. Reconciliation";
        BankAccountLedgerEntryPage: TestPage "Bank Account Ledger Entries";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 307867] Drill Down on "Applied Amount" in Bank Acc. Reconciliation Lines opens relevant Bank Account Ledger Entries.
        Initialize;

        // [GIVEN] Bank Acc. Reconciliation with manually matched Bank Acc. Reconciliation Line and Bank Account Ledger Entry.
        CreateBankAccountReconciliationWithMatchedLineAndLedgerEntry(BankAccReconciliation, BankAccReconciliationLine);
        BankAccReconciliationPage.OpenView;
        BankAccReconciliationPage.FILTER.SetFilter("Statement Type", Format(BankAccReconciliation."Statement Type"));
        BankAccReconciliationPage.FILTER.SetFilter("Bank Account No.", Format(BankAccReconciliation."Bank Account No."));
        BankAccReconciliationPage.FILTER.SetFilter("Statement No.", Format(BankAccReconciliation."Statement No."));
        BankAccountLedgerEntryPage.Trap;

        // [WHEN] Drill down to "Applied Amount".
        BankAccReconciliationPage.StmtLine."Applied Amount".DrillDown;

        // [THEN] "Amount" at opened page equals to "Applied Amount" of Bank Acc. Reconciliation Line.
        BankAccountLedgerEntryPage."Bank Account No.".AssertEquals(BankAccReconciliationLine."Bank Account No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccReconNotReversed()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        BankRecMatchCandidates: Query "Bank Rec. Match Candidates";
        Cnt: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 316656] Bank Rec. Match Candidates does not collect reversed entries

        Initialize;
        SetupBankAccReconciliation(BankAccReconciliation, BankAccReconciliationLine);
        MockBankAccLedgerEntry(BankAccountLedgerEntry, BankAccReconciliation."Bank Account No.", true);
        MockBankAccLedgerEntry(BankAccountLedgerEntry, BankAccReconciliation."Bank Account No.", false);

        BankRecMatchCandidates.SetFilter(BankRecMatchCandidates.Rec_Line_Bank_Account_No, BankAccReconciliationLine."Bank Account No.");
        BankRecMatchCandidates.Open;
        while BankRecMatchCandidates.Read do begin
            Assert.AreEqual(BankAccountLedgerEntry."Remaining Amount", BankRecMatchCandidates.Remaining_Amount, '');
            Cnt += 1;
        end;
        Assert.AreEqual(1, Cnt, 'Only one Bank Account Ledger Entry is expected.');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Bank Reconciliation");
        LibrarySetupStorage.Restore;
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Bank Reconciliation");
        LibraryVariableStorage.Clear;
        LibraryERMCountryData.UpdateGeneralLedgerSetup;
        LibraryERMCountryData.UpdateLocalPostingSetup;
        LibraryERMCountryData.UpdatePurchasesPayablesSetup;
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Source Code Setup");
        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Bank Reconciliation");
    end;

    local procedure PostCheck(var BankAccount: Record "Bank Account"; AccountNo: Code[20]; JnlAmount: Decimal): Code[20]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create General Journal Template and Batch for posting checks.
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        with GenJournalTemplate do begin
            Validate(Type, Type::Payments);
            Validate(Recurring, false);
            Modify(true);
        end;
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        with GenJournalBatch do begin
            Validate("Bal. Account Type", "Bal. Account Type"::"Bank Account");
            Validate("Bal. Account No.", CreateBankAccount);
            Modify(true);
            BankAccount.Get("Bal. Account No.");
        end;

        // Generate a journal line.
        with GenJournalLine do begin
            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
              "Document Type"::Payment, "Account Type"::"Bank Account",
              AccountNo, JnlAmount);
            Validate("Document No.", LibraryUtility.GenerateRandomCode(FieldNo("Document No."), DATABASE::"Gen. Journal Line"));
            Validate("Currency Code", BankAccount."Currency Code");
            Validate("Bal. Account Type", "Bal. Account Type"::"Bank Account");
            Validate("Bal. Account No.", BankAccount."No.");
            Validate("Bank Payment Type", "Bank Payment Type"::"Manual Check");
            Modify(true);
        end;

        // Post the check.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure PrepareBankAccReconciliationWithPostPaymentsOnly(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; BankAccountNo: Code[20]; PostPaymentsOnly: Boolean)
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CustLedgerEntryNo: Integer;
        CustNo: Code[20];
        StatementAmount: Decimal;
    begin
        StatementAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        CreateAndPostSalesInvoice(CustNo, CustLedgerEntryNo, StatementAmount);
        CreateApplyBankAccReconcilationLine(
          BankAccReconciliation, BankAccReconciliationLine, BankAccReconciliationLine."Account Type"::Customer, CustNo, StatementAmount,
          BankAccountNo);
        ApplyBankAccReconcilationLine(BankAccReconciliationLine, CustLedgerEntryNo, BankAccReconciliationLine."Account Type"::Customer, '');
        BankAccReconciliation.Validate("Post Payments Only", PostPaymentsOnly);
    end;

    local procedure PostTwoPaymentJournalLinesWithDocNoAndBalAccount(var DocumentNo: array[2] of Code[20]; BankAccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        AccountNo: Code[20];
        I: Integer;
    begin
        AccountNo := LibraryPurchase.CreateVendorNo;

        for I := 1 to ArrayLen(DocumentNo) do begin
            DocumentNo[I] := CreatePaymentJournalLineWithVendorAndBank(GenJournalLine, AccountNo, BankAccountNo);
            LibraryERM.PostGeneralJnlLine(GenJournalLine);
        end;
    end;

    local procedure ReverseTransactionGenJournalLine(DocumentNo: Code[20]; BankAccountNo: Code[20])
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetRange("Document No.", DocumentNo);
        BankAccountLedgerEntry.FindFirst;
        LibraryERM.ReverseTransaction(BankAccountLedgerEntry."Transaction No.");
    end;

    local procedure CreatePaymentJournalLineWithVendorAndBank(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; BankAccountNo: Code[20]): Code[20]
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, AccountNo,
          LibraryRandom.RandDecInRange(1000, 2000, 2));
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccountNo);
        GenJournalLine.Modify(true);

        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; BankAccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.DeleteAll(true);

        // Use Random because value is not important.
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo,
          GenJournalLine."Bal. Account Type"::"Bank Account", BankAccountNo, -LibraryRandom.RandDec(5, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostSalesInvoice(var CustomerNo: Code[20]; var CustLedgerEntryNo: Integer; var RemainingAmount: Decimal)
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibrarySales.CreateSalesInvoice(SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        CustLedgerEntry.SetRange("Customer No.", SalesHeader."Sell-to Customer No.");
        CustLedgerEntry.FindFirst;
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustomerNo := CustLedgerEntry."Customer No.";
        CustLedgerEntryNo := CustLedgerEntry."Entry No.";
        RemainingAmount := CustLedgerEntry."Remaining Amount";
    end;

    local procedure CreateAndPostPurchaseInvoice(var VendorNo: Code[20]; var VendLedgerEntryNo: Integer; var RemainingAmount: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        VendorLedgerEntry.SetRange("Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        VendorLedgerEntry.FindFirst;
        VendorLedgerEntry.CalcFields("Remaining Amount");
        VendorNo := VendorLedgerEntry."Vendor No.";
        VendLedgerEntryNo := VendorLedgerEntry."Entry No.";
        RemainingAmount := VendorLedgerEntry."Remaining Amount";
    end;

    local procedure CreateGLAccountWithVATPostingSetup(var VATRate: Decimal) GLAccountNo: Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATRate := LibraryRandom.RandIntInRange(2, 5);
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup,
          VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATRate);
        GLAccountNo := VATPostingSetup."Purchase VAT Account";
        UpdateGLAccountPostingGroups(GLAccountNo,
          VATPostingSetup."VAT Prod. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
    end;

    local procedure UpdateGLAccountPostingGroups(GLAccountNo: Code[20]; VATProdPostingGroup: Code[20]; VATBusPostingGroup: Code[20])
    var
        GLAccount: Record "G/L Account";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        GLAccount.Get(GLAccountNo);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        GLAccount."Gen. Posting Type" := GLAccount."Gen. Posting Type"::Purchase;
        GLAccount."Gen. Prod. Posting Group" := GenProductPostingGroup.Code;
        GLAccount."VAT Prod. Posting Group" := VATProdPostingGroup;
        GLAccount."VAT Bus. Posting Group" := VATBusPostingGroup;
        GLAccount.Modify(true);
    end;

    local procedure CreateDefaultDimension(AccountNo: Code[20]; TableID: Integer)
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, TableID, AccountNo, Dimension.Code, DimensionValue.Code);
    end;

    local procedure CreateDefaultDimensionWithSpecCode(AccountNo: Code[20]; TableID: Integer)
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimension(Dimension);
        CreateDimensionValueWithSpecCode(DimensionValue, AccountNo, Dimension.Code);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, TableID, AccountNo, Dimension.Code, DimensionValue.Code);
    end;

    local procedure CreateDimensionValueWithSpecCode(var DimensionValue: Record "Dimension Value"; DimensionValueCode: Code[20]; DimensionCode: Code[20])
    begin
        DimensionValue.Init;
        DimensionValue.Validate("Dimension Code", DimensionCode);
        DimensionValue.Validate(Code, DimensionValueCode);
        DimensionValue.Insert(true);
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Last Statement No.", Format(LibraryRandom.RandInt(10)));  // Take Random Value.
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateBankAccountWithCurrencyCode(CurrencyCode: Code[10]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(CreateBankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateBankAccountReconciliationWithMatchedLineAndLedgerEntry(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateAndPostGenJournalLine(GenJournalLine, CreateBankAccount);
        CreateSuggestedBankReconc(BankAccReconciliation, GenJournalLine."Bal. Account No.", false);

        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.FindFirst;
    end;

    local procedure CreateBankAccountStatement(BankAccount: Record "Bank Account")
    var
        BankAccountStatement: Record "Bank Account Statement";
    begin
        BankAccountStatement.Init;
        BankAccountStatement."Bank Account No." := BankAccount."No.";
        BankAccountStatement."Statement No." := BankAccount."Last Statement No.";
        BankAccountStatement."Statement Date" := WorkDate;
        BankAccountStatement.Insert;
    end;

    local procedure CreateBankReconciliation(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; BankAccountNo: Code[20]; BankReconType: Option)
    begin
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccountNo, BankReconType);
        BankAccReconciliation.Validate("Statement Date", WorkDate);
        BankAccReconciliation.Modify(true);
    end;

    [Normal]
    local procedure CreateBankReconciliationWithLedgerEntries(var BankAccountStatement: Record "Bank Account Statement")
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateAndPostGenJournalLine(GenJournalLine, CreateBankAccount);
        CreateSuggestedBankReconc(BankAccReconciliation, GenJournalLine."Bal. Account No.", false);
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);
        BankAccountStatement.Get(BankAccReconciliation."Bank Account No.", BankAccReconciliation."Statement No.");
    end;

    local procedure CreateBankReconciliationWithGLAccount(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; GLAccNo: Code[20])
    begin
        LibraryERM.CreateBankAccReconciliation(
          BankAccReconciliation, CreateBankAccount, BankAccReconciliation."Statement Type"::"Payment Application");
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Account Type", BankAccReconciliationLine."Account Type"::"G/L Account");
        BankAccReconciliationLine.Validate("Account No.", GLAccNo);
        BankAccReconciliationLine.Validate("Statement Amount", LibraryRandom.RandDec(100, 2));
        BankAccReconciliationLine.Validate("Transaction Date", WorkDate);
        BankAccReconciliationLine.Validate(Description, GLAccNo);
        BankAccReconciliationLine.Modify(true);
        ApplyBankAccReconLineToGLAccount(BankAccReconciliationLine, GLAccNo, BankAccReconciliationLine."Statement Amount");
    end;

    local procedure CreateBankAccReconciliationLine(BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; VendorNo: Code[20]; Amount: Decimal; Date: Date)
    begin
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Account Type", BankAccReconciliationLine."Account Type"::Vendor);
        BankAccReconciliationLine.Validate("Account No.", VendorNo);
        BankAccReconciliationLine.Validate("Document No.", LibraryUtility.GenerateGUID);
        BankAccReconciliationLine.Validate("Statement Amount", Amount);
        BankAccReconciliationLine.Validate("Transaction Date", Date);
        BankAccReconciliationLine.Validate(Description, VendorNo);
        BankAccReconciliationLine.Modify(true);
    end;

    local procedure CreateApplyBankAccReconcilationLine(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; AccountType: Option; AccountNo: Code[20]; StatementAmount: Decimal; BankAccountNo: Code[20])
    begin
        LibraryERM.CreateBankAccReconciliation(
          BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Payment Application");
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Account Type", AccountType);
        BankAccReconciliationLine.Validate("Account No.", AccountNo);
        BankAccReconciliationLine.Validate("Document No.",
          LibraryUtility.GenerateRandomCode(BankAccReconciliationLine.FieldNo("Document No."), DATABASE::"Bank Acc. Reconciliation Line"));
        BankAccReconciliationLine.Validate("Statement Amount", StatementAmount);
        BankAccReconciliationLine.Validate("Dimension Set ID", CreateDimSet(BankAccReconciliationLine."Dimension Set ID"));
        BankAccReconciliationLine.Validate("Transaction Date", WorkDate);
        BankAccReconciliationLine.Validate(Description, AccountNo);
        BankAccReconciliationLine.Modify(true);
    end;

    local procedure CreateApplyBankReconWithDescription(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; AppliesEntryDescription: Text[50]; BankAccRecLineDescription: Text[50])
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CustomerNo: Code[20];
        StatementAmount: Decimal;
        CustLedgerEntryNo: Integer;
    begin
        CreateAndPostSalesInvoice(CustomerNo, CustLedgerEntryNo, StatementAmount);
        CreateApplyBankAccReconcilationLine(
          BankAccReconciliation, BankAccReconciliationLine,
          BankAccReconciliationLine."Account Type"::Customer,
          CustomerNo, StatementAmount, LibraryERM.CreateBankAccountNo);
        ApplyBankAccReconcilationLine(
          BankAccReconciliationLine, CustLedgerEntryNo,
          BankAccReconciliationLine."Account Type"::Customer, AppliesEntryDescription);
        UpdateBankAccReconciliationLineDescription(BankAccReconciliationLine, BankAccRecLineDescription);
    end;

    local procedure CreatePurchaseInvoice(Date: Date)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader.Validate("Posting Date", Date);
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateBankAccReconLineWithAmountTransferredToAcc(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccountNo: Code[20];
    begin
        BankAccountNo := CreateBankAccount;
        CreateBankReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Payment Application");
        CreateBankAccReconciliationLine(
          BankAccReconciliation, BankAccReconciliationLine, LibraryPurchase.CreateVendorNo, -LibraryRandom.RandDec(100, 2), WorkDate);
        BankAccReconciliationLine.TransferRemainingAmountToAccount;
        BankAccReconciliationLine.Find;
    end;

    local procedure MockBankAccReconLine(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; AccountType: Option)
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        LibraryERM.CreateBankAccReconciliation(
          BankAccReconciliation, LibraryERM.CreateBankAccountNo, BankAccReconciliation."Statement Type"::"Payment Application");
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Account Type", AccountType);
    end;

    local procedure MockAppliedPmtEntry(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; AppliesToEntryNo: Integer; NewDescription: Text[50])
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        with AppliedPaymentEntry do begin
            Init;
            TransferFromBankAccReconLine(BankAccReconciliationLine);
            "Applies-to Entry No." := AppliesToEntryNo;
            Description := NewDescription;
            Insert;
        end;
    end;

    local procedure MockBankAccLedgerEntry(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; BankAccountNo: Code[20]; IsReversed: Boolean)
    begin
        BankAccountLedgerEntry.Init;
        BankAccountLedgerEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(BankAccountLedgerEntry, BankAccountLedgerEntry.FieldNo("Entry No."));
        BankAccountLedgerEntry."Bank Account No." := BankAccountNo;
        BankAccountLedgerEntry."Remaining Amount" := LibraryRandom.RandDec(100, 2);
        BankAccountLedgerEntry."Statement Status" := BankAccountLedgerEntry."Statement Status"::Open;
        BankAccountLedgerEntry.Open := true;
        BankAccountLedgerEntry.Reversed := IsReversed;
        BankAccountLedgerEntry.Insert;
    end;

    local procedure CreateDimSet(DimSetID: Integer): Integer
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        exit(LibraryDimension.CreateDimSet(DimSetID, Dimension.Code, DimensionValue.Code));
    end;

    local procedure ApplyBankAccReconcilationLine(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; LedgerEntryNo: Integer; AccountType: Option; Description: Text[50]): Integer
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        AppliedPaymentEntry.Init;
        AppliedPaymentEntry.TransferFromBankAccReconLine(BankAccReconciliationLine);
        AppliedPaymentEntry.Validate("Account Type", AccountType);
        AppliedPaymentEntry.Validate("Account No.", BankAccReconciliationLine."Account No.");
        AppliedPaymentEntry.Validate("Applies-to Entry No.", LedgerEntryNo);
        AppliedPaymentEntry.Description := Description;
        AppliedPaymentEntry.Insert(true);
        BankAccReconciliationLine.Find;
        exit(BankAccReconciliationLine."Dimension Set ID");
    end;

    local procedure ApplyBankAccReconLineToGLAccount(var BankAccReconLine: Record "Bank Acc. Reconciliation Line"; AccountNo: Code[20]; StatementAmount: Decimal)
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        AppliedPaymentEntry.Init;
        AppliedPaymentEntry.TransferFromBankAccReconLine(BankAccReconLine);
        AppliedPaymentEntry.Validate("Account Type", AppliedPaymentEntry."Account Type"::"G/L Account");
        AppliedPaymentEntry.Validate("Account No.", AccountNo);
        AppliedPaymentEntry.Validate("Applied Amount", StatementAmount);
        AppliedPaymentEntry.Validate("Match Confidence", AppliedPaymentEntry."Match Confidence"::Manual);
        AppliedPaymentEntry.Insert(true);
        BankAccReconLine.Find;
    end;

    local procedure CreateSuggestedBankReconc(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; BankAccountNo: Code[20]; IncludeChecks: Boolean)
    begin
        CreateBankReconciliation(BankAccReconciliation, BankAccountNo, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        SuggestBankRecLines(BankAccReconciliation, IncludeChecks);

        // Balance Bank Account Reconciliation.
        BankAccReconciliation.Validate("Statement Ending Balance",
          BankAccReconciliation."Balance Last Statement" + BankAccRecSum(BankAccReconciliation));
        BankAccReconciliation.Modify(true);
    end;

    local procedure UpdateGeneralShortcutDimensionSetup()
    var
        DimensionValue: Record "Dimension Value";
        i: Integer;
    begin
        for i := 1 to 8 do begin
            LibraryDimension.CreateDimWithDimValue(DimensionValue);
            LibraryERM.SetShortcutDimensionCode(i, DimensionValue."Dimension Code");
        end;
    end;

    local procedure UpdateBankAccReconciliationLineDescription(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; Description: Text[50])
    begin
        BankAccReconciliationLine.Validate(Description, Description);
        BankAccReconciliationLine.Modify(true);
    end;

    local procedure GetDimensionValueCodeFromSetEntry(DimensionSetID: Integer; ShortcutDimensionCode: Code[20]): Code[20]
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Code", ShortcutDimensionCode);
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, DimensionSetID);
        exit(DimensionSetEntry."Dimension Value Code");
    end;

    local procedure GetStatementAmountFromBankAccRecon(BankAccountNo: Code[20]): Decimal
    var
        PostedPaymentReconLine: Record "Posted Payment Recon. Line";
    begin
        PostedPaymentReconLine.SetRange("Bank Account No.", BankAccountNo);
        PostedPaymentReconLine.FindFirst;
        exit(PostedPaymentReconLine."Statement Amount");
    end;

    local procedure BankAccRecSum(BankAccReconciliation: Record "Bank Acc. Reconciliation"): Decimal
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        with BankAccReconciliationLine do begin
            FilterBankRecLines(BankAccReconciliation);
            CalcSums("Statement Amount");
            exit("Statement Amount");
        end;
    end;

    local procedure MatchBankReconLineManually(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
    begin
        PaymentReconciliationJournal.OpenEdit;
        PaymentReconciliationJournal.GotoRecord(BankAccReconciliationLine);
        PaymentReconciliationJournal.ApplyEntries.Invoke;
    end;

    local procedure SuggestBankRecLines(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; IncludeChecks: Boolean)
    var
        BankAccount: Record "Bank Account";
        SuggestBankAccReconLines: Report "Suggest Bank Acc. Recon. Lines";
    begin
        SuggestBankAccReconLines.SetStmt(BankAccReconciliation);
        SuggestBankAccReconLines.SetTableView(BankAccount);
        SuggestBankAccReconLines.InitializeRequest(WorkDate, WorkDate, IncludeChecks);
        SuggestBankAccReconLines.UseRequestPage(false);
        SuggestBankAccReconLines.Run;
    end;

    local procedure SuggestAndVerifyBankReconcLine(BankAccount: Record "Bank Account"; DocumentNo: Code[20]; Type: Option; IncludeChecks: Boolean)
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        // Exercise: Suggest lines on Bank Account Reconciliation.
        CreateSuggestedBankReconc(BankAccReconciliation, BankAccount."No.", IncludeChecks);

        // Verify: Verify Check No., type on Bank Account Reconciliation Line.
        BankAccount.CalcFields(Balance);
        VerifyBankAccReconcLine(BankAccount."No.", Type, DocumentNo, BankAccount.Balance);
    end;

    local procedure SetupBankAccReconciliation(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
        CreateBankReconciliation(BankAccReconciliation, CreateBankAccount, BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        CreateBankAccReconLine(BankAccReconciliationLine, BankAccReconciliation);
    end;

    local procedure CreateBankAccReconLine(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; BankAccReconciliation: Record "Bank Acc. Reconciliation")
    begin
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Transaction Date", WorkDate);
        BankAccReconciliationLine.Validate("Document No.",
          LibraryUtility.GenerateRandomCode(BankAccReconciliationLine.FieldNo("Document No."), DATABASE::"Bank Acc. Reconciliation Line"));
        BankAccReconciliationLine.Validate("Statement Amount", LibraryRandom.RandDec(1000, 2));
        BankAccReconciliationLine.Validate(Description, BankAccReconciliationLine."Document No."); // required for APAC
        BankAccReconciliationLine.Modify(true);
    end;

    local procedure TransferToGenJnlReport(BankAccReconciliation: Record "Bank Acc. Reconciliation"; GenJournalBatch: Record "Gen. Journal Batch")
    var
        TransBankRecToGenJnl: Report "Trans. Bank Rec. to Gen. Jnl.";
    begin
        TransBankRecToGenJnl.SetBankAccRecon(BankAccReconciliation);
        TransBankRecToGenJnl.InitializeRequest(GenJournalBatch."Journal Template Name", GenJournalBatch.Name);
        TransBankRecToGenJnl.UseRequestPage := false;
        TransBankRecToGenJnl.Run;
    end;

    local procedure InitLastStatementNo(var BankAccount: Record "Bank Account"; NewLastStatementNo: Code[20])
    begin
        BankAccount."Last Statement No." := NewLastStatementNo;
        BankAccount.Modify;
    end;

    local procedure SetupGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; BalAccountType: Option; BankAccountNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account Type", BalAccountType);
        GenJournalBatch.Validate("Bal. Account No.", BankAccountNo);
        GenJournalBatch.Modify(true);
    end;

    local procedure VerifyReversedBankLedgerEntry(BankAccountNo: Code[20]; DocumentNo: Code[20]; Amount: Decimal)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get;
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.SetRange("Document No.", DocumentNo);
        BankAccountLedgerEntry.SetRange(Reversed, true);
        BankAccountLedgerEntry.SetFilter("Reversed Entry No.", '<>0');
        BankAccountLedgerEntry.FindFirst;
        Assert.AreNearlyEqual(
          Amount, BankAccountLedgerEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(WrongAmountErr, BankAccountLedgerEntry.Amount, Amount));
    end;

    local procedure VerifyBankRecLedgerEntry(AccountNo: Code[20]; DocumentNo: Code[20])
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        with BankAccountLedgerEntry do begin
            SetRange("Bank Account No.", AccountNo);
            SetRange("Document No.", DocumentNo);
            FindSet;

            repeat
                Assert.IsFalse(Open, 'Bank ledger entry did not close:');
            until Next = 0;
        end;
    end;

    local procedure VerifyBankAccReconcLine(BankAccountNo: Code[20]; Type: Option; DocumentNo: Code[20]; Amount: Decimal)
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccountNo);
        BankAccReconciliationLine.FindFirst;
        BankAccReconciliationLine.TestField(Type, Type);
        BankAccReconciliationLine.TestField("Document No.", DocumentNo);
        BankAccReconciliationLine.TestField("Statement Amount", Amount);
        BankAccReconciliationLine.TestField("Applied Amount", Amount);
    end;

    local procedure VerifyBankAccountLastStatementFields(BankAccountNo: Code[20]; LastPaymentStatementNo: Code[20]; LastStatementNo: Code[20]; BalanceLastStatement: Decimal)
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(BankAccountNo);
        BankAccount.TestField("Last Payment Statement No.", LastPaymentStatementNo);
        BankAccount.TestField("Last Statement No.", LastStatementNo);
        BankAccount.TestField("Balance Last Statement", BalanceLastStatement);
    end;

    local procedure VerifyCustLedgerEntry(CustomerNo: Code[20]; DocumentNo: Code[20]; DimSetID: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst;
        CustLedgerEntry.TestField("Dimension Set ID", DimSetID);
    end;

    local procedure VerifyVendLedgerEntry(VendorNo: Code[20]; DocumentNo: Code[20]; DimSetID: Integer)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst;
        VendorLedgerEntry.TestField("Dimension Set ID", DimSetID);
    end;

    local procedure VerifyDimSetEntryValue(DimSetID: Integer; DimValueCode: Code[20])
    var
        DummyDimensionSetEntry: Record "Dimension Set Entry";
    begin
        DummyDimensionSetEntry.SetRange("Dimension Set ID", DimSetID);
        DummyDimensionSetEntry.SetRange("Dimension Value Code", DimValueCode);
        DummyDimensionSetEntry.FindFirst;
        Assert.RecordIsNotEmpty(DummyDimensionSetEntry);
    end;

    local procedure VerifyGlobalDimensionCodeAndSetInGLEntry(GLAccNo: Code[20]; ExpectedGlobal1DimensionCode: Code[20]; ExpectedDimSetID: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        GLEntry.FindFirst;
        GLEntry.TestField("Global Dimension 1 Code", ExpectedGlobal1DimensionCode);
        GLEntry.TestField("Dimension Set ID", ExpectedDimSetID);
    end;

    local procedure VerifyGenJournalLine(GenJournalTemplateNo: Code[50]; GenJournalBatchNo: Code[50]; ExpectedAmount: Decimal; BalAccountType: Option; BAlAccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalTemplateNo);
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatchNo);
        GenJournalLine.FindFirst;
        GenJournalLine.TestField("Bal. Account Type", BalAccountType);
        GenJournalLine.TestField("Bal. Account No.", BAlAccountNo);
        GenJournalLine.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyGLEntryAmount(DocNo: Code[20]; AccNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Payment);
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("G/L Account No.", AccNo);
        GLEntry.FindFirst;
        GLEntry.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyGLEntryWithDescriptionExists(LastEntryNo: Integer; Description: Text[50])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetFilter("Entry No.", '>%1', LastEntryNo);
        GLEntry.SetRange(Description, Description);
        Assert.RecordIsNotEmpty(GLEntry);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Handler for confirmation messages, always send positive reply.
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageWithVerificationHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText, Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DeleteStatementConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        Confirm: Variant;
    begin
        LibraryVariableStorage.Dequeue(Confirm);

        Assert.IsTrue(StrPos(Question, HasBankEntriesMsg) > 0, 'Unexpected message.');
        Reply := Confirm;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GenJnlPageHandler(var GeneralJournal: TestPage "General Journal")
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TransToDiffAccModalPageHandler(var TransferDifferencetoAccount: TestPage "Transfer Difference to Account")
    begin
        TransferDifferencetoAccount."Account No.".SetValue(LibraryVariableStorage.DequeueText);
        TransferDifferencetoAccount.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankAccReconTestRequestPageHandler(var BankAccReconTest: TestRequestPage "Bank Acc. Recon. - Test")
    begin
        // Close handler
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentApplicationModalPageHandler(var PaymentApplication: TestPage "Payment Application")
    begin
        PaymentApplication.FILTER.SetFilter("Account No.", LibraryVariableStorage.DequeueText);
        PaymentApplication.FILTER.SetFilter("Document No.", LibraryVariableStorage.DequeueText);
        PaymentApplication.Applied.SetValue(true);
        PaymentApplication.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentApplicationWithReducedAmtModalPageHandler(var PaymentApplication: TestPage "Payment Application")
    begin
        PaymentApplication.FILTER.SetFilter("Account No.", LibraryVariableStorage.DequeueText);
        PaymentApplication.AppliedAmount.SetValue(LibraryVariableStorage.DequeueDecimal);
        PaymentApplication.Accept.Invoke;
    end;
}

