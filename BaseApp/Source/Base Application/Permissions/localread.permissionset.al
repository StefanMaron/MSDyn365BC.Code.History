#if not CLEAN20
permissionset 1002 "LOCAL READ"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific read only access.';
    Permissions =
#if not CLEAN19
                  tabledata "Acc. Sched. Expression Buffer" = R,
                  tabledata "Acc. Schedule Extension" = R,
                  tabledata "Acc. Schedule Result Column" = R,
                  tabledata "Acc. Schedule Result Header" = R,
                  tabledata "Acc. Schedule Result History" = R,
                  tabledata "Acc. Schedule Result Line" = R,
                  tabledata "Acc. Schedule Result Value" = R,
                  tabledata "Adv. Letter Line Rel. Buffer" = R,
                  tabledata "Advance Letter Line Relation" = R,
                  tabledata "Advance Letter Matching Buffer" = R,
                  tabledata "Advance Link" = R,
                  tabledata "Advance Link Buffer - Entry" = R,
                  tabledata "Advance Link Buffer" = R,
                  tabledata "Bank Pmt. Appl. Rule Code" = R,
                  tabledata "Bank Statement Header" = R,
                  tabledata "Bank Statement Line" = R,
                  tabledata "Detailed G/L Entry" = R,
                  tabledata "Issued Bank Statement Header" = R,
                  tabledata "Issued Bank Statement Line" = R,
                  tabledata "Issued Payment Order Header" = R,
                  tabledata "Issued Payment Order Line" = R,
                  tabledata "Payment Order Header" = R,
                  tabledata "Payment Order Line" = R,
                  tabledata "Purch. Advance Letter Entry" = R,
                  tabledata "Purch. Advance Letter Header" = R,
                  tabledata "Purch. Advance Letter Line" = R,
                  tabledata "Purchase Adv. Payment Template" = R,
                  tabledata "Sales Adv. Payment Template" = R,
                  tabledata "Sales Advance Letter Entry" = R,
                  tabledata "Sales Advance Letter Header" = R,
                  tabledata "Sales Advance Letter Line" = R,
                  tabledata "Text-to-Account Mapping Code" = R,
#endif
                  tabledata "Acc. Schedule Filter Line" = R,
                  tabledata "Bank Acc. Adjustment Buffer" = R,
                  tabledata "Detailed Fin. Charge Memo Line" = R,
                  tabledata "Detailed Iss.Fin.Ch. Memo Line" = R,
                  tabledata "Detailed Issued Reminder Line" = R,
                  tabledata "Detailed Reminder Line" = R,
                  tabledata "Enhanced Currency Buffer" = R,
                  tabledata "Export Acc. Schedule" = R,
                  tabledata "G/L Account Adjustment Buffer" = R,
                  tabledata "Multiple Interest Calc. Line" = R,
                  tabledata "Multiple Interest Rate" = R;
}
#endif