table 7112 "Analysis Line Template"
{
    Caption = 'Analysis Line Template';
    DataCaptionFields = Name, Description;
    LookupPageID = "Analysis Line Templates";
    ReplicateData = true;

    fields
    {
        field(1; "Analysis Area"; Option)
        {
            Caption = 'Analysis Area';
            OptionCaption = 'Sales,Purchase,Inventory';
            OptionMembers = Sales,Purchase,Inventory;
        }
        field(2; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(3; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(4; "Default Column Template Name"; Code[10])
        {
            Caption = 'Default Column Template Name';
            TableRelation = "Analysis Column Template".Name WHERE("Analysis Area" = FIELD("Analysis Area"));
        }
        field(5; "Item Analysis View Code"; Code[10])
        {
            Caption = 'Item Analysis View Code';
            TableRelation = "Item Analysis View".Code WHERE("Analysis Area" = FIELD("Analysis Area"));
        }
    }

    keys
    {
        key(Key1; "Analysis Area", Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ItemSchedLine: Record "Analysis Line";
    begin
        ItemSchedLine.SetRange("Analysis Area", "Analysis Area");
        ItemSchedLine.SetRange("Analysis Line Template Name", Name);
        ItemSchedLine.DeleteAll(true);
    end;
}

