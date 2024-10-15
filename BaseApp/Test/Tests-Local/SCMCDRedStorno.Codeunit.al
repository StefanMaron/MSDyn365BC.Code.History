codeunit 147107 "SCM CD Red Storno"
{
    Subtype = Test;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryCDTracking: Codeunit "Library - CD Tracking";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryCosting: Codeunit "Library - Costing";
        NoAppliesEntryErr: Label 'Applies-from Entry must have a value in Item Journal Line: Journal Template Name=, Journal Batch Name=, Line No.=0.';
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        isInitialized: Boolean;
        WrongValueErr: Label 'Wrong value of field %1 in table %2.';

    [Test]
    [Scope('OnPrem')]
    procedure TestRedStorno()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Customer: Record Customer;
        Vendor: Record Vendor;
        Item: Record Item;
        ReservationEntry: Record "Reservation Entry";
        ItemJnlLine: Record "Item Journal Line";
        Location: Record Location;
        EntryType: Option Purchase,Sale,"Positive Adjmt.","Negative Adjmt.",Transfer,Consumption,Output;
        CDNo: Code[30];
        Qty: Integer;
    begin
        Initialize;

        LibraryCDTracking.CreateForeignVendor(Vendor);
        LibrarySales.CreateCustomer(Customer);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);

        LibraryCDTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode.Code);

        CDNo := CreateItemCDInfo(Item."No.");

        LibraryCDTracking.CreatePurchOrder(PurchaseHeader, Vendor."No.", Location.Code);
        Qty := LibraryRandom.RandInt(3);
        LibraryCDTracking.CreatePurchLineItem(
          PurchaseLine, PurchaseHeader, Item."No.", LibraryRandom.RandDec(100, 2), Qty);
        LibraryCDTracking.CreatePurchLineTracking(ReservationEntry, PurchaseLine, '', '', CDNo, Qty);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', CDNo, Qty);

        LibraryCDTracking.CreateItemJnlLine(ItemJnlLine, EntryType::Purchase, WorkDate, Item."No.", -Qty, Location.Code);
        ItemJnlLine."Red Storno" := true;
        ItemJnlLine.Modify();

        LibraryCDTracking.CreateItemJnlLineTracking(ReservationEntry, ItemJnlLine, '', '', CDNo, -Qty);
        ReservationEntry.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
        ReservationEntry.Modify();
        LibraryCDTracking.PostItemJnlLine(ItemJnlLine);

        LibraryCDTracking.CheckLastItemLedgerEntry(ItemLedgerEntry, Item."No.", Location.Code, '', '', CDNo, -Qty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS336176_Ship()
    var
        ItemDocHeader: Record "Item Document Header";
    begin
        TFS336176_ShipReceipt(ItemDocHeader."Document Type"::Shipment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS336176_Receipt()
    var
        ItemDocHeader: Record "Item Document Header";
    begin
        TFS336176_ShipReceipt(ItemDocHeader."Document Type"::Receipt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS336176_CheckErrNoApplyEntry()
    var
        ItemCode: Code[20];
        LocationCode: Code[10];
        DocType: Option Rcpt,Ship;
        ItemQty: Integer;
        Amount: Decimal;
    begin
        Initialize;
        ItemQty := LibraryRandom.RandInt(3);
        Amount := LibraryRandom.RandDec(100, 2);

        ItemCode := LibraryInventory.CreateItemNo;
        LocationCode := CreateLocation;
        CreateInventoryPostingSetup(LocationCode, GetItemGroupCode(ItemCode));

        CreatePostItemJnlLine(ItemCode, LocationCode, ItemQty, Amount);
        CreatePostItemDocument(DocType::Ship, LocationCode, ItemCode, ItemQty, Amount);
        asserterror CreatePostShipCorrItDocNoApply(LocationCode, ItemCode, ItemQty, Amount);
        Assert.ExpectedError(NoAppliesEntryErr);
    end;

    local procedure TFS336176_ShipReceipt(DocType: Option)
    var
        Amount: Decimal;
    begin
        Initialize;
        Amount := LibraryRandom.RandDec(100, 2);
        CreateDocRunAdjustCostEntries(DocType, Amount);
        VerifyPostedGLEntries(DocType, Amount);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceLinesModalPageHandler,CorrectionTypeStrMenuHandler')]
    [Scope('OnPrem')]
    procedure BlankAppliesFromEntryForCorrCrMemoWithTracking()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        CorrectiveDocumentMgt: Codeunit "Corrective Document Mgt.";
        InvoiceNo: Code[20];
        CDNo: Code[30];
    begin
        // [FEATURE] [Sales] [Correction] [Credit Memo] [Item Tracking]
        // [SCENARIO 206411] Function "Get Corr. Lines" of Corrective Sales Credit Memo does not assign "Applies-From Item Entry No." automatically if tracking exists

        Initialize;

        // [GIVEN] Inventory Setup "Enable Red Storno" = TRUE.
        // [GIVEN] Posted Sales Invoice "I" with Item Tracking for "CD No."

        LibraryCDTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        CreateItemWithTrackingCode(Item, ItemTrackingCode.Code);
        CDNo := CreateItemCDInfo(Item."No.");

        LibraryCDTracking.CreateSalesOrder(SalesHeader, LibrarySales.CreateCustomerNo, '');
        LibraryCDTracking.CreateSalesLineItem(
          SalesLine, SalesHeader, LibraryInventory.CreateItemNo, LibraryRandom.RandDec(100, 2), LibraryRandom.RandIntInRange(100, 200));
        LibraryCDTracking.CreateSalesLineTracking(ReservationEntry, SalesLine, '', '', CDNo, SalesLine.Quantity);
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Create Corrective Sales Credit Memo with "Corrective Doc. Type" = Revision. Use "Get Corr. Doc. Lines" from posted invoice "I".
        LibrarySales.CreateCorrSalesCrMemoByInvNo(SalesHeader, SalesHeader."Bill-to Customer No.", InvoiceNo);

        // [WHEN] Invoke function "Get Corr. Lines" against Corrective Sales Credit Memo and select line from Posted Sales Invoice
        // Selection handled by SalesInvoiceLinesModalPageHandler
        CorrectiveDocumentMgt.SetSalesHeader(SalesHeader."Document Type", SalesHeader."No.");
        CorrectiveDocumentMgt.SelectPstdSalesDocLines;

        // [THEN] Sales Line is copied from Posted Sales Invoice to Corrective Sales Credit Memo and "Applies-From Item Entry No. is blank
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        SalesLine.TestField("Appl.-from Item Entry", 0);
    end;

    local procedure Initialize()
    begin
        if isInitialized then
            exit;

        LibraryCDTracking.UpdateERMCountryData;

        EnableRedStorno;
        DisableStockoutWarning;

        isInitialized := true;
    end;

    local procedure EnableRedStorno()
    var
        InvSetup: Record "Inventory Setup";
    begin
        with InvSetup do begin
            Get;
            "Enable Red Storno" := true;
            Modify(true);
        end;
    end;

    local procedure DisableStockoutWarning()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        with SalesReceivablesSetup do begin
            Get;
            Validate("Stockout Warning", false);
            Modify(true);
        end;
    end;

    local procedure CreateInventoryPostingSetup(LocationCode: Code[10]; PostGroupCode: Code[10])
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        with InventoryPostingSetup do begin
            LibraryInventory.CreateInventoryPostingSetup(InventoryPostingSetup, LocationCode, PostGroupCode);
            Validate("Inventory Account", CreateGLAcc);
            Modify(true);
        end;
    end;

    local procedure CreateGLAcc(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        with GLAccount do begin
            LibraryERM.CreateGLAccount(GLAccount);
            exit("No.");
        end;
    end;

    local procedure CreatePostItemJnlLine(ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal; UnitAmt: Decimal)
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        CreateItemJnlLine(ItemJnlLine, ItemNo, LocationCode, ItemJnlLine."Entry Type"::"Positive Adjmt.", Qty, UnitAmt);
        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");
    end;

    local procedure CreateItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; ItemNo: Code[20]; LocationCode: Code[10]; EntryType: Option; Qty: Decimal; UnitAmt: Decimal)
    var
        ItemJnlBatch: Record "Item Journal Batch";
        TemplateName: Code[10];
        ItemJnlTemplateType: Option Item,Transfer,"Phys. Inventory",Revaluation,Consumption,Output,Capacity,"Prod.Order";
    begin
        TemplateName := FindItemJnlTemplate(ItemJnlTemplateType::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJnlBatch, TemplateName);

        with ItemJnlLine do begin
            LibraryInventory.CreateItemJournalLine(
              ItemJnlLine, TemplateName, ItemJnlBatch.Name, EntryType, ItemNo, Qty);
            Validate("Location Code", LocationCode);
            Validate("Unit Amount", UnitAmt);
            Modify(true);
        end;
    end;

    local procedure CreateLocation(): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocation(Location);
        exit(Location.Code);
    end;

    local procedure FindItemJnlTemplate(ItemJnlTemplateType: Option): Code[10]
    var
        ItemJnlTemplate: Record "Item Journal Template";
    begin
        with ItemJnlTemplate do begin
            SetRange(Type, ItemJnlTemplateType);
            SetRange(Recurring, false);
            FindFirst;
            exit(Name);
        end;
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocType: Option; DocNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocType);
        SalesLine.SetRange("Document No.", DocNo);
        SalesLine.FindFirst;
    end;

    local procedure GetItemGroupCode(ItemCode: Code[20]): Code[10]
    var
        Item: Record Item;
    begin
        with Item do begin
            Get(ItemCode);
            exit("Inventory Posting Group");
        end;
    end;

    local procedure GetItemLedgEntryNo(ItemNo: Code[20]; LocationCode: Code[10]): Integer
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        with ItemLedgEntry do begin
            SetRange("Item No.", ItemNo);
            SetRange("Location Code", LocationCode);
            if FindLast then
                exit("Entry No.");
        end;
    end;

    local procedure CreatePostShipCorrItDocNoApply(LocationCode: Code[10]; ItemNo: Code[20]; Qty: Decimal; UnitAmt: Decimal)
    var
        ItemDocumentHeader: Record "Item Document Header";
    begin
        CreatePostCorrItemDocument(ItemDocumentHeader."Document Type"::Shipment, LocationCode, ItemNo, Qty, UnitAmt, 0);
    end;

    local procedure CreatePostCorrItemDocument(DocType: Option; LocationCode: Code[10]; ItemNo: Code[20]; Qty: Decimal; UnitAmt: Decimal; ApplyEntry: Integer)
    var
        ItemDocumentHeader: Record "Item Document Header";
        ItemDocumentLine: Record "Item Document Line";
    begin
        with ItemDocumentHeader do begin
            CreateItemDocument(ItemDocumentHeader, DocType, LocationCode);
            Validate(Correction, true);
            Modify(true);
        end;

        with ItemDocumentLine do begin
            CreateItemDocumentLine(ItemDocumentHeader, ItemDocumentLine, ItemNo, Qty, UnitAmt);
            if "Document Type" = "Document Type"::Shipment then
                Validate("Applies-from Entry", ApplyEntry)
            else
                Validate("Applies-to Entry", ApplyEntry);
            Modify(true);
        end;
        PostItemDocument(ItemDocumentHeader);
    end;

    local procedure CreatePostItemDocument(DocumentType: Option; LocationCode: Code[10]; ItemNo: Code[20]; Qty: Decimal; UnitAmt: Decimal)
    var
        ItemDocumentHeader: Record "Item Document Header";
        ItemDocumentLine: Record "Item Document Line";
    begin
        CreateItemDocument(ItemDocumentHeader, DocumentType, LocationCode);
        CreateItemDocumentLine(ItemDocumentHeader, ItemDocumentLine, ItemNo, Qty, UnitAmt);
        PostItemDocument(ItemDocumentHeader);
    end;

    local procedure CreateItemDocument(var ItemDocumentHeader: Record "Item Document Header"; DocumentType: Option; LocationCode: Code[10])
    begin
        with ItemDocumentHeader do begin
            Init;
            "Document Type" := DocumentType;
            Insert(true);
            Validate("Location Code", LocationCode);
            Modify;
        end;
    end;

    local procedure CreateItemDocumentLine(var ItemDocumentHeader: Record "Item Document Header"; var ItemDocumentLine: Record "Item Document Line"; ItemNo: Code[20]; Qty: Decimal; UnitAmt: Decimal)
    var
        RecRef: RecordRef;
    begin
        with ItemDocumentLine do begin
            Init;
            Validate("Document Type", ItemDocumentHeader."Document Type");
            Validate("Document No.", ItemDocumentHeader."No.");
            RecRef.GetTable(ItemDocumentLine);
            Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, FieldNo("Line No.")));
            Insert(true);
            Validate("Item No.", ItemNo);
            Validate(Quantity, Qty);
            Validate("Unit Amount", UnitAmt);
            Modify(true);
        end;
    end;

    local procedure CreateItemCDInfo(ItemNo: Code[20]) CDNo: Code[30]
    var
        CountryRegion: Record "Country/Region";
        CDNoHeader: Record "CD No. Header";
        CDNoInformation: Record "CD No. Information";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibraryCDTracking.CreateCDHeader(CDNoHeader, CountryRegion.Code);
        CDNo := LibraryUtility.GenerateGUID;
        LibraryCDTracking.CreateItemCDInfo(CDNoHeader, CDNoInformation, ItemNo, CDNo);
        exit(CDNo);
    end;

    local procedure CreateItemWithTrackingCode(var Item: Record Item; TrackingCode: Code[10])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", TrackingCode);
        Item.Modify(true);
    end;

    local procedure PostItemDocument(ItemDocumentHeader: Record "Item Document Header")
    begin
        with ItemDocumentHeader do
            case "Document Type" of
                "Document Type"::Receipt:
                    CODEUNIT.Run(CODEUNIT::"Item Doc.-Post Receipt", ItemDocumentHeader);
                "Document Type"::Shipment:
                    CODEUNIT.Run(CODEUNIT::"Item Doc.-Post Shipment", ItemDocumentHeader);
            end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceLinesModalPageHandler(var SalesInvoiceLines: TestPage "Sales Invoice Lines")
    begin
        SalesInvoiceLines.OK.Invoke;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CorrectionTypeStrMenuHandler(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        Choice := 1; // Quantity
    end;

    local procedure VerifyPostedGLEntries(DocType: Option; ExpectedAmount: Decimal)
    var
        ItemDocHeader: Record "Item Document Header";
        GLRegister: Record "G/L Register";
        GLEntry: Record "G/L Entry";
    begin
        GLRegister.FindLast;
        with GLEntry do begin
            Ascending(DocType = ItemDocHeader."Document Type"::Shipment);
            SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");
            FindSet;
            Assert.AreEqual(
              "Credit Amount", ExpectedAmount, StrSubstNo(WrongValueErr, FieldCaption("Credit Amount"), TableCaption));
            Next;
            Assert.AreEqual(
              "Debit Amount", ExpectedAmount, StrSubstNo(WrongValueErr, FieldCaption("Debit Amount"), TableCaption));
        end;
    end;

    local procedure CreateDocRunAdjustCostEntries(DocType: Option; Amount: Decimal)
    var
        ItemCode: Code[20];
        LocationCode: Code[10];
        ItemQty: Integer;
        i: Integer;
    begin
        ItemCode := LibraryInventory.CreateItemNo;
        ItemQty := LibraryRandom.RandInt(3);
        LocationCode := CreateLocation;
        CreateInventoryPostingSetup(LocationCode, GetItemGroupCode(ItemCode));

        CreatePostItemJnlLine(ItemCode, LocationCode, ItemQty, Amount);
        CreatePostItemDocument(DocType, LocationCode, ItemCode, ItemQty, Amount);
        CreatePostCorrItemDocument(DocType, LocationCode, ItemCode, ItemQty, Amount, GetItemLedgEntryNo(ItemCode, LocationCode));
        for i := 1 to ItemQty do
            CreatePostItemDocument(DocType, LocationCode, ItemCode, 1, Amount);
        LibraryCosting.AdjustCostItemEntries(ItemCode, '');
    end;
}

