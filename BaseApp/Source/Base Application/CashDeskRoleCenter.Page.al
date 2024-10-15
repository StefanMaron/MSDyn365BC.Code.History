page 11750 "Cash Desk Role Center"
{
    Caption = 'Cash Desk', Comment = 'Use same translation as ''Profile Description'' ';
    PageType = RoleCenter;

    layout
    {
        area(rolecenter)
        {
            group(Control1220005)
            {
                ShowCaption = false;
                part(Control1220004; "Cash Desk Activities")
                {
                    ApplicationArea = Basic, Suite;
                }
                systempart(Control1220003; MyNotes)
                {
                }
            }
            group(Control1220002)
            {
                ShowCaption = false;
                chartpart("Q11750-01"; "Q11750-01")
                {
                    ApplicationArea = Basic, Suite;
                }
                systempart(Control1220000; Outlook)
                {
                }
            }
        }
    }

    actions
    {
        area(reporting)
        {
            action("Cash Desk Account Book")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cash Desk Account Book';
                Image = Print;
                RunObject = Report "Cash Desk Account Book";
                ToolTip = 'Open the report for cash desk account book - printed only posted documents.';
            }
            action("Cash Inventory")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cash Inventory';
                Image = Print;
                RunObject = Report "Cash Inventory";
                ToolTip = 'Open the report for cash inventory.';
            }
            action("Cash Desk Book")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cash Desk Book';
                Image = Print;
                RunObject = Report "Cash Desk Book";
                ToolTip = 'Open the report for cash desk book - printed posted and released unposted documents.';
            }
        }
        area(processing)
        {
        }
        area(sections)
        {
        }
        area(embedding)
        {
            action("Cash Desks")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cash Desks';
                Image = List;
                RunObject = Page "Cash Desk List";
                ToolTip = 'Specifies cash desks';
            }
        }
    }
}

