#if not CLEAN20
permissionset 1001 "LOCAL"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific func.';
    Permissions =
#if not CLEAN19
                  tabledata "Acc. Sched. Expression Buffer" = RIMD,
                  tabledata "Acc. Schedule Extension" = RIMD,
                  tabledata "Acc. Schedule Result Column" = RIMD,
                  tabledata "Acc. Schedule Result Header" = RIMD,
                  tabledata "Acc. Schedule Result History" = RIMD,
                  tabledata "Acc. Schedule Result Line" = RIMD,
                  tabledata "Acc. Schedule Result Value" = RIMD,
                  tabledata "Adv. Letter Line Rel. Buffer" = RIMD,
                  tabledata "Advance Letter Line Relation" = RIMD,
                  tabledata "Advance Letter Matching Buffer" = RIMD,
                  tabledata "Advance Link" = RIMD,
                  tabledata "Advance Link Buffer - Entry" = RIMD,
                  tabledata "Advance Link Buffer" = RIMD,
                  tabledata "Bank Pmt. Appl. Rule Code" = RIMD,
                  tabledata "Bank Statement Header" = RIMD,
                  tabledata "Bank Statement Line" = RIMD,
                  tabledata "Detailed G/L Entry" = RIMD,
                  tabledata "Issued Bank Statement Header" = RIMD,
                  tabledata "Issued Bank Statement Line" = RIMD,
                  tabledata "Issued Payment Order Header" = RIMD,
                  tabledata "Issued Payment Order Line" = RIMD,
                  tabledata "Payment Order Header" = RIMD,
                  tabledata "Payment Order Line" = RIMD,
                  tabledata "Purch. Advance Letter Entry" = RIMD,
                  tabledata "Purch. Advance Letter Header" = RIMD,
                  tabledata "Purch. Advance Letter Line" = RIMD,
                  tabledata "Purchase Adv. Payment Template" = RIMD,
                  tabledata "Sales Adv. Payment Template" = RIMD,
                  tabledata "Sales Advance Letter Entry" = RIMD,
                  tabledata "Sales Advance Letter Header" = RIMD,
                  tabledata "Sales Advance Letter Line" = RIMD,
                  tabledata "Text-to-Account Mapping Code" = RIMD,
                  tabledata "VAT Amount Line Adv. Payment" = RIMD,
#endif
                  tabledata "Acc. Schedule Filter Line" = RIMD,
                  tabledata "Bank Acc. Adjustment Buffer" = RIMD,
                  tabledata "Detailed Fin. Charge Memo Line" = RIMD,
                  tabledata "Detailed Iss.Fin.Ch. Memo Line" = RIMD,
                  tabledata "Detailed Issued Reminder Line" = RIMD,
                  tabledata "Detailed Reminder Line" = RIMD,
                  tabledata "Enhanced Currency Buffer" = RIMD,
                  tabledata "Export Acc. Schedule" = RIMD,
                  tabledata "G/L Account Adjustment Buffer" = RIMD,
                  tabledata "Multiple Interest Calc. Line" = RIMD,
                  tabledata "Multiple Interest Rate" = RIMD;
}

#endif