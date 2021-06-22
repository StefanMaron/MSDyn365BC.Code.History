table 7505 "Item Attribute Value Mapping"
{
    Caption = 'Item Attribute Value Mapping';

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(3; "Item Attribute ID"; Integer)
        {
            Caption = 'Item Attribute ID';
            TableRelation = "Item Attribute";
        }
        field(4; "Item Attribute Value ID"; Integer)
        {
            Caption = 'Item Attribute Value ID';
            TableRelation = "Item Attribute Value".ID;
        }
    }

    keys
    {
        key(Key1; "Table ID", "No.", "Item Attribute ID")
        {
            Clustered = true;
        }
        key(Key2; "Item Attribute ID", "Item Attribute Value ID")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        ItemAttribute.Get("Item Attribute ID");
        if ItemAttribute.Type = ItemAttribute.Type::Option then
            exit;

        if not ItemAttributeValue.Get("Item Attribute ID", "Item Attribute Value ID") then
            exit;

        ItemAttributeValueMapping.SetRange("Item Attribute ID", "Item Attribute ID");
        ItemAttributeValueMapping.SetRange("Item Attribute Value ID", "Item Attribute Value ID");
        if ItemAttributeValueMapping.Count <> 1 then
            exit;

        ItemAttributeValueMapping := Rec;
        if ItemAttributeValueMapping.Find then
            ItemAttributeValue.Delete();
    end;

    procedure RenameItemAttributeValueMapping(PrevNo: Code[20]; NewNo: Code[20])
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        SetRange("Table ID", DATABASE::Item);
        SetRange("No.", PrevNo);
        if FindSet then
            repeat
                ItemAttributeValueMapping := Rec;
                ItemAttributeValueMapping.Rename("Table ID", NewNo, "Item Attribute ID");
            until Next = 0;
    end;
}

