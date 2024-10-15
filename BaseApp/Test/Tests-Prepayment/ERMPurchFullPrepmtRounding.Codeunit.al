﻿codeunit 134109 "ERM Purch Full Prepmt Rounding"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Prepayment] [Rounding] [Purchase]
        IsInitialized := false;
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        CannotBeLessThanMsg: Label 'cannot be less than %1', Comment = '.';
        CannotBeMoreThanMsg: Label 'cannot be more than %1', Comment = '.';
        DirectCostModifyMsg: Label 'must be %1 when the Prepayment Invoice has already been posted', Comment = 'starts with a field name; %1 - numeric value';

    [Test]
    [Scope('OnPrem')]
    procedure RecAllPartiallyGetRcptsToInv()
    var
        PurchOrderHeader: Record "Purchase Header";
        PurchInvoiceHeader: Record "Purchase Header";
        PurchOrderLine: Record "Purchase Line";
        i: Integer;
    begin
        Initialize();
        PurchOrderHeader."Prices Including VAT" := false;
        PreparePurchOrder(PurchOrderHeader);
        AddSpecificOrderLine100PctPrepmt(PurchOrderLine, PurchOrderHeader);
        PostPurchPrepmtInvoice(PurchOrderHeader);

        PurchInvoiceHeader."Buy-from Vendor No." := PurchOrderHeader."Buy-from Vendor No.";
        CreatePurchInvoice(PurchInvoiceHeader, PurchOrderHeader."Prices Including VAT");

        for i := 1 to 3 do begin
            UpdateQtysInLine(PurchOrderLine, 2, 0);
            PurchOrderHeader.Find();
            LibraryPurchase.PostPurchaseDocument(PurchOrderHeader, true, false);
            GetReceiptLine(PurchInvoiceHeader, PurchOrderHeader."Last Receiving No.");
        end;

        PurchOrderHeader.Find();
        LibraryPurchase.PostPurchaseDocument(PurchOrderHeader, true, false);
        GetReceiptLine(PurchInvoiceHeader, PurchOrderHeader."Last Receiving No.");

        LibraryPurchase.PostPurchaseDocument(PurchInvoiceHeader, false, true);
        VerifyZeroVendorAccEntry();

        PurchOrderLine.Find();
        Assert.AreEqual(
          PurchOrderLine."Prepmt. Amt. Inv.",
          PurchOrderLine."Prepmt Amt Deducted", '"Prepmt Amt Deducted" should be equal to "Prepmt. Amt. Inv.".');
    end;

    local procedure AddSpecificOrderLine100PctPrepmt(var PurchLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        // Magic numbers from original repro steps Bug 332246
        AddPurchOrderLine(PurchLine, PurchaseHeader, 19.625, 1192, 100, 0);
        PurchLine.Validate("Line Amount", 16559.33);
        PurchLine.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FinalInvAfterRemoteInvPosExclVAT()
    begin
        FinalInvAfterRemoteInv(false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FinalInvAfterRemoteInvNegExclVAT()
    begin
        FinalInvAfterRemoteInv(false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FinalInvAfterRemoteInvPosInclVAT()
    begin
        FinalInvAfterRemoteInv(true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FinalInvAfterRemoteInvNegInclVAT()
    begin
        FinalInvAfterRemoteInv(true, false);
    end;

    local procedure FinalInvAfterRemoteInv(PricesInclVAT: Boolean; PositiveDiff: Boolean)
    var
        PurchOrderHeader: Record "Purchase Header";
        PurchInvoiceHeader: Record "Purchase Header";
        PurchOrderLine: Record "Purchase Line";
    begin
        Initialize();
        PurchOrderHeader."Prices Including VAT" := PricesInclVAT;
        PreparePurchOrderWithPostedPrepmtInv(PurchOrderHeader, PurchOrderLine, 1, PositiveDiff);

        PurchInvoiceHeader."Buy-from Vendor No." := PurchOrderHeader."Buy-from Vendor No.";
        CreatePurchInvoice(PurchInvoiceHeader, PurchOrderHeader."Prices Including VAT");

        LibraryPurchase.PostPurchaseDocument(PurchOrderHeader, true, false);
        GetReceiptLine(PurchInvoiceHeader, PurchOrderHeader."Last Receiving No.");

        LibraryPurchase.PostPurchaseDocument(PurchInvoiceHeader, false, true);
        VerifyZeroVendorAccEntry();

        PurchOrderHeader.Find();
        InvoicePurchaseDoc(PurchOrderHeader);
        VerifyZeroVendorAccEntry();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipTwiceGetRcptsToInvPosExclVAT()
    begin
        RecTwiceGetRcptsToInv(false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecTwiceGetRcptsToInvNegExclVAT()
    begin
        RecTwiceGetRcptsToInv(false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipTwiceGetRcptsToInvPosInclVAT()
    begin
        RecTwiceGetRcptsToInv(true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecTwiceGetRcptsToInvNegInclVAT()
    begin
        RecTwiceGetRcptsToInv(true, false);
    end;

    local procedure RecTwiceGetRcptsToInv(PricesInclVAT: Boolean; PositiveDiff: Boolean)
    var
        PurchOrderHeader: Record "Purchase Header";
        PurchInvoiceHeader: Record "Purchase Header";
        PurchOrderLine: Record "Purchase Line";
    begin
        Initialize();
        PurchOrderHeader."Prices Including VAT" := PricesInclVAT;
        PreparePurchOrderWithPostedPrepmtInv(PurchOrderHeader, PurchOrderLine, 1, PositiveDiff);

        PurchInvoiceHeader."Buy-from Vendor No." := PurchOrderHeader."Buy-from Vendor No.";
        CreatePurchInvoice(PurchInvoiceHeader, PurchOrderHeader."Prices Including VAT");

        LibraryPurchase.PostPurchaseDocument(PurchOrderHeader, true, false);
        GetReceiptLine(PurchInvoiceHeader, PurchOrderHeader."Last Receiving No.");

        UpdateQtysInLine(PurchOrderLine, GetQtyToShipTFS332246(PositiveDiff), 0);
        PurchOrderHeader.Find();
        LibraryPurchase.PostPurchaseDocument(PurchOrderHeader, true, false);
        GetReceiptLine(PurchInvoiceHeader, PurchOrderHeader."Last Receiving No.");

        LibraryPurchase.PostPurchaseDocument(PurchInvoiceHeader, false, true);
        VerifyZeroVendorAccEntry();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartInvFinRemInvPosExclVAT()
    var
        PurchHeader: Record "Purchase Header";
    begin
        PostPartInvFinRemoteInv(PurchHeader, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartInvFinRemInvNegExclVAT()
    var
        PurchHeader: Record "Purchase Header";
    begin
        PostPartInvFinRemoteInv(PurchHeader, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartInvFinRemInvPosInclVAT()
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader."Prices Including VAT" := true;
        PostPartInvFinRemoteInv(PurchHeader, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartInvFinRemInvNegInclVAT()
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader."Prices Including VAT" := true;
        PostPartInvFinRemoteInv(PurchHeader, false);
    end;

    local procedure PostPartInvFinRemoteInv(var PurchOrderHeader: Record "Purchase Header"; PositiveDiff: Boolean)
    begin
        Initialize();
        PostPartialInvoiceWithPrepmt(PurchOrderHeader, PositiveDiff);
        PostInvoiceWithRcptFromOrder(PurchOrderHeader);
        VerifyZeroVendorAccEntry();
    end;

    local procedure PostInvoiceWithRcptFromOrder(PurchOrderHeader: Record "Purchase Header")
    var
        PurchInvoiceHeader: Record "Purchase Header";
    begin
        LibraryPurchase.PostPurchaseDocument(PurchOrderHeader, true, false);

        PurchInvoiceHeader."Buy-from Vendor No." := PurchOrderHeader."Buy-from Vendor No.";
        CreatePurchInvoice(PurchInvoiceHeader, PurchOrderHeader."Prices Including VAT");

        GetReceiptLine(PurchInvoiceHeader, PurchOrderHeader."Last Receiving No.");

        InvoicePurchaseDoc(PurchInvoiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartInvLineDiscFinRemInv()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PositiveDiff: Boolean;
    begin
        Initialize();
        PositiveDiff := true;
        PreparePOLineWithLineDisc(PurchHeader, PurchLine, PositiveDiff);
        PostPurchPrepmtInvoice(PurchHeader);

        UpdateQtysInLine(PurchLine, GetQtyToShipTFS332246(PositiveDiff), GetQtyToShipTFS332246(PositiveDiff));
        InvoicePurchaseDoc(PurchHeader);

        PostInvoiceWithRcptFromOrder(PurchHeader);
        VerifyZeroVendorAccEntry();
    end;

    local procedure PreparePOLineWithLineDisc(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; PositiveDiff: Boolean)
    begin
        PreparePurchOrder(PurchHeader);
        AddPurchOrderLine100PctPrepmt(PurchLine, PurchHeader, PositiveDiff);
        PurchLine.Validate("Line Discount %", GetSpecialLineDiscPct());
        PurchLine.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialInvoicePosExclVAT()
    var
        PurchHeader: Record "Purchase Header";
    begin
        PostPartialInvoiceWithPrepmt(PurchHeader, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialInvoiceNegExclVAT()
    var
        PurchHeader: Record "Purchase Header";
    begin
        PostPartialInvoiceWithPrepmt(PurchHeader, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialInvoicePosInclVAT()
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader."Prices Including VAT" := true;
        PostPartialInvoiceWithPrepmt(PurchHeader, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialInvoiceNegInclVAT()
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader."Prices Including VAT" := true;
        PostPartialInvoiceWithPrepmt(PurchHeader, false);
    end;

    local procedure PostPartialInvoiceWithPrepmt(var PurchHeader: Record "Purchase Header"; PositiveDiff: Boolean)
    var
        PurchLine: Record "Purchase Line";
    begin
        Initialize();
        PreparePurchOrderWithPostedPrepmtInv(PurchHeader, PurchLine, 2, PositiveDiff);

        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false);
        PurchHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        LibraryPurchase.PostPurchaseDocument(PurchHeader, false, true);

        PurchLine.FindFirst();
        PurchLine.TestField("Quantity Invoiced", GetQtyToShipTFS332246(PositiveDiff));

        VerifyZeroVendorAccEntry();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartInvFinalInvPosInclVAT()
    begin
        PartInvFinalInvFromOrder(true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartInvFinalInvNegInclVAT()
    begin
        PartInvFinalInvFromOrder(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartInvFinalInvPosExclVAT()
    begin
        PartInvFinalInvFromOrder(false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartInvFinalInvNegExclVAT()
    begin
        PartInvFinalInvFromOrder(false, false);
    end;

    local procedure PartInvFinalInvFromOrder(PricesInclVAT: Boolean; PositiveDiff: Boolean)
    var
        PurchHeader: Record "Purchase Header";
    begin
        Initialize();
        PurchHeader."Prices Including VAT" := PricesInclVAT;
        PostPartialInvoiceWithPrepmt(PurchHeader, PositiveDiff);
        InvoicePurchaseDoc(PurchHeader);
        VerifyZeroVendorAccEntry();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartInvWithLineDiscExclVAT()
    begin
        PartInvWithLineDisc(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartInvWithLineDiscInclVAT()
    begin
        PartInvWithLineDisc(true);
    end;

    local procedure PartInvWithLineDisc(PricesInclVAT: Boolean)
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PositiveDiff: Boolean;
    begin
        Initialize();
        PositiveDiff := true;
        PurchHeader."Prices Including VAT" := PricesInclVAT;
        PreparePOLineWithLineDisc(PurchHeader, PurchLine, PositiveDiff);
        PostPurchPrepmtInvoice(PurchHeader);

        UpdateQtysInLine(PurchLine, GetQtyToShipTFS332246(PositiveDiff), GetQtyToShipTFS332246(PositiveDiff));
        InvoicePurchaseDoc(PurchHeader);
        VerifyZeroVendorAccEntry();

        UpdateQtysInLine(PurchLine, GetQtyToShipTFS332246(PositiveDiff), GetQtyToShipTFS332246(PositiveDiff));
        InvoicePurchaseDoc(PurchHeader);
        VerifyZeroVendorAccEntry();

        InvoicePurchaseDoc(PurchHeader);
        VerifyZeroVendorAccEntry();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorDecreasingInvLineQuantityWith100PctPrepmtAfterGetReceipt()
    var
        PurchaseOrderHeader: Record "Purchase Header";
        PurchaseInvoiceHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Get Receipt Lines] [UI]
        // [SCENARIO 374897] Error when User tries to decrease PurchaseInvoiceLine.Quantity value with 100% Prepayment after Get Receipt Lines
        Initialize();

        // [GIVEN] Purchase Order with 100% Prepayment, Line Discount and "Line Amount" = "X". Post Prepayment. Post Receipt.
        PreparePOPostPrepmtAndReceipt(PurchaseOrderHeader);

        // [GIVEN] Create Purchase Invoice. Get Receipt Lines from posted Receipt.
        CreateInvWithGetRcptLines(PurchaseInvoiceHeader, PurchaseOrderHeader);

        // [WHEN] Try to decrease Purchase Invoice Line Quantity value from Purchase Invoice page.
        OpenPurchaseInvoicePage(PurchaseInvoice, PurchaseInvoiceHeader);
        asserterror PurchaseInvoice.PurchLines.Quantity.SetValue(PurchaseInvoice.PurchLines.Quantity.AsDecimal() - 0.01);

        // [THEN] Error occurs: "Line Amount Excl. VAT cannot be less than X"
        VerifyLineAmountExpectedError(CannotBeLessThanMsg, PurchaseInvoice.PurchLines."Line Amount".AsDecimal());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorDecreasingInvLineUnitCostWith100PctPrepmtAfterGetReceipt()
    var
        PurchaseOrderHeader: Record "Purchase Header";
        PurchaseInvoiceHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Get Receipt Lines] [UI]
        // [SCENARIO 374897] Error when User tries to decrease PurchaseInvoiceLine."Direct Unit Cost" value with 100% Prepayment after Get Receipt Lines
        Initialize();

        // [GIVEN] Purchase Order with 100% Prepayment, Line Discount and "Direct Unit Cost" = "X". Post Prepayment. Post Receipt.
        PreparePOPostPrepmtAndReceipt(PurchaseOrderHeader);

        // [GIVEN] Create Purchase Invoice. Get Receipt Lines from posted Receipt.
        CreateInvWithGetRcptLines(PurchaseInvoiceHeader, PurchaseOrderHeader);

        // [WHEN] Try to decrease Purchase Invoice Line "Direct Unit Cost" value
        OpenPurchaseInvoicePage(PurchaseInvoice, PurchaseInvoiceHeader);
        asserterror PurchaseInvoice.PurchLines."Direct Unit Cost".SetValue(
            PurchaseInvoice.PurchLines."Direct Unit Cost".AsDecimal() - 0.01);

        // [THEN] Error occurs: "Direct Unit Cost must be X when the Prepayment Invoice has already been posted"
        Assert.ExpectedErrorCode('Validation');
        Assert.ExpectedError(PurchaseLine.FieldCaption("Direct Unit Cost"));
        Assert.ExpectedError(StrSubstNo(DirectCostModifyMsg, PurchaseInvoice.PurchLines."Direct Unit Cost".AsDecimal()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorIncreasingInvLineUnitCostWith100PctPrepmtAfterGetReceipt()
    var
        PurchaseOrderHeader: Record "Purchase Header";
        PurchaseInvoiceHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Get Receipt Lines] [UI]
        // [SCENARIO 374897] Error when User tries to increase PurchaseInvoiceLine."Direct Unit Cost" value with 100% Prepayment after Get Receipt Lines
        Initialize();

        // [GIVEN] Purchase Order with 100% Prepayment, Line Discount and "Direct Unit Cost" = "X". Post Prepayment. Post Receipt.
        PreparePOPostPrepmtAndReceipt(PurchaseOrderHeader);

        // [GIVEN] Create Purchase Invoice. Get Receipt Lines from posted Receipt.
        CreateInvWithGetRcptLines(PurchaseInvoiceHeader, PurchaseOrderHeader);

        // [WHEN] Try to increase Purchase Invoice Line "Direct Unit Cost" value
        OpenPurchaseInvoicePage(PurchaseInvoice, PurchaseInvoiceHeader);
        asserterror PurchaseInvoice.PurchLines."Direct Unit Cost".SetValue(
            PurchaseInvoice.PurchLines."Direct Unit Cost".AsDecimal() + 0.01);

        // [THEN] Error occurs: "Direct Unit Cost must be X when the Prepayment Invoice has already been posted"
        Assert.ExpectedErrorCode('Validation');
        Assert.ExpectedError(PurchaseLine.FieldCaption("Direct Unit Cost"));
        Assert.ExpectedError(StrSubstNo(DirectCostModifyMsg, PurchaseInvoice.PurchLines."Direct Unit Cost".AsDecimal()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorDecreasingInvLineDiscountWith100PctPrepmtAfterGetReceipt()
    var
        PurchaseOrderHeader: Record "Purchase Header";
        PurchaseInvoiceHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Get Receipt Lines] [UI]
        // [SCENARIO 374897] Error when User tries to decrease PurchaseInvoiceLine."Line Discount %" value with 100% Prepayment after Get Receipt Lines
        Initialize();

        // [GIVEN] Purchase Order with 100% Prepayment, Line Discount and "Line Amount" = "X". Post Prepayment. Post Receipt.
        PreparePOPostPrepmtAndReceipt(PurchaseOrderHeader);

        // [GIVEN] Create Purchase Invoice. Get Receipt Lines from posted Receipt.
        CreateInvWithGetRcptLines(PurchaseInvoiceHeader, PurchaseOrderHeader);

        // [WHEN] Try to decrease Purchase Invoice Line "Line Discount %" value
        OpenPurchaseInvoicePage(PurchaseInvoice, PurchaseInvoiceHeader);
        asserterror PurchaseInvoice.PurchLines."Line Discount %".SetValue(PurchaseInvoice.PurchLines."Line Discount %".AsDecimal() - 0.01);

        // [THEN] Error occurs: "Line Amount Excl. VAT cannot be more than X"
        VerifyLineAmountExpectedError(CannotBeMoreThanMsg, PurchaseInvoice.PurchLines."Line Amount".AsDecimal());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorIncreasingInvLineDiscountWith100PctPrepmtAfterGetReceipt()
    var
        PurchaseOrderHeader: Record "Purchase Header";
        PurchaseInvoiceHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [Get Receipt Lines] [UI]
        // [SCENARIO 374897] Error when User tries to increase PurchaseInvoiceLine."Line Discount %" value with 100% Prepayment after Get Receipt Lines
        Initialize();

        // [GIVEN] Purchase Order with 100% Prepayment, Line Discount and "Line Amount" = "X". Post Prepayment. Post Receipt.
        PreparePOPostPrepmtAndReceipt(PurchaseOrderHeader);

        // [GIVEN] Create Purchase Invoice. Get Receipt Lines from posted Receipt.
        CreateInvWithGetRcptLines(PurchaseInvoiceHeader, PurchaseOrderHeader);

        // [WHEN] Try to increase Purchase Invoice Line "Line Discount %" value
        OpenPurchaseInvoicePage(PurchaseInvoice, PurchaseInvoiceHeader);
        asserterror PurchaseInvoice.PurchLines."Line Discount %".SetValue(PurchaseInvoice.PurchLines."Line Discount %".AsDecimal() + 0.01);

        // [THEN] Error occurs: "Line Amount Excl. VAT cannot be less than X"
        VerifyLineAmountExpectedError(CannotBeLessThanMsg, PurchaseInvoice.PurchLines."Line Amount".AsDecimal());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoDocLinesWithDiffVATGroupsPrepmt100PctCompressLCY()
    var
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 376958] Purchase Order with two custom amount lines post with Prepayment = 100%, Compress Prepayment = TRUE and different line's VAT groups

        // [GIVEN] Two VAT Posting Setup "X" and "Y" with VAT % = 21
        // [GIVEN] Sales Order with "Prepayment %" = 100, "Compress Prepayment" = TRUE and two lines:
        // [GIVEN] Line1: "Line Amount" = 0.055, VAT Posting Setup "X"
        // [GIVEN] Line2: "Line Amount" := 95.3, VAT Posting Setup "Y"
        // [GIVEN] Post Prepayment Invoice
        // [WHEN] Post Sales Order
        // [THEN] G/L Entry with "Payables Account" has been posted with Amount = 0
        // [THEN] G/L Entries are posted with zero Amount and "VAT Amount" balance
        // [THEN] VAT Entries are posted with zero Base and Amount balance
        InvoiceNo := TwoDocLinesPrepmt100Pct_Case376958(true, true, '');
        VerifyGLEntryBalance(InvoiceNo, 0, 0);
        VerifyVATEntryBalance(InvoiceNo, 0, 0);
        VerifyZeroPostedInvoiceAmounts(InvoiceNo);
        VerifyZeroVendorAccEntry();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoDocLinesWithSameVATGroupsPrepmt100PctCompressLCY()
    var
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 376958] Purchase Order with two custom amount lines post with Prepayment = 100%, Compress Prepayment = TRUE

        // [GIVEN] Sales Order with "Prepayment %" = 100, "Compress Prepayment" = TRUE and two lines:
        // [GIVEN] "Line Amount" = 0.055
        // [GIVEN] "Line Amount" := 95.3
        // [GIVEN] Post Prepayment Invoice
        // [WHEN] Post Sales Order
        // [THEN] G/L Entry with "Payables Account" has been posted with Amount = 0
        // [THEN] G/L Entries are posted with zero Amount and "VAT Amount" balance
        // [THEN] VAT Entries are posted with zero Base and Amount balance
        InvoiceNo := TwoDocLinesPrepmt100Pct_Case376958(false, true, '');
        VerifyGLEntryBalance(InvoiceNo, 0, 0);
        VerifyVATEntryBalance(InvoiceNo, 0, 0);
        VerifyZeroPostedInvoiceAmounts(InvoiceNo);
        VerifyZeroVendorAccEntry();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoDocLinesWithDiffVATGroupsPrepmt100PctNotCompressLCY()
    var
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 376958] Purchase Order with two custom amount lines post with Prepayment = 100%, Compress Prepayment = FALSE and different line's VAT groups

        // [GIVEN] Two VAT Posting Setup "X" and "Y" with VAT % = 21
        // [GIVEN] Sales Order with "Prepayment %" = 100, "Compress Prepayment" = FALSE and two lines:
        // [GIVEN] Line1: "Line Amount" = 0.055, VAT Posting Setup "X"
        // [GIVEN] Line2: "Line Amount" := 95.3, VAT Posting Setup "Y"
        // [GIVEN] Post Prepayment Invoice
        // [WHEN] Post Sales Order
        // [THEN] G/L Entry with "Payables Account" has been posted with Amount = 0
        // [THEN] G/L Entries are posted with zero Amount and "VAT Amount" balance
        // [THEN] VAT Entries are posted with zero Base and Amount balance
        InvoiceNo := TwoDocLinesPrepmt100Pct_Case376958(true, false, '');
        VerifyGLEntryBalance(InvoiceNo, 0, 0);
        VerifyVATEntryBalance(InvoiceNo, 0, 0);
        VerifyZeroPostedInvoiceAmounts(InvoiceNo);
        VerifyZeroVendorAccEntry();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoDocLinesWithSameVATGroupsPrepmt100PctNotCompressLCY()
    var
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 376958] Purchase Order with two custom amount lines post with Prepayment = 100%, Compress Prepayment = FALSE

        // [GIVEN] Sales Order with "Prepayment %" = 100, "Compress Prepayment" = FALSE and two lines:
        // [GIVEN] "Line Amount" = 0.055
        // [GIVEN] "Line Amount" := 95.3
        // [WHEN] Post Prepayment Invoice
        // [WHEN] Post Sales Order
        // [THEN] G/L Entry with "Payables Account" has been posted with Amount = 0
        // [THEN] G/L Entries are posted with zero Amount and "VAT Amount" balance
        // [THEN] VAT Entries are posted with zero Base and Amount balance
        InvoiceNo := TwoDocLinesPrepmt100Pct_Case376958(false, false, '');
        VerifyGLEntryBalance(InvoiceNo, 0, 0);
        VerifyVATEntryBalance(InvoiceNo, 0, 0);
        VerifyZeroPostedInvoiceAmounts(InvoiceNo);
        VerifyZeroVendorAccEntry();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoDocLinesWithDiffVATGroupsPrepmt100PctCompressFCY()
    begin
        // [FEATURE] [FCY]
        // [SCENARIO 376958] Purchase Order with two custom amount lines post with Prepayment = 100%, Compress Prepayment = TRUE, Foreign Currency and different line's VAT groups

        // [GIVEN] Two VAT Posting Setup "X" and "Y" with VAT % = 21
        // [GIVEN] Sales Order with Currency, "Prepayment %" = 100, "Compress Prepayment" = TRUE and two lines:
        // [GIVEN] Line1: "Line Amount" = 0.055, VAT Posting Setup "X"
        // [GIVEN] Line2: "Line Amount" := 95.3, VAT Posting Setup "Y"
        // [GIVEN] Post Prepayment Invoice
        // [WHEN] Post Sales Order
        // [THEN] G/L Entry with "Payables Account" has been posted with Amount = 0
        TwoDocLinesPrepmt100Pct_Case376958(true, true, CreateCurrencyCodeWithRandomExchRate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoDocLinesWithSameVATGroupsPrepmt100PctCompressFCY()
    begin
        // [FEATURE] [FCY]
        // [SCENARIO 376958] Purchase Order with two custom amount lines post with Prepayment = 100%, Compress Prepayment = TRUE, Foreign Currency

        // [GIVEN] Sales Order with Currency,  "Prepayment %" = 100, "Compress Prepayment" = TRUE and two lines:
        // [GIVEN] "Line Amount" = 0.055
        // [GIVEN] "Line Amount" := 95.3
        // [GIVEN] Post Prepayment Invoice
        // [WHEN] Post Sales Order
        // [THEN] G/L Entry with "Payables Account" has been posted with Amount = 0
        TwoDocLinesPrepmt100Pct_Case376958(false, true, CreateCurrencyCodeWithRandomExchRate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoDocLinesWithDiffVATGroupsPrepmt100PctNotCompressFCY()
    begin
        // [FEATURE] [FCY]
        // [SCENARIO 376958] Purchase Order with two custom amount lines post with Prepayment = 100%, Compress Prepayment = FALSE, Foreign Currency and different line's VAT groups

        // [GIVEN] Two VAT Posting Setup "X" and "Y" with VAT % = 21
        // [GIVEN] Sales Order with Currency,  "Prepayment %" = 100, "Compress Prepayment" = FALSE and two lines:
        // [GIVEN] Line1: "Line Amount" = 0.055, VAT Posting Setup "X"
        // [GIVEN] Line2: "Line Amount" := 95.3, VAT Posting Setup "Y"
        // [GIVEN] Post Prepayment Invoice
        // [WHEN] Post Sales Order
        // [THEN] G/L Entry with "Payables Account" has been posted with Amount = 0
        TwoDocLinesPrepmt100Pct_Case376958(true, false, CreateCurrencyCodeWithRandomExchRate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoDocLinesWithSameVATGroupsPrepmt100PctNotCompressFCY()
    begin
        // [FEATURE] [FCY]
        // [SCENARIO 376958] Purchase Order with two custom amount lines post with Prepayment = 100%, Compress Prepayment = FALSE, Foreign Currency

        // [GIVEN] Sales Order with Currency,  "Prepayment %" = 100, "Compress Prepayment" = FALSE and two lines:
        // [GIVEN] "Line Amount" = 0.055
        // [GIVEN] "Line Amount" := 95.3
        // [GIVEN] Post Prepayment Invoice
        // [WHEN] Post Sales Order
        // [THEN] G/L Entry with "Payables Account" has been posted with Amount = 0
        TwoDocLinesPrepmt100Pct_Case376958(false, false, CreateCurrencyCodeWithRandomExchRate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtLCYRoundingCalcEqualFinalInvoiceLCYRounding()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PrepmtInvNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [FCY]
        // [SCENARIO 379324] Prepayment LCY rounding works the same way as final invoice LCY rounding in case of currency
        Initialize();

        // [GIVEN] Purchase Order with 100% Prepayment, Currency (Exch. Rate = 1:1000), VAT% = 10, Line Amount Excl. VAT = 100.01, Total Amount = 110.01 (VAT Amount = 10)
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 10);
        CreatePurchDoc(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, VATPostingSetup."VAT Bus. Posting Group",
          CreateCurrencyCodeWithExchRate(0.001), false, false);
        AddPurchOrderLineWithPrepmtVATProdGroup(
          PurchaseLine, PurchaseHeader, VATPostingSetup."VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group", 1, 100.01);
        // [GIVEN] Post prepayment invoice
        PostPurchPrepmtInvoice(PurchaseHeader);
        PrepmtInvNo := FindPrepmtInvoice(PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."No.");

        // [WHEN] Post final invoice
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] There are 3 Prepayment Invoice G/L Entries:
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        VerifyGLEntryCount(PrepmtInvNo, 3);
        // [THEN] G/L Account 5410 <Vendor Domestic> Amount = -110010, VAT Amount = 0
        VerifyGLEntryAmount(PrepmtInvNo, GetVendorPostingGroupPayAccNo(PurchaseHeader."Buy-from Vendor No."), -110010, 0);
        // [THEN] G/L Account 2430 <Vendor Prepayments VAT 10 %> Amount = 100010, VAT Amount = 10000
        VerifyGLEntryAmount(PrepmtInvNo, GeneralPostingSetup."Purch. Prepayments Account", 100010, 10000);
        // [THEN] G/L Account 5630 <Purchase VAT 10 %> Amount = 100010, VAT Amount = 0
        VerifyGLEntryAmount(PrepmtInvNo, VATPostingSetup."Purchase VAT Account", 10000, 0);

        // [THEN] There are 5 Invoice G/L Entries:
        VerifyGLEntryCount(InvoiceNo, 5);
        // [THEN] G/L Account 5410 <Vendor Domestic> Amount = 0, VAT Amount = 0
        VerifyGLEntryAmount(InvoiceNo, GetVendorPostingGroupPayAccNo(PurchaseHeader."Buy-from Vendor No."), 0, 0);
        // [THEN] G/L Account 2430 <Vendor Prepayments VAT 10 %> Amount = -100010, VAT Amount = -10000
        VerifyGLEntryAmount(InvoiceNo, GeneralPostingSetup."Purch. Prepayments Account", -100010, -10000);
        // [THEN] G/L Account 7120 <Purch., Retail - EU> Amount = 100010, VAT Amount = 10000
        VerifyGLEntryAmount(InvoiceNo, PurchaseLine."No.", 100010, 10000);
        // [THEN] G/L Account 5630 <Purchase VAT 10 %> Amount = 100010, VAT Amount = 0
        // [THEN] G/L Account 5630 <Purchase VAT 10 %> Amount = -100010, VAT Amount = 0
        VerifyGLEntryAccountCount(InvoiceNo, VATPostingSetup."Purchase VAT Account", 2);
        VerifyGLEntryAccountBalance(InvoiceNo, VATPostingSetup."Purchase VAT Account", 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteLinesFromSeparateInvoiceAfterFullPrepaymentAndReceipt()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Get Receipt Lines]
        // [SCENARIO 348166] Stan can delete line from Invoice created from prepaid shipment lines.

        // [GIVEN] Purchase order with 2 lines
        PreparePurchOrder(PurchaseHeaderOrder);
        AddPurchOrderLine(
          PurchaseLine, PurchaseHeaderOrder, LibraryRandom.RandDecInRange(10, 100, 2), LibraryRandom.RandDecInRange(1000, 2000, 2), 100, 0);
        AddPurchOrderLine(
          PurchaseLine, PurchaseHeaderOrder, LibraryRandom.RandDecInRange(10, 100, 2), LibraryRandom.RandDecInRange(1000, 2000, 2), 100, 0);
        // [GIVEN] Posted 100% prepayment invoice
        PostPurchPrepmtInvoice(PurchaseHeaderOrder);
        // [GIVEN] Posted receipt
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        // [GIVEN] Purchase Invoice create from receipt lines
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, PurchaseHeaderOrder."Buy-from Vendor No.");
        GetReceiptLine(PurchaseHeaderInvoice, PurchaseHeaderOrder."Last Receiving No.");

        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeaderInvoice);
        PurchaseLine.SetFilter(Quantity, '<>0');
        PurchaseLine.FindFirst();
        Assert.RecordCount(PurchaseLine, 2);

        // [WHEN] Delete line with amount from Invoice
        PurchaseLine.Delete(true);

        // [THEN] The single line with amount remains in invoice
        Assert.RecordCount(PurchaseLine, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DescriptionOfRoundingAccountInPostedPrepaymentInvoice()
    var
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FETAURE] [Invoice Rounding]
        // [SCENARIO 397118] System copies "Invoice Rounding" account's description to posted invoice line.
        Initialize();

        LibraryERM.SetInvRoundingPrecisionLCY(1);
        LibraryPurchase.SetInvoiceRounding(true);

        PreparePurchOrder(PurchaseHeaderOrder);
        AddPurchOrderLine(
          PurchaseLine, PurchaseHeaderOrder, LibraryRandom.RandDecInRange(10, 100, 2), LibraryRandom.RandDecInRange(1000, 2000, 2), 100, 0);

        LibraryERMCountryData.UpdateVATPostingSetup();

        PostPurchPrepmtInvoice(PurchaseHeaderOrder);

        VerifyDescriptionOnPostedInvoiceRoundingLine(PurchaseHeaderOrder);
    end;

    local procedure Initialize()
    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Purch Full Prepmt Rounding");
        LibraryApplicationArea.EnableFoundationSetup();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Purch Full Prepmt Rounding");

        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();

        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibrarySetupStorage.SavePurchasesSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Purch Full Prepmt Rounding");
    end;

    local procedure TwoDocLinesPrepmt100Pct_Case376958(UseDiffVATGroups: Boolean; CompressPrepmt: Boolean; CurrencyCode: Code[10]) InvoiceNo: Code[20]
    var
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
    begin
        Initialize();
        CreateTwoVATPostingSetups(VATPostingSetup, 21);

        CreatePurchDoc(
          PurchaseHeader, PurchaseHeader."Document Type"::Order,
          VATPostingSetup[1]."VAT Bus. Posting Group", CurrencyCode, false, CompressPrepmt);
        AddPurchOrderLinesCase376958(PurchaseHeader, VATPostingSetup, UseDiffVATGroups);

        PostPurchPrepmtInvoice(PurchaseHeader);
        InvoiceNo := InvoicePurchaseDoc(PurchaseHeader);

        VerifyGLEntryAmount(InvoiceNo, GetVendorPostingGroupPayAccNo(PurchaseHeader."Buy-from Vendor No."), 0, 0);
        VerifyGLEntryCount(InvoiceNo, 9); // 2 (prepmt + deduct) x 2 lines x 2(amount + VAT) + zero total balance
        VerifyVATEntryCount(InvoiceNo, 4); // 2 (prepmt + deduct) x 2 lines VAT
        VerifyZeroPostedInvoiceAmounts(InvoiceNo);
        VerifyZeroVendorAccEntry();
    end;

    local procedure PreparePOPostPrepmtAndReceipt(var PurchaseOrderHeader: Record "Purchase Header")
    var
        PurchaseOrderLine: Record "Purchase Line";
    begin
        PreparePurchOrder(PurchaseOrderHeader);
        AddPurchOrderLine(
          PurchaseOrderLine,
          PurchaseOrderHeader,
          LibraryRandom.RandDecInRange(10, 100, 2),
          LibraryRandom.RandDecInRange(1000, 2000, 2),
          100,
          LibraryRandom.RandDecInRange(10, 50, 2));
        PostPurchPrepmtInvoice(PurchaseOrderHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseOrderHeader, true, false);
    end;

    local procedure CreateInvWithGetRcptLines(var PurchaseInvoiceHeader: Record "Purchase Header"; PurchaseOrderHeader: Record "Purchase Header")
    begin
        PurchaseInvoiceHeader."Buy-from Vendor No." := PurchaseOrderHeader."Buy-from Vendor No.";
        CreatePurchInvoice(PurchaseInvoiceHeader, PurchaseOrderHeader."Prices Including VAT");
        GetReceiptLine(PurchaseInvoiceHeader, PurchaseOrderHeader."Last Receiving No.");
    end;

    local procedure PreparePurchOrderWithPostedPrepmtInv(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; NoOfLines: Integer; PositiveDiff: Boolean)
    var
        i: Integer;
    begin
        PreparePurchOrder(PurchHeader);
        for i := 1 to NoOfLines do
            AddPurchOrderLine100PctPrepmt(PurchLine, PurchHeader, PositiveDiff);

        PostPurchPrepmtInvoice(PurchHeader);

        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetFilter(Quantity, '<>%1', 0);
        if PurchLine.FindSet() then
            repeat
                UpdateQtysInLine(PurchLine, GetQtyToShipTFS332246(PositiveDiff), 0);
            until PurchLine.Next() = 0;
    end;

    local procedure PreparePurchOrder(var PurchHeader: Record "Purchase Header")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreatePurchOrder(PurchHeader, VATPostingSetup."VAT Bus. Posting Group", PurchHeader."Prices Including VAT");
    end;

    local procedure CreateTwoVATPostingSetups(var VATPostingSetup: array[2] of Record "VAT Posting Setup"; VATRate: Decimal)
    var
        DummyGLAccount: Record "G/L Account";
        i: Integer;
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup[1], VATPostingSetup[1]."VAT Calculation Type"::"Normal VAT", VATRate);

        DummyGLAccount."VAT Bus. Posting Group" := VATPostingSetup[1]."VAT Bus. Posting Group";
        DummyGLAccount."VAT Prod. Posting Group" := VATPostingSetup[1]."VAT Prod. Posting Group";
        VATPostingSetup[2].Get(VATPostingSetup[1]."VAT Bus. Posting Group", LibraryERM.CreateRelatedVATPostingSetup(DummyGLAccount));
        VATPostingSetup[2].Validate("VAT Identifier", LibraryUtility.GenerateGUID());
        VATPostingSetup[2].Modify(true);

        for i := 1 to ArrayLen(VATPostingSetup) do
            UpdateVATPostingSetupAccounts(VATPostingSetup[i]);
    end;

    local procedure CreatePurchInvoice(var PurchaseHeader: Record "Purchase Header"; PricesInclVAT: Boolean)
    begin
        CreatePurchDoc(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '', '', PricesInclVAT, true);
    end;

    local procedure CreatePurchOrder(var PurchaseHeader: Record "Purchase Header"; VATBusPostingGroupCode: Code[20]; PricesInclVAT: Boolean)
    begin
        CreatePurchDoc(PurchaseHeader, PurchaseHeader."Document Type"::Order, VATBusPostingGroupCode, '', PricesInclVAT, true);
    end;

    local procedure CreatePurchDoc(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VATBusPostingGroupCode: Code[20]; CurrencyCode: Code[10]; PricesInclVAT: Boolean; CompressPrepmt: Boolean)
    var
        VendorNo: Code[20];
    begin
        if PurchaseHeader."Buy-from Vendor No." = '' then
            VendorNo := CreateVendorWithVATBusPostGr(VATBusPostingGroupCode)
        else
            VendorNo := PurchaseHeader."Buy-from Vendor No.";
        with PurchaseHeader do begin
            LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
            Validate("Currency Code", CurrencyCode);
            Validate("Prices Including VAT", PricesInclVAT);
            Validate("Compress Prepayment", CompressPrepmt);
            Modify();
        end;
    end;

    local procedure CreateVendorWithVATBusPostGr(VATBusPostingGroupCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        with Vendor do begin
            Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
            Modify(true);
            UpdateVendorInvoiceRoundingAccount("Vendor Posting Group", "VAT Bus. Posting Group");
            exit("No.");
        end;
    end;

    local procedure CreateCurrencyCodeWithRandomExchRate(): Code[10]
    begin
        exit(UpdateCurrencyInvRoundPrecision(LibraryERM.CreateCurrencyWithRandomExchRates()));
    end;

    local procedure CreateCurrencyCodeWithExchRate(ExchRate: Decimal): Code[10]
    begin
        exit(UpdateCurrencyInvRoundPrecision(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchRate, ExchRate)));
    end;

    local procedure AddPurchOrderLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Qty: Decimal; UnitPrice: Decimal; PrepmtPct: Decimal; DiscountPct: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), Qty);
        UpdateGenPostingSetupPrepmtAccounts(PurchaseLine, PurchaseLine."VAT Prod. Posting Group");
        UpdatePurchLine(PurchaseLine, UnitPrice, DiscountPct, PrepmtPct);
    end;

    local procedure AddPurchOrderLineWithPrepmtVATProdGroup(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; VATProdPostingGroupCode: Code[20]; PrepmtAccVATProdPostingGroup: Code[20]; Qty: Decimal; DirectUnitCost: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        VATPostingSetup.Get(PurchaseHeader."VAT Bus. Posting Group", VATProdPostingGroupCode);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase), Qty);
        UpdateGenPostingSetupPrepmtAccounts(PurchaseLine, PrepmtAccVATProdPostingGroup);
        UpdatePurchLine(PurchaseLine, DirectUnitCost, 0, 100);
    end;

    local procedure AddPurchOrderLine100PctPrepmt(var PurchLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; PositiveDiff: Boolean)
    begin
        AddPurchOrderLine(PurchLine, PurchaseHeader, GetLineQuantityTFS332246(PositiveDiff), 3.99, 100, 0);
    end;

    local procedure AddPurchOrderLinesCase376958(PurchaseHeader: Record "Purchase Header"; VATPostingSetup: array[2] of Record "VAT Posting Setup"; UseDiffVATGroups: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        VATProdPostingGroupCode2: Code[20];
    begin
        if UseDiffVATGroups then
            VATProdPostingGroupCode2 := VATPostingSetup[2]."VAT Prod. Posting Group"
        else
            VATProdPostingGroupCode2 := VATPostingSetup[1]."VAT Prod. Posting Group";

        AddPurchOrderLineWithPrepmtVATProdGroup(
          PurchaseLine, PurchaseHeader, VATPostingSetup[1]."VAT Prod. Posting Group", VATPostingSetup[1]."VAT Prod. Posting Group", 1, 0.055);
        AddPurchOrderLineWithPrepmtVATProdGroup(
          PurchaseLine, PurchaseHeader, VATProdPostingGroupCode2, VATProdPostingGroupCode2, 1, 95.3);
    end;

    local procedure FindPrepmtInvoice(VendorNo: Code[20]; OrderNo: Code[20]): Code[20]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        with PurchInvHeader do begin
            SetRange("Buy-from Vendor No.", VendorNo);
            SetRange("Prepayment Invoice", true);
            SetRange("Prepayment Order No.", OrderNo);
            FindFirst();
            exit("No.");
        end;
    end;

    local procedure GetQtyToShipTFS332246(PositiveDiff: Boolean): Decimal
    begin
        if PositiveDiff then
            exit(2.6);
        exit(2.5);
    end;

    local procedure GetLineQuantityTFS332246(PositiveDiff: Boolean): Decimal
    begin
        if PositiveDiff then
            exit(7.5);
        exit(7.6);
    end;

    local procedure GetSpecialLineDiscPct(): Decimal
    begin
        exit(29.72);
    end;

    local procedure GetReceiptLine(PurchHeader: Record "Purchase Header"; ShipmentNo: Code[20])
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetRcpt: Codeunit "Purch.-Get Receipt";
    begin
        PurchGetRcpt.SetPurchHeader(PurchHeader);
        PurchRcptLine.SetRange("Document No.", ShipmentNo);
        PurchGetRcpt.CreateInvLines(PurchRcptLine);
    end;

    local procedure GetVendorPostingGroupPayAccNo(VendorNo: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        Vendor.Get(VendorNo);
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        exit(VendorPostingGroup."Payables Account");
    end;

    local procedure GetVendorInvoiceRoundingAccount(var GLAccount: Record "G/L Account"; VendorNo: Code[20])
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        Vendor.Get(VendorNo);
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        GLAccount.Get(VendorPostingGroup."Invoice Rounding Account");
    end;

    local procedure PostPurchPrepmtInvoice(var PurchHeader: Record "Purchase Header")
    var
        PurchPostPrepayments: Codeunit "Purchase-Post Prepayments";
    begin
        PurchPostPrepayments.Invoice(PurchHeader);
    end;

    local procedure InvoicePurchaseDoc(var PurchaseHeader: Record "Purchase Header"): Code[20]
    begin
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure UpdateQtysInLine(var PurchLine: Record "Purchase Line"; QtyToReceive: Decimal; QtyToInvoice: Decimal)
    begin
        PurchLine.Find();
        PurchLine.Validate("Qty. to Receive", QtyToReceive);
        PurchLine.Validate("Qty. to Invoice", QtyToInvoice);
        PurchLine.Modify();
    end;

    local procedure UpdatePurchLine(var PurchaseLine: Record "Purchase Line"; NewDirectUnitCost: Decimal; NewDiscountPct: Decimal; NewPrepmtPct: Decimal)
    begin
        with PurchaseLine do begin
            Validate("Direct Unit Cost", NewDirectUnitCost);
            Validate("Line Discount %", NewDiscountPct);
            Validate("Prepayment %", NewPrepmtPct);
            Modify(true);
        end;
    end;

    local procedure UpdateVATPostingSetupAccounts(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        with VATPostingSetup do begin
            Validate("Sales VAT Account", LibraryERM.CreateGLAccountWithSalesSetup());
            Validate("Purchase VAT Account", LibraryERM.CreateGLAccountWithPurchSetup());
            Modify(true);
        end;
    end;

    local procedure UpdateGenPostingSetupPrepmtAccounts(var PurchaseLine: Record "Purchase Line"; PrepmtAccVATProdPostingGroup: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GLAccount: Record "G/L Account";
    begin
        VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);

        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        GeneralPostingSetup."Gen. Prod. Posting Group" := GenProductPostingGroup.Code;
        GeneralPostingSetup."Purch. Prepayments Account" :=
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        GeneralPostingSetup.Insert();

        PurchaseLine."Gen. Prod. Posting Group" := GeneralPostingSetup."Gen. Prod. Posting Group";
        PurchaseLine.Modify();

        GLAccount.Get(GeneralPostingSetup."Purch. Prepayments Account");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", PrepmtAccVATProdPostingGroup);
        GLAccount.Modify();
    end;

    local procedure UpdateVendorInvoiceRoundingAccount(VendorPostingGroupCode: Code[20]; VATBusPostingGroupCode: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VendorPostingGroup: Record "Vendor Posting Group";
        GLAccount: Record "G/L Account";
    begin
        VendorPostingGroup.Get(VendorPostingGroupCode);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroupCode, VATProductPostingGroup.Code);

        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));
        GLAccount.Validate(Name, LibraryUtility.GenerateGUID());
        GLAccount.Modify(true);
        VendorPostingGroup.Validate("Invoice Rounding Account", GLAccount."No.");
        VendorPostingGroup.Modify(true);
    end;

    local procedure UpdateCurrencyInvRoundPrecision(CurrencyCode: Code[10]): Code[10]
    var
        Currency: Record Currency;
    begin
        with Currency do begin
            Get(CurrencyCode);
            Validate("Invoice Rounding Precision", 0.01);
            Modify(true);
            exit(Code);
        end;
    end;

    local procedure OpenPurchaseInvoicePage(var PurchaseInvoice: TestPage "Purchase Invoice"; PurchaseInvoiceHeader: Record "Purchase Header")
    begin
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseInvoiceHeader);
        PurchaseInvoice.PurchLines.Last();
    end;

    local procedure VerifyDescriptionOnPostedInvoiceRoundingLine(PurchaseHeaderOrder: Record "Purchase Header")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        GLAccountRounding: Record "G/L Account";
    begin
        PurchInvHeader.SetRange("Prepayment Order No.", PurchaseHeaderOrder."No.");
        PurchInvHeader.SetRange("Buy-from Vendor No.", PurchaseHeaderOrder."Buy-from Vendor No.");
        PurchInvHeader.FindFirst();

        GetVendorInvoiceRoundingAccount(GLAccountRounding, PurchaseHeaderOrder."Buy-from Vendor No.");
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.SetRange("No.", GLAccountRounding."No.");
        PurchInvLine.FindFirst();
        PurchInvLine.TestField(Description, GLAccountRounding.Name);
    end;

    local procedure VerifyZeroVendorAccEntry()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        with VendLedgEntry do begin
            FindLast();
            CalcFields(Amount);
            Assert.AreEqual(0, Amount, 'Expected zero Vendor Ledger Entry due to 100% prepayment.');
        end;
    end;

    local procedure VerifyZeroPostedInvoiceAmounts(DocumentNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.CalcFields(Amount, "Amount Including VAT");
        PurchInvHeader.TestField(Amount, 0);
        PurchInvHeader.TestField("Amount Including VAT", 0);
    end;

    local procedure VerifyLineAmountExpectedError(ErrorTemplate: Text; ExpectedLineAmount: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        Assert.ExpectedErrorCode('Validation');
        Assert.ExpectedError(PurchaseLine.FieldCaption("Line Amount"));
        Assert.ExpectedError(StrSubstNo(ErrorTemplate, ExpectedLineAmount));
    end;

    local procedure VerifyGLEntryAmount(DocumentNo: Code[20]; GLAccountNo: Code[20]; ExpectedAmount: Decimal; ExpectedVATAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        with GLEntry do begin
            SetRange("Document No.", DocumentNo);
            SetRange("G/L Account No.", GLAccountNo);
            FindFirst();
            Assert.AreEqual(ExpectedAmount, Amount, FieldCaption(Amount));
            Assert.AreEqual(ExpectedVATAmount, "VAT Amount", FieldCaption("VAT Amount"));
        end;
    end;

    local procedure VerifyGLEntryCount(DocumentNo: Code[20]; ExpectedCount: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(GLEntry, ExpectedCount);
    end;

    local procedure VerifyGLEntryAccountCount(DocumentNo: Code[20]; GLAccountNo: Code[20]; ExpectedCount: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        Assert.RecordCount(GLEntry, ExpectedCount);
    end;

    local procedure VerifyGLEntryBalance(DocumentNo: Code[20]; ExpectedAmountBalance: Decimal; ExpectedVATAmountBalance: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        with GLEntry do begin
            SetRange("Document No.", DocumentNo);
            CalcSums(Amount, "VAT Amount");
            Assert.AreEqual(ExpectedAmountBalance, Amount, FieldCaption(Amount));
            Assert.AreEqual(ExpectedVATAmountBalance, "VAT Amount", FieldCaption("VAT Amount"));
        end;
    end;

    local procedure VerifyGLEntryAccountBalance(DocumentNo: Code[20]; GLAccountNo: Code[20]; ExpectedAmountBalance: Decimal; ExpectedVATAmountBalance: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        with GLEntry do begin
            SetRange("Document No.", DocumentNo);
            SetRange("G/L Account No.", GLAccountNo);
            CalcSums(Amount, "VAT Amount");
            Assert.AreEqual(ExpectedAmountBalance, Amount, FieldCaption(Amount));
            Assert.AreEqual(ExpectedVATAmountBalance, "VAT Amount", FieldCaption("VAT Amount"));
        end;
    end;

    local procedure VerifyVATEntryCount(DocumentNo: Code[20]; ExpectedCount: Integer)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(VATEntry, ExpectedCount);
    end;

    local procedure VerifyVATEntryBalance(DocumentNo: Code[20]; ExpectedBaseBalance: Decimal; ExpectedAmountBalance: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        with VATEntry do begin
            SetRange("Document No.", DocumentNo);
            CalcSums(Base, Amount);
            Assert.AreEqual(ExpectedBaseBalance, Base, FieldCaption(Base));
            Assert.AreEqual(ExpectedAmountBalance, Amount, FieldCaption(Amount));
        end;
    end;
}

