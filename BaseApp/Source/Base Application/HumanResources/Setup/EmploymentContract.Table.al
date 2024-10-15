namespace Microsoft.HumanResources.Setup;

using Microsoft.HumanResources.Employee;

table 5211 "Employment Contract"
{
    Caption = 'Employment Contract';
    DrillDownPageID = "Employment Contracts";
    LookupPageID = "Employment Contracts";
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
        field(3; "No. of Contracts"; Integer)
        {
            CalcFormula = count(Employee where(Status = const(Active),
                                                "Emplymt. Contract Code" = field(Code)));
            Caption = 'No. of Contracts';
            Editable = false;
            FieldClass = FlowField;
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

