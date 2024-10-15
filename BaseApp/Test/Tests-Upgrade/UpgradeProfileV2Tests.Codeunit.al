#if not CLEAN22
#pragma warning disable AS0072
codeunit 135971 "Upgrade Profile V2 Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    ObsoleteReason = 'Not used.';
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';

    trigger OnRun()
    begin
        // [FEATURE] [Profiles] [Customization]
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateProfileUpgrade()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        ConfigSetup: Record "Config. Setup";
        UserGroup: Record "User Group";
        UpgradeStatus: Codeunit "Upgrade Status";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UserPersonalization: Record "User Personalization";
        TenantProfile: Record "Tenant Profile";
        Assert: Codeunit "Library Assert";
    begin
        if not UpgradeStatus.UpgradeTriggered() then
            exit;

        if UpgradeStatus.UpgradeTagPresentBeforeUpgrade(UpgradeTagDefinitions.GetUpdateProfileReferencesForDatabaseTag()) then
            exit;

        // No reference to System Profiles should be left in the tables referencing All Profile
        Assert.IsTrue(ConfigSetup.FindSet(), 'Could not find any Config. Setup.');
        repeat
            if ConfigSetup."Your Profile Code" = '' then
                Assert.AreEqual(ConfigSetup."Your Profile Scope", ConfigSetup."Your Profile Scope"::System,
                    StrSubstNo('Empty ConfigSetup should not have been updated. ID: %1, Profile ID: %2.', ConfigSetup."Primary Key", ConfigSetup."Your Profile Code"))
            else
                Assert.AreEqual(ConfigSetup."Your Profile Scope", ConfigSetup."Your Profile Scope"::Tenant,
                    StrSubstNo('ConfigSetup should have been updated. ID: %1, Profile ID: %2.', ConfigSetup."Primary Key", ConfigSetup."Your Profile Code"));
        until ConfigSetup.Next() = 0;

        Assert.IsTrue(UserGroup.FindSet(), 'Could not find any User Group.');
        repeat
            if UserGroup."Default Profile ID" = '' then
                Assert.AreEqual(UserGroup."Default Profile Scope", UserGroup."Default Profile Scope"::System,
                    StrSubstNo('Empty UserGroup should not have been updated. UserGroup ID: %1, Profile ID: %2.', UserGroup.Code, UserGroup."Default Profile ID"))
            else
                Assert.AreEqual(UserGroup."Default Profile Scope", UserGroup."Default Profile Scope"::Tenant,
                    StrSubstNo('UserGroup should have been updated. UserGroup ID: %1, Profile ID: %2.', UserGroup.Code, UserGroup."Default Profile ID"));
        until UserGroup.Next() = 0;

        Assert.IsTrue(UserPersonalization.FindSet(), 'Could not find any User Personalization.');
        repeat
            if UserPersonalization."Profile ID" = '' then
                Assert.AreEqual(UserPersonalization."Scope", UserPersonalization."Scope"::System,
                    StrSubstNo('Empty UserPersonalization should not have been updated. User ID: %1, Profile ID: %2.', UserPersonalization."User SID", UserPersonalization."Profile ID"))
            else
                Assert.AreEqual(UserPersonalization."Scope", UserPersonalization."Scope"::Tenant,
                    StrSubstNo('UserPersonalization should have been updated. User ID: %1, Profile ID: %2.', UserPersonalization."User SID", UserPersonalization."Profile ID"));
        until UserPersonalization.Next() = 0;

        ApplicationAreaSetup.SetRange(Basic, true);
        ApplicationAreaSetup.SetRange(Suite, true);
        ApplicationAreaSetup.SetRange("Fixed Assets", false);
        ApplicationAreaSetup.SetRange("User ID", '');
        ApplicationAreaSetup.SetRange("Profile ID", '');
        if ApplicationAreaSetup.IsEmpty() then
            Assert.Fail('Empty ApplicationAreaSetup should not have been updated.');

        Clear(ApplicationAreaSetup);
        ApplicationAreaSetup.SetFilter("Profile ID", '<>%1&<>%2', '', 'ACCOUNTANT PORTAL');
        // Accountant Portal does not exist in the tenant profiles because it is installed by an extension but still added as a reference by demotool
        Assert.IsTrue(ApplicationAreaSetup.FindSet(), 'Could not find any Application Area Setup with non-empty profile.');
        repeat
            TenantProfile.SetRange("Profile ID", ApplicationAreaSetup."Profile ID");
            Assert.IsFalse(TenantProfile.IsEmpty(),
                StrSubstNo('ApplicationAreaSetup should have been updated. Profile ID: %1.', ApplicationAreaSetup."Profile ID"));
        until ApplicationAreaSetup.Next() = 0;
    end;

}
#endif