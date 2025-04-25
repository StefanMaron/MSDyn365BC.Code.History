// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

codeunit 99000866 "Mfg. Requisition Line"
{

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnCleanProdBOMNo', '', true, true)]
    local procedure OnCleanProdBOMNo(var RequisitionLine: Record "Requisition Line")
    begin
        RequisitionLine.Validate("Production BOM No.", '');
        RequisitionLine.Validate("Routing No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnCleanProdOrderNo', '', true, true)]
    local procedure OnCleanProdOrderNo(var RequisitionLine: Record "Requisition Line")
    begin
        RequisitionLine."Prod. Order No." := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnIsProdOrder', '', true, true)]
    local procedure OnIsProdOrder(var RequisitionLine: Record "Requisition Line"; var Result: Boolean)
    begin
        Result := RequisitionLine."Prod. Order No." <> '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnTestProdOrderNo', '', true, true)]
    local procedure OnTestProdOrderNo(var RequisitionLine: Record "Requisition Line")
    begin
        RequisitionLine.TestField("Prod. Order No.", '');
    end;
}