codeunit 134290 "Non-Deductible VAT Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Non-Deductible VAT]
    end;

    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryNonDeductibleVAT: Codeunit "Library - NonDeductible VAT";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit "Assert";
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler')]
    procedure VATSettlementReverseChargeVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATEntry: Record "VAT Entry";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ExpectedSettlementAmount, ExpectedSettlementAmountACY : Decimal;
        CurrencyCode: Code[10];
        SettlementDocNo, SettlementAccNo : Code[20];
        NDVATBase, NDVATAmount, NDVATBaseACY, NDVATAmountACY : Decimal;
    begin
        // [FEATURE] [VAT Settlement]
        // [SCENARIO 507719] VAT settlement considers both deductible and non-deductible parts for reverse charge VAT

        Initialize();
        // [GIVEN] VAT Posting Setup with Reverse Charge VAT, "VAT %" = 25 and "Non-Deductible VAT %" = 50
        LibraryNonDeductibleVAT.CreateNonDeductibleReverseChargeVATPostingSetup(VATPostingSetup);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 10, 10);
        LibraryERM.SetAddReportingCurrency(CurrencyCode);
        // [GIVEN] Purchase invoice with Amount = 1000, VAT Amount = 250, Non-Deductible VAT Amount = 125
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
            LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::Purchase), LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        VATEntry.SetRange("Posting Date", PurchaseHeader."Posting Date");
        VATEntry.SetRange("Document No.", LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        VATEntry.FindFirst();
        NDVATBase := VATEntry."Non-Deductible VAT Base";
        NDVATAmount := VATEntry."Non-Deductible VAT Amount";
        NDVATBaseACY := VATEntry."Non-Deductible VAT Base ACY";
        NDVATAmountACY := VATEntry."Non-Deductible VAT Amount ACY";
        ExpectedSettlementAmount := -Round(
            Round(PurchaseLine.Amount * VATPostingSetup."VAT %" / 100) * VATPostingSetup."Non-Deductible VAT %" / 100);
        CurrencyExchangeRate.Get(CurrencyCode, PurchaseHeader."Posting Date");
        ExpectedSettlementAmountACY :=
            -Round(
                Round(PurchaseLine.Amount * CurrencyExchangeRate."Exchange Rate Amount" / CurrencyExchangeRate."Relational Exch. Rate Amount") *
                (VATPostingSetup."VAT %" / 100) * VATPostingSetup."Non-Deductible VAT %" / 100);
        SettlementDocNo := LibraryUtility.GenerateGUID();
        SettlementAccNo := LibraryERM.CreateGLAccountNo();

        // [WHEN] Run "Calc. and Post VAT Settlement" report with a Post option
        RunCalcAndPostVATSettlementReport(VATPostingSetup, SettlementDocNo, SettlementAccNo, true);
        // [THEN] VAT Amount printed in the report is 125
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VATAmount', ExpectedSettlementAmount);
        LibraryReportDataset.AssertElementWithValueExists('VATAmountAddCurr', ExpectedSettlementAmountACY);
        // [THEN] G/L Entry with settlement amount has value of 125
        VerifySingleGLEntryAmount(PurchaseHeader."Posting Date", SettlementAccNo, ExpectedSettlementAmount);
        // [THEN] Settlement VAT entry has negative values for the Non-Deductible VAT base and amount
        VATEntry.SetRange("Posting Date", PurchaseHeader."Posting Date");
        VATEntry.SetRange("Document No.", SettlementDocNo);
        VATEntry.SetRange(Type, VATEntry.Type::Settlement);
        Assert.RecordCount(VATEntry, 1);
        VATEntry.FindFirst();
        VATEntry.TestField("Non-Deductible VAT Base", -NDVATBase);
        VATEntry.TestField("Non-Deductible VAT Amount", -NDVATAmount);
        VATEntry.TestField("Non-Deductible VAT Base ACY", -NDVATBaseACY);
        VATEntry.TestField("Non-Deductible VAT Amount ACY", -NDVATAmountACY);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Non-Deductible VAT Reports");
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Non-Deductible VAT Reports");
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibraryNonDeductibleVAT.EnableNonDeductibleVAT();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibrarySetupStorage.Save(Database::"VAT Setup");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Non-Deductible VAT Reports");
    end;

    local procedure RunCalcAndPostVATSettlementReport(VATPostingSetup: Record "VAT Posting Setup"; DocumentNo: Code[20]; SettlementAccNo: Code[20]; Post: Boolean)
        CalcAndPostVATSettlement: Report "Calc. and Post VAT Settlement";
    begin
        VATPostingSetup.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATPostingSetup.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        CalcAndPostVATSettlement.SetTableView(VATPostingSetup);
        CalcAndPostVATSettlement.InitializeRequest(WorkDate(), WorkDate(), WorkDate(), DocumentNo, SettlementAccNo, false, Post);
        Commit();
        CalcAndPostVATSettlement.Run();
    end;

    local procedure VerifySingleGLEntryAmount(PostingDate: Date; GLAccNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        Assert.RecordCount(GLEntry, 1);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, Amount);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcAndPostVATSettlementRequestPageHandler(var CalcAndPostVATSettlement: TestRequestPage "Calc. and Post VAT Settlement")
    begin
        if CalcAndPostVATSettlement.Editable then;
        CalcAndPostVATSettlement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName())
    end;
}
