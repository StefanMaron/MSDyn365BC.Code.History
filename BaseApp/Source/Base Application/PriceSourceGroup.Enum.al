enum 7002 "Price Source Group" implements "Price Source Group"
{
    Extensible = true;
    value(0; All)
    {
        Implementation = "Price Source Group" = "Price Source Group - All";
    }
    value(11; Customer)
    {
        Implementation = "Price Source Group" = "Price Source Group - Customer";
    }
    value(21; Vendor)
    {
        Implementation = "Price Source Group" = "Price Source Group - Vendor";
    }
    value(31; Job)
    {
        Implementation = "Price Source Group" = "Price Source Group - Job";
    }
}