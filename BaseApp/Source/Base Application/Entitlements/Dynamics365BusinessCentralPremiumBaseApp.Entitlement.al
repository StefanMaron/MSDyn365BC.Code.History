namespace System.Security.AccessControl;

entitlement "Dynamics 365 Business Central Premium BaseApp"
{
    Type = PerUserServicePlan;
    Id = '8e9002c0-a1d8-4465-b952-817d2948e6e2';
    ObjectEntitlements = "BaseApp Objects - Exec",
                         "D365 BASIC",
                         "D365 BUS PREMIUM",
                         "D365 DIM CORRECTION",
                         "D365 MONITOR FIELDS",
                         "LOCAL",
                         "Reten. Pol. Setup - BaseApp",
                         "Security - Baseapp";
}
