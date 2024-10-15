permissionset 1001 "LOCAL"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific func.';
    Permissions =
#if not CLEAN17
                  tabledata "Cash Desk Cue" = RIMD,
                  tabledata "Cash Desk Event" = RIMD,
                  tabledata "Cash Desk Report Selections" = RIMD,
                  tabledata "Cash Desk User" = RIMD,
                  tabledata "Cash Document Header" = RIMD,
                  tabledata "Cash Document Line" = RIMD,
                  tabledata Commodity = RIMD,
                  tabledata "Commodity Setup" = RIMD,
                  tabledata "Company Officials" = RIMD,
                  tabledata "Currency Nominal Value" = RIMD,
                  tabledata "Document Footer" = RIMD,
                  tabledata "Electronically Govern. Setup" = RIMD,
                  tabledata "Excel Template" = RIMD,
                  tabledata "Posted Cash Document Header" = RIMD,
                  tabledata "Posted Cash Document Line" = RIMD,
                  tabledata "Reg. No. Srv Config" = RIMD,
                  tabledata "Registration Log" = RIMD,
                  tabledata "Statement File Mapping" = RIMD,
                  tabledata "Statistic Indication" = RIMD,
                  tabledata "Stockkeeping Unit Template" = RIMD,
                  tabledata "Uncertainty Payer Entry" = RIMD,
                  tabledata "VAT Attribute Code" = RIMD,
                  tabledata "VAT Control Report Buffer" = RIMD,
                  tabledata "VAT Control Report Header" = RIMD,
                  tabledata "VAT Control Report Line" = RIMD,
                  tabledata "VAT Control Report Section" = RIMD,
                  tabledata "VAT Ctrl.Rep. - VAT Entry Link" = RIMD,
                  tabledata "VAT Period" = RIMD,
                  tabledata "VAT Statement Attachment" = RIMD,
                  tabledata "VAT Statement Comment Line" = RIMD,
                  tabledata "VIES Declaration Header" = RIMD,
                  tabledata "VIES Declaration Line" = RIMD,
                  tabledata "VIES Transaction Buffer" = RIMD,
                  tabledata "Whse. Net Change Template" = RIMD,
#endif
#if not CLEAN18
                  tabledata "Certificate CZ Code" = RIMD,
                  tabledata "Classification Code" = RIMD,
                  tabledata "Constant Symbol" = RIMD,
                  tabledata "Credit Header" = RIMD,
                  tabledata "Credit Line" = RIMD,
                  tabledata "Credit Report Selections" = RIMD,
                  tabledata "Credits Setup" = RIMD,
                  tabledata "Depreciation Group" = RIMD,
                  tabledata "EET Business Premises" = RIMD,
                  tabledata "EET Cash Register" = RIMD,
                  tabledata "EET Entry" = RIMD,
                  tabledata "EET Entry Status" = RIMD,
                  tabledata "EET Service Setup" = RIMD,
                  tabledata "FA Extended Posting Group" = RIMD,
                  tabledata "FA History Entry" = RIMD,
                  tabledata "Intrastat Currency Exch. Rate" = RIMD,
                  tabledata "Intrastat Delivery Group" = RIMD,
                  tabledata "Posted Credit Header" = RIMD,
                  tabledata "Posted Credit Line" = RIMD,
                  tabledata "Specific Movement" = RIMD,
                  tabledata "Stat. Reporting Setup" = RIMD,
                  tabledata "Subst. Customer Posting Group" = RIMD,
                  tabledata "Subst. Vendor Posting Group" = RIMD,
                  tabledata "User Setup Line" = RIMD,
                  tabledata "VAT Amount Line Adv. Payment" = RIMD,
                  tabledata "XML Export Buffer" = RIMD,
#endif
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
