#if not CLEAN22
#pragma warning disable AS0072
codeunit 135953 "SmartList Designer Upg. Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    ObsoleteReason = 'Not used.';
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';

    trigger OnRun()
    begin
        // [FEATURE] [SmartList Designer Permissions]
    end;

    var
        SmartListDesignerTok: Label 'SMARTLIST DESIGNER', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure SmartListUserGroupAndPermissionsDontExist()
    var
        PermissionSetRec: Record "Permission Set";
        Permission: Record Permission;
        UserGroup: Record "User Group";
        UserGroupPermissionSet: Record "User Group Permission Set";
        LibraryAssert: Codeunit "Library Assert";
    begin
        LibraryAssert.IsFalse(PermissionSetRec.Get(SmartListDesignerTok), 'Permission set should not be present');

        Permission.SetRange("Role ID", SmartListDesignerTok);
        LibraryAssert.RecordIsEmpty(Permission);

        UserGroupPermissionSet.SetRange("Role ID", SmartListDesignerTok);
        LibraryAssert.RecordIsEmpty(UserGroupPermissionSet);
        UserGroupPermissionSet.Reset();
        UserGroupPermissionSet.SetRange("User Group Code", SmartListDesignerTok);
        LibraryAssert.RecordIsEmpty(UserGroupPermissionSet);

        LibraryAssert.IsFalse(UserGroup.Get(SmartListDesignerTok), 'User group should not be present');
    end;
}
#endif