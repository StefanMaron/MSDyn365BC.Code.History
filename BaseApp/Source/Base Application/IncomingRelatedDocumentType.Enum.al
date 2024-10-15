#if not CLEAN19
enum 141 "Incoming Related Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Journal") { Caption = 'Journal'; }
    value(1; "Sales Invoice") { Caption = 'Sales Invoice'; }
    value(2; "Sales Credit Memo") { Caption = 'Sales Credit Memo'; }
    value(3; "Purchase Invoice") { Caption = 'Purchase Invoice'; }
    value(4; "Purchase Credit Memo") { Caption = 'Purchase Credit Memo'; }
    value(5; " ") { Caption = ' '; }
    value(6; "Sales Advance")
    {
        Caption = 'Sales Advance';
        ObsoleteState = Pending;
        ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
        ObsoleteTag = '19.0';
    }
    value(7; "Purchase Advance")
    {
        Caption = 'Purchase Advance';
        ObsoleteState = Pending;
        ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
        ObsoleteTag = '19.0';
    }
#if not CLEAN18
    value(8; "Credit")
    {
        Caption = 'Credit';
        ObsoleteState = Pending;
        ObsoleteReason = 'Moved to Compensation Localization Pack for Czech.';
        ObsoleteTag = '18.0';
    }
#endif
}
#endif