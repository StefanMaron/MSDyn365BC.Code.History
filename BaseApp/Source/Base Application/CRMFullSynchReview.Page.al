page 5331 "CRM Full Synch. Review"
{
    Caption = 'Common Data Service Full Synch. Review';
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
                field(Name; Name)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name.';
                }
                field("Dependency Filter"; "Dependency Filter")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a dependency to the synchronization of another record, such as a customer that must be synchronized before a contact can be synchronized.';
                    Visible = false;
                }
                field("Job Queue Entry Status"; "Job Queue Entry Status")
                {
                    ApplicationArea = Suite;
                    StyleExpr = JobQueueEntryStatusStyle;
                    ToolTip = 'Specifies the status of the job queue entry.';

                    trigger OnDrillDown()
                    begin
                        ShowJobQueueLogEntry;
                    end;
                }
                field(ActiveSession; IsActiveSession)
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
                field("To Int. Table Job Status"; "To Int. Table Job Status")
                {
                    ApplicationArea = Suite;
                    StyleExpr = ToIntTableJobStatusStyle;
                    ToolTip = 'Specifies the status of jobs for data going to the integration table. ';

                    trigger OnDrillDown()
                    begin
                        ShowSynchJobLog("To Int. Table Job ID");
                    end;
                }
                field("From Int. Table Job Status"; "From Int. Table Job Status")
                {
                    ApplicationArea = Suite;
                    StyleExpr = FromIntTableJobStatusStyle;
                    ToolTip = 'Specifies the status of jobs for data coming from the integration table. ';

                    trigger OnDrillDown()
                    begin
                        ShowSynchJobLog("From Int. Table Job ID");
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
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Start all the default integration jobs for synchronizing Business Central record types and Common Data Service entities, as defined on the Integration Table Mappings page.';

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
                        QuestionTxt := StrSubstNo(StartInitialSynchPersonOwnershipModelQst, PRODUCTNAME.Short, 'CDS');
                    if Confirm(QuestionTxt) then
                        Start;
                end;
            }
            action(Restart)
            {
                ApplicationArea = Suite;
                Caption = 'Restart';
                Enabled = ActionRestartEnabled;
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Restart the integration job for synchronizing Business Central record types and Common Data Service entities, as defined on the Integration Table Mappings page.';
                trigger OnAction()
                begin
                    Delete();
                    Generate();
                    Start();
                end;
            }
            action(Reset)
            {
                ApplicationArea = Suite;
                Caption = 'Reset';
                Enabled = ActionResetEnabled;
                Image = ResetStatus;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Removes all lines and readds all Integration Table Mappings.';
                trigger OnAction()
                begin
                    DeleteAll();
                    Generate();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ActionStartEnabled := (not IsThereActiveSessionInProgress) and IsThereBlankStatusLine;
        ActionResetEnabled := (not IsThereActiveSessionInProgress());
        ActionRestartEnabled := (not IsThereActiveSessionInProgress()) and (("Job Queue Entry Status" = "Job Queue Entry Status"::Error) or ("Job Queue Entry Status" = "Job Queue Entry Status"::Finished));
        JobQueueEntryStatusStyle := GetStatusStyleExpression(Format("Job Queue Entry Status"));
        ToIntTableJobStatusStyle := GetStatusStyleExpression(Format("To Int. Table Job Status"));
        FromIntTableJobStatusStyle := GetStatusStyleExpression(Format("From Int. Table Job Status"));
    end;

    trigger OnOpenPage()
    begin
        Generate(SkipEntitiesNotFullSyncReady);
    end;

    [Scope('OnPrem')]
    procedure SetSkipEntitiesNotFullSyncReady()
    begin
        SkipEntitiesNotFullSyncReady := true;
    end;

    var
        ActionStartEnabled: Boolean;
        ActionResetEnabled: Boolean;
        ActionRestartEnabled: Boolean;
        SkipEntitiesNotFullSyncReady: Boolean;
        JobQueueEntryStatusStyle: Text;
        ToIntTableJobStatusStyle: Text;
        FromIntTableJobStatusStyle: Text;
        StartInitialSynchPersonOwnershipModelQst: Label 'Full synchronization will synchronize all coupled and uncoupled records.\You should use this option only when you are synchronizing data for the first time.\The synchronization will run in the background, so you can continue with other tasks.\To check the status, return to this page or refresh it.\\Before running full synchronization, you should couple all %1 salespeople to %2 users.\\Do you want to continue?', Comment = '%1 - product name, %2 = CRM product name';
        StartInitialSynchTeamOwnershipModelQst: Label 'Full synchronization will synchronize all coupled and uncoupled records.\You should use this option only when you are synchronizing data for the first time.\The synchronization will run in the background, so you can continue with other tasks.\To check the status, return to this page or refresh it.\\Do you want to continue?';
}

