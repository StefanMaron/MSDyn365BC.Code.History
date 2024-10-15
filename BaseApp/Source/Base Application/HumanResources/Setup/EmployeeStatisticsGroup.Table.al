namespace Microsoft.HumanResources.Setup;

table 5212 "Employee Statistics Group"
{
    Caption = 'Employee Statistics Group';
    DrillDownPageID = "Employee Statistics Groups";
    LookupPageID = "Employee Statistics Groups";
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

