table 5329 "CRM Redirect"
{
    Caption = 'CRM Redirect';

    fields
    {
        field(1; "No."; Code[10])
        {
            Caption = 'No.';
        }
        field(2; "Filter"; Text[128])
        {
            CalcFormula = Lookup (Customer.Name);
            Caption = 'Filter';
            Description = 'Only to be used for passthrough of URL parameters';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

