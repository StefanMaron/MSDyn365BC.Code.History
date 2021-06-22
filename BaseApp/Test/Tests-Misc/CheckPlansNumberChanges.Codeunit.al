codeunit 135399 "Check Plans Number Changes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Plan]
    end;

    var
        PlansNumberChangeErr: Label 'The number of available plans has changed. Make sure that you have added or removed tests on these changes in Plan-Based tests and then update the number of plans in this test.', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPlansNumber()
    var
        AzureADPlan: Codeunit "Azure AD Plan";
        AvailablePlansNumber: Integer;
    begin
        AvailablePlansNumber := 21;

        if AzureADPlan.GetAvailablePlansCount() <> AvailablePlansNumber then
            Error(PlansNumberChangeErr);

    end;
}

