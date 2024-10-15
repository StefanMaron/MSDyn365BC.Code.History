codeunit 11784 "Purchase Line Handler CZL"
{
    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterAssignItemValues', '', false, false)]
    local procedure TariffNoOnAfterAssignItemValues(var PurchLine: Record "Purchase Line"; Item: Record Item)
    begin
        PurchLine."Tariff No. CZL" := Item."Tariff No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterAssignItemValues', '', false, false)]
    local procedure StatisticIndicationOnAfterAssignItemValues(var PurchLine: Record "Purchase Line"; Item: Record Item)
    begin
        PurchLine."Statistic Indication CZL" := Item."Statistic Indication CZL";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnBeforeGetPurchHeader', '', false, false)]
    local procedure SetPurchaseHeaderArchiveOnBeforeGetPurchHeader(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseHeaderArchive: Record "Purchase Header Archive";
    begin
        // This function should be removed at the same time as the DivideAmount function in Purchase Line table
        PurchaseHeader.SetRange("Document Type", PurchaseLine."Document Type");
        PurchaseHeader.SetRange("No.", PurchaseLine."Document No.");
        if not PurchaseHeader.IsEmpty() then
            exit;

        PurchaseHeaderArchive.SetRange("Document Type", PurchaseLine."Document Type");
        PurchaseHeaderArchive.SetRange("No.", PurchaseLine."Document No.");
        if not PurchaseHeaderArchive.FindFirst() then
            exit;

        PurchaseHeader.TransferFields(PurchaseHeaderArchive);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure RemoveVATCorrectionOnBeforeDeleteEvent(var Rec: Record "Purchase Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        if not RunTrigger then
            exit;
        RemoveVATCorrection(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure RemoveVATCorrectionOnBeforeInsertEvent(var Rec: Record "Purchase Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        if not RunTrigger then
            exit;
        RemoveVATCorrection(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnBeforeModifyEvent', '', false, false)]
    local procedure RemoveVATCorrectionOnBeforeModifyEvent(var Rec: Record "Purchase Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;
        if not RunTrigger then
            exit;
        RemoveVATCorrection(Rec);
    end;

    local procedure RemoveVATCorrection(var PurchaseLine: Record "Purchase Line")
    var
        PurchaseLine2: Record "Purchase Line";
    begin
        // remove vat correction on current line
        if (PurchaseLine."VAT Difference" <> 0) and (PurchaseLine.Quantity <> 0) then begin
            PurchaseLine."VAT Difference" := 0;
            PurchaseLine.UpdateAmounts();
        end;

        // remove vat correction on another lines except the current line
        PurchaseLine2.Reset();
        PurchaseLine2.SetRange("Document Type", PurchaseLine."Document Type");
        PurchaseLine2.SetRange("Document No.", PurchaseLine."Document No.");
        PurchaseLine2.SetFilter("Line No.", '<>%1', PurchaseLine."Line No.");
        PurchaseLine2.SetFilter("VAT Difference", '<>0');
        if PurchaseLine2.FindSet() then
            repeat
                PurchaseLine2."VAT Difference" := 0;
                PurchaseLine2.UpdateAmounts();
                PurchaseLine2.Modify();
            until PurchaseLine2.Next() = 0;
    end;
}