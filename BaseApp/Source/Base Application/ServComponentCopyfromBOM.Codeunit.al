codeunit 5921 "ServComponent-Copy from BOM"
{
    TableNo = "Service Item";

    trigger OnRun()
    begin
        ServItem.Get("No.");
        ServItem.TestField("Item No.");

        ServItemComponent.LockTable();
        ServItemComponent.Reset();
        ServItemComponent.SetRange(Active, true);
        ServItemComponent.SetRange("Parent Service Item No.", ServItem."No.");
        if ServItemComponent.FindLast then
            LineNo := ServItemComponent."Line No."
        else
            LineNo := 0;

        BOMComp.SetCurrentKey("Parent Item No.", "Line No.");
        BOMComp.SetRange("Parent Item No.", ServItem."Item No.");
        BOMComp.SetRange(Type, BOMComp.Type::Item);
        if BOMComp.Find('-') then begin
            repeat
                if BOMComp."Quantity per" <> Round(BOMComp."Quantity per", 1) then
                    Error(Text001, ServItem.TableCaption, BOMComp.FieldCaption("Quantity per"));
                for Index := 1 to BOMComp."Quantity per" do begin
                    LineNo := LineNo + 10000;
                    Item.Get(BOMComp."No.");
                    Clear(ServItemComponent);
                    ServItemComponent.Active := true;
                    ServItemComponent.Init();
                    ServItemComponent."Parent Service Item No." := ServItem."No.";
                    ServItemComponent."Line No." := LineNo;
                    ServItemComponent.Type := ServItemComponent.Type::Item;
                    ServItemComponent."No." := BOMComp."No.";
                    ServItemComponent."Variant Code" := BOMComp."Variant Code";
                    ServItemComponent."Date Installed" := ServItem."Installation Date";
                    ServItemComponent.Description := Item.Description;
                    ServItemComponent."Description 2" := Item."Description 2";
                    ServItemComponent."From Line No." := 0;
                    if not ServItemComponent.Insert() then
                        ServItemComponent.Modify();
                end;
            until BOMComp.Next = 0;
        end else
            Error(
              Text000,
              BOMComp.TableCaption, ServItem.FieldCaption("Item No."), ServItem."Item No.");
    end;

    var
        Text000: Label '%1 for %2 %3 cannot be found.';
        ServItem: Record "Service Item";
        BOMComp: Record "BOM Component";
        ServItemComponent: Record "Service Item Component";
        Item: Record Item;
        LineNo: Integer;
        Index: Integer;
        Text001: Label 'You cannot copy the component list for this %1 from BOM. The %2 of one or more BOM components is not a whole number.';
}

