permissionset 6948 "D365 FULL ACCESS"
{
    Access = Public;
    Assignable = true;
    Caption = 'Dynamics 365 Full access';

    IncludedPermissionSets = "D365 BUS PREMIUM",
                             "System App - Admin",
                             SECURITY;

    Permissions = tabledata "All Profile" = IMD,
                  tabledata "Application Dependency" = Rimd,
                  tabledata "Application Object Metadata" = Rimd,
                  tabledata "Application Resource" = Rimd,
                  tabledata "Feature Key" = IMD,
                  tabledata "Installed Application" = Rimd,
                  tabledata "NAV App Capabilities" = Rimd,
                  tabledata "NAV App Data Archive" = Rimd,
                  tabledata "NAV App Object Prerequisites" = Rimd,
                  tabledata "NAV App Tenant Add-In" = Rimd,
                  tabledata "NAV App Tenant Operation" = RIMD,
                  tabledata Profile = IMD,
                  tabledata "Profile Configuration Symbols" = IMD,
                  tabledata "Tenant Profile" = IMD,
                  tabledata "Tenant Profile Extension" = IMD,
                  tabledata "Tenant Profile Page Metadata" = IMD,
                  tabledata "Tenant Profile Setting" = IMD,
                  tabledata "Designer Diagnostic" = RIMD,
                  tabledata "Field Monitoring Setup" = iMd,
                  tabledata "Profile Designer Diagnostic" = RIMD,
                  tabledata "Profile Import" = RIMD,
                  tabledata "Support Contact Information" = imd,
                  tabledata "User Group" = IMD,
                  tabledata "User Group Access Control" = IMD,
                  tabledata "User Group Permission Set" = IMD;
}
