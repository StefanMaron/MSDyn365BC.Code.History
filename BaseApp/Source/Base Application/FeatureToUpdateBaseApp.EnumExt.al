#if not CLEAN20
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
#endif
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
    value(5405; CurrencySymbolMapping)
    {
        Implementation = "Feature Data Update" = "Feature Map Currency Symbol";
    }
    value(5408; OptionMapping)
    {
        Implementation = "Feature Data Update" = "Feature - Option Mapping";
    }
    value(31429; ReplaceMultipleInterestRateCZ)
    {
        Implementation = "Feature Data Update" = "Feature Replace Mul. Int. Rate";
        ObsoleteState = Pending;
        ObsoleteReason = 'Feature Multiple Interest Rate CZ will be replaced by Finance Charge Interest Rate by default.';
        ObsoleteTag = '20.0';
    }
}
#endif