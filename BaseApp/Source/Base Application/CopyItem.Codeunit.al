codeunit 730 "Copy Item"
{
    TableNo = Item;

    trigger OnRun()
    var
        CopyItem: Report "Copy Item";
        FirstItemNo: Code[20];
        LastItemNo: Code[20];
    begin
        CopyItem.SetItem(Rec);
        CopyItem.RunModal;
        if CopyItem.IsItemCopied(FirstItemNo, LastItemNo) then
            ShowNotification(Rec, FirstItemNo, LastItemNo);
    end;

    var
        ItemCopiedMsg: Label 'Item %1 was successfully copied.', Comment = '%1 - item number';
        ShowCreatedItemTxt: Label 'Show created item.';
        ShowCreatedItemsTxt: Label 'Show created items.';

    local procedure ShowNotification(Item: Record Item; FirstItemNo: Code[20]; LastItemNo: Code[20])
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ItemCopiedNotification: Notification;
        ShowCreatedActionCaption: Text;
    begin
        ItemCopiedNotification.Id := CreateGuid;
        ItemCopiedNotification.Scope(NOTIFICATIONSCOPE::LocalScope);
        ItemCopiedNotification.SetData('FirstItemNo', FirstItemNo);
        ItemCopiedNotification.SetData('LastItemNo', LastItemNo);
        ItemCopiedNotification.Message(StrSubstNo(ItemCopiedMsg, Item."No."));
        if FirstItemNo = LastItemNo then
            ShowCreatedActionCaption := ShowCreatedItemTxt
        else
            ShowCreatedActionCaption := ShowCreatedItemsTxt;
        ItemCopiedNotification.AddAction(ShowCreatedActionCaption, CODEUNIT::"Copy Item", 'ShowCreatedItems');
        NotificationLifecycleMgt.SendNotification(ItemCopiedNotification, Item.RecordId);
    end;

    procedure ShowCreatedItems(var ItemCopiedNotification: Notification)
    var
        Item: Record Item;
    begin
        Item.SetRange(
          "No.",
          ItemCopiedNotification.GetData('FirstItemNo'),
          ItemCopiedNotification.GetData('LastItemNo'));
        if Item.FindFirst then
            if Item.Count = 1 then
                PAGE.RunModal(PAGE::"Item Card", Item)
            else
                PAGE.RunModal(PAGE::"Item List", Item);
    end;
}

