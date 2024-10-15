codeunit 147105 "SCM CD SE Fixes"
{
    // // [FEATURE] [CD Tracking]

    Subtype = Test;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        LibraryCDTracking: Codeunit "Library - CD Tracking";
        LibraryPurchase: Codeunit "Library - Purchase";
        CDNumberIsRequired: Label 'You must assign a CD number for item %1.', Comment = '%1 - Item No.';
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LineNoTxt: Label ' Line No. = ''%1''.', Comment = '%1 - Line No.';
        IncorrectErrorMessageErr: Label 'Incorrect error message';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        ItemTrackingOption: Option AssignCDNo,ReclassCDNo;

    [Test]
    [Scope('OnPrem')]
    procedure PostIJL_PositiveAdjNoCD_CDItem()
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        // Test case to check Positive Adjustment Item Journal Line with undefined Tracking Specification
        // for Item with CD Tracking cannot be posted

        PostItemJnlLineWithUndefinedCDNo(ItemJnlLine."Entry Type"::"Positive Adjmt.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostIJL_PurchaseNoCD_CDItem()
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        // Test case to check Purchase Item Journal Line with undefined Tracking Specification
        // for Item with CD Tracking cannot be posted

        PostItemJnlLineWithUndefinedCDNo(ItemJnlLine."Entry Type"::Purchase);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSE30275()
    var
        Location: Record Location;
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        Vendor: Record Vendor;
        PurchRcptLine: Record "Purch. Rcpt. Line";
        CopyPurchaseDocument: Report "Copy Purchase Document";
        DocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Receipt","Posted Invoice","Posted Return Shipment","Posted Credit Memo","Posted Shipment";
        CDNo: array[2] of Code[30];
    begin
        // Test case to check Purchase Credit Memo creation from Posted Purchase Receipt using Copy Document functionality
        // Check for CD Tracking info is correctly copied also

        Initialize;
        LibraryPurchase.CreateVendor(Vendor);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);
        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        CDNo[1] := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", CDNo[1]);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Location Code", Location.Code);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 10);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify();
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo[1], 10);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchRcptLine.Reset();
        PurchRcptLine.SetFilter("Buy-from Vendor No.", Vendor."No.");
        PurchRcptLine.FindFirst;

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", Vendor."No.");
        PurchaseHeader."Vendor Cr. Memo No." := PurchaseHeader."No.";
        CopyPurchaseDocument.UseRequestPage(false);
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader);
        CopyPurchaseDocument.InitializeRequest(DocType::"Posted Receipt", PurchRcptLine."Document No.", true, true);
        CopyPurchaseDocument.Run;
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', CDNo[1], -10);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VSE30283()
    var
        LibrarySales: Codeunit "Library - Sales";
        Location: Record Location;
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        Vendor: Record Vendor;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        CDNo: array[2] of Code[30];
        Qty: Decimal;
    begin
        // Test case to check Purchase Credit Memo creation from Posted Purchase Receipt using Copy Document functionality
        // Check for CD Tracking info is correctly copied also

        Initialize;
        LibraryPurchase.CreateVendor(Vendor);
        LibrarySales.CreateCustomer(Customer);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);
        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        CDNo[1] := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", CDNo[1]);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Location Code", Location.Code);
        PurchaseHeader.Modify(true);
        Qty := LibraryRandom.RandInt(100);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Qty);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify();
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo[1], Qty);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryCDTracking.CreateSalesOrder(SalesHeader, Customer."No.", Location.Code);
        LibraryCDTracking.CreateSalesLineItem(SalesLine, SalesHeader, Item."No.", Qty, Qty);
        ReservationEntry.Reset();
        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine, '', '', CDNo[1], Qty);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindLast;

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        LibraryCDTracking.CreateSalesLineItem(
          SalesLine, SalesHeader, Item."No.", LibraryRandom.RandDec(100, 2), Qty);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify();
        ReservationEntry.Reset();
        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine, '', '', '', Qty);
        ReservationEntry.Validate("Appl.-from Item Entry", ItemLedgerEntry."Entry No.");
        ReservationEntry.Validate("CD No.", CDNo[1]);
        ReservationEntry.UpdateItemTracking;
        ReservationEntry.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', CDNo[1], Qty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageWithLineNoShownWhenPostItemJnlLineWithoutCDNo()
    var
        Item: Record Item;
        Location: Record Location;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemJnlLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 378978] Error message with current "Line No." is shown when post Item Journal Line without "CD No." assigned

        Initialize;

        // [GIVEN] Item "X" with "CD Specific Tracking"
        LibraryWarehouse.CreateLocation(Location);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);

        // [WHEN] Post Item Journal Line without "CD No." assigned
        LibraryCDTracking.CreateItemJnlLine(
          ItemJnlLine, ItemJnlLine."Entry Type"::"Positive Adjmt.", WorkDate, Item."No.", LibraryRandom.RandInt(100), Location.Code);
        asserterror LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        // [THEN] Error Message "CD Number required. Line No. = '10000'" is shown
        Assert.AreEqual(
          GetLastErrorText, StrSubstNo(CDNumberIsRequired, Item."No.") + StrSubstNo(LineNoTxt, ItemJnlLine."Line No."),
          IncorrectErrorMessageErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure NewCDNoSavedAfterModification()
    var
        Item: Record Item;
        Location: Record Location;
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        ItemJournalLine: Record "Item Journal Line";
        Qty: Integer;
        CDNo: array[3] of Code[30];
        I: Integer;
    begin
        // [FEATURE] [Item Reclassfication]
        // [SCENARIO 229926] "New CD No." should be saved when it is defined and then changed in the item tracking page

        Initialize;

        // [GIVEN] Item "I" with CD tracking
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);
        LibraryCDTracking.CreateCDTracking(CDTrackingSetup, ItemTrackingCode.Code, Location.Code);

        for I := 1 to ArrayLen(CDNo) do
            CDNo[I] := LibraryUtility.GenerateGUID;
        Qty := LibraryRandom.RandInt(100);

        // [GIVEN] Post inbound inventory for item "I" and assign CD no. "CD1"
        LibraryCDTracking.CreateItemJnlLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", WorkDate, Item."No.", Qty, Location.Code);
        LibraryVariableStorage.Enqueue(ItemTrackingOption::AssignCDNo);
        LibraryVariableStorage.Enqueue(CDNo[1]);
        LibraryVariableStorage.Enqueue(ItemJournalLine."Quantity (Base)");
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryCDTracking.PostItemJnlLine(ItemJournalLine);

        // [GIVEN] Create an item reclassification journal line for item "I", assign new CD "CD2"
        LibraryCDTracking.CreateItemJnlLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::Transfer, WorkDate, Item."No.", Qty, Location.Code);
        ItemJournalLine.Validate("New Location Code", Location.Code);
        ItemJournalLine.Modify(true);

        AssignTrackingReclassification(ItemJournalLine, CDNo[1], CDNo[2]);

        // [WHEN] Reopen item tracking for the same journal line and change "New CD No." from "CD2" to "CD3"
        AssignTrackingReclassification(ItemJournalLine, CDNo[1], CDNo[3]);

        // [THEN] Reservatin entry is updated. "New CD No." is "CD3"
        VerifyTrackingReclassification(ItemJournalLine, CDNo[3]);
    end;

    local procedure Initialize()
    begin
        if isInitialized then
            exit;

        LibraryCDTracking.UpdateERMCountryData;
        UpdateSalesSetup;
        UpdateInventorySetup;

        isInitialized := true;
        Commit();
    end;

    local procedure AssignTrackingReclassification(var ItemJournalLine: Record "Item Journal Line"; CDNo: Code[30]; NewCDNo: Code[30])
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingOption::ReclassCDNo);
        LibraryVariableStorage.Enqueue(CDNo);
        LibraryVariableStorage.Enqueue(ItemJournalLine."Quantity (Base)");
        LibraryVariableStorage.Enqueue(NewCDNo);
        ItemJournalLine.OpenItemTrackingLines(true);
    end;

    local procedure PostItemJnlLineWithUndefinedCDNo(EntryType: Option)
    var
        Location: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemTrackingCode: Record "Item Tracking Code";
        CDHeader: Record "CD No. Header";
        CDLine: Record "CD No. Information";
        CDNo: array[2] of Code[30];
    begin
        Initialize;
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);

        LibraryCDTracking.CreateCDHeaderWithCountryRegion(CDHeader);
        CDNo[1] := LibraryUtility.GenerateGUID;

        LibraryCDTracking.CreateItemCDInfo(CDHeader, CDLine, Item."No.", CDNo[1]);
        LibraryCDTracking.CreateItemJnlLine(
          ItemJnlLine, EntryType, WorkDate, Item."No.", LibraryRandom.RandInt(100), Location.Code);

        asserterror LibraryCDTracking.PostItemJnlLine(ItemJnlLine);
        Assert.ExpectedError(StrSubstNo(CDNumberIsRequired, Item."No."));
    end;

    local procedure UpdateSalesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Exact Cost Reversing Mandatory" := true;
        SalesReceivablesSetup.Modify();
    end;

    local procedure UpdateInventorySetup()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Location Mandatory", true);
        InventorySetup.Modify();
    end;

    local procedure VerifyTrackingReclassification(ItemJnlLine: Record "Item Journal Line"; ExpectedCDNo: Code[30])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        with ReservationEntry do begin
            SetRange("Item No.", ItemJnlLine."Item No.");
            SetRange("Source Type", DATABASE::"Item Journal Line");
            SetRange("Source ID", ItemJnlLine."Journal Template Name");
            SetRange("Source Batch Name", ItemJnlLine."Journal Batch Name");
            FindFirst;

            TestField("New CD No.", ExpectedCDNo);
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        TrackingOption: Option;
    begin
        TrackingOption := LibraryVariableStorage.DequeueInteger;
        ItemTrackingLines."CD No.".SetValue(LibraryVariableStorage.DequeueText);
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal);
        if TrackingOption = ItemTrackingOption::ReclassCDNo then
            ItemTrackingLines."New CD No.".SetValue(LibraryVariableStorage.DequeueText);
        ItemTrackingLines.OK.Invoke;
    end;
}

