codeunit 132864 "User Groups Data Setup"
{
    Subtype = Upgrade;

    var
        BaseAppAppIdLbl: Label '437dbf0e-84ff-417a-965d-ed2bb9650972';
        SystemApplicationAppIdLbl: Label '4846d32b-e7ca-4c4c-94e0-3eee0eccd715';
        TestUserSecId1Lbl: Label '24b82390-152d-40d8-8ccd-e85a9e087cb9';
        TestUserSecId2Lbl: Label '96923896-daad-4782-b4f1-893f0c20ad5e';
        TestUserSecId3Lbl: Label 'f781c995-3386-4f55-9b07-a3902a70acaa';
        NoPermissionsNoMembersUserGroupCodeTxt: Label 'UG1';
        PermissionsButNoMembersUserGroupCodeTxt: Label 'UG2';
        NoPermissionsButWithMembersUserGroupCodeTxt: Label 'UG3';
        PermissionsAnd1MemberUserGroupCodeTxt: Label 'UG4';
        PermissionsAnd2MembersUserGroupCodeTxt: Label 'UG5';
        ExcelExportActionUserGroupTxt: Label 'EXCEL EXPORT ACTION';
        TestPlanIdLbl: Label '8d2edf83-4f9f-4346-9184-f1aa4b62d598';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Test Data Setup Mgt.", 'OnSetupDataPerDatabase', '', false, false)]
    local procedure OnSetupDataPerDatabaseSubscriber()
    begin
        CleanupUserGroups();
        SetupUserGroupPermissionSetRecords();
        SetupTestUserGroupsForMigration();
        SetupSuperUser();
    end;

    local procedure SetupSuperUser()
    var
        User: Record User;
        AccessControl: Record "Access Control";
    begin
        // The system needs to have at least one user with SUPER when syncing apps after the technical upgrade.
        // Since the upgrade is run on behalf of the system user, we cannot just run the "Users - Create Super User" codeunit.
        User."User Security ID" := CreateGuid();
        User."User Name" := 'Test';
        User."Windows Security ID" := 'Test Windows ID';
        User.Insert(true);

        // Add SUPER, as there must be at least one user with SUPER in the system
        AccessControl."User Security ID" := User."User Security ID";
        AccessControl."Role ID" := 'SUPER';
        AccessControl.Insert(true);
    end;

    local procedure CleanupUserGroups()
    var
        UserGroup: Record "User Group";
        UserGroupPermissionSet: Record "User Group Permission Set";
        UserGroupAccessControl: Record "User Group Access Control";
        UserGroupMember: Record "User Group Member";
        UserGroupPlan: Record "User Group Plan";
    begin
        UserGroupAccessControl.DeleteAll();
        UserGroupPermissionSet.DeleteAll();
        UserGroupMember.DeleteAll();
        UserGroupPlan.DeleteAll();
        UserGroup.DeleteAll();
    end;

    local procedure SetupTestUserGroupsForMigration()
    var
        UserGroup: Record "User Group";
        UserGroupMember: Record "User Group Member";
        UserGroupPermissionSet: Record "User Group Permission Set";
        UserGroupPlan: Record "User Group Plan";
        UserGroupUpgradeLibrary: Codeunit "Upgrade Plan Permissions";
    begin
        // Create user groups
        UserGroup.Code := NoPermissionsNoMembersUserGroupCodeTxt;
        UserGroup.Insert();

        UserGroup.Code := PermissionsButNoMembersUserGroupCodeTxt;
        UserGroup.Insert();

        UserGroup.Code := NoPermissionsButWithMembersUserGroupCodeTxt;
        UserGroup.Insert();

        UserGroup.Code := PermissionsAnd1MemberUserGroupCodeTxt;
        UserGroup.Insert();

        UserGroup.Code := PermissionsAnd2MembersUserGroupCodeTxt;
        UserGroup.Insert();

        // Add user group permissions
        UserGroupPermissionSet."User Group Code" := PermissionsButNoMembersUserGroupCodeTxt;
        UserGroupPermissionSet."Role ID" := 'D365 SNAPSHOT DEBUG';
        UserGroupPermissionSet."App ID" := SystemApplicationAppIdLbl;
        UserGroupPermissionSet.Insert();

        UserGroupPermissionSet."User Group Code" := PermissionsAnd1MemberUserGroupCodeTxt;
        UserGroupPermissionSet.Insert();

        UserGroupPermissionSet."User Group Code" := PermissionsAnd2MembersUserGroupCodeTxt;
        UserGroupPermissionSet.Insert();

        UserGroupPermissionSet."Role ID" := 'D365 BASIC';
        UserGroupPermissionSet."App ID" := BaseAppAppIdLbl; // BaseApp app ID
        UserGroupPermissionSet.Insert();

        // Add users to user groups
        UserGroupMember."User Security ID" := TestUserSecId1Lbl;
        UserGroupMember."User Group Code" := NoPermissionsButWithMembersUserGroupCodeTxt;
        UserGroupMember.Insert();
        UserGroupUpgradeLibrary.AddUserGroupMember(NoPermissionsButWithMembersUserGroupCodeTxt, TestUserSecId1Lbl, '');

        UserGroupMember."User Group Code" := PermissionsAnd1MemberUserGroupCodeTxt;
        UserGroupMember.Insert();
        UserGroupUpgradeLibrary.AddUserGroupMember(PermissionsAnd1MemberUserGroupCodeTxt, TestUserSecId1Lbl, '');

        UserGroupMember."User Group Code" := PermissionsAnd2MembersUserGroupCodeTxt;
        UserGroupMember.Insert();
        UserGroupUpgradeLibrary.AddUserGroupMember(PermissionsAnd2MembersUserGroupCodeTxt, TestUserSecId1Lbl, '');

        UserGroupMember."User Security ID" := TestUserSecId2Lbl;
        UserGroupMember."User Group Code" := PermissionsAnd2MembersUserGroupCodeTxt;
        UserGroupMember.Insert();
        UserGroupUpgradeLibrary.AddUserGroupMember(PermissionsAnd2MembersUserGroupCodeTxt, TestUserSecId2Lbl, '');

        // Add user group plan
        UserGroupPlan."Plan ID" := TestPlanIdLbl;
        UserGroupPlan."User Group Code" := PermissionsAnd2MembersUserGroupCodeTxt;
        UserGroupPlan.Insert();
    end;

    local procedure SetupUserGroupPermissionSetRecords()
    var
        UserGroup: Record "User Group";
        UserGroupPermissionSet: Record "User Group Permission Set";
        UserGroupMember: Record "User Group Member";
        UserGroupUpgradeLibrary: Codeunit "Upgrade Plan Permissions";
#if not CLEAN22
        UserGrpPermTestLibrary: Codeunit "User Grp. Perm. Test Library";
#endif
        UserGroupCode: Label 'Test UG';
    begin
#if not CLEAN22
        BindSubscription(UserGrpPermTestLibrary);
#endif
        UserGroup.Code := UserGroupCode;
        UserGroup.Insert();

        UserGroupPermissionSet."User Group Code" := UserGroup.Code;
        UserGroupPermissionSet."Role ID" := 'D365 BASIC';
        UserGroupPermissionSet.Insert();

        UserGroupPermissionSet."User Group Code" := UserGroup.Code;
        UserGroupPermissionSet."Role ID" := 'D365 BUS FULL ACCESS';
        UserGroupPermissionSet.Insert();

        UserGroupPermissionSet."User Group Code" := UserGroup.Code;
        UserGroupPermissionSet."Role ID" := 'SECURITY';
        UserGroupPermissionSet.Insert();

        UserGroupPermissionSet."User Group Code" := UserGroup.Code;
        UserGroupPermissionSet."Role ID" := 'EMAIL SETUP';
        UserGroupPermissionSet.Insert();

        UserGroupPermissionSet."User Group Code" := UserGroup.Code;
        UserGroupPermissionSet."Role ID" := 'D365 EXTENSION MGT';
        UserGroupPermissionSet.Insert();

        UserGroupPermissionSet."User Group Code" := UserGroup.Code;
        UserGroupPermissionSet."Role ID" := 'RETENTION POL. SETUP';
        UserGroupPermissionSet.Insert();

        if UserGroup.Get(ExcelExportActionUserGroupTxt) then
            UserGroup.Delete();

        UserGroupPermissionSet.SetRange("User Group Code", ExcelExportActionUserGroupTxt);
        UserGroupPermissionSet.DeleteAll();

        UserGroup.Code := ExcelExportActionUserGroupTxt;
        UserGroup.Insert();

        UserGroupPermissionSet."User Group Code" := UserGroup.Code;
        UserGroupPermissionSet."Role ID" := 'EXCEL EXPORT ACTION';
        UserGroupPermissionSet.Insert();

        // Add user to the user groups above
        UserGroupMember."User Security ID" := TestUserSecId3Lbl;
        UserGroupMember."User Group Code" := UserGroupCode;
        UserGroupMember.Insert();
        UserGroupUpgradeLibrary.AddUserGroupMember(UserGroupCode, TestUserSecId3Lbl, '');

        UserGroupMember."User Group Code" := ExcelExportActionUserGroupTxt;
        UserGroupMember.Insert();
        UserGroupUpgradeLibrary.AddUserGroupMember(ExcelExportActionUserGroupTxt, TestUserSecId3Lbl, '');
    end;
}