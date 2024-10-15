namespace System.Security.AccessControl;

using System.Apps;

table 9003 "User Group Permission Set"
{
    Caption = 'User Group Permission Set';
    DataPerCompany = false;
    ReplicateData = false;
#if not CLEAN22
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '25.0';
#endif 
    ObsoleteReason = '[220_UserGroups] The user groups functionality is deprecated. Use security groups (Security Group codeunit) or permission sets directly instead. To learn more, go to https://go.microsoft.com/fwlink/?linkid=2245709.';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User Group Code"; Code[20])
        {
            Caption = 'User Group Code';
            TableRelation = "User Group";
        }
        field(2; "Role ID"; Code[20])
        {
            Caption = 'Permission Set';
            Editable = false;
            TableRelation = "Aggregate Permission Set"."Role ID";
        }
        field(3; "User Group Name"; Text[50])
        {
            CalcFormula = lookup("User Group".Name where(Code = field("User Group Code")));
            Caption = 'User Group Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Role Name"; Text[30])
        {
            CalcFormula = lookup("Permission Set".Name where("Role ID" = field("Role ID")));
            Caption = 'Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "App ID"; Guid)
        {
            Caption = 'App ID';
        }
        field(6; Scope; Option)
        {
            Caption = 'Scope';
            OptionCaption = 'System,Tenant';
            OptionMembers = System,Tenant;
        }
        field(7; "Extension Name"; Text[250])
        {
            CalcFormula = lookup("Published Application".Name where(ID = field("App ID"), "Tenant Visible" = const(true)));
            Caption = 'Extension Name';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "User Group Code", "Role ID", Scope, "App ID")
        {
            Clustered = true;
        }
    }

#if not CLEAN22
    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        MarkUserGroupAsCustomized("User Group Code");
    end;

    trigger OnInsert()
    begin
        MarkUserGroupAsCustomized("User Group Code");
    end;

    trigger OnModify()
    begin
        MarkUserGroupAsCustomized("User Group Code");
    end;

    trigger OnRename()
    begin
        MarkUserGroupAsCustomized("User Group Code");
    end;

    local procedure MarkUserGroupAsCustomized(UserGroupCode: Code[20])
    var
        UserGroup: Record "User Group";
    begin
        if not UserGroup.Get(UserGroupCode) then
            exit;

        UserGroup.Customized := true;
        UserGroup.Modify();
    end;
#endif
}

