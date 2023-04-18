#if not CLEAN21
page 2351 "BC O365 Payment Services Card"
{
    Caption = 'Online Payments';
    PageType = Card;
    RefreshOnActivate = true;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            part(PaymentServicesSubpage; "BC O365 Payment Services")
            {
                ApplicationArea = Invoicing, Basic, Suite;
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
    }
}
#endif
