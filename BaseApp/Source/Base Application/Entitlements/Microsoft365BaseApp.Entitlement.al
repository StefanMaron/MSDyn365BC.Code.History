namespace System.Security.AccessControl;

entitlement "Microsoft 365 BaseApp"
{
    Type = PerUserServicePlan;
    Id = '57ff2da0-773e-42df-b2af-ffb7a2317929';
    ObjectEntitlements = "D365 READ",
                         "Security - Baseapp",
                         "Local Read";
}
