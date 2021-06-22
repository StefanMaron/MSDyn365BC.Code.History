codeunit 135950 "Backup/Restore Permissions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Backup/Restore Permissions]
    end;

    var
        BackupRestoreDataTok: Label 'D365 BACKUP/RESTORE', Locked = true;
        BackupRestoreDataDescription: Label 'Backup or restore database';

    [Test]
    [Scope('OnPrem')]
    procedure BackupRestorePermissionSetExists()
    var
        PermissionSet: Record "Permission Set";
        Permission: Record Permission;
        LibraryAssert: Codeunit "Library Assert";
    begin
        PermissionSet.Get(BackupRestoreDataTok);
        PermissionSet.TestField(Name, BackupRestoreDataDescription);

        Permission.Get(BackupRestoreDataTok, Permission."Object Type"::System, 5410); // Backup permission
        LibraryAssert.AreEqual(Permission."Read Permission", Permission."Read Permission"::Yes, 'Wrong value for Read Permission');
        LibraryAssert.AreEqual(Permission."Insert Permission", Permission."Insert Permission"::Yes, 'Wrong value for Insert Permission');
        LibraryAssert.AreEqual(Permission."Modify Permission", Permission."Modify Permission"::Yes, 'Wrong value for Modify Permission');
        LibraryAssert.AreEqual(Permission."Delete Permission", Permission."Delete Permission"::Yes, 'Wrong value for Delete Permission');
        LibraryAssert.AreEqual(Permission."Execute Permission", Permission."Execute Permission"::Yes, 'Wrong value for Execute Permission');

        Permission.Get(BackupRestoreDataTok, Permission."Object Type"::System, 5420); // Restore permission
        LibraryAssert.AreEqual(Permission."Read Permission", Permission."Read Permission"::Yes, 'Wrong value for Read Permission');
        LibraryAssert.AreEqual(Permission."Insert Permission", Permission."Insert Permission"::Yes, 'Wrong value for Insert Permission');
        LibraryAssert.AreEqual(Permission."Modify Permission", Permission."Modify Permission"::Yes, 'Wrong value for Modify Permission');
        LibraryAssert.AreEqual(Permission."Delete Permission", Permission."Delete Permission"::Yes, 'Wrong value for Delete Permission');
        LibraryAssert.AreEqual(Permission."Execute Permission", Permission."Execute Permission"::Yes, 'Wrong value for Execute Permission');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BackupRestoreUserGroupExists()
    var
        UserGroup: Record "User Group";
        LibraryAssert: Codeunit "Library Assert";
    begin
        UserGroup.Get(BackupRestoreDataTok);
        LibraryAssert.AreEqual(UserGroup.Name, BackupRestoreDataDescription, 'Wrong value for UserGroup name');
        LibraryAssert.IsFalse(UserGroup."Assign to All New Users", 'Wrong value for Assign to All New Users field');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BackupRestoreUserGroupIsPartOfDelegatedAdminPlan()
    var
        UserGroupPlan: Record "User Group Plan";
        Plan: Query Plan;
        PlanIds: Codeunit "Plan Ids";
        LibraryAssert: Codeunit "Library Assert";
    begin
        Plan.Open();

        if Plan.Read() then
            repeat
                if (Plan."Plan_ID" = PlanIds.GetDelegatedAdminPlanId())
                    or (Plan."Plan_ID" = PlanIds.GetInternalAdminPlanId()) then
                    UserGroupPlan.Get(Plan."Plan_ID", BackupRestoreDataTok)
                else
                    LibraryAssert.IsFalse(UserGroupPlan.Get(Plan."Plan_ID", BackupRestoreDataTok), 'Plan should not be found');
            until not Plan.Read();
    end;
}

