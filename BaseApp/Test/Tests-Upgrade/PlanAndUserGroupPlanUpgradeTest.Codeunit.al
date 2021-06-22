codeunit 135960 "Plan And User Group Plan Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Backup/Restore Permissions]
    end;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    [Scope('OnPrem')]
    procedure TestIfDeviceISVPlanExists()
    var
        AzureADPlan: Codeunit "Azure AD Plan";
        PlanIds: Codeunit "Plan Ids";
    begin
        Assert.IsTrue(AzureADPlan.DoesPlanExist(PlanIds.GetDeviceISVPlanId()),
            StrSubstNo('Plan with ID %1 cannot be found', PlanIds.GetDeviceISVPlanId()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIfUserGroupPlanExists()
    var
        UserGroupPlan: Record "User Group Plan";
        PlanIds: Codeunit "Plan Ids";
        UserGroupCode: Text;
    begin
        UserGroupCode := 'D365 BUS FULL ACCESS';

        Assert.IsTrue(UserGroupPlan.GET(PlanIds.GetDeviceISVPlanId(), UserGroupCode),
            StrSubstNo('Cannot find User Group %1 assigned to Plan with ID %2', UserGroupCode, PlanIds.GetDeviceISVPlanId()));
    end;
}