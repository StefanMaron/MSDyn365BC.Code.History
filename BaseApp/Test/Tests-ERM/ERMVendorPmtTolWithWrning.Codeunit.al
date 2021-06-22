codeunit 134016 "ERM Vendor Pmt Tol With Wrning"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Tolerance] [Purchase]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        AmountError: Label '%1 must be %2 in %3.';

    [Test]
    [Scope('OnPrem')]
    procedure OverPmtWithDisountLCY()
    begin
        // Covers documents TFS_TC_ID=124390,124391.

        // Check Payment Tolerance on various entries after Post General Lines with more Amount and Same Posting Date.
        Initialize;
        OverPmtWithDiscount('', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OverPmtWithDiscountFCY()
    var
        CurrencyCode: Code[10];
    begin
        // Covers documents TFS_TC_ID=124390,124391.

        // Check Payment Tolerance on various entries after Post General Lines with more Amount and Same Posting Date with Currency.
        Initialize;
        CurrencyCode := CreateCurrency;
        OverPmtWithDiscount(CurrencyCode, CurrencyCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OverPmtWithDiscountMultiCur()
    begin
        // Covers documents TFS_TC_ID=124390,124391.

        // Check Payment Tolerance on various entries after Post General Lines with more Amount and Same Posting Date with New Currency.
        Initialize;
        OverPmtWithDiscount(CreateCurrency, CreateCurrency);
    end;

    local procedure OverPmtWithDiscount(CurrencyCode1: Code[10]; CurrencyCode2: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        Amount2: Decimal;
    begin
        // Modify General Ledger Setup and Post Gen. Journal Lines for Invoice/Credit Memo and Payment/Refund
        // with Random Amount.
        LibraryPmtDiscSetup.SetPmtTolerance(1);

        GeneralLedgerSetup.Get();
        Amount := 10 * LibraryRandom.RandInt(100);
        Amount2 := Amount + GeneralLedgerSetup."Max. Payment Tolerance Amount";

        PaymentWithDiscount(
          CurrencyCode1, CurrencyCode2, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Document Type"::Refund, Amount, -Amount2);
        PaymentWithDiscount(
          CurrencyCode1, CurrencyCode2, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -Amount, Amount2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EqualPmtWithDisountLCY()
    begin
        // Covers documents TFS_TC_ID=124390,124392.

        // Check Payment Tolerance on various entries after Post General Lines with more Amount and Same Posting Date.
        Initialize;
        EqualPmtWithDiscount('', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EqualPmtWithDisountFCY()
    var
        CurrencyCode: Code[10];
    begin
        // Covers documents TFS_TC_ID=124390,124392.

        // Check Payment Tolerance on various entries after Post General Lines with more Amount and Same Posting Date with Currency.
        Initialize;
        CurrencyCode := CreateCurrency;
        EqualPmtWithDiscount(CurrencyCode, CurrencyCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EqualPmtWithDisountMultiCur()
    begin
        // Covers documents TFS_TC_ID=124390,124392.

        // Check Payment Tolerance on various entries after Post General Lines with more Amount and Same Posting Date with New Currency.
        Initialize;
        EqualPmtWithDiscount(CreateCurrency, CreateCurrency);
    end;

    local procedure EqualPmtWithDiscount(CurrencyCode1: Code[10]; CurrencyCode2: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // Modify General Ledger Setup and Post Gen. Journal Lines for Invoice/Credit Memo and Payment/Refund
        // with Random Amount.
        LibraryPmtDiscSetup.SetPmtTolerance(1);
        Amount := 10 * LibraryRandom.RandInt(100);

        PaymentWithDiscount(
          CurrencyCode1, CurrencyCode2, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Document Type"::Refund, Amount, -Amount);
        PaymentWithDiscount(
          CurrencyCode1, CurrencyCode2, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -Amount, Amount);
    end;

    [Test]
    [HandlerFunctions('PaymentDiscTolPageHandler,PaymentTolerancePageHandler')]
    [Scope('OnPrem')]
    procedure LessPmtWithToleranceLCY()
    begin
        // Covers documents TFS_TC_ID=124390,124401,124402,124403.

        // Check Payment Tolerance on various entries after Post General Lines with Less Amount and After Posting Date.
        Initialize;
        LessPmtWithTolerance('', '');
    end;

    [Test]
    [HandlerFunctions('PaymentDiscTolPageHandler,PaymentTolerancePageHandler')]
    [Scope('OnPrem')]
    procedure LessPmtWithToleranceFCY()
    var
        CurrencyCode: Code[10];
    begin
        // Covers documents TFS_TC_ID=124390,124401,124402,124403.

        // Check Payment Tolerance on various entries after Post General Lines with Less Amount and After Posting Date with Currency.
        Initialize;
        CurrencyCode := CreateCurrency;
        LessPmtWithTolerance(CurrencyCode, CurrencyCode);
    end;

    [Test]
    [HandlerFunctions('PaymentDiscTolPageHandler,PaymentTolerancePageHandler')]
    [Scope('OnPrem')]
    procedure LessPmtWithToleranceMultiCur()
    begin
        // Covers documents TFS_TC_ID=124390,124401,124402,124403.

        // Check Payment Tolerance on various entries after Post General Lines with Less Amount and After Posting Date with New Currency.
        Initialize;
        LessPmtWithTolerance(CreateCurrency, CreateCurrency);
    end;

    local procedure LessPmtWithTolerance(CurrencyCode1: Code[10]; CurrencyCode2: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        Amount2: Decimal;
    begin
        // Check Payment Tolerance on various entries after Post General Lines with Less Amount and After Posting Date.

        // Modify General Ledger Setup and Post Gen. Journal Lines for Invoice/Credit Memo and Payment/Refund
        // with Random Amount.
        LibraryPmtDiscSetup.SetPmtTolerance(1);
        GeneralLedgerSetup.Get();

        ComputePmtTolAmountForMinValue(Amount, Amount2);
        PaymentWithDiscountTolerance(
          CurrencyCode1, CurrencyCode2, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Document Type"::Refund, Amount, -Amount2);
        ComputePmtTolAmountForMaxValue(Amount, Amount2);
        PaymentWithDiscountTolerance(
          CurrencyCode1, CurrencyCode2, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -Amount, Amount2);
    end;

    [Test]
    [HandlerFunctions('PaymentTolerancePageHandler')]
    [Scope('OnPrem')]
    procedure UnderAmtBfrDiscDateLCY()
    begin
        // Covers documents TFS_TC_ID=124390, 124393,124394,124395.

        // Check Payment Tolerance on various entries after Post General Lines with Less Amount and Less Posting Date.
        Initialize;
        UnderAmtBfrDiscDate('', '');
    end;

    [Test]
    [HandlerFunctions('PaymentTolerancePageHandler')]
    [Scope('OnPrem')]
    procedure UnderAmtBfrDiscDateFCY()
    var
        CurrencyCode: Code[10];
    begin
        // Covers documents TFS_TC_ID=124390, 124393,124394,124395.

        // Check Payment Tolerance on various entries after Post General Lines with Less Amount and Less Posting Date with Currency.
        Initialize;
        CurrencyCode := CreateCurrency;
        UnderAmtBfrDiscDate(CurrencyCode, CurrencyCode);
    end;

    [Test]
    [HandlerFunctions('PaymentTolerancePageHandler')]
    [Scope('OnPrem')]
    procedure UnderAmtBfrDiscDateMultiCur()
    begin
        // Covers documents TFS_TC_ID=124390, 124393,124394,124395.

        // Check Payment Tolerance on various entries after Post General Lines with Less Amount and Less Posting Date with New Currency.
        Initialize;
        UnderAmtBfrDiscDate(CreateCurrency, CreateCurrency);
    end;

    local procedure UnderAmtBfrDiscDate(CurrencyCode1: Code[10]; CurrencyCode2: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        Amount2: Decimal;
    begin
        // Modify General Ledger Setup and Post Gen. Journal Lines for Credit Memo and Refund with Random Amount.
        LibraryPmtDiscSetup.SetPmtTolerance(1);

        ComputePmtTolAmountForMinValue(Amount, Amount2);
        PaymentWithTolerance(
          CurrencyCode1, CurrencyCode2, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Document Type"::Refund, Amount, -Amount2);
        PaymentWithTolerance(
          CurrencyCode1, CurrencyCode2, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -Amount, Amount2);
    end;

    [Test]
    [HandlerFunctions('PaymentDiscTolPageHandler')]
    [Scope('OnPrem')]
    procedure OverWithoutToleranceLCY()
    begin
        // Covers documents TFS_TC_ID=124390,124404,124405,124409,124410.

        // Check Payment Tolerance on various entries after Post General Lines with More Amount and After Posting Date.
        Initialize;
        OverWithoutTolerance('', '');
    end;

    [Test]
    [HandlerFunctions('PaymentDiscTolPageHandler')]
    [Scope('OnPrem')]
    procedure OverWithoutToleranceFCY()
    var
        CurrencyCode: Code[10];
    begin
        // Covers documents TFS_TC_ID=124390,124404,124405,124409,124410.

        // Check Payment Tolerance on various entries after Post General Lines with Less Amount and After Posting Date with Currency.
        Initialize;
        CurrencyCode := CreateCurrency;
        OverWithoutTolerance(CurrencyCode, CurrencyCode);
    end;

    [Test]
    [HandlerFunctions('PaymentDiscTolPageHandler')]
    [Scope('OnPrem')]
    procedure OverWithoutToleranceMultiCur()
    begin
        // Covers documents TFS_TC_ID=124390,124404,124405,124409,124410.

        // Check Payment Tolerance on various entries after Post General Lines with Less Amount and After Posting Date with New Currency.
        Initialize;
        OverWithoutTolerance(CreateCurrency, CreateCurrency);
    end;

    local procedure OverWithoutTolerance(CurrencyCode1: Code[10]; CurrencyCode2: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        Amount2: Decimal;
    begin
        // Check Payment Tolerance on various entries after Post General Lines with More Amount and After Posting Date.

        // Modify General Ledger Setup and Post Gen. Journal Lines for Credit Memo and Refund with Random Amount.
        LibraryPmtDiscSetup.SetPmtTolerance(1);
        GeneralLedgerSetup.Get();
        Amount := 10 * LibraryRandom.RandInt(100);
        Amount2 := Amount + GeneralLedgerSetup."Max. Payment Tolerance Amount";

        PaymentWithoutTolerance(
          CurrencyCode1, CurrencyCode2, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Document Type"::Refund, Amount, -Amount2);
        PaymentWithoutTolerance(
          CurrencyCode1, CurrencyCode2, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -Amount, Amount2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EqualWithoutDiscountLCY()
    begin
        // Covers documents TFS_TC_ID=124390,124406,124407,124408.

        // Check Payment Tolerance on various entries after Post General Lines with Same Amount and After Posting Date.
        Initialize;
        EqualWithoutDiscount('', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EqualWithoutDiscountFCY()
    var
        CurrencyCode: Code[10];
    begin
        // Covers documents TFS_TC_ID=124390,124406,124407,124408.

        // Check Payment Tolerance on various entries after Post General Lines with Same Amount and After Posting Date with Currency.
        Initialize;
        CurrencyCode := CreateCurrency;
        EqualWithoutDiscount(CurrencyCode, CurrencyCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EqualWithoutDiscountMultiCur()
    begin
        // Covers documents TFS_TC_ID=124390,124406,124407,124408.

        // Check Payment Tolerance on various entries after Post General Lines with Same Amount and After Posting Date with New Currency.
        Initialize;
        EqualWithoutDiscount(CreateCurrency, CreateCurrency);
    end;

    local procedure EqualWithoutDiscount(CurrencyCode1: Code[10]; CurrencyCode2: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
    begin
        // Check Payment Tolerance on various entries after Post General Lines with Same Amount and After Posting Date.

        // Modify General Ledger Setup and Post Gen. Journal Lines for Credit Memo and Refund with Random Amount.
        LibraryPmtDiscSetup.SetPmtTolerance(1);
        Amount := 10 * LibraryRandom.RandInt(100);

        PaymentWithoutDiscount(
          CurrencyCode1, CurrencyCode2, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Document Type"::Refund, Amount, -Amount);
        PaymentWithoutDiscount(
          CurrencyCode1, CurrencyCode2, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -Amount, Amount);
    end;

    [Test]
    [HandlerFunctions('PaymentTolerancePageHandler')]
    [Scope('OnPrem')]
    procedure LessWithoutDiscountLCY()
    begin
        // Covers documents TFS_TC_ID=124390, 124396,124397,124398,124399,124400.

        // Check Payment Tolerance on various entries after Post General Lines with Less Amount and Over Posting Date.
        Initialize;
        LessPmtWithoutDiscount('', '');
    end;

    [Test]
    [HandlerFunctions('PaymentTolerancePageHandler')]
    [Scope('OnPrem')]
    procedure LessPmtWithoutDiscountFCY()
    var
        CurrencyCode: Code[10];
    begin
        // Covers documents TFS_TC_ID=124390, 124396,124397,124398,124399,124400.

        // Check Payment Tolerance on various entries after Post General Lines with Less Amount and Over Posting Date with Currency.
        Initialize;
        CurrencyCode := CreateCurrency;
        LessPmtWithoutDiscount(CurrencyCode, CurrencyCode);
    end;

    [Test]
    [HandlerFunctions('PaymentTolerancePageHandler')]
    [Scope('OnPrem')]
    procedure LessPmtWithoutDiscountMultiCur()
    begin
        // Covers documents TFS_TC_ID=124390, 124396,124397,124398,124399,124400.

        // Check Payment Tolerance on various entries after Post General Lines with Less Amount and Over Posting Date with New Currency.
        Initialize;
        LessPmtWithoutDiscount(CreateCurrency, CreateCurrency);
    end;

    local procedure LessPmtWithoutDiscount(CurrencyCode1: Code[10]; CurrencyCode2: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Amount: Decimal;
        Amount2: Decimal;
    begin
        // Modify General Ledger Setup and Post Gen. Journal Lines for Credit Memo and Refund with Random Amount.
        LibraryPmtDiscSetup.SetPmtTolerance(1);
        GeneralLedgerSetup.Get();

        ComputePmtTolAmountForMinValue(Amount, Amount2);
        PaymentWithoutDiscount(
          CurrencyCode1, CurrencyCode2, GenJournalLine."Document Type"::"Credit Memo",
          GenJournalLine."Document Type"::Refund, Amount, -Amount2);
        ComputeAmountForABSMaxValue(Amount, Amount2);
        PaymentWithoutDiscount(
          CurrencyCode1, CurrencyCode2, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, -Amount, Amount2);
    end;

    [Normal]
    local procedure PaymentWithoutDiscount(CurrencyCode: Code[10]; CurrencyCode2: Code[10]; GenJnlDocumentType: Option; GenJnlDocumentType2: Option; Amount: Decimal; Amount2: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // Setup: Modify General Ledger Setup and Post Gen. Journal Lines for Invoice and Payment with Random Amount and
        // attached currency and Post them.
        CreateAndPostJnlLine(GenJournalLine, CurrencyCode, GenJnlDocumentType, Amount);

        // Exercise: Apply Invoice Document No. with Payment Gen. Journal Line and Post it.
        DocumentNo :=
          PostApplicationJnlLine(GenJournalLine, CurrencyCode2, GenJnlDocumentType2,
            Amount2, CalcDate('<' + LibraryPmtDiscSetup.GetPmtDiscGracePeriod + '>', CalcDate('<1M>', CalcDueDate)));

        // Verify: Verify Vendor Ledger Entry, Detailed Vendor Ledger Entry.
        VerifyVendorLedgerEntry(GenJnlDocumentType, GenJournalLine."Document No.", (Amount * GetDiscountPercent / 100));
        VerifyDetldVendorLedgerEntry(
          GenJnlDocumentType2, DetailedVendorLedgEntry."Entry Type"::Application, DocumentNo, -GetAmountFCY(CurrencyCode2, Amount));
    end;

    [Normal]
    local procedure PaymentWithDiscount(CurrencyCode: Code[10]; CurrencyCode2: Code[10]; GenJnlDocumentType: Option; GenJnlDocumentType2: Option; Amount: Decimal; Amount2: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        PmtDiscount: Decimal;
    begin
        // Setup: Modify General Ledger Setup and Post Gen. Journal Lines with Random Amount and
        // attached currency and Post them.
        CreateAndPostJnlLine(GenJournalLine, CurrencyCode, GenJnlDocumentType, Amount);

        // Exercise: Apply Document with Gen. Journal Line and Post it.
        DocumentNo := PostApplicationJnlLine(GenJournalLine, CurrencyCode2, GenJnlDocumentType2, Amount2, CalcDueDate);

        // Verify: Verify Vendor Ledger Entry, Detailed Vendor Ledger Entry and G/L Entry.
        PmtDiscount := GetAmountFCY(CurrencyCode2, GetDiscountAmount(Amount));
        VerifyVendorLedgerEntry(GenJnlDocumentType, GenJournalLine."Document No.", GetDiscountAmount(Amount));
        VerifyDetldVendorLedgerEntry(GenJnlDocumentType2, DetailedVendorLedgEntry."Entry Type"::"Payment Discount", DocumentNo, -PmtDiscount)
        ;
    end;

    [Normal]
    local procedure PaymentWithTolerance(CurrencyCode: Code[10]; CurrencyCode2: Code[10]; GenJnlDocumentType: Option; GenJnlDocumentType2: Option; Amount: Decimal; Amount2: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        PmtTolAmount: Decimal;
    begin
        // Setup: Modify General Ledger Setup and Post Gen. Journal Lines with Random Amount and
        // attached currency and Post them.
        CreateAndPostJnlLine(GenJournalLine, CurrencyCode, GenJnlDocumentType, Amount);

        // Exercise: Apply Invoice/Credit Memo Document No. with Payment/Refund Gen. Journal Line and Post it.
        DocumentNo := PostApplicationJnlLine(GenJournalLine, CurrencyCode2, GenJnlDocumentType2, Amount2, CalcDate('<-1D>', CalcDueDate));

        // Verify: Verify Vendor Ledger Entry, Detailed Vendor Ledger Entry.
        PmtTolAmount := GetAmountFCY(CurrencyCode2, Amount2 + (Amount - GetDiscountAmount(Amount)));
        VerifyVendorLedgerEntry(GenJnlDocumentType, GenJournalLine."Document No.", GetDiscountAmount(Amount));
        VerifyDetldVendorLedgerEntry(
          GenJnlDocumentType2, DetailedVendorLedgEntry."Entry Type"::"Payment Tolerance", DocumentNo, -PmtTolAmount);
    end;

    local procedure PaymentWithoutTolerance(CurrencyCode: Code[10]; CurrencyCode2: Code[10]; GenJnlDocumentType: Option; GenJnlDocumentType2: Option; Amount: Decimal; Amount2: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        PmtDiscount: Decimal;
    begin
        // Setup: Modify General Ledger Setup and Post Gen. Journal Lines with Random Amount and
        // attached currency and Post them.
        CreateAndPostJnlLine(GenJournalLine, CurrencyCode, GenJnlDocumentType, Amount);

        // Exercise: Apply Credit Memo Document No. with Refund Gen. Journal Line and Post it.
        DocumentNo := PostApplicationJnlLine(GenJournalLine, CurrencyCode2, GenJnlDocumentType2, Amount2, CalcDate('<1D>', CalcDueDate));

        // Verify: Verify Vendor Ledger Entry and Detailed Vendor Ledger Entry.
        PmtDiscount := GetAmountFCY(CurrencyCode2, GetDiscountAmount(Amount));
        VerifyVendorLedgerEntry(GenJnlDocumentType, GenJournalLine."Document No.", Amount * GetDiscountPercent / 100);
        VerifyDetldVendorLedgerEntry(
          GenJnlDocumentType2, DetailedVendorLedgEntry."Entry Type"::"Payment Discount Tolerance", DocumentNo, -PmtDiscount);
    end;

    local procedure PaymentWithDiscountTolerance(CurrencyCode: Code[10]; CurrencyCode2: Code[10]; GenJnlDocumentType: Option; GenJnlDocumentType2: Option; Amount: Decimal; Amount2: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        PmtTolAmount: Decimal;
    begin
        // Setup: Modify General Ledger Setup and Post Gen. Journal Lines for Invoice and Payment with Random Amount and
        // attached currency and Post them.
        CreateAndPostJnlLine(GenJournalLine, CurrencyCode, GenJnlDocumentType, Amount);

        // Exercise: Apply Document with Gen. Journal Line and Post it.
        DocumentNo := PostApplicationJnlLine(GenJournalLine, CurrencyCode2, GenJnlDocumentType2, Amount2, CalcDate('<1D>', CalcDueDate));

        // Verify: Verify Vendor Ledger Entry, Detailed Vendor Ledger Entry and G/L Entry.
        PmtTolAmount := GetAmountFCY(CurrencyCode2, Amount2 + (Amount - GetDiscountAmount(Amount)));
        VerifyDetldVendorLedgerEntry(
          GenJnlDocumentType2, DetailedVendorLedgEntry."Entry Type"::"Payment Tolerance", DocumentNo, -PmtTolAmount);
        VerifyDetldVendorLedgerEntry(GenJnlDocumentType2, DetailedVendorLedgEntry."Entry Type"::"Payment Discount Tolerance", DocumentNo,
          -GetAmountFCY(CurrencyCode2, GetDiscountAmount(Amount)));
    end;

    local procedure CreateAndPostJnlLine(var GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10]; GenJnlDocumentType: Option; Amount: Decimal)
    begin
        // Setup: Modify General Ledger Setup and Post Gen. Journal Lines for Invoice and Payment with Random Amount and
        // attached currency and Post them.
        CreateDocumentLine(GenJournalLine, GenJnlDocumentType, CreateVendor, Amount, CurrencyCode, WorkDate);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostApplicationJnlLine(GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10]; GenJnlDocumentType: Option; Amount2: Decimal; DueDate: Date): Code[20]
    var
        GenJournalLine2: Record "Gen. Journal Line";
    begin
        // Set Amount and Posting Date with Payment Terms for Payment Tolerance Discount.
        CreateDocumentLine(GenJournalLine2, GenJnlDocumentType, GenJournalLine."Account No.", Amount2, CurrencyCode, DueDate);

        // Exercise: Apply Document with Gen. Journal Line and Post it.
        UpdateAndPostGenJnlLine(GenJournalLine2, GenJournalLine."Document Type", GenJournalLine."Document No.");
        exit(GenJournalLine2."Document No.");
    end;

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Vendor Pmt Tol With Wrning");
        LibrarySetupStorage.Restore;
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Vendor Pmt Tol With Wrning");

        LibraryERMCountryData.UpdateGeneralLedgerSetup;
        LibraryERMCountryData.UpdateGeneralPostingSetup;

        isInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Vendor Pmt Tol With Wrning")
    end;

    local procedure ComputePmtTolAmountForMinValue(var Amount: Decimal; var Amount2: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // To Calculate Payment/Refund value using "Payment Tolerance %" field value from General Ledger Setup need to take fixed
        // higher seed value to 499.
        GeneralLedgerSetup.Get();
        Amount := LibraryRandom.RandInt(499);
        Amount2 := Amount - (Amount * GeneralLedgerSetup."Payment Tolerance %" / 100);
    end;

    local procedure ComputePmtTolAmountForMaxValue(var Amount: Decimal; var Amount2: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // To Calculate Payment/Refund value using "Max. Payment Tolerance Amount" field value from General Ledger Setup need to take fixed
        // lower seed value to 500.
        GeneralLedgerSetup.Get();
        Amount := 500 * LibraryRandom.RandInt(5);
        Amount2 := Amount - (GeneralLedgerSetup."Max. Payment Tolerance Amount" + (Amount * GetDiscountPercent / 100));
    end;

    local procedure ComputeAmountForABSMaxValue(var Amount: Decimal; var Amount2: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // To Calculate Payment/Refund value using "Max. Payment Tolerance Amount" field value from General Ledger Setup need to take fixed
        // lower seed value to 500.
        GeneralLedgerSetup.Get();
        Amount := 500 * LibraryRandom.RandInt(5);
        Amount2 := Amount - GeneralLedgerSetup."Max. Payment Tolerance Amount";
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Application Method", Vendor."Application Method"::Manual);
        Vendor.Validate("Payment Terms Code", GetPaymentTerms);
        Vendor.Modify(true);

        UpdateVendorPostingGroup(Vendor."Vendor Posting Group");
        exit(Vendor."No.");
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Payment Tolerance %", 1);
        Currency.Validate("Max. Payment Tolerance Amount", 5);
        Currency.Validate("Residual Gains Account", Currency."Realized Gains Acc.");
        Currency.Validate("Residual Losses Account", Currency."Realized Losses Acc.");
        Currency.Modify(true);

        // Create Exchange Rate.
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        Commit();
        exit(Currency.Code);
    end;

    local procedure CreateDocumentLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Option; VendorNo: Code[20]; Amount: Decimal; CurrencyCode: Code[10]; PostingDate: Date)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Select Journal Batch Name and Template Name.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, GenJournalLine."Account Type"::Vendor,
          VendorNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
    end;

    local procedure CalcDueDate(): Date
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

    [Normal]
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

    local procedure UpdateVendorPostingGroup(PostingGroupCode: Code[20])
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        GLAccount: Record "G/L Account";
    begin
        VendorPostingGroup.Get(PostingGroupCode);
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.SetRange(Blocked, false);
        GLAccount.FindSet;
        VendorPostingGroup.Validate("Payment Disc. Debit Acc.", GLAccount."No.");
        VendorPostingGroup.Validate("Payment Disc. Credit Acc.", GLAccount."No.");
        GLAccount.Next;
        VendorPostingGroup.Validate("Payment Tolerance Debit Acc.", GLAccount."No.");
        VendorPostingGroup.Validate("Payment Tolerance Credit Acc.", GLAccount."No.");
        VendorPostingGroup.Modify(true);
    end;

    [Normal]
    local procedure UpdateAndPostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; AppliestoDocType: Option; DocumentNo: Code[20])
    begin
        GenJournalLine.Validate("Applies-to Doc. Type", AppliestoDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    [Normal]
    local procedure VerifyVendorLedgerEntry(DocumentType: Option; DocumentNo: Code[20]; ToleranceDiscount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        VendorLedgerEntry.SetRange("Document Type", DocumentType);
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst;
        Assert.AreNearlyEqual(
          ToleranceDiscount, VendorLedgerEntry."Original Pmt. Disc. Possible", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, VendorLedgerEntry.FieldCaption("Original Pmt. Disc. Possible"),
            ToleranceDiscount, VendorLedgerEntry.TableCaption));
    end;

    [Normal]
    local procedure VerifyDetldVendorLedgerEntry(DocumentType: Option; EntryType: Option; DocumentNo: Code[20]; ToleranceDiscount: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        DetailedVendorLedgEntry.SetRange("Document Type", DocumentType);
        DetailedVendorLedgEntry.SetRange("Entry Type", EntryType);
        DetailedVendorLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedVendorLedgEntry.FindFirst;
        Assert.AreNearlyEqual(
          ToleranceDiscount, DetailedVendorLedgEntry."Amount (LCY)", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, DetailedVendorLedgEntry.FieldCaption("Amount (LCY)"),
            ToleranceDiscount, DetailedVendorLedgEntry.TableCaption));
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
}

