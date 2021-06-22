page 5098 "Task Card"
{
    Caption = 'Task Card';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "To-do";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Description)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the description of the task.';
                }
                field(Location; Location)
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = LocationEnable;
                    ToolTip = 'Specifies the location where the meeting will take place.';
                    Visible = NOT IsSoftwareAsAService;
                }
                field("Salesperson Code"; "Salesperson Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code of the salesperson assigned to the task.';

                    trigger OnValidate()
                    begin
                        SalespersonCodeOnAfterValidate;
                    end;
                }
                field("No. of Attendees"; "No. of Attendees")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = NoOfAttendeesEnable;
                    ToolTip = 'Specifies the number of attendees for the meeting. click the field to view the Attendee Scheduling card.';

                    trigger OnDrillDown()
                    begin
                        Modify;
                        Commit();
                        PAGE.RunModal(PAGE::"Attendee Scheduling", Rec);
                        Get("No.");
                        CurrPage.Update;
                    end;
                }
                field("Attendees Accepted No."; "Attendees Accepted No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = AttendeesAcceptedNoEnable;
                    ToolTip = 'Specifies the number of attendees that have confirmed their participation in the meeting.';

                    trigger OnDrillDown()
                    begin
                        Modify;
                        Commit();
                        PAGE.RunModal(PAGE::"Attendee Scheduling", Rec);
                        Get("No.");
                        CurrPage.Update;
                    end;
                }
                field("Contact No."; "Contact No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = ContactNoEditable;
                    ToolTip = 'Specifies the number of the contact linked to the task.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Task: Record "To-do";
                        Cont: Record Contact;
                    begin
                        if Type = Type::Meeting then begin
                            Task.SetRange("No.", "No.");
                            PAGE.RunModal(PAGE::"Attendee Scheduling", Task);
                        end else begin
                            if Cont.Get("Contact No.") then;
                            if PAGE.RunModal(0, Cont) = ACTION::LookupOK then begin
                                Validate("Contact No.", Cont."No.");
                                CurrPage.Update;
                            end;
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        ContactNoOnAfterValidate;
                    end;
                }
                field("Contact Name"; "Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = false;
                    ToolTip = 'Specifies the name of the contact to which this task has been assigned.';
                }
                field("Contact Company Name"; "Contact Company Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = false;
                    ToolTip = 'Specifies the name of the company for which the contact involved in the task works.';
                }
                field("Team Code"; "Team Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code of the team to which the task is assigned.';

                    trigger OnValidate()
                    begin
                        TeamCodeOnAfterValidate;
                    end;
                }
                field("Completed By"; "Completed By")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = CompletedByEditable;
                    Enabled = CompletedByEnable;
                    ToolTip = 'Specifies the salesperson who completed this team task.';

                    trigger OnValidate()
                    begin
                        SwitchCardControls
                    end;
                }
                field(Status; Status)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the status of the task. There are five options: Not Started, In Progress, Completed, Waiting and Postponed.';
                }
                field(Priority; Priority)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the priority of the task.';
                }
                field(TypeSaaS; Type)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Type';
                    OptionCaption = ' ,,Phone Call';
                    ToolTip = 'Specifies the type of the task.';
                    Visible = IsSoftwareAsAService;

                    trigger OnValidate()
                    begin
                        TypeOnAfterValidate;
                    end;
                }
                field(TypeOnPrem; Type)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Type';
                    OptionCaption = ' ,Meeting,Phone Call';
                    ToolTip = 'Specifies the type of the task.';
                    Visible = NOT IsSoftwareAsAService;

                    trigger OnValidate()
                    begin
                        TypeOnAfterValidate;
                    end;
                }
                field(AllDayEvent; "All Day Event")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'All Day Event';
                    Enabled = AllDayEventEnable;
                    ToolTip = 'Specifies that the task of the Meeting type is an all-day event, which is an activity that lasts 24 hours or longer.';

                    trigger OnValidate()
                    begin
                        AllDayEventOnAfterValidate;
                    end;
                }
                field(Date; Date)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the date when the task should be started. There are certain rules for how dates should be entered found in How to: Enter Dates and Times.';
                }
                field(StartTime; "Start Time")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = StartTimeEnable;
                    ToolTip = 'Specifies the time when the task of the Meeting type should be started.';
                }
                field(Duration; Duration)
                {
                    ApplicationArea = RelationshipMgmt;
                    BlankZero = true;
                    Enabled = DurationEnable;
                    ToolTip = 'Specifies the duration of the task of the Meeting type.';
                }
                field(EndingDate; "Ending Date")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Ending Date';
                    ToolTip = 'Specifies the date of when the task should end. There are certain rules for how dates should be entered. For more information, see How to: Enter Dates and Times.';
                }
                field(EndingTime; "Ending Time")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Ending Time';
                    Enabled = EndingTimeEnable;
                    ToolTip = 'Specifies the time of when the task of the Meeting type should end.';
                }
                field(Canceled; Canceled)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that the task has been canceled.';

                    trigger OnValidate()
                    begin
                        SwitchCardControls
                    end;
                }
                field(Closed; Closed)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that the task is closed.';

                    trigger OnValidate()
                    begin
                        SwitchCardControls
                    end;
                }
                field("Date Closed"; "Date Closed")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the date the task was closed.';
                }
            }
            group("Related Activities")
            {
                Caption = 'Related Activities';
                field("Campaign No."; "Campaign No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the campaign to which the task is linked.';

                    trigger OnValidate()
                    begin
                        CampaignNoOnAfterValidate;
                    end;
                }
                field("Campaign Description"; "Campaign Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = false;
                    ToolTip = 'Specifies the description of the campaign to which the task is linked.';
                }
                field("Opportunity No."; "Opportunity No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the opportunity to which the task is linked.';

                    trigger OnValidate()
                    begin
                        OpportunityNoOnAfterValidate;
                    end;
                }
                field("Opportunity Description"; "Opportunity Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = false;
                    ToolTip = 'Specifies a description of the opportunity related to the task. The description is copied from the opportunity card.';
                }
            }
            group(Recurring)
            {
                Caption = 'Recurring';
                field(Control39; Recurring)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that the task occurs periodically.';

                    trigger OnValidate()
                    begin
                        RecurringOnPush;
                    end;
                }
                field("Recurring Date Interval"; "Recurring Date Interval")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = RecurringDateIntervalEditable;
                    Enabled = RecurringDateIntervalEnable;
                    ToolTip = 'Specifies the date formula to assign automatically a recurring task to a salesperson or team.';
                }
                field("Calc. Due Date From"; "Calc. Due Date From")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = CalcDueDateFromEditable;
                    Enabled = CalcDueDateFromEnable;
                    ToolTip = 'Specifies the date to use to calculate the date on which the next task should be completed.';
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Ta&sk")
            {
                Caption = 'Ta&sk';
                Image = Task;
                action("Co&mment")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mment';
                    Image = ViewComments;
                    RunObject = Page "Rlshp. Mgt. Comment Sheet";
                    RunPageLink = "Table Name" = CONST("To-do"),
                                  "No." = FIELD("Organizer To-do No."),
                                  "Sub No." = CONST(0);
                    ToolTip = 'View or add comments.';
                }
                action("Interaction Log E&ntries")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Interaction Log E&ntries';
                    Image = InteractionLog;
                    RunObject = Page "Interaction Log Entries";
                    RunPageLink = "To-do No." = FIELD("Organizer To-do No.");
                    RunPageView = SORTING("To-do No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View interaction log entries for the task.';
                }
                action("Postponed &Interactions")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Postponed &Interactions';
                    Image = PostponedInteractions;
                    RunObject = Page "Postponed Interactions";
                    RunPageLink = "To-do No." = FIELD("Organizer To-do No.");
                    RunPageView = SORTING("To-do No.");
                    ToolTip = 'View postponed interactions for the task.';
                }
                action("A&ttendee Scheduling")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'A&ttendee Scheduling';
                    Image = ProfileCalender;
                    ToolTip = 'View the status of a scheduled meeting.';

                    trigger OnAction()
                    begin
                        if Type <> Type::Meeting then
                            Error(CannotSelectAttendeesErr, Format(Type));

                        PAGE.RunModal(PAGE::"Attendee Scheduling", Rec);
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Assign Activities")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Assign Activities';
                    Image = Allocate;
                    ToolTip = 'View all the tasks that have been assigned to salespeople and teams. A task can be organizing meetings, making phone calls, and so on.';

                    trigger OnAction()
                    var
                        TempTask: Record "To-do" temporary;
                    begin
                        TempTask.AssignActivityFromTask(Rec)
                    end;
                }
                action(MakePhoneCall)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Make &Phone Call';
                    Image = Calls;
                    ToolTip = 'Call the selected contact.';

                    trigger OnAction()
                    var
                        TempSegmentLine: Record "Segment Line" temporary;
                    begin
                        if "Contact No." = '' then begin
                            if (Type = Type::Meeting) and ("Team Code" = '') then
                                Error(MakePhoneCallIsNotAvailableErr);
                            Error(MustAssignContactErr);
                        end;
                        TempSegmentLine."To-do No." := "No.";
                        TempSegmentLine."Contact No." := "Contact No.";
                        TempSegmentLine."Contact Company No." := "Contact Company No.";
                        TempSegmentLine."Campaign No." := "Campaign No.";
                        TempSegmentLine."Salesperson Code" := "Salesperson Code";
                        TempSegmentLine.CreatePhoneCall;
                    end;
                }
            }
            action("&Create Task")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = '&Create Task';
                Image = NewToDo;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Create a new task.';

                trigger OnAction()
                var
                    TempTask: Record "To-do" temporary;
                begin
                    TempTask.CreateTaskFromTask(Rec);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SwitchCardControls;
        if "No." <> "Organizer To-do No." then
            CurrPage.Editable := false
        else
            CurrPage.Editable := true;
        SetRecurringEditable;
        EnableFields;
        ContactNoOnFormat(Format("Contact No."));
    end;

    trigger OnInit()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        CalcDueDateFromEnable := true;
        RecurringDateIntervalEnable := true;
        CompletedByEnable := true;
        AttendeesAcceptedNoEnable := true;
        NoOfAttendeesEnable := true;
        AllDayEventEnable := true;
        LocationEnable := true;
        DurationEnable := true;
        EndingTimeEnable := true;
        StartTimeEnable := true;
        CompletedByEditable := true;
        CalcDueDateFromEditable := true;
        RecurringDateIntervalEditable := true;
        ContactNoEditable := true;
        IsSoftwareAsAService := EnvironmentInfo.IsSaaS;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if ("Team Code" = '') and ("Salesperson Code" = '') then
            Error(
              Text000, TableCaption, FieldCaption("Salesperson Code"), FieldCaption("Team Code"));

        if (Type = Type::Meeting) and (not "All Day Event") then begin
            if "Start Time" = 0T then
                Error(Text002, TableCaption, Type, FieldCaption("Start Time"));
            if Duration = 0 then
                Error(Text002, TableCaption, Type, FieldCaption(Duration));
        end;
    end;

    var
        Text000: Label 'The %1 will always have either the %2 or %3 assigned.';
        Text002: Label 'The %1 of the %2 type must always have the %3 assigned.';
        CannotSelectAttendeesErr: Label 'You cannot select attendees for a task of the ''%1'' type.', Comment = '%1 = Task Type';
        MakePhoneCallIsNotAvailableErr: Label 'The Make Phone Call function for this task is available only in the Attendee Scheduling window.';
        MustAssignContactErr: Label 'You must assign a contact to this task before you can use the Make Phone Call function.';
        MultipleTxt: Label '(Multiple)';
        [InDataSet]
        ContactNoEditable: Boolean;
        [InDataSet]
        RecurringDateIntervalEditable: Boolean;
        [InDataSet]
        CalcDueDateFromEditable: Boolean;
        [InDataSet]
        CompletedByEditable: Boolean;
        [InDataSet]
        StartTimeEnable: Boolean;
        [InDataSet]
        EndingTimeEnable: Boolean;
        [InDataSet]
        DurationEnable: Boolean;
        [InDataSet]
        LocationEnable: Boolean;
        [InDataSet]
        AllDayEventEnable: Boolean;
        [InDataSet]
        NoOfAttendeesEnable: Boolean;
        [InDataSet]
        AttendeesAcceptedNoEnable: Boolean;
        [InDataSet]
        CompletedByEnable: Boolean;
        [InDataSet]
        RecurringDateIntervalEnable: Boolean;
        [InDataSet]
        CalcDueDateFromEnable: Boolean;
        IsSoftwareAsAService: Boolean;

    procedure SetRecurringEditable()
    begin
        RecurringDateIntervalEditable := Recurring;
        CalcDueDateFromEditable := Recurring;
    end;

    local procedure EnableFields()
    begin
        RecurringDateIntervalEnable := Recurring;
        CalcDueDateFromEnable := Recurring;

        if not Recurring then begin
            Evaluate("Recurring Date Interval", '');
            Clear("Calc. Due Date From");
        end;

        if Type = Type::Meeting then begin
            StartTimeEnable := not "All Day Event";
            EndingTimeEnable := not "All Day Event";
            DurationEnable := not "All Day Event";
            LocationEnable := true;
            AllDayEventEnable := true;
        end else begin
            StartTimeEnable := false;
            EndingTimeEnable := false;
            LocationEnable := false;
            DurationEnable := false;
            AllDayEventEnable := false;
        end;

        GetEndDateTime;
    end;

    local procedure SwitchCardControls()
    begin
        if Type = Type::Meeting then begin
            ContactNoEditable := false;

            NoOfAttendeesEnable := true;
            AttendeesAcceptedNoEnable := true;
        end else begin
            ContactNoEditable := true;

            NoOfAttendeesEnable := false;
            AttendeesAcceptedNoEnable := false;
        end;
        if "Team Code" = '' then
            CompletedByEnable := false
        else begin
            CompletedByEnable := true;
            CompletedByEditable := not Closed
        end
    end;

    local procedure TeamCodeOnAfterValidate()
    begin
        SwitchCardControls;
        CalcFields(
          "No. of Attendees",
          "Attendees Accepted No.",
          "Contact Name",
          "Contact Company Name",
          "Campaign Description",
          "Opportunity Description")
    end;

    local procedure ContactNoOnAfterValidate()
    begin
        CalcFields("Contact Name", "Contact Company Name");
    end;

    local procedure TypeOnAfterValidate()
    begin
        EnableFields;
    end;

    local procedure AllDayEventOnAfterValidate()
    begin
        EnableFields;
    end;

    local procedure SalespersonCodeOnAfterValidate()
    begin
        SwitchCardControls;
        CalcFields(
          "No. of Attendees",
          "Attendees Accepted No.",
          "Contact Name",
          "Contact Company Name",
          "Campaign Description",
          "Opportunity Description");
    end;

    local procedure CampaignNoOnAfterValidate()
    begin
        CalcFields("Campaign Description");
    end;

    local procedure OpportunityNoOnAfterValidate()
    begin
        CalcFields("Opportunity Description");
    end;

    local procedure RecurringOnPush()
    begin
        SetRecurringEditable;
    end;

    local procedure ContactNoOnFormat(Text: Text[1024])
    begin
        if Type = Type::Meeting then
            Text := MultipleTxt;
    end;
}

