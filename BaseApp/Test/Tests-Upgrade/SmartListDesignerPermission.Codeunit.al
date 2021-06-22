codeunit 135953 "SmartList Designer Permission"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SmartList Designer Permissions]
    end;

    var
        SmartListDesignerTok: Label 'SMARTLIST DESIGNER', Locked = true;
        SmartListDesignerDescriptionTxt: Label 'SmartList Designer';

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
    procedure SmartListDesignerUserGroupExists()
    var
        UserGroup: Record "User Group";
        LibraryAssert: Codeunit "Library Assert";
    begin
        UserGroup.Get(SmartListDesignerTok);
        LibraryAssert.AreEqual(UserGroup.Name, SmartListDesignerDescriptionTxt, 'Wrong value for UserGroup name');
        LibraryAssert.IsFalse(UserGroup."Assign to All New Users", 'Wrong value for Assign to All New Users field');
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
}

