namespace System.Security.AccessControl;

entitlement "Dynamics 365 Business Central Premium - Embedded BaseApp"
{
    Type = PerUserServicePlan;
    Id = '4c52d56d-5121-425a-91a5-dd0de136ca17';
    ObjectEntitlements = "BaseApp Objects - Exec",
                         "D365 BASIC",
                         "D365 BUS PREMIUM",
                         "D365 DIM CORRECTION",
                         "D365 MONITOR FIELDS",
                         "LOCAL",
                         "Reten. Pol. Setup - BaseApp",
                         "Security - Baseapp";
}
