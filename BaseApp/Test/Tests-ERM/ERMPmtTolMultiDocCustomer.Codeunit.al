codeunit 134023 "ERM Pmt Tol Multi Doc Customer"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Tolerance] [Sales]
        IsInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        AmountError: Label '%1 must be %2 in \\%3, %4=%5.';

    [Test]
    [HandlerFunctions('ApplyCustEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure OverPmtBeforeDiscDateLCY()
    begin
        // Covers documents TFS_TC_ID=126464, 126465, 126469, 124028.

        // Check Payment Discount and Amount LCY on Customer Ledger Entries after posting Journal Lines with more Amount and within Payment
        // Discount Period.
        Initialize;
        OverPmtBeforeDiscDate('', '');
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure OverPmtBeforeDiscDateFCY()
    var
        CurrencyCode: Code[10];
    begin
        // Covers documents TFS_TC_ID=126464, 126465, 126469, 126470, 124028.

        // Check Payment Discount and Amount LCY on Customer Ledger Entries after posting Journal Lines with more Amount and same Currency
        // and within Payment Discount Period.
        Initialize;
        CurrencyCode := CreateCurrency;
        OverPmtBeforeDiscDate(CurrencyCode, CurrencyCode);
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure OverPmtBeforeDiscDateMultiCur()
    begin
        // Covers documents TFS_TC_ID=126465, 126469, 126470, 124028.

        // Check Payment Discount and Amount LCY on Customer Ledger Entries after posting Journal Lines with more Amount and multiple
        // Currencies, within Payment Discount Period.
        Initialize;
        OverPmtBeforeDiscDate(CreateCurrency, CreateCurrency);
    end;

    local procedure OverPmtBeforeDiscDate(CurrencyCode: Code[10]; CurrencyCode2: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        Amount2: Decimal;
        NoOfLines: Integer;
    begin
        // Setup: Modify General Ledger Setup and Post Multiple Gen. Journal Lines for Invoice and Payment with
        // Random Amount. Take Payment Amount more than Invoice Amount and within Discount Period.
        GeneralLedgerSetup.Get;
        ModifyGeneralLedgerSetup;
        ComputeAmountAndNoOfLines(Amount, NoOfLines);
        Amount2 := Amount * NoOfLines + GeneralLedgerSetup."Max. Payment Tolerance Amount";
        PaymentWithDiscount(CurrencyCode, CurrencyCode2, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment,
          Amount, -Amount2, NoOfLines, GetDueDate);

        // Tear Down.
        CleanupGeneralLedgerSetup;
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntriesPageHandler,PaymentDiscTolPageHandler')]
    [Scope('OnPrem')]
    procedure OverPmtAfterDiscDateLCY()
    begin
        // Covers documents TFS_TC_ID=126464,126471, 126475, 124029.

        // Check Payment Discount and Amount LCY on Customer Ledger Entries after posting Journal Lines with more Amount and after Payment
        // Discount Period.
        Initialize;
        OverPmtAfterDiscDate('', '');
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntriesPageHandler,PaymentDiscTolPageHandler')]
    [Scope('OnPrem')]
    procedure OverPmtAfterDiscDateFCY()
    var
        CurrencyCode: Code[10];
    begin
        // Covers documents TFS_TC_ID=126464, 126471, 126475, 124029, 124033.

        // Check Payment Discount and Amount LCY on Customer Ledger Entries after posting Journal Lines with more Amount and same Currency
        // and after Payment Discount Period..
        Initialize;
        CurrencyCode := CreateCurrency;
        OverPmtAfterDiscDate(CurrencyCode, CurrencyCode);
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntriesPageHandler,PaymentDiscTolPageHandler')]
    [Scope('OnPrem')]
    procedure OverPmtAfterDiscDateMultiCur()
    begin
        // Covers documents TFS_TC_ID=126464, 126471, 126475, 124029, 124033.

        // Check Payment Discount and Amount LCY on Customer Ledger Entries after posting Journal Lines with more Amount and multiple
        // Currencies, after Payment Discount Period..
        Initialize;
        OverPmtAfterDiscDate(CreateCurrency, CreateCurrency);
    end;

    local procedure OverPmtAfterDiscDate(CurrencyCode: Code[10]; CurrencyCode2: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        Amount2: Decimal;
        NoOfLines: Integer;
    begin
        // Setup: Modify General Ledger Setup and Post Multiple Gen. Journal Lines for Invoice and
        // Payment with Random Amount. Take Payment Amount more than Invoice Amount and after Discount Period.
        GeneralLedgerSetup.Get;
        ModifyGeneralLedgerSetup;
        ComputeAmountAndNoOfLines(Amount, NoOfLines);
        Amount2 := Amount * NoOfLines + GeneralLedgerSetup."Max. Payment Tolerance Amount";
        PaymentWithDiscountTolerance(CurrencyCode, CurrencyCode2, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Document Type"::Payment, Amount, -Amount2, NoOfLines, CalcDate('<1D>', GetDueDate));

        // Tear Down.
        CleanupGeneralLedgerSetup;
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure EqualPmtBeforeDiscDateLCY()
    begin
        // Covers documents TFS_TC_ID=126464, 126466, 124030.

        // Check Payment Discount and Amount LCY on Customer Ledger Entries after posting Journal Lines with equal Payment Amount and
        // within Payment Discount Period.
        Initialize;
        EqualPmtBeforeDiscDate('', '');
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure EqualPmtBeforeDiscDateFCY()
    var
        CurrencyCode: Code[10];
    begin
        // Covers documents TFS_TC_ID=126464, 126466, 124030.

        // Check Payment Discount and Amount LCY on Customer Ledger Entries after posting Journal Lines with equal Payment Amount
        // and same Currency, within Payment Discount Period.
        Initialize;
        CurrencyCode := CreateCurrency;
        EqualPmtBeforeDiscDate(CurrencyCode, CurrencyCode);
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure EqualPmtBeforeDiscDateMultiCur()
    begin
        // Covers documents TFS_TC_ID=126464, 126466, 124030.

        // Check Payment Discount and Amount LCY on Customer Ledger Entries after posting Journal Lines with equal Payment Amount
        // and same Currency, within Payment Discount Period.
        Initialize;
        EqualPmtBeforeDiscDate(CreateCurrency, CreateCurrency);
    end;

    local procedure EqualPmtBeforeDiscDate(CurrencyCode: Code[10]; CurrencyCode2: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        NoOfLines: Integer;
    begin
        // Setup: Modify General Ledger Setup and Post Gen. Journal Lines for Invoice and Payment with Random Amount.
        // Take Payment Amount equal to Invoice Amount and within Discount Period. Use different currency for Invoice and Payment.
        ModifyGeneralLedgerSetup;
        ComputeAmountAndNoOfLines(Amount, NoOfLines);
        PaymentWithDiscount(CurrencyCode, CurrencyCode2, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment,
          Amount, -Amount * NoOfLines, NoOfLines, GetDueDate);

        // Tear Down.
        CleanupGeneralLedgerSetup;
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntriesPageHandler,PaymentDiscTolPageHandler')]
    [Scope('OnPrem')]
    procedure EqualPmtAfterDueDateLCY()
    begin
        // Covers documents TFS_TC_ID=126464, 126472, 126476, 124031, 124035.

        // Check Payment Discount and Amount LCY on Customer Ledger Entries after posting Journal Lines with equal Payment Amount and after
        // Payment Discount Period.
        Initialize;
        EqualPmtAfterDueDate('', '');
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntriesPageHandler,PaymentDiscTolPageHandler')]
    [Scope('OnPrem')]
    procedure EqualPmtAfterDueDateFCY()
    var
        CurrencyCode: Code[10];
    begin
        // Covers documents TFS_TC_ID=126464, 126472, 136476, 124031, 124035.

        // Check Payment Discount and Amount LCY on Customer Ledger Entries after posting Journal Lines with equal Payment Amount
        // and same Currency and after Payment Discount Period.
        Initialize;
        CurrencyCode := CreateCurrency;
        EqualPmtAfterDueDate(CurrencyCode, CurrencyCode);
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntriesPageHandler,PaymentDiscTolPageHandler')]
    [Scope('OnPrem')]
    procedure EqualPmtAfterDueDateMultiCur()
    begin
        // Covers documents TFS_TC_ID=126464, 126472, 126476, 124031, 124035.

        // Check Payment Discount and Amount LCY on Customer Ledger Entries after posting Journal Lines with equal Payment Amount
        // and different Currencies and after Payment Discount Period.
        Initialize;
        EqualPmtAfterDueDate(CreateCurrency, CreateCurrency);
    end;

    local procedure EqualPmtAfterDueDate(CurrencyCode: Code[10]; CurrencyCode2: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        NoOfLines: Integer;
    begin
        // Setup: Modify General Ledger Setup and Post Gen. Journal Lines for Invoice and Payment with Random Amount.
        // and after Discount Period. Take Payment Amount equal to Invoice Amount.
        ModifyGeneralLedgerSetup;
        ComputeAmountAndNoOfLines(Amount, NoOfLines);
        PaymentWithDiscountTolerance(CurrencyCode, CurrencyCode2, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Document Type"::Payment, Amount, -Amount * NoOfLines, NoOfLines, CalcDate('<1D>', GetDueDate));

        // Tear Down.
        CleanupGeneralLedgerSetup;
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntriesPageHandler,PaymentTolerancePageHandler')]
    [Scope('OnPrem')]
    procedure LessPmtBeforeDiscDateLCY()
    begin
        // Covers documents TFS_TC_ID=126464, 126467, 124032.

        // Check Payment Discount Tolerance, Amount LCY on Customer Ledger Entries after Posting Journal Lines with Less Amount and within
        // within Payment Discount Period.
        Initialize;
        LessPmtBeforeDiscDate('', '');
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntriesPageHandler,PaymentTolerancePageHandler')]
    [Scope('OnPrem')]
    procedure LessPmtBeforeDiscDateFCY()
    var
        CurrencyCode: Code[10];
    begin
        // Covers documents TFS_TC_ID=126464, 126467, 124032.

        // Check Payment Discount Tolerance, Amount LCY on Customer Ledger Entries after Posting Journal Lines with Less Amount and same
        // Currency and within discount period.
        Initialize;
        CurrencyCode := CreateCurrency;
        LessPmtBeforeDiscDate(CurrencyCode, CurrencyCode);
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntriesPageHandler,PaymentTolerancePageHandler')]
    [Scope('OnPrem')]
    procedure LessPmtBeforeDiscDateMultiCur()
    begin
        // Covers documents TFS_TC_ID=126464, 126467, 124032.

        // Check Payment Discount Tolerance, Amount LCY on Customer Ledger Entries after Posting Journal Lines with Less Amount and with
        // different Currencies and within Payment Discount Period.
        Initialize;
        LessPmtBeforeDiscDate(CreateCurrency, CreateCurrency);
    end;

    local procedure LessPmtBeforeDiscDate(CurrencyCode: Code[10]; CurrencyCode2: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        Amount2: Decimal;
        NoOfLines: Integer;
    begin
        // Setup: Modify General Ledger Setup and Post Gen. Journal Lines for Invoice and Payment with Random Amount.
        // Take Payment Amount less than Invoice Amount and within Discount Period. Post Payment Lines in Payment Discount Grace Period.
        ModifyGeneralLedgerSetup;
        ComputeAmountFromMaxPmtTol(Amount, Amount2, NoOfLines);
        PaymentWithTolerance(CurrencyCode, CurrencyCode2, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment,
          Amount, -Amount2, NoOfLines, GetDueDate);

        // Tear Down.
        CleanupGeneralLedgerSetup;
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntriesPageHandler,PaymentDiscTolPageHandler,PaymentTolerancePageHandler')]
    [Scope('OnPrem')]
    procedure LessPmtAfterDiscDateLCY()
    begin
        // Covers documents TFS_TC_ID=126464, 126473, 124033.

        // Check Payment Discount Tolerance, Amount LCY on Customer Ledger Entries after Posting Journal Lines with Less Amount and after
        // Payment Discount Period.
        Initialize;
        LessPmtAfterDiscDate('', '');
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntriesPageHandler,PaymentDiscTolPageHandler,PaymentTolerancePageHandler')]
    [Scope('OnPrem')]
    procedure LessPmtAfterDiscDateFCY()
    var
        CurrencyCode: Code[10];
    begin
        // Covers documents TFS_TC_ID=126464, 126473, 124033.

        // Check Payment Discount Tolerance, Amount LCY on Customer Ledger Entries after Posting Journal Lines with Less Amount
        // and same Currency and after Payment Discount Period.
        Initialize;
        CurrencyCode := CreateCurrency;
        LessPmtAfterDiscDate(CurrencyCode, CurrencyCode);
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntriesPageHandler,PaymentDiscTolPageHandler,PaymentTolerancePageHandler')]
    [Scope('OnPrem')]
    procedure LessPmtAfterDiscDateMultiCur()
    begin
        // Covers documents TFS_TC_ID=126464, 126473, 124033.

        // Check Payment Discount Tolerance, Amount LCY on Customer Ledger Entries after Posting Journal Lines with Less Amount and with
        // different Currencies and after Payment Discount Period.
        Initialize;
        LessPmtAfterDiscDate(CreateCurrency, CreateCurrency);
    end;

    local procedure LessPmtAfterDiscDate(CurrencyCode: Code[10]; CurrencyCode2: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        Amount2: Decimal;
        NoOfLines: Integer;
    begin
        // Setup: Modify General Ledger Setup and Post Gen. Journal Lines for Invoice and Payment with Random Amount.
        // Take Payment Amount less than Invoice Amount. Post Payment Lines after Payment Discount Grace Period.
        ModifyGeneralLedgerSetup;
        ComputeAmountFromMaxPmtTol(Amount, Amount2, NoOfLines);
        PaymentWithDiscountTolerance(CurrencyCode, CurrencyCode2, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Document Type"::Payment, Amount, -Amount2, NoOfLines, CalcDate('<1D>', GetDueDate));

        // Tear Down.
        CleanupGeneralLedgerSetup;
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntriesPageHandler,PaymentTolerancePageHandler')]
    [Scope('OnPrem')]
    procedure UnderAmtBeforeDiscDateLCY()
    begin
        // Covers documents TFS_TC_ID=126464, 126468, 124036, 124037.

        // Check Payment Tolerance, Amount LCY on Customer Ledger Entries after Posting Journal Lines with Less Amount and within Payment
        // Discount Period.
        Initialize;
        UnderAmtBeforeDiscDate('', '');
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntriesPageHandler,PaymentTolerancePageHandler')]
    [Scope('OnPrem')]
    procedure UnderAmtBeforeDiscDateFCY()
    var
        CurrencyCode: Code[10];
    begin
        // Covers documents TFS_TC_ID=126464, 126468, 124036, 124037.

        // Check Payment Tolerance, Amount LCY on Customer Ledger Entries after Posting Journal Lines with Less Amount and Currency
        // within Payment Discount Period.
        Initialize;
        CurrencyCode := CreateCurrency;
        UnderAmtBeforeDiscDate(CurrencyCode, CurrencyCode);
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntriesPageHandler,PaymentTolerancePageHandler')]
    [Scope('OnPrem')]
    procedure UnderAmtBeforeDiscDateMultiCur()
    begin
        // Covers documents TFS_TC_ID=126464, 126468, 124036, 124037.

        // Check Payment Tolerance, Amount LCY on Customer Ledger Entries after Posting Journal Lines with Less Amount and multiple
        // Currencies and within Payment Discount Period.
        Initialize;
        UnderAmtBeforeDiscDate(CreateCurrency, CreateCurrency);
    end;

    local procedure UnderAmtBeforeDiscDate(CurrencyCode: Code[10]; CurrencyCode2: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        Amount2: Decimal;
        NoOfLines: Integer;
    begin
        // Setup: Modify General Ledger Setup and Post Gen. Journal Lines for Invoice and Payment with Random Amount.
        // Take Payment Amount less than Invoice Amount and within Discount Period.
        ModifyGeneralLedgerSetup;
        ComputeAmountFromPmtTolPercent(Amount, Amount2, NoOfLines);
        PaymentWithTolerance(CurrencyCode, CurrencyCode2, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment,
          Amount, -Amount2, NoOfLines, GetDueDate);

        // Tear Down.
        CleanupGeneralLedgerSetup;
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntriesPageHandler,PaymentDiscTolPageHandler,PaymentTolerancePageHandler')]
    [Scope('OnPrem')]
    procedure UnderAmtAfterDiscDateLCY()
    begin
        // Covers documents TFS_TC_ID=126464, 126474, 126477, 124038.

        // Check Payment Tolerance, Amount LCY on Customer Ledger Entries after Posting Journal Lines with Less Amount after Payment
        // Discount Period.
        Initialize;
        UnderAmtAfterDiscDate('', '');
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntriesPageHandler,PaymentDiscTolPageHandler,PaymentTolerancePageHandler')]
    [Scope('OnPrem')]
    procedure UnderAmtAfterDiscDateFCY()
    var
        CurrencyCode: Code[10];
    begin
        // Covers documents TFS_TC_ID=126464, 126474, 126477, 124038.

        // Check Payment Tolerance, Amount LCY on Customer Ledger Entries after Posting Journal Lines with Less Amount and Same Currency
        // after Payment Discount Period.
        Initialize;
        CurrencyCode := CreateCurrency;
        UnderAmtAfterDiscDate(CurrencyCode, CurrencyCode);
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntriesPageHandler,PaymentDiscTolPageHandler,PaymentTolerancePageHandler')]
    [Scope('OnPrem')]
    procedure UnderAmtAfterDiscDateMultiCur()
    begin
        // Covers documents TFS_TC_ID=126464, 126474, 126477, 124038.

        // Check Payment Tolerance, Amount LCY on Customer Ledger Entries after Posting Journal Lines with Less Amount and multiple
        // Currencies.
        Initialize;
        UnderAmtAfterDiscDate(CreateCurrency, CreateCurrency);
    end;

    local procedure UnderAmtAfterDiscDate(CurrencyCode: Code[10]; CurrencyCode2: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        Amount2: Decimal;
        NoOfLines: Integer;
    begin
        // Modify General Ledger Setup and Post Gen. Journal Lines for Invoice and Payment with Random Amount.
        // Take Payment Amount less than Invoice Amount and after Discount Period.
        ModifyGeneralLedgerSetup;
        ComputeAmountFromPmtTolPercent(Amount, Amount2, NoOfLines);
        PaymentWithDiscountTolerance(CurrencyCode, CurrencyCode2, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Document Type"::Payment, Amount, -Amount2, NoOfLines, CalcDate('<1D>', GetDueDate));

        // Tear Down.
        CleanupGeneralLedgerSetup;
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Pmt Tol Multi Doc Customer");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Pmt Tol Multi Doc Customer");
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibraryERMCountryData.UpdateGeneralLedgerSetup;

        IsInitialized := true;
        Commit;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Pmt Tol Multi Doc Customer");
    end;

    local procedure PaymentWithDiscount(CurrencyCode: Code[10]; CurrencyCode2: Code[10]; DocumentType: Option; DocumentType2: Option; Amount: Decimal; Amount2: Decimal; NoOfLines: Integer; PostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        PmtDiscount: Decimal;
    begin
        // Exercise: Create and Post General Journal Lines with Random Amount. Apply the later created Journal Line on previously created
        // Journal Lines and Post them. Take Posting Date in Payment Discount Period.
        CreateDocumentLine(GenJournalLine, DocumentType, CreateCustomer, CurrencyCode, Amount, WorkDate, NoOfLines);
        SaveGenJnlLineInTempTable(TempGenJournalLine, GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        CreateDocumentLine(GenJournalLine, DocumentType2, GenJournalLine."Account No.", CurrencyCode2, Amount2, PostingDate, 1);
        ApplyAndPostJournalLines(GenJournalLine, DocumentType);

        // Verify: Verify Vendor Ledger Entry, Detailed Vendor Ledger Entry and G/L Entry.
        PmtDiscount := GetAmountFCY(CurrencyCode2, GetDiscountAmount(Amount * NoOfLines));
        VerifyCustomerLedgerEntry(TempGenJournalLine, GetDiscountAmount(Amount));
        VerifyDetldCustomerLedgerEntry(
          GenJournalLine."Document No.", DocumentType2, DetailedCustLedgEntry."Entry Type"::"Payment Discount",
          -PmtDiscount);
    end;

    local procedure PaymentWithTolerance(CurrencyCode: Code[10]; CurrencyCode2: Code[10]; DocumentType: Option; DocumentType2: Option; Amount: Decimal; Amount2: Decimal; NoOfLines: Integer; PostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        PmtTolAmount: Decimal;
    begin
        // Exercise: Create and Post General Journal Lines with Random Amount. Apply the later created Journal Line on previously created
        // Journal Lines and Post them. Take Posting Date within Payment Discount Period.
        CreateDocumentLine(GenJournalLine, DocumentType, CreateCustomer, CurrencyCode, Amount, WorkDate, NoOfLines);
        SaveGenJnlLineInTempTable(TempGenJournalLine, GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        CreateDocumentLine(GenJournalLine, DocumentType2, GenJournalLine."Account No.", CurrencyCode2, Amount2, PostingDate, 1);
        ApplyAndPostJournalLines(GenJournalLine, DocumentType);

        // Verify: Verify Vendor Ledger Entry, Detailed Vendor Ledger Entry.
        PmtTolAmount := GetAmountFCY(CurrencyCode2, Amount2 + (Amount * NoOfLines - GetDiscountAmount(Amount * NoOfLines)));
        VerifyCustomerLedgerEntry(TempGenJournalLine, GetDiscountAmount(Amount));
        VerifyDetldCustomerLedgerEntry(GenJournalLine."Document No.", DocumentType2,
          DetailedCustLedgEntry."Entry Type"::"Payment Tolerance", -PmtTolAmount);
    end;

    local procedure PaymentWithDiscountTolerance(CurrencyCode: Code[10]; CurrencyCode2: Code[10]; DocumentType: Option; DocumentType2: Option; Amount: Decimal; Amount2: Decimal; NoOfLines: Integer; PostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        PmtTolAmount: Decimal;
    begin
        // Exercise: Create and Post General Journal Lines with Random Amount. Apply the later created Journal Line on previously created
        // Journal Lines and Post them. Take Posting Date after Payment Discount Period.
        CreateDocumentLine(GenJournalLine, DocumentType, CreateCustomer, CurrencyCode, Amount, WorkDate, NoOfLines);
        SaveGenJnlLineInTempTable(TempGenJournalLine, GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        CreateDocumentLine(GenJournalLine, DocumentType2, GenJournalLine."Account No.", CurrencyCode2, Amount2, PostingDate, 1);
        ApplyAndPostJournalLines(GenJournalLine, DocumentType);

        // Verify: Verify Vendor Ledger Entry, Detailed Vendor Ledger Entry and G/L Entry.
        PmtTolAmount := GetAmountFCY(CurrencyCode2, GetDiscountAmount(Amount * NoOfLines));
        VerifyCustomerLedgerEntry(TempGenJournalLine, GetDiscountAmount(Amount));
        VerifyDetldCustomerLedgerEntry(GenJournalLine."Document No.", DocumentType2,
          DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance", -PmtTolAmount);
    end;

    local procedure ModifyGeneralLedgerSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Take Payment Discount Grace Period: 5D. Payment Tolerance %: 1 and Max Payment Tolerance Amount: 5 (Standard Values).
        GeneralLedgerSetup.Get;
        Evaluate(GeneralLedgerSetup."Payment Discount Grace Period", '<5D>');
        GeneralLedgerSetup.Validate("Payment Tolerance %", 1);
        GeneralLedgerSetup.Validate("Max. Payment Tolerance Amount", 5);
        GeneralLedgerSetup.Validate(
          "Pmt. Disc. Tolerance Posting", GeneralLedgerSetup."Pmt. Disc. Tolerance Posting"::"Payment Discount Accounts");
        GeneralLedgerSetup.Validate(
          "Payment Tolerance Posting", GeneralLedgerSetup."Payment Tolerance Posting"::"Payment Discount Accounts");
        GeneralLedgerSetup.Validate("Pmt. Disc. Tolerance Warning", true);
        GeneralLedgerSetup.Validate("Payment Tolerance Warning", true);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure CleanupGeneralLedgerSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Cleanup of the Setups done.
        GeneralLedgerSetup.Get;
        Evaluate(GeneralLedgerSetup."Payment Discount Grace Period", '');
        GeneralLedgerSetup.Validate("Payment Tolerance %", 0);
        GeneralLedgerSetup.Validate("Max. Payment Tolerance Amount", 0);
        GeneralLedgerSetup.Validate(
          "Pmt. Disc. Tolerance Posting", GeneralLedgerSetup."Pmt. Disc. Tolerance Posting"::"Payment Tolerance Accounts");
        GeneralLedgerSetup.Validate(
          "Payment Tolerance Posting", GeneralLedgerSetup."Payment Tolerance Posting"::"Payment Tolerance Accounts");
        GeneralLedgerSetup.Validate("Pmt. Disc. Tolerance Warning", false);
        GeneralLedgerSetup.Validate("Payment Tolerance Warning", false);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure CreateDocumentLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Option; CustomerNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal; DocumentDate: Date; NoOfLines: Integer)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Counter: Integer;
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        for Counter := 1 to NoOfLines do
            CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, DocumentType, Amount, CustomerNo, IncStr(GenJournalLine."Document No."),
              CurrencyCode, DocumentDate);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Option; Amount: Decimal; CustomerNo: Code[20]; DocumentNo: Code[20]; CurrencyCode: Code[10]; PostingDate: Date)
    begin
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Posting Date", PostingDate);
        if DocumentNo <> '' then
            GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Modify(true);
    end;

    local procedure SaveGenJnlLineInTempTable(var TempGenJournalLine: Record "Gen. Journal Line" temporary; GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.FindSet;
        repeat
            TempGenJournalLine := GenJournalLine;
            TempGenJournalLine.Insert;
        until GenJournalLine.Next = 0;
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", GetPaymentTerms);
        Customer.Modify(true);
        UpdateCustomerPostingGroup(Customer."Customer Posting Group");
        exit(Customer."No.");
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        // Create Currency with Payment Tolerance %: 1 and Max. Payment Tolerance Amount: 5 (Standard Values).
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Payment Tolerance %", 1);
        Currency.Validate("Max. Payment Tolerance Amount", 5);
        Currency.Validate("Residual Gains Account", Currency."Realized Gains Acc.");
        Currency.Validate("Residual Losses Account", Currency."Realized Losses Acc.");
        Currency.Modify(true);

        // Create Exchange Rate.
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure UpdateCustomerPostingGroup(PostingGroupCode: Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        GLAccount: Record "G/L Account";
    begin
        CustomerPostingGroup.Get(PostingGroupCode);
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.SetRange(Blocked, false);
        GLAccount.FindSet;
        CustomerPostingGroup.Validate("Payment Disc. Debit Acc.", GLAccount."No.");
        CustomerPostingGroup.Validate("Payment Disc. Credit Acc.", GLAccount."No.");
        GLAccount.Next;
        CustomerPostingGroup.Validate("Payment Tolerance Debit Acc.", GLAccount."No.");
        CustomerPostingGroup.Validate("Payment Tolerance Credit Acc.", GLAccount."No.");
        CustomerPostingGroup.Modify(true);
    end;

    local procedure ComputeAmountAndNoOfLines(var Amount: Decimal; var NoOfLines: Integer)
    begin
        NoOfLines := 1 + LibraryRandom.RandInt(5);
        Amount := 10 * LibraryRandom.RandInt(100);
    end;

    local procedure ComputeAmountFromPmtTolPercent(var Amount: Decimal; var Amount2: Decimal; var NoOfLines: Integer)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // To Calculate Payment value using "Payment Tolerance %" from General Ledger Setup.
        GeneralLedgerSetup.Get;
        NoOfLines := 1 + LibraryRandom.RandInt(5);
        Amount := LibraryRandom.RandInt(499);
        Amount2 := Amount * NoOfLines - ((Amount * NoOfLines) * GeneralLedgerSetup."Payment Tolerance %" / 100);
    end;

    local procedure ComputeAmountFromMaxPmtTol(var Amount: Decimal; var Amount2: Decimal; var NoOfLines: Integer)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // To Calculate Payment value using "Max. Payment Tolerance Amount" from General Ledger Setup.
        GeneralLedgerSetup.Get;
        NoOfLines := 1 + LibraryRandom.RandInt(5);
        Amount := 500 * LibraryRandom.RandInt(10);
        Amount2 :=
          Amount * NoOfLines - (GeneralLedgerSetup."Max. Payment Tolerance Amount" + (Amount * NoOfLines * GetDiscountPercent / 100));
    end;

    local procedure ApplyAndPostJournalLines(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Option)
    var
        GLRegister: Record "G/L Register";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJnlApply: Codeunit "Gen. Jnl.-Apply";
        CustEntrySetApplID: Codeunit "Cust. Entry-SetAppl.ID";
        ApplyCustomerEntries: Page "Apply Customer Entries";
    begin
        GLRegister.FindLast;
        CustLedgerEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.FindSet;
        repeat
            CustEntrySetApplID.SetApplId(CustLedgerEntry, CustLedgerEntry, GenJournalLine."Document No.");
            ApplyCustomerEntries.CalcApplnAmount;
        until CustLedgerEntry.Next = 0;
        Commit;
        GenJnlApply.Run(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure GetDueDate(): Date
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Get(GetPaymentTerms);
        exit(CalcDate(PaymentTerms."Discount Date Calculation", WorkDate));
    end;

    local procedure GetDiscountPercent(): Decimal
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Get(GetPaymentTerms);
        exit(PaymentTerms."Discount %");
    end;

    local procedure GetDiscountAmount(Amount: Decimal): Decimal
    begin
        exit(Amount * GetDiscountPercent / 100);
    end;

    local procedure GetPaymentTerms(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        if not PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" then begin
            PaymentTerms.Validate("Calc. Pmt. Disc. on Cr. Memos", true);
            PaymentTerms.Modify(true);
        end;
        exit(PaymentTerms.Code);
    end;

    local procedure GetAmountFCY(CurrencyCode: Code[10]; Amount: Decimal): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        if CurrencyCode = '' then
            exit(Amount);
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst;
        exit(Amount * CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount");
    end;

    [Normal]
    local procedure VerifyCustomerLedgerEntry(var TempGenJournalLine: Record "Gen. Journal Line" temporary; OriginalPmtDiscPossible: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Verify Payment Discount Amount in Customer Ledger Entry.
        GeneralLedgerSetup.Get;
        TempGenJournalLine.FindSet;
        repeat
            CustLedgerEntry.SetRange("Document No.", TempGenJournalLine."Document No.");
            CustLedgerEntry.FindFirst;
            Assert.AreNearlyEqual(
              OriginalPmtDiscPossible, CustLedgerEntry."Original Pmt. Disc. Possible", GeneralLedgerSetup."Amount Rounding Precision",
              StrSubstNo(AmountError, CustLedgerEntry.FieldCaption("Original Pmt. Disc. Possible"), OriginalPmtDiscPossible,
                CustLedgerEntry.TableCaption, CustLedgerEntry.FieldCaption("Entry No."), CustLedgerEntry."Entry No."));
        until TempGenJournalLine.Next = 0;
    end;

    local procedure VerifyDetldCustomerLedgerEntry(DocumentNo: Code[20]; DocumentType: Option; EntryType: Option; AmountLCY: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Verify Amount LCY for Various Entries in Detailed Customer Ledger Entry.
        GeneralLedgerSetup.Get;
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.SetRange("Document Type", DocumentType);
        DetailedCustLedgEntry.SetRange("Entry Type", EntryType);
        DetailedCustLedgEntry.FindFirst;
        Assert.AreNearlyEqual(AmountLCY, DetailedCustLedgEntry."Amount (LCY)", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, DetailedCustLedgEntry.FieldCaption("Amount (LCY)"), AmountLCY, DetailedCustLedgEntry.TableCaption,
            DetailedCustLedgEntry.FieldCaption("Entry No."), DetailedCustLedgEntry."Entry No."));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentTolerancePageHandler(var PaymentToleranceWarning: Page "Payment Tolerance Warning"; var Response: Action)
    begin
        // Set Integer Value 1 for option "Post Balance for Payment Discount" on Tolerance Warning page.
        PaymentToleranceWarning.InitializeOption(1);
        Response := ACTION::Yes;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentDiscTolPageHandler(var PaymentDiscToleranceWarning: Page "Payment Disc Tolerance Warning"; var Response: Action)
    begin
        // Set Integer Value 1 for option "Post as Payment Disc. Tolerance" on Tolerance Warning page.
        PaymentDiscToleranceWarning.InitializeNewPostingAction(1);
        Response := ACTION::Yes;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustEntriesPageHandler(var ApplyCustomerEntries: Page "Apply Customer Entries"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;
}

