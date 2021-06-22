codeunit 139197 "Date Time Eval. Notification"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        EnviromentInfoLibrary: Codeunit "Environment Info Test Library";
        EvaluationInfoMsg: Label 'We have improved date and time calculations in configuration packages. Dates and times are now always treated in the local time. This ensures that dates are accurate in regions with a negative offset for UTC.';

    trigger OnRun()
    begin
        // [FEATURE] [Rapid Start]
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,PageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NotificationIsShown()
    begin
        // [GIVEN] In SaaS
        // [GIVEN] The timezone in user preference is set to negative UTC offset
        Initialize();

        // [WHEN] Configuration Packages page is opened
        Page.Run(Page::"Config. Packages");

        // [THEN] Notification is shown, verify in SendNotificationHandler
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandlerThrowError,PageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NotificationIsNotShownOnPrem()
    var
        Notification: Notification;
    begin
        // [GIVEN] The timezone in user preference is set to negative UTC offset
        Initialize();
        // [GIVEN] Not SaaS
        EnviromentInfoLibrary.SetTestabilitySoftwareAsAService(false);

        // [WHEN] Configuration Packages page is opened
        // [THEN] NO notification is shown/ No error is thrown
        Page.Run(Page::"Config. Packages");

        // Needed to make sure the handler is called even when no Notification is sent
        Notification.Message('Dummy');
        asserterror Notification.Send();
    end;

    [Test]
    [HandlerFunctions('PageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NotificationIsNotShownWhenUserPersonalizationDoesNotExist()
    var
        UserPersonalization: Record "User Personalization";
    begin
        // [GIVEN] In SaaS
        Initialize();

        // [When] There is no user personalization for the current user
        UserPersonalization.DeleteAll();

        // [WHEN] Configuration Packages page is opened
        Page.Run(Page::"Config. Packages");

        // [Then] There is no error due unhandled notification UI. So no notification was shown.
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandlerThrowError,PageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure NotificationIsNotShownForNonNegativeUtcOffset()
    var
        UserPersonalization: Record "User Personalization";
        Notification: Notification;
    begin
        // [GIVEN] In SaaS
        Initialize();

        // [GIVEN] The timezone in user preference is set to positive UTC offset
        UserPersonalization.Get(UserSecurityId());
        UserPersonalization."Time Zone" := 'Romance Standard Time'; // UTC+1
        UserPersonalization.Modify();

        // [WHEN] Configuration Packages page is opened
        // [THEN] NO notification is shown/ No error is thrown
        Page.Run(Page::"Config. Packages");

        // Needed to make sure the handler is called even when no Notification is sent
        Notification.Message('Dummy');
        asserterror Notification.Send();
    end;

    [PageHandler]
    procedure PageHandler(var ConfigPackages: TestPage "Config. Packages")
    begin

    end;

    local procedure Initialize()
    var
        UserPersonalization: Record "User Personalization";
    begin
        EnviromentInfoLibrary.SetTestabilitySoftwareAsAService(true);

        if UserPersonalization.Get(UserSecurityId()) then begin
            UserPersonalization."Time Zone" := 'Haiti Standard Time'; // UTC-5
            UserPersonalization.Modify();
        end else begin
            UserPersonalization."User SID" := UserSecurityId();
            UserPersonalization."Time Zone" := 'Haiti Standard Time';
            UserPersonalization.Insert();
        end;
    end;

    [SendNotificationHandler]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
        Assert.ExpectedMessage(EvaluationInfoMsg, Notification.Message);
    end;

    [SendNotificationHandler]
    procedure SendNotificationHandlerThrowError(var Notification: Notification): Boolean
    begin
        Error('No notification was expected.')
    end;
}

