namespace System.Security.AccessControl;

using Microsoft.FixedAssets.Depreciation;
using Microsoft.Bank.Payment;
#if not CLEAN22
using Microsoft.Finance.AutomaticAccounts;
#endif
using Microsoft.Bank.Setup;

permissionset 1002 "LOCAL READ"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific read only access.';

    Permissions = tabledata "Depr. Diff. Posting Buffer" = R,
                  tabledata "Foreign Payment Types" = R,
#if not CLEAN22
                  tabledata "Automatic Acc. Header" = R,
                  tabledata "Automatic Acc. Line" = R,
                  tabledata "Intrastat - File Setup" = R,
#endif
                  tabledata "Ref. Payment - Exported" = R,
                  tabledata "Ref. Payment - Exported Buffer" = R,
                  tabledata "Ref. Payment - Imported" = R,
                  tabledata "Reference File Setup" = R;
}
