page 5096 "Task List"
{
    Caption = 'Task List';
    CardPageID = "Task Card";
    DataCaptionExpression = Caption;
    Editable = false;
    PageType = List;
    SourceTable = "To-do";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field(Closed; Closed)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that the task is closed.';
                }
                field(Date; Date)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the date when the task should be started. There are certain rules for how dates should be entered found in How to: Enter Dates and Times.';
                }
                field(Type; Type)
                {
                    ApplicationArea = RelationshipMgmt;
                    OptionCaption = ' ,Meeting,Phone Call';
                    ToolTip = 'Specifies the type of the task.';
                }
                field(Description; Description)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the description of the task.';
                }
                field(Priority; Priority)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the priority of the task.';
                }
                field(Status; Status)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the status of the task. There are five options: Not Started, In Progress, Completed, Waiting and Postponed.';
                }
                field("Organizer To-do No."; "Organizer To-do No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the organizer''s task. The field is not editable.';
                }
                field("Date Closed"; "Date Closed")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the date the task was closed.';
                }
                field(Canceled; Canceled)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that the task has been canceled.';
                }
                field(Comment; Comment)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies that a comment has been assigned to the task.';
                }
                field("Contact No."; "Contact No.")
                {
                    ApplicationArea = RelationshipMgmt;
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
                            if PAGE.RunModal(0, Cont) = ACTION::LookupOK then;
                        end;
                    end;
                }
                field("Contact Company No."; "Contact Company No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the contact number of the company for which the contact involved in the task works.';
                    Visible = false;
                }
                field("Salesperson Code"; "Salesperson Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code of the salesperson assigned to the task.';
                }
                field("Team Code"; "Team Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code of the team to which the task is assigned.';
                }
                field("Campaign No."; "Campaign No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the campaign to which the task is linked.';
                }
                field("Opportunity No."; "Opportunity No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the opportunity to which the task is linked.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
            }
            group(Control55)
            {
                ShowCaption = false;
                field("Contact Name"; "Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Contact Name';
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the contact to which this task has been assigned.';
                }
                field("Contact Company Name"; "Contact Company Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the company for which the contact involved in the task works.';
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
            group(Task)
            {
                Caption = 'Task';
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
                    var
                        Task: Record "To-do";
                    begin
                        Task.Get("Organizer To-do No.");
                        PAGE.RunModal(PAGE::"Attendee Scheduling", Task);
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
                        TempTask.AssignActivityFromTask(Rec);
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
                        ContactNo: Code[10];
                        ContCompanyNo: Code[10];
                    begin
                        if "Contact No." <> '' then
                            ContactNo := "Contact No."
                        else
                            ContactNo := GetFilter("Contact No.");
                        if "Contact Company No." <> '' then
                            ContCompanyNo := "Contact Company No."
                        else
                            ContCompanyNo := GetFilter("Contact Company No.");
                        if ContactNo = '' then begin
                            if (Type = Type::Meeting) and ("Team Code" = '') then
                                Error(Text004);
                            Error(Text005);
                        end;
                        TempSegmentLine."To-do No." := "No.";
                        TempSegmentLine."Contact No." := ContactNo;
                        TempSegmentLine."Contact Company No." := ContCompanyNo;
                        TempSegmentLine."Campaign No." := "Campaign No.";
                        TempSegmentLine."Salesperson Code" := "Salesperson Code";
                        TempSegmentLine.CreatePhoneCall;
                    end;
                }
                action("Delete Canceled Tasks")
                {
                    ApplicationArea = All;
                    Caption = 'Delete Canceled Tasks';
                    Image = Delete;
                    RunObject = Report "Delete Tasks";
                    ToolTip = 'Find and delete canceled tasks.';
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
            action("Edit Organizer Task")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Edit Organizer Task';
                Image = Edit;
                Promoted = false;
                RunObject = Page "Task Card";
                RunPageLink = "No." = FIELD("Organizer To-do No.");
                ToolTip = 'View general information about the task such as type, description, priority and status of the task, as well as the salesperson or team the task is assigned to.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CalcFields("Contact Name", "Contact Company Name");
    end;

    trigger OnAfterGetRecord()
    begin
        ContactNoOnFormat(Format("Contact No."));
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        RecordsFound := Find(Which);
        exit(RecordsFound);
    end;

    var
        Cont: Record Contact;
        Contact1: Record Contact;
        Salesperson: Record "Salesperson/Purchaser";
        Campaign: Record Campaign;
        Team: Record Team;
        Opp: Record Opportunity;
        SegHeader: Record "Segment Header";
        RecordsFound: Boolean;
        Text000: Label '(Multiple)';
        Text001: Label 'untitled';
        Text004: Label 'The Make Phone Call function for this task is available only on the Attendee Scheduling window.';
        Text005: Label 'You must select a task with a contact assigned to it before you can use the Make Phone Call function.';

    procedure Caption(): Text
    var
        CaptionStr: Text;
    begin
        if Cont.Get(GetFilter("Contact Company No.")) then begin
            Contact1.Get(GetFilter("Contact Company No."));
            if Contact1."No." <> Cont."No." then
                CaptionStr := CopyStr(Cont."No." + ' ' + Cont.Name, 1, MaxStrLen(CaptionStr));
        end;
        if Cont.Get(GetFilter("Contact No.")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + Cont."No." + ' ' + Cont.Name, 1, MaxStrLen(CaptionStr));
        if Salesperson.Get(GetFilter("Salesperson Code")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + Salesperson.Code + ' ' + Salesperson.Name, 1, MaxStrLen(CaptionStr));
        if Team.Get(GetFilter("Team Code")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + Team.Code + ' ' + Team.Name, 1, MaxStrLen(CaptionStr));
        if Campaign.Get(GetFilter("Campaign No.")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + Campaign."No." + ' ' + Campaign.Description, 1, MaxStrLen(CaptionStr));
        if Opp.Get(GetFilter("Opportunity No.")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + Opp."No." + ' ' + Opp.Description, 1, MaxStrLen(CaptionStr));
        if SegHeader.Get(GetFilter("Segment No.")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + SegHeader."No." + ' ' + SegHeader.Description, 1, MaxStrLen(CaptionStr));
        if CaptionStr = '' then
            CaptionStr := Text001;

        exit(CaptionStr);
    end;

    local procedure ContactNoOnFormat(Text: Text[1024])
    begin
        if Type = Type::Meeting then
            Text := Text000;
    end;
}

