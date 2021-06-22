page 676 "Schedule a Job"
{
    Caption = 'Schedule a Job';
    DataCaptionExpression = Description;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = StandardDialog;
    SourceTable = "Job Queue Entry";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            field(Description; Description)
            {
                ApplicationArea = Basic, Suite;
                Enabled = false;
                ToolTip = 'Specifies a description of the job queue entry. You can edit and update the description on the job queue entry card. The description is also displayed in the Job Queue Entries window, but it cannot be updated there.';
            }
            field("Earliest Start Date/Time"; "Earliest Start Date/Time")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the earliest date and time when the job should be started. If you leave the field blank, the job starts when you choose the OK button.';
            }
        }
    }

    actions
    {
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if CloseAction <> ACTION::OK then
            exit(true);

        JobQueueEntry := Rec;
        Clear(JobQueueEntry.ID); // "Job Queue - Enqueue" defines it on the real record insert
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
        exit(true);
    end;

    procedure ScheduleJob(JobQueueEntry: Record "Job Queue Entry"): Boolean
    var
        ScheduleAJob: Page "Schedule a Job";
    begin
        ScheduleAJob.SetJob(JobQueueEntry);
        exit(ScheduleAJob.RunModal = ACTION::OK);
    end;

    procedure SetJob(JobQueueEntry: Record "Job Queue Entry")
    begin
        Rec := JobQueueEntry;
        Insert(true);
    end;
}

