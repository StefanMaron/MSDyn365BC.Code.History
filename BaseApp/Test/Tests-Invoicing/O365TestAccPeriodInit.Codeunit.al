codeunit 138903 "O365 Test Acc. Period Init"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Invoicing] [Accounting Period]
    end;

    var
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        TelemetryBackgroundScheduler: Codeunit "Telemetry Background Scheduler";
        InvoiceTok: Label 'INV', Locked = true;
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestStartWithNoAccountingPeriods()
    var
        AccountingPeriod: Record "Accounting Period";
        ReferenceDate: Date;
    begin
        Initialize;

        // [HAVING] No accounting periods (first login).
        SetItemsToFiFoCosting;
        SetAccountPeriods(0D);
        ReferenceDate := WorkDate;
        LibraryLowerPermissions.SetO365BusFull;

        // [WHEN] The user opens the company
        OpenCompany;

        // [THEN] The accounting periods are created for the first 5 years
        Assert.AreEqual(13, AccountingPeriod.Count, 'Wrong number of accounting periods');
        AccountingPeriod.FindFirst;
        Assert.IsTrue(AccountingPeriod."Starting Date" <= ReferenceDate, 'Start date is not less than ReferenceDate');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestStartWithTooFewAccountingPeriods()
    var
        AccountingPeriod: Record "Accounting Period";
        ReferenceDate: Date;
    begin
        Initialize;

        // [HAVING] No accounting periods (first login).
        SetItemsToFiFoCosting;
        ReferenceDate := CalcDate('<-CY>', WorkDate);
        SetAccountPeriods(CalcDate('<-CY>', CalcDate('<1Y>', ReferenceDate))); // should trigger creation of new accounting periods

        LibraryLowerPermissions.SetAccountPayables;
        LibraryLowerPermissions.AddO365BusFull;

        // [WHEN] The user opens the company
        OpenCompany;

        // [THEN] The accounting periods are created for the next year
        Assert.AreEqual(13, AccountingPeriod.Count, 'Wrong number of accounting periods');
        AccountingPeriod.FindLast;
        Assert.IsTrue(AccountingPeriod."Starting Date" > ReferenceDate + 365, 'Start date is not greater than ReferenceDate');
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure TestStartWithEnoughAccountingPeriods()
    var
        AccountingPeriod: Record "Accounting Period";
        ReferenceDate: Date;
    begin
        Initialize;

        // [HAVING] No accounting periods (first login).
        SetItemsToFiFoCosting;
        ReferenceDate := WorkDate;
        SetAccountPeriods(CalcDate('<-CY>', ReferenceDate + 800)); // should not trigger creation of new accounting periods

        LibraryLowerPermissions.SetAccountReceivables;
        LibraryLowerPermissions.AddO365BusFull;

        // [WHEN] The user opens the company
        OpenCompany;

        // [THEN] The accounting periods are created for the first 5 years
        Assert.AreEqual(1, AccountingPeriod.Count, 'Wrong number of accounting periods');
        AccountingPeriod.FindLast;
        Assert.IsTrue(AccountingPeriod."Starting Date" > ReferenceDate + 365, 'Start date is not greater than ReferenceDate');
    end;

    local procedure SetItemsToFiFoCosting()
    var
        Item: Record Item;
    begin
        Item.ModifyAll("Costing Method", Item."Costing Method"::FIFO);
    end;

    local procedure SetAccountPeriods(StartDate: Date)
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        AccountingPeriod.DeleteAll();
        if StartDate = 0D then
            exit;
        AccountingPeriod.Init();
        AccountingPeriod."Starting Date" := StartDate;
        AccountingPeriod."New Fiscal Year" := true;
        AccountingPeriod.Insert();
    end;

    local procedure OpenCompany()
    var
        LogInManagement: Codeunit LogInManagement;
    begin
        LogInManagement.CompanyOpen;
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        EnvironmentInfoTestLibrary.SetAppId(InvoiceTok);
        BindSubscription(TelemetryBackgroundScheduler);
        BindSubscription(EnvironmentInfoTestLibrary);

        IsInitialized := true;
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        Assert.Fail('No notification should be thrown.');
    end;
}

