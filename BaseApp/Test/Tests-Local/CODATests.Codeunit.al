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
        Initialize;

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
        Initialize;

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
        Initialize;

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
        Initialize;

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
        Initialize;

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
        Initialize;

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
        Initialize;

        LibraryCODAHelper.CreateVendorBankAccount(VendorBankAccount);
        CreateCODAStatementLine(CODAStatementLine, VendorBankAccount."Bank Account No.", TransactionCoding."Account Type"::Vendor);

        BankAccount.FindLast;
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
        Initialize;

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
        CustLedgerEntry.FindFirst;
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
        Initialize;

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
        VendLedgerEntry.FindFirst;
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
        Initialize;

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
        Initialize;

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
        Initialize;

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
        Customer.FindFirst;

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
        Initialize;

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
        BankAccount.FindFirst;
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
        Initialize;

        CreateCustLedgerEntry(CustLedgerEntry, LibrarySales.CreateCustomerNo, false);

        with CODAStatementLine do begin
            Init;
            "Statement No." := LibraryUtility.GenerateGUID;
            "Statement Line No." := LibraryRandom.RandInt(100);
            "Posting Date" := WorkDate;
            "Document No." := LibraryUtility.GenerateGUID;
            "Account Type" := "Account Type"::Customer;
            "Account No." := CustLedgerEntry."Customer No.";
            Insert;
            TestField("Applies-to ID", '');
        end;

        CODAWriteStatements.Apply(CODAStatementLine);

        CODAStatementLine.Find;
        CODAStatementLine.TestField("Applies-to ID", CODAStatementLine."Document No.");
    end;

    [Normal]
    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"CODA Tests");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"CODA Tests");

        LibraryBEHelper.InitializeCompanyInformation;
        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"CODA Tests");
    end;

    [Normal]
    local procedure CreateVendLedgerEntry(var VendLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; SetupApply: Boolean)
    var
        LastEntryNo: Integer;
    begin
        VendLedgerEntry.FindLast;
        LastEntryNo := VendLedgerEntry."Entry No.";

        VendLedgerEntry.Init();
        VendLedgerEntry."Vendor No." := VendorNo;
        VendLedgerEntry."Document Type" := VendLedgerEntry."Document Type"::Invoice;
        VendLedgerEntry.Amount := LibraryRandom.RandDecInRange(1, 1000, 1);
        VendLedgerEntry."Entry No." := LastEntryNo + 1;
        VendLedgerEntry.Open := true;

        if SetupApply then begin
            VendLedgerEntry."Applies-to ID" := LibraryUtility.GenerateRandomCode(
                VendLedgerEntry.FieldNo("Applies-to ID"), DATABASE::"Vendor Ledger Entry");
            VendLedgerEntry."Amount to Apply" := LibraryRandom.RandDecInRange(1, 100, 1);
        end;
        VendLedgerEntry.Insert();
    end;

    [Normal]
    local procedure CreateCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; SetupApply: Boolean)
    var
        LastEntryNo: Integer;
    begin
        CustLedgerEntry.FindLast;
        LastEntryNo := CustLedgerEntry."Entry No.";

        CustLedgerEntry.Init();
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Invoice;
        CustLedgerEntry.Amount := LibraryRandom.RandDecInRange(1, 1000, 1);
        CustLedgerEntry."Entry No." := LastEntryNo + 1;
        CustLedgerEntry.Open := true;

        if SetupApply then begin
            CustLedgerEntry."Applies-to ID" := LibraryUtility.GenerateRandomCode(
                CustLedgerEntry.FieldNo("Applies-to ID"), DATABASE::"Cust. Ledger Entry");
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
        CODAStatement."Statement Date" := WorkDate;
        CODAStatement.Insert();
        with CODAStatementLine do begin
            "Bank Account No." := BankAccount."No.";
            "Statement No." := CODAStatement."Statement No.";
            "Transaction Family" := TransactionCoding."Transaction Family";
            Transaction := TransactionCoding.Transaction;
            "Transaction Category" := TransactionCoding."Transaction Category";
            "Bank Account No. Other Party" := CopyStr(BankAccountNoOtherParty, 1, MaxStrLen("Bank Account No. Other Party"));
            Insert;
        end;
    end;

    local procedure CreateTransactionCoding(var TransactionCoding: Record "Transaction Coding"; AccountType: Option)
    var
        LastTransactionCoding: Record "Transaction Coding";
    begin
        with TransactionCoding do begin
            if LastTransactionCoding.FindLast then;
            "Transaction Family" := LastTransactionCoding."Transaction Family" + 1;
            Transaction := LastTransactionCoding.Transaction + 1;
            "Transaction Category" := LastTransactionCoding."Transaction Category" + 1;
            "Account Type" := AccountType;
            Insert;
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

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke;
        ApplyCustomerEntries.OK.Invoke;
    end;
}

