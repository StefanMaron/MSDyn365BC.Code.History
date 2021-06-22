table 7111 "Analysis Report Name"
{
    Caption = 'Analysis Report Name';
    DataCaptionFields = Name, Description;
    LookupPageID = "Analysis Report Names";

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
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "Analysis Line Template Name"; Code[10])
        {
            Caption = 'Analysis Line Template Name';
            TableRelation = "Analysis Line Template".Name WHERE("Analysis Area" = FIELD("Analysis Area"));
        }
        field(5; "Analysis Column Template Name"; Code[10])
        {
            Caption = 'Analysis Column Template Name';
            TableRelation = "Analysis Column Template".Name WHERE("Analysis Area" = FIELD("Analysis Area"));
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
}

