codeunit 142091 "Expense/Capitalize Sales Tax"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales Tax] [Expense/Capitalize]
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryJob: Codeunit "Library - Job";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        WrongAmountErr: Label 'Wrong amount in field %1, table %2.';
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure JobUsageCostLCYShouldIncludeExpensedTax()
    var
        TaxArea: Record "Tax Area";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TaxGroup: Record "Tax Group";
    begin
        Initialize;
        UpdatePurchaseSetup(true);

        CreateSalesTaxSetupWithTaxExpenseJurisdiction(TaxArea, TaxGroup);
        CreateJobPurchaseOrderInLocalCurrency(PurchaseHeader, PurchaseLine, TaxGroup.Code, TaxArea.Code, 1,
          LibraryRandom.RandDecInRange(100, 500, 2));
        PostPurchaseDocSaveLine(PurchaseHeader, PurchaseLine);

        VerifyJobLedgerEntry(PurchaseLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobUsageCostFCYShouldIncludeExpensedTax()
    var
        TaxArea: Record "Tax Area";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TaxGroup: Record "Tax Group";
    begin
        Initialize;
        UpdatePurchaseSetup(true);

        CreateSalesTaxSetupWithTaxExpenseJurisdiction(TaxArea, TaxGroup);
        CreateJobPurchaseOrderInForeignCurrency(PurchaseHeader, PurchaseLine, TaxGroup.Code, TaxArea.Code, 1,
          LibraryRandom.RandDecInRange(100, 500, 2));
        PostPurchaseDocSaveLine(PurchaseHeader, PurchaseLine);

        VerifyJobLedgerEntry(PurchaseLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmtReceivedNotInvoicedShouldNotIncludeExpensedTax()
    var
        TaxArea: Record "Tax Area";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TaxGroup: Record "Tax Group";
        UnitAmount: Decimal;
    begin
        Initialize;
        UpdatePurchaseSetup(true);

        CreateSalesTaxSetupWithTaxExpenseJurisdiction(TaxArea, TaxGroup);
        CreateTaxJurisdiction(TaxArea.Code, TaxGroup.Code, false);

        UnitAmount := LibraryRandom.RandDecInRange(100, 500, 2);
        CreateJobPurchaseOrderInLocalCurrency(
          PurchaseHeader, PurchaseLine, TaxGroup.Code, TaxArea.Code, LibraryRandom.RandIntInRange(2, 5), UnitAmount);
        SetQuantityToReceive(PurchaseLine, 1);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        with PurchaseLine do begin
            Find;
            Assert.AreNearlyEqual(
              UnitAmount, "A. Rcd. Not Inv. Ex. VAT (LCY)", 0.01,
              StrSubstNo(WrongAmountErr, FieldName("A. Rcd. Not Inv. Ex. VAT (LCY)"), TableName));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleaseReopenedPurchOrderWithClearedSalesTax()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TaxArea: Record "Tax Area";
        TaxGroup: Record "Tax Group";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 379357] Release Purchase Order after reopen and clear Sales Tax fields
        // [GIVEN] "Use Vendor's Tax Area Code" is TRUE on Purchase Setup
        Initialize;
        UpdatePurchaseSetup(true);

        // [GIVEN] Released Purchase Order with Expense Sales Tax, where "Tax To Be Expensed" = 100
        CreateSalesTaxSetupWithTaxExpenseJurisdiction(TaxArea, TaxGroup);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, TaxArea.Code, TaxGroup.Code);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Tax is reset for Purchase Line
        ReleasePurchaseDocument.Reopen(PurchaseHeader);
        PurchaseLine.Find;
        PurchaseLine.Validate("Tax Liable", false);
        PurchaseLine.Validate("Tax Area Code", '');
        PurchaseLine.Validate("Tax Group Code", '');
        PurchaseLine.Modify(true);

        // [WHEN] Release Purchase Order
        ReleasePurchaseDocument.PerformManualRelease(PurchaseHeader);

        // [THEN] Purchase Line has "Tax To Be Expensed" is 0
        PurchaseLine.Find;
        PurchaseLine.TestField("Tax To Be Expensed", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesAmountInclTaxAfterReleaseWithoutCalcInvDisc()
    var
        SalesHeader: Record "Sales Header";
        TaxArea: Record "Tax Area";
        TaxGroup: Record "Tax Group";
    begin
        // [FEATURE] [Release] [Invoice Discount] [Sales]
        // [SCENARIO 214434] Sales Line is recalculated after Manual Release
        // [SCENARIO 214434] in case of Sales Tax setup with "Expense/Capitalize" = TRUE, SalesReceivablesSetup."Calc. Inv. Discount" = FALSE
        Initialize;

        // [GIVEN] SalesReceivablesSetup."Calc. Inv. Discount" = FALSE
        LibrarySales.SetCalcInvDiscount(false);

        // [GIVEN] Sales Tax setup with "Tax Below Maximum" = 10, "Expense/Capitalize" = TRUE
        CreateSalesTaxSetupWithTaxExpenseJurisdiction(TaxArea, TaxGroup);

        // [GIVEN] Sales Invoice with "Unit Price" = 1000
        CreateSalesInvoice(SalesHeader, TaxArea.Code, TaxGroup.Code);

        // [WHEN] Perform manual release
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [THEN] Sales Line has been recalculated and "Amount Including VAT" = 1100
        VerifySalesHeaderAmountInclVAT(SalesHeader, TaxGroup.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesAmountInclTaxAfterReleaseWithCalcInvDisc()
    var
        SalesHeader: Record "Sales Header";
        TaxArea: Record "Tax Area";
        TaxGroup: Record "Tax Group";
    begin
        // [FEATURE] [Release] [Invoice Discount] [Sales]
        // [SCENARIO 214434] Sales Line is recalculated after Manual Release
        // [SCENARIO 214434] in case of Sales Tax setup with "Expense/Capitalize" = TRUE, SalesReceivablesSetup."Calc. Inv. Discount" = TRUE
        Initialize;

        // [GIVEN] SalesReceivablesSetup."Calc. Inv. Discount" = TRUE
        LibrarySales.SetCalcInvDiscount(true);

        // [GIVEN] Sales Tax setup with "Tax Below Maximum" = 10, "Expense/Capitalize" = TRUE
        CreateSalesTaxSetupWithTaxExpenseJurisdiction(TaxArea, TaxGroup);

        // [GIVEN] Sales Invoice with "Unit Price" = 1000
        CreateSalesInvoice(SalesHeader, TaxArea.Code, TaxGroup.Code);

        // [WHEN] Perform manual release
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [THEN] Sales Line has been recalculated and "Amount Including VAT" = 1100
        VerifySalesHeaderAmountInclVAT(SalesHeader, TaxGroup.Code);
    end;

    [Test]
    [HandlerFunctions('SalesDocumentTest_RPH')]
    [Scope('OnPrem')]
    procedure SalesAmountInclTaxAfterReleaseAndTestReportWithoutCalcInvDisc()
    var
        SalesHeader: Record "Sales Header";
        TaxArea: Record "Tax Area";
        TaxGroup: Record "Tax Group";
    begin
        // [FEATURE] [Release] [Invoice Discount] [Sales] [Report]
        // [SCENARIO 214434] Sales Line is recalculated after Manual Release and print test report
        // [SCENARIO 214434] in case of Sales Tax setup with "Expense/Capitalize" = TRUE, SalesReceivablesSetup."Calc. Inv. Discount" = FALSE
        Initialize;

        // [GIVEN] SalesReceivablesSetup."Calc. Inv. Discount" = FALSE
        LibrarySales.SetCalcInvDiscount(false);

        // [GIVEN] Sales Tax setup with "Tax Below Maximum" = 10, "Expense/Capitalize" = TRUE
        CreateSalesTaxSetupWithTaxExpenseJurisdiction(TaxArea, TaxGroup);

        // [GIVEN] Sales Invoice with "Unit Price" = 1000
        CreateSalesInvoice(SalesHeader, TaxArea.Code, TaxGroup.Code);

        // [GIVEN] Perform manual release
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] Print "Test Report"
        TestReportPrintSalesDoc(SalesHeader);

        // [THEN] SalesLine."Amount Including VAT" = 1100
        VerifySalesHeaderAmountInclVAT(SalesHeader, TaxGroup.Code);
    end;

    [Test]
    [HandlerFunctions('SalesDocumentTest_RPH')]
    [Scope('OnPrem')]
    procedure SalesAmountInclTaxAfterReleaseAndTestReportWithCalcInvDisc()
    var
        SalesHeader: Record "Sales Header";
        TaxArea: Record "Tax Area";
        TaxGroup: Record "Tax Group";
    begin
        // [FEATURE] [Release] [Invoice Discount] [Sales] [Report]
        // [SCENARIO 214434] Sales Line is recalculated after Manual Release and print test report
        // [SCENARIO 214434] in case of Sales Tax setup with "Expense/Capitalize" = TRUE, SalesReceivablesSetup."Calc. Inv. Discount" = TRUE
        Initialize;

        // [GIVEN] SalesReceivablesSetup."Calc. Inv. Discount" = TRUE
        LibrarySales.SetCalcInvDiscount(true);

        // [GIVEN] Sales Tax setup with "Tax Below Maximum" = 10, "Expense/Capitalize" = TRUE
        CreateSalesTaxSetupWithTaxExpenseJurisdiction(TaxArea, TaxGroup);

        // [GIVEN] Sales Invoice with "Unit Price" = 1000
        CreateSalesInvoice(SalesHeader, TaxArea.Code, TaxGroup.Code);

        // [GIVEN] Perform manual release
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] Print "Test Report"
        TestReportPrintSalesDoc(SalesHeader);

        // [THEN] SalesLine."Amount Including VAT" = 1100
        VerifySalesHeaderAmountInclVAT(SalesHeader, TaxGroup.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseAmountInclTaxAfterReleaseWithoutCalcInvDisc()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxArea: Record "Tax Area";
        TaxGroup: Record "Tax Group";
    begin
        // [FEATURE] [Release] [Invoice Discount] [Purchase]
        // [SCENARIO 214434] Purchase Line is recalculated after Manual Release
        // [SCENARIO 214434] in case of Sales Tax setup with "Expense/Capitalize" = TRUE, PurchasesPayablesSetup."Calc. Inv. Discount" = FALSE
        Initialize;

        // [GIVEN] PurchasesPayablesSetup."Calc. Inv. Discount" = FALSE
        LibraryPurchase.SetCalcInvDiscount(false);

        // [GIVEN] Sales Tax setup with "Tax Below Maximum" = 10, "Expense/Capitalize" = TRUE
        CreateSalesTaxSetupWithTaxExpenseJurisdiction(TaxArea, TaxGroup);

        // [GIVEN] Purchase Invoice with "Direct Unit Cost" = 1000
        CreatePurchaseInvoice(PurchaseHeader, TaxArea.Code, TaxGroup.Code);

        // [WHEN] Perform manual release
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [THEN] Purchase Line has been recalculated and "Amount Including VAT" = 1100
        VerifyPurchaseHeaderAmountInclVAT(PurchaseHeader, TaxGroup.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseAmountInclTaxAfterReleaseWithCalcInvDisc()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxArea: Record "Tax Area";
        TaxGroup: Record "Tax Group";
    begin
        // [FEATURE] [Release] [Invoice Discount] [Purchase]
        // [SCENARIO 214434] Purchase Line is recalculated after Manual Release
        // [SCENARIO 214434] in case of Sales Tax setup with "Expense/Capitalize" = TRUE, PurchasesPayablesSetup."Calc. Inv. Discount" = TRUE
        Initialize;

        // [GIVEN] PurchasesPayablesSetup."Calc. Inv. Discount" = TRUE
        LibraryPurchase.SetCalcInvDiscount(true);

        // [GIVEN] Sales Tax setup with "Tax Below Maximum" = 10, "Expense/Capitalize" = TRUE
        CreateSalesTaxSetupWithTaxExpenseJurisdiction(TaxArea, TaxGroup);

        // [GIVEN] Purchase Invoice with "Direct Unit Cost" = 1000
        CreatePurchaseInvoice(PurchaseHeader, TaxArea.Code, TaxGroup.Code);

        // [WHEN] Perform manual release
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [THEN] Purchase Line has been recalculated and "Amount Including VAT" = 1100
        VerifyPurchaseHeaderAmountInclVAT(PurchaseHeader, TaxGroup.Code);
    end;

    [Test]
    [HandlerFunctions('PurchaseDocumentTest_RPH')]
    [Scope('OnPrem')]
    procedure PurchaseAmountInclTaxAfterReleaseAndTestReportWithoutCalcInvDisc()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxArea: Record "Tax Area";
        TaxGroup: Record "Tax Group";
    begin
        // [FEATURE] [Release] [Invoice Discount] [Purchase] [Report]
        // [SCENARIO 214434] Purchase Line is recalculated after Manual Release and print test report
        // [SCENARIO 214434] in case of Sales Tax setup with "Expense/Capitalize" = TRUE, PurchasesPayablesSetup."Calc. Inv. Discount" = FALSE
        Initialize;

        // [GIVEN] PurchasesPayablesSetup."Calc. Inv. Discount" = FALSE
        LibraryPurchase.SetCalcInvDiscount(false);

        // [GIVEN] Sales Tax setup with "Tax Below Maximum" = 10, "Expense/Capitalize" = TRUE
        CreateSalesTaxSetupWithTaxExpenseJurisdiction(TaxArea, TaxGroup);

        // [GIVEN] Purchase Invoice with "Direct Unit Cost" = 1000
        CreatePurchaseInvoice(PurchaseHeader, TaxArea.Code, TaxGroup.Code);

        // [GIVEN] Perform manual release
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Print "Test Report"
        TestReportPrintPurchaseDoc(PurchaseHeader);

        // [THEN] PurchaseLine."Amount Including VAT" = 1100
        VerifyPurchaseHeaderAmountInclVAT(PurchaseHeader, TaxGroup.Code);
    end;

    [Test]
    [HandlerFunctions('PurchaseDocumentTest_RPH')]
    [Scope('OnPrem')]
    procedure PurchaseAmountInclTaxAfterReleaseAndTestReportWithCalcInvDisc()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxArea: Record "Tax Area";
        TaxGroup: Record "Tax Group";
    begin
        // [FEATURE] [Release] [Invoice Discount] [Purchase] [Report]
        // [SCENARIO 214434] Purchase Line is recalculated after Manual Release and print test report
        // [SCENARIO 214434] in case of Sales Tax setup with "Expense/Capitalize" = TRUE, PurchasesPayablesSetup."Calc. Inv. Discount" = TRUE
        Initialize;

        // [GIVEN] PurchasesPayablesSetup."Calc. Inv. Discount" = TRUE
        LibraryPurchase.SetCalcInvDiscount(true);

        // [GIVEN] Sales Tax setup with "Tax Below Maximum" = 10, "Expense/Capitalize" = TRUE
        CreateSalesTaxSetupWithTaxExpenseJurisdiction(TaxArea, TaxGroup);

        // [GIVEN] Purchase Invoice with "Direct Unit Cost" = 1000
        CreatePurchaseInvoice(PurchaseHeader, TaxArea.Code, TaxGroup.Code);

        // [GIVEN] Perform manual release
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] Print "Test Report"
        TestReportPrintPurchaseDoc(PurchaseHeader);

        // [THEN] PurchaseLine."Amount Including VAT" = 1100
        VerifyPurchaseHeaderAmountInclVAT(PurchaseHeader, TaxGroup.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseExpenceTaxWithZeroBalance()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TotalPurchaseLine: Record "Purchase Line";
        TaxArea: Record "Tax Area";
        TaxGroup: Record "Tax Group";
        DocumentTotals: Codeunit "Document Totals";
        VATAmount: Decimal;
        Amount: Decimal;
        TaxToBeExpenced: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 281818] "Tax To Be Expensed" is calculated for Purchase Invoice with zero balance
        Initialize;

        // [GIVEN] Sales Tax setup with "Tax Below Maximum" = 10, "Expense/Capitalize" = TRUE
        CreateSalesTaxSetupWithTaxExpenseJurisdiction(TaxArea, TaxGroup);

        // [GIVEN] Purchase Invoice of one line with "Direct Unit Cost" = 1000
        CreatePurchaseInvoice(PurchaseHeader, TaxArea.Code, TaxGroup.Code);

        // [GIVEN] "Tax To Be Expensed" is equal to 100
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst;
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchaseLine);
        PurchaseLine.TestField("Tax To Be Expensed");
        Amount := PurchaseLine.Amount;
        TaxToBeExpenced := PurchaseLine."Tax To Be Expensed";

        // [WHEN] Create purchase line with opposite quantity and "Direct Unit Cost" = 1000
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type, PurchaseLine."No.", -PurchaseLine.Quantity);
        PurchaseLine.Validate("Direct Unit Cost", Amount);
        PurchaseLine.Validate("Tax Group Code", TaxGroup.Code);
        PurchaseLine.Modify(true);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchaseLine);

        // [THEN] "Tax To Be Expensed" = -100 in balanced line
        PurchaseLine.TestField("Tax To Be Expensed", -TaxToBeExpenced);
    end;

    local procedure Initialize()
    var
        ReportSelections: Record "Report Selections";
    begin
        LibrarySetupStorage.Restore;
        if isInitialized then
            exit;
        isInitialized := true;

        LibraryERM.SetupReportSelection(ReportSelections.Usage::"S.Test", REPORT::"Sales Document - Test");
        LibraryERM.SetupReportSelection(ReportSelections.Usage::"P.Test", REPORT::"Purchase Document - Test");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        Commit;
    end;

    local procedure CreateSalesTaxVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        if not VATPostingSetup.Get('', '') then
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, '', '');
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Sales Tax");
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateCurrencyWithExchangeRate(): Code[10]
    var
        ExchangeRateAmount: Decimal;
    begin
        ExchangeRateAmount := LibraryRandom.RandDecInRange(10, 20, 2);
        exit(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate, ExchangeRateAmount, ExchangeRateAmount));
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account"; VATProdPostingGroup: Code[20]; TaxGroupCode: Code[20])
    var
        GenPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.FindGeneralPostingSetup(GenPostingSetup);

        with GLAccount do begin
            Validate("Gen. Bus. Posting Group", GenPostingSetup."Gen. Bus. Posting Group");
            Validate("Gen. Prod. Posting Group", GenPostingSetup."Gen. Prod. Posting Group");
            Validate("VAT Prod. Posting Group", VATProdPostingGroup);
            Validate("Tax Group Code", TaxGroupCode);
            Modify(true);
        end;
    end;

    local procedure CreateJobAndTask(var Job: Record Job; var JobTask: Record "Job Task"; CurrencyCode: Code[10])
    begin
        LibraryJob.CreateJob(Job);
        Job.Validate("Currency Code", CurrencyCode);
        Job.Modify(true);

        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateJobPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; TaxGroupCode: Code[20]; TaxAreaCode: Code[20]; Quantity: Decimal; UnitCost: Decimal; CurrencyCode: Code[10])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateVATPostingSetupForSalesTax(VATPostingSetup);
        CreateJobPurchaseHeader(PurchaseHeader, VATPostingSetup, TaxAreaCode);
        CreateJobPurchaseLine(PurchaseLine, PurchaseHeader, VATPostingSetup."VAT Prod. Posting Group", TaxGroupCode, Quantity, UnitCost, CurrencyCode);
    end;

    local procedure CreateJobPurchaseOrderInForeignCurrency(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; TaxGroupCode: Code[20]; TaxAreaCode: Code[20]; Quantity: Decimal; UnitCost: Decimal)
    begin
        CreateJobPurchaseOrder(
          PurchaseHeader, PurchaseLine, TaxGroupCode, TaxAreaCode, Quantity, UnitCost, CreateCurrencyWithExchangeRate);
    end;

    local procedure CreateJobPurchaseOrderInLocalCurrency(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; TaxGroupCode: Code[20]; TaxAreaCode: Code[20]; Quantity: Decimal; UnitCost: Decimal)
    begin
        CreateJobPurchaseOrder(PurchaseHeader, PurchaseLine, TaxGroupCode, TaxAreaCode, Quantity, UnitCost, '');
    end;

    local procedure CreateJobPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"; TaxAreaCode: Code[20])
    var
        Vendor: Record Vendor;
    begin
        CreateVendor(Vendor, VATPostingSetup, TaxAreaCode);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
    end;

    local procedure CreateJobPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; VATProdPostingGroupCode: Code[20]; TaxGroupCode: Code[20]; Quantity: Decimal; UnitCost: Decimal; CurrencyCode: Code[10])
    var
        GLAccount: Record "G/L Account";
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        CreateGLAccount(GLAccount, VATProdPostingGroupCode, TaxGroupCode);
        CreateJobAndTask(Job, JobTask, CurrencyCode);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", Quantity);
        with PurchaseLine do begin
            Validate("Direct Unit Cost", UnitCost);
            Validate("Job No.", Job."No.");
            Validate("Job Task No.", JobTask."Job Task No.");
            Validate("Job Line Type", "Job Line Type"::"Both Budget and Billable");
            Validate("Job Unit Price", UnitCost + LibraryRandom.RandDec(Round(UnitCost, 1), 2));
            Modify(true);
        end;
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        CreateVATPostingSetupForSalesTax(VATPostingSetup);
        CreateJobPurchaseHeader(PurchaseHeader, VATPostingSetup, TaxAreaCode);
        CreateGLAccount(GLAccount, VATPostingSetup."VAT Prod. Posting Group", TaxGroupCode);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesTaxSetup(var TaxArea: Record "Tax Area"; var TaxGroup: Record "Tax Group")
    begin
        LibraryERM.CreateTaxGroup(TaxGroup);
        LibraryERM.CreateTaxArea(TaxArea);
    end;

    local procedure CreateSalesTaxSetupWithTaxExpenseJurisdiction(var TaxArea: Record "Tax Area"; var TaxGroup: Record "Tax Group")
    begin
        CreateSalesTaxSetup(TaxArea, TaxGroup);
        CreateTaxJurisdiction(TaxArea.Code, TaxGroup.Code, true);
    end;

    local procedure CreateTaxDetail(var TaxDetail: Record "Tax Detail"; TaxJurisdictionCode: Code[10]; TaxGroupCode: Code[20]; SalesTaxRate: Decimal; ExpenseTax: Boolean)
    begin
        LibraryERM.CreateTaxDetail(TaxDetail, TaxJurisdictionCode, TaxGroupCode, TaxDetail."Tax Type"::"Sales and Use Tax", WorkDate);
        TaxDetail.Validate("Tax Below Maximum", SalesTaxRate);
        TaxDetail.Validate("Expense/Capitalize", ExpenseTax);
        TaxDetail.Modify(true);
    end;

    local procedure CreateTaxJurisdiction(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; ExpenseTax: Boolean)
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxAreaLine: Record "Tax Area Line";
        TaxDetail: Record "Tax Detail";
    begin
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxAreaCode, TaxJurisdiction.Code);
        CreateTaxDetail(TaxDetail, TaxAreaLine."Tax Jurisdiction Code", TaxGroupCode, LibraryRandom.RandIntInRange(5, 10), ExpenseTax);
    end;

    local procedure CreateVATPostingSetupForSalesTax(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup.Code, VATProdPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Sales Tax");
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor; VATPostingSetup: Record "VAT Posting Setup"; TaxAreaCode: Code[20])
    begin
        LibraryPurchase.CreateVendor(Vendor);

        with Vendor do begin
            Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
            Validate("Tax Liable", true);
            Validate("Tax Area Code", TaxAreaCode);
            Modify(true);
        end;
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesTaxVATPostingSetup(VATPostingSetup);

        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        SalesHeader.Validate("Tax Liable", true);
        SalesHeader.Validate("Tax Area Code", TaxAreaCode);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountNo, 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseLine: Record "Purchase Line";
    begin
        CreateSalesTaxVATPostingSetup(VATPostingSetup);

        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        PurchaseHeader.Validate("Tax Liable", true);
        PurchaseHeader.Validate("Tax Area Code", TaxAreaCode);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountNo, 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);
    end;

    local procedure PostPurchaseDocSaveLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseLine.Find;
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure TestReportPrintSalesDoc(var SalesHeader: Record "Sales Header")
    var
        TestReportPrint: Codeunit "Test Report-Print";
    begin
        Commit;
        TestReportPrint.PrintSalesHeader(SalesHeader);
    end;

    local procedure TestReportPrintPurchaseDoc(var PurchaseHeader: Record "Purchase Header")
    var
        TestReportPrint: Codeunit "Test Report-Print";
    begin
        Commit;
        TestReportPrint.PrintPurchHeader(PurchaseHeader);
    end;

    local procedure SetQuantityToReceive(var PurchaseLine: Record "Purchase Line"; Quantity: Decimal)
    begin
        PurchaseLine.Validate("Qty. to Receive", Quantity);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdatePurchaseSetup(NewUseVendorTaxAreaCode: Boolean): Boolean
    var
        PurchaseSetup: Record "Purchases & Payables Setup";
        OldUseVendorTaxAreaCode: Boolean;
    begin
        with PurchaseSetup do begin
            Get;
            OldUseVendorTaxAreaCode := "Use Vendor's Tax Area Code";
            Validate("Use Vendor's Tax Area Code", NewUseVendorTaxAreaCode);
            Modify(true);
        end;

        exit(OldUseVendorTaxAreaCode);
    end;

    local procedure VerifyJobLedgerEntry(PurchaseLine: Record "Purchase Line")
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        JobCurrFactor: Decimal;
    begin
        with JobLedgerEntry do begin
            SetRange("Job No.", PurchaseLine."Job No.");
            SetRange("Job Task No.", PurchaseLine."Job Task No.");
            SetRange(Type, Type::"G/L Account");
            SetRange("No.", PurchaseLine."No.");
            FindFirst;

            if PurchaseLine."Job Currency Code" <> '' then
                JobCurrFactor := PurchaseLine."Job Currency Factor"
            else
                JobCurrFactor := 1;

            Assert.AreNearlyEqual(
              PurchaseLine."Amount Including VAT" * JobCurrFactor, "Total Cost", 0.01, StrSubstNo(WrongAmountErr, FieldName("Total Cost"), TableName));
            Assert.AreEqual(
              PurchaseLine."Amount Including VAT", "Total Cost (LCY)", StrSubstNo(WrongAmountErr, FieldName("Total Cost (LCY)"), TableName));
        end;
    end;

    local procedure VerifySalesHeaderAmountInclVAT(SalesHeader: Record "Sales Header"; TaxGroupCode: Code[20])
    var
        TaxDetail: Record "Tax Detail";
    begin
        TaxDetail.SetRange("Tax Group Code", TaxGroupCode);
        TaxDetail.FindFirst;

        with SalesHeader do begin
            CalcFields(Amount, "Amount Including VAT");
            TestField("Amount Including VAT", Round(Amount * (1 + TaxDetail."Tax Below Maximum" / 100)));
        end;
    end;

    local procedure VerifyPurchaseHeaderAmountInclVAT(PurchaseHeader: Record "Purchase Header"; TaxGroupCode: Code[20])
    var
        TaxDetail: Record "Tax Detail";
    begin
        TaxDetail.SetRange("Tax Group Code", TaxGroupCode);
        TaxDetail.FindFirst;

        with PurchaseHeader do begin
            CalcFields(Amount, "Amount Including VAT");
            TestField("Amount Including VAT", Round(Amount * (1 + TaxDetail."Tax Below Maximum" / 100)));
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesDocumentTest_RPH(var SalesDocumentTest: TestRequestPage "Sales Document - Test")
    begin
        SalesDocumentTest.Cancel.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseDocumentTest_RPH(var PurchaseDocumentTest: TestRequestPage "Purchase Document - Test")
    begin
        PurchaseDocumentTest.Cancel.Invoke;
    end;
}

