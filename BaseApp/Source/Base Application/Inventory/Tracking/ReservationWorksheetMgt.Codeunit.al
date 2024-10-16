namespace Microsoft.Inventory.Tracking;

using Microsoft.Assembly.Document;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Service.Document;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Availability;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;

codeunit 300 "Reservation Worksheet Mgt."
{
    trigger OnRun()
    begin

    end;

    var
        DefaultNameTok: Label 'DEFAULT';
        DefaultDescriptionTok: Label 'Default Worksheet';
        LineIsOutdatedErr: Label 'The Reservation Worksheet Line is outdated. Please recalculate the demand.';
        SourceDocTok: Label '%1 %2 %3', Comment = '%1: Source Document, %2: Source Document Type, %3: Source Document No.';
        SalesTok: Label 'Sales';
        TransferTok: Label 'Transfer';
        ServiceTok: Label 'Service';
        JobTok: Label 'Project';
        AssemblyTok: Label 'Assembly';
        ReleasedTok: Label 'Released';
        ProductionTok: Label 'Prod. Order';

    procedure LookupName(var CurrentJnlBatchName: Code[10]; var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        ReservationWkshBatch: Record "Reservation Wksh. Batch";
    begin
        Commit();
        ReservationWkshBatch.Name := ReservationWkshLine.GetRangeMax("Journal Batch Name");
        if PAGE.RunModal(0, ReservationWkshBatch) = ACTION::LookupOK then begin
            CurrentJnlBatchName := ReservationWkshBatch.Name;
            SetName(CurrentJnlBatchName, ReservationWkshLine);
        end;
    end;

    procedure SetName(CurrentJnlBatchName: Code[10]; var ReservationWkshLine: Record "Reservation Wksh. Line")
    begin
        ReservationWkshLine.FilterGroup(2);
        ReservationWkshLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        ReservationWkshLine.FilterGroup(0);
        if ReservationWkshLine.FindFirst() then;
    end;

    procedure CheckName(CurrentJnlBatchName: Code[10])
    var
        ReservationWkshBatch: Record "Reservation Wksh. Batch";
    begin
        ReservationWkshBatch.Get(CurrentJnlBatchName);
    end;

    local procedure CheckAndCreateName(var CurrentJnlBatchName: Code[10])
    var
        ReservationWkshBatch: Record "Reservation Wksh. Batch";
    begin
        if ReservationWkshBatch.Get(CurrentJnlBatchName) then
            exit;

        if not ReservationWkshBatch.FindFirst() then begin
            ReservationWkshBatch.Init();
            ReservationWkshBatch.Name := DefaultNameTok;
            ReservationWkshBatch.Description := DefaultDescriptionTok;
            ReservationWkshBatch.Insert(true);
            Commit();
        end;
        CurrentJnlBatchName := ReservationWkshBatch.Name;
    end;

    procedure OpenJnl(var CurrentJnlBatchName: Code[10]; var ReservationWkshLine: Record "Reservation Wksh. Line")
    begin
        CheckAndCreateName(CurrentJnlBatchName);
        ReservationWkshLine.FilterGroup(2);
        ReservationWkshLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        ReservationWkshLine.FilterGroup(0);
    end;

    procedure CalculateDemand(BatchName: Code[10])
    var
        GetDemandToReserve: Report "Get Demand To Reserve";
    begin
        GetDemandToReserve.SetBatchName(BatchName);
        GetDemandToReserve.RunModal();
        SyncSalesOrderLines(BatchName, GetDemandToReserve);
        SyncTransferOrderLines(BatchName, GetDemandToReserve);
        SyncServiceOrderLines(BatchName, GetDemandToReserve);
        SyncJobPlanningLines(BatchName, GetDemandToReserve);
        SyncAssemblyOrderLines(BatchName, GetDemandToReserve);
        SyncProdOrderComponents(BatchName, GetDemandToReserve);
        AutoAllocate(BatchName, GetDemandToReserve);
    end;

    local procedure SyncSalesOrderLines(BatchName: Code[10]; var GetDemandToReserve: Report "Get Demand To Reserve")
    var
        ReservationWkshLine: Record "Reservation Wksh. Line";
        TempSalesLine: Record "Sales Line" temporary;
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        RemainingQty, RemainingQtyBase : Decimal;
        AvailableQtyBase, InventoryQtyBase, ReservedQtyBase, WarehouseQtyBase : Decimal;
        LineNo: Integer;
    begin
        GetDemandToReserve.GetSalesOrderLines(TempSalesLine);
        if TempSalesLine.IsEmpty() then
            exit;

        ReservationWkshLine.SetCurrentKey("Journal Batch Name", "Source Type");
        ReservationWkshLine.SetRange("Journal Batch Name", BatchName);
        ReservationWkshLine.SetRange("Source Type", Database::"Sales Line");
        if ReservationWkshLine.FindSet(true) then
            repeat
                if ReservationWkshLine.IsOutdated() or TempSalesLine.Get(ReservationWkshLine."Record ID") then
                    ReservationWkshLine.Delete(true);
            until ReservationWkshLine.Next() = 0;

        ReservationWkshLine."Journal Batch Name" := BatchName;
        LineNo := ReservationWkshLine.GetLastLineNo();

        TempSalesLine.FindSet();
        repeat
            LineNo += 10000;
            ReservationWkshLine.Init();
            ReservationWkshLine."Journal Batch Name" := BatchName;
            ReservationWkshLine."Line No." := LineNo;
            ReservationWkshLine."Source Type" := Database::"Sales Line";
            ReservationWkshLine."Source Subtype" := TempSalesLine."Document Type".AsInteger();
            ReservationWkshLine."Source ID" := TempSalesLine."Document No.";
            ReservationWkshLine."Source Ref. No." := TempSalesLine."Line No.";
            ReservationWkshLine."Record ID" := TempSalesLine.RecordId;
            ReservationWkshLine."Item No." := TempSalesLine."No.";
            ReservationWkshLine."Variant Code" := TempSalesLine."Variant Code";
            ReservationWkshLine."Location Code" := TempSalesLine."Location Code";
            ReservationWkshLine.Description := TempSalesLine.Description;
            ReservationWkshLine."Description 2" := TempSalesLine."Description 2";

            SalesHeader.Get(TempSalesLine."Document Type", TempSalesLine."Document No.");
            ReservationWkshLine."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
            ReservationWkshLine."Sell-to Customer Name" := SalesHeader."Sell-to Customer Name";
            Customer.SetLoadFields(Priority);
            if Customer.Get(ReservationWkshLine."Sell-to Customer No.") then
                ReservationWkshLine.Priority := Customer.Priority;

            ReservationWkshLine."Demand Date" := TempSalesLine."Shipment Date";
            ReservationWkshLine."Unit of Measure Code" := TempSalesLine."Unit of Measure Code";
            ReservationWkshLine."Qty. per Unit of Measure" := TempSalesLine."Qty. per Unit of Measure";

            TempSalesLine.GetRemainingQty(RemainingQty, RemainingQtyBase);
            ReservationWkshLine."Remaining Qty. to Reserve" := RemainingQty;
            ReservationWkshLine."Rem. Qty. to Reserve (Base)" := RemainingQtyBase;

            GetAvailRemainingQtyOnItemLedgerEntry(
              AvailableQtyBase, InventoryQtyBase, ReservedQtyBase, WarehouseQtyBase,
              ReservationWkshLine."Item No.", ReservationWkshLine."Variant Code", ReservationWkshLine."Location Code");

            ReservationWkshLine.Validate("Avail. Qty. to Reserve (Base)", AvailableQtyBase);
            ReservationWkshLine.Validate("Qty. in Stock (Base)", InventoryQtyBase);
            ReservationWkshLine.Validate("Qty. Reserv. in Stock (Base)", ReservedQtyBase);
            ReservationWkshLine.Validate("Qty. in Whse. Handling (Base)", WarehouseQtyBase);

            if (ReservationWkshLine."Remaining Qty. to Reserve" > 0) and
               (ReservationWkshLine."Available Qty. to Reserve" > 0)
            then
                ReservationWkshLine.Insert(true);
        until TempSalesLine.Next() = 0;
    end;

    local procedure SyncTransferOrderLines(BatchName: Code[10]; var GetDemandToReserve: Report "Get Demand To Reserve")
    var
        ReservationWkshLine: Record "Reservation Wksh. Line";
        TempTransferLine: Record "Transfer Line" temporary;
        RemainingQty, RemainingQtyBase : Decimal;
        AvailableQtyBase, InventoryQtyBase, ReservedQtyBase, WarehouseQtyBase : Decimal;
        LineNo: Integer;
    begin
        GetDemandToReserve.GetTransferOrderLines(TempTransferLine);
        if TempTransferLine.IsEmpty() then
            exit;

        ReservationWkshLine.SetCurrentKey("Journal Batch Name", "Source Type");
        ReservationWkshLine.SetRange("Journal Batch Name", BatchName);
        ReservationWkshLine.SetRange("Source Type", Database::"Transfer Line");
        if ReservationWkshLine.FindSet(true) then
            repeat
                if ReservationWkshLine.IsOutdated() or TempTransferLine.Get(ReservationWkshLine."Record ID") then
                    ReservationWkshLine.Delete(true);
            until ReservationWkshLine.Next() = 0;

        ReservationWkshLine."Journal Batch Name" := BatchName;
        LineNo := ReservationWkshLine.GetLastLineNo();

        TempTransferLine.FindSet();
        repeat
            LineNo += 10000;
            ReservationWkshLine.Init();
            ReservationWkshLine."Journal Batch Name" := BatchName;
            ReservationWkshLine."Line No." := LineNo;
            ReservationWkshLine."Source Type" := Database::"Transfer Line";
            ReservationWkshLine."Source Subtype" := Enum::"Transfer Direction"::Outbound.AsInteger();
            ReservationWkshLine."Source ID" := TempTransferLine."Document No.";
            ReservationWkshLine."Source Ref. No." := TempTransferLine."Line No.";
            ReservationWkshLine."Record ID" := TempTransferLine.RecordId;
            ReservationWkshLine."Item No." := TempTransferLine."Item No.";
            ReservationWkshLine."Variant Code" := TempTransferLine."Variant Code";
            ReservationWkshLine."Location Code" := TempTransferLine."Transfer-from Code";
            ReservationWkshLine.Description := TempTransferLine.Description;
            ReservationWkshLine."Description 2" := TempTransferLine."Description 2";
            ReservationWkshLine."Demand Date" := TempTransferLine."Shipment Date";
            ReservationWkshLine."Unit of Measure Code" := TempTransferLine."Unit of Measure Code";
            ReservationWkshLine."Qty. per Unit of Measure" := TempTransferLine."Qty. per Unit of Measure";

            TempTransferLine.GetRemainingQty(RemainingQty, RemainingQtyBase, Enum::"Transfer Direction"::Outbound.AsInteger());
            ReservationWkshLine."Remaining Qty. to Reserve" := RemainingQty;
            ReservationWkshLine."Rem. Qty. to Reserve (Base)" := RemainingQtyBase;

            GetAvailRemainingQtyOnItemLedgerEntry(
              AvailableQtyBase, InventoryQtyBase, ReservedQtyBase, WarehouseQtyBase,
              ReservationWkshLine."Item No.", ReservationWkshLine."Variant Code", ReservationWkshLine."Location Code");

            ReservationWkshLine.Validate("Avail. Qty. to Reserve (Base)", AvailableQtyBase);
            ReservationWkshLine.Validate("Qty. in Stock (Base)", InventoryQtyBase);
            ReservationWkshLine.Validate("Qty. Reserv. in Stock (Base)", ReservedQtyBase);
            ReservationWkshLine.Validate("Qty. in Whse. Handling (Base)", WarehouseQtyBase);

            if (ReservationWkshLine."Remaining Qty. to Reserve" > 0) and
               (ReservationWkshLine."Available Qty. to Reserve" > 0)
            then
                ReservationWkshLine.Insert(true);
        until TempTransferLine.Next() = 0;
    end;

    local procedure SyncServiceOrderLines(BatchName: Code[10]; var GetDemandToReserve: Report "Get Demand To Reserve")
    var
        ReservationWkshLine: Record "Reservation Wksh. Line";
        TempServiceLine: Record "Service Line" temporary;
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        RemainingQty, RemainingQtyBase : Decimal;
        AvailableQtyBase, InventoryQtyBase, ReservedQtyBase, WarehouseQtyBase : Decimal;
        LineNo: Integer;
    begin
        GetDemandToReserve.GetServiceOrderLines(TempServiceLine);
        if TempServiceLine.IsEmpty() then
            exit;

        ReservationWkshLine.SetCurrentKey("Journal Batch Name", "Source Type");
        ReservationWkshLine.SetRange("Journal Batch Name", BatchName);
        ReservationWkshLine.SetRange("Source Type", Database::"Service Line");
        if ReservationWkshLine.FindSet(true) then
            repeat
                if ReservationWkshLine.IsOutdated() or TempServiceLine.Get(ReservationWkshLine."Record ID") then
                    ReservationWkshLine.Delete(true);
            until ReservationWkshLine.Next() = 0;

        ReservationWkshLine."Journal Batch Name" := BatchName;
        LineNo := ReservationWkshLine.GetLastLineNo();

        TempServiceLine.FindSet();
        repeat
            LineNo += 10000;
            ReservationWkshLine.Init();
            ReservationWkshLine."Journal Batch Name" := BatchName;
            ReservationWkshLine."Line No." := LineNo;
            ReservationWkshLine."Source Type" := Database::"Service Line";
            ReservationWkshLine."Source Subtype" := TempServiceLine."Document Type".AsInteger();
            ReservationWkshLine."Source ID" := TempServiceLine."Document No.";
            ReservationWkshLine."Source Ref. No." := TempServiceLine."Line No.";
            ReservationWkshLine."Record ID" := TempServiceLine.RecordId;
            ReservationWkshLine."Item No." := TempServiceLine."No.";
            ReservationWkshLine."Variant Code" := TempServiceLine."Variant Code";
            ReservationWkshLine."Location Code" := TempServiceLine."Location Code";
            ReservationWkshLine.Description := TempServiceLine.Description;
            ReservationWkshLine."Description 2" := TempServiceLine."Description 2";

            ServiceHeader.Get(TempServiceLine."Document Type", TempServiceLine."Document No.");
            ReservationWkshLine."Sell-to Customer No." := ServiceHeader."Customer No.";
            ReservationWkshLine."Sell-to Customer Name" := ServiceHeader.Name;
            Customer.SetLoadFields(Priority);
            if Customer.Get(ReservationWkshLine."Sell-to Customer No.") then
                ReservationWkshLine.Priority := Customer.Priority;

            ReservationWkshLine."Demand Date" := TempServiceLine."Needed by Date";
            ReservationWkshLine."Unit of Measure Code" := TempServiceLine."Unit of Measure Code";
            ReservationWkshLine."Qty. per Unit of Measure" := TempServiceLine."Qty. per Unit of Measure";

            TempServiceLine.GetRemainingQty(RemainingQty, RemainingQtyBase);
            ReservationWkshLine."Remaining Qty. to Reserve" := RemainingQty;
            ReservationWkshLine."Rem. Qty. to Reserve (Base)" := RemainingQtyBase;

            GetAvailRemainingQtyOnItemLedgerEntry(
              AvailableQtyBase, InventoryQtyBase, ReservedQtyBase, WarehouseQtyBase,
              ReservationWkshLine."Item No.", ReservationWkshLine."Variant Code", ReservationWkshLine."Location Code");

            ReservationWkshLine.Validate("Avail. Qty. to Reserve (Base)", AvailableQtyBase);
            ReservationWkshLine.Validate("Qty. in Stock (Base)", InventoryQtyBase);
            ReservationWkshLine.Validate("Qty. Reserv. in Stock (Base)", ReservedQtyBase);
            ReservationWkshLine.Validate("Qty. in Whse. Handling (Base)", WarehouseQtyBase);

            if (ReservationWkshLine."Remaining Qty. to Reserve" > 0) and
               (ReservationWkshLine."Available Qty. to Reserve" > 0)
            then
                ReservationWkshLine.Insert(true);
        until TempServiceLine.Next() = 0;
    end;

    local procedure SyncJobPlanningLines(BatchName: Code[10]; var GetDemandToReserve: Report "Get Demand To Reserve")
    var
        ReservationWkshLine: Record "Reservation Wksh. Line";
        TempJobPlanningLine: Record "Job Planning Line" temporary;
        Job: Record Job;
        Customer: Record Customer;
        RemainingQty, RemainingQtyBase : Decimal;
        AvailableQtyBase, InventoryQtyBase, ReservedQtyBase, WarehouseQtyBase : Decimal;
        LineNo: Integer;
    begin
        GetDemandToReserve.GetJobPlanningLines(TempJobPlanningLine);
        if TempJobPlanningLine.IsEmpty() then
            exit;

        ReservationWkshLine.SetCurrentKey("Journal Batch Name", "Source Type");
        ReservationWkshLine.SetRange("Journal Batch Name", BatchName);
        ReservationWkshLine.SetRange("Source Type", Database::"Job Planning Line");
        if ReservationWkshLine.FindSet(true) then
            repeat
                if ReservationWkshLine.IsOutdated() or TempJobPlanningLine.Get(ReservationWkshLine."Record ID") then
                    ReservationWkshLine.Delete(true);
            until ReservationWkshLine.Next() = 0;

        ReservationWkshLine."Journal Batch Name" := BatchName;
        LineNo := ReservationWkshLine.GetLastLineNo();

        TempJobPlanningLine.FindSet();
        repeat
            LineNo += 10000;
            ReservationWkshLine.Init();
            ReservationWkshLine."Journal Batch Name" := BatchName;
            ReservationWkshLine."Line No." := LineNo;
            ReservationWkshLine."Source Type" := Database::"Job Planning Line";
            ReservationWkshLine."Source Subtype" := TempJobPlanningLine.Status.AsInteger();
            ReservationWkshLine."Source ID" := TempJobPlanningLine."Job No.";
            ReservationWkshLine."Source Ref. No." := TempJobPlanningLine."Job Contract Entry No.";
            ReservationWkshLine."Record ID" := TempJobPlanningLine.RecordId;
            ReservationWkshLine."Item No." := TempJobPlanningLine."No.";
            ReservationWkshLine."Variant Code" := TempJobPlanningLine."Variant Code";
            ReservationWkshLine."Location Code" := TempJobPlanningLine."Location Code";
            ReservationWkshLine.Description := TempJobPlanningLine.Description;
            ReservationWkshLine."Description 2" := TempJobPlanningLine."Description 2";

            Job.Get(TempJobPlanningLine."Job No.");
            ReservationWkshLine."Sell-to Customer No." := Job."Sell-to Customer No.";
            ReservationWkshLine."Sell-to Customer Name" := Job."Sell-to Customer Name";
            Customer.SetLoadFields(Priority);
            if Customer.Get(ReservationWkshLine."Sell-to Customer No.") then
                ReservationWkshLine.Priority := Customer.Priority;

            ReservationWkshLine."Demand Date" := TempJobPlanningLine."Planning Date";
            ReservationWkshLine."Unit of Measure Code" := TempJobPlanningLine."Unit of Measure Code";
            ReservationWkshLine."Qty. per Unit of Measure" := TempJobPlanningLine."Qty. per Unit of Measure";

            TempJobPlanningLine.GetRemainingQty(RemainingQty, RemainingQtyBase);
            ReservationWkshLine."Remaining Qty. to Reserve" := RemainingQty;
            ReservationWkshLine."Rem. Qty. to Reserve (Base)" := RemainingQtyBase;

            GetAvailRemainingQtyOnItemLedgerEntry(
              AvailableQtyBase, InventoryQtyBase, ReservedQtyBase, WarehouseQtyBase,
              ReservationWkshLine."Item No.", ReservationWkshLine."Variant Code", ReservationWkshLine."Location Code");

            ReservationWkshLine.Validate("Avail. Qty. to Reserve (Base)", AvailableQtyBase);
            ReservationWkshLine.Validate("Qty. in Stock (Base)", InventoryQtyBase);
            ReservationWkshLine.Validate("Qty. Reserv. in Stock (Base)", ReservedQtyBase);
            ReservationWkshLine.Validate("Qty. in Whse. Handling (Base)", WarehouseQtyBase);

            if (ReservationWkshLine."Remaining Qty. to Reserve" > 0) and
               (ReservationWkshLine."Available Qty. to Reserve" > 0)
            then
                ReservationWkshLine.Insert(true);
        until TempJobPlanningLine.Next() = 0;
    end;

    local procedure SyncAssemblyOrderLines(BatchName: Code[10]; var GetDemandToReserve: Report "Get Demand To Reserve")
    var
        ReservationWkshLine: Record "Reservation Wksh. Line";
        TempAssemblyLine: Record "Assembly Line" temporary;
        RemainingQty, RemainingQtyBase : Decimal;
        AvailableQtyBase, InventoryQtyBase, ReservedQtyBase, WarehouseQtyBase : Decimal;
        LineNo: Integer;
    begin
        GetDemandToReserve.GetAssemblyLines(TempAssemblyLine);
        if TempAssemblyLine.IsEmpty() then
            exit;

        ReservationWkshLine.SetCurrentKey("Journal Batch Name", "Source Type");
        ReservationWkshLine.SetRange("Journal Batch Name", BatchName);
        ReservationWkshLine.SetRange("Source Type", Database::"Assembly Line");
        if ReservationWkshLine.FindSet(true) then
            repeat
                if ReservationWkshLine.IsOutdated() or TempAssemblyLine.Get(ReservationWkshLine."Record ID") then
                    ReservationWkshLine.Delete(true);
            until ReservationWkshLine.Next() = 0;

        ReservationWkshLine."Journal Batch Name" := BatchName;
        LineNo := ReservationWkshLine.GetLastLineNo();

        TempAssemblyLine.FindSet();
        repeat
            LineNo += 10000;
            ReservationWkshLine.Init();
            ReservationWkshLine."Journal Batch Name" := BatchName;
            ReservationWkshLine."Line No." := LineNo;
            ReservationWkshLine."Source Type" := Database::"Assembly Line";
            ReservationWkshLine."Source Subtype" := TempAssemblyLine."Document Type".AsInteger();
            ReservationWkshLine."Source ID" := TempAssemblyLine."Document No.";
            ReservationWkshLine."Source Ref. No." := TempAssemblyLine."Line No.";
            ReservationWkshLine."Record ID" := TempAssemblyLine.RecordId;
            ReservationWkshLine."Item No." := TempAssemblyLine."No.";
            ReservationWkshLine."Variant Code" := TempAssemblyLine."Variant Code";
            ReservationWkshLine."Location Code" := TempAssemblyLine."Location Code";
            ReservationWkshLine.Description := TempAssemblyLine.Description;
            ReservationWkshLine."Description 2" := TempAssemblyLine."Description 2";

            ReservationWkshLine."Demand Date" := TempAssemblyLine."Due Date";
            ReservationWkshLine."Unit of Measure Code" := TempAssemblyLine."Unit of Measure Code";
            ReservationWkshLine."Qty. per Unit of Measure" := TempAssemblyLine."Qty. per Unit of Measure";

            TempAssemblyLine.GetRemainingQty(RemainingQty, RemainingQtyBase);
            ReservationWkshLine."Remaining Qty. to Reserve" := RemainingQty;
            ReservationWkshLine."Rem. Qty. to Reserve (Base)" := RemainingQtyBase;

            GetAvailRemainingQtyOnItemLedgerEntry(
              AvailableQtyBase, InventoryQtyBase, ReservedQtyBase, WarehouseQtyBase,
              ReservationWkshLine."Item No.", ReservationWkshLine."Variant Code", ReservationWkshLine."Location Code");

            ReservationWkshLine.Validate("Avail. Qty. to Reserve (Base)", AvailableQtyBase);
            ReservationWkshLine.Validate("Qty. in Stock (Base)", InventoryQtyBase);
            ReservationWkshLine.Validate("Qty. Reserv. in Stock (Base)", ReservedQtyBase);
            ReservationWkshLine.Validate("Qty. in Whse. Handling (Base)", WarehouseQtyBase);

            if (ReservationWkshLine."Remaining Qty. to Reserve" > 0) and
               (ReservationWkshLine."Available Qty. to Reserve" > 0)
            then
                ReservationWkshLine.Insert(true);
        until TempAssemblyLine.Next() = 0;
    end;

    local procedure SyncProdOrderComponents(BatchName: Code[10]; var GetDemandToReserve: Report "Get Demand To Reserve")
    var
        ReservationWkshLine: Record "Reservation Wksh. Line";
        TempProdOrderComponent: Record "Prod. Order Component" temporary;
        RemainingQty, RemainingQtyBase : Decimal;
        AvailableQtyBase, InventoryQtyBase, ReservedQtyBase, WarehouseQtyBase : Decimal;
        LineNo: Integer;
    begin
        GetDemandToReserve.GetProdOrderComponents(TempProdOrderComponent);
        if TempProdOrderComponent.IsEmpty() then
            exit;

        ReservationWkshLine.SetCurrentKey("Journal Batch Name", "Source Type");
        ReservationWkshLine.SetRange("Journal Batch Name", BatchName);
        ReservationWkshLine.SetRange("Source Type", Database::"Prod. Order Component");
        if ReservationWkshLine.FindSet(true) then
            repeat
                if ReservationWkshLine.IsOutdated() or TempProdOrderComponent.Get(ReservationWkshLine."Record ID") then
                    ReservationWkshLine.Delete(true);
            until ReservationWkshLine.Next() = 0;

        ReservationWkshLine."Journal Batch Name" := BatchName;
        LineNo := ReservationWkshLine.GetLastLineNo();

        TempProdOrderComponent.FindSet();
        repeat
            LineNo += 10000;
            ReservationWkshLine.Init();
            ReservationWkshLine."Journal Batch Name" := BatchName;
            ReservationWkshLine."Line No." := LineNo;
            ReservationWkshLine."Source Type" := Database::"Prod. Order Component";
            ReservationWkshLine."Source Subtype" := TempProdOrderComponent.Status.AsInteger();
            ReservationWkshLine."Source ID" := TempProdOrderComponent."Prod. Order No.";
            ReservationWkshLine."Source Ref. No." := TempProdOrderComponent."Line No.";
            ReservationWkshLine."Source Prod. Order Line" := TempProdOrderComponent."Prod. Order Line No.";
            ReservationWkshLine."Record ID" := TempProdOrderComponent.RecordId;
            ReservationWkshLine."Item No." := TempProdOrderComponent."Item No.";
            ReservationWkshLine."Variant Code" := TempProdOrderComponent."Variant Code";
            ReservationWkshLine."Location Code" := TempProdOrderComponent."Location Code";
            ReservationWkshLine.Description := TempProdOrderComponent.Description;

            ReservationWkshLine."Demand Date" := TempProdOrderComponent."Due Date";
            ReservationWkshLine."Unit of Measure Code" := TempProdOrderComponent."Unit of Measure Code";
            ReservationWkshLine."Qty. per Unit of Measure" := TempProdOrderComponent."Qty. per Unit of Measure";

            TempProdOrderComponent.GetRemainingQty(RemainingQty, RemainingQtyBase);
            ReservationWkshLine."Remaining Qty. to Reserve" := RemainingQty;
            ReservationWkshLine."Rem. Qty. to Reserve (Base)" := RemainingQtyBase;

            GetAvailRemainingQtyOnItemLedgerEntry(
              AvailableQtyBase, InventoryQtyBase, ReservedQtyBase, WarehouseQtyBase,
              ReservationWkshLine."Item No.", ReservationWkshLine."Variant Code", ReservationWkshLine."Location Code");

            ReservationWkshLine.Validate("Avail. Qty. to Reserve (Base)", AvailableQtyBase);
            ReservationWkshLine.Validate("Qty. in Stock (Base)", InventoryQtyBase);
            ReservationWkshLine.Validate("Qty. Reserv. in Stock (Base)", ReservedQtyBase);
            ReservationWkshLine.Validate("Qty. in Whse. Handling (Base)", WarehouseQtyBase);

            if (ReservationWkshLine."Remaining Qty. to Reserve" > 0) and
               (ReservationWkshLine."Available Qty. to Reserve" > 0)
            then
                ReservationWkshLine.Insert(true);
        until TempProdOrderComponent.Next() = 0;
    end;

    local procedure AutoAllocate(BatchName: Code[10]; var GetDemandToReserve: Report "Get Demand To Reserve")
    var
        ReservationWkshLine: Record "Reservation Wksh. Line";
    begin
        if GetDemandToReserve.GetAllocateAfterPopulate() then begin
            ReservationWkshLine.SetRange("Journal Batch Name", BatchName);
            AllocateQuantity(ReservationWkshLine);
        end;
    end;

    procedure CreateSourceDocumentText(ReservationWkshLine: Record "Reservation Wksh. Line"): Text[100]
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Sales Line":
                exit(
                  StrSubstNo(
                    SourceDocTok, SalesTok,
                    Enum::"Sales Document Type".FromInteger(ReservationWkshLine."Source Subtype"), ReservationWkshLine."Source ID"));
            Database::"Transfer Line":
                exit(
                  StrSubstNo(
                    SourceDocTok, TransferTok,
                    Enum::"Transfer Direction".FromInteger(ReservationWkshLine."Source Subtype"), ReservationWkshLine."Source ID"));
            Database::"Service Line":
                exit(
                  StrSubstNo(
                    SourceDocTok, ServiceTok,
                    Enum::"Service Document Type".FromInteger(ReservationWkshLine."Source Subtype"), ReservationWkshLine."Source ID"));
            Database::"Job Planning Line":
                exit(StrSubstNo(SourceDocTok, JobTok, ReservationWkshLine."Source ID", ''));
            Database::"Assembly Line":
                exit(
                  StrSubstNo(
                    SourceDocTok, AssemblyTok,
                    Enum::"Assembly Document Type".FromInteger(ReservationWkshLine."Source Subtype"), ReservationWkshLine."Source ID"));
            Database::"Prod. Order Component":
                exit(
                  StrSubstNo(
                    SourceDocTok, ReleasedTok, ProductionTok, ReservationWkshLine."Source ID"));
        end;

        exit('');
    end;

    procedure GetSourceDocumentLine(ReservationWkshLine: Record "Reservation Wksh. Line";
                                    var RecordVariant: Variant;
                                    var MaxQtyToReserve: Decimal; var MaxQtyToReserveBase: Decimal;
                                    var AvailabilityDate: Date)
    var
        SalesLine: Record "Sales Line";
        TransferLine: Record "Transfer Line";
        ServiceLine: Record "Service Line";
        JobPlanningLine: Record "Job Planning Line";
        AssemblyLine: Record "Assembly Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        Clear(RecordVariant);
        Clear(MaxQtyToReserve);
        Clear(MaxQtyToReserveBase);
        Clear(AvailabilityDate);

        if ReservationWkshLine.IsOutdated() then
            exit;

        case ReservationWkshLine."Source Type" of
            Database::"Sales Line":
                begin
                    SalesLine.Get(ReservationWkshLine."Record ID");
                    RecordVariant := SalesLine;
                    SalesLine.GetRemainingQty(MaxQtyToReserve, MaxQtyToReserveBase);
                    AvailabilityDate := SalesLine."Shipment Date";
                end;
            Database::"Transfer Line":
                begin
                    TransferLine.Get(ReservationWkshLine."Record ID");
                    RecordVariant := TransferLine;
                    TransferLine.GetRemainingQty(MaxQtyToReserve, MaxQtyToReserveBase, ReservationWkshLine."Source Subtype");
                    AvailabilityDate := TransferLine."Shipment Date";
                end;
            Database::"Service Line":
                begin
                    ServiceLine.Get(ReservationWkshLine."Record ID");
                    RecordVariant := ServiceLine;
                    ServiceLine.GetRemainingQty(MaxQtyToReserve, MaxQtyToReserveBase);
                    AvailabilityDate := ServiceLine."Needed by Date";
                end;
            Database::"Job Planning Line":
                begin
                    JobPlanningLine.Get(ReservationWkshLine."Record ID");
                    RecordVariant := JobPlanningLine;
                    JobPlanningLine.GetRemainingQty(MaxQtyToReserve, MaxQtyToReserveBase);
                    AvailabilityDate := JobPlanningLine."Planning Date";
                end;
            Database::"Assembly Line":
                begin
                    AssemblyLine.Get(ReservationWkshLine."Record ID");
                    RecordVariant := AssemblyLine;
                    AssemblyLine.GetRemainingQty(MaxQtyToReserve, MaxQtyToReserveBase);
                    AvailabilityDate := AssemblyLine."Due Date";
                end;
            Database::"Prod. Order Component":
                begin
                    ProdOrderComponent.Get(ReservationWkshLine."Record ID");
                    RecordVariant := ProdOrderComponent;
                    ProdOrderComponent.GetRemainingQty(MaxQtyToReserve, MaxQtyToReserveBase);
                    AvailabilityDate := ProdOrderComponent."Due Date";
                end;
        end;
    end;

    procedure GetSourceDocumentLineQuantities(ReservationWkshLine: Record "Reservation Wksh. Line";
                                              var OutstandingQty: Decimal; var ReservedQty: Decimal; var ReservedFromStockQty: Decimal)
    var
        SalesLine: Record "Sales Line";
        TransferLine: Record "Transfer Line";
        ServiceLine: Record "Service Line";
        JobPlanningLine: Record "Job Planning Line";
        AssemblyLine: Record "Assembly Line";
        ProdOrderComponent: Record "Prod. Order Component";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        TransferLineReserve: Codeunit "Transfer Line-Reserve";
        ServiceLineReserve: Codeunit "Service Line-Reserve";
        JobPlanningLineReserve: Codeunit "Job Planning Line-Reserve";
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
    begin
        OutstandingQty := 0;
        ReservedQty := 0;
        ReservedFromStockQty := 0;

        if ReservationWkshLine.IsOutdated() then
            exit;

        case ReservationWkshLine."Source Type" of
            Database::"Sales Line":
                begin
                    SalesLine.SetLoadFields("Outstanding Quantity");
                    SalesLine.Get(ReservationWkshLine."Record ID");
                    SalesLine.CalcFields("Reserved Quantity");
                    OutstandingQty := SalesLine."Outstanding Quantity";
                    ReservedQty := SalesLine."Reserved Quantity";
                    ReservedFromStockQty := SalesLineReserve.GetReservedQtyFromInventory(SalesLine);
                end;
            Database::"Transfer Line":
                begin
                    TransferLine.SetLoadFields("Outstanding Quantity");
                    TransferLine.Get(ReservationWkshLine."Record ID");
                    TransferLine.CalcFields("Reserved Quantity Outbnd.");
                    OutstandingQty := TransferLine."Outstanding Quantity";
                    ReservedQty := TransferLine."Reserved Quantity Outbnd.";
                    ReservedFromStockQty := TransferLineReserve.GetReservedQtyFromInventory(TransferLine);
                end;
            Database::"Service Line":
                begin
                    ServiceLine.SetLoadFields("Outstanding Quantity");
                    ServiceLine.Get(ReservationWkshLine."Record ID");
                    ServiceLine.CalcFields("Reserved Quantity");
                    OutstandingQty := ServiceLine."Outstanding Quantity";
                    ReservedQty := ServiceLine."Reserved Quantity";
                    ReservedFromStockQty := ServiceLineReserve.GetReservedQtyFromInventory(ServiceLine);
                end;
            Database::"Job Planning Line":
                begin
                    JobPlanningLine.SetLoadFields("Remaining Qty.");
                    JobPlanningLine.Get(ReservationWkshLine."Record ID");
                    JobPlanningLine.CalcFields("Reserved Quantity");
                    OutstandingQty := JobPlanningLine."Remaining Qty.";
                    ReservedQty := JobPlanningLine."Reserved Quantity";
                    ReservedFromStockQty := JobPlanningLineReserve.GetReservedQtyFromInventory(JobPlanningLine);
                end;
            Database::"Assembly Line":
                begin
                    AssemblyLine.SetLoadFields("Remaining Quantity");
                    AssemblyLine.Get(ReservationWkshLine."Record ID");
                    AssemblyLine.CalcFields("Reserved Quantity");
                    OutstandingQty := AssemblyLine."Remaining Quantity";
                    ReservedQty := AssemblyLine."Reserved Quantity";
                    ReservedFromStockQty := AssemblyLineReserve.GetReservedQtyFromInventory(AssemblyLine);
                end;
            Database::"Prod. Order Component":
                begin
                    ProdOrderComponent.SetLoadFields("Remaining Quantity");
                    ProdOrderComponent.Get(ReservationWkshLine."Record ID");
                    ProdOrderComponent.CalcFields("Reserved Quantity");
                    OutstandingQty := ProdOrderComponent."Remaining Quantity";
                    ReservedQty := ProdOrderComponent."Reserved Quantity";
                    ReservedFromStockQty := ProdOrderCompReserve.GetReservedQtyFromInventory(ProdOrderComponent);
                end;
        end;
    end;

    procedure ShowSourceDocument(ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        SalesLine: Record "Sales Line";
        TransferLine: Record "Transfer Line";
        ServiceLine: Record "Service Line";
        JobPlanningLine: Record "Job Planning Line";
        AssemblyLine: Record "Assembly Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        if ReservationWkshLine.IsOutdated() then
            Error(LineIsOutdatedErr);

        case ReservationWkshLine."Source Type" of
            Database::"Sales Line":
                if SalesLine.Get(ReservationWkshLine."Record ID") then begin
                    SalesLine.SetRecFilter();
                    Page.Run(0, SalesLine);
                end;
            Database::"Transfer Line":
                if TransferLine.Get(ReservationWkshLine."Record ID") then begin
                    TransferLine.SetRecFilter();
                    Page.Run(0, TransferLine);
                end;
            Database::"Service Line":
                if ServiceLine.Get(ReservationWkshLine."Record ID") then begin
                    ServiceLine.SetRecFilter();
                    Page.Run(0, ServiceLine);
                end;
            Database::"Job Planning Line":
                if JobPlanningLine.Get(ReservationWkshLine."Record ID") then begin
                    JobPlanningLine.SetRecFilter();
                    Page.Run(0, JobPlanningLine);
                end;
            Database::"Assembly Line":
                if AssemblyLine.Get(ReservationWkshLine."Record ID") then begin
                    AssemblyLine.SetRecFilter();
                    Page.Run(0, AssemblyLine);
                end;
            Database::"Prod. Order Component":
                if ProdOrderComponent.Get(ReservationWkshLine."Record ID") then begin
                    ProdOrderComponent.SetRecFilter();
                    Page.Run(0, ProdOrderComponent);
                end;
        end;
    end;

    procedure ShowReservationEntries(ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        SalesLine: Record "Sales Line";
        TransferLine: Record "Transfer Line";
        ServiceLine: Record "Service Line";
        JobPlanningLine: Record "Job Planning Line";
        AssemblyLine: Record "Assembly Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        if ReservationWkshLine.IsOutdated() then
            Error(LineIsOutdatedErr);

        case ReservationWkshLine."Source Type" of
            Database::"Sales Line":
                begin
                    SalesLine.Get(ReservationWkshLine."Record ID");
                    SalesLine.ShowReservationEntries(false);
                end;
            Database::"Transfer Line":
                begin
                    TransferLine.Get(ReservationWkshLine."Record ID");
                    TransferLine.ShowReservationEntries(false, Enum::"Transfer Direction"::Outbound);
                end;
            Database::"Service Line":
                begin
                    ServiceLine.Get(ReservationWkshLine."Record ID");
                    ServiceLine.ShowReservationEntries(false);
                end;
            Database::"Job Planning Line":
                begin
                    JobPlanningLine.Get(ReservationWkshLine."Record ID");
                    JobPlanningLine.ShowReservationEntries(false);
                end;
            Database::"Assembly Line":
                begin
                    AssemblyLine.Get(ReservationWkshLine."Record ID");
                    AssemblyLine.ShowReservationEntries(false);
                end;
            Database::"Prod. Order Component":
                begin
                    ProdOrderComponent.Get(ReservationWkshLine."Record ID");
                    ProdOrderComponent.ShowReservationEntries(false);
                end;
        end;
    end;

    procedure ShowStatistics(ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        SalesHeader: Record "Sales Header";
        TransferHeader: Record "Transfer Header";
        ServiceHeader: Record "Service Header";
        Job: Record Job;
        AssemblyHeader: Record "Assembly Header";
        ProductionOrder: Record "Production Order";
    begin
        if ReservationWkshLine.IsOutdated() then
            Error(LineIsOutdatedErr);

        case ReservationWkshLine."Source Type" of
            Database::"Sales Line":
                begin
                    SalesHeader.SetLoadFields("Document Type", "No.");
                    SalesHeader.Get(ReservationWkshLine."Source Subtype", ReservationWkshLine."Source ID");
                    SalesHeader.ShowDocumentStatisticsPage();
                end;
            Database::"Transfer Line":
                begin
                    TransferHeader.SetLoadFields("No.");
                    TransferHeader.Get(ReservationWkshLine."Source ID");
                    Page.RunModal(Page::"Transfer Statistics", TransferHeader);
                end;
            Database::"Service Line":
                begin
                    ServiceHeader.SetLoadFields("Document Type", "No.");
                    ServiceHeader.Get(ReservationWkshLine."Source Subtype", ReservationWkshLine."Source ID");
                    ServiceHeader.OpenOrderStatistics();
                end;
            Database::"Job Planning Line":
                begin
                    Job.SetLoadFields("No.");
                    Job.Get(ReservationWkshLine."Source ID");
                    Page.RunModal(Page::"Job Statistics", Job);
                end;
            Database::"Assembly Line":
                begin
                    AssemblyHeader.SetLoadFields("Document Type", "No.");
                    AssemblyHeader.Get(ReservationWkshLine."Source Subtype", ReservationWkshLine."Source ID");
                    AssemblyHeader.ShowStatistics();
                end;
            Database::"Prod. Order Component":
                begin
                    ProductionOrder.SetLoadFields(Status, "No.");
                    ProductionOrder.Get(ReservationWkshLine."Source Subtype", ReservationWkshLine."Source ID");
                    Page.RunModal(Page::"Production Order Statistics", ProductionOrder);
                end;
        end;
    end;

    procedure GetAvailRemainingQtyOnItemLedgerEntry(var AvailableQtyBase: Decimal; var InventoryQtyBase: Decimal; var ReservedQtyBase: Decimal; var WarehouseQtyBase: Decimal;
                                                    ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
        Location: Record Location;
        TempBinContentBuffer: Record "Bin Content Buffer" temporary;
        WarehouseAvailabilityMgt: Codeunit "Warehouse Availability Mgt.";
        SummarizedStockByItemTrkg: Query "Summarized Stock By Item Trkg.";
        QtyReservedFromItemLedger: Query "Qty. Reserved From Item Ledger";
        NonReservedQtyLotSN: Decimal;
        CurrWhseQty: Decimal;
        QtyOnOutboundBins: Decimal;
        QtyOnSpecialBins: Decimal;
    begin
        AvailableQtyBase := 0;
        InventoryQtyBase := 0;
        ReservedQtyBase := 0;
        WarehouseQtyBase := 0;

        SummarizedStockByItemTrkg.SetRange(Item_No_, ItemNo);
        SummarizedStockByItemTrkg.SetRange(Variant_Code, VariantCode);
        SummarizedStockByItemTrkg.SetRange(Location_Code, LocationCode);
        SummarizedStockByItemTrkg.SetRange(Open, true);
        SummarizedStockByItemTrkg.SetRange(Positive, true);
        SummarizedStockByItemTrkg.Open();
        while SummarizedStockByItemTrkg.Read() do begin
            ItemTrackingSetup."Serial No." := SummarizedStockByItemTrkg.Serial_No_;
            ItemTrackingSetup."Lot No." := SummarizedStockByItemTrkg.Lot_No_;
            ItemTrackingSetup."Package No." := SummarizedStockByItemTrkg.Package_No_;
            if not IsItemTrackingBlocked(ItemNo, VariantCode, ItemTrackingSetup) then begin
                NonReservedQtyLotSN := SummarizedStockByItemTrkg.Remaining_Quantity;
                InventoryQtyBase += SummarizedStockByItemTrkg.Remaining_Quantity;

                QtyReservedFromItemLedger.SetRange(Item_No_, ItemNo);
                QtyReservedFromItemLedger.SetRange(Variant_Code, VariantCode);
                QtyReservedFromItemLedger.SetRange(Location_Code, LocationCode);
                QtyReservedFromItemLedger.SetRange(Serial_No_, ItemTrackingSetup."Serial No.");
                QtyReservedFromItemLedger.SetRange(Lot_No_, ItemTrackingSetup."Lot No.");
                QtyReservedFromItemLedger.SetRange(Package_No_, ItemTrackingSetup."Package No.");
                QtyReservedFromItemLedger.Open();
                if QtyReservedFromItemLedger.Read() then begin
                    NonReservedQtyLotSN -= QtyReservedFromItemLedger.Quantity__Base_;
                    ReservedQtyBase += QtyReservedFromItemLedger.Quantity__Base_;
                end;

                CurrWhseQty := 0;
                QtyOnOutboundBins := 0;
                QtyOnSpecialBins := 0;
                if Location.Get(LocationCode) and Location."Require Pick" then begin
                    CurrWhseQty := CalcNonRegisteredQtyOutstanding(ItemNo, VariantCode, LocationCode, ItemTrackingSetup);

                    if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" and ItemTrackingSetup.TrackingExists()
                    then begin
                        WarehouseAvailabilityMgt.GetOutboundBinsOnBasicWarehouseLocation(
                          TempBinContentBuffer, LocationCode, ItemNo, VariantCode, ItemTrackingSetup);
                        TempBinContentBuffer.CalcSums("Qty. Outstanding (Base)");
                        QtyOnOutboundBins := TempBinContentBuffer."Qty. Outstanding (Base)";
                    end else
                        QtyOnOutboundBins :=
                            WarehouseAvailabilityMgt.CalcQtyOnOutboundBins(LocationCode, ItemNo, VariantCode, ItemTrackingSetup, true);

                    QtyOnSpecialBins :=
                        WarehouseAvailabilityMgt.CalcQtyOnSpecialBinsOnLocation(
                          LocationCode, ItemNo, VariantCode, ItemTrackingSetup, TempBinContentBuffer);

                    CurrWhseQty += QtyOnOutboundBins + QtyOnSpecialBins;
                    if CurrWhseQty < 0 then
                        CurrWhseQty := 0;
                end;
                NonReservedQtyLotSN -= CurrWhseQty;
                WarehouseQtyBase += CurrWhseQty;

                if NonReservedQtyLotSN > 0 then
                    AvailableQtyBase += NonReservedQtyLotSN;
            end;
        end;
    end;

    local procedure IsItemTrackingBlocked(ItemNo: Code[20]; VariantCode: Code[10]; ItemTrackingSetup: Record "Item Tracking Setup"): Boolean
    var
        LotNoInformation: Record "Lot No. Information";
        SerialNoInformation: Record "Serial No. Information";
    begin
        if ItemTrackingSetup."Lot No." <> '' then
            if LotNoInformation.Get(ItemNo, VariantCode, ItemTrackingSetup."Lot No.") then
                if LotNoInformation.Blocked then
                    exit(true);

        if ItemTrackingSetup."Serial No." <> '' then
            if SerialNoInformation.Get(ItemNo, VariantCode, ItemTrackingSetup."Serial No.") then
                if SerialNoInformation.Blocked then
                    exit(true);

        exit(false);
    end;

    local procedure CalcNonRegisteredQtyOutstanding(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"): Decimal
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange("Variant Code", VariantCode);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetTrackingFilterFromItemTrackingSetup(WhseItemTrackingSetup);
        WarehouseActivityLine.CalcSums("Qty. Outstanding (Base)");
        exit(WarehouseActivityLine."Qty. Outstanding (Base)");
    end;

    procedure CarryOutAction(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        ReservationWkshLineToProcess: Record "Reservation Wksh. Line";
        CarryOutReservation: Report "Carry Out Reservation";
    begin
        ReservationWkshLineToProcess.Copy(ReservationWkshLine);
        CarryOutReservation.SetTableView(ReservationWkshLineToProcess);
        CarryOutReservation.RunModal();
    end;

    procedure LogChanges(ReservationWkshLine: Record "Reservation Wksh. Line"; Qty: Decimal)
    var
        ReservationWorksheetLog: Record "Reservation Worksheet Log";
    begin
        ReservationWorksheetLog.Init();
        ReservationWorksheetLog."Journal Batch Name" := ReservationWkshLine."Journal Batch Name";
        ReservationWorksheetLog."Entry No." := 0;
        ReservationWorksheetLog."Record ID" := ReservationWkshLine."Record ID";
        ReservationWorksheetLog.Quantity := Qty;
        ReservationWorksheetLog.Insert(true);
    end;

    procedure AllocateQuantity(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        AllocationPolicy: Record "Allocation Policy";
        TempAllocationPolicy: Record "Allocation Policy" temporary;
        AllocateReservation: Interface "Allocate Reservation";
        AllocationCompleted: Boolean;
    begin
        ReservationWkshLine.LockTable();
        if not ReservationWkshLine.FindFirst() then
            exit;

        AllocationPolicy.SetRange("Journal Batch Name", ReservationWkshLine."Journal Batch Name");
        if not AllocationPolicy.FindSet() then begin
            TempAllocationPolicy.Init();
            TempAllocationPolicy."Journal Batch Name" := ReservationWkshLine."Journal Batch Name";
            TempAllocationPolicy."Line No." := 10000;
            TempAllocationPolicy."Allocation Rule" := TempAllocationPolicy."Allocation Rule"::"Basic (No Conflicts)";
            TempAllocationPolicy.Insert();
        end else
            repeat
                TempAllocationPolicy.Init();
                TempAllocationPolicy := AllocationPolicy;
                TempAllocationPolicy.Insert();
            until AllocationPolicy.Next() = 0;

        TempAllocationPolicy.FindSet();
        repeat
            AllocateReservation := TempAllocationPolicy."Allocation Rule";
            AllocateReservation.DeleteAllocation(ReservationWkshLine);
            AllocateReservation.Allocate(ReservationWkshLine);
            AllocationCompleted := AllocateReservation.AllocationCompleted(ReservationWkshLine);
        until (TempAllocationPolicy.Next() = 0) or AllocationCompleted;
    end;

    procedure DeleteAllocation(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        ReservWkshLine: Record "Reservation Wksh. Line";
    begin
        ReservWkshLine.LockTable();
        ReservWkshLine.Copy(ReservationWkshLine);
        if not ReservWkshLine.FindSet(true) then
            exit;

        repeat
            ReservWkshLine.Validate("Qty. to Reserve", 0);
            ReservWkshLine.Modify(true);
        until ReservWkshLine.Next() = 0;
    end;

    procedure AcceptSelected(var ReservationWkshLine: Record "Reservation Wksh. Line")
    begin
        ReservationWkshLine.ModifyAll(Accept, true, true);
    end;

    procedure CreateTransferOrder(var TransferHeader: Record "Transfer Header"; ReservationWkshLine: Record "Reservation Wksh. Line"; LocationFromCode: Code[10])
    var
        TransferLine: Record "Transfer Line";
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.TestField("Transfer Order Nos.");

        TransferHeader.Init();
        TransferHeader."No." := '';
        TransferHeader."Posting Date" := WorkDate();
        TransferHeader.Insert(true);
        TransferHeader.Validate("Transfer-from Code", LocationFromCode);
        TransferHeader.Validate("Transfer-to Code", ReservationWkshLine."Location Code");
        TransferHeader.Modify();

        TransferLine.Init();
        TransferLine.BlockDynamicTracking(true);
        TransferLine."Document No." := TransferHeader."No.";
        TransferLine."Line No." := 10000;
        TransferLine.Validate("Item No.", ReservationWkshLine."Item No.");
        TransferLine.Description := ReservationWkshLine.Description;
        TransferLine.Validate("Variant Code", ReservationWkshLine."Variant Code");
        TransferLine.Validate("Transfer-from Code", TransferHeader."Transfer-from Code");
        TransferLine.Validate("Transfer-to Code", TransferHeader."Transfer-to Code");
        TransferLine.Validate("Unit of Measure Code", ReservationWkshLine."Unit of Measure Code");
        TransferLine."Receipt Date" := TransferHeader."Receipt Date";
        TransferLine."Shipment Date" := TransferHeader."Shipment Date";
        TransferLine.Insert();
    end;
}
