codeunit 99000845 "Reservation Management"
{
    Permissions = TableData "Item Ledger Entry" = rm,
                  TableData "Reservation Entry" = rimd,
                  TableData "Prod. Order Line" = rimd,
                  TableData "Prod. Order Component" = rimd,
                  TableData "Action Message Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Firm Planned %1';
        Text001: Label 'Released %1';
        Text003: Label 'CU99000845: CalculateRemainingQty - Source type missing';
        Text004: Label 'Codeunit 99000845: Illegal FieldFilter parameter';
        Text006: Label 'Outbound,Inbound';
        Text007: Label 'CU99000845 DeleteReservEntries2: Surplus order tracking double record detected.';
        CalcReservEntry: Record "Reservation Entry";
        CalcReservEntry2: Record "Reservation Entry";
        ForItemLedgEntry: Record "Item Ledger Entry";
        CalcItemLedgEntry: Record "Item Ledger Entry";
        ForSalesLine: Record "Sales Line";
        CalcSalesLine: Record "Sales Line";
        ForPurchLine: Record "Purchase Line";
        CalcPurchLine: Record "Purchase Line";
        ForItemJnlLine: Record "Item Journal Line";
        ForReqLine: Record "Requisition Line";
        CalcReqLine: Record "Requisition Line";
        ForProdOrderLine: Record "Prod. Order Line";
        CalcProdOrderLine: Record "Prod. Order Line";
        ForProdOrderComp: Record "Prod. Order Component";
        CalcProdOrderComp: Record "Prod. Order Component";
        ForPlanningComponent: Record "Planning Component";
        CalcPlanningComponent: Record "Planning Component";
        ForAssemblyHeader: Record "Assembly Header";
        CalcAssemblyHeader: Record "Assembly Header";
        ForAssemblyLine: Record "Assembly Line";
        CalcAssemblyLine: Record "Assembly Line";
        ForTransLine: Record "Transfer Line";
        CalcTransLine: Record "Transfer Line";
        ForServiceLine: Record "Service Line";
        CalcServiceLine: Record "Service Line";
        ForJobPlanningLine: Record "Job Planning Line";
        CalcJobPlanningLine: Record "Job Planning Line";
        ActionMessageEntry: Record "Action Message Entry";
        Item: Record Item;
        Location: Record Location;
        MfgSetup: Record "Manufacturing Setup";
        SKU: Record "Stockkeeping Unit";
        ItemTrackingCode: Record "Item Tracking Code";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        CallTrackingSpecification: Record "Tracking Specification";
        ForJobJnlLine: Record "Job Journal Line";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        ReserveSalesLine: Codeunit "Sales Line-Reserve";
        ReserveReqLine: Codeunit "Req. Line-Reserve";
        ReservePurchLine: Codeunit "Purch. Line-Reserve";
        ReserveItemJnlLine: Codeunit "Item Jnl. Line-Reserve";
        ReserveProdOrderLine: Codeunit "Prod. Order Line-Reserve";
        ReserveProdOrderComp: Codeunit "Prod. Order Comp.-Reserve";
        AssemblyHeaderReserve: Codeunit "Assembly Header-Reserve";
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
        ReservePlanningComponent: Codeunit "Plng. Component-Reserve";
        ReserveServiceInvLine: Codeunit "Service Line-Reserve";
        ReserveTransLine: Codeunit "Transfer Line-Reserve";
        JobPlanningLineReserve: Codeunit "Job Planning Line-Reserve";
        GetPlanningParameters: Codeunit "Planning-Get Parameters";
        CreatePick: Codeunit "Create Pick";
        UOMMgt: Codeunit "Unit of Measure Management";
        Positive: Boolean;
        CurrentBindingIsSet: Boolean;
        HandleItemTracking: Boolean;
        InvSearch: Text[1];
        FieldFilter: Text[80];
        InvNextStep: Integer;
        ValueArray: array[18] of Integer;
        CurrentBinding: Option ,"Order-to-Order";
        ItemTrackingHandling: Option "None","Allow deletion",Match;
        Text008: Label 'Item tracking defined for item %1 in the %2 accounts for more than the quantity you have entered.\You must adjust the existing item tracking and then reenter the new quantity.';
        Text009: Label 'Item Tracking cannot be fully matched.\Serial No.: %1, Lot No.: %2, outstanding quantity: %3.';
        Text010: Label 'Item tracking is defined for item %1 in the %2.\You must delete the existing item tracking before modifying or deleting the %2.';
        TotalAvailQty: Decimal;
        QtyAllocInWhse: Decimal;
        QtyOnOutBound: Decimal;
        Text011: Label 'Item tracking is defined for item %1 in the %2.\Do you want to delete the %2 and the item tracking lines?';
        QtyReservedOnPickShip: Decimal;
        AssemblyTxt: Label 'Assembly';
        DeleteDocLineWithItemReservQst: Label '%1 %2 has item reservation. Do you want to delete it anyway?', Comment = '%1 = Document Type, %2 = Document No.';
        DeleteTransLineWithItemReservQst: Label 'Transfer order %1 has item reservation. Do you want to delete it anyway?', Comment = '%1 = Document No.';
        DeleteProdOrderLineWithItemReservQst: Label '%1 production order %2 has item reservation. Do you want to delete it anyway?', Comment = '%1 = Status, %2 = Prod. Order No.';
        SkipUntrackedSurplus: Boolean;

    procedure IsPositive(): Boolean
    begin
        exit(Positive);
    end;

    procedure FormatQty(Quantity: Decimal): Decimal
    begin
        if Positive then
            exit(Quantity);

        exit(-Quantity);
    end;

    procedure SetCalcReservEntry(TrackingSpecification: Record "Tracking Specification"; var ReservEntry: Record "Reservation Entry")
    begin
        // Late Binding
        CalcReservEntry.TransferFields(TrackingSpecification);
        SourceQuantity(CalcReservEntry, true);
        CalcReservEntry.CopyTrackingFromSpec(TrackingSpecification);
        ReservEntry := CalcReservEntry;
        HandleItemTracking := true;
    end;

    procedure SetSalesLine(NewSalesLine: Record "Sales Line")
    begin
        ClearAll;
        TempTrackingSpecification.DeleteAll;

        ForSalesLine := NewSalesLine;

        CalcReservEntry.SetSource(
          DATABASE::"Sales Line", ForSalesLine."Document Type", NewSalesLine."Document No.", NewSalesLine."Line No.", '', 0);
        CalcReservEntry.SetItemData(
          NewSalesLine."No.", NewSalesLine.Description, NewSalesLine."Location Code", NewSalesLine."Variant Code",
          NewSalesLine."Qty. per Unit of Measure");
        if NewSalesLine.Type <> NewSalesLine.Type::Item then
            CalcReservEntry."Item No." := '';
        CalcReservEntry."Expected Receipt Date" := NewSalesLine."Shipment Date";
        CalcReservEntry."Shipment Date" := NewSalesLine."Shipment Date";
        OnSetSalesLineOnBeforeUpdateReservation(CalcReservEntry, NewSalesLine);

        UpdateReservation((CreateReservEntry.SignFactor(CalcReservEntry) * ForSalesLine."Outstanding Qty. (Base)") <= 0);
    end;

    procedure SetReqLine(NewReqLine: Record "Requisition Line")
    begin
        ClearAll;
        TempTrackingSpecification.DeleteAll;

        ForReqLine := NewReqLine;

        CalcReservEntry.SetSource(
          DATABASE::"Requisition Line", 0, NewReqLine."Worksheet Template Name", NewReqLine."Line No.", NewReqLine."Journal Batch Name", 0);
        CalcReservEntry.SetItemData(
          NewReqLine."No.", NewReqLine.Description, NewReqLine."Location Code", NewReqLine."Variant Code",
          NewReqLine."Qty. per Unit of Measure");
        if NewReqLine.Type <> NewReqLine.Type::Item then
            CalcReservEntry."Item No." := '';
        CalcReservEntry."Expected Receipt Date" := NewReqLine."Due Date";
        CalcReservEntry."Shipment Date" := NewReqLine."Due Date";
        CalcReservEntry."Planning Flexibility" := NewReqLine."Planning Flexibility";
        OnSetReqLineOnBeforeUpdateReservation(CalcReservEntry, NewReqLine);
        UpdateReservation(ForReqLine."Net Quantity (Base)" < 0);
    end;

    procedure SetPurchLine(NewPurchLine: Record "Purchase Line")
    begin
        ClearAll;
        TempTrackingSpecification.DeleteAll;

        ForPurchLine := NewPurchLine;

        CalcReservEntry.SetSource(
          DATABASE::"Purchase Line", ForPurchLine."Document Type", NewPurchLine."Document No.", NewPurchLine."Line No.", '', 0);
        CalcReservEntry.SetItemData(
          NewPurchLine."No.", NewPurchLine.Description, NewPurchLine."Location Code", NewPurchLine."Variant Code",
          NewPurchLine."Qty. per Unit of Measure");
        if NewPurchLine.Type <> NewPurchLine.Type::Item then
            CalcReservEntry."Item No." := '';
        CalcReservEntry."Expected Receipt Date" := NewPurchLine."Expected Receipt Date";
        CalcReservEntry."Shipment Date" := NewPurchLine."Expected Receipt Date";
        CalcReservEntry."Planning Flexibility" := NewPurchLine."Planning Flexibility";
        OnSetPurchLineOnBeforeUpdateReservation(CalcReservEntry, NewPurchLine);
        UpdateReservation((CreateReservEntry.SignFactor(CalcReservEntry) * ForPurchLine."Outstanding Qty. (Base)") < 0);
    end;

    procedure SetItemJnlLine(NewItemJnlLine: Record "Item Journal Line")
    begin
        ClearAll;
        TempTrackingSpecification.DeleteAll;

        ForItemJnlLine := NewItemJnlLine;

        CalcReservEntry.SetSource(
          DATABASE::"Item Journal Line", ForItemJnlLine."Entry Type", NewItemJnlLine."Journal Template Name",
          NewItemJnlLine."Line No.", NewItemJnlLine."Journal Batch Name", 0);
        CalcReservEntry.SetItemData(
          NewItemJnlLine."Item No.", NewItemJnlLine.Description, NewItemJnlLine."Location Code", NewItemJnlLine."Variant Code",
          NewItemJnlLine."Qty. per Unit of Measure");
        CalcReservEntry."Expected Receipt Date" := NewItemJnlLine."Posting Date";
        CalcReservEntry."Shipment Date" := NewItemJnlLine."Posting Date";
        OnSetItemJnlLineOnBeforeUpdateReservation(CalcReservEntry, NewItemJnlLine);
        UpdateReservation((CreateReservEntry.SignFactor(CalcReservEntry) * ForItemJnlLine."Quantity (Base)") < 0);
    end;

    procedure SetProdOrderLine(NewProdOrderLine: Record "Prod. Order Line")
    begin
        ClearAll;
        TempTrackingSpecification.DeleteAll;

        ForProdOrderLine := NewProdOrderLine;

        CalcReservEntry.SetSource(
          DATABASE::"Prod. Order Line", ForProdOrderLine.Status, ForProdOrderLine."Prod. Order No.", 0, '', NewProdOrderLine."Line No.");
        CalcReservEntry.SetItemData(
          NewProdOrderLine."Item No.", NewProdOrderLine.Description, NewProdOrderLine."Location Code", NewProdOrderLine."Variant Code",
          NewProdOrderLine."Qty. per Unit of Measure");
        CalcReservEntry."Expected Receipt Date" := NewProdOrderLine."Due Date";
        CalcReservEntry."Shipment Date" := NewProdOrderLine."Due Date";
        CalcReservEntry."Planning Flexibility" := NewProdOrderLine."Planning Flexibility";
        OnSetProdOrderLineOnBeforeUpdateReservation(CalcReservEntry, NewProdOrderLine);
        UpdateReservation(ForProdOrderLine."Remaining Qty. (Base)" < 0);
    end;

    procedure SetProdOrderComponent(NewProdOrderComp: Record "Prod. Order Component")
    begin
        ClearAll;
        TempTrackingSpecification.DeleteAll;

        ForProdOrderComp := NewProdOrderComp;

        CalcReservEntry.SetSource(
          DATABASE::"Prod. Order Component", NewProdOrderComp.Status, NewProdOrderComp."Prod. Order No.",
          NewProdOrderComp."Line No.", '', NewProdOrderComp."Prod. Order Line No.");
        CalcReservEntry.SetItemData(
          NewProdOrderComp."Item No.", NewProdOrderComp.Description, NewProdOrderComp."Location Code", NewProdOrderComp."Variant Code",
          NewProdOrderComp."Qty. per Unit of Measure");
        CalcReservEntry."Expected Receipt Date" := NewProdOrderComp."Due Date";
        CalcReservEntry."Shipment Date" := NewProdOrderComp."Due Date";
        OnSetProdOrderCompOnBeforeUpdateReservation(CalcReservEntry, NewProdOrderComp);
        UpdateReservation(ForProdOrderComp."Remaining Qty. (Base)" > 0);
    end;

    procedure SetAssemblyHeader(NewAssemblyHeader: Record "Assembly Header")
    begin
        ClearAll;
        TempTrackingSpecification.DeleteAll;

        ForAssemblyHeader := NewAssemblyHeader;

        CalcReservEntry.SetSource(
          DATABASE::"Assembly Header", ForAssemblyHeader."Document Type", NewAssemblyHeader."No.", 0, '', 0);
        CalcReservEntry.SetItemData(
          NewAssemblyHeader."Item No.", NewAssemblyHeader.Description, NewAssemblyHeader."Location Code", NewAssemblyHeader."Variant Code",
          NewAssemblyHeader."Qty. per Unit of Measure");
        CalcReservEntry."Expected Receipt Date" := NewAssemblyHeader."Due Date";
        CalcReservEntry."Shipment Date" := NewAssemblyHeader."Due Date";
        OnSetAssemblyHeaderOnBeforeUpdateReservation(CalcReservEntry, NewAssemblyHeader);
        UpdateReservation((CreateReservEntry.SignFactor(CalcReservEntry) * ForAssemblyHeader."Remaining Quantity (Base)") < 0);
    end;

    procedure SetAssemblyLine(NewAssemblyLine: Record "Assembly Line")
    begin
        ClearAll;
        TempTrackingSpecification.DeleteAll;

        ForAssemblyLine := NewAssemblyLine;

        CalcReservEntry.SetSource(
          DATABASE::"Assembly Line", ForAssemblyLine."Document Type", NewAssemblyLine."Document No.", NewAssemblyLine."Line No.", '', 0);
        CalcReservEntry.SetItemData(
          NewAssemblyLine."No.", NewAssemblyLine.Description, NewAssemblyLine."Location Code", NewAssemblyLine."Variant Code",
          NewAssemblyLine."Qty. per Unit of Measure");
        if NewAssemblyLine.Type <> NewAssemblyLine.Type::Item then
            CalcReservEntry."Item No." := '';
        CalcReservEntry."Expected Receipt Date" := NewAssemblyLine."Due Date";
        CalcReservEntry."Shipment Date" := NewAssemblyLine."Due Date";
        OnSetAssemblyLineOnBeforeUpdateReservation(CalcReservEntry, NewAssemblyLine);
        UpdateReservation((CreateReservEntry.SignFactor(CalcReservEntry) * ForAssemblyLine."Remaining Quantity (Base)") < 0);
    end;

    procedure SetPlanningComponent(NewPlanningComponent: Record "Planning Component")
    begin
        ClearAll;
        TempTrackingSpecification.DeleteAll;

        ForPlanningComponent := NewPlanningComponent;

        CalcReservEntry.SetSource(
          DATABASE::"Planning Component", 0, NewPlanningComponent."Worksheet Template Name",
          NewPlanningComponent."Line No.", NewPlanningComponent."Worksheet Batch Name", NewPlanningComponent."Worksheet Line No.");
        CalcReservEntry.SetItemData(
          NewPlanningComponent."Item No.", NewPlanningComponent.Description, NewPlanningComponent."Location Code",
          NewPlanningComponent."Variant Code", NewPlanningComponent."Qty. per Unit of Measure");
        CalcReservEntry."Expected Receipt Date" := NewPlanningComponent."Due Date";
        CalcReservEntry."Shipment Date" := NewPlanningComponent."Due Date";
        OnSetPlanningCompOnBeforeUpdateReservation(CalcReservEntry, NewPlanningComponent);
        UpdateReservation(ForPlanningComponent."Net Quantity (Base)" > 0);
    end;

    procedure SetItemLedgEntry(NewItemLedgEntry: Record "Item Ledger Entry")
    begin
        ClearAll;
        TempTrackingSpecification.DeleteAll;

        ForItemLedgEntry := NewItemLedgEntry;

        CalcReservEntry.SetSource(DATABASE::"Item Ledger Entry", 0, '', NewItemLedgEntry."Entry No.", '', 0);

        CalcReservEntry.SetItemData(
          NewItemLedgEntry."Item No.", NewItemLedgEntry.Description, NewItemLedgEntry."Location Code", NewItemLedgEntry."Variant Code",
          NewItemLedgEntry."Qty. per Unit of Measure");
        CalcReservEntry.CopyTrackingFromItemLedgEntry(NewItemLedgEntry);

        Positive := ForItemLedgEntry."Remaining Quantity" <= 0;
        if Positive then begin
            CalcReservEntry."Expected Receipt Date" := DMY2Date(31, 12, 9999);
            CalcReservEntry."Shipment Date" := DMY2Date(31, 12, 9999);
        end else begin
            CalcReservEntry."Expected Receipt Date" := 0D;
            CalcReservEntry."Shipment Date" := 0D;
        end;
        OnSetItemLedgEntryOnBeforeUpdateReservation(CalcReservEntry, NewItemLedgEntry);
        UpdateReservation(Positive);
    end;

    procedure SetTransferLine(NewTransLine: Record "Transfer Line"; Direction: Option Outbound,Inbound)
    begin
        ClearAll;
        TempTrackingSpecification.DeleteAll;

        ForTransLine := NewTransLine;

        CalcReservEntry.SetSource(
          DATABASE::"Transfer Line", Direction, NewTransLine."Document No.", NewTransLine."Line No.", '',
          NewTransLine."Derived From Line No.");

        case Direction of
            Direction::Outbound:
                begin
                    CalcReservEntry.SetItemData(
                      NewTransLine."Item No.", NewTransLine.Description, NewTransLine."Transfer-from Code", NewTransLine."Variant Code",
                      NewTransLine."Qty. per Unit of Measure");
                    CalcReservEntry."Shipment Date" := NewTransLine."Shipment Date";
                end;
            Direction::Inbound:
                begin
                    CalcReservEntry.SetItemData(
                      NewTransLine."Item No.", NewTransLine.Description, NewTransLine."Transfer-to Code", NewTransLine."Variant Code",
                      NewTransLine."Qty. per Unit of Measure");
                    CalcReservEntry."Expected Receipt Date" := NewTransLine."Receipt Date";
                end;
        end;
        OnSetTransLineOnBeforeUpdateReservation(CalcReservEntry, NewTransLine);
        UpdateReservation((CreateReservEntry.SignFactor(CalcReservEntry) * ForTransLine."Outstanding Qty. (Base)") <= 0);
    end;

    procedure SetServLine(NewServiceLine: Record "Service Line")
    begin
        ClearAll;
        TempTrackingSpecification.DeleteAll;

        ForServiceLine := NewServiceLine;

        CalcReservEntry.SetSource(
          DATABASE::"Service Line", ForServiceLine."Document Type", ForServiceLine."Document No.", NewServiceLine."Line No.", '', 0);
        CalcReservEntry.SetItemData(
          NewServiceLine."No.", NewServiceLine.Description, NewServiceLine."Location Code", NewServiceLine."Variant Code",
          NewServiceLine."Qty. per Unit of Measure");
        if NewServiceLine.Type <> NewServiceLine.Type::Item then
            CalcReservEntry."Item No." := '';
        CalcReservEntry."Expected Receipt Date" := NewServiceLine."Needed by Date";
        CalcReservEntry."Shipment Date" := NewServiceLine."Needed by Date";
        OnSetServLineOnBeforeUpdateReservation(CalcReservEntry, NewServiceLine);
        UpdateReservation((CreateReservEntry.SignFactor(CalcReservEntry) * ForServiceLine."Outstanding Qty. (Base)") <= 0);
    end;

    procedure SetJobJnlLine(NewJobJnlLine: Record "Job Journal Line")
    begin
        ClearAll;
        ForJobJnlLine := NewJobJnlLine;

        CalcReservEntry.SetSource(
          DATABASE::"Job Journal Line", ForJobJnlLine."Entry Type", NewJobJnlLine."Journal Template Name", NewJobJnlLine."Line No.",
          NewJobJnlLine."Journal Batch Name", 0);
        CalcReservEntry.SetItemData(
          NewJobJnlLine."No.", NewJobJnlLine.Description, NewJobJnlLine."Location Code", NewJobJnlLine."Variant Code",
          NewJobJnlLine."Qty. per Unit of Measure");
        CalcReservEntry."Expected Receipt Date" := NewJobJnlLine."Posting Date";
        CalcReservEntry."Shipment Date" := NewJobJnlLine."Posting Date";
        OnSetJobJnlLineOnBeforeUpdateReservation(CalcReservEntry, NewJobJnlLine);
        UpdateReservation((CreateReservEntry.SignFactor(CalcReservEntry) * ForJobJnlLine."Quantity (Base)") < 0);
    end;

    procedure SetJobPlanningLine(NewJobPlanningLine: Record "Job Planning Line")
    begin
        ClearAll;
        TempTrackingSpecification.DeleteAll;

        ForJobPlanningLine := NewJobPlanningLine;

        CalcReservEntry.SetSource(
          DATABASE::"Job Planning Line", ForJobPlanningLine.Status, NewJobPlanningLine."Job No.",
          NewJobPlanningLine."Job Contract Entry No.", '', 0);
        CalcReservEntry.SetItemData(
          NewJobPlanningLine."No.", NewJobPlanningLine.Description, NewJobPlanningLine."Location Code", NewJobPlanningLine."Variant Code",
          NewJobPlanningLine."Qty. per Unit of Measure");
        if NewJobPlanningLine.Type <> NewJobPlanningLine.Type::Item then
            CalcReservEntry."Item No." := '';
        CalcReservEntry."Expected Receipt Date" := NewJobPlanningLine."Planning Date";
        CalcReservEntry."Shipment Date" := NewJobPlanningLine."Planning Date";
        OnSetJobPlanningLineOnBeforeUpdateReservation(CalcReservEntry, NewJobPlanningLine);
        UpdateReservation((CreateReservEntry.SignFactor(CalcReservEntry) * ForJobPlanningLine."Remaining Qty. (Base)") <= 0);
    end;

    procedure SetExternalDocumentResEntry(ReservEntry: Record "Reservation Entry"; UpdReservation: Boolean)
    begin
        ClearAll;
        TempTrackingSpecification.DeleteAll;
        CalcReservEntry := ReservEntry;
        UpdateReservation(UpdReservation);
    end;

    procedure SalesLineUpdateValues(var CurrentSalesLine: Record "Sales Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var QtyReservedThisLine: Decimal; var QtyReservedThisLineBase: Decimal)
    begin
        with CurrentSalesLine do begin
            CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
            if "Document Type" = "Document Type"::"Return Order" then begin
                "Reserved Quantity" := -"Reserved Quantity";
                "Reserved Qty. (Base)" := -"Reserved Qty. (Base)";
            end;
            QtyReservedThisLine := "Reserved Quantity";
            QtyReservedThisLineBase := "Reserved Qty. (Base)";
            QtyToReserve := "Outstanding Quantity" - "Reserved Quantity";
            QtyToReserveBase := "Outstanding Qty. (Base)" - "Reserved Qty. (Base)";
        end;
    end;

    procedure ReqLineUpdateValues(var CurrentReqLine: Record "Requisition Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var QtyReservedThisLine: Decimal; var QtyReservedThisLineBase: Decimal)
    begin
        with CurrentReqLine do begin
            CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
            QtyReservedThisLine := "Reserved Quantity";
            QtyReservedThisLineBase := "Reserved Qty. (Base)";
            QtyToReserve := Quantity - "Reserved Quantity";
            QtyToReserveBase := "Quantity (Base)" - "Reserved Qty. (Base)";
        end;
    end;

    procedure PurchLineUpdateValues(var CurrentPurchLine: Record "Purchase Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var QtyReservedThisLine: Decimal; var QtyReservedThisLineBase: Decimal)
    begin
        with CurrentPurchLine do begin
            CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
            if "Document Type" = "Document Type"::"Return Order" then begin
                "Reserved Quantity" := -"Reserved Quantity";
                "Reserved Qty. (Base)" := -"Reserved Qty. (Base)";
            end;
            QtyReservedThisLine := "Reserved Quantity";
            QtyReservedThisLineBase := "Reserved Qty. (Base)";
            QtyToReserve := "Outstanding Quantity" - "Reserved Quantity";
            QtyToReserveBase := "Outstanding Qty. (Base)" - "Reserved Qty. (Base)";
        end;
    end;

    procedure ProdOrderLineUpdateValues(var CurrentProdOrderLine: Record "Prod. Order Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var QtyReservedThisLine: Decimal; var QtyReservedThisLineBase: Decimal)
    begin
        with CurrentProdOrderLine do begin
            CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
            QtyReservedThisLine := "Reserved Quantity";
            QtyReservedThisLineBase := "Reserved Qty. (Base)";
            QtyToReserve := "Remaining Quantity" - "Reserved Quantity";
            QtyToReserveBase := "Remaining Qty. (Base)" - "Reserved Qty. (Base)";
        end;
    end;

    procedure ProdOrderCompUpdateValues(var CurrentProdOrderComp: Record "Prod. Order Component"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var QtyReservedThisLine: Decimal; var QtyReservedThisLineBase: Decimal)
    begin
        with CurrentProdOrderComp do begin
            CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
            QtyReservedThisLine := "Reserved Qty. (Base)";
            QtyReservedThisLineBase := "Reserved Qty. (Base)";
            QtyToReserve := "Remaining Quantity" - "Reserved Quantity";
            QtyToReserveBase := "Remaining Qty. (Base)" - "Reserved Qty. (Base)";
        end;
    end;

    procedure AssemblyHeaderUpdateValues(var CurrentAssemblyHeader: Record "Assembly Header"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var QtyReservedThisLine: Decimal; var QtyReservedThisLineBase: Decimal)
    begin
        with CurrentAssemblyHeader do begin
            CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
            QtyReservedThisLine := "Reserved Quantity";
            QtyReservedThisLineBase := "Reserved Qty. (Base)";
            QtyToReserve := "Remaining Quantity" - "Reserved Quantity";
            QtyToReserveBase := "Remaining Quantity (Base)" - "Reserved Qty. (Base)";
        end;
    end;

    procedure AssemblyLineUpdateValues(var CurrentAssemblyLine: Record "Assembly Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var QtyReservedThisLine: Decimal; var QtyReservedThisLineBase: Decimal)
    begin
        with CurrentAssemblyLine do begin
            CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
            QtyReservedThisLine := "Reserved Quantity";
            QtyReservedThisLineBase := "Reserved Qty. (Base)";
            QtyToReserve := "Remaining Quantity" - "Reserved Quantity";
            QtyToReserveBase := "Remaining Quantity (Base)" - "Reserved Qty. (Base)";
        end;
    end;

    procedure PlanningComponentUpdateValues(var CurrentPlanningComponent: Record "Planning Component"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var QtyReservedThisLine: Decimal; var QtyReservedThisLineBase: Decimal)
    begin
        with CurrentPlanningComponent do begin
            CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
            QtyReservedThisLine := "Reserved Quantity";
            QtyReservedThisLineBase := "Reserved Qty. (Base)";
            QtyToReserve := 0;
            QtyToReserveBase := "Net Quantity (Base)" - "Reserved Qty. (Base)";
        end;
    end;

    procedure ItemLedgEntryUpdateValues(var CurrentItemLedgEntry: Record "Item Ledger Entry"; var QtyToReserve: Decimal; var QtyReservedThisLine: Decimal)
    begin
        with CurrentItemLedgEntry do begin
            CalcFields("Reserved Quantity");
            QtyReservedThisLine := "Reserved Quantity";
            QtyToReserve := "Remaining Quantity" - "Reserved Quantity";
        end;
    end;

    procedure ServiceInvLineUpdateValues(var CurrentServiceInvLine: Record "Service Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var QtyReservedThisLine: Decimal; var QtyReservedThisLineBase: Decimal)
    begin
        with CurrentServiceInvLine do begin
            CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
            QtyReservedThisLine := "Reserved Quantity";
            QtyReservedThisLineBase := "Reserved Qty. (Base)";
            QtyToReserve := "Outstanding Quantity" - "Reserved Quantity";
            QtyToReserveBase := "Outstanding Qty. (Base)" - "Reserved Qty. (Base)";
        end;
    end;

    procedure TransferLineUpdateValues(var CurrentTransLine: Record "Transfer Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var QtyReservedThisLine: Decimal; var QtyReservedThisLineBase: Decimal; Direction: Option Outbound,Inbound)
    begin
        with CurrentTransLine do
            case Direction of
                Direction::Outbound:
                    begin
                        CalcFields("Reserved Quantity Outbnd.", "Reserved Qty. Outbnd. (Base)");
                        QtyReservedThisLine := "Reserved Quantity Outbnd.";
                        QtyReservedThisLineBase := "Reserved Qty. Outbnd. (Base)";
                        QtyToReserve := -"Outstanding Quantity" + "Reserved Quantity Outbnd.";
                        QtyToReserveBase := -"Outstanding Qty. (Base)" + "Reserved Qty. Outbnd. (Base)";
                    end;
                Direction::Inbound:
                    begin
                        CalcFields("Reserved Quantity Inbnd.", "Reserved Qty. Inbnd. (Base)");
                        QtyReservedThisLine := "Reserved Quantity Inbnd.";
                        QtyReservedThisLineBase := "Reserved Qty. Inbnd. (Base)";
                        QtyToReserve := "Outstanding Quantity" - "Reserved Quantity Inbnd.";
                        QtyToReserveBase := "Outstanding Qty. (Base)" - "Reserved Qty. Inbnd. (Base)";
                    end;
            end;
    end;

    procedure JobPlanningLineUpdateValues(var CurrentJobPlanningLine: Record "Job Planning Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var QtyReservedThisLine: Decimal; var QtyReservedThisLineBase: Decimal)
    begin
        with CurrentJobPlanningLine do begin
            CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
            QtyReservedThisLine := "Reserved Quantity";
            QtyReservedThisLineBase := "Reserved Qty. (Base)";
            QtyToReserve := "Remaining Qty." - "Reserved Quantity";
            QtyToReserveBase := "Remaining Qty. (Base)" - "Reserved Qty. (Base)";
        end;
    end;

    local procedure UpdateReservation(EntryIsPositive: Boolean)
    begin
        CalcReservEntry2 := CalcReservEntry;
        GetItemSetup(CalcReservEntry);
        Positive := EntryIsPositive;
        CalcReservEntry2.SetPointerFilter;
        CallCalcReservedQtyOnPick;
    end;

    procedure UpdateStatistics(var ReservSummEntry: Record "Entry Summary"; AvailabilityDate: Date; HandleItemTracking2: Boolean)
    var
        i: Integer;
        CurrentEntryNo: Integer;
        ValueArrayNo: Integer;
        CalcSumValue: Decimal;
    begin
        CurrentEntryNo := ReservSummEntry."Entry No.";
        CalcReservEntry.TestField("Source Type");
        ReservSummEntry.DeleteAll;
        HandleItemTracking := HandleItemTracking2;
        if HandleItemTracking2 then
            ValueArrayNo := 3;
        for i := 1 to SetValueArray(ValueArrayNo) do begin
            CalcSumValue := 0;
            ReservSummEntry.Init;
            ReservSummEntry."Entry No." := ValueArray[i];

            case ValueArray[i] of
                1: // Item Ledger Entry
                    UpdateItemLedgEntryStats(ReservSummEntry, AvailabilityDate, i, CalcSumValue, HandleItemTracking2);
                12, 16: // Purchase Order, Purchase Return Order
                    UpdatePurchLineStats(ReservSummEntry, AvailabilityDate, i, CalcSumValue);
                32, 36: // Sales Order, Sales Return Order
                    UpdateSalesLineStats(ReservSummEntry, AvailabilityDate, i, CalcSumValue);
                63: // Firm Planned Prod. Order Line
                    UpdateProdOrderLineStats(ReservSummEntry, AvailabilityDate, i, CalcSumValue);
                64: // Released Prod. Order Line
                    UpdateProdOrderLineStats(ReservSummEntry, AvailabilityDate, i, CalcSumValue);
                73: // Firm Planned Component Line
                    UpdateProdOrderCompStats(ReservSummEntry, AvailabilityDate, i, CalcSumValue);
                74: // Released Component Line
                    UpdateProdOrderCompStats(ReservSummEntry, AvailabilityDate, i, CalcSumValue);
                101, 102: // Transfer Line
                    UpdateTransLineStats(ReservSummEntry, AvailabilityDate, i, CalcSumValue);
                110: // Service Line Order
                    UpdateServLineStats(ReservSummEntry, AvailabilityDate, i, CalcSumValue);
                133: // Job Planning Line Order
                    UpdateJobPlanningLineStats(ReservSummEntry, AvailabilityDate, i, CalcSumValue);
                141, 142: // Assembly Header
                    UpdateAssemblyHeaderStats(ReservSummEntry, AvailabilityDate, i, CalcSumValue);
                151, 152: // AssemblyLine
                    UpdateAssemblyLineStats(ReservSummEntry, AvailabilityDate, i, CalcSumValue);
                6500: // Item Tracking
                    UpdateItemTrackingLineStats(ReservSummEntry, AvailabilityDate);
            end;
        end;

        OnAfterUpdateStatistics(ReservSummEntry, AvailabilityDate, CalcSumValue);

        if not ReservSummEntry.Get(CurrentEntryNo) then
            if ReservSummEntry.IsEmpty then
                Clear(ReservSummEntry);
    end;

    local procedure UpdateItemLedgEntryStats(var ReservEntrySummary: Record "Entry Summary"; AvailabilityDate: Date; i: Integer; var CalcSumValue: Decimal; HandleItemTracking2: Boolean)
    var
        LateBindingMgt: Codeunit "Late Binding Management";
        ReservForm: Page Reservation;
        CurrReservedQtyBase: Decimal;
    begin
        OnBeforeUpdateItemLedgEntryStats(CalcReservEntry);
        if CalcItemLedgEntry.ReadPermission then begin
            InitFilter(ValueArray[i], AvailabilityDate);
            if CalcItemLedgEntry.FindSet then
                repeat
                    CalcItemLedgEntry.CalcFields("Reserved Quantity");
                    OnUpdateItemLedgEntryStatsUpdateTotals(CalcReservEntry, CalcItemLedgEntry, TotalAvailQty, QtyOnOutBound);
                    ReservEntrySummary."Total Reserved Quantity" += CalcItemLedgEntry."Reserved Quantity";
                    CalcSumValue += CalcItemLedgEntry."Remaining Quantity";
                until CalcItemLedgEntry.Next = 0;
            if HandleItemTracking2 then
                if ReservEntrySummary."Total Reserved Quantity" > 0 then
                    ReservEntrySummary."Non-specific Reserved Qty." := LateBindingMgt.NonspecificReservedQty(CalcItemLedgEntry);

            if CalcSumValue <> 0 then
                if (CalcSumValue > 0) = Positive then begin
                    if Location.Get(CalcItemLedgEntry."Location Code") and
                       (Location."Bin Mandatory" or Location."Require Pick")
                    then begin
                        CalcReservedQtyOnPick(TotalAvailQty, QtyAllocInWhse);
                        QtyOnOutBound :=
                          CreatePick.CheckOutBound(
                            CalcReservEntry."Source Type", CalcReservEntry."Source Subtype",
                            CalcReservEntry."Source ID", CalcReservEntry."Source Ref. No.",
                            CalcReservEntry."Source Prod. Order Line");
                    end else begin
                        QtyAllocInWhse := 0;
                        QtyOnOutBound := 0;
                    end;
                    if QtyAllocInWhse < 0 then
                        QtyAllocInWhse := 0;
                    ReservEntrySummary."Table ID" := DATABASE::"Item Ledger Entry";
                    ReservEntrySummary."Summary Type" :=
                      CopyStr(CalcItemLedgEntry.TableCaption, 1, MaxStrLen(ReservEntrySummary."Summary Type"));
                    ReservEntrySummary."Total Quantity" := CalcSumValue;
                    ReservEntrySummary."Total Available Quantity" :=
                      ReservEntrySummary."Total Quantity" - ReservEntrySummary."Total Reserved Quantity";

                    Clear(ReservForm);
                    ReservForm.SetReservEntry(CalcReservEntry);
                    CurrReservedQtyBase := ReservForm.ReservedThisLine(ReservEntrySummary);
                    if (CurrReservedQtyBase <> 0) and (QtyOnOutBound <> 0) then
                        if QtyOnOutBound > CurrReservedQtyBase then
                            QtyOnOutBound := QtyOnOutBound - CurrReservedQtyBase
                        else
                            QtyOnOutBound := 0;

                    if Location."Bin Mandatory" or Location."Require Pick" then begin
                        if TotalAvailQty + QtyOnOutBound < ReservEntrySummary."Total Available Quantity" then
                            ReservEntrySummary."Total Available Quantity" := TotalAvailQty + QtyOnOutBound;
                        ReservEntrySummary."Qty. Alloc. in Warehouse" := QtyAllocInWhse;
                        ReservEntrySummary."Res. Qty. on Picks & Shipmts." := QtyReservedOnPickShip
                    end else begin
                        ReservEntrySummary."Qty. Alloc. in Warehouse" := 0;
                        ReservEntrySummary."Res. Qty. on Picks & Shipmts." := 0
                    end;
                    if not ReservEntrySummary.Insert then
                        ReservEntrySummary.Modify;
                end;
        end;
    end;

    local procedure UpdatePurchLineStats(var ReservEntrySummary: Record "Entry Summary"; AvailabilityDate: Date; i: Integer; var CalcSumValue: Decimal)
    begin
        if CalcPurchLine.ReadPermission then begin
            InitFilter(ValueArray[i], AvailabilityDate);
            if CalcPurchLine.FindSet then
                repeat
                    CalcPurchLine.CalcFields("Reserved Qty. (Base)");
                    if not CalcPurchLine."Special Order" then begin
                        ReservEntrySummary."Total Reserved Quantity" += CalcPurchLine."Reserved Qty. (Base)";
                        CalcSumValue += CalcPurchLine."Outstanding Qty. (Base)";
                    end;
                until CalcPurchLine.Next = 0;

            if CalcSumValue <> 0 then
                with ReservEntrySummary do
                    if (Positive = (CalcSumValue > 0)) and (ValueArray[i] <> 16) or
                       (Positive = (CalcSumValue < 0)) and (ValueArray[i] = 16)
                    then begin
                        "Table ID" := DATABASE::"Purchase Line";
                        "Summary Type" :=
                          CopyStr(
                            StrSubstNo('%1, %2', CalcPurchLine.TableCaption, CalcPurchLine."Document Type"),
                            1, MaxStrLen("Summary Type"));
                        if ValueArray[i] = 16 then
                            "Total Quantity" := -CalcSumValue
                        else
                            "Total Quantity" := CalcSumValue;
                        "Total Available Quantity" := "Total Quantity" - "Total Reserved Quantity";
                        if not Insert then
                            Modify;
                    end;
        end;
    end;

    local procedure UpdateSalesLineStats(var ReservEntrySummary: Record "Entry Summary"; AvailabilityDate: Date; i: Integer; var CalcSumValue: Decimal)
    begin
        if CalcSalesLine.ReadPermission then begin
            InitFilter(ValueArray[i], AvailabilityDate);
            if CalcSalesLine.FindSet then
                repeat
                    CalcSalesLine.CalcFields("Reserved Qty. (Base)");
                    ReservEntrySummary."Total Reserved Quantity" -= CalcSalesLine."Reserved Qty. (Base)";
                    CalcSumValue += CalcSalesLine."Outstanding Qty. (Base)";
                until CalcSalesLine.Next = 0;

            if CalcSumValue <> 0 then
                with ReservEntrySummary do
                    if (Positive = (CalcSumValue < 0)) and (ValueArray[i] <> 36) or
                       (Positive = (CalcSumValue > 0)) and (ValueArray[i] = 36)
                    then begin
                        "Table ID" := DATABASE::"Sales Line";
                        "Summary Type" :=
                          CopyStr(
                            StrSubstNo('%1, %2', CalcSalesLine.TableCaption, CalcSalesLine."Document Type"),
                            1, MaxStrLen("Summary Type"));
                        if ValueArray[i] = 36 then
                            "Total Quantity" := CalcSumValue
                        else
                            "Total Quantity" := -CalcSumValue;
                        "Total Available Quantity" := "Total Quantity" - "Total Reserved Quantity";
                        if not Insert then
                            Modify;
                    end;
        end;
    end;

    local procedure UpdateProdOrderLineStats(var ReservEntrySummary: Record "Entry Summary"; AvailabilityDate: Date; i: Integer; var CalcSumValue: Decimal)
    begin
        if CalcProdOrderLine.ReadPermission then begin
            InitFilter(ValueArray[i], AvailabilityDate);
            if CalcProdOrderLine.FindSet then
                repeat
                    CalcProdOrderLine.CalcFields("Reserved Qty. (Base)");
                    ReservEntrySummary."Total Reserved Quantity" += CalcProdOrderLine."Reserved Qty. (Base)";
                    CalcSumValue += CalcProdOrderLine."Remaining Qty. (Base)";
                until CalcProdOrderLine.Next = 0;

            if CalcSumValue <> 0 then
                with ReservEntrySummary do
                    if (CalcSumValue > 0) = Positive then begin
                        "Table ID" := DATABASE::"Prod. Order Line";
                        if "Entry No." = 63 then
                            "Summary Type" := CopyStr(StrSubstNo(Text000, CalcProdOrderLine.TableCaption), 1, MaxStrLen("Summary Type"))
                        else
                            "Summary Type" := CopyStr(StrSubstNo(Text001, CalcProdOrderLine.TableCaption), 1, MaxStrLen("Summary Type"));
                        "Total Quantity" := CalcSumValue;
                        "Total Available Quantity" := "Total Quantity" - "Total Reserved Quantity";
                        if not Insert then
                            Modify;
                    end;
        end;
    end;

    local procedure UpdateAssemblyHeaderStats(var ReservEntrySummary: Record "Entry Summary"; AvailabilityDate: Date; i: Integer; var CalcSumValue: Decimal)
    begin
        if CalcAssemblyHeader.ReadPermission then begin
            InitFilter(ValueArray[i], AvailabilityDate);
            if CalcAssemblyHeader.FindSet then
                repeat
                    CalcAssemblyHeader.CalcFields("Reserved Qty. (Base)");
                    ReservEntrySummary."Total Reserved Quantity" += CalcAssemblyHeader."Reserved Qty. (Base)";
                    CalcSumValue += CalcAssemblyHeader."Remaining Quantity (Base)";
                until CalcAssemblyHeader.Next = 0;

            if CalcSumValue <> 0 then
                with ReservEntrySummary do
                    if (CalcSumValue > 0) = Positive then begin
                        "Table ID" := DATABASE::"Assembly Header";
                        "Summary Type" :=
                          CopyStr(
                            StrSubstNo('%1 %2', AssemblyTxt, CalcAssemblyHeader."Document Type"),
                            1, MaxStrLen("Summary Type"));
                        "Total Quantity" := CalcSumValue;
                        "Total Available Quantity" := "Total Quantity" - "Total Reserved Quantity";
                        if not Insert then
                            Modify;
                    end;
        end;
    end;

    local procedure UpdateAssemblyLineStats(var ReservEntrySummary: Record "Entry Summary"; AvailabilityDate: Date; i: Integer; var CalcSumValue: Decimal)
    begin
        if CalcAssemblyLine.ReadPermission then begin
            InitFilter(ValueArray[i], AvailabilityDate);
            if CalcAssemblyLine.FindSet then
                repeat
                    CalcAssemblyLine.CalcFields("Reserved Qty. (Base)");
                    ReservEntrySummary."Total Reserved Quantity" -= CalcAssemblyLine."Reserved Qty. (Base)";
                    CalcSumValue += CalcAssemblyLine."Remaining Quantity (Base)";
                until CalcAssemblyLine.Next = 0;

            if CalcSumValue <> 0 then
                with ReservEntrySummary do
                    if CalcSumValue < 0 = Positive then begin
                        "Table ID" := DATABASE::"Assembly Line";
                        "Summary Type" :=
                          CopyStr(
                            StrSubstNo('%1, %2', CalcAssemblyLine.TableCaption, CalcAssemblyLine."Document Type"),
                            1, MaxStrLen("Summary Type"));
                        "Total Quantity" := -CalcSumValue;
                        "Total Available Quantity" := "Total Quantity" - "Total Reserved Quantity";
                        if not Insert then
                            Modify;
                    end;
        end;
    end;

    local procedure UpdateProdOrderCompStats(var ReservEntrySummary: Record "Entry Summary"; AvailabilityDate: Date; i: Integer; var CalcSumValue: Decimal)
    begin
        if CalcProdOrderComp.ReadPermission then begin
            InitFilter(ValueArray[i], AvailabilityDate);
            if CalcProdOrderComp.FindSet then
                repeat
                    CalcProdOrderComp.CalcFields("Reserved Qty. (Base)");
                    ReservEntrySummary."Total Reserved Quantity" -= CalcProdOrderComp."Reserved Qty. (Base)";
                    CalcSumValue += CalcProdOrderComp."Remaining Qty. (Base)";
                until CalcProdOrderComp.Next = 0;

            if CalcSumValue <> 0 then
                with ReservEntrySummary do
                    if (CalcSumValue < 0) = Positive then begin
                        "Table ID" := DATABASE::"Prod. Order Component";
                        if "Entry No." = 73 then
                            "Summary Type" :=
                              CopyStr(StrSubstNo(Text000, CalcProdOrderComp.TableCaption), 1, MaxStrLen("Summary Type"))
                        else
                            "Summary Type" :=
                              CopyStr(StrSubstNo(Text001, CalcProdOrderComp.TableCaption), 1, MaxStrLen("Summary Type"));
                        "Total Quantity" := -CalcSumValue;
                        "Total Available Quantity" := "Total Quantity" - "Total Reserved Quantity";
                        if not Insert then
                            Modify;
                    end;
        end;
    end;

    local procedure UpdateTransLineStats(var ReservEntrySummary: Record "Entry Summary"; AvailabilityDate: Date; i: Integer; var CalcSumValue: Decimal)
    begin
        if CalcTransLine.ReadPermission then begin
            InitFilter(ValueArray[i], AvailabilityDate);
            if CalcTransLine.FindSet then
                repeat
                    case ValueArray[i] of
                        101:
                            begin
                                CalcTransLine.CalcFields("Reserved Qty. Outbnd. (Base)");
                                ReservEntrySummary."Total Reserved Quantity" -= CalcTransLine."Reserved Qty. Outbnd. (Base)";
                                CalcSumValue -= CalcTransLine."Outstanding Qty. (Base)";
                            end;
                        102:
                            begin
                                CalcTransLine.CalcFields("Reserved Qty. Inbnd. (Base)");
                                ReservEntrySummary."Total Reserved Quantity" += CalcTransLine."Reserved Qty. Inbnd. (Base)";
                                CalcSumValue += CalcTransLine."Outstanding Qty. (Base)";
                            end;
                    end;
                until CalcTransLine.Next = 0;

            if CalcSumValue <> 0 then
                with ReservEntrySummary do
                    if (CalcSumValue > 0) = Positive then begin
                        "Table ID" := DATABASE::"Transfer Line";
                        "Summary Type" :=
                          CopyStr(
                            StrSubstNo('%1, %2', CalcTransLine.TableCaption, SelectStr(ValueArray[i] - 100, Text006)),
                            1, MaxStrLen("Summary Type"));
                        "Total Quantity" := CalcSumValue;
                        "Total Available Quantity" := "Total Quantity" - "Total Reserved Quantity";
                        if not Insert then
                            Modify;
                    end;
        end;
    end;

    local procedure UpdateServLineStats(var ReservEntrySummary: Record "Entry Summary"; AvailabilityDate: Date; i: Integer; var CalcSumValue: Decimal)
    begin
        if CalcServiceLine.ReadPermission then begin
            InitFilter(ValueArray[i], AvailabilityDate);
            if CalcServiceLine.FindSet then
                repeat
                    CalcServiceLine.CalcFields("Reserved Qty. (Base)");
                    ReservEntrySummary."Total Reserved Quantity" -= CalcServiceLine."Reserved Qty. (Base)";
                    CalcSumValue += CalcServiceLine."Outstanding Qty. (Base)";
                until CalcServiceLine.Next = 0;

            if CalcSumValue <> 0 then
                with ReservEntrySummary do
                    if (CalcSumValue < 0) = Positive then begin
                        "Table ID" := DATABASE::"Service Line";
                        "Summary Type" :=
                          CopyStr(StrSubstNo('%1', CalcServiceLine.TableCaption), 1, MaxStrLen("Summary Type"));
                        "Total Quantity" := -CalcSumValue;
                        "Total Available Quantity" := "Total Quantity" - "Total Reserved Quantity";
                        if not Insert then
                            Modify;
                    end;
        end;
    end;

    local procedure UpdateJobPlanningLineStats(var ReservEntrySummary: Record "Entry Summary"; AvailabilityDate: Date; i: Integer; var CalcSumValue: Decimal)
    begin
        if CalcJobPlanningLine.ReadPermission then begin
            InitFilter(ValueArray[i], AvailabilityDate);
            if CalcJobPlanningLine.FindSet then
                repeat
                    CalcJobPlanningLine.CalcFields("Reserved Qty. (Base)");
                    ReservEntrySummary."Total Reserved Quantity" -= CalcJobPlanningLine."Reserved Qty. (Base)";
                    CalcSumValue += CalcJobPlanningLine."Remaining Qty. (Base)";
                until CalcJobPlanningLine.Next = 0;

            if CalcSumValue <> 0 then
                with ReservEntrySummary do
                    if (CalcSumValue < 0) = Positive then begin
                        "Table ID" := DATABASE::"Job Planning Line";
                        "Summary Type" :=
                          CopyStr(
                            StrSubstNo('%1, %2', CalcJobPlanningLine.TableCaption, CalcJobPlanningLine.Status),
                            1, MaxStrLen("Summary Type"));
                        "Total Quantity" := -CalcSumValue;
                        "Total Available Quantity" := "Total Quantity" - "Total Reserved Quantity";
                        if not Insert then
                            Modify;
                    end;
        end;
    end;

    local procedure UpdateItemTrackingLineStats(var ReservEntrySummary: Record "Entry Summary"; AvailabilityDate: Date)
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.Reset;
        ReservEntry.SetCurrentKey(
          "Item No.", "Source Type", "Source Subtype", "Reservation Status", "Location Code",
          "Variant Code", "Shipment Date", "Expected Receipt Date", "Serial No.", "Lot No.");
        ReservEntry.SetRange("Item No.", CalcReservEntry."Item No.");
        ReservEntry.SetFilter("Source Type", '<> %1', DATABASE::"Item Ledger Entry");
        ReservEntry.SetRange("Reservation Status",
          ReservEntry."Reservation Status"::Reservation, ReservEntry."Reservation Status"::Surplus);
        ReservEntry.SetRange("Location Code", CalcReservEntry."Location Code");
        ReservEntry.SetRange("Variant Code", CalcReservEntry."Variant Code");
        if Positive then
            ReservEntry.SetFilter("Expected Receipt Date", '..%1', AvailabilityDate)
        else
            ReservEntry.SetFilter("Shipment Date", '>=%1', AvailabilityDate);
        ReservEntry.SetTrackingFilterFromReservEntry(CalcReservEntry);
        ReservEntry.SetRange(Positive, Positive);
        if ReservEntry.FindSet then
            repeat
                ReservEntry.SetRange("Source Type", ReservEntry."Source Type");
                ReservEntry.SetRange("Source Subtype", ReservEntry."Source Subtype");
                ReservEntrySummary.Init;
                ReservEntrySummary."Entry No." := ReservEntry.SummEntryNo;
                ReservEntrySummary."Table ID" := ReservEntry."Source Type";
                ReservEntrySummary."Summary Type" :=
                  CopyStr(ReservEntry.TextCaption, 1, MaxStrLen(ReservEntrySummary."Summary Type"));
                ReservEntrySummary."Source Subtype" := ReservEntry."Source Subtype";
                ReservEntrySummary."Serial No." := ReservEntry."Serial No.";
                ReservEntrySummary."Lot No." := ReservEntry."Lot No.";
                if ReservEntry.FindSet then
                    repeat
                        ReservEntrySummary."Total Quantity" += ReservEntry."Quantity (Base)";
                        if ReservEntry."Reservation Status" = ReservEntry."Reservation Status"::Reservation then
                            ReservEntrySummary."Total Reserved Quantity" += ReservEntry."Quantity (Base)";
                        if CalcReservEntry.HasSamePointer(ReservEntry) then
                            ReservEntrySummary."Current Reserved Quantity" += ReservEntry."Quantity (Base)";
                    until ReservEntry.Next = 0;
                ReservEntrySummary."Total Available Quantity" :=
                  ReservEntrySummary."Total Quantity" - ReservEntrySummary."Total Reserved Quantity";
                OnUpdateItemTrackingLineStatsOnBeforeReservEntrySummaryInsert(ReservEntrySummary, ReservEntry);
                ReservEntrySummary.Insert;
                ReservEntry.SetRange("Source Type");
                ReservEntry.SetRange("Source Subtype");
            until ReservEntry.Next = 0;
    end;

    procedure AutoReserve(var FullAutoReservation: Boolean; Description: Text[100]; AvailabilityDate: Date; MaxQtyToReserve: Decimal; MaxQtyToReserveBase: Decimal)
    var
        RemainingQtyToReserve: Decimal;
        RemainingQtyToReserveBase: Decimal;
        i: Integer;
        StopReservation: Boolean;
    begin
        CalcReservEntry.TestField("Source Type");

        if CalcReservEntry."Source Type" in [DATABASE::"Sales Line", DATABASE::"Purchase Line", DATABASE::"Service Line"] then
            StopReservation := not (CalcReservEntry."Source Subtype" in [1, 5]); // Only order and return order

        if CalcReservEntry."Source Type" in [DATABASE::"Assembly Line", DATABASE::"Assembly Header"] then
            StopReservation := not (CalcReservEntry."Source Subtype" = 1); // Only Assembly Order

        if CalcReservEntry."Source Type" in [DATABASE::"Prod. Order Line", DATABASE::"Prod. Order Component"]
        then
            StopReservation := CalcReservEntry."Source Subtype" < 2; // Not simulated or planned

        if CalcReservEntry."Source Type" = DATABASE::"Sales Line" then
            if (CalcReservEntry."Source Subtype" = 1) and (ForSalesLine.Quantity < 0) then
                StopReservation := true;

        if CalcReservEntry."Source Type" = DATABASE::"Sales Line" then
            if (CalcReservEntry."Source Subtype" = 5) and (ForSalesLine.Quantity >= 0) then
                StopReservation := true;

        if StopReservation then begin
            FullAutoReservation := true;
            exit;
        end;

        CalculateRemainingQty(RemainingQtyToReserve, RemainingQtyToReserveBase);
        if (MaxQtyToReserveBase <> 0) and (Abs(MaxQtyToReserveBase) < Abs(RemainingQtyToReserveBase)) then begin
            RemainingQtyToReserve := MaxQtyToReserve;
            RemainingQtyToReserveBase := MaxQtyToReserveBase;
        end;

        if (RemainingQtyToReserveBase <> 0) and
           HandleItemTracking and
           ItemTrackingCode."SN Specific Tracking"
        then
            RemainingQtyToReserveBase := 1;
        FullAutoReservation := false;

        if RemainingQtyToReserveBase = 0 then begin
            FullAutoReservation := true;
            exit;
        end;

        for i := 1 to SetValueArray(0) do
            AutoReserveOneLine(ValueArray[i], RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate);

        FullAutoReservation := (RemainingQtyToReserveBase = 0);

        OnAfterAutoReserve(CalcReservEntry, FullAutoReservation);
    end;

    procedure AutoReserveOneLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date)
    var
        Item: Record Item;
        Search: Text[1];
        NextStep: Integer;
    begin
        CalcReservEntry.TestField("Source Type");

        if RemainingQtyToReserveBase = 0 then
            exit;

        if not Item.Get(CalcReservEntry."Item No.") then
            Clear(Item);

        CalcReservEntry.Lock;

        if Positive then begin
            Search := '+';
            NextStep := -1;
            if Item."Costing Method" = Item."Costing Method"::LIFO then begin
                InvSearch := '+';
                InvNextStep := -1;
            end else begin
                InvSearch := '-';
                InvNextStep := 1;
            end;
        end else begin
            Search := '-';
            NextStep := 1;
            InvSearch := '-';
            InvNextStep := 1;
        end;

        case ReservSummEntryNo of
            1: // Item Ledger Entry
                AutoReserveItemLedgEntry(
                  ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate);
            12,
          16: // Purchase Line, Purchase Return Line
                AutoReservePurchLine(
                  ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate, Search, NextStep);
            21: // Requisition Line
                AutoReserveReqLine(ReservSummEntryNo, AvailabilityDate);
            31,
          32,
          36: // Sales Line, Sales Return Line
                AutoReserveSalesLine(
                  ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate, Search, NextStep);
            61,
          62,
          63,
          64: // Prod. Order
                AutoReserveProdOrderLine(
                  ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate, Search, NextStep);
            71,
          72,
          73,
          74: // Prod. Order Component
                AutoReserveProdOrderComp(
                  ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate, Search, NextStep);
            91: // Planning Component
                AutoReservePlanningComp(ReservSummEntryNo, AvailabilityDate);
            101,
          102: // Transfer
                AutoReserveTransLine(
                  ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate, Search, NextStep);
            110: // Service Line Order
                AutoReserveServLine(
                  ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate, Search, NextStep);
            133: // Job Planning Line Order
                AutoReserveJobPlanningLine(
                  ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate, Search, NextStep);
            142: // Assembly Header
                AutoReserveAssemblyHeader(
                  ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate, Search, NextStep);
            152: // Assembly Line
                AutoReserveAssemblyLine(
                  ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate, Search, NextStep);
            else
                OnAfterAutoReserveOneLine(
                  ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate, Search, NextStep);
        end;
    end;

    local procedure AutoReserveItemLedgEntry(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date)
    var
        Location: Record Location;
        LateBindingMgt: Codeunit "Late Binding Management";
        AllocationsChanged: Boolean;
        QtyThisLine: Decimal;
        QtyThisLineBase: Decimal;
        IsReserved: Boolean;
        IsHandled: Boolean;
        IsFound: Boolean;
    begin
        IsReserved := false;
        OnBeforeAutoReserveItemLedgEntry(
          ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserve, Description, AvailabilityDate, IsReserved, CalcReservEntry);
        if IsReserved then
            exit;

        if not Location.Get(CalcReservEntry."Location Code") then
            Clear(Location);

        InitFilter(ReservSummEntryNo, AvailabilityDate);
        // Late Binding
        if HandleItemTracking then
            AllocationsChanged :=
              LateBindingMgt.ReleaseForReservation(CalcItemLedgEntry, CalcReservEntry, RemainingQtyToReserveBase);

        IsFound := false;
        IsHandled := false;
        OnAutoReserveItemLedgEntryOnFindFirstItemLedgEntry(CalcReservEntry, CalcItemLedgEntry, InvSearch, IsHandled, IsFound);
        if not IsHandled then
            IsFound := CalcItemLedgEntry.Find(InvSearch);
        if IsFound then begin
            if Location."Bin Mandatory" or Location."Require Pick" then begin
                QtyOnOutBound :=
                  CreatePick.CheckOutBound(
                    CalcReservEntry."Source Type", CalcReservEntry."Source Subtype",
                    CalcReservEntry."Source ID", CalcReservEntry."Source Ref. No.",
                    CalcReservEntry."Source Prod. Order Line") -
                  CalcCurrLineReservQtyOnPicksShips(CalcReservEntry);
                if AllocationsChanged then
                    CalcReservedQtyOnPick(TotalAvailQty, QtyAllocInWhse); // If allocations have changed we must recalculate
            end;
            repeat
                CalcItemLedgEntry.CalcFields("Reserved Quantity");
                if (CalcItemLedgEntry."Remaining Quantity" -
                    CalcItemLedgEntry."Reserved Quantity") <> 0
                then begin
                    if Abs(CalcItemLedgEntry."Remaining Quantity" -
                         CalcItemLedgEntry."Reserved Quantity") > Abs(RemainingQtyToReserveBase)
                    then begin
                        QtyThisLine := Abs(RemainingQtyToReserve);
                        QtyThisLineBase := Abs(RemainingQtyToReserveBase);
                    end else begin
                        QtyThisLineBase :=
                          CalcItemLedgEntry."Remaining Quantity" - CalcItemLedgEntry."Reserved Quantity";
                        QtyThisLine := 0;
                    end;
                    if IsSpecialOrder(CalcItemLedgEntry."Purchasing Code") or (Positive = (QtyThisLineBase < 0)) then begin
                        QtyThisLineBase := 0;
                        QtyThisLine := 0;
                    end;

                    if (Location."Bin Mandatory" or Location."Require Pick") and
                       (TotalAvailQty + QtyOnOutBound < QtyThisLineBase)
                    then
                        if (TotalAvailQty + QtyOnOutBound) < 0 then begin
                            QtyThisLineBase := 0;
                            QtyThisLine := 0
                        end else begin
                            QtyThisLineBase := TotalAvailQty + QtyOnOutBound;
                            QtyThisLine := Round(QtyThisLineBase, UOMMgt.QtyRndPrecision);
                        end;

                    OnAfterCalcReservation(CalcReservEntry, CalcItemLedgEntry, ReservSummEntryNo, QtyThisLine, QtyThisLineBase);

                    CallTrackingSpecification.InitTrackingSpecification(
                      DATABASE::"Item Ledger Entry", 0, '', '', 0, CalcItemLedgEntry."Entry No.",
                      CalcItemLedgEntry."Variant Code", CalcItemLedgEntry."Location Code",
                      CalcItemLedgEntry."Serial No.", CalcItemLedgEntry."Lot No.",
                      CalcItemLedgEntry."Qty. per Unit of Measure");

                    if CallCreateReservation(RemainingQtyToReserve, RemainingQtyToReserveBase, 0,
                         Description, 0D, QtyThisLine, QtyThisLineBase, CallTrackingSpecification)
                    then
                        if Location."Bin Mandatory" or Location."Require Pick" then
                            TotalAvailQty := TotalAvailQty - QtyThisLineBase;
                end;

                IsHandled := false;
                IsFound := false;
                OnAutoReserveItemLedgEntryOnFindNextItemLedgEntry(CalcReservEntry, CalcItemLedgEntry, InvSearch, IsHandled, IsFound);
                if not IsHandled then
                    IsFound := CalcItemLedgEntry.Next(InvNextStep) <> 0;
            until not IsFound or (RemainingQtyToReserveBase = 0);
        end;
    end;

    local procedure AutoReservePurchLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer)
    var
        QtyThisLine: Decimal;
        QtyThisLineBase: Decimal;
        ReservQty: Decimal;
        IsReserved: Boolean;
    begin
        IsReserved := false;
        OnBeforeAutoReservePurchLine(
          ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserve, Description, AvailabilityDate, IsReserved, Search, NextStep);
        if IsReserved then
            exit;

        InitFilter(ReservSummEntryNo, AvailabilityDate);
        if CalcPurchLine.Find(Search) then
            repeat
                CalcPurchLine.CalcFields("Reserved Qty. (Base)");
                if not CalcPurchLine."Special Order" then begin
                    QtyThisLine := CalcPurchLine."Outstanding Quantity";
                    QtyThisLineBase := CalcPurchLine."Outstanding Qty. (Base)";
                end;
                if ReservSummEntryNo = 16 then // Return Order
                    ReservQty := -CalcPurchLine."Reserved Qty. (Base)"
                else
                    ReservQty := CalcPurchLine."Reserved Qty. (Base)";
                if (Positive = (QtyThisLineBase < 0)) and (ReservSummEntryNo <> 16) or
                   (Positive = (QtyThisLineBase > 0)) and (ReservSummEntryNo = 16)
                then begin
                    QtyThisLine := 0;
                    QtyThisLineBase := 0;
                end;

                NarrowQtyToReserveDownToTrackedQuantity(
                  CalcReservEntry, CalcPurchLine.RowID1, QtyThisLine, QtyThisLineBase);

                CallTrackingSpecification.InitTrackingSpecification(
                  DATABASE::"Purchase Line", CalcPurchLine."Document Type", CalcPurchLine."Document No.", '',
                  0, CalcPurchLine."Line No.",
                  CalcPurchLine."Variant Code", CalcPurchLine."Location Code",
                  CalcReservEntry."Serial No.", CalcReservEntry."Lot No.",
                  CalcPurchLine."Qty. per Unit of Measure");

                CallCreateReservation(RemainingQtyToReserve, RemainingQtyToReserveBase, ReservQty,
                  Description, CalcPurchLine."Expected Receipt Date", QtyThisLine, QtyThisLineBase, CallTrackingSpecification);
            until (CalcPurchLine.Next(NextStep) = 0) or (RemainingQtyToReserveBase = 0);
    end;

    local procedure AutoReserveReqLine(ReservSummEntryNo: Integer; AvailabilityDate: Date)
    begin
        InitFilter(ReservSummEntryNo, AvailabilityDate);
    end;

    local procedure AutoReserveSalesLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer)
    var
        QtyThisLine: Decimal;
        QtyThisLineBase: Decimal;
        ReservQty: Decimal;
        IsReserved: Boolean;
    begin
        IsReserved := false;
        OnBeforeAutoReserveSalesLine(
          ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserve, Description, AvailabilityDate, IsReserved, Search, NextStep);
        if IsReserved then
            exit;

        InitFilter(ReservSummEntryNo, AvailabilityDate);
        if CalcSalesLine.Find(Search) then
            repeat
                CalcSalesLine.CalcFields("Reserved Qty. (Base)");
                QtyThisLine := CalcSalesLine."Outstanding Quantity";
                QtyThisLineBase := CalcSalesLine."Outstanding Qty. (Base)";
                if ReservSummEntryNo = 36 then // Return Order
                    ReservQty := -CalcSalesLine."Reserved Qty. (Base)"
                else
                    ReservQty := CalcSalesLine."Reserved Qty. (Base)";
                if (Positive = (QtyThisLineBase > 0)) and (ReservSummEntryNo <> 36) or
                   (Positive = (QtyThisLineBase < 0)) and (ReservSummEntryNo = 36)
                then begin
                    QtyThisLine := 0;
                    QtyThisLineBase := 0;
                end;

                NarrowQtyToReserveDownToTrackedQuantity(
                  CalcReservEntry, CalcSalesLine.RowID1, QtyThisLine, QtyThisLineBase);

                CallTrackingSpecification.InitTrackingSpecification(
                  DATABASE::"Sales Line", CalcSalesLine."Document Type", CalcSalesLine."Document No.", '',
                  0, CalcSalesLine."Line No.", CalcSalesLine."Variant Code", CalcSalesLine."Location Code",
                  CalcReservEntry."Serial No.", CalcReservEntry."Lot No.",
                  CalcSalesLine."Qty. per Unit of Measure");

                CallCreateReservation(RemainingQtyToReserve, RemainingQtyToReserveBase, ReservQty,
                  Description, CalcSalesLine."Shipment Date", QtyThisLine, QtyThisLineBase, CallTrackingSpecification);
            until (CalcSalesLine.Next(NextStep) = 0) or (RemainingQtyToReserveBase = 0);
    end;

    local procedure AutoReserveProdOrderLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer)
    var
        QtyThisLine: Decimal;
        QtyThisLineBase: Decimal;
        ReservQty: Decimal;
        IsReserved: Boolean;
    begin
        IsReserved := false;
        OnBeforeAutoReserveProdOrderLine(
          ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserve, Description, AvailabilityDate, IsReserved, Search, NextStep);
        if IsReserved then
            exit;

        InitFilter(ReservSummEntryNo, AvailabilityDate);
        if CalcProdOrderLine.Find(Search) then
            repeat
                CalcProdOrderLine.CalcFields("Reserved Qty. (Base)");
                QtyThisLine := CalcProdOrderLine."Remaining Quantity";
                QtyThisLineBase := CalcProdOrderLine."Remaining Qty. (Base)";
                ReservQty := CalcProdOrderLine."Reserved Qty. (Base)";
                if Positive = (QtyThisLineBase < 0) then begin
                    QtyThisLine := 0;
                    QtyThisLineBase := 0;
                end;

                NarrowQtyToReserveDownToTrackedQuantity(
                  CalcReservEntry, CalcProdOrderLine.RowID1, QtyThisLine, QtyThisLineBase);

                CallTrackingSpecification.InitTrackingSpecification(
                  DATABASE::"Prod. Order Line", CalcProdOrderLine.Status, CalcProdOrderLine."Prod. Order No.", '',
                  CalcProdOrderLine."Line No.", 0, CalcProdOrderLine."Variant Code", CalcProdOrderLine."Location Code",
                  CalcReservEntry."Serial No.", CalcReservEntry."Lot No.",
                  CalcProdOrderLine."Qty. per Unit of Measure");

                CallCreateReservation(RemainingQtyToReserve, RemainingQtyToReserveBase, ReservQty,
                  Description, CalcProdOrderLine."Due Date", QtyThisLine, QtyThisLineBase, CallTrackingSpecification);
            until (CalcProdOrderLine.Next(NextStep) = 0) or (RemainingQtyToReserveBase = 0);
    end;

    local procedure AutoReserveProdOrderComp(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer)
    var
        QtyThisLine: Decimal;
        QtyThisLineBase: Decimal;
        ReservQty: Decimal;
        IsReserved: Boolean;
    begin
        IsReserved := false;
        OnBeforeAutoReserveProdOrderComp(
          ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserve, Description, AvailabilityDate, IsReserved, Search, NextStep);
        if IsReserved then
            exit;

        InitFilter(ReservSummEntryNo, AvailabilityDate);
        if CalcProdOrderComp.Find(Search) then
            repeat
                CalcProdOrderComp.CalcFields("Reserved Qty. (Base)");
                QtyThisLine := CalcProdOrderComp."Remaining Quantity";
                QtyThisLineBase := CalcProdOrderComp."Remaining Qty. (Base)";
                ReservQty := CalcProdOrderComp."Reserved Qty. (Base)";
                if Positive = (QtyThisLineBase > 0) then begin
                    QtyThisLine := 0;
                    QtyThisLineBase := 0;
                end;

                NarrowQtyToReserveDownToTrackedQuantity(
                  CalcReservEntry, CalcProdOrderComp.RowID1, QtyThisLine, QtyThisLineBase);

                CallTrackingSpecification.InitTrackingSpecification(
                  DATABASE::"Prod. Order Component", CalcProdOrderComp.Status, CalcProdOrderComp."Prod. Order No.", '',
                  CalcProdOrderComp."Prod. Order Line No.", CalcProdOrderComp."Line No.",
                  CalcProdOrderComp."Variant Code", CalcProdOrderComp."Location Code",
                  CalcReservEntry."Serial No.", CalcReservEntry."Lot No.",
                  CalcProdOrderComp."Qty. per Unit of Measure");

                CallCreateReservation(RemainingQtyToReserve, RemainingQtyToReserveBase, ReservQty,
                  Description, CalcProdOrderComp."Due Date", QtyThisLine, QtyThisLineBase, CallTrackingSpecification);
            until (CalcProdOrderComp.Next(NextStep) = 0) or (RemainingQtyToReserveBase = 0);
    end;

    local procedure AutoReserveAssemblyHeader(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer)
    var
        QtyThisLine: Decimal;
        QtyThisLineBase: Decimal;
        ReservQty: Decimal;
        IsReserved: Boolean;
    begin
        IsReserved := false;
        OnBeforeAutoReserveAssemblyHeader(
          ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserve, Description, AvailabilityDate, IsReserved, Search, NextStep);
        if IsReserved then
            exit;

        InitFilter(ReservSummEntryNo, AvailabilityDate);
        if CalcAssemblyHeader.Find(Search) then
            repeat
                CalcAssemblyHeader.CalcFields("Reserved Qty. (Base)");
                QtyThisLine := CalcAssemblyHeader."Remaining Quantity";
                QtyThisLineBase := CalcAssemblyHeader."Remaining Quantity (Base)";
                ReservQty := CalcAssemblyHeader."Reserved Qty. (Base)";
                if Positive = (QtyThisLineBase < 0) then begin
                    QtyThisLine := 0;
                    QtyThisLineBase := 0;
                end;

                NarrowQtyToReserveDownToTrackedQuantity(
                  CalcReservEntry, CalcAssemblyHeader.RowID1, QtyThisLine, QtyThisLineBase);

                CallTrackingSpecification.InitTrackingSpecification(
                  DATABASE::"Assembly Header", CalcAssemblyHeader."Document Type", CalcAssemblyHeader."No.", '',
                  0, 0, CalcAssemblyHeader."Variant Code", CalcAssemblyHeader."Location Code",
                  CalcReservEntry."Serial No.", CalcReservEntry."Lot No.",
                  CalcAssemblyHeader."Qty. per Unit of Measure");

                CallCreateReservation(RemainingQtyToReserve, RemainingQtyToReserveBase, ReservQty,
                  Description, CalcAssemblyHeader."Due Date", QtyThisLine, QtyThisLineBase, CallTrackingSpecification);
            until (CalcAssemblyHeader.Next(NextStep) = 0) or (RemainingQtyToReserveBase = 0);
    end;

    local procedure AutoReserveAssemblyLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer)
    var
        QtyThisLine: Decimal;
        QtyThisLineBase: Decimal;
        ReservQty: Decimal;
        IsReserved: Boolean;
    begin
        IsReserved := false;
        OnBeforeAutoReserveAssemblyLine(
          ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserve, Description, AvailabilityDate, IsReserved, Search, NextStep);
        if IsReserved then
            exit;

        InitFilter(ReservSummEntryNo, AvailabilityDate);
        if CalcAssemblyLine.Find(Search) then
            repeat
                CalcAssemblyLine.CalcFields("Reserved Qty. (Base)");
                QtyThisLine := CalcAssemblyLine."Remaining Quantity";
                QtyThisLineBase := CalcAssemblyLine."Remaining Quantity (Base)";
                ReservQty := CalcAssemblyLine."Reserved Qty. (Base)";
                if Positive = (QtyThisLineBase > 0) then begin
                    QtyThisLine := 0;
                    QtyThisLineBase := 0;
                end;

                NarrowQtyToReserveDownToTrackedQuantity(
                  CalcReservEntry, CalcAssemblyLine.RowID1, QtyThisLine, QtyThisLineBase);

                CallTrackingSpecification.InitTrackingSpecification(
                  DATABASE::"Assembly Line", CalcAssemblyLine."Document Type", CalcAssemblyLine."Document No.", '',
                  0, CalcAssemblyLine."Line No.", CalcAssemblyLine."Variant Code", CalcAssemblyLine."Location Code",
                  CalcReservEntry."Serial No.", CalcReservEntry."Lot No.",
                  CalcAssemblyLine."Qty. per Unit of Measure");

                CallCreateReservation(RemainingQtyToReserve, RemainingQtyToReserveBase, ReservQty,
                  Description, CalcAssemblyLine."Due Date", QtyThisLine, QtyThisLineBase, CallTrackingSpecification);
            until (CalcAssemblyLine.Next(NextStep) = 0) or (RemainingQtyToReserveBase = 0);
    end;

    local procedure AutoReservePlanningComp(ReservSummEntryNo: Integer; AvailabilityDate: Date)
    begin
        InitFilter(ReservSummEntryNo, AvailabilityDate);
    end;

    local procedure AutoReserveTransLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer)
    var
        QtyThisLine: Decimal;
        QtyThisLineBase: Decimal;
        ReservQty: Decimal;
        LocationCode: Code[10];
        EntryDate: Date;
        IsReserved: Boolean;
    begin
        IsReserved := false;
        OnBeforeAutoReserveTransLine(
          ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserve, Description, AvailabilityDate, IsReserved, Search, NextStep);
        if IsReserved then
            exit;

        InitFilter(ReservSummEntryNo, AvailabilityDate);
        if CalcTransLine.Find(Search) then
            repeat
                case ReservSummEntryNo of
                    101: // Outbound
                        begin
                            CalcTransLine.CalcFields("Reserved Qty. Outbnd. (Base)");
                            QtyThisLine := -CalcTransLine."Outstanding Quantity";
                            QtyThisLineBase := -CalcTransLine."Outstanding Qty. (Base)";
                            ReservQty := -CalcTransLine."Reserved Qty. Outbnd. (Base)";
                            EntryDate := CalcTransLine."Shipment Date";
                            LocationCode := CalcTransLine."Transfer-from Code";
                            if Positive = (QtyThisLineBase < 0) then begin
                                QtyThisLine := 0;
                                QtyThisLineBase := 0;
                            end;
                            NarrowQtyToReserveDownToTrackedQuantity(
                              CalcReservEntry, CalcTransLine.RowID1(0), QtyThisLine, QtyThisLineBase);
                        end;
                    102: // Inbound
                        begin
                            CalcTransLine.CalcFields("Reserved Qty. Inbnd. (Base)");
                            QtyThisLine := CalcTransLine."Outstanding Quantity";
                            QtyThisLineBase := CalcTransLine."Outstanding Qty. (Base)";
                            ReservQty := CalcTransLine."Reserved Qty. Inbnd. (Base)";
                            EntryDate := CalcTransLine."Receipt Date";
                            LocationCode := CalcTransLine."Transfer-to Code";
                            if Positive = (QtyThisLineBase < 0) then begin
                                QtyThisLine := 0;
                                QtyThisLineBase := 0;
                            end;
                            NarrowQtyToReserveDownToTrackedQuantity(
                              CalcReservEntry, CalcTransLine.RowID1(1), QtyThisLine, QtyThisLineBase);
                        end;
                end;

                CallTrackingSpecification.InitTrackingSpecification(
                  DATABASE::"Transfer Line", ReservSummEntryNo - 101, CalcTransLine."Document No.", '',
                  CalcTransLine."Derived From Line No.", CalcTransLine."Line No.",
                  CalcTransLine."Variant Code", LocationCode,
                  CalcReservEntry."Serial No.", CalcReservEntry."Lot No.",
                  CalcTransLine."Qty. per Unit of Measure");

                CallCreateReservation(RemainingQtyToReserve, RemainingQtyToReserveBase, ReservQty,
                  Description, EntryDate, QtyThisLine, QtyThisLineBase, CallTrackingSpecification);
            until (CalcTransLine.Next(NextStep) = 0) or (RemainingQtyToReserveBase = 0);
    end;

    local procedure AutoReserveServLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer)
    var
        QtyThisLine: Decimal;
        QtyThisLineBase: Decimal;
        ReservQty: Decimal;
        IsReserved: Boolean;
    begin
        IsReserved := false;
        OnBeforeAutoReserveServLine(
          ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserve, Description, AvailabilityDate, IsReserved, Search, NextStep);
        if IsReserved then
            exit;

        InitFilter(ReservSummEntryNo, AvailabilityDate);
        if CalcServiceLine.Find(Search) then
            repeat
                CalcServiceLine.CalcFields("Reserved Qty. (Base)");
                QtyThisLine := CalcServiceLine."Outstanding Quantity";
                QtyThisLineBase := CalcServiceLine."Outstanding Qty. (Base)";
                ReservQty := CalcServiceLine."Reserved Qty. (Base)";
                if Positive = (QtyThisLineBase > 0) then begin
                    QtyThisLine := 0;
                    QtyThisLineBase := 0;
                end;

                NarrowQtyToReserveDownToTrackedQuantity(
                  CalcReservEntry, CalcServiceLine.RowID1, QtyThisLine, QtyThisLineBase);

                CallTrackingSpecification.InitTrackingSpecification(
                  DATABASE::"Service Line", CalcServiceLine."Document Type", CalcServiceLine."Document No.", '',
                  0, CalcServiceLine."Line No.", CalcServiceLine."Variant Code", CalcServiceLine."Location Code",
                  CalcReservEntry."Serial No.", CalcReservEntry."Lot No.",
                  CalcServiceLine."Qty. per Unit of Measure");

                CallCreateReservation(RemainingQtyToReserve, RemainingQtyToReserveBase, ReservQty,
                  Description, CalcServiceLine."Needed by Date", QtyThisLine, QtyThisLineBase, CallTrackingSpecification);
            until (CalcServiceLine.Next(NextStep) = 0) or (RemainingQtyToReserveBase = 0);
    end;

    local procedure AutoReserveJobPlanningLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer)
    var
        QtyThisLine: Decimal;
        QtyThisLineBase: Decimal;
        ReservQty: Decimal;
        IsReserved: Boolean;
    begin
        IsReserved := false;
        OnBeforeAutoReserveJobPlanningLine(
          ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserve, Description, AvailabilityDate, IsReserved, Search, NextStep);
        if IsReserved then
            exit;

        InitFilter(ReservSummEntryNo, AvailabilityDate);
        if CalcJobPlanningLine.Find(Search) then
            repeat
                CalcJobPlanningLine.CalcFields("Reserved Qty. (Base)");
                QtyThisLine := CalcJobPlanningLine."Remaining Qty.";
                QtyThisLineBase := CalcJobPlanningLine."Remaining Qty. (Base)";
                ReservQty := CalcJobPlanningLine."Reserved Qty. (Base)";
                if Positive = (QtyThisLineBase > 0) then begin
                    QtyThisLine := 0;
                    QtyThisLineBase := 0;
                end;

                CallTrackingSpecification.InitTrackingSpecification(
                  DATABASE::"Job Planning Line", CalcJobPlanningLine.Status, CalcJobPlanningLine."Job No.", '',
                  0, CalcJobPlanningLine."Job Contract Entry No.",
                  CalcJobPlanningLine."Variant Code", CalcJobPlanningLine."Location Code",
                  CalcReservEntry."Serial No.", CalcReservEntry."Lot No.",
                  CalcJobPlanningLine."Qty. per Unit of Measure");

                CallCreateReservation(RemainingQtyToReserve, RemainingQtyToReserveBase, ReservQty,
                  Description, CalcJobPlanningLine."Planning Date", QtyThisLine, QtyThisLineBase, CallTrackingSpecification);
            until (CalcJobPlanningLine.Next(NextStep) = 0) or (RemainingQtyToReserveBase = 0);
    end;

    local procedure CallCreateReservation(var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; ReservQty: Decimal; Description: Text[100]; ExpectedDate: Date; QtyThisLine: Decimal; QtyThisLineBase: Decimal; TrackingSpecification: Record "Tracking Specification") ReservationCreated: Boolean
    begin
        if QtyThisLineBase = 0 then
            exit;
        if Abs(QtyThisLineBase - ReservQty) > 0 then begin
            if Abs(QtyThisLineBase - ReservQty) > Abs(RemainingQtyToReserveBase) then begin
                QtyThisLine := RemainingQtyToReserve;
                QtyThisLineBase := RemainingQtyToReserveBase;
            end else begin
                QtyThisLineBase := QtyThisLineBase - ReservQty;
                QtyThisLine := Round(RemainingQtyToReserve / RemainingQtyToReserveBase * QtyThisLineBase, UOMMgt.QtyRndPrecision);
            end;
            CopySign(RemainingQtyToReserveBase, QtyThisLineBase);
            CopySign(RemainingQtyToReserve, QtyThisLine);
            CreateReservation(Description, ExpectedDate, QtyThisLine, QtyThisLineBase, TrackingSpecification);
            RemainingQtyToReserve := RemainingQtyToReserve - QtyThisLine;
            RemainingQtyToReserveBase := RemainingQtyToReserveBase - QtyThisLineBase;
            ReservationCreated := true;
        end;
    end;

    procedure CreateReservation(Description: Text[100]; ExpectedDate: Date; Quantity: Decimal; QuantityBase: Decimal; TrackingSpecification: Record "Tracking Specification")
    begin
        CalcReservEntry.TestField("Source Type");

        OnBeforeCreateReservation(TrackingSpecification, CalcReservEntry, CalcItemLedgEntry);

        case CalcReservEntry."Source Type" of
            DATABASE::"Sales Line":
                begin
                    ReserveSalesLine.CreateReservationSetFrom(TrackingSpecification);
                    ReserveSalesLine.CreateReservation(
                      ForSalesLine, Description, ExpectedDate, Quantity, QuantityBase,
                      CalcReservEntry."Serial No.", CalcReservEntry."Lot No.");
                    ForSalesLine.CalcFields("Reserved Qty. (Base)");
                end;
            DATABASE::"Requisition Line":
                begin
                    ReserveReqLine.CreateReservationSetFrom(TrackingSpecification);
                    ReserveReqLine.CreateReservation(
                      ForReqLine, Description, ExpectedDate, Quantity, QuantityBase,
                      CalcReservEntry."Serial No.", CalcReservEntry."Lot No.");
                    ForReqLine.CalcFields("Reserved Qty. (Base)");
                end;
            DATABASE::"Purchase Line":
                begin
                    ReservePurchLine.CreateReservationSetFrom(TrackingSpecification);
                    ReservePurchLine.CreateReservation(
                      ForPurchLine, Description, ExpectedDate, Quantity, QuantityBase,
                      CalcReservEntry."Serial No.", CalcReservEntry."Lot No.");
                    ForPurchLine.CalcFields("Reserved Qty. (Base)");
                end;
            DATABASE::"Item Journal Line":
                begin
                    ReserveItemJnlLine.CreateReservationSetFrom(TrackingSpecification);
                    ReserveItemJnlLine.CreateReservation(
                      ForItemJnlLine, Description, ExpectedDate, Quantity, QuantityBase,
                      CalcReservEntry."Serial No.", CalcReservEntry."Lot No.");
                    ForItemJnlLine.CalcFields("Reserved Qty. (Base)");
                end;
            DATABASE::"Prod. Order Line":
                begin
                    ReserveProdOrderLine.CreateReservationSetFrom(TrackingSpecification);
                    ReserveProdOrderLine.CreateReservation(
                      ForProdOrderLine, Description, ExpectedDate, Quantity, QuantityBase,
                      CalcReservEntry."Serial No.", CalcReservEntry."Lot No.");
                    ForProdOrderLine.CalcFields("Reserved Qty. (Base)");
                end;
            DATABASE::"Prod. Order Component":
                begin
                    ReserveProdOrderComp.CreateReservationSetFrom(TrackingSpecification);
                    ReserveProdOrderComp.CreateReservation(
                      ForProdOrderComp, Description, ExpectedDate, Quantity, QuantityBase,
                      CalcReservEntry."Serial No.", CalcReservEntry."Lot No.");
                    ForProdOrderComp.CalcFields("Reserved Qty. (Base)");
                end;
            DATABASE::"Assembly Header":
                begin
                    AssemblyHeaderReserve.CreateReservationSetFrom(TrackingSpecification);
                    AssemblyHeaderReserve.CreateReservation(
                      ForAssemblyHeader, Description, ExpectedDate, Quantity, QuantityBase,
                      CalcReservEntry."Serial No.", CalcReservEntry."Lot No.");
                    ForAssemblyHeader.CalcFields("Reserved Qty. (Base)");
                end;
            DATABASE::"Assembly Line":
                begin
                    AssemblyLineReserve.CreateReservationSetFrom(TrackingSpecification);
                    AssemblyLineReserve.CreateReservation(
                      ForAssemblyLine, Description, ExpectedDate, Quantity, QuantityBase,
                      CalcReservEntry."Serial No.", CalcReservEntry."Lot No.");
                    ForAssemblyLine.CalcFields("Reserved Qty. (Base)");
                end;
            DATABASE::"Planning Component":
                begin
                    ReservePlanningComponent.CreateReservationSetFrom(TrackingSpecification);
                    ReservePlanningComponent.CreateReservation(
                      ForPlanningComponent, Description, ExpectedDate, Quantity, QuantityBase,
                      CalcReservEntry."Serial No.", CalcReservEntry."Lot No.");
                    ForPlanningComponent.CalcFields("Reserved Qty. (Base)");
                end;
            DATABASE::"Transfer Line":
                begin
                    ReserveTransLine.CreateReservationSetFrom(TrackingSpecification);
                    ReserveTransLine.CreateReservation(
                      ForTransLine, Description, ExpectedDate, Quantity, QuantityBase,
                      CalcReservEntry."Serial No.", CalcReservEntry."Lot No.",
                      CalcReservEntry."Source Subtype");
                    ForTransLine.CalcFields("Reserved Qty. Outbnd. (Base)");
                    ForTransLine.CalcFields("Reserved Qty. Inbnd. (Base)");
                end;
            DATABASE::"Service Line":
                begin
                    ReserveServiceInvLine.CreateReservationSetFrom(TrackingSpecification);
                    ReserveServiceInvLine.CreateReservation(
                      ForServiceLine, Description, ExpectedDate, Quantity, QuantityBase,
                      CalcReservEntry."Serial No.", CalcReservEntry."Lot No.");
                    ForServiceLine.CalcFields("Reserved Qty. (Base)");
                end;
            DATABASE::"Job Planning Line":
                begin
                    JobPlanningLineReserve.CreateReservationSetFrom(TrackingSpecification);
                    JobPlanningLineReserve.CreateReservation(
                      ForJobPlanningLine, Description, ExpectedDate, Quantity, QuantityBase,
                      CalcReservEntry."Serial No.", CalcReservEntry."Lot No.");
                    ForJobPlanningLine.CalcFields("Reserved Qty. (Base)");
                end;
        end;
    end;

    procedure DeleteReservEntries(DeleteAll: Boolean; DownToQuantity: Decimal)
    var
        CalcReservEntry4: Record "Reservation Entry";
        TrackingMgt: Codeunit OrderTrackingManagement;
        ReservMgt: Codeunit "Reservation Management";
        QtyToReTrack: Decimal;
        QtyTracked: Decimal;
    begin
        DeleteReservEntries(DeleteAll, DownToQuantity, CalcReservEntry2);

        // Handle both sides of a req. line related to a transfer line:
        if ((CalcReservEntry."Source Type" = DATABASE::"Requisition Line") and
            (ForReqLine."Ref. Order Type" = ForReqLine."Ref. Order Type"::Transfer))
        then begin
            CalcReservEntry4 := CalcReservEntry;
            CalcReservEntry4."Source Subtype" := 1;
            CalcReservEntry4.SetPointerFilter;
            DeleteReservEntries(DeleteAll, DownToQuantity, CalcReservEntry4);
        end;

        if DeleteAll then
            if ((CalcReservEntry."Source Type" = DATABASE::"Requisition Line") and
                (ForReqLine."Planning Line Origin" <> ForReqLine."Planning Line Origin"::" ")) or
               (CalcReservEntry."Source Type" = DATABASE::"Planning Component")
            then begin
                CalcReservEntry4.Reset;
                if TrackingMgt.DerivePlanningFilter(CalcReservEntry2, CalcReservEntry4) then
                    if CalcReservEntry4.FindFirst then begin
                        QtyToReTrack := ReservMgt.SourceQuantity(CalcReservEntry4, true);
                        CalcReservEntry4.SetRange("Reservation Status", CalcReservEntry4."Reservation Status"::Reservation);
                        if not CalcReservEntry4.IsEmpty then begin
                            CalcReservEntry4.CalcSums("Quantity (Base)");
                            QtyTracked += CalcReservEntry4."Quantity (Base)";
                        end;
                        CalcReservEntry4.SetFilter("Reservation Status", '<>%1', CalcReservEntry4."Reservation Status"::Reservation);
                        CalcReservEntry4.SetFilter("Item Tracking", '<>%1', CalcReservEntry4."Item Tracking"::None);
                        if not CalcReservEntry4.IsEmpty then begin
                            CalcReservEntry4.CalcSums("Quantity (Base)");
                            QtyTracked += CalcReservEntry4."Quantity (Base)";
                        end;
                        if CalcReservEntry."Source Type" = DATABASE::"Planning Component" then
                            QtyTracked := -QtyTracked;
                        ReservMgt.DeleteReservEntries(QtyTracked = 0, QtyTracked);
                        ReservMgt.AutoTrack(QtyToReTrack);
                    end;
            end;
    end;

    procedure DeleteReservEntries(DeleteAll: Boolean; DownToQuantity: Decimal; var ReservEntry: Record "Reservation Entry")
    var
        CalcReservEntry4: Record "Reservation Entry";
        SurplusEntry: Record "Reservation Entry";
        DummyEntry: Record "Reservation Entry";
        Status: Option Reservation,Tracking,Surplus,Prospect;
        QtyToRelease: Decimal;
        QtyTracked: Decimal;
        QtyToReleaseForLotSN: Decimal;
        CurrentQty: Decimal;
        CurrentSerialNo: Code[50];
        CurrentLotNo: Code[50];
        AvailabilityDate: Date;
        Release: Option "Non-Inventory",Inventory;
        HandleItemTracking2: Boolean;
        SignFactor: Integer;
        QuantityIsValidated: Boolean;
    begin
        ReservEntry.SetRange("Reservation Status");
        if ReservEntry.IsEmpty then
            exit;
        CurrentSerialNo := ReservEntry."Serial No.";
        CurrentLotNo := ReservEntry."Lot No.";
        CurrentQty := ReservEntry."Quantity (Base)";

        GetItemSetup(ReservEntry);
        ReservEntry.TestField("Source Type");
        ReservEntry.Lock;
        SignFactor := CreateReservEntry.SignFactor(ReservEntry);
        QtyTracked := QuantityTracked(ReservEntry);
        CurrentBinding := ReservEntry.Binding;
        CurrentBindingIsSet := true;

        // Item Tracking:
        if ItemTrackingCode."SN Specific Tracking" or ItemTrackingCode."Lot Specific Tracking" or
           (CurrentSerialNo <> '') or (CurrentLotNo <> '')
        then begin
            ReservEntry.SetFilter("Item Tracking", '<>%1', ReservEntry."Item Tracking"::None);
            HandleItemTracking2 := not ReservEntry.IsEmpty;
            ReservEntry.SetRange("Item Tracking");
            case ItemTrackingHandling of
                ItemTrackingHandling::None:
                    ReservEntry.SetTrackingFilter('', '');
                ItemTrackingHandling::Match:
                    begin
                        if not ((CurrentSerialNo = '') and (CurrentLotNo = '')) then begin
                            QtyToReleaseForLotSN := QuantityTracked2(ReservEntry);
                            if Abs(QtyToReleaseForLotSN) > Abs(CurrentQty) then
                                QtyToReleaseForLotSN := CurrentQty;
                            DownToQuantity := (QtyTracked - QtyToReleaseForLotSN) * SignFactor;
                            ReservEntry.SetTrackingFilter(CurrentSerialNo, CurrentLotNo);
                        end else
                            DownToQuantity += CalcDownToQtySyncingToAssembly(ReservEntry);
                    end;
            end;
        end;

        if SignFactor * QtyTracked * DownToQuantity < 0 then
            DeleteAll := true
        else
            if Abs(QtyTracked) < Abs(DownToQuantity) then
                exit;

        QtyToRelease := QtyTracked - (DownToQuantity * SignFactor);

        for Status := Status::Prospect downto Status::Reservation do begin
            ReservEntry.SetRange("Reservation Status", Status);
            if ReservEntry.FindSet and (QtyToRelease <> 0) then
                case Status of
                    Status::Prospect:
                    repeat
                        if (Abs(ReservEntry."Quantity (Base)") <= Abs(QtyToRelease)) or DeleteAll then begin
                            ReservEntry.Delete;
                            SaveTrackingSpecification(ReservEntry, ReservEntry."Quantity (Base)");
                            QtyToRelease := QtyToRelease - ReservEntry."Quantity (Base)";
                        end else begin
                            ReservEntry.Validate("Quantity (Base)", ReservEntry."Quantity (Base)" - QtyToRelease);
                            ReservEntry.Modify;
                            SaveTrackingSpecification(ReservEntry, QtyToRelease);
                            QtyToRelease := 0;
                        end;
                    until (ReservEntry.Next = 0) or ((not DeleteAll) and (QtyToRelease = 0));
                    Status::Surplus:
                    repeat
                        if CalcReservEntry4.Get(ReservEntry."Entry No.", not ReservEntry.Positive) then // Find related entry
                            Error(Text007);
                        if (Abs(ReservEntry."Quantity (Base)") <= Abs(QtyToRelease)) or DeleteAll then begin
                            ReservEngineMgt.CloseReservEntry(ReservEntry, false, DeleteAll);
                            SaveTrackingSpecification(ReservEntry, ReservEntry."Quantity (Base)");
                            QtyToRelease := QtyToRelease - ReservEntry."Quantity (Base)";
                            if not DeleteAll and CalcReservEntry4.TrackingExists then begin
                                CalcReservEntry4."Reservation Status" := CalcReservEntry4."Reservation Status"::Surplus;
                                CalcReservEntry4.Insert;
                            end;
                            ModifyActionMessage(ReservEntry."Entry No.", 0, true); // Delete action messages
                        end else begin
                            ReservEntry.Validate("Quantity (Base)", ReservEntry."Quantity (Base)" - QtyToRelease);
                            ReservEntry.Modify;
                            SaveTrackingSpecification(ReservEntry, QtyToRelease);
                            ModifyActionMessage(ReservEntry."Entry No.", QtyToRelease, false); // Modify action messages
                            QtyToRelease := 0;
                        end;
                    until (ReservEntry.Next = 0) or ((not DeleteAll) and (QtyToRelease = 0));
                    Status::Tracking, Status::Reservation:
                        for Release := Release::"Non-Inventory" to Release::Inventory do begin
                            // Release non-inventory reservations in first cycle
                            repeat
                                CalcReservEntry4.Get(ReservEntry."Entry No.", not ReservEntry.Positive); // Find related entry
                                if (Release = Release::Inventory) = (CalcReservEntry4."Source Type" = DATABASE::"Item Ledger Entry") then
                                    if (Abs(ReservEntry."Quantity (Base)") <= Abs(QtyToRelease)) or DeleteAll then begin
                                        ReservEngineMgt.CloseReservEntry(ReservEntry, false, DeleteAll);
                                        SaveTrackingSpecification(ReservEntry, ReservEntry."Quantity (Base)");
                                        QtyToRelease := QtyToRelease - ReservEntry."Quantity (Base)";
                                    end else begin
                                        ReservEntry.Validate("Quantity (Base)", ReservEntry."Quantity (Base)" - QtyToRelease);
                                        ReservEntry.Modify;
                                        SaveTrackingSpecification(ReservEntry, QtyToRelease);

                                        if Item."Order Tracking Policy" <> Item."Order Tracking Policy"::None then begin
                                            if CalcReservEntry4."Quantity (Base)" > 0 then
                                                AvailabilityDate := CalcReservEntry4."Shipment Date"
                                            else
                                                AvailabilityDate := CalcReservEntry4."Expected Receipt Date";

                                            QtyToRelease := -MatchSurplus(CalcReservEntry4, SurplusEntry, -QtyToRelease,
                                                CalcReservEntry4."Quantity (Base)" < 0, AvailabilityDate, Item."Order Tracking Policy");

                                            // Make residual surplus record:
                                            if QtyToRelease <> 0 then begin
                                                MakeConnection(CalcReservEntry4, CalcReservEntry4, -QtyToRelease, 2,
                                                  AvailabilityDate, CalcReservEntry4.Binding);
                                                if Item."Order Tracking Policy" = Item."Order Tracking Policy"::"Tracking & Action Msg." then begin
                                                    CreateReservEntry.GetLastEntry(SurplusEntry); // Get the surplus-entry just inserted
                                                    IssueActionMessage(SurplusEntry, false, DummyEntry);
                                                end;
                                            end;
                                        end else
                                            if ItemTrackingHandling = ItemTrackingHandling::None then
                                                QuantityIsValidated := SaveItemTrackingAsSurplus(CalcReservEntry4,
                                                    -ReservEntry.Quantity, -ReservEntry."Quantity (Base)");

                                        if not QuantityIsValidated then
                                            CalcReservEntry4.Validate("Quantity (Base)", -ReservEntry."Quantity (Base)");

                                        CalcReservEntry4.Modify;
                                        QtyToRelease := 0;
                                        QuantityIsValidated := false;
                                    end;
                            until (ReservEntry.Next = 0) or ((not DeleteAll) and (QtyToRelease = 0));
                            if not ReservEntry.FindFirst then // Rewind for second cycle
                                Release := Release::Inventory;
                        end;
                end;
        end;

        if HandleItemTracking2 then
            CheckQuantityIsCompletelyReleased(QtyToRelease, DeleteAll, CurrentSerialNo, CurrentLotNo, ReservEntry);
    end;

    procedure CalculateRemainingQty(var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    begin
        CalcReservEntry.TestField("Source Type");

        case CalcReservEntry."Source Type" of
            DATABASE::"Sales Line":
                begin
                    ForSalesLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
                    RemainingQty := ForSalesLine."Outstanding Quantity" - Abs(ForSalesLine."Reserved Quantity");
                    RemainingQtyBase := ForSalesLine."Outstanding Qty. (Base)" - Abs(ForSalesLine."Reserved Qty. (Base)");
                end;
            DATABASE::"Requisition Line":
                begin
                    ForReqLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
                    RemainingQty := 0;
                    RemainingQtyBase := ForReqLine."Net Quantity (Base)" - Abs(ForReqLine."Reserved Qty. (Base)");
                end;
            DATABASE::"Purchase Line":
                begin
                    ForPurchLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
                    RemainingQty := ForPurchLine."Outstanding Quantity" - Abs(ForPurchLine."Reserved Quantity");
                    RemainingQtyBase := ForPurchLine."Outstanding Qty. (Base)" - Abs(ForPurchLine."Reserved Qty. (Base)");
                end;
            DATABASE::"Prod. Order Line":
                begin
                    ForProdOrderLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
                    RemainingQty := ForProdOrderLine."Remaining Quantity" - Abs(ForProdOrderLine."Reserved Quantity");
                    RemainingQtyBase := ForProdOrderLine."Remaining Qty. (Base)" - Abs(ForProdOrderLine."Reserved Qty. (Base)");
                end;
            DATABASE::"Prod. Order Component":
                begin
                    ForProdOrderComp.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
                    RemainingQty := ForProdOrderComp."Remaining Quantity" - Abs(ForProdOrderComp."Reserved Quantity");
                    RemainingQtyBase := ForProdOrderComp."Remaining Qty. (Base)" - Abs(ForProdOrderComp."Reserved Qty. (Base)");
                end;
            DATABASE::"Assembly Header":
                begin
                    ForAssemblyHeader.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
                    RemainingQty := ForAssemblyHeader."Remaining Quantity" - Abs(ForAssemblyHeader."Reserved Quantity");
                    RemainingQtyBase := ForAssemblyHeader."Remaining Quantity (Base)" - Abs(ForAssemblyHeader."Reserved Qty. (Base)");
                end;
            DATABASE::"Assembly Line":
                begin
                    ForAssemblyLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
                    RemainingQty := ForAssemblyLine."Remaining Quantity" - Abs(ForAssemblyLine."Reserved Quantity");
                    RemainingQtyBase := ForAssemblyLine."Remaining Quantity (Base)" - Abs(ForAssemblyLine."Reserved Qty. (Base)");
                end;
            DATABASE::"Planning Component":
                begin
                    ForPlanningComponent.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
                    RemainingQty := 0;
                    RemainingQtyBase := ForPlanningComponent."Net Quantity (Base)" - Abs(ForPlanningComponent."Reserved Qty. (Base)");
                end;
            DATABASE::"Transfer Line":
                case CalcReservEntry."Source Subtype" of
                    0: // Outbound
                        begin
                            ForTransLine.CalcFields("Reserved Quantity Outbnd.", "Reserved Qty. Outbnd. (Base)");
                            RemainingQty := ForTransLine."Outstanding Quantity" - Abs(ForTransLine."Reserved Quantity Outbnd.");
                            RemainingQtyBase := ForTransLine."Outstanding Qty. (Base)" - Abs(ForTransLine."Reserved Qty. Outbnd. (Base)");
                        end;
                    1: // Inbound
                        begin
                            ForTransLine.CalcFields("Reserved Quantity Inbnd.", "Reserved Qty. Inbnd. (Base)");
                            RemainingQty := ForTransLine."Outstanding Quantity" - Abs(ForTransLine."Reserved Quantity Inbnd.");
                            RemainingQtyBase := ForTransLine."Outstanding Qty. (Base)" - Abs(ForTransLine."Reserved Qty. Inbnd. (Base)");
                        end;
                end;
            DATABASE::"Service Line":
                begin
                    ForServiceLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
                    RemainingQty := ForServiceLine."Outstanding Quantity" - Abs(ForServiceLine."Reserved Quantity");
                    RemainingQtyBase := ForServiceLine."Outstanding Qty. (Base)" - Abs(ForServiceLine."Reserved Qty. (Base)");
                end;
            DATABASE::"Job Planning Line":
                begin
                    ForJobPlanningLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
                    RemainingQty := ForJobPlanningLine."Remaining Qty." - Abs(ForJobPlanningLine."Reserved Quantity");
                    RemainingQtyBase := ForJobPlanningLine."Remaining Qty. (Base)" - Abs(ForJobPlanningLine."Reserved Qty. (Base)");
                end;
            else
                Error(Text003);
        end;
    end;

    local procedure FieldFilterNeeded(var ReservEntry: Record "Reservation Entry"; "Field": Option "Lot No.","Serial No."): Boolean
    begin
        exit(FieldFilterNeeded(ReservEntry, Positive, Field));
    end;

    procedure FieldFilterNeeded(var ReservEntry: Record "Reservation Entry"; SearchForSupply: Boolean; "Field": Option "Lot No.","Serial No."): Boolean
    var
        ReservEntry2: Record "Reservation Entry";
        FieldValue: Code[50];
    begin
        FieldFilter := '';

        FieldValue := '';
        GetItemSetup(ReservEntry);
        case Field of
            0:
                begin
                    if not ItemTrackingCode."Lot Specific Tracking" then
                        exit(false);
                    FieldValue := ReservEntry."Lot No.";
                end;
            1:
                begin
                    if not ItemTrackingCode."SN Specific Tracking" then
                        exit(false);
                    FieldValue := ReservEntry."Serial No.";
                end;
            else
                Error(Text004);
        end;

        // The field "Lot No." is used a foundation for building up the filter:

        if FieldValue <> '' then begin
            if SearchForSupply then // Demand
                ReservEntry2.SetRange("Lot No.", FieldValue)
            else // Supply
                ReservEntry2.SetFilter("Lot No.", '%1|%2', FieldValue, '');
            FieldFilter := ReservEntry2.GetFilter("Lot No.");
        end else // FieldValue = ''
            if SearchForSupply then // Demand
                exit(false)
            else
                FieldFilter := StrSubstNo('''%1''', '');

        exit(true);
    end;

    local procedure FilterPlanningComponent(AvailabilityDate: Date)
    begin
        with CalcPlanningComponent do begin
            Reset;
            SetCurrentKey("Item No.", "Variant Code", "Location Code", "Due Date");
            SetRange("Item No.", CalcReservEntry."Item No.");
            SetRange("Variant Code", CalcReservEntry."Variant Code");
            SetRange("Location Code", CalcReservEntry."Location Code");
            SetFilter("Due Date", GetAvailabilityFilter(AvailabilityDate));
            if Positive then
                SetFilter("Net Quantity (Base)", '<0')
            else
                SetFilter("Net Quantity (Base)", '>0');
        end;
    end;

    procedure GetFieldFilter(): Text[80]
    begin
        exit(FieldFilter);
    end;

    procedure GetAvailabilityFilter(AvailabilityDate: Date): Text[80]
    begin
        exit(GetAvailabilityFilter2(AvailabilityDate, Positive));
    end;

    local procedure GetAvailabilityFilter2(AvailabilityDate: Date; SearchForSupply: Boolean): Text[80]
    var
        ReservEntry2: Record "Reservation Entry";
    begin
        if SearchForSupply then
            ReservEntry2.SetFilter("Expected Receipt Date", '..%1', AvailabilityDate)
        else
            ReservEntry2.SetFilter("Expected Receipt Date", '>=%1', AvailabilityDate);

        exit(ReservEntry2.GetFilter("Expected Receipt Date"));
    end;

    procedure CopySign(FromValue: Decimal; var ToValue: Decimal)
    begin
        if FromValue * ToValue < 0 then
            ToValue := -ToValue;
    end;

    local procedure InitFilter(EntryID: Integer; AvailabilityDate: Date)
    begin
        case EntryID of
            1:
                begin // Item Ledger Entry
                    CalcItemLedgEntry.Reset;
                    CalcItemLedgEntry.SetCurrentKey("Item No.", Open, "Variant Code", Positive, "Location Code");
                    CalcItemLedgEntry.SetRange("Item No.", CalcReservEntry."Item No.");
                    CalcItemLedgEntry.SetRange(Open, true);
                    CalcItemLedgEntry.SetRange("Variant Code", CalcReservEntry."Variant Code");
                    CalcItemLedgEntry.SetRange(Positive, Positive);
                    CalcItemLedgEntry.SetRange("Location Code", CalcReservEntry."Location Code");
                    CalcItemLedgEntry.SetRange("Drop Shipment", false);
                    if FieldFilterNeeded(CalcReservEntry, Positive, 0) then
                        CalcItemLedgEntry.SetFilter("Lot No.", GetFieldFilter);
                    if FieldFilterNeeded(CalcReservEntry, Positive, 1) then
                        CalcItemLedgEntry.SetFilter("Serial No.", GetFieldFilter);
                end;
            12, 16:
                begin // Purchase Line
                    CalcPurchLine.Reset;
                    CalcPurchLine.SetCurrentKey(
                      "Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Expected Receipt Date");
                    CalcPurchLine.SetRange("Document Type", EntryID - 11);
                    CalcPurchLine.SetRange(Type, CalcPurchLine.Type::Item);
                    CalcPurchLine.SetRange("No.", CalcReservEntry."Item No.");
                    CalcPurchLine.SetRange("Variant Code", CalcReservEntry."Variant Code");
                    CalcPurchLine.SetRange("Drop Shipment", false);
                    CalcPurchLine.SetRange("Location Code", CalcReservEntry."Location Code");
                    CalcPurchLine.SetFilter("Expected Receipt Date", GetAvailabilityFilter(AvailabilityDate));
                    if Positive and (EntryID <> 16) then
                        CalcPurchLine.SetFilter("Quantity (Base)", '>0')
                    else
                        CalcPurchLine.SetFilter("Quantity (Base)", '<0');
                    CalcPurchLine.SetRange("Job No.", ' ');
                end;
            21:
                begin // Requisition Line
                    CalcReqLine.Reset;
                    CalcReqLine.SetCurrentKey(
                      Type, "No.", "Variant Code", "Location Code", "Sales Order No.", "Planning Line Origin", "Due Date");
                    CalcReqLine.SetRange(Type, CalcReqLine.Type::Item);
                    CalcReqLine.SetRange("No.", CalcReservEntry."Item No.");
                    CalcReqLine.SetRange("Variant Code", CalcReservEntry."Variant Code");
                    CalcReqLine.SetRange("Location Code", CalcReservEntry."Location Code");
                    CalcReqLine.SetRange("Sales Order No.", '');
                    CalcReqLine.SetFilter("Due Date", GetAvailabilityFilter(AvailabilityDate));
                    if Positive then
                        CalcReqLine.SetFilter("Quantity (Base)", '>0')
                    else
                        CalcReqLine.SetFilter("Quantity (Base)", '<0');
                end;
            31, 32, 36:
                begin // Sales Line
                    CalcSalesLine.Reset;
                    CalcSalesLine.SetCurrentKey(
                      "Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Shipment Date");
                    CalcSalesLine.SetRange("Document Type", EntryID - 31);
                    CalcSalesLine.SetRange(Type, CalcSalesLine.Type::Item);
                    CalcSalesLine.SetRange("No.", CalcReservEntry."Item No.");
                    CalcSalesLine.SetRange("Variant Code", CalcReservEntry."Variant Code");
                    CalcSalesLine.SetRange("Drop Shipment", false);
                    CalcSalesLine.SetRange("Location Code", CalcReservEntry."Location Code");
                    CalcSalesLine.SetFilter("Shipment Date", GetAvailabilityFilter(AvailabilityDate));
                    if EntryID = 36 then
                        if Positive then
                            CalcSalesLine.SetFilter("Quantity (Base)", '>0')
                        else
                            CalcSalesLine.SetFilter("Quantity (Base)", '<0')
                    else
                        if Positive then
                            CalcSalesLine.SetFilter("Quantity (Base)", '<0')
                        else
                            CalcSalesLine.SetFilter("Quantity (Base)", '>0');
                    CalcSalesLine.SetRange("Job No.", ' ');
                end;
            61, 62, 63, 64:
                begin // Prod. Order
                    CalcProdOrderLine.Reset;
                    CalcProdOrderLine.SetCurrentKey(Status, "Item No.", "Variant Code", "Location Code", "Due Date");
                    CalcProdOrderLine.SetRange(Status, EntryID - 61);
                    CalcProdOrderLine.SetRange("Item No.", CalcReservEntry."Item No.");
                    CalcProdOrderLine.SetRange("Variant Code", CalcReservEntry."Variant Code");
                    CalcProdOrderLine.SetRange("Location Code", CalcReservEntry."Location Code");
                    CalcProdOrderLine.SetFilter("Due Date", GetAvailabilityFilter(AvailabilityDate));
                    if Positive then
                        CalcProdOrderLine.SetFilter("Remaining Qty. (Base)", '>0')
                    else
                        CalcProdOrderLine.SetFilter("Remaining Qty. (Base)", '<0');
                end;
            71, 72, 73, 74:
                begin // Prod. Order Component
                    CalcProdOrderComp.Reset;
                    CalcProdOrderComp.SetCurrentKey(Status, "Item No.", "Variant Code", "Location Code", "Due Date");
                    CalcProdOrderComp.SetRange(Status, EntryID - 71);
                    CalcProdOrderComp.SetRange("Item No.", CalcReservEntry."Item No.");
                    CalcProdOrderComp.SetRange("Variant Code", CalcReservEntry."Variant Code");
                    CalcProdOrderComp.SetRange("Location Code", CalcReservEntry."Location Code");
                    CalcProdOrderComp.SetFilter("Due Date", GetAvailabilityFilter(AvailabilityDate));
                    if Positive then
                        CalcProdOrderComp.SetFilter("Remaining Qty. (Base)", '<0')
                    else
                        CalcProdOrderComp.SetFilter("Remaining Qty. (Base)", '>0');
                end;
            91:
                FilterPlanningComponent(AvailabilityDate);
            101:
                begin // Transfer, Outbound
                    CalcTransLine.Reset;
                    CalcTransLine.SetCurrentKey("Transfer-from Code", "Shipment Date", "Item No.", "Variant Code");
                    CalcTransLine.SetRange("Item No.", CalcReservEntry."Item No.");
                    CalcTransLine.SetRange("Variant Code", CalcReservEntry."Variant Code");
                    CalcTransLine.SetRange("Transfer-from Code", CalcReservEntry."Location Code");
                    CalcTransLine.SetFilter("Shipment Date", GetAvailabilityFilter(AvailabilityDate));
                    if Positive then
                        CalcTransLine.SetFilter("Outstanding Qty. (Base)", '<0')
                    else
                        CalcTransLine.SetFilter("Outstanding Qty. (Base)", '>0');
                end;
            102:
                begin // Transfer, Inbound
                    CalcTransLine.Reset;
                    CalcTransLine.SetCurrentKey("Transfer-to Code", "Receipt Date", "Item No.", "Variant Code");
                    CalcTransLine.SetRange("Item No.", CalcReservEntry."Item No.");
                    CalcTransLine.SetRange("Variant Code", CalcReservEntry."Variant Code");
                    CalcTransLine.SetRange("Transfer-to Code", CalcReservEntry."Location Code");
                    CalcTransLine.SetFilter("Receipt Date", GetAvailabilityFilter(AvailabilityDate));
                    if Positive then
                        CalcTransLine.SetFilter("Outstanding Qty. (Base)", '>0')
                    else
                        CalcTransLine.SetFilter("Outstanding Qty. (Base)", '<0');
                end;
            110:
                begin // Service Line
                    CalcServiceLine.Reset;
                    CalcServiceLine.SetCurrentKey(Type, "No.", "Variant Code", "Location Code", "Needed by Date", "Document Type");
                    CalcServiceLine.SetRange(Type, CalcServiceLine.Type::Item);
                    CalcServiceLine.SetRange("No.", CalcReservEntry."Item No.");
                    CalcServiceLine.SetRange("Variant Code", CalcReservEntry."Variant Code");
                    CalcServiceLine.SetRange("Location Code", CalcReservEntry."Location Code");
                    CalcServiceLine.SetFilter("Needed by Date", GetAvailabilityFilter(AvailabilityDate));
                    if Positive then
                        CalcServiceLine.SetFilter("Quantity (Base)", '<0')
                    else
                        CalcServiceLine.SetFilter("Quantity (Base)", '>0');
                    CalcServiceLine.SetRange("Job No.", ' ');
                end;
            133:
                begin // Job Planning Line
                    CalcJobPlanningLine.Reset;
                    CalcJobPlanningLine.SetCurrentKey(Status, Type, "No.", "Variant Code", "Location Code", "Planning Date");
                    CalcJobPlanningLine.SetRange(Status, EntryID - 131);
                    CalcJobPlanningLine.SetRange(Type, CalcJobPlanningLine.Type::Item);
                    CalcJobPlanningLine.SetRange("No.", CalcReservEntry."Item No.");
                    CalcJobPlanningLine.SetRange("Variant Code", CalcReservEntry."Variant Code");
                    CalcJobPlanningLine.SetRange("Location Code", CalcReservEntry."Location Code");
                    CalcJobPlanningLine.SetFilter("Planning Date", GetAvailabilityFilter(AvailabilityDate));
                    if Positive then
                        CalcJobPlanningLine.SetFilter("Quantity (Base)", '<0')
                    else
                        CalcJobPlanningLine.SetFilter("Quantity (Base)", '>0');
                end;
            141, 142:
                begin // Assembly Header
                    CalcAssemblyHeader.Reset;
                    CalcAssemblyHeader.SetCurrentKey(
                      "Document Type", "Item No.", "Variant Code", "Location Code", "Due Date");
                    CalcAssemblyHeader.SetRange("Document Type", EntryID - 141);
                    CalcAssemblyHeader.SetRange("Item No.", CalcReservEntry."Item No.");
                    CalcAssemblyHeader.SetRange("Variant Code", CalcReservEntry."Variant Code");
                    CalcAssemblyHeader.SetRange("Location Code", CalcReservEntry."Location Code");
                    CalcAssemblyHeader.SetFilter("Due Date", GetAvailabilityFilter(AvailabilityDate));
                    if Positive then
                        CalcAssemblyHeader.SetFilter("Remaining Quantity (Base)", '>0')
                    else
                        CalcAssemblyHeader.SetFilter("Remaining Quantity (Base)", '<0');
                end;
            151, 152:
                begin // Assembly Line
                    CalcAssemblyLine.Reset;
                    CalcAssemblyLine.SetCurrentKey(
                      "Document Type", Type, "No.", "Variant Code", "Location Code", "Due Date");
                    CalcAssemblyLine.SetRange("Document Type", EntryID - 151);
                    CalcAssemblyLine.SetRange(Type, CalcAssemblyLine.Type::Item);
                    CalcAssemblyLine.SetRange("No.", CalcReservEntry."Item No.");
                    CalcAssemblyLine.SetRange("Variant Code", CalcReservEntry."Variant Code");
                    CalcAssemblyLine.SetRange("Location Code", CalcReservEntry."Location Code");
                    CalcAssemblyLine.SetFilter("Due Date", GetAvailabilityFilter(AvailabilityDate));
                    if Positive then
                        CalcAssemblyLine.SetFilter("Remaining Quantity (Base)", '<0')
                    else
                        CalcAssemblyLine.SetFilter("Remaining Quantity (Base)", '>0');
                end;
        end;

        OnAfterInitFilter(CalcReservEntry, EntryID);
    end;

    local procedure SetValueArray(EntryStatus: Option Reservation,Tracking,Simulation): Integer
    begin
        Clear(ValueArray);
        case EntryStatus of
            0:
                begin // Reservation
                    ValueArray[1] := 1;
                    ValueArray[2] := 12;
                    ValueArray[3] := 16;
                    ValueArray[4] := 32;
                    ValueArray[5] := 36;
                    ValueArray[6] := 63;
                    ValueArray[7] := 64;
                    ValueArray[8] := 73;
                    ValueArray[9] := 74;
                    ValueArray[10] := 101;
                    ValueArray[11] := 102;
                    ValueArray[12] := 110;
                    ValueArray[13] := 133;
                    ValueArray[14] := 142;
                    ValueArray[15] := 152;
                    exit(15);
                end;
            1:
                begin // Order Tracking
                    ValueArray[1] := 1;
                    ValueArray[2] := 12;
                    ValueArray[3] := 16;
                    ValueArray[4] := 21;
                    ValueArray[5] := 32;
                    ValueArray[6] := 36;
                    ValueArray[7] := 62;
                    ValueArray[8] := 63;
                    ValueArray[9] := 64;
                    ValueArray[10] := 72;
                    ValueArray[11] := 73;
                    ValueArray[12] := 74;
                    ValueArray[13] := 101;
                    ValueArray[14] := 102;
                    ValueArray[15] := 110;
                    ValueArray[16] := 133;
                    ValueArray[17] := 142;
                    ValueArray[18] := 152;
                    exit(18);
                end;
            2:
                begin // Simulation order tracking
                    ValueArray[1] := 31;
                    ValueArray[2] := 61;
                    ValueArray[3] := 71;
                    exit(3);
                end;
            3:
                begin // Item Tracking
                    ValueArray[1] := 1;
                    ValueArray[2] := 6500;
                    exit(2);
                end;
        end;

        OnAfterSetValueArray(EntryStatus, ValueArray);
    end;

    procedure ClearSurplus()
    var
        ReservEntry2: Record "Reservation Entry";
    begin
        CalcReservEntry.TestField("Source Type");
        ReservEntry2 := CalcReservEntry;
        ReservEntry2.SetPointerFilter;
        ReservEntry2.SetRange("Reservation Status", ReservEntry2."Reservation Status"::Surplus);
        // Item Tracking
        if ItemTrackingHandling = ItemTrackingHandling::None then
            ReservEntry2.SetTrackingFilter('', '');

        if Item."Order Tracking Policy" = Item."Order Tracking Policy"::"Tracking & Action Msg." then begin
            ReservEntry2.Lock;
            if not ReservEntry2.FindSet then
                exit;
            ActionMessageEntry.Reset;
            ActionMessageEntry.SetCurrentKey("Reservation Entry");
            repeat
                ActionMessageEntry.SetRange("Reservation Entry", ReservEntry2."Entry No.");
                ActionMessageEntry.DeleteAll;
            until ReservEntry2.Next = 0;
        end;

        ReservEntry2.SetRange(
          "Reservation Status", ReservEntry2."Reservation Status"::Surplus, ReservEntry2."Reservation Status"::Prospect);
        ReservEntry2.DeleteAll;
    end;

    local procedure QuantityTracked(var ReservEntry: Record "Reservation Entry"): Decimal
    var
        ReservEntry2: Record "Reservation Entry";
        QtyTracked: Decimal;
    begin
        ReservEntry2 := ReservEntry;
        ReservEntry2.SetPointerFilter;
        ReservEntry.CopyFilter("Serial No.", ReservEntry2."Serial No.");
        ReservEntry.CopyFilter("Lot No.", ReservEntry2."Lot No.");
        if ReservEntry2.FindFirst then begin
            ReservEntry.Binding := ReservEntry2.Binding;
            ReservEntry2.CalcSums("Quantity (Base)");
            QtyTracked := ReservEntry2."Quantity (Base)";
        end;
        exit(QtyTracked);
    end;

    local procedure QuantityTracked2(var ReservEntry: Record "Reservation Entry"): Decimal
    var
        ReservEntry2: Record "Reservation Entry";
        QtyTracked: Decimal;
    begin
        ReservEntry2 := ReservEntry;
        ReservEntry2.SetPointerFilter;
        ReservEntry2.SetTrackingFilterFromReservEntry(ReservEntry);
        ReservEntry2.SetRange("Reservation Status",
          ReservEntry2."Reservation Status"::Tracking, ReservEntry2."Reservation Status"::Prospect);
        if not ReservEntry2.IsEmpty then begin
            ReservEntry2.CalcSums("Quantity (Base)");
            QtyTracked := ReservEntry2."Quantity (Base)";
        end;
        exit(QtyTracked);
    end;

    procedure AutoTrack(TotalQty: Decimal)
    var
        SurplusEntry: Record "Reservation Entry";
        DummyEntry: Record "Reservation Entry";
        AvailabilityDate: Date;
        QtyToTrack: Decimal;
    begin
        CalcReservEntry.TestField("Source Type");
        if CalcReservEntry."Item No." = '' then
            exit;

        GetItemSetup(CalcReservEntry);
        if Item."Order Tracking Policy" = Item."Order Tracking Policy"::None then
            exit;

        if CalcReservEntry."Source Type" in [DATABASE::"Sales Line", DATABASE::"Purchase Line", DATABASE::"Service Line"] then
            if not (CalcReservEntry."Source Subtype" in [1, 5]) then
                exit; // Only order, return order

        if CalcReservEntry."Source Type" in [DATABASE::"Prod. Order Line", DATABASE::"Prod. Order Component"]
        then
            if CalcReservEntry."Source Subtype" = 0 then
                exit; // Not simulation

        CalcReservEntry.Lock;

        QtyToTrack := CreateReservEntry.SignFactor(CalcReservEntry) * TotalQty - QuantityTracked(CalcReservEntry);

        if QtyToTrack = 0 then begin
            UpdateDating;
            exit;
        end;

        QtyToTrack := MatchSurplus(CalcReservEntry, SurplusEntry, QtyToTrack, Positive, AvailabilityDate, Item."Order Tracking Policy");

        // Make residual surplus record:
        if QtyToTrack <> 0 then begin
            if CurrentBindingIsSet then
                MakeConnection(CalcReservEntry, SurplusEntry, QtyToTrack, 2, AvailabilityDate, CurrentBinding)
            else
                MakeConnection(CalcReservEntry, SurplusEntry, QtyToTrack, 2, AvailabilityDate, CalcReservEntry.Binding);

            CreateReservEntry.GetLastEntry(SurplusEntry); // Get the surplus-entry just inserted
            if SurplusEntry.IsResidualSurplus then begin
                SurplusEntry."Untracked Surplus" := true;
                SurplusEntry.Modify;
            end;
            if Item."Order Tracking Policy" = Item."Order Tracking Policy"::"Tracking & Action Msg." then // Issue Action Message
                IssueActionMessage(SurplusEntry, true, DummyEntry);
        end else
            UpdateDating;
    end;

    procedure MatchSurplus(var ReservEntry: Record "Reservation Entry"; var SurplusEntry: Record "Reservation Entry"; QtyToTrack: Decimal; SearchForSupply: Boolean; var AvailabilityDate: Date; TrackingPolicy: Option "None","Tracking Only","Tracking & Action Msg."): Decimal
    var
        ReservEntry2: Record "Reservation Entry";
        Search: Text[1];
        NextStep: Integer;
        ReservationStatus: Option Reservation,Tracking;
    begin
        if QtyToTrack = 0 then
            exit;

        ReservEntry.Lock;
        SurplusEntry.SetCurrentKey(
          "Item No.", "Variant Code", "Location Code", "Reservation Status",
          "Shipment Date", "Expected Receipt Date", "Serial No.", "Lot No.");
        SurplusEntry.SetRange("Item No.", ReservEntry."Item No.");
        SurplusEntry.SetRange("Variant Code", ReservEntry."Variant Code");
        SurplusEntry.SetRange("Location Code", ReservEntry."Location Code");
        SurplusEntry.SetRange("Reservation Status", SurplusEntry."Reservation Status"::Surplus);
        if SkipUntrackedSurplus then
            SurplusEntry.SetRange("Untracked Surplus", false);
        if SearchForSupply then begin
            AvailabilityDate := ReservEntry."Shipment Date";
            Search := '+';
            NextStep := -1;
            SurplusEntry.SetFilter("Expected Receipt Date", GetAvailabilityFilter2(AvailabilityDate, SearchForSupply));
            SurplusEntry.SetFilter("Quantity (Base)", '>0');
        end else begin
            AvailabilityDate := ReservEntry."Expected Receipt Date";
            Search := '-';
            NextStep := 1;
            SurplusEntry.SetFilter("Shipment Date", GetAvailabilityFilter2(AvailabilityDate, SearchForSupply));
            SurplusEntry.SetFilter("Quantity (Base)", '<0')
        end;
        if FieldFilterNeeded(ReservEntry, SearchForSupply, 0) then
            SurplusEntry.SetFilter("Lot No.", GetFieldFilter);
        if FieldFilterNeeded(ReservEntry, SearchForSupply, 1) then
            SurplusEntry.SetFilter("Serial No.", GetFieldFilter);
        if SurplusEntry.Find(Search) then
            repeat
                if not IsSpecialOrderOrDropShipment(SurplusEntry) then begin
                    ReservationStatus := ReservationStatus::Tracking;
                    if Abs(SurplusEntry."Quantity (Base)") <= Abs(QtyToTrack) then begin
                        ReservEntry2 := SurplusEntry;
                        MakeConnection(ReservEntry, SurplusEntry, -SurplusEntry."Quantity (Base)", ReservationStatus,
                          AvailabilityDate, SurplusEntry.Binding);
                        QtyToTrack := QtyToTrack + SurplusEntry."Quantity (Base)";
                        SurplusEntry := ReservEntry2;
                        SurplusEntry.Delete;
                        if TrackingPolicy = TrackingPolicy::"Tracking & Action Msg." then
                            ModifyActionMessage(SurplusEntry."Entry No.", 0, true); // Delete related Action Message
                    end else begin
                        SurplusEntry.Validate("Quantity (Base)", SurplusEntry."Quantity (Base)" + QtyToTrack);
                        SurplusEntry.Modify;
                        MakeConnection(ReservEntry, SurplusEntry, QtyToTrack, ReservationStatus, AvailabilityDate, SurplusEntry.Binding);
                        if TrackingPolicy = TrackingPolicy::"Tracking & Action Msg." then
                            ModifyActionMessage(SurplusEntry."Entry No.", QtyToTrack, false); // Modify related Action Message
                        QtyToTrack := 0;
                    end;
                end;
            until (SurplusEntry.Next(NextStep) = 0) or (QtyToTrack = 0);

        exit(QtyToTrack);
    end;

    local procedure MakeConnection(var FromReservEntry: Record "Reservation Entry"; var ToReservEntry: Record "Reservation Entry"; Quantity: Decimal; ReservationStatus: Option Reservation,Tracking,Surplus; AvailabilityDate: Date; Binding: Option ,"Order-to-Order")
    var
        sign: Integer;
    begin
        if Quantity < 0 then
            ToReservEntry."Shipment Date" := AvailabilityDate
        else
            ToReservEntry."Expected Receipt Date" := AvailabilityDate;

        CreateReservEntry.SetBinding(Binding);

        if FromReservEntry."Planning Flexibility" <> FromReservEntry."Planning Flexibility"::Unlimited then
            CreateReservEntry.SetPlanningFlexibility(FromReservEntry."Planning Flexibility");

        sign := CreateReservEntry.SignFactor(FromReservEntry);
        CreateReservEntry.CreateReservEntryFor(
          FromReservEntry."Source Type", FromReservEntry."Source Subtype", FromReservEntry."Source ID",
          FromReservEntry."Source Batch Name", FromReservEntry."Source Prod. Order Line", FromReservEntry."Source Ref. No.",
          FromReservEntry."Qty. per Unit of Measure",
          0, sign * Quantity,
          FromReservEntry."Serial No.", FromReservEntry."Lot No.");
        CreateReservEntry.CreateReservEntryFrom(
          ToReservEntry."Source Type", ToReservEntry."Source Subtype", ToReservEntry."Source ID", ToReservEntry."Source Batch Name",
          ToReservEntry."Source Prod. Order Line", ToReservEntry."Source Ref. No.", ToReservEntry."Qty. per Unit of Measure",
          ToReservEntry."Serial No.", ToReservEntry."Lot No.");
        CreateReservEntry.SetApplyFromEntryNo(FromReservEntry."Appl.-from Item Entry");
        CreateReservEntry.SetApplyToEntryNo(FromReservEntry."Appl.-to Item Entry");
        CreateReservEntry.SetUntrackedSurplus(ToReservEntry."Untracked Surplus");

        if IsSpecialOrderOrDropShipment(ToReservEntry) then begin
            if FromReservEntry."Source Type" = DATABASE::"Purchase Line" then
                ToReservEntry."Shipment Date" := 0D;
            if FromReservEntry."Source Type" = DATABASE::"Sales Line" then
                ToReservEntry."Expected Receipt Date" := 0D;
        end;
        CreateReservEntry.CreateEntry(
          FromReservEntry."Item No.", FromReservEntry."Variant Code", FromReservEntry."Location Code",
          FromReservEntry.Description, ToReservEntry."Expected Receipt Date", ToReservEntry."Shipment Date", 0, ReservationStatus);
    end;

    procedure ModifyUnitOfMeasure()
    begin
        ReservEngineMgt.ModifyUnitOfMeasure(CalcReservEntry, CalcReservEntry."Qty. per Unit of Measure");
    end;

    procedure MakeRoomForReservation(var ReservEntry: Record "Reservation Entry")
    var
        ReservEntry2: Record "Reservation Entry";
        TotalQuantity: Decimal;
    begin
        TotalQuantity := SourceQuantity(ReservEntry, false);
        ReservEntry2 := ReservEntry;
        ReservEntry2.SetPointerFilter;
        ItemTrackingHandling := ItemTrackingHandling::Match;
        DeleteReservEntries(false, TotalQuantity - (ReservEntry."Quantity (Base)" * CreateReservEntry.SignFactor(ReservEntry)),
          ReservEntry2);
    end;

    local procedure SaveTrackingSpecification(var ReservEntry: Record "Reservation Entry"; QtyReleased: Decimal)
    begin
        // Used when creating reservations.
        if ItemTrackingHandling = ItemTrackingHandling::None then
            exit;
        if not ReservEntry.TrackingExists then
            exit;
        TempTrackingSpecification.SetTrackingFilterFromReservEntry(ReservEntry);
        if TempTrackingSpecification.FindSet then begin
            TempTrackingSpecification.Validate("Quantity (Base)",
              TempTrackingSpecification."Quantity (Base)" + QtyReleased);
            TempTrackingSpecification.Modify;
        end else begin
            TempTrackingSpecification.TransferFields(ReservEntry);
            TempTrackingSpecification.Validate("Quantity (Base)", QtyReleased);
            TempTrackingSpecification.Insert;
        end;
        TempTrackingSpecification.Reset;
    end;

    procedure CollectTrackingSpecification(var TargetTrackingSpecification: Record "Tracking Specification" temporary): Boolean
    begin
        // Used when creating reservations.
        TempTrackingSpecification.Reset;
        TargetTrackingSpecification.Reset;

        if not TempTrackingSpecification.FindSet then
            exit(false);

        repeat
            TargetTrackingSpecification := TempTrackingSpecification;
            TargetTrackingSpecification.Insert;
        until TempTrackingSpecification.Next = 0;

        TempTrackingSpecification.DeleteAll;

        exit(true);
    end;

    procedure SourceQuantity(var ReservEntry: Record "Reservation Entry"; SetAsCurrent: Boolean): Decimal
    begin
        exit(GetSourceRecordValue(ReservEntry, SetAsCurrent, 0));
    end;

    procedure GetSourceRecordValue(var ReservEntry: Record "Reservation Entry"; SetAsCurrent: Boolean; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        ReturnQty: Decimal;
    begin
        with ReservEntry do
            case "Source Type" of
                DATABASE::"Item Ledger Entry":
                    exit(GetSourceItemLedgEntryValue(ReservEntry, SetAsCurrent, ReturnOption));
                DATABASE::"Sales Line":
                    exit(GetSourceSalesLineValue(ReservEntry, SetAsCurrent, ReturnOption));
                DATABASE::"Requisition Line":
                    exit(GetSourceReqLineValue(ReservEntry, SetAsCurrent, ReturnOption));
                DATABASE::"Purchase Line":
                    exit(GetSourcePurchLineValue(ReservEntry, SetAsCurrent, ReturnOption));
                DATABASE::"Item Journal Line":
                    exit(GetSourceItemJnlLineValue(ReservEntry, SetAsCurrent, ReturnOption));
                DATABASE::"Job Journal Line":
                    exit(GetSourceJobJnlLineValue(ReservEntry, SetAsCurrent, ReturnOption));
                DATABASE::"Prod. Order Line":
                    exit(GetSourceProdOrderLineValue(ReservEntry, SetAsCurrent, ReturnOption));
                DATABASE::"Prod. Order Component":
                    exit(GetSourceProdOrderCompValue(ReservEntry, SetAsCurrent, ReturnOption));
                DATABASE::"Assembly Header":
                    exit(GetSourceAsmHeaderValue(ReservEntry, SetAsCurrent, ReturnOption));
                DATABASE::"Assembly Line":
                    exit(GetSourceAsmLineValue(ReservEntry, SetAsCurrent, ReturnOption));
                DATABASE::"Planning Component":
                    exit(GetSourcePlanningCompValue(ReservEntry, SetAsCurrent, ReturnOption));
                DATABASE::"Transfer Line":
                    exit(GetSourceTransLineValue(ReservEntry, SetAsCurrent, ReturnOption));
                DATABASE::"Service Line":
                    exit(GetSourceServLineValue(ReservEntry, SetAsCurrent, ReturnOption));
                DATABASE::"Job Planning Line":
                    exit(GetSourceJobPlanningLineValue(ReservEntry, SetAsCurrent, ReturnOption));
                else begin
                        OnGetSourceRecordValue(ReservEntry, SetAsCurrent, ReturnOption, ReturnQty);
                        exit(ReturnQty);
                    end;
            end;
    end;

    local procedure GetSourceItemLedgEntryValue(var ReservEntry: Record "Reservation Entry"; SetAsCurrent: Boolean; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.Get(ReservEntry."Source Ref. No.");
        if SetAsCurrent then
            SetItemLedgEntry(ItemLedgEntry);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(ItemLedgEntry."Remaining Quantity");
            ReturnOption::"Gross Qty. (Base)":
                exit(ItemLedgEntry.Quantity);
        end;
    end;

    local procedure GetSourceSalesLineValue(var ReservEntry: Record "Reservation Entry"; SetAsCurrent: Boolean; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Ref. No.");
        if SetAsCurrent then
            SetSalesLine(SalesLine);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(SalesLine."Outstanding Qty. (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(SalesLine."Quantity (Base)");
        end;
    end;

    local procedure GetSourceReqLineValue(var ReservEntry: Record "Reservation Entry"; SetAsCurrent: Boolean; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        ReqLine: Record "Requisition Line";
    begin
        ReqLine.Get(ReservEntry."Source ID", ReservEntry."Source Batch Name", ReservEntry."Source Ref. No.");
        if SetAsCurrent then
            SetReqLine(ReqLine);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(ReqLine."Net Quantity (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(ReqLine."Quantity (Base)");
        end;
    end;

    local procedure GetSourcePurchLineValue(var ReservEntry: Record "Reservation Entry"; SetAsCurrent: Boolean; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Ref. No.");
        if SetAsCurrent then
            SetPurchLine(PurchLine);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(PurchLine."Outstanding Qty. (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(PurchLine."Quantity (Base)");
        end;
    end;

    local procedure GetSourceItemJnlLineValue(var ReservEntry: Record "Reservation Entry"; SetAsCurrent: Boolean; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        ItemJnlLine.Get(ReservEntry."Source ID", ReservEntry."Source Batch Name", ReservEntry."Source Ref. No.");
        if SetAsCurrent then
            SetItemJnlLine(ItemJnlLine);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(ItemJnlLine."Quantity (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(ItemJnlLine."Quantity (Base)");
        end;
    end;

    local procedure GetSourceJobJnlLineValue(var ReservEntry: Record "Reservation Entry"; SetAsCurrent: Boolean; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        JobJnlLine: Record "Job Journal Line";
    begin
        JobJnlLine.Get(ReservEntry."Source ID", ReservEntry."Source Batch Name", ReservEntry."Source Ref. No.");
        if SetAsCurrent then
            SetJobJnlLine(JobJnlLine);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(JobJnlLine."Quantity (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(JobJnlLine."Quantity (Base)");
        end;
    end;

    local procedure GetSourceProdOrderLineValue(var ReservEntry: Record "Reservation Entry"; SetAsCurrent: Boolean; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Prod. Order Line");
        if SetAsCurrent then
            SetProdOrderLine(ProdOrderLine);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(ProdOrderLine."Remaining Qty. (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(ProdOrderLine."Quantity (Base)");
        end;
    end;

    local procedure GetSourceProdOrderCompValue(var ReservEntry: Record "Reservation Entry"; SetAsCurrent: Boolean; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        ProdOrderComp.Get(
          ReservEntry."Source Subtype",
          ReservEntry."Source ID",
          ReservEntry."Source Prod. Order Line",
          ReservEntry."Source Ref. No.");
        if SetAsCurrent then
            SetProdOrderComponent(ProdOrderComp);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(ProdOrderComp."Remaining Qty. (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(ProdOrderComp."Expected Qty. (Base)");
        end;
    end;

    local procedure GetSourceAsmHeaderValue(var ReservEntry: Record "Reservation Entry"; SetAsCurrent: Boolean; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        AssemblyHeader.Get(ReservEntry."Source Subtype", ReservEntry."Source ID");
        if SetAsCurrent then
            SetAssemblyHeader(AssemblyHeader);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(AssemblyHeader."Remaining Quantity (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(AssemblyHeader."Quantity (Base)");
        end;
    end;

    local procedure GetSourceAsmLineValue(var ReservEntry: Record "Reservation Entry"; SetAsCurrent: Boolean; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyLine.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Ref. No.");
        if SetAsCurrent then
            SetAssemblyLine(AssemblyLine);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(AssemblyLine."Remaining Quantity (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(AssemblyLine."Quantity (Base)");
        end;
    end;

    local procedure GetSourcePlanningCompValue(var ReservEntry: Record "Reservation Entry"; SetAsCurrent: Boolean; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        PlanningComponent: Record "Planning Component";
    begin
        PlanningComponent.Get(
          ReservEntry."Source ID", ReservEntry."Source Batch Name",
          ReservEntry."Source Prod. Order Line", ReservEntry."Source Ref. No.");
        if SetAsCurrent then
            SetPlanningComponent(PlanningComponent);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(PlanningComponent."Net Quantity (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(PlanningComponent."Expected Quantity (Base)");
        end;
    end;

    local procedure GetSourceTransLineValue(var ReservEntry: Record "Reservation Entry"; SetAsCurrent: Boolean; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        TransLine: Record "Transfer Line";
    begin
        TransLine.Get(ReservEntry."Source ID", ReservEntry."Source Ref. No.");
        if SetAsCurrent then
            SetTransferLine(TransLine, ReservEntry."Source Subtype");
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(TransLine."Outstanding Qty. (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(TransLine."Quantity (Base)");
        end;
    end;

    local procedure GetSourceServLineValue(var ReservEntry: Record "Reservation Entry"; SetAsCurrent: Boolean; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        ServLine: Record "Service Line";
    begin
        ServLine.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Ref. No.");
        if SetAsCurrent then
            SetServLine(ServLine);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(ServLine."Outstanding Qty. (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(ServLine."Quantity (Base)");
        end;
    end;

    local procedure GetSourceJobPlanningLineValue(var ReservEntry: Record "Reservation Entry"; SetAsCurrent: Boolean; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"): Decimal
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetCurrentKey("Job Contract Entry No.");
        JobPlanningLine.SetRange("Job Contract Entry No.", ReservEntry."Source Ref. No.");
        JobPlanningLine.FindFirst;
        if SetAsCurrent then
            SetJobPlanningLine(JobPlanningLine);
        case ReturnOption of
            ReturnOption::"Net Qty. (Base)":
                exit(JobPlanningLine."Remaining Qty. (Base)");
            ReturnOption::"Gross Qty. (Base)":
                exit(JobPlanningLine."Quantity (Base)");
        end;
    end;

    local procedure GetItemSetup(var ReservEntry: Record "Reservation Entry")
    begin
        if ReservEntry."Item No." <> Item."No." then begin
            Item.Get(ReservEntry."Item No.");
            if Item."Item Tracking Code" <> '' then
                ItemTrackingCode.Get(Item."Item Tracking Code")
            else
                ItemTrackingCode.Init;
            GetPlanningParameters.AtSKU(SKU, ReservEntry."Item No.",
              ReservEntry."Variant Code", ReservEntry."Location Code");
            MfgSetup.Get;
        end;
    end;

    procedure MarkReservConnection(var ReservEntry: Record "Reservation Entry"; TargetReservEntry: Record "Reservation Entry") ReservedQuantity: Decimal
    var
        ReservEntry2: Record "Reservation Entry";
        SignFactor: Integer;
    begin
        if not ReservEntry.FindSet then
            exit;
        SignFactor := CreateReservEntry.SignFactor(ReservEntry);

        repeat
            if ReservEntry2.Get(ReservEntry."Entry No.", not ReservEntry.Positive) then
                if ReservEntry2.HasSamePointer(TargetReservEntry) then begin
                    ReservEntry.Mark(true);
                    ReservedQuantity += ReservEntry."Quantity (Base)" * SignFactor;
                end;
        until ReservEntry.Next = 0;
        ReservEntry.MarkedOnly(true);
    end;

    local procedure IsSpecialOrder(PurchasingCode: Code[10]): Boolean
    var
        Purchasing: Record Purchasing;
    begin
        if PurchasingCode <> '' then
            if Purchasing.Get(PurchasingCode) then
                exit(Purchasing."Special Order");

        exit(false);
    end;

    procedure IssueActionMessage(var SurplusEntry: Record "Reservation Entry"; UseGlobalSettings: Boolean; AllDeletedEntry: Record "Reservation Entry")
    var
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        ReservEntry3: Record "Reservation Entry";
        ActionMessageEntry2: Record "Action Message Entry";
        NextEntryNo: Integer;
        FirstDate: Date;
        Found: Boolean;
        FreeBinding: Boolean;
        NoMoreData: Boolean;
        DateFormula: DateFormula;
    begin
        SurplusEntry.TestField("Quantity (Base)");
        if SurplusEntry."Reservation Status" < SurplusEntry."Reservation Status"::Surplus then
            SurplusEntry.FieldError("Reservation Status");
        SurplusEntry.CalcFields("Action Message Adjustment");
        if SurplusEntry."Quantity (Base)" + SurplusEntry."Action Message Adjustment" = 0 then
            exit;

        ActionMessageEntry.Reset;

        if ActionMessageEntry.FindLast then
            NextEntryNo := ActionMessageEntry."Entry No." + 1
        else
            NextEntryNo := 1;

        ActionMessageEntry.Init;
        ActionMessageEntry."Entry No." := NextEntryNo;

        if SurplusEntry."Quantity (Base)" > 0 then begin // Supply: Issue AM directly
            if SurplusEntry."Planning Flexibility" = SurplusEntry."Planning Flexibility"::None then
                exit;
            if not (SurplusEntry."Source Type" in [DATABASE::"Prod. Order Line", DATABASE::"Purchase Line"]) then
                exit;

            ActionMessageEntry.TransferFromReservEntry(SurplusEntry);
            ActionMessageEntry.Quantity := -(SurplusEntry."Quantity (Base)" + SurplusEntry."Action Message Adjustment");
            ActionMessageEntry.Type := ActionMessageEntry.Type::New;
            ReservEntry2 := SurplusEntry;
        end else begin // Demand: Find supply and issue AM
            case SurplusEntry.Binding of
                SurplusEntry.Binding::" ":
                    begin
                        if UseGlobalSettings then begin
                            ReservEntry.Copy(SurplusEntry); // Copy filter and sorting
                            ReservEntry.SetRange("Reservation Status"); // Remove filter on Reservation Status
                        end else begin
                            GetItemSetup(SurplusEntry);
                            Positive := true;
                            ReservEntry.SetCurrentKey(
                              "Item No.", "Variant Code", "Location Code", "Reservation Status",
                              "Shipment Date", "Expected Receipt Date", "Serial No.", "Lot No.");
                            ReservEntry.SetRange("Item No.", SurplusEntry."Item No.");
                            ReservEntry.SetRange("Variant Code", SurplusEntry."Variant Code");
                            ReservEntry.SetRange("Location Code", SurplusEntry."Location Code");
                            ReservEntry.SetFilter("Expected Receipt Date", GetAvailabilityFilter(SurplusEntry."Shipment Date"));
                            if FieldFilterNeeded(SurplusEntry, 0) then
                                ReservEntry.SetFilter("Lot No.", GetFieldFilter);
                            if FieldFilterNeeded(SurplusEntry, 1) then
                                ReservEntry.SetFilter("Serial No.", GetFieldFilter);
                            ReservEntry.SetRange(Positive, true);
                        end;
                        ReservEntry.SetRange(Binding, ReservEntry.Binding::" ");
                        ReservEntry.SetRange("Planning Flexibility", ReservEntry."Planning Flexibility"::Unlimited);
                        ReservEntry.SetFilter("Source Type", '=%1|=%2', DATABASE::"Purchase Line", DATABASE::"Prod. Order Line");
                    end;
                SurplusEntry.Binding::"Order-to-Order":
                    begin
                        ReservEntry3 := SurplusEntry;
                        ReservEntry3.SetPointerFilter;
                        ReservEntry3.SetRange(
                          "Reservation Status", ReservEntry3."Reservation Status"::Reservation, ReservEntry3."Reservation Status"::Tracking);
                        ReservEntry3.SetRange(Binding, ReservEntry3.Binding::"Order-to-Order");
                        if ReservEntry3.FindFirst then begin
                            ReservEntry3.Get(ReservEntry3."Entry No.", not ReservEntry3.Positive);
                            ReservEntry := ReservEntry3;
                            ReservEntry.SetRecFilter;
                            Found := true;
                        end else begin
                            Found := false;
                            FreeBinding := true;
                        end;
                    end;
            end;

            ActionMessageEntry.Quantity := -(SurplusEntry."Quantity (Base)" + SurplusEntry."Action Message Adjustment");

            if not FreeBinding then
                if ReservEntry.Find('+') then begin
                    if AllDeletedEntry."Entry No." > 0 then // The supply record has been deleted and cannot be reused.
                        repeat
                            Found := not AllDeletedEntry.HasSamePointer(ReservEntry);
                            if not Found then
                                NoMoreData := ReservEntry.Next(-1) = 0;
                        until Found or NoMoreData
                    else
                        Found := true;
                end;

            if Found then begin
                ActionMessageEntry.TransferFromReservEntry(ReservEntry);
                ActionMessageEntry.Type := ActionMessageEntry.Type::"Change Qty.";
                ReservEntry2 := ReservEntry;
            end else begin
                ActionMessageEntry."Location Code" := SurplusEntry."Location Code";
                ActionMessageEntry."Variant Code" := SurplusEntry."Variant Code";
                ActionMessageEntry."Item No." := SurplusEntry."Item No.";

                case SKU."Replenishment System" of
                    SKU."Replenishment System"::Purchase:
                        ActionMessageEntry."Source Type" := DATABASE::"Purchase Line";
                    SKU."Replenishment System"::"Prod. Order":
                        ActionMessageEntry."Source Type" := DATABASE::"Prod. Order Line";
                    SKU."Replenishment System"::Transfer:
                        ActionMessageEntry."Source Type" := DATABASE::"Transfer Line";
                    SKU."Replenishment System"::Assembly:
                        ActionMessageEntry."Source Type" := DATABASE::"Assembly Header";
                end;

                ActionMessageEntry.Type := ActionMessageEntry.Type::New;
            end;
            ActionMessageEntry."Reservation Entry" := SurplusEntry."Entry No.";
        end;

        ReservEntry2.SetPointerFilter;
        ReservEntry2.SetRange(
          "Reservation Status", ReservEntry2."Reservation Status"::Reservation, ReservEntry2."Reservation Status"::Tracking);

        if ReservEntry2."Source Type" <> DATABASE::"Item Ledger Entry" then
            if ReservEntry2.FindFirst then begin
                FirstDate := FindDate(ReservEntry2, 0, true);
                if FirstDate <> 0D then begin
                    if (Format(MfgSetup."Default Dampener Period") = '') or
                       ((ReservEntry2.Binding = ReservEntry2.Binding::"Order-to-Order") and
                        (ReservEntry2."Reservation Status" = ReservEntry2."Reservation Status"::Reservation))
                    then
                        Evaluate(MfgSetup."Default Dampener Period", '<0D>');

                    Evaluate(DateFormula, StrSubstNo('%1%2', '-', Format(MfgSetup."Default Dampener Period")));
                    if CalcDate(DateFormula, FirstDate) > ReservEntry2."Expected Receipt Date" then begin
                        ActionMessageEntry2.SetCurrentKey(
                          "Source Type", "Source Subtype", "Source ID", "Source Batch Name", "Source Prod. Order Line", "Source Ref. No.");
                        ActionMessageEntry2.SetSourceFilterFromActionEntry(ActionMessageEntry);
                        ActionMessageEntry2.SetRange(Quantity, 0);
                        ActionMessageEntry2.DeleteAll;
                        ActionMessageEntry2.Reset;
                        ActionMessageEntry2 := ActionMessageEntry;
                        ActionMessageEntry2.Quantity := 0;
                        ActionMessageEntry2."New Date" := FirstDate;
                        ActionMessageEntry2.Type := ActionMessageEntry.Type::Reschedule;
                        ActionMessageEntry2."Reservation Entry" := ReservEntry2."Entry No.";
                        while not ActionMessageEntry2.Insert do
                            ActionMessageEntry2."Entry No." += 1;
                        ActionMessageEntry."Entry No." := ActionMessageEntry2."Entry No." + 1;
                    end;
                end;
            end;

        while not ActionMessageEntry.Insert do
            ActionMessageEntry."Entry No." += 1;
    end;

    procedure ModifyActionMessage(RelatedToEntryNo: Integer; Quantity: Decimal; Delete: Boolean)
    begin
        ActionMessageEntry.Reset;
        ActionMessageEntry.SetCurrentKey("Reservation Entry");
        ActionMessageEntry.SetRange("Reservation Entry", RelatedToEntryNo);

        if Delete then begin
            ActionMessageEntry.DeleteAll;
            exit;
        end;
        ActionMessageEntry.SetRange("New Date", 0D);

        if ActionMessageEntry.FindFirst then begin
            ActionMessageEntry.Quantity -= Quantity;
            if ActionMessageEntry.Quantity = 0 then
                ActionMessageEntry.Delete
            else
                ActionMessageEntry.Modify;
        end;
    end;

    procedure FindDate(var ReservEntry: Record "Reservation Entry"; Which: Option "Earliest Shipment","Latest Receipt"; ReturnRecord: Boolean): Date
    var
        ReservEntry2: Record "Reservation Entry";
        LastDate: Date;
    begin
        ReservEntry2.Copy(ReservEntry); // Copy filter and sorting

        if not ReservEntry2.FindSet then
            exit;

        case Which of
            0:
                begin
                    LastDate := DMY2Date(31, 12, 9999);
                    repeat
                        if ReservEntry2."Shipment Date" < LastDate then begin
                            LastDate := ReservEntry2."Shipment Date";
                            if ReturnRecord then
                                ReservEntry := ReservEntry2;
                        end;
                    until ReservEntry2.Next = 0;
                end;
            1:
                begin
                    LastDate := 0D;
                    repeat
                        if ReservEntry2."Expected Receipt Date" > LastDate then begin
                            LastDate := ReservEntry2."Expected Receipt Date";
                            if ReturnRecord then
                                ReservEntry := ReservEntry2;
                        end;
                    until ReservEntry2.Next = 0;
                end;
        end;
        exit(LastDate);
    end;

    local procedure UpdateDating()
    var
        FilterReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
    begin
        if CalcReservEntry2."Source Type" = DATABASE::"Planning Component" then
            exit;

        if Item."Order Tracking Policy" <> Item."Order Tracking Policy"::"Tracking & Action Msg." then
            exit;

        if CalcReservEntry2."Source Type" = DATABASE::"Requisition Line" then
            if ForReqLine."Planning Line Origin" <> ForReqLine."Planning Line Origin"::" " then
                exit;

        FilterReservEntry := CalcReservEntry2;
        FilterReservEntry.SetPointerFilter;

        if not FilterReservEntry.FindFirst then
            exit;

        if CalcReservEntry2."Source Type" in [DATABASE::"Prod. Order Line", DATABASE::"Purchase Line"]
        then
            ReservEngineMgt.ModifyActionMessageDating(FilterReservEntry)
        else begin
            if FilterReservEntry.Positive then
                exit;
            FilterReservEntry.SetRange("Reservation Status", FilterReservEntry."Reservation Status"::Reservation,
              FilterReservEntry."Reservation Status"::Tracking);
            if not FilterReservEntry.FindSet then
                exit;
            repeat
                if ReservEntry2.Get(FilterReservEntry."Entry No.", not FilterReservEntry.Positive) then
                    ReservEngineMgt.ModifyActionMessageDating(ReservEntry2);
            until FilterReservEntry.Next = 0;
        end;
    end;

    procedure ClearActionMessageReferences()
    var
        ActionMessageEntry2: Record "Action Message Entry";
    begin
        ActionMessageEntry.Reset;
        ActionMessageEntry.FilterFromReservEntry(CalcReservEntry);
        if ActionMessageEntry.FindSet then
            repeat
                ActionMessageEntry2 := ActionMessageEntry;
                if ActionMessageEntry2.Quantity = 0 then
                    ActionMessageEntry2.Delete
                else begin
                    ActionMessageEntry2."Source Subtype" := 0;
                    ActionMessageEntry2."Source ID" := '';
                    ActionMessageEntry2."Source Batch Name" := '';
                    ActionMessageEntry2."Source Prod. Order Line" := 0;
                    ActionMessageEntry2."Source Ref. No." := 0;
                    ActionMessageEntry2."New Date" := 0D;
                    ActionMessageEntry2.Modify;
                end;
            until ActionMessageEntry.Next = 0;
    end;

    procedure SetItemTrackingHandling(Mode: Option "None","Allow deletion",Match)
    begin
        ItemTrackingHandling := Mode;
    end;

    procedure DeleteItemTrackingConfirm(): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not ItemTrackingExist(CalcReservEntry2) then
            exit(true);

        if ConfirmManagement.GetResponseOrDefault(
             StrSubstNo(Text011, CalcReservEntry2."Item No.", CalcReservEntry2.TextCaption), true)
        then
            exit(true);

        exit(false);
    end;

    local procedure ItemTrackingExist(var ReservEntry: Record "Reservation Entry"): Boolean
    var
        ReservEntry2: Record "Reservation Entry";
    begin
        ReservEntry2.Copy(ReservEntry);
        ReservEntry2.SetFilter("Item Tracking", '> %1', ReservEntry2."Item Tracking"::None);
        exit(not ReservEntry2.IsEmpty);
    end;

    procedure SetSerialLotNo(SerialNo: Code[50]; LotNo: Code[50])
    begin
        CalcReservEntry."Serial No." := SerialNo;
        CalcReservEntry."Lot No." := LotNo;
    end;

    procedure SetMatchFilter(var ReservEntry: Record "Reservation Entry"; var FilterReservEntry: Record "Reservation Entry"; SearchForSupply: Boolean; AvailabilityDate: Date)
    begin
        FilterReservEntry.Reset;
        FilterReservEntry.SetCurrentKey(
          "Item No.", "Variant Code", "Location Code", "Reservation Status",
          "Shipment Date", "Expected Receipt Date", "Serial No.", "Lot No.");
        FilterReservEntry.SetRange("Item No.", ReservEntry."Item No.");
        FilterReservEntry.SetRange("Variant Code", ReservEntry."Variant Code");
        FilterReservEntry.SetRange("Location Code", ReservEntry."Location Code");
        FilterReservEntry.SetRange("Reservation Status",
          FilterReservEntry."Reservation Status"::Reservation, FilterReservEntry."Reservation Status"::Surplus);
        if SearchForSupply then
            FilterReservEntry.SetFilter("Expected Receipt Date", '..%1', AvailabilityDate)
        else
            FilterReservEntry.SetFilter("Shipment Date", '>=%1', AvailabilityDate);
        if FieldFilterNeeded(ReservEntry, SearchForSupply, 0) then
            FilterReservEntry.SetFilter("Lot No.", GetFieldFilter);
        if FieldFilterNeeded(ReservEntry, SearchForSupply, 1) then
            FilterReservEntry.SetFilter("Serial No.", GetFieldFilter);
        FilterReservEntry.SetRange(Positive, SearchForSupply);
    end;

    procedure LookupLine(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        SalesLine: Record "Sales Line";
        PurchLine: Record "Purchase Line";
        ItemJnlLine: Record "Item Journal Line";
        ReqLine: Record "Requisition Line";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        PlanningComponent: Record "Planning Component";
        ServLine: Record "Service Line";
        JobPlanningLine: Record "Job Planning Line";
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
    begin
        case SourceType of
            DATABASE::"Sales Line":
                begin
                    SalesLine.Reset;
                    SalesLine.SetRange("Document Type", SourceSubtype);
                    SalesLine.SetRange("Document No.", SourceID);
                    SalesLine.SetRange("Line No.", SourceRefNo);
                    PAGE.Run(PAGE::"Sales Lines", SalesLine);
                end;
            DATABASE::"Requisition Line":
                begin
                    ReqLine.Reset;
                    ReqLine.SetRange("Worksheet Template Name", SourceID);
                    ReqLine.SetRange("Journal Batch Name", SourceBatchName);
                    ReqLine.SetRange("Line No.", SourceRefNo);
                    PAGE.Run(PAGE::"Requisition Lines", ReqLine);
                end;
            DATABASE::"Purchase Line":
                begin
                    PurchLine.Reset;
                    PurchLine.SetRange("Document Type", SourceSubtype);
                    PurchLine.SetRange("Document No.", SourceID);
                    PurchLine.SetRange("Line No.", SourceRefNo);
                    PAGE.Run(PAGE::"Purchase Lines", PurchLine);
                end;
            DATABASE::"Item Journal Line":
                begin
                    ItemJnlLine.Reset;
                    ItemJnlLine.SetRange("Journal Template Name", SourceID);
                    ItemJnlLine.SetRange("Journal Batch Name", SourceBatchName);
                    ItemJnlLine.SetRange("Line No.", SourceRefNo);
                    ItemJnlLine.SetRange("Entry Type", SourceSubtype);
                    PAGE.Run(PAGE::"Item Journal Lines", ItemJnlLine);
                end;
            DATABASE::"Item Ledger Entry":
                begin
                    ItemLedgEntry.Reset;
                    ItemLedgEntry.SetRange("Entry No.", SourceRefNo);
                    PAGE.Run(0, ItemLedgEntry);
                end;
            DATABASE::"Prod. Order Line":
                begin
                    ProdOrderLine.Reset;
                    ProdOrderLine.SetRange(Status, SourceSubtype);
                    ProdOrderLine.SetRange("Prod. Order No.", SourceID);
                    ProdOrderLine.SetRange("Line No.", SourceProdOrderLine);
                    PAGE.Run(0, ProdOrderLine);
                end;
            DATABASE::"Prod. Order Component":
                begin
                    ProdOrderComp.Reset;
                    ProdOrderComp.SetRange(Status, SourceSubtype);
                    ProdOrderComp.SetRange("Prod. Order No.", SourceID);
                    ProdOrderComp.SetRange("Prod. Order Line No.", SourceProdOrderLine);
                    ProdOrderComp.SetRange("Line No.", SourceRefNo);
                    PAGE.Run(0, ProdOrderComp);
                end;
            DATABASE::"Planning Component":
                begin
                    PlanningComponent.Reset;
                    PlanningComponent.SetRange("Worksheet Template Name", SourceID);
                    PlanningComponent.SetRange("Worksheet Batch Name", SourceBatchName);
                    PlanningComponent.SetRange("Worksheet Line No.", SourceProdOrderLine);
                    PlanningComponent.SetRange("Line No.", SourceRefNo);
                    PAGE.Run(0, PlanningComponent);
                end;
            DATABASE::"Service Line":
                begin
                    ServLine.Reset;
                    ServLine.SetRange("Document Type", SourceSubtype);
                    ServLine.SetRange("Document No.", SourceID);
                    ServLine.SetRange("Line No.", SourceRefNo);
                    PAGE.Run(0, ServLine);
                end;
            DATABASE::"Job Planning Line":
                begin
                    JobPlanningLine.Reset;
                    JobPlanningLine.SetCurrentKey("Job Contract Entry No.");
                    JobPlanningLine.SetRange("Job Contract Entry No.", SourceRefNo);
                    PAGE.Run(0, JobPlanningLine);
                end;
            DATABASE::"Assembly Header":
                begin
                    AsmHeader.Reset;
                    AsmHeader.SetRange("Document Type", SourceSubtype);
                    AsmHeader.SetRange("No.", SourceID);
                    PAGE.Run(PAGE::"Assembly Orders", AsmHeader);
                end;
            DATABASE::"Assembly Line":
                begin
                    AsmLine.Reset;
                    AsmLine.SetRange("Document Type", SourceSubtype);
                    AsmLine.SetRange("Document No.", SourceID);
                    AsmLine.SetRange("Line No.", SourceRefNo);
                    PAGE.Run(PAGE::"Assembly Lines", AsmLine);
                end;
            else
                OnLookupLine(SourceType, SourceSubtype, SourceID, SourceBatchName, SourceProdOrderLine, SourceRefNo);
        end;
    end;

    procedure LookupDocument(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer)
    var
        SalesHeader: Record "Sales Header";
        PurchHeader: Record "Purchase Header";
        ReqLine: Record "Requisition Line";
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgEntry: Record "Item Ledger Entry";
        ProdOrder: Record "Production Order";
        TransHeader: Record "Transfer Header";
        ServiceHeader: Record "Service Header";
        Job: Record Job;
        AsmHeader: Record "Assembly Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookupDocument(SourceType, SourceSubtype, SourceID, SourceBatchName, SourceProdOrderLine, SourceRefNo, IsHandled);
        if IsHandled then
            exit;

        case SourceType of
            DATABASE::"Sales Line":
                begin
                    SalesHeader.Reset;
                    SalesHeader.SetRange("Document Type", SourceSubtype);
                    SalesHeader.SetRange("No.", SourceID);
                    case SourceSubtype of
                        0:
                            PAGE.RunModal(PAGE::"Sales Quote", SalesHeader);
                        1:
                            PAGE.RunModal(PAGE::"Sales Order", SalesHeader);
                        2:
                            PAGE.RunModal(PAGE::"Sales Invoice", SalesHeader);
                        3:
                            PAGE.RunModal(PAGE::"Sales Credit Memo", SalesHeader);
                        5:
                            PAGE.RunModal(PAGE::"Sales Return Order", SalesHeader);
                    end;
                end;
            DATABASE::"Requisition Line":
                begin
                    ReqLine.Reset;
                    ReqLine.SetRange("Worksheet Template Name", SourceID);
                    ReqLine.SetRange("Journal Batch Name", SourceBatchName);
                    ReqLine.SetRange("Line No.", SourceRefNo);
                    PAGE.RunModal(PAGE::"Requisition Lines", ReqLine);
                end;
            DATABASE::"Planning Component":
                begin
                    ReqLine.Reset;
                    ReqLine.SetRange("Worksheet Template Name", SourceID);
                    ReqLine.SetRange("Journal Batch Name", SourceBatchName);
                    ReqLine.SetRange("Line No.", SourceProdOrderLine);
                    PAGE.RunModal(PAGE::"Requisition Lines", ReqLine);
                end;
            DATABASE::"Purchase Line":
                begin
                    PurchHeader.Reset;
                    PurchHeader.SetRange("Document Type", SourceSubtype);
                    PurchHeader.SetRange("No.", SourceID);
                    case SourceSubtype of
                        0:
                            PAGE.RunModal(PAGE::"Purchase Quote", PurchHeader);
                        1:
                            PAGE.RunModal(PAGE::"Purchase Order", PurchHeader);
                        2:
                            PAGE.RunModal(PAGE::"Purchase Invoice", PurchHeader);
                        3:
                            PAGE.RunModal(PAGE::"Purchase Credit Memo", PurchHeader);
                        5:
                            PAGE.RunModal(PAGE::"Purchase Return Order", PurchHeader);
                    end;
                end;
            DATABASE::"Item Journal Line":
                begin
                    ItemJnlLine.Reset;
                    ItemJnlLine.SetRange("Journal Template Name", SourceID);
                    ItemJnlLine.SetRange("Journal Batch Name", SourceBatchName);
                    ItemJnlLine.SetRange("Line No.", SourceRefNo);
                    ItemJnlLine.SetRange("Entry Type", SourceSubtype);
                    PAGE.RunModal(PAGE::"Item Journal Lines", ItemJnlLine);
                end;
            DATABASE::"Item Ledger Entry":
                begin
                    ItemLedgEntry.Reset;
                    ItemLedgEntry.SetRange("Entry No.", SourceRefNo);
                    PAGE.RunModal(0, ItemLedgEntry);
                end;
            DATABASE::"Prod. Order Line",
            DATABASE::"Prod. Order Component":
                begin
                    ProdOrder.Reset;
                    ProdOrder.SetRange(Status, SourceSubtype);
                    ProdOrder.SetRange("No.", SourceID);
                    case SourceSubtype of
                        0:
                            PAGE.RunModal(PAGE::"Simulated Production Order", ProdOrder);
                        1:
                            PAGE.RunModal(PAGE::"Planned Production Order", ProdOrder);
                        2:
                            PAGE.RunModal(PAGE::"Firm Planned Prod. Order", ProdOrder);
                        3:
                            PAGE.RunModal(PAGE::"Released Production Order", ProdOrder);
                    end;
                end;
            DATABASE::"Transfer Line":
                begin
                    TransHeader.Reset;
                    TransHeader.SetRange("No.", SourceID);
                    PAGE.RunModal(PAGE::"Transfer Order", TransHeader);
                end;
            DATABASE::"Service Line":
                begin
                    ServiceHeader.Reset;
                    ServiceHeader.SetRange("Document Type", SourceSubtype);
                    ServiceHeader.SetRange("No.", SourceID);
                    if SourceSubtype = 0 then
                        PAGE.RunModal(PAGE::"Service Quote", ServiceHeader)
                    else
                        PAGE.RunModal(PAGE::"Service Order", ServiceHeader);
                end;
            DATABASE::"Job Planning Line":
                begin
                    Job.Reset;
                    Job.SetRange("No.", SourceID);
                    PAGE.RunModal(PAGE::"Job Card", Job)
                end;
            DATABASE::"Assembly Header",
            DATABASE::"Assembly Line":
                begin
                    AsmHeader.Reset;
                    AsmHeader.SetRange("Document Type", SourceSubtype);
                    AsmHeader.SetRange("No.", SourceID);
                    case SourceSubtype of
                        0:
                            ;
                        1:
                            PAGE.RunModal(PAGE::"Assembly Order", AsmHeader);
                        5:
                            ;
                    end;
                end;
            else
                OnLookupDocument(SourceType, SourceSubtype, SourceID, SourceBatchName, SourceProdOrderLine, SourceRefNo);
        end;
    end;

    local procedure CallCalcReservedQtyOnPick()
    begin
        if Positive and (CalcReservEntry."Location Code" <> '') then
            if Location.Get(CalcReservEntry."Location Code") and
               (Location."Bin Mandatory" or Location."Require Pick")
            then
                CalcReservedQtyOnPick(TotalAvailQty, QtyAllocInWhse);
    end;

    local procedure CalcReservedQtyOnPick(var AvailQty: Decimal; var AllocQty: Decimal)
    var
        WhseActivLine: Record "Warehouse Activity Line";
        TempWhseActivLine2: Record "Warehouse Activity Line" temporary;
        WhseAvailMgt: Codeunit "Warehouse Availability Mgt.";
        PickQty: Decimal;
        QtyOnOutboundBins: Decimal;
        QtyOnInvtMovement: Decimal;
        QtyOnAssemblyBin: Decimal;
        QtyOnOpenShopFloorBin: Decimal;
        QtyOnToProductionBin: Decimal;
    begin
        with CalcReservEntry do begin
            GetItemSetup(CalcReservEntry);
            Item.SetRange("Location Filter", "Location Code");
            Item.SetRange("Variant Filter", "Variant Code");
            if "Lot No." <> '' then
                Item.SetRange("Lot No. Filter", "Lot No.");
            if "Serial No." <> '' then
                Item.SetRange("Serial No. Filter", "Serial No.");
            Item.CalcFields(
              Inventory, "Reserved Qty. on Inventory");

            WhseActivLine.SetCurrentKey(
              "Item No.", "Bin Code", "Location Code", "Action Type", "Variant Code",
              "Unit of Measure Code", "Breakbulk No.", "Activity Type", "Lot No.", "Serial No.");

            WhseActivLine.SetRange("Item No.", "Item No.");
            if Location."Bin Mandatory" then
                WhseActivLine.SetFilter("Bin Code", '<>%1', '');
            WhseActivLine.SetRange("Location Code", "Location Code");
            WhseActivLine.SetFilter(
              "Action Type", '%1|%2', WhseActivLine."Action Type"::" ", WhseActivLine."Action Type"::Take);
            WhseActivLine.SetRange("Variant Code", "Variant Code");
            WhseActivLine.SetRange("Breakbulk No.", 0);
            WhseActivLine.SetFilter(
              "Activity Type", '%1|%2', WhseActivLine."Activity Type"::Pick, WhseActivLine."Activity Type"::"Invt. Pick");
            if "Lot No." <> '' then
                WhseActivLine.SetRange("Lot No.", "Lot No.");
            if "Serial No." <> '' then
                WhseActivLine.SetRange("Serial No.", "Serial No.");
            WhseActivLine.CalcSums("Qty. Outstanding (Base)");

            if Location."Require Pick" then begin
                QtyOnOutboundBins :=
                  CreatePick.CalcQtyOnOutboundBins(
                    "Location Code", "Item No.", "Variant Code", "Lot No.", "Serial No.", true);

                QtyReservedOnPickShip :=
                  WhseAvailMgt.CalcReservQtyOnPicksShips(
                    "Location Code", "Item No.", "Variant Code", TempWhseActivLine2);

                QtyOnInvtMovement := CalcQtyOnInvtMovement(WhseActivLine);

                QtyOnAssemblyBin :=
                  WhseAvailMgt.CalcQtyOnBin(
                    "Location Code", Location."To-Assembly Bin Code", "Item No.", "Variant Code", "Lot No.", "Serial No.");

                QtyOnOpenShopFloorBin :=
                  WhseAvailMgt.CalcQtyOnBin(
                    "Location Code", Location."Open Shop Floor Bin Code", "Item No.", "Variant Code", "Lot No.", "Serial No.");

                QtyOnToProductionBin :=
                  WhseAvailMgt.CalcQtyOnBin(
                    "Location Code", Location."To-Production Bin Code", "Item No.", "Variant Code", "Lot No.", "Serial No.");
            end;

            AllocQty :=
              WhseActivLine."Qty. Outstanding (Base)" + QtyOnInvtMovement +
              QtyOnOutboundBins + QtyOnAssemblyBin + QtyOnOpenShopFloorBin + QtyOnToProductionBin;
            PickQty := WhseActivLine."Qty. Outstanding (Base)" + QtyOnInvtMovement;

            AvailQty :=
              Item.Inventory - PickQty - QtyOnOutboundBins - QtyOnAssemblyBin - QtyOnOpenShopFloorBin - QtyOnToProductionBin -
              Item."Reserved Qty. on Inventory" + QtyReservedOnPickShip;
        end;
    end;

    local procedure SaveItemTrackingAsSurplus(var ReservEntry: Record "Reservation Entry"; NewQty: Decimal; NewQtyBase: Decimal) QuantityIsValidated: Boolean
    var
        SurplusEntry: Record "Reservation Entry";
        CreateReservEntry2: Codeunit "Create Reserv. Entry";
        QtyToSave: Decimal;
        QtyToSaveBase: Decimal;
        QtyToHandleThisLine: Decimal;
        QtyToInvoiceThisLine: Decimal;
        SignFactor: Integer;
    begin
        QtyToSave := ReservEntry.Quantity - NewQty;
        QtyToSaveBase := ReservEntry."Quantity (Base)" - NewQtyBase;

        if QtyToSaveBase = 0 then
            exit;

        if ReservEntry."Item Tracking" = ReservEntry."Item Tracking"::None then
            exit;

        if ReservEntry."Source Type" = DATABASE::"Item Ledger Entry" then
            exit;

        if QtyToSaveBase * ReservEntry."Quantity (Base)" < 0 then
            ReservEntry.FieldError("Quantity (Base)");

        SignFactor := ReservEntry."Quantity (Base)" / Abs(ReservEntry."Quantity (Base)");

        if SignFactor * QtyToSaveBase > SignFactor * ReservEntry."Quantity (Base)" then
            ReservEntry.FieldError("Quantity (Base)");

        QtyToHandleThisLine := ReservEntry."Qty. to Handle (Base)" - NewQtyBase;
        QtyToInvoiceThisLine := ReservEntry."Qty. to Invoice (Base)" - NewQtyBase;

        ReservEntry.Validate("Quantity (Base)", NewQtyBase);

        if SignFactor * QtyToHandleThisLine < 0 then begin
            ReservEntry.Validate("Qty. to Handle (Base)", ReservEntry."Qty. to Handle (Base)" + QtyToHandleThisLine);
            QtyToHandleThisLine := 0;
        end;

        if SignFactor * QtyToInvoiceThisLine < 0 then begin
            ReservEntry.Validate("Qty. to Invoice (Base)", ReservEntry."Qty. to Invoice (Base)" + QtyToInvoiceThisLine);
            QtyToInvoiceThisLine := 0;
        end;

        QuantityIsValidated := true;

        SurplusEntry := ReservEntry;
        SurplusEntry."Reservation Status" := SurplusEntry."Reservation Status"::Surplus;
        if SurplusEntry.Positive then
            SurplusEntry."Shipment Date" := 0D
        else
            SurplusEntry."Expected Receipt Date" := 0D;
        CreateReservEntry2.SetQtyToHandleAndInvoice(QtyToHandleThisLine, QtyToInvoiceThisLine);
        CreateReservEntry2.CreateRemainingReservEntry(SurplusEntry, QtyToSave, QtyToSaveBase);
    end;

    procedure CalcIsAvailTrackedQtyInBin(ItemNo: Code[20]; BinCode: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer): Boolean
    var
        ReservationEntry: Record "Reservation Entry";
        WhseEntry: Record "Warehouse Entry";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WhseSNRequired: Boolean;
        WhseLNRequired: Boolean;
    begin
        ItemTrackingMgt.CheckWhseItemTrkgSetup(ItemNo, WhseSNRequired, WhseLNRequired, false);
        if not (WhseSNRequired or WhseLNRequired) or (BinCode = '') then
            exit(true);

        ReservationEntry.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, false);
        ReservationEntry.SetSourceFilter(SourceBatchName, SourceProdOrderLine);
        ReservationEntry.SetRange(Positive, false);
        if ReservationEntry.FindSet then
            repeat
                if ReservEntryPositiveTypeIsItemLedgerEntry(ReservationEntry."Entry No.") then begin
                    WhseEntry.SetCurrentKey("Item No.", "Location Code", "Variant Code", "Bin Type Code");
                    WhseEntry.SetRange("Item No.", ItemNo);
                    WhseEntry.SetRange("Location Code", LocationCode);
                    WhseEntry.SetRange("Bin Code", BinCode);
                    WhseEntry.SetRange("Variant Code", VariantCode);
                    if ReservationEntry."Lot No." <> '' then
                        WhseEntry.SetRange("Lot No.", ReservationEntry."Lot No.");
                    if ReservationEntry."Serial No." <> '' then
                        WhseEntry.SetRange("Serial No.", ReservationEntry."Serial No.");
                    WhseEntry.CalcSums("Qty. (Base)");
                    if WhseEntry."Qty. (Base)" < Abs(ReservationEntry."Quantity (Base)") then
                        exit(false);
                end;
            until ReservationEntry.Next = 0;

        exit(true);
    end;

    local procedure CalcQtyOnInvtMovement(var WarehouseActivityLine: Record "Warehouse Activity Line"): Decimal
    var
        xWarehouseActivityLine: Record "Warehouse Activity Line";
        OutstandingQty: Decimal;
    begin
        xWarehouseActivityLine.Copy(WarehouseActivityLine);

        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Movement");
        if WarehouseActivityLine.Find('-') then
            repeat
                if WarehouseActivityLine."Source Type" <> 0 then
                    OutstandingQty += WarehouseActivityLine."Qty. Outstanding (Base)"
            until WarehouseActivityLine.Next = 0;

        WarehouseActivityLine.Copy(xWarehouseActivityLine);
        exit(OutstandingQty);
    end;

    local procedure ProdJnlLineEntry(ReservationEntry: Record "Reservation Entry"): Boolean
    begin
        with ReservationEntry do
            exit(("Source Type" = DATABASE::"Item Journal Line") and ("Source Subtype" = 6));
    end;

    local procedure CalcDownToQtySyncingToAssembly(ReservEntry: Record "Reservation Entry"): Decimal
    var
        SynchronizingSalesLine: Record "Sales Line";
    begin
        if ReservEntry."Source Type" = DATABASE::"Sales Line" then begin
            SynchronizingSalesLine.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Ref. No.");
            if (Item."Order Tracking Policy" <> Item."Order Tracking Policy"::None) and
               (Item."Assembly Policy" = Item."Assembly Policy"::"Assemble-to-Order") and
               (Item."Replenishment System" = Item."Replenishment System"::Assembly) and
               (SynchronizingSalesLine."Quantity (Base)" = 0)
            then
                exit(ReservEntry."Quantity (Base)" * CreateReservEntry.SignFactor(ReservEntry));
        end;
    end;

    local procedure CalcCurrLineReservQtyOnPicksShips(ReservationEntry: Record "Reservation Entry"): Decimal
    var
        ReservEntry: Record "Reservation Entry";
        TempWhseActivLine: Record "Warehouse Activity Line" temporary;
        WhseAvailMgt: Codeunit "Warehouse Availability Mgt.";
        PickQty: Decimal;
    begin
        with ReservEntry do begin
            PickQty := WhseAvailMgt.CalcRegisteredAndOutstandingPickQty(ReservationEntry, TempWhseActivLine);

            SetSourceFilter(
              ReservationEntry."Source Type", ReservationEntry."Source Subtype",
              ReservationEntry."Source ID", ReservationEntry."Source Ref. No.", false);
            SetRange("Source Prod. Order Line", ReservationEntry."Source Prod. Order Line");
            SetRange("Reservation Status", "Reservation Status"::Reservation);
            CalcSums("Quantity (Base)");
            if -"Quantity (Base)" > PickQty then
                exit(PickQty);
            exit(-"Quantity (Base)");
        end;
    end;

    local procedure CheckQuantityIsCompletelyReleased(QtyToRelease: Decimal; DeleteAll: Boolean; CurrentSerialNo: Code[50]; CurrentLotNo: Code[50]; ReservEntry: Record "Reservation Entry")
    begin
        if QtyToRelease = 0 then
            exit;

        if ItemTrackingHandling = ItemTrackingHandling::None then begin
            if DeleteAll then
                Error(Text010, ReservEntry."Item No.", ReservEntry.TextCaption);
            if not ProdJnlLineEntry(ReservEntry) then
                Error(Text008, ReservEntry."Item No.", ReservEntry.TextCaption);
        end;

        if ItemTrackingHandling = ItemTrackingHandling::Match then
            Error(Text009, CurrentSerialNo, CurrentLotNo, Abs(QtyToRelease));
    end;

    local procedure ReservEntryPositiveTypeIsItemLedgerEntry(ReservationEntryNo: Integer): Boolean
    var
        ReservationEntryPositive: Record "Reservation Entry";
    begin
        if ReservationEntryPositive.Get(ReservationEntryNo, true) then
            exit(ReservationEntryPositive."Source Type" = DATABASE::"Item Ledger Entry");

        exit(true);
    end;

    procedure DeleteDocumentReservation(TableID: Integer; DocType: Option; DocNo: Code[20]; HideValidationDialog: Boolean)
    var
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        ConfirmManagement: Codeunit "Confirm Management";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        DocTypeCaption: Text;
        Confirmed: Boolean;
    begin
        OnBeforeDeleteDocumentReservation(TableID, DocType, DocNo, HideValidationDialog);

        with ReservEntry do begin
            Reset;
            SetCurrentKey(
              "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
              "Source Batch Name", "Source Prod. Order Line", "Reservation Status");
            if TableID <> DATABASE::"Prod. Order Line" then begin
                SetRange("Source Type", TableID);
                SetRange("Source Prod. Order Line", 0);
            end else
                SetFilter("Source Type", '%1|%2', DATABASE::"Prod. Order Line", DATABASE::"Prod. Order Component");

            case TableID of
                DATABASE::"Transfer Line":
                    begin
                        SetRange("Source Subtype");
                        DocTypeCaption := StrSubstNo(DeleteTransLineWithItemReservQst, DocNo);
                    end;
                DATABASE::"Prod. Order Line":
                    begin
                        SetRange("Source Subtype", DocType);
                        RecRef.Open(TableID);
                        FieldRef := RecRef.FieldIndex(1);
                        DocTypeCaption :=
                          StrSubstNo(DeleteProdOrderLineWithItemReservQst, SelectStr(DocType + 1, FieldRef.OptionCaption), DocNo);
                    end;
                else begin
                        SetRange("Source Subtype", DocType);
                        RecRef.Open(TableID);
                        FieldRef := RecRef.FieldIndex(1);
                        DocTypeCaption :=
                          StrSubstNo(DeleteDocLineWithItemReservQst, SelectStr(DocType + 1, FieldRef.OptionCaption), DocNo);
                    end;
            end;

            SetRange("Source ID", DocNo);
            SetRange("Source Batch Name", '');
            SetFilter("Item Tracking", '> %1', "Item Tracking"::None);
            if IsEmpty then
                exit;

            if HideValidationDialog then
                Confirmed := true
            else
                Confirmed := ConfirmManagement.GetResponseOrDefault(DocTypeCaption, true);

            if not Confirmed then
                Error('');

            if FindSet then
                repeat
                    ReservEntry2 := ReservEntry;
                    ReservEntry2.ClearItemTrackingFields;
                    ReservEntry2.Modify;
                until Next = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetSkipUntrackedSurplus(NewSkipUntrackedSurplus: Boolean)
    begin
        SkipUntrackedSurplus := NewSkipUntrackedSurplus;
    end;

    local procedure NarrowQtyToReserveDownToTrackedQuantity(ReservEntry: Record "Reservation Entry"; RowID: Text[250]; var QtyThisLine: Decimal; var QtyThisLineBase: Decimal)
    var
        FilterReservEntry: Record "Reservation Entry";
        TempTrackingSpec: Record "Tracking Specification" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        MaxReservQtyPerLotOrSerial: Decimal;
        MaxReservQtyBasePerLotOrSerial: Decimal;
    begin
        if not ReservEntry.TrackingExists then
            exit;

        FilterReservEntry.SetPointer(RowID);
        FilterReservEntry.SetPointerFilter;
        FilterReservEntry.SetTrackingFilterFromReservEntry(ReservEntry);
        ItemTrackingMgt.SumUpItemTracking(FilterReservEntry, TempTrackingSpec, true, true);

        MaxReservQtyBasePerLotOrSerial := TempTrackingSpec."Quantity (Base)";
        MaxReservQtyPerLotOrSerial := UOMMgt.CalcQtyFromBase(MaxReservQtyBasePerLotOrSerial, TempTrackingSpec."Qty. per Unit of Measure");
        QtyThisLine := MinAbs(QtyThisLine, MaxReservQtyPerLotOrSerial) * Sign(QtyThisLine);
        QtyThisLineBase := MinAbs(QtyThisLineBase, MaxReservQtyPerLotOrSerial) * Sign(QtyThisLineBase);
    end;

    local procedure IsSpecialOrderOrDropShipment(ReservationEntry: Record "Reservation Entry"): Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        if ReservationEntry."Source Type" = DATABASE::"Sales Line" then
            if SalesLine.Get(ReservationEntry."Source Subtype", ReservationEntry."Source ID", ReservationEntry."Source Ref. No.") then
                if SalesLine."Special Order" or SalesLine."Drop Shipment" then
                    exit(true);
        exit(false);
    end;

    local procedure MinAbs(Value1: Decimal; Value2: Decimal): Decimal
    begin
        Value1 := Abs(Value1);
        Value2 := Abs(Value2);
        if Value1 <= Value2 then
            exit(Value1);
        exit(Value2);
    end;

    local procedure Sign(Value: Decimal): Integer
    begin
        if Value >= 0 then
            exit(1);
        exit(-1);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAutoReserve(var ReservationEntry: Record "Reservation Entry"; var FullAutoReservation: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAutoReserveOneLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcReservation(var ReservEntry: Record "Reservation Entry"; var ItemLedgEntry: Record "Item Ledger Entry"; var ResSummEntryNo: Integer; var QtyThisLine: Decimal; var QtyThisLineBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteDocumentReservation(TableID: Integer; DocType: Option; DocNo: Code[20]; HideValidationDialog: Boolean)
    begin
    end;

    [IntegrationEvent(TRUE, false)]
    local procedure OnAfterInitFilter(var CalcReservEntry: Record "Reservation Entry"; EntryID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetValueArray(EntryStatus: Option Reservation,Tracking,Simulation; var ValueArray: array[18] of Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateStatistics(var ReservEntrySummary: Record "Entry Summary"; AvailabilityDate: Date; var CalcSumValue: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAutoReserveItemLedgEntryOnFindFirstItemLedgEntry(CalcReservEntry: Record "Reservation Entry"; var CalcItemLedgEntry: Record "Item Ledger Entry"; var InvSearch: Text[1]; var IsHandled: Boolean; var IsFound: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAutoReserveItemLedgEntryOnFindNextItemLedgEntry(CalcReservEntry: Record "Reservation Entry"; var CalcItemLedgEntry: Record "Item Ledger Entry"; var InvSearch: Text[1]; var IsHandled: Boolean; var IsFound: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserveItemLedgEntry(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; var IsReserved: Boolean; CalcReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReservePurchLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; var IsReserved: Boolean; Search: Text[1]; NextStep: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserveSalesLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; var IsReserved: Boolean; Search: Text[1]; NextStep: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserveProdOrderLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; var IsReserved: Boolean; Search: Text[1]; NextStep: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserveProdOrderComp(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; var IsReserved: Boolean; Search: Text[1]; NextStep: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserveAssemblyHeader(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; var IsReserved: Boolean; Search: Text[1]; NextStep: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserveAssemblyLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; var IsReserved: Boolean; Search: Text[1]; NextStep: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserveTransLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; var IsReserved: Boolean; Search: Text[1]; NextStep: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserveServLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; var IsReserved: Boolean; Search: Text[1]; NextStep: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserveJobPlanningLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; var IsReserved: Boolean; Search: Text[1]; NextStep: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateReservation(var TrkgSpec: Record "Tracking Specification"; var ReservEntry: Record "Reservation Entry"; var ItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupDocument(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateItemLedgEntryStats(var CalcReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSourceRecordValue(var ReservEntry: Record "Reservation Entry"; SetAsCurrent: Boolean; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"; var ReturnQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupDocument(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupLine(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetAssemblyHeaderOnBeforeUpdateReservation(var ReservEntry: Record "Reservation Entry"; AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetAssemblyLineOnBeforeUpdateReservation(var ReservEntry: Record "Reservation Entry"; AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetItemJnlLineOnBeforeUpdateReservation(var ReservEntry: Record "Reservation Entry"; ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetItemLedgEntryOnBeforeUpdateReservation(var ReservEntry: Record "Reservation Entry"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetJobPlanningLineOnBeforeUpdateReservation(var ReservEntry: Record "Reservation Entry"; JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetJobJnlLineOnBeforeUpdateReservation(var ReservEntry: Record "Reservation Entry"; JobJnlLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetSalesLineOnBeforeUpdateReservation(var ReservEntry: Record "Reservation Entry"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetPlanningCompOnBeforeUpdateReservation(var ReservEntry: Record "Reservation Entry"; PlanningComponent: Record "Planning Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetProdOrderLineOnBeforeUpdateReservation(var ReservEntry: Record "Reservation Entry"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetProdOrderCompOnBeforeUpdateReservation(var ReservEntry: Record "Reservation Entry"; ProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetPurchLineOnBeforeUpdateReservation(var ReservEntry: Record "Reservation Entry"; PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetReqLineOnBeforeUpdateReservation(var ReservEntry: Record "Reservation Entry"; ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetServLineOnBeforeUpdateReservation(var ReservEntry: Record "Reservation Entry"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetTransLineOnBeforeUpdateReservation(var ReservEntry: Record "Reservation Entry"; TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateItemLedgEntryStatsUpdateTotals(CalcReservEntry: Record "Reservation Entry"; var CalcItemLedgEntry: Record "Item Ledger Entry"; TotalAvailQty: Decimal; QtyOnOutBound: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateItemTrackingLineStatsOnBeforeReservEntrySummaryInsert(var ReservEntrySummary: Record "Entry Summary"; ReservationEntry: Record "Reservation Entry")
    begin
    end;
}

