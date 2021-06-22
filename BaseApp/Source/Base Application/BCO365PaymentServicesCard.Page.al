page 2351 "BC O365 Payment Services Card"
{
    Caption = 'Online Payments';
    PageType = Card;
    RefreshOnActivate = true;

    layout
    {
        area(content)
        {
            part(PaymentServicesSubpage; "BC O365 Payment Services")
            {
                ApplicationArea = Basic, Suite, Invoicing;
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
    }
}

