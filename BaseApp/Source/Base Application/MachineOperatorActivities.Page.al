page 9047 "Machine Operator Activities"
{
    Caption = 'Activities';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Manufacturing Cue";

    layout
    {
        area(content)
        {
            cuegroup("Production Orders")
            {
                Caption = 'Production Orders';
                field("Released Prod. Orders - All"; "Released Prod. Orders - All")
                {
                    ApplicationArea = Manufacturing;
                    DrillDownPageID = "Released Production Orders";
                    ToolTip = 'Specifies the number of released production orders that are displayed in the Manufacturing Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("Rlsd. Prod. Orders Until Today"; "Rlsd. Prod. Orders Until Today")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Released Prod. Orders Until Today';
                    DrillDownPageID = "Released Production Orders";
                    ToolTip = 'Specifies the number of released production orders that are displayed in the Manufacturing Cue on the Role Center. The documents are filtered by today''s date.';
                }

                actions
                {
                    action("Consumption Journal")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Consumption Journal';
                        RunObject = Page "Consumption Journal";
                        ToolTip = 'Post the consumption of material as operations are performed.';
                    }
                    action("Output Journal")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Output Journal';
                        RunObject = Page "Output Journal";
                        ToolTip = 'Post finished end items and time spent in production. ';
                    }
                }
            }
            cuegroup(Operations)
            {
                Caption = 'Operations';
                field("Prod. Orders Routings-in Queue"; "Prod. Orders Routings-in Queue")
                {
                    ApplicationArea = Manufacturing;
                    DrillDownPageID = "Prod. Order Routing";
                    ToolTip = 'Specifies the number of production order routings in queue that are displayed in the Manufacturing Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("Prod. Orders Routings-in Prog."; "Prod. Orders Routings-in Prog.")
                {
                    ApplicationArea = Manufacturing;
                    DrillDownPageID = "Prod. Order Routing";
                    ToolTip = 'Specifies the number of inactive service orders that are displayed in the Service Cue on the Role Center. The documents are filtered by today''s date.';
                }

                actions
                {
                    action("Register Absence - Machine Center")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Register Absence - Machine Center';
                        RunObject = Report "Reg. Abs. (from Machine Ctr.)";
                        ToolTip = 'Register planned absences at a machine center. The planned absence can be registered for both human and machine resources. You can register changes in the available resources in the Registered Absence table. When the batch job has been completed, you can see the result in the Registered Absences window.';
                    }
                    action("Register Absence - Work Center")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Register Absence - Work Center';
                        RunObject = Report "Reg. Abs. (from Work Center)";
                        ToolTip = 'Register planned absences at a machine center. The planned absence can be registered for both human and machine resources. You can register changes in the available resources in the Registered Absence table. When the batch job has been completed, you can see the result in the Registered Absences window.';
                    }
                    action("Prod. Order - Job Card")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Prod. Order - Job Card';
                        RunObject = Report "Prod. Order - Job Card";
                        ToolTip = 'View a list of the work in progress of a production order. Output, Scrapped Quantity and Production Lead Time are shown or printed depending on the operation.';
                    }
                }
            }
            cuegroup("Warehouse Documents")
            {
                Caption = 'Warehouse Documents';
                field("Invt. Picks to Production"; "Invt. Picks to Production")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Inventory Picks";
                    ToolTip = 'Specifies the number of inventory picks that are displayed in the Manufacturing Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("Invt. Put-aways from Prod."; "Invt. Put-aways from Prod.")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Inventory Put-aways";
                    ToolTip = 'Specifies the number of inventory put-always from production that are displayed in the Manufacturing Cue on the Role Center. The documents are filtered by today''s date.';
                }

                actions
                {
                    action("New Inventory Pick")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'New Inventory Pick';
                        RunObject = Page "Inventory Pick";
                        RunPageMode = Create;
                        ToolTip = 'Prepare to pick items in a basic warehouse configuration.';
                    }
                    action("New Inventory Put-away")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'New Inventory Put-away';
                        RunObject = Page "Inventory Put-away";
                        RunPageMode = Create;
                        ToolTip = 'Prepare to put items away in a basic warehouse configuration.';
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

        SetFilter("Date Filter", '<=%1', WorkDate);
        SetFilter("User ID Filter", UserId);
    end;

    var
        UserTaskManagement: Codeunit "User Task Management";
}

