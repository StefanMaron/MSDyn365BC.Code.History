namespace Microsoft.HumanResources.Setup;

table 5210 "Cause of Inactivity"
{
    Caption = 'Cause of Inactivity';
    DrillDownPageID = "Causes of Inactivity";
    LookupPageID = "Causes of Inactivity";
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

