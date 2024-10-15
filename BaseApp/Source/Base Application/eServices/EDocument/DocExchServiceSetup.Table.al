// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using System.Integration;
using System.Privacy;
using System.Security.Encryption;
using System.Telemetry;
using System.Threading;

table 1275 "Doc. Exch. Service Setup"
{
    Caption = 'Doc. Exch. Service Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(4; "Sign-up URL"; Text[250])
        {
            Caption = 'Sign-up URL';
            ExtendedDatatype = URL;

            trigger OnValidate()
            var
                WebRequestHelper: Codeunit "Web Request Helper";
            begin
                if "Sign-up URL" <> '' then
                    WebRequestHelper.IsSecureHttpUrl("Sign-up URL");
            end;
        }
        field(5; "Service URL"; Text[250])
        {
            Caption = 'Service URL';
            ExtendedDatatype = URL;

            trigger OnValidate()
            var
                WebRequestHelper: Codeunit "Web Request Helper";
            begin
                if "Service URL" <> '' then
                    WebRequestHelper.IsSecureHttpUrl("Service URL");
            end;
        }
        field(6; "Sign-in URL"; Text[250])
        {
            Caption = 'Sign-in URL';
            ExtendedDatatype = URL;

            trigger OnValidate()
            var
                WebRequestHelper: Codeunit "Web Request Helper";
            begin
                if "Sign-in URL" <> '' then
                    WebRequestHelper.IsSecureHttpUrl("Sign-in URL");
            end;
        }
        field(7; "Consumer Key"; Guid)
        {
            Caption = 'Consumer Key';
            ObsoleteReason = 'Authentication with OAuth 1.0 is deprecated.';
#if CLEAN23
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '19.0';
#endif
        }
        field(8; "Consumer Secret"; Guid)
        {
            Caption = 'Consumer Secret';
            Editable = false;
            ObsoleteReason = 'Authentication with OAuth 1.0 is deprecated.';
#if CLEAN23
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '19.0';
#endif
        }
        field(9; Token; Guid)
        {
            Caption = 'Token';
            Editable = false;
            ObsoleteReason = 'Authentication with OAuth 1.0 is deprecated.';
#if CLEAN23
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '19.0';
#endif
        }
        field(10; "Token Secret"; Guid)
        {
            Caption = 'Token Secret';
            Editable = false;
            ObsoleteReason = 'Authentication with OAuth 1.0 is deprecated.';
#if CLEAN23
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '19.0';
#endif
        }
        field(11; "Doc. Exch. Tenant ID"; Guid)
        {
            Caption = 'Doc. Exch. Tenant ID';
            DataClassification = OrganizationIdentifiableInformation;
            Editable = false;
            ObsoleteReason = 'Authentication with OAuth 1.0 is deprecated.';
#if CLEAN23
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '19.0';
#endif
        }
        field(12; "User Agent"; Text[30])
        {
            Caption = 'User Agent';
            DataClassification = EndUserIdentifiableInformation;
            NotBlank = true;
        }
        field(13; "Client Id"; Text[250])
        {
            Caption = 'Client Id';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(14; "Client Secret Key"; Guid)
        {
            Caption = 'Client Secret Key';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(15; "Redirect URL"; Text[250])
        {
            Caption = 'Redirect URL';
            ExtendedDatatype = URL;
            DataClassification = OrganizationIdentifiableInformation;

            trigger OnValidate()
            var
                WebRequestHelper: Codeunit "Web Request Helper";
            begin
                if "Redirect URL" <> '' then
                    WebRequestHelper.IsSecureHttpUrl("Redirect URL");
            end;
        }
        field(16; "Auth URL"; Text[250])
        {
            Caption = 'Authentication URL';
            ExtendedDatatype = URL;
            DataClassification = OrganizationIdentifiableInformation;

            trigger OnValidate()
            var
                WebRequestHelper: Codeunit "Web Request Helper";
            begin
                if "Auth URL" <> '' then
                    WebRequestHelper.IsSecureHttpUrl("Auth URL");
            end;
        }
        field(17; "Token URL"; Text[250])
        {
            Caption = 'Token URL';
            ExtendedDatatype = URL;
            DataClassification = OrganizationIdentifiableInformation;

            trigger OnValidate()
            var
                WebRequestHelper: Codeunit "Web Request Helper";
            begin
                if "Token URL" <> '' then
                    WebRequestHelper.IsSecureHttpUrl("Token URL");
            end;
        }
        field(18; "Access Token Key"; Guid)
        {
            Caption = 'Access Token Key';
            DataClassification = CustomerContent;
        }
        field(19; "Refresh Token Key"; Guid)
        {
            Caption = 'Refresh Token Key';
            DataClassification = CustomerContent;
        }
        field(20; Enabled; Boolean)
        {
            Caption = 'Enabled';

            trigger OnValidate()
            var
                CustomerConsentMgt: Codeunit "Customer Consent Mgt.";
            begin
                if Enabled then begin
                    if not CustomerConsentMgt.ConfirmUserConsent() then
                        Enabled := false;
                    DocExchServiceMgt.VerifyPrerequisites(true);
                end;
            end;
        }
        field(21; "Log Web Requests"; Boolean)
        {
            Caption = 'Log Web Requests';
        }
        field(24; "Token Subject"; Text[250])
        {
            Caption = 'Token Subject';
            DataClassification = AccountData;
        }
        field(25; "Token Issued At"; DateTime)
        {
            Caption = 'Token Issued At';
            DataClassification = AccountData;
        }
        field(27; "Id Token"; Text[1024])
        {
            Caption = 'Id Token';
            DataClassification = AccountData;
        }
        field(28; "Token Expired"; Boolean)
        {
            Caption = 'Id Token';
            DataClassification = AccountData;
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
        [NonDebuggable]
        TempClientSecret: Text;
        [NonDebuggable]
        TempAccessToken: Text;
        [NonDebuggable]
        TempRefreshToken: Text;

    trigger OnDelete()
    begin
        DeleteClientSecret();
        DeleteAccessToken();
        DeleteRefreshToken();
    end;

    trigger OnModify()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000IM7', DocExchServiceMgt.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");
        if IsEnabledChanged() then
            if Enabled then
                EnableConnection()
            else
                DisableConnection();
    end;

    trigger OnInsert()
    begin
        TestField("Primary Key", '');
        LogTelemetryWhenServiceCreated();
        if Enabled then
            EnableConnection()
        else
            DisableConnection();
    end;

    var
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
        DocExchServiceMgt: Codeunit "Doc. Exch. Service Mgt.";
        JobQEntriesCreatedQst: Label 'A job queue entry for exchanging documents has been created.\\Do you want to open the Job Queue Entries page?';
        DocExchServiceCreatedTxt: Label 'The user started setting up document exchange service.', Locked = true;
        DocExchServiceEnabledTxt: Label 'The user enabled document exchange service.', Locked = true;
        DocExchServiceDisabledTxt: Label 'The user disabled document exchange service.', Locked = true;
        TelemetryCategoryTok: Label 'AL Document Exchange Service', Locked = true;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure SetClientSecret(ClientSecretText: Text)
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        if IsTemporary() then begin
            TempClientSecret := ClientSecretText;
            exit;
        end;

        if IsNullGuid("Client Secret Key") then begin
            "Client Secret Key" := CreateGuid();
            if DocExchServiceSetup.Get("Primary Key") then
                Modify()
            else
                Insert();
        end;

        IsolatedStorageManagement.Set(Format("Client Secret Key"), ClientSecretText, DATASCOPE::Company);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure GetClientSecret(): Text
    var
        Value: Text;
    begin
        if IsTemporary() then
            exit(TempClientSecret);

        if not IsNullGuid("Client Secret Key") then
            if IsolatedStorageManagement.Get(Format("Client Secret Key"), DATASCOPE::Company, Value) then
                exit(Value);

        exit('');
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure DeleteClientSecret()
    begin
        if IsTemporary() then begin
            Clear(TempClientSecret);
            exit;
        end;

        if IsNullGuid("Client Secret Key") then
            exit;

        IsolatedStorageManagement.Delete(Format("Client Secret Key"), DATASCOPE::Company);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure SetAccessToken(AccessToken: Text)
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        if IsTemporary() then begin
            TempAccessToken := AccessToken;
            exit;
        end;

        if IsNullGuid("Access Token Key") then begin
            "Access Token Key" := CreateGuid();
            if DocExchServiceSetup.Get("Primary Key") then
                Modify()
            else
                Insert();
        end;

        SetToken("Access Token Key", AccessToken);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure GetAccessToken(): Text
    var
        Value: Text;
    begin
        if IsTemporary() then
            exit(TempAccessToken);

        if IsNullGuid("Access Token Key") then
            exit('');

        Value := GetToken("Access Token Key");
        exit(Value);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure DeleteAccessToken()
    begin
        if IsTemporary() then begin
            Clear(TempAccessToken);
            exit;
        end;

        if IsNullGuid("Access Token Key") then
            exit;

        DeleteToken("Access Token Key");
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure SetRefreshToken(RefreshToken: Text)
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        if IsTemporary() then begin
            TempRefreshToken := RefreshToken;
            exit;
        end;

        if IsNullGuid("Refresh Token Key") then begin
            "Refresh Token Key" := CreateGuid();
            if DocExchServiceSetup.Get("Primary Key") then
                Modify()
            else
                Insert();
        end;

        SetToken("Refresh Token Key", RefreshToken);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure GetRefreshToken(): Text
    var
        Value: Text;
    begin
        if IsTemporary() then
            exit(TempRefreshToken);

        if IsNullGuid("Refresh Token Key") then
            exit('');

        Value := GetToken("Refresh Token Key");
        exit(Value);
    end;

    [Scope('OnPrem')]
    [NonDebuggable]
    procedure DeleteRefreshToken()
    begin
        if IsTemporary() then begin
            Clear(TempRefreshToken);
            exit;
        end;

        if IsNullGuid("Refresh Token Key") then
            exit;

        DeleteToken("Refresh Token Key");
    end;

    local procedure DeleteToken(TokenKey: Guid)
    var
        I: Integer;
        N: Integer;
        PartKey: Text;
    begin
        N := GetMaxTokenPartCount();
        for I := 1 to N do begin
            PartKey := GetTokenPartKey(TokenKey, I);
            if not IsolatedStorageManagement.Delete(PartKey, DataScope::Company) then
                break;
        end;
    end;

    [NonDebuggable]
    local procedure GetToken(TokenKey: Guid): Text
    var
        I: Integer;
        N: Integer;
        PartKey: Text;
        TokenPart: Text;
        TokenValue: Text;
    begin
        N := GetMaxTokenPartCount();
        for I := 1 to N do begin
            PartKey := GetTokenPartKey(TokenKey, I);
            if IsolatedStorageManagement.Get(PartKey, DataScope::Company, TokenPart) then
                TokenValue += TokenPart
            else
                break;
        end;
        exit(TokenValue);
    end;

    [NonDebuggable]
    local procedure SetToken(TokenKey: Guid; TokenValue: Text): Boolean
    var
        TokenLen: Integer;
        PartLen: Integer;
        PartCount: Integer;
        PartKey: Text;
        TokenPart: Text;
        I: Integer;
    begin
        DeleteToken(TokenKey);

        TokenLen := StrLen(TokenValue);
        PartLen := GetMaxTokenPartLength();
        PartCount := TokenLen div PartLen;
        if TokenLen > (PartCount * PartLen) then
            PartCount += 1;

        if PartCount > GetMaxTokenPartCount() then begin
            PartKey := GetTokenPartKey(TokenKey, 1);
            exit(IsolatedStorageManagement.Set(PartKey, TokenValue, DataScope::Company));
        end;

        for I := 1 to PartCount do begin
            PartKey := GetTokenPartKey(TokenKey, I);
            TokenPart := CopyStr(TokenValue, (PartLen * (I - 1)) + 1, PartLen);
            if TokenPart <> '' then
                if not IsolatedStorageManagement.Set(PartKey, TokenPart, DataScope::Company) then
                    exit(false);
        end;
        exit(true);
    end;

    local procedure GetTokenPartKey(TokenKey: Guid; PartNumber: Integer): Text
    begin
        exit(Format(TokenKey) + '#' + Format(PartNumber))
    end;

    local procedure GetMaxTokenPartLength(): Integer
    begin
        exit(100);
    end;

    local procedure GetMaxTokenPartCount(): Integer
    begin
        exit(21);
    end;

    [Scope('OnPrem')]
    procedure SetDefaultRedirectUrl()
    begin
        DocExchServiceMgt.SetDefaultRedirectUrl(Rec);
    end;

    procedure SetURLsToDefault()
    var
        Sandbox: Boolean;
    begin
        Sandbox := DocExchServiceMgt.IsSandbox(Rec);
        SetURLsToDefault(Sandbox);
    end;

    [Scope('OnPrem')]
    procedure SetURLsToDefault(Sandbox: Boolean)
    begin
        DocExchServiceMgt.SetURLsToDefault(Rec, Sandbox);
    end;

    [Scope('OnPrem')]
    procedure CheckConnection()
    begin
        DocExchServiceMgt.CheckConnection();
    end;

    internal procedure IsEnabledChanged(): Boolean
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        if Enabled <> xRec.Enabled then
            exit(true);
        if DocExchServiceSetup.Get() then
            exit(Enabled <> DocExchServiceSetup.Enabled);
        exit(false);
    end;

    local procedure EnableConnection()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeEnableConnection(Rec, IsHandled);
        if IsHandled then
            exit;

        Enabled := false;
        Modify();
        DocExchServiceMgt.AcquireAccessTokenByAuthorizationCode(false);
        Get();
        Enabled := true;
        Modify();
        DocExchServiceMgt.CheckConnection();
        ScheduleJobQueueEntries();
        LogTelemetryWhenServiceEnabled();

        if not GuiAllowed() then
            exit;

        DocExchServiceMgt.RecallActivateAppNotification();

        if Confirm(JobQEntriesCreatedQst) then
            ShowJobQueueEntry();
    end;

    local procedure DisableConnection()
    begin
        Enabled := false;
        CancelJobQueueEntries();
        LogTelemetryWhenServiceDisabled();
    end;

    procedure ScheduleJobQueueEntries()
    var
        JobQueueEntry: Record "Job Queue Entry";
        DummyRecId: RecordID;
    begin
        JobQueueEntry.ScheduleRecurrentJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit,
          CODEUNIT::"Doc. Exch. Serv.- Doc. Status", DummyRecId);
        JobQueueEntry.ScheduleRecurrentJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit,
          CODEUNIT::"Doc. Exch. Serv. - Recv. Docs.", DummyRecId);
    end;

    procedure CancelJobQueueEntries()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        CancelJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit,
          CODEUNIT::"Doc. Exch. Serv.- Doc. Status");
        CancelJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit,
          CODEUNIT::"Doc. Exch. Serv. - Recv. Docs.");
    end;

    local procedure CancelJobQueueEntry(ObjType: Option; ObjID: Integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if JobQueueEntry.FindJobQueueEntry(ObjType, ObjID) then
            JobQueueEntry.Cancel();
    end;

    procedure ShowJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetFilter("Object ID to Run", '%1|%2',
          CODEUNIT::"Doc. Exch. Serv.- Doc. Status",
          CODEUNIT::"Doc. Exch. Serv. - Recv. Docs.");
        if JobQueueEntry.FindFirst() then
            PAGE.Run(PAGE::"Job Queue Entries", JobQueueEntry);
    end;

    local procedure LogTelemetryWhenServiceEnabled()
    begin
        Session.LogMessage('00008A9', DocExchServiceEnabledTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        Session.LogMessage('00008AA', "Service URL", Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
    end;

    local procedure LogTelemetryWhenServiceDisabled()
    begin
        Session.LogMessage('00008AB', DocExchServiceDisabledTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        Session.LogMessage('00008AC', "Service URL", Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
    end;

    local procedure LogTelemetryWhenServiceCreated()
    begin
        Session.LogMessage('00008AD', DocExchServiceCreatedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEnableConnection(var DocExchServiceSetup: Record "Doc. Exch. Service Setup"; var IsHandled: Boolean)
    begin
    end;
}

