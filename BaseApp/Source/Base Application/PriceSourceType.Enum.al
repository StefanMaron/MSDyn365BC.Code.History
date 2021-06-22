enum 7003 "Price Source Type" implements "Price Source", "Price Source Group"
{
    Extensible = true;
    value(0; All)
    {
        Implementation = "Price Source" = "Price Source - All", "Price Source Group" = "Price Source Group - All";
    }
    value(10; "All Customers")
    {
        Implementation = "Price Source" = "Price Source - All", "Price Source Group" = "Price Source Group - Customer";
    }
    value(11; Customer)
    {
        Implementation = "Price Source" = "Price Source - Customer", "Price Source Group" = "Price Source Group - Customer";
    }
    value(12; "Customer Price Group")
    {
        Implementation = "Price Source" = "Price Source - Cust. Price Gr.", "Price Source Group" = "Price Source Group - All";
    }
    value(13; "Customer Disc. Group")
    {
        Implementation = "Price Source" = "Price Source - Cust. Disc. Gr.", "Price Source Group" = "Price Source Group - All";
    }
    value(20; "All Vendors")
    {
        Implementation = "Price Source" = "Price Source - All", "Price Source Group" = "Price Source Group - Vendor";
    }
    value(21; Vendor)
    {
        Implementation = "Price Source" = "Price Source - Vendor", "Price Source Group" = "Price Source Group - Vendor";
    }
    value(30; "All Jobs")
    {
        Implementation = "Price Source" = "Price Source - All", "Price Source Group" = "Price Source Group - Job";
    }
    value(31; Job)
    {
        Implementation = "Price Source" = "Price Source - Job", "Price Source Group" = "Price Source Group - Job";
    }
    value(32; "Job Task")
    {
        Implementation = "Price Source" = "Price Source - Job Task", "Price Source Group" = "Price Source Group - Job";
    }
    value(50; Campaign)
    {
        Implementation = "Price Source" = "Price Source - Campaign", "Price Source Group" = "Price Source Group - All";
    }
    value(51; Contact)
    {
        Implementation = "Price Source" = "Price Source - Contact", "Price Source Group" = "Price Source Group - All";
    }
}