#if not CLEAN25
codeunit 140611 "ERM - Purchase Document"
{
    Subtype = Test;
    TestPermissions = Disabled;
    ObsoleteReason = 'Moved to IRS Forms App.';
    ObsoleteState = Pending;
    ObsoleteTag = '25.0';

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [IRS 1099 Liable]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure CheckIRS1099LiableOnPurchaseLine()
    var
        Vendor: Record Vendor;
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemVendor: Record "Item Vendor";
        RequisitionLine: Record "Requisition Line";
    begin
        // Create Vendor and Create Customer and Create Item-Vendor Catalog and Create Sales Order with Release Status and Create Purchase Order through Requisition Worksheet and Verify IRS 1099 Liable True.

        // Setup: Create Item Vendor and Create Sales Order.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("IRS 1099 Code", FindIrs1099Code());
        Vendor.Modify(true);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVendor(ItemVendor, Vendor."No.", Item."No.");
        CreateReleaseSalesDocument(SalesLine, Item."No.");

        // Exercise: Run Get Sales Order on Planning WorkSheet.
        RunGetSalesOrders(RequisitionLine, SalesLine);
        CarryOutActionMessage(RequisitionLine, Item."No.", Vendor."No.");

        // Verify: Verify IRS 1099 Liable True.
        VerifyIRS1099Liable(Vendor."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IRS1099AmountInSecondVendLedgEntryAfterPartialPostingOfPurchOrderTwice()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        // [SCENARIO 434149] "IRS 1099 Amount" is correct in the second Vendor Ledger Entriy after posting purchase partially twice

        Initialize();
        // [GIVEN] Purchase order with "IRS 1099 Code" = "MISC-01"
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchHeader.Validate("IRS 1099 Code", FindIrs1099Code());
        PurchHeader.Modify(true);
        // [GIVEN] Purchase line has Quantity = 20, "Unit Cost" = 100
        LibraryPurchase.CreatePurchaseLineWithUnitCost(
            PurchLine, PurchHeader, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(100, 2), LibraryRandom.RandIntInRange(20, 30));
        // [GIVEN] "Qty. To Receive" in purchase line is set to 10
        PurchLine.Validate("Qty. to Receive", Round(PurchLine.Quantity / 3, 1));
        PurchLine.Modify(true);
        // [GIVEN] Purchase order is posted partially
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        PurchHeader.Find();
        PurchHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchLine.Find();
        // [GIVEN] "Qty. To Receive" in purchase line is set to 10
        PurchLine.Validate("Qty. to Receive", Round(PurchLine.Quantity / 3, 1));
        PurchLine.Modify(true);
        // [WHEN] Post purchase order partially again
        LibraryERM.FindVendorLedgerEntry(VendLedgEntry, VendLedgEntry."Document Type"::Invoice, LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
        // [THEN] Vendor Ledger Entry has "IRS 1099 Amount" = 1000
        VendLedgEntry.CalcFields(Amount);
        VendLedgEntry.TestField("IRS 1099 Amount", VendLedgEntry.Amount);
    end;

    [Test]
    procedure CheckCopyPurchaseDocumentNotCopyIRS1099AmountInPurchaseDocument()
    var
        FromPurchHeader, ToPurchHeader : Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        //[SCENARIO 573639] Verify Copy Purchase Document should not copy the IRS 1099 amount in the Purchase Document.
        Initialize();

        // [GIVEN] Create Purchase order with IRS 1099 Code.
        LibraryPurchase.CreatePurchHeader(FromPurchHeader, FromPurchHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        FromPurchHeader.Validate("IRS 1099 Code", FindIrs1099Code());
        FromPurchHeader.Modify(true);

        // [GIVEN] Create Purchase Line.
        LibraryPurchase.CreatePurchaseLineWithUnitCost(
            PurchLine, FromPurchHeader, LibraryInventory.CreateItemNo(),
            LibraryRandom.RandDec(100, 2), LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Set the 'Qty. to Receive' and 'Qty. to Invoice' fields to partial quantities on the purchase line.
        PurchLine.Validate("Qty. to Receive", LibraryRandom.RandIntInRange(30, 40));
        PurchLine.Validate("Qty. to Invoice", LibraryRandom.RandIntInRange(20, 25));
        PurchLine.Modify(true);

        // [GIVEN] Partially Post a Purchase Order.
        LibraryPurchase.PostPurchaseDocument(FromPurchHeader, true, true);
        Commit();

        // [GIVEN] Create second purchase order.
        LibraryPurchase.CreatePurchHeader(
            ToPurchHeader, ToPurchHeader."Document Type"::Order, FromPurchHeader."Buy-from Vendor No.");

        // [WHEN] Use the 'Copy Document' function to copy from the first purchase order, setting 'Include Header' to true.
        PurchaseCopyDocument(ToPurchHeader, FromPurchHeader."No.", "Purchase Document Type From"::Order);
        ToPurchHeader.Get(ToPurchHeader."Document Type", ToPurchHeader."No.");

        // [THEN] Verify Copy Purchase Document should not copy the IRS 1099 amount in the Purchase Document.
        Assert.Equal(ToPurchHeader."IRS 1099 Code", FromPurchHeader."IRS 1099 Code");
        Assert.Equal(ToPurchHeader."IRS 1099 Amount", 0);
    end;

    local procedure Initialize()
    begin
        if isInitialized then
            exit;
        LibraryERMCountryData.CreateVATData();
        isInitialized := true;
        Commit();
    end;

    local procedure CarryOutActionMessage(RequisitionLine: Record "Requisition Line"; ItemNo: Code[20]; VendorNo: Code[20])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.FindFirst();
        RequisitionLine.Validate("Vendor No.", VendorNo);
        RequisitionLine.Modify(true);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure CreateReleaseSalesDocument(var SalesLine: Record "Sales Line"; ItemNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Purchasing Code", FindPurchasingCode());
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure FindIrs1099Code(): Code[10]
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
    begin
        IRS1099FormBox.Next(LibraryRandom.RandInt(IRS1099FormBox.Count));
        exit(IRS1099FormBox.Code);
    end;

    local procedure FindPurchasingCode(): Code[10]
    var
        Purchasing: Record Purchasing;
    begin
        Purchasing.SetRange("Special Order", true);
        Purchasing.FindFirst();
        exit(Purchasing.Code);
    end;

    local procedure RunGetSalesOrders(var RequisitionLine: Record "Requisition Line"; SalesLine: Record "Sales Line")
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        GetSalesOrders: Report "Get Sales Orders";
    begin
        RequisitionWkshName.SetRange("Template Type", RequisitionWkshName."Template Type"::"Req.");
        RequisitionWkshName.FindFirst();
        RequisitionLine.Validate("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.Validate("Journal Batch Name", RequisitionWkshName.Name);

        SalesLine.SetRange("Document Type", SalesLine."Document Type");
        SalesLine.SetRange("Document No.", SalesLine."Document No.");
        Clear(GetSalesOrders);
        GetSalesOrders.SetReqWkshLine(RequisitionLine, 1);
        GetSalesOrders.UseRequestPage(false);
        GetSalesOrders.RunModal();
    end;

    local procedure VerifyIRS1099Liable(VendorNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("Buy-from Vendor No.", VendorNo);
        PurchaseLine.FindFirst();
        PurchaseLine.TestField("IRS 1099 Liable", true);
    end;

    local procedure PurchaseCopyDocument(PurchaseHeader: Record "Purchase Header"; No: Code[20]; DocumentType: Enum "Purchase Document Type From")
    var
        CopyPurchaseDocument: Report "Copy Purchase Document";
    begin
        Clear(CopyPurchaseDocument);
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader);
        CopyPurchaseDocument.SetParameters(DocumentType, No, true, false);
        CopyPurchaseDocument.UseRequestPage(false);
        CopyPurchaseDocument.Run();
        Commit();
    end;
}
#endif
