namespace Microsoft.Service.Contract;

enum 5997 "Service Contract Header Invoice Period"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; Month)
    {
        Caption = 'Month';
    }
    value(1; "Two Months")
    {
        Caption = 'Two Months';
    }
    value(2; Quarter)
    {
        Caption = 'Quarter';
    }
    value(3; "Half Year")
    {
        Caption = 'Half Year';
    }
    value(4; Year)
    {
        Caption = 'Year';
    }
    value(5; "None")
    {
        Caption = 'None';
    }
}