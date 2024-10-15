namespace System.Security.AccessControl;

table 9006 "Plan Permission Set"
{
    Caption = 'Plan Permission Set';
    DataPerCompany = false;
    ReplicateData = false;
    ObsoleteState = Removed;
    ObsoleteTag = '23.0';
    ObsoleteReason = 'No longer used.';
    DataClassification = CustomerContent;

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
            CalcFormula = lookup(System.Azure.Identity.Plan.Name where("Plan ID" = field("Plan ID")));
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

