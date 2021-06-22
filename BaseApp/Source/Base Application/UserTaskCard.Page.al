page 1171 "User Task Card"
{
    Caption = 'User Task';
    PageType = Card;
    SourceTable = "User Task";

    layout
    {
        area(content)
        {
            group(General)
            {
                field(Title; Title)
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the title of the task.';
                }
                field(MultiLineTextControl; MultiLineTextControl)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Task Description';
                    MultiLine = true;
                    ToolTip = 'Specifies what the task is about.';

                    trigger OnValidate()
                    begin
                        SetDescription(MultiLineTextControl);
                    end;
                }
                field("Created By User Name"; "Created By User Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Enabled = false;
                    Importance = Additional;
                    ToolTip = 'Specifies who created the task.';
                }
                field("Created DateTime"; "Created DateTime")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies when the task was created.';
                }
            }
            group(Status)
            {
                Caption = 'Status';
                field("Assigned To User Name"; "Assigned To User Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies who the task is assigned to.';

                    trigger OnAssistEdit()
                    var
                        User: Record User;
                        Users: Page Users;
                    begin
                        if User.Get("Assigned To") then
                            Users.SetRecord(User);

                        Users.LookupMode := true;
                        if Users.RunModal = ACTION::LookupOK then begin
                            Users.GetRecord(User);
                            Validate("Assigned To", User."User Security ID");
                            CurrPage.Update(true);
                        end;
                    end;
                }
                field("User Task Group Assigned To"; "User Task Group Assigned To")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User Task Group';
                    ToolTip = 'Specifies the group if the task has been assigned to a group of people.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Due DateTime"; "Due DateTime")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the task must be completed.';
                }
                field("Percent Complete"; "Percent Complete")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the progress of the task.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Start DateTime"; "Start DateTime")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the task must start.';
                }
                field(Priority; Priority)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the priority of the task.';
                }
                field("Completed By User Name"; "Completed By User Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    Importance = Additional;
                    ToolTip = 'Specifies who completed the task.';

                    trigger OnAssistEdit()
                    var
                        User: Record User;
                        Users: Page Users;
                    begin
                        if User.Get("Completed By") then
                            Users.SetRecord(User);

                        Users.LookupMode := true;
                        if Users.RunModal = ACTION::LookupOK then begin
                            Users.GetRecord(User);
                            Validate("Completed By", User."User Security ID");
                            CurrPage.Update(true);
                        end;
                    end;
                }
                field("Completed DateTime"; "Completed DateTime")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies when the task was completed.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
            }
            group("Task Item")
            {
                Caption = 'Task Item';
                field("Object Type"; "Object Type")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    OptionCaption = ',,,Report,,,,,Page';
                    ToolTip = 'Specifies the type of window that the task opens.';

                    trigger OnValidate()
                    begin
                        // Clear out the values for object id if it exists.
                        if "Object ID" <> 0 then
                            "Object ID" := 0;
                    end;
                }
                field("Object ID"; "Object ID")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    CaptionClass = GetObjectTypeCaption;
                    Lookup = true;
                    ToolTip = 'Specifies the window that the task opens.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        AllObjWithCaption: Record AllObjWithCaption;
                        AllObjectsWithCaption: Page "All Objects with Caption";
                    begin
                        // If object type is empty then show both pages / reports in lookup
                        AllObjWithCaption.FilterGroup(2);
                        if "Object Type" = 0 then begin
                            AllObjWithCaption.SetFilter("Object Type", 'Page|Report');
                            AllObjWithCaption.SetFilter("Object Subtype", '%1|%2', '', 'List');
                        end else begin
                            if "Object Type" = AllObjWithCaption."Object Type"::Page then begin
                                AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Page);
                                AllObjWithCaption.SetRange("Object Subtype", 'List');
                            end else
                                AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Report);
                        end;
                        AllObjWithCaption.FilterGroup(0);

                        AllObjectsWithCaption.IsObjectTypeVisible(false);
                        AllObjectsWithCaption.SetTableView(AllObjWithCaption);

                        AllObjectsWithCaption.LookupMode := true;
                        if AllObjectsWithCaption.RunModal = ACTION::LookupOK then begin
                            AllObjectsWithCaption.GetRecord(AllObjWithCaption);
                            "Object ID" := AllObjWithCaption."Object ID";
                            "Object Type" := AllObjWithCaption."Object Type";
                        end;
                    end;

                    trigger OnValidate()
                    var
                        AllObjWithCaption: Record AllObjWithCaption;
                    begin
                        if "Object Type" = AllObjWithCaption."Object Type"::Page then begin
                            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Page);
                            AllObjWithCaption.SetRange("Object ID", "Object ID");
                            if AllObjWithCaption.FindFirst then
                                if AllObjWithCaption."Object Subtype" <> 'List' then
                                    Error(InvalidPageTypeErr);
                        end;
                    end;
                }
                field(ObjectName; DisplayObjectName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Resource Name';
                    Enabled = false;
                    ToolTip = 'Specifies the name of the resource that is assigned to the task.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Go To Task Item")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Go To Task Item';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Open the page or report that is associated with this task.';

                trigger OnAction()
                begin
                    RunReportOrPageLink;
                end;
            }
            action("Mark Completed")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Mark Completed';
                Enabled = IsMarkCompleteEnabled;
                Image = Completed;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Mark the task as completed.';

                trigger OnAction()
                begin
                    // Marks the current task as completed.
                    SetCompleted;
                    CurrPage.Update(true);
                end;
            }
            action(Recurrence)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Recurrence';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Make this a recurring task.';

                trigger OnAction()
                var
                    UserTaskRecurrence: Page "User Task Recurrence";
                begin
                    UserTaskRecurrence.SetInitialData(Rec);
                    UserTaskRecurrence.RunModal;
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        MultiLineTextControl := GetDescription;
        IsMarkCompleteEnabled := not IsCompleted;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        "Created By" := UserSecurityId;
        Validate("Created DateTime", CurrentDateTime);
        CalcFields("Created By User Name");

        Clear(MultiLineTextControl);
    end;

    trigger OnOpenPage()
    begin
        Reset;
    end;

    var
        MultiLineTextControl: Text;
        InvalidPageTypeErr: Label 'You must specify a list page.';
        IsMarkCompleteEnabled: Boolean;
        PageTok: Label 'Page';
        ReportTok: Label 'Report';

    local procedure DisplayObjectName(): Text
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        AllObjWithCaption.SetRange("Object Type", "Object Type");
        AllObjWithCaption.SetRange("Object ID", "Object ID");
        if AllObjWithCaption.FindFirst then
            exit(AllObjWithCaption."Object Name");
    end;

    local procedure RunReportOrPageLink()
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        if ("Object Type" = 0) or ("Object ID" = 0) then
            exit;
        if "Object Type" = AllObjWithCaption."Object Type"::Page then
            PAGE.Run("Object ID")
        else
            REPORT.Run("Object ID");
    end;

    local procedure GetObjectTypeCaption(): Text
    begin
        if "Object Type" = "Object Type"::Page then
            exit(PageTok);

        exit(ReportTok);
    end;
}

