namespace Microsoft.Manufacturing.Setup;

table 99000750 "Work Shift"
{
    Caption = 'Work Shift';
    DrillDownPageID = "Work Shifts";
    LookupPageID = "Work Shifts";
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

