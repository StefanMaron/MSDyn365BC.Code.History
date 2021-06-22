codeunit 134332 "ERM Copy Purch/Sales Doc"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Copy Document]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryService: Codeunit "Library - Service";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        LibraryResource: Codeunit "Library - Resource";
        SalesDocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Shipment","Posted Invoice","Posted Return Receipt","Posted Credit Memo","Arch. Quote","Arch. Order","Arch. Blanket Order","Arch. Return Order";
        PurchDocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Receipt","Posted Invoice","Posted Return Shipment","Posted Credit Memo","Arch. Quote","Arch. Order","Arch. Blanket Order","Arch. Return Order";
        IsInitialized: Boolean;
        OneLineShouldBeCopiedErr: Label 'One line should be copied.';
        InvoiceNoTxt: Label 'Invoice No. %1:';
        WrongCopyPurchaseResourceErr: Label 'Wrong data after copy purchase resource';
        AddrChangedErr: Label 'field on the purchase order %1 must be the same as on sales order %2.', Comment = '%1: Purchase Order No., %2: Sales Order No.';

    [Test]
    [Scope('OnPrem')]
    procedure CopyPurchOrdCopyHeadRecalcLine()
    var
        Item: Record Item;
        OriginalPurchLine: Record "Purchase Line";
        DestinationPurchLine: Record "Purchase Line";
        PurchaseLineDiscount: Record "Purchase Line Discount";
        OriginalPurchHeader: Record "Purchase Header";
        DestinationPurchHeader: Record "Purchase Header";
        PriceListLine: Record "Price List Line";
        OriginalDocType: Enum "Purchase Document Type";
        DestinationDocType: Enum "Purchase Document Type";
        ItemCost: Integer;
        ItemPrice: Integer;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Purchase Document is copied with options CopyHeader = TRUE and RecalculateLine = TRUE
        Initialize;
        PreparePurchaseTest(Item, OriginalDocType, DestinationDocType, ItemCost, ItemPrice);

        // Create original purch document without discount specified.
        CreateOneItemPurchDocWithItem(OriginalPurchHeader, Item, OriginalDocType);

        // Prepare destination document type
        DestinationPurchHeader.Init();
        DestinationPurchHeader.Validate("Document Type", DestinationDocType);
        DestinationPurchHeader.Insert(true);

        CreateVendorItemDiscount(PurchaseLineDiscount, OriginalPurchHeader."Buy-from Vendor No.", Item);
        CopyFromToPriceListLine.CopyFrom(PurchaseLineDiscount, PriceListLine);

        // 2. Exercise
        RunCopyPurchaseDoc(
          OriginalPurchHeader."No.", DestinationPurchHeader,
          MapperPurchaseHeaders(OriginalPurchHeader."Document Type"), true, true);

        // 3. Validation
        DestinationPurchHeader.Get(DestinationPurchHeader."Document Type", DestinationPurchHeader."No.");
        VerifyPurchaseHeadersAreEqual(OriginalPurchHeader, DestinationPurchHeader);
        DestinationPurchHeader.TestField("Quote No.", '');

        // Assumes only one line of each type exists in the purchase order.
        FindFirstLineOfPurchaseDocument(OriginalPurchHeader, OriginalPurchLine);
        FindFirstLineOfPurchaseDocument(DestinationPurchHeader, DestinationPurchLine);

        ValidatePurchaseLine(DestinationPurchLine,
          OriginalPurchLine.Quantity,
          ItemCost,
          PurchaseLineDiscount."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPurchOrdCopyHead()
    var
        OriginalPurchHeader: Record "Purchase Header";
        DestinationPurchHeader: Record "Purchase Header";
        Item: Record Item;
        PurchaseLineDiscount: Record "Purchase Line Discount";
        PriceListLine: Record "Price List Line";
        OriginalDocType: Enum "Purchase Document Type";
        DestinationDocType: Enum "Purchase Document Type";
        ItemCost: Integer;
        ItemPrice: Integer;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Purchase Document is copied with options CopyHeader = TRUE and RecalculateLine = FALSE
        Initialize;
        PreparePurchaseTest(Item, OriginalDocType, DestinationDocType, ItemCost, ItemPrice);

        // Create original purch document without discount specified.
        CreateOneItemPurchDocWithItem(OriginalPurchHeader, Item, OriginalDocType);

        // Create destination purchase header
        CreatePurchHeader(DestinationPurchHeader, DestinationDocType);

        // Order date should be today otherwise the discount we created won't be able to apply
        DestinationPurchHeader.Validate("Order Date", WorkDate);
        DestinationPurchHeader.Modify(true);

        CreateVendorItemDiscount(PurchaseLineDiscount, OriginalPurchHeader."Buy-from Vendor No.", Item);
        CopyFromToPriceListLine.CopyFrom(PurchaseLineDiscount, PriceListLine);

        // 2. Exercise
        RunCopyPurchaseDoc(
          OriginalPurchHeader."No.", DestinationPurchHeader,
          MapperPurchaseHeaders(OriginalPurchHeader."Document Type"), true, false);

        // 3. Validation
        DestinationPurchHeader.Get(DestinationPurchHeader."Document Type", DestinationPurchHeader."No.");
        VerifyPurchaseHeadersAreEqual(OriginalPurchHeader, DestinationPurchHeader);

        // Quantity, unit cost and discount should be same as original although now a discount exists for this item and vendor.
        VerifyPurchaseLinesAreEqual(OriginalPurchHeader, DestinationPurchHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPurchOrdRecalcLine()
    var
        OriginalPurchHeader: Record "Purchase Header";
        DestinationPurchHeader: Record "Purchase Header";
        PurchaseLineDiscount: Record "Purchase Line Discount";
        Item: Record Item;
        DestinationInvoiceVendor: Record Vendor;
        DestinationPurchLine: Record "Purchase Line";
        OriginalPurchLine: Record "Purchase Line";
        PriceListLine: Record "Price List Line";
        OriginalDocType: Enum "Purchase Document Type";
        DestinationDocType: Enum "Purchase Document Type";
        ItemCost: Integer;
        ItemPrice: Integer;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Purchase Document is copied with options CopyHeader = FALSE and RecalculateLine = TRUE
        Initialize;
        PreparePurchaseTest(Item, OriginalDocType, DestinationDocType, ItemCost, ItemPrice);

        CreateOneItemPurchDocWithItem(OriginalPurchHeader, Item, OriginalDocType);

        LibraryPurchase.CreateVendor(DestinationInvoiceVendor);

        // If Copy Purch Document is ran with IncludeHeader=False is mandatory to have the same vendor in original and destination doc.
        CreatePurchHeaderForVendor(DestinationPurchHeader, DestinationDocType, DestinationInvoiceVendor."No.");

        // Order date should be today otherwise the discount we will create won't apply
        DestinationPurchHeader.Validate("Order Date", WorkDate);
        DestinationPurchHeader.Modify(true);

        CreateVendorItemDiscount(PurchaseLineDiscount, DestinationInvoiceVendor."No.", Item);
        CopyFromToPriceListLine.CopyFrom(PurchaseLineDiscount, PriceListLine);

        // 2. Exercise
        RunCopyPurchaseDoc(
          OriginalPurchHeader."No.", DestinationPurchHeader,
          MapperPurchaseHeaders(OriginalPurchHeader."Document Type"), false, true);

        // 3. Validation
        // Validate the line is right (don't care about the header because it has not been copied).
        // Line prices should be recalculated according to the new vendor prices considering the discount.
        // Refresh new purchase header after the copy
        DestinationPurchHeader.Get(DestinationPurchHeader."Document Type", DestinationPurchHeader."No.");

        // Assumes only one line of each type exists in the purchase order.
        FindFirstLineOfPurchaseDocument(OriginalPurchHeader, OriginalPurchLine);
        FindFirstLineOfPurchaseDocument(DestinationPurchHeader, DestinationPurchLine);

        ValidatePurchaseLine(DestinationPurchLine,
          OriginalPurchLine.Quantity,
          ItemCost,
          PurchaseLineDiscount."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPurchOrdWithInvRoundingLine()
    var
        OriginalPurchHeader: Record "Purchase Header";
        DestinationPurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        InvRoundingAccNo: Code[20];
    begin
        // [FEATURE] [Invoice Rounding] [Purchase]
        // [SCENARIO 140138] Copy Document should not skip a purchase line that has Item's "No." equal to "Invoice Rounding Account"
        Initialize;
        LibraryPurchase.SetInvoiceRounding(true);

        // [GIVEN] Order "1001" with two lines:
        // [GIVEN] The 1st line of Type "Item", where "No." is "IRA"
        CreateOneItemPurchDoc(OriginalPurchHeader, OriginalPurchHeader."Document Type"::Order);
        // [GIVEN] Vendor with Vendor Posting Group, where "Invoice Rounding Account" = "IRA"
        FindFirstLineOfPurchaseDocument(OriginalPurchHeader, PurchLine);
        InvRoundingAccNo := PurchLine."No.";
        SetPurchInvoiceRoundingAccount(OriginalPurchHeader."Vendor Posting Group", CreatePurchGLAccNo(InvRoundingAccNo));
        // [GIVEN] The 2nd line of Type "G/L Account", where "No." is "IRA"
        LibraryPurchase.CreatePurchaseLine(PurchLine, OriginalPurchHeader, PurchLine.Type::"G/L Account", InvRoundingAccNo, 1);
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchLine.Modify(true);

        // [WHEN] Copy Document "1001" to new Order "1002"
        CreatePurchHeaderForVendor(
          DestinationPurchHeader, DestinationPurchHeader."Document Type"::Order, OriginalPurchHeader."Buy-from Vendor No.");
        RunCopyPurchaseDoc(
          OriginalPurchHeader."No.", DestinationPurchHeader,
          MapperPurchaseHeaders(OriginalPurchHeader."Document Type"), false, false);

        // [THEN] Order "1002" contains two lines, where "Type" is "Item" and "G/L Account", where "No." is "IRA"
        PurchLine.SetRange("Document Type", DestinationPurchHeader."Document Type");
        PurchLine.SetRange("Document No.", DestinationPurchHeader."No.");
        PurchLine.SetRange("No.", InvRoundingAccNo);
        PurchLine.FindSet;
        PurchLine.TestField(Type, PurchLine.Type::Item);
        PurchLine.Next;
        PurchLine.TestField(Type, PurchLine.Type::"G/L Account");
        Assert.RecordCount(PurchLine, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPurchOrdFailsWithBlankInvRndAcc()
    var
        OriginalPurchHeader: Record "Purchase Header";
        DestinationPurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Vendor: Record Vendor;
        OldGLAccountNo: Code[20];
    begin
        // [FEATURE] [Invoice Rounding] [Purchase]
        // [SCENARIO] Copy Document should not fail trying to copy a line of Type "G/L Account" when "Invoice Rounding Account" is not defined
        Initialize;
        LibraryPurchase.SetInvoiceRounding(true);

        // [GIVEN] Vendor with Vendor Posting Group, where "Invoice Rounding Account" is blank
        LibraryPurchase.CreateVendor(Vendor);
        OldGLAccountNo := SetPurchInvoiceRoundingAccount(Vendor."Vendor Posting Group", '');

        // [GIVEN] Order "1001" with one line of Type "G/L Account"
        LibraryPurchase.CreatePurchHeader(
          OriginalPurchHeader, OriginalPurchHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, OriginalPurchHeader, PurchLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup, 1);

        // [WHEN] Copy Document "1001" to new Order "1002"
        CreatePurchHeaderForVendor(
          DestinationPurchHeader, DestinationPurchHeader."Document Type"::Order, OriginalPurchHeader."Buy-from Vendor No.");
        RunCopyPurchaseDoc(
          OriginalPurchHeader."No.", DestinationPurchHeader,
          MapperPurchaseHeaders(OriginalPurchHeader."Document Type"), false, false);

        // [THEN] New document with single line is created
        PurchLine.SetRange("Document Type", DestinationPurchHeader."Document Type");
        PurchLine.SetRange("Document No.", DestinationPurchHeader."No.");
        PurchLine.SetRange("No.", PurchLine."No.");
        Assert.RecordCount(PurchLine, 1);

        SetPurchInvoiceRoundingAccount(Vendor."Vendor Posting Group", OldGLAccountNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPurchOrdWithBlankInvRndAcc()
    var
        OriginalPurchHeader: Record "Purchase Header";
        DestinationPurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        Vendor: Record Vendor;
        OldGLAccountNo: Code[20];
    begin
        // [FEATURE] [Invoice Rounding] [Purchase]
        // [SCENARIO] Copy Document should copy a line of Type "G/L Account" and blank "No." when "Invoice Rounding Account" is not defined
        Initialize;

        // [GIVEN] Vendor with Vendor Posting Group, where "Invoice Rounding Account" is blank
        LibraryPurchase.CreateVendor(Vendor);
        OldGLAccountNo := SetPurchInvoiceRoundingAccount(Vendor."Vendor Posting Group", '');

        // [GIVEN] Order "1001" with one line of Type "G/L Account", where "No." is blank
        LibraryPurchase.CreatePurchHeader(
          OriginalPurchHeader, OriginalPurchHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchLine, OriginalPurchHeader, PurchLine.Type::"G/L Account", '', 0);
        PurchLine."No." := '';
        PurchLine.Modify();

        // [WHEN] Copy Document "1001" to new Order "1002"
        CreatePurchHeaderForVendor(
          DestinationPurchHeader, DestinationPurchHeader."Document Type"::Order, OriginalPurchHeader."Buy-from Vendor No.");
        RunCopyPurchaseDoc(
          OriginalPurchHeader."No.", DestinationPurchHeader,
          MapperPurchaseHeaders(OriginalPurchHeader."Document Type"), false, false);

        // [THEN] One line is copied
        PurchLine.SetRange("Document Type", DestinationPurchHeader."Document Type");
        PurchLine.SetRange("Document No.", DestinationPurchHeader."No.");
        Assert.AreEqual(1, PurchLine.Count, OneLineShouldBeCopiedErr);
        PurchLine.FindFirst;
        PurchLine.TestField("No.", '');

        // Tear Down
        SetPurchInvoiceRoundingAccount(Vendor."Vendor Posting Group", OldGLAccountNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPurchOrd()
    var
        OriginalPurchHeader: Record "Purchase Header";
        DestinationPurchHeader: Record "Purchase Header";
        OriginalDocType: Enum "Purchase Document Type";
        DestinationDocType: Enum "Purchase Document Type";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Purchase Document is copied with options CopyHeader = FALSE and RecalculateLine = FALSE
        Initialize;

        DestinationDocType := LibraryRandom.RandInt(6) - 1;
        OriginalDocType := LibraryRandom.RandInt(6) - 1;

        CreateOneItemPurchDoc(OriginalPurchHeader, OriginalDocType);

        // If Copy Purch Document is ran with IncludeHeader=False is mandatory to have the same vendor in original and destination doc.
        CreatePurchHeaderForVendor(DestinationPurchHeader, DestinationDocType, OriginalPurchHeader."Buy-from Vendor No.");

        // 2. Exercise
        RunCopyPurchaseDoc(
          OriginalPurchHeader."No.", DestinationPurchHeader,
          MapperPurchaseHeaders(OriginalPurchHeader."Document Type"), false, false);

        // 3. Validation
        // Validate the line is price is the same as in original document because recalculate lines was not enabled.
        DestinationPurchHeader.Get(DestinationPurchHeader."Document Type", DestinationPurchHeader."No.");
        VerifyPurchaseLinesAreEqual(OriginalPurchHeader, DestinationPurchHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopySalesOrdCopyHeadRecalcLine()
    var
        Item: Record Item;
        OriginalSalesLine: Record "Sales Line";
        DestinationSalesLine: Record "Sales Line";
        SalesLineDiscount: Record "Sales Line Discount";
        OriginalSalesHeader: Record "Sales Header";
        DestinationSalesHeader: Record "Sales Header";
        PriceListLine: Record "Price List Line";
        OriginalDocType: Enum "Sales Document Type";
        DestinationDocType: Enum "Sales Document Type";
        ItemCost: Integer;
        ItemPrice: Integer;
        ExpectedDiscount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Sales Document is copied with options CopyHeader = TRUE and RecalculateLine = TRUE
        Initialize;
        PrepareSalesTest(Item, OriginalDocType, DestinationDocType, ItemCost, ItemPrice);

        // Create original Sales document without discount specified.
        CreateOneItemSalesDocWithItem(OriginalSalesHeader, Item, OriginalDocType);

        // Prepare destination document type
        DestinationSalesHeader.Init();
        DestinationSalesHeader.Validate("Document Type", DestinationDocType);
        DestinationSalesHeader.Insert(true);

        CreateCustomerItemDiscount(SalesLineDiscount, OriginalSalesHeader."Sell-to Customer No.", Item);
        ExpectedDiscount := SalesLineDiscount."Line Discount %";
        CopyFromToPriceListLine.CopyFrom(SalesLineDiscount, PriceListLine);
        // 2. Exercise
        RunCopySalesDoc(
          OriginalSalesHeader."No.", DestinationSalesHeader,
          MapperSalesHeaders(OriginalSalesHeader."Document Type"), true, true);

        // 3. Validation
        DestinationSalesHeader.Get(DestinationSalesHeader."Document Type", DestinationSalesHeader."No.");
        VerifySalesHeadersAreEqual(OriginalSalesHeader, DestinationSalesHeader);
        DestinationSalesHeader.TestField("Quote No.", '');

        // Assumes only one line of each type exists in the Sales order.
        FindFirstLineOfSalesDocument(OriginalSalesHeader, OriginalSalesLine);
        FindFirstLineOfSalesDocument(DestinationSalesHeader, DestinationSalesLine);

        ValidateSalesLine(DestinationSalesLine, OriginalSalesLine.Quantity, ItemPrice, ExpectedDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopySalesOrdCopyHead()
    var
        OriginalSalesHeader: Record "Sales Header";
        DestinationSalesHeader: Record "Sales Header";
        Item: Record Item;
        SalesLineDiscount: Record "Sales Line Discount";
        OriginalDocType: Enum "Sales Document Type";
        DestinationDocType: Enum "Sales Document Type";
        ItemCost: Integer;
        ItemPrice: Integer;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Sales Document is copied with options CopyHeader = TRUE and RecalculateLine = FALSE
        Initialize;
        PrepareSalesTest(Item, OriginalDocType, DestinationDocType, ItemCost, ItemPrice);

        // Create original Sales document without discount specified.
        CreateOneItemSalesDocWithItem(OriginalSalesHeader, Item, OriginalDocType);

        // Create destination Sales header
        CreateSalesHeader(DestinationSalesHeader, DestinationDocType);

        // Order date should be today otherwise the discount we created won't be able to apply
        DestinationSalesHeader.Validate("Order Date", WorkDate);
        DestinationSalesHeader.Modify(true);

        CreateCustomerItemDiscount(SalesLineDiscount, OriginalSalesHeader."Sell-to Customer No.", Item);

        // 2. Exercise
        RunCopySalesDoc(
          OriginalSalesHeader."No.", DestinationSalesHeader,
          MapperSalesHeaders(OriginalSalesHeader."Document Type"), true, false);

        // 3. Validation
        DestinationSalesHeader.Get(DestinationSalesHeader."Document Type", DestinationSalesHeader."No.");
        VerifySalesHeadersAreEqual(OriginalSalesHeader, DestinationSalesHeader);

        // Quantity, unit price and discount should be same as original although now a discount exists for this item and vendor.
        VerifySalesLinesAreEqual(OriginalSalesHeader, DestinationSalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopySalesOrdRecalcLine()
    var
        OriginalSalesHeader: Record "Sales Header";
        DestinationSalesHeader: Record "Sales Header";
        SalesLineDiscount: Record "Sales Line Discount";
        Item: Record Item;
        Customer: Record Customer;
        DestinationSalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        OriginalDocType: Enum "Sales Document Type";
        DestinationDocType: Enum "Sales Document Type";
        ItemCost: Integer;
        ItemPrice: Integer;
        ExpectedDiscount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Sales Document is copied with options CopyHeader = FALSE and RecalculateLine = TRUE
        Initialize;
        PrepareSalesTest(Item, OriginalDocType, DestinationDocType, ItemCost, ItemPrice);

        CreateOneItemSalesDocWithItem(OriginalSalesHeader, Item, OriginalDocType);

        // Create 2nd customer to invoice
        LibrarySales.CreateCustomer(Customer);

        // If Copy Sales Document is ran with IncludeHeader=False is mandatory to have the same vendor in original and destination doc.
        CreateSalesHeaderForCustomer(DestinationSalesHeader, DestinationDocType, Customer."No.");

        // Order date should be today otherwise the discount we will create won't apply
        DestinationSalesHeader.Validate("Order Date", WorkDate);
        DestinationSalesHeader.Modify(true);

        CreateCustomerItemDiscount(SalesLineDiscount, Customer."No.", Item);
        ExpectedDiscount := SalesLineDiscount."Line Discount %";
        CopyFromToPriceListLine.CopyFrom(SalesLineDiscount, PriceListLine);
        // 2. Exercise
        RunCopySalesDoc(
          OriginalSalesHeader."No.", DestinationSalesHeader,
          MapperSalesHeaders(OriginalSalesHeader."Document Type"), false, true);

        // 3. Validation
        // Validate the line is right (don't care about the header because it has not been copied).
        // Line prices should be recalculated according to the new vendor prices considering the discount.
        // Refresh new Sales header after the copy
        DestinationSalesHeader.Get(DestinationSalesHeader."Document Type", DestinationSalesHeader."No.");

        // Assumes only one line of each type exists in the Sales order.
        FindFirstLineOfSalesDocument(OriginalSalesHeader, OriginalSalesLine);
        FindFirstLineOfSalesDocument(DestinationSalesHeader, DestinationSalesLine);

        ValidateSalesLine(DestinationSalesLine, OriginalSalesLine.Quantity, ItemPrice, ExpectedDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopySalesOrdWithInvRoundingLine()
    var
        OriginalSalesHeader: Record "Sales Header";
        DestinationSalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InvRoundingAccNo: Code[20];
    begin
        // [FEATURE] [Invoice Rounding] [Sales]
        // [SCENARIO 140138] Copy Document should not skip a sales line that has Item's "No." equal to "Invoice Rounding Account"
        Initialize;

        // [GIVEN] Order "1001" with two lines:
        // [GIVEN] The 1st line of Type "Item", where "No." is "IRA"
        CreateOneItemSalesDoc(OriginalSalesHeader, OriginalSalesHeader."Document Type"::Order);
        // [GIVEN] Vendor with Customer Posting Group, where "Invoice Rounding Account" = "IRA"
        FindFirstLineOfSalesDocument(OriginalSalesHeader, SalesLine);
        InvRoundingAccNo := SalesLine."No.";
        SetSalesInvoiceRoundingAccount(OriginalSalesHeader."Customer Posting Group", CreateSalesGLAccNo(InvRoundingAccNo));
        // [GIVEN] The 2nd line of Type "G/L Account", where "No." is "IRA"
        LibrarySales.CreateSalesLine(SalesLine, OriginalSalesHeader, SalesLine.Type::"G/L Account", InvRoundingAccNo, 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);

        // [WHEN] Copy Document "1001" to new Order "1002"
        CreateSalesHeaderForCustomer(
          DestinationSalesHeader, DestinationSalesHeader."Document Type"::Order, OriginalSalesHeader."Sell-to Customer No.");
        RunCopySalesDoc(
          OriginalSalesHeader."No.", DestinationSalesHeader,
          MapperSalesHeaders(OriginalSalesHeader."Document Type"), false, false);

        // [THEN] Order "1002" contains two lines, where "Type" is "Item" and "G/L Account", where "No." is "IRA"
        SalesLine.SetRange("Document Type", DestinationSalesHeader."Document Type");
        SalesLine.SetRange("Document No.", DestinationSalesHeader."No.");
        SalesLine.SetRange("No.", InvRoundingAccNo);
        SalesLine.FindSet;
        SalesLine.TestField(Type, SalesLine.Type::Item);
        SalesLine.Next;
        SalesLine.TestField(Type, SalesLine.Type::"G/L Account");
        Assert.RecordCount(SalesLine, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopySalesOrdFailsWithBlankInvRndAcc()
    var
        OriginalSalesHeader: Record "Sales Header";
        DestinationSalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        OldGLAccountNo: Code[20];
    begin
        // [FEATURE] [Invoice Rounding] [Sales]
        // [SCENARIO] Copy Document should not fail trying to copy a line of Type "G/L Account" when "Invoice Rounding Account" is not defined
        Initialize;

        // [GIVEN] Customer with Customer Posting Group, where "Invoice Rounding Account" is blank
        LibrarySales.CreateCustomer(Customer);
        OldGLAccountNo := SetSalesInvoiceRoundingAccount(Customer."Customer Posting Group", '');

        // [GIVEN] Order "1001" with one line of Type "G/L Account"
        LibrarySales.CreateSalesHeader(
          OriginalSalesHeader, OriginalSalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine, OriginalSalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup, 1);

        // [WHEN] Copy Document "1001" to new Order "1002"
        CreateSalesHeaderForCustomer(
          DestinationSalesHeader, DestinationSalesHeader."Document Type"::Order, OriginalSalesHeader."Sell-to Customer No.");
        RunCopySalesDoc(
          OriginalSalesHeader."No.", DestinationSalesHeader,
          MapperSalesHeaders(OriginalSalesHeader."Document Type"), false, false);

        // [THEN] New document created with the single line
        SalesLine.SetRange("Document Type", DestinationSalesHeader."Document Type");
        SalesLine.SetRange("Document No.", DestinationSalesHeader."No.");
        SalesLine.SetRange("No.", SalesLine."No.");
        Assert.RecordCount(SalesLine, 1);

        SetSalesInvoiceRoundingAccount(Customer."Customer Posting Group", OldGLAccountNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopySalesOrdWithBlankInvRndAcc()
    var
        OriginalSalesHeader: Record "Sales Header";
        DestinationSalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        OldGLAccountNo: Code[20];
    begin
        // [FEATURE] [Invoice Rounding] [Sales]
        // [SCENARIO] Copy Document should copy a line of Type "G/L Account" and blank "No." when "Invoice Rounding Account" is not defined
        Initialize;

        // [GIVEN] Customer with Customer Posting Group, where "Invoice Rounding Account" is blank
        LibrarySales.CreateCustomer(Customer);
        OldGLAccountNo := SetSalesInvoiceRoundingAccount(Customer."Customer Posting Group", '');

        // [GIVEN] Order "1001" with one line of Type "G/L Account", where "No." is blank
        LibrarySales.CreateSalesHeader(
          OriginalSalesHeader, OriginalSalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, OriginalSalesHeader, SalesLine.Type::"G/L Account", '', 0);
        SalesLine."No." := '';
        SalesLine.Modify();

        // [WHEN] Copy Document "1001" to new Order "1002"
        CreateSalesHeaderForCustomer(
          DestinationSalesHeader, DestinationSalesHeader."Document Type"::Order, OriginalSalesHeader."Sell-to Customer No.");
        RunCopySalesDoc(
          OriginalSalesHeader."No.", DestinationSalesHeader,
          MapperSalesHeaders(OriginalSalesHeader."Document Type"), false, false);

        // [THEN] One line is copied
        SalesLine.SetRange("Document Type", DestinationSalesHeader."Document Type");
        SalesLine.SetRange("Document No.", DestinationSalesHeader."No.");
        Assert.AreEqual(1, SalesLine.Count, OneLineShouldBeCopiedErr);
        SalesLine.FindFirst;
        SalesLine.TestField("No.", '');

        // Tear Down
        SetSalesInvoiceRoundingAccount(Customer."Customer Posting Group", OldGLAccountNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopySalesOrd()
    var
        OriginalSalesHeader: Record "Sales Header";
        DestinationSalesHeader: Record "Sales Header";
        OriginalDocType: Enum "Sales Document Type";
        DestinationDocType: Enum "Sales Document Type";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Sales Document is copied with options CopyHeader = FALSE and RecalculateLine = FALSE
        Initialize;

        DestinationDocType := LibraryRandom.RandInt(6) - 1;
        OriginalDocType := LibraryRandom.RandInt(6) - 1;

        CreateOneItemSalesDoc(OriginalSalesHeader, OriginalDocType);

        // If Copy Sales Document is ran with IncludeHeader=False is mandatory to have the same customer in original and destination doc.
        CreateSalesHeaderForCustomer(DestinationSalesHeader, DestinationDocType, OriginalSalesHeader."Sell-to Customer No.");

        // 2. Exercise
        RunCopySalesDoc(
          OriginalSalesHeader."No.", DestinationSalesHeader,
          MapperSalesHeaders(OriginalSalesHeader."Document Type"), false, false);

        // 3. Validation
        // Validate the line is price is the same as in original document because recalculate lines was not enabled.
        DestinationSalesHeader.Get(DestinationSalesHeader."Document Type", DestinationSalesHeader."No.");
        VerifySalesLinesAreEqual(OriginalSalesHeader, DestinationSalesHeader);
    end;

    [Test]
    [HandlerFunctions('CopySalesDocReportHandlerOKWithEmptyDocumentNo')]
    [Scope('OnPrem')]
    procedure CopySalesOrdWithEmptySrcDocumentNoThrowsError()
    var
        OriginalSalesHeader: Record "Sales Header";
        DestinationSalesHeader: Record "Sales Header";
        OriginalDocType: Enum "Sales Document Type";
        DestinationDocType: Enum "Sales Document Type";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Copy of Sales Document without specifying a source document no. fails
        Initialize;

        DestinationDocType := LibraryRandom.RandInt(6) - 1;
        OriginalDocType := LibraryRandom.RandInt(6) - 1;

        CreateOneItemSalesDoc(OriginalSalesHeader, OriginalDocType);

        // If Copy Sales Document is ran with IncludeHeader=False is mandatory to have the same customer in original and destination doc.
        CreateSalesHeaderForCustomer(DestinationSalesHeader, DestinationDocType, OriginalSalesHeader."Sell-to Customer No.");

        // 2. Exercise
        Commit();
        asserterror RunCopySalesDocWithRequestPage(
            OriginalSalesHeader."No.", DestinationSalesHeader,
            MapperSalesHeaders(OriginalSalesHeader."Document Type"), false, false, true);

        // 3. Validation
        // Error mentioned the dicument number is thrown.
        Assert.ExpectedError('document number');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPostedSalesOrderToDoc()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        DestinationSalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Extended Text]
        // [SCENARIO 375365] Extended text lines should be copied to Document from Posted Sales Order preserving the original order.
        Initialize;

        // [GIVEN] Posted Sales Order with 2 lines of extended text divided by an empty line.
        CreateSalesDocWithExtLines(SalesHeader, SalesHeader."Document Type"::Order);
        SetSalesInvoiceRoundingAccount(SalesHeader."Customer Posting Group", LibraryERM.CreateGLAccountWithSalesSetup);
        SalesInvHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Copy Sales Document.
        CreateSalesHeaderForCustomer(
          DestinationSalesHeader, DestinationSalesHeader."Document Type"::Invoice, SalesHeader."Sell-to Customer No.");
        RunCopySalesDoc(
          SalesInvHeader."No.", DestinationSalesHeader, SalesDocType::"Posted Invoice", false, false);

        // [THEN] Copied Sales Document gets 2 lines of extended text divided by an empty line.
        SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
        VerifyCopiedSalesLines(
          SalesInvLine, SalesInvLine.FieldNo(Type), SalesInvLine.FieldNo(Description),
          DestinationSalesHeader."Document Type", DestinationSalesHeader."No.");
        // [THEN] 2 extended text lines are attached to item line // TFS 215250
        VerifySalesAttachedLines(DestinationSalesHeader, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyShippedSalesOrderToDoc()
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        DestinationSalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Extended Text]
        // [SCENARIO 375365] Extended text lines should be copied to Document from Shipped Sales Order preserving the original order.
        Initialize;

        // [GIVEN] Shipped Sales Order with 2 lines of extended text divided by an empty line.
        CreateSalesDocWithExtLines(SalesHeader, SalesHeader."Document Type"::Order);
        SalesShipmentHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, false));

        // [WHEN] Copy Sales Document.
        CreateSalesHeaderForCustomer(
          DestinationSalesHeader, DestinationSalesHeader."Document Type"::Invoice, SalesHeader."Sell-to Customer No.");
        RunCopySalesDoc(
          SalesShipmentHeader."No.", DestinationSalesHeader, SalesDocType::"Posted Shipment", false, false);

        // [THEN] Copied Sales Document gets 2 lines of extended text divided by an empty line.
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        VerifyCopiedSalesLines(
          SalesShipmentLine, SalesShipmentLine.FieldNo(Type), SalesShipmentLine.FieldNo(Description),
          DestinationSalesHeader."Document Type", DestinationSalesHeader."No.");
        // [THEN] 2 extended text lines are attached to item line // TFS 215250
        VerifySalesAttachedLines(DestinationSalesHeader, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPostedSalesCrMToDoc()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        DestinationSalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Extended Text]
        // [SCENARIO 375365] Extended text lines should be copied to Document from Posted Sales Credit Memo preserving the original order.
        Initialize;

        // [GIVEN] Posted Sales Credit Memo with 2 lines of extended text divided by an empty line.
        CreateSalesDocWithExtLines(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        SetSalesInvoiceRoundingAccount(SalesHeader."Customer Posting Group", LibraryERM.CreateGLAccountWithSalesSetup);
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [WHEN] Copy Sales Document.
        CreateSalesHeaderForCustomer(
          DestinationSalesHeader, DestinationSalesHeader."Document Type"::Invoice, SalesHeader."Sell-to Customer No.");
        RunCopySalesDoc(
          SalesCrMemoHeader."No.", DestinationSalesHeader, SalesDocType::"Posted Credit Memo", false, false);

        // [THEN] Copied Sales Document gets 2 lines of extended text divided by an empty line.
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        VerifyCopiedSalesLines(
          SalesCrMemoLine, SalesCrMemoLine.FieldNo(Type), SalesCrMemoLine.FieldNo(Description),
          DestinationSalesHeader."Document Type", DestinationSalesHeader."No.");
        // [THEN] 2 extended text lines are attached to item line // TFS 215250
        VerifySalesAttachedLines(DestinationSalesHeader, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPostedSalesReturnOrderToDoc()
    var
        SalesHeader: Record "Sales Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
        ReturnReceiptLine: Record "Return Receipt Line";
        DestinationSalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Extended Text]
        // [SCENARIO 375365] Extended text lines should be copied to Document from Posted Sales Return Order preserving the original order.
        Initialize;

        // [GIVEN] Posted Sales Return Order with 2 lines of extended text divided by an empty line.
        CreateSalesDocWithExtLines(SalesHeader, SalesHeader."Document Type"::"Return Order");
        ReturnReceiptHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, false));

        // [WHEN] Copy Sales Document.
        CreateSalesHeaderForCustomer(
          DestinationSalesHeader, DestinationSalesHeader."Document Type"::Invoice, SalesHeader."Sell-to Customer No.");
        RunCopySalesDoc(
          ReturnReceiptHeader."No.", DestinationSalesHeader, SalesDocType::"Posted Return Receipt", false, false);

        // [THEN] Copied Sales Document gets 2 lines of extended text divided by an empty line.
        ReturnReceiptLine.SetRange("Document No.", ReturnReceiptHeader."No.");
        VerifyCopiedSalesLines(
          ReturnReceiptLine, ReturnReceiptLine.FieldNo(Type), ReturnReceiptLine.FieldNo(Description),
          DestinationSalesHeader."Document Type", DestinationSalesHeader."No.");
        // [THEN] 2 extended text lines are attached to item line // TFS 215250
        VerifySalesAttachedLines(DestinationSalesHeader, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPostedPurchaseOrderToDoc()
    var
        PurchHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        DestinationPurchHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Extended Text]
        // [SCENARIO 375365] Extended text lines should be copied to Document from Posted Purchase Order preserving the original order.
        Initialize;

        // [GIVEN] Posted Purchase Order with 2 lines with extended text divided by an empty line.
        CreatePurchDocWithExtLines(PurchHeader, PurchHeader."Document Type"::Order);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));

        // [WHEN] Copy Purchase Document.
        CreatePurchHeaderForVendor(
          DestinationPurchHeader, DestinationPurchHeader."Document Type"::Invoice, PurchHeader."Buy-from Vendor No.");
        RunCopyPurchaseDoc(
          PurchInvHeader."No.", DestinationPurchHeader, PurchDocType::"Posted Invoice", false, false);

        // [THEN] Copied Purchase Document gets 2 lines of extended text divided by an empty line.
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        VerifyCopiedPurchLines(
          PurchInvLine, PurchInvLine.FieldNo(Type), PurchInvLine.FieldNo(Description),
          DestinationPurchHeader."Document Type", DestinationPurchHeader."No.");
        // [THEN] 2 extended text lines are attached to item line // TFS 215250
        VerifyPurchaseAttachedLines(DestinationPurchHeader, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyReceiptPurchaseOrderToDoc()
    var
        PurchHeader: Record "Purchase Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        DestinationPurchHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Extended Text]
        // [SCENARIO 375365] Extended text lines should be copied to Document from Receipt Purchase Order preserving the original order.
        Initialize;

        // [GIVEN] Receipt Purchase Order with 2 lines with extended text divided by an empty line.
        CreatePurchDocWithExtLines(PurchHeader, PurchHeader."Document Type"::Order);
        PurchRcptHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false));

        // [WHEN] Copy Purchase Document.
        CreatePurchHeaderForVendor(
          DestinationPurchHeader, DestinationPurchHeader."Document Type"::Invoice, PurchHeader."Buy-from Vendor No.");
        RunCopyPurchaseDoc(
          PurchRcptHeader."No.", DestinationPurchHeader, PurchDocType::"Posted Receipt", false, false);

        // [THEN] Copied Purchase Document gets 2 lines of extended text divided by an empty line.
        PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
        VerifyCopiedPurchLines(
          PurchRcptLine, PurchRcptLine.FieldNo(Type), PurchRcptLine.FieldNo(Description),
          DestinationPurchHeader."Document Type", DestinationPurchHeader."No.");
        // [THEN] 2 extended text lines are attached to item line // TFS 215250
        VerifyPurchaseAttachedLines(DestinationPurchHeader, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPostedPurchaseCrMToDoc()
    var
        PurchHeader: Record "Purchase Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        DestinationPurchHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Extended Text]
        // [SCENARIO 375365] Extended text lines should be copied to Document from Posted Purchase Credit Memo preserving the original order.
        Initialize;

        // [GIVEN] Posted Purchase Credit Memo with 2 lines with extended text divided by an empty line.
        CreatePurchDocWithExtLines(PurchHeader, PurchHeader."Document Type"::"Credit Memo");
        PurchCrMemoHdr.Get(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));

        // [WHEN] Copy Purchase Document.
        CreatePurchHeaderForVendor(
          DestinationPurchHeader, DestinationPurchHeader."Document Type"::Invoice, PurchHeader."Buy-from Vendor No.");
        RunCopyPurchaseDoc(
          PurchCrMemoHdr."No.", DestinationPurchHeader, PurchDocType::"Posted Credit Memo", false, false);

        // [THEN] Copied Purchase Document gets 2 lines of extended text divided by an empty line.
        PurchCrMemoLine.SetRange("Document No.", PurchCrMemoHdr."No.");
        VerifyCopiedPurchLines(
          PurchCrMemoLine, PurchCrMemoLine.FieldNo(Type), PurchCrMemoLine.FieldNo(Description),
          DestinationPurchHeader."Document Type", DestinationPurchHeader."No.");
        // [THEN] 2 extended text lines are attached to item line // TFS 215250
        VerifyPurchaseAttachedLines(DestinationPurchHeader, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPostedPurchaseReturnOrderToDoc()
    var
        PurchHeader: Record "Purchase Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
        ReturnShipmentLine: Record "Return Shipment Line";
        DestinationPurchHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Extended Text]
        // [SCENARIO 375365] Extended text lines should be copied to Document from Posted Purchase Return Order preserving the original order.
        Initialize;

        // [GIVEN] Posted Purchase Return Order with 2 lines with extended text divided by an empty line.
        CreatePurchDocWithExtLines(PurchHeader, PurchHeader."Document Type"::"Return Order");
        ReturnShipmentHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false));

        // [WHEN] Copy Purchase Document.
        CreatePurchHeaderForVendor(
          DestinationPurchHeader, DestinationPurchHeader."Document Type"::Invoice, PurchHeader."Buy-from Vendor No.");
        RunCopyPurchaseDoc(
          ReturnShipmentHeader."No.", DestinationPurchHeader, PurchDocType::"Posted Return Shipment", false, false);

        // [THEN] Copied Purchase Document gets 2 lines of extended text divided by an empty line.
        ReturnShipmentLine.SetRange("Document No.", ReturnShipmentHeader."No.");
        VerifyCopiedPurchLines(
          ReturnShipmentLine, ReturnShipmentLine.FieldNo(Type), ReturnShipmentLine.FieldNo(Description),
          DestinationPurchHeader."Document Type", DestinationPurchHeader."No.");
        // [THEN] 2 extended text lines are attached to item line // TFS 215250
        VerifyPurchaseAttachedLines(DestinationPurchHeader, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPostedSalesInvoiceDescriptionItemLine()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        PostedDocNo: Code[20];
        Description: Text[100];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 378530] Copy posted Sales Invoice description line with Type = Item
        Initialize;

        // [GIVEN] Posted Sales Order with two lines:
        // [GIVEN] Line1: Type = "Item", No="1000", Description = "Bicycle"
        // [GIVEN] Line2: Type = "Item", No="", Description = "Description Line"
        PostedDocNo := CreatePostSalesDocWithItemDescriptionLine(CustomerNo, Description);
        // [GIVEN] Create a new Sales Order.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);

        // [WHEN] Run CopyDocument. Use posted Invoice. "Include Header" = TRUE, "Recalculate Lines" = FALSE
        RunCopySalesDoc(PostedDocNo, SalesHeader, SalesDocType::"Posted Invoice", true, false);

        // [THEN] Item description line has been copied: Type = "", No="", Description = "Description Line"
        VerifySalesDescriptionLineExists(SalesHeader, Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPostedPurchInvoiceDescriptionItemLine()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
        PostedDocNo: Code[20];
        Description: Text[100];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 378530] Copy posted Purchase Invoice description line with Type = Item
        Initialize;

        // [GIVEN] Posted Purchase Order with two lines:
        // [GIVEN] Line1: Type = "Item", No="1000", Description = "Bicycle"
        // [GIVEN] Line2: Type = "Item", No="", Description = "Description Line"
        PostedDocNo := CreatePostPurchDocWithItemDescriptionLine(VendorNo, Description);
        // [GIVEN] Create a new Purchase Order.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);

        // [WHEN] Run CopyDocument. Use posted Invoice. "Include Header" = TRUE, "Recalculate Lines" = FALSE
        RunCopyPurchaseDoc(PostedDocNo, PurchaseHeader, PurchDocType::"Posted Invoice", true, false);

        // [THEN] Item description line has been copied: Type = "", No="", Description = "Description Line"
        VerifyPurchDescriptionLineExists(PurchaseHeader, Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShiptoAddrOfCompanyAfterCopySalesInvToCrMemo()
    var
        SalesHeader: Record "Sales Header";
        PostedSalesDocNo: Code[20];
    begin
        // [FEATURE] [Sales][Credit Memo]
        // [SCENARIO 381712] Ship-to address of Credit Memo have to contains Ship-to Address of Company after copying Sales Invoice to Credit Memo
        Initialize;

        // [GIVEN] Company Information with "Ship-to Address" = "SA"
        UpdateShiptoAddrOfCompany;

        // [GIVEN] Posted Sales Invoice "PSI"
        PostedSalesDocNo := CreatePostSalesDocWithShiptoAddr(SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo, '');

        // [GIVEN] New Credit Memo "CM"
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo");

        // [WHEN] Run copy sales document - "PSI" -> "CM"
        RunCopySalesDoc(PostedSalesDocNo, SalesHeader, SalesDocType::"Posted Invoice", true, false);

        // [THEN] Ship-to address fields of "CM" are equal to "SA"
        VerifyShiptoAddressInSalesDocToCompanyInfo(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShiptoAddrOfCustomerAfterCopyCrMemoToSalesInv()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        PostedSalesDocNo: Code[20];
    begin
        // [FEATURE] [Sales][Invoice]
        // [SCENARIO 381712] Ship-to address of Sales Invoice have to contains Address of Customer after copying Credit Memo to Sales Invoice
        Initialize;

        // [GIVEN] Customer with address = "A"
        CreateCustomerWithShiptoAddr(Customer);

        // [GIVEN] Company Info with Ship-to Address
        UpdateShiptoAddrOfCompany;

        // [GIVEN] Posted Sales Credit Memo = "PCM"
        PostedSalesDocNo := CreatePostSalesDocWithShiptoAddr(SalesHeader."Document Type"::"Credit Memo", Customer."No.", '');

        // [GIVEN] New Sales Invoice = "SI"
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice);

        // [WHEN] Run copy sales document - "PCM" -> "SI"
        RunCopySalesDoc(PostedSalesDocNo, SalesHeader, SalesDocType::"Posted Credit Memo", true, false);

        // [THEN] Ship-to address fields of "SI" are equal to "A"
        VerifyShiptoAddressSalesDocToCustomerAddress(SalesHeader, Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShiptoAddrSalesInvAfterPostInvCopyCrMemo()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ShiptoAddressCode: Code[10];
        PostedSalesDocNo: Code[20];
    begin
        // [FEATURE] [Sales][Invoice]
        // [SCENARIO 381712] Ship-to address of Sales Invoice have to contains Ship-to address original invoice after copying from credit memo
        Initialize;

        // [GIVEN] Customer with "Ship-to Address" = "SA"
        ShiptoAddressCode := CreateCustomerWithShiptoAddr(Customer);

        // [GIVEN] Posted sales invoice "PSI1" with "Ship-to Code" = "SA"
        PostedSalesDocNo := CreatePostSalesDocWithShiptoAddr(SalesHeader."Document Type"::Invoice, Customer."No.", ShiptoAddressCode);

        // [GIVEN] Copied and posted credit memo "PCM" from invoice "PSI1"; "PSI1" -> "PCM"
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        RunCopySalesDoc(PostedSalesDocNo, SalesHeader, SalesDocType::"Posted Invoice", true, false);
        SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", SalesHeader."No.");
        PostedSalesDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] New sales invoice "SI"
        Clear(SalesHeader);
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice);

        // [WHEN] Run copy sales document - "PCM" -> "SI"
        RunCopySalesDoc(PostedSalesDocNo, SalesHeader, SalesDocType::"Posted Credit Memo", true, false);

        // [THEN] "Ship-to Code" and Ship-to Address field of "SI" are equal to "SA"
        VerifyShiptoAddressSalesDocToShiptoAddress(SalesHeader, Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShiptoAddrSalesInvAfterPostInvWithoutShiptoAddrCopyCrMemo()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        PostedSalesDocNo: Code[20];
    begin
        // [FEATURE] [Sales][Invoice]
        // [SCENARIO 381712] Ship-to address of Sales Invoice have to contains address of Customer if Ship-to address of original invoice is empty after copying from credit memo
        Initialize;

        // [GIVEN] Customer with "Ship-to Address" = "SA" and Address = "A"
        CreateCustomerWithShiptoAddr(Customer);

        // [GIVEN] Posted sales invoice "PSI1" with "Ship-to Code" = <empty>
        PostedSalesDocNo := CreatePostSalesDocWithShiptoAddr(SalesHeader."Document Type"::Invoice, Customer."No.", '');

        // [GIVEN] Copied and posted credit memo "PCM" from invoice "PSI1"; "PSI1" -> "PCM"
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        RunCopySalesDoc(PostedSalesDocNo, SalesHeader, SalesDocType::"Posted Invoice", true, false);
        SalesHeader.Get(SalesHeader."Document Type"::"Credit Memo", SalesHeader."No.");
        PostedSalesDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] New sales invoice "SI"
        Clear(SalesHeader);
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice);

        // [WHEN] Run copy sales document - "PCM" -> "SI"
        RunCopySalesDoc(PostedSalesDocNo, SalesHeader, SalesDocType::"Posted Credit Memo", true, false);

        // [THEN] "Ship-to Code" and Ship-to Address field of "SI" are equal to "A"
        VerifyShiptoAddressSalesDocToCustomerAddress(SalesHeader, Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemo_GetPstdDocLinesToRev_TwoDocs_GLAccounts()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        GLAccountNo: array[2] of Code[20];
        InvoiceNo: array[2] of Code[20];
    begin
        // [FEATURE] [Sales] [Credit Memo] [Get Posted Document Lines to Reverse] [G/L Account]
        // [SCENARIO 382275] Sales Credit Memo "Get Posted Document Lines to Reverse" from two Invoices (G/L Account)
        Initialize;
        CustomerNo := LibrarySales.CreateCustomerNo;

        // [GIVEN] Posted sales invoice "I1" with line "Type" = "G/L Account", "No." = "GLAcc1"
        // [GIVEN] Posted sales invoice "I2" with line "Type" = "G/L Account", "No." = "GLAcc2"
        CreatePostSalesOrderWithGLAccount(InvoiceNo[1], GLAccountNo[1], CustomerNo);
        CreatePostSalesOrderWithGLAccount(InvoiceNo[2], GLAccountNo[2], CustomerNo);
        // [GIVEN] A new sales credit memo
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);

        // [WHEN] Perform "Get Posted Document Lines to Reverse" action (select all lines, press OK)
        CopyPostedSalesInvoiceLines(SalesHeader);

        // [THEN] There are 4 lines have been created in sales credit memo:
        // [THEN] Line1: "Type" = "", "No." = "", "Description" = "Invoice No. I1"
        // [THEN] Line2: "Type" = "G/L Account", "No." = "GLAcc1"
        // [THEN] Line3: "Type" = "", "No." = "", "Description" = "Invoice No. I2"
        // [THEN] Line4: "Type" = "G/L Account", "No." = "GLAcc2"
        FindFirstLineOfSalesDocument(SalesHeader, SalesLine);
        Assert.RecordCount(SalesLine, 4);
        VerifySalesInvoiceDescription(SalesLine, InvoiceNo[1], GLAccountNo[1]);
        VerifySalesInvoiceDescription(SalesLine, InvoiceNo[2], GLAccountNo[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemo_GetPstdDocLinesToRev_TwoDocs_Items()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        ItemNo: array[2] of Code[20];
        InvoiceNo: array[2] of Code[20];
        ShipmentNo: array[2] of Code[20];
    begin
        // [FEATURE] [Sales] [Credit Memo] [Get Posted Document Lines to Reverse] [Item]
        // [SCENARIO 382275] Sales Credit Memo "Get Posted Document Lines to Reverse" from two Invoices (Item)
        Initialize;
        CustomerNo := LibrarySales.CreateCustomerNo;

        // [GIVEN] Posted sales invoice "I1" and shipment "S1" with line "Type" = "Item", "No." = "ITEM1"
        // [GIVEN] Posted sales invoice "I2" and shipment "S2" with line "Type" = "Item", "No." = "ITEM2"
        CreatePostSalesOrderWithItem(InvoiceNo[1], ShipmentNo[1], ItemNo[1], CustomerNo);
        CreatePostSalesOrderWithItem(InvoiceNo[2], ShipmentNo[2], ItemNo[2], CustomerNo);
        // [GIVEN] A new sales credit mMemo
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);

        // [WHEN] Perform "Get Posted Document Lines to Reverse" action (select all lines, press OK)
        CopyPostedSalesInvoiceLines(SalesHeader);

        // [THEN] There are 6 lines have been created in sales credit memo:
        // [THEN] Line1: "Type" = "", "No." = "", "Description" = "Invoice No. I1"
        // [THEN] Line2: "Type" = "", "No." = "", "Description" = "Inv. No. I1 - Shpt. No. S1"
        // [THEN] Line3: "Type" = "Item", "No." = "ITEM1"
        // [THEN] Line4: "Type" = "", "No." = "", "Description" = "Invoice No. I2"
        // [THEN] Line5: "Type" = "", "No." = "", "Description" = "Inv. No. I2 - Shpt. No. S2"
        // [THEN] Line6: "Type" = "Item", "No." = "ITEM2"
        FindFirstLineOfSalesDocument(SalesHeader, SalesLine);
        Assert.RecordCount(SalesLine, 6);
        VerifySalesInvoiceShipmentDescription(SalesLine, InvoiceNo[1], ShipmentNo[1], ItemNo[1]);
        VerifySalesInvoiceShipmentDescription(SalesLine, InvoiceNo[2], ShipmentNo[2], ItemNo[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemo_GetPstdDocLinesToRev_TwoDocs_GLAccountItem()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        GLAccountNo: Code[20];
        ItemNo: Code[20];
        InvoiceNo: array[2] of Code[20];
        ShipmentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Credit Memo] [Get Posted Document Lines to Reverse] [G/L Account] [Item]
        // [SCENARIO 382275] Sales Credit Memo "Get Posted Document Lines to Reverse" from two Invoices (G/L Account, Item)
        Initialize;
        CustomerNo := LibrarySales.CreateCustomerNo;

        // [GIVEN] Posted sales invoice "I1" with line "Type" = "G/L Account", "No." = "GLAcc"
        // [GIVEN] Posted sales invoice "I2" and shipment "S2" with line "Type" = "Item", "No." = "ITEM"
        CreatePostSalesOrderWithGLAccount(InvoiceNo[1], GLAccountNo, CustomerNo);
        CreatePostSalesOrderWithItem(InvoiceNo[2], ShipmentNo, ItemNo, CustomerNo);
        // [GIVEN] A new sales credit memo
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);

        // [WHEN] Perform "Get Posted Document Lines to Reverse" action (select all lines, press OK)
        CopyPostedSalesInvoiceLines(SalesHeader);

        // [THEN] There are 5 lines have been created in sales credit memo:
        // [THEN] Line1: "Type" = "", "No." = "", "Description" = "Invoice No. I1"
        // [THEN] Line2: "Type" = "G/L Account", "No." = "GLAcc"
        // [THEN] Line3: "Type" = "", "No." = "", "Description" = "Invoice No. I2"
        // [THEN] Line4: "Type" = "", "No." = "", "Description" = "Inv. No. I2 - Shpt. No. S2"
        // [THEN] Line5: "Type" = "Item", "No." = "ITEM"
        FindFirstLineOfSalesDocument(SalesHeader, SalesLine);
        Assert.RecordCount(SalesLine, 5);
        VerifySalesInvoiceDescription(SalesLine, InvoiceNo[1], GLAccountNo);
        VerifySalesInvoiceShipmentDescription(SalesLine, InvoiceNo[2], ShipmentNo, ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemo_GetPstdDocLinesToRev_TwoDocs_ItemGLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        GLAccountNo: Code[20];
        ItemNo: Code[20];
        InvoiceNo: array[2] of Code[20];
        ShipmentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Credit Memo] [Get Posted Document Lines to Reverse] [G/L Account] [Item]
        // [SCENARIO 382275] Sales Credit Memo "Get Posted Document Lines to Reverse" from two Invoices (Item, G/L Account)
        Initialize;
        CustomerNo := LibrarySales.CreateCustomerNo;

        // [GIVEN] Posted sales invoice "I1" and shipment "S1" with line "Type" = "Item", "No." = "ITEM"
        // [GIVEN] Posted sales invoice "I2" with line "Type" = "G/L Account", "No." = "GLAcc"
        CreatePostSalesOrderWithItem(InvoiceNo[1], ShipmentNo, ItemNo, CustomerNo);
        CreatePostSalesOrderWithGLAccount(InvoiceNo[2], GLAccountNo, CustomerNo);
        // [GIVEN] A new sales credit memo
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);

        // [WHEN] Perform "Get Posted Document Lines to Reverse" action (select all lines, press OK)
        CopyPostedSalesInvoiceLines(SalesHeader);

        // [THEN] There are 5 lines have been created in sales credit memo:
        // [THEN] Line1: "Type" = "", "No." = "", "Description" = "Invoice No. I1"
        // [THEN] Line2: "Type" = "", "No." = "", "Description" = "Inv. No. I1 - Shpt. No. S1"
        // [THEN] Line3: "Type" = "Item", "No." = "ITEM"
        // [THEN] Line4: "Type" = "", "No." = "", "Description" = "Invoice No. I2"
        // [THEN] Line5: "Type" = "G/L Account", "No." = "GLAcc"
        FindFirstLineOfSalesDocument(SalesHeader, SalesLine);
        Assert.RecordCount(SalesLine, 5);
        VerifySalesInvoiceShipmentDescription(SalesLine, InvoiceNo[1], ShipmentNo, ItemNo);
        VerifySalesInvoiceDescription(SalesLine, InvoiceNo[2], GLAccountNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemo_GetPstdDocLinesToRev_ThreeDocs_GLAccountItemGLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        GLAccountNo: array[2] of Code[20];
        ItemNo: Code[20];
        InvoiceNo: array[3] of Code[20];
        ShipmentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Credit Memo] [Get Posted Document Lines to Reverse] [G/L Account] [Item]
        // [SCENARIO 382275] Sales Credit Memo "Get Posted Document Lines to Reverse" from three Invoices (G/L Account, Item, G/L Account)
        Initialize;
        CustomerNo := LibrarySales.CreateCustomerNo;

        // [GIVEN] Posted sales invoice "I1" with line "Type" = "G/L Account", "No." = "GLAcc1"
        // [GIVEN] Posted sales invoice "I2" and shipment "S1" with line "Type" = "Item", "No." = "ITEM"
        // [GIVEN] Posted sales invoice "I3" with line "Type" = "G/L Account", "No." = "GLAcc2"
        CreatePostSalesOrderWithGLAccount(InvoiceNo[1], GLAccountNo[1], CustomerNo);
        CreatePostSalesOrderWithItem(InvoiceNo[2], ShipmentNo, ItemNo, CustomerNo);
        CreatePostSalesOrderWithGLAccount(InvoiceNo[3], GLAccountNo[2], CustomerNo);
        // [GIVEN] A new sales credit memo
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);

        // [WHEN] Perform "Get Posted Document Lines to Reverse" action (select all lines, press OK)
        CopyPostedSalesInvoiceLines(SalesHeader);

        // [THEN] There are 7 lines have been created in sales credit memo:
        // [THEN] Line1: "Type" = "", "No." = "", "Description" = "Invoice No. I1"
        // [THEN] Line2: "Type" = "G/L Account", "No." = "GLAcc1"
        // [THEN] Line3: "Type" = "", "No." = "", "Description" = "Invoice No. I2"
        // [THEN] Line4: "Type" = "", "No." = "", "Description" = "Inv. No. I2 - Shpt. No. S1"
        // [THEN] Line5: "Type" = "Item", "No." = "ITEM"
        // [THEN] Line6: "Type" = "", "No." = "", "Description" = "Invoice No. I3"
        // [THEN] Line7: "Type" = "G/L Account", "No." = "GLAcc2"
        FindFirstLineOfSalesDocument(SalesHeader, SalesLine);
        Assert.RecordCount(SalesLine, 7);
        VerifySalesInvoiceDescription(SalesLine, InvoiceNo[1], GLAccountNo[1]);
        VerifySalesInvoiceShipmentDescription(SalesLine, InvoiceNo[2], ShipmentNo, ItemNo);
        VerifySalesInvoiceDescription(SalesLine, InvoiceNo[3], GLAccountNo[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemo_GetPstdDocLinesToRev_ThreeDocs_ItemGLAccountItem()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        GLAccountNo: Code[20];
        ItemNo: array[2] of Code[20];
        InvoiceNo: array[3] of Code[20];
        ShipmentNo: array[2] of Code[20];
    begin
        // [FEATURE] [Sales] [Credit Memo] [Get Posted Document Lines to Reverse] [G/L Account] [Item]
        // [SCENARIO 382275] Sales Credit Memo "Get Posted Document Lines to Reverse" from three Invoices (Item, G/L Account, Item)
        Initialize;
        CustomerNo := LibrarySales.CreateCustomerNo;

        // [GIVEN] Posted sales invoice "I1" and shipment "S1" with line "Type" = "Item", "No." = "ITEM1"
        // [GIVEN] Posted sales invoice "I2" with line "Type" = "G/L Account", "No." = "GLAcc"
        // [GIVEN] Posted sales invoice "I3" and shipment "S2" with line "Type" = "Item", "No." = "ITEM2"
        CreatePostSalesOrderWithItem(InvoiceNo[1], ShipmentNo[1], ItemNo[1], CustomerNo);
        CreatePostSalesOrderWithGLAccount(InvoiceNo[2], GLAccountNo, CustomerNo);
        CreatePostSalesOrderWithItem(InvoiceNo[3], ShipmentNo[2], ItemNo[2], CustomerNo);
        // [GIVEN] A new sales credit memo
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);

        // [WHEN] Perform "Get Posted Document Lines to Reverse" action (select all lines, press OK)
        CopyPostedSalesInvoiceLines(SalesHeader);

        // [THEN] There are 8 lines have been created in sales credit memo:
        // [THEN] Line1: "Type" = "", "No." = "", "Description" = "Invoice No. I1"
        // [THEN] Line2: "Type" = "", "No." = "", "Description" = "Inv. No. I1 - Shpt. No. S1"
        // [THEN] Line3: "Type" = "Item", "No." = "ITEM1"
        // [THEN] Line4: "Type" = "", "No." = "", "Description" = "Invoice No. I2"
        // [THEN] Line5: "Type" = "G/L Account", "No." = "GLAcc"
        // [THEN] Line6: "Type" = "", "No." = "", "Description" = "Invoice No. I3"
        // [THEN] Line7: "Type" = "", "No." = "", "Description" = "Inv. No. I3 - Shpt. No. S2"
        // [THEN] Line8: "Type" = "Item", "No." = "ITEM2"
        FindFirstLineOfSalesDocument(SalesHeader, SalesLine);
        Assert.RecordCount(SalesLine, 8);
        VerifySalesInvoiceShipmentDescription(SalesLine, InvoiceNo[1], ShipmentNo[1], ItemNo[1]);
        VerifySalesInvoiceDescription(SalesLine, InvoiceNo[2], GLAccountNo);
        VerifySalesInvoiceShipmentDescription(SalesLine, InvoiceNo[3], ShipmentNo[2], ItemNo[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCrMemo_GetPstdDocLinesToRev_TwoDocs_GLAccounts()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        GLAccountNo: array[2] of Code[20];
        InvoiceNo: array[2] of Code[20];
    begin
        // [FEATURE] [Purchase] [Credit Memo] [Get Posted Document Lines to Reverse] [G/L Account]
        // [SCENARIO 382275] Purchase Credit Memo "Get Posted Document Lines to Reverse" from two Invoices (G/L Account)
        Initialize;
        VendorNo := LibraryPurchase.CreateVendorNo;

        // [GIVEN] Posted purchase invoice "I1" and receipt "R1" with line "Type" = "G/L Account", "No." = "GLAcc1"
        // [GIVEN] Posted purchase invoice "I2" and receipt "R2" with line "Type" = "G/L Account", "No." = "GLAcc2"
        CreatePostPurchaseOrderWithGLAccount(InvoiceNo[1], GLAccountNo[1], VendorNo);
        CreatePostPurchaseOrderWithGLAccount(InvoiceNo[2], GLAccountNo[2], VendorNo);
        // [GIVEN] A new purchase credit memo
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);

        // [WHEN] Perform "Get Posted Document Lines to Reverse" action (select all lines, press OK)
        CopyPostedPurchaseInvoiceLines(PurchaseHeader);

        // [THEN] There are 4 lines have been created in purchase credit memo:
        // [THEN] Line1: "Type" = "", "No." = "", "Description" = "Invoice No. I1"
        // [THEN] Line2: "Type" = "G/L Account", "No." = "GLAcc1"
        // [THEN] Line3: "Type" = "", "No." = "", "Description" = "Invoice No. I2"
        // [THEN] Line4: "Type" = "G/L Account", "No." = "GLAcc2"
        FindFirstLineOfPurchaseDocument(PurchaseHeader, PurchaseLine);
        Assert.RecordCount(PurchaseLine, 4);
        VerifyPurchaseInvoiceDescription(PurchaseLine, InvoiceNo[1], GLAccountNo[1]);
        VerifyPurchaseInvoiceDescription(PurchaseLine, InvoiceNo[2], GLAccountNo[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCrMemo_GetPstdDocLinesToRev_TwoDocs_Items()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        ItemNo: array[2] of Code[20];
        InvoiceNo: array[2] of Code[20];
        ReceiptNo: array[2] of Code[20];
    begin
        // [FEATURE] [Purchase] [Credit Memo] [Get Posted Document Lines to Reverse] [Item]
        // [SCENARIO 382275] Purchase Credit Memo "Get Posted Document Lines to Reverse" from two Invoices (Item)
        Initialize;
        VendorNo := LibraryPurchase.CreateVendorNo;

        // [GIVEN] Posted purchase invoice "I1" with line "Type" = "Item", "No." = "ITEM1"
        // [GIVEN] Posted purchase invoice "I2" with line "Type" = "Item", "No." = "ITEM2"
        CreatePostPurchaseOrderWithItem(InvoiceNo[1], ReceiptNo[1], ItemNo[1], VendorNo);
        CreatePostPurchaseOrderWithItem(InvoiceNo[2], ReceiptNo[2], ItemNo[2], VendorNo);
        // [GIVEN] A new purchase credit memo
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);

        // [WHEN] Perform "Get Posted Document Lines to Reverse" action (select all lines, press OK)
        CopyPostedPurchaseInvoiceLines(PurchaseHeader);

        // [THEN] There are 6 lines have been created in purchase credit memo:
        // [THEN] Line1: "Type" = "", "No." = "", "Description" = "Invoice No. I1"
        // [THEN] Line2: "Type" = "", "No." = "", "Description" = "Inv. No. I1 - Rcpt. No. R1"
        // [THEN] Line3: "Type" = "Item", "No." = "ITEM1"
        // [THEN] Line4: "Type" = "", "No." = "", "Description" = "Invoice No. I2"
        // [THEN] Line5: "Type" = "", "No." = "", "Description" = "Inv. No. I2 - Rcpt. No. R2"
        // [THEN] Line6: "Type" = "Item", "No." = "ITEM2"
        FindFirstLineOfPurchaseDocument(PurchaseHeader, PurchaseLine);
        Assert.RecordCount(PurchaseLine, 6);
        VerifyPurchaseInvoiceReceiptDescription(PurchaseLine, InvoiceNo[1], ReceiptNo[1], ItemNo[1]);
        VerifyPurchaseInvoiceReceiptDescription(PurchaseLine, InvoiceNo[2], ReceiptNo[2], ItemNo[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCrMemo_GetPstdDocLinesToRev_TwoDocs_GLAccountItem()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        GLAccountNo: Code[20];
        ItemNo: Code[20];
        InvoiceNo: array[2] of Code[20];
        ReceiptNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Credit Memo] [Get Posted Document Lines to Reverse] [G/L Account] [Item]
        // [SCENARIO 382275] Purchase Credit Memo "Get Posted Document Lines to Reverse" from two Invoices (G/L Account, Item)
        Initialize;
        VendorNo := LibraryPurchase.CreateVendorNo;

        // [GIVEN] Posted purchase invoice "I1" with line "Type" = "G/L Account", "No." = "GLAcc"
        // [GIVEN] Posted purchase invoice "I2" and receipt "R1" with line "Type" = "Item", "No." = "ITEM"
        CreatePostPurchaseOrderWithGLAccount(InvoiceNo[1], GLAccountNo, VendorNo);
        CreatePostPurchaseOrderWithItem(InvoiceNo[2], ReceiptNo, ItemNo, VendorNo);
        // [GIVEN] A new purchase credit memo
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);

        // [WHEN] Perform "Get Posted Document Lines to Reverse" action (select all lines, press OK)
        CopyPostedPurchaseInvoiceLines(PurchaseHeader);

        // [THEN] There are 5 lines have been created in purchase credit memo:
        // [THEN] Line1: "Type" = "", "No." = "", "Description" = "Invoice No. I1"
        // [THEN] Line2: "Type" = "G/L Account", "No." = "GLAcc"
        // [THEN] Line3: "Type" = "", "No." = "", "Description" = "Invoice No. I2"
        // [THEN] Line4: "Type" = "", "No." = "", "Description" = "Inv. No. I2 - Rcpt. No. R1"
        // [THEN] Line5: "Type" = "Item", "No." = "ITEM"
        FindFirstLineOfPurchaseDocument(PurchaseHeader, PurchaseLine);
        Assert.RecordCount(PurchaseLine, 5);
        VerifyPurchaseInvoiceDescription(PurchaseLine, InvoiceNo[1], GLAccountNo);
        VerifyPurchaseInvoiceReceiptDescription(PurchaseLine, InvoiceNo[2], ReceiptNo, ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCrMemo_GetPstdDocLinesToRev_TwoDocs_ItemGLAccount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        GLAccountNo: Code[20];
        ItemNo: Code[20];
        InvoiceNo: array[2] of Code[20];
        ReceiptNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Credit Memo] [Get Posted Document Lines to Reverse] [G/L Account] [Item]
        // [SCENARIO 382275] Purchase Credit Memo "Get Posted Document Lines to Reverse" from two Invoices (Item, G/L Account)
        Initialize;
        VendorNo := LibraryPurchase.CreateVendorNo;

        // [GIVEN] Posted purchase invoice "I1" and receipt "R1" with line "Type" = "Item", "No." = "ITEM"
        // [GIVEN] Posted purchase invoice "I2" with line "Type" = "G/L Account", "No." = "GLAcc"
        CreatePostPurchaseOrderWithItem(InvoiceNo[1], ReceiptNo, ItemNo, VendorNo);
        CreatePostPurchaseOrderWithGLAccount(InvoiceNo[2], GLAccountNo, VendorNo);
        // [GIVEN] A new purchase credit memo
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);

        // [WHEN] Perform "Get Posted Document Lines to Reverse" action (select all lines, press OK)
        CopyPostedPurchaseInvoiceLines(PurchaseHeader);

        // [THEN] There are 5 lines have been created in purchase credit memo:
        // [THEN] Line1: "Type" = "", "No." = "", "Description" = "Invoice No. I1"
        // [THEN] Line2: "Type" = "", "No." = "", "Description" = "Inv. No. I1 - Rcpt. No. R1"
        // [THEN] Line3: "Type" = "Item", "No." = "ITEM"
        // [THEN] Line4: "Type" = "", "No." = "", "Description" = "Invoice No. I2"
        // [THEN] Line5: "Type" = "G/L Account", "No." = "GLAcc"
        FindFirstLineOfPurchaseDocument(PurchaseHeader, PurchaseLine);
        Assert.RecordCount(PurchaseLine, 5);
        VerifyPurchaseInvoiceReceiptDescription(PurchaseLine, InvoiceNo[1], ReceiptNo, ItemNo);
        VerifyPurchaseInvoiceDescription(PurchaseLine, InvoiceNo[2], GLAccountNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCrMemo_GetPstdDocLinesToRev_ThreeDocs_GLAccountItemGLAccount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        GLAccountNo: array[2] of Code[20];
        ItemNo: Code[20];
        InvoiceNo: array[3] of Code[20];
        ReceiptNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Credit Memo] [Get Posted Document Lines to Reverse] [G/L Account] [Item]
        // [SCENARIO 382275] Purchase Credit Memo "Get Posted Document Lines to Reverse" from three Invoices (G/L Account, Item, G/L Account)
        Initialize;
        VendorNo := LibraryPurchase.CreateVendorNo;

        // [GIVEN] Posted purchase invoice "I1" with line "Type" = "G/L Account", "No." = "GLAcc1"
        // [GIVEN] Posted purchase invoice "I2" and receipt "R1" with line "Type" = "Item", "No." = "ITEM"
        // [GIVEN] Posted purchase invoice "I3" with line "Type" = "G/L Account", "No." = "GLAcc2"
        CreatePostPurchaseOrderWithGLAccount(InvoiceNo[1], GLAccountNo[1], VendorNo);
        CreatePostPurchaseOrderWithItem(InvoiceNo[2], ReceiptNo, ItemNo, VendorNo);
        CreatePostPurchaseOrderWithGLAccount(InvoiceNo[3], GLAccountNo[2], VendorNo);
        // [GIVEN] A new purchase credit memo
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);

        // [WHEN] Perform "Get Posted Document Lines to Reverse" action (select all lines, press OK)
        CopyPostedPurchaseInvoiceLines(PurchaseHeader);

        // [THEN] There are 7 lines have been created in purchase credit memo:
        // [THEN] Line1: "Type" = "", "No." = "", "Description" = "Invoice No. I1"
        // [THEN] Line2: "Type" = "G/L Account", "No." = "GLAcc1"
        // [THEN] Line3: "Type" = "", "No." = "", "Description" = "Invoice No. I2"
        // [THEN] Line4: "Type" = "", "No." = "", "Description" = "Inv. No. I2 - Rcpt. No. R1"
        // [THEN] Line5: "Type" = "Item", "No." = "ITEM"
        // [THEN] Line6: "Type" = "", "No." = "", "Description" = "Invoice No. I3"
        // [THEN] Line7: "Type" = "G/L Account", "No." = "GLAcc2"
        FindFirstLineOfPurchaseDocument(PurchaseHeader, PurchaseLine);
        Assert.RecordCount(PurchaseLine, 7);
        VerifyPurchaseInvoiceDescription(PurchaseLine, InvoiceNo[1], GLAccountNo[1]);
        VerifyPurchaseInvoiceReceiptDescription(PurchaseLine, InvoiceNo[2], ReceiptNo, ItemNo);
        VerifyPurchaseInvoiceDescription(PurchaseLine, InvoiceNo[3], GLAccountNo[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCrMemo_GetPstdDocLinesToRev_ThreeDocs_ItemGLAccountItem()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        GLAccountNo: Code[20];
        ItemNo: array[2] of Code[20];
        InvoiceNo: array[3] of Code[20];
        ReceiptNo: array[2] of Code[20];
    begin
        // [FEATURE] [Purchase] [Credit Memo] [Get Posted Document Lines to Reverse] [G/L Account] [Item]
        // [SCENARIO 382275] Purchase Credit Memo "Get Posted Document Lines to Reverse" from three Invoices (Item, G/L Account, Item)
        Initialize;
        VendorNo := LibraryPurchase.CreateVendorNo;

        // [GIVEN] Posted purchase invoice "I1" and receipt "R1" with line "Type" = "Item", "No." = "ITEM1"
        // [GIVEN] Posted purchase invoice "I2" with line "Type" = "G/L Account", "No." = "GLAcc"
        // [GIVEN] Posted purchase invoice "I3" and receipt "R2" with line "Type" = "Item", "No." = "ITEM2"
        CreatePostPurchaseOrderWithItem(InvoiceNo[1], ReceiptNo[1], ItemNo[1], VendorNo);
        CreatePostPurchaseOrderWithGLAccount(InvoiceNo[2], GLAccountNo, VendorNo);
        CreatePostPurchaseOrderWithItem(InvoiceNo[3], ReceiptNo[2], ItemNo[2], VendorNo);
        // [GIVEN] A new purchase credit memo
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);

        // [WHEN] Perform "Get Posted Document Lines to Reverse" action (select all lines, press OK)
        CopyPostedPurchaseInvoiceLines(PurchaseHeader);

        // [THEN] There are 8 lines have been created in purchase credit memo:
        // [THEN] Line1: "Type" = "", "No." = "", "Description" = "Invoice No. I1"
        // [THEN] Line2: "Type" = "", "No." = "", "Description" = "Inv. No. I1 - Rcpt. No. R1"
        // [THEN] Line3: "Type" = "Item", "No." = "ITEM1"
        // [THEN] Line4: "Type" = "", "No." = "", "Description" = "Invoice No. I2"
        // [THEN] Line5: "Type" = "G/L Account", "No." = "GLAcc"
        // [THEN] Line6: "Type" = "", "No." = "", "Description" = "Invoice No. I3"
        // [THEN] Line7: "Type" = "", "No." = "", "Description" = "Inv. No. I3 - Rcpt. No. R2"
        // [THEN] Line8: "Type" = "Item", "No." = "ITEM2"
        FindFirstLineOfPurchaseDocument(PurchaseHeader, PurchaseLine);
        Assert.RecordCount(PurchaseLine, 8);
        VerifyPurchaseInvoiceReceiptDescription(PurchaseLine, InvoiceNo[1], ReceiptNo[1], ItemNo[1]);
        VerifyPurchaseInvoiceDescription(PurchaseLine, InvoiceNo[2], GLAccountNo);
        VerifyPurchaseInvoiceReceiptDescription(PurchaseLine, InvoiceNo[3], ReceiptNo[2], ItemNo[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPriceIncludingVATFieldWhenCopySalesShptLineWithDiffersFromFalseUT()
    var
        ToSalesHeader: Record "Sales Header";
        FromSalesShptLine: Record "Sales Shipment Line";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        DummyInt: Integer;
        DummyBool: Boolean;
    begin
        // [FEATURE] [Sales] [Shipment] [Prices Incl. VAT] [UT]
        // [SCENARIO 211714] If "Prices Including VAT" value of Sales Shipment Line is FALSE and in destination Sales Document it is TRUE, then it cannot be copied to Sales Document

        Initialize;

        CreateSalesHeaderWithPricesInclVAT(ToSalesHeader, true);
        MockSalesShptLineWithPricesInclVAT(FromSalesShptLine, false);
        FromSalesShptLine.SetRecFilter;

        asserterror CopyDocumentMgt.CopySalesShptLinesToDoc(ToSalesHeader, FromSalesShptLine, DummyInt, DummyBool);
        Assert.ExpectedError('Prices Including VAT must be equal to ''Yes''');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPriceIncludingVATFieldWhenCopySalesShptLineWithDiffersFromTrueUT()
    var
        ToSalesHeader: Record "Sales Header";
        FromSalesShptLine: Record "Sales Shipment Line";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        DummyInt: Integer;
        DummyBool: Boolean;
    begin
        // [FEATURE] [Sales] [Shipment] [Prices Incl. VAT] [UT]
        // [SCENARIO 211714] If "Prices Including VAT" value of Sales Shipment Line is TRUE and in destination Sales Document it is FALSE, then it cannot be copied to Sales Document

        Initialize;

        CreateSalesHeaderWithPricesInclVAT(ToSalesHeader, false);
        MockSalesShptLineWithPricesInclVAT(FromSalesShptLine, true);
        FromSalesShptLine.SetRecFilter;

        asserterror CopyDocumentMgt.CopySalesShptLinesToDoc(ToSalesHeader, FromSalesShptLine, DummyInt, DummyBool);
        Assert.ExpectedError('Prices Including VAT must be equal to ''No''');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShiptoAddressPurchOrderAfterCopyFromPurchOrder()
    var
        FromPurchaseHeader: Record "Purchase Header";
        ToPurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 212724] Ship-to address should be copied to Purchase Order from original Purchase Order with Location = '' after copying
        Initialize;

        // [GIVEN] A purchase order "PO1" with "Ship-to Address" = 'Lenina St.', "Ship-to Address 2" = 'Bld. 3, App. 45'
        // [GIVEN] "Ship-to City" = 'Moscow', "Ship-to Country/Region Code" = 'RU'
        // [GIVEN] "Ship-to County" = 'Moscowia', "Ship-to Post Code" = '123456'
        // [GIVEN] "Ship-to Name" = 'Main Address', "Ship-to Name 2" = 'Secondary Address'
        // [GIVEN] "Location Code" = '', "Ship-to Contact" = 'Ivanov Ivan'
        // [GIVEN] "Inbound Whse. Handling Time" = '4D'
        LibraryPurchase.CreatePurchHeader(FromPurchaseHeader, FromPurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo);
        UpdateShiptoAddrOfPurchOrder(FromPurchaseHeader, '');

        // [GIVEN] A purchase order "PO2"
        LibraryPurchase.CreatePurchHeader(
          ToPurchaseHeader, ToPurchaseHeader."Document Type"::Order, FromPurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Copying "PO1" to "PO2"
        RunCopyPurchaseDoc(FromPurchaseHeader."No.", ToPurchaseHeader, PurchDocType::Order, true, false);

        // [THEN] "PO2"."Ship-to Address" = 'Lenina St.', "PO2"."Ship-to Address 2" = 'Bld. 3, App. 45'
        // [THEN] "PO2"."Ship-to City" = 'Moscow', "PO2"."Ship-to Country/Region Code" = 'RU'
        // [THEN] "PO2"."Ship-to County" = 'Moscowia', "PO2"."Ship-to Post Code" = '123456'
        // [THEN] "PO2"."Ship-to Name" = 'Main Address', "PO2"."Ship-to Name 2" = 'Secondary Address'
        // [THEN] "PO2"."Location Code" = '', "PO2"."Ship-to Contact" = 'Ivanov Ivan'
        // [THEN] "PO2"."Inbound Whse. Handling Time" = '4D'
        VerifyShiptoAddressPurchaseOrder(FromPurchaseHeader, ToPurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShiptoAddressPurchOrderAfterCopyFromPurchOrderWithLocation()
    var
        FromPurchaseHeader: Record "Purchase Header";
        ToPurchaseHeader: Record "Purchase Header";
        Location: Record Location;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 212724] Ship-to address should be copied to Purchase Order from original Purchase Order with Location <> '' after copying
        Initialize;

        // [GIVEN] A purchase order "PO1" with "Ship-to Address" = 'Lenina St.', "Ship-to Address 2" = 'Bld. 3, App. 45'
        // [GIVEN] "Ship-to City" = 'Moscow', "Ship-to Country/Region Code" = 'RU'
        // [GIVEN] "Ship-to County" = 'Moscowia', "Ship-to Post Code" = '123456'
        // [GIVEN] "Ship-to Name" = 'Main Address', "Ship-to Name 2" = 'Secondary Address'
        // [GIVEN] "Location Code" = 'Warehouse 1', "Ship-to Contact" = 'Ivanov Ivan'
        // [GIVEN] "Inbound Whse. Handling Time" = '4D'
        LibraryPurchase.CreatePurchHeader(FromPurchaseHeader, FromPurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo);
        UpdateShiptoAddrOfPurchOrder(FromPurchaseHeader, LibraryWarehouse.CreateLocation(Location));

        // [GIVEN] A purchase order "PO2"
        LibraryPurchase.CreatePurchHeader(
          ToPurchaseHeader, ToPurchaseHeader."Document Type"::Order, FromPurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Copying "PO1" to "PO2"
        RunCopyPurchaseDoc(FromPurchaseHeader."No.", ToPurchaseHeader, PurchDocType::Order, true, false);

        // [THEN] "PO2"."Ship-to Address" = 'Lenina St.', "PO2"."Ship-to Address 2" = 'Bld. 3, App. 45'
        // [THEN] "PO2"."Ship-to City" = 'Moscow', "PO2"."Ship-to Country/Region Code" = 'RU'
        // [THEN] "PO2"."Ship-to County" = 'Moscowia', "PO2"."Ship-to Post Code" = '123456'
        // [THEN] "PO2"."Ship-to Name" = 'Main Address', "PO2"."Ship-to Name 2" = 'Secondary Address'
        // [THEN] "PO2"."Location Code" = 'Warehouse 1', "PO2"."Ship-to Contact" = 'Ivanov Ivan'
        // [THEN] "PO2"."Inbound Whse. Handling Time" = '4D'
        VerifyShiptoAddressPurchaseOrder(FromPurchaseHeader, ToPurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPriceIncludingVATFieldWhenCopyPurchRcptLineWithDiffersFromFalseUT()
    var
        ToPurchaseHeader: Record "Purchase Header";
        FromPurchRcptLine: Record "Purch. Rcpt. Line";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        DummyInt: Integer;
        DummyBool: Boolean;
    begin
        // [FEATURE] [Purchase] [Receipt] [Prices Incl. VAT] [UT]
        // [SCENARIO 216846] If "Prices Including VAT" value of Purchase Receipt Line is FALSE and in destination Purchase Document it is TRUE, then it cannot be copied to Purchase Document

        Initialize;

        CreatePurchHeaderWithPricesInclVAT(ToPurchaseHeader, true);
        MockPurchRcptLineWithPricesInclVAT(FromPurchRcptLine, false);

        asserterror CopyDocumentMgt.CopyPurchRcptLinesToDoc(ToPurchaseHeader, FromPurchRcptLine, DummyInt, DummyBool);
        Assert.ExpectedError('Prices Including VAT must be equal to ''Yes''');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPriceIncludingVATFieldWhenCopyPurchRcptLineWithDiffersFromTrueUT()
    var
        ToPurchaseHeader: Record "Purchase Header";
        FromPurchRcptLine: Record "Purch. Rcpt. Line";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        DummyInt: Integer;
        DummyBool: Boolean;
    begin
        // [FEATURE] [Purchase] [Receipt] [Prices Incl. VAT] [UT]
        // [SCENARIO 216846] If "Prices Including VAT" value of Purchase Receipt Line is TRUE and in destination Purchase Document it is FALSE, then it cannot be copied to Purchase Document

        Initialize;

        CreatePurchHeaderWithPricesInclVAT(ToPurchaseHeader, false);
        MockPurchRcptLineWithPricesInclVAT(FromPurchRcptLine, true);

        asserterror CopyDocumentMgt.CopyPurchRcptLinesToDoc(ToPurchaseHeader, FromPurchRcptLine, DummyInt, DummyBool);
        Assert.ExpectedError('Prices Including VAT must be equal to ''No''');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPriceIncludingVATFieldWhenCopyPurchInvLineWithDiffersFromFalseUT()
    var
        ToPurchaseHeader: Record "Purchase Header";
        FromPurchInvLine: Record "Purch. Inv. Line";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        DummyInt: Integer;
        DummyBool: Boolean;
    begin
        // [FEATURE] [Purchase] [Invoice] [Prices Incl. VAT] [UT]
        // [SCENARIO 216846] If "Prices Including VAT" value of Purchase Receipt Line is FALSE and in destination Purchase Document it is TRUE, then it cannot be copied to Purchase Document

        Initialize;

        CreatePurchHeaderWithPricesInclVAT(ToPurchaseHeader, true);
        MockPurchInvLineWithPricesInclVAT(FromPurchInvLine, false);

        asserterror CopyDocumentMgt.CopyPurchInvLinesToDoc(ToPurchaseHeader, FromPurchInvLine, DummyInt, DummyBool);
        Assert.ExpectedError('Prices Including VAT must be equal to ''Yes''');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPriceIncludingVATFieldWhenCopyPurchInvtLineWithDiffersFromTrueUT()
    var
        ToPurchaseHeader: Record "Purchase Header";
        FromPurchInvLine: Record "Purch. Inv. Line";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        DummyInt: Integer;
        DummyBool: Boolean;
    begin
        // [FEATURE] [Purchase] [Invoice] [Prices Incl. VAT] [UT]
        // [SCENARIO 216846] If "Prices Including VAT" value of Purchase Receipt Line is TRUE and in destination Purchase Document it is FALSE, then it cannot be copied to Purchase Document

        Initialize;

        CreatePurchHeaderWithPricesInclVAT(ToPurchaseHeader, false);
        MockPurchInvLineWithPricesInclVAT(FromPurchInvLine, true);

        asserterror CopyDocumentMgt.CopyPurchInvLinesToDoc(ToPurchaseHeader, FromPurchInvLine, DummyInt, DummyBool);
        Assert.ExpectedError('Prices Including VAT must be equal to ''No''');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPriceIncludingVATFieldWhenCopyPurchCrMemoLineWithDiffersFromFalseUT()
    var
        ToPurchaseHeader: Record "Purchase Header";
        FromPurchCrMemoLine: Record "Purch. Cr. Memo Line";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        DummyInt: Integer;
        DummyBool: Boolean;
    begin
        // [FEATURE] [Purchase] [Credit Memo] [Prices Incl. VAT] [UT]
        // [SCENARIO 216846] If "Prices Including VAT" value of Purchase Credit Memo Line is FALSE and in destination Purchase Document it is TRUE, then it cannot be copied to Purchase Document

        Initialize;

        CreatePurchHeaderWithPricesInclVAT(ToPurchaseHeader, true);
        MockPurchCrMemoLineWithPricesInclVAT(FromPurchCrMemoLine, false);

        asserterror CopyDocumentMgt.CopyPurchCrMemoLinesToDoc(ToPurchaseHeader, FromPurchCrMemoLine, DummyInt, DummyBool);
        Assert.ExpectedError('Prices Including VAT must be equal to ''Yes''');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPriceIncludingVATFieldWhenCopyPurchCrMemoLineWithDiffersFromTrueUT()
    var
        ToPurchaseHeader: Record "Purchase Header";
        FromPurchCrMemoLine: Record "Purch. Cr. Memo Line";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        DummyInt: Integer;
        DummyBool: Boolean;
    begin
        // [FEATURE] [Purchase] [Credit Memo] [Prices Incl. VAT] [UT]
        // [SCENARIO 216846] If "Prices Including VAT" value of Purchase Credit Memo Line is TRUE and in destination Purchase Document it is FALSE, then it cannot be copied to Purchase Document

        Initialize;

        CreatePurchHeaderWithPricesInclVAT(ToPurchaseHeader, false);
        MockPurchCrMemoLineWithPricesInclVAT(FromPurchCrMemoLine, true);

        asserterror CopyDocumentMgt.CopyPurchCrMemoLinesToDoc(ToPurchaseHeader, FromPurchCrMemoLine, DummyInt, DummyBool);
        Assert.ExpectedError('Prices Including VAT must be equal to ''No''');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPriceIncludingVATFieldWhenCopyReturnShptLineWithDiffersFromFalseUT()
    var
        ToPurchaseHeader: Record "Purchase Header";
        FromReturnShipmentLine: Record "Return Shipment Line";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        DummyInt: Integer;
        DummyBool: Boolean;
    begin
        // [FEATURE] [Purchase] [Return] [Shipment] [Prices Incl. VAT] [UT]
        // [SCENARIO 216846] If "Prices Including VAT" value of Return Shipment Line is FALSE and in destination Purchase Document it is TRUE, then it cannot be copied to Purchase Document

        Initialize;

        CreatePurchHeaderWithPricesInclVAT(ToPurchaseHeader, true);
        MockReturnShptLineWithPricesInclVAT(FromReturnShipmentLine, false);

        asserterror CopyDocumentMgt.CopyPurchReturnShptLinesToDoc(ToPurchaseHeader, FromReturnShipmentLine, DummyInt, DummyBool);
        Assert.ExpectedError('Prices Including VAT must be equal to ''Yes''');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPriceIncludingVATFieldWhenCopyReturnShptLineWithDiffersFromTrueUT()
    var
        ToPurchaseHeader: Record "Purchase Header";
        FromReturnShipmentLine: Record "Return Shipment Line";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        DummyInt: Integer;
        DummyBool: Boolean;
    begin
        // [FEATURE] [Purchase] [Return] [Shipment] [Prices Incl. VAT] [UT]
        // [SCENARIO 216846] If "Prices Including VAT" value of Purchase Credit Memo Line is TRUE and in destination Purchase Document it is FALSE, then it cannot be copied to Purchase Document

        Initialize;

        CreatePurchHeaderWithPricesInclVAT(ToPurchaseHeader, false);
        MockReturnShptLineWithPricesInclVAT(FromReturnShipmentLine, true);

        asserterror CopyDocumentMgt.CopyPurchReturnShptLinesToDoc(ToPurchaseHeader, FromReturnShipmentLine, DummyInt, DummyBool);
        Assert.ExpectedError('Prices Including VAT must be equal to ''No''');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopySalesInvoiceWithInvDiscountAndItemOfZeroPrice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ToSalesHeader: Record "Sales Header";
        ToSalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Invoice Discount]
        // [SCENARIO 277369] Copy sales document with include header and recalculate lines and calculate invoice discount
        // [SCENARIO 277369] when destination line has zero amount after recalculation
        Initialize;

        // [GIVEN] Calc. Invoice Discount is Yes in Sales Setup
        UpdateSalesSetupCalcInvDiscount(true);

        // [GIVEN] Item with zero unit price is added to sales invoice with line Unit Price = 50 and quantity = 2
        // [GIVEN] Discount Amount = 50 is applied to the sales invoice
        CreateSalesInvoiceWithInvDiscount(
          SalesHeader, SalesLine, LibraryInventory.CreateItemNo, LibraryRandom.RandDecInRange(100, 200, 2));

        // [GIVEN] Sales invoice is copied with Include Header and Recalculate Lines to new sales order
        LibrarySales.CreateSalesHeader(ToSalesHeader, ToSalesHeader."Document Type"::Order, SalesHeader."Sell-to Customer No.");
        RunCopySalesDoc(
          SalesHeader."No.", ToSalesHeader,
          MapperSalesHeaders(SalesHeader."Document Type"), true, true);
        ToSalesHeader.Find;
        ToSalesHeader.TestField("Invoice Discount Value", 0);

        // [WHEN] Calc invoice discount on destination sales line
        CalcInvoiceDiscountOnSalesLine(ToSalesLine, ToSalesHeader, SalesLine."No.");

        // [THEN] "Inv. Disc. Amount to Invoice" is 0
        ToSalesLine.Find;
        ToSalesLine.TestField("Inv. Disc. Amount to Invoice", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopySalesInvoiceWithInvDiscountAndItemOfSmallPrice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ToSalesHeader: Record "Sales Header";
        ToSalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Invoice Discount]
        // [SCENARIO 277369] Copy sales document with include header and recalculate lines and calculate invoice discount
        // [SCENARIO 277369] when destination line has amount less than source invoice discount
        Initialize;

        // [GIVEN] Calc. Invoice Discount is Yes in Sales Setup
        UpdateSalesSetupCalcInvDiscount(true);

        // [GIVEN] Item with Unit Price = 1
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandIntInRange(1, 5));
        Item.Modify(true);

        // [GIVEN] Item with unit price = 1 is added to sales invoice with line Unit Price = 50 and quantity = 2
        // [GIVEN] Discount Amount = 50 is applied to the sales invoice
        CreateSalesInvoiceWithInvDiscount(
          SalesHeader, SalesLine, Item."No.", LibraryRandom.RandDecInRange(100, 200, 2));

        // [GIVEN] Sales invoice is copied with Include Header and Recalculate Lines
        LibrarySales.CreateSalesHeader(ToSalesHeader, ToSalesHeader."Document Type"::Order, SalesHeader."Sell-to Customer No.");
        RunCopySalesDoc(
          SalesHeader."No.", ToSalesHeader,
          MapperSalesHeaders(SalesHeader."Document Type"), true, true);
        ToSalesHeader.Find;
        ToSalesHeader.TestField("Invoice Discount Value", Item."Unit Price" * SalesLine.Quantity);

        // [WHEN] Calc invoice discount on destination sales line
        CalcInvoiceDiscountOnSalesLine(ToSalesLine, ToSalesHeader, SalesLine."No.");

        // [THEN] "Inv. Disc. Amount to Invoice" = 2
        ToSalesLine.Find;
        ToSalesLine.TestField("Inv. Disc. Amount to Invoice", ToSalesLine."Line Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPurchaseInvoiceWithInvDiscountAndItemOfZeroCost()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ToPurchaseHeader: Record "Purchase Header";
        ToPurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Invoice Discount]
        // [SCENARIO 277369] Copy purchase document with include header and recalculate lines and calculate invoice discount
        // [SCENARIO 277369] when destination line has zero amount after recalculation
        Initialize;

        // [GIVEN] Calc. Invoice Discount is Yes in Purchase Setup
        UpdatePurchaseSetupCalcInvDiscount(true);

        // [GIVEN] Item with zero unit cost is added to purchase invoice with line Unit Cost = 50 and quantity = 2
        // [GIVEN] Discount Amount = 50 is applied to the purchase invoice
        CreatePurchaseInvoiceWithInvDiscount(
          PurchaseHeader, PurchaseLine, LibraryInventory.CreateItemNo, LibraryRandom.RandDecInRange(100, 200, 2));

        // [GIVEN] Purchase invoice is copied with Include Header and Recalculate Lines to new purchase order
        LibraryPurchase.CreatePurchHeader(ToPurchaseHeader, ToPurchaseHeader."Document Type"::Order, PurchaseHeader."Buy-from Vendor No.");
        RunCopyPurchaseDoc(
          PurchaseHeader."No.", ToPurchaseHeader, MapperPurchaseHeaders(PurchaseHeader."Document Type"), true, true);
        ToPurchaseHeader.Find;
        ToPurchaseHeader.TestField("Invoice Discount Value", 0);

        // [WHEN] Calc invoice discount on destination purchase line
        CalcInvoiceDiscountOnPurchaseLine(ToPurchaseLine, ToPurchaseHeader, PurchaseLine."No.");

        // [THEN] "Inv. Disc. Amount to Invoice" is 0
        ToPurchaseLine.Find;
        ToPurchaseLine.TestField("Inv. Disc. Amount to Invoice", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPurchaseInvoiceWithInvDiscountAndItemOfSmallCost()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        ToPurchaseHeader: Record "Purchase Header";
        ToPurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Invoice Discount]
        // [SCENARIO 277369] Copy purchase document with include header and recalculate lines and calculate invoice discount
        // [SCENARIO 277369] when destination line has amount less than source invoice discount
        Initialize;

        // [GIVEN] Calc. Invoice Discount is Yes in Purchase Setup
        UpdatePurchaseSetupCalcInvDiscount(true);

        // [GIVEN] Item with Unit Price = 1
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandIntInRange(1, 5));
        Item.Modify(true);

        // [GIVEN] Item with unit cost = 1 is added to purchase invoice with line Unit Cost = 50 and quantity = 2
        // [GIVEN] Discount Amount = 50 is applied to the purchase invoice
        CreatePurchaseInvoiceWithInvDiscount(
          PurchaseHeader, PurchaseLine, Item."No.", LibraryRandom.RandDecInRange(100, 200, 2));

        // [GIVEN] Purchase invoice is copied with Include Header and Recalculate Lines
        LibraryPurchase.CreatePurchHeader(ToPurchaseHeader, ToPurchaseHeader."Document Type"::Order, PurchaseHeader."Buy-from Vendor No.");
        RunCopyPurchaseDoc(
          PurchaseHeader."No.", ToPurchaseHeader, MapperPurchaseHeaders(PurchaseHeader."Document Type"), true, true);
        ToPurchaseHeader.Find;
        ToPurchaseHeader.TestField("Invoice Discount Value", Item."Unit Price" * PurchaseLine.Quantity);

        // [WHEN] Calc invoice discount on destination purhcase line
        CalcInvoiceDiscountOnPurchaseLine(ToPurchaseLine, ToPurchaseHeader, PurchaseLine."No.");

        // [THEN] "Inv. Disc. Amount to Invoice" = 2
        ToPurchaseLine.Find;
        ToPurchaseLine.TestField("Inv. Disc. Amount to Invoice", ToPurchaseLine."Line Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPurchOrderWithDropShipment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchasingCode: Code[10];
        OldPurchHeaderNo: Code[20];
        DropShipment: Boolean;
        SpecialOrder: Boolean;
    begin
        // [FEATURE] [Purchase] [Purchasing Code] [Drop Shipment]
        // [SCENARIO 304519] Purchasing Code and Drop Shipment are not copied to Purchase Order
        Initialize;
        DropShipment := true;
        SpecialOrder := not DropShipment;

        // [GIVEN] Purchasing Code DROP-SHIP with Drop Shipment = TRUE
        PurchasingCode := CreatePurchasingCode(DropShipment, SpecialOrder);

        // [GIVEN] Purchase Order with Purchase Line, having Purchasing Code = DROP-SHIP and Drop Shipment = TRUE
        CreateOneItemPurchDoc(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        UpdatePurchLinePurchasingCodeDropShipmentSpecialOrder(PurchaseHeader, PurchasingCode, DropShipment, SpecialOrder);
        OldPurchHeaderNo := PurchaseHeader."No.";

        // [GIVEN] New Purchase Order
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Copy Purchase Order to New Purchase Order with Recalculate Lines = FALSE
        RunCopyPurchaseDoc(OldPurchHeaderNo, PurchaseHeader, PurchDocType::Order, true, false);

        // [THEN] New Purchase Order has Purchasing Code <blank> and Drop Shipment = FALSE in the line
        VerifyPurchLinePurchasingCodeDropShipmentSpecialOrder(PurchaseHeader, '', false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure CopyArchivedPurchOrderWithDropShipment()
    var
        PurchaseHeader: Record "Purchase Header";
        ArchiveManagement: Codeunit ArchiveManagement;
        PurchasingCode: Code[10];
        OldPurchHeaderNo: Code[20];
        DropShipment: Boolean;
        SpecialOrder: Boolean;
    begin
        // [FEATURE] [Purchase] [Purchasing Code] [Drop Shipment] [Archive]
        // [SCENARIO 304519] Purchasing Code and Drop Shipment are not copied to Purchase Order from Archived Purchase Order
        Initialize;
        DropShipment := true;
        SpecialOrder := not DropShipment;

        // [GIVEN] Purchasing Code DROP-SHIP with Drop Shipment = TRUE
        PurchasingCode := CreatePurchasingCode(DropShipment, SpecialOrder);

        // [GIVEN] Archived Purchase Order with Purchase Line, having Purchasing Code = DROP-SHIP and Drop Shipment = TRUE
        CreateOneItemPurchDoc(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        UpdatePurchLinePurchasingCodeDropShipmentSpecialOrder(PurchaseHeader, PurchasingCode, DropShipment, SpecialOrder);
        OldPurchHeaderNo := PurchaseHeader."No.";
        ArchiveManagement.ArchivePurchDocument(PurchaseHeader);

        // [GIVEN] New Purchase Order
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Copy Archived Purchase Order to New Purchase Order with Recalculate Lines = FALSE
        CopyPurchDocFromArchive(PurchaseHeader, PurchDocType::"Arch. Order", OldPurchHeaderNo, true, false, PurchaseHeader."Document Type");

        // [THEN] New Purchase Order has Purchasing Code <blank> and Drop Shipment = FALSE in the line
        VerifyPurchLinePurchasingCodeDropShipmentSpecialOrder(PurchaseHeader, '', false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPurchOrderWithSpecialOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchasingCode: Code[10];
        OldPurchHeaderNo: Code[20];
        DropShipment: Boolean;
        SpecialOrder: Boolean;
    begin
        // [FEATURE] [Purchase] [Purchasing Code] [Special Order]
        // [SCENARIO 304519] Purchasing Code and Special Order are not copied to Purchase Order
        Initialize;
        SpecialOrder := true;
        DropShipment := not SpecialOrder;

        // [GIVEN] Purchasing Code SPO with Special Order = TRUE
        PurchasingCode := CreatePurchasingCode(DropShipment, SpecialOrder);

        // [GIVEN] Purchase Order with Purchase Line, having Purchasing Code = SPO and Special Order = TRUE
        CreateOneItemPurchDoc(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        UpdatePurchLinePurchasingCodeDropShipmentSpecialOrder(PurchaseHeader, PurchasingCode, DropShipment, SpecialOrder);
        OldPurchHeaderNo := PurchaseHeader."No.";

        // [GIVEN] New Purchase Order
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Copy Purchase Order to New Purchase Order with Recalculate Lines = FALSE
        RunCopyPurchaseDoc(OldPurchHeaderNo, PurchaseHeader, PurchDocType::Order, true, false);

        // [THEN] New Purchase Order has Purchasing Code <blank> and Special Order = FALSE in the line
        VerifyPurchLinePurchasingCodeDropShipmentSpecialOrder(PurchaseHeader, '', false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure CopyArchivedPurchOrderWithSpecialOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        ArchiveManagement: Codeunit ArchiveManagement;
        PurchasingCode: Code[10];
        OldPurchHeaderNo: Code[20];
        DropShipment: Boolean;
        SpecialOrder: Boolean;
    begin
        // [FEATURE] [Purchase] [Purchasing Code] [Special Order] [Archive]
        // [SCENARIO 304519] Purchasing Code and Special Order are not copied to Purchase Order from Archived Purchase Order
        Initialize;
        SpecialOrder := true;
        DropShipment := not SpecialOrder;

        // [GIVEN] Purchasing Code SPO with Special Order = TRUE
        PurchasingCode := CreatePurchasingCode(DropShipment, SpecialOrder);

        // [GIVEN] Archived Purchase Order with Purchase Line, having Purchasing Code = SPO and Special Order = TRUE
        CreateOneItemPurchDoc(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        UpdatePurchLinePurchasingCodeDropShipmentSpecialOrder(PurchaseHeader, PurchasingCode, DropShipment, SpecialOrder);
        OldPurchHeaderNo := PurchaseHeader."No.";
        ArchiveManagement.ArchivePurchDocument(PurchaseHeader);

        // [GIVEN] New Purchase Order
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Copy Archived Purchase Order to New Purchase Order with Recalculate Lines = FALSE
        CopyPurchDocFromArchive(PurchaseHeader, PurchDocType::"Arch. Order", OldPurchHeaderNo, true, false, PurchaseHeader."Document Type");

        // [THEN] New Purchase Order has Purchasing Code <blank> and Special Order = FALSE in the line
        VerifyPurchLinePurchasingCodeDropShipmentSpecialOrder(PurchaseHeader, '', false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopySalesOrderWithDropShipment()
    var
        SalesHeader: Record "Sales Header";
        PurchasingCode: Code[10];
        OldSalesHeaderNo: Code[20];
        DropShipment: Boolean;
        SpecialOrder: Boolean;
    begin
        // [FEATURE] [Sales] [Purchasing Code] [Drop Shipment]
        // [SCENARIO 304519] Purchasing Code and Drop Shipment are copied to Sales Order when Recalculate Lines is FALSE
        Initialize;
        DropShipment := true;
        SpecialOrder := not DropShipment;

        // [GIVEN] Purchasing Code DROP-SHIP with Drop Shipment = TRUE
        PurchasingCode := CreatePurchasingCode(DropShipment, SpecialOrder);

        // [GIVEN] Sales Order with Sales Line, having Purchasing Code = DROP-SHIP and Drop Shipment = TRUE
        CreateOneItemSalesDoc(SalesHeader, SalesHeader."Document Type"::Order);
        UpdateSalesLinePurchasingCodeDropShipmentSpecialOrder(SalesHeader, PurchasingCode, DropShipment, SpecialOrder);
        OldSalesHeaderNo := SalesHeader."No.";

        // [GIVEN] New Sales Order
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, SalesHeader."Sell-to Customer No.");

        // [WHEN] Copy Sales Order to New Sales Order with Recalculate Lines = FALSE
        RunCopySalesDoc(OldSalesHeaderNo, SalesHeader, SalesDocType::Order, true, false);

        // [THEN] New Sales Order has Purchasing Code = DROP-SHIP and Drop Shipment = TRUE in the line
        VerifySalesLinePurchasingCodeDropShipmentSpecialOrder(SalesHeader, PurchasingCode, DropShipment, SpecialOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure CopyArchivedSalesOrderWithDropShipment()
    var
        SalesHeader: Record "Sales Header";
        ArchiveManagement: Codeunit ArchiveManagement;
        PurchasingCode: Code[10];
        OldSalesHeaderNo: Code[20];
        DropShipment: Boolean;
        SpecialOrder: Boolean;
    begin
        // [FEATURE] [Sales] [Purchasing Code] [Drop Shipment] [Archive]
        // [SCENARIO 304519] Purchasing Code and Drop Shipment are copied to Sales Order from Archived Sales Order when Recalculate Lines is FALSE
        Initialize;
        DropShipment := true;
        SpecialOrder := not DropShipment;

        // [GIVEN] Purchasing Code DROP-SHIP with Drop Shipment = TRUE
        PurchasingCode := CreatePurchasingCode(DropShipment, SpecialOrder);

        // [GIVEN] Archived Sales Order with Sales Line, having Purchasing Code = DROP-SHIP and Drop Shipment = TRUE
        CreateOneItemSalesDoc(SalesHeader, SalesHeader."Document Type"::Order);
        UpdateSalesLinePurchasingCodeDropShipmentSpecialOrder(SalesHeader, PurchasingCode, DropShipment, SpecialOrder);
        OldSalesHeaderNo := SalesHeader."No.";
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);

        // [GIVEN] New Sales Order
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, SalesHeader."Sell-to Customer No.");

        // [WHEN] Copy Archived Sales Order to New Sales Order with Recalculate Lines = FALSE
        CopySalesDocFromArchive(SalesHeader, SalesDocType::"Arch. Order", OldSalesHeaderNo, true, false, SalesHeader."Document Type");

        // [THEN] New Sales Order has Purchasing Code = DROP-SHIP and Drop Shipment = TRUE in the line
        VerifySalesLinePurchasingCodeDropShipmentSpecialOrder(SalesHeader, PurchasingCode, DropShipment, SpecialOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopySalesOrderWithSpecialOrder()
    var
        SalesHeader: Record "Sales Header";
        PurchasingCode: Code[10];
        OldSalesHeaderNo: Code[20];
        DropShipment: Boolean;
        SpecialOrder: Boolean;
    begin
        // [FEATURE] [Sales] [Purchasing Code] [Special Order]
        // [SCENARIO 304519] Purchasing Code and Special Order are copied to Sales Order when Recalculate Lines is FALSE
        Initialize;
        SpecialOrder := true;
        DropShipment := not SpecialOrder;

        // [GIVEN] Purchasing Code SPO with Special Order = TRUE
        PurchasingCode := CreatePurchasingCode(DropShipment, SpecialOrder);

        // [GIVEN] Sales Order with Sales Line, having Purchasing Code = SPO and Special Order = TRUE
        CreateOneItemSalesDoc(SalesHeader, SalesHeader."Document Type"::Order);
        UpdateSalesLinePurchasingCodeDropShipmentSpecialOrder(SalesHeader, PurchasingCode, DropShipment, SpecialOrder);
        OldSalesHeaderNo := SalesHeader."No.";

        // [GIVEN] New Sales Order
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, SalesHeader."Sell-to Customer No.");

        // [WHEN] Copy Sales Order to New Sales Order with Recalculate Lines = FALSE
        RunCopySalesDoc(OldSalesHeaderNo, SalesHeader, SalesDocType::Order, true, false);

        // [THEN] New Sales Order has Purchasing Code = SPO and Special Order = TRUE in the line
        VerifySalesLinePurchasingCodeDropShipmentSpecialOrder(SalesHeader, PurchasingCode, DropShipment, SpecialOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure CopyArchivedSalesOrderWithSpecialOrder()
    var
        SalesHeader: Record "Sales Header";
        ArchiveManagement: Codeunit ArchiveManagement;
        PurchasingCode: Code[10];
        OldSalesHeaderNo: Code[20];
        DropShipment: Boolean;
        SpecialOrder: Boolean;
    begin
        // [FEATURE] [Sales] [Purchasing Code] [Special Order] [Archive]
        // [SCENARIO 304519] Purchasing Code and Special Order are copied to Sales Order from archived Sales Order when Recalculate Lines is FALSE
        Initialize;
        SpecialOrder := true;
        DropShipment := not SpecialOrder;

        // [GIVEN] Purchasing Code SPO with Special Order = TRUE
        PurchasingCode := CreatePurchasingCode(DropShipment, SpecialOrder);

        // [GIVEN] Archived Sales Order with Sales Line, having Purchasing Code = SPO and Special Order = TRUE
        CreateOneItemSalesDoc(SalesHeader, SalesHeader."Document Type"::Order);
        UpdateSalesLinePurchasingCodeDropShipmentSpecialOrder(SalesHeader, PurchasingCode, DropShipment, SpecialOrder);
        OldSalesHeaderNo := SalesHeader."No.";
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);

        // [GIVEN] New Sales Order
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, SalesHeader."Sell-to Customer No.");

        // [WHEN] Copy Archived Sales Order to New Sales Order with Recalculate Lines = FALSE
        CopySalesDocFromArchive(SalesHeader, SalesDocType::"Arch. Order", OldSalesHeaderNo, true, false, SalesHeader."Document Type");

        // [THEN] New Sales Order has Purchasing Code = SPO and Special Order = TRUE in the line
        VerifySalesLinePurchasingCodeDropShipmentSpecialOrder(SalesHeader, PurchasingCode, DropShipment, SpecialOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPurchDocWithoutCopyFromLine()
    var
        DestinationPurchHeader: Record "Purchase Header";
        DestinationPurchLine: Record "Purchase Line";
        ERMCopyPurchSalesDoc: Codeunit "ERM Copy Purch/Sales Doc";
        InvoiceNo: Code[20];
        GLAccountNo: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Purchase Document is copied without creating first "copy from" line
        Initialize;
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Create and post purchase invoce
        CreatePostPurchaseOrderWithGLAccount(InvoiceNo, GLAccountNo, VendorNo);

        // [GIVEN] Prepare destination invoice YYY
        DestinationPurchHeader.Init();
        DestinationPurchHeader.Validate("Document Type", DestinationPurchHeader."Document Type"::Invoice);
        DestinationPurchHeader.Insert(true);

        // [GIVEN] Subscibe on CopyDocumentMgt.OnBeforeInsertOldPurchDocNoLine
        BindSubscription(ERMCopyPurchSalesDoc);

        // [WHEN] Copy posted invoice XXX to purchase invoice YYY 
        RunCopyPurchaseDoc(
          InvoiceNo, DestinationPurchHeader, 7, true, true);

        // [THEN] Line with description "Invoice XXX:" is not created
        DestinationPurchLine.SetRange("Document Type", DestinationPurchHeader."Document Type");
        DestinationPurchLine.SetRange("Document No.", DestinationPurchHeader."No.");
        DestinationPurchLine.SetRange(Description, StrSubstNo(InvoiceNoTxt, InvoiceNo));
        Assert.RecordIsEmpty(DestinationPurchLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopySalesDocWithoutCopyFromLine()
    var
        DestinationSalesHeader: Record "Sales Header";
        DestinationSalesLine: Record "Sales Line";
        ERMCopySalesSalesDoc: Codeunit "ERM Copy Purch/Sales Doc";
        InvoiceNo: Code[20];
        GLAccountNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Sales Document is copied without creating first "copy from" line
        Initialize;
        CustomerNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] Create and post sales invoce
        CreatePostSalesOrderWithGLAccount(InvoiceNo, GLAccountNo, CustomerNo);

        // [GIVEN] Prepare destination invoice YYY
        DestinationSalesHeader.Init();
        DestinationSalesHeader.Validate("Document Type", DestinationSalesHeader."Document Type"::Invoice);
        DestinationSalesHeader.Insert(true);

        // [GIVEN] Subscibe on CopyDocumentMgt.OnBeforeInsertOldSalesDocNoLine
        BindSubscription(ERMCopySalesSalesDoc);

        // [WHEN] Copy posted invoice XXX to sales invoice YYY 
        RunCopySalesDoc(
          InvoiceNo, DestinationSalesHeader, 7, true, true);

        // [THEN] Line with description "Invoice XXX:" is not created
        DestinationSalesLine.SetRange("Document Type", DestinationSalesHeader."Document Type");
        DestinationSalesLine.SetRange("Document No.", DestinationSalesHeader."No.");
        DestinationSalesLine.SetRange(Description, StrSubstNo(InvoiceNoTxt, InvoiceNo));
        Assert.RecordIsEmpty(DestinationSalesLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CorrectPostedPurchaseInvoiceWithZeroChargeItemUnitCost();
    var
        GeneralLedgerSetup: Record 98;
        Item: Record 27;
        ItemCharge: Record 5800;
        Vendor: Record 23;
        PurchaseHeader: Record 38;
        PurchaseLineItem: Record 39;
        PurchaseLineChargeItem: Record 39;
        ItemChargeAssignmentPurch: Record 5805;
        PurchInvHeader: Record 122;
        CorrectPostedPurchInvoice: Codeunit 1313;
        DirectUnitCost: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 318774] Posted Sales Invoice is copied to Corrective Credit Memo with item charge of zero unit cost.
        Initialize;

        // [GIVEN] Purchase invoice with two lines - first with item, second one with item charge assigned to the first line.
        GeneralLedgerSetup.Get();
        DirectUnitCost := GeneralLedgerSetup."Unit-Amount Rounding Precision";
        GeneralLedgerSetup.Validate("Unit-Amount Rounding Precision", GeneralLedgerSetup."Unit-Amount Rounding Precision" * 10);
        GeneralLedgerSetup.Modify(true);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        CreatePurchaseLine(
          PurchaseLineItem, PurchaseHeader, PurchaseLineItem.Type::Item, Item."No.",
          LibraryRandom.RandIntInRange(100, 1000), DirectUnitCost);
        CreatePurchaseLine(
          PurchaseLineChargeItem, PurchaseHeader, PurchaseLineChargeItem.Type::"Charge (Item)", ItemCharge."No.",
          LibraryRandom.RandIntInRange(100, 1000), DirectUnitCost);
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLineChargeItem,
          PurchaseLineItem."Document Type", PurchaseLineItem."Document No.", PurchaseLineItem."Line No.", Item."No.");

        // [GIVEN] Posted purchase invoice.
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [WHEN] Invoke "Create Corrective Credit Memo" from posted purchase invoice.
        CorrectPostedPurchInvoice.CreateCreditMemoCopyDocument(PurchInvHeader, PurchaseHeader);

        // [THEN] Two purchase lines are created for corrective credit memo.
        PurchaseLineItem.SetRange("Buy-from Vendor No.", Vendor."No.");
        Assert.RecordCount(PurchaseLineItem, 2);

        // [THEN] Number of charge item purchase line created for corrective credit memo is the same as of charge item.
        PurchaseLineItem.SetRange("No.", ItemCharge."No.");
        PurchaseLineItem.FindFirst;
        PurchaseLineItem.TestField("Unit Cost", 0);
        PurchaseLineItem.TestField("Qty. to Assign", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectPostedPurchaseInvoiceWithStandardText()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        CopiedPurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        StandardText: Record "Standard Text";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 323428] Posted Sales Invoice is copied to Corrective Credit Memo with item charge of zero unit cost.
        Initialize;

        // [GIVEN] Purchase invoice with two lines - first with standard text, second one with item
        UpdatePurchaseSetupForCorrectiveMemo(false, true);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo);
        LibrarySales.CreateStandardText(StandardText);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine[1], PurchaseHeader, PurchaseLine[1].Type::" ",
          StandardText.Code, LibraryRandom.RandInt(10));
        CreatePurchaseLine(
          PurchaseLine[2], PurchaseHeader, PurchaseLine[2].Type::Item, LibraryInventory.CreateItemNo,
          LibraryRandom.RandInt(10), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Posted purchase invoice
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [WHEN] Invoke "Create Corrective Credit Memo" from posted purchase invoice
        CorrectPostedPurchInvoice.CreateCreditMemoCopyDocument(PurchInvHeader, PurchaseHeader);

        // [THEN] Two purchase lines are created for corrective credit memo. First - with standard text
        CopiedPurchaseLine.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        Assert.RecordCount(CopiedPurchaseLine, 2);
        CopiedPurchaseLine.FindFirst;
        CopiedPurchaseLine.TestField(Type, CopiedPurchaseLine.Type::" ");
        CopiedPurchaseLine.TestField("No.", StandardText.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPurchaseOrderFromPostedPurchaseInvoiceWithResource()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ToPurchaseHeader: Record "Purchase Header";
        ToPurchaseLine: Record "Purchase Line";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        DocNo: Code[20];
    begin
        // [FEATURE] [Resource]
        // [SCENARIO 289386] Copy purchase order from posted purchase invoice with resource line and "Recalculate Lines" = true
        Initialize();

        // [GIVEN] Posted purchase invoice "PPI" with resource line 
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Resource, '', LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchaseLine.Modify(true);
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Purchase order "PO"
        LibraryPurchase.CreatePurchHeader(ToPurchaseHeader, ToPurchaseHeader."Document Type"::Order, PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Copy "PPI" to "PO", "Recalculate Lines" = true
        CopyDocumentMgt.SetProperties(true, true, false, false, false, false, false);
        CopyDocumentMgt.CopyPurchDoc(7, DocNo, ToPurchaseHeader); // 7 - posted invoice

        // [THEN] "PO" contains two lines
        ToPurchaseLine.SetRange("Document Type", ToPurchaseHeader."Document Type");
        ToPurchaseLine.SetRange("Document No.", ToPurchaseHeader."No.");
        Assert.RecordCount(ToPurchaseLine, 2);

        // [THEN] "PO" contains one "resource" line
        ToPurchaseLine.SetRange(Type, ToPurchaseLine.Type::Resource);
        ToPurchaseLine.SetRange("No.", PurchaseLine."No.");
        ToPurchaseLine.FindFirst();
        Assert.RecordCount(ToPurchaseLine, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPurchaseOrderFromPostedPurchaseInvoiceWithBlockedResource()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ToPurchaseHeader: Record "Purchase Header";
        ToPurchaseLine: Record "Purchase Line";
        Resource: Record Resource;
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        DocNo: Code[20];
    begin
        // [FEATURE] [Resource]
        // [SCENARIO 289386] Copy purchase order from posted purchase invoice with blocked resource line
        Initialize();

        // [GIVEN] Posted purchase invoice "PPI" with resource line 
        LibraryResource.CreateResourceNew(Resource);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Resource, Resource."No.", LibraryRandom.RandInt(10));
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Purchase order "PO"
        LibraryPurchase.CreatePurchHeader(ToPurchaseHeader, ToPurchaseHeader."Document Type"::Order, PurchaseHeader."Buy-from Vendor No.");

        // [GIVEN] Resource is blocked
        Resource.Validate(Blocked, true);
        Resource.Modify();

        // [WHEN] Copy "PPI" to "PO"
        CopyDocumentMgt.SetProperties(true, true, false, false, false, false, false);
        CopyDocumentMgt.CopyPurchDoc(7, DocNo, ToPurchaseHeader); // 7 - posted invoice

        // [THEN] "Resource" line was not coppied
        // [THEN] "PO" contains one comment line       
        ToPurchaseLine.SetRange("Document Type", ToPurchaseHeader."Document Type");
        ToPurchaseLine.SetRange("Document No.", ToPurchaseHeader."No.");
        Assert.RecordCount(ToPurchaseLine, 1);
        ToPurchaseLine.FindFirst();
        Assert.IsTrue(ToPurchaseLine.Type = ToPurchaseLine.Type::" ", WrongCopyPurchaseResourceErr);
        Assert.IsTrue(ToPurchaseLine."No." = '', WrongCopyPurchaseResourceErr);
        Assert.AreEqual(StrSubstNo(InvoiceNoTxt, DocNo), ToPurchaseLine.Description, WrongCopyPurchaseResourceErr);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPurchaseOrderFromPostedPurchaseReceiptWithResourceAndDeferral()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ToPurchaseHeader: Record "Purchase Header";
        ToPurchaseLine: Record "Purchase Line";
        Resource: Record Resource;
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        DocNo: Code[20];
    begin
        // [FEATURE] [Resource]
        // [SCENARIO 289386] "Deferral Code" is updated from resource when copy purchase order from posted purchase receipt and "Recalculate Lines" = false
        Initialize();

        // [GIVEN] Resource with default deferral template code "DTC1"
        LibraryResource.CreateResourceNew(Resource);
        Resource.Validate("Default Deferral Template Code", CreateDeferralTemplate());
        Resource.Modify(true);

        // [GIVEN] Posted purchase receipt "PPR" with resource line 
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Resource, Resource."No.", LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchaseLine.Modify(true);
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Resource with updated deferral template code "DTC2"
        Resource.Validate("Default Deferral Template Code", CreateDeferralTemplate());
        Resource.Modify(true);

        // [GIVEN] Purchase order "PO"
        LibraryPurchase.CreatePurchHeader(ToPurchaseHeader, ToPurchaseHeader."Document Type"::Order, PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Copy "PPR" to "PO", "Recalculate Lines" = false
        CopyDocumentMgt.SetProperties(true, false, false, false, false, false, false);
        CopyDocumentMgt.CopyPurchDoc(6, DocNo, ToPurchaseHeader); // 7 - posted receipt

        // [THEN] "PO" resource line "Deferral Code" = "DTC2"
        ToPurchaseLine.SetRange("Document Type", ToPurchaseHeader."Document Type");
        ToPurchaseLine.SetRange("Document No.", ToPurchaseHeader."No.");
        ToPurchaseLine.SetRange(Type, ToPurchaseLine.Type::Resource);
        ToPurchaseLine.FindFirst();
        Assert.AreEqual(Resource."Default Deferral Template Code", ToPurchaseLine."Deferral Code", WrongCopyPurchaseResourceErr);
    end;

    [Test]
    [HandlerFunctions('SalesListModalPageHandler')]
    [Scope('OnPrem')]
    procedure CanGetSalesLineToExistingPurchSpecialOrderOnBlankLocAddrNotChanged()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasingCode: Code[10];
    begin
        // [FEATURE] [Special Order] [Purchase] [Ship-to Address]
        // [SCENARIO 358333] Stan can add purchase line with "Get Sales Orders" to existing purchase special order on blank location if the ship-to address has not been changed.
        Initialize();

        // [GIVEN] Sales order set up for special order.
        PurchasingCode := CreatePurchasingCode(false, true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLineWithPurchasingCode(SalesLine, SalesHeader, PurchasingCode);

        // [GIVEN] Purchase order.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        PurchaseHeader.Modify(true);

        // [GIVEN] Populate the purchase order from the sales order with "Get Sales Orders".
        LibraryPurchase.GetSpecialOrder(PurchaseHeader);

        // [GIVEN] Add one more line to the sales order.
        CreateSalesLineWithPurchasingCode(SalesLine, SalesHeader, PurchasingCode);

        // [WHEN] Update the purchase order with "Get Sales Orders".
        LibraryPurchase.GetSpecialOrder(PurchaseHeader);

        // [THEN] A new purchase line has been added.
        FindLastLineOfPurchaseDocument(PurchaseHeader, PurchaseLine);
        PurchaseLine.TestField("No.", SalesLine."No.");
    end;

    [Test]
    [HandlerFunctions('SalesListModalPageHandler')]
    [Scope('OnPrem')]
    procedure CannotGetSalesLineToExistingPurchSpecialOrderOnBlankLocAddrChanged()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchasingCode: Code[10];
    begin
        // [FEATURE] [Special Order] [Purchase] [Ship-to Address]
        // [SCENARIO 358333] Stan cannot add purchase line with "Get Sales Orders" to existing purchase special order on blank location if the ship-to address has been changed on Company Information.
        Initialize();

        // [GIVEN] Sales order set up for special order.
        PurchasingCode := CreatePurchasingCode(false, true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLineWithPurchasingCode(SalesLine, SalesHeader, PurchasingCode);

        // [GIVEN] Purchase order.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        PurchaseHeader.Modify(true);

        // [GIVEN] Populate the purchase order from the sales order with "Get Sales Orders".
        LibraryPurchase.GetSpecialOrder(PurchaseHeader);

        // [GIVEN] Add one more line to the sales order.
        CreateSalesLineWithPurchasingCode(SalesLine, SalesHeader, PurchasingCode);

        // [GIVEN] Update Ship-to address on Company Information.
        UpdateShiptoAddrOfCompany();

        // [WHEN] Update the purchase order with "Get Sales Orders".
        asserterror LibraryPurchase.GetSpecialOrder(PurchaseHeader);

        // [THEN] Error is thrown pointing that ship-to address is different between the purchase and the sales order.
        Assert.ExpectedError(StrSubstNo(AddrChangedErr, PurchaseHeader."No.", SalesHeader."No."));
        Assert.ExpectedErrorCode('Dialog');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        PriceListLine: Record "Price List Line";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Copy Purch/Sales Doc");
        LibrarySetupStorage.Restore;
        PriceListLine.DeleteAll();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Copy Purch/Sales Doc");

        LibrarySales.SetCreditWarningsToNoWarnings;
        LibrarySales.SetStockoutWarning(false);
        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibraryERMCountryData.UpdateGeneralLedgerSetup;
        LibraryERMCountryData.UpdatePurchasesPayablesSetup;
        LibrarySetupStorage.SaveSalesSetup();
        LibrarySetupStorage.SavePurchasesSetup();
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibrarySetupStorage.SaveCompanyInformation();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Copy Purch/Sales Doc");
    end;

    local procedure SetRandomSalesValues(var ItemCost: Integer; var ItemPrice: Integer; var DestinationDocType: Option; var OriginalDocType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        RecordRef: RecordRef;
        NumOfDocTypes: Integer;
    begin
        RecordRef.GetTable(SalesHeader);
        NumOfDocTypes := GetNumberOfOptions(RecordRef.Number, SalesHeader.FieldNo("Document Type")) - 1;

        ItemCost := LibraryRandom.RandInt(100);
        ItemPrice := LibraryRandom.RandInt(100);
        DestinationDocType := LibraryRandom.RandInt(NumOfDocTypes) - 1;
        OriginalDocType := LibraryRandom.RandInt(NumOfDocTypes) - 1;
    end;

    local procedure SetRandomPurchaseValues(var ItemCost: Integer; var ItemPrice: Integer; var DestinationDocType: Option; var OriginalDocType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
        RecordRef: RecordRef;
        NumOfDocTypes: Integer;
    begin
        RecordRef.GetTable(PurchaseHeader);
        NumOfDocTypes := GetNumberOfOptions(RecordRef.Number, PurchaseHeader.FieldNo("Document Type")) - 1;

        ItemCost := LibraryRandom.RandInt(100);
        ItemPrice := LibraryRandom.RandInt(100);
        DestinationDocType := LibraryRandom.RandInt(NumOfDocTypes) - 1;
        OriginalDocType := LibraryRandom.RandInt(NumOfDocTypes) - 1;
    end;

    local procedure CopyPurchDocFromArchive(ToPurchaseHeader: Record "Purchase Header"; FromDocType: Integer; FromDocNo: Code[20]; IncludeHeader: Boolean; RecalculateLines: Boolean; ArchivedDocType: Integer)
    var
        PurchaseHeaderArchive: Record "Purchase Header Archive";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
    begin
        CopyDocumentMgt.SetProperties(
          IncludeHeader, RecalculateLines, false, false, false, false, false);
        PurchaseHeaderArchive.SetRange("Document Type", ArchivedDocType);
        PurchaseHeaderArchive.SetRange("No.", FromDocNo);
        PurchaseHeaderArchive.FindFirst;
        CopyDocumentMgt.SetArchDocVal(PurchaseHeaderArchive."Doc. No. Occurrence", PurchaseHeaderArchive."Version No.");
        CopyDocumentMgt.CopyPurchDoc(FromDocType, FromDocNo, ToPurchaseHeader);
    end;

    local procedure CopySalesDocFromArchive(var ToSalesHeader: Record "Sales Header"; FromDocType: Integer; FromDocNo: Code[20]; IncludeHeader: Boolean; RecalculateLines: Boolean; ArchivedDocType: Integer)
    var
        SalesHeaderArchive: Record "Sales Header Archive";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
    begin
        CopyDocumentMgt.SetProperties(
          IncludeHeader, RecalculateLines, false, false, false, false, false);
        SalesHeaderArchive.SetRange("Document Type", ArchivedDocType);
        SalesHeaderArchive.SetRange("No.", FromDocNo);
        SalesHeaderArchive.FindFirst;
        CopyDocumentMgt.SetArchDocVal(SalesHeaderArchive."Doc. No. Occurrence", SalesHeaderArchive."Version No.");
        CopyDocumentMgt.CopySalesDoc(FromDocType, FromDocNo, ToSalesHeader);
    end;

    local procedure RunCopyPurchaseDoc(DocumentNo: Code[20]; NewPurchHeader: Record "Purchase Header"; DocType: Option; IncludeHeader: Boolean; RecalculateLines: Boolean)
    var
        CopyPurchDoc: Report "Copy Purchase Document";
    begin
        Clear(CopyPurchDoc);
        CopyPurchDoc.InitializeRequest(DocType, DocumentNo, IncludeHeader, RecalculateLines);
        CopyPurchDoc.SetPurchHeader(NewPurchHeader);
        CopyPurchDoc.UseRequestPage(false);
        CopyPurchDoc.RunModal;
    end;

    local procedure RunCopySalesDoc(DocumentNo: Code[20]; NewSalesHeader: Record "Sales Header"; DocType: Option; IncludeHeader: Boolean; RecalculateLines: Boolean)
    begin
        RunCopySalesDocWithRequestPage(DocumentNo, NewSalesHeader, DocType, IncludeHeader, RecalculateLines, false);
    end;

    local procedure RunCopySalesDocWithRequestPage(DocumentNo: Code[20]; NewSalesHeader: Record "Sales Header"; DocType: Option; IncludeHeader: Boolean; RecalculateLines: Boolean; UseRequestPage: Boolean)
    var
        CopySalesDoc: Report "Copy Sales Document";
    begin
        Clear(CopySalesDoc);
        CopySalesDoc.InitializeRequest(DocType, DocumentNo, IncludeHeader, RecalculateLines);
        CopySalesDoc.SetSalesHeader(NewSalesHeader);
        CopySalesDoc.UseRequestPage(UseRequestPage);
        CopySalesDoc.RunModal;
    end;

    local procedure CopyPostedSalesInvoiceLines(var SalesHeader: Record "Sales Header")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        LinesNotCopied: Integer;
        MissingExCostRevLink: Boolean;
    begin
        SalesInvoiceLine.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        CopyDocMgt.SetProperties(false, false, false, false, true, true, false);
        CopyDocMgt.CopySalesInvLinesToDoc(
          SalesHeader, SalesInvoiceLine, LinesNotCopied, MissingExCostRevLink);
    end;

    local procedure CopyPostedPurchaseInvoiceLines(var PurchaseHeader: Record "Purchase Header")
    var
        PurchInvLine: Record "Purch. Inv. Line";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        LinesNotCopied: Integer;
        MissingExCostRevLink: Boolean;
    begin
        PurchInvLine.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        CopyDocMgt.SetProperties(false, false, false, false, true, true, false);
        CopyDocMgt.CopyPurchInvLinesToDoc(
          PurchaseHeader, PurchInvLine, LinesNotCopied, MissingExCostRevLink);
    end;

    local procedure CreatePostSalesDocWithItemDescriptionLine(var CustomerNo: Code[20]; var Description: Text[100]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          LibraryInventory.CreateItemNo, LibraryRandom.RandIntInRange(2, 5));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type, SalesLine."No.", 0);
        SalesLine.Validate("No.", '');
        SalesLine.Modify();
        LibraryUtility.FillFieldMaxText(SalesLine, SalesLine.FieldNo(Description));
        SalesLine.Find;

        CustomerNo := SalesHeader."Sell-to Customer No.";
        Description := SalesLine.Description;
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePostPurchDocWithItemDescriptionLine(var VendorNo: Code[20]; var Description: Text[100]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          LibraryInventory.CreateItemNo, LibraryRandom.RandIntInRange(2, 5));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type, PurchaseLine."No.", 0);
        PurchaseLine.Validate("No.", '');
        PurchaseLine.Modify();
        LibraryUtility.FillFieldMaxText(PurchaseLine, PurchaseLine.FieldNo(Description));
        PurchaseLine.Find;

        VendorNo := PurchaseHeader."Buy-from Vendor No.";
        Description := PurchaseLine.Description;
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreatePostSalesOrderWithGLAccount(var InvoiceNo: Code[20]; var GLAccountNo: Code[20]; CustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup, LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
        GLAccountNo := SalesLine."No.";
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreatePostSalesOrderWithItem(var InvoiceNo: Code[20]; var ShipmentNo: Code[20]; var ItemNo: Code[20]; CustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo, LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
        ItemNo := SalesLine."No.";
        ShipmentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreatePostPurchaseOrderWithGLAccount(var InvoiceNo: Code[20]; var GLAccountNo: Code[20]; VendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithPurchSetup, LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine.Modify(true);
        GLAccountNo := PurchaseLine."No.";
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreatePostPurchaseOrderWithItem(var InvoiceNo: Code[20]; var ReceiptNo: Code[20]; var ItemNo: Code[20]; VendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo, LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine.Modify(true);
        ItemNo := PurchaseLine."No.";
        ReceiptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateOneItemPurchDoc(var PurchHeader: Record "Purchase Header"; DocType: Option)
    var
        Item: Record Item;
    begin
        // Create a new purchase doc with only one item.
        LibraryInventory.CreateItem(Item);
        CreateOneItemPurchDocWithItem(PurchHeader, Item, DocType);
    end;

    local procedure CreateOneItemSalesDoc(var SalesHeader: Record "Sales Header"; DocType: Option)
    var
        Item: Record Item;
    begin
        // Create a new purchase doc with only one item.
        LibraryInventory.CreateItem(Item);
        CreateOneItemSalesDocWithItem(SalesHeader, Item, DocType);
    end;

    local procedure CreateOneItemPurchDocWithItem(var PurchHeader: Record "Purchase Header"; Item: Record Item; DocType: Option)
    var
        Vendor: Record Vendor;
        PurchLine: Record "Purchase Line";
    begin
        // No currency code to simplify "Direct unit cost" validation.
        Vendor.SetFilter("Currency Code", '''''');
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchHeader, DocType, Vendor."No.");

        // Set the workdate of the document to Today, so discounts can be applied
        PurchHeader.Validate("Order Date", WorkDate);
        PurchHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, Item."No.",
          LibraryRandom.RandInt(100));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchLine.Validate("Receipt Line No.", PurchLine."Line No.");
        PurchLine.Validate("Receipt No.", PurchLine."Document No.");
        PurchLine.Modify(true);
    end;

    local procedure CreateOneItemSalesDocWithItem(var SalesHeader: Record "Sales Header"; Item: Record Item; DocType: Option)
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, Customer."No.");

        // Set the workdate of the document to Today, so discounts can be applied
        SalesHeader.Validate("Order Date", WorkDate);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.",
          LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(100));
        SalesLine.Validate("Shipment Line No.", SalesLine."Line No.");
        SalesLine.Validate("Shipment No.", SalesLine."Document No.");
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchGLAccNo(GLAccountNo: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup);
        GLAccount.Rename(GLAccountNo);
        exit(GLAccountNo)
    end;

    local procedure CreateSalesGLAccNo(GLAccountNo: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup);
        GLAccount.Rename(GLAccountNo);
        exit(GLAccountNo)
    end;

    local procedure CreatePurchDocWithExtLines(var PurchHeader: Record "Purchase Header"; DocumentType: Option)
    var
        PurchLine: Record "Purchase Line";
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, DocumentType, LibraryPurchase.CreateVendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, CreateItemWithExtText,
          LibraryRandom.RandInt(100));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchLine.Modify(true);
        TransferExtendedText.PurchCheckIfAnyExtText(PurchLine, true);
        TransferExtendedText.InsertPurchExtText(PurchLine);
        FindLastLineOfPurchaseDocument(PurchHeader, PurchLine);
        InsertEmptyPurchLine(PurchHeader."Document Type", PurchHeader."No.", PurchLine."Line No." - 1);
    end;

    local procedure CreateSalesDocWithExtLines(var SalesHeader: Record "Sales Header"; DocumentType: Option)
    var
        SalesLine: Record "Sales Line";
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, LibrarySales.CreateCustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItemWithExtText,
          LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(100));
        SalesLine.Modify(true);
        TransferExtendedText.SalesCheckIfAnyExtText(SalesLine, true);
        TransferExtendedText.InsertSalesExtText(SalesLine);
        FindLastLineOfSalesDocument(SalesHeader, SalesLine);
        InsertEmptySalesLine(SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No." - 1);
    end;

    local procedure CreateSalesInvoiceWithInvDiscount(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; UnitPrice: Decimal)
    var
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(5));
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(SalesLine."Unit Price" / 2, SalesHeader);
    end;

    local procedure CreatePurchaseInvoiceWithInvDiscount(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; UnitCost: Decimal)
    var
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(5));
        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Modify(true);
        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(PurchaseLine."Direct Unit Cost" / 2, PurchaseHeader);
    end;

    local procedure CreatePurchHeaderWithPricesInclVAT(var PurchaseHeader: Record "Purchase Header"; PricesInclVAT: Boolean)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo);
        PurchaseHeader.Validate("Prices Including VAT", PricesInclVAT);
        PurchaseHeader.Modify();
    end;

    local procedure MockPurchCrMemoLineWithPricesInclVAT(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; PricesInclVAT: Boolean)
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr.Init();
        PurchCrMemoHdr."No." := LibraryUtility.GenerateGUID;
        PurchCrMemoHdr."Prices Including VAT" := PricesInclVAT;
        PurchCrMemoHdr."Pay-to Vendor No." := LibraryPurchase.CreateVendorNo;
        PurchCrMemoHdr.Insert();

        PurchCrMemoLine.Init();
        PurchCrMemoLine."Document No." := PurchCrMemoHdr."No.";
        PurchCrMemoLine.Insert();
        PurchCrMemoLine.SetRecFilter;
    end;

    local procedure MockPurchInvLineWithPricesInclVAT(var PurchInvLine: Record "Purch. Inv. Line"; PricesInclVAT: Boolean)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Init();
        PurchInvHeader."No." := LibraryUtility.GenerateGUID;
        PurchInvHeader."Prices Including VAT" := PricesInclVAT;
        PurchInvHeader."Pay-to Vendor No." := LibraryPurchase.CreateVendorNo;
        PurchInvHeader.Insert();

        PurchInvLine.Init();
        PurchInvLine."Document No." := PurchInvHeader."No.";
        PurchInvLine.Insert();
        PurchInvLine.SetRecFilter;
    end;

    local procedure MockPurchRcptLineWithPricesInclVAT(var PurchRcptLine: Record "Purch. Rcpt. Line"; PricesInclVAT: Boolean)
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo);
        PurchaseHeader."Prices Including VAT" := PricesInclVAT;
        PurchaseHeader.Modify();

        PurchRcptHeader.Init();
        PurchRcptHeader."No." := LibraryUtility.GenerateGUID;
        PurchRcptHeader."Order No." := PurchaseHeader."No.";
        PurchRcptHeader."Pay-to Vendor No." := LibraryPurchase.CreateVendorNo;
        PurchRcptHeader.Insert();

        PurchRcptLine.Init();
        PurchRcptLine."Document No." := PurchRcptHeader."No.";
        PurchRcptLine.Insert();
        PurchRcptLine.SetRecFilter;
    end;

    local procedure MockReturnShptLineWithPricesInclVAT(var ReturnShipmentLine: Record "Return Shipment Line"; PricesInclVAT: Boolean)
    var
        ReturnShipmentHeader: Record "Return Shipment Header";
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", LibraryPurchase.CreateVendorNo);
        PurchaseHeader."Prices Including VAT" := PricesInclVAT;
        PurchaseHeader.Modify();

        ReturnShipmentHeader.Init();
        ReturnShipmentHeader."No." := LibraryUtility.GenerateGUID;
        ReturnShipmentHeader."Return Order No." := PurchaseHeader."No.";
        ReturnShipmentHeader."Pay-to Vendor No." := LibraryPurchase.CreateVendorNo;
        ReturnShipmentHeader.Insert();

        ReturnShipmentLine.Init();
        ReturnShipmentLine."Document No." := ReturnShipmentHeader."No.";
        ReturnShipmentLine.Insert();
        ReturnShipmentLine.SetRecFilter;
    end;

    local procedure CreateSalesHeaderWithPricesInclVAT(var SalesHeader: Record "Sales Header"; PricesInclVAT: Boolean)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo);
        SalesHeader.Validate("Prices Including VAT", PricesInclVAT);
        SalesHeader.Modify();
    end;

    local procedure MockSalesShptLineWithPricesInclVAT(var SalesShipmentLine: Record "Sales Shipment Line"; PricesInclVAT: Boolean)
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesShipmentHeader.Init();
        SalesShipmentHeader."No." := LibraryUtility.GenerateGUID;
        SalesShipmentHeader."Prices Including VAT" := PricesInclVAT;
        SalesShipmentHeader.Insert();

        SalesShipmentLine.Init();
        SalesShipmentLine."Document No." := SalesShipmentHeader."No.";
        SalesShipmentLine.Insert();
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record 39; PurchaseHeader: Record 38; PurchaseLineType: Option; ItemNo: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLineType, ItemNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Option)
    begin
        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", DocumentType);
        PurchaseHeader.Insert(true);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Option)
    begin
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", DocumentType);
        SalesHeader.Insert(true);
    end;

    local procedure CreateSalesLineWithPurchasingCode(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; PurchasingCode: Code[10])
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        SalesLine.Validate("Purchasing Code", PurchasingCode);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchHeaderForVendor(var PurchaseHeader: Record "Purchase Header"; DocumentType: Option; VendorCode: Code[20])
    begin
        CreatePurchHeader(PurchaseHeader, DocumentType);

        // If Copy Purch Document is ran with IncludeHeader=False is mandatory to have the same vendor in original and destination doc.
        PurchaseHeader.Validate("Buy-from Vendor No.", VendorCode);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateSalesHeaderForCustomer(var SalesHeader: Record "Sales Header"; DocumentType: Option; CustomerCode: Code[20])
    begin
        CreateSalesHeader(SalesHeader, DocumentType);

        // If Copy Sales Document is ran with IncludeHeader=False is mandatory to have the same vendor in original and destination doc.
        SalesHeader.Validate("Sell-to Customer No.", CustomerCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateCopiableItem(var Item: Record Item; ItemCost: Integer; ItemPrice: Integer)
    begin
        // Create an item and set the last item cost, so when copying the lines we'll have a cost to retrieve (otherwise is 0).
        LibraryInventory.CreateItem(Item);
        Item.Validate("Last Direct Cost", ItemCost);
        Item.Validate("Unit Price", ItemPrice);
        Item.Modify(true);
    end;

    local procedure CreateVendorItemDiscount(var PurchaseLineDiscount: Record "Purchase Line Discount"; VendorCode: Code[20]; Item: Record Item)
    begin
        // Create a random discount without item quantity limitation (to be sure it is applied when recalculating lines)
        LibraryERM.CreateLineDiscForVendor(PurchaseLineDiscount,
          Item."No.", VendorCode, WorkDate, '', '',
          Item."Base Unit of Measure", 0);
        PurchaseLineDiscount.Validate("Line Discount %", LibraryRandom.RandInt(100));
        PurchaseLineDiscount.Modify(true);
    end;

    local procedure CreateCustomerItemDiscount(var SalesLineDiscount: Record "Sales Line Discount"; CustomerCode: Code[20]; Item: Record Item)
    begin
        // Create a random discount without item quantity limitation (to be sure it is applied when recalculating lines)
        LibraryERM.CreateLineDiscForCustomer(SalesLineDiscount,
          SalesLineDiscount.Type::Item, Item."No.", SalesLineDiscount."Sales Type"::Customer, CustomerCode, WorkDate, '', '',
          Item."Base Unit of Measure", 0);
        SalesLineDiscount.Validate("Line Discount %", LibraryRandom.RandInt(100));
        SalesLineDiscount.Modify(true);
    end;

    local procedure CreateItemWithExtText(): Code[20]
    var
        Item: Record Item;
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        LibraryService.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        UpdateTextInExtendedTextLine(ExtendedTextLine, Item."No.");
        LibraryService.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        UpdateTextInExtendedTextLine(ExtendedTextLine, Item."No.");
        exit(Item."No.");
    end;

    local procedure CreatePostSalesDocWithShiptoAddr(DocumentType: Option; CustomerNo: Code[20]; ShiptoCode: Code[10]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        UpdateShiptoAddrSalesHeader(SalesHeader);
        SalesHeader.Validate("Ship-to Code", ShiptoCode);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo, LibraryRandom.RandIntInRange(1, 10));
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateCustomerWithShiptoAddr(var Customer: Record Customer): Code[10]
    begin
        LibrarySales.CreateCustomer(Customer);
        UpdateAddrOfCustomer(Customer);
        exit(CreateShiptoAddrCustomer(Customer."No."));
    end;

    local procedure CreateShiptoAddrCustomer(CustomerNo: Code[20]): Code[10]
    var
        ShipToAddress: Record "Ship-to Address";
    begin
        LibrarySales.CreateShipToAddress(ShipToAddress, CustomerNo);
        LibraryUtility.FillFieldMaxText(ShipToAddress, ShipToAddress.FieldNo(Name));
        ShipToAddress.Get(CustomerNo, ShipToAddress.Code);
        LibraryUtility.FillFieldMaxText(ShipToAddress, ShipToAddress.FieldNo("Name 2"));
        ShipToAddress.Get(CustomerNo, ShipToAddress.Code);
        LibraryUtility.FillFieldMaxText(ShipToAddress, ShipToAddress.FieldNo(Address));
        ShipToAddress.Get(CustomerNo, ShipToAddress.Code);
        LibraryUtility.FillFieldMaxText(ShipToAddress, ShipToAddress.FieldNo("Address 2"));
        ShipToAddress.Get(CustomerNo, ShipToAddress.Code);
        LibraryUtility.FillFieldMaxText(ShipToAddress, ShipToAddress.FieldNo(County));
        ShipToAddress.Get(CustomerNo, ShipToAddress.Code);
        ShipToAddress.Validate("Post Code", CreatePostCode);
        ShipToAddress.Modify();
        exit(ShipToAddress.Code);
    end;

    local procedure CreatePostCode(): Code[20]
    var
        PostCode: Record "Post Code";
    begin
        LibraryERM.CreatePostCode(PostCode);
        LibraryUtility.FillFieldMaxText(PostCode, PostCode.FieldNo(County));
        exit(PostCode.Code);
    end;

    local procedure CreatePurchasingCode(IsDropShipment: Boolean; IsSpecialOrder: Boolean): Code[10]
    var
        Purchasing: Record Purchasing;
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Drop Shipment", IsDropShipment);
        Purchasing.Validate("Special Order", IsSpecialOrder);
        Purchasing.Modify(true);
        exit(Purchasing.Code);
    end;

    local procedure CalcInvoiceDiscountOnSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; No: Code[20])
    var
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("No.", No);
        SalesLine.FindFirst;
        SalesCalcDiscountByType.CalcInvoiceDiscOnLine(true);
        SalesCalcDiscountByType.Run(SalesLine);
    end;

    local procedure CalcInvoiceDiscountOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; No: Code[20])
    var
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst;
        PurchCalcDiscount.CalculateInvoiceDiscountOnLine(PurchaseLine);
    end;

    local procedure UpdatePurchLinePurchasingCodeDropShipmentSpecialOrder(PurchaseHeader: Record "Purchase Header"; PurchasingCode: Code[10]; DropShipment: Boolean; SpecialOrder: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        FindFirstLineOfPurchaseDocument(PurchaseHeader, PurchaseLine);
        PurchaseLine.Validate("Purchasing Code", PurchasingCode);
        PurchaseLine.Validate("Drop Shipment", DropShipment);
        PurchaseLine.Validate("Special Order", SpecialOrder);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateSalesLinePurchasingCodeDropShipmentSpecialOrder(SalesHeader: Record "Sales Header"; PurchasingCode: Code[10]; DropShipment: Boolean; SpecialOrder: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        FindFirstLineOfSalesDocument(SalesHeader, SalesLine);
        SalesLine.Validate("Purchasing Code", PurchasingCode);
        SalesLine.Validate("Drop Shipment", DropShipment);
        SalesLine.Validate("Special Order", SpecialOrder);
        SalesLine.Modify(true);
    end;

    local procedure UpdateTextInExtendedTextLine(var ExtendedTextLine: Record "Extended Text Line"; Text: Code[20])
    begin
        ExtendedTextLine.Validate(Text, Text);
        ExtendedTextLine.Modify(true);
    end;

    local procedure InsertEmptyPurchLine(DocumentType: Option; DocumentNo: Code[20]; LineNo: Integer)
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.Init();
        PurchLine."Document Type" := DocumentType;
        PurchLine."Document No." := DocumentNo;
        PurchLine."Line No." := LineNo;
        PurchLine.Insert();
        LibraryUtility.FillFieldMaxText(PurchLine, PurchLine.FieldNo(Description));
    end;

    local procedure InsertEmptySalesLine(DocumentType: Option; DocumentNo: Code[20]; LineNo: Integer)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Init();
        SalesLine."Document Type" := DocumentType;
        SalesLine."Document No." := DocumentNo;
        SalesLine.Type := SalesLine.Type::" ";
        SalesLine."Line No." := LineNo;
        SalesLine.Insert();
        LibraryUtility.FillFieldMaxText(SalesLine, SalesLine.FieldNo(Description));
    end;

    local procedure SetPurchInvoiceRoundingAccount(VendorPostingGroupCode: Code[20]; GLAccountNo: Code[20]) OldGLAccountNo: Code[20]
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        VendorPostingGroup.Get(VendorPostingGroupCode);
        OldGLAccountNo := VendorPostingGroup."Invoice Rounding Account";
        VendorPostingGroup.Validate("Invoice Rounding Account", GLAccountNo);
        VendorPostingGroup.Modify();
    end;

    local procedure SetSalesInvoiceRoundingAccount(CustomerPostingGroupCode: Code[20]; GLAccountNo: Code[20]) OldGLAccountNo: Code[20]
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustomerPostingGroup.Get(CustomerPostingGroupCode);
        OldGLAccountNo := CustomerPostingGroup."Invoice Rounding Account";
        CustomerPostingGroup.Validate("Invoice Rounding Account", GLAccountNo);
        CustomerPostingGroup.Modify();
    end;

    local procedure UpdateShiptoAddrOfCompany()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        LibraryUtility.FillFieldMaxText(CompanyInformation, CompanyInformation.FieldNo("Ship-to Name"));
        CompanyInformation.Get();
        LibraryUtility.FillFieldMaxText(CompanyInformation, CompanyInformation.FieldNo("Ship-to Name 2"));
        CompanyInformation.Get();
        LibraryUtility.FillFieldMaxText(CompanyInformation, CompanyInformation.FieldNo("Ship-to Address"));
        CompanyInformation.Get();
        LibraryUtility.FillFieldMaxText(CompanyInformation, CompanyInformation.FieldNo("Ship-to Address 2"));
        CompanyInformation.Get();
        LibraryUtility.FillFieldMaxText(CompanyInformation, CompanyInformation.FieldNo("Ship-to Contact"));
        CompanyInformation.Get();
        CompanyInformation.Validate("Ship-to Post Code", CreatePostCode);
        CompanyInformation.Modify();
    end;

    local procedure UpdateShiptoAddrSalesHeader(var SalesHeader: Record "Sales Header")
    begin
        LibraryUtility.FillFieldMaxText(SalesHeader, SalesHeader.FieldNo("Ship-to Name"));
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        LibraryUtility.FillFieldMaxText(SalesHeader, SalesHeader.FieldNo("Ship-to Name 2"));
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        LibraryUtility.FillFieldMaxText(SalesHeader, SalesHeader.FieldNo("Ship-to Address"));
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        LibraryUtility.FillFieldMaxText(SalesHeader, SalesHeader.FieldNo("Ship-to Address 2"));
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        LibraryUtility.FillFieldMaxText(SalesHeader, SalesHeader.FieldNo("Ship-to Contact"));
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        SalesHeader.Validate("Ship-to Post Code", CreatePostCode);
        SalesHeader.Modify();
    end;

    local procedure UpdateAddrOfCustomer(var Customer: Record Customer)
    begin
        LibraryUtility.FillFieldMaxText(Customer, Customer.FieldNo(Name));
        Customer.Get(Customer."No.");
        LibraryUtility.FillFieldMaxText(Customer, Customer.FieldNo("Name 2"));
        Customer.Get(Customer."No.");
        LibraryUtility.FillFieldMaxText(Customer, Customer.FieldNo(Address));
        Customer.Get(Customer."No.");
        LibraryUtility.FillFieldMaxText(Customer, Customer.FieldNo("Address 2"));
        Customer.Get(Customer."No.");
        LibraryUtility.FillFieldMaxText(Customer, Customer.FieldNo(Contact));
        Customer.Get(Customer."No.");
        Customer.Validate("Post Code", CreatePostCode);
        Customer.Modify();
    end;

    local procedure UpdateShiptoAddrOfPurchOrder(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10])
    begin
        LibraryUtility.FillFieldMaxText(PurchaseHeader, PurchaseHeader.FieldNo("Ship-to Address"));
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        LibraryUtility.FillFieldMaxText(PurchaseHeader, PurchaseHeader.FieldNo("Ship-to Address 2"));
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        LibraryUtility.FillFieldMaxText(PurchaseHeader, PurchaseHeader.FieldNo("Ship-to City"));
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        LibraryUtility.FillFieldMaxText(PurchaseHeader, PurchaseHeader.FieldNo("Ship-to Country/Region Code"));
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        LibraryUtility.FillFieldMaxText(PurchaseHeader, PurchaseHeader.FieldNo("Ship-to County"));
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        LibraryUtility.FillFieldMaxText(PurchaseHeader, PurchaseHeader.FieldNo("Ship-to Name"));
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        LibraryUtility.FillFieldMaxText(PurchaseHeader, PurchaseHeader.FieldNo("Ship-to Name 2"));
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        LibraryUtility.FillFieldMaxText(PurchaseHeader, PurchaseHeader.FieldNo("Ship-to Post Code"));
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        LibraryUtility.FillFieldMaxText(PurchaseHeader, PurchaseHeader.FieldNo("Ship-to Contact"));
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        Evaluate(PurchaseHeader."Inbound Whse. Handling Time", StrSubstNo('<%1D>', LibraryRandom.RandIntInRange(5, 10)));
        PurchaseHeader."Location Code" := LocationCode;
        PurchaseHeader.Modify();
    end;

    local procedure UpdateSalesSetupCalcInvDiscount(CalcInvDiscount: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Calc. Inv. Discount", CalcInvDiscount);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdatePurchaseSetupCalcInvDiscount(CalcInvDiscount: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Calc. Inv. Discount", CalcInvDiscount);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdatePurchaseSetupForCorrectiveMemo(ReceiptOnInvoice: Boolean; ExactCostReversingMandatory: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Receipt on Invoice", ReceiptOnInvoice);
        PurchasesPayablesSetup.Validate("Exact Cost Reversing Mandatory", ExactCostReversingMandatory);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure FindFirstLineOfPurchaseDocument(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst;
    end;

    local procedure FindFirstLineOfSalesDocument(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst;
    end;

    local procedure FindLastLineOfPurchaseDocument(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindLast;
    end;

    local procedure FindLastLineOfSalesDocument(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindLast;
    end;

    local procedure GetNumberOfOptions(TableID: Integer; FieldNo: Integer): Integer
    var
        "Field": Record "Field";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        OptionStringCommas: Text[30];
    begin
        RecordRef.Open(TableID);
        FieldRef := RecordRef.Field(FieldNo);
        Field.Get(RecordRef.Number, FieldRef.Number);
        if Field.Type <> Field.Type::Option then
            exit(0);
        OptionStringCommas := DelChr(FieldRef.OptionMembers, '=', DelChr(FieldRef.OptionMembers, '=', ','));
        if (StrLen(OptionStringCommas) = 0) and (StrLen(FieldRef.OptionMembers) = 0) then
            exit(0);
        exit(StrLen(OptionStringCommas) + 1);
    end;

    local procedure MapperPurchaseHeaders(PurchHeaderDocType: Option) ReportDocType: Integer
    var
        PurchHeader: Record "Purchase Header";
    begin
        case PurchHeaderDocType of
            PurchHeader."Document Type"::Quote:
                ReportDocType := PurchDocType::Quote;
            PurchHeader."Document Type"::Order:
                ReportDocType := PurchDocType::Order;
            PurchHeader."Document Type"::Invoice:
                ReportDocType := PurchDocType::Invoice;
            PurchHeader."Document Type"::"Credit Memo":
                ReportDocType := PurchDocType::"Credit Memo";
            PurchHeader."Document Type"::"Blanket Order":
                ReportDocType := PurchDocType::"Blanket Order";
            PurchHeader."Document Type"::"Return Order":
                ReportDocType := PurchDocType::"Return Order";
        end;
    end;

    local procedure MapperSalesHeaders(SalesHeaderDocType: Option) ReportDocType: Integer
    var
        SalesHeader: Record "Sales Header";
    begin
        case SalesHeaderDocType of
            SalesHeader."Document Type"::Quote:
                ReportDocType := SalesDocType::Quote;
            SalesHeader."Document Type"::Order:
                ReportDocType := SalesDocType::Order;
            SalesHeader."Document Type"::Invoice:
                ReportDocType := SalesDocType::Invoice;
            SalesHeader."Document Type"::"Credit Memo":
                ReportDocType := SalesDocType::"Credit Memo";
            SalesHeader."Document Type"::"Blanket Order":
                ReportDocType := SalesDocType::"Blanket Order";
            SalesHeader."Document Type"::"Return Order":
                ReportDocType := SalesDocType::"Return Order";
        end;
    end;

    local procedure PrepareSalesTest(var Item: Record Item; var OriginalDocType: Enum "Sales Document Type"; var DestinationDocType: Option; var ItemCost: Integer; var ItemPrice: Integer)
    begin
        SetRandomSalesValues(ItemCost, ItemPrice, DestinationDocType, OriginalDocType);
        CreateCopiableItem(Item, ItemCost, ItemPrice);
    end;

    local procedure PreparePurchaseTest(var Item: Record Item; var OriginalDocType: Enum "Purchase Document Type"; var DestinationDocType: Option; var ItemCost: Integer; var ItemPrice: Integer)
    begin
        SetRandomPurchaseValues(ItemCost, ItemPrice, DestinationDocType, OriginalDocType);
        CreateCopiableItem(Item, ItemCost, ItemPrice);
    end;

    local procedure VerifyPurchLinePurchasingCodeDropShipmentSpecialOrder(PurchaseHeader: Record "Purchase Header"; PurchasingCode: Code[10]; DropShipment: Boolean; SpecialOrder: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        FindFirstLineOfPurchaseDocument(PurchaseHeader, PurchaseLine);
        PurchaseLine.TestField("Purchasing Code", PurchasingCode);
        PurchaseLine.TestField("Drop Shipment", DropShipment);
        PurchaseLine.TestField("Special Order", SpecialOrder);
    end;

    local procedure VerifySalesLinePurchasingCodeDropShipmentSpecialOrder(SalesHeader: Record "Sales Header"; PurchasingCode: Code[10]; DropShipment: Boolean; SpecialOrder: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        FindFirstLineOfSalesDocument(SalesHeader, SalesLine);
        SalesLine.TestField("Purchasing Code", PurchasingCode);
        SalesLine.TestField("Drop Shipment", DropShipment);
        SalesLine.TestField("Special Order", SpecialOrder);
    end;

    local procedure VerifyPurchaseHeadersAreEqual(OriginalPurchHeader: Record "Purchase Header"; CopiedPurchHeader: Record "Purchase Header")
    begin
        OriginalPurchHeader.TestField("Buy-from Vendor No.", CopiedPurchHeader."Buy-from Vendor No.");
        OriginalPurchHeader.TestField(Amount, CopiedPurchHeader.Amount);
    end;

    local procedure VerifySalesHeadersAreEqual(OriginalSalesHeader: Record "Sales Header"; CopiedSalesHeader: Record "Sales Header")
    begin
        OriginalSalesHeader.TestField("Sell-to Customer No.", CopiedSalesHeader."Sell-to Customer No.");
        OriginalSalesHeader.TestField(Amount, CopiedSalesHeader.Amount);
    end;

    local procedure VerifyPurchaseLinesAreEqual(PurchHeaderOriginal: Record "Purchase Header"; PurchHeaderCopied: Record "Purchase Header")
    var
        OriginalPurchLine: Record "Purchase Line";
        DestinationPurchLine: Record "Purchase Line";
    begin
        // Assumes only one line of each type exists in the purchase order.
        FindFirstLineOfPurchaseDocument(PurchHeaderOriginal, OriginalPurchLine);
        FindFirstLineOfPurchaseDocument(PurchHeaderCopied, DestinationPurchLine);

        ValidatePurchaseLine(DestinationPurchLine,
          OriginalPurchLine.Quantity,
          OriginalPurchLine."Direct Unit Cost",
          OriginalPurchLine."Line Discount %");
    end;

    local procedure VerifySalesLinesAreEqual(SalesHeaderOriginal: Record "Sales Header"; SalesHeaderCopied: Record "Sales Header")
    var
        OriginalSalesLine: Record "Sales Line";
        DestinationSalesLine: Record "Sales Line";
    begin
        // Assumes only one line of each type exists in the sales order.
        FindFirstLineOfSalesDocument(SalesHeaderOriginal, OriginalSalesLine);
        FindFirstLineOfSalesDocument(SalesHeaderCopied, DestinationSalesLine);

        ValidateSalesLine(DestinationSalesLine,
          OriginalSalesLine.Quantity,
          OriginalSalesLine."Unit Price",
          OriginalSalesLine."Line Discount %");
    end;

    local procedure ValidatePurchaseLine(PurchLine: Record "Purchase Line"; Quantity: Integer; DirectUnitCost: Integer; LineDiscount: Integer)
    begin
        PurchLine.TestField(Quantity, Quantity);
        PurchLine.TestField("Direct Unit Cost", DirectUnitCost);
        PurchLine.TestField("Line Discount %", LineDiscount);
        PurchLine.TestField("Receipt Line No.", 0);
        PurchLine.TestField("Receipt No.", '');
    end;

    local procedure ValidateSalesLine(SalesLine: Record "Sales Line"; Quantity: Integer; UnitPrice: Integer; LineDiscount: Integer)
    begin
        SalesLine.TestField(Quantity, Quantity);
        SalesLine.TestField("Unit Price", UnitPrice);
        SalesLine.TestField("Line Discount %", LineDiscount);
        SalesLine.TestField("Shipment Line No.", 0);
        SalesLine.TestField("Shipment No.", '');
    end;

    local procedure VerifyCopiedSalesLines(CopiedDocument: Variant; TypeFieldNo: Integer; DescriptionFieldNo: Integer; SalesDocType: Option; SalesDocNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        RecRef: RecordRef;
        ExpectedType: Option;
        ExpectedDescription: Text;
    begin
        SalesLine.SetRange("Document Type", SalesDocType);
        SalesLine.SetRange("Document No.", SalesDocNo);
        SalesLine.FindSet;
        SalesLine.Next;
        RecRef.GetTable(CopiedDocument);
        RecRef.FindSet;
        repeat
            ExpectedType := RecRef.Field(TypeFieldNo).Value;
            SalesLine.TestField(Type, ExpectedType);
            ExpectedDescription := RecRef.Field(DescriptionFieldNo).Value;
            SalesLine.TestField(Description, ExpectedDescription);
            RecRef.Next;
        until SalesLine.Next = 0;
    end;

    local procedure VerifyCopiedPurchLines(CopiedDocument: Variant; TypeFieldNo: Integer; DescriptionFieldNo: Integer; PurchDocType: Option; PurchDocNo: Code[20])
    var
        PurchLine: Record "Purchase Line";
        RecRef: RecordRef;
        ExpectedType: Option;
        ExpectedDescription: Text;
    begin
        PurchLine.SetRange("Document Type", PurchDocType);
        PurchLine.SetRange("Document No.", PurchDocNo);
        PurchLine.FindSet;
        PurchLine.Next;
        RecRef.GetTable(CopiedDocument);
        RecRef.FindSet;
        repeat
            ExpectedType := RecRef.Field(TypeFieldNo).Value;
            PurchLine.TestField(Type, ExpectedType);
            ExpectedDescription := RecRef.Field(DescriptionFieldNo).Value;
            PurchLine.TestField(Description, ExpectedDescription);
            RecRef.Next;
        until PurchLine.Next = 0;
    end;

    local procedure VerifySalesDescriptionLineExists(SalesHeader: Record "Sales Header"; ExpectedDescription: Text[100])
    var
        DummySalesLine: Record "Sales Line";
    begin
        with DummySalesLine do begin
            SetRange("Document Type", SalesHeader."Document Type");
            SetRange("Document No.", SalesHeader."No.");
            SetRange(Type, Type::" ");
            SetRange("No.", '');
            SetRange(Description, ExpectedDescription);
            Assert.RecordIsNotEmpty(DummySalesLine);
        end;
    end;

    local procedure VerifyPurchDescriptionLineExists(PurchaseHeader: Record "Purchase Header"; ExpectedDescription: Text[100])
    var
        DummyPurchaseLine: Record "Purchase Line";
    begin
        with DummyPurchaseLine do begin
            SetRange("Document Type", PurchaseHeader."Document Type");
            SetRange("Document No.", PurchaseHeader."No.");
            SetRange(Type, Type::" ");
            SetRange("No.", '');
            SetRange(Description, ExpectedDescription);
            Assert.RecordIsNotEmpty(DummyPurchaseLine);
        end;
    end;

    local procedure VerifyShiptoAddressInSalesDocToCompanyInfo(SalesHeader: Record "Sales Header")
    var
        CompanyInformation: Record "Company Information";
        ShiptoAddr: array[9] of Text;
    begin
        CompanyInformation.Get();
        ShiptoAddr[1] := CompanyInformation."Ship-to Name";
        ShiptoAddr[2] := CompanyInformation."Ship-to Name 2";
        ShiptoAddr[3] := CompanyInformation."Ship-to Address";
        ShiptoAddr[4] := CompanyInformation."Ship-to Address 2";
        ShiptoAddr[5] := CompanyInformation."Ship-to City";
        ShiptoAddr[6] := CompanyInformation."Ship-to Post Code";
        ShiptoAddr[7] := CompanyInformation."Ship-to County";
        ShiptoAddr[8] := CompanyInformation."Ship-to Country/Region Code";
        ShiptoAddr[9] := CompanyInformation."Ship-to Contact";
        VerifyShiptoAddrSalesDoc(SalesHeader, ShiptoAddr);
    end;

    local procedure VerifyShiptoAddressSalesDocToCustomerAddress(SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        Customer: Record Customer;
        ShiptoAddr: array[9] of Text;
    begin
        Customer.SetRange("No.", CustomerNo);
        Customer.FindFirst;
        ShiptoAddr[1] := Customer.Name;
        ShiptoAddr[2] := Customer."Name 2";
        ShiptoAddr[3] := Customer.Address;
        ShiptoAddr[4] := Customer."Address 2";
        ShiptoAddr[5] := Customer.City;
        ShiptoAddr[6] := Customer."Post Code";
        ShiptoAddr[7] := Customer.County;
        ShiptoAddr[8] := Customer."Country/Region Code";
        ShiptoAddr[9] := Customer.Contact;
        VerifyShiptoAddrSalesDoc(SalesHeader, ShiptoAddr);
    end;

    local procedure VerifyShiptoAddressSalesDocToShiptoAddress(SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        ShipToAddress: Record "Ship-to Address";
        ShiptoAddr: array[9] of Text;
    begin
        ShipToAddress.SetRange("Customer No.", CustomerNo);
        ShipToAddress.FindFirst;
        ShiptoAddr[1] := ShipToAddress.Name;
        ShiptoAddr[2] := ShipToAddress."Name 2";
        ShiptoAddr[3] := ShipToAddress.Address;
        ShiptoAddr[4] := ShipToAddress."Address 2";
        ShiptoAddr[5] := ShipToAddress.City;
        ShiptoAddr[6] := ShipToAddress."Post Code";
        ShiptoAddr[7] := ShipToAddress.County;
        ShiptoAddr[8] := ShipToAddress."Country/Region Code";
        ShiptoAddr[9] := ShipToAddress.Contact;
        VerifyShiptoAddrSalesDoc(SalesHeader, ShiptoAddr);
    end;

    local procedure VerifyShiptoAddrSalesDoc(SalesHeader: Record "Sales Header"; ShiptoAddr: array[9] of Text)
    begin
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        SalesHeader.TestField("Ship-to Name", ShiptoAddr[1]);
        SalesHeader.TestField("Ship-to Name 2", ShiptoAddr[2]);
        SalesHeader.TestField("Ship-to Address", ShiptoAddr[3]);
        SalesHeader.TestField("Ship-to Address 2", ShiptoAddr[4]);
        SalesHeader.TestField("Ship-to City", ShiptoAddr[5]);
        SalesHeader.TestField("Ship-to Post Code", ShiptoAddr[6]);
        SalesHeader.TestField("Ship-to County", ShiptoAddr[7]);
        SalesHeader.TestField("Ship-to Country/Region Code", ShiptoAddr[8]);
        SalesHeader.TestField("Ship-to Contact", ShiptoAddr[9]);
    end;

    local procedure VerifySalesLineAndStepNext(var SalesLine: Record "Sales Line"; ExpectedType: Option; ExpectedNo: Code[20]; ExpectedDescription: Text; StepNext: Boolean)
    begin
        with SalesLine do begin
            Assert.AreEqual(ExpectedType, Type, FieldCaption(Type));
            Assert.AreEqual(ExpectedNo, "No.", FieldCaption("No."));
            Assert.ExpectedMessage(ExpectedDescription, Description);
            if StepNext then
                Next;
        end;
    end;

    local procedure VerifySalesDescriptionLine(var SalesLine: Record "Sales Line"; ExpectedDescription: Text)
    begin
        VerifySalesLineAndStepNext(SalesLine, SalesLine.Type::" ", '', ExpectedDescription, true);
    end;

    local procedure VerifySalesCombinedDescriptionLine(var SalesLine: Record "Sales Line"; ExpectedDescription1: Text; ExpectedDescription2: Text)
    begin
        VerifySalesLineAndStepNext(SalesLine, SalesLine.Type::" ", '', ExpectedDescription1, false);
        VerifySalesLineAndStepNext(SalesLine, SalesLine.Type::" ", '', ExpectedDescription2, true);
    end;

    local procedure VerifySalesInvoiceDescription(var SalesLine: Record "Sales Line"; InvoiceNo: Code[20]; GLAccountNo: Code[20])
    begin
        VerifySalesDescriptionLine(SalesLine, InvoiceNo);
        VerifySalesLineAndStepNext(SalesLine, SalesLine.Type::"G/L Account", GLAccountNo, SalesLine."No.", true);
    end;

    local procedure VerifySalesInvoiceShipmentDescription(var SalesLine: Record "Sales Line"; InvoiceNo: Code[20]; ShipmentNo: Code[20]; ItemNo: Code[20])
    begin
        VerifySalesDescriptionLine(SalesLine, InvoiceNo);
        VerifySalesCombinedDescriptionLine(SalesLine, InvoiceNo, ShipmentNo);
        VerifySalesLineAndStepNext(SalesLine, SalesLine.Type::Item, ItemNo, SalesLine."No.", true);
    end;

    local procedure VerifySalesAttachedLines(SalesHeader: Record "Sales Header"; ExpectedCount: Integer)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst;
        SalesLine.SetRange("Attached to Line No.", SalesLine."Line No.");
        SalesLine.SetRange(Type, SalesLine.Type::" ");
        Assert.RecordCount(SalesLine, ExpectedCount);
    end;

    local procedure VerifyPurchaseLineAndStepNext(var PurchaseLine: Record "Purchase Line"; ExpectedType: Option; ExpectedNo: Code[20]; ExpectedDescription: Text; StepNext: Boolean)
    begin
        with PurchaseLine do begin
            Assert.AreEqual(ExpectedType, Type, FieldCaption(Type));
            Assert.AreEqual(ExpectedNo, "No.", FieldCaption("No."));
            Assert.ExpectedMessage(ExpectedDescription, Description);
            if StepNext then
                Next;
        end;
    end;

    local procedure VerifyPurchaseDescriptionLine(var PurchaseLine: Record "Purchase Line"; ExpectedDescription: Text)
    begin
        VerifyPurchaseLineAndStepNext(PurchaseLine, PurchaseLine.Type::" ", '', ExpectedDescription, true);
    end;

    local procedure VerifyPurchaseCombinedDescriptionLine(var PurchaseLine: Record "Purchase Line"; ExpectedDescription1: Text; ExpectedDescription2: Text)
    begin
        VerifyPurchaseLineAndStepNext(PurchaseLine, PurchaseLine.Type::" ", '', ExpectedDescription1, false);
        VerifyPurchaseLineAndStepNext(PurchaseLine, PurchaseLine.Type::" ", '', ExpectedDescription2, true);
    end;

    local procedure VerifyPurchaseInvoiceDescription(var PurchaseLine: Record "Purchase Line"; InvoiceNo: Code[20]; GLAccountNo: Code[20])
    begin
        VerifyPurchaseDescriptionLine(PurchaseLine, InvoiceNo);
        VerifyPurchaseLineAndStepNext(PurchaseLine, PurchaseLine.Type::"G/L Account", GLAccountNo, PurchaseLine."No.", true);
    end;

    local procedure VerifyPurchaseInvoiceReceiptDescription(var PurchaseLine: Record "Purchase Line"; InvoiceNo: Code[20]; ReceiptNo: Code[20]; ItemNo: Code[20])
    begin
        VerifyPurchaseDescriptionLine(PurchaseLine, InvoiceNo);
        VerifyPurchaseCombinedDescriptionLine(PurchaseLine, InvoiceNo, ReceiptNo);
        VerifyPurchaseLineAndStepNext(PurchaseLine, PurchaseLine.Type::Item, ItemNo, PurchaseLine."No.", true);
    end;

    local procedure VerifyShiptoAddressPurchaseOrder(FromPurchaseHeader: Record "Purchase Header"; ToPurchaseHeader: Record "Purchase Header")
    begin
        ToPurchaseHeader.Get(ToPurchaseHeader."Document Type", ToPurchaseHeader."No.");
        ToPurchaseHeader.TestField("Ship-to Address", FromPurchaseHeader."Ship-to Address");
        ToPurchaseHeader.TestField("Ship-to Address 2", FromPurchaseHeader."Ship-to Address 2");
        ToPurchaseHeader.TestField("Ship-to City", FromPurchaseHeader."Ship-to City");
        ToPurchaseHeader.TestField("Ship-to Country/Region Code", FromPurchaseHeader."Ship-to Country/Region Code");
        ToPurchaseHeader.TestField("Ship-to County", FromPurchaseHeader."Ship-to County");
        ToPurchaseHeader.TestField("Ship-to Name", FromPurchaseHeader."Ship-to Name");
        ToPurchaseHeader.TestField("Ship-to Name 2", FromPurchaseHeader."Ship-to Name 2");
        ToPurchaseHeader.TestField("Ship-to Post Code", FromPurchaseHeader."Ship-to Post Code");
        ToPurchaseHeader.TestField("Ship-to Contact", FromPurchaseHeader."Ship-to Contact");
        ToPurchaseHeader.TestField("Inbound Whse. Handling Time", FromPurchaseHeader."Inbound Whse. Handling Time");
        ToPurchaseHeader.TestField("Location Code", FromPurchaseHeader."Location Code");
    end;

    local procedure VerifyPurchaseAttachedLines(PurchaseHeader: Record "Purchase Header"; ExpectedCount: Integer)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindFirst;
        PurchaseLine.SetRange("Attached to Line No.", PurchaseLine."Line No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::" ");
        Assert.RecordCount(PurchaseLine, ExpectedCount);
    end;

    local procedure CreateDeferralTemplate(): code[10]
    var
        DeferralTemplate: Record "Deferral Template";
    begin
        DeferralTemplate.Init();
        DeferralTemplate."Deferral Code" := LibraryUtility.GenerateRandomCode(DeferralTemplate.FieldNo("Deferral Code"), DATABASE::"Deferral Template");
        DeferralTemplate."Deferral Account" := LibraryERM.CreateGLAccountNo;
        DeferralTemplate."Calc. Method" := DeferralTemplate."Calc. Method"::"Straight-Line";
        DeferralTemplate."Start Date" := DeferralTemplate."Start Date"::"Posting Date";
        DeferralTemplate."No. of Periods" := 1;
        DeferralTemplate.Insert();

        exit(DeferralTemplate."Deferral Code");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopySalesDocReportHandlerOKWithEmptyDocumentNo(var CopySalesDocument: TestRequestPage "Copy Sales Document")
    begin
        CopySalesDocument.DocumentNo.Value := '';
        CopySalesDocument.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesListModalPageHandler(var SalesList: TestPage "Sales List")
    begin
        SalesList.OK.Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, 6620, 'OnBeforeInsertOldPurchDocNoLine', '', false, false)]
    local procedure OnBeforeInsertOldPurchDocNoLine(ToPurchHeader: Record "Purchase Header"; var ToPurchLine: Record "Purchase Line"; OldDocType: Option; OldDocNo: Code[20]; var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, 6620, 'OnBeforeInsertOldSalesDocNoLine', '', false, false)]
    local procedure OnBeforeInsertOldSalesDocNoLine(ToSalesHeader: Record "Sales Header"; var ToSalesLine: Record "Sales Line"; OldDocType: Option; OldDocNo: Code[20]; var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;

}

