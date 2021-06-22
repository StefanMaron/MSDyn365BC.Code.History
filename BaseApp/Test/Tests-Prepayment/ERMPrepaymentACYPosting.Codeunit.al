codeunit 134110 "ERM Prepayment ACY Posting"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Prepayment] [ACY]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;
        NoGLEntriesPostedErr: Label 'No realized gains/losses have been posted.';
        LCYAmtMustBeZeroErr: Label 'Additional-currency Amount in realized gain/loss entries must be 0.';
        IncorrectRoundingAmtErr: Label 'Invoice rounding amount is incorrect.';

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure TFS353014_ACYAmountOnFinalInvoiceSales()
    var
        AddCurrency: Record Currency;
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        GLAccount: Record "G/L Account";
    begin
        Initialize;

        LibrarySales.CreatePrepaymentVATSetup(GLAccount, "General Posting Type"::" ");
        CreateAddReportingCurrency(AddCurrency);
        CreateBankAccountWithCurrencyCode(BankAccount, AddCurrency.Code);
        CreateCustomer(Customer, GLAccount."Gen. Bus. Posting Group", GLAccount."VAT Bus. Posting Group", AddCurrency.Code);

        CreateSalesOrder(SalesHeader, Customer, GLAccount."No.");
        PostSalesPrepayment(SalesHeader);
        SalesHeader.CalcFields("Amount Including VAT");
        PostCashPayment(
          "Gen. Journal Account Type"::Customer, Customer."No.", BankAccount."No.", AddCurrency.Code, CalcDate('<+1M>', WorkDate),
          -SalesHeader."Amount Including VAT", FindPostedSalesInvoiceForCustomer(Customer."No."));

        // Applied cash receipt posting updates sales header status. Need to re-read it.
        SalesHeader.Find;
        UpdatePostingDateOnSalesHeader(SalesHeader, CalcDate('<+2M>', WorkDate));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        VerifyACYAmountIsZero(AddCurrency."Realized Losses Acc.");
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure TFS353014_ACYAmountOnFinalInvoicePurch()
    var
        AddCurrency: Record Currency;
        BankAccount: Record "Bank Account";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        GLAccount: Record "G/L Account";
    begin
        Initialize;

        LibraryPurchase.CreatePrepaymentVATSetup(GLAccount, "General Posting Type"::" ");
        CreateAddReportingCurrency(AddCurrency);
        CreateBankAccountWithCurrencyCode(BankAccount, AddCurrency.Code);
        CreateVendor(Vendor, GLAccount."Gen. Bus. Posting Group", GLAccount."VAT Bus. Posting Group", AddCurrency.Code);

        CreatePurchaseOrder(PurchaseHeader, Vendor, GLAccount."No.");
        PostPurchasePrepayment(PurchaseHeader);
        PurchaseHeader.CalcFields("Amount Including VAT");
        PostCashPayment(
          "Gen. Journal Account Type"::Vendor, Vendor."No.", BankAccount."No.", AddCurrency.Code, CalcDate('<+1M>', WorkDate),
          PurchaseHeader."Amount Including VAT", FindPostedPurchaseInvoiceForVendor(Vendor."No."));

        // Applied cash payment posting updates purchase header status. Need to re-read it.
        PurchaseHeader.Find;
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        UpdatePostingDateOnPurchaseHeader(PurchaseHeader, CalcDate('<+2M>', WorkDate));
        PurchaseHeader.Validate(
          "Vendor Invoice No.",
          CopyStr(PurchaseHeader."No." + PurchaseHeader."Buy-from Vendor No.", 1, MaxStrLen(PurchaseHeader."Vendor Invoice No.")));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        VerifyACYAmountIsZero(AddCurrency."Realized Gains Acc.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS353478_VATRoundingOnSalesPrpmtACY()
    var
        AddCurrency: Record Currency;
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        Initialize;

        LibrarySales.SetInvoiceRounding(true);

        LibrarySales.CreatePrepaymentVATSetup(GLAccount, "General Posting Type"::" ");
        CreateAddReportingCurrency(AddCurrency);
        CreateCustomer(Customer, GLAccount."Gen. Bus. Posting Group", GLAccount."VAT Bus. Posting Group", AddCurrency.Code);
        SetCustomerInvRoundingAcc(Customer."Customer Posting Group", GLAccount);

        CreateSalesOrder(SalesHeader, Customer, GLAccount."No.");
        PostSalesPrepayment(SalesHeader);
        SalesHeader.Find;
        SalesHeader.CalcFields("Amount Including VAT");
        VerifySalesInvRoundingAmount(
          Customer."Customer Posting Group", SalesHeader, AddCurrency."Invoice Rounding Precision");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS353478_VATRoundingOnPurchPrpmtACY()
    var
        AddCurrency: Record Currency;
        GLAccount: Record "G/L Account";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        Initialize;

        LibraryPurchase.SetInvoiceRounding(true);
        LibraryPurchase.CreatePrepaymentVATSetup(GLAccount, "General Posting Type"::" ");
        CreateAddReportingCurrency(AddCurrency);
        CreateVendor(Vendor, GLAccount."Gen. Bus. Posting Group", GLAccount."VAT Bus. Posting Group", AddCurrency.Code);
        SetVendorInvRoundingAcc(Vendor."Vendor Posting Group", GLAccount);

        CreatePurchaseOrder(PurchaseHeader, Vendor, GLAccount."No.");
        PostPurchasePrepayment(PurchaseHeader);
        PurchaseHeader.Find;
        PurchaseHeader.CalcFields("Amount Including VAT");
        VerifyPurchInvRoundingAmount(
          Vendor."Vendor Posting Group", PurchaseHeader, AddCurrency."Invoice Rounding Precision");
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure TFS356654_ACYAmountInPurchCreditMemo()
    var
        AddCurrency: Record Currency;
        GLAccount: Record "G/L Account";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        Initialize;

        LibraryPurchase.CreatePrepaymentVATSetup(GLAccount, "General Posting Type"::" ");
        CreateAddReportingCurrency(AddCurrency);
        CreateVendor(Vendor, GLAccount."Gen. Bus. Posting Group", GLAccount."VAT Bus. Posting Group", AddCurrency.Code);

        CreatePurchaseOrder(PurchaseHeader, Vendor, GLAccount."No.");

        PostPurchasePrepayment(PurchaseHeader);

        UpdatePostingDateOnPurchaseHeader(PurchaseHeader, CalcDate('<+2M>', WorkDate));
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryPurchase.GegVendorLedgerEntryUniqueExternalDocNo);
        PurchaseHeader.Modify(true);
        PostPurchasePrepmtCreditMemo(PurchaseHeader);

        VerifyACYAmountIsZero(AddCurrency."Realized Gains Acc.");
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure TFS356654_ACYAmountInSaleCreditMemo()
    var
        AddCurrency: Record Currency;
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        Initialize;

        LibrarySales.CreatePrepaymentVATSetup(GLAccount, "General Posting Type"::" ");
        CreateAddReportingCurrency(AddCurrency);
        CreateCustomer(Customer, GLAccount."Gen. Bus. Posting Group", GLAccount."VAT Bus. Posting Group", AddCurrency.Code);

        CreateSalesOrder(SalesHeader, Customer, GLAccount."No.");

        PostSalesPrepayment(SalesHeader);

        UpdatePostingDateOnSalesHeader(SalesHeader, CalcDate('<+2M>', WorkDate));
        PostSalesPrepmtCreditMemo(SalesHeader);

        VerifyACYAmountIsZero(AddCurrency."Realized Losses Acc.");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Prepayment ACY Posting");
        LibrarySetupStorage.Restore;
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Prepayment ACY Posting");

        LibraryPurchase.SetInvoiceRounding(false);
        LibrarySales.SetInvoiceRounding(false);
        LibraryERMCountryData.UpdateGeneralLedgerSetup;
        LibraryERMCountryData.UpdateGeneralPostingSetup;

        isInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Prepayment ACY Posting");
    end;

    local procedure CreateAddReportingCurrency(var AddCurrency: Record Currency)
    var
        RealizedGainsAccNo: Code[20];
        RealizedLossesAccNo: Code[20];
    begin
        CreateCurrencyWithExchangeRates(AddCurrency);

        LibraryERM.SetAddReportingCurrency(AddCurrency.Code);

        RealizedGainsAccNo := CreateGLAccount('');
        RealizedLossesAccNo := CreateGLAccount('');

        AddCurrency.Validate("Realized Gains Acc.", RealizedGainsAccNo);
        AddCurrency.Validate("Realized Losses Acc.", RealizedLossesAccNo);
        AddCurrency.Modify(true);
    end;

    local procedure CreateBankAccountWithCurrencyCode(var BankAccount: Record "Bank Account"; CurrencyCode: Code[10])
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Modify(true);
    end;

    local procedure CreateCurrencyWithExchangeRates(var AddCurrency: Record Currency)
    var
        GLAccount: Record "G/L Account";
        BaseExchRate: Integer;
        I: Integer;
    begin
        LibraryERM.CreateCurrency(AddCurrency);

        LibraryERM.CreateGLAccount(GLAccount);
        AddCurrency.Validate("Residual Gains Account", GLAccount."No.");
        AddCurrency.Validate("Residual Losses Account", GLAccount."No.");
        AddCurrency.Modify(true);

        BaseExchRate := LibraryRandom.RandIntInRange(100, 200);

        for I := -1 to 3 do
            CreateExchangeRate(AddCurrency.Code, CalcDate(StrSubstNo('<%1M>', Format(I)), WorkDate), BaseExchRate, BaseExchRate + 10 * I + 20);
    end;

    local procedure CreateCustomer(var Customer: Record Customer; GenBusPostingGroupCode: Code[20]; VATBusPostingGroupCode: Code[20]; CurrencyCode: Code[10])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", GenBusPostingGroupCode);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
    end;

    local procedure CreateExchangeRate(CurrencyCode: Code[10]; StartingDate: Date; ExchangeRateAmount: Decimal; RelationalExchRateAmt: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, StartingDate);
        with CurrencyExchangeRate do begin
            Validate("Exchange Rate Amount", ExchangeRateAmount);
            Validate("Relational Exch. Rate Amount", RelationalExchRateAmt);
            Validate("Adjustment Exch. Rate Amount", ExchangeRateAmount);
            Validate("Relational Adjmt Exch Rate Amt", RelationalExchRateAmt);
            Modify(true);
        end;
    end;

    local procedure CreateGLAccount(VATProdPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.FindGenProductPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateVendor(var Vendor: Record Vendor; GenBusPostingGroupCode: Code[20]; VATBusPostingGroupCode: Code[20]; CurrencyCode: Code[10])
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GenBusPostingGroupCode);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; Vendor: Record Vendor; GLAccNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Prepayment %", 100);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccNo, LibraryRandom.RandInt(5));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 1));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; Customer: Record Customer; GLAccNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Prepayment %", 100);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccNo, LibraryRandom.RandInt(5));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 1));
        SalesLine.Modify(true);
    end;

    local procedure FindPostedPurchaseInvoiceForVendor(VendorNo: Code[20]): Code[20]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchInvHeader.FindFirst;
        exit(PurchInvHeader."No.");
    end;

    local procedure FindPostedSalesInvoiceForCustomer(CustomerNo: Code[20]): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesInvoiceHeader.FindFirst;
        exit(SalesInvoiceHeader."No.");
    end;

    local procedure PostCashPayment(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BankAccNo: Code[20]; CurrencyCode: Code[10]; PostingDate: Date; Amount: Decimal; AppliesToDocNo: Code[20])
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        LibraryERM.FindGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
          GenJnlLine,
          GenJnlTemplate.Name,
          GenJnlBatch.Name,
          GenJnlLine."Document Type"::Payment,
          AccountType,
          AccountNo,
          Amount);

        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"Bank Account");
        GenJnlLine.Validate("Bal. Account No.", BankAccNo);
        GenJnlLine.Description := BankAccNo;

        GenJnlLine.Validate("Currency Code", CurrencyCode);
        GenJnlLine.Validate("Posting Date", PostingDate);

        GenJnlLine.Validate("Applies-to Doc. Type", GenJnlLine."Applies-to Doc. Type"::Invoice);
        GenJnlLine.Validate("Applies-to Doc. No.", AppliesToDocNo);

        GenJnlLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJnlLine);
    end;

    local procedure PostPurchasePrepayment(PurchHeader: Record "Purchase Header")
    begin
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchHeader);
    end;

    local procedure PostPurchasePrepmtCreditMemo(PurchHeader: Record "Purchase Header")
    begin
        LibraryPurchase.PostPurchasePrepaymentCrMemo(PurchHeader);
    end;

    local procedure PostSalesPrepayment(SalesHeader: Record "Sales Header")
    begin
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
    end;

    local procedure PostSalesPrepmtCreditMemo(SalesHeader: Record "Sales Header")
    begin
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);
    end;

    local procedure SetInvRoundingAccVATPostingGroups(InvRoundingAccountNo: Code[20]; GLAccount: Record "G/L Account")
    var
        InvRoudingGLAccount: Record "G/L Account";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Invoice Rounding Account should have different VAT Account
        VATPostingSetup.Get(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        VATPostingSetup."Sales VAT Account" := LibraryERM.CreateGLAccountNo;
        VATPostingSetup."Purchase VAT Account" := LibraryERM.CreateGLAccountNo;
        VATPostingSetup.Insert(true);

        InvRoudingGLAccount.Get(InvRoundingAccountNo);
        InvRoudingGLAccount."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        InvRoudingGLAccount."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        InvRoudingGLAccount.Modify(true);
    end;

    local procedure SetCustomerInvRoundingAcc(CustomerPostingGroupCode: Code[20]; GLAccount: Record "G/L Account")
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustomerPostingGroup.Get(CustomerPostingGroupCode);
        CustomerPostingGroup.TestField("Invoice Rounding Account");
        SetInvRoundingAccVATPostingGroups(CustomerPostingGroup."Invoice Rounding Account", GLAccount);
    end;

    local procedure SetVendorInvRoundingAcc(VendorPostingGroupCode: Code[20]; GLAccount: Record "G/L Account")
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        VendorPostingGroup.Get(VendorPostingGroupCode);
        VendorPostingGroup.TestField("Invoice Rounding Account");
        SetInvRoundingAccVATPostingGroups(VendorPostingGroup."Invoice Rounding Account", GLAccount);
    end;

    local procedure UpdatePostingDateOnPurchaseHeader(var PurchHeader: Record "Purchase Header"; PostingDate: Date)
    begin
        PurchHeader.Validate("Posting Date", PostingDate);
        PurchHeader.Modify(true);
    end;

    local procedure UpdatePostingDateOnSalesHeader(var SalesHeader: Record "Sales Header"; PostingDate: Date)
    begin
        LibrarySales.ReopenSalesDocument(SalesHeader);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
    end;

    local procedure VerifyPurchInvRoundingAmount(VendorPostingGroupCode: Code[20]; PurchaseHeader: Record "Purchase Header"; RoundingPrecision: Decimal)
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        VendorPostingGroup.Get(VendorPostingGroupCode);
        GLAccount.Get(VendorPostingGroup."Invoice Rounding Account");
        VATPostingSetup.Get(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");
        VerifyInvoiceRoundingAmount(
          PurchaseHeader."Last Prepayment No.", VendorPostingGroup."Invoice Rounding Account", VATPostingSetup."Purchase VAT Account",
          -PurchaseHeader."Amount Including VAT", RoundingPrecision);
    end;

    local procedure VerifySalesInvRoundingAmount(CustPostingGroupCode: Code[20]; SalesHeader: Record "Sales Header"; RoundingPrecision: Decimal)
    var
        CustPostingGroup: Record "Customer Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        CustPostingGroup.Get(CustPostingGroupCode);
        GLAccount.Get(CustPostingGroup."Invoice Rounding Account");
        VATPostingSetup.Get(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");
        VerifyInvoiceRoundingAmount(
          SalesHeader."Last Prepayment No.", CustPostingGroup."Invoice Rounding Account", VATPostingSetup."Sales VAT Account",
          SalesHeader."Amount Including VAT", RoundingPrecision);
    end;

    local procedure VerifyInvoiceRoundingAmount(DocumentNo: Code[20]; RoundingAccNo: Code[20]; VATRoundingAccNo: Code[20]; InvoiceAmount: Decimal; RoundingPrecision: Decimal)
    var
        GLEntry: Record "G/L Entry";
        ExpectedRoundingAmt: Decimal;
    begin
        ExpectedRoundingAmt := InvoiceAmount - Round(InvoiceAmount, RoundingPrecision);

        with GLEntry do begin
            SetRange("Document No.", DocumentNo);
            SetFilter("G/L Account No.", '%1|%2', RoundingAccNo, VATRoundingAccNo);
            CalcSums("Additional-Currency Amount");
            Assert.AreEqual(ExpectedRoundingAmt, "Additional-Currency Amount", IncorrectRoundingAmtErr);
        end;
    end;

    local procedure VerifyACYAmountIsZero(GLAccNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        with GLEntry do begin
            SetRange("G/L Account No.", GLAccNo);
            Assert.IsFalse(IsEmpty, NoGLEntriesPostedErr);

            FindSet;
            repeat
                Assert.AreEqual(0, "Additional-Currency Amount", LCYAmtMustBeZeroErr);
            until Next = 0;
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

