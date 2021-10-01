enumextension 2611 "Feature To Update - BaseApp" extends "Feature To Update"
{
#if not CLEAN19
    value(5721; ItemReference)
    {
        Implementation = "Feature Data Update" = "Feature - Item Reference";
        ObsoleteState = Pending;
        ObsoleteReason = 'Feature ItemReference got enabled by default.';
        ObsoleteTag = '19.0';
    }
    value(7049; SalesPrices)
    {
        Implementation = "Feature Data Update" = "Feature - Price Calculation";
        ObsoleteState = Pending;
        ObsoleteReason = 'Feature SalesPrices will be enabled by default in version 22.0.';
        ObsoleteTag = '19.0';
    }
#endif
    value(5401; UnitGroupMapping)
    {
        Implementation = "Feature Data Update" = "Feature - Unit Group Mapping";
    }
}