namespace Microsoft.Inventory.Requisition;

using Microsoft.Assembly.Document;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Setup;
using System.Text;

codeunit 99000813 "Carry Out Action"
{
    Permissions = TableData "Prod. Order Capacity Need" = rid;
    TableNo = "Requisition Line";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        OnBeforeRun(Rec);
        ProductionExist := true;
        AssemblyExist := true;
        case TrySourceType of
            TrySourceType::Purchase:
                CarryOutToReqWksh(Rec, TryWkshTempl, TryWkshName);
            TrySourceType::Transfer:
                CarryOutActionsFromTransOrder(Rec, Enum::"Planning Create Transfer Order".FromInteger(TryChoice), TryWkshTempl, TryWkshName);
            TrySourceType::Production:
                begin
                    IsHandled := false;
                    OnRunOnBeforeCalcProductionExist(Rec, TryChoice, TryWkshTempl, TryWkshName, ProductionExist, IsHandled);
                    if not IsHandled then
                        ProductionExist := CarryOutActionsFromProdOrder(Rec, Enum::"Planning Create Prod. Order".FromInteger(TryChoice), TryWkshTempl, TryWkshName);
                end;
            TrySourceType::Assembly:
                AssemblyExist := CarryOutActionsFromAssemblyOrder(Rec, Enum::"Planning Create Assembly Order".FromInteger(TryChoice));
        end;

        if Rec."Action Message" = Rec."Action Message"::Cancel then
            Rec.Delete(true);

        ReservationEntry.SetCurrentKey(
          "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
          "Source Batch Name", "Source Prod. Order Line");
        Rec.SetReservationFilters(ReservationEntry);
        ReservationEntry.DeleteAll(true);

        if not (Rec."Action Message" = Rec."Action Message"::Cancel) then begin
            Rec.BlockDynamicTracking(true);
            if TrySourceType = TrySourceType::Production then
                Rec.BlockDynamicTrackingOnComp(true);
            if ProductionExist and AssemblyExist then
                DeleteRequisitionLine(Rec);
            Rec.BlockDynamicTracking(false);
        end;
    end;

    var
        TempProductionOrder: Record "Production Order" temporary;
        LastTransferHeader: Record "Transfer Header";
        TempTransferHeaderToPrint: Record "Transfer Header" temporary;
        ReservationEntry: Record "Reservation Entry";
        TempDocumentEntry: Record "Document Entry" temporary;
        TempAssemblyHeaderToPrint: Record "Assembly Header" temporary;
        CarryOutAction: Codeunit "Carry Out Action";
        CalculateProdOrder: Codeunit "Calculate Prod. Order";
        ReservationManagement: Codeunit "Reservation Management";
        ReqLineReserve: Codeunit "Req. Line-Reserve";
        PlngComponentReserve: Codeunit "Plng. Component-Reserve";
        ReservationCheckDateConfl: Codeunit "Reservation-Check Date Confl.";
        PrintOrder: Boolean;
        SplitTransferOrders: Boolean;
        UseTransferNo: Code[20];
        ProductionExist: Boolean;
        AssemblyExist: Boolean;
        TrySourceType: Enum "Planning Create Source Type";
        TryChoice: Option;
        TryWkshTempl: Code[10];
        TryWkshName: Code[10];
        LineNo: Integer;
        CouldNotChangeSupplyTxt: Label 'The supply type could not be changed in order %1, order line %2.', Comment = '%1 - Production Order No. or Assembly Header No. or Purchase Header No., %2 - Production Order Line or Assembly Line No. or Purchase Line No.';

    procedure TryCarryOutAction(SourceType: Enum "Planning Create Source Type"; var RequisitionLine: Record "Requisition Line"; Choice: Option; WkshTempl: Code[10]; WkshName: Code[10]): Boolean
    begin
        CarryOutAction.SetSplitTransferOrders(SplitTransferOrders);
        CarryOutAction.SetParameters(SourceType, Choice, WkshTempl, WkshName);
        exit(CarryOutAction.Run(RequisitionLine));
    end;

    procedure SetParameters(SourceType: Enum "Planning Create Source Type"; Choice: Integer; WkshTempl: Code[10]; WkshName: Code[10])
    begin
        TrySourceType := SourceType;
        TryChoice := Choice;
        TryWkshTempl := WkshTempl;
        TryWkshName := WkshName;
    end;

    procedure CarryOutActionsFromProdOrder(RequisitionLine: Record "Requisition Line"; ProdOrderChoice: Enum "Planning Create Prod. Order"; ProdWkshTempl: Code[10]; ProdWkshName: Code[10]): Boolean
    begin
        PrintOrder := ProdOrderChoice = ProdOrderChoice::"Firm Planned & Print";
        OnCarryOutActionsFromProdOrderOnAfterCalcPrintOrder(PrintOrder, ProdOrderChoice.AsInteger());

        case RequisitionLine."Action Message" of
            RequisitionLine."Action Message"::New:
                if ProdOrderChoice = ProdOrderChoice::"Copy to Req. Wksh" then
                    CarryOutToReqWksh(RequisitionLine, ProdWkshTempl, ProdWkshName)
                else
                    InsertProductionOrder(RequisitionLine, ProdOrderChoice);
            RequisitionLine."Action Message"::"Change Qty.",
          RequisitionLine."Action Message"::Reschedule,
          RequisitionLine."Action Message"::"Resched. & Chg. Qty.":
                exit(ProdOrderChgAndReshedule(RequisitionLine));
            RequisitionLine."Action Message"::Cancel:
                DeleteOrderLines(RequisitionLine);
        end;
        exit(true);
    end;

    procedure CarryOutActionsFromTransOrder(RequisitionLine: Record "Requisition Line"; TransOrderChoice: Enum "Planning Create Transfer Order"; TransWkshTempName: Code[10];
                                                                                                              TransJournalName: Code[10])
    var
        IsHandled: Boolean;
    begin
        OnBeforeCarryOutTransOrder(SplitTransferOrders);

        PrintOrder := TransOrderChoice = TransOrderChoice::"Make Trans. Order & Print";

        if SplitTransferOrders then
            Clear(LastTransferHeader);

        if TransOrderChoice = TransOrderChoice::"Copy to Req. Wksh" then
            CarryOutToReqWksh(RequisitionLine, TransWkshTempName, TransJournalName)
        else
            case RequisitionLine."Action Message" of
                RequisitionLine."Action Message"::New:
                    begin
                        IsHandled := false;
                        OnCarryOutActionsFromTransOrderOnBeforeInsertTransLine(RequisitionLine, PrintOrder, IsHandled);
                        if not IsHandled then
                            InsertTransLine(RequisitionLine, LastTransferHeader);
                    end;
                RequisitionLine."Action Message"::"Change Qty.",
              RequisitionLine."Action Message"::Reschedule,
              RequisitionLine."Action Message"::"Resched. & Chg. Qty.":
                    begin
                        IsHandled := false;
                        OnCarryOutActionsFromTransOrderOnBeforeTransOrderChgAndReshedule(RequisitionLine, PrintOrder, IsHandled);
                        if not IsHandled then
                            TransOrderChgAndReshedule(RequisitionLine);
                    end;
                RequisitionLine."Action Message"::Cancel:
                    DeleteOrderLines(RequisitionLine);
            end;
    end;

    procedure CarryOutActionsFromAssemblyOrder(RequisitionLine: Record "Requisition Line"; AsmOrderChoice: Enum "Planning Create Assembly Order"): Boolean
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        PrintOrder := AsmOrderChoice = AsmOrderChoice::"Make Assembly Orders & Print";
        case RequisitionLine."Action Message" of
            RequisitionLine."Action Message"::New:
                InsertAsmHeader(RequisitionLine, AssemblyHeader);
            RequisitionLine."Action Message"::"Change Qty.",
          RequisitionLine."Action Message"::Reschedule,
          RequisitionLine."Action Message"::"Resched. & Chg. Qty.":
                exit(AsmOrderChgAndReshedule(RequisitionLine));
            RequisitionLine."Action Message"::Cancel:
                DeleteOrderLines(RequisitionLine);
        end;
        exit(true);
    end;

    procedure CarryOutToReqWksh(RequisitionLine: Record "Requisition Line"; ReqWkshTempName: Code[10]; ReqJournalName: Code[10])
    var
        RequisitionLine2: Record "Requisition Line";
        PlanningComponent: Record "Planning Component";
        PlanningRoutingLine: Record "Planning Routing Line";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        PlanningComponent2: Record "Planning Component";
        PlanningRoutingLine2: Record "Planning Routing Line";
        ProdOrderCapacityNeed2: Record "Prod. Order Capacity Need";
        RequisitionLine3: Record "Requisition Line";
    begin
        RequisitionLine2 := RequisitionLine;
        RequisitionLine2."Worksheet Template Name" := ReqWkshTempName;
        RequisitionLine2."Journal Batch Name" := ReqJournalName;

        if LineNo = 0 then begin
            // we need to find the last line in worksheet
            RequisitionLine3.SetCurrentKey("Worksheet Template Name", "Journal Batch Name", "Line No.");
            RequisitionLine3.SetRange("Worksheet Template Name", ReqWkshTempName);
            RequisitionLine3.SetRange("Journal Batch Name", ReqJournalName);
            if RequisitionLine3.FindLast() then
                LineNo := RequisitionLine3."Line No.";
        end;
        LineNo += 10000;
        RequisitionLine2."Line No." := LineNo;

        if RequisitionLine2."Planning Line Origin" = RequisitionLine2."Planning Line Origin"::"Order Planning" then begin
            RequisitionLine2."Planning Line Origin" := RequisitionLine2."Planning Line Origin"::" ";
            RequisitionLine2.Level := 0;
            RequisitionLine2.Status := 0;
            RequisitionLine2.Reserve := false;
            RequisitionLine2."Demand Type" := 0;
            RequisitionLine2."Demand Subtype" := 0;
            RequisitionLine2."Demand Order No." := '';
            RequisitionLine2."Demand Line No." := 0;
            RequisitionLine2."Demand Ref. No." := 0;
            RequisitionLine2."Demand Date" := 0D;
            RequisitionLine2."Demand Quantity" := 0;
            RequisitionLine2."Demand Quantity (Base)" := 0;
            RequisitionLine2."Needed Quantity" := 0;
            RequisitionLine2."Needed Quantity (Base)" := 0;
            RequisitionLine2."Qty. per UOM (Demand)" := 0;
            RequisitionLine2."Unit Of Measure Code (Demand)" := '';
        end;
        OnCarryOutToReqWkshOnBeforeReqLineInsert(RequisitionLine2, ReqWkshTempName, ReqJournalName, LineNo);
        RequisitionLine2.Insert();

        ReqLineReserve.TransferReqLineToReqLine(RequisitionLine, RequisitionLine2, 0, true);
        if RequisitionLine.Reserve then
            ReserveBindingOrderToReqline(RequisitionLine2, RequisitionLine);

        PlanningComponent.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningComponent.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        PlanningComponent.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        if PlanningComponent.Find('-') then
            repeat
                PlanningComponent2 := PlanningComponent;
                PlanningComponent2."Worksheet Template Name" := ReqWkshTempName;
                PlanningComponent2."Worksheet Batch Name" := ReqJournalName;
                PlanningComponent2."Worksheet Line No." := LineNo;
                if PlanningComponent2."Planning Line Origin" = PlanningComponent2."Planning Line Origin"::"Order Planning" then
                    PlanningComponent2."Planning Line Origin" := PlanningComponent2."Planning Line Origin"::" ";
                PlanningComponent2."Dimension Set ID" := RequisitionLine2."Dimension Set ID";
                PlanningComponent2.Insert();
                OnCarryOutToReqWkshOnAfterPlanningCompInsert(PlanningComponent2, PlanningComponent);
            until PlanningComponent.Next() = 0;

        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        if PlanningRoutingLine.Find('-') then
            repeat
                PlanningRoutingLine2 := PlanningRoutingLine;
                PlanningRoutingLine2."Worksheet Template Name" := ReqWkshTempName;
                PlanningRoutingLine2."Worksheet Batch Name" := ReqJournalName;
                PlanningRoutingLine2."Worksheet Line No." := LineNo;
                OnCarryOutToReqWkshOnAfterPlanningRoutingLineInsert(PlanningRoutingLine2, PlanningRoutingLine);
                PlanningRoutingLine2.Insert();
            until PlanningRoutingLine.Next() = 0;

        ProdOrderCapacityNeed.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        ProdOrderCapacityNeed.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        ProdOrderCapacityNeed.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        if ProdOrderCapacityNeed.Find('-') then
            repeat
                ProdOrderCapacityNeed2 := ProdOrderCapacityNeed;
                ProdOrderCapacityNeed2."Worksheet Template Name" := ReqWkshTempName;
                ProdOrderCapacityNeed2."Worksheet Batch Name" := ReqJournalName;
                ProdOrderCapacityNeed2."Worksheet Line No." := LineNo;
                ProdOrderCapacityNeed.Delete();
                ProdOrderCapacityNeed2.Insert();
            until ProdOrderCapacityNeed.Next() = 0;

        OnAfterCarryOutToReqWksh(RequisitionLine2, RequisitionLine);
    end;

    procedure GetTransferOrdersToPrint(var TransferHeader: Record "Transfer Header")
    begin
        if TempTransferHeaderToPrint.FindSet() then
            repeat
                TransferHeader := TempTransferHeaderToPrint;
                TransferHeader.Insert();
            until TempTransferHeaderToPrint.Next() = 0;
    end;

    procedure ProdOrderChgAndReshedule(RequisitionLine: Record "Requisition Line"): Boolean
    var
        ProdOrderLine: Record "Prod. Order Line";
        PlanningComponent: Record "Planning Component";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
    begin
        RequisitionLine.TestField(RequisitionLine."Ref. Order Type", RequisitionLine."Ref. Order Type"::"Prod. Order");
        ProdOrderLine.LockTable();
        if ProdOrderLine.Get(RequisitionLine."Ref. Order Status", RequisitionLine."Ref. Order No.", RequisitionLine."Ref. Line No.") then begin
            ProdOrderCapacityNeed.SetCurrentKey("Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.");
            ProdOrderCapacityNeed.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
            ProdOrderCapacityNeed.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
            ProdOrderCapacityNeed.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
            ProdOrderCapacityNeed.DeleteAll();
            ProdOrderLine.BlockDynamicTracking(true);
            ProdOrderLine.Validate(Quantity, RequisitionLine.Quantity);
            OnProdOrderChgAndResheduleOnAfterValidateQuantity(ProdOrderLine, RequisitionLine);
            ProdOrderLine."Ending Time" := RequisitionLine."Ending Time";
            ProdOrderLine.Validate("Planning Flexibility", RequisitionLine."Planning Flexibility");
            ProdOrderLine.Validate("Ending Date", RequisitionLine."Ending Date");
            ProdOrderLine."Due Date" := RequisitionLine."Due Date";
            ProdOrderLine.Modify();
            ReqLineReserve.TransferPlanningLineToPOLine(RequisitionLine, ProdOrderLine, 0, true);
            ReqLineReserve.UpdateDerivedTracking(RequisitionLine);
            ReservationManagement.SetReservSource(ProdOrderLine);
            ReservationManagement.DeleteReservEntries(false, ProdOrderLine."Remaining Qty. (Base)");
            ReservationManagement.ClearSurplus();
            ReservationManagement.AutoTrack(ProdOrderLine."Remaining Qty. (Base)");
            PlanningComponent.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
            PlanningComponent.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
            PlanningComponent.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
            if PlanningComponent.Find('-') then
                repeat
                    if ProdOrderComponent.Get(
                            ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.", PlanningComponent."Line No.")
                    then begin
                        PlngComponentReserve.TransferPlanningCompToPOComp(PlanningComponent, ProdOrderComponent, 0, true);
                        PlngComponentReserve.UpdateDerivedTracking(PlanningComponent);
                        ReservationManagement.SetReservSource(ProdOrderComponent);
                        ReservationManagement.DeleteReservEntries(false, ProdOrderComponent."Remaining Qty. (Base)");
                        ReservationManagement.ClearSurplus();
                        ReservationManagement.AutoTrack(ProdOrderComponent."Remaining Qty. (Base)");
                        ReservationCheckDateConfl.ProdOrderComponentCheck(ProdOrderComponent, false, false);
                    end else
                        PlanningComponent.Delete(true);
                until PlanningComponent.Next() = 0;

            if RequisitionLine."Planning Level" = 0 then
                if ProductionOrder.Get(RequisitionLine."Ref. Order Status", RequisitionLine."Ref. Order No.") then begin
                    ProductionOrder.Quantity := RequisitionLine.Quantity;
                    ProductionOrder."Starting Time" := RequisitionLine."Starting Time";
                    ProductionOrder."Starting Date" := RequisitionLine."Starting Date";
                    ProductionOrder."Ending Time" := RequisitionLine."Ending Time";
                    ProductionOrder."Ending Date" := RequisitionLine."Ending Date";
                    ProductionOrder."Due Date" := RequisitionLine."Due Date";
                    OnProdOrderChgAndResheduleOnBeforeProdOrderModify(ProductionOrder, ProdOrderLine, RequisitionLine);
                    ProductionOrder.Modify();
                    FinalizeOrderHeader(ProductionOrder);
                end;
            OnAfterProdOrderChgAndReshedule(RequisitionLine, ProdOrderLine);
        end else begin
            Message(StrSubstNo(CouldNotChangeSupplyTxt, RequisitionLine."Ref. Order No.", RequisitionLine."Ref. Line No."));
            exit(false);
        end;
        exit(true);
    end;

    procedure PurchOrderChgAndReshedule(RequisitionLine: Record "Requisition Line")
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        RequisitionLine.TestField("Ref. Order Type", RequisitionLine."Ref. Order Type"::Purchase);
        if PurchaseLine.Get(PurchaseLine."Document Type"::Order, RequisitionLine."Ref. Order No.", RequisitionLine."Ref. Line No.") then begin
            OnPurchOrderChgAndResheduleOnAfterGetPurchLine(PurchaseLine);
            PurchaseLine.BlockDynamicTracking(true);
            PurchaseLine.Validate(Quantity, RequisitionLine.Quantity);
            OnPurchOrderChgAndResheduleOnBeforeValidateExpectedReceiptDate(RequisitionLine);
            PurchaseLine.Validate("Expected Receipt Date", RequisitionLine."Due Date");
            PurchaseLine.Validate("Planning Flexibility", RequisitionLine."Planning Flexibility");
            OnPurchOrderChgAndResheduleOnBeforePurchLineModify(RequisitionLine, PurchaseLine);
            PurchaseLine.Modify(true);
            ReqLineReserve.TransferReqLineToPurchLine(RequisitionLine, PurchaseLine, 0, true);
            ReqLineReserve.UpdateDerivedTracking(RequisitionLine);
            ReservationManagement.SetReservSource(PurchaseLine);
            ReservationManagement.DeleteReservEntries(false, PurchaseLine."Outstanding Qty. (Base)");
            ReservationManagement.ClearSurplus();
            ReservationManagement.AutoTrack(PurchaseLine."Outstanding Qty. (Base)");

            PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
            OnPurchOrderChgAndResheduleOnAfterGetPurchHeader(PurchaseHeader, PurchaseLine, RequisitionLine);
            PrintPurchaseOrder(PurchaseHeader);
        end else
            Error(CouldNotChangeSupplyTxt, RequisitionLine."Ref. Order No.", RequisitionLine."Ref. Line No.");
    end;

    procedure TransOrderChgAndReshedule(RequisitionLine: Record "Requisition Line")
    var
        TransferLine: Record "Transfer Line";
        TransferHeader: Record "Transfer Header";
    begin
        RequisitionLine.TestField("Ref. Order Type", RequisitionLine."Ref. Order Type"::Transfer);

        if TransferLine.Get(RequisitionLine."Ref. Order No.", RequisitionLine."Ref. Line No.") then begin
            TransferLine.BlockDynamicTracking(true);
            TransferLine.Validate(Quantity, RequisitionLine.Quantity);
            TransferLine.Validate("Receipt Date", RequisitionLine."Due Date");
            TransferLine."Shipment Date" := RequisitionLine."Transfer Shipment Date";
            TransferLine.Validate("Planning Flexibility", RequisitionLine."Planning Flexibility");
            OnTransOrderChgAndResheduleOnBeforeTransLineModify(RequisitionLine, TransferLine);
            TransferLine.Modify(true);
            ReqLineReserve.TransferReqLineToTransLine(RequisitionLine, TransferLine, 0, true);
            ReqLineReserve.UpdateDerivedTracking(RequisitionLine);
            ReservationManagement.SetReservSource(TransferLine, Enum::"Transfer Direction"::Outbound);
            ReservationManagement.DeleteReservEntries(false, TransferLine."Outstanding Qty. (Base)");
            ReservationManagement.ClearSurplus();
            ReservationManagement.AutoTrack(TransferLine."Outstanding Qty. (Base)");
            ReservationManagement.SetReservSource(TransferLine, Enum::"Transfer Direction"::Inbound);
            ReservationManagement.DeleteReservEntries(false, TransferLine."Outstanding Qty. (Base)");
            ReservationManagement.ClearSurplus();
            ReservationManagement.AutoTrack(TransferLine."Outstanding Qty. (Base)");
            TransferHeader.Get(TransferLine."Document No.");
            PrintTransferOrder(TransferHeader);
        end;
    end;

    procedure AsmOrderChgAndReshedule(RequisitionLine: Record "Requisition Line"): Boolean
    var
        AssemblyHeader: Record "Assembly Header";
        PlanningComponent: Record "Planning Component";
        AssemblyLine: Record "Assembly Line";
    begin
        RequisitionLine.TestField("Ref. Order Type", RequisitionLine."Ref. Order Type"::Assembly);
        AssemblyHeader.LockTable();
        if AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, RequisitionLine."Ref. Order No.") then begin
            AssemblyHeader.SetWarningsOff();
            AssemblyHeader.Validate(Quantity, RequisitionLine.Quantity);
            AssemblyHeader.Validate("Planning Flexibility", RequisitionLine."Planning Flexibility");
            AssemblyHeader.Validate("Due Date", RequisitionLine."Due Date");
            OnAsmOrderChgAndResheduleOnBeforeAsmHeaderModify(RequisitionLine, AssemblyHeader);
            AssemblyHeader.Modify(true);
            ReqLineReserve.TransferPlanningLineToAsmHdr(RequisitionLine, AssemblyHeader, 0, true);
            ReqLineReserve.UpdateDerivedTracking(RequisitionLine);
            ReservationManagement.SetReservSource(AssemblyHeader);
            ReservationManagement.DeleteReservEntries(false, AssemblyHeader."Remaining Quantity (Base)");
            ReservationManagement.ClearSurplus();
            ReservationManagement.AutoTrack(AssemblyHeader."Remaining Quantity (Base)");

            PlanningComponent.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
            PlanningComponent.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
            PlanningComponent.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
            if PlanningComponent.Find('-') then
                repeat
                    if AssemblyLine.Get(AssemblyHeader."Document Type", AssemblyHeader."No.", PlanningComponent."Line No.") then begin
                        PlngComponentReserve.TransferPlanningCompToAsmLine(PlanningComponent, AssemblyLine, 0, true);
                        PlngComponentReserve.UpdateDerivedTracking(PlanningComponent);
                        ReservationManagement.SetReservSource(AssemblyLine);
                        ReservationManagement.DeleteReservEntries(false, AssemblyLine."Remaining Quantity (Base)");
                        ReservationManagement.ClearSurplus();
                        ReservationManagement.AutoTrack(AssemblyLine."Remaining Quantity (Base)");
                        ReservationCheckDateConfl.AssemblyLineCheck(AssemblyLine, false);
                    end else
                        PlanningComponent.Delete(true);
                until PlanningComponent.Next() = 0;

            CollectAsmOrderForPrinting(AssemblyHeader);
        end else begin
            Message(StrSubstNo(CouldNotChangeSupplyTxt, RequisitionLine."Ref. Order No.", RequisitionLine."Ref. Line No."));
            exit(false);
        end;
        exit(true);
    end;

    procedure DeleteOrderLines(RequisitionLine: Record "Requisition Line")
    begin
        OnBeforeDeleteOrderLines(RequisitionLine);

        case RequisitionLine."Ref. Order Type" of
            RequisitionLine."Ref. Order Type"::"Prod. Order":
                DeleteProdOrderLines(RequisitionLine);
            RequisitionLine."Ref. Order Type"::Purchase:
                DeletePurchaseOrderLines(RequisitionLine);
            RequisitionLine."Ref. Order Type"::Transfer:
                DeleteTransferOrderLines(RequisitionLine);
            RequisitionLine."Ref. Order Type"::Assembly:
                DeleteAssemblyOrderLines(RequisitionLine);
        end;

        OnAfterDeleteOrderLines(RequisitionLine);
    end;

    local procedure DeleteProdOrderLines(RequisitionLine: Record "Requisition Line")
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteProdOrderLines(RequisitionLine, IsHandled);
        if IsHandled then
            exit;

        ProdOrderLine.SetCurrentKey(Status, "Prod. Order No.", "Line No.");
        ProdOrderLine.SetFilter("Item No.", '<>%1', '');
        ProdOrderLine.SetRange(Status, RequisitionLine."Ref. Order Status");
        ProdOrderLine.SetRange("Prod. Order No.", RequisitionLine."Ref. Order No.");
        if ProdOrderLine.Count in [0, 1] then begin
            if ProductionOrder.Get(RequisitionLine."Ref. Order Status", RequisitionLine."Ref. Order No.") then
                ProductionOrder.Delete(true);
        end else begin
            ProdOrderLine.SetRange("Line No.", RequisitionLine."Ref. Line No.");
            if ProdOrderLine.FindFirst() then
                ProdOrderLine.Delete(true);
        end;
    end;

    local procedure DeletePurchaseOrderLines(RequisitionLine: Record "Requisition Line")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeletePurchaseLines(RequisitionLine, IsHandled);
        if IsHandled then
            exit;

        PurchaseLine.SetCurrentKey("Document Type", "Document No.", "Line No.");
        PurchaseLine.SetFilter(Type, '<>%1', PurchaseLine.Type::" ");
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", RequisitionLine."Ref. Order No.");
        if PurchaseLine.Count in [0, 1] then begin
            if PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, RequisitionLine."Ref. Order No.") then
                PurchaseHeader.Delete(true);
        end else begin
            PurchaseLine.SetRange("Line No.", RequisitionLine."Ref. Line No.");
            if PurchaseLine.FindFirst() then
                PurchaseLine.Delete(true);
        end;
    end;

    local procedure DeleteTransferOrderLines(RequisitionLine: Record "Requisition Line")
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteTransferLines(RequisitionLine, IsHandled);
        if IsHandled then
            exit;

        TransferLine.SetCurrentKey("Document No.", "Line No.");
        TransferLine.SetRange("Document No.", RequisitionLine."Ref. Order No.");
        if TransferLine.Count in [0, 1] then begin
            if TransferHeader.Get(RequisitionLine."Ref. Order No.") then
                TransferHeader.Delete(true);
        end else begin
            TransferLine.SetRange("Line No.", RequisitionLine."Ref. Line No.");
            if TransferLine.FindFirst() then
                TransferLine.Delete(true);
        end;
    end;

    local procedure DeleteAssemblyOrderLines(RequisitionLine: Record "Requisition Line")
    var
        AssemblyHeader: Record "Assembly Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteAssemblyLines(RequisitionLine, IsHandled);
        if IsHandled then
            exit;

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, RequisitionLine."Ref. Order No.");
        AssemblyHeader.Delete(true);
    end;

    local procedure DeleteRequisitionLine(var RequisitionLine: Record "Requisition Line")
    begin
        OnBeforeDeleteRequisitionLine(RequisitionLine);
        RequisitionLine.Delete(true);
        OnAfterDeleteRequisitionLine(RequisitionLine);
    end;

    procedure InsertProductionOrder(RequisitionLine: Record "Requisition Line"; ProdOrderChoice: Enum "Planning Create Prod. Order")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        HeaderExist: Boolean;
        IsHandled: Boolean;
    begin
        Item.Get(RequisitionLine."No.");
        ManufacturingSetup.Get();
        if FindTempProdOrder(RequisitionLine) then
            HeaderExist := ProductionOrder.Get(TempProductionOrder.Status, TempProductionOrder."No.");

        OnInsertProdOrderOnAfterFindTempProdOrder(RequisitionLine, ProductionOrder, HeaderExist, Item);

        if not HeaderExist then begin
            case ProdOrderChoice of
                ProdOrderChoice::Planned:
                    ManufacturingSetup.TestField("Planned Order Nos.");
                ProdOrderChoice::"Firm Planned",
                ProdOrderChoice::"Firm Planned & Print":
                    ManufacturingSetup.TestField("Firm Planned Order Nos.");
                else
                    OnInsertProductionOrderOnProdOrderChoiceCaseElse(ProdOrderChoice);
            end;

            OnInsertProdOrderOnBeforeProdOrderInit(RequisitionLine);
            ProductionOrder.Init();
            if ProdOrderChoice = ProdOrderChoice::"Firm Planned & Print" then
                ProductionOrder.Status := ProductionOrder.Status::"Firm Planned"
            else begin
                IsHandled := false;
                OnInsertProdOrderOnProdOrderChoiceNotFirmPlannedPrint(ProductionOrder, ProdOrderChoice, IsHandled);
                if not IsHandled then
                    ProductionOrder.Status := Enum::"Production Order Status".FromInteger(ProdOrderChoice.AsInteger());
            end;
            ProductionOrder."No. Series" := ProductionOrder.GetNoSeriesCode();
            if ProductionOrder."No. Series" = RequisitionLine."No. Series" then
                ProductionOrder."No." := RequisitionLine."Ref. Order No.";
            OnInsertProdOrderOnBeforeProdOrderInsert(ProductionOrder, RequisitionLine);
            ProductionOrder.Insert(true);
            OnInsertProdOrderOnAfterProdOrderInsert(ProductionOrder, RequisitionLine);
            ProductionOrder."Source Type" := ProductionOrder."Source Type"::Item;
            ProductionOrder."Source No." := RequisitionLine."No.";
            ProductionOrder.Validate(Description, RequisitionLine.Description);
            ProductionOrder."Description 2" := RequisitionLine."Description 2";
            ProductionOrder."Variant Code" := RequisitionLine."Variant Code";
            ProductionOrder."Creation Date" := Today;
            ProductionOrder."Last Date Modified" := Today;
            ProductionOrder."Inventory Posting Group" := Item."Inventory Posting Group";
            ProductionOrder."Gen. Prod. Posting Group" := RequisitionLine."Gen. Prod. Posting Group";
            ProductionOrder."Due Date" := RequisitionLine."Due Date";
            ProductionOrder."Starting Time" := RequisitionLine."Starting Time";
            ProductionOrder."Starting Date" := RequisitionLine."Starting Date";
            ProductionOrder."Ending Time" := RequisitionLine."Ending Time";
            ProductionOrder."Ending Date" := RequisitionLine."Ending Date";
            ProductionOrder."Location Code" := RequisitionLine."Location Code";
            ProductionOrder."Bin Code" := RequisitionLine."Bin Code";
            ProductionOrder."Low-Level Code" := RequisitionLine."Low-Level Code";
            ProductionOrder."Routing No." := RequisitionLine."Routing No.";
            ProductionOrder.Quantity := RequisitionLine.Quantity;
            ProductionOrder."Unit Cost" := RequisitionLine."Unit Cost";
            ProductionOrder."Cost Amount" := RequisitionLine."Cost Amount";
            ProductionOrder."Shortcut Dimension 1 Code" := RequisitionLine."Shortcut Dimension 1 Code";
            ProductionOrder."Shortcut Dimension 2 Code" := RequisitionLine."Shortcut Dimension 2 Code";
            ProductionOrder."Dimension Set ID" := RequisitionLine."Dimension Set ID";
            ProductionOrder.UpdateDatetime();
            OnInsertProdOrderWithReqLine(ProductionOrder, RequisitionLine);
            ProductionOrder.Modify();
            InsertTempProdOrder(RequisitionLine, ProductionOrder);
        end;
        InsertProdOrderLine(RequisitionLine, ProductionOrder, Item);

        OnAfterInsertProdOrder(ProductionOrder, ProdOrderChoice.AsInteger(), RequisitionLine);
    end;

    procedure InsertProdOrderLine(RequisitionLine: Record "Requisition Line"; ProductionOrder: Record "Production Order"; Item: Record Item)
    var
        ProdOrderLine: Record "Prod. Order Line";
        NextLineNo: Integer;
    begin
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.LockTable();
        if ProdOrderLine.FindLast() then
            NextLineNo := ProdOrderLine."Line No." + 10000
        else
            NextLineNo := 10000;

        OnInsertProdOrderLineOnBeforeProdOrderLineInit(RequisitionLine, Item);
        ProdOrderLine.Init();
        ProdOrderLine.BlockDynamicTracking(true);
        ProdOrderLine.Status := ProductionOrder.Status;
        ProdOrderLine."Prod. Order No." := ProductionOrder."No.";
        ProdOrderLine."Line No." := NextLineNo;
        ProdOrderLine."Item No." := RequisitionLine."No.";
        ProdOrderLine.Validate("Unit of Measure Code", RequisitionLine."Unit of Measure Code");
        ProdOrderLine."Production BOM Version Code" := RequisitionLine."Production BOM Version Code";
        ProdOrderLine."Routing Version Code" := RequisitionLine."Routing Version Code";
        ProdOrderLine."Routing Type" := RequisitionLine."Routing Type";
        ProdOrderLine."Routing Reference No." := ProdOrderLine."Line No.";
        ProdOrderLine.Description := RequisitionLine.Description;
        ProdOrderLine."Description 2" := RequisitionLine."Description 2";
        ProdOrderLine."Variant Code" := RequisitionLine."Variant Code";
        ProdOrderLine."Location Code" := RequisitionLine."Location Code";
        OnInsertProdOrderLineOnBeforeGetBinCode(ProdOrderLine, RequisitionLine);
        if RequisitionLine."Bin Code" <> '' then
            ProdOrderLine.Validate("Bin Code", RequisitionLine."Bin Code")
        else
            CalculateProdOrder.SetProdOrderLineBinCodeFromRoute(ProdOrderLine, ProductionOrder."Location Code", ProductionOrder."Routing No.");
        ProdOrderLine."Scrap %" := RequisitionLine."Scrap %";
        ProdOrderLine."Production BOM No." := RequisitionLine."Production BOM No.";
        ProdOrderLine."Inventory Posting Group" := Item."Inventory Posting Group";
        OnInsertProdOrderLineOnBeforeValidateUnitCost(RequisitionLine, ProductionOrder, ProdOrderLine, Item);
        ProdOrderLine.Validate("Unit Cost", RequisitionLine."Unit Cost");
        ProdOrderLine."Routing No." := RequisitionLine."Routing No.";
        ProdOrderLine."Starting Time" := RequisitionLine."Starting Time";
        ProdOrderLine."Starting Date" := RequisitionLine."Starting Date";
        ProdOrderLine."Ending Time" := RequisitionLine."Ending Time";
        ProdOrderLine."Ending Date" := RequisitionLine."Ending Date";
        ProdOrderLine."Due Date" := RequisitionLine."Due Date";
        ProdOrderLine.Status := ProductionOrder.Status;
        ProdOrderLine."Planning Level Code" := RequisitionLine."Planning Level";
        ProdOrderLine."Indirect Cost %" := RequisitionLine."Indirect Cost %";
        ProdOrderLine."Overhead Rate" := RequisitionLine."Overhead Rate";
        UpdateProdOrderLineQuantity(ProdOrderLine, RequisitionLine, Item);
        if not (ProductionOrder.Status = ProductionOrder.Status::Planned) then
            ProdOrderLine."Planning Flexibility" := RequisitionLine."Planning Flexibility";
        ProdOrderLine.UpdateDatetime();
        ProdOrderLine."Shortcut Dimension 1 Code" := RequisitionLine."Shortcut Dimension 1 Code";
        ProdOrderLine."Shortcut Dimension 2 Code" := RequisitionLine."Shortcut Dimension 2 Code";
        ProdOrderLine."Dimension Set ID" := RequisitionLine."Dimension Set ID";
        OnInsertProdOrderLineWithReqLine(ProdOrderLine, RequisitionLine);
        ProdOrderLine.Insert();
        OnInsertProdOrderLineOnAfterProdOrderLineInsert(ProdOrderLine, RequisitionLine);
        CalculateProdOrder.CalculateProdOrderDates(ProdOrderLine, false);

        ReqLineReserve.TransferPlanningLineToPOLine(RequisitionLine, ProdOrderLine, RequisitionLine."Net Quantity (Base)", false);
        if RequisitionLine.Reserve and not (ProdOrderLine.Status = ProdOrderLine.Status::Planned) then
            ReserveBindingOrderToProd(ProdOrderLine, RequisitionLine);

        OnInsertProdOrderLineOnBeforeModifyProdOrderLine(ProdOrderLine, RequisitionLine);
        ProdOrderLine.Modify();
        SetProdOrderLineBinCodeFromPlanningRtngLines(ProductionOrder, ProdOrderLine, RequisitionLine, Item);
        TransferBOM(RequisitionLine, ProductionOrder, ProdOrderLine."Line No.");
        TransferCapNeed(RequisitionLine, ProductionOrder, ProdOrderLine."Routing No.", ProdOrderLine."Routing Reference No.");

        if ProdOrderLine."Planning Level Code" > 0 then
            UpdateComponentLink(ProdOrderLine);

        OnAfterInsertProdOrderLine(RequisitionLine, ProductionOrder, ProdOrderLine, Item);

        FinalizeOrderHeader(ProductionOrder);
    end;

    local procedure SetProdOrderLineBinCodeFromPlanningRtngLines(ProductionOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; RequisitionLine: Record "Requisition Line"; Item: Record Item)
    var
        RefreshProdOrderLine: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetProdOrderLineBinCodeFromPlanningRtngLines(ProductionOrder, ProdOrderLine, RequisitionLine, Item, IsHandled);
        if IsHandled then
            exit;

        if TransferRouting(RequisitionLine, ProductionOrder, ProdOrderLine."Routing No.", ProdOrderLine."Routing Reference No.") then begin
            RefreshProdOrderLine := false;
            OnInsertProdOrderLineOnAfterTransferRouting(ProdOrderLine, RefreshProdOrderLine);
            if RefreshProdOrderLine then
                ProdOrderLine.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
            CalculateProdOrder.SetProdOrderLineBinCodeFromPlanningRtngLines(ProdOrderLine, RequisitionLine);
            ProdOrderLine.Modify();
        end;
    end;

    local procedure UpdateProdOrderLineQuantity(var ProdOrderLine: Record "Prod. Order Line"; RequisitionLine: Record "Requisition Line"; Item: Record Item)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateProdOrderLineQuantity(ProdOrderLine, RequisitionLine, Item, IsHandled);
        if IsHandled then
            exit;

        ProdOrderLine.Validate(Quantity, RequisitionLine.Quantity);
    end;

    [Scope('OnPrem')]
    procedure InsertAsmHeader(RequisitionLine: Record "Requisition Line"; var AssemblyHeader: Record "Assembly Header")
    var
        Item: Record Item;
    begin
        Item.Get(RequisitionLine."No.");
        AssemblyHeader.Init();
        AssemblyHeader."Document Type" := AssemblyHeader."Document Type"::Order;
        OnInsertAsmHeaderOnBeforeAsmHeaderInsert(AssemblyHeader, RequisitionLine);
        AssemblyHeader.Insert(true);
        OnInsertAsmHeaderOnAfterAsmHeaderInsert(AssemblyHeader, RequisitionLine);
        AssemblyHeader.SetWarningsOff();
        AssemblyHeader.Validate("Item No.", RequisitionLine."No.");
        AssemblyHeader.Validate("Unit of Measure Code", RequisitionLine."Unit of Measure Code");
        AssemblyHeader.Description := RequisitionLine.Description;
        AssemblyHeader."Description 2" := RequisitionLine."Description 2";
        AssemblyHeader."Variant Code" := RequisitionLine."Variant Code";
        AssemblyHeader."Location Code" := RequisitionLine."Location Code";
        AssemblyHeader."Inventory Posting Group" := Item."Inventory Posting Group";
        AssemblyHeader.Validate("Unit Cost", RequisitionLine."Unit Cost");
        AssemblyHeader."Due Date" := RequisitionLine."Due Date";
        AssemblyHeader."Starting Date" := RequisitionLine."Starting Date";
        AssemblyHeader."Ending Date" := RequisitionLine."Ending Date";

        AssemblyHeader.Quantity := RequisitionLine.Quantity;
        AssemblyHeader."Quantity (Base)" := RequisitionLine."Quantity (Base)";
        AssemblyHeader.InitRemainingQty();
        AssemblyHeader.InitQtyToAssemble();
        if RequisitionLine."Bin Code" <> '' then
            AssemblyHeader."Bin Code" := RequisitionLine."Bin Code"
        else
            AssemblyHeader.GetDefaultBin();

        AssemblyHeader."Planning Flexibility" := RequisitionLine."Planning Flexibility";
        AssemblyHeader."Shortcut Dimension 1 Code" := RequisitionLine."Shortcut Dimension 1 Code";
        AssemblyHeader."Shortcut Dimension 2 Code" := RequisitionLine."Shortcut Dimension 2 Code";
        AssemblyHeader."Dimension Set ID" := RequisitionLine."Dimension Set ID";
        ReqLineReserve.TransferPlanningLineToAsmHdr(RequisitionLine, AssemblyHeader, RequisitionLine."Net Quantity (Base)", false);
        if RequisitionLine.Reserve then
            ReserveBindingOrderToAsm(AssemblyHeader, RequisitionLine);
        AssemblyHeader.Modify();

        TransferAsmPlanningComp(RequisitionLine, AssemblyHeader);

        AddResourceComponents(RequisitionLine, AssemblyHeader);

        OnAfterInsertAsmHeader(RequisitionLine, AssemblyHeader);

        CollectAsmOrderForPrinting(AssemblyHeader);

        TempDocumentEntry.Init();
        TempDocumentEntry."Table ID" := Database::"Assembly Header";
        TempDocumentEntry."Document Type" := AssemblyHeader."Document Type"::Order;
        TempDocumentEntry."Document No." := AssemblyHeader."No.";
        TempDocumentEntry."Entry No." := TempDocumentEntry.Count + 1;
        TempDocumentEntry.Insert();
    end;

    local procedure CollectAsmOrderForPrinting(var AssemblyHeader: Record "Assembly Header")
    begin
        if PrintOrder then begin
            TempAssemblyHeaderToPrint.Init();
            TempAssemblyHeaderToPrint."Document Type" := AssemblyHeader."Document Type";
            TempAssemblyHeaderToPrint."No." := AssemblyHeader."No.";
            TempAssemblyHeaderToPrint."Item No." := AssemblyHeader."Item No.";
            TempAssemblyHeaderToPrint.Insert(false);
        end;
    end;

    local procedure AddResourceComponents(RequisitionLine: Record "Requisition Line"; var AssemblyHeader: Record "Assembly Header")
    var
        BOMComponent: Record "BOM Component";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAddResourceComponents(RequisitionLine, AssemblyHeader, IsHandled);
        if IsHandled then
            exit;

        BOMComponent.SetRange("Parent Item No.", RequisitionLine."No.");
        BOMComponent.SetRange(Type, BOMComponent.Type::Resource);
        if BOMComponent.Find('-') then
            repeat
                AssemblyHeader.AddBOMLine(BOMComponent);
            until BOMComponent.Next() = 0;
    end;

    procedure TransferAsmPlanningComp(RequisitionLine: Record "Requisition Line"; AssemblyHeader: Record "Assembly Header")
    var
        AssemblyLine: Record "Assembly Line";
        PlanningComponent: Record "Planning Component";
    begin
        PlanningComponent.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningComponent.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        PlanningComponent.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        if PlanningComponent.Find('-') then
            repeat
                AssemblyLine.Init();
                AssemblyLine."Document Type" := AssemblyHeader."Document Type";
                AssemblyLine."Document No." := AssemblyHeader."No.";
                AssemblyLine."Line No." := PlanningComponent."Line No.";
                AssemblyLine.Type := AssemblyLine.Type::Item;
                AssemblyLine."Dimension Set ID" := PlanningComponent."Dimension Set ID";
                AssemblyLine.Validate("No.", PlanningComponent."Item No.");
                AssemblyLine.Description := PlanningComponent.Description;
                AssemblyLine."Unit of Measure Code" := PlanningComponent."Unit of Measure Code";
                AssemblyLine."Qty. Rounding Precision" := PlanningComponent."Qty. Rounding Precision";
                AssemblyLine."Qty. Rounding Precision (Base)" := PlanningComponent."Qty. Rounding Precision (Base)";
                AssemblyLine."Lead-Time Offset" := PlanningComponent."Lead-Time Offset";
                AssemblyLine.Position := PlanningComponent.Position;
                AssemblyLine."Position 2" := PlanningComponent."Position 2";
                AssemblyLine."Position 3" := PlanningComponent."Position 3";
                AssemblyLine."Variant Code" := PlanningComponent."Variant Code";
                AssemblyLine."Location Code" := PlanningComponent."Location Code";

                AssemblyLine."Quantity per" := PlanningComponent."Quantity per";
                AssemblyLine."Qty. per Unit of Measure" := PlanningComponent."Qty. per Unit of Measure";
                AssemblyLine.Quantity := PlanningComponent."Expected Quantity";
                AssemblyLine."Quantity (Base)" := PlanningComponent."Expected Quantity (Base)";
                AssemblyLine.InitRemainingQty();
                AssemblyLine.InitQtyToConsume();
                if PlanningComponent."Bin Code" <> '' then
                    AssemblyLine."Bin Code" := PlanningComponent."Bin Code"
                else
                    AssemblyLine.GetDefaultBin();

                AssemblyLine."Due Date" := PlanningComponent."Due Date";
                AssemblyLine."Unit Cost" := PlanningComponent."Unit Cost";
                AssemblyLine."Variant Code" := PlanningComponent."Variant Code";
                AssemblyLine."Cost Amount" := PlanningComponent."Cost Amount";

                AssemblyLine."Shortcut Dimension 1 Code" := PlanningComponent."Shortcut Dimension 1 Code";
                AssemblyLine."Shortcut Dimension 2 Code" := PlanningComponent."Shortcut Dimension 2 Code";

                OnAfterTransferAsmPlanningComp(PlanningComponent, AssemblyLine);

                AssemblyLine.Insert();

                PlngComponentReserve.TransferPlanningCompToAsmLine(PlanningComponent, AssemblyLine, 0, true);
                AssemblyLine.AutoReserve();
                ReservationManagement.SetReservSource(AssemblyLine);
                ReservationManagement.AutoTrack(AssemblyLine."Remaining Quantity (Base)");
            until PlanningComponent.Next() = 0;
    end;

    procedure InsertTransHeader(RequisitionLine: Record "Requisition Line"; var TransferHeader: Record "Transfer Header")
    var
        InventorySetup: Record "Inventory Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertTransHeader(RequisitionLine, TransferHeader, IsHandled);
        if IsHandled then
            exit;

        InventorySetup.Get();
        InventorySetup.TestField("Transfer Order Nos.");

        TransferHeader.Init();
        TransferHeader."No." := '';
        TransferHeader."Posting Date" := WorkDate();
        OnInsertTransHeaderOnBeforeTransHeaderInsert(TransferHeader, RequisitionLine);
        TransferHeader.Insert(true);
        OnInsertTransHeaderOnAfterTransHeaderInsert(TransferHeader, RequisitionLine);
        TransferHeader.Validate("Transfer-from Code", RequisitionLine."Transfer-from Code");
        TransferHeader.Validate("Transfer-to Code", RequisitionLine."Location Code");
        TransferHeader."Receipt Date" := RequisitionLine."Due Date";
        TransferHeader."Shipment Date" := RequisitionLine."Transfer Shipment Date";
        OnInsertTransHeaderOnBeforeTransHeaderModify(TransferHeader, RequisitionLine);
        TransferHeader.Modify();
        TempDocumentEntry.Init();
        TempDocumentEntry."Table ID" := Database::"Transfer Header";
        TempDocumentEntry."Document No." := TransferHeader."No.";
        TempDocumentEntry."Entry No." := TempDocumentEntry.Count + 1;
        TempDocumentEntry.Insert();

        UseTransferNo := TransferHeader."No.";
        if PrintOrder then begin
            TempTransferHeaderToPrint."No." := TransferHeader."No.";
            TempTransferHeaderToPrint.Insert();
        end;
    end;

    procedure InsertTransHeaderWithNo(ReqLine: Record "Requisition Line"; TransOrderChoice: Option " ","Make Trans. Orders","Make Trans. Orders & Print","Copy to Req. Wksh"; var TransferHeader: Record "Transfer Header")
    begin
        InsertTransHeader(ReqLine, TransferHeader);
        TransferHeader.Get(UseTransferNo);
    end;

    procedure InsertTransLine(RequisitionLine: Record "Requisition Line"; var TransferHeader: Record "Transfer Header")
    var
        TransferLine: Record "Transfer Line";
        NextLineNo: Integer;
        ShouldInsertTransHeader: Boolean;
    begin
        ShouldInsertTransHeader := (RequisitionLine."Transfer-from Code" <> TransferHeader."Transfer-from Code") or
           (RequisitionLine."Location Code" <> TransferHeader."Transfer-to Code");
        OnInsertTransLineOnAfterCalcShouldInsertTransHeader(RequisitionLine, TransferHeader, ShouldInsertTransHeader);
        if ShouldInsertTransHeader then
            InsertTransHeader(RequisitionLine, TransferHeader);

        TransferLine.SetRange("Document No.", TransferHeader."No.");
        if TransferLine.FindLast() then
            NextLineNo := TransferLine."Line No." + 10000
        else
            NextLineNo := 10000;

        TransferLine.Init();
        OnInsertTransLineOnAfterTransLineInit(TransferLine, RequisitionLine);
        TransferLine.BlockDynamicTracking(true);
        TransferLine."Document No." := TransferHeader."No.";
        TransferLine."Line No." := NextLineNo;
        TransferLine.Validate("Item No.", RequisitionLine."No.");
        TransferLine.Description := RequisitionLine.Description;
        TransferLine."Description 2" := RequisitionLine."Description 2";
        TransferLine.Validate("Variant Code", RequisitionLine."Variant Code");
        TransferLine.Validate("Transfer-from Code", RequisitionLine."Transfer-from Code");
        TransferLine.Validate("Transfer-to Code", RequisitionLine."Location Code");
        TransferLine.Validate(Quantity, RequisitionLine.Quantity);
        TransferLine.Validate("Unit of Measure Code", RequisitionLine."Unit of Measure Code");
        CopyDimensionsFromReqToTransLine(TransferLine, RequisitionLine);
        TransferLine."Receipt Date" := RequisitionLine."Due Date";
        TransferLine."Shipment Date" := RequisitionLine."Transfer Shipment Date";
        TransferLine.Validate("Planning Flexibility", RequisitionLine."Planning Flexibility");
        OnInsertTransLineWithReqLine(TransferLine, RequisitionLine, NextLineNo);
        TransferLine.Insert();
        OnAfterTransLineInsert(TransferLine, RequisitionLine);

        ReqLineReserve.TransferReqLineToTransLine(RequisitionLine, TransferLine, RequisitionLine."Quantity (Base)", false);
        if RequisitionLine.Reserve then
            ReserveBindingOrderToTrans(TransferLine, RequisitionLine);

        OnAfterInsertTransLine(TransferHeader, RequisitionLine, TransferLine, NextLineNo);
    end;

    local procedure CopyDimensionsFromReqToTransLine(var TransferLine: Record "Transfer Line"; RequisitionLine: Record "Requisition Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyDimensionsFromReqToTransLine(TransferLine, RequisitionLine, IsHandled);
        if IsHandled then
            exit;

        TransferLine."Shortcut Dimension 1 Code" := RequisitionLine."Shortcut Dimension 1 Code";
        TransferLine."Shortcut Dimension 2 Code" := RequisitionLine."Shortcut Dimension 2 Code";
        TransferLine."Dimension Set ID" := RequisitionLine."Dimension Set ID";
    end;

    procedure PrintTransferOrders()
    var
        TransferHeader: Record "Transfer Header";
        ReportSelections: Record "Report Selections";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        RecordRefToPrint: RecordRef;
        RecordRefToHeader: RecordRef;
        TransferOrderNoFilter: Text;
    begin
        CarryOutAction.GetTransferOrdersToPrint(TempTransferHeaderToPrint);

        case TempTransferHeaderToPrint.Count() of
            0:
                exit;
            1:
                begin
                    PrintOrder := true;
                    TempTransferHeaderToPrint.FindFirst();
                    PrintTransferOrder(TempTransferHeaderToPrint);
                end;
            else begin
                RecordRefToPrint.GetTable(TempTransferHeaderToPrint);
                RecordRefToHeader.GetTable(TransferHeader);
                TransferOrderNoFilter := SelectionFilterManagement.CreateFilterFromTempTable(RecordRefToPrint, RecordRefToHeader, TransferHeader.FieldNo("No."));

                TransferHeader.SetFilter("No.", TransferOrderNoFilter);
                OnPrintTransferOrderOnBeforePrintWithDialogWithCheckForCust(ReportSelections);
                ReportSelections.PrintWithDialogWithCheckForCust(Enum::"Report Selection Usage"::Inv1, TransferHeader, false, 0);
            end;
        end;

        TempTransferHeaderToPrint.DeleteAll();
    end;

    procedure PrintTransferOrder(TransferHeader: Record "Transfer Header")
    var
        ReportSelections: Record "Report Selections";
        TransferHeader2: Record "Transfer Header";
    begin
        if PrintOrder then begin
            TransferHeader2 := TransferHeader;
            TransferHeader2.SetRecFilter();
            OnPrintTransferOrderOnBeforePrintWithDialogWithCheckForCust(ReportSelections);
            ReportSelections.PrintWithDialogWithCheckForCust(Enum::"Report Selection Usage"::Inv1, TransferHeader2, false, 0);
        end;
    end;

    procedure PrintPurchaseOrder(PurchaseHeader: Record "Purchase Header")
    var
        ReportSelections: Record "Report Selections";
        PurchaseHeader2: Record "Purchase Header";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintPurchaseOrder2(PurchaseHeader, PrintOrder, IsHandled);
        if IsHandled then
            exit;

        if PrintOrder and (PurchaseHeader."Buy-from Vendor No." <> '') then begin
            PurchaseHeader2 := PurchaseHeader;
            PurchasesPayablesSetup.Get();
            if PurchasesPayablesSetup."Calc. Inv. Discount" then begin
                PurchaseLine.Reset();
                PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
                PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
                PurchaseLine.FindFirst();
                CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchaseLine);
            end;

            IsHandled := false;
            OnBeforePrintPurchaseOrder(PurchaseHeader2, IsHandled, PrintOrder);
            if IsHandled then
                exit;

            PurchaseHeader2.SetRecFilter();
            ReportSelections.PrintWithDialogWithCheckForVend(
              ReportSelections.Usage::"P.Order", PurchaseHeader2, false, PurchaseHeader2.FieldNo("Buy-from Vendor No."));
        end;
    end;

    procedure PrintMultiplePurchaseOrders(var TempPurchaseHeader: Record "Purchase Header" temporary)
    var
        PurchaseHeader: Record "Purchase Header";
        ReportSelections: Record "Report Selections";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        RecordRefToPrint: RecordRef;
        RecordRefToHeader: RecordRef;
        PurchaseOrderNoFilter: Text;
        IsHandled: Boolean;
    begin
        if not PrintOrder then
            exit;

        TempPurchaseHeader.Reset();
        if TempPurchaseHeader.IsEmpty() then
            exit;

        TempPurchaseHeader.FindSet();
        repeat
            PurchaseHeader.Get(TempPurchaseHeader."Document Type", TempPurchaseHeader."No.");
            PurchCalcDiscByType.ApplyDefaultInvoiceDiscount(0, PurchaseHeader);
        until TempPurchaseHeader.Next() = 0;

        IsHandled := false;
        OnBeforePrintMultiplePurchaseDocs(TempPurchaseHeader, IsHandled);
        if IsHandled then
            exit;

        RecordRefToPrint.GetTable(TempPurchaseHeader);
        RecordRefToHeader.GetTable(PurchaseHeader);
        PurchaseOrderNoFilter := SelectionFilterManagement.CreateFilterFromTempTable(RecordRefToPrint, RecordRefToHeader, PurchaseHeader.FieldNo("No."));

        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetFilter("No.", PurchaseOrderNoFilter);
        PurchaseHeader.SetFilter("Buy-from Vendor No.", '<>%1', '');
        ReportSelections.PrintWithDialogWithCheckForVend(
            ReportSelections.Usage::"P.Order", PurchaseHeader, false, PurchaseHeader.FieldNo("Buy-from Vendor No."));
    end;

    procedure PrintAsmOrder(AssemblyHeader: Record "Assembly Header")
    var
        ReportSelections: Record "Report Selections";
        AssemblyHeader2: Record "Assembly Header";
    begin
        if PrintOrder and (AssemblyHeader."Item No." <> '') then begin
            AssemblyHeader2 := AssemblyHeader;
            AssemblyHeader2.SetRecFilter();
            ReportSelections.PrintWithDialogWithCheckForCust(ReportSelections.Usage::"Asm.Order", AssemblyHeader2, false, 0);
        end;
    end;

    internal procedure PrintAsmOrders()
    var
        AssemblyHeader: Record "Assembly Header";
        ReportSelections: Record "Report Selections";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        RecordRefToPrint: RecordRef;
        RecordRefToHeader: RecordRef;
    begin
        CarryOutAction.GetAllAssemblyOrderForPrinting(TempAssemblyHeaderToPrint);
        if not TempAssemblyHeaderToPrint.IsEmpty() then begin
            RecordRefToPrint.GetTable(TempAssemblyHeaderToPrint);
            RecordRefToHeader.GetTable(AssemblyHeader);
            AssemblyHeader.SetFilter("No.", SelectionFilterManagement.CreateFilterFromTempTable(RecordRefToPrint, RecordRefToHeader, AssemblyHeader.FieldNo("No.")));
            AssemblyHeader.SetFilter("Item No.", '<>%1', '');
            ReportSelections.PrintWithDialogWithCheckForCust(ReportSelections.Usage::"Asm.Order", AssemblyHeader, false, 0);
            TempAssemblyHeaderToPrint.DeleteAll();
        end;
    end;

    internal procedure GetAllAssemblyOrderForPrinting(var TempAssemblyHeader: Record "Assembly Header" temporary)
    begin
        if PrintOrder then
            if TempAssemblyHeaderToPrint.FindSet() then begin
                repeat
                    TempAssemblyHeader := TempAssemblyHeaderToPrint;
                    if TempAssemblyHeader.Insert(false) then;
                until TempAssemblyHeaderToPrint.Next() = 0;
                TempAssemblyHeaderToPrint.DeleteAll();
            end;
    end;

    local procedure FinalizeOrderHeader(ProductionOrder: Record "Production Order")
    var
        ReportSelections: Record "Report Selections";
        ProductionOrder2: Record "Production Order";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFinalizeOrderHeader(ProductionOrder, PrintOrder, IsHandled);
        if IsHandled then
            exit;

        if PrintOrder and (ProductionOrder."No." <> '') then begin
            ProductionOrder2 := ProductionOrder;
            ProductionOrder2.SetRecFilter();
            ReportSelections.PrintWithDialogWithCheckForCust(ReportSelections.Usage::"Prod.Order", ProductionOrder2, false, 0);
        end;
    end;

    procedure TransferRouting(RequisitionLine: Record "Requisition Line"; ProductionOrder: Record "Production Order"; RoutingNo: Code[20]; RoutingRefNo: Integer): Boolean
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        PlanningRoutingLine: Record "Planning Routing Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderWarehouseMgt: Codeunit "Prod. Order Warehouse Mgt.";
        FlushingMethod: Enum "Flushing Method Routing";
    begin
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        if PlanningRoutingLine.Find('-') then
            repeat
                ProdOrderRoutingLine.Init();
                ProdOrderRoutingLine.Status := ProductionOrder.Status;
                ProdOrderRoutingLine."Prod. Order No." := ProductionOrder."No.";
                ProdOrderRoutingLine."Routing No." := RoutingNo;
                ProdOrderRoutingLine."Routing Reference No." := RoutingRefNo;
                ProdOrderRoutingLine.CopyFromPlanningRoutingLine(PlanningRoutingLine);
                case ProdOrderRoutingLine.Type of
                    ProdOrderRoutingLine.Type::"Work Center":
                        begin
                            WorkCenter.Get(PlanningRoutingLine."No.");
                            ProdOrderRoutingLine."Flushing Method" := WorkCenter."Flushing Method";
                        end;
                    ProdOrderRoutingLine.Type::"Machine Center":
                        begin
                            MachineCenter.Get(ProdOrderRoutingLine."No.");
                            ProdOrderRoutingLine."Flushing Method" := MachineCenter."Flushing Method";
                        end;
                end;
                ProdOrderRoutingLine."Location Code" := RequisitionLine."Location Code";
                ProdOrderRoutingLine."From-Production Bin Code" :=
                  ProdOrderWarehouseMgt.GetProdCenterBinCode(
                    PlanningRoutingLine.Type, PlanningRoutingLine."No.", RequisitionLine."Location Code", false, Enum::"Flushing Method"::Manual);

                FlushingMethod := ProdOrderRoutingLine."Flushing Method";
                if ProdOrderRoutingLine."Flushing Method" = ProdOrderRoutingLine."Flushing Method"::Manual then
                    ProdOrderRoutingLine."To-Production Bin Code" :=
                        ProdOrderWarehouseMgt.GetProdCenterBinCode(
                            PlanningRoutingLine.Type, PlanningRoutingLine."No.", RequisitionLine."Location Code", true,
                            FlushingMethod)
                else
                    ProdOrderRoutingLine."Open Shop Floor Bin Code" :=
                        ProdOrderWarehouseMgt.GetProdCenterBinCode(
                            PlanningRoutingLine.Type, PlanningRoutingLine."No.", RequisitionLine."Location Code", true,
                            FlushingMethod);

                ProdOrderRoutingLine.UpdateDatetime();
                OnAfterTransferPlanningRtngLine(PlanningRoutingLine, ProdOrderRoutingLine);
                ProdOrderRoutingLine.Insert();
                OnAfterProdOrderRtngLineInsert(ProdOrderRoutingLine, PlanningRoutingLine, ProductionOrder, RequisitionLine);
                CalculateProdOrder.TransferTaskInfo(ProdOrderRoutingLine, RequisitionLine."Routing Version Code");
            until PlanningRoutingLine.Next() = 0;

        exit(not PlanningRoutingLine.IsEmpty);
    end;

    procedure TransferBOM(RequisitionLine: Record "Requisition Line"; ProductionOrder: Record "Production Order"; ProdOrderLineNo: Integer)
    var
        PlanningComponent: Record "Planning Component";
        ProdOrderComponent2: Record "Prod. Order Component";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferBOM(RequisitionLine, ProductionOrder, ProdOrderLineNo, IsHandled);
        if IsHandled then
            exit;

        PlanningComponent.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningComponent.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        PlanningComponent.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        if PlanningComponent.Find('-') then
            repeat
                OnTransferBOMOnBeforeProdOrderComp2Init(PlanningComponent);
                ProdOrderComponent2.Init();
                ProdOrderComponent2.Status := ProductionOrder.Status;
                ProdOrderComponent2."Prod. Order No." := ProductionOrder."No.";
                ProdOrderComponent2."Prod. Order Line No." := ProdOrderLineNo;
                ProdOrderComponent2.CopyFromPlanningComp(PlanningComponent);
                ProdOrderComponent2.UpdateDatetime();
                OnAfterTransferPlanningComp(PlanningComponent, ProdOrderComponent2);
                ProdOrderComponent2.Insert();
                CopyProdBOMComments(ProdOrderComponent2);
                OnTransferBOMOnAfterCopyProdBOMComments(PlanningComponent, ProdOrderComponent2);
                PlngComponentReserve.TransferPlanningCompToPOComp(PlanningComponent, ProdOrderComponent2, 0, true);
                if ProdOrderComponent2.Status in [ProdOrderComponent2.Status::"Firm Planned", ProdOrderComponent2.Status::Released] then
                    ProdOrderComponent2.AutoReserve();

                ReservationManagement.SetReservSource(ProdOrderComponent2);
                ReservationManagement.AutoTrack(ProdOrderComponent2."Remaining Qty. (Base)");
            until PlanningComponent.Next() = 0;
    end;

    procedure TransferCapNeed(RequisitionLine: Record "Requisition Line"; ProductionOrder: Record "Production Order"; RoutingNo: Code[20]; RoutingRefNo: Integer)
    var
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        NewProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferCapNeed(RequisitionLine, ProductionOrder, RoutingNo, RoutingRefNo, IsHandled);
        if IsHandled then
            exit;

        ProdOrderCapacityNeed.SetCurrentKey("Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.");
        ProdOrderCapacityNeed.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        ProdOrderCapacityNeed.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        ProdOrderCapacityNeed.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        if ProdOrderCapacityNeed.Find('-') then
            repeat
                NewProdOrderCapacityNeed.Init();
                NewProdOrderCapacityNeed := ProdOrderCapacityNeed;
                NewProdOrderCapacityNeed."Requested Only" := false;
                NewProdOrderCapacityNeed.Status := ProductionOrder.Status;
                NewProdOrderCapacityNeed."Prod. Order No." := ProductionOrder."No.";
                NewProdOrderCapacityNeed."Routing No." := RoutingNo;
                NewProdOrderCapacityNeed."Routing Reference No." := RoutingRefNo;
                NewProdOrderCapacityNeed."Worksheet Template Name" := '';
                NewProdOrderCapacityNeed."Worksheet Batch Name" := '';
                NewProdOrderCapacityNeed."Worksheet Line No." := 0;
                NewProdOrderCapacityNeed.UpdateDatetime();
                NewProdOrderCapacityNeed.Insert();
            until ProdOrderCapacityNeed.Next() = 0;
    end;

    procedure UpdateComponentLink(ProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrderComponent: Record "Prod. Order Component";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateComponentLink(ProdOrderLine, IsHandled);
        if IsHandled then
            exit;

        ProdOrderComponent.SetCurrentKey(Status, "Prod. Order No.", "Prod. Order Line No.", "Item No.");
        ProdOrderComponent.SetRange(Status, ProdOrderLine.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderComponent.SetRange("Item No.", ProdOrderLine."Item No.");
        if ProdOrderComponent.Find('-') then
            repeat
                ProdOrderComponent."Supplied-by Line No." := ProdOrderLine."Line No.";
                ProdOrderComponent.Modify();
            until ProdOrderComponent.Next() = 0;
    end;

    procedure SetCreatedDocumentBuffer(var TempDocumentEntryNew: Record "Document Entry" temporary)
    begin
        TempDocumentEntry.Copy(TempDocumentEntryNew, true);
    end;

    local procedure InsertTempProdOrder(var RequisitionLine: Record "Requisition Line"; var NewProductionOrder: Record "Production Order")
    begin
        if TempProductionOrder.Get(NewProductionOrder.Status, NewProductionOrder."No.") then
            exit;

        TempDocumentEntry.Init();
        TempDocumentEntry."Table ID" := Database::"Production Order";
        TempDocumentEntry."Document Type" := NewProductionOrder.Status;
        TempDocumentEntry."Document No." := NewProductionOrder."No.";
        TempDocumentEntry."Entry No." := TempDocumentEntry.Count + 1;
        TempDocumentEntry.Insert();

        TempProductionOrder := NewProductionOrder;
        if RequisitionLine."Ref. Order Status" = RequisitionLine."Ref. Order Status"::Planned then begin
            TempProductionOrder."Planned Order No." := RequisitionLine."Ref. Order No.";
            TempProductionOrder.Insert();
        end;
    end;

    local procedure FindTempProdOrder(var RequisitionLine: Record "Requisition Line"): Boolean
    begin
        if RequisitionLine."Ref. Order Status" = RequisitionLine."Ref. Order Status"::Planned then begin
            TempProductionOrder.SetRange("Planned Order No.", RequisitionLine."Ref. Order No.");
            exit(TempProductionOrder.FindFirst())
        end;
    end;

    procedure SetPrintOrder(OrderPrinting: Boolean)
    begin
        PrintOrder := OrderPrinting;
    end;

    procedure SetSplitTransferOrders(Split: Boolean)
    begin
        SplitTransferOrders := Split;
    end;

    procedure ReserveBindingOrderToProd(var ProdOrderLine: Record "Prod. Order Line"; var RequisitionLine: Record "Requisition Line")
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservQty: Decimal;
        ReservQtyBase: Decimal;
    begin
        ProdOrderLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        if ProdOrderLine."Remaining Qty. (Base)" - ProdOrderLine."Reserved Qty. (Base)" >
           RequisitionLine."Demand Quantity (Base)"
        then begin
            ReservQty := RequisitionLine."Demand Quantity";
            ReservQtyBase := RequisitionLine."Demand Quantity (Base)";
        end else begin
            ReservQty := ProdOrderLine."Remaining Quantity" - ProdOrderLine."Reserved Quantity";
            ReservQtyBase := ProdOrderLine."Remaining Qty. (Base)" - ProdOrderLine."Reserved Qty. (Base)";
        end;

        TrackingSpecification.InitTrackingSpecification(
            Database::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.", 0,
            ProdOrderLine."Variant Code", ProdOrderLine."Location Code", ProdOrderLine."Qty. per Unit of Measure");

        RequisitionLine.ReserveBindingOrder(
            TrackingSpecification, ProdOrderLine.Description, ProdOrderLine."Ending Date", ReservQty, ReservQtyBase, true);

        ProdOrderLine.Modify();
    end;

    procedure ReserveBindingOrderToTrans(var TransferLine: Record "Transfer Line"; var RequisitionLine: Record "Requisition Line")
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservQty: Decimal;
        ReservQtyBase: Decimal;
    begin
        TransferLine.CalcFields("Reserved Quantity Inbnd.", "Reserved Qty. Inbnd. (Base)");
        if (TransferLine."Outstanding Qty. (Base)" - TransferLine."Reserved Qty. Inbnd. (Base)") > RequisitionLine."Demand Quantity (Base)" then begin
            ReservQty := RequisitionLine."Demand Quantity";
            ReservQtyBase := RequisitionLine."Demand Quantity (Base)";
        end else begin
            ReservQty := TransferLine."Outstanding Quantity" - TransferLine."Reserved Quantity Inbnd.";
            ReservQtyBase := TransferLine."Outstanding Qty. (Base)" - TransferLine."Reserved Qty. Inbnd. (Base)";
        end;

        TrackingSpecification.InitTrackingSpecification(
            Database::"Transfer Line", 1, TransferLine."Document No.", '', 0, TransferLine."Line No.",
            TransferLine."Variant Code", TransferLine."Transfer-to Code", TransferLine."Qty. per Unit of Measure");

        RequisitionLine.ReserveBindingOrder(
            TrackingSpecification, TransferLine.Description, TransferLine."Receipt Date", ReservQty, ReservQtyBase, true);

        TransferLine.Modify();
    end;

    procedure ReserveBindingOrderToAsm(var AssemblyHeader: Record "Assembly Header"; var RequisitionLine: Record "Requisition Line")
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservQty: Decimal;
        ReservQtyBase: Decimal;
    begin
        AssemblyHeader.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        if AssemblyHeader."Remaining Quantity (Base)" - AssemblyHeader."Reserved Qty. (Base)" >
           RequisitionLine."Demand Quantity (Base)"
        then begin
            ReservQty := RequisitionLine."Demand Quantity";
            ReservQtyBase := RequisitionLine."Demand Quantity (Base)";
        end else begin
            ReservQty := AssemblyHeader."Remaining Quantity" - AssemblyHeader."Reserved Quantity";
            ReservQtyBase := AssemblyHeader."Remaining Quantity (Base)" - AssemblyHeader."Reserved Qty. (Base)";
        end;

        TrackingSpecification.InitTrackingSpecification(
            Database::"Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", '', 0, 0,
            AssemblyHeader."Variant Code", AssemblyHeader."Location Code", AssemblyHeader."Qty. per Unit of Measure");

        RequisitionLine.ReserveBindingOrder(
            TrackingSpecification, AssemblyHeader.Description, AssemblyHeader."Due Date", ReservQty, ReservQtyBase, true);

        AssemblyHeader.Modify();
    end;

    procedure ReserveBindingOrderToReqline(var DemandRequisitionLine: Record "Requisition Line"; var SupplyRequisitionLine: Record "Requisition Line")
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservQty: Decimal;
        ReservQtyBase: Decimal;
    begin
        TrackingSpecification.InitTrackingSpecification(
            Database::"Requisition Line",
            0, DemandRequisitionLine."Worksheet Template Name", DemandRequisitionLine."Journal Batch Name", 0, DemandRequisitionLine."Line No.",
            DemandRequisitionLine."Variant Code", DemandRequisitionLine."Location Code", DemandRequisitionLine."Qty. per Unit of Measure");

        ReservQty := SupplyRequisitionLine."Needed Quantity";
        ReservQtyBase := SupplyRequisitionLine."Needed Quantity (Base)";

        SupplyRequisitionLine.ReserveBindingOrder(
            TrackingSpecification, DemandRequisitionLine.Description, DemandRequisitionLine."Due Date", ReservQty, ReservQtyBase, true);
    end;

    local procedure CopyProdBOMComments(ProdOrderComponent: Record "Prod. Order Component")
    var
        ProductionBOMCommentLine: Record "Production BOM Comment Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderCompCmtLine: Record "Prod. Order Comp. Cmt Line";
        ProductionBOMLine: Record "Production BOM Line";
        VersionManagement: Codeunit VersionManagement;
        ActiveVersionCode: Code[20];
    begin
        ProdOrderLine.Get(ProdOrderComponent.Status, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.");

        if not ProductionBOMHeader.Get(ProdOrderLine."Production BOM No.") then
            exit;

        ActiveVersionCode := VersionManagement.GetBOMVersion(ProductionBOMHeader."No.", WorkDate(), true);

        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
        ProductionBOMLine.SetRange(Type, ProductionBOMLine.Type::Item);
        ProductionBOMLine.SetRange("No.", ProdOrderComponent."Item No.");
        if ProductionBOMLine.FindSet() then
            repeat
                ProductionBOMCommentLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
                ProductionBOMCommentLine.SetRange("BOM Line No.", ProductionBOMLine."Line No.");
                ProductionBOMCommentLine.SetRange("Version Code", ActiveVersionCode);
                if ProductionBOMCommentLine.FindSet() then
                    repeat
                        ProdOrderCompCmtLine.CopyFromProdBOMComponent(ProductionBOMCommentLine, ProdOrderComponent);
                        if not ProdOrderCompCmtLine.Insert() then
                            ProdOrderCompCmtLine.Modify();
                    until ProductionBOMCommentLine.Next() = 0;
            until ProductionBOMLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCarryOutToReqWksh(var RequisitionLine: Record "Requisition Line"; RequisitionLine2: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteOrderLines(RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteRequisitionLine(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertProdOrder(var ProductionOrder: Record "Production Order"; ProdOrderChoice: Integer; var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertProdOrderLine(ReqLine: Record "Requisition Line"; ProdOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertAsmHeader(var ReqLine: Record "Requisition Line"; var AsmHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertTransLine(var TransHeader: Record "Transfer Header"; var ReqLine: Record "Requisition Line"; var TransLine: Record "Transfer Line"; var NextLineNo: Integer);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferAsmPlanningComp(var PlanningComponent: Record "Planning Component"; var AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransLineInsert(var TransferLine: Record "Transfer Line"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferPlanningRtngLine(var PlanningRtngLine: Record "Planning Routing Line"; var ProdOrderRtngLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferPlanningComp(var PlanningComponent: Record "Planning Component"; var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProdOrderRtngLineInsert(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; PlanningRoutingLine: Record "Planning Routing Line"; ProdOrder: Record "Production Order"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProdOrderChgAndReshedule(var RequisitionLine: Record "Requisition Line"; var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddResourceComponents(RequisitionLine: Record "Requisition Line"; var AssemblyHeader: Record "Assembly Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyDimensionsFromReqToTransLine(var TransferLine: Record "Transfer Line"; RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteOrderLines(RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteAssemblyLines(RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteProdOrderLines(RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeletePurchaseLines(RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteRequisitionLine(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteTransferLines(RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFinalizeOrderHeader(ProdOrder: Record "Production Order"; PrintOrder: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTransHeader(ReqLine: Record "Requisition Line"; var TransHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean; PrintOrder: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferBOM(ReqLine: Record "Requisition Line"; ProdOrder: Record "Production Order"; ProdOrderLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferCapNeed(ReqLine: Record "Requisition Line"; ProdOrder: Record "Production Order"; RoutingNo: Code[20]; RoutingRefNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateProdOrderLineQuantity(var ProdOrderLine: Record "Prod. Order Line"; ReqLine: Record "Requisition Line"; Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetProdOrderLineBinCodeFromPlanningRtngLines(ProdOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; ReqLine: Record "Requisition Line"; Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateComponentLink(ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCarryOutToReqWkshOnAfterPlanningCompInsert(var PlanningComponent: Record "Planning Component"; PlanningComponent2: Record "Planning Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCarryOutToReqWkshOnAfterPlanningRoutingLineInsert(var PlanningRoutingLine: Record "Planning Routing Line"; PlanningRoutingLine2: Record "Planning Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCarryOutToReqWkshOnBeforeReqLineInsert(var ReqLine: Record "Requisition Line"; var ReqWkshTempName: Code[10]; var ReqJournalName: Code[10]; var LineNo: Integer);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertProdOrderWithReqLine(var ProductionOrder: Record "Production Order"; var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertProdOrderLineWithReqLine(var ProdOrderLine: Record "Prod. Order Line"; var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertProdOrderLineOnBeforeProdOrderLineInit(var ReqLine: Record "Requisition Line"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTransLineWithReqLine(var TransferLine: Record "Transfer Line"; var RequisitionLine: Record "Requisition Line"; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertProdOrderLineOnAfterTransferRouting(var ProdOrderLine: Record "Prod. Order Line"; var RefreshProdOrderLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertProdOrderLineOnAfterProdOrderLineInsert(var ProdOrderLine: Record "Prod. Order Line"; var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertProdOrderOnBeforeProdOrderInit(var ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertProdOrderOnAfterFindTempProdOrder(var ReqLine: Record "Requisition Line"; var ProdOrder: Record "Production Order"; var HeaderExists: Boolean; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertProdOrderOnAfterProdOrderInsert(var ProdOrder: Record "Production Order"; ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertProdOrderOnBeforeProdOrderInsert(var ProdOrder: Record "Production Order"; ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchOrderChgAndResheduleOnAfterGetPurchHeader(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchOrderChgAndResheduleOnAfterGetPurchLine(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchOrderChgAndResheduleOnBeforePurchLineModify(var ReqLine: Record "Requisition Line"; var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransOrderChgAndResheduleOnBeforeTransLineModify(var ReqLine: Record "Requisition Line"; var TransLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferBOMOnBeforeProdOrderComp2Init(var PlanningComponent: Record "Planning Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAsmOrderChgAndResheduleOnBeforeAsmHeaderModify(var ReqLine: Record "Requisition Line"; var AssemblyHeader: Record "Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProdOrderChgAndResheduleOnAfterValidateQuantity(var ProdOrderLine: Record "Prod. Order Line"; var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProdOrderChgAndResheduleOnBeforeProdOrderModify(var ProductionOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTransHeaderOnBeforeTransHeaderInsert(var TransHeader: Record "Transfer Header"; ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTransHeaderOnAfterTransHeaderInsert(var TransHeader: Record "Transfer Header"; ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTransHeaderOnBeforeTransHeaderModify(var TransHeader: Record "Transfer Header"; ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTransLineOnAfterCalcShouldInsertTransHeader(RequisitionLine: Record "Requisition Line"; TransferHeader: Record "Transfer Header"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTransLineOnAfterTransLineInit(var TransLine: Record "Transfer Line"; ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertAsmHeaderOnBeforeAsmHeaderInsert(var AsmHeader: Record "Assembly Header"; ReqLine: Record "Requisition Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertAsmHeaderOnAfterAsmHeaderInsert(var AsmHeader: Record "Assembly Header"; ReqLine: Record "Requisition Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrintTransferOrderOnBeforePrintWithDialogWithCheckForCust(var ReportSelections: Record "Report Selections")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCarryOutActionsFromProdOrderOnAfterCalcPrintOrder(var PrintOrder: Boolean; ProdOrderChoice: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertProductionOrderOnProdOrderChoiceCaseElse(ProdOrderChoice: Enum "Planning Create Prod. Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCarryOutActionsFromTransOrderOnBeforeTransOrderChgAndReshedule(ReqLine: Record "Requisition Line"; PrintOrder: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertProdOrderLineOnBeforeGetBinCode(var ProdOrderLine: Record "Prod. Order Line"; ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertProdOrderOnProdOrderChoiceNotFirmPlannedPrint(var ProdOrder: Record "Production Order"; ProdOrderChoice: Enum "Planning Create Prod. Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCarryOutActionsFromTransOrderOnBeforeInsertTransLine(ReqLine: Record "Requisition Line"; PrintOrder: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintPurchaseOrder2(var PurchHeader: Record "Purchase Header"; PrintOrder: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchOrderChgAndResheduleOnBeforeValidateExpectedReceiptDate(var ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeCalcProductionExist(RequisitionLine: Record "Requisition Line"; TryChoice: Option; TryWkshTempl: Code[10]; TryWkshName: Code[10]; var ProductionExist: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCarryOutTransOrder(SplitTransferOrders: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintMultiplePurchaseDocs(var TempPurchaseHeader: Record "Purchase Header" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferBOMOnAfterCopyProdBOMComments(var PlanningComponent: Record "Planning Component"; var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertProdOrderLineOnBeforeValidateUnitCost(var RequisitionLine: Record "Requisition Line"; ProductionOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var Rec: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnInsertProdOrderLineOnBeforeModifyProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; var RequisitionLine: Record "Requisition Line")
    begin
    end;
}

