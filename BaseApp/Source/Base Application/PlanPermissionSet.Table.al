table 9006 "Plan Permission Set"
{
    Caption = 'Plan Permission Set';
    DataPerCompany = false;
    ReplicateData = false;

    fields
    {
        field(1; "Plan ID"; Guid)
        {
            Caption = 'Plan ID';
        }
        field(2; "Permission Set ID"; Code[20])
        {
            Caption = 'Permission Set ID';
        }
        field(3; "Plan Name"; Text[50])
        {
            CalcFormula = Lookup (Plan.Name WHERE("Plan ID" = FIELD("Plan ID")));
            Caption = 'Plan Name';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Plan ID", "Permission Set ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

