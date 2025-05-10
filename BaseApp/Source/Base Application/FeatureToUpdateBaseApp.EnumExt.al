namespace System.Environment.Configuration;

#if not CLEAN25
using Microsoft.Pricing.Calculation;
#endif

enumextension 2611 "Feature To Update - BaseApp" extends "Feature To Update"
{
#if not CLEAN25
    value(7049; SalesPrices)
    {
        Implementation = "Feature Data Update" = "Feature - Price Calculation";
        ObsoleteState = Pending;
        ObsoleteReason = 'Feature SalesPrices will be enabled by default in version 22.0.';
        ObsoleteTag = '19.0';
    }
#endif
#if not CLEAN24
    value(5409; EnablePlatformBasedReportSelection)
    {
        Implementation = "Feature Data Update" = "Feature - Report Selection";
        ObsoleteState = Pending;
        ObsoleteReason = 'Feature EnablePlatformBasedReportSelection will be enabled by default in version 24.0.';
        ObsoleteTag = '24.0';
    }
#endif
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
#if not CLEAN26
    value(5892; Manufacturing_FlushingMethod_ActivateManualWoPick)
    {
        Implementation = "Feature Data Update" = "Feature-ManualFlushingMethod";
        ObsoleteState = Pending;
        ObsoleteReason = 'Feature ''Manual Flushing Method without requiring pick'' will be enabled by default in version 29.0.';
        ObsoleteTag = '26.0';
    }
#endif
}