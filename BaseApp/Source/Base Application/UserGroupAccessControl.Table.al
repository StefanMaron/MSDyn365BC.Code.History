table 9002 "User Group Access Control"
{
    Caption = 'User Group Access Control';
    DataPerCompany = false;
    Permissions = TableData "Access Control" = rimd;
    ReplicateData = false;

    fields
    {
        field(1; "User Group Code"; Code[20])
        {
            Caption = 'User Group Code';
            TableRelation = "User Group";
        }
        field(2; "User Security ID"; Guid)
        {
            Caption = 'User Security ID';
            DataClassification = EndUserPseudonymousIdentifiers;
            TableRelation = User;
        }
        field(3; "Role ID"; Code[20])
        {
            Caption = 'Role ID';
            Editable = false;
            TableRelation = "Aggregate Permission Set"."Role ID";
        }
        field(4; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
            TableRelation = Company;
        }
        field(5; "User Name"; Code[50])
        {
            CalcFormula = Lookup (User."User Name" WHERE("User Security ID" = FIELD("User Security ID")));
            Caption = 'User Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; Scope; Option)
        {
            Caption = 'Scope';
            OptionCaption = 'System,Tenant';
            OptionMembers = System,Tenant;
        }
        field(7; "App ID"; Guid)
        {
            Caption = 'App ID';
        }
    }

    keys
    {
        key(Key1; "User Group Code", "User Security ID", "Role ID", "Company Name", Scope, "App ID")
        {
            Clustered = true;
        }
        key(Key2; "User Security ID", "Role ID", "Company Name", Scope, "App ID")
        {
        }
    }

    fieldgroups
    {
    }

    procedure AddUserGroupMember(UserGroupCode: Code[20]; UserSecurityID: Guid; SelectedCompany: Text[30])
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
    begin
        UserGroupPermissionSet.SetRange("User Group Code", UserGroupCode);
        if UserGroupPermissionSet.FindSet then
            repeat
                AddPermissionSetToUser(
                  UserGroupCode, UserSecurityID, SelectedCompany, UserGroupPermissionSet."Role ID", UserGroupPermissionSet."App ID",
                  UserGroupPermissionSet.Scope);
            until UserGroupPermissionSet.Next = 0;
    end;

    procedure RemoveUserGroupMember(UserGroupCode: Code[20]; UserSecurityID: Guid; SelectedCompany: Text[30])
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
    begin
        UserGroupPermissionSet.SetRange("User Group Code", UserGroupCode);
        if UserGroupPermissionSet.FindSet then
            repeat
                RemovePermissionSetFromUser(
                  UserGroupCode, UserSecurityID, SelectedCompany, UserGroupPermissionSet."Role ID", UserGroupPermissionSet."App ID",
                  UserGroupPermissionSet.Scope);
            until UserGroupPermissionSet.Next = 0;
    end;

    procedure AddUserGroupPermissionSet(UserGroupCode: Code[20]; RoleID: Code[20]; AppID: Guid; ItemScope: Integer)
    var
        UserGroupMember: Record "User Group Member";
    begin
        UserGroupMember.SetRange("User Group Code", UserGroupCode);
        if UserGroupMember.FindSet then
            repeat
                AddPermissionSetToUser(
                  UserGroupCode, UserGroupMember."User Security ID", UserGroupMember."Company Name", RoleID, AppID, ItemScope);
            until UserGroupMember.Next = 0;
    end;

    procedure RemoveUserGroupPermissionSet(UserGroupCode: Code[20]; RoleID: Code[20]; AppID: Guid; ItemScope: Integer)
    var
        UserGroupMember: Record "User Group Member";
    begin
        UserGroupMember.SetRange("User Group Code", UserGroupCode);
        if UserGroupMember.FindSet then
            repeat
                RemovePermissionSetFromUser(
                  UserGroupCode, UserGroupMember."User Security ID", UserGroupMember."Company Name", RoleID, AppID, ItemScope);
            until UserGroupMember.Next = 0;
    end;

    procedure AddPermissionSetToUser(UserGroupCode: Code[20]; UserSecurityID: Guid; SelectedCompany: Text[30]; RoleID: Code[20]; AppID: Guid; ItemScope: Integer)
    var
        AccessControl: Record "Access Control";
        AccessControlExists: Boolean;
    begin
        // If this is the first assignment via a user group and the user already had a manually defined access control,
        // we add a 'null' record for it.
        if Get(UserGroupCode, UserSecurityID, RoleID, SelectedCompany, ItemScope, AppID) then
            exit;
        AccessControlExists := AccessControl.Get(UserSecurityID, RoleID, SelectedCompany, ItemScope, AppID);
        Reset;
        Init;
        "User Group Code" := '';
        "User Security ID" := UserSecurityID;
        "Role ID" := RoleID;
        "Company Name" := SelectedCompany;
        "App ID" := AppID;
        Scope := ItemScope;
        if AccessControlExists then begin
            SetRange("User Security ID", UserSecurityID);
            SetRange("Role ID", RoleID);
            SetRange("Company Name", SelectedCompany);
            SetRange(Scope, ItemScope);
            SetRange("App ID", AppID);
            if IsEmpty then
                Insert;
        end;
        "User Group Code" := UserGroupCode;
        Insert;
        if not AccessControlExists then begin
            AccessControl.Init();
            AccessControl."User Security ID" := UserSecurityID;
            AccessControl."Role ID" := RoleID;
            AccessControl."Company Name" := SelectedCompany;
            AccessControl.Scope := ItemScope;
            AccessControl."App ID" := AppID;
            AccessControl.Insert();
        end;
    end;

    procedure RemovePermissionSetFromUser(UserGroupCode: Code[20]; UserSecurityID: Guid; SelectedCompany: Text[30]; RoleID: Code[20]; AppID: Guid; ItemScope: Integer)
    var
        AccessControl: Record "Access Control";
        AccessControlExists: Boolean;
        ReferenceExists: Boolean;
    begin
        // If this is the last assignment via a user group and the user does not have a manually defined access control,
        // we remove the 'null' record for it if it exists.
        if not Get(UserGroupCode, UserSecurityID, RoleID, SelectedCompany, ItemScope, AppID) then
            exit;
        Delete;
        AccessControlExists := AccessControl.Get(UserSecurityID, RoleID, SelectedCompany, ItemScope, AppID);
        if AccessControlExists then begin
            Reset;
            SetRange("User Security ID", UserSecurityID);
            SetRange("Role ID", RoleID);
            SetRange("Company Name", SelectedCompany);
            SetRange(Scope, ItemScope);
            SetRange("App ID", AppID);
            ReferenceExists := FindLast;
            if not ReferenceExists then
                AccessControl.Delete(true);
            if ReferenceExists and ("User Group Code" = '') then
                Delete;
        end;
    end;
}

