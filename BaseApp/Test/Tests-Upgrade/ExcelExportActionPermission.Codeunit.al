codeunit 135952 "Excel Export Action Permission"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Excel Export Action Permissions]
    end;

    var
        ExcelExportActionTok: Label 'EXCEL EXPORT ACTION', Locked = true;
        ExcelExportActionDescriptionTxt: Label 'D365 Excel Export Action';

    [Test]
    [Scope('OnPrem')]
    procedure ExcelExportActionPermissionSetExists()
    var
        PermissionSet: Record "Permission Set";
        Permission: Record Permission;
        LibraryAssert: Codeunit "Library Assert";
    begin
        PermissionSet.Get(ExcelExportActionTok);
        PermissionSet.TestField(Name, ExcelExportActionDescriptionTxt);

        Permission.Get(ExcelExportActionTok, Permission."Object Type"::System, 6110); // Excel Export action permission
        LibraryAssert.AreEqual(Permission."Execute Permission", Permission."Execute Permission"::Yes, 'Wrong value for Execute Permission');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExcelExportActionUserGroupExists()
    var
        UserGroup: Record "User Group";
        LibraryAssert: Codeunit "Library Assert";
    begin
        UserGroup.Get(ExcelExportActionTok);
        LibraryAssert.AreEqual(UserGroup.Name, ExcelExportActionDescriptionTxt, 'Wrong value for UserGroup name');
        LibraryAssert.IsTrue(UserGroup."Assign to All New Users", 'Wrong value for Assign to All New Users field');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExcelExportActionUserGroupIsPartOfExistingPlans()
    var
        UserGroupPlan: Record "User Group Plan";
        Plan: Query Plan;
        PlanIds: Codeunit "Plan Ids";
        LibraryAssert: Codeunit "Library Assert";
    begin
        Plan.Open();

        if Plan.Read() then
            repeat
                LibraryAssert.IsTrue(UserGroupPlan.Get(Plan."Plan_ID", ExcelExportActionTok), StrSubstNo('Plan %1 should contain %2 user group', Plan."Plan_ID", ExcelExportActionTok));
            until not Plan.Read();
    end;
}

