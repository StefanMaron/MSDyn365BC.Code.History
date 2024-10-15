table 27007 "CFDI Transport Operator"
{
    DrillDownPageID = "CFDI Transport Operators";
    LookupPageID = "CFDI Transport Operators";

    fields
    {
        field(1; "Document Table ID"; Integer)
        {
            Caption = 'Document Table ID';
        }
        field(2; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionMembers = Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(4; "Operator Code"; Code[20])
        {
            Caption = 'Operator Code';
            TableRelation = Employee;
        }
        field(5; "Operator Name"; Text[30])
        {
            Caption = 'Operator Name';
            CalcFormula = Lookup (Employee.Initials WHERE ("No." = FIELD ("Operator Code")));
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Document Table ID", "Document Type", "Document No.", "Operator Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

