table 9006 "Plan Permission Set"
{
    Caption = 'Plan Permission Set';
    DataPerCompany = false;
    ReplicateData = false;
#if not CLEAN20
    ObsoleteState = Pending;
    ObsoleteTag = '20.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '23.0';
#endif 
    ObsoleteReason = 'No longer used.';

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
            CalcFormula = Lookup(Plan.Name WHERE("Plan ID" = FIELD("Plan ID")));
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

