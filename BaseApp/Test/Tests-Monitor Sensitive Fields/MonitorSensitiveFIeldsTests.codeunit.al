codeunit 139064 "Monitor Sensitive Field Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UserAndEmailValidationBeforeEnableMonitor()
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
        User: Record User;
        UserCard: TestPage "User Card";
        EmailSetupWizardPage: TestPage "Email Setup Wizard";
    begin
        // [Scenario] try To enable without choosing user.
        // [GIVEN] Clean Entry and setup table 
        MonitorFieldTestHelper.InitMonitor();
        LibraryLowerPermissions.SetSecurity();

        LibraryEmailFeature.SetEmailFeatureEnabled(false);
        EmailSetupWizardPage.Trap();
        asserterror MonitorSensitiveField.EnableMonitor(true);
        EmailSetupWizardPage.Close();

        // [WHEN] Try to enable without choosing a email account
        LibraryEmailFeature.SetEmailFeatureEnabled(true);
        MonitorSensitiveField.GetSetupTable(FieldMonitoringSetup);
        asserterror MonitorSensitiveField.EnableMonitor(true);
        Assert.ExpectedError(EmailAccountMissingErr);

        MonitorSensitiveField.GetSetupTable(FieldMonitoringSetup);
        FieldMonitoringSetup."Email Account Name" := 'Test';
        FieldMonitoringSetup.Modify();

        asserterror MonitorSensitiveField.EnableMonitor(true);
        Assert.ExpectedError(UserNotFoundErr);

        InsertUser(User, '');
        UserCard.Trap();
        asserterror FieldMonitoringSetup.Validate("User Id", User."User Name");
        FieldMonitoringSetup.Modify();
        Assert.AreEqual(User."User Name", UserCard."User Name".Value(), 'User card for selected user in setup table should have been opened');
        UserCard.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EnableMonitor()
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
        User: Record User;
    begin
        // [Scenario] try To enable without choosing user.
        // [GIVEN] Clean Entry and setup table 
        LibraryEmailFeature.SetEmailFeatureEnabled(true);
        MonitorFieldTestHelper.InitMonitor();
        LibraryLowerPermissions.SetSecurity();
        InsertUser(User, 'test');

        // [WHEN] 
        MonitorSensitiveField.GetSetupTable(FieldMonitoringSetup);
        FieldMonitoringSetup.Validate("Email Account Name", 'Test');
        FieldMonitoringSetup.Validate("User Id", User."User Name");
        FieldMonitoringSetup.Modify();

        MonitorSensitiveField.EnableMonitor(true);

        FieldMonitoringSetup.Get();
        Assert.IsTrue(FieldMonitoringSetup."Monitor Status", 'Monitor should be enabled');
        // [THEN] Entry should exist for enabling the monitor
        Assert.IsTrue(MonitorFieldTestHelper.EntryExists(Database::"Field Monitoring Setup", FieldMonitoringSetup.FieldNo(FieldMonitoringSetup."Monitor Status"),
            'false', 'true'), 'An entry should be logged after enabling the monitor');
    end;

    [Test]
    [HandlerFunctions('CreatePromotionNotificationHandler')]
    procedure ShowPromotionNotification()
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
        MyNotifications: Record "My Notifications";
        CompanyInformation: TestPage "Company Information";
    begin
        // [Scenario] Promoting monitor sensitive field in company information page
        // [GIVEN] Clean Entry and setup table 
        MonitorFieldTestHelper.InitMonitor();

        // [WHEN] Monitor opening company page
        // [THEN] User should get a notification
        CompanyInformation.OpenEdit();
        CompanyInformation.Close();
        Assert.IsTrue(IsPromotionNotificationShown, 'Promotion notification should show up when we open pages with sensitive field');
        CleanUpNotificationBoolean();

        // [WHEN] Monitor is enabled
        // [THEN] No notification 
        MonitorSensitiveField.GetSetupTable(FieldMonitoringSetup);
        FieldMonitoringSetup."Monitor Status" := true;
        FieldMonitoringSetup.Modify(false);
        CompanyInformation.OpenEdit();
        CompanyInformation.Close();
        Assert.IsFalse(IsPromotionNotificationShown, 'Promotion notification should be shown');

        // [WHEN] User ask not to see the promotion message again
        // [THEN] No notification 
        MyNotifications.Disable(MonitorSensitiveField.GetPromoteMonitorFeatureNotificationId());
        CompanyInformation.OpenEdit();
        CompanyInformation.Close();
        Assert.IsFalse(IsPromotionNotificationShown, 'Promotion notification should be shown');
        CleanUpNotificationBoolean();
    end;

    [Test]
    [HandlerFunctions('CreateHiddenTablesNotificationHandler')]
    procedure ShowHiddenTablenotificationInChangeLogSetupTable()
    var
        ChangeLogSetupTableList: TestPage "Change Log Setup (Table) List";
        TestTableC: Record "Test Table C";
    begin
        // [Scenario] Notify the user that some tables are hidden because they are monitored in Monitor Sensitive field feature
        // [GIVEN] Clean Entry and setup table 
        LibraryLowerPermissions.SetSecurity();
        MonitorFieldTestHelper.InitMonitor();
        ChangeLogSetupTableList.OpenEdit();
        ChangeLogSetupTableList.Close();
        Assert.IsFalse(IsHiddenTableNotificationShown, 'If no fields are monitored, then change log should not have any hidden tables');
        CleanUpNotificationBoolean();

        // [WHEN] Adding record in the monitor
        // [THEN] User should get notification that some tables are hidden in change log
        MonitorSensitiveField.AddMonitoredField(Database::"Test Table C", TestTableC.FieldNo("Integer Field"), true);
        ChangeLogSetupTableList.OpenEdit();
        ChangeLogSetupTableList.Close();
        Assert.IsTrue(IsHiddenTableNotificationShown, 'Hidden table notification should be shown when opening change log table list');
        CleanUpNotificationBoolean();
    end;

    [Test]
    [HandlerFunctions('CreateEmailFeatureEnabledNotificationHandler')]
    procedure ShowEmailFeatureEnabledNotification()
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
        MonitoredFieldsWorksheet: TestPage "Monitored Fields Worksheet";
        FieldMonitoringSetupPage: TestPage "Field Monitoring Setup";
        MonitoredFieldLogEntries: TestPage "Monitored Field Log Entries";
    begin
        // [Scenario] Notify the user that new email experience is enabled
        // [GIVEN] Clean Entry and setup table 
        MonitorFieldTestHelper.InitMonitor();
        LibraryLowerPermissions.SetSecurity();
        MonitorSensitiveField.GetSetupTable(FieldMonitoringSetup);
        FieldMonitoringSetup."Monitor Status" := true;
        FieldMonitoringSetup.Modify(false);
        LibraryEmailFeature.SetEmailFeatureEnabled(true);

        MonitoredFieldLogEntries.OpenEdit();
        MonitoredFieldLogEntries.Close();
        Assert.IsTrue(IsEmailFeatureNotificationShown, 'New email experience notification should show up when the feature key is enabled and the monitor');
        CleanUpNotificationBoolean();

        FieldMonitoringSetupPage.OpenEdit();
        FieldMonitoringSetupPage.Close();
        Assert.IsTrue(IsEmailFeatureNotificationShown, 'New email experience notification should show up when the feature key is enabled and the monitor');
        CleanUpNotificationBoolean();

        MonitoredFieldsWorksheet.OpenEdit();
        MonitoredFieldsWorksheet.Close();
        Assert.IsTrue(IsEmailFeatureNotificationShown, 'New email experience notification should show up when the feature key is enabled and the monitor');
        CleanUpNotificationBoolean();


        // [WHEN] Email account is set
        FieldMonitoringSetup."Email Account Name" := 'Dummy';
        FieldMonitoringSetup.Modify(false);

        MonitoredFieldsWorksheet.OpenEdit();
        MonitoredFieldsWorksheet.Close();
        Assert.IsFalse(IsEmailFeatureNotificationShown, 'No notification should be raised');

        // [WHEN] Monitor is disabled
        FieldMonitoringSetup."Monitor Status" := false;
        FieldMonitoringSetup."Email Account Name" := '';
        FieldMonitoringSetup.Modify(false);

        MonitoredFieldsWorksheet.OpenEdit();
        MonitoredFieldsWorksheet.Close();
        Assert.IsFalse(IsEmailFeatureNotificationShown, 'No notification should be raised');
    end;

    local procedure InitSMTP()
    var
        SMTPMailSetup: Record "SMTP Mail Setup";
    begin
        if not SMTPMailSetup.Get() then
            SMTPMailSetup.Insert();

        SMTPMailSetup."SMTP Server" := 'Dummy';
        SMTPMailSetup.Modify();
    end;

    local procedure VerifyWizardSetup(User: Record User)
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
        TestTableC: Record "Test Table C";
        ChangeLogSetupField: Record "Change Log Setup (Field)";
    begin
        MonitorSensitiveField.GetSetupTable(FieldMonitoringSetup);
        Assert.IsTrue(FieldMonitoringSetup."Monitor Status", 'Monitor should be enabled after running the wizard');
        Assert.AreEqual(User."User Name", FieldMonitoringSetup."User Id", 'User assigned in wizard setup is not in setup table');

        MonitorFieldTestHelper.AssertMonitoredFieldAddedCorrectly(Database::"Test Table C", TestTableC.FieldNo("Integer Field"));
        Assert.IsTrue(MonitorFieldTestHelper.EntryExists(Database::"Field Monitoring Setup", FieldMonitoringSetup.FieldNo(FieldMonitoringSetup."Monitor Status"), 'false', 'true'),
            'Enable entry should create an entry');
        Assert.IsTrue(MonitorFieldTestHelper.EntryExists(Database::"Change Log Setup (Field)", ChangeLogSetupField.FieldNo("Table No."), '', Format(Database::"Test Table C")),
            'Insert monitor record should create an entry with table number');
        Assert.IsTrue(MonitorFieldTestHelper.EntryExists(Database::"Change Log Setup (Field)", ChangeLogSetupField.FieldNo("Field No."), '', Format(TestTableC.FieldNo("Integer Field"))),
            'Insert monitor record should create an entry with field number');
    end;

    local procedure CleanUpNotificationBoolean()
    begin
        IsEmailFeatureNotificationShown := false;
        IsHiddenTableNotificationShown := false;
        IsPromotionNotificationShown := false;
    end;

    local procedure InsertSensitiveFields()
    var
        DataSensitivity: Record "Data Sensitivity";
        TestTableC: Record "Test Table C";
        DataClassigication: Codeunit "Data Classification Mgt.";
    begin
        DataSensitivity.DeleteAll();
        DataClassigication.InsertDataSensitivityForField(Database::"Test Table C", TestTableC.FieldNo(TestTableC."Integer Field"), DataSensitivity."Data Sensitivity"::Sensitive);
    end;

    [Normal]
    local procedure InsertUser(var User: Record User; ContactEmail: Text);
    begin
        User."User Security ID" := CreateGuid();
        User."User Name" := 'TESTUSER';
        User."Contact Email" := CopyStr(ContactEmail, 1, 80);
        User.State := User.State::Enabled;
        User.Insert();
    end;

    local procedure SetMonitorSetup(EnableMonitor: Boolean)
    var
        FieldMonitoringSetup: Record "Field Monitoring Setup";
    begin
        if FieldMonitoringSetup.Get() then begin
            FieldMonitoringSetup."Monitor Status" := EnableMonitor;
            FieldMonitoringSetup.Modify();
        end else begin
            FieldMonitoringSetup."Monitor Status" := EnableMonitor;
            FieldMonitoringSetup.Insert();
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure CreatePromotionNotificationHandler(var Notification: Notification): Boolean
    begin
        IsPromotionNotificationShown := Notification.Id = MonitorSensitiveField.GetPromoteMonitorFeatureNotificationId()
    end;


    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure CreateHiddenTablesNotificationHandler(var Notification: Notification): Boolean
    begin
        IsHiddenTableNotificationShown := Notification.Id = MonitorSensitiveField.GetChangeLogHiddenTablesNotificationId()
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure CreateEmailFeatureEnabledNotificationHandler(var Notification: Notification): Boolean
    begin
        IsEmailFeatureNotificationShown := Notification.Id = MonitorSensitiveField.GetEmailFeatureEnabledNotificationId();
    end;

    var
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryEmailFeature: Codeunit "Library - Email Feature";
        Assert: Codeunit "Library Assert";
        MonitorSensitiveField: Codeunit "Monitor Sensitive Field";
        MonitorFieldTestHelper: Codeunit "Monitor Field Test Helper";
        IsEmailFeatureNotificationShown, IsHiddenTableNotificationShown, IsPromotionNotificationShown : boolean;
        EmailAccountMissingErr: label 'You must specify the email account to send notification email from when field values change. Specify the account in the Notification Email Account field. If no accounts are available, you can add one.';
        UserNotFoundErr: Label 'To start monitoring fields, you must specify the user who will receive notification emails when field values change.', Locked = true;
}

