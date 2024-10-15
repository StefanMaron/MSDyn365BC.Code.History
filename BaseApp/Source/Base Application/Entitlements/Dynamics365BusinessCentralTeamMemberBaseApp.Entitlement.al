namespace System.Security.AccessControl;

entitlement "Dynamics 365 Business Central Team Member BaseApp"
{
    Type = PerUserServicePlan;
    Id = 'd9a6391b-8970-4976-bd94-5f205007c8d8';
    ObjectEntitlements = "BaseApp Objects - Exec",
                         "D365 BASIC",
                         "D365 MONITOR FIELDS",
                         "D365 READ",
                         "D365 TEAM MEMBER",
                         "LOCAL",
                         "Security - Baseapp";
}
