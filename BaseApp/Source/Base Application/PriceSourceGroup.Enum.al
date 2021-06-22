enum 7002 "Price Source Group" implements "Price Source Group"
{
    Extensible = true;
    value(0; All)
    {
        Caption = '(All)';
        Implementation = "Price Source Group" = "Price Source Group - All";
    }
    value(11; Customer)
    {
        Caption = 'Customer';
        Implementation = "Price Source Group" = "Price Source Group - Customer";
    }
    value(21; Vendor)
    {
        Caption = 'Vendor';
        Implementation = "Price Source Group" = "Price Source Group - Vendor";
    }
    value(31; Job)
    {
        Caption = 'Job';
        Implementation = "Price Source Group" = "Price Source Group - Job";
    }
}