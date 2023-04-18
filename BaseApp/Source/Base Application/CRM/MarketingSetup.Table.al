table 5079 "Marketing Setup"
{
    Caption = 'Marketing Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Contact Nos."; Code[20])
        {
            Caption = 'Contact Nos.';
            TableRelation = "No. Series";
        }
        field(3; "Campaign Nos."; Code[20])
        {
            AccessByPermission = TableData Campaign = R;
            Caption = 'Campaign Nos.';
            TableRelation = "No. Series";
        }
        field(4; "Segment Nos."; Code[20])
        {
            Caption = 'Segment Nos.';
            TableRelation = "No. Series";
        }
        field(5; "To-do Nos."; Code[20])
        {
            Caption = 'Task Nos.';
            TableRelation = "No. Series";
        }
        field(6; "Opportunity Nos."; Code[20])
        {
            AccessByPermission = TableData "Sales Cycle" = R;
            Caption = 'Opportunity Nos.';
            TableRelation = "No. Series";
        }
        field(7; "Bus. Rel. Code for Customers"; Code[10])
        {
            Caption = 'Bus. Rel. Code for Customers';
            TableRelation = "Business Relation";
        }
        field(8; "Bus. Rel. Code for Vendors"; Code[10])
        {
            Caption = 'Bus. Rel. Code for Vendors';
            TableRelation = "Business Relation";
        }
        field(9; "Bus. Rel. Code for Bank Accs."; Code[10])
        {
            Caption = 'Bus. Rel. Code for Bank Accs.';
            TableRelation = "Business Relation";
        }
        field(10; "Bus. Rel. Code for Employees"; Code[10])
        {
            Caption = 'Bus. Rel. Code for Employees';
            TableRelation = "Business Relation";
        }
        field(22; "Inherit Salesperson Code"; Boolean)
        {
            Caption = 'Inherit Salesperson Code';
            InitValue = true;
        }
        field(23; "Inherit Territory Code"; Boolean)
        {
            Caption = 'Inherit Territory Code';
            InitValue = true;
        }
        field(24; "Inherit Country/Region Code"; Boolean)
        {
            Caption = 'Inherit Country/Region Code';
            InitValue = true;
        }
        field(25; "Inherit Language Code"; Boolean)
        {
            Caption = 'Inherit Language Code';
            InitValue = true;
        }
        field(26; "Inherit Address Details"; Boolean)
        {
            Caption = 'Inherit Address Details';
            InitValue = true;
        }
        field(27; "Inherit Communication Details"; Boolean)
        {
            Caption = 'Inherit Communication Details';
            InitValue = true;
        }
        field(28; "Default Salesperson Code"; Code[20])
        {
            Caption = 'Default Salesperson Code';
            TableRelation = "Salesperson/Purchaser" where(Blocked = const(false));
        }
        field(29; "Default Territory Code"; Code[10])
        {
            Caption = 'Default Territory Code';
            TableRelation = Territory;
        }
        field(30; "Default Country/Region Code"; Code[10])
        {
            Caption = 'Default Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(31; "Default Language Code"; Code[10])
        {
            Caption = 'Default Language Code';
            TableRelation = Language;
        }
        field(33; "Default Sales Cycle Code"; Code[10])
        {
            Caption = 'Default Sales Cycle Code';
            TableRelation = "Sales Cycle";
        }
        field(35; "Attachment Storage Type"; Enum "Setup Attachment Storage Type")
        {
            Caption = 'Attachment Storage Type';
        }
        field(36; "Attachment Storage Location"; Text[250])
        {
            Caption = 'Attachment Storage Location';
        }
        field(37; "Autosearch for Duplicates"; Boolean)
        {
            Caption = 'Autosearch for Duplicates';
            InitValue = true;

            trigger OnValidate()
            begin
                if "Autosearch for Duplicates" then
                    Validate("Maintain Dupl. Search Strings", true);
            end;
        }
        field(38; "Search Hit %"; Integer)
        {
            Caption = 'Search Hit %';
            InitValue = 60;
            MaxValue = 100;
            MinValue = 1;
            NotBlank = true;
        }
        field(39; "Maintain Dupl. Search Strings"; Boolean)
        {
            Caption = 'Maintain Dupl. Search Strings';
            InitValue = true;
            NotBlank = true;

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                "Autosearch for Duplicates" := "Maintain Dupl. Search Strings";
                if "Maintain Dupl. Search Strings" and not xRec."Maintain Dupl. Search Strings" then
                    if ConfirmManagement.GetResponse(DuplicateSearchQst, true) then
                        REPORT.Run(REPORT::"Generate Dupl. Search String");
            end;
        }
        field(50; "Mergefield Language ID"; Integer)
        {
            BlankZero = true;
            Caption = 'Mergefield Language ID';
            TableRelation = "Windows Language";
        }
        field(51; "Def. Company Salutation Code"; Code[10])
        {
            Caption = 'Def. Company Salutation Code';
            TableRelation = Salutation;
        }
        field(52; "Default Person Salutation Code"; Code[10])
        {
            Caption = 'Default Person Salutation Code';
            TableRelation = Salutation;
        }
        field(53; "Default Correspondence Type"; Enum "Correspondence Type")
        {
            Caption = 'Default Correspondence Type';
        }
        field(56; "Queue Folder Path"; Text[250])
        {
            Caption = 'Queue Folder Path';
            Editable = false;
            ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
#if not CLEAN22
            ObsoleteState = Pending;
            ObsoleteTag = '22.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
#endif   
        }
        field(57; "Queue Folder UID"; BLOB)
        {
            Caption = 'Queue Folder UID';
            ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
#if not CLEAN22
            ObsoleteState = Pending;
            ObsoleteTag = '22.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
#endif   
        }
        field(59; "Storage Folder Path"; Text[250])
        {
            Caption = 'Storage Folder Path';
            Editable = false;
            ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
#if not CLEAN22
            ObsoleteState = Pending;
            ObsoleteTag = '22.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
#endif   
        }
        field(60; "Storage Folder UID"; BLOB)
        {
            Caption = 'Storage Folder UID';
            ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
#if not CLEAN22
            ObsoleteState = Pending;
            ObsoleteTag = '22.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
#endif
        }
        field(67; "Default To-do Date Calculation"; DateFormula)
        {
            Caption = 'Default Task Date Calculation';
        }
        field(69; "Autodiscovery E-Mail Address"; Text[250])
        {
            Caption = 'Autodiscovery Email Address';
            ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
#if not CLEAN22
            ObsoleteState = Pending;
            ObsoleteTag = '22.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
#endif

#if not CLEAN22
            trigger OnValidate()
            begin
                ResetExchangeTenantId();
            end;
#endif
        }
        field(70; "Email Batch Size"; Integer)
        {
            Caption = 'Email Batch Size';
            MinValue = 0;
            ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
#if not CLEAN22
            ObsoleteState = Pending;
            ObsoleteTag = '22.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
#endif
        }
        field(71; "Exchange Service URL"; Text[250])
        {
            Caption = 'Exchange Service URL';
            ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
#if not CLEAN22
            ObsoleteState = Pending;
            ObsoleteTag = '22.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
#endif

#if not CLEAN22
            trigger OnValidate()
            begin
                ResetExchangeTenantId();
            end;
#endif
        }
        field(72; "Exchange Account User Name"; Text[250])
        {
            Caption = 'Exchange Account User Name';
            DataClassification = EndUserIdentifiableInformation;
            ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
#if not CLEAN22
            ObsoleteState = Pending;
            ObsoleteTag = '22.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
#endif
        }
        field(73; "Exchange Account Password Key"; Guid)
        {
            Caption = 'Exchange Account Password Key';
        }
        field(74; "Sync with Microsoft Graph"; Boolean)
        {
            Caption = 'Sync with Microsoft Graph';
            Editable = false;
            ObsoleteState = Removed;
            ObsoleteReason = 'The field will be removed. The API that this field was used for was discontinued.';
            ObsoleteTag = '20.0';
        }
        field(75; "WebHook Run Notification As"; Guid)
        {
            Caption = 'WebHook Run Notification As';
        }
        field(76; "Cust. Template Company Code"; Code[10])
        {
            Caption = 'Cust. Template Company Code';
        }
        field(77; "Cust. Template Person Code"; Code[10])
        {
            Caption = 'Cust. Template Person Code';
        }
        field(78; "Exchange Tenant Id Key"; Guid)
        {
            Caption = 'Exchange Tenant Id Key';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(79; "Exchange Client Id"; Text[250])
        {
            Caption = 'Exchange Client Id';
            DataClassification = EndUserIdentifiableInformation;
            ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
#if not CLEAN22
            ObsoleteState = Pending;
            ObsoleteTag = '22.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
#endif

#if not CLEAN22
            trigger OnValidate()
            begin
                ResetExchangeTenantId();
            end;
#endif
        }
        field(80; "Exchange Client Secret Key"; Guid)
        {
            Caption = 'Exchange Client Secret Key';
            DataClassification = EndUserPseudonymousIdentifiers;
            ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
#if not CLEAN22
            ObsoleteState = Pending;
            ObsoleteTag = '22.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
#endif

#if not CLEAN22
            trigger OnValidate()
            begin
                ResetExchangeTenantId();
            end;
#endif
        }
        field(81; "Email Logging Enabled"; Boolean)
        {
            Caption = 'Email Logging Enabled';
            DataClassification = CustomerContent;
            ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
#if not CLEAN22
            ObsoleteState = Pending;
            ObsoleteTag = '22.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
#endif
        }
        field(82; "Exchange Redirect URL"; Text[2048])
        {
            Caption = 'Exchange Redirect URL';
            DataClassification = EndUserIdentifiableInformation;
            ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
#if not CLEAN22
            ObsoleteState = Pending;
            ObsoleteTag = '22.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
#endif

#if not CLEAN22
            trigger OnValidate()
            begin
                ResetExchangeTenantId();
            end;
#endif
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
#if not CLEAN22
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
        Text010: Label 'The queue and storage folders cannot be the same. Choose a different folder.';
        ExchangeAccountNotConfiguredErr: Label 'You must set up an Exchange account for email logging.';
#endif
        DuplicateSearchQst: Label 'Do you want to generate duplicate search strings?';
#if not CLEAN22
        EmailLoggingTelemetryCategoryTxt: Label 'AL Email Logging', Locked = true;
        ConfigureExchangeAccountTxt: Label 'Configure Exchange account.', Locked = true;
        ExchangeAccountNotConfiguredTxt: Label 'Exchange account is not configured.', Locked = true;
        ExchangeAccountConfiguredTxt: Label 'Exchange account is configured.', Locked = true;
        QueueFolderNotSetTxt: Label 'Queue folder is not set.', Locked = true;
        QueueFolderSetTxt: Label 'Queue folder is set.', Locked = true;
        StorageFolderNotSetTxt: Label 'Storage folder is not set.', Locked = true;
        StorageFolderSetTxt: Label 'Storage folder is set.', Locked = true;
        SetExchangeAccountPasswordTxt: Label 'Set Exchange account password.', Locked = true;
        ExchangeTenantIdClearedTxt: Label 'Exchange tenant ID is cleared.', Locked = true;
        ExchangeTenantIdSetTxt: Label 'Exchange tenant ID is set.', Locked = true;
#endif

#if not CLEAN22
    [Obsolete('Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0', '22.0')]
    [Scope('OnPrem')]
    procedure SetQueueFolder(ExchangeFolder: Record "Exchange Folder")
    var
        InStream: InStream;
        OutStream: OutStream;
    begin
        if (ExchangeFolder.FullPath = "Storage Folder Path") and (ExchangeFolder.FullPath <> '') then begin
            Session.LogMessage('0000BXS', QueueFolderNotSetTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            Error(Text010);
        end;
        if (ExchangeFolder.ReadUniqueID() = GetStorageFolderUID()) and ExchangeFolder."Unique ID".HasValue() then begin
            Session.LogMessage('0000BXT', QueueFolderNotSetTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            Error(Text010);
        end;

        Session.LogMessage('0000BXU', QueueFolderSetTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);

        "Queue Folder Path" := ExchangeFolder.FullPath;

        ExchangeFolder."Unique ID".CreateInStream(InStream);
        "Queue Folder UID".CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);
        Modify();
    end;

    [Obsolete('Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0', '22.0')]
    [Scope('OnPrem')]
    procedure SetStorageFolder(ExchangeFolder: Record "Exchange Folder")
    var
        InStream: InStream;
        OutStream: OutStream;
    begin
        if (ExchangeFolder.FullPath = "Queue Folder Path") and (ExchangeFolder.FullPath <> '') then begin
            Session.LogMessage('0000BXV', StorageFolderNotSetTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            Error(Text010);
        end;
        if (ExchangeFolder.ReadUniqueID() = GetQueueFolderUID()) and ExchangeFolder."Unique ID".HasValue() then begin
            Session.LogMessage('0000BXW', StorageFolderNotSetTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            Error(Text010);
        end;

        Session.LogMessage('0000BXX', StorageFolderSetTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);

        "Storage Folder Path" := ExchangeFolder.FullPath;

        ExchangeFolder."Unique ID".CreateInStream(InStream);
        "Storage Folder UID".CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);
        Modify();
    end;

    [Obsolete('Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0', '22.0')]
    procedure GetQueueFolderUID() Return: Text
    var
        Stream: InStream;
    begin
        CalcFields("Queue Folder UID");
        "Queue Folder UID".CreateInStream(Stream);
        Stream.ReadText(Return);
    end;

    [Obsolete('Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0', '22.0')]
    procedure GetStorageFolderUID() Return: Text
    var
        Stream: InStream;
    begin
        CalcFields("Storage Folder UID");
        "Storage Folder UID".CreateInStream(Stream);
        Stream.ReadText(Return);
    end;

    [Obsolete('Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0', '22.0')]
    [NonDebuggable]
    [Scope('OnPrem')]
    procedure SetExchangeAccountPassword(Password: Text)
    begin
        Session.LogMessage('0000BY0', SetExchangeAccountPasswordTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);

        if Password = '' then
            if not IsNullGuid("Exchange Account Password Key") then begin
                IsolatedStorageManagement.Delete("Exchange Account Password Key", DATASCOPE::Company);
                exit;
            end;

        if IsNullGuid("Exchange Account Password Key") then begin
            "Exchange Account Password Key" := CreateGuid();
            Modify();
        end;

        IsolatedStorageManagement.Set("Exchange Account Password Key", Password, DATASCOPE::Company);
    end;

    [Obsolete('Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0', '22.0')]
    [NonDebuggable]
    [Scope('OnPrem')]
    procedure CreateExchangeAccountCredentials(var WebCredentials: DotNet WebCredentials)
    var
        Value: Text;
    begin
        Session.LogMessage('0000BY1', ConfigureExchangeAccountTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);

        if "Exchange Account User Name" = '' then begin
            Session.LogMessage('0000BY2', ExchangeAccountNotConfiguredTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            Error(ExchangeAccountNotConfiguredErr);
        end;
        if IsNullGuid("Exchange Account Password Key") or
           not ISOLATEDSTORAGE.Contains("Exchange Account Password Key", DATASCOPE::Company)
        then begin
            Session.LogMessage('0000BY3', ExchangeAccountNotConfiguredTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            Error(ExchangeAccountNotConfiguredErr);
        end;

        IsolatedStorageManagement.Get("Exchange Account Password Key", DATASCOPE::Company, Value);
        WebCredentials := WebCredentials.WebCredentials("Exchange Account User Name", Value);

        Session.LogMessage('0000BY4', ExchangeAccountConfiguredTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
    end;
#endif

    procedure TrySetWebhookSubscriptionUser(UserSecurityID: Guid): Boolean
    var
        WebhookManagement: Codeunit "Webhook Management";
    begin
        if "WebHook Run Notification As" <> UserSecurityID then
            if WebhookManagement.IsValidNotificationRunAsUser(UserSecurityID) then begin
                "WebHook Run Notification As" := UserSecurityID;
                exit(true);
            end;

        exit(false);
    end;

    procedure GetWebhookSubscriptionUser(): Guid
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        if MarketingSetup.Get() then
            exit(MarketingSetup."WebHook Run Notification As");
    end;

    local procedure UserIsNotValidForWebhookSubscription(UserSecurityID: Guid): Boolean
    var
        WebhookManagement: Codeunit "Webhook Management";
    begin
        exit(not WebhookManagement.IsValidNotificationRunAsUser(UserSecurityID));
    end;

    local procedure CurrentUserHasPermissionsForWebhookSubscription(): Boolean
    var
        Contact: Record Contact;
        Customer: Record Customer;
    begin
        exit(Customer.WritePermission and Contact.WritePermission)
    end;

    procedure TrySetWebhookSubscriptionUserAsCurrentUser(): Guid
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        if not MarketingSetup.Get() then
            MarketingSetup.Insert(true);

        if UserIsNotValidForWebhookSubscription(MarketingSetup."WebHook Run Notification As") then
            if CurrentUserHasPermissionsForWebhookSubscription() then
                if MarketingSetup.TrySetWebhookSubscriptionUser(UserSecurityId()) then
                    MarketingSetup.Modify(true);

        exit(MarketingSetup."WebHook Run Notification As");
    end;

    procedure GetCustomerTemplate(ContactType: Option Company,Person): Code[10]
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get();

        case ContactType of
            ContactType::Company:
                exit(MarketingSetup."Cust. Template Company Code");
            ContactType::Person:
                exit(MarketingSetup."Cust. Template Person Code");
        end
    end;

#if not CLEAN22
    [Obsolete('Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0', '22.0')]
    [Scope('OnPrem')]
    [NonDebuggable]
    procedure ResetExchangeTenantId()
    begin
        SetExchangeTenantId('');
    end;

    [Obsolete('Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0', '22.0')]
    [Scope('OnPrem')]
    [NonDebuggable]
    procedure SetExchangeTenantId(TenantId: Text)
    begin
        if TenantId = '' then
            if not IsNullGuid("Exchange Tenant Id Key") then begin
                IsolatedStorageManagement.Delete("Exchange Tenant Id Key", DATASCOPE::Company);
                Session.LogMessage('0000D9K', ExchangeTenantIdClearedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
                exit;
            end;

        if IsNullGuid("Exchange Tenant Id Key") then begin
            "Exchange Tenant Id Key" := CreateGuid();
            Modify();
        end;

        IsolatedStorageManagement.Set("Exchange Tenant Id Key", TenantId, DATASCOPE::Company);
        Session.LogMessage('0000D9J', ExchangeTenantIdSetTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
    end;

    [Obsolete('Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0', '22.0')]
    [Scope('OnPrem')]
    [NonDebuggable]
    procedure GetExchangeTenantId(): Text
    var
        TenantId: Text;
    begin
        if IsNullGuid("Exchange Tenant Id Key") or
           not IsolatedStorage.Contains("Exchange Tenant Id Key", DATASCOPE::Company)
        then
            exit('');

        IsolatedStorageManagement.Get("Exchange Tenant Id Key", DATASCOPE::Company, TenantId);
        exit(TenantId);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure SetExchangeClientSecret(ClientSecret: Text)
    begin
        if ClientSecret = '' then
            if not IsNullGuid("Exchange Client Secret Key") then begin
                IsolatedStorageManagement.Delete("Exchange Client Secret Key", DATASCOPE::Company);
                exit;
            end;

        if IsNullGuid("Exchange Client Secret Key") then begin
            "Exchange Client Secret Key" := CreateGuid();
            Modify();
        end;

        IsolatedStorageManagement.Set("Exchange Client Secret Key", ClientSecret, DATASCOPE::Company);
    end;

    [Obsolete('Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0', '22.0')]
    [Scope('OnPrem')]
    [NonDebuggable]
    procedure GetExchangeClientSecret(): Text
    var
        ClientSecret: Text;
    begin
        if IsNullGuid("Exchange Client Secret Key") or
           not IsolatedStorage.Contains("Exchange Client Secret Key", DATASCOPE::Company)
        then begin
            Session.LogMessage('0000CF9', ExchangeAccountNotConfiguredTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EmailLoggingTelemetryCategoryTxt);
            exit('');
        end;

        IsolatedStorageManagement.Get("Exchange Client Secret Key", DATASCOPE::Company, ClientSecret);
        exit(ClientSecret);
    end;
#endif
}

