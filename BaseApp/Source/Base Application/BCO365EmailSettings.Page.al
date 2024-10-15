#if not CLEAN21
page 2329 "BC O365 Email Settings"
{
    Caption = 'CC/BCC', Comment = 'CC and BCC are the acronyms for Carbon Copy and Blind Carbon Copy';
    InsertAllowed = false;
    PageType = Card;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            group(Control12)
            {
                InstructionalText = 'You can add email addresses to include your accountant or yourself for all sent invoices and estimates.';
                ShowCaption = false;
            }
            part(Control2; "BC O365 Email Settings Part")
            {
                ApplicationArea = Invoicing, Basic, Suite;
            }
        }
    }

    actions
    {
    }
}
#endif
