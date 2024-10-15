namespace System.Security.AccessControl;

#pragma warning disable AL0792
using System.Azure.Identity;
#pragma warning restore AL0792

table 9007 "User Group Plan"
{
    Caption = 'User Group Plan';
    DataPerCompany = false;
    ReplicateData = false;
#if not CLEAN22
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '25.0';
#endif 
    ObsoleteReason = '[220_UserGroups] The user groups functionality is deprecated. Default permission sets per plan are defined using the Plan Configuration codeunit. To learn more, go to https://go.microsoft.com/fwlink/?linkid=2245709.';

    fields
    {
        field(1; "Plan ID"; Guid)
        {
            Caption = 'Plan ID';
            TableRelation = Plan."Plan ID";
        }
        field(2; "User Group Code"; Code[20])
        {
            Caption = 'User Group Code';
            TableRelation = "User Group".Code;
        }
        field(10; "Plan Name"; Text[50])
        {
            CalcFormula = Lookup(Plan.Name where("Plan ID" = field("Plan ID")));
            Caption = 'Plan Name';
            FieldClass = FlowField;
        }
        field(11; "User Group Name"; Text[50])
        {
            CalcFormula = Lookup("User Group".Name where(Code = field("User Group Code")));
            Caption = 'User Group Name';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Plan ID", "User Group Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

