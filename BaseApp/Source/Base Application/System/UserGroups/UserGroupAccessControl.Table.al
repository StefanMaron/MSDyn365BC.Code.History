namespace System.Security.AccessControl;

using System.Environment;
#if not CLEAN22
using System.Environment.Configuration;
#endif

table 9002 "User Group Access Control"
{
    Caption = 'User Group Access Control';
    DataPerCompany = false;
    Permissions = TableData "Access Control" = rimd;
    ReplicateData = false;
#if not CLEAN22
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '25.0';
#endif 
    ObsoleteReason = '[220_UserGroups] The user groups functionality is deprecated. Use security groups or permission sets directly instead. To learn more, go to https://go.microsoft.com/fwlink/?linkid=2245709.';
    DataClassification = CustomerContent;

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
            CalcFormula = lookup(User."User Name" where("User Security ID" = field("User Security ID")));
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

#if not CLEAN22
    fieldgroups
    {
    }

    procedure AddUserGroupMember(UserGroupCode: Code[20]; UserSecurityID: Guid; SelectedCompany: Text[30])
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
    begin
        UserGroupPermissionSet.SetRange("User Group Code", UserGroupCode);
        if UserGroupPermissionSet.FindSet() then
            repeat
                AddPermissionSetToUser(
                  UserGroupCode, UserSecurityID, SelectedCompany, UserGroupPermissionSet."Role ID", UserGroupPermissionSet."App ID",
                  UserGroupPermissionSet.Scope);
            until UserGroupPermissionSet.Next() = 0;
    end;

    procedure RemoveUserGroupMember(UserGroupCode: Code[20]; UserSecurityID: Guid; SelectedCompany: Text[30])
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
    begin
        UserGroupPermissionSet.SetRange("User Group Code", UserGroupCode);
        if UserGroupPermissionSet.FindSet() then
            repeat
                RemovePermissionSetFromUser(
                  UserGroupCode, UserSecurityID, SelectedCompany, UserGroupPermissionSet."Role ID", UserGroupPermissionSet."App ID",
                  UserGroupPermissionSet.Scope);
            until UserGroupPermissionSet.Next() = 0;
    end;

    procedure AddUserGroupPermissionSet(UserGroupCode: Code[20]; RoleID: Code[20]; AppID: Guid; ItemScope: Integer)
    var
        UserGroupMember: Record "User Group Member";
    begin
        UserGroupMember.SetRange("User Group Code", UserGroupCode);
        if UserGroupMember.FindSet() then
            repeat
                AddPermissionSetToUser(
                  UserGroupCode, UserGroupMember."User Security ID", UserGroupMember."Company Name", RoleID, AppID, ItemScope);
            until UserGroupMember.Next() = 0;
    end;

    procedure RemoveUserGroupPermissionSet(UserGroupCode: Code[20]; RoleID: Code[20]; AppID: Guid; ItemScope: Integer)
    var
        UserGroupMember: Record "User Group Member";
    begin
        UserGroupMember.SetRange("User Group Code", UserGroupCode);
        if UserGroupMember.FindSet() then
            repeat
                RemovePermissionSetFromUser(
                  UserGroupCode, UserGroupMember."User Security ID", UserGroupMember."Company Name", RoleID, AppID, ItemScope);
            until UserGroupMember.Next() = 0;
    end;

    procedure AddPermissionSetToUser(UserGroupCode: Code[20]; UserSecurityID: Guid; SelectedCompany: Text[30]; RoleID: Code[20]; AppID: Guid; ItemScope: Integer)
    var
        AccessControl: Record "Access Control";
        ServerSetting: Codeunit "Server Setting";
        AccessControlExists: Boolean;
        NullGuid: Guid;
    begin
        if Get(UserGroupCode, UserSecurityID, RoleID, SelectedCompany, ItemScope, AppID) then
            exit;

        // Filter on an App ID only when UsePermissionSetsFromExtensions is set to true.
        // The folowing filtering is to try find the correct Access Control since there has been cases of corrupt data,
        // such as System permission sets with NULL GUID-s
        if ServerSetting.GetUsePermissionSetsFromExtensions() then begin
            AccessControl.SetRange("User Security ID", UserSecurityID);
            AccessControl.SetRange("Role ID", RoleID);
            AccessControl.SetRange("Company Name", SelectedCompany);
            AccessControl.SetRange(Scope, ItemScope);

            // SUPER and SECURITY always have null guids
            if RoleID in ['SUPER', 'SECURITY'] then
                AccessControl.SetRange("App ID", NullGuid)
            else
                // If scope is system and App ID is null, filter to non-null App IDs
                if (ItemScope = AccessControl.Scope::System) and IsNullGuid(AppID) then
                    AccessControl.SetFilter("App ID", '<>%1', NullGuid)
                else
                    AccessControl.SetRange("App ID", AppID);

            AccessControlExists := not AccessControl.IsEmpty();
        end else
            AccessControlExists := AccessControl.Get(UserSecurityID, RoleID, SelectedCompany, ItemScope, AppID);

        Reset();
        Init();
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

            // If this is the first assignment via a user group and the user already had a manually defined access control,
            // we add a 'null' record for it.
            if IsEmpty() then
                Insert();
        end;
        "User Group Code" := UserGroupCode;
        Insert();
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
        Delete();
        AccessControlExists := AccessControl.Get(UserSecurityID, RoleID, SelectedCompany, ItemScope, AppID);
        if AccessControlExists then begin
            Reset();
            SetRange("User Security ID", UserSecurityID);
            SetRange("Role ID", RoleID);
            SetRange("Company Name", SelectedCompany);
            SetRange(Scope, ItemScope);
            SetRange("App ID", AppID);
            ReferenceExists := FindLast();
            if not ReferenceExists then
                AccessControl.Delete(true);
            if ReferenceExists and ("User Group Code" = '') then
                Delete();
        end;
    end;
#endif
}

