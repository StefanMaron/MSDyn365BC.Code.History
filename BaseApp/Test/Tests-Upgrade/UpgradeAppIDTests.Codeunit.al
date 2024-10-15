codeunit 135972 "Upgrade App ID Tests"
{
    Subtype = Test;

    [Test]
    procedure UserGroupPermissionSetDataTest()
    var
        UserGroupPermissionSet: Record "User Group Permission Set";
        Assert: Codeunit "Library Assert";
        UpgradeStatus: Codeunit "Upgrade Status";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        NullGuid: Guid;
    begin
        // [SCENARIO] The upgrade is filling the App Ids in Access Control Table
        if not UpgradeStatus.UpgradeTriggered() then
            exit;

        if UpgradeStatus.UpgradeTagPresentBeforeUpgrade(UpgradeTagDefinitions.GetUserGroupsSetAppIdUpgradeTag()) then
            exit;

        UserGroupPermissionSet.SetRange("Role ID", 'D365 BASIC');
        UserGroupPermissionSet.FindFirst();
        Assert.AreEqual('437dbf0e-84ff-417a-965d-ed2bb9650972', UserGroupPermissionSet."App ID", 'BaseApp''s Id was expected');

        UserGroupPermissionSet.SetRange("Role ID", 'D365 BUS FULL ACCESS');
        UserGroupPermissionSet.FindFirst();
        Assert.AreEqual('437dbf0e-84ff-417a-965d-ed2bb9650972', UserGroupPermissionSet."App ID", 'BaseApp''s Id was expected');

        UserGroupPermissionSet.SetRange("Role ID", 'SECURITY');
        UserGroupPermissionSet.FindFirst();
        Assert.AreEqual(NullGuid, UserGroupPermissionSet."App ID" , 'NullGUid was expected');
    end;
}