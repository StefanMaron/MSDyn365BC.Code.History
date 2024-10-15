codeunit 147104 "SCM CD Fixed Assets"
{
    // Fixed Assets PO - Full Cycle
    // 1. Test case to check CD mixed PO (FA + Item)
    //   a. Create a new foreign vendor
    //   b. Create a new FA
    //   c. Create a new item
    //   d. Create a new CD
    //   e. Purchase new item and FA
    //   f. Check Item Ledger Entry
    //   g. Release FA
    //   h. Create a new VAT Purchase Ledger
    //   i. Check VAT Purchase Ledger Lines
    // 2. Test case to check CD for Sale and Return FA
    //   a. Create a new foreign vendor
    //   b. Create a new customer
    //   c. Create a new FA
    //   d. Create a new CD
    //   e. Purchase the FA
    //   f. Release FA
    //   h. Create a new VAT Purchase Ledger
    //   i. Writeoff FA
    //   j. Create a new sale order for FA
    //   k. Create sales return order
    //   l. Check VAT Purchase Ledger Lines

    Subtype = Test;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryCDTracking: Codeunit "Library - CD Tracking";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        Assert: Codeunit Assert;
        VATLedgerErr: Label 'Couldn''t find Purchase VAT Ledger Line with CDNo';
        isInitialized: Boolean;

    [Normal]
    local procedure Initialize()
    begin
        if isInitialized then
            exit;

        LibraryCDTracking.UpdateERMCountryData;

        isInitialized := true;
        Commit;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderWithFAAndItem()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        Location: Record Location;
        Customer: Record Customer;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        PurchaseHeader: Record "Purchase Header";
        FA: Record "Fixed Asset";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        FADocHeader: Record "FA Document Header";
        VATLedgerCode: Code[20];
        CDNo: array[2] of Code[30];
        ReleaseDate: Date;
        StartDate: Date;
        EndDate: Date;
        Qty: Integer;
        i: Integer;
    begin
        Initialize;
        StartDate := WorkDate;
        EndDate := CalcDate('<CM>', StartDate);

        LibraryCDTracking.CreateForeignVendor(Vendor);
        LibrarySales.CreateCustomer(Customer);
        LibraryCDTracking.CreateFixedAsset(FA);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, Location.Code);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        for i := 1 to ArrayLen(CDNo) do
            CDNo[i] := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateFACDInfo(CDHeader, CDLine, FA."No.", CDNo[1]);
        FA.Validate("CD No.", CDNo[1]);
        FA.Modify;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", CDNo[2]);

        LibraryCDTracking.CreatePurchOrder(PurchaseHeader, Vendor."No.", Location.Code);
        Qty := 5;
        LibraryCDTracking.CreatePurchLineFA(PurchaseLine, PurchaseHeader, FA."No.", 10000, Qty);
        LibraryCDTracking.CreatePurchLineItem(PurchaseLine, PurchaseHeader, Item."No.", 100, Qty);
        DisableUnrealizedVATPostingSetup(PurchaseLine);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo[2], Qty);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', CDNo[2], 5);

        ReleaseDate := CalcDate('<+1D>', WorkDate);
        LibraryCDTracking.CreateFAReleaseAct(FADocHeader, FA."No.", ReleaseDate);
        LibraryCDTracking.PostFAReleaseAct(FADocHeader);

        VATLedgerCode := LibraryCDTracking.CreateVATPurchaseLedger(StartDate, EndDate, '');
        CheckPurchaseLedger(VATLedgerCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithFA()
    var
        Vendor: Record Vendor;
        Location: Record Location;
        Customer: Record Customer;
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        PurchaseHeader: Record "Purchase Header";
        FA: Record "Fixed Asset";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FADocHeader: Record "FA Document Header";
        CopySalesDocument: Report "Copy Sales Document";
        LibrarySales: Codeunit "Library - Sales";
        VATLedgerCode: Code[20];
        CDNo: Code[30];
        SaleDocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Shipment","Posted Invoice","Posted Return Receipt","Posted Credit Memo";
        WriteoffDate: Date;
        ReleaseDate: Date;
        Qty: Integer;
        StartDate: Date;
        EndDate: Date;
    begin
        Initialize;
        StartDate := WorkDate;
        EndDate := CalcDate('<CM>', StartDate);

        LibraryCDTracking.CreateForeignVendor(Vendor);
        LibrarySales.CreateCustomer(Customer);
        LibraryCDTracking.CreateFixedAsset(FA);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        CDNo := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateFACDInfo(CDHeader, CDLine, FA."No.", CDNo);
        FA.Validate("CD No.", CDNo);
        FA.Modify;

        LibraryCDTracking.CreatePurchOrder(PurchaseHeader, Vendor."No.", '');

        Qty := 1;
        LibraryCDTracking.CreatePurchLineFA(PurchaseLine, PurchaseHeader, FA."No.", 10000, Qty);
        DisableUnrealizedVATPostingSetup(PurchaseLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        ReleaseDate := CalcDate('<+1D>', WorkDate);
        LibraryCDTracking.CreateFAReleaseAct(FADocHeader, FA."No.", ReleaseDate);
        LibraryCDTracking.PostFAReleaseAct(FADocHeader);

        VATLedgerCode := LibraryCDTracking.CreateVATPurchaseLedger(StartDate, EndDate, '');

        WriteoffDate := CalcDate('<+1D>', ReleaseDate);
        LibraryCDTracking.CreateFAWriteOffAct(FADocHeader, FA."No.", WriteoffDate);
        LibraryCDTracking.PostFAWriteOffAct(FADocHeader);

        WorkDate := CalcDate('<+1D>', WriteoffDate);
        LibraryCDTracking.CreateSalesOrder(SalesHeader, Customer."No.", '');
        LibraryCDTracking.CreateSalesLineFA(SalesLine, SalesHeader, FA."No.", 10000, 1);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        WorkDate := CalcDate('<+1D>', WorkDate);
        SalesInvoiceHeader.SetCurrentKey("Sell-to Customer No.");
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesInvoiceHeader.FindLast;

        LibraryCDTracking.CreateSalesReturnOrder(SalesHeader, Customer."No.", Location.Code);
        CopySalesDocument.SetSalesHeader(SalesHeader);
        CopySalesDocument.InitializeRequest(SaleDocType::"Posted Invoice", SalesInvoiceHeader."No.", true, true);
        CopySalesDocument.UseRequestPage(false);
        CopySalesDocument.Run;

        SalesHeader."Include In Purch. VAT Ledger" := true;
        SalesHeader.Modify;

        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CheckPurchaseLedger(VATLedgerCode);
    end;

    [Normal]
    local procedure CheckPurchaseLedger(DocNo: Code[50])
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        VATLedgerLine.Reset;
        VATLedgerLine.SetCurrentKey(Type, Code, "Line No.");
        VATLedgerLine.SetRange(Code, DocNo);
        Assert.IsTrue(VATLedgerLine.FindLast, VATLedgerErr);
    end;

    local procedure DisableUnrealizedVATPostingSetup(PurchLine: Record "Purchase Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(PurchLine."VAT Bus. Posting Group", PurchLine."VAT Prod. Posting Group");
        VATPostingSetup.Validate("Unrealized VAT Type", 0);
        VATPostingSetup.Modify(true);
    end;
}

