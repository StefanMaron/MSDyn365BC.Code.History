namespace Microsoft.Manufacturing.Setup;

table 99000762 Scrap
{
    Caption = 'Scrap';
    DrillDownPageID = "Scrap Codes";
    LookupPageID = "Scrap Codes";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
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

