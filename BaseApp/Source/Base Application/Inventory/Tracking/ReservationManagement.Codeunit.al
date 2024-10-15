namespace Microsoft.Inventory.Tracking;

using Microsoft.Assembly.Document;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Document;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Setup;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Document;
using Microsoft.Service.Document;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Availability;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;
using System.Utilities;

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
        LateBindingMgt: Codeunit "Late Binding Management";
        SourceRecRef: RecordRef;
        RefOrderType: Option;
        PlanningLineOrigin: Enum "Planning Line Origin Type";
        Positive: Boolean;
        CurrentBindingIsSet: Boolean;
        HandleItemTracking: Boolean;
        InvSearch: Text[1];
        InvNextStep: Integer;
        ValueArray: array[30] of Integer;
        CurrentBinding: Enum "Reservation Binding";
        ItemTrackingHandling: Option "None","Allow deletion",Match;
        Text008: Label 'Item tracking defined for item %1 in the %2 accounts for more than the quantity you have entered.\You must adjust the existing item tracking and then reenter the new quantity.';
        ItemTrackingCannotBeFullyMatchedErr: Label 'Item Tracking cannot be fully matched.\Serial No.: %1, Lot No.: %2, outstanding quantity: %3.';
        Text010: Label 'Item tracking is defined for item %1 in the %2.\You must delete the existing item tracking before modifying or deleting the %2.';
        TotalAvailQty: Decimal;
        QtyAllocInWhse: Decimal;
        QtyOnOutBound: Decimal;
        Text011: Label 'Item tracking is defined for item %1 in the %2.\Do you want to delete the %2 and the item tracking lines?';
        QtyReservedOnPickShip: Decimal;
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

    procedure SetOrderTrackingSurplusEntries(var TempReservEntry: Record "Reservation Entry" temporary)
    begin
        // Late Binding
        LateBindingMgt.SetOrderTrackingSurplusEntries(TempReservEntry);
    end;

    procedure SetReservSource(NewRecordVar: Variant)
    begin
        SourceRecRef.GetTable(NewRecordVar);
        SetReservSource(SourceRecRef, Enum::"Transfer Direction"::Outbound);
    end;

    procedure SetReservSource(NewRecordVar: Variant; Direction: Enum "Transfer Direction")
    begin
        SourceRecRef.GetTable(NewRecordVar);
        SetReservSource(SourceRecRef, Direction);
    end;

    procedure SetReservSource(NewSourceRecRef: RecordRef)
    begin
        SetReservSource(NewSourceRecRef, Enum::"Transfer Direction"::Outbound);
    end;

    procedure SetReservSource(NewSourceRecRef: RecordRef; Direction: Enum "Transfer Direction")
    begin
        ClearAll();
        TempTrackingSpecification.DeleteAll();

        SourceRecRef := NewSourceRecRef;

        OnSetReservSource(SourceRecRef, CalcReservEntry, Direction);
        case SourceRecRef.Number of
            Database::"Sales Line":
                SetSourceForSalesLine();
            Database::"Requisition Line":
                SetSourceForReqLine();
            Database::"Purchase Line":
                SetSourceForPurchLine();
            Database::"Item Journal Line":
                SetSourceForItemJnlLine();
            Database::"Item Ledger Entry":
                SetSourceForItemLedgerEntry();
            Database::"Prod. Order Line":
                SetSourceForProdOrderLine();
            Database::"Prod. Order Component":
                SetSourceForProdOrderComp();
            Database::"Planning Component":
                SetSourceForPlanningComp();
            Database::"Transfer Line":
                SetSourceForTransferLine(Direction);
            Database::"Service Line":
                SetSourceForServiceLine();
            Database::"Job Journal Line":
                SetSourceForJobJournalLine();
            Database::"Job Planning Line":
                SetSourceForJobPlanningLine();
            Database::"Assembly Header":
                SetSourceForAssemblyHeader();
            Database::"Assembly Line":
                SetSourceForAssemblyLine();
            Database::"Invt. Document Line":
                SetSourceForInvtDocLine();
        end;

        OnAfterSetReservSource(SourceRecRef, CalcReservEntry, Direction);
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
        UpdateReservation((CreateReservEntry.SignFactor(CalcReservEntry) * AssemblyLine."Remaining Quantity (Base)") <= 0);
    end;

    local procedure SetSourceForInvtDocLine()
    var
        InvtDocLine: Record "Invt. Document Line";
    begin
        SourceRecRef.SetTable(InvtDocLine);
        InvtDocLine.SetReservationEntry(CalcReservEntry);
        UpdateReservation((CreateReservEntry.SignFactor(CalcReservEntry) * InvtDocLine."Quantity (Base)") < 0);
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
        OnAfterSetSourceForSalesLine(CalcReservEntry, SalesLine);
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

    procedure SetExternalDocumentResEntry(ReservEntry: Record "Reservation Entry"; UpdReservation: Boolean)
    begin
        ClearAll();
        TempTrackingSpecification.DeleteAll();
        CalcReservEntry := ReservEntry;
        UpdateReservation(UpdReservation);
    end;

    procedure UpdateReservation(EntryIsPositive: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateReservation(SourceRecRef, CalcReservEntry, IsHandled);
        if IsHandled then
            exit;

        CalcReservEntry2 := CalcReservEntry;
        GetItemSetup(CalcReservEntry);
        Positive := EntryIsPositive;
        CalcReservEntry2.SetPointerFilter();
        CallCalcReservedQtyOnPick();
    end;

    procedure UpdateStatistics(var TempEntrySummary: Record "Entry Summary" temporary; AvailabilityDate: Date; HandleItemTracking2: Boolean)
    var
        i: Integer;
        CurrentEntryNo: Integer;
        ValueArrayNo: Integer;
        TotalQuantity: Decimal;
    begin
        OnBeforeUpdateStatistics(AvailabilityDate);
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
                Enum::"Reservation Summary Type"::"Item Ledger Entry".AsInteger():
                    UpdateItemLedgEntryStats(CalcReservEntry, TempEntrySummary, TotalQuantity, HandleItemTracking2);
                Enum::"Reservation Summary Type"::"Item Tracking Line".AsInteger():
                    UpdateItemTrackingLineStats(CalcReservEntry, TempEntrySummary, AvailabilityDate);
            end;

            OnUpdateStatistics(CalcReservEntry, TempEntrySummary, AvailabilityDate, Positive, TotalQuantity, HandleItemTracking2, QtyOnOutBound);
        end;

        OnAfterUpdateStatistics(TempEntrySummary, AvailabilityDate, TotalQuantity);

        if not TempEntrySummary.Get(CurrentEntryNo) then
            if TempEntrySummary.IsEmpty() then
                Clear(TempEntrySummary);
    end;

    local procedure UpdateItemLedgEntryStats(CalcReservEntry: Record "Reservation Entry"; var TempEntrySummary: Record "Entry Summary" temporary; var CalcSumValue: Decimal; HandleItemTracking2: Boolean)
    var
        ReservForm: Page Reservation;
        CurrReservedQtyBase: Decimal;
        IsHandled: Boolean;
    begin
        OnBeforeUpdateItemLedgEntryStats(CalcReservEntry);
        if CalcItemLedgEntry.ReadPermission then begin
            CalcItemLedgEntry.FilterLinesForReservation(CalcReservEntry, Positive);
            CalcItemLedgEntry.FilterLinesForTracking(CalcReservEntry, Positive);
            OnAfterInitFilter(CalcReservEntry, 1);
            if CalcItemLedgEntry.FindSet() then
                repeat
                    CalcItemLedgEntry.CalcFields("Reserved Quantity");
                    IsHandled := false;
                    OnUpdateItemLedgEntryStatsUpdateTotals(CalcReservEntry, CalcItemLedgEntry, TotalAvailQty, QtyOnOutBound, CalcSumValue, TempEntrySummary, IsHandled);
                    if not IsHandled then begin
                        TempEntrySummary."Total Reserved Quantity" += CalcItemLedgEntry."Reserved Quantity";
                        CalcSumValue += CalcItemLedgEntry."Remaining Quantity";
                    end;
                until CalcItemLedgEntry.Next() = 0;
            if HandleItemTracking2 then
                if TempEntrySummary."Total Reserved Quantity" > 0 then
                    TempEntrySummary."Non-specific Reserved Qty." := LateBindingMgt.NonspecificReservedQty(CalcItemLedgEntry);

            OnUpdateItemLedgEntryStatsOnBeforePrepareTempEntrySummary(CalcReservEntry, TempEntrySummary);
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

                    TempEntrySummary."Table ID" := Database::"Item Ledger Entry";
                    TempEntrySummary."Summary Type" :=
                      CopyStr(CalcItemLedgEntry.TableCaption(), 1, MaxStrLen(TempEntrySummary."Summary Type"));
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

                    if Location."Bin Mandatory" and Location."Require Pick" then begin
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
        ReservEntry.SetFilter("Source Type", '<> %1', Database::"Item Ledger Entry");
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
        OnUpdateItemTrackingLineStatsOnAfterReservEntrySetFilters(ReservEntry, CalcReservEntry);
        if ReservEntry.FindSet() then
            repeat
                ReservEntry.SetRange("Source Type", ReservEntry."Source Type");
                ReservEntry.SetRange("Source Subtype", ReservEntry."Source Subtype");
                TempEntrySummary.Init();
                TempEntrySummary."Entry No." := ReservEntry.SummEntryNo();
                TempEntrySummary."Table ID" := ReservEntry."Source Type";
                TempEntrySummary."Summary Type" :=
                  CopyStr(ReservEntry.TextCaption(), 1, MaxStrLen(TempEntrySummary."Summary Type"));
                TempEntrySummary."Source Subtype" := ReservEntry."Source Subtype";
                TempEntrySummary.CopyTrackingFromReservEntry(ReservEntry);
                if ReservEntry.FindSet() then
                    repeat
                        TempEntrySummary."Total Quantity" += ReservEntry."Quantity (Base)";
                        if ReservEntry."Reservation Status" = ReservEntry."Reservation Status"::Reservation then
                            TempEntrySummary."Total Reserved Quantity" += ReservEntry."Quantity (Base)";
                        if CalcReservEntry.HasSamePointer(ReservEntry) then
                            TempEntrySummary."Current Reserved Quantity" += ReservEntry."Quantity (Base)";
                    until ReservEntry.Next() = 0;
                TempEntrySummary."Total Available Quantity" :=
                  TempEntrySummary."Total Quantity" - TempEntrySummary."Total Reserved Quantity";
                OnUpdateItemTrackingLineStatsOnBeforeReservEntrySummaryInsert(TempEntrySummary, ReservEntry);
                TempEntrySummary.Insert();
                ReservEntry.SetRange("Source Type");
                ReservEntry.SetRange("Source Subtype");
            until ReservEntry.Next() = 0;
    end;

    procedure AutoReserve(var FullAutoReservation: Boolean; Description: Text[100]; AvailabilityDate: Date; MaxQtyToReserve: Decimal; MaxQtyToReserveBase: Decimal)
    var
        SalesLine: Record "Sales Line";
        RemainingQtyToReserve: Decimal;
        RemainingQtyToReserveBase: Decimal;
        i: Integer;
        ValueArrayNo: Integer;
        StopReservation: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAutoReserve(CalcReservEntry, FullAutoReservation, Description, AvailabilityDate, MaxQtyToReserve, MaxQtyToReserveBase, IsHandled);
        if IsHandled then
            exit;

        CalcReservEntry.TestField("Source Type");

        if CalcReservEntry."Source Type" in [Database::"Sales Line", Database::"Purchase Line", Database::"Service Line"] then
            StopReservation := not (CalcReservEntry."Source Subtype" in [1, 5]); // Only order and return order

        if CalcReservEntry."Source Type" in [Database::"Assembly Line", Database::"Assembly Header"] then
            StopReservation := not (CalcReservEntry."Source Subtype" = 1); // Only Assembly Order

        if CalcReservEntry."Source Type" in [Database::"Prod. Order Line", Database::"Prod. Order Component"]
        then
            StopReservation := CalcReservEntry."Source Subtype" < 2; // Not simulated or planned

        if CalcReservEntry."Source Type" = Database::"Sales Line" then begin
            SourceRecRef.SetTable(SalesLine);
            if (CalcReservEntry."Source Subtype" = 1) and (SalesLine.Quantity < 0) then
                StopReservation := true;
            if (CalcReservEntry."Source Subtype" = 5) and (SalesLine.Quantity >= 0) then
                StopReservation := true;
        end;

        if CalcReservEntry."Source Type" = Database::"Job Planning Line" then
            StopReservation := CalcReservEntry."Source Subtype" <> 2;

        OnAutoReserveOnBeforeStopReservation(CalcReservEntry, FullAutoReservation, AvailabilityDate, MaxQtyToReserve, MaxQtyToReserveBase, StopReservation);
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

        OnAutoReserveOnBeforeSetValueArray(ValueArrayNo, AvailabilityDate);
        for i := 1 to SetValueArray(ValueArrayNo) do
            AutoReserveOneLine(ValueArray[i], RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate);

        FullAutoReservation := (RemainingQtyToReserveBase = 0);

        OnAfterAutoReserve(CalcReservEntry, FullAutoReservation);
    end;

    procedure AutoReserveOneLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date)
    var
        Item: Record Item;
        ReservSummaryType: Enum "Reservation Summary Type";
        Search: Text[1];
        NextStep: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAutoReserveOneLine(IsHandled, AvailabilityDate, CalcReservEntry);
        if IsHandled then
            exit;

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

        ReservSummaryType := Enum::"Reservation Summary Type".FromInteger(ReservSummEntryNo);

        OnAutoReserveOneLineOnAfterUpdateSearchNextStep(Item, Positive, Search, NextStep, InvSearch, InvNextStep, RemainingQtyToReserve);

        case ReservSummaryType of
            Enum::"Reservation Summary Type"::"Item Ledger Entry":
                AutoReserveItemLedgEntry(
                    ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate);
            Enum::"Reservation Summary Type"::"Purchase Order",
            Enum::"Reservation Summary Type"::"Purchase Return Order":
                AutoReservePurchLine(
                    ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate, Search, NextStep);
            Enum::"Reservation Summary Type"::"Sales Quote",
            Enum::"Reservation Summary Type"::"Sales Order",
            Enum::"Reservation Summary Type"::"Sales Return Order":
                AutoReserveSalesLine(
                    ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate, Search, NextStep);
            Enum::"Reservation Summary Type"::"Simulated Production Order",
            Enum::"Reservation Summary Type"::"Planned Production Order",
            Enum::"Reservation Summary Type"::"Firm Planned Production Order",
            Enum::"Reservation Summary Type"::"Released Production Order":
                AutoReserveProdOrderLine(
                    ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate, Search, NextStep);
            Enum::"Reservation Summary Type"::"Simulated Prod. Order Comp.",
            Enum::"Reservation Summary Type"::"Planned Prod. Order Comp.",
            Enum::"Reservation Summary Type"::"Firm Planned Prod. Order Comp.",
            Enum::"Reservation Summary Type"::"Released Prod. Order Comp.":
                AutoReserveProdOrderComp(
                    ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate, Search, NextStep);
            Enum::"Reservation Summary Type"::"Transfer Shipment",
            Enum::"Reservation Summary Type"::"Transfer Receipt":
                AutoReserveTransLine(
                    ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate, Search, NextStep);
            Enum::"Reservation Summary Type"::"Service Order":
                AutoReserveServLine(
                    ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate, Search, NextStep);
            Enum::"Reservation Summary Type"::"Job Planning Order":
                AutoReserveJobPlanningLine(
                    ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate, Search, NextStep);
            Enum::"Reservation Summary Type"::"Assembly Order Header":
                AutoReserveAssemblyHeader(
                    ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate, Search, NextStep);
            Enum::"Reservation Summary Type"::"Assembly Order Line":
                AutoReserveAssemblyLine(
                  ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate, Search, NextStep);
            Enum::"Reservation Summary Type"::"Inventory Receipt",
            Enum::"Reservation Summary Type"::"Inventory Shipment":
                AutoInvtDocLineReserve(
                  ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate, Search, NextStep);
            else
                OnAfterAutoReserveOneLine(
                  ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate, Search, NextStep, CalcReservEntry, CalcReservEntry2, Positive);
        end;
        OnAfterFinishedAutoReserveOneLine(ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate);
    end;

    local procedure AutoReserveItemLedgEntry(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date)
    var
        Location: Record Location;
        AllocationsChanged: Boolean;
        QtyThisLine: Decimal;
        QtyThisLineBase: Decimal;
        IsReserved: Boolean;
        IsHandled: Boolean;
        IsFound: Boolean;
    begin
        IsReserved := false;
        OnBeforeAutoReserveItemLedgEntry(ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate, IsReserved, CalcReservEntry, CalcItemLedgEntry, ItemTrackingCode, Positive);
        if IsReserved then
            exit;

        if not Location.Get(CalcReservEntry."Location Code") then
            Clear(Location);

        CalcItemLedgEntry.FilterLinesForReservation(CalcReservEntry, Positive);
        CalcItemLedgEntry.FilterLinesForTracking(CalcReservEntry, Positive);

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
                    if (FindUnfinishedSpecialOrderSalesNo(CalcItemLedgEntry) <> '') or (Positive = (QtyThisLineBase < 0)) then begin
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
                            QtyThisLine := Round(QtyThisLineBase, UOMMgt.QtyRndPrecision());
                        end;

                    OnAfterCalcReservation(CalcReservEntry, CalcItemLedgEntry, ReservSummEntryNo, QtyThisLine, QtyThisLineBase, TotalAvailQty);

                    CallTrackingSpecification.InitTrackingSpecification(
                      Database::"Item Ledger Entry", 0, '', '', 0, CalcItemLedgEntry."Entry No.",
                      CalcItemLedgEntry."Variant Code", CalcItemLedgEntry."Location Code", CalcItemLedgEntry."Qty. per Unit of Measure");
                    CallTrackingSpecification.CopyTrackingFromItemLedgEntry(CalcItemLedgEntry);

                    if InsertReservationEntries(
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

        OnAfterAutoReserveItemLedgEntry(CalcItemLedgEntry, RemainingQtyToReserveBase);
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
          ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate, IsReserved, Search, NextStep, CalcReservEntry);
        if IsReserved then
            exit;

        PurchLine.FilterLinesForReservation(
          CalcReservEntry, Enum::"Purchase Document Type".FromInteger(ReservSummEntryNo - Enum::"Reservation Summary Type"::"Purchase Quote".AsInteger()),
          GetAvailabilityFilter(AvailabilityDate), Positive);
        if PurchLine.Find(Search) then
            repeat
                PurchLine.CalcFields("Reserved Qty. (Base)");
                if not PurchLine."Special Order" then begin
                    QtyThisLine := PurchLine."Outstanding Quantity";
                    QtyThisLineBase := PurchLine."Outstanding Qty. (Base)";
                end;
                if ReservSummEntryNo = Enum::"Reservation Summary Type"::"Purchase Return Order".AsInteger() then
                    ReservQty := -PurchLine."Reserved Qty. (Base)"
                else
                    ReservQty := PurchLine."Reserved Qty. (Base)";
                if (Positive = (QtyThisLineBase < 0)) and (ReservSummEntryNo <> Enum::"Reservation Summary Type"::"Purchase Return Order".AsInteger()) or
                   (Positive = (QtyThisLineBase > 0)) and (ReservSummEntryNo = Enum::"Reservation Summary Type"::"Purchase Return Order".AsInteger())
                then begin
                    QtyThisLine := 0;
                    QtyThisLineBase := 0;
                end;

                OnAutoReservePurchLineOnBeforeSetQtyToReserveDownToTrackedQuantity(
                    PurchLine, CalcReservEntry, ReservQty, QtyThisLine, QtyThisLineBase);
                SetQtyToReserveDownToTrackedQuantity(CalcReservEntry, PurchLine.RowID1(), QtyThisLine, QtyThisLineBase);

                CallTrackingSpecification.InitTrackingSpecification(
                    Database::"Purchase Line", PurchLine."Document Type".AsInteger(), PurchLine."Document No.", '', 0, PurchLine."Line No.",
                    PurchLine."Variant Code", PurchLine."Location Code", PurchLine."Qty. per Unit of Measure");
                CallTrackingSpecification.CopyTrackingFromReservEntry(CalcReservEntry);

                InsertReservationEntries(
                    RemainingQtyToReserve, RemainingQtyToReserveBase, ReservQty,
                    Description, PurchLine."Expected Receipt Date", QtyThisLine, QtyThisLineBase, CallTrackingSpecification);
            until (PurchLine.Next(NextStep) = 0) or (RemainingQtyToReserveBase = 0);

        OnAfterAutoReservePurchLine(PurchLine, ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate);
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
          ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate, IsReserved, Search, NextStep, CalcReservEntry);
        if IsReserved then
            exit;

        SalesLine.FilterLinesForReservation(
          CalcReservEntry, Enum::"Sales Document Type".FromInteger(ReservSummEntryNo - Enum::"Reservation Summary Type"::"Sales Quote".AsInteger()), GetAvailabilityFilter(AvailabilityDate), Positive);
        if SalesLine.Find(Search) then
            repeat
                SalesLine.CalcFields("Reserved Qty. (Base)");
                QtyThisLine := SalesLine."Outstanding Quantity";
                QtyThisLineBase := SalesLine."Outstanding Qty. (Base)";
                if ReservSummEntryNo = Enum::"Reservation Summary Type"::"Sales Return Order".AsInteger() then // Return Order
                    ReservQty := -SalesLine."Reserved Qty. (Base)"
                else
                    ReservQty := SalesLine."Reserved Qty. (Base)";
                if (Positive = (QtyThisLineBase > 0)) and (ReservSummEntryNo <> Enum::"Reservation Summary Type"::"Sales Return Order".AsInteger()) or
                   (Positive = (QtyThisLineBase < 0)) and (ReservSummEntryNo = Enum::"Reservation Summary Type"::"Sales Return Order".AsInteger())
                then begin
                    QtyThisLine := 0;
                    QtyThisLineBase := 0;
                end;

                SetQtyToReserveDownToTrackedQuantity(CalcReservEntry, SalesLine.RowID1(), QtyThisLine, QtyThisLineBase);

                CallTrackingSpecification.InitTrackingSpecification(
                  Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", '', 0, SalesLine."Line No.",
                  SalesLine."Variant Code", SalesLine."Location Code", SalesLine."Qty. per Unit of Measure");
                CallTrackingSpecification.CopyTrackingFromReservEntry(CalcReservEntry);

                InsertReservationEntries(
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
          ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserve, Description, AvailabilityDate, IsReserved, Search, NextStep, CalcReservEntry);
        if IsReserved then
            exit;

        ProdOrderLine.FilterLinesForReservation(
            CalcReservEntry, ReservSummEntryNo - Enum::"Reservation Summary Type"::"Simulated Production Order".AsInteger(),
            GetAvailabilityFilter(AvailabilityDate), Positive);
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

                SetQtyToReserveDownToTrackedQuantity(CalcReservEntry, ProdOrderLine.RowID1(), QtyThisLine, QtyThisLineBase);

                CallTrackingSpecification.InitTrackingSpecification(
                    Database::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.", 0,
                    ProdOrderLine."Variant Code", ProdOrderLine."Location Code", ProdOrderLine."Qty. per Unit of Measure");
                CallTrackingSpecification.CopyTrackingFromReservEntry(CalcReservEntry);

                InsertReservationEntries(
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
          ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserve, Description, AvailabilityDate, IsReserved, Search, NextStep, CalcReservEntry);
        if IsReserved then
            exit;

        ProdOrderComp.FilterLinesForReservation(
            CalcReservEntry, ReservSummEntryNo - Enum::"Reservation Summary Type"::"Simulated Prod. Order Comp.".AsInteger(),
            GetAvailabilityFilter(AvailabilityDate), Positive);
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

                SetQtyToReserveDownToTrackedQuantity(CalcReservEntry, ProdOrderComp.RowID1(), QtyThisLine, QtyThisLineBase);

                CallTrackingSpecification.InitTrackingSpecification(
                    Database::"Prod. Order Component", ProdOrderComp.Status.AsInteger(), ProdOrderComp."Prod. Order No.", '',
                    ProdOrderComp."Prod. Order Line No.", ProdOrderComp."Line No.",
                    ProdOrderComp."Variant Code", ProdOrderComp."Location Code", ProdOrderComp."Qty. per Unit of Measure");
                CallTrackingSpecification.CopyTrackingFromReservEntry(CalcReservEntry);

                InsertReservationEntries(
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
          ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserve, Description, AvailabilityDate, IsReserved, Search, NextStep, CalcReservEntry);
        if IsReserved then
            exit;

        AssemblyHeader.FilterLinesForReservation(
            CalcReservEntry, ReservSummEntryNo - Enum::"Reservation Summary Type"::"Assembly Quote Header".AsInteger(),
            GetAvailabilityFilter(AvailabilityDate), Positive);
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

                SetQtyToReserveDownToTrackedQuantity(CalcReservEntry, AssemblyHeader.RowID1(), QtyThisLine, QtyThisLineBase);

                CallTrackingSpecification.InitTrackingSpecification(
                  Database::"Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", '', 0, 0,
                  AssemblyHeader."Variant Code", AssemblyHeader."Location Code", AssemblyHeader."Qty. per Unit of Measure");
                CallTrackingSpecification.CopyTrackingFromReservEntry(CalcReservEntry);

                InsertReservationEntries(
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
          ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserve, Description, AvailabilityDate, IsReserved, Search, NextStep, CalcReservEntry);
        if IsReserved then
            exit;

        AssemblyLine.FilterLinesForReservation(
            CalcReservEntry, ReservSummEntryNo - Enum::"Reservation Summary Type"::"Assembly Quote Line".AsInteger(),
            GetAvailabilityFilter(AvailabilityDate), Positive);
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

                SetQtyToReserveDownToTrackedQuantity(CalcReservEntry, AssemblyLine.RowID1(), QtyThisLine, QtyThisLineBase);

                CallTrackingSpecification.InitTrackingSpecification(
                  Database::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.", '', 0, AssemblyLine."Line No.",
                  AssemblyLine."Variant Code", AssemblyLine."Location Code", AssemblyLine."Qty. per Unit of Measure");
                CallTrackingSpecification.CopyTrackingFromReservEntry(CalcReservEntry);

                InsertReservationEntries(
                    RemainingQtyToReserve, RemainingQtyToReserveBase, ReservQty,
                    Description, AssemblyLine."Due Date", QtyThisLine, QtyThisLineBase, CallTrackingSpecification);
            until (AssemblyLine.Next(NextStep) = 0) or (RemainingQtyToReserveBase = 0);
    end;

    local procedure AutoReserveTransLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer)
    var
        TransLine: Record "Transfer Line";
        TransferDirection: Enum "Transfer Direction";
        QtyThisLine: Decimal;
        QtyThisLineBase: Decimal;
        ReservQty: Decimal;
        LocationCode: Code[10];
        EntryDate: Date;
        IsReserved: Boolean;
    begin
        IsReserved := false;
        OnBeforeAutoReserveTransLine(
          ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserve, Description, AvailabilityDate, IsReserved, Search, NextStep, CalcReservEntry);
        if IsReserved then
            exit;

        case ReservSummEntryNo of
            Enum::"Reservation Summary Type"::"Transfer Shipment".AsInteger():
                TransLine.FilterOutboundLinesForReservation(CalcReservEntry, GetAvailabilityFilter(AvailabilityDate), Positive);
            Enum::"Reservation Summary Type"::"Transfer Receipt".AsInteger():
                TransLine.FilterInboundLinesForReservation(CalcReservEntry, GetAvailabilityFilter(AvailabilityDate), Positive);
        end;
        if TransLine.Find(Search) then
            repeat
                case ReservSummEntryNo of
                    Enum::"Reservation Summary Type"::"Transfer Shipment".AsInteger():
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
                            SetQtyToReserveDownToTrackedQuantity(
                                CalcReservEntry, TransLine.RowID1(TransferDirection::Outbound), QtyThisLine, QtyThisLineBase);
                        end;
                    Enum::"Reservation Summary Type"::"Transfer Receipt".AsInteger():
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
                            SetQtyToReserveDownToTrackedQuantity(
                                CalcReservEntry, TransLine.RowID1(TransferDirection::Inbound), QtyThisLine, QtyThisLineBase);
                        end;
                end;

                CallTrackingSpecification.InitTrackingSpecification(
                  Database::"Transfer Line", ReservSummEntryNo - Enum::"Reservation Summary Type"::"Transfer Shipment".AsInteger(),
                  TransLine."Document No.", '', TransLine."Derived From Line No.", TransLine."Line No.",
                  TransLine."Variant Code", LocationCode, TransLine."Qty. per Unit of Measure");
                CallTrackingSpecification.CopyTrackingFromReservEntry(CalcReservEntry);

                InsertReservationEntries(
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
          ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserve, Description, AvailabilityDate, IsReserved, Search, NextStep, CalcReservEntry);
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

                SetQtyToReserveDownToTrackedQuantity(CalcReservEntry, ServiceLine.RowID1(), QtyThisLine, QtyThisLineBase);

                CallTrackingSpecification.InitTrackingSpecification(
                  Database::"Service Line", ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.", '', 0, ServiceLine."Line No.",
                  ServiceLine."Variant Code", ServiceLine."Location Code", ServiceLine."Qty. per Unit of Measure");
                CallTrackingSpecification.CopyTrackingFromReservEntry(CalcReservEntry);

                InsertReservationEntries(
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
          ReservSummEntryNo, RemainingQtyToReserve, RemainingQtyToReserve, Description, AvailabilityDate, IsReserved, Search, NextStep, CalcReservEntry);
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
                  Database::"Job Planning Line", JobPlanningLine.Status.AsInteger(), JobPlanningLine."Job No.", '',
                  0, JobPlanningLine."Job Contract Entry No.",
                  JobPlanningLine."Variant Code", JobPlanningLine."Location Code", JobPlanningLine."Qty. per Unit of Measure");
                CallTrackingSpecification.CopyTrackingFromReservEntry(CalcReservEntry);

                InsertReservationEntries(
                    RemainingQtyToReserve, RemainingQtyToReserveBase, ReservQty,
                    Description, JobPlanningLine."Planning Date", QtyThisLine, QtyThisLineBase, CallTrackingSpecification);
            until (JobPlanningLine.Next(NextStep) = 0) or (RemainingQtyToReserveBase = 0);
    end;

    local procedure AutoInvtDocLineReserve(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer)
    var
        InvtDocLine: Record "Invt. Document Line";
        QtyThisLine: Decimal;
        QtyThisLineBase: Decimal;
        ReservQty: Decimal;
    begin
        case ReservSummEntryNo of
            Enum::"Reservation Summary Type"::"Inventory Receipt".AsInteger():
                InvtDocLine.FilterReceiptLinesForReservation(CalcReservEntry, GetAvailabilityFilter(AvailabilityDate), Positive);
            Enum::"Reservation Summary Type"::"Inventory Shipment".AsInteger():
                InvtDocLine.FilterShipmentLinesForReservation(CalcReservEntry, GetAvailabilityFilter(AvailabilityDate), Positive);
        end;

        if InvtDocLine.Find(Search) then
            repeat
                case ReservSummEntryNo of
                    Enum::"Reservation Summary Type"::"Inventory Shipment".AsInteger():
                        begin
                            InvtDocLine.CalcFields("Reserved Qty. Outbnd. (Base)");
                            QtyThisLine := -InvtDocLine.Quantity;
                            QtyThisLineBase := -InvtDocLine."Quantity (Base)";
                            ReservQty := -InvtDocLine."Reserved Qty. Outbnd. (Base)";
                            if Positive = (QtyThisLine < 0) then begin
                                QtyThisLine := 0;
                                QtyThisLineBase := 0;
                            end;
                        end;
                    Enum::"Reservation Summary Type"::"Inventory Receipt".AsInteger():
                        begin
                            InvtDocLine.CalcFields("Reserved Qty. Inbnd. (Base)");
                            QtyThisLine := InvtDocLine.Quantity;
                            QtyThisLineBase := InvtDocLine."Quantity (Base)";
                            ReservQty := InvtDocLine."Reserved Qty. Inbnd. (Base)";
                            if Positive = (QtyThisLine < 0) then begin
                                QtyThisLine := 0;
                                QtyThisLineBase := 0;
                            end;
                        end;
                end;
                if QtyThisLine <> 0 then
                    if Abs(QtyThisLine - ReservQty) > 0 then begin
                        if Abs(QtyThisLine - ReservQty) > Abs(RemainingQtyToReserve) then begin
                            QtyThisLine := RemainingQtyToReserve;
                            QtyThisLineBase := RemainingQtyToReserveBase;
                        end else begin
                            QtyThisLineBase := QtyThisLineBase - ReservQty;
                            QtyThisLine := Round(RemainingQtyToReserve / RemainingQtyToReserveBase * QtyThisLineBase, UOMMgt.QtyRndPrecision());
                        end;

                        CopySign(RemainingQtyToReserve, QtyThisLine);
                        CopySign(RemainingQtyToReserveBase, QtyThisLineBase);

                        CallTrackingSpecification.InitTrackingSpecification(
                          Database::"Invt. Document Line", ReservSummEntryNo - Enum::"Reservation Summary Type"::"Inventory Receipt".AsInteger(),
                          InvtDocLine."Document No.", '', 0, InvtDocLine."Line No.", InvtDocLine."Variant Code", InvtDocLine."Location Code", InvtDocLine."Qty. per Unit of Measure");
                        CallTrackingSpecification.CopyTrackingFromReservEntry(CalcReservEntry);

                        CreateReservation(Description, InvtDocLine."Posting Date", QtyThisLine, QtyThisLineBase, CallTrackingSpecification);

                        RemainingQtyToReserve := RemainingQtyToReserve - QtyThisLine;
                        RemainingQtyToReserveBase := RemainingQtyToReserveBase - QtyThisLineBase;
                    end;
            until (InvtDocLine.Next(NextStep) = 0) or (RemainingQtyToReserve = 0);
    end;

    procedure InsertReservationEntries(var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; ReservQty: Decimal; Description: Text[100]; ExpectedDate: Date; QtyThisLine: Decimal; QtyThisLineBase: Decimal; TrackingSpecification: Record "Tracking Specification") ReservationCreated: Boolean
    begin
        if QtyThisLineBase = 0 then
            exit;
        if Abs(QtyThisLineBase - ReservQty) > 0 then begin
            if Abs(QtyThisLineBase - ReservQty) > Abs(RemainingQtyToReserveBase) then begin
                QtyThisLine := RemainingQtyToReserve;
                QtyThisLineBase := RemainingQtyToReserveBase;
            end else begin
                QtyThisLineBase := QtyThisLineBase - ReservQty;
                QtyThisLine := Round(RemainingQtyToReserve / RemainingQtyToReserveBase * QtyThisLineBase, UOMMgt.QtyRndPrecision());
            end;
            CopySign(RemainingQtyToReserveBase, QtyThisLineBase);
            CopySign(RemainingQtyToReserve, QtyThisLine);
            OnInsertReservationEntriesOnBeforeCreateReservation(TrackingSpecification, CalcReservEntry);
            CreateReservation(Description, ExpectedDate, QtyThisLine, QtyThisLineBase, TrackingSpecification);
            RemainingQtyToReserve := RemainingQtyToReserve - QtyThisLine;
            RemainingQtyToReserveBase := RemainingQtyToReserveBase - QtyThisLineBase;
            ReservationCreated := true;
        end;

        OnAfterInsertReservationEntries(TrackingSpecification, CalcReservEntry, RemainingQtyToReserve, RemainingQtyToReserveBase, QtyThisLine, QtyThisLineBase, ReservationCreated);
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
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnDeleteReservEntriesOnBeforeDeleteReservEntries(CalcReservEntry, CalcReservEntry2, IsHandled);
        if IsHandled then
            exit;

        DeleteReservEntries(DeleteAll, DownToQuantity, CalcReservEntry2);

        // Handle both sides of a req. line related to a transfer line:
        if ((CalcReservEntry."Source Type" = Database::"Requisition Line") and
            (RefOrderType = ReqLine."Ref. Order Type"::Transfer))
        then begin
            CalcReservEntry4 := CalcReservEntry;
            CalcReservEntry4."Source Subtype" := 1;
            CalcReservEntry4.SetPointerFilter();
            DeleteReservEntries(DeleteAll, DownToQuantity, CalcReservEntry4);
        end;

        if DeleteAll then
            if ((CalcReservEntry."Source Type" = Database::"Requisition Line") and
                (PlanningLineOrigin <> ReqLine."Planning Line Origin"::" ")) or
               (CalcReservEntry."Source Type" = Database::"Planning Component")
            then begin
                CalcReservEntry4.Reset();
                if TrackingMgt.DerivePlanningFilter(CalcReservEntry2, CalcReservEntry4) then
                    if CalcReservEntry4.FindFirst() then begin
                        QtyToReTrack := ReservMgt.SourceQuantity(CalcReservEntry4, true);
                        CalcReservEntry4.SetRange("Reservation Status", CalcReservEntry4."Reservation Status"::Reservation);
                        if not CalcReservEntry4.IsEmpty() then begin
                            CalcReservEntry4.CalcSums("Quantity (Base)");
                            QtyTracked += CalcReservEntry4."Quantity (Base)";
                        end;
                        CalcReservEntry4.SetFilter("Reservation Status", '<>%1', CalcReservEntry4."Reservation Status"::Reservation);
                        CalcReservEntry4.SetFilter("Item Tracking", '<>%1', CalcReservEntry4."Item Tracking"::None);
                        if not CalcReservEntry4.IsEmpty() then begin
                            CalcReservEntry4.CalcSums("Quantity (Base)");
                            QtyTracked += CalcReservEntry4."Quantity (Base)";
                        end;
                        if CalcReservEntry."Source Type" = Database::"Planning Component" then
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
        CurrentItemTrackingSetup: Record "Item Tracking Setup";
        ReservStatus: Enum "Reservation Status";
        QtyToRelease: Decimal;
        QtyTracked: Decimal;
        QtyToReleaseForLotSN: Decimal;
        CurrentQty: Decimal;
        AvailabilityDate: Date;
        Release: Option "Non-Inventory",Inventory;
        HandleItemTracking2: Boolean;
        SignFactor: Integer;
        QuantityIsValidated: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteReservEntries(ReservEntry, DownToQuantity, CalcReservEntry, CalcReservEntry2, IsHandled, ItemTrackingHandling);
        if IsHandled then
            exit;

        ReservEntry.SetRange("Reservation Status");
        if ReservEntry.IsEmpty() then
            exit;

        CurrentItemTrackingSetup.CopyTrackingFromReservEntry(ReservEntry);
        CurrentQty := ReservEntry."Quantity (Base)";

        GetItemSetup(ReservEntry);
        IsHandled := false;
        OnDeleteReservEntriesOnBeforeReservEntryTestField(ReservEntry, IsHandled);
        if not IsHandled then
            ReservEntry.TestField("Source Type");
        ReservEntry.Lock();
        SignFactor := CreateReservEntry.SignFactor(ReservEntry);
        QtyTracked := QuantityTracked(ReservEntry);
        CurrentBinding := ReservEntry.Binding;
        CurrentBindingIsSet := true;

        // Item Tracking:
        if ItemTrackingCode.IsSpecific() or CurrentItemTrackingSetup.TrackingExists() then begin
            ReservEntry.SetFilter("Item Tracking", '<>%1', ReservEntry."Item Tracking"::None);
            HandleItemTracking2 := not ReservEntry.IsEmpty();
            ReservEntry.SetRange("Item Tracking");
            OnDeleteReservEntriesOnAfterReservEntrySetFilters(ReservEntry, ItemTrackingHandling);
            case ItemTrackingHandling of
                ItemTrackingHandling::None:
                    ReservEntry.SetTrackingFilterBlank();
                ItemTrackingHandling::Match:
                    begin
                        if CurrentItemTrackingSetup.TrackingExists() then begin
                            QtyToReleaseForLotSN := QuantityTracked2(ReservEntry);
                            if Abs(QtyToReleaseForLotSN) > Abs(CurrentQty) then
                                QtyToReleaseForLotSN := CurrentQty;
                            DownToQuantity := (QtyTracked - QtyToReleaseForLotSN) * SignFactor;
                            ReservEntry.SetTrackingFilterFromItemTrackingSetup(CurrentItemTrackingSetup);
                        end else
                            DownToQuantity += CalcDownToQtySyncingToAssembly(ReservEntry);
                    end;
            end;
            OnDeleteReservEntriesOnAfterItemTrackingHandling(ReservEntry, ItemTrackingHandling);
        end;

        if SignFactor * QtyTracked * DownToQuantity < 0 then
            DeleteAll := true
        else
            if Abs(QtyTracked) < Abs(DownToQuantity) then
                exit;

        QtyToRelease := QtyTracked - (DownToQuantity * SignFactor);

        for ReservStatus := ReservStatus::Prospect downto ReservStatus::Reservation do begin
            ReservEntry.SetRange("Reservation Status", ReservStatus);
            if ReservEntry.FindSet() and (QtyToRelease <> 0) then
                case ReservStatus of
                    Enum::"Reservation Status"::Prospect:
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
                        until (ReservEntry.Next() = 0) or ((not DeleteAll) and (QtyToRelease = 0));
                    Enum::"Reservation Status"::Surplus:
                        repeat
                            if CalcReservEntry4.Get(ReservEntry."Entry No.", not ReservEntry.Positive) then // Find related entry
                                Error(Text007);
                            if (Abs(ReservEntry."Quantity (Base)") <= Abs(QtyToRelease)) or DeleteAll then begin
                                ReservEngineMgt.CloseReservEntry(ReservEntry, false, DeleteAll);
                                SaveTrackingSpecification(ReservEntry, ReservEntry."Quantity (Base)");
                                QtyToRelease := QtyToRelease - ReservEntry."Quantity (Base)";
                                if not DeleteAll and CalcReservEntry4.TrackingExists() then begin
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
                        until (ReservEntry.Next() = 0) or ((not DeleteAll) and (QtyToRelease = 0));
                    Enum::"Reservation Status"::Tracking,
                    Enum::"Reservation Status"::Reservation:
                        for Release := Release::"Non-Inventory" to Release::Inventory do begin
                            // Release non-inventory reservations in first cycle
                            repeat
                                CalcReservEntry4.Get(ReservEntry."Entry No.", not ReservEntry.Positive); // Find related entry
                                OnDeleteReservEntriesOnReservationOnAfterCalcReservEntry4Get(CalcReservEntry4, ReservEntry);
                                if (Release = Release::Inventory) = (CalcReservEntry4."Source Type" = Database::"Item Ledger Entry") then
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
                                                MakeConnection(
                                                    CalcReservEntry4, CalcReservEntry4, -QtyToRelease, CalcReservEntry4."Reservation Status"::Surplus,
                                                    AvailabilityDate, CalcReservEntry4.Binding);
                                                if Item."Order Tracking Policy" = Item."Order Tracking Policy"::"Tracking & Action Msg." then begin
                                                    CreateReservEntry.GetLastEntry(SurplusEntry); // Get the surplus-entry just inserted
                                                    IssueActionMessage(SurplusEntry, false, DummyEntry);
                                                end;
                                            end;
                                        end else
                                            if ItemTrackingHandling = ItemTrackingHandling::None then
                                                QuantityIsValidated :=
                                                    SaveItemTrackingAsSurplus(CalcReservEntry4, -ReservEntry.Quantity, -ReservEntry."Quantity (Base)");

                                        if not QuantityIsValidated then
                                            CalcReservEntry4.Validate("Quantity (Base)", -ReservEntry."Quantity (Base)");

                                        CalcReservEntry4.Modify();
                                        QtyToRelease := 0;
                                        QuantityIsValidated := false;
                                    end;
                            until (ReservEntry.Next() = 0) or ((not DeleteAll) and (QtyToRelease = 0));
                            if not ReservEntry.FindFirst() then // Rewind for second cycle
                                Release := Release::Inventory;
                        end;
                end;
        end;

        if HandleItemTracking2 then
            CheckQuantityIsCompletelyReleased(QtyToRelease, DeleteAll, CurrentItemTrackingSetup, ReservEntry);
    end;

    procedure CalculateRemainingQty(var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    begin
        CalcReservEntry.TestField("Source Type");

        OnCalculateRemainingQty(SourceRecRef, CalcReservEntry, RemainingQty, RemainingQtyBase);
    end;

    procedure GetAvailabilityFilter(AvailabilityDate: Date): Text[80]
    begin
        exit(GetAvailabilityFilter2(AvailabilityDate, Positive));
    end;

    local procedure GetAvailabilityFilter2(AvailabilityDate: Date; SearchForSupply: Boolean) Result: Text[80]
    var
        ReservEntry2: Record "Reservation Entry";
    begin
        if SearchForSupply then
            ReservEntry2.SetFilter("Expected Receipt Date", '..%1', AvailabilityDate)
        else
            ReservEntry2.SetFilter("Expected Receipt Date", '>=%1', AvailabilityDate);

        Result := ReservEntry2.GetFilter("Expected Receipt Date");
        OnAfterGetAvailabilityFilter2(ReservEntry2, AvailabilityDate, SearchForSupply, Result);
    end;

    procedure CopySign(FromValue: Decimal; var ToValue: Decimal)
    begin
        if FromValue * ToValue < 0 then
            ToValue := -ToValue;
    end;

    local procedure SetValueArray(EntryStatus: Option Reservation,Tracking,Simulation) ArrayCounter: Integer
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetValueArray(EntryStatus, ValueArray, ArrayCounter, IsHandled);
        if not IsHandled then begin
            Clear(ValueArray);
            case EntryStatus of
                0:
                    begin // Reservation
                        ValueArray[1] := Enum::"Reservation Summary Type"::"Item Ledger Entry".AsInteger();
                        ValueArray[2] := Enum::"Reservation Summary Type"::"Sales Order".AsInteger();
                        ValueArray[3] := Enum::"Reservation Summary Type"::"Sales Return Order".AsInteger();
                        ValueArray[4] := Enum::"Reservation Summary Type"::"Purchase Order".AsInteger();
                        ValueArray[5] := Enum::"Reservation Summary Type"::"Purchase Return Order".AsInteger();
                        ValueArray[6] := Enum::"Reservation Summary Type"::"Firm Planned Production Order".AsInteger();
                        ValueArray[7] := Enum::"Reservation Summary Type"::"Released Production Order".AsInteger();
                        ValueArray[8] := Enum::"Reservation Summary Type"::"Firm Planned Prod. Order Comp.".AsInteger();
                        ValueArray[9] := Enum::"Reservation Summary Type"::"Released Prod. Order Comp.".AsInteger();
                        ValueArray[10] := Enum::"Reservation Summary Type"::"Transfer Shipment".AsInteger();
                        ValueArray[11] := Enum::"Reservation Summary Type"::"Transfer Receipt".AsInteger();
                        ValueArray[12] := Enum::"Reservation Summary Type"::"Service Order".AsInteger();
                        ValueArray[13] := Enum::"Reservation Summary Type"::"Job Planning Order".AsInteger();
                        ValueArray[14] := Enum::"Reservation Summary Type"::"Assembly Order Header".AsInteger();
                        ValueArray[15] := Enum::"Reservation Summary Type"::"Assembly Order Line".AsInteger();
                        ValueArray[16] := Enum::"Reservation Summary Type"::"Inventory Receipt".AsInteger();
                        ValueArray[17] := Enum::"Reservation Summary Type"::"Inventory Shipment".AsInteger();
                        ArrayCounter := 17;
                    end;
                1:
                    begin // Order Tracking
                        ValueArray[1] := Enum::"Reservation Summary Type"::"Item Ledger Entry".AsInteger();
                        ValueArray[2] := Enum::"Reservation Summary Type"::"Sales Order".AsInteger();
                        ValueArray[3] := Enum::"Reservation Summary Type"::"Sales Return Order".AsInteger();
                        ValueArray[4] := Enum::"Reservation Summary Type"::"Requisition Line".AsInteger();
                        ValueArray[5] := Enum::"Reservation Summary Type"::"Purchase Order".AsInteger();
                        ValueArray[6] := Enum::"Reservation Summary Type"::"Purchase Return Order".AsInteger();
                        ValueArray[7] := Enum::"Reservation Summary Type"::"Planned Production Order".AsInteger();
                        ValueArray[8] := Enum::"Reservation Summary Type"::"Firm Planned Production Order".AsInteger();
                        ValueArray[9] := Enum::"Reservation Summary Type"::"Released Production Order".AsInteger();
                        ValueArray[10] := Enum::"Reservation Summary Type"::"Planned Prod. Order Comp.".AsInteger();
                        ValueArray[11] := Enum::"Reservation Summary Type"::"Firm Planned Prod. Order Comp.".AsInteger();
                        ValueArray[12] := Enum::"Reservation Summary Type"::"Released Prod. Order Comp.".AsInteger();
                        ValueArray[13] := Enum::"Reservation Summary Type"::"Transfer Shipment".AsInteger();
                        ValueArray[14] := Enum::"Reservation Summary Type"::"Transfer Receipt".AsInteger();
                        ValueArray[15] := Enum::"Reservation Summary Type"::"Service Order".AsInteger();
                        ValueArray[16] := Enum::"Reservation Summary Type"::"Job Planning Order".AsInteger();
                        ValueArray[17] := Enum::"Reservation Summary Type"::"Assembly Order Header".AsInteger();
                        ValueArray[18] := Enum::"Reservation Summary Type"::"Assembly Order Line".AsInteger();
                        ValueArray[19] := Enum::"Reservation Summary Type"::"Inventory Receipt".AsInteger();
                        ValueArray[20] := Enum::"Reservation Summary Type"::"Inventory Shipment".AsInteger();
                        ArrayCounter := 20;
                    end;
                2:
                    begin // Simulation order tracking
                        ValueArray[1] := Enum::"Reservation Summary Type"::"Sales Quote".AsInteger();
                        ValueArray[2] := Enum::"Reservation Summary Type"::"Simulated Production Order".AsInteger();
                        ValueArray[3] := Enum::"Reservation Summary Type"::"Simulated Prod. Order Comp.".AsInteger();
                        ArrayCounter := 3;
                    end;
                3:
                    begin // Item Tracking
                        ValueArray[1] := Enum::"Reservation Summary Type"::"Item Ledger Entry".AsInteger();
                        ValueArray[2] := Enum::"Reservation Summary Type"::"Item Tracking Line".AsInteger();
                        ArrayCounter := 2;
                    end;
            end;
        end;
        OnAfterSetValueArray(EntryStatus, ValueArray, ArrayCounter);
    end;

    procedure ClearSurplus()
    var
        ReservEntry2: Record "Reservation Entry";
        ActionMessageEntry: Record "Action Message Entry";
    begin
        CalcReservEntry.TestField("Source Type");
        ReservEntry2 := CalcReservEntry;
        ReservEntry2.SetPointerFilter();
        ReservEntry2.SetRange("Reservation Status", ReservEntry2."Reservation Status"::Surplus);
        // Item Tracking
        if ItemTrackingHandling = ItemTrackingHandling::None then
            ReservEntry2.SetTrackingFilterBlank();
        OnClearSurplusOnAfterReservEntry2SetFilters(ReservEntry2, ItemTrackingHandling);

        if Item."Order Tracking Policy" = Item."Order Tracking Policy"::"Tracking & Action Msg." then begin
            ReservEntry2.Lock();
            ReservEntry2.SetLoadFields("Entry No.");
            OnClearSurplusOnBeforeReservEntry2FindSet(ReservEntry2);
            if not ReservEntry2.FindSet() then
                exit;
            ActionMessageEntry.Reset();
            ActionMessageEntry.SetCurrentKey("Reservation Entry");
            repeat
                ActionMessageEntry.SetRange("Reservation Entry", ReservEntry2."Entry No.");
                ActionMessageEntry.DeleteAll();
            until ReservEntry2.Next() = 0;
        end;

        ReservEntry2.SetRange(
          "Reservation Status", ReservEntry2."Reservation Status"::Surplus, ReservEntry2."Reservation Status"::Prospect);
        if not ReservEntry2.IsEmpty() then
            ReservEntry2.DeleteAll();
    end;

    local procedure QuantityTracked(var ReservEntry: Record "Reservation Entry"): Decimal
    var
        ReservEntry2: Record "Reservation Entry";
        QtyTracked: Decimal;
    begin
        ReservEntry2 := ReservEntry;
        ReservEntry2.SetPointerFilter();
        ReservEntry.CopyTrackingFiltersToReservEntry(ReservEntry2);
        if ReservEntry2.FindFirst() then begin
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
        ReservEntry2.SetPointerFilter();
        ReservEntry2.SetTrackingFilterFromReservEntry(ReservEntry);
        ReservEntry2.SetRange("Reservation Status",
          ReservEntry2."Reservation Status"::Tracking, ReservEntry2."Reservation Status"::Prospect);
        if not ReservEntry2.IsEmpty() then begin
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

        if CalcReservEntry."Source Type" in [Database::"Sales Line", Database::"Purchase Line", Database::"Service Line"] then
            if not (CalcReservEntry."Source Subtype" in [1, 5]) then
                exit; // Only order, return order

        if CalcReservEntry."Source Type" in [Database::"Prod. Order Line", Database::"Prod. Order Component"]
        then
            if CalcReservEntry."Source Subtype" = 0 then
                exit; // Not simulation

        if CalcReservEntry."Source Type" = Database::"Item Journal Line" then
            exit;

        if CalcReservEntry."Item No." = '' then
            exit;

        GetItemSetup(CalcReservEntry);
        if Item."Order Tracking Policy" = Item."Order Tracking Policy"::None then
            exit;

        CalcReservEntry.Lock();

        QtyToTrack := CreateReservEntry.SignFactor(CalcReservEntry) * TotalQty - QuantityTracked(CalcReservEntry);

        if QtyToTrack = 0 then begin
            UpdateDating();
            exit;
        end;

        QtyToTrack := MatchSurplus(CalcReservEntry, SurplusEntry, QtyToTrack, Positive, AvailabilityDate, Item."Order Tracking Policy");

        // Make residual surplus record:
        if QtyToTrack <> 0 then begin
            if CurrentBindingIsSet then
                MakeConnection(
                    CalcReservEntry, SurplusEntry, QtyToTrack, CalcReservEntry."Reservation Status"::Surplus, AvailabilityDate, CurrentBinding)
            else
                MakeConnection(
                    CalcReservEntry, SurplusEntry, QtyToTrack, CalcReservEntry."Reservation Status"::Surplus, AvailabilityDate, CalcReservEntry.Binding);

            CreateReservEntry.GetLastEntry(SurplusEntry); // Get the surplus-entry just inserted
            if SurplusEntry.IsResidualSurplus() then begin
                SurplusEntry."Untracked Surplus" := true;
                SurplusEntry.Modify();
            end;
            if Item."Order Tracking Policy" = Item."Order Tracking Policy"::"Tracking & Action Msg." then // Issue Action Message
                IssueActionMessage(SurplusEntry, true, DummyEntry);
        end else
            UpdateDating();
    end;

    procedure MatchSurplus(var ReservEntry: Record "Reservation Entry"; var SurplusEntry: Record "Reservation Entry"; QtyToTrack: Decimal; SearchForSupply: Boolean; var AvailabilityDate: Date; TrackingPolicy: Enum "Order Tracking Policy"): Decimal
    var
        ReservEntry2: Record "Reservation Entry";
        Search: Text[1];
        NextStep: Integer;
        ReservationStatus: Enum "Reservation Status";
    begin
        if QtyToTrack = 0 then
            exit;

        ReservEntry.Lock();
        SurplusEntry.SetCurrentKey(
          "Item No.", "Variant Code", "Location Code", "Reservation Status",
          "Shipment Date", "Expected Receipt Date", "Serial No.", "Lot No.");
        SurplusEntry.SetRange("Item No.", ReservEntry."Item No.");
        SurplusEntry.SetRange("Variant Code", ReservEntry."Variant Code");
        SurplusEntry.SetRange("Location Code", ReservEntry."Location Code");
        SurplusEntry.SetRange("Reservation Status", SurplusEntry."Reservation Status"::Surplus);
        SurplusEntry.SetRange(Positive, SearchForSupply);
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
        SurplusEntry.FilterLinesForTracking(ReservEntry, SearchForSupply);
        if SurplusEntry.Find(Search) then
            repeat
                if not IsSpecialOrderOrDropShipment(SurplusEntry) then begin
                    ReservationStatus := ReservationStatus::Tracking;
                    if Abs(SurplusEntry."Quantity (Base)") <= Abs(QtyToTrack) then begin
                        ReservEntry2 := SurplusEntry;
                        MakeConnection(
                            ReservEntry, SurplusEntry, -SurplusEntry."Quantity (Base)", ReservationStatus, AvailabilityDate, SurplusEntry.Binding);
                        QtyToTrack := QtyToTrack + SurplusEntry."Quantity (Base)";
                        SurplusEntry := ReservEntry2;
                        SurplusEntry.Delete();
                        if TrackingPolicy = TrackingPolicy::"Tracking & Action Msg." then
                            ModifyActionMessage(SurplusEntry."Entry No.", 0, true); // Delete related Action Message
                    end else begin
                        SurplusEntry.Validate("Quantity (Base)", SurplusEntry."Quantity (Base)" + QtyToTrack);
                        SurplusEntry.Modify();
                        MakeConnection(
                            ReservEntry, SurplusEntry, QtyToTrack, ReservationStatus, AvailabilityDate, SurplusEntry.Binding);
                        if TrackingPolicy = TrackingPolicy::"Tracking & Action Msg." then
                            ModifyActionMessage(SurplusEntry."Entry No.", QtyToTrack, false); // Modify related Action Message
                        QtyToTrack := 0;
                    end;
                end;
            until (SurplusEntry.Next(NextStep) = 0) or (QtyToTrack = 0);

        SurplusEntry.SetRange(Positive);
        exit(QtyToTrack);
    end;

    local procedure MakeConnection(var FromReservEntry: Record "Reservation Entry"; var ToReservEntry: Record "Reservation Entry"; Quantity: Decimal; ReservationStatus: Enum "Reservation Status"; AvailabilityDate: Date; Binding: Enum "Reservation Binding")
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
            if FromReservEntry."Source Type" = Database::"Purchase Line" then
                ToReservEntry."Shipment Date" := 0D;
            if FromReservEntry."Source Type" = Database::"Sales Line" then
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
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMakeRoomForReservation(ReservEntry, IsHandled);
        if IsHandled then
            exit;

        TotalQuantity := SourceQuantity(ReservEntry, false);
        ReservEntry2 := ReservEntry;
        ReservEntry2.SetPointerFilter();
        ItemTrackingHandling := ItemTrackingHandling::Match;
        DeleteReservEntries(false, TotalQuantity - (ReservEntry."Quantity (Base)" * CreateReservEntry.SignFactor(ReservEntry)),
          ReservEntry2);
    end;

    local procedure SaveTrackingSpecification(var ReservEntry: Record "Reservation Entry"; QtyReleased: Decimal)
    begin
        // Used when creating reservations.
        if ItemTrackingHandling = ItemTrackingHandling::None then
            exit;
        if not ReservEntry.TrackingExists() then
            exit;
        TempTrackingSpecification.SetTrackingFilterFromReservEntry(ReservEntry);
        if TempTrackingSpecification.FindSet() then begin
            TempTrackingSpecification.Validate("Quantity (Base)",
              TempTrackingSpecification."Quantity (Base)" + QtyReleased);
            TempTrackingSpecification.Modify();
        end else begin
            TempTrackingSpecification.TransferFields(ReservEntry);
            TempTrackingSpecification.Validate("Quantity (Base)", QtyReleased);
            TempTrackingSpecification.Insert();
        end;
        TempTrackingSpecification.Reset();

        OnAfterSaveTrackingSpecification(ReservEntry, TempTrackingSpecification, QtyReleased);
    end;

    procedure CollectTrackingSpecification(var TargetTrackingSpecification: Record "Tracking Specification" temporary): Boolean
    begin
        // Used when creating reservations.
        TempTrackingSpecification.Reset();
        TargetTrackingSpecification.Reset();

        if not TempTrackingSpecification.FindSet() then
            exit(false);

        repeat
            TargetTrackingSpecification := TempTrackingSpecification;
            TargetTrackingSpecification.Insert();
        until TempTrackingSpecification.Next() = 0;

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

        OnFilterReservFor(SourceRecRef, ReservEntry, Direction.AsInteger(), CaptionText);
    end;

    procedure GetSourceRecordValue(var ReservEntry: Record "Reservation Entry"; SetAsCurrent: Boolean; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)") SourceQty: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnGetSourceRecordValue(ReservEntry, SetAsCurrent, ReturnOption, SourceQty, SourceRecRef, IsHandled);
        if IsHandled then
            exit;

        if SetAsCurrent then
            SetReservSource(SourceRecRef, ReservEntry.GetTransferDirection());
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
        IsHandled: Boolean;
    begin
        if not ReservEntry.FindSet() then
            exit;

        SignFactor := CreateReservEntry.SignFactor(ReservEntry);
        repeat
            if ReservEntry2.Get(ReservEntry."Entry No.", not ReservEntry.Positive) then
                if ReservEntry2.HasSamePointer(TargetReservEntry) then begin
                    ReservEntry.Mark(true);
                    IsHandled := false;
                    OnBeforeReservedQuantityAssign(ReservEntry, ReservedQuantity, SignFactor, IsHandled);
                    if not IsHandled then
                        ReservedQuantity += ReservEntry."Quantity (Base)" * SignFactor;
                end;
        until ReservEntry.Next() = 0;
        ReservEntry.MarkedOnly(true);
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
        if SurplusEntry.IsReservationOrTracking() then
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
            if not (SurplusEntry."Source Type" in [Database::"Prod. Order Line", Database::"Purchase Line"]) then
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
                            ReservEntry.FilterLinesForTracking(SurplusEntry, Positive);
                            ReservEntry.SetRange(Positive, true);
                        end;
                        ReservEntry.SetRange(Binding, ReservEntry.Binding::" ");
                        ReservEntry.SetRange("Planning Flexibility", ReservEntry."Planning Flexibility"::Unlimited);
                        ReservEntry.SetFilter("Source Type", '=%1|=%2', Database::"Purchase Line", Database::"Prod. Order Line");
                    end;
                SurplusEntry.Binding::"Order-to-Order":
                    begin
                        ReservEntry3 := SurplusEntry;
                        ReservEntry3.SetPointerFilter();
                        ReservEntry3.SetRange(
                          "Reservation Status", ReservEntry3."Reservation Status"::Reservation, ReservEntry3."Reservation Status"::Tracking);
                        ReservEntry3.SetRange(Binding, ReservEntry3.Binding::"Order-to-Order");
                        if ReservEntry3.FindFirst() then begin
                            ReservEntry3.Get(ReservEntry3."Entry No.", not ReservEntry3.Positive);
                            ReservEntry := ReservEntry3;
                            ReservEntry.SetRecFilter();
                            Found := true;
                        end else begin
                            Found := false;
                            FreeBinding := true;
                        end;
                    end;
            end;

            ActionMessageEntry.Quantity := -(SurplusEntry."Quantity (Base)" + SurplusEntry."Action Message Adjustment");

            if not FreeBinding then begin
                ReservEntry.SetLoadFields(
                    "Source Type", "Source Subtype", "Source ID", "Source Batch Name", "Source Prod. Order Line", "Source Ref. No.");
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
                        ActionMessageEntry."Source Type" := Database::"Purchase Line";
                    SKU."Replenishment System"::"Prod. Order":
                        ActionMessageEntry."Source Type" := Database::"Prod. Order Line";
                    SKU."Replenishment System"::Transfer:
                        ActionMessageEntry."Source Type" := Database::"Transfer Line";
                    SKU."Replenishment System"::Assembly:
                        ActionMessageEntry."Source Type" := Database::"Assembly Header";
                end;

                ActionMessageEntry.Type := ActionMessageEntry.Type::New;
            end;
            ActionMessageEntry."Reservation Entry" := SurplusEntry."Entry No.";
        end;

        ReservEntry2.SetPointerFilter();
        ReservEntry2.SetRange(
          "Reservation Status", ReservEntry2."Reservation Status"::Reservation, ReservEntry2."Reservation Status"::Tracking);

        if ReservEntry2."Source Type" <> Database::"Item Ledger Entry" then
            if ReservEntry2.FindFirst() then begin
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
                        while not ActionMessageEntry2.Insert() do
                            ActionMessageEntry2."Entry No." += 1;
                        ActionMessageEntry."Entry No." := ActionMessageEntry2."Entry No." + 1;
                    end;
                end;
            end;

        while not ActionMessageEntry.Insert() do
            ActionMessageEntry."Entry No." += 1;
    end;

    procedure ModifyActionMessage(RelatedToEntryNo: Integer; Quantity: Decimal; DoDelete: Boolean)
    var
        ActionMessageEntry: Record "Action Message Entry";
    begin
        ActionMessageEntry.Reset();
        ActionMessageEntry.SetCurrentKey("Reservation Entry");
        ActionMessageEntry.SetRange("Reservation Entry", RelatedToEntryNo);

        if DoDelete then begin
            ActionMessageEntry.DeleteAll();
            exit;
        end;
        ActionMessageEntry.SetRange("New Date", 0D);

        if ActionMessageEntry.FindFirst() then begin
            ActionMessageEntry.Quantity -= Quantity;
            if ActionMessageEntry.Quantity = 0 then
                ActionMessageEntry.Delete()
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

        if not ReservEntry2.FindSet() then
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
                    until ReservEntry2.Next() = 0;
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
                    until ReservEntry2.Next() = 0;
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
        if CalcReservEntry2."Source Type" = Database::"Planning Component" then
            exit;

        if Item."Order Tracking Policy" <> Item."Order Tracking Policy"::"Tracking & Action Msg." then
            exit;

        if CalcReservEntry2."Source Type" = Database::"Requisition Line" then
            if PlanningLineOrigin <> ReqLine."Planning Line Origin"::" " then
                exit;

        FilterReservEntry := CalcReservEntry2;
        FilterReservEntry.SetPointerFilter();

        if not FilterReservEntry.FindFirst() then
            exit;

        if CalcReservEntry2."Source Type" in [Database::"Prod. Order Line", Database::"Purchase Line"]
        then
            ReservEngineMgt.ModifyActionMessageDating(FilterReservEntry)
        else begin
            if FilterReservEntry.Positive then
                exit;
            FilterReservEntry.SetRange("Reservation Status", FilterReservEntry."Reservation Status"::Reservation,
              FilterReservEntry."Reservation Status"::Tracking);
            if not FilterReservEntry.FindSet() then
                exit;
            repeat
                if ReservEntry2.Get(FilterReservEntry."Entry No.", not FilterReservEntry.Positive) then
                    ReservEngineMgt.ModifyActionMessageDating(ReservEntry2);
            until FilterReservEntry.Next() = 0;
        end;
    end;

    procedure ClearActionMessageReferences()
    var
        ActionMessageEntry: Record "Action Message Entry";
        ActionMessageEntry2: Record "Action Message Entry";
    begin
        ActionMessageEntry.Reset();
        ActionMessageEntry.FilterFromReservEntry(CalcReservEntry);
        if ActionMessageEntry.FindSet() then
            repeat
                ActionMessageEntry2 := ActionMessageEntry;
                if ActionMessageEntry2.Quantity = 0 then
                    ActionMessageEntry2.Delete()
                else begin
                    ActionMessageEntry2."Source Subtype" := 0;
                    ActionMessageEntry2."Source ID" := '';
                    ActionMessageEntry2."Source Batch Name" := '';
                    ActionMessageEntry2."Source Prod. Order Line" := 0;
                    ActionMessageEntry2."Source Ref. No." := 0;
                    ActionMessageEntry2."New Date" := 0D;
                    ActionMessageEntry2.Modify();
                end;
            until ActionMessageEntry.Next() = 0;
    end;

    procedure SetItemTrackingHandling(Mode: Option "None","Allow deletion",Match)
    begin
        ItemTrackingHandling := Mode;
    end;

    procedure DeleteItemTrackingConfirm() Result: Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteItemTrackingConfirm(CalcReservEntry2, IsHandled, Result);
        if IsHandled then
            exit(Result);

        if not ItemTrackingExist(CalcReservEntry2) then
            exit(true);

        if ConfirmManagement.GetResponseOrDefault(
             StrSubstNo(Text011, CalcReservEntry2."Item No.", CalcReservEntry2.TextCaption()), true)
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
        FilterReservEntry.FilterLinesForTracking(ReservEntry, SearchForSupply);
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
    var
        ShouldCalsReservedQtyOnPick: Boolean;
    begin
        ShouldCalsReservedQtyOnPick :=
            Positive and (CalcReservEntry."Location Code" <> '') and
            Location.Get(CalcReservEntry."Location Code") and (Location."Bin Mandatory" or Location."Require Pick");

        OnBeforeCallCalcReservedQtyOnPick(CalcReservEntry, Positive, ShouldCalsReservedQtyOnPick);

        if ShouldCalsReservedQtyOnPick then
            CalcReservedQtyOnPick(TotalAvailQty, QtyAllocInWhse);
    end;

    local procedure CalcReservedQtyOnPick(var AvailQty: Decimal; var AllocQty: Decimal)
    var
        WhseActivLine: Record "Warehouse Activity Line";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        TempWhseActivLine2: Record "Warehouse Activity Line" temporary;
        TempBinContentBuffer: Record "Bin Content Buffer" temporary;
        WhseAvailMgt: Codeunit "Warehouse Availability Mgt.";
        QtyOnOutboundBins: Decimal;
        QtyOnInvtMovement: Decimal;
        QtyOnSpecialBins: Decimal;
        IsHandled: Boolean;
    begin
        GetItemSetup(CalcReservEntry);
        Item.SetRange("Location Filter", CalcReservEntry."Location Code");
        IsHandled := false;
        OnCalcReservedQtyOnPickOnbeforeSetItemVariantCodeFilter(Item, CalcReservEntry, IsHandled);
        if not IsHandled then
            Item.SetRange("Variant Filter", CalcReservEntry."Variant Code");
        CalcReservEntry.SetTrackingFilterToItemIfRequired(Item);
        Item.CalcFields(Inventory, "Reserved Qty. on Inventory");

        WhseActivLine.SetCurrentKey(
          "Item No.", "Bin Code", "Location Code", "Action Type", "Variant Code",
          "Unit of Measure Code", "Breakbulk No.", "Activity Type", "Lot No.", "Serial No.");

        WhseActivLine.SetRange("Item No.", CalcReservEntry."Item No.");
        if Location."Bin Mandatory" then
            WhseActivLine.SetFilter("Bin Code", '<>%1', '');
        WhseActivLine.SetRange("Location Code", CalcReservEntry."Location Code");
        WhseActivLine.SetFilter(
          "Action Type", '%1|%2', WhseActivLine."Action Type"::" ", WhseActivLine."Action Type"::Take);
        IsHandled := false;
        OnCalcReservedQtyOnPickOnBeforeSetWhseActivLineVariantCodeFilter(WhseActivLine, CalcReservEntry, IsHandled);
        if not IsHandled then
            WhseActivLine.SetRange("Variant Code", CalcReservEntry."Variant Code");
        WhseActivLine.SetRange("Breakbulk No.", 0);
        WhseActivLine.SetFilter(
          "Activity Type", '%1|%2', WhseActivLine."Activity Type"::Pick, WhseActivLine."Activity Type"::"Invt. Pick");
        WhseActivLine.SetTrackingFilterFromReservEntryIfRequired(CalcReservEntry);
        WhseActivLine.CalcSums("Qty. Outstanding (Base)");

        if Location."Require Pick" then begin
            WhseItemTrackingSetup.CopyTrackingFromItemTrackingCodeSpecificTracking(ItemTrackingCode);
            WhseItemTrackingSetup.CopyTrackingFromReservEntry(CalcReservEntry);

            if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" and
               WhseItemTrackingSetup.TrackingExists()
            then begin
                WhseAvailMgt.GetOutboundBinsOnBasicWarehouseLocation(
                  TempBinContentBuffer, CalcReservEntry."Location Code", CalcReservEntry."Item No.", CalcReservEntry."Variant Code", WhseItemTrackingSetup);
                TempBinContentBuffer.CalcSums("Qty. Outstanding (Base)");
                QtyOnOutboundBins := TempBinContentBuffer."Qty. Outstanding (Base)";
            end else
                QtyOnOutboundBins :=
                    WhseAvailMgt.CalcQtyOnOutboundBins(CalcReservEntry."Location Code", CalcReservEntry."Item No.", CalcReservEntry."Variant Code", WhseItemTrackingSetup, true);

            QtyReservedOnPickShip :=
              WhseAvailMgt.CalcReservQtyOnPicksShips(
                CalcReservEntry."Location Code", CalcReservEntry."Item No.", CalcReservEntry."Variant Code", TempWhseActivLine2);

            QtyOnInvtMovement := CalcQtyOnInvtMovement(WhseActivLine);

            QtyOnSpecialBins :=
                WhseAvailMgt.CalcQtyOnSpecialBinsOnLocation(
                  CalcReservEntry."Location Code", CalcReservEntry."Item No.", CalcReservEntry."Variant Code", WhseItemTrackingSetup, TempBinContentBuffer);
        end;

        CalcAvailAllocQuantities(
            Item, WhseActivLine, QtyOnOutboundBins, QtyOnInvtMovement, QtyOnSpecialBins, AvailQty, AllocQty);

        OnAfterCalcReservedQtyOnPick(Item, WhseActivLine, CalcReservEntry, AvailQty, AllocQty);
    end;

    local procedure CalcAvailAllocQuantities(
        Item: Record Item; WhseActivLine: Record "Warehouse Activity Line";
        QtyOnOutboundBins: Decimal; QtyOnInvtMovement: Decimal; QtyOnSpecialBins: Decimal;
        var AvailQty: Decimal; var AllocQty: Decimal)
    var
        IsHandled: Boolean;
        PickQty: Decimal;
    begin
        IsHandled := false;
        OnBeforeCalcAvailAllocQuantities(
            Item, WhseActivLine, QtyOnOutboundBins, QtyOnInvtMovement, QtyOnSpecialBins,
            AvailQty, AllocQty, IsHandled);
        if IsHandled then
            exit;

        AllocQty :=
            WhseActivLine."Qty. Outstanding (Base)" + QtyOnInvtMovement +
            QtyOnOutboundBins + QtyOnSpecialBins;
        PickQty := WhseActivLine."Qty. Outstanding (Base)" + QtyOnInvtMovement;

        AvailQty :=
            Item.Inventory - PickQty - QtyOnOutboundBins - QtyOnSpecialBins -
            Item."Reserved Qty. on Inventory" + QtyReservedOnPickShip;
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

        if ReservEntry."Source Type" = Database::"Item Ledger Entry" then
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

    procedure CalcIsAvailTrackedQtyInBin(ItemNo: Code[20]; BinCode: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceProdOrderLine: Integer; SourceRefNo: Integer) Result: Boolean
    var
        ReservationEntry: Record "Reservation Entry";
        WhseEntry: Record "Warehouse Entry";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcIsAvailTrackedQtyInBin(ItemNo, BinCode, LocationCode, VariantCode, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not ItemTrackingMgt.GetWhseItemTrkgSetup(ItemNo) or (BinCode = '') then
            exit(true);

        ReservationEntry.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, false);
        ReservationEntry.SetSourceFilter(SourceBatchName, SourceProdOrderLine);
        ReservationEntry.SetRange(Positive, false);
        if ReservationEntry.FindSet() then
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
            until ReservationEntry.Next() = 0;

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
            until WarehouseActivityLine.Next() = 0;

        WarehouseActivityLine.Copy(xWarehouseActivityLine);
        exit(OutstandingQty);
    end;

    local procedure ProdJnlLineEntry(ReservationEntry: Record "Reservation Entry"): Boolean
    begin
        exit((ReservationEntry."Source Type" = Database::"Item Journal Line") and (ReservationEntry."Source Subtype" = 6));
    end;

    local procedure CalcDownToQtySyncingToAssembly(ReservEntry: Record "Reservation Entry"): Decimal
    var
        SynchronizingSalesLine: Record "Sales Line";
    begin
        if ReservEntry."Source Type" = Database::"Sales Line" then begin
            SynchronizingSalesLine.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Ref. No.");
            if (Item."Order Tracking Policy" <> Item."Order Tracking Policy"::None) and
               (Item."Assembly Policy" = Item."Assembly Policy"::"Assemble-to-Order") and
               (Item."Replenishment System" = Item."Replenishment System"::Assembly) and
               (SynchronizingSalesLine."Quantity (Base)" = 0)
            then
                exit(ReservEntry."Quantity (Base)" * CreateReservEntry.SignFactor(ReservEntry));
        end;
    end;

    procedure AutoReserveToShip(var FullAutoReservation: Boolean; Description: Text[100]; AvailabilityDate: Date; QuantityToShip: Decimal; QuantityToShipBase: Decimal)
    var
        RemainingQtyToReserve: Decimal;
        RemainingQtyToReserveBase: Decimal;
        StopReservation: Boolean;
    begin
        CalcReservEntry.TestField("Source Type");

        if CalcReservEntry."Source Type" in [1 /*Sales*/, 3 /* Purchase*/]
        then
            StopReservation := not (CalcReservEntry."Source Subtype" in [1, 2, 5]); // Only invoice, order and return order

        if CalcReservEntry."Source Type" in [7 /*Prod. Order Line"*/, 8 /* Prod. Order Component */]
        then
            StopReservation := CalcReservEntry."Source Subtype" < 2; // Not simulated or planned

        if StopReservation then begin
            FullAutoReservation := true;
            exit;
        end;

        RemainingQtyToReserve := QuantityToShip;
        RemainingQtyToReserveBase := QuantityToShipBase;
        FullAutoReservation := false;

        if RemainingQtyToReserve = 0 then begin
            FullAutoReservation := true;
            exit;
        end;

        SetValueArray(0);
        AutoReserveOneLine(ValueArray[1], RemainingQtyToReserve, RemainingQtyToReserveBase, Description, AvailabilityDate);

        FullAutoReservation := (RemainingQtyToReserve = 0);
    end;

    local procedure CalcCurrLineReservQtyOnPicksShips(ReservationEntry: Record "Reservation Entry"): Decimal
    var
        ReservEntry: Record "Reservation Entry";
        TempWhseActivLine: Record "Warehouse Activity Line" temporary;
        WhseAvailMgt: Codeunit "Warehouse Availability Mgt.";
        PickQty: Decimal;
    begin
        PickQty := WhseAvailMgt.CalcRegisteredAndOutstandingPickQty(ReservationEntry, TempWhseActivLine);

        ReservEntry.SetSourceFilter(
          ReservationEntry."Source Type", ReservationEntry."Source Subtype",
          ReservationEntry."Source ID", ReservationEntry."Source Ref. No.", false);
        ReservEntry.SetRange("Source Prod. Order Line", ReservationEntry."Source Prod. Order Line");
        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
        ReservEntry.CalcSums("Quantity (Base)");
        if -ReservEntry."Quantity (Base)" > PickQty then
            exit(PickQty);
        exit(-ReservEntry."Quantity (Base)");
    end;

    local procedure CheckQuantityIsCompletelyReleased(QtyToRelease: Decimal; DeleteAll: Boolean; CurrentItemTrackingSetup: Record "Item Tracking Setup"; ReservEntry: Record "Reservation Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckQuantityIsCompletelyReleased(ItemTrackingHandling, QtyToRelease, DeleteAll, CurrentItemTrackingSetup, ReservEntry, IsHandled);
        if IsHandled then
            exit;

        if QtyToRelease = 0 then
            exit;

        if ItemTrackingHandling = ItemTrackingHandling::None then begin
            if DeleteAll then
                Error(Text010, ReservEntry."Item No.", ReservEntry.TextCaption());
            if not ProdJnlLineEntry(ReservEntry) then
                Error(Text008, ReservEntry."Item No.", ReservEntry.TextCaption());
        end;

        if ItemTrackingHandling = ItemTrackingHandling::Match then
            Error(
                ItemTrackingCannotBeFullyMatchedErr,
                CurrentItemTrackingSetup."Serial No.", CurrentItemTrackingSetup."Lot No.", Abs(QtyToRelease));
    end;

    [Scope('OnPrem')]
    procedure ReservEntryPositiveTypeIsItemLedgerEntry(ReservationEntryNo: Integer): Boolean
    var
        ReservationEntryPositive: Record "Reservation Entry";
    begin
        if ReservationEntryPositive.Get(ReservationEntryNo, true) then
            exit(ReservationEntryPositive."Source Type" = Database::"Item Ledger Entry");

        exit(true);
    end;

    procedure DeleteDocumentReservation(TableID: Integer; DocType: Option; DocNo: Code[20]; HideValidationDialog: Boolean)
    var
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        ConfirmManagement: Codeunit "Confirm Management";
        DocTypeCaption: Text;
        Confirmed: Boolean;
    begin
        OnBeforeDeleteDocumentReservation(TableID, DocType, DocNo, HideValidationDialog);

        ReservEntry.Reset();
        ReservEntry.SetCurrentKey(
            "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
            "Source Batch Name", "Source Prod. Order Line", "Reservation Status");
        if TableID <> Database::"Prod. Order Line" then begin
            ReservEntry.SetRange("Source Type", TableID);
            ReservEntry.SetRange("Source Prod. Order Line", 0);
        end else
            ReservEntry.SetFilter("Source Type", '%1|%2', Database::"Prod. Order Line", Database::"Prod. Order Component");

        case TableID of
            Database::"Transfer Line":
                ReservEntry.SetRange("Source Subtype");
            Database::"Prod. Order Line":
                ReservEntry.SetRange("Source Subtype", DocType);
            Database::"Assembly Line":
                ReservEntry.SetRange("Source Subtype", DocType);
            else
                ReservEntry.SetRange("Source Subtype", DocType);
        end;

        ReservEntry.SetRange("Source ID", DocNo);
        ReservEntry.SetRange("Source Batch Name", '');
        ReservEntry.SetFilter("Item Tracking", '> %1', Enum::"Item Tracking Entry Type"::None);
        if ReservEntry.IsEmpty() then
            exit;

        if HideValidationDialog then
            Confirmed := true
        else begin
            DocTypeCaption := GetDocumentReservationDeleteQst(TableID, DocType, DocNo);
            Confirmed := ConfirmManagement.GetResponseOrDefault(DocTypeCaption, true);
        end;

        if not Confirmed then
            Error('');

        if ReservEntry.FindSet() then
            repeat
                ReservEntry2 := ReservEntry;
                ReservEntry2.ClearItemTrackingFields();
                ReservEntry2.Modify();
                OnDeleteDocumentReservationOnAfterReservEntry2Modify(ReservEntry);
            until ReservEntry.Next() = 0;
    end;

    local procedure GetDocumentReservationDeleteQst(TableID: Integer; DocType: Option; DocNo: Code[20]): Text
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        DocTypeCaption: Text;
        IsHandled: Boolean;
    begin
        case TableID of
            Database::"Transfer Line":
                exit(StrSubstNo(DeleteTransLineWithItemReservQst, DocNo));
            Database::"Prod. Order Line":
                begin
                    RecRef.Open(TableID);
                    FldRef := RecRef.FieldIndex(1);
                    exit(StrSubstNo(DeleteProdOrderLineWithItemReservQst, SelectStr(DocType + 1, FldRef.OptionCaption), DocNo));
                end;
            Database::"Assembly Line":
                begin
                    RecRef.Open(TableID);
                    FldRef := RecRef.FieldIndex(1);
                    case DocType of
                        Enum::"Assembly Document Type"::Quote.AsInteger(),
                        Enum::"Assembly Document Type"::"Order".AsInteger():
                            exit(StrSubstNo(DeleteDocLineWithItemReservQst, SelectStr(DocType + 1, FldRef.OptionCaption), DocNo));
                        Enum::"Assembly Document Type"::"Blanket Order".AsInteger():
                            exit(StrSubstNo(DeleteDocLineWithItemReservQst, SelectStr(3, FldRef.OptionCaption), DocNo));
                    end;
                end;
            else begin
                RecRef.Open(TableID);
                FldRef := RecRef.FieldIndex(1);
                OnGetDocumentReservationDeleteQstOnElseCase(RecRef, FldRef, DocType, DocTypeCaption, IsHandled);
                if not IsHandled then
                    exit(StrSubstNo(DeleteDocLineWithItemReservQst, SelectStr(DocType + 1, FldRef.OptionCaption), DocNo));
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetSkipUntrackedSurplus(NewSkipUntrackedSurplus: Boolean)
    begin
        SkipUntrackedSurplus := NewSkipUntrackedSurplus;
    end;

    procedure SetQtyToReserveDownToTrackedQuantity(ReservEntry: Record "Reservation Entry"; RowID: Text[250]; var QtyThisLine: Decimal; var QtyThisLineBase: Decimal)
    var
        FilterReservEntry: Record "Reservation Entry";
        TempTrackingSpec: Record "Tracking Specification" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        MaxReservQtyPerLotOrSerial: Decimal;
        MaxReservQtyBasePerLotOrSerial: Decimal;
    begin
        if not ReservEntry.TrackingExists() then
            exit;

        FilterReservEntry.SetPointer(RowID);
        FilterReservEntry.SetPointerFilter();
        FilterReservEntry.SetTrackingFilterFromReservEntry(ReservEntry);
        ItemTrackingMgt.SumUpItemTracking(FilterReservEntry, TempTrackingSpec, true, true);

        MaxReservQtyBasePerLotOrSerial := TempTrackingSpec."Quantity (Base)";
        MaxReservQtyPerLotOrSerial :=
            UOMMgt.CalcQtyFromBase(
                FilterReservEntry."Item No.", FilterReservEntry."Variant Code", '',
                MaxReservQtyBasePerLotOrSerial, TempTrackingSpec."Qty. per Unit of Measure");
        QtyThisLine := GetMinAbs(QtyThisLine, MaxReservQtyPerLotOrSerial) * GetSign(QtyThisLine);
        QtyThisLineBase := GetMinAbs(QtyThisLineBase, MaxReservQtyBasePerLotOrSerial) * GetSign(QtyThisLineBase);
    end;

    local procedure IsSpecialOrderOrDropShipment(ReservationEntry: Record "Reservation Entry"): Boolean
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
    begin
        if ReservationEntry."Source Type" = Database::"Sales Line" then
            if SalesLine.Get(ReservationEntry."Source Subtype", ReservationEntry."Source ID", ReservationEntry."Source Ref. No.") then
                if SalesLine."Special Order" or SalesLine."Drop Shipment" then
                    exit(true);
        if ReservationEntry."Source Type" = Database::"Purchase Line" then
            if PurchaseLine.Get(ReservationEntry."Source Subtype", ReservationEntry."Source ID", ReservationEntry."Source Ref. No.") then
                if PurchaseLine."Special Order" or PurchaseLine."Drop Shipment" then
                    exit(true);
        exit(false);
    end;

    procedure FindUnfinishedSpecialOrderSalesNo(ItemLedgerEntry: Record "Item Ledger Entry") Result: Code[20]
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        SalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindUnfinishedSpecialOrderSalesNo(ItemLedgerEntry, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if ItemLedgerEntry."Document Type" = ItemLedgerEntry."Document Type"::"Purchase Receipt" then
            if PurchRcptLine.Get(ItemLedgerEntry."Document No.", ItemLedgerEntry."Document Line No.") then
                if SalesLine.Get(
                     SalesLine."Document Type"::Order, PurchRcptLine."Special Order Sales No.", PurchRcptLine."Special Order Sales Line No.")
                then
                    if SalesLine.Quantity <> SalesLine."Quantity Shipped" then
                        exit(SalesLine."Document No.");

        exit('');
    end;

    procedure GetMinAbs(Value1: Decimal; Value2: Decimal): Decimal
    begin
        Value1 := Abs(Value1);
        Value2 := Abs(Value2);
        if Value1 <= Value2 then
            exit(Value1);
        exit(Value2);
    end;

    procedure GetSign(Value: Decimal): Integer
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
            Database::"Assembly Line":
                begin
                    SourceRecRef.SetTable(AssemblyLine);
                    AssemblyLine.TestField(Type, AssemblyLine.Type::Item);
                end;
            Database::"Sales Line":
                begin
                    SourceRecRef.SetTable(SalesLine);
                    SalesLine.TestField(Type, SalesLine.Type::Item);
                end;
            Database::"Purchase Line":
                begin
                    SourceRecRef.SetTable(PurchaseLine);
                    PurchaseLine.TestField(Type, PurchaseLine.Type::Item);
                end;
            Database::"Service Line":
                begin
                    SourceRecRef.SetTable(ServiceLine);
                    ServiceLine.TestField(Type, ServiceLine.Type::Item);
                end;
            Database::"Job Planning Line":
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

    [IntegrationEvent(true, false)]
    local procedure OnAfterAutoReserveOneLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; Search: Text[1]; NextStep: Integer; CalcReservEntry: Record "Reservation Entry"; CalcReservEntry2: Record "Reservation Entry"; Positive: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAutoReservePurchLine(var PurchLine: Record "Purchase Line"; ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcReservation(var ReservEntry: Record "Reservation Entry"; var ItemLedgEntry: Record "Item Ledger Entry"; var ResSummEntryNo: Integer; var QtyThisLine: Decimal; var QtyThisLineBase: Decimal; TotalAvailQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAutoReserveItemLedgEntry(var CalcItemLedgEntry: Record "Item Ledger Entry"; var RemainingQtyToReserveBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAvailabilityFilter2(var ReservationEntry: Record "Reservation Entry"; AvailabilityDate: Date; SearchForSupply: Boolean; Result: Text[80])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertReservationEntries(var TrackingSpecification: Record "Tracking Specification"; var CalcReservEntry: Record "Reservation Entry"; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; var QtyThisLine: Decimal; var QtyThisLineBase: Decimal; var ReservationCreated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserveOneLine(var IsHandled: Boolean; var AvailabilityDate: Date; var CalcReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcIsAvailTrackedQtyInBin(ItemNo: Code[20]; BinCode: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteDocumentReservation(TableID: Integer; DocType: Option; DocNo: Code[20]; var HideValidationDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMakeRoomForReservation(var ReservationEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetValueArray(EntryStatus: Option; var ValueArray: array[30] of Integer; var ArrayCounter: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateStatistics(var AvailabilityDate: Date)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInitFilter(var CalcReservEntry: Record "Reservation Entry"; EntryID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSaveTrackingSpecification(var ReservationEntry: Record "Reservation Entry"; var TrackingSpecification: Record "Tracking Specification"; QtyReleased: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservSource(var SourceRecRef: RecordRef; var CalcReservEntry: Record "Reservation Entry"; var Direction: Enum "Transfer Direction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetValueArray(EntryStatus: Option Reservation,Tracking,Simulation; var ValueArray: array[30] of Integer; var ArrayCounter: Integer)
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
    local procedure OnAutoReserveOnBeforeStopReservation(var CalcReservEntry: Record "Reservation Entry"; var FullAutoReservation: Boolean; var AvailabilityDate: Date; var MaxQtyToReserve: Decimal; var MaxQtyToReserveBase: Decimal; var StopReservation: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAutoReserveOnBeforeSetValueArray(var ValueArrayNo: Integer; AvailabilityDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAutoReserveOneLineOnAfterUpdateSearchNextStep(var Item: Record Item; var Positive: Boolean; var Search: Text[1]; var NextStep: Integer; var InvSearch: Text[1]; InvNextStep: Integer; var RemainingQtyToReserve: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAutoReserveItemLedgEntryOnFindNextItemLedgEntry(CalcReservEntry: Record "Reservation Entry"; var CalcItemLedgEntry: Record "Item Ledger Entry"; var InvSearch: Text[1]; var IsHandled: Boolean; var IsFound: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSourceForSalesLine(var CalcReservEntry: Record "Reservation Entry"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserve(var CalcReservEntry: Record "Reservation Entry"; var FullAutoReservation: Boolean; var Description: Text[100]; var AvailabilityDate: Date; var MaxQtyToReserve: Decimal; var MaxQtyToReserveBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeAutoReserveItemLedgEntry(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; var IsReserved: Boolean; CalcReservEntry: Record "Reservation Entry"; var CalcItemLedgerEntry: Record "Item Ledger Entry"; var ItemTrackingCode: Record "Item Tracking Code"; Positive: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReservePurchLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; var IsReserved: Boolean; var Search: Text[1]; var NextStep: Integer; CalcReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserveSalesLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; var IsReserved: Boolean; Search: Text[1]; NextStep: Integer; CalcReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserveProdOrderLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; var IsReserved: Boolean; Search: Text[1]; NextStep: Integer; CalcReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserveProdOrderComp(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; var IsReserved: Boolean; Search: Text[1]; NextStep: Integer; CalcReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserveAssemblyHeader(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; var IsReserved: Boolean; Search: Text[1]; NextStep: Integer; CalcReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserveAssemblyLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; var IsReserved: Boolean; Search: Text[1]; NextStep: Integer; CalcReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserveTransLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; var IsReserved: Boolean; var Search: Text[1]; var NextStep: Integer; CalcReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserveServLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; var IsReserved: Boolean; Search: Text[1]; NextStep: Integer; CalcReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserveJobPlanningLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date; var IsReserved: Boolean; Search: Text[1]; NextStep: Integer; CalcReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcAvailAllocQuantities(
        Item: Record Item; WhseActivLine: Record "Warehouse Activity Line";
        QtyOnOutboundBins: Decimal; QtyOnInvtMovement: Decimal; QtyOnSpecialBins: Decimal;
        var AvailQty: Decimal; var AllocQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateReservation(var TrkgSpec: Record "Tracking Specification"; var ReservEntry: Record "Reservation Entry"; var ItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeDeleteItemTrackingConfirm(var CalcReservEntry2: Record "Reservation Entry"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteReservEntries(var ReservationEntry: Record "Reservation Entry"; var DownToQuantity: Decimal; CalcReservEntry: Record "Reservation Entry"; var CalcReservEntry2: Record "Reservation Entry"; var IsHandled: Boolean; var ItemTrackingHandling: Option "None","Allow deletion",Match)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindUnfinishedSpecialOrderSalesNo(ItemLedgerEntry: Record "Item Ledger Entry"; var Result: Code[20]; var IsHandled: Boolean)
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
    local procedure OnBeforeUpdateReservation(var SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; var IsHandled: Boolean)
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
    local procedure OnClearSurplusOnAfterReservEntry2SetFilters(var ReservationEntry: Record "Reservation Entry"; ItemTrackingHandling: Option "None","Allow deletion",Match)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnClearSurplusOnBeforeReservEntry2FindSet(var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateReservation(SourceRecRef: RecordRef; TrackingSpecification: Record "Tracking Specification"; ForReservEntry: Record "Reservation Entry"; Description: Text[100]; ExpectedDate: Date; Quantity: Decimal; QuantityBase: Decimal);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDocumentReservationDeleteQstOnElseCase(RecRef: RecordRef; FldRef: FieldRef; DocType: Integer; var DocTypeCaption: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteReservEntriesOnAfterReservEntrySetFilters(var ReservEntry: Record "Reservation Entry"; var ItemTrackingHandling: Option "None","Allow deletion",Match)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteDocumentReservationOnAfterReservEntry2Modify(var ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSourceRecordValue(var ReservEntry: Record "Reservation Entry"; SetAsCurrent: Boolean; ReturnOption: Option "Net Qty. (Base)","Gross Qty. (Base)"; var ReturnQty: Decimal; var SourceRecRef: RecordRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFilterReservFor(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; Direction: Integer; var CaptionText: Text);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertReservationEntriesOnBeforeCreateReservation(var TrackingSpecification: Record "Tracking Specification"; var CalcReservEntry: Record "Reservation Entry")
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

    [IntegrationEvent(true, false)]
    local procedure OnSetReservSource(SourceRecRef: RecordRef; var ReservEntry: Record "Reservation Entry"; Direction: Enum "Transfer Direction")
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
    local procedure OnUpdateItemLedgEntryStatsOnBeforePrepareTempEntrySummary(CalcReservationEntry: Record "Reservation Entry"; var TempEntrySummary: Record "Entry Summary")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateItemLedgEntryStatsUpdateTotals(CalcReservEntry: Record "Reservation Entry"; var CalcItemLedgEntry: Record "Item Ledger Entry"; TotalAvailQty: Decimal; QtyOnOutBound: Decimal; var CalcSumValue: Decimal; var TempEntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateItemTrackingLineStatsOnBeforeReservEntrySummaryInsert(var ReservEntrySummary: Record "Entry Summary"; ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateItemTrackingLineStatsOnAfterReservEntrySetFilters(var ReservEntry: Record "Reservation Entry"; CalcReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateStatistics(CalcReservEntry: Record "Reservation Entry"; var ReservSummEntry: Record "Entry Summary"; AvailabilityDate: Date; Positive: Boolean; var TotalQuantity: Decimal; HandleItemTracking2: Boolean; var QtyOnOutBound: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcReservedQtyOnPick(var Item: Record Item; var WhseActivLine: Record "Warehouse Activity Line"; var CalcReservEntry: Record "Reservation Entry"; var AvailQty: Decimal; var AllocQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCallCalcReservedQtyOnPick(CalcReservEntry: Record "Reservation Entry"; Positive: Boolean; var ShouldCalsReservedQtyOnPick: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckQuantityIsCompletelyReleased(ItemTrackingHandling: Option "None","Allow deletion",Match; QtyToRelease: Decimal; DeleteAll: Boolean; CurrentItemTrackingSetup: Record "Item Tracking Setup"; ReservEntry: Record "Reservation Entry"; var IsHandled: boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReservedQuantityAssign(ReservationEntry: Record "Reservation Entry"; var ReservedQuantity: Decimal; SignFactor: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteReservEntriesOnBeforeDeleteReservEntries(CalcReservEntry: Record "Reservation Entry"; var CalcReservEntry2: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteReservEntriesOnReservationOnAfterCalcReservEntry4Get(var CalcReservEntry4: Record "Reservation Entry"; var ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAutoReservePurchLineOnBeforeSetQtyToReserveDownToTrackedQuantity(PurchLine: Record "Purchase Line"; CalcReservEntry: Record "Reservation Entry"; var ReservQty: Decimal; var QtyThisLine: Decimal; var QtyThisLineBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteReservEntriesOnBeforeReservEntryTestField(var ReservEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFinishedAutoReserveOneLine(ReservSummEntryNo: Integer; var RemainingQtyToReserve: Decimal; var RemainingQtyToReserveBase: Decimal; Description: Text[100]; AvailabilityDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteReservEntriesOnAfterItemTrackingHandling(var ReservationEntry: Record "Reservation Entry"; var ItemTrackingHandling: Option "None","Allow deletion",Match)
    begin
    end;
}

