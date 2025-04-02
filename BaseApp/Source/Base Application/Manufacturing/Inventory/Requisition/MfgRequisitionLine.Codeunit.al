// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

codeunit 99000866 "Mfg. Requisition Line"
{

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnCleanProdBOMNo', '', false, false)]
    local procedure OnCleanProdBOMNo(var RequisitionLine: Record "Requisition Line")
    begin
        RequisitionLine.Validate("Production BOM No.", '');
        RequisitionLine.Validate("Routing No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnCleanProdOrderNo', '', false, false)]
    local procedure OnCleanProdOrderNo(var RequisitionLine: Record "Requisition Line")
    begin
        RequisitionLine."Prod. Order No." := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnIsProdOrder', '', false, false)]
    local procedure OnIsProdOrder(var RequisitionLine: Record "Requisition Line"; var Result: Boolean)
    begin
        Result := RequisitionLine."Prod. Order No." <> '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnTestProdOrderNo', '', false, false)]
    local procedure OnTestProdOrderNo(var RequisitionLine: Record "Requisition Line")
    begin
        RequisitionLine.TestField("Prod. Order No.", '');
    end;
}