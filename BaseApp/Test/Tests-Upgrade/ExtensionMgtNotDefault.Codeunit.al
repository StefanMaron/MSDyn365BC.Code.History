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
        UserGroupPlan.SetFilter("Plan ID", '<>%1', '00000000-0000-0000-0000-000000000010'); // D365 Automation, not meant for users but requires permissions by default
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

