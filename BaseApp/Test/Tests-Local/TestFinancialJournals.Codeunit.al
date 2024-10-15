codeunit 144024 "Test Financial Journals"
{
    // Automation of manual tests related to page 11300 'Financial Journals'. The vendor part cannot be automated due to hidden fields.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        PmtTerms: Record "Payment Terms";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        RandomNoGenerator: Codeunit "Library - Random";
        isInitialized: Boolean;
        BankAccountNo: Code[20];

    [Test]
    [HandlerFunctions('GeneralJournalTemplateListModalPageHandler,ApplyCustomerEntriesModalPageHandler,GeneralLedgerEntriesPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostCustomerLedgerEntries()
    var
        FinancialJournalPage: TestPage "Financial Journal";
        GLRegisters: TestPage "G/L Registers";
        BalanceLastStatement: Decimal;
        DocumentNo: Code[20];
        DocumentType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund;
        AccountType: Option "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset","IC Partner";
    begin
        // FINJNL - Validate Customer Ledger Entries
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=60224
        Initialize;

        SetupFinancialJournalPage(
          FinancialJournalPage, BalanceLastStatement, DocumentType::Payment, 'T6001', AccountType::Customer, '10000', 0);

        DocumentNo := FinancialJournalPage."Document No.".Value;
        LibraryVariableStorage.Clear;
        LibraryVariableStorage.Enqueue(DocumentNo);

        FinancialJournalPage."Apply Entries".Invoke;

        // Try to post
        FinancialJournalPage."P&ost".Invoke;
        FinancialJournalPage.Close;

        // Verify
        GLRegisters.OpenView;
        GLRegisters.First;
        LibraryVariableStorage.Clear;
        LibraryVariableStorage.Enqueue(DocumentNo);
        LibraryVariableStorage.Enqueue(BalanceLastStatement);

        GLRegisters."General Ledger".Invoke;
        GLRegisters.Close;
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTemplateListModalPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostGLAccountLedgerEntries()
    var
        FinancialJournalPage: TestPage "Financial Journal";
        BalanceLastStatement: Decimal;
        DocumentType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund;
        AccountType: Option "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset","IC Partner";
    begin
        // FINJNL - Validate the Posting of Financial Journal Lines
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=60218
        Initialize;

        SetupFinancialJournalPage(
          FinancialJournalPage, BalanceLastStatement, DocumentType::" ", 'T7001', AccountType::"G/L Account", '57000', 100000);

        LibraryVariableStorage.Clear;
        LibraryVariableStorage.Enqueue(FinancialJournalPage."Document No.".Value);

        // Try to post
        FinancialJournalPage."P&ost".Invoke;

        FinancialJournalPage.Close;
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ValidateBankReconciliationForm()
    var
        GLAccount: Record "G/L Account";
        FinancialJournalPage: TestPage "Financial Journal";
        Reconciliation: TestPage Reconciliation;
        BalanceLastStatement: Decimal;
        BalanceAtDate: Decimal;
        EndingBalance: Decimal;
        DocumentType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund;
        AccountType: Option "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset","IC Partner";
    begin
        // FINJNL - Validate the Bank Reconciliation form
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=60226
        Initialize;

        EndingBalance := 100000;
        SetupFinancialJournalPage(
          FinancialJournalPage, BalanceLastStatement, DocumentType::Payment, 'T6001', AccountType::Customer, '10000', EndingBalance);

        GLAccount.Get('550005');
        GLAccount.CalcFields("Balance at Date");
        BalanceAtDate := GLAccount."Balance at Date";

        // Try to recon
        // Reconciliation (345)
        Reconciliation.Trap;
        FinancialJournalPage.Reconcile.Invoke;

        Reconciliation.FILTER.SetFilter("No.", '550005');
        Assert.AreEqual(BalanceAtDate - BalanceLastStatement + EndingBalance,
          Reconciliation."Balance after Posting".AsDEcimal, 'Balance after post');

        Reconciliation.OK.Invoke;

        FinancialJournalPage.Close;
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ValidateCorrectBalanceAccountType()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FinancialJournalPage: TestPage "Financial Journal";
    begin
        // FINJNL - Verify Bal. Account Type in Financial Journal
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=60219
        Initialize;

        FinancialJournalPage.OpenEdit;
        FinancialJournalPage.StatementEndingBalance.SetValue(100000);
        FinancialJournalPage."Document No.".SetValue('T7001');
        FinancialJournalPage."Account Type".SetValue(GenJournalLine."Account Type"::"G/L Account");
        FinancialJournalPage."Account No.".SetValue(57000);
        FinancialJournalPage.Amount.SetValue(100000);
        asserterror FinancialJournalPage."Bal. Account Type".SetValue('Vendor');

        FinancialJournalPage.Close;
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ValidatePostingErrorOnMissingDocumentNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FinancialJournalPage: TestPage "Financial Journal";
    begin
        // FINJNL - Validate Posting of Invoice from Financial Journal, When "Document No."  Field is Empty
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=60220

        Initialize;

        FinancialJournalPage.OpenEdit;
        FinancialJournalPage.StatementEndingBalance.SetValue(100000);
        FinancialJournalPage."Document No.".SetValue(' ');
        FinancialJournalPage."Account Type".SetValue(GenJournalLine."Account Type"::"G/L Account");
        FinancialJournalPage."Account No.".SetValue(57000);
        FinancialJournalPage.Amount.SetValue(100000);
        FinancialJournalPage."Bal. Account Type".SetValue(GenJournalLine."Bal. Account Type"::"Bank Account");

        LibraryVariableStorage.Clear;
        LibraryVariableStorage.Enqueue(FinancialJournalPage."Document No.".Value);

        // Try to post
        asserterror FinancialJournalPage."P&ost".Invoke;

        FinancialJournalPage.Close;
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ValidatePostingErrorOnInvalidAmount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FinancialJournalPage: TestPage "Financial Journal";
    begin
        // FINJNL - Validate Financial Journal, When "Total Balance" Field’s Value is not Equal to "Statement Ending Balance"
        // Field’s Value
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=60217
        Initialize;

        FinancialJournalPage.OpenEdit;
        FinancialJournalPage.StatementEndingBalance.SetValue(100000);
        FinancialJournalPage."Document No.".SetValue('T001');
        FinancialJournalPage."Account Type".SetValue(GenJournalLine."Account Type"::"G/L Account");
        FinancialJournalPage."Account No.".SetValue(57000);
        FinancialJournalPage.Amount.SetValue(-900000);
        FinancialJournalPage."Bal. Account Type".SetValue(GenJournalLine."Bal. Account Type"::"Bank Account");

        LibraryVariableStorage.Clear;
        LibraryVariableStorage.Enqueue(FinancialJournalPage."Document No.".Value);

        // Try to post
        asserterror FinancialJournalPage."P&ost".Invoke;

        FinancialJournalPage.Close;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalTemplateListModalPageHandler(var GeneralJournalTemplateListPage: TestPage "General Journal Template List")
    var
        Variant: Variant;
    begin
        LibraryVariableStorage.Dequeue(Variant);
        GeneralJournalTemplateListPage.FILTER.SetFilter(Name, Variant);
        GeneralJournalTemplateListPage.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesModalPageHandler(var ApplyCustomerEntriesPage: TestPage "Apply Customer Entries")
    var
        Variant: Variant;
        AppliesTo: Text;
    begin
        ApplyCustomerEntriesPage.First;
        if ApplyCustomerEntriesPage.AppliesToID.Value <> '' then
            ApplyCustomerEntriesPage."Set Applies-to ID".Invoke;
        ApplyCustomerEntriesPage."Set Applies-to ID".Invoke;
        ApplyCustomerEntriesPage.Next;
        if ApplyCustomerEntriesPage.AppliesToID.Value <> '' then
            ApplyCustomerEntriesPage."Set Applies-to ID".Invoke;
        ApplyCustomerEntriesPage."Set Applies-to ID".Invoke;

        ApplyCustomerEntriesPage.First;
        LibraryVariableStorage.Dequeue(Variant);
        AppliesTo := Variant;
        Assert.AreEqual(AppliesTo, ApplyCustomerEntriesPage.AppliesToID.Value, 'Applies to ID does not match');

        ApplyCustomerEntriesPage.OK.Invoke;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GeneralLedgerEntriesPageHandler(var GeneralLedgerEntries: TestPage "General Ledger Entries")
    var
        Variant: Variant;
        Amount: Decimal;
    begin
        LibraryVariableStorage.Dequeue(Variant);
        GeneralLedgerEntries.FILTER.SetFilter("Document No.", Variant);
        LibraryVariableStorage.Dequeue(Variant);
        Amount := Variant;
        GeneralLedgerEntries.First;
        Assert.AreEqual(Format(550005), GeneralLedgerEntries."G/L Account No.".Value, 'GL Account No.');
        Assert.AreEqual('Payment', GeneralLedgerEntries."Document Type".Value, 'Document Type');
        Assert.AreEqual(-1 * Amount, GeneralLedgerEntries.Amount.AsDEcimal, 'Amount 1');
        GeneralLedgerEntries.Next;
        Assert.AreEqual(Amount, GeneralLedgerEntries.Amount.AsDEcimal, 'Amount 2');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Confirm: Boolean)
    begin
        Confirm := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;

    [Normal]
    local procedure Initialize()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        BankAccount: Record "Bank Account";
    begin
        // Generate random seed.
        BankAccount.SetFilter("Last Check No.", '<>%1', '');
        BankAccount.FindFirst;
        GenJournalTemplate.SetRange("Bal. Account No.", BankAccount."No.");
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Financial);
        GenJournalTemplate.FindFirst;
        BankAccountNo := GenJournalTemplate."Bal. Account No.";
        LibraryVariableStorage.Clear;
        LibraryVariableStorage.Enqueue(GenJournalTemplate.Name);

        if isInitialized then
            exit;

        // Setup default fixture

        // Create new payment terms with random discount due date and discount percentage.
        // The due date must be after the discount due date.
        ReplacePaymentTerms(
          PmtTerms, 'NEW', '<1M>', '<' + Format(RandomNoGenerator.RandInt(20)) + 'D>', RandomNoGenerator.RandInt(200) / 10);
        ModifyGenJnlBatchNoSeries;
        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibraryERMCountryData.UpdateAccountInVendorPostingGroups;
        LibraryERMCountryData.UpdatePurchasesPayablesSetup;
        LibraryERMCountryData.UpdateGeneralLedgerSetup;
        isInitialized := true;
        Commit();
    end;

    local procedure ReplacePaymentTerms(var PmtTerms: Record "Payment Terms"; "Code": Code[10]; DueDateCalc: Text[30]; DiscountDateCalc: Text[30]; Discount: Decimal)
    begin
        // Creates or updates payment terms with given code.
        if not PmtTerms.Get(Code) then begin
            PmtTerms.Init();
            PmtTerms.Code := Code;
            PmtTerms.Insert(true);
        end;

        Evaluate(PmtTerms."Due Date Calculation", DueDateCalc);
        Evaluate(PmtTerms."Discount Date Calculation", DiscountDateCalc);
        PmtTerms.Validate("Discount %", Discount);
        PmtTerms.Modify(true);
    end;

    local procedure ModifyGenJnlBatchNoSeries()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJnlBatch);
        GenJnlBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode);
        GenJnlBatch.Modify(true);
    end;

    [Normal]
    local procedure SetupFinancialJournalPage(var FinancialJournalPage: TestPage "Financial Journal"; var BalanceLastStatement: Decimal; DocumentType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund; DocumentNo: Code[20]; AccountType: Option "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset","IC Partner"; AccountNo: Code[20]; EndingBalance: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        FinancialJournalPage.OpenEdit;
        BalanceLastStatement := FinancialJournalPage.BalanceLastStatement.AsDEcimal;
        FinancialJournalPage.StatementEndingBalance.SetValue(EndingBalance);
        FinancialJournalPage."Document Type".SetValue(DocumentType);
        FinancialJournalPage."Document No.".SetValue(DocumentNo);
        FinancialJournalPage."Account Type".SetValue(AccountType);
        FinancialJournalPage."Account No.".SetValue(AccountNo);
        FinancialJournalPage.Amount.SetValue(BalanceLastStatement - EndingBalance);
        FinancialJournalPage."Bal. Account Type".SetValue(GenJournalLine."Bal. Account Type"::"Bank Account");
        FinancialJournalPage."Bal. Account No.".SetValue(BankAccountNo);

        FinancialJournalPage.Next;
        FinancialJournalPage.Previous;
    end;
}

