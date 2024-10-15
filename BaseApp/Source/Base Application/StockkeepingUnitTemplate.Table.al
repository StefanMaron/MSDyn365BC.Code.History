table 31072 "Stockkeeping Unit Template"
{
    Caption = 'Stockkeeping Unit Template';
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '20.0';

    fields
    {
        field(1; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = "Item Category";
        }
        field(3; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            NotBlank = true;
            TableRelation = Location;
        }
        field(10; "Components at Location"; Code[10])
        {
            Caption = 'Components at Location';
            TableRelation = Location;
        }
        field(20; "Replenishment System"; Option)
        {
            Caption = 'Replenishment System';
            InitValue = "From Item Card";
            OptionCaption = 'Purchase,Prod. Order,Transfer,From Item Card';
            OptionMembers = Purchase,"Prod. Order",Transfer,"From Item Card";
        }
        field(30; "Reordering Policy"; Option)
        {
            Caption = 'Reordering Policy';
            InitValue = "From Item Card";
            OptionCaption = ' ,Fixed Reorder Qty.,Maximum Qty.,Order,Lot-for-Lot,From Item Card';
            OptionMembers = " ","Fixed Reorder Qty.","Maximum Qty.","Order","Lot-for-Lot","From Item Card";

            trigger OnValidate()
            begin
                if "Reordering Policy" <> "Reordering Policy"::"Lot-for-Lot" then
                    "Include Inventory" :=
                      ("Reordering Policy" <> "Reordering Policy"::" ") and
                      ("Reordering Policy" <> "Reordering Policy"::Order);
            end;
        }
        field(40; "Include Inventory"; Boolean)
        {
            Caption = 'Include Inventory';
        }
        field(50; "Transfer-from Code"; Code[10])
        {
            Caption = 'Transfer-from Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(60; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
    }

    keys
    {
        key(Key1; "Item Category Code", "Location Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
