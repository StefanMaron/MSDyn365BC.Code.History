namespace Microsoft.Sales.Customer;

pageextension 6492 "Serv. Customer Templ. Card" extends "Customer Templ. Card"
{
    layout
    {
        addafter("Responsibility Center")
        {
            field("Service Zone Code"; Rec."Service Zone Code")
            {
                ApplicationArea = Service;
                Importance = Additional;
                ToolTip = 'Specifies the code for the service zone that is assigned to the customer.';
                Visible = false;
            }
        }
    }
}