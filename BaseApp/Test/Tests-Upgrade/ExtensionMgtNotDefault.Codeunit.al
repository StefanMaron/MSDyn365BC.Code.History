codeunit 135951 "Extension Mgt. Not Default"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Extension management is not assigned to any plan by default]
    end;

    var
        ExtensionMgtTok: Label 'D365 EXTENSION MGT', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure ExtensionManagementNotAssignedToAnyPlanByDefault()
    var
        UserGroupPlan: Record "User Group Plan";
        LibraryAssert: Codeunit "Library Assert";
    begin
        UserGroupPlan.SetRange("User Group Code", ExtensionMgtTok);
        LibraryAssert.RecordIsEmpty(UserGroupPlan);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExtensionManagementNotAssignedToAnyUser()
    var
        AccessControl: Record "Access Control";
        LibraryAssert: Codeunit "Library Assert";
    begin
        AccessControl.SetRange("Role ID", ExtensionMgtTok);
        LibraryAssert.RecordIsEmpty(AccessControl);
    end;
}

