#if not CLEAN21
page 9029 "O365 Sales Activities RC"
{
    Caption = 'Microsoft Invoicing';
    PageType = RoleCenter;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(rolecenter)
        {
            part(Control2; "O365 Sales Activities")
            {
                ApplicationArea = Invoicing, Basic, Suite;
            }
            part(Control3; "BC O365 Top five Cust")
            {
                ApplicationArea = Invoicing, Basic, Suite;
            }
            part(Control4; "O365 Sales Year Summary")
            {
                ApplicationArea = Invoicing, Basic, Suite;
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
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Invoices';
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "BC O365 Invoice List";
                ToolTip = 'Register your sales, and make it easy for your customer to pay you according to the payment terms by sending them a sales invoice document.';
            }
            action(InvoicesHomeItemDraft)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Draft';
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "BC O365 Invoice List";
                RunPageView = WHERE(Posted = CONST(false));
                ToolTip = 'Register your sales, and make it easy for your customer to pay you according to the payment terms by sending them a sales invoice document.';
            }
            action(InvoicesHomeItemSent)
            {
                ApplicationArea = Invoicing, Basic, Suite;
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
                ApplicationArea = Invoicing, Basic, Suite;
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
                ApplicationArea = Invoicing, Basic, Suite;
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
                ApplicationArea = Invoicing, Basic, Suite;
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
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Estimates';
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "BC O365 Estimate List";
                ToolTip = 'Send your customers offers on products. When the customer accepts the offer, you can convert the estimate to a sales invoice.';
            }
            action(EstimatesHomeItemAccepted)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Accepted';
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "BC O365 Estimate List";
                RunPageView = WHERE("Quote Accepted" = CONST(true));
                ToolTip = 'Send your customers offers on products. When the customer accepts the offer, you can convert the estimate to a sales invoice.';
            }
            action(EstimatesHomeItemExpired)
            {
                ApplicationArea = Invoicing, Basic, Suite;
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
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Customers';
                RunObject = Page "BC O365 Customer List";
                ToolTip = 'View or edit detailed information for the customers that you trade with.';
            }
            action(ItemsHomeItem)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Prices';
                RunObject = Page "BC O365 Item List";
                ToolTip = 'View or edit detailed information for the products that you trade in.';
            }
        }
    }
}
#endif
