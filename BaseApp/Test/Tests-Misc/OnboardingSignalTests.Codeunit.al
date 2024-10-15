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

    [Test]
    procedure TestCompanySignal()
    var
        Company: Record Company;
        OnboardingSignalImpl: Codeunit "Onboarding Signal";
        OnboardingSignalType: Enum "Onboarding Signal Type";
    begin
        // [SCENARIO] Test if Company Signal is working as expected
        LibraryOnboardingSignal.InitializeOnboardingSignalTestingEnv();
        LibraryLowerPermissions.SetO365Basic();

        Company.Get(CompanyName());
        // [GIVEN] Register Company Signal
        OnboardingSignalImpl.RegisterNewOnboardingSignal(Company.Name, OnboardingSignalType::Company);

        // [GIVEN] Register a new test onboarding signal
        OnboardingSignalImpl.RegisterNewOnboardingSignal(Company.Name, OnboardingSignalType::"Test Signal");

        // [THEN] The Company should is not onboarded yet
        Assert.IsFalse(OnboardingSignalImpl.HasCompanyOnboarded(Company.Name), 'The company is not onboarded yet');
        Assert.IsFalse(LibraryOnboardingSignal.IsOnboardingCompleted(Company.Name, OnboardingSignalType::Company), 'The Company Signal should be False');

        // [GIVEN] Check if registered signal has met its requirement, check it two times as we do not know the order.
        OnboardingSignalImpl.CheckAndEmitOnboardingSignals();
        OnboardingSignalImpl.CheckAndEmitOnboardingSignals();

        // [THEN] The Company should be onboarded now
        Assert.IsTrue(OnboardingSignalImpl.HasCompanyOnboarded(Company.Name), 'The company should be onboarded');
        Assert.IsTrue(LibraryOnboardingSignal.IsOnboardingCompleted(Company.Name, OnboardingSignalType::Company), 'The Company Signal should be True');
    end;

    [Test]
    procedure TestGetOnboardingSignal()
    var
        Company: Record Company;
        OnboardingSignalBuffer: Record "Onboarding Signal Buffer" temporary;
        OnboardingSignalImpl: Codeunit "Onboarding Signal";
        OnboardingSignalType: Enum "Onboarding Signal Type";
    begin
        // [SCENARIO] Test if GetOnboardingSignals procedure is working as expected
        LibraryOnboardingSignal.InitializeOnboardingSignalTestingEnv();
        LibraryLowerPermissions.SetO365Basic();

        Company.Get(CompanyName());

        // [GIVEN] Register Company Signal
        OnboardingSignalImpl.RegisterNewOnboardingSignal(Company.Name, OnboardingSignalType::Company);

        // [GIVEN] Register a new test onboarding signal
        OnboardingSignalImpl.RegisterNewOnboardingSignal(Company.Name, OnboardingSignalType::"Test Signal");

        OnboardingSignalImpl.GetOnboardingSignals(OnboardingSignalBuffer);

        // [THEN] There should be two signals already registered
        Assert.AreEqual(2, OnboardingSignalBuffer.Count(), 'There should be two signals already registered');

        // [GIVEN] Select the Company signal
        OnboardingSignalBuffer.SetRange("Onboarding Signal Type", OnboardingSignalType::Company);
        OnboardingSignalBuffer.FindFirst();

        // [THEN] The value inside onboarding signals should be properly set
        Assert.AreEqual(Today(), OnboardingSignalBuffer."Onboarding Start Date", 'The start date of a signal should be correctly copied to buffer table');
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