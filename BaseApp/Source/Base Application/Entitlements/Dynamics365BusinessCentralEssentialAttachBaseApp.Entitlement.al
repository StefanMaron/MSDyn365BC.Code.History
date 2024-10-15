namespace System.Security.AccessControl;

entitlement "Dynamics 365 Business Central Essential - Attach BaseApp"
{
    Type = PerUserServicePlan;
    Id = '17ca446c-d7a4-4d29-8dec-8e241592164b';
    ObjectEntitlements = "BaseApp Objects - Exec",
                         "D365 BASIC",
                         "D365 BUS FULL ACCESS",
                         "D365 DIM CORRECTION",
                         "D365 MONITOR FIELDS",
                         "LOCAL",
                         "Reten. Pol. Setup - BaseApp",
                         "Security - Baseapp";
}
