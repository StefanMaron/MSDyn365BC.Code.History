namespace System.Security.AccessControl;

entitlement "Azure AD Application Automation BaseApp"
{
    Type = ApplicationScope;
    Id = '00000000-0000-0000-0000-000000000010';
    ObjectEntitlements = "D365 AUTOMATION",
                         "D365 RAPIDSTART",
                         "LOCAL",
                         "Security - Baseapp";
}
