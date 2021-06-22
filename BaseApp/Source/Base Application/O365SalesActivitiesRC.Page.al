page 9029 "O365 Sales Activities RC"
{
    Caption = 'Microsoft Invoicing';
    PageType = RoleCenter;

    layout
    {
        area(rolecenter)
        {
            part(Control2; "O365 Sales Activities")
            {
                ApplicationArea = Basic, Suite, Invoicing;
            }
            part(Control3; "BC O365 Top five Cust")
            {
                ApplicationArea = Basic, Suite, Invoicing;
            }
            part(Control4; "O365 Sales Year Summary")
            {
                ApplicationArea = Basic, Suite, Invoicing;
            }
        }
    }

    actions
    {
        area(embedding)
        {
            ToolTip = 'See KPI charts, get the overview, and manage your business.';
            action(InvoicesHomeItem)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Invoices';
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "BC O365 Invoice List";
                ToolTip = 'Register your sales, and make it easy for your customer to pay you according to the payment terms by sending them a sales invoice document.';
            }
            action(InvoicesHomeItemDraft)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Draft';
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "BC O365 Invoice List";
                RunPageView = WHERE(Posted = CONST(false));
                ToolTip = 'Register your sales, and make it easy for your customer to pay you according to the payment terms by sending them a sales invoice document.';
            }
            action(InvoicesHomeItemSent)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Sent';
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "BC O365 Invoice List";
                RunPageView = WHERE(Posted = CONST(true),
                                    "Outstanding Amount" = FILTER(> 0));
                ToolTip = 'Register your sales, and make it easy for your customer to pay you according to the payment terms by sending them a sales invoice document.';
            }
            action(InvoicesHomeItemOverdue)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Overdue';
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "BC O365 Invoice List";
                RunPageView = WHERE(Canceled = CONST(false),
                                    "Outstanding Amount" = FILTER(> 0));
                ToolTip = 'Register your sales, and make it easy for your customer to pay you according to the payment terms by sending them a sales invoice document.';
                Visible = false;
            }
            action(InvoicesHomeItemPaid)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Paid';
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "BC O365 Invoice List";
                RunPageView = WHERE(Posted = CONST(true),
                                    "Outstanding Amount" = FILTER(= 0),
                                    Canceled = CONST(false));
                ToolTip = 'Register your sales, and make it easy for your customer to pay you according to the payment terms by sending them a sales invoice document.';
            }
            action(InvoicesHomeItemCanceled)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Canceled';
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "BC O365 Invoice List";
                RunPageView = WHERE(Canceled = CONST(true),
                                    Posted = CONST(true));
                ToolTip = 'Register your sales, and make it easy for your customer to pay you according to the payment terms by sending them a sales invoice document.';
            }
            action(EstimatesHomeItem)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Estimates';
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "BC O365 Estimate List";
                ToolTip = 'Send your customers offers on products. When the customer accepts the offer, you can convert the estimate to a sales invoice.';
            }
            action(EstimatesHomeItemAccepted)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Accepted';
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "BC O365 Estimate List";
                RunPageView = WHERE("Quote Accepted" = CONST(true));
                ToolTip = 'Send your customers offers on products. When the customer accepts the offer, you can convert the estimate to a sales invoice.';
            }
            action(EstimatesHomeItemExpired)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Expired';
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "BC O365 Invoice List";
                RunPageView = WHERE("Quote Accepted" = CONST(true));
                ToolTip = 'Send your customers offers on products. When the customer accepts the offer, you can convert the estimate to a sales invoice.';
                Visible = false;
            }
            action(CustomersHomeItem)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Customers';
                RunObject = Page "BC O365 Customer List";
                ToolTip = 'View or edit detailed information for the customers that you trade with.';
            }
            action(ItemsHomeItem)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Prices';
                RunObject = Page "BC O365 Item List";
                ToolTip = 'View or edit detailed information for the products that you trade in.';
            }
        }
    }
}

