codeunit 134157 "ERM Posting Rounding"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Posting] [Rounding]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure NOVATFCYPurchaseInvoiceWithPositiveAndNegativeLineAmounts()
    var
        PurchaseHeader: Record "Purchase Header";
        GLEntry: Record "G/L Entry";
        GLAccountNo: array[4] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 268735] Posting of a purchase invoice with NO VAT, currency, several G/L Accounts with positive and negative lines having zero balance on one of the G/L Accounts
        // [SCENARIO 268735] in case of balanced invoice posting buffer groups rounding
        Initialize();

        // [GIVEN] Purchase invoice with NO VAT, currency, several G/L Accounts with positive and negative lines having zero balance on GLAccount "A"
        CreatePurchaseInvoice_TFS268735(PurchaseHeader, GLAccountNo);

        // [WHEN] Post the document
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The document has been posted and GLEntry.Amount = 0 for the "A" GLAccount
        GLEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(GLEntry, 5);

        VerifyGLEntry(DocumentNo, GLAccountNo[1], 19645.33);
        VerifyGLEntry(DocumentNo, GLAccountNo[2], 10025.89);
        VerifyGLEntry(DocumentNo, GLAccountNo[3], 0);
        VerifyGLEntry(DocumentNo, GLAccountNo[4], 5477.46);
        VerifyGLEntry(DocumentNo, GetVendorPayablesAccountNo(PurchaseHeader."Vendor Posting Group"), -35148.68);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NOVATFCYPurchaseInvoiceWithPositiveAndNegativeLineAmounts2()
    var
        PurchaseHeader: Record "Purchase Header";
        GLEntry: Record "G/L Entry";
        GLAccountNo: array[4] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 396183] Posting of a purchase invoice with NO VAT, currency, several G/L Accounts with positive and negative lines
        // [SCENARIO 396183] in case of non balanced invoice posting buffer groups rounding
        Initialize();

        // [GIVEN] Purchase invoice with NO VAT, currency, several G/L Accounts with positive and negative lines
        CreatePurchaseInvoice_TFS268735_2(PurchaseHeader, GLAccountNo);

        // [WHEN] Post the document
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The document has been posted
        GLEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(GLEntry, 5);

        VerifyGLEntry(DocumentNo, GLAccountNo[1], 19645.32);
        VerifyGLEntry(DocumentNo, GLAccountNo[2], 10025.89);
        VerifyGLEntry(DocumentNo, GLAccountNo[3], 5477.46);
        VerifyGLEntry(DocumentNo, GLAccountNo[4], 5477.48);
        VerifyGLEntry(DocumentNo, GetVendorPayablesAccountNo(PurchaseHeader."Vendor Posting Group"), -40626.15);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NOVATFCYSalesInvoiceWithPositiveAndNegativeLineAmounts()
    var
        SalesHeader: Record "Sales Header";
        GLEntry: Record "G/L Entry";
        GLAccountNo: array[4] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 268735] Posting of a sales invoice with NO VAT, currency, several G/L Accounts with positive and negative lines having zero balance on one of the G/L Accounts
        // [SCENARIO 268735] in case of balanced invoice posting buffer groups rounding
        Initialize();

        // [GIVEN] Sales invoice with NO VAT, currency, several G/L Accounts with positive and negative lines having zero balance on GLAccount "A"
        CreateSalesInvoice_TFS268735(SalesHeader, GLAccountNo);

        // [WHEN] Post the document
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The document has been posted and GLEntry.Amount = 0 for the "A" GLAccount
        GLEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(GLEntry, 5);

        VerifyGLEntry(DocumentNo, GLAccountNo[1], -19645.33);
        VerifyGLEntry(DocumentNo, GLAccountNo[2], -10025.89);
        VerifyGLEntry(DocumentNo, GLAccountNo[3], 0);
        VerifyGLEntry(DocumentNo, GLAccountNo[4], -5477.46);
        VerifyGLEntry(DocumentNo, GetCustomerReceivablesAccountNo(SalesHeader."Customer Posting Group"), 35148.68);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NOVATFCYSalesInvoiceWithPositiveAndNegativeLineAmounts2()
    var
        SalesHeader: Record "Sales Header";
        GLEntry: Record "G/L Entry";
        GLAccountNo: array[4] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 396183] Posting of a sales invoice with NO VAT, currency, several G/L Accounts with positive and negative lines
        // [SCENARIO 396183] in case of non balanced invoice posting buffer groups rounding
        Initialize();

        // [GIVEN] Sales invoice with NO VAT, currency, several G/L Accounts with positive and negative lines
        CreateSalesInvoice_TFS268735_2(SalesHeader, GLAccountNo);

        // [WHEN] Post the document
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The document has been posted
        GLEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(GLEntry, 5);

        VerifyGLEntry(DocumentNo, GLAccountNo[1], -19645.32);
        VerifyGLEntry(DocumentNo, GLAccountNo[2], -10025.89);
        VerifyGLEntry(DocumentNo, GLAccountNo[3], -5477.46);
        VerifyGLEntry(DocumentNo, GLAccountNo[4], -5477.48);
        VerifyGLEntry(DocumentNo, GetCustomerReceivablesAccountNo(SalesHeader."Customer Posting Group"), 40626.15);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoicePostBuffer_Update_ZeroRounding()
    var
        TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary;
        TempInvoicePostBuffer2: Record "Invoice Post. Buffer" temporary;
        InvDefLineNo: Integer;
        DeferralLineNo: Integer;
    begin
        // [FEATURE] [UT] [Invoice Post. Buffer]
        // [SCENARIO 268735] TAB 49 "Invoice Post. Buffer".Update() in case of zero rounding for the paired field (i.e. "Amount" = 0, "Amount (ACY)" <> 0)
        MockTempInvoicePostBuffer(TempInvoicePostBuffer, 0, 0, 0, 0, 0, 0);

        MockTempInvoicePostBuffer(TempInvoicePostBuffer2, 1, 0, 1, 0, 1, 0);
        TempInvoicePostBuffer.Update(TempInvoicePostBuffer2, InvDefLineNo, DeferralLineNo);
        VerifyInvoicePostBufferAmounts(TempInvoicePostBuffer, 0, 0, 0, 0, 0, 0);

        TempInvoicePostBuffer2.DELETE;
        MockTempInvoicePostBuffer(TempInvoicePostBuffer2, 1, 1, 1, 1, 1, 1);
        TempInvoicePostBuffer.Update(TempInvoicePostBuffer2, InvDefLineNo, DeferralLineNo);
        VerifyInvoicePostBufferAmounts(TempInvoicePostBuffer, 1, 1, 1, 1, 1, 1);

        TempInvoicePostBuffer.ApplyRoundingForFinalPosting;
        VerifyInvoicePostBufferAmounts(TempInvoicePostBuffer, 2, 1, 2, 1, 2, 1);

        TempInvoicePostBuffer.ApplyRoundingForFinalPosting;
        VerifyInvoicePostBufferAmounts(TempInvoicePostBuffer, 2, 1, 2, 1, 2, 1);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Posting Rounding");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Posting Rounding");

        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibraryERMCountryData.UpdatePurchasesPayablesSetup;

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Posting Rounding");
    end;

    local procedure PrepareAmounts_TFS268735(var Amounts: array[9] of Decimal; var CurrencyExchRate: Decimal)
    begin
        Amounts[1] := 5075;
        Amounts[2] := 2590;
        Amounts[3] := 1415;
        Amounts[4] := -5075;
        Amounts[5] := -2590;
        Amounts[6] := -1415;
        Amounts[7] := 5075;
        Amounts[8] := 2590;
        Amounts[9] := 1415;
        CurrencyExchRate := 0.25833118;
    end;

    local procedure CreatePurchaseInvoice_TFS268735(var PurchaseHeader: Record "Purchase Header"; var GLAccountNo: array[4] of Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        CurrencyCode: Code[10];
        CurrExchRate: Decimal;
        Amounts: array[9] of Decimal;
        i: Integer;
    begin
        CreateVATPostingSetup(VATPostingSetup, 0);
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        for i := 1 to ArrayLen(GLAccountNo) do
            GLAccountNo[i] := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::" ");
        PrepareAmounts_TFS268735(Amounts, CurrExchRate);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate, CurrExchRate, 1);

        CreatePurchaseHeader(PurchaseHeader, VendorNo, CurrencyCode);
        CreatePurchaseLine(PurchaseHeader, GLAccountNo[1], Amounts[1]);
        CreatePurchaseLine(PurchaseHeader, GLAccountNo[2], Amounts[2]);
        CreatePurchaseLine(PurchaseHeader, GLAccountNo[3], Amounts[3]);
        CreatePurchaseLine(PurchaseHeader, GLAccountNo[1], Amounts[4]);
        CreatePurchaseLine(PurchaseHeader, GLAccountNo[2], Amounts[5]);
        CreatePurchaseLine(PurchaseHeader, GLAccountNo[3], Amounts[6]);
        CreatePurchaseLine(PurchaseHeader, GLAccountNo[1], Amounts[7]);
        CreatePurchaseLine(PurchaseHeader, GLAccountNo[2], Amounts[8]);
        CreatePurchaseLine(PurchaseHeader, GLAccountNo[4], Amounts[9]);
    end;

    local procedure CreatePurchaseInvoice_TFS268735_2(var PurchaseHeader: Record "Purchase Header"; var GLAccountNo: array[4] of Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        CurrencyCode: Code[10];
        CurrExchRate: Decimal;
        Amounts: array[9] of Decimal;
        i: Integer;
    begin
        CreateVATPostingSetup(VATPostingSetup, 0);
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        for i := 1 to ArrayLen(GLAccountNo) do
            GLAccountNo[i] := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::" ");
        PrepareAmounts_TFS268735(Amounts, CurrExchRate);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate, CurrExchRate, 1);

        CreatePurchaseHeader(PurchaseHeader, VendorNo, CurrencyCode);
        CreatePurchaseLine(PurchaseHeader, GLAccountNo[1], Amounts[1]);
        CreatePurchaseLine(PurchaseHeader, GLAccountNo[2], Amounts[2]);
        CreatePurchaseLine(PurchaseHeader, GLAccountNo[3], Amounts[3]);
        CreatePurchaseLine(PurchaseHeader, GLAccountNo[1], Amounts[4]);
        CreatePurchaseLine(PurchaseHeader, GLAccountNo[2], Amounts[5]);
        CreatePurchaseLine(PurchaseHeader, GLAccountNo[1], Amounts[7]);
        CreatePurchaseLine(PurchaseHeader, GLAccountNo[2], Amounts[8]);
        CreatePurchaseLine(PurchaseHeader, GLAccountNo[4], Amounts[9]);
    end;

    local procedure CreateSalesInvoice_TFS268735(var SalesHeader: Record "Sales Header"; var GLAccountNo: array[4] of Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerNo: Code[20];
        CurrencyCode: Code[10];
        CurrExchRate: Decimal;
        Amounts: array[9] of Decimal;
        i: Integer;
    begin
        CreateVATPostingSetup(VATPostingSetup, 0);
        CustomerNo := LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        for i := 1 to ArrayLen(GLAccountNo) do
            GLAccountNo[i] := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::" ");
        PrepareAmounts_TFS268735(Amounts, CurrExchRate);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate, CurrExchRate, 1);

        CreateSalesHeader(SalesHeader, CustomerNo, CurrencyCode);
        CreateSalesLine(SalesHeader, GLAccountNo[1], Amounts[1]);
        CreateSalesLine(SalesHeader, GLAccountNo[2], Amounts[2]);
        CreateSalesLine(SalesHeader, GLAccountNo[3], Amounts[3]);
        CreateSalesLine(SalesHeader, GLAccountNo[1], Amounts[4]);
        CreateSalesLine(SalesHeader, GLAccountNo[2], Amounts[5]);
        CreateSalesLine(SalesHeader, GLAccountNo[3], Amounts[6]);
        CreateSalesLine(SalesHeader, GLAccountNo[1], Amounts[7]);
        CreateSalesLine(SalesHeader, GLAccountNo[2], Amounts[8]);
        CreateSalesLine(SalesHeader, GLAccountNo[4], Amounts[9]);
    end;

    local procedure CreateSalesInvoice_TFS268735_2(var SalesHeader: Record "Sales Header"; var GLAccountNo: array[4] of Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerNo: Code[20];
        CurrencyCode: Code[10];
        CurrExchRate: Decimal;
        Amounts: array[9] of Decimal;
        i: Integer;
    begin
        CreateVATPostingSetup(VATPostingSetup, 0);
        CustomerNo := LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        for i := 1 to ArrayLen(GLAccountNo) do
            GLAccountNo[i] := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::" ");
        PrepareAmounts_TFS268735(Amounts, CurrExchRate);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate, CurrExchRate, 1);

        CreateSalesHeader(SalesHeader, CustomerNo, CurrencyCode);
        CreateSalesLine(SalesHeader, GLAccountNo[1], Amounts[1]);
        CreateSalesLine(SalesHeader, GLAccountNo[2], Amounts[2]);
        CreateSalesLine(SalesHeader, GLAccountNo[3], Amounts[3]);
        CreateSalesLine(SalesHeader, GLAccountNo[1], Amounts[4]);
        CreateSalesLine(SalesHeader, GLAccountNo[2], Amounts[5]);
        CreateSalesLine(SalesHeader, GLAccountNo[1], Amounts[7]);
        CreateSalesLine(SalesHeader, GLAccountNo[2], Amounts[8]);
        CreateSalesLine(SalesHeader, GLAccountNo[4], Amounts[9]);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATRate: Decimal)
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATRate);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; CurrencyCode: Code[10])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseLine(PurchaseHeader: Record "Purchase Header"; GLAccountNo: Code[20]; DirectUnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, 1);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; CurrencyCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLine(SalesHeader: Record "Sales Header"; GLAccountNo: Code[20]; UnitPrice: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, 1);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure MockTempInvoicePostBuffer(var TempInvoicePostBuffer: Record "Invoice Post. Buffer" temporary; NewAmount: Decimal; NewAmountACY: Decimal; NewVATAmount: Decimal; NewVATAmountACY: Decimal; NewVATBaseAmount: Decimal; NewVATBaseAmountACY: Decimal)
    begin
        with TempInvoicePostBuffer do begin
            Init;
            Amount := NewAmount;
            "Amount (ACY)" := NewAmountACY;
            "VAT Amount" := NewVATAmount;
            "VAT Amount (ACY)" := NewVATAmountACY;
            "VAT Base Amount" := NewVATBaseAmount;
            "VAT Base Amount (ACY)" := NewVATBaseAmountACY;
            Insert;
        end;
    end;

    local procedure GetVendorPayablesAccountNo(VendorPostingGroupCode: Code[20]): Code[20]
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        VendorPostingGroup.Get(VendorPostingGroupCode);
        exit(VendorPostingGroup."Payables Account");
    end;

    local procedure GetCustomerReceivablesAccountNo(CustomerPostingGroupCode: Code[20]): Code[20]
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustomerPostingGroup.Get(CustomerPostingGroupCode);
        exit(CustomerPostingGroup."Receivables Account");
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        with GLEntry do begin
            SetRange("Document No.", DocumentNo);
            SetRange("G/L Account No.", GLAccountNo);
            FindFirst;
            TestField(Amount, ExpectedAmount);
        end;
    end;

    local procedure VerifyInvoicePostBufferAmounts(InvoicePostBuffer: Record "Invoice Post. Buffer"; ExpAmount: Decimal; ExpAmountACY: Decimal; ExpVATAmount: Decimal; ExpVATAmountACY: Decimal; ExpVATBaseAmount: Decimal; ExpVATBaseAmountACY: Decimal)
    begin
        with InvoicePostBuffer do begin
            TestField(Amount, ExpAmount);
            TestField("Amount (ACY)", ExpAmountACY);
            TestField("VAT Amount", ExpVATAmount);
            TestField("VAT Amount (ACY)", ExpVATAmountACY);
            TestField("VAT Base Amount", ExpVATBaseAmount);
            TestField("VAT Base Amount (ACY)", ExpVATBaseAmountACY);
        end;
    end;
}

