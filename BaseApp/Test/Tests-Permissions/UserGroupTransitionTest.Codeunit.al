#if not CLEAN22
#pragma warning disable AS0072
codeunit 139401 "User Group Transition Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    ObsoleteReason = 'Not used.';
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';

    var
        Assert: Codeunit Assert;
        TestUserName1: Label 'User Group Test User 1';
        TestUserName2: Label 'User Group Test User 2';
        NoPermissionsNoMembersUserGroupCode: Label 'UG1';
        PermissionsButNoMembersUserGroupCode: Label 'UG2';
        NoPermissionsButWithMembersUserGroupCode: Label 'UG3';
        PermissionsAnd1MemberUserGroupCode: Label 'UG4';
        PermissionsAnd2MembersUserGroupCode: Label 'UG5';
        UnexpectedRoleIDErr: Label 'Unexpected Role ID.';
        TestPlanId: Label '8d2edf83-4f9f-4346-9184-f1aa4b62d598';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestMigrateUserGroupsNoUserGroupsToConvert()
    var
        User: Record User;
        UserGroup: Record "User Group";
        AccessControl: Record "Access Control";
        PermissionSetInPlanBuffer: Record "Permission Set In Plan Buffer";
        PlanConfiguration: Codeunit "Plan Configuration";
        UpgradeUserGroups: Codeunit "Upgrade User Groups";
        EmptyList: List of [Code[20]];
        AccessControlCountBeforeMigration: Integer;
    begin
        // [GIVEN] User groups are defined in the system
        SetupUserGroups();
        AccessControlCountBeforeMigration := AccessControl.Count();

        // [WHEN] User groups are migrated (disabled) without conversion
        UpgradeUserGroups.MigrateUserGroups(EmptyList);

        // [THEN] No user group records remain
        Assert.RecordIsEmpty(UserGroup);

        // [THEN] Access Control has the same number of records as before the migration
        Assert.AreEqual(AccessControlCountBeforeMigration, AccessControl.Count(), 'Expected Access Control records to not be affected by user group migration.');

        // [THEN] User permissions are intact
        User.SetRange("User Name", TestUserName1);
        User.FindFirst();

        AccessControl.SetRange("User Security ID", User."User Security ID");
        AccessControl.SetRange("Role ID", 'D365 SNAPSHOT DEBUG');
        Assert.RecordIsNotEmpty(AccessControl);

        User.SetRange("User Name", TestUserName2);
        User.FindFirst();

        AccessControl.SetRange("User Security ID", User."User Security ID");
        AccessControl.SetRange("Role ID", 'D365 SNAPSHOT DEBUG');
        Assert.RecordIsNotEmpty(AccessControl);

        AccessControl.SetRange("Role ID", 'D365 BASIC');
        Assert.RecordIsNotEmpty(AccessControl);


        // Verify user group plan migration
        PlanConfiguration.GetDefaultPermissions(PermissionSetInPlanBuffer);
        PermissionSetInPlanBuffer.SetRange("Plan ID", TestPlanId);

        Assert.RecordCount(PermissionSetInPlanBuffer, 2);

        PermissionSetInPlanBuffer.FindSet();
        Assert.AreEqual('D365 BASIC', PermissionSetInPlanBuffer."Role ID", UnexpectedRoleIDErr);

        PermissionSetInPlanBuffer.Next();
        Assert.AreEqual('D365 SNAPSHOT DEBUG', PermissionSetInPlanBuffer."Role ID", UnexpectedRoleIDErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestMigrateUserGroupsWithUserGroupsToConvert()
    var
        User: Record User;
        UserGroup: Record "User Group";
        AccessControl: Record "Access Control";
        UpgradeUserGroups: Codeunit "Upgrade User Groups";
        UserGroupsToConvert: List of [Code[20]];
    begin
        // [GIVEN] User groups are defined in the system
        SetupUserGroups();

        // [WHEN] User groups are migrated (disabled) with conversion
        UserGroupsToConvert.Add(PermissionsButNoMembersUserGroupCode);
        UserGroupsToConvert.Add(PermissionsAnd1MemberUserGroupCode);
        UserGroupsToConvert.Add(PermissionsAnd2MembersUserGroupCode);
        UpgradeUserGroups.MigrateUserGroups(UserGroupsToConvert);

        // [THEN] No user group records remain
        Assert.RecordIsEmpty(UserGroup);

        // [THEN] User are changed to include converted permission sets
        User.SetRange("User Name", TestUserName1);
        User.FindFirst();

        AccessControl.SetRange("User Security ID", User."User Security ID");
        AccessControl.SetRange("Role ID", PermissionsButNoMembersUserGroupCode);
        Assert.RecordIsEmpty(AccessControl); // no user was a member of this user group

        AccessControl.SetRange("Role ID", PermissionsAnd1MemberUserGroupCode);
        Assert.RecordIsNotEmpty(AccessControl);

        AccessControl.SetRange("Role ID", PermissionsAnd2MembersUserGroupCode);
        Assert.RecordIsNotEmpty(AccessControl);

        User.SetRange("User Name", TestUserName2);
        User.FindFirst();

        AccessControl.SetRange("User Security ID", User."User Security ID");
        AccessControl.SetRange("Role ID", PermissionsAnd2MembersUserGroupCode);
        Assert.RecordIsNotEmpty(AccessControl);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestMigrateUserGroupsWithUserGroupsToConvertAndNameClash()
    var
        User: Record User;
        UserGroup: Record "User Group";
        AccessControl: Record "Access Control";
        UpgradeUserGroups: Codeunit "Upgrade User Groups";
        UserGroupsToConvert: List of [Code[20]];
        LibraryPermissions: Codeunit "Library - Permissions";
        Suffix: Label '_1';
    begin
        // [GIVEN] User groups are defined in the system
        SetupUserGroups();

        // [GIVEN] A permission set exists with the same name as the user group
        LibraryPermissions.CreatePermissionSetWithCode(PermissionsAnd2MembersUserGroupCode);

        // [WHEN] User groups are migrated (disabled) with the name clash conversion
        UserGroupsToConvert.Add(PermissionsAnd2MembersUserGroupCode);
        UpgradeUserGroups.MigrateUserGroups(UserGroupsToConvert);

        // [THEN] No user group records remain
        Assert.RecordIsEmpty(UserGroup);

        // [THEN] The newly created permission set is suffixed with _1 to avoid the name clash
        User.SetRange("User Name", TestUserName1);
        User.FindFirst();

        AccessControl.SetRange("Role ID", PermissionsAnd2MembersUserGroupCode + Suffix);
        Assert.RecordIsNotEmpty(AccessControl);

        User.SetRange("User Name", TestUserName2);
        User.FindFirst();

        AccessControl.SetRange("User Security ID", User."User Security ID");
        AccessControl.SetRange("Role ID", PermissionsAnd2MembersUserGroupCode + Suffix);
        Assert.RecordIsNotEmpty(AccessControl);
    end;

    local procedure SetupUserGroups()
    var
        GroupMemberUser1: Record User;
        GroupMemberUser2: Record User;
        UserGroup: Record "User Group";
        UserGroupMember: Record "User Group Member";
        UserGroupPermissionSet: Record "User Group Permission Set";
        UserGroupPlan: Record "User Group Plan";
        UserGroupUpgradeLibrary: Codeunit "Upgrade Plan Permissions";
    begin
        // Create user groups
        UserGroup.Code := NoPermissionsNoMembersUserGroupCode;
        UserGroup.Insert();

        UserGroup.Code := PermissionsButNoMembersUserGroupCode;
        UserGroup.Insert();

        UserGroup.Code := NoPermissionsButWithMembersUserGroupCode;
        UserGroup.Insert();

        UserGroup.Code := PermissionsAnd1MemberUserGroupCode;
        UserGroup.Insert();

        UserGroup.Code := PermissionsAnd2MembersUserGroupCode;
        UserGroup.Insert();

        // Add user group permissions
        UserGroupPermissionSet."User Group Code" := PermissionsButNoMembersUserGroupCode;
        UserGroupPermissionSet."Role ID" := 'D365 SNAPSHOT DEBUG';
        UserGroupPermissionSet."App ID" := '4846d32b-e7ca-4c4c-94e0-3eee0eccd715';
        UserGroupPermissionSet.Insert();

        UserGroupPermissionSet."User Group Code" := PermissionsAnd1MemberUserGroupCode;
        UserGroupPermissionSet.Insert();

        UserGroupPermissionSet."User Group Code" := PermissionsAnd2MembersUserGroupCode;
        UserGroupPermissionSet.Insert();

        UserGroupPermissionSet."Role ID" := 'D365 BASIC';
        UserGroupPermissionSet."App ID" := '437dbf0e-84ff-417a-965d-ed2bb9650972'; // BaseApp app ID
        UserGroupPermissionSet.Insert();

        // Create users
        GroupMemberUser1."User Security ID" := CreateGuid();
        GroupMemberUser1."User Name" := TestUserName1;
        GroupMemberUser1.Insert();

        GroupMemberUser2."User Security ID" := CreateGuid();
        GroupMemberUser2."User Name" := TestUserName2;
        GroupMemberUser2.Insert();

        // Add users to user groups
        UserGroupMember."User Security ID" := GroupMemberUser1."User Security ID";
        UserGroupMember."User Group Code" := NoPermissionsButWithMembersUserGroupCode;
        UserGroupMember.Insert();
        UserGroupUpgradeLibrary.AddUserGroupMember(NoPermissionsButWithMembersUserGroupCode, GroupMemberUser1."User Security ID", '');

        UserGroupMember."User Group Code" := PermissionsAnd1MemberUserGroupCode;
        UserGroupMember.Insert();
        UserGroupUpgradeLibrary.AddUserGroupMember(PermissionsAnd1MemberUserGroupCode, GroupMemberUser1."User Security ID", '');

        UserGroupMember."User Group Code" := PermissionsAnd2MembersUserGroupCode;
        UserGroupMember.Insert();
        UserGroupUpgradeLibrary.AddUserGroupMember(PermissionsAnd2MembersUserGroupCode, GroupMemberUser1."User Security ID", '');

        UserGroupMember."User Security ID" := GroupMemberUser2."User Security ID";
        UserGroupMember."User Group Code" := PermissionsAnd2MembersUserGroupCode;
        UserGroupMember.Insert();
        UserGroupUpgradeLibrary.AddUserGroupMember(PermissionsAnd2MembersUserGroupCode, GroupMemberUser2."User Security ID", '');

        // Add user group plan
        UserGroupPlan."Plan ID" := TestPlanId;
        UserGroupPlan."User Group Code" := PermissionsAnd2MembersUserGroupCode;
        UserGroupPlan.Insert();
    end;
}
#endif