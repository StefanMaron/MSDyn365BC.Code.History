page 5331 "CRM Full Synch. Review"
{
    Caption = 'Dataverse Full Synch. Review';
    PageType = Worksheet;
    SourceTable = "CRM Full Synch. Review Line";
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Editable = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name.';
                }
                field("Dependency Filter"; Rec."Dependency Filter")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a dependency to the synchronization of another record, such as a customer that must be synchronized before a contact can be synchronized.';
                    Visible = false;
                }
                field("Job Queue Entry Status"; Rec."Job Queue Entry Status")
                {
                    ApplicationArea = Suite;
                    StyleExpr = JobQueueEntryStatusStyle;
                    ToolTip = 'Specifies the status of the job queue entry.';

                    trigger OnDrillDown()
                    begin
                        ShowJobQueueLogEntry();
                    end;
                }
                field(ActiveSession; IsActiveSession())
                {
                    ApplicationArea = Suite;
                    Caption = 'Active Session';
                    ToolTip = 'Specifies whether the session is active.';
                }
                field(Direction; Direction)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the synchronization direction.';
                }
                field("To Int. Table Job Status"; Rec."To Int. Table Job Status")
                {
                    ApplicationArea = Suite;
                    StyleExpr = ToIntTableJobStatusStyle;
                    ToolTip = 'Specifies the status of jobs for data going to the integration table. ';

                    trigger OnDrillDown()
                    begin
                        ShowSynchJobLog("To Int. Table Job ID");
                    end;
                }
                field("From Int. Table Job Status"; Rec."From Int. Table Job Status")
                {
                    ApplicationArea = Suite;
                    StyleExpr = FromIntTableJobStatusStyle;
                    ToolTip = 'Specifies the status of jobs for data coming from the integration table. ';

                    trigger OnDrillDown()
                    begin
                        ShowSynchJobLog("From Int. Table Job ID");
                    end;
                }
                field("Initial Synchronization Recommendation"; InitialSynchRecommendation)
                {
                    Caption = 'Recommendation';
                    ApplicationArea = Suite;
                    Enabled = SynchRecommendationDrillDownEnabled;
                    StyleExpr = InitialSynchRecommendationStyle;
                    ToolTip = 'Specifies the recommended action for the initial synchronization.';

                    trigger OnDrillDown()
                    var
                        IntegrationFieldMapping: Record "Integration Field Mapping";
                        IntegrationTableMapping: Record "Integration Table Mapping";
                    begin
                        if not (InitialSynchRecommendation in [MatchBasedCouplingTxt, CouplingCriteriaSelectedTxt]) then
                            exit;

                        if not IntegrationTableMapping.Get(Name) then
                            exit;

                        IntegrationFieldMapping.SetMatchBasedCouplingFilters(IntegrationTableMapping);
                        if Page.RunModal(Page::"Match Based Coupling Criteria", IntegrationFieldMapping) = Action::LookupOK then
                            CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Start)
            {
                ApplicationArea = Suite;
                Caption = 'Sync All';
                Enabled = ActionStartEnabled;
                Image = Start;
                ToolTip = 'Start all the default integration jobs for synchronizing Business Central record types and Dataverse entities, as defined on the Integration Table Mappings page. Mappings with finished job status will be skipped.';

                trigger OnAction()
                var
                    CDSConnectionSetup: Record "CDS Connection Setup";
                    CRMSynchHelper: Codeunit "CRM Synch. Helper";
                    OwnershipModel: Option;
                    handled: Boolean;
                    QuestionTxt: Text;
                begin
                    CRMSynchHelper.OnGetCDSOwnershipModel(OwnershipModel, handled);
                    if handled and (OwnershipModel = CDSConnectionSetup."Ownership Model"::Team) then
                        QuestionTxt := StartInitialSynchTeamOwnershipModelQst
                    else
                        QuestionTxt := StrSubstNo(StartInitialSynchPersonOwnershipModelQst, PRODUCTNAME.Short(), CRMProductName.CDSServiceName());
                    if Confirm(QuestionTxt) then
                        Start();
                end;
            }
            action(Restart)
            {
                ApplicationArea = Suite;
                Caption = 'Restart';
                Enabled = ActionRestartEnabled;
                Image = Refresh;
                ToolTip = 'Restart the integration job for synchronizing Business Central record types and Dataverse entities, as defined on the Integration Table Mappings page.';
                trigger OnAction()
                begin
                    Delete();
                    Generate(InitialSynchRecommendations, DeletedLines);
                    Start();
                end;
            }
            action(Reset)
            {
                ApplicationArea = Suite;
                Caption = 'Reset';
                Enabled = ActionResetEnabled;
                Image = ResetStatus;
                ToolTip = 'Removes all lines, readds all Integration Table Mappings and recalculates synchronization recommendations.';
                trigger OnAction()
                begin
                    DeleteAll();
                    Clear(InitialSynchRecommendations);
                    Clear(DeletedLines);
                    Generate();
                end;
            }
            action(ScheduleFullSynch)
            {
                ApplicationArea = Suite;
                Caption = 'Recommend Full Synchronization';
                Enabled = ActionRecommendFullSynchEnabled;
                Image = RefreshLines;
                ToolTip = 'Recommend full synchronization job for the selected line.';

                trigger OnAction()
                begin
                    if InitialSynchRecommendations.ContainsKey(Name) then
                        InitialSynchRecommendations.Remove(Name);
                    InitialSynchRecommendations.Add(Name, "Initial Synch Recommendation"::"Full Synchronization");
                    Delete();
                    Generate(InitialSynchRecommendations, DeletedLines);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Start_Promoted; Start)
                {
                }
                actionref(Restart_Promoted; Restart)
                {
                }
                actionref(Reset_Promoted; Reset)
                {
                }
                actionref(ScheduleFullSynch_Promoted; ScheduleFullSynch)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        ActionStartEnabled := (not IsThereActiveSessionInProgress()) and IsThereBlankStatusLine();
        ActionResetEnabled := (not IsThereActiveSessionInProgress());
        ActionRestartEnabled := (not IsThereActiveSessionInProgress()) and (("Job Queue Entry Status" = "Job Queue Entry Status"::Error) or ("Job Queue Entry Status" = "Job Queue Entry Status"::Finished));
        ActionRecommendFullSynchEnabled := ActionResetEnabled and ("Initial Synch Recommendation" = "Initial Synch Recommendation"::"Couple Records");
        JobQueueEntryStatusStyle := GetStatusStyleExpression(Format("Job Queue Entry Status"));
        ToIntTableJobStatusStyle := GetStatusStyleExpression(Format("To Int. Table Job Status"));
        FromIntTableJobStatusStyle := GetStatusStyleExpression(Format("From Int. Table Job Status"));
        if not InitialSynchRecommendations.ContainsKey(Name) then
            InitialSynchRecommendations.Add(Name, "Initial Synch Recommendation");

        if "Initial Synch Recommendation" <> "Initial Synch Recommendation"::"Couple Records" then
            InitialSynchRecommendation := Format("Initial Synch Recommendation")
        else begin
            IntegrationFieldMapping.SetRange("Integration Table Mapping Name", Name);
            IntegrationFieldMapping.SetRange("Use For Match-Based Coupling", true);
            if IntegrationFieldMapping.IsEmpty() then
                InitialSynchRecommendation := MatchBasedCouplingTxt
            else
                InitialSynchRecommendation := CouplingCriteriaSelectedTxt
        end;
        if InitialSynchRecommendation = CouplingCriteriaSelectedTxt then
            InitialSynchRecommendationStyle := 'Favorable'
        else
            InitialSynchRecommendationStyle := GetInitialSynchRecommendationStyleExpression(Format("Initial Synch Recommendation"));
        SynchRecommendationDrillDownEnabled := (InitialSynchRecommendation in [MatchBasedCouplingTxt, CouplingCriteriaSelectedTxt]);
    end;

    trigger OnOpenPage()
    begin
        Clear(DeletedLines);
        Generate(SkipEntitiesNotFullSyncReady);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        DeletedLines.Add(Rec.Name);
    end;

    [Scope('OnPrem')]
    procedure SetSkipEntitiesNotFullSyncReady()
    begin
        SkipEntitiesNotFullSyncReady := true;
    end;

    var
        CRMProductName: Codeunit "CRM Product Name";
        ActionStartEnabled: Boolean;
        ActionResetEnabled: Boolean;
        ActionRestartEnabled: Boolean;
        ActionRecommendFullSynchEnabled: Boolean;
        SkipEntitiesNotFullSyncReady: Boolean;
        SynchRecommendationDrillDownEnabled: Boolean;
        InitialSynchRecommendations: Dictionary of [Code[20], Integer];
        DeletedLines: List of [Code[20]];
        JobQueueEntryStatusStyle: Text;
        ToIntTableJobStatusStyle: Text;
        FromIntTableJobStatusStyle: Text;
        StartInitialSynchPersonOwnershipModelQst: Label 'Full synchronization will synchronize all coupled and uncoupled records.\You should use this option only when you are synchronizing data for the first time.\The synchronization will run in the background, so you can continue with other tasks.\To check the status, return to this page or refresh it.\\Before running full synchronization, you should couple all %1 salespeople to %2 users.\\Do you want to continue?', Comment = '%1 - product name, %2 = Dataverse service name';
        StartInitialSynchTeamOwnershipModelQst: Label 'Full synchronization will synchronize all coupled and uncoupled records.\You should use this option only when you are synchronizing data for the first time.\The synchronization will run in the background, so you can continue with other tasks.\To check the status, return to this page or refresh it.\\Do you want to continue?';
        InitialSynchRecommendation: Text;
        InitialSynchRecommendationStyle: Text;
        MatchBasedCouplingTxt: Label 'Select Coupling Criteria';
        CouplingCriteriaSelectedTxt: Label 'Coupling Criteria Selected';
}

