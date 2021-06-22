codeunit 52 "BOM-BOM Component"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Table, 90, 'OnAfterInsertEvent', '', false, false)]
    local procedure UpdateParentItemReplenishmentSystemOnAfterInsertBOMComponent(var Rec: Record "BOM Component"; RunTrigger: Boolean)
    begin
        TryUpdateParentItemReplenishmentSystem(Rec);
    end;

    [EventSubscriber(ObjectType::Table, 90, 'OnAfterDeleteEvent', '', false, false)]
    local procedure UpdateParentItemReplenishmentSystemOnAfterDeleteBOMComponent(var Rec: Record "BOM Component"; RunTrigger: Boolean)
    begin
        if RunTrigger then
            TryUpdateParentItemReplenishmentSystem(Rec);
    end;

    [EventSubscriber(ObjectType::Table, 90, 'OnAfterRenameEvent', '', false, false)]
    local procedure UpdateParentItemReplenishmentSystemOnAfterRenameBOMComponent(var Rec: Record "BOM Component"; var xRec: Record "BOM Component"; RunTrigger: Boolean)
    begin
        if Rec."Parent Item No." <> xRec."Parent Item No." then begin
            TryUpdateParentItemReplenishmentSystem(Rec);
            TryUpdateParentItemReplenishmentSystem(xRec);
        end
    end;

    local procedure TryUpdateParentItemReplenishmentSystem(var BOMComponent: Record "BOM Component")
    var
        Item: Record Item;
    begin
        if BOMComponent.IsTemporary then
            exit;
        if Item.Get(BOMComponent."Parent Item No.") then
            if Item.UpdateReplenishmentSystem then
                Item.Modify(true);
    end;
}

