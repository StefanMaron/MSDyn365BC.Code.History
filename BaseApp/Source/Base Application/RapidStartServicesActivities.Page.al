page 9075 "RapidStart Services Activities"
{
    Caption = 'Activities';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "RapidStart Services Cue";

    layout
    {
        area(content)
        {
            cuegroup(Tables)
            {
                Caption = 'Tables';
                field(Promoted; Promoted)
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Config. Tables";
                    ToolTip = 'Specifies the number of configuration tables that have been promoted. The documents are filtered by today''s date.';
                }
                field("Not Started"; "Not Started")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Config. Tables";
                    ToolTip = 'Specifies the number of configuration tables that have not been started. The documents are filtered by today''s date.';
                }
                field("In Progress"; "In Progress")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Config. Tables";
                    ToolTip = 'Specifies the number of configuration tables that are in progress. The documents are filtered by today''s date.';
                }
                field(Completed; Completed)
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Config. Tables";
                    ToolTip = 'Specifies the number of configuration tables that have been completed. The documents are filtered by today''s date.';
                }
                field(Ignored; Ignored)
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Config. Tables";
                    ToolTip = 'Specifies the number of configuration tables that you have designated to be ignored. The documents are filtered by today''s date.';
                }
                field(Blocked; Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Config. Tables";
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
            }
            cuegroup("My User Tasks")
            {
                Caption = 'My User Tasks';
                field("UserTaskManagement.GetMyPendingUserTasksCount"; UserTaskManagement.GetMyPendingUserTasksCount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pending User Tasks';
                    Image = Checklist;
                    ToolTip = 'Specifies the number of pending tasks that are assigned to you or to a group that you are a member of.';

                    trigger OnDrillDown()
                    var
                        UserTaskList: Page "User Task List";
                    begin
                        UserTaskList.SetPageToShowMyPendingUserTasks;
                        UserTaskList.Run;
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;

        SetFilter("User ID Filter", UserId);
    end;

    var
        UserTaskManagement: Codeunit "User Task Management";
}

