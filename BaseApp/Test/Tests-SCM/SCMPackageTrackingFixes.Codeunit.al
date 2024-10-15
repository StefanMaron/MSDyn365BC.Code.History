codeunit 137268 "SCM Package Tracking Fixes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        PackageNumberIsRequired: Label 'You must assign a package number for item %1.', Comment = '%1 - Item No.';
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LineNoTxt: Label ' Line No. = ''%1''.', Comment = '%1 - Line No.';
        IncorrectErrorMessageErr: Label 'Incorrect error message';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        ItemTrackingOption: Option AssignPackageNo,ReclassPackageNo;

    [Test]
    [Scope('OnPrem')]
    procedure PostItemJnlLinePosAdjmtNoPackage()
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        // Test case to check Positive Adjustment Item Journal Line with undefined Tracking Specification
        // for Item with Package Tracking cannot be posted

        PostItemJnlLineWithUndefinedPackageNo(ItemJnlLine."Entry Type"::"Positive Adjmt.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostItemJnlLinePurchaseNoPackage()
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        // Test case to check Purchase Item Journal Line with undefined Tracking Specification
        // for Item with Package Tracking cannot be posted

        PostItemJnlLineWithUndefinedPackageNo(ItemJnlLine."Entry Type"::Purchase);
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
        PackageNoInfo: Record "Package No. Information";
        Vendor: Record Vendor;
        PurchRcptLine: Record "Purch. Rcpt. Line";
        CopyPurchaseDocument: Report "Copy Purchase Document";
        DocType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Receipt","Posted Invoice","Posted Return Shipment","Posted Credit Memo","Posted Shipment";
        CDNo: array[2] of Code[50];
    begin
        // Test case to check Purchase Credit Memo creation from Posted Purchase Receipt using Copy Document functionality
        // Check for CD Tracking info is correctly copied also

        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);
        CDNo[1] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", CDNo[1]);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Location Code", Location.Code);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 10);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify();
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', '', CDNo[1], 10);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchRcptLine.Reset();
        PurchRcptLine.SetFilter("Buy-from Vendor No.", Vendor."No.");
        PurchRcptLine.FindFirst;

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", Vendor."No.");
        PurchaseHeader."Vendor Cr. Memo No." := PurchaseHeader."No.";
        CopyPurchaseDocument.UseRequestPage(false);
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader);
#if CLEAN17
        CopyPurchaseDocument.SetParameters(DocType::"Posted Receipt", PurchRcptLine."Document No.", true, true);
#else
        CopyPurchaseDocument.InitializeRequest(DocType::"Posted Receipt", PurchRcptLine."Document No.", true, true);
#endif
        CopyPurchaseDocument.Run;

        LibrarySmallBusiness.UpdatePurchHeaderDocTotal(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', CDNo[1], -10);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPackageTrackingWithAppliedEntryNo()
    var
        Location: Record Location;
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        PackageNoInfo: Record "Package No. Information";
        Vendor: Record Vendor;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PackageNo: array[2] of Code[50];
        Qty: Decimal;
    begin
        // Test case to check Purchase Credit Memo creation from Posted Purchase Receipt using Copy Document functionality
        // Check for Package Tracking info is correctly copied also

        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        LibrarySales.CreateCustomer(Customer);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);
        PackageNo[1] := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[1]);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Location Code", Location.Code);
        PurchaseHeader.Modify(true);
        Qty := LibraryRandom.RandInt(100);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Qty);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify();
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', '', PackageNo[1], Qty);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibrarySales.CreateSalesOrderWithLocation(SalesHeader, Customer."No.", Location.Code);
        LibrarySales.CreateSalesLineWithUnitPrice(SalesLine, SalesHeader, Item."No.", Qty, Qty);
        ReservationEntry.Reset();
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine, '', '', PackageNo[1], Qty);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindLast;

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        LibrarySales.CreateSalesLineWithUnitPrice(
          SalesLine, SalesHeader, Item."No.", LibraryRandom.RandDec(100, 2), Qty);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify();
        ReservationEntry.Reset();
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine, '', '', '', Qty);
        ReservationEntry.Validate("Appl.-from Item Entry", ItemLedgerEntry."Entry No.");
        ReservationEntry.Validate("Package No.", PackageNo[1]);
        ReservationEntry.UpdateItemTracking;
        ReservationEntry.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryItemTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', PackageNo[1], Qty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorMessageWithLineNoShownWhenPostItemJnlLineWithoutPackageNo()
    var
        Item: Record Item;
        Location: Record Location;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemJnlLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 378978] Error message with current "Line No." is shown when post Item Journal Line without "Package No." assigned

        Initialize();

        // [GIVEN] Item "X" with "Package Specific Tracking"
        LibraryWarehouse.CreateLocation(Location);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        // [WHEN] Post Item Journal Line without "Package No." assigned
        LibraryInventory.CreateItemJnlLine(
          ItemJnlLine, ItemJnlLine."Entry Type"::"Positive Adjmt.", WorkDate, Item."No.", LibraryRandom.RandInt(100), Location.Code);
        asserterror LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);

        // [THEN] Error Message "Package Number required. Line No. = '10000'" is shown
        Assert.AreEqual(
          GetLastErrorText, StrSubstNo(PackageNumberIsRequired, Item."No.") + StrSubstNo(LineNoTxt, ItemJnlLine."Line No."),
          IncorrectErrorMessageErr);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SCM Package Tracking Fixes");
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Package Tracking Fixes");
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.UpdateLocalData();

        UpdateSalesSetup();
        UpdateInventorySetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Package Tracking Fixes");
    end;

    local procedure AssignTrackingReclassification(var ItemJournalLine: Record "Item Journal Line"; PackageNo: Code[50]; NewPackageNo: Code[50])
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingOption::ReclassPackageNo);
        LibraryVariableStorage.Enqueue(PackageNo);
        LibraryVariableStorage.Enqueue(ItemJournalLine."Quantity (Base)");
        LibraryVariableStorage.Enqueue(NewPackageNo);
        ItemJournalLine.OpenItemTrackingLines(true);
    end;

    local procedure PostItemJnlLineWithUndefinedPackageNo(EntryType: Enum "Item Ledger Entry Type")
    var
        Location: Record Location;
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemTrackingCode: Record "Item Tracking Code";
        PackageNoInfo: Record "Package No. Information";
        PackageNo: array[2] of Code[50];
    begin
        Initialize();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        PackageNo[1] := LibraryUtility.GenerateGUID();

        LibraryItemTracking.CreatePackageNoInformation(PackageNoInfo, Item."No.", PackageNo[1]);
        LibraryInventory.CreateItemJnlLine(
          ItemJnlLine, EntryType, WorkDate, Item."No.", LibraryRandom.RandInt(100), Location.Code);

        asserterror LibraryInventory.PostItemJnlLineWithCheck(ItemJnlLine);
        Assert.ExpectedError(StrSubstNo(PackageNumberIsRequired, Item."No."));
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

    local procedure VerifyTrackingReclassification(ItemJnlLine: Record "Item Journal Line"; ExpectedPackageNo: Code[50])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        with ReservationEntry do begin
            SetRange("Item No.", ItemJnlLine."Item No.");
            SetRange("Source Type", DATABASE::"Item Journal Line");
            SetRange("Source ID", ItemJnlLine."Journal Template Name");
            SetRange("Source Batch Name", ItemJnlLine."Journal Batch Name");
            FindFirst;

            TestField("New Package No.", ExpectedPackageNo);
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        TrackingOption: Option;
    begin
        TrackingOption := LibraryVariableStorage.DequeueInteger;
        ItemTrackingLines."Package No.".SetValue(LibraryVariableStorage.DequeueText);
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal);
        if TrackingOption = ItemTrackingOption::ReclassPackageNo then
            ItemTrackingLines."New Package No.".SetValue(LibraryVariableStorage.DequeueText);
        ItemTrackingLines.OK.Invoke;
    end;
}

