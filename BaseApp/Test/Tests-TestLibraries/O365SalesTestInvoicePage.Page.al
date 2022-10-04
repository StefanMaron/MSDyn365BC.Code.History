#if not CLEAN21
page 138900 "O365 Sales Test Invoice Page"
{

    layout
    {
    }

    actions
    {
        area(creation)
        {
            action("Create Test Invoice")
            {
                ApplicationArea = Invoicing;
                Caption = 'Create test invoice.';
                RunObject = Page "BC O365 Sales Invoice";
                RunPageLink = "No." = CONST('TESTINVOICE');
                RunPageMode = Create;
                ToolTip = 'ENU=Create the test invoice.';
            }
            action("Create Normal Invoice")
            {
                ApplicationArea = Invoicing;
                Caption = 'Create normal invoice.';
                RunObject = Page "BC O365 Sales Invoice";
                RunPageMode = Create;
                ToolTip = 'Create the normal  invoice';
            }
        }
    }
}
#endif
