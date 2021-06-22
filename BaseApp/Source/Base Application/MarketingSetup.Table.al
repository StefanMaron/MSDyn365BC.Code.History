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
            TableRelation = "Salesperson/Purchaser";
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
        field(35; "Attachment Storage Type"; Option)
        {
            Caption = 'Attachment Storage Type';
            OptionCaption = 'Embedded,Disk File';
            OptionMembers = Embedded,"Disk File";
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
        }
        field(57; "Queue Folder UID"; BLOB)
        {
            Caption = 'Queue Folder UID';
        }
        field(59; "Storage Folder Path"; Text[250])
        {
            Caption = 'Storage Folder Path';
            Editable = false;
        }
        field(60; "Storage Folder UID"; BLOB)
        {
            Caption = 'Storage Folder UID';
        }
        field(67; "Default To-do Date Calculation"; DateFormula)
        {
            Caption = 'Default Task Date Calculation';
        }
        field(69; "Autodiscovery E-Mail Address"; Text[250])
        {
            Caption = 'Autodiscovery Email Address';

            trigger OnValidate()
            begin
                ResetExchangeTenantId();
            end;
        }
        field(70; "Email Batch Size"; Integer)
        {
            Caption = 'Email Batch Size';
            MinValue = 0;
        }
        field(71; "Exchange Service URL"; Text[250])
        {
            Caption = 'Exchange Service URL';

            trigger OnValidate()
            begin
                ResetExchangeTenantId();
            end;
        }
        field(72; "Exchange Account User Name"; Text[250])
        {
            Caption = 'Exchange Account User Name';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(73; "Exchange Account Password Key"; Guid)
        {
            Caption = 'Exchange Account Password Key';
        }
        field(74; "Sync with Microsoft Graph"; Boolean)
        {
            Caption = 'Sync with Microsoft Graph';
            Editable = false;

            trigger OnValidate()
            var
                WebhookManagement: Codeunit "Webhook Management";
            begin
                if WebhookManagement.IsSyncAllowed and "Sync with Microsoft Graph" then begin
                    CODEUNIT.Run(CODEUNIT::"Graph Data Setup");
                    "WebHook Run Notification As" := GetWebhookSubscriptionUser;
                    if UserIsNotValidForWebhookSubscription("WebHook Run Notification As") then
                        if CurrentUserHasPermissionsForWebhookSubscription then
                            TrySetWebhookSubscriptionUser(UserSecurityId);
                end else
                    "Sync with Microsoft Graph" := false;
            end;
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

            trigger OnValidate()
            begin
                ResetExchangeTenantId();
            end;
        }
        field(80; "Exchange Client Secret Key"; Guid)
        {
            Caption = 'Exchange Client Secret Key';
            DataClassification = EndUserPseudonymousIdentifiers;

            trigger OnValidate()
            begin
                ResetExchangeTenantId();
            end;
        }
        field(81; "Email Logging Enabled"; Boolean)
        {
            Caption = 'Email Logging Enabled';
            DataClassification = CustomerContent;
        }
        field(82; "Exchange Redirect URL"; Text[2048])
        {
            Caption = 'Exchange Redirect URL';
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                ResetExchangeTenantId();
            end;
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
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
        Text010: Label 'The queue and storage folders cannot be the same. Choose a different folder.';
        ExchangeAccountNotConfiguredErr: Label 'You must set up an Exchange account for email logging.';
        DuplicateSearchQst: Label 'Do you want to generate duplicate search strings?';
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

    [Scope('OnPrem')]
    procedure SetQueueFolder(ExchangeFolder: Record "Exchange Folder")
    var
        InStream: InStream;
        OutStream: OutStream;
    begin
        if (ExchangeFolder.FullPath = "Storage Folder Path") and (ExchangeFolder.FullPath <> '') then begin
            SendTraceTag('0000BXS', EmailLoggingTelemetryCategoryTxt, Verbosity::Warning, QueueFolderNotSetTxt, DataClassification::SystemMetadata);
            Error(Text010);
        end;
        if (ExchangeFolder.ReadUniqueID = GetStorageFolderUID) and ExchangeFolder."Unique ID".HasValue then begin
            SendTraceTag('0000BXT', EmailLoggingTelemetryCategoryTxt, Verbosity::Warning, QueueFolderNotSetTxt, DataClassification::SystemMetadata);
            Error(Text010);
        end;

        SendTraceTag('0000BXU', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, QueueFolderSetTxt, DataClassification::SystemMetadata);

        "Queue Folder Path" := ExchangeFolder.FullPath;

        ExchangeFolder."Unique ID".CreateInStream(InStream);
        "Queue Folder UID".CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);
        Modify;
    end;

    [Scope('OnPrem')]
    procedure SetStorageFolder(ExchangeFolder: Record "Exchange Folder")
    var
        InStream: InStream;
        OutStream: OutStream;
    begin
        if (ExchangeFolder.FullPath = "Queue Folder Path") and (ExchangeFolder.FullPath <> '') then begin
            SendTraceTag('0000BXV', EmailLoggingTelemetryCategoryTxt, Verbosity::Warning, StorageFolderNotSetTxt, DataClassification::SystemMetadata);
            Error(Text010);
        end;
        if (ExchangeFolder.ReadUniqueID = GetQueueFolderUID) and ExchangeFolder."Unique ID".HasValue then begin
            SendTraceTag('0000BXW', EmailLoggingTelemetryCategoryTxt, Verbosity::Warning, StorageFolderNotSetTxt, DataClassification::SystemMetadata);
            Error(Text010);
        end;

        SendTraceTag('0000BXX', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, StorageFolderSetTxt, DataClassification::SystemMetadata);

        "Storage Folder Path" := ExchangeFolder.FullPath;

        ExchangeFolder."Unique ID".CreateInStream(InStream);
        "Storage Folder UID".CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);
        Modify;
    end;

    procedure GetQueueFolderUID() Return: Text
    var
        Stream: InStream;
    begin
        CalcFields("Queue Folder UID");
        "Queue Folder UID".CreateInStream(Stream);
        Stream.ReadText(Return);
    end;

    procedure GetStorageFolderUID() Return: Text
    var
        Stream: InStream;
    begin
        CalcFields("Storage Folder UID");
        "Storage Folder UID".CreateInStream(Stream);
        Stream.ReadText(Return);
    end;

    [Scope('OnPrem')]
    procedure SetExchangeAccountPassword(Password: Text)
    begin
        SendTraceTag('0000BY0', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, SetExchangeAccountPasswordTxt, DataClassification::SystemMetadata);

        if IsNullGuid("Exchange Account Password Key") then
            "Exchange Account Password Key" := CreateGuid;

        IsolatedStorageManagement.Set("Exchange Account Password Key", Password, DATASCOPE::Company);
    end;

    [Scope('OnPrem')]
    procedure CreateExchangeAccountCredentials(var WebCredentials: DotNet WebCredentials)
    var
        Value: Text;
    begin
        SendTraceTag('0000BY1', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, ConfigureExchangeAccountTxt, DataClassification::SystemMetadata);

        if "Exchange Account User Name" = '' then begin
            SendTraceTag('0000BY2', EmailLoggingTelemetryCategoryTxt, Verbosity::Warning, ExchangeAccountNotConfiguredTxt, DataClassification::SystemMetadata);
            Error(ExchangeAccountNotConfiguredErr);
        end;
        if IsNullGuid("Exchange Account Password Key") or
           not ISOLATEDSTORAGE.Contains("Exchange Account Password Key", DATASCOPE::Company)
        then begin
            SendTraceTag('0000BY3', EmailLoggingTelemetryCategoryTxt, Verbosity::Warning, ExchangeAccountNotConfiguredTxt, DataClassification::SystemMetadata);
            Error(ExchangeAccountNotConfiguredErr);
        end;

        IsolatedStorageManagement.Get("Exchange Account Password Key", DATASCOPE::Company, Value);
        WebCredentials := WebCredentials.WebCredentials("Exchange Account User Name", Value);

        SendTraceTag('0000BY4', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, ExchangeAccountConfiguredTxt, DataClassification::SystemMetadata);
    end;

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
        if MarketingSetup.Get then
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
        if not MarketingSetup.Get then
            MarketingSetup.Insert(true);

        if UserIsNotValidForWebhookSubscription(MarketingSetup."WebHook Run Notification As") then
            if CurrentUserHasPermissionsForWebhookSubscription then
                if MarketingSetup.TrySetWebhookSubscriptionUser(UserSecurityId) then
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

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure ResetExchangeTenantId()
    var
        EmptyGuid: Guid;
    begin
        SetExchangeTenantId(EmptyGuid);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure SetExchangeTenantId(TenantId: Text)
    begin
        if IsNullGuid("Exchange Tenant Id Key") then begin
            "Exchange Tenant Id Key" := CreateGuid();
            Modify();
        end;

        IsolatedStorageManagement.Set("Exchange Tenant Id Key", TenantId, DATASCOPE::Company);
        if TenantId <> '' then
            SendTraceTag('0000D9J', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, ExchangeTenantIdSetTxt, DataClassification::SystemMetadata)
        else
            SendTraceTag('0000D9K', EmailLoggingTelemetryCategoryTxt, Verbosity::Normal, ExchangeTenantIdClearedTxt, DataClassification::SystemMetadata);
    end;


    [Scope('OnPrem')]
    [NonDebuggable]
    procedure GetExchangeTenantId(): Text
    var
        TenantId: Text;
    begin
        if IsNullGuid("Exchange Tenant Id Key") or
           not IsolatedStorage.Contains("Exchange Tenant Id Key", DATASCOPE::Company)
        then begin
            SendTraceTag('0000CF8', EmailLoggingTelemetryCategoryTxt, Verbosity::Warning, ExchangeAccountNotConfiguredTxt, DataClassification::SystemMetadata);
            Error(ExchangeAccountNotConfiguredErr);
        end;

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

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure GetExchangeClientSecret(): Text
    var
        ClientSecret: Text;
    begin
        if IsNullGuid("Exchange Client Secret Key") or
           not IsolatedStorage.Contains("Exchange Client Secret Key", DATASCOPE::Company)
        then begin
            SendTraceTag('0000CF9', EmailLoggingTelemetryCategoryTxt, Verbosity::Warning, ExchangeAccountNotConfiguredTxt, DataClassification::SystemMetadata);
            Error(ExchangeAccountNotConfiguredErr);
        end;

        IsolatedStorageManagement.Get("Exchange Client Secret Key", DATASCOPE::Company, ClientSecret);
        exit(ClientSecret);
    end;
}

