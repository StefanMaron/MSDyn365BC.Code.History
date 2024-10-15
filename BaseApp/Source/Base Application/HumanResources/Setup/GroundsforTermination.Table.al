namespace Microsoft.HumanResources.Setup;

table 5217 "Grounds for Termination"
{
    Caption = 'Grounds for Termination';
    DrillDownPageID = "Grounds for Termination";
    LookupPageID = "Grounds for Termination";
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

