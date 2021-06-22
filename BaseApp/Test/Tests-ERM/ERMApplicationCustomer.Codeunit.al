codeunit 134010 "ERM Application Customer"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryERMCustomerWatch: Codeunit "Library - ERM Customer Watch";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        DeltaAssert: Codeunit "Delta Assert";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        CustomerAmount: Decimal;
        ExchRateWasAdjustedTxt: Label 'One or more currency exchange rates have been adjusted.';
        WrongBalancePerTransNoErr: Label 'Wrong total amount of detailed entries per transaction.';

    [Test]
    [Scope('OnPrem')]
    procedure CustomerNoDiscount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize;

        for Stepwise := false to true do
            with GenJournalLine do begin
                CustomerInvPmt("Document Type"::Payment, "Document Type"::Invoice, CustomerAmount, Stepwise);
                CustomerInvPmt("Document Type"::Refund, "Document Type"::"Credit Memo", -CustomerAmount, Stepwise);
                CustomerInvPmt("Document Type"::Payment, "Document Type"::Refund, CustomerAmount, Stepwise);
                CustomerInvPmt("Document Type"::Invoice, "Document Type"::"Credit Memo", -CustomerAmount, Stepwise);
            end;

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerDiscount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize;

        for Stepwise := false to true do
            with GenJournalLine do begin
                CustomerInvPmtDisc("Document Type"::Payment, "Document Type"::Invoice, CustomerAmount, Stepwise);
                CustomerInvPmtDisc("Document Type"::Refund, "Document Type"::"Credit Memo", -CustomerAmount, Stepwise);
                // The following two combinations do not generate discount ledger entries and will thus fail to close.
                asserterror CustomerInvPmtDisc("Document Type"::Payment, "Document Type"::Refund, CustomerAmount, Stepwise);
                DeltaAssert.Reset;
                asserterror CustomerInvPmtDisc("Document Type"::Invoice, "Document Type"::"Credit Memo", -CustomerAmount, Stepwise);
                DeltaAssert.Reset;
            end;

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerVAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize;

        for Stepwise := false to true do
            with GenJournalLine do begin
                CustomerInvPmtVAT("Document Type"::Payment, "Document Type"::Invoice, CustomerAmount, Stepwise);
                CustomerInvPmtVAT("Document Type"::Refund, "Document Type"::"Credit Memo", -CustomerAmount, Stepwise);
                CustomerInvPmtVAT("Document Type"::Payment, "Document Type"::Refund, CustomerAmount, Stepwise);
                CustomerInvPmtVAT("Document Type"::Invoice, "Document Type"::"Credit Memo", -CustomerAmount, Stepwise);
            end;

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCorrection()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize;

        for Stepwise := false to true do
            with GenJournalLine do begin
                CustomerInvPmtCorrection("Document Type"::Payment, "Document Type"::Invoice, CustomerAmount, Stepwise);
                CustomerInvPmtCorrection("Document Type"::Refund, "Document Type"::"Credit Memo", -CustomerAmount, Stepwise);
                CustomerInvPmtCorrection("Document Type"::Payment, "Document Type"::Refund, CustomerAmount, Stepwise);
                CustomerInvPmtCorrection("Document Type"::Invoice, "Document Type"::"Credit Memo", -CustomerAmount, Stepwise);
            end;

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerDiscVATAdjust()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize;

        for Stepwise := false to true do
            with GenJournalLine do begin
                CustomerPmtDiscVATAdjust("Document Type"::Payment, "Document Type"::Invoice, CustomerAmount, Stepwise);
                CustomerPmtDiscVATAdjust("Document Type"::Refund, "Document Type"::"Credit Memo", -CustomerAmount, Stepwise);
                // The following two combinations do not generate payment tolerance ledger entries and will thus fail to close.
                asserterror CustomerPmtDiscVATAdjust("Document Type"::Payment, "Document Type"::Refund, CustomerAmount, Stepwise);
                asserterror CustomerPmtDiscVATAdjust("Document Type"::Invoice, "Document Type"::"Credit Memo", -CustomerAmount, Stepwise);
            end;

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerTolVATAdjust()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize;

        SetupPaymentTolerance;

        for Stepwise := false to true do
            with GenJournalLine do begin
                CustomerPmtTolVATAdjust("Document Type"::Payment, "Document Type"::Invoice, CustomerAmount, Stepwise);
                CustomerPmtTolVATAdjust("Document Type"::Refund, "Document Type"::"Credit Memo", -CustomerAmount, Stepwise);
                // The following two combinations do not generate payment tolerance ledger entries and will thus fail to close.
                asserterror CustomerPmtTolVATAdjust("Document Type"::Payment, "Document Type"::Refund, CustomerAmount, Stepwise);
                asserterror CustomerPmtTolVATAdjust("Document Type"::Invoice, "Document Type"::"Credit Memo", -CustomerAmount, Stepwise);
            end;

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerDiscTolVATAdjust()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize;

        LibraryPmtDiscSetup.SetPmtDiscGracePeriodByText('<5D>');

        for Stepwise := false to true do
            with GenJournalLine do begin
                CustomerPmtDiscTolVATAdjust("Document Type"::Payment, "Document Type"::Invoice, CustomerAmount, Stepwise);
                CustomerPmtDiscTolVATAdjust("Document Type"::Refund, "Document Type"::"Credit Memo", -CustomerAmount, Stepwise);
                // The following two combinations do not generate payment discount / tolerance ledger entries and will thus fail to close.
                asserterror CustomerPmtDiscTolVATAdjust("Document Type"::Payment, "Document Type"::Refund, CustomerAmount, Stepwise);
                asserterror CustomerPmtDiscTolVATAdjust("Document Type"::Invoice, "Document Type"::"Credit Memo", -CustomerAmount, Stepwise);
            end;

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerRealizedGain()
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize;

        for Stepwise := false to true do
            with GenJournalLine do begin
                CustomerRealizedAdjust("Document Type"::Payment, "Document Type"::Invoice, CustomerAmount, Stepwise,
                  0.9, DtldCustLedgEntry."Entry Type"::"Realized Loss");
                CustomerRealizedAdjust("Document Type"::Refund, "Document Type"::"Credit Memo", -CustomerAmount, Stepwise,
                  1.1, DtldCustLedgEntry."Entry Type"::"Realized Loss");
                CustomerRealizedAdjust("Document Type"::Payment, "Document Type"::Refund, CustomerAmount, Stepwise,
                  0.9, DtldCustLedgEntry."Entry Type"::"Realized Loss");
                CustomerRealizedAdjust("Document Type"::Invoice, "Document Type"::"Credit Memo", -CustomerAmount, Stepwise,
                  1.1, DtldCustLedgEntry."Entry Type"::"Realized Loss");
            end;

        TearDown;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerRealizedLoss()
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize;

        for Stepwise := false to true do
            with GenJournalLine do begin
                CustomerRealizedAdjust("Document Type"::Payment, "Document Type"::Invoice, CustomerAmount, Stepwise,
                  1.1, DtldCustLedgEntry."Entry Type"::"Realized Gain");
                CustomerRealizedAdjust("Document Type"::Refund, "Document Type"::"Credit Memo", -CustomerAmount, Stepwise,
                  0.9, DtldCustLedgEntry."Entry Type"::"Realized Gain");
                CustomerRealizedAdjust("Document Type"::Payment, "Document Type"::Refund, CustomerAmount, Stepwise,
                  1.1, DtldCustLedgEntry."Entry Type"::"Realized Gain");
                CustomerRealizedAdjust("Document Type"::Invoice, "Document Type"::"Credit Memo", -CustomerAmount, Stepwise,
                  0.9, DtldCustLedgEntry."Entry Type"::"Realized Gain");
            end;

        TearDown;
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerUnrealizedGain()
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize;

        for Stepwise := false to true do
            with GenJournalLine do begin
                CustomerUnrealizedAdjust("Document Type"::Payment, "Document Type"::Invoice, CustomerAmount, Stepwise,
                  0.9, DtldCustLedgEntry."Entry Type"::"Realized Loss");
                CustomerUnrealizedAdjust("Document Type"::Refund, "Document Type"::"Credit Memo", -CustomerAmount, Stepwise,
                  1.1, DtldCustLedgEntry."Entry Type"::"Realized Loss");
                CustomerUnrealizedAdjust("Document Type"::Payment, "Document Type"::Refund, CustomerAmount, Stepwise,
                  0.9, DtldCustLedgEntry."Entry Type"::"Realized Loss");
                CustomerUnrealizedAdjust("Document Type"::Invoice, "Document Type"::"Credit Memo", -CustomerAmount, Stepwise,
                  1.1, DtldCustLedgEntry."Entry Type"::"Realized Loss");
            end;

        TearDown;
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure CustomerUnrealizedLoss()
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize;

        for Stepwise := false to true do
            with GenJournalLine do begin
                CustomerUnrealizedAdjust("Document Type"::Payment, "Document Type"::Invoice, CustomerAmount, Stepwise,
                  1.1, DtldCustLedgEntry."Entry Type"::"Realized Gain");
                CustomerUnrealizedAdjust("Document Type"::Refund, "Document Type"::"Credit Memo", -CustomerAmount, Stepwise,
                  0.9, DtldCustLedgEntry."Entry Type"::"Realized Gain");
                CustomerUnrealizedAdjust("Document Type"::Payment, "Document Type"::Refund, CustomerAmount, Stepwise,
                  1.1, DtldCustLedgEntry."Entry Type"::"Realized Gain");
                CustomerUnrealizedAdjust("Document Type"::Invoice, "Document Type"::"Credit Memo", -CustomerAmount, Stepwise,
                  0.9, DtldCustLedgEntry."Entry Type"::"Realized Gain");
            end;

        TearDown;
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure FutureCurrAdjTransaction()
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        LastTransactionNo: array[2] of Integer;
        TransactionNo: Integer;
        i: Integer;
        TotalAmount: Decimal;
        InvAmount: Decimal;
    begin
        // [FEATURE] [Adjust Exchange Rates] [Transaction No.]
        // [SCENARIO] Currency Adjustment job posts Detailed Customer Ledger Entries linked by "Transaction No." with related G/L Entries
        Initialize;

        // [GIVEN] Currency "FCY" with different rates on Workdate and on (WorkDate + 1)
        CurrencyCode := SetExchRateForCurrency(2);

        LibrarySales.CreateCustomer(Customer);

        GetGLBalancedBatch(GenJournalTemplate, GenJournalBatch, GenJournalTemplate.Type::General);
        for i := 1 to 3 do
            with GenJournalLine do begin
                // [GIVEN] Post Invoice in "FCY" on WorkDate
                InvAmount := LibraryRandom.RandDec(1000, 2);
                DocumentNo :=
                  CreateJournalLine(
                    GenJournalLine, GenJournalBatch, "Document Type"::Invoice, "Account Type"::Customer,
                    Customer."No.", InvAmount, '<0D>', CurrencyCode, LibraryUtility.GenerateGUID, '');
                RunGenJnlPostLine(GenJournalLine);

                // [GIVEN] Post 1st partial Payment in "FCY" on WorkDate with application to Invoice
                CreateJournalLine(
                  GenJournalLine, GenJournalBatch, "Document Type"::Payment, "Account Type"::Customer,
                  Customer."No.", -InvAmount / (i + 1), '<0D>', CurrencyCode, LibraryUtility.GenerateGUID, '');
                Validate("Applies-to Doc. Type", "Applies-to Doc. Type"::Invoice);
                Validate("Applies-to Doc. No.", DocumentNo);
                Modify;
                RunGenJnlPostLine(GenJournalLine);

                // [GIVEN] Post 2nd partial Payment in "FCY" on (WorkDate + 2) with application to Invoice
                CreateJournalLine(
                  GenJournalLine, GenJournalBatch, "Document Type"::Payment, "Account Type"::Customer,
                  Customer."No.", -InvAmount - Amount, '<2D>', CurrencyCode, LibraryUtility.GenerateGUID, '');
                Validate("Applies-to Doc. Type", "Applies-to Doc. Type"::Invoice);
                Validate("Applies-to Doc. No.", DocumentNo);
                Modify;
                RunGenJnlPostLine(GenJournalLine);
            end;

        LastTransactionNo[1] := GetLastTransactionNo;

        // [WHEN] Run the Adjust Exchange Rates Batch job on (Workdate + 1)
        LibraryERM.RunAdjustExchangeRatesSimple(
          CurrencyCode, CalcDate('<1D>', WorkDate), CalcDate('<1D>', WorkDate));

        // [THEN] posted G/L Entries on different dates have different "Transaction No."
        // [THEN] Dtld. Customer Ledger Entries have same "Transaction No." with related G/L Entries
        LastTransactionNo[2] := GetLastTransactionNo;
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        for TransactionNo := LastTransactionNo[1] + 1 to LastTransactionNo[2] do begin
            GLEntry.SetRange("Transaction No.", TransactionNo);
            GLEntry.SetRange("G/L Account No.", CustomerPostingGroup."Receivables Account");
            GLEntry.FindLast;
            TotalAmount := 0;
            DtldCustLedgEntry.SetRange("Transaction No.", TransactionNo);
            DtldCustLedgEntry.FindSet;
            repeat
                TotalAmount += DtldCustLedgEntry."Amount (LCY)";
            until DtldCustLedgEntry.Next = 0;
            Assert.AreEqual(GLEntry.Amount, TotalAmount, WrongBalancePerTransNoErr);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_ApplyMultipleLedgEntriesBySetAppliesToId()
    var
        ApplyingCustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        CustEntrySetApplID: Codeunit "Cust. Entry-SetAppl.ID";
        AppliesToID: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 213825] Multiple customer ledger entries applies when call SetApplId function of codeunit "Cust. Entry-SetAppl.ID"

        Initialize;
        MockCustLedgEntry(ApplyingCustLedgerEntry);
        MockCustLedgEntry(CustLedgerEntry);
        MockCustLedgEntry(CustLedgerEntry2);
        CustLedgerEntry.SetRange("Entry No.", CustLedgerEntry."Entry No.", CustLedgerEntry2."Entry No.");
        AppliesToID := LibraryUtility.GenerateGUID;

        CustEntrySetApplID.SetApplId(CustLedgerEntry, ApplyingCustLedgerEntry, AppliesToID);

        VerifyAppliedLedgerEntry(CustLedgerEntry, AppliesToID);
        VerifyAppliedLedgerEntry(CustLedgerEntry2, AppliesToID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_ClearApplicationInforForMultipleAlreadyAppliedLedgEntriesBySetAppliesToId()
    var
        ApplyingCustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        CustEntrySetApplID: Codeunit "Cust. Entry-SetAppl.ID";
        AppliesToID: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 213825] Application information clears for already applied customer ledger entries when call SetApplId function of codeunit "Cust. Entry-SetAppl.ID"

        Initialize;
        MockCustLedgEntry(ApplyingCustLedgerEntry);
        MockAppliedCustLedgEntry(CustLedgerEntry);
        MockAppliedCustLedgEntry(CustLedgerEntry2);
        CustLedgerEntry.SetRange("Entry No.", CustLedgerEntry."Entry No.", CustLedgerEntry2."Entry No.");
        AppliesToID := LibraryUtility.GenerateGUID;

        CustEntrySetApplID.SetApplId(CustLedgerEntry, ApplyingCustLedgerEntry, AppliesToID);

        VerifyUnappliedLedgerEntry(CustLedgerEntry);
        VerifyUnappliedLedgerEntry(CustLedgerEntry2);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibrarySetupStorage.Restore;
        // Lazy Setup.
        if isInitialized then
            exit;

        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralLedgerSetup;
        LibraryERMCountryData.UpdateAccountInCustomerPostingGroup;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        CustomerAmount := -1000;  // Use a fixed amount to avoid rounding issues.
        isInitialized := true;
        Commit;
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
    end;

    local procedure CustomerRealizedAdjust(PmtType: Option; InvType: Option; Amount: Decimal; Stepwise: Boolean; CurrencyAdjustFactor: Decimal; DtldLedgerType: Option)
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        Desc: Text[30];
        InvAmount: Decimal;
        PmtAmount: Decimal;
    begin
        // Test without payment discount
        GetGLBalancedBatch(GenJournalTemplate, GenJournalBatch, GenJournalTemplate.Type::General);
        CreateCustomerWithPaymentTerms(Customer, GetPaymentTerms('0'));

        // Find currency code with realized gaisn/losses account
        Currency.Get(LibraryERM.CreateCurrencyWithGLAccountSetup);

        // Create new exchange rate
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        CurrencyExchangeRate.SetRange("Currency Code", Currency.Code);
        CurrencyExchangeRate.FindFirst;

        // Watch for Realized gain/loss dtld. ledger entries
        LibraryERMCustomerWatch.Init;
        LibraryERMCustomerWatch.DtldEntriesEqual(Customer."No.", DtldLedgerType, 0);

        // Generate a document that triggers application dtld. ledger entries.
        InvAmount := Amount;
        PmtAmount := LibraryERM.ConvertCurrency(InvAmount, Currency.Code, '', WorkDate) * CurrencyAdjustFactor;

        Desc := GenerateDocument(GenJournalBatch, Customer, PmtType, InvType, PmtAmount, InvAmount, '<0D>', '', Currency.Code);

        // Adjust the currency exchange rate of the document currency to trigger realized gain/loss
        CurrencyExchangeRate."Relational Exch. Rate Amount" *= CurrencyAdjustFactor;
        CurrencyExchangeRate."Relational Adjmt Exch Rate Amt" *= CurrencyAdjustFactor;
        CurrencyExchangeRate.Modify(true);

        CustomerApplyUnapply(Desc, Stepwise);

        LibraryERMCustomerWatch.AssertCustomer;
    end;

    local procedure CustomerUnrealizedAdjust(PmtType: Option; InvType: Option; Amount: Decimal; Stepwise: Boolean; CurrencyAdjustFactor: Decimal; DtldLedgerType: Option)
    var
        Currency: Record Currency;
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        Desc: Text[30];
        InvAmount: Decimal;
        PmtAmount: Decimal;
    begin
        // Test without payment discount
        GetGLBalancedBatch(GenJournalTemplate, GenJournalBatch, GenJournalTemplate.Type::General);
        CreateCustomerWithPaymentTerms(Customer, GetPaymentTerms('0'));

        Currency.Get(SetExchRateForCurrency(CurrencyAdjustFactor));

        // Watch for Realized gain/loss dtld. ledger entries
        LibraryERMCustomerWatch.Init;
        LibraryERMCustomerWatch.DtldEntriesEqual(Customer."No.", DtldLedgerType, 0);

        // Generate a document that triggers application dtld. ledger entries.
        InvAmount := Amount;
        PmtAmount := LibraryERM.ConvertCurrency(InvAmount, Currency.Code, '', WorkDate) * CurrencyAdjustFactor;

        Desc := GenerateDocument(GenJournalBatch, Customer, PmtType, InvType, PmtAmount, InvAmount, '<1D>', '', Currency.Code);

        // Run the Adjust Exchange Rates Batch job.
        LibraryERM.RunAdjustExchangeRatesSimple(
          Currency.Code, CalcDate('<1D>', WorkDate), CalcDate('<1D>', WorkDate));

        CustomerApplyUnapply(Desc, Stepwise);

        LibraryERMCustomerWatch.AssertCustomer;
    end;

    local procedure CustomerPmtDiscVATAdjust(PmtType: Option; InvType: Option; Amount: Decimal; Stepwise: Boolean)
    var
        Customer: Record Customer;
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // Tests the VAT adjustment detailed ledger entries created
        // when posting an application where the payment is overdue
        // but within the grace period of payment tolerance.

        // Find discounted payment terms
        CreateCustomerWithPaymentTerms(Customer, GetPaymentTerms('>0'));

        // Watch for detailed ledger entry type "Payment Discount Tolerance (VAT Adjustment)" and "Payment Discount Tolerance (VAT Excl.)"
        LibraryERMCustomerWatch.Init;
        LibraryERMCustomerWatch.DtldEntriesSigned(
          Amount, Customer."No.", DtldCustLedgEntry."Entry Type"::"Payment Discount (VAT Adjustment)", 0);
        LibraryERMCustomerWatch.DtldEntriesSigned(
          Amount, Customer."No.", DtldCustLedgEntry."Entry Type"::"Payment Discount (VAT Excl.)", 0);
        LibraryERMCustomerWatch.DtldEntriesSigned(
          Amount, Customer."No.", DtldCustLedgEntry."Entry Type"::"Payment Discount", 0);

        // Apply / Unapply with VAT posting setup
        CustomerApplyUnapplyVAT(
          Customer, PmtType, InvType, Amount - GetDiscount(Customer."Payment Terms Code", Amount), Amount, '<0D>', Stepwise);

        LibraryERMCustomerWatch.AssertCustomer;
    end;

    local procedure CustomerPmtTolVATAdjust(PmtType: Option; InvType: Option; Amount: Decimal; Stepwise: Boolean)
    var
        Customer: Record Customer;
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // Tests the VAT adjustment detailed ledger entries created
        // when posting an application that triggers payment tolerance

        // Find none discounted payment terms
        CreateCustomerWithPaymentTerms(Customer, GetPaymentTerms('0'));

        // Watch for detailed ledger entry type "Payment Tolerance (VAT Adjustment)" and "Payment Tolerance (VAT Excl.)"
        LibraryERMCustomerWatch.Init;
        LibraryERMCustomerWatch.DtldEntriesGreaterThan(
          Customer."No.", DtldCustLedgEntry."Entry Type"::"Payment Tolerance (VAT Adjustment)", 0);
        LibraryERMCustomerWatch.DtldEntriesGreaterThan(
          Customer."No.", DtldCustLedgEntry."Entry Type"::"Payment Tolerance (VAT Excl.)", 0);
        LibraryERMCustomerWatch.DtldEntriesGreaterThan(
          Customer."No.", DtldCustLedgEntry."Entry Type"::"Payment Tolerance", 0);

        // Apply / Unapply with VAT posting setup
        CustomerApplyUnapplyVAT(Customer, PmtType, InvType, Amount - GetPaymentTolerance, Amount, '<0D>', Stepwise);

        LibraryERMCustomerWatch.AssertCustomer;
    end;

    local procedure CustomerPmtDiscTolVATAdjust(PmtType: Option; InvType: Option; Amount: Decimal; Stepwise: Boolean)
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Offset: Text[30];
    begin
        // Tests the VAT adjustment detailed ledger entries created
        // when posting an application where the payment is overdue
        // but within the grace period of payment tolerance.

        // Find discounted payment terms
        PaymentTerms.Get(GetPaymentTerms('>0'));
        CreateCustomerWithPaymentTerms(Customer, PaymentTerms.Code);

        // Watch for detailed ledger entry type "Payment Discount Tolerance (VAT Adjustment)" and "Payment Discount Tolerance (VAT Excl.)"
        LibraryERMCustomerWatch.Init;
        LibraryERMCustomerWatch.DtldEntriesSigned(
          Amount, Customer."No.", DtldCustLedgEntry."Entry Type"::"Payment Discount Tolerance (VAT Adjustment)", 0);
        LibraryERMCustomerWatch.DtldEntriesSigned(
          Amount, Customer."No.", DtldCustLedgEntry."Entry Type"::"Payment Discount Tolerance (VAT Excl.)", 0);
        LibraryERMCustomerWatch.DtldEntriesSigned(
          Amount, Customer."No.", DtldCustLedgEntry."Entry Type"::"Payment Discount Tolerance", 0);

        // Trigger payment discount tolerance by exceeding discount due date by 1 day
        Offset := Format(PaymentTerms."Discount Date Calculation") + '+<1D>';

        // Apply / Unapply with VAT posting setup
        CustomerApplyUnapplyVAT(Customer, PmtType, InvType, Amount - GetDiscount(PaymentTerms.Code, Amount), Amount, Offset, Stepwise);

        LibraryERMCustomerWatch.AssertCustomer;
    end;

    local procedure CustomerInvPmt(PmtType: Option; InvType: Option; Amount: Decimal; Stepwise: Boolean)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Desc: Text[30];
    begin
        // Test without payment discount
        GetGLBalancedBatch(GenJournalTemplate, GenJournalBatch, GenJournalTemplate.Type::General);
        CreateCustomerWithPaymentTerms(Customer, GetPaymentTerms('0'));

        // Setup basic application watches
        LibraryERMCustomerWatch.Init;
        LibraryERMCustomerWatch.EntriesEqual(Customer."No.", InvType, -Amount);
        LibraryERMCustomerWatch.EntriesEqual(Customer."No.", PmtType, Amount);
        LibraryERMCustomerWatch.DtldEntriesEqual(Customer."No.", DtldCustLedgEntry."Entry Type"::"Initial Entry", 0);
        LibraryERMCustomerWatch.DtldEntriesGreaterThan(Customer."No.", DtldCustLedgEntry."Entry Type"::Application, 0);

        // Generate a document that triggers application dtld. ledger entries.
        Desc := GenerateDocument(GenJournalBatch, Customer, PmtType, InvType, Amount, Amount, '<0D>', '', '');
        CustomerApplyUnapply(Desc, Stepwise);

        LibraryERMCustomerWatch.AssertCustomer;
    end;

    local procedure CustomerInvPmtDisc(PmtType: Option; InvType: Option; Amount: Decimal; Stepwise: Boolean)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DiscountAmount: Decimal;
        Desc: Text[30];
    begin
        // Test with payment discount
        GetGLBalancedBatch(GenJournalTemplate, GenJournalBatch, GenJournalTemplate.Type::General);
        CreateCustomerWithPaymentTerms(Customer, GetPaymentTerms('>0'));
        DiscountAmount := GetDiscount(Customer."Payment Terms Code", Amount);

        // Watch for "Payment Discount" detailed ledger entries.
        LibraryERMCustomerWatch.Init;
        LibraryERMCustomerWatch.DtldEntriesEqual(Customer."No.", DtldCustLedgEntry."Entry Type"::"Payment Discount", DiscountAmount);

        // Generate a document that triggers payment discount dtld. ledger entries.
        Desc := GenerateDocument(GenJournalBatch, Customer, PmtType, InvType, Amount - DiscountAmount, Amount, '<0D>', '', '');
        CustomerApplyUnapply(Desc, Stepwise);

        LibraryERMCustomerWatch.AssertCustomer;
    end;

    local procedure CustomerInvPmtVAT(PmtType: Option; InvType: Option; Amount: Decimal; Stepwise: Boolean)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Desc: Text[30];
    begin
        // Test with VAT

        // Find a VAT setup that has a balancing account with direct posting
        GetDirectVATPostingSetup(VATPostingSetup, GLAccount, '>0');
        GetVATBalancedBatch(GenJournalTemplate, GenJournalBatch, GLAccount);

        // Find payment terms with no discount
        CreateCustomerWithPaymentTerms(Customer, GetPaymentTerms('0'));
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);

        // Try out Customer watch
        LibraryERMCustomerWatch.Init;
        LibraryERMCustomerWatch.EntriesEqual(Customer."No.", InvType, -Amount);
        LibraryERMCustomerWatch.EntriesEqual(Customer."No.", PmtType, Amount);
        LibraryERMCustomerWatch.DtldEntriesEqual(Customer."No.", DtldCustLedgEntry."Entry Type"::"Initial Entry", 0);
        LibraryERMCustomerWatch.DtldEntriesGreaterThan(Customer."No.", DtldCustLedgEntry."Entry Type"::Application, 0);

        // Generate a document that triggers payment discount dtld. ledger entries.
        Desc := GenerateDocument(GenJournalBatch, Customer, PmtType, InvType, Amount, Amount, '<0D>', '', '');
        CustomerApplyUnapply(Desc, Stepwise);

        LibraryERMCustomerWatch.AssertCustomer;
    end;

    local procedure CustomerInvPmtCorrection(PmtType: Option; InvType: Option; Amount: Decimal; Stepwise: Boolean)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Desc: Text[30];
    begin
        // Test with payment discount
        GetGLBalancedBatch(GenJournalTemplate, GenJournalBatch, GenJournalTemplate.Type::General);
        CreateCustomerWithPaymentTerms(Customer, GetPaymentTerms('0'));

        // Create a currency code with magic exchange rate valid for Amount = 1000
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, WorkDate);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 64.580459);  // Magic exchange rate
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", 100);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);

        // Watch for "Correction of Remaining Amount" detailed ledger entries.
        LibraryERMCustomerWatch.Init;
        LibraryERMCustomerWatch.DtldEntriesGreaterThan(
          Customer."No.", DtldCustLedgEntry."Entry Type"::"Correction of Remaining Amount", 0);

        // Generate a document that triggers "Correction of Remaining Amount" dtld. ledger entries.
        Desc := GenerateDocument(GenJournalBatch, Customer, PmtType, InvType, Amount, Amount, '<0D>', Currency.Code, Currency.Code);
        CustomerApplyUnapply(Desc, Stepwise);

        LibraryERMCustomerWatch.AssertCustomer;
    end;

    local procedure CustomerApplyUnapplyVAT(Customer: Record Customer; PmtType: Option; InvType: Option; PmtAmount: Decimal; InvAmount: Decimal; PmtOffset: Text[30]; Stepwise: Boolean)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        Desc: Text[30];
    begin
        // Setup payment tolerance on payment discount
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);

        // Find a VAT setup that has a balancing account with direct posting and update it
        GetDirectVATPostingSetup(VATPostingSetup, GLAccount, '>0');
        GetVATBalancedBatch(GenJournalTemplate, GenJournalBatch, GLAccount);
        VATPostingSetup.Validate("Adjust for Payment Discount", true);
        VATPostingSetup.Modify(true);

        // Update General Posting Setup
        GeneralPostingSetup.Get(GLAccount."Gen. Bus. Posting Group", GLAccount."Gen. Prod. Posting Group");
        GeneralPostingSetup.Validate("Sales Pmt. Disc. Credit Acc.", GLAccount."No.");
        GeneralPostingSetup.Validate("Sales Pmt. Disc. Debit Acc.", GLAccount."No.");
        GeneralPostingSetup.Validate("Sales Pmt. Tol. Credit Acc.", GLAccount."No.");
        GeneralPostingSetup.Validate("Sales Pmt. Tol. Debit Acc.", GLAccount."No.");
        GeneralPostingSetup.Modify(true);

        // Update Customer to our needs
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Validate("Application Method", Customer."Application Method"::Manual);
        Customer.Modify(true);

        // Generate a document that triggers "Payment Tolerance (VAT Adjustment)" dtld. ledger entries.
        Desc := GenerateDocument(GenJournalBatch, Customer, PmtType, InvType, PmtAmount, InvAmount, PmtOffset, '', '');
        CustomerApplyUnapply(Desc, Stepwise);
    end;

    local procedure CustomerApplyUnapply(Desc: Text[30]; Stepwise: Boolean)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange(Description, Desc);
        Assert.AreEqual(CustLedgerEntry.Count, 4, 'Expected to find exactly 4 Customer ledger entries!');

        // Exercise #1. Apply entries.
        PostCustomerApplication(CustLedgerEntry, Stepwise);

        // Verify #1.
        VerifyCustomerEntriesClosed(CustLedgerEntry);

        // Exercise #2. Unapply entries.
        PostCustomerUnapply(CustLedgerEntry, Stepwise);

        // Verify #2.
        VerifyCustomerEntriesOpen(CustLedgerEntry);

        // Exercise #3. Apply entries.
        PostCustomerApplication(CustLedgerEntry, Stepwise);

        // Verify #3.
        VerifyCustomerEntriesClosed(CustLedgerEntry);
    end;

    local procedure SetupPaymentTolerance()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get;
        GeneralLedgerSetup.Validate("Payment Tolerance %", 1.0);
        GeneralLedgerSetup.Validate("Max. Payment Tolerance Amount", 5.0);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure GenerateDocument(GenJournalBatch: Record "Gen. Journal Batch"; Customer: Record Customer; PmtType: Option; InvType: Option; PmtAmount: Decimal; InvAmount: Decimal; PmtOffset: Text[30]; PmtCurrencyCode: Code[10]; InvCurrencyCode: Code[10]): Text[30]
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        Desc: Text[30];
    begin
        ClearJournalBatch(GenJournalBatch);

        // Create four documents with seperate document no. and external document no. but with unique description.
        with GenJournalLine do begin
            DocumentNo := CreateJournalLine(
                GenJournalLine, GenJournalBatch, PmtType, "Account Type"::Customer,
                Customer."No.", PmtAmount / 4, PmtOffset, PmtCurrencyCode, DocumentNo, '');
            Desc := DocumentNo;
            DocumentNo := CreateJournalLine(
                GenJournalLine, GenJournalBatch, PmtType, "Account Type"::Customer,
                Customer."No.", PmtAmount / 4, PmtOffset, PmtCurrencyCode, IncStr(DocumentNo), Desc);
            DocumentNo := CreateJournalLine(
                GenJournalLine, GenJournalBatch, PmtType, "Account Type"::Customer,
                Customer."No.", PmtAmount / 2, PmtOffset, PmtCurrencyCode, IncStr(DocumentNo), Desc);
            DocumentNo := CreateJournalLine(
                GenJournalLine, GenJournalBatch, InvType, "Account Type"::Customer,
                Customer."No.", -InvAmount, '<0D>', InvCurrencyCode, IncStr(DocumentNo), Desc);
        end;

        PostJournalBatch(GenJournalBatch);
        exit(Desc);
    end;

    local procedure CreateCustomerWithPaymentTerms(var Customer: Record Customer; PaymentTermsCode: Code[10])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTermsCode);
        Customer.Modify(true);
    end;

    local procedure CreateJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Option; AccountType: Option; AccountNo: Code[20]; Amount: Decimal; PmtOffset: Text[30]; CurrencyCode: Code[10]; DocNo: Code[20]; Description: Text[30]): Code[20]
    var
        DateOffset: DateFormula;
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine,
          GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name,
          DocumentType,
          AccountType,
          AccountNo,
          Amount);

        Evaluate(DateOffset, PmtOffset);

        // Update journal line currency
        GenJournalLine.Validate("Posting Date", CalcDate(DateOffset, WorkDate));
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate(Description, GenJournalLine."Document No.");

        // Update document number and description if specified
        if DocNo <> '' then
            GenJournalLine."Document No." := DocNo;
        if Description <> '' then
            GenJournalLine.Description := Description;

        GenJournalLine.Validate("External Document No.", GenJournalLine."Document No.");
        GenJournalLine.Modify(true);

        exit(GenJournalLine."Document No.");
    end;

    local procedure ClearJournalBatch(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetFilter("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.DeleteAll;
    end;

    local procedure MockCustLedgEntry(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        with CustLedgerEntry do begin
            Init;
            "Entry No." :=
              LibraryUtility.GetNewRecNo(CustLedgerEntry, FieldNo("Entry No."));
            Open := true;
            Insert;
            MockDtldLedgEntry("Entry No.");
        end;
    end;

    local procedure MockDtldLedgEntry(CustLedgEntryNo: Integer)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        with DetailedCustLedgEntry do begin
            Init;
            "Entry No." :=
              LibraryUtility.GetNewRecNo(DetailedCustLedgEntry, FieldNo("Entry No."));
            "Cust. Ledger Entry No." := CustLedgEntryNo;
            "Entry Type" := "Entry Type"::"Initial Entry";
            Amount := LibraryRandom.RandDec(100, 2);
            Insert;
        end;
    end;

    local procedure MockAppliedCustLedgEntry(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        with CustLedgerEntry do begin
            MockCustLedgEntry(CustLedgerEntry);
            "Amount to Apply" := LibraryRandom.RandDec(100, 2);
            "Applies-to ID" := LibraryUtility.GenerateGUID;
            "Accepted Pmt. Disc. Tolerance" := true;
            "Accepted Payment Tolerance" := LibraryRandom.RandDec(100, 2);
            Modify;
        end;
    end;

    local procedure PostJournalBatch(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetFilter("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst;

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostCustomerApplication(var CustLedgerEntry: Record "Cust. Ledger Entry"; Stepwise: Boolean)
    begin
        if Stepwise then
            PostCustomerApplicationStepwis(CustLedgerEntry)
        else
            PostCustomerApplicationOneGo(CustLedgerEntry);
    end;

    local procedure PostCustomerApplicationOneGo(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        // The first entry is the applying entry.
        CustLedgerEntry.FindFirst;
        CustLedgerEntry.CalcFields(Amount);
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, CustLedgerEntry.Amount);

        // Apply to all other entries.
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);

        // Call Apply codeunit.
        CustLedgerEntry.FindFirst;
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure PostCustomerApplicationStepwis(var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        i: Integer;
    begin
        // The first entry is the applying entry.
        CustLedgerEntry.FindLast;
        CustLedgerEntry2.SetRange("Entry No.", CustLedgerEntry."Entry No.");
        CustLedgerEntry2.FindFirst;

        CustLedgerEntry.FindFirst;
        for i := 1 to CustLedgerEntry.Count - 1 do begin
            CustLedgerEntry.CalcFields(Amount);
            LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, CustLedgerEntry.Amount);

            // Apply to last entry.
            LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);

            // Post application.
            LibraryERM.PostCustLedgerApplication(CustLedgerEntry);

            CustLedgerEntry.Next;
        end;
    end;

    local procedure PostCustomerUnapply(var CustLedgerEntry: Record "Cust. Ledger Entry"; Stepwise: Boolean)
    begin
        if Stepwise then
            PostCustomerUnapplyStepwise(CustLedgerEntry)
        else
            PostCustomerUnapplyOneGo(CustLedgerEntry);
    end;

    local procedure PostCustomerUnapplyOneGo(var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        PostingDate: Date;
    begin
        DtldCustLedgEntry.Get(FindLastApplEntry(CustLedgerEntry."Entry No."));

        DtldCustLedgEntry2.SetRange("Transaction No.", DtldCustLedgEntry."Transaction No.");
        DtldCustLedgEntry2.SetRange("Customer No.", DtldCustLedgEntry."Customer No.");
        DtldCustLedgEntry2.FindFirst;

        PostingDate := DtldCustLedgEntry."Posting Date";

        CustEntryApplyPostedEntries.PostUnApplyCustomer(
          DtldCustLedgEntry,
          CustLedgerEntry."Document No.",
          PostingDate);
    end;

    local procedure PostCustomerUnapplyStepwise(var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        i: Integer;
    begin
        CustLedgerEntry.FindLast;

        for i := 1 to CustLedgerEntry.Count - 1 do begin
            // Unapply in reverse order.
            CustLedgerEntry.Next(-1);
            PostCustomerUnapplyOneGo(CustLedgerEntry);
        end;
    end;

    local procedure SetExchRateForCurrency(CurrencyAdjustFactor: Decimal): Code[10]
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Find currency code with realized gaisn/losses account
        Currency.Get(LibraryERM.CreateCurrencyWithGLAccountSetup);

        // Create new exchange rates
        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, WorkDate);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 100);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", 100);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", 100);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", 100);
        CurrencyExchangeRate.Modify(true);

        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, CalcDate('<1D>', WorkDate));
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 100);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", 100);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", 100 * CurrencyAdjustFactor);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", 100 * CurrencyAdjustFactor);
        CurrencyExchangeRate.Modify(true);

        exit(Currency.Code);
    end;

    local procedure GetDirectVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; var GLAccount: Record "G/L Account"; VATFilter: Text[30])
    begin
        VATPostingSetup.SetFilter("VAT %", VATFilter);
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.FindSet;
        repeat
            GLAccount.SetRange("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
            GLAccount.SetFilter("Gen. Bus. Posting Group", '<>''''');
            GLAccount.SetFilter("Gen. Prod. Posting Group", '<>''''');
            GLAccount.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
            GLAccount.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
            GLAccount.SetRange("Direct Posting", true);
        until (VATPostingSetup.Next = 0) or GLAccount.FindFirst;

        VATPostingSetup.Get(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");
    end;

    local procedure GetLastTransactionNo(): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.FindLast;
        exit(GLEntry."Transaction No.");
    end;

    local procedure GetPaymentTerms(DiscountFilter: Text[30]): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Reset;
        PaymentTerms.SetFilter("Discount %", DiscountFilter);
        PaymentTerms.FindFirst;
        PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" := true;
        PaymentTerms.Modify(true);
        exit(PaymentTerms.Code);
    end;

    local procedure GetGLBalancedBatch(var GenJnlTemplate: Record "Gen. Journal Template"; var GenJnlBatch: Record "Gen. Journal Batch"; TemplateType: Option)
    begin
        // Find template type.
        GenJnlTemplate.SetFilter(Type, Format(TemplateType));
        LibraryERM.FindGenJournalTemplate(GenJnlTemplate);

        // Create a GL balanced batch.
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        GenJnlBatch.Validate("Bal. Account Type", GenJnlBatch."Bal. Account Type"::"G/L Account");
        GenJnlBatch.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo);
        GenJnlBatch.Modify(true);
    end;

    local procedure GetVATBalancedBatch(var GenJournalTemplate: Record "Gen. Journal Template"; var GenJournalBatch: Record "Gen. Journal Batch"; GLAccount: Record "G/L Account")
    begin
        with GenJournalBatch do begin
            SetRange("Bal. Account Type", "Bal. Account Type"::"G/L Account");
            SetRange("Bal. Account No.", GLAccount."No.");
            if not FindFirst then begin
                GetGLBalancedBatch(GenJournalTemplate, GenJournalBatch, GenJournalTemplate.Type::General);
                Name := 'CustVAT';
                "Bal. Account Type" := "Bal. Account Type"::"G/L Account";
                "Bal. Account No." := GLAccount."No.";
                Insert(true);
            end;
        end;
    end;

    local procedure GetPaymentTolerance(): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get;
        exit(GeneralLedgerSetup."Max. Payment Tolerance Amount");
    end;

    local procedure GetDiscount(PmtTerms: Code[10]; Amount: Decimal): Decimal
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Get(PmtTerms);
        exit(Amount * PaymentTerms."Discount %" / 100);
    end;

    local procedure RunGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"): Integer
    var
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        exit(GenJnlPostLine.RunWithCheck(GenJnlLine));
    end;

    local procedure VerifyCustomerEntriesClosed(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        with CustLedgerEntry do begin
            FindFirst;
            repeat
                Assert.IsFalse(Open, StrSubstNo('Customer ledger entry %1 did not close.', "Entry No."));
            until Next = 0;
        end;
    end;

    local procedure VerifyCustomerEntriesOpen(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        with CustLedgerEntry do begin
            FindFirst;
            repeat
                Assert.IsTrue(Open, StrSubstNo('Customer ledger entry %1 did not open.', "Entry No."));
            until Next = 0;
        end;
    end;

    local procedure VerifyAppliedLedgerEntry(CustLedgerEntry: Record "Cust. Ledger Entry"; AppliesToID: Code[50])
    begin
        CustLedgerEntry.Find;
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustLedgerEntry.TestField("Applies-to ID", AppliesToID);
        CustLedgerEntry.TestField("Amount to Apply", CustLedgerEntry."Remaining Amount");
    end;

    local procedure VerifyUnappliedLedgerEntry(CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry.Find;
        CustLedgerEntry.TestField("Applies-to ID", '');
        CustLedgerEntry.TestField("Amount to Apply", 0);
        CustLedgerEntry.TestField("Accepted Payment Tolerance", 0);
        CustLedgerEntry.TestField("Accepted Pmt. Disc. Tolerance", false);
    end;

    local procedure FindLastApplEntry(VendLedgEntryNo: Integer): Integer
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        ApplicationEntryNo: Integer;
    begin
        DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type");
        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", VendLedgEntryNo);
        DtldCustLedgEntry.SetRange("Entry Type", DtldCustLedgEntry."Entry Type"::Application);
        ApplicationEntryNo := 0;
        if DtldCustLedgEntry.Find('-') then
            repeat
                if (DtldCustLedgEntry."Entry No." > ApplicationEntryNo) and not DtldCustLedgEntry.Unapplied then
                    ApplicationEntryNo := DtldCustLedgEntry."Entry No.";
            until DtldCustLedgEntry.Next = 0;
        exit(ApplicationEntryNo);
    end;

    local procedure TearDown()
    begin
        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure StatisticsMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(ExchRateWasAdjustedTxt, Message);
    end;
}

