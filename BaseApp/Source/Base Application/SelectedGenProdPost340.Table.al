table 10733 "Selected Gen. Prod. Post. 340"
{
    Caption = 'Selected Gen. Prod. Post. 340';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Gen. Product Posting Groups";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

