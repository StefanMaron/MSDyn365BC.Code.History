page 9067 "Resource Manager Activities"
{
    Caption = 'Activities';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Job Cue";

    layout
    {
        area(content)
        {
            cuegroup(Allocation)
            {
                Caption = 'Allocation';
                field("Available Resources"; "Available Resources")
                {
                    ApplicationArea = Jobs;
                    DrillDownPageID = "Resource List";
                    ToolTip = 'Specifies the number of available resources that are displayed in the Job Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("Jobs w/o Resource"; "Jobs w/o Resource")
                {
                    ApplicationArea = Jobs;
                    DrillDownPageID = "Job List";
                    ToolTip = 'Specifies the number of jobs without an assigned resource that are displayed in the Job Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("Unassigned Resource Groups"; "Unassigned Resource Groups")
                {
                    ApplicationArea = Jobs;
                    DrillDownPageID = "Resource Groups";
                    ToolTip = 'Specifies the number of unassigned resource groups that are displayed in the Job Cue on the Role Center. The documents are filtered by today''s date.';
                }

                actions
                {
                    action("Resource Capacity")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Resource Capacity';
                        RunObject = Page "Resource Capacity";
                        ToolTip = 'View the capacity of the resource.';
                    }
                    action("Resource Group Capacity")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Resource Group Capacity';
                        RunObject = Page "Res. Group Capacity";
                        ToolTip = 'View the capacity of resource groups.';
                    }
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

        SetRange("Date Filter", WorkDate, WorkDate);
        SetFilter("User ID Filter", UserId);
    end;

    var
        UserTaskManagement: Codeunit "User Task Management";
}

