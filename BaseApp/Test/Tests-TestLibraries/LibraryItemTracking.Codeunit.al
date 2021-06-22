codeunit 130502 "Library - Item Tracking"
{
    // Unsupported version tags:
    // NA: Unable to Compile

    Permissions = TableData "Whse. Item Tracking Line" = rimd;

    trigger OnRun()
    begin
    end;

    var
        Text001: Label 'Not implemented. Source Type = %1.';
        Text002: Label 'Qty Base for Serial No. %1 is %2.';
        Text031: Label 'You cannot define item tracking on this line because it is linked to production order %1.';
        Text048: Label 'You cannot use item tracking on a %1 created from a %2.';
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";

    procedure AddSerialNoTrackingInfo(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        CreateItemTrackingCode(ItemTrackingCode, true, false);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        Item.Modify(true);
    end;

    procedure AddLotNoTrackingInfo(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        CreateItemTrackingCode(ItemTrackingCode, false, true);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode);
        Item.Modify(true);
    end;

    procedure CreateAssemblyHeaderItemTracking(var ReservEntry: Record "Reservation Entry"; AssemblyHeader: Record "Assembly Header"; SerialNo: Code[50]; LotNo: Code[50]; QtyBase: Decimal)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(AssemblyHeader);
        ItemTracking(ReservEntry, RecRef, SerialNo, LotNo, QtyBase);
    end;

    procedure CreateAssemblyLineItemTracking(var ReservEntry: Record "Reservation Entry"; AssemblyLine: Record "Assembly Line"; SerialNo: Code[50]; LotNo: Code[50]; QtyBase: Decimal)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(AssemblyLine);
        ItemTracking(ReservEntry, RecRef, SerialNo, LotNo, QtyBase);
    end;

    procedure CreateItemJournalLineItemTracking(var ReservEntry: Record "Reservation Entry"; ItemJournalLine: Record "Item Journal Line"; SerialNo: Code[50]; LotNo: Code[50]; QtyBase: Decimal)
    var
        RecRef: RecordRef;
    begin
        if ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::Transfer then // cannot create this type from UI
            Error(Text001, RecRef.Number);
        RecRef.GetTable(ItemJournalLine);
        ItemTracking(ReservEntry, RecRef, SerialNo, LotNo, QtyBase);
    end;

    procedure CreateItemTrackingCodeWithExpirationDate(var ItemTrackingCode: Record "Item Tracking Code"; SNSpecific: Boolean; LNSpecific: Boolean)
    begin
        CreateItemTrackingCode(ItemTrackingCode, SNSpecific, LNSpecific);
        ItemTrackingCode.Validate("Use Expiration Dates", true);
        ItemTrackingCode.Modify();
    end;

    procedure CreateItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code"; SNSpecific: Boolean; LNSpecific: Boolean)
    begin
        Clear(ItemTrackingCode);
        ItemTrackingCode.Validate(Code,
          LibraryUtility.GenerateRandomCode(ItemTrackingCode.FieldNo(Code), DATABASE::"Item Tracking Code"));
        ItemTrackingCode.Validate("SN Specific Tracking", SNSpecific);
        ItemTrackingCode.Validate("Lot Specific Tracking", LNSpecific);
        ItemTrackingCode.Insert(true);
    end;

    procedure CreateLotItem(var Item: Record Item): Code[20]
    begin
        LibraryInventory.CreateItem(Item);
        AddLotNoTrackingInfo(Item);
        exit(Item."No.");
    end;

    procedure CreateLotNoInformation(var LotNoInformation: Record "Lot No. Information"; ItemNo: Code[20]; VariantCode: Code[10]; LotNo: Code[50])
    begin
        Clear(LotNoInformation);
        LotNoInformation.Init();
        LotNoInformation.Validate("Item No.", ItemNo);
        LotNoInformation.Validate("Variant Code", VariantCode);
        LotNoInformation.Validate("Lot No.", LotNo);
        LotNoInformation.Insert(true);
    end;

    procedure CreatePlanningWkshItemTracking(var ReservEntry: Record "Reservation Entry"; ReqLine: Record "Requisition Line"; SerialNo: Code[50]; LotNo: Code[50]; QtyBase: Decimal)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(ReqLine);
        ItemTracking(ReservEntry, RecRef, SerialNo, LotNo, QtyBase);
    end;

    procedure CreateProdOrderItemTracking(var ReservEntry: Record "Reservation Entry"; ProdOrderLine: Record "Prod. Order Line"; SerialNo: Code[50]; LotNo: Code[50]; QtyBase: Decimal)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(ProdOrderLine);
        ItemTracking(ReservEntry, RecRef, SerialNo, LotNo, QtyBase);
    end;

    procedure CreateProdOrderCompItemTracking(var ReservEntry: Record "Reservation Entry"; ProdOrderComp: Record "Prod. Order Component"; SerialNo: Code[50]; LotNo: Code[50]; QtyBase: Decimal)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(ProdOrderComp);
        ItemTracking(ReservEntry, RecRef, SerialNo, LotNo, QtyBase);
    end;

    procedure CreatePurchOrderItemTracking(var ReservEntry: Record "Reservation Entry"; PurchLine: Record "Purchase Line"; SerialNo: Code[50]; LotNo: Code[50]; QtyBase: Decimal)
    var
        RecRef: RecordRef;
    begin
        if PurchLine."Document Type" = PurchLine."Document Type"::"Blanket Order" then // cannot create IT for this line from UI
            Error(Text001, RecRef.Number);
        RecRef.GetTable(PurchLine);
        ItemTracking(ReservEntry, RecRef, SerialNo, LotNo, QtyBase);
    end;

    procedure CreateReqWkshItemTracking(var ReservEntry: Record "Reservation Entry"; ReqLine: Record "Requisition Line"; SerialNo: Code[50]; LotNo: Code[50]; QtyBase: Decimal)
    begin
        CreatePlanningWkshItemTracking(ReservEntry, ReqLine, SerialNo, LotNo, QtyBase);
    end;

    procedure CreateSalesOrderItemTracking(var ReservEntry: Record "Reservation Entry"; SalesLine: Record "Sales Line"; SerialNo: Code[50]; LotNo: Code[50]; QtyBase: Decimal)
    var
        RecRef: RecordRef;
    begin
        if SalesLine."Document Type" = SalesLine."Document Type"::"Blanket Order" then // cannot create IT for this line from UI
            Error(Text001, RecRef.Number);
        RecRef.GetTable(SalesLine);
        ItemTracking(ReservEntry, RecRef, SerialNo, LotNo, QtyBase);
    end;

    procedure CreateSerialItem(var Item: Record Item): Code[20]
    begin
        LibraryInventory.CreateItem(Item);
        AddSerialNoTrackingInfo(Item);
        exit(Item."No.");
    end;

    procedure CreateSerialNoInformation(var SerialNoInformation: Record "Serial No. Information"; ItemNo: Code[20]; VariantCode: Code[10]; SerialNo: Code[50])
    begin
        Clear(SerialNoInformation);
        SerialNoInformation.Init();
        SerialNoInformation.Validate("Item No.", ItemNo);
        SerialNoInformation.Validate("Variant Code", VariantCode);
        SerialNoInformation.Validate("Serial No.", SerialNo);
        SerialNoInformation.Insert(true);
    end;

    procedure CreateTransferOrderItemTracking(var ReservEntry: Record "Reservation Entry"; TransferLine: Record "Transfer Line"; SerialNo: Code[50]; LotNo: Code[50]; QtyBase: Decimal)
    var
        RecRef: RecordRef;
    begin
        // Only creates IT lines for Transfer order shipment! IT lines for receipt cannot be added in form.
        // Note that the ReservEntry returned has two lines - one for TRANSFER-FROM and one for TRANSFER-TO
        RecRef.GetTable(TransferLine);
        ItemTracking(ReservEntry, RecRef, SerialNo, LotNo, QtyBase);
    end;

    procedure CreateWhseInvtPickItemTracking(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseInternalPickLine: Record "Whse. Internal Pick Line"; SerialNo: Code[50]; LotNo: Code[50]; QtyBase: Decimal)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(WhseInternalPickLine);
        WhseItemTracking(WhseItemTrackingLine, RecRef, SerialNo, LotNo, QtyBase);
    end;

    procedure CreateWhseInvtPutawayItemTracking(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line"; SerialNo: Code[50]; LotNo: Code[50]; QtyBase: Decimal)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(WhseInternalPutAwayLine);
        WhseItemTracking(WhseItemTrackingLine, RecRef, SerialNo, LotNo, QtyBase);
    end;

    procedure CreateWhseJournalLineItemTracking(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseJnlLine: Record "Warehouse Journal Line"; SerialNo: Code[50]; LotNo: Code[50]; QtyBase: Decimal)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(WhseJnlLine);
        WhseItemTracking(WhseItemTrackingLine, RecRef, SerialNo, LotNo, QtyBase);
    end;

    procedure CreateWhseReceiptItemTracking(var ReservEntry: Record "Reservation Entry"; WhseRcptLine: Record "Warehouse Receipt Line"; SerialNo: Code[50]; LotNo: Code[50]; QtyBase: Decimal)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(WhseRcptLine);
        ItemTracking(ReservEntry, RecRef, SerialNo, LotNo, QtyBase);
    end;

    procedure CreateWhseShipmentItemTracking(var ReservEntry: Record "Reservation Entry"; WhseShptLine: Record "Warehouse Shipment Line"; SerialNo: Code[50]; LotNo: Code[50]; QtyBase: Decimal)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(WhseShptLine);
        ItemTracking(ReservEntry, RecRef, SerialNo, LotNo, QtyBase);
    end;

    procedure CreateWhseWkshItemTracking(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseWkshLine: Record "Whse. Worksheet Line"; SerialNo: Code[50]; LotNo: Code[50]; QtyBase: Decimal)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(WhseWkshLine);
        WhseItemTracking(WhseItemTrackingLine, RecRef, SerialNo, LotNo, QtyBase);
    end;

    procedure ItemJournal_CalcWhseAdjmnt(var Item: Record Item; NewPostingDate: Date; DocumentNo: Text[20])
    var
        ItemJournalLine: Record "Item Journal Line";
        TmpItem: Record Item;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        CalcWhseAdjmnt: Report "Calculate Whse. Adjustment";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        LibraryAssembly: Codeunit "Library - Assembly";
    begin
        LibraryAssembly.SetupItemJournal(ItemJournalTemplate, ItemJournalBatch);
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);

        Commit();
        CalcWhseAdjmnt.SetItemJnlLine(ItemJournalLine);
        if DocumentNo = '' then
            DocumentNo := NoSeriesMgt.GetNextNo(ItemJournalBatch."No. Series", NewPostingDate, false);
        CalcWhseAdjmnt.InitializeRequest(NewPostingDate, DocumentNo);
        if Item.HasFilter then
            TmpItem.CopyFilters(Item)
        else begin
            Item.Get(Item."No.");
            TmpItem.SetRange("No.", Item."No.");
        end;

        CalcWhseAdjmnt.SetTableView(TmpItem);
        CalcWhseAdjmnt.UseRequestPage(false);
        CalcWhseAdjmnt.RunModal;
    end;

    local procedure ItemTracking(var ReservEntry: Record "Reservation Entry"; RecRef: RecordRef; SerialNo: Code[50]; LotNo: Code[50]; QtyBase: Decimal)
    var
        SalesLine: Record "Sales Line";
        PurchLine: Record "Purchase Line";
        AssemblyLine: Record "Assembly Line";
        AssemblyHeader: Record "Assembly Header";
        TransLine: Record "Transfer Line";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderCompLine: Record "Prod. Order Component";
        ItemJournalLine: Record "Item Journal Line";
        ReqLine: Record "Requisition Line";
        WhseShptLine: Record "Warehouse Shipment Line";
        WhseRcptLine: Record "Warehouse Receipt Line";
        Job: Record Job;
        Item: Record Item;
        OutgoingEntryNo: Integer;
        IncomingEntryNo: Integer;
    begin
        SerialNo := DelChr(SerialNo, '<', ' '); // remove leading spaces
        LotNo := DelChr(LotNo, '<', ' '); // remove leading spaces
        case RecRef.Number of
            DATABASE::"Sales Line":
                begin
                    RecRef.SetTable(SalesLine);
                    // COPY FROM TAB 37: OpenItemTrackingLines
                    SalesLine.TestField(Type, SalesLine.Type::Item);
                    SalesLine.TestField("No.");
                    SalesLine.TestField("Quantity (Base)");
                    if SalesLine."Job Contract Entry No." <> 0 then
                        Error(Text048, SalesLine.TableCaption, Job.TableCaption);
                    // COPY END
                    InsertItemTracking(ReservEntry,
                      SalesLine.SignedXX(SalesLine.Quantity) > 0,
                      SalesLine."No.",
                      SalesLine."Location Code",
                      SalesLine."Variant Code",
                      SalesLine.SignedXX(QtyBase),
                      SalesLine."Qty. per Unit of Measure",
                      SerialNo,
                      LotNo,
                      DATABASE::"Sales Line",
                      SalesLine."Document Type".AsInteger(),
                      SalesLine."Document No.",
                      '',
                      0,
                      SalesLine."Line No.",
                      SalesLine."Shipment Date");
                end;
            DATABASE::"Purchase Line":
                begin
                    RecRef.SetTable(PurchLine);
                    // COPY FROM TAB 39: OpenItemTrackingLines
                    PurchLine.TestField(Type, PurchLine.Type::Item);
                    PurchLine.TestField("No.");
                    if PurchLine."Prod. Order No." <> '' then
                        Error(Text031, PurchLine."Prod. Order No.");
                    PurchLine.TestField("Quantity (Base)");
                    // COPY END
                    InsertItemTracking(ReservEntry,
                      PurchLine.Signed(PurchLine.Quantity) > 0,
                      PurchLine."No.",
                      PurchLine."Location Code",
                      PurchLine."Variant Code",
                      PurchLine.Signed(QtyBase),
                      PurchLine."Qty. per Unit of Measure",
                      SerialNo,
                      LotNo,
                      DATABASE::"Purchase Line",
                      PurchLine."Document Type".AsInteger(),
                      PurchLine."Document No.",
                      '',
                      0,
                      PurchLine."Line No.",
                      PurchLine."Expected Receipt Date");
                end;
            DATABASE::"Assembly Line":
                begin
                    RecRef.SetTable(AssemblyLine);
                    AssemblyLine.TestField(Type, AssemblyLine.Type::Item);
                    AssemblyLine.TestField("No.");
                    AssemblyLine.TestField("Quantity (Base)");
                    InsertItemTracking(ReservEntry,
                      AssemblyLine.Quantity < 0,
                      AssemblyLine."No.",
                      AssemblyLine."Location Code",
                      AssemblyLine."Variant Code",
                      -QtyBase,
                      AssemblyLine."Qty. per Unit of Measure",
                      SerialNo,
                      LotNo,
                      DATABASE::"Assembly Line",
                      AssemblyLine."Document Type".AsInteger(),
                      AssemblyLine."Document No.",
                      '',
                      0,
                      AssemblyLine."Line No.",
                      AssemblyLine."Due Date");
                end;
            DATABASE::"Assembly Header":
                begin
                    RecRef.SetTable(AssemblyHeader);
                    AssemblyHeader.TestField("Document Type", AssemblyHeader."Document Type"::Order);
                    AssemblyHeader.TestField("Item No.");
                    AssemblyHeader.TestField("Quantity (Base)");
                    InsertItemTracking(ReservEntry,
                      AssemblyHeader.Quantity > 0,
                      AssemblyHeader."Item No.",
                      AssemblyHeader."Location Code",
                      AssemblyHeader."Variant Code",
                      QtyBase,
                      AssemblyHeader."Qty. per Unit of Measure",
                      SerialNo,
                      LotNo,
                      DATABASE::"Assembly Header",
                      AssemblyHeader."Document Type".AsInteger(),
                      AssemblyHeader."No.",
                      '',
                      0,
                      0,
                      AssemblyHeader."Due Date");
                end;
            DATABASE::"Transfer Line":
                begin
                    RecRef.SetTable(TransLine);
                    // COPY FROM TAB 5741: OpenItemTrackingLines
                    TransLine.TestField("Item No.");
                    TransLine.TestField("Quantity (Base)");
                    // COPY END
                    // creates 2 lines- one for Transfer-from and another for Transfer-to
                    // first, outgoing line
                    InsertItemTracking(ReservEntry,
                      false,
                      TransLine."Item No.",
                      TransLine."Transfer-from Code",
                      TransLine."Variant Code",
                      -QtyBase,
                      TransLine."Qty. per Unit of Measure",
                      SerialNo,
                      LotNo,
                      DATABASE::"Transfer Line",
                      0,
                      TransLine."Document No.",
                      '',
                      0,
                      TransLine."Line No.",
                      TransLine."Shipment Date");
                    OutgoingEntryNo := ReservEntry."Entry No.";
                    // next, incoming line
                    InsertItemTracking(ReservEntry,
                      true,
                      TransLine."Item No.",
                      TransLine."Transfer-to Code",
                      TransLine."Variant Code",
                      QtyBase,
                      TransLine."Qty. per Unit of Measure",
                      SerialNo,
                      LotNo,
                      DATABASE::"Transfer Line",
                      1,
                      TransLine."Document No.",
                      '',
                      0,
                      TransLine."Line No.",
                      TransLine."Receipt Date");
                    IncomingEntryNo := ReservEntry."Entry No.";
                    Clear(ReservEntry);
                    ReservEntry.SetFilter("Entry No.", '%1|%2', OutgoingEntryNo, IncomingEntryNo);
                    ReservEntry.FindSet; // returns both entries
                end;
            DATABASE::"Prod. Order Line":
                begin
                    RecRef.SetTable(ProdOrderLine);
                    // COPY FROM COD 99000837: CallItemTracking
                    if ProdOrderLine.Status = ProdOrderLine.Status::Finished then
                        exit;
                    ProdOrderLine.TestField("Item No.");
                    // COPY END
                    InsertItemTracking(ReservEntry,
                      ProdOrderLine.Quantity > 0,
                      ProdOrderLine."Item No.",
                      ProdOrderLine."Location Code",
                      ProdOrderLine."Variant Code",
                      QtyBase,
                      ProdOrderLine."Qty. per Unit of Measure",
                      SerialNo,
                      LotNo,
                      DATABASE::"Prod. Order Line",
                      ProdOrderLine.Status.AsInteger(),
                      ProdOrderLine."Prod. Order No.",
                      '',
                      ProdOrderLine."Line No.",
                      0,
                      ProdOrderLine."Due Date");
                end;
            DATABASE::"Prod. Order Component":
                begin
                    RecRef.SetTable(ProdOrderCompLine);
                    // COPY FROM COD 99000838: CallItemTracking
                    if ProdOrderCompLine.Status = ProdOrderCompLine.Status::Finished then
                        exit;
                    ProdOrderCompLine.TestField("Item No.");
                    // COPY END
                    InsertItemTracking(ReservEntry,
                      ProdOrderCompLine.Quantity < 0,
                      ProdOrderCompLine."Item No.",
                      ProdOrderCompLine."Location Code",
                      ProdOrderCompLine."Variant Code",
                      -QtyBase,
                      ProdOrderCompLine."Qty. per Unit of Measure",
                      SerialNo,
                      LotNo,
                      DATABASE::"Prod. Order Component",
                      ProdOrderCompLine.Status.AsInteger(),
                      ProdOrderCompLine."Prod. Order No.",
                      '',
                      ProdOrderCompLine."Prod. Order Line No.",
                      ProdOrderCompLine."Line No.",
                      ProdOrderCompLine."Due Date");
                end;
            DATABASE::"Item Journal Line":
                begin
                    RecRef.SetTable(ItemJournalLine);
                    InsertItemTracking(ReservEntry,
                      ItemJournalLine.Signed(ItemJournalLine.Quantity) > 0,
                      ItemJournalLine."Item No.",
                      ItemJournalLine."Location Code",
                      ItemJournalLine."Variant Code",
                      ItemJournalLine.Signed(QtyBase),
                      ItemJournalLine."Qty. per Unit of Measure",
                      SerialNo,
                      LotNo,
                      DATABASE::"Item Journal Line",
                      ItemJournalLine."Entry Type".AsInteger(),
                      ItemJournalLine."Journal Template Name",
                      ItemJournalLine."Journal Batch Name",
                      0,
                      ItemJournalLine."Line No.",
                      ItemJournalLine."Posting Date");
                end;
            DATABASE::"Requisition Line":
                begin
                    RecRef.SetTable(ReqLine);
                    // COPY FROM TAB 246: OpenItemTrackingLines
                    ReqLine.TestField(Type, ReqLine.Type::Item);
                    ReqLine.TestField("No.");
                    ReqLine.TestField("Quantity (Base)");
                    // COPY END
                    InsertItemTracking(ReservEntry,
                      ReqLine.Quantity > 0,
                      ReqLine."No.",
                      ReqLine."Location Code",
                      ReqLine."Variant Code",
                      QtyBase,
                      ReqLine."Qty. per Unit of Measure",
                      SerialNo,
                      LotNo,
                      DATABASE::"Requisition Line",
                      0,
                      ReqLine."Worksheet Template Name",
                      ReqLine."Journal Batch Name",
                      ReqLine."Prod. Order Line No.",
                      ReqLine."Line No.",
                      ReqLine."Due Date");
                end;
            DATABASE::"Warehouse Shipment Line":
                begin
                    WhseShptLine.Init();
                    RecRef.SetTable(WhseShptLine);
                    // COPY FROM TAB 7321: OpenItemTrackingLines
                    WhseShptLine.TestField("No.");
                    WhseShptLine.TestField("Qty. (Base)");
                    Item.Get(WhseShptLine."Item No.");
                    Item.TestField("Item Tracking Code");
                    // COPY END
                    case WhseShptLine."Source Type" of
                        DATABASE::"Sales Line":
                            begin
                                if SalesLine.Get(WhseShptLine."Source Subtype", WhseShptLine."Source No.", WhseShptLine."Source Line No.") then
                                    CreateSalesOrderItemTracking(ReservEntry, SalesLine, SerialNo, LotNo, QtyBase);
                            end;
                        DATABASE::"Purchase Line":
                            begin
                                if PurchLine.Get(WhseShptLine."Source Subtype", WhseShptLine."Source No.", WhseShptLine."Source Line No.") then
                                    CreatePurchOrderItemTracking(ReservEntry, PurchLine, SerialNo, LotNo, QtyBase);
                            end;
                        DATABASE::"Transfer Line":
                            begin
                                // Outbound only
                                if TransLine.Get(WhseShptLine."Source No.", WhseShptLine."Source Line No.") then
                                    CreateTransferOrderItemTracking(ReservEntry, TransLine, SerialNo, LotNo, QtyBase);
                            end;
                    end;
                end;
            DATABASE::"Warehouse Receipt Line":
                begin
                    WhseRcptLine.Init();
                    RecRef.SetTable(WhseRcptLine);
                    // COPY FROM TAB 7317: OpenItemTrackingLines
                    WhseRcptLine.TestField("No.");
                    WhseRcptLine.TestField("Qty. (Base)");
                    Item.Get(WhseRcptLine."Item No.");
                    Item.TestField("Item Tracking Code");
                    // COPY END
                    case WhseRcptLine."Source Type" of
                        DATABASE::"Purchase Line":
                            begin
                                if PurchLine.Get(WhseRcptLine."Source Subtype", WhseRcptLine."Source No.", WhseRcptLine."Source Line No.") then
                                    CreatePurchOrderItemTracking(ReservEntry, PurchLine, SerialNo, LotNo, QtyBase);
                            end;
                        DATABASE::"Sales Line":
                            begin
                                if SalesLine.Get(WhseRcptLine."Source Subtype", WhseRcptLine."Source No.", WhseRcptLine."Source Line No.") then
                                    CreateSalesOrderItemTracking(ReservEntry, SalesLine, SerialNo, LotNo, QtyBase);
                            end;
                        DATABASE::"Transfer Line":
                            // Inbound only - not possible to ADD item tracking lines- so throw error
                            Error(Text001, RecRef.Number);
                    end;
                end;
            else
                Error(Text001, RecRef.Number);
        end;
    end;

    local procedure InsertItemTracking(var ReservEntry: Record "Reservation Entry"; Positive2: Boolean; Item: Code[20]; Location: Code[10]; Variant: Code[10]; QtyBase: Decimal; QtyperUOM: Decimal; SerialNo: Code[50]; LotNo: Code[50]; SourceType: Integer; SourceSubType: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer; DueDate: Date)
    var
        SalesLine: Record "Sales Line";
        PurchLine: Record "Purchase Line";
        ItemJnlLine: Record "Item Journal Line";
        LastEntryNo: Integer;
    begin
        if (SerialNo <> '') and (Abs(QtyBase) > 1) then
            Error(Text002, SerialNo, QtyBase);
        Clear(ReservEntry);
        with ReservEntry do begin
            if FindLast then
                LastEntryNo := "Entry No." + 1
            else
                LastEntryNo := 1;
            Init;
            "Entry No." := LastEntryNo;
            Positive := Positive2;
            if (SourceType = DATABASE::"Item Journal Line") or
               ((SourceType = DATABASE::"Prod. Order Line") and (SourceSubType in [0, 1])) or // simulated or planned prod line
               ((SourceType = DATABASE::"Prod. Order Component") and (SourceSubType in [0, 1])) or // simulated or planned prod comp
               (SourceType = DATABASE::"Requisition Line")
            then
                Validate("Reservation Status", "Reservation Status"::Prospect)
            else
                Validate("Reservation Status", "Reservation Status"::Surplus);

            Validate("Item No.", Item);
            Validate("Location Code", Location);
            Validate("Variant Code", Variant);
            Validate("Qty. per Unit of Measure", QtyperUOM);
            Validate("Quantity (Base)", QtyBase);

            case SourceType of
                DATABASE::"Item Journal Line":
                    case "Item Ledger Entry Type".FromInteger(SourceSubType) of
                        ItemJnlLine."Entry Type"::Purchase,
                        ItemJnlLine."Entry Type"::"Positive Adjmt.",
                        ItemJnlLine."Entry Type"::Output:
                            Validate("Expected Receipt Date", DueDate);
                        ItemJnlLine."Entry Type"::Sale,
                        ItemJnlLine."Entry Type"::"Negative Adjmt.",
                        ItemJnlLine."Entry Type"::Consumption:
                            Validate("Shipment Date", DueDate);
                    end;
                DATABASE::"Prod. Order Line",
              DATABASE::"Requisition Line",
              DATABASE::"Prod. Order Component":
                    Validate("Shipment Date", DueDate);
                DATABASE::"Sales Line":
                    case SourceSubType of
                        SalesLine."Document Type"::Order.AsInteger(),
                        SalesLine."Document Type"::Invoice.AsInteger(),
                        SalesLine."Document Type"::Quote.AsInteger():
                            Validate("Shipment Date", DueDate);
                        SalesLine."Document Type"::"Return Order".AsInteger(),
                        SalesLine."Document Type"::"Credit Memo".AsInteger():
                            Validate("Expected Receipt Date", DueDate);
                    end;
                DATABASE::"Purchase Line":
                    case SourceSubType of
                        PurchLine."Document Type"::Order.AsInteger(),
                        PurchLine."Document Type"::Invoice.AsInteger(),
                        PurchLine."Document Type"::Quote.AsInteger():
                            Validate("Expected Receipt Date", DueDate);
                        PurchLine."Document Type"::"Return Order".AsInteger(),
                        PurchLine."Document Type"::"Credit Memo".AsInteger():
                            Validate("Shipment Date", DueDate);
                    end;
                else
                    if Positive2 then
                        Validate("Expected Receipt Date", DueDate)
                    else
                        Validate("Shipment Date", DueDate);
            end;
            Validate("Creation Date", WorkDate);
            "Created By" := UserId;

            if SerialNo <> '' then begin
                Validate("Serial No.", SerialNo);
                if LotNo <> '' then
                    Validate("Item Tracking", "Item Tracking"::"Lot and Serial No.")
                else
                    Validate("Item Tracking", "Item Tracking"::"Serial No.");
            end;
            if LotNo <> '' then begin
                Validate("Lot No.", LotNo);
                if SerialNo <> '' then
                    Validate("Item Tracking", "Item Tracking"::"Lot and Serial No.")
                else
                    Validate("Item Tracking", "Item Tracking"::"Lot No.");
            end;

            Validate("Source Type", SourceType);
            Validate("Source Subtype", SourceSubType);
            Validate("Source ID", SourceID);
            Validate("Source Batch Name", SourceBatchName);
            Validate("Source Prod. Order Line", SourceProdOrderLine);
            Validate("Source Ref. No.", SourceRefNo);

            Insert(true);
        end;
    end;

    local procedure WhseItemTracking(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; RecRef: RecordRef; SerialNo: Code[50]; LotNo: Code[50]; QtyBase: Decimal)
    var
        WhseJnlLine: Record "Warehouse Journal Line";
        WhseWkshLine: Record "Whse. Worksheet Line";
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
        SourceType: Integer;
        SourceID: Code[20];
        SourceBatchName: Code[10];
        SourceRefNo: Integer;
    begin
        SerialNo := DelChr(SerialNo, '<', ' '); // remove leading spaces
        LotNo := DelChr(LotNo, '<', ' '); // remove leading spaces
        case RecRef.Number of
            DATABASE::"Warehouse Journal Line":
                begin
                    WhseJnlLine.Init();
                    RecRef.SetTable(WhseJnlLine);
                    // COPY FROM TAB 7311: OpenItemTrackingLines
                    WhseJnlLine.TestField("Item No.");
                    WhseJnlLine.TestField("Qty. (Base)");
                    // COPY END
                    WhseInsertItemTracking(WhseItemTrackingLine,
                      WhseJnlLine."Item No.",
                      WhseJnlLine."Location Code",
                      WhseJnlLine."Variant Code",
                      QtyBase,
                      WhseJnlLine."Qty. per Unit of Measure",
                      SerialNo,
                      LotNo,
                      DATABASE::"Warehouse Journal Line",
                      0,
                      WhseJnlLine."Journal Batch Name",
                      WhseJnlLine."Journal Template Name",
                      0,
                      WhseJnlLine."Line No.");
                end;
            DATABASE::"Whse. Worksheet Line":
                begin
                    RecRef.SetTable(WhseWkshLine);
                    // COPY FROM TAB 7326: OpenItemTrackingLines
                    WhseWkshLine.TestField("Item No.");
                    WhseWkshLine.TestField("Qty. (Base)");
                    case WhseWkshLine."Whse. Document Type" of
                        WhseWkshLine."Whse. Document Type"::Receipt:
                            begin
                                SourceType := DATABASE::"Posted Whse. Receipt Line";
                                SourceID := WhseWkshLine."Whse. Document No.";
                                SourceBatchName := '';
                                SourceRefNo := WhseWkshLine."Whse. Document Line No.";
                            end;
                        WhseWkshLine."Whse. Document Type"::Shipment:
                            begin
                                SourceType := DATABASE::"Warehouse Shipment Line";
                                SourceID := WhseWkshLine."Whse. Document No.";
                                SourceBatchName := '';
                                SourceRefNo := WhseWkshLine."Whse. Document Line No.";
                            end;
                        WhseWkshLine."Whse. Document Type"::"Internal Put-away":
                            begin
                                SourceType := DATABASE::"Whse. Internal Put-away Line";
                                SourceID := WhseWkshLine."Whse. Document No.";
                                SourceBatchName := '';
                                SourceRefNo := WhseWkshLine."Whse. Document Line No.";
                            end;
                        WhseWkshLine."Whse. Document Type"::"Internal Pick":
                            begin
                                SourceType := DATABASE::"Whse. Internal Pick Line";
                                SourceID := WhseWkshLine."Whse. Document No.";
                                SourceBatchName := '';
                                SourceRefNo := WhseWkshLine."Whse. Document Line No.";
                            end;
                        WhseWkshLine."Whse. Document Type"::Production:
                            begin
                                SourceType := DATABASE::"Prod. Order Component";
                                SourceID := WhseWkshLine."Whse. Document No.";
                                SourceBatchName := '';
                                SourceRefNo := WhseWkshLine."Whse. Document Line No.";
                            end;
                        WhseWkshLine."Whse. Document Type"::Assembly:
                            begin
                                SourceType := DATABASE::"Assembly Line";
                                SourceID := WhseWkshLine."Whse. Document No.";
                                SourceBatchName := '';
                                SourceRefNo := WhseWkshLine."Whse. Document Line No.";
                            end;
                        else begin
                                SourceType := DATABASE::"Whse. Worksheet Line";
                                SourceID := WhseWkshLine.Name;
                                SourceBatchName := WhseWkshLine."Worksheet Template Name";
                                SourceRefNo := WhseWkshLine."Line No.";
                            end;
                    end;
                    // COPY END
                    WhseInsertItemTracking(WhseItemTrackingLine,
                      WhseWkshLine."Item No.",
                      WhseWkshLine."Location Code",
                      WhseWkshLine."Variant Code",
                      QtyBase,
                      WhseWkshLine."Qty. per Unit of Measure",
                      SerialNo,
                      LotNo,
                      SourceType,
                      0,
                      SourceID,
                      SourceBatchName,
                      0,
                      SourceRefNo);
                end;
            DATABASE::"Whse. Internal Put-away Line":
                begin
                    WhseInternalPutAwayLine.Init();
                    RecRef.SetTable(WhseInternalPutAwayLine);
                    // COPY FROM TAB 7332: OpenItemTrackingLines
                    WhseInternalPutAwayLine.TestField("Item No.");
                    WhseInternalPutAwayLine.TestField("Qty. (Base)");
                    WhseWkshLine.Init();
                    WhseWkshLine."Whse. Document Type" :=
                      WhseWkshLine."Whse. Document Type"::"Internal Put-away";
                    WhseWkshLine."Whse. Document No." := WhseInternalPutAwayLine."No.";
                    WhseWkshLine."Whse. Document Line No." := WhseInternalPutAwayLine."Line No.";
                    WhseWkshLine."Location Code" := WhseInternalPutAwayLine."Location Code";
                    WhseWkshLine."Item No." := WhseInternalPutAwayLine."Item No.";
                    WhseWkshLine."Qty. (Base)" := WhseInternalPutAwayLine."Qty. (Base)";
                    WhseWkshLine."Qty. to Handle (Base)" :=
                      WhseInternalPutAwayLine."Qty. (Base)" - WhseInternalPutAwayLine."Qty. Put Away (Base)" -
                      WhseInternalPutAwayLine."Put-away Qty. (Base)";
                    WhseWkshLine."Qty. per Unit of Measure" := WhseInternalPutAwayLine."Qty. per Unit of Measure";
                    // COPY END
                    RecRef.GetTable(WhseWkshLine);
                    WhseItemTracking(WhseItemTrackingLine, RecRef, SerialNo, LotNo, QtyBase);
                end;
            DATABASE::"Whse. Internal Pick Line":
                begin
                    WhseInternalPickLine.Init();
                    RecRef.SetTable(WhseInternalPickLine);
                    // COPY FROM TAB 7334: OpenItemTrackingLines
                    WhseInternalPickLine.TestField("Item No.");
                    WhseInternalPickLine.TestField("Qty. (Base)");
                    WhseWkshLine.Init();
                    WhseWkshLine."Whse. Document Type" :=
                      WhseWkshLine."Whse. Document Type"::"Internal Pick";
                    WhseWkshLine."Whse. Document No." := WhseInternalPickLine."No.";
                    WhseWkshLine."Whse. Document Line No." := WhseInternalPickLine."Line No.";
                    WhseWkshLine."Location Code" := WhseInternalPickLine."Location Code";
                    WhseWkshLine."Item No." := WhseInternalPickLine."Item No.";
                    WhseWkshLine."Qty. (Base)" := WhseInternalPickLine."Qty. (Base)";
                    WhseWkshLine."Qty. to Handle (Base)" :=
                      WhseInternalPickLine."Qty. (Base)" - WhseInternalPickLine."Qty. Picked (Base)" -
                      WhseInternalPickLine."Pick Qty. (Base)";
                    // WhseWkshLine."Qty. per Unit of Measure" := WhseInternalPickLine."Qty. per Unit of Measure";
                    // COPY END
                    RecRef.GetTable(WhseWkshLine);
                    WhseItemTracking(WhseItemTrackingLine, RecRef, SerialNo, LotNo, QtyBase);
                end;
        end;
    end;

    local procedure WhseInsertItemTracking(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; Item: Code[20]; Location: Code[10]; Variant: Code[10]; QtyBase: Decimal; QtyperUOM: Decimal; SerialNo: Code[50]; LotNo: Code[50]; SourceType: Integer; SourceSubType: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer)
    var
        LastEntryNo: Integer;
    begin
        if (SerialNo <> '') and (Abs(QtyBase) > 1) then
            Error(Text002, SerialNo, QtyBase);
        Clear(WhseItemTrackingLine);
        with WhseItemTrackingLine do begin
            if FindLast then
                LastEntryNo := "Entry No." + 1
            else
                LastEntryNo := 1;
            Init;
            "Entry No." := LastEntryNo;

            Validate("Item No.", Item);
            Validate("Location Code", Location);
            Validate("Variant Code", Variant);
            Validate("Qty. per Unit of Measure", QtyperUOM);
            Validate("Quantity (Base)", Abs(QtyBase));

            if SerialNo <> '' then
                Validate("Serial No.", SerialNo);

            if LotNo <> '' then
                Validate("Lot No.", LotNo);

            Validate("Source Type", SourceType);
            Validate("Source Subtype", SourceSubType);
            Validate("Source ID", SourceID);
            Validate("Source Batch Name", SourceBatchName);
            Validate("Source Prod. Order Line", SourceProdOrderLine);
            Validate("Source Ref. No.", SourceRefNo);

            Insert(true);
        end;
    end;
}

