page 672 "Job Queue Entries"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Job Queue Entries';
    CardPageID = "Job Queue Entry Card";
    PageType = List;
    SourceTable = "Job Queue Entry";
    SourceTableView = SORTING("Last Ready State");
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the job queue entry. When you create a job queue entry, its status is set to On Hold. You can set the status to Ready and back to On Hold. Otherwise, status information in this field is updated automatically.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Basic, Suite;
                    Style = Unfavorable;
                    StyleExpr = UserDoesNotExist;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                }
                field("Object Type to Run"; "Object Type to Run")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the object, report or codeunit, that is to be run for the job queue entry. After you specify a type, you then select an object ID of that type in the Object ID to Run field.';
                }
                field("Object ID to Run"; "Object ID to Run")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the object that is to be run for this job. You can select an ID that is of the object type that you have specified in the Object Type to Run field.';
                }
                field("Object Caption to Run"; "Object Caption to Run")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the object that is selected in the Object ID to Run field.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the job queue entry. You can edit and update the description on the job queue entry card. The description is also displayed in the Job Queue Entries window, but it cannot be updated there.';
                }
                field("Job Queue Category Code"; "Job Queue Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the job queue category to which the job queue entry belongs. Choose the field to select a code from the list.';
                }
                field("User Session Started"; "User Session Started")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date and time that a user session started.';
                }
                field("Parameter String"; "Parameter String")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a text string that is used as a parameter by the job queue when it is run.';
                    Visible = false;
                }
                field("Earliest Start Date/Time"; "Earliest Start Date/Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the earliest date and time when the job queue entry should be run.';
                }
                field(Scheduled; Scheduled)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Unfavorable;
                    StyleExpr = NOT Scheduled;
                    ToolTip = 'Specifies the assigned priority of a job queue entry. You can use priority to determine the order in which job queue entries are run.';
                }
                field("Recurring Job"; "Recurring Job")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the job queue entry is recurring. If the Recurring Job check box is selected, then the job queue entry is recurring. If the check box is cleared, the job queue entry is not recurring. After you specify that a job queue entry is a recurring one, you must specify on which days of the week the job queue entry is to run. Optionally, you can also specify a time of day for the job to run and how many minutes should elapse between runs.';
                }
                field("No. of Minutes between Runs"; "No. of Minutes between Runs")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the minimum number of minutes that are to elapse between runs of a job queue entry. This field only has meaning if the job queue entry is set to be a recurring job.';
                }
                field("Run on Mondays"; "Run on Mondays")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the job queue entry runs on Mondays.';
                    Visible = false;
                }
                field("Run on Tuesdays"; "Run on Tuesdays")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the job queue entry runs on Tuesdays.';
                    Visible = false;
                }
                field("Run on Wednesdays"; "Run on Wednesdays")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the job queue entry runs on Wednesdays.';
                    Visible = false;
                }
                field("Run on Thursdays"; "Run on Thursdays")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the job queue entry runs on Thursdays.';
                    Visible = false;
                }
                field("Run on Fridays"; "Run on Fridays")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the job queue entry runs on Fridays.';
                    Visible = false;
                }
                field("Run on Saturdays"; "Run on Saturdays")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the job queue entry runs on Saturdays.';
                    Visible = false;
                }
                field("Run on Sundays"; "Run on Sundays")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the job queue entry runs on Sundays.';
                    Visible = false;
                }
                field("Starting Time"; "Starting Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the earliest time of the day that the recurring job queue entry is to be run.';
                    Visible = false;
                }
                field("Ending Time"; "Ending Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the latest time of the day that the recurring job queue entry is to be run.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("Job &Queue")
            {
                Caption = 'Job &Queue';
                Image = CheckList;
                action(ResetStatus)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set Status to Ready';
                    Image = ResetStatus;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Change the status of the selected entry.';

                    trigger OnAction()
                    begin
                        SetStatus(Status::Ready);
                    end;
                }
                action(Suspend)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set On Hold';
                    Image = Pause;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Change the status of the selected entry.';

                    trigger OnAction()
                    begin
                        SetStatus(Status::"On Hold");
                    end;
                }
                action(ShowError)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Error';
                    Image = Error;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    ToolTip = 'Show the error message that has stopped the entry.';

                    trigger OnAction()
                    begin
                        ShowErrorMessage;
                    end;
                }
                action(Restart)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Restart';
                    Image = Start;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Stop and start the selected entry.';

                    trigger OnAction()
                    begin
                        Restart;
                    end;
                }
            }
        }
        area(navigation)
        {
            group(Action15)
            {
                Caption = 'Job &Queue';
                Image = CheckList;
                action(LogEntries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Log Entries';
                    Image = Log;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Job Queue Log Entries";
                    RunPageLink = ID = FIELD(ID);
                    ToolTip = 'View the job queue log entries.';
                }
                action(ShowRecord)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Record';
                    Image = ViewDetails;
                    ToolTip = 'Show the record for the selected entry.';

                    trigger OnAction()
                    begin
                        LookupRecordToProcess;
                    end;
                }
                action(RemoveError)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remove Failed Entries';
                    Image = Delete;
                    ToolTip = 'Deletes the job queue entries that have failed.';

                    trigger OnAction()
                    begin
                        RemoveFailedJobs;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        User: Record User;
    begin
        UserDoesNotExist := false;
        if "User ID" = UserId then
            exit;
        if User.IsEmpty then
            exit;
        User.SetRange("User Name", "User ID");
        UserDoesNotExist := User.IsEmpty;
    end;

    var
        UserDoesNotExist: Boolean;

    local procedure RemoveFailedJobs()
    var
        JobQueueEntry: Record "Job Queue Entry";
        FailedJobQueueEntry: Query "Failed Job Queue Entry";
    begin
        // Don't remove jobs that have just failed (i.e. last 30 sec)
        FailedJobQueueEntry.SetRange(End_Date_Time, 0DT, CurrentDateTime - 30000);
        FailedJobQueueEntry.Open;

        while FailedJobQueueEntry.Read do begin
            if JobQueueEntry.Get(FailedJobQueueEntry.ID) then
                JobQueueEntry.Delete(true);
        end;
    end;
}

