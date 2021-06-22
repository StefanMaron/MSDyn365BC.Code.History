table 1271 "OCR Service Document Template"
{
    Caption = 'OCR Service Document Template';
    DataCaptionFields = "Code", Name;
    DrillDownPageID = "OCR Service Document Templates";
    LookupPageID = "OCR Service Document Templates";
    ReplicateData = true;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
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

