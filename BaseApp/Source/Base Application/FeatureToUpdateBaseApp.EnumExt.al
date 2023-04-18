enumextension 2611 "Feature To Update - BaseApp" extends "Feature To Update"
{
#if not CLEAN21
    value(7049; SalesPrices)
    {
        Implementation = "Feature Data Update" = "Feature - Price Calculation";
        ObsoleteState = Pending;
        ObsoleteReason = 'Feature SalesPrices will be enabled by default in version 22.0.';
        ObsoleteTag = '19.0';
    }
#endif
#if not CLEAN21
    value(5401; UnitGroupMapping)
    {
        Implementation = "Feature Data Update" = "Feature - Unit Group Mapping";
        ObsoleteState = Pending;
        ObsoleteReason = 'Feature UnitGroupMapping will be deprecated and instead will be an option on the connection setup.';
        ObsoleteTag = '21.0';
    }
#endif
#if not CLEAN22
    value(5405; CurrencySymbolMapping)
    {
        Implementation = "Feature Data Update" = "Feature Map Currency Symbol";
        ObsoleteState = Pending;
        ObsoleteReason = 'Feature CurrencySymbolMapping will be enabled by default in version 22.0.';
        ObsoleteTag = '22.0';
    }
    value(5408; OptionMapping)
    {
        Implementation = "Feature Data Update" = "Feature - Option Mapping";
        ObsoleteState = Pending;
        ObsoleteReason = 'Feature OptionMapping will be enabled by default in version 22.0.';
        ObsoleteTag = '22.0';
    }
#endif
}