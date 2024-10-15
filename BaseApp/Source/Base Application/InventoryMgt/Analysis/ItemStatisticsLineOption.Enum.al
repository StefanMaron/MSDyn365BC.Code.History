namespace Microsoft.Inventory.Analysis;

enum 5821 "Item Statistics Line Option"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Profit Calculation")
    {
        Caption = 'Profit Calculation';
    }
    value(1; "Cost Specification")
    {
        Caption = 'Cost Specification';
    }
    value(2; "Purch. Item Charge Spec.")
    {
        Caption = 'Purch. Item Charge Spec.';
    }
    value(3; "Sales Item Charge Spec.")
    {
        Caption = 'Sales Item Charge Spec.';
    }
    value(4; "Period")
    {
        Caption = 'Period';
    }
    value(5; "Location")
    {
        Caption = 'Location';
    }
}