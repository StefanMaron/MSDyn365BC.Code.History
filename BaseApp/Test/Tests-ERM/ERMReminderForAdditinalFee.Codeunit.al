codeunit 134904 "ERM Reminder For Additinal Fee"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [ERM] [Reminder]
        IsInitialized := false;
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        AmountError: Label 'Additional Fee must be %1.';
        IsInitialized: Boolean;
        ErrMsg: Label 'Rounding in the end is not expected.';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Reminder For Additinal Fee");
        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Reminder For Additinal Fee");

        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.CreateGeneralPostingSetupData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        IsInitialized := true;
        Commit;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Reminder For Additinal Fee");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderWithAdditionalFee()
    var
        ReminderLevel: Record "Reminder Level";
        SalesHeader: Record "Sales Header";
        CurrencyCode: Code[10];
        Amount: Decimal;
        ReminderNo: Code[20];
    begin
        // Create Sales Invoice with Reminder and Check Additional Fee after Suggest Reminder Lines.

        // Setup: Create Reminder with Additional Fee and Sales Invoice and Post it.
        Initialize;
        CurrencyCode := CreateCurrency;
        CreateReminderTerms(ReminderLevel, CurrencyCode);
        CreateAndPostSalesInvoice(SalesHeader, ReminderLevel."Reminder Terms Code", CurrencyCode);
        Amount := LibraryERM.ConvertCurrency(ReminderLevel."Additional Fee (LCY)", '', CurrencyCode, WorkDate);

        // Exercise: Create and Suggest Reminder Lines.
        ReminderNo :=
          CreateAndSuggestReminder(
            SalesHeader."Sell-to Customer No.", CalcDate('<1D>', CalcDate(ReminderLevel."Grace Period", SalesHeader."Due Date")));

        // Verify: Verify Reminder Lines after Suggesting.
        VerifyReminderLine(ReminderNo, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderFromRefund()
    var
        ReminderLevel: Record "Reminder Level";
        ReminderLine: Record "Reminder Line";
        GenJournalLine: Record "Gen. Journal Line";
        ReminderNo: Code[20];
    begin
        // Test Reminder Lines after Suggesting Lines for Reminder.

        // 1. Setup: Create Reminder Terms, Create Customer, Create and Post General Journal Line for Refund.
        Initialize;
        CreateReminderTerms(ReminderLevel, '');
        CreateAndPostGeneralJournal(GenJournalLine, CreateCustomer(ReminderLevel."Reminder Terms Code", ''));

        // 2. Exercise: Create Reminder Header and Suggest Lines.
        ReminderNo :=
          CreateAndSuggestReminder(
            GenJournalLine."Account No.",
            CalcDate('<' + Format(LibraryRandom.RandInt(3)) + 'D>', CalcDate(ReminderLevel."Grace Period", WorkDate)));

        // 3. Verify: Verify Reminder Lines.
        VerifyReminderLine(ReminderNo, ReminderLevel."Additional Fee (LCY)");
        FindReminderLine(ReminderLine, ReminderNo, ReminderLine.Type::"Customer Ledger Entry");
        ReminderLine.TestField("Remaining Amount", GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IssuedReminderFromRefund()
    var
        ReminderLevel: Record "Reminder Level";
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedReminderLine: Record "Issued Reminder Line";
        GenJournalLine: Record "Gen. Journal Line";
        ReminderHeader: Record "Reminder Header";
    begin
        // Test Issued Reminder Lines after Issuing Reminder.

        // 1. Setup: Create Reminder Terms, Create Customer, Create and Post General Journal Line for Refund, Create Reminder Header
        // and Suggest Lines.
        Initialize;
        CreateReminderTerms(ReminderLevel, '');
        CreateAndPostGeneralJournal(GenJournalLine, CreateCustomer(ReminderLevel."Reminder Terms Code", ''));
        ReminderHeader.Get(
          CreateAndSuggestReminder(
            GenJournalLine."Account No.",
            CalcDate('<' + Format(LibraryRandom.RandInt(3)) + 'D>', CalcDate(ReminderLevel."Grace Period", WorkDate))));

        // 2. Exercise: Issue Reminder.
        IssueReminder(ReminderHeader);

        // 3. Verify: Verify Issued Reminder Lines.
        IssuedReminderHeader.SetRange("Pre-Assigned No.", ReminderHeader."No.");
        IssuedReminderHeader.FindFirst;
        VerifyIssuedReminderLine(IssuedReminderHeader."No.", IssuedReminderLine.Type::"Customer Ledger Entry", GenJournalLine.Amount, 0);
        VerifyIssuedReminderLine(
          IssuedReminderHeader."No.", IssuedReminderLine.Type::"G/L Account", 0, ReminderLevel."Additional Fee (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderWithRounding()
    var
        SalesHeader: Record "Sales Header";
        ReminderLevel: Record "Reminder Level";
        ReminderText: Record "Reminder Text";
        ReminderNo: Code[20];
        ReminderTermsCode: Code[10];
    begin
        // Setup: Set the Rounding Precision.
        Initialize;
        LibraryERM.SetInvRoundingPrecisionLCY(LibraryRandom.RandDec(1, 2));
        ReminderTermsCode := CreateReminderTerms(ReminderLevel, '');
        LibraryERM.CreateReminderText(ReminderText, ReminderTermsCode, ReminderLevel."No.",
          ReminderText.Position::Ending, 'Reminder Text');

        // Setup: Create and Post Sales Invoice.
        CreateAndPostSalesInvoice(SalesHeader, ReminderTermsCode, '');

        // Setup: Re-Set the Rounding Precision.
        LibraryERM.SetInvRoundingPrecisionLCY(LibraryRandom.RandDec(1, 1));

        // Exercise: Create and Suggest Reminder Lines.
        ReminderNo :=
          CreateAndSuggestReminder(
            SalesHeader."Sell-to Customer No.", CalcDate('<1D>', CalcDate(ReminderLevel."Grace Period", SalesHeader."Due Date")));

        // Verify: Verify Reminder Lines after Suggesting.
        VerifyReminderRoundingLine(ReminderNo);
    end;

    [Scope('OnPrem')]
    procedure InterestAmountWithBeginningText()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        Reminder: Report Reminder;
    begin
        // [SCENARIO 252587] Interest Amount is printed with Issued Reminder when begin text exist
        Initialize;

        // [GIVEN] Reminder with Interest amount "RM" and Beginning Text = "AAA"
        // [GIVEN] "RM" is issued
        CreateIssuedReminderWithInterestAmount(IssuedReminderHeader);

        // [WHEN] Print issued "RM"
        Commit;
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID);
        IssuedReminderHeader.SetRecFilter;
        Reminder.SetTableView(IssuedReminderHeader);
        Reminder.SaveAsExcel(LibraryReportValidation.GetFileName);

        // [THEN] Interest amount is printed
        LibraryReportValidation.OpenExcelFile;
        Assert.IsTrue(LibraryReportValidation.CheckIfValueExists('Interest Amount'), 'Interest Amount must be printed');
    end;

    local procedure CreateAndPostGeneralJournal(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGeneralJournalBatch(GenJournalBatch);

        // Use Random because value is not important.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Refund,
          GenJournalLine."Account Type"::Customer, AccountNo, LibraryRandom.RandDec(1000, 2));
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostSalesInvoice(var SalesHeader: Record "Sales Header"; ReminderTermsCode: Code[10]; CurrencyCode: Code[10])
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        // Take Random Quantity for Sales Invoice.
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDec(1000, 2), LibraryRandom.RandDec(1000, 2));
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(ReminderTermsCode, CurrencyCode));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostSalesDocument(): Code[20]
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        with SalesHeader do begin
            LibrarySales.CreateSalesHeader(
              SalesHeader, "Document Type"::Invoice,
              CreateCustomerWithReminderSetup(VATPostingSetup."VAT Bus. Posting Group"));
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::Item,
              LibraryInventory.CreateItemNo,
              LibraryRandom.RandDec(10, 2));
            SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
            SalesLine.Modify(true);
        end;
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCustomer(ReminderTermsCode: Code[10]; CurrencyCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Validate("Reminder Terms Code", ReminderTermsCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithReminderSetup(VATBusPostingGroupCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
        ReminderTerms: Record "Reminder Terms";
    begin
        CreateReminderTerm(ReminderTerms);
        with Customer do begin
            LibrarySales.CreateCustomer(Customer);
            Validate("Reminder Terms Code", ReminderTerms.Code);
            Validate("Customer Posting Group", LibrarySales.FindCustomerPostingGroup);
            Validate("Fin. Charge Terms Code", CreateFinanceChargeTerms);
            Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
            Modify(true);
            exit("No.");
        end;
    end;

    local procedure CreateFinanceChargeTerms(): Code[10]
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
    begin
        // Create Finance Charge Term with Random Interest Rate, Minimum Amount, Additional Amount, Grace Period, Interest Period and
        // Due Date Calculation.
        LibraryERM.CreateFinanceChargeTerms(FinanceChargeTerms);
        FinanceChargeTerms.Validate("Interest Rate", LibraryRandom.RandDec(10, 2));
        FinanceChargeTerms.Validate("Additional Fee (LCY)", LibraryRandom.RandDec(1000, 2));
        FinanceChargeTerms.Validate("Interest Period (Days)", LibraryRandom.RandInt(30));
        Evaluate(FinanceChargeTerms."Due Date Calculation", '<' + Format(LibraryRandom.RandInt(20)) + 'D>');
        FinanceChargeTerms.Validate("Post Additional Fee", true);
        FinanceChargeTerms.Validate("Post Interest", true);
        FinanceChargeTerms.Modify(true);
        exit(FinanceChargeTerms.Code);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::General);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode);
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateReminder(CustomerNo: Code[20]; DocumentDate: Date): Code[20]
    var
        ReminderHeader: Record "Reminder Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgEntryLineFeeOn: Record "Cust. Ledger Entry";
        ReminderMake: Codeunit "Reminder-Make";
    begin
        LibraryERM.CreateReminderHeader(ReminderHeader);
        with ReminderHeader do begin
            Validate("Customer No.", CustomerNo);
            Validate("Posting Date", DocumentDate);
            Validate("Document Date", DocumentDate);
            Modify(true);
            CustLedgerEntry.SetRange("Customer No.", CustomerNo);
            ReminderMake.SuggestLines(ReminderHeader, CustLedgerEntry, false, false, CustLedgEntryLineFeeOn);
            ReminderMake.Code;
            exit("No.");
        end;
    end;

    local procedure CreateReminderTerm(var ReminderTerms: Record "Reminder Terms")
    var
        ReminderLevel: Record "Reminder Level";
        ReminderText: Record "Reminder Text";
    begin
        LibraryERM.CreateReminderTerms(ReminderTerms);
        LibraryERM.CreateReminderLevel(ReminderLevel, ReminderTerms.Code);
        ReminderLevel.Validate("Calculate Interest", true);
        ReminderLevel.Modify(true);

        LibraryERM.CreateReminderText(
          ReminderText, ReminderTerms.Code, ReminderLevel."No.",
          ReminderText.Position::Beginning, LibraryUtility.GenerateGUID);
    end;

    local procedure CreateReminderTerms(var ReminderLevel: Record "Reminder Level"; CurrencyCode: Code[10]): Code[10]
    var
        ReminderTerms: Record "Reminder Terms";
    begin
        LibraryERM.CreateReminderTerms(ReminderTerms);
        CreateReminderLevel(ReminderLevel, ReminderTerms.Code);
        ModifyCurrencyOnReminderLevel(ReminderTerms.Code, ReminderLevel."Additional Fee (LCY)", CurrencyCode);
        exit(ReminderTerms.Code);
    end;

    local procedure CreateReminderLevel(var ReminderLevel: Record "Reminder Level"; ReminderTermsCode: Code[10])
    begin
        // Take Random Grace Period and Additional Fee.
        LibraryERM.CreateReminderLevel(ReminderLevel, ReminderTermsCode);
        Evaluate(ReminderLevel."Grace Period", '<' + Format(LibraryRandom.RandInt(5)) + 'M>');
        ReminderLevel.Validate("Additional Fee (LCY)", LibraryRandom.RandInt(10));
        ReminderLevel.Modify(true);
    end;

    local procedure CreateReminderWithInterestAmount(var ReminderHeader: Record "Reminder Header")
    var
        SalesInvHeader: Record "Sales Invoice Header";
        ReminderNo: Code[20];
    begin
        SalesInvHeader.Get(CreateAndPostSalesDocument);
        ReminderNo := CreateReminderWithGivenDocNo(SalesInvHeader."No.", SalesInvHeader."Sell-to Customer No.");
        ReminderHeader.Get(ReminderNo);
        ReminderHeader.CalcFields("Interest Amount");
    end;

    local procedure CreateReminderWithGivenDocNo(DocumentNo: Code[20]; CustomerNo: Code[20]): Code[20]
    var
        ReminderLevel: Record "Reminder Level";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        FindReminderLevel(ReminderLevel, Customer."Reminder Terms Code");
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);

        // Calculate Document Date according to Reminder Level's Grace Period and add One day.
        exit(
          CreateReminder(
            CustomerNo, CalcDate('<1D>', CalcDate(ReminderLevel."Grace Period", CustLedgerEntry."Due Date"))));
    end;

    local procedure CreateIssuedReminderWithInterestAmount(var IssuedReminderHeader: Record "Issued Reminder Header")
    var
        ReminderHeader: Record "Reminder Header";
        IssuedReminderNo: Code[20];
    begin
        CreateReminderWithInterestAmount(ReminderHeader);
        IssuedReminderNo := IssueReminderAndGetIssuedNo(ReminderHeader."No.");
        IssuedReminderHeader.Get(IssuedReminderNo);
        IssuedReminderHeader.CalcFields("Interest Amount");
    end;

    local procedure FindReminderLine(var ReminderLine: Record "Reminder Line"; ReminderNo: Code[20]; Type: Option)
    begin
        ReminderLine.SetRange("Reminder No.", ReminderNo);
        ReminderLine.SetRange(Type, Type);
        ReminderLine.FindFirst;
    end;

    local procedure FindReminderLevel(var ReminderLevel: Record "Reminder Level"; ReminderTermsCode: Code[10])
    begin
        ReminderLevel.SetRange("Reminder Terms Code", ReminderTermsCode);
        ReminderLevel.FindFirst;
    end;

    local procedure IssueReminder(ReminderHeader: Record "Reminder Header")
    var
        ReminderIssue: Codeunit "Reminder-Issue";
    begin
        ReminderIssue.Set(ReminderHeader, false, ReminderHeader."Document Date");
        LibraryERM.RunReminderIssue(ReminderIssue);
    end;

    local procedure IssueReminderAndGetIssuedNo(ReminderNo: Code[20]) IssuedReminderNo: Code[20]
    var
        ReminderHeader: Record "Reminder Header";
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        ReminderHeader.Get(ReminderNo);
        IssuedReminderNo := NoSeriesManagement.GetNextNo(ReminderHeader."Issuing No. Series", WorkDate, false);
        IssueReminder(ReminderHeader);
    end;

    local procedure ModifyCurrencyOnReminderLevel(ReminderTermsCode: Code[10]; AdditionalFee: Decimal; CurrencyCode: Code[10])
    var
        CurrencyForReminderLevel: Record "Currency for Reminder Level";
    begin
        LibraryERM.CreateCurrencyForReminderLevel(CurrencyForReminderLevel, ReminderTermsCode, CurrencyCode);
        CurrencyForReminderLevel.Validate("Additional Fee", AdditionalFee);
        CurrencyForReminderLevel.Modify(true);
    end;

    local procedure CreateAndSuggestReminder(CustomerNo: Code[20]; DocumentDate: Date): Code[20]
    var
        ReminderHeader: Record "Reminder Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgEntryLineFeeOn: Record "Cust. Ledger Entry";
        ReminderMake: Codeunit "Reminder-Make";
    begin
        LibraryERM.CreateReminderHeader(ReminderHeader);
        ReminderHeader.Validate("Customer No.", CustomerNo);
        ReminderHeader.Validate("Document Date", DocumentDate);
        ReminderHeader.Modify(true);

        ReminderMake.SuggestLines(ReminderHeader, CustLedgerEntry, true, false, CustLedgEntryLineFeeOn);
        ReminderMake.Code;
        exit(ReminderHeader."No.");
    end;

    local procedure VerifyIssuedReminderLine(ReminderNo: Code[20]; Type: Option; RemainingAmount: Decimal; Amount: Decimal)
    var
        IssuedReminderLine: Record "Issued Reminder Line";
    begin
        IssuedReminderLine.SetRange("Reminder No.", ReminderNo);
        IssuedReminderLine.SetRange(Type, Type);
        IssuedReminderLine.FindFirst;
        IssuedReminderLine.TestField("Remaining Amount", RemainingAmount);
        IssuedReminderLine.TestField(Amount, Amount);
    end;

    local procedure VerifyReminderLine(ReminderNo: Code[20]; Amount: Decimal)
    var
        ReminderLine: Record "Reminder Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Assert: Codeunit Assert;
    begin
        GeneralLedgerSetup.Get;
        ReminderLine.SetRange("Reminder No.", ReminderNo);
        ReminderLine.SetRange(Type, ReminderLine.Type::"G/L Account");
        ReminderLine.SetRange("Line Type", ReminderLine."Line Type"::"Additional Fee");
        ReminderLine.FindFirst;
        Assert.AreNearlyEqual(Amount, ReminderLine.Amount, GeneralLedgerSetup."Amount Rounding Precision", StrSubstNo(AmountError, Amount));
    end;

    local procedure VerifyReminderRoundingLine(ReminderNo: Code[20])
    var
        ReminderLine: Record "Reminder Line";
    begin
        ReminderLine.SetRange("Reminder No.", ReminderNo);
        ReminderLine.SetFilter("Line Type", '%1|%2',
          ReminderLine."Line Type"::Rounding, ReminderLine."Line Type"::"Ending Text");
        ReminderLine.FindLast;
        Assert.AreNotEqual(ReminderLine."Line Type"::Rounding, ReminderLine."Line Type", ErrMsg);
    end;
}

