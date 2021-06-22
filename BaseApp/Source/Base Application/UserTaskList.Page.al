page 1170 "User Task List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'User Tasks';
    CardPageID = "User Task Card";
    DelayedInsert = true;
    DeleteAllowed = true;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    ODataKeyFields = ID;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "User Task";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Title; Title)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the title of the task.';
                }
                field("Due DateTime"; "Due DateTime")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies when the task must be completed.';
                }
                field(Priority; Priority)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the priority of the task.';
                }
                field("Percent Complete"; "Percent Complete")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the progress of the task.';
                }
                field("Assigned To User Name"; "Assigned To User Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies who the task is assigned to.';
                }
                field("User Task Group Assigned To"; "User Task Group Assigned To")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User Task Group';
                    ToolTip = 'Specifies the group if the task has been assigned to a group of people.';
                }
                field("Created DateTime"; "Created DateTime")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the task was created.';
                    Visible = false;
                }
                field("Completed DateTime"; "Completed DateTime")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the task was completed.';
                    Visible = false;
                }
                field("Start DateTime"; "Start DateTime")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the task must start.';
                    Visible = false;
                }
                field("Created By User Name"; "Created By User Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies who created the task.';
                    Visible = false;
                }
                field("Completed By User Name"; "Completed By User Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies who completed the task.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(creation)
        {
            action("User Task Groups")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User Task Groups';
                Image = Users;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = Page "User Task Groups";
                ToolTip = 'Add or modify groups of users that you can assign user tasks to in this company.';
            }
            action("Mark Complete")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Mark as Completed';
                Image = CheckList;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Indicate that the task is completed. The % Complete field is set to 100.';

                trigger OnAction()
                var
                    UserTask: Record "User Task";
                begin
                    CurrPage.SetSelectionFilter(UserTask);
                    if UserTask.FindSet(true) then
                        repeat
                            UserTask.SetCompleted;
                            UserTask.Modify();
                        until UserTask.Next = 0;
                end;
            }
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
        }
        area(processing)
        {
            action("Delete User Tasks")
            {
                ApplicationArea = All;
                Caption = 'Delete User Tasks';
                Image = Delete;
                RunObject = Report "User Task Utility";
                ToolTip = 'Find and delete user tasks.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        StyleTxt := SetStyle;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        FilterUserTasks;
        exit(Find(Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        FilterUserTasks;
        exit(Next(Steps));
    end;

    trigger OnOpenPage()
    var
        ShouldOpenToViewPendingTasks: Boolean;
    begin
        if Evaluate(ShouldOpenToViewPendingTasks, GetFilter(ShouldShowPendingTasks)) and ShouldOpenToViewPendingTasks then
            SetPageToShowMyPendingUserTasks;
    end;

    var
        UserTaskManagement: Codeunit "User Task Management";
        DueDateFilterOptions: Option "NONE",TODAY,THIS_WEEK;
        StyleTxt: Text;
        IsShowingMyPendingTasks: Boolean;

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

    [ServiceEnabled]
    procedure SetComplete()
    begin
        SetCompleted;
        Modify;
    end;

    local procedure FilterUserTasks()
    begin
        if IsShowingMyPendingTasks then
            UserTaskManagement.SetFiltersToShowMyUserTasks(Rec, DueDateFilterOptions::NONE);
    end;

    procedure SetPageToShowMyPendingUserTasks()
    begin
        // This functions sets up this page to show pending tasks assigned to current user
        IsShowingMyPendingTasks := true;
    end;
}

