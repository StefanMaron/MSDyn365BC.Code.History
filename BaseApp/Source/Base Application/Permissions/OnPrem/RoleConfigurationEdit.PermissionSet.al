namespace System.Security.AccessControl;

using System.Reflection;
using System.Environment.Configuration;
using System.Tooling;

permissionset 6607 "Role Configuration - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Role Configuration';

    IncludedPermissionSets = "Metadata - Read",
                             "User Personalization - Edit";

    Permissions = tabledata "All Profile" = IMD,
                  tabledata "Profile Configuration Symbols" = IMD,
#pragma warning disable AL0432
                  tabledata "Tenant Profile" = IMD,
#pragma warning restore AL0432
                  tabledata "Tenant Profile Extension" = IMD,
                  tabledata "Tenant Profile Page Metadata" = IMD,
                  tabledata "Tenant Profile Setting" = IMD,
                  tabledata "Designer Diagnostic" = RIMD,
                  tabledata "Profile Designer Diagnostic" = RIMD,
                  tabledata "Profile Import" = RIMD;
}
