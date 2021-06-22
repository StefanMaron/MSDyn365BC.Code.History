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
        Text003: Label 'CU99000845: CalculateRemainingQty - Source type missing';
        Text004: Label 'Codeunit 99000845: Illegal FieldFilter parameter';
        Text007: Label 'CU99000845 DeleteReservEntries2: Surplus order tracking double record detected.';
        CalcReservEntry: Record "Reservation Entry";
        CalcReservEntry2: Record "Reservation Entry";
        CalcItemLedgEntry: Record "Item Ledger Entry";
        Item: Record Item;
        Location: Record Location;
        MfgSetup: Record "Manufacturing Setup";
        SKU: Record "Stockkeeping Unit";
        ItemTrackingCode: Record "Item Tracking Code";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        CallTrackingSpecification: Record "Tracking Specification";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        CreatePick: Codeunit "Create Pick";
        UOMMgt: Codeunit "Unit of Measure Management";
        ItemTrackingType: Enum "Item Tracking Type";
        SourceRecRef: RecordRef;
        RefOrderType: Option;
        PlanningLineOrigin: Option;
        Positive: Boolean;
        CurrentBindingIsSet: Boolean;
        HandleItemTracking: Boolean;
        InvSearch: Text[1];
        FieldFilter: Text;
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

    procedure SetReservSource(NewRecordVar: Variant)
    begin
        SourceRecRef.GetTable(NewRecordVar);
        SetReservSource(SourceRecRef, 0);
    end;

    procedure SetReservSource(NewRecordVar: Variant; Direction: Enum "Transfer Direction")
    begin
        SourceRecRef.GetTable(NewRecordVar);
        SetReservSource(SourceRecRef, Direction);
    end;

    procedure SetReservSource(NewSourceRecRef: RecordRef; Direction: Enum "Transfer Direction")
    begin
        ClearAll;
        TempTrackingSpecification.DeleteAll();

        SourceRecRef := NewSourceRecRef;

        case SourceRecRef.Number of
            DATABASE::"Sales Line":
                SetSourceForSalesLine;
            DATABASE::"Requisition Line":
                SetSourceForReqLine;
            DATABASE::"Purchase Line":
                SetSourceForPurchLine;
            DATABASE::"Item Journal Line":
                SetSourceForItemJnlLine;
            DATABASE::"Item Ledger Entry":
                SetSourceForItemLedgerEntry;
            DATABASE::"Prod. Order Line":
                SetSourceForProdOrderLine;
            DATABASE::"Prod. Order Component":
                SetSourceForProdOrderComp;
            DATABASE::"Planning Component":
                SetSourceForPlanningComp;
            DATABASE::"Transfer Line":
                SetSourceForTransferLine(Direction);
            DATABASE::"Service Line":
                SetSourceForServiceLine;
            DATABASE::"Job Journal Line":
                SetSourceForJobJournalLine;
            DATABASE::"Job Planning Line":
                SetSourceForJobPlanningLine;
            DATABASE::"Assembly Header":
                SetSourceForAssemblyHeader;
            DATABASE::"Assembly Line":
                SetSourceForAssemblyLine;
        end;
    end;

    local procedure SetSourceForAssemblyHeader()
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        SourceRecRef.SetTable(AssemblyHeader);
        AssemblyHeader.SetReservationEntry(CalcReservEntry);
        OnSetAssemblyHeaderOnBeforeUpdateReservation(CalcReservEntry, AssemblyHeader);
        UpdateReservation((CreateReservEntry.SignFactor(CalcReservEntry) * AssemblyHeader."Remaining Quantity (Base)") < 0);
    end;

    local procedure SetSourceForAssemblyLine()
    var
        AssemblyLine: Record "Assembly Line";
    begin
        SourceRecRef.SetTable(AssemblyLine);
        AssemblyLine.SetReservationEntry(CalcReservEntry);
        OnSetAssemblyLineOnBeforeUpdateReservation(CalcReservEntry, AssemblyLine);
        UpdateReservation((CreateReservEntry.SignFactor(CalcReservEntry) * AssemblyLine."Remaining Quantity (Base)") < 0);
    end;

    local procedure SetSourceForItemJnlLine()
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        SourceRecRef.SetTable(ItemJnlLine);
        ItemJnlLine.SetReservationEntry(CalcReservEntry);
        OnSetItemJnlLineOnBeforeUpdateReservation(CalcReservEntry, ItemJnlLine);
        UpdateReservation((CreateReservEntry.SignFactor(CalcReservEntry) * ItemJnlLine."Quantity (Base)") < 0);
    end;

    local procedure SetSourceForItemLedgerEntry()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        SourceRecRef.SetTable(ItemLedgerEntry);
        ItemLedgerEntry.SetReservationEntry(CalcReservEntry);
        CalcReservEntry.CopyTrackingFromItemLedgEntry(ItemLedgerEntry);
        OnSetItemLedgEntryOnBeforeUpdateReservation(CalcReservEntry, ItemLedgerEntry);
        UpdateReservation(Positive);
    end;

    local procedure SetSourceForJobJournalLine()
    var
        JobJournalLine: Record "Job Journal Line";
    begin
        SourceRecRef.SetTable(JobJournalLine);
        JobJournalLine.SetReservationEntry(CalcReservEntry);
        OnSetJobJnlLineOnBeforeUpdateReservation(CalcReservEntry, JobJournalLine);
        UpdateReservation((CreateReservEntry.SignFactor(CalcReservEntry) * JobJournalLine."Quantity (Base)") < 0);
    end;

    local procedure SetSourceForJobPlanningLine()
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        SourceRecRef.SetTable(JobPlanningLine);
        JobPlanningLine.SetReservationEntry(CalcReservEntry);
        OnSetJobPlanningLineOnBeforeUpdateReservation(CalcReservEntry, JobPlanningLine);
        UpdateReservation((CreateReservEntry.SignFactor(CalcReservEntry) * JobPlanningLine."Remaining Qty. (Base)") <= 0);
    end;

    local procedure SetSourceForReqLine()
    var
        ReqLine: Record "Requisition Line";
    begin
        SourceRecRef.SetTable(ReqLine);
        ReqLine.SetReservationEntry(CalcReservEntry);
        RefOrderType := ReqLine."Ref. Order Type";
        PlanningLineOrigin := ReqLine."Planning Line Origin";
        OnSetReqLineOnBeforeUpdateReservation(CalcReservEntry, ReqLine);
        UpdateReservation(ReqLine."Net Quantity (Base)" < 0);
    end;

    local procedure SetSourceForProdOrderLine()
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        SourceRecRef.SetTable(ProdOrderLine);
        ProdOrderLine.SetReservationEntry(CalcReservEntry);
        OnSetProdOrderLineOnBeforeUpdateReservation(CalcReservEntry, ProdOrderLine);
        UpdateReservation(ProdOrderLine."Remaining Qty. (Base)" < 0);
    end;

    local procedure SetSourceForProdOrderComp()
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        SourceRecRef.SetTable(ProdOrderComp);
        ProdOrderComp.SetReservationEntry(CalcReservEntry);
        OnSetProdOrderCompOnBeforeUpdateReservation(CalcReservEntry, ProdOrderComp);
        UpdateReservation(ProdOrderComp."Remaining Qty. (Base)" > 0);
    end;

    local procedure SetSourceForPlanningComp()
    var
        PlanningComponent: Record "Planning Component";
    begin
        SourceRecRef.SetTable(PlanningComponent);
        PlanningComponent.SetReservationEntry(CalcReservEntry);
        OnSetPlanningCompOnBeforeUpdateReservation(CalcReservEntry, PlanningComponent);
        UpdateReservation(PlanningComponent."Net Quantity (Base)" > 0);
    end;

    local procedure SetSourceForPurchLine()
    var
        PurchLine: Record "Purchase Line";
    begin
        SourceRecRef.SetTable(PurchLine);
        PurchLine.SetReservationEntry(CalcReservEntry);
        OnSetPurchLineOnBeforeUpdateReservation(CalcReservEntry, PurchLine);
        UpdateReservation((CreateReservEntry.SignFactor(CalcReservEntry) * PurchLine."Outstanding Qty. (Base)") < 0);
    end;

    local procedure SetSourceForTransferLine(Direction: Enum "Transfer Direction")
    var
        TransferLine: Record "Transfer Line";
    begin
        SourceRecRef.SetTable(TransferLine);
        TransferLine.SetReservationEntry(CalcReservEntry, Direction);
        OnSetTransLineOnBeforeUpdateReservation(CalcReservEntry, TransferLine);
        UpdateReservation((CreateReservEntry.SignFactor(CalcReservEntry) * TransferLine."Outstanding Qty. (Base)") <= 0);
    end;

    local procedure SetSourceForSalesLine()
    var
        SalesLine: Record "Sales Line";
    begin
        SourceRecRef.SetTable(SalesLine);
        SalesLine.SetReservationEntry(CalcReservEntry);
        OnSetSalesLineOnBeforeUpdateReservation(CalcReservEntry, SalesLine);
        UpdateReservation((CreateReservEntry.SignFactor(CalcReservEntry) * SalesLine."Outstanding Qty. (Base)") <= 0);
    end;

    local procedure SetSourceForServiceLine()
    var
        ServiceLine: Record "Service Line";
    begin
        SourceRecRef.SetTable(ServiceLine);
        ServiceLine.SetReservationEntry(CalcReservEntry);
        OnSetServLineOnBeforeUpdateReservation(CalcReservEntry, ServiceLine);
        UpdateReservation((CreateReservEntry.SignFactor(CalcReservEntry) * ServiceLine."Outstanding Qty. (Base)") <= 0);
    end;

    [Obsolete('Replaced by SetReservSource procedure.','16.0')]
    procedure SetSalesLine(NewSalesLine: Record "Sales Line")
    begin
        SourceRecRef.GetTable(NewSalesLine);
        SetReservSource(SourceRecRef, 0);
    end;

    [Obsolete('Replaced by SetReservSource procedure.','16.0')]
    procedure SetReqLine(NewReqLine: Record "Requisition Line")
    begin
        SourceRecRef.GetTable(NewReqLine);
        SetReservSource(SourceRecRef, 0);
    end;

    [Obsolete('Replaced by SetReservSource procedure.','16.0')]
    procedure SetPurchLine(NewPurchLine: Record "Purchase Line")
    begin
        SourceRecRef.GetTable(NewPurchLine);
        SetReservSource(SourceRecRef, 0);
    end;

    [Obsolete('Replaced by SetReservSource procedure.','16.0')]
    procedure SetItemJnlLine(NewItemJnlLine: Record "Item Journal Line")
    begin
        SourceRecRef.GetTable(NewItemJnlLine);
        SetReservSource(SourceRecRef, 0);
    end;

    [Obsolete('Replaced by SetReservSource procedure.','16.0')]
    procedure SetProdOrderLine(NewProdOrderLine: Record "Prod. Order Line")
    begin
        SourceRecRef.GetTable(NewProdOrderLine);
        SetReservSource(SourceRecRef, 0);
    end;

    [Obsolete('Replaced by SetReservSource procedure.','16.0')]
    procedure SetProdOrderComponent(NewProdOrderComp: Record "Prod. Order Component")
    begin
        SourceRecRef.GetTable(NewProdOrderComp);
        SetReservSource(SourceRecRef, 0);
    end;

    [Obsolete('Replaced by SetReservSource procedure.','16.0')]
    procedure SetAssemblyHeader(NewAssemblyHeader: Record "Assembly Header")
    begin
        SourceRecRef.GetTable(NewAssemblyHeader);
        SetReservSource(SourceRecRef, 0);
    end;

    [Obsolete('Replaced by SetReservSource procedure.','16.0')]
    procedure SetAssemblyLine(NewAssemblyLine: Record "Assembly Line")
    begin
        SourceRecRef.GetTable(NewAssemblyLine);
        SetReservSource(SourceRecRef, 0);
    end;

    [Obsolete('Replaced by SetReservSource procedure.','16.0')]
    procedure SetPlanningComponent(NewPlanningComponent: Record "Planning Component")
    begin
        SourceRecRef.GetTable(NewPlanningComponent);
        SetReservSource(SourceRecRef, 0);
    end;

    [Obsolete('Replaced by SetReservSource procedure.','16.0')]
    procedure SetItemLedgEntry(NewItemLedgEntry: Record "Item Ledger Entry")
    begin
        SourceRecRef.GetTable(NewItemLedgEntry);
        SetReservSource(SourceRecRef, 0);
    end;

    [Obsolete('Replaced by SetReservSource procedure.','16.0')]
    procedure SetTransferLine(NewTransLine: Record "Transfer Line"; Direction: Option Outbound,Inbound)
    begin
        SourceRecRef.GetTable(NewTransLine);
        SetReservSource(SourceRecRef, Direction);
    end;

    [Obsolete('Replaced by SetReservSource procedure.','16.0')]
    procedure SetServLine(NewServiceLine: Record "Service Line")
    begin
        SourceRecRef.GetTable(NewServiceLine);
        SetReservSource(SourceRecRef, 0);
    end;

    [Obsolete('Replaced by SetReservSource procedure.','16.0')]
    procedure SetJobJnlLine(NewJobJnlLine: Record "Job Journal Line")
    begin
        SourceRecRef.GetTable(NewJobJnlLine);
        SetReservSource(SourceRecRef, 0);
    end;

    [Obsolete('Replaced by SetReservSource procedure.','16.0')]
    procedure SetJobPlanningLine(NewJobPlanningLine: Record "Job Planning Line")
    begin
        SourceRecRef.GetTable(NewJobPlanningLine);
        SetReservSource(SourceRecRef, 0);
    end;

    procedure SetExternalDocumentResEntry(ReservEntry: Record "Reservation Entry"; UpdReservation: Boolean)
    begin
        ClearAll;
        TempTrackingSpecification.DeleteAll();
        CalcReservEntry := ReservEntry;
        UpdateReservation(UpdReservation);
    end;

    [Obsolete('Replaced by SalesLine.GetReservationQty','16.0')]
    procedure SalesLineUpdateValues(var CurrentSalesLine: Record "Sales Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal)
    begin
        CurrentSalesLine.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
    end;

    [Obsolete('Replaced by ReqLine.GetReservationQty','16.0')]
    procedure ReqLineUpdateValues(var CurrentReqLine: Record "Requisition Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal)
    begin
        CurrentReqLine.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
    end;

    [Obsolete('Replaced by PurchLine.GetReservationQty','16.0')]
    procedure PurchLineUpdateValues(var CurrentPurchLine: Record "Purchase Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal)
    begin
        CurrentPurchLine.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
    end;

    [Obsolete('Replaced by ProdOrderLine.GetReservationQty','16.0')]
    procedure ProdOrderLineUpdateValues(var CurrentProdOrderLine: Record "Prod. Order Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal)
    begin
        CurrentProdOrderLine.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
    end;

    [Obsolete('Replaced by ProdOrderComp.GetReservationQty','16.0')]
    procedure ProdOrderCompUpdateValues(var CurrentProdOrderComp: Record "Prod. Order Component"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal)
    begin
        CurrentProdOrderComp.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
    end;

    [Obsolete('Replaced by AssemblyHeader.GetReservationQty','16.0')]
    procedure AssemblyHeaderUpdateValues(var CurrentAssemblyHeader: Record "Assembly Header"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal)
    begin
        CurrentAssemblyHeader.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
    end;

    [Obsolete('Replaced by AssemblyLine.GetReservationQty','16.0')]
    procedure AssemblyLineUpdateValues(var CurrentAssemblyLine: Record "Assembly Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal)
    begin
        CurrentAssemblyLine.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
    end;

    [Obsolete('Replaced by PlanningComponent.GetReservationQty','16.0')]
    procedure PlanningComponentUpdateValues(var CurrentPlanningComponent: Record "Planning Component"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal)
    begin
        CurrentPlanningComponent.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
    end;

    [Obsolete('Replaced by ItemLedgEntry.GetReservationQty','16.0')]
    procedure ItemLedgEntryUpdateValues(var CurrentItemLedgEntry: Record "Item Ledger Entry"; var QtyToReserve: Decimal; var QtyReserved: Decimal)
    begin
        CurrentItemLedgEntry.GetReservationQty(QtyReserved, QtyToReserve);
    end;

    [Obsolete('Replaced by ServiceLine.GetReservationQty','16.0')]
    procedure ServiceInvLineUpdateValues(var CurrentServiceLine: Record "Service Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal)
    begin
        CurrentServiceLine.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
    end;

    [Obsolete('Replaced by TransferLine.GetReservationQty','16.0')]
    procedure TransferLineUpdateValues(var CurrentTransLine: Record "Transfer Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal; Direction: Enum "Transfer Direction")
    begin
        CurrentTransLine.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase, Direction);
    end;

    [Obsolete('Replaced by JobPlanningLine.GetReservationQty','16.0')]
    procedure JobPlanningLineUpdateValues(var CurrentJobPlanningLine: Record "Job Planning Line"; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal; var QtyReserved: Decimal; var QtyReservedBase: Decimal)
    begin
        CurrentJobPlanningLine.GetReservationQty(QtyReserved, QtyReservedBase, QtyToReserve, QtyToReserveBase);
    end;

    local procedure UpdateReservation(EntryIsPositive: Boolean)
    begin
        CalcReservEntry2 := CalcReservEntry;
        GetItemSetup(CalcReservEntry);
        Positive := EntryIsPositive;
        CalcReservEntry2.SetPointerFilter;
        CallCalcReservedQtyOnPick;
    end;

    procedure UpdateStatistics(var TempEntrySummary: Record "Entry Summary" temporary; AvailabilityDate: Date; HandleItemTracking2: Boolean)
    var
        i: Integer;
        CurrentEntryNo: Integer;
        ValueArrayNo: Integer;
        TotalQuantity: Decimal;
    begin
        CurrentEntryNo := TempEntrySummary."Entry No.";
        CalcReservEntry.TestField("Source Type");
        TempEntrySummary.DeleteAll();
        HandleItemTracking := HandleItemTracking2;
        if HandleItemTracking2 then
            ValueArrayNo := 3;
        for i := 1 to SetValueArray(ValueArrayNo) do begin
            TotalQuantity := 0;
            TempEntrySummary.Init();
            TempEntrySummary."Entry No." := ValueArray[i];

            case ValueArray[i] of
                1: // Item Ledger Entry
                    UpdateItemLedgEntryStats(CalcReservEntry, TempEntrySummary, TotalQuantity, HandleItemTracking2);
                6500: // Item Tracking
                    UpdateItemTrackingLineStats(CalcReservEntry, TempEntrySummary, AvailabilityDate);
            end;

            OnUpdateStatistics(CalcReservEntry, TempEntrySummary, AvailabilityDate, Positive, TotalQuantity);
        end;

        OnAfterUpdateStatistics(TempEntrySummary, AvailabilityDate, TotalQuantity);

        if not TempEntrySummary.Get(CurrentEntryNo) then
            if TempEntrySummary.IsEmpty then
                Clear(TempEntrySummary);
    end;

    local procedure UpdateItemLedgEntryStats(CalcReservEntry: Record "Reservation Entry"; var TempEntrySummary: Record "Entry Summary" temporary; var CalcSumValue: Decimal; HandleItemTracking2: Boolean)
    var
        LateBindingMgt: Codeunit "Late Binding Management";
        ReservForm: Page Reservation;
        CurrReservedQtyBase: Decimal;
    begin
        OnBeforeUpdateItemLedgEntryStats(CalcReservEntry);
        if CalcItemLedgEntry.ReadPermission then begin
            CalcItemLedgEntry.FilterLinesForReservation(CalcReservEntry, Positive);
            if CalcReservEntry.FieldFilterNeeded(FieldFilter, Positive, ItemTrackingType::"Lot No.") then
                CalcItemLedgEntry.SetFilter("Lot No.", FieldFilter);
            if CalcReservEntry.FieldFilterNeeded(FieldFilter, Positive, ItemTrackingType::"Serial No.") then
                CalcItemLedgEntry.SetFilter("Serial No.", FieldFilter);
            OnAfterInitFilter(CalcReservEntry, 1);
            if CalcItemLedgEntry.FindSet then
                repeat
                    CalcItemLedgEntry.CalcFields("Reserved Quantity");
                    OnUpdateItemLedgEntryStatsUpdateTotals(CalcReservEntry, CalcItemLedgEntry, TotalAvailQty, QtyOnOutBound);
                    TempEntrySummary."Total Reserved Quantity" += CalcItemLedgEntry."Reserved Quantity";
                    CalcSumValue += CalcItemLedgEntry."Remaining Quantity";
                until CalcItemLedgEntry.Next = 0;
            if HandleItemTracking2 then
                if TempEntrySummary."Total Reserved Quantity" > 0 then
                    TempEntrySummary."Non-specific Reserved Qty." := LateBindingMgt.NonspecificReservedQty(CalcItemLedgEntry);

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

                    TempEntrySummary."Table ID" := DATABASE::"Item Ledger Entry";
                    TempEntrySummary."Summary Type" :=
                      CopyStr(CalcItemLedgEntry.TableCaption, 1, MaxStrLen(TempEntrySummary."Summary Type"));
                    TempEntrySummary."Total Quantity" := CalcSumValue;
                    TempEntrySummary."Total Available Quantity" :=
                      TempEntrySummary."Total Quantity" - TempEntrySummary."Total Reserved Quantity";

                    Clear(ReservForm);
                    ReservForm.SetReservEntry(CalcReservEntry);
                    CurrReservedQtyBase := ReservForm.ReservedThisLine(TempEntrySummary);
                    if (CurrReservedQtyBase <> 0) and (QtyOnOutBound <> 0) then
                        if QtyOnOutBound > CurrReservedQtyBase then
                            QtyOnOutBound := QtyOnOutBound - CurrReservedQtyBase
                        else
                            QtyOnOutBound := 0;

                    if Location."Bin Mandatory" or Location."Require Pick" then begin
                        if TotalAvailQty + QtyOnOutBound < TempEntrySummary."Total Available Quantity" then
                            TempEntrySummary."Total Available Quantity" := TotalAvailQty + QtyOnOutBound;
                        TempEntrySummary."Qty. Alloc. in Warehouse" := QtyAllocInWhse;
                        TempEntrySummary."Res. Qty. on Picks & Shipmts." := QtyReservedOnPickShip
                    end else begin
                        TempEntrySummary."Qty. Alloc. in Warehouse" := 0;
                        TempEntrySummary."Res. Qty. on Picks & Shipmts." := 0
                    end;

                    if not TempEntrySummary.Insert() then
                        TempEntrySummary.Modify();
                end;
        end;
    end;

    local procedure UpdateItemTrackingLineStats(CalcReservEntry: Record "Reservation Entry"; var TempEntrySummary: Record "Entry Summary"; AvailabilityDate: Date)
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.Reset();
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
                TempEntrySummary.Init();
                TempEntrySummary."Entry No." := ReservEntry.SummEntryNo;
                TempEntrySummary."Table ID" := ReservEntry."Source Type";
                TempEntrySummary."Summary Type" :=
                  CopyStr(ReservEntry.TextCaption, 1, MaxStrLen(TempEntrySummary."Summary Type"));
                TempEntrySummary."Source Subtype" := ReservEntry."Source Subtype";
                TempEntrySummary.CopyTrackingFromReservEntry(ReservEntry);
                if ReservEntry.FindSet then
                    repeat
                        TempEntrySummary."Total Quantity" += ReservEntry."Quantity (Base)";
                        if ReservEntry."Reservation Status" = ReservEntry."Reservation Status"::Reservation then
                            TempEntrySummary."Total Reserved Quantity" += ReservEntry."Quantity (Base)";
                        if CalcReservEntry.HasSamePointer(ReservEntry) then
                            TempEntrySummary."Current Reserved Quantity" += ReservEntry."Quantity (Base)";
                    until ReservEntry.Next = 0;
                TempEntrySummary."Total Available Quantity" :=
                  TempEntrySummary."Total Quantity" - TempEntrySummary."Total Reserved Quantity";
                OnUpdateItemTrackingLineStatsOnBeforeReservEntrySummaryInsert(TempEntrySummary, ReservEntry);
                TempEntrySummary.Insert();
                ReservEntry.SetRange("Source Type");
                ReservEntry.SetRange("Source Subtype");
            until ReservEntry.Next = 0;
    end;

    procedure AutoReserve(var FullAutoReservation: Boolean; Description: Text[100]; AvailabilityDate: Date; MaxQtyToReserve: Decimal; MaxQtyToReserveBase: Decimal)
    var
        SalesLine: Record "Sales Line";
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

        if CalcReservEntry."Source Type" = DATABASE::"Sales Line" then begin
            SourceRecRef.SetTable(SalesLine);
            if (CalcReservEntry."Source Subtype" = 1) and (SalesLine.Quantity < 0) then
                StopReservation := true;
            if (CalcReservEntry."Source Subtype" = 5) and (SalesLine.Quantity >= 0) then
                StopReservation := true;
        end;

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

        CalcReservEntry.Lock();

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

        OnAutoReserveOneLineOnAfterUpdateSearchNextStep(Item, Positive, Search, NextStep, InvSearch, InvNextStep);

        case ReservSummEntryNo of
            1: // Item Ledger Entry
                AutoReserveItemLedgEntry(
                  ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate);
            12,
            16: // Purchase Line, Purchase Return Line
                AutoReservePurchLine(
                  ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate, Search, NextStep);
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

        CalcItemLedgEntry.FilterLinesForReservation(CalcReservEntry, Positive);
        if CalcReservEntry.FieldFilterNeeded(FieldFilter, Positive, ItemTrackingType::"Lot No.") then
            CalcItemLedgEntry.SetFilter("Lot No.", FieldFilter);
        if CalcReservEntry.FieldFilterNeeded(FieldFilter, Positive, ItemTrackingType::"Serial No.") then
            CalcItemLedgEntry.SetFilter("Serial No.", FieldFilter);

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
                      CalcItemLedgEntry."Variant Code", CalcItemLedgEntry."Location Code", CalcItemLedgEntry."Qty. per Unit of Measure");
                    CallTrackingSpecification.CopyTrackingFromItemLedgEntry(CalcItemLedgEntry);

                    if CallCreateReservation(
                        RemainingQtyToReserve, RemainingQtyToReserveBase, 0,
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
        PurchLine: Record "Purchase Line";
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

        PurchLine.FilterLinesForReservation(
          CalcReservEntry, ReservSummEntryNo - 11, GetAvailabilityFilter(AvailabilityDate), Positive);
        if PurchLine.Find(Search) then
            repeat
                PurchLine.CalcFields("Reserved Qty. (Base)");
                if not PurchLine."Special Order" then begin
                    QtyThisLine := PurchLine."Outstanding Quantity";
                    QtyThisLineBase := PurchLine."Outstanding Qty. (Base)";
                end;
                if ReservSummEntryNo = 16 then // Return Order
                    ReservQty := -PurchLine."Reserved Qty. (Base)"
                else
                    ReservQty := PurchLine."Reserved Qty. (Base)";
                if (Positive = (QtyThisLineBase < 0)) and (ReservSummEntryNo <> 16) or
                   (Positive = (QtyThisLineBase > 0)) and (ReservSummEntryNo = 16)
                then begin
                    QtyThisLine := 0;
                    QtyThisLineBase := 0;
                end;

                NarrowQtyToReserveDownToTrackedQuantity(
                  CalcReservEntry, PurchLine.RowID1, QtyThisLine, QtyThisLineBase);

                CallTrackingSpecification.InitTrackingSpecification(
                    DATABASE::"Purchase Line", PurchLine."Document Type", PurchLine."Document No.", '', 0, PurchLine."Line No.",
                    PurchLine."Variant Code", PurchLine."Location Code", PurchLine."Qty. per Unit of Measure");
                CallTrackingSpecification.CopyTrackingFromReservEntry(CalcReservEntry);

                CallCreateReservation(
                    RemainingQtyToReserve, RemainingQtyToReserveBase, ReservQty,
                    Description, PurchLine."Expected Receipt Date", QtyThisLine, QtyThisLineBase, CallTrackingSpecification);
            until (PurchLine.Next(NextStep) = 0) or (RemainingQtyToReserveBase = 0);
    end;

    local procedure AutoReserveSalesLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer)
    var
        SalesLine: Record "Sales Line";
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

        SalesLine.FilterLinesForReservation(
          CalcReservEntry, ReservSummEntryNo - 31, GetAvailabilityFilter(AvailabilityDate), Positive);
        if SalesLine.Find(Search) then
            repeat
                SalesLine.CalcFields("Reserved Qty. (Base)");
                QtyThisLine := SalesLine."Outstanding Quantity";
                QtyThisLineBase := SalesLine."Outstanding Qty. (Base)";
                if ReservSummEntryNo = 36 then // Return Order
                    ReservQty := -SalesLine."Reserved Qty. (Base)"
                else
                    ReservQty := SalesLine."Reserved Qty. (Base)";
                if (Positive = (QtyThisLineBase > 0)) and (ReservSummEntryNo <> 36) or
                   (Positive = (QtyThisLineBase < 0)) and (ReservSummEntryNo = 36)
                then begin
                    QtyThisLine := 0;
                    QtyThisLineBase := 0;
                end;

                NarrowQtyToReserveDownToTrackedQuantity(
                  CalcReservEntry, SalesLine.RowID1, QtyThisLine, QtyThisLineBase);

                CallTrackingSpecification.InitTrackingSpecification(
                  DATABASE::"Sales Line", SalesLine."Document Type", SalesLine."Document No.", '', 0, SalesLine."Line No.",
                  SalesLine."Variant Code", SalesLine."Location Code", SalesLine."Qty. per Unit of Measure");
                CallTrackingSpecification.CopyTrackingFromReservEntry(CalcReservEntry);

                CallCreateReservation(
                    RemainingQtyToReserve, RemainingQtyToReserveBase, ReservQty,
                    Description, SalesLine."Shipment Date", QtyThisLine, QtyThisLineBase, CallTrackingSpecification);
            until (SalesLine.Next(NextStep) = 0) or (RemainingQtyToReserveBase = 0);
    end;

    local procedure AutoReserveProdOrderLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer)
    var
        ProdOrderLine: Record "Prod. Order Line";
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

        ProdOrderLine.FilterLinesForReservation(
          CalcReservEntry, ReservSummEntryNo - 61, GetAvailabilityFilter(AvailabilityDate), Positive);
        if ProdOrderLine.Find(Search) then
            repeat
                ProdOrderLine.CalcFields("Reserved Qty. (Base)");
                QtyThisLine := ProdOrderLine."Remaining Quantity";
                QtyThisLineBase := ProdOrderLine."Remaining Qty. (Base)";
                ReservQty := ProdOrderLine."Reserved Qty. (Base)";
                if Positive = (QtyThisLineBase < 0) then begin
                    QtyThisLine := 0;
                    QtyThisLineBase := 0;
                end;

                NarrowQtyToReserveDownToTrackedQuantity(
                  CalcReservEntry, ProdOrderLine.RowID1, QtyThisLine, QtyThisLineBase);

                CallTrackingSpecification.InitTrackingSpecification(
                  DATABASE::"Prod. Order Line", ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.", 0,
                  ProdOrderLine."Variant Code", ProdOrderLine."Location Code", ProdOrderLine."Qty. per Unit of Measure");
                CallTrackingSpecification.CopyTrackingFromReservEntry(CalcReservEntry);

                CallCreateReservation(
                    RemainingQtyToReserve, RemainingQtyToReserveBase, ReservQty,
                    Description, ProdOrderLine."Due Date", QtyThisLine, QtyThisLineBase, CallTrackingSpecification);
            until (ProdOrderLine.Next(NextStep) = 0) or (RemainingQtyToReserveBase = 0);
    end;

    local procedure AutoReserveProdOrderComp(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer)
    var
        ProdOrderComp: Record "Prod. Order Component";
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

        ProdOrderComp.FilterLinesForReservation(
          CalcReservEntry, ReservSummEntryNo - 71, GetAvailabilityFilter(AvailabilityDate), Positive);
        if ProdOrderComp.Find(Search) then
            repeat
                ProdOrderComp.CalcFields("Reserved Qty. (Base)");
                QtyThisLine := ProdOrderComp."Remaining Quantity";
                QtyThisLineBase := ProdOrderComp."Remaining Qty. (Base)";
                ReservQty := ProdOrderComp."Reserved Qty. (Base)";
                if Positive = (QtyThisLineBase > 0) then begin
                    QtyThisLine := 0;
                    QtyThisLineBase := 0;
                end;

                NarrowQtyToReserveDownToTrackedQuantity(
                  CalcReservEntry, ProdOrderComp.RowID1, QtyThisLine, QtyThisLineBase);

                CallTrackingSpecification.InitTrackingSpecification(
                  DATABASE::"Prod. Order Component", ProdOrderComp.Status, ProdOrderComp."Prod. Order No.", '',
                  ProdOrderComp."Prod. Order Line No.", ProdOrderComp."Line No.",
                  ProdOrderComp."Variant Code", ProdOrderComp."Location Code", ProdOrderComp."Qty. per Unit of Measure");
                CallTrackingSpecification.CopyTrackingFromReservEntry(CalcReservEntry);

                CallCreateReservation(
                    RemainingQtyToReserve, RemainingQtyToReserveBase, ReservQty,
                    Description, ProdOrderComp."Due Date", QtyThisLine, QtyThisLineBase, CallTrackingSpecification);
            until (ProdOrderComp.Next(NextStep) = 0) or (RemainingQtyToReserveBase = 0);
    end;

    local procedure AutoReserveAssemblyHeader(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer)
    var
        AssemblyHeader: Record "Assembly Header";
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

        AssemblyHeader.FilterLinesForReservation(
          CalcReservEntry, ReservSummEntryNo - 141, GetAvailabilityFilter(AvailabilityDate), Positive);
        if AssemblyHeader.Find(Search) then
            repeat
                AssemblyHeader.CalcFields("Reserved Qty. (Base)");
                QtyThisLine := AssemblyHeader."Remaining Quantity";
                QtyThisLineBase := AssemblyHeader."Remaining Quantity (Base)";
                ReservQty := AssemblyHeader."Reserved Qty. (Base)";
                if Positive = (QtyThisLineBase < 0) then begin
                    QtyThisLine := 0;
                    QtyThisLineBase := 0;
                end;

                NarrowQtyToReserveDownToTrackedQuantity(
                  CalcReservEntry, AssemblyHeader.RowID1, QtyThisLine, QtyThisLineBase);

                CallTrackingSpecification.InitTrackingSpecification(
                  DATABASE::"Assembly Header", AssemblyHeader."Document Type", AssemblyHeader."No.", '', 0, 0,
                  AssemblyHeader."Variant Code", AssemblyHeader."Location Code", AssemblyHeader."Qty. per Unit of Measure");
                CallTrackingSpecification.CopyTrackingFromReservEntry(CalcReservEntry);

                CallCreateReservation(
                    RemainingQtyToReserve, RemainingQtyToReserveBase, ReservQty,
                    Description, AssemblyHeader."Due Date", QtyThisLine, QtyThisLineBase, CallTrackingSpecification);
            until (AssemblyHeader.Next(NextStep) = 0) or (RemainingQtyToReserveBase = 0);
    end;

    local procedure AutoReserveAssemblyLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer)
    var
        AssemblyLine: Record "Assembly Line";
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

        AssemblyLine.FilterLinesForReservation(
          CalcReservEntry, ReservSummEntryNo - 151, GetAvailabilityFilter(AvailabilityDate), Positive);
        if AssemblyLine.Find(Search) then
            repeat
                AssemblyLine.CalcFields("Reserved Qty. (Base)");
                QtyThisLine := AssemblyLine."Remaining Quantity";
                QtyThisLineBase := AssemblyLine."Remaining Quantity (Base)";
                ReservQty := AssemblyLine."Reserved Qty. (Base)";
                if Positive = (QtyThisLineBase > 0) then begin
                    QtyThisLine := 0;
                    QtyThisLineBase := 0;
                end;

                NarrowQtyToReserveDownToTrackedQuantity(
                  CalcReservEntry, AssemblyLine.RowID1, QtyThisLine, QtyThisLineBase);

                CallTrackingSpecification.InitTrackingSpecification(
                  DATABASE::"Assembly Line", AssemblyLine."Document Type", AssemblyLine."Document No.", '', 0, AssemblyLine."Line No.",
                  AssemblyLine."Variant Code", AssemblyLine."Location Code", AssemblyLine."Qty. per Unit of Measure");
                CallTrackingSpecification.CopyTrackingFromReservEntry(CalcReservEntry);

                CallCreateReservation(
                    RemainingQtyToReserve, RemainingQtyToReserveBase, ReservQty,
                    Description, AssemblyLine."Due Date", QtyThisLine, QtyThisLineBase, CallTrackingSpecification);
            until (AssemblyLine.Next(NextStep) = 0) or (RemainingQtyToReserveBase = 0);
    end;

    local procedure AutoReserveTransLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer)
    var
        TransLine: Record "Transfer Line";
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

        case ReservSummEntryNo of
            101: // Outbound
                TransLine.FilterOutboundLinesForReservation(CalcReservEntry, GetAvailabilityFilter(AvailabilityDate), Positive);
            102:
                TransLine.FilterInboundLinesForReservation(CalcReservEntry, GetAvailabilityFilter(AvailabilityDate), Positive);
        end;
        if TransLine.Find(Search) then
            repeat
                case ReservSummEntryNo of
                    101: // Outbound
                        begin
                            TransLine.CalcFields("Reserved Qty. Outbnd. (Base)");
                            QtyThisLine := -TransLine."Outstanding Quantity";
                            QtyThisLineBase := -TransLine."Outstanding Qty. (Base)";
                            ReservQty := -TransLine."Reserved Qty. Outbnd. (Base)";
                            EntryDate := TransLine."Shipment Date";
                            LocationCode := TransLine."Transfer-from Code";
                            if Positive = (QtyThisLineBase < 0) then begin
                                QtyThisLine := 0;
                                QtyThisLineBase := 0;
                            end;
                            NarrowQtyToReserveDownToTrackedQuantity(
                              CalcReservEntry, TransLine.RowID1(0), QtyThisLine, QtyThisLineBase);
                        end;
                    102: // Inbound
                        begin
                            TransLine.CalcFields("Reserved Qty. Inbnd. (Base)");
                            QtyThisLine := TransLine."Outstanding Quantity";
                            QtyThisLineBase := TransLine."Outstanding Qty. (Base)";
                            ReservQty := TransLine."Reserved Qty. Inbnd. (Base)";
                            EntryDate := TransLine."Receipt Date";
                            LocationCode := TransLine."Transfer-to Code";
                            if Positive = (QtyThisLineBase < 0) then begin
                                QtyThisLine := 0;
                                QtyThisLineBase := 0;
                            end;
                            NarrowQtyToReserveDownToTrackedQuantity(
                              CalcReservEntry, TransLine.RowID1(1), QtyThisLine, QtyThisLineBase);
                        end;
                end;

                CallTrackingSpecification.InitTrackingSpecification(
                  DATABASE::"Transfer Line", ReservSummEntryNo - 101, TransLine."Document No.", '',
                  TransLine."Derived From Line No.", TransLine."Line No.",
                  TransLine."Variant Code", LocationCode, TransLine."Qty. per Unit of Measure");
                CallTrackingSpecification.CopyTrackingFromReservEntry(CalcReservEntry);

                CallCreateReservation(
                    RemainingQtyToReserve, RemainingQtyToReserveBase, ReservQty,
                    Description, EntryDate, QtyThisLine, QtyThisLineBase, CallTrackingSpecification);
            until (TransLine.Next(NextStep) = 0) or (RemainingQtyToReserveBase = 0);
    end;

    local procedure AutoReserveServLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer)
    var
        ServiceLine: Record "Service Line";
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

        ServiceLine.FindLinesForReservation(CalcReservEntry, GetAvailabilityFilter(AvailabilityDate), Positive);
        if ServiceLine.Find(Search) then
            repeat
                ServiceLine.CalcFields("Reserved Qty. (Base)");
                QtyThisLine := ServiceLine."Outstanding Quantity";
                QtyThisLineBase := ServiceLine."Outstanding Qty. (Base)";
                ReservQty := ServiceLine."Reserved Qty. (Base)";
                if Positive = (QtyThisLineBase > 0) then begin
                    QtyThisLine := 0;
                    QtyThisLineBase := 0;
                end;

                NarrowQtyToReserveDownToTrackedQuantity(
                  CalcReservEntry, ServiceLine.RowID1, QtyThisLine, QtyThisLineBase);

                CallTrackingSpecification.InitTrackingSpecification(
                  DATABASE::"Service Line", ServiceLine."Document Type", ServiceLine."Document No.", '', 0, ServiceLine."Line No.",
                  ServiceLine."Variant Code", ServiceLine."Location Code", ServiceLine."Qty. per Unit of Measure");
                CallTrackingSpecification.CopyTrackingFromReservEntry(CalcReservEntry);

                CallCreateReservation(
                    RemainingQtyToReserve, RemainingQtyToReserveBase, ReservQty,
                    Description, ServiceLine."Needed by Date", QtyThisLine, QtyThisLineBase, CallTrackingSpecification);
            until (ServiceLine.Next(NextStep) = 0) or (RemainingQtyToReserveBase = 0);
    end;

    local procedure AutoReserveJobPlanningLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer)
    var
        JobPlanningLine: Record "Job Planning Line";
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

        JobPlanningLine.FilterLinesForReservation(
          CalcReservEntry, ReservSummEntryNo - 131, GetAvailabilityFilter(AvailabilityDate), Positive);
        if JobPlanningLine.Find(Search) then
            repeat
                JobPlanningLine.CalcFields("Reserved Qty. (Base)");
                QtyThisLine := JobPlanningLine."Remaining Qty.";
                QtyThisLineBase := JobPlanningLine."Remaining Qty. (Base)";
                ReservQty := JobPlanningLine."Reserved Qty. (Base)";
                if Positive = (QtyThisLineBase > 0) then begin
                    QtyThisLine := 0;
                    QtyThisLineBase := 0;
                end;

                CallTrackingSpecification.InitTrackingSpecification(
                  DATABASE::"Job Planning Line", JobPlanningLine.Status, JobPlanningLine."Job No.", '',
                  0, JobPlanningLine."Job Contract Entry No.",
                  JobPlanningLine."Variant Code", JobPlanningLine."Location Code", JobPlanningLine."Qty. per Unit of Measure");
                CallTrackingSpecification.CopyTrackingFromReservEntry(CalcReservEntry);

                CallCreateReservation(
                    RemainingQtyToReserve, RemainingQtyToReserveBase, ReservQty,
                    Description, JobPlanningLine."Planning Date", QtyThisLine, QtyThisLineBase, CallTrackingSpecification);
            until (JobPlanningLine.Next(NextStep) = 0) or (RemainingQtyToReserveBase = 0);
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

        OnCreateReservation(SourceRecRef, TrackingSpecification, CalcReservEntry, Description, ExpectedDate, Quantity, QuantityBase);

    end;

    procedure DeleteReservEntries(DeleteAll: Boolean; DownToQuantity: Decimal)
    var
        CalcReservEntry4: Record "Reservation Entry";
        ReqLine: Record "Requisition Line";
        TrackingMgt: Codeunit OrderTrackingManagement;
        ReservMgt: Codeunit "Reservation Management";
        QtyToReTrack: Decimal;
        QtyTracked: Decimal;
    begin
        DeleteReservEntries(DeleteAll, DownToQuantity, CalcReservEntry2);

        // Handle both sides of a req. line related to a transfer line:
        if ((CalcReservEntry."Source Type" = DATABASE::"Requisition Line") and
            (RefOrderType = ReqLine."Ref. Order Type"::Transfer))
        then begin
            CalcReservEntry4 := CalcReservEntry;
            CalcReservEntry4."Source Subtype" := 1;
            CalcReservEntry4.SetPointerFilter;
            DeleteReservEntries(DeleteAll, DownToQuantity, CalcReservEntry4);
        end;

        if DeleteAll then
            if ((CalcReservEntry."Source Type" = DATABASE::"Requisition Line") and
                (PlanningLineOrigin <> ReqLine."Planning Line Origin"::" ")) or
               (CalcReservEntry."Source Type" = DATABASE::"Planning Component")
            then begin
                CalcReservEntry4.Reset();
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
        ReservStatus: Enum "Reservation Status";
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
        OnBeforeDeleteReservEntries(ReservEntry, DownToQuantity);

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
                    ReservEntry.SetTrackingFilterBlank;
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

        for ReservStatus := ReservStatus::Prospect downto ReservStatus::Reservation do begin
            ReservEntry.SetRange("Reservation Status", ReservStatus);
            if ReservEntry.FindSet and (QtyToRelease <> 0) then
                case ReservStatus of
                    ReservStatus::Prospect:
                    repeat
                        if (Abs(ReservEntry."Quantity (Base)") <= Abs(QtyToRelease)) or DeleteAll then begin
                            ReservEntry.Delete();
                            SaveTrackingSpecification(ReservEntry, ReservEntry."Quantity (Base)");
                            QtyToRelease := QtyToRelease - ReservEntry."Quantity (Base)";
                        end else begin
                            ReservEntry.Validate("Quantity (Base)", ReservEntry."Quantity (Base)" - QtyToRelease);
                            ReservEntry.Modify();
                            SaveTrackingSpecification(ReservEntry, QtyToRelease);
                            QtyToRelease := 0;
                        end;
                    until (ReservEntry.Next = 0) or ((not DeleteAll) and (QtyToRelease = 0));
                    ReservStatus::Surplus:
                    repeat
                        if CalcReservEntry4.Get(ReservEntry."Entry No.", not ReservEntry.Positive) then // Find related entry
                            Error(Text007);
                        if (Abs(ReservEntry."Quantity (Base)") <= Abs(QtyToRelease)) or DeleteAll then begin
                            ReservEngineMgt.CloseReservEntry(ReservEntry, false, DeleteAll);
                            SaveTrackingSpecification(ReservEntry, ReservEntry."Quantity (Base)");
                            QtyToRelease := QtyToRelease - ReservEntry."Quantity (Base)";
                            if not DeleteAll and CalcReservEntry4.TrackingExists then begin
                                CalcReservEntry4."Reservation Status" := CalcReservEntry4."Reservation Status"::Surplus;
                                CalcReservEntry4.Insert();
                            end;
                            ModifyActionMessage(ReservEntry."Entry No.", 0, true); // Delete action messages
                        end else begin
                            ReservEntry.Validate("Quantity (Base)", ReservEntry."Quantity (Base)" - QtyToRelease);
                            ReservEntry.Modify();
                            SaveTrackingSpecification(ReservEntry, QtyToRelease);
                            ModifyActionMessage(ReservEntry."Entry No.", QtyToRelease, false); // Modify action messages
                            QtyToRelease := 0;
                        end;
                    until (ReservEntry.Next = 0) or ((not DeleteAll) and (QtyToRelease = 0));
                    ReservStatus::Tracking,
                    ReservStatus::Reservation:
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
                                        ReservEntry.Modify();
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

                                        CalcReservEntry4.Modify();
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

        OnCalculateRemainingQty(SourceRecRef, CalcReservEntry, RemainingQty, RemainingQtyBase);
    end;

    [Obsolete('Replaced by ReservEntry.FieldFilterNeeded(FieldFilter, SearchForSupply, Field)','16.0')]
    procedure FieldFilterNeeded(var ReservEntry: Record "Reservation Entry"; SearchForSupply: Boolean; TrackingField: Enum "Item Tracking Type"): Boolean
    var
        ReservEntry2: Record "Reservation Entry";
        FieldValue: Code[50];
    begin
        case TrackingField of
            TrackingField::"Lot No.":
                exit(ReservEntry.FieldFilterNeeded(FieldFilter, SearchForSupply, ItemTrackingType::"Lot No."));
            TrackingField::"Serial No.":
                exit(ReservEntry.FieldFilterNeeded(FieldFilter, SearchForSupply, ItemTrackingType::"Serial No."));
        end;
    end;

    [Obsolete('Not used','16.0')]
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
        ActionMessageEntry: Record "Action Message Entry";
    begin
        CalcReservEntry.TestField("Source Type");
        ReservEntry2 := CalcReservEntry;
        ReservEntry2.SetPointerFilter;
        ReservEntry2.SetRange("Reservation Status", ReservEntry2."Reservation Status"::Surplus);
        // Item Tracking
        if ItemTrackingHandling = ItemTrackingHandling::None then
            ReservEntry2.SetTrackingFilterBlank;

        if Item."Order Tracking Policy" = Item."Order Tracking Policy"::"Tracking & Action Msg." then begin
            ReservEntry2.Lock;
            if not ReservEntry2.FindSet then
                exit;
            ActionMessageEntry.Reset();
            ActionMessageEntry.SetCurrentKey("Reservation Entry");
            repeat
                ActionMessageEntry.SetRange("Reservation Entry", ReservEntry2."Entry No.");
                ActionMessageEntry.DeleteAll();
            until ReservEntry2.Next = 0;
        end;

        ReservEntry2.SetRange(
          "Reservation Status", ReservEntry2."Reservation Status"::Surplus, ReservEntry2."Reservation Status"::Prospect);
        ReservEntry2.DeleteAll();
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
                SurplusEntry.Modify();
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
        if ReservEntry.FieldFilterNeeded(FieldFilter, SearchForSupply, ItemTrackingType::"Lot No.") then
            SurplusEntry.SetFilter("Lot No.", FieldFilter);
        if ReservEntry.FieldFilterNeeded(FieldFilter, SearchForSupply, ItemTrackingType::"Serial No.") then
            SurplusEntry.SetFilter("Serial No.", FieldFilter);
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
                        SurplusEntry.Delete();
                        if TrackingPolicy = TrackingPolicy::"Tracking & Action Msg." then
                            ModifyActionMessage(SurplusEntry."Entry No.", 0, true); // Delete related Action Message
                    end else begin
                        SurplusEntry.Validate("Quantity (Base)", SurplusEntry."Quantity (Base)" + QtyToTrack);
                        SurplusEntry.Modify();
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
        FromTrackingSpecification: Record "Tracking Specification";
        Sign: Integer;
    begin
        if Quantity < 0 then
            ToReservEntry."Shipment Date" := AvailabilityDate
        else
            ToReservEntry."Expected Receipt Date" := AvailabilityDate;

        CreateReservEntry.SetBinding(Binding);

        if FromReservEntry."Planning Flexibility" <> FromReservEntry."Planning Flexibility"::Unlimited then
            CreateReservEntry.SetPlanningFlexibility(FromReservEntry."Planning Flexibility");

        Sign := CreateReservEntry.SignFactor(FromReservEntry);
        CreateReservEntry.CreateReservEntryFor(
          FromReservEntry."Source Type", FromReservEntry."Source Subtype", FromReservEntry."Source ID",
          FromReservEntry."Source Batch Name", FromReservEntry."Source Prod. Order Line", FromReservEntry."Source Ref. No.",
          FromReservEntry."Qty. per Unit of Measure", 0, Sign * Quantity,
          FromReservEntry);

        FromTrackingSpecification.SetSourceFromReservEntry(ToReservEntry);
        FromTrackingSpecification."Qty. per Unit of Measure" := ToReservEntry."Qty. per Unit of Measure";
        FromTrackingSpecification.CopyTrackingFromReservEntry(ToReservEntry);
        CreateReservEntry.CreateReservEntryFrom(FromTrackingSpecification);
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
            TempTrackingSpecification.Modify();
        end else begin
            TempTrackingSpecification.TransferFields(ReservEntry);
            TempTrackingSpecification.Validate("Quantity (Base)", QtyReleased);
            TempTrackingSpecification.Insert();
        end;
        TempTrackingSpecification.Reset();
    end;

    procedure CollectTrackingSpecification(var TargetTrackingSpecification: Record "Tracking Specification" temporary): Boolean
    begin
        // Used when creating reservations.
        TempTrackingSpecification.Reset();
        TargetTrackingSpecification.Reset();

        if not TempTrackingSpecification.FindSet then
            exit(false);

        repeat
            TargetTrackingSpecification := TempTrackingSpecification;
            TargetTrackingSpecification.Insert();
        until TempTrackingSpecification.Next = 0;

        TempTrackingSpecification.DeleteAll();

        exit(true);
    end;

    procedure SourceQuantity(var ReservEntry: Record "Reservation Entry"; SetAsCurrent: Boolean): Decimal
    begin
        exit(GetSourceRecordValue(ReservEntry, SetAsCurrent, 0));
    end;

    procedure FilterReservFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; Direction: Enum "Transfer Direction") CaptionText: Text
    begin
        ReservEntry.InitSortingAndFilters(true);

        OnFilterReservFor(SourceRecRef, ReservEntry, Direction, CaptionText);
    end;

    procedure GetSourceRecordValue(var ReservEntry: Record "Reservation Entry"; SetAsCurrent: Boolean; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)") SourceQty: Decimal
    begin
        OnGetSourceRecordValue(ReservEntry, SetAsCurrent, ReturnOption, SourceQty, SourceRecRef);

        if SetAsCurrent then
            SetReservSource(SourceRecRef, ReservEntry."Source Subtype");
    end;

    local procedure GetItemSetup(var ReservEntry: Record "Reservation Entry")
    var
        PlanningGetParameters: Codeunit "Planning-Get Parameters";
    begin
        if ReservEntry."Item No." <> Item."No." then begin
            Item.Get(ReservEntry."Item No.");
            if Item."Item Tracking Code" <> '' then
                ItemTrackingCode.Get(Item."Item Tracking Code")
            else
                ItemTrackingCode.Init();
            PlanningGetParameters.AtSKU(
              SKU, ReservEntry."Item No.", ReservEntry."Variant Code", ReservEntry."Location Code");
            MfgSetup.Get();
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
        ActionMessageEntry: Record "Action Message Entry";
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

        ActionMessageEntry.Reset();
        NextEntryNo := ActionMessageEntry.GetLastEntryNo() + 1;

        ActionMessageEntry.Init();
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
                            if SurplusEntry.FieldFilterNeeded(FieldFilter, Positive, ItemTrackingType::"Lot No.") then
                                ReservEntry.SetFilter("Lot No.", FieldFilter);
                            if SurplusEntry.FieldFilterNeeded(FieldFilter, Positive, ItemTrackingType::"Serial No.") then
                                ReservEntry.SetFilter("Serial No.", FieldFilter);
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
                        ActionMessageEntry2.DeleteAll();
                        ActionMessageEntry2.Reset();
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
    var
        ActionMessageEntry: Record "Action Message Entry";
    begin
        ActionMessageEntry.Reset();
        ActionMessageEntry.SetCurrentKey("Reservation Entry");
        ActionMessageEntry.SetRange("Reservation Entry", RelatedToEntryNo);

        if Delete then begin
            ActionMessageEntry.DeleteAll();
            exit;
        end;
        ActionMessageEntry.SetRange("New Date", 0D);

        if ActionMessageEntry.FindFirst then begin
            ActionMessageEntry.Quantity -= Quantity;
            if ActionMessageEntry.Quantity = 0 then
                ActionMessageEntry.Delete
            else
                ActionMessageEntry.Modify();
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
        ReqLine: Record "Requisition Line";
    begin
        if CalcReservEntry2."Source Type" = DATABASE::"Planning Component" then
            exit;

        if Item."Order Tracking Policy" <> Item."Order Tracking Policy"::"Tracking & Action Msg." then
            exit;

        if CalcReservEntry2."Source Type" = DATABASE::"Requisition Line" then
            if PlanningLineOrigin <> ReqLine."Planning Line Origin"::" " then
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
        ActionMessageEntry: Record "Action Message Entry";
        ActionMessageEntry2: Record "Action Message Entry";
    begin
        ActionMessageEntry.Reset();
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
                    ActionMessageEntry2.Modify();
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

    procedure SetTrackingFromReservEntry(ReservEntry: Record "Reservation Entry")
    begin
        CalcReservEntry.CopyTrackingFromReservEntry(ReservEntry);
    end;

    procedure SetTrackingFromWhseActivityLine(WhseActivityLine: Record "Warehouse Activity Line")
    begin
        CalcReservEntry.CopyTrackingFromWhseActivLine(WhseActivityLine);
    end;

    procedure SetMatchFilter(var ReservEntry: Record "Reservation Entry"; var FilterReservEntry: Record "Reservation Entry"; SearchForSupply: Boolean; AvailabilityDate: Date)
    begin
        FilterReservEntry.Reset();
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
        if ReservEntry.FieldFilterNeeded(FieldFilter, SearchForSupply, ItemTrackingType::"Lot No.") then
            FilterReservEntry.SetFilter("Lot No.", FieldFilter);
        if ReservEntry.FieldFilterNeeded(FieldFilter, SearchForSupply, ItemTrackingType::"Serial No.") then
            FilterReservEntry.SetFilter("Serial No.", FieldFilter);
        FilterReservEntry.SetRange(Positive, SearchForSupply);
    end;

    procedure LookupLine(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer)
    begin
        OnLookupLine(SourceType, SourceSubtype, SourceID, SourceBatchName, SourceProdOrderLine, SourceRefNo);
    end;

    procedure LookupDocument(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookupDocument(SourceType, SourceSubtype, SourceID, SourceBatchName, SourceProdOrderLine, SourceRefNo, IsHandled);
        if IsHandled then
            exit;

        OnLookupDocument(SourceType, SourceSubtype, SourceID, SourceBatchName, SourceProdOrderLine, SourceRefNo);
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
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        TempWhseActivLine2: Record "Warehouse Activity Line" temporary;
        WhseAvailMgt: Codeunit "Warehouse Availability Mgt.";
        PickQty: Decimal;
        QtyOnOutboundBins: Decimal;
        QtyOnInvtMovement: Decimal;
        QtyOnAssemblyBin: Decimal;
        QtyOnOpenShopFloorBin: Decimal;
        QtyOnToProductionBin: Decimal;
        IsHandled: Boolean;
    begin
        with CalcReservEntry do begin
            GetItemSetup(CalcReservEntry);
            Item.SetRange("Location Filter", "Location Code");
            IsHandled := false;
            OnCalcReservedQtyOnPickOnbeforeSetItemVariantCodeFilter(Item, CalcReservEntry, IsHandled);
            if not IsHandled then
                Item.SetRange("Variant Filter", "Variant Code");
            SetTrackingFilterToItemIfRequired(Item);
            Item.CalcFields(Inventory, "Reserved Qty. on Inventory");

            WhseActivLine.SetCurrentKey(
              "Item No.", "Bin Code", "Location Code", "Action Type", "Variant Code",
              "Unit of Measure Code", "Breakbulk No.", "Activity Type", "Lot No.", "Serial No.");

            WhseActivLine.SetRange("Item No.", "Item No.");
            if Location."Bin Mandatory" then
                WhseActivLine.SetFilter("Bin Code", '<>%1', '');
            WhseActivLine.SetRange("Location Code", "Location Code");
            WhseActivLine.SetFilter(
              "Action Type", '%1|%2', WhseActivLine."Action Type"::" ", WhseActivLine."Action Type"::Take);
            IsHandled := false;
            OnCalcReservedQtyOnPickOnBeforeSetWhseActivLineVariantCodeFilter(WhseActivLine, CalcReservEntry, IsHandled);
            if not IsHandled then
                WhseActivLine.SetRange("Variant Code", "Variant Code");
            WhseActivLine.SetRange("Breakbulk No.", 0);
            WhseActivLine.SetFilter(
              "Activity Type", '%1|%2', WhseActivLine."Activity Type"::Pick, WhseActivLine."Activity Type"::"Invt. Pick");
            WhseActivLine.SetTrackingFilterFromReservEntryIfRequired(CalcReservEntry);
            WhseActivLine.CalcSums("Qty. Outstanding (Base)");

            if Location."Require Pick" then begin
                WhseItemTrackingSetup.CopyTrackingFromReservEntry(CalcReservEntry);

                QtyOnOutboundBins :=
                    WhseAvailMgt.CalcQtyOnOutboundBins("Location Code", "Item No.", "Variant Code", WhseItemTrackingSetup, true);

                QtyReservedOnPickShip :=
                  WhseAvailMgt.CalcReservQtyOnPicksShips(
                    "Location Code", "Item No.", "Variant Code", TempWhseActivLine2);

                QtyOnInvtMovement := CalcQtyOnInvtMovement(WhseActivLine);

                QtyOnAssemblyBin :=
                    WhseAvailMgt.CalcQtyOnBin("Location Code", Location."To-Assembly Bin Code", "Item No.", "Variant Code", WhseItemTrackingSetup);

                QtyOnOpenShopFloorBin :=
                    WhseAvailMgt.CalcQtyOnBin("Location Code", Location."Open Shop Floor Bin Code", "Item No.", "Variant Code", WhseItemTrackingSetup);

                QtyOnToProductionBin :=
                    WhseAvailMgt.CalcQtyOnBin("Location Code", Location."To-Production Bin Code", "Item No.", "Variant Code", WhseItemTrackingSetup);
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
    begin
        if not ItemTrackingMgt.GetWhseItemTrkgSetup(ItemNo) or (BinCode = '') then
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
                    WhseEntry.SetTrackingFilterFromReservEntryIfNotBlank(ReservationEntry);
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

    [Scope('OnPrem')]
    procedure ReservEntryPositiveTypeIsItemLedgerEntry(ReservationEntryNo: Integer): Boolean
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
                    ReservEntry2.Modify();
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
        MaxReservQtyPerLotOrSerial :=
            UOMMgt.CalcQtyFromBase(
                FilterReservEntry."Item No.", FilterReservEntry."Variant Code", '',
                MaxReservQtyBasePerLotOrSerial, TempTrackingSpec."Qty. per Unit of Measure");
        QtyThisLine := MinAbs(QtyThisLine, MaxReservQtyPerLotOrSerial) * Sign(QtyThisLine);
        QtyThisLineBase := MinAbs(QtyThisLineBase, MaxReservQtyPerLotOrSerial) * Sign(QtyThisLineBase);
    end;

    local procedure IsSpecialOrderOrDropShipment(ReservationEntry: Record "Reservation Entry"): Boolean
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
    begin
        if ReservationEntry."Source Type" = DATABASE::"Sales Line" then
            if SalesLine.Get(ReservationEntry."Source Subtype", ReservationEntry."Source ID", ReservationEntry."Source Ref. No.") then
                if SalesLine."Special Order" or SalesLine."Drop Shipment" then
                    exit(true);
        if ReservationEntry."Source Type" = DATABASE::"Purchase Line" then
            if PurchaseLine.Get(ReservationEntry."Source Subtype", ReservationEntry."Source ID", ReservationEntry."Source Ref. No.") then
                if PurchaseLine."Special Order" or PurchaseLine."Drop Shipment" then
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

    procedure TestItemType(SourceRecRef: RecordRef)
    var
        AssemblyLine: Record "Assembly Line";
        JobPlanningLine: Record "Job Planning Line";
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        ServiceLine: Record "Service Line";
    begin
        case SourceRecRef.Number of
            DATABASE::"Assembly Line":
                begin
                    SourceRecRef.SetTable(AssemblyLine);
                    AssemblyLine.TestField(Type, AssemblyLine.Type::Item);
                end;
            DATABASE::"Sales Line":
                begin
                    SourceRecRef.SetTable(SalesLine);
                    SalesLine.TestField(Type, SalesLine.Type::Item);
                end;
            DATABASE::"Purchase Line":
                begin
                    SourceRecRef.SetTable(PurchaseLine);
                    PurchaseLine.TestField(Type, PurchaseLine.Type::Item);
                end;
            DATABASE::"Service Line":
                begin
                    SourceRecRef.SetTable(ServiceLine);
                    ServiceLine.TestField(Type, ServiceLine.Type::Item);
                end;
            DATABASE::"Job Planning Line":
                begin
                    SourceRecRef.SetTable(JobPlanningLine);
                    JobPlanningLine.TestField(Type, JobPlanningLine.Type::Item);
                end;
        end;
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
    local procedure OnAutoReserveOneLineOnAfterUpdateSearchNextStep(var Item: Record Item; var Positive: Boolean; var Search: Text[1]; var NextStep: Integer; var InvSearch: Text[1]; InvNextStep: Integer)
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
    local procedure OnBeforeDeleteReservEntries(var ReservationEntry: Record "Reservation Entry"; var DownToQuantity: Decimal)
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
    local procedure OnCalculateRemainingQty(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var RemainingQty: Decimal; var RemainingQtyBase: Decimal);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcReservedQtyOnPickOnBeforeSetItemVariantCodeFilter(var Item: Record Item; var ReservationEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcReservedQtyOnPickOnBeforeSetWhseActivLineVariantCodeFilter(var WnseActivLine: Record "Warehouse Activity Line"; var ReservationEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateReservation(SourceRecRef: RecordRef; TrackingSpecification: Record "Tracking Specification"; ForReservEntry: Record "Reservation Entry"; Description: Text[100]; ExpectedDate: Date; Quantity: Decimal; QuantityBase: Decimal);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSourceRecordValue(var ReservEntry: Record "Reservation Entry"; SetAsCurrent: Boolean; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"; var ReturnQty: Decimal; var SourceRecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFilterReservFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; Direction: Integer; var CaptionText: Text);
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

    [IntegrationEvent(false, false)]
    local procedure OnUpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var ReservSummEntry: Record "Entry Summary"; AvailabilityDate: Date; Positive: Boolean; var TotalQuantity: Decimal)
    begin
    end;
}

