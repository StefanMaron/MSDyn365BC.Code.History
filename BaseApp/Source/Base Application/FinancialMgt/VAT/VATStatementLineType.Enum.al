enum 256 "VAT Statement Line Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Account Totaling")
    {
        Caption = 'Account Totaling';
    }
    value(1; "VAT Entry Totaling")
    {
        Caption = 'VAT Entry Totaling';
    }
    value(2; "Row Totaling")
    {
        Caption = 'Row Totaling';
    }
    value(3; Description)
    {
        Caption = 'Description';
    }
}