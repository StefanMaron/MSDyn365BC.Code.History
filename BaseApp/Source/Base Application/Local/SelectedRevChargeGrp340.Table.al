table 10734 "Selected Rev. Charge Grp. 340"
{
    Caption = 'Selected Rev. Charge Grp. 340';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Gen. Product Posting Groups";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[50])
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

