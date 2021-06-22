page 9031 "O365 Invoicing RC"
{
    Caption = 'Invoicing', Comment = 'Use same translation as ''Profile Description'' (if applicable)';
    PageType = RoleCenter;

    layout
    {
        area(rolecenter)
        {
            part(Control9; "O365 Invoicing Activities")
            {
                AccessByPermission = TableData "G/L Entry" = R;
                ApplicationArea = Invoicing;
            }
            part(Control8; "Help And Chart Wrapper")
            {
                ApplicationArea = Invoicing;
            }
            part(Control19; "Product Video Topics")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(embedding)
        {
            action(Customers)
            {
                ApplicationArea = Invoicing;
                Caption = 'Customers';
                RunObject = Page "O365 Customer Lookup";
                ToolTip = 'View or edit detailed information for the customers that you trade with. From each customer card, you can open related information, such as sales statistics and ongoing orders, and you can define special prices and line discounts that you grant if certain conditions are met.';
            }
            action(Invoices)
            {
                ApplicationArea = Invoicing;
                Caption = 'Invoices';
                RunObject = Page "O365 Invoicing Sales Doc. List";
                //The property 'ToolTip' cannot be empty.
                //ToolTip = '';
            }
            action("Draft Invoices")
            {
                ApplicationArea = Invoicing;
                Caption = 'Draft Invoices';
                RunObject = Page "O365 Invoicing Sales Doc. List";
                RunPageView = WHERE(Posted = CONST(false));
                ToolTip = 'Open the list of draft invoices';
            }
            action("Sent Invoices")
            {
                ApplicationArea = Invoicing;
                Caption = 'Sent Invoices';
                RunObject = Page "O365 Invoicing Sales Doc. List";
                RunPageView = WHERE(Posted = CONST(true));
                ToolTip = 'Open the list of sent invoices';
            }
            action(Items)
            {
                ApplicationArea = Invoicing;
                Caption = 'Items';
                RunObject = Page "Item List";
                //The property 'ToolTip' cannot be empty.
                //ToolTip = '';
            }
            action(Settings)
            {
                ApplicationArea = Invoicing;
                Caption = 'Settings';
                RunObject = Page "O365 Invoicing Settings";
                ToolTip = 'Open the list of settings';
            }
        }
    }
}

