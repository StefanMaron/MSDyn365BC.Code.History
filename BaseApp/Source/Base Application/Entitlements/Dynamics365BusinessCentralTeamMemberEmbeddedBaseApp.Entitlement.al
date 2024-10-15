namespace System.Security.AccessControl;

entitlement "Dynamics 365 Business Central Team Member - Embedded BaseApp"
{
    Type = PerUserServicePlan;
    Id = 'fd1441b8-116b-4fa7-836e-d7956700e0fa';
    ObjectEntitlements = "BaseApp Objects - Exec",
                         "D365 BASIC",
                         "D365 MONITOR FIELDS",
                         "D365 READ",
                         "D365 TEAM MEMBER",
                         "LOCAL",
                         "Security - Baseapp";
}
