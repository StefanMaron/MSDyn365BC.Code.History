table 27004 "CFDI Export Code"
{
    DrillDownPageID = "CFDI Export Codes";
    LookupPageID = "CFDI Export Codes";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(3; "Foreign Trade"; Boolean)
        {
            Caption = 'Foreign Trade';	
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

