page 675 "My Job Queue"
{
    Caption = 'My Job Queue';
    Editable = false;
    PageType = ListPart;
    RefreshOnActivate = true;
    SourceTable = "Job Queue Entry";
    SourceTableView = SORTING("Last Ready State");

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Object Caption to Run"; "Object Caption to Run")
                {
                    ApplicationArea = Basic, Suite;
                    Style = Attention;
                    StyleExpr = StatusIsError;
                    ToolTip = 'Specifies the name of the object that is selected in the Object ID to Run field.';
                    Visible = false;
                }
                field("Parameter String"; "Parameter String")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a text string that is used as a parameter by the job queue when it is run.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Attention;
                    StyleExpr = StatusIsError;
                    ToolTip = 'Specifies a description of the job queue entry. You can edit and update the description on the job queue entry card. The description is also displayed in the Job Queue Entries window, but it cannot be updated there.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Attention;
                    StyleExpr = StatusIsError;
                    ToolTip = 'Specifies the status of the job queue entry. When you create a job queue entry, its status is set to On Hold. You can set the status to Ready and back to On Hold. Otherwise, status information in this field is updated automatically.';
                }
                field("Earliest Start Date/Time"; "Earliest Start Date/Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the earliest date and time when the job queue entry should be run.';
                }
                field("Expiration Date/Time"; "Expiration Date/Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date and time when the job queue entry is to expire, after which the job queue entry will not be run.';
                    Visible = false;
                }
                field("Job Queue Category Code"; "Job Queue Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the job queue category to which the job queue entry belongs. Choose the field to select a code from the list.';
                    Visible = false;
                }
            }
            group(Control18)
            {
                ShowCaption = false;
                usercontrol(PingPong; "Microsoft.Dynamics.Nav.Client.PingPong")
                {
                    ApplicationArea = Basic, Suite;

                    trigger AddInReady()
                    begin
                        AddInReady := true;
                        if not PrevLastJobQueueEntry.FindLast then
                            Clear(PrevLastJobQueueEntry);
                        CurrPage.PingPong.Ping(10000);
                    end;

                    trigger Pong()
                    var
                        CurrLastJobQueueEntry: Record "Job Queue Entry";
                    begin
                        if not CurrLastJobQueueEntry.FindLast then
                            Clear(CurrLastJobQueueEntry);
                        if (CurrLastJobQueueEntry.ID <> PrevLastJobQueueEntry.ID) or (CurrLastJobQueueEntry.Status <> PrevLastJobQueueEntry.Status) then
                            CurrPage.Update(false);
                        PrevLastJobQueueEntry := CurrLastJobQueueEntry;
                        CurrPage.PingPong.Ping(10000);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ShowError)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show Error';
                Image = Error;
                ToolTip = 'Show the error message that has stopped the entry.';

                trigger OnAction()
                begin
                    ShowErrorMessage;
                end;
            }
            action(Cancel)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Delete';
                Image = Delete;
                ToolTip = 'Delete the record.';

                trigger OnAction()
                begin
                    Cancel;
                end;
            }
            action(Restart)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Restart';
                Image = Start;
                ToolTip = 'Stop and start the entry.';

                trigger OnAction()
                begin
                    Restart;
                end;
            }
            action(ShowRecord)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show Record';
                Image = ViewDetails;
                ToolTip = 'Show the record for the entry.';

                trigger OnAction()
                begin
                    LookupRecordToProcess;
                end;
            }
            action(ScheduleReport)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Schedule a Report';
                Image = "Report";
                ToolTip = 'Add a report to a job queue. You must already have set up a job queue for scheduled reports.';

                trigger OnAction()
                begin
                    CurrPage.PingPong.Stop;
                    PAGE.RunModal(PAGE::"Schedule a Report");
                    CurrPage.PingPong.Ping(1000);
                end;
            }
            action(EditJob)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit Job';
                Image = Edit;
                RunObject = Page "Job Queue Entry Card";
                RunPageOnRec = true;
                ShortCutKey = 'Return';
                ToolTip = 'Change the settings for the job queue entry.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        StatusIsError := Status = Status::Error;
    end;

    trigger OnOpenPage()
    begin
        SetRange("User ID", UserId);
        AddInReady := false;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if AddInReady then
            CurrPage.PingPong.Stop;
        exit(true);
    end;

    var
        PrevLastJobQueueEntry: Record "Job Queue Entry";
        [InDataSet]
        StatusIsError: Boolean;
        AddInReady: Boolean;
}

