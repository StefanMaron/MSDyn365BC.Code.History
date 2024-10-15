codeunit 144065 "Test CH VATSTAT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('AdjustExchageRatesRequestPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestInsertACorrectionVATEntryInsteadOfCorrectingTheOriginal()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetupInvt(VATPostingSetup);
        ExecuteAdjustExchangeRelatedTest(true, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCalculateVATAmountForInsertedCorrectionVATEntries()
    var
        CurrencyCode: Code[10];
        CustomerNumber: Code[20];
        DocumentNumber: Code[20];
        SettlementAccountNo: Code[20];
        BaseAmount: Decimal;
        Date: Date;
    begin
        RunCalcAndPostVATSettlementAndAdjustExchangeRates(Date, CurrencyCode, DocumentNumber, CustomerNumber,
          BaseAmount, SettlementAccountNo, false);

        VerifyReport(DocumentNumber, CustomerNumber, 'Base_VATEntry', 'Amount_VATEntry', 1);
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler,ConfirmHandler,AdjustExchageRatesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestCheckExchangeRateAdjustmentFunctionalityWithVATEntries()
    var
        CurrencyCode: Code[10];
        CustomerNumber: Code[20];
        DocumentNumber: Code[20];
        SettlementAccountNo: Code[20];
        BaseAmount: Decimal;
        Date: Date;
    begin
        RunCalcAndPostVATSettlementAndAdjustExchangeRates(Date, CurrencyCode, DocumentNumber, CustomerNumber,
          BaseAmount, SettlementAccountNo, true);

        VerifyVATEntry(DocumentNumber, CustomerNumber, CurrencyCode, Date, BaseAmount);
    end;

    [Test]
    [HandlerFunctions('SwissVATStatementReportRequestPageHandler,CalcAndPostVATSettlementRequestPageHandler,ConfirmHandler,AdjustExchageRatesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OldSwissVATStatementIsCreated()
    var
        GLEntry: Record "G/L Entry";
        GLRegister: Record "G/L Register";
        VATEntry: Record "VAT Entry";
        CurrencyCode: Code[10];
        CustomerNumber: Code[20];
        DocumentNumber: Code[20];
        SettlementAccountNo: Code[20];
        BaseAmount: Decimal;
        Date: Date;
    begin
        RunCalcAndPostVATSettlementAndAdjustExchangeRates(Date, CurrencyCode, DocumentNumber, CustomerNumber,
          BaseAmount, SettlementAccountNo, true);
        VATEntry.SetRange("Posting Date", Date);
        VATEntry.SetRange("Document No.", DocumentNumber);
        VATEntry.SetRange(Type, VATEntry.Type::Settlement);
        VATEntry.FindFirst;

        GLRegister.SetRange("From VAT Entry No.", VATEntry."Entry No.");
        GLRegister.FindFirst;
        LibraryVariableStorage.Enqueue(GLRegister."No.");

        Commit;
        GLEntry.SetRange("Document No.", DocumentNumber);
        REPORT.Run(REPORT::"Old Swiss VAT Statement", true, false, GLEntry);
        VerifyReport(DocumentNumber, CustomerNumber, 'Base_VATEntry', 'Amt_VATEntry', -1);
    end;

    [Test]
    [HandlerFunctions('AdjustExchageRatesRequestPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestAdjustVATBaseAmountsOnVATEntries()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindZeroVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        ExecuteAdjustExchangeRelatedTest(false, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AdjustExchageRatesRequestPageHandler(var AdjustExchangeRates: TestRequestPage "Adjust Exchange Rates")
    var
        DocumentNumber: Variant;
        DateAsVariant: Variant;
        Date: Date;
    begin
        LibraryVariableStorage.Dequeue(DocumentNumber);
        LibraryVariableStorage.Dequeue(DateAsVariant);
        Date := Variant2Date(DateAsVariant);
        AdjustExchangeRates.Post.SetValue(true);
        AdjustExchangeRates.AdjustBankAccounts.SetValue(true);
        AdjustExchangeRates.AdjCustomers.SetValue(true);
        AdjustExchangeRates.AdjVendors.SetValue(true);
        AdjustExchangeRates.AdjVAT.SetValue(true);
        AdjustExchangeRates.AdjGLAcc.SetValue(false);
        AdjustExchangeRates.StartingDate.SetValue(Date);
        AdjustExchangeRates.EndingDate.SetValue(Date + 30);
        AdjustExchangeRates.PostingDate.SetValue(Date + 30);
        AdjustExchangeRates.DocumentNo.SetValue(DocumentNumber);

        AdjustExchangeRates.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
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

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcAndPostVATSettlementRequestPageHandler(var CalcAndPostVATSettlement: TestRequestPage "Calc. and Post VAT Settlement")
    var
        DocumentNo: Variant;
        SettlementAccountNo: Variant;
        DateAsVariant: Variant;
        Date: Date;
    begin
        LibraryVariableStorage.Dequeue(SettlementAccountNo);
        LibraryVariableStorage.Dequeue(DocumentNo);
        LibraryVariableStorage.Dequeue(DateAsVariant);
        Date := Variant2Date(DateAsVariant);
        CalcAndPostVATSettlement.StartingDate.SetValue(Date);
        CalcAndPostVATSettlement.EndDateReq.SetValue(Date);
        CalcAndPostVATSettlement.PostingDt.SetValue(Date);
        CalcAndPostVATSettlement.DocumentNo.SetValue(DocumentNo);
        CalcAndPostVATSettlement.SettlementAcc.SetValue(SettlementAccountNo);
        CalcAndPostVATSettlement.ShowVATEntries.SetValue(true);
        CalcAndPostVATSettlement.Post.SetValue(true);
        CalcAndPostVATSettlement.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SwissVATStatementReportRequestPageHandler(var OldSwissVATStatement: TestRequestPage "Old Swiss VAT Statement")
    var
        SettlementDocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(SettlementDocumentNo);

        OldSwissVATStatement.ClosedWithJournalnumber.SetValue(SettlementDocumentNo);
        OldSwissVATStatement.ShowEntries.SetValue(true);
        OldSwissVATStatement.ShowBalanceEntries.SetValue(true);
        OldSwissVATStatement.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [Normal]
    local procedure Setup(var Date: Date; var CurrencyCode: Code[10]; var DocumentNumber: Code[20]; var CustomerNumber: Code[20]; var BaseAmount: Decimal; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; IsLocalWithForeignCurrency: Boolean)
    var
        UnitAmount: Decimal;
        Quantity: Integer;
        ForeignCurrencyCode: Code[10];
    begin
        Date := WorkDate;
        CurrencyCode := CreateCurrency(Date);
        CustomerNumber := CreateCustomer(VATBusPostingGroup, CurrencyCode);
        UnitAmount := LibraryRandom.RandDec(10000, 2);
        Quantity := LibraryRandom.RandInt(10);
        if IsLocalWithForeignCurrency then
            ForeignCurrencyCode := CurrencyCode;

        CreateAndPostSalesOrder(
          DocumentNumber,
          BaseAmount,
          CustomerNumber,
          Quantity,
          UnitAmount,
          VATProdPostingGroup,
          ForeignCurrencyCode);

        LibraryVariableStorage.Enqueue(DocumentNumber);
        LibraryVariableStorage.Enqueue(Date);
    end;

    [Normal]
    local procedure ExecuteAdjustExchangeRelatedTest(IsLocalWithForeignCurrency: Boolean; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    var
        Currency: Record Currency;
        CurrencyCode: Code[10];
        CustomerNumber: Code[20];
        DocumentNumber: Code[20];
        Date: Date;
        BaseAmount: Decimal;
    begin
        Init;

        // Setup
        Setup(Date, CurrencyCode, DocumentNumber, CustomerNumber, BaseAmount, VATBusPostingGroup,
          VATProdPostingGroup, IsLocalWithForeignCurrency);

        // Run the report.
        Commit;
        Currency.SetRange(Code, CurrencyCode);
        REPORT.Run(REPORT::"Adjust Exchange Rates", true, false, Currency);

        // Validate
        VerifyVATEntry(DocumentNumber, CustomerNumber, CurrencyCode, Date, BaseAmount);
    end;

    [Normal]
    local procedure RunCalcAndPostVATSettlementAndAdjustExchangeRates(var Date: Date; var CurrencyCode: Code[10]; var DocumentNumber: Code[20]; var CustomerNumber: Code[20]; var BaseAmount: Decimal; var SettlementAccountNo: Code[20]; RunAdjustExchangeRate: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccountForSettlement: Record "G/L Account";
        Currency: Record Currency;
    begin
        Init;

        // Setup
        LibraryERM.FindVATPostingSetupInvt(VATPostingSetup);

        LibraryERM.CreateGLAccount(GLAccountForSettlement);
        LibraryVariableStorage.Enqueue(GLAccountForSettlement."No.");
        SettlementAccountNo := GLAccountForSettlement."No.";
        Setup(Date, CurrencyCode, DocumentNumber, CustomerNumber, BaseAmount, VATPostingSetup."VAT Bus. Posting Group",
          VATPostingSetup."VAT Prod. Posting Group", true);

        // Run the Calc. and Post VAT Settlement batch job.
        Commit;
        REPORT.Run(REPORT::"Calc. and Post VAT Settlement", true, false);

        if not RunAdjustExchangeRate then
            exit;

        // Enqueue again.
        LibraryVariableStorage.Enqueue(DocumentNumber);
        LibraryVariableStorage.Enqueue(Date);

        // Run Adjust Exchange rates
        Currency.SetRange(Code, CurrencyCode);
        REPORT.Run(REPORT::"Adjust Exchange Rates", true, false, Currency);
    end;

    local procedure Init()
    begin
        LibraryVariableStorage.Clear;

        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup;
        IsInitialized := true;
    end;

    local procedure CreateAndPostSalesOrder(var DocumentNumber: Code[20]; var BaseAmount: Decimal; CustomerNumber: Code[20]; Quantity: Decimal; UnitPrice: Decimal; VATProdPostingGroup: Code[20]; ForeignCurrencyCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNumber);
        if StrLen(ForeignCurrencyCode) > 0 then
            SalesHeader.Validate("Currency Code", ForeignCurrencyCode);

        LibrarySales.CreateSalesLine(
          SalesLine,
          SalesHeader,
          SalesLine.Type::Item,
          CreateItem(VATProdPostingGroup),
          Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);

        DocumentNumber := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        BaseAmount := Quantity * UnitPrice;
        BaseAmount += SalesLine."VAT %" * BaseAmount / 100;
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify;
        exit(Item."No.");
    end;

    [Normal]
    local procedure CreateCustomer(VATPostingGroup: Code[20]; CurrencyCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingGroup);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify;
        exit(Customer."No.");
    end;

    [Normal]
    local procedure CreateCurrency(Date: Date): Code[10]
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GainsGLAccount: Record "G/L Account";
        LossesGLAccount: Record "G/L Account";
        Currency: Record Currency;
        RelationalExchangeRate: Decimal;
        CurrencyCode: Code[10];
    begin
        LibraryERM.CreateGLAccount(GainsGLAccount);
        LibraryERM.CreateGLAccount(LossesGLAccount);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(Date, 1, 1);

        Currency.Get(CurrencyCode);
        Currency.Validate("Realized Gains Acc.", GainsGLAccount."No.");
        Currency.Validate("Realized Losses Acc.", LossesGLAccount."No.");
        Currency.Modify(true);

        CurrencyExchangeRate.Get(CurrencyCode, Date);
        with CurrencyExchangeRate do begin
            RelationalExchangeRate := LibraryRandom.RandDecInRange(1, 2, 1);
            Validate("Relational Exch. Rate Amount", RelationalExchangeRate);
            Validate("Relational Adjmt Exch Rate Amt", RelationalExchangeRate);
            Validate("VAT Exch. Rate Amount", 1);
            Validate("Relational VAT Exch. Rate Amt", LibraryRandom.RandDecInRange(1, 2, 2));
            Modify(true);
        end;
        exit(CurrencyCode);
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; CustomerNo: Code[20]; CurrencyCode: Code[10]; Date: Date; BaseAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        AdjustedBaseAmount: Decimal;
        AmountInCH: Decimal;
        AmountInVATEntry: Decimal;
        AdjustedBaseAmountFound: Boolean;
        BaseAmountFound: Boolean;
    begin
        with CurrencyExchangeRate do begin
            Get(CurrencyCode, Date);

            AmountInCH := BaseAmount / "Exchange Rate Amount" * "Relational Exch. Rate Amount";
            AdjustedBaseAmount := BaseAmount / "VAT Exch. Rate Amount" * "Relational VAT Exch. Rate Amt" - AmountInCH;
        end;

        with VATEntry do begin
            SetRange("Document No.", DocumentNo);
            SetRange("Document Type", "Document Type"::Invoice);
            SetRange(Type, Type::Sale);
            SetRange("Bill-to/Pay-to No.", CustomerNo);

            AdjustedBaseAmountFound := false;
            BaseAmountFound := false;
            if Find('-') then
                repeat
                    // If the entry is closed then the "Unadjusted Exchange Rate" is true
                    Assert.IsTrue(not Closed or "Unadjusted Exchange Rate",
                      'If the entry is closed then the "Unadjusted Exchange Rate" is true');
                    AmountInVATEntry := Base + Amount;
                    if Abs(Abs(AmountInVATEntry) - AdjustedBaseAmount) <= LibraryERM.GetAmountRoundingPrecision then begin
                        Assert.IsFalse(Closed, 'Found an adjusted amount for a closed VAT amount');
                        AdjustedBaseAmountFound := true
                    end else begin
                        // For closed entries the adjusted amount does not exist.
                        if Closed then
                            AdjustedBaseAmountFound := true;

                        if Abs(Abs(AmountInVATEntry) - AmountInCH) <= LibraryERM.GetAmountRoundingPrecision then
                            BaseAmountFound := true;
                    end;
                until Next = 0;

            Assert.IsTrue(BaseAmountFound and AdjustedBaseAmountFound,
              'Could not find neither the base amount, nor the adjusted amount in the VAT entry table');
        end;
    end;

    [Normal]
    local procedure VerifyReport(DocumentNumber: Code[20]; CustomerNumber: Code[20]; FieldNameBase: Text; FieldNameVAT: Text; Sign: Integer)
    var
        VATEntry: Record "VAT Entry";
    begin
        LibraryReportDataset.LoadDataSetFile;
        // Verify that an additional entry for the currency difference has been generated besides the normal entry.
        with VATEntry do begin
            SetRange("Document No.", DocumentNumber);
            SetRange("Document Type", "Document Type"::Invoice);
            SetRange(Type, Type::Sale);
            SetRange("Bill-to/Pay-to No.", CustomerNumber);

            if Find('-') then
                repeat
                    LibraryReportDataset.AssertElementWithValueExists(FieldNameBase, Sign * Base);
                    LibraryReportDataset.AssertElementWithValueExists(FieldNameVAT, Sign * Amount);
                until Next = 0;
        end;
    end;
}

