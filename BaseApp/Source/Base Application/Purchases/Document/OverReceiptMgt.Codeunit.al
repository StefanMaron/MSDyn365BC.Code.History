﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Vendor;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Request;
using System.Environment.Configuration;

codeunit 8510 "Over-Receipt Mgt."
{
    trigger OnRun()
    begin

    end;

    var
        OverReceiptQuantityErr: Label 'You cannot enter more than %1 in the Over-Receipt Quantity field.';
        OverReceiptNotificationTxt: Label 'An over-receipt quantity is recorded on purchase order %1.', Comment = '%1 - document number';

    procedure IsOverReceiptAllowed() OverReceiptAllowed: Boolean
    begin
        OverReceiptAllowed := true;
        OnIsOverReceiptAllowed(OverReceiptAllowed);
    end;

    procedure IsQuantityUpdatedFromWarehouseOverReceipt(PurchaseLine: Record "Purchase Line"): Boolean
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WhseManagement: Codeunit "Whse. Management";
    begin
        if not IsOverReceiptAllowed() then
            exit(false);
        WhseManagement.SetSourceFilterForWhseRcptLine(
            WarehouseReceiptLine, Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.", true);
        if not WarehouseReceiptLine.FindFirst() then
            exit(false);
        exit(PurchaseLine.Quantity = WarehouseReceiptLine.Quantity);
    end;

    procedure IsQuantityUpdatedFromInvtPutAwayOverReceipt(PurchaseLine: Record "Purchase Line"): Boolean
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseManagement: Codeunit "Whse. Management";
    begin
        if not IsOverReceiptAllowed() then
            exit(false);
        WhseManagement.SetSourceFilterForWhseActivityLine(
            WarehouseActivityLine, Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.", true);
        WarehouseActivityLine.CalcSums(Quantity);
        exit(PurchaseLine.Quantity = WarehouseActivityLine.Quantity);
    end;

    procedure UpdatePurchaseLineOverReceiptQuantityFromWarehouseReceiptLine(WarehouseReceiptLine: Record "Warehouse Receipt Line")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if not IsOverReceiptAllowed() then
            exit;
        if PurchaseLine.Get(WarehouseReceiptLine."Source Subtype", WarehouseReceiptLine."Source No.", WarehouseReceiptLine."Source Line No.") then begin
            PurchaseLine.Validate("Over-Receipt Code", WarehouseReceiptLine."Over-Receipt Code");
            PurchaseLine.Validate("Over-Receipt Quantity", WarehouseReceiptLine."Over-Receipt Quantity");
            PurchaseLine.Modify();
        end;
    end;

    procedure UpdatePurchaseLineOverReceiptQuantityFromWarehouseActivityLine(WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if not IsOverReceiptAllowed() then
            exit;

        PurchaseLine.SetLoadFields(PurchaseLine."Over-Receipt Code", PurchaseLine."Over-Receipt Quantity");
        if PurchaseLine.Get(WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.", WarehouseActivityLine."Source Line No.") then begin
            WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type");
            WarehouseActivityLine.SetRange("No.", WarehouseActivityLine."No.");
            WarehouseActivityLine.SetSourceFilter(
              WarehouseActivityLine."Source Type", WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.",
              WarehouseActivityLine."Source Line No.", 0, false);
            WarehouseActivityLine.CalcSums("Over-Receipt Quantity");

            if (PurchaseLine."Over-Receipt Code" <> WarehouseActivityLine."Over-Receipt Code") or (PurchaseLine."Over-Receipt Quantity" <> WarehouseActivityLine."Over-Receipt Quantity") then begin
                PurchaseLine.Validate("Over-Receipt Code", WarehouseActivityLine."Over-Receipt Code");
                PurchaseLine.Validate("Over-Receipt Quantity", WarehouseActivityLine."Over-Receipt Quantity");
                PurchaseLine.Modify();
            end;
        end;
    end;

    procedure VerifyOverReceiptQuantity(PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line")
    var
        OverReceiptCode: Record "Over-Receipt Code";
        UoMMgt: Codeunit "Unit of Measure Management";
        OverReceiptQtyBase: Decimal;
        LineBaseQty: Decimal;
        MaxOverReceiptQtyAllowed: Decimal;
        IsHandled: Boolean;
        ShouldCallError: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyOverReceiptQuantity(PurchaseLine, xPurchaseLine, IsHandled);
        if IsHandled then
            exit;

        if not IsOverReceiptAllowed() then
            exit;
        OverReceiptCode.Get(PurchaseLine."Over-Receipt Code");
        OverReceiptQtyBase := UOMMgt.CalcBaseQty(PurchaseLine."Over-Receipt Quantity", PurchaseLine."Qty. per Unit of Measure");
        LineBaseQty := UoMMgt.CalcBaseQty(xPurchaseLine.Quantity - xPurchaseLine."Over-Receipt Quantity", xPurchaseLine."Qty. per Unit of Measure");
        MaxOverReceiptQtyAllowed := UOMMgt.RoundQty(LineBaseQty / 100 * OverReceiptCode."Over-Receipt Tolerance %");

        ShouldCallError := OverReceiptQtyBase > MaxOverReceiptQtyAllowed;
        OnVerifyOverReceiptQuantityOnAfterCalcShouldCallError(PurchaseLine, OverReceiptQtyBase, MaxOverReceiptQtyAllowed, ShouldCallError);
        if ShouldCallError then
            Error(OverReceiptQuantityErr, MaxOverReceiptQtyAllowed);
    end;

    procedure GetDefaultOverReceiptCode(PurchaseLine: Record "Purchase Line") DefaultOverReceiptCode: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        OverReceiptCode: Record "Over-Receipt Code";
        IsHandled: Boolean;
    begin
        DefaultOverReceiptCode := '';
        OnGetDefaultOverReceiptCode(PurchaseLine, DefaultOverReceiptCode, IsHandled);
        if IsHandled then
            exit;

        Item.Get(PurchaseLine."No.");
        if Item."Over-Receipt Code" <> '' then begin
            DefaultOverReceiptCode := Item."Over-Receipt Code";
            exit;
        end;

        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        if Vendor."Over-Receipt Code" <> '' then begin
            DefaultOverReceiptCode := Vendor."Over-Receipt Code";
            exit;
        end;

        OverReceiptCode.SetRange(Default, true);
        if OverReceiptCode.FindFirst() then
            DefaultOverReceiptCode := OverReceiptCode.Code;
    end;

    procedure RecallOverReceiptNotification(PurchaseHeaderRecordId: RecordId)
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        NotificationLifecycleMgt.RecallNotificationsForRecord(PurchaseHeaderRecordId, false);
    end;

    local procedure ShowOverReceiptNotification(PurchaseHeaderRecordId: RecordId; NotificationMessage: Text)
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        OverReceiptNotification: Notification;
    begin
        OverReceiptNotification.Id := GetOverReceiptNotificationId();
        OverReceiptNotification.Scope(NotificationScope::LocalScope);
        OverReceiptNotification.Message(NotificationMessage);
        NotificationLifecycleMgt.SendNotification(OverReceiptNotification, PurchaseHeaderRecordId);
    end;

    procedure ShowOverReceiptNotificationFromLine(DocumentNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        if not IsOverReceiptAllowed() then
            exit;
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, DocumentNo);
        ShowOverReceiptNotification(PurchaseHeader.RecordId(), StrSubstNo(OverReceiptNotificationTxt, PurchaseHeader."No."));
    end;

    procedure ShowOverReceiptNotificationFromOrder(DocumentNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        if not IsOverReceiptAllowed() then
            exit;
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, DocumentNo);
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetFilter("Over-Receipt Quantity", '<>0');
        if not PurchaseLine.IsEmpty() then
            ShowOverReceiptNotification(PurchaseHeader.RecordId(), StrSubstNo(OverReceiptNotificationTxt, PurchaseHeader."No."));
    end;

    local procedure GetOverReceiptNotificationId(): Guid
    begin
        exit('ea49207f-4275-45d1-804e-508dea5ae8dc');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyOverReceiptQuantity(PurchaseLine: Record "Purchase Line"; xPurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsOverReceiptAllowed(var OverReceiptAllowed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDefaultOverReceiptCode(PurchaseLine: Record "Purchase Line"; var DefaultOverReceipCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnVerifyOverReceiptQuantityOnAfterCalcShouldCallError(PurchaseLine: Record "Purchase Line"; OverReceiptQtyBase: Decimal; MaxOverReceiptQtyAllowed: Decimal; var ShouldCallError: Boolean)
    begin
    end;
}
