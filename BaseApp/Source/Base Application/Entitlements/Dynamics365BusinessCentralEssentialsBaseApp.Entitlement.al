namespace System.Security.AccessControl;

entitlement "Dynamics 365 Business Central Essentials BaseApp"
{
    Type = PerUserServicePlan;
    Id = '920656a2-7dd8-4c83-97b6-a356414dbd36';
    ObjectEntitlements = "BaseApp Objects - Exec",
                         "D365 BASIC",
                         "D365 BUS FULL ACCESS",
                         "D365 DIM CORRECTION",
                         "D365 MONITOR FIELDS",
                         "LOCAL",
                         "Reten. Pol. Setup - BaseApp",
                         "Security - Baseapp";
}
