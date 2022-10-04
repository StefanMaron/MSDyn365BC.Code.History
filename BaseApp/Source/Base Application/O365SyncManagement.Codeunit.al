
codeunit 6700 "O365 Sync. Management"
{
    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        OnBeforeOnRun(IsHandled);
        if IsHandled then
            exit;

        CODEUNIT.Run(CODEUNIT::"Exchange Contact Sync.");
        CODEUNIT.Run(CODEUNIT::"Booking Customer Sync.");
        CODEUNIT.Run(CODEUNIT::"Booking Service Sync.");
    end;

    var
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
        ProgressWindow: Dialog;
        BookingsConnectionID: Text;
        ConnectionErr: Label '%1 is unable to connect to Exchange. This may be due to a service outage or invalid credentials.', Comment = '%1 = User who cannot connect';
        LoggingConstTxt: Label 'Contact synchronization.';
        O365RecordMissingErr: Label 'The Office 365 synchronization setup record is not configured correctly.';
        ExchangeConnectionID: Text;
        RegisterConnectionTxt: Label 'Register connection.';
        SetupO365Qst: Label 'Would you like to configure your connection to Office 365 now?';
        BookingsConnectionString: Text;
        ExchangeConnectionString: Text;
        GettingContactsTxt: Label 'Getting Exchange contacts.';
        GettingBookingCustomersTxt: Label 'Getting Booking customers.';
        GettingBookingServicesTxt: Label 'Getting Booking services.';
        NoUserAccessErr: Label 'Could not connect to %1. Verify that %2 is an administrator in the Bookings mailbox.', Comment = '%1 = The Bookings company; %2 = The user';
        JobQueueEntryDescTxt: Label 'Auto-created for retrieval of new data from Outlook and Bookings. Can be deleted if not used. Will be recreated when the feature is activated.';

    [TryFunction]
    [Scope('OnPrem')]
    procedure GetBookingMailboxes(BookingSync: Record "Booking Sync"; var TempBookingMailbox: Record "Booking Mailbox" temporary; MailboxName: Text)
    var
        BookingMailbox: Record "Booking Mailbox";
    begin
        BookingSync."Booking Mailbox Address" := CopyStr(MailboxName, 1, 80);
        RegisterBookingsConnection(BookingSync);
        TempBookingMailbox.Reset();
        TempBookingMailbox.DeleteAll();
        if BookingMailbox.FindSet() then
            repeat
                TempBookingMailbox.Init();
                TempBookingMailbox.TransferFields(BookingMailbox);
                TempBookingMailbox.Insert();
            until BookingMailbox.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CreateExchangeConnection(var ExchangeSync: Record "Exchange Sync") Valid: Boolean
    var
        User: Record User;
        AuthenticationEmail: Text[250];
    begin
        IsO365Setup(false);
        if GetUser(User, ExchangeSync."User ID") then begin
            AuthenticationEmail := User."Authentication Email";
            Valid := ValidateExchangeConnection(AuthenticationEmail, ExchangeSync);
        end;
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure IsO365Setup(AddOnTheFly: Boolean): Boolean
    var
        User: Record User;
        LocalExchangeSync: Record "Exchange Sync";
        AuthenticationEmail: Text[250];
        Password: Text;
        Token: Text;
    begin
        with LocalExchangeSync do begin
            if GetUser(User, UserId()) then
                AuthenticationEmail := User."Authentication Email";

            if not Get(UserId) or
               (AuthenticationEmail = '') or ("Folder ID" = '') or not GetPasswordOrToken(LocalExchangeSync, Password, Token)
            then
                if AddOnTheFly then begin
                    if not OpenSetupWindow() then
                        Error(O365RecordMissingErr)
                end else
                    Error(O365RecordMissingErr);
        end;

        exit(true);
    end;

    procedure OpenSetupWindow(): Boolean
    var
        ExchangeSyncSetup: Page "Exchange Sync. Setup";
    begin
        if Confirm(SetupO365Qst, true) then
            exit(ExchangeSyncSetup.RunModal() = ACTION::OK);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure SetupContactSyncJobQueue()
    var
        JobQueueEntry: Record "Job Queue Entry";
        TwentyFourHours: Integer;
    begin
        if TASKSCHEDULER.CanCreateTask() then
            with JobQueueEntry do begin
                SetRange("Object Type to Run", "Object Type to Run"::Codeunit);
                SetRange("Object ID to Run", CODEUNIT::"O365 Sync. Management");

                if IsEmpty() then begin
                    TwentyFourHours := 24 * 60;
                    InitRecurringJob(TwentyFourHours);
                    "Object Type to Run" := "Object Type to Run"::Codeunit;
                    "Object ID to Run" := CODEUNIT::"O365 Sync. Management";
                    Description := CopyStr(JobQueueEntryDescTxt, 1, MaxStrLen(Description));
                    CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
                end;
            end;
    end;

    [Scope('OnPrem')]
    procedure SyncBookingCustomers(var BookingSync: Record "Booking Sync")
    var
        BookingCustomerSync: Codeunit "Booking Customer Sync.";
    begin
        Session.LogMessage('0000ACP', 'Syncing Bookings Customers', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TraceCategory());
        CheckUserAccess(BookingSync);
        ShowProgress(GettingBookingCustomersTxt);
        RegisterBookingsConnection(BookingSync);
        CloseProgress();
        BookingCustomerSync.SyncRecords(BookingSync);
    end;

    [Scope('OnPrem')]
    procedure SyncBookingServices(var BookingSync: Record "Booking Sync")
    var
        BookingServiceSync: Codeunit "Booking Service Sync.";
    begin
        Session.LogMessage('0000ACQ', 'Syncing Bookings Services', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TraceCategory());
        CheckUserAccess(BookingSync);
        ShowProgress(GettingBookingServicesTxt);
        RegisterBookingsConnection(BookingSync);
        CloseProgress();
        BookingServiceSync.SyncRecords(BookingSync);
    end;

    [Scope('OnPrem')]
    procedure SyncExchangeContacts(ExchangeSync: Record "Exchange Sync"; FullSync: Boolean)
    var
        ExchangeContactSync: Codeunit "Exchange Contact Sync.";
    begin
        Session.LogMessage('0000ACR', 'Syncing Exchange Contacts', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TraceCategory());
        ShowProgress(GettingContactsTxt);
        RegisterExchangeConnection(ExchangeSync);
        CloseProgress();
        ExchangeContactSync.SyncRecords(ExchangeSync, FullSync);
    end;

    procedure LogActivityFailed(RecordID: Variant; UserID: Code[50]; ActivityDescription: Text; ActivityMessage: Text)
    var
        ActivityLog: Record "Activity Log";
    begin
        ActivityMessage := GetLastErrorText + ' ' + ActivityMessage;
        ClearLastError();

        ActivityLog.LogActivityForUser(RecordID, ActivityLog.Status::Failed, CopyStr(LoggingConstTxt, 1, 30),
          ActivityDescription, ActivityMessage, UserID);
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure BuildBookingsConnectionString(var BookingSync: Record "Booking Sync") ConnectionString: Text
    var
        User: Record User;
        ExchangeSync: Record "Exchange Sync";
        Password: Text;
        Token: Text;
    begin
        // Example connection string
        // {UserName}="user@user.onmicrosoft.com";{Password}="1234";{FolderID}="Dynamics NAV";{Uri}=https://outlook.office365.com/EWS/Exchange.asmx
        ExchangeSync.Get(BookingSync."User ID");
        if (not GetUser(User, BookingSync."User ID")) or
           (User."Authentication Email" = '') or
           (not GetPasswordOrToken(ExchangeSync, Password, Token))
        then
            Error(O365RecordMissingErr);

        ConnectionString :=
          StrSubstNo(
            '{UserName}=%1;{Password}=%2;{Token}=%3;{Mailbox}=%4;',
            User."Authentication Email",
            Password,
            Token,
            BookingSync."Booking Mailbox Address");

        if Token <> '' then
            ConnectionString := StrSubstNo('%1;{Uri}=%2', ConnectionString, ExchangeSync.GetExchangeEndpoint());
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure BuildExchangeConnectionString(var ExchangeSync: Record "Exchange Sync") ConnectionString: Text
    var
        User: Record User;
        Token: Text;
        Password: Text;
    begin
        // Example connection string
        // {UserName}="user@user.onmicrosoft.com";{Password}="1234";{FolderID}="Dynamics NAV";{Uri}=https://outlook.office365.com/EWS/Exchange.asmx
        if (not GetUser(User, ExchangeSync."User ID")) or
           (User."Authentication Email" = '') or
           (ExchangeSync."Folder ID" = '') or (not GetPasswordOrToken(ExchangeSync, Password, Token))
        then
            Error(O365RecordMissingErr);

        ConnectionString :=
          StrSubstNo(
            '{UserName}=%1;{Password}=%2;{Token}=%3;{FolderID}=%4;',
            User."Authentication Email",
            Password,
            Token,
            ExchangeSync."Folder ID");

        if Token <> '' then
            ConnectionString := StrSubstNo('%1;{Uri}=%2', ConnectionString, ExchangeSync.GetExchangeEndpoint());
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure RegisterBookingsConnection(BookingSync: Record "Booking Sync")
    var
        ExchangeSync: Record "Exchange Sync";
    begin
        if ExchangeConnectionID <> '' then
            UnregisterConnection(ExchangeConnectionID);

        if BookingsConnectionReady(BookingSync) then
            exit;

        if BookingsConnectionID <> '' then
            UnregisterConnection(BookingsConnectionID);

        ExchangeSync.Get(BookingSync."User ID");
        BookingsConnectionID := CreateGuid();

        if RegisterConnection(ExchangeSync, BookingsConnectionID, BookingsConnectionString) then
            SetConnection(ExchangeSync, BookingsConnectionID);
    end;

    [Scope('OnPrem')]
    procedure RegisterExchangeConnection(ExchangeSync: Record "Exchange Sync")
    begin
        if BookingsConnectionID <> '' then
            UnregisterConnection(BookingsConnectionID);

        if ExchangeConnectionReady(ExchangeSync) then
            exit;

        if ExchangeConnectionID <> '' then
            UnregisterConnection(ExchangeConnectionID);

        ExchangeConnectionID := CreateGuid();
        if RegisterConnection(ExchangeSync, ExchangeConnectionID, ExchangeConnectionString) then
            SetConnection(ExchangeSync, ExchangeConnectionID);
    end;

    procedure TraceCategory(): Text
    begin
        exit('ExchangeSync');
    end;

    [TryFunction]
    local procedure TryRegisterConnection(ConnectionID: Guid; ConnectionString: Text)
    begin
        // Using a try function, as these may throw an exception under certain circumstances (improper credentials, broken connection)
        RegisterTableConnection(TABLECONNECTIONTYPE::Exchange, ConnectionID, ConnectionString);
    end;

    [NonDebuggable]
    local procedure RegisterConnection(ExchangeSync: Record "Exchange Sync"; ConnectionID: Guid; ConnectionString: Text) Success: Boolean
    begin
        Success := TryRegisterConnection(ConnectionID, ConnectionString);
        if not Success then
            ConnectionFailure(ExchangeSync);
    end;

    [TryFunction]
    local procedure TrySetConnection(ConnectionID: Guid)
    begin
        // Using a try function, as these may throw an exception under certain circumstances (improper credentials, broken connection)
        SetDefaultTableConnection(TABLECONNECTIONTYPE::Exchange, ConnectionID);
    end;

    local procedure SetConnection(ExchangeSync: Record "Exchange Sync"; ConnectionID: Guid) Success: Boolean
    begin
        Success := TrySetConnection(ConnectionID);
        if not Success then
            ConnectionFailure(ExchangeSync);
    end;

    [TryFunction]
    local procedure UnregisterConnection(var ConnectionID: Text)
    begin
        UnregisterTableConnection(TABLECONNECTIONTYPE::Exchange, ConnectionID);
        ConnectionID := '';
    end;

    local procedure ConnectionFailure(ExchangeSync: Record "Exchange Sync")
    begin
        with ExchangeSync do begin
            LogActivityFailed(RecordId, RegisterConnectionTxt, StrSubstNo(ConnectionErr, "User ID"), "User ID");
            if GuiAllowed then begin
                CloseProgress();
                Error(ConnectionErr, "User ID");
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure ValidateExchangeConnection(AuthenticationEmail: Text[250]; var ExchangeSync: Record "Exchange Sync") Valid: Boolean
    var
        ExchangeWebServicesServer: Codeunit "Exchange Web Services Server";
        Credentials: DotNet ExchangeCredentials;
        Endpoint: Text[250];
    begin
        CreateExchangeAccountCredentials(ExchangeSync, Credentials);
        Endpoint := ExchangeSync."Exchange Service URI";
        Valid := ExchangeWebServicesServer.InitializeAndValidate(AuthenticationEmail, Endpoint, Credentials);
        if Valid and (Endpoint <> ExchangeSync."Exchange Service URI") then begin
            ExchangeSync.Validate("Exchange Service URI", Endpoint);
            ExchangeSync.Modify();
        end;
    end;

    [NonDebuggable]
    local procedure CreateExchangeAccountCredentials(var ExchangeSync: Record "Exchange Sync"; var Credentials: DotNet ExchangeCredentials)
    var
        User: Record User;
        WebCredentials: DotNet WebCredentials;
        OAuthCredentials: DotNet OAuthCredentials;
        AuthenticationEmail: Text[250];
        Token: Text;
        Password: Text;
    begin
        with ExchangeSync do begin
            if GetUser(User, "User ID") then
                AuthenticationEmail := User."Authentication Email";
            if AuthenticationEmail = '' then
                Error(O365RecordMissingErr);
            if not GetPasswordOrToken(ExchangeSync, Password, Token) then
                Error(O365RecordMissingErr);

            if Token <> '' then
                Credentials := OAuthCredentials.OAuthCredentials(Token)
            else
                Credentials := WebCredentials.WebCredentials(AuthenticationEmail, Password);
        end;
    end;

    local procedure GetUser(var User: Record User; UserID: Text[50]): Boolean
    begin
        User.SetRange("User Name", UserID);
        exit(User.FindFirst());
    end;

    procedure ShowProgress(Message: Text)
    begin
        if GuiAllowed then begin
            CloseProgress();
            ProgressWindow.Open(Message);
        end;
    end;

    procedure CloseProgress()
    begin
        if GuiAllowed then
            if TryCloseProgress() then;
    end;

    [TryFunction]
    local procedure TryCloseProgress()
    begin
        ProgressWindow.Close();
    end;

    [NonDebuggable]
    local procedure BookingsConnectionReady(BookingSync: Record "Booking Sync") Ready: Boolean
    var
        NewConnectionString: Text;
    begin
        NewConnectionString := BuildBookingsConnectionString(BookingSync);
        Ready := (BookingsConnectionID <> '') and (NewConnectionString = BookingsConnectionString);
        BookingsConnectionString := NewConnectionString;
    end;

    [NonDebuggable]
    local procedure ExchangeConnectionReady(ExchangeSync: Record "Exchange Sync") Ready: Boolean
    var
        NewConnectionString: Text;
    begin
        NewConnectionString := BuildExchangeConnectionString(ExchangeSync);
        Ready := (ExchangeConnectionID <> '') and (NewConnectionString = ExchangeConnectionString);
        ExchangeConnectionString := NewConnectionString;
    end;

    [NonDebuggable]
    [Scope('OnPrem')]
    local procedure GetPasswordOrToken(ExchangeSync: Record "Exchange Sync"; var Password: Text; var Token: Text): Boolean
    var
        AzureADMgt: Codeunit "Azure AD Mgt.";
        Value: Text;
    begin
        Token := AzureADMgt.GetAccessToken(AzureADMgt.GetO365Resource(), AzureADMgt.GetO365ResourceName(), false);
        if (Token = '') and not IsNullGuid(ExchangeSync."Exchange Account Password Key") then
            if IsolatedStorageManagement.Get(ExchangeSync."Exchange Account Password Key", DATASCOPE::Company, Value) then
                Password := Value;

        exit((Token <> '') or (Password <> ''));
    end;

    local procedure CheckUserAccess(BookingSync: Record "Booking Sync")
    var
        ExchangeSync: Record "Exchange Sync";
        Credentials: DotNet ExchangeCredentials;
        ExchangeServiceFactory: DotNet ServiceWrapperFactory;
        ExchangeService: DotNet ExchangeServiceWrapper;
    begin
        ExchangeSync.Get(BookingSync."User ID");
        ExchangeService := ExchangeServiceFactory.CreateServiceWrapper2013();
        CreateExchangeAccountCredentials(ExchangeSync, Credentials);
        ExchangeService.SetNetworkCredential(Credentials);
        ExchangeService.ExchangeServiceUrl := ExchangeSync.GetExchangeEndpoint();

        if not ExchangeService.CanAccessBookingMailbox(BookingSync."Booking Mailbox Address") then
            Error(NoUserAccessErr, BookingSync."Booking Mailbox Name", BookingSync."User ID");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var IsHandled: Boolean)
    begin
    end;
}
