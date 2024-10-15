namespace Microsoft.Manufacturing.Document;

enum 5407 "Prod. Order Source Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Item")
    {
        Caption = 'Item';
    }
    value(1; "Family")
    {
        Caption = 'Family';
    }
    value(2; "Sales Header")
    {
        Caption = 'Sales Header';
    }
}