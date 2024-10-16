// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

codeunit 5403 AddOnIntegrManagement
{
    Permissions = TableData "Manufacturing Setup" = rimd;

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        CostCalcMgt: Codeunit "Cost Calculation Management";
        RndgSetupRead: Boolean;

    procedure CheckReceiptOrderStatus(var SalesLine: Record "Sales Line")
    var
        CheckReceiptOrderStatus: Codeunit "Check Prod. Order Status";
        Checked: Boolean;
    begin
        OnBeforeCheckReceiptOrderStatus(SalesLine, Checked);
        if Checked then
            exit;

        if SalesLine."Document Type" <> SalesLine."Document Type"::Order then
            exit;

        if SalesLine.Type <> SalesLine.Type::Item then
            exit;

        CheckReceiptOrderStatus.SalesLineCheck(SalesLine);
    end;

    procedure ValidateProdOrderOnPurchLine(var PurchLine: Record "Purchase Line")
    var
        Item: Record Item;
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateProdOrderOnPurchLine(PurchLine, IsHandled);
        if IsHandled then
            exit;

        PurchLine.TestField(Type, PurchLine.Type::Item);

        if ProdOrder.Get(ProdOrder.Status::Released, PurchLine."Prod. Order No.") then begin
            ProdOrder.TestField(Blocked, false);
            ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
            ProdOrderLine.SetRange("Prod. Order No.", PurchLine."Prod. Order No.");
            ProdOrderLine.SetRange("Item No.", PurchLine."No.");
            if ProdOrderLine.FindFirst() then
                PurchLine."Routing No." := ProdOrderLine."Routing No.";
            Item.Get(PurchLine."No.");
            PurchLine.Validate("Unit of Measure Code", Item."Base Unit of Measure");
        end;
    end;

    procedure ResetReqLineFields(var ReqLine: Record "Requisition Line")
    begin
        ReqLine."Prod. Order Line No." := 0;
        ReqLine."Routing No." := '';
        ReqLine."Routing Reference No." := 0;
        ReqLine."Operation No." := '';
        ReqLine."Work Center No." := '';

        OnAfterResetReqLineFields(ReqLine);
    end;

    procedure ValidateProdOrderOnReqLine(var ReqLine: Record "Requisition Line")
    var
        Item: Record Item;
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ReqLine.TestField(Type, ReqLine.Type::Item);

        if ProdOrder.Get(ProdOrder.Status::Released, ReqLine."Prod. Order No.") then begin
            ProdOrder.TestField(Blocked, false);
            ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
            ProdOrderLine.SetRange("Prod. Order No.", ReqLine."Prod. Order No.");
            ProdOrderLine.SetRange("Item No.", ReqLine."No.");
            if ProdOrderLine.FindFirst() then begin
                ReqLine."Routing No." := ProdOrderLine."Routing No.";
                ReqLine."Routing Reference No." := ProdOrderLine."Line No.";
                ReqLine."Prod. Order Line No." := ProdOrderLine."Line No.";
                ReqLine."Requester ID" := UserId;
            end;
            Item.Get(ReqLine."No.");
            ReqLine.Validate("Unit of Measure Code", Item."Base Unit of Measure");
        end;
    end;

    procedure InitMfgSetup()
    var
        MfgSetup: Record "Manufacturing Setup";
    begin
        if not MfgSetup.FindFirst() then begin
            MfgSetup.Init();
            MfgSetup.Insert();
        end;
    end;

    procedure TransferFromReqLineToPurchLine(var PurchOrderLine: Record "Purchase Line"; ReqLine: Record "Requisition Line")
    var
        MfgSetup: Record "Manufacturing Setup";
        WorkCenter: Record "Work Center";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferFromReqLineToPurchLine(PurchOrderLine, ReqLine, IsHandled);
        if not IsHandled then begin
            PurchOrderLine."Routing No." := ReqLine."Routing No.";
            PurchOrderLine."Routing Reference No." := ReqLine."Routing Reference No.";
            PurchOrderLine."Operation No." := ReqLine."Operation No.";
            PurchOrderLine.Validate("Work Center No.", ReqLine."Work Center No.");
            if ReqLine."Prod. Order No." <> '' then
                if ReqLine."Work Center No." <> '' then begin
                    OnTransferFromReqLineToPurchLineOnBeforeBeforeAssignOverheadRate(WorkCenter, ReqLine."Order Date");
                    WorkCenter.Get(PurchOrderLine."Work Center No.");
                    if WorkCenter."Unit Cost Calculation" = WorkCenter."Unit Cost Calculation"::Time then begin
                        ProdOrderRtngLine.Get(
                          ProdOrderRtngLine.Status::Released, ReqLine."Prod. Order No.", ReqLine."Routing Reference No.", ReqLine."Routing No.", ReqLine."Operation No.");
                        MfgSetup.Get();
                        CostCalcMgt.GetRndgSetup(GLSetup, Currency, RndgSetupRead);
                        if MfgSetup."Cost Incl. Setup" and (ReqLine.Quantity <> 0) then
                            PurchOrderLine."Overhead Rate" :=
                              Round(
                                WorkCenter."Overhead Rate" *
                                (ProdOrderRtngLine."Setup Time" /
                                 ReqLine.Quantity +
                                 ProdOrderRtngLine."Run Time"),
                                GLSetup."Unit-Amount Rounding Precision")
                        else
                            PurchOrderLine."Overhead Rate" :=
                              Round(
                                WorkCenter."Overhead Rate" * ProdOrderRtngLine."Run Time",
                                GLSetup."Unit-Amount Rounding Precision");
                    end else
                        PurchOrderLine."Overhead Rate" := WorkCenter."Overhead Rate";
                    PurchOrderLine."Indirect Cost %" := WorkCenter."Indirect Cost %";
                    PurchOrderLine."Gen. Prod. Posting Group" := WorkCenter."Gen. Prod. Posting Group";
                    PurchOrderLine.Validate("Direct Unit Cost", ReqLine."Direct Unit Cost");
                end;
        end;

        OnAfterTransferFromReqLineToPurchLine(PurchOrderLine, ReqLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckReceiptOrderStatus(SalesLine: Record "Sales Line"; var Checked: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromReqLineToPurchLine(var PurchOrderLine: Record "Purchase Line"; var ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferFromReqLineToPurchLine(var PurchOrderLine: Record "Purchase Line"; var ReqLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateProdOrderOnPurchLine(var PurchLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferFromReqLineToPurchLineOnBeforeBeforeAssignOverheadRate(var WordCenter: Record "Work Center"; var OrderDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResetReqLineFields(var ReqLine: Record "Requisition Line")
    begin
    end;
}

