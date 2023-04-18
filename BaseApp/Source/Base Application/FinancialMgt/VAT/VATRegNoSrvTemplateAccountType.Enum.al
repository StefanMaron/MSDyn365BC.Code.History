enum 241 "VAT Reg. No. Srv. Template Account Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; None)
    {
        Caption = ' ';
    }
    value(1; Customer)
    {
        Caption = 'Customer';
    }
    value(2; Vendor)
    {
        Caption = 'Vendor';
    }
    value(3; Contact)
    {
        Caption = 'Contact';
    }
}