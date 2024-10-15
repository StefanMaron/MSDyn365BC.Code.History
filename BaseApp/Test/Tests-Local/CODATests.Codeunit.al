codeunit 144006 "CODA Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [CODA]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryCODAHelper: Codeunit "Library - CODA Helper";
        LibraryUtility: Codeunit "Library - Utility";
        IncorrectAccountNoErr: Label '%1 is incorrect in %2';
        LibraryERM: Codeunit "Library - ERM";
        LibraryBEHelper: Codeunit "Library - BE Helper";
        LibraryRandom: Codeunit "Library - Random";
        IncorrectNoOfRecordsErr: Label 'The expected number of records were not found.';
        AppliedToIdNotResetErr: Label 'The Applies-to ID field is not reset.';
        AmountToApplyNotResetErr: Label 'The Amount To Apply field is not reset.';
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SearchCustForCODAStatementLine()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        TransactionCoding: Record "Transaction Coding";
    begin
        // [SCENARIO 291527] Search Customer by Bank Account No. for CODA Statement Line
        Initialize();

        // [GIVEN] Customer "Cust" with "Bank Account No." = '123456789'
        // [GIVEN] CODA Statement line has "Bank Account No. Other Party" = '123456789'
        LibraryCODAHelper.CreateCustomerBankAccount(CustomerBankAccount);

        // [WHEN] Process CODA Bank Statement Line
        // [THEN] CODA Statement Lines matches to the Customer "Cust"
        ProcessCODABankStmtLine(
          CustomerBankAccount."Customer No.", CustomerBankAccount."Bank Account No.", TransactionCoding."Account Type"::Customer);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SearchVendForCODAStatementLine()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        TransactionCoding: Record "Transaction Coding";
    begin
        // [SCENARIO 291527] Search Vendor by Bank Account No. for CODA Statement Line
        Initialize();

        // [GIVEN] Vendor "Vend" has Bank Account with "Bank Account No." = '123456789'
        // [GIVEN] CODA Statement line has "Bank Account No. Other Party" = '123456789'
        LibraryCODAHelper.CreateVendorBankAccount(VendorBankAccount);

        // [WHEN] Process CODA Bank Statement Line
        // [THEN] CODA Statement Lines matches to the Vendor "Vend"
        ProcessCODABankStmtLine(
          VendorBankAccount."Vendor No.", VendorBankAccount."Bank Account No.", TransactionCoding."Account Type"::Vendor);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SearchCustIBANForCODAStatementLine()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        TransactionCoding: Record "Transaction Coding";
    begin
        // [SCENARIO 291527] Search Customer by IBAN for CODA Statement Line
        Initialize();

        // [GIVEN] Customer "Cust" has Bank Account with IBAN = 'BE0123456789'
        // [GIVEN] CODA Statement line has "Bank Account No. Other Party" = 'BE0123456789'
        LibraryCODAHelper.CreateCustomerBankAccount(CustomerBankAccount);

        // [WHEN] Process CODA Bank Statement Line
        // [THEN] CODA Statement Lines matches to the Customer "Cust"
        ProcessCODABankStmtLine(
          CustomerBankAccount."Customer No.", CustomerBankAccount.IBAN, TransactionCoding."Account Type"::Customer);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SearchVendIBANForCODAStatementLine()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        TransactionCoding: Record "Transaction Coding";
    begin
        // [SCENARIO 291527] Search Vendor by IBAN for CODA Statement Line
        Initialize();

        // [GIVEN] Vendor "Vend" has Bank Account with IBAN = 'BE0123456789'
        // [GIVEN] CODA Statement line has "Bank Account No. Other Party" = 'BE0123456789'
        LibraryCODAHelper.CreateVendorBankAccount(VendorBankAccount);

        // [WHEN] Process CODA Bank Statement Line
        // [THEN] CODA Statement Lines matches to the Vendor "Vend"
        ProcessCODABankStmtLine(
          VendorBankAccount."Vendor No.", VendorBankAccount.IBAN, TransactionCoding."Account Type"::Vendor);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SearchCustIBANPriorityForCODAStatementLine()
    var
        CustomerBankAccount1: Record "Customer Bank Account";
        CustomerBankAccount2: Record "Customer Bank Account";
        TransactionCoding: Record "Transaction Coding";
        BankAccOtherParty: Text[20];
    begin
        // [SCENARIO 291527] Search Customer by IBAN first for CODA Statement Line
        Initialize();

        // [GIVEN] Customer "Cust1" has Bank Account with "Bank Account No." = '1110123456789'
        // [GIVEN] Customer "Cust2" has Bank Account with IBAN = '1110123456789'
        // [GIVEN] CODA Statement line has "Bank Account No. Other Party" = '1110123456789'
        BankAccOtherParty := Format(LibraryRandom.RandIntInRange(10000000, 99999999));
        LibraryCODAHelper.CreateCustomerBankAccount(CustomerBankAccount1);
        CustomerBankAccount1."Bank Account No." := BankAccOtherParty;
        CustomerBankAccount1.Modify();
        LibraryCODAHelper.CreateCustomerBankAccount(CustomerBankAccount2);
        CustomerBankAccount2.IBAN := BankAccOtherParty;
        CustomerBankAccount2.Modify();

        // [WHEN] Process CODA Bank Statement Line
        // [THEN] CODA Statement Lines matches to the Customer "Cust2"
        ProcessCODABankStmtLine(
          CustomerBankAccount2."Customer No.", BankAccOtherParty, TransactionCoding."Account Type"::Customer);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SearchVendIBANPriorityForCODAStatementLine()
    var
        VendorBankAccount1: Record "Vendor Bank Account";
        VendorBankAccount2: Record "Vendor Bank Account";
        TransactionCoding: Record "Transaction Coding";
        BankAccOtherParty: Text[20];
    begin
        // [SCENARIO 291527] Search Vendor by IBAN first for CODA Statement Line
        Initialize();

        // [GIVEN] Vendor "Vend1" has Bank Account with "Bank Account No." = '2220123456789'
        // [GIVEN] Vendor "Vend2" has Bank Account with IBAN = '2220123456789'
        // [GIVEN] CODA Statement line has "Bank Account No. Other Party" = '2220123456789'
        BankAccOtherParty := Format(LibraryRandom.RandIntInRange(10000000, 99999999));
        LibraryCODAHelper.CreateVendorBankAccount(VendorBankAccount1);
        VendorBankAccount1."Bank Account No." := BankAccOtherParty;
        VendorBankAccount1.Modify();
        LibraryCODAHelper.CreateVendorBankAccount(VendorBankAccount2);
        VendorBankAccount2.IBAN := BankAccOtherParty;
        VendorBankAccount2.Modify();

        // [WHEN] Process CODA Bank Statement Line
        // [THEN] CODA Statement Lines matches to the Vendor "Vend2"
        ProcessCODABankStmtLine(
          VendorBankAccount2."Vendor No.", BankAccOtherParty, TransactionCoding."Account Type"::Vendor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenamingBankAccountNoIsNotAllowed()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        TransactionCoding: Record "Transaction Coding";
        CODAStatementLine: Record "CODA Statement Line";
        BankAccount: Record "Bank Account";
    begin
        Initialize();

        LibraryCODAHelper.CreateVendorBankAccount(VendorBankAccount);
        CreateCODAStatementLine(CODAStatementLine, VendorBankAccount."Bank Account No.", TransactionCoding."Account Type"::Vendor);

        BankAccount.FindLast();
        asserterror CODAStatementLine.Rename(BankAccount."No.", CODAStatementLine."Statement No.", CODAStatementLine."Statement Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangingAccountTypeFromVendToCustResetsCustLedgerEntry()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        TransactionCoding: Record "Transaction Coding";
        CODAStatementLine: Record "CODA Statement Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Setup
        Initialize();

        // 1. Create a Customer and a CustomerBankAccount.
        LibraryCODAHelper.CreateCustomerBankAccount(CustomerBankAccount);

        // 2. Create a CustomerLedgerEntry for the above created Customer.
        CreateCustLedgerEntry(CustLedgerEntry, CustomerBankAccount."Customer No.", true);

        // 3. Create a CODAStatementLine for the BankAccount that was created earlier and set the account type to Vendor
        // simulating a mistaken entry
        CreateCODAStatementLine(CODAStatementLine, CustomerBankAccount."Bank Account No.", TransactionCoding."Account Type"::Vendor);
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::Vendor;
        CODAStatementLine."Account No." := CustomerBankAccount."Customer No.";
        CODAStatementLine."Applies-to ID" := CustLedgerEntry."Applies-to ID";
        CODAStatementLine.Modify();

        // Excercise : Change the Acount Type to CustomerAccount
        CODAStatementLine.Validate("Account Type", CODAStatementLine."Account Type"::Customer);

        // Validation
        CustLedgerEntry.Reset();
        CustLedgerEntry.SetRange("Customer No.", CustomerBankAccount."Customer No.");
        CustLedgerEntry.FindFirst();
        Assert.AreEqual(1, CustLedgerEntry.Count, IncorrectNoOfRecordsErr);
        Assert.AreEqual('', CustLedgerEntry."Applies-to ID", AppliedToIdNotResetErr);
        Assert.AreEqual(0, CustLedgerEntry."Amount to Apply", AmountToApplyNotResetErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangingAccountTypeFromCustToVendResetsVendLedgerEntry()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        TransactionCoding: Record "Transaction Coding";
        CODAStatementLine: Record "CODA Statement Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Setup
        Initialize();

        // 1. Create a Vendor and a CustomerBankAccount.
        LibraryCODAHelper.CreateVendorBankAccount(VendorBankAccount);

        // 2. Create a VendorLedgerEntry for the above created Customer.
        CreateVendLedgerEntry(VendLedgerEntry, VendorBankAccount."Vendor No.", true);

        // 3. Create a CODAStatementLine for the BankAccount that was created earlier and set the account type to Customer
        // simulating a mistaken entry
        CreateCODAStatementLine(CODAStatementLine, VendorBankAccount."Bank Account No.", TransactionCoding."Account Type"::Customer);
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::Customer;
        CODAStatementLine."Account No." := VendorBankAccount."Vendor No.";
        CODAStatementLine."Applies-to ID" := VendLedgerEntry."Applies-to ID";
        CODAStatementLine.Modify();

        // Excercise : Change the Account Type to VendorAccount
        CODAStatementLine.Validate("Account Type", CODAStatementLine."Account Type"::Vendor);

        // Validation
        VendLedgerEntry.Reset();
        VendLedgerEntry.SetRange("Vendor No.", VendorBankAccount."Vendor No.");
        VendLedgerEntry.FindFirst();
        Assert.AreEqual(1, VendLedgerEntry.Count, IncorrectNoOfRecordsErr);
        Assert.AreEqual('', VendLedgerEntry."Applies-to ID", AppliedToIdNotResetErr);
        Assert.AreEqual(0, VendLedgerEntry."Amount to Apply", AmountToApplyNotResetErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotChangeAccountNoOnAppliedCODAStatementLine()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        TransactionCoding: Record "Transaction Coding";
        CODAStatementLine: Record "CODA Statement Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Setup
        Initialize();

        // 1. Create a Vendor and a CustomerBankAccount.
        LibraryCODAHelper.CreateVendorBankAccount(VendorBankAccount);

        // 2. Create a VendorLedgerEntry for the above created Customer.
        CreateVendLedgerEntry(VendLedgerEntry, VendorBankAccount."Vendor No.", true);

        // 3. Create a CODAStatementLine for the BankAccount that was created earlier and set the account type to Customer
        // simulating a mistaken entry
        CreateCODAStatementLine(CODAStatementLine, VendorBankAccount."Bank Account No.", TransactionCoding."Account Type"::Customer);
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::Vendor;
        CODAStatementLine."Applies-to ID" := VendLedgerEntry."Applies-to ID";
        CODAStatementLine."System-Created Entry" := true;
        CODAStatementLine."Application Status" := CODAStatementLine."Application Status"::Applied;
        CODAStatementLine.Modify();

        // Excercise & Validation : Change the Account Type to VendorAccount
        asserterror CODAStatementLine.Validate("Account No.", VendorBankAccount."Vendor No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatingAccountNoTriggerUpdateOfAccountNameVendor()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        TransactionCoding: Record "Transaction Coding";
        CODAStatementLine: Record "CODA Statement Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
    begin
        // Setup
        Initialize();

        // 1. Create a Vendor and a VendorBankAccount.
        LibraryCODAHelper.CreateVendorBankAccount(VendorBankAccount);

        // 2. Create a VendorLedgerEntry for the above created Customer.
        CreateVendLedgerEntry(VendLedgerEntry, VendorBankAccount."Vendor No.", false);

        // 3. Create a CODAStatementLine for the BankAccount that was created earlier and set the account type to Vendor
        CreateCODAStatementLine(CODAStatementLine, VendorBankAccount."Bank Account No.", TransactionCoding."Account Type"::Vendor);
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::Vendor;
        CODAStatementLine."Applies-to ID" := VendLedgerEntry."Applies-to ID";
        CODAStatementLine."System-Created Entry" := false;
        CODAStatementLine."Application Status" := CODAStatementLine."Application Status"::" ";
        CODAStatementLine.Modify();

        // Excercise & Validation : Change the Account No. to VendorAccount and ensure
        // Account Name field contains Vendor Name.
        CODAStatementLine.Validate("Account No.", VendorBankAccount."Vendor No.");
        Vendor.Get(VendorBankAccount."Vendor No.");

        Assert.AreEqual(Vendor.Name, CODAStatementLine."Account Name", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatingAccountNoTriggerUpdateOfAccountNameCustomer()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        TransactionCoding: Record "Transaction Coding";
        CODAStatementLine: Record "CODA Statement Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
    begin
        // Setup
        Initialize();

        // 1. Create a Customer and a CustomerBankAccount.
        LibraryCODAHelper.CreateCustomerBankAccount(CustomerBankAccount);

        // 2. Create a CustomerLedgerEntry for the above created Customer.
        CreateCustLedgerEntry(CustLedgerEntry, CustomerBankAccount."Customer No.", false);

        // 3. Create a CODAStatementLine for the BankAccount that was created earlier and set the account type to Customer
        CreateCODAStatementLine(CODAStatementLine, CustomerBankAccount."Bank Account No.", TransactionCoding."Account Type"::Customer);
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::Customer;
        CODAStatementLine."Applies-to ID" := CustLedgerEntry."Applies-to ID";
        CODAStatementLine."System-Created Entry" := false;
        CODAStatementLine.Type := CODAStatementLine.Type::Detail;
        CODAStatementLine."Application Status" := CODAStatementLine."Application Status"::" ";
        CODAStatementLine.Modify();

        // Excercise & Validation : Change the Account No. to VendorAccount and ensure
        // Account Name field contains Vendor Name.
        CODAStatementLine.Validate("Account No.", CustomerBankAccount."Customer No.");
        Customer.SetRange("No.", CustomerBankAccount."Customer No.");
        Customer.FindFirst();

        Assert.AreEqual(Customer.Name, CODAStatementLine."Account Name", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplicationStatus()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        TransactionCoding: Record "Transaction Coding";
        CODAStatementLine: Record "CODA Statement Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Setup
        Initialize();

        LibraryCODAHelper.CreateCustomerBankAccount(CustomerBankAccount);
        CreateCustLedgerEntry(CustLedgerEntry, CustomerBankAccount."Customer No.", true);
        CreateCODAStatementLine(CODAStatementLine, CustomerBankAccount."Bank Account No.", TransactionCoding."Account Type"::Vendor);

        // Execution
        CODAStatementLine."Account Type" := CODAStatementLine."Account Type"::Customer;
        CODAStatementLine.Validate("Account No.", CustomerBankAccount."Customer No.");
        CODAStatementLine.Modify();

        // Validation
        Assert.AreEqual(CODAStatementLine."Application Status"::"Partly applied", CODAStatementLine."Application Status", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyCODAStatementTriggers()
    var
        CODAStatement: Record "CODA Statement";
        BankAccount: Record "Bank Account";
        ExpectedStatement: Code[10];
    begin
        // Ensure the the table triggers are tested.
        BankAccount.SetFilter("Payment Export Format", '<>%1', '');
        BankAccount.FindFirst();
        CODAStatement.Init();
        CODAStatement.Validate("Bank Account No.", BankAccount."No.");
        if CODAStatement."Statement No." = '' then
            CODAStatement."Statement No." := '1';

        if BankAccount."Last Statement No." = '' then
            ExpectedStatement := '1'
        else
            ExpectedStatement := IncStr(BankAccount."Last Statement No.");

        CODAStatement.Insert(true);

        Assert.AreEqual(ExpectedStatement, CODAStatement."Statement No.", 'Statement No.');

        asserterror CODAStatement.Rename('WWB-EUR-A', '2');
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyCODAStatementLinesApplicationIsSaved()
    var
        CODAStatementLine: Record "CODA Statement Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CODAWriteStatements: Codeunit "CODA Write Statements";
    begin
        // [FEATURE] [UT] [UI] [Apply] [Applies-to]
        // [SCENARIO 287687] When Stan applies Customer Ledger Entry to a CODA Statement Line, "Applies-to ID" field is updated for CODA Statement Line.
        Initialize();

        CreateCustLedgerEntry(CustLedgerEntry, LibrarySales.CreateCustomerNo(), false);

        with CODAStatementLine do begin
            Init();
            "Statement No." := LibraryUtility.GenerateGUID();
            "Statement Line No." := LibraryRandom.RandInt(100);
            "Posting Date" := WorkDate();
            "Document No." := LibraryUtility.GenerateGUID();
            "Account Type" := "Account Type"::Customer;
            "Account No." := CustLedgerEntry."Customer No.";
            Insert();
            TestField("Applies-to ID", '');
        end;

        CODAWriteStatements.Apply(CODAStatementLine);

        CODAStatementLine.Find();
        CODAStatementLine.TestField("Applies-to ID", CODAStatementLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyCODAStatementLineDidNotChangedAmountsWhenPartlyApplied()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        TransactionCoding: Record "Transaction Coding";
        CODAStatementLine: Record "CODA Statement Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Apply] [Applies-to]
        // [SCENARIO 363395] Create a CODAStatementLine and validate Account No. with created Vendor
        Initialize();

        // [GIVEN] Create a Vendor and a VendorBankAccount
        LibraryCODAHelper.CreateVendorBankAccount(VendorBankAccount);

        // [GIVEN] Create a VendorLedgerEntry for the above created Vendor with Amount = "Amt"
        CreateVendLedgerEntry(VendLedgerEntry, VendorBankAccount."Vendor No.", false);

        // [GIVEN] Create a CODAStatementLine for the BankAccount that was created earlier
        // [GIVEN] Set the account type to Vendor and "Statement Amount" = "Amt"
        CreateCODAStatementLineWithStatementLineNo(
          CODAStatementLine, VendorBankAccount."Bank Account No.", TransactionCoding."Account Type"::Vendor);
        UpdateCODAStatementLine(
          CODAStatementLine, WorkDate(), CODAStatementLine."Account Type"::Vendor,
          VendLedgerEntry.Amount, CODAStatementLine."Application Status"::" ", LibraryUtility.GenerateGUID());

        // [WHEN] Change the Account No. to VendorAccount and ensure
        CODAStatementLine.Validate("Account No.", VendorBankAccount."Vendor No.");

        // [THEN] "Statement Amount" = "Amt"
        // [THEN] Amount = 0
        // [THEN] "Application Status" is changed to "Partly applied"
        // [THEN] "Unapplied Amount" = "Amt"
        VerifyCODAStatementLineApplicationInfo(
          CODAStatementLine, VendLedgerEntry.Amount, 0, CODAStatementLine."Application Status"::"Partly applied", VendLedgerEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyCODAStatementLineChangedAmountsCorrectlyWhenApplied()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        TransactionCoding: Record "Transaction Coding";
        CODAStatementLine: Record "CODA Statement Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        CODAWriteStatements: Codeunit "CODA Write Statements";
    begin
        // [FEATURE] [Apply] [Applies-to]
        // [SCENARIO 363395] Create a CODAStatementLine and validate Account No. with created Vendor, then apply entry
        Initialize();

        // [GIVEN] Create a Vendor and a VendorBankAccount
        LibraryCODAHelper.CreateVendorBankAccount(VendorBankAccount);

        // [GIVEN] Create a VendorLedgerEntry for the above created Vendor with Amount = "Amt"
        CreateVendLedgerEntry(VendLedgerEntry, VendorBankAccount."Vendor No.", false);

        // [GIVEN] Create a CODAStatementLine for the BankAccount that was created earlier
        // [GIVEN] Set the account type to Vendor and "Statement Amount" = "Amt"
        CreateCODAStatementLineWithStatementLineNo(
          CODAStatementLine, VendorBankAccount."Bank Account No.", TransactionCoding."Account Type"::Vendor);
        UpdateCODAStatementLine(
          CODAStatementLine, WorkDate(), CODAStatementLine."Account Type"::Vendor,
          VendLedgerEntry.Amount, CODAStatementLine."Application Status"::" ", LibraryUtility.GenerateGUID());

        // [GIVEN] Change the Account No. to VendorAccount
        CODAStatementLine.Validate("Account No.", VendorBankAccount."Vendor No.");
        CODAStatementLine.Modify(true);

        // [WHEN] Apply entry
        LibraryVariableStorage.Enqueue(CODAStatementLine."Document No.");
        CODAWriteStatements.Apply(CODAStatementLine);

        // [THEN] "Applies-to ID" is validated
        // [THEN] Amount = "Amt"
        // [THEN] "Statement Amount" = "Amt"
        // [THEN] "Application Status" is changed to "Applied"
        // [THEN] "Unapplied Amount" = 0
        CODAStatementLine.Find();
        CODAStatementLine.TestField("Applies-to ID", CODAStatementLine."Document No.");
        // BUG 368200: Statement amount must remains unchanged
        VerifyCODAStatementLineApplicationInfo(
          CODAStatementLine, VendLedgerEntry.Amount, VendLedgerEntry.Amount, CODAStatementLine."Application Status"::Applied, 0);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyCODAStatementLineChangedAmountsCorrectlyWhenUnapplied()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        TransactionCoding: Record "Transaction Coding";
        CODAStatementLine: Record "CODA Statement Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        CODAWriteStatements: Codeunit "CODA Write Statements";
    begin
        // [FEATURE] [Apply] [Applies-to]
        // [SCENARIO 363395] Create a CODAStatementLine and validate Account No. with created Vendor, apply entry, then unapply entry
        Initialize();

        // [GIVEN] Create a Vendor and a VendorBankAccount
        LibraryCODAHelper.CreateVendorBankAccount(VendorBankAccount);

        // [GIVEN] Create a VendorLedgerEntry for the above created Vendor with Amount = "Amt"
        CreateVendLedgerEntry(VendLedgerEntry, VendorBankAccount."Vendor No.", false);

        // [GIVEN] Create a CODAStatementLine for the BankAccount that was created earlier
        // [GIVEN] Set the account type to Vendor and "Statement Amount" = "Amt"
        CreateCODAStatementLineWithStatementLineNo(
          CODAStatementLine, VendorBankAccount."Bank Account No.", TransactionCoding."Account Type"::Vendor);
        UpdateCODAStatementLine(
          CODAStatementLine, WorkDate(), CODAStatementLine."Account Type"::Vendor,
          VendLedgerEntry.Amount, CODAStatementLine."Application Status"::" ", LibraryUtility.GenerateGUID());

        // [GIVEN] Change the Account No. to VendorAccount
        CODAStatementLine.Validate("Account No.", VendorBankAccount."Vendor No.");
        CODAStatementLine.Modify(true);

        // [GIVEN] Apply entry
        LibraryVariableStorage.Enqueue(CODAStatementLine."Document No.");
        CODAWriteStatements.Apply(CODAStatementLine);

        // [WHEN] Unapply entry
        LibraryVariableStorage.Enqueue('');
        CODAWriteStatements.Apply(CODAStatementLine);

        // [THEN] "Applies-to ID" is not validated
        // [THEN] "Statement Amount" = "Amt"
        // [THEN] Amount = 0
        // [THEN] "Application Status" is changed to "Partly applied"
        // [THEN] "Unapplied Amount" = "Amt"
        CODAStatementLine.Find();
        CODAStatementLine.TestField("Applies-to ID", '');
        VerifyCODAStatementLineApplicationInfo(
          CODAStatementLine, VendLedgerEntry.Amount, 0, CODAStatementLine."Application Status"::"Partly applied", VendLedgerEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure CODAStatementLineChangeAmountsWhenAccountNoIsChanged()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        NewVendorBankAccount: Record "Vendor Bank Account";
        TransactionCoding: Record "Transaction Coding";
        CODAStatementLine: Record "CODA Statement Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        CODAWriteStatements: Codeunit "CODA Write Statements";
    begin
        // [FEATURE] [Apply] [Applies-to]
        // [SCENARIO 367180] Revalidation of Account No. with another Vendor restores the values of Unapplied Amount and Amount

        Initialize();

        // [GIVEN] Vendor "X"
        LibraryCODAHelper.CreateVendorBankAccount(VendorBankAccount);

        // [GIVEN] Create a VendorLedgerEntry for the above created Vendor with Amount = "Amt"
        CreateVendLedgerEntry(VendLedgerEntry, VendorBankAccount."Vendor No.", false);

        // [GIVEN] Create a CODAStatementLine for the BankAccount that was created earlier
        // [GIVEN] Set the account type to Vendor and "Statement Amount" = "Amt"
        CreateCODAStatementLineWithStatementLineNo(
          CODAStatementLine, VendorBankAccount."Bank Account No.", TransactionCoding."Account Type"::Vendor);
        UpdateCODAStatementLine(
          CODAStatementLine, WorkDate(), CODAStatementLine."Account Type"::Vendor,
          VendLedgerEntry.Amount, CODAStatementLine."Application Status"::" ", LibraryUtility.GenerateGUID());

        // [GIVEN] Account No. is "X"
        CODAStatementLine.Validate("Account No.", VendorBankAccount."Vendor No.");
        CODAStatementLine.Modify(true);

        // [GIVEN] Vendor Ledger entry applied to CODA Statement Line
        LibraryVariableStorage.Enqueue(CODAStatementLine."Document No.");
        CODAWriteStatements.Apply(CODAStatementLine);

        // [GIVEN] Vendor "Y"
        LibraryCODAHelper.CreateVendorBankAccount(NewVendorBankAccount);

        // [GIVEN] Account No. is "Y"
        CODAStatementLine.Find();
        CODAStatementLine.Validate("Account No.", NewVendorBankAccount."Vendor No.");

        // [THEN] "Statement Amount" = "Amt"
        // [THEN] Amount = 0
        // BUG 372224: The status of the line must be "Partly applied" when account no. gets changed
        // [THEN] "Application Status" is changed to "Partly applied"
        // [THEN] "Unapplied Amount" = "Amt"
        VerifyCODAStatementLineApplicationInfo(
          CODAStatementLine, VendLedgerEntry.Amount, 0, CODAStatementLine."Application Status"::"Partly applied", VendLedgerEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('CancelApplyVendorEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure CODAStatementLineDidNotChangedAmountsWhenApplicationWasCancelled()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        TransactionCoding: Record "Transaction Coding";
        CODAStatementLine: Record "CODA Statement Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        CODAWriteStatements: Codeunit "CODA Write Statements";
    begin
        // [FEATURE] [Apply] [Applies-to]
        // [SCENARIO 368531] No amounts changed when the application process of the CODA statement was cancelled

        Initialize();

        // [GIVEN] Create a Vendor and a VendorBankAccount
        LibraryCODAHelper.CreateVendorBankAccount(VendorBankAccount);

        // [GIVEN] Create a VendorLedgerEntry for the above created Vendor with Amount = "Amt"
        CreateVendLedgerEntry(VendLedgerEntry, VendorBankAccount."Vendor No.", false);

        // [GIVEN] Create a CODAStatementLine for the BankAccount that was created earlier
        // [GIVEN] Set the account type to Vendor and "Statement Amount" = "Amt"
        CreateCODAStatementLineWithStatementLineNo(
          CODAStatementLine, VendorBankAccount."Bank Account No.", TransactionCoding."Account Type"::Vendor);
        UpdateCODAStatementLine(
          CODAStatementLine, WorkDate(), CODAStatementLine."Account Type"::Vendor,
          VendLedgerEntry.Amount, CODAStatementLine."Application Status"::" ", LibraryUtility.GenerateGUID());

        // [GIVEN] Change the Account No. to VendorAccount
        CODAStatementLine.Validate("Account No.", VendorBankAccount."Vendor No.");
        CODAStatementLine.Modify(true);

        // [WHEN] Set applies-to id in the "Apply Entries" page and then press cancel
        LibraryVariableStorage.Enqueue(CODAStatementLine."Document No.");
        CODAWriteStatements.Apply(CODAStatementLine);

        // [THEN] "Statement Amount" = Amt
        // [THEN] "Application Status" is changed to "Partly applied"
        // [THEN] Amount = 0
        // [THEN] "Unapplied Amount" = Amt
        CODAStatementLine.Find();
        VerifyCODAStatementLineApplicationInfo(
          CODAStatementLine, VendLedgerEntry.Amount, 0, CODAStatementLine."Application Status"::"Partly applied", VendLedgerEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('SetAppliesToIDAndOkOrCancelVendorEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure CODAStatementLineChangeAmountsWhenAppliesToIDBlanksAndApplicationWasCancelled()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        TransactionCoding: Record "Transaction Coding";
        CODAStatementLine: Record "CODA Statement Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        CODAWriteStatements: Codeunit "CODA Write Statements";
    begin
        // [FEATURE] [Apply] [Applies-to]
        // [SCENARIO 373272] When the application process of the CODA statement was cancelled but applies-to id blanks it restores the values of Unapplied Amount and Amount

        Initialize();

        // [GIVEN] Create a Vendor and a VendorBankAccount
        LibraryCODAHelper.CreateVendorBankAccount(VendorBankAccount);

        // [GIVEN] Create a VendorLedgerEntry for the above created Vendor with Amount = "Amt"
        CreateVendLedgerEntry(VendLedgerEntry, VendorBankAccount."Vendor No.", false);

        // [GIVEN] Create a CODAStatementLine for the BankAccount that was created earlier
        // [GIVEN] Set the account type to Vendor and "Statement Amount" = "Amt"
        CreateCODAStatementLineWithStatementLineNo(
          CODAStatementLine, VendorBankAccount."Bank Account No.", TransactionCoding."Account Type"::Vendor);
        UpdateCODAStatementLine(
          CODAStatementLine, WorkDate(), CODAStatementLine."Account Type"::Vendor,
          VendLedgerEntry.Amount, CODAStatementLine."Application Status"::" ", LibraryUtility.GenerateGUID());

        // [GIVEN] Change the Account No. to VendorAccount
        CODAStatementLine.Validate("Account No.", VendorBankAccount."Vendor No.");
        CODAStatementLine.Modify(true);

        // [GIVEN] Application is made
        LibraryVariableStorage.Enqueue(CODAStatementLine."Document No.");
        LibraryVariableStorage.Enqueue(true);
        CODAWriteStatements.Apply(CODAStatementLine);

        // [WHEN] Set applies-to id to blank in the "Apply Entries" page and then press Cancel
        LibraryVariableStorage.Enqueue(CODAStatementLine."Document No.");
        LibraryVariableStorage.Enqueue(false);
        CODAWriteStatements.Apply(CODAStatementLine);

        // [THEN] "Statement Amount" = "Amt"
        // [THEN] Amount = 0
        // [THEN] "Application Status" is changed to "Partly applied"
        // [THEN] "Unapplied Amount" = "Amt"
        CODAStatementLine.Find();
        VerifyCODAStatementLineApplicationInfo(
          CODAStatementLine, VendLedgerEntry.Amount, 0, CODAStatementLine."Application Status"::"Partly applied", VendLedgerEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('SetAppliesToIDOkOrCancelVendorEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure CODAStatementLineDidNotChangedAmountsWhenApplicationWasCancelledAfterItWasCompleted()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        TransactionCoding: Record "Transaction Coding";
        CODAStatementLine: Record "CODA Statement Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        CODAWriteStatements: Codeunit "CODA Write Statements";
    begin
        // [FEATURE] [Apply] [Applies-to]
        // [SCENARIO 368531] No amounts changed when the application process of the CODA statement was cancelled after it was successfully completed

        Initialize();

        // [GIVEN] Create a Vendor and a VendorBankAccount
        LibraryCODAHelper.CreateVendorBankAccount(VendorBankAccount);

        // [GIVEN] Create a VendorLedgerEntry for the above created Vendor with Amount = "Amt"
        CreateVendLedgerEntry(VendLedgerEntry, VendorBankAccount."Vendor No.", false);

        // [GIVEN] Create a CODAStatementLine for the BankAccount that was created earlier
        // [GIVEN] Set the account type to Vendor and "Statement Amount" = "Amt"
        CreateCODAStatementLineWithStatementLineNo(
          CODAStatementLine, VendorBankAccount."Bank Account No.", TransactionCoding."Account Type"::Vendor);
        UpdateCODAStatementLine(
          CODAStatementLine, WorkDate(), CODAStatementLine."Account Type"::Vendor,
          VendLedgerEntry.Amount, CODAStatementLine."Application Status"::" ", LibraryUtility.GenerateGUID());

        // [GIVEN] Change the Account No. to VendorAccount
        CODAStatementLine.Validate("Account No.", VendorBankAccount."Vendor No.");
        CODAStatementLine.Modify(true);

        // [GIVEN] Application is made
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(CODAStatementLine."Document No.");
        CODAWriteStatements.Apply(CODAStatementLine);

        // [WHEN] Set applies-to id in the "Apply Entries" page and then press cancel
        LibraryVariableStorage.Enqueue(false);
        CODAWriteStatements.Apply(CODAStatementLine);

        // [THEN] "Statement Amount" = Amt
        // [THEN] "Application Status" is Applied
        // [THEN] Amount = Amt
        // [THEN] "Unapplied Amount" = 0
        CODAStatementLine.Find();
        VerifyCODAStatementLineApplicationInfo(
          CODAStatementLine, VendLedgerEntry.Amount, VendLedgerEntry.Amount, CODAStatementLine."Application Status"::Applied, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnappliedAmountEqualsStatementAmountForIndirectlyAppliedLine()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        TransactionCoding: Record "Transaction Coding";
        CODAStatementLine: Record "CODA Statement Line";
        RelatedCODAStatementLine: Record "CODA Statement Line";
    begin
        // [FEATURE] [Apply] [Applies-to] [UT]
        // [SCENARIO 375361] An "unapplied amount" equals the "statement amount for the indirectly applied statement line

        Initialize();

        // [GIVEN] CODA Statement line "X" has "Statement amount" = 100
        LibraryCODAHelper.CreateVendorBankAccount(VendorBankAccount);
        CreateCODAStatementLineWithStatementLineNo(
          CODAStatementLine, VendorBankAccount."Bank Account No.", TransactionCoding."Account Type"::Vendor);
        UpdateCODAStatementLine(
          CODAStatementLine, WorkDate(), CODAStatementLine."Account Type"::Vendor,
          LibraryRandom.RandDec(100, 2), CODAStatementLine."Application Status"::" ", LibraryUtility.GenerateGUID());

        // [GIVEN] CODA Statement line "Y" with "Attached to Line No." = "X" and "Statement amount" = 200
        RelatedCODAStatementLine := CODAStatementLine;
        RelatedCODAStatementLine."Attached to Line No." := CODAStatementLine."Statement Line No.";
        RelatedCODAStatementLine."Statement Line No." += 10000;
        RelatedCODAStatementLine."Statement Amount" += LibraryRandom.RandDec(100, 2);
        RelatedCODAStatementLine.Insert();

        // [GIVEN] Change the Account No. in the line "X"
        CODAStatementLine.Validate("Account No.", VendorBankAccount."Vendor No.");
        CODAStatementLine.Modify(true);

        // [THEN] The "application status" of the line "Y" is "Indirectly applied", the "Unapplied amount" = 200
        RelatedCODAStatementLine.Find();
        RelatedCODAStatementLine.TestField("Application Status", RelatedCODAStatementLine."Application Status"::"Indirectly applied");
        RelatedCODAStatementLine.TestField("Unapplied Amount", RelatedCODAStatementLine."Statement Amount");
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesModalPageHandler')]
    procedure ApplyOneOfTwoVendorLedgerEntries()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        VendorLedgerEntry: array[2] of Record "Vendor Ledger Entry";
        CODAStatementLine: Record "CODA Statement Line";
        TransactionCoding: Record "Transaction Coding";
        CODAWriteStatements: Codeunit "CODA Write Statements";
        TotalAmount: Decimal;
    begin
        // [FEATURE] [Apply] [Vendor]
        // [SCENARIO 405674] Apply one of two vendor ledger entries in CODA statement line leads to "Partly applied" line status
        Initialize();

        // [GIVEN] Two vendor ledger entries with amounts "X" and "Y"
        LibraryCODAHelper.CreateVendorBankAccount(VendorBankAccount);
        CreateVendLedgerEntry(VendorLedgerEntry[1], VendorBankAccount."Vendor No.", false);
        CreateVendLedgerEntry(VendorLedgerEntry[2], VendorBankAccount."Vendor No.", false);
        TotalAmount := VendorLedgerEntry[1].Amount + VendorLedgerEntry[2].Amount;

        // [GIVEN] CODA statement line with Statement Amount = "X" + "Y"
        CreateCODAStatementLineWithStatementLineNo(
          CODAStatementLine, VendorBankAccount."Bank Account No.", TransactionCoding."Account Type"::Vendor);
        UpdateCODAStatementLine(
          CODAStatementLine, WorkDate(), CODAStatementLine."Account Type"::Vendor, TotalAmount,
          CODAStatementLine."Application Status"::" ", LibraryUtility.GenerateGUID());
        CODAStatementLine.Validate("Account No.", VendorBankAccount."Vendor No.");
        CODAStatementLine.Modify(true);

        // [WHEN] Apply the line (set Applies-To ID) for the first vendor ledger entry with amount "X"
        LibraryVariableStorage.Enqueue(CODAStatementLine."Document No.");
        CODAWriteStatements.Apply(CODAStatementLine);

        // [THEN] Statement line Status = "Partly applied", "Amount" = "X", "Unapplied Amount" = "Y"
        CODAStatementLine.Find();
        VerifyCODAStatementLineApplicationInfo(
          CODAStatementLine, TotalAmount, VendorLedgerEntry[1].Amount,
          CODAStatementLine."Application Status"::"Partly applied", VendorLedgerEntry[2].Amount);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesModalPageHandler')]
    procedure ApplyOneOfTwoCustomerLedgerEntries()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        CustLedgerEntry: array[2] of Record "Cust. Ledger Entry";
        CODAStatementLine: Record "CODA Statement Line";
        TransactionCoding: Record "Transaction Coding";
        CODAWriteStatements: Codeunit "CODA Write Statements";
        TotalAmount: Decimal;
    begin
        // [FEATURE] [Apply] [Customer]
        // [SCENARIO 405674] Apply one of two customer ledger entries in CODA statement line leads to "Partly applied" line status
        Initialize();

        // [GIVEN] Two customer ledger entries with amounts "X" and "Y"
        LibraryCODAHelper.CreateCustomerBankAccount(CustomerBankAccount);
        CreateCustLedgerEntry(CustLedgerEntry[1], CustomerBankAccount."Customer No.", false);
        CreateCustLedgerEntry(CustLedgerEntry[2], CustomerBankAccount."Customer No.", false);
        TotalAmount := CustLedgerEntry[1].Amount + CustLedgerEntry[2].Amount;

        // [GIVEN] CODA statement line with Statement Amount = "X" + "Y"
        CreateCODAStatementLineWithStatementLineNo(
          CODAStatementLine, CustomerBankAccount."Bank Account No.", TransactionCoding."Account Type"::Customer);
        UpdateCODAStatementLine(
          CODAStatementLine, WorkDate(), CODAStatementLine."Account Type"::Customer, TotalAmount,
          CODAStatementLine."Application Status"::" ", LibraryUtility.GenerateGUID());
        CODAStatementLine.Validate("Account No.", CustomerBankAccount."Customer No.");
        CODAStatementLine.Modify(true);

        // [WHEN] Apply the line (set Applies-To ID) for the first customer ledger entry with amount "X"
        LibraryVariableStorage.Enqueue(CODAStatementLine."Document No.");
        CODAWriteStatements.Apply(CODAStatementLine);

        // [THEN] Statement line Status = "Partly applied", "Amount" = "X", "Unapplied Amount" = "Y"
        CODAStatementLine.Find();
        VerifyCODAStatementLineApplicationInfo(
          CODAStatementLine, TotalAmount, CustLedgerEntry[1].Amount,
          CODAStatementLine."Application Status"::"Partly applied", CustLedgerEntry[2].Amount);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"CODA Tests");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"CODA Tests");

        LibraryBEHelper.InitializeCompanyInformation();
        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"CODA Tests");
    end;

    [Normal]
    local procedure CreateVendLedgerEntry(var VendLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; SetupApply: Boolean)
    var
        LastEntryNo: Integer;
    begin
        VendLedgerEntry.FindLast();
        LastEntryNo := VendLedgerEntry."Entry No.";

        VendLedgerEntry.Init();
        VendLedgerEntry."Vendor No." := VendorNo;
        VendLedgerEntry."Document Type" := VendLedgerEntry."Document Type"::Invoice;
        VendLedgerEntry."Entry No." := LastEntryNo + 1;
        VendLedgerEntry.Open := true;

        MockDtldVendLedgerEntry(VendLedgerEntry."Entry No.");
        VendLedgerEntry.CalcFields(Amount);

        if SetupApply then begin
            VendLedgerEntry."Applies-to ID" := LibraryUtility.GenerateRandomCode(
                VendLedgerEntry.FieldNo("Applies-to ID"), Database::"Vendor Ledger Entry");
            VendLedgerEntry."Amount to Apply" := LibraryRandom.RandDecInRange(1, 100, 1);
        end;
        VendLedgerEntry.Insert();
    end;

    [Normal]
    local procedure CreateCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; SetupApply: Boolean)
    var
        LastEntryNo: Integer;
    begin
        CustLedgerEntry.FindLast();
        LastEntryNo := CustLedgerEntry."Entry No.";

        CustLedgerEntry.Init();
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Invoice;
        CustLedgerEntry."Entry No." := LastEntryNo + 1;
        CustLedgerEntry.Open := true;

        MockDtldCustLedgerEntry(CustLedgerEntry."Entry No.");
        CustLedgerEntry.CalcFields(Amount);

        if SetupApply then begin
            CustLedgerEntry."Applies-to ID" := LibraryUtility.GenerateRandomCode(
                CustLedgerEntry.FieldNo("Applies-to ID"), Database::"Cust. Ledger Entry");
            CustLedgerEntry."Amount to Apply" := LibraryRandom.RandDecInRange(1, 100, 1);
        end;
        CustLedgerEntry.Insert();
    end;

    local procedure CreateCODAStatementLine(var CODAStatementLine: Record "CODA Statement Line"; BankAccountNoOtherParty: Text[50]; AccountType: Option)
    var
        BankAccount: Record "Bank Account";
        TransactionCoding: Record "Transaction Coding";
        CODAStatement: Record "CODA Statement";
    begin
        LibraryERM.CreateBankAccount(BankAccount);

        CreateTransactionCoding(TransactionCoding, AccountType);
        CODAStatement.Init();
        CODAStatement."Bank Account No." := BankAccount."No.";
        CODAStatement."Statement No." := Format(LibraryRandom.RandInt(10));
        CODAStatement."Statement Date" := WorkDate();
        CODAStatement.Insert();
        with CODAStatementLine do begin
            "Bank Account No." := BankAccount."No.";
            "Statement No." := CODAStatement."Statement No.";
            "Transaction Family" := TransactionCoding."Transaction Family";
            Transaction := TransactionCoding.Transaction;
            "Transaction Category" := TransactionCoding."Transaction Category";
            "Bank Account No. Other Party" := CopyStr(BankAccountNoOtherParty, 1, MaxStrLen("Bank Account No. Other Party"));
            Insert();
        end;
    end;

    local procedure CreateTransactionCoding(var TransactionCoding: Record "Transaction Coding"; AccountType: Option)
    var
        LastTransactionCoding: Record "Transaction Coding";
    begin
        with TransactionCoding do begin
            if LastTransactionCoding.FindLast() then;
            "Transaction Family" := LastTransactionCoding."Transaction Family" + 1;
            Transaction := LastTransactionCoding.Transaction + 1;
            "Transaction Category" := LastTransactionCoding."Transaction Category" + 1;
            "Account Type" := AccountType;
            Insert();
        end;
    end;

    local procedure ProcessCODABankStmtLine(AccountNo: Code[20]; BankAccountNoOtherParty: Text[50]; AccountType: Option)
    var
        CODAStatementLine: Record "CODA Statement Line";
        PostCodedBankStatement: Codeunit "Post Coded Bank Statement";
    begin
        CreateCODAStatementLine(CODAStatementLine, BankAccountNoOtherParty, AccountType);

        PostCodedBankStatement.InitCodeunit(false, false);
        PostCodedBankStatement.ProcessCodBankStmtLine(CODAStatementLine);

        Assert.AreEqual(
          AccountNo, CODAStatementLine."Account No.",
          StrSubstNo(IncorrectAccountNoErr, CODAStatementLine.FieldCaption("Account No."), CODAStatementLine.TableName));
    end;

    local procedure CreateCODAStatementLineWithStatementLineNo(var CODAStatementLine: Record "CODA Statement Line"; BankAccountNoOtherParty: Text[50]; AccountType: Option)
    var
        BankAccount: Record "Bank Account";
        TransactionCoding: Record "Transaction Coding";
        CODAStatement: Record "CODA Statement";
    begin
        LibraryERM.CreateBankAccount(BankAccount);

        CreateTransactionCoding(TransactionCoding, AccountType);
        CODAStatement.Init();
        CODAStatement."Bank Account No." := BankAccount."No.";
        CODAStatement."Statement No." := Format(LibraryRandom.RandInt(10));
        CODAStatement."Statement Date" := WorkDate();
        CODAStatement.Insert();
        with CODAStatementLine do begin
            "Bank Account No." := BankAccount."No.";
            "Statement No." := CODAStatement."Statement No.";
            "Statement Line No." := LibraryRandom.RandInt(1000);
            "Transaction Family" := TransactionCoding."Transaction Family";
            Transaction := TransactionCoding.Transaction;
            "Transaction Category" := TransactionCoding."Transaction Category";
            "Bank Account No. Other Party" := CopyStr(BankAccountNoOtherParty, 1, MaxStrLen("Bank Account No. Other Party"));
            Insert();
        end;
    end;

    local procedure MockDtldVendLedgerEntry(VendorLedgerEntryNo: Integer);
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        LastEntryNo: Integer;
    begin
        if DetailedVendorLedgEntry.FindLast() then;
        LastEntryNo := DetailedVendorLedgEntry."Entry No.";
        DetailedVendorLedgEntry.Init();
        DetailedVendorLedgEntry."Entry No." := LastEntryNo + 1;
        DetailedVendorLedgEntry."Ledger Entry Amount" := true;
        DetailedVendorLedgEntry.Amount := LibraryRandom.RandDecInRange(1, 1000, 1);
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorLedgerEntryNo;
        DetailedVendorLedgEntry.Insert();
    end;

    local procedure MockDtldCustLedgerEntry(CustLedgerEntryNo: Integer);
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        LastEntryNo: Integer;
    begin
        if DetailedCustLedgEntry.FindLast() then;
        LastEntryNo := DetailedCustLedgEntry."Entry No.";
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." := LastEntryNo + 1;
        DetailedCustLedgEntry."Ledger Entry Amount" := true;
        DetailedCustLedgEntry.Amount := LibraryRandom.RandDecInRange(1, 1000, 1);
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgerEntryNo;
        DetailedCustLedgEntry.Insert();
    end;

    local procedure UpdateCODAStatementLine(var CODAStatementLine: Record "CODA Statement Line"; PostingDate: Date; AccountType: Enum "Gen. Journal Account Type"; StatementAmount: Decimal; ApplicationStatus: Option; DocumentNo: Code[20])
    begin
        CODAStatementLine.Validate("Posting Date", PostingDate);
        CODAStatementLine.Validate("Account Type", AccountType);
        CODAStatementLine.Validate("Statement Amount", StatementAmount);
        CODAStatementLine.Validate("Application Status", ApplicationStatus);
        CODAStatementLine.Validate("Document No.", DocumentNo);
        CODAStatementLine.Modify(true);
    end;

    local procedure VerifyCODAStatementLineApplicationInfo(CODAStatementLine: Record "CODA Statement Line"; StatementAmount: Decimal; Amount: Decimal; ApplicationStatus: Option; UnappliedAmount: Decimal)
    begin
        CODAStatementLine.TestField("Statement Amount", StatementAmount);
        CODAStatementLine.TestField(Amount, Amount);
        CODAStatementLine.TestField("Application Status", ApplicationStatus);
        CODAStatementLine.TestField("Unapplied Amount", UnappliedAmount);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesModalPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.AppliesToID.SetValue(LibraryVariableStorage.DequeueText());
        ApplyVendorEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CancelApplyVendorEntriesModalPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.AppliesToID.SetValue(LibraryVariableStorage.DequeueText());
        ApplyVendorEntries.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SetAppliesToIDAndOkOrCancelVendorEntriesModalPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.AppliesToID.SetValue(LibraryVariableStorage.DequeueText());
        if LibraryVariableStorage.DequeueBoolean() then
            ApplyVendorEntries.OK().Invoke()
        else
            ApplyVendorEntries.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SetAppliesToIDOkOrCancelVendorEntriesModalPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        if LibraryVariableStorage.DequeueBoolean() then begin
            ApplyVendorEntries.AppliesToID.SetValue(LibraryVariableStorage.DequeueText());
            ApplyVendorEntries.OK().Invoke();
        end else
            ApplyVendorEntries.Cancel().Invoke();
    end;
}

