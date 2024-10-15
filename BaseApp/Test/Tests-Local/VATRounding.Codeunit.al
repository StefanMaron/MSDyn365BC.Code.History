codeunit 144000 "VAT Rounding"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;
        WrongAmtInclVATInCrMemoErr: Label 'Wrong total amount including VAT in Credit Memo %1.';
        NonZeroCustLedgEntryErr: Label 'Expected Customer Ledger Entry with Amount = 0.';

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWith100PctInvDiscount()
    var
        Customer: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        SalesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        LineNo: Integer;
        PostedDocNo: Code[20];
    begin
        // [SCENARIO 360140] Sales Invoice with 100 percent invoice discount.
        Initialize;

        // [GIVEN] Sales Setup: Calculate all discounts.
        SalesSetup.Get;
        SalesSetup.Validate("Calc. Inv. Discount", true);
        SalesSetup."Discount Posting" := SalesSetup."Discount Posting"::"All Discounts";
        SalesSetup.Modify(true);

        // [GIVEN] Customer has Invoice Discount = 100 pct.
        LibrarySales.CreateCustomer(Customer);
        SetInvoiceDiscountForCustomer(Customer."No.", 100);

        // [GIVEN] Create Sales Invoice with more than 1 line with an amount to be rounded up (0.04)
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        for LineNo := 1 to 2 do
            CreateFixedSalesLine(SalesHeader, 1, 0.04, 0);

        // [WHEN] Post Sales Invoice
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Posted Customer Ledger Entry amount is 0
        CustLedgEntry.SetRange("Document No.", PostedDocNo);
        CustLedgEntry.FindLast;
        CustLedgEntry.CalcFields(Amount);
        Assert.AreEqual(0, CustLedgEntry.Amount, NonZeroCustLedgEntryErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesOrderApplyInvRoundAmtToVATTest()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Check that Amounts in Sales Order Statistics are correct when using "Apply Inv. Round Amt. to VAT" option.

        // 1. Setup
        Initialize;
        UpdateGLSetup(0.05, 0);
        UpdateSalesSetup(true);

        // 2. Exercise
        CreateReleaseSalesOrder(SalesHeader);

        // 3. Verify
        VerifyVATAmountsInSalesOrder(SalesHeader, 80.63, 6.12, 86.75); // ExpectedVATBase, ExpectedVATAmount, ExpectedAmtInclVAT
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesOrderDoNotApplyInvRoundAmtToVATTest()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Check that Amounts in Sales Order Statistics are correct when using "Apply Inv. Round Amt. to VAT" option.

        // 1. Setup
        Initialize;
        // Inv. Rounding Precision (LCY), Appln. Rounding Precision, Apply Inv. Round. Amt. To VAT
        UpdateGLSetup(0.05, 0);
        UpdateSalesSetup(false);

        // 2. Exercise
        CreateReleaseSalesOrder(SalesHeader);

        // 3. Verify
        VerifyVATAmountsInSalesOrder(SalesHeader, 80.63, 6.13, 86.76);  // ExpectedVATBase, ExpectedVATAmount, ExpectedAmtInclVAT
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostCreditMemoApplyInvRoundAmtToVATTest()
    var
        InvNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // Check that Credit Memo which is created as a Copy from Sales Order was successfully posted with correct Amount Incl. VAT

        // 1. Setup
        Initialize;
        // Inv. Rounding Precision (LCY), Appln. Rounding Precision, Apply Inv. Round. Amt. To VAT
        UpdateSalesSetup(true);

        // 2. Exercise
        InvNo := CreatePostSalesOrder;
        CrMemoNo := CreatePostSalesCrMemoByCopyDocument(InvNo);

        // 3. Verify
        VerifyAmountsInPostedSalesCrMemo(CrMemoNo, 10.75); // LineDiscount
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPrepaymentInvoiceApplyInvRoundAmtToVATTest()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        RoundingPrecision: Decimal;
        PrepaymentPercent: Integer;
        Quantity: Integer;
        Price: Decimal;
    begin
        // 1. Setup
        Initialize;

        RoundingPrecision := LibraryRandom.RandDecInDecimalRange(0.01, 0.9, 2);
        UpdateGLSetup(RoundingPrecision, 0);
        UpdateSalesSetup(true);

        // 2. Exercise
        PrepaymentPercent := LibraryRandom.RandInt(100);
        Quantity := LibraryRandom.RandInt(10);
        Price := LibraryRandom.RandDecInDecimalRange(0, 1000, 2);
        CratePostSalesPrepaymentInvoice(SalesHeader, PrepaymentPercent, Quantity, Price); // PrepaymentPercent, Quantity, Price

        // 3. Verify
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesInvoiceHeader.SetRange("External Document No.", SalesHeader."External Document No.");
        SalesInvoiceHeader.SetAutoCalcFields(Amount);
        SalesInvoiceHeader.FindFirst;

        Assert.AreEqual(1, SalesInvoiceHeader.Count, 'There should be one sales invoice.');
        Assert.AreEqual(Round(Quantity * Price * PrepaymentPercent / 100, RoundingPrecision), SalesInvoiceHeader.Amount, 'Wrong amount.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceApplnRoundingPrecisionApplyInvRoundAmtToVATTest()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
        InvRoundPrecision: Decimal;
        ApplnRoundingPrecision: Decimal;
        UnitPrice: Decimal;
        ExpectedAmount: Decimal;
        ApplyInvRoundAmtToVAT: Boolean;
        Quantity: Integer;
    begin
        // 1. Setup
        Initialize;

        InvRoundPrecision := LibraryRandom.RandDecInDecimalRange(0.01, 0.9, 2);
        ApplnRoundingPrecision := LibraryRandom.RandDecInDecimalRange(0.01, 0.9, 2);
        ApplyInvRoundAmtToVAT := true;

        UpdateGLSetup(InvRoundPrecision, ApplnRoundingPrecision);
        UpdateSalesSetup(ApplyInvRoundAmtToVAT);

        // 2. Exercise
        // Crate and post sales invoice
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Prices Including VAT", true);
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        Quantity := LibraryRandom.RandInt(10);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem, Quantity);
        UnitPrice := LibraryRandom.RandDecInDecimalRange(0, 1000, 2);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);

        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // 3. Verify
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesInvoiceHeader.SetRange("External Document No.", SalesHeader."External Document No.");
        SalesInvoiceHeader.SetAutoCalcFields(Amount);
        SalesInvoiceHeader.FindFirst;

        Assert.AreEqual(1, SalesInvoiceHeader.Count, 'There should be one sales invoice.');

        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        Assert.AreEqual(1, SalesInvoiceLine.Count, 'There should be one sales line.');

        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");

        ExpectedAmount := Round(Quantity * UnitPrice / (VATPostingSetup."VAT %" / 100 + 1));
        Assert.AreEqual(ExpectedAmount, SalesInvoiceHeader.Amount, 'Wrong amount.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceDoNotApplyInvRoundAmtToVATTest()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        ExpectedAmount: Decimal;
    begin
        // 1. Setup
        Initialize;

        UpdateGLSetup(LibraryRandom.RandDecInDecimalRange(0.01, 0.9, 2), 0);
        UpdateSalesSetup(false);

        // 2. Exercise
        CratePostSalesInvoice(SalesHeader, LibraryRandom.RandInt(10), LibraryRandom.RandInt(1000)); // Quantity, Price

        // 3. Verify
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesInvoiceHeader.SetRange("External Document No.", SalesHeader."External Document No.");
        SalesInvoiceHeader.SetAutoCalcFields(Amount);
        SalesInvoiceHeader.FindFirst;

        Assert.AreEqual(1, SalesInvoiceHeader.Count, 'There should be one sales invoice.');

        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        Assert.AreEqual(2, SalesInvoiceLine.Count, 'There should be one sales line.');

        SalesInvoiceLine.FindSet;
        ExpectedAmount += SalesInvoiceLine.Amount;
        SalesInvoiceLine.Next;
        ExpectedAmount += SalesInvoiceLine.Amount;

        Assert.AreEqual(ExpectedAmount, SalesInvoiceHeader.Amount, 'Wrong amount.');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"VAT Rounding");
        LibrarySetupStorage.Restore;

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"VAT Rounding");

        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        isInitialized := true;
        Commit;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"VAT Rounding");
    end;

    local procedure UpdateGLSetup(NewInvRoundPrecision: Decimal; NewApplnRoundingPrecision: Decimal)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get;
        if NewInvRoundPrecision <> 0 then
            GLSetup.Validate("Inv. Rounding Precision (LCY)", NewInvRoundPrecision);
        if NewApplnRoundingPrecision <> 0 then
            GLSetup.Validate("Appln. Rounding Precision", NewApplnRoundingPrecision);
        GLSetup.Modify(true);
    end;

    local procedure UpdateSalesSetup(NewApplyInvRoundAmtToVAT: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get;
        SalesReceivablesSetup.Validate("Apply Inv. Round. Amt. To VAT", NewApplyInvRoundAmtToVAT);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        exit(Item."No.");
    end;

    local procedure CreateReleaseSalesOrder(var SalesHeader: Record "Sales Header")
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify(true);
        CreateFixedSalesLine(SalesHeader, 1, 50, 10);
        CreateFixedSalesLine(SalesHeader, 1, 18, 0);
        CreateFixedSalesLine(SalesHeader, 1, 11.9, 10);
        CreateFixedSalesLine(SalesHeader, 1, 14.5, 10);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreatePostSalesOrder(): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateFixedSalesLineWithQtyToInvoice(SalesHeader, 10, 10, 9);
        CreateFixedSalesLine(SalesHeader, 1, 1000, 0);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true)); // posting the last piece of the first line
    end;

    local procedure CratePostSalesPrepaymentInvoice(var SalesHeader: Record "Sales Header"; PrepaymentPercent: Integer; Quantity: Integer; Price: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader."Prepayment %" := PrepaymentPercent;
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem, Quantity);
        SalesLine.Validate("Unit Price", Price);
        SalesLine.Modify(true);

        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        LibrarySales.PostSalesDocument(SalesHeader, true, false)
    end;

    local procedure CratePostSalesInvoice(var SalesHeader: Record "Sales Header"; Quantity: Integer; Price: Decimal): Code[20]
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", Price);
        Item.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePostSalesCrMemoByCopyDocument(CopyFromDocNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        DocumentType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Shipment","Posted Invoice","Posted Return Receipt","Posted Credit Memo";
    begin
        SalesHeader.Init;
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.Insert(true);
        LibrarySales.CopySalesDocument(SalesHeader, DocumentType::"Posted Invoice", CopyFromDocNo, true, false);
        SalesHeader.Find;
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateFixedSalesLineWithQtyToInvoice(SalesHeader: Record "Sales Header"; Quantity: Decimal; UnitPrice: Decimal; QtyToInvoice: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateFixedSalesLine(SalesHeader, Quantity, UnitPrice, 0);
        FindLastSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Qty. to Invoice", QtyToInvoice);
        SalesLine.Modify(true);
    end;

    local procedure CreateFixedSalesLine(SalesHeader: Record "Sales Header"; Quantity: Decimal; UnitPrice: Decimal; LineDiscount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem, Quantity);
        SetFixedVATPctInSetupBySalesLine(SalesLine);
        SalesLine.Validate("VAT Prod. Posting Group", SalesLine."VAT Prod. Posting Group");
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Line Discount %", LineDiscount);
        SalesLine.Modify(true);
    end;

    local procedure FindLastSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        with SalesLine do begin
            SetRange("Document Type", SalesHeader."Document Type");
            SetRange("Document No.", SalesHeader."No.");
            FindLast;
        end;
    end;

    local procedure SetFixedVATPctInSetupBySalesLine(SalesLine: Record "Sales Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        VATPostingSetup.Validate("VAT %", 7.6);
        VATPostingSetup.Modify(true);
    end;

    local procedure SetInvoiceDiscountForCustomer(CustomerNo: Code[20]; DiscountPct: Decimal)
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CustomerNo, '', 0);
        CustInvoiceDisc.Validate("Discount %", DiscountPct);
        CustInvoiceDisc.Modify(true);
    end;

    local procedure VerifyVATAmountsInSalesOrder(SalesHeader: Record "Sales Header"; ExpectedVATBase: Decimal; ExpectedVATAmount: Decimal; ExpectedAmtInclVAT: Decimal)
    begin
        VerifyAmountsInSalesHeader(SalesHeader, ExpectedVATBase, ExpectedAmtInclVAT);
        VerifyAmountsInVATAmountLine(SalesHeader, ExpectedVATBase, ExpectedVATAmount, ExpectedAmtInclVAT);
    end;

    local procedure VerifyAmountsInSalesHeader(SalesHeader: Record "Sales Header"; ExpectedVATBase: Decimal; ExpectedAmtInclVAT: Decimal)
    begin
        SalesHeader.CalcFields(Amount, "Amount Including VAT");
        SalesHeader.TestField(Amount, ExpectedVATBase);
        SalesHeader.TestField("Amount Including VAT", ExpectedAmtInclVAT);
    end;

    local procedure VerifyAmountsInPostedSalesCrMemo(DocNo: Code[20]; ExpectedAmtInclVAT: Decimal)
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        AmtInclVAT: Decimal;
    begin
        with SalesCrMemoLine do begin
            SetRange("Document No.", DocNo);
            FindSet;
            repeat
                AmtInclVAT += "Amount Including VAT";
            until Next = 0;
            Assert.AreEqual(ExpectedAmtInclVAT, AmtInclVAT, StrSubstNo(WrongAmtInclVATInCrMemoErr, DocNo));
        end;
    end;

    local procedure VerifyAmountsInVATAmountLine(SalesHeader: Record "Sales Header"; ExpectedVATBase: Decimal; ExpectedVATAmount: Decimal; ExpectedAmtInclVAT: Decimal)
    var
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line" temporary;
    begin
        SalesLine.CalcVATAmountLines(0, SalesHeader, SalesLine, VATAmountLine);
        with VATAmountLine do begin
            TestField("VAT Base", ExpectedVATBase);
            TestField("VAT Amount", ExpectedVATAmount);
            TestField("Amount Including VAT", ExpectedAmtInclVAT);
        end;
    end;
}

