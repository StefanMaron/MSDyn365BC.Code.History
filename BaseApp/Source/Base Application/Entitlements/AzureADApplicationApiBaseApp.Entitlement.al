namespace System.Security.AccessControl;

entitlement "Azure AD Application Api BaseApp"
{
    Type = ApplicationScope;
    Id = 'API.ReadWrite.All';
    ObjectEntitlements = "BaseApp Objects - Exec",
                         "D365 DIM CORRECTION",
                         "D365 FULL ACCESS",
                         "D365 MONITOR FIELDS",
                         "D365 RAPIDSTART",
                         "LOCAL",
                         "Security - Baseapp";
}
