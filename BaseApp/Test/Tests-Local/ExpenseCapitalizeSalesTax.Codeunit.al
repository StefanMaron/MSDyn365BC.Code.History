﻿codeunit 142091 "Expense/Capitalize Sales Tax"
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
        Initialize();
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
        Initialize();
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
        Initialize();
        UpdatePurchaseSetup(true);

        CreateSalesTaxSetupWithTaxExpenseJurisdiction(TaxArea, TaxGroup);
        CreateTaxJurisdictionWithTaxRate(TaxArea.Code, TaxGroup.Code, LibraryRandom.RandDecInRange(5, 10, 2), false);

        UnitAmount := LibraryRandom.RandDecInRange(100, 500, 2);
        CreateJobPurchaseOrderInLocalCurrency(
          PurchaseHeader, PurchaseLine, TaxGroup.Code, TaxArea.Code, LibraryRandom.RandIntInRange(2, 5), UnitAmount);
        SetQuantityToReceive(PurchaseLine, 1);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        with PurchaseLine do begin
            Find();
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
        Initialize();
        UpdatePurchaseSetup(true);

        // [GIVEN] Released Purchase Order with Expense Sales Tax, where "Tax To Be Expensed" = 100
        CreateSalesTaxSetupWithTaxExpenseJurisdiction(TaxArea, TaxGroup);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, TaxArea.Code, TaxGroup.Code, LibraryRandom.RandDec(100, 2));
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Tax is reset for Purchase Line
        ReleasePurchaseDocument.Reopen(PurchaseHeader);
        PurchaseLine.Find();
        PurchaseLine.Validate("Tax Liable", false);
        PurchaseLine.Validate("Tax Area Code", '');
        PurchaseLine.Validate("Tax Group Code", '');
        PurchaseLine.Modify(true);

        // [WHEN] Release Purchase Order
        ReleasePurchaseDocument.PerformManualRelease(PurchaseHeader);

        // [THEN] Purchase Line has "Tax To Be Expensed" is 0
        PurchaseLine.Find();
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
        Initialize();

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
        Initialize();

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
        Initialize();

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
        Initialize();

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
        Initialize();

        // [GIVEN] PurchasesPayablesSetup."Calc. Inv. Discount" = FALSE
        LibraryPurchase.SetCalcInvDiscount(false);

        // [GIVEN] Sales Tax setup with "Tax Below Maximum" = 10, "Expense/Capitalize" = TRUE
        CreateSalesTaxSetupWithTaxExpenseJurisdiction(TaxArea, TaxGroup);

        // [GIVEN] Purchase Invoice with "Direct Unit Cost" = 1000
        CreatePurchaseInvoice(PurchaseHeader, TaxArea.Code, TaxGroup.Code, true);

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
        Initialize();

        // [GIVEN] PurchasesPayablesSetup."Calc. Inv. Discount" = TRUE
        LibraryPurchase.SetCalcInvDiscount(true);

        // [GIVEN] Sales Tax setup with "Tax Below Maximum" = 10, "Expense/Capitalize" = TRUE
        CreateSalesTaxSetupWithTaxExpenseJurisdiction(TaxArea, TaxGroup);

        // [GIVEN] Purchase Invoice with "Direct Unit Cost" = 1000
        CreatePurchaseInvoice(PurchaseHeader, TaxArea.Code, TaxGroup.Code, true);

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
        Initialize();

        // [GIVEN] PurchasesPayablesSetup."Calc. Inv. Discount" = FALSE
        LibraryPurchase.SetCalcInvDiscount(false);

        // [GIVEN] Sales Tax setup with "Tax Below Maximum" = 10, "Expense/Capitalize" = TRUE
        CreateSalesTaxSetupWithTaxExpenseJurisdiction(TaxArea, TaxGroup);

        // [GIVEN] Purchase Invoice with "Direct Unit Cost" = 1000
        CreatePurchaseInvoice(PurchaseHeader, TaxArea.Code, TaxGroup.Code, true);

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
        Initialize();

        // [GIVEN] PurchasesPayablesSetup."Calc. Inv. Discount" = TRUE
        LibraryPurchase.SetCalcInvDiscount(true);

        // [GIVEN] Sales Tax setup with "Tax Below Maximum" = 10, "Expense/Capitalize" = TRUE
        CreateSalesTaxSetupWithTaxExpenseJurisdiction(TaxArea, TaxGroup);

        // [GIVEN] Purchase Invoice with "Direct Unit Cost" = 1000
        CreatePurchaseInvoice(PurchaseHeader, TaxArea.Code, TaxGroup.Code, true);

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
        Initialize();

        // [GIVEN] Sales Tax setup with "Tax Below Maximum" = 10, "Expense/Capitalize" = TRUE
        CreateSalesTaxSetupWithTaxExpenseJurisdiction(TaxArea, TaxGroup);

        // [GIVEN] Purchase Invoice of one line with "Direct Unit Cost" = 1000
        CreatePurchaseInvoice(PurchaseHeader, TaxArea.Code, TaxGroup.Code, true);

        // [GIVEN] "Tax To Be Expensed" is equal to 100
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
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

    [Test]
    [Scope('OnPrem')]
    procedure PostingPurchaseDocumentWithExpenseWithoutTaxLiable()
    var
        GLEntry: Record "G/L Entry";
        PurchaseHeader: Record "Purchase Header";
        TaxArea: Record "Tax Area";
        TaxGroup: Record "Tax Group";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 348878] It is possible to post Purchase document with "Expense/Capitalize" = TRUE, non-zero "Tax Below Maximum", "Tax Liable" = FALSE.
        Initialize();

        // [GIVEN] Sales Tax setup with "Tax Below Maximum" = 10, "Expense/Capitalize" = TRUE.
        CreateSalesTaxSetupWithTaxExpenseJurisdiction(TaxArea, TaxGroup);

        // [GIVEN] Purchase Document of one line with "Direct Unit Cost" = 1000, "Tax Liable" = FALSE.
        CreatePurchaseInvoice(PurchaseHeader, TaxArea.Code, TaxGroup.Code, false);

        // [WHEN] Purchase Document is posted.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Posting is successful.
        GLEntry.SetRange("External Document No.", PurchaseHeader."Vendor Invoice No.");
        Assert.RecordCount(GLEntry, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseAmtRcdNotInvExVATCalculationWhenTaxMinus100Pct()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TaxArea: Record "Tax Area";
        TaxGroup: Record "Tax Group";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
        VendorPostingGroup: Record "Vendor Posting Group";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        GLAccountNo: array[2] of Code[20];
        PostedDocNo: Code[20];
        TaxJurisdictionCode: Code[10];
        DirectUnitCost: array[2] of Decimal;
        Amount: array[2] of Decimal;
        TaxRate1: Decimal;
        TaxRate2: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 351503] Calculation of "A. Rcd. Not Inv. Ex. VAT (LCY)" for Purchase Line in case ("VAT %" - Expense Tax) = -100 for this line.
        Initialize();
        UpdatePurchaseSetup(true);
        CreateSalesTaxVATPostingSetup(VATPostingSetup);

        // [GIVEN] Tax Area with two lines. Tax Jurisdiction "GST" is set for the first line and has "Tax Below Maximum" = 5%, "Expense/Capitalize" = FALSE.
        // [GIVEN] Tax Jurisdiction "PST" is set for the second line and has "Tax Below Maximum" = 7%, "Expense/Capitalize" = TRUE.
        // [GIVEN] Both Tax Jurisdictions have Details with Tax Group.
        TaxRate1 := 0.05;
        TaxRate2 := 0.07;
        CreateSalesTaxSetup(TaxArea, TaxGroup);
        TaxJurisdictionCode := CreateTaxJurisdictionWithTaxRate(TaxArea.Code, TaxGroup.Code, TaxRate1 * 100, false);
        CreateTaxJurisdictionWithTaxRate(TaxArea.Code, TaxGroup.Code, TaxRate2 * 100, true);

        // [GIVEN] Purchase Order with two lines, G/L Accounts "G1" and "G2" are set for both lines.
        // [GIVEN] First Purchase Line has Quantity = 3, "Direct Unit Cost" = 150. Second Purchase Line has Quantity = 30.
        CreateVATPostingSetupForSalesTax(VATPostingSetup);
        CreateVendor(Vendor, VATPostingSetup, TaxArea.Code);
        GLAccountNo[1] := CreateGLAccountNo(VATPostingSetup."VAT Prod. Posting Group", TaxGroup.Code);
        GLAccountNo[2] := CreateGLAccountNo(VATPostingSetup."VAT Prod. Posting Group", TaxGroup.Code);
        DirectUnitCost[1] := 150;
        DirectUnitCost[2] := 1;
        Amount[1] := 3 * 150;
        Amount[2] := 30 * 1;

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo[1], 3);
        UpdateDirectUnitCostOnPurchaseLine(PurchaseLine, DirectUnitCost[1]);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo[2], 30);

        // [WHEN] Set "Direct Unit Cost" = 1 for the second Purchase Line.
        UpdateDirectUnitCostOnPurchaseLine(PurchaseLine, DirectUnitCost[2]);

        // [THEN] "Direct Unit Cost" was set to 1; "A. Rcd. Not Inv. Ex. VAT (LCY)" = 0, because "Amt. Rcd. Not Invoiced" = 0.
        PurchaseLine.TestField("Direct Unit Cost", DirectUnitCost[2]);
        PurchaseLine.TestField("Amt. Rcd. Not Invoiced", 0);
        PurchaseLine.TestField("A. Rcd. Not Inv. Ex. VAT (LCY)", 0);

        // [THEN] Purchase Invoice can be posted. Four G/L Entries and one VAT entry are created.
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        GLEntry.SetRange("Document No.", PostedDocNo);
        VATEntry.SetRange("Document No.", PostedDocNo);
        Assert.RecordCount(GLEntry, 4);
        Assert.RecordCount(VATEntry, 1);

        // [THEN] Two G/L Entries are created for G/L Accounts "G1"/"G2" and included "PST" taxes; "G1" Amount = 450 + (450 * 0.07); "G2" Amount = 30 + (30 * 0.07).
        // [THEN] One G/L Entry is created for Tax Account from Tax Jurisdiction "GST"; Amount = (450 + 30) * 0.05.
        // [THEN] One G/L Entry is created for Payables Account from Vendor Posting Group; Amount = -(450 + 30) * (1 + 0.05 + 0.07).
        // [THEN] VAT Entry with Amount = (450 + 30) * 0.05.
        TaxJurisdiction.Get(TaxJurisdictionCode);
        VendorPostingGroup.Get(PurchaseHeader."Vendor Posting Group");
        VerifyGLEntry(PostedDocNo, GLAccountNo[1], Amount[1] * (1 + TaxRate2));
        VerifyGLEntry(PostedDocNo, GLAccountNo[2], Amount[2] * (1 + TaxRate2));
        VerifyGLEntry(PostedDocNo, TaxJurisdiction."Tax Account (Purchases)", (Amount[1] + Amount[2]) * TaxRate1);
        VerifyGLEntry(
          PostedDocNo, VendorPostingGroup."Payables Account", -(Amount[1] + Amount[2]) * (1 + TaxRate1 + TaxRate2));
        VerifyVATEntry(PostedDocNo, TaxJurisdictionCode, (Amount[1] + Amount[2]) * TaxRate1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseDocTaxToBeExpensedForSecondLine()
    var
        TaxArea: Record "Tax Area";
        TaxGroup: Record "Tax Group";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
    begin
        // [SCENARIO 360864] Adding second line to the purchase order with expense tax
        Initialize();

        // [GIVEN] Tax detailes for two tax jurisdicstions, 5% no expense, 7% with expense
        CreateSalesTaxSetup(TaxArea, TaxGroup);
        CreateTaxJurisdictionWithTaxRate(TaxArea.Code, TaxGroup.Code, LibraryRandom.RandIntInRange(5, 10), false);
        CreateTaxJurisdictionWithTaxRate(TaxArea.Code, TaxGroup.Code, LibraryRandom.RandIntInRange(5, 10), true);

        // [GIVEN] Purchase order with the line of Amount = 100, Amount Including VAT = 112, Tax To Be Expensed = 7
        UpdatePurchaseSetup(true);
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseLine1, TaxArea.Code, TaxGroup.Code, LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Second line with the same No and Quantity is added to the purhase order
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine2, PurchaseHeader, PurchaseLine1.Type, PurchaseLine1."No.", PurchaseLine1.Quantity);

        // [WHEN] Update 'Direct Unit Cost' to the same value as in first line
        PurchaseLine2.Validate("Direct Unit Cost", PurchaseLine1."Direct Unit Cost");

        // [THEN] New line has the same Amount = 100, Amount Including VAT = 112, Tax To Be Expensed = 7
        PurchaseLine2.TestField(Amount, PurchaseLine1.Amount);
        PurchaseLine2.TestField("Amount Including VAT", PurchaseLine1."Amount Including VAT");
        PurchaseLine2.TestField("Tax To Be Expensed", PurchaseLine1."Tax To Be Expensed");
    end;

    local procedure Initialize()
    var
        ReportSelections: Record "Report Selections";
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.DeleteAll();
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;
        isInitialized := true;

        CreateVATPostingSetupWithBlankBusProdGroupCodes();
        LibraryERM.SetupReportSelection(ReportSelections.Usage::"S.Test", REPORT::"Sales Document - Test");
        LibraryERM.SetupReportSelection(ReportSelections.Usage::"P.Test", REPORT::"Purchase Document - Test");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        Commit();
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
        exit(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchangeRateAmount, ExchangeRateAmount));
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

    local procedure CreateGLAccountNo(VATProdPostingGroup: Code[20]; TaxGroupCode: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        CreateGLAccount(GLAccount, VATProdPostingGroup, TaxGroupCode);
        exit(GLAccount."No.");
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

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; DirectUnitCost: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        CreateVATPostingSetupForSalesTax(VATPostingSetup);
        CreateJobPurchaseHeader(PurchaseHeader, VATPostingSetup, TaxAreaCode);
        CreateGLAccount(GLAccount, VATPostingSetup."VAT Prod. Posting Group", TaxGroupCode);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
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
        CreateTaxJurisdictionWithTaxRate(TaxArea.Code, TaxGroup.Code, LibraryRandom.RandDecInRange(5, 10, 2), true);
    end;

    local procedure CreateTaxDetail(var TaxDetail: Record "Tax Detail"; TaxJurisdictionCode: Code[10]; TaxGroupCode: Code[20]; SalesTaxRate: Decimal; ExpenseTax: Boolean)
    begin
        LibraryERM.CreateTaxDetail(TaxDetail, TaxJurisdictionCode, TaxGroupCode, TaxDetail."Tax Type"::"Sales and Use Tax", WorkDate());
        TaxDetail.Validate("Tax Below Maximum", SalesTaxRate);
        TaxDetail.Validate("Expense/Capitalize", ExpenseTax);
        TaxDetail.Modify(true);
    end;

    local procedure CreateTaxJurisdictionWithTaxRate(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; SalesTaxRate: Decimal; ExpenseTax: Boolean): Code[10]
    var
        GLAccount: Record "G/L Account";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxAreaLine: Record "Tax Area Line";
        TaxDetail: Record "Tax Detail";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        TaxJurisdiction.Validate("Tax Account (Sales)", GLAccount."No.");
        TaxJurisdiction.Validate("Tax Account (Purchases)", GLAccount."No.");
        TaxJurisdiction.Modify(true);

        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxAreaCode, TaxJurisdiction.Code);
        CreateTaxDetail(TaxDetail, TaxAreaLine."Tax Jurisdiction Code", TaxGroupCode, SalesTaxRate, ExpenseTax);
        exit(TaxJurisdiction.Code);
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

    local procedure CreateVATPostingSetupWithBlankBusProdGroupCodes()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("VAT Bus. Posting Group", '');
        VATPostingSetup.SetRange("VAT Prod. Posting Group", '');
        VATPostingSetup.DeleteAll();

        LibraryERM.CreateVATPostingSetup(VATPostingSetup, '', '');
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

    local procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxLiable: Boolean)
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseLine: Record "Purchase Line";
    begin
        CreateSalesTaxVATPostingSetup(VATPostingSetup);

        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        PurchaseHeader.Validate("Tax Liable", TaxLiable);
        PurchaseHeader.Validate("Tax Area Code", TaxAreaCode);
        PurchaseHeader.Modify(true);

        CreateGLAccount(GLAccount, VATPostingSetup."VAT Prod. Posting Group", TaxGroupCode);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          GLAccount."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);
    end;

    local procedure PostPurchaseDocSaveLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseLine.Find();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure TestReportPrintSalesDoc(var SalesHeader: Record "Sales Header")
    var
        TestReportPrint: Codeunit "Test Report-Print";
    begin
        Commit();
        TestReportPrint.PrintSalesHeader(SalesHeader);
    end;

    local procedure TestReportPrintPurchaseDoc(var PurchaseHeader: Record "Purchase Header")
    var
        TestReportPrint: Codeunit "Test Report-Print";
    begin
        Commit();
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
            Get();
            OldUseVendorTaxAreaCode := "Use Vendor's Tax Area Code";
            Validate("Use Vendor's Tax Area Code", NewUseVendorTaxAreaCode);
            Modify(true);
        end;

        exit(OldUseVendorTaxAreaCode);
    end;

    local procedure UpdateDirectUnitCostOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; DirectUnitCost: Decimal)
    begin
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
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
            FindFirst();

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
        TaxDetail.FindFirst();

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
        TaxDetail.FindFirst();

        with PurchaseHeader do begin
            CalcFields(Amount, "Amount Including VAT");
            TestField("Amount Including VAT", Round(Amount * (1 + TaxDetail."Tax Below Maximum" / 100)));
        end;
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, ExpectedAmount);
        end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; TaxJurisdictionCode: Code[10]; ExpectedAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Tax Jurisdiction Code", TaxJurisdictionCode);
        VATEntry.FindFirst();
        VATEntry.TestField(Amount, ExpectedAmount);
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

