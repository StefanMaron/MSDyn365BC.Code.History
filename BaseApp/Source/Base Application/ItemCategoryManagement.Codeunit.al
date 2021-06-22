codeunit 5722 "Item Category Management"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        TempItemCategory: Record "Item Category" temporary;

    [EventSubscriber(ObjectType::Table, 5722, 'OnAfterRenameEvent', '', false, false)]
    local procedure UpdatedPresentationOrderOnAfterRenameItemCategory(var Rec: Record "Item Category"; var xRec: Record "Item Category"; RunTrigger: Boolean)
    begin
        UpdatePresentationOrder;
    end;

    [EventSubscriber(ObjectType::Table, 5722, 'OnAfterModifyEvent', '', false, false)]
    local procedure UpdatePresentationOrderOnAfterModifyItemCategory(var Rec: Record "Item Category"; var xRec: Record "Item Category"; RunTrigger: Boolean)
    var
        NewParentItemCategory: Record "Item Category";
    begin
        if not Rec.IsTemporary then
            if xRec."Parent Category" <> Rec."Parent Category" then begin
                UpdatePresentationOrder;
                if NewParentItemCategory.Get(Rec."Parent Category") then
                    Rec.Validate(Indentation, NewParentItemCategory.Indentation + 1)
                else
                    Rec.Validate(Indentation, 0);
                Rec.Modify();
            end;
    end;

    [EventSubscriber(ObjectType::Table, 5722, 'OnAfterInsertEvent', '', false, false)]
    local procedure UpdatePresentationOrdOnAfterInsertItemCategory(var Rec: Record "Item Category"; RunTrigger: Boolean)
    var
        NewParentItemCategory: Record "Item Category";
    begin
        if not Rec.IsTemporary then begin
            UpdatePresentationOrder;
            if NewParentItemCategory.Get(Rec."Parent Category") then begin
                Rec.Validate(Indentation, NewParentItemCategory.Indentation + 1);
                Rec.Modify();
            end;
        end;
    end;

    procedure UpdatePresentationOrder()
    var
        ItemCategory: Record "Item Category";
    begin
        TempItemCategory.Reset();
        TempItemCategory.DeleteAll();

        // This is to cleanup wrong created blank entries created by an import mistake
        if ItemCategory.Get('') then
            ItemCategory.Delete();

        if ItemCategory.FindSet(false, false) then
            repeat
                TempItemCategory.TransferFields(ItemCategory);
                TempItemCategory.Insert();
            until ItemCategory.Next = 0;
        UpdatePresentationOrderIterative;
    end;

    local procedure UpdatePresentationOrderIterative()
    var
        ItemCategory: Record "Item Category";
        TempStack: Record TempStack temporary;
        TempCurItemCategory: Record "Item Category" temporary;
        CurItemCategoryID: RecordID;
        PresentationOrder: Integer;
        Indentation: Integer;
        HasChildren: Boolean;
    begin
        PresentationOrder := 0;

        TempCurItemCategory.Copy(TempItemCategory, true);

        TempItemCategory.SetCurrentKey("Parent Category");
        TempItemCategory.Ascending(false);
        TempItemCategory.SetRange("Parent Category", '');
        if TempItemCategory.FindSet(false, false) then
            repeat
                TempStack.Push(TempItemCategory.RecordId);
            until TempItemCategory.Next = 0;

        while TempStack.Pop(CurItemCategoryID) do begin
            TempCurItemCategory.Get(CurItemCategoryID);
            HasChildren := false;

            TempItemCategory.SetRange("Parent Category", TempCurItemCategory.Code);
            if TempItemCategory.FindSet(false, false) then
                repeat
                    TempStack.Push(TempItemCategory.RecordId);
                    HasChildren := true;
                until TempItemCategory.Next = 0;

            if TempCurItemCategory."Parent Category" <> '' then begin
                TempItemCategory.Get(TempCurItemCategory."Parent Category");
                Indentation := TempItemCategory.Indentation + 1;
            end else
                Indentation := 0;
            PresentationOrder := PresentationOrder + 1;

            if (TempCurItemCategory."Presentation Order" <> PresentationOrder) or
               (TempCurItemCategory.Indentation <> Indentation) or (TempCurItemCategory."Has Children" <> HasChildren)
            then begin
                ItemCategory.Get(TempCurItemCategory.Code);
                ItemCategory.Validate("Presentation Order", PresentationOrder);
                ItemCategory.Validate(Indentation, Indentation);
                ItemCategory.Validate("Has Children", HasChildren);
                ItemCategory.Modify();
                TempItemCategory.Get(TempCurItemCategory.Code);
                TempItemCategory.Validate("Presentation Order", PresentationOrder);
                TempItemCategory.Validate(Indentation, Indentation);
                TempItemCategory.Validate("Has Children", HasChildren);
                TempItemCategory.Modify();
            end;
        end;
    end;

    procedure DoesValueExistInItemCategories(Text: Code[20]; var ItemCategory: Record "Item Category"): Boolean
    begin
        ItemCategory.Reset();
        ItemCategory.SetFilter(Code, '@' + Text);
        exit(ItemCategory.FindSet);
    end;
}

