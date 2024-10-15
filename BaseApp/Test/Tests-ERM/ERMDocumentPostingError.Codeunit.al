codeunit 134384 "ERM Document Posting Error"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Order] [Status]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        IsInitialized: Boolean;
        SalesOrderPostingErr: Label 'The total amount for the invoice must be 0 or greater.';
        PurchaseInvoicePostingErr: Label 'Amount must be negative in Gen. Journal Line Journal Template Name=''%1'',Journal Batch Name='''',Line No.=''0''.', Comment = '.';
        StatusErr: Label 'Status must be equal to ''Open''  in %1: Document Type=%2, No.=%3. Current value is ''Released''.', Comment = '.';

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithNegativeValue()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Test Sales Order Posting Error for Negative value and Status field.

        // Setup: Create Sales Order with Negative value.
        Initialize;
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);

        // Exercise: Post Sales Order.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Posting Error and Status field.
        Assert.ExpectedError(SalesOrderPostingErr);
        SalesHeader.TestField(Status, SalesHeader.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithNegativeValue()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Test Purchase Invoice Posting Error for Negative value and Status field.

        // Setup: Create Purchase Invoice with Negative value.
        Initialize;
        CreatePurchDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        // Exercise: Post Purchase Invoice.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Posting Error and Status field.
        Assert.ExpectedError(GetPurchInvPostingErr(PurchaseHeader));
        PurchaseHeader.TestField(Status, PurchaseHeader.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeSellToCustomerOnOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Test Release Sales Order not allow changing Sell-to Customer No. field.

        // Setup: Create Sales Order and use Release function.
        Initialize;
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);

        // Exercise: Validate Sell to Customer No.
        asserterror SalesHeader.Validate("Sell-to Customer No.");

        // Verify: Verify Release Sales Order not allow changing field Sell-to Customer No.
        VerifyReleaseSalesDocument(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeBillToCustomerOnInvoice()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Test Release Sales Invoice not allow changing Bill-to Customer No. field.

        // Setup: Create Sales Invoice and use Release function.
        Initialize;
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);

        // Exercise: Validate Bill-to Customer No.
        asserterror SalesHeader.Validate("Bill-to Customer No.");

        // Verify: Verify Release Sales Invoice not allow changing field Bill-to Customer No.
        VerifyReleaseSalesDocument(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangePriceIncludingVATOnOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Test Release Sales Order not allow changing Prices Including VAT field.

        // Setup: Create Sales Order and use Release function.
        Initialize;
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);

        // Exercise: Change Prices Including VAT.
        asserterror SalesHeader.Validate("Prices Including VAT", true);

        // Verify: Verify Release Sales Order not allow changing Prices Including VAT.
        VerifyReleaseSalesDocument(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure ChangePayToVendorOnOrder()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        OldBillToSellToVATCalc: Option;
        VATBusPostingGroup: Code[20];
    begin
        // Test VAT Business Posting Group not changing on Purchase Order while Change Pay to Vendor field.

        // Setup: Create Purchase Invoice with Negative value.
        Initialize;
        UpdateGenenralLedgerSetup(OldBillToSellToVATCalc, GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.");
        CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        VATBusPostingGroup := PurchaseHeader."VAT Bus. Posting Group";

        // Exercise: Change Pay to Vendor No. on Purchase Header.
        PurchaseHeader.Validate("Pay-to Vendor No.", LibraryPurchase.CreateVendorNo);
        PurchaseHeader.Modify(true);

        // Verify: Verify VAT Bus.Posting Group.
        Assert.AreEqual(VATBusPostingGroup, PurchaseHeader."VAT Bus. Posting Group", 'Posting Group must match');

        // Tear Down: Roll back General Ledger Setup.
        UpdateGenenralLedgerSetup(OldBillToSellToVATCalc, OldBillToSellToVATCalc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeCurrencyOnSalesCrMemo()
    var
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
    begin
        // Test Release Sales Credit Memo not allow changing Currency Code field.

        // Setup: Create Sales Credit Memo and use Release function.
        Initialize;
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        LibraryERM.FindCurrency(Currency);

        // Exercise: Validate Currency Code
        asserterror SalesHeader.Validate("Currency Code", Currency.Code);

        // Verify: Verify Release Sales Credit Memo not allow changing Currency Code field.
        VerifyReleaseSalesDocument(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeBuyFromVendorOnCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Test Release Purchase Credit Memo not allow changing Buy-from Vendor No. field.

        // Setup: Create Purchase Credit Memo and use Release function.
        Initialize;
        CreateAndReleasePurchDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");

        // Exercise: Validate Buy-from Vendor No. on Release Purchase Header.
        asserterror PurchaseHeader.Validate("Buy-from Vendor No.");

        // Verify: Verify Release Purchase Credit Memo not allow changing "Buy-from Vendor No.".
        VerifyReleasePurchDocument(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangePayToVendorOnReleaseDoc()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Test Release Purchase Order not allow changing Pay-to Vendor No. field.

        // Setup: Create Purchase Order and use Release function.
        Initialize;
        CreateAndReleasePurchDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order);

        // Exercise: Validate Pay to Vendor No. on Purchase Header.
        asserterror PurchaseHeader.Validate("Pay-to Vendor No.");

        // Verify: Verify Release Purchase Order not allow changing "Pay-to Vendor No.".
        VerifyReleasePurchDocument(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PriceIncludingVATOnPurchOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Test Release Purchase Order not allow changing Prices Including VAT field.

        // Setup: Create Purchase Order and use Release function.
        Initialize;
        CreateAndReleasePurchDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order);

        // Exercise: Validate Prices Including VAT on Purchase Header.
        asserterror PurchaseHeader.Validate("Prices Including VAT", true);

        // Verify: Verify Release Purchase Order not allow changing Prices Including VAT.
        VerifyReleasePurchDocument(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeCurrencyOnPurchInvoice()
    var
        Currency: Record Currency;
        PurchaseHeader: Record "Purchase Header";
    begin
        // Test Release Purchase Invoice not allow changing Currency Code field.

        // Setup: Create Purchase Invoice and use Release function.
        Initialize;
        CreateAndReleasePurchDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        LibraryERM.FindCurrency(Currency);

        // Exercise: Validate Currency on Purchase Header.
        asserterror PurchaseHeader.Validate("Currency Code", Currency.Code);

        // Verify: Verify Release Purchase Invoice not allow changing Currency Code field.
        VerifyReleasePurchDocument(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteSalesLineWithNonZeroQty()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify not possible to delete Released Sales Item Line.

        // Setup: Create and Release Sale Order.
        Initialize;
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);
        FindSalesLine(SalesLine, SalesHeader."No.", SalesLine.Type::Item);

        // Exercise: Delete Released Sales Line.
        asserterror SalesLine.Delete(true);

        // Verify: Status Error Message.
        VerifyReleaseSalesDocument(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteSalesLineWithZeroQty()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        // Verify not possible to delete Released Sales Item Line with zero Quantity.

        // Setup: Create Sale Order with multiple Lines and Release Sales Order.
        Initialize;
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo, 0);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        FindSalesLine(SalesLine, SalesHeader."No.", SalesLine.Type::Item);

        // Exercise: Delete Zero Quantity Sales Line.
        SalesLine2.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        asserterror SalesLine2.Delete(true);

        // Verify: Verify not possible to Delete Released Sales Line.
        VerifyReleaseSalesDocument(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLineGLAccWithNonZeroQty()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify possible to delete Released Sales G/L Account Line.

        // Setup: Create Sale Order for Type G/L Account and Release Sales Order.
        Initialize;
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup, LibraryRandom.RandInt(10));
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");

        // Exercise: Delete Released Sales Line.
        SalesLine.Delete(true);

        // Verify: Verify Sales Line Deleted.
        Assert.IsFalse(
          SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No."), 'Sales Line must not Exist.')
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddNewSalesLineInReleaseOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify not possible to add new Item Line in Released Sales Order with Quantity value zero.

        // Setup: Create and Release Sales Order for Item.
        Initialize;
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);

        // Exercise: Add New Item Line in Released Sales Line with Quantity zero.
        asserterror LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo, 0);

        // Verify: Verify Error message for not possible to add New Item Line in Released Order.
        VerifyReleaseSalesDocument(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddChargeItemInReleaseSalesDoc()
    var
        ItemCharge: Record "Item Charge";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify possible to add new Charge Item Line in Released Sales Order.

        // Setup: Create and Release Sales Order.
        Initialize;
        LibraryInventory.CreateItemCharge(ItemCharge);
        CreateAndReleaseSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // Exercise: Add New Charge Item Line in Sales Line with Random Quantity.
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", ItemCharge."No.", LibraryRandom.RandInt(10));

        // Verify: Verify New Charge Item Line added in Order.
        FindSalesLine(SalesLine, SalesHeader."No.", SalesLine.Type::"Charge (Item)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePurchLineWithNonZeroQty()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify not possible to delete Released Purchase Line.

        // Setup: Create and Release Purchase Order.
        Initialize;
        CreateAndReleasePurchDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.", PurchaseLine.Type::Item);

        // Exercise: Delete Released Sales Line.
        asserterror PurchaseLine.Delete(true);

        // Verify: Verify Error message for not possible to Delete Released Purchase Line.
        VerifyReleasePurchDocument(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePurchLineWithZeroQty()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
    begin
        // Verify not possible to delete Released Purchase Line.

        // Setup: Create Purchase Order for multiple lines and  Release Purchase Order.
        Initialize;
        CreatePurchDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo, 0);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        FindPurchaseLine(PurchaseLine2, PurchaseHeader."No.", PurchaseLine.Type::Item);

        // Exercise: Delete Released Purchase Line for zero Quantity.
        asserterror PurchaseLine2.Delete(true);

        // Verify: Verify Error message for not possible to Delete Released Purchase Line for zero Quantity.
        VerifyReleasePurchDocument(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchLineGLAccWithNonZeroQty()
    var
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
    begin
        // Verify possible to delete Released Purchase Order for Line Type G/L Account.

        // Setup: Create Purchase Order for G/L Account lines. Using Random value for Quantity and Release Purchase Order.
        Initialize;
        LibraryERM.FindGLAccount(GLAccount);
        CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandInt(10));
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseLine2.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        // Exercise: Delete Purchase Line.
        PurchaseLine2.Delete(true);

        // Verify: Verify Purchase Line Deleted.
        Assert.IsFalse(
          PurchaseLine2.Get(
            PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No."), 'Purchase Line must not Exist.')
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddNewPurchLineInReleaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify not possible to add new Item Line in Released Purchase Order.

        // Setup: Create and Release Purchase Order.
        Initialize;
        CreateAndReleasePurchDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order);

        // Exercise: Add new Item Line with Random Quantity in Released Purchase Line.
        asserterror LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo, LibraryRandom.RandInt(10));

        // Verify: Verify not possible to add new Item Purchase Line in Released Order.
        VerifyReleasePurchDocument(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddGLAccLineInReleasePurchDoc()
    var
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify possible to add new G/L Account Line in Released Purchase Order.
        // Setup: Create and Release Purchase Order.
        Initialize;
        LibraryERM.FindGLAccount(GLAccount);
        CreateAndReleasePurchDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        // Exercise: Add new Line Type G/L Account with Random Quantity in Released Purchase Line.
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandInt(10));

        // Verify: Verify G/L Account Type Line added in Released Order.
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.", PurchaseLine.Type::"G/L Account");
    end;

    [Normal]
    local procedure Initialize()
    var
        PurchaseHeader: Record "Purchase Header";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Document Posting Error");
        // Lazy Setup.
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyVendorAddressNotificationId);
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyPayToVendorAddressNotificationId);
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Document Posting Error");
        LibraryERMCountryData.CreateVATData;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibraryERMCountryData.UpdatePurchasesPayablesSetup;
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Document Posting Error");
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
    begin
        // Unit Price updating with Negative Random value and Quantity with Random Value.
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", -LibraryRandom.RandDec(50, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateAndReleaseSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    begin
        CreateSalesDocument(SalesHeader, DocumentType);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreatePurchDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Direct Unit Cost updating with Negative Random value and Quantity with Random Value.
        CreatePurchHeader(PurchaseHeader, DocumentType);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo, LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", -LibraryRandom.RandDec(50, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, Vendor."No.");
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateAndReleasePurchDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    begin
        CreatePurchDocument(PurchaseHeader, DocumentType);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20]; Type: Enum "Purchase Document Type")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange(Type, Type);
        PurchaseLine.FindLast;
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentNo: Code[20]; Type: Enum "Sales Document Type")
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange(Type, Type);
        SalesLine.FindLast;
    end;

    local procedure UpdateGenenralLedgerSetup(var OldBillToSellToVATCalc: Option; BillToSellToVATCalc: Option)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldBillToSellToVATCalc := GeneralLedgerSetup."Bill-to/Sell-to VAT Calc.";
        GeneralLedgerSetup.Validate("Bill-to/Sell-to VAT Calc.", BillToSellToVATCalc);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure GetPurchInvPostingErr(PurchHeader: Record "Purchase Header"): Text[250]
    begin
        exit(StrSubstNo(PurchaseInvoicePostingErr, PurchHeader."Journal Template Name"));
    end;

    local procedure VerifyReleaseSalesDocument(SalesHeader: Record "Sales Header")
    begin
        Assert.ExpectedError(
          StrSubstNo(StatusErr, SalesHeader.TableCaption, SalesHeader."Document Type", SalesHeader."No."));
    end;

    local procedure VerifyReleasePurchDocument(PurchaseHeader: Record "Purchase Header")
    begin
        Assert.ExpectedError(
          StrSubstNo(StatusErr, PurchaseHeader.TableCaption, PurchaseHeader."Document Type", PurchaseHeader."No."));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

