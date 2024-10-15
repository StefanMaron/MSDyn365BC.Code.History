namespace Microsoft.Foundation.Enums;

enum 254 "Tax Calculation Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Normal VAT")
    {
        Caption = 'Normal VAT';
    }
    value(1; "Reverse Charge VAT")
    {
        Caption = 'Reverse Charge VAT';
    }
    value(2; "Full VAT")
    {
        Caption = 'Full VAT';
    }
    value(3; "Sales Tax")
    {
        Caption = 'Sales Tax';
    }
}