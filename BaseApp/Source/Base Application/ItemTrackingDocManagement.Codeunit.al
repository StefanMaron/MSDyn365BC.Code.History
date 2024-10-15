codeunit 6503 "Item Tracking Doc. Management"
{

    trigger OnRun()
    begin
    end;

    var
        CountingRecordsMsg: Label 'Counting records...';
        TableNotSupportedErr: Label 'Table %1 is not supported.';
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        RetrieveAsmItemTracking: Boolean;
        CreateTrackingSpecQst: Label 'This function create tracking specification from reservation entries. Continue?';

    local procedure AddTempRecordToSet(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; SignFactor: Integer)
    var
        TempItemLedgEntry2: Record "Item Ledger Entry" temporary;
    begin
        if SignFactor <> 1 then begin
            TempItemLedgEntry.Quantity *= SignFactor;
            TempItemLedgEntry."Remaining Quantity" *= SignFactor;
            TempItemLedgEntry."Invoiced Quantity" *= SignFactor;
        end;
        ItemTrackingMgt.RetrieveAppliedExpirationDate(TempItemLedgEntry);
        TempItemLedgEntry2 := TempItemLedgEntry;
        TempItemLedgEntry.Reset;
        TempItemLedgEntry.SetTrackingFilter(
          TempItemLedgEntry2."Serial No.", TempItemLedgEntry2."Lot No.", TempItemLedgEntry2."CD No.");
        TempItemLedgEntry.SetRange("Warranty Date", TempItemLedgEntry2."Warranty Date");
        TempItemLedgEntry.SetRange("Expiration Date", TempItemLedgEntry2."Expiration Date");
        if TempItemLedgEntry.FindFirst then begin
            TempItemLedgEntry.Quantity += TempItemLedgEntry2.Quantity;
            TempItemLedgEntry."Remaining Quantity" += TempItemLedgEntry2."Remaining Quantity";
            TempItemLedgEntry."Invoiced Quantity" += TempItemLedgEntry2."Invoiced Quantity";
            TempItemLedgEntry.Modify;
        end else
            TempItemLedgEntry.Insert;

        OnAfterAddTempRecordToSet(TempItemLedgEntry, TempItemLedgEntry2, SignFactor);
        TempItemLedgEntry.Reset;
    end;

    procedure CollectItemTrkgPerPostedDocLine(var TempReservEntry: Record "Reservation Entry" temporary; var TempItemLedgEntry: Record "Item Ledger Entry" temporary; FromPurchase: Boolean; DocNo: Code[20]; LineNo: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        TempItemLedgEntry.Reset;
        TempItemLedgEntry.DeleteAll;

        with TempReservEntry do begin
            Reset;
            SetCurrentKey("Source ID", "Source Ref. No.");
            SetRange("Source ID", DocNo);
            SetRange("Source Ref. No.", LineNo);
            if FindSet then
                repeat
                    ItemLedgEntry.Get("Item Ledger Entry No.");
                    TempItemLedgEntry := ItemLedgEntry;
                    if "Reservation Status" = "Reservation Status"::Prospect then
                        TempItemLedgEntry."Entry No." := -TempItemLedgEntry."Entry No.";
                    if FromPurchase then
                        TempItemLedgEntry."Remaining Quantity" := "Quantity (Base)"
                    else
                        TempItemLedgEntry."Shipped Qty. Not Returned" := "Quantity (Base)";
                    TempItemLedgEntry."Document No." := "Source ID";
                    TempItemLedgEntry."Document Line No." := "Source Ref. No.";
                    TempItemLedgEntry.Insert;
                until Next = 0;
        end;
    end;

    procedure CopyItemLedgerEntriesToTemp(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; var FromItemLedgEntry: Record "Item Ledger Entry")
    begin
        TempItemLedgEntry.Reset;
        TempItemLedgEntry.DeleteAll;
        if FromItemLedgEntry.FindSet then
            repeat
                TempItemLedgEntry := FromItemLedgEntry;
                AddTempRecordToSet(TempItemLedgEntry, 1);
            until FromItemLedgEntry.Next = 0;

        TempItemLedgEntry.Reset;
    end;

    local procedure FillTrackingSpecBuffer(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; Type: Integer; Subtype: Integer; ID: Code[20]; BatchName: Code[10]; ProdOrderLine: Integer; RefNo: Integer; Description: Text[100]; ItemNo: Code[20]; LN: Code[50]; SN: Code[50]; CD: Code[30]; Qty: Decimal; Correction: Boolean)
    var
        LastEntryNo: Integer;
    begin
        // creates or sums up a record in TempTrackingSpecBuffer

        TempTrackingSpecBuffer.Reset;
        if TempTrackingSpecBuffer.FindLast then
            LastEntryNo := TempTrackingSpecBuffer."Entry No.";

        if ItemTrackingExistsInBuffer(TempTrackingSpecBuffer, Type, Subtype, ID, BatchName, ProdOrderLine, RefNo, LN, SN, CD) then begin
            TempTrackingSpecBuffer."Quantity (Base)" += Abs(Qty);                      // Sum up Qty
            TempTrackingSpecBuffer.Modify;
        end else begin
            LastEntryNo += 1;
            InitTrackingSpecBuffer(TempTrackingSpecBuffer, LastEntryNo, Type, Subtype, ID, BatchName,
              ProdOrderLine, RefNo, Description, ItemNo, LN, SN, Correction, CD);
            TempTrackingSpecBuffer."Quantity (Base)" := Abs(Qty);
            TempTrackingSpecBuffer.Insert;
        end;
    end;

    procedure FillTrackingSpecBufferFromILE(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; Type: Integer; Subtype: Integer; ID: Code[20]; BatchName: Code[10]; ProdOrderLine: Integer; RefNo: Integer; Description: Text[100])
    begin
        // creates a new record in TempTrackingSpecBuffer (used for Posted Shipments/Receipts/Invoices)

        if TempItemLedgEntry.FindSet then
            repeat
                if TempItemLedgEntry.TrackingExists then begin
                    FillTrackingSpecBuffer(
                        TempTrackingSpecBuffer, Type, Subtype, ID, BatchName, ProdOrderLine, RefNo, Description,
                        TempItemLedgEntry."Item No.", TempItemLedgEntry."Lot No.", TempItemLedgEntry."Serial No.", TempItemLedgEntry."CD No.",
                        TempItemLedgEntry.Quantity, TempItemLedgEntry.Correction);
                    OnAfterFillTrackingSpecBufferFromItemLedgEntry(TempTrackingSpecBuffer, TempItemLedgEntry);
                end;
            until TempItemLedgEntry.Next = 0;
    end;

    local procedure FindReservEntries(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; Type: Integer; Subtype: Integer; ID: Code[20]; BatchName: Code[10]; ProdOrderLine: Integer; RefNo: Integer; Description: Text[100])
    var
        ReservEntry: Record "Reservation Entry";
    begin
        // finds Item Tracking for Quote, Order, Invoice, Credit Memo, Return Order

        ReservEntry.SetSourceFilter(Type, Subtype, ID, RefNo, true);
        ReservEntry.SetSourceFilter(BatchName, ProdOrderLine);
        if ReservEntry.FindSet then
            repeat
                if ReservEntry.TrackingExists then begin
                    FillTrackingSpecBuffer(TempTrackingSpecBuffer, Type, Subtype, ID, BatchName,
                      ProdOrderLine, RefNo, Description, ReservEntry."Item No.", ReservEntry."Lot No.",
                      ReservEntry."Serial No.", ReservEntry."CD No.", ReservEntry."Quantity (Base)", ReservEntry.Correction);
                    OnAfterFillTrackingSpecBufferFromReservEntry(TempTrackingSpecBuffer, ReservEntry);
                end;
            until ReservEntry.Next = 0;
    end;

    local procedure FindTrackingEntries(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; Type: Integer; Subtype: Integer; ID: Code[20]; BatchName: Code[10]; ProdOrderLine: Integer; RefNo: Integer; Description: Text[100])
    var
        TrackingSpec: Record "Tracking Specification";
    begin
        // finds Item Tracking for Quote, Order, Invoice, Credit Memo, Return Order when shipped/received

        TrackingSpec.SetSourceFilter(Type, Subtype, ID, RefNo, true);
        TrackingSpec.SetSourceFilter(BatchName, ProdOrderLine);
        if TrackingSpec.FindSet then
            repeat
                if TrackingSpec.TrackingExists then begin
                    FillTrackingSpecBuffer(TempTrackingSpecBuffer, Type, Subtype, ID, BatchName,
                      ProdOrderLine, RefNo, Description, TrackingSpec."Item No.", TrackingSpec."Lot No.",
                      TrackingSpec."Serial No.", TrackingSpec."CD No.", TrackingSpec."Quantity (Base)", TrackingSpec.Correction);
                    OnAfterFillTrackingSpecBufferFromTrackingEntries(TempTrackingSpecBuffer, TrackingSpec);
                end;
            until TrackingSpec.Next = 0;
    end;

    procedure FindShptRcptEntries(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; Type: Integer; Subtype: Integer; ID: Code[20]; BatchName: Code[10]; ProdOrderLine: Integer; RefNo: Integer; Description: Text[100])
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
    begin
        // finds Item Tracking for Posted Shipments/Receipts

        RetrieveEntriesFromShptRcpt(TempItemLedgEntry, Type, Subtype, ID, BatchName, ProdOrderLine, RefNo);
        FillTrackingSpecBufferFromILE(
          TempItemLedgEntry, TempTrackingSpecBuffer, Type, Subtype, ID, BatchName, ProdOrderLine, RefNo, Description);

        TempTrackingSpecBuffer.Reset;
    end;

    procedure FindInvoiceEntries(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; Type: Integer; Subtype: Integer; ID: Code[20]; BatchName: Code[10]; ProdOrderLine: Integer; RefNo: Integer; Description: Text[100])
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        InvoiceRowID: Text[250];
    begin
        InvoiceRowID := ItemTrackingMgt.ComposeRowID(Type, Subtype, ID, BatchName, ProdOrderLine, RefNo);
        RetrieveEntriesFromPostedInv(TempItemLedgEntry, InvoiceRowID);
        FillTrackingSpecBufferFromILE(
          TempItemLedgEntry, TempTrackingSpecBuffer, Type, Subtype, ID, BatchName, ProdOrderLine, RefNo, Description);

        TempTrackingSpecBuffer.Reset;
    end;

    local procedure InitTrackingSpecBuffer(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; EntryNo: Integer; Type: Integer; Subtype: Integer; ID: Code[20]; BatchName: Code[10]; ProdOrderLine: Integer; RefNo: Integer; Description: Text[100]; ItemNo: Code[20]; LN: Code[50]; SN: Code[50]; Correction: Boolean; CD: Code[30])
    begin
        // initializes a new record for TempTrackingSpecBuffer

        TempTrackingSpecBuffer.Init;
        TempTrackingSpecBuffer."Source Type" := Type;
        TempTrackingSpecBuffer."Entry No." := EntryNo;
        TempTrackingSpecBuffer."Item No." := ItemNo;
        TempTrackingSpecBuffer.Description := Description;
        TempTrackingSpecBuffer."Source Subtype" := Subtype;
        TempTrackingSpecBuffer."Source ID" := ID;
        TempTrackingSpecBuffer."Source Batch Name" := BatchName;
        TempTrackingSpecBuffer."Source Prod. Order Line" := ProdOrderLine;
        TempTrackingSpecBuffer."Source Ref. No." := RefNo;
        TempTrackingSpecBuffer."Lot No." := LN;
        TempTrackingSpecBuffer."Serial No." := SN;
        TempTrackingSpecBuffer.Correction := Correction;
        TempTrackingSpecBuffer."CD No." := CD;
    end;

    local procedure ItemTrackingExistsInBuffer(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; Type: Integer; Subtype: Integer; ID: Code[20]; BatchName: Code[10]; ProdOrderLine: Integer; RefNo: Integer; LotNo: Code[50]; SerialNo: Code[50]; CDNo: Code[30]): Boolean
    begin
        // searches after existing record in TempTrackingSpecBuffer
        TempTrackingSpecBuffer.SetSourceFilter(Type, Subtype, ID, RefNo, true);
        TempTrackingSpecBuffer.SetSourceFilter(BatchName, ProdOrderLine);
        TempTrackingSpecBuffer.SetTrackingFilter(SerialNo, LotNo, CDNo);
        if not TempTrackingSpecBuffer.IsEmpty then begin
            TempTrackingSpecBuffer.FindFirst;
            exit(true);
        end;
        exit(false);
    end;

    procedure RetrieveDocumentItemTracking(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; SourceID: Code[20]; SourceType: Integer; SourceSubType: Option): Integer
    var
        Found: Boolean;
    begin
        // retrieves Item Tracking for Purchase Header, Sales Header, Sales Shipment Header, Sales Invoice Header
        TempTrackingSpecBuffer.DeleteAll;
        case SourceType of
            DATABASE::"Purchase Header":
                RetrieveTrackingPurchase(TempTrackingSpecBuffer, SourceID, SourceSubType);
            DATABASE::"Sales Header":
                RetrieveTrackingSales(TempTrackingSpecBuffer, SourceID, SourceSubType);
            DATABASE::"Service Header":
                RetrieveTrackingService(TempTrackingSpecBuffer, SourceID, SourceSubType);
            DATABASE::"Purch. Rcpt. Header":
                RetrieveTrackingPurchaseReceipt(TempTrackingSpecBuffer, SourceID);
            DATABASE::"Sales Shipment Header":
                RetrieveTrackingSalesShipment(TempTrackingSpecBuffer, SourceID);
            DATABASE::"Sales Invoice Header":
                RetrieveTrackingSalesInvoice(TempTrackingSpecBuffer, SourceID);
            DATABASE::"Sales Cr.Memo Header":
                RetrieveTrackingSalesCrMemoHeader(TempTrackingSpecBuffer, SourceID);
            DATABASE::"Purch. Inv. Header":
                RetrieveTrackingPurhInvHeader(TempTrackingSpecBuffer, SourceID);
            DATABASE::"Purch. Cr. Memo Hdr.":
                RetrieveTrackingPurchCrMemoHeader(TempTrackingSpecBuffer, SourceID);
            DATABASE::"Service Shipment Header":
                RetrieveTrackingServiceShipment(TempTrackingSpecBuffer, SourceID);
            DATABASE::"Service Invoice Header":
                RetrieveTrackingServiceInvoice(TempTrackingSpecBuffer, SourceID);
            else begin
                    OnRetrieveDocumentItemTracking(TempTrackingSpecBuffer, SourceID, Found, SourceType, SourceSubType);
                    if not Found then
                        Error(TableNotSupportedErr, SourceType);
                end;
        end;
        TempTrackingSpecBuffer.Reset;
        exit(TempTrackingSpecBuffer.Count);
    end;

    procedure RetrieveEntriesFromShptRcpt(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; Type: Integer; Subtype: Integer; ID: Code[20]; BatchName: Code[10]; ProdOrderLine: Integer; RefNo: Integer)
    var
        ItemEntryRelation: Record "Item Entry Relation";
        ItemLedgEntry: Record "Item Ledger Entry";
        SignFactor: Integer;
    begin
        // retrieves a data set of Item Ledger Entries (Posted Shipments/Receipts)
        ItemEntryRelation.SetCurrentKey("Source ID", "Source Type");
        ItemEntryRelation.SetRange("Source Type", Type);
        ItemEntryRelation.SetRange("Source Subtype", Subtype);
        ItemEntryRelation.SetRange("Source ID", ID);
        ItemEntryRelation.SetRange("Source Batch Name", BatchName);
        ItemEntryRelation.SetRange("Source Prod. Order Line", ProdOrderLine);
        ItemEntryRelation.SetRange("Source Ref. No.", RefNo);
        if ItemEntryRelation.FindSet then begin
            SignFactor := TableSignFactor(Type);
            repeat
                ItemLedgEntry.Get(ItemEntryRelation."Item Entry No.");
                TempItemLedgEntry := ItemLedgEntry;
                AddTempRecordToSet(TempItemLedgEntry, SignFactor);
            until ItemEntryRelation.Next = 0;
        end;
    end;

    local procedure RetrieveEntriesFromPostedInv(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; InvoiceRowID: Text[250])
    var
        ValueEntryRelation: Record "Value Entry Relation";
        ValueEntry: Record "Value Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        SignFactor: Integer;
    begin
        // retrieves a data set of Item Ledger Entries (Posted Invoices)
        ValueEntryRelation.SetCurrentKey("Source RowId");
        ValueEntryRelation.SetRange("Source RowId", InvoiceRowID);
        if ValueEntryRelation.Find('-') then begin
            SignFactor := TableSignFactor2(InvoiceRowID);
            repeat
                ValueEntry.Get(ValueEntryRelation."Value Entry No.");
                if ValueEntry."Item Ledger Entry Type" in
                   [ValueEntry."Item Ledger Entry Type"::Purchase,
                    ValueEntry."Item Ledger Entry Type"::Sale,
                    ValueEntry."Item Ledger Entry Type"::"Positive Adjmt.",
                    ValueEntry."Item Ledger Entry Type"::"Negative Adjmt."]
                then begin
                    ItemLedgEntry.Get(ValueEntry."Item Ledger Entry No.");
                    TempItemLedgEntry := ItemLedgEntry;
                    TempItemLedgEntry.Quantity := ValueEntry."Invoiced Quantity";
                    OnRetrieveEntriesFromPostedInvOnBeforeAddTempRecordToSet(TempItemLedgEntry, ValueEntry);
                    if TempItemLedgEntry.Quantity <> 0 then
                        AddTempRecordToSet(TempItemLedgEntry, SignFactor);
                end;
            until ValueEntryRelation.Next = 0;
        end;
    end;

    local procedure RetrieveTrackingPurchase(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; SourceID: Code[20]; SourceSubType: Option)
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        Descr: Text[100];
    begin
        PurchaseLine.SetRange("Document Type", SourceSubType);
        PurchaseLine.SetRange("Document No.", SourceID);
        if not PurchaseLine.IsEmpty then begin
            PurchaseLine.FindSet;
            repeat
                if (PurchaseLine.Type = PurchaseLine.Type::Item) and
                   (PurchaseLine."Quantity (Base)" <> 0)
                then begin
                    if Item.Get(PurchaseLine."No.") then
                        Descr := Item.Description;
                    FindReservEntries(TempTrackingSpecBuffer, DATABASE::"Purchase Line", PurchaseLine."Document Type",
                      PurchaseLine."Document No.", '', 0, PurchaseLine."Line No.", Descr);
                    FindTrackingEntries(TempTrackingSpecBuffer, DATABASE::"Purchase Line", PurchaseLine."Document Type",
                      PurchaseLine."Document No.", '', 0, PurchaseLine."Line No.", Descr);
                end;
            until PurchaseLine.Next = 0;
        end;
    end;

    local procedure RetrieveTrackingPurchaseReceipt(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; SourceID: Code[20])
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        Item: Record Item;
        Descr: Text[100];
    begin
        PurchRcptLine.SetRange("Document No.", SourceID);
        if PurchRcptLine.FindSet then begin
            repeat
                if (PurchRcptLine.Type = PurchRcptLine.Type::Item) and
                   (PurchRcptLine."No." <> '') and
                   (PurchRcptLine."Quantity (Base)" <> 0)
                then begin
                    if Item.Get(PurchRcptLine."No.") then
                        Descr := Item.Description;
                    FindShptRcptEntries(
                      TempTrackingSpecBuffer,
                      DATABASE::"Purch. Rcpt. Line", 0, PurchRcptLine."Document No.", '', 0, PurchRcptLine."Line No.", Descr);
                end;
            until PurchRcptLine.Next = 0;
        end;
    end;

    local procedure RetrieveTrackingSales(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; SourceID: Code[20]; SourceSubType: Option)
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        Descr: Text[100];
    begin
        SalesLine.SetRange("Document Type", SourceSubType);
        SalesLine.SetRange("Document No.", SourceID);
        if not SalesLine.IsEmpty then begin
            SalesLine.FindSet;
            repeat
                if (SalesLine.Type = SalesLine.Type::Item) and
                   (SalesLine."No." <> '') and
                   (SalesLine."Quantity (Base)" <> 0)
                then begin
                    if Item.Get(SalesLine."No.") then
                        Descr := Item.Description;
                    FindReservEntries(TempTrackingSpecBuffer, DATABASE::"Sales Line", SalesLine."Document Type",
                      SalesLine."Document No.", '', 0, SalesLine."Line No.", Descr);
                    FindTrackingEntries(TempTrackingSpecBuffer, DATABASE::"Sales Line", SalesLine."Document Type",
                      SalesLine."Document No.", '', 0, SalesLine."Line No.", Descr);
                end;
            until SalesLine.Next = 0;
        end;
    end;

    local procedure RetrieveTrackingService(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; SourceID: Code[20]; SourceSubType: Option)
    var
        ServLine: Record "Service Line";
        Item: Record Item;
        Descr: Text[100];
    begin
        ServLine.SetRange("Document Type", SourceSubType);
        ServLine.SetRange("Document No.", SourceID);
        if not ServLine.IsEmpty then begin
            ServLine.FindSet;
            repeat
                if (ServLine.Type = ServLine.Type::Item) and
                   (ServLine."No." <> '') and
                   (ServLine."Quantity (Base)" <> 0)
                then begin
                    if Item.Get(ServLine."No.") then
                        Descr := Item.Description;
                    FindReservEntries(TempTrackingSpecBuffer, DATABASE::"Service Line", ServLine."Document Type",
                      ServLine."Document No.", '', 0, ServLine."Line No.", Descr);
                    FindTrackingEntries(TempTrackingSpecBuffer, DATABASE::"Service Line", ServLine."Document Type",
                      ServLine."Document No.", '', 0, ServLine."Line No.", Descr);
                end;
            until ServLine.Next = 0;
        end;
    end;

    local procedure RetrieveTrackingSalesShipment(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; SourceID: Code[20])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        Item: Record Item;
        PostedAsmHeader: Record "Posted Assembly Header";
        PostedAsmLine: Record "Posted Assembly Line";
        Descr: Text[100];
    begin
        SalesShipmentLine.SetRange("Document No.", SourceID);
        if not SalesShipmentLine.IsEmpty then begin
            SalesShipmentLine.FindSet;
            repeat
                if (SalesShipmentLine.Type = SalesShipmentLine.Type::Item) and
                   (SalesShipmentLine."No." <> '') and
                   (SalesShipmentLine."Quantity (Base)" <> 0)
                then begin
                    if Item.Get(SalesShipmentLine."No.") then
                        Descr := Item.Description;
                    FindShptRcptEntries(TempTrackingSpecBuffer,
                      DATABASE::"Sales Shipment Line", 0, SalesShipmentLine."Document No.", '', 0, SalesShipmentLine."Line No.", Descr);
                    if RetrieveAsmItemTracking then
                        if SalesShipmentLine.AsmToShipmentExists(PostedAsmHeader) then begin
                            PostedAsmLine.SetRange("Document No.", PostedAsmHeader."No.");
                            if PostedAsmLine.FindSet then
                                repeat
                                    Descr := PostedAsmLine.Description;
                                    FindShptRcptEntries(TempTrackingSpecBuffer,
                                      DATABASE::"Posted Assembly Line", 0, PostedAsmLine."Document No.", '', 0, PostedAsmLine."Line No.", Descr);
                                until PostedAsmLine.Next = 0;
                        end;
                end;
            until SalesShipmentLine.Next = 0;
        end;
    end;

    local procedure RetrieveTrackingSalesInvoice(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; SourceID: Code[20])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        Item: Record Item;
        Descr: Text[100];
    begin
        SalesInvoiceLine.SetRange("Document No.", SourceID);
        if not SalesInvoiceLine.IsEmpty then begin
            SalesInvoiceLine.FindSet;
            repeat
                if (SalesInvoiceLine.Type = SalesInvoiceLine.Type::Item) and
                   (SalesInvoiceLine."No." <> '') and
                   (SalesInvoiceLine."Quantity (Base)" <> 0)
                then begin
                    if Item.Get(SalesInvoiceLine."No.") then
                        Descr := Item.Description;
                    FindInvoiceEntries(TempTrackingSpecBuffer,
                      DATABASE::"Sales Invoice Line", 0, SalesInvoiceLine."Document No.", '', 0, SalesInvoiceLine."Line No.", Descr);
                end;
            until SalesInvoiceLine.Next = 0;
        end;
    end;

    local procedure RetrieveTrackingSalesCrMemoHeader(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; SourceID: Code[20])
    var
        SalesCrMLine: Record "Sales Cr.Memo Line";
        Item: Record Item;
        Descr: Text[100];
    begin
        SalesCrMLine.SetRange("Document No.", SourceID);
        if not SalesCrMLine.IsEmpty then begin
            SalesCrMLine.FindSet;
            repeat
                if (SalesCrMLine.Type = SalesCrMLine.Type::Item) and
                   (SalesCrMLine."No." <> '') and
                   (SalesCrMLine."Quantity (Base)" <> 0)
                then begin
                    if Item.Get(SalesCrMLine."No.") then
                        Descr := Item.Description;
                    FindInvoiceEntries(TempTrackingSpecBuffer,
                      DATABASE::"Sales Cr.Memo Line", 0, SalesCrMLine."Document No.", '', 0, SalesCrMLine."Line No.", Descr);
                end;
            until SalesCrMLine.Next = 0;
        end;
    end;

    local procedure RetrieveTrackingPurhInvHeader(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; SourceID: Code[20])
    var
        PurchInvLine: Record "Purch. Inv. Line";
        Item: Record Item;
        Descr: Text[100];
    begin
        PurchInvLine.SetRange("Document No.", SourceID);
        if not PurchInvLine.IsEmpty then begin
            PurchInvLine.FindSet;
            repeat
                if (PurchInvLine.Type = PurchInvLine.Type::Item) and
                   (PurchInvLine."No." <> '') and
                   (PurchInvLine."Quantity (Base)" <> 0)
                then begin
                    if Item.Get(PurchInvLine."No.") then
                        Descr := Item.Description;
                    FindInvoiceEntries(TempTrackingSpecBuffer,
                      DATABASE::"Purch. Inv. Line", 0, PurchInvLine."Document No.", '', 0, PurchInvLine."Line No.", Descr);
                end;
            until PurchInvLine.Next = 0;
        end;
    end;

    local procedure RetrieveTrackingPurchCrMemoHeader(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; SourceID: Code[20])
    var
        PurchCrMLine: Record "Purch. Cr. Memo Line";
        Item: Record Item;
        Descr: Text[100];
    begin
        PurchCrMLine.SetRange("Document No.", SourceID);
        if not PurchCrMLine.IsEmpty then begin
            PurchCrMLine.FindSet;
            repeat
                if (PurchCrMLine.Type = PurchCrMLine.Type::Item) and
                   (PurchCrMLine."No." <> '') and
                   (PurchCrMLine."Quantity (Base)" <> 0)
                then begin
                    if Item.Get(PurchCrMLine."No.") then
                        Descr := Item.Description;
                    FindInvoiceEntries(TempTrackingSpecBuffer,
                      DATABASE::"Purch. Cr. Memo Line", 0, PurchCrMLine."Document No.", '', 0, PurchCrMLine."Line No.", Descr);
                end;
            until PurchCrMLine.Next = 0;
        end;
    end;

    local procedure RetrieveTrackingServiceShipment(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; SourceID: Code[20])
    var
        ServShptLine: Record "Service Shipment Line";
        Item: Record Item;
        Descr: Text[100];
    begin
        ServShptLine.SetRange("Document No.", SourceID);
        if not ServShptLine.IsEmpty then begin
            ServShptLine.FindSet;
            repeat
                if (ServShptLine.Type = ServShptLine.Type::Item) and
                   (ServShptLine."No." <> '') and
                   (ServShptLine."Quantity (Base)" <> 0)
                then begin
                    if Item.Get(ServShptLine."No.") then
                        Descr := Item.Description;
                    FindShptRcptEntries(TempTrackingSpecBuffer,
                      DATABASE::"Service Shipment Line", 0, ServShptLine."Document No.", '', 0, ServShptLine."Line No.", Descr);
                end;
            until ServShptLine.Next = 0;
        end;
    end;

    local procedure RetrieveTrackingServiceInvoice(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; SourceID: Code[20])
    var
        ServInvLine: Record "Service Invoice Line";
        Item: Record Item;
        Descr: Text[100];
    begin
        ServInvLine.SetRange("Document No.", SourceID);
        if not ServInvLine.IsEmpty then begin
            ServInvLine.FindSet;
            repeat
                if (ServInvLine.Type = ServInvLine.Type::Item) and
                   (ServInvLine."No." <> '') and
                   (ServInvLine."Quantity (Base)" <> 0)
                then begin
                    if Item.Get(ServInvLine."No.") then
                        Descr := Item.Description;
                    FindInvoiceEntries(TempTrackingSpecBuffer,
                      DATABASE::"Service Invoice Line", 0, ServInvLine."Document No.", '', 0, ServInvLine."Line No.", Descr);
                end;
            until ServInvLine.Next = 0;
        end;
    end;

    procedure SetRetrieveAsmItemTracking(RetrieveAsmItemTracking2: Boolean)
    begin
        RetrieveAsmItemTracking := RetrieveAsmItemTracking2;
    end;

    procedure ShowItemTrackingForInvoiceLine(InvoiceRowID: Text[250]): Boolean
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
    begin
        RetrieveEntriesFromPostedInv(TempItemLedgEntry, InvoiceRowID);
        if not TempItemLedgEntry.IsEmpty then begin
            PAGE.RunModal(PAGE::"Posted Item Tracking Lines", TempItemLedgEntry);
            exit(true);
        end;
        exit(false);
    end;

    procedure ShowItemTrackingForMasterData(SourceType: Option " ",Customer,Vendor,Item; SourceNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[20]; SerialNo: Code[50]; LotNo: Code[50]; CDNo: Code[30]; LocationCode: Code[10])
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        Item: Record Item;
        Window: Dialog;
    begin
        // Used when calling Item Tracking from Item, Stockkeeping Unit, Customer, Vendor and information card:
        Window.Open(CountingRecordsMsg);

        if SourceNo <> '' then begin
            ItemLedgEntry.SetCurrentKey("Source Type", "Source No.", "Item No.", "Variant Code");
            ItemLedgEntry.SetRange("Source No.", SourceNo);
            ItemLedgEntry.SetRange("Source Type", SourceType);
        end else
            ItemLedgEntry.SetCurrentKey("Item No.", Open, "Variant Code");

        if LocationCode <> '' then
            ItemLedgEntry.SetRange("Location Code", LocationCode);

        if ItemNo <> '' then begin
            Item.Get(ItemNo);
            Item.TestField("Item Tracking Code");
            ItemLedgEntry.SetRange("Item No.", ItemNo);
        end;
        if SourceType = 0 then
            ItemLedgEntry.SetRange("Variant Code", VariantCode);
        if SerialNo <> '' then
            ItemLedgEntry.SetRange("Serial No.", SerialNo);
        if LotNo <> '' then
            ItemLedgEntry.SetRange("Lot No.", LotNo);
        if CDNo <> '' then
            ItemLedgEntry.SetRange("CD No.", CDNo);

        if ItemLedgEntry.FindSet then
            repeat
                if ItemLedgEntry.TrackingExists then begin
                    TempItemLedgEntry := ItemLedgEntry;
                    TempItemLedgEntry.Insert;
                end
            until ItemLedgEntry.Next = 0;
        Window.Close;
        PAGE.RunModal(PAGE::"Item Tracking Entries", TempItemLedgEntry);
    end;

    procedure ShowItemTrackingForProdOrderComp(Type: Integer; ID: Code[20]; ProdOrderLine: Integer; RefNo: Integer): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        Window: Dialog;
    begin
        Window.Open(CountingRecordsMsg);
        ItemLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.",
          "Entry Type", "Prod. Order Comp. Line No.");
        ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type"::Production);
        ItemLedgEntry.SetRange("Order No.", ID);
        ItemLedgEntry.SetRange("Order Line No.", ProdOrderLine);
        case Type of
            DATABASE::"Prod. Order Line":
                begin
                    ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Output);
                    ItemLedgEntry.SetRange("Prod. Order Comp. Line No.", 0);
                end;
            DATABASE::"Prod. Order Component":
                begin
                    ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Consumption);
                    ItemLedgEntry.SetRange("Prod. Order Comp. Line No.", RefNo);
                end;
            else
                exit(false);
        end;
        if ItemLedgEntry.FindSet then
            repeat
                if ItemLedgEntry.TrackingExists then begin
                    TempItemLedgEntry := ItemLedgEntry;
                    TempItemLedgEntry.Insert;
                end
            until ItemLedgEntry.Next = 0;
        Window.Close;
        if TempItemLedgEntry.IsEmpty then
            exit(false);

        PAGE.RunModal(PAGE::"Posted Item Tracking Lines", TempItemLedgEntry);
        exit(true);
    end;

    procedure ShowItemTrackingForShptRcptLine(Type: Integer; Subtype: Integer; ID: Code[20]; BatchName: Code[10]; ProdOrderLine: Integer; RefNo: Integer): Boolean
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
    begin
        RetrieveEntriesFromShptRcpt(TempItemLedgEntry, Type, Subtype, ID, BatchName, ProdOrderLine, RefNo);
        if not TempItemLedgEntry.IsEmpty then begin
            PAGE.RunModal(PAGE::"Posted Item Tracking Lines", TempItemLedgEntry);
            exit(true);
        end;
        exit(false);
    end;

    local procedure TableSignFactor(TableNo: Integer): Integer
    begin
        if TableNo in [
                       DATABASE::"Sales Line",
                       DATABASE::"Sales Shipment Line",
                       DATABASE::"Sales Invoice Line",
                       DATABASE::"Purch. Cr. Memo Line",
                       DATABASE::"Prod. Order Component",
                       DATABASE::"Transfer Shipment Line",
                       DATABASE::"Return Shipment Line",
                       DATABASE::"Item Shipment Line",
                       DATABASE::"Planning Component",
                       DATABASE::"Posted Assembly Line",
                       DATABASE::"Service Line",
                       DATABASE::"Service Shipment Line",
                       DATABASE::"Service Invoice Line"]
        then
            exit(-1);

        exit(1);
    end;

    local procedure TableSignFactor2(RowID: Text[250]): Integer
    var
        TableNo: Integer;
    begin
        RowID := DelChr(RowID, '<', '"');
        RowID := CopyStr(RowID, 1, StrPos(RowID, '"') - 1);
        if Evaluate(TableNo, RowID) then
            exit(TableSignFactor(TableNo));

        exit(1);
    end;

    [Scope('OnPrem')]
    procedure CreateTrackingInfo(TableID: Integer; DocumentType: Integer; DocumentNo: Code[20])
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        SerialNoInfo: Record "Serial No. Information";
        LotNoInfo: Record "Lot No. Information";
        CDNoInfo: Record "CD No. Information";
        CDTrackingSetup: Record "CD Tracking Setup";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        Inbound: Boolean;
    begin
        RetrieveDocumentItemTracking(TempTrackingSpecification, DocumentNo, TableID, DocumentType);

        Inbound := TableSignFactor(DocumentType) > 0;
        with TempTrackingSpecification do
            if FindSet then
                repeat
                    Item.Get("Item No.");
                    ItemTrackingCode.Get(Item."Item Tracking Code");
                    if ((Inbound and ItemTrackingCode."SN Info. Inbound Must Exist") or
                        (not Inbound and ItemTrackingCode."SN Info. Outbound Must Exist")) and ("Serial No." <> '')
                    then
                        if not SerialNoInfo.Get("Item No.", "Variant Code", "Serial No.") then begin
                            SerialNoInfo.Init;
                            SerialNoInfo."Item No." := "Item No.";
                            SerialNoInfo."Variant Code" := "Variant Code";
                            SerialNoInfo."Serial No." := "Serial No.";
                            SerialNoInfo.Insert;
                        end;
                    if ((Inbound and ItemTrackingCode."Lot Info. Inbound Must Exist") or
                        (not Inbound and ItemTrackingCode."Lot Info. Outbound Must Exist")) and ("Lot No." <> '')
                    then
                        if not LotNoInfo.Get("Item No.", "Variant Code", "Lot No.") then begin
                            LotNoInfo.Init;
                            LotNoInfo."Item No." := "Item No.";
                            LotNoInfo."Variant Code" := "Variant Code";
                            LotNoInfo."Lot No." := "Lot No.";
                            LotNoInfo.Insert;
                        end;
                    if not CDNoInfo.Get(CDNoInfo.Type::Item, "Item No.", "Variant Code", "CD No.") then begin
                        CDNoInfo.Init;
                        CDNoInfo.Type := CDNoInfo.Type::Item;
                        CDNoInfo.Validate("No.", "Item No.");
                        CDNoInfo."Variant Code" := "Variant Code";
                        CDNoInfo."CD No." := "CD No.";
                        CDNoInfo.Insert;
                    end;
                until Next = 0;
    end;

    local procedure CreateLineTrkgFromReservation(ItemNo: Code[20]; LocationCode: Code[10]; Type: Integer; Subtype: Integer; DocNo: Code[20]; LineNo: Integer)
    var
        ReservEntryFor: Record "Reservation Entry";
        ReservEntryFrom: Record "Reservation Entry";
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        SNRequired: Boolean;
        LotRequired: Boolean;
        CDRequired: Boolean;
        SNInfoRequired: Boolean;
        LotInfoRequired: Boolean;
        CDInfoRequired: Boolean;
    begin
        Item.Get(ItemNo);
        if Item."Item Tracking Code" <> '' then begin
            ItemTrackingCode.Code := Item."Item Tracking Code";
            CDTrackingSetup."Item Tracking Code" := Item."Item Tracking Code";
            CDTrackingSetup."Location Code" := LocationCode;
            ItemTrackingMgt.GetItemTrackingSettings(
              ItemTrackingCode, CDTrackingSetup, 0, false,
              SNRequired, LotRequired, CDRequired, SNInfoRequired, LotInfoRequired, CDInfoRequired);
            if SNRequired or LotRequired or CDRequired then begin
                ReservEntryFor.Reset;
                ReservEntryFor.SetSourceFilter(Type, Subtype, DocNo, LineNo, true);
                if ReservEntryFor.FindSet then
                    repeat
                        ReservEntryFrom.Get(ReservEntryFor."Entry No.", not ReservEntryFor.Positive);
                        ReservEntryFor."Serial No." := ReservEntryFrom."Serial No.";
                        ReservEntryFor."Lot No." := ReservEntryFrom."Lot No.";
                        ReservEntryFor."CD No." := ReservEntryFrom."CD No.";
                        ReservEntryFor.UpdateItemTracking;
                        ReservEntryFor.Modify;
                    until ReservEntryFor.Next = 0;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure CopyDocTrkgFromReservation(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; HideDialog: Boolean)
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        CDTrackingSetup: Record "CD Tracking Setup";
        TransLine: Record "Transfer Line";
        ItemDocLine: Record "Item Document Line";
        SNRequired: Boolean;
        LotRequired: Boolean;
        CDRequired: Boolean;
        SNInfoRequired: Boolean;
        LotInfoRequired: Boolean;
        CDInfoRequired: Boolean;
    begin
        if not HideDialog then
            if not Confirm(CreateTrackingSpecQst, true) then
                exit;

        case SourceType of
            DATABASE::"Sales Header":
                begin
                    SalesLine.SetRange("Document Type", SourceSubtype);
                    SalesLine.SetRange("Document No.", SourceID);
                    SalesLine.SetRange(Type, SalesLine.Type::Item);
                    if SalesLine.FindSet then
                        repeat
                            CreateLineTrkgFromReservation(
                              SalesLine."No.", SalesLine."Location Code", DATABASE::"Sales Line",
                              SourceSubtype, SourceID, SalesLine."Line No.");
                        until SalesLine.Next = 0;
                end;
            DATABASE::"Transfer Header":
                begin
                    TransLine.SetRange("Document No.", SourceID);
                    if TransLine.FindSet then
                        repeat
                            if SourceSubtype = 0 then
                                CreateLineTrkgFromReservation(
                                  TransLine."Item No.", TransLine."Transfer-from Code", DATABASE::"Transfer Line",
                                  SourceSubtype, SourceID, TransLine."Line No.")
                            else
                                CreateLineTrkgFromReservation(
                                  TransLine."Item No.", TransLine."Transfer-to Code", DATABASE::"Transfer Line",
                                  SourceSubtype, SourceID, TransLine."Line No.")
                        until TransLine.Next = 0;
                end;
            DATABASE::"Item Document Header":
                begin
                    ItemDocLine.SetRange("Document No.", SourceID);
                    if ItemDocLine.FindSet then
                        repeat
                            CreateLineTrkgFromReservation(
                              ItemDocLine."Item No.", ItemDocLine."Location Code", DATABASE::"Item Document Line",
                              SourceSubtype, SourceID, ItemDocLine."Line No.");
                        until ItemDocLine.Next = 0;
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddTempRecordToSet(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; var TempItemLedgerEntry2: Record "Item Ledger Entry" temporary; SignFactor: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillTrackingSpecBufferFromItemLedgEntry(var TempTrackingSpecification: Record "Tracking Specification" temporary; var TempItemLedgerEntry: Record "Item Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillTrackingSpecBufferFromReservEntry(var TempTrackingSpecification: Record "Tracking Specification" temporary; var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillTrackingSpecBufferFromTrackingEntries(var TempTrackingSpecification: Record "Tracking Specification" temporary; var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveDocumentItemTracking(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; SourceID: Code[20]; var Found: Boolean; SourceType: Integer; SourceSubType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveEntriesFromPostedInvOnBeforeAddTempRecordToSet(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; ValueEntry: Record "Value Entry")
    begin
    end;
}

