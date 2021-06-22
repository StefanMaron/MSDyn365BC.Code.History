page 9056 "Warehouse Worker Activities"
{
    Caption = 'Activities';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Warehouse Worker WMS Cue";

    layout
    {
        area(content)
        {
            cuegroup(Outbound)
            {
                Caption = 'Outbound';
                field("Unassigned Picks"; "Unassigned Picks")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Warehouse Picks";
                    ToolTip = 'Specifies the number of unassigned picks that are displayed in the Warehouse Worker WMS Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("My Picks"; "My Picks")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Warehouse Picks";
                    ToolTip = 'Specifies the number of picks that are displayed in the Warehouse Worker WMS Cue on the Role Center. The documents are filtered by today''s date.';
                }

                actions
                {
                    action("Edit Pick Worksheet")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Edit Pick Worksheet';
                        RunObject = Page "Pick Worksheet";
                        ToolTip = 'Plan and organize different kinds of picks, including picks with lines from several orders or assignment of picks to particular employees.';
                    }
                }
            }
            cuegroup(Inbound)
            {
                Caption = 'Inbound';
                field("Unassigned Put-aways"; "Unassigned Put-aways")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Warehouse Put-aways";
                    ToolTip = 'Specifies the number of unassigned put-always that are displayed in the Warehouse Worker WMS Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("My Put-aways"; "My Put-aways")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Warehouse Put-aways";
                    ToolTip = 'Specifies the number of put-always that are displayed in the Warehouse Worker WMS Cue on the Role Center. The documents are filtered by today''s date.';
                }

                actions
                {
                    action("Edit Put-away Worksheet")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Edit Put-away Worksheet';
                        RunObject = Page "Put-away Worksheet";
                        ToolTip = 'Plan and organize different kinds of put-aways, including put-aways with lines from several orders. You can also assign the planned put-aways to particular warehouse employees.';
                    }
                }
            }
            cuegroup(Internal)
            {
                Caption = 'Internal';
                field("Unassigned Movements"; "Unassigned Movements")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Warehouse Movements";
                    ToolTip = 'Specifies the number of unassigned movements that are displayed in the Warehouse Worker WMS Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("My Movements"; "My Movements")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Warehouse Movements";
                    ToolTip = 'Specifies the number of movements that are displayed in the Warehouse Worker WMS Cue on the Role Center. The documents are filtered by today''s date.';
                }

                actions
                {
                    action("Edit Movement Worksheet")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Edit Movement Worksheet';
                        RunObject = Page "Movement Worksheet";
                        ToolTip = 'Prepare to move items between bins within the warehouse.';
                    }
                    action("Edit Warehouse Item Journal")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Edit Warehouse Item Journal';
                        RunObject = Page "Whse. Item Journal";
                        ToolTip = 'Adjust the quantity of an item in a particular bin or bins. For instance, you might find some items in a bin that are not registered in the system, or you might not be able to pick the quantity needed because there are fewer items in a bin than was calculated by the program. The bin is then updated to correspond to the actual quantity in the bin. In addition, it creates a balancing quantity in the adjustment bin, for synchronization with item ledger entries, which you can then post with an item journal.';
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

        SetRange("User ID Filter", UserId);

        LocationCode := WhseWMSCue.GetEmployeeLocation(UserId);
        SetFilter("Location Filter", LocationCode);
    end;

    var
        WhseWMSCue: Record "Warehouse WMS Cue";
        UserTaskManagement: Codeunit "User Task Management";
        LocationCode: Text[1024];
}

