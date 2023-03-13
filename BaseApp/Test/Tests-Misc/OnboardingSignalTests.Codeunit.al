codeunit 139323 "Onboarding Signal Tests"
{
    Subtype = Test;
    EventSubscriberInstance = Manual;
    Permissions = tabledata "Onboarding Signal" = ri;

    var
        OnboardingSignal: Record "Onboarding Signal";
        Assert: Codeunit Assert;
        LibraryOnboardingSignal: Codeunit "Library - Onboarding Signal";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";

    [Test]
    procedure OnboardingSignalDeleteCompany()
    var
        Company: Record Company;
        OnboardingSignalTests: Codeunit "Onboarding Signal Tests";
        MockCompanyName: Text[30];
    begin
        // [SCENARIO] After a company is deleted, remove all corresponding onboarding signals
        LibraryOnboardingSignal.InitializeOnboardingSignalTestingEnv();
        LibraryLowerPermissions.SetO365Basic();
        BindSubscription(OnboardingSignalTests);

        // [THEN] After initializing, table Onboarding Signal is emtpy
        Assert.IsTrue(OnboardingSignal.Count() = 0, 'After initializing, table Onboarding Signal should be emtpy.');

        // [GIVEN] Populate some demo data into Onboarding Signal table
        MockCompanyName := 'Mock Company 1';
        PopulateOnboardingSignals(MockCompanyName, true);
        PopulateOnboardingSignals(MockCompanyName, false);
        PopulateOnboardingSignals('Mock Company 2', true);

        // [WHEN] When we delete the company
        LibraryLowerPermissions.SetOutsideO365Scope();
        Company.Init();
        Company.Name := MockCompanyName;
        Company.Insert();
        Company.Delete();
        LibraryLowerPermissions.SetO365Basic();

        // [THEN] The entry in Onboarding Signal should be deleted as well
        Assert.IsTrue(OnboardingSignal.Count() = 1, 'Corresponding Onboarding Signals should not exist after the company is deleted.');

        UnbindSubscription(OnboardingSignalTests);
    end;

    [Test]
    procedure OnboardingSignalTestSignal()
    var
        Company: Record Company;
        OnboardingSignalImpl: Codeunit "Onboarding Signal";
        OnboardingSignalType: Enum "Onboarding Signal Type";
    begin
        // [SCENARIO] Testing an example extension would work.
        LibraryOnboardingSignal.InitializeOnboardingSignalTestingEnv();
        LibraryLowerPermissions.SetO365Basic();

        // [THEN] After initializing, table Onboarding Signal is emtpy
        Assert.IsTrue(OnboardingSignal.Count() = 0, 'After initializing, table Onboarding Signal should be emtpy.');

        // [GIVEN] Register a new test onboarding signal
        Company.Get(CompanyName());
        OnboardingSignalImpl.RegisterNewOnboardingSignal(Company.Name, OnboardingSignalType::"Test Signal");

        // [THEN] The test signal should be properly registered as false
        OnboardingSignal.SetRange("Company Name", Company.Name);
        OnboardingSignal.SetRange("Onboarding Completed", false);
        OnboardingSignal.SetRange("Onboarding Signal Type", OnboardingSignalType::"Test Signal");

        Assert.IsTrue(OnboardingSignal.Count() = 1, 'Test Signal should be register.');
        Assert.IsFalse(LibraryOnboardingSignal.IsOnboardingCompleted(Company.Name, OnboardingSignalType::"Test Signal"), 'Test Signal should be register as false.');

        // [GIVEN] Check if registered signal has met its requirement.
        OnboardingSignalImpl.CheckAndEmitOnboardingSignals();

        // [THEN] The test signal should have status "Onboarding Compelete" = true
        Assert.IsTrue(LibraryOnboardingSignal.IsOnboardingCompleted(Company.Name, OnboardingSignalType::"Test Signal"), 'Test Signal''s status should be true.');
    end;

    local procedure PopulateOnboardingSignals(CompanyName: Text[30]; IsCompleted: Boolean)
    var
        OnboardingSignal: Record "Onboarding Signal";
    begin
        OnboardingSignal.Init();
        OnboardingSignal."Company Name" := CompanyName;
        OnboardingSignal."Onboarding Completed" := IsCompleted;
        OnboardingSignal.Insert();
    end;
}