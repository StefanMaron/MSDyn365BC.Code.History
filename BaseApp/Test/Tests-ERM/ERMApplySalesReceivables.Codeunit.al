codeunit 134000 "ERM Apply Sales/Receivables"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJournals: Codeunit "Library - Journals";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        WrongValErr: Label '%1 must be %2 in %3.';
        ApplnRoundingError: Label '%1 must be equal to ''Application''  in %2: %3=%4. Current value is ''Appln. Rounding''.';
        ErrorMessage: Label 'Error Message must be same.';
        AppliesToIDIsNotEmptyOnLedgEntryErr: Label 'Applies-to ID is not empty in %1.';
        AmountToApplyErr: Label '"Amount to Apply" should be zero.';
        DimensionUsedErr: Label 'A dimension used in %1 %2, %3, %4 has caused an error.';
        DialogTxt: Label 'Dialog';

    [Test]
    [Scope('OnPrem')]
    procedure TestPmntDiscWithinDueDate()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DueDate: Date;
        PaymentDiscountPercent: Decimal;
        DiscountAmount: Decimal;
    begin
        // Create General Journal Line for Customer, Post and Validate Customer Ledger Entry and Detailed Customer Ledger Entry for
        // Payment Discount(Amount and "Amount LCY") field.

        // Calculate Due Date and Payment Discount Percent then Post and Apply General Lines.
        Initialize;
        CalcDueDateAndPaymentDiscount(DueDate, PaymentDiscountPercent);
        PostAndApplyGenLines(GenJournalLine, DueDate);
        DiscountAmount := Round(GenJournalLine.Amount * PaymentDiscountPercent / 100);

        // Verify: Verify Applied Entry.
        VerifyPaymentWithDiscount(GenJournalLine."Document No.", DiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPmntDiscAfterDueDate()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DueDate: Date;
        PaymentDiscountPercent: Decimal;
    begin
        // Create General Journal Line for Customer, Post and Validate "Original Pmt. Disc. Possible" and "Open" field for Payment line in
        // Customer Ledger Entry.

        // Calculate Due Date and Payment Discount Percent then Post and Apply General Lines.
        Initialize;
        CalcDueDateAndPaymentDiscount(DueDate, PaymentDiscountPercent);
        PostAndApplyGenLines(GenJournalLine, CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', DueDate));

        // Verify: Verify Payment Applied Entry.
        VerifyPaymentWithoutDiscount(GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUnapplyPmntDisc()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DueDate: Date;
        PaymentDiscountPercent: Decimal;
        DocumentNo: Code[20];
    begin
        // Create General Journal Line for Customer, Post and Validate "Original Pmt. Disc. Possible" and "Open" field for Payment line in
        // Customer Ledger Entry.

        // Calculate Due Date and Payment Discount Percent then Post and Apply General Lines.
        Initialize;
        CalcDueDateAndPaymentDiscount(DueDate, PaymentDiscountPercent);
        DocumentNo := PostAndApplyGenLines(GenJournalLine, DueDate);

        // Exercise: Unapply Payment to Invoice.
        UnapplyCustLedgerEntry(GenJournalLine."Document Type"::Payment, GenJournalLine."Document No.");

        // Verify: Verify UnApplied Entry.
        VerifyUnapplyPaymentDiscount(DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplnRoundingForInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Application Rounding Entry in Detailed Customer Ledger Entry with Apply and Unapply Invoice and Payment with Random Values.
        // Using 0 for Application Rounding Precision for Currency.
        Initialize;
        ApplyUnapplyCustRounding(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, CreateCurrency(0),
          10 * LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(5, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplnRoundingForCreditMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Application Rounding Entry in Detailed Customer Ledger Entry with Apply and Unapply Credit Memo and Refund
        // with Random Values and using 0 for Application Rounding Precision for Currency..
        Initialize;
        ApplyUnapplyCustRounding(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, CreateCurrency(0),
          -10 * LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(5, 2));
    end;

    local procedure ApplyUnapplyCustRounding(DocumentType: Option; DocumentType2: Option; CurrencyCode: Code[10]; Amount: Decimal; AppRounding: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Setup.
        CreatePostApplyGenJournalLine(GenJournalLine, DocumentType, DocumentType2, CurrencyCode, Amount, AppRounding);

        // Exercise.
        UnapplyCustLedgerEntry(DocumentType2, GenJournalLine."Document No.");

        // Verify: Verify Application Rounding Entry on Detailed Customer Ledger Entry.
        VerifyApplnRoundingCustLedger(GenJournalLine."Document No.", -AppRounding);
        exit(GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyPmntAdditionalCurr()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        AppRounding: Decimal;
    begin
        // Check Application Rounding Entry in Detailed Customer Ledger Entry and Additional Currency Amount in G/L Entry
        // with Apply and Unapply Invoice and Payment with Random Values and using 0 for Application Rounding Precision for Currency..
        Initialize;
        CurrencyCode := CreateCurrency(0);
        LibraryERM.SetAddReportingCurrency(CurrencyCode);
        AppRounding := LibraryRandom.RandDec(5, 2);
        DocumentNo :=
          ApplyUnapplyCustRounding(
            GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, CurrencyCode,
            10 * LibraryRandom.RandDec(100, 2), AppRounding);

        // Verify: Verify Additional Currency Amount in G/L Entry.
        VerifyGLEntry(DocumentNo, CurrencyCode, GenJournalLine."Document Type"::" ", AppRounding);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyRefAdditionalCurr()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        AppRounding: Decimal;
    begin
        // Check Application Rounding Entry in Detailed Customer Ledger Entry and Additional Currency Amount in G/L Entry
        // with Apply and Unapply Credit Memo and Refund with Random Values and using 0 for Application Rounding Precision for Currency..
        Initialize;
        CurrencyCode := CreateCurrency(0);
        LibraryERM.SetAddReportingCurrency(CurrencyCode);
        AppRounding := LibraryRandom.RandDec(5, 2);
        DocumentNo :=
          ApplyUnapplyCustRounding(
            GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund, CurrencyCode,
            -10 * LibraryRandom.RandDec(100, 2), AppRounding);

        // Verify: Verify Additional Currency Amount in G/L Entry.
        VerifyGLEntry(DocumentNo, CurrencyCode, GenJournalLine."Document Type"::" ", AppRounding);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyApplyPmntAdditionalCurr()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Application Rounding Entry in Detailed Customer Ledger Entry and Additional Currency Amount in G/L Entry
        // with Apply already Unapplied Invoice and Payment with Random Values.
        Initialize;
        UnapplyApplyAdditionalCurr(
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, 10 * LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyApplyRefAdditionalCurr()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Application Rounding Entry in Detailed Customer Ledger Entry and Additional Currency Amount in G/L Entry
        // with Apply already Unapplied Credit Memo and Refund with Random Values.
        Initialize;
        UnapplyApplyAdditionalCurr(
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund,
          -10 * LibraryRandom.RandDec(100, 2));
    end;

    local procedure UnapplyApplyAdditionalCurr(DocumentType: Option; DocumentType2: Option; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        CurrencyCode: Code[10];
        AppRounding: Decimal;
    begin
        // Setup.
        CurrencyCode := CreateCurrency(0);  // Using 0 for Application Rounding Precision for Currency.
        LibraryERM.SetAddReportingCurrency(CurrencyCode);
        AppRounding := LibraryRandom.RandDec(5, 2);
        DocumentNo := CreatePostApplyGenJournalLine(GenJournalLine, DocumentType, DocumentType2, CurrencyCode, Amount, AppRounding);
        UnapplyCustLedgerEntry(DocumentType2, GenJournalLine."Document No.");

        // Exercise. Apply already Unapplied Document from Customer Ledger Entry.
        LibraryERM.ApplyCustomerLedgerEntries(DocumentType2, DocumentType, GenJournalLine."Document No.", DocumentNo);

        // Verify: Verify Application Rounding Entry on Detailed Customer Ledger Entry and Additional Currency Amount in G/L Entry.
        VerifyApplnRoundingCustLedger(GenJournalLine."Document No.", -AppRounding);
        VerifyGLEntry(GenJournalLine."Document No.", CurrencyCode, GenJournalLine."Document Type"::" ", AppRounding);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyPmntApplnRoundingError()
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        CurrencyCode: Code[10];
        AppRounding: Decimal;
    begin
        // Verify Error when Unapply Entry of the type Appln. Rounding from Detailed Customer Ledger Entry.

        // Setup.
        CurrencyCode := CreateCurrency(0);  // Using 0 for Application Rounding Precision for Currency.
        LibraryERM.SetAddReportingCurrency(CurrencyCode);
        AppRounding := LibraryRandom.RandDec(5, 2);

        CreatePostApplyGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment, CurrencyCode,
          10 * LibraryRandom.RandDec(100, 2), AppRounding);

        FindDetailedLedgerEntry(
          DetailedCustLedgEntry, GenJournalLine."Document No.", DetailedCustLedgEntry."Entry Type"::"Appln. Rounding");

        // Exercise. Unapply Payment from Detailed Customer ledger Entry.
        asserterror CustEntryApplyPostedEntries.UnApplyDtldCustLedgEntry(DetailedCustLedgEntry);

        // Verify: Verify Error when Unapply Entry of the type Appln. Rounding from Detailed Customer Ledger Entry.
        Assert.AreEqual(
          StrSubstNo(ApplnRoundingError, DetailedCustLedgEntry.FieldCaption("Entry Type"), DetailedCustLedgEntry.TableCaption,
            DetailedCustLedgEntry.FieldCaption("Entry No."), DetailedCustLedgEntry."Entry No."), GetLastErrorText, ErrorMessage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ClearAppliesToIDFromCLEWhenChangeValueOnGenJnlLine()
    var
        GenJnlLine: Record "Gen. Journal Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        // [SCENARIO 118226] Applies-to ID is cleared from Customer Ledger Entry when change value of General Journal Line
        Initialize;

        // [GIVEN] Customer Ledger Entry and General Journal Line with the same Applies-to ID
        FindOpenInvCustLedgEntry(CustLedgEntry);
        SetAppliesToIDOnCustLedgEntry(CustLedgEntry);
        CreateGenJnlLineWithAppliesToID(
          GenJnlLine, GenJnlLine."Account Type"::Customer, CustLedgEntry."Customer No.", CustLedgEntry."Applies-to ID");

        // [WHEN] Change "Applies-to ID" in General Journal Line
        GenJnlLine.Validate("Applies-to ID", LibraryUtility.GenerateGUID);
        GenJnlLine.Modify(true);

        // [THEN] "Applies-to ID" in Customer Ledger Entry is empty
        CustLedgEntry.Find;
        Assert.AreEqual('', CustLedgEntry."Applies-to ID", StrSubstNo(AppliesToIDIsNotEmptyOnLedgEntryErr, CustLedgEntry.TableCaption));
        Assert.AreEqual(0, CustLedgEntry."Amount to Apply", AmountToApplyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ClearAppliesToIDFromCLEWhenDeleteGenJnlLine()
    var
        GenJnlLine: Record "Gen. Journal Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        // [SCENARIO 118226] Applies-to ID is cleared from Customer Ledger Entry when delete General Journal Line
        Initialize;

        // [GIVEN] Customer Ledger Entry and General Journal Line with the same Applies-to ID
        FindOpenInvCustLedgEntry(CustLedgEntry);
        SetAppliesToIDOnCustLedgEntry(CustLedgEntry);
        CreateGenJnlLineWithAppliesToID(
          GenJnlLine, GenJnlLine."Account Type"::Customer, CustLedgEntry."Customer No.", CustLedgEntry."Applies-to ID");

        // [WHEN] Delete General Journal Line
        GenJnlLine.Delete(true);

        // [THEN] "Applies-to ID" in Customer Ledger Entry is empty
        CustLedgEntry.Find;
        Assert.AreEqual('', CustLedgEntry."Applies-to ID", StrSubstNo(AppliesToIDIsNotEmptyOnLedgEntryErr, CustLedgEntry.TableCaption));
        Assert.AreEqual(0, CustLedgEntry."Amount to Apply", AmountToApplyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ClearAppliesToDocNoValueFromGenJnlLine()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 120733] Customer Ledger Entry "Amount-to Apply" = 0 when blank "Applies-to Doc. No." field in General Journal Line
        Initialize;

        // [GIVEN] Customer Ledger Entry and General Journal Line with "Applies-to Doc. No"
        FindOpenInvCustLedgEntry(CustLedgEntry);
        CreateGenJnlLineWithAppliesToDocNo(
          GenJnlLine, GenJnlLine."Account Type"::Customer, CustLedgEntry."Customer No.", CustLedgEntry."Document No.");

        // [WHEN] Blank "Applies-to Doc. No." field in General Journal Line
        GenJnlLine.Validate("Applies-to Doc. No.", '');
        GenJnlLine.Modify(true);

        // [THEN] Customer Ledger Entry "Amount to Apply" = 0
        CustLedgEntry.Find;
        Assert.AreEqual(0, CustLedgEntry."Amount to Apply", AmountToApplyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteGenJnlLineWithAppliesToDocNo()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 120733] Customer Ledger Entry "Amount-to Apply" = 0 when delete General Journal Line with "Applies-to Doc. No."
        Initialize;

        // [GIVEN] Customer Ledger Entry and General Journal Line with "Applies-to Doc. No."
        FindOpenInvCustLedgEntry(CustLedgEntry);
        CreateGenJnlLineWithAppliesToDocNo(
          GenJnlLine, GenJnlLine."Account Type"::Customer, CustLedgEntry."Customer No.", CustLedgEntry."Document No.");

        // [WHEN] Delete General Journal Line
        GenJnlLine.Delete(true);

        // [THEN] Customer Ledger Entry "Amount to Apply" = 0
        CustLedgEntry.Find;
        Assert.AreEqual(0, CustLedgEntry."Amount to Apply", AmountToApplyErr);
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyAmountApplToExtDocNoWhenSetValue()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
        PostedDocNo: Code[20];
        ExpectedExtDocNo: Code[35];
    begin
        // [FEATURE] [Application] [Cash Receipt]
        // [SCENARIO 363069] Verify that External Doc No transferred when setting 'Applies-to Doc. No.' value in Cash Receipt Journal.

        // [GIVEN] Invoice customer ('External Document No.' non-empty).
        Initialize;
        PostInvoice(GenJournalLine);
        ExpectedExtDocNo := GenJournalLine."External Document No.";
        PostedDocNo := GenJournalLine."Document No.";

        // [GIVEN] Create Cash Receipt Journal Line for the customer.
        CreateCashReceiptJnlLine(GenJournalLine, GenJournalLine."Account No.");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        Commit();

        CashReceiptJournal.OpenEdit;
        CashReceiptJournal."Applies-to Doc. Type".SetValue(GenJournalLine."Applies-to Doc. Type"::Invoice);

        // [WHEN] Set 'Applies-to Doc. No.' manually to Posted Invoice doc. no.
        CashReceiptJournal."Applies-to Doc. No.".SetValue(PostedDocNo);
        CashReceiptJournal.OK.Invoke;

        // [THEN] External doc. no. transferred to 'Applied-to Ext. Doc. No.', but Amount is not.
        VerifyExtDocNoAmount(GenJournalLine, ExpectedExtDocNo, 0);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesModalPageHandler,GeneralJournalTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyAmountApplToExtDocNoWhenLookUp()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
        ExpectedExtDocNo: Code[35];
        ExpectedAmount: Decimal;
    begin
        // [FEATURE] [Application] [Cash Receipt]
        // [SCENARIO 363069] Verify that Amount and External Doc No transferred when looking up 'Applies-to Doc. No.' value in Cash Receipt Journal.

        // [GIVEN] Invoice customer ('External Document No.' non-empty).
        Initialize;
        PostInvoice(GenJournalLine);
        ExpectedAmount := -GenJournalLine.Amount;
        ExpectedExtDocNo := GenJournalLine."External Document No.";

        // [GIVEN] Create Cash Receipt Journal Line for the customer.
        CreateCashReceiptJnlLine(GenJournalLine, GenJournalLine."Account No.");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        Commit();

        CashReceiptJournal.OpenEdit;
        CashReceiptJournal."Applies-to Doc. Type".SetValue(GenJournalLine."Applies-to Doc. Type"::Invoice);

        // [WHEN] Look up and set 'Applies-to Doc. No.' to Posted Invoice doc. no.
        CashReceiptJournal."Applies-to Doc. No.".Lookup;
        CashReceiptJournal.OK.Invoke;

        // [THEN] External doc. no. transferred to 'Applied-to Ext. Doc. No.' as well as Amount.
        VerifyExtDocNoAmount(GenJournalLine, ExpectedExtDocNo, ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtJnlApplToInvWithNoDimDiscountAndDefDimErr()
    var
        DimensionValue: Record "Dimension Value";
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
        PaymentAmount: Decimal;
    begin
        // [FEATURE] [Dimension] [Payment Discount]
        // [SCENARIO 376797] Error try posting sales payment journal without dimension applied to posted Invoice in case of Discount, "Payment Disc. Debit Acc." with default dimension with "Value Posting" = "Same Code"
        Initialize;

        // [GIVEN] Customer with "Payment Disc. Debit Acc." = "A"
        // [GIVEN] Default Dimension "D" with "Value Posting" = "Same Code" is set for G/L Account "A"
        CustomerNo := CreateCustomer;
        CreateDefaultDimensionGLAccSameValue(DimensionValue, CreateCustPostingGrPmtDiscDebitAccNo(CustomerNo));

        // [GIVEN] Posted Sales Invoice with Amount Including VAT = 10000 and possible Discount = 2%. No dimension is set.
        CreateAndPostGenJnlLine(
          GenJournalLine, WorkDate, GenJournalLine."Document Type"::Invoice, LibraryRandom.RandIntInRange(1000, 2000), CustomerNo, '');
        PaymentAmount := -GenJournalLine.Amount + GenJournalLine.Amount * GetPmtTermsDiscountPct / 100;

        // [GIVEN] Sales Journal with Payment Amount = 9800 and applied to posted Invoice. No dimension is set.
        // [WHEN] Post Sales Journal
        asserterror LibrarySales.CreatePaymentAndApplytoInvoice(
            GenJournalLine, CustomerNo, GenJournalLine."Document No.", PaymentAmount);

        // [THEN] Error occurs: "A dimension used in Gen. Journal Line GENERAL, CASH, 10000 has caused an error."
        Assert.ExpectedErrorCode(DialogTxt);
        Assert.ExpectedError(
          StrSubstNo(DimensionUsedErr,
            GenJournalLine.TableCaption, GenJournalLine."Journal Template Name",
            GenJournalLine."Journal Batch Name", GenJournalLine."Line No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtJnlApplToInvWithDimDiscountAndDefDim()
    var
        DimensionValue: Record "Dimension Value";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        CustomerNo: Code[20];
        GLAccountNo: Code[20];
        PaymentAmount: Decimal;
    begin
        // [FEATURE] [Dimension] [Payment Discount]
        // [SCENARIO 376797] Sales payment journal with dimension applied to posted Invoice can be posted in case of Discount, "Payment Disc. Debit Acc." with default dimension with "Value Posting" = "Same Code"
        Initialize;

        // [GIVEN] Customer with "Payment Disc. Debit Acc." = "A"
        // [GIVEN] Default Dimension "D" with "Value Posting" = "Same Code" is set for G/L Account "A"
        CustomerNo := CreateCustomer;
        GLAccountNo := CreateCustPostingGrPmtDiscDebitAccNo(CustomerNo);
        CreateDefaultDimensionGLAccSameValue(DimensionValue, GLAccountNo);

        // [GIVEN] Posted Sales Invoice with Amount Including VAT = 10000 and possible Discount = 2%. No dimension is set.
        CreateAndPostGenJnlLine(
          GenJournalLine, WorkDate, GenJournalLine."Document Type"::Invoice, LibraryRandom.RandIntInRange(1000, 2000), CustomerNo, '');
        PaymentAmount := -GenJournalLine.Amount + GenJournalLine.Amount * GetPmtTermsDiscountPct / 100;

        // [GIVEN] Sales Journal with Payment Amount = 9800 and applied to posted Invoice. Dimension "D" is set.
        CreateGenJnlLineWithAppliesToDocNo(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CustomerNo, GenJournalLine."Document No.");
        GenJournalLine.Validate("Dimension Set ID", LibraryDimension.CreateDimSet(0, DimensionValue."Dimension Code", DimensionValue.Code));
        GenJournalLine.Validate(Amount, PaymentAmount);
        GenJournalLine.Modify();

        // [WHEN] Post Sales Journal
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Posted G/L Entry with "G/L Account No." = "A" has Dimension "D"
        FindGLEntry(GLEntry, GenJournalLine."Document No.", GLAccountNo);
        Assert.AreEqual(GenJournalLine."Dimension Set ID", GLEntry."Dimension Set ID", GLEntry.FieldCaption("Dimension Set ID"))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtToInvApplWithNoDimDiscountAndDefDim()
    var
        DimensionValue: Record "Dimension Value";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        CustomerNo: Code[20];
        InvoiceDocumentNo: Code[20];
        GLAccountNo: Code[20];
        PaymentAmount: Decimal;
    begin
        // [FEATURE] [Dimension] [Payment Discount]
        // [SCENARIO 376797] Posted sales payment without dimension can be applied to posted Invoice in case of Discount, "Payment Disc. Debit Acc." with default dimension with "Value Posting" = "Same Code"
        Initialize;

        // [GIVEN] Customer with "Payment Disc. Debit Acc." = "A"
        // [GIVEN] Default Dimension "D" with "Value Posting" = "Same Code" is set for G/L Account "A"
        CustomerNo := CreateCustomer;
        GLAccountNo := CreateCustPostingGrPmtDiscDebitAccNo(CustomerNo);
        CreateDefaultDimensionGLAccSameValue(DimensionValue, GLAccountNo);

        // [GIVEN] Posted Sales Invoice with Amount Including VAT = 10000 and possible Discount = 2%. No dimension is set.
        CreateAndPostGenJnlLine(
          GenJournalLine, WorkDate, GenJournalLine."Document Type"::Invoice, LibraryRandom.RandIntInRange(1000, 2000), CustomerNo, '');
        InvoiceDocumentNo := GenJournalLine."Document No.";
        PaymentAmount := -GenJournalLine.Amount + GenJournalLine.Amount * GetPmtTermsDiscountPct / 100;

        // [GIVEN] Posted Sales Payment with Amount = 9800. No dimension is set.
        CreateAndPostGenJnlLine(
          GenJournalLine, WorkDate, GenJournalLine."Document Type"::Payment,
          PaymentAmount, GenJournalLine."Account No.", '');

        // [WHEN] Post Payment to Invoice application
        ApplyAndPostPaymentToInvoice(GenJournalLine."Document No.", InvoiceDocumentNo);

        // [THEN] Posted G/L Entry with "G/L Account No." = "A" has no Dimension ("Dimension Set ID" = 0).
        FindGLEntry(GLEntry, GenJournalLine."Document No.", GLAccountNo);
        Assert.AreEqual(0, GLEntry."Dimension Set ID", GLEntry.FieldCaption("Dimension Set ID"))
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesWithSetAppliesToIDModalPageHandler,GeneralJournalTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ClearAmountToApplyWhenDeleteAppliesToIDUT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
        ExpectedAmount: Decimal;
    begin
        // [FEATURE] [Application] [Cash Receipt]
        // [SCENARIO 230936] When deleting the value in "Applies-to-ID" field on the "Apply Customer Entries" page manually, "Amount to Apply" must be reset to zero

        // [GIVEN] Posted Sales Invoice
        Initialize;

        PostInvoice(GenJournalLine);
        ExpectedAmount := GenJournalLine.Amount;

        // [GIVEN] Create Cash Receipt Journal Line
        CreateCashReceiptJnlLine(GenJournalLine, GenJournalLine."Account No.");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        Commit();

        CashReceiptJournal.OpenEdit;
        CashReceiptJournal."Applies-to Doc. Type".SetValue(GenJournalLine."Applies-to Doc. Type"::Invoice);

        // [GIVEN] Open "Apply Customer Entries" page
        LibraryVariableStorage.Enqueue(ExpectedAmount);
        CashReceiptJournal."Apply Entries".Invoke;

        // [GIVEN] Use "Set Applies-to ID"
        // Done in ApplyCustomerEntriesWithSetAppliesToIDModalPageHandler

        // [WHEN] Manually remove "Applies-to ID"
        // Done in ApplyCustomerEntriesWithSetAppliesToIDModalPageHandler

        // [THEN] "Amount to apply" on "Apply Customer Entries" page is 0
        // Done in ApplyCustomerEntriesWithSetAppliesToIDModalPageHandler

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('TwoApplyCustomerEntriesModalPageHandler,GeneralJournalTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ClearAppliesToIDInOneRecordOfSeveralCustLedgEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // [FEATURE] [Application] [Cash Receipt]
        // [SCENARIO 230936] When deleting the value in "Applies-to-ID" field on the "Apply Customer Entries" page manually, "Applies-to-ID" should not be deleted in other lines having the same "Applies-to-ID"

        Initialize;

        // [GIVEN] Two Posted Sales Invoices
        CreateAndPostTwoGenJournalLinesForSameCustomer(GenJournalLine);

        // [GIVEN] Create Cash Receipt Journal Line
        CreateCashReceiptJnlLine(GenJournalLine, GenJournalLine."Account No.");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        Commit();

        CashReceiptJournal.OpenEdit;
        CashReceiptJournal."Applies-to Doc. Type".SetValue(GenJournalLine."Applies-to Doc. Type"::Invoice);

        // [GIVEN] Open "Apply Customer Entries" page with two lines
        CashReceiptJournal."Apply Entries".Invoke;

        // [GIVEN] Use "Set Applies-to ID" on both lines, "Applies-to ID" of the 1st line = "A", "Applies-to ID" of the 2nd line = "A"
        // Done in SeveralEntriesWithSameAppliesToIDModalPageHandler

        // [WHEN] Manually remove "Applies-to ID" on the 2nd line
        // Done in SeveralEntriesWithSameAppliesToIDModalPageHandler

        // [THEN] "Applies-to ID" of the 1st line = "A"
        // Done in SeveralEntriesWithSameAppliesToIDModalPageHandler

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('TwoEntriesWithSameAppliesToIDModalPageHandler,GeneralJournalTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure SetAppliesToIDInOneRecordOfSeveralCustLedgEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // [FEATURE] [Application] [Cash Receipt]
        // [SCENARIO 230936] When manually set the value in "Applies-to-ID" field on the "Apply Customer Entries" page, "Applies-to-ID" of the other lines with the same value is not changed

        Initialize;

        // [GIVEN] Two Posted Sales Invoices
        CreateAndPostTwoGenJournalLinesForSameCustomer(GenJournalLine);

        // [GIVEN] Create Cash Receipt Journal Line
        CreateCashReceiptJnlLine(GenJournalLine, GenJournalLine."Account No.");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        Commit();

        CashReceiptJournal.OpenEdit;
        CashReceiptJournal."Applies-to Doc. Type".SetValue(GenJournalLine."Applies-to Doc. Type"::Invoice);

        // [GIVEN] Open "Apply Customer Entries" page with two lines
        CashReceiptJournal."Apply Entries".Invoke;

        // [GIVEN] Use "Set Applies-to ID" action on 1st line, "Applies-to ID" of the 1st line = "A"
        // Done in SeveralApplyCustomerEntriesModalPageHandler

        // [WHEN] Manually set "Applies-to ID" on the 2nd line = "A"
        // Done in SeveralApplyCustomerEntriesModalPageHandler

        // [THEN] "Applies-to ID" of the 1st line = "A"
        // Done in SeveralApplyCustomerEntriesModalPageHandler

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('TwoEntriesWithDifferentAppliesToIDModalPageHandler,GeneralJournalTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure SetDifferentAppliesToIDInOneRecordOfSeveralCustLedgEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // [FEATURE] [Application] [Cash Receipt]
        // [SCENARIO 230936] When manually set the value in "Applies-to-ID" field on the "Apply Customer Entries" page, "Applies-to-ID" of the other lines with different value is not changed

        Initialize;

        // [GIVEN] Two Posted Sales Invoices
        CreateAndPostTwoGenJournalLinesForSameCustomer(GenJournalLine);

        // [GIVEN] Create Cash Receipt Journal Line
        CreateCashReceiptJnlLine(GenJournalLine, GenJournalLine."Account No.");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        Commit();

        CashReceiptJournal.OpenEdit;
        CashReceiptJournal."Applies-to Doc. Type".SetValue(GenJournalLine."Applies-to Doc. Type"::Invoice);

        // [GIVEN] Open "Apply Customer Entries" page with two lines
        CashReceiptJournal."Apply Entries".Invoke;

        // [GIVEN] Use "Set Applies-to ID" action on 1st line, "Applies-to ID" of the 1st line = "A"
        // Done in SeveralEntriesWithDifferentAppliesToIDModalPageHandler

        // [WHEN] Manually set "Applies-to ID" of the 2nd line = "B"
        // Done in SeveralEntriesWithDifferentAppliesToIDModalPageHandler

        // [THEN] "Applies-to ID" of the 1st line = "A", "Applies-to ID" of the 2nd line = "B"
        // Done in SeveralEntriesWithDifferentAppliesToIDModalPageHandler

        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('GeneralJournalTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyExtDocNoWhenAppliesToDocSetValue()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
        PostedDocNo: Code[35];
        OriginalExtDocNo: Code[35];
        InvoiceExtDocNo: Code[35];
    begin
        // [FEATURE] [Application] [Cash Receipt]
        // [SCENARIO 278790] Verify that External Doc No is not filled when looking up 'Applies-to Doc. No.' value and "Applies-to Ext. Doc. No" is
        Initialize;

        // [GIVEN] Invoice customer ('External Document No.' non-empty).
        PostInvoice(GenJournalLine);
        PostedDocNo := GenJournalLine."Document No.";
        InvoiceExtDocNo := GenJournalLine."External Document No.";

        // [GIVEN] Create Cash Receipt Journal Line for the customer with a filled external doc no but empty Account No
        CreateCashReceiptJnlLine(GenJournalLine, '');
        OriginalExtDocNo := GenJournalLine."External Document No.";

        // [GIVEN] Cash Receipt Journal was open
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        Commit();
        CashReceiptJournal.OpenEdit;

        // [WHEN] Set 'Applies-to Doc. No.' value to Posted Invoice doc. no.
        CashReceiptJournal."Applies-to Doc. No.".SetValue(PostedDocNo);
        CashReceiptJournal.OK.Invoke;

        // [THEN] External doc. no. of posted invoice is not transferred to 'External Document No.' of Cash Receipt Journal Line
        GenJournalLine.Find;
        GenJournalLine.TestField("External Document No.", OriginalExtDocNo);
        // [THEN] Applies-to Ext. Doc. No. of Cash Receipt Journal Line contains External Document No. of the posted invoice
        GenJournalLine.TestField("Applies-to Ext. Doc. No.", InvoiceExtDocNo);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Apply Sales/Receivables");

        LibraryVariableStorage.Clear;
        LibrarySetupStorage.Restore;
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Apply Sales/Receivables");
        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateAccountInCustomerPostingGroup;
        LibraryERMCountryData.UpdateGeneralLedgerSetup;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        ModifyGenJnlBatchNoSeries;
        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Apply Sales/Receivables");
    end;

    local procedure ApplyAndPostPaymentToInvoice(PmtDocumentNo: Code[20]; InvDocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::Payment, CustLedgerEntry."Document Type"::Invoice,
          PmtDocumentNo, InvDocumentNo);
    end;

    local procedure PostAndApplyGenLines(var GenJournalLine: Record "Gen. Journal Line"; DueDate: Date) DocumentNo: Code[20]
    begin
        // Setup: Create Invoice and Payment General Lines and Post them.
        CreateAndPostGenJnlLine(
          GenJournalLine, WorkDate, GenJournalLine."Document Type"::Invoice, LibraryRandom.RandInt(10000), CreateCustomer, '');
        DocumentNo := GenJournalLine."Document No.";
        CreateAndPostGenJnlLine(
          GenJournalLine, DueDate, GenJournalLine."Document Type"::Payment, -GenJournalLine.Amount, GenJournalLine."Account No.", '');

        // Exercise: Apply a Payment to Invoice.
        ApplyAndPostPaymentToInvoice(GenJournalLine."Document No.", DocumentNo);
    end;

    local procedure CalcDueDateAndPaymentDiscount(var DueDate: Date; var PaymentDiscountPercent: Decimal)
    var
        PaymentTerms: Record "Payment Terms";
    begin
        // Calculate Due Date and Discount Percentage.
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        DueDate := CalcDate(PaymentTerms."Discount Date Calculation", WorkDate);
        PaymentDiscountPercent := PaymentTerms."Discount %";
    end;

    local procedure CreateCurrency(ApplnRoundingPrecision: Decimal): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Residual Gains Account", Currency."Realized Gains Acc.");
        Currency.Validate("Residual Losses Account", Currency."Realized Losses Acc.");
        Currency.Validate("Appln. Rounding Precision", ApplnRoundingPrecision);
        Currency.Modify(true);

        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        PaymentTerms: Record "Payment Terms";
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateAndPostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; DocumentType: Option; Amount: Decimal; CustomerNo: Code[20]; CurrencyCode: Code[10])
    begin
        CreateGenJnlLine(GenJournalLine, PostingDate, DocumentType, Amount, CustomerNo, CurrencyCode);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; DocumentType: Option; Amount: Decimal; CustomerNo: Code[20]; CurrencyCode: Code[10])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAndPostTwoGenJournalLinesForSameCustomer(var GenJournalLine: Record "Gen. Journal Line")
    var
        CustomerNo: Code[20];
    begin
        CustomerNo := LibrarySales.CreateCustomerNo;
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer,
          CustomerNo, LibraryRandom.RandIntInRange(1000, 2000));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer,
          CustomerNo, LibraryRandom.RandIntInRange(1000, 2000));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostApplyGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Option; DocumentType2: Option; CurrencyCode: Code[10]; Amount: Decimal; AppRounding: Decimal) DocumentNo: Code[20]
    var
        Customer: Record Customer;
    begin
        // Setup: Create Invoice Line and Post with Currency without Application Rounding then Payment Line with Currency
        // Application Rounding.
        LibrarySales.CreateCustomer(Customer);
        CreateAndPostGenJnlLine(GenJournalLine, WorkDate, DocumentType, Amount, Customer."No.", CurrencyCode);
        DocumentNo := GenJournalLine."Document No.";
        CreateAndPostGenJnlLine(
          GenJournalLine, WorkDate, DocumentType2, -GenJournalLine.Amount + AppRounding, Customer."No.", CreateCurrency(AppRounding));
        LibraryERM.ApplyCustomerLedgerEntries(DocumentType2, DocumentType, GenJournalLine."Document No.", DocumentNo);
    end;

    local procedure CreateGenJnlLineWithAppliesToID(var GenJnlLine: Record "Gen. Journal Line"; AccType: Option; AccNo: Code[20]; AppliesToID: Code[50])
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        with GenJnlLine do begin
            LibraryERM.SelectGenJnlBatch(GenJnlBatch);
            LibraryERM.CreateGeneralJnlLine(
              GenJnlLine, GenJnlBatch."Journal Template Name", GenJnlBatch.Name, "Document Type"::Payment, AccType, AccNo, 0);
            "Applies-to ID" := AppliesToID;
            Modify;
        end;
    end;

    local procedure CreateGenJnlLineWithAppliesToDocNo(var GenJnlLine: Record "Gen. Journal Line"; AccType: Option; AccNo: Code[20]; AppliesToDocNo: Code[20])
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        with GenJnlLine do begin
            LibraryERM.SelectGenJnlBatch(GenJnlBatch);
            LibraryERM.CreateGeneralJnlLine(
              GenJnlLine, GenJnlBatch."Journal Template Name", GenJnlBatch.Name, "Document Type"::Payment, AccType, AccNo, 0);
            "Applies-to Doc. Type" := "Applies-to Doc. Type"::Invoice;
            "Applies-to Doc. No." := AppliesToDocNo;
            Modify;
        end;
    end;

    local procedure CreateCashReceiptJnlLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        with GenJournalTemplate do begin
            LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
            Validate(Type, Type::"Cash Receipts");
            Modify(true);
            LibraryERM.CreateGenJournalBatch(GenJournalBatch, Name);
        end;

        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, AccountNo,
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo, 0);
    end;

    local procedure CreateDefaultDimensionGLAccSameValue(var DimensionValue: Record "Dimension Value"; GLAccountNo: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccountNo, DimensionValue."Dimension Code", DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Same Code");
        DefaultDimension.Modify();
    end;

    local procedure CreateCustPostingGrPmtDiscDebitAccNo(CustomerNo: Code[20]): Code[20]
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        CustomerPostingGroup.Validate("Payment Disc. Debit Acc.", LibraryERM.CreateGLAccountNo);
        CustomerPostingGroup.Modify(true);
        exit(CustomerPostingGroup."Payment Disc. Debit Acc.");
    end;

    local procedure PostInvoice(var GenJournalLine: Record "Gen. Journal Line")
    begin
        with GenJournalLine do begin
            CreateGenJnlLine(
              GenJournalLine, WorkDate, "Document Type"::Invoice, LibraryRandom.RandIntInRange(1000, 2000),
              LibrarySales.CreateCustomerNo, '');
            Validate("External Document No.", LibraryUtility.GenerateGUID);
            Modify(true);
            LibraryERM.PostGeneralJnlLine(GenJournalLine);
        end;
    end;

    local procedure FindDetailedLedgerEntry(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; DocumentNo: Code[20]; EntryType: Option)
    begin
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.SetRange("Entry Type", EntryType);
        DetailedCustLedgEntry.FindFirst;
    end;

    local procedure FindOpenInvCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        with CustLedgEntry do begin
            SetRange("Document Type", "Document Type"::Invoice);
            SetRange("Applying Entry", false);
            SetRange(Open, true);
            FindFirst;
        end;
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GLAccountNo: Code[20])
    begin
        with GLEntry do begin
            SetRange("Document No.", DocumentNo);
            SetRange("G/L Account No.", GLAccountNo);
            FindFirst;
        end;
    end;

    local procedure SetAppliesToIDOnCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgEntry."Applies-to ID" := LibraryUtility.GenerateGUID;
        CustLedgEntry.Modify();
    end;

    local procedure GetPmtTermsDiscountPct(): Decimal
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        exit(PaymentTerms."Discount %");
    end;

    local procedure ModifyGenJnlBatchNoSeries()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJnlBatch);
        GenJnlBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode);
        GenJnlBatch.Modify(true);
    end;

    local procedure UnapplyCustLedgerEntry(DocumentType: Option; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
    end;

    local procedure VerifyApplnRoundingCustLedger(DocumentNo: Code[20]; Amount: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Assert: Codeunit Assert;
    begin
        FindDetailedLedgerEntry(DetailedCustLedgEntry, DocumentNo, DetailedCustLedgEntry."Entry Type"::"Appln. Rounding");
        Assert.AreEqual(
          Amount, DetailedCustLedgEntry.Amount,
          StrSubstNo(WrongValErr, DetailedCustLedgEntry.FieldCaption(Amount), Amount, DetailedCustLedgEntry.TableCaption));
    end;

    local procedure VerifyPaymentWithDiscount(DocumentNo: Code[20]; Amount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // Select Customer Payment Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, DocumentNo);

        // Verify Payment Discount.
        FindDetailedLedgerEntry(
          DetailedCustLedgEntry, CustLedgerEntry."Document No.", DetailedCustLedgEntry."Entry Type"::"Payment Discount");
        CustLedgerEntry.TestField(Open);
        DetailedCustLedgEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyPaymentWithoutDiscount(DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // If Payment is made after Due Date, verify "Original Pmt Disc. Possible" equal to zero and "Open" must be FALSE in the Customer
        // Ledger Entry.

        // Select Customer Payment Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, DocumentNo);

        // Verify Payment Discount.
        CustLedgerEntry.TestField(Open, false);
        CustLedgerEntry.TestField("Original Pmt. Disc. Possible", 0);
    end;

    local procedure VerifyUnapplyPaymentDiscount(DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Verify "Original Pmt Disc. Possible" and "Remaining Pmt. Disc. Possible" should be equal in the Customer Ledger Entry.

        // Select Customer Invoice Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);

        // Verify Unapply Payment Discount.
        CustLedgerEntry.CalcFields("Original Amount", "Original Amt. (LCY)", "Remaining Amount", "Remaining Amt. (LCY)");
        CustLedgerEntry.TestField("Original Amount", CustLedgerEntry."Remaining Amount");
        CustLedgerEntry.TestField("Original Amt. (LCY)", CustLedgerEntry."Remaining Amt. (LCY)");
        CustLedgerEntry.TestField("Original Pmt. Disc. Possible", CustLedgerEntry."Remaining Pmt. Disc. Possible");
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; CurrencyCode: Code[10]; DocumentType: Option; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst;
        Assert.AreNearlyEqual(
          Amount / 2, LibraryERM.ConvertCurrency(Amount, '', CurrencyCode, WorkDate), Currency."Amount Rounding Precision",
          'Amount must be equal');
    end;

    local procedure VerifyExtDocNoAmount(GenJournalLine: Record "Gen. Journal Line"; ExpectedExtDocNo: Code[35]; ExpectedAmount: Decimal)
    begin
        with GenJournalLine do begin
            Find;
            Assert.AreEqual(
              ExpectedExtDocNo, "Applies-to Ext. Doc. No.",
              StrSubstNo(WrongValErr, FieldCaption("Applies-to Ext. Doc. No."), ExpectedExtDocNo, TableCaption));
            Assert.AreEqual(
              ExpectedAmount, Amount,
              StrSubstNo(WrongValErr, FieldCaption(Amount), ExpectedAmount, TableCaption));
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesWithSetAppliesToIDModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke;
        ApplyCustomerEntries.AppliedAmount.AssertEquals(LibraryVariableStorage.DequeueDecimal);

        ApplyCustomerEntries.AppliesToID.SetValue('');
        ApplyCustomerEntries.AppliedAmount.AssertEquals(0);
        ApplyCustomerEntries."Amount to Apply".AssertEquals(0);
        ApplyCustomerEntries.ApplnAmountToApply.AssertEquals(0);

        ApplyCustomerEntries.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TwoApplyCustomerEntriesModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    var
        AppliesToID: Code[20];
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke;
        AppliesToID := ApplyCustomerEntries.AppliesToID.Value;

        ApplyCustomerEntries.Next;
        ApplyCustomerEntries."Set Applies-to ID".Invoke;
        ApplyCustomerEntries.AppliesToID.SetValue('');
        ApplyCustomerEntries.AppliesToID.AssertEquals('');

        ApplyCustomerEntries.Previous;
        ApplyCustomerEntries.AppliesToID.AssertEquals(AppliesToID);

        ApplyCustomerEntries.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TwoEntriesWithSameAppliesToIDModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    var
        AppliesToID: Code[20];
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke;
        AppliesToID := ApplyCustomerEntries.AppliesToID.Value;

        ApplyCustomerEntries.Next;
        ApplyCustomerEntries.AppliesToID.SetValue(AppliesToID);
        ApplyCustomerEntries.AppliesToID.AssertEquals(AppliesToID);

        ApplyCustomerEntries.Previous;
        ApplyCustomerEntries.AppliesToID.AssertEquals(AppliesToID);

        ApplyCustomerEntries.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TwoEntriesWithDifferentAppliesToIDModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    var
        AppliesToID: Code[20];
        AlternativeAppliesToID: Code[20];
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke;
        AppliesToID := ApplyCustomerEntries.AppliesToID.Value;

        ApplyCustomerEntries.Next;
        AlternativeAppliesToID := LibraryUtility.GenerateGUID;
        ApplyCustomerEntries.AppliesToID.SetValue(AlternativeAppliesToID);
        ApplyCustomerEntries.AppliesToID.AssertEquals(AlternativeAppliesToID);

        ApplyCustomerEntries.Previous;
        ApplyCustomerEntries.AppliesToID.AssertEquals(AppliesToID);

        ApplyCustomerEntries.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalTemplateListModalPageHandler(var GeneralJournalTemplateList: TestPage "General Journal Template List")
    begin
        GeneralJournalTemplateList.GotoKey(LibraryVariableStorage.DequeueText);
        GeneralJournalTemplateList.OK.Invoke;
    end;
}

