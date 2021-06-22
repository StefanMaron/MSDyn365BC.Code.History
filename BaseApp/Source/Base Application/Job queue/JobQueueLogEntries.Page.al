page 674 "Job Queue Log Entries"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Job Queue Log Entries';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Job Queue Log Entry";
    SourceTableView = SORTING("Start Date/Time", ID)
                      ORDER(Descending);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the running of the job queue entry in a log.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the job queue entry in the log.';
                }
                field("Object Type to Run"; "Object Type to Run")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the object that is to be run for the job.';
                }
                field("Object ID to Run"; "Object ID to Run")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the object that is to be run for the job.';
                }
                field("Object Caption to Run"; "Object Caption to Run")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name or caption of the object that was run for the job.';
                }
                field("Parameter String"; "Parameter String")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the parameter string of the corresponding job.';
                }
                field("Start Date/Time"; "Start Date/Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date and time when the job was started.';
                }
                field(Duration; Duration)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Duration';
                    ToolTip = 'Specifies how long the job queue log entry will take to run.';
                }
                field("End Date/Time"; "End Date/Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date and time when the job ended.';
                    Visible = false;
                }
                field("Error Message"; "Error Message")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Error Message';
                    ToolTip = 'Specifies an error that occurred in the job queue.';

                    trigger OnAssistEdit()
                    begin
                        ShowErrorMessage;
                    end;
                }
                field("Processed by User ID"; "Processed by User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user ID of the job queue entry processor. The user ID comes from the job queue entry card.';
                    Visible = false;
                }
                field("Job Queue Category Code"; "Job Queue Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the category code for the entry in the job queue log.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Delete7days)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Delete Entries Older Than 7 Days';
                Image = ClearLog;
                ToolTip = 'Clear the list of log entries that are older than 7 days.';

                trigger OnAction()
                begin
                    DeleteEntries(7);
                end;
            }
            action(Delete0days)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Delete All Entries';
                Image = Delete;
                ToolTip = 'Clear the list of all log entries.';

                trigger OnAction()
                begin
                    DeleteEntries(0);
                end;
            }
            action("Show Error Message")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show Error Message';
                Enabled = Status = Status::Error;
                Image = Error;
                ToolTip = 'Show the error message that has stopped the entry.';

                trigger OnAction()
                begin
                    ShowErrorMessage;
                end;
            }
            action("Show Error Call Stack")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show Error Call Stack';
                Enabled = Status = Status::Error;
                Image = StepInto;
                ToolTip = 'Show the call stack for the error that has stopped the entry.';

                trigger OnAction()
                begin
                    ShowErrorCallStack;
                end;
            }
            action(SetStatusToError)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set Status to Error';
                Image = DefaultFault;
                ToolTip = 'Change the status of the entry.';

                trigger OnAction()
                begin
                    if Confirm(JobQueueEntryRunningQst, false) then
                        MarkAsError;
                end;
            }
        }
        area(navigation)
        {
            action(Details)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Details';
                Image = Log;
                Promoted = true;
                PromotedCategory = "Report";
                PromotedIsBig = true;
                ToolTip = 'View detailed information about the job queue log entry.';

                trigger OnAction()
                begin
                    OnShowDetails(Rec);
                end;
            }
        }
    }

    var
        JobQueueEntryRunningQst: Label 'This job queue entry may be still running. If you set the status to Error, it may keep running in the background. Are you sure you want to set the status to Error?';

    [IntegrationEvent(false, false)]
    local procedure OnShowDetails(JobQueueLogEntry: Record "Job Queue Log Entry")
    begin
    end;
}

