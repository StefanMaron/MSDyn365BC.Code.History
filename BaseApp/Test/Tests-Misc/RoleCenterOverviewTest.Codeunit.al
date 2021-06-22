codeunit 134680 "Role Center Overview Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Role Center Overview]
    end;

    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure EditingRoleCenterOverviewOnMySettingsAddsUserPreferenceRecord()
    var
        UserPreference: Record "User Preference";
        RolecenterSelectorMgt: Codeunit "Rolecenter Selector Mgt.";
        MySettings: TestPage "My Settings";
    begin
        // [Scenario] Role Center Overview User Preference is shown on My Settings.

        // [GIVEN] Role Center Overview is disabled in the UserPreference or missing UserPreference
        if UserPreference.Get(UserId, RolecenterSelectorMgt.GetUserPreferenceCode) then begin
            UserPreference.SetUserSelection(false);
            UserPreference.Modify;
        end;

        // [WHEN] Enable the Role Center Overview on My Settings page
        MySettings.OpenEdit;
        MySettings.RoleCenterOverviewEnabled.SetValue(true);

        // [THEN] UserPreference is changed to the new value
        if not UserPreference.Get(UserId, RolecenterSelectorMgt.GetUserPreferenceCode) then
            Assert.Fail('User Preference should exist.');

        Assert.IsTrue(RolecenterSelectorMgt.GetShowStateFromUserPreference(UserId), 'RoleCenterOverview preference is not enabled');
    end;

    [Test]
    [HandlerFunctions('AvailableRoleCentersModalPageHandler')]
    [Scope('OnPrem')]
    procedure AvailableRoleCentersPageOpensWhenRoleCenterOverviewIsDisabled()
    var
        MySettings: TestPage "My Settings";
    begin
        // [Scenario] Available Role Centers page is opened when Role Center Overview is disabled

        // [GIVEN] My Settings page where Role Center Overview boolean is disabled
        MySettings.OpenEdit;
        MySettings.RoleCenterOverviewEnabled.SetValue(false);

        // [WHEN] UserRoleCenter assistedit is invoked
        MySettings.UserRoleCenter.AssistEdit;

        // [THEN] Available Role Centers page is opened which is verified in the handler
    end;

    [Test]
    [HandlerFunctions('AvailableRoleCentersModalPageHandler')]
    [Scope('OnPrem')]
    procedure AvailableRoleCentersPageOpensWhenRoleCenterOverviewIsEnabled()
    var
        MySettings: TestPage "My Settings";
    begin
        // [Scenario] Available Role Centers page is opened when Role Center Overview is enabled (overview will be removed)

        // [GIVEN] My Settings page where Role Center Overview boolean is disabled
        MySettings.OpenEdit;
        MySettings.RoleCenterOverviewEnabled.SetValue(true);

        // [WHEN] UserRoleCenter assistedit is invoked
        MySettings.UserRoleCenter.AssistEdit;

        // [THEN] Available Role Centers page is opened which is verified in the handler
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RoleCenterOverviewEnabledIsNotAvailableOnMySettingsInBasic()
    var
        MySettings: TestPage "My Settings";
    begin
        // [Scenario] Role Center Overview Enabled is not available on Basic

        // [GIVEN] Basic experience in ON
        LibraryApplicationArea.EnableBasicSetup;

        // [WHEN] My Settings page is opened
        MySettings.OpenEdit;

        // [THEN] Role Center Overview Enabled boolean field cannot be found
        Assert.IsFalse(MySettings.RoleCenterOverviewEnabled.Visible, 'Field should not be visible.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RoleCenterOverviewEnabledIsNotAvailableOnMySettingsInEssential()
    var
        MySettings: TestPage "My Settings";
    begin
        // [Scenario] Role Center Overview Enabled is not available on Suite

        // [GIVEN] Essential experience in ON
        LibraryApplicationArea.EnableFoundationSetup;

        // [WHEN] My Settings page is opened
        MySettings.OpenEdit;

        // [THEN] Role Center Overview Enabled boolean field cannot be found
        Assert.IsFalse(MySettings.RoleCenterOverviewEnabled.Visible, 'Field should not be visible.');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableRoleCentersModalPageHandler(var AvailableRoles: TestPage "Available Roles")
    begin
    end;
}

