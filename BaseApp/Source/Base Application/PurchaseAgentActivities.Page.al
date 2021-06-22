page 9063 "Purchase Agent Activities"
{
    Caption = 'Activities';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Purchase Cue";

    layout
    {
        area(content)
        {
            cuegroup("Pre-arrival Follow-up on Purchase Orders")
            {
                Caption = 'Pre-arrival Follow-up on Purchase Orders';
                field("To Send or Confirm"; "To Send or Confirm")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Purchase Order List";
                    ToolTip = 'Specifies the number of documents to send or confirm that are displayed in the Purchase Cue on the Role Center. The documents are filtered by today''s date.';
                }
                field("Upcoming Orders"; "Upcoming Orders")
                {
                    ApplicationArea = Suite;
                    DrillDownPageID = "Purchase Order List";
                    ToolTip = 'Specifies the number of upcoming orders that are displayed in the Purchase Cue on the Role Center. The documents are filtered by today''s date.';
                }

                actions
                {
                    action("New Purchase Quote")
                    {
                        ApplicationArea = Suite;
                        Caption = 'New Purchase Quote';
                        RunObject = Page "Purchase Quote";
                        RunPageMode = Create;
                        ToolTip = 'Prepare a request for quote';
                    }
                    action("New Purchase Order")
                    {
                        ApplicationArea = Suite;
                        Caption = 'New Purchase Order';
                        RunObject = Page "Purchase Order";
                        RunPageMode = Create;
                        ToolTip = 'Purchase goods or services from a vendor.';
                    }
                    action("Edit Purchase Journal")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Edit Purchase Journal';
                        RunObject = Page "Purchase Journal";
                        ToolTip = 'Post purchase invoices in a purchase journal that may already contain journal lines.';
                    }
                }
            }
            cuegroup("Post Arrival Follow-up")
            {
                Caption = 'Post Arrival Follow-up';
                field(OutstandingOrders; "Outstanding Purchase Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Outstanding Purchase Orders';
                    DrillDownPageID = "Purchase Order List";
                    ToolTip = 'Specifies the number of outstanding purchase orders that are displayed in the Purchase Cue on the Role Center. The documents are filtered by today''s date.';

                    trigger OnDrillDown()
                    begin
                        ShowOrders(FieldNo("Outstanding Purchase Orders"));
                    end;
                }
                field("Purchase Return Orders - All"; "Purchase Return Orders - All")
                {
                    ApplicationArea = PurchReturnOrder;
                    DrillDownPageID = "Purchase Return Order List";
                    ToolTip = 'Specifies the number of purchase return orders that are displayed in the Purchase Cue on the Role Center. The documents are filtered by today''s date.';
                }

                actions
                {
                    action(Navigate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Navigate';
                        RunObject = Page Navigate;
                        ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';
                    }
                    action("New Purchase Return Order")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'New Purchase Return Order';
                        RunObject = Page "Purchase Return Order";
                        RunPageMode = Create;
                        ToolTip = 'Process a return or refund that requires inventory handling by creating a new purchase return order.';
                    }
                }
            }
            cuegroup("Purchase Orders - Authorize for Payment")
            {
                Caption = 'Purchase Orders - Authorize for Payment';
                field(NotInvoiced; "Not Invoiced")
                {
                    ApplicationArea = Suite;
                    Caption = 'Received, Not Invoiced';
                    DrillDownPageID = "Purchase Order List";
                    ToolTip = 'Specifies received orders that are not invoiced. The orders are displayed in the Purchase Cue on the Purchasing Agent role center, and filtered by today''s date.';

                    trigger OnDrillDown()
                    begin
                        ShowOrders(FieldNo("Not Invoiced"));
                    end;
                }
                field(PartiallyInvoiced; "Partially Invoiced")
                {
                    ApplicationArea = Suite;
                    Caption = 'Partially Invoiced';
                    DrillDownPageID = "Purchase Order List";
                    ToolTip = 'Specifies the number of partially invoiced orders that are displayed in the Purchase Cue on the Role Center. The documents are filtered by today''s date.';

                    trigger OnDrillDown()
                    begin
                        ShowOrders(FieldNo("Partially Invoiced"));
                    end;
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

    trigger OnAfterGetRecord()
    begin
        CalculateCueFieldValues;
    end;

    trigger OnOpenPage()
    begin
        Reset;
        if not Get then begin
            Init;
            Insert;
        end;

        SetRespCenterFilter;
        SetFilter("Date Filter", '>=%1', WorkDate);
        SetFilter("User ID Filter", UserId);
    end;

    var
        UserTaskManagement: Codeunit "User Task Management";

    local procedure CalculateCueFieldValues()
    begin
        if FieldActive("Outstanding Purchase Orders") then
            "Outstanding Purchase Orders" := CountOrders(FieldNo("Outstanding Purchase Orders"));

        if FieldActive("Not Invoiced") then
            "Not Invoiced" := CountOrders(FieldNo("Not Invoiced"));

        if FieldActive("Partially Invoiced") then
            "Partially Invoiced" := CountOrders(FieldNo("Partially Invoiced"));
    end;
}

