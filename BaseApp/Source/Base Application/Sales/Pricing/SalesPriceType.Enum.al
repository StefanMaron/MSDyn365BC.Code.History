namespace Microsoft.Sales.Pricing;

enum 7023 "Sales Price Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Customer") { Caption = 'Customer'; }
    value(1; "Customer Price Group") { Caption = 'Customer Price Group'; }
    value(2; "All Customers") { Caption = 'All Customers'; }
    value(3; "Campaign") { Caption = 'Campaign'; }
}