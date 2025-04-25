namespace Microsoft.Manufacturing.Integration;

using Microsoft.Finance.Dimension;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Reports;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;

codeunit 99000789 "Mfg. Purchase Document Mgt."
{
    var
        DimMgt: Codeunit DimensionManagement;
        CannotDefineItemTrackingErr: Label 'You cannot define item tracking on this line because it is linked to production order %1.', Comment = '%1 - production order number';
        CannotChangePurchaseOrderErr: Label 'You cannot change %1 because this purchase order is associated with %2 %3.', Comment = '%1 - type, %2 - production order, %3 - number';

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterInitPurchaseLineDefaultDimSource', '', true, true)]
    local procedure OnAfterInitPurchaseLineDefaultDimSource(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; SourcePurchaseLine: Record "Purchase Line")
    begin
        DimMgt.AddDimSource(DefaultDimSource, Database::"Work Center", SourcePurchaseLine."Work Center No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterInitDefaultDimensionSources', '', true, true)]
    local procedure OnAfterInitDefaultDimensionSources(var PurchaseLine: Record "Purchase Line"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
        DimMgt.AddDimSource(DefaultDimSource, Database::"Work Center", PurchaseLine."Work Center No.", FieldNo = PurchaseLine.FieldNo("Work Center No."));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnIsProdOrder', '', true, true)]
    local procedure OnIsProdOrder(var PurchaseLine: Record "Purchase Line"; var Result: Boolean)
    begin
        Result := PurchaseLine."Prod. Order No." <> '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnIsSubcontractingCreditMemo', '', true, true)]
    local procedure OnIsSubcontractingCreditMemo(var PurchaseLine: Record "Purchase Line"; var Result: Boolean)
    begin
        if (PurchaseLine."Document Type" = PurchaseLine."Document Type"::"Credit Memo") and PurchaseLine.IsProdOrder() and
           (PurchaseLine."Operation No." <> '') and (PurchaseLine."Work Center No." <> '') then
            Result := true
        else
            Result := false;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnOpenItemTrackingLinesOnAfterCheck', '', true, true)]
    local procedure OnOpenItemTrackingLinesOnAfterCheck(var PurchaseLine: Record "Purchase Line")
    begin
        if PurchaseLine."Prod. Order No." <> '' then
            Error(CannotDefineItemTrackingErr, PurchaseLine."Prod. Order No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterCheckAssosiatedProdOrder', '', true, true)]
    local procedure OnAfterCheckAssosiatedProdOrder(var PurchaseLine: Record "Purchase Line")
    begin
        if PurchaseLine."Prod. Order No." <> '' then
            Error(CannotChangePurchaseOrderErr, PurchaseLine.FieldCaption(Type), PurchaseLine.FieldCaption("Prod. Order No."), PurchaseLine."Prod. Order No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnTestProdOrderNo', '', true, true)]
    local procedure OnTestProdOrderNo(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.TestField("Prod. Order No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Inv. Line", 'OnGetItemLedgEntryOnShouldExit', '', true, true)]
    local procedure OnGetItemLedgEntryOnShouldExit(var PurchInvLine: Record "Purch. Inv. Line"; var ShouldExit: Boolean);
    begin
        if PurchInvLine."Work Center No." <> '' then
            ShouldExit := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purchase-Post Prepayments", 'OnCreateDimensionsOnAfterAddDimSources', '', true, true)]
    local procedure OnCreateDimensionsOnAfterAddDimSources(var PurchaseLine: Record "Purchase Line"; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
        DimMgt.AddDimSource(DefaultDimSource, Database::"Work Center", PurchaseLine."Work Center No.");
    end;

    [EventSubscriber(ObjectType::Report, Report::"Purchase Document - Test", 'OnBeforeCheckDimValuePostingLine', '', true, true)]
    local procedure OnBeforeCheckDimValuePostingLine(var PurchaseLine: Record "Purchase Line"; var TableID: array[10] of Integer; var No: array[10] of Code[20]);
    begin
        TableID[3] := Database::"Work Center";
        No[3] := PurchaseLine."Work Center No.";
    end;

}
