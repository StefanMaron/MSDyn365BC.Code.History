page 9053 "WMS Ship & Receive Activities"
{
    Caption = 'Activities';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Warehouse WMS Cue";

    layout
    {
        area(content)
        {
            cuegroup("Outbound - Today")
            {
                Caption = 'Outbound - Today';
                field("Released Sales Orders - Today"; "Released Sales Orders - Today")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Sales Order List";
                    ToolTip = 'Specifies the number of released sales orders that are displayed in the Warehouse WMS Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("Shipments - Today"; "Shipments - Today")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Warehouse Shipment List";
                    ToolTip = 'Specifies the number of shipments that are displayed in the Warehouse WMS Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("Picked Shipments - Today"; "Picked Shipments - Today")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Warehouse Shipment List";
                    ToolTip = 'Specifies the number of picked shipments that are displayed in the Warehouse WMS Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("Posted Shipments - Today"; "Posted Shipments - Today")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Posted Whse. Shipment List";
                    ToolTip = 'Specifies the number of posted shipments that are displayed in the Warehouse WMS Cue on the Role Center. The documents are filtered by today''s date.';
                }

                actions
                {
                    action("New Warehouse Shipment")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'New Warehouse Shipment';
                        RunObject = Page "Warehouse Shipment";
                        RunPageMode = Create;
                        ToolTip = 'Ship items according to an advanced warehouse configuration.';
                    }
                    action("New Transfer Order")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Transfer Order';
                        RunObject = Page "Transfer Order";
                        RunPageMode = Create;
                        ToolTip = 'Move items from one warehouse location to another.';
                    }
                }
            }
            cuegroup("Inbound - Today")
            {
                Caption = 'Inbound - Today';
                field("Expected Purchase Orders"; "Expected Purchase Orders")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Purchase Order List";
                    ToolTip = 'Specifies the number of expected purchase orders that are displayed in the Warehouse WMS Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field(Arrivals; Arrivals)
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Warehouse Receipts";
                    ToolTip = 'Specifies the number of arrivals that are displayed in the Warehouse WMS Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("Posted Receipts - Today"; "Posted Receipts - Today")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Posted Whse. Receipt List";
                    ToolTip = 'Specifies the number of posted receipts that are displayed in the Warehouse WMS Cue on the Role Center. The documents are filtered by today''s date.';
                }

                actions
                {
                    action("New Purchase Order")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Purchase Order';
                        RunObject = Page "Purchase Order";
                        RunPageMode = Create;
                        ToolTip = 'Purchase goods or services from a vendor.';
                    }
                    action("New Whse. Receipt")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'New Whse. Receipt';
                        RunObject = Page "Warehouse Receipt";
                        RunPageMode = Create;
                        ToolTip = 'Receive items according to an advanced warehouse configuration. ';
                    }
                }
            }
            cuegroup(Internal)
            {
                Caption = 'Internal';
                field("Picks - All"; "Picks - All")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Warehouse Picks";
                    ToolTip = 'Specifies the number of picks that are displayed in the Warehouse WMS Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("Put-aways - All"; "Put-aways - All")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Warehouse Put-aways";
                    ToolTip = 'Specifies the number of put-always that are displayed in the Warehouse WMS Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("Movements - All"; "Movements - All")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Warehouse Movements";
                    ToolTip = 'Specifies the number of movements that are displayed in the Warehouse WMS Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("Registered Picks - Today"; "Registered Picks - Today")
                {
                    ApplicationArea = Warehouse;
                    DrillDownPageID = "Registered Whse. Picks";
                    ToolTip = 'Specifies the number of registered picks that are displayed in the Warehouse WMS Cue on the Role Center. The documents are filtered by today''s date.';
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
                    action("Edit Pick Worksheet")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Edit Pick Worksheet';
                        RunObject = Page "Pick Worksheet";
                        ToolTip = 'Plan and organize different kinds of picks, including picks with lines from several orders or assignment of picks to particular employees.';
                    }
                    action("Edit Movement Worksheet")
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Edit Movement Worksheet';
                        RunObject = Page "Movement Worksheet";
                        ToolTip = 'Prepare to move items between bins within the warehouse.';
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

        SetRange("Date Filter", 0D, WorkDate);
        SetRange("Date Filter2", WorkDate, WorkDate);
        SetFilter("User ID Filter", UserId);

        LocationCode := GetEmployeeLocation(UserId);
        SetFilter("Location Filter", LocationCode);
    end;

    var
        UserTaskManagement: Codeunit "User Task Management";
        LocationCode: Text[1024];
}

