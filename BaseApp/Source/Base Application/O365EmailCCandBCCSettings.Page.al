#if not CLEAN21
page 2128 "O365 Email CC and BCC Settings"
{
    Caption = 'Email for all new invoices';
    InsertAllowed = false;
    PageType = List;
    SourceTable = "O365 Email Setup";
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            part("CC List"; "O365 Email CC Listpart")
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'CC List';
            }
            part("BCC List"; "O365 Email BCC Listpart")
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'BCC List';
            }
        }
    }

    actions
    {
    }
}
#endif
