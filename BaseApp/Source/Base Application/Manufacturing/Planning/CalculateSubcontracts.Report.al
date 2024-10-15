﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Planning;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;

report 99001015 "Calculate Subcontracts"
{
    Caption = 'Calculate Subcontracts';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Work Center"; "Work Center")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Subcontractor No.";
            dataitem("Prod. Order Routing Line"; "Prod. Order Routing Line")
            {
                DataItemLink = "No." = field("No.");
                DataItemTableView = sorting(Type, "No.") where(Status = const(Released), Type = const("Work Center"), "Routing Status" = filter(< Finished));
                RequestFilterFields = "Prod. Order No.", "Starting Date";

                trigger OnAfterGetRecord()
                begin
                    Window.Update(2, "Prod. Order No.");

                    ProdOrderLine.SetCurrentKey(Status, "Prod. Order No.", "Routing No.", "Routing Reference No.");
                    ProdOrderLine.SetRange(Status, Status);
                    ProdOrderLine.SetRange("Prod. Order No.", "Prod. Order No.");
                    ProdOrderLine.SetRange("Routing No.", "Routing No.");
                    ProdOrderLine.SetRange("Routing Reference No.", "Routing Reference No.");
                    OnProdOrderRoutingLineOnAfterGetRecordOnAfterProdOrderLineSetFilters(ProdOrderLine, "Prod. Order Routing Line");
                    if ProdOrderLine.Find('-') then begin
                        DeleteRepeatedReqLines();
                        repeat
                            BaseQtyToPurch :=
                                CostCalcMgt.CalcQtyAdjdForRoutingScrap(
                                    CostCalcMgt.CalcQtyAdjdForBOMScrap(
                                        ProdOrderLine."Quantity (Base)", ProdOrderLine."Scrap %"),
                                        "Scrap Factor % (Accumulated)", "Fixed Scrap Qty. (Accum.)") -
                                (CostCalcMgt.CalcOutputQtyBaseOnPurchOrder(ProdOrderLine, "Prod. Order Routing Line") +
                                 CostCalcMgt.CalcActOutputQtyBase(ProdOrderLine, "Prod. Order Routing Line"));
                            QtyToPurch := Round(BaseQtyToPurch / ProdOrderLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                            OnAfterCalcQtyToPurch(ProdOrderLine, QtyToPurch);
                            if QtyToPurch > 0 then
                                InsertReqWkshLine();
                        until ProdOrderLine.Next() = 0;
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if "Subcontractor No." = '' then
                    CurrReport.Skip();

                Window.Update(1, "No.");
            end;

            trigger OnPreDataItem()
            begin
                ReqLine.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
                ReqLine.SetRange("Journal Batch Name", ReqLine."Journal Batch Name");
                ReqLine.DeleteAll();
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        MfgSetup.Get();
    end;

    trigger OnPreReport()
    begin
        ReqWkshTmpl.Get(ReqLine."Worksheet Template Name");
        ReqWkShName.Get(ReqLine."Worksheet Template Name", ReqLine."Journal Batch Name");
        ReqLine.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
        ReqLine.SetRange("Journal Batch Name", ReqLine."Journal Batch Name");
        ReqLine.LockTable();

        if ReqLine.FindLast() then
            ReqLine.Init();

        Window.Open(Text000 + Text001);
    end;

    var
        MfgSetup: Record "Manufacturing Setup";
        ReqWkshTmpl: Record "Req. Wksh. Template";
        ReqWkShName: Record "Requisition Wksh. Name";
        ReqLine: Record "Requisition Line";
        ProdOrderLine: Record "Prod. Order Line";
        GLSetup: Record "General Ledger Setup";
        PurchLine: Record "Purchase Line";
        Item: Record Item;
        CostCalcMgt: Codeunit "Cost Calculation Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        Window: Dialog;
        BaseQtyToPurch: Decimal;
        QtyToPurch: Decimal;
        GLSetupRead: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Processing Work Centers   #1##########\';
        Text001: Label 'Processing Orders         #2########## ';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure SetWkShLine(NewReqLine: Record "Requisition Line")
    begin
        ReqLine := NewReqLine;
    end;

    local procedure InsertReqWkshLine()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertReqWkshLine("Prod. Order Routing Line", "Work Center", ReqLine, IsHandled, ProdOrderLine);
        if IsHandled then
            exit;

        ProdOrderLine.CalcFields("Total Exp. Oper. Output (Qty.)");

        ReqLine.SetSubcontracting(true);
        ReqLine.BlockDynamicTracking(true);

        ReqLine.Init();
        ReqLine."Line No." := ReqLine."Line No." + 10000;
        ReqLine.Validate(Type, ReqLine.Type::Item);
        ReqLine.Validate("No.", ProdOrderLine."Item No.");
        ReqLine.Validate("Variant Code", ProdOrderLine."Variant Code");
        ReqLine.Validate("Unit of Measure Code", ProdOrderLine."Unit of Measure Code");
        ReqLine.Validate(Quantity, QtyToPurch);
        GetGLSetup();
        IsHandled := false;
        OnBeforeValidateUnitCost(ReqLine, "Work Center", IsHandled, ProdOrderLine, "Prod. Order Routing Line");
        if not IsHandled then
            if ReqLine.Quantity <> 0 then begin
                if "Work Center"."Unit Cost Calculation" = "Work Center"."Unit Cost Calculation"::Units then
                    ReqLine.Validate(
                        ReqLine."Direct Unit Cost",
                        Round(
                            "Prod. Order Routing Line"."Direct Unit Cost" * ProdOrderLine."Qty. per Unit of Measure",
                            GLSetup."Unit-Amount Rounding Precision"))
                else
                    ReqLine.Validate(
                        ReqLine."Direct Unit Cost",
                        Round(
                            ("Prod. Order Routing Line"."Expected Operation Cost Amt." - "Prod. Order Routing Line"."Expected Capacity Ovhd. Cost") /
                            ProdOrderLine."Total Exp. Oper. Output (Qty.)",
                            GLSetup."Unit-Amount Rounding Precision"));
            end else
                ReqLine.Validate(ReqLine."Direct Unit Cost", 0);
        ReqLine."Qty. per Unit of Measure" := 0;
        ReqLine."Quantity (Base)" := 0;
        ReqLine."Qty. Rounding Precision" := ProdOrderLine."Qty. Rounding Precision";
        ReqLine."Qty. Rounding Precision (Base)" := ProdOrderLine."Qty. Rounding Precision (Base)";
        ReqLine."Prod. Order No." := ProdOrderLine."Prod. Order No.";
        ReqLine."Prod. Order Line No." := ProdOrderLine."Line No.";
        ReqLine."Due Date" := "Prod. Order Routing Line"."Ending Date";
        ReqLine."Requester ID" := CopyStr(UserId(), 1, 50);
        ReqLine."Location Code" := ProdOrderLine."Location Code";
        ReqLine."Bin Code" := ProdOrderLine."Bin Code";
        ReqLine."Routing Reference No." := "Prod. Order Routing Line"."Routing Reference No.";
        ReqLine."Routing No." := "Prod. Order Routing Line"."Routing No.";
        ReqLine."Operation No." := "Prod. Order Routing Line"."Operation No.";
        ReqLine."Work Center No." := "Prod. Order Routing Line"."Work Center No.";
        ReqLine.Validate(ReqLine."Vendor No.", "Work Center"."Subcontractor No.");
        ReqLine.Description := "Prod. Order Routing Line".Description;
        SetVendorItemNo();
        OnAfterTransferProdOrderRoutingLine(ReqLine, "Prod. Order Routing Line");
        // If purchase order already exist we will change this if possible
        PurchLine.Reset();
        PurchLine.SetCurrentKey("Document Type", Type, "Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.");
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        PurchLine.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        PurchLine.SetRange("Routing No.", "Prod. Order Routing Line"."Routing No.");
        PurchLine.SetRange("Operation No.", "Prod. Order Routing Line"."Operation No.");
        PurchLine.SetRange("Planning Flexibility", PurchLine."Planning Flexibility"::Unlimited);
        PurchLine.SetRange("Quantity Received", 0);
        if PurchLine.FindFirst() then begin
            ReqLine.Validate(ReqLine.Quantity, ReqLine.Quantity + PurchLine."Outstanding Quantity");
            ReqLine."Quantity (Base)" := 0;
            ReqLine."Replenishment System" := ReqLine."Replenishment System"::Purchase;
            ReqLine."Ref. Order No." := PurchLine."Document No.";
            ReqLine."Ref. Order Type" := ReqLine."Ref. Order Type"::Purchase;
            ReqLine."Ref. Line No." := PurchLine."Line No.";
            if PurchLine."Expected Receipt Date" = ReqLine."Due Date" then
                ReqLine."Action Message" := ReqLine."Action Message"::"Change Qty."
            else
                ReqLine."Action Message" := ReqLine."Action Message"::"Resched. & Chg. Qty.";
            ReqLine."Accept Action Message" := true;
        end else begin
            ReqLine."Replenishment System" := ReqLine."Replenishment System"::"Prod. Order";
            ReqLine."Ref. Order No." := ProdOrderLine."Prod. Order No.";
            ReqLine."Ref. Order Type" := ReqLine."Ref. Order Type"::"Prod. Order";
            ReqLine."Ref. Order Status" := ProdOrderLine.Status;
            ReqLine."Ref. Line No." := ProdOrderLine."Line No.";
            ReqLine."Action Message" := ReqLine."Action Message"::New;
            ReqLine."Accept Action Message" := true;
        end;

        if ReqLine."Ref. Order No." <> '' then
            ReqLine.GetDimFromRefOrderLine(true);

        OnBeforeReqWkshLineInsert(ReqLine, ProdOrderLine);
        ReqLine.Insert();
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get();
        GLSetupRead := true;
    end;

    local procedure DeleteRepeatedReqLines()
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ProdOrderLine."Item No.");
        RequisitionLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        RequisitionLine.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        RequisitionLine.SetRange("Operation No.", "Prod. Order Routing Line"."Operation No.");
        OnDeleteRepeatedReqLinesOnAfterRequisitionLineSetFilters(RequisitionLine, ProdOrderLine, "Prod. Order Routing Line");
        RequisitionLine.DeleteAll(true);
    end;

    local procedure SetVendorItemNo()
    var
        ItemVendor: Record "Item Vendor";
    begin
        if ReqLine."No." = '' then
            exit;

        if Item."No." <> ReqLine."No." then begin
            Item.SetLoadFields("No.");
            Item.Get(ReqLine."No.");
        end;

        ItemVendor.Init();
        ItemVendor."Vendor No." := ReqLine."Vendor No.";
        ItemVendor."Variant Code" := ReqLine."Variant Code";
        Item.FindItemVend(ItemVendor, ReqLine."Location Code");
        ReqLine.Validate("Vendor Item No.", ItemVendor."Vendor Item No.");
        OnAfterSetVendorItemNo(ReqLine, ItemVendor, Item);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcQtyToPurch(ProdOrderLine: Record "Prod. Order Line"; var QtyToPurch: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferProdOrderRoutingLine(var RequisitionLine: Record "Requisition Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertReqWkshLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var WorkCenter: Record "Work Center"; var ReqLine: Record "Requisition Line"; var IsHandled: Boolean; ProdOrderLine: Record "Prod. Order Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateUnitCost(var RequisitionLine: Record "Requisition Line"; var WorkCenter: Record "Work Center"; var IsHandled: Boolean; ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReqWkshLineInsert(var RequisitionLine: Record "Requisition Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteRepeatedReqLinesOnAfterRequisitionLineSetFilters(var RequisitionLine: Record "Requisition Line"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProdOrderRoutingLineOnAfterGetRecordOnAfterProdOrderLineSetFilters(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetVendorItemNo(var RequisitionLine: Record "Requisition Line"; ItemVendor: Record "Item Vendor"; Item: Record Item)
    begin
    end;
}

