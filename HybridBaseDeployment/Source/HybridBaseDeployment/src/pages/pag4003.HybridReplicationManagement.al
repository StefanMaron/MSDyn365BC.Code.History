page 4003 "Intelligent Cloud Management"
{
    SourceTable = "Hybrid Replication Summary";
    Caption = 'Cloud Migration Management';
    SourceTableView = sorting("Start Time") order(descending);
    PageType = List;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    UsageCategory = Lists;
    ApplicationArea = Basic, Suite;
    PromotedActionCategories = 'Process';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Start Time"; "Start Time")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("End Time"; "End Time")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Trigger Type"; "Trigger Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Replication Type"; ReplicationType)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Status"; Status)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Source"; Source)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Details"; DetailsValue)
                {
                    ApplicationArea = Basic, Suite;
                    trigger OnDrillDown()
                    begin
                        if DetailsValue <> '' then
                            Message(DetailsValue);
                    end;
                }
            }
        }
        area(FactBoxes)
        {
            part("Replication Statistics"; "Intelligent Cloud Stat Factbox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Run ID" = field("Run ID");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ManageSchedule)
            {
                Enabled = IsSuper and IsSetupComplete;
                Visible = not IsOnPrem;
                ApplicationArea = Basic, Suite;
                Caption = 'Manage Schedule';
                ToolTip = 'Manage migration schedule.';
                Promoted = true;
                PromotedCategory = Process;
                RunObject = page "Intelligent Cloud Schedule";
                RunPageMode = Edit;
                Image = CalendarMachine;
            }

            action(RunReplicationNow)
            {
                Enabled = IsSuper and IsSetupComplete;
                Visible = not IsOnPrem;
                ApplicationArea = Basic, Suite;
                Caption = 'Run Migration Now';
                ToolTip = 'Manually trigger the Cloud Migration.';
                Promoted = true;
                PromotedCategory = Process;
                Image = Setup;

                trigger OnAction()
                var
                    HybridReplicationSummary: Record "Hybrid Replication Summary";
                    IntelligentCloudSetup: Record "Intelligent Cloud Setup";
                    HybridCloudManagement: Codeunit "Hybrid Cloud Management";
                    ErrorMessage: Text;
                begin
                    if IntelligentCloudSetup.Get() then
                        CompanyCreationTaskID := IntelligentCloudSetup."Company Creation Task ID";
                    if CompanyCreationInProgress() then
                        Error(CompanyNotCreatedErr);
                    if CompanyCreationFailed(ErrorMessage) then
                        Error(StrSubstNo(CompanyCreationFailedErr, ErrorMessage));
                    if CompanyCreationNotComplete() then
                        Error(CompanyNotCreatedErr);
                    if not CanRunReplication() then
                        Error(CannotRunReplicationErr);
                    if Dialog.Confirm(RunReplicationConfirmQst, false) then begin
                        HybridCloudManagement.RunReplication(HybridReplicationSummary.ReplicationType::Normal);
                        Message(RunReplicationTxt);
                    end;
                end;
            }

            action(RunDiagnostic)
            {
                Enabled = IsSuper and IsSetupComplete;
                Visible = not IsOnPrem and DiagnosticRunsEnabled;
                ApplicationArea = Basic, Suite;
                Caption = 'Create Diagnostic Run';
                ToolTip = 'Trigger a diagnostic run of the Cloud Migration.';
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                Image = Tools;

                trigger OnAction()
                var
                    DummyHybridReplicationSummary: Record "Hybrid Replication Summary";
                    HybridCloudManagement: Codeunit "Hybrid Cloud Management";
                    ErrorMessage: Text;
                begin
                    if CompanyCreationInProgress() then
                        Error(CompanyNotCreatedErr);
                    if CompanyCreationFailed(ErrorMessage) then
                        Error(StrSubstNo(CompanyCreationFailedErr, ErrorMessage));
                    if not CanRunReplication() then
                        Error(CannotRunReplicationErr);

                    HybridCloudManagement.RunReplication(DummyHybridReplicationSummary.ReplicationType::Diagnostic);
                end;
            }

            action(RefreshStatus)
            {
                Enabled = IsSuper and IsSetupComplete;
                Visible = not IsOnPrem;
                ApplicationArea = Basic, Suite;
                Caption = 'Refresh Status';
                ToolTip = 'Refresh the status of in-progress migration runs.';
                Promoted = true;
                PromotedCategory = Process;
                Image = RefreshLines;

                trigger OnAction()
                var
                    HybridCloudManagement: Codeunit "Hybrid Cloud Management";
                begin
                    HybridCloudManagement.RefreshReplicationStatus();
                    CurrPage.Update();
                end;
            }

            action(ResetAllCloudData)
            {
                Enabled = IsSuper and IsSetupComplete;
                Visible = not IsOnPrem;
                ApplicationArea = Basic, Suite;
                Caption = 'Reset Cloud Data';
                ToolTip = 'Resets migration enabled data in the cloud tenant.';
                Image = Restore;

                trigger OnAction()
                var
                    IntelligentCloudSetup: Record "Intelligent Cloud Setup";
                    HybridDeployment: Codeunit "Hybrid Deployment";
                begin
                    if Dialog.Confirm(ResetCloudDataConfirmQst, false) then
                        if not IntelligentCloudSetup.Get() then
                            Error(ResetCloudFailedErr)
                        else begin
                            HybridDeployment.Initialize(IntelligentCloudSetup."Product ID");
                            HybridDeployment.ResetCloudData();
                            Message(ResetTriggeredTxt);
                        end;
                end;
            }

            action(PrepareTables)
            {
                Enabled = IsSuper and IsSetupComplete;
                Visible = IsOnPrem;
                ApplicationArea = Basic, Suite;
                Caption = 'Prepare tables for migration';
                ToolTip = 'Gets the candidate tables ready for migration';
                Promoted = true;
                PromotedCategory = Process;
                Image = SuggestTables;

                trigger OnAction()
                begin
                    HybridDeployment.PrepareTablesForReplication();
                    Message(TablesReadyForReplicationMsg);
                end;
            }

            action(GetRuntimeKey)
            {
                Enabled = IsSuper and IsSetupComplete;
                Visible = not IsOnPrem;
                ApplicationArea = Basic, Suite;
                Caption = 'Get Runtime Service Key';
                ToolTip = 'Gets the integration runtime key.';
                Image = EncryptionKeys;

                trigger OnAction()
                var
                    PrimaryKey: Text;
                    SecondaryKey: Text;
                begin
                    HybridDeployment.GetIntegrationRuntimeKeys(PrimaryKey, SecondaryKey);
                    Message(IntegrationKeyTxt, PrimaryKey);
                end;
            }

            action(GenerateNewKey)
            {
                Enabled = IsSuper and IsSetupComplete;
                Visible = not IsOnPrem;
                ApplicationArea = Basic, Suite;
                Caption = 'Reset Runtime Service Key';
                ToolTip = 'Resets integration runtime service key.';
                Image = New;

                trigger OnAction()
                var
                    PrimaryKey: Text;
                    SecondaryKey: Text;
                begin
                    if Dialog.Confirm(RegenerateNewKeyConfirmQst, false) then begin
                        HybridDeployment.RegenerateIntegrationRuntimeKeys(PrimaryKey, SecondaryKey);
                        Message(NewIntegrationKeyTxt, PrimaryKey);
                    end;
                end;
            }

            action(DisableIntelligentCloud)
            {
                Enabled = IsSuper and IsSetupComplete;
                Visible = not IsOnPrem;
                ApplicationArea = Basic, Suite;
                Caption = 'Disable Cloud Migration';
                ToolTip = 'Disables Cloud Migration setup.';
                RunObject = page "Intelligent Cloud Ready";
                RunPageMode = Edit;
                Image = Delete;
            }

            action(CheckForUpdate)
            {
                Enabled = IsSuper and IsSetupComplete;
                Visible = not IsOnPrem;
                ApplicationArea = Basic, Suite;
                Caption = 'Check for Update';
                ToolTip = 'Checks if an update is available for your Cloud Migration integration.';
                RunObject = page "Intelligent Cloud Update";
                RunPageMode = Edit;
                Image = Setup;
            }

            action(UpdateReplicationCompanies)
            {
                Enabled = IsSuper and IsSetupComplete and UpdateReplicationCompaniesEnabled;
                Visible = not IsOnPrem and UpdateReplicationCompaniesEnabled;
                ApplicationArea = Basic, Suite;
                Caption = 'Select Companies to Migrate';
                ToolTip = 'Select companies to Migrate';
                Image = Setup;

                trigger OnAction()
                begin
                    Page.RunModal(Page::"Hybrid Companies Management");
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
        IntelligentCloudStatus: Record "Intelligent Cloud Status";
        HybridCompany: Record "Hybrid Company";
        PermissionManager: Codeunit "Permission Manager";
        UserPermissions: Codeunit "User Permissions";
        EnvironmentInfo: Codeunit "Environment Information";
        IntelligentCloudNotifier: Codeunit "Intelligent Cloud Notifier";
    begin
        IsSuper := UserPermissions.IsSuper(UserSecurityId());
        IsOnPrem := NOT EnvironmentInfo.IsSaaS();
        IsSetupComplete := PermissionManager.IsIntelligentCloud() OR (IsOnPrem AND NOT IntelligentCloudStatus.IsEmpty());
        IsMigratedCompany := HybridCompany.Get(CompanyName()) and HybridCompany.Replicate;
        UpdateReplicationCompaniesEnabled := true;

        CanRunDiagnostic(DiagnosticRunsEnabled);
        CanShowSetupChecklist(SetupChecklistEnabled);
        CanShowMapUsers(MapUsersEnabled);
        CanShowUpdateReplicationCompanies(UpdateReplicationCompaniesEnabled);

        if IntelligentCloudSetup.Get() then begin
            HybridDeployment.Initialize(IntelligentCloudSetup."Product ID");
            CompanyCreationTaskID := IntelligentCloudSetup."Company Creation Task ID";
        end;

        IntelligentCloudNotifier.ShowICUpdateNotification();

        SetFilter("Start Time", '>%1', CreateDateTime(CALCDATE('<CD-30D>', Today()), 0T));
        if not FindSet() then
            exit;
    end;

    trigger OnAfterGetRecord()
    begin
        DetailsValue := GetDetails();
    end;

    local procedure CanRunReplication(): Boolean
    var
        HybridReplicationSummary: Record "Hybrid Replication Summary";
    begin
        HybridReplicationSummary.SetRange(Status, Status::InProgress);
        HybridReplicationSummary.SetFilter("Start Time", '>%1', (CurrentDateTime() - 86400000));
        if not HybridReplicationSummary.IsEmpty() then
            exit(false);
        exit(true);
    end;

    local procedure CompanyCreationInProgress(): Boolean
    var
        ScheduledTask: Record "Scheduled Task";
    begin
        exit(ScheduledTask.Get(CompanyCreationTaskID));
    end;

    local procedure CompanyCreationNotComplete(): Boolean
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        HybridCompany: Record "Hybrid Company";
        SetupStatus: Option " ","Completed","In Progress","Error","Missing Permission";
    begin
        HybridCompany.Reset();
        HybridCompany.SetRange(Replicate, true);
        if HybridCompany.FindSet() then
            repeat
                if AssistedCompanySetupStatus.Get(HybridCompany.Name) then begin
                    SetupStatus := AssistedCompanySetupStatus.GetCompanySetupStatus(CopyStr(HybridCompany.Name, 1, 30));
                    if SetupStatus <> SetupStatus::Completed then
                        exit(true);
                end;
            until HybridCompany.Next() = 0;
        exit(false);
    end;

    local procedure CompanyCreationFailed(var ErrorMessage: Text): Boolean
    var
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
    begin
        if IntelligentCloudSetup.Get() then begin
            ErrorMessage := IntelligentCloudSetup."Company Creation Task Error";
            exit((IntelligentCloudSetup."Company Creation Task Status" = IntelligentCloudSetup."Company Creation Task Status"::Failed));
        end;
        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure CanRunDiagnostic(var CanRun: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    protected procedure CanShowSetupChecklist(var Enabled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    protected procedure CanShowMapUsers(var Enabled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure CanShowUpdateReplicationCompanies(var Enabled: Boolean)
    begin
    end;

    var
        HybridDeployment: Codeunit "Hybrid Deployment";
        CompanyCreationTaskID: Guid;
        IsSetupComplete: Boolean;
        IsSuper: Boolean;
        IsOnPrem: Boolean;
        IsMigratedCompany: Boolean;
        DiagnosticRunsEnabled: Boolean;
        SetupChecklistEnabled: Boolean;
        MapUsersEnabled: Boolean;
        UpdateReplicationCompaniesEnabled: Boolean;
        DetailsValue: Text;
        RunReplicationConfirmQst: Label 'Are you sure you want to trigger migration?';
        RegenerateNewKeyConfirmQst: Label 'Are you sure you want to generate new integration runtime key?';
        CompanyNotCreatedErr: Label 'Cannot run migration since the background task has not finished creating companies yet.';
        CompanyCreationFailedErr: Label 'Company creation failed with error %1. Please fix this and re-run the Cloud Migration Setup wizard.';
        CannotRunReplicationErr: Label 'A migration is already in progress.';
        RunReplicationTxt: Label 'Migration has been successfully triggered. You can track the status on the management page.';
        IntegrationKeyTxt: Label 'Primary key for the integration runtime is: %1', Comment = '%1 = Integration Runtime Key';
        NewIntegrationKeyTxt: Label 'New Primary key for the integration runtime is: %1', Comment = '%1 = Integration Runtime Key';
        ResetCloudDataConfirmQst: Label 'Are you sure you want to reset all cloud data?';
        ResetCloudFailedErr: Label 'Failed to reset cloud data';
        ResetTriggeredTxt: Label 'Reset has been successfully triggered. All migration enabled data will be reset in the next sync.';
        TablesReadyForReplicationMsg: Label 'All tables have been successfully prepared for migration.';
}