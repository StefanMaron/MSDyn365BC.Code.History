page 5331 "CRM Full Synch. Review"
{
    Caption = 'Dynamics 365 Sales Full Synch. Review';
    PageType = Worksheet;
    SourceTable = "CRM Full Synch. Review Line";

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
                    ToolTip = 'Specifies if the session is active.';
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
                Caption = 'Start';
                Enabled = ActionStartEnabled;
                Image = Start;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Start all the default integration jobs for synchronizing Business Central record types and Dynamics 365 Sales entities, as defined on the Integration Table Mappings page.';

                trigger OnAction()
                begin
                    if Confirm(StrSubstNo(StartInitialSynchQst, PRODUCTNAME.Short, CRMProductName.SHORT)) then
                        Start;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ActionStartEnabled := (not IsThereActiveSessionInProgress) and IsThereBlankStatusLine;
        JobQueueEntryStatusStyle := GetStatusStyleExpression(Format("Job Queue Entry Status"));
        ToIntTableJobStatusStyle := GetStatusStyleExpression(Format("To Int. Table Job Status"));
        FromIntTableJobStatusStyle := GetStatusStyleExpression(Format("From Int. Table Job Status"));
    end;

    trigger OnOpenPage()
    begin
        Generate;
    end;

    var
        CRMProductName: Codeunit "CRM Product Name";
        ActionStartEnabled: Boolean;
        JobQueueEntryStatusStyle: Text;
        ToIntTableJobStatusStyle: Text;
        FromIntTableJobStatusStyle: Text;
        StartInitialSynchQst: Label 'This will synchronize records in all integration table mappings, including uncoupled records.\\Before running full synchronization, you should couple all %1 salespeople to %2 users.\\To prevent data duplication, it is also recommended to couple and synchronize other existing records in advance.\\Do you want to continue?', Comment = '%1 - product name, %2 = CRM product name';
}

