namespace System.Security.AccessControl;

using Microsoft.FixedAssets.Depreciation;
using Microsoft.Bank.Payment;
using Microsoft.Finance.AutomaticAccounts;
using Microsoft.Bank.Setup;

permissionset 1001 "LOCAL"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific func.';

    IncludedPermissionSets = "LOCAL READ";

    Permissions = tabledata "Depr. Diff. Posting Buffer" = IMD,
                  tabledata "Foreign Payment Types" = IMD,
#if not CLEAN22
                  tabledata "Automatic Acc. Header" = IMD,
                  tabledata "Automatic Acc. Line" = IMD,
                  tabledata "Intrastat - File Setup" = IMD,
#endif
                  tabledata "Ref. Payment - Exported" = IMD,
                  tabledata "Ref. Payment - Exported Buffer" = IMD,
                  tabledata "Ref. Payment - Imported" = IMD,
                  tabledata "Reference File Setup" = IMD;
}
