codeunit 135953 "SmartList Designer Upg. Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SmartList Designer Permissions]
    end;

    var
        SmartListDesignerTok: Label 'SMARTLIST DESIGNER', Locked = true;
#if not CLEAN20
        SmartListDesignerDescriptionTxt: Label 'SmartList Designer (Obsolete)';
#endif

    [Test]
    [Scope('OnPrem')]
    procedure SmartListUserGroupAndPermissionsDontExist()
    var
#if CLEAN20
        PermissionSetRec: Record "Permission Set";
        Permission: Record Permission;
#endif
        UserGroup: Record "User Group";
        UserGroupPermissionSet: Record "User Group Permission Set";
        LibraryAssert: Codeunit "Library Assert";
    begin
#if CLEAN20
        LibraryAssert.IsFalse(PermissionSetRec.Get(SmartListDesignerTok), 'Permission set should not be present');

        Permission.SetRange("Role ID", SmartListDesignerTok);
        LibraryAssert.RecordIsEmpty(Permission);
        
#endif
        UserGroupPermissionSet.SetRange("Role ID", SmartListDesignerTok);
        LibraryAssert.RecordIsEmpty(UserGroupPermissionSet);
        UserGroupPermissionSet.Reset();
        UserGroupPermissionSet.SetRange("User Group Code", SmartListDesignerTok);
        LibraryAssert.RecordIsEmpty(UserGroupPermissionSet);

        LibraryAssert.IsFalse(UserGroup.Get(SmartListDesignerTok), 'User group should not be present');
    end;

#if not CLEAN20
    [Test]
    [Scope('OnPrem')]
    procedure SmartListDesignerPermissionSetExists()
    var
        PermissionSet: Record "Permission Set";
        Permission: Record Permission;
        LibraryAssert: Codeunit "Library Assert";
    begin
        PermissionSet.Get(SmartListDesignerTok);
        PermissionSet.TestField(Name, SmartListDesignerDescriptionTxt);

        Permission.Get(SmartListDesignerTok, Permission."Object Type"::System, 9600);
        Permission.Get(SmartListDesignerTok, Permission."Object Type"::System, 9605);
        Permission.Get(SmartListDesignerTok, Permission."Object Type"::System, 9610);
        Permission.Get(SmartListDesignerTok, Permission."Object Type"::System, 9615);
        LibraryAssert.AreEqual(Permission."Execute Permission", Permission."Execute Permission"::Yes, 'Wrong value for Execute Permission');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SmartListDesignerUserGroupIsNotPartOfExistingPlans()
    var
        UserGroupPlan: Record "User Group Plan";
        Plan: Query Plan;
        PlanIds: Codeunit "Plan Ids";
        LibraryAssert: Codeunit "Library Assert";
    begin
        Plan.Open();

        if Plan.Read() then
            repeat
                LibraryAssert.IsFalse(UserGroupPlan.Get(Plan."Plan_ID", SmartListDesignerTok), StrSubstNo('Plan %1 should not contain %2 user group', Plan."Plan_ID", SmartListDesignerTok));
            until not Plan.Read();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SmartListDesignerManualSetupDeleted()
    var
        GuidedExperience: Codeunit "Guided Experience";
        LibraryAssert: Codeunit "Library Assert";
    begin
        LibraryAssert.IsFalse(GuidedExperience.Exists(Enum::"Guided Experience Type"::"Manual Setup", ObjectType::Page, Page::"SmartList Designer Setup"),
            'Manual setup for SmartList designer is not deleted.');
    end;
#endif
}
