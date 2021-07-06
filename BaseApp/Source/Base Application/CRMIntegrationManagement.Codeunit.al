codeunit 5330 "CRM Integration Management"
{
    SingleInstance = true;

    trigger OnRun()
    begin
        CheckOrEnableCRMConnection;
    end;

    var
        CRMEntityUrlTemplateTxt: Label '%1/main.aspx?pagetype=entityrecord&etn=%2&id=%3', Locked = true;
        NewestUIAppIdParameterTxt: Label '&appid=%1', Locked = true;
        UnableToResolveCRMEntityNameFrmTableIDErr: Label 'The application is not designed to integrate table %1 with %2.', Comment = '%1 = table ID (numeric), %2 = Dataverse service name';
        CouplingNotFoundErr: Label 'The record is not coupled to %1.', Comment = '%1 = Dataverse service name';
        NoCardPageActionDefinedForTableIdErr: Label 'The open page action is not supported for Table %1.', Comment = '%1 = Table ID';
        IntegrationTableMappingNotFoundErr: Label 'No %1 was found for table %2.', Comment = '%1 = Integration Table Mapping caption, %2 = Table caption for the table which is not mapped';
        UpdateNowUniDirectionQst: Label 'Send data update to Dataverse.,Get data update from Dataverse.';
        UpdateNowBiDirectionQst: Label 'Send data update to Dataverse.,Get data update from Dataverse.,Merge data.';
        UpdateOneNowTitleTxt: Label 'Synchronize data for %1?', Comment = '%1 = Table caption and value for the entity we want to synchronize now.';
        UpdateMultipleNowTitleTxt: Label 'Synchronize data for the selected records?';
        ManageCouplingQst: Label 'The %1 record is not coupled to %2. Do you want to create a coupling?', Comment = '%1=The record caption (type), %2 = Dataverse service name';
        SyncNowFailedMsg: Label 'The synchronization failed.';
        SyncNowScheduledMsg: Label 'The synchronization has been scheduled.';
        SyncNowSkippedMsg: Label 'The synchronization has been skipped.';
        SyncMultipleMsg: Label 'The synchronization has been scheduled for %1 of %4 records. %2 records failed. %3 records were skipped.', Comment = '%1,%2,%3,%4 are numbers of records';
        SyncSkippedMsg: Label 'The record will be skipped for further synchronization due to a repeatable failure.';
        SyncRestoredMsg: Label 'The record has been restored for synchronization.';
        SyncMultipleRestoredMsg: Label '%1 records have been restored for synchronization.', Comment = '%1 - an integer, a count of records.';
        UncoupleFailedMsg: Label 'The uncoupling failed.';
        UncoupleScheduledMsg: Label 'The uncoupling has been scheduled.';
        UncoupleSkippedMsg: Label 'The uncoupling has been skipped.';
        UncoupleMultipleMsg: Label 'The uncoupling has been scheduled for %1 of %4 records. %2 records failed. %3 records were skipped.', Comment = '%1,%2,%3,%4 are numbers of records';
        DetailsTxt: Label 'Details.';
        UpdateOneNowToCRMQst: Label 'Send data update to %2 for %1?', Comment = '%1 = Table caption and value for the entity we want to synchronize now., %2 = Dataverse service name';
        UpdateOneNowToModifiedCRMQst: Label 'The %3 record coupled to %1 contains newer data than the %2 record. Do you want to overwrite the data in %3?', Comment = '%1 = Table caption and value for the entity we want to synchronize now. %2 - product name, %3 = Dataverse service name';
        UpdateOneNowFromCRMQst: Label 'Get data update from %2 for %1?', Comment = '%1 = Table caption and value for the entity we want to synchronize now., %2 = Dataverse service name';
        UpdateOneNowFromOldCRMQst: Label 'The %2 record %1 contains newer data than the %3 record. Get data update from %3, overwriting data in %2?', Comment = '%1 = Table caption and value for the entity we want to synchronize now. %2 - product name, %3 = Dataverse service name';
        UpdateMultipleNowToCRMQst: Label 'Send data update to %1 for the selected records?', Comment = '%1 = Dataverse service name';
        UpdateMultipleNowFromCRMQst: Label 'Get data update from %1 for the selected records?', Comment = '%1 = Dataverse service name';
        AccountStatisticsUpdatedMsg: Label 'The customer statistics have been successfully updated in %1.', Comment = '%1 = Dataverse service name';
        BothRecordsModifiedBiDirectionalConflictMsg: Label 'Both the %1 record and the %3 %2 record have been changed since the last synchronization, or synchronization has never been performed. Bi-directional synchronization is forbidden as a changed bidirectional field was detected, but you can continue continue with uni-derictional synchronization. If you continue, data on one of the records will be lost and replaced with data from the other record.', Comment = '%1 and %2 area captions of tables such as Customer and CRM Account, %3 = Dataverse service name';
        BothRecordsModifiedBiDirectionalNoConflictMsg: Label 'Both the %1 record and the %3 %2 record have been changed since the last synchronization, or synchronization has never been performed. No one changed bidirectional field was detected, therefore you can continue continue with both bi- and uni-directional synchronization. If you continue, data will be updated in accordance with the chosen synchronization direction and fields mapping.', Comment = '%1 and %2 area captions of tables such as Customer and CRM Account, %3 = Dataverse service name';
        BothRecordsModifiedToCRMQst: Label 'Both %1 and the %4 %2 record have been changed since the last synchronization, or synchronization has never been performed. If you continue with synchronization, data in %4 will be overwritten with data from %3. Are you sure you want to synchronize?', Comment = '%1 is a formatted RecordID, such as ''Customer 1234''. %2 is the caption of a Dataverse table. %3 - product name, %4 = Dataverse service name';
        BothRecordsModifiedToNAVQst: Label 'Both %1 and the %4 %2 record have been changed since the last synchronization, or synchronization has never been performed. If you continue with synchronization, data in %3 will be overwritten with data from %4. Are you sure you want to synchronize?', Comment = '%1 is a formatted RecordID, such as ''Customer 1234''. %2 is the caption of a Dataverse table. %3 - product name, %4 = Dataverse service name';
        CRMProductName: Codeunit "CRM Product Name";
        CRMIntegrationEnabledState: Option " ","Not Enabled",Enabled,"Enabled But Not For Current User";
        CDSIntegrationEnabledState: Option " ","Not Enabled",Enabled,"Enabled But Not For Current User";
        NotEnabledForCurrentUserMsg: Label '%3 Integration is enabled.\However, because the %2 Users Must Map to %4 Users field is set, %3 integration is not enabled for %1.', Comment = '%1 = Current User Id %2 - product name, %3 = CRM product name, %4 = Dataverse service name';
        CRMIntegrationEnabledLastError: Text;
        ImportSolutionConnectStringTok: Label '%1api%2/XRMServices/2011/Organization.svc', Locked = true;
        UserDoesNotExistCRMErr: Label 'There is no user with email address %1 in %2. Enter a valid email address.', Comment = '%1 = User email address, %2 = Dataverse service name';
        EmailAndServerAddressEmptyErr: Label 'The Integration User Email and Server Address fields must not be empty.';
        CRMSolutionFileNotFoundErr: Label 'A file for a CRM solution could not be found.';
        MicrosoftDynamicsNavIntegrationTxt: Label 'MicrosoftDynamicsNavIntegration', Locked = true;
        AdminEmailPasswordWrongErr: Label 'Enter valid %1 administrator credentials.', Comment = '%1 = CRM product name';
        OrganizationServiceFailureErr: Label 'The import of the integration solution failed. This may be because the solution file is broken, or because the solution upgrade failed or because the specified administrator does not have sufficient privileges. If you have upgraded to Business Central 16, follow this document to upgrade your integration solution: https://docs.microsoft.com/en-us/dynamics365/business-central/admin-upgrade-sales-to-cds';
        InvalidUriErr: Label 'The value entered is not a valid URL.';
        MustUseHttpsErr: Label 'The application is set up to support secure connections (HTTPS) to %1 only. You cannot use HTTP.', Comment = '%1 = CRM product name';
        MustUseHttpOrHttpsErr: Label '%1 is not a valid URI scheme for %2 connections. You can only use HTTPS or HTTP as the scheme in the URL.', Comment = '%1 is a URI scheme, such as FTP, HTTP, chrome or file, %2 = CRM product name';
        ReplaceServerAddressQst: Label 'The URL is not valid. Do you want to replace it with the URL suggested below?\\Entered URL: "%1".\Suggested URL: "%2".', Comment = '%1 and %2 are URLs';
        CRMConnectionURLWrongErr: Label 'The URL is incorrect. Enter the URL for the %1 connection.', Comment = '%1 = CRM product name';
        NoOf: Option ,Scheduled,Failed,Skipped,Total;
        NotEnabledMsg: Label 'To perform this action you must be connected to %1. You can set up the connection to %1 from the %2 page.', Comment = '%1 = Dataverse service name, %2 = Assisted Setup page caption.';
        ConnectionStringFormatTok: Label 'Url=%1; UserName=%2; Password=%3; ProxyVersion=%4; %5', Locked = true;
        OAuthConnectionStringFormatTok: Label 'Url=%1; AccessToken=%2; ProxyVersion=%3; %4', Locked = true;
        CRMDisabledErrorReasonNotificationIdTxt: Label 'd82835d9-a005-451a-972b-0d6532de2072';
        ConnectionBrokenMsg: Label 'The connection to Dynamics 365 Sales is disabled due to the following error: %1.\\Please contact your system administrator.', Comment = '%1 = Error text received from D365 for Sales';
        ConnectionDisabledNotificationMsg: Label 'Connection to Dynamics 365 is broken and that it has been disabled due to an error: %1', Comment = '%1 = Error text received from D365 for Sales';
        DoYouWantEnableWebServiceQst: Label 'Do you want to enable the Item Availability web service?';
        DoYouWantDisableWebServiceQst: Label 'Do you want to disable the Item Availability web service?';
        CRMConnectionSetupTitleTxt: Label 'Set up a connection to %1', Comment = '%1 = CRM product name';
        CRMConnectionSetupShortTitleTxt: Label 'Connect to %1', Comment = '%1 = CRM product name';
        CRMConnectionSetupDescriptionTxt: Label 'Connect your Dynamics 365 services for better insights. Data is exchanged between the apps for better productivity.';
        VideoUrlSetupCRMConnectionTxt: Label '', Locked = true;
        ConnectionDisabledReasonTxt: Label 'The connection to %1 was disabled because integration user %2 has insufficient privileges to run the synchronization.', Comment = '%1 = a URL, %2 - an email address';
        CannotAssignRoleToTeamErr: Label 'Cannot assign role %3 to team %1 for business unit %2.', Comment = '%1 = team name, %2 = business unit name, %3 = security role name';
        CannotAssignRoleToTeamTxt: Label 'Cannot assign role to team.', Locked = true;
        IntegrationRoleNotFoundErr: Label 'There is no integration role %1 for business unit %2.', Comment = '%1 = role name, %2 = business unit name';
        RoleNotFoundForBusinessUnitTxt: Label 'Integration role is not found for business unit.', Locked = true;
        CategoryTok: Label 'AL Dataverse Integration', Locked = true;
        TimeoutTxt: Label 'timeout', Locked = true;
        RetryAfterTimeoutErr: Label 'The operation timed out. Try again.\\%1', Comment = '%1 - exception message ';
        ConnectionFailureTxt: Label 'Connection failure.', Locked = true;
        DisableIntegrationTxt: Label 'Disable integration.', Locked = true;
        ClearDisabledReasonTxt: Label 'Clear disabled reason.', Locked = true;
        IntegrationDisabledTxt: Label 'Integration is disabled.', Locked = true;
        IntegrationNotConfiguredTxt: Label 'Integration is not configured.', Locked = true;
        NoPermissionsTxt: Label 'No permissions.', Locked = true;
        NotLocalTableTxt: Label 'Table %1 is not local.', Locked = true;
        UpdateConflictHandledFromIntTxt: Label 'Update conflict handled by getting update from Dynamics 365 Sales.', Locked = true;
        UpdateConflictHandledToIntTxt: Label 'Update conflict handled by sending update to Dynamics 365 Sales.', Locked = true;
        UpdateConflictHandledSkipTxt: Label 'Update conflict handled by skipping the updated record.', Locked = true;
        DeletionConflictHandledRemoveCouplingTxt: Label 'Deletion conflict handled by removing the coupling to the deleted record.', Locked = true;
        DeletionConflictHandledRestoreRecordTxt: Label 'Deletion conflict handled by restoring the deleted record.', Locked = true;
        ResetAllCustomIntegrationTableMappingsLbl: Label 'One or more of the selected integration table mappings is custom.\\Restoring the default table mapping for a custom table mapping will restore all custom table mappings to their default.\\Do you want to continue?';
        OptionMappingFailedNotificationTxt: Label 'There was a problem synchronizing %1 with Dataverse. This is probably because one or more option mappings are missing.', Comment = '%1 = Failed option fields';
        OptionMappingDocumentantionUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2139110';
        LearnMoreTxt: Label 'Learn more';
        DeletedRecordWithZeroTableIdTxt: Label 'CRM Integration Record with zero Table ID has been deleted. Integration ID: %1, CRM ID: %2', Locked = true;
        RecordMarkedAsSkippedTxt: Label 'The %1 record was marked as skipped before.', Comment = '%1 = table caption';
        RecordAlreadyCoupledTxt: Label 'The %1 record is already coupled.', Comment = '%1 = table caption';
        DetailedNotificationMessageTxt: Label '%1 %2', Comment = '%1 - notification message, %2 - details', Locked = true;
        BrokenCouplingsFoundAndMarkedAsSkippedForMappingTxt: Label 'Broken couplings were found and marked as skipped. Mapping: %1 - %2. Direction: %3. Count: %4.', Locked = true;
        BrokenCouplingsFoundAndMarkedAsSkippedTotalTxt: Label 'Broken couplings were found and marked as skipped. Total count: %1.', Locked = true;
        NoBrokenCouplingsFoundTxt: Label 'No broken couplings were found.', Locked = true;

    procedure IsCRMIntegrationEnabled(): Boolean
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if not CRMConnectionSetup.ReadPermission() then
            exit(false);

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

    [Scope('OnPrem')]
    procedure IsIntegrationEnabled(): Boolean
    var
        CRMConnectionSentup: Record "CRM Connection Setup";
    begin
        if not CRMConnectionSentup.ReadPermission() then
            exit(false);

        if not CRMConnectionSentup.Get() then
            exit(false);

        if not CRMConnectionSentup."Is Enabled" then
            exit(false);

        exit(true);
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
        Cnt: Integer;
    begin
        Cnt := CRMAccountStatistics.Count();
        Cnt := CRMNAVConnection.Count();
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

    [Obsolete('This procedure will be removed.', '18.0')]
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
        SkipReason: Text;
    begin
        RecordCounter[NoOf::Total] := GetRecordRef(RecVariant, RecRef);
        if RecordCounter[NoOf::Total] = 0 then
            exit;

        if RecRef.Number = DATABASE::"CRM Integration Record" then
            ShouldSendNotification := UpdateCRMIntRecords(RecRef, RecordCounter)
        else
            ShouldSendNotification := UpdateRecords(RecRef, RecordCounter, SkipReason);
        if ShouldSendNotification then
            SendSyncNotification(RecordCounter, SkipReason);
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
        if SelectedDirection < 0 then
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
                CRMIntegrationRecord.GetBySystemId(CRMIntegrationRecord.SystemId);
                CRMIntegrationRecord.Skipped := false;
                CRMIntegrationRecord.Modify();
                RecordCounter[NoOf::Scheduled] += 1;
            end else
                RecordCounter[NoOf::Failed] += 1;
        until RecRef.Next() = 0;
        exit(true);
    end;

    local procedure UpdateRecords(var RecRef: RecordRef; var RecordCounter: array[4] of Integer; var SkipReason: Text): Boolean
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        SelectedDirection: Integer;
        CRMID: Guid;
        Unused: Boolean;
        Skipped: Boolean;
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
        if SelectedDirection < 0 then
            exit(false); // The user cancelled

        repeat
            Skipped := false;
            if RecordCounter[NoOf::Total] > 1 then begin
                Skipped := not GetCoupledCRMID(RecRef.RecordId, CRMID);
                if not Skipped then
                    Skipped := WasRecordModifiedAfterLastSynch(IntegrationTableMapping, RecRef, CRMID, SelectedDirection);
            end;
            if not Skipped then
                Skipped := IsRecordSkipped(RecRef.RecordId);
            if Skipped then begin
                RecordCounter[NoOf::Skipped] += 1;
                SkipReason := StrSubstNo(RecordMarkedAsSkippedTxt, GetTableCaption(RecRef.Number()));
            end else
                if EnqueueSyncJob(IntegrationTableMapping, RecRef.RecordId, CRMID, SelectedDirection) then
                    RecordCounter[NoOf::Scheduled] += 1
                else
                    RecordCounter[NoOf::Failed] += 1;
        until RecRef.Next() = 0;
        if (SkipReason <> '') and (RecordCounter[NoOf::Total] > 1) then
            SkipReason := '';
        exit(true);
    end;

    procedure UpdateOneNow(RecordID: RecordID)
    begin
        // Extinct method. Kept for backward compatibility.
        UpdateMultipleNow(RecordID)
    end;

    procedure UpdateSkippedNow(var CRMIntegrationRecord: Record "CRM Integration Record")
    begin
        UpdateSkippedNow(CRMIntegrationRecord, false);
    end;

    [Scope('OnPrem')]
    procedure UpdateSkippedNow(var CRMIntegrationRecord: Record "CRM Integration Record"; SkipNotification: Boolean)
    var
        RecId: RecordId;
        RestoredRecCounter: Integer;
    begin
        if CRMIntegrationRecord.FindSet then
            repeat
                if CRMIntegrationRecord.Skipped then
                    if CRMIntegrationRecord.FindRecordId(RecId) then begin
                        CRMIntegrationRecord.Skipped := false;
                        CRMIntegrationRecord.Modify();
                        RestoredRecCounter += 1;
                    end;
            until CRMIntegrationRecord.Next() = 0;
        if not SkipNotification then
            SendRestoredSyncNotification(RestoredRecCounter);
    end;

    [Scope('OnPrem')]
    procedure UpdateAllSkippedNow()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RestoredRecCounter: Integer;
    begin
        CRMIntegrationRecord.SetRange(Skipped, true);
        RestoredRecCounter := CRMIntegrationRecord.Count();
        if RestoredRecCounter > 0 then
            CRMIntegrationRecord.ModifyAll(Skipped, false);
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
    var
        AssistedSetup: Page "Assisted Setup";
    begin
        if IsCDSIntegrationEnabled() then
            exit;

        if IsCRMIntegrationEnabled() then
            exit;

        if CRMIntegrationEnabledLastError <> '' then
            Error(CRMIntegrationEnabledLastError);

        if GuiAllowed then
            if CRMIntegrationEnabledState = CRMIntegrationEnabledState::"Enabled But Not For Current User" then
                Message(NotEnabledForCurrentUserMsg, UserId, PRODUCTNAME.Short, CRMProductName.SHORT(), CRMProductName.CDSServiceName())
            else
                Message(NotEnabledMsg, CRMProductName.CDSServiceName(), AssistedSetup.Caption());

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

#if not CLEAN18
    [Obsolete('Replaced by CreateNewRecordsInCRM', '18.0')]
    procedure CreateNewRecordInCRM(RecordID: RecordID; ConfirmBeforeDeletingExistingCoupling: Boolean)
    begin
        // Extinct method. Kept for backward compatibility.
        ConfirmBeforeDeletingExistingCoupling := false;
        CreateNewRecordsInCRM(RecordID);
    end;
#endif

    procedure CreateNewRecordsInCRM(RecVariant: Variant)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        RecRef: RecordRef;
        CRMID: Guid;
        RecordCounter: array[4] of Integer;
        SkipReason: Text;
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
        until RecRef.Next() = 0;

        if (RecordCounter[NoOf::Total] = 1) and (RecordCounter[NoOf::Skipped] = 1) then
            SkipReason := StrSubstNo(RecordAlreadyCoupledTxt, GetTableCaption(IntegrationTableMapping."Table ID"));
        SendSyncNotification(RecordCounter, SkipReason);
    end;

    procedure CreateNewRecordsFromCRM(RecVariant: Variant)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecRef: RecordRef;
        CRMID: Guid;
        RecordCounter: array[4] of Integer;
        SkipReason: Text;
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
        until RecRef.Next() = 0;

        if (RecordCounter[NoOf::Total] = 1) and (RecordCounter[NoOf::Skipped] = 1) then
            SkipReason := StrSubstNo(RecordAlreadyCoupledTxt, GetTableCaption(IntegrationTableMapping."Integration Table ID"));
        SendSyncNotification(RecordCounter, SkipReason);
    end;

    [Scope('OnPrem')]
    procedure CreateNewRecordsFromSelectedCRMRecords(RecVariant: Variant)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        RecRef: RecordRef;
        CRMID: Guid;
        RecordCounter: array[4] of Integer;
        CRMIdFilter: Text;
        SkipReason: Text;
    begin
        RecordCounter[NoOf::Total] := GetRecordRef(RecVariant, RecRef);
        if RecordCounter[NoOf::Total] = 0 then
            exit;

        CRMIdFilter := '';
        repeat
            GetIntegrationTableMappingFromCRMRecord(IntegrationTableMapping, RecRef);
            CRMID := RecRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.").Value;
            if CRMIntegrationRecord.FindValidByCRMID(CRMID) then
                RecordCounter[NoOf::Skipped] += 1
            else begin
                if not IsNullGuid(CRMIntegrationRecord."CRM ID") then // found the corrupt coupling
                    CRMIntegrationRecord.Delete();
                CRMIdFilter += CRMID + '|';
                RecordCounter[NoOf::Scheduled] += 1;
            end;
        until RecRef.Next() = 0;
        CRMIdFilter := CRMIdFilter.TrimEnd('|');
        if CRMIdFilter = '' then begin
            SkipReason := StrSubstNo(RecordAlreadyCoupledTxt, GetTableCaption(IntegrationTableMapping."Integration Table ID"));
            SendNotification(StrSubstNo(DetailedNotificationMessageTxt, SyncNowSkippedMsg, SkipReason));
            exit;
        end;
        IntegrationTableMapping.SetIntegrationTableFilter(GetTableViewForFilter(IntegrationTableMapping."Integration Table ID", CRMIdFilter));
        IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::FromIntegrationTable;
        AddIntegrationTableMapping(IntegrationTableMapping);
        Commit();
        CRMSetupDefaults.CreateJobQueueEntry(IntegrationTableMapping);
        SendSyncNotification(RecordCounter, SkipReason);
    end;

    [Obsolete('This method is identical to CreateNewRecordsFromSelectedCRMRecords', '17.0')]
    procedure CreateNewSystemUsersFromCRM(RecVariant: Variant)
    begin
        CreateNewRecordsFromSelectedCRMRecords(RecVariant);
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

    internal procedure MarkLocalDeletedAsSkipped()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        TableFilter: Text;
        Count: Integer;
        TotalCount: Integer;
    begin
        IntegrationTableMapping.SetFilter(Direction, '<>%1', IntegrationTableMapping.Direction::Bidirectional);
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        if not IntegrationTableMapping.FindSet() then
            exit;

        repeat
            Count := 0;
            TableFilter := IntegrationTableMapping.GetTableFilter();
            CRMIntegrationRecord.SetRange("Table ID", IntegrationTableMapping."Table ID");
            CRMIntegrationRecord.SetRange(Skipped, false);
            if CRMIntegrationRecord.FindSet() then
                repeat
                    RecordRef.Open(IntegrationTableMapping."Table ID");
                    RecordRef.SetView(TableFilter);
                    FieldRef := RecordRef.Field(RecordRef.SystemIdNo());
                    FieldRef.SetRange(CRMIntegrationRecord."Integration ID");
                    if RecordRef.IsEmpty() then begin
                        CRMIntegrationRecord.Skipped := true;
                        CRMIntegrationRecord.Modify();
                        Count += 1;
                    end;
                    RecordRef.Close();
                until CRMIntegrationRecord.Next() = 0;
            TotalCount += Count;
            if Count > 0 then
                Session.LogMessage('0000F26', StrSubstNo(BrokenCouplingsFoundAndMarkedAsSkippedForMappingTxt,
                    GetTableCaption(IntegrationTableMapping."Table ID"), GetTableCaption(IntegrationTableMapping."Integration Table ID"), IntegrationTableMapping.Direction, Count),
                    Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
        until IntegrationTableMapping.Next() = 0;
        if TotalCount > 0 then
            Session.LogMessage('0000F27', StrSubstNo(BrokenCouplingsFoundAndMarkedAsSkippedTotalTxt, TotalCount), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok)
        else
            Session.LogMessage('0000F28', NoBrokenCouplingsFoundTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
    end;

    [Scope('OnPrem')]
    procedure RepairBrokenCouplings()
    begin
        RepairBrokenCouplings(false);
    end;

    [Scope('OnPrem')]
    procedure RepairBrokenCouplings(UseLocalRecordsOnly: Boolean)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        BlankGuid: Guid;
    begin
        CRMIntegrationRecord.SetRange("Table ID", 0);
        CRMIntegrationRecord.SetFilter("Integration ID", '<>%1', BlankGuid);
        if CRMIntegrationRecord.FindSet() then
            repeat
                if not CRMIntegrationRecord.RepairTableIdByLocalRecord() then
                    if not UseLocalRecordsOnly then
                        if not CRMIntegrationRecord.RepairTableIdByCRMRecord() then begin
                            CRMIntegrationRecord.Delete();
                            Session.LogMessage('0000DQD', StrSubstNo(DeletedRecordWithZeroTableIdTxt, CRMIntegrationRecord."Integration ID", CRMIntegrationRecord."CRM ID"), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                        end;
            until CRMIntegrationRecord.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure RemoveCoupling(TableID: Integer; CRMTableID: Integer)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        if GetIntegrationTableMappingForUncoupling(IntegrationTableMapping, TableID, CRMTableID) then
            ScheduleUncoupling(IntegrationTableMapping, '', '')
        else begin
            RepairBrokenCouplings();
            CRMIntegrationRecord.SetRange("Table ID", TableID);
            CRMIntegrationRecord.DeleteAll();
        end;
    end;

    [Scope('OnPrem')]
    procedure RemoveCoupling(var LocalRecordRef: RecordRef)
    begin
        RemoveCoupling(LocalRecordRef, true);
    end;

    [Scope('OnPrem')]
    procedure RemoveCoupling(LocalTableID: Integer; var LocalIdList: List of [Guid])
    var
        LocalRecordRef: RecordRef;
        LocalIdFilter: Text;
    begin
        if LocalIdList.Count() = 0 then
            exit;
        LocalIdFilter := Join(LocalIdList, '|');
        LocalRecordRef.Open(LocalTableId);
        LocalRecordRef.Field(LocalRecordRef.SystemIdNo()).SetFilter(LocalIdFilter);
        RemoveCoupling(LocalRecordRef);
    end;

    [Scope('OnPrem')]
    procedure RemoveCoupling(LocalTableID: Integer; IntegrationTableID: Integer; var IntegrationIdList: List of [Guid])
    begin
        RemoveCoupling(LocalTableID, IntegrationTableID, IntegrationIdList, true);
    end;

    internal procedure RemoveCoupling(var LocalRecordRef: RecordRef; Schedule: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        if IsCRMTable(LocalRecordRef.Number()) then begin
            Session.LogMessage('0000DHU', StrSubstNo(NotLocalTableTxt, GetTableCaption(LocalRecordRef.Number())), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            exit;
        end;

        if GetIntegrationTableMappingForUncoupling(IntegrationTableMapping, LocalRecordRef.Number()) then
            if Schedule then
                ScheduleUncoupling(IntegrationTableMapping, GetTableViewForLocalRecords(LocalRecordRef), '')
            else
                PerformUncoupling(IntegrationTableMapping, GetTableViewForLocalRecords(LocalRecordRef), '')
        else
            RemoveCouplingToRecord(LocalRecordRef);
    end;

    internal procedure RemoveCoupling(LocalTableID: Integer; IntegrationTableID: Integer; var IntegrationIdList: List of [Guid]; Schedule: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationIdFilter: Text;
    begin
        if IntegrationIdList.Count() = 0 then
            exit;
        if GetIntegrationTableMappingForUncoupling(IntegrationTableMapping, LocalTableID) then begin
            IntegrationIdFilter := Join(IntegrationIdList, '|');
            if Schedule then
                ScheduleUncoupling(IntegrationTableMapping, '', GetTableViewForIntegrationRecords(IntegrationTableID, IntegrationIdFilter))
            else
                PerformUncoupling(IntegrationTableMapping, '', GetTableViewForIntegrationRecords(IntegrationTableID, IntegrationIdFilter))
        end else
            RemoveCouplingToRecord(LocalTableID, IntegrationIdList);
    end;

    local procedure RemoveCouplingToRecord(var LocalRecordRef: RecordRef)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if LocalRecordRef.FindSet() then
            repeat
                CRMIntegrationRecord.RemoveCouplingToRecord(LocalRecordRef.RecordId());
            until LocalRecordRef.Next() = 0;
    end;

    local procedure RemoveCouplingToRecord(LocalTableID: Integer; var CRMIDList: List of [Guid])
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMID: Guid;
    begin
        foreach CRMID in CRMIDList do
            CRMIntegrationRecord.RemoveCouplingToCRMID(CRMID, LocalTableID);
    end;

    [Scope('OnPrem')]
    procedure RemoveCoupling(RecordID: RecordID)
    begin
        RemoveCoupling(RecordID, true);
    end;

    internal procedure RemoveCoupling(RecordID: RecordID; Schedule: Boolean): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        if IsCRMTable(RecordID.TableNo()) then begin
            Session.LogMessage('0000DHV', StrSubstNo(NotLocalTableTxt, GetTableCaption(RecordID.TableNo())), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            exit(false);
        end;

        if not GetIntegrationTableMappingForUncoupling(IntegrationTableMapping, RecordID.TableNo()) then
            exit(CRMIntegrationRecord.RemoveCouplingToRecord(RecordID));

        if Schedule then
            exit(ScheduleUncoupling(IntegrationTableMapping, GetTableViewForRecordID(RecordID), ''));

        exit(PerformUncoupling(IntegrationTableMapping, GetTableViewForRecordID(RecordID), ''));
    end;

    [Scope('OnPrem')]
    procedure RemoveCoupling(TableID: Integer; CRMTableID: Integer; CRMID: Guid)
    begin
        RemoveCoupling(TableID, CRMTableID, CRMID, true);
    end;

    internal procedure RemoveCoupling(TableID: Integer; CRMTableID: Integer; CRMID: Guid; Schedule: Boolean): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        if not GetIntegrationTableMappingForUncoupling(IntegrationTableMapping, TableID, CRMTableID) then
            exit(CRMIntegrationRecord.RemoveCouplingToCRMID(CRMID, TableID));

        if Schedule then
            exit(ScheduleUncoupling(IntegrationTableMapping, '', GetTableViewForGuid(CRMTableID, CRMID)));

        exit(PerformUncoupling(IntegrationTableMapping, '', GetTableViewForGuid(CRMTableID, CRMID)));
    end;

    local procedure ScheduleUncoupling(var IntegrationTableMapping: Record "Integration Table Mapping"; LocalTableFilter: Text; IntegrationTableFilter: Text): Boolean
    var
        RecordCounter: array[4] of Integer;
        Scheduled: Boolean;
    begin
        RecordCounter[NoOf::Total] := 1;
        Scheduled := EnqueueUncoupleJob(IntegrationTableMapping, LocalTableFilter, IntegrationTableFilter);
        if Scheduled then
            RecordCounter[NoOf::Scheduled] += 1
        else
            RecordCounter[NoOf::Failed] += 1;
        SendUncoupleNotification(RecordCounter);
        exit(Scheduled);
    end;

    local procedure PerformUncoupling(IntegrationTableMapping: Record "Integration Table Mapping"; LocalTableFilter: Text; IntegrationTableFilter: Text): Boolean
    var
        IntRecUncoupleInvoke: Codeunit "Int. Rec. Uncouple Invoke";
        LocalRecordRef: RecordRef;
        IntegrationRecordRef: RecordRef;
        SynchAction: Option "None",Insert,Modify,ForceModify,IgnoreUnchanged,Fail,Skip,Delete,Uncouple;
        LocalRecordModified: Boolean;
        IntegrationRecordModified: Boolean;
        JobId: Guid;
    begin
        AddIntegrationTableMapping(IntegrationTableMapping);
        IntegrationTableMapping.SetTableFilter(LocalTableFilter);
        IntegrationTableMapping.SetIntegrationTableFilter(IntegrationTableFilter);
        if LocalTableFilter <> '' then begin
            LocalRecordRef.Open(IntegrationTableMapping."Table ID");
            LocalRecordRef.SetView(LocalTableFilter);
            if not LocalRecordRef.FindFirst() then
                exit(false);
        end else begin
            IntegrationRecordRef.Open(IntegrationTableMapping."Integration Table ID");
            IntegrationRecordRef.SetView(IntegrationTableFilter);
            if not IntegrationRecordRef.FindFirst() then
                exit(false);
        end;
        SynchAction := SynchAction::Uncouple;
        IntRecUncoupleInvoke.SetContext(IntegrationTableMapping, LocalRecordRef, IntegrationRecordRef, SynchAction, LocalRecordModified, IntegrationRecordModified, JobId, TableConnectionType::CRM);
        IntRecUncoupleInvoke.Run();
        IntRecUncoupleInvoke.GetContext(IntegrationTableMapping, LocalRecordRef, IntegrationRecordRef, SynchAction, LocalRecordModified, IntegrationRecordModified);
        IntegrationTableMapping.Delete(true);
        exit(SynchAction <> SynchAction::Fail);
    end;

    local procedure GetIntegrationTableMappingForUncoupling(var IntegrationTableMapping: Record "Integration Table Mapping"; TableID: Integer; CRMTableID: Integer): Boolean
    begin
        IntegrationTableMapping.SetRange("Uncouple Codeunit ID", Codeunit::"CDS Int. Table Uncouple");
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        IntegrationTableMapping.SetRange("Table ID", TableID);
        IntegrationTableMapping.SetRange("Integration Table ID", CRMTableID);
        exit(IntegrationTableMapping.FindFirst());
    end;

    local procedure GetIntegrationTableMappingForUncoupling(var IntegrationTableMapping: Record "Integration Table Mapping"; TableID: Integer): Boolean
    begin
        IntegrationTableMapping.SetRange("Uncouple Codeunit ID", Codeunit::"CDS Int. Table Uncouple");
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        IntegrationTableMapping.SetRange("Table ID", TableID);
        exit(IntegrationTableMapping.FindFirst());
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

    local procedure Join(var IdList: List of [Guid]; Delimiter: Text[1]): Text
    var
        IdValue: Guid;
        IdFilter: Text;
    begin
        foreach IdValue in IdList do
            IdFilter += Delimiter + IdValue;
        IdFilter := IdFilter.TrimStart(Delimiter);
        exit(IdFilter);
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
        if Direction in [IntegrationTableMapping.Direction::Bidirectional, IntegrationTableMapping.Direction::FromIntegrationTable] then
            IntegrationTableMapping.SetIntegrationTableFilter(GetTableViewForGuid(IntegrationTableMapping."Integration Table ID", CRMID));
        if Direction in [IntegrationTableMapping.Direction::Bidirectional, IntegrationTableMapping.Direction::ToIntegrationTable] then
            IntegrationTableMapping.SetTableFilter(GetTableViewForRecordIDAndFlowFilters(IntegrationTableMapping, RecordID));
        AddIntegrationTableMapping(IntegrationTableMapping);
        Commit();
        exit(CRMSetupDefaults.CreateJobQueueEntry(IntegrationTableMapping));
    end;

    local procedure EnqueueUncoupleJob(IntegrationTableMapping: Record "Integration Table Mapping"; LocalTableFilter: Text; IntegrationTableFilter: Text): Boolean
    var
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
    begin
        IntegrationTableMapping.SetTableFilter(LocalTableFilter);
        IntegrationTableMapping.SetIntegrationTableFilter(IntegrationTableFilter);
        AddIntegrationTableMapping(IntegrationTableMapping);
        Commit();
        exit(CDSSetupDefaults.CreateUncoupleJobQueueEntry(IntegrationTableMapping));
    end;

    [Scope('OnPrem')]
    procedure AddIntegrationTableMapping(var IntegrationTableMapping: Record "Integration Table Mapping")
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
            until IntegrationFieldMapping.Next() = 0;
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

    local procedure GetTableViewForFilter(TableNo: Integer; FilterText: Text) View: Text
    var
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        RecordRef: RecordRef;
    begin
        RecordRef.Open(TableNo);
        KeyRef := RecordRef.KeyIndex(1); // Primary Key
        FieldRef := KeyRef.FieldIndex(1);
        FieldRef.SetFilter(FilterText);
        View := RecordRef.GetView();
        RecordRef.Close();
    end;

    local procedure GetTableViewForRecordID(RecordID: RecordID) View: Text
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        KeyRef: KeyRef;
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

    local procedure GetTableViewForRecordIDAndFlowFilters(IntegrationTableMapping: Record "Integration Table Mapping"; RecordID: RecordID) View: Text
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        I: Integer;
        Pos: Integer;
        StartPos: Integer;
        EndPos: Integer;
        MappingTableFilter: Text;
        CurrentFieldFilter: Text;
    begin
        RecordRef := RecordID.GetRecord();
        KeyRef := RecordRef.KeyIndex(1); // Primary Key
        for I := 1 to KeyRef.FieldCount() do begin
            FieldRef := KeyRef.FieldIndex(I);
            FieldRef.SetRange(FieldRef.Value);
        end;
        MappingTableFilter := IntegrationTableMapping.GetTableFilter();
        for I := 1 to RecordRef.FieldCount() do begin
            FieldRef := RecordRef.FieldIndex(I);
            if FieldRef.Class = FieldClass::FlowFilter then begin
                Pos := StrPos(MappingTableFilter, 'Field' + Format(FieldRef.Number()) + '=');
                if Pos <> 0 then begin
                    CurrentFieldFilter := CopyStr(MappingTableFilter, Pos);
                    StartPos := StrPos(CurrentFieldFilter, '(');
                    EndPos := StrPos(CurrentFieldFilter, ')');
                    FieldRef.SetFilter(CopyStr(CurrentFieldFilter, StartPos, EndPos - StartPos + 1));
                end;
            end;
        end;
        View := RecordRef.GetView();
        RecordRef.Close();
    end;

    local procedure GetTableViewForLocalRecords(var RecRef: RecordRef) View: Text
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        IdFieldNo: Integer;
        IdFieldValue: Guid;
        TableNo: Integer;
        FilterText: Text;
    begin
        if not RecRef.FindSet() then
            exit;

        TableNo := RecRef.Number();
        IdFieldNo := RecRef.SystemIdNo();

        repeat
            IdFieldValue := RecRef.Field(IdFieldNo).Value();
            FilterText += '|' + IdFieldValue;
        until RecRef.Next() = 0;

        FilterText := FilterText.TrimStart('|');
        if FilterText = '' then
            exit;

        RecordRef.Open(TableNo);
        FieldRef := RecordRef.Field(IdFieldNo);
        FieldRef.SetFilter(FilterText);
        View := RecordRef.GetView();
        RecordRef.Close();
    end;

    local procedure GetTableViewForIntegrationRecords(TableNo: Integer; IdFieldFilter: Text) View: Text
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        IdFieldNo: Integer;
    begin
        if IdFieldFilter = '' then
            exit;

        RecordRef.Open(TableNo);
        IdFieldNo := RecordRef.KeyIndex(1).FieldIndex(1).Number();
        FieldRef := RecordRef.Field(IdFieldNo);
        FieldRef.SetFilter(IdFieldFilter);
        View := RecordRef.GetView();
        RecordRef.Close();
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
        Message(StrSubstNo(AccountStatisticsUpdatedMsg, CRMProductName.CDSServiceName()));
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
            Error(CouplingNotFoundErr, CRMProductName.CDSServiceName());

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
        Error(UnableToResolveCRMEntityNameFrmTableIDErr, TableId, CRMProductName.CDSServiceName());
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
        if Confirm(StrSubstNo(ManageCouplingQst, RecordRef.Caption, CRMProductName.CDSServiceName()), false) then
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

    procedure CreateNewVendorFromCRM()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        GetIntegrationTableMapping(IntegrationTableMapping, DATABASE::Vendor);
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

    [Scope('OnPrem')]
    procedure ResetIntTableMappingDefaultConfiguration(var IntegrationTableMapping: Record "Integration Table Mapping")
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSSetupDefaults: Codeunit "CDS Setup Defaults";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        EnqueueJobQueEntries: Boolean;
        IsTeamOwnershipModel: Boolean;
        IsHandled: Boolean;
    begin
        Codeunit.Run(Codeunit::"CRM Integration Management");

        if CRMConnectionSetup.Get() then
            EnqueueJobQueEntries := CRMConnectionSetup.DoReadCRMData and CRMConnectionSetup.IsEnabled;

        IsTeamOwnershipModel := CDSIntegrationMgt.IsTeamOwnershipModelSelected();

        if IntegrationTableMapping.FindSet() then
            repeat
                case IntegrationTableMapping."Table ID" of
                    Database::"Salesperson/Purchaser":
                        CDSSetupDefaults.ResetSalesPeopleSystemUserMapping(IntegrationTableMapping.Name, IsTeamOwnershipModel, true);
                    Database::Customer:
                        CDSSetupDefaults.ResetCustomerAccountMapping(IntegrationTableMapping.Name, IsTeamOwnershipModel, true);
                    Database::Vendor:
                        CDSSetupDefaults.ResetVendorAccountMapping(IntegrationTableMapping.Name, IsTeamOwnershipModel, true);
                    Database::Contact:
                        CDSSetupDefaults.ResetContactContactMapping(IntegrationTableMapping.Name, IsTeamOwnershipModel, true);
                    Database::Currency:
                        CDSSetupDefaults.ResetCurrencyTransactionCurrencyMapping(IntegrationTableMapping.Name, true);
                    Database::"Payment Terms":
                        CDSSetupDefaults.ResetPaymentTermsMapping(IntegrationTableMapping.Name);
                    Database::"Shipment Method":
                        CDSSetupDefaults.ResetShipmentMethodMapping(IntegrationTableMapping.Name);
                    Database::"Shipping Agent":
                        CDSSetupDefaults.ResetShippingAgentMapping(IntegrationTableMapping.Name);
                    Database::"Unit of Measure":
                        CRMSetupDefaults.ResetUnitOfMeasureUoMScheduleMapping(IntegrationTableMapping.Name, EnqueueJobQueEntries);
                    Database::Item:
                        CRMSetupDefaults.ResetItemProductMapping(IntegrationTableMapping.Name, EnqueueJobQueEntries);
                    Database::Resource:
                        CRMSetupDefaults.ResetResourceProductMapping(IntegrationTableMapping.Name, EnqueueJobQueEntries);
                    Database::"Customer Price Group":
                        CRMSetupDefaults.ResetCustomerPriceGroupPricelevelMapping(IntegrationTableMapping.Name, EnqueueJobQueEntries);
                    Database::"Sales Invoice Header":
                        CRMSetupDefaults.ResetSalesInvoiceHeaderInvoiceMapping(IntegrationTableMapping.Name, IsTeamOwnershipModel, EnqueueJobQueEntries);
                    Database::"Sales Invoice Line":
                        CRMSetupDefaults.ResetSalesInvoiceLineInvoiceMapping(IntegrationTableMapping.Name);
                    Database::Opportunity:
                        CRMSetupDefaults.ResetOpportunityMapping(IntegrationTableMapping.Name, IsTeamOwnershipModel);
                    Database::"Sales Header":
                        begin
                            CRMSetupDefaults.ResetSalesOrderMapping(IntegrationTableMapping.Name, IsTeamOwnershipModel, EnqueueJobQueEntries);
                            CRMSetupDefaults.RecreateSalesOrderStatusJobQueueEntry(EnqueueJobQueEntries);
                            CRMSetupDefaults.RecreateSalesOrderNotesJobQueueEntry(EnqueueJobQueEntries);
                        end;
                    else begin
                            OnBeforeHandleCustomIntegrationTableMapping(IsHandled, IntegrationTableMapping.Name);
                            if not IsHandled then begin
                                if Confirm(ResetAllCustomIntegrationTableMappingsLbl) then begin
                                    if CDSConnectionSetup.Get() then
                                        CDSSetupDefaults.SetCustomIntegrationsTableMappings(CDSConnectionSetup);
                                    if CRMConnectionSetup.Get() then
                                        CRMSetupDefaults.SetCustomIntegrationsTableMappings(CRMConnectionSetup);
                                end;
                                IsHandled := true;
                            end;
                        end;
                end;
            until IntegrationTableMapping.Next() = 0;
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
        SelectedDirection: Integer;
    begin
        AllowedDirection := IntegrationTableMapping.Direction;
        RecommendedDirection := AllowedDirection;
        case AllowedDirection of
            IntegrationTableMapping.Direction::Bidirectional:
                begin
                    SelectedDirection := StrMenu(UpdateNowUniDirectionQst, RecommendedDirection, UpdateMultipleNowTitleTxt);
                    if SelectedDirection = 0 then
                        SelectedDirection := -1;
                    exit(SelectedDirection);
                end;
            IntegrationTableMapping.Direction::FromIntegrationTable:
                SynchronizeNowQuestion := StrSubstNo(UpdateMultipleNowFromCRMQst, CRMProductName.CDSServiceName());
            else
                SynchronizeNowQuestion := StrSubstNo(UpdateMultipleNowToCRMQst, CRMProductName.CDSServiceName());
        end;

        if Confirm(SynchronizeNowQuestion, true) then
            exit(AllowedDirection);
        exit(-1); // user canceled the process
    end;

    local procedure GetSelectedSingleSyncDirection(IntegrationTableMapping: Record "Integration Table Mapping"; RecordRef: RecordRef; CRMID: Guid; var RecommendedDirectionIgnored: Boolean): Integer
    var
        IntegrationRecSynchInvoke: Codeunit "Integration Rec. Synch. Invoke";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        CRMRecordRef: RecordRef;
        RecordIDDescr: Text;
        SynchronizeNowQuestion: Text;
        AllowedDirection: Integer;
        RecommendedDirection: Integer;
        SelectedDirection: Integer;
        RecordModified: Boolean;
        CRMRecordModified: Boolean;
        BothModified: Boolean;
        DefaultAnswer: Boolean;
        FieldsModified: Boolean;
        BidirectionalFieldsModified: Boolean;
    begin
        AllowedDirection := IntegrationTableMapping.Direction;

        // Determine which sides were modified since last synch
        IntegrationTableMapping.GetRecordRef(CRMID, CRMRecordRef);
        RecordModified := IntegrationRecSynchInvoke.WasModifiedAfterLastSynch(IntegrationTableMapping, RecordRef);
        CRMRecordModified := IntegrationRecSynchInvoke.WasModifiedAfterLastSynch(IntegrationTableMapping, CRMRecordRef);
        BothModified := RecordModified and CRMRecordModified;
        RecordIDDescr := Format(RecordRef.RecordId, 0, 1);
        if BothModified then
            // Changes on both sides. Bidirectional: warn user. Unidirectional: confirm and exit.
            case AllowedDirection of
                IntegrationTableMapping.Direction::Bidirectional:
                    begin
                        IntegrationTableSynch.CheckTransferFields(IntegrationTableMapping, RecordRef, CRMRecordRef, FieldsModified, BidirectionalFieldsModified);
                        if BidirectionalFieldsModified then
                            Message(BothRecordsModifiedBiDirectionalConflictMsg, RecordRef.Caption, CRMRecordRef.Caption, CRMProductName.CDSServiceName())
                        else begin
                            if not FieldsModified then
                                IntegrationTableSynch.CheckTransferFields(IntegrationTableMapping, CRMRecordRef, RecordRef, FieldsModified, BidirectionalFieldsModified);
                            if FieldsModified then
                                Message(BothRecordsModifiedBiDirectionalNoConflictMsg, RecordRef.Caption, CRMRecordRef.Caption, CRMProductName.CDSServiceName());
                        end;
                    end;
                IntegrationTableMapping.Direction::ToIntegrationTable:
                    begin
                        IntegrationTableSynch.CheckTransferFields(IntegrationTableMapping, RecordRef, CRMRecordRef, FieldsModified, BidirectionalFieldsModified);
                        if not FieldsModified then
                            exit(AllowedDirection);
                        if Confirm(BothRecordsModifiedToCRMQst, false, RecordIDDescr, CRMRecordRef.Caption, PRODUCTNAME.Short, CRMProductName.CDSServiceName()) then
                            exit(AllowedDirection);
                        exit(-1);
                    end;
                IntegrationTableMapping.Direction::FromIntegrationTable:
                    begin
                        IntegrationTableSynch.CheckTransferFields(IntegrationTableMapping, CRMRecordRef, RecordRef, FieldsModified, BidirectionalFieldsModified);
                        if not FieldsModified then
                            exit(AllowedDirection);
                        if Confirm(BothRecordsModifiedToNAVQst, false, RecordIDDescr, CRMRecordRef.Caption, PRODUCTNAME.Short, CRMProductName.CDSServiceName()) then
                            exit(AllowedDirection);
                        exit(-1);
                    end;
            end;

        // Zero or one side changed. Synch for zero too because dependent objects could have changed.
        case AllowedDirection of
            IntegrationTableMapping.Direction::Bidirectional:
                begin
                    if BothModified and BidirectionalFieldsModified then begin
                        RecommendedDirection := IntegrationTableMapping.Direction::ToIntegrationTable;
                        SelectedDirection := StrMenu(UpdateNowUniDirectionQst, RecommendedDirection, StrSubstNo(UpdateOneNowTitleTxt, RecordIDDescr));
                        if SelectedDirection = 0 then
                            SelectedDirection := -1;
                    end else begin
                        if RecordModified = CRMRecordModified then
                            RecommendedDirection := IntegrationTableMapping.Direction::Bidirectional
                        else
                            if CRMRecordModified then
                                RecommendedDirection := IntegrationTableMapping.Direction::FromIntegrationTable
                            else
                                RecommendedDirection := IntegrationTableMapping.Direction::ToIntegrationTable;
                        SelectedDirection := StrMenu(UpdateNowBiDirectionQst, RecommendedDirection, StrSubstNo(UpdateOneNowTitleTxt, RecordIDDescr));
                        case SelectedDirection of
                            0:
                                SelectedDirection := -1;
                            3:
                                SelectedDirection := IntegrationTableMapping.Direction::Bidirectional;
                        end;
                    end;
                    RecommendedDirectionIgnored := SelectedDirection <> RecommendedDirection;
                    exit(SelectedDirection);
                end;
            IntegrationTableMapping.Direction::FromIntegrationTable:
                if RecordModified then
                    SynchronizeNowQuestion := StrSubstNo(UpdateOneNowFromOldCRMQst, RecordIDDescr, PRODUCTNAME.Short, CRMProductName.CDSServiceName())
                else begin
                    SynchronizeNowQuestion := StrSubstNo(UpdateOneNowFromCRMQst, RecordIDDescr, CRMProductName.CDSServiceName());
                    DefaultAnswer := true;
                end;
            else
                if CRMRecordModified then
                    SynchronizeNowQuestion := StrSubstNo(UpdateOneNowToModifiedCRMQst, RecordIDDescr, PRODUCTNAME.Short, CRMProductName.CDSServiceName())
                else begin
                    SynchronizeNowQuestion := StrSubstNo(UpdateOneNowToCRMQst, RecordIDDescr, CRMProductName.CDSServiceName());
                    DefaultAnswer := true;
                end;
        end;

        if Confirm(SynchronizeNowQuestion, DefaultAnswer) then
            exit(AllowedDirection);

        exit(-1); // user canceled the process
    end;

    local procedure DeleteIntegrationRecordByBCID(var BCRecordRef: RecordRef)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if CRMIntegrationRecord.FindByRecordID(BCRecordRef.RecordId()) then begin
            CRMIntegrationRecord.Delete();
            Commit();
        end;
    end;

    local procedure DeleteIntegrationRecordByCRMID(var CRMRecordRef: RecordRef; var IntegrationTableMapping: Record "Integration Table Mapping")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMID: Guid;
    begin
        CRMID := CRMRecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.").Value();
        if CRMIntegrationRecord.FindByCRMID(CRMID) then begin
            CRMIntegrationRecord.Delete();
            Commit();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnUpdateConflictDetected', '', false, false)]
    local procedure HandleOnUpdateConflictDetected(var IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var UpdateConflictHandled: Boolean; var SkipRecord: Boolean)
    begin
        if UpdateConflictHandled then
            exit;

        if not (IsCDSIntegrationEnabled() or IsCRMIntegrationEnabled()) then
            exit;

        case IntegrationTableMapping."Update-Conflict Resolution" of
            IntegrationTableMapping."Update-Conflict Resolution"::"Get Update from Integration":
                begin
                    UpdateConflictHandled := true;
                    if SourceRecordRef.Number() = IntegrationTableMapping."Integration Table ID" then begin
                        SkipRecord := false;
                        Session.LogMessage('0000CUC', UpdateConflictHandledFromIntTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                    end else begin
                        SkipRecord := true;
                        Session.LogMessage('0000D3O', UpdateConflictHandledSkipTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                    end;
                end;
            IntegrationTableMapping."Update-Conflict Resolution"::"Send Update to Integration":
                begin
                    UpdateConflictHandled := true;
                    if SourceRecordRef.Number() = IntegrationTableMapping."Table ID" then begin
                        SkipRecord := false;
                        Session.LogMessage('0000CUD', UpdateConflictHandledToIntTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                    end else begin
                        SkipRecord := true;
                        Session.LogMessage('0000D3P', UpdateConflictHandledSkipTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                    end;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnDeletionConflictDetected', '', false, false)]
    local procedure HandleOnDeletionConflictDetected(var IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DeletionConflictHandled: Boolean)
    var
        CRMID: Guid;
    begin
        if DeletionConflictHandled then
            exit;

        if not (IsCDSIntegrationEnabled() or IsCRMIntegrationEnabled()) then
            exit;

        case IntegrationTableMapping."Deletion-Conflict Resolution" of
            IntegrationTableMapping."Deletion-Conflict Resolution"::"Remove Coupling":
                begin
                    if SourceRecordRef.Number = IntegrationTableMapping."Table ID" then begin
                        DeletionConflictHandled := RemoveCoupling(SourceRecordRef.RecordId(), false);
                    end else begin
                        CRMID := SourceRecordRef.Field(IntegrationTableMapping."Integration Table UID Fld. No.").Value();
                        DeletionConflictHandled := RemoveCoupling(IntegrationTableMapping."Table ID", IntegrationTableMapping."Integration Table ID", CRMID, false);
                    end;

                    if DeletionConflictHandled then
                        Session.LogMessage('0000CUE', DeletionConflictHandledRemoveCouplingTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                end;
            IntegrationTableMapping."Deletion-Conflict Resolution"::"Restore Records":
                begin
                    if SourceRecordRef.Number = IntegrationTableMapping."Table ID" then
                        DeleteIntegrationRecordByBCID(SourceRecordRef)
                    else
                        DeleteIntegrationRecordByCRMID(SourceRecordRef, IntegrationTableMapping);

                    DeletionConflictHandled := true;
                    Session.LogMessage('0000CUF', DeletionConflictHandledRestoreRecordTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Connection", 'OnRegisterServiceConnection', '', false, false)]
    procedure HandleCRMRegisterServiceConnection(var ServiceConnection: Record "Service Connection")
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        RecRef: RecordRef;
    begin
        if not CRMConnectionSetup.Get then begin
            if not CRMConnectionSetup.WritePermission then begin
                Session.LogMessage('0000CLV', NoPermissionsTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                exit;
            end;
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
    [NonDebuggable]
    procedure ImportCRMSolution(ServerAddress: Text; IntegrationUserEmail: Text; AdminUserEmail: Text; AdminUserPassword: Text; AccessToken: Text; AdminADDomain: Text; ProxyVersion: Integer; ForceRedeploy: Boolean)
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
        SolutionInstalled: Boolean;
        SolutionOutdated: Boolean;
        ImportSolution: Boolean;
    begin
        CheckConnectRequiredFields(ServerAddress, IntegrationUserEmail);
        CDSConnectionSetup.Get();
        if AccessToken <> '' then
            TempConnectionString :=
                StrSubstNo(OAuthConnectionStringFormatTok, ServerAddress, AccessToken, ProxyVersion, CDSIntegrationImpl.GetAuthenticationTypeToken(CDSConnectionSetup))
        else
            if AdminADDomain <> '' then
                TempConnectionString := StrSubstNo(
                    ConnectionStringFormatTok, ServerAddress, AdminUserEmail, AdminUserPassword, ProxyVersion, CDSIntegrationImpl.GetAuthenticationTypeToken(CDSConnectionSetup, AdminADDomain))
            else
                TempConnectionString := StrSubstNo(
                    ConnectionStringFormatTok, ServerAddress, AdminUserEmail, AdminUserPassword, ProxyVersion, CDSIntegrationImpl.GetAuthenticationTypeToken(CDSConnectionSetup));

        if CDSConnectionSetup."Authentication Type" = CDSConnectionSetup."Authentication Type"::OAuth then
            TempConnectionString := CDSIntegrationImpl.ReplaceUserNamePasswordInConnectionstring(CDSConnectionSetup, AdminUserEmail, AdminUserPassword);

        if not InitializeCRMConnection(CRMHelper, TempConnectionString) then
            ProcessConnectionFailures;

        UserGUID := CRMHelper.GetUserId(IntegrationUserEmail);
        if IsNullGuid(UserGUID) then
            Error(UserDoesNotExistCRMErr, IntegrationUserEmail, CRMProductName.CDSServiceName());

        SolutionInstalled := CRMHelper.CheckSolutionPresence(MicrosoftDynamicsNavIntegrationTxt);
        if SolutionInstalled then
            SolutionOutdated := IsSolutionOutdated(TempConnectionString);

        if ForceRedeploy then
            ImportSolution := (not SolutionInstalled) or SolutionOutdated
        else
            ImportSolution := not SolutionInstalled;

        if ImportSolution then
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
                Session.LogMessage('0000BKQ', RoleNotFoundForBusinessUnitTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                Error(IntegrationRoleNotFoundErr, GetIntegrationAdminRoleID(), CDSIntegrationImpl.GetDefaultBusinessUnitName());
            end;
            if not CDSIntegrationImpl.AssignTeamRole(CrmHelper, DefaultOwningTeamGUID, CRMRole.RoleId) then begin
                Session.LogMessage('0000BKR', CannotAssignRoleToTeamTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                Error(CannotAssignRoleToTeamErr, DefaultOwningTeamGUID, CDSIntegrationImpl.GetDefaultBusinessUnitName(), CRMRole.Name);
            end;
            CRMRole.SetRange(ParentRoleId, IntegrationUserRoleGUID);
            CRMRole.SetRange(BusinessUnitId, CDSIntegrationImpl.GetCoupledBusinessUnitId());
            if not CRMRole.FindFirst() then begin
                Session.LogMessage('0000BKS', RoleNotFoundForBusinessUnitTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                Error(IntegrationRoleNotFoundErr, GetIntegrationUserRoleID(), CDSIntegrationImpl.GetDefaultBusinessUnitName());
            end;
            if not CDSIntegrationImpl.AssignTeamRole(CrmHelper, DefaultOwningTeamGUID, CRMRole.RoleId) then begin
                Session.LogMessage('0000BKT', CannotAssignRoleToTeamTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                Error(CannotAssignRoleToTeamErr, DefaultOwningTeamGUID, CDSIntegrationImpl.GetDefaultBusinessUnitName(), CRMRole.Name);
            end;
        end;
    end;

    [NonDebuggable]
    local procedure IsSolutionOutdated(TempConnectionString: Text): Boolean
    var
        CDSSolution: Record "CDS Solution";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        NavTenantSettingsHelper: DotNet NavTenantSettingsHelper;
        Version: DotNet Version;
        TempConnectionName: Text;
        SolutionOutdated: Boolean;
    begin
        TempConnectionName := CDSIntegrationImpl.GetTempConnectionName();
        if HasTableConnection(TableConnectionType::CRM, TempConnectionName) then
            UnregisterTableConnection(TableConnectionType::CRM, TempConnectionName);
        RegisterTableConnection(TableConnectionType::CRM, TempConnectionName, TempConnectionString);
        SetDefaultTableConnection(TableConnectionType::CRM, TempConnectionName, true);
        SolutionOutdated := true;
        CDSSolution.SetRange(UniqueName, MicrosoftDynamicsNavIntegrationTxt);
        if CDSSolution.FindFirst() then
            if Version.TryParse(CDSSolution.Version, Version) then
                SolutionOutdated := Version.CompareTo(NavTenantSettingsHelper.GetPlatformVersion()) < 0;
        UnregisterTableConnection(TableConnectionType::CRM, TempConnectionName);
        exit(SolutionOutdated);
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
    [NonDebuggable]
    local procedure InitializeCRMConnection(var CRMHelper: DotNet CrmHelper; ConnectionString: Text)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if ConnectionString = '' then begin
            CRMConnectionSetup.Get();
            CRMHelper := CRMHelper.CrmHelper(CRMConnectionSetup.GetConnectionStringWithCredentials());
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
        ErrorMessage: Text;
    begin
        DotNetExceptionHandler.Collect();

        if DotNetExceptionHandler.TryCastToType(GetDotNetType(FaultException)) then begin
            Session.LogMessage('0000CLW', ConnectionFailureTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            Error(AdminEmailPasswordWrongErr, CRMProductName.SHORT);
        end;
        if DotNetExceptionHandler.TryCastToType(GetDotNetType(FileNotFoundException)) then begin
            Session.LogMessage('0000CLX', ConnectionFailureTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            Error(CRMSolutionFileNotFoundErr);
        end;
        if DotNetExceptionHandler.TryCastToType(CRMHelper.OrganizationServiceFaultExceptionType) then begin
            Session.LogMessage('0000CLY', ConnectionFailureTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            Error(OrganizationServiceFailureErr)
        end;
        if DotNetExceptionHandler.TryCastToType(CRMHelper.SystemNetWebException) then begin
            Session.LogMessage('0000CLZ', ConnectionFailureTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            Error(CRMConnectionURLWrongErr, CRMProductName.SHORT);
        end;
        if DotNetExceptionHandler.CastToType(ArgumentNullException, GetDotNetType(ArgumentNullException)) then
            case ArgumentNullException.ParamName of
                'cred':
                    begin
                        Session.LogMessage('0000CM0', ConnectionFailureTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                        Error(AdminEmailPasswordWrongErr, CRMProductName.SHORT);
                    end;
                'Organization Name':
                    begin
                        Session.LogMessage('0000CM1', ConnectionFailureTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                        Error(CRMConnectionURLWrongErr, CRMProductName.SHORT);
                    end;
            end;

        ErrorMessage := DotNetExceptionHandler.GetMessage();
        if ErrorMessage <> '' then
            if ErrorMessage.ToLower().Contains(TimeoutTxt) then begin
                Session.LogMessage('0000EJ7', ConnectionFailureTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                Error(RetryAfterTimeoutErr, ErrorMessage);
            end;

        DotNetExceptionHandler.Rethrow();
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

    [Obsolete('This procedure will be removed.', '18.0')]
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
        CDSFailedOptionMapping: Record "CDS Failed Option Mapping";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        RecordRef: RecordRef;
        NotificationMessage: Text;
        FailedOptionFields: Text;
        FailureDatetime: DateTime;
        SuccessDateTime: DateTime;
    begin
        RecordRef.GetTable(RecVariant);
        if CRMIntegrationRecord.FindByRecordID(RecordRef.RecordId) then begin
            if CRMIntegrationRecord.Skipped then
                exit(SendSkippedSyncNotification(CRMIntegrationRecord."Integration ID"));

            CDSFailedOptionMapping.SetRange("CRM Integration Record Id", CRMIntegrationRecord.SystemId);
            CDSFailedOptionMapping.SetRange("Record Id", CRMIntegrationRecord."Integration ID");
            if CDSFailedOptionMapping.FindSet() then
                if IntegrationTableMapping.FindMappingForTable(CRMIntegrationRecord."Table ID") then begin
                    IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
                    repeat
                        IntegrationFieldMapping.SetRange("Field No.", CDSFailedOptionMapping."Field No.");
                        if IntegrationFieldMapping.FindFirst() then
                            if IntegrationFieldMapping.Status = IntegrationFieldMapping.Status::Enabled then
                                FailedOptionFields += RecordRef.Field(CDSFailedOptionMapping."Field No.").Name() + ', ';
                    until CDSFailedOptionMapping.Next() = 0;
                    if FailedOptionFields <> '' then begin
                        FailedOptionFields := FailedOptionFields.TrimEnd(', ');
                        SendFailedOptionMappingNotification(StrSubstNo(OptionMappingFailedNotificationTxt, FailedOptionFields));
                    end;
                end;

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

    local procedure SendFailedOptionMappingNotification(Msg: Text): Boolean
    var
        SyncNotification: Notification;
    begin
        SyncNotification.Id := GetCommonNotificationID();
        SyncNotification.Recall();
        SyncNotification.Message(Msg);
        SyncNotification.AddAction(LearnMoreTxt, Codeunit::"CRM Integration Management", 'LinkMissingOptionDoc');
        SyncNotification.Scope(NotificationScope::LocalScope);
        SyncNotification.Send();
        exit(true);
    end;

    procedure LinkMissingOptionDoc(SkippedSyncNotification: Notification)
    begin
        Hyperlink(OptionMappingDocumentantionUrlTxt);
    end;

    local procedure SendSyncNotification(RecordCounter: array[4] of Integer): Boolean
    begin
        exit(SendSyncNotification(RecordCounter, ''));
    end;

    local procedure SendSyncNotification(RecordCounter: array[4] of Integer; SkipReason: Text): Boolean
    begin
        if RecordCounter[NoOf::Total] = 1 then begin
            if RecordCounter[NoOf::Scheduled] = 1 then
                exit(SendNotification(SyncNowScheduledMsg));
            if RecordCounter[NoOf::Skipped] = 1 then
                if SkipReason = '' then
                    exit(SendNotification(SyncNowSkippedMsg))
                else
                    exit(SendNotification(StrSubstNo(DetailedNotificationMessageTxt, SyncNowSkippedMsg, SkipReason)));
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

    local procedure SendUncoupleNotification(RecordCounter: array[4] of Integer): Boolean
    begin
        if RecordCounter[NoOf::Total] = 1 then begin
            if RecordCounter[NoOf::Scheduled] = 1 then
                exit(SendNotification(UncoupleScheduledMsg));
            if RecordCounter[NoOf::Skipped] = 1 then
                exit(SendNotification(UncoupleSkippedMsg));
            exit(SendNotification(UncoupleFailedMsg));
        end;
        exit(SendMultipleUncoupleNotification(RecordCounter));
    end;

    local procedure SendMultipleUncoupleNotification(RecordCounter: array[4] of Integer): Boolean
    begin
        exit(
          SendNotification(
            StrSubstNo(
              UncoupleMultipleMsg,
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
        Notification: Notification;
    begin
        Session.LogMessage('0000CM2', ClearDisabledReasonTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
        Notification.Id := GetCRMDisabledErrorReasonNotificationId;
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
        Session.LogMessage('0000CM3', DisableIntegrationTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
        LastError := GetLastErrorText;
        LastError := CopyStr(LastError, StrPos(Format(LastError), ':') + 1, StrLen(LastError));
        Message(StrSubstNo(ConnectionBrokenMsg, LastError));
        if CRMConnectionSetup.Get then begin
            CRMConnectionSetup.Validate("Is Enabled", false);
            CRMConnectionSetup.Validate(
              "Disable Reason",
              CopyStr(LastError, 1, MaxStrLen(CRMConnectionSetup."Disable Reason")));
            CRMConnectionSetup.Modify();
            Session.LogMessage('0000CM4', IntegrationDisabledTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
        end else
            Session.LogMessage('0000CM5', IntegrationNotConfiguredTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
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

    [Scope('OnPrem')]
    procedure IsItemAvailabilityEnabled(): Boolean
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if CRMConnectionSetup.Get() then
            exit(CRMConnectionSetup."Item Availability Enabled");
    end;

    [Obsolete('This procedure will be removed.', '18.0')]
    procedure IsItemAvailabilityWebServiceEnabled(): Boolean
    var
        TenantWebService: Record "Tenant Web Service";
    begin
        if TenantWebService.Get(TenantWebService."Object Type"::Page, GetProductItemAvailabilityServiceName) then
            exit(TenantWebService.Published);
        exit(false);
    end;

    [Obsolete('This procedure will be removed.', '18.0')]
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

    [Obsolete('This procedure will be removed.', '18.0')]
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

    [Obsolete('This procedure will be removed.', '18.0')]
    procedure PublishWebService(var CRMConnectionSetup: Record "CRM Connection Setup")
    begin
        if not Confirm(DoYouWantEnableWebServiceQst) then
            exit;

        SetupItemAvailabilityService;
        CRMConnectionSetup.Validate(
          "Dynamics NAV OData URL",
          GetItemAvailabilityWebServiceURL);
        CRMConnectionSetup.Modify();
    end;

    [Obsolete('This procedure will be removed.', '18.0')]
    local procedure GetProductItemAvailabilityServiceName(): Text[250]
    begin
        exit('ProductItemAvailability');
    end;

    procedure InitializeCRMSynchStatus()
    var
        CRMSynchStatus: Record "CRM Synch Status";
    begin
        if CRMSynchStatus.IsEmpty() then begin
            CRMSynchStatus."Last Update Invoice Entry No." := 0;
            CRMSynchStatus.Insert();
        end;
    end;

    procedure HasUncoupledSelectedUsers(var SelectedCRMSystemuser: Record "CRM Systemuser"): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecordID: RecordID;
    begin
        if SelectedCRMSystemuser.FindSet() then
            repeat
                if not CRMIntegrationRecord.FindRecordIDFromID(SelectedCRMSystemuser.SystemUserId, Database::"Salesperson/Purchaser", RecordID) then
                    exit(true);
            until SelectedCRMSystemuser.Next() = 0;
        exit(false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Integration Synch. Job Errors", 'OnIsDataIntegrationEnabled', '', false, false)]
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

    [EventSubscriber(ObjectType::Table, Database::"Integration Synch. Job Errors", 'OnForceSynchronizeDataIntegration', '', false, false)]
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
        GuidedExperience: Codeunit "Guided Experience";
        GuidedExperienceType: Enum "Guided Experience Type";
        Info: ModuleInfo;
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
    begin
        NavApp.GetCurrentModuleInfo(Info);
        if not GuidedExperience.Exists(GuidedExperienceType::"Assisted Setup", ObjectType::Page, PAGE::"CRM Connection Setup Wizard") then begin
            GuidedExperience.InsertAssistedSetup(StrSubstNo(CRMConnectionSetupTitleTxt, CRMProductName.SHORT),
                StrSubstNo(CRMConnectionSetupShortTitleTxt, CRMProductName.SHORT), CRMConnectionSetupDescriptionTxt,
                10, ObjectType::Page, PAGE::"CRM Connection Setup Wizard", AssistedSetupGroup::Customize, VideoUrlSetupCRMConnectionTxt, VideoCategory::Customize, '');
        end;
    end;

    [Scope('OnPrem')]
    procedure IsCRMIntegrationRecord(TableID: Integer): Boolean
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        isIntegrationRecord: Boolean;
    begin
        // this is the new event that partners who have integration to custom entities should subscribe to
        OnIsCRMIntegrationRecord(TableID, isIntegrationRecord);
        if isIntegrationRecord then
            exit(true);

        exit(IntegrationTableMapping.FindMappingForTable(TableID));
    end;

    [Scope('OnPrem')]
    procedure GetDatabaseTableTriggerSetup(TableID: Integer; var Insert: Boolean; var Modify: Boolean; var Delete: Boolean; var Rename: Boolean)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSConnectionSetup: Record "CDS Connection Setup";
        Enabled: Boolean;
    begin
        if (Insert and Modify and Rename) then
            exit;

        if CompanyName = '' then
            exit;

        OnEnabledDatabaseTriggersSetup(TableID, Enabled);
        if not Enabled then begin
            if CDSConnectionSetup.Get() then
                if CDSConnectionSetup."Is Enabled" then
                    Enabled := IsCRMIntegrationRecord(TableID);
            if not Enabled then
                if CRMConnectionSetup.IsEnabled() then
                    Enabled := IsCRMIntegrationRecord(TableID);
        end;

        if Enabled then begin
            Insert := true;
            Modify := true;
            Rename := true;
            if not Delete then
                Delete := false;
        end;
    end;

    [Scope('OnPrem')]
    procedure OnDatabaseInsert(RecRef: RecordRef)
    begin
        ReactivateJobForTable(RecRef.Number);
    end;

    [Scope('OnPrem')]
    procedure OnDatabaseModify(RecRef: RecordRef)
    begin
        ReactivateJobForTable(RecRef.Number);
    end;

    [Scope('OnPrem')]
    procedure OnDatabaseRename(RecRef: RecordRef; XRecRef: RecordRef)
    begin
        ReactivateJobForTable(RecRef.Number);
    end;

    local procedure ReactivateJobForTable(TableNo: Integer)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSConnectionSetup: Record "CDS Connection Setup";
        JobQueueEntry: Record "Job Queue Entry";
        DataUpgradeMgt: Codeunit "Data Upgrade Mgt.";
        JobQueueDispatcher: Codeunit "Job Queue Dispatcher";
        MomentForJobToBeReady: DateTime;
        Enabled: Boolean;
    begin
        if CDSConnectionSetup.Get() then
            Enabled := CDSConnectionSetup."Is Enabled";

        if not Enabled then
            Enabled := CRMConnectionSetup.IsEnabled();

        if not Enabled then
            exit;

        if not IsCRMIntegrationRecord(TableNo) then
            exit;

        if DataUpgradeMgt.IsUpgradeInProgress() then
            exit;
        JobQueueEntry.FilterInactiveOnHoldEntries();
        JobQueueEntry.SetRange("Recurring Job", true);
        if JobQueueEntry.IsEmpty() then
            exit;
        if not UserCanRescheduleJob() then
            exit;
        JobQueueEntry.FindSet();
        repeat
            // Restart only those jobs whose time to re-execute has nearly arrived.
            // This postpones locking of the Job Queue Entries when restarting.
            // Th job will restart with half a second delay
            MomentForJobToBeReady := JobQueueDispatcher.CalcNextReadyStateMoment(JobQueueEntry);
            if CurrentDateTime > MomentForJobToBeReady then
                if DoesJobActOnTable(JobQueueEntry, TableNo) then
                    JobQueueEntry.Restart();
        until JobQueueEntry.Next() = 0;
    end;

    local procedure DoesJobActOnTable(JobQueueEntry: Record "Job Queue Entry"; TableNo: Integer): Boolean
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        RecRef: RecordRef;
    begin
        if RecRef.Get(JobQueueEntry."Record ID to Process") and
           (RecRef.Number = DATABASE::"Integration Table Mapping")
        then begin
            RecRef.SetTable(IntegrationTableMapping);
            exit(IntegrationTableMapping."Table ID" = TableNo);
        end;
    end;

    local procedure UserCanRescheduleJob(): Boolean
    begin
        if not TaskScheduler.CanCreateTask() then
            exit(false);
        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandleCustomIntegrationTableMapping(var IsHandled: Boolean; IntegrationTableMappingName: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsCRMIntegrationRecord(TableID: Integer; var isIntegrationRecord: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEnabledDatabaseTriggersSetup(TableID: Integer; var Enabled: Boolean)
    begin
    end;
}

