#if not CLEAN22
#pragma warning disable AS0072
codeunit 135972 "Upg User Group Perm. Set Tests"
{
    Subtype = Test;
    ObsoleteReason = 'Not used.';
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';

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
        if not UpgradeStatus.UpgradeTriggered() then
            exit;

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

    [Test]
    procedure UserGroupPermissionSetRoleIDTest()
    var
        UpgradeStatus: Codeunit "Upgrade Status";
    begin
        if not UpgradeStatus.UpgradeTriggered() then
            exit;
        // [SCENARIO] The upgrade changes the Role ID field of replaced (obsolete) permission sets

        // The following user group permission sets are added by Demotool - on a new database, the old ones should not exist and the new ones should. 
        VerifyPermissionSetIsReplaced('EMAIL SETUP', 'Email - Admin');
        VerifyPermissionSetIsReplaced('D365 EXTENSION MGT', 'Exten. Mgt. - Admin');
        VerifyPermissionSetIsReplaced('RETENTION POL. SETUP', 'Retention Pol. Admin');
        VerifyPermissionSetIsReplaced('EXCEL EXPORT ACTION', 'Edit in Excel - View');
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
#endif