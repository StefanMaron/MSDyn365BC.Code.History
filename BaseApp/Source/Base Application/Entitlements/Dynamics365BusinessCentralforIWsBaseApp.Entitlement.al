namespace System.Security.AccessControl;

entitlement "Dynamics 365 Business Central for IWs BaseApp"
{
    Type = PerUserServicePlan;
    Id = '3f2afeed-6fb5-4bf9-998f-f2912133aead';
    ObjectEntitlements = "BaseApp Objects - Exec",
                         "D365 BASIC",
                         "D365 BUS PREMIUM",
                         "D365 DIM CORRECTION",
                         "D365 MONITOR FIELDS",
                         "LOCAL",
                         "Reten. Pol. Setup - BaseApp",
                         "Security - Baseapp";
}
