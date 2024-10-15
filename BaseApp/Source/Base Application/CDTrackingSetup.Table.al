table 12410 "CD Tracking Setup"
{
    Caption = 'CD Tracking Setup';
    LookupPageID = "CD Tracking Setup";

    fields
    {
        field(1; "Item Tracking Code"; Code[10])
        {
            Caption = 'Item Tracking Code';
            NotBlank = true;
            TableRelation = "Item Tracking Code";
        }
        field(2; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            NotBlank = true;
            TableRelation = Location;
        }
        field(3; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(21; "CD Info. Must Exist"; Boolean)
        {
            Caption = 'CD Info. Must Exist';
        }
        field(23; "CD Sales Check on Release"; Boolean)
        {
            Caption = 'CD Sales Check on Release';
        }
        field(24; "CD Purchase Check on Release"; Boolean)
        {
            Caption = 'CD Purchase Check on Release';
        }
        field(25; "Allow Temporary CD No."; Boolean)
        {
            Caption = 'Allow Temporary CD No.';
        }
    }

    keys
    {
        key(Key1; "Item Tracking Code", "Location Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TestDelete;
    end;

    trigger OnInsert()
    begin
        TestInsert;
    end;

    var
        Item: Record Item;
        ItemLedgEntry: Record "Item Ledger Entry";
        Text002: Label 'You cannot delete setup because it is used on one or more items.';

    [Scope('OnPrem')]
    procedure TestDelete()
    begin
        Item.Reset();
        Item.SetRange("Item Tracking Code", "Item Tracking Code");
        if Item.Find('-') then
            repeat
                ItemLedgEntry.Reset();
                ItemLedgEntry.SetCurrentKey("Item No.");
                ItemLedgEntry.SetRange("Item No.", Item."No.");
                ItemLedgEntry.SetRange("Location Code", "Location Code");
                if ItemLedgEntry.FindFirst then
                    Error(Text002);
            until Item.Next = 0;
    end;

    [Scope('OnPrem')]
    procedure TestInsert()
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        ItemTrackingCode.Get("Item Tracking Code");
        ItemTrackingCode.TestField("CD Specific Tracking");
    end;
}

