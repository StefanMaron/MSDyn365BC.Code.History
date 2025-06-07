// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.Document;
using Microsoft.Warehouse.Worksheet;
using Microsoft.Manufacturing.Setup;

codeunit 99000891 "Mfg. Item Tracking Mgt."
{
    var
        ItemTrackingLines: Page "Item Tracking Lines";
        ItemTrackingManagement: Codeunit "Item Tracking Management";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Management", 'OnGetItemTrackingSetupOnSetSerialNoRequired', '', false, false)]
    local procedure OnGetItemTrackingSetupOnSetSerialNoRequired(var ItemTrackingSetup: Record "Item Tracking Setup"; ItemTrackingCode: Record "Item Tracking Code"; EntryType: Enum "Item Ledger Entry Type"; Inbound: Boolean)
    begin
        case EntryType of
            EntryType::Consumption, EntryType::Output:
                if Inbound then
                    ItemTrackingSetup."Serial No. Required" := ItemTrackingCode."SN Manuf. Inbound Tracking"
                else
                    ItemTrackingSetup."Serial No. Required" := ItemTrackingCode."SN Manuf. Outbound Tracking";
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Management", 'OnGetItemTrackingSetupOnSetLotNoRequired', '', false, false)]
    local procedure OnGetItemTrackingSetupOnSetLotNoRequired(var ItemTrackingSetup: Record "Item Tracking Setup"; ItemTrackingCode: Record "Item Tracking Code"; EntryType: Enum "Item Ledger Entry Type"; Inbound: Boolean)
    begin
        case EntryType of
            EntryType::Consumption, EntryType::Output:
                if Inbound then
                    ItemTrackingSetup."Lot No. Required" := ItemTrackingCode."Lot Manuf. Inbound Tracking"
                else
                    ItemTrackingSetup."Lot No. Required" := ItemTrackingCode."Lot Manuf. Outbound Tracking";
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Management", 'OnGetItemTrackingSetupOnSetPackageNoRequired', '', false, false)]
    local procedure OnGetItemTrackingSetupOnSetPackageNoRequired(var ItemTrackingSetup: Record "Item Tracking Setup"; ItemTrackingCode: Record "Item Tracking Code"; EntryType: Enum "Item Ledger Entry Type"; Inbound: Boolean)
    begin
        case EntryType of
            EntryType::Consumption, EntryType::Output:
                if Inbound then
                    ItemTrackingSetup."Package No. Required" := ItemTrackingCode."Package Manuf. Inb. Tracking"
                else
                    ItemTrackingSetup."Package No. Required" := ItemTrackingCode."Package Manuf. Outb. Tracking";
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Management", 'OnAfterInitWhseWorksheetLine', '', false, false)]
    local procedure OnAfterInitWhseWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WhseDocType: Enum "Warehouse Worksheet Document Type"; SourceSubtype: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer)
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if WhseDocType <> Enum::"Warehouse Worksheet Document Type"::Production then
            exit;

        case WhseWorksheetLine."Source Type" of
            Database::"Prod. Order Line":
                begin
                    ProdOrderLine.SetLoadFields("Qty. Put Away (Base)");
                    ProdOrderLine.Get(SourceSubtype, SourceNo, SourceLineNo);
                    WhseWorksheetLine."Qty. Handled (Base)" := ProdOrderLine."Qty. Put Away (Base)";
                end;
            else begin
                ProdOrderComponent.SetLoadFields("Qty. Picked (Base)");
                ProdOrderComponent.Get(SourceSubtype, SourceNo, SourceLineNo, SourceSublineNo);
                WhseWorksheetLine."Qty. Handled (Base)" := ProdOrderComponent."Qty. Picked (Base)";
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Management", 'OnBeforeRetrieveItemTrackingFromReservEntry', '', false, false)]
    local procedure OnBeforeRetrieveItemTrackingFromReservEntry(ItemJnlLine: Record "Item Journal Line"; var ReservEntry: Record "Reservation Entry"; var Result: Boolean; var IsHandled: Boolean; var TempTrackingSpec: Record "Tracking Specification" temporary)
    begin
        if ItemJnlLine.Subcontracting then begin
            Result := RetrieveSubcontrItemTracking(ItemJnlLine, TempTrackingSpec);
            IsHandled := true;
        end;
    end;

    procedure RetrieveConsumpItemTracking(ItemJnlLine: Record "Item Journal Line"; var TempHandlingSpecification: Record "Tracking Specification" temporary): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ItemJnlLine.TestField("Order Type", ItemJnlLine."Order Type"::Production);
        ReservEntry.SetSourceFilter(
          Database::"Prod. Order Component", 3, ItemJnlLine."Order No.", ItemJnlLine."Prod. Order Comp. Line No.", true);
        ReservEntry.SetSourceFilter('', ItemJnlLine."Order Line No.");
        ReservEntry.SetFilter("Qty. to Handle (Base)", '<>0');
        ReservEntry.SetTrackingFilterFromItemJnlLine(ItemJnlLine);
        OnRetrieveConsumpItemTrackingOnAfterSetFilters(ReservEntry, ItemJnlLine);
#if not CLEAN26
        ItemTrackingManagement.RunOnRetrieveConsumpItemTrackingOnAfterSetFilters(ReservEntry, ItemJnlLine);
#endif

        // Sum up in a temporary table per component line:
        exit(ItemTrackingManagement.SumUpItemTracking(ReservEntry, TempHandlingSpecification, true, true));
    end;

    local procedure RetrieveSubcontrItemTracking(ItemJnlLine: Record "Item Journal Line"; var TempHandlingSpecification: Record "Tracking Specification" temporary) Result: Boolean
    var
        ReservEntry: Record "Reservation Entry";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        IsLastOperation: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRetrieveSubcontrItemTracking(ItemJnlLine, TempHandlingSpecification, Result, IsHandled);
#if not CLEAN26
        ItemTrackingManagement.RunOnBeforeRetrieveSubcontrItemTracking(ItemJnlLine, TempHandlingSpecification, Result, IsHandled);
#endif
        if IsHandled then
            exit(Result);

        if not ItemJnlLine.Subcontracting then
            exit(false);

        if ItemJnlLine."Operation No." = '' then
            exit(false);

        ItemJnlLine.TestField("Routing No.");
        ItemJnlLine.TestField("Order Type", ItemJnlLine."Order Type"::Production);
        if not ProdOrderRoutingLine.Get(
             ProdOrderRoutingLine.Status::Released, ItemJnlLine."Order No.",
             ItemJnlLine."Routing Reference No.", ItemJnlLine."Routing No.", ItemJnlLine."Operation No.")
        then
            exit(false);

        IsLastOperation := ProdOrderRoutingLine."Next Operation No." = '';
        OnRetrieveSubcontrItemTrackingOnBeforeCheckLastOperation(ProdOrderRoutingLine, IsLastOperation);
#if not CLEAN26
        ItemTrackingManagement.RunOnRetrieveSubcontrItemTrackingOnBeforeCheckLastOperation(ProdOrderRoutingLine, IsLastOperation);
#endif
        if not IsLastOperation then
            exit(false);

        ReservEntry.SetSourceFilter(Database::"Prod. Order Line", 3, ItemJnlLine."Order No.", 0, true);
        ReservEntry.SetSourceFilter('', ItemJnlLine."Order Line No.");
        ReservEntry.SetFilter("Qty. to Handle (Base)", '<>0');
        if ItemTrackingManagement.SumUpItemTracking(ReservEntry, TempHandlingSpecification, false, true) then begin
            ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Prospect);
            if not ReservEntry.IsEmpty() then
                ReservEntry.DeleteAll();
            OnRetrieveSubcontrItemTrackingOnAfterDeleteReservEntries(TempHandlingSpecification, ReservEntry);
#if not CLEAN26
            ItemTrackingManagement.RunOnRetrieveSubcontrItemTrackingOnAfterDeleteReservEntries(TempHandlingSpecification, ReservEntry);
#endif
            exit(true);
        end;
        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveConsumpItemTrackingOnAfterSetFilters(var ReservationEntry: Record "Reservation Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRetrieveSubcontrItemTracking(ItemJnlLine: Record "Item Journal Line"; var TempHandlingSpecification: Record "Tracking Specification" temporary; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveSubcontrItemTrackingOnBeforeCheckLastOperation(ProdOrderRoutingLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line"; var IsLastOperation: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveSubcontrItemTrackingOnAfterDeleteReservEntries(var TempHandlingSpecification: Record "Tracking Specification" temporary; var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    // Item Tracking Code

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Code", 'OnValidateSNSpecificTrackingOnAfterSet', '', false, false)]
    local procedure OnValidateSNSpecificTrackingOnAfterSet(var ItemTrackingCode: Record "Item Tracking Code")
    begin
        ItemTrackingCode."SN Manuf. Inbound Tracking" := true;
        ItemTrackingCode."SN Manuf. Outbound Tracking" := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Code", 'OnValidateLotSpecificTrackingOnAfterSet', '', false, false)]
    local procedure OnValidateLotSpecificTrackingOnAfterSet(var ItemTrackingCode: Record "Item Tracking Code")
    begin
        ItemTrackingCode."Lot Manuf. Inbound Tracking" := true;
        ItemTrackingCode."Lot Manuf. Outbound Tracking" := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Code", 'OnValidatePackageSpecificTrackingOnAfterSet', '', false, false)]
    local procedure OnValidatePackageSpecificTrackingOnAfterSet(var ItemTrackingCode: Record "Item Tracking Code")
    begin
        ItemTrackingCode."Package Manuf. Inb. Tracking" := true;
        ItemTrackingCode."Package Manuf. Outb. Tracking" := true;
    end;

    // Report Carry Out Reservation
    [EventSubscriber(ObjectType::Report, Report::"Carry Out Reservation", 'OnCarryOutReservationOtherDemandType', '', false, false)]
    local procedure OnCarryOutReservationOtherDemandType(var ReservationWkshLine: Record "Reservation Wksh. Line"; DemandType: Enum "Reservation Demand Type")
    begin
        case DemandType of
            DemandType::"Production Components":
                ReservationWkshLine.SetRange("Source Type", Database::"Prod. Order Component");
        end;
    end;


    [EventSubscriber(ObjectType::Table, Database::"Action Message Entry", 'OnAfterSumUp', '', false, false)]
    local procedure OnAfterSumUp(var ActionMessageEntry: Record "Action Message Entry"; var ComponentBinding: Boolean; var FirstDate: Date; var FirstTime: Time)
    var
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        ProdOrderComp: Record "Prod. Order Component";
    begin
        ComponentBinding := false;
        if ActionMessageEntry."Source Type" = Database::"Prod. Order Line" then begin
            FirstDate := DMY2Date(31, 12, 9999);
            ActionMessageEntry.FilterToReservEntry(ReservEntry);
            ReservEntry.SetRange(Binding, ReservEntry.Binding::"Order-to-Order");
            if ReservEntry.FindSet() then
                repeat
                    if ReservEntry2.Get(ReservEntry."Entry No.", false) then
                        if (ReservEntry2."Source Type" = Database::"Prod. Order Component") and
                           (ReservEntry2."Source Subtype" = ReservEntry."Source Subtype") and
                           (ReservEntry2."Source ID" = ReservEntry."Source ID")
                        then
                            if ProdOrderComp.Get(
                                 ReservEntry2."Source Subtype", ReservEntry2."Source ID",
                                 ReservEntry2."Source Prod. Order Line", ReservEntry2."Source Ref. No.")
                            then begin
                                ComponentBinding := true;
                                if ProdOrderComp."Due Date" < FirstDate then begin
                                    FirstDate := ProdOrderComp."Due Date";
                                    FirstTime := ProdOrderComp."Due Time";
                                end;
                            end;
                until ReservEntry.Next() = 0;
        end;
    end;

    // Codeunit "Item Tracing Mgt."

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracing Mgt.", 'OnInsertRecordOnBeforeSetDescription', '', false, false)]
    local procedure OnInsertRecordOnBeforeSetDescription(var TempTrackEntry: Record "Item Tracing Buffer"; var RecRef: RecordRef; var Description2: Text[100])
    var
        ProductionOrder: Record "Production Order";
    begin
        if RecRef.Get(TempTrackEntry."Record Identifier") then
            case RecRef.Number of
                Database::"Production Order":
                    begin
                        RecRef.SetTable(ProductionOrder);
                        Description2 :=
                            StrSubstNo('%1 %2 %3 %4', ProductionOrder.Status, RecRef.Caption, TempTrackEntry."Entry Type", TempTrackEntry."Document No.");
                    end;
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracing Mgt.", 'OnAfterSetRecordID', '', false, false)]
    local procedure OnAfterSetRecordID(var TrackingEntry: Record "Item Tracing Buffer"; RecRef: RecordRef)
    var
        ProductionOrder: Record "Production Order";
    begin
        case TrackingEntry."Entry Type" of
            TrackingEntry."Entry Type"::Consumption,
            TrackingEntry."Entry Type"::Output:
                begin
                    ProductionOrder.SetFilter(Status, '>=%1', ProductionOrder.Status::Released);
                    ProductionOrder.SetRange("No.", TrackingEntry."Document No.");
                    if ProductionOrder.FindFirst() then begin
                        RecRef.GetTable(ProductionOrder);
                        TrackingEntry."Record Identifier" := RecRef.RecordId;
                    end;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracing Mgt.", 'OnShowDocument', '', false, false)]
    local procedure OnShowDocument(RecRef: RecordRef; RecID: RecordId)
    var
        ProductionOrder: Record "Production Order";
    begin
        case RecID.TableNo of
            Database::"Production Order":
                begin
                    RecRef.SetTable(ProductionOrder);
                    if ProductionOrder.Status = ProductionOrder.Status::Released then
                        PAGE.RunModal(PAGE::"Released Production Order", ProductionOrder)
                    else
                        if ProductionOrder.Status = ProductionOrder.Status::Finished then
                            PAGE.RunModal(PAGE::"Finished Production Order", ProductionOrder);
                end;
        end;
    end;

    // Codeunit Reservation Engine Mgt.

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Engine Mgt.", 'OnModifyActionMessageDatingOnGetDampenerPeriod', '', false, false)]
    local procedure OnModifyActionMessageDatingOnGetDampenerPeriod(ReservEntry: Record "Reservation Entry"; var DampenerPeriod: Dateformula)
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        if (Format(ManufacturingSetup."Default Dampener Period") = '') or
           ((ReservEntry.Binding = ReservEntry.Binding::"Order-to-Order") and
            (ReservEntry."Reservation Status" = ReservEntry."Reservation Status"::Reservation))
        then
            Evaluate(ManufacturingSetup."Default Dampener Period", '<0D>');
        DampenerPeriod := ManufacturingSetup."Default Dampener Period";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Engine Mgt.", 'OnAfterShouldModifyActionMessageDating', '', false, false)]
    local procedure OnAfterShouldModifyActionMessageDating(ReservationEntry: Record "Reservation Entry"; var Result: Boolean)
    begin
        Result := Result or (ReservationEntry."Source Type" = Database::"Prod. Order Line");
    end;

    // Page Item Tracking Lines

    [EventSubscriber(ObjectType::Page, Page::"Item Tracking Lines", 'OnSetSourceSpecOnCollectTrackingData', '', false, false)]
    local procedure OnSetSourceSpecOnCollectTrackingData(var TrackingSpecification: Record "Tracking Specification"; var TempTrackingSpecification: Record "Tracking Specification" temporary; ExcludePostedEntries: Boolean; CurrentSignFactor: Integer; var SourceQuantity: Decimal)
    begin
        if TrackingSpecification."Source Type" = Database::"Prod. Order Line" then
            if TrackingSpecification."Source Subtype" = 3 then
                CollectPostedOutputEntries(TrackingSpecification, TempTrackingSpecification, SourceQuantity);
    end;

    local procedure CollectPostedOutputEntries(TrackingSpecification: Record "Tracking Specification"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var SourceQuantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Used for collecting information about posted prod. order output from the created Item Ledger Entries.
        if TrackingSpecification."Source Type" <> Database::"Prod. Order Line" then
            exit;

        ItemLedgerEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type");
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.SetRange("Order No.", TrackingSpecification."Source ID");
        ItemLedgerEntry.SetRange("Order Line No.", TrackingSpecification."Source Prod. Order Line");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);

        if ItemLedgerEntry.Find('-') then begin
            repeat
                TempTrackingSpecification := TrackingSpecification;
                TempTrackingSpecification."Entry No." := ItemLedgerEntry."Entry No.";
                TempTrackingSpecification."Item No." := ItemLedgerEntry."Item No.";
                TempTrackingSpecification.CopyTrackingFromItemLedgEntry(ItemLedgerEntry);
                TempTrackingSpecification."Quantity (Base)" := ItemLedgerEntry.Quantity;
                TempTrackingSpecification."Quantity Handled (Base)" := ItemLedgerEntry.Quantity;
                TempTrackingSpecification."Quantity Invoiced (Base)" := ItemLedgerEntry.Quantity;
                TempTrackingSpecification."Qty. per Unit of Measure" := ItemLedgerEntry."Qty. per Unit of Measure";
                TempTrackingSpecification.InitQtyToShip();
                ItemTrackingLines.RunOnBeforeCollectTempTrackingSpecificationInsert(TempTrackingSpecification, ItemLedgerEntry, TrackingSpecification);
                TempTrackingSpecification.Insert();
            until ItemLedgerEntry.Next() = 0;

            ItemLedgerEntry.CalcSums(Quantity);
            if ItemLedgerEntry.Quantity > SourceQuantity then
                SourceQuantity := ItemLedgerEntry.Quantity;
        end;

        OnAfterCollectPostedOutputEntries(ItemLedgerEntry, TempTrackingSpecification);
#if not CLEAN26
        ItemTrackingLines.RunOnAfterCollectPostedOutputEntries(ItemLedgerEntry, TempTrackingSpecification);
#endif
    end;

    [EventSubscriber(ObjectType::Page, Page::"Item Tracking Lines", 'OnCheckItemTrackingLineIsBoundForBarcodeScanning', '', false, false)]
    local procedure OnCheckItemTrackingLineIsBoundForBarcodeScanning(var TrackingSpecification: Record "Tracking Specification"; var Result: Boolean; IsHandled: Boolean)
    begin
        if TrackingSpecification."Source Type" = Database::"Prod. Order Line" then begin
            Result := not (TrackingSpecification."Qty. to Handle (Base)" < 0);
            IsHandled := true;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCollectPostedOutputEntries(ItemLedgerEntry: Record "Item Ledger Entry"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", OnCheckIsSNSpecificTracking, '', false, false)]
    local procedure OnCheckIsSNSpecificTracking(ItemTrackingCode: Record "Item Tracking Code"; var SNSepecificTracking: Boolean)
    begin
        if SNSepecificTracking then
            exit;

        SNSepecificTracking := ItemTrackingCode."SN Manuf. Inbound Tracking" or ItemTrackingCode."SN Manuf. Outbound Tracking";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Inventory Profile Offsetting", OnCheckIsLotSpecificTracking, '', false, false)]
    local procedure OnCheckIsLotSpecificTracking(ItemTrackingCode: Record "Item Tracking Code"; var LotSepecificTracking: Boolean)
    begin
        if LotSepecificTracking then
            exit;

        LotSepecificTracking := ItemTrackingCode."Lot Manuf. Inbound Tracking" or ItemTrackingCode."Lot Manuf. Outbound Tracking";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Management", OnRegisterNewItemTrackingLinesOnBeforeCannotMatchItemTrackingError, '', false, false)]
    local procedure OnRegisterNewItemTrackingLinesOnBeforeCannotMatchItemTrackingError(var TempTrackingSpecification: Record "Tracking Specification" temporary; var QtyToHandleToNewRegister: Decimal; var QtyToHandleInItemTracking: Decimal; var QtyToHandleOnSourceDocLine: Decimal; var IsHandled: Boolean; var AllowWhseOverpick: Boolean)
    var
        Item: Record Item;
    begin
        if (TempTrackingSpecification."Source Type" <> Database::"Prod. Order Component") or (TempTrackingSpecification."Source Subtype" <> TempTrackingSpecification."Source Subtype"::"3") then
            exit;

        Item.SetLoadFields("Allow Whse. Overpick");
        Item.Get(TempTrackingSpecification."Item No.");
        AllowWhseOverpick := Item."Allow Whse. Overpick";
    end;
}
