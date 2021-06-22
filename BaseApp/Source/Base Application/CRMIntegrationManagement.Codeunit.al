codeunit 5330 "CRM Integration Management"
{
    SingleInstance = true;

    trigger OnRun()
    begin
        CheckOrEnableCRMConnection;
    end;

    var
        CRMEntityUrlTemplateTxt: Label '%1/main.aspx?pagetype=entityrecord&etn=%2&id=%3', Locked = true;
        NewestUIAppIdParameterTxt: Label '&appId=%1', Locked = true;
        UnableToResolveCRMEntityNameFrmTableIDErr: Label 'The application is not designed to integrate table %1 with %2.', Comment = '%1 = table ID (numeric), %2 = CRM Product Name';
        CouplingNotFoundErr: Label 'The record is not coupled to %1.', Comment = '%1 = CRM Product Name';
        NoCardPageActionDefinedForTableIdErr: Label 'The open page action is not supported for Table %1.', Comment = '%1 = Table ID';
        IntegrationTableMappingNotFoundErr: Label 'No %1 was found for table %2.', Comment = '%1 = Integration Table Mapping caption, %2 = Table caption for the table which is not mapped';
        UpdateNowDirectionQst: Label 'Send data update to Common Data Service.,Get data update from Common Data Service.';
        UpdateOneNowTitleTxt: Label 'Synchronize data for %1?', Comment = '%1 = Table caption and value for the entity we want to synchronize now.';
        UpdateMultipleNowTitleTxt: Label 'Synchronize data for the selected records?';
        ManageCouplingQst: Label 'The %1 record is not coupled to %2. Do you want to create a coupling?', Comment = '%1=The record caption (type), %2 = CRM Product Name';
        SyncNowFailedMsg: Label 'The synchronization failed.';
        SyncNowScheduledMsg: Label 'The synchronization has been scheduled.';
        SyncNowSkippedMsg: Label 'The synchronization has been skipped.';
        SyncMultipleMsg: Label 'The synchronization has been scheduled for %1 of %4 records. %2 records failed. %3 records were skipped.', Comment = '%1,%2,%3,%4 are numbers of records';
        SyncSkippedMsg: Label 'The record will be skipped for further synchronization due to a repeatable failure.';
        SyncRestoredMsg: Label 'The record has been restored for synchronization.';
        SyncMultipleRestoredMsg: Label '%1 records have been restored for synchronization.', Comment = '%1 - an integer, a count of records.';
        DetailsTxt: Label 'Details.';
        UpdateOneNowToCRMQst: Label 'Send data update to %2 for %1?', Comment = '%1 = Table caption and value for the entity we want to synchronize now., %2 = short CRM Product Name';
        UpdateOneNowToModifiedCRMQst: Label 'The %3 record coupled to %1 contains newer data than the %2 record. Do you want to overwrite the data in %3?', Comment = '%1 = Table caption and value for the entity we want to synchronize now. %2 - product name, %3 = short CRM product name';
        UpdateOneNowFromCRMQst: Label 'Get data update from %2 for %1?', Comment = '%1 = Table caption and value for the entity we want to synchronize now., %2 = short CRM product name';
        UpdateOneNowFromOldCRMQst: Label 'The %2 record %1 contains newer data than the %3 record. Get data update from %3, overwriting data in %2?', Comment = '%1 = Table caption and value for the entity we want to synchronize now. %2 - product name, %3 = short CRM product name';
        UpdateMultipleNowToCRMQst: Label 'Send data update to %1 for the selected records?', Comment = '%1 = short CRM product name';
        UpdateMultipleNowFromCRMQst: Label 'Get data update from %1 for the selected records?', Comment = '%1 = short CRM product name';
        AccountStatisticsUpdatedMsg: Label 'The customer statistics have been successfully updated in %1.', Comment = '%1 = short CRM product name';
        BothRecordsModifiedBiDirectionalMsg: Label 'Both the %1 record and the %3 %2 record have been changed since the last synchronization, or synchronization has never been performed. If you continue with synchronization, data on one of the records will be lost and replaced with data from the other record.', Comment = '%1 and %2 area captions of tables such as Customer and CRM Account, %3 = short CRM product name';
        BothRecordsModifiedToCRMQst: Label 'Both %1 and the %4 %2 record have been changed since the last synchronization, or synchronization has never been performed. If you continue with synchronization, data in %4 will be overwritten with data from %3. Are you sure you want to synchronize?', Comment = '%1 is a formatted RecordID, such as ''Customer 1234''. %2 is the caption of a CRM table. %3 - product name, %4 = short CRM product name';
        BothRecordsModifiedToNAVQst: Label 'Both %1 and the %4 %2 record have been changed since the last synchronization, or synchronization has never been performed. If you continue with synchronization, data in %3 will be overwritten with data from %4. Are you sure you want to synchronize?', Comment = '%1 is a formatted RecordID, such as ''Customer 1234''. %2 is the caption of a CRM table. %3 - product name, %4 = short CRM product name';
        CRMProductName: Codeunit "CRM Product Name";
        CRMIntegrationEnabledState: Option " ","Not Enabled",Enabled,"Enabled But Not For Current User";
        CDSIntegrationEnabledState: Option " ","Not Enabled",Enabled,"Enabled But Not For Current User";
        NotEnabledForCurrentUserMsg: Label '%3 Integration is enabled.\However, because the %2 Users Must Map to %3 Users field is set, %3 integration is not enabled for %1.', Comment = '%1 = Current User Id %2 - product name, %3 = CRM product name';
        CRMIntegrationEnabledLastError: Text;
        ImportSolutionConnectStringTok: Label '%1api%2/XRMServices/2011/Organization.svc', Locked = true;
        UserDoesNotExistCRMErr: Label 'There is no user with email address %1 in %2. Enter a valid email address.', Comment = '%1 = User email address, %2 = CRM product name';
        EmailAndServerAddressEmptyErr: Label 'The Integration User Email and Server Address fields must not be empty.';
        CRMSolutionFileNotFoundErr: Label 'A file for a CRM solution could not be found.';
        MicrosoftDynamicsNavIntegrationTxt: Label 'MicrosoftDynamicsNavIntegration', Locked = true;
        AdminEmailPasswordWrongErr: Label 'Enter valid %1 administrator credentials.', Comment = '%1 = CRM product name';
        AdminUserDoesNotHavePriviligesErr: Label 'The specified %1 administrator does not have sufficient privileges to import a %1 solution.', Comment = '%1 = CRM product name';
        InvalidUriErr: Label 'The value entered is not a valid URL.';
        MustUseHttpsErr: Label 'The application is set up to support secure connections (HTTPS) to %1 only. You cannot use HTTP.', Comment = '%1 = CRM product name';
        MustUseHttpOrHttpsErr: Label '%1 is not a valid URI scheme for %2 connections. You can only use HTTPS or HTTP as the scheme in the URL.', Comment = '%1 is a URI scheme, such as FTP, HTTP, chrome or file, %2 = CRM product name';
        ReplaceServerAddressQst: Label 'The URL is not valid. Do you want to replace it with the URL suggested below?\\Entered URL: "%1".\Suggested URL: "%2".', Comment = '%1 and %2 are URLs';
        CRMConnectionURLWrongErr: Label 'The URL is incorrect. Enter the URL for the %1 connection.', Comment = '%1 = CRM product name';
        NoOf: Option ,Scheduled,Failed,Skipped,Total;
        CRMConnSetupWizardQst: Label 'Do you want to open the %1 Connection assisted setup wizard?', Comment = '%1 = CRM product name';
        ConnectionStringFormatTok: Label 'Url=%1; UserName=%2; Password=%3; ProxyVersion=%4; %5', Locked = true;
        CRMDisabledErrorReasonNotificationIdTxt: Label 'd82835d9-a005-451a-972b-0d6532de2072';
        ConnectionBrokenMsg: Label 'The connection to Dynamics 365 Sales is disabled due to the following error: %1.\\Please contact your system administrator.', Comment = '%1 = Error text received from D365 for Sales';
        ConnectionDisabledNotificationMsg: Label 'Connection to Dynamics 365 is broken and that it has been disabled due to an error: %1', Comment = '%1 = Error text received from D365 for Sales';
        DoYouWantEnableWebServiceQst: Label 'Do you want to enable the Item Availability web service?';
        DoYouWantDisableWebServiceQst: Label 'Do you want to disable the Item Availability web service?';
        CRMConnectionSetupTxt: Label 'Set up %1 connection', Comment = '%1 = CRM product name';
        VideoUrlSetupCRMConnectionTxt: Label 'https://go.microsoft.com/fwlink/?linkid=843244', Locked = true;
        ConnectionDisabledReasonTxt: Label 'The connection to %1 was disabled because integration user %2 has insufficient privileges to run the synchronization.', Comment = '%1 = a URL, %2 - an email address';
        CannotAssignRoleToTeamErr: Label 'Cannot assign role %3 to team %1 for business unit %2.', Comment = '%1 = team name, %2 = business unit name, %3 = security role name';
        CannotAssignRoleToTeamTxt: Label 'Cannot assign role to team.', Locked = true;
        IntegrationRoleNotFoundErr: Label 'There is no integration role %1 for business unit %2.', Comment = '%1 = role name, %2 = business unit name';
        RoleNotFoundForBusinessUnitTxt: Label 'Integration role is not found for business unit.', Locked = true;
        CategoryTok: Label 'AL Common Data Service Integration', Locked = true;

    procedure IsCRMIntegrationEnabled(): Boolean
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if CRMIntegrationEnabledState = CRMIntegrationEnabledState::" " then begin
            ClearLastError;
            CRMIntegrationEnabledState := CRMIntegrationEnabledState::"Not Enabled";
            Clear(CRMIntegrationEnabledLastError);
            if CRMConnectionSetup.Get then begin
                CRMConnectionSetup.RestoreConnection;
                if CRMConnectionSetup."Is Enabled" then begin
                    if not HasTableConnection(TABLECONNECTIONTYPE::CRM, GetDefaultTableConnection(TABLECONNECTIONTYPE::CRM)) then
                        CRMConnectionSetup.RegisterUserConnection;
                    if not CRMConnectionSetup."Is User Mapping Required" then
                        CRMIntegrationEnabledState := CRMIntegrationEnabledState::Enabled
                    else
                        if CRMConnectionSetup.IsCurrentUserMappedToCrmSystemUser then
                            CRMIntegrationEnabledState := CRMIntegrationEnabledState::Enabled
                        else begin
                            CRMIntegrationEnabledState := CRMIntegrationEnabledState::"Enabled But Not For Current User";
                            CRMIntegrationEnabledLastError := GetLastErrorMessage;
                        end;
                    if CRMIntegrationEnabledState = CRMIntegrationEnabledState::Enabled then
                        OnAfterCRMIntegrationEnabled;
                end;
            end;
        end;

        exit(CRMIntegrationEnabledState = CRMIntegrationEnabledState::Enabled);
    end;

    procedure IsCDSIntegrationEnabled(): Boolean
    var
        isEnabled: Boolean;
        initConnectionHandled: Boolean;
        ConnectionName: text;
    begin
        OnIsCDSIntegrationEnabled(isEnabled);
        if isEnabled then begin
            OnInitCDSConnection(ConnectionName, initConnectionHandled);
            CDSIntegrationEnabledState := CDSIntegrationEnabledState::Enabled;
        end else
            CDSIntegrationEnabledState := CDSIntegrationEnabledState::"Not Enabled";

        exit(isEnabled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsCDSIntegrationEnabled(var isEnabled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnInitCDSConnection(var ConnectionName: Text; var handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnGetCDSIntegrationUserId(var IntegrationUserId: Guid; var handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnGetCDSServerAddress(var CDSServerAddress: Text; var handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnTestCDSConnection(var handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCloseCDSConnection(ConnectionName: Text; var handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCRMIntegrationEnabled()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenRecordCardPage(RecordID: RecordID; var IsHandled: Boolean)
    begin
    end;

    procedure IsCRMSolutionInstalled(): Boolean
    begin
        if TryTouchCRMSolutionEntities then
            exit(true);

        ClearLastError;
        exit(false);
    end;

    [TryFunction]
    local procedure TryTouchCRMSolutionEntities()
    var
        CRMNAVConnection: Record "CRM NAV Connection";
        CRMAccountStatistics: Record "CRM Account Statistics";
    begin
        if CRMAccountStatistics.FindFirst then;
        if CRMNAVConnection.FindFirst then;
    end;

    procedure SetCRMNAVConnectionUrl(WebClientUrl: Text[250])
    var
        CRMNAVConnection: Record "CRM NAV Connection";
        NewConnection: Boolean;
    begin
        if not CRMNAVConnection.FindFirst then begin
            CRMNAVConnection.Init();
            NewConnection := true;
        end;

        CRMNAVConnection."Dynamics NAV URL" := WebClientUrl;

        if NewConnection then
            CRMNAVConnection.Insert
        else
            CRMNAVConnection.Modify();
    end;

    procedure SetCRMNAVODataUrlCredentials(ODataUrl: Text[250]; Username: Text[250]; Accesskey: Text[250])
    var
        CRMNAVConnection: Record "CRM NAV Connection";
        NewConnection: Boolean;
    begin
        if not CRMNAVConnection.FindFirst then begin
            CRMNAVConnection.Init();
            NewConnection := true;
        end;

        CRMNAVConnection."Dynamics NAV OData URL" := ODataUrl;
        CRMNAVConnection."Dynamics NAV OData Username" := Username;
        CRMNAVConnection."Dynamics NAV OData Accesskey" := Accesskey;

        if NewConnection then
            CRMNAVConnection.Insert
        else
            CRMNAVConnection.Modify();
    end;

    procedure UpdateMultipleNow(RecVariant: Variant)
    var
        RecRef: RecordRef;
        RecordCounter: array[4] of Integer;
        ShouldSendNotification: Boolean;
    begin
        RecordCounter[NoOf::Total] := GetRecordRef(RecVariant, RecRef);
        if RecordCounter[NoOf::Total] = 0 then
            exit;

        if RecRef.Number = DATABASE::"CRM Integration Record" then
            ShouldSendNotification := UpdateCRMIntRecords(RecRef, RecordCounter)
        else
            ShouldSendNotification := UpdateRecords(RecRef, RecordCounter);
        if ShouldSendNotification then
            SendSyncNotification(RecordCounter);
    end;

    local procedure UpdateCRMIntRecords(var RecRef: RecordRef; var RecordCounter: array[4] of Integer): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        SourceRecRef: RecordRef;
        RecId: RecordId;
        SelectedDirection: Integer;
        Direction: Integer;
        Unused: Boolean;
    begin
        if RecordCounter[NoOf::Total] = 1 then begin
            RecRef.SetTable(CRMIntegrationRecord);
            GetIntegrationTableMapping(IntegrationTableMapping, CRMIntegrationRecord."Table ID");
            CRMIntegrationRecord.FindRecordId(RecId);
            SourceRecRef.Get(RecId);
            SelectedDirection :=
              GetSelectedSingleSyncDirection(IntegrationTableMapping, SourceRecRef, CRMIntegrationRecord."CRM ID", Unused)
        end else begin
            IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::Bidirectional;
            SelectedDirection := GetSelectedMultipleSyncDirection(IntegrationTableMapping);
        end;
        if SelectedDirection = 0 then
            exit(false); // The user cancelled

        repeat
            RecRef.SetTable(CRMIntegrationRecord);
            GetIntegrationTableMapping(IntegrationTableMapping, CRMIntegrationRecord."Table ID");
            if IntegrationTableMapping.Direction = IntegrationTableMapping.Direction::Bidirectional then
                Direction := SelectedDirection
            else
                Direction := IntegrationTableMapping.Direction;
            CRMIntegrationRecord.FindRecordId(RecId);
            if EnqueueSyncJob(IntegrationTableMapping, RecId, CRMIntegrationRecord."CRM ID", Direction) then begin
                CRMIntegrationRecord.Skipped := false;
                CRMIntegrationRecord.Modify();
                RecordCounter[NoOf::Scheduled] += 1;
            end else
                RecordCounter[NoOf::Failed] += 1;
        until RecRef.Next = 0;
        exit(true);
    end;

    local procedure UpdateRecords(var RecRef: RecordRef; var RecordCounter: array[4] of Integer): Boolean
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        SelectedDirection: Integer;
        CRMID: Guid;
        Unused: Boolean;
    begin
        GetIntegrationTableMapping(IntegrationTableMapping, RecRef.Number);

        if RecordCounter[NoOf::Total] = 1 then
            if GetCoupledCRMID(RecRef.RecordId, CRMID) then
                SelectedDirection :=
                  GetSelectedSingleSyncDirection(IntegrationTableMapping, RecRef, CRMID, Unused)
            else begin
                DefineCouplingIfNotCoupled(RecRef.RecordId, CRMID);
                exit(false);
            end
        else
            SelectedDirection := GetSelectedMultipleSyncDirection(IntegrationTableMapping);
        if SelectedDirection = 0 then
            exit(false); // The user cancelled

        repeat
            if not GetCoupledCRMID(RecRef.RecordId, CRMID) then
                RecordCounter[NoOf::Skipped] += 1
            else begin
                if (RecordCounter[NoOf::Total] > 1) and
                   WasRecordModifiedAfterLastSynch(IntegrationTableMapping, RecRef, CRMID, SelectedDirection)
                then
                    RecordCounter[NoOf::Skipped] += 1
                else
                    if IsRecordSkipped(RecRef.RecordId) then
                        RecordCounter[NoOf::Skipped] += 1
                    else
                        if EnqueueSyncJob(IntegrationTableMapping, RecRef.RecordId, CRMID, SelectedDirection) then
                            RecordCounter[NoOf::Scheduled] += 1
                        else
                            RecordCounter[NoOf::Failed] += 1;
            end;
        until RecRef.Next = 0;
        exit(true);
    end;

    procedure UpdateOneNow(RecordID: RecordID)
    begin
        // Extinct method. Kept for backward compatibility.
        UpdateMultipleNow(RecordID)
    end;

    procedure UpdateSkippedNow(var CRMIntegrationRecord: Record "CRM Integration Record")
    var
        RecId: RecordId;
        RestoredRecCounter: Integer;
    begin
        if CRMIntegrationRecord.FindSet then
            repeat
                if CRMIntegrationRecord.FindRecordId(RecId) then begin
                    CRMIntegrationRecord.Skipped := false;
                    CRMIntegrationRecord.Modify();
                    RestoredRecCounter += 1;
                end;
            until CRMIntegrationRecord.Next = 0;
        SendRestoredSyncNotification(RestoredRecCounter);
    end;

    local procedure WasRecordModifiedAfterLastSynch(IntegrationTableMapping: Record "Integration Table Mapping"; RecRef: RecordRef; CRMID: Guid; SelectedDirection: Option): Boolean
    var
        IntegrationRecSynchInvoke: Codeunit "Integration Rec. Synch. Invoke";
        CRMRecordRef: RecordRef;
        RecordModified: Boolean;
        CRMRecordModified: Boolean;
    begin
        RecordModified := IntegrationRecSynchInvoke.WasModifiedAfterLastSynch(IntegrationTableMapping, RecRef);
        IntegrationTableMapping.GetRecordRef(CRMID, CRMRecordRef);
        CRMRecordModified := IntegrationRecSynchInvoke.WasModifiedAfterLastSynch(IntegrationTableMapping, CRMRecordRef);
        exit(
          ((SelectedDirection = IntegrationTableMapping.Direction::ToIntegrationTable) and CRMRecordModified) or
          ((SelectedDirection = IntegrationTableMapping.Direction::FromIntegrationTable) and RecordModified))
    end;

    procedure CheckOrEnableCRMConnection()
    begin
        if IsCDSIntegrationEnabled() then
            exit;

        if IsCRMIntegrationEnabled() then
            exit;

        if CRMIntegrationEnabledLastError <> '' then
            Error(CRMIntegrationEnabledLastError);

        if CRMIntegrationEnabledState = CRMIntegrationEnabledState::"Enabled But Not For Current User" then
            Message(NotEnabledForCurrentUserMsg, UserId, PRODUCTNAME.Short, CRMProductName.SHORT)
        else
            if Confirm(CRMConnSetupWizardQst, true, CRMProductName.SHORT) then
                PAGE.Run(PAGE::"CRM Connection Setup Wizard");

        Error('');
    end;

    local procedure GetRecordRef(RecVariant: Variant; var RecordRef: RecordRef): Integer
    begin
        case true of
            RecVariant.IsRecord:
                RecordRef.GetTable(RecVariant);
            RecVariant.IsRecordId:
                if RecordRef.Get(RecVariant) then
                    RecordRef.SetRecFilter;
            RecVariant.IsRecordRef:
                RecordRef := RecVariant;
            else
                exit(0);
        end;
        if RecordRef.FindSet then
            exit(RecordRef.Count);
        exit(0);
    end;

    procedure CreateNewRecordInCRM(RecordID: RecordID; ConfirmBeforeDeletingExistingCoupling: Boolean)
    begin
        // Extinct method. Kept for backward compatibility.
        ConfirmBeforeDeletingExistingCoupling := false;
        CreateNewRecordsInCRM(RecordID);
    end;

    procedure CreateNewRecordsInCRM(RecVariant: Variant)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        RecRef: RecordRef;
        CRMID: Guid;
        RecordCounter: array[4] of Integer;
    begin
        RecordCounter[NoOf::Total] := GetRecordRef(RecVariant, RecRef);
        if RecordCounter[NoOf::Total] = 0 then
            exit;
        GetIntegrationTableMapping(IntegrationTableMapping, RecRef.Number);
        repeat
            if CRMIntegrationRecord.FindValidByRecordID(RecRef.RecordId, IntegrationTableMapping."Integration Table ID") then
                RecordCounter[NoOf::Skipped] += 1
            else begin
                if not IsNullGuid(CRMIntegrationRecord."CRM ID") then // found the corrupt coupling
                    CRMIntegrationRecord.Delete();
                if EnqueueSyncJob(IntegrationTableMapping, RecRef.RecordId, CRMID, IntegrationTableMapping.Direction::ToIntegrationTable) then
                    RecordCounter[NoOf::Scheduled] += 1
                else
                    RecordCounter[NoOf::Failed] += 1;
            end;
        until RecRef.Next = 0;

        SendSyncNotification(RecordCounter);
    end;

    procedure CreateNewRecordsFromCRM(RecVariant: Variant)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecRef: RecordRef;
        CRMID: Guid;
        RecordCounter: array[4] of Integer;
    begin
        RecordCounter[NoOf::Total] := GetRecordRef(RecVariant, RecRef);
        if RecordCounter[NoOf::Total] = 0 then
            exit;

        repeat
            GetIntegrationTableMappingFromCRMRecord(IntegrationTableMapping, RecRef);
            CRMID := RecRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.").Value;
            if CRMIntegrationRecord.FindValidByCRMID(CRMID) then
                RecordCounter[NoOf::Skipped] += 1
            else begin
                if not IsNullGuid(CRMIntegrationRecord."CRM ID") then // found the corrupt coupling
                    CRMIntegrationRecord.Delete();
                if EnqueueSyncJob(IntegrationTableMapping, RecRef.RecordId, CRMID, IntegrationTableMapping.Direction::FromIntegrationTable) then
                    RecordCounter[NoOf::Scheduled] += 1
                else
                    RecordCounter[NoOf::Failed] += 1;
            end;
        until RecRef.Next = 0;

        SendSyncNotification(RecordCounter);
    end;

    local procedure PerformInitialSynchronization(RecordID: RecordID; CRMID: Guid; Direction: Option)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        RecordCounter: array[4] of Integer;
    begin
        RecordCounter[NoOf::Total] := 1;
        GetIntegrationTableMapping(IntegrationTableMapping, RecordID.TableNo);
        if EnqueueSyncJob(IntegrationTableMapping, RecordID, CRMID, Direction) then
            RecordCounter[NoOf::Scheduled] += 1
        else
            RecordCounter[NoOf::Failed] += 1;

        SendSyncNotification(RecordCounter);
    end;

    local procedure GetIntegrationTableMapping(var IntegrationTableMapping: Record "Integration Table Mapping"; TableID: Integer)
    begin
        IntegrationTableMapping.SetRange("Synch. Codeunit ID", CODEUNIT::"CRM Integration Table Synch.");
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        if IsCRMTable(TableID) then
            IntegrationTableMapping.SetRange("Integration Table ID", TableID)
        else
            IntegrationTableMapping.SetRange("Table ID", TableID);
        if not IntegrationTableMapping.FindFirst then
            Error(IntegrationTableMappingNotFoundErr, IntegrationTableMapping.TableCaption, GetTableCaption(TableID));
    end;

    local procedure GetIntegrationTableMappingFromCRMRecord(var IntegrationTableMapping: Record "Integration Table Mapping"; RecRef: RecordRef)
    var
        CRMAccount: Record "CRM Account";
        CustomerTypeCodeFieldRef: FieldRef;
        CustomerTypeCode: Text;
    begin
        if RecRef.Number <> Database::"CRM Account" then begin
            GetIntegrationTableMapping(IntegrationTableMapping, RecRef.Number);
            exit;
        end;

        CustomerTypeCodeFieldRef := RecRef.Field(CRMAccount.FieldNo(CustomerTypeCode));
        Evaluate(CustomerTypeCode, Format(CustomerTypeCodeFieldRef.Value));
        IntegrationTableMapping.SetRange("Synch. Codeunit ID", CODEUNIT::"CRM Integration Table Synch.");
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        IntegrationTableMapping.SetRange("Integration Table ID", RecRef.Number);
        if CustomerTypeCode = Format(CRMAccount.CustomerTypeCode::Customer) then
            IntegrationTableMapping.SetRange("Table ID", Database::Customer)
        else
            if CustomerTypeCode = Format(CRMAccount.CustomerTypeCode::Vendor) then
                IntegrationTableMapping.SetRange("Table ID", Database::Vendor);
        if not IntegrationTableMapping.FindFirst then
            Error(IntegrationTableMappingNotFoundErr, IntegrationTableMapping.TableCaption, GetTableCaption(RecRef.Number));
    end;

    local procedure GetTableCaption(TableID: Integer): Text
    var
        TableMetadata: Record "Table Metadata";
    begin
        if TableMetadata.Get(TableID) then
            exit(TableMetadata.Caption);
        exit('');
    end;

    procedure IsCRMTable(TableID: Integer): Boolean
    var
        TableMetadata: Record "Table Metadata";
    begin
        if TableMetadata.Get(TableID) then
            exit(TableMetadata.TableType = TableMetadata.TableType::CRM);
    end;

    local procedure IsRecordSkipped(RecID: RecordID): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if CRMIntegrationRecord.FindByRecordID(RecID) then
            exit(CRMIntegrationRecord.Skipped);
    end;

    procedure EnqueueFullSyncJob(Name: Code[20]): Guid
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        JobQueueEntry: Record "Job Queue Entry";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
    begin
        IntegrationTableMapping.Get(Name);
        IntegrationTableMapping."Full Sync is Running" := true;
        IntegrationTableMapping.CalcFields("Table Filter", "Integration Table Filter");
        AddIntegrationTableMapping(IntegrationTableMapping);
        Commit();
        if CRMSetupDefaults.CreateJobQueueEntry(IntegrationTableMapping) then begin
            JobQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId);
            if JobQueueEntry.FindFirst then
                exit(JobQueueEntry.ID);
        end;
    end;

    local procedure EnqueueSyncJob(IntegrationTableMapping: Record "Integration Table Mapping"; RecordID: RecordID; CRMID: Guid; Direction: Integer): Boolean
    var
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
    begin
        IntegrationTableMapping.Direction := Direction;
        if Direction = IntegrationTableMapping.Direction::FromIntegrationTable then
            IntegrationTableMapping.SetIntegrationTableFilter(GetTableViewForGuid(IntegrationTableMapping."Integration Table ID", CRMID))
        else
            IntegrationTableMapping.SetTableFilter(GetTableViewForRecordID(RecordID));
        AddIntegrationTableMapping(IntegrationTableMapping);
        Commit();
        exit(CRMSetupDefaults.CreateJobQueueEntry(IntegrationTableMapping));
    end;

    local procedure AddIntegrationTableMapping(var IntegrationTableMapping: Record "Integration Table Mapping")
    var
        SourceMappingName: Code[20];
    begin
        SourceMappingName := IntegrationTableMapping.Name;
        IntegrationTableMapping.Name := CopyStr(DelChr(Format(CreateGuid), '=', '{}-'), 1, MaxStrLen(IntegrationTableMapping.Name));
        IntegrationTableMapping."Synch. Only Coupled Records" := false;
        IntegrationTableMapping."Delete After Synchronization" := true;
        IntegrationTableMapping."Parent Name" := SourceMappingName;
        Clear(IntegrationTableMapping."Synch. Modified On Filter");
        Clear(IntegrationTableMapping."Synch. Int. Tbl. Mod. On Fltr.");
        Clear(IntegrationTableMapping."Last Full Sync Start DateTime");
        IntegrationTableMapping.Insert();

        CloneIntegrationFieldMapping(SourceMappingName, IntegrationTableMapping.Name);
    end;

    local procedure CloneIntegrationFieldMapping(SourceMappingName: Code[20]; DestinationMappingName: Code[20])
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
        NewIntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", SourceMappingName);
        if IntegrationFieldMapping.FindSet then
            repeat
                NewIntegrationFieldMapping := IntegrationFieldMapping;
                NewIntegrationFieldMapping."No." := 0; // Autoincrement
                NewIntegrationFieldMapping."Integration Table Mapping Name" := DestinationMappingName;
                NewIntegrationFieldMapping.Insert();
            until IntegrationFieldMapping.Next = 0;
    end;

    local procedure GetTableViewForGuid(TableNo: Integer; CRMId: Guid) View: Text
    var
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        RecordRef: RecordRef;
    begin
        RecordRef.Open(TableNo);
        KeyRef := RecordRef.KeyIndex(1); // Primary Key
        FieldRef := KeyRef.FieldIndex(1);
        FieldRef.SetRange(CRMId);
        View := RecordRef.GetView;
        RecordRef.Close;
    end;

    local procedure GetTableViewForRecordID(RecordID: RecordID) View: Text
    var
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        RecordRef: RecordRef;
        I: Integer;
    begin
        RecordRef := RecordID.GetRecord;
        KeyRef := RecordRef.KeyIndex(1); // Primary Key
        for I := 1 to KeyRef.FieldCount do begin
            FieldRef := KeyRef.FieldIndex(I);
            FieldRef.SetRange(FieldRef.Value);
        end;
        View := RecordRef.GetView;
        RecordRef.Close;
    end;

    procedure CreateOrUpdateCRMAccountStatistics(Customer: Record Customer)
    var
        CRMAccount: Record "CRM Account";
        CRMStatisticsJob: Codeunit "CRM Statistics Job";
        CRMID: Guid;
    begin
        if not GetCoupledCRMID(Customer.RecordId, CRMID) then
            exit;

        CRMAccount.Get(CRMID);
        CRMStatisticsJob.CreateOrUpdateCRMAccountStatistics(Customer, CRMAccount);
        CRMStatisticsJob.UpdateStatusOfPaidInvoices(Customer."No.");
        Message(StrSubstNo(AccountStatisticsUpdatedMsg, CRMProductName.SHORT));
    end;

    procedure ShowCRMEntityFromRecordID(RecordID: RecordID)
    var
        CRMID: Guid;
    begin
        if not DefineCouplingIfNotCoupled(RecordID, CRMID) then
            exit;

        HyperLink(GetCRMEntityUrlFromRecordID(RecordID));
    end;

    procedure GetCRMEntityUrlFromRecordID(TargetRecordID: RecordID): Text
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMId: Guid;
    begin
        if not CRMIntegrationRecord.FindIDFromRecordID(TargetRecordID, CRMId) then
            Error(CouplingNotFoundErr, CRMProductName.FULL);

        exit(GetCRMEntityUrlFromCRMID(TargetRecordID.TableNo, CRMId));
    end;

    procedure GetCRMEntityUrlFromCRMID(TableId: Integer; CRMId: Guid): Text
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMEntityUrl: Text;
        CDSServerAddress: Text;
        handled: Boolean;
    begin
        OnGetCDSServerAddress(CDSServerAddress, handled);
        if handled then
            CRMEntityUrl := StrSubstNo(CRMEntityUrlTemplateTxt, CDSServerAddress, GetCRMEntityTypeName(TableId), CRMId)
        else begin
            CRMConnectionSetup.Get();
            CRMEntityUrl := StrSubstNo(CRMEntityUrlTemplateTxt, CRMConnectionSetup."Server Address", GetCRMEntityTypeName(TableId), CRMId);
            if CRMConnectionSetup."Use Newest UI" and (CRMConnectionSetup."Newest UI AppModuleId" <> '') then
                CRMEntityUrl += StrSubstNo(NewestUIAppIdParameterTxt, CRMConnectionSetup."Newest UI AppModuleId")
        end;

        exit(CRMEntityUrl);
    end;

    procedure OpenCoupledNavRecordPage(CRMID: Guid; CRMEntityTypeName: Text): Boolean
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        RecordId: RecordId;
        BCTableId: Integer;
    begin
        // Find the corresponding NAV record and type
        CRMSetupDefaults.GetTableIDCRMEntityNameMapping(TempNameValueBuffer);
        TempNameValueBuffer.SetCurrentKey(Name);
        TempNameValueBuffer.SetRange(Name, LowerCase(CRMEntityTypeName));

        if TempNameValueBuffer.IsEmpty() then
            exit(false);

        FindRecordFromNameValueBuffer(TempNameValueBuffer, CRMID, RecordId, BCTableId, CRMEntityTypeName);
        if RecordId.TableNo = 0 then begin
            GetIntegrationTableMappingFromCRMID(IntegrationTableMapping, BcTableId, CRMID);
            if (IntegrationTableMapping.Direction in [IntegrationTableMapping.Direction::Bidirectional, IntegrationTableMapping.Direction::FromIntegrationTable])
              and (IntegrationTableMapping."Synch. Only Coupled Records" = false) then
                SynchFromIntegrationTable(IntegrationTableMapping, CRMID)
            else
                exit(false);
        end;

        FindRecordFromNameValueBuffer(TempNameValueBuffer, CRMID, RecordId, BCTableId, CRMEntityTypeName);
        if RecordId.TableNo = 0 then
            exit(false);
        OpenRecordCardPage(RecordID);
        exit(true);
    end;

    local procedure FindRecordFromNameValueBuffer(var TempNameValueBuffer: Record "Name/Value Buffer" temporary; CRMID: Guid; var RecordId: RecordId; var BCTableId: Integer; CRMEntityTypeName: Text)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        TableId: Integer;
    begin
        TempNameValueBuffer.SetCurrentKey(Name);
        TempNameValueBuffer.SetRange(Name, LowerCase(CRMEntityTypeName));
        if TempNameValueBuffer.FindSet() then
            repeat
                Evaluate(TableId, TempNameValueBuffer.Value);
                if not IsCRMTable(TableId) then
                    BCTableId := TableId;
                if CRMIntegrationRecord.FindRecordIDFromID(CRMID, TableId, RecordId) then
                    break;
            until TempNameValueBuffer.Next() = 0;
    end;

    local procedure SynchFromIntegrationTable(IntegrationTableMapping: Record "Integration Table Mapping"; CRMID: Guid)
    begin
        IntegrationTableMapping.SetIntegrationTableFilter(GetTableViewForGuid(IntegrationTableMapping."Integration Table ID", CRMID));
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::FromIntegrationTable;
        AddIntegrationTableMapping(IntegrationTableMapping);
        Commit();
        Codeunit.Run(IntegrationTableMapping."Synch. Codeunit ID", IntegrationTableMapping);
        IntegrationTableMapping.Delete(true);
        Commit();
    end;

    local procedure OpenRecordCardPage(RecordID: RecordID)
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
        Currency: Record Currency;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        UnitOfMeasure: Record "Unit of Measure";
        Item: Record Item;
        Resource: Record Resource;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustomerPriceGroup: Record "Customer Price Group";
        RecordRef: RecordRef;
        IsHandled: Boolean;
    begin
        // Open the right kind of card page
        OnBeforeOpenRecordCardPage(RecordID, IsHandled);
        If IsHandled then
            exit;

        RecordRef := RecordID.GetRecord;
        case RecordID.TableNo of
            DATABASE::Contact:
                begin
                    RecordRef.SetTable(Contact);
                    PAGE.Run(PAGE::"Contact Card", Contact);
                end;
            DATABASE::Currency:
                begin
                    RecordRef.SetTable(Currency);
                    PAGE.Run(PAGE::"Currency Card", Currency);
                end;
            DATABASE::Customer:
                begin
                    RecordRef.SetTable(Customer);
                    PAGE.Run(PAGE::"Customer Card", Customer);
                end;
            DATABASE::Vendor:
                begin
                    RecordRef.SetTable(Vendor);
                    PAGE.Run(PAGE::"Vendor Card", Vendor);
                end;
            DATABASE::Item:
                begin
                    RecordRef.SetTable(Item);
                    PAGE.Run(PAGE::"Item Card", Item);
                end;
            DATABASE::"Sales Invoice Header":
                begin
                    RecordRef.SetTable(SalesInvoiceHeader);
                    PAGE.Run(PAGE::"Posted Sales Invoice", SalesInvoiceHeader);
                end;
            DATABASE::Resource:
                begin
                    RecordRef.SetTable(Resource);
                    PAGE.Run(PAGE::"Resource Card", Resource);
                end;
            DATABASE::"Salesperson/Purchaser":
                begin
                    RecordRef.SetTable(SalespersonPurchaser);
                    PAGE.Run(PAGE::"Salesperson/Purchaser Card", SalespersonPurchaser);
                end;
            DATABASE::"Unit of Measure":
                begin
                    RecordRef.SetTable(UnitOfMeasure);
                    // There is no Unit of Measure card. Open the list, filtered down to this instance.
                    PAGE.Run(PAGE::"Units of Measure", UnitOfMeasure);
                end;
            DATABASE::"Customer Price Group":
                begin
                    RecordRef.SetTable(CustomerPriceGroup);
                    // There is no Customer Price Group card. Open the list, filtered down to this instance.
                    PAGE.Run(PAGE::"Customer Price Groups", CustomerPriceGroup);
                end;
            else
                Error(NoCardPageActionDefinedForTableIdErr, RecordID.TableNo);
        end;
    end;

    procedure GetCRMEntityTypeName(TableId: Integer): Text
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
    begin
        CRMSetupDefaults.GetTableIDCRMEntityNameMapping(TempNameValueBuffer);
        TempNameValueBuffer.SetRange(Value, Format(TableId));
        if TempNameValueBuffer.FindFirst then
            exit(TempNameValueBuffer.Name);
        Error(UnableToResolveCRMEntityNameFrmTableIDErr, TableId, CRMProductName.SHORT);
    end;

    local procedure GetCoupledCRMID(RecordID: RecordID; var CRMID: Guid): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        exit(CRMIntegrationRecord.FindIDFromRecordID(RecordID, CRMID))
    end;

    local procedure DefineCouplingIfNotCoupled(RecordID: RecordID; var CRMID: Guid): Boolean
    var
        RecordRef: RecordRef;
    begin
        if GetCoupledCRMID(RecordID, CRMID) then
            exit(true);

        RecordRef.Open(RecordID.TableNo);
        if Confirm(StrSubstNo(ManageCouplingQst, RecordRef.Caption, CRMProductName.FULL), false) then
            if DefineCoupling(RecordID) then
                exit(GetCoupledCRMID(RecordID, CRMID));
        exit(false);
    end;

    procedure DefineCoupling(RecordID: RecordID): Boolean
    var
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        CreateNew: Boolean;
        Synchronize: Boolean;
        Direction: Option;
        CRMID: Guid;
    begin
        if CRMCouplingManagement.DefineCoupling(RecordID, CRMID, CreateNew, Synchronize, Direction) then begin
            if CreateNew then
                CreateNewRecordsInCRM(RecordID)
            else
                if Synchronize then
                    PerformInitialSynchronization(RecordID, CRMID, Direction);
            exit(true);
        end;

        exit(false);
    end;

    procedure ManageCreateNewRecordFromCRM(TableID: Integer)
    begin
        // Extinct method. Kept for backward compatibility.
        case TableID of
            DATABASE::Contact:
                CreateNewContactFromCRM;
            DATABASE::Customer:
                CreateNewCustomerFromCRM;
        end;
    end;

    procedure CreateNewContactFromCRM()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        GetIntegrationTableMapping(IntegrationTableMapping, DATABASE::Contact);
        PAGE.RunModal(PAGE::"CRM Contact List");
    end;

    procedure CreateNewCustomerFromCRM()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        GetIntegrationTableMapping(IntegrationTableMapping, DATABASE::Customer);
        PAGE.RunModal(PAGE::"CRM Account List");
    end;

    [Scope('OnPrem')]
    procedure ShowCustomerCRMOpportunities(Customer: Record Customer)
    var
        CRMOpportunity: Record "CRM Opportunity";
        CRMID: Guid;
    begin
        if not IsCRMIntegrationEnabled then
            exit;

        if not DefineCouplingIfNotCoupled(Customer.RecordId, CRMID) then
            exit;

        CRMOpportunity.FilterGroup := 2;
        CRMOpportunity.SetRange(ParentAccountId, CRMID);
        CRMOpportunity.SetRange(StateCode, CRMOpportunity.StateCode::Open);
        CRMOpportunity.FilterGroup := 0;
        PAGE.Run(PAGE::"CRM Opportunity List", CRMOpportunity);
    end;

    [Scope('OnPrem')]
    procedure ShowCustomerCRMQuotes(Customer: Record Customer)
    var
        CRMQuote: Record "CRM Quote";
        CRMID: Guid;
    begin
        if not IsCRMIntegrationEnabled then
            exit;

        if not DefineCouplingIfNotCoupled(Customer.RecordId, CRMID) then
            exit;

        CRMQuote.FilterGroup := 2;
        CRMQuote.SetRange(CustomerId, CRMID);
        CRMQuote.SetRange(StateCode, CRMQuote.StateCode::Active);
        CRMQuote.FilterGroup := 0;
        PAGE.Run(PAGE::"CRM Sales Quote List", CRMQuote);
    end;

    [Scope('OnPrem')]
    procedure ShowCustomerCRMCases(Customer: Record Customer)
    var
        CRMIncident: Record "CRM Incident";
        CRMID: Guid;
    begin
        if not IsCRMIntegrationEnabled then
            exit;

        if not DefineCouplingIfNotCoupled(Customer.RecordId, CRMID) then
            exit;

        CRMIncident.FilterGroup := 2;
        CRMIncident.SetRange(CustomerId, CRMID);
        CRMIncident.SetRange(StateCode, CRMIncident.StateCode::Active);
        CRMIncident.FilterGroup := 2;
        PAGE.Run(PAGE::"CRM Case List", CRMIncident);
    end;

    procedure GetNoOfCRMOpportunities(Customer: Record Customer): Integer
    var
        CRMOpportunity: Record "CRM Opportunity";
        CRMID: Guid;
    begin
        if not IsCRMIntegrationEnabled then
            exit(0);

        if not GetCoupledCRMID(Customer.RecordId, CRMID) then
            exit(0);

        CRMOpportunity.SetRange(ParentAccountId, CRMID);
        CRMOpportunity.SetRange(StateCode, CRMOpportunity.StateCode::Open);
        exit(CRMOpportunity.Count);
    end;

    procedure GetNoOfCRMQuotes(Customer: Record Customer): Integer
    var
        CRMQuote: Record "CRM Quote";
        CRMID: Guid;
    begin
        if not IsCRMIntegrationEnabled then
            exit(0);

        if not GetCoupledCRMID(Customer.RecordId, CRMID) then
            exit(0);

        CRMQuote.SetRange(CustomerId, CRMID);
        CRMQuote.SetRange(StateCode, CRMQuote.StateCode::Active);
        exit(CRMQuote.Count);
    end;

    procedure GetNoOfCRMCases(Customer: Record Customer): Integer
    var
        CRMIncident: Record "CRM Incident";
        CRMID: Guid;
    begin
        if not IsCRMIntegrationEnabled then
            exit(0);

        if not GetCoupledCRMID(Customer.RecordId, CRMID) then
            exit(0);

        CRMIncident.SetRange(StateCode, CRMIncident.StateCode::Active);
        CRMIncident.SetRange(CustomerId, CRMID);
        exit(CRMIncident.Count);
    end;

    local procedure GetSelectedMultipleSyncDirection(IntegrationTableMapping: Record "Integration Table Mapping"): Integer
    var
        SynchronizeNowQuestion: Text;
        AllowedDirection: Integer;
        RecommendedDirection: Integer;
    begin
        AllowedDirection := IntegrationTableMapping.Direction;
        RecommendedDirection := AllowedDirection;
        case AllowedDirection of
            IntegrationTableMapping.Direction::Bidirectional:
                exit(
                  StrMenu(UpdateNowDirectionQst, RecommendedDirection, UpdateMultipleNowTitleTxt));
            IntegrationTableMapping.Direction::FromIntegrationTable:
                SynchronizeNowQuestion := StrSubstNo(UpdateMultipleNowFromCRMQst, CRMProductName.SHORT);
            else
                SynchronizeNowQuestion := StrSubstNo(UpdateMultipleNowToCRMQst, CRMProductName.SHORT);
        end;

        if Confirm(SynchronizeNowQuestion, true) then
            exit(AllowedDirection);
        exit(0); // user canceled the process
    end;

    local procedure GetSelectedSingleSyncDirection(IntegrationTableMapping: Record "Integration Table Mapping"; RecordRef: RecordRef; CRMID: Guid; var RecommendedDirectionIgnored: Boolean): Integer
    var
        IntegrationRecSynchInvoke: Codeunit "Integration Rec. Synch. Invoke";
        CRMRecordRef: RecordRef;
        RecordIDDescr: Text;
        SynchronizeNowQuestion: Text;
        AllowedDirection: Integer;
        RecommendedDirection: Integer;
        SelectedDirection: Integer;
        RecordModified: Boolean;
        CRMRecordModified: Boolean;
        DefaultAnswer: Boolean;
    begin
        AllowedDirection := IntegrationTableMapping.Direction;

        // Determine which sides were modified since last synch
        IntegrationTableMapping.GetRecordRef(CRMID, CRMRecordRef);
        RecordModified := IntegrationRecSynchInvoke.WasModifiedAfterLastSynch(IntegrationTableMapping, RecordRef);
        CRMRecordModified := IntegrationRecSynchInvoke.WasModifiedAfterLastSynch(IntegrationTableMapping, CRMRecordRef);
        RecordIDDescr := Format(RecordRef.RecordId, 0, 1);
        if RecordModified and CRMRecordModified then
            // Changes on both sides. Bidirectional: warn user. Unidirectional: confirm and exit.
            case AllowedDirection of
                IntegrationTableMapping.Direction::Bidirectional:
                    Message(BothRecordsModifiedBiDirectionalMsg, RecordRef.Caption, CRMRecordRef.Caption, CRMProductName.SHORT);
                IntegrationTableMapping.Direction::ToIntegrationTable:
                    begin
                        if Confirm(
                             BothRecordsModifiedToCRMQst, false, RecordIDDescr, CRMRecordRef.Caption, PRODUCTNAME.Full, CRMProductName.SHORT)
                        then
                            exit(AllowedDirection);
                        exit(0);
                    end;
                IntegrationTableMapping.Direction::FromIntegrationTable:
                    begin
                        if Confirm(BothRecordsModifiedToNAVQst, false, RecordIDDescr, CRMRecordRef.Caption, PRODUCTNAME.Short) then
                            exit(AllowedDirection);
                        exit(0);
                    end;
            end;

        // Zero or one side changed. Synch for zero too because dependent objects could have changed.
        case AllowedDirection of
            IntegrationTableMapping.Direction::Bidirectional:
                begin
                    // Default from NAV to CRM
                    RecommendedDirection := IntegrationTableMapping.Direction::ToIntegrationTable;
                    if CRMRecordModified and not RecordModified then
                        RecommendedDirection := IntegrationTableMapping.Direction::FromIntegrationTable;
                    SelectedDirection :=
                      StrMenu(
                        UpdateNowDirectionQst, RecommendedDirection,
                        StrSubstNo(UpdateOneNowTitleTxt, RecordIDDescr));
                    RecommendedDirectionIgnored := SelectedDirection <> RecommendedDirection;
                    exit(SelectedDirection);
                end;
            IntegrationTableMapping.Direction::FromIntegrationTable:
                if RecordModified then
                    SynchronizeNowQuestion := StrSubstNo(UpdateOneNowFromOldCRMQst, RecordIDDescr, PRODUCTNAME.Short, CRMProductName.SHORT)
                else begin
                    SynchronizeNowQuestion := StrSubstNo(UpdateOneNowFromCRMQst, RecordIDDescr, CRMProductName.SHORT);
                    DefaultAnswer := true;
                end;
            else
                if CRMRecordModified then
                    SynchronizeNowQuestion := StrSubstNo(UpdateOneNowToModifiedCRMQst, RecordIDDescr, PRODUCTNAME.Short, CRMProductName.SHORT)
                else begin
                    SynchronizeNowQuestion := StrSubstNo(UpdateOneNowToCRMQst, RecordIDDescr, CRMProductName.SHORT);
                    DefaultAnswer := true;
                end;
        end;

        if Confirm(SynchronizeNowQuestion, DefaultAnswer) then
            exit(AllowedDirection);

        exit(0); // user canceled the process
    end;

    [EventSubscriber(ObjectType::Table, 1400, 'OnRegisterServiceConnection', '', false, false)]
    procedure HandleCRMRegisterServiceConnection(var ServiceConnection: Record "Service Connection")
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        RecRef: RecordRef;
    begin
        if not CRMConnectionSetup.Get then begin
            if not CRMConnectionSetup.WritePermission then
                exit;
            CRMConnectionSetup.Init();
            CRMConnectionSetup.Insert();
        end;

        RecRef.GetTable(CRMConnectionSetup);
        ServiceConnection.Status := ServiceConnection.Status::Enabled;
        with CRMConnectionSetup do begin
            if not "Is Enabled" then
                ServiceConnection.Status := ServiceConnection.Status::Disabled
            else begin
                if TestConnection then
                    ServiceConnection.Status := ServiceConnection.Status::Connected
                else
                    ServiceConnection.Status := ServiceConnection.Status::Error;
            end;
            ServiceConnection.InsertServiceConnectionExtended(
              ServiceConnection, RecRef.RecordId, TableCaption, "Server Address", PAGE::"CRM Connection Setup",
              PAGE::"CRM Connection Setup Wizard");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDS Integration Mgt.", 'OnGetIntegrationSolutions', '', false, false)]
    local procedure HandleOnGetIntegrationSolutions(var SolutionUniqueNameList: List of [Text])
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if CRMConnectionSetup.Get() then
            if CRMConnectionSetup."Is Enabled" then
                SolutionUniqueNameList.Add(CRMProductName.UNIQUE());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDS Integration Mgt.", 'OnGetIntegrationRequiredRoles', '', false, false)]
    local procedure HandleOnGetIntegrationRequiredRoles(var RequiredRoleIdList: List of [Guid])
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if CRMConnectionSetup.Get() then
            if CRMConnectionSetup."Is Enabled" then begin
                RequiredRoleIdList.Add(GetIntegrationAdminRoleID());
                RequiredRoleIdList.Add(GetIntegrationUserRoleID());
            end;
    end;

    procedure ClearState()
    begin
        CRMIntegrationEnabledState := CRMIntegrationEnabledState::" "
    end;

    [Scope('OnPrem')]
    procedure GetLastErrorMessage(): Text
    var
        ErrorObject: DotNet Exception;
    begin
        ErrorObject := GetLastErrorObject;
        if IsNull(ErrorObject) then
            exit('');
        if StrPos(ErrorObject.GetType.Name, 'NavCrmException') > 0 then
            if not IsNull(ErrorObject.InnerException) then
                exit(ErrorObject.InnerException.Message);
        exit(GetLastErrorText);
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure ImportCRMSolution(ServerAddress: Text; IntegrationUserEmail: Text; AdminUserEmail: Text; AdminUserPassword: Text; ProxyVersion: Integer)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMRole: Record "CRM Role";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        CRMHelper: DotNet CrmHelper;
        UserGUID: Guid;
        IntegrationAdminRoleGUID: Guid;
        IntegrationUserRoleGUID: Guid;
        DefaultOwningTeamGUID: Guid;
        TempConnectionString: Text;
    begin
        CheckConnectRequiredFields(ServerAddress, IntegrationUserEmail);
        TempConnectionString := StrSubstNo(
            ConnectionStringFormatTok, ServerAddress, AdminUserEmail, AdminUserPassword, ProxyVersion, 'AuthType=Office365;');
        if not InitializeCRMConnection(CRMHelper, TempConnectionString) then
            ProcessConnectionFailures;

        UserGUID := CRMHelper.GetUserId(IntegrationUserEmail);
        if IsNullGuid(UserGUID) then
            Error(UserDoesNotExistCRMErr, IntegrationUserEmail, CRMProductName.SHORT);

        if not CRMHelper.CheckSolutionPresence(MicrosoftDynamicsNavIntegrationTxt) then
            if not ImportDefaultCRMSolution(CRMHelper) then
                ProcessConnectionFailures;

        IntegrationAdminRoleGUID := CRMHelper.GetRoleId(GetIntegrationAdminRoleID);
        IntegrationUserRoleGUID := CRMHelper.GetRoleId(GetIntegrationUserRoleID);
        if not CRMHelper.CheckRoleAssignedToUser(UserGUID, IntegrationAdminRoleGUID) then
            CRMHelper.AssociateUserWithRole(UserGUID, IntegrationAdminRoleGUID);
        if not CRMHelper.CheckRoleAssignedToUser(UserGUID, IntegrationUserRoleGUID) then
            CRMHelper.AssociateUserWithRole(UserGUID, IntegrationUserRoleGUID);

        if CDSIntegrationImpl.IsIntegrationEnabled() then begin
            CDSIntegrationImpl.RegisterConnection();
            CDSIntegrationImpl.ActivateConnection();
            CDSConnectionSetup.Get();
            DefaultOwningTeamGUID := CDSIntegrationImpl.GetOwningTeamId(CDSConnectionSetup);
            CRMRole.SetRange(ParentRoleId, IntegrationAdminRoleGUID);
            CRMRole.SetRange(BusinessUnitId, CDSIntegrationImpl.GetCoupledBusinessUnitId());
            if not CRMRole.FindFirst() then begin
                SendTraceTag('0000BKQ', CategoryTok, VERBOSITY::Normal, RoleNotFoundForBusinessUnitTxt, DataClassification::SystemMetadata);
                Error(IntegrationRoleNotFoundErr, GetIntegrationAdminRoleID(), CDSIntegrationImpl.GetDefaultBusinessUnitName());
            end;
            if not CDSIntegrationImpl.AssignTeamRole(CrmHelper, DefaultOwningTeamGUID, CRMRole.RoleId) then begin
                SendTraceTag('0000BKR', CategoryTok, VERBOSITY::Normal, CannotAssignRoleToTeamTxt, DataClassification::SystemMetadata);
                Error(CannotAssignRoleToTeamErr, DefaultOwningTeamGUID, CDSIntegrationImpl.GetDefaultBusinessUnitName(), CRMRole.Name);
            end;
            CRMRole.SetRange(ParentRoleId, IntegrationUserRoleGUID);
            CRMRole.SetRange(BusinessUnitId, CDSIntegrationImpl.GetCoupledBusinessUnitId());
            if not CRMRole.FindFirst() then begin
                SendTraceTag('0000BKS', CategoryTok, VERBOSITY::Normal, RoleNotFoundForBusinessUnitTxt, DataClassification::SystemMetadata);
                Error(IntegrationRoleNotFoundErr, GetIntegrationUserRoleID(), CDSIntegrationImpl.GetDefaultBusinessUnitName());
            end;
            if not CDSIntegrationImpl.AssignTeamRole(CrmHelper, DefaultOwningTeamGUID, CRMRole.RoleId) then begin
                SendTraceTag('0000BKT', CategoryTok, VERBOSITY::Normal, CannotAssignRoleToTeamTxt, DataClassification::SystemMetadata);
                Error(CannotAssignRoleToTeamErr, DefaultOwningTeamGUID, CDSIntegrationImpl.GetDefaultBusinessUnitName(), CRMRole.Name);
            end;
        end;
    end;

    [TryFunction]
    local procedure ImportDefaultCRMSolution(var CRMHelper: DotNet CrmHelper)
    begin
        CRMHelper.ImportDefaultCrmSolution;
    end;

    procedure CheckConnectRequiredFields(ServerAddress: Text; IntegrationUserEmail: Text)
    begin
        if (IntegrationUserEmail = '') or (ServerAddress = '') then
            Error(EmailAndServerAddressEmptyErr);
    end;

    procedure CheckModifyCRMConnectionURL(var ServerAddress: Text[250])
    var
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        UriHelper: DotNet Uri;
        UriHelper2: DotNet Uri;
        UriKindHelper: DotNet UriKind;
        UriPartialHelper: DotNet UriPartial;
        ProposedUri: Text[250];
    begin
        if (ServerAddress = '') or (ServerAddress = '@@test@@') then
            exit;

        ServerAddress := DelChr(ServerAddress, '<>');

        if not UriHelper.TryCreate(ServerAddress, UriKindHelper.Absolute, UriHelper2) then
            if not UriHelper.TryCreate('https://' + ServerAddress, UriKindHelper.Absolute, UriHelper2) then
                Error(InvalidUriErr);

        if UriHelper2.Scheme <> 'https' then begin
            if not CRMSetupDefaults.GetAllowNonSecureConnections then
                Error(MustUseHttpsErr, CRMProductName.SHORT);
            if UriHelper2.Scheme <> 'http' then
                Error(MustUseHttpOrHttpsErr, UriHelper2.Scheme, CRMProductName.SHORT);
        end;

        ProposedUri := UriHelper2.GetLeftPart(UriPartialHelper.Authority);

        // Test that a specific port number is given
        if ((UriHelper2.Port = 443) or (UriHelper2.Port = 80)) and (LowerCase(ServerAddress) <> LowerCase(ProposedUri)) then begin
            if Confirm(StrSubstNo(ReplaceServerAddressQst, ServerAddress, ProposedUri)) then
                ServerAddress := ProposedUri;
        end;
    end;

    procedure GetOrganizationFromUrl(ServerAddress: Text[250]) orgName: Text
    var
        UriHelper: DotNet Uri;
        UriHelper2: DotNet Uri;
        UriKindHelper: DotNet UriKind;
    begin
        // Return the organization name from an OnPremise URL which is in the form
        // http://crm-server:port/organization-name
        // Notice that TryCreate will fail if the port is not a number

        if (ServerAddress = '') or (ServerAddress = '@@test@@') then
            exit('');

        ServerAddress := DelChr(ServerAddress, '<>');

        if not UriHelper.TryCreate(ServerAddress, UriKindHelper.Absolute, UriHelper2) then
            if not UriHelper.TryCreate('https://' + ServerAddress, UriKindHelper.Absolute, UriHelper2) then
                Error(InvalidUriErr);

        orgName := UriHelper2.AbsolutePath;
        if orgName = '/' then
            exit('');

        if (orgName <> '') and (StrLen(orgName) > 1) then
            orgName := CopyStr(orgName, 2);
        exit(orgName);
    end;

    procedure ConstructConnectionStringForSolutionImport(ServerAddress: Text): Text
    var
        FirstPart: Text;
        SecondPart: Text;
        FirstLevel: Integer;
    begin
        FirstLevel := StrPos(ServerAddress, '.');
        if FirstLevel = 0 then
            Error(CRMConnectionURLWrongErr, CRMProductName.SHORT);
        FirstPart := CopyStr(ServerAddress, 1, FirstLevel);
        SecondPart := CopyStr(ServerAddress, FirstLevel);
        exit(StrSubstNo(ImportSolutionConnectStringTok, FirstPart, SecondPart));
    end;

    [TryFunction]
    local procedure InitializeCRMConnection(var CRMHelper: DotNet CrmHelper; ConnectionString: Text)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if ConnectionString = '' then begin
            CRMConnectionSetup.Get();
            CRMHelper := CRMHelper.CrmHelper(CRMConnectionSetup.GetConnectionStringWithPassword);
        end else
            CRMHelper := CRMHelper.CrmHelper(ConnectionString);
        if not TestCRMConnection(CRMHelper) then
            ProcessConnectionFailures;
    end;

    local procedure ProcessConnectionFailures()
    var
        DotNetExceptionHandler: Codeunit "DotNet Exception Handler";
        FaultException: DotNet FaultException;
        FileNotFoundException: DotNet FileNotFoundException;
        ArgumentNullException: DotNet ArgumentNullException;
        CRMHelper: DotNet CrmHelper;
    begin
        DotNetExceptionHandler.Collect;

        if DotNetExceptionHandler.TryCastToType(GetDotNetType(FaultException)) then
            Error(AdminEmailPasswordWrongErr, CRMProductName.SHORT);
        if DotNetExceptionHandler.TryCastToType(GetDotNetType(FileNotFoundException)) then
            Error(CRMSolutionFileNotFoundErr);
        if DotNetExceptionHandler.TryCastToType(CRMHelper.OrganizationServiceFaultExceptionType) then
            Error(AdminUserDoesNotHavePriviligesErr, CRMProductName.SHORT);
        if DotNetExceptionHandler.TryCastToType(CRMHelper.SystemNetWebException) then
            Error(CRMConnectionURLWrongErr, CRMProductName.SHORT);
        if DotNetExceptionHandler.CastToType(ArgumentNullException, GetDotNetType(ArgumentNullException)) then
            case ArgumentNullException.ParamName of
                'cred':
                    Error(AdminEmailPasswordWrongErr, CRMProductName.SHORT);
                'Organization Name':
                    Error(CRMConnectionURLWrongErr, CRMProductName.SHORT)
            end;
        DotNetExceptionHandler.Rethrow;
    end;

    local procedure GetIntegrationTableMappingFromCRMID(var IntegrationTableMapping: Record "Integration Table Mapping"; TableID: Integer; CRMID: Guid)
    var
        CRMAccount: Record "CRM Account";
        CRMProduct: Record "CRM Product";
    begin
        IntegrationTableMapping.SetRange("Synch. Codeunit ID", CODEUNIT::"CRM Integration Table Synch.");
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        if IsCRMTable(TableID) then
            IntegrationTableMapping.SetRange("Integration Table ID", TableID)
        else begin
            if (TableID = DATABASE::Vendor) or (TableID = DATABASE::Customer) then begin
                CRMAccount.SetRange(AccountId, CRMID);
                if CRMAccount.FindFirst() then begin
                    if CRMAccount.CustomerTypeCode = CRMAccount.CustomerTypeCode::Vendor then
                        TableID := DATABASE::Vendor;
                    if CRMAccount.CustomerTypeCode = CRMAccount.CustomerTypeCode::Customer then
                        TableID := DATABASE::Customer;
                end;
            end;
            if (TableID = DATABASE::Item) or (TableID = DATABASE::Resource) then begin
                CRMProduct.SetRange(ProductId, CRMID);
                if CRMProduct.FindFirst() then begin
                    if CRMProduct.ProductTypeCode = CRMProduct.ProductTypeCode::Services then
                        TableID := DATABASE::Resource;
                    if CRMProduct.ProductTypeCode = CRMProduct.ProductTypeCode::SalesInventory then
                        TableID := DATABASE::Item;
                end;
            end;
            IntegrationTableMapping.SetRange("Table ID", TableID);
        end;
        if not IntegrationTableMapping.FindFirst() then
            Error(IntegrationTableMappingNotFoundErr, IntegrationTableMapping.TableCaption, GetTableCaption(TableID));
    end;

    procedure SetupItemAvailabilityService()
    var
        TenantWebService: Record "Tenant Web Service";
        WebServiceManagement: Codeunit "Web Service Management";
    begin
        WebServiceManagement.CreateTenantWebService(
          TenantWebService."Object Type"::Page, PAGE::"Product Item Availability", GetProductItemAvailabilityServiceName, true);
    end;

    local procedure GetIntegrationAdminRoleID(): Text
    begin
        exit('8c8d4f51-a72b-e511-80d9-3863bb349780');
    end;

    local procedure GetIntegrationUserRoleID(): Text
    begin
        exit('6f960e32-a72b-e511-80d9-3863bb349780');
    end;

    procedure GetCommonNotificationID(): Guid
    begin
        exit('63428E33-54E4-42A6-82EE-3EEF268340BA');
    end;

    procedure GetSkippedNotificationID(): Guid
    begin
        exit('B523E8EA-56B3-4E79-837E-F812CFB74DD4');
    end;

    local procedure SendRestoredSyncNotification(Counter: Integer)
    var
        Msg: Text;
    begin
        if Counter = 1 then
            Msg := SyncRestoredMsg
        else
            Msg := StrSubstNo(SyncMultipleRestoredMsg, Counter);
        SendNotification(Msg);
    end;

    procedure SendResultNotification(RecVariant: Variant): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        RecordRef: RecordRef;
        NotificationMessage: Text;
        FailureDatetime: DateTime;
        SuccessDateTime: DateTime;
    begin
        RecordRef.GetTable(RecVariant);
        if CRMIntegrationRecord.FindByRecordID(RecordRef.RecordId) then begin
            if CRMIntegrationRecord.Skipped then
                exit(SendSkippedSyncNotification(CRMIntegrationRecord."Integration ID"));

            if CRMIntegrationRecord."Last Synch. CRM Result" = CRMIntegrationRecord."Last Synch. CRM Result"::Failure then
                GetNotificationDetailsFromIntegrationSyncJobEntry(
                  CRMIntegrationRecord."Last Synch. CRM Job ID", RecordRef.RecordId, NotificationMessage, FailureDatetime)
            else
                SuccessDateTime := CRMIntegrationRecord."Last Synch. CRM Modified On";

            if CRMIntegrationRecord."Last Synch. Result" = CRMIntegrationRecord."Last Synch. Result"::Failure then
                GetNotificationDetailsFromIntegrationSyncJobEntry(
                  CRMIntegrationRecord."Last Synch. Job ID", RecordRef.RecordId, NotificationMessage, FailureDatetime)
            else
                SuccessDateTime := CRMIntegrationRecord."Last Synch. Modified On";

            if SuccessDateTime > FailureDatetime then
                NotificationMessage := '';
        end else begin
            Clear(IntegrationSynchJob);
            IntegrationSynchJob."Synch. Direction" := IntegrationSynchJob."Synch. Direction"::ToIntegrationTable;
            if IntegrationSynchJob.GetErrorForRecordID(RecordRef.RecordId, IntegrationSynchJobErrors) then
                NotificationMessage := IntegrationSynchJobErrors.Message;
        end;
        if NotificationMessage <> '' then
            exit(SendNotification(NotificationMessage));
    end;

    local procedure SendSkippedSyncNotification(IntegrationID: Guid): Boolean
    var
        SyncNotification: Notification;
    begin
        SyncNotification.Id := GetSkippedNotificationID;
        SyncNotification.Recall;
        SyncNotification.Message(SyncSkippedMsg);
        SyncNotification.Scope(NOTIFICATIONSCOPE::LocalScope);
        SyncNotification.SetData('IntegrationID', IntegrationID);
        SyncNotification.AddAction(DetailsTxt, CODEUNIT::"CRM Integration Management", 'ShowSkippedRecords');
        SyncNotification.Send;
        exit(true);
    end;

    local procedure SendSyncNotification(RecordCounter: array[4] of Integer): Boolean
    begin
        if RecordCounter[NoOf::Total] = 1 then begin
            if RecordCounter[NoOf::Scheduled] = 1 then
                exit(SendNotification(SyncNowScheduledMsg));
            if RecordCounter[NoOf::Skipped] = 1 then
                exit(SendNotification(SyncNowSkippedMsg));
            exit(SendNotification(SyncNowFailedMsg));
        end;
        exit(SendMultipleSyncNotification(RecordCounter));
    end;

    local procedure SendMultipleSyncNotification(RecordCounter: array[4] of Integer): Boolean
    begin
        exit(
          SendNotification(
            StrSubstNo(
              SyncMultipleMsg,
              RecordCounter[NoOf::Scheduled], RecordCounter[NoOf::Failed],
              RecordCounter[NoOf::Skipped], RecordCounter[NoOf::Total])));
    end;

    local procedure SendNotification(Msg: Text): Boolean
    var
        SyncNotification: Notification;
    begin
        SyncNotification.Id := GetCommonNotificationID;
        SyncNotification.Recall;
        SyncNotification.Message(Msg);
        SyncNotification.Scope(NOTIFICATIONSCOPE::LocalScope);
        SyncNotification.Send;
        exit(true);
    end;

    procedure ShowLog(RecId: RecordID)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        GetIntegrationTableMapping(IntegrationTableMapping, RecId.TableNo);
        CRMIntegrationRecord.FindByRecordID(RecId);
        IntegrationTableMapping.ShowLog(CRMIntegrationRecord.GetLatestJobIDFilter);
    end;

    procedure ShowSkippedRecords(SkippedSyncNotification: Notification)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMSkippedRecords: Page "CRM Skipped Records";
        IntegrationID: Guid;
    begin
        if Evaluate(IntegrationID, SkippedSyncNotification.GetData('IntegrationID')) then begin
            CRMIntegrationRecord.SetRange("Integration ID", IntegrationID);
            if CRMIntegrationRecord.FindFirst then
                CRMSkippedRecords.SetRecords(CRMIntegrationRecord);
        end;
        CRMSkippedRecords.Run;
    end;

    procedure CoupleCRMEntity(RecordID: RecordID; CRMID: Guid; var Synchronize: Boolean; var Direction: Option): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CouplingRecordBuffer: Record "Coupling Record Buffer";
    begin
        CouplingRecordBuffer.Initialize(RecordID);
        CouplingRecordBuffer."CRM ID" := CRMID;
        if not CouplingRecordBuffer.Insert() then
            CouplingRecordBuffer.Modify();
        if not IsNullGuid(CouplingRecordBuffer."CRM ID") then begin
            CRMIntegrationRecord.CoupleRecordIdToCRMID(CouplingRecordBuffer."NAV Record ID", CouplingRecordBuffer."CRM ID");
            if CouplingRecordBuffer.GetPerformInitialSynchronization then begin
                Synchronize := true;
                Direction := CouplingRecordBuffer.GetInitialSynchronizationDirection;
                PerformInitialSynchronization(CouplingRecordBuffer."NAV Record ID", CouplingRecordBuffer."CRM ID", Direction);
            end;
        end else
            exit(false);
        exit(true);
    end;

    [TryFunction]
    local procedure TestCRMConnection(var CRMHelper: DotNet CrmHelper)
    begin
        CRMHelper.CheckCredentials;
        CRMHelper.GetConnectedCrmVersion;
    end;

    [Scope('OnPrem')]
    procedure InitializeProxyVersionList(var TempStack: Record TempStack temporary)
    var
        CRMHelper: DotNet CrmHelper;
        IList: DotNet GenericList1;
        i: Integer;
        ProxyCount: Integer;
    begin
        IList := CRMHelper.GetProxyIdList;
        ProxyCount := IList.Count();
        for i := 0 to ProxyCount - 1 do begin
            TempStack.StackOrder := IList.Item(i);
            TempStack.Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure GetLastProxyVersionItem(): Integer
    var
        TempStack: Record TempStack temporary;
    begin
        InitializeProxyVersionList(TempStack);
        TempStack.FindLast;
        exit(TempStack.StackOrder);
    end;

    local procedure GetNotificationDetailsFromIntegrationSyncJobEntry(JobId: Guid; RecRefRecId: RecordID; var NotificationMessage: Text; var FailureDatetime: DateTime)
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
    begin
        if IntegrationSynchJob.Get(JobId) then
            if IntegrationSynchJob.GetErrorForRecordID(RecRefRecId, IntegrationSynchJobErrors) then begin
                NotificationMessage := IntegrationSynchJobErrors.Message;
                FailureDatetime := IntegrationSynchJobErrors."Date/Time";
            end
    end;

    procedure ClearConnectionDisableReason(var CRMConnectionSetup: Record "CRM Connection Setup")
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        Notification: Notification;
    begin
        Notification.Id := CRMIntegrationManagement.GetCRMDisabledErrorReasonNotificationId;
        Notification.Recall;
        Clear(CRMConnectionSetup."Disable Reason");
        CRMConnectionSetup.Modify();
    end;

    procedure GetCRMDisabledErrorReasonNotificationId() CRMDisabledErrorReasonNotificationId: Guid
    begin
        Evaluate(CRMDisabledErrorReasonNotificationId, CRMDisabledErrorReasonNotificationIdTxt);
        exit(CRMDisabledErrorReasonNotificationId);
    end;

    procedure IsWorkingConnection(): Boolean
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        exit(CRMConnectionSetup.TryReadSystemUsers);
    end;

    local procedure DisableConnection()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        LastError: Text;
    begin
        LastError := GetLastErrorText;
        LastError := CopyStr(LastError, StrPos(Format(LastError), ':') + 1, StrLen(LastError));
        Message(StrSubstNo(ConnectionBrokenMsg, LastError));
        if CRMConnectionSetup.Get then begin
            CRMConnectionSetup.Validate("Is Enabled", false);
            CRMConnectionSetup.Validate(
              "Disable Reason",
              CopyStr(LastError, 1, MaxStrLen(CRMConnectionSetup."Disable Reason")));
            CRMConnectionSetup.Modify();
        end;
    end;

    procedure SendConnectionDisabledNotification(DisableReason: Text[250])
    var
        Notification: Notification;
    begin
        Notification.Id := GetCRMDisabledErrorReasonNotificationId;
        Notification.Message := StrSubstNo(ConnectionDisabledNotificationMsg, DisableReason);
        Notification.Scope := NOTIFICATIONSCOPE::LocalScope;
        Notification.Send;
    end;

    procedure IsItemAvailabilityWebServiceEnabled(): Boolean
    var
        TenantWebService: Record "Tenant Web Service";
    begin
        if TenantWebService.Get(TenantWebService."Object Type"::Page, GetProductItemAvailabilityServiceName) then
            exit(TenantWebService.Published);
        exit(false);
    end;

    procedure GetItemAvailabilityWebServiceURL(): Text[250]
    var
        TenantWebService: Record "Tenant Web Service";
        TempWebServiceAggregate: Record "Web Service Aggregate" temporary;
        CRMConnectionSetup: Record "CRM Connection Setup";
        WebServiceManagement: Codeunit "Web Service Management";
        ClientType: Enum "Client Type";
    begin
        if not TenantWebService.Get(TenantWebService."Object Type"::Page, GetProductItemAvailabilityServiceName) then
            exit('');
        TempWebServiceAggregate.TransferFields(TenantWebService);
        TempWebServiceAggregate.Insert();
        exit(CopyStr(WebServiceManagement.GetWebServiceUrl(TempWebServiceAggregate, ClientType::ODataV3), 1, MaxStrLen(CRMConnectionSetup."Dynamics NAV OData URL")));
    end;

    procedure UnPublishOnWebService(var CRMConnectionSetup: Record "CRM Connection Setup")
    var
        TenantWebService: Record "Tenant Web Service";
    begin
        if Confirm(DoYouWantDisableWebServiceQst) then begin
            if TenantWebService.Get(TenantWebService."Object Type"::Page, GetProductItemAvailabilityServiceName) then begin
                TenantWebService.Validate(Published, false);
                TenantWebService.Modify();
            end;
            CRMConnectionSetup."Dynamics NAV OData URL" := '';
            CRMConnectionSetup.Modify();
        end;
    end;

    procedure PublishWebService(var CRMConnectionSetup: Record "CRM Connection Setup")
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        if not Confirm(DoYouWantEnableWebServiceQst) then
            exit;

        CRMIntegrationManagement.SetupItemAvailabilityService;
        CRMConnectionSetup.Validate(
          "Dynamics NAV OData URL",
          CRMIntegrationManagement.GetItemAvailabilityWebServiceURL);
        CRMConnectionSetup.Modify();
    end;

    local procedure GetProductItemAvailabilityServiceName(): Text[250]
    begin
        exit('ProductItemAvailability');
    end;

    procedure InitializeCRMSynchStatus()
    var
        CRMSynchStatus: Record "CRM Synch Status";
    begin
        if CRMSynchStatus.IsEmpty then begin
            CRMSynchStatus."Last Update Invoice Entry No." := 0;
            CRMSynchStatus.Insert();
        end;
    end;

    [EventSubscriber(ObjectType::Table, 5339, 'OnIsDataIntegrationEnabled', '', false, false)]
    local procedure IsDataIntegrationEnabled(var IsIntegrationEnabled: Boolean)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if not IsIntegrationEnabled then
            IsIntegrationEnabled := CRMConnectionSetup.IsEnabled;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Integration Synch. Job Errors", 'OnAfterLogSynchError', '', false, false)]
    local procedure DisableConnectionOnAfterLongSynchError(IntegrationSynchJobErrors: Record "Integration Synch. Job Errors")
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if not IntegrationSynchJobErrors.Message.Contains('CrmCreate') then
            exit;

        if not IntegrationSynchJobErrors.Message.Contains('prvCreate') then
            exit;

        DisableConnection();

        if CRMConnectionSetup.Get() then begin
            CRMConnectionSetup."Disable Reason" := StrSubstNo(ConnectionDisabledReasonTxt, CRMConnectionSetup."Server Address", CRMConnectionSetup."User Name");
            CRMConnectionSetup.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Table, 5339, 'OnForceSynchronizeDataIntegration', '', false, false)]
    local procedure ForceSynchronizeDataIntegration(LocalRecordID: RecordID; var SynchronizeHandled: Boolean)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if not CRMConnectionSetup.IsEnabled then
            exit;

        if SynchronizeHandled then
            exit;

        UpdateOneNow(LocalRecordID);
        SynchronizeHandled := true;
    end;

    [Scope('OnPrem')]
    procedure RegisterAssistedSetup()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        Info: ModuleInfo;
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
    begin
        NavApp.GetCurrentModuleInfo(Info);
        if not AssistedSetup.Exists(Info.Id(), PAGE::"CRM Connection Setup Wizard") then begin
            AssistedSetup.Add(Info.Id(), PAGE::"CRM Connection Setup Wizard", StrSubstNo(CRMConnectionSetupTxt, CRMProductName.SHORT),
                AssistedSetupGroup::Customize, VideoUrlSetupCRMConnectionTxt, VideoCategory::Customize, '');
        end;
    end;
}

