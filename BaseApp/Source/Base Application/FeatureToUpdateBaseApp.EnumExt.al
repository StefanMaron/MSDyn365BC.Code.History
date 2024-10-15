namespace System.Environment.Configuration;

#if not CLEAN23
using Microsoft.Pricing.Calculation;
#endif

enumextension 2611 "Feature To Update - BaseApp" extends "Feature To Update"
{
#if not CLEAN23
    value(7049; SalesPrices)
    {
        Implementation = "Feature Data Update" = "Feature - Price Calculation";
        ObsoleteState = Pending;
        ObsoleteReason = 'Feature SalesPrices will be enabled by default in version 22.0.';
        ObsoleteTag = '19.0';
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
    value(5409; EnablePlatformBasedReportSelection)
    {
        Implementation = "Feature Data Update" = "Feature - Report Selection";
        ObsoleteState = Pending;
        ObsoleteReason = 'Feature EnablePlatformBasedReportSelection will be enabled by default in version 24.0.';
        ObsoleteTag = '24.0';
    }
#if not CLEAN24
    value(5877; PhysInvtOrderPackageTracking)
    {
        Implementation = "Feature Data Update" = "Feature - Invt. Orders Package";
        ObsoleteState = Pending;
        ObsoleteReason = 'Feature Phys. Invt. Orders Package Tracking will be enabled by default in version 27.0.';
        ObsoleteTag = '24.0';
    }
#endif
#if not CLEAN24
    value(5878; GLCurrencyRevaluation)
    {
        Implementation = "Feature Data Update" = "Feature-GLCurrencyRevaluation";
        ObsoleteState = Pending;
        ObsoleteReason = 'Feature G/L Currency REvaluation will be enabled by default in version 27.0.';
        ObsoleteTag = '24.0';
    }
#endif
}