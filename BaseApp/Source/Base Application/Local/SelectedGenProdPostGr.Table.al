table 10731 "Selected Gen. Prod. Post. Gr."
{
    Caption = 'Selected Gen. Prod. Post. Gr.';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Gen. Product Posting Groups";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
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

