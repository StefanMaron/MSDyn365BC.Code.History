codeunit 134398 "ERM Sales/Purch. Correct. Docs"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Corrective Documents]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        IsInitialized: Boolean;
        COGSAccountEmptyErr: Label 'COGS Account must have a value in General Posting Setup: Gen. Bus. Posting Group=%1, Gen. Prod. Posting Group=%2. It cannot be zero or empty.';
        CannotCancelSalesInvInventoryPeriodClosedErr: Label 'You cannot cancel this posted sales invoice because the posting inventory period is already closed.';
        CannotCancelPurchInvInventoryPeriodClosedErr: Label 'You cannot cancel this posted purchase invoice because the posting inventory period is already closed.';

    [Test]
    [Scope('OnPrem')]
    procedure CorrectSalesInvoiceWithLinePointingRoundingAccount()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice] [Credit Memo]
        // [SCENARIO 224605] Cassie can correct posted sales invoice with line pointing to customer's rounding G/L Account.
        Initialize();

        // [GIVEN] Invoice rounding is enabled in sales setup
        LibrarySales.SetInvoiceRounding(true);

        // [GIVEN] Posted invoice with line pointed to customer's rounding G/L Account.
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        CreateSalesLinesWithRoundingGLAcccount(SalesHeader, Customer);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesInvoiceHeader.Get(DocumentNo);

        // [WHEN] Correct posted invoice
        Clear(SalesHeader);
        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, false);
        CorrectPostedSalesInvoice.CancelPostedInvoiceStartNewInvoice(SalesInvoiceHeader, SalesHeader);

        // [THEN] System created new invoice with two lines copied from posted invoice
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        Assert.RecordCount(SalesLine, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectPurchaseInvoiceWithLinePointingRoundingAccount()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Invoice] [Credit Memo]
        // [SCENARIO 224605] Cassie can correct posted zero balanced purchase invoice
        Initialize();

        // [GIVEN] Cassie can correct posted purchase invoice with line pointing to customer's rounding G/L Account.
        LibraryPurchase.SetInvoiceRounding(true);

        // [GIVEN] Posted invoice with line pointed to vendor's rounding G/L Account.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        CreatePurchaseLinesWithRoundingGLAcccount(PurchaseHeader, Vendor);

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchInvHeader.Get(DocumentNo);

        // [WHEN] Correct posted invoice
        Clear(PurchaseHeader);
        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, false);
        CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeader);

        // [THEN] System created new invoice with two lines copied from posted invoice
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        Assert.RecordCount(PurchaseLine, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectSalesInvoiceWithoutDiscountPosting()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Invoice] [Credit Memo]
        // [SCENARIO 299514] Cassie can correct posted sales invoice when "Sales Line Disc. Account" is not set and "Discount Posting" = "No Discounts" in setup
        Initialize();

        LibrarySales.SetDiscountPosting(SalesReceivablesSetup."Discount Posting"::"No Discounts");

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo, LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(10));
        SalesLine.Modify(true);
        CleanSalesLineDiscAccountOnGenPostingSetup(SalesLine, GeneralPostingSetup);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesInvoiceHeader.Get(DocumentNo);

        Clear(SalesHeader);
        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, false);
        CorrectPostedSalesInvoice.CancelPostedInvoiceStartNewInvoice(SalesInvoiceHeader, SalesHeader);

        SalesHeader.TestField("Document Type", SalesHeader."Document Type"::Invoice);

        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectPurchaseInvoiceWithoutDiscountPosting()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Invoice] [Credit Memo]
        // [SCENARIO 299514] Cassie can correct posted purchase invoice when "Purch. Line Disc. Account" is not set and "Discount Posting" = "No Discounts" in setup
        Initialize();

        LibraryPurchase.SetDiscountPosting(PurchasesPayablesSetup."Discount Posting"::"No Discounts");

        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo, LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(10));
        PurchaseLine.Modify(true);
        CleanPurchLineDiscAccountOnGenPostingSetup(PurchaseLine, GeneralPostingSetup);

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchInvHeader.Get(DocumentNo);

        Clear(PurchaseHeader);
        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, false);
        CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeader);

        PurchaseHeader.TestField("Document Type", PurchaseHeader."Document Type"::Invoice);

        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanCancelSalesInvoiceWithServiceItemWhenCOGSAccountIsEmpty()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice] [UT]
        // [SCENARIO 322909] Cassie can cancel Posted Sales Invoice with Item of Type Service when COGS account is empty in General Posting Setup.
        Initialize();

        CreateSalesHeaderWithItemWithType(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, Item.Type::Service);
        CleanCOGSAccountOnGenPostingSetup(SalesLine, GeneralPostingSetup);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, true);

        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanCancelSalesInvoiceWithNonInventoryItemWhenCOGSAccountIsEmpty()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice] [UT]
        // [SCENARIO 322909] Cassie can cancel Posted Sales Invoice with Item of Type Non-Inventory when COGS account is empty in General Posting Setup.
        Initialize();

        CreateSalesHeaderWithItemWithType(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, Item.Type::"Non-Inventory");
        CleanCOGSAccountOnGenPostingSetup(SalesLine, GeneralPostingSetup);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, true);

        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CantCancelSalesInvoiceWithInventoryItemWhenCOGSAccountIsEmpty()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice] [UT]
        // [SCENARIO 322909] Cassie can't cancel Posted Sales Invoice with Item of Type Inventory when COGS account is empty in General Posting Setup.
        Initialize();

        CreateSalesHeaderWithItemWithType(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, Item.Type::Inventory);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        CleanCOGSAccountOnGenPostingSetup(SalesLine, GeneralPostingSetup);

        asserterror CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, true);
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(
          StrSubstNo(COGSAccountEmptyErr, GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group"));

        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectSalesInvoiceWithGLAccountWithoutSalesAccountInGenPostingSetup()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice] [UT]
        // [SCENARIO 337408] Cassie can cancel Posted Sales Invoice with G/L Account that does not have "Sales Account" in General Posting Setup.
        Initialize();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        CleanSalesAccountOnGenPostingSetup(SalesLine, GeneralPostingSetup);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, true);

        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectSalesInvoiceWithGLAccountWithoutSalesCreditMemoAccountInGenPostingSetup()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice] [UT]
        // [SCENARIO 337408] Cassie can cancel Posted Sales Invoice with G/L Account that does not have "Sales Credit Memo Account" in General Posting Setup.
        Initialize();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        CleanSalesCreditMemoAccountOnGenPostingSetup(SalesLine, GeneralPostingSetup);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, true);

        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectPurchaseInvoiceWithGLAccountWithoutSalesAccountInGenPostingSetup()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [FEATURE] [Purchase] [Invoice] [UT]
        // [SCENARIO 337408] Cassie can cancel Posted Purchase Invoice with G/L Account that does not have "Sales Account" in General Posting Setup.
        Initialize();

        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Modify(true);
        CleanPurchAccountOnGenPostingSetup(PurchaseLine, GeneralPostingSetup);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, true);

        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectPurchaseInvoiceWithGLAccountWithoutSalesCreditMemoAccountInGenPostingSetup()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [FEATURE] [Purchase] [Invoice] [UT]
        // [SCENARIO 337408] Cassie can cancel Posted Purchase Invoice with G/L Account that does not have "Sales Credit Memo Account" in General Posting Setup.
        Initialize();

        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Modify(true);
        CleanPurchCreditMemoAccountOnGenPostingSetup(PurchaseLine, GeneralPostingSetup);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, true);

        RestoreGenPostingSetup(GeneralPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceIsAllowed_Sales_GLAccount_InventoryPeriod_Closed()
    var
        InventoryPeriod: Record "Inventory Period";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice] [UT]
        // [SCENARIO 341572] COD1303.TestCorrectInvoiceIsAllowed does not throw error for posted invoice with G/L Account only when Inventory Period is closed
        Initialize();

        InventoryPeriod.DeleteAll();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        CreateInventoryPeriod(WorkDate + 1, true);

        Commit();

        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceIsAllowed_Sales_GLAccount_InventoryPeriod_Open()
    var
        InventoryPeriod: Record "Inventory Period";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice] [UT]
        // [SCENARIO 341572] COD1303.TestCorrectInvoiceIsAllowed does not throw error for posted invoice with G/L Account only when Inventory Period is open
        Initialize();

        InventoryPeriod.DeleteAll();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        CreateInventoryPeriod(WorkDate + 1, false);

        Commit();

        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceIsAllowed_Sales_Item_InventoryPeriod_Closed()
    var
        InventoryPeriod: Record "Inventory Period";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice] [UT]
        // [SCENARIO 341572] COD1303.TestCorrectInvoiceIsAllowed does not throw error for posted invoice having Item when Inventory Period is closed
        Initialize();

        InventoryPeriod.DeleteAll();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo, 1);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        CreateInventoryPeriod(WorkDate + 1, true);

        Commit();

        asserterror CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, true);

        Assert.ExpectedError(CannotCancelSalesInvInventoryPeriodClosedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceIsAllowed_Sales_Item_InventoryPeriod_Open()
    var
        InventoryPeriod: Record "Inventory Period";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice] [UT]
        // [SCENARIO 341572] COD1303.TestCorrectInvoiceIsAllowed does not throw error for posted invoice having Item only when Inventory Period is open
        Initialize();

        InventoryPeriod.DeleteAll();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo, 1);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        CreateInventoryPeriod(WorkDate + 1, false);

        Commit();

        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceIsAllowed_Sales_ItemCharge_InventoryPeriod_Closed()
    var
        InventoryPeriod: Record "Inventory Period";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice] [UT]
        // [SCENARIO 341572] COD1303.TestCorrectInvoiceIsAllowed does not throw error for posted invoice having Item Charge only when Inventory Period is closed
        Initialize();

        InventoryPeriod.DeleteAll();

        CreateSalesHeaderWithItemAndChargeItem(SalesHeader);

        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        CreateInventoryPeriod(WorkDate + 1, true);

        Commit();

        asserterror CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, true);

        Assert.ExpectedError(CannotCancelSalesInvInventoryPeriodClosedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceIsAllowed_Sales_ItemCharge_InventoryPeriod_Open()
    var
        InventoryPeriod: Record "Inventory Period";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [FEATURE] [Sales] [Invoice] [UT]
        // [SCENARIO 341572] COD1303.TestCorrectInvoiceIsAllowed does not throw error for posted invoice having Item Charge when Inventory Period is open
        Initialize();

        InventoryPeriod.DeleteAll();

        CreateSalesHeaderWithItemAndChargeItem(SalesHeader);

        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        CreateInventoryPeriod(WorkDate + 1, false);

        Commit();

        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceIsAllowed_Purchase_GLAccount_InventoryPeriod_Closed()
    var
        InventoryPeriod: Record "Inventory Period";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [FEATURE] [Purchase] [Invoice] [UT]
        // [SCENARIO 341572] COD1313.TestCorrectInvoiceIsAllowed does not throw error for posted invoice with G/L Account only when Inventory Period is closed
        Initialize();

        InventoryPeriod.DeleteAll();

        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Modify(true);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        CreateInventoryPeriod(WorkDate + 1, true);

        Commit();

        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceIsAllowed_Purchase_GLAccount_InventoryPeriod_Open()
    var
        InventoryPeriod: Record "Inventory Period";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [FEATURE] [Purchase] [Invoice] [UT]
        // [SCENARIO 341572] COD1313.TestCorrectInvoiceIsAllowed does not throw error for posted invoice with G/L Account only when Inventory Period is open
        Initialize();

        InventoryPeriod.DeleteAll();

        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Modify(true);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        CreateInventoryPeriod(WorkDate + 1, false);

        Commit();

        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceIsAllowed_Purchase_Item_InventoryPeriod_Closed()
    var
        InventoryPeriod: Record "Inventory Period";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [FEATURE] [Purchase] [Invoice] [UT]
        // [SCENARIO 341572] COD1313.TestCorrectInvoiceIsAllowed does not throw error for posted invoice having Item when Inventory Period is closed
        Initialize();

        InventoryPeriod.DeleteAll();

        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Modify(true);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        CreateInventoryPeriod(WorkDate + 1, true);

        Commit();

        asserterror CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, true);

        Assert.ExpectedError(CannotCancelPurchInvInventoryPeriodClosedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceIsAllowed_Purchase_Item_InventoryPeriod_Open()
    var
        InventoryPeriod: Record "Inventory Period";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [FEATURE] [Purchase] [Invoice] [UT]
        // [SCENARIO 341572] COD1313.TestCorrectInvoiceIsAllowed does not throw error for posted invoice having Item when Inventory Period is open
        Initialize();

        InventoryPeriod.DeleteAll();

        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Modify(true);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        CreateInventoryPeriod(WorkDate + 1, false);

        Commit();

        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceIsAllowed_Purchase_ItemCharge_InventoryPeriod_Closed()
    var
        InventoryPeriod: Record "Inventory Period";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [FEATURE] [Purchase] [Invoice] [UT]
        // [SCENARIO 341572] COD1313.TestCorrectInvoiceIsAllowed does not throw error for posted invoice having Item Charge when Inventory Period is closed
        Initialize();
        InitializeSetupData();

        InventoryPeriod.DeleteAll();

        CreatePurchaseHeaderWithItemAndChargeItem(PurchaseHeader);

        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        UpdateGLAccountsInGeneralPostingSetupFromPurchaseInvoiceLine(PurchInvHeader);

        CreateInventoryPeriod(WorkDate + 1, true);

        Commit();

        asserterror CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, true);

        Assert.ExpectedError(CannotCancelPurchInvInventoryPeriodClosedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceIsAllowed_Purchase_ItemCharge_InventoryPeriod_Open()
    var
        InventoryPeriod: Record "Inventory Period";
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [FEATURE] [Purchase] [Invoice] [UT]
        // [SCENARIO 341572] COD1313.TestCorrectInvoiceIsAllowed does not throw error for posted invoice having Item Charge when Inventory Period is open
        Initialize();

        InventoryPeriod.DeleteAll();

        CreatePurchaseHeaderWithItemAndChargeItem(PurchaseHeader);

        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        UpdateGLAccountsInGeneralPostingSetupFromPurchaseInvoiceLine(PurchInvHeader);

        CreateInventoryPeriod(WorkDate + 1, false);

        Commit();

        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, true);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Sales/Purch. Correct. Docs");
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Sales/Purch. Correct. Docs");

        InitializeSetupData();

        LibrarySetupStorage.SaveSalesSetup();
        LibrarySetupStorage.SavePurchasesSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Sales/Purch. Correct. Docs");
    end;

    local procedure InitializeSetupData()
    begin
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
    end;

    local procedure UpdateGLAccountsInGeneralPostingSetupFromPurchaseInvoiceLine(PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchInvLine: Record "Purch. Inv. Line";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.FindSet();
        repeat
            GeneralPostingSetup.Get(PurchInvLine."Gen. Bus. Posting Group", PurchInvLine."Gen. Prod. Posting Group");
            GeneralPostingSetup."Sales Credit Memo Account" := LibraryERM.CreateGLAccountNo();
            GeneralPostingSetup."Purch. Credit Memo Account" := LibraryERM.CreateGLAccountNo();
            GeneralPostingSetup.Modify();
        until PurchInvLine.Next() = 0;
    end;

    local procedure CreateSalesHeaderWithItemWithType(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Option; ItemType: Option)
    var
        Item: Record Item;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, LibrarySales.CreateCustomerNo);
        LibraryInventory.CreateItem(Item);
        Item.Validate(Type, ItemType);
        Item.Validate("Unit Price", LibraryRandom.RandInt(10));
        Item.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
    end;

    local procedure CreateSalesLinesWithRoundingGLAcccount(SalesHeader: Record "Sales Header"; Customer: Record Customer)
    var
        SalesLine: Record "Sales Line";
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        with SalesLine do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup, 1);
            Validate("Unit Price", LibraryRandom.RandIntInRange(20, 40));
            Modify(true);

            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup, 1);
            Validate("Unit Price", -LibraryRandom.RandIntInRange(5, 10));
            Modify(true);
        end;

        with CustomerPostingGroup do begin
            Get(Customer."Customer Posting Group");
            Validate("Invoice Rounding Account", SalesLine."No.");
            Modify(true);
        end;
    end;

    local procedure CreatePurchaseLinesWithRoundingGLAcccount(PurchaseHeader: Record "Purchase Header"; Vendor: Record Vendor)
    var
        PurchaseLine: Record "Purchase Line";
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        with PurchaseLine do begin
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup, 1);
            Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(20, 40));
            Modify(true);

            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup, 1);
            Validate("Direct Unit Cost", -LibraryRandom.RandIntInRange(5, 10));
            Modify(true);
        end;

        with VendorPostingGroup do begin
            Get(Vendor."Vendor Posting Group");
            Validate("Invoice Rounding Account", PurchaseLine."No.");
            Modify(true);
        end;
    end;

    local procedure CleanSalesLineDiscAccountOnGenPostingSetup(SalesLine: Record "Sales Line"; var OldGeneralPostingSetup: Record "General Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        OldGeneralPostingSetup.Copy(GeneralPostingSetup);
        GeneralPostingSetup.Validate("Sales Line Disc. Account", '');
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CleanPurchLineDiscAccountOnGenPostingSetup(PurchaseLine: Record "Purchase Line"; var OldGeneralPostingSetup: Record "General Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        OldGeneralPostingSetup.Copy(GeneralPostingSetup);
        GeneralPostingSetup.Validate("Purch. Line Disc. Account", '');
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CleanCOGSAccountOnGenPostingSetup(SalesLine: Record "Sales Line"; var OldGeneralPostingSetup: Record "General Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        OldGeneralPostingSetup.Copy(GeneralPostingSetup);
        GeneralPostingSetup.Validate("COGS Account", '');
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CleanSalesAccountOnGenPostingSetup(SalesLine: Record "Sales Line"; var OldGeneralPostingSetup: Record "General Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        OldGeneralPostingSetup.Copy(GeneralPostingSetup);
        GeneralPostingSetup.Validate("Sales Account", '');
        GeneralPostingSetup.Validate("Sales Credit Memo Account", LibraryERM.CreateGLAccountWithSalesSetup());
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CleanSalesCreditMemoAccountOnGenPostingSetup(SalesLine: Record "Sales Line"; var OldGeneralPostingSetup: Record "General Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        OldGeneralPostingSetup.Copy(GeneralPostingSetup);
        GeneralPostingSetup.Validate("Sales Account", LibraryERM.CreateGLAccountWithSalesSetup());
        GeneralPostingSetup.Validate("Sales Credit Memo Account", '');
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CleanPurchAccountOnGenPostingSetup(PurchaseLine: Record "Purchase Line"; var OldGeneralPostingSetup: Record "General Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        OldGeneralPostingSetup.Copy(GeneralPostingSetup);
        GeneralPostingSetup.Validate("Purch. Account", '');
        GeneralPostingSetup.Validate("Purch. Credit Memo Account", LibraryERM.CreateGLAccountWithPurchSetup());
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CleanPurchCreditMemoAccountOnGenPostingSetup(PurchaseLine: Record "Purchase Line"; var OldGeneralPostingSetup: Record "General Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        OldGeneralPostingSetup.Copy(GeneralPostingSetup);
        GeneralPostingSetup.Validate("Purch. Account", LibraryERM.CreateGLAccountWithPurchSetup());
        GeneralPostingSetup.Validate("Purch. Credit Memo Account", '');
        GeneralPostingSetup.Modify(true);
    end;

    local procedure RestoreGenPostingSetup(OldGeneralPostingSetup: Record "General Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(OldGeneralPostingSetup."Gen. Bus. Posting Group", OldGeneralPostingSetup."Gen. Prod. Posting Group");
        GeneralPostingSetup."Sales Line Disc. Account" := OldGeneralPostingSetup."Sales Inv. Disc. Account";
        GeneralPostingSetup."Purch. Line Disc. Account" := OldGeneralPostingSetup."Purch. Line Disc. Account";
        GeneralPostingSetup."COGS Account" := OldGeneralPostingSetup."COGS Account";
        GeneralPostingSetup."Sales Credit Memo Account" := OldGeneralPostingSetup."Sales Credit Memo Account";
        GeneralPostingSetup."Sales Account" := OldGeneralPostingSetup."Sales Account";
        GeneralPostingSetup.Modify();
    end;

    local procedure CreateSalesHeaderWithItemAndChargeItem(var SalesHeader: Record "Sales Header")
    var
        SalesLineItem: Record "Sales Line";
        SalesLineChargeItem: Record "Sales Line";
        ItemCharge: Record "Item Charge";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        LibrarySales.CreateSalesHeader(
            SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());

        LibrarySales.CreateSalesLine(
            SalesLineItem, SalesHeader, SalesLineItem.Type::Item, LibraryInventory.CreateItemNo(), 1);
        SalesLineItem.Validate("Unit Price", LibraryRandom.RandIntInRange(10, 20));
        SalesLineItem.Modify(true);

        LibrarySales.CreateSalesLine(
            SalesLineChargeItem, SalesHeader, SalesLineChargeItem.Type::"Charge (Item)",
            LibraryInventory.CreateItemChargeNo(), 1);
        SalesLineChargeItem.Validate("Unit Price", LibraryRandom.RandIntInRange(10, 20));
        SalesLineChargeItem.Modify(true);

        ItemCharge.Get(SalesLineChargeItem."No.");
        LibrarySales.CreateItemChargeAssignment(
            ItemChargeAssignmentSales, SalesLineChargeItem, ItemCharge,
            SalesLineItem."Document Type"::Invoice, SalesLineItem."Document No.", SalesLineItem."Line No.",
            SalesLineItem."No.", SalesLineChargeItem.Quantity, LibraryRandom.RandIntInRange(10, 20));
        ItemChargeAssignmentSales.Insert(true);
    end;

    local procedure CreatePurchaseHeaderWithItemAndChargeItem(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLineItem: Record "Purchase Line";
        PurchaseLineChargeItem: Record "Purchase Line";
        ItemCharge: Record "Item Charge";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());

        LibraryPurchase.CreatePurchaseLine(
            PurchaseLineItem, PurchaseHeader, PurchaseLineItem.Type::Item, LibraryInventory.CreateItemNo(), 1);
        PurchaseLineItem.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(10, 20));
        PurchaseLineItem.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
            PurchaseLineChargeItem, PurchaseHeader, PurchaseLineChargeItem.Type::"Charge (Item)",
            LibraryInventory.CreateItemChargeNo(), 1);
        PurchaseLineChargeItem.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(10, 20));
        PurchaseLineChargeItem.Modify(true);

        ItemCharge.Get(PurchaseLineChargeItem."No.");
        LibraryPurchase.CreateItemChargeAssignment(
            ItemChargeAssignmentPurch, PurchaseLineChargeItem, ItemCharge,
            PurchaseLineItem."Document Type"::Invoice, PurchaseLineItem."Document No.", PurchaseLineItem."Line No.",
            PurchaseLineItem."No.", PurchaseLineChargeItem.Quantity, LibraryRandom.RandIntInRange(10, 20));
        ItemChargeAssignmentPurch.Insert(true);
    end;

    local procedure CreateInventoryPeriod(EndingDate: Date; IsClosed: Boolean)
    var
        InventoryPeriod: Record "Inventory Period";
    begin
        InventoryPeriod.Init();
        InventoryPeriod."Ending Date" := EndingDate;
        InventoryPeriod.Closed := IsClosed;
        InventoryPeriod.Insert(true);
    end;
}

