codeunit 142052 "ERM Payables/Receivables"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Deposit] [Reconciliation]
    end;

    var
        Assert: Codeunit Assert;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        AmountError: Label 'Amount must be equal.';
        DimensionError: Label 'A dimension used in Gen. Journal Line';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryJournals: Codeunit "Library - Journals";
        IsInitialized: Boolean;
        GLEntryError: Label 'Unexpected G/L entries amount.';
        PostedDepositLinkErr: Label 'Posted Deposit is missing a link.';
        NothingToAdjustTxt: Label 'There is nothing to adjust.';
        SingleHeaderAllowedErr: Label 'Only one %1 is allowed for each %2. You can use Deposit, Change Batch if you want to create a new Deposit.';

    [Test]
    [HandlerFunctions('GeneralJournalBatchesPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure GLDeposit()
    var
        GLAccount: Record "G/L Account";
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        DepositHeader: Record "Deposit Header";
        GLEntry: Record "G/L Entry";
    begin
        // Verify G/L Entry after post Deposit with Account Type GL as Payment, Vendor as Refund and Bank without Document Type.

        // Setup: Create GL Account, Vendor and Bank Account.
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateBankAccount(BankAccount);

        // Exercise.
        SetupAndPostDeposit(DepositHeader, GLAccount."No.", Vendor."No.", BankAccount."No.");

        // Verify: Verify G/L Entry after post Deposit with Account Type GL, Vendor and Bank.
        Assert.AreEqual(
          DepositHeader."Total Deposit Amount", CalcGLEntryAmount(
            Vendor."No.", GLEntry."Bal. Account Type"::Vendor, GLEntry."Document Type"::Refund) + CalcGLEntryAmount(
            GLAccount."No.", GLEntry."Bal. Account Type"::"G/L Account", GLEntry."Document Type"::Payment) + CalcGLEntryAmount(
            BankAccount."No.", GLEntry."Bal. Account Type"::"Bank Account", GLEntry."Document Type"::" "), GLEntryError);
    end;

    [Test]
    [HandlerFunctions('GeneralJournalBatchesPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ForceDocBalTrueOnGenTemplate()
    var
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        DepositHeader: Record "Deposit Header";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
    begin
        // Verify G/L Entry after post Deposit with Checked Force Doc. Balance.

        // Setup: Create GL Account and Vendor, create Deposit Document with Account Type GL, Customer.
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        LibrarySales.CreateCustomer(Customer);
        CreateMultilineDepositDocument(
          DepositHeader, Customer."No.", GenJournalLine."Account Type"::Customer, GLAccount."No.",
          GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Document Type"::Payment);

        // Update Total Deposit Amount on header, Force Doc. Balance on Gen. Journal Template. and post Deposit Document.
        UpdateDepositHeaderWithAmount(DepositHeader);
        UpdateGenJournalTemplate(DepositHeader."Journal Template Name", true);

        // Exercise.
        LibrarySales.PostDepositDocument(DepositHeader);

        // Verify: Verify G/L Entry after post Deposit with Checked Force Doc. Balance.
        Assert.AreEqual(
          DepositHeader."Total Deposit Amount", CalcGLEntryAmount(
            Customer."No.", GLEntry."Bal. Account Type"::Customer, GLEntry."Document Type"::Payment) + CalcGLEntryAmount(
            GLAccount."No.", GLEntry."Bal. Account Type"::"G/L Account", GLEntry."Document Type"::Payment), GLEntryError);
    end;

    [Test]
    [HandlerFunctions('GeneralJournalBatchesPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ForceDocBalFalseOnGenTemplate()
    var
        GLAccount: Record "G/L Account";
        Vendor: Record Vendor;
        DepositHeader: Record "Deposit Header";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
    begin
        // Verify G/L Entry after post Deposit with Unchecked Force Doc. Balance.

        // Setup: Create GL Account and Vendor, create Deposit Document with Account Type GL, Vendor.
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryPurchase.CreateVendor(Vendor);
        CreateMultilineDepositDocument(
          DepositHeader, GLAccount."No.", GenJournalLine."Account Type"::"G/L Account", Vendor."No.", GenJournalLine."Account Type"::Vendor,
          GenJournalLine."Document Type"::Refund);

        // Update Total Deposit Amount on header, Force Doc. Balance on Gen. Journal Template. and post Deposit Document.
        UpdateDepositHeaderWithAmount(DepositHeader);
        UpdateGenJournalTemplate(DepositHeader."Journal Template Name", false);

        // Exercise.
        LibrarySales.PostDepositDocument(DepositHeader);

        // Verify: Verify G/L Entry after post Deposit with Unchecked Force Doc. Balance.
        GLEntry.SetRange("Document No.", DepositHeader."No.");
        GLEntry.FindFirst();
        GLEntry.TestField("Document Type", GLEntry."Document Type"::" ");
        GLEntry.TestField(Amount, DepositHeader."Total Deposit Amount");
    end;

    [Test]
    [HandlerFunctions('GeneralJournalBatchesPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure FullyAppliedSalesInvoice()
    var
        Item: Record Item;
        TaxGroup: Record "Tax Group";
        Customer: Record Customer;
        DepositHeader: Record "Deposit Header";
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Verify fully applied Customer Ledger Entry after post Deposit.

        // Setup: Create Sales Document and post, create Deposit Document with Applies-to Doc. No. and post.
        Initialize();
        LibraryERM.CreateTaxGroup(TaxGroup);
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        CreateAndPostSalesDocument(
          SalesLine, Customer."No.", SalesLine."Document Type"::Order, SalesLine.Type::Item, Item."No.",
          LibraryRandom.RandInt(10), LibraryRandom.RandDec(100, 2));  // Using Random value for Quantity and Unit Price.
        CreateDepositDocument(
          DepositHeader, SalesLine."Sell-to Customer No.", GenJournalLine."Account Type"::Customer, -1);  // Using 1 as Sign Factor.
        UpdateGenJournalLine(DepositHeader, SalesLine);
        UpdateDepositHeaderWithAmount(DepositHeader);

        // Exercise.
        LibrarySales.PostDepositDocument(DepositHeader);

        // Verify: Verify fully applied Customer Ledger Entry after post Deposit.
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Customer No.", SalesLine."Sell-to Customer No.");
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.TestField("Closed by Amount", DepositHeader."Total Deposit Amount");
    end;

    [Test]
    [HandlerFunctions('GeneralJournalBatchesPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnPostVendPaymentDepositWithDefaultDimension()
    var
        Vendor: Record Vendor;
        DepositHeader: Record "Deposit Header";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify Error while posting Deposit Document with different default Dimension on Vendor.

        // Setup: Create Vendor, create Deposit Document with Dimension.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        SetupForDepostiWithDimension(
          DepositHeader, DATABASE::Vendor, Vendor."No.", GenJournalLine."Account Type"::Vendor, 1);  // Using 1 as Sign Factor.

        // Exercise.
        asserterror LibrarySales.PostDepositDocument(DepositHeader);

        // Verify: Verify Error while posting Deposit Document with different Dimension.
        Assert.ExpectedError(DimensionError);
    end;

    [Test]
    [HandlerFunctions('GeneralJournalBatchesPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnPostCustPaymentDepositWithDefaultDimension()
    var
        Customer: Record Customer;
        DepositHeader: Record "Deposit Header";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify Error while posting Deposit Document with different default Dimension on Customer.

        // Setup: Create Customer, create Deposit Document with Dimension.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        SetupForDepostiWithDimension(
          DepositHeader, DATABASE::Customer, Customer."No.", GenJournalLine."Account Type"::Customer, -1);  // Using 1 as Sign Factor.

        // Exercise.
        asserterror LibrarySales.PostDepositDocument(DepositHeader);

        // Verify: Verify Error while posting Deposit Document with different Dimension.
        Assert.ExpectedError(DimensionError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnrealizedGainLossOnBankReconciliation()
    var
        Currency: Record Currency;
        BankAccount: Record "Bank Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankRecWorksheet: TestPage "Bank Rec. Worksheet";
    begin
        // Verify Difference value on Bank Acc. Reconcilation card after Suggest Lines from same.

        // Setup: Create Currency with Exch. Rate, update General Ledger Setup, create Bank Account, create Gen. Journal Line and post.
        Initialize();
        CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        UpdateGenLedgerSetup(Currency.Code);
        CreateBankAccount(BankAccount, Currency.Code);
        BankAccountPostingGroup.Get(BankAccount."Bank Acc. Posting Group");
        CreateAndPostUpdatedGenJournal(
          GenJournalLine, GenJournalLine."Account Type"::"Bank Account", BankAccount."No.", WorkDate,
          BankAccountPostingGroup."G/L Account No.", LibraryRandom.RandInt(100));  // Using Random value for Amount.

        // Exercise.
        SuggestBankReconLines(BankAccReconciliation, BankAccount);

        // Verify: Verify Difference value on Bank Acc. Reconcilation card.
        BankRecWorksheet.OpenEdit;
        BankRecWorksheet.FILTER.SetFilter("Bank Account No.", BankAccount."No.");
        Assert.AreEqual(BankRecWorksheet.Difference.AsDEcimal, 0, '');  // Difference.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DescriptionOnCheckLedgerEntry()
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        // Verify Description in Check Ledger same as in Payment Journal after post Payment Entry to Vendor.

        // Setup: Create Bank Account and Vendor, create payment journal with manual check and post.
        Initialize();
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryPurchase.CreateVendor(Vendor);

        // Exercise.
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.", BankAccount."No.",
          GenJournalLine."Bank Payment Type"::"Manual Check", LibraryRandom.RandInt(100), GenJournalTemplate.Type::Payments,
          GenJournalLine."Document Type"::Payment);  // Using Random value for Deposit Amount.

        // Verify: Verify Description in Check Ledger same as in Payment Journal.
        CheckLedgerEntry.SetRange("Bank Account No.", BankAccount."No.");
        CheckLedgerEntry.FindFirst();
        CheckLedgerEntry.TestField(Description, GenJournalLine.Description);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DocNoOnBankReconcilation()
    var
        BankAccount: Record "Bank Account";
        BankRecLine: Record "Bank Rec. Line";
        BankRecLine2: Record "Bank Rec. Line";
    begin
        // Verify Continuity of Adjustment Document No. on next Bank Rec. Worksheet.

        // Setup: Create Bank Account, create Bank Rec. Worksheet and post.
        Initialize();
        CreateBankAccount(BankAccount, '');
        CreateAndPostBankRecWorksheet(BankRecLine, BankAccount."No.");

        // Exercise.
        CreateBankRecWorksheet(BankRecLine2, BankAccount."No.");

        // Verify: Verify Adjustment Document No. on Bank Rec Worksheet.
        BankRecLine2.TestField("Document No.", IncStr(BankRecLine."Document No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ContinuityOfDocNoOnBankReconcilation()
    var
        BankAccount: Record "Bank Account";
        BankRecLine: Record "Bank Rec. Line";
        BankRecLine2: Record "Bank Rec. Line";
    begin
        // Verify Continuity of Adjustment Document No. on Bank Rec. Worksheet after post multiple Document.

        // Setup: Create Bank Account, create Bank Rec. Worksheet and post.
        Initialize();
        CreateBankAccount(BankAccount, '');
        CreateAndPostBankRecWorksheet(BankRecLine, BankAccount."No.");
        CreateAndPostBankRecWorksheet(BankRecLine, BankAccount."No.");

        // Exercise.
        CreateBankRecWorksheet(BankRecLine2, BankAccount."No.");

        // Verify: Verify Continuity of Adjustment Document No. on Bank Rec Worksheet.
        BankRecLine2.TestField("Document No.", IncStr(BankRecLine."Document No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure MultLineContinuityOfDocNoOnBankReconcilation()
    var
        BankAccount: Record "Bank Account";
        BankRecHeader: Record "Bank Rec. Header";
        BankRecLine: Record "Bank Rec. Line";
        BankRecLine2: Record "Bank Rec. Line";
        DocumentNo: Code[20];
    begin
        // Verify Continuity of Adjustment Document No. on next Bank Rec. Worksheet after post Multiline Bank Rec. Worksheet.

        // Setup: Create Bank Account, create Bank Rec. Worksheet and post.
        Initialize();
        CreateBankAccount(BankAccount, '');
        CreateBankRecWorksheet(BankRecLine, BankAccount."No.");
        BankRecHeader.Get(BankRecLine."Bank Account No.", BankRecLine."Statement No.");
        Commit();
        CreateBankRecLineFromPage(BankRecHeader);
        DocumentNo := CreateBankRecLineFromPage(BankRecHeader);
        CODEUNIT.Run(CODEUNIT::"Bank Rec.-Post (Yes/No)", BankRecHeader);

        // Exercise.
        CreateBankRecWorksheet(BankRecLine2, BankAccount."No.");

        // Verify: Verify Continuity of Adjustment Document No. on Bank Rec Worksheet.
        BankRecLine2.TestField("Document No.", IncStr(DocumentNo));
    end;

    [Test]
    [HandlerFunctions('SuggestAndMarkLinesHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AllTransactionOfBankReconcilation()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        BankAccount2: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        BankRecHeader: Record "Bank Rec. Header";
        GLEntry: Record "G/L Entry";
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // Verify GL Entries after post Bank Reconcilation with Checks and Deposit.

        Initialize();
        CreateBankAccount(BankAccount, '');
        LibraryERM.CreateBankAccount(BankAccount2);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        // Create and Post General Journal.
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::"Bank Account", BankAccount2."No.", BankAccount."No.",
          GenJournalLine."Bank Payment Type"::" ", -LibraryRandom.RandInt(100), GenJournalTemplate.Type::General,
          GenJournalLine."Document Type"::Payment);

        // Create and Post Purchase Order.
        DocumentNo :=
          CreateAndPostPurchaseDocument(
            PurchaseLine, PurchaseLine."Document Type"::Order, Vendor."No.", Item."No.", PurchaseLine.Type::Item,
            LibraryRandom.RandInt(100), LibraryRandom.RandDec(100, 2));  // Using Random value for Quantity and Direct Unit Cost.

        // Create and Post Payment Journal, refund to Vendor
        Amount := LibraryRandom.RandInt(100);
        CreatePaymentGenJournal(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.", BankAccount."No.",
          GenJournalLine."Bank Payment Type"::"Manual Check", 0, GenJournalTemplate.Type::Payments,
          GenJournalLine."Document Type"::Payment);
        UpdateApplicationOnGenJournalLine(
          GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          DocumentNo, CalcDate(Format(LibraryRandom.RandInt(10)) + 'D', GenJournalLine."Posting Date"), Amount);  // Using Random value for No. of Days.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Create and Post Cash Receipt Journal.
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.", BankAccount."No.",
          GenJournalLine."Bank Payment Type"::" ", Amount / 3, GenJournalTemplate.Type::"Cash Receipts",
          GenJournalLine."Document Type"::Payment);  // Using Random value for Amount.

        // Create and Suggest Bank Reconcilation.
        CreateAndSuggesBankRecWorksheet(BankRecHeader, BankAccount."No.");

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"Bank Rec.-Post (Yes/No)", BankRecHeader);

        // Verify: Verify GL Entries after post Bank Reconcilation.
        VerifyGLEntry(GLEntry."Bal. Account Type"::Vendor, Vendor."No.", Vendor."No.");
        VerifyGLEntry(GLEntry."Bal. Account Type"::"Bank Account", Vendor."No.", BankAccount."No.");
    end;

    [Test]
    [HandlerFunctions('SuggestAndMarkLinesHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ChecksOnBankReconcilation()
    var
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        BankRecHeader: Record "Bank Rec. Header";
        GLEntry: Record "G/L Entry";
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // Verify GL Entries after post Bank Reconcilation with Checks.

        // Setup.
        Initialize();
        CreateBankAccount(BankAccount, '');
        LibrarySales.CreateCustomer(Customer);

        // Create and Post General Journal and Sales Order.
        DocumentNo := PostGenJournalAndSalesOrder(BankAccount."No.", Customer."No.");

        // Create and Post Payment Journal, refund to Customer.
        Amount := LibraryRandom.RandInt(100);
        CreatePaymentGenJournal(
          GenJournalLine, GenJournalLine."Account Type"::Customer, Customer."No.", BankAccount."No.",
          GenJournalLine."Bank Payment Type"::"Manual Check", 0, GenJournalTemplate.Type::Payments,
          GenJournalLine."Document Type"::Payment);
        UpdateApplicationOnGenJournalLine(
          GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          DocumentNo, CalcDate(Format(LibraryRandom.RandInt(10)) + 'D', GenJournalLine."Posting Date"), -Amount);  // Using Random value for No. of Days.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Create and Suggest Bank Reconcilation.
        CreateAndSuggesBankRecWorksheet(BankRecHeader, BankAccount."No.");

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"Bank Rec.-Post (Yes/No)", BankRecHeader);

        // Verify: Verify GL Entries after post Bank Reconcilation.
        VerifyGLEntry(GLEntry."Bal. Account Type"::Customer, Customer."No.", Customer."No.");
        VerifyGLEntry(GLEntry."Bal. Account Type"::"Bank Account", Customer."No.", BankAccount."No.");
    end;

    [Test]
    [HandlerFunctions('SuggestAndMarkLinesHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DepositOnBankReconcilation()
    var
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        BankRecLine: Record "Bank Rec. Line";
        BankRecHeader: Record "Bank Rec. Header";
        GLEntry: Record "G/L Entry";
    begin
        // Verify GL Entries after post Bank Reconcilation with Deposit.

        // Setup.
        Initialize();
        CreateBankAccount(BankAccount, '');
        LibrarySales.CreateCustomer(Customer);
        SetupForDeposit(BankRecLine, BankAccount."No.", Customer."No.");
        BankRecHeader.Get(BankRecLine."Bank Account No.", BankRecLine."Statement No.");
        BankRecHeader.CalcFields("G/L Balance (LCY)");
        BankRecHeader.Validate("Statement Balance", BankRecHeader."G/L Balance (LCY)");
        BankRecHeader.Modify(true);

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"Bank Rec.-Post (Yes/No)", BankRecHeader);

        // Verify: Verify GL Entries after post Bank Reconcilation.
        VerifyGLEntry(GLEntry."Bal. Account Type"::Customer, Customer."No.", Customer."No.");
        VerifyGLEntry(GLEntry."Bal. Account Type"::"Bank Account", Customer."No.", BankAccount."No.");
    end;

    [Test]
    [HandlerFunctions('SuggestAndMarkLinesHandler')]
    [Scope('OnPrem')]
    procedure ClearedOnBankReconcilationLine()
    var
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        BankRecLine: Record "Bank Rec. Line";
    begin
        // Verify Cleared on Bank Rec. Lines after Mark the Lines.

        // Setup.
        Initialize();
        CreateBankAccount(BankAccount, '');
        LibrarySales.CreateCustomer(Customer);

        // Exercise.
        SetupForDeposit(BankRecLine, BankAccount."No.", Customer."No.");

        // Verify: Verify Cleared on Bank Rec. Lines.
        BankRecLine.SetRange("Bank Account No.", BankAccount."No.");
        BankRecLine.FindFirst();
        BankRecLine.TestField(Cleared, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AdjustmentOnBankReconcilation()
    var
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        BankRecLine: Record "Bank Rec. Line";
        BankRecHeader: Record "Bank Rec. Header";
        GLEntry: Record "G/L Entry";
    begin
        // Verify GL Entries after post Bank Reconcilation with Adjustment.

        // Setup: Create Bank Rec. Worksheet with Adjustment.
        Initialize();
        CreateBankAccount(BankAccount, '');
        LibrarySales.CreateCustomer(Customer);
        CreateBankRecWorksheet(BankRecLine, BankAccount."No.");
        UpdateBankRecLine(BankRecLine, BankAccount."No.", Customer."No.");
        BankRecHeader.Get(BankRecLine."Bank Account No.", BankRecLine."Statement No.");

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"Bank Rec.-Post (Yes/No)", BankRecHeader);

        // Verify: Verify GL Entries after post Bank Reconcilation.
        VerifyGLEntry(GLEntry."Bal. Account Type"::Customer, BankAccount."No.", Customer."No.");
        VerifyGLEntry(GLEntry."Bal. Account Type"::"Bank Account", BankAccount."No.", BankAccount."No.");
    end;

    [Test]
    [HandlerFunctions('GeneralJournalBatchesPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostedDepositAndBankAccLedger()
    var
        BankAccount: Record "Bank Account";
        DepositHeader: Record "Deposit Header";
        GLAccount: Record "G/L Account";
        PostedDepositHeader: Record "Posted Deposit Header";
        Vendor: Record Vendor;
    begin
        // Verify Posted Deposit after post Deposit and Bank Account Ledger Entry.

        // Setup: Create GL Account, Vendor and Bank Account.
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateBankAccount(BankAccount);

        // Exercise.
        SetupAndPostDeposit(DepositHeader, GLAccount."No.", Vendor."No.", BankAccount."No.");

        // Verify: Verify Posted Deposit after post Deposit and Bank Account Ledger Entry.

        PostedDepositHeader.Get(DepositHeader."No.");
        PostedDepositHeader.TestField("Bank Account No.", DepositHeader."Bank Account No.");
        PostedDepositHeader.TestField("Total Deposit Amount", DepositHeader."Total Deposit Amount");
        VerifyBankAccLedgerEntryAmount(DepositHeader."Bank Account No.", DepositHeader."Total Deposit Amount");
    end;

    [Test]
    [HandlerFunctions('AdjustExchangeRatesReqPageHandler,SuggestAndMarkLinesHandler,NothingAdjustedMessageHandler')]
    [Scope('OnPrem')]
    procedure RealizedGainInGLBalOnBankReconciliation()
    var
        RateFactor: Decimal;
    begin
        // Verify Realized Gain on GL Balace LCY and GL Balance value on Bank Acc. Reconcilation card after Suggest Lines with more than one Currency Exch. Rate.
        RateFactor := LibraryRandom.RandDec(3, 2);  // Using Random Range value for Currency Exch. Rate factor.
        RealizedGainLossInGLBalOnBankReconciliation(RateFactor, RateFactor + 1, LibraryRandom.RandInt(1000));  // Using Random value for Amount.
    end;

    [Test]
    [HandlerFunctions('AdjustExchangeRatesReqPageHandler,SuggestAndMarkLinesHandler,NothingAdjustedMessageHandler')]
    [Scope('OnPrem')]
    procedure RealizedLossInGLBalOnBankReconciliation()
    var
        RateFactor: Decimal;
    begin
        // Verify Realized Loss on GL Balace LCY and GL Balance value on Bank Acc. Reconcilation card after Suggest Lines with more than one Currency Exch. Rate.
        RateFactor := LibraryRandom.RandDec(3, 2);  // Using Random Range value for Currency Exch. Rate factor.
        RealizedGainLossInGLBalOnBankReconciliation(RateFactor + 1, RateFactor, LibraryRandom.RandInt(1000));  // Using Random value for Amount.
    end;

    local procedure RealizedGainLossInGLBalOnBankReconciliation(RateFactor: Decimal; RateFactor2: Decimal; Amount: Decimal)
    var
        Currency: Record Currency;
        BankAccount: Record "Bank Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        BankRecHeader: Record "Bank Rec. Header";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Setup: Create Currency with Exch. Rate, create Bank Account, create GL Account, create Gen. Journal Line and post.
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.FindGLAccount(GLAccount2);
        CreateCurrency(Currency);
        CreateBankAccount(BankAccount, Currency.Code);
        CreateCurrencyExchangeRate(Currency.Code, WorkDate, RateFactor);
        CreateCurrencyExchangeRate(
          Currency.Code, CalcDate(Format(LibraryRandom.RandIntInRange(2, 6)) + 'M', WorkDate), RateFactor2);  // Using Random Range value for No. of Month.
        CreateAndPostUpdatedGenJournal(
          GenJournalLine, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          WorkDate - 1, GLAccount2."No.", Amount);

        // Post Cash Receipt with GL Bank Account No. as Bal. Account and Currency Code.
        BankAccountPostingGroup.Get(BankAccount."Bank Acc. Posting Group");
        CreateAndPostUpdatedGenJournal(
          GenJournalLine, GenJournalLine."Account Type"::"Bank Account", BankAccount."No.",
          WorkDate + 1, BankAccountPostingGroup."G/L Account No.",
          Amount - LibraryRandom.RandInt(200));  // Using Random value for increase Amount.

        // Update Bank Account Posting Group and run Adjust Exchange Rates Report.
        BankAccountPostingGroup.Validate("G/L Account No.", GLAccount."No.");
        BankAccountPostingGroup.Modify(true);
        LibraryVariableStorage.Enqueue(Currency.Code);  // Enqueue Currency Code for AdjustExchangeRatesReqPageHandler.
        Commit();  // Commit required for run Report.
        REPORT.RunModal(REPORT::"Adjust Exchange Rates");

        // Exercise.
        CreateAndSuggesBankRecWorksheet(BankRecHeader, BankAccount."No.");

        // Verify: Verify GL Balance values on Bank Acc. Reconcilation card.
        BankRecHeader.SetRange("Bank Account No.", BankAccount."No.");
        BankRecHeader.FindFirst();
        BankRecHeader.CalcFields("G/L Balance (LCY)");
        BankRecHeader.TestField("G/L Balance (LCY)", Amount);
        BankRecHeader.TestField(
          "G/L Balance", Round(
            BankRecHeader."G/L Balance (LCY)" * BankRecHeader."Currency Factor", LibraryERM.GetAmountRoundingPrecision));
    end;

    [Test]
    [HandlerFunctions('SuggestAndMarkLinesHandler')]
    [Scope('OnPrem')]
    procedure TotalClearedOnSubFormOfBankRecWorksheet()
    var
        BankAccount: Record "Bank Account";
        BankAccount2: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        BankRecHeader: Record "Bank Rec. Header";
        BankRecLine: Record "Bank Rec. Line";
    begin
        // Verify Total Cleared value on Deposit fast tab of Bank Reconcilation.

        // Setup: Create Bank Account and post Payment and Invoice through Gen. Journal.
        Initialize();
        CreateBankAccount(BankAccount, '');
        LibraryERM.CreateBankAccount(BankAccount2);
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::"Bank Account", BankAccount."No.", BankAccount2."No.",
          GenJournalLine."Bank Payment Type"::" ", LibraryRandom.RandDec(1000, 2), GenJournalTemplate.Type::"Cash Receipts",
          GenJournalLine."Document Type"::Payment);  // Using Random value for Amount.
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::"Bank Account", BankAccount2."No.", BankAccount."No.",
          GenJournalLine."Bank Payment Type"::" ", LibraryRandom.RandDec(500, 2), GenJournalTemplate.Type::"Cash Receipts",
          GenJournalLine."Document Type"::Invoice);  // Using Random value for Amount.

        // Exercise.
        CreateAndSuggesBankRecWorksheet(BankRecHeader, BankAccount."No.");

        // Verify: Verify Total Cleard value on Deposit fast tab.
        BankRecLine.SetRange("Bank Account No.", BankAccount."No.");
        BankRecLine.CalcSums(Amount);
        BankRecHeader.CalcFields("Total Cleared Deposits");
        BankRecHeader.TestField("Total Cleared Deposits", BankRecLine.Amount);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentRequestPageHandler,MessageHandler,ConfirmHandler,GeneralJournalTemplateListPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendFullPaymentAgainstInvoiceAndCrMemo()
    begin
        // Verify Vendor balance after post payment of remaining balance in case of fully applied Credit Memo.
        SuggestVendPaymentAgainstInvoiceAndCrMemo(1);  // Using 1 as multiplication factor for full value.
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentRequestPageHandler,MessageHandler,ConfirmHandler,GeneralJournalTemplateListPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendPartialPaymentAgainstInvoiceAndCrMemo()
    begin
        // Verify Vendor balance after post payment of remaining balance in case of partial applied Credit Memo.
        SuggestVendPaymentAgainstInvoiceAndCrMemo(2);   // Using 2 as multiplication factor for partial value.
    end;

    local procedure SuggestVendPaymentAgainstInvoiceAndCrMemo(PartialFactor: Decimal)
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // Setup: Create Vendor, Post Purchase Invoice and Credit Memo.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateBankAccount(BankAccount);
        PostPurchInvAndCrMemo(Vendor."No.", Vendor."VAT Bus. Posting Group", PartialFactor);

        // Open Payment Journal, Suggest Vendor Payment and Post.
        GenJournalBatch.SetRange("Template Type", GenJournalBatch."Template Type"::Payments);
        GenJournalBatch.FindFirst();
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryVariableStorage.Enqueue(Vendor."No.");
        LibraryVariableStorage.Enqueue(BankAccount."No.");
        Commit();  // Commit required for open Payment Journal.
        PaymentJournal.OpenEdit;
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        PaymentJournal.SuggestVendorPayments.Invoke;

        // Exercise.
        PaymentJournal.Post.Invoke;  // Post.

        // Verify: Verify Vendor balance after post payment of remaining balance.
        Vendor.CalcFields("Balance (LCY)");
        Vendor.TestField("Balance (LCY)", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyEntriesForVendPartialPaymentAgainstInvoiceAndCrMemo()
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Verify Vendor balance after post payment of remaining balance through Apply Entries.

        // Setup: Create Vendor, Post Purchase Invoice and Credit Memo.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateBankAccount(BankAccount);
        PostPurchInvAndCrMemo(Vendor."No.", Vendor."VAT Bus. Posting Group", 2);  // Using 2 for partial payment.

        // Open Payment Journal, Suggest Vendor Payment and Post.
        CreatePaymentGenJournal(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.", BankAccount."No.",
          GenJournalLine."Bank Payment Type"::"Manual Check", 0, GenJournalTemplate.Type::Payments,
          GenJournalLine."Document Type"::Payment);

        // Apply Vendor Ledger Entry and update Amount to Apply on Payment Journal.
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry);
        GenJournalLine.Validate(Amount, VendorLedgerEntry."Amount to Apply");
        GenJournalLine.Modify(true);

        // Excercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Vendor balance after post payment of remaining balance through Apply Entries.
        Vendor.CalcFields("Balance (LCY)");
        Assert.AreNearlyEqual(0, Vendor."Balance (LCY)", LibraryERM.GetAmountRoundingPrecision, AmountError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyEntriesForCustPartialPaymentAgainstInvoiceAndCrMemo()
    var
        Item: Record Item;
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        SalesLine: Record "Sales Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Verify Customer balance after post payment of remaining balance through Apply Entries.

        // Setup: Create Customer, Bank and Item.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryInventory.CreateItem(Item);

        // Post Sales Invoice and Credit Memo with partial quantity.
        CreateAndPostSalesDocument(SalesLine, Customer."No.", SalesLine."Document Type"::Invoice, SalesLine.Type::Item, Item."No.",
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(100));  // Using Random value for Quantity and Unit Price.
        CreateAndPostSalesDocument(SalesLine, Customer."No.", SalesLine."Document Type"::"Credit Memo", SalesLine.Type::Item, Item."No.",
          SalesLine.Quantity / 2, SalesLine."Unit Price");  // Using divide by 2 for partial value of Invoice.

        // Open Payment Journal, Suggest Customer Payment and Post.
        CreatePaymentGenJournal(
          GenJournalLine, GenJournalLine."Account Type"::Customer, Customer."No.", BankAccount."No.",
          GenJournalLine."Bank Payment Type"::"Manual Check", 0, GenJournalTemplate.Type::Payments,
          GenJournalLine."Document Type"::Payment);

        // Apply Customer Ledger Entry and update Amount to Apply on Payment Journal.
        CustomerLedgerEntry.SetRange("Customer No.", Customer."No.");
        LibraryERM.SetAppliestoIdCustomer(CustomerLedgerEntry);
        GenJournalLine.Validate(Amount, CustomerLedgerEntry."Amount to Apply");
        GenJournalLine.Modify(true);

        // Excercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Customer balance after post payment of remaining balance through Apply Entries.
        Customer.CalcFields("Balance (LCY)");
        Assert.AreNearlyEqual(0, Customer."Balance (LCY)", LibraryERM.GetAmountRoundingPrecision, AmountError);
    end;

    [Test]
    [HandlerFunctions('GeneralJournalBatchesPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DepositWithNewGenJournalBatch()
    var
        GLAccount: Record "G/L Account";
        DepositHeader: Record "Deposit Header";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
    begin
        // Verify Journal Batch Name in G/L Entry after post Deposit with Account Type GL.

        // Setup: Create GL Account, Deposit and update Total Deposit Amount on header.
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        CreateDepositDocument(DepositHeader, GLAccount."No.", GenJournalLine."Account Type"::"G/L Account", 1);
        UpdateDepositHeaderWithAmount(DepositHeader);

        // Exercise.
        LibrarySales.PostDepositDocument(DepositHeader);

        // Verify: Verify Journal Batch Name in G/L Entry after post Deposit with Account Type GL.
        GLEntry.SetRange("Bal. Account No.", GLAccount."No.");
        GLEntry.FindFirst();
        GLEntry.TestField("Journal Batch Name", DepositHeader."Journal Batch Name");
    end;

    [Test]
    [HandlerFunctions('SuggestAndMarkLinesHandler')]
    [Scope('OnPrem')]
    procedure SuggestBankReconcilationWithMaxLengthExternalDocNo()
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        BankRecHeader: Record "Bank Rec. Header";
        BankRecLine: Record "Bank Rec. Line";
    begin
        // Verify Suggest Bank Reconcilation can be executed successfully when exist a payment Journal with Max length External Document No.

        // Setup: Create a bank account and vendor. Create and post a payment journal with max length External Document No.(Current Max Length = 35).
        Initialize();
        CreateBankAccount(BankAccount, '');
        LibraryPurchase.CreateVendor(Vendor);
        CreatePaymentGenJournalWithMaxLengthExternalDoctNo(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, Vendor."No.", BankAccount."No.",
          GenJournalLine."Bank Payment Type"::"Manual Check", LibraryRandom.RandDec(100, 2),
          GenJournalTemplate.Type::Payments, GenJournalLine."Document Type"::Payment);

        // Exercise and Verify: Create and Suggest Bank Reconcilation. Verify no error pops up.
        CreateAndSuggesBankRecWorksheet(BankRecHeader, BankAccount."No.");

        // Verify: Verify the field of External Document No. in Bank Rec. line.
        FindBankRecLine(BankRecLine, BankAccount."No.");
        BankRecLine.TestField("External Document No.", GenJournalLine."External Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPreviewContainsVendorAddress()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        Country: Record "Country/Region";
        CheckPreview: TestPage "Check Preview";
    begin
        // [FEATURE] [Payables]
        // [SCENARIO 378666] When we run Preview Check function from the Payment Journal correct Payee address is shown

        // [GIVEN] Vendor: Address=A, "Address 2"=B, City=C, County=D, "Post Code"=E,  "Country/Region Code"="Country/Region".Code; "Country/Region".Name=F
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Address := 'A';
        Vendor."Address 2" := 'B';
        Vendor.City := 'C';
        Vendor.County := 'D';
        Vendor."Post Code" := 'E';
        LibraryERM.CreateCountryRegion(Country);
        Country.Name := 'F';
        Country.Modify();
        Vendor."Country/Region Code" := Country.Code;
        Vendor.Modify();
        // [GIVEN] Gen. Journal Line payment to Vendor
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, Vendor."No.", 100);

        // [WHEN] Calling page "Check Preview"
        CallCheckPreview(CheckPreview, GenJournalLine);

        // [THEN] Page "Address" field is 'A, B, C, E, D, F'
        CheckPreview.Address.AssertEquals('A, B, C, E, D, F');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPreviewContainsCustomerAddress()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        Country: Record "Country/Region";
        CheckPreview: TestPage "Check Preview";
    begin
        // [FEATURE] [Receivables]
        // [SCENARIO 378666] When we run Preview Check function from the Payment Journal correct Payee address is shown

        // [GIVEN] Customer: Address=A, "Address 2"=B, City=C, County=D, "Post Code"=E,  "Country/Region Code"="Country/Region".Code; "Country/Region".Name=F
        LibrarySales.CreateCustomer(Customer);
        Customer.Address := 'A';
        Customer."Address 2" := 'B';
        Customer.City := 'C';
        Customer.County := 'D';
        Customer."Post Code" := 'E';
        LibraryERM.CreateCountryRegion(Country);
        Country.Name := 'F';
        Country.Modify();
        Customer."Country/Region Code" := Country.Code;
        Customer.Modify();
        // [GIVEN] Gen. Journal Line refund to Customer
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, GenJournalLine."Document Type"::Refund,
          GenJournalLine."Account Type"::Customer, Customer."No.", 100);

        // [WHEN] Calling page "Check Preview"
        CallCheckPreview(CheckPreview, GenJournalLine);

        // [THEN] Page "Address" field is 'A, B, C, E, D, F'
        CheckPreview.Address.AssertEquals('A, B, C, E, D, F');
    end;

    [Test]
    [HandlerFunctions('GeneralJournalBatchesPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostDepositWithLink()
    var
        DepositHeader: Record "Deposit Header";
        GenJournalLine: Record "Gen. Journal Line";
        PostedDepositHeader: Record "Posted Deposit Header";
    begin
        // [FEATURE] [Record Link]
        // [SCENARIO 378922] Deposit posting procedure copy links to posted document
        Initialize();

        // [GIVEN] Deposit with random Link added
        CreateDepositDocument(DepositHeader, LibrarySales.CreateCustomerNo, GenJournalLine."Account Type"::Customer, -1);
        UpdateDepositHeaderWithAmount(DepositHeader);
        DepositHeader.AddLink(LibraryUtility.GenerateRandomText(10));

        // [WHEN] Post Deposit
        LibrarySales.PostDepositDocument(DepositHeader);

        // [THEN] Posted Depostit has attached link
        PostedDepositHeader.Get(DepositHeader."No.");
        Assert.IsTrue(PostedDepositHeader.HasLinks, PostedDepositLinkErr);
    end;

    [Test]
    [HandlerFunctions('GeneralJournalBatchesPageHandler')]
    [Scope('OnPrem')]
    procedure DuplicateDepositForSameBatchWithFilter()
    var
        DepositHeader: Record "Deposit Header";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // [SCENARIO 313506] Check for existing Deposit Headers for Gen. Journal Batch on insert new record disregards filters
        Initialize();

        // [GIVEN] Gen. Journal Batch for Deposits template
        CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Deposits);

        // [GIVEN] Deposit Header with "Bank Account No." = "BANK01"
        CreateDepositHeader(DepositHeader, GenJournalBatch);

        // [WHEN] Create new Deposit Header for the same Gen. Journal Batch with filter set to "Bank Account No." <> "BANK01"
        DepositHeader.SetFilter("Bank Account No.", '<>%1', DepositHeader."Bank Account No.");
        asserterror LibrarySales.CreateDepositHeader(DepositHeader, GenJournalBatch);

        // [THEN] Error: "Only one Deposit Header is allowed for each Gen. Journal Batch."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(SingleHeaderAllowedErr, DepositHeader.TableCaption, GenJournalBatch.TableCaption));
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryERMCountryData.CreateVATData();
        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        UpdateGenLedgerSetup('');
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        IsInitialized := true;
        Commit();
    end;

    local procedure CalcGLEntryAmount(BalAccountNo: Code[20]; BalAccountType: Option; DocumentType: Option) Amount: Decimal
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Bal. Account No.", BalAccountNo);
        GLEntry.SetRange("Bal. Account Type", BalAccountType);
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.FindSet();
        repeat
            Amount += GLEntry.Amount;
        until GLEntry.Next = 0;
    end;

    local procedure CreateVATPostingSetup(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if not VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup) then
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup, VATProdPostingGroup);
    end;

    local procedure CreateAndPostBankRecWorksheet(var BankRecLines: Record "Bank Rec. Line"; BankAccountNo: Code[20])
    var
        BankRecHeader: Record "Bank Rec. Header";
    begin
        CreateBankRecWorksheet(BankRecLines, BankAccountNo);
        BankRecHeader.Get(BankRecLines."Bank Account No.", BankRecLines."Statement No.");
        CODEUNIT.Run(CODEUNIT::"Bank Rec.-Post (Yes/No)", BankRecHeader);
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Option; AccountNo: Code[20]; BalAccountNo: Code[20]; BankPaymentType: Option; Amount: Decimal; Type: Option; DocumentType: Option)
    begin
        CreatePaymentGenJournal(
          GenJournalLine, AccountType, AccountNo, BalAccountNo, BankPaymentType, Amount, Type, DocumentType);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePaymentGenJournalWithMaxLengthExternalDoctNo(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Option; AccountNo: Code[20]; BalAccountNo: Code[20]; BankPaymentType: Option; Amount: Decimal; Type: Option; DocumentType: Option)
    begin
        CreatePaymentGenJournal(GenJournalLine, AccountType, AccountNo, BalAccountNo, BankPaymentType, Amount, Type, DocumentType);
        GenJournalLine.Validate("External Document No.", PadStr(GenJournalLine."External Document No.", MaxStrLen(GenJournalLine."External Document No."), '0'));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Option; BuyfromVendorNo: Code[20]; No: Code[20]; Type: Option; Quantity: Decimal; DirectUnitCost: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, BuyfromVendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostSalesDocument(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; DocumentType: Option; Type: Option; No: Code[20]; Quantity: Decimal; UnitPrice: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostUpdatedGenJournal(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Option; AccountNo: Code[20]; PostingDate: Date; BalAccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndSuggesBankRecWorksheet(var BankRecHeader: Record "Bank Rec. Header"; BankAccountNo: Code[20])
    var
        BankRecLine: Record "Bank Rec. Line";
        BankRecWorksheet: TestPage "Bank Rec. Worksheet";
    begin
        CreateBankRecWorksheet(BankRecLine, BankAccountNo);
        BankRecHeader.Get(BankRecLine."Bank Account No.", BankRecLine."Statement No.");
        Commit();
        BankRecWorksheet.OpenEdit;
        BankRecWorksheet.GotoRecord(BankRecHeader);
        BankRecWorksheet.SuggestLines.Invoke;  // Suggest Lines.
        BankRecWorksheet.MarkLines.Invoke;  // Mark Lines.
        BankRecHeader.CalcFields("G/L Balance (LCY)");
        BankRecHeader.Validate("Statement Balance", BankRecHeader."G/L Balance (LCY)");
        BankRecHeader.Modify(true);
    end;

    local procedure CreateBankAccount(var BankAccount: Record "Bank Account"; CurrencyCode: Code[10])
    var
        GLAccount: Record "G/L Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        BankAccountPostingGroup.FindFirst();
        BankAccountPostingGroup.Validate("G/L Account No.", GLAccount."No.");
        BankAccountPostingGroup.Modify(true);
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Validate("Bank Acc. Posting Group", BankAccountPostingGroup.Code);
        BankAccount.Validate("Last Statement No.", LibraryUtility.GenerateGUID());
        BankAccount.Modify(true);
    end;

    local procedure CreateBankAccRecnocilation(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; BankAccount: Record "Bank Account")
    begin
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccount."No.",
          BankAccReconciliation."Statement Type"::"Bank Reconciliation");
        BankAccReconciliation.Validate("Statement Date", WorkDate);
        BankAccReconciliation.Modify(true);
    end;

    local procedure CreateBankRecWorksheet(var BankRecLine: Record "Bank Rec. Line"; BankAccountNo: Code[20])
    var
        BankRecHeader: Record "Bank Rec. Header";
    begin
        LibraryERM.CreateBankRecHeader(BankRecHeader, BankAccountNo);
        LibraryERM.CreateBankRecLine(BankRecLine, BankRecHeader);
    end;

    local procedure CreateBankRecLineFromPage(BankRecHeader: Record "Bank Rec. Header"): Code[20]
    var
        BankRecWorksheet: TestPage "Bank Rec. Worksheet";
    begin
        BankRecWorksheet.OpenEdit;
        BankRecWorksheet.GotoRecord(BankRecHeader);
        BankRecWorksheet.AdjustmentsSubForm."Posting Date".SetValue(WorkDate);
        exit(BankRecWorksheet.AdjustmentsSubForm."Document No.".Value);
    end;

    local procedure CreateCurrency(var Currency: Record Currency)
    begin
        Currency.Get(LibraryERM.CreateCurrencyWithGLAccountSetup);
    end;

    local procedure CreateCurrencyExchangeRate(CurrencyCode: Code[10]; StartingDate: Date; MultiplicationFactor: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, StartingDate);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 10 + LibraryRandom.RandDec(100, 2));  // Validate any random Exchange Rate Amount greater than 10.
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount" * MultiplicationFactor);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateDefaultDimension(TableID: Integer; No: Code[20])
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, TableID, No, Dimension.Code, DimensionValue.Code);
        LibraryDimension.FindDefaultDimension(DefaultDimension, TableID, No);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Same Code");
        DefaultDimension.Modify(true);
    end;

    local procedure CreateDepositDocument(var DepositHeader: Record "Deposit Header"; AccountNo: Code[20]; AccountType: Option; SignFactor: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Deposits);
        CreateDepositHeader(DepositHeader, GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, DepositHeader."Journal Template Name", DepositHeader."Journal Batch Name", GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, LibraryRandom.RandInt(1000) * SignFactor);  // Using Random value for Deposit Amount.
    end;

    local procedure CreateDepositHeader(var DepositHeader: Record "Deposit Header"; GenJournalBatch: Record "Gen. Journal Batch")
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        LibrarySales.CreateDepositHeader(DepositHeader, GenJournalBatch);
        DepositHeader.Validate("Bank Account No.", BankAccount."No.");
        DepositHeader.Modify(true);
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; Type: Option)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, Type);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateMultilineDepositDocument(var DepositHeader: Record "Deposit Header"; AccountNo: Code[20]; AccountType: Option; AccountNo2: Code[20]; AccountType2: Option; DocumentType: Option)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Deposit Document WIth two line with different Account Type.
        CreateDepositDocument(DepositHeader, AccountNo, AccountType, -1);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, DepositHeader."Journal Template Name", DepositHeader."Journal Batch Name", DocumentType,
          AccountType2, AccountNo2, -LibraryRandom.RandInt(1000));  // Using Random value for Deposit Amount.
    end;

    local procedure CreatePaymentGenJournal(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Option; AccountNo: Code[20]; BalAccountNo: Code[20]; BankPaymentType: Option; Amount: Decimal; Type: Option; DocumentType: Option)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalBatch(GenJournalBatch, Type);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          AccountType, AccountNo, Amount);  // Using Random value for Deposit Amount.
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Validate("Bank Payment Type", BankPaymentType);
        GenJournalLine.Modify(true);
    end;

    local procedure PostGenJournalAndSalesOrder(BankAccountNo: Code[20]; CustomerNo: Code[20]): Code[20]
    var
        Item: Record Item;
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Create and Post General Journal.
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryInventory.CreateItem(Item);
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::"Bank Account", BankAccount."No.", BankAccountNo,
          GenJournalLine."Bank Payment Type"::" ", -LibraryRandom.RandInt(100), GenJournalTemplate.Type::General,
          GenJournalLine."Document Type"::Payment);

        // Create and Post Sales Order.
        exit(
          CreateAndPostSalesDocument(SalesLine, CustomerNo, SalesLine."Document Type"::Order, SalesLine.Type::Item, Item."No.",
            LibraryRandom.RandInt(10), LibraryRandom.RandDec(100, 2)));  // Using Random value for Quantity and Unit Price.
    end;

    local procedure PostPurchInvAndCrMemo(VendorNo: Code[20]; VATBusPostingGroup: Code[20]; PartialFactor: Decimal)
    var
        GLAccount: Record "G/L Account";
        PurchaseLine: Record "Purchase Line";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.FindGenProductPostingGroup(GenProductPostingGroup);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        GLAccount.Modify(true);
        CreateVATPostingSetup(VATBusPostingGroup, GLAccount."VAT Prod. Posting Group");
        CreateAndPostPurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Invoice, VendorNo, GLAccount."No.", PurchaseLine.Type::"G/L Account",
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(100));  // Using Random value for Quantity and Direct Unit Cost.
        CreateAndPostPurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::"Credit Memo", VendorNo, GLAccount."No.", PurchaseLine.Type::"G/L Account",
          PurchaseLine.Quantity / PartialFactor, PurchaseLine."Direct Unit Cost");
    end;

    local procedure SetupForDeposit(var BankRecLine: Record "Bank Rec. Line"; BankAccountNo: Code[20]; CustomerNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        BankRecHeader: Record "Bank Rec. Header";
        BankRecWorksheet: TestPage "Bank Rec. Worksheet";
    begin
        // Create and Post General Journal and Sales Order.
        PostGenJournalAndSalesOrder(BankAccountNo, CustomerNo);

        // Create and Post Cash Receipt Journal.
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CustomerNo, BankAccountNo,
          GenJournalLine."Bank Payment Type"::" ", -LibraryRandom.RandInt(100) / 2,
          GenJournalTemplate.Type::"Cash Receipts", GenJournalLine."Document Type"::Payment);  // Using Random value for Amount.

        // Create and Suggest Bank Reconcilation.
        CreateBankRecWorksheet(BankRecLine, BankAccountNo);
        BankRecHeader.Get(BankRecLine."Bank Account No.", BankRecLine."Statement No.");
        Commit();
        BankRecWorksheet.OpenEdit;
        BankRecWorksheet.GotoRecord(BankRecHeader);
        BankRecWorksheet.SuggestLines.Invoke;  // Suggest Lines.
        BankRecWorksheet.MarkLines.Invoke;  // Mark Lines.
    end;

    local procedure SetupAndPostDeposit(var DepositHeader: Record "Deposit Header"; GLAccountNo: Code[20]; VendorNo: Code[20]; BankAccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create Deposit Document with Account Type GL, Vendor and Bank.
        CreateMultilineDepositDocument(
          DepositHeader, GLAccountNo, GenJournalLine."Account Type"::"G/L Account", VendorNo, GenJournalLine."Account Type"::Vendor,
          GenJournalLine."Document Type"::Refund);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, DepositHeader."Journal Template Name", DepositHeader."Journal Batch Name", GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"Bank Account", BankAccountNo, -LibraryRandom.RandInt(1000));  // Using Random value for Deposit Amount.
        UpdateDepositHeaderWithAmount(DepositHeader);
        LibrarySales.PostDepositDocument(DepositHeader);
    end;

    local procedure SetupForDepostiWithDimension(var DepositHeader: Record "Deposit Header"; TableID: Integer; No: Code[20]; AccountType: Option; SignFactor: Integer)
    begin
        // Create Default Dimension, create Deposit Document and update Total Deposit Amount.
        CreateDefaultDimension(TableID, No);
        CreateDepositDocument(DepositHeader, No, AccountType, SignFactor);
        CreateDefaultDimension(DATABASE::"Bank Account", DepositHeader."Bank Account No.");
        UpdateDepositHeaderWithAmount(DepositHeader);
    end;

    local procedure SuggestBankReconLines(var BankAccReconciliation: Record "Bank Acc. Reconciliation"; BankAccount: Record "Bank Account")
    var
        SuggestBankAccReconLines: Report "Suggest Bank Acc. Recon. Lines";
    begin
        CreateBankAccRecnocilation(BankAccReconciliation, BankAccount);
        SuggestBankAccReconLines.SetStmt(BankAccReconciliation);
        SuggestBankAccReconLines.SetTableView(BankAccount);
        SuggestBankAccReconLines.InitializeRequest(WorkDate, WorkDate, true);  // Set TRUE for Include Checks Option.
        SuggestBankAccReconLines.UseRequestPage(false);
        SuggestBankAccReconLines.Run();
        Commit(); // Commit Required for Open Page.
    end;

    local procedure UpdateApplicationOnGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10]; AppliestoDocNo: Code[20]; DueDate: Date; Amount: Decimal)
    begin
        GenJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        GenJournalLine.FindFirst();
        GenJournalLine.Validate(Amount, Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliestoDocNo);
        GenJournalLine.Validate("Due Date", DueDate);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateBankRecLine(var BankRecLine: Record "Bank Rec. Line"; BankAccountNo: Code[20]; CustomerNo: Code[20])
    begin
        BankRecLine.Validate("Posting Date", CalcDate(Format(LibraryRandom.RandInt(20)) + 'D', WorkDate));
        BankRecLine.Validate("Document Type", BankRecLine."Document Type"::"Finance Charge Memo");
        BankRecLine.Validate("Account Type", BankRecLine."Account Type"::"Bank Account");
        BankRecLine.Validate("Account No.", BankAccountNo);
        BankRecLine.Validate("Bal. Account Type", BankRecLine."Bal. Account Type"::Customer);
        BankRecLine.Validate("Bal. Account No.", CustomerNo);
        BankRecLine.Validate(Amount, -LibraryRandom.RandInt(100));  // Using Random value for Amount.
        BankRecLine.Modify(true);
    end;

    local procedure UpdateDepositHeaderWithAmount(var DepositHeader: Record "Deposit Header")
    begin
        DepositHeader.CalcFields("Total Deposit Lines");
        DepositHeader.Validate("Total Deposit Amount", DepositHeader."Total Deposit Lines");
        DepositHeader.Modify(true);
    end;

    local procedure UpdateGenJournalLine(DepositHeader: Record "Deposit Header"; SalesLine: Record "Sales Line")
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesLine."Sell-to Customer No.");
        SalesInvoiceHeader.FindFirst();
        UpdateApplicationOnGenJournalLine(
          GenJournalLine, DepositHeader."Journal Template Name", DepositHeader."Journal Batch Name",
          SalesInvoiceHeader."No.", 0D, -SalesLine."Amount Including VAT");
    end;

    local procedure UpdateGenJournalTemplate(Name: Code[10]; ForceDocBalance: Boolean)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Get(Name);
        GenJournalTemplate.Validate("Force Doc. Balance", ForceDocBalance);
        GenJournalTemplate.Modify(true);
    end;

    local procedure UpdateGenLedgerSetup(CurrencyCode: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := CurrencyCode; // Validate is not required.
        GeneralLedgerSetup.Validate("Deposit Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        GeneralLedgerSetup.Validate("Bank Rec. Adj. Doc. Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure FindBankRecLine(var BankRecLine: Record "Bank Rec. Line"; BankAccountNo: Code[20])
    begin
        BankRecLine.SetRange("Bank Account No.", BankAccountNo);
        BankRecLine.FindFirst();
    end;

    local procedure VerifyBankAccLedgerEntryAmount(BankAccountNo: Code[20]; TotalDepositAmount: Decimal)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        Amount: Decimal;
    begin
        BankAccountLedgerEntry.SetRange("Bank Account No.", BankAccountNo);
        BankAccountLedgerEntry.FindSet();
        repeat
            Amount += BankAccountLedgerEntry.Amount;
        until BankAccountLedgerEntry.Next = 0;
        Assert.AreEqual(TotalDepositAmount, Amount, GLEntryError);
    end;

    local procedure VerifyGLEntry(BalAccountType: Option; Description: Text[50]; BalAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Bal. Account Type", BalAccountType);
        GLEntry.SetRange(Description, Description);
        GLEntry.SetFilter(
          "Document Type", '%1|%2', GLEntry."Document Type"::Payment, GLEntry."Document Type"::"Finance Charge Memo");
        GLEntry.FindFirst();
        GLEntry.TestField("Bal. Account No.", BalAccountNo);
    end;

    local procedure CallCheckPreview(var CheckPreview: TestPage "Check Preview"; GenJournalLine: Record "Gen. Journal Line")
    begin
        CheckPreview.OpenView;
        CheckPreview.FILTER.SetFilter("Journal Template Name", GenJournalLine."Journal Template Name");
        CheckPreview.FILTER.SetFilter("Journal Batch Name", GenJournalLine."Journal Batch Name");
        CheckPreview.FILTER.SetFilter("Line No.", Format(GenJournalLine."Line No."));
        CheckPreview.First;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AdjustExchangeRatesReqPageHandler(var AdjustExchangeRates: TestRequestPage "Adjust Exchange Rates")
    var
        CurrencyCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(CurrencyCode);
        AdjustExchangeRates.Currency.SetFilter(Code, CurrencyCode);
        AdjustExchangeRates.EndingDate.SetValue(CalcDate(Format(LibraryRandom.RandInt(5)) + 'M', WorkDate));  // 1 Using Random for No. of Months.
        AdjustExchangeRates.PostingDate.SetValue(WorkDate);
        AdjustExchangeRates.DocumentNo.SetValue(LibraryRandom.RandInt(1000));
        AdjustExchangeRates.AdjBankAcc.SetValue(true);
        AdjustExchangeRates.AdjCustAcc.SetValue(true);
        AdjustExchangeRates.AdjVendAcc.SetValue(true);
        AdjustExchangeRates.AdjGLAcc.SetValue(false);
        AdjustExchangeRates.OK.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalBatchesPageHandler(var GeneralJournalBatches: TestPage "General Journal Batches")
    begin
        GeneralJournalBatches.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalTemplateListPageHandler(var GeneralJournalTemplateList: TestPage "General Journal Template List")
    begin
        GeneralJournalTemplateList.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestAndMarkLinesHandler(var BankRecProcessLines: TestRequestPage "Bank Rec. Process Lines")
    begin
        BankRecProcessLines.RecordTypeToProcess.SetValue(BankRecProcessLines.RecordTypeToProcess.GetOption(3));  // Record Type to Process.
        BankRecProcessLines.MarkAsCleared.SetValue(true);
        BankRecProcessLines.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentRequestPageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    var
        BalAccountType: Enum "Gen. Journal Account Type";
        BankAccountNo: Variant;
        VendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        LibraryVariableStorage.Dequeue(BankAccountNo);
        SuggestVendorPayments.LastPaymentDate.SetValue(CalcDate(Format(LibraryRandom.RandInt(3)) + 'M', WorkDate));  // 1 Using Random for No. of Months.
        SuggestVendorPayments.PostingDate.SetValue(WorkDate);
        SuggestVendorPayments.SummarizePerVendor.SetValue(true);
        SuggestVendorPayments.StartingDocumentNo.SetValue(LibraryRandom.RandInt(1000));
        SuggestVendorPayments.BalAccountType.SetValue(BalAccountType::"Bank Account");
        SuggestVendorPayments.BalAccountNo.SetValue(BankAccountNo);
        SuggestVendorPayments.Vendor.SetFilter("No.", VendorNo);
        SuggestVendorPayments.OK.Invoke;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure NothingAdjustedMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(NothingToAdjustTxt, Message);
    end;
}

