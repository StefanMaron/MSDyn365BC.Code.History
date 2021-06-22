table 7200 "CDS Connection Setup"
{
    Caption = 'Common Data Service Connection Setup';

    fields
    {
        field(1; "Primary Key"; Code[20])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Server Address"; Text[250])
        {
            Caption = 'Environment URL';
            DataClassification = OrganizationIdentifiableInformation;

            trigger OnValidate()
            begin
                CDSIntegrationImpl.CheckModifyConnectionURL("Server Address");

                if StrPos("Server Address", '.dynamics.com') > 0 then
                    "Authentication Type" := "Authentication Type"::Office365
                else
                    "Authentication Type" := "Authentication Type"::AD;
                CDSIntegrationImpl.UpdateConnectionString(Rec);
            end;
        }
        field(3; "User Name"; Text[250])
        {
            Caption = 'User Name';
            DataClassification = EndUserIdentifiableInformation;

            trigger OnValidate()
            begin
                "User Name" := DelChr("User Name", '<>');
                CDSIntegrationImpl.CheckUserName(Rec);
                CDSIntegrationImpl.UpdateDomainName(Rec);
                CDSIntegrationImpl.UpdateConnectionString(Rec);
            end;
        }
        field(4; "User Password Key"; Guid)
        {
            Caption = 'User Password Key';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(60; "Is Enabled"; Boolean)
        {
            Caption = 'Is Enabled';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                if not "Is Enabled" then
                    exit;

                if IsTemporary() then begin
                    CDSIntegrationImpl.CheckConnectionRequiredFields(Rec, false);
                    CDSIntegrationImpl.CheckConnectionRequiredFieldsMatch(Rec, false);
                    exit;
                end;

                CDSIntegrationImpl.CheckConnectionRequiredFieldsMatch(Rec, false);

                if not CDSIntegrationImpl.TryCheckCredentials(Rec) then
                    Error(GetLastErrorText());
            end;
        }
        field(76; "Proxy Version"; Integer)
        {
            Caption = 'Proxy Version';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                CDSIntegrationImpl.UpdateConnectionString(Rec);
            end;
        }
        field(118; CurrencyDecimalPrecision; Integer)
        {
            Caption = 'Currency Decimal Precision';
            Description = 'Number of decimal places that can be used for currency.';
            DataClassification = SystemMetadata;
        }
        field(124; BaseCurrencyId; Guid)
        {
            Caption = 'Currency';
            Description = 'Unique identifier of the base currency of the organization.';
            TableRelation = "CRM Transactioncurrency".TransactionCurrencyId;
            DataClassification = SystemMetadata;
        }
        field(133; BaseCurrencyPrecision; Integer)
        {
            Caption = 'Base Currency Precision';
            Description = 'Number of decimal places that can be used for the base currency.';
            DataClassification = SystemMetadata;
            MaxValue = 4;
            MinValue = 0;
        }
        field(134; BaseCurrencySymbol; Text[5])
        {
            Caption = 'Base Currency Symbol';
            Description = 'Symbol used for the base currency.';
            DataClassification = SystemMetadata;
        }
        field(135; "Authentication Type"; Option)
        {
            Caption = 'Authentication Type';
            OptionCaption = 'Office365,AD,IFD,OAuth';
            OptionMembers = Office365,AD,IFD,OAuth;
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                case "Authentication Type" of
                    "Authentication Type"::Office365:
                        Domain := '';
                    "Authentication Type"::AD:
                        CDSIntegrationImpl.UpdateDomainName(Rec);
                end;
                CDSIntegrationImpl.UpdateConnectionString(Rec);
            end;
        }
        field(136; "Connection String"; Text[2048])
        {
            Caption = 'Connection String';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(137; Domain; Text[250])
        {
            Caption = 'Domain';
            DataClassification = OrganizationIdentifiableInformation;
            Editable = false;
        }
        field(139; "Disable Reason"; Text[250])
        {
            Caption = 'Disable Reason';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(140; "Ownership Model"; Option)
        {
            Caption = 'Ownership Model';
            OptionMembers = ,Person,Team;
            OptionCaption = ',Person,Team';
            DataClassification = SystemMetadata;
        }
        field(150; "Business Unit Id"; Guid)
        {
            Caption = 'Business Unit ID';
            DataClassification = SystemMetadata;
        }
        field(151; "Business Unit Name"; Text[160])
        {
            Caption = 'Business Unit Name';
            DataClassification = OrganizationIdentifiableInformation;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        if IsTemporary() then
            exit;

        CDSIntegrationImpl.InsertBusinessUnitCoupling(Rec);

        if "Is Enabled" then
            EnableConnection()
        else
            DisableConnection();
    end;

    trigger OnModify()
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        PasswordChanged: Boolean;
        BusinessUnitChanged: Boolean;
        IsEnabledChanged: Boolean;
    begin
        if IsTemporary() then
            exit;

        GetConfigurationUpdates(PasswordChanged, BusinessUnitChanged, IsEnabledChanged);

        if PasswordChanged then
            CDSConnectionSetup.DeletePassword();

        GetConfigurationUpdates(PasswordChanged, BusinessUnitChanged, IsEnabledChanged);

        if PasswordChanged then
            CDSConnectionSetup.DeletePassword();

        if BusinessUnitChanged then
            CDSIntegrationImpl.ModifyBusinessUnitCoupling(Rec);

        if IsEnabledChanged then
            if "Is Enabled" then
                EnableConnection()
            else
                DisableConnection();
    end;

    trigger OnDelete()
    begin
        if IsTemporary() then
            exit;

        DeletePassword();
        CDSIntegrationImpl.DeleteBusinessUnitCoupling(Rec);
        DisableConnection();
    end;

    local procedure EnableConnection()
    begin
        if CDSIntegrationImpl.ImportAndConfigureIntegrationSolution(Rec, false) then
            CDSIntegrationImpl.CheckIntegrationRequirements(Rec, false);
        CDSIntegrationImpl.RegisterConnection(Rec, false);
        CDSIntegrationImpl.ClearConnectionDisableReason(Rec);
        EnableIntegrationTables();

        CDSIntegrationMgt.OnEnableIntegration();
    end;

    local procedure GetConfigurationUpdates(var PasswordChanged: Boolean; var BusinessUnitChanged: Boolean; var IsEnabledChanged: Boolean)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        PasswordChanged := "User Password Key" <> xRec."User Password Key";
        BusinessUnitChanged := "Business Unit Id" <> xRec."Business Unit Id";
        IsEnabledChanged := "Is Enabled" <> xRec."Is Enabled";
        if not (PasswordChanged or BusinessUnitChanged or IsEnabledChanged) then
            if CDSConnectionSetup.Get() then begin
                PasswordChanged := "User Password Key" <> CDSConnectionSetup."User Password Key";
                BusinessUnitChanged := "Business Unit Id" <> CDSConnectionSetup."Business Unit Id";
                IsEnabledChanged := "Is Enabled" <> CDSConnectionSetup."Is Enabled";
            end;
    end;

    local procedure DisableConnection()
    begin
        UpdateCDSJobQueueEntriesStatus();
        CDSIntegrationImpl.UnregisterConnection();
        CDSIntegrationMgt.OnDisableIntegration();
    end;

    [Scope('OnPrem')]
    procedure HasPassword(): Boolean
    begin
        exit(GetPassword() <> '');
    end;

    [Scope('OnPrem')]
    procedure GetPassword(): Text
    var
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
        Value: Text;
    begin
        if IsTemporary() then
            exit(TempUserPassword);

        if not IsNullGuid("User Password Key") then
            if IsolatedStorageManagement.Get("User Password Key", DATASCOPE::Company, Value) then
                exit(Value);

        exit('');
    end;

    [Scope('OnPrem')]
    procedure SetPassword(PasswordText: Text)
    var
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
    begin
        if IsTemporary() then begin
            TempUserPassword := PasswordText;
            exit;
        end;

        if IsNullGuid("User Password Key") then
            "User Password Key" := CreateGuid();

        IsolatedStorageManagement.Set(Format("User Password Key"), PasswordText, DATASCOPE::Company);
    end;

    [Scope('OnPrem')]
    procedure DeletePassword()
    var
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
    begin
        if IsTemporary() then begin
            Clear(TempUserPassword);
            exit;
        end;

        if IsNullGuid("User Password Key") then
            exit;

        IsolatedStorageManagement.Delete(Format("User Password Key"), DATASCOPE::Company);
    end;

    [Scope('OnPrem')]
    procedure SynchronizeNow(DoFullSynch: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
        ProgressWindow: Dialog;
        MappingCount: Integer;
        CurrentMappingIndex: Integer;
    begin
        CDSSetupDefaults.GetPrioritizedMappingList(TempNameValueBuffer);

        CurrentMappingIndex := 0;
        MappingCount := TempNameValueBuffer.Count();
        if MappingCount = 0 then
            exit;
        ProgressWindow.Open(ProcessDialogMapTitleMsg, CurrentMappingIndex);
        TempNameValueBuffer.Ascending(true);
        TempNameValueBuffer.FindSet();
        repeat
            CurrentMappingIndex := CurrentMappingIndex + 1;
            ProgressWindow.Update(1, Round(CurrentMappingIndex / MappingCount * 10000, 1));
            if IntegrationTableMapping.Get(TempNameValueBuffer.Value) then
                IntegrationTableMapping.SynchronizeNow(DoFullSynch);
        until TempNameValueBuffer.Next() = 0;
        ProgressWindow.Close();
    end;

    local procedure EnableIntegrationTables()
    var
        IntegrationRecord: Record "Integration Record";
        IntegrationManagement: Codeunit "Integration Management";
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
    begin
        if IntegrationRecord.IsEmpty() then
            IntegrationManagement.SetupIntegrationTables();
        IntegrationManagement.SetConnectorIsEnabledForSession(true);
        Modify(); // Job Queue to read "Is Enabled"
        Commit();
        CDSSetupDefaults.ResetConfiguration(Rec);
    end;

    procedure SetBaseCurrencyData()
    var
        CRMOrganization: Record "CRM Organization";
    begin
        CDSIntegrationMgt.RegisterConnection();
        CDSIntegrationMgt.ActivateConnection();
        if CRMOrganization.FindFirst() then begin
            CurrencyDecimalPrecision := CRMOrganization.CurrencyDecimalPrecision;
            BaseCurrencyId := CRMOrganization.BaseCurrencyId;
            BaseCurrencyPrecision := CRMOrganization.BaseCurrencyPrecision;
            BaseCurrencySymbol := CRMOrganization.BaseCurrencySymbol;
            Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure LoadConnectionStringElementsFromCRMConnectionSetup();
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        Exists: Boolean;
    begin
        if Get() then
            if "Is Enabled" then
                exit;

        if "Server Address" <> '' then
            exit;

        if "User Name" <> '' then
            exit;

        if not IsNullGuid("User Password Key") then
            exit;

        if CRMConnectionSetup.Get() then
            if CRMConnectionSetup."Is Enabled" then begin
                Exists := Get();
                "Server Address" := CRMConnectionSetup."Server Address";
                "User Name" := CRMConnectionSetup."User Name";
                "User Password Key" := CRMConnectionSetup."User Password Key";
                "Authentication Type" := CRMConnectionSetup."Authentication Type";
                if Exists then
                    Modify()
                else
                    Insert();
                exit;
            end;

    end;

    local procedure UpdateCDSJobQueueEntriesStatus()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        JobQueueEntry: Record "Job Queue Entry";
        NewStatus: Option;
    begin
        if "Is Enabled" then
            NewStatus := JobQueueEntry.Status::Ready
        else
            NewStatus := JobQueueEntry.Status::"On Hold";
        IntegrationTableMapping.SetRange("Synch. Codeunit ID", CODEUNIT::"CRM Integration Table Synch.");
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        if IntegrationTableMapping.FindSet() then
            repeat
                JobQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId());
                if JobQueueEntry.FindSet() then
                    repeat
                        JobQueueEntry.SetStatus(NewStatus);
                    until JobQueueEntry.Next() = 0;
            until IntegrationTableMapping.Next() = 0;
    end;

    var
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        TempUserPassword: Text;
        ProcessDialogMapTitleMsg: Label 'Synchronizing @1', Comment = '@1 Progress dialog map no.';
}
