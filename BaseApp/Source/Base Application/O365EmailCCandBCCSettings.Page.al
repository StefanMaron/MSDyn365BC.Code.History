page 2128 "O365 Email CC and BCC Settings"
{
    Caption = 'Email for all new invoices';
    InsertAllowed = false;
    PageType = List;
    SourceTable = "O365 Email Setup";

    layout
    {
        area(content)
        {
            part("CC List"; "O365 Email CC Listpart")
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'CC List';
            }
            part("BCC List"; "O365 Email BCC Listpart")
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'BCC List';
            }
        }
    }

    actions
    {
    }
}

