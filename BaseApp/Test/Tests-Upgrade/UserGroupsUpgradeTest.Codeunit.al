codeunit 135978 "User Groups Upgrade Tests"
{
    Subtype = Test;

    var
        LibraryAssert: Codeunit "Library Assert";
        TestUserSecId1Lbl: Label '24b82390-152d-40d8-8ccd-e85a9e087cb9';
        TestUserSecId2Lbl: Label '96923896-daad-4782-b4f1-893f0c20ad5e';
        TestUserSecId3Lbl: Label 'f781c995-3386-4f55-9b07-a3902a70acaa';
        TestUserSecId4Lbl: Label '46d9d1a0-75f2-444a-a386-9657da1fe204';
        NoPermissionsNoMembersUserGroupCodeTxt: Label 'UG1';
        PermissionsButNoMembersUserGroupCodeTxt: Label 'UG2';
        NoPermissionsButWithMembersUserGroupCodeTxt: Label 'UG3';
        PermissionsAnd1MemberUserGroupCodeTxt: Label 'UG4';
        PermissionsAnd2MembersUserGroupCodeTxt: Label 'UG5';
        TestPlanIdLbl: Label '8d2edf83-4f9f-4346-9184-f1aa4b62d598';
        UnexpectedRoleIDErr: Label 'Unexpected Role ID.';

    [Test]
    procedure UserGroupsUpgradeTests()
    var
        SecurityGroupBuffer: Record "Security Group Buffer";
        SecurityGroup: Codeunit "Security Group";
        UpgradeUserGroups: Codeunit "Upgrade User Groups";
        UpgradeStatus: Codeunit "Upgrade Status";
    begin
        if not UpgradeStatus.UpgradeTriggered() then
            exit;

#if not CLEAN22
        // Run the upgrade manually. In v25+ the upgrade will run automatically.
        UpgradeUserGroups.RunUpgrade();
#endif
        VerifyMigration();
        VerifyAppIdReplacement();
        VerifyDeprecatedPermissionSetReplacement();
    end;

    local procedure VerifyMigration()
    var
        AccessControl: Record "Access Control";
        PermissionSetInPlanBuffer: Record "Permission Set In Plan Buffer";
        PlanConfiguration: Codeunit "Plan Configuration";
    begin
        AccessControl.SetRange("User Security ID", TestUserSecId1Lbl);
        AccessControl.SetRange("Role ID", 'D365 SNAPSHOT DEBUG');
        LibraryAssert.RecordIsNotEmpty(AccessControl);

        AccessControl.SetRange("User Security ID", TestUserSecId2Lbl);
        AccessControl.SetRange("Role ID", 'D365 SNAPSHOT DEBUG');
        LibraryAssert.RecordIsNotEmpty(AccessControl);

        AccessControl.SetRange("Role ID", 'D365 BASIC');
        LibraryAssert.RecordIsNotEmpty(AccessControl);

        // Verify user group plan migration
        PlanConfiguration.GetDefaultPermissions(PermissionSetInPlanBuffer);
        PermissionSetInPlanBuffer.SetRange("Plan ID", TestPlanIdLbl);

        LibraryAssert.RecordCount(PermissionSetInPlanBuffer, 2);

        PermissionSetInPlanBuffer.FindSet();
        LibraryAssert.AreEqual('D365 BASIC', PermissionSetInPlanBuffer."Role ID", UnexpectedRoleIDErr);

        PermissionSetInPlanBuffer.Next();
        LibraryAssert.AreEqual('D365 SNAPSHOT DEBUG', PermissionSetInPlanBuffer."Role ID", UnexpectedRoleIDErr);
    end;

    local procedure VerifyAppIdReplacement()
    var
        AccessControl: Record "Access Control";
        NullGuid: Guid;
        BaseAppId: Guid;
    begin
        BaseAppId := '437dbf0e-84ff-417a-965d-ed2bb9650972';
        AccessControl.SetRange("User Security ID", TestUserSecId3Lbl);

        AccessControl.SetRange("Role ID", 'D365 BASIC');
        AccessControl.FindFirst();
        LibraryAssert.AreEqual(BaseAppId, AccessControl."App ID", 'BaseApp''s ID was expected');

        AccessControl.SetRange("Role ID", 'D365 BUS FULL ACCESS');
        AccessControl.FindFirst();
        LibraryAssert.AreEqual(BaseAppId, AccessControl."App ID", 'BaseApp''s ID was expected');

        AccessControl.SetRange("Role ID", 'SECURITY');
        AccessControl.FindFirst();
        LibraryAssert.AreEqual(NullGuid, AccessControl."App ID", 'Null GUID was expected');
    end;

    local procedure VerifyDeprecatedPermissionSetReplacement()
    var
        AccessControl: Record "Access Control";
    begin
        AccessControl.SetRange("User Security ID", TestUserSecId3Lbl);

        AccessControl.SetRange("Role ID", 'Email - Admin');
        LibraryAssert.RecordIsNotEmpty(AccessControl);

        AccessControl.SetRange("Role ID", 'Exten. Mgt. - Admin');
        LibraryAssert.RecordIsNotEmpty(AccessControl);

        AccessControl.SetRange("Role ID", 'Retention Pol. Admin');
        LibraryAssert.RecordIsNotEmpty(AccessControl);

        AccessControl.SetRange("Role ID", 'Edit in Excel - View');
        LibraryAssert.RecordIsNotEmpty(AccessControl);
    end;
}