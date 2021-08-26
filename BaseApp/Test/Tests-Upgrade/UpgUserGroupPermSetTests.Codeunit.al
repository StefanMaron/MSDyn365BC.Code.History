codeunit 135972 "Upg User Group Perm. Set Tests"
{
    Subtype = Test;

    [Test]
    procedure UserGroupPermissionSetAppIDTest()
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
        Assert: Codeunit "Library Assert";
        UpgradeStatus: Codeunit "Upgrade Status";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        BaseAppGuid, NullGuid : Guid;
    begin
        // [SCENARIO] The upgrade is filling the App Ids in Access Control Table

        if UpgradeStatus.UpgradeTagPresentBeforeUpgrade(UpgradeTagDefinitions.GetUserGroupsSetAppIdUpgradeTag()) then
            exit;

        BaseAppGuid := Text.UpperCase('{437dbf0e-84ff-417a-965d-ed2bb9650972}');

        UserGroupPermissionSet.SetRange("Role ID", 'D365 BASIC');
        UserGroupPermissionSet.FindFirst();
        Assert.AreEqual(BaseAppGuid, UserGroupPermissionSet."App ID", 'BaseApp''s ID was expected');

        UserGroupPermissionSet.SetRange("Role ID", 'D365 BUS FULL ACCESS');
        UserGroupPermissionSet.FindFirst();
        Assert.AreEqual(BaseAppGuid, UserGroupPermissionSet."App ID", 'BaseApp''s ID was expected');

        UserGroupPermissionSet.SetRange("Role ID", 'SECURITY');
        UserGroupPermissionSet.FindFirst();
        Assert.AreEqual(NullGuid, UserGroupPermissionSet."App ID", 'Null GUID was expected');
    end;

#if not CLEAN19
    procedure UserGroupExportReportExcelTest()
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
        Assert: Codeunit "Library Assert";
        UpgradeStatus: Codeunit "Upgrade Status";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        BaseAppGuid, NullGuid : Guid;
    begin
        // [SCENARIO] The upgrade is adding Export Report Excel PS in EXCEL EXPORT ACTION User Group
        if UpgradeStatus.UpgradeTagPresentBeforeUpgrade(UpgradeTagDefinitions.GetExportExcelReportUpgradeTag()) then
            exit;

        UserGroupPermissionSet.SetRange("User Group Code", 'EXCEL EXPORT ACTION');
        Assert.RecordCount(UserGroupPermissionSet, 2);

        UserGroupPermissionSet.SetRange("Role ID", 'Export Report Excel');
        Assert.IsTrue(UserGroupPermissionSet.FindFirst(), 'Export Report Excel was not added in EXCEL EXPORT ACTION User Group');       
    end;
#endif

    [Test]
    procedure UserGroupPermissionSetRoleIDTest()
    begin
        // [SCENARIO] The upgrade changes the Role ID field of replaced (obsolete) permission sets

        // The following user group permission sets are added by Demotool - on a new database, the old ones should not exist and the new ones should. 
        VerifyPermissionSetIsReplaced('EMAIL SETUP', 'Email - Admin');
        VerifyPermissionSetIsReplaced('D365 EXTENSION MGT', 'Exten. Mgt. - Admin');
        VerifyPermissionSetIsReplaced('RETENTION POL. SETUP', 'Retention Pol. Admin');
    end;

    local procedure VerifyPermissionSetIsReplaced(OldPermissionSet: Code[20]; NewPermissionSet: Code[20])
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
        Assert: Codeunit "Library Assert";
        ServerSettings: Codeunit "Server Setting";
        UsePermissionsFromExtensions: Boolean;
    begin
        UsePermissionsFromExtensions := ServerSettings.GetUsePermissionSetsFromExtensions();

        UserGroupPermissionSet.SetRange("Role ID", OldPermissionSet);
        Assert.AreEqual(not UsePermissionsFromExtensions, UserGroupPermissionSet.FindFirst(), StrSubstNo('%1 permission set should not be assigned', OldPermissionSet));

        UserGroupPermissionSet.SetRange("Role ID", NewPermissionSet);
        Assert.AreEqual(UsePermissionsFromExtensions, UserGroupPermissionSet.FindFirst(), StrSubstNo('%1 permission set should be assigned', NewPermissionSet));
    end;
}