enumextension 134118 "Mock Source Type - Locations" extends "Price Source Type"
{
    value(134110; "All Locations")
    {
        Caption = 'All Locations';
        Implementation = "Price Source" = "Price Source - All", "Price Source Group" = "Price Source Group - All";
    }
    value(134111; Location)
    {
        Caption = 'Location';
        Implementation = "Price Source" = "Mock Price Source - Location", "Price Source Group" = "Price Source Group - All";
    }
}
