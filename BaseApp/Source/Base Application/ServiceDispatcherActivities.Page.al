page 9057 "Service Dispatcher Activities"
{
    Caption = 'Activities';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Service Cue";

    layout
    {
        area(content)
        {
            cuegroup("Service Orders")
            {
                Caption = 'Service Orders';
                field("Service Orders - in Process"; "Service Orders - in Process")
                {
                    ApplicationArea = Service;
                    DrillDownPageID = "Service Orders";
                    ToolTip = 'Specifies the number of in process service orders that are displayed in the Service Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("Service Orders - Finished"; "Service Orders - Finished")
                {
                    ApplicationArea = Service;
                    DrillDownPageID = "Service Orders";
                    ToolTip = 'Specifies the finished service orders that are displayed in the Service Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("Service Orders - Inactive"; "Service Orders - Inactive")
                {
                    ApplicationArea = Service;
                    DrillDownPageID = "Service Orders";
                    ToolTip = 'Specifies the number of inactive service orders that are displayed in the Service Cue on the Role Center. The documents are filtered by today''s date.';
                }

                actions
                {
                    action("New Service Order")
                    {
                        ApplicationArea = Service;
                        Caption = 'New Service Order';
                        RunObject = Page "Service Order";
                        RunPageMode = Create;
                        ToolTip = 'Create an order for specific service work to be performed on a customer''s item. ';
                    }
                    action("New Service Item")
                    {
                        ApplicationArea = Service;
                        Caption = 'New Service Item';
                        RunObject = Page "Service Item Card";
                        RunPageMode = Create;
                        ToolTip = 'Set up an item that represents a customer''s machine that you perform service on.';
                    }
                    action("Edit Dispatch Board")
                    {
                        ApplicationArea = Service;
                        Caption = 'Edit Dispatch Board';
                        RunObject = Page "Dispatch Board";
                        ToolTip = 'View or edit the service response date, response time, priority, order number, customer number, contract number, service zone code, number of allocations, and order date.';
                    }
                    action("Edit Service Tasks")
                    {
                        ApplicationArea = Service;
                        Caption = 'Edit Service Tasks';
                        RunObject = Page "Service Tasks";
                        ToolTip = 'View or edit information on service items in service orders, for example, repair status, response time and service shelf number.';
                    }
                }
            }
            cuegroup("Service Quotes")
            {
                Caption = 'Service Quotes';
                field("Open Service Quotes"; "Open Service Quotes")
                {
                    ApplicationArea = Service;
                    DrillDownPageID = "Service Quotes";
                    ToolTip = 'Specifies the number of open service quotes that are displayed in the Service Cue on the Role Center. The documents are filtered by today''s date.';
                }

                actions
                {
                    action("New Service Quote")
                    {
                        ApplicationArea = Service;
                        Caption = 'New Service Quote';
                        RunObject = Page "Service Quote";
                        RunPageMode = Create;
                        ToolTip = 'Create an to offer to a customer to perform specific service work on a customer''s item. ';
                    }
                    action(Action17)
                    {
                        ApplicationArea = Service;
                        Caption = 'New Service Order';
                        RunObject = Page "Service Order";
                        RunPageMode = Create;
                        ToolTip = 'Create an order for specific service work to be performed on a customer''s item. ';
                    }
                }
            }
            cuegroup("Service Contracts")
            {
                Caption = 'Service Contracts';
                field("Open Service Contract Quotes"; "Open Service Contract Quotes")
                {
                    ApplicationArea = Service;
                    DrillDownPageID = "Service Contract Quotes";
                    ToolTip = 'Specifies the number of open service contract quotes that are displayed in the Service Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("Service Contracts to Expire"; "Service Contracts to Expire")
                {
                    ApplicationArea = Service;
                    DrillDownPageID = "Service Contracts";
                    ToolTip = 'Specifies the number of service contracts set to expire that are displayed in the Service Cue on the Role Center. The documents are filtered by today''s date.';
                }

                actions
                {
                    action("New Service Contract Quote")
                    {
                        ApplicationArea = Service;
                        Caption = 'New Service Contract Quote';
                        RunObject = Page "Service Contract Quote";
                        RunPageMode = Create;
                        ToolTip = 'Offer an agreement with a customer to perform service on the customer''s item. ';
                    }
                    action("New Service Contract")
                    {
                        ApplicationArea = Service;
                        Caption = 'New Service Contract';
                        RunObject = Page "Service Contract";
                        RunPageMode = Create;
                        ToolTip = 'Create an agreement with a customer to perform service on the customer''s item. ';
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
        area(processing)
        {
            action("Set Up Cues")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set Up Cues';
                Image = Setup;
                ToolTip = 'Set up the cues (status tiles) related to the role.';

                trigger OnAction()
                var
                    CueRecordRef: RecordRef;
                begin
                    CueRecordRef.GetTable(Rec);
                    CuesAndKpis.OpenCustomizePageForCurrentUser(CueRecordRef.Number);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;

        SetRespCenterFilter;
        SetRange("Date Filter", 0D, WorkDate);
        SetFilter("User ID Filter", UserId);
    end;

    var
        UserTaskManagement: Codeunit "User Task Management";
        CuesAndKpis: Codeunit "Cues And KPIs";
}

