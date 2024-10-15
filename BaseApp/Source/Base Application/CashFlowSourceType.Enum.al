#if not CLEAN19
enum 847 "Cash Flow Source Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Receivables") { Caption = 'Receivables'; }
    value(2; "Payables") { Caption = 'Payables'; }
    value(3; "Liquid Funds") { Caption = 'Liquid Funds'; }
    value(4; "Cash Flow Manual Expense") { Caption = 'Cash Flow Manual Expense'; }
    value(5; "Cash Flow Manual Revenue") { Caption = 'Cash Flow Manual Revenue'; }
    value(6; "Sales Orders") { Caption = 'Sales Orders'; }
    value(7; "Purchase Orders") { Caption = 'Purchase Orders'; }
    value(8; "Fixed Assets Budget") { Caption = 'Fixed Assets Budget'; }
    value(9; "Fixed Assets Disposal") { Caption = 'Fixed Assets Disposal'; }
    value(10; "Service Orders") { Caption = 'Service Orders'; }
    value(11; "G/L Budget") { Caption = 'G/L Budget'; }
    value(12; "Sales Advance Letters") { Caption = 'Sales Advance Letters'; ObsoleteState = Pending; ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.'; ObsoleteTag = '19.0'; }
    value(13; "Purchase Advance Letters") { Caption = 'Purchase Advance Letters'; ObsoleteState = Pending; ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.'; ObsoleteTag = '19.0'; }
    value(14; "Job") { Caption = 'Job'; }
    value(15; "Tax") { Caption = 'Tax'; }
    value(16; "Azure AI") { Caption = 'Azure AI'; }
}
#endif