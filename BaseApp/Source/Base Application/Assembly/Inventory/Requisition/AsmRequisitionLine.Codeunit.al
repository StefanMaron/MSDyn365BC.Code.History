// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using Microsoft.Assembly.Document;

codeunit 923 "Asm. Requisition Line"
{
    var
        NoAssemblyHeaderErr: Label 'There is no Assembly Header for this line.';

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnGetDimFromRefOrderLineElseCase', '', false, false)]
    local procedure OnGetDimFromRefOrderLineElseCase(var RequisitionLine: Record "Requisition Line"; DimSetIDArr: array[10] of Integer; i: Integer)
    var
        AsmHeader: Record "Assembly Header";
    begin
        case RequisitionLine."Ref. Order Type" of
            RequisitionLine."Ref. Order Type"::Assembly:
                if AsmHeader.Get(AsmHeader."Document Type"::Order, RequisitionLine."Ref. Order No.") then
                    DimSetIDArr[i] := AsmHeader."Dimension Set ID";
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnLookupRefOrderNoElseCase', '', false, false)]
    local procedure OnLookupRefOrderNoElseCase(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyOrder: Page "Assembly Order";
    begin
        case RequisitionLine."Ref. Order Type" of
            RequisitionLine."Ref. Order Type"::Assembly:
                if AssemblyHeader.Get(RequisitionLine."Ref. Order Status", RequisitionLine."Ref. Order No.") then begin
                    AssemblyOrder.SetRecord(AssemblyHeader);
                    AssemblyOrder.RunModal();
                end else
                    Message(NoAssemblyHeaderErr);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnValidateReplenishmentSystemCaseElse', '', false, false)]
    local procedure OnValidateReplenishmentSystemCaseElse(var RequisitionLine: Record "Requisition Line")
    begin
        case RequisitionLine."Replenishment System" of
            RequisitionLine."Replenishment System"::Assembly:
                RequisitionLine.SetReplenishmentSystemFromAssembly();
        end;
    end;
}